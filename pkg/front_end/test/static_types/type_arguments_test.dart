// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/testing/analysis_helper.dart';
import '../../lib/src/testing/verifying_analysis.dart';

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart';
import 'package:kernel/ast.dart';

Future<void> main(List<String> args) async {
  await run(cfeAndBackendsEntryPoints,
      'pkg/front_end/test/static_types/type_arguments.json',
      analyzedUrisFilter: cfeAndBackends,
      verbose: args.contains('-v'),
      generate: args.contains('-g'));
}

Future<void> run(List<Uri> entryPoints, String allowedListPath,
    {bool verbose = false,
    bool generate = false,
    bool Function(Uri uri)? analyzedUrisFilter}) async {
  await runAnalysis(entryPoints,
      (DiagnosticMessageHandler onDiagnostic, Component component) {
    new TypeArgumentsVisitor(
            onDiagnostic, component, allowedListPath, analyzedUrisFilter)
        .run(verbose: verbose, generate: generate);
  });
}

class TypeArgumentsVisitor extends VerifyingAnalysis {
  TypeArgumentsVisitor(
      DiagnosticMessageHandler onDiagnostic,
      Component component,
      String? allowedListPath,
      UriFilter? analyzedUrisFilter)
      : super(onDiagnostic, component, allowedListPath, analyzedUrisFilter);

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    if (node.name.text == 'toList') {
      TreeNode receiver = node.receiver;
      if (receiver is InstanceInvocation &&
          receiver.name.text == 'map' &&
          receiver.arguments.types.length == 1) {
        String astUri = 'package:kernel/ast.dart';
        InterfaceType expressionType =
            interface.createInterfaceType('Expression', uri: astUri);
        InterfaceType statementType =
            interface.createInterfaceType('Statement', uri: astUri);
        InterfaceType assertStatementType =
            interface.createInterfaceType('AssertStatement', uri: astUri);
        InterfaceType variableDeclarationType =
            interface.createInterfaceType('VariableDeclaration', uri: astUri);
        DartType typeArgument = receiver.arguments.types.single;
        if (interface.isSubtypeOf(typeArgument, expressionType) &&
            typeArgument != expressionType) {
          registerError(
              node,
              "map().toList() with type argument "
              "${typeArgument} instead of ${expressionType}");
        }
        if (interface.isSubtypeOf(typeArgument, statementType)) {
          if (interface.isSubtypeOf(typeArgument, assertStatementType)) {
            // [AssertStatement] is used as an exclusive member of
            // `InstanceCreation.asserts`.
            if (typeArgument != assertStatementType) {
              registerError(
                  node,
                  "map().toList() with type argument "
                  "${typeArgument} instead of ${assertStatementType}");
            }
          } else if (interface.isSubtypeOf(
              typeArgument, variableDeclarationType)) {
            // [VariableDeclaration] is used as an exclusive member of, for
            // instance, `FunctionNode.positionalParameters`.
            if (typeArgument != variableDeclarationType) {
              registerError(
                  node,
                  "map().toList() with type argument "
                  "${typeArgument} instead of ${variableDeclarationType}");
            }
          } else if (typeArgument != statementType) {
            registerError(
                node,
                "map().toList() with type argument "
                "${typeArgument} instead of ${statementType}");
          }
        }
      }
    }
    super.visitInstanceInvocation(node);
  }
}
