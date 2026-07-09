// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/yaml/producer.dart';
import 'package:analysis_server/src/services/pub/pub_package_service.dart';
import 'package:analysis_server/src/utilities/extensions/yaml.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:yaml/yaml.dart';

/// A completion generator that can produce completion suggestions for files
/// containing a YAML structure.
abstract class YamlCompletionGenerator {
  /// The resource provider used to access the content of the file in which
  /// completion was requested.
  final ResourceProvider resourceProvider;

  /// A service used for collecting Pub package information. May be `null` for
  /// generators that do not use Pub packages.
  final PubPackageService? pubPackageService;

  /// Initialize a newly created generator to use the [resourceProvider] to
  /// access the content of the file in which completion was requested.
  new(this.resourceProvider, this.pubPackageService);

  /// Return the producer used to produce suggestions at the top-level of the
  /// file.
  Producer get topLevelProducer;

  /// Return the completion suggestions appropriate for the given [offset] in
  /// the file at the given [filePath].
  YamlCompletionResults getSuggestions(String filePath, int offset) {
    var file = resourceProvider.getFile(filePath);
    String content;
    try {
      content = file.readAsStringSync();
    } on FileSystemException {
      // If the file doesn't exist or can't be read, then there are no
      // suggestions.
      return const YamlCompletionResults.empty();
    }
    var root = _parseYaml(content);
    if (root == null) {
      // If the contents can't be parsed, then there are no suggestions.
      return const YamlCompletionResults.empty();
    }
    var cursorColumn = _columnAt(content, offset);
    var nodePath = _pathToOffset(root, offset, cursorColumn: cursorColumn);
    var completionNode = nodePath.last;
    var precedingText = '';
    if (completionNode is YamlScalar) {
      var value = completionNode.value;
      if (value is String &&
          completionNode.style == ScalarStyle.PLAIN &&
          // It's possible that `offset` is after the end of `value` because we
          // could be in whitespace after the value.
          offset - completionNode.span.start.offset <= value.length) {
        precedingText = value.substring(
          0,
          offset - completionNode.span.start.offset,
        );
      } else if (value != null) {
        // There are no completions at the given location.
        return const YamlCompletionResults.empty();
      }
    }
    var request = YamlCompletionRequest(
      filePath: filePath,
      precedingText: precedingText,
      resourceProvider: resourceProvider,
      pubPackageService: pubPackageService,
    );
    return getSuggestionsForPath(request, nodePath, offset);
  }

  /// Given the [request] to pass to producers, a [nodePath] to the node in
  /// which completions are being requested and the offset of the cursor, return
  /// the completions appropriate at that location.
  YamlCompletionResults getSuggestionsForPath(
    YamlCompletionRequest request,
    List<YamlNode> nodePath,
    int offset,
  ) {
    var producer = _producerForPath(nodePath);
    if (producer == null) {
      return const YamlCompletionResults.empty();
    }
    if (producer is ListOrMapProducer) {
      producer = _resolveListOrMapProducer(producer, nodePath);
    }
    var invalidSuggestions = _siblingsOnPath(nodePath);
    var suggestions = <CompletionSuggestion>[];
    for (var suggestion in producer.suggestions(request)) {
      if (!invalidSuggestions.contains(suggestion.completion)) {
        suggestions.add(suggestion);
      }
    }
    var node = nodePath.isNotEmpty ? nodePath.last : null;
    String targetPrefix;
    int replacementOffset;
    int replacementLength;
    if (node is YamlScalar && node.containsOffset(offset)) {
      targetPrefix = node.span.text.substring(
        0,
        offset - node.span.start.offset,
      );
      replacementOffset = node.span.start.offset;
      replacementLength = node.span.length;
    } else {
      targetPrefix = '';
      replacementOffset = offset;
      replacementLength = 0;
    }
    return YamlCompletionResults(
      suggestions,
      targetPrefix,
      replacementOffset,
      replacementLength,
    );
  }

  /// Return the result of parsing the file [content] into a YAML node.
  YamlNode? _parseYaml(String content) {
    try {
      return loadYamlNode(content, recover: true);
    } on YamlException {
      // If the file can't be parsed, then fall through to return `null`.
    }
    return null;
  }

  /// Return a list containing the node containing the [offset] and all of the
  /// nodes between that and the [root] node. The root node is first in the list
  /// and the node containing the offset is the last element in the list.
  List<YamlNode> _pathToOffset(
    YamlNode root,
    int offset, {
    required int cursorColumn,
  }) {
    var path = <YamlNode>[];
    YamlNode? node = root;
    while (node != null) {
      path.add(node);
      node = node.childContainingOffset(offset, cursorColumn: cursorColumn);
    }
    return path;
  }

  /// Return the producer that should be used to produce completion suggestions
  /// for the last node in the node [path].
  Producer? _producerForPath(List<YamlNode> path) {
    Producer? producer = topLevelProducer;
    for (var i = 0; i < path.length - 1; i++) {
      var node = path[i];
      if (node is YamlMap && producer is KeyValueProducer) {
        // Value producers are based on keys, so try to locate the key for the
        // value that was next in the path.
        var key = node.keyAtValue(path[i + 1]);
        if (key is YamlScalar) {
          producer = producer.producerForKey(key.value as String);
          // Otherwise, if the item next in the path was a key itself, use the
          // current producer to provide completion for the key.
        } else if (node.nodes.containsKey(path[i + 1])) {
          return producer;
        } else {
          return null;
        }
      } else if (node is YamlList && producer is ListProducer) {
        producer = producer.element;
      } else {
        return producer;
      }
    }
    return producer;
  }

  /// Return the producer to use in place of the [producer], for a location
  /// where either a list or a map is valid, based on the form already being
  /// used at the location of the last node in the node [path].
  Producer _resolveListOrMapProducer(
    ListOrMapProducer producer,
    List<YamlNode> path,
  ) {
    var node = path.last;
    if (node is YamlMap) {
      // The cursor is inside an already started map.
      return producer.keyProducer;
    }
    if (node is YamlList) {
      // The cursor is inside an already started list.
      return ListProducer(producer.element);
    }
    if (path.length >= 2) {
      var parent = path[path.length - 2];
      if (parent is YamlMap && parent.nodes.containsKey(node)) {
        // The cursor is inside a key of an already started map.
        return producer.keyProducer;
      }
    }
    // Default to the list form, both when the list form is already being used
    // and when neither form has been started.
    return producer;
  }

  /// Return a list of the suggestions that should not be suggested because they
  /// are already in the structure.
  List<String> _siblingsOnPath(List<YamlNode> path) {
    List<String> siblingsInList(YamlList list, YamlNode? currentElement) {
      var siblings = <String>[];
      for (var element in list.nodes) {
        if (element != currentElement && element is YamlScalar) {
          var value = element.value;
          if (value is String) {
            siblings.add(value);
            siblings.add('- $value');
          }
        }
      }
      return siblings;
    }

    List<String> siblingsInMap(YamlMap map, YamlNode? currentKey) {
      var siblings = <String>[];
      for (var entry in map.nodes.entries) {
        var key = entry.key;
        if (key != currentKey && key is YamlScalar && key.value is String) {
          // Match the format used by MapProducer.suggestions(): no trailing
          // space for list values (value goes on the next line after the colon).
          var suffix = entry.value is YamlList ? ':' : ': ';
          siblings.add('${key.value}$suffix');
        }
      }
      return siblings;
    }

    var length = path.length;
    if (length < 2) {
      // Path is just the root node. If it's a map, its own keys are the
      // siblings that should be excluded from top-level key suggestions.
      if (length == 1 && path[0] is YamlMap) {
        return siblingsInMap(path[0] as YamlMap, null);
      }
      return const <String>[];
    }
    var node = path[length - 1];
    if (node is YamlList) {
      return siblingsInList(node, null);
    } else if (node is YamlMap) {
      return siblingsInMap(node, null);
    }
    var parent = path[length - 2];
    if (parent is YamlList) {
      return siblingsInList(parent, node);
    } else if (parent is YamlMap) {
      return siblingsInMap(parent, node);
    }
    return const <String>[];
  }

  /// Returns the 0-based column of [offset] within [content].
  static int _columnAt(String content, int offset) {
    if (offset == 0) return 0;
    var lastNewline = content.lastIndexOf('\n', offset - 1);
    return offset - lastNewline - 1;
  }
}

class YamlCompletionResults {
  final List<CompletionSuggestion> suggestions;
  final String targetPrefix;
  final int replacementOffset;
  final int replacementLength;

  const new(
    this.suggestions,
    this.targetPrefix,
    this.replacementOffset,
    this.replacementLength,
  );

  const new empty()
    : suggestions = const [],
      targetPrefix = '',
      replacementOffset = 0,
      replacementLength = 0;
}
