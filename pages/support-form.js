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
 <div style={{ position: 'relative', width: '100%', height: '700px', marginTop: '20px' }}>
 {!isLoaded && <p>This block should show a support form. If that is not a case, try a different browser or check if there is an ad-blocke active.</p>}
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