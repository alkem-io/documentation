import { useEffect } from 'react';
import '../styles.css';
import IframeCommunication from '../components/iframeCommunication';

export default function MyApp({ Component, pageProps }) {
  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (window.self !== window.top) {
      document.body.classList.add("in-iframe");
    } else {
      document.body.classList.remove("in-iframe");
    }
  }, []);

  return (
    <>
      <IframeCommunication />
      <Component {...pageProps} />
    </>
  );
}
