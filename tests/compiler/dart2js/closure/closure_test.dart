// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' hide Link;
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
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
    await for (FileSystemEntity entity in dataDir.list()) {
      print('----------------------------------------------------------------');
      print('Checking ${entity.uri}');
      print('----------------------------------------------------------------');
      String annotatedCode = await new File.fromUri(entity.uri).readAsString();
      print('--from source---------------------------------------------------');
      await checkCode(annotatedCode, computeClosureData, compileFromSource,
          verbose: verbose);
      // TODO(johnnniwinther,efortuna): Enable the these tests for .dill.
      if (['captured_variable.dart'].contains(entity.uri.pathSegments.last)) {
        print('--skipped for dill--------------------------------------------');
        continue;
      }
      print('--from dill-----------------------------------------------------');
      await checkCode(annotatedCode, computeKernelClosureData, compileFromDill,
          verbose: verbose);
    }
  });
}

/// Compute closure data mapping for [_member] as a [MemberElement].
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
void computeClosureData(Compiler compiler, MemberEntity _member,
    Map<Id, String> actualMap, Map<Id, SourceSpan> sourceSpanMap,
    {bool verbose: false}) {
  MemberElement member = _member;
  ClosureDataLookup<ast.Node> closureDataLookup =
      compiler.backendStrategy.closureDataLookup as ClosureDataLookup<ast.Node>;
  new ClosureAstComputer(compiler.reporter, actualMap, sourceSpanMap,
          member.resolvedAst, closureDataLookup,
          verbose: verbose)
      .run();
}

/// Compute closure data mapping for [member] as a kernel based element.
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
void computeKernelClosureData(Compiler compiler, MemberEntity member,
    Map<Id, String> actualMap, Map<Id, SourceSpan> sourceSpanMap,
    {bool verbose: false}) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMapForBuilding elementMap = backendStrategy.elementMap;
  GlobalLocalsMap localsMap = backendStrategy.globalLocalsMapForTesting;
  ClosureDataLookup closureDataLookup = backendStrategy.closureDataLookup;
  MemberDefinition definition = elementMap.getMemberDefinition(member);
  assert(definition.kind == MemberKind.regular,
      failedAt(member, "Unexpected member definition $definition"));
  new ClosureIrChecker(actualMap, sourceSpanMap, elementMap, member,
          localsMap.getLocalsMap(member), closureDataLookup,
          verbose: verbose)
      .run(definition.node);
}

/// Ast visitor for computing closure data.
class ClosureAstComputer extends AbstractResolvedAstComputer
    with ComputeValueMixin {
  final ClosureDataLookup<ast.Node> closureDataLookup;
  final bool verbose;

  ClosureAstComputer(
      DiagnosticReporter reporter,
      Map<Id, String> actualMap,
      Map<Id, Spannable> spannableMap,
      ResolvedAst resolvedAst,
      this.closureDataLookup,
      {this.verbose: false})
      : super(reporter, actualMap, spannableMap, resolvedAst) {
    push(resolvedAst.element);
  }

  visitFunctionExpression(ast.FunctionExpression node) {
    Entity localFunction = resolvedAst.elements.getFunctionDefinition(node);
    if (localFunction is LocalFunctionElement) {
      push(localFunction);
      super.visitFunctionExpression(node);
      pop();
    } else {
      super.visitFunctionExpression(node);
    }
  }

  @override
  String computeNodeValue(ast.Node node, [AstElement element]) {
    if (element != null && element.isLocal) {
      if (element.isFunction) {
        return computeEntityValue(element);
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
    return computeEntityValue(element);
  }
}

/// Kernel IR visitor for computing closure data.
class ClosureIrChecker extends AbstractIrComputer
    with ComputeValueMixin<ir.Node> {
  final ClosureDataLookup<ir.Node> closureDataLookup;
  final KernelToLocalsMap _localsMap;
  final bool verbose;

  ClosureIrChecker(
      Map<Id, String> actualMap,
      Map<Id, SourceSpan> sourceSpanMap,
      KernelToElementMapForBuilding elementMap,
      MemberEntity member,
      this._localsMap,
      this.closureDataLookup,
      {this.verbose: false})
      : super(actualMap, sourceSpanMap) {
    push(member);
  }

  visitFunctionExpression(ir.FunctionExpression node) {
    Local localFunction = _localsMap.getLocalFunction(node);
    push(localFunction);
    super.visitFunctionExpression(node);
    pop();
  }

  visitFunctionDeclaration(ir.FunctionDeclaration node) {
    Local localFunction = _localsMap.getLocalFunction(node);
    push(localFunction);
    super.visitFunctionDeclaration(node);
    pop();
  }

  @override
  String computeNodeValue(ir.Node node) {
    if (node is ir.VariableDeclaration) {
      Local local = _localsMap.getLocalVariable(node);
      return computeLocalValue(local);
    }
    // TODO(johnniwinther,efortuna): Collect data for other nodes?
    return null;
  }

  @override
  String computeMemberValue(ir.Member member) {
    // TODO(johnniwinther,efortuna): Collect data for the member
    // (has thisLocal, has box, etc.).
    return computeEntityValue(entity);
  }
}

abstract class ComputeValueMixin<T> {
  bool get verbose;
  ClosureDataLookup<T> get closureDataLookup;
  Entity get entity => entityStack.head;
  Link<Entity> entityStack = const Link<Entity>();
  Link<ScopeInfo> scopeInfoStack = const Link<ScopeInfo>();
  ScopeInfo get scopeInfo => scopeInfoStack.head;
  CapturedScope capturedScope;
  Link<ClosureRepresentationInfo> closureRepresentationInfoStack =
      const Link<ClosureRepresentationInfo>();
  ClosureRepresentationInfo get closureRepresentationInfo =>
      closureRepresentationInfoStack.head;

  void push(Entity entity) {
    entityStack = entityStack.prepend(entity);
    scopeInfoStack =
        scopeInfoStack.prepend(closureDataLookup.getScopeInfo(entity));
    if (entity is MemberEntity) {
      capturedScope = closureDataLookup.getCapturedScope(entity);
    }
    closureRepresentationInfoStack = closureRepresentationInfoStack.prepend(
        closureDataLookup.getClosureRepresentationInfoForTesting(entity));
    dump(entity);
  }

  void pop() {
    entityStack = entityStack.tail;
    scopeInfoStack = scopeInfoStack.tail;
    closureRepresentationInfoStack = closureRepresentationInfoStack.tail;
  }

  void dump(Entity entity) {
    if (!verbose) return;

    print('entity: $entity');
    print(' scopeInfo (${scopeInfo.runtimeType})');
    scopeInfo.forEachBoxedVariable((a, b) => print('  boxed1: $a->$b'));
    print(' capturedScope (${capturedScope.runtimeType})');
    capturedScope.forEachBoxedVariable((a, b) => print('  boxed2: $a->$b'));
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

  String computeEntityValue(Entity entity) {
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
            features[name], value, "Inconsistent values for $name on $entity.");
      }
      features[name] = value;
    }

    if (scopeInfo.thisLocal != null) {
      features['hasThis'] = '';
    }
    addLocals('boxed', scopeInfo.forEachBoxedVariable);

    if (entity is MemberEntity) {
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
