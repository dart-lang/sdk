// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ExtensionTypeNullable(String? s) {}

extension type ExtensionTypeNum(num n) {}

extension type ExtensionTypeBool(bool b) {}

sealed class S {}
class A extends S {}
class B extends S {}

extension type ExtensionTypeSealed(S s) {}

methodNull1(ExtensionTypeNullable o) => /*
 checkingOrder={String?,String,Null},
 subtypes={String,Null},
 type=String?
*/switch (o) {
  null /*space=Null*/=> 0,
  String s /*space=String*/=> 1,
};

methodNull2(ExtensionTypeNullable o) => /*
 checkingOrder={String?,String,Null},
 subtypes={String,Null},
 type=String?
*/switch (o) {
  ExtensionTypeNullable() /*space=String?*/=> 2,
};

methodNull3(String? o) => /*
 checkingOrder={String?,String,Null},
 subtypes={String,Null},
 type=String?
*/switch (o) {
  ExtensionTypeNullable s /*space=String?*/=> 3,
};

methodNum1(ExtensionTypeNum o) => /*
 checkingOrder={num,double,int},
 subtypes={double,int},
 type=num
*/switch (o) {
  int() /*space=int*/=> 0,
  double() /*space=double*/=> 1,
};

methodNum2(ExtensionTypeNum o) => /*
 checkingOrder={num,double,int},
 subtypes={double,int},
 type=num
*/switch (o) {
  ExtensionTypeNum() /*space=num*/=> 2,
};

methodNum3(num o) => /*
 checkingOrder={num,double,int},
 subtypes={double,int},
 type=num
*/switch (o) {
  ExtensionTypeNum() /*space=num*/=> 3,
};

methodBool1(ExtensionTypeBool o) => /*
 checkingOrder={bool,true,false},
 subtypes={true,false},
 type=bool
*/switch (o) {
  true /*space=true*/=> 0,
  false /*space=false*/=> 1,
};

methodBool2(ExtensionTypeBool o) => /*
 checkingOrder={bool,true,false},
 subtypes={true,false},
 type=bool
*/switch (o) {
  ExtensionTypeBool() /*space=bool*/=> 2,
};

methodBool3(bool o) => /*
 checkingOrder={bool,true,false},
 subtypes={true,false},
 type=bool
*/switch (o) {
  ExtensionTypeBool() /*space=bool*/=> 3,
};

methodSealed1(ExtensionTypeSealed o) => /*
 checkingOrder={S,A,B},
 subtypes={A,B},
 type=S
*/switch (o) {
  A() /*space=A*/=> 0,
  B() /*space=B*/=> 1,
};

methodSealed2(ExtensionTypeSealed o) => /*
 checkingOrder={S,A,B},
 subtypes={A,B},
 type=S
*/switch (o) {
  ExtensionTypeSealed() /*space=S*/=> 2,
};

methodSealed3(S o) => /*
 checkingOrder={S,A,B},
 subtypes={A,B},
 type=S
*/switch (o) {
  ExtensionTypeSealed() /*space=S*/=> 3,
};
