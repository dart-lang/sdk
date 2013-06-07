// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library formatter_impl;


import 'dart:io';

import 'package:analyzer_experimental/analyzer.dart';
import 'package:analyzer_experimental/src/generated/parser.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:analyzer_experimental/src/generated/source.dart';


/// OS line separator. --- TODO(pquitslund): may not be necessary
const NEW_LINE = '\n' ; //Platform.pathSeparator;

/// Formatter options.
class FormatterOptions {

  /// Create formatter options with defaults derived (where defined) from
  /// the style guide: <http://www.dartlang.org/articles/style-guide/>.
  const FormatterOptions({this.initialIndentationLevel: 0,
                 this.indentPerLevel: 2,
                 this.lineSeparator: NEW_LINE,
                 this.pageWidth: 80,
                 this.tabSize: 2});

  final String lineSeparator;
  final int initialIndentationLevel;
  final int indentPerLevel;
  final int tabSize;
  final int pageWidth;
}


/// Thrown when an error occurs in formatting.
class FormatterException implements Exception {

  /// A message describing the error.
  final message;

  /// Creates a new FormatterException with an optional error [message].
  const FormatterException([this.message = '']);

  FormatterException.forError(List<AnalysisError> errors) :
    // TODO(pquitslund): add descriptive message based on errors
    message = 'an analysis error occured during format';

  String toString() => 'FormatterException: $message';

}

/// Specifies the kind of code snippet to format.
class CodeKind {

  final index;

  const CodeKind(this.index);

  /// A compilation unit snippet.
  static const COMPILATION_UNIT = const CodeKind(0);

  /// A statement snippet.
  static const STATEMENT = const CodeKind(1);

}

/// Dart source code formatter.
abstract class CodeFormatter {

  factory CodeFormatter([FormatterOptions options = const FormatterOptions()])
                        => new CodeFormatterImpl(options);

  /// Format the specified portion (from [offset] with [length]) of the given
  /// [source] string, optionally providing an [indentationLevel].
  String format(CodeKind kind, String source, {int offset, int end,
    int indentationLevel:0});

}

class CodeFormatterImpl implements CodeFormatter, AnalysisErrorListener {

  final FormatterOptions options;
  final List<AnalysisError> errors = <AnalysisError>[];

  CodeFormatterImpl(this.options);

  String format(CodeKind kind, String source, {int offset, int end,
      int indentationLevel:0}) {

    var start = tokenize(source);
    _checkForErrors();

    var node = parse(kind, start);
    _checkForErrors();

    // To be continued...

    return source;
  }

  ASTNode parse(CodeKind kind, Token start) {

    var parser = new Parser(null, this);

    switch (kind) {
      case CodeKind.COMPILATION_UNIT:
        return parser.parseCompilationUnit(start);
      case CodeKind.STATEMENT:
        return parser.parseStatement(start);
    }

    throw new FormatterException('Unsupported format kind: $kind');
  }

  _checkForErrors() {
    if (errors.length > 0) {
      throw new FormatterException.forError(errors);
    }
  }

  void onError(AnalysisError error) {
    errors.add(error);
  }

  Token tokenize(String source) {
    var scanner = new StringScanner(null, source, this);
    return scanner.tokenize();
  }

}

/// Placeholder class to hold a reference to the Class object representing
/// the Dart keyword void.
class Void extends Object {

}


/// Records a sequence of edits to a source string that will cause the string
/// to be formatted when applied.
class EditRecorder {

  final FormatterOptions options;

  int column = 0;

  int sourceIndex = 0;
  String source = '';

  Token currentToken;

  int indentationLevel = 0;
  int numberOfIndentations = 0;

  bool isIndentNeeded = false;

  EditRecorder(this.options);

  /// Count the number of whitespace chars beginning at the current
  /// [sourceIndex].
  int countWhitespace() {
    var count = 0;
    for (var i = sourceIndex; i < source.length; ++i) {
      if (isIndentChar(source[i])) {
        ++count;
      } else {
        break;
      }
    }
    return count;
  }

  /// Indent.
  void indent() {
    indentationLevel += options.indentPerLevel;
    numberOfIndentations++;
  }

  /// Test if there is a newline at the given source [index].
  bool isNewlineAt(int index) {
    if (index < 0 || index + NEW_LINE.length > source.length) {
      return false;
    }
    for (var i = 0; i < NEW_LINE.length; i++) {
      if (source[index] != NEW_LINE[i]) {
        return false;
      }
    }
    return true;
  }

}

const SPACE = ' ';

bool isIndentChar(String ch) => ch == SPACE; // TODO(pquitslund) also check tab


/// Manages stored [Edit]s.
class EditStore {

  /// The underlying sequence of [Edit]s.
  final edits = <Edit>[];

  /// Add the given [Edit] to the end of the edit sequence.
  void add(Edit edit) {
    edits.add(edit);
  }

  /// Add an [Edit] that describes a textual [replacement] of a text interval
  /// starting at the given [offset] spanning the given [length].
  void addEdit(int offset, int length, String replacement) {
    add(new Edit(offset, length, replacement));
  }

  /// Get the index of the current edit (for use in caching location
  /// information).
  int getCurrentEditIndex() =>  edits.length - 1;

  /// Get the last edit.
  Edit getLastEdit() => edits.isEmpty ? null : edits.last;

  /// Add an [Edit] that describes an insertion of text starting at the given
  /// [offset].
  void insert(int offset, String insertedString) {
    addEdit(offset, 0, insertedString);
  }

  /// Reset cached state.
  void reset() {
    edits.clear();
  }

  String toString() => 'EditStore( ${edits.toString()} )';

}



/// Describes a text edit.
class Edit {

  /// The offset at which to apply the edit.
  final int offset;

  /// The length of the text interval to replace.
  final int length;

  /// The replacement text.
  final String replacement;

  /// Create an edit.
  const Edit(this.offset, this.length, this.replacement);

  /// Create an edit for the given [range].
  Edit.forRange(SourceRange range, String replacement):
    this(range.offset, range.length, replacement);

  String toString() => '${offset < 0 ? '(' : 'X('} offset: ${offset} , '
                         'length ${length}, replacement :> ${replacement} <:)';

}

/// An AST visitor that drives formatting heuristics.
class FormattingEngine extends RecursiveASTVisitor<Void> {

  final FormatterOptions options;

  FormattingEngine(this.options);

}
