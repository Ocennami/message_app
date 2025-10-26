// API endpoint để lấy thông tin version cho website
// File: pages/api/releases.js

export default async function handler(req, res) {
  if (req.method !== "GET") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  try {
    // Gọi Supabase Edge Function để lấy thông tin version
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const functionUrl = `${supabaseUrl}/functions/v1/releases`;

    const response = await fetch(functionUrl, {
      headers: {
        Authorization: `Bearer ${process.env.SUPABASE_ANON_KEY}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch release info: ${response.status}`);
    }

    const data = await response.json();

    // Cache response for 5 minutes
    res.setHeader("Cache-Control", "public, max-age=300");
    res.status(200).json(data);
  } catch (error) {
    console.error("API error:", error);
    res.status(500).json({
      error: "Failed to fetch release information",
    });
  }
}
