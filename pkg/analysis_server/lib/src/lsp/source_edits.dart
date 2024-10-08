// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' as server
    show SourceEdit;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:dart_style/dart_style.dart';

/// Checks whether a string contains only characters that are allowed to differ
/// between unformattedformatted code (such as whitespace, commas, semicolons).
final _isValidFormatterChange = RegExp(r'^[\s,;<>]*$').hasMatch;

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
  var serverEdits = <server.SourceEdit>[];

  for (var change in changes) {
    // Change is a union that may/may not include a range. If no range
    // is provided (t2 of the union) the whole document should be replaced.
    var result = change.map(
      // TextDocumentContentChangeEvent1
      // {range, text}
      (change) {
        var lines = LineInfo.fromContent(newContent);
        var offsetStart = toOffset(lines, change.range.start,
            failureIsCritical: failureIsCritical);
        var offsetEnd = toOffset(lines, change.range.end,
            failureIsCritical: failureIsCritical);
        if (offsetStart.isError) {
          return failure(offsetStart);
        }
        if (offsetEnd.isError) {
          return failure(offsetEnd);
        }
        (offsetStart, offsetEnd).ifResults((offsetStart, offsetEnd) {
          newContent =
              newContent.replaceRange(offsetStart, offsetEnd, change.text);
          serverEdits.add(server.SourceEdit(
              offsetStart, offsetEnd - offsetStart, change.text));
        });
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
      return failure(result);
    }
  }
  return ErrorOr.success((content: newContent, edits: serverEdits));
}

/// Generates a list of [TextEdit]s to format the code for [result].
///
/// [defaultPageWidth] will be used as the default page width if [result] does
/// not have an analysis_options file that defines a page width.
///
/// If [range] is provided, only edits that intersect with this range will be
/// returned.
ErrorOr<List<TextEdit>?> generateEditsForFormatting(
  ParsedUnitResult result, {
  int? defaultPageWidth,
  Range? range,
}) {
  var unformattedSource = result.content;

  // The analysis options page width always takes priority over the default from
  // the LSP configuration.
  var effectivePageWidth =
      result.analysisOptions.formatterOptions.pageWidth ?? defaultPageWidth;

  var code = SourceCode(unformattedSource);
  SourceCode formattedResult;
  try {
    // Create a new formatter on every request because it may contain state that
    // affects repeated formats.
    // https://github.com/dart-lang/dart_style/issues/1337
    var languageVersion =
        result.unit.declaredElement?.library.languageVersion.effective ??
            DartFormatter.latestLanguageVersion;
    var formatter = DartFormatter(
        pageWidth: effectivePageWidth, languageVersion: languageVersion);
    formattedResult = formatter.formatSource(code);
  } on FormatterException {
    // If the document fails to parse, just return no edits to avoid the
    // use seeing edits on every save with invalid code (if LSP gains the
    // ability to pass a context to know if the format was manually invoked
    // we may wish to change this to return an error for that case).
    return success(null);
  }
  var formattedSource = formattedResult.text;

  if (formattedSource == unformattedSource) {
    return success(null);
  }

  return generateMinimalEdits(result, formattedSource, range: range);
}

List<TextEdit> generateFullEdit(
    LineInfo lineInfo, String unformattedSource, String formattedSource) {
  var end = lineInfo.getLocation(unformattedSource.length);
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
  var unformatted = result.content;
  var lineInfo = result.lineInfo;
  var rangeStart =
      range != null ? toOffset(lineInfo, range.start) : success(null);
  var rangeEnd = range != null ? toOffset(lineInfo, range.end) : success(null);

  return (rangeStart, rangeEnd).mapResultsSync((rangeStart, rangeEnd) {
    var computer = _MinimalEditComputer(
      result: result,
      lineInfo: lineInfo,
      unformatted: unformatted,
      formatted: formatted,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    var edits = computer.computeMinimalEdits();
    return success(edits);
  });
}

enum ChangeAnnotations {
  /// Do not include change annotations.
  none,

  /// Include change annotations but do not require a user to confirm changes.
  include,

  /// Include change annotations and require the user to confirm changes.
  requireConfirmation,
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

/// Computes minimal edits to translate a set of parseable source code into
/// another (usually produced by the formatter).
class _MinimalEditComputer {
  // A set of tokens that the formatter may add or remove, which we will
  // allow and not abort for.
  static const allowedAddOrRemovedTokens = {
    TokenType.COMMA,
    TokenType.SEMICOLON,
  };

  // A set of tokens that the formatter may alter the lexem for but must still
  // match types.
  static const allowedLexemeDifferences = {
    // Comments may have trailing spaces removed from lines.
    TokenType.MULTI_LINE_COMMENT,
    TokenType.SINGLE_LINE_COMMENT,
  };

  // A map of tokens that are allowed to be substituted as a result of
  // format changes and the set of possible sequences they may be replaced
  // with.
  static const allowedSubstitutions = {
    TokenType.GT_GT_GT: {
      [TokenType.GT, TokenType.GT, TokenType.GT],
      [TokenType.GT, TokenType.GT_GT],
      [TokenType.GT_GT, TokenType.GT],
    },
    TokenType.GT_GT: {
      [TokenType.GT, TokenType.GT]
    },
    TokenType.LT_LT: {
      [TokenType.LT, TokenType.LT]
    },
    TokenType.INDEX: {
      [TokenType.OPEN_SQUARE_BRACKET, TokenType.CLOSE_SQUARE_BRACKET]
    }
  };

  final LineInfo _lineInfo;
  final String _unformatted;
  final String _formatted;
  final int? _rangeStart;

  final int? _rangeEnd;
  final Token? _parsedUnformatted;

  final Token? _parsedFormatted;

  /// The edits being built.
  final _edits = <TextEdit>[];

  _MinimalEditComputer({
    required ParsedUnitResult result,
    required LineInfo lineInfo,
    required String unformatted,
    required String formatted,
    required int? rangeStart,
    required int? rangeEnd,
  })  : _lineInfo = lineInfo,
        _unformatted = unformatted,
        _formatted = formatted,
        _rangeStart = rangeStart,
        _rangeEnd = rangeEnd,
        _parsedUnformatted = _parse(unformatted, result.unit.featureSet),
        _parsedFormatted = _parse(formatted, result.unit.featureSet);

  /// Compute the edits.
  ///
  /// If for any reason edits cannot be computed, then:
  ///
  /// - If a range was specified, no edits will be returned.
  /// - If no range was specified, a single edit for the entire document will be
  ///   returned.
  List<TextEdit> computeMinimalEdits() {
    if (_edits.isNotEmpty) {
      throw StateError('computeMinimalEdits may only used once per instance.');
    }

    // It shouldn't be the case that we can't parse the code but if it happens
    // fall back to a full replacement rather than fail.
    if (_parsedFormatted == null || _parsedUnformatted == null) {
      return generateFullEdit(_lineInfo, _unformatted, _formatted);
    }

    var unformattedTokens = _iterateAllTokens(_parsedUnformatted).iterator;
    var formattedTokens = _iterateAllTokens(_parsedFormatted).iterator;

    var unformattedOffset = 0;
    var formattedOffset = 0;

    // Walk through the token streams computing edits for the differences.
    bool unformattedHasMore, formattedHasMore;
    while ((unformattedHasMore =
            unformattedTokens.moveNext()) & // Don't short-circuit.
        (formattedHasMore = formattedTokens.moveNext())) {
      var unformattedToken = unformattedTokens.current;
      var formattedToken = formattedTokens.current;

      // Compute the ranges from each side that that we will produce an edit for.
      // This is usually just the whitespace from each side (the range between the
      // end of the previous token and the start of the current), but in the case
      // of commas will be expanded to include the commas (and then the following
      // whitespace).
      var unformattedStart = unformattedOffset;
      var unformattedEnd = unformattedToken.offset;
      var formattedStart = formattedOffset;
      var formattedEnd = formattedToken.offset;
      var allowAnyContentDifferences = false;

      /// Helper to advance the formatted stream by [count] tokens if it is not
      /// at the end.
      void advanceFormatted([int count = 1]) {
        // Don't use `formattedToken.next?.offset`, that would skip comments.
        formattedEnd = formattedToken.end;
        for (int i = 0; i < count; i++) {
          if (formattedHasMore = formattedTokens.moveNext()) {
            formattedToken = formattedTokens.current;
            formattedEnd = formattedToken.offset;
          }
        }
      }

      /// Helper to advance the unformatted stream by [count] tokens if it is
      /// not at the end.
      void advanceUnformatted([int count = 1]) {
        // Don't use `unformattedToken.next?.offset`, that would skip comments.
        unformattedEnd = unformattedToken.end;
        for (int i = 0; i < count; i++) {
          if (unformattedHasMore = unformattedTokens.moveNext()) {
            unformattedToken = unformattedTokens.current;
            unformattedEnd = unformattedToken.offset;
          }
        }
      }

      // We may need to advance multiple times if multiple allowed tokens are
      // added/removed consecutively.
      while (unformattedHasMore && formattedHasMore) {
        var sameTokenTypes = formattedToken.type == unformattedToken.type;

        // Handle differences allowed when tokens are different types.
        if (!sameTokenTypes) {
          // The formatter added an allowed token, advance over it.
          if (_isAllowedOptional(formattedToken)) {
            advanceFormatted();
            continue;
          }

          // The formatter removed an allowed token, advance over it.
          if (_isAllowedOptional(unformattedToken)) {
            advanceUnformatted();
            continue;
          }

          // The formatter substituted `unformattedToken` for some other tokens
          // starting at `formattedToken`.
          if (_substitutes(unformattedToken, formattedToken) case var num?) {
            advanceUnformatted();
            advanceFormatted(num);
            continue;
          }

          // The formatter collapsed tokens in `unformattedToken` for a new
          // `formattedToken`. This is the opposite of the case above.
          if (_substitutes(formattedToken, unformattedToken) case var num?) {
            advanceFormatted();
            advanceUnformatted(num);
            continue;
          }
        }

        // Handle differences allowed when tokens are the same type.
        if (sameTokenTypes) {
          // The formatter made a change to the lexeme of a token type we allow.
          if (allowedLexemeDifferences.contains(unformattedToken.type) &&
              unformattedToken.lexeme != formattedToken.lexeme) {
            advanceUnformatted();
            advanceFormatted();
            allowAnyContentDifferences = true;
            continue;
          }
        }

        // If we didn't hit any `continue` above to restart the loop, then we
        // are done.
        break;
      }

      if (unformattedToken.lexeme != formattedToken.lexeme) {
        // If the token lexemes do not match, there is a difference in the
        // parsed token streams (this should not ordinarily happen) so use the
        // fallback.
        return _generateFallback();
      }

      // Add edits for the computed ranges.
      _addEditFor(
        unformattedStart,
        unformattedEnd,
        formattedStart,
        formattedEnd,
        allowAnyContentDifferences: allowAnyContentDifferences,
      );

      // And move the pointers along to after these tokens.
      unformattedOffset = unformattedToken.end;
      formattedOffset = formattedToken.end;

      // When range formatting, if we've processed a token that ends after the
      // range then there can't be any more relevant edits and we can return early.
      if (_rangeEnd != null && unformattedOffset > _rangeEnd) {
        return _edits;
      }
    }

    // If we got here and either of the streams still have tokens, something
    // did not match so use the fallback.
    if (unformattedHasMore || formattedHasMore) {
      return _generateFallback();
    }

    // Finally, handle any whitespace that was after the last token.
    _addEditFor(
      unformattedOffset,
      _unformatted.length,
      formattedOffset,
      _formatted.length,
    );

    return _edits;
  }

  /// Helper for comparing whitespace and appending an edit.
  void _addEditFor(
    int unformattedStart,
    int unformattedEnd,
    int formattedStart,
    int formattedEnd, {
    bool allowAnyContentDifferences = false,
  }) {
    var unformattedWhitespace =
        _unformatted.substring(unformattedStart, unformattedEnd);
    var formattedWhitespace =
        _formatted.substring(formattedStart, formattedEnd);

    if (_rangeStart != null && _rangeEnd != null) {
      // If this change crosses over the start of the requested range,
      // discarding the change may result in leading whitespace of the next line
      // not being formatted correctly.
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
      if (unformattedStart < _rangeStart &&
          unformattedEnd > _rangeStart &&
          unformattedWhitespace.contains('\n') &&
          formattedWhitespace.contains('\n') &&
          !unformattedWhitespace.endsWith('\n')) {
        // Find the offsets of the character after the last newlines.
        var unformattedOffset = unformattedWhitespace.lastIndexOf('\n') + 1;
        var formattedOffset = formattedWhitespace.lastIndexOf('\n') + 1;
        // Call us again for the leading part
        _addEditFor(
          unformattedStart,
          unformattedStart + unformattedOffset,
          formattedStart,
          formattedStart + formattedOffset,
        );
        // Call us again for the trailing part
        _addEditFor(
          unformattedStart + unformattedOffset,
          unformattedEnd,
          formattedStart + formattedOffset,
          formattedEnd,
        );
        return;
      }

      // If we're formatting only a range, skip over any segments that don't
      // fall entirely within that range.
      if (unformattedStart < _rangeStart || unformattedEnd > _rangeEnd) {
        return;
      }
    }

    if (unformattedWhitespace == formattedWhitespace) {
      return;
    }

    var startOffset = unformattedStart;
    var endOffset = unformattedEnd;
    var oldText = unformattedWhitespace;
    var newText = formattedWhitespace;

    // Simplify some common cases where the new whitespace is a subset of
    // the old.
    // Remove common prefixes.
    int commonPrefixLength = 0;
    while (commonPrefixLength < oldText.length &&
        commonPrefixLength < newText.length &&
        oldText[commonPrefixLength] == newText[commonPrefixLength]) {
      commonPrefixLength++;
    }
    if (commonPrefixLength != 0) {
      oldText = oldText.substring(commonPrefixLength);
      newText = newText.substring(commonPrefixLength);
      startOffset += commonPrefixLength;
    }

    // Remove common suffixes.
    int commonSuffixLength = 0;
    while (commonSuffixLength < oldText.length &&
        commonSuffixLength < newText.length &&
        oldText[oldText.length - 1 - commonSuffixLength] ==
            newText[newText.length - 1 - commonSuffixLength]) {
      commonSuffixLength++;
    }
    if (commonSuffixLength != 0) {
      oldText = oldText.substring(0, oldText.length - commonSuffixLength);
      newText = newText.substring(0, newText.length - commonSuffixLength);
      endOffset -= commonSuffixLength;
    }

    // Unless allowing any differences, validate that the replaced and
    // replacement text only contain characters that we expected the formatter
    // to have changed. If the change contains other characters, it's likely
    // the token offsets used were incorrect and it's better to not modify the
    // code than potentially corrupt it.
    if (!allowAnyContentDifferences &&
        (!_isValidFormatterChange(oldText) ||
            !_isValidFormatterChange(newText))) {
      return;
    }

    // Finally, append the edit for this whitespace.
    // Note: As with all LSP edits, offsets are based on the original location
    // as they are applied in one shot. They should not account for the previous
    // edits in the same set.
    _edits.add(TextEdit(
      range: Range(
        start: toPosition(_lineInfo.getLocation(startOffset)),
        end: toPosition(_lineInfo.getLocation(endOffset)),
      ),
      newText: newText,
    ));
  }

  /// Generates fallback results for if we are unable to minimize edits
  /// because the token streams differ in a way that we don't expect. This may
  /// indicate a bug in the formatter, or a bug in our assumptions about what
  /// tokens may change between formatted/unformatted (such as brackets - see
  /// https://github.com/Dart-Code/Dart-Code/issues/5169).
  List<TextEdit> _generateFallback() {
    if (_rangeStart == null && _rangeEnd == null) {
      // If this was a full document format, we can fall back to a single edit
      // for the whole document.
      return generateFullEdit(_lineInfo, _unformatted, _formatted);
    } else {
      // If we were a range format, we are unable to reduce the edits to that
      // range so we should format nothing.
      return [];
    }
  }

  /// Whether [token] is allowed to exist only in the formatted or unformatted
  /// code.
  ///
  /// For example, the formatted may add or remove commas or semicolons and we
  /// should not consider these errors.
  bool _isAllowedOptional(Token token) {
    return allowedAddOrRemovedTokens.contains(token.type);
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

  /// A helper to check whether the token [left] has been substituted in [right]
  /// and returns the total number of tokens it was subtituted with.
  ///
  /// For example, if [left] is a `GT_GT_GT` token and [right] is a sequence
  /// starting `GT`, `GT, `GT`, returns 3.
  ///
  /// Returns `null` if [right] does not begin with an allowed substitution.
  int? _substitutes(Token left, Token right) {
    var possibleSubstitutions = allowedSubstitutions[left.type];
    if (possibleSubstitutions == null) return null;

    // For each possible sequence of substitutes...
    for (var possibleSubstitution in possibleSubstitutions) {
      var numSubtitutes = possibleSubstitution.length;
      var match = true;
      Token? current = right;

      // Check if the first `possibleSubstitution.length` tokens match the
      // allowed substitution.
      for (int i = 0; i < numSubtitutes && match; i++) {
        if (possibleSubstitution[i] != current?.type) {
          match = false;
          break;
        }
        current = current?.next;
      }

      if (match) {
        return numSubtitutes;
      }
    }

    return null;
  }

  /// Parse and return the first of the given Dart source, `null` if code cannot
  /// be parsed.
  static Token? _parse(String s, FeatureSet featureSet) {
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
}

class _SourceMock implements Source {
  static final Source instance = _SourceMock();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
