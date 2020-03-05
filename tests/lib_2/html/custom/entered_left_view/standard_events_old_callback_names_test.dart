// Copyright (c) 2020 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library entered_left_view_test;

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;

import 'entered_left_view_util.dart';
import 'package:unittest/unittest.dart';

import '../utils.dart';

main() {
  setUp(setupFunc);
  // TODO(jmesserly): remove after deprecation period.
  group('standard_events_old_callback_names', () {
    var a;
    setUp(() {
      invocations = [];
    });

    test('Created', () {
      a = new Element.tag('x-a-old');
      expect(invocations, ['created']);
    });

    test('enteredView', () {
      document.body.append(a);
      customElementsTakeRecords();
      expect(invocations, ['enteredView']);
    });

    test('leftView', () {
      a.remove();
      customElementsTakeRecords();
      expect(invocations, ['leftView']);
    });

    var div = new DivElement();
    test('nesting does not trigger enteredView', () {
      div.append(a);
      customElementsTakeRecords();
      expect(invocations, []);
    });

    test('nested entering triggers enteredView', () {
      document.body.append(div);
      customElementsTakeRecords();
      expect(invocations, ['enteredView']);
    });

    test('nested leaving triggers leftView', () {
      div.remove();
      customElementsTakeRecords();
      expect(invocations, ['leftView']);
    });
  });
}
