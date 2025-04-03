// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';

sealed class ManifestNode {
  bool match(MatchContext context, AstNode node);

  void write(BufferedSink sink);

  static ManifestNode encode(EncodeContext context, AstNode node) {
    switch (node) {
      case Annotation():
        return ManifestNodeAnnotation.encode(context, node);
      case IntegerLiteral():
        return ManifestNodeIntegerLiteral.encode(node);
      case SimpleIdentifier():
        return ManifestNodeSimpleIdentifier.encode(context, node);
      default:
        throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  static ManifestNode read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestNodeKind.values);
    switch (kind) {
      case _ManifestNodeKind.annotation:
        return ManifestNodeAnnotation.read(reader);
      case _ManifestNodeKind.integerLiteral:
        return ManifestNodeIntegerLiteral.read(reader);
      case _ManifestNodeKind.simpleIdentifier:
        return ManifestNodeSimpleIdentifier.read(reader);
    }
  }

  static ManifestNode? readOptional(SummaryDataReader reader) {
    return reader.readOptionalObject(() => ManifestNode.read(reader));
  }
}

class ManifestNodeAnnotation extends ManifestNode {
  final ManifestNodeSimpleIdentifier name;

  ManifestNodeAnnotation({
    required this.name,
  });

  factory ManifestNodeAnnotation.encode(
    EncodeContext context,
    Annotation node,
  ) {
    if (node.name case SimpleIdentifier identifier) {
      return ManifestNodeAnnotation(
        name: ManifestNodeSimpleIdentifier.encode(context, identifier),
      );
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  factory ManifestNodeAnnotation.read(SummaryDataReader reader) {
    return ManifestNodeAnnotation(
      name: ManifestNodeSimpleIdentifier.read(reader),
    );
  }

  @override
  bool match(MatchContext context, AstNode node) {
    if (node is! Annotation) {
      return false;
    }

    if (!name.match(context, node.name)) {
      return false;
    }

    return true;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestNodeKind.annotation);
    name.writeNoTag(sink);
  }
}

class ManifestNodeIntegerLiteral extends ManifestNode {
  final int? value;

  ManifestNodeIntegerLiteral({
    required this.value,
  });

  factory ManifestNodeIntegerLiteral.encode(IntegerLiteral node) {
    return ManifestNodeIntegerLiteral(
      value: node.value,
    );
  }

  factory ManifestNodeIntegerLiteral.read(SummaryDataReader reader) {
    return ManifestNodeIntegerLiteral(
      value: reader.readOptionalInt64(),
    );
  }

  @override
  bool match(MatchContext context, AstNode node) {
    return node is IntegerLiteral && node.value == value;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestNodeKind.integerLiteral);
    sink.writeOptionalInt64(value);
  }
}

class ManifestNodeSimpleIdentifier extends ManifestNode {
  final String name;
  final ManifestElement? element;

  ManifestNodeSimpleIdentifier({
    required this.name,
    required this.element,
  });

  factory ManifestNodeSimpleIdentifier.encode(
    EncodeContext context,
    SimpleIdentifier node,
  ) {
    var element = node.element;
    return ManifestNodeSimpleIdentifier(
      name: node.name,
      element:
          element != null ? ManifestElement.encode(context, element) : null,
    );
  }

  factory ManifestNodeSimpleIdentifier.read(SummaryDataReader reader) {
    return ManifestNodeSimpleIdentifier(
      name: reader.readStringUtf8(),
      element: reader.readOptionalObject(
        () => ManifestElement.read(reader),
      ),
    );
  }

  @override
  bool match(MatchContext context, AstNode node) {
    if (node is! SimpleIdentifier) {
      return false;
    }

    if (node.name != name) {
      return false;
    }

    var element = this.element;
    var nodeElement = node.element;
    if (element == null && nodeElement == null) {
    } else if (element == null || nodeElement == null) {
      return false;
    } else if (!element.match(context, nodeElement)) {
      return false;
    }

    return true;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestNodeKind.simpleIdentifier);
    writeNoTag(sink);
  }

  void writeNoTag(BufferedSink sink) {
    sink.writeStringUtf8(name);
    sink.writeOptionalObject(element, (it) => it.write(sink));
  }
}

enum _ManifestNodeKind {
  annotation,
  integerLiteral,
  simpleIdentifier,
}

extension ManifestNodeOrNullExtension on ManifestNode? {
  bool match(MatchContext context, AstNode? node) {
    var self = this;
    if (self == null && node == null) {
      return true;
    } else if (self == null || node == null) {
      return false;
    } else {
      return self.match(context, node);
    }
  }

  void writeOptional(BufferedSink sink) {
    sink.writeOptionalObject(this, (it) => it.write(sink));
  }
}
