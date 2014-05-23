// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

/// This test runs the news example and checks the state of the initial page.
main() {
  initPolymer();
  useHtmlConfiguration();

  extractLinks(nodes) => nodes.where((n) => n is Element)
      .map((n) => n.query('a').href.split('/').last).toList();

  test('initial state', () {
    final listComp = querySelector('ul');
    final items = listComp.querySelectorAll('li');
    expect(items.length, 6);
    expect(extractLinks(items), ['1', '2', '3', '4', '4', '5']);
    expect(listComp is Polymer, true, reason: 'x-news should be created');

    final contents = listComp.shadowRoot.querySelectorAll('content');
    expect(contents.length, 2, reason: 'news has 2 content tags');
    expect(extractLinks(contents[0].getDistributedNodes()),
        ['3', '5'], reason: 'breaking stories first');
    expect(extractLinks(contents[1].getDistributedNodes()),
        ['1', '2', '4', '4'], reason: 'other stories after breaking stories');
  });
}
