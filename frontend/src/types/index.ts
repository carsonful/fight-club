// Data types
export interface OHLCVData {
  timestamp: string
  open: number
  high: number
  low: number
  close: number
  volume: number
}

export interface Strategy {
  id: string
  name: string
  description?: string
  indicators: Indicator[]
  conditions: Condition[]
}

export interface Indicator {
  id: string
  name: string
  type: string
  parameters: Record<string, any>
}

export interface Condition {
  id: string
  indicator: string
  operator: 'gt' | 'lt' | 'eq' | 'gte' | 'lte'
  value: number
}

export interface Position {
  id: string
  timestamp: string
  type: 'long' | 'short'
  entry_price: number
  exit_price?: number
  quantity: number
  pnl?: number
}

export interface BacktestResult {
  total_return: number
  sharpe_ratio: number
  max_drawdown: number
  win_rate: number
  positions: Position[]
}
