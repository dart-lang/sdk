// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' as server
    show SourceEdit;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:dart_style/dart_style.dart';

DartFormatter _formatter = DartFormatter();

/// Transforms a sequence of LSP document change events to a sequence of source
/// edits used by analysis plugins.
///
/// Since the translation from line/characters to offsets needs to take previous
/// changes into account, this will also apply the edits to [oldContent].
ErrorOr<({String content, List<plugin.SourceEdit> edits})>
    applyAndConvertEditsToServer(
  String oldContent,
  List<TextDocumentContentChangeEvent> changes, {
  bool failureIsCritical = false,
}) {
  var newContent = oldContent;
  final serverEdits = <server.SourceEdit>[];

  for (var change in changes) {
    // Change is a union that may/may not include a range. If no range
    // is provided (t2 of the union) the whole document should be replaced.
    final result = change.map(
      // TextDocumentContentChangeEvent1
      // {range, text}
      (change) {
        final lines = LineInfo.fromContent(newContent);
        final offsetStart = toOffset(lines, change.range.start,
            failureIsCritical: failureIsCritical);
        final offsetEnd = toOffset(lines, change.range.end,
            failureIsCritical: failureIsCritical);
        if (offsetStart.isError) {
          return ErrorOr.error(offsetStart.error);
        }
        if (offsetEnd.isError) {
          return ErrorOr.error(offsetEnd.error);
        }
        newContent = newContent.replaceRange(
            offsetStart.result, offsetEnd.result, change.text);
        serverEdits.add(server.SourceEdit(offsetStart.result,
            offsetEnd.result - offsetStart.result, change.text));
      },
      // TextDocumentContentChangeEvent2
      // {text}
      (change) {
        serverEdits
          ..clear()
          ..add(server.SourceEdit(0, newContent.length, change.text));
        newContent = change.text;
      },
    );
    // If any change fails, immediately return the error.
    if (result != null && result.isError) {
      return ErrorOr.error(result.error);
    }
  }
  return ErrorOr.success((content: newContent, edits: serverEdits));
}

ErrorOr<List<TextEdit>?> generateEditsForFormatting(
  ParsedUnitResult result,
  int? lineLength, {
  Range? range,
}) {
  final unformattedSource = result.content;

  final code =
      SourceCode(unformattedSource, uri: null, isCompilationUnit: true);
  SourceCode formattedResult;
  try {
    // If the lineLength has changed, recreate the formatter with the new setting.
    if (lineLength != _formatter.pageWidth) {
      _formatter = DartFormatter(pageWidth: lineLength);
    }
    formattedResult = _formatter.formatSource(code);
  } on FormatterException {
    // If the document fails to parse, just return no edits to avoid the
    // use seeing edits on every save with invalid code (if LSP gains the
    // ability to pass a context to know if the format was manually invoked
    // we may wish to change this to return an error for that case).
    return success(null);
  }
  final formattedSource = formattedResult.text;

  if (formattedSource == unformattedSource) {
    return success(null);
  }

  return generateMinimalEdits(result, formattedSource, range: range);
}

List<TextEdit> generateFullEdit(
    LineInfo lineInfo, String unformattedSource, String formattedSource) {
  final end = lineInfo.getLocation(unformattedSource.length);
  return [
    TextEdit(
      range:
          Range(start: Position(line: 0, character: 0), end: toPosition(end)),
      newText: formattedSource,
    )
  ];
}

/// Generates edits that modify the minimum amount of code (if only whitespace,
/// commas and comments) to change the source of [result] to [formatted].
///
/// This allows editors to more easily track important locations (such as
/// breakpoints) without needing to do their own diffing.
///
/// If [range] is supplied, only edits that fall entirely inside this range will
/// be included in the results.
ErrorOr<List<TextEdit>> generateMinimalEdits(
  ParsedUnitResult result,
  String formatted, {
  Range? range,
}) {
  final unformatted = result.content;
  final lineInfo = result.lineInfo;
  final rangeStart = range != null ? toOffset(lineInfo, range.start) : null;
  final rangeEnd = range != null ? toOffset(lineInfo, range.end) : null;

  if (rangeStart != null && rangeStart.isError) {
    return failure(rangeStart);
  }
  if (rangeEnd != null && rangeEnd.isError) {
    return failure(rangeEnd);
  }

  // It shouldn't be the case that we can't parse the code but if it happens
  // fall back to a full replacement rather than fail.
  final parsedFormatted = _parse(formatted, result.unit.featureSet);
  final parsedUnformatted = _parse(unformatted, result.unit.featureSet);
  if (parsedFormatted == null || parsedUnformatted == null) {
    return success(generateFullEdit(lineInfo, unformatted, formatted));
  }

  final unformattedTokens = _iterateAllTokens(parsedUnformatted).iterator;
  final formattedTokens = _iterateAllTokens(parsedFormatted).iterator;

  var unformattedOffset = 0;
  var formattedOffset = 0;
  final edits = <TextEdit>[];

  /// Helper for comparing whitespace and appending an edit.
  void addEditFor(
    int unformattedStart,
    int unformattedEnd,
    int formattedStart,
    int formattedEnd,
  ) {
    final unformattedWhitespace =
        unformatted.substring(unformattedStart, unformattedEnd);
    final formattedWhitespace =
        formatted.substring(formattedStart, formattedEnd);

    if (rangeStart != null && rangeEnd != null) {
      // If this change crosses over the start of the requested range, discarding
      // the change may result in leading whitespace of the next line not being
      // formatted correctly.
      //
      // To handle this, if both unformatted/formatted contain at least one
      // newline, split this change into two around the last newline so that the
      // final part (likely leading whitespace) can be included without
      // including the whole change. This cannot be done if the newline is at
      // the end of the source whitespace though, as this would create a split
      // where the first part is the same and the second part is empty,
      // resulting in an infinite loop/stack overflow.
      //
      // Without this, functionality like VS Code's "format modified lines"
      // (which uses Git status to know which lines are edited) may appear to
      // fail to format the first newly added line in a range.
      if (unformattedStart < rangeStart.result &&
          unformattedEnd > rangeStart.result &&
          unformattedWhitespace.contains('\n') &&
          formattedWhitespace.contains('\n') &&
          !unformattedWhitespace.endsWith('\n')) {
        // Find the offsets of the character after the last newlines.
        final unformattedOffset = unformattedWhitespace.lastIndexOf('\n') + 1;
        final formattedOffset = formattedWhitespace.lastIndexOf('\n') + 1;
        // Call us again for the leading part
        addEditFor(
          unformattedStart,
          unformattedStart + unformattedOffset,
          formattedStart,
          formattedStart + formattedOffset,
        );
        // Call us again for the trailing part
        addEditFor(
          unformattedStart + unformattedOffset,
          unformattedEnd,
          formattedStart + formattedOffset,
          formattedEnd,
        );
        return;
      }

      // If we're formatting only a range, skip over any segments that don't fall
      // entirely within that range.
      if (unformattedStart < rangeStart.result ||
          unformattedEnd > rangeEnd.result) {
        return;
      }
    }

    if (unformattedWhitespace == formattedWhitespace) {
      return;
    }

    // Validate we didn't find more than whitespace. If this occurs, it's likely
    // the token offsets used were incorrect. In this case it's better to not
    // modify the code than potentially remove something important.
    if (unformattedWhitespace.trim().isNotEmpty ||
        formattedWhitespace.trim().isNotEmpty) {
      return;
    }

    var startOffset = unformattedStart;
    var endOffset = unformattedEnd;
    var newText = formattedWhitespace;

    // Simplify some common cases where the new whitespace is a subset of
    // the old.
    if (formattedWhitespace.isNotEmpty) {
      if (unformattedWhitespace.startsWith(formattedWhitespace)) {
        startOffset = unformattedStart + formattedWhitespace.length;
        newText = '';
      } else if (unformattedWhitespace.endsWith(formattedWhitespace)) {
        endOffset = unformattedEnd - formattedWhitespace.length;
        newText = '';
      }
    }

    // Finally, append the edit for this whitespace.
    // Note: As with all LSP edits, offsets are based on the original location
    // as they are applied in one shot. They should not account for the previous
    // edits in the same set.
    edits.add(TextEdit(
      range: Range(
        start: toPosition(lineInfo.getLocation(startOffset)),
        end: toPosition(lineInfo.getLocation(endOffset)),
      ),
      newText: newText,
    ));
  }

  // Process the whitespace before each token.
  bool unformattedHasMore, formattedHasMore;
  while ((unformattedHasMore =
          unformattedTokens.moveNext()) & // Don't short-circuit
      (formattedHasMore = formattedTokens.moveNext())) {
    final unformattedToken = unformattedTokens.current;
    final formattedToken = formattedTokens.current;

    if (unformattedToken.lexeme != formattedToken.lexeme) {
      // If the token lexemes do not match, there is a difference in the parsed
      // token streams (this should not ordinarily happen) so fall back to a
      // full edit.
      return success(generateFullEdit(lineInfo, unformatted, formatted));
    }

    addEditFor(
      unformattedOffset,
      unformattedToken.offset,
      formattedOffset,
      formattedToken.offset,
    );

    // When range formatting, if we've processed a token that ends after the
    // range then there can't be any more relevant edits and we can return early.
    if (rangeEnd != null && unformattedToken.end > rangeEnd.result) {
      return success(edits);
    }

    unformattedOffset = unformattedToken.end;
    formattedOffset = formattedToken.end;
  }

  // If we got here and either of the streams still have tokens, something
  // did not match so fall back to a full edit.
  if (unformattedHasMore || formattedHasMore) {
    return success(generateFullEdit(lineInfo, unformatted, formatted));
  }

  // Finally, handle any whitespace that was after the last token.
  addEditFor(
    unformattedOffset,
    unformatted.length,
    formattedOffset,
    formatted.length,
  );

  return success(edits);
}

/// Iterates over a token stream returning all tokens including comments.
Iterable<Token> _iterateAllTokens(Token token) sync* {
  while (!token.isEof) {
    Token? commentToken = token.precedingComments;
    while (commentToken != null) {
      yield commentToken;
      commentToken = commentToken.next;
    }
    yield token;
    token = token.next!;
  }
}

/// Parse and return the first of the given Dart source, `null` if code cannot
/// be parsed.
Token? _parse(String s, FeatureSet featureSet) {
  try {
    var scanner = Scanner(_SourceMock.instance, CharSequenceReader(s),
        AnalysisErrorListener.NULL_LISTENER)
      ..configureFeatures(
        featureSetForOverriding: featureSet,
        featureSet: featureSet,
      );
    return scanner.tokenize();
  } catch (e) {
    return null;
  }
}

/// Helper class that bundles up all information required when converting server
/// SourceEdits into LSP-compatible WorkspaceEdits.
class FileEditInformation {
  final OptionalVersionedTextDocumentIdentifier doc;
  final LineInfo lineInfo;

  /// A list of edits to be made to the file.
  ///
  /// These edits must be sorted using servers rules (as in `SourceFileEdit`s).
  ///
  /// Server works with edits that can be applied sequentially to a [String]. This
  /// means inserts at the same offset are in the reverse order. For LSP, all
  /// offsets relate to the original document and inserts with the same offset
  /// appear in the order they will appear in the final document.
  final List<server.SourceEdit> edits;

  final bool newFile;

  /// The selection offset, relative to the edit.
  final int? selectionOffsetRelative;
  final int? selectionLength;

  FileEditInformation(
    this.doc,
    this.lineInfo,
    this.edits, {
    required this.newFile,
    this.selectionOffsetRelative,
    this.selectionLength,
  });
}

class _SourceMock implements Source {
  static final Source instance = _SourceMock();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
