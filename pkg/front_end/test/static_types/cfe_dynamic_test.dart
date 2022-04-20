// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/testing/analysis_helper.dart';
import 'verifying_analysis.dart';

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart';
import 'package:kernel/ast.dart';

Future<void> main(List<String> args) async {
  await run(
      cfeOnlyEntryPoints, 'pkg/front_end/test/static_types/cfe_allowed.json',
      analyzedUrisFilter: cfeOnly,
      verbose: args.contains('-v'),
      generate: args.contains('-g'));
}

Future<void> run(List<Uri> entryPoints, String allowedListPath,
    {bool verbose = false,
    bool generate = false,
    bool Function(Uri uri)? analyzedUrisFilter}) async {
  await runAnalysis(entryPoints,
      (DiagnosticMessageHandler onDiagnostic, Component component) {
    new DynamicVisitor(
            onDiagnostic, component, allowedListPath, analyzedUrisFilter)
        .run(verbose: verbose, generate: generate);
  });
}

class DynamicVisitor extends VerifyingAnalysis {
  // TODO(johnniwinther): Enable this when it is less noisy.
  static const bool checkReturnTypes = false;

  DynamicVisitor(DiagnosticMessageHandler onDiagnostic, Component component,
      String? allowedListPath, UriFilter? analyzedUrisFilter)
      : super(onDiagnostic, component, allowedListPath, analyzedUrisFilter);

  @override
  void visitDynamicGet(DynamicGet node) {
    registerError(node, "Dynamic access of '${node.name}'.");
    super.visitDynamicGet(node);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    registerError(node, "Dynamic update to '${node.name}'.");
    super.visitDynamicSet(node);
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    registerError(node, "Dynamic invocation of '${node.name}'.");
    super.visitDynamicInvocation(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (checkReturnTypes && node.function.returnType is DynamicType) {
      registerError(node, "Dynamic return type");
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (checkReturnTypes && node.function.returnType is DynamicType) {
      registerError(node, "Dynamic return type");
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitProcedure(Procedure node) {
    if (checkReturnTypes &&
        node.function.returnType is DynamicType &&
        node.name.text != 'noSuchMethod') {
      registerError(node, "Dynamic return type on $node");
    }
    super.visitProcedure(node);
  }
}
