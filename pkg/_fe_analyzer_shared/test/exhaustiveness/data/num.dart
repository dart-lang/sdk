// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

exhaustiveSwitchNum(num n) {
  /*
   checkingOrder={num,double,int},
   subtypes={double,int},
   type=num
  */
  switch (n) {
    /*space=num*/
    case num n:
  }
}

exhaustiveSwitchIntDouble(num n) {
  /*
   checkingOrder={num,double,int},
   subtypes={double,int},
   type=num
  */
  switch (n) {
    /*space=int*/
    case int i:
    /*space=double*/
    case double d:
  }
}

exhaustiveSwitchNullable(num? n) {
  /*
   checkingOrder={num?,num,Null,double,int},
   expandedSubtypes={double,int,Null},
   subtypes={num,Null},
   type=num?
  */
  switch (n) {
    /*space=int*/
    case int i:
    /*space=double*/
    case double d:
    /*space=Null*/
    case null:
  }
}

nonExhaustiveSwitch(num n1, num n2, num? n3) {
  /*
   checkingOrder={num,double,int},
   error=non-exhaustive:double(),
   subtypes={double,int},
   type=num
  */
  switch (n1) {
    /*space=int*/
    case int i:
  }
  /*
   checkingOrder={num,double,int},
   error=non-exhaustive:int(),
   subtypes={double,int},
   type=num
  */
  switch (n2) {
    /*space=double*/
    case double d:
  }
  /*
   checkingOrder={num?,num,Null,double,int},
   error=non-exhaustive:null,
   expandedSubtypes={double,int,Null},
   subtypes={num,Null},
   type=num?
  */
  switch (n3) {
    /*space=int*/
    case int i:
    /*space=double*/
    case double d:
  }
}
