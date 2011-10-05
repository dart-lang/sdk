class Result {
  int get runs() { return _sorted.length; }

  double get sum() {
    double result = 0.0;
    _sorted.forEach((double e) { result += e; });
    return result;
  }

  double get min() { return _sorted[0]; }
  double get max() { return _sorted[runs - 1]; }

  double get mean() { return sum / runs; }

  double get median() {
    return (runs % 2 == 0) ?
        (_sorted[runs ~/ 2] + _sorted[runs ~/ 2 + 1]) / 2 : _sorted[runs ~/ 2];
  }

  double get variance() {
    double m = mean;
    double result = 0.0;
    _sorted.forEach((double e) { result += Math.pow(e - m, 2.0); });
    return result / (runs - 1);
  }

  double get deviation() { return Math.sqrt(variance); }

  // Compute Standard Errors Mean
  double get sem() { return (deviation / Math.sqrt(runs)) * T_DISTRIBUTION; }

  double get error() { return (sem / mean) * 100; }

  // TODO: Implement writeOn.
  String toString() {
    return '[Result: mean = ${mean}]';
  }

  factory Result(Array<double> runsPerSecond) {
    runsPerSecond.sort(int _(double a, double b) => a.compareTo(b));
    return new Result._internal(runsPerSecond);
  }

  Result._internal(this._sorted) {}

  Array<double> _sorted;

  // Populated from: http://www.medcalc.be/manual/t-distribution.php
  // 95% confidence for N - 1 = 4
  static final double T_DISTRIBUTION = 2.776;
}
