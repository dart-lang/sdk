// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.7

import 'issue42836_lib.dart';

class Legacy extends Generic<int> {
  int legacyMethod() => 3;
}

var legacyInstance = Legacy();

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

main() {}
