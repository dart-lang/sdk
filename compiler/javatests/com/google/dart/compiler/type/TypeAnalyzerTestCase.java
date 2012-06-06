// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.common.base.Joiner;
import com.google.common.collect.Maps;
import com.google.common.io.CharStreams;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.parser.DartParser;
import com.google.dart.compiler.parser.DartScannerParserContext;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ClassNodeElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.FunctionAliasElement;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MemberBuilder;
import com.google.dart.compiler.resolver.MockLibraryUnit;
import com.google.dart.compiler.resolver.ResolutionContext;
import com.google.dart.compiler.resolver.Resolver;
import com.google.dart.compiler.resolver.Resolver.ResolveElementsVisitor;
import com.google.dart.compiler.resolver.Scope;
import com.google.dart.compiler.resolver.SupertypeResolver;
import com.google.dart.compiler.resolver.TopLevelElementBuilder;
import com.google.dart.compiler.util.DartSourceString;

import java.io.IOError;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Map;

/**
 * Base class for static type analysis tests.
 */
public abstract class TypeAnalyzerTestCase extends TypeTestCase {
  private class MockCoreTypeProvider implements CoreTypeProvider {
    private final Type voidType = Types.newVoidType();
    private final DynamicType dynamicType = Types.newDynamicType();

    @Override
    public InterfaceType getArrayLiteralType(Type value) {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getArrayType(Type elementType) {
      return list.getType().subst(Arrays.asList(elementType), list.getTypeParameters());
    }

    @Override
    public InterfaceType getBoolType() {
      return bool.getType();
    }

    @Override
    public InterfaceType getDoubleType() {
      return doubleElement.getType();
    }

    @Override
    public DynamicType getDynamicType() {
      return dynamicType;
    }

    @Override
    public InterfaceType getFallThroughError() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getFunctionType() {
      return function.getType();
    }

    @Override
    public InterfaceType getIntType() {
      return intElement.getType();
    }

    @Override
    public InterfaceType getIteratorType(Type elementType) {
      InterfaceType iteratorType = iterElement.getType();
      return iteratorType.subst(Arrays.asList(elementType), iterElement.getTypeParameters());
    }

    @Override
    public InterfaceType getMapLiteralType(Type key, Type value) {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getMapType(Type key, Type value) {
      InterfaceType mapType = map.getType();
      return mapType.subst(Arrays.asList(key, value),
                           mapType.getElement().getTypeParameters());
    }

    @Override
    public Type getNullType() {
      return getDynamicType();
    }

    @Override
    public InterfaceType getNumType() {
      return number.getType();
    }

    @Override
    public InterfaceType getObjectArrayType() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getObjectType() {
      return object.getType();
    }

    @Override
    public InterfaceType getStringImplementationType() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getStringType() {
      return string.getType();
    }

    @Override
    public Type getVoidType() {
      return voidType;
    }
  }
  private class MockScope extends Scope {
    private MockScope() {
      super("test mock scope", null);
    }

    @Override
    public Element findLocalElement(String name) {
      return coreElements.get(name);
    }

  }
  protected final CoreTypeProvider typeProvider = new MockCoreTypeProvider();
  private Resolver resolver = new Resolver(context, getMockScope("<test toplevel>"), typeProvider);

  private final Types types = Types.getInstance(typeProvider);

  private HashSet<ClassElement> diagnosedAbstractClasses = new HashSet<ClassElement>();

  protected DartStatement analyze(String statement) {
    DartStatement node = parseStatement(statement);
    analyzeNode(node);
    return node;
  }

  protected ClassElement analyzeClass(ClassNodeElement cls, int expectedErrorCount) {
    setExpectedTypeErrorCount(expectedErrorCount);
    analyzeToplevel(cls.getNode());
    checkExpectedTypeErrorCount(cls.getName());
    return cls;
  }

  protected Map<String, ClassNodeElement> analyzeClasses(Map<String, ClassNodeElement> classes,
                                                   ErrorCode... codes) {
    setExpectedTypeErrorCount(codes.length);
    for (ClassNodeElement cls : classes.values()) {
      analyzeToplevel(cls.getNode());
    }
    List<ErrorCode> errorCodes = context.getErrorCodes();
    assertEquals(Arrays.toString(codes), errorCodes.toString());
    errorCodes.clear();
    checkExpectedTypeErrorCount();
    return classes;
  }

  protected void analyzeFail(String statement, ErrorCode errorCode) {
    try {
      analyze(statement);
      fail("Test unexpectedly passed.  Expected ErrorCode: " + errorCode);
    } catch (TestTypeError error) {
      assertEquals(errorCode, error.getErrorCode());
    }
  }

  protected Type analyzeIn(ClassElement element, String expression, int expectedErrorCount) {
    DartExpression node = parseExpression(expression);
    ResolutionContext resolutionContext =
        new ResolutionContext(getMockScope("<test expression>"), context,
                              typeProvider).extend(element);
    ResolveElementsVisitor visitor =
        resolver.new ResolveElementsVisitor(resolutionContext, element,
                                            Elements.methodElement(null, null));
    setExpectedTypeErrorCount(expectedErrorCount);
    node.accept(visitor);
    Type type = node.accept(makeTypeAnalyzer(element));
    checkExpectedTypeErrorCount(expression);
    return type;
  }

  private Type analyzeNode(DartNode node) {
    ResolutionContext resolutionContext =
        new ResolutionContext(getMockScope("<test node>"), context, typeProvider);
    ResolveElementsVisitor visitor =
        resolver.new ResolveElementsVisitor(resolutionContext, null,
                                            Elements.methodElement(null, null));
    node.accept(visitor);
    return node.accept(makeTypeAnalyzer(Elements.dynamicElement()));
  }

  private Type analyzeToplevel(DartNode node) {
    return node.accept(makeTypeAnalyzer(Elements.dynamicElement()));
  }

  private String assign(String type, String expression) {
    return String.format("void foo() { %s x = %s; }", type, expression);
  }

  protected Type checkAssignIn(ClassElement element, String type, String expression, int errorCount) {
    return analyzeIn(element, assign(type, expression), errorCount);
  }

  protected void checkFunctionStatement(String statement, String printString) {
    DartExprStmt node = (DartExprStmt) analyze(statement);
    DartFunctionExpression expression = (DartFunctionExpression) node.getExpression();
    Element element = expression.getElement();
    FunctionType type = (FunctionType) element.getType();
    assertEquals(printString, type.toString());
  }

  protected void checkSimpleType(Type type, String expression) {
    assertSame(type, typeOf(expression));
    setExpectedTypeErrorCount(1); // x is unresolved.
    assertSame(type, typeOf("x = " + expression));
    checkExpectedTypeErrorCount();
  }

  protected void checkType(Type type, String expression) {
    assertEquals(type, typeOf(expression));
    assertEquals(type, typeOf("x = " + expression));
  }

  private Scope getMockScope(String name) {
    LibraryUnit libraryUnit = MockLibraryUnit.create();
    return new Scope(name, libraryUnit.getElement(), new MockScope());
  }

  private DartParser getParser(String string) {
    DartSourceString source = new DartSourceString("<source string>", string);
    return new DartParser(new DartScannerParserContext(source, string, listener));
  }

  private String getResource(String name) {
    String packageName = getClass().getPackage().getName().replace('.', '/');
    String resouceName = packageName + "/" + name;
    InputStream stream = getClass().getClassLoader().getResourceAsStream(resouceName);
    if (stream == null) {
      throw new AssertionError("Missing resource: " + resouceName);
    }
    InputStreamReader reader = new InputStreamReader(stream);
    try {
      return CharStreams.toString(reader); // Also closes the reader.
    } catch (IOException e) {
      throw new IOError(e);
    }
  }

  @Override
  Types getTypes() {
    return types;
  }

  protected ClassElement loadClass(String file, String name) {
    ClassElement cls = loadFile(file).get(name);
    assertNotNull("unable to locate " + name, cls);
    return cls;
  }

  protected Map<String, ClassNodeElement> loadFile(final String name) {
    String source = getResource(name);
    return loadSource(source);
  }

  protected Map<String, ClassNodeElement> loadSource(String source) {
    Map<String, ClassNodeElement> classes = Maps.newLinkedHashMap();
    DartUnit unit = parseUnit(source);
    Scope scope = getMockScope("<test toplevel>");
    LibraryElement libraryElement = scope.getLibrary();
    libraryElement.getScope().declareElement("Object", object);
    unit.setLibrary(libraryElement.getLibraryUnit());
    TopLevelElementBuilder elementBuilder = new TopLevelElementBuilder();
    elementBuilder.exec(unit.getLibrary(), unit, context);
    for (DartNode node : unit.getTopLevelNodes()) {
      if (node instanceof DartClass) {
        DartClass classNode = (DartClass) node;
        ClassNodeElement classElement = classNode.getElement();
        String className = classElement.getName();
        coreElements.put(className, classElement);
        classes.put(className, classElement);
      } else if (node instanceof DartFieldDefinition) {
        DartFieldDefinition fieldNode = (DartFieldDefinition) node;
        for (DartField field : fieldNode.getFields()) {
          Element fieldElement = field.getElement();
          coreElements.put(fieldElement.getName(), fieldElement);
        }
      } else {
        DartFunctionTypeAlias alias = (DartFunctionTypeAlias) node;
        FunctionAliasElement element = alias.getElement();
        coreElements.put(element.getName(), element);
      }
    }
    SupertypeResolver supertypeResolver = new SupertypeResolver();
    supertypeResolver.exec(unit, context, scope, typeProvider);
    MemberBuilder memberBuilder = new MemberBuilder();
    memberBuilder.exec(unit, context, scope, typeProvider);
    resolver.exec(unit);
    return classes;
  }

  protected Map<String, ClassNodeElement> loadSource(String firstLine, String secondLine,
                                               String... rest) {
    return loadSource(Joiner.on('\n').join(firstLine, secondLine, (Object[]) rest).toString());
  }

  private TypeAnalyzer.Analyzer makeTypeAnalyzer(ClassElement element) {
    TypeAnalyzer.Analyzer analyzer =
        new TypeAnalyzer.Analyzer(context, typeProvider, diagnosedAbstractClasses);
    analyzer.setCurrentClass(element.getType());
    return analyzer;
  }

  private DartExpression parseExpression(String source) {
    return getParser(source).parseExpression();
  }

  private DartStatement parseStatement(String source) {
    return getParser(source).parseStatement();
  }

  private DartUnit parseUnit(String string) {
    DartSourceString source = new DartSourceString("<source string>", string);
    return getParser(string).parseUnit(source);
  }

  protected String returnWithType(String type, Object expression) {
    return String.format("%s foo() { return %s; }", type, String.valueOf(expression));
  }

  @Override
  protected void tearDown() {
    resolver = null;
    diagnosedAbstractClasses = null;
  }

  private Type typeOf(String expression) {
    return analyzeNode(parseExpression(expression));
  }
}
