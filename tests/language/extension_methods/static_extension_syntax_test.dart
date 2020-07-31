// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests extension declaration syntax combinations.

import "package:expect/expect.dart";

void checkStaticType<T>(T x) {
  Expect.type<T>(x);
}

main() {
  Object object = <int>[];
  List<Object> list = <int>[];
  List<num> numList = <int>[];
  Pair<int, double> numPair = Pair(1, 2.5);
  RecSolution recs = RecSolution();

  Expect.equals(0, object.e0);
  Expect.equals(0, list.e0);

  Expect.equals(1, object.e1);
  Expect.equals(1, list.e1);

  Expect.equals(0, object.e4);
  Expect.equals(0, list.e4);
  Expect.equals(4, numList.e4);

  Expect.equals(0, object.e5);
  Expect.equals(0, list.e5);
  Expect.equals(5, numList.e5);

  Expect.equals(0, object.e6);
  Expect.equals(6, list.e6);
  Expect.equals(6, numList.e6);
  checkStaticType<List<num>>(numList.list6);

  Expect.equals(0, object.e7);
  Expect.equals(7, list.e7);
  Expect.equals(7, numList.e7);
  checkStaticType<List<num>>(numList.list7);

  Expect.equals(10, object.e10);
  Expect.equals(10, numList.e10);
  checkStaticType<List<Object>>(object.list10);
  checkStaticType<List<List<num>>>(numList.list10);

  Expect.equals(11, object.e11);
  Expect.equals(11, numList.e11);
  checkStaticType<List<Object>>(object.list11);
  checkStaticType<List<List<num>>>(numList.list11);

  Expect.equals(0, object.e14);
  Expect.equals(14, numPair.e14);
  Expect.type<List<num>>(numPair.list14);
  checkStaticType<List<num>>(numPair.list14);

  Expect.equals(0, object.e16);
  Expect.equals(16, numPair.e16);
  Expect.type<Map<int, double>>(numPair.map16);
  checkStaticType<Map<int, double>>(numPair.map16);

  Expect.equals(0, object.e17);
  Expect.equals(0, list.e17);
  Expect.equals(17, numList.e17);
  Expect.type<List<num>>(numList.list17);
  checkStaticType<List<num>>(numList.list17);

  Expect.equals(0, object.e19);
  Expect.equals(19, recs.e19);
  Expect.type<List<RecSolution>>(recs.list19);
  checkStaticType<List<RecSolution>>(recs.list19);

  Expect.equals(0, object.e20);
  Expect.equals(20, recs.e20);
  Expect.type<List<RecSolution>>(recs.list20);
  checkStaticType<List<RecSolution>>(recs.list20);
}

extension on Object {
  int get e0 => 0;
  // Fallbacks to test cases where other extensions do not apply.
  int get e4 => 0;
  int get e5 => 0;
  int get e6 => 0;
  int get e7 => 0;
  int get e14 => 0;
  int get e16 => 0;
  int get e17 => 0;
  int get e19 => 0;
  int get e20 => 0;
}

extension E1 on Object {
  int get e1 => 1;
}

extension on List<num> {
  int get e4 => 4;
}

extension E5 on List<num> {
  int get e5 => 5;
}

extension<T> on List<T> {
  int get e6 => 6;
  List<T> get list6 => <T>[];
}

extension E7<T> on List<T> {
  int get e7 => 7;
  List<T> get list7 => <T>[];
}

extension<T> on T {
  int get e10 => 10;
  List<T> get list10 => <T>[];
}

extension E11<T> on T {
  int get e11 => 11;
  List<T> get list11 => <T>[];
}

extension<T> on Pair<T, T> {
  int get e14 => 14;
  List<T> get list14 => <T>[];
}

extension E16<S, T> on Pair<S, T> {
  int get e16 => 16;
  Map<S, T> get map16 => <S, T>{};
}

extension<T extends num> on List<T> {
  int get e17 => 17;
  List<T> get list17 => <T>[];
}

extension<T extends Rec<T>> on T {
  int get e19 => 19;
  List<T> get list19 => <T>[];
}

extension E20<T extends Rec<T>> on T {
  int get e20 => 20;
  List<T> get list20 => <T>[];
}

class Pair<A, B> {
  final A first;
  final B second;
  const Pair(this.first, this.second);
}

class Rec<T extends Rec<T>> {}

class RecSolution extends Rec<RecSolution> {}
