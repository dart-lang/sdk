// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/ir/static_type.dart';
import 'package:compiler/src/phase/load_kernel.dart' as load_kernel;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'package:front_end/src/api_prototype/constant_evaluator.dart' as ir;

import 'package:compiler/src/util/memory_compiler.dart';
import 'analysis_helper.dart';

const String source = '''
main() {}
''';

main() {
  asyncTest(() async {
    Compiler compiler = await compilerFor(
        memorySourceFiles: {'main.dart': source},
        entryPoint: Uri.parse('memory:main.dart'));
    load_kernel.Output result = (await load_kernel.run(load_kernel.Input(
        compiler.options,
        compiler.provider,
        compiler.reporter,
        compiler.initializedCompilerState,
        false)))!;
    ir.Component component = result.component;
    StaticTypeVisitor visitor = Visitor(component);
    component.accept(visitor);
  });
}

class Visitor extends StaticTypeVisitorBase {
  Visitor(ir.Component component)
      : super(component, ir.ClassHierarchy(component, ir.CoreTypes(component)),
            evaluationMode: ir.EvaluationMode.weak);

  ir.DartType getStaticType(ir.Expression node) {
    ir.TreeNode? enclosingMember = node;
    while (enclosingMember != null && enclosingMember is! ir.Member) {
      enclosingMember = enclosingMember.parent;
    }
    try {
      staticTypeContext =
          ir.StaticTypeContext(enclosingMember as ir.Member, typeEnvironment);
      return node.getStaticType(staticTypeContext);
    } catch (e) {
      // The static type computation crashes on type errors. Use `dynamic`
      // as static type.
      return const ir.DynamicType();
    }
  }
}
