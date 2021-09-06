// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';

import 'server_abstract.dart';

mixin CompletionTestMixin on AbstractLspAnalysisServerTest {
  /// The last set of completion results fetched.
  List<CompletionItem> completionResults = [];

  int sortTextSorter(CompletionItem item1, CompletionItem item2) =>
      (item1.sortText ?? item1.label).compareTo(item2.sortText ?? item2.label);

  Future<String?> verifyCompletions(
    Uri fileUri,
    String content, {
    required List<String> expectCompletions,
    String? applyEditsFor,
    bool resolve = false,
    String? expectedContent,
    String? expectedContentIfInserting,
    bool verifyInsertReplaceRanges = false,
    bool openCloseFile = true,
  }) async {
    // If verifyInsertReplaceRanges is true, we need both expected contents.
    assert(verifyInsertReplaceRanges == false ||
        (expectedContent != null && expectedContentIfInserting != null));

    if (!initialized) {
      var textDocCapabilities =
          withCompletionItemSnippetSupport(emptyTextDocumentClientCapabilities);

      if (verifyInsertReplaceRanges) {
        textDocCapabilities =
            withCompletionItemInsertReplaceSupport(textDocCapabilities);
      }
      await initialize(textDocumentCapabilities: textDocCapabilities);
    }

    if (openCloseFile) {
      await openFile(fileUri, withoutMarkers(content));
    }
    completionResults =
        await getCompletion(fileUri, positionFromMarker(content));
    if (openCloseFile) {
      await closeFile(fileUri);
    }

    // Sort the completions by sortText and filter to those we expect, so the ordering
    // can be compared.
    final sortedResults = completionResults
        .where((r) => expectCompletions.contains(r.label))
        .toList()
      ..sort(sortTextSorter);

    expect(sortedResults.map((item) => item.label), equals(expectCompletions));

    // Check the edits apply correctly.
    if (applyEditsFor != null) {
      var item = completionResults.singleWhere((c) => c.label == applyEditsFor);
      final insertFormat = item.insertTextFormat;

      if (resolve) {
        item = await resolveCompletion(item);
      }

      String updatedContent;
      if (verifyInsertReplaceRanges &&
          expectedContent != expectedContentIfInserting) {
        // Replacing.
        updatedContent = applyTextEdits(
          withoutMarkers(content),
          [textEditForReplace(item.textEdit!)],
        );
        expect(
            withCaret(updatedContent, insertFormat), equals(expectedContent));

        // Inserting.
        final inserted = applyTextEdits(
          withoutMarkers(content),
          [textEditForInsert(item.textEdit!)],
        );
        expect(withCaret(inserted, insertFormat),
            equals(expectedContentIfInserting));
      } else {
        updatedContent = applyTextEdits(
          withoutMarkers(content),
          [toTextEdit(item.textEdit!)],
        );
        if (expectedContent != null) {
          expect(
              withCaret(updatedContent, insertFormat), equals(expectedContent));
        }
      }
      return updatedContent;
    }

    return null;
  }

  /// Replaces the LSP snippet placeholder '${0:}' with '^' for easier verifying
  /// of the cursor position in completions.
  String withCaret(String contents, InsertTextFormat? format) =>
      format == InsertTextFormat.Snippet
          ? contents.replaceFirst(r'${0:}', '^')
          : contents;
}
