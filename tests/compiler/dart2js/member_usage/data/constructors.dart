// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  /*element: Class.constructor1:invoke*/
  Class.constructor1() {}

  /*element: Class.constructor2a:invoke=(0)*/
  Class.constructor2a([a]) {}

  /*element: Class.constructor2b:invoke*/
  Class.constructor2b([a]) {}

  /*element: Class.constructor2c:invoke*/
  Class.constructor2c([a]) {}

  /*element: Class.constructor3a:invoke=(0)*/
  Class.constructor3a([a, b]) {}

  /*element: Class.constructor3b:invoke=(1)*/
  Class.constructor3b([a, b]) {}

  /*element: Class.constructor3c:invoke*/
  Class.constructor3c([a, b]) {}

  /*element: Class.constructor4a:invoke=(0)*/
  Class.constructor4a({a}) {}

  /*element: Class.constructor4b:invoke*/
  Class.constructor4b({a}) {}

  /*element: Class.constructor4c:invoke*/
  Class.constructor4c({a}) {}

  /*element: Class.constructor5a:invoke=(0)*/
  Class.constructor5a({a, b}) {}

  /*element: Class.constructor5b:invoke=(0,a)*/
  Class.constructor5b({a, b}) {}

  /*element: Class.constructor5c:invoke=(0,b)*/
  Class.constructor5c({a, b}) {}

  /*element: Class.constructor6a:invoke=(1)*/
  Class.constructor6a(a, [b, c]) {}

  /*element: Class.constructor6b:invoke=(2)*/
  Class.constructor6b(a, [b, c]) {}

  /*element: Class.constructor6c:invoke*/
  Class.constructor6c(a, [b, c]) {}

  /*element: Class.constructor7a:invoke=(1)*/
  Class.constructor7a(a, {b, c}) {}

  /*element: Class.constructor7b:invoke=(1,b)*/
  Class.constructor7b(a, {b, c}) {}

  /*element: Class.constructor7c:invoke=(1,c)*/
  Class.constructor7c(a, {b, c}) {}
}

/*element: main:invoke*/
main() {
  new Class.constructor1();

  new Class.constructor2a();
  new Class.constructor2b(null);
  new Class.constructor2c();
  new Class.constructor2c(null);

  new Class.constructor3a();
  new Class.constructor3b();
  new Class.constructor3b(null);
  new Class.constructor3c(null, null);

  new Class.constructor4a();
  new Class.constructor4b(a: null);
  new Class.constructor4c();
  new Class.constructor4c(a: null);

  new Class.constructor5a();
  new Class.constructor5b(a: null);
  new Class.constructor5c(b: null);

  new Class.constructor6a(null);
  new Class.constructor6b(null);
  new Class.constructor6b(null, null);
  new Class.constructor6c(null, null, null);

  new Class.constructor7a(null);
  new Class.constructor7b(null, b: null);
  new Class.constructor7c(null, c: null);
}
