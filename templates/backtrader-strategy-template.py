"""
PipAtlas backtrader strategy template — https://pipatlas.com/learn/conversions

The same four pieces as the Pine and MQL templates: entry, exit, a stop decided before the
order, and a position size derived from risk. Backtrader is a Python backtesting library;
it does not connect to a broker here and it makes no prediction.

Run:  python3 backtrader-strategy-template.py --csv EURUSD_H1.csv
CSV needs the columns: date, open, high, low, close (a header row is required).
Education only, never financial advice. MIT licensed.
"""
import argparse
import csv
import datetime as dt

try:
    import backtrader as bt
except ImportError:  # keep the file readable without the dependency installed
    bt = None


if bt is not None:

    class PipAtlasTemplate(bt.Strategy):
        params = dict(
            fast=20,          # fast EMA period
            slow=50,          # slow EMA period
            atr_mult=2.0,     # stop distance = ATR x this
            reward_mult=2.0,  # target = stop distance x this
            risk_pct=1.0,     # risk per trade, % of equity
        )

        def __init__(self):
            self.fast_ma = bt.indicators.EMA(self.data.close, period=self.p.fast)
            self.slow_ma = bt.indicators.EMA(self.data.close, period=self.p.slow)
            self.atr = bt.indicators.ATR(self.data, period=14)
            self.crossover = bt.indicators.CrossOver(self.fast_ma, self.slow_ma)
            self.order = None

        def next(self):
            if self.order:                   # one order in flight at a time
                return
            if not self.position:
                if self.crossover[0] > 0:
                    self.enter(long=True)
                elif self.crossover[0] < 0:
                    self.enter(long=False)

        def enter(self, long: bool):
            price = self.data.close[0]
            stop_distance = self.atr[0] * self.p.atr_mult
            if stop_distance <= 0:
                return
            # size from the distance to the stop, not from conviction
            risk_cash = self.broker.getvalue() * self.p.risk_pct / 100.0
            # backtrader sizes in units; the pip value is a broker assumption, stated not hidden
            size = risk_cash / stop_distance
            stop = price - stop_distance if long else price + stop_distance
            target = (price + stop_distance * self.p.reward_mult if long
                      else price - stop_distance * self.p.reward_mult)
            self.order = self.buy(size=size, exectype=bt.Order.Market) if long \
                else self.sell(size=size, exectype=bt.Order.Market)
            self.stop_price, self.target_price = stop, target

        def notify_order(self, order):
            if order.status in (order.Completed, order.Canceled, order.Margin, order.Rejected):
                self.order = None
            if order.status == order.Completed and self.position:
                # attach the stop and target only once the entry has filled
                self.sell(exectype=bt.Order.Stop, price=self.stop_price) if self.position.size > 0 \
                    else self.buy(exectype=bt.Order.Stop, price=self.stop_price)
                self.sell(exectype=bt.Order.Limit, price=self.target_price) if self.position.size > 0 \
                    else self.buy(exectype=bt.Order.Limit, price=self.target_price)


def load_csv(path):
    """Yield (datetime, open, high, low, close) tuples from a header CSV."""
    with open(path, newline="") as fh:
        for row in csv.DictReader(fh):
            stamp = row["date"].strip()
            for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d"):
                try:
                    when = dt.datetime.strptime(stamp, fmt)
                    break
                except ValueError:
                    when = None
            if when is None:
                continue
            yield (when, float(row["open"]), float(row["high"]), float(row["low"]), float(row["close"]))


def main():
    parser = argparse.ArgumentParser(description="PipAtlas backtrader strategy template")
    parser.add_argument("--csv", required=True, help="OHLC CSV with a header row")
    parser.add_argument("--cash", type=float, default=10000.0, help="starting cash (default 10000)")
    args = parser.parse_args()

    if bt is None:
        print("backtrader is not installed. pip install backtrader, then run this again.")
        print("The file still documents the structure: entry, exit, stop before the order, size from risk.")
        for _ in load_csv(args.csv):     # prove the CSV parses even without backtrader
            pass
        return

    cerebro = bt.Cerebro()
    cerebro.addstrategy(PipAtlasTemplate)
    cerebro.adddata(bt.feeds.GenericCSVData(
        dataname=args.csv, dtformat=1, datetime=0, open=1, high=2, low=3, close=4, volume=-1,
        timeframe=bt.TimeFrame.Minutes, compression=60,
    ))
    cerebro.broker.setcash(args.cash)
    cerebro.broker.setcommission(commission=0.0002)   # a stated assumption, not a broker quote
    cerebro.addsizer(bt.sizers.PercentSizer, percents=1)
    print(f"Starting value: {cerebro.broker.getvalue():,.2f}")
    cerebro.run()
    print(f"Final value:    {cerebro.broker.getvalue():,.2f}")
    print("One symbol, one timeframe, one set of cost assumptions: this is one sample, not evidence.")


if __name__ == "__main__":
    main()
