// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

// Test the JS array proxy or reference that's created for lists for interop.

import 'dart:js_interop';
import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS()
external int iterateAndValidateArray(JSArray array);

@JS()
external Counter get counter;

extension type Counter(JSObject _) implements JSObject {
  external int get numElements;
  external JSFunction get forEachBound;
}

extension on JSArray {
  external int get length;
  external set length(int val);
  external int operator [](int i);
  external void operator []=(int i, int value);
  external int at(int i);
  external JSArray concat([JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]);
  external void forEach(JSFunction callback, [JSObject thisObj]);
  external int indexOf(JSAny? element, [int? fromIndex]);
  external bool includes(JSAny? element, [int? fromIndex]);
  external String join([String? delimiter]);
  external int pop();
  external int push([JSAny? arg1, JSAny? arg2, JSAny? arg3]);
  external JSArray slice([int? start, int? end]);
  external JSArray splice(
      [int? start,
      int? deleteCount,
      JSAny? arg1,
      JSAny? arg2,
      JSAny? arg3,
      JSAny? arg4]);
}

void main() {
  final numList = <int?>[4, 3, 2, 1, 0].map((e) => e?.toJS).toList();
  final numProxy = numList.toJSProxyOrRef;
  final roundTripProxy = numProxy.toDart.toJSProxyOrRef;
  expect(numProxy, roundTripProxy);

  // `length`/`[]`/`at`/`[]=`
  numProxy.length = 6;
  expect(numList.length, 6);
  expect(numProxy.length, numList.length);
  numList.length = 5;
  expect(numProxy.length, numList.length);
  for (var i = 0; i < numProxy.length; i++) {
    expect(numProxy[i], numProxy.length - i - 1);
    expect(numProxy.at(i), numProxy.length - i - 1);

    numProxy[i] = i;

    expect(numProxy[i], i);
    expect(numProxy.at(i), i);
    // Test negative indexing.
    expect(numProxy.at(i - numProxy.length), i);
    expect(numList[i]!.toDartInt, i);
  }

  // `includes`/`indexOf`
  expect(numProxy.includes(0.toJS), true);
  expect(numProxy.includes(0.toJS, 1), false);
  expect(numProxy.includes(5.toJS), false);
  expect(numProxy.indexOf(0.toJS), 0);
  expect(numProxy.indexOf(0.toJS, 1), -1);
  expect(numProxy.indexOf(5.toJS), -1);

  // `pop`/`push`
  expect(numProxy.push(5.toJS), numList.length);
  expect(numProxy.length, numList.length);
  expect(numList.length, 6);
  expect(numList[5]!.toDartInt, 5);

  expect(numProxy.pop(), 5);
  expect(numProxy.length, numList.length);
  expect(numList.length, 5);

  expect(numProxy.push(5.toJS, 6.toJS, 7.toJS), 8);
  expect(numProxy.push(8.toJS, null, null), 11);
  expect(numList.length, 11);
  numList.length = 9; // Remove the `null`s we just added.

  // iteration/for loop
  eval('''
    globalThis.iterateAndValidateArray = function(array) {
      var counter = 0;
      for (const i of array) {
        if (counter != i) break;
        counter++;
      }
      return counter;
    };
  ''');
  expect(iterateAndValidateArray(numProxy), numList.length);

  // `forEach`
  var numElements = 0;
  numProxy.forEach((int element, int index, JSArray array) {
    expect(numElements, element);
    expect(numElements, index);
    expect(numProxy, array);
    numElements++;
  }.toJS);
  expect(numElements, numList.length);

  // `forEach` with a bound this.
  eval('''
    const counter = {
      numElements: 0,
      forEachBound: function (element, index, array) {
        this.numElements++;
      },
    };
    globalThis.counter = counter;
  ''');
  numProxy.forEach(counter.forEachBound, counter);
  expect(counter.numElements, numList.length);

  // `slice`, `splice`, and `concat`
  void testEquals(JSArray arr, List<int> list) {
    final len = list.length;
    for (var i = 0; i < len; i++) {
      expect(arr[i], list[i]);
    }
  }

  final sliced = numProxy.slice(4, 9);
  testEquals(sliced, [4, 5, 6, 7, 8]);
  expect(numList.length, 9);
  final deleted = numProxy.splice(4, 5);
  testEquals(deleted, [4, 5, 6, 7, 8]);
  expect(numList.length, 4);

  final deleted2 = numProxy.splice(0, 4, 3.toJS, 2.toJS, 1.toJS, 0.toJS);
  testEquals(deleted2, [0, 1, 2, 3]);
  testEquals(numProxy, [3, 2, 1, 0]);
  testEquals(numProxy.concat(deleted2), [3, 2, 1, 0, 0, 1, 2, 3]);

  // `join`
  expect(numProxy.join('-'), '3-2-1-0');
  expect(numProxy.join(), '3,2,1,0');

  // TODO(srujzs): Test the remaining JS Array methods. While we cover the
  // common ones and the ones needed for JSArrayImpl, we might be missing some
  // subtleties (like `isConcatSpreadble` for example) or missing handler
  // methods that are needed other Array methods.
}
