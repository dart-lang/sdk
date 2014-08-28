// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The entry point for the command-line version analyzer2dart. */
library analyzer2dart.cmdline;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/element.dart';

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

class CpsGeneratingVisitor extends RecursiveAstVisitor {
  // TODO(johnniwinther)
}

class ClosedWorld {
  // TODO(paulberry): is it a problem to hold on to all the AST's for the
  // duration of tree shaking & CPS generation?
  Map<Element, AstNode> elements = <Element, AstNode>{};
  ClosedWorld();
}

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

void main(List<String> args) {
  // Create the analysis context
  AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();

  // Set up the source factory.
  // TODO(paulberry): do we want to use ExplicitPackageUriResolver?
  List<UriResolver> uriResolvers = [
      new FileUriResolver(),
      new DartUriResolver(DirectoryBasedDartSdk.defaultSdk) /* ,
      new PackageUriResolver(packagesDirectories) */
  ];
  context.sourceFactory = new SourceFactory(uriResolvers);

  // Tell the analysis server about the root
  JavaFile javaFile = new JavaFile(args[0]); // TODO(paulberry): hacky
  Source source = new FileBasedSource.con1(javaFile);
  ChangeSet changeSet = new ChangeSet();
  changeSet.addedSources.add(source);
  context.applyChanges(changeSet);

  // Get the library element associated with the source.
  LibraryElement libraryElement = context.computeLibraryElement(source);

  // Get the resolved AST for main
  FunctionElement entryPointElement = libraryElement.entryPoint;
  if (entryPointElement == null) {
    throw new Exception('No main()!');
  }

  // TODO(brianwilkerson,paulberry,johnniwinther): Perform tree-growing by
  // visiting the ast and feeding the dependencies into a work queue (enqueuer).
  TreeShaker treeShaker = new TreeShaker();
  treeShaker.add(entryPointElement);
  ClosedWorld world = treeShaker.shake(context);

  // TODO(brianwilkerson,paulberry,johnniwinther): Convert the ast into cps by
  // visiting the ast and invoking the ir builder.
  new CpsGeneratingVisitor();

  // TODO(johnniwinther): Convert the analyzer element model into the dart2js
  // element model to fit the needs of the cps encoding above.

  // TODO(johnniwinther): Feed the cps ir into the new dart2dart backend to
  // generate dart file(s).
}
