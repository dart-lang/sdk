// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N always_specify_types`

// ignore_for_file: unused_local_variable

import 'package:meta/meta.dart';

/// https://github.com/dart-lang/linter/issues/3275
typedef Foo1 = Map<String, Object>;
final Foo1 foo = Foo1();

/// Constructor tear-offs
void constructorTearOffs() {
  List<List>.filled; // LINT
  List<E> Function<E>(int, E) filledList = List.filled; // OK - generic function
  filledList<int>(3, 3); // OK
  filledList(3, 3); // OK - generic function invocations are uncovered -- see: #2914
}

typedef MapList = List<StringMap>; //LINT
typedef JsonMap = Map<String, dynamic>; //OK
typedef StringList = List<JsonMap>; //OK
typedef RawList = List; //LINT
typedef StringMap<V> = Map<String, V>; //OK

StringMap<String> sm = StringMap<String>(); //OK
StringMap? rm1; //LINT
StringMap<String> rm2 = StringMap(); //LINT
StringMap rm3 = StringMap<String>(); //LINT

Map<String, String> map = {}; //LINT
List<String> strings = []; //LINT
Set<String> set = {}; //LINT

List? list; //LINT
List<List>? lists; //LINT
List<int> ints = <int>[1]; //OK

final x = 1; //LINT [1:5] Missing type annotation.
final x1 = 1, x2 = '', x3 = 1.2; //LINT [1:5]
final int xx = 3;
const y = 2; //LINT Missing type annotation.
const int yy = 3;
String? s1 = '';
var s2 = '', s3 = s1; //LINT Missing type annotation.

a(var x) {} //LINT Missing type annotation.
b(s) {} //LINT [3:1] Missing type annotation.
c(int x) {}
d(final x) {} //LINT
e(final int x) {}

@optionalTypeArgs
class P<T> { }

@optionalTypeArgs
void g<T>() {}

//https://github.com/dart-lang/linter/issues/851
void test() {
  g<dynamic>(); //OK
  g(); //OK
}

main() {
  var x = ''; //LINT [3:3] Missing type annotation.
  var x1 = '', x2 = 1.2; //LINT [3:3]
  for (var i = 0; i < 10; ++i) {  //LINT [8:3] Missing type annotation.
    print(i);
  }
  List<String> ls = <String>[];
  // ignore: avoid_function_literals_in_foreach_calls
  ls.forEach((s) => print(s)); //LINT [15:1] Missing type annotation.
  ls.forEach((var s) => print(s)); //LINT [15:3] Missing type annotation.
  for (var l in ls) { //LINT [8:3] Missing type annotation.
    print(l);
  }
  try {
    for (final l in ls) { // LINT [10:5] Missing type annotation.
      print(l);
    }
  } on Exception catch (ex) {
    print(ex);
  } catch (e) { // NO warning (https://codereview.chromium.org/1427223002/)
    print(e);
  }

  // ignore: non_constant_identifier_names
  var __; // LINT

  listen((_) { // OK!
    // ...
  });

  P p = P(); //OK (optionalTypeArgs)
}

P doSomething(P p) //OK (optionalTypeArgs)
{
  return p;
}

listen(void Function(Object event) onData) {}

var z; //LINT

class Foo {
  static var bar; //LINT
  static final baz = 1; //LINT Missing type annotation.
  static final int bazz = 42;
  var foo; //LINT Missing type annotation.
  Foo(var bar); //LINT [7:3] Missing type annotation.
  void f(List l) { } //LINT
}

void m() {
  if ('' is Map) //OK
  {
    print("won't happen");
  }
}
