"""B4：要件定義書 6.4 のテストケースを、動いている API に送って判定する。

使い方（backend フォルダで）
    1. 別のターミナルで API を起動しておく：uvicorn main:app --reload
    2. このファイルを実行する：python check_cases.py
    3. 各ケースの「実際の結果」と「判定」を、6.4 の表に書き写す

期待値は、いささんの backend/sql/004_test_queries.sql（t403 で確認済み）から写したもの。
DB のデータが変わったら、ここの期待値も直す。
"""

import json
import urllib.error
import urllib.request

API = "http://localhost:8000/api/recommendations"

# (No, 状況, choiceIds, 期待する件数, 期待する上位の商品ID（先頭から順に）, 追加の確認)
CASES = [
    (1, "毎朝お茶を飲む", [101], 10, ["G4315", "G3226", "G4018"], None),
    (2, "料理が好き", [201], 9, ["G5412", "G3327"], None),
    (3, "園芸が趣味", [202], 8, ["G3042"], None),
    (4, "友だちと出かけるのが好き", [401], 9, ["G2103", "G0564", "G1745"], None),
    (
        5,
        "複数の習慣（コーヒーと甘いもの）",
        [102, 104],
        17,
        ["G4901"],
        "score_1st2_rest1",
    ),
    (6, "該当タグがない（特にない）", [404], 0, [], None),
    (7, "同じスコアの商品がある", [101], None, [], "G3226_before_G4018"),
    (8, "回答が一部未入力", [101, 201], 19, [], None),
    (9, "手が荒れる", [301], 9, ["G0088"], None),
    (10, "同じタグを指す選択肢を2つ", [201, 402], 9, [], "max_score_1"),
]


def post(choice_ids: list[int]) -> tuple[int, dict]:
    """API に POST して、(ステータスコード, 返ってきた JSON) を返す"""
    body = json.dumps({"choiceIds": choice_ids}).encode()
    req = urllib.request.Request(
        API, data=body, headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req) as res:
            return res.status, json.load(res)
    except urllib.error.HTTPError as e:
        return e.code, json.load(e)


def check_extra(kind: str | None, results: list[dict]) -> tuple[bool, str]:
    """件数・上位以外の確認"""
    ids = [r["id"] for r in results]
    if kind == "score_1st2_rest1":
        ok = (
            bool(results)
            and results[0]["score"] == 2
            and all(r["score"] == 1 for r in results[1:])
        )
        return ok, "1位がスコア2、2位以降がスコア1"
    if kind == "G3226_before_G4018":
        ok = (
            "G3226" in ids
            and "G4018" in ids
            and ids.index("G3226") < ids.index("G4018")
        )
        return ok, "G3226 が G4018 より上"
    if kind == "max_score_1":
        ok = all(r["score"] == 1 for r in results)
        return ok, "スコアが2にならず全件1"
    return True, ""


def main() -> None:
    passed = 0
    for no, label, ids, want_total, want_top, extra in CASES:
        code, data = post(ids)
        results = data.get("results", [])
        got_top = [r["id"] for r in results[: len(want_top)]]
        checks = [code == 200]
        if want_total is not None:
            checks.append(data.get("total") == want_total)
        checks.append(got_top == want_top)
        extra_ok, extra_label = check_extra(extra, results)
        checks.append(extra_ok)
        ok = all(checks)
        passed += ok

        top3 = "、".join(
            f"{i + 1}位 {r['id']}（スコア{r['score']}）"
            for i, r in enumerate(results[:3])
        )
        print(f"No.{no} {label}  choiceIds={ids}")
        print(f"  実際の結果：{data.get('total')}件。{top3 or '結果は空'}")
        if extra_label:
            print(f"  追加の確認：{extra_label} → {'OK' if extra_ok else 'NG'}")
        print(
            f"  判定：{'○' if ok else '×'}"
            + ("" if ok else f"（期待：{want_total}件、上位 {want_top}）")
        )

    # No.8 の後半：何も選ばずに送ると 422 で入力を促す
    code, data = post([])
    ok = code == 422
    passed += ok
    print(f"No.8 追加 回答が1つもない  choiceIds=[]")
    print(f"  実際の結果：{code}、{data.get('detail')}")
    print(f"  判定：{'○' if ok else '×'}")

    print(f"\n{passed} / {len(CASES) + 1} 件 合格")


if __name__ == "__main__":
    main()
