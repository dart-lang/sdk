// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:compiler/src/resolution/access_semantics.dart';
import 'package:compiler/src/resolution/send_structure.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

const List<String> dataDirectories = const <String>[
  '../closure/data',
  '../inference/data',
];

main() {
  asyncTest(() async {
    for (String path in dataDirectories) {
      Directory dataDir = new Directory.fromUri(Platform.script.resolve(path));
      await for (FileSystemEntity entity in dataDir.list()) {
        print('Checking ${entity.uri}');
        String annotatedCode =
            await new File.fromUri(entity.uri).readAsString();
        IdData data1 = await computeData(
            annotatedCode, computeAstMemberData, compileFromSource);
        IdData data2 = await computeData(
            annotatedCode, computeIrMemberData, compileFromDill);
        data1.actualMap.forEach((Id id, String value1) {
          String value2 = data2.actualMap[id];
          if (value1 != value2) {
            reportHere(data1.compiler.reporter, data1.sourceSpanMap[id],
                '$id: from source:${value1},from dill:${value2}');
          }
          Expect.equals(value1, value2, 'Value mismatch for $id');
        });
        data2.actualMap.forEach((Id id, String value2) {
          String value1 = data1.actualMap[id];
          if (value1 != value2) {
            reportHere(data2.compiler.reporter, data2.sourceSpanMap[id],
                '$id: from source:${value1},from dill:${value2}');
          }
          Expect.equals(value1, value2, 'Value mismatch for $id');
        });
      }
    }
  });
}

/// Compute a descriptive mapping of the [Id]s in [_member] as a
/// [MemberElement].
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
void computeAstMemberData(Compiler compiler, MemberEntity _member,
    Map<Id, String> actualMap, Map<Id, SourceSpan> sourceSpanMap) {
  MemberElement member = _member;
  ResolvedAst resolvedAst = member.resolvedAst;
  if (resolvedAst.kind != ResolvedAstKind.PARSED) return;
  new ResolvedAstComputer(
          compiler.reporter, actualMap, sourceSpanMap, resolvedAst)
      .run();
}

/// Mixin used for0computing a descriptive mapping of the [Id]s in a member.
class ComputerMixin {
  String computeMemberName(String className, String memberName) {
    if (className != null) {
      return 'member:$className.$memberName';
    }
    return 'member:$memberName';
  }

  String computeLocalName(String localName) {
    return 'local:$localName';
  }

  String computeDynamicGetName(String propertyName) {
    return 'dynamic-get:$propertyName';
  }

  String computeDynamicInvokeName(String propertyName) {
    return 'dynamic-invoke:$propertyName';
  }
}

/// AST visitor for computing a descriptive mapping of the [Id]s in a member.
class ResolvedAstComputer extends AbstractResolvedAstComputer
    with ComputerMixin {
  ResolvedAstComputer(DiagnosticReporter reporter, Map<Id, String> actualMap,
      Map<Id, SourceSpan> spannableMap, ResolvedAst resolvedAst)
      : super(reporter, actualMap, spannableMap, resolvedAst);

  @override
  String computeNodeValue(ast.Node node, AstElement element) {
    if (element != null && element.isLocal) {
      return computeLocalName(element.name);
    }
    if (node is ast.Send) {
      dynamic sendStructure = elements.getSendStructure(node);
      if (sendStructure == null) return null;

      String getDynamicName() {
        switch (sendStructure.semantics.kind) {
          case AccessKind.DYNAMIC_PROPERTY:
            DynamicAccess access = sendStructure.semantics;
            return access.name.text;
          default:
            return null;
        }
      }

      switch (sendStructure.kind) {
        case SendStructureKind.GET:
          String dynamicName = getDynamicName();
          if (dynamicName != null) return computeDynamicGetName(dynamicName);
          break;
        case SendStructureKind.INVOKE:
          String dynamicName = getDynamicName();
          if (dynamicName != null) return computeDynamicInvokeName(dynamicName);
          break;
        default:
      }
    }
    return '<unknown:$node>';
  }

  @override
  String computeElementValue(AstElement element) {
    return computeMemberName(element.enclosingClass?.name, element.name);
  }
}

/// Compute a descriptive mapping of the [Id]s in [member] as a kernel based
/// member.
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
void computeIrMemberData(Compiler compiler, MemberEntity member,
    Map<Id, String> actualMap, Map<Id, Spannable> spannableMap) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  new IrComputer(actualMap, spannableMap).run(elementMap.getMemberNode(member));
}

/// IR visitor for computing a descriptive mapping of the [Id]s in a member.
class IrComputer extends AbstractIrComputer with ComputerMixin {
  IrComputer(Map<Id, String> actualMap, Map<Id, SourceSpan> spannableMap)
      : super(actualMap, spannableMap);

  @override
  String computeNodeValue(ir.TreeNode node) {
    if (node is ir.VariableDeclaration) {
      return computeLocalName(node.name);
    } else if (node is ir.FunctionDeclaration) {
      return computeLocalName(node.variable.name);
    } else if (node is ir.MethodInvocation) {
      return computeDynamicInvokeName(node.name.name);
    } else if (node is ir.PropertyGet) {
      return computeDynamicGetName(node.name.name);
    }
    return '<unknown:$node>';
  }

  @override
  String computeMemberValue(ir.Member member) {
    return computeMemberName(member.enclosingClass?.name, member.name.name);
  }
}
