// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

exhaustiveNullableTypeVariable<T>(
        o) => /*
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      T() /*space=Object?*/ => 0,
      _ /*space=()*/ => 1,
    };

nonExhaustiveNullableTypeVariable<T>(
        o) => /*
         checkingOrder={Object?,Object,Null},
         error=non-exhaustive:Object();null,
         subtypes={Object,Null},
         type=Object?
        */
    switch (o) {
      T() /*space=Object?*/ => 0,
    };

exhaustiveNonNullableTypeVariable<T extends Object>(
        o) => /*
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      T() /*space=Object*/ => 0,
      _ /*space=()*/ => 1,
    };

nonExhaustiveNonNullableTypeVariableOnObject<T extends Object>(
        Object
            o) => /*
             error=non-exhaustive:Object(),
             type=Object
            */
    switch (o) {
      T() /*space=Object*/ => 0,
    };

nonExhaustiveNonNullableTypeVariableOnDynamic<T extends Object>(
        o) => /*
         checkingOrder={Object?,Object,Null},
         error=non-exhaustive:Object();null,
         subtypes={Object,Null},
         type=Object?
        */
    switch (o) {
      T() /*space=Object*/ => 0,
    };
