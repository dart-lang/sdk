// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';

import '../../../../client/completion_driver_test.dart';

class CompletionRelevanceTest extends AbstractCompletionDriverTest {
  @override
  bool get supportsAvailableSuggestions => true;

  /// Assert that all of the given completions were produced and that the
  /// suggestions are ordered in decreasing order based on relevance scores.
  void assertOrder(List<CompletionSuggestion> suggestions) {
    var length = suggestions.length;
    expect(length, greaterThan(1),
        reason: 'Test must specify more than one suggestion');
    var previous = suggestions[0];
    for (var i = 1; i < length; i++) {
      var current = suggestions[i];
      if (current.relevance > previous.relevance) {
        suggestions.sort((first, second) => second.relevance - first.relevance);
        var buffer = StringBuffer();
        buffer.writeln('Actual sort order does not match expected order.');
        buffer.writeln('To accept the actual sort order, use:');
        buffer.writeln();
        buffer.writeln('    assertOrder([');
        for (var suggestion in suggestions) {
          var completion = suggestion.completion;
          buffer.writeln("      suggestionWith(completion: '$completion'),");
        }
        buffer.writeln('    ]);');
        fail(buffer.toString());
      }
      previous = current;
    }
  }
}
