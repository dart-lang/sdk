// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that evaluation containers aren't renamed by DDC.

import 'dart:_foreign_helper' as helper show JS;

import 'package:expect/expect.dart';

class T {
  final int T$Eval = 0;
  final int S$Eval = 0;
  String get realT$Eval => helper.JS<String>('', 'T\$Eval.toString()');
  String get realS$Eval => helper.JS<String>('', 'S\$Eval.toString()');
}

class T$Eval {}

void main() {
  var T$Eval = T();
  var S$Eval = T$Eval;

  var container1 = helper.JS<String>('', 'T\$Eval.toString()');
  var container2 = helper.JS<String>('', 'S\$Eval.toString()');

  // Evaluation containers are JS Objects. Ensure they aren't shadowed by JS
  // symbols or Dart constructs.
  Expect.equals('[object Object]', '$container1');
  Expect.equals('[object Object]', '$container2');

  Expect.equals("Instance of 'T'", T$Eval.toString());
  Expect.equals(T$Eval.T$Eval, 0);
  Expect.equals(T$Eval.S$Eval, 0);
  Expect.notEquals(T$Eval.toString(), container1);
  Expect.equals(T$Eval.realT$Eval, container1);
  Expect.equals(T$Eval.realS$Eval, container2);
}
