// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import '../scrape.dart';

/// Wire up [visitor] to [scrape] the given [path] containing [source] with
/// [info].
///
/// This is a top-level function instead of an instance method so that we can
/// hide it and not export it from scrape's public API. Only [Scrape] itself
/// should call this. We bind separately instead of passing these through the
/// [ScrapeVisitor] constructor so that subclasses of [ScrapeVisitor] don't
/// need to define a pass-through constructor.
void bindVisitor(ScrapeVisitor visitor, Scrape scrape, String path,
    String source, LineInfo info) {
  assert(visitor._scrape == null, 'Should only bind once.');
  visitor._scrape = scrape;
  visitor._path = path;
  visitor._source = source;
  visitor.lineInfo = info;
}

/// Base Visitor class with some utility functionality.
class ScrapeVisitor extends RecursiveAstVisitor<void> {
  // These final-ish fields are initialized by [bindVisitor()].
  Scrape _scrape;
  String _path;
  String _source;
  LineInfo lineInfo;

  /// How many levels deep the visitor is currently nested inside build methods.
  int _inFlutterBuildMethods = 0;

  String get path => _path;

  // TODO(rnystrom): Remove this in favor of using surveyor for these kinds of
  // analyses.
  /// Whether the visitor is currently inside a Flutter "build" method,
  /// either directly or nested inside some other function inside one.
  ///
  /// This is only an approximate guess. It assumes a method is a "build"-like
  /// method if it returns "Widget", or has a parameter list that starts with
  /// "BuildContext context".
  bool get isInFlutterBuildMethod => _inFlutterBuildMethods > 0;

  bool _isBuildMethod(TypeAnnotation returnType, SimpleIdentifier name,
      FormalParameterList parameters) {
    var parameterString = parameters.toString();

    if (returnType.toString() == 'void') return false;
    if (parameterString.startsWith('(BuildContext context')) return true;
    if (returnType.toString() == 'Widget') return true;

    return false;
  }

  /// Add an occurrence of [item] to [histogram].
  void record(String histogram, Object item) {
    _scrape.record(histogram, item);
  }

  /// Write [message] to stdout, clearing the current line if needed.
  void log(Object message) {
    _scrape.log(message);
  }

  /// Print a nice representation of [node].
  void printNode(AstNode node) {
    log(nodeToString(node));
  }

  /// Generate a nice string representation of [node] include file path and
  /// line information.
  String nodeToString(AstNode node) {
    var startLine = lineInfo.getLocation(node.offset).lineNumber;
    var endLine = lineInfo.getLocation(node.end).lineNumber;

    startLine = startLine.clamp(0, lineInfo.lineCount - 1) as int;
    endLine = endLine.clamp(0, lineInfo.lineCount - 1) as int;

    var buffer = StringBuffer();
    buffer.writeln('// $path:$startLine');
    for (var line = startLine; line <= endLine; line++) {
      // Note that getLocation() returns 1-based lines, but getOffsetOfLine()
      // expects 0-based.
      var offset = lineInfo.getOffsetOfLine(line - 1);
      // -1 to not include the newline.
      var end = lineInfo.getOffsetOfLine(line) - 1;

      buffer.writeln(_source.substring(offset, end));
    }

    return buffer.toString();
  }

  /// Get the line number of the code at [offset].
  int getLine(int offset) => lineInfo.getLocation(offset).lineNumber;

  /// Override this to execute custom code before visiting a Flutter build
  /// method.
  void beforeVisitBuildMethod(Declaration node) {}

  /// Override this to execute custom code after visiting a Flutter build
  /// method.
  void afterVisitBuildMethod(Declaration node) {}

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var isBuild = _isBuildMethod(node.returnType, node.name, node.parameters);
    if (isBuild) _inFlutterBuildMethods++;

    try {
      if (isBuild) beforeVisitBuildMethod(node);
      super.visitMethodDeclaration(node);
      if (isBuild) afterVisitBuildMethod(node);
    } finally {
      if (isBuild) _inFlutterBuildMethods--;
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var isBuild = _isBuildMethod(
        node.returnType, node.name, node.functionExpression.parameters);
    if (isBuild) _inFlutterBuildMethods++;

    try {
      if (isBuild) beforeVisitBuildMethod(node);
      super.visitFunctionDeclaration(node);
      if (isBuild) afterVisitBuildMethod(node);
    } finally {
      if (isBuild) _inFlutterBuildMethods--;
    }
  }
}
