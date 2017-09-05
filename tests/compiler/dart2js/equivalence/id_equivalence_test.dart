// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
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
  '../jumps/data',
];

main(List<String> args) {
  asyncTest(() async {
    for (String path in dataDirectories) {
      Directory dataDir = new Directory.fromUri(Platform.script.resolve(path));
      await for (FileSystemEntity entity in dataDir.list()) {
        if (args.isNotEmpty && !args.contains(entity.uri.pathSegments.last)) {
          continue;
        }
        print('Checking ${entity.uri}');
        String annotatedCode =
            await new File.fromUri(entity.uri).readAsString();
        IdData data1 = await computeData(
            annotatedCode, computeAstMemberData, compileFromSource,
            options: [Flags.disableTypeInference]);
        IdData data2 = await computeData(
            annotatedCode, computeIrMemberData, compileFromDill,
            options: [Flags.disableTypeInference]);
        data1.actualMap.forEach((Id id, ActualData actualData1) {
          IdValue value1 = actualData1.value;
          IdValue value2 = data2.actualMap[id]?.value;
          if (value1 != value2) {
            reportHere(data1.compiler.reporter, actualData1.sourceSpan,
                '$id: from source:${value1},from dill:${value2}');
            print('--annotations diff----------------------------------------');
            print(data1.computeDiffCodeFor(data2));
            print('----------------------------------------------------------');
          }
          Expect.equals(value1, value2, 'Value mismatch for $id');
        });
        data2.actualMap.forEach((Id id, ActualData actualData2) {
          IdValue value2 = actualData2.value;
          IdValue value1 = data1.actualMap[id]?.value;
          if (value1 != value2) {
            reportHere(data2.compiler.reporter, actualData2.sourceSpan,
                '$id: from source:${value1},from dill:${value2}');
            print('--annotations diff----------------------------------------');
            print(data1.computeDiffCodeFor(data2));
            print('----------------------------------------------------------');
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
void computeAstMemberData(
    Compiler compiler, MemberEntity _member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  MemberElement member = _member;
  ResolvedAst resolvedAst = member.resolvedAst;
  if (resolvedAst.kind != ResolvedAstKind.PARSED) return;
  new ResolvedAstComputer(compiler.reporter, actualMap, resolvedAst).run();
}

/// Mixin used for computing a descriptive mapping of the [Id]s in a member.
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

  String computeGetName(String propertyName) {
    return 'get:$propertyName';
  }

  String computeInvokeName(String propertyName) {
    return 'invoke:$propertyName';
  }

  String computeSetName(String propertyName) {
    return 'set:$propertyName';
  }

  String get loopName => 'loop';

  String get gotoName => 'goto';

  String get switchName => 'switch';

  String get switchCaseName => 'case';
}

/// AST visitor for computing a descriptive mapping of the [Id]s in a member.
class ResolvedAstComputer extends AstDataExtractor with ComputerMixin {
  ResolvedAstComputer(DiagnosticReporter reporter,
      Map<Id, ActualData> actualMap, ResolvedAst resolvedAst)
      : super(reporter, actualMap, resolvedAst);

  @override
  String computeNodeValue(Id id, ast.Node node, AstElement element) {
    if (element != null && element.isLocal) {
      return computeLocalName(element.name);
    }
    if (node is ast.Loop) {
      return loopName;
    } else if (node is ast.GotoStatement) {
      return gotoName;
    } else if (node is ast.SwitchStatement) {
      return switchName;
    } else if (node is ast.SwitchCase) {
      return switchCaseName;
    }

    dynamic sendStructure;
    if (node is ast.Send) {
      sendStructure = elements.getSendStructure(node);
      if (sendStructure == null) return null;

      String getDynamicName() {
        switch (sendStructure.semantics.kind) {
          case AccessKind.PARAMETER:
          case AccessKind.FINAL_PARAMETER:
          case AccessKind.LOCAL_VARIABLE:
          case AccessKind.FINAL_LOCAL_VARIABLE:
          case AccessKind.LOCAL_FUNCTION:
            return sendStructure.semantics.element.name;
          case AccessKind.THIS_PROPERTY:
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
          if (dynamicName != null) return computeGetName(dynamicName);
          break;
        case SendStructureKind.BINARY:
          return computeInvokeName(sendStructure.operator.selectorName);
        case SendStructureKind.EQUALS:
          return computeInvokeName('==');
        case SendStructureKind.NOT_EQUALS:
          return computeInvokeName('!=');
        case SendStructureKind.INVOKE:
          String dynamicName = getDynamicName();
          if (dynamicName != null) return computeInvokeName(dynamicName);
          break;
        case SendStructureKind.SET:
          String dynamicName = getDynamicName();
          if (dynamicName != null) return computeSetName(dynamicName);
          break;
        case SendStructureKind.POSTFIX:
          String dynamicName = getDynamicName();
          if (dynamicName != null) {
            if (id.kind == IdKind.update) {
              return computeSetName(dynamicName);
            } else if (id.kind == IdKind.invoke) {
              return computeInvokeName(
                  sendStructure.operator.binaryOperator.name);
            } else {
              return computeGetName(dynamicName);
            }
          }
          break;
        default:
      }
    }
    if (sendStructure != null) {
      return '<unknown:$node (${node.runtimeType}) $sendStructure>';
    }
    return '<unknown:$node (${node.runtimeType})>';
  }

  @override
  String computeElementValue(Id id, AstElement element) {
    return computeMemberName(element.enclosingClass?.name, element.name);
  }
}

/// Compute a descriptive mapping of the [Id]s in [member] as a kernel based
/// member.
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
void computeIrMemberData(
    Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  assert(definition.kind == MemberKind.regular,
      failedAt(member, "Unexpected member definition $definition"));
  new IrComputer(compiler.reporter, actualMap).run(definition.node);
}

/// IR visitor for computing a descriptive mapping of the [Id]s in a member.
class IrComputer extends IrDataExtractor with ComputerMixin {
  IrComputer(DiagnosticReporter reporter, Map<Id, ActualData> actualMap)
      : super(reporter, actualMap);

  @override
  String computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.VariableDeclaration) {
      return computeLocalName(node.name);
    } else if (node is ir.FunctionDeclaration) {
      return computeLocalName(node.variable.name);
    } else if (node is ir.FunctionExpression) {
      return computeLocalName('');
    } else if (node is ir.MethodInvocation) {
      return computeInvokeName(node.name.name);
    } else if (node is ir.PropertyGet) {
      return computeGetName(node.name.name);
    } else if (node is ir.PropertySet) {
      return computeSetName(node.name.name);
    } else if (node is ir.VariableGet) {
      return computeGetName(node.variable.name);
    } else if (node is ir.VariableSet) {
      return computeSetName(node.variable.name);
    } else if (node is ir.DoStatement) {
      return loopName;
    } else if (node is ir.ForStatement) {
      return loopName;
    } else if (node is ir.ForInStatement) {
      return loopName;
    } else if (node is ir.WhileStatement) {
      return loopName;
    } else if (node is ir.BreakStatement) {
      return gotoName;
    } else if (node is ir.ContinueSwitchStatement) {
      return gotoName;
    } else if (node is ir.SwitchStatement) {
      return switchName;
    } else if (node is ir.SwitchCase) {
      return switchCaseName;
    }
    return '<unknown:$node (${node.runtimeType})>';
  }

  @override
  String computeMemberValue(Id id, ir.Member member) {
    return computeMemberName(member.enclosingClass?.name, member.name.name);
  }
}
