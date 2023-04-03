// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {}

extension<T> on A<T> {
  void member(T t) {}
}

exhaustiveInferred(
        A<num>
            a) => /*cfe.
 fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
 type=<invalid>
*/ /*analyzer.
 checkingOrder={Object?,Object,Null},
 error=non-exhaustive:Object(),
 fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      A<int>(
        :var member
      ) /*cfe.space=<invalid>(A<int>.member: void Function(int) (void Function(int)))*/ /*analyzer.space=A<int>(A<int>.member: void Function(int) (void Function(int)))*/ =>
        0,
      A<num>(
        :var member
      ) /*cfe.
     error=unreachable,
     space=<invalid>(A<num>.member: void Function(num) (void Function(num)))
    */ /*analyzer.space=A<num>(A<num>.member: void Function(num) (void Function(num)))*/ =>
        1,
    };

exhaustiveTyped(
        A<num>
            a) => /*cfe.
 fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
 type=<invalid>
*/ /*analyzer.
 checkingOrder={Object?,Object,Null},
 error=non-exhaustive:Object(),
 fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      A<int>(
        :void Function(int) member
      ) /*cfe.space=<invalid>(A<int>.member: void Function(int) (void Function(int)))*/ /*analyzer.space=A<int>(A<int>.member: void Function(int) (void Function(int)))*/ =>
        0,
      A<num>(
        :void Function(num) member
      ) /*cfe.
     error=unreachable,
     space=<invalid>(A<num>.member: void Function(num) (void Function(num)))
    */ /*analyzer.space=A<num>(A<num>.member: void Function(num) (void Function(num)))*/ =>
        1,
    };

unreachable(
        A<num>
            a) => /*cfe.
 fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
 type=<invalid>
*/ /*analyzer.
 checkingOrder={Object?,Object,Null},
 error=non-exhaustive:Object(),
 fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      A<num>(
        :var member
      ) /*cfe.space=<invalid>(A<num>.member: void Function(num) (void Function(num)))*/ /*analyzer.space=A<num>(A<num>.member: void Function(num) (void Function(num)))*/ =>
        1,
      A<int>(
        :var member
      ) /*cfe.
     error=unreachable,
     space=<invalid>(A<int>.member: void Function(int) (void Function(int)))
    */ /*analyzer.
     error=unreachable,
     space=A<int>(A<int>.member: void Function(int) (void Function(int)))
    */
        =>
        0,
    };

nonExhaustiveRestricted(
        A<num>
            a) => /*cfe.
 fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
 type=<invalid>
*/ /*analyzer.
 checkingOrder={Object?,Object,Null},
 error=non-exhaustive:Object(),
 fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      A<num>(
        :void Function(num) member
      ) /*cfe.space=<invalid>(A<num>.member: void Function(num) (void Function(num)))*/ /*analyzer.space=A<num>(A<num>.member: void Function(num) (void Function(num)))*/ =>
        1,
      A<int>(
        :var member
      ) /*cfe.
     error=unreachable,
     space=<invalid>(A<int>.member: void Function(int) (void Function(int)))
    */ /*analyzer.
     error=unreachable,
     space=A<int>(A<int>.member: void Function(int) (void Function(int)))
    */
        =>
        0,
    };

intersection(o) {
  /*
   checkingOrder={Object?,Object,Null},
   fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
   subtypes={Object,Null},
   type=Object?
  */
  switch (o) {
    /*space=?*/ case A<int>(member: var member1) &&
          A<double>(member: var member2):
    /*space=A<int>(A<int>.member: void Function(int) (void Function(int)), A<num>.member: void Function(num) (void Function(num)))*/ case A<
              int>(member: var member1) &&
          A<num>(member: var member2):
  }
}
