// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that passing `null` for a boolean typed parameter will still cause
// a boolean conversion error when used in a condition.

import 'package:expect/expect.dart';

@NoInline()
String check({bool a, bool b}) {
  String aString = a ? 'a' : '';
  String bString = b ? 'b' : '';
  return '$aString$bString';
}

class Class {
  final String field;
  Class({bool a: false, bool b: true}) : this.field = check(a: a, b: b);
}

main() {
  Expect.throwsAssertionError(() => new Class(a: null, b: null).field);
}
