// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Partial regression test for #40152.

import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
external dynamic eval(String s);

main() {
  // Regular JS-interop Array.
  var a1 = eval('["hello","world"]');

  // Array with $ti set to something.
  // TODO(40175): Update this test if the access is changed.
  var a2 = eval(r'(function(){var x =["hi","bye"]; x.$ti=[666]; return x})()');

  var b1 = List.of(a1.cast<String>());
  Expect.listEquals(['hello', 'world'], a1);
  Expect.listEquals(['hello', 'world'], b1);

  var b2 = List.of(a2.cast<String>());
  Expect.listEquals(['hi', 'bye'], a2);
  Expect.listEquals(['hi', 'bye'], b2);
}
