import { useEffect } from 'react';
import '../styles.css';
import IframeCommunication from '../components/iframeCommunication';

export default function MyApp({ Component, pageProps }) {
  useEffect(() => {
    try {
      if (window.self === window.top) {
        document.body.classList.add("not-in-iframe");
      }
    } catch (e) {}
  }, []);

  return (
    <>
      <IframeCommunication />
      <Component {...pageProps} />
    </>
  );
}
