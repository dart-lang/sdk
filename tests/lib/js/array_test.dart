// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library array_test;

import 'package:expect/expect.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js;

main() {
  testArrayConstructor();
}

/// Test that we can access .constructor() on a JS Array instance, regardless
/// of the reified generic type.
///
/// Regression test for https://github.com/dart-lang/sdk/issues/36372
testArrayConstructor() {
  var list = <int>[1, 2, 3];
  testArray = list;

  // Call the consturctor with `new`.
  var array = js.callConstructor(js.getProperty(testArray, 'constructor'), []);
  var list2 = array as List;
  Expect.listEquals(list2, []);
  Expect.notEquals(list, list2, '$list2 should be a new list');

  // We could return a reified type here, but currently does not to match
  // dart2js, and because the Array is being returned to JS.
  Expect.isFalse(list2 is List<int>,
      '$list2 should not have a reified generic type (it was allocated by JS)');

  list2.addAll([1, 2, 3]);
  Expect.listEquals(list, list2);
}

external Object get testArray;
external set testArray(value);
