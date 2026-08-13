// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void something(List<String> l) {
  String s = l.first;
}

void checkAndInvoke(Function f) {
  f(["foo"]);
  var l = <int>[1];
  Expect.throwsTypeError(() => f(l));
  if (f is Function(List<Never>)) {
    Expect.throwsTypeError(() => (f as Function)(l));
  }
}

void main() {
  checkAndInvoke(something);
}
