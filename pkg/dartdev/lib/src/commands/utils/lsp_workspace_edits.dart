// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/protocol.dart' show SourceEdit;
import 'package:analyzer/source/line_info.dart';
import 'package:language_server_protocol/protocol_generated.dart' as lsp;
import 'package:language_server_protocol/protocol_special.dart';
import 'package:path/path.dart' as path;

import '../../core.dart';
import '../../utils.dart';

/// Applies the changes defined in a [lsp.WorkspaceEdit] using the provided
/// functions for reading and writing files.
void applyWorkspaceEdit(
  lsp.WorkspaceEdit workspaceEdit,
  String? Function(String filePath) readFile,
  void Function(String filePath, String content) writeFile,
) {
  void applyEdits(Uri uri, List<lsp.TextEdit> edits) {
    final filePath = path.fromUri(uri);
    final content = readFile(filePath);
    if (content == null) {
      log.stderr(
        "Warning: File doesn't exist for migration edit: $filePath",
      );
      return;
    }

    final lineInfo = LineInfo.fromContent(content);
    final sourceEdits = <SourceEdit>[];

    for (final edit in edits) {
      final startOffset = lineInfo.offsetOfPosition(edit.range.start);
      final endOffset = lineInfo.offsetOfPosition(edit.range.end);
      if (startOffset < 0 || endOffset < startOffset) {
        log.stderr('Warning: Invalid edit range in $filePath');
        continue;
      }

      sourceEdits.add(
        SourceEdit(startOffset, endOffset - startOffset, edit.newText),
      );
    }

    // SourceEdit.applySequence applies edits from the back of the list to the
    // front, so edits must be sorted in descending order by offset to avoid
    // shifting character offsets for subsequent edits.
    sourceEdits.sort((a, b) => b.offset.compareTo(a.offset));
    final updatedContent = SourceEdit.applySequence(content, sourceEdits);
    writeFile(filePath, updatedContent);
  }

  // LSP WorkspaceEdits can encode changes in two ways:
  // 1. A simple map of URIs to lists of TextEdits (`changes`).
  // 2. A list of resource operations and versioned document edits
  // (`documentChanges`).
  // We check and handle both representations.
  if (workspaceEdit.changes case final changes?) {
    changes.forEach(applyEdits);
  }
  if (workspaceEdit.documentChanges case final documentChanges?) {
    for (final change in documentChanges) {
      if (change.textDocumentEdit case final docEdit?) {
        applyEdits(docEdit.textDocument.uri, docEdit.plainTextEdits);
      }
    }
  }
}

extension on lsp.TextDocumentEdit {
  /// Converts all edits in this document edit (including snippet edits) into
  /// a uniform list of plain [lsp.TextEdit]s.
  List<lsp.TextEdit> get plainTextEdits {
    return edits
        .map(
          (e) => e.map(
            (a) => a,
            (l) => l,
            (s) => lsp.TextEdit(range: s.range, newText: s.snippet.value),
            (t) => t,
          ),
        )
        .toList();
  }
}

extension
    on
        Either4<
          lsp.CreateFile,
          lsp.DeleteFile,
          lsp.RenameFile,
          lsp.TextDocumentEdit
        > {
  /// Extracts the [lsp.TextDocumentEdit] from this union, or returns `null` if
  /// this is a resource operation ([lsp.CreateFile], [lsp.DeleteFile], or
  /// [lsp.RenameFile]).
  lsp.TextDocumentEdit? get textDocumentEdit {
    return map((_) => null, (_) => null, (_) => null, (docEdit) => docEdit);
  }
}

extension WorkspaceEditExtension on lsp.WorkspaceEdit? {
  /// Returns `true` if [edit] contains any proposed file or document changes.
  bool get hasEdits {
    var edit = this;
    if (edit == null) return false;
    if (edit.changes case final changes?) {
      if (changes.values.any((list) => list.isNotEmpty)) return true;
    }
    if (edit.documentChanges case final documentChanges?) {
      return documentChanges.any((change) {
        if (change.textDocumentEdit case final docEdit?) {
          return docEdit.edits.isNotEmpty;
        }
        return true;
      });
    }
    return false;
  }
}
