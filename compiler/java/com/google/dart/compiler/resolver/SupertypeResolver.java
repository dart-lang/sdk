// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartNodeTraverser;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;

/**
 * Resolves the super class, interfaces, default implementation and
 * bounds type parameters of classes in a DartUnit.
 */
public class SupertypeResolver {

  private ResolutionContext topLevelContext;
  private CoreTypeProvider typeProvider;

  public void exec(DartUnit unit, DartCompilerContext context, CoreTypeProvider typeProvider) {
    exec(unit, context, unit.getLibrary().getElement().getScope(), typeProvider);
  }

  public void exec(DartUnit unit, DartCompilerContext compilerContext, Scope libraryScope,
                   CoreTypeProvider typeProvider) {
    this.typeProvider = typeProvider;
    this.topLevelContext = new ResolutionContext(libraryScope, compilerContext, typeProvider);
    unit.accept(new ClassElementResolver());
  }

  // Resolves super class, interfaces and default class of all classes.
  private class ClassElementResolver extends DartNodeTraverser<Void> {
    @Override
    public Void visitClass(DartClass node) {
      ClassElement classElement = node.getSymbol();

      // Make sure that the type parameters are in scope before resolving the
      // super class and interfaces
      ResolutionContext classContext = topLevelContext.extend(classElement);

      DartTypeNode superclassNode = node.getSuperclass();
      InterfaceType supertype;
      if (superclassNode == null) {
        supertype = typeProvider.getObjectType();
        if (supertype.equals(classElement.getType())) {
          // Object has no supertype.
          supertype = null;
        }
      } else {
        supertype = classContext.resolveClass(superclassNode, false);
        supertype.getClass(); // Quick null check.
      }
      if (supertype != null) {
        // TODO(scheglov) check for "extends/implements Dynamic"
        /*if (supertype == typeProvider.getDynamicType()) {
          topLevelContext.onError(superclassNode, ResolverErrorCode.EXTENDS_DYNAMIC, node.getName());
        }*/
        classElement.setSupertype(supertype);
      } else {
        assert classElement.getName().equals("Object") : classElement;
      }

      InterfaceType defaultClass = classContext.resolveClass(node.getDefaultClass(), false);
      if (defaultClass != null) {
        Elements.setDefaultClass(classElement, defaultClass);
        node.getDefaultClass().setType(defaultClass);
      }

      if (node.getInterfaces() != null) {
        for (DartTypeNode cls : node.getInterfaces()) {
          Elements.addInterface(classElement, classContext.resolveInterface(cls, false));
        }
      }

      for (Type typeParameter : classElement.getTypeParameters()) {
        TypeVariableElement variable = (TypeVariableElement) typeParameter.getElement();
        DartTypeParameter typeParameterNode = (DartTypeParameter) variable.getNode();
        DartTypeNode boundNode = typeParameterNode.getBound();
        Type bound;
        if (boundNode != null) {
          bound =
              classContext.resolveType(
                  boundNode,
                  false,
                  ResolverErrorCode.NO_SUCH_TYPE);
          boundNode.setType(bound);
        } else {
          bound = typeProvider.getObjectType();
        }
        variable.setBound(bound);
      }

      return null;
    }

    @Override
    public Void visitFunctionTypeAlias(DartFunctionTypeAlias node) {
      Elements.addInterface(node.getSymbol(), typeProvider.getFunctionType());
      return null;
    }
  }
}
