// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  // **NOTE**: This test is currently being skipped everywhere until deferred
  // imports have actual support.
  test('Polymer.import', () {
    return Polymer.import(['element_import/import_a.html']).then((_) {
      expect((querySelector('x-foo') as dynamic).isCustom, true);
      var dom = document.importNode(
          (querySelector('#myTemplate') as TemplateElement).content, true);
      return Polymer.importElements(dom).then((_) {
        expect((querySelector('x-bar') as dynamic).isCustom, true);
      });
    });
  });
});

