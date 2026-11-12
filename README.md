# PipAtlas Trading Tools — free MT4 / MT5 indicators, EA template & TradingView scripts

Open-source indicators, an EA risk template and Pine Script v5 studies from **[PipAtlas](https://pipatlas.com)** — free forex education, calculators and a plain-English glossary. Every file is readable source code: no compiled binaries, no sign-up, no licence keys.

> **Education only — not financial advice.** Indicators describe past price; none of these files predicts the market or guarantees protection. Read the code, test on a demo account first, and check every number against your broker's contract specifications.

## What's inside

| Tool | MT4 | MT5 | TradingView | What it does |
|---|:-:|:-:|:-:|---|
| **Economic Calendar** | ✅ | ✅ | ✅ | Draws your upcoming events as chart lines, a next-events panel and pre-event alerts (event list from an input string or CSV). |
| **Balance & Equity** | ✅ | ✅ | ✅ | Plots balance and equity forward from attach time, with drawdown-from-peak and margin-level alerts. |
| **Risk Guard (EA template)** | ✅ | ✅ | — | Fixed-fractional position sizing (the "1% rule") for *your own* entry logic. Contains **no** entry signals. |
| **Session Range** | ✅ | ✅ | ✅ | Asia / London / New York high-low boxes. |
| **Fair Value Gaps** | ✅ | ✅ | ✅ | Three-candle imbalance boxes, removed once filled (optional). |
| **ATR Stop** | ✅ | ✅ | ✅ | MT4/MT5: the initial stop width implied by ATR × multiplier. TradingView: chandelier-style ATR trailing levels for longs and shorts. Never places or manages orders. |
| **RSI Alerts** | ✅ | ✅ | ✅ | Terminal / push alert when RSI closes across your levels, one alert per bar per level. |
| **Liquidity Sweep** | — | — | ✅ | Marks bars that trade beyond a reference high/low and close back inside. |
| **Market Structure (BOS / CHoCH)** | — | — | ✅ | Labels swing highs/lows, breaks of structure and changes of character. |
| **Bollinger Bands** | ✅ | ✅ | ✅ | Classic 20/2 bands (population deviation — matches the terminal's own). |
| **Stochastic Oscillator** | ✅ | ✅ | ✅ | %K/%D with 80/20 bands and an optional higher-timeframe trend filter. |
| **Dual MA Cross** | ✅ | ✅ | ✅ | Two moving averages with cross alerts (`pipatlas-dual-ma-defaults.set` included). |
| **Strategy templates** | ✅ | ✅ | ✅ | Starting points for MQL4, MQL5, Pine v5 and Python backtrader (`templates/`). |

Full guides, screenshots and the browser calculators these tools pair with: **[pipatlas.com/library](https://pipatlas.com/library)** · Position size calculator: **[pipatlas.com/tools/position-size-calculator](https://pipatlas.com/tools/position-size-calculator)**

## Install

**MetaTrader 4 / 5**
1. In MetaTrader: *File → Open Data Folder*.
2. Copy indicators into `MQL4/Indicators` (MT4) or `MQL5/Indicators` (MT5); copy the Risk Guard EA into `MQL4/Experts` or `MQL5/Experts`.
3. Open the file in MetaEditor and press **Compile** (F7). Fix nothing blindly — read any compiler message.
4. Restart the terminal or refresh the Navigator, then drag the tool onto a chart.

**TradingView**
1. Open the Pine Editor, create a new indicator, paste the `.pine` source and **Save**.
2. **Add to chart.** Alerts are created from the chart's *Alert* dialog.

## Safety notes

- Run any EA on a **demo account** first. The Risk Guard template sizes positions; it does not decide entries.
- Pip value, contract size and minimum lot differ by broker and symbol (gold, indices and JPY pairs especially). Cross-check with a calculator before trading real money.
- Times in the session and calendar tools follow your chart/server time.

## Licence

MIT — see [`LICENSE`](LICENSE). Copyright © 2026 PipAtlas.

## Contributing

Bug reports and improvements are welcome via GitHub issues and pull requests. Please keep contributions educational: no signal-selling, no guaranteed-profit claims.
