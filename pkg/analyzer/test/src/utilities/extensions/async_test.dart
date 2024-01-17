// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/utilities/extensions/async.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListOfCompleterExtensionTest);
  });
}

@reflectiveTest
class ListOfCompleterExtensionTest {
  test_completeAll_value() async {
    var completers = [Completer<int>(), Completer<int>()];
    completers.completeAll(42);
    for (var completer in completers) {
      expect(await completer.future, 42);
    }
  }

  test_completeAll_void() async {
    var completers = [Completer<void>(), Completer<void>()];
    completers.completeAll();
    for (var completer in completers) {
      await completer.future;
    }
  }

  test_completeErrorAll() async {
    var completers = [Completer<int>(), Completer<int>()];
    var error = Object();
    completers.completeErrorAll(error);
    for (var completer in completers) {
      expect(completer.future, throwsA(same(error)));
    }
  }
}
