// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/pub/pub_package_service.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' as path;

/// An object that represents the location of a Boolean value.
class BooleanProducer extends Producer {
  /// Initialize a location whose valid values are Booleans.
  const new();

  @override
  List<CompletionSuggestion> suggestions(YamlCompletionRequest request) {
    return [identifier('true'), identifier('false')];
  }
}

/// An object that represents the location of an arbitrary value. They serve as
/// placeholders when there are no reasonable suggestions for a given location.
class EmptyProducer extends Producer {
  /// Initialize a location whose valid values are arbitrary.
  const new();

  @override
  List<CompletionSuggestion> suggestions(YamlCompletionRequest request) {
    // Returns nothing.
    // See https://github.com/dart-lang/sdk/issues/51806#issuecomment-4736379661
    // for why this is faster than `Iterable`.
    return const [];
  }
}

/// An object that represents the location of a value from a finite set of
/// choices.
class EnumProducer extends Producer {
  /// The list of valid values at this location.
  final List<String> values;

  /// Initialize a location whose valid values are in the list of [values].
  const new(this.values);

  @override
  List<CompletionSuggestion> suggestions(YamlCompletionRequest request) {
    return [for (var value in values) identifier(value)];
  }
}

/// An object that represents the location of a possibly relative file path.
class FilePathProducer extends Producer {
  /// Initialize a producer whose valid values are file paths.
  const new();

  @override
  List<CompletionSuggestion> suggestions(YamlCompletionRequest request) {
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
        0,
        parentDirectory.length - separator.length,
      );
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
      parentDirectory = context.join(
        context.dirname(request.filePath),
        parentDirectory,
      );
    }
    parentDirectory = context.normalize(parentDirectory);
    var dir = provider.getResource(parentDirectory);
    if (dir is Folder) {
      try {
        var list = <CompletionSuggestion>[];
        for (var child in dir.getChildren()) {
          var name = child.shortName;
          var relevance = name.startsWith('.') ? 500 : 1000;
          list.add(identifier(name, relevance: relevance));
        }
        return list;
      } on FileSystemException {
        // Guard against I/O exceptions.
      }
    }
    return const [];
  }
}

/// An object that represents the location of the keys/values in a map.
abstract class KeyValueProducer extends Producer {
  /// Initialize a producer representing a key/value pair in a map.
  const new();

  /// Returns a producer for values of the given [key], or `null` if there is
  /// no registered producer for the [key].
  Producer? producerForKey(String key);
}

/// An object that represents the location of a value that can be expressed
/// either as an element of a list or as a key in a map.
///
/// For example, the lint rules in an analysis options file can be written
/// either as a list of rule names or as a map from rule names to Booleans.
class ListOrMapProducer extends ListProducer implements KeyValueProducer {
  /// The producer used to produce suggestions for the value of a key when the
  /// map form is used.
  final Producer mapValue;

  /// Initialize a location whose valid values are either the elements of a
  /// list, as determined by the [element] producer, or the keys of a map whose
  /// values are determined by the [mapValue] producer.
  const new(super.element, {required this.mapValue});

  /// A producer that suggests the suggestions of [element] as map keys.
  Producer get keyProducer => _MapKeyProducer(element);

  @override
  Producer? producerForKey(String key) => mapValue;

  @override
  List<CompletionSuggestion> suggestions(YamlCompletionRequest request) {
    // Neither form has been started yet — suggest both list (`- rule`) and
    // map (`rule: `) forms so the user can choose which style to begin with.
    return [...super.suggestions(request), ...keyProducer.suggestions(request)];
  }
}

/// An object that represents the location of an element in a list.
class ListProducer extends Producer {
  /// The producer used to produce suggestions for an element of the list.
  final Producer element;

  /// Initialize a location whose valid values are determined by the [element]
  /// producer.
  const new(this.element);

  @override
  List<CompletionSuggestion> suggestions(YamlCompletionRequest request) {
    // This method is only called when the cursor is NOT already inside a list
    // item (the path didn't traverse a YamlList). When the cursor IS inside
    // an item (after `- `), `element.suggestions()` is called directly by
    // `_producerForPath`. Therefore we always need the `- ` prefix here.
    return [
      for (var suggestion in element.suggestions(request))
        identifier(
          '- ${suggestion.completion}',
          relevance: suggestion.relevance,
          docComplete: suggestion.docComplete,
        ),
    ];
  }
}

/// An object that represents the location of the keys in a map.
class MapProducer extends KeyValueProducer {
  /// A table from the value of a key to the producer used to make suggestions
  /// for the value following the key.
  final Map<String, Producer> _children;

  /// Initialize a location whose valid values are the keys of a map as encoded
  /// by the map of [_children].
  const new(this._children);

  @override
  Producer? producerForKey(String key) => _children[key];

  @override
  List<CompletionSuggestion> suggestions(YamlCompletionRequest request) {
    return [
      for (var entry in _children.entries)
        if (entry.value is ListProducer)
          identifier('${entry.key}:')
        else
          identifier('${entry.key}: '),
    ];
  }
}

/// An object that represents a specific location in the structure of the valid
/// YAML representation and can produce completion suggestions appropriate for
/// that location.
abstract class Producer {
  /// Initialize a newly created instance of this class.
  const new();

  /// A utility method used to create a suggestion for the [identifier].
  CompletionSuggestion identifier(
    String identifier, {
    int relevance = 1000,
    String? docComplete,
  }) => CompletionSuggestion(
    CompletionSuggestionKind.IDENTIFIER,
    relevance,
    identifier,
    identifier.length,
    0,
    false,
    false,
    docComplete: docComplete,
  );

  /// A utility method used to create a suggestion for the package [packageName].
  CompletionSuggestion packageName(
    String packageName, {
    int relevance = 1000,
  }) => CompletionSuggestion(
    CompletionSuggestionKind.PACKAGE_NAME,
    relevance,
    packageName,
    packageName.length,
    0,
    false,
    false,
  );

  /// Return the completion suggestions appropriate to this location.
  Iterable<CompletionSuggestion> suggestions(YamlCompletionRequest request);
}

/// The information provided to a [Producer] when requesting completions.
class YamlCompletionRequest {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The Pub package service used for looking up package names/versions.
  final PubPackageService? pubPackageService;

  /// The absolute path of the file in which completions are being requested.
  final String filePath;

  /// The text to the left of the cursor.
  final String precedingText;

  /// Initialize a newly created completion request.
  new({
    required this.filePath,
    required this.precedingText,
    required this.resourceProvider,
    required this.pubPackageService,
  });
}

/// An object that suggests the suggestions of another producer as map keys.
class _MapKeyProducer extends Producer {
  /// The producer whose suggestions are to be suggested as map keys.
  final Producer element;

  /// Initialize a location whose valid values are the suggestions of the
  /// [element] producer, written as map keys.
  const new(this.element);

  @override
  List<CompletionSuggestion> suggestions(YamlCompletionRequest request) {
    return [
      for (var suggestion in element.suggestions(request))
        identifier(
          '${suggestion.completion}: ',
          relevance: suggestion.relevance,
          docComplete: suggestion.docComplete,
        ),
    ];
  }
}
