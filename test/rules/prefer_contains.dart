// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file

// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_contains`

const int MINUS_ONE = -1;

List<int> list = [];

List get getter => [];

typedef List F();

F a() {
  return () => [];
}

bool le = list.indexOf(1) > -1; //LINT

bool le2 = [].indexOf(1) > -1; //LINT

bool le3 = ([].indexOf(1) as int) > -1; //LINT

bool le4 = -1 < list.indexOf(1); //LINT

bool le5 = [].indexOf(1) < MINUS_ONE; //LINT

bool le6 = MINUS_ONE < [].indexOf(1); //LINT

bool ge = getter.indexOf(1) != -1; //LINT

bool ce = a()().indexOf(1) == -1; //LINT

bool se = "aaa".indexOf('a') == -1; //LINT

int ser = "aaa".indexOf('a', 2); //OK

bool mixed = list.indexOf(1) + "a".indexOf("ab") > 0; //OK

condition() {
  final int a = list.indexOf(1) > -1 ? 2 : 3; //LINT
  list..indexOf(1);
  var next;
  while ((next = list.indexOf('{')) != -1) {} //OK
}

bool le7 = [].indexOf(1) > 1; //OK

testOperators() {
  [].indexOf(1) == -1; // LINT
  [].indexOf(1) != -1; // LINT
  [].indexOf(1) > -1; // LINT
  [].indexOf(1) >= -1; // LINT
  [].indexOf(1) < -1; // LINT
  [].indexOf(1) <= -1; // LINT

  [].indexOf(1) == -2; // LINT
  [].indexOf(1) != -2; // LINT
  [].indexOf(1) > -2; // LINT
  [].indexOf(1) >= -2; // LINT
  [].indexOf(1) < -2; // LINT
  [].indexOf(1) <= -2; // LINT

  [].indexOf(1) == 0; // OK
  [].indexOf(1) != 0; // OK
  [].indexOf(1) > 0; // OK
  [].indexOf(1) >= 0; // LINT
  [].indexOf(1) < 0; // LINT
  [].indexOf(1) <= 0; // OK

  -1 == [].indexOf(1); // LINT
  -1 != [].indexOf(1); // LINT
  -1 < [].indexOf(1); // LINT
  -1 <= [].indexOf(1); // LINT
  -1 > [].indexOf(1); // LINT
  -1 >= [].indexOf(1); // LINT

  -2 == [].indexOf(1); // LINT
  -2 != [].indexOf(1); // LINT
  -2 < [].indexOf(1); // LINT
  -2 <= [].indexOf(1); // LINT
  -2 > [].indexOf(1); // LINT
  -2 >= [].indexOf(1); // LINT

  0 == [].indexOf(1); // OK
  0 != [].indexOf(1); // OK
  0 < [].indexOf(1); // OK
  0 <= [].indexOf(1); // LINT
  0 > [].indexOf(1); // LINT
  0 >= [].indexOf(1); // OK
}
