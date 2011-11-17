// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartNodeTraverser;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.DartVariableStatement;
import com.google.dart.compiler.ast.Modifiers;

import java.util.List;


/**
 * Compile-time constants need to infer types, not just in the current units to be resolved, but
 * in all units.  This pass resolves the right hand side of compile-time constants for the later
 * type analysis and cycle detection done in {@link CompileTimeConstantAnalyzer}.
 */
public class CompileTimeConstantResolver {

  private class ConstResolveVisitor extends ResolveVisitor {
    private class ConstExpressionVisitor extends DartNodeTraverser<Void> {

      @Override
      public Void visitPropertyAccess(DartPropertyAccess x) {
        DartNode qualifierNode = x.getQualifier();
        Element qualifier = null;
        if (qualifierNode instanceof DartIdentifier) {
          DartIdentifier qualifierIdent = (DartIdentifier) qualifierNode;
          qualifier = getContext().getScope().findElement(libraryElement,
                                                          qualifierIdent
                                                              .getTargetName());
          qualifierNode.setSymbol(qualifier);
        }

        if (qualifier != null) {
          Element element = null;

          switch (ElementKind.of(qualifier)) {
            case CLASS:
              // Must be a static field.
              element = Elements.findElement(((ClassElement) qualifier), x
                  .getPropertyName());
              break;

            case LIBRARY:
              // Library prefix, lookup the element in the reference library.
              Scope scope = ((LibraryElement) qualifier).getScope();
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
            .findElement(libraryElement, x.getTargetName());
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
      currentHolder = node.getSymbol();
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
      DartFunction functionNode = node.getFunction();
      List<DartParameter> parameters = functionNode.getParams();
      for (DartParameter parameter : parameters) {
        // Then resolve the default values.
        resolveConstantExpression(parameter.getDefaultExpr());
      }
      return null;
    }

    @Override
    public Element visitNewExpression(DartNewExpression node) {
      if (node.isConst()) {
        for (DartExpression arg : node.getArgs()) {
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
