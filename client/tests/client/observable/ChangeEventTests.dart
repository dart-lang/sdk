// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ChangeEventTests extends ObservableTestSetBase {
  // TODO(rnystrom): Remove this when default constructors are supported.
  ChangeEventTests() : super();

  setup() {
    addTest(testChangeEventConstructors);
  }

  void testChangeEventConstructors() {
    // create property, list, global and check the proper initialization.
    final target = new AbstractObservable();

    checkEvent(new ChangeEvent.property(target, "pK", 33, "12"),
        target, "pK", null, ChangeEvent.UPDATE, 33, "12");

    checkEvent(new ChangeEvent.list(target, ChangeEvent.UPDATE, 3, 33, "12"),
        target, null, 3, ChangeEvent.UPDATE, 33, "12");

    checkEvent(new ChangeEvent.list(target, ChangeEvent.INSERT, 3, 33, null),
        target, null, 3, ChangeEvent.INSERT, 33, null);

    checkEvent(new ChangeEvent.list(target, ChangeEvent.REMOVE, 3, null, "12"),
        target, null, 3, ChangeEvent.REMOVE, null, "12");

    checkEvent(new ChangeEvent.list(target, ChangeEvent.GLOBAL, 0, null, null),
        target, null, 0, ChangeEvent.GLOBAL, null, null);
  }
}
