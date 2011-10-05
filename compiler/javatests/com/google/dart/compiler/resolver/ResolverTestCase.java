// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.testing.TestCompilerContext;
import com.google.dart.compiler.type.DynamicType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.Types;

import junit.framework.TestCase;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * Utility methods for resolver tests.
 */
abstract class ResolverTestCase extends TestCase {

  static Scope resolve(DartUnit unit, TestCompilerContext context) {
    Scope scope = new Scope("library");
    new TopLevelElementBuilder().exec(unit, context);
    new TopLevelElementBuilder().fillInUnitScope(unit, context, scope);
    ClassElement object = (ClassElement) scope.findElement("Object");
    assertNotNull("Cannot resolve Object", object);
    CoreTypeProvider typeProvider = new MockCoreTypeProvider(object);
    new SupertypeResolver().exec(unit, context, scope, typeProvider);
    new MemberBuilder().exec(unit, context, scope, typeProvider);
    new Resolver(context, scope, typeProvider).exec(unit);
    return scope;
  }

  static DartClass makeClass(String name, DartTypeNode supertype, String... typeParameters) {
    return makeClass(name, supertype, Collections.<DartTypeNode>emptyList(), typeParameters);
  }

  static DartClass makeClass(String name, DartTypeNode supertype, List<DartTypeNode> interfaces,
      String... typeParameters) {
    List<DartTypeParameter> parameterNodes = new ArrayList<DartTypeParameter>();
    for (String parameter : typeParameters) {
      parameterNodes.add(makeTypeVariable(parameter));
    }
    List<DartNode> members = Arrays.<DartNode>asList();
    return new DartClass(new DartIdentifier(name), null, supertype,
                         interfaces, members, parameterNodes);
  }

  static DartClass makeInterface(String name, List<DartTypeNode> interfaces,
      DartTypeNode defaultClass, String... typeParameters) {
    List<DartTypeParameter> parameterNodes = new ArrayList<DartTypeParameter>();
    for (String parameter : typeParameters) {
      parameterNodes.add(makeTypeVariable(parameter));
    }
    List<DartNode> members = Arrays.<DartNode>asList();
    return new DartClass(new DartIdentifier(name), null, null,
                         interfaces, members, parameterNodes, defaultClass, true);
  }

  private static DartTypeParameter makeTypeVariable(String name) {
    return new DartTypeParameter(new DartIdentifier(name), null);
  }

  static class MockCoreTypeProvider implements CoreTypeProvider {

    private final InterfaceType intType;
    private final InterfaceType stringType;
    private final InterfaceType functionType;
    private final InterfaceType mapType;
    private final InterfaceType arrayType;
    private final ClassElement objectElement;


    {
      ClassElement intElement = Elements.classNamed("int");
      intType = Types.interfaceType(intElement, Collections.<Type>emptyList());
      ClassElement stringElement = Elements.classNamed("String");
      stringType = Types.interfaceType(stringElement, Collections.<Type>emptyList());
      intElement.setType(intType);
      ClassElement functionElement = Elements.classNamed("Function");
      functionType = Types.interfaceType(functionElement, Collections.<Type>emptyList());
      ClassElement mapElement = Elements.classNamed("Map");
      mapType = Types.interfaceType(mapElement, Collections.<Type>emptyList());
      ClassElement arrayElement = Elements.classNamed("Array");
      arrayType = Types.interfaceType(arrayElement, Collections.<Type>emptyList());
      functionElement.setType(functionType);
    }

    MockCoreTypeProvider(ClassElement objectElement) {
      this.objectElement = objectElement;
    }

    @Override
    public InterfaceType getIntType() {
      return intType;
    }

    @Override
    public InterfaceType getDoubleType() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getBoolType() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getStringType() {
      return stringType;
    }

    @Override
    public InterfaceType getFunctionType() {
      return functionType;
    }

    @Override
    public InterfaceType getArrayType(Type elementType) {
      return arrayType;
    }

    @Override
    public Type getNullType() {
      throw new AssertionError();
    }

    @Override
    public Type getVoidType() {
      throw new AssertionError();
    }

    @Override
    public DynamicType getDynamicType() {
      return Types.newDynamicType();
    }

    @Override
    public InterfaceType getFallThroughError() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getMapType(Type key, Type value) {
      return mapType;
    }

    @Override
    public InterfaceType getObjectArrayType() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getObjectType() {
      return objectElement.getType();
    }

    @Override
    public InterfaceType getNumType() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getArrayLiteralType(Type value) {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getMapLiteralType(Type key, Type value) {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getStringImplementationType() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getIsolateType() {
      throw new AssertionError();
    }
  }
}
