// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

class A {
  void m2<T>(void Function(T) f, [a]) {}
}

main() => new A().m2<String>(null);
