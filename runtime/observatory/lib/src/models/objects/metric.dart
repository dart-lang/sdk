// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class Metric {
  String get id;
  String get name;
  String get description;
}

abstract class MetricSample {
  double get value;
  DateTime get time;
}
