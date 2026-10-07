// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:language_server_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetClientCapabilitiesTest);
  });
}

@reflectiveTest
class SetClientCapabilitiesTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_lspCapabilities_semanticTokensLegend() async {
    var response = await sendServerSetClientCapabilities(
      [],
      lspCapabilities: ClientCapabilities(),
    );

    expect(response.lspCapabilities, isNotNull);
    var serverCapabilities = ServerCapabilities.fromJson(
      response.lspCapabilities as Map<String, Object?>,
    );
    var tokens = serverCapabilities.semanticTokensProvider?.map(
      (options) => options,
      (registrationOptions) => throw 'Expected simple options',
    );

    // Spot check a few values.
    expect(tokens!.legend.tokenTypes, containsAll(['class', 'comment']));
    expect(
      tokens.legend.tokenModifiers,
      containsAll(['documentation', 'instance', 'wildcard']),
    );

    // Ensure no dupes.
    expect(
      tokens.legend.tokenTypes,
      hasLength(tokens.legend.tokenTypes.toSet().length),
    );
    expect(
      tokens.legend.tokenModifiers,
      hasLength(tokens.legend.tokenModifiers.toSet().length),
    );
  }

  Future<void> test_noLspCapabilities() async {
    var response = await sendServerSetClientCapabilities([]);
    expect(response.lspCapabilities, isNull);
  }
}
