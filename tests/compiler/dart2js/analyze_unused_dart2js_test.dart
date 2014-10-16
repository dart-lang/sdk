// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_unused_dart2js;

import 'package:async_helper/async_helper.dart';

import 'package:compiler/implementation/dart2jslib.dart';
import 'package:compiler/implementation/filenames.dart';

import 'analyze_helper.dart';

// Do not remove WHITE_LIST even if it's empty.  The error message for
// unused members refers to WHITE_LIST by name.
const Map<String, List<String>> WHITE_LIST = const {
  // Helper methods for debugging should never be called from production code:
  "implementation/helpers/": const [" is never "],

  // Node.asLiteralBool is never used.
  "implementation/tree/nodes.dart": const [
      "The method 'asLiteralBool' is never called"],

  // Some things in dart_printer are not yet used
  "implementation/dart_backend/backend_ast_nodes.dart": const [" is never "],

  // dart2js uses only the encoding functions, the decoding functions are used
  // from the generated code.
  "js_lib/shared/runtime_data.dart": const [" is never "],

  // MethodElement
  // TODO(20377): Why is MethodElement unused?
  "implementation/elements/elements.dart": const [" is never "]
};

void main() {
  var uri = currentDirectory.resolve(
      'sdk/lib/_internal/compiler/implementation/use_unused_api.dart');
  asyncTest(() => analyze([uri], WHITE_LIST,
      analyzeAll: false, checkResults: checkResults));
}

bool checkResults(Compiler compiler, CollectingDiagnosticHandler handler) {
  var helperUri = currentDirectory.resolve(
      'sdk/lib/_internal/compiler/implementation/helpers/helpers.dart');
  void checkLive(member) {
    if (member.isFunction) {
      if (compiler.enqueuer.resolution.hasBeenResolved(member)) {
        compiler.reportHint(member, MessageKind.GENERIC,
            {'text': "Helper function in production code '$member'."});
      }
    } else if (member.isClass) {
      if (member.isResolved) {
        compiler.reportHint(member, MessageKind.GENERIC,
            {'text': "Helper class in production code '$member'."});
      } else {
        member.forEachLocalMember(checkLive);
      }
    } else if (member.isTypedef) {
      if (member.isResolved) {
        compiler.reportHint(member, MessageKind.GENERIC,
            {'text': "Helper typedef in production code '$member'."});
      }
    }
  }
  compiler.libraryLoader.lookupLibrary(helperUri).forEachLocalMember(checkLive);
  return handler.checkResults();
}
