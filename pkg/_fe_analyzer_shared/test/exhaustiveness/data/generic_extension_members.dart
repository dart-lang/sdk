// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<T> {}

class J<T> extends I<T> {}

class A<T> extends J<T> {}

extension<T> on I<T> {
  num get member {
    return T == int ? 0.5 : 1;
  }
}

extension<T> on A<T> {
  void member(T t) {}
}

exhaustiveInferred(
        A<num>
            a) => /*
             fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
             type=A<num>
            */
    switch (a) {
      A<int>(
        :var member
      ) /*space=A<int>(A<int>.member: void Function(int) (void Function(int)))*/ =>
        0,
      A<num>(
        :var member
      ) /*space=A<num>(A<num>.member: void Function(num) (void Function(num)))*/ =>
        1,
    };

exhaustiveTyped(
        A<num>
            a) => /*cfe.
             fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
             type=Never
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
      ) /*cfe.space=Never(A<int>.member: void Function(int) (void Function(int)))*/ /*analyzer.space=A<int>(A<int>.member: void Function(int) (void Function(int)))*/ =>
        0,
      A<num>(
        :void Function(num) member
      ) /*cfe.
       error=unreachable,
       space=Never(A<num>.member: void Function(num) (void Function(num)))
      */ /*analyzer.space=A<num>(A<num>.member: void Function(num) (void Function(num)))*/ =>
        1,
    };

unreachable(
        A<num>
            a) => /*cfe.
             fields={A<int>.member:void Function(int),A<num>.member:void Function(num)},
             type=Never
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
      ) /*cfe.space=Never(A<num>.member: void Function(num) (void Function(num)))*/ /*analyzer.space=A<num>(A<num>.member: void Function(num) (void Function(num)))*/ =>
        1,
      A<int>(
        :var member
      ) /*cfe.
       error=unreachable,
       space=Never(A<int>.member: void Function(int) (void Function(int)))
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
             type=Never
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
      ) /*cfe.space=Never(A<num>.member: void Function(num) (void Function(num)))*/ /*analyzer.space=A<num>(A<num>.member: void Function(num) (void Function(num)))*/ =>
        1,
      A<int>(
        :var member
      ) /*cfe.
       error=unreachable,
       space=Never(A<int>.member: void Function(int) (void Function(int)))
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

// TODO(johnniwinther): This should be exhaustive.
num exhaustiveMixed(
        I<num>
            i) => /*
 error=non-exhaustive:I<num>(member: double()),
 fields={I<num>.member:num,J<num>.member:num},
 type=I<num>
*/
    switch (i) {
      I<num>(:int member) /*space=I<num>(I<num>.member: int (num))*/ => member,
      J<num>(:double member) /*space=J<num>(J<num>.member: double (num))*/ =>
        member,
    };
