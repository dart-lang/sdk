// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../test/lsp/request_helpers_mixin.dart';
import 'integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializationTest);
    defineReflectiveTests(StringIdInitializationTest);
  });
}

@reflectiveTest
class InitializationTest extends AbstractLspAnalysisServerIntegrationTest {
  Future<void> test_initialize() async {
    var response = await initialize();
    expect(
      InitializeResult.canParse(response.result, nullLspJsonReporter),
      isTrue,
    );
    var result = InitializeResult.fromJson(
      response.result as Map<String, Object?>,
    );
    // Check we have some expected fields.
    expect(result.capabilities.textDocumentSync, isNotNull);
    expect(result.capabilities.codeActionProvider, isNotNull);
  }

  Future<void> test_initialize_invalidParams() async {
    var params = {'processId': 'invalid'};
    var request = RequestMessage(
      id: Either2<int, String>.t1(1),
      method: Method.initialize,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    var response = await sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.error!.code, equals(ErrorCodes.InvalidParams));
    expect(response.result, isNull);
  }
}

/// Runs all initialization tests using String IDs instead of integers (both
/// are valid).
@reflectiveTest
class StringIdInitializationTest extends InitializationTest {
  @override
  LspMessageIdMode get idMode => LspMessageIdMode.string;
}
