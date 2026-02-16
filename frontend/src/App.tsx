import { useState, useEffect } from 'react'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

function App() {
  const [backendStatus, setBackendStatus] = useState<'checking' | 'connected' | 'disconnected'>('checking')

  useEffect(() => {
    fetch(`${API_URL}/health`)
      .then((res) => res.json())
      .then((data) => {
        if (data.status === 'healthy') {
          setBackendStatus('connected')
        }
      })
      .catch(() => {
        setBackendStatus('disconnected')
      })
  }, [])

  return (
    <div style={{ padding: '2rem', fontFamily: 'sans-serif', maxWidth: '1200px', margin: '0 auto' }}>
      <h1>Fight Club</h1>
      <p>
        Backend status:{' '}
        {backendStatus === 'checking' && <span>Checking...</span>}
        {backendStatus === 'connected' && <span style={{ color: '#28a745' }}>Connected</span>}
        {backendStatus === 'disconnected' && <span style={{ color: '#dc3545' }}>Disconnected</span>}
      </p>
    </div>
  )
}

export default App
