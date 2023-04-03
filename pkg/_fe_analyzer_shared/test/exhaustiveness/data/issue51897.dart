// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1<T>(T t) {
  if (t is bool?) {
    /*
     checkingOrder={bool?,bool,Null,true,false},
     expandedSubtypes={true,false,Null},
     subtypes={bool,Null},
     type=bool?
    */
    switch (t) {
      /*space=true*/ case true:
      /*space=false*/ case false:
      /*space=Null*/ case null:
    }
  }
}

test2<T>(T t) {
  if (t is bool?) {
    /*
     checkingOrder={bool?,bool,Null,true,false},
     expandedSubtypes={true,false,Null},
     subtypes={bool,Null},
     type=bool?
    */
    switch (t) {
      /*space=bool*/ case bool():
      /*space=Null*/ case Null():
    }
  }
}

test3<T extends bool?>(T t) {
  /*
   checkingOrder={bool?,bool,Null,true,false},
   expandedSubtypes={true,false,Null},
   subtypes={bool,Null},
   type=bool?
  */
  switch (t) {
    /*space=true*/ case true:
    /*space=false*/ case false:
    /*space=Null*/ case null:
  }
}

main() {
  test1<bool?>(null);
  test2<bool?>(true);
  test3(true);
}
