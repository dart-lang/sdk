// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  Expect.equals('', useParameterInClosure(1));
  Expect.equals(43, updateParameterInClosure(1)());
}

String useParameterInClosure(arg1, {int arg2}) {
  if (arg1 is Map) {
    return arg1.keys.map((key) => arg1[key]).first;
  } else {
    return '';
  }
}

Function updateParameterInClosure(arg1) {
  if (arg1 is Map) {
    return () => arg1 = 42;
  } else {
    return () => arg1 = arg1 + 42;
  }
}
