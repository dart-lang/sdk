// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for dartbug.com/43520.
///
/// Safari has a bug that makes it a syntax error for a function name to overlap
/// with names of parameters in functions with default parameter values.
///
/// DDC now generates code to circumvent this issue.

import 'package:expect/expect.dart';

String a(Object a, [String f = '3']) {
  return "$a$f";
}

main() async {
  Expect.equals('13', a(1));
}
