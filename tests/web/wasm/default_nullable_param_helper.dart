// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String doSplit(String s) {
  return s.split(',').join(';');
}

abstract class Base {
  void format(String s, [String? p]);
}

class A extends Base {
  void format(String s, [String? p = 'a']) {
    print('A: ${doSplit(s ?? p!)}');
  }
}

class B extends Base {
  final String bDefault;

  B(this.bDefault);

  void format(String s, [String? p]) {
    print('B: ${doSplit(s + (p ?? bDefault))}');
  }
}
