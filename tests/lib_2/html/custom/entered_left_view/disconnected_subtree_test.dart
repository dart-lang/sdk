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
  group('disconnected_subtree', () {
    var div = new DivElement();

    setUp() {
      invocations = [];
    }

    test('Enters a disconnected subtree of DOM', () {
      setUp();
      div.setInnerHtml('<x-a></x-a>', treeSanitizer: nullSanitizer);
      upgradeCustomElements(div);

      expect(invocations, ['created'],
          reason: 'the attached callback should not be invoked when inserted '
              'into a disconnected subtree');
    });

    test('Leaves a disconnected subtree of DOM', () {
      setUp();
      div.innerHtml = '';
      expect(invocations, [],
          reason:
              'the detached callback should not be invoked when removed from a '
              'disconnected subtree');
    });

    test('Enters a document with a view as a constituent of a subtree', () {
      setUp();
      div.setInnerHtml('<x-a></x-a>', treeSanitizer: nullSanitizer);
      upgradeCustomElements(div);
      invocations = [];
      document.body.append(div);
      customElementsTakeRecords();
      expect(invocations, ['attached'],
          reason:
              'the attached callback should be invoked when inserted into a '
              'document with a view as part of a subtree');
    });
  });
}
