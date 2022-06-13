// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/src/protocol_server.dart' as server
    hide AnalysisError;
import 'package:collection/collection.dart';

/// Builds an LSP snippet string using the supplied edit groups.
///
/// [editGroups] are provided as absolute positions, where the edit will be
/// made starting at [editOffset].
///
/// [selectionOffset] is also absolute and assumes [text] will be
/// inserted at [editOffset].
String buildSnippetStringForEditGroups(
  String text, {
  required String filePath,
  required List<server.LinkedEditGroup> editGroups,
  required int editOffset,
  int? selectionOffset,
  int? selectionLength,
}) =>
    _buildSnippetString(
      text,
      filePath: filePath,
      editGroups: editGroups,
      editGroupsOffset: editOffset,
      selectionOffset:
          selectionOffset != null ? selectionOffset - editOffset : null,
      selectionLength: selectionLength,
    );

/// Builds an LSP snippet string with supplied ranges as tab stops.
///
/// [tabStopOffsetLengthPairs] are relative to the supplied text.
String buildSnippetStringWithTabStops(
  String text,
  List<int>? tabStopOffsetLengthPairs,
) =>
    _buildSnippetString(
      text,
      filePath: null,
      tabStopOffsetLengthPairs: tabStopOffsetLengthPairs,
    );

/// Builds an LSP snippet string with supplied ranges as tab stops.
///
/// [tabStopOffsetLengthPairs] are relative to the supplied text.
///
/// [selectionOffset]/[selectionLength] form a tab stop that is always "number 0"
/// which is the final tab stop.
///
/// [editGroups] are provided as absolute positions, where [text] is known to
/// start at [editGroupsOffset] in the final document.
String _buildSnippetString(
  String text, {
  required String? filePath,
  List<int>? tabStopOffsetLengthPairs,
  int? selectionOffset,
  int? selectionLength,
  List<server.LinkedEditGroup>? editGroups,
  int editGroupsOffset = 0,
}) {
  tabStopOffsetLengthPairs ??= const [];
  editGroups ??= const [];
  assert(tabStopOffsetLengthPairs.length % 2 == 0);

  /// Helper to create a [SnippetPlaceholder] for each position in a linked
  /// edit group.
  Iterable<SnippetPlaceholder> convertEditGroup(
    int index,
    server.LinkedEditGroup editGroup,
  ) {
    final validPositions = editGroup.positions.where((p) => p.file == filePath);
    // Create a placeholder for each position in the group.
    return validPositions.map(
      (position) => SnippetPlaceholder(
        // Make the position relative to the supplied text.
        position.offset - editGroupsOffset,
        editGroup.length,
        suggestions: editGroup.suggestions
            .map((suggestion) => suggestion.value)
            .toList(),
        // Use the index as an ID to keep all related positions together (so
        // the remain "linked").
        linkedGroupId: index,
        // If there is no selection, no tabstops, only a single edit group and
        // not multiple suggestions (which map to a choice), allow this to be
        // the final tabstop.
        isFinal: selectionOffset == null &&
            (tabStopOffsetLengthPairs?.isEmpty ?? false) &&
            editGroups?.length == 1 &&
            editGroup.suggestions.length <= 1,
      ),
    );
  }

  // Convert selection/tab stops/edit groups all into the same format
  // (`_SnippetPlaceholder`) so they can be handled in a single pass through
  // the text.
  final placeholders = [
    // Selection.
    if (selectionOffset != null)
      SnippetPlaceholder(selectionOffset, selectionLength ?? 0, isFinal: true),

    // Tab stops.
    for (var i = 0; i < tabStopOffsetLengthPairs.length - 1; i += 2)
      SnippetPlaceholder(
        tabStopOffsetLengthPairs[i],
        tabStopOffsetLengthPairs[i + 1],
        // If there's only a single tab stop (and no selection/editGroups), mark
        // it as the final stop so it exit "snippet mode" when tabbed to.
        isFinal: selectionOffset == null &&
            editGroups.isEmpty &&
            tabStopOffsetLengthPairs.length == 2,
      ),

    // Linked edit groups.
    ...editGroups.expandIndexed(convertEditGroup),
  ];

  // Remove any groups outside of the range (it's possible the edit groups apply
  // to a different edit in the collection).
  placeholders.removeWhere((placeholder) =>
      placeholder.offset < 0 ||
      placeholder.offset + placeholder.length > text.length);

  /// If there are no edit groups, then placeholders are all simple and
  /// guaranteed to be in the correct order.
  final isPreSorted = editGroups.isEmpty;
  final builder = SnippetBuilder()
    ..appendPlaceholders(text, placeholders, isPreSorted: isPreSorted);
  return builder.value;
}

/// A helper for building for snippets using LSP/TextMate syntax.
///
/// https://microsoft.github.io/language-server-protocol/specifications/specification-current/#snippet_syntax
///
///  - $1, $2, etc. are used for tab stops
///  - ${1:foo} inserts a placeholder of foo
///  - ${1|foo,bar|} inserts a placeholder of foo with a selection list
///      containing "foo" and "bar"
class SnippetBuilder {
  /// The constant `$0` used do indicate a final tab stop in the snippet syntax.
  static const finalTabStop = r'$0';

  /// Regex used by [escapeSnippetChoiceText].
  static final _escapeSnippetChoiceTextRegex =
      RegExp(r'[$}\\\|,]'); // Replace any of $ } \ | ,

  /// Regex used by [escapeSnippetPlainText].
  static final _escapeSnippetPlainTextRegex =
      RegExp(r'[$\\]'); // Replace any of $ \

  /// Regex used by [escapeSnippetVariableText].
  static final _escapeSnippetVariableTextRegex =
      RegExp(r'[$}\\]'); // Replace any of $ } \

  final _buffer = StringBuffer();

  var _nextPlaceholder = 1;

  /// The built snippet text using the LSP snippet syntax.
  String get value => _buffer.toString();

  /// Appends a placeholder with a set of choices to choose from.
  ///
  /// If there are 0 or 1 choices, a placeholder will be inserted instead.
  /// If there are multiple choices, [placeholderNumber] must not be 0.
  ///
  /// Returns the placeholder number used.
  int appendChoice(Set<String> uniqueChoices, {int? placeholderNumber}) {
    // If there's only 0/1 items, we can downgrade this to a placeholder.
    if (uniqueChoices.length <= 1) {
      return appendPlaceholder(
        uniqueChoices.firstOrNull ?? '',
        placeholderNumber: placeholderNumber,
      );
    }

    // Otherwise, we will use a choice. In a choice it'snot valid to be the
    // final (0th) tabstop.
    assert(placeholderNumber == null || placeholderNumber > 0);

    // To avoid producing broken choice snippets in release builds (if the
    // assert above didn't catch issues at dev time), map any final tabstops to
    // use the next available tabstop to produce a valid snippet.
    if (placeholderNumber == 0) {
      placeholderNumber = null;
    }

    placeholderNumber = _usePlaceholerNumber(placeholderNumber);

    final escapedChoices = uniqueChoices.map(escapeSnippetChoiceText).join(',');
    _buffer.write('\${$placeholderNumber|$escapedChoices|}');

    return placeholderNumber;
  }

  /// Appends a placeholder with the given text.
  ///
  /// If the text is empty, inserts a tab stop instead.
  ///
  /// Returns the placeholder number used.
  int appendPlaceholder(String text, {int? placeholderNumber}) {
    // If there's no text, we can downgrade this to a tab stop.
    if (text.isEmpty) {
      return appendTabStop(placeholderNumber: placeholderNumber);
    }

    placeholderNumber = _usePlaceholerNumber(placeholderNumber);

    final escapedText = escapeSnippetVariableText(text);
    _buffer.write(r'${');
    _buffer.write(placeholderNumber);
    _buffer.write(':');
    _buffer.write(escapedText);
    _buffer.write('}');

    return placeholderNumber;
  }

  /// Appends a tab stop.
  ///
  /// Returns the placeholder number used.
  int appendTabStop({int? placeholderNumber}) {
    placeholderNumber = _usePlaceholerNumber(placeholderNumber);

    _buffer.write(r'$');
    _buffer.write(placeholderNumber);

    return placeholderNumber;
  }

  /// Appends normal text (escaping it as required).
  void appendText(String text) {
    _buffer.write(escapeSnippetPlainText(text));
  }

  /// Generates the current and next placeholder numbers.
  int _usePlaceholerNumber(int? placeholderNumber) {
    // If a number was not supplied, use the next available one.
    placeholderNumber ??= _nextPlaceholder;
    // If the number we used was the highest seen, set the next one after it.
    _nextPlaceholder = math.max(_nextPlaceholder, placeholderNumber + 1);

    return placeholderNumber;
  }

  /// Escapes a string use inside a "choice" in a snippet.
  ///
  /// Similar to [escapeSnippetPlainText], but choices are delimited/separated
  /// by pipes and commas (`${1:|a,b,c|}`).
  static String escapeSnippetChoiceText(String input) => _escapeCharacters(
        input,
        _escapeSnippetChoiceTextRegex,
      );

  /// Escapes a string to be used in an LSP edit that uses Snippet mode where the
  /// text is outside of a snippet token.
  ///
  /// Snippets can contain special markup like `${a:b}` so `$` needs escaping
  /// as does `\` so it's not interpreted as an escape.
  static String escapeSnippetPlainText(String input) =>
      _escapeCharacters(input, _escapeSnippetPlainTextRegex);

  /// Escapes a string to be used inside a snippet token.
  ///
  /// Similar to [escapeSnippetPlainText] but additionally escapes `}` so that the
  /// token is not ended early if the included text contains braces.
  static String escapeSnippetVariableText(String input) => _escapeCharacters(
        input,
        _escapeSnippetVariableTextRegex,
      );

  /// Escapes [pattern] in [input] with backslashes.
  static String _escapeCharacters(String input, Pattern pattern) =>
      input.replaceAllMapped(pattern, (c) => '\\${c[0]}');
}

/// Information about an individual placeholder/tab stop in a piece of code.
///
/// Each placeholder represents a single position into the code, so a linked
/// edit group with 2 positions will be represented as two instances of this
/// class (with the same [linkedGroupId]).
class SnippetPlaceholder {
  final int offset;
  final int length;
  final List<String>? suggestions;
  final int? linkedGroupId;
  final bool isFinal;

  SnippetPlaceholder(
    this.offset,
    this.length, {
    this.suggestions,
    this.linkedGroupId,
    this.isFinal = false,
  });
}

/// Helpers for [SnippetBuilder] that do not relate to building the main snippet
/// syntax (for example, converting from intermediate structures).
///
/// `isPreSorted` is a performance optimisation that allows skipping some
/// sorting if it's guaranteed that placeholders are already in source-order.
extension SnippetBuilderExtensions on SnippetBuilder {
  void appendPlaceholders(
    String text,
    List<SnippetPlaceholder> placeholders, {
    required bool isPreSorted,
  }) {
    // Ensure placeholders are in the order they're visible in the source so
    // tabbing through them doesn't appear to jump around.
    if (!isPreSorted) {
      placeholders.sortBy<num>((placeholder) => placeholder.offset);
    }

    // We need to use the same placeholder number for all placeholders in the
    // same linked group, so the first time we see a linked item, store its
    // placeholder number here, so subsequent placeholders for the same linked
    // group can reuse it.
    final placeholderIdForLinkedGroupId = <int, int>{};

    var offset = 0;
    for (final placeholder in placeholders) {
      // Add any text that came before this placeholder to the result.
      appendText(text.substring(offset, placeholder.offset));

      final linkedGroupId = placeholder.linkedGroupId;
      int? thisPaceholderNumber;
      // Override the placeholder number if it's the final one (0) or needs to
      // re-use an existing one for a linked group.
      if (placeholder.isFinal) {
        thisPaceholderNumber = 0;
      } else if (linkedGroupId != null) {
        thisPaceholderNumber = placeholderIdForLinkedGroupId[linkedGroupId];
      }

      // Append the placeholder/choices.
      final placeholderText = text.substring(
        placeholder.offset,
        placeholder.offset + placeholder.length,
      );
      // appendChoice handles mapping empty/single suggestions to a normal
      // placeholder but it's faster if we can avoid putting a single item into
      // a set and then detecting it.
      if (placeholder.suggestions == null) {
        thisPaceholderNumber = appendPlaceholder(
          placeholderText,
          placeholderNumber: thisPaceholderNumber,
        );
      } else {
        final choices = <String>{
          if (placeholderText.isNotEmpty) placeholderText,
          ...?placeholder.suggestions,
        };
        thisPaceholderNumber = appendChoice(
          choices,
          placeholderNumber: thisPaceholderNumber,
        );
      }

      // Track where we're up to.
      offset = placeholder.offset + placeholder.length;

      // Store the placeholder number used for linked groups so it can be reused
      // by subsequent references to it.
      if (linkedGroupId != null) {
        placeholderIdForLinkedGroupId[linkedGroupId] = thisPaceholderNumber;
      }
    }

    // Add any remaining text that was after the last placeholder.
    appendText(text.substring(offset));
  }
}
