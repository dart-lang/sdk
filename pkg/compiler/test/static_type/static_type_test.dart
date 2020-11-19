// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/ir/cached_static_type.dart';
import 'package:compiler/src/ir/static_type_base.dart';
import 'package:compiler/src/ir/static_type_cache.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../helpers/ir_types.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, new StaticTypeDataComputer(),
        args: args, testedConfigs: allSpecConfigs);
  });
}

class StaticTypeDataComputer extends DataComputer<String> {
  ir.TypeEnvironment _typeEnvironment;

  ir.StaticTypeContext getStaticTypeContext(
      KernelToElementMapImpl elementMap, ir.Member node) {
    if (_typeEnvironment == null) {
      ir.Component component = elementMap.env.mainComponent;
      ir.CoreTypes coreTypes = new ir.CoreTypes(component);
      _typeEnvironment = new ir.TypeEnvironment(
          coreTypes, new ir.ClassHierarchy(component, coreTypes));
    }
    return new ir.StaticTypeContext(node, _typeEnvironment);
  }

  /// Compute type inference data for [member] from kernel based inference.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose: false}) {
    KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
    KernelToElementMapImpl elementMap = frontendStrategy.elementMap;
    StaticTypeCache staticTypeCache = elementMap.getCachedStaticTypes(member);
    ir.Member node = elementMap.getMemberNode(member);
    new StaticTypeIrComputer(
            compiler.reporter,
            actualMap,
            new CachedStaticType(
                getStaticTypeContext(elementMap, node),
                staticTypeCache,
                new ThisInterfaceType.from(node.enclosingClass?.getThisType(
                    _typeEnvironment.coreTypes,
                    node.enclosingLibrary.nonNullable))))
        .run(node);
  }

  @override
  bool get testFrontend => true;

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

/// IR visitor for computing inference data for a member.
class StaticTypeIrComputer extends IrDataExtractor<String> {
  final CachedStaticType staticTypeCache;

  StaticTypeIrComputer(DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap, this.staticTypeCache)
      : super(reporter, actualMap);

  @override
  String computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.VariableGet) {
      return typeToText(node.accept(staticTypeCache));
    } else if (node is ir.MethodInvocation) {
      return '[${typeToText(node.receiver.accept(staticTypeCache))}]->'
          '${typeToText(node.accept(staticTypeCache))}';
    }
    return null;
  }
}
