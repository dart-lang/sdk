// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/yaml/producer.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:yaml/yaml.dart';

/// A completion generator that can produce completion suggestions for files
/// containing a YAML structure.
abstract class YamlCompletionGenerator {
  /// The resource provider used to access the content of the file in which
  /// completion was requested.
  final ResourceProvider resourceProvider;

  /// Initialize a newly created generator to use the [resourceProvider] to
  /// access the content of the file in which completion was requested.
  YamlCompletionGenerator(this.resourceProvider);

  /// Return the producer used to produce suggestions at the top-level of the
  /// file.
  Producer get topLevelProducer;

  /// Return the completion suggestions appropriate for the given [offset] in
  /// the file at the given [filePath].
  List<CompletionSuggestion> getSuggestions(String filePath, int offset) {
    var file = resourceProvider.getFile(filePath);
    String content;
    try {
      content = file.readAsStringSync();
    } on FileSystemException {
      // If the file doesn't exist or can't be read, then there are no
      // suggestions.
      return const <CompletionSuggestion>[];
    }
    var root = _parseYaml(content);
    if (root == null) {
      // If the contents can't be parsed, then there are no suggestions.
      return const <CompletionSuggestion>[];
    }
    var path = _pathToOffset(root, offset);
    var completionNode = path.last;
    if (completionNode is YamlScalar) {
      var value = completionNode.value;
      if (value == null) {
        return getSuggestionsForPath(path, offset);
      } else if (value is String && completionNode.style == ScalarStyle.PLAIN) {
        return getSuggestionsForPath(path, offset);
      }
    } else {
      return getSuggestionsForPath(path, offset);
    }
    // There are no completions at the given location.
    return const <CompletionSuggestion>[];
  }

  /// Given a [path] to the node in which completions are being requested and
  /// the offset of the cursor, return the completions appropriate at that
  /// location.
  List<CompletionSuggestion> getSuggestionsForPath(
      List<YamlNode> path, int offset) {
    var producer = _producerForPath(path);
    if (producer == null) {
      return const <CompletionSuggestion>[];
    }
    var invalidSuggestions = _siblingsOnPath(path);
    var suggestions = <CompletionSuggestion>[];
    for (var suggestion in producer.suggestions()) {
      if (!invalidSuggestions.contains(suggestion.completion)) {
        suggestions.add(suggestion);
      }
    }
    return suggestions;
  }

  /// Return the result of parsing the file [content] into a YAML node.
  YamlNode _parseYaml(String content) {
    try {
      return loadYamlNode(content);
    } on YamlException {
      // If the file can't be parsed, then fall through to return `null`.
    }
    return null;
  }

  /// Return a list containing the node containing the [offset] and all of the
  /// nodes between that and the [root] node. The root node is first in the list
  /// and the node containing the offset is the last element in the list.
  List<YamlNode> _pathToOffset(YamlNode root, int offset) {
    var path = <YamlNode>[];
    var node = root;
    while (node != null) {
      path.add(node);
      node = node.childContainingOffset(offset);
    }
    return path;
  }

  /// Return the producer that should be used to produce completion suggestions
  /// for the last node in the node [path].
  Producer _producerForPath(List<YamlNode> path) {
    var producer = topLevelProducer;
    for (var i = 0; i < path.length - 1; i++) {
      var node = path[i];
      if (node is YamlMap && producer is MapProducer) {
        var key = node.keyAtValue(path[i + 1]);
        if (key is YamlScalar) {
          producer = (producer as MapProducer).children[key.value];
        } else {
          return null;
        }
      } else if (node is YamlList && producer is ListProducer) {
        producer = (producer as ListProducer).element;
      } else {
        return producer;
      }
    }
    return producer;
  }

  /// Return a list of the suggestions that should not be suggested because they
  /// are already in the structure.
  List<String> _siblingsOnPath(List<YamlNode> path) {
    List<String> siblingsInList(YamlList list, YamlNode currentElement) {
      var siblings = <String>[];
      for (var element in list.nodes) {
        if (element != currentElement &&
            element is YamlScalar &&
            element.value is String) {
          siblings.add(element.value);
        }
      }
      return siblings;
    }

    List<String> siblingsInMap(YamlMap map, YamlNode currentKey) {
      var siblings = <String>[];
      for (var key in map.nodes.keys) {
        if (key != currentKey && key is YamlScalar && key.value is String) {
          siblings.add('${key.value}: ');
        }
      }
      return siblings;
    }

    var length = path.length;
    if (length < 2) {
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
}

extension on YamlMap {
  /// Return the node representing the key that corresponds to the value
  /// represented by the [value] node.
  YamlNode keyAtValue(YamlNode value) {
    for (var entry in nodes.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    return null;
  }
}

extension on YamlNode {
  /// Return the child of this node that contains the given [offset], or `null`
  /// if none of the children contains the offset.
  YamlNode childContainingOffset(int offset) {
    var node = this;
    if (node is YamlList) {
      for (var element in node.nodes) {
        if (element.containsOffset(offset)) {
          return element;
        }
      }
      for (var element in node.nodes) {
        if (element is YamlScalar && element.value == null) {
          // TODO(brianwilkerson) Testing for a null value probably gets
          //  confused when there are multiple null values.
          return element;
        }
      }
    } else if (node is YamlMap) {
      for (var entry in node.nodes.entries) {
        if ((entry.key as YamlNode).containsOffset(offset)) {
          return entry.key;
        }
        var value = entry.value;
        if (value.containsOffset(offset) ||
            (value is YamlScalar && value.value == null)) {
          // TODO(brianwilkerson) Testing for a null value probably gets
          //  confused when there are multiple null values or when there is a
          //  null value before the node that actually contains the offset.
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Return `true` if this node contains the given [offset].
  bool containsOffset(int offset) {
    // TODO(brianwilkerson) Nodes at the end of the file contain any trailing
    //  whitespace. This needs to be accounted for, here or elsewhere.
    var nodeOffset = span.start.offset;
    var nodeEnd = nodeOffset + span.length;
    return nodeOffset <= offset && offset <= nodeEnd;
  }
}
