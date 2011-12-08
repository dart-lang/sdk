// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioParam {

  num get defaultValue();

  num get maxValue();

  num get minValue();

  String get name();

  int get units();

  num get value();

  void set value(num value);

  void cancelScheduledValues(num startTime);

  void exponentialRampToValueAtTime(num value, num time);

  void linearRampToValueAtTime(num value, num time);

  void setTargetValueAtTime(num targetValue, num time, num timeConstant);

  void setValueAtTime(num value, num time);

  void setValueCurveAtTime(Float32Array values, num time, num duration);
}
