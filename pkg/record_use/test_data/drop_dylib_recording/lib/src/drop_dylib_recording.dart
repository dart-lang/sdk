// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import 'drop_dylib_recording_bindings.dart' as bindings;

class MyMath {
  @RecordUse()
  static int add(int a, int b) => bindings.add(a, b);

  @RecordUse()
  static int multiply(int a, int b) => bindings.multiply(a, b);

  @RecordCallToC('add')
  static int double(int a) => bindings.add(a, a);

  @RecordCallToC('multiply')
  static int square(int a) => bindings.multiply(a, a);
}

@RecordUse()
class RecordCallToC {
  final String symbol;

  const RecordCallToC(this.symbol);
}
