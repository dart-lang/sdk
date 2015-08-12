// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_unused_dart2js;

import 'package:async_helper/async_helper.dart';

import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/filenames.dart';

import 'analyze_helper.dart';

// Do not remove WHITE_LIST even if it's empty.  The error message for
// unused members refers to WHITE_LIST by name.
const Map<String, List<String>> WHITE_LIST = const {
  // Helper methods for debugging should never be called from production code:
  "lib/src/helpers/": const [" is never "],

  // Node.asLiteralBool is never used.
  "lib/src/tree/nodes.dart": const [
      "The method 'asLiteralBool' is never called"],

  // Some things in dart_printer are not yet used
  "lib/src/dart_backend/backend_ast_nodes.dart": const [" is never "],

  // Uncalled methods in SemanticSendVisitor and subclasses.
  "lib/src/resolution/semantic_visitor.dart": const [
      "The method 'error"],
  "lib/src/resolution/semantic_visitor_mixins.dart": const [
      "The class 'Base", "The method 'error", "The method 'visit"],

  // Uncalled type predicate.  Keep while related predicates are used.
  "lib/src/ssa/nodes.dart": const [
      "The method 'isArray' is never called"],

  // Serialization code is only used in test.
  "lib/src/serialization/": const [
      "is never"],

  // Nested functions are currently kept alive in the IR.
  "lib/src/tree_ir/": const [
    "accept", "FunctionExpression", "CreateFunction"
  ],

  // AllInfo.fromJson and visit methods are not used yet.
  "lib/src/info/info.dart": const [ "is never" ],

  "lib/src/universe/universe.dart": const [
      "The method 'getterInvocationsByName' is never called.",
      "The method 'setterInvocationsByName' is never called."],

  "lib/src/cps_ir/": const [
    "accept", "CreateFunction",
  ],

  "/lib/src/dart_backend/backend_ast_to_frontend_ast.dart": const [
    " is never "
  ],
};

void main() {
  var uri = currentDirectory.resolve(
      'pkg/compiler/lib/src/use_unused_api.dart');
  asyncTest(() => analyze([uri], WHITE_LIST,
      analyzeAll: false, checkResults: checkResults));
}

bool checkResults(Compiler compiler, CollectingDiagnosticHandler handler) {
  var helperUri = currentDirectory.resolve(
      'pkg/compiler/lib/src/helpers/helpers.dart');
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
