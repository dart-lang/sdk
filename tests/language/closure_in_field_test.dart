// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test handling of type variable in field initializers.

import 'package:expect/expect.dart';

class Mixin<S> {
  var field = (S s) => null;
}

class Class<T> extends Object with Mixin<T> {}

void main() {
  Expect.isTrue(test(new Mixin<int>()));
  Expect.isFalse(test(new Mixin<String>())); //# 01: ok
  Expect.isTrue(test(new Class<int>()));
  Expect.isFalse(test(new Class<String>())); //# 02: ok
}

test(o) => o.field is dynamic Function(int);
