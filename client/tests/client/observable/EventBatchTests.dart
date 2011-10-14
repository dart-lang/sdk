// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EventBatchTests extends ObservableTestSetBase {
  // TODO(rnystrom): Remove this when default constructors are supported.
  EventBatchTests() : super();

  setup() {
    addTest(testEventBatch);
  }

  void testEventBatch() {
    // check that all events are fired at the end. Use all record methods
    // in abstract observable
    final target = new AbstractObservable();
    EventSummary res = null;
    target.addChangeListener((summary) {
      expect(res).isNull();
      res = summary;
      expect(res).isNotNull();
    });

    final f = EventBatch.wrap((e) {
      target.recordPropertyUpdate('pM', 10, 11);
      target.recordPropertyUpdate('pL', '11', '13');
      target.recordListUpdate(2, 'a', 'b');
      target.recordListInsert(5, 'a');
      target.recordListRemove(4, 'c');
      target.recordGlobalChange();
    });

    expect(res).isNull();
    f(null);
    expect(res).isNotNull();

    expect(res.events.length).equals(6);
    checkEvent(res.events[0],
        target, 'pM', null, ChangeEvent.UPDATE, 10, 11);

    checkEvent(res.events[1],
        target, 'pL', null, ChangeEvent.UPDATE, '11', '13');

    checkEvent(res.events[2],
        target, null, 2, ChangeEvent.UPDATE, 'a', 'b');

    checkEvent(res.events[3],
        target, null, 5, ChangeEvent.INSERT, 'a', null);

    checkEvent(res.events[4],
        target, null, 4, ChangeEvent.REMOVE, null, 'c');

    checkEvent(res.events[5],
        target, null, null, ChangeEvent.GLOBAL, null, null);
  }
}
