// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String test1(Object? o) {
  /*
   checkingOrder={Object?,Object,Null},
   subtypes={Object,Null},
   type=Object?
  */
  switch (o) {
    /*space=()*/
    case Object _!:
      return "exhaustive";
  }
}

String test2(
        Object?
            o) => /*
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      Object _! /*space=()*/ => "exhaustive"
    };

main() {
  print(test1(42));
  print(test2(42));
}
