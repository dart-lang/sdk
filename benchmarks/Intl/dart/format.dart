// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Micro-benchmarks for formatting with Intl.

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:intl/intl.dart';

var DATES = List.generate(
  100,
  (i) => DateTime.fromMillisecondsSinceEpoch(1417666640631 - i * 1649837618),
);

const DATE_FORMATS = ['Hm', 'MMM yyyy', 'MMM dd, yyyy'];

var NUMBERS = [
  12.345,
  1.2345,
  -12.345,
  20000000.1,
  -200000001.2,
  ...List.generate(90, (i) => (i - 45) * i * 0.716739 + 0.21),
];

const NUMBER_FORMATS = ['\$#,##0.0', '#%', '#,##0', '#.##%'];

const LOCALE = 'en_US';

var g;

class Base extends BenchmarkBase {
  Base(name, variant) : super('Intl.$name.format.$variant');

  var formatters;
  var data;

  @override
  void run() {
    for (var datum in data) {
      for (var formatter in formatters) {
        g = formatter.format(datum);
      }
    }
  }
}

class DateBenchmark extends Base {
  DateBenchmark() : super('DateFormat', 'oneshot');

  @override
  void setup() {
    formatters = DATE_FORMATS.map((s) => DateFormat(s, LOCALE));
    data = DATES;
  }
}

class DateBenchmarkReused extends Base {
  DateBenchmarkReused() : super('DateFormat', 'reused');

  @override
  void setup() {
    formatters = DATE_FORMATS.map((s) => DateFormat(s, LOCALE)).toList();
    data = DATES;
  }
}

class NumberBenchmark extends Base {
  NumberBenchmark() : super('NumberFormat', 'oneshot');

  @override
  void setup() {
    formatters = NUMBER_FORMATS.map((s) => NumberFormat(s, LOCALE));
    data = NUMBERS;
  }
}

class NumberBenchmarkReused extends Base {
  NumberBenchmarkReused() : super('NumberFormat', 'reused');

  @override
  void setup() {
    formatters = NUMBER_FORMATS.map((s) => NumberFormat(s, LOCALE)).toList();
    data = NUMBERS;
  }
}

void main() {
  DateBenchmark().report();
  DateBenchmarkReused().report();
  NumberBenchmark().report();
  NumberBenchmarkReused().report();

  if (g is! String) throw 'Error';
}
