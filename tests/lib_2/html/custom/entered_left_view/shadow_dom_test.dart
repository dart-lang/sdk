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
  group('shadow_dom', () {
    var div;
    var s;
    setUp() {
      invocations = [];
      div = new DivElement();
      s = div.createShadowRoot();
    }

    tearDown() {
      customElementsTakeRecords();
    }

    test('Created in Shadow DOM that is not in a document', () {
      setUp();
      s.setInnerHtml('<x-a></x-a>', treeSanitizer: nullSanitizer);
      upgradeCustomElements(s);

      expect(invocations, ['created'],
          reason: 'the attached callback should not be invoked when entering a '
              'Shadow DOM subtree not in the document');
      tearDown();
    });

    test('Leaves Shadow DOM that is not in a document', () {
      setUp();
      s.innerHtml = '';
      expect(invocations, [],
          reason: 'the detached callback should not be invoked when leaving a '
              'Shadow DOM subtree not in the document');
      tearDown();
    });

    test('Enters a document with a view as a constituent of Shadow DOM', () {
      setUp();
      s.setInnerHtml('<x-a></x-a>', treeSanitizer: nullSanitizer);
      upgradeCustomElements(s);

      document.body.append(div);
      customElementsTakeRecords();
      expect(invocations, ['created', 'attached'],
          reason: 'the attached callback should be invoked when inserted into '
              'a document with a view as part of Shadow DOM');

      div.remove();
      customElementsTakeRecords();

      expect(invocations, ['created', 'attached', 'detached'],
          reason: 'the detached callback should be invoked when removed from a '
              'document with a view as part of Shadow DOM');
      tearDown();
    });
  });
}
