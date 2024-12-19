import { useEffect } from 'react';
import { useRouter } from 'next/router';

// not used as there's no access to the parent origin it's not ideal as anyone can embed the documentation and receive messages
// const allowedOrigins = ['https://alkem.io', 'https://dev-alkem.io', 'https://acc-alkem.io', 'https://sandbox-alkem.io', 'http://localhost:3000'];
// const isOriginValid = (origin) => allowedOrigins.includes(origin);

const sendMessageToParent = (message) => {
    if (window.parent) {
        window.parent.postMessage(message, '*');
    } else {
        console.warn('Parent window not found or origin not allowed.');
    }
};

// copy in client-web
const SupportedMessageTypes = {
    PageHeight: 'PAGE_HEIGHT',
    PageChange: 'PAGE_CHANGE',
}

let oldPath = '';

const IframeCommunication = () => {
    const router = useRouter();

    const sendPageHeight = () => {
        const pageHeight = document.documentElement.scrollHeight || document.body.scrollHeight;

        if (oldPath !== router.pathname) {
            sendMessageToParent({ type: SupportedMessageTypes.PageHeight, height: pageHeight });
            oldPath = router.pathname;
        }
    };

    useEffect(() => {
        // Send initial pathname and page height to the parent window
        sendMessageToParent({ type: SupportedMessageTypes.PageChange, url: router.pathname });
        sendPageHeight();

        // Send page height on resize
        window.addEventListener('resize', sendPageHeight);

        return () => {
            window.removeEventListener('resize', sendPageHeight);
        };
    }, [router.pathname]);

  return null;
};

export default IframeCommunication;