# 翻譯引擎與參考來源

Lingo Prism 0.3 使用 Swift URLSession 原生實作以下協定。參考 Pot 的服務端點、請求格式、語言對應與回應結構，沒有把 Pot 的 JavaScript、UI、圖示或建置套件加入 App。Pot 儲存庫標示為 GPL-3.0；以下連結保留參考來源。

## 選項與實測

2026-10-21 於這台 Mac，以 App 相同的 Swift 網路實作與固定文字 `Hello, welcome to Lingo Prism.` 測試：

| 選項 | 使用者須提供 | 實測結果 |
| --- | --- | --- |
| Google（預設） | 不需金鑰 | 成功回傳繁中；另外測試兩行 OCR 對應 |
| Bing | 不需金鑰 | 成功回傳繁中，透過 Bing 網頁短期 token |
| Yandex | 不需金鑰 | 成功回傳中文，以本機文字轉換保留繁體目標 |
| DeepL | 不需金鑰 | 新端點回傳 404，舊 JSON-RPC 端點成功回傳繁中 |
| Ollama | 自己的 URL、模型 | 保留原有實作；本次未驗證使用者的伺服器 |

此表是一次實測記錄，不代表公共服務的持續可用性。設定裡的「測試翻譯」可確認當下狀態。既有 Ollama 選擇與螢幕覆蓋設定會保留。

## Pot 如何免金鑰接入

- **Google**：`/translate_a/single`，`client=gtx`，讀取陣列內的翻譯片段。Lingo Prism 使用實測可用的 `translate.googleapis.com` 根位址；逐行請求和拼接句子片段，避免譯文對到錯誤的畫面位置。[Pot Google 原始碼](https://github.com/pot-app/pot-desktop/blob/594d32ede96acd106b0256deaa8bb440ffcdff40/src/services/translate/google/index.jsx)
- **Bing**：先呼叫 `edge.microsoft.com/translate/auth` 取得短期 bearer token，再使用 Edge Translator。該 token 端點實測 404；Lingo Prism 在 404／410 時讀取 Bing Translator 頁面的短期 token 與頁面識別，使用同一供應商的 `/ttranslatev3` 完成翻譯。[Pot Bing 原始碼](https://github.com/pot-app/pot-desktop/blob/594d32ede96acd106b0256deaa8bb440ffcdff40/src/services/translate/bing/index.jsx)
- **Yandex**：以 form body 呼叫 `translate.yandex.net/api/v1/tr.json/translate`，帶入隨機請求識別與 `srv=android`，不需要使用者金鑰。繁簡在此端點都對應 `zh`；Lingo Prism 會在本機轉換為所選文字系統。[Pot Yandex 原始碼](https://github.com/pot-app/pot-desktop/blob/594d32ede96acd106b0256deaa8bb440ffcdff40/src/services/translate/yandex/index.jsx)
- **DeepL**：Pot master 使用 `www2.deepl.com/jsonrpc`；PR #1290 提供 `oneshot-free.www.deepl.com/v1/storefront/translate` 與 `zh-Hant` 的新接法。Lingo Prism 支援新格式，遇 404／410 時才試舊格式，舊格式的中文結果在本機轉繁簡。[Pot DeepL 原始碼](https://github.com/pot-app/pot-desktop/blob/594d32ede96acd106b0256deaa8bb440ffcdff40/src/services/translate/deepl/index.jsx)、[PR #1290](https://github.com/pot-app/pot-desktop/pull/1290)

Pot 中的百度、彩雲、有道、小牛與其他商用 API 並非都免金鑰；不能僅因出現在 Pot 的選單中就當成無需申請的免費服務。Bing／劍橋詞典則偏向單字釋義，未當作螢幕整句翻譯引擎加入。

## 資料與錯誤處理

各引擎只接收辨識後的文字。Bing token 只供本次翻譯使用，不寫入設定。沒有跨供應商自動降級。429、403、格式改變、行數不符、網路與憑證錯誤均會回報；TLS 憑證驗證保持開啟。
