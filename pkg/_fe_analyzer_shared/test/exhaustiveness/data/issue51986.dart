// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int test1(Object obj) {
  /*
   fields={isEven:-},
   type=Object
  */
  switch (obj) {
    /*space=int(isEven: true)|Null*/ case int(isEven: true) as int:
      return 1;
    /*space=int*/ case int _:
      return 2;
  }
}

int test2(Object obj) =>
    /*
     error=non-exhaustive:Object(),
     fields={isEven:-},
     type=Object
    */
    switch (obj) {
      int(isEven: true) as int /*space=int(isEven: true)|Null*/ => 1,
      int _ /*space=int*/ => 2
    };
