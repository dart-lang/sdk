// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable_tests;

testObservableValue() {
  test('ObservableValue', () {
    final value = new ObservableValue<String>('initial');
    expect(value.value, equals('initial'));

    // Set value.
    value.value = 'new';
    expect(value.value, equals('new'));

    // Change event is sent when value is changed.
    EventSummary result = null;
    value.addChangeListener((summary) {
      expect(result, isNull);
      result = summary;
      expect(result, isNotNull);
    });

    value.value = 'newer';

    expect(result, isNotNull);
    expect(result.events.length, equals(1));
    validateUpdate(result.events[0], value, 'value', null, 'newer', 'new');
  });

  test('does not raise event if unchanged', () {
    final value = new ObservableValue<String>('foo');
    expect(value.value, equals('foo'));

    bool called = false;
    value.addChangeListener((summary) {
      called = true;
    });

    // Set it to the same value.
    value.value = 'foo';

    // Should not have gotten an event.
    expect(called, isFalse);
  });
}
