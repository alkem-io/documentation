import React, { useState, useEffect } from 'react';

const IframeComponent = () => {
 const [isLoaded, setIsLoaded] = useState(false);

 useEffect(() => {
 const iframe = document.querySelector('iframe');
 iframe.addEventListener('load', () => {
 setIsLoaded(true);
 });
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
 {!isLoaded && <p style={{ textAlign: 'center' }}>This block should show a support form. If that is not a case, try a different browser or check if there is an ad-blocker active.</p>}
 <iframe
 src="https://share-eu1.hsforms.com/1IKi5Eg2DT3C1BoWQzNQ0Eg2drqet"
 title="Embedded Form"
 frameborder="0"
 style={{ width: '100%', height: '100%', display: isLoaded ? 'block' : 'none' }}
 ></iframe>
 </div>
 );
};

export default IframeComponent;