// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:test/test.dart';

import '../mocks.dart';

main() {
  // TODO(dantup): Change this to use ReflectiveTests with an LSP base class.
  // TODO(dantup): Create a real integration test that includes sending/verifying
  // the Content-Length headers, since using the mock server channel doesn't
  // test any of that.
  LspAnalysisServer server;
  MockLspServerChannel serverChannel;

  setUp(() {
    serverChannel = new MockLspServerChannel();
    var resourceProvider = new MemoryResourceProvider();
    server = new LspAnalysisServer(
      serverChannel,
      resourceProvider,
    );
  });

  tearDown(() {
    server.shutdown();
  });

  group('LSP Analysis Server', () {
    test('handles initialize', () async {
      final capabilities = new ClientCapabilities(null, null, null);
      final params =
          new InitializeParams(null, null, null, null, capabilities, null);
      final request = new RequestMessage(new Either2<num, String>.t1(1),
          "initialize", new Either2<List<dynamic>, dynamic>.t2(params), "2.0");

      // TODO(dantup): Constructing unions is ugly...
      final response = await serverChannel.sendRequest(RequestMessage.fromJson(
        jsonDecode(jsonEncode(request)),
      ));

      expect(response, const TypeMatcher<ResponseMessage>());
      expect(response.error?.message, isNull);
      final result = response.result as InitializeResult;
      expect(result.capabilities.hoverProvider, true);
    });
  });
}
