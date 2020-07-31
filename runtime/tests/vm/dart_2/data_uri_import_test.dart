// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// foo() => 42;
import 'data:application/dart;charset=utf-8,foo%28%29%20%3D%3E%2042%3B';  /// percentencoded: ok
import 'data:text/plain;charset=utf-8,foo%28%29%20%3D%3E%2042%3B';  /// wrongmime: ok
import 'data:;charset=utf-8,foo%28%29%20%3D%3E%2042%3B';  /// nomime: ok
import 'data:application/dart;charset=utf-16,foo%28%29%20%3D%3E%2042%3B';  /// utf16: ok
import 'data:application/dart,foo%28%29%20%3D%3E%2042%3B';  /// nocharset: ok
import 'data:application/dart;charset=utf-8,foo?%9g';  /// badencodeddate: compile-time error
import 'data:application/dart;charset=utf-8;base64,Zm9vKCkgPT4gNDI7';  /// base64: ok

import "package:expect/expect.dart";

main() {
  Expect.equals(42, foo());
}
