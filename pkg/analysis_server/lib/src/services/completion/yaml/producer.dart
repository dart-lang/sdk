// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// An object that represents the location of a Boolean value.
class BooleanProducer extends Producer {
  /// Initialize a location whose valid values are Booleans.
  const BooleanProducer();

  @override
  Iterable<CompletionSuggestion> suggestions(
      YamlCompletionRequest request) sync* {
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
  Iterable<CompletionSuggestion> suggestions(
      YamlCompletionRequest request) sync* {
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
  Iterable<CompletionSuggestion> suggestions(
      YamlCompletionRequest request) sync* {
    for (var value in values) {
      yield identifier(value);
    }
  }
}

/// An object that represents the location of a possibly relative file path.
class FilePathProducer extends Producer {
  /// Initialize a producer whose valid values are file paths.
  const FilePathProducer();

  @override
  Iterable<CompletionSuggestion> suggestions(
      YamlCompletionRequest request) sync* {
    //
    // This currently assumes that all of the paths in the assets section will
    // be posix paths.
    //
    var context = path.posix;
    var separator = context.separator;
    var precedingText = request.precedingText;

    String parentDirectory;
    if (precedingText.isEmpty || precedingText.endsWith(separator)) {
      parentDirectory = precedingText;
    } else {
      parentDirectory = context.dirname(precedingText);
    }
    if (parentDirectory == '.') {
      parentDirectory = '';
    } else if (parentDirectory.endsWith(separator)) {
      parentDirectory = parentDirectory.substring(
          0, parentDirectory.length - separator.length);
    }
    //
    // Convert from posix to the platform context.
    //
    var provider = request.resourceProvider;
    context = provider.pathContext;
    parentDirectory = context.joinAll(path.posix.split(parentDirectory));
    //
    // Resolve the relative path and access the disk to see what child entities
    // exist within the [parentDirectory] that can be suggested.
    //
    if (context.isRelative(parentDirectory)) {
      parentDirectory =
          context.join(context.dirname(request.filePath), parentDirectory);
    }
    parentDirectory = context.normalize(parentDirectory);
    var dir = provider.getResource(parentDirectory);
    if (dir is Folder) {
      try {
        for (var child in dir.getChildren()) {
          var name = child.shortName;
          var relevance = name.startsWith('.') ? 500 : 1000;
          yield identifier(name, relevance: relevance);
        }
      } on FileSystemException {
        // Guard against I/O exceptions.
      }
    }
  }
}

/// An object that represents the location of the keys/values in a map.
abstract class KeyValueProducer extends Producer {
  /// Initialize a producer representing a key/value pair in a map.
  const KeyValueProducer();

  /// Returns a producer for values of the given [key].
  Producer producerForKey(String key);
}

/// An object that represents the location of an element in a list.
class ListProducer extends Producer {
  /// The producer used to produce suggestions for an element of the list.
  final Producer element;

  /// Initialize a location whose valid values are determined by the [element]
  /// producer.
  const ListProducer(this.element);

  @override
  Iterable<CompletionSuggestion> suggestions(
      YamlCompletionRequest request) sync* {
    for (var suggestion in element.suggestions(request)) {
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
class MapProducer extends KeyValueProducer {
  /// A table from the value of a key to the producer used to make suggestions
  /// for the value following the key.
  final Map<String, Producer> _children;

  /// Initialize a location whose valid values are the keys of a map as encoded
  /// by the map of [children].
  const MapProducer(this._children);

  @override
  Producer producerForKey(String key) => _children[key];

  @override
  Iterable<CompletionSuggestion> suggestions(
      YamlCompletionRequest request) sync* {
    for (var entry in _children.entries) {
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
  CompletionSuggestion identifier(String identifier, {int relevance = 1000}) =>
      CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER, relevance,
          identifier, identifier.length, 0, false, false);

  /// Return the completion suggestions appropriate to this location.
  Iterable<CompletionSuggestion> suggestions(YamlCompletionRequest request);
}

/// The information provided to a [Producer] when requesting completions.
class YamlCompletionRequest {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The absolute path of the file in which completions are being requested.
  final String filePath;

  /// The text to the left of the cursor.
  final String precedingText;

  /// Initialize a newly created completion request.
  YamlCompletionRequest(
      {@required this.filePath,
      @required this.precedingText,
      @required this.resourceProvider});
}
