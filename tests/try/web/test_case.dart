// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.test_case;

import 'dart:html' show
    document;

import 'dart:async';

import 'package:async_helper/async_helper.dart';

typedef void VoidFunction();

class TestCase {
  final String description;
  final VoidFunction setup;
  final VoidFunction validate;

  TestCase(this.description, this.setup, this.validate);
}

/**
 * Executes [tests] each test in order using the following approach for each
 * test:
 *
 *   1. Run setup synchronously.
 *
 *   2. Schedule a new (async) Future which runs validate followed by the next
 *   test's setup.
 *
 *   3. Repeat step 2 until there are no more tests.
 *
 * The purpose of this test is to simulate edits (during setup), and then let
 * the the mutation observer to process the mutations followed by validation.
 */
void runTests(List<TestCase> tests) {
  Completer completer = new Completer();
  asyncTest(() => completer.future.then((_) {
    // Clear the DOM to work around a bug in test.dart.
    document.body.nodes.clear();
  }));

  void iterateTests(Iterator<TestCase> iterator) {
    if (iterator.moveNext()) {
      TestCase test = iterator.current;
      print('${test.description}\nSetup.');
      test.setup();
      new Future(() {
        test.validate();
        print('${test.description}\nDone.');
        iterateTests(iterator);
      });
    } else {
      completer.complete(null);
    }
  }

  iterateTests(tests.iterator);
}
