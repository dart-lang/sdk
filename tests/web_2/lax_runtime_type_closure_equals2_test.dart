// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong --omit-implicit-checks --lax-runtime-type-to-string

import 'package:expect/expect.dart';

class Class<T> {
  Class();
}

main() {
  T local1a<T>() => null;

  T local1b<T>() => null;

  T local2<T>(T t, String s) => t;

  Expect.isTrue(local1a.runtimeType == local1b.runtimeType);
  Expect.isFalse(local1a.runtimeType == local2.runtimeType);
  new Class();
}
