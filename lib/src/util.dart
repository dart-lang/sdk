// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.util;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/parser.dart' show Parser;
import 'package:analyzer/src/generated/scanner.dart'
    show CharSequenceReader, CommentToken, Scanner, Token;
import 'package:analyzer/src/string_source.dart' show StringSource;
import 'package:path/path.dart' as p;

final _identifier = new RegExp(r'^([_a-zA-Z]+([_a-zA-Z0-9])*)$');

final _lowerCamelCase = new RegExp(r'^[_]?[a-z][a-z0-9]*([A-Z][a-z0-9]*)*$');

final _lowerCaseUnderScore = new RegExp(r'^([a-z]+([_]?[a-z0-9]+)*)+$');

final _lowerCaseUnderScoreWithDots =
    new RegExp(r'^([a-z]+([_]?[a-z0-9]+)?)+(.([a-z]+([_]?[a-z0-9]+)?))*$');

final _pubspec = new RegExp(r'^[_]?pubspec\.yaml$');

/// Create a library name prefix based on [libraryPath], [projectRoot] and
/// current [packageName].
String createLibraryNamePrefix(
    {String libraryPath, String projectRoot, String packageName}) {
  // Use the posix context to canonicalize separators (`\`).
  var libraryDirectory = p.posix.dirname(libraryPath);
  var path = p.posix.relative(libraryDirectory, from: projectRoot);
  // Drop 'lib/'.
  var segments = p.split(path);
  if (segments[0] == 'lib') {
    path = p.posix.joinAll(segments.sublist(1));
  }
  // Replace separators.
  path = path.replaceAll('/', '.');
  // Add separator if needed.
  if (path.isNotEmpty) {
    path = '.$path';
  }

  return '$packageName$path';
}

/// Returns `true` if this [fileName] is a Dart file.
bool isDartFileName(String fileName) => fileName.endsWith('.dart');

/// Returns `true` if this [name] is a legal Dart identifier.
bool isIdentifier(String name) => _identifier.hasMatch(name);

/// Returns `true` if this [id] is `lowerCamelCase`.
bool isLowerCamelCase(String id) => _lowerCamelCase.hasMatch(id) || id == '_';

/// Returns `true` if this [id] is `lower_camel_case_with_underscores`.
bool isLowerCaseUnderScore(String id) => _lowerCaseUnderScore.hasMatch(id);

/// Returns `true` if this [id] is `lower_camel_case_with_underscores_or.dots`.
bool isLowerCaseUnderScoreWithDots(String id) =>
    _lowerCaseUnderScoreWithDots.hasMatch(id);

/// Returns `true` if this [fileName] is a Pubspec file.
bool isPubspecFileName(String fileName) => _pubspec.hasMatch(fileName);

class _ErrorListener implements AnalysisErrorListener {
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

class _SourceVisitor extends GeneralizingAstVisitor {
  int indent = 0;

  final IOSink sink;
  _SourceVisitor(this.sink);

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
    comments.forEach((c) => sink.writeln('${"  " * indent}$c'));

    sink.writeln(
        '${"  " * indent}${asString(node)} ${getTrailingComment(node)}');
  }
}

class Spelunker {
  final String path;
  final IOSink sink;
  Spelunker(this.path, {IOSink sink}) : this.sink = sink ?? stdout;

  void spelunk() {
    var contents = new File(path).readAsStringSync();

    var errorListener = new _ErrorListener();

    var reader = new CharSequenceReader(contents);
    var stringSource = new StringSource(contents, path);
    var scanner = new Scanner(stringSource, reader, errorListener);
    var startToken = scanner.tokenize();

    errorListener.throwIfErrors();

    var parser = new Parser(stringSource, errorListener);
    var node = parser.parseCompilationUnit(startToken);

    errorListener.throwIfErrors();

    var visitor = new _SourceVisitor(sink);
    node.accept(visitor);
  }
}
