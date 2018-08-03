// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Use qualified symbols with generics at various places.

library Prefix15Test.dart;

import "package:expect/expect.dart";
import "library12.dart" as lib12;

typedef T myFunc<T>(T param);

class myInterface<T extends lib12.Library12>
    implements lib12.Library12Interface {
  myInterface(T this.myfld);
  T addObjects(covariant T value1, covariant T value2) {
    myfld.fld = (value1.fld + value2.fld + myfld.fld);
    return myfld;
  }

  T myfld;
}

class myClass2<T> {
  myClass2(T this.fld2);
  T func(T val) => val;
  T fld2;
}

main() {
  var o;
  o = new myClass2<lib12.Library12>(new lib12.Library12(100));
  myFunc<lib12.Library12> func = o.func;
  Expect.equals(2, func(new lib12.Library12(10)).func());
  Expect.equals(10, func(new lib12.Library12(10)).fld);

  o = new myClass2<lib12.Library12>(new lib12.Library12(200));
  Expect.equals(2, o.fld2.func());
  Expect.equals(200, o.fld2.fld);

  o = new myInterface<lib12.Library12>(new lib12.Library12(100));
  Expect.equals(2, o.myfld.func());
  Expect.equals(100, o.myfld.fld);
  o = o.addObjects(new lib12.Library12(200), new lib12.Library12(300));
  Expect.equals(2, o.func());
  Expect.equals(600, o.fld);
}
