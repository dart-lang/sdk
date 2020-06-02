// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

Element navBar(List<Element> content) {
  assert(content != null);
  return document.createElement('nav')
    ..classes = ['nav-bar']
    ..children = <Element>[
      new UListElement()..children = content,
    ];
}
