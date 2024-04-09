// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type parameters on @staticInterop factories.

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

@JS()
@staticInterop
class Array<T, U extends String> {
  external factory Array(T t, U u);
  factory Array.nonExternal(T t, U u) => Array(t, u);
}

extension on Array {
  external Object operator [](int index);
}

@JS()
@staticInterop
@anonymous
class Anonymous<T, U extends String> {
  external factory Anonymous({T? t, U? u});
  factory Anonymous.nonExternal({T? t, U? u}) => Anonymous(t: t, u: u);
}

extension AnonymousExtension<T, U extends String> on Anonymous<T, U> {
  external T get t;
  external U get u;
}

void main() {
  final arr1 = Array(true, '');
  expect(arr1[0], true);
  expect(arr1[1], '');
  final arr2 = Array<bool, String>(false, '');
  expect(arr2[0], false);
  expect(arr2[1], '');
  final anon1 = Anonymous(t: true, u: '');
  expect(anon1.t, true);
  expect(anon1.u, '');
  final anon2 = Anonymous<bool, String>(t: false, u: '');
  expect(anon2.t, false);
  expect(anon2.u, '');
}
