// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer_plugin/src/utilities/extensions/string_extension.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import 'request_helpers_mixin.dart';

/// Applies LSP [WorkspaceEdit]s to produce a flattened string describing the
/// new file contents and any create/rename/deletes to use in test expectations.
///
/// Expects all file content to use [testEol] and automatically
/// normalizes expectations to use the same. Does not normalize edits, as line
/// ending differences in edits indicate a bug in the edit creation.
class LspChangeVerifier {
  /// Marks that signifies the start of an edit description.
  static final editMarkerStart = '>>>>>>>>>>';

  /// Marks the end of an edit description if the content did not end with a
  /// newline.
  static final editMarkerEnd = '<<<<<<<<<<';

  /// Changes collected while applying the edit.
  final _changes = <Uri, _Change>{};

  /// A mixin with helpers for applying LSP edits.
  final LspVerifyEditHelpersMixin editHelpers;

  /// The [WorkspaceEdit] being applied/verified.
  final WorkspaceEdit edit;

  /// The line terminator to use in the output.
  final String endOfLine = testEol;

  LspChangeVerifier(this.editHelpers, this.edit) {
    _applyEdit();
  }

  void verifyFiles(String expected, {Map<Uri, int>? expectedVersions}) {
    expected = normalizeNewlinesForPlatform(expected);

    var actual = _toChangeString();
    if (actual != expected) {
      print('-' * 64);
      print(actual.trimRight());
      print('-' * 64);
    }
    expect(actual, equals(expected));

    if (expectedVersions != null) {
      _verifyDocumentVersions(expectedVersions);
    }
  }

  void _applyChanges(Map<Uri, List<TextEdit>> changes) {
    changes.forEach((fileUri, edits) {
      var change = _change(fileUri);
      change.content = _applyTextEdits(change.content!, edits);

      // Record annotations with their ranges.
      for (var edit in edits.whereType<AnnotatedTextEdit>()) {
        var annotation = this.edit.changeAnnotations![edit.annotationId]!;
        change.annotations
            .putIfAbsent(annotation, () => [])
            .add(edit.range.toDisplayString());
      }
    });
  }

  void _applyDocumentChanges(DocumentChanges documentChanges) {
    _applyResourceChanges(documentChanges);
  }

  void _applyEdit() {
    var documentChanges = edit.documentChanges;
    var changes = edit.changes;

    if (documentChanges != null) {
      _applyDocumentChanges(documentChanges);
    }
    if (changes != null) {
      _applyChanges(changes);
    }
  }

  void _applyResourceChanges(DocumentChanges changes) {
    for (var change in changes) {
      change.map(
        _applyResourceCreate,
        _applyResourceDelete,
        _applyResourceRename,
        _applyTextDocumentEdit,
      );
    }
  }

  void _applyResourceCreate(CreateFile create) {
    var uri = create.uri;
    var change = _change(uri);
    if (change.content != null) {
      throw 'Received create instruction for $uri which already exists';
    }
    _change(uri).content = '';
    change.actions.add('created');

    if (create.annotationId case String annotationId) {
      var annotation = edit.changeAnnotations![annotationId]!;
      change.annotations.putIfAbsent(annotation, () => []).add('create');
    }
  }

  void _applyResourceDelete(DeleteFile delete) {
    var uri = delete.uri;
    var change = _change(uri);

    if (change.content == null) {
      throw 'Received delete instruction for $uri which does not exist';
    }

    change.content = null;
    change.actions.add('deleted');

    if (delete.annotationId case String annotationId) {
      var annotation = edit.changeAnnotations![annotationId]!;
      change.annotations.putIfAbsent(annotation, () => []).add('delete');
    }
  }

  void _applyResourceRename(RenameFile rename) {
    var oldUri = rename.oldUri;
    var newUri = rename.newUri;
    var oldChange = _change(oldUri);
    var newChange = _change(newUri);

    if (oldChange.content == null) {
      throw 'Received rename instruction from $oldUri which did not exist';
    } else if (newChange.content != null) {
      throw 'Received rename instruction to $newUri which already exists';
    }

    newChange.content = oldChange.content;
    newChange.actions.add('renamed from ${_relativeUri(oldUri)}');
    oldChange.content = null;
    oldChange.actions.add('renamed to ${_relativeUri(newUri)}');

    if (rename.annotationId case String annotationId) {
      var annotation = edit.changeAnnotations![annotationId]!;
      newChange.annotations.putIfAbsent(annotation, () => []).add('rename');
      oldChange.annotations.putIfAbsent(annotation, () => []).add('rename');
    }
  }

  void _applyTextDocumentEdit(TextDocumentEdit documentEdit) {
    var uri = documentEdit.textDocument.uri;
    var change = _change(uri);

    // Compute new content from the edits.
    if (change.content == null) {
      throw 'Received edits for $uri which does not exist. '
          'Perhaps a CreateFile change was missing from the edits?';
    }
    change.content = _applyTextDocumentEditEdit(change.content!, documentEdit);

    // Record annotations with their ranges.
    for (var editEither in documentEdit.edits) {
      editEither.map(
        (annotated) {
          var annotation = edit.changeAnnotations![annotated.annotationId]!;
          change.annotations
              .putIfAbsent(annotation, () => [])
              .add(annotated.range.toDisplayString());
        },
        // No annotations on these other kinds.
        (snippet) {},
        (textEdit) {},
      );
    }
  }

  String _applyTextDocumentEditEdit(String content, TextDocumentEdit edit) {
    // Extract the edits from the union (they all have the same superclass).
    var edits = edit.edits
        .map((edit) => edit.map((e) => e, (e) => e, (e) => e))
        .toList();
    return _applyTextEdits(content, edits);
  }

  String _applyTextEdits(String content, List<TextEdit> changes) =>
      editHelpers.applyTextEdits(content, changes);

  /// Assert that [input] uses the current platforms line endings.
  void _assertLineEnding(String input) {
    var actualLineEnding = input.endOfLine;
    if (actualLineEnding != null) {
      assert(
        actualLineEnding == endOfLine,
        'Expected line ending ${jsonEncode(endOfLine)} '
        'but string uses ${jsonEncode(actualLineEnding)}',
      );
    }
  }

  _Change _change(Uri fileUri) => _changes.putIfAbsent(
    fileUri,
    () => _Change(_getCurrentFileContent(fileUri)),
  );

  void _expectDocumentVersion(
    TextDocumentEdit edit,
    Map<Uri, int> expectedVersions,
  ) {
    var uri = edit.textDocument.uri;
    var expectedVersion = expectedVersions[uri];

    expect(edit.textDocument.version, equals(expectedVersion));
  }

  String? _getCurrentFileContent(Uri uri) {
    var content = editHelpers.getCurrentFileContent(uri);
    if (content != null) {
      _assertLineEnding(content);
    }
    return content;
  }

  String _relativeUri(Uri uri) => editHelpers.relativeUri(uri);

  String _toChangeString() {
    var buffer = StringBuffer();
    for (var MapEntry(key: uri, value: change) in _changes.entries.sortedBy(
      (entry) => _relativeUri(entry.key),
    )) {
      // Write the path in a common format for Windows/non-Windows.
      var relativePath = _relativeUri(uri);
      var content = change.content;
      var annotations = change.annotations;

      // Write header/actions.
      buffer.write('$editMarkerStart $relativePath');
      for (var action in change.actions) {
        buffer.write(' $action');
      }
      if (content?.isEmpty ?? false) {
        buffer.write(' empty');
      }
      buffer.write(endOfLine);

      // Write any annotations.
      if (annotations.isNotEmpty) {
        for (var MapEntry(key: annotation, value: operations)
            in annotations.entries) {
          buffer.write('$editMarkerStart   ${annotation.label}');
          if (annotation.description != null) {
            buffer.write(' (${annotation.description})');
          }
          buffer.write(': ${operations.join(', ')}');
          buffer.write(endOfLine);
        }
      }

      // Write content.
      if (content != null) {
        buffer.write(content);

        // If the content didn't end with a newline we need to add one, but
        // add a marked so it's clear there was no trailing newline.
        if (content.isNotEmpty && !content.endsWith('\n')) {
          buffer.write(editMarkerEnd);
          buffer.write(endOfLine);
        }
      }
    }

    return buffer.toString();
  }

  /// Validates the document versions for a set of edits match the versions in
  /// the supplied map.
  void _verifyDocumentVersions(Map<Uri, int> expectedVersions) {
    // For resource changes, we only need to validate changes since
    // creates/renames/deletes do not supply versions.
    for (var change in edit.documentChanges!) {
      change.map(
        (create) {},
        (delete) {},
        (rename) {},
        (edit) => _expectDocumentVersion(edit, expectedVersions),
      );
    }
  }
}

/// An LSP TextEdit with its index, and comparers to stably sort them by source
/// position (forwards).
class TextEditWithIndex {
  final int index;
  final TextEdit edit;

  TextEditWithIndex(this.index, this.edit);

  TextEditWithIndex.fromUnion(
    this.index,
    Either3<AnnotatedTextEdit, SnippetTextEdit, TextEdit> edit,
  ) : edit = edit.map((e) => e, (e) => e, (e) => e);

  /// Compares two [TextEditWithIndex] to sort them stably in source-order.
  ///
  /// In this order, edits cannot be applied sequentially to a file because
  /// each edit may change the location of future edits. This can be used to
  /// apply them if all locations are computed against the original code using
  /// a [StringBuffer] for better performance than repeatedly applying
  /// sequentially.
  static int compare(TextEditWithIndex edit1, TextEditWithIndex edit2) {
    var end1 = edit1.edit.range.end;
    var end2 = edit2.edit.range.end;

    // VS Code's implementation of this is here:
    // https://github.com/microsoft/vscode/blob/856a306d1a9b0879727421daf21a8059e671e3ea/src/vs/editor/common/model/pieceTreeTextBuffer/pieceTreeTextBuffer.ts#L475

    if (end1.line != end2.line) {
      return end1.line.compareTo(end2.line);
    } else if (end1.character != end2.character) {
      return end1.character.compareTo(end2.character);
    } else {
      return edit1.index.compareTo(edit2.index);
    }
  }
}

class _Change {
  String? content;
  final actions = <String>[];
  final annotations = <ChangeAnnotation, List<String>>{};

  _Change(this.content);
}

extension on Range {
  String toDisplayString() => start.line == end.line
      ? 'line ${start.line + 1}'
      : 'lines ${start.line + 1}-${end.line + 1}';
}
