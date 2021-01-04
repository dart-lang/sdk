// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:scrape/scrape.dart';

final quoteRegExp = RegExp('\\\\?[\'"]');

void main(List<String> arguments) {
  Scrape()
    ..addHistogram('Directive')
    ..addHistogram('Expression')
    ..addHistogram('Escapes')
    ..addVisitor(() => StringVisitor())
    ..runCommandLine(arguments);
}

class StringVisitor extends ScrapeVisitor {
  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _record('Expression', node);
    _recordEscapes(node);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    // Entire expression containing interpolation elements.
    _record('Expression', node);

    // TODO: Analyze escaped quotes inside strings.

    // TODO: Analyze string literals nested inside interpolation.
    super.visitStringInterpolation(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _record('Directive', node.uri);
    // Don't recurse so that we don't treat the URI as a string expression.
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _record('Directive', node.uri);
    // Don't recurse so that we don't treat the URI as a string expression.
  }

  @override
  void visitPartDirective(PartDirective node) {
    _record('Directive', node.uri);
    // Don't recurse so that we don't treat the URI as a string expression.
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    if (node.uri != null) _record('Directive', node.uri);
    // Don't recurse so that we don't treat the URI as a string expression.
  }

  void _record(String histogram, StringLiteral string) {
    record(histogram, _quoteType(string.beginToken.lexeme));
  }

  void _recordEscapes(StringLiteral string) {
    var quote = _quoteType(string.beginToken.lexeme);

    // Ignore the rarer quote styles.
    if (quote != "'" && quote != '"') return;

    var contents = string.toSource();
    contents = contents.substring(1, contents.length - 1);

    var quotes = quoteRegExp
        .allMatches(contents)
        .map((match) => match[0])
        .toSet()
        .toList();
    quotes.sort();

    if (quotes.isNotEmpty) {
      record('Escapes', '$quote containing ${quotes.join(" ")}');
    }
  }

  String _quoteType(String lexeme) {
    const types = ['"""', "'''", 'r"""', "r'''", '"', "'", 'r"', "r'"];

    for (var type in types) {
      if (lexeme.startsWith(type)) return type;
    }

    log('Unknown string quote in $lexeme');
    return '';
  }
}
