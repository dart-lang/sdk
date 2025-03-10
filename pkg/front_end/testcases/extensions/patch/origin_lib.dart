// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long long long long long long long long long long long long long long long
// long comment to make offsets in `origin_lib.dart` out of range in
// `patch_lib.dart`.

extension IntExtension on int {
  external int method1();
}

extension GenericExtension<T> on T {
  external int method3();
}

method1() {
  0.method1();
  0.method2();
  0.method3();
  0.method4();
}
