import { useState } from 'react'
import { dataService, OHLCVResponse } from './services/dataService'
import { backtestService } from './services/backtestService'
import { BacktestResult } from './types'

function App() {
  const [symbol, setSymbol] = useState('AAPL')
  const [loading, setLoading] = useState(false)
  const [stockData, setStockData] = useState<OHLCVResponse | null>(null)
  const [backtestResult, setBacktestResult] = useState<BacktestResult | null>(null)
  const [error, setError] = useState<string | null>(null)

  const fetchStockData = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await dataService.getOHLCVData(symbol)
      setStockData(data)
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to fetch data')
    } finally {
      setLoading(false)
    }
  }

  const runBacktest = async () => {
    setLoading(true)
    setError(null)
    try {
      const endDate = new Date()
      const startDate = new Date()
      startDate.setDate(startDate.getDate() - 365)

      const result = await backtestService.runBacktest({
        symbol: symbol,
        start_date: startDate.toISOString().split('T')[0],
        end_date: endDate.toISOString().split('T')[0],
        initial_capital: 10000,
        strategy: {
          id: 'sma_crossover',
          name: 'SMA Crossover Strategy',
          description: 'Buy when SMA20 > SMA50',
          indicators: [
            {
              id: 'i1',
              name: 'SMA_20',
              type: 'sma',
              parameters: { period: 20 }
            },
            {
              id: 'i2',
              name: 'SMA_50',
              type: 'sma',
              parameters: { period: 50 }
            }
          ],
          conditions: [
            {
              id: 'c1',
              indicator: 'SMA_20',
              operator: 'gt',
              value: 'SMA_50' as any
            }
          ]
        }
      })
      setBacktestResult(result)
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to run backtest')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ padding: '2rem', fontFamily: 'sans-serif', maxWidth: '1200px', margin: '0 auto' }}>
      <h1>🚀 Trading Backtest System</h1>
      <p>Backend and Frontend are connected!</p>

      {/* Input Section */}
      <div style={{ marginTop: '2rem', padding: '1.5rem', border: '1px solid #ddd', borderRadius: '8px' }}>
        <h2>Stock Symbol</h2>
        <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
          <input
            type="text"
            value={symbol}
            onChange={(e) => setSymbol(e.target.value.toUpperCase())}
            placeholder="Enter symbol (e.g., AAPL)"
            style={{
              padding: '0.5rem 1rem',
              fontSize: '1rem',
              border: '1px solid #ccc',
              borderRadius: '4px',
              width: '200px'
            }}
          />
          <button
            onClick={fetchStockData}
            disabled={loading}
            style={{
              padding: '0.5rem 1.5rem',
              fontSize: '1rem',
              backgroundColor: '#007bff',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: loading ? 'not-allowed' : 'pointer'
            }}
          >
            {loading ? 'Loading...' : 'Fetch Stock Data'}
          </button>
          <button
            onClick={runBacktest}
            disabled={loading}
            style={{
              padding: '0.5rem 1.5rem',
              fontSize: '1rem',
              backgroundColor: '#28a745',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: loading ? 'not-allowed' : 'pointer'
            }}
          >
            {loading ? 'Running...' : 'Run Backtest (SMA Crossover)'}
          </button>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div style={{
          marginTop: '1rem',
          padding: '1rem',
          backgroundColor: '#f8d7da',
          color: '#721c24',
          border: '1px solid #f5c6cb',
          borderRadius: '4px'
        }}>
          <strong>Error:</strong> {error}
        </div>
      )}

      {/* Stock Data Display */}
      {stockData && (
        <div style={{ marginTop: '2rem', padding: '1.5rem', border: '1px solid #ddd', borderRadius: '8px' }}>
          <h2>📊 Stock Data: {stockData.symbol}</h2>
          <p><strong>Records:</strong> {stockData.data.length}</p>
          <p><strong>Cached:</strong> {stockData.cached ? 'Yes' : 'No (Fresh from API)'}</p>

          <h3>All Data ({stockData.data.length} records):</h3>
          <div style={{ maxHeight: '500px', overflowY: 'auto', marginTop: '1rem' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ backgroundColor: '#f0f0f0', position: 'sticky', top: 0 }}>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>Date</th>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>Open</th>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>High</th>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>Low</th>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>Close</th>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>Volume</th>
              </tr>
            </thead>
            <tbody>
              {[...stockData.data].reverse().map((row, idx) => (
                <tr key={idx}>
                  <td style={{ padding: '0.5rem', border: '1px solid #ddd' }}>
                    {new Date(row.timestamp).toLocaleDateString()}
                  </td>
                  <td style={{ padding: '0.5rem', border: '1px solid #ddd' }}>${row.open.toFixed(2)}</td>
                  <td style={{ padding: '0.5rem', border: '1px solid #ddd' }}>${row.high.toFixed(2)}</td>
                  <td style={{ padding: '0.5rem', border: '1px solid #ddd' }}>${row.low.toFixed(2)}</td>
                  <td style={{ padding: '0.5rem', border: '1px solid #ddd' }}>${row.close.toFixed(2)}</td>
                  <td style={{ padding: '0.5rem', border: '1px solid #ddd' }}>
                    {row.volume.toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          </div>
        </div>
      )}

      {/* Backtest Results Display */}
      {backtestResult && (
        <div style={{ marginTop: '2rem', padding: '1.5rem', border: '1px solid #ddd', borderRadius: '8px', backgroundColor: '#f9f9f9' }}>
          <h2>📈 Backtest Results</h2>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem', marginTop: '1rem' }}>
            <div style={{ padding: '1rem', backgroundColor: 'white', borderRadius: '4px', border: '1px solid #ddd' }}>
              <div style={{ fontSize: '0.875rem', color: '#666' }}>Total Return</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 'bold', color: backtestResult.total_return >= 0 ? '#28a745' : '#dc3545' }}>
                {backtestResult.total_return.toFixed(2)}%
              </div>
            </div>

            <div style={{ padding: '1rem', backgroundColor: 'white', borderRadius: '4px', border: '1px solid #ddd' }}>
              <div style={{ fontSize: '0.875rem', color: '#666' }}>Sharpe Ratio</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>
                {backtestResult.sharpe_ratio.toFixed(2)}
              </div>
            </div>

            <div style={{ padding: '1rem', backgroundColor: 'white', borderRadius: '4px', border: '1px solid #ddd' }}>
              <div style={{ fontSize: '0.875rem', color: '#666' }}>Max Drawdown</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 'bold', color: '#dc3545' }}>
                {backtestResult.max_drawdown.toFixed(2)}%
              </div>
            </div>

            <div style={{ padding: '1rem', backgroundColor: 'white', borderRadius: '4px', border: '1px solid #ddd' }}>
              <div style={{ fontSize: '0.875rem', color: '#666' }}>Win Rate</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>
                {backtestResult.win_rate.toFixed(2)}%
              </div>
            </div>
          </div>

          <h3 style={{ marginTop: '2rem' }}>Recent Trades ({backtestResult.positions.length} total):</h3>
          <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '1rem' }}>
            <thead>
              <tr style={{ backgroundColor: '#f0f0f0' }}>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>Date</th>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>Type</th>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>Entry</th>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>Exit</th>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>Quantity</th>
                <th style={{ padding: '0.5rem', border: '1px solid #ddd' }}>P&L</th>
              </tr>
            </thead>
            <tbody>
              {backtestResult.positions.slice(0, 10).map((position, idx) => (
                <tr key={idx}>
                  <td style={{ padding: '0.5rem', border: '1px solid #ddd' }}>
                    {new Date(position.timestamp).toLocaleDateString()}
                  </td>
                  <td style={{ padding: '0.5rem', border: '1px solid #ddd' }}>
                    <span style={{
                      padding: '0.25rem 0.5rem',
                      borderRadius: '4px',
                      backgroundColor: position.type === 'long' ? '#d1ecf1' : '#f8d7da',
                      color: position.type === 'long' ? '#0c5460' : '#721c24'
                    }}>
                      {position.type.toUpperCase()}
                    </span>
                  </td>
                  <td style={{ padding: '0.5rem', border: '1px solid #ddd' }}>${position.entry_price.toFixed(2)}</td>
                  <td style={{ padding: '0.5rem', border: '1px solid #ddd' }}>
                    {position.exit_price ? `$${position.exit_price.toFixed(2)}` : '-'}
                  </td>
                  <td style={{ padding: '0.5rem', border: '1px solid #ddd' }}>{position.quantity}</td>
                  <td style={{
                    padding: '0.5rem',
                    border: '1px solid #ddd',
                    color: position.pnl && position.pnl >= 0 ? '#28a745' : '#dc3545',
                    fontWeight: 'bold'
                  }}>
                    {position.pnl ? `$${position.pnl.toFixed(2)}` : '-'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

export default App
