// Download page: /download/[platform]
// Hiển thị trang download với thông tin release

import { useRouter } from "next/router";
import { useEffect, useState } from "react";

export default function DownloadPage() {
  const router = useRouter();
  const { platform } = router.query;
  const [releaseInfo, setReleaseInfo] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!platform) return;

    const fetchReleaseInfo = async () => {
      try {
        const response = await fetch(`/api/download/${platform}`);

        if (!response.ok) {
          throw new Error("Failed to fetch release info");
        }

        // Nếu được redirect, download sẽ tự động bắt đầu
        if (response.redirected) {
          window.location.href = response.url;
        }

        const data = await response.json();
        setReleaseInfo(data);
        setLoading(false);
      } catch (err) {
        setError(err.message);
        setLoading(false);
      }
    };

    fetchReleaseInfo();
  }, [platform]);

  if (loading) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1>⏳ Preparing download...</h1>
          <p>Your download will start shortly.</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1>❌ Download Failed</h1>
          <p>{error}</p>
          <button onClick={() => router.reload()} style={styles.button}>
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1>🎉 Download Started!</h1>
        <p>
          <strong>Alliance Messenger</strong> {releaseInfo?.version || ""}
        </p>
        <p>Platform: {platform === "android" ? "📱 Android" : "💻 Windows"}</p>

        {releaseInfo?.notes && (
          <div style={styles.notes}>
            <h3>Release Notes:</h3>
            <pre>{releaseInfo.notes}</pre>
          </div>
        )}

        <div style={styles.actions}>
          <button
            onClick={() => (window.location.href = `/api/download/${platform}`)}
            style={styles.button}
          >
            Download Again
          </button>
        </div>
      </div>
    </div>
  );
}

const styles = {
  container: {
    minHeight: "100vh",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#0f0f0f",
    fontFamily: "system-ui, -apple-system, sans-serif",
    padding: "20px",
  },
  card: {
    backgroundColor: "#1a1a1a",
    padding: "40px",
    borderRadius: "12px",
    maxWidth: "600px",
    width: "100%",
    color: "#ffffff",
    textAlign: "center",
  },
  notes: {
    marginTop: "30px",
    textAlign: "left",
    backgroundColor: "#0a0a0a",
    padding: "20px",
    borderRadius: "8px",
    maxHeight: "300px",
    overflow: "auto",
  },
  actions: {
    marginTop: "30px",
  },
  button: {
    backgroundColor: "#0070f3",
    color: "white",
    border: "none",
    padding: "12px 24px",
    borderRadius: "6px",
    fontSize: "16px",
    cursor: "pointer",
    fontWeight: "500",
  },
};
