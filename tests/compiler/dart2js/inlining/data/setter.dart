// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

/*element: main:[]*/
main() {
  inlineSetter();
}

class Class1 {
  var field;
/*element: Class1.:[]*/
  @NoInline()
  Class1();
  /*element: Class1.setter=:[inlineSetter]*/
  set setter(value) {
    field = value;
  }
}

/*element: inlineSetter:[]*/
@NoInline()
inlineSetter() {
  Class1 c = new Class1();
  c.setter = 42;
}
