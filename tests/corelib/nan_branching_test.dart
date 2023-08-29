// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma("vm:never-inline")
@pragma("dart2js:noInline")
double hiddenZero() => double.parse("0.0");

@pragma("vm:never-inline")
@pragma("dart2js:noInline")
double hiddenNaN() => double.parse("NaN");

void main() {
  if (hiddenZero() == hiddenNaN()) throw "==";
  if (hiddenZero() != hiddenNaN()) {} else throw "!=";
  if (hiddenZero()  < hiddenNaN()) throw "<";
  if (hiddenZero() <= hiddenNaN()) throw "<=";
  if (hiddenZero()  > hiddenNaN()) throw ">";
  if (hiddenZero() >= hiddenNaN()) throw ">=";

  if (hiddenNaN() == hiddenNaN()) throw "==";
  if (hiddenNaN() != hiddenNaN()) {} else throw "!=";
  if (hiddenNaN()  < hiddenNaN()) throw "<";
  if (hiddenNaN() <= hiddenNaN()) throw "<=";
  if (hiddenNaN()  > hiddenNaN()) throw ">";
  if (hiddenNaN() >= hiddenNaN()) throw ">=";

  if (hiddenNaN() == hiddenZero()) throw "==";
  if (hiddenNaN() != hiddenZero()) {} else throw "!=";
  if (hiddenNaN()  < hiddenZero()) throw "<";
  if (hiddenNaN() <= hiddenZero()) throw "<=";
  if (hiddenNaN()  > hiddenZero()) throw ">";
  if (hiddenNaN() >= hiddenZero()) throw ">=";
}
