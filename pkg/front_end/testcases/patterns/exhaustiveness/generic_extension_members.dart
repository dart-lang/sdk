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

exhaustiveInferred(A<num> a) => switch (a) {
      A<int>(:var member) => 0,
      A<num>(:var member) => 1,
    };

exhaustiveTyped(A<num> a) => switch (a) {
      A<int>(:void Function(int) member) => 0,
      A<num>(:void Function(num) member) => 1,
    };

unreachable(A<num> a) => switch (a) {
      A<num>(:var member) => 1,
      A<int>(:var member) => 0,
    };

nonExhaustiveRestricted(A<num> a) => switch (a) {
      A<num>(:void Function(num) member) => 1,
      A<int>(:var member) => 0,
    };

intersection(o) {
  switch (o) {
    case A<int>(member: var member1) && A<double>(member: var member2):
    case A<int>(member: var member1) && A<num>(member: var member2):
  }
}

// TODO(johnniwinther): This should be exhaustive.
num exhaustiveMixed(I<num> i) => switch (i) {
      I<num>(:int member) => member,
      J<num>(:double member) => member,
    };
