// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable_tests;

testChangeEvent() {
  test('constructor', () {
    // create property, list, global and check the proper initialization.
    final target = new AbstractObservable();

    validateUpdate(new ChangeEvent.property(target, 'pK', 33, '12'), target,
        'pK', null, 33, '12');

    validateUpdate(
        new ChangeEvent.list(target, ChangeEvent.UPDATE, 3, 33, '12'),
        target,
        null,
        3,
        33,
        '12');

    validateInsert(
        new ChangeEvent.list(target, ChangeEvent.INSERT, 3, 33, null),
        target,
        null,
        3,
        33);

    validateRemove(
        new ChangeEvent.list(target, ChangeEvent.REMOVE, 3, null, '12'),
        target,
        null,
        3,
        '12');

    validateGlobal(
        new ChangeEvent.list(target, ChangeEvent.GLOBAL, null, null, null),
        target);
  });
}
