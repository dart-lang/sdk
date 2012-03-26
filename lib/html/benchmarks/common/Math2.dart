// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Various math-related utility functions.

class Math2 {
  /// Computes the geometric mean of a set of numbers.
  /// [minNumber] is optional (defaults to 0.001) anything smaller than this
  /// will be changed to this value, eliminating infinite results.
  static double geometricMean(Array<double> numbers,
                              [double minNumber = 0.001]) {
    double log = 0.0;
    int nNumbers = 0;
    for (int i = 0, n = numbers.length; i < n; i++) {
      double number = numbers[i];
      if (number < minNumber) {
        number = minNumber;
      }
      nNumbers++;
      log += Math.log(number);
    }

    return nNumbers > 0 ? Math.pow(Math.E, log / nNumbers) : 0.0;
  }

  static int round(double d) {
    return d.round().toInt();
  }

  static int floor(double d) {
    return d.floor().toInt();
  }

  // TODO (olonho): use d.toStringAsFixed(precision) when implemented by DartVM
  static String toStringAsFixed(num d, int precision) {
    String dStr = d.toString();
    int pos = dStr.indexOf('.', 0);
    int end = pos < 0 ? dStr.length : pos + precision;
    if (precision > 0) {
      end++;
    }
    if (end > dStr.length) {
      end = dStr.length;
    }

    return dStr.substring(0, end);
  }
}
