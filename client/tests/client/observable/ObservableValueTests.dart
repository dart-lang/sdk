// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ObservableValueTests extends ObservableTestSetBase {
  // TODO(rnystrom): Remove this when default constructors are supported.
  ObservableValueTests() : super();

  setup() {
    addTest(testObservableValue);
    addTest(testObservableValueDoesNotRaiseEventIfUnchanged);
  }

  void testObservableValue() {
    final value = new ObservableValue<String>("initial");
    expect(value.value) == "initial";

    // Set value.
    value.value = "new";
    expect(value.value) == "new";

    // Change event is sent when value is changed.
    EventSummary result = null;
    value.addChangeListener((summary) {
      expect(result) == null;
      result = summary;
      expect(result).isNotNull();
    });

    value.value = "newer";

    expect(result).isNotNull();
    expect(result.events.length) == 1;
    checkEvent(result.events[0],
        value, "value", null, ChangeEvent.UPDATE, "newer", "new");
  }

  void testObservableValueDoesNotRaiseEventIfUnchanged() {
    final value = new ObservableValue<String>("foo");
    expect(value.value) == "foo";

    bool called = false;
    value.addChangeListener((summary) { called = true; });

    // Set it to the same value.
    value.value = "foo";

    // Should not have gotten an event.
    expect(called) == false;
  }
}
