// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/constants.dart';

import '../lsp/code_actions_mixin.dart';
import 'abstract_lsp_over_legacy.dart';

class AbstractCodeActionsTest extends SharedLspOverLegacyTest
    with CodeActionsTestMixin {
  @override
  bool get serverSupportsFixAll =>
      // Legacy doesn't currently support the fix all command, but read it
      // directly from the handler so if it changes in future the test starts
      // running (and fails, prompting updating).
      server.executeCommandHandler!.commandHandlers[Commands.fixAll] != null;

  @override
  Future<void> initializeServer() async {
    await super.initializeServer();
    await server.lspInitialized;

    // Most CodeActions tests set LSP capabilities so automatically send these
    // to the legacy server as part of initialization.
    await sendClientCapabilities();
  }
}
