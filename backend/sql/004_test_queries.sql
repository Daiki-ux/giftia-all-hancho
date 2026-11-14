-- 004_test_queries.sql — 要件定義書 6.4 テストケース用：期待される推薦結果をDBから出すSQL
-- 先に 001〜003 を実行しておく。Workbench で giftia_t403 を選んでから、ケースごとに
--   カーソルをSELECTの中に置いて Cmd + Enter（1本だけ実行）で試す。
-- 全部を一度に実行（Cmd + Shift + Enter）すると、結果が複数のタブに分かれて出る。
--
-- ロジックは API（backend/recommend.py）と同じ：
--   候補　＝ 在庫あり（stock > 0）で、product_scenes が「誕生日」か「母の日」、かつ回答のタグを1つ以上持つ商品
--   score ＝ 回答の選択肢から出る生活場面タグ（重複は1回）と、商品のタグが一致した「種類の数」
--   並び順＝ score の高い順 → 評価（rating）→ レビュー数（review_count）→ 商品ID の昇順
--   販売数（sales_count）は使わない（BR-03「ランキング外でも」と矛盾するため）
-- 各ケースの IN ( ) の数字は、API に送る choiceIds と同じ。
-- タグを付け直した（003 を作り直した）ときは、ここを再実行して、要件定義書 6.4 の期待結果を直す。


-- 参考：選択肢IDと生活場面タグの対応
SELECT c.choice_id, c.choice_text, GROUP_CONCAT(t.life_tag ORDER BY t.life_tag) AS life_tags
FROM choices c
LEFT JOIN choice_life_tags t ON t.choice_id = c.choice_id
GROUP BY c.choice_id, c.choice_text
ORDER BY c.choice_id;

-- =====================================================================
-- ケース1：毎朝お茶を飲む（choiceIds: [101]）
-- 期待：お茶に関連する商品が上位。10件。1位 G4315、2位 G3226、3位 G4018
-- =====================================================================
SELECT
  p.product_id,
  p.product_name,
  p.rating,
  p.review_count,
  COUNT(DISTINCT plt.life_tag)                              AS score,
  GROUP_CONCAT(DISTINCT plt.life_tag ORDER BY plt.life_tag) AS matched_tags
FROM products p
JOIN product_life_tags plt ON plt.product_id = p.product_id
WHERE plt.life_tag IN (
        SELECT life_tag FROM choice_life_tags
        WHERE choice_id IN (101)
      )
  AND p.stock > 0
  AND EXISTS (
        SELECT 1 FROM product_scenes ps
        WHERE ps.product_id = p.product_id
          AND ps.scene_tag IN ('誕生日', '母の日')
      )
GROUP BY p.product_id, p.product_name, p.rating, p.review_count
ORDER BY score DESC, p.rating DESC, p.review_count DESC, p.product_id ASC;

-- =====================================================================
-- ケース2：料理が好き（choiceIds: [201]）
-- 期待：調理に関連する商品が上位。9件。1位 G5412、2位 G3327
-- =====================================================================
SELECT
  p.product_id,
  p.product_name,
  p.rating,
  p.review_count,
  COUNT(DISTINCT plt.life_tag)                              AS score,
  GROUP_CONCAT(DISTINCT plt.life_tag ORDER BY plt.life_tag) AS matched_tags
FROM products p
JOIN product_life_tags plt ON plt.product_id = p.product_id
WHERE plt.life_tag IN (
        SELECT life_tag FROM choice_life_tags
        WHERE choice_id IN (201)
      )
  AND p.stock > 0
  AND EXISTS (
        SELECT 1 FROM product_scenes ps
        WHERE ps.product_id = p.product_id
          AND ps.scene_tag IN ('誕生日', '母の日')
      )
GROUP BY p.product_id, p.product_name, p.rating, p.review_count
ORDER BY score DESC, p.rating DESC, p.review_count DESC, p.product_id ASC;

-- =====================================================================
-- ケース3：園芸が趣味（choiceIds: [202]）
-- 期待：園芸関連の商品が上位。8件。1位 G3042
-- =====================================================================
SELECT
  p.product_id,
  p.product_name,
  p.rating,
  p.review_count,
  COUNT(DISTINCT plt.life_tag)                              AS score,
  GROUP_CONCAT(DISTINCT plt.life_tag ORDER BY plt.life_tag) AS matched_tags
FROM products p
JOIN product_life_tags plt ON plt.product_id = p.product_id
WHERE plt.life_tag IN (
        SELECT life_tag FROM choice_life_tags
        WHERE choice_id IN (202)
      )
  AND p.stock > 0
  AND EXISTS (
        SELECT 1 FROM product_scenes ps
        WHERE ps.product_id = p.product_id
          AND ps.scene_tag IN ('誕生日', '母の日')
      )
GROUP BY p.product_id, p.product_name, p.rating, p.review_count
ORDER BY score DESC, p.rating DESC, p.review_count DESC, p.product_id ASC;

-- =====================================================================
-- ケース4：友だちと出かけるのが好き（choiceIds: [401]）
-- 期待：お出かけ用品が上位。9件。1位 G2103、2位 G0564、3位 G1745
-- =====================================================================
SELECT
  p.product_id,
  p.product_name,
  p.rating,
  p.review_count,
  COUNT(DISTINCT plt.life_tag)                              AS score,
  GROUP_CONCAT(DISTINCT plt.life_tag ORDER BY plt.life_tag) AS matched_tags
FROM products p
JOIN product_life_tags plt ON plt.product_id = p.product_id
WHERE plt.life_tag IN (
        SELECT life_tag FROM choice_life_tags
        WHERE choice_id IN (401)
      )
  AND p.stock > 0
  AND EXISTS (
        SELECT 1 FROM product_scenes ps
        WHERE ps.product_id = p.product_id
          AND ps.scene_tag IN ('誕生日', '母の日')
      )
GROUP BY p.product_id, p.product_name, p.rating, p.review_count
ORDER BY score DESC, p.rating DESC, p.review_count DESC, p.product_id ASC;

-- =====================================================================
-- ケース5：複数の習慣がある（コーヒーと甘いもの）（choiceIds: [102, 104]）
-- 期待：17件。1位 G4901（score 2）、2位以降は score 1
-- =====================================================================
SELECT
  p.product_id,
  p.product_name,
  p.rating,
  p.review_count,
  COUNT(DISTINCT plt.life_tag)                              AS score,
  GROUP_CONCAT(DISTINCT plt.life_tag ORDER BY plt.life_tag) AS matched_tags
FROM products p
JOIN product_life_tags plt ON plt.product_id = p.product_id
WHERE plt.life_tag IN (
        SELECT life_tag FROM choice_life_tags
        WHERE choice_id IN (102, 104)
      )
  AND p.stock > 0
  AND EXISTS (
        SELECT 1 FROM product_scenes ps
        WHERE ps.product_id = p.product_id
          AND ps.scene_tag IN ('誕生日', '母の日')
      )
GROUP BY p.product_id, p.product_name, p.rating, p.review_count
ORDER BY score DESC, p.rating DESC, p.review_count DESC, p.product_id ASC;

-- =====================================================================
-- ケース6：該当タグがない（「特にない」）（choiceIds: [403]）
-- 期待：0件（行が1つも出ない。エラーにならない）
-- =====================================================================
SELECT
  p.product_id,
  p.product_name,
  p.rating,
  p.review_count,
  COUNT(DISTINCT plt.life_tag)                              AS score,
  GROUP_CONCAT(DISTINCT plt.life_tag ORDER BY plt.life_tag) AS matched_tags
FROM products p
JOIN product_life_tags plt ON plt.product_id = p.product_id
WHERE plt.life_tag IN (
        SELECT life_tag FROM choice_life_tags
        WHERE choice_id IN (403)
      )
  AND p.stock > 0
  AND EXISTS (
        SELECT 1 FROM product_scenes ps
        WHERE ps.product_id = p.product_id
          AND ps.scene_tag IN ('誕生日', '母の日')
      )
GROUP BY p.product_id, p.product_name, p.rating, p.review_count
ORDER BY score DESC, p.rating DESC, p.review_count DESC, p.product_id ASC;

-- =====================================================================
-- ケース7：同じスコアの商品がある（choiceIds: [101]）
-- 期待：G3226 と G4018 は評価4.8・レビュー4件で同点 → 商品IDの小さい G3226 が先
-- =====================================================================
SELECT
  p.product_id,
  p.product_name,
  p.rating,
  p.review_count,
  COUNT(DISTINCT plt.life_tag)                              AS score,
  GROUP_CONCAT(DISTINCT plt.life_tag ORDER BY plt.life_tag) AS matched_tags
FROM products p
JOIN product_life_tags plt ON plt.product_id = p.product_id
WHERE plt.life_tag IN (
        SELECT life_tag FROM choice_life_tags
        WHERE choice_id IN (101)
      )
  AND p.stock > 0
  AND EXISTS (
        SELECT 1 FROM product_scenes ps
        WHERE ps.product_id = p.product_id
          AND ps.scene_tag IN ('誕生日', '母の日')
      )
GROUP BY p.product_id, p.product_name, p.rating, p.review_count
ORDER BY score DESC, p.rating DESC, p.review_count DESC, p.product_id ASC;

-- =====================================================================
-- ケース8：回答が一部未入力（choiceIds: [101, 201]）
-- 期待：19件（お茶10件＋料理9件）。※回答が1つもない [] はAPIで422になる（SQLでは試せない）
-- =====================================================================
SELECT
  p.product_id,
  p.product_name,
  p.rating,
  p.review_count,
  COUNT(DISTINCT plt.life_tag)                              AS score,
  GROUP_CONCAT(DISTINCT plt.life_tag ORDER BY plt.life_tag) AS matched_tags
FROM products p
JOIN product_life_tags plt ON plt.product_id = p.product_id
WHERE plt.life_tag IN (
        SELECT life_tag FROM choice_life_tags
        WHERE choice_id IN (101, 201)
      )
  AND p.stock > 0
  AND EXISTS (
        SELECT 1 FROM product_scenes ps
        WHERE ps.product_id = p.product_id
          AND ps.scene_tag IN ('誕生日', '母の日')
      )
GROUP BY p.product_id, p.product_name, p.rating, p.review_count
ORDER BY score DESC, p.rating DESC, p.review_count DESC, p.product_id ASC;

-- =====================================================================
-- ケース9：手が荒れる（choiceIds: [301]）
-- 期待：手肌ケアの商品が上位。9件。1位 G0088
-- =====================================================================
SELECT
  p.product_id,
  p.product_name,
  p.rating,
  p.review_count,
  COUNT(DISTINCT plt.life_tag)                              AS score,
  GROUP_CONCAT(DISTINCT plt.life_tag ORDER BY plt.life_tag) AS matched_tags
FROM products p
JOIN product_life_tags plt ON plt.product_id = p.product_id
WHERE plt.life_tag IN (
        SELECT life_tag FROM choice_life_tags
        WHERE choice_id IN (301)
      )
  AND p.stock > 0
  AND EXISTS (
        SELECT 1 FROM product_scenes ps
        WHERE ps.product_id = p.product_id
          AND ps.scene_tag IN ('誕生日', '母の日')
      )
GROUP BY p.product_id, p.product_name, p.rating, p.review_count
ORDER BY score DESC, p.rating DESC, p.review_count DESC, p.product_id ASC;

-- =====================================================================
-- ケース10：同じタグを指す選択肢を2つ選ぶ（choiceIds: [201, 402]）
-- 期待：9件。score は2にならず1のまま
-- =====================================================================
SELECT
  p.product_id,
  p.product_name,
  p.rating,
  p.review_count,
  COUNT(DISTINCT plt.life_tag)                              AS score,
  GROUP_CONCAT(DISTINCT plt.life_tag ORDER BY plt.life_tag) AS matched_tags
FROM products p
JOIN product_life_tags plt ON plt.product_id = p.product_id
WHERE plt.life_tag IN (
        SELECT life_tag FROM choice_life_tags
        WHERE choice_id IN (201, 402)
      )
  AND p.stock > 0
  AND EXISTS (
        SELECT 1 FROM product_scenes ps
        WHERE ps.product_id = p.product_id
          AND ps.scene_tag IN ('誕生日', '母の日')
      )
GROUP BY p.product_id, p.product_name, p.rating, p.review_count
ORDER BY score DESC, p.rating DESC, p.review_count DESC, p.product_id ASC;
