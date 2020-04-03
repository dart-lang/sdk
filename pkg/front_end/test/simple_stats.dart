import 'dart:math' as math;

class SimpleTTestStat {
  static TTestResult ttest(List<int> a, List<int> b) {
    int aSum = a.reduce((value, element) => (value + element));
    int bSum = b.reduce((value, element) => (value + element));
    int aCount = a.length;
    int bCount = b.length;
    double aMean = aSum / aCount;
    double bMean = bSum / bCount;
    double aVariance = variance(a);
    double bVariance = variance(b);
    double pooledStandardDeviation = math.sqrt((aVariance + bVariance) / 2);
    double pooledSampleStandardError =
        pooledStandardDeviation * math.sqrt(1 / aCount + 1 / bCount);
    double diffMean = aMean - bMean;

    // Difference in population mean with confidence interval:
    // μ1 - μ2 = (M1 - M2) ± t * standardError
    double confidence =
        tTableTwoTails_0_05(aCount + bCount - 2) * pooledSampleStandardError;

    if (confidence < diffMean.abs()) {
      double percentDiff = diffMean * 100 / bMean;
      double percentDiffConfidence = confidence * 100 / bMean;
      return new TTestResult(
          true, percentDiff, percentDiffConfidence, diffMean, confidence);
    } else {
      return new TTestResult(false, 0, 0, 0, 0);
    }
  }

  static double variance(List<int> data) {
    int sum = data.reduce((value, element) => (value + element));
    int count = data.length;
    double average = sum / count;

    double diffSquareSum = 0;
    for (int value in data) {
      double diff = value - average;
      double squared = diff * diff;
      diffSquareSum += squared;
    }

    double variance = diffSquareSum / (count - 1);
    return variance;
  }

  static double tTableTwoTails_0_05(int value) {
    // TODO: Maybe actually calculate this? I haven't looked that up.
    // These numbers are from google sheets "=TINV(0.05, value)"
    if (value < 1) throw "value has to be > 0";
    if (value == 1) return 12.70620474;
    if (value == 2) return 4.30265273;
    if (value == 3) return 3.182446305;
    if (value == 4) return 2.776445105;
    if (value == 5) return 2.570581836;
    if (value == 6) return 2.446911851;
    if (value == 7) return 2.364624252;
    if (value == 8) return 2.306004135;
    if (value == 9) return 2.262157163;
    if (value == 10) return 2.228138852;
    if (value == 11) return 2.20098516;
    if (value == 12) return 2.17881283;
    if (value == 13) return 2.160368656;
    if (value == 14) return 2.144786688;
    if (value == 15) return 2.131449546;
    if (value == 16) return 2.119905299;
    if (value == 17) return 2.109815578;
    if (value == 18) return 2.10092204;
    if (value == 19) return 2.093024054;
    if (value == 20) return 2.085963447;
    if (value <= 30) return 2.042272456;
    if (value <= 40) return 2.02107539;
    if (value <= 50) return 2.008559112;
    if (value <= 60) return 2.000297822;
    if (value <= 70) return 1.994437112;
    if (value <= 80) return 1.990063421;
    if (value <= 80) return 1.990063421;
    if (value <= 90) return 1.986674541;
    if (value <= 100) return 1.983971519;
    if (value <= 150) return 1.975905331;
    if (value <= 200) return 1.971896224;
    if (value <= 250) return 1.969498393;
    if (value <= 500) return 1.964719837;
    if (value <= 1000) return 1.962339081;
    if (value <= 10000) return 1.96020124;
    if (value <= 100000) return 1.959987708;
    if (value <= 1000000) return 1.959966357;
    return 1.959964228;
  }
}

class TTestResult {
  final bool significant;
  final double percentDiff;
  final double percentDiffConfidence;
  final double diff;
  final double confidence;

  TTestResult(this.significant, this.percentDiff, this.percentDiffConfidence,
      this.diff, this.confidence);

  String toString() {
    if (significant) {
      double leastConfidentChange;
      if (diff < 0) {
        leastConfidentChange = diff + confidence;
      } else {
        leastConfidentChange = diff - confidence;
      }
      return "TTestResult[significant: "
          "${_format(percentDiff)}% +/- ${_format(percentDiffConfidence)}% "
          "(${_format(diff)} +/- ${_format(confidence)}) "
          "(at least ${_format(leastConfidentChange)})]";
    } else {
      return "TTestResult[not significant]";
    }
  }

  String _format(double d) {
    return d.toStringAsFixed(2);
  }
}
