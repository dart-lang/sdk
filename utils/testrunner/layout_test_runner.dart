// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The filters must be set by the caller that #sources this file.
List includeFilters;
List excludeFilters;

class LayoutTestConfiguration extends unittest.Configuration {
  get autoStart => false;
  void onTestResult(unittest.TestCase testCase) {
    window.postMessage('done', '*'); // Unblock DRT
  }
}

filterTest(t) {
  var name = t.description.replaceAll("###", " ");
  if (includeFilters.length > 0) {
    for (var f in includeFilters) {
      if (name.indexOf(f) >= 0) return true;
    }
    return false;
  } else if (excludeFilters.length > 0) {
    for (var f in excludeFilters) {
      if (name.indexOf(f) >= 0) return false;
    }
    return true;
  } else {
    return true;
  }
}

runTests(testMain) {
  unittest.groupSep = '###';
  unittest.configure(new LayoutTestConfiguration());

  // Create the set of test cases.
  unittest.group('', testMain);

  // Do any user-specified test filtering.
  unittest.filterTests(filterTest);

  // Filter to the test number in the search query.
  var testNum = int.parse(window.location.search.substring(6));
  if (testNum < 0 || testNum >= unittest.testCases.length) {
    print('#TEST NONEXISTENT');
    window.postMessage('done', '*'); // Unblock DRT
  } else {
    var name = unittest.testCases[testNum].description;
    print('#TEST $name');
    unittest.filterTests(name);
    // Run the test.
    print('Tests - ${unittest.testCases.length}');
    unittest.runTests();
  }
}
