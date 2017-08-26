// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' hide Link;
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:compiler/src/js_model/locals.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;
import 'package:compiler/src/util/util.dart';
import 'package:expect/expect.dart';
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import 'package:kernel/ast.dart' as ir;

main(List<String> args) {
  bool verbose = args.contains('-v');
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, computeClosureData, computeKernelClosureData,
        // TODO(johnnniwinther,efortuna): Enable these tests for .dill.
        skipForKernel: ['captured_variable.dart'],
        options: [Flags.disableTypeInference],
        verbose: verbose);
  });
}

/// Compute closure data mapping for [_member] as a [MemberElement].
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
void computeClosureData(
    Compiler compiler, MemberEntity _member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  MemberElement member = _member;
  ClosureDataLookup<ast.Node> closureDataLookup =
      compiler.backendStrategy.closureDataLookup as ClosureDataLookup<ast.Node>;
  new ClosureAstComputer(
          compiler.reporter, actualMap, member.resolvedAst, closureDataLookup,
          verbose: verbose)
      .run();
}

/// Compute closure data mapping for [member] as a kernel based element.
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
void computeKernelClosureData(
    Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
    {bool verbose: false}) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  GlobalLocalsMap localsMap = backendStrategy.globalLocalsMapForTesting;
  ClosureDataLookup closureDataLookup = backendStrategy.closureDataLookup;
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  assert(definition.kind == MemberKind.regular,
      failedAt(member, "Unexpected member definition $definition"));
  new ClosureIrChecker(actualMap, elementMap, member,
          localsMap.getLocalsMap(member), closureDataLookup,
          verbose: verbose)
      .run(definition.node);
}

/// Ast visitor for computing closure data.
class ClosureAstComputer extends AstDataExtractor with ComputeValueMixin {
  final ClosureDataLookup<ast.Node> closureDataLookup;
  final bool verbose;

  ClosureAstComputer(DiagnosticReporter reporter, Map<Id, ActualData> actualMap,
      ResolvedAst resolvedAst, this.closureDataLookup,
      {this.verbose: false})
      : super(reporter, actualMap, resolvedAst) {
    pushMember(resolvedAst.element as MemberElement);
  }

  visitFunctionExpression(ast.FunctionExpression node) {
    Entity localFunction = resolvedAst.elements.getFunctionDefinition(node);
    if (localFunction is LocalFunctionElement) {
      pushLocalFunction(node);
      super.visitFunctionExpression(node);
      popLocalFunction();
    } else {
      super.visitFunctionExpression(node);
    }
  }

  @override
  String computeNodeValue(ast.Node node, [AstElement element]) {
    if (element != null && element.isLocal) {
      if (element.isFunction) {
        return computeObjectValue(element);
      } else {
        LocalElement local = element;
        return computeLocalValue(local);
      }
    }
    // TODO(johnniwinther,efortuna): Collect data for other nodes?
    return null;
  }

  @override
  String computeElementValue(AstElement element) {
    // TODO(johnniwinther,efortuna): Collect data for the member
    // (has thisLocal, has box, etc.).
    return computeObjectValue(element);
  }
}

/// Kernel IR visitor for computing closure data.
class ClosureIrChecker extends IrDataExtractor with ComputeValueMixin<ir.Node> {
  final MemberEntity member;
  final ClosureDataLookup<ir.Node> closureDataLookup;
  final KernelToLocalsMap _localsMap;
  final bool verbose;

  ClosureIrChecker(
      Map<Id, ActualData> actualMap,
      KernelToElementMapForBuilding elementMap,
      this.member,
      this._localsMap,
      this.closureDataLookup,
      {this.verbose: false})
      : super(actualMap) {
    pushMember(member);
  }

  visitFunctionExpression(ir.FunctionExpression node) {
    pushLocalFunction(node);
    super.visitFunctionExpression(node);
    popLocalFunction();
  }

  visitFunctionDeclaration(ir.FunctionDeclaration node) {
    pushLocalFunction(node);
    super.visitFunctionDeclaration(node);
    popLocalFunction();
  }

  @override
  String computeNodeValue(ir.Node node) {
    if (node is ir.VariableDeclaration) {
      if (node.parent is ir.FunctionDeclaration) {
        return computeObjectValue(node.parent);
      }
      Local local = _localsMap.getLocalVariable(node);
      return computeLocalValue(local);
    } else if (node is ir.FunctionExpression) {
      return computeObjectValue(node);
    }
    return null;
  }

  @override
  String computeMemberValue(ir.Member node) {
    return computeObjectValue(member);
  }
}

abstract class ComputeValueMixin<T> {
  bool get verbose;
  ClosureDataLookup<T> get closureDataLookup;
  Link<ScopeInfo> scopeInfoStack = const Link<ScopeInfo>();
  ScopeInfo get scopeInfo => scopeInfoStack.head;
  CapturedScope capturedScope;
  Link<ClosureRepresentationInfo> closureRepresentationInfoStack =
      const Link<ClosureRepresentationInfo>();
  ClosureRepresentationInfo get closureRepresentationInfo =>
      closureRepresentationInfoStack.isNotEmpty
          ? closureRepresentationInfoStack.head
          : null;

  void pushMember(MemberEntity member) {
    scopeInfoStack =
        scopeInfoStack.prepend(closureDataLookup.getScopeInfo(member));
    capturedScope = closureDataLookup.getCapturedScope(member);
    dump(member);
  }

  void popMember() {
    scopeInfoStack = scopeInfoStack.tail;
  }

  void pushLocalFunction(T node) {
    closureRepresentationInfoStack = closureRepresentationInfoStack
        .prepend(closureDataLookup.getClosureInfo(node));
    dump(node);
  }

  void popLocalFunction() {
    closureRepresentationInfoStack = closureRepresentationInfoStack.tail;
  }

  void dump(Object object) {
    if (!verbose) return;

    print('object: $object');
    if (object is MemberEntity) {
      print(' scopeInfo (${scopeInfo.runtimeType})');
      scopeInfo.forEachBoxedVariable((a, b) => print('  boxed1: $a->$b'));
      print(' capturedScope (${capturedScope.runtimeType})');
      capturedScope.forEachBoxedVariable((a, b) => print('  boxed2: $a->$b'));
    }
    print(
        ' closureRepresentationInfo (${closureRepresentationInfo.runtimeType})');
    closureRepresentationInfo
        ?.forEachCapturedVariable((a, b) => print('  captured: $a->$b'));
    closureRepresentationInfo
        ?.forEachFreeVariable((a, b) => print('  free3: $a->$b'));
    closureRepresentationInfo
        ?.forEachBoxedVariable((a, b) => print('  boxed3: $a->$b'));
  }

  /// Compute a string representation of the data stored for [local] in [info].
  String computeLocalValue(Local local) {
    List<String> features = <String>[];
    if (scopeInfo.localIsUsedInTryOrSync(local)) {
      features.add('inTry');
      // TODO(johnniwinther,efortuna): Should this be enabled and checked?
      //Expect.isTrue(capturedScope.localIsUsedInTryOrSync(local));
    } else {
      //Expect.isFalse(capturedScope.localIsUsedInTryOrSync(local));
    }
    if (scopeInfo.isBoxed(local)) {
      features.add('boxed');
      Expect.isTrue(capturedScope.isBoxed(local));
    } else {
      Expect.isFalse(capturedScope.isBoxed(local));
    }
    if (capturedScope.context == local) {
      features.add('local');
    }
    if (capturedScope is CapturedLoopScope) {
      CapturedLoopScope loopScope = capturedScope;
      if (loopScope.boxedLoopVariables.contains(local)) {
        features.add('loop');
      }
    }
    if (closureRepresentationInfo != null) {
      if (closureRepresentationInfo.createdFieldEntities.contains(local)) {
        features.add('field');
      }
      if (closureRepresentationInfo.isVariableBoxed(local)) {
        features.add('variable-boxed');
      }
    }
    // TODO(johnniwinther,efortuna): Add more info?
    return (features.toList()..sort()).join(',');
  }

  String computeObjectValue(Object object) {
    Map<String, String> features = <String, String>{};

    void addLocals(String name, forEach(f(Local local, _))) {
      List<String> names = <String>[];
      forEach((Local local, _) {
        if (local is BoxLocal) {
          names.add('box');
        } else {
          names.add(local.name);
        }
      });
      String value = names.isEmpty ? null : '[${(names..sort()).join(',')}]';
      if (features.containsKey(name)) {
        Expect.equals(
            features[name], value, "Inconsistent values for $name on $object.");
      }
      features[name] = value;
    }

    if (object is MemberEntity) {
      if (scopeInfo.thisLocal != null) {
        features['hasThis'] = '';
      }
      addLocals('boxed', scopeInfo.forEachBoxedVariable);

      if (capturedScope.requiresContextBox) {
        features['requiresBox'] = '';
      }
      addLocals('boxed', capturedScope.forEachBoxedVariable);
    }

    if (closureRepresentationInfo != null) {
      addLocals('boxed', closureRepresentationInfo.forEachBoxedVariable);
      addLocals('captured', closureRepresentationInfo.forEachCapturedVariable);
      addLocals('free', closureRepresentationInfo.forEachFreeVariable);
    }

    StringBuffer sb = new StringBuffer();
    bool needsComma = false;
    for (String name in features.keys.toList()..sort()) {
      String value = features[name];
      if (value != null) {
        if (needsComma) {
          sb.write(',');
        }
        sb.write(name);
        if (value != '') {
          sb.write('=');
          sb.write(value);
        }
        needsComma = true;
      }
    }
    return sb.toString();
  }
}
