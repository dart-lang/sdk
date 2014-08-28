// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.treeShaker;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';

import 'closed_world.dart';

class TreeShaker {
  List<Element> _queue = <Element>[];
  Set<Element> _alreadyEnqueued = new Set<Element>();
  ClosedWorld _world = new ClosedWorld();

  void add(Element e) {
    if (!_alreadyEnqueued.contains(e)) {
      _queue.add(e);
      _alreadyEnqueued.add(e);
    }
  }

  ClosedWorld shake(AnalysisContext context) {
    while (_queue.isNotEmpty) {
      Element e = _queue.removeAt(0);
      print('Tree shaker handling $e');
      CompilationUnit compilationUnit =
          context.getResolvedCompilationUnit(e.source, e.library);
      AstNode identifier =
          new NodeLocator.con1(e.nameOffset).searchWithin(compilationUnit);
      FunctionDeclaration declaration =
          identifier.getAncestor((node) => node is FunctionDeclaration);
      _world.elements[e] = declaration;
      declaration.accept(new TreeShakingVisitor(this));
    }
    print('Tree shaking done');
    return _world;
  }
}

class TreeShakingVisitor extends RecursiveAstVisitor {
  final TreeShaker treeShaker;

  TreeShakingVisitor(this.treeShaker);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    print('Visiting function ${node.name.name}');
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    print('Visiting invocation of ${node.methodName.name}');
    Element staticElement = node.methodName.staticElement;
    if (staticElement != null) {
      // TODO(paulberry): deal with the case where staticElement is
      // not necessarily the exact target.  (Dart2js calls this a
      // "dynamic invocation").  We need a notion of "selector".  Maybe
      // we can use Dart2js selectors.
      treeShaker.add(staticElement);
    } else {
      // TODO(paulberry): deal with this case.
    }
    super.visitMethodInvocation(node);
  }

}

