// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart' hide expect;

import 'server_abstract.dart';

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

  /// A base test class used to obtain the current content of a file.
  final LspAnalysisServerTestMixin _server;

  /// The [WorkspaceEdit] being applied/verified.
  final WorkspaceEdit edit;

  LspChangeVerifier(this._server, this.edit) {
    _applyEdit();
  }

  void verifyFiles(String expected, {Map<Uri, int>? expectedVersions}) {
    _server.expect(_toChangeString(), equals(expected));
    if (expectedVersions != null) {
      _verifyDocumentVersions(expectedVersions);
    }
  }

  void _applyChanges(Map<Uri, List<TextEdit>> changes) {
    changes.forEach((fileUri, edits) {
      final change = _change(fileUri);
      change.content = _applyTextEdits(change.content!, edits);
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
  }

  void _applyResourceDelete(DeleteFile delete) {
    final uri = delete.uri;
    final change = _change(uri);

    if (change.content == null) {
      throw 'Received delete instruction for $uri which does not exist';
    }

    change.content = null;
    change.actions.add('deleted');
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
  }

  void _applyTextDocumentEdit(TextDocumentEdit edit) {
    final uri = edit.textDocument.uri;
    final change = _change(uri);

    if (change.content == null) {
      throw 'Received edits for $uri which does not exist. '
          'Perhaps a CreateFile change was missing from the edits?';
    }
    change.content = _applyTextDocumentEditEdit(change.content!, edit);
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
    return indexedEdits.map((e) => e.edit).fold(content, _server.applyTextEdit);
  }

  String _applyTextEdits(String content, List<TextEdit> changes) =>
      _server.applyTextEdits(content, changes);

  _Change _change(Uri fileUri) => _changes.putIfAbsent(
      fileUri, () => _Change(_getCurrentFileContent(fileUri)));

  void _expectDocumentVersion(
    TextDocumentEdit edit,
    Map<Uri, int> expectedVersions,
  ) {
    final uri = edit.textDocument.uri;
    final expectedVersion = expectedVersions[uri];

    _server.expect(edit.textDocument.version, equals(expectedVersion));
  }

  String? _getCurrentFileContent(Uri uri) => _server.getCurrentFileContent(uri);

  String _relativeUri(Uri uri) => _server.relativeUri(uri);

  String _toChangeString() {
    final buffer = StringBuffer();
    for (final entry
        in _changes.entries.sortedBy((entry) => _relativeUri(entry.key))) {
      // Write the path in a common format for Windows/non-Windows.
      final relativePath = _relativeUri(entry.key);
      final change = entry.value;
      final content = change.content;

      // Write header/actions.
      buffer.write('$editMarkerStart $relativePath');
      for (final action in change.actions) {
        buffer.write(' $action');
      }
      if (content?.isEmpty ?? false) {
        buffer.write(' empty');
      }
      buffer.writeln();

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

  _Change(this.content);
}
