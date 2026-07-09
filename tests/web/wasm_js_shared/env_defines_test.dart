// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions="-DFOO=a, b, c=123" --define=BAR=hi
// ddcOptions="-DFOO=a, b, c=123" --define=BAR=hi
// dart2wasmOptions="--extra-compiler-option=-DFOO=a, b, c=123" --define=BAR=hi

import 'package:expect/expect.dart';

void main() {
  Expect.equals("a, b, c=123", const String.fromEnvironment("FOO"));
  Expect.equals("hi", const String.fromEnvironment("BAR"));
}
