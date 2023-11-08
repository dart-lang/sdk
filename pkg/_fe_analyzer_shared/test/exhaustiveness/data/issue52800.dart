// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum MyEnum { first, second }

typedef MyData = (
  MyEnum field1,
  MyEnum field2,
);

void main() {
  print(myFn(MyEnum.first, null));
  print(myFn(MyEnum.first, MyEnum.second));
}

MyData? myFn(MyEnum field1, MyEnum? field2) {
  return /*type=(MyEnum, MyEnum?)*/
      switch ((field1, field2)) {
    final MyData a /*space=(MyEnum, MyEnum)*/
      =>
      a,
    _ /*space=(MyEnum, MyEnum?)*/
      =>
      null,
  };
}

method(
        (
          String,
          Object
        ) o) => /*
 fields={$1:String,$2:Object},
 type=(String, Object)
*/
    switch (o) {
      (Object _, String s) /*space=(String, String)*/ => 0,
      _ /*space=(String, Object)*/ => 1,
    };
