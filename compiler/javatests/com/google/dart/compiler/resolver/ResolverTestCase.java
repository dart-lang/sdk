// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.base.Joiner;
import com.google.common.base.Splitter;
import com.google.common.collect.Lists;
import com.google.common.collect.Sets;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartParameterizedTypeNode;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.ErrorExpectation;
import com.google.dart.compiler.parser.DartParser;
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

  private List<DartCompilationError> parseErrors = Lists.newArrayList();

  @Override
  public void setUp() {
    resetParseErrors();
  }

  @Override
  public void tearDown() {
    resetParseErrors();
  }

  private static CoreTypeProvider setupTypeProvider(DartUnit unit, TestCompilerContext context, Scope scope) {
    new TopLevelElementBuilder().exec(unit.getLibrary(), unit, context);
    new TopLevelElementBuilder().fillInUnitScope(unit, context, scope, null);
    ClassElement object = (ClassElement) scope.findElement(null, "Object");
    assertNotNull("Cannot resolve Object", object);
    return new MockCoreTypeProvider(object);
  }

  static Scope resolve(DartUnit unit, TestCompilerContext context) {
    LibraryUnit libraryUnit = MockLibraryUnit.create(unit);

    // Prepare for running phases.
    Scope scope = libraryUnit.getElement().getScope();
    CoreTypeProvider typeProvider = setupTypeProvider(unit, context, scope);
    // Run phases as in compiler.
    new SupertypeResolver().exec(unit, context, scope, typeProvider);
    new MemberBuilder().exec(unit, context, scope, typeProvider);
    new Resolver(context, scope, typeProvider).exec(unit);
    // TODO(zundel): One day, we want all AST nodes that are identifiers to point to
    // elements if they are resolved.  Uncommenting this line helps track missing elements
    // down.
    // ResolverAuditVisitor.exec(unit);
    return scope;
  }

  static Scope resolveCompileTimeConst(DartUnit unit, TestCompilerContext context) {
    LibraryUnit libraryUnit = MockLibraryUnit.create(unit);
    // Prepare for running phases.
    Scope scope = libraryUnit.getElement().getScope();
    CoreTypeProvider typeProvider = setupTypeProvider(unit, context, scope);
    // Run phases as in compiler.
    new SupertypeResolver().exec(unit, context, scope, typeProvider);
    new MemberBuilder().exec(unit, context, scope, typeProvider);
    new Resolver.Phase().exec(unit, context, typeProvider);
    new CompileTimeConstantAnalyzer(typeProvider, context).exec(unit);
    return scope;
  }


  static DartClass makeClass(String name, DartTypeNode supertype, String... typeParameters) {
    return makeClass(name, supertype, Collections.<DartTypeNode>emptyList(), typeParameters);
  }

  static DartClass makeInterface(String name, String... typeParameters) {
    return makeInterface(name, Collections.<DartTypeNode>emptyList(), null, typeParameters);
  }

  static DartClass makeClass(String name, DartTypeNode supertype, List<DartTypeNode> interfaces,
      String... typeParameters) {
    List<DartTypeParameter> parameterNodes = new ArrayList<DartTypeParameter>();
    for (String parameter : typeParameters) {
      parameterNodes.add(makeTypeVariable(parameter));
    }
    List<DartNode> members = Arrays.<DartNode>asList();
    return new DartClass(-1, 0, new DartIdentifier(name), null, supertype,
                         interfaces, -1, -1, -1, members, parameterNodes, Modifiers.NONE);
  }

  static DartClass makeInterface(String name, List<DartTypeNode> interfaces,
      DartParameterizedTypeNode defaultClass, String... typeParameters) {
    List<DartTypeParameter> parameterNodes = new ArrayList<DartTypeParameter>();
    for (String parameter : typeParameters) {
      parameterNodes.add(makeTypeVariable(parameter));
    }
    List<DartNode> members = Arrays.<DartNode> asList();
    return new DartClass(-1, 0, new DartIdentifier(name), null, null, interfaces, -1, -1, -1,
        members, parameterNodes, defaultClass, true, Modifiers.NONE);
  }

  static DartParameterizedTypeNode makeDefault(String name) {
    return new DartParameterizedTypeNode(new DartIdentifier(name), null);
  }

  private static DartTypeParameter makeTypeVariable(String name) {
    return new DartTypeParameter(new DartIdentifier(name), null);
  }

  /**
   * Look for  DartIdentifier nodes in the tree whose elements are null.  They should all either
   * be resolved, or marked as an unresolved element.
   */
  static class ResolverAuditVisitor extends ASTVisitor<Void> {
    private List<String> failures = Lists.newArrayList();

    @Override
    public Void visitIdentifier(DartIdentifier node) {

      if (node.getElement() == null) {
        failures.add("Identifier: "
            + node.getName()
            + " has null element @ ("
            + node.getSourceInfo().getLine()
            + ":"
            + node.getSourceInfo().getColumn()
            + ")");
      }
      return null;
    }

    public List<String> getFailures() {
      return failures;
    }

    public static void exec(DartNode root) {
      ResolverAuditVisitor visitor = new ResolverAuditVisitor();
      root.accept(visitor);
      List<String> results = visitor.getFailures();
      if (results.size() > 0) {
        StringBuilder out = new StringBuilder("Missing elements found in AST\n");
        Joiner.on("\n").appendTo(out, results);
        fail(out.toString());
      }
    }
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
    private final InterfaceType typeType;
    private final Type voidType;
    private final ClassElement objectElement;

    {
      ClassElement dynamicElement = Elements.classNamed("dynamic");
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
      defaultMapLiteralType =
          Types.interfaceType(mapElement, Lists.<Type>newArrayList(stringType, dynamicType));
      mapElement.setType(defaultMapLiteralType);

      ClassElement listElement = Elements.classNamed("List");
      defaultListType = Types.interfaceType(listElement, Lists.<Type>newArrayList(dynamicType));
      listElement.setType(defaultListType);
      
      ClassElement typeElement = Elements.classNamed("Type");
      typeType = Types.interfaceType(typeElement, Collections.<Type>emptyList());
      listElement.setType(defaultListType);

      voidType = Types.newVoidType();
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
      return voidType;
    }

    @Override
    public DynamicType getDynamicType() {
      return Types.newDynamicType();
    }

    @Override
    public InterfaceType getMapType(Type key, Type value) {
      return defaultMapLiteralType;
    }

    @Override
    public InterfaceType getObjectType() {
      return objectElement.getType();
    }

    @Override
    public InterfaceType getIteratorType(Type elementType) {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getTypeType() {
      return typeType;
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
    DartUnit unit = new DartUnit(null, false);
    for (DartNode topLevelElement : topLevelElements) {
      unit.getTopLevelNodes().add(topLevelElement);
    }
    return unit;
  }

  protected DartUnit parseUnit(String firstLine, String secondLine, String... rest) {
    return parseUnit(Joiner.on('\n').join(firstLine, secondLine, (Object[]) rest).toString());
  }

  protected DartUnit parseUnit(String string) {
    DartSourceString source = new DartSourceString("<source string>", string);
    DartParser parser = new DartParser(
        source,
        string,
        false,
        Sets.<String>newHashSet(),
        getListener(),
        null);
    return parser.parseUnit();
  }

  private DartCompilerListener getListener() {
    return new DartCompilerListener.Empty() {
      @Override
      public void onError(DartCompilationError event) {
        parseErrors.add(event);
      }
    };
  }

  protected void checkExpectedErrors(ErrorCode[] errorCodes) {
    checkExpectedErrors(parseErrors, errorCodes, null);
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
        recordParseError(event);
      }
    };
  }

  /**
   * Resets the global list of encountered errors.  Call this before evaluating a new test.
   */
  protected void resetParseErrors() {
    parseErrors = Lists.newArrayList();
  }

  /**
   * Save an error event in the global list of encountered errors.  For use by
   * custom {@link DartCompilerListener} implementations.
   */
  protected void recordParseError(DartCompilationError event) {
    parseErrors.add(event);
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
      ErrorCode errorCode = error.getErrorCode();
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
   *
   * @return resolve errors.
   */
  protected List<DartCompilationError> resolveAndTest(String source, ErrorCode errorCode, ErrorCode... errorCodeRest) {
    ErrorCode errorCodes[] = new ErrorCode[errorCodeRest.length + 1];
    errorCodes[0] = errorCode;
    if (errorCodeRest.length > 0) {
      System.arraycopy(errorCodeRest, 0, errorCodes, 1, errorCodeRest.length);
    }
    // parse DartUnit
    DartUnit unit = parseUnit(source);
    if (parseErrors.size() != 0) {
      printSource(source);
      printEncountered(parseErrors);
      assertEquals("Expected no errors in parse step:", 0, parseErrors.size());
    }
    // prepare for recording resolving errors
    resetParseErrors();
    final List<DartCompilationError> resolveErrors = Lists.newArrayList();
    TestCompilerContext ctx =  new TestCompilerContext() {
      @Override
      public void onError(DartCompilationError event) {
        resolveErrors.add(event);
      }
    };
    // resolve and check errors
    resolve(unit, ctx);
    checkExpectedErrors(resolveErrors, errorCodes, source);
    return resolveErrors;
  }

  protected List<DartCompilationError> resolveAndTest(String source,
                                                      ErrorExpectation... expectedErrors) {
    // parse DartUnit
    DartUnit unit = parseUnit(source);
    if (parseErrors.size() != 0) {
      printSource(source);
      printEncountered(parseErrors);
      assertEquals("Expected no errors in parse step:", 0, parseErrors.size());
    }
    // prepare for recording resolving errors
    resetParseErrors();
    final List<DartCompilationError> resolveErrors = Lists.newArrayList();
    TestCompilerContext ctx =  new TestCompilerContext() {
      @Override
      public void onError(DartCompilationError event) {
        resolveErrors.add(event);
      }
    };
    // resolve and check errors
    resolve(unit, ctx);
    ErrorExpectation.assertErrors(resolveErrors, expectedErrors);
    return resolveErrors;
  }

  /**
   * Convenience method to parse and resolve a code snippet, then test for error codes.
   *
   * @return resolve errors.
   */
  protected List<DartCompilationError> resolveAndTestCtConst(String source, ErrorCode... errorCodes) {
    // parse DartUnit
    DartUnit unit = parseUnit(source);
    if (parseErrors.size() != 0) {
      printSource(source);
      printEncountered(parseErrors);
      assertEquals("Expected no errors in parse step:", 0, parseErrors.size());
    }
    // prepare for recording resolving errors
    resetParseErrors();
    final List<DartCompilationError> resolveErrors = Lists.newArrayList();
    TestCompilerContext ctx =  new TestCompilerContext() {
      @Override
      public void onError(DartCompilationError event) {
        resolveErrors.add(event);
      }
    };
    // resolve and check errors
    resolveCompileTimeConst(unit, ctx);
    checkExpectedErrors(resolveErrors, errorCodes, source);
    return resolveErrors;
  }

  protected List<DartCompilationError> resolveAndTestCtConstExpectErrors(String source, ErrorExpectation... expectedErrors) {
    // parse DartUnit
    DartUnit unit = parseUnit(source);
    if (parseErrors.size() != 0) {
      printSource(source);
      printEncountered(parseErrors);
      assertEquals("Expected no errors in parse step:", 0, parseErrors.size());
    }
    // prepare for recording resolving errors
    resetParseErrors();
    final List<DartCompilationError> resolveErrors = Lists.newArrayList();
    TestCompilerContext ctx =  new TestCompilerContext() {
      @Override
      public void onError(DartCompilationError event) {
        resolveErrors.add(event);
      }
    };
    // resolve and check errors
    resolveCompileTimeConst(unit, ctx);
    ErrorExpectation.assertErrors(resolveErrors, expectedErrors);
    return resolveErrors;
  }
}
