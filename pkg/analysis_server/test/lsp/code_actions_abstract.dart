// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';

import 'server_abstract.dart';

abstract class AbstractCodeActionsTest extends AbstractLspAnalysisServerTest {
  initializeWithSupportForKinds(List<CodeActionKind> kinds) async {
    await initialize(textDocumentCapabilities: {
      'codeAction': {
        'codeActionLiteralSupport': {
          'codeActionKind': {
            'valueSet': kinds.map((k) => k.toJson()).toList(),
          },
        },
      },
    });
  }
}
