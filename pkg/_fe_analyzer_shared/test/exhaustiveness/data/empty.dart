// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

emptyBool(bool b) {
  return /*
   checkingOrder={bool,true,false},
   error=non-exhaustive:true,
   subtypes={true,false},
   type=bool
  */
      switch (b) {
    
  };
}

emptyNum(num n) {
  return /*
   checkingOrder={num,double,int},
   error=non-exhaustive:double(),
   subtypes={double,int},
   type=num
  */
      switch (n) {
    
  };
}

emptyInt(int i) {
  return /*
   error=non-exhaustive:int(),
   type=int
  */
      switch (i) {
    
  };
}

enum E { a, b }

emptyEnum(E e) {
  return /*
   checkingOrder={E,E.a,E.b},
   error=non-exhaustive:E.a,
   subtypes={E.a,E.b},
   type=E
  */
      switch (e) {
    
  };
}

sealed class Empty {}

emptySealed(Empty empty) => /*
 checkingOrder={Empty},
 type=Empty
*/
    switch (empty) {
      
    };

emptyNever(Never never) => /*type=Never*/ switch (never) {  };

emptyUnresolved(
        Unresolved
            unresolved) => /*cfe.type=Never*/ /*analyzer.
 checkingOrder={Object?,Object,Null},
 error=non-exhaustive:Object(),
 subtypes={Object,Null},
 type=Object?
*/
    switch (unresolved) {
      
    };

nonEmptyUnresolved(
        Unresolved
            unresolved) => /*cfe.type=Never*/ /*analyzer.
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (unresolved) {
      _ /*cfe.space=∅*/ /*analyzer.space=()*/ => 0,
    };
