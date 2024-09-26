// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LspOverLegacyNotificationTest);
  });
}

/// Integration tests for receiving LSP notifications over the Legacy protocol.
///
/// These tests are slow (each test spawns an out-of-process server) so these
/// tests are intended only to ensure the basic functionality is available and
/// not to test all handlers/functionality already covered by LSP tests.
///
/// Additional tests (to verify each expected LSP handler is available over
/// Legacy) are in `test/lsp_over_legacy/` and tests for all handler
/// functionality are in `test/lsp`.
@reflectiveTest
class LspOverLegacyNotificationTest extends AbstractLspOverLegacyTest {
  /// Tells the server we support custom URIs, otherwise we won't be allowed to
  /// fetch any content from a URI.
  Future<void> enableCustomUriSupport() async {
    // Tell the server we will be using URIs.
    await sendServerSetClientCapabilities([], supportsUris: true);
    // Set the encoder for the test class so the JSON we produce maps files to
    // URIs so the test implementations can just work with the internal paths.
    uriConverter = ClientUriConverter.withVirtualFileSupport(pathContext);
  }

  Future<void> test_macroModifiedContentEvent() async {
    addMacros([declareInTypeMacro()]);

    // TODO(dantup): There are existing methods like
    //  `ResourceProviderMixin.newAnalysisOptionsYamlFile` that would be useful
    //  here, but we'd need to split it up to not be specific to
    //  MemoryResourceProvider.
    writeFile(
      pathContext.join(testPackageRootPath, file_paths.analysisOptionsYaml),
      analysisOptionsContent(experiments: ['macros']),
    );
    writeFile(
      pathContext.join(testPackageRootPath, file_paths.pubspecYaml),
      'name: test',
    );

    var content = '''
import 'macros.dart';

@DeclareInType('void foo() {}')
class A {}
''';
    writeFile(testFile, content);

    await enableCustomUriSupport();
    await standardAnalysisSetup();
    await analysisFinished;

    // Modify the file and expect a change event.
    writeFile(testFile, content.replaceAll('void foo() {', 'void foo2() {'));
    await dartTextDocumentContentDidChangeNotifications
        .firstWhere((notification) => notification.uri == testFileMacroUri);
  }
}
