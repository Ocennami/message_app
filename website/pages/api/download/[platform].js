// Direct download endpoint cho website
// File: pages/api/download/[platform].js
// URL: /api/download/android hoặc /api/download/windows

export default async function handler(req, res) {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { platform } = req.query;

  if (!platform || !['android', 'windows'].includes(platform)) {
    res.status(400).json({ error: 'Invalid platform. Use "android" or "windows"' });
    return;
  }

  try {
    // Lấy thông tin download URL từ Supabase
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const functionUrl = `${supabaseUrl}/functions/v1/releases?platform=${platform}`;
    
    const response = await fetch(functionUrl, {
      headers: {
        'Authorization': `Bearer ${process.env.SUPABASE_ANON_KEY}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch download URL: ${response.status}`);
    }

    const data = await response.json();
    
    if (!data.url) {
      res.status(404).json({ error: 'Download URL not found' });
      return;
    }

    // Redirect trực tiếp đến file download
    res.redirect(302, data.url);
    
  } catch (error) {
    console.error('Download error:', error);
    res.status(500).json({ 
      error: 'Failed to process download request'
    });
  }
}
