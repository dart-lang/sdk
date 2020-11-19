// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../helpers/shared_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script
        .resolve('../../../../pkg/_fe_analyzer_shared/test/constants/data_2'));
    await checkTests<String>(dataDir, new ConstantDataComputer(),
        args: args, testedConfigs: [sharedConfig]);
  });
}

class ConstantDataComputer extends DataComputer<String> {
  ir.TypeEnvironment _typeEnvironment;

  ir.TypeEnvironment getTypeEnvironment(KernelToElementMapImpl elementMap) {
    if (_typeEnvironment == null) {
      ir.Component component = elementMap.env.mainComponent;
      ir.CoreTypes coreTypes = new ir.CoreTypes(component);
      _typeEnvironment = new ir.TypeEnvironment(
          coreTypes, new ir.ClassHierarchy(component, coreTypes));
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
    new ConstantDataExtractor(compiler.reporter, actualMap, elementMap, member)
        .run(node);
  }

  @override
  bool get supportsErrors => true;

  @override
  String computeErrorData(
      Compiler compiler, Id id, List<CollectedMessage> errors) {
    return errors.map((c) => c.message.message).join(',');
  }

  @override
  bool get testFrontend => true;

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

/// IR visitor for computing inference data for a member.
class ConstantDataExtractor extends IrDataExtractor<String> {
  final KernelToElementMapImpl elementMap;
  final MemberEntity member;

  ConstantDataExtractor(DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap, this.elementMap, this.member)
      : super(reporter, actualMap);

  @override
  String computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.ConstantExpression) {
      return constantToText(
          elementMap.types,
          elementMap.getConstantValue(
              elementMap.getStaticTypeContext(member), node));
    }
    return null;
  }
}
