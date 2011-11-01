// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.base.Joiner;
import com.google.common.base.Splitter;
import com.google.common.collect.Lists;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.parser.DartParser;
import com.google.dart.compiler.parser.DartScannerParserContext;
import com.google.dart.compiler.testing.TestCompilerContext;
import com.google.dart.compiler.type.DynamicType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.Types;
import com.google.dart.compiler.util.DartSourceString;

import junit.framework.TestCase;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * Utility methods for resolver tests.
 */
abstract class ResolverTestCase extends TestCase {

  private List<DartCompilationError> encounteredErrors = Lists.newArrayList();

  @Override
  public void setUp() {
    resetExpectedErrors();
  }

  @Override
  public void tearDown() {
    resetExpectedErrors();
  }

  static Scope resolve(DartUnit unit, TestCompilerContext context) {
    Scope scope = new Scope("library", null);
    new TopLevelElementBuilder().exec(unit, context);
    new TopLevelElementBuilder().fillInUnitScope(unit, context, scope);
    ClassElement object = (ClassElement) scope.findElement(null, "Object");
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

    private final InterfaceType boolType;
    private final InterfaceType intType;
    private final InterfaceType doubleType;
    private final InterfaceType numType;
    private final InterfaceType stringType;
    private final InterfaceType functionType;
    private final InterfaceType dynamicType;
    private final InterfaceType defaultMapLiteralType;
    private final InterfaceType defaultListType;
    private final ClassElement objectElement;


    {
      ClassElement dynamicElement = Elements.classNamed("Dynamic");
      dynamicType = Types.interfaceType(dynamicElement, Collections.<Type>emptyList());
      dynamicElement.setType(dynamicType);

      ClassElement boolElement = Elements.classNamed("bool");
      boolType = Types.interfaceType(boolElement, Collections.<Type>emptyList());
      boolElement.setType(boolType);

      ClassElement intElement = Elements.classNamed("int");
      intType = Types.interfaceType(intElement, Collections.<Type>emptyList());
      intElement.setType(intType);

      ClassElement doubleElement = Elements.classNamed("double");
      doubleType = Types.interfaceType(doubleElement, Collections.<Type>emptyList());
      doubleElement.setType(doubleType);

      ClassElement numElement = Elements.classNamed("num");
      numType = Types.interfaceType(numElement, Collections.<Type>emptyList());
      numElement.setType(numType);

      ClassElement stringElement = Elements.classNamed("String");
      stringType = Types.interfaceType(stringElement, Collections.<Type>emptyList());
      intElement.setType(intType);

      ClassElement functionElement = Elements.classNamed("Function");
      functionType = Types.interfaceType(functionElement, Collections.<Type>emptyList());
      functionElement.setType(functionType);

      ClassElement mapElement = Elements.classNamed("Map");
      defaultMapLiteralType = Types.interfaceType(mapElement, Lists.newArrayList(stringType, dynamicType));
      mapElement.setType(defaultMapLiteralType);

      ClassElement listElement = Elements.classNamed("List");
      defaultListType = Types.interfaceType(listElement, Lists.newArrayList(dynamicType));
      listElement.setType(defaultListType);
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
      return doubleType;
    }

    @Override
    public InterfaceType getNumType() {
      return numType;
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
      return defaultListType;
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
      return defaultMapLiteralType;
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
    public InterfaceType getArrayLiteralType(Type value) {
      return defaultListType;
    }

    @Override
    public InterfaceType getMapLiteralType(Type key, Type value) {
      return defaultMapLiteralType;
    }

    @Override
    public InterfaceType getStringImplementationType() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getIsolateType() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getIteratorType(Type elementType) {
      throw new AssertionError();
    }
  }

  protected static DartTypeNode makeType(String name, String... arguments) {
    List<DartTypeNode> argumentNodes = makeTypes(arguments);
    return new DartTypeNode(new DartIdentifier(name), argumentNodes);
  }

  static List<DartTypeNode> makeTypes(String... typeNames) {
    List<DartTypeNode> types = new ArrayList<DartTypeNode>();
    for (String typeName : typeNames) {
      types.add(makeType(typeName));
    }
    return types;
  }


  protected static DartUnit makeUnit(DartNode... topLevelElements) {
    DartUnit unit = new DartUnit(null);
    for (DartNode topLevelElement : topLevelElements) {
      unit.addTopLevelNode(topLevelElement);
    }
    return unit;
  }

  protected DartUnit parseUnit(String firstLine, String secondLine, String... rest) {
    return parseUnit(Joiner.on('\n').join(firstLine, secondLine, (Object[]) rest).toString());
  }

  protected DartUnit parseUnit(String string) {
    DartSourceString source = new DartSourceString("<source string>", string);
    return getParser(string).parseUnit(source);
  }

  private DartParser getParser(String string) {
    return new DartParser(new DartScannerParserContext(null, string, getListener()));
  }

  private DartCompilerListener getListener() {
    return new DartCompilerListener() {
      @Override
      public void onError(DartCompilationError event) {
        encounteredErrors.add(event);
      }

      @Override
      public void unitCompiled(DartUnit unit) {
      }
    };
  }

  protected void checkExpectedErrors(ErrorCode[] errorCodes) {
    checkExpectedErrors(encounteredErrors, errorCodes, null);
  }

  /**
   * Given a list of errors encountered during parse/resolve, compare them to
   * a list of expected error codes.
   *
   * @param encountered errors actually encountered
   * @param errorCodes expected errors.
   */
  protected void checkExpectedErrors(List<DartCompilationError> encountered,
                                        ErrorCode[] errorCodes,
                                        String source) {
    if (errorCodes.length != encountered.size()) {
      printSource(source);
      printEncountered(encountered);
      assertEquals(errorCodes.length, encountered.size());
    }
    int index = 0;
    for (ErrorCode errorCode : errorCodes) {
      ErrorCode found = encountered.get(index).getErrorCode();
      if (!found.equals(errorCode)) {
        printSource(source);
        printEncountered(encountered);
        assertEquals("Unexpected Error Code: ", errorCode, found);
      }
      index++;
    }
  }

  /**
   * Returns a context with a listener that remembers all DartCompilationErrors and records
   * them.
   * @return
   */
  protected TestCompilerContext getContext() {
    return new TestCompilerContext() {
      @Override
      public void onError(DartCompilationError event) {
        recordError(event);
      }
    };
  }

  /**
   * Resets the global list of encountered errors.  Call this before evaluating a new test.
   */
  protected void resetExpectedErrors() {
    encounteredErrors = Lists.newArrayList();
  }

  /**
   * Save an error event in the global list of encountered errors.  For use by
   * custom {@link DartCompilerListener} implementations.
   */
  protected void recordError(DartCompilationError event) {
    encounteredErrors.add(event);
  }

  protected void printSource(String source) {
    if (source != null) {
      int count = 1;
      for (String line : Splitter.on("\n").split(source)) {
        System.out.println(String.format(" %02d: %s", count++, line));
      }
    }
  }
  /**
   * For debugging.
   */
  protected void printEncountered(List<DartCompilationError> encountered) {
    for (DartCompilationError error : encountered) {
      ErrorCode errorCode = (ErrorCode) error.getErrorCode();
      String msg =
          String.format(
              "%s > %s (%d:%d)",
              errorCode.toString(),
              error.getMessage(),
              error.getLineNumber(),
              error.getColumnNumber());
      System.out.println(msg);
    }
  }

  /**
   * Convenience method to parse and resolve a code snippet, then test for error codes.
   */
  protected void resolveAndTest(String source, ErrorCode... errorCodes) {
    resetExpectedErrors();
    final List<DartCompilationError> encountered = Lists.newArrayList();
    TestCompilerContext ctx =  new TestCompilerContext() {
      @Override
      public void onError(DartCompilationError event) {
        encountered.add(event);
      }
    };
    DartUnit unit = parseUnit(source);
    if (encounteredErrors.size() != 0) {
      printSource(source);
      printEncountered(encounteredErrors);
      assertEquals("Expected no errors in parse step:", 0, encounteredErrors.size());
    }
    resolve(unit, ctx);
    checkExpectedErrors(encountered, errorCodes, source);
  }
}
