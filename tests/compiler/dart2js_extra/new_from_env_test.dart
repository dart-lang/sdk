// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/// Dart2js only supports the const constructor for `?.fromEnvironment`. The
/// current behavior is to throw at runtime if they call this constructor with
/// `new` instead of `const`.
main() {
  Expect.isFalse(const bool.fromEnvironment('X'));
  Expect.isNull(const String.fromEnvironment('X'));
  Expect.equals(const int.fromEnvironment('X', defaultValue: 0), 0);

  Expect.throws(() => new bool.fromEnvironment('X'));
  Expect.throws(() => new String.fromEnvironment('X'));
  Expect.throws(() => new int.fromEnvironment('X', defaultValue: 0));
}
