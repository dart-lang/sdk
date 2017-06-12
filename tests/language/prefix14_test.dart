// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Use qualified symbols at various places.

library Prefix14Test.dart;

import "package:expect/expect.dart";
import "library12.dart" as lib12;

typedef lib12.Library12 myFunc(lib12.Library12 param);

class myInterface implements lib12.Library12Interface {
  myInterface(lib12.Library12 this.myfld);
  lib12.Library12 addObjects(lib12.Library12 value1, lib12.Library12 value2) {
    myfld.fld = (value1.fld + value2.fld + myfld.fld);
    return myfld;
  }

  lib12.Library12 myfld;
}

class myClass extends lib12.Library12 {
  myClass(int value) : super(value);
  static lib12.Library12 func1() {
    var i = new lib12.Library12(10);
    return i;
  }

  static lib12.Library12 func2(lib12.Library12 param) {
    return param;
  }
}

class myClass1 {
  myClass1(int value) : fld1 = new lib12.Library12(value);
  lib12.Library12 fld1;
}

class myClass2 {
  myClass2(lib12.Library12 this.fld2);
  lib12.Library12 fld2;
}

main() {
  var o = myClass.func1();
  Expect.equals(2, o.func());
  o = new myClass(10);
  Expect.equals(10, o.fld);

  myFunc func = myClass.func2;
  Expect.equals(2, func(new lib12.Library12(10)).func());
  Expect.equals(10, func(new lib12.Library12(10)).fld);

  o = new myClass1(100);
  Expect.equals(2, o.fld1.func());
  Expect.equals(100, o.fld1.fld);

  o = new myClass2(new lib12.Library12(200));
  Expect.equals(2, o.fld2.func());
  Expect.equals(200, o.fld2.fld);

  o = new myInterface(new lib12.Library12(100));
  Expect.equals(2, o.myfld.func());
  Expect.equals(100, o.myfld.fld);
  o = o.addObjects(new lib12.Library12(200), new lib12.Library12(300));
  Expect.equals(2, o.func());
  Expect.equals(600, o.fld);
}
