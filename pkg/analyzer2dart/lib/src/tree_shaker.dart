// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.treeShaker;

import 'dart:collection';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:compiler/implementation/universe/universe.dart';

import 'closed_world.dart';

class TreeShaker {
  List<Element> _queue = <Element>[];
  Set<Element> _alreadyEnqueued = new HashSet<Element>();
  ClosedWorld _world = new ClosedWorld();
  Set<Selector> _selectors = new HashSet<Selector>();

  void addElement(Element element) {
    if (_alreadyEnqueued.add(element)) {
      _queue.add(element);
    }
  }

  void addSelector(Selector selector) {
    if (_selectors.add(selector)) {
      // New selector, so match it against all class methods.
      _world.instantiatedClasses.forEach((ClassElement element, AstNode node) {
        matchClassToSelector(element, selector);
      });
    }
  }

  void matchClassToSelector(ClassElement classElement, Selector selector) {
    // TODO(paulberry): walk through superclasses and mixins as well.  Consider
    // using InheritanceManager to do this.
    for (MethodElement method in classElement.methods) {
      // TODO(paulberry): account for arity and named arguments when matching
      // the selector against the method.
      if (selector.name == method.name) {
        addElement(method);
      }
    }
  }

  ClosedWorld shake(AnalysisContext context) {
    while (_queue.isNotEmpty) {
      Element element = _queue.removeLast();
      print('Tree shaker handling $element');
      CompilationUnit compilationUnit =
          context.getResolvedCompilationUnit(element.source, element.library);
      AstNode identifier =
          new NodeLocator.con1(element.nameOffset).searchWithin(compilationUnit);
      if (element is FunctionElement) {
        FunctionDeclaration declaration =
            identifier.getAncestor((node) => node is FunctionDeclaration);
        _world.executableElements[element] = declaration;
        declaration.accept(new TreeShakingVisitor(this));
      } else if (element is ClassElement) {
        ClassDeclaration declaration =
            identifier.getAncestor((node) => node is ClassDeclaration);
        _world.instantiatedClasses[element] = declaration;
        for (Selector selector in _selectors) {
          matchClassToSelector(element, selector);
        }
      } else if (element is MethodElement) {
        MethodDeclaration declaration =
            identifier.getAncestor((node) => node is MethodDeclaration);
        _world.executableElements[element] = declaration;
        declaration.accept(new TreeShakingVisitor(this));
      } else {
        throw new Exception('Unexpected element type while tree shaking');
      }
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
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorElement staticElement = node.staticElement;
    if (staticElement != null) {
      // TODO(paulberry): Really we should enqueue the constructor, and then
      // when we visit it add the class to the class bucket.
      ClassElement classElement = staticElement.enclosingElement;
      treeShaker.addElement(classElement);
    } else {
      // TODO(paulberry): deal with this situation.  This can happen, for
      // example, in the case "main() => new Unresolved();" (which is a
      // warning, not an error).
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    Element staticElement = node.methodName.staticElement;
    if (staticElement == null) {
      if (node.realTarget != null) {
        // Calling a method that has no known element, e.g.:
        //   dynamic x;
        //   x.foo();
        handleMethodCall(node);
      } else {
        // Calling a toplevel function which has no known element, e.g.
        //   main() {
        //     foo();
        //   }
        // TODO(paulberry): deal with this case.
        throw new UnimplementedError();
      }
    } else if (staticElement is MethodElement) {
      // Invoking a method, e.g.:
      //   class A {
      //     f() {}
      //   }
      //   main() {
      //     new A().f();
      //   }
      // or via implicit this, i.e.:
      //   class A {
      //     f() {}
      //     foo() {
      //       f();
      //     }
      //   }
      // TODO(paulberry): if user-provided types are wrong, this may actually
      // be the PropertyAccessorElement case.
      // TODO(paulberry): do we need to do something different for static
      // methods?
      handleMethodCall(node);
    } else if (staticElement is PropertyAccessorElement) {
      // Invoking a callable getter, e.g.:
      //   typedef FunctionType();
      //   class A {
      //     FunctionType get f { ... }
      //   }
      //   main() {
      //     new A().f();
      //   }
      // or via implicit this, i.e.:
      //   typedef FunctionType();
      //   class A {
      //     FunctionType get f { ... }
      //     foo() {
      //       f();
      //     }
      //   }
      // This also covers the case where the getter is synthetic, because we
      // are getting a field (TODO(paulberry): verify that this is the case).
      // TODO(paulberry): deal with this case.
      // TODO(paulberry): if user-provided types are wrong, this may actually
      // be the MethodElement case.
      throw new UnimplementedError();
    } else if (staticElement is MultiplyInheritedExecutableElement) {
      // TODO(paulberry): deal with this case.
      throw new UnimplementedError();
    } else if (staticElement is LocalElement) {
      // Invoking a callable local, e.g.:
      //   typedef FunctionType();
      //   main() {
      //     FunctionType f = ...;
      //     f();
      //   }
      // or:
      //   main() {
      //     f() { ... }
      //     f();
      //   }
      // or:
      //   f() {}
      //   main() {
      //     f();
      //   }
      // TODO(paulberry): for the moment we are assuming it's a toplevel
      // function.
      treeShaker.addElement(staticElement);
    } else if (staticElement is MultiplyDefinedElement) {
      // TODO(paulberry): do we have to deal with this case?
      throw new UnimplementedError();
    }
    // TODO(paulberry): I believe all the other possibilities are errors, but
    // we should double check.
    super.visitMethodInvocation(node);
  }

  /**
   * Handle a true method call (a MethodInvocation that represents a call to
   * a non-static method).
   */
  void handleMethodCall(MethodInvocation node) {
    int arity = 0;
    List<String> namedArguments = <String>[];
    for (var x in node.argumentList.arguments) {
      if (x is NamedExpression) {
        namedArguments.add(x.name.label.name);
      } else {
        arity++;
      }
    }
    treeShaker.addSelector(
        new Selector.call(node.methodName.name, null, arity, namedArguments));
  }
}
