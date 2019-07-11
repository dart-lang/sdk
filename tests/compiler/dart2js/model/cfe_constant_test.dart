// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:front_end/src/testing/id_testing.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../helpers/shared_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script
        .resolve('../../../../pkg/front_end/test/constants/data'));
    await checkTests(dataDir, new ConstantDataComputer(),
        args: args,
        testedConfigs: [sharedConfig],
        supportedMarkers: sharedMarkers);
  });
}

class ConstantDataComputer extends DataComputer<String> {
  ir.TypeEnvironment _typeEnvironment;

  ir.TypeEnvironment getTypeEnvironment(KernelToElementMapImpl elementMap) {
    if (_typeEnvironment == null) {
      ir.Component component = elementMap.env.mainComponent;
      _typeEnvironment = new ir.TypeEnvironment(
          new ir.CoreTypes(component), new ir.ClassHierarchy(component));
    }
    return _typeEnvironment;
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
    ir.Member node = elementMap.getMemberNode(member);
    new ConstantDataExtractor(compiler.reporter, actualMap, elementMap)
        .run(node);
  }

  @override
  bool get testFrontend => true;

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

/// IR visitor for computing inference data for a member.
class ConstantDataExtractor extends IrDataExtractor<String> {
  final KernelToElementMapImpl elementMap;

  ConstantDataExtractor(DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap, this.elementMap)
      : super(reporter, actualMap);

  @override
  String computeClassValue(Id id, ir.Class cls) {
    return null;
  }

  @override
  String computeMemberValue(Id id, ir.Member node) {
    return null;
  }

  @override
  String computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.ConstantExpression) {
      return constantToText(elementMap.getConstantValue(node));
    }
    return null;
  }
}
