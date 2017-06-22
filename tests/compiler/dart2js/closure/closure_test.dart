// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_backend_strategy.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import 'package:kernel/ast.dart' as ir;

main() {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await for (FileSystemEntity entity in dataDir.list()) {
      print('Checking ${entity.uri}');
      String annotatedCode = await new File.fromUri(entity.uri).readAsString();
      await checkCode(annotatedCode, computeClosureData, compileFromSource);
      await checkCode(annotatedCode, computeKernelClosureData, compileFromDill);
    }
  });
}

/// Compute closure data mapping for [_member] as a [MemberElement].
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
void computeClosureData(Compiler compiler, MemberEntity _member,
    Map<Id, String> actualMap, Map<Id, SourceSpan> sourceSpanMap) {
  MemberElement member = _member;
  ClosureDataLookup<ast.Node> closureDataLookup =
      compiler.backendStrategy.closureDataLookup as ClosureDataLookup<ast.Node>;
  new ClosureAstComputer(compiler.reporter, actualMap, sourceSpanMap,
          member.resolvedAst, closureDataLookup)
      .run();
}

/// Compute closure data mapping for [member] as a kernel based element.
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
void computeKernelClosureData(Compiler compiler, MemberEntity member,
    Map<Id, String> actualMap, Map<Id, SourceSpan> sourceSpanMap) {
  KernelBackendStrategy backendStrategy = compiler.backendStrategy;
  KernelToElementMap elementMap = backendStrategy.elementMap;
  GlobalLocalsMap localsMap = backendStrategy.globalLocalsMapForTesting;
  ClosureDataLookup closureDataLookup = backendStrategy.closureDataLookup;
  new ClosureIrChecker(actualMap, sourceSpanMap, elementMap, member,
          localsMap.getLocalsMap(member), closureDataLookup)
      .run(elementMap.getMemberNode(member));
}

/// Ast visitor for computing closure data.
class ClosureAstComputer extends AbstractResolvedAstComputer {
  final ClosureDataLookup<ast.Node> closureDataLookup;
  final ClosureRepresentationInfo info;

  ClosureAstComputer(
      DiagnosticReporter reporter,
      Map<Id, String> actualMap,
      Map<Id, Spannable> spannableMap,
      ResolvedAst resolvedAst,
      this.closureDataLookup)
      : this.info =
            closureDataLookup.getClosureRepresentationInfo(resolvedAst.element),
        super(reporter, actualMap, spannableMap, resolvedAst);

  @override
  String computeNodeValue(ast.Node node, [AstElement element]) {
    if (element != null && element.isLocal) {
      LocalElement local = element;
      return computeLocalValue(info, local);
    }
    // TODO(johnniwinther,efortuna): Collect data for other nodes?
    return null;
  }

  @override
  String computeElementValue(AstElement element) {
    // TODO(johnniwinther,efortuna): Collect data for the member
    // (has thisLocal, has box, etc.).
    return null;
  }
}

/// Kernel IR visitor for computing closure data.
class ClosureIrChecker extends AbstractIrComputer {
  final ClosureDataLookup<ir.Node> closureDataLookup;
  final ClosureRepresentationInfo info;
  final KernelToLocalsMap _localsMap;

  ClosureIrChecker(
      Map<Id, String> actualMap,
      Map<Id, SourceSpan> sourceSpanMap,
      KernelToElementMap elementMap,
      MemberEntity member,
      this._localsMap,
      this.closureDataLookup)
      : this.info = closureDataLookup.getClosureRepresentationInfo(member),
        super(actualMap, sourceSpanMap);

  @override
  String computeNodeValue(ir.Node node) {
    if (node is ir.VariableDeclaration) {
      Local local = _localsMap.getLocal(node);
      return computeLocalValue(info, local);
    }
    // TODO(johnniwinther,efortuna): Collect data for other nodes?
    return null;
  }

  @override
  String computeMemberValue(ir.Member member) {
    // TODO(johnniwinther,efortuna): Collect data for the member
    // (has thisLocal, has box, etc.).
    return null;
  }
}

/// Compute a string representation of the data stored for [local] in [info].
String computeLocalValue(ClosureRepresentationInfo info, Local local) {
  StringBuffer sb = new StringBuffer();
  if (info.variableIsUsedInTryOrSync(local)) {
    sb.write('inTry');
  }
  // TODO(johnniwinther,efortuna): Add more info (captured, boxed etc.).
  return sb.toString();
}
