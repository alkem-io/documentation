import React, { useState, useEffect } from 'react';

const states = {
  LOADING: 'loading',
  LOADED: 'loaded',
  ERROR: 'error',
};

const MonthlySessionForm = () => {
 const [status, setStatus] = useState(states.LOADING);
 const [iframeSrc, setIframeSrc] = useState();

  useEffect(() => {
    // Delay setting src to ensure onLoad can be captured
    setIframeSrc('https://share-eu1.hsforms.com/14vkAt9WBQUeS11UrJb8R8w2drqet');
  }, []);

  const handleLoad = () => setStatus(states.LOADED);
  const handleError = () => setStatus(states.ERROR);

 return (
  <div 
    style={{
      position: 'relative',
      width: '100%',
      maxWidth: '600px',
      height: '800px',
      margin: '40px auto',
      padding: '20px',
      backgroundColor: '#f9f9f9',
      border: '1px solid #ddd',
      borderRadius: '10px',
      boxShadow: '0 0 10px rgba(0,0,0,0.1)'
    }}
  >
    {status === states.LOADING && (
      <p style={{ textAlign: 'center' }}>Loading sign-up form...</p>
    )}
    {status === states.ERROR && (
      <p style={{ textAlign: 'center' }}>
        We couldn't load the sign-up form. Please try a different browser, check if you have an ad-blocker active, or <a href="mailto:support@alkem.io">contact us directly</a>.
      </p>
    )}
    <iframe
      src={iframeSrc}
      title="Embedded Form"
      onLoad={handleLoad}
      onError={handleError}
      frameBorder="0"
      style={{ 
        width: '100%', 
        height: '100%', 
        border: 'none',
        opacity: status === states.LOADED ? 1 : 0,
        transition: 'opacity 0.3s ease-in-out',
      }}
    />
 </div>
 );
};

export default MonthlySessionForm;