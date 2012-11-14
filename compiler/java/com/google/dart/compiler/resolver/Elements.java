// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.base.Objects;
import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;
import com.google.common.collect.Sets;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartClassMember;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNativeBlock;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartObsoleteMetadata;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartSuperExpression;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.resolver.LabelElement.LabeledStatementType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.InterfaceType.Member;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeVariable;
import com.google.dart.compiler.util.Paths;
import com.google.dart.compiler.util.apache.StringUtils;

import java.io.File;
import java.net.URI;
import java.text.MessageFormat;
import java.util.Arrays;
import java.util.List;
import java.util.Set;

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

  static LabelElement statementLabelElement(DartLabel node, String name,
      MethodElement enclosingFunction) {
    return new LabelElementImplementation(node, name, enclosingFunction,
        LabeledStatementType.STATEMENT);
  }

  static LabelElement switchMemberLabelElement(DartLabel node, String name,
      MethodElement enclosingFunction) {
    return new LabelElementImplementation(node, name, enclosingFunction,
        LabeledStatementType.SWITCH_MEMBER_STATEMENT);
  }

  static LabelElement switchLabelElement(DartLabel node, String name,
      MethodElement enclosingFunction) {
    return new LabelElementImplementation(node, name, enclosingFunction,
        LabeledStatementType.SWITCH_STATEMENT);
  }

  public static LibraryElement libraryElement(LibraryUnit libraryUnit) {
    return new LibraryElementImplementation(libraryUnit);
  }
  
  public static void addExportedElement(LibraryElement libraryElement, Element element) {
    ((LibraryElementImplementation) libraryElement).addExportedElements(element);
  }

  public static LibraryElement getLibraryElement(Element element) {
    while (element != null) {
      if (ElementKind.of(element) == ElementKind.LIBRARY) {
        return (LibraryElement) element;
      }
      EnclosingElement enclosingElement = element.getEnclosingElement();
      if (enclosingElement == element) {
        return null;
      }
      element = enclosingElement;
    };
    return null;
  }
  
  /**
   * @return <code>true</code> if "a" and "b" are declared in the same {@link LibraryElement}.
   */
  public static boolean areSameLibrary(Element a, Element b) {
    LibraryElement aLibrary = getLibraryElement(a);
    LibraryElement bLibrary = getLibraryElement(b);
    return Objects.equal(aLibrary, bLibrary);
  }

  @VisibleForTesting
  public static MethodElement methodElement(DartFunctionExpression node, String name) {
    return new MethodElementImplementation(node, name, Modifiers.NONE);
  }

  public static TypeVariableElement typeVariableElement(String name, Type bound) {
    return new TypeVariableElementImplementation(name, bound);
  }

  public static VariableElement variableElement(EnclosingElement owner,
      DartVariable node,
      String name,
      Modifiers modifiers) {
    return new VariableElementImplementation(owner,
        node,
        node.getName().getSourceInfo(),
        name,
        ElementKind.VARIABLE,
        modifiers,
        false,
        null);
  }

  public static VariableElement parameterElement(EnclosingElement owner,
      DartParameter node,
      String name,
      Modifiers modifiers) {
    return new VariableElementImplementation(owner,
        node,
        node.getName().getSourceInfo(),
        name,
        ElementKind.PARAMETER,
        modifiers,
        node.getModifiers().isNamed(),
        node.getDefaultExpr());
  }

  public static SuperElement superElement(DartSuperExpression node, ClassElement cls) {
    return new SuperElementImplementation(node, cls);
  }

  static void addConstructor(ClassElement cls, ConstructorNodeElement constructor) {
    ((ClassElementImplementation) cls).addConstructor(constructor);
  }

  static void addField(EnclosingElement holder, FieldNodeElement field) {
    if (ElementKind.of(holder).equals(ElementKind.CLASS)) {
      ((ClassElementImplementation) holder).addField(field);
    } else if (ElementKind.of(holder).equals(ElementKind.LIBRARY)) {
      ((LibraryElementImplementation) holder).addField(field);
    } else {
      throw new IllegalArgumentException();
    }
  }

  @VisibleForTesting
  public static void addMethod(EnclosingElement holder, MethodNodeElement method) {
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

  static Element findElement(EnclosingElement cls, String name) {
    if (cls instanceof  ClassElementImplementation) {
      return ((ClassElementImplementation) cls).findElement(name);
    }
    return null;
  }

  public static MethodElement methodFromFunctionExpression(DartFunctionExpression node,
                                                           Modifiers modifiers) {
    return MethodElementImplementation.fromFunctionExpression(node, modifiers);
  }

  public static MethodNodeElement methodFromMethodNode(DartMethodDefinition node,
      EnclosingElement holder) {
    return MethodElementImplementation.fromMethodNode(node, holder);
  }

  static ConstructorNodeElement constructorFromMethodNode(DartMethodDefinition node,
                                                      String name,
                                                      ClassElement declaringClass,
                                                      ClassElement constructorType) {
    return ConstructorElementImplementation.fromMethodNode(node, name, declaringClass,
                                                           constructorType);
  }

  public static void setType(Element element, Type type) {
    ((AbstractNodeElement) element).setType(type);
  }

  public static void setOverridden(Element element, Set<Element> overridden) {
    if (element instanceof MethodElementImplementation) {
      ((MethodElementImplementation) element).setOverridden(overridden);
    }
    if (element instanceof FieldElementImplementation) {
      ((FieldElementImplementation) element).setOverridden(overridden);
    }
  }

static FieldElementImplementation fieldFromNode(DartField node,
                                                  EnclosingElement holder,
                                                  DartObsoleteMetadata metadata,
                                                  Modifiers modifiers) {
    return FieldElementImplementation.fromNode(node, holder, metadata, modifiers);
  }

  static ClassElement classFromNode(DartClass node, LibraryElement library) {
    return ClassElementImplementation.fromNode(node, library);
  }

  public static ClassElement classNamed(String name) {
    return ClassElementImplementation.named(name);
  }

  static TypeVariableElement typeVariableFromNode(DartTypeParameter node, EnclosingElement element) {
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

  public static FunctionAliasElement functionTypeAliasFromNode(DartFunctionTypeAlias node,
                                                               LibraryElement library) {
    return FunctionAliasElementImplementation.fromNode(node, library);
  }

  /**
   * @return <code>true</code> if given {@link Element} represents {@link VariableElement} for
   *         parameter in {@link DartMethodDefinition}.
   */
  public static boolean isConstructorParameter(Element element) {
    Element parent = element.getEnclosingElement();
    if (parent instanceof MethodElement) {
      return ((MethodElement) parent).isConstructor();
    }
    return false;
  }

  /**
   * @return <code>true</code> if given {@link Element} represents {@link VariableElement} for
   *         parameter in {@link DartMethodDefinition} without body, or with {@link DartNativeBlock}
   *         as body.
   */
  public static boolean isParameterOfMethodWithoutBody(Element element) {
    if (element instanceof VariableElement) {
      Element parent = element.getEnclosingElement();
      if (parent instanceof MethodElement) {
        MethodElement parentMethod = (MethodElement) parent;
        return !parentMethod.hasBody();
      }
    }
    return false;
  }

  /**
   * @return <code>non-null</code>  {@link MethodElement} if "holder", or one of its
   *         interfaces, or its superclass has {@link FieldElement} with getter.
   */
  public static MethodElement lookupFieldElementGetter(EnclosingElement holder, String name) {
    Element element = holder.lookupLocalElement(name);
    if (element instanceof FieldElement) {
      FieldElement fieldElement = (FieldElement) element;
      MethodElement result = fieldElement.getGetter();
      if (result != null) {
        return fieldElement.getGetter();
      }
    }
    if (holder instanceof ClassElement) {
      ClassElement classHolder = (ClassElement) holder;
      for (InterfaceType interfaceType : classHolder.getInterfaces()) {
        MethodElement result = lookupFieldElementGetter(interfaceType.getElement(), name);
        if (result != null) {
          return result;
        }
      }
      if (classHolder.getSupertype() != null) {
        MethodElement result = lookupFieldElementGetter(classHolder.getSupertype().getElement(),
            name);
        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  /**
   * @return <code>non-null</code> {@link MethodElement} if "holder", or one of its interfaces,
   *         or its superclass has {@link FieldElement} with setter.
   */
  public static MethodElement lookupFieldElementSetter(EnclosingElement holder, String name) {
    Element element = holder.lookupLocalElement(name);
    if (element instanceof FieldElement) {
      FieldElement fieldElement = (FieldElement) element;
      MethodElement result = fieldElement.getSetter();
      if (result != null) {
        return result;
      }
    }
    if (holder instanceof ClassElement) {
      ClassElement classHolder = (ClassElement)holder;
      for (InterfaceType interfaceType : classHolder.getInterfaces()) {
        MethodElement result = lookupFieldElementSetter(interfaceType.getElement(), name);
        if (result != null) {
          return result;
        }
      }
      if (classHolder.getSupertype() != null) {
        MethodElement result = lookupFieldElementSetter(classHolder.getSupertype().getElement(),
            name);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  /**
   * @return <code>true</code> if {@link DartNode} of given {@link Element} if part of static
   *         {@link DartClassMember} or part of top level declaration.
   */
  public static boolean isStaticContext(Element element) {
    if (element instanceof ClassElement) {
      return true;
    }
    while (element != null) {
      if (element instanceof MethodElement) {
        MethodElement methodElement = (MethodElement) element;
        return methodElement.isStatic() || methodElement.getEnclosingElement()  instanceof LibraryElement;
      }
      if (element instanceof FieldElement) {
        FieldElement fieldElement = (FieldElement) element;
        return fieldElement.isStatic()
            || fieldElement.getEnclosingElement() instanceof LibraryElement;
      }
      if (element instanceof ClassElement) {
        return false;
      }
      element = element.getEnclosingElement();
    }
    return true;
  }

  public static boolean isNonFactoryConstructor(Element method) {
    return !method.getModifiers().isFactory()
        && ElementKind.of(method) == ElementKind.CONSTRUCTOR;
  }

  public static boolean isTopLevel(Element element) {
    return ElementKind.of(element.getEnclosingElement()) == ElementKind.LIBRARY;
  }

  static List<TypeVariable> makeTypeVariables(List<DartTypeParameter> parameterNodes,
                                              EnclosingElement enclosingElement) {
    if (parameterNodes == null) {
      return Arrays.<TypeVariable>asList();
    }
    TypeVariable[] typeVariables = new TypeVariable[parameterNodes.size()];
    int i = 0;
    for (DartTypeParameter parameterNode : parameterNodes) {
      TypeVariable typeVariable =
          Elements.typeVariableFromNode(parameterNode, enclosingElement).getTypeVariable();
      typeVariables[i++] = typeVariable;
      parameterNode.getName().setElement(typeVariable.getElement());
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
    return classElement.getConstructors().isEmpty()
        && (!classElement.isInterface() || classElement.getDefaultClass() != null);
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
    if (methodElement instanceof ConstructorElement) {
      ConstructorElement constructorElement = (ConstructorElement) methodElement;
      return constructorElement.getRawName();
    }
    return methodElement.getName();
  }

  /**
   * @return the number of required (not optional/named) parameters in given {@link MethodElement}.
   */
  public static int getNumberOfRequiredParameters(MethodElement method) {
    int num = 0;
    List<VariableElement> parameters = method.getParameters();
    for (VariableElement parameter : parameters) {
      if (!parameter.isOptional() && !parameter.isNamed()) {
        num++;
      }
    }
    return num;
  }
  
  /**
   * @return the number of optional positional parameters in given {@link MethodElement}.
   */
  public static int getNumberOfOptionalPositionalParameters(MethodElement method) {
    int num = 0;
    List<VariableElement> parameters = method.getParameters();
    for (VariableElement parameter : parameters) {
      if (parameter.isOptional()) {
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
  
  /**
   * Prepares title for {@link TypeErrorCode#DEPRECATED_ELEMENT}.
   */
  public static String getDeprecatedElementTitle(Element element) {
    String title = getUserElementTitle(element);
    return StringUtils.capitalize(title);
  }

  /**
   * @return the user readable title of the given {@link Element}, a little different than
   *         "technical" title returned from {@link Element#toString()}.
   */
  public static String getUserElementTitle(Element element) {
    return MessageFormat.format("{0} ''{1}''", getUserElementKindTitle(element), element.getName());
  }

  /**
   * @return the user readable title of the given {@link Element}'s {@link ElementKind}, a little
   *         different than "technical" title returned from {@link Element#toString()}.
   */
  private static String getUserElementKindTitle(Element element) {
    ElementKind kind = element.getKind();
    switch (kind) {
      case CLASS:
        if (((ClassElement) element).isInterface()) {
          return "interface";
        }
        break;
      case METHOD:
        if (isTopLevel(element)) {
          return "top-level function";
        }
        break;
      case FIELD:
        if (isTopLevel(element)) {
          return "top-level variable";
        }
        break;
    }
    String title = kind.toString();
    title = StringUtils.replace(title, "_", " ");
    title = title.toLowerCase();
    return title;
  }

  /**
   * @return the {@link String} which contains user-readable description of "target" {@link Element}
   *         location relative to "source".
   */
  public static String getRelativeElementLocation(Element source, Element target) {
    // Prepare "target" SourceInfo.
    SourceInfo targetInfo;
    {
      targetInfo = target.getNameLocation();
      if (targetInfo == null) {
        return "unknown";
      }
    }
    // Prepare path to the target unit from source unit.
    String targetPath;
    {
      SourceInfo sourceInfo = source.getSourceInfo();
      targetPath = getRelativeSourcePath(sourceInfo, targetInfo);
    }
    // Prepare (may be empty) target class name.
    String targetClassName;
    {
      EnclosingElement targetEnclosing = target.getEnclosingElement();
      ClassElement targetClass = getEnclosingClassElement(targetEnclosing);
      targetClassName = targetClass != null ? targetClass.getName() : "";
    }
    // Format location string.
    if (StringUtils.isEmpty(targetClassName)) {
      return MessageFormat.format("{0} line:{1} col:{2}", targetPath, targetInfo.getLine(),
          targetInfo.getColumn());
    } else {
      return MessageFormat.format("{0} class:{1} line:{2} col:{3}", targetPath, targetClassName,
          targetInfo.getLine(), targetInfo.getColumn());
    }
  }

  /**
   * @return the relative or absolute path from "source" to "target".
   */
  private static String getRelativeSourcePath(SourceInfo source, SourceInfo target) {
    Source sourceSource = source.getSource();
    Source targetSource = target.getSource();
    return getRelativeSourcePath(sourceSource, targetSource);
  }

  /**
   * @return the relative or absolute path from "source" to "target".
   */
  public static String getRelativeSourcePath(Source sourceSource, Source targetSource) {
    // If both source are from file, prepare relative path.
    if (sourceSource != null && targetSource != null) {
      URI sourceUri = sourceSource.getUri();
      URI targetUri = targetSource.getUri();
      if (Objects.equal(sourceUri.getScheme(), "file")
          && Objects.equal(targetUri.getScheme(), "file")) {
        return Paths.relativePathFor(new File(sourceUri.getPath()), new File(targetUri.getPath()));
      }
    }
    // Else return absolute path (including dart:// protocol).
    if (targetSource != null) {
      URI targetUri = targetSource.getUri();
      return targetUri.toString();
    }
    // No source for target.
    return "<unknown>";
  }

  /**
   * @return the full location of the given {@link Element} - library and unit.
   */
  public static String getLibraryUnitLocation(Element element) {
    try {
      StringBuilder sb = new StringBuilder();
      // library URI
      String libraryUri;
      {
        LibraryUnit libraryUnit = getDeclaringLibrary(element).getLibraryUnit();
        libraryUri = libraryUnit.getSource().getUri().toString();
        sb.append(libraryUri);
      }
      // unit URI
      SourceInfo sourceInfo = element.getSourceInfo();
      {
        String unitUri = sourceInfo.getSource().getUri().toString();
        if (!unitUri.equals(libraryUri)) {
          sb.append(" ");
          sb.append(unitUri);
        }
      }
      // line
      sb.append(":");
      sb.append(sourceInfo.getLine());
      // done
      return sb.toString();
    } catch (Throwable e) {
      return "<exception>";
    }
  }

  /**
   * @return the enclosing {@link ClassElement} (may be same if already given {@link ClassElement}),
   *         may be <code>null</code> if top level element.
   */
  public static ClassElement getEnclosingClassElement(Element element) {
    while (element != null) {
      if (element instanceof ClassElement) {
        return (ClassElement) element;
      }
      element = element.getEnclosingElement();
    }
    return null;
  }

  /**
   * @return <code>true</code> if the given {@link DartTypeNode} is type with one of the given
   *         names.
   */
  public static boolean isTypeNode(DartTypeNode typeNode, Set<String> names) {
    if (typeNode != null) {
      DartNode identifier = typeNode.getIdentifier();
      String typeName = getIdentifierName(identifier);
      return names.contains(typeName);
    }
    return false;
  }

  /**
   * @return <code>true</code> if the given {@link DartTypeNode} is type with given name.
   */
  public static boolean isTypeNode(DartTypeNode typeNode, String name) {
    return typeNode != null && isIdentifierName(typeNode.getIdentifier(), name);
  }

  /**
   * @return <code>true</code> if the given {@link DartNode} is type identifier with given name.
   */
  public static boolean isIdentifierName(DartNode identifier, String name) {
    String identifierName = getIdentifierName(identifier);
    return Objects.equal(identifierName, name);
  }

  /**
   * @return <code>true</code> if the given {@link ConstructorElement} is a synthetic default
   *         constructor.
   */
  public static boolean isSyntheticConstructor(ConstructorElement element) {
    return element != null && element.isSynthetic();
  }

  /**
   * @return <code>true</code> if the given {@link ConstructorElement} is a default constructor.
   */
  public static boolean isDefaultConstructor(ConstructorElement element) {
    return element != null
        && element.getParameters().isEmpty()
        && getRawMethodName(element).equals(element.getEnclosingElement().getName());
  }
  
  public static void setRedirectingFactoryConstructor(ConstructorElement source,
      ConstructorElement target) {
    ((ConstructorElementImplementation) source).setRedirectingFactoryConstructor(target);
  }

  /**
   * @return the name of given {@link DartNode} if it is {@link DartIdentifier}, or
   *         <code>null</code> otherwise.
   */
  private static String getIdentifierName(DartNode identifier) {
    if (identifier != null && identifier instanceof DartIdentifier) {
      return ((DartIdentifier) identifier).getName();
    }
    return null;
  }

  /**
   * @return <code>true</code> if given {@link Source} represents library with given name.
   */
  public static boolean isLibrarySource(Source source, String name) {
    LibrarySource library = null;
    if (source instanceof LibrarySource) {
      library = (LibrarySource) source;
    }
    if (source instanceof DartSource) {
      DartSource dartSource = (DartSource) source;
      library = dartSource.getLibrary();
    }
    if (library != null) {
      String libraryName = library.getName();
      return libraryName.endsWith(name);
    }
    return false;
  }
  
  /**
   * @return <code>true</code> if given {@link Source} represents library with given name.
   */
  public static boolean isDart2JsLibrarySource(Source source) {
    if (source instanceof DartSource) {
      DartSource dartSource = (DartSource) source;
      LibrarySource library = dartSource.getLibrary();
      if (library != null) {
        String libraryName = library.getName();
        return libraryName.contains("lib/compiler/implementation/");
      }
    }
    return false;
  }

  /**
   * @return <code>true</code> if given {@link Source} represents code library declaration or
   *         implementation.
   */
  public static boolean isCoreLibrarySource(Source source) {
    if (source != null && source.getUri() != null
        && source.getUri().toString().equals("libraries.dart")) {
      return true;
    }
    // TODO (danrubel) remove these when dartc libraries are removed
    // Old core library file names
    return Elements.isLibrarySource(source, "/core/corelib.dart")
        || Elements.isLibrarySource(source, "/core/corelib_impl.dart")
        // New core library file names
        || Elements.isLibrarySource(source, "/core/core.dart");
  }
  
  public static boolean isHtmlLibrarySource(Source source) {
    return Elements.isLibrarySource(source, "/html/dartium/html_dartium.dart");
  }

  /**
   * @return the {@link LibraryElement} which declares given {@link Element}.
   */
  public static LibraryElement getDeclaringLibrary(Element element) {
    while (element != null) {
      if (element instanceof LibraryElement) {
        return (LibraryElement) element;
      }
      element = element.getEnclosingElement();
    }
    return null;
  }

  /**
   * @return <code>true</code> if "element" is accessible in "scopeLibrary".
   */
  public static boolean isAccessible(LibraryElement scopeLibrary, Element element) {
    if (element != null && StringUtils.startsWith(element.getName(), "_")) {
      return Objects.equal(scopeLibrary, getDeclaringLibrary(element));
    }
    return true;
  }

  /**
   * @return <code>true</code> if given {@link Element} if {@link MethodElement} for
   *         function "identical".
   */
  public static boolean isFunctionIdentical(Element element) {
    if (element instanceof MethodElement) {
      MethodElement methodElement = (MethodElement) element;
      return Objects.equal(methodElement.getName(), "identical")
          && methodElement.getEnclosingElement() instanceof LibraryElement
          && methodElement.getEnclosingElement().getName().equals("dart://core/core.dart");
    }
    return false;
  }

  /**
   * @return <code>true</code> if normal field or abstract field with getter.
   */
  public static boolean isFieldWithGetter(FieldElement fieldElement) {
    if (fieldElement.getModifiers().isAbstractField()) {
      return fieldElement.getGetter() != null;
    }
    return true;
  }
  
  public static boolean isAbstractFieldWithoutGetter(Element element) {
    if (element instanceof FieldElement) {
      FieldElement fieldElement = (FieldElement) element;
      return fieldElement.getModifiers().isAbstractField() && fieldElement.getGetter() == null;
    }
    return false;
  }

  public static boolean hasClassMember(ClassElement clazz, String name) {
    if (clazz.lookupLocalElement(name) != null) {
      return true;
    }
    for (InterfaceType interfaceType : clazz.getInterfaces()) {
      if (hasClassMember(interfaceType.getElement(), name)) {
        return true;
      }
    }
    if (clazz.getSupertype() != null) {
      if (hasClassMember(clazz.getSupertype().getElement(), name)) {
        return true;
      }
    }
    return false;
  }
  
  /**
   * @return <code>true</code> if given {@link FieldElement} is explicitly declared static, or is
   *         static implicitly.
   */
  public static boolean isStaticField(FieldElement field) {
    Modifiers modifiers = field.getModifiers();
    return modifiers.isStatic();
  }

  /**
   * @return <code>true</code> if given {@link InterfaceType} overrides "noSuchMethod".
   */
  public static boolean handlesNoSuchMethod(InterfaceType type) {
    Member member = type.lookupMember("noSuchMethod");
    if (member == null) {
      return false;
    }
    Source source = member.getElement().getSourceInfo().getSource();
    return !isCoreLibrarySource(source);
  }
  
  public static DuplicateElement createDuplicateElement(Element oldElement, Element newElement) {
    return new DuplicateElementImplementation(oldElement, newElement);
  }
  
  
  public static List<Element> getAllMembers(ClassElement classElement) {
    List<Element> allMembers = Lists.newArrayList();
    Set<ClassElement> visited = Sets.newHashSet();
    addAllMembers(visited, allMembers, classElement);
    return allMembers;
  }
  
  private static void addAllMembers(Set<ClassElement> visited, List<Element> allMembers, ClassElement classElement) {
    if (classElement == null) {
      return;
    }
    if (visited.contains(classElement)) {
      return;
    }
    visited.add(classElement);
    Iterables.addAll(allMembers, classElement.getMembers());
    {
      InterfaceType superType = classElement.getSupertype();
      if (superType != null)
        addAllMembers(visited, allMembers, superType.getElement());
    }
    for (InterfaceType intf : classElement.getInterfaces()) {
      addAllMembers(visited, allMembers, intf.getElement());
    }
  }
}
