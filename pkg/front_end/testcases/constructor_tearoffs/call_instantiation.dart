// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T func<T>(T value) => value;
var funcValue = func;
int Function(int) f = funcValue.call;
int Function(int) g = funcValue.call<int>;

test(Function f) {
  int Function(int) g = f.call<int>;
}

main() {}
