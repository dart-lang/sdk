// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';

import 'domain_completion_test.dart';

/**
 * A base class for classes containing completion tests.
 */
class CompletionTestCase extends CompletionDomainHandlerTest {
  static const String CURSOR_MARKER = '!';

  List get suggestedCompletions => suggestions
      .map((CompletionSuggestion suggestion) => suggestion.completion)
      .toList();

  void assertHasCompletion(String completion) {
    int expectedOffset = completion.indexOf(CURSOR_MARKER);
    if (expectedOffset >= 0) {
      if (completion.indexOf(CURSOR_MARKER, expectedOffset + 1) >= 0) {
        fail(
            "Invalid completion, contains multiple cursor positions: '$completion'");
      }
      completion = completion.replaceFirst(CURSOR_MARKER, '');
    } else {
      expectedOffset = completion.length;
    }
    CompletionSuggestion matchingSuggestion;
    suggestions.forEach((CompletionSuggestion suggestion) {
      if (suggestion.completion == completion) {
        if (matchingSuggestion == null) {
          matchingSuggestion = suggestion;
        } else {
          fail(
              "Expected exactly one '$completion' but found multiple:\n  $suggestedCompletions");
        }
      }
    });
    if (matchingSuggestion == null) {
      fail("Expected '$completion' but found none:\n  $suggestedCompletions");
    }
    expect(matchingSuggestion.selectionOffset, equals(expectedOffset));
    expect(matchingSuggestion.selectionLength, equals(0));
  }

  void assertHasNoCompletion(String completion) {
    if (suggestions.any((CompletionSuggestion suggestion) =>
        suggestion.completion == completion)) {
      fail(
          "Did not expect completion '$completion' but found:\n  $suggestedCompletions");
    }
  }

  /**
   * Discard any results that do not start with the characters the user has
   * "already typed".
   */
  void filterResults(String content) {
    String charsAlreadyTyped =
        content.substring(replacementOffset, completionOffset).toLowerCase();
    suggestions = suggestions
        .where((CompletionSuggestion suggestion) =>
            suggestion.completion.toLowerCase().startsWith(charsAlreadyTyped))
        .toList();
  }

  runTest(LocationSpec spec, [Map<String, String> extraFiles]) {
    super.setUp();
    return new Future(() {
      String content = spec.source;
      addFile(testFile, content);
      this.testCode = content;
      completionOffset = spec.testLocation;
      if (extraFiles != null) {
        extraFiles.forEach((String fileName, String content) {
          addFile(fileName, content);
        });
      }
    }).then((_) => getSuggestions()).then((_) {
      filterResults(spec.source);
      for (String result in spec.positiveResults) {
        assertHasCompletion(result);
      }
      for (String result in spec.negativeResults) {
        assertHasNoCompletion(result);
      }
    }).whenComplete(() {
      super.tearDown();
    });
  }
}

/**
 * A specification of the completion results expected at a given location.
 */
class LocationSpec {
  String id;
  int testLocation = -1;
  List<String> positiveResults = <String>[];
  List<String> negativeResults = <String>[];
  String source;

  LocationSpec(this.id);

  /**
   * Parse a set of tests from the given `originalSource`. Return a list of the
   * specifications that were parsed.
   *
   * The source string has test locations embedded in it, which are identified
   * by '!X' where X is a single character. Each X is matched to positive or
   * negative results in the array of [validationStrings]. Validation strings
   * contain the name of a prediction with a two character prefix. The first
   * character of the prefix corresponds to an X in the [originalSource]. The
   * second character is either a '+' or a '-' indicating whether the string is
   * a positive or negative result. If logical not is needed in the source it
   * can be represented by '!!'.
   *
   * The [originalSource] is the source for a test that contains test locations.
   * The [validationStrings] are the positive and negative predictions.
   */
  static List<LocationSpec> from(
      String originalSource, List<String> validationStrings) {
    Map<String, LocationSpec> tests = new HashMap<String, LocationSpec>();
    String modifiedSource = originalSource;
    int modifiedPosition = 0;
    while (true) {
      int index = modifiedSource.indexOf('!', modifiedPosition);
      if (index < 0) {
        break;
      }
      int n = 1; // only delete one char for double-bangs
      String id = modifiedSource.substring(index + 1, index + 2);
      if (id != '!') {
        n = 2;
        LocationSpec test = new LocationSpec(id);
        tests[id] = test;
        test.testLocation = index;
      } else {
        modifiedPosition = index + 1;
      }
      modifiedSource = modifiedSource.substring(0, index) +
          modifiedSource.substring(index + n);
    }
    if (modifiedSource == originalSource) {
      throw new StateError("No tests in source: " + originalSource);
    }
    for (String result in validationStrings) {
      if (result.length < 3) {
        throw new StateError("Invalid location result: " + result);
      }
      String id = result.substring(0, 1);
      String sign = result.substring(1, 2);
      String value = result.substring(2);
      LocationSpec test = tests[id];
      if (test == null) {
        throw new StateError("Invalid location result id: $id for: $result");
      }
      test.source = modifiedSource;
      if (sign == '+') {
        test.positiveResults.add(value);
      } else if (sign == '-') {
        test.negativeResults.add(value);
      } else {
        String err = "Invalid location result sign: $sign for: $result";
        throw new StateError(err);
      }
    }
    List<String> badPoints = <String>[];
    List<String> badResults = <String>[];
    for (LocationSpec test in tests.values) {
      if (test.testLocation == -1) {
        badPoints.add(test.id);
      }
      if (test.positiveResults.isEmpty && test.negativeResults.isEmpty) {
        badResults.add(test.id);
      }
    }
    if (!(badPoints.isEmpty && badResults.isEmpty)) {
      StringBuffer err = new StringBuffer();
      if (!badPoints.isEmpty) {
        err.write("No test location for tests:");
        for (String ch in badPoints) {
          err..write(' ')..write(ch);
        }
        err.write(' ');
      }
      if (!badResults.isEmpty) {
        err.write("No results for tests:");
        for (String ch in badResults) {
          err..write(' ')..write(ch);
        }
      }
      throw new StateError(err.toString());
    }
    return tests.values.toList();
  }
}
