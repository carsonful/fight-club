from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from ...models.data import OHLCVRequest, OHLCVResponse
from ...data.warehouse import DataWarehouse
from ...data.transformations import dataframe_to_ohlcv
from ...utils.helpers import get_db

router = APIRouter()


@router.get("/ohlcv", response_model=OHLCVResponse)
async def get_ohlcv_data(
    symbol: str = Query(..., description="Stock symbol (e.g., AAPL)"),
    start_date: str = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: str = Query(None, description="End date (YYYY-MM-DD)"),
    interval: str = Query("daily", description="Time interval (daily, intraday)"),
    db: AsyncSession = Depends(get_db)
):
    """
    Fetch OHLCV data for a symbol.
    Checks cache first, fetches from Alpha Vantage if needed.
    """
    try:
        warehouse = DataWarehouse(db)

        # Get data (from cache or API)
        df = await warehouse.get_ohlcv_data(symbol, start_date, end_date)

        if df.empty:
            raise HTTPException(status_code=404, detail=f"No data found for symbol {symbol}")

        # Convert to response format
        ohlcv_data = dataframe_to_ohlcv(df)

        # Check if data was cached (simple heuristic: if we got data quickly, it was cached)
        cached = len(df) > 0

        await warehouse.close()

        return OHLCVResponse(
            symbol=symbol,
            data=ohlcv_data,
            cached=cached
        )

    except ValueError as e:
        print(f"ValueError in get_ohlcv_data: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        print(f"Exception in get_ohlcv_data: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error fetching data: {str(e)}")


@router.post("/refresh")
async def refresh_data(
    request: OHLCVRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Force refresh data from Alpha Vantage API.
    Note: Subject to API rate limits.
    """
    try:
        warehouse = DataWarehouse(db)

        # Fetch fresh data from API
        outputsize = "compact"
        ohlcv_data = await warehouse.av_client.fetch_daily(request.symbol, outputsize)

        if not ohlcv_data:
            raise HTTPException(status_code=404, detail=f"No data returned for symbol {request.symbol}")

        # Save to cache
        await warehouse.save_ohlcv_data(request.symbol, ohlcv_data)

        await warehouse.close()

        return {
            "message": f"Data refreshed for {request.symbol}",
            "records": len(ohlcv_data)
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error refreshing data: {str(e)}")


@router.get("/symbols")
async def get_available_symbols():
    """
    Get list of available/suggested symbols.
    """
    # Common symbols for testing
    symbols = [
        {"symbol": "AAPL", "name": "Apple Inc."},
        {"symbol": "MSFT", "name": "Microsoft Corporation"},
        {"symbol": "GOOGL", "name": "Alphabet Inc."},
        {"symbol": "AMZN", "name": "Amazon.com Inc."},
        {"symbol": "TSLA", "name": "Tesla Inc."},
        {"symbol": "SPY", "name": "SPDR S&P 500 ETF"},
    ]

    return {"symbols": symbols}
