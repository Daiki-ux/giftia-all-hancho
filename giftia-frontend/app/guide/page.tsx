
"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

type Choice = {
  id: number;
  text: string;
};

type Question = {
  id: number;
  order: number;
  text: string;
  choices: Choice[];
};

type RecommendationResponse = {
  total: number;
  results: unknown[];
};

export default function GuidePage() {
  const router = useRouter();

  const [questions, setQuestions] = useState<Question[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [currentIndex, setCurrentIndex] = useState(0);
  const [answers, setAnswers] = useState<Record<number, number>>({});

  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState("");
  const [resultCount, setResultCount] = useState<number | null>(null);

  // 質問APIから質問と選択肢を取得
  useEffect(() => {
    async function loadQuestions() {
      try {
        const response = await fetch(
          "http://localhost:8000/api/questions"
        );

        if (!response.ok) {
          throw new Error("質問の取得に失敗しました");
        }

        const data = await response.json();
        setQuestions(data.questions);
      } catch {
        setError("質問を取得できませんでした。");
      } finally {
        setLoading(false);
      }
    }

    loadQuestions();
  }, []);

  const question = questions[currentIndex];
  const answeredCount = Object.keys(answers).length;

  // 5問の回答を推薦APIに送信
  async function submitAnswers() {
    if (
      questions.length === 0 ||
      questions.some((q) => answers[q.id] === undefined)
    ) {
      setSubmitError("すべての質問に回答してください。");
      return;
    }

    setSubmitting(true);
    setSubmitError("");
    setResultCount(null);

    try {
      // 質問順に選択肢IDを並べる
      const choiceIds = questions.map((q) => answers[q.id]);

      const response = await fetch(
        "http://localhost:8000/api/recommendations",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ choiceIds }),
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          typeof data.detail === "string"
            ? data.detail
            : `推薦APIでエラーが発生しました（HTTP ${response.status}）`
        );
      }

      const result = data as RecommendationResponse;

      // 推薦結果を同じタブ内に保存
      sessionStorage.setItem(
        "giftia_recommendations",
        JSON.stringify(result)
      );

      setResultCount(result.total);

      // 保存が成功したら結果画面へ自動遷移
      router.push("/results");

    } catch (err) {
      setSubmitError(
        err instanceof Error
          ? err.message
          : "推薦結果を取得できませんでした。"
      );
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main style={{ padding: "32px", maxWidth: "800px" }}>
      <h1>思い出しガイド</h1>
      <p>お母さんへのギフト選びをお手伝いします。</p>

      {loading && <p>質問を読み込み中...</p>}
      {error && <p role="alert">{error}</p>}

      {!loading && !error && questions.length === 0 && (
        <p>質問がありません。</p>
      )}

      {!loading && !error && question && (
        <section>
          <p>
            {currentIndex + 1} / {questions.length} 問目
          </p>

          <p>
            回答済み：{answeredCount} / {questions.length} 問
          </p>

          <h2>
            Q{question.order}. {question.text}
          </h2>

          {question.choices.map((choice) => (
            <label
              key={choice.id}
              style={{
                display: "block",
                padding: "12px",
                margin: "12px 0",
                border: "1px solid #ccc",
                borderRadius: "8px",
                cursor: "pointer",
              }}
            >
              <input
                type="radio"
                name={`question-${question.id}`}
                checked={answers[question.id] === choice.id}
                onChange={() => {
                  setAnswers((prev) => ({
                    ...prev,
                    [question.id]: choice.id,
                  }));
                  setResultCount(null);
                }}
              />
              {" "}{choice.text}
            </label>
          ))}

          <div
            style={{
              display: "flex",
              gap: "16px",
              marginTop: "24px",
            }}
          >
            <button
              type="button"
              disabled={currentIndex === 0 || submitting}
              onClick={() => setCurrentIndex(currentIndex - 1)}
            >
              戻る
            </button>

            {currentIndex < questions.length - 1 && (
              <button
                type="button"
                disabled={
                  answers[question.id] === undefined || submitting
                }
                onClick={() => setCurrentIndex(currentIndex + 1)}
              >
                次へ
              </button>
            )}
          </div>

          {currentIndex === questions.length - 1 &&
            answeredCount === questions.length && (
              <div style={{ marginTop: "24px" }}>
                <button
                  type="button"
                  disabled={submitting}
                  onClick={submitAnswers}
                >
                  {submitting
                    ? "おすすめを検索中..."
                    : "おすすめギフトを探す"}
                </button>

                {submitError && (
                  <p role="alert">{submitError}</p>
                )}

                {resultCount !== null && (
                  <p>
                    推薦API接続成功！
                    候補商品を{resultCount}件取得しました。
                  </p>
                )}
              </div>
            )}
        </section>
      )}
    </main>
  );
}
