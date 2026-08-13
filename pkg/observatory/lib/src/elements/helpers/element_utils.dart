// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:web/web.dart';

extension ElementAppendChildren on Element {
  Element appendChildren(Iterable<Node> nodes) {
    for (final node in nodes) {
      this.appendChild(node);
    }
    return this;
  }

  removeChildren() {
    while (true) {
      var child = childNodes.item(0);
      if (child == null) {
        break;
      }
      removeChild(child);
    }
    return this;
  }

  Element setChildren(Iterable<Node> nodes) {
    removeChildren();
    appendChildren(nodes);
    return this;
  }
}

HTMLElement toggleClass(HTMLElement element, String classMember) {
  if (element.className.contains(classMember)) {
    element.className = element.className.replaceAll(classMember, '');
  } else {
    element.className += classMember;
  }
  return element;
}
