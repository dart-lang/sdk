// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

class Element {}

class InheritedElement extends Element {
  final Map<Element, Object> _dependents = <Element, Object>{};

  void setDependencies(Element dependent, Object value) {
    _dependents[dependent] = value;
  }
}

main() {
  var ie = InheritedElement();
  ie.setDependencies(ie, 0);
  ie.setDependencies(Element(), null);
}
