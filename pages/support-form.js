import React, { useState, useEffect } from 'react';

const IframeComponent = () => {
 const [status, setStatus] = useState('loading'); // 'loading', 'loaded', 'error'
 const iframeRef = React.useRef(null);

 useEffect(() => {
 const iframe = iframeRef.current;
 if (iframe) {
    const handleLoad = () => setStatus('loaded');
    const handleError = () => setStatus('error');
    iframe.addEventListener('load', handleLoad);
    iframe.addEventListener('error', handleError);
    return () => {
        iframe.removeEventListener('load', handleLoad);
        iframe.removeEventListener('error', handleError);
    };
 }
 }, []);

 return (
 <div style={{
 position: 'relative',
 width: '100%',
 maxWidth: '600px',
 height: '700px',
 margin: '40px auto',
 padding: '20px',
 backgroundColor: '#f9f9f9',
 border: '1px solid #ddd',
 borderRadius: '10px',
 boxShadow: '0 0 10px rgba(0,0,0,0.1)'
 }}>
 {status == 'loading' && (
      <p style={{ textAlign: 'center' }}>Loading support form...</p>
    )}
    {status == 'error' && (
      <p style={{ textAlign: 'center' }}>
        We couldn't load the support form. Please try a different browser, check if you have an ad-blocker active, or <a href="mailto:support@alkem.io">contact us directly</a>.
      </p>
    )}
 <iframe
 ref={iframeRef}
 src="https://share-eu1.hsforms.com/1IKi5Eg2DT3C1BoWQzNQ0Eg2drqet"
 title="Embedded Form"
 frameborder="0"
 style={{ width: '100%', height: '100%', display: status === 'loaded' ? 'block' : 'none', border: 'none' }}
 ></iframe>
 </div>
 );
};

export default IframeComponent;