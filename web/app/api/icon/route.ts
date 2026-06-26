import { ImageResponse } from 'next/og'

export const runtime = 'edge'

export function GET(req: Request) {
  const { searchParams } = new URL(req.url)
  const size = parseInt(searchParams.get('size') ?? '512', 10)

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%', height: '100%',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          backgroundColor: '#0A1A3A',
        }}
      >
        <div
          style={{
            color: '#D4AF37',
            fontSize: Math.round(size * 0.6),
            fontWeight: 900,
            fontFamily: 'sans-serif',
            letterSpacing: '-0.02em',
          }}
        >
          S
        </div>
      </div>
    ),
    { width: size, height: size }
  )
}
