// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

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
  Future<void> test_completionItemKind_firstNotSupported() async {
    // TYPE_PARAMETER maps to TypeParameter first, but since originally LSP
    // did not support it, it'll map to Variable if the client doesn't support
    // that.
    var supportedKinds = HashSet.of([
      lsp.CompletionItemKind.TypeParameter,
      lsp.CompletionItemKind.Variable,
    ]);
    var result = lsp.elementKindToCompletionItemKind(
      supportedKinds,
      server.ElementKind.TYPE_PARAMETER,
    );
    expect(result, equals(lsp.CompletionItemKind.TypeParameter));
  }

  Future<void> test_completionItemKind_firstSupported() async {
    // TYPE_PARAMETER maps to TypeParameter first, but since originally LSP
    // did not support it, it'll map to Variable if the client doesn't support
    // that.
    var supportedKinds = HashSet.of([lsp.CompletionItemKind.Variable]);
    var result = lsp.elementKindToCompletionItemKind(
      supportedKinds,
      server.ElementKind.TYPE_PARAMETER,
    );
    expect(result, equals(lsp.CompletionItemKind.Variable));
  }

  Future<void> test_completionItemKind_knownMapping() async {
    final supportedKinds = HashSet.of([lsp.CompletionItemKind.Class]);
    final result = lsp.elementKindToCompletionItemKind(
      supportedKinds,
      server.ElementKind.CLASS,
    );
    expect(result, equals(lsp.CompletionItemKind.Class));
  }

  Future<void> test_completionItemKind_notMapped() async {
    var supportedKinds = HashSet<lsp.CompletionItemKind>();
    var result = lsp.elementKindToCompletionItemKind(
      supportedKinds,
      server.ElementKind.UNKNOWN, // Unknown is not mapped.
    );
    expect(result, isNull);
  }

  Future<void> test_completionItemKind_notSupported() async {
    var supportedKinds = HashSet<lsp.CompletionItemKind>();
    var result = lsp.elementKindToCompletionItemKind(
      supportedKinds,
      server.ElementKind.CLASS,
    );
    expect(result, isNull);
  }

  Future<void> test_selectionsInSnippets_empty() async {
    var result = lsp.buildSnippetStringWithSelection('teststring', 4, 0);
    expect(result, equals(r'test${1:}string'));
  }

  Future<void> test_selectionsInSnippets_escaping() async {
    var result = lsp.buildSnippetStringWithSelection(r'te$tstri}ng', 4, 3);
    expect(result, equals(r'te\$t${1:str}i\}ng'));
  }

  Future<void> test_selectionsInSnippets_selection() async {
    var result = lsp.buildSnippetStringWithSelection('teststring', 4, 3);
    expect(result, equals(r'test${1:str}ing'));
  }
}
