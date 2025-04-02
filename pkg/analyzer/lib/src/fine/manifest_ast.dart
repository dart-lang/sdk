// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';

class ManifestAnnotation extends ManifestNode {
  final ManifestSimpleIdentifier name;

  ManifestAnnotation({
    required this.name,
  });

  factory ManifestAnnotation.encode(
    EncodeContext context,
    Annotation node,
  ) {
    if (node.name case SimpleIdentifier identifier) {
      return ManifestAnnotation(
        name: ManifestSimpleIdentifier.encode(context, identifier),
      );
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  factory ManifestAnnotation.read(SummaryDataReader reader) {
    return ManifestAnnotation(
      name: ManifestSimpleIdentifier.read(reader),
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

sealed class ManifestNode {
  bool match(MatchContext context, AstNode node);

  void write(BufferedSink sink);

  static ManifestNode encode(EncodeContext context, AstNode node) {
    switch (node) {
      case Annotation():
        return ManifestAnnotation.encode(context, node);
      case SimpleIdentifier():
        return ManifestSimpleIdentifier.encode(context, node);
      default:
        throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  static ManifestNode read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestNodeKind.values);
    switch (kind) {
      case _ManifestNodeKind.annotation:
        return ManifestAnnotation.read(reader);
      case _ManifestNodeKind.simpleIdentifier:
        return ManifestSimpleIdentifier.read(reader);
    }
  }
}

class ManifestSimpleIdentifier extends ManifestNode {
  final String name;
  final ManifestElement? element;

  ManifestSimpleIdentifier({
    required this.name,
    required this.element,
  });

  factory ManifestSimpleIdentifier.encode(
    EncodeContext context,
    SimpleIdentifier node,
  ) {
    var element = node.element;
    return ManifestSimpleIdentifier(
      name: node.name,
      element:
          element != null ? ManifestElement.encode(context, element) : null,
    );
  }

  factory ManifestSimpleIdentifier.read(SummaryDataReader reader) {
    return ManifestSimpleIdentifier(
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
  simpleIdentifier,
}
