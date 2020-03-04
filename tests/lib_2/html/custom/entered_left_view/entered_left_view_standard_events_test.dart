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
  group('standard_events', () {
    var a;
    setUp(() {
      invocations = [];
    });

    test('Created', () {
      a = new Element.tag('x-a');
      expect(invocations, ['created']);
    });

    test('attached', () {
      document.body.append(a);
      customElementsTakeRecords();
      expect(invocations, ['attached']);
    });

    test('detached', () {
      a.remove();
      customElementsTakeRecords();
      expect(invocations, ['detached']);
    });

    var div = new DivElement();
    test('nesting does not trigger attached', () {
      div.append(a);
      customElementsTakeRecords();
      expect(invocations, []);
    });

    test('nested entering triggers attached', () {
      document.body.append(div);
      customElementsTakeRecords();
      expect(invocations, ['attached']);
    });

    test('nested leaving triggers detached', () {
      div.remove();
      customElementsTakeRecords();
      expect(invocations, ['detached']);
    });
  });
}
