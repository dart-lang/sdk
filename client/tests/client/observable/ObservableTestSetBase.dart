// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines helper methods that the other TestSet classes in this library
 * share.
 */
class ObservableTestSetBase extends TestSet {
  // TODO(rnystrom): Remove this when default constructors are supported.
  ObservableTestSetBase() : super();

  void checkEvent(ChangeEvent e, target, pName, index, type, newVal, oldVal) {
    expect(e.target).equals(target);
    expect(e.propertyName).equals(pName);
    expect(e.index).equals(index);
    expect(e.type).equals(type);
    expect(e.newValue).equals(newVal);
    expect(e.oldValue).equals(oldVal);
  }
}
