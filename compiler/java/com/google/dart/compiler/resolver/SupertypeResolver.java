// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.collect.ImmutableSet;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeKind;

import java.util.List;
import java.util.Set;

/**
 * Resolves the super class, interfaces, default implementation and
 * bounds type parameters of classes in a DartUnit.
 */
public class SupertypeResolver {
  private static final Set<String> BLACK_LISTED_TYPES = ImmutableSet.of(
      "Dynamic",
      "Function",
      "bool",
      "num",
      "int",
      "double",
      "String");

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
  private class ClassElementResolver extends ASTVisitor<Void> {
    @Override
    public Void visitClass(DartClass node) {
      ClassElement classElement = node.getElement();

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
        supertype = classContext.resolveClass(superclassNode, false, false);
        supertype.getClass(); // Quick null check.
      }
      if (supertype != null) {
        if (Elements.isTypeNode(superclassNode, BLACK_LISTED_TYPES)
            && !isCoreLibrarySource(node.getSourceInfo().getSource())) {
          topLevelContext.onError(
              superclassNode,
              ResolverErrorCode.BLACK_LISTED_EXTENDS,
              superclassNode);
        }
        classElement.setSupertype(supertype);
      } else {
        assert classElement.getName().equals("Object") : classElement;
      }

      if (node.getDefaultClass() != null) {
        Element defaultClassElement = classContext.resolveName(node.getDefaultClass().getExpression());
        if (ElementKind.of(defaultClassElement).equals(ElementKind.CLASS)) {
          Elements.setDefaultClass(classElement, (InterfaceType)defaultClassElement.getType());
          node.getDefaultClass().setType(defaultClassElement.getType());
        }
      }

      if (node.getInterfaces() != null) {
        for (DartTypeNode intNode : node.getInterfaces()) {
          InterfaceType intElement = classContext.resolveInterface(intNode, false, false);
          Elements.addInterface(classElement, intElement);
          // Dynamic can not be used as interface.
          if (Elements.isTypeNode(intNode, BLACK_LISTED_TYPES)
              && !isCoreLibrarySource(node.getSourceInfo().getSource())) {
            topLevelContext.onError(intNode, ResolverErrorCode.BLACK_LISTED_IMPLEMENTS, intNode);
            continue;
          }
          // May be unresolved type, error already reported, ignore.
          if (intElement.getKind() == TypeKind.DYNAMIC) {
            continue;
          }
        }
      }
      setBoundsOnTypeParameters(classElement.getTypeParameters(), classContext);
      return null;
    }

    @Override
    public Void visitFunctionTypeAlias(DartFunctionTypeAlias node) {
      ResolutionContext resolutionContext = topLevelContext.extend(node.getElement());
      Elements.addInterface(node.getElement(), typeProvider.getFunctionType());
      setBoundsOnTypeParameters(node.getElement().getTypeParameters(), resolutionContext);
      return null;
    }
  }

  private void setBoundsOnTypeParameters(List<Type> typeParameters,
                                         ResolutionContext resolutionContext) {
    for (Type typeParameter : typeParameters) {
      TypeVariableNodeElement variable = (TypeVariableNodeElement) typeParameter.getElement();
      DartTypeParameter typeParameterNode = (DartTypeParameter) variable.getNode();
      DartTypeNode boundNode = typeParameterNode.getBound();
      if (boundNode != null) {
        Type bound =
            resolutionContext.resolveType(
                boundNode,
                false,
                false,
                ResolverErrorCode.NO_SUCH_TYPE,
                ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
        boundNode.setType(bound);
      }
    }
  }

  /**
   * @return <code>true</code> if given {@link Source} represents code library declaration or
   *         implementation.
   */
  static boolean isCoreLibrarySource(Source source) {
    
    // TODO (danrubel) remove these when dartc libraries are removed
    // Old core library file names
    return Elements.isLibrarySource(source, "corelib.dart")
        || Elements.isLibrarySource(source, "corelib_impl.dart")
        
        // New core library file names
        || Elements.isLibrarySource(source, "core_frog.dart")
        || Elements.isLibrarySource(source, "coreimpl_frog.dart")
        || Elements.isLibrarySource(source, "core_runtime.dart")
        || Elements.isLibrarySource(source, "coreimpl_runtime.dart");
  }
}
