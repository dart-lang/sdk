// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: method1:params=0*/
@pragma('dart2js:noInline')
method1([a]) => /*params=0*/ () => a;

class Class {
  var f;

  /*element: Class.capture:params=0*/
  @pragma('dart2js:noInline')
  Class.capture([a]) : f = (/*params=0*/ () => a);

  /*element: Class.box:params=0*/
  @pragma('dart2js:noInline')
  Class.box([a])
      : f = (/*params=0*/ () {
          a = 42;
        });

  Class.internal(this.f);
}

class Subclass extends Class {
  /*element: Subclass.capture:params=0*/
  @pragma('dart2js:noInline')
  Subclass.capture([a]) : super.internal(/*params=0*/ () => a);

  /*element: Subclass.box:params=0*/
  @pragma('dart2js:noInline')
  Subclass.box([a])
      : super.internal(/*params=0*/ () {
          a = 42;
        });
}

/*element: main:calls=*,params=0*/
main() {
  method1();
  new Class.capture();
  new Class.box();
  new Subclass.capture();
  new Subclass.box();
}
