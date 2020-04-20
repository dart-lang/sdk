// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  inlineSetter();
}

class Class1 {
  var field;
/*member: Class1.:[]*/
  @pragma('dart2js:noInline')
  Class1();
  /*member: Class1.setter=:[inlineSetter]*/
  set setter(value) {
    field = value;
  }
}

/*member: inlineSetter:[]*/
@pragma('dart2js:noInline')
inlineSetter() {
  Class1 c = new Class1();
  c.setter = 42;
}
