// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

class MyMath {
  @RecordUse()
  static int add(int a, int b) => a + b;

  @RecordUse()
  static int multiply(int a, int b) => a * b;

  @RecordCallToC('double')
  static int double(int a) => a + a;

  @RecordCallToC('square')
  static int square(int a) => a * a;
}

@RecordUse()
class RecordCallToC {
  final String symbol;

  const RecordCallToC(this.symbol);
}
