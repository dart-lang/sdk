// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/ir/static_type.dart';
import 'package:compiler/src/kernel/loader.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'package:front_end/src/api_prototype/constant_evaluator.dart' as ir;

import '../helpers/memory_compiler.dart';
import 'analysis_helper.dart';

const String source = '''
main() {}
''';

main() {
  asyncTest(() async {
    Compiler compiler =
        await compilerFor(memorySourceFiles: {'main.dart': source});
    KernelResult result =
        await compiler.kernelLoader.load(Uri.parse('memory:main.dart'));
    ir.Component component = result.component;
    StaticTypeVisitor visitor = new Visitor(component);
    component.accept(visitor);
  });
}

class Visitor extends StaticTypeVisitorBase {
  Visitor(ir.Component component)
      : super(component,
            new ir.ClassHierarchy(component, new ir.CoreTypes(component)),
            evaluationMode: ir.EvaluationMode.weak);

  ir.DartType getStaticType(ir.Expression node) {
    if (typeEnvironment == null) {
      // The class hierarchy crashes on multiple inheritance. Use `dynamic`
      // as static type.
      return const ir.DynamicType();
    }
    ir.TreeNode enclosingMember = node;
    while (enclosingMember != null && enclosingMember is! ir.Member) {
      enclosingMember = enclosingMember.parent;
    }
    try {
      staticTypeContext =
          new ir.StaticTypeContext(enclosingMember, typeEnvironment);
      return node.getStaticType(staticTypeContext);
    } catch (e) {
      // The static type computation crashes on type errors. Use `dynamic`
      // as static type.
      return const ir.DynamicType();
    }
  }
}
