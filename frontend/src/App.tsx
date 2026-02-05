import { useState } from 'react'

function App() {
  const [count, setCount] = useState<number>(0)

  return (
    <div style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <h1>Trading Backtest System</h1>
      <p>Backend and Frontend are connected!</p>
      <button 
        onClick={() => setCount((count) => count + 1)}
        style={{ 
          padding: '0.5rem 1rem', 
          fontSize: '1rem',
          cursor: 'pointer'
        }}
      >
        Count: {count}
      </button>
    </div>
  )
}

export default App
