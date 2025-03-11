import { useEffect } from 'react';
import Head from 'next/head';
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
      <Head>
        <title>Alkemio - Safe Spaces for Collaboration</title>
        <meta name="description" content="Join Alkemio! Achieve your goals. Safe smart spaces for collective action." />
      </Head>
      <IframeCommunication />
      <Component {...pageProps} />
    </>
  );
}