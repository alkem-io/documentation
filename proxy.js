import { NextResponse } from 'next/server'

const locales = ['en-US', 'nl-NL']
const defaultLocale = 'en-US'

export function proxy(request) {
  const { pathname } = request.nextUrl

  // Check if pathname already has a locale
  const pathnameHasLocale = locales.some(
    (locale) => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
  )

  if (pathnameHasLocale) {
    return NextResponse.next()
  }

  // Try to get locale from cookie (set when user switches language)
  const cookieLocale = request.cookies.get('NEXT_LOCALE')?.value

  // Or from Accept-Language header
  const acceptLanguage = request.headers.get('accept-language') || ''
  const browserLocale = acceptLanguage.includes('nl') ? 'nl-NL' : defaultLocale

  // Prefer cookie, then browser, then default
  const locale = (cookieLocale && locales.includes(cookieLocale))
    ? cookieLocale
    : browserLocale

  // Redirect to localized path
  const url = request.nextUrl.clone()
  url.pathname = `/${locale}${pathname}`

  const response = NextResponse.redirect(url)

  // Set cookie to remember the locale
  response.cookies.set('NEXT_LOCALE', locale, {
    path: '/',
    maxAge: 60 * 60 * 24 * 365 // 1 year
  })

  return response
}

export const config = {
  matcher: [
    '/',
    '/((?!api|_next/static|_next/image|favicon.ico|icon.svg|apple-icon.png|manifest|_pagefind).*)'
  ]
}
