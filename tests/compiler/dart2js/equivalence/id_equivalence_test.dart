// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/kernel.dart';
import 'package:compiler/src/tree/nodes.dart' as ast;
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

const List<String> dataDirectories = const <String>[
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
        await checkCode(annotatedCode, checkMemberEquivalence,
            options: [Flags.useKernel]);
      }
    }
  });
}

/// Check that the ids in [expectedMap] map to equivalent nodes/elements in
/// the AST and kernel IR.
void checkMemberEquivalence(
    Compiler compiler, Map<Id, String> expectedMap, MemberEntity _member) {
  MemberElement member = _member;
  ResolvedAst resolvedAst = member.resolvedAst;
  if (resolvedAst.kind != ResolvedAstKind.PARSED) return;
  Map<Id, ast.Node> astMap = <Id, ast.Node>{};
  Map<Id, Element> elementMap = <Id, Element>{};
  AstIdFinder astFinder = new AstIdFinder(resolvedAst.elements);
  for (Id id in expectedMap.keys.toList()) {
    var result = astFinder.find(resolvedAst.node, id);
    if (result is ast.Node) {
      astMap[id] = result;
    } else if (result is AstElement) {
      elementMap[id] = result;
    }
  }

  Kernel kernel = compiler.backend.kernelTask.kernel;
  Map<Id, ir.Node> irMap = <Id, ir.Node>{};
  ir.Node node = kernel.elementToIr(member);
  IrIdFinder irFinder = new IrIdFinder();
  for (Id id in expectedMap.keys.toList()) {
    ir.Node result = irFinder.find(node, id);
    if (result != null) {
      irMap[id] = result;
    }
  }

  elementMap.forEach((Id id, _element) {
    AstElement element = _element;
    ir.Node irNode = irMap[id];
    Expect.equals(kernel.elementToIr(element), irNode,
        "Element mismatch on $id = $element");
    expectedMap.remove(id);
    irMap.remove(id);
  });
  astMap.forEach((Id id, ast.Node astNode) {
    ir.Node irNode = irMap[id];
    Expect.equals(
        kernel.nodeToAst[irNode], astNode, "Node mismatch on $id = $astNode");
    expectedMap.remove(id);
    irMap.remove(id);
  });
  Expect.isTrue(irMap.isEmpty, "Extra IR ids: $irMap");
}
