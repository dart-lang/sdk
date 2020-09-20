// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  List<int> l = [1, 2, 3].where((x) => x.isEven).map((x) => x + 1);
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                                             ^
  // [cfe] A value of type 'Iterable<int>' can't be assigned to a variable of type 'List<int>'.

  {
    // Works.
    C<Object> c = C<Object>(1);
    Iterable<bool Function(Object)> myList = c.f();
  }

  {
    C<Object> c = C<Object>(1);
    List<bool Function(Object)> myList = c.f();
    //                                   ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                                     ^
    // [cfe] A value of type 'Iterable<bool Function(Object)>' can't be assigned to a variable of type 'List<bool Function(Object)>'.
  }

  {
    C<Object> c = C<int>(1);
    List<bool Function(Object)> myList = c.f();
    //                                   ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                                     ^
    // [cfe] A value of type 'Iterable<bool Function(Object)>' can't be assigned to a variable of type 'List<bool Function(Object)>'.
  }

  {
    C<Object> c = C<int>(1);
    Iterable<bool Function(Object)> myList = c.f();
  }

  {
    // Works.
    C<Iterable<Object>> c = D<Object>([1]);
    Iterable<bool Function(Iterable<Object>)> myList = c.f();
  }

  {
    C<Iterable<Object>> c = D<Object>([1]);
    List<bool Function(Iterable<Object>)> myList = c.f();
    //                                             ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //                                               ^
    // [cfe] A value of type 'Iterable<bool Function(Iterable<Object>)>' can't be assigned to a variable of type 'List<bool Function(Iterable<Object>)>'.
  }

  {
    C<Iterable<Object>> c = D<int>([1]);
    Iterable<bool Function(Iterable<Object>)> myList = c.f();
  }
}

class C<T> {
  final T t;
  C(this.t);
  Iterable<bool Function(T)> f() sync* {
    yield (T x) => x == t;
  }
}

class D<S> extends C<Iterable<S>> {
  D(Iterable<S> s) : super(s);
}
