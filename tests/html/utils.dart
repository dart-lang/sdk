#library('TestUtils');

/**
 * Verifies that [actual] has the same graph structure as [expected].
 * Detects cycles and DAG structure in Maps and Lists.
 */
verifyGraph(expected, actual) {
  var eItems = [];
  var aItems = [];

  message(path, reason) => path == ''
      ? reason
      : reason == null ? "path: $path" : "path: $path, $reason";

  walk(path, expected, actual) {
    if (expected is String || expected is num || expected == null) {
      Expect.equals(expected, actual, message(path, 'not equal'));
      return;
    }

    // Cycle or DAG?
    for (int i = 0; i < eItems.length; i++) {
      if (expected === eItems[i]) {
        Expect.identical(aItems[i], actual,
                         message(path, 'missing back or side edge'));
        return;
      }
    }
    for (int i = 0; i < aItems.length; i++) {
      if (actual === aItems[i]) {
        Expect.identical(eItems[i], expected,
                         message(path, 'extra back or side edge'));
        return;
      }
    }
    eItems.add(expected);
    aItems.add(actual);

    if (expected is List) {
      Expect.isTrue(actual is List, message(path, '$actual is List'));
      Expect.equals(expected.length, actual.length,
                    message(path, 'different list lengths'));
      for (var i = 0; i < expected.length; i++) {
        walk('$path[$i]', expected[i], actual[i]);
      }
      return;
    }

    if (expected is Map) {
      Expect.isTrue(actual is Map, message(path, '$actual is Map'));
      for (var key in expected.keys) {
        if (!actual.containsKey(key)) {
          Expect.fail(message(path, 'missing key "$key"'));
        }
        walk('$path["$key"]',  expected[key], actual[key]);
      }
      for (var key in actual.keys) {
        if (!expected.containsKey(key)) {
          Expect.fail(message(path, 'extra key "$key"'));
        }
      }
      return;
    }

    Expect.fail('Unhandled type: $expected');
  }

  walk('', expected, actual);
}
