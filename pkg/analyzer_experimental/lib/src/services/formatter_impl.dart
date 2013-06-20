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
  final EditRecorder recorder;
  final errors = <AnalysisError>[];

  CodeFormatterImpl(FormatterOptions options) : this.options = options,
      recorder = new EditRecorder(options);

  String format(CodeKind kind, String source, {int offset, int end,
      int indentationLevel:0}) {

    var start = tokenize(source);
    checkForErrors();

    var node = parse(kind, start);
    checkForErrors();

    var formatter = new FormattingEngine(options);
    return formatter.format(source, node, start, kind, recorder);
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

  checkForErrors() {
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


/// Records a sequence of edits to a source string that will cause the string
/// to be formatted when applied.
class EditRecorder {

  final FormatterOptions options;
  final EditStore editStore;

  int column = 0;

  int sourceIndex = 0;
  String source = '';

  Token currentToken;

  int numberOfIndentations = 0;

  bool needsIndent = false;

  EditRecorder(this.options): editStore = new EditStore();

  /// Add an [Edit] that describes a textual [replacement] of a text
  /// interval starting at the given [offset] spanning the given [length].
  void addEdit(int offset, int length, String replacement) {
    editStore.addEdit(offset, length, replacement);
  }

  /// Advance past the given expected [token] (or fail if not matched).
  void advance(Token token) {
    if (currentToken.lexeme == token.lexeme) {

      // TODO(pquitslund) emit comments
//      if (needsIndent) {
//        advanceIndent();
//        needsIndent = false;
//      }
      // Record writing a token at the current edit location
      advanceChars(token.length);
      currentToken = currentToken.next;
    } else {
      wrongToken(token.lexeme);
    }
  }

  /// Move indices past indent, adding an edit if needed to adjust indentation
  void advanceIndent() {
//    var indentWidth = options.indentPerLevel * indentationLevel;
//    var indentString = getIndentString(indentWidth);
//    var sourceIndentWidth = 0;
//    for (var i = 0; i < source.length; i++) {
//      if (isIndentChar(source[sourceIndex + i])) {
//        sourceIndentWidth += 1;
//      } else {
//        break;
//      }
//    }
//    var hasSameIndent = sourceIndentWidth == indentWidth;
//    if (hasSameIndent) {
//      for (var i = 0; i < indentWidth; i++) {
//        if (source[sourceIndex + i] != indentString[i]) {
//          hasSameIndent = false;
//          break;
//        }
//      }
//      if (hasSameIndent) {
//        advanceChars(indentWidth);
//        return;
//      }
//    }
//    addEdit(sourceIndex, sourceIndentWidth, indentString);
//    column += indentWidth;
//    sourceIndex += sourceIndentWidth;

    var indent = options.indentPerLevel * numberOfIndentations;

    spaces(indent);
  }

  String getIndentString(int indentWidth) {

    // TODO(pquitslund) a temporary workaround
    if (indentWidth < 0) {
      return '';
    }

    // TODO(pquitslund) allow indent with tab chars

    // Fetch a precomputed indent string
    if (indentWidth < SPACES.length) {
      return SPACES[indentWidth];
    }

    // Build un-precomputed strings dynamically
    var sb = new StringBuffer();
    for (var i = 0; i < indentWidth; ++i) {
      sb.write(' ');
    }
    return sb.toString();
  }

  /// Advance past the given expected [token] (or fail if not matched).
  void advanceToken(String token) {
    if (currentToken.lexeme == token) {
      advance(currentToken);
    } else {
      wrongToken(token);
    }
  }

  /// Advance [column] and [sourceIndex] indices by [len] characters.
  void advanceChars(int len) {
    column += len;
    sourceIndex += len;
  }

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

  /// Update indent indices.
  void indent() {
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

  /// Newline.
  void newline() {
    // TODO(pquitslund) emit comments
    needsIndent = true;
    // If there is a newline before the edit location, do nothing.
    if (isNewlineAt(sourceIndex - NEW_LINE.length)) {
      return;
    }
    // If there is a newline after the edit location, advance over it.
    if (isNewlineAt(sourceIndex)) {
      advanceChars(NEW_LINE.length);
      return;
    }
    // Otherwise, replace whitespace with a newline.
    var charsToReplace = countWhitespace();
    if (isNewlineAt(sourceIndex + charsToReplace)) {
      charsToReplace += NEW_LINE.length;
    }
    addEdit(sourceIndex, charsToReplace, NEW_LINE);
    advanceChars(charsToReplace);
  }


  /// Un-indent.
  void unindent() {
    numberOfIndentations--;
  }

  /// Space.
  void space() {
    // TODO(pquitslund) emit comments
//    // If there is a space before the edit location, do nothing.
//    if (isSpaceAt(sourceIndex - 1)) {
//      return;
//    }
//    // If there is a space after the edit location, advance over it.
//    if (isSpaceAt(sourceIndex)) {
//      advance(1);
//      return;
//    }
    // Otherwise, replace spaces with a single space.
    spaces(1);
  }

  /// Spaces.
  void spaces(int num) {
    var charsToReplace = countWhitespace();
    addEdit(sourceIndex, charsToReplace, SPACES[num]);
    advanceChars(charsToReplace);
  }

  wrongToken(String token) {
    throw new FormatterException('expected token: "${token}", '
                                 'actual: "${currentToken}"');
  }

  String toString() =>
      new EditOperation().apply(editStore.edits,
                                source.substring(0, sourceIndex));

}

const SPACE = ' ';
final SPACES = [
          '',
          ' ',
          '  ',
          '   ',
          '    ',
          '     ',
          '      ',
          '       ',
          '        ',
          '         ',
          '          ',
          '           ',
          '            ',
          '             ',
          '              ',
          '               ',
          '                ',
];


bool isIndentChar(String ch) => ch == SPACE; // TODO(pquitslund) also check tab


/// Manages stored [Edit]s.
class EditStore {

  const EditStore();

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

/// Applies a sequence of [edits] to a [document].
class EditOperation {

  String apply(List<Edit> edits, String document) {

    var edit;
    for (var i = edits.length - 1; i >= 0; --i) {
      edit = edits[i];
      document = replace(document, edit.offset,
                         edit.offset + edit.length, edit.replacement);
    }

    return document;
  }

}


String replace(String str, int start, int end, String replacement) =>
    str.substring(0, start) + replacement + str.substring(end);


/// An AST visitor that drives formatting heuristics.
class FormattingEngine extends RecursiveASTVisitor {

  final FormatterOptions options;

  CodeKind kind;
  EditRecorder recorder;

  FormattingEngine(this.options);

  String format(String source, ASTNode node, Token start, CodeKind kind,
      EditRecorder recorder) {

    this.kind = kind;
    this.recorder = recorder;

    recorder..source = source
            ..currentToken = start;

    node.accept(this);

    var editor = new EditOperation();
    return editor.apply(recorder.editStore.edits, source);
  }


  visitClassDeclaration(ClassDeclaration node) {

    recorder.advanceIndent();

    if (node.documentationComment != null) {
      node.documentationComment.accept(this);
    }

    recorder..advance(node.classKeyword)..space();

    node.name.accept(this);

    if (node.typeParameters != null) {
      node.typeParameters.accept(this);
    }
    recorder.space();

    if (node.extendsClause != null) {
      node.extendsClause.accept(this);
      recorder.space();
    }

    if (node.implementsClause != null) {
      node.implementsClause.accept(this);
      recorder.space();
    }

    recorder..advance(node.leftBracket)
            ..indent();

    for (var member in node.members) {
      recorder..newline()
              ..advanceIndent();
      member.accept(this);
    }

    recorder..unindent()
            ..newline()
            ..advanceIndent()
            ..advance(node.rightBracket);
  }


  visitBlockFunctionBody(BlockFunctionBody node) {
    node.block.accept(this);
  }


  visitBlock(Block block) {
    recorder..advance(block.leftBracket)
            ..indent()
            ..newline();
    // ...
    recorder..unindent()
            ..advanceIndent()
            ..advance(block.rightBracket);
  }


  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    recorder..advance(node.functionDefinition)
            ..indent()
            ..newline();
    node.expression.accept(this);
    recorder..unindent()
            ..advanceIndent()
            ..advance(node.semicolon);
  }


  visitMethodDeclaration(MethodDeclaration node) {

    if (node.modifierKeyword != null) {
      recorder.advance(node.modifierKeyword);
      recorder.space();
    }

    if (node.returnType != null) {
      node.returnType.accept(this);
      recorder.space();
    }

    recorder.advance(node.name.beginToken);

    node.parameters.accept(this);

    recorder.space();

    node.body.accept(this);
  }


  visitFormalParameterList(FormalParameterList node) {
    recorder.advance(node.beginToken);
    //...
    recorder.advance(node.endToken);
  }


  visitSimpleIdentifier(SimpleIdentifier node) {
    recorder.advance(node.token);
  }

}
