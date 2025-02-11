import { useEffect, useRef } from 'react';
import { useRouter } from 'next/router';

const HEIGHT_DIFFERENCE_THRESHOLD = 130; // ~30 locally and 122 on Sandbox (Donna PC)

const allowedOrigins = ['https://alkem.io', 'https://dev-alkem.io', 'https://acc-alkem.io', 'https://sandbox-alkem.io', 'http://localhost:3000'];
const isOriginValid = (origin) => allowedOrigins.includes(origin);

const getCurrentOrigin = () => {
    const { protocol, hostname, origin, port } = window.location;
    if (port) {
        return `${protocol}//${hostname}:3000`; // local client port
    }

    return origin;
};

const sendMessageToParent = (message) => {
    try {
        const origin = getCurrentOrigin();

        if (!isOriginValid(origin)) {
            console.warn('Invalid origin: ', origin);
            return;
        }

        window.parent.postMessage(message, getCurrentOrigin());
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
        console.log('Scroll change new/old: ', pageHeight, lastHeight.current);

        // Only send if there's a meaningful difference in height
        if (Math.abs(pageHeight - lastHeight.current) > HEIGHT_DIFFERENCE_THRESHOLD) {
            lastHeight.current = pageHeight;

            // Debounce the message to avoid excessive calls
            clearTimeout(debounceTimeout.current);
            debounceTimeout.current = setTimeout(() => {
                console.log('Scroll change SENT: ', pageHeight, lastHeight.current);
                sendMessageToParent({ type: SupportedMessageTypes.PageHeight, height: pageHeight });
            }, 50);
        }
    };
    

    useEffect(() => {
        // Send path
        sendMessageToParent({ type: SupportedMessageTypes.PageChange, url: router.pathname });

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
