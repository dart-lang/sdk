// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.collect.Lists;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartParameterizedNode;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartSuperExpression;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeVariable;

import java.util.Arrays;
import java.util.List;

/**
 * Utility and factory methods for elements.
 */
public class Elements {
  private Elements() {} // Prevent subclassing and instantiation.

  static void setParameterInitializerElement(VariableElement varElement, FieldElement element) {
    ((VariableElementImplementation) varElement).setParameterInitializerElement(element);
  }

  static void setDefaultClass(ClassElement classElement, InterfaceType defaultClass) {
    ((ClassElementImplementation) classElement).setDefaultClass(defaultClass);
  }

  static void addInterface(ClassElement classElement, InterfaceType type) {
    ((ClassElementImplementation) classElement).addInterface(type);
  }

  static LabelElement labelElement(DartLabel node, String name, MethodElement enclosingFunction) {
    return new LabelElementImplementation(node, name, enclosingFunction);
  }

  public static LibraryElement libraryElement(LibraryUnit libraryUnit) {
    return new LibraryElementImplementation(libraryUnit);
  }

  @VisibleForTesting
  public static MethodElement methodElement(DartFunctionExpression node, String name) {
    return new MethodElementImplementation(node, name, Modifiers.NONE);
  }

  public static TypeVariableElement typeVariableElement(DartNode node, String name, Element owner) {
    return new TypeVariableElementImplementation(node, name, owner);
  }

  public static VariableElement variableElement(DartVariable node, String name,
                                                Modifiers modifiers) {
    return new VariableElementImplementation(node, name, ElementKind.VARIABLE, modifiers, false,
                                             null);
  }

  public static VariableElement parameterElement(DartParameter node, String name,
                                                 Modifiers modifiers) {
    return new VariableElementImplementation(node, name, ElementKind.PARAMETER, modifiers,
                                             node.getModifiers().isNamed(),
                                             node.getDefaultExpr());
  }

  public static VariableElement makeVariable(String name) {
    return new VariableElementImplementation(null, name,
                                             ElementKind.VARIABLE, Modifiers.NONE, false, null);
  }

  public static SuperElement superElement(DartSuperExpression node, ClassElement cls) {
    return new SuperElementImplementation(node, cls);
  }

  static void addConstructor(ClassElement cls, ConstructorElement constructor) {
    ((ClassElementImplementation) cls).addConstructor(constructor);
  }

  static void addField(EnclosingElement holder, FieldElement field) {
    if (ElementKind.of(holder).equals(ElementKind.CLASS)) {
      ((ClassElementImplementation) holder).addField(field);
    } else if (ElementKind.of(holder).equals(ElementKind.LIBRARY)) {
      ((LibraryElementImplementation) holder).addField(field);
    } else {
      throw new IllegalArgumentException();
    }
  }

  @VisibleForTesting
  public static void addMethod(EnclosingElement holder, MethodElement method) {
    if (ElementKind.of(holder).equals(ElementKind.CLASS)) {
      ((ClassElementImplementation) holder).addMethod(method);
    } else if (ElementKind.of(holder).equals(ElementKind.LIBRARY)) {
      ((LibraryElementImplementation) holder).addMethod(method);
    } else {
      throw new IllegalArgumentException();
    }
  }

  public static void addParameter(MethodElement method, VariableElement parameter) {
    ((MethodElementImplementation) method).addParameter(parameter);
  }

  static Element findElement(ClassElement cls, String name) {
    if (cls instanceof  ClassElementImplementation) {
      return ((ClassElementImplementation) cls).findElement(name);
    }
    return null;
  }

  public static MethodElement methodFromFunctionExpression(DartFunctionExpression node,
                                                           Modifiers modifiers) {
    return MethodElementImplementation.fromFunctionExpression(node, modifiers);
  }

  @VisibleForTesting
  public static MethodElement methodFromMethodNode(DartMethodDefinition node,
      EnclosingElement holder) {
    return MethodElementImplementation.fromMethodNode(node, holder);
  }

  static ConstructorElement constructorFromMethodNode(DartMethodDefinition node,
                                                      String name,
                                                      ClassElement declaringClass,
                                                      ClassElement constructorType) {
    return ConstructorElementImplementation.fromMethodNode(node, name, declaringClass,
                                                           constructorType);
  }

  @VisibleForTesting
  public static void setType(Element element, Type type) {
    ((AbstractElement) element).setType(type);
  }

  static FieldElementImplementation fieldFromNode(DartField node,
                                                  EnclosingElement holder,
                                                  Modifiers modifiers) {
    return FieldElementImplementation.fromNode(node, holder, modifiers);
  }

  static ClassElement classFromNode(DartClass node, LibraryElement library) {
    return ClassElementImplementation.fromNode(node, library);
  }

  public static ClassElement classNamed(String name) {
    return ClassElementImplementation.named(name);
  }

  static TypeVariableElement typeVariableFromNode(DartTypeParameter node, Element element) {
    return TypeVariableElementImplementation.fromNode(node, element);
  }

  public static DynamicElement dynamicElement() {
    return DynamicElementImplementation.getInstance();
  }

  static ConstructorElement lookupConstructor(ClassElement cls, ClassElement type, String name) {
    return ((ClassElementImplementation) cls).lookupConstructor(type, name);
  }

  static ConstructorElement lookupConstructor(ClassElement cls, String name) {
    if (cls instanceof  ClassElementImplementation) {
      return ((ClassElementImplementation) cls).lookupConstructor(name);
    }
    return null;
  }

  public static MethodElement lookupLocalMethod(ClassElement cls, String name) {
    return ((ClassElementImplementation) cls).lookupLocalMethod(name);
  }

  public static FieldElement lookupLocalField(ClassElement cls, String name) {
    return ((ClassElementImplementation) cls).lookupLocalField(name);
  }

  static ConstructorElement constructorNamed(String name, ClassElement declaringClass,
                                             ClassElement constructorType) {
    return ConstructorElementImplementation.named(name, declaringClass, constructorType);
  }

  public static FunctionAliasElement functionTypeAliasFromNode(DartFunctionTypeAlias node,
                                                               LibraryElement library) {
    return FunctionAliasElementImplementation.fromNode(node, library);
  }

  public static boolean isNonFactoryConstructor(Element method) {
    return !method.getModifiers().isFactory()
        && ElementKind.of(method).equals(ElementKind.CONSTRUCTOR);
  }

  public static boolean isTopLevel(Element element) {
    return ElementKind.of(element.getEnclosingElement()).equals(ElementKind.LIBRARY);
  }

  static List<TypeVariable> makeTypeVariables(List<DartTypeParameter> parameterNodes,
                                              Element element) {
    if (parameterNodes == null) {
      return Arrays.<TypeVariable>asList();
    }
    TypeVariable[] typeVariables = new TypeVariable[parameterNodes.size()];
    int i = 0;
    for (DartTypeParameter parameterNode : parameterNodes) {
      typeVariables[i++] =
          Elements.typeVariableFromNode(parameterNode, element).getTypeVariable();
    }
    return Arrays.asList(typeVariables);
  }

  public static Element voidElement() {
    return VoidElement.getInstance();
  }

  /**
   * Returns true if the class needs an implicit default constructor.
   */
  public static boolean needsImplicitDefaultConstructor(ClassElement classElement) {
    return !classElement.isObject() && classElement.getConstructors().isEmpty();
  }

  /**
   * @return <code>true</code> if {@link #classElement} implements {@link #interfaceElement}.
   */
  public static boolean implementsType(ClassElement classElement, ClassElement interfaceElement) {
    try {
      for (InterfaceType supertype : classElement.getAllSupertypes()) {
        if (supertype.getElement().equals(interfaceElement)) {
          return true;
        }
      }
    } catch (Throwable e) {
    }
    return false;
  }

  /**
   * @return the "name" or "qualifier.name" raw name of {@link DartMethodDefinition} which
   *         corresponds the given {@link MethodElement}.
   */
  public static String getRawMethodName(MethodElement methodElement) {
    DartMethodDefinition method = (DartMethodDefinition) methodElement.getNode();
    // Synthetic method (implicit default constructor).
    if (method == null) {
      return methodElement.getEnclosingElement().getName();
    }
    // Real method.
    DartExpression nameExpression = method.getName();
    return getRawName(nameExpression);
  }

  private static String getRawName(DartNode name) {
    if (name instanceof DartIdentifier) {
      return ((DartIdentifier) name).getTargetName();
    } else if (name instanceof DartParameterizedNode) {
      return getRawName(((DartParameterizedNode) name).getExpression());
    } else {
      DartPropertyAccess propertyAccess = (DartPropertyAccess) name;
      return getRawName(propertyAccess.getQualifier()) + "." + getRawName(propertyAccess.getName());
    }
  }

  /**
   * @return the number of required (not optional/named) parameters in given {@link MethodElement}.
   */
  public static int getNumberOfRequiredParameters(MethodElement method) {
    int num = 0;
    List<VariableElement> parameters = method.getParameters();
    for (VariableElement parameter : parameters) {
      if (!parameter.isNamed()) {
        num++;
      }
    }
    return num;
  }

  /**
   * @return the names for named parameters in given {@link MethodElement}.
   */
  public static List<String> getNamedParameters(MethodElement method) {
    List<String> names = Lists.newArrayList();
    List<VariableElement> parameters = method.getParameters();
    for (VariableElement parameter : parameters) {
      if (parameter.isNamed()) {
        names.add(parameter.getName());
      }
    }
    return names;
  }

  /**
   * @return the names for parameters types in given {@link MethodElement}.
   */
  public static List<String> getParameterTypeNames(MethodElement method) {
    List<String> names = Lists.newArrayList();
    List<VariableElement> parameters = method.getParameters();
    for (VariableElement parameter : parameters) {
      String typeName = parameter.getType().getElement().getName();
      names.add(typeName);
    }
    return names;
  }
}
