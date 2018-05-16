// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.constant.utilities;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart'
    show ConstructorElementHandle;
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/task/dart.dart';

ConstructorElementImpl getConstructorImpl(ConstructorElement constructor) {
  while (constructor is ConstructorMember) {
    constructor = (constructor as ConstructorMember).baseElement;
  }
  if (constructor is ConstructorElementHandle) {
    constructor = (constructor as ConstructorElementHandle).actualElement;
  }
  return constructor;
}

/**
 * Callback used by [ReferenceFinder] to report that a dependency was found.
 */
typedef void ReferenceFinderCallback(ConstantEvaluationTarget dependency);

/**
 * An [AstCloner] that copies the necessary information from the AST to allow
 * constants to be evaluated.
 */
class ConstantAstCloner extends AstCloner {
  final bool previewDart2;

  ConstantAstCloner(this.previewDart2) : super(true);

  @override
  Annotation visitAnnotation(Annotation node) {
    Annotation annotation = super.visitAnnotation(node);
    annotation.element = node.element;
    return annotation;
  }

  @override
  ConstructorName visitConstructorName(ConstructorName node) {
    ConstructorName name = super.visitConstructorName(node);
    name.staticElement = node.staticElement;
    return name;
  }

  @override
  FunctionExpression visitFunctionExpression(FunctionExpression node) {
    FunctionExpression expression = super.visitFunctionExpression(node);
    expression.element = node.element;
    return expression;
  }

  @override
  InstanceCreationExpression visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    InstanceCreationExpression expression =
        super.visitInstanceCreationExpression(node);
    if (previewDart2 && node.keyword == null) {
      if (node.isConst) {
        expression.keyword = new KeywordToken(Keyword.CONST, node.offset);
      } else {
        expression.keyword = new KeywordToken(Keyword.NEW, node.offset);
      }
    }
    expression.staticElement = node.staticElement;
    return expression;
  }

  @override
  ListLiteral visitListLiteral(ListLiteral node) {
    ListLiteral literal = super.visitListLiteral(node);
    if (previewDart2 && node.constKeyword == null && node.isConst) {
      literal.constKeyword = new KeywordToken(Keyword.CONST, node.offset);
    }
    return literal;
  }

  @override
  MapLiteral visitMapLiteral(MapLiteral node) {
    MapLiteral literal = super.visitMapLiteral(node);
    if (previewDart2 && node.constKeyword == null && node.isConst) {
      literal.constKeyword = new KeywordToken(Keyword.CONST, node.offset);
    }
    return literal;
  }

  @override
  RedirectingConstructorInvocation visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation invocation =
        super.visitRedirectingConstructorInvocation(node);
    invocation.staticElement = node.staticElement;
    return invocation;
  }

  @override
  SimpleIdentifier visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier identifier = super.visitSimpleIdentifier(node);
    identifier.staticElement = node.staticElement;
    return identifier;
  }

  @override
  SuperConstructorInvocation visitSuperConstructorInvocation(
      SuperConstructorInvocation node) {
    SuperConstructorInvocation invocation =
        super.visitSuperConstructorInvocation(node);
    invocation.staticElement = node.staticElement;
    return invocation;
  }

  @override
  TypeName visitTypeName(TypeName node) {
    TypeName typeName = super.visitTypeName(node);
    typeName.type = node.type;
    return typeName;
  }
}

/**
 * A visitor used to traverse the AST structures of all of the compilation units
 * being resolved and build the full set of dependencies for all constant
 * expressions.
 */
class ConstantExpressionsDependenciesFinder extends RecursiveAstVisitor {
  /**
   * The constants whose values need to be computed.
   */
  HashSet<ConstantEvaluationTarget> dependencies =
      new HashSet<ConstantEvaluationTarget>();

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      _find(node);
    } else {
      super.visitInstanceCreationExpression(node);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      _find(node);
    } else {
      super.visitListLiteral(node);
    }
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      _find(node);
    } else {
      super.visitMapLiteral(node);
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _find(node.expression);
    node.statements.accept(this);
  }

  void _find(Expression node) {
    if (node != null) {
      ReferenceFinder referenceFinder = new ReferenceFinder(dependencies.add);
      node.accept(referenceFinder);
    }
  }
}

/**
 * A visitor used to traverse the AST structures of all of the compilation units
 * being resolved and build tables of the constant variables, constant
 * constructors, constant constructor invocations, and annotations found in
 * those compilation units.
 */
class ConstantFinder extends RecursiveAstVisitor<Object> {
  /**
   * The elements and AST nodes whose constant values need to be computed.
   */
  List<ConstantEvaluationTarget> constantsToCompute =
      <ConstantEvaluationTarget>[];

  /**
   * A flag indicating whether instance variables marked as "final" should be
   * treated as "const".
   */
  bool treatFinalInstanceVarAsConst = false;

  @override
  Object visitAnnotation(Annotation node) {
    super.visitAnnotation(node);
    ElementAnnotation elementAnnotation = node.elementAnnotation;
    if (elementAnnotation == null) {
      // Analyzer ignores annotations on "part of" directives and on enum
      // constant declarations.
      assert(node.parent is PartOfDirective ||
          node.parent is EnumConstantDeclaration);
    } else {
      constantsToCompute.add(elementAnnotation);
    }
    return null;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    bool prevTreatFinalInstanceVarAsConst = treatFinalInstanceVarAsConst;
    if (resolutionMap
        .elementDeclaredByClassDeclaration(node)
        .constructors
        .any((ConstructorElement e) => e.isConst)) {
      // Instance vars marked "final" need to be included in the dependency
      // graph, since constant constructors implicitly use the values in their
      // initializers.
      treatFinalInstanceVarAsConst = true;
    }
    try {
      return super.visitClassDeclaration(node);
    } finally {
      treatFinalInstanceVarAsConst = prevTreatFinalInstanceVarAsConst;
    }
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    super.visitConstructorDeclaration(node);
    if (node.constKeyword != null) {
      ConstructorElement element = node.element;
      if (element != null) {
        constantsToCompute.add(element);
        constantsToCompute.addAll(element.parameters);
      }
    }
    return null;
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    super.visitDefaultFormalParameter(node);
    Expression defaultValue = node.defaultValue;
    if (defaultValue != null && node.element != null) {
      constantsToCompute
          .add(resolutionMap.elementDeclaredByFormalParameter(node));
    }
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    Expression initializer = node.initializer;
    VariableElement element = node.element;
    if (initializer != null &&
        (node.isConst ||
            treatFinalInstanceVarAsConst &&
                element is FieldElement &&
                node.isFinal &&
                !element.isStatic)) {
      if (element != null) {
        constantsToCompute.add(element);
      }
    }
    return null;
  }
}

/**
 * An object used to add reference information for a given variable to the
 * bi-directional mapping used to order the evaluation of constants.
 */
class ReferenceFinder extends RecursiveAstVisitor<Object> {
  /**
   * The callback which should be used to report any dependencies that were
   * found.
   */
  final ReferenceFinderCallback _callback;

  /**
   * Initialize a newly created reference finder to find references from a given
   * variable to other variables and to add those references to the given graph.
   * The [_callback] will be invoked for every dependency found.
   */
  ReferenceFinder(this._callback);

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      ConstructorElement constructor = getConstructorImpl(node.staticElement);
      if (constructor != null) {
        _callback(constructor);
      }
    }
    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitLabel(Label node) {
    // We are visiting the "label" part of a named expression in a function
    // call (presumably a constructor call), e.g. "const C(label: ...)".  We
    // don't want to visit the SimpleIdentifier for the label because that's a
    // reference to a function parameter that needs to be filled in; it's not a
    // constant whose value we depend on.
    return null;
  }

  @override
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    super.visitRedirectingConstructorInvocation(node);
    ConstructorElement target = getConstructorImpl(node.staticElement);
    if (target != null) {
      _callback(target);
    }
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    Element staticElement = node.staticElement;
    Element element = staticElement is PropertyAccessorElement
        ? staticElement.variable
        : staticElement;
    if (element is VariableElement && element.isConst) {
      _callback(element);
    }
    return null;
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    super.visitSuperConstructorInvocation(node);
    ConstructorElement constructor = getConstructorImpl(node.staticElement);
    if (constructor != null) {
      _callback(constructor);
    }
    return null;
  }
}
