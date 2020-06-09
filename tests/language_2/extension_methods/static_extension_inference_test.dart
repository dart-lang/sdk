// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests extension method resolution type inference.

import "package:expect/expect.dart";

void main() {
  List<num> numList = <int>[];
  // Inference of E1(numList), implicit or explicit, is the same as
  // for C1(numList), which infers `num`.
  var numListInstance1 = C1<num>(numList);

  Expect.type<List<num>>(numList.argList1);
  sameType(numListInstance1.argDynList1, numList.argDynList1);
  sameType(numListInstance1.selfList1, numList.selfList1);

  Expect.type<List<num>>(E1(numList).argList1);
  sameType(numListInstance1.argDynList1, E1(numList).argDynList1);
  sameType(numListInstance1.selfList1, E1(numList).selfList1);

  var numListInstance2 = C2<List<num>>(numList);

  Expect.type<List<List<num>>>(numList.argList2);
  sameType(numListInstance2.argDynList2, numList.argDynList2);
  sameType(numListInstance2.selfList2, numList.selfList2);

  Expect.type<List<List<num>>>(E2(numList).argList2);
  sameType(numListInstance2.argDynList2, E2(numList).argDynList2);
  sameType(numListInstance2.selfList2, E2(numList).selfList2);

  Pair<int, double> pair = Pair(1, 2.5);
  var pairInstance3 = C3<int, double>(pair);

  Expect.type<List<int>>(pair.argList3);
  Expect.type<List<double>>(pair.arg2List3);
  sameType(pairInstance3.argDynList3, pair.argDynList3);
  sameType(pairInstance3.arg2DynList3, pair.arg2DynList3);
  sameType(pairInstance3.selfList3, pair.selfList3);

  Expect.type<List<int>>(E3(pair).argList3);
  Expect.type<List<double>>(E3(pair).arg2List3);
  sameType(pairInstance3.argDynList3, E3(pair).argDynList3);
  sameType(pairInstance3.arg2DynList3, E3(pair).arg2DynList3);
  sameType(pairInstance3.selfList3, E3(pair).selfList3);

  var pairInstance4 = C4<num>(pair);

  Expect.type<List<num>>(pair.argList4);
  sameType(pairInstance4.argDynList4, pair.argDynList4);
  sameType(pairInstance4.selfList4, pair.selfList4);

  Expect.type<List<num>>(E4(pair).argList4);
  sameType(pairInstance4.argDynList4, E4(pair).argDynList4);
  sameType(pairInstance4.selfList4, E4(pair).selfList4);

  List<int> intList = <int>[1];
  var intListInstance5 = C5<int>(intList);

  Expect.type<List<int>>(intList.argList5);
  sameType(intListInstance5.argDynList5, intList.argDynList5);
  sameType(intListInstance5.selfList5, intList.selfList5);

  Expect.type<List<int>>(E5(intList).argList5);
  sameType(intListInstance5.argDynList5, E5(intList).argDynList5);
  sameType(intListInstance5.selfList5, E5(intList).selfList5);
}

void sameType(o1, o2) {
  Expect.equals(o1.runtimeType, o2.runtimeType);
}

extension E1<T> on List<T> {
  List<T> get argList1 => <T>[];
  List<Object> get argDynList1 => <T>[];
  List<Object> get selfList1 {
    var result = [this];
    return result;
  }
}

class C1<T> {
  List<T> self;
  C1(this.self);
  List<T> get argList1 => <T>[];
  List<Object> get argDynList1 => <T>[];
  List<Object> get selfList1 {
    var result = [self];
    return result;
  }
}

extension E2<T> on T {
  List<T> get argList2 => <T>[];
  List<Object> get argDynList2 => <T>[];
  List<Object> get selfList2 {
    var result = [this];
    return result;
  }
}

class C2<T> {
  T self;
  C2(this.self);
  List<T> get argList2 => <T>[];
  List<Object> get argDynList2 => <T>[];
  List<Object> get selfList2 {
    var result = [self];
    return result;
  }
}

extension E3<S, T> on Pair<T, S> {
  List<T> get argList3 => <T>[];
  List<Object> get argDynList3 => <T>[];
  List<S> get arg2List3 => <S>[];
  List<Object> get arg2DynList3 => <S>[];
  List<Object> get selfList3 {
    var result = [this];
    return result;
  }
}

class C3<T, S> {
  Pair<T, S> self;
  C3(this.self);
  List<T> get argList3 => <T>[];
  List<Object> get argDynList3 => <T>[];
  List<S> get arg2List3 => <S>[];
  List<Object> get arg2DynList3 => <S>[];
  List<Object> get selfList3 {
    var result = [self];
    return result;
  }
}

extension E4<T> on Pair<T, T> {
  List<T> get argList4 => <T>[];
  List<Object> get argDynList4 => <T>[];
  List<Object> get selfList4 {
    var result = [this];
    return result;
  }
}

class C4<T> {
  Pair<T, T> self;
  C4(this.self);
  List<T> get argList4 => <T>[];
  List<Object> get argDynList4 => <T>[];
  List<Object> get selfList4 {
    var result = [self];
    return result;
  }
}

extension E5<T extends num> on List<T> {
  List<T> get argList5 => <T>[];
  List<Object> get argDynList5 => <T>[];
  List<Object> get selfList5 {
    var result = [this];
    return result;
  }
}

class C5<T extends num> {
  List<T> self;
  C5(this.self);
  List<T> get argList5 => <T>[];
  List<Object> get argDynList5 => <T>[];
  List<Object> get selfList5 {
    var result = [self];
    return result;
  }
}

class Pair<A, B> {
  final A first;
  final B second;
  Pair(this.first, this.second);
}
