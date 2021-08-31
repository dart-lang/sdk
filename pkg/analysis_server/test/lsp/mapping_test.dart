// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart' as lsp;
import 'package:analysis_server/src/lsp/mapping.dart' as lsp;
import 'package:analysis_server/src/protocol_server.dart' as server;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MappingTest);
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
    final supportedKinds = {lsp.CompletionItemKind.Class};
    final result = lsp.elementKindToCompletionItemKind(
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
    final expectedOrder =
        [999999, 1000, 100, 1, 0].map(lsp.relevanceToSortText).toList();

    // Test with inputs in both directions to ensure the results are actually
    // unique and sorted.
    final results1 =
        [999999, 1000, 100, 1, 0].map(lsp.relevanceToSortText).toList()..sort();
    final results2 =
        [0, 1, 100, 1000, 999999].map(lsp.relevanceToSortText).toList()..sort();

    expect(results1, equals(expectedOrder));
    expect(results2, equals(expectedOrder));
  }

  Future<void> test_tabStopsInSnippets_contains() async {
    var result = lsp.buildSnippetStringWithTabStops('a, b, c', [3, 1]);
    expect(result, equals(r'a, ${0:b}, c'));
  }

  Future<void> test_tabStopsInSnippets_empty() async {
    var result = lsp.buildSnippetStringWithTabStops('a, b', []);
    expect(result, equals(r'a, b'));
  }

  Future<void> test_tabStopsInSnippets_endsWith() async {
    var result = lsp.buildSnippetStringWithTabStops('a, b', [3, 1]);
    expect(result, equals(r'a, ${0:b}'));
  }

  Future<void> test_tabStopsInSnippets_escape() async {
    var result = lsp.buildSnippetStringWithTabStops(
        r'te$tstri}ng, te$tstri}ng, te$tstri}ng', [13, 11]);
    expect(result, equals(r'te\$tstri\}ng, ${0:te\$tstri\}ng}, te\$tstri\}ng'));
  }

  Future<void> test_tabStopsInSnippets_multiple() async {
    var result =
        lsp.buildSnippetStringWithTabStops('a, b, c', [0, 1, 3, 1, 6, 1]);
    expect(result, equals(r'${1:a}, ${2:b}, ${3:c}'));
  }

  Future<void> test_tabStopsInSnippets_startsWith() async {
    var result = lsp.buildSnippetStringWithTabStops('a, b', [0, 1]);
    expect(result, equals(r'${0:a}, b'));
  }

  /// Verifies that [kind] maps to [expectedKind] when the client supports
  /// [supportedKinds].
  void verifyCompletionItemKind({
    required server.ElementKind kind,
    required Set<lsp.CompletionItemKind> supportedKinds,
    required lsp.CompletionItemKind expectedKind,
  }) {
    final result = lsp.elementKindToCompletionItemKind(supportedKinds, kind);
    expect(result, equals(expectedKind));
  }
}
