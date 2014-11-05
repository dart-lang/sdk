// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.treeShaker;

import 'dart:collection';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:compiler/implementation/universe/universe.dart';

import 'closed_world.dart';
import 'util.dart';
import 'semantic_visitor.dart';
import 'identifier_semantics.dart';

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
   * The fields and top-level variables statically accessed by the method.
   */
  // TODO(johnniwinther): Should we split this into reads and writes?
  final List<PropertyInducingElement> accesses = <PropertyInducingElement>[];

  /**
   * The selectors used by the method to perform dynamic invocation.
   */
  final List<Selector> invokes = <Selector>[];

  /**
   * The classes that are instantiated by the method.
   */
  // TODO(johnniwinther,paulberry): Register instantiated types.
  // TODO(johnniwinther,paulberry): Register checked types from is/as checks,
  // catch clauses and (checked) type annotations.
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
    Declaration declaration = method.node;
    MethodAnalysis analysis = new MethodAnalysis(declaration);
    if (declaration != null) {
      declaration.accept(new TreeShakingVisitor(analysis));
    } else if (method is ConstructorElement) {
      // This constructor has no associated declaration in the AST.  Either it
      // is a default constructor for an ordinary class, or it's a synthetic
      // constructor associated with a mixin.  For now we assume it's a default
      // constructor, in which case all we need to do is record the class as
      // being instantiated by this method.  TODO(paulberry): handle the
      // mixin case.
      analysis.instantiates.add(method.enclosingElement);
    } else {
      // This is an executable element with no associated declaration in the
      // AST, and it's not a constructor.  TODO(paulberry): can this ever
      // happen?
      throw new UnimplementedError();
    }
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
    } else if (selector.kind == SelectorKind.SETTER) {
      // accessor.name uses the convention that setter names end in '='.
      String selectorNameWithEquals = '${selector.name}=';
      for (PropertyAccessorElement accessor in classElement.accessors) {
        if (accessor.isSetter && selectorNameWithEquals == accessor.name) {
          if (accessor.isSynthetic) {
            // This accessor is implied by the corresponding field declaration.
            // TODO(paulberry): should we distinguish reads and writes?
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
  final LocalReachabilityComputer _localComputer =
      new LocalReachabilityComputer();

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
      if (element is ExecutableElement) {
        MethodAnalysis analysis = _localComputer.analyzeMethod(element);
        _world.executableElements[element] = analysis.declaration;
        analysis.calls.forEach(_addElement);
        analysis.invokes.forEach(_addSelector);
        analysis.instantiates.forEach(_addElement);
        analysis.accesses.forEach(_addElement);
      } else if (element is ClassElement) {
        ClassAnalysis analysis = _localComputer.analyzeClass(element);
        _world.instantiatedClasses[element] = analysis.declaration;
        for (Selector selector in _selectors) {
          _matchClassToSelector(element, selector);
        }
      } else if (element is FieldElement) {
        VariableDeclaration declaration = element.node;
        _world.fields[element] = declaration;
      } else if (element is TopLevelVariableElement) {
        VariableDeclaration declaration = element.node;
        _world.variables[element] = declaration;
      } else {
        throw new Exception(
            'Unexpected element type while tree shaking: '
                '$element (${element.runtimeType})');
      }
    }
    return _world;
  }
}

class TreeShakingVisitor extends SemanticVisitor {
  final MethodAnalysis analysis;

  TreeShakingVisitor(this.analysis);

  Source get currentSource => analysis.declaration.element.source;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorElement staticElement = node.staticElement;
    if (staticElement != null) {
      analysis.calls.add(staticElement);
    } else {
      // TODO(paulberry): deal with this situation.  This can happen, for
      // example, in the case "main() => new Unresolved();" (which is a
      // warning, not an error).
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitDynamicInvocation(MethodInvocation node,
      AccessSemantics semantics) {
    analysis.invokes.add(createSelectorFromMethodInvocation(
        node.argumentList, node.methodName.name));
  }

  @override
  void visitLocalFunctionInvocation(MethodInvocation node,
      AccessSemantics semantics) {
    // Locals don't need to be tree shaken.
  }

  @override
  void visitLocalVariableInvocation(MethodInvocation node,
      AccessSemantics semantics) {
    // Locals don't need to be tree shaken.
  }

  @override
  void visitParameterInvocation(MethodInvocation node,
      AccessSemantics semantics) {
    // Locals don't need to be tree shaken.
  }

  @override
  void visitStaticFieldInvocation(MethodInvocation node,
      AccessSemantics semantics) {
    // Invocation of a static field.
    analysis.accesses.add(semantics.element);
    analysis.invokes.add(createSelectorFromMethodInvocation(
        node.argumentList, 'call'));
  }

  @override
  void visitStaticMethodInvocation(MethodInvocation node,
      AccessSemantics semantics) {
    analysis.calls.add(semantics.element);
  }

  @override
  void visitStaticPropertyInvocation(MethodInvocation node,
      AccessSemantics semantics) {
    // Invocation of a property.  TODO(paulberry): handle this.
    super.visitStaticPropertyInvocation(node, semantics);
  }

  void handleDynamicAccess(AccessSemantics semantics) {
    if (semantics.isRead) {
      analysis.invokes.add(
          new Selector.getter(semantics.identifier.name, null));
    }
    if (semantics.isWrite) {
      // Selector.setter constructor uses the convention that setter names
      // don't end in '='.
      analysis.invokes.add(
          new Selector.setter(semantics.identifier.name, null));
    }
  }

  @override
  void visitDynamicAccess(AstNode node, AccessSemantics semantics) {
    handleDynamicAccess(semantics);
  }

  @override
  void visitLocalFunctionAccess(AstNode node, AccessSemantics semantics) {
    // Locals don't need to be tree shaken.
  }

  @override
  void visitLocalVariableAccess(AstNode node, AccessSemantics semantics) {
    // Locals don't need to be tree shaken.
  }

  @override
  void visitParameterAccess(AstNode node, AccessSemantics semantics) {
    // Locals don't need to be tree shaken.
  }

  @override
  void visitStaticFieldAccess(AstNode node, AccessSemantics semantics) {
    analysis.accesses.add(semantics.element);
  }

  @override
  void visitStaticMethodAccess(AstNode node, AccessSemantics semantics) {
    // Method tear-off.  TODO(paulberry): implement.
    super.visitStaticMethodAccess(node, semantics);
  }

  @override
  void visitStaticPropertyAccess(AstNode node, AccessSemantics semantics) {
    // TODO(paulberry): implement.
    super.visitStaticPropertyAccess(node, semantics);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // TODO(paulberry): handle parameter list.
    node.initializers.accept(this);
    node.body.accept(this);
    if (node.factoryKeyword == null) {
      // This is a generative constructor.  Figure out if it is redirecting.
      // If it isn't, then the constructor instantiates the class so we need to
      // add the class to analysis.instantiates.  (If it is redirecting, then
      // we don't need to, because the redirected-to constructor will take care
      // of that).
      if (node.initializers.length != 1 || node.initializers[0] is! RedirectingConstructorInvocation) {
        analysis.instantiates.add(node.element.enclosingElement);
      }
    } else if (node.redirectedConstructor != null) {
      if (node.redirectedConstructor.staticElement == null) {
        // Factory constructor redirects to a non-existent constructor.
        // TODO(paulberry): handle this.
        throw new UnimplementedError();
      } else {
        analysis.calls.add(node.redirectedConstructor.staticElement);
      }
    }
  }

  @override
  void
      visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    // Note: we don't have to worry about node.staticElement being
    // null, because that would have been detected by the analyzer and
    // reported as a compile time error.
    analysis.calls.add(node.staticElement);
  }

  @override
  void handleAssignmentExpression(AssignmentExpression node) {
    // Don't special-case assignment expressions.
  }
}
