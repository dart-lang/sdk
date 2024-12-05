// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:front_end/src/api_prototype/testing.dart'
    show getMemberName, getEnclosingMember;
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = Directory.fromUri(Platform.script
        .resolve('../../../../pkg/front_end/test/id_testing/data'));
    await checkTests(dataDir, IdTestingDataComputer(),
        args: args, testedConfigs: [sharedConfig]);
  });
}

class IdTestingDataComputer extends DataComputer<String> {
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose = false}) {
    KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
    KernelToElementMap elementMap = frontendStrategy.elementMap;
    ir.Member node = elementMap.getMemberNode(member);
    IdTestingDataExtractor(compiler.reporter, actualMap, elementMap).run(node);
  }

  @override
  void computeClassData(
      Compiler compiler, ClassEntity cls, Map<Id, ActualData<String>> actualMap,
      {required bool verbose}) {
    KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
    KernelToElementMap elementMap = frontendStrategy.elementMap;
    ir.Class node = elementMap.getClassNode(cls);
    IdTestingDataExtractor(compiler.reporter, actualMap, elementMap)
        .computeForClass(node);
  }

  @override
  void computeLibraryData(Compiler compiler, LibraryEntity library,
      Map<Id, ActualData<String>> actualMap,
      {required bool verbose}) {
    KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
    KernelToElementMap elementMap = frontendStrategy.elementMap;
    ir.Library node = elementMap.getLibraryNode(library);
    IdTestingDataExtractor(compiler.reporter, actualMap, elementMap)
        .computeForLibrary(node);
  }

  @override
  bool get supportsErrors => true;

  @override
  String computeErrorData(
      Compiler compiler, Id id, List<CollectedMessage> errors) {
    return errors.map((c) => c.message!.message).join(',');
  }

  @override
  bool get testFrontend => true;

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

/// IR visitor for computing inference data for a member.
class IdTestingDataExtractor extends IrDataExtractor<String> {
  final KernelToElementMap elementMap;

  IdTestingDataExtractor(DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap, this.elementMap)
      : super(reporter, actualMap);

  @override
  String computeLibraryValue(Id id, ir.Library library) {
    StringBuffer sb = StringBuffer();
    sb.write('file=${library.importUri.pathSegments.last}');
    if (library.name != null) {
      sb.write(',name=${library.name}');
    }
    return sb.toString();
  }

  String computeClassName(ir.Class cls) {
    return cls.name;
  }

  String computeMemberName(ir.Member member) {
    if (member.enclosingClass != null) {
      return '${computeClassName(member.enclosingClass!)}.'
          '${getMemberName(member)}';
    }
    return getMemberName(member);
  }

  @override
  String computeClassValue(Id id, ir.Class cls) {
    return computeClassName(cls);
  }

  @override
  String? computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionDeclaration) {
      return '${computeMemberName(getEnclosingMember(node))}.'
          '${node.variable.name}';
    } else if (node is ir.FunctionExpression) {
      return '${computeMemberName(getEnclosingMember(node))}.'
          '<anonymous>';
    }
    return null;
  }

  @override
  String computeMemberValue(Id id, ir.Member member) {
    return computeMemberName(member);
  }
}
