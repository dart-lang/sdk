// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends num> {
  const A({int? x, String? y, bool? z});
}

const a = {"a": A(x: 0, y: "", z: false, x: 1)};

main() {}
