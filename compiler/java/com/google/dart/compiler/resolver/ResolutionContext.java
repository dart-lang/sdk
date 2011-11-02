// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartNodeTraverser;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeKind;
import com.google.dart.compiler.type.TypeVariable;

import java.util.Arrays;
import java.util.List;

/**
 * Resolution context for resolution of Dart programs. The initial context is
 * derived from the library scope, which is then extended with class scope,
 * method scope, and block scope as the program is traversed.
 */
@VisibleForTesting
public class ResolutionContext implements ResolutionErrorListener {
  private Scope scope;
  private final DartCompilerContext context;
  private final CoreTypeProvider typeProvider;

  ResolutionContext(String name, LibraryElement library, DartCompilerContext context,
                    CoreTypeProvider typeProvider) {
    this(new Scope(name, library), context, typeProvider);
  }

  @VisibleForTesting
  public ResolutionContext(Scope scope, DartCompilerContext context,
                           CoreTypeProvider typeProvider) {
    this.scope = scope;
    this.context = context;
    this.typeProvider = typeProvider;
  }

  ResolutionContext(LibraryUnit unit, DartCompilerContext context, CoreTypeProvider typeProvider) {
    this(unit.getElement().getScope(), context, typeProvider);
  }

  @VisibleForTesting
  public ResolutionContext extend(ClassElement element) {
    return new ResolutionContext(new ClassScope(element, scope), context, typeProvider);
  }

  ResolutionContext extend(String name) {
    return new ResolutionContext(new Scope(name, scope.getLibrary(), scope), context, typeProvider);
  }

  Scope getScope() {
    return scope;
  }

  void declare(Element element) {
    Element existingElement = scope.declareElement(element.getName(), element);
    if (existingElement != null) {
      onError(element.getNode(), ResolverErrorCode.DUPLICATE_DEFINITION,
          element.getName());
    }
  }

  void pushScope(String name) {
    scope = new Scope(name, scope.getLibrary(), scope);
  }

  void popScope() {
    scope = scope.getParent();
  }

  /**
   * Returns <code>true</code> if the type is dynamic or an interface type where
   * {@link ClassElement#isInterface()} equals <code>isInterface</code>.
   */
  private boolean isInterfaceEquals(Type type, boolean isInterface) {
    switch (type.getKind()) {
      case DYNAMIC:
        // Considered to be a match.
        return true;

      case INTERFACE:
        InterfaceType interfaceType = (InterfaceType) type;
        ClassElement element = interfaceType.getElement();
        return (element != null && element.isInterface() == isInterface);

      default:
        break;
    }

    return false;
  }

  /**
   * Returns <code>true</code> if the type is dynamic or is a class type.
   */
  private boolean isClassType(Type type) {
    return isInterfaceEquals(type, false);
  }
 
  /**
   * Returns <code>true</code> if the type is a class or interface type.
   */
  private boolean isClassOrInterfaceType(Type type) {
    return type.getKind() == TypeKind.INTERFACE
        && ((InterfaceType) type).getElement() != null;
  }

  InterfaceType resolveClass(DartTypeNode node, boolean isStatic) {
    if (node == null) {
      return null;
    }

    Type type = resolveType(node, isStatic, ResolverErrorCode.NO_SUCH_TYPE);
    if (!isClassType(type)) {
      onError(node.getIdentifier(), ResolverErrorCode.NOT_A_CLASS, type);
      type = typeProvider.getDynamicType();
    }

    node.setType(type);
    return (InterfaceType) type;
  }

  InterfaceType resolveInterface(DartTypeNode node, boolean isStatic) {
    Type type = resolveType(node, isStatic, ResolverErrorCode.NO_SUCH_TYPE);
    if (type.getKind() != TypeKind.DYNAMIC && !isClassOrInterfaceType(type)) {
      onError(node.getIdentifier(), ResolverErrorCode.NOT_A_CLASS_OR_INTERFACE, type);
      type = typeProvider.getDynamicType();
    }

    node.setType(type);
    return (InterfaceType) type;
  }

  Type resolveType(DartTypeNode node, boolean isStatic, ErrorCode errorCode) {
    if (node == null) {
      return null;
    } else {
      return resolveType(node, node.getIdentifier(), node.getTypeArguments(), isStatic, errorCode);
    }
  }

  Type resolveType(DartNode diagnosticNode, DartNode identifier, List<DartTypeNode> typeArguments,
                   boolean isStatic, ErrorCode errorCode) {
    Element element = resolveName(identifier);
    ElementKind elementKind = ElementKind.of(element);
    switch (elementKind) {
      case TYPE_VARIABLE: {
        TypeVariableElement typeVariableElement = (TypeVariableElement) element;
        if (isStatic &&
            typeVariableElement.getDeclaringElement().getKind().equals(ElementKind.CLASS)) {
          onError(identifier, ResolverErrorCode.TYPE_VARIABLE_IN_STATIC_CONTEXT,
                          identifier);
          return typeProvider.getDynamicType();
        }
        return makeTypeVariable(typeVariableElement, typeArguments);
      }
      case CLASS:
      case FUNCTION_TYPE_ALIAS:
        return instantiateParameterizedType(
            (ClassElement) element,
            diagnosticNode,
            typeArguments,
            isStatic,
            errorCode);
      case NONE:
        if (identifier.toString().equals("void")) {
          return typeProvider.getVoidType();
        }
        if (identifier.toString().equals("Dynamic")) {
          return typeProvider.getDynamicType();
        }
        break;
      default:
        onError(identifier, TypeErrorCode.NOT_A_TYPE, identifier, elementKind);
    }
    onError(identifier, errorCode, identifier);
    return typeProvider.getDynamicType();
  }

  InterfaceType instantiateParameterizedType(ClassElement element, DartNode node,
                                             List<DartTypeNode> typeArgumentNodes,
                                             boolean isStatic,
                                             ErrorCode errorCode) {
    List<? extends Type> typeParameters = element.getTypeParameters();
    Type[] typeArguments;
    if (typeArgumentNodes == null || typeArgumentNodes.size() != typeParameters.size()) {
      typeArguments = new Type[typeParameters.size()];
      for (int i = 0; i < typeArguments.length; i++) {
        typeArguments[i] = typeProvider.getDynamicType();
      }
      if (typeArgumentNodes != null && typeArgumentNodes.size() > 0) {
        ErrorCode wrongNumberErrorCode =
            errorCode instanceof ResolverErrorCode
                ? ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS
                : TypeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS;
        onError(node, wrongNumberErrorCode, element.getType());
      }
      int index = 0;
      if (typeArgumentNodes != null) {
        for (DartTypeNode typeNode : typeArgumentNodes) {
          Type type = resolveType(typeNode, isStatic, errorCode);
          typeNode.setType(type);
          if (index < typeArguments.length) {
            typeArguments[index] = type;
          }
          index++;
        }
      }
    } else {
      typeArguments = new Type[typeArgumentNodes.size()];
      for (int i = 0; i < typeArguments.length; i++) {
        typeArguments[i] = resolveType(typeArgumentNodes.get(i), isStatic, errorCode);
        typeArgumentNodes.get(i).setType(typeArguments[i]);
      }
    }
    return element.getType().subst(Arrays.asList(typeArguments), typeParameters);
  }

  private TypeVariable makeTypeVariable(TypeVariableElement element,
                                        List<DartTypeNode> typeArguments) {
    for (DartTypeNode typeArgument : typeArguments) {
      onError(typeArgument, ResolverErrorCode.EXTRA_TYPE_ARGUMENT);
    }
    return element.getTypeVariable();
  }

  Element resolveName(DartNode node) {
    return node.accept(new Selector());
  }

  MethodElement declareFunction(DartFunctionExpression node) {
    MethodElement element = Elements.methodFromFunctionExpression(node, Modifiers.NONE);
    if (node.getFunctionName() != null) {
      declare(element);
    }
    return element;
  }

  void pushFunctionScope(DartFunctionExpression x) {
    pushScope(x.getFunctionName() == null ? "<function>" : x.getFunctionName());
  }

  AssertionError internalError(DartNode node, String message, Object... arguments) {
    message = String.format(message, arguments);
    context.onError(new DartCompilationError(node, ResolverErrorCode.INTERNAL_ERROR,
                                                      message));
    return new AssertionError("Internal error: " + message);
  }

  @Override
  public void onError(DartNode node, ErrorCode errorCode, Object... arguments) {
    context.onError(new DartCompilationError(node, errorCode, arguments));
  }

  public boolean shouldWarnOnNoSuchType() {
    return context.shouldWarnOnNoSuchType();
  }

  class Selector extends DartNodeTraverser<Element> {
    @Override
    public Element visitNode(DartNode node) {
      throw internalError(node, "Unexpected node: %s", node);
    }

    @Override
    public Element visitPropertyAccess(DartPropertyAccess node) {
      Element element = node.getQualifier().accept(this);
      switch (element.getKind()) {
        case LIBRARY:
          Scope elementScope = ((LibraryElement) element).getScope();
          return elementScope.findElement(scope.getLibrary(), node.getPropertyName());

        case CLASS:
          return Elements.findElement((ClassElement) element, node.getPropertyName());

        default:
          return null;
      }
    }

    @Override
    public Element visitIdentifier(DartIdentifier node) {
      String name = node.getTargetName();
      return scope.findElement(scope.getLibrary(), name);
    }
  }
}
