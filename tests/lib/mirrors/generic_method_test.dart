// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Foo {
  T bar<T>() => null;
}

void main() {
  var type = reflectClass(Foo);
  Expect.isTrue(type.declarations.keys.contains(#bar));
}
