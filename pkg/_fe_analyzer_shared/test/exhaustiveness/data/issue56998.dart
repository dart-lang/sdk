// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int nonExhaustive1<T extends int?>(T value) =>
    /*
     checkingOrder={int?,int,Null},
     error=non-exhaustive:null,
     subtypes={int,Null},
     type=int?
    */
    switch (value) {
      int() /*space=int*/ => value,
    };

int nonExhaustive2<T extends int?>(T? value) => /*
 checkingOrder={int?,int,Null},
 error=non-exhaustive:null,
 subtypes={int,Null},
 type=int?
*/ switch (value) {
  int() /*space=int*/ => value,
};

int exhaustive<T extends int>(T value) => /*type=int*/ switch (value) {
  int() /*space=int*/ => value,
};

int nonExhaustive3<T extends int>(T? value) => /*
 checkingOrder={int?,int,Null},
 error=non-exhaustive:null,
 subtypes={int,Null},
 type=int?
*/ switch (value) {
  int() /*space=int*/ => value,
};
