// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  // Ensure all classes are used.
  final l = <dynamic>[Base(), A<int>(), B<int>(), I<int>()];
  print(l);

  // Call `add(T)` with `T = A<int/String>` (the VM will not generate an
  // optimized TTS for `A<int>` because there's two classes implementing
  // `A`, both have type argument vector at a different offset, so it wouldn't
  // know where to load it from)

  // Populate the SubtypeTestCache with successfull `add(I<String>())`.
  final x = <dynamic>[<A<String>>[]];
  x.single.add(I<String>());

  // Ensure type check fails if list type is now `A<int>`.
  final y = <dynamic>[<A<int>>[]];
  String exception = '';
  try {
    y.single.add(I<String>());
  } catch (e) {
    exception = e.toString();
  }
  print(exception);
  Expect.isTrue(exception.contains('is not a subtype of'));
}

// Ensure depth-first preorder cid numbering will have the cid for [A] in the
// middle and ensure type argument vector will be second field.
class Base {
  final int baseField = int.parse('1');
}

class A<T> extends Base {
  T foo(T arg) => arg;
}

class B<T> extends A<T> {}

// Make another implementation of A<T> where type argument vector is first
// field.
class I<T> implements A<T> {
  int get baseField => int.parse('2');
  T foo(T arg) => arg;
}
