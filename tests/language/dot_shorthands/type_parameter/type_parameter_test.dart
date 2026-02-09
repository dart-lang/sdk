// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing `id<type>()` uses the correct type parameters.

import '../dot_shorthand_helper.dart';

import "package:expect/expect.dart";

class A<T, U> {
  static A<X, Y> method<X, Y>(X x, Y y) => A<X, Y>.ctor(x, y);

  final T? x;
  final U? y;
  A.ctor(this.x, this.y);
}

void main() {
  StaticMember<int> sMemberType = .memberType<int, String>(1);
  StaticMemberExt<int> sExtMemberType = .memberType<int, String>(1);

  A aMethod = .method<int, int>(1, 2);
  Expect.type<A<int, int>>(aMethod);

  A aCall = .method<int, int>.call(1, 2);
  Expect.type<A<int, int>>(aCall);

  // With constructor invocations, the shorthand expression is preceded by
  // the raw type and then type inference infers the type arguments.
  List<String> l =
    .generate(10, (int i) => i + 1).map((x) => x.toRadixString(16)).toList();
}
