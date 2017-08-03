// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart' show Parser;
import 'package:analyzer/src/string_source.dart' show StringSource;
import 'package:path/path.dart' as p;

final _identifier = new RegExp(r'^([(_|$)a-zA-Z]+([_a-zA-Z0-9])*)$');

final _lowerCamelCase =
    new RegExp(r'^(_)*[?$a-z][a-z0-9?$]*([A-Z][a-z0-9?$]*)*$');

final _lowerCaseUnderScore = new RegExp(r'^([a-z]+([_]?[a-z0-9]+)*)+$');

final _lowerCaseUnderScoreWithDots =
    new RegExp(r'^[a-z][_a-z0-9]*(\.[a-z][_a-z0-9]*)*$');

final _pubspec = new RegExp(r'^[_]?pubspec\.yaml$');

final _underscores = new RegExp(r'^[_]+$');

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
@deprecated // Never intended for public use.
bool isDartFileName(String fileName) => fileName.endsWith('.dart');

/// Returns `true` if this [name] is a legal Dart identifier.
@deprecated // Never intended for public use.
bool isIdentifier(String name) => _identifier.hasMatch(name);

/// Returns `true` of the given [name] is composed only of `_`s.
@deprecated // Never intended for public use.
bool isJustUnderscores(String name) => _underscores.hasMatch(name);

/// Returns `true` if this [id] is `lowerCamelCase`.
@deprecated // Never intended for public use.
bool isLowerCamelCase(String id) =>
    id.length == 1 && isUpperCase(id.codeUnitAt(0)) ||
    id == '_' ||
    _lowerCamelCase.hasMatch(id);

/// Returns `true` if this [id] is `lower_camel_case_with_underscores`.
@deprecated // Never intended for public use.
bool isLowerCaseUnderScore(String id) => _lowerCaseUnderScore.hasMatch(id);

/// Returns `true` if this [id] is `lower_camel_case_with_underscores_or.dots`.
@deprecated // Never intended for public use.
bool isLowerCaseUnderScoreWithDots(String id) =>
    _lowerCaseUnderScoreWithDots.hasMatch(id);

/// Returns `true` if this [fileName] is a Pubspec file.
@deprecated // Never intended for public use.
bool isPubspecFileName(String fileName) => _pubspec.hasMatch(fileName);

/// Returns `true` if the given code unit [c] is upper case.
@deprecated // Never intended for public use.
bool isUpperCase(int c) => c >= 0x40 && c <= 0x5A;

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

class _ErrorListener implements AnalysisErrorListener {
  final errors = <AnalysisError>[];

  @override
  void onError(AnalysisError error) {
    errors.add(error);
  }

  void throwIfErrors() {
    if (errors.isNotEmpty) {
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
