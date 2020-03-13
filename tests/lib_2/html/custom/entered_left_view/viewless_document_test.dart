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
  group('viewless_document', () {
    var a;
    setUp() {
      invocations = [];
    }

    test('Created, owned by a document without a view', () {
      setUp();
      a = docB.createElement('x-a');
      expect(a.ownerDocument, docB,
          reason: 'new instance should be owned by the document the definition '
              'was registered with');
      expect(invocations, ['created'],
          reason: 'calling the constructor should invoke the created callback');
    });

    test('Entered document without a view', () {
      setUp();
      docB.body.append(a);
      expect(invocations, [],
          reason: 'attached callback should not be invoked when entering a '
              'document without a view');
    });

    test('Attribute changed in document without a view', () {
      setUp();
      a.setAttribute('data-foo', 'bar');
      expect(invocations, ['attribute changed'],
          reason: 'changing an attribute should invoke the callback, even in a '
              'document without a view');
    });

    test('Entered document with a view', () {
      setUp();
      document.body.append(a);
      customElementsTakeRecords();
      expect(invocations, ['attached'],
          reason:
              'attached callback should be invoked when entering a document '
              'with a view');
    });

    test('Left document with a view', () {
      setUp();
      a.remove();
      customElementsTakeRecords();
      expect(invocations, ['detached'],
          reason: 'detached callback should be invoked when leaving a document '
              'with a view');
    });

    test('Created in a document without a view', () {
      setUp();
      docB.body.setInnerHtml('<x-a></x-a>', treeSanitizer: nullSanitizer);
      upgradeCustomElements(docB.body);

      expect(invocations, ['created'],
          reason: 'only created callback should be invoked when parsing a '
              'custom element in a document without a view');
    });
  });
}
