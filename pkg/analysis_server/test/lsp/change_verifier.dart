// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import 'request_helpers_mixin.dart';

/// Applies LSP [WorkspaceEdit]s to produce a flattened string describing the
/// new file contents and any create/rename/deletes to use in test expectations.
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

  LspChangeVerifier(this.editHelpers, this.edit) {
    _applyEdit();
  }

  void verifyFiles(String expected, {Map<Uri, int>? expectedVersions}) {
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
      final change = _change(fileUri);
      change.content = _applyTextEdits(change.content!, edits);

      // Record annotations with their ranges.
      for (final edit in edits.whereType<AnnotatedTextEdit>()) {
        final annotation = this.edit.changeAnnotations![edit.annotationId]!;
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
    final documentChanges = edit.documentChanges;
    final changes = edit.changes;

    if (documentChanges != null) {
      _applyDocumentChanges(documentChanges);
    }
    if (changes != null) {
      _applyChanges(changes);
    }
  }

  void _applyResourceChanges(DocumentChanges changes) {
    for (final change in changes) {
      change.map(
        _applyResourceCreate,
        _applyResourceDelete,
        _applyResourceRename,
        _applyTextDocumentEdit,
      );
    }
  }

  void _applyResourceCreate(CreateFile create) {
    final uri = create.uri;
    final change = _change(uri);
    if (change.content != null) {
      throw 'Received create instruction for $uri which already exists';
    }
    _change(uri).content = '';
    change.actions.add('created');

    if (create.annotationId case String annotationId) {
      final annotation = edit.changeAnnotations![annotationId]!;
      change.annotations.putIfAbsent(annotation, () => []).add('create');
    }
  }

  void _applyResourceDelete(DeleteFile delete) {
    final uri = delete.uri;
    final change = _change(uri);

    if (change.content == null) {
      throw 'Received delete instruction for $uri which does not exist';
    }

    change.content = null;
    change.actions.add('deleted');

    if (delete.annotationId case String annotationId) {
      final annotation = edit.changeAnnotations![annotationId]!;
      change.annotations.putIfAbsent(annotation, () => []).add('delete');
    }
  }

  void _applyResourceRename(RenameFile rename) {
    final oldUri = rename.oldUri;
    final newUri = rename.newUri;
    final oldChange = _change(oldUri);
    final newChange = _change(newUri);

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
      final annotation = edit.changeAnnotations![annotationId]!;
      newChange.annotations.putIfAbsent(annotation, () => []).add('rename');
      oldChange.annotations.putIfAbsent(annotation, () => []).add('rename');
    }
  }

  void _applyTextDocumentEdit(TextDocumentEdit documentEdit) {
    final uri = documentEdit.textDocument.uri;
    final change = _change(uri);

    // Compute new content from the edits.
    if (change.content == null) {
      throw 'Received edits for $uri which does not exist. '
          'Perhaps a CreateFile change was missing from the edits?';
    }
    change.content = _applyTextDocumentEditEdit(change.content!, documentEdit);

    // Record annotations with their ranges.
    for (final editEither in documentEdit.edits) {
      editEither.map(
        (annotated) {
          final annotation = edit.changeAnnotations![annotated.annotationId]!;
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
    // To simulate the behaviour we'll get from an LSP client, apply edits from
    // the latest offset to the earliest, but with items at the same offset
    // being reversed so that when applied sequentially they appear in the
    // document in-order.
    //
    // This is essentially a stable sort over the offset (descending), but since
    // List.sort() is not stable so we additionally sort by index).
    final indexedEdits =
        edit.edits.mapIndexed(TextEditWithIndex.fromUnion).toList();
    indexedEdits.sort(TextEditWithIndex.compare);
    return indexedEdits
        .map((e) => e.edit)
        .fold(content, editHelpers.applyTextEdit);
  }

  String _applyTextEdits(String content, List<TextEdit> changes) =>
      editHelpers.applyTextEdits(content, changes);

  _Change _change(Uri fileUri) => _changes.putIfAbsent(
      fileUri, () => _Change(_getCurrentFileContent(fileUri)));

  void _expectDocumentVersion(
    TextDocumentEdit edit,
    Map<Uri, int> expectedVersions,
  ) {
    final uri = edit.textDocument.uri;
    final expectedVersion = expectedVersions[uri];

    expect(edit.textDocument.version, equals(expectedVersion));
  }

  String? _getCurrentFileContent(Uri uri) =>
      editHelpers.getCurrentFileContent(uri);

  String _relativeUri(Uri uri) => editHelpers.relativeUri(uri);

  String _toChangeString() {
    final buffer = StringBuffer();
    for (final MapEntry(key: uri, value: change)
        in _changes.entries.sortedBy((entry) => _relativeUri(entry.key))) {
      // Write the path in a common format for Windows/non-Windows.
      final relativePath = _relativeUri(uri);
      final content = change.content;
      final annotations = change.annotations;

      // Write header/actions.
      buffer.write('$editMarkerStart $relativePath');
      for (final action in change.actions) {
        buffer.write(' $action');
      }
      if (content?.isEmpty ?? false) {
        buffer.write(' empty');
      }
      buffer.writeln();

      // Write any annotations.
      if (annotations.isNotEmpty) {
        for (final MapEntry(key: annotation, value: operations)
            in annotations.entries) {
          buffer.write('$editMarkerStart   ${annotation.label}');
          if (annotation.description != null) {
            buffer.write(' (${annotation.description})');
          }
          buffer.write(': ${operations.join(', ')}');
          buffer.writeln();
        }
      }

      // Write content.
      if (content != null) {
        buffer.write(content);

        // If the content didn't end with a newline we need to add one, but
        // add a marked so it's clear there was no trailing newline.
        if (content.isNotEmpty && !content.endsWith('\n')) {
          buffer.writeln(editMarkerEnd);
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

/// An LSP TextEdit with its index, and a comparer to sort them in a way that
/// can be applied sequentially while preserving expected behaviour.
class TextEditWithIndex {
  final int index;
  final TextEdit edit;

  TextEditWithIndex(this.index, this.edit);

  TextEditWithIndex.fromUnion(
      this.index, Either3<AnnotatedTextEdit, SnippetTextEdit, TextEdit> edit)
      : edit = edit.map((e) => e, (e) => e, (e) => e);

  /// Compares two [TextEditWithIndex] to sort them by the order in which they
  /// can be sequentially applied to a String to match the behaviour of an LSP
  /// client.
  static int compare(TextEditWithIndex edit1, TextEditWithIndex edit2) {
    final end1 = edit1.edit.range.end;
    final end2 = edit2.edit.range.end;

    // VS Code's implementation of this is here:
    // https://github.com/microsoft/vscode/blob/856a306d1a9b0879727421daf21a8059e671e3ea/src/vs/editor/common/model/pieceTreeTextBuffer/pieceTreeTextBuffer.ts#L475

    if (end1.line != end2.line) {
      return end1.line.compareTo(end2.line) * -1;
    } else if (end1.character != end2.character) {
      return end1.character.compareTo(end2.character) * -1;
    } else {
      return edit1.index.compareTo(edit2.index) * -1;
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
