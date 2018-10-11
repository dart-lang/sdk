// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test checks that TFA works as expected on an example imitating the
// InheritedElement.setDependencies hotspot in Flutter. The example is modified
// to use a custom class 'MockHashMap' rather than the regular 'HashMap' since
// we want to print out the inferred type of the '_dependents' field, which
// would be a 'SetType' under the regular 'HashMap' (and set types aren't
// translated into 'InferredType'). Also, []= is the target of a truly-dynamic
// call, and we want to make sure there is only one call-site in this example
// (call-site level info is not available yet).

import 'dart:collection';

class Element {}

abstract class MockHashMap<K, V> {
  factory MockHashMap() {
    return _NotRealHashMap<K, V>();
  }

  void setEntry(K key, V value);
}

class _NotRealHashMap<K, V> implements MockHashMap<K, V> {
  void setEntry(K key, V value) {}
}

class InheritedElement extends Element {
  // The inferred type for '_dependents' needs to be concrete and have exact
  // type arguments.
  final MockHashMap<Element, Object> _dependents =
      MockHashMap<Element, Object>();

  void setDependencies(Element dependent, Object value) {
    _dependents.setEntry(dependent, value);
  }
}

main() {
  var ie = InheritedElement();
  ie.setDependencies(ie, 0);
  ie.setDependencies(Element(), null);
}
