// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/protocol_server.dart';

import '../analysis_server_base.dart';

abstract class LspOverLegacyTest extends PubPackageAnalysisServerTest {
  var _requestId = 0;

  TextDocumentIdentifier get testFileIdentifier => TextDocumentIdentifier(
      uri:
          server.resourceProvider.pathContext.toUri(convertPath(testFilePath)));

  Request createRequest(Method method, ToJsonable params) {
    return Request('${_requestId++}', method.toString(),
        params.toJson() as Map<String, Object?>);
  }

  Future<T> sendRequest<T>(
      Request request, T Function(Map<String, Object?>) fromJson) async {
    final response = await handleSuccessfulRequest(request);

    // Round-trip via JSON because this doesn't happen automatically when
    // we're bypassing the streams (running in-process) and we want to ensure
    // everything is valid.
    final jsonResult = jsonDecode(jsonEncode(response.result));
    return fromJson(jsonResult as Map<String, Object?>);
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }
}
