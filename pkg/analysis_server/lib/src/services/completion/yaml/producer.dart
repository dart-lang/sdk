// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/file_system/file_system.dart';

/// An object that represents the location of a Boolean value.
class BooleanProducer extends Producer {
  /// Initialize a location whose valid values are Booleans.
  const BooleanProducer();

  @override
  Iterable<CompletionSuggestion> suggestions() sync* {
    yield identifier('true');
    yield identifier('false');
  }
}

/// An object that represents the location of an arbitrary value. They serve as
/// placeholders when there are no reasonable suggestions for a given location.
class EmptyProducer extends Producer {
  /// Initialize a location whose valid values are arbitrary.
  const EmptyProducer();

  @override
  Iterable<CompletionSuggestion> suggestions() sync* {
    // Returns nothing.
  }
}

/// An object that represents the location of a value from a finite set of
/// choices.
class EnumProducer extends Producer {
  /// The list of valid values at this location.
  final List<String> values;

  /// Initialize a location whose valid values are in the list of [values].
  const EnumProducer(this.values);

  @override
  Iterable<CompletionSuggestion> suggestions() sync* {
    for (var value in values) {
      yield identifier(value);
    }
  }
}

/// An object that represents the location of a possibly relative file path.
class FilePathProducer extends Producer {
  /// The resource provider used to access the content of the file in which
  /// completion was requested.
  final ResourceProvider provider;

  /// Initialize a location whose valid values are file paths.
  FilePathProducer(this.provider);

  @override
  Iterable<CompletionSuggestion> suggestions() sync* {
    // TODO(brianwilkerson) Implement this.
  }
}

/// An object that represents the location of an element in a list.
class ListProducer extends Producer {
  /// The producer used to produce suggestions for an element of the list.
  final Producer element;

  /// Initialize a location whose valid values are determined by the [element]
  /// producer.
  const ListProducer(this.element);

  @override
  Iterable<CompletionSuggestion> suggestions() sync* {
    for (var suggestion in element.suggestions()) {
      // TODO(brianwilkerson) Consider prepending the suggestion with a hyphen
      //  when the current node isn't already preceded by a hyphen. The
      //  cleanest way to do this is probably to access the [element] producer
      //  in the place where we're choosing a producer in that situation.
      // suggestion.completion = '- ${suggestion.completion}';
      yield suggestion;
    }
  }
}

/// An object that represents the location of the keys in a map.
class MapProducer extends Producer {
  /// A table from the value of a key to the producer used to make suggestions
  /// for the value following the key.
  final Map<String, Producer> children;

  /// Initialize a location whose valid values are the keys of a map as encoded
  /// by the map of [children].
  const MapProducer(this.children);

  @override
  Iterable<CompletionSuggestion> suggestions() sync* {
    for (var entry in children.entries) {
      if (entry.value is ListProducer) {
        yield identifier('${entry.key}:');
      } else {
        yield identifier('${entry.key}: ');
      }
    }
  }
}

/// An object that represents a specific location in the structure of the valid
/// YAML representation and can produce completion suggestions appropriate for
/// that location.
abstract class Producer {
  /// Initialize a newly created instance of this class.
  const Producer();

  /// A utility method used to create a suggestion for the [identifier].
  CompletionSuggestion identifier(String identifier) => CompletionSuggestion(
      CompletionSuggestionKind.IDENTIFIER,
      1000,
      identifier,
      identifier.length,
      0,
      false,
      false);

  /// Return the completion suggestions appropriate to this location.
  Iterable<CompletionSuggestion> suggestions();
}
