// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../lsp/code_actions_mixin.dart';
import 'abstract_lsp_over_legacy.dart';

class AbstractCodeActionsTest extends SharedLspOverLegacyTest
    with CodeActionsTestMixin {
  @override
  Future<void> initializeServer() async {
    await super.initializeServer();

    // Most CodeActions tests set LSP capabilities so automatically send these
    // to the legacy server as part of initialization.
    await sendClientCapabilities();
  }
}
