// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.parser.DartScanner.Location;
import com.google.dart.compiler.type.DynamicType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.Types;

import java.util.Arrays;

public class CoreTypeProviderImplementation implements CoreTypeProvider {
  private final InterfaceType intType;
  private final InterfaceType doubleType;
  private final InterfaceType numType;
  private final InterfaceType boolType;
  private final InterfaceType stringType;
  private final InterfaceType functionType;
  private final InterfaceType arrayType;
  private final DynamicType dynamicType;
  private final Type voidType;
  private final Type nullType;
  private final InterfaceType fallThroughError;
  private final InterfaceType mapType;
  private final InterfaceType mapLiteralType;
  private final InterfaceType objectArrayType;
  private final InterfaceType objectType;
  private final InterfaceType stringImplementation;
  private final InterfaceType iteratorType;

  public CoreTypeProviderImplementation(Scope scope, DartCompilerListener listener) {
    this.intType = getType("int", scope, listener);
    this.doubleType = getType("double", scope, listener);
    this.boolType = getType("bool", scope, listener);
    this.numType = getType("num", scope, listener);
    this.stringType = getType("String", scope, listener);
    this.functionType = getType("Function", scope, listener);
    this.arrayType = getType("List", scope, listener);
    this.dynamicType = Types.newDynamicType();
    this.voidType = Types.newVoidType();
    // Currently, there is no need for a special null type.
    this.nullType = dynamicType;
    this.fallThroughError = getType("FallThroughError", scope, listener);
    this.mapType = getType("Map", scope, listener);
    this.mapLiteralType = getType("LinkedHashMapImplementation", scope, listener);
    this.objectArrayType = getType(new String[] {
        "ListImplementation", "GrowableObjectArray", "ListFactory"}, scope, listener);
    this.objectType = getType("Object", scope, listener);
    this.stringImplementation = getType(new String[] {
        "StringImplementation", "OneByteString"}, scope, listener);
    iteratorType = getType("Iterator", scope, listener);
  }

  private static InterfaceType getType(String name, Scope scope, DartCompilerListener listener) {
    ClassElement element = (ClassElement) scope.findElement(scope.getLibrary(), name);
    if (element == null) {
      DartCompilationError error =
          new DartCompilationError(null, Location.NONE,
              ResolverErrorCode.CANNOT_BE_RESOLVED, name);
      listener.onError(error);
      return Types.newDynamicType();
    }
    return element.getType();
  }

  private static InterfaceType getType(String[] names, Scope scope, DartCompilerListener listener) {
    ClassElement element = null;
    for (String name : names) {
      element = (ClassElement) scope.findElement(scope.getLibrary(), name);
      if (element != null)
        break;
    }
    if (element == null) {
      DartCompilationError error =
          new DartCompilationError(null, Location.NONE,
              ResolverErrorCode.CANNOT_BE_RESOLVED, names[0]);
      listener.onError(error);
      return Types.newDynamicType();
    }
    return element.getType();
  }

  @Override
  public InterfaceType getIntType() {
    return intType;
  }

  @Override
  public InterfaceType getDoubleType() {
    return doubleType;
  }

  @Override
  public InterfaceType getBoolType() {
    return boolType;
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
    return arrayType.subst(Arrays.asList(elementType), arrayType.getElement().getTypeParameters());
  }

  @Override
  public InterfaceType getArrayLiteralType(Type elementType) {
    return objectArrayType.subst(
        Arrays.asList(elementType), objectArrayType.getElement().getTypeParameters());
  }

  @Override
  public DynamicType getDynamicType() {
    return dynamicType;
  }

  @Override
  public Type getVoidType() {
    return voidType;
  }

  @Override
  public Type getNullType() {
    return nullType;
  }

  @Override
  public InterfaceType getFallThroughError() {
    return fallThroughError;
  }

  @Override
  public InterfaceType getMapType(Type key, Type value) {
    return mapType.subst(Arrays.asList(key, value), mapType.getElement().getTypeParameters());
  }

  @Override
  public InterfaceType getMapLiteralType(Type key, Type value) {
    return mapLiteralType.subst(
        Arrays.asList(key, value), mapLiteralType.getElement().getTypeParameters());
  }

  @Override
  public InterfaceType getObjectArrayType() {
    return objectArrayType;
  }

  @Override
  public InterfaceType getObjectType() {
    return objectType;
  }

  @Override
  public InterfaceType getNumType() {
    return numType;
  }

  @Override
  public InterfaceType getStringImplementationType() {
    return stringImplementation;
  }

  @Override
  public InterfaceType getIteratorType(Type elementType) {
    return iteratorType.subst(Arrays.asList(elementType), 
        iteratorType.getElement().getTypeParameters());
  }
}
