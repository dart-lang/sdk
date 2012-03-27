// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;
import com.google.common.annotations.VisibleForTesting;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ErrorSeverity;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.SystemLibraryManager;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.HasSourceInfo;
import com.google.dart.compiler.common.SourceInfo;
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
  private final boolean suppressSdkWarnings;
  
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
    this.suppressSdkWarnings = context.getCompilerConfiguration().getCompilerOptions()
        .suppressSdkWarnings();
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

  void declare(Element element, ErrorCode errorCode, ErrorCode warningCode) {
    String name = element.getName();
    Element existingLocalElement = scope.findLocalElement(name);
    // Check for duplicate declaration in the enclosing scope.
    if (existingLocalElement == null && warningCode != null) {
      Element existingElement = scope.findElement(scope.getLibrary(), name);
      if (existingElement != null) {
        if (!Elements.isConstructorParameter(element)
            && !Elements.isParameterOfMethodWithoutBody(element)
            && !(Elements.isStaticContext(element) && !Elements.isStaticContext(existingElement))
            && !existingElement.getModifiers().isAbstractField()) {
          SourceInfo nameSourceInfo = element.getNameLocation();
          String existingLocation = Elements.getRelativeElementLocation(element, existingElement);
          // TODO(scheglov) remove condition once HTML will be fixed to don't have duplicates.
          // http://code.google.com/p/dart/issues/detail?id=1060
          if (!Elements.isLibrarySource(element.getSourceInfo().getSource(), "html.dart")
              && !Elements.isLibrarySource(element.getSourceInfo().getSource(), "dom.dart")) {
            onError(nameSourceInfo, warningCode, name, existingElement, existingLocation);
          }
        }
      }
    }
    // Check for duplicate declaration in the same scope.
    if (existingLocalElement != null && errorCode != null) {
      SourceInfo nameSourceInfo = element.getNameLocation();
      String existingLocation = Elements.getRelativeElementLocation(element, existingLocalElement);
      onError(nameSourceInfo, errorCode, name, existingLocation);
    }
    // Declare, may be hide existing element.
    scope.declareElement(name, element);
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

  /**
   * To resolve the  class<typeparameters?> specified for extends on a class definition.
   */
  InterfaceType resolveClass(DartTypeNode node, boolean isStatic, boolean isFactory) {
    if (node == null) {
      return null;
    }

    Type type = resolveType(node, isStatic, isFactory, ResolverErrorCode.NO_SUCH_TYPE);
    if (!isClassType(type)) {
      onError(node.getIdentifier(), ResolverErrorCode.NOT_A_CLASS, type);
      type = typeProvider.getDynamicType();
    }

    node.setType(type);
    return (InterfaceType) type;
  }

  InterfaceType resolveInterface(DartTypeNode node, boolean isStatic, boolean isFactory) {
    Type type = resolveType(node, isStatic, isFactory, ResolverErrorCode.NO_SUCH_TYPE);
    if (type.getKind() != TypeKind.DYNAMIC && !isClassOrInterfaceType(type)) {
      onError(node.getIdentifier(), ResolverErrorCode.NOT_A_CLASS_OR_INTERFACE, type);
      type = typeProvider.getDynamicType();
    }

    node.setType(type);
    return (InterfaceType) type;
  }

  Type resolveType(DartTypeNode node, boolean isStatic, boolean isFactory, ErrorCode errorCode) {
    if (node == null) {
      return null;
    } else {
      Type type = resolveType(node, node.getIdentifier(), node.getTypeArguments(), isStatic, isFactory,
                         errorCode);
      recordTypeIdentifier(node.getIdentifier(), type.getElement());
      return type;
    }
  }

  protected <E extends Element> E recordTypeIdentifier(DartNode node, E element) {
    node.getClass();
    if (node instanceof DartPropertyAccess) {
      recordTypeIdentifier(((DartPropertyAccess)node).getQualifier(),
                           element.getEnclosingElement());
      return recordTypeIdentifier(((DartPropertyAccess)node).getName(), element);
    } else if (node instanceof DartIdentifier) {
      if (element == null) {
        // TypeAnalyzer will diagnose unresolved identifiers.
        return null;
      }
      node.setElement(element);
    } else {
      throw internalError(node, "Unexpected node: %s", node);
    }
    return element;
  }

  Type resolveType(DartNode diagnosticNode, DartNode identifier, List<DartTypeNode> typeArguments,
                   boolean isStatic, boolean isFactory, ErrorCode errorCode) {
    Element element = resolveName(identifier);
    ElementKind elementKind = ElementKind.of(element);
    switch (elementKind) {
      case TYPE_VARIABLE: {
        TypeVariableElement typeVariableElement = (TypeVariableElement) element;
        if (!isFactory && isStatic &&
            typeVariableElement.getDeclaringElement().getKind().equals(ElementKind.CLASS)) {

          // Check that type variable is not shadowing any element in enclosing context.
          Scope libraryScope = scope.getLibrary().getScope();
          String name = element.getName();
          Element existingElement = libraryScope.findElement(scope.getLibrary(), name);

          switch(ElementKind.of(existingElement)) {
            case CLASS:
            case FUNCTION_TYPE_ALIAS:
            return instantiateParameterizedType((ClassElement)existingElement,
                                                diagnosticNode,
                                                typeArguments,
                                                isStatic,
                                                isFactory,
                                                errorCode);
            case NONE:
              onError(identifier, ResolverErrorCode.TYPE_VARIABLE_IN_STATIC_CONTEXT,
                      identifier);
              return typeProvider.getDynamicType();

            default:
              onError(identifier, TypeErrorCode.NOT_A_TYPE, identifier, elementKind);
              return typeProvider.getDynamicType();
          }
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
            isFactory,
            errorCode);
      case NONE:
        if (Elements.isIdentifierName(identifier, "void")) {
          return typeProvider.getVoidType();
        }
        if (Elements.isIdentifierName(identifier, "Dynamic")) {
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
                                             boolean isFactory,
                                             ErrorCode errorCode) {
    List<Type> typeParameters = element.getTypeParameters();
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
        onError(node, wrongNumberErrorCode, element.getType(), typeArgumentNodes.size(), typeParameters.size());
      }
      int index = 0;
      if (typeArgumentNodes != null) {
        for (DartTypeNode typeNode : typeArgumentNodes) {
          Type type = resolveType(typeNode, isStatic, isFactory, errorCode);
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
        typeArguments[i] = resolveType(typeArgumentNodes.get(i), isStatic, isFactory, errorCode);
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

  /*
   * Interpret this node as a name reference,
   */
  Element resolveName(DartNode node) {
    return node.accept(new Selector());
  }

  MethodElement declareFunction(DartFunctionExpression node) {
    MethodElement element = Elements.methodFromFunctionExpression(node, Modifiers.NONE);
    if (node.getFunctionName() != null) {
      declare(
          element,
          ResolverErrorCode.DUPLICATE_FUNCTION_EXPRESSION,
          ResolverErrorCode.DUPLICATE_FUNCTION_EXPRESSION_WARNING);
    }
    return element;
  }

  void pushFunctionScope(DartFunctionExpression x) {
    pushScope(x.getFunctionName() == null ? "<function>" : x.getFunctionName());
  }

  void pushFunctionAliasScope(DartFunctionTypeAlias x) {
    pushScope(x.getName().getName() == null ? "<function>" : x.getName().getName());
  }

  AssertionError internalError(HasSourceInfo node, String message, Object... arguments) {
    message = String.format(message, arguments);
    context.onError(new DartCompilationError(node, ResolverErrorCode.INTERNAL_ERROR,
                                                      message));
    return new AssertionError("Internal error: " + message);
  }

  @Override
  public void onError(HasSourceInfo hasSourceInfo, ErrorCode errorCode, Object... arguments) {
    onError(hasSourceInfo.getSourceInfo(), errorCode, arguments);
  }

  public void onError(SourceInfo sourceInfo, ErrorCode errorCode, Object... arguments) {
    if (suppressSdkWarnings && errorCode.getErrorSeverity() == ErrorSeverity.WARNING) {
      Source source = sourceInfo.getSource();
      if (source != null && SystemLibraryManager.isDartUri(source.getUri())) {
        return;
      }
    }
    context.onError(new DartCompilationError(sourceInfo, errorCode, arguments));
  }

  class Selector extends ASTVisitor<Element> {
    @Override
    public Element visitNode(DartNode node) {
      throw internalError(node, "Unexpected node: %s", node);
    }

    @Override
    public Element visitPropertyAccess(DartPropertyAccess node) {
      Element element = node.getQualifier().accept(this);
      if (element != null) {
        switch (element.getKind()) {
          case LIBRARY :
            Scope elementScope = ((LibraryElement) element).getScope();
            return elementScope.findElement(scope.getLibrary(), node.getPropertyName());
          case CLASS :
            return Elements.findElement((ClassElement) element, node.getPropertyName());
        }
      }
      return null;
    }

    @Override
    public Element visitIdentifier(DartIdentifier node) {
      String name = node.getName();
      return scope.findElement(scope.getLibrary(), name);
    }
  }
}
