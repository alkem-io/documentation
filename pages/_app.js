import '../styles.css'
import IframeCommunication from '../components/iframeCommunication';
 
// This default export is required in a new `pages/_app.js` file.
export default function MyApp({ Component, pageProps }) {
  return <><IframeCommunication /><Component {...pageProps} /></>;
}
