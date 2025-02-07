// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the JS array proxy or reference that's created for lists for interop.

import 'dart:js_interop';
import 'package:expect/expect.dart';

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

extension JSArrayExtension<T extends JSAny?> on JSArray<T> {
  external int at(int i);
  external JSArray<T> concat([
    JSArray<T> arg1,
    JSArray<T> arg2,
    JSArray<T> arg3,
    JSArray<T> arg4,
  ]);
  external void forEach(JSFunction callback, [JSObject thisObj]);
  external int indexOf(JSAny? element, [int? fromIndex]);
  external bool includes(JSAny? element, [int? fromIndex]);
  external String join([String? delimiter]);
  external int pop();
  external int push([T arg1, T arg2, T arg3]);
  external JSArray<T> slice([int? start, int? end]);
  external JSArray<T> splice([
    int? start,
    int? deleteCount,
    T arg1,
    T arg2,
    T arg3,
    T arg4,
  ]);
}

void main() {
  final numList = <int?>[4, 3, 2, 1, 0].map((e) => e?.toJS).toList();
  final numProxy = numList.toJSProxyOrRef;
  final roundTripProxy = numProxy.toDart.toJSProxyOrRef;
  Expect.equals(roundTripProxy, numProxy);

  // `length`/`[]`/`at`/`[]=`
  numProxy.length = 6;
  Expect.equals(6, numList.length);
  Expect.equals(numList.length, numProxy.length);
  numList.length = 5;
  Expect.equals(numList.length, numProxy.length);
  for (var i = 0; i < numProxy.length; i++) {
    Expect.equals(numProxy[i]!.toDartInt, numProxy.length - i - 1);
    Expect.equals(numProxy.at(i), numProxy.length - i - 1);

    numProxy[i] = i.toJS;

    Expect.equals(i, numProxy[i]!.toDartInt);
    Expect.equals(i, numProxy.at(i));
    // Test negative indexing.
    Expect.equals(i, numProxy.at(i - numProxy.length));
    Expect.equals(i, numList[i]!.toDartInt);
  }

  // `includes`/`indexOf`
  Expect.isTrue(numProxy.includes(0.toJS));
  Expect.isFalse(numProxy.includes(0.toJS, 1));
  Expect.isFalse(numProxy.includes(5.toJS));
  Expect.equals(0, numProxy.indexOf(0.toJS));
  Expect.equals(-1, numProxy.indexOf(0.toJS, 1));
  Expect.equals(-1, numProxy.indexOf(5.toJS));

  // `pop`/`push`
  Expect.equals(numList.length + 1, numProxy.push(5.toJS));
  Expect.equals(numList.length, numProxy.length);
  Expect.equals(6, numList.length);
  Expect.equals(5, numList[5]!.toDartInt);

  Expect.equals(5, numProxy.pop());
  Expect.equals(numList.length, numProxy.length);
  Expect.equals(5, numList.length);

  Expect.equals(8, numProxy.push(5.toJS, 6.toJS, 7.toJS));
  Expect.equals(11, numProxy.push(8.toJS, null, null));
  Expect.equals(11, numList.length);
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
  Expect.equals(numList.length, iterateAndValidateArray(numProxy));

  // `forEach`
  var numElements = 0;
  numProxy.forEach(
    (int element, int index, JSArray array) {
      Expect.equals(element, numElements);
      Expect.equals(index, numElements);
      Expect.equals(array, numProxy);
      numElements++;
    }.toJS,
  );
  Expect.equals(numList.length, numElements);

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
  Expect.equals(numList.length, counter.numElements);

  // `slice`, `splice`, and `concat`
  void testEquals(JSArray<JSNumber?> arr, List<int> list) {
    final len = list.length;
    for (var i = 0; i < len; i++) {
      Expect.equals(arr[i]!.toDartInt, list[i]);
    }
  }

  final sliced = numProxy.slice(4, 9);
  testEquals(sliced, [4, 5, 6, 7, 8]);
  Expect.equals(9, numList.length);
  final deleted = numProxy.splice(4, 5);
  testEquals(deleted, [4, 5, 6, 7, 8]);
  Expect.equals(4, numList.length);

  final deleted2 = numProxy.splice(0, 4, 3.toJS, 2.toJS, 1.toJS, 0.toJS);
  testEquals(deleted2, [0, 1, 2, 3]);
  testEquals(numProxy, [3, 2, 1, 0]);
  testEquals(numProxy.concat(deleted2), [3, 2, 1, 0, 0, 1, 2, 3]);

  // `join`
  Expect.equals('3-2-1-0', numProxy.join('-'));
  Expect.equals('3,2,1,0', numProxy.join());

  // TODO(srujzs): Test the remaining JS Array methods. While we cover the
  // common ones and the ones needed for JSArrayImpl, we might be missing some
  // subtleties (like `isConcatSpreadble` for example) or missing handler
  // methods that are needed other Array methods.
}
