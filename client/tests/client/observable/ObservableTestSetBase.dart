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
    expect(e.target) == target;
    expect(e.propertyName) == pName;
    expect(e.index) == index;
    expect(e.type) == type;
    expect(e.newValue) == newVal;
    expect(e.oldValue) == oldVal;
  }
}
