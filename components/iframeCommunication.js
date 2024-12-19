import { useEffect, useRef } from 'react';
import { useRouter } from 'next/router';

// not used as there's no access to the parent origin. This is not ideal as anyone can embed the documentation and receive messages.
// const allowedOrigins = ['https://alkem.io', 'https://dev-alkem.io', 'https://acc-alkem.io', 'https://sandbox-alkem.io', 'http://localhost:3000'];
// const isOriginValid = (origin) => allowedOrigins.includes(origin);

const sendMessageToParent = (message) => {
    try {
        // todo: check for isOriginValid here
        window.parent.postMessage(message, '*');
    } catch (error) {
        console.warn('Failed to send message to parent: ', error);
    }
};

const SupportedMessageTypes = {
    PageHeight: 'PAGE_HEIGHT',
    PageChange: 'PAGE_CHANGE',
};

const IframeCommunication = () => {
    const router = useRouter();
    const lastHeight = useRef(0);
    const debounceTimeout = useRef(null);

    const sendPageHeight = () => {
        const pageHeight = document.documentElement.scrollHeight || document.body.scrollHeight;

        // Only send if there's a meaningful difference in height
        if (Math.abs(pageHeight - lastHeight.current) > 40) {
            lastHeight.current = pageHeight;

            // Debounce the message to avoid excessive calls
            clearTimeout(debounceTimeout.current);
            debounceTimeout.current = setTimeout(() => {
                sendMessageToParent({ type: SupportedMessageTypes.PageHeight, height: pageHeight });
            }, 50);
        }
    };

    useEffect(() => {
        // Send initial page height and path
        sendMessageToParent({ type: SupportedMessageTypes.PageChange, url: router.pathname });
        sendPageHeight();

        // Observe changes to the body size
        const resizeObserver = new ResizeObserver(sendPageHeight);
        resizeObserver.observe(document.body);

        // Cleanup
        return () => {
            resizeObserver.disconnect();
            clearTimeout(debounceTimeout.current);
        };
    }, [router.pathname]);

    return null;
};

export default IframeCommunication;
