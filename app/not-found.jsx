export default function NotFound() {
  return (
    <html lang="en" dir="ltr">
      <body style={{
        backgroundColor: '#fff',
        color: '#000',
        fontFamily: 'system-ui, sans-serif',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        minHeight: '100vh',
        margin: 0
      }}>
        <div style={{ textAlign: 'center' }}>
          <h1 style={{ fontSize: '2rem', marginBottom: '1rem' }}>404 - Page Not Found</h1>
          <p style={{ color: '#666' }}>The page you are looking for does not exist.</p>
          <a
            href="/documentation/en-US"
            style={{
              color: '#0070f3',
              textDecoration: 'none',
              marginTop: '1rem',
              display: 'inline-block'
            }}
          >
            Go to Documentation
          </a>
        </div>
      </body>
    </html>
  )
}
