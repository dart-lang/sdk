// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Wrong MIME.
import 'data:text/plain;charset=utf-8,foo%28%29%20%3D%3E%2042%3B';  /// 01: runtime error

// No MIME.
import 'data:;charset=utf-8,foo%28%29%20%3D%3E%2042%3B';  /// 02: runtime error

// Wrong charset.
import 'data:application/dart;charset=utf-16,foo%28%29%20%3D%3E%2042%3B';  /// 03: runtime error

// No charset.
import 'data:application/dart,foo%28%29%20%3D%3E%2042%3B';  /// 04: runtime error

// Bad encoding.
import 'data:application/dart;charset=utf-8,foo?%9g';  /// 05: runtime error

// Wrong encoding.
import 'data:application/dart;charset=utf-8;base64,Zm9vKCkgPT4gNDI7';  /// 06: runtime error

main() {
}