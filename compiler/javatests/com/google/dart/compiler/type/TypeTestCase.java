// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.common.collect.Maps;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.SubSystem;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartInitializer;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.MethodNodeElement;
import com.google.dart.compiler.resolver.TypeVariableElement;
import com.google.dart.compiler.testing.TestCompilerContext;

import junit.framework.TestCase;

import org.junit.Assert;

import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Common superclass for type tests.
 */
abstract class TypeTestCase extends TestCase {

  final Map<String, Element> coreElements = Maps.newHashMap();
  final ClassElement object = element("Object", null);
  final ClassElement function = element("Function", itype(object));
  final ClassElement number = element("num", itype(object));
  final ClassElement intElement = element("int", itype(number));
  final ClassElement doubleElement = element("double", itype(number));
  final ClassElement bool = element("bool", itype(object));
  final ClassElement string = element("String", itype(object));
  final ClassElement iterElement = element("Iterator", itype(object), typeVar("E", itype(object)));
  final ClassElement list = makeListElement();
  final ClassElement map = element("Map", itype(object),
                                   typeVar("K", itype(object)), typeVar("V", itype(object)));
  final ClassElement stackTrace = element("StackTrace", itype(object));
  final ClassElement reverseMap = makeReverseMap(map);
  final InterfaceType objectList = itype(list, itype(object));
  final InterfaceType objectMap = itype(map, itype(object), itype(object));
  final InterfaceType reverseObjectMap = itype(reverseMap, itype(object), itype(object));
  final InterfaceType stringIntMap = itype(map, itype(string), itype(intElement));
  final InterfaceType intStringMap = itype(map, itype(intElement), itype(string));
  final InterfaceType stringIntReverseMap = itype(reverseMap, itype(string), itype(intElement));
  final FunctionType returnObject = ftype(function, itype(object), null, null);
  final FunctionType returnString = ftype(function, itype(string), null, null);
  final FunctionType objectToObject = ftype(function, itype(object), null, null, itype(object));
  final FunctionType objectToString = ftype(function, itype(string), null, null, itype(object));
  final FunctionType stringToObject = ftype(function, itype(object), null, null, itype(string));
  final FunctionType stringAndIntToBool = ftype(function, itype(bool),
                                                null, null, itype(string), itype(intElement));
  final FunctionType stringAndIntToMap = ftype(function, stringIntMap,
                                               null, null, itype(string), itype(intElement));
  private int expectedTypeErrors = 0;
  private int foundTypeErrors = 0;

  abstract Types getTypes();

  ClassElement makeListElement() {
    final TypeVariable typeVar = typeVar("E", itype(object));
    final ClassElement element = element("List", itype(object), typeVar);
    DartTypeNode returnTypeNode = new DartTypeNode(new DartIdentifier("Iterator"),
        Arrays.asList(new DartTypeNode(new DartIdentifier("E"))));

    DartMethodDefinition iteratorMethod = DartMethodDefinition.create(
        new DartIdentifier("iterator"), new DartFunction(Collections.<DartParameter>emptyList(),
            new DartBlock(Collections.<DartStatement>emptyList()), returnTypeNode),
        Modifiers.NONE,
        Collections.<DartInitializer>emptyList());
    MethodNodeElement iteratorMethodElement = Elements.methodFromMethodNode(iteratorMethod, element);
    Type returnType = Types.interfaceType(iterElement, Arrays.<Type>asList(typeVar));
    FunctionType functionType = ftype(function, returnType, Collections.<String,Type>emptyMap(),
         null);
    Elements.setType(iteratorMethodElement, functionType);
    Elements.addMethod(element, iteratorMethodElement);
    return element;
  }

  protected void setExpectedTypeErrorCount(int count) {
    checkExpectedTypeErrorCount();
    expectedTypeErrors = count;
    foundTypeErrors  = 0;
  }

  protected void checkExpectedTypeErrorCount(String message) {
    assertEquals(message, expectedTypeErrors, foundTypeErrors);
  }

  protected void checkExpectedTypeErrorCount() {
    checkExpectedTypeErrorCount(null);
  }

  static TypeVariable typeVar(String name, Type bound) {
    TypeVariableElement element = Elements.typeVariableElement(name, bound);
    return new TypeVariableImplementation(element);
  }

  private ClassElement makeReverseMap(ClassElement map) {
    TypeVariable K = typeVar("K", itype(object));
    TypeVariable V = typeVar("V", itype(object));
    return element("ReverseMap", itype(map, V, K), K, V);
  }

  static InterfaceType itype(ClassElement element, Type... arguments) {
    return new InterfaceTypeImplementation(element, Arrays.asList(arguments));
  }

  static FunctionType ftype(ClassElement element, Type returnType,
                            Map<String, Type> namedParameterTypes, Type rest, Type... arguments) {
    return FunctionTypeImplementation.of(element, Arrays.asList(arguments), namedParameterTypes,
                                         rest, returnType);
  }

  static Map<String, Type> named(Object... pairs) {
    Map<String, Type> named = new LinkedHashMap<String, Type>();
    for (int i = 0; i < pairs.length; i++) {
      Type type = (Type) pairs[i++];
      String name = (String) pairs[i];
      named.put(name, type);
    }
    return named;
  }

  ClassElement element(String name, InterfaceType supertype, TypeVariable... parameters) {
    ClassElement element = Elements.classNamed(name);
    element.setSupertype(supertype);
    element.setType(itype(element, parameters));
    coreElements.put(name, element);
    return element;
  }

  void checkSubtype(Type t, Type s) {
    Assert.assertTrue(getTypes().isSubtype(t, s));
  }

  void checkStrictSubtype(Type t, Type s) {
    checkSubtype(t, s);
    checkNotSubtype(s, t);
  }

  void checkNotSubtype(Type t, Type s) {
    Assert.assertFalse(getTypes().isSubtype(t, s));
  }

  void checkNotAssignable(Type t, Type s) {
    checkNotSubtype(t, s);
    checkNotSubtype(s, t);
  }

  final DartCompilerListener listener = new DartCompilerListener.Empty() {
    @Override
    public void onError(DartCompilationError event) {
      throw new AssertionError(event);
    }
  };

  final TestCompilerContext context = new TestCompilerContext() {
    @Override
    public void onError(DartCompilationError event) {
      if (event.getErrorCode().getSubSystem() == SubSystem.STATIC_TYPE) {
        getErrorCodes().add(event.getErrorCode());
        foundTypeErrors++;
        if (expectedTypeErrors - foundTypeErrors < 0) {
          throw new TestTypeError(event);
        }
      }
    }
  };

  static class TestTypeError extends RuntimeException {
    final DartCompilationError event;

    TestTypeError(DartCompilationError event) {
      super(String.valueOf(event));
      this.event = event;
    }

    ErrorCode getErrorCode() {
      return event.getErrorCode();
    }
  }
}
