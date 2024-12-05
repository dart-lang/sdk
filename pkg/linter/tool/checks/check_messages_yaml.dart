// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages_info.dart';

void main() {
  checkMessagesYaml();
}

/// Checks the `pkg/linter/messages.yaml` file for correctness.
///
/// Throws an error if there's any formatting or content issues.
void checkMessagesYaml() {
  var parsedLintRuleDocs = messagesRuleInfo;
  if (parsedLintRuleDocs.isEmpty) {
    throw StateError("The 'pkg/linter/messages.yaml' file was parsed "
        'as including no lint rule entries.');
  }
}
