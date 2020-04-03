// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.superclass;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class MyClass {}

main() {
  var cls = reflectClass(MyClass);
  Expect.isNotNull(cls, 'Failed to reflect on MyClass.');
  var superclass = cls.superclass;
  Expect.isNotNull(superclass, 'Failed to obtain superclass of MyClass.');
  Expect.equals(
      reflectClass(Object), superclass, 'Superclass of MyClass is not Object.');
  Expect.isNull(superclass.superclass, 'Superclass of Object is not null.');
}
