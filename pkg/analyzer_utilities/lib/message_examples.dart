// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Data model for the examples that accompany diagnostic messages in CFE style
/// `messages.yaml` files (the `bytes`, `declaration`, `expression`, `script`,
/// and `statement` keys).
///
/// These examples are used by both the front end's `messages_suite.dart` and
/// the analyzer's tests to verify that the corresponding diagnostic is
/// reported.
library;

import 'dart:typed_data';

import 'package:analyzer_utilities/located_error.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/// An example consisting of raw bytes, used to test diagnostics that can't be
/// represented by valid UTF-8 source code.
class BytesExample extends MessageExample {
  /// The bytes of the main file.
  final Uint8List bytes;

  new(super.name, super.span, this.bytes);
}

/// An example consisting of a top level declaration.
///
/// The declaration is followed by an empty `main` function.
class DeclarationExample extends SourceExample {
  /// The source text of the declaration.
  final String declaration;

  new(super.name, super.span, this.declaration);

  @override
  Map<String, String> get files => {
    MessageExample.mainFileName: '$declaration\n\nmain() {\n}\n',
  };
}

/// An example consisting of an expression.
///
/// The expression is wrapped in an expression statement inside a `main`
/// function.
class ExpressionExample extends SourceExample {
  /// The source text of the expression.
  final String expression;

  new(super.name, super.span, this.expression);

  @override
  Map<String, String> get files => {
    MessageExample.mainFileName: 'main() {\n  $expression;\n}\n',
  };
}

/// An example from a CFE style `messages.yaml` file, which should cause the
/// corresponding diagnostic to be reported.
sealed class MessageExample {
  /// The name of the file that should be analyzed or compiled.
  static const String mainFileName = 'main.dart';

  /// The name of the example (e.g. `script` or `script2`), which is unique
  /// within the message.
  final String name;

  /// The span of the YAML node that the example was decoded from.
  final SourceSpan span;

  new(this.name, this.span);

  /// Decodes the examples associated with [key] in a message's YAML map, where
  /// [node] is the corresponding value.
  ///
  /// If [node] is a list (or, for `bytes`, a list of lists), each element is a
  /// separate example, and the examples are named by appending a 1-based index
  /// to [key]. Otherwise there is a single example, named [key].
  static List<MessageExample> decode(String key, YamlNode node) {
    MessageExample Function(String name, YamlNode node) decodeOne =
        switch (key) {
          'bytes' => _decodeBytes,
          'declaration' => (name, node) => DeclarationExample(
            name,
            node.span,
            _decodeString(node),
          ),
          'expression' => (name, node) => ExpressionExample(
            name,
            node.span,
            _decodeString(node),
          ),
          'script' => _decodeScript,
          'statement' => (name, node) => StatementExample(
            name,
            node.span,
            _decodeString(node),
          ),
          _ => throw ArgumentError.value(key, 'key', 'Not an example key'),
        };
    var isMultiple = switch (node) {
      YamlList(:var nodes) when key == 'bytes' =>
        nodes.isNotEmpty && nodes.first is YamlList,
      YamlList() => key != 'bytes',
      _ => false,
    };
    if (isMultiple) {
      var nodes = (node as YamlList).nodes;
      return [
        for (var i = 0; i < nodes.length; i++)
          LocatedError.wrap(
            () => decodeOne('$key${i + 1}', nodes[i]),
            span: nodes[i].span,
          ),
      ];
    } else {
      return [decodeOne(key, node)];
    }
  }

  static BytesExample _decodeBytes(String name, YamlNode node) {
    if (node is! YamlList) throw 'Must be a list of bytes';
    var bytes = <int>[];
    for (var element in node.nodes) {
      if (element case YamlScalar(:int value) when value >= 0 && value < 256) {
        bytes.add(value);
      } else {
        throw 'Must be a list of bytes';
      }
    }
    return BytesExample(name, node.span, Uint8List.fromList(bytes));
  }

  static ScriptExample _decodeScript(String name, YamlNode node) {
    switch (node) {
      case YamlScalar(:String value):
        return ScriptExample(name, node.span, {mainFileName: value});
      case YamlMap(:var nodes):
        var files = <String, String>{};
        for (var MapEntry(key: keyNode, value: valueNode) in nodes.entries) {
          if (keyNode case YamlScalar(value: String fileName)) {
            files[fileName] = _decodeString(valueNode);
          } else {
            throw 'Script file names must be strings';
          }
        }
        if (!files.containsKey(mainFileName)) {
          throw 'A multi-file script must contain a file named '
              '"$mainFileName"';
        }
        return ScriptExample(name, node.span, files);
      default:
        throw 'A script must be either a String or a Map';
    }
  }

  static String _decodeString(YamlNode node) => switch (node) {
    YamlScalar(:String value) => value,
    _ => throw 'Must be a string',
  };
}

/// An example consisting of a complete Dart script.
///
/// A script may consist of multiple files, in which case one of them must be
/// named [MessageExample.mainFileName].
class ScriptExample extends SourceExample {
  @override
  final Map<String, String> files;

  new(super.name, super.span, this.files);
}

/// An example whose contents are Dart source code (as opposed to raw bytes).
sealed class SourceExample extends MessageExample {
  new(super.name, super.span);

  /// The files making up the example, as a map from file name to source text.
  ///
  /// This map always contains an entry for [MessageExample.mainFileName].
  Map<String, String> get files;
}

/// An example consisting of a statement.
///
/// The statement is placed inside a `main` function.
class StatementExample extends SourceExample {
  /// The source text of the statement.
  final String statement;

  new(super.name, super.span, this.statement);

  @override
  Map<String, String> get files => {
    MessageExample.mainFileName: 'main() {\n  $statement\n}\n',
  };
}
