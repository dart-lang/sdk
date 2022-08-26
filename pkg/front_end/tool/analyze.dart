// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/testing/analysis_helper.dart';
import 'package:kernel/kernel.dart';

Future<void> main(List<String> arguments) async {
  await runAnalysis(
      cfeAndBackendsEntryPoints,
      performGeneralAnalysis(cfeAndBackends,
          (TreeNode node, AnalysisInterface interface) {
        // Use 'analyze.dart' to perform advanced analysis/code search by
        // replacing the "example analysis" with a custom analysis.

        // Example analysis:
        if (node is InstanceInvocation && node.name.text == 'toList') {
          TreeNode receiver = node.receiver;
          if (receiver is InstanceInvocation &&
              receiver.name.text == 'map' &&
              receiver.arguments.types.length == 1) {
            InterfaceType expressionType = interface.createInterfaceType(
                'Expression',
                uri: 'package:kernel/ast.dart');
            DartType typeArgument = receiver.arguments.types.single;
            if (interface.isSubtypeOf(typeArgument, expressionType) &&
                typeArgument != expressionType) {
              interface.reportMessage(node, "map().toList()");
            }
          }
        }
      }));
}
