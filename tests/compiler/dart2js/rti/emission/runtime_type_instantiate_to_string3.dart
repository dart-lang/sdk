// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: Class:checks=[],instance*/
class Class {
  T id<T>(T t) => t;
}

main() {
  int Function(int) x = new Class().id;
  print("${x.runtimeType}");
}
