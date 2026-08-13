// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  /*member: Class.constructor1:invoke*/
  Class.constructor1() {}

  /*member: Class.constructor2a:invoke=(0)*/
  Class.constructor2a([a]) {}

  /*member: Class.constructor2b:invoke*/
  Class.constructor2b([a]) {}

  /*member: Class.constructor2c:invoke*/
  Class.constructor2c([a]) {}

  /*member: Class.constructor3a:invoke=(0)*/
  Class.constructor3a([a, b]) {}

  /*member: Class.constructor3b:invoke=(1)*/
  Class.constructor3b([a, b]) {}

  /*member: Class.constructor3c:invoke*/
  Class.constructor3c([a, b]) {}

  /*member: Class.constructor4a:invoke=(0)*/
  Class.constructor4a({a}) {}

  /*member: Class.constructor4b:invoke*/
  Class.constructor4b({a}) {}

  /*member: Class.constructor4c:invoke*/
  Class.constructor4c({a}) {}

  /*member: Class.constructor5a:invoke=(0)*/
  Class.constructor5a({a, b}) {}

  /*member: Class.constructor5b:invoke=(0,a)*/
  Class.constructor5b({a, b}) {}

  /*member: Class.constructor5c:invoke=(0,b)*/
  Class.constructor5c({a, b}) {}

  /*member: Class.constructor6a:invoke=(1)*/
  Class.constructor6a(a, [b, c]) {}

  /*member: Class.constructor6b:invoke=(2)*/
  Class.constructor6b(a, [b, c]) {}

  /*member: Class.constructor6c:invoke*/
  Class.constructor6c(a, [b, c]) {}

  /*member: Class.constructor7a:invoke=(1)*/
  Class.constructor7a(a, {b, c}) {}

  /*member: Class.constructor7b:invoke=(1,b)*/
  Class.constructor7b(a, {b, c}) {}

  /*member: Class.constructor7c:invoke=(1,c)*/
  Class.constructor7c(a, {b, c}) {}

  /*member: Class.constructor8a:invoke=(0)*/
  @pragma('dart2js:noElision')
  Class.constructor8a([a, b]) {}

  /*member: Class.constructor8b:invoke=(0)*/
  @pragma('dart2js:noElision')
  Class.constructor8b({a, b}) {}
}

/*member: main:invoke*/
main() {
  Class.constructor1();

  Class.constructor2a();
  Class.constructor2b(null);
  Class.constructor2c();
  Class.constructor2c(null);

  Class.constructor3a();
  Class.constructor3b();
  Class.constructor3b(null);
  Class.constructor3c(null, null);

  Class.constructor4a();
  Class.constructor4b(a: null);
  Class.constructor4c();
  Class.constructor4c(a: null);

  Class.constructor5a();
  Class.constructor5b(a: null);
  Class.constructor5c(b: null);

  Class.constructor6a(null);
  Class.constructor6b(null);
  Class.constructor6b(null, null);
  Class.constructor6c(null, null, null);

  Class.constructor7a(null);
  Class.constructor7b(null, b: null);
  Class.constructor7c(null, c: null);

  Class.constructor8a();
  Class.constructor8b();
}
