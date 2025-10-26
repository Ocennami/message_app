# Alliance Messenger Website

Website để host và distribute releases của Alliance Messenger app.

## 🌐 Features

- ✅ Auto-redirect download links
- ✅ Release info API
- ✅ Platform detection
- ✅ Integration với Supabase

## 🚀 Quick Deploy to Vercel

### 1. Click Deploy Button

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone)

### 2. Configure Environment Variables

Add these in Vercel Dashboard:

```env
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. Deploy Settings

- **Root Directory**: `website`
- **Framework Preset**: Next.js
- **Build Command**: `npm run build`
- **Output Directory**: `.next`

## 📁 Project Structure

```
website/
├── pages/
│   ├── api/
│   │   └── download/
│   │       └── [platform].js    # Download redirect API
│   └── download/
│       └── [platform].js        # Download page
├── package.json
├── .env.example
└── README.md
```

## 🔗 API Endpoints

### Get Latest Release Info

```
GET /api/releases?platform={android|windows}
```

Response:

```json
{
  "latest_version": "1.0.1",
  "notes": "Release notes...",
  "url": "https://...",
  "sha256": "abc123..."
}
```

### Download Release

```
GET /download/android
GET /download/windows
```

Auto-redirects to download file.

## 🧪 Local Development

```bash
cd website
npm install
npm run dev
```

Open http://localhost:3000

## 📝 Environment Variables

Copy `.env.example` to `.env.local`:

```bash
cp .env.example .env.local
```

Edit `.env.local` with your values.

## 🔐 Security

- ✅ CORS enabled for API routes
- ✅ Service Role Key only used server-side
- ✅ Public files served via Supabase Storage
- ✅ SHA256 checksum verification

## 📊 Usage

### Direct Links (for sharing)

- Android: `https://your-website.vercel.app/download/android`
- Windows: `https://your-website.vercel.app/download/windows`

### QR Code (for mobile)

Generate QR code pointing to `/download/android` for easy mobile installation.

## 🎨 Customization

Edit `pages/download/[platform].js` to customize download page UI.

## 📚 More Info

See main project README for full setup guide.
