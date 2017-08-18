// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

navMenu(String label, {String link, Iterable<Element> content: const []}) {
  assert(label != null);
  assert(content != null);
  return new LIElement()
    ..classes = ['nav-menu']
    ..children = [
      new SpanElement()
        ..classes = ['nav-menu_label']
        ..children = [
          new AnchorElement(href: link)..text = label,
          new UListElement()..children = content
        ]
    ];
}
