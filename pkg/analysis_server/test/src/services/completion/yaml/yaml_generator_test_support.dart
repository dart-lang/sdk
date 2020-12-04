// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/yaml/yaml_completion_generator.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';

abstract class YamlGeneratorTest with ResourceProviderMixin {
  /// The completion results produced by [getCompletions].
  /* late */ List<CompletionSuggestion> results;

  /// Return the name of the file being tested.
  String get fileName;

  /// Return the generator to be used for this test.
  YamlCompletionGenerator get generator;

  /// Assert that there is no suggestion with the given [completion].
  void assertNoSuggestion(String completion) {
    for (var suggestion in results) {
      if (suggestion.completion == completion) {
        var buffer = StringBuffer();
        buffer.writeln("Unexpected suggestion of '$completion' in:");
        for (var suggestion in results) {
          buffer.writeln("  '${suggestion.completion}'");
        }
        fail(buffer.toString());
      }
    }
  }

  /// Assert that there is a suggestion with the given [completion].
  void assertSuggestion(String completion) {
    for (var suggestion in results) {
      if (suggestion.completion == completion) {
        return;
      }
    }
    var buffer = StringBuffer();
    buffer.writeln("Missing suggestion of '$completion', found:");
    for (var suggestion in results) {
      buffer.writeln("  '${suggestion.completion}'");
    }
    fail(buffer.toString());
  }

  /// Compute the completions in the given [content]. The location of the
  /// completion request is encoded in the content as a caret (`^`).
  void getCompletions(String content) {
    // Extract the completion location from the [content].
    var completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    var nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    content = content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
    // Add the file to the file system.
    var file = newFile('/home/test/$fileName', content: content);
    // Generate completions.
    results = generator.getSuggestions(file.path, completionOffset).suggestions;
  }
}
