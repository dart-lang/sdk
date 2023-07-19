// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool doIt1(Object arg1, [Object? arg2]) {
  /*
   fields={$1:Object,$2:Object?},
   type=(Object, Object?)
  */
  switch ((arg1, arg2)) {
    /*space=(Object, Null)*/ case (_, null):
      return true;

    /*space=(Object, Object)*/ case (_, _?):
      return true;
    /*
     error=unreachable,
     space=(Object, ())
    */
    case (_, _):
      return true;
  }
}

bool doIt2(Object arg1,
        [Object?
            arg2]) => /*
 fields={$1:Object,$2:Object?},
 type=(Object, Object?)
*/
    switch ((arg1, arg2)) {
      (_, null) /*space=(Object, Null)*/ => true,
      (_, _?) /*space=(Object, Object)*/ => true,
    };
