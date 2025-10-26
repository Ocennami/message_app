import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const url = new URL(req.url);
    const platform = url.searchParams.get("platform"); // 'android' | 'windows' | null

    // Lấy thông tin release mới nhất từ database
    const { data: latestRelease, error } = await supabaseClient
      .from("app_releases")
      .select("*")
      .eq("is_active", true)
      .order("created_at", { ascending: false })
      .limit(1)
      .single();

    if (error || !latestRelease) {
      return new Response(JSON.stringify({ error: "No releases found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Tạo direct download URLs cho website
    const baseUrl = "http://localhost:3000"; // Thay bằng domain website của bạn

    let response: any = {
      latest_version: latestRelease.version,
      notes: latestRelease.release_notes,
      release_date: latestRelease.created_at,
      // Direct download URLs cho website
      download_urls: {
        android: `${baseUrl}/download/android`,
        windows: `${baseUrl}/download/windows`,
      },
    };

    // Cho auto-update trong app, trả về direct file URLs
    if (platform === "android") {
      response.url = latestRelease.android_download_url;
      response.sha256 = latestRelease.android_sha256;
    } else if (platform === "windows") {
      response.url = latestRelease.windows_download_url;
      response.sha256 = latestRelease.windows_sha256;
    }

    return new Response(JSON.stringify(response), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
        "Cache-Control": "public, max-age=300",
      },
    });
  } catch (error) {
    console.error("Function error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

