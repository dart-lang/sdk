// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.treeShaker;

import 'dart:collection';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:compiler/implementation/universe/universe.dart';

import 'closed_world.dart';
import 'package:analyzer2dart/src/identifier_semantics.dart';

/**
 * The result of performing local reachability analysis on a method.
 */
class MethodAnalysis {
  /**
   * The AST for the method.
   */
  final Declaration declaration;

  /**
   * The functions statically called by the method.
   */
  final List<ExecutableElement> calls = <ExecutableElement>[];

  /**
   * The selectors used by the method to perform dynamic invocation.
   */
  final List<Selector> invokes = <Selector>[];

  /**
   * The classes that are instantiated by the method.
   */
  final List<ClassElement> instantiates = <ClassElement>[];

  MethodAnalysis(this.declaration);
}

/**
 * The result of performing local reachability analysis on a class.
 *
 * TODO(paulberry): Do we need to do any other analysis of classes?  (For
 * example, detect annotations that are relevant to mirrors, detect that a
 * class might be used for custom HTML elements, or collect inherited and
 * mixed-in classes).
 */
class ClassAnalysis {
  /**
   * The AST for the class.
   */
  final ClassDeclaration declaration;

  ClassAnalysis(this.declaration);
}

/**
 * This class is responsible for performing local analysis of the source code
 * to provide the information needed to do tree shaking.
 */
class LocalReachabilityComputer {
  /**
   * Perform local reachability analysis of [method].
   */
  MethodAnalysis analyzeMethod(ExecutableElement method) {
    MethodAnalysis analysis = new MethodAnalysis(method.node);
    analysis.declaration.accept(new TreeShakingVisitor(analysis));
    return analysis;
  }

  /**
   * Perform local reachability analysis of [classElement].
   */
  ClassAnalysis analyzeClass(ClassElement classElement) {
    return new ClassAnalysis(classElement.node);
  }

  /**
   * Determine which members of [classElement] are matched by the given
   * [selector].
   *
   * [methods] is populated with all the class methods which are matched by the
   * selector, [accessors] with all the getters and setters which are matched
   * by the selector, and [fields] with all the fields which are matched by the
   * selector.
   */
  void getMatchingClassMembers(ClassElement classElement, Selector selector,
      List<MethodElement> methods, List<PropertyAccessorElement> accessors,
      List<PropertyInducingElement> fields) {
    // TODO(paulberry): should we walk through superclasses and mixins as well
    // here?  Or would it be better to make [TreeShaker] responsible for those
    // relationships (since they are non-local)?  Consider making use of
    // InheritanceManager to do this.
    for (MethodElement method in classElement.methods) {
      // TODO(paulberry): account for arity and named arguments when matching
      // the selector against the method.
      if (selector.name == method.name) {
        methods.add(method);
      }
    }
    if (selector.kind == SelectorKind.GETTER) {
      for (PropertyAccessorElement accessor in classElement.accessors) {
        if (accessor.isGetter && selector.name == accessor.name) {
          if (accessor.isSynthetic) {
            // This accessor is implied by the corresponding field declaration.
            fields.add(accessor.variable);
          } else {
            accessors.add(accessor);
          }
        }
      }
    }
  }
}

/**
 * This class is responsible for driving the tree shaking process, and
 * and performing the global inferences necessary to determine which methods
 * in the source program are reachable.  It makes use of
 * [LocalReachabilityComputer] to do local analysis of individual classes and
 * methods.
 */
class TreeShaker {
  List<Element> _queue = <Element>[];
  Set<Element> _alreadyEnqueued = new HashSet<Element>();
  ClosedWorld _world;
  Set<Selector> _selectors = new HashSet<Selector>();
  final LocalReachabilityComputer _localComputer = new LocalReachabilityComputer();

  TreeShaker(FunctionElement mainFunction)
      : _world = new ClosedWorld(mainFunction);

  void _addElement(Element element) {
    if (_alreadyEnqueued.add(element)) {
      _queue.add(element);
    }
  }

  void _addSelector(Selector selector) {
    if (_selectors.add(selector)) {
      // New selector, so match it against all class methods.
      _world.instantiatedClasses.forEach((ClassElement element, AstNode node) {
        _matchClassToSelector(element, selector);
      });
    }
  }

  void _matchClassToSelector(ClassElement classElement, Selector selector) {
    List<MethodElement> methods = <MethodElement>[];
    List<PropertyAccessorElement> accessors = <PropertyAccessorElement>[];
    List<PropertyInducingElement> fields = <PropertyInducingElement>[];
    _localComputer.getMatchingClassMembers(
        classElement,
        selector,
        methods,
        accessors,
        fields);
    methods.forEach(_addElement);
    accessors.forEach(_addElement);
    fields.forEach(_addElement);
  }

  ClosedWorld shake() {
    _addElement(_world.mainFunction);
    while (_queue.isNotEmpty) {
      Element element = _queue.removeLast();
      print('Tree shaker handling $element');
      if (element is ExecutableElement) {
        MethodAnalysis analysis = _localComputer.analyzeMethod(element);
        _world.executableElements[element] = analysis.declaration;
        analysis.calls.forEach(_addElement);
        analysis.invokes.forEach(_addSelector);
        analysis.instantiates.forEach(_addElement);
      } else if (element is ClassElement) {
        ClassAnalysis analysis = _localComputer.analyzeClass(element);
        _world.instantiatedClasses[element] = analysis.declaration;
        for (Selector selector in _selectors) {
          _matchClassToSelector(element, selector);
        }
      } else if (element is FieldElement) {
        VariableDeclaration declaration = element.node;
        _world.fields[element] = declaration;
      } else {
        throw new Exception('Unexpected element type while tree shaking');
      }
    }
    print('Tree shaking done');
    return _world;
  }
}

Selector createSelectorFromMethodInvocation(MethodInvocation node) {
  int arity = 0;
  List<String> namedArguments = <String>[];
  for (var x in node.argumentList.arguments) {
    if (x is NamedExpression) {
      namedArguments.add(x.name.label.name);
    } else {
      arity++;
    }
  }
  return new Selector.call(node.methodName.name, null, arity, namedArguments);
}

class TreeShakingVisitor extends RecursiveAstVisitor {
  final MethodAnalysis analysis;

  TreeShakingVisitor(this.analysis);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorElement staticElement = node.staticElement;
    if (staticElement != null) {
      // TODO(paulberry): Really we should enqueue the constructor, and then
      // when we visit it add the class to the class bucket.
      ClassElement classElement = staticElement.enclosingElement;
      analysis.instantiates.add(classElement);
    } else {
      // TODO(paulberry): deal with this situation.  This can happen, for
      // example, in the case "main() => new Unresolved();" (which is a
      // warning, not an error).
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target != null) {
      node.target.accept(this);
    }
    node.argumentList.accept(this);
    AccessSemantics semantics = classifyMethodInvocation(node);
    switch (semantics.kind) {
      case AccessKind.DYNAMIC:
        analysis.invokes.add(createSelectorFromMethodInvocation(node));
        break;
      case AccessKind.LOCAL_FUNCTION:
      case AccessKind.LOCAL_VARIABLE:
      case AccessKind.PARAMETER:
        // Locals don't need to be tree shaken.
        break;
      case AccessKind.STATIC_FIELD:
        // Invocation of a field.  TODO(paulberry): handle this.
        throw new UnimplementedError();
      case AccessKind.STATIC_METHOD:
        analysis.calls.add(semantics.element);
        break;
      case AccessKind.STATIC_PROPERTY:
        // Invocation of a property.  TODO(paulberry): handle this.
        throw new UnimplementedError();
      default:
        // Unexpected access kind.
        throw new UnimplementedError();
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target != null) {
      node.target.accept(this);
    }
    _handlePropertyAccess(classifyPropertyAccess(node));
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept(this);
    _handlePropertyAccess(classifyPrefixedIdentifier(node));
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    AccessSemantics semantics = classifySimpleIdentifier(node);
    if (semantics != null) {
      _handlePropertyAccess(semantics);
    }
  }

  void _handlePropertyAccess(AccessSemantics semantics) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC:
        if (semantics.isRead) {
          analysis.invokes.add(
              new Selector.getter(semantics.identifier.name, null));
        }
        if (semantics.isWrite) {
          // TODO(paulberry): implement.
          throw new UnimplementedError();
        }
        break;
      case AccessKind.LOCAL_FUNCTION:
      case AccessKind.LOCAL_VARIABLE:
      case AccessKind.PARAMETER:
        // Locals don't need to be tree shaken.
        break;
      case AccessKind.STATIC_FIELD:
        // TODO(paulberry): implement.
        throw new UnimplementedError();
      case AccessKind.STATIC_METHOD:
        // Method tear-off.  TODO(paulberry): implement.
        break;
      case AccessKind.STATIC_PROPERTY:
        // TODO(paulberry): implement.
        throw new UnimplementedError();
      default:
        // Unexpected access kind.
        throw new UnimplementedError();
    }
  }
}
