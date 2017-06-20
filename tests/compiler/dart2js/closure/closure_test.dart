// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/tree/nodes.dart';
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main() {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await for (FileSystemEntity entity in dataDir.list()) {
      print('Checking ${entity.uri}');
      String annotatedCode = await new File.fromUri(entity.uri).readAsString();
      await checkCode(annotatedCode, checkClosureData);
    }
  });
}

void checkClosureData(
    Compiler compiler, Map<Id, String> expectedMap, MemberEntity _member) {
  MemberElement member = _member;
  new ClosureChecker(compiler.reporter, expectedMap, member.resolvedAst,
          compiler.backendStrategy.closureDataLookup as ClosureDataLookup<Node>)
      .check();
}

class ClosureChecker extends AbstractResolvedAstChecker {
  final ClosureDataLookup<Node> closureDataLookup;
  final ClosureRepresentationInfo info;

  ClosureChecker(DiagnosticReporter reporter, Map<Id, String> expectedMap,
      ResolvedAst resolvedAst, this.closureDataLookup)
      : this.info =
            closureDataLookup.getClosureRepresentationInfo(resolvedAst.element),
        super(reporter, expectedMap, resolvedAst);

  @override
  String computeNodeValue(Node node, [AstElement element]) {
    if (element != null && element.isLocal) {
      LocalElement local = element;
      StringBuffer sb = new StringBuffer();
      if (info.variableIsUsedInTryOrSync(local)) {
        sb.write('inTry');
      }
      return sb.toString();
    }
    return null;
  }

  @override
  String computeElementValue(AstElement element) {
    return null;
  }
}
