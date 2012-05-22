// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.type.DynamicType;
import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.Types;

import java.util.Collections;
import java.util.List;

/**
 * Dummy element corresponding to {@link DynamicType}.
 */
class DynamicElementImplementation extends AbstractNodeElement implements DynamicElement {

  private DynamicElementImplementation() {
    super(null, "<dynamic>");
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.DYNAMIC;
  }

  public static DynamicElementImplementation getInstance() {
    return new DynamicElementImplementation();
  }

  @Override
  public void setType(InterfaceType type) {
    throw new UnsupportedOperationException();
  }

  @Override
  public List<Type> getTypeParameters() {
    return Collections.<Type>emptyList();
  }

  @Override
  public InterfaceType getSupertype() {
    return null;
  }

  @Override
  public InterfaceType getDefaultClass() {
    return null;
  }

  @Override
  public void setSupertype(InterfaceType element) {
    throw new UnsupportedOperationException();
  }

  @Override
  public List<Element> getMembers() {
    return Collections.<Element>emptyList();
  }

  @Override
  public List<ConstructorElement> getConstructors() {
    return Collections.<ConstructorElement>emptyList();
  }

  @Override
  public List<InterfaceType> getInterfaces() {
    return Collections.<InterfaceType>emptyList();
  }

  @Override
  public DynamicType getType() {
    return Types.newDynamicType();
  }
  
  @Override
  public boolean isTypeInferred() {
    return false;
  }

  @Override
  public DynamicType getTypeVariable() {
    return getType();
  }

  @Override
  public ClassElement getEnclosingElement() {
    return this;
  }

  @Override
  public boolean isConstructor() {
    return false;
  }
  
  @Override
  public boolean isSynthetic() {
    return true;
  }

  @Override
  public ConstructorElement getDefaultConstructor() {
    throw new UnsupportedOperationException();
  }

  @Override
  public void setDefaultConstructor(ConstructorElement defaultConstructor) {
    throw new UnsupportedOperationException();
  }

  @Override
  public boolean isStatic() {
    return false;
  }

  @Override
  public boolean hasBody() {
    return false;
  }

  @Override
  public boolean isInterface() {
    return false;
  }

  @Override
  public String getNativeName() {
    return null;
  }

  @Override
  public List<VariableElement> getParameters() {
    return Collections.<VariableElement>emptyList();
  }

  @Override
  public Type getReturnType() {
    return getType();
  }

  @Override
  public boolean isDynamic() {
    return true;
  }

  @Override
  public boolean isObject() {
    return false;
  }
  
  @Override
  public String getDeclarationNameWithTypeParameters() {
    return "Dynamic";
  }

  @Override
  public boolean isObjectChild() {
    return false;
  }

  @Override
  public boolean isAbstract() {
    return false;
  }

  @Override
  public Element lookupLocalElement(String name) {
    return this;
  }

  @Override
  public LibraryElement getLibrary() {
    return null;
  }

  @Override
  public Type getBound() {
    return getType();
  }

  @Override
  public Element getDeclaringElement() {
    return this;
  }

  @Override
  public ConstructorElement lookupConstructor(String name) {
    return null;
  }

  @Override
  public FunctionType getFunctionType() {
    return null;
  }

  @Override
  public void setFunctionType(FunctionType functionType) {
  }

  @Override
  public List<InterfaceType> getAllSupertypes() {
    return Collections.emptyList();
  }

  @Override
  public Scope getScope() {
    return null;
  }

  @Override
  public LibraryUnit getLibraryUnit() {
    return null;
  }

  @Override
  public void setEntryPoint(MethodElement element) {
    throw new AssertionError();
  }

  @Override
  public MethodElement getEntryPoint() {
    return null;
  }

  @Override
  public MethodElement getGetter() {
    return null;
  }

  @Override
  public MethodElement getSetter() {
    return null;
  }

  @Override
  public MethodElement getEnclosingFunction() {
    return this;
  }

  @Override
  public ClassElement getClassElement() {
    return this;
  }

  @Override
  public FieldElement getParameterInitializerElement() {
    return this;
  }

  @Override
  public boolean isNamed() {
    return false;
  }

  @Override
  public DartExpression getDefaultValue() {
    return null;
  }

  @Override
  public ClassElement getConstructorType() {
    return this;
  }
  
  @Override
  public String getRawName() {
    return getName();
  }

  @Override
  public void setType(Type type) {
    super.setType(type);
  }
  
  @Override
  public Type getConstantType() {
    return null;
  }
  @Override
  public List<Element> getUnimplementedMembers() {
    return null;
  }
}
