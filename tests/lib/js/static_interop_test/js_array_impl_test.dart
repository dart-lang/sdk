// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that JS backed [List] classes behaves correctly.

import 'dart:math';
import 'dart:js_interop';

import 'package:expect/expect.dart';

// We run many tests in three configurations:
// 1) Test should ensure receivers for all [List] operations will be
// `JSArrayImpl`.
// 2) Test should ensure arguments to all [List] operations will be
// `JSArrayImpl`.
// 3) Test should ensure both receivers and arguments for all [List] operations
// will be `JSArrayImpl`.
enum TestMode {
  jsReceiver,
  jsArgument,
  jsReceiverAndArguments,
}

enum Position {
  jsReceiver,
  jsArgument,
}

bool useJSType(Position pos, TestMode mode) =>
    (pos == Position.jsReceiver &&
        (mode == TestMode.jsReceiver ||
            mode == TestMode.jsReceiverAndArguments)) ||
    (pos == Position.jsArgument &&
        (mode == TestMode.jsArgument ||
            mode == TestMode.jsReceiverAndArguments));

// We test two types of round-trips from Dart to JS to Dart:
// - A copy that `toJS` creates that then gets wrapped by JSArrayImpl
// - A proxy that `toJSProxyOrRef` creates that then gets wrapped by JSArrayImpl
List<T> jsList<T extends JSAny?>(List<T> l, bool testProxy) {
  final arr = testProxy ? l.toJS : l.toJSProxyOrRef;
  return arr.toDart;
}

String jsString(String s) => s.toJS.toDart;

extension ListJSAnyExtension on List<JSAny?> {
  List<double?> get toListDouble =>
      this.map((a) => (a as JSNumber?)?.toDartDouble).toList();
}

extension ListNumExtension on List<num?> {
  List<T> toListT<T extends JSAny?>() =>
      this.map<T>((n) => n?.toJS as T).toList();

  List<T> toJSListT<T extends JSAny?>(bool testProxy) =>
      jsList<T>(this.toListT<T>(), testProxy);
}

extension NullableJSAnyExtension on JSAny? {
  double? get toDouble => (this as JSNumber?)?.toDartDouble;
}

extension JSAnyExtension on JSAny {
  double get toDouble => (this as JSNumber).toDartDouble;
}

// Test the list methods that need to take in a list using the `mode` to
// indicate whether the receiver or the argument or both are `JSArrayImpl` on
// dart2wasm. `T` here is the type of the list to use (either `JSAny?` or
// `JSArray?`) and `testProxy` determines whether we do a round trip conversion
// using a potentially proxied list or the default `toJS` conversion.
void modedTests<T extends JSAny?>(TestMode mode, {required bool testProxy}) {
  List<T> rListDouble(List<double> l) => useJSType(Position.jsReceiver, mode)
      ? l.toJSListT<T>(testProxy)
      : l.toListT<T>();

  List<T> aListDouble(List<double> l) => useJSType(Position.jsArgument, mode)
      ? l.toJSListT<T>(testProxy)
      : l.toListT<T>();

  var rlist = rListDouble([1, 2, 3, 4]);

  // setRange
  rlist.setRange(0, 4, aListDouble([3, 2, 1, 0]));
  Expect.listEquals([3, 2, 1, 0], rlist.toListDouble);

  var alist = aListDouble([3, 2, 1, 0]);
  rlist.setRange(1, 4, alist);
  Expect.listEquals([3, 3, 2, 1], rlist.toListDouble);

  alist = aListDouble([3, 3, 2, 1]);
  rlist.setRange(0, 3, alist, 1);
  Expect.listEquals([3, 2, 1, 1], rlist.toListDouble);

  alist = aListDouble([3, 2, 1, 1]);
  rlist.setRange(0, 3, alist, 1);
  Expect.listEquals([2, 1, 1, 1], rlist.toListDouble);

  alist = aListDouble([2, 1, 1, 1]);
  rlist.setRange(2, 4, alist, 0);
  Expect.listEquals([2, 1, 2, 1], rlist.toListDouble);

  // setAll
  rlist.setAll(0, aListDouble([3, 2, 0, 1]));
  Expect.listEquals([3, 2, 0, 1], rlist.toListDouble);

  rlist.setAll(1, aListDouble([0, 1]));
  Expect.listEquals([3, 0, 1, 1], rlist.toListDouble);

  // insertAll
  rlist.clear();
  rlist.insertAll(0, aListDouble(<double>[]));
  Expect.isTrue(rlist.isEmpty);

  rlist.insertAll(0, aListDouble([1, 2, 3]));
  Expect.listEquals([1, 2, 3], rlist.toListDouble);

  rlist.insertAll(3, aListDouble([4, 5, 6]));
  Expect.listEquals([1, 2, 3, 4, 5, 6], rlist.toListDouble);

  // addAll
  rlist.clear();
  rlist.addAll(aListDouble(<double>[]));
  Expect.isTrue(rlist.isEmpty);

  rlist.addAll(aListDouble([1, 2, 3]));
  Expect.listEquals([1, 2, 3], rlist.toListDouble);

  rlist.addAll(aListDouble([4, 5, 6]));
  Expect.listEquals([1, 2, 3, 4, 5, 6], rlist.toListDouble);

  // replaceRange
  rlist.replaceRange(0, 2, aListDouble([3, 4]));
  Expect.listEquals([3, 4, 3, 4, 5, 6], rlist.toListDouble);

  rlist.replaceRange(0, 0, aListDouble([1, 1, 1]));
  Expect.listEquals([1, 1, 1, 3, 4, 3, 4, 5, 6], rlist.toListDouble);

  rlist.clear();
  rlist.replaceRange(0, 0, aListDouble([1]));
  Expect.listEquals([1], rlist.toListDouble);

  // operator+
  rlist = rListDouble([1, 2]);
  alist = aListDouble([3, 4]);
  Expect.listEquals([1, 2, 3, 4], (rlist + alist).toListDouble);

  rlist = rListDouble([]);
  alist = aListDouble([3, 4]);
  Expect.listEquals([3, 4], (rlist + alist).toListDouble);

  rlist = rListDouble([1, 2]);
  alist = aListDouble([]);
  Expect.listEquals([1, 2], (rlist + alist).toListDouble);
}

// Test the list methods that don't need to take in a list, and therefore the
// mode does not matter. `T` here is the type of the list to use (either
// `JSAny?` or `JSArray?`) and `testProxy` determines whether we do a
// round trip conversion using a potentially proxied list or the default
// `toJS` conversion.
void nonModedTests<T extends JSAny?>({required bool testProxy}) {
  List<T> toJSList(List<num?> l) => l.toJSListT<T>(testProxy);

  var list = toJSList([1, 2, 3, 4]);

  // iteration
  var count = 0;
  for (var _ in toJSList(<num>[])) {
    Expect.equals(true, false);
    count++;
  }
  Expect.equals(0, count);

  for (var i in toJSList([1])) {
    Expect.equals(1, i?.toDouble);
    count++;
  }
  Expect.equals(1, count);

  var index = 1;
  for (var i in list) {
    Expect.equals(index++, i?.toDouble);
    count++;
  }
  Expect.equals(5, count);

  // length
  Expect.equals(4, list.length);
  list.length = 3;
  Expect.equals(3, list.length);
  Expect.listEquals([1, 2, 3], list.toListDouble);
  list.length = 4;
  Expect.listEquals([1, 2, 3, null], list.toListDouble);

  // operators [], []=
  Expect.equals(1, list[0]?.toDouble);
  list[0] = 5.toJS as T;
  Expect.equals(5, list[0]?.toDouble);
  list[0] = null as T;
  Expect.equals(null, list[0]);

  // indexOf, lastIndexOf
  list = toJSList([0, 1, 2, 3]);
  for (var i = 0; i < 4; i++) {
    Expect.equals(i, list[i]?.toDouble);
    Expect.equals(i, list.indexOf(i.toJS as T));
    Expect.equals(i, list.lastIndexOf(i.toJS as T));
  }

  // fillRange
  list = toJSList([3, 3, 3, 1]);
  list.fillRange(1, 3);
  Expect.listEquals([3, null, null, 1], list.toListDouble);

  list.fillRange(1, 3, 7.toJS as T);
  Expect.listEquals([3, 7, 7, 1], list.toListDouble);

  list.fillRange(0, 0, 9.toJS as T);
  Expect.listEquals([3, 7, 7, 1], list.toListDouble);

  list.fillRange(4, 4, 9.toJS as T);
  Expect.listEquals([3, 7, 7, 1], list.toListDouble);

  list.fillRange(0, 4, 9.toJS as T);
  Expect.listEquals([9, 9, 9, 9], list.toListDouble);

  // sort
  list.setRange(0, 4, toJSList([3, 2, 1, 0]));
  list.sort();
  Expect.listEquals([0, 1, 2, 3], list.toListDouble);

  // Iterable methods
  list = toJSList([0, 1, 2, 3]);
  Expect.listEquals([0, 2, 4, 6], list.map((v) => v!.toDouble * 2).toList());

  bool matchAll(T _) => true;
  bool matchNone(T _) => false;
  bool matchSome(T v) {
    double d = v!.toDouble;
    return d == 1 || d == 2;
  }

  bool matchFirst(T v) => v!.toDouble == 0;
  bool matchLast(T v) => v!.toDouble == 3;

  // where
  Expect.listEquals([1, 2], list.where(matchSome).toList().toListDouble);

  // every
  Expect.isTrue(list.every(matchAll));
  Expect.isFalse(list.every(matchSome));
  Expect.isFalse(list.every(matchNone));

  // any
  Expect.isTrue(list.any(matchAll));
  Expect.isTrue(list.any(matchSome));
  Expect.isTrue(list.any(matchFirst));
  Expect.isTrue(list.any(matchLast));
  Expect.isFalse(list.any(matchNone));

  // add, removeLast
  list.clear();
  Expect.equals(0, list.length);
  Expect.isTrue(list.isEmpty);
  list.add(4.toJS as T);
  Expect.isTrue(list.isNotEmpty);
  Expect.equals(1, list.length);
  Expect.equals(4, list.removeLast()?.toDouble);
  Expect.equals(0, list.length);
  list.add(null as T);
  Expect.equals(null, list.removeLast());

  // remove
  list = toJSList([1, 2, 3, 4, 4]);
  Expect.isTrue(list.remove(4.toJS));
  Expect.listEquals([1, 2, 3, 4], list.toListDouble);

  // removeWhere
  list = toJSList([1, 2, 3, 4]);
  list.removeWhere((T v) => v!.toDouble % 2 == 0);
  Expect.listEquals([1, 3], list.toListDouble);

  // retainWhere
  list = toJSList([1, 2, 3, 4]);
  list.retainWhere((T v) => v!.toDouble % 2 == 0);
  Expect.listEquals([2, 4], list.toListDouble);

  // insert
  list.clear();
  list.insert(0, 0.toJS as T);
  Expect.listEquals([0], list.toListDouble);
  list.insert(0, 1.toJS as T);
  Expect.listEquals([1, 0], list.toListDouble);
  list.insert(2, 2.toJS as T);
  Expect.listEquals([1, 0, 2], list.toListDouble);
  list.insert(0, null as T);
  Expect.listEquals([null, 1, 0, 2], list.toListDouble);

  // removeAt
  list.removeAt(0);
  Expect.listEquals([1, 0, 2], list.toListDouble);
  list.removeAt(1);
  Expect.listEquals([1, 2], list.toListDouble);

  // reversed
  list = toJSList([1, 2, 3, 4, 5, 6]);
  Expect.listEquals([6, 5, 4, 3, 2, 1], list.reversed.toList().toListDouble);

  // forEach
  list = toJSList([1, 2, 3]);
  index = 0;
  list.forEach((v) {
    index++;
    Expect.equals(index, v!.toDouble);
  });
  Expect.equals(index, list.length);

  // join
  list = toJSList([0, 1, 2]);
  Expect.equals('0,1,2', list.join(','));
  Expect.equals('0,1,2', list.join(jsString(',')));

  Expect.equals('012', list.join());

  list = toJSList(<int>[]);
  Expect.equals('', list.join(','));
  Expect.equals('', list.join(jsString(',')));

  // take
  list = toJSList([1, 2, 3]);
  Expect.listEquals([], list.take(0).toList().toListDouble);
  Expect.listEquals([1], list.take(1).toList().toListDouble);

  // takeWhile
  Expect.listEquals(
      [],
      list
          .takeWhile((n) => (n as JSNumber).toDouble > 3)
          .toList()
          .toListDouble);
  Expect.listEquals([
    1,
    2
  ], list.takeWhile((n) => (n as JSNumber).toDouble < 3).toList().toListDouble);

  // skip
  Expect.listEquals([1, 2, 3], list.skip(0).toList().toListDouble);
  Expect.listEquals([2, 3], list.skip(1).toList().toListDouble);

  // skipWhile
  Expect.listEquals([
    1,
    2,
    3
  ], list.skipWhile((n) => (n as JSNumber).toDouble > 3).toList().toListDouble);
  Expect.listEquals(
      [],
      list
          .skipWhile((n) => (n as JSNumber).toDouble < 4)
          .toList()
          .toListDouble);

  // reduce
  Expect.equals(
      6,
      (list.reduce((a, b) =>
              ((a as JSNumber).toDouble + (b as JSNumber).toDouble).toJS
                  as T) as JSNumber)
          .toDartDouble);

  // fold
  Expect.equals(
      6, list.fold<double>(0, (a, b) => a + (b as JSNumber).toDouble));

  // firstWhere
  Expect.equals(
      1, list.firstWhere((a) => (a as JSNumber).toDartDouble == 1).toDouble);
  Expect.equals(
      45,
      list
          .firstWhere((a) => (a as JSNumber).toDartDouble == 4,
              orElse: () => 45.toJS as T)
          .toDouble);

  // lastWhere
  list = toJSList([1, 2, 3, 4]);
  Expect.equals(
      4, list.lastWhere((a) => (a as JSNumber).toDartDouble % 2 == 0).toDouble);
  Expect.equals(
      45,
      list
          .lastWhere((a) => (a as JSNumber).toDartDouble == 5,
              orElse: () => 45.toJS as T)
          .toDouble);

  // singleWhere
  Expect.equals(
      1, list.singleWhere((a) => (a as JSNumber).toDartDouble == 1).toDouble);
  Expect.throwsStateError(
      () => list.singleWhere((a) => (a as JSNumber).toDartDouble % 2 == 0));
  Expect.equals(
      45,
      list
          .singleWhere((a) => (a as JSNumber).toDartDouble == 5,
              orElse: () => 45.toJS as T)
          .toDouble);

  // sublist
  Expect.listEquals([1, 2, 3, 4], list.sublist(0).toListDouble);
  Expect.listEquals([2, 3, 4], list.sublist(1).toListDouble);
  Expect.listEquals([], list.sublist(0, 0).toListDouble);
  Expect.listEquals([1], list.sublist(0, 1).toListDouble);
  Expect.listEquals([2], list.sublist(1, 2).toListDouble);

  // getRange
  Expect.listEquals([1, 2, 3, 4], list.getRange(0, 4).toList().toListDouble);
  Expect.listEquals([2, 3, 4], list.getRange(1, 4).toList().toListDouble);
  Expect.listEquals([2, 3], list.getRange(1, 3).toList().toListDouble);
  Expect.listEquals([1, 2, 3], list.getRange(0, 3).toList().toListDouble);

  // removeRange
  list.removeRange(0, 4);
  Expect.listEquals([], list.toListDouble);

  list = toJSList([1, 2, 3, 4]);
  list.removeRange(1, 4);
  Expect.listEquals([1], list.toListDouble);

  list = toJSList([1, 2, 3, 4]);
  list.removeRange(1, 3);
  Expect.listEquals([1, 4], list.toListDouble);

  list = toJSList([1, 2, 3, 4]);
  list.removeRange(0, 3);
  Expect.listEquals([4], list.toListDouble);

  // shuffle
  list = toJSList([1, 2, 3, 4]);
  list.shuffle(MockRandom(4));
  Expect.listEquals([4, 2, 3, 1], list.toListDouble);

  list = toJSList([1, 2, 3, 4]);
  list.shuffle();
  Expect.equals(4, list.length);
  Expect.isTrue(list.contains(1.toJS));
  Expect.isTrue(list.contains(2.toJS));
  Expect.isTrue(list.contains(3.toJS));
  Expect.isTrue(list.contains(4.toJS));
}

void runAllTests() {
  for (final mode in [
    TestMode.jsReceiver,
    TestMode.jsArgument,
    TestMode.jsReceiverAndArguments
  ]) {
    modedTests<JSAny?>(mode, testProxy: true);
    modedTests<JSAny?>(mode, testProxy: false);
    modedTests<JSNumber?>(mode, testProxy: true);
    modedTests<JSNumber?>(mode, testProxy: false);
  }
  nonModedTests<JSAny?>(testProxy: true);
  nonModedTests<JSAny?>(testProxy: false);
  nonModedTests<JSNumber?>(testProxy: true);
  nonModedTests<JSNumber?>(testProxy: false);
}

void main() {
  runAllTests();
}

// Will swap the first and last items in a list, while leaving the the middle
// elements in place because they will be swapped and then swapped back as
// shuffle iterates through the list.
class MockRandom implements Random {
  int index = 0;
  final int max;

  MockRandom(this.max);

  int nextInt(int limit) {
    return index++;
  }

  double nextDouble() => throw 'Not supported';

  bool nextBool() => throw 'Not supported';
}
