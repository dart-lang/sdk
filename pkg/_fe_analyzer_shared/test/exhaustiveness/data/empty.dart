// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

emptyBool(bool b) {
  return /*
   error=non-exhaustive:true,
   subtypes={true,false},
   type=bool
  */
  switch (b) {
  };
}

emptyNum(num n) {
  return /*
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
   error=non-exhaustive:E.a,
   subtypes={E.a,E.b},
   type=E
  */
  switch (e) {
  };
}
