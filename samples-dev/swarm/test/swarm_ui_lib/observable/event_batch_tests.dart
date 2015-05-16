// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable_tests;

testEventBatch() {
  test('EventBatch', () {
    // check that all events are fired at the end. Use all record methods
    // in abstract observable
    final target = new AbstractObservable();
    EventSummary res = null;
    target.addChangeListener((summary) {
      expect(res, isNull);
      res = summary;
      expect(res, isNotNull);
    });

    final f = EventBatch.wrap((e) {
      target.recordPropertyUpdate('pM', 10, 11);
      target.recordPropertyUpdate('pL', '11', '13');
      target.recordListUpdate(2, 'a', 'b');
      target.recordListInsert(5, 'a');
      target.recordListRemove(4, 'c');
      target.recordGlobalChange();
    });

    expect(res, isNull);
    f(null);
    expect(res, isNotNull);

    expect(res.events, hasLength(6));
    validateUpdate(res.events[0], target, 'pM', null, 10, 11);
    validateUpdate(res.events[1], target, 'pL', null, '11', '13');
    validateUpdate(res.events[2], target, null, 2, 'a', 'b');
    validateInsert(res.events[3], target, null, 5, 'a');
    validateRemove(res.events[4], target, null, 4, 'c');
    validateGlobal(res.events[5], target);
  });
}
