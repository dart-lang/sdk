// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_is_empty`

const l = '';
const bool empty = l.length == 0; //OK

class A {
  final List<String> a;
  const A(this.a) : assert(a.length > 0); //OK
}

class B {
  final String b;
  const B(this.b) : assert(b.length > 0); //OK
}

class C {
  final bool empty;
  const C(dynamic l) : this.empty = l.length == 0; //OK
}


const int zero = 0;
Iterable<int> list = [];
Map map = {};

Iterable get iterable => [];

typedef F = Iterable Function();

F a() => () => [];

bool le = list.length > 0; //LINT
bool le2 = [].length > 0; //LINT
bool le3 = ([].length as int) > 0; //LINT
bool le4 = 0 < list.length; //LINT
bool le5 = [].length < zero;
bool le6 = zero < [].length;
bool me = (map.length) == 0; //LINT
bool ie = iterable.length != 0; //LINT
bool ce = a()().length == 0; //LINT
bool mixed = list.length + map.length > 0; //OK

Iterable length = [];
bool ok = length.first > 0; // OK

void condition() {
  final int a = list.length > 0 ? list.first : 0; //LINT
  list..length;
}

bool le7 = [].length > 1; //OK

void testOperators() {
  [].length == 0; // LINT
  [].length != 0; // LINT
  [].length > 0; // LINT
  [].length >= 0; // LINT
  [].length < 0; // LINT
  [].length <= 0; // LINT

  [].length == -1; // LINT
  [].length != -1; // LINT
  [].length > -1; // LINT
  [].length >= -1; // LINT
  [].length < -1; // LINT
  [].length <= -1; // LINT

  [].length == 1; // OK
  [].length != 1; // OK
  [].length > 1; // OK
  [].length >= 1; // LINT
  [].length < 1; // LINT
  [].length <= 1; // OK

  0 == [].length; // LINT
  0 != [].length; // LINT
  0 < [].length; // LINT
  0 <= [].length; // LINT
  0 > [].length; // LINT
  0 >= [].length; // LINT

  -1 == [].length; // LINT
  -1 != [].length; // LINT
  -1 < [].length; // LINT
  -1 <= [].length; // LINT
  -1 > [].length; // LINT
  -1 >= [].length; // LINT

  1 == [].length; // OK
  1 != [].length; // OK
  1 < [].length; // OK
  1 <= [].length; // LINT
  1 > [].length; // LINT
  1 >= [].length; // OK
}
