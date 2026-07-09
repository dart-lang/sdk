// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo {
  void bar() {}
}

void main(List<String> arguments) {
  dynamic exception = null;
  try {
    final typeObject = Foo as dynamic;
    print(typeObject.bar);
  } catch (e) {
    exception = e;
  }
  Expect.isNotNull(exception);
  Expect.isTrue(exception is NoSuchMethodError);
  // The NoSuchMethodError.toString() in the regression caused a crash.
  Expect.isTrue(exception.toString().contains('NoSuchMethodError'));
}
