// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/lsp/client_capabilities.dart' as lsp;
import 'package:analysis_server/src/lsp/mapping.dart' as lsp;
import 'package:analysis_server/src/lsp/source_edits.dart' as server;
import 'package:analysis_server/src/protocol_server.dart' as server;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as server;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MappingTest);
    defineReflectiveTests(SourceEditMappingTest);
  });
}

@reflectiveTest
class MappingTest extends AbstractLspAnalysisServerTest {
  void test_completionItemKind_enum() {
    // Enums should always map to Enums, never EumMember.
    verifyCompletionItemKind(
      kind: server.ElementKind.ENUM,
      supportedKinds: {
        lsp.CompletionItemKind.Enum,
        lsp.CompletionItemKind.EnumMember,
      },
      expectedKind: lsp.CompletionItemKind.Enum,
    );
  }

  void test_completionItemKind_enumValueNotSupported() {
    // ENUM_CONSTANT maps to EnumMember first, but since originally LSP
    // did not support it, it'll map to Enum if the client doesn't support
    // that.
    verifyCompletionItemKind(
      kind: server.ElementKind.ENUM_CONSTANT,
      supportedKinds: {lsp.CompletionItemKind.Enum},
      expectedKind: lsp.CompletionItemKind.Enum,
    );
  }

  void test_completionItemKind_enumValueSupported() {
    verifyCompletionItemKind(
      kind: server.ElementKind.ENUM_CONSTANT,
      supportedKinds: {
        lsp.CompletionItemKind.Enum,
        lsp.CompletionItemKind.EnumMember,
      },
      expectedKind: lsp.CompletionItemKind.EnumMember,
    );
  }

  Future<void> test_completionItemKind_knownMapping() async {
    var supportedKinds = {lsp.CompletionItemKind.Class};
    var result = lsp.elementKindToCompletionItemKind(
      supportedKinds,
      server.ElementKind.CLASS,
    );
    expect(result, equals(lsp.CompletionItemKind.Class));
  }

  Future<void> test_completionItemKind_notMapped() async {
    var supportedKinds = <lsp.CompletionItemKind>{};
    var result = lsp.elementKindToCompletionItemKind(
      supportedKinds,
      server.ElementKind.UNKNOWN, // Unknown is not mapped.
    );
    expect(result, isNull);
  }

  Future<void> test_completionItemKind_notSupported() async {
    var supportedKinds = <lsp.CompletionItemKind>{};
    var result = lsp.elementKindToCompletionItemKind(
      supportedKinds,
      server.ElementKind.CLASS,
    );
    expect(result, isNull);
  }

  void test_completionItemKind_typeParamNotSupported() {
    // TYPE_PARAMETER maps to TypeParameter first, but since originally LSP
    // did not support it, it'll map to Variable if the client doesn't support
    // that.
    verifyCompletionItemKind(
      kind: server.ElementKind.TYPE_PARAMETER,
      supportedKinds: {lsp.CompletionItemKind.Variable},
      expectedKind: lsp.CompletionItemKind.Variable,
    );
  }

  void test_completionItemKind_typeParamSupported() {
    verifyCompletionItemKind(
      kind: server.ElementKind.TYPE_PARAMETER,
      supportedKinds: {
        lsp.CompletionItemKind.TypeParameter,
        lsp.CompletionItemKind.Variable,
      },
      expectedKind: lsp.CompletionItemKind.TypeParameter,
    );
  }

  void test_relevanceToSortText() {
    // The expected order is the same as from the highest relevance.
    var expectedOrder =
        [999999, 1000, 100, 1, 0].map(lsp.relevanceToSortText).toList();

    // Test with inputs in both directions to ensure the results are actually
    // unique and sorted.
    var results1 =
        [999999, 1000, 100, 1, 0].map(lsp.relevanceToSortText).toList()..sort();
    var results2 =
        [0, 1, 100, 1000, 999999].map(lsp.relevanceToSortText).toList()..sort();

    expect(results1, equals(expectedOrder));
    expect(results2, equals(expectedOrder));
  }

  /// Verifies that [kind] maps to [expectedKind] when the client supports
  /// [supportedKinds].
  void verifyCompletionItemKind({
    required server.ElementKind kind,
    required Set<lsp.CompletionItemKind> supportedKinds,
    required lsp.CompletionItemKind expectedKind,
  }) {
    var result = lsp.elementKindToCompletionItemKind(supportedKinds, kind);
    expect(result, equals(expectedKind));
  }
}

@reflectiveTest
class SourceEditMappingTest extends AbstractLspAnalysisServerTest {
  /// A simple edit that inserts 'FIRSTSECOND' into a document.
  late server.FileEditInformation simpleFirstSecondEdit;

  @override
  void setUp() {
    super.setUp();

    simpleFirstSecondEdit = server.FileEditInformation(
      lsp.OptionalVersionedTextDocumentIdentifier(uri: mainFileUri),
      LineInfo.fromContent(''),
      [
        // Server works with edits that can be applied sequentially to a
        // [String]. This means inserts at the same offset are in the reverse
        // order.
        server.SourceEdit(0, 0, 'SECOND'),
        server.SourceEdit(0, 0, 'FIRST'),
      ],
      newFile: false,
    );
  }

  void test_toTextDocumentEdit_multipleInsertsSameOffset() {
    var edit = lsp.toTextDocumentEdit(
      lsp.LspClientCapabilities(lsp.ClientCapabilities()),
      simpleFirstSecondEdit,
    );

    /// For LSP, offsets relate to the original document and inserts with the
    /// same offset appear in the order they will appear in the final document.
    var edit0 = _unwrapEdit(edit.edits[0]);
    var edit1 = _unwrapEdit(edit.edits[1]);
    expect(edit0.newText, 'FIRST');
    expect(edit1.newText, 'SECOND');
  }

  void test_toWorkspaceEditChanges_multipleInsertsSameOffset() {
    var changes = lsp.toWorkspaceEditChanges([simpleFirstSecondEdit]);
    var edit = changes[mainFileUri]!;

    /// For LSP, offsets relate to the original document and inserts with the
    /// same offset appear in the order they will appear in the final document.
    expect(edit[0].newText, 'FIRST');
    expect(edit[1].newText, 'SECOND');
  }

  lsp.TextEdit _unwrapEdit(
    lsp.Either3<lsp.AnnotatedTextEdit, lsp.SnippetTextEdit, lsp.TextEdit> edit,
  ) {
    // All types extend from TextEdit.
    return edit.map((e) => e, (e) => e, (e) => e);
  }
}
