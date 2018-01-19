// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_unused_dart2js;

import 'package:async_helper/async_helper.dart';

import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/elements/elements.dart' show LibraryElement;
import 'package:compiler/src/filenames.dart';

import 'analyze_helper.dart';

// Do not remove WHITE_LIST even if it's empty.  The error message for
// unused members refers to WHITE_LIST by name.
const Map<String, List<String>> WHITE_LIST = const {
  // TODO(johnniwinther): uncomment when [Compiler.reportUnusedCode] is
  // reenabled.
  // // Helper methods for debugging should never be called from production code:
  // "lib/src/helpers/": const [" is never "],

  // // Node.asAssert, Node.asLiteralBool is never used.
  // "lib/src/tree/nodes.dart": const [
  //   "The method 'asAssert' is never called.",
  //   "The method 'asLiteralBool' is never called."
  // ],

  // // Uncalled methods in SemanticSendVisitor and subclasses.
  // "lib/src/resolution/semantic_visitor.dart": const ["The method 'error"],
  // "lib/src/resolution/semantic_visitor_mixins.dart": const [
  //   "The class 'SuperBulkMixin'",
  //   "The class 'Base",
  //   "The method 'error",
  //   "The method 'visit"
  // ],

  // // Uncalled type predicate.  Keep while related predicates are used.
  // "lib/src/ssa/nodes.dart": const ["The method 'isArray' is never called"],

  // // Serialization code is only used in test.
  // "lib/src/serialization/": const ["is never"],

  // "lib/src/universe/world_builder.dart": const [
  //   "The method 'getterInvocationsByName' is never called.",
  //   "The method 'setterInvocationsByName' is never called."
  // ],

  "pkg/front_end/lib/src/fasta/kernel/kernel_library_builder.dart": const [
    "The getter 'iterator' is not defined for the class 'Object'.",
  ],

  "pkg/front_end/lib/src/fasta/type_inference/type_schema.dart": const [
    "The class 'UnknownType' overrides 'operator==', but not 'get hashCode'."
  ],

  "pkg/kernel/lib/transformations/closure/": const [
    "Duplicated library name 'kernel.transformations.closure.converter'",
  ],
  "pkg/front_end/lib/src/fasta/kernel/kernel_shadow_ast.dart": const [
    "Library 'dart:core' doesn't export a 'MapEntry' declaration.",
  ],
  "pkg/front_end/lib/src/fasta/kernel/body_builder.dart": const [
    "Library 'dart:core' doesn't export a 'MapEntry' declaration.",
  ],
  "pkg/kernel/lib/visitor.dart": const [
    "Library 'dart:core' doesn't export a 'MapEntry' declaration.",
  ],
  "pkg/kernel/lib/text/ast_to_text.dart": const [
    "Library 'dart:core' doesn't export a 'MapEntry' declaration.",
  ],
  "pkg/kernel/lib/target/vm.dart": const [
    "Library 'dart:core' doesn't export a 'MapEntry' declaration.",
  ],
  "pkg/kernel/lib/clone.dart": const [
    "Library 'dart:core' doesn't export a 'MapEntry' declaration.",
  ],
  "pkg/kernel/lib/binary/ast_to_binary.dart": const [
    "Library 'dart:core' doesn't export a 'MapEntry' declaration.",
  ],
  "pkg/kernel/lib/binary/ast_from_binary.dart": const [
    "Library 'dart:core' doesn't export a 'MapEntry' declaration.",
  ],
};

void main() {
  var uri =
      currentDirectory.resolve('pkg/compiler/lib/src/use_unused_api.dart');
  asyncTest(() => analyze([uri], WHITE_LIST,
      mode: AnalysisMode.TREE_SHAKING, checkResults: checkResults));
}

bool checkResults(Compiler compiler, CollectingDiagnosticHandler handler) {
  var helperUri =
      currentDirectory.resolve('pkg/compiler/lib/src/helpers/helpers.dart');
  void checkLive(member) {
    if (member.isFunction) {
      if (compiler.resolutionWorldBuilder.isMemberUsed(member)) {
        compiler.reporter.reportHintMessage(member, MessageKind.GENERIC,
            {'text': "Helper function in production code '$member'."});
      }
    } else if (member.isClass) {
      if (member.isResolved) {
        compiler.reporter.reportHintMessage(member, MessageKind.GENERIC,
            {'text': "Helper class in production code '$member'."});
      } else {
        member.forEachLocalMember(checkLive);
      }
    } else if (member.isTypedef) {
      if (member.isResolved) {
        compiler.reporter.reportHintMessage(member, MessageKind.GENERIC,
            {'text': "Helper typedef in production code '$member'."});
      }
    }
  }

  (compiler.libraryLoader.lookupLibrary(helperUri) as LibraryElement)
      .forEachLocalMember(checkLive);
  return handler.checkResults();
}
