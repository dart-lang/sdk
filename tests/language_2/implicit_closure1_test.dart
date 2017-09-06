// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks --enable_asserts

typedef Handler(bool e);

class Hello {
  Hello() {}
  void handler2(bool e) {
    print('handler2');
  }

  static void handler1(bool e) {
    print('handler1');
  }

  void addEventListener(String s, Handler handler, bool status) {
    handler(status);
  }

  static void main() {
    final h = new Hello();
    h.addEventListener('click', handler1, false);
    h.addEventListener('click', h.handler2, false);
  }
}

main() {
  Hello.main();
}
