// Copyright (c) 2020 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library entered_left_view_test;

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;

import 'entered_left_view_util.dart';
import 'package:async_helper/async_minitest.dart';

import '../utils.dart';

main() async {
  await setupFunc();
  group('standard_events', () {
    var a;
    setUp() {
      invocations = [];
    }

    test('Created', () {
      setUp();
      a = new Element.tag('x-a');
      expect(invocations, ['created']);
    });

    test('attached', () {
      setUp();
      document.body.append(a);
      customElementsTakeRecords();
      expect(invocations, ['attached']);
    });

    test('detached', () {
      setUp();
      a.remove();
      customElementsTakeRecords();
      expect(invocations, ['detached']);
    });

    var div = new DivElement();
    test('nesting does not trigger attached', () {
      setUp();
      div.append(a);
      customElementsTakeRecords();
      expect(invocations, []);
    });

    test('nested entering triggers attached', () {
      setUp();
      document.body.append(div);
      customElementsTakeRecords();
      expect(invocations, ['attached']);
    });

    test('nested leaving triggers detached', () {
      setUp();
      div.remove();
      customElementsTakeRecords();
      expect(invocations, ['detached']);
    });
  });
}
