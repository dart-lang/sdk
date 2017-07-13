// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of analyzer.parser;

class _Builder implements Builder {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _KernelLibraryBuilder implements KernelLibraryBuilder {
  @override
  final uri;

  _KernelLibraryBuilder(this.uri);

  @override
  Uri get fileUri => uri;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Replacement parser based on Fasta.
 */
class _Parser2 implements Parser {
  @override
  Token currentToken;

  /**
   * The builder which creates the analyzer AST data structures
   * based on the Fasta parser.
   */
  final AstBuilder _astBuilder;

  /**
   * The fasta parser being wrapped.
   */
  final fasta.Parser _fastaParser;

  /**
   * The source being parsed.
   */
  final Source _source;

  factory _Parser2(Source source, AnalysisErrorListener errorListener) {
    var errorReporter = new ErrorReporter(errorListener, source);
    var library = new _KernelLibraryBuilder(source.uri);
    var member = new _Builder();
    var scope = new Scope.top(isModifiable: true);

    AstBuilder astBuilder =
        new AstBuilder(errorReporter, library, member, scope, true);
    fasta.Parser fastaParser = new fasta.Parser(astBuilder);
    astBuilder.parser = fastaParser;
    return new _Parser2._(source, fastaParser, astBuilder);
  }

  _Parser2._(this._source, this._fastaParser, this._astBuilder);

  @override
  bool get parseGenericMethodComments => _astBuilder.parseGenericMethodComments;

  @override
  set parseGenericMethodComments(bool value) {
    _astBuilder.parseGenericMethodComments = value;
  }

  @override
  CompilationUnit parseCompilationUnit(Token token) {
    currentToken = token;
    return parseCompilationUnit2();
  }

  @override
  CompilationUnit parseCompilationUnit2() {
    currentToken = _fastaParser.parseUnit(currentToken);
    return _astBuilder.pop();
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
