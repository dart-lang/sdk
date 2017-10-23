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
import 'package:kernel/ast.dart' as ir;
import '../annotated_code_helper.dart';
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
        AnnotatedCode code =
            new AnnotatedCode.fromText(annotatedCode, commentStart, commentEnd);
        // Pretend this is a dart2js_native test to allow use of 'native'
        // keyword and import of private libraries.
        Uri entryPoint =
            Uri.parse('memory:sdk/tests/compiler/dart2js_native/main.dart');
        Map<String, String> memorySourceFiles = {
          entryPoint.path: code.sourceCode
        };
        await compareData(entryPoint, memorySourceFiles, computeAstMemberData,
            computeIrMemberData,
            options: [Flags.disableTypeInference, stopAfterTypeInference]);
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

  String get labelName => 'label';
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
    } else if (node is ast.LabeledStatement) {
      return labelName;
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
          case AccessKind.CONDITIONAL_DYNAMIC_PROPERTY:
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
        case SendStructureKind.UNARY:
          return computeInvokeName(sendStructure.operator.selectorName);
        case SendStructureKind.INDEX:
          return computeInvokeName('[]');
        case SendStructureKind.EQUALS:
          return computeInvokeName('==');
        case SendStructureKind.NOT_EQUALS:
          return computeInvokeName('==');
        case SendStructureKind.INVOKE:
          switch (sendStructure.semantics.kind) {
            case AccessKind.LOCAL_VARIABLE:
            case AccessKind.FINAL_LOCAL_VARIABLE:
            case AccessKind.PARAMETER:
            case AccessKind.FINAL_PARAMETER:
            case AccessKind.EXPRESSION:
              if (id.kind == IdKind.invoke) {
                return computeInvokeName('call');
              } else if (id.kind == IdKind.node) {
                String dynamicName = getDynamicName();
                if (dynamicName != null) return computeGetName(dynamicName);
              }
              break;
            case AccessKind.STATIC_FIELD:
            case AccessKind.FINAL_STATIC_FIELD:
            case AccessKind.TOPLEVEL_FIELD:
            case AccessKind.FINAL_TOPLEVEL_FIELD:
            case AccessKind.STATIC_GETTER:
            case AccessKind.TOPLEVEL_GETTER:
            case AccessKind.SUPER_FIELD:
            case AccessKind.SUPER_FINAL_FIELD:
            case AccessKind.SUPER_GETTER:
              if (id.kind == IdKind.invoke) {
                return computeInvokeName('call');
              }
              break;
            default:
              String dynamicName = getDynamicName();
              if (dynamicName != null) return computeInvokeName(dynamicName);
          }
          break;
        case SendStructureKind.SET:
          String dynamicName = getDynamicName();
          if (dynamicName != null) return computeSetName(dynamicName);
          break;
        case SendStructureKind.PREFIX:
        case SendStructureKind.POSTFIX:
        case SendStructureKind.COMPOUND:
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
  assert(
      definition.kind == MemberKind.regular ||
          definition.kind == MemberKind.constructor,
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
      ir.TreeNode receiver = node.receiver;
      if (receiver is ir.VariableGet &&
          receiver.variable.parent is ir.FunctionDeclaration) {
        // This is an invocation of a named local function.
        return computeInvokeName(receiver.variable.name);
      } else {
        return computeInvokeName(node.name.name);
      }
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
    } else if (node is ir.LabeledStatement) {
      return labelName;
    }
    return '<unknown:$node (${node.runtimeType})>';
  }

  @override
  String computeMemberValue(Id id, ir.Member member) {
    return computeMemberName(member.enclosingClass?.name, member.name.name);
  }
}
