// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  /*1:main*/ test(new Class());
}

@NoInline()
test(c) {
  /*ast.2:test*/ c. /*kernel.2:test*/ field.method();
}

class Class {
  var field;
}
