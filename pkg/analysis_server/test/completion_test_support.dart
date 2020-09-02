// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';

import 'domain_completion_test.dart';

/// A base class for classes containing completion tests.
class CompletionTestCase extends CompletionDomainHandlerListTokenDetailsTest {
  static const String CURSOR_MARKER = '!';

  List get suggestedCompletions => suggestions
      .map((CompletionSuggestion suggestion) => suggestion.completion)
      .toList();

  void assertHasCompletion(String completion) {
    var expectedOffset = completion.indexOf(CURSOR_MARKER);
    if (expectedOffset >= 0) {
      if (completion.contains(CURSOR_MARKER, expectedOffset + 1)) {
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
          // It is OK to have a class and its default constructor suggestions.
          if (matchingSuggestion.element?.kind == ElementKind.CLASS &&
                  suggestion.element?.kind == ElementKind.CONSTRUCTOR ||
              matchingSuggestion.element?.kind == ElementKind.CONSTRUCTOR &&
                  suggestion.element?.kind == ElementKind.CLASS) {
            return;
          }
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

  /// Discard any results that do not start with the characters the user has
  /// "already typed".
  void filterResults(String content) {
    var charsAlreadyTyped =
        content.substring(replacementOffset, completionOffset).toLowerCase();
    suggestions = suggestions
        .where((CompletionSuggestion suggestion) =>
            suggestion.completion.toLowerCase().startsWith(charsAlreadyTyped))
        .toList();
  }

  Future runTest(LocationSpec spec, [Map<String, String> extraFiles]) {
    super.setUp();
    return Future(() {
      var content = spec.source;
      newFile(testFile, content: content);
      testCode = content;
      completionOffset = spec.testLocation;
      if (extraFiles != null) {
        extraFiles.forEach((String fileName, String content) {
          newFile(fileName, content: content);
        });
      }
    }).then((_) => getSuggestions()).then((_) {
      filterResults(spec.source);
      for (var result in spec.positiveResults) {
        assertHasCompletion(result);
      }
      for (var result in spec.negativeResults) {
        assertHasNoCompletion(result);
      }
    }).whenComplete(() {
      super.tearDown();
    });
  }
}

/// A specification of the completion results expected at a given location.
class LocationSpec {
  String id;
  int testLocation = -1;
  List<String> positiveResults = <String>[];
  List<String> negativeResults = <String>[];
  String source;

  LocationSpec(this.id);

  /// Parse a set of tests from the given `originalSource`. Return a list of the
  /// specifications that were parsed.
  ///
  /// The source string has test locations embedded in it, which are identified
  /// by '!X' where X is a single character. Each X is matched to positive or
  /// negative results in the array of [validationStrings]. Validation strings
  /// contain the name of a prediction with a two character prefix. The first
  /// character of the prefix corresponds to an X in the [originalSource]. The
  /// second character is either a '+' or a '-' indicating whether the string is
  /// a positive or negative result. If logical not is needed in the source it
  /// can be represented by '!!'.
  ///
  /// The [originalSource] is the source for a test that contains test
  /// locations. The [validationStrings] are the positive and negative
  /// predictions.
  static List<LocationSpec> from(
      String originalSource, List<String> validationStrings) {
    Map<String, LocationSpec> tests = HashMap<String, LocationSpec>();
    var modifiedSource = originalSource;
    var modifiedPosition = 0;
    while (true) {
      var index = modifiedSource.indexOf('!', modifiedPosition);
      if (index < 0) {
        break;
      }
      var n = 1; // only delete one char for double-bangs
      var id = modifiedSource.substring(index + 1, index + 2);
      if (id != '!') {
        n = 2;
        var test = LocationSpec(id);
        tests[id] = test;
        test.testLocation = index;
      } else {
        modifiedPosition = index + 1;
      }
      modifiedSource = modifiedSource.substring(0, index) +
          modifiedSource.substring(index + n);
    }
    if (modifiedSource == originalSource) {
      throw StateError('No tests in source: ' + originalSource);
    }
    for (var result in validationStrings) {
      if (result.length < 3) {
        throw StateError('Invalid location result: ' + result);
      }
      var id = result.substring(0, 1);
      var sign = result.substring(1, 2);
      var value = result.substring(2);
      var test = tests[id];
      if (test == null) {
        throw StateError('Invalid location result id: $id for: $result');
      }
      test.source = modifiedSource;
      if (sign == '+') {
        test.positiveResults.add(value);
      } else if (sign == '-') {
        test.negativeResults.add(value);
      } else {
        var err = 'Invalid location result sign: $sign for: $result';
        throw StateError(err);
      }
    }
    var badPoints = <String>[];
    var badResults = <String>[];
    for (var test in tests.values) {
      if (test.testLocation == -1) {
        badPoints.add(test.id);
      }
      if (test.positiveResults.isEmpty && test.negativeResults.isEmpty) {
        badResults.add(test.id);
      }
    }
    if (!(badPoints.isEmpty && badResults.isEmpty)) {
      var err = StringBuffer();
      if (badPoints.isNotEmpty) {
        err.write('No test location for tests:');
        for (var ch in badPoints) {
          err..write(' ')..write(ch);
        }
        err.write(' ');
      }
      if (badResults.isNotEmpty) {
        err.write('No results for tests:');
        for (var ch in badResults) {
          err..write(' ')..write(ch);
        }
      }
      throw StateError(err.toString());
    }
    return tests.values.toList();
  }
}
