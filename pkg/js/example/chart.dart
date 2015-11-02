// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library chart;

import 'dart:html';
import 'package:js/js.dart';

@JS()
class Chart {
  external Chart(CanvasRenderingContext2D ctx);

  external dynamic Line(Data data, Options options);
}

@JS()
@anonymous
class Data {
  external List get labels;
  external List<DataSet> get datasets;

  external factory Data({List<String> labels, List<DataSet> datasets});
}

/// Minimal implementation of dataset for line chart
///
/// http://www.chartjs.org/docs/#line-chart-data-structure
@JS()
@anonymous
class DataSet {
  external String get label;
  external String get fillColor;
  external String get strokeColor;
  external String get pointColor;
  external String get pointStrokeColor;
  external String get pointHighlightFill;
  external String get pointHighlightStroke;

  external List<num> get data;

  external factory DataSet(
      {String label,
      String fillColor,
      String strokeColor,
      String pointColor,
      String pointStrokeColor,
      String pointHighlightFill,
      String pointHighlightStroke,
      List<num> data});
}

/// Minimal implementation of options
///
/// http://www.chartjs.org/docs/#getting-started-global-chart-configuration
@JS()
@anonymous
class Options {
  external bool get responsive;

  external factory Options({bool responsive});
}
