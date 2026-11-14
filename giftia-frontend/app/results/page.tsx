
"use client";

import { useEffect, useState } from "react";

type Product = {
  id: string;
  name: string;
  brand: string;
  category: string;
  price: number;
  rating: number;
  reviewCount: number;
  score: number;
  matchedTags: string[];
  reason: string | null;
};

type RecommendationResponse = {
  total: number;
  results: Product[];
};

export default function ResultsPage() {
  const [data, setData] = useState<RecommendationResponse | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    // ガイド画面が保存した推薦結果を取得
    const saved = sessionStorage.getItem("giftia_recommendations");

    if (!saved) {
      setError("推薦結果がありません。先にガイドに回答してください。");
      return;
    }

    try {
      const parsed = JSON.parse(saved) as RecommendationResponse;

      if (!Array.isArray(parsed.results)) {
        throw new Error("データ形式が正しくありません");
      }

      setData(parsed);
    } catch {
      setError("推薦結果を読み込めませんでした。");
    }
  }, []);

  return (
    <main style={{ padding: "32px", maxWidth: "900px" }}>
      <h1>おすすめギフト</h1>
      <p>回答との一致度が高い順に表示しています。</p>

      {error && <p role="alert">{error}</p>}

      {!error && !data && <p>読み込み中...</p>}

      {data && (
        <>
          <p>候補商品：{data.total}件</p>

          {data.results.length === 0 && (
            <p>条件に合う商品が見つかりませんでした。</p>
          )}

          {data.results.map((product, index) => (
            <div
              key={product.id}
              style={{
                border: "1px solid #ccc",
                borderRadius: "8px",
                padding: "16px",
                marginTop: "16px",
              }}
            >
              <h2>{index + 1}位：{product.name}</h2>
              <p>ブランド：{product.brand}</p>
              <p>価格：{product.price.toLocaleString()}円</p>
              <p>一致スコア：{product.score}点</p>
              <p>
                一致タグ：
                {product.matchedTags.join("、") || "なし"}
              </p>
              {product.reason && (
                <p>推薦理由：{product.reason}</p>
              )}
            </div>
          ))}
        </>
      )}
    </main>
  );
}
