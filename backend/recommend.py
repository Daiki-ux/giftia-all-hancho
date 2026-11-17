"""思い出しガイドの質問と、商品推薦（Phase1）

現在の版（B2）：いささん作成のDBから読み込む
    使うテーブル：questions / choices / choice_life_tags / product_life_tags / products_scenes / products
    関数の名前と、返す形はB1のダミーから変えない（main.py と画面を直さずに済むように）。

順位のルール（要件定義書 FR-01・6.2）
    スコア　＝ 回答から出てきた生活場面タグと、商品のタグが一致した「種類の数」
              （別の選択肢が同じタグを指しても1回と数える）
    候補　　＝ 生活場面タグに「誕生日」か「母の日」の行を1つ以上持つ、在庫があり（stock > 0）、スコアが1以上のもの
    並び順　＝ スコアの高い順 → 評価（rating）の高い順 → レビュー数の多い順 → 商品IDの昇順
              販売数（sales_count）は使わない（BR-03「ランキング外でも」と矛盾するため）
"""

from database import fetch_all

# 候補に用途タグ（product_scenes.scene_tagの値）。DBの表記と1文字でも違うと0件になる。
TARGET_SCENES = ("誕生日", "母の日")


def placeholders(n: int) -> str:
    """IN(...)の中に並べる%sをn個作る。例：3 → "%s, %s, %s"
    値は文字列に繋げず、必ずparamsで渡す（入力次第でDBを壊されるのを防ぐため）"""
    return ", ".join(["%s"] * n)


def get_questions() -> list[dict]:
    """質問と選択肢を表示順に返す（画面に渡す形。tagsは画面に見せないので外す）"""
    row = fetch_all(
        """SELECT q.question_id, q.question_text, q.display_order, c.choice_id, c.choice_text
            FROM questions q
            JOIN choices c ON c.question_id = q.question_id
            ORDER BY q.display_order, c.choice_id"""
    )

    # DBは「選択肢1つにつき1行」で返ってくるので、質問ごとにまとめ直す
    questions: list[dict] = []
    for r in row:
        if not questions or questions[-1]["id"] != r["question_id"]:
            questions.append(
                {
                    "id": r["question_id"],
                    "order": r["display_order"],
                    "text": r["question_text"],
                    "choices": [],
                }
            )
        questions[-1]["choices"].append(
            {"id": r["choice_id"], "text": r["choice_text"]}
        )
    return questions


def recommend(choice_ids: list[int]) -> list[dict]:
    """選ばれた選択肢IDから、推薦する商品を順位通りに返す。返す行はDBの列名（product_idなど）に、scoreとmatched_tagsを足したもの"""
    # 　①選択肢ID　→　生活場面タグ（重複は1つにまとめて回答した順番はたもつ）。知らないIDは無視する。
    tag_rows = fetch_all(
        f"SELECT choice_id, life_tag FROM choice_life_tags WHERE choice_id IN ({placeholders(len(choice_ids))})",
        tuple(choice_ids),
    )
    answer_tags: list[str] = []
    for cid in choice_ids:
        for r in tag_rows:
            if r["choice_id"] == cid and r["life_tag"] not in answer_tags:
                answer_tags.append(r["life_tag"])
    if (
        not answer_tags
    ):  # 「特にない」だけを選んだ場合など。IN()はSQLの文法エラーになるので、ここで0件を返す
        return []

    # ②在庫がある商品ごとに一致したタグの種類の数をスコアにして順位通りに並べる。0点の商品は候補にしない。
    # product_scenesは1商品に複数行ある（誕生日と母の日等）。JOINすると商品が2回数えられるので、EXISTSで「誕生日か母の日を1行でも持つかだけ調べる」
    # COUNT(DISTINCT...)で同じタグを2回数えないようにする
    rows = fetch_all(
        f"""SELECT p.product_id, p.product_name, p.category, p.brand, p.price, p.rating, p.review_count,
                    COUNT(DISTINCT pl.life_tag) AS score,
                    GROUP_CONCAT(DISTINCT pl.life_tag SEPARATOR '\\t') AS matched
            FROM products p
            JOIN product_life_tags pl ON pl.product_id = p.product_id
            WHERE pl.life_tag IN ({placeholders(len(answer_tags))})
                AND p.stock > 0
                AND EXISTS (SELECT 1 FROM product_scenes ps WHERE ps.product_id = p.product_id AND ps.scene_tag IN ({placeholders(len(TARGET_SCENES))}))
            GROUP BY p.product_id, p.product_name, p.category, p.brand, p.price, p.rating, p.review_count
            ORDER BY score DESC, p.rating DESC, p.review_count DESC, p.product_id ASC""",
        (*answer_tags, *TARGET_SCENES),
    )

    # 一致したタグを回答した順番に並べなおしてリストにする
    for r in rows:
        matched = set(r.pop("matched").split("\t"))
        r["matched_tags"] = [t for t in answer_tags if t in matched]
    return rows
