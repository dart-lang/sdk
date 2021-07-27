// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart' show Expect;

import 'package:kernel/testing/type_parser.dart';

testParse(String text) {
  Expect.stringEquals(text.trim(), "${parse(text).join('\n')}");
}

main() {
  testParse("""
() ->* void
() ->? void
() -> void
(int) -> dynamic
([int]) -> int
({double parameter}) -> int
(num, [int]) -> int
(num, {double parameter}) -> int
(num, {required double parameter}) -> int
class Object;
class Comparable<T>;
class num implements Comparable<num>;
class int extends num;
class double extends num;
class Function;
class Iterable<E>;
class EfficientLength;
class List<E> implements Iterable<E>, EfficientLength;
class Intersection implements Comparable<int>, Comparable<double>;
typedef OtherObject Object;
typedef MyList<T> List<T>;
typedef StringList List<String>;
typedef VoidFunction () -> void;
typedef GenericFunction<T> () -> T;
List<List<Object>>
List<List<List<Object>>>
class A<T extends List<Object>>;
class B<T extends List<List<Object>>>;
<E>(E) -> int
S & T
S & T & U
class C;
<E>(E) -> int & <E>(E) -> void
C*
C?
C
A<C>*
A<C>?
A<C>
A<C*>
A<C?>
A<C>
<T extends bool>(T) -> void
""");
}
