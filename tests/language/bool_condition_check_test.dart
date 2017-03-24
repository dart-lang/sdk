// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that passing `null` for a boolean typed parameter will still cause
// a boolean conversion error when used in a condition in checked mode.

import 'package:expect/expect.dart';

@NoInline()
String check({bool a, bool b}) {
  String a_string = a ? 'a' : '';
  String b_string = b ? 'b' : '';
  return '$a_string$b_string';
}

class Class {
  final String field;
  Class({bool a: false, bool b: true}) : this.field = check(a: a, b: b);
}

main() {
  Expect.equals('', new Class(a: null, b: null).field); //# 01: dynamic type error
}
