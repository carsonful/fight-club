import httpx
import pandas as pd
from datetime import datetime, timedelta
from typing import Optional, List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.data import OHLCVRecord, OHLCVData
from ..utils.config import get_settings
from ..utils.helpers import parse_date


class AlphaVantageClient:
    """Client for Alpha Vantage API."""

    BASE_URL = "https://www.alphavantage.co/query"

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.client = httpx.AsyncClient(timeout=30.0)

    async def fetch_daily(self, symbol: str, outputsize: str = "compact") -> List[OHLCVData]:
        """
        Fetch daily OHLCV data from Alpha Vantage.

        Args:
            symbol: Stock symbol (e.g., 'AAPL')
            outputsize: 'compact' (last 100 days) or 'full' (20+ years)

        Returns:
            List of OHLCVData objects
        """
        params = {
            "function": "TIME_SERIES_DAILY",
            "symbol": symbol,
            "apikey": self.api_key,
            "outputsize": outputsize,
            "datatype": "json"
        }

        print(f"Fetching from Alpha Vantage: {symbol}, outputsize: {outputsize}")
        response = await self.client.get(self.BASE_URL, params=params)
        response.raise_for_status()
        data = response.json()

        print(f"Alpha Vantage response keys: {list(data.keys())}")

        if "Error Message" in data:
            raise ValueError(f"Alpha Vantage error: {data['Error Message']}")

        if "Note" in data:
            raise ValueError("API rate limit exceeded. Please wait and try again.")

        if "Information" in data:
            print(f"Alpha Vantage info: {data['Information']}")
            raise ValueError(f"Alpha Vantage: {data['Information']}")

        time_series = data.get("Time Series (Daily)", {})
        if not time_series:
            print(f"Full response: {data}")
            raise ValueError(f"No time series data in response. Keys: {list(data.keys())}")

        return self._parse_time_series(time_series)

    async def fetch_intraday(self, symbol: str, interval: str = "5min") -> List[OHLCVData]:
        """
        Fetch intraday OHLCV data from Alpha Vantage.

        Args:
            symbol: Stock symbol
            interval: Time interval (1min, 5min, 15min, 30min, 60min)

        Returns:
            List of OHLCVData objects
        """
        params = {
            "function": "TIME_SERIES_INTRADAY",
            "symbol": symbol,
            "interval": interval,
            "apikey": self.api_key,
            "outputsize": "compact",
            "datatype": "json"
        }

        response = await self.client.get(self.BASE_URL, params=params)
        response.raise_for_status()
        data = response.json()

        if "Error Message" in data:
            raise ValueError(f"Alpha Vantage error: {data['Error Message']}")

        if "Note" in data:
            raise ValueError("API rate limit exceeded. Please wait and try again.")

        time_series = data.get(f"Time Series ({interval})", {})
        return self._parse_time_series(time_series)

    def _parse_time_series(self, time_series: dict) -> List[OHLCVData]:
        """Parse Alpha Vantage time series data to OHLCVData objects."""
        ohlcv_data = []

        for timestamp_str, values in time_series.items():
            try:
                ohlcv = OHLCVData(
                    timestamp=datetime.fromisoformat(timestamp_str),
                    open=float(values["1. open"]),
                    high=float(values["2. high"]),
                    low=float(values["3. low"]),
                    close=float(values["4. close"]),
                    volume=float(values["5. volume"])
                )
                ohlcv_data.append(ohlcv)
            except (KeyError, ValueError) as e:
                print(f"Error parsing data for {timestamp_str}: {e}")
                continue

        return sorted(ohlcv_data, key=lambda x: x.timestamp)

    async def close(self):
        """Close the HTTP client."""
        await self.client.aclose()


class DataWarehouse:
    """Manages data fetching and caching."""

    def __init__(self, db_session: AsyncSession):
        self.db_session = db_session
        settings = get_settings()
        self.av_client = AlphaVantageClient(settings.alpha_vantage_api_key)

    async def get_ohlcv_data(
        self,
        symbol: str,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None
    ) -> pd.DataFrame:
        """
        Get OHLCV data, checking cache first.

        Args:
            symbol: Stock symbol
            start_date: Start date (YYYY-MM-DD)
            end_date: End date (YYYY-MM-DD)

        Returns:
            pandas DataFrame with OHLCV data
        """
        try:
            # Parse dates
            start_dt = parse_date(start_date) if start_date else datetime(2000, 1, 1)
            end_dt = parse_date(end_date) if end_date else datetime.now()

            # Check cache
            cached_data = await self._get_cached_data(symbol, start_dt, end_dt)

            if cached_data and len(cached_data) > 0:
                # Cache hit
                df = self._records_to_dataframe(cached_data)
            else:
                # Cache miss - fetch from API
                print(f"Cache miss for {symbol}, fetching from Alpha Vantage...")
                outputsize = "compact"
                ohlcv_data = await self.av_client.fetch_daily(symbol, outputsize)

                if not ohlcv_data:
                    raise ValueError(f"No data returned from Alpha Vantage for {symbol}")

                # Save to cache
                await self.save_ohlcv_data(symbol, ohlcv_data)

                # Convert to DataFrame
                df = self._ohlcv_to_dataframe(ohlcv_data)

            # Filter by date range
            if len(df) > 0:
                df = df[(df['timestamp'] >= start_dt) & (df['timestamp'] <= end_dt)]

            return df.reset_index(drop=True)
        except Exception as e:
            print(f"Error in get_ohlcv_data: {str(e)}")
            raise

    async def save_ohlcv_data(self, symbol: str, data: List[OHLCVData]):
        """Save OHLCV data to database cache."""
        for ohlcv in data:
            # Check if record already exists
            stmt = select(OHLCVRecord).where(
                OHLCVRecord.symbol == symbol,
                OHLCVRecord.timestamp == ohlcv.timestamp
            )
            result = await self.db_session.execute(stmt)
            existing = result.scalar_one_or_none()

            if not existing:
                record = OHLCVRecord(
                    symbol=symbol,
                    timestamp=ohlcv.timestamp,
                    open=ohlcv.open,
                    high=ohlcv.high,
                    low=ohlcv.low,
                    close=ohlcv.close,
                    volume=ohlcv.volume
                )
                self.db_session.add(record)

        await self.db_session.commit()

    async def _get_cached_data(
        self,
        symbol: str,
        start_date: datetime,
        end_date: datetime
    ) -> List[OHLCVRecord]:
        """Query cached data from database."""
        stmt = select(OHLCVRecord).where(
            OHLCVRecord.symbol == symbol,
            OHLCVRecord.timestamp >= start_date,
            OHLCVRecord.timestamp <= end_date
        ).order_by(OHLCVRecord.timestamp)

        result = await self.db_session.execute(stmt)
        return list(result.scalars().all())

    def _records_to_dataframe(self, records: List[OHLCVRecord]) -> pd.DataFrame:
        """Convert database records to pandas DataFrame."""
        data = [{
            'timestamp': r.timestamp,
            'open': r.open,
            'high': r.high,
            'low': r.low,
            'close': r.close,
            'volume': r.volume
        } for r in records]

        return pd.DataFrame(data)

    def _ohlcv_to_dataframe(self, ohlcv_list: List[OHLCVData]) -> pd.DataFrame:
        """Convert OHLCVData list to pandas DataFrame."""
        data = [{
            'timestamp': o.timestamp,
            'open': o.open,
            'high': o.high,
            'low': o.low,
            'close': o.close,
            'volume': o.volume
        } for o in ohlcv_list]

        return pd.DataFrame(data)

    async def close(self):
        """Clean up resources."""
        await self.av_client.close()
