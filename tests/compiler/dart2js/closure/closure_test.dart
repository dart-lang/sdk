// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io' hide Link;
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:_fe_analyzer_shared/src/util/link.dart' show Link;
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/js_model/locals.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const ClosureDataComputer(), args: args);
  });
}

class ClosureDataComputer extends DataComputer<String> {
  const ClosureDataComputer();

  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    GlobalLocalsMap localsMap = closedWorld.globalLocalsMap;
    ClosureData closureDataLookup = closedWorld.closureDataLookup;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    assert(
        definition.kind == MemberKind.regular ||
            definition.kind == MemberKind.constructor,
        failedAt(member, "Unexpected member definition $definition"));
    new ClosureIrChecker(compiler.reporter, actualMap, elementMap, member,
            localsMap.getLocalsMap(member), closureDataLookup, closedWorld,
            verbose: verbose)
        .run(definition.node);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

/// Kernel IR visitor for computing closure data.
class ClosureIrChecker extends IrDataExtractor<String> {
  final MemberEntity member;
  final ClosureData closureDataLookup;
  final JClosedWorld _closedWorld;
  final KernelToLocalsMap _localsMap;
  final bool verbose;

  Map<BoxLocal, String> boxNames = <BoxLocal, String>{};
  Link<ScopeInfo> scopeInfoStack = const Link<ScopeInfo>();

  Link<CapturedScope> capturedScopeStack = const Link<CapturedScope>();
  Link<ClosureRepresentationInfo> closureRepresentationInfoStack =
      const Link<ClosureRepresentationInfo>();

  ClosureIrChecker(
      DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap,
      JsToElementMap elementMap,
      this.member,
      this._localsMap,
      this.closureDataLookup,
      this._closedWorld,
      {this.verbose: false})
      : super(reporter, actualMap) {
    pushMember(member);
  }

  ScopeInfo get scopeInfo => scopeInfoStack.head;
  CapturedScope get capturedScope => capturedScopeStack.head;

  ClosureRepresentationInfo get closureRepresentationInfo =>
      closureRepresentationInfoStack.isNotEmpty
          ? closureRepresentationInfoStack.head
          : null;

  @override
  visitFunctionExpression(ir.FunctionExpression node) {
    ClosureRepresentationInfo info = closureDataLookup.getClosureInfo(node);
    pushMember(info.callMethod);
    pushLocalFunction(node);
    super.visitFunctionExpression(node);
    popLocalFunction();
    popMember();
  }

  @override
  visitFunctionDeclaration(ir.FunctionDeclaration node) {
    ClosureRepresentationInfo info = closureDataLookup.getClosureInfo(node);
    pushMember(info.callMethod);
    pushLocalFunction(node);
    super.visitFunctionDeclaration(node);
    popLocalFunction();
    popMember();
  }

  @override
  visitForStatement(ir.ForStatement node) {
    pushLoopNode(node);
    super.visitForStatement(node);
    popLoop();
  }

  @override
  visitWhileStatement(ir.WhileStatement node) {
    pushLoopNode(node);
    super.visitWhileStatement(node);
    popLoop();
  }

  @override
  visitForInStatement(ir.ForInStatement node) {
    pushLoopNode(node);
    super.visitForInStatement(node);
    popLoop();
  }

  @override
  String computeNodeValue(Id id, ir.Node node) {
    if (node is ir.VariableDeclaration) {
      Local local = _localsMap.getLocalVariable(node);
      return computeLocalValue(local);
    } else if (node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = closureDataLookup.getClosureInfo(node);
      return computeObjectValue(info.callMethod);
    } else if (node is ir.FunctionExpression) {
      ClosureRepresentationInfo info = closureDataLookup.getClosureInfo(node);
      return computeObjectValue(info.callMethod);
    }
    return null;
  }

  @override
  String computeMemberValue(Id id, ir.Member node) {
    return computeObjectValue(member);
  }

  void pushMember(MemberEntity member) {
    scopeInfoStack =
        scopeInfoStack.prepend(closureDataLookup.getScopeInfo(member));
    capturedScopeStack =
        capturedScopeStack.prepend(closureDataLookup.getCapturedScope(member));
    if (capturedScope.requiresContextBox) {
      boxNames[capturedScope.context] = 'box${boxNames.length}';
    }
    dump(member);
  }

  void popMember() {
    scopeInfoStack = scopeInfoStack.tail;
    capturedScopeStack = capturedScopeStack.tail;
  }

  void pushLoopNode(ir.Node node) {
    //scopeInfoStack = // TODO?
    //    scopeInfoStack.prepend(closureDataLookup.getScopeInfo(member));
    capturedScopeStack = capturedScopeStack
        .prepend(closureDataLookup.getCapturedLoopScope(node));
    if (capturedScope.requiresContextBox) {
      boxNames[capturedScope.context] = 'box${boxNames.length}';
    }
    dump(node);
  }

  void popLoop() {
    capturedScopeStack = capturedScopeStack.tail;
  }

  void pushLocalFunction(ir.Node node) {
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
      print(' capturedScope (${capturedScope.runtimeType})');
      capturedScope.forEachBoxedVariable((a, b) => print('  boxed: $a->$b'));
    }
    print(
        ' closureRepresentationInfo (${closureRepresentationInfo.runtimeType})');
    closureRepresentationInfo
        ?.forEachFreeVariable((a, b) => print('  free: $a->$b'));
    closureRepresentationInfo
        ?.forEachBoxedVariable((a, b) => print('  boxed: $a->$b'));
  }

  /// Compute a string representation of the data stored for [local] in [info].
  String computeLocalValue(Local local) {
    Features features = new Features();
    if (scopeInfo.localIsUsedInTryOrSync(local)) {
      features.add('inTry');
      // TODO(johnniwinther,efortuna): Should this be enabled and checked?
      //Expect.isTrue(capturedScope.localIsUsedInTryOrSync(local));
    } else {
      //Expect.isFalse(capturedScope.localIsUsedInTryOrSync(local));
    }
    if (capturedScope.isBoxedVariable(local)) {
      features.add('boxed');
    }
    if (capturedScope.context == local) {
      // TODO(johnniwinther): This shouldn't happen! Remove branch/throw error
      // when we verify it can't happen.
      features.add('error-box');
    }
    if (capturedScope is CapturedLoopScope) {
      CapturedLoopScope loopScope = capturedScope;
      if (loopScope.boxedLoopVariables.contains(local)) {
        features.add('loop');
      }
    }
    // TODO(johnniwinther,efortuna): Add more info?
    return features.getText();
  }

  String computeObjectValue(MemberEntity member) {
    Features features = new Features();

    void addLocals(String name, forEach(f(Local local, _))) {
      List<String> names = <String>[];
      forEach((Local local, _) {
        if (local is BoxLocal) {
          names.add(boxNames[local]);
        } else {
          names.add(local.name);
        }
      });
      String value = names.isEmpty ? null : '[${(names..sort()).join(',')}]';
      if (features.containsKey(name)) {
        Expect.equals(
            features[name], value, "Inconsistent values for $name on $member.");
      }
      features[name] = value;
    }

    if (scopeInfo.thisLocal != null) {
      features['hasThis'] = '';
    }
    if (capturedScope.requiresContextBox) {
      var keyword = 'boxed';
      addLocals(keyword, capturedScope.forEachBoxedVariable);
      features['box'] = '(${boxNames[capturedScope.context]} which holds '
          '${features[keyword]})';
      features.remove(keyword);
    }

    if (closureRepresentationInfo != null) {
      addLocals('free', closureRepresentationInfo.forEachFreeVariable);
      if (closureRepresentationInfo.closureClassEntity != null) {
        addLocals('fields', (f(Local local, _)) {
          _closedWorld.elementEnvironment.forEachInstanceField(
              closureRepresentationInfo.closureClassEntity,
              (_, FieldEntity field) {
            if (_closedWorld.fieldAnalysis.getFieldData(field).isElided) return;
            f(closureRepresentationInfo.getLocalForField(field), field);
          });
        });
      }
    }

    return features.getText();
  }
}
