// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/analyzer.dart'
    show AnalysisError, AnalysisErrorListener, AstNode, GeneralizingAstVisitor;
import 'package:analyzer/src/generated/parser.dart' show Parser;
import 'package:analyzer/src/generated/scanner.dart'
    show CharSequenceReader, CommentToken, Scanner, Token;
import 'package:analyzer/src/string_source.dart' show StringSource;
import 'package:args/args.dart';

/// AST Spelunker
void main([args]) {
  var parser = new ArgParser(allowTrailingOptions: true);

  var options = parser.parse(args);
  options.rest.forEach((path) => spelunk(path));
}

void spelunk(String path) {
  var contents = new File(path).readAsStringSync();

  var errorListener = new ErrorListener();

  var reader = new CharSequenceReader(contents);
  var stringSource = new StringSource(contents, path);
  var scanner = new Scanner(stringSource, reader, errorListener);
  var startToken = scanner.tokenize();

  errorListener.throwIfErrors();

  var parser = new Parser(stringSource, errorListener);
  var node = parser.parseCompilationUnit(startToken);

  errorListener.throwIfErrors();

  var visitor = new SourceVisitor();
  node.accept(visitor);
}

class ErrorListener implements AnalysisErrorListener {
  final errors = <AnalysisError>[];

  void onError(AnalysisError error) {
    errors.add(error);
  }

  void throwIfErrors() {
    if (!errors.isEmpty) {
      throw new Exception(errors);
    }
  }
}

class SourceVisitor extends GeneralizingAstVisitor {
  var indent = 0;

  String asString(AstNode node) =>
      typeInfo(node.runtimeType) + ' [${node.toString()}]';

  List<CommentToken> getPrecedingComments(Token token) {
    var comments = <CommentToken>[];
    var comment = token.precedingComments;
    while (comment is CommentToken) {
      comments.add(comment);
      comment = comment.next;
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
  visitNode(AstNode node) {
    write(node);

    ++indent;
    node.visitChildren(this);
    --indent;
    return null;
  }

  write(AstNode node) {
    //EOL comments
    var comments = getPrecedingComments(node.beginToken);
    comments.forEach((c) => print('${"  " * indent}$c'));

    print('${"  " * indent}${asString(node)} ${getTrailingComment(node)}');
  }
}
