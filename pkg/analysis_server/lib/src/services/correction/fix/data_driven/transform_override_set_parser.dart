// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_override.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_override_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_parser.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:yaml/yaml.dart';

/// A parser used to parse the content of a configuration file.
class TransformOverrideSetParser {
  // TODO(brianwilkerson) Create a class or mixin that would allow this class
  //  and `TransformSetParser` to share code.
  static const String _bulkApplyKey = 'bulkApply';

  /// The error reporter to which diagnostics will be reported.
  final ErrorReporter errorReporter;

  /// Initialize a newly created parser to report errors to the [errorReporter].
  TransformOverrideSetParser(this.errorReporter);

  /// Return the result of parsing the file [content] into a transform override,
  /// or `null` if the content does not represent a valid transform override.
  TransformOverrideSet? parse(String content) {
    var map = _parseYaml(content);
    if (map == null) {
      // The error has already been reported.
      return null;
    }
    return _translateTransformOverrideSet(map);
  }

  /// Return a textual description of the type of value represented by the
  /// [node].
  String _nodeType(YamlNode node) {
    if (node is YamlScalar) {
      return node.value.runtimeType.toString();
    } else if (node is YamlList) {
      return 'List';
    } else if (node is YamlMap) {
      return 'Map';
    }
    // We shouldn't get here.
    return node.runtimeType.toString();
  }

  /// Return the result of parsing the file [content] into a YAML node.
  YamlNode? _parseYaml(String content) {
    try {
      return loadYamlNode(content);
    } on YamlException catch (e) {
      var span = e.span;
      var offset = span?.start.offset ?? 0;
      var length = span?.length ?? 0;
      errorReporter.reportErrorForOffset(
          TransformSetErrorCode.yamlSyntaxError, offset, length, [e.message]);
    }
    return null;
  }

  /// Report a diagnostic with the given [code] associated with the given
  /// [node]. A list of [arguments] should be provided if the diagnostic message
  /// has parameters.
  void _reportError(TransformSetErrorCode code, YamlNode node,
      [List<String> arguments = const []]) {
    var span = node.span;
    errorReporter.reportErrorForOffset(
        code, span.start.offset, span.length, arguments);
  }

  /// Report that the value represented by the [node] does not have the
  /// [expectedType], using the [context] to get the key to use in the message.
  Null _reportInvalidValue(
      YamlNode node, ErrorContext context, String expectedType) {
    _reportError(TransformSetErrorCode.invalidValue, node,
        [context.key, expectedType, _nodeType(node)]);
    return null;
  }

  /// Report that a required key is missing, using the [context] to locate the
  /// node associated with the diagnostic and the key to use in the message.
  Null _reportMissingKey(ErrorContext context) {
    _reportError(
        TransformSetErrorCode.missingKey, context.parentNode, [context.key]);
    return null;
  }

  /// Report any keys in the [map] whose values are not in [validKeys].
  void _reportUnsupportedKeys(YamlMap map, Set<String> validKeys) {
    for (var keyNode in map.nodes.keys) {
      keyNode as YamlNode;
      var key = _translateKey(keyNode);
      if (key != null && !validKeys.contains(key)) {
        _reportError(TransformSetErrorCode.unsupportedKey, keyNode, [key]);
      }
    }
  }

  /// Translate the [node] into a bool. Return the resulting bool, or `null`
  /// if the [node] doesn't represent a valid bool. If the [node] isn't valid,
  /// use the [context] to report the error. If the [node] doesn't exist and
  /// [required] is `true`, then report an error.
  bool? _translateBool(YamlNode? node, ErrorContext context,
      {bool required = true}) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is bool) {
        return value;
      }
      return _reportInvalidValue(node, context, 'boolean');
    } else if (node == null) {
      if (required) {
        return _reportMissingKey(context);
      }
      return null;
    } else {
      return _reportInvalidValue(node, context, 'boolean');
    }
  }

  /// Translate the given [node] as a key.
  String? _translateKey(YamlNode node) {
    String type;
    if (node is YamlScalar) {
      if (node.value is String) {
        return node.value as String;
      }
      type = node.value.runtimeType.toString();
    } else if (node is YamlList) {
      type = 'List';
    } else if (node is YamlMap) {
      type = 'Map';
    } else {
      type = node.runtimeType.toString();
    }
    _reportError(TransformSetErrorCode.invalidKey, node, [type]);
    return null;
  }

  /// Translate the [node] into a string. Return the resulting string, or `null`
  /// if the [node] doesn't represent a valid string. If the [node] isn't valid,
  /// use the [context] to report the error. If the [node] doesn't exist and
  /// [required] is `true`, then report an error.
  String? _translateString(YamlNode? node, ErrorContext context,
      {bool required = true}) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is String) {
        return value;
      }
      return _reportInvalidValue(node, context, 'String');
    } else if (node == null) {
      if (required) {
        return _reportMissingKey(context);
      }
      return null;
    } else {
      return _reportInvalidValue(node, context, 'String');
    }
  }

  /// Translate the [node] into a transform override. Return the resulting
  /// transform override, or `null` if the [node] does not represent a valid
  /// transform override.
  TransformOverride? _translateTransformOverride(
      YamlNode node, ErrorContext context, String title) {
    if (node is YamlMap) {
      _reportUnsupportedKeys(node, const {_bulkApplyKey});
      var bulkApplyNode = node.valueAt(_bulkApplyKey);
      if (bulkApplyNode != null) {
        var bulkApplyValue = _translateBool(
            bulkApplyNode, ErrorContext(key: _bulkApplyKey, parentNode: node),
            required: true);
        if (bulkApplyValue != null) {
          return TransformOverride(title: title, bulkApply: bulkApplyValue);
        }
      }
      return null;
    } else {
      return _reportInvalidValue(node, context, 'Map');
    }
  }

  /// Translate the [node] into a transform override. Return the resulting
  /// transform override, or `null` if the [node] does not represent a valid
  /// transform override.
  TransformOverrideSet? _translateTransformOverrideSet(YamlNode node) {
    if (node is YamlMap) {
      var overrides = <TransformOverride>[];
      for (var entry in node.nodes.entries) {
        var keyNode = entry.key as YamlNode;
        var errorContext = ErrorContext(key: 'file', parentNode: node);
        var key = _translateString(keyNode, errorContext);
        if (key != null) {
          var valueNode = entry.value;
          var override =
              _translateTransformOverride(valueNode, errorContext, key);
          if (override != null) {
            overrides.add(override);
          }
        }
      }
      return TransformOverrideSet(overrides);
    } else {
      // TODO(brianwilkerson) Consider having a different error code for the
      //  top-level node (instead of using 'file' as the "key").
      _reportError(TransformSetErrorCode.invalidValue, node,
          ['file', 'Map', _nodeType(node)]);
      return null;
    }
  }
}
