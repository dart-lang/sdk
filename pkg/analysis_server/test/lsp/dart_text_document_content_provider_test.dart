// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:analyzer_testing/experiments/experiments.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartTextDocumentContentProviderTest);
  });
}

@reflectiveTest
class DartTextDocumentContentProviderTest
    extends AbstractLspAnalysisServerTest {
  @override
  AnalysisServerOptions get serverOptions => AnalysisServerOptions()
    ..enabledExperiments = [
      ...super.serverOptions.enabledExperiments,
      ...experimentsForTests,
    ];

  @override
  void setUp() {
    super.setUp();
    setDartTextDocumentContentProviderSupport();
  }

  Future<void> test_invalid_badScheme() async {
    await initialize();

    await expectLater(
      getDartTextDocumentContent(Uri.parse('abcde:foo/bar.dart')),
      throwsA(
        isResponseError(
          ErrorCodes.InvalidParams,
          message:
              "Fetching content for scheme 'abcde' is not supported. "
              "Supported schemes are '$macroClientUriScheme'.",
        ),
      ),
    );
  }

  Future<void> test_invalid_fileScheme() async {
    await initialize();

    await expectLater(
      getDartTextDocumentContent(mainFileUri),
      throwsA(
        isResponseError(
          ErrorCodes.InvalidParams,
          message:
              "Fetching content for scheme 'file' is not supported. "
              "Supported schemes are '$macroClientUriScheme'.",
        ),
      ),
    );
  }

  Future<void> test_support_notSupported() async {
    setDartTextDocumentContentProviderSupport(false);
    await initialize();
    expect(
      experimentalServerCapabilities['dartTextDocumentContentProvider'],
      isNull,
    );
  }

  Future<void> test_supported_static() async {
    await initialize();
    expect(experimentalServerCapabilities['dartTextDocumentContentProvider'], {
      'schemes': [macroClientUriScheme],
    });
  }
}
