'use client'

import { usePathname } from 'next/navigation'
import { useEffect } from 'react'

export default function LocaleSwitchWrapper() {
  const pathname = usePathname()

  useEffect(() => {
    // Extract locale from pathname (e.g., /en-US/page -> en-US)
    const localeMatch = pathname.match(/^\/(en-US|nl-NL)/)
    if (localeMatch) {
      const locale = localeMatch[1]
      // Set cookie to remember the locale
      document.cookie = `NEXT_LOCALE=${locale}; path=/; max-age=${60 * 60 * 24 * 365}`
    }
  }, [pathname])

  return null
}
