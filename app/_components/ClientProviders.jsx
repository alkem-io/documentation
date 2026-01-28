'use client'

import { useEffect, useRef } from 'react'
import { usePathname } from 'next/navigation'

const HEIGHT_DIFFERENCE_THRESHOLD = 130

const allowedOrigins = [
  'https://alkem.io',
  'https://dev-alkem.io',
  'https://acc-alkem.io',
  'https://sandbox-alkem.io',
  'https://test-alkem.io',
  'http://localhost:3000'
]

const isOriginValid = (origin) => allowedOrigins.includes(origin)

const getCurrentOrigin = () => {
  if (typeof window === 'undefined') return ''
  const { protocol, hostname, origin, port } = window.location
  if (port) {
    return `${protocol}//${hostname}:3000`
  }
  return origin
}

const sendMessageToParent = (message) => {
  try {
    const origin = getCurrentOrigin()
    if (!isOriginValid(origin)) {
      console.warn('Invalid origin: ', origin)
      return
    }
    window.parent.postMessage(message, getCurrentOrigin())
  } catch (error) {
    console.warn('Failed to send message to parent: ', error)
  }
}

const SupportedMessageTypes = {
  PageHeight: 'PAGE_HEIGHT',
  PageChange: 'PAGE_CHANGE'
}

export default function ClientProviders() {
  const pathname = usePathname()
  const lastHeight = useRef(0)
  const debounceTimeout = useRef(null)

  const sendPageHeight = () => {
    if (typeof document === 'undefined') return
    const pageHeight = document.documentElement.scrollHeight || document.body.scrollHeight

    if (Math.abs(pageHeight - lastHeight.current) > HEIGHT_DIFFERENCE_THRESHOLD) {
      lastHeight.current = pageHeight
      clearTimeout(debounceTimeout.current)
      debounceTimeout.current = setTimeout(() => {
        sendMessageToParent({ type: SupportedMessageTypes.PageHeight, height: pageHeight })
      }, 50)
    }
  }

  useEffect(() => {
    try {
      if (window.self === window.top) {
        document.body.classList.add('not-in-iframe')
      }
    } catch (e) {}
  }, [])

  useEffect(() => {
    sendMessageToParent({ type: SupportedMessageTypes.PageChange, url: pathname })

    const resizeObserver = new ResizeObserver(sendPageHeight)
    resizeObserver.observe(document.body)

    return () => {
      resizeObserver.disconnect()
      clearTimeout(debounceTimeout.current)
    }
  }, [pathname])

  return null
}
