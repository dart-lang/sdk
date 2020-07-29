// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue42836.dart';

class Generic<T> {}

class NonNullable extends Generic<int> {}

class Nullable extends Generic<int?> {}

var nonNullableInstance = NonNullable();
var nullableInstance = Nullable();

test(bool b) {
  var a1 = b ? legacyInstance : legacyInstance;
  var a2 = b ? legacyInstance : nonNullableInstance;
  var a3 = b ? legacyInstance : nullableInstance;
  var b1 = b ? nonNullableInstance : legacyInstance;
  var b2 = b ? nonNullableInstance : nonNullableInstance;
  var b3 = b ? nonNullableInstance : nullableInstance;
  var c1 = b ? nullableInstance : legacyInstance;
  var c2 = b ? nullableInstance : nonNullableInstance;
  var c3 = b ? nullableInstance : nullableInstance;
}
