// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartInitializer;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartRedirectConstructorInvocation;
import com.google.dart.compiler.ast.DartSuperConstructorInvocation;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.DartVariableStatement;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.type.InterfaceType;

import java.util.List;


/**
 * Compile-time constants need to infer types, not just in the current units to be resolved, but
 * in all units.  This pass resolves the right hand side of compile-time constants for the later
 * type analysis and cycle detection done in {@link CompileTimeConstantAnalyzer}.
 */
public class CompileTimeConstantResolver {

  private class ConstResolveVisitor extends ResolveVisitor {
    private class ConstExpressionVisitor extends ASTVisitor<Void> {

      @Override
      public Void visitPropertyAccess(DartPropertyAccess x) {
        DartNode qualifierNode = x.getQualifier();
        Element qualifier = null;
        if (qualifierNode instanceof DartIdentifier) {
          DartIdentifier qualifierIdent = (DartIdentifier) qualifierNode;
          qualifier = getContext().getScope().findElement(libraryElement,
                                                          qualifierIdent
                                                              .getName());
          qualifierNode.setElement(qualifier);
        }

        if (qualifier != null) {
          Element element = null;

          switch (ElementKind.of(qualifier)) {
            case CLASS:
              // Must be a static field.
              element = Elements.findElement(((ClassElement) qualifier), x
                  .getPropertyName());
              break;

            case LIBRARY_PREFIX:
              // Library prefix, lookup the element in the reference library.
              Scope scope = ((LibraryPrefixElement) qualifier).getScope();
              element = scope
                  .findElement(scope.getLibrary(), x.getPropertyName());
              break;

            default:
              break;
          }
          if (element != null) {
            recordElement(x, element);
          }
        }
        return null;
      }

      @Override
      public Void visitIdentifier(DartIdentifier x) {
        x.visitChildren(this);

        Element element = getContext().getScope()
            .findElement(libraryElement, x.getName());
        if (element != null) {
          recordElement(x, element);
        }
        return null;
      }

      @Override
      public Void visitSuperConstructorInvocation(DartSuperConstructorInvocation x) {
        x.visitChildren(this);

        String name = x.getName() == null ? "" : x.getName().getName();
        InterfaceType supertype = ((ClassElement) currentHolder).getSupertype();
        ConstructorElement element = (supertype == null) ?
            null : Elements.lookupConstructor(supertype.getElement(), name);
        if (element != null) {
          recordElement(x, element);
        }
        return null;
      }

      @Override
      public Void visitRedirectConstructorInvocation(DartRedirectConstructorInvocation x) {
        x.visitChildren(this);

        String name = x.getName() == null ? "" : x.getName().getName();
        InterfaceType supertype = ((ClassElement) currentHolder).getSupertype();
        ConstructorElement element = (supertype == null) ?
            null : Elements.lookupConstructor(supertype.getElement(), name);
        if (element != null) {
          recordElement(x, element);
        }
        return null;
      }
    }

    private final LibraryElement libraryElement;
    private EnclosingElement currentHolder;
    private final ResolutionContext topLevelContext;
    private ResolutionContext context;

    private ConstResolveVisitor(DartUnit unit,
        DartCompilerContext compilerContext, Scope scope,
        CoreTypeProvider typeProvider) {
      super(typeProvider);
      this.libraryElement = unit.getLibrary() == null ? null : unit
          .getLibrary().getElement();
      this.topLevelContext = this.context = new ResolutionContext(scope,
          compilerContext, typeProvider);
      this.currentHolder = libraryElement;
    }

    private void beginClassContext(final DartClass node) {
      assert !ElementKind.of(currentHolder).equals(ElementKind.CLASS) : "nested class?";
      currentHolder = node.getElement();
      context = context.extend((ClassElement) currentHolder);
    }

    private void endClassContext() {
      currentHolder = libraryElement;
      context = topLevelContext;
    }

    @Override
    ResolutionContext getContext() {
      return context;
    }

    @Override
    boolean isStaticContext() {
      return true;
    }
    
    boolean isFactoryContext() {
      return false;
    }

    private void resolveConstantExpression(DartExpression expression) {
      if (expression != null) {
        expression.accept(new ConstExpressionVisitor());
      }
    }

    @Override
    public Element visitClass(DartClass node) {
      assert !ElementKind.of(currentHolder).equals(ElementKind.CLASS) : "nested class?";
      beginClassContext(node);
      this.visit(node.getMembers());
      endClassContext();
      return null;
    }

    @Override
    public Element visitField(DartField node) {
      resolveConstantExpression(node.getValue());
      return null;
    }

    @Override
    public Element visitMethodDefinition(DartMethodDefinition node) {
      MethodElement member = node.getElement();
      ResolutionContext previousContext = context;
      context = context.extend(member.getName());
      DartFunction functionNode = node.getFunction();
      List<DartParameter> parameters = functionNode.getParameters();
      for (DartParameter parameter : parameters) {
        getContext().declare(parameter.getElement(), null);
        // Then resolve the default values.
        resolveConstantExpression(parameter.getDefaultExpr());
      }
      Element element = node.getElement();
      if (ElementKind.of(element) == ElementKind.CONSTRUCTOR &&
        node.getModifiers().isConstant()) {
        for (DartInitializer initializer : node.getInitializers()) {
          DartExpression initializerValue = initializer.getValue();
          resolveConstantExpression(initializerValue);
        }
      }
      context = previousContext;
      // resolve reference in body
      DartBlock body = node.getFunction().getBody();
      if (body != null) {
        super.visitBlock(body);
      }
      return null;
    }

    @Override
    public Element visitNewExpression(DartNewExpression node) {
      if (node.isConst()) {
        for (DartExpression arg : node.getArguments()) {
          resolveConstantExpression(arg);
        }
      }
      return null;
    }

    @Override
    public Element visitParameter(DartParameter node) {
      resolveConstantExpression(node.getDefaultExpr());
      return null;
    }

    @Override
    public Element visitVariableStatement(DartVariableStatement node) {
      for (DartVariable variable : node.getVariables()) {
        Modifiers modifiers = node.getModifiers();
        if (modifiers.isStatic() && modifiers.isFinal()
            && variable.getValue() != null) {
          resolveConstantExpression(variable.getValue());
        }
      }
      return null;
    }
  }

  public void exec(DartUnit unit,
              DartCompilerContext compilerContext, CoreTypeProvider typeProvider) {
    exec(unit, compilerContext, unit.getLibrary().getElement().getScope(), typeProvider);
  }

  @VisibleForTesting
  public void exec(DartUnit unit, DartCompilerContext compilerContext,
                   Scope scope, CoreTypeProvider typeProvider) {
    unit.accept(new ConstResolveVisitor(unit, compilerContext, scope,
        typeProvider));
  }
}
