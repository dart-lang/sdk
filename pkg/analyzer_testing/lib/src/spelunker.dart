// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

final class Spelunker {
  final StringSink _sink;
  final FeatureSet _featureSet;
  final String _source;

  Spelunker(this._source, {StringSink? sink, FeatureSet? featureSet})
    : _sink = sink ?? stdout,
      _featureSet = featureSet ?? FeatureSet.latestLanguageVersion();

  void spelunk() {
    var parseResult = parseString(content: _source, featureSet: _featureSet);

    var visitor = _SourceVisitor(_sink);
    parseResult.unit.accept(visitor);
  }
}

class _SourceVisitor extends GeneralizingAstVisitor<void> {
  int indent = 0;

  final StringSink sink;

  _SourceVisitor(this.sink);

  String asString(AstNode node) => '${typeInfo(node.runtimeType)} [$node]';

  List<CommentToken> getPrecedingComments(Token token) {
    var comments = <CommentToken>[];
    var comment = token.precedingComments;
    while (comment is CommentToken) {
      comments.add(comment);
      comment = comment.next as CommentToken?;
    }
    return comments;
  }

  String getTrailingComment(AstNode node) {
    var successor = node.endToken.next;
    if (successor != null) {
      var precedingComments = successor.precedingComments;
      if (precedingComments != null) {
        return precedingComments.toString();
      }
    }
    return '';
  }

  String typeInfo(Type type) => type.toString();

  @override
  void visitNode(AstNode node) {
    write(node);

    ++indent;
    node.visitChildren(this);
    --indent;
  }

  void write(AstNode node) {
    // EOL comments.
    var comments = getPrecedingComments(node.beginToken);
    for (var comment in comments) {
      sink.writeln('${"  " * indent}$comment');
    }

    sink.writeln(
      '${"  " * indent}${asString(node)} ${getTrailingComment(node)}',
    );
  }
}
