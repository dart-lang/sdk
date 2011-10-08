// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.common.collect.Lists;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartCompilerErrorCode;
import com.google.dart.compiler.InternalCompilerException;
import com.google.dart.compiler.ast.DartArrayAccess;
import com.google.dart.compiler.ast.DartArrayLiteral;
import com.google.dart.compiler.ast.DartAssertion;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartBooleanLiteral;
import com.google.dart.compiler.ast.DartBreakStatement;
import com.google.dart.compiler.ast.DartCase;
import com.google.dart.compiler.ast.DartCatchBlock;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartClassMember;
import com.google.dart.compiler.ast.DartConditional;
import com.google.dart.compiler.ast.DartContinueStatement;
import com.google.dart.compiler.ast.DartDefault;
import com.google.dart.compiler.ast.DartDoWhileStatement;
import com.google.dart.compiler.ast.DartDoubleLiteral;
import com.google.dart.compiler.ast.DartEmptyStatement;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartForInStatement;
import com.google.dart.compiler.ast.DartForStatement;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionObjectInvocation;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartIfStatement;
import com.google.dart.compiler.ast.DartImportDirective;
import com.google.dart.compiler.ast.DartInitializer;
import com.google.dart.compiler.ast.DartIntegerLiteral;
import com.google.dart.compiler.ast.DartInvocation;
import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartLibraryDirective;
import com.google.dart.compiler.ast.DartMapLiteral;
import com.google.dart.compiler.ast.DartMapLiteralEntry;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartNamedExpression;
import com.google.dart.compiler.ast.DartNativeBlock;
import com.google.dart.compiler.ast.DartNativeDirective;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartNodeTraverser;
import com.google.dart.compiler.ast.DartNullLiteral;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartParameterizedNode;
import com.google.dart.compiler.ast.DartParenthesizedExpression;
import com.google.dart.compiler.ast.DartPlainVisitor;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartRedirectConstructorInvocation;
import com.google.dart.compiler.ast.DartResourceDirective;
import com.google.dart.compiler.ast.DartReturnStatement;
import com.google.dart.compiler.ast.DartSourceDirective;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartStringInterpolation;
import com.google.dart.compiler.ast.DartStringLiteral;
import com.google.dart.compiler.ast.DartSuperConstructorInvocation;
import com.google.dart.compiler.ast.DartSuperExpression;
import com.google.dart.compiler.ast.DartSwitchStatement;
import com.google.dart.compiler.ast.DartSyntheticErrorExpression;
import com.google.dart.compiler.ast.DartSyntheticErrorStatement;
import com.google.dart.compiler.ast.DartThisExpression;
import com.google.dart.compiler.ast.DartThrowStatement;
import com.google.dart.compiler.ast.DartTryStatement;
import com.google.dart.compiler.ast.DartTypeExpression;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnaryExpression;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.DartVariableStatement;
import com.google.dart.compiler.ast.DartWhileStatement;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.backend.common.TypeHeuristic.FieldKind;
import com.google.dart.compiler.backend.js.ScopeRootInfo.DartScope;
import com.google.dart.compiler.backend.js.ast.JsArrayLiteral;
import com.google.dart.compiler.backend.js.ast.JsBinaryOperation;
import com.google.dart.compiler.backend.js.ast.JsBinaryOperator;
import com.google.dart.compiler.backend.js.ast.JsBlock;
import com.google.dart.compiler.backend.js.ast.JsBreak;
import com.google.dart.compiler.backend.js.ast.JsCase;
import com.google.dart.compiler.backend.js.ast.JsCatch;
import com.google.dart.compiler.backend.js.ast.JsConditional;
import com.google.dart.compiler.backend.js.ast.JsContinue;
import com.google.dart.compiler.backend.js.ast.JsDefault;
import com.google.dart.compiler.backend.js.ast.JsDoWhile;
import com.google.dart.compiler.backend.js.ast.JsExprStmt;
import com.google.dart.compiler.backend.js.ast.JsExpression;
import com.google.dart.compiler.backend.js.ast.JsFor;
import com.google.dart.compiler.backend.js.ast.JsFunction;
import com.google.dart.compiler.backend.js.ast.JsIf;
import com.google.dart.compiler.backend.js.ast.JsInvocation;
import com.google.dart.compiler.backend.js.ast.JsLabel;
import com.google.dart.compiler.backend.js.ast.JsLiteral;
import com.google.dart.compiler.backend.js.ast.JsName;
import com.google.dart.compiler.backend.js.ast.JsNameRef;
import com.google.dart.compiler.backend.js.ast.JsNew;
import com.google.dart.compiler.backend.js.ast.JsNode;
import com.google.dart.compiler.backend.js.ast.JsNullLiteral;
import com.google.dart.compiler.backend.js.ast.JsNumberLiteral;
import com.google.dart.compiler.backend.js.ast.JsObjectLiteral;
import com.google.dart.compiler.backend.js.ast.JsParameter;
import com.google.dart.compiler.backend.js.ast.JsPostfixOperation;
import com.google.dart.compiler.backend.js.ast.JsPrefixOperation;
import com.google.dart.compiler.backend.js.ast.JsProgram;
import com.google.dart.compiler.backend.js.ast.JsPropertyInitializer;
import com.google.dart.compiler.backend.js.ast.JsReturn;
import com.google.dart.compiler.backend.js.ast.JsScope;
import com.google.dart.compiler.backend.js.ast.JsStatement;
import com.google.dart.compiler.backend.js.ast.JsStringLiteral;
import com.google.dart.compiler.backend.js.ast.JsSwitch;
import com.google.dart.compiler.backend.js.ast.JsSwitchMember;
import com.google.dart.compiler.backend.js.ast.JsThisRef;
import com.google.dart.compiler.backend.js.ast.JsThrow;
import com.google.dart.compiler.backend.js.ast.JsTry;
import com.google.dart.compiler.backend.js.ast.JsUnaryOperator;
import com.google.dart.compiler.backend.js.ast.JsValueLiteral;
import com.google.dart.compiler.backend.js.ast.JsVars;
import com.google.dart.compiler.backend.js.ast.JsVars.JsVar;
import com.google.dart.compiler.backend.js.ast.JsWhile;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ConstructorElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.EnclosingElement;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.SuperElement;
import com.google.dart.compiler.resolver.VariableElement;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeKind;
import com.google.dart.compiler.type.Types;
import com.google.dart.compiler.util.AstUtil;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Deque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.Stack;
import java.util.concurrent.Callable;

/**
 * Visitor that generates a Javascript AST from an existing Dart AST.
 */
public class GenerateJavascriptAST {
  private final DartCompilerContext context;
  private final OptimizationStrategy optStrategy;
  private final DartUnit unit;
  private CoreTypeProvider typeProvider;

  /**
   * Generates the Javascript AST using the names created in {@link GenerateNamesAndScopes}.
   */
  static class GenerateJavascriptVisitor
      implements DartPlainVisitor<JsNode>, TraversalContextProvider {

    private static boolean isSuperCall(Symbol symbol) {
      return ElementKind.of(symbol).equals(ElementKind.SUPER);
    }

    /**
     * Returns <code>true</code> for members that are static or should be treated
     * as if the user had declared them as static.
     */
    private static boolean isDeclaredAsStaticOrImplicitlyStatic(Element element) {
      Modifiers modifiers = element.getModifiers();
      if (modifiers.isStatic()) {
        // Member was actually declared static
        return true;
      }

      if (Elements.isTopLevel(element)) {
        // Top level fields and methods are implicitly static
        ElementKind elementKind = ElementKind.of(element);
        return elementKind == ElementKind.FIELD || elementKind == ElementKind.METHOD;
      }

      return false;
    }

    /**
     * The name of the javascript function used to intern compile time constants
     */
    private static final String INTERN_CONST_FUNCTION = "$intern";

    /**
     * The name of the function used to lookup a id for a constant object
     */
    private static final String DART_CONST_ID_JS_FUNC = "$dart_const_id";

    /**
     * The name of the method use to generate the id for an constant object
     */
    private static final String CONST_ID_JS_METHOD_NAME = "$const_id";

    private static final String STATIC_UNINITIALIZED = "static$uninitialized";
    private static final String STATIC_INITIALIZING = "static$initializing";
    private static final String ISOLATE_CURRENT = "isolate$current";
    private static final String ISOLATE_INITS = "isolate$inits";
    private static final String ISOLATE_DEFAULT_FACTORY = "default$factory";
    static final int MAX_SPECIALIZED_BIND_SCOPES = 3;
    static final int MAX_SPECIALIZED_BIND_ARGS = 5;
    private static final String ISOLATE_ISOLATE_FACTORY = "isolateFactory";
    private static final String ISOLATE_ISOLATE_FACTORY_GETTER = "getIsolateFactory";

    private final JsScope globalScope;
    private final JsBlock globalBlock;
    private final List<JsStatement> staticInit = Lists.newArrayList();
    private final Deque<DartFunction> functionStack = new LinkedList<DartFunction>();
    private final Deque<Set<JsName>> jsNewDeclarationsStack = new LinkedList<Set<JsName>>();
    private Element currentHolder;
    private boolean inFactoryOrStaticContext = false;
    private ScopeRootInfo currentScopeInfo;
    private JsName traceCounter;
    private final RuntimeTypeInjector rtt;

    private final TranslationContext translationContext;
    private final OptimizationStrategy optStrategy;
    private final DartCompilerContext context;
    private final LibraryElement unitLibrary;
    private final DartMangler mangler;
    private final CoreTypeProvider typeProvider;
    private final Types typeUtils;

    public GenerateJavascriptVisitor(DartUnit unit, DartCompilerContext context,
        TranslationContext translationContext,
        OptimizationStrategy optStrategy, CoreTypeProvider typeProvider) {
      this.context = context;
      this.translationContext = translationContext;
      this.optStrategy = optStrategy;
      this.typeProvider = typeProvider;
      this.typeUtils = Types.getInstance(typeProvider);
      this.unitLibrary = unit.getLibrary().getElement();

      // Cache the mangler in a field since it is used frequently
      mangler = translationContext.getMangler();

      JsProgram program = translationContext.getProgram();
      globalScope = program.getScope();
      globalBlock = program.getGlobalBlock();
      // setup the global scope.
      jsNewDeclarationsStack.push(new HashSet<JsName>());
      currentHolder = unit.getLibrary().getElement();
      rtt = new RuntimeTypeInjector(this, typeProvider, translationContext,
          context.getCompilerConfiguration().developerModeChecks());
    }

    /**
     * @param block The global block to add the static init statements too.
     */
    public void addStaticInitsToBlock(JsBlock block) {
      if (staticInit.isEmpty()) return;
      JsFunction init = new JsFunction(globalScope);
      JsBlock body = new JsBlock();
      body.getStatements().addAll(staticInit);
      init.setBody(body);
      staticInit.clear();

      // All the static variable initialization code belonging to the
      // current compilation unit is appended to the initialization
      // list (isolate$inits) through Array.prototype.push.
      JsNameRef pushRef = AstUtil.newNameRef(new JsNameRef(ISOLATE_INITS), "push");
      JsInvocation invokePush = AstUtil.newInvocation(pushRef);
      invokePush.getArguments().add(init);
      block.getStatements().add(new JsExprStmt(invokePush));
    }

    /**
     * @return the JsScope that is used to create temporary Js-variables in the current scope.
     */
    private JsScope getCurrentFunctionScope() {
      return translationContext.getMethods().get(functionStack.peek()).getScope();
    }

    /**
     * Adds the given name to the declarations-array. All names in the array will be declared at
     * the beginning of the function. The same name can be registered multiple times.
     * @param name
     */
    private void registerForDeclaration(JsName name) {
      jsNewDeclarationsStack.peek().add(name);
    }


    /**
     * Creates a temporary variable but does not register it for var-declaration.
     * @return the JsName of the temporary.
     */
    private JsName createNonVarTempory() {
      JsScope scope;
      if (!functionStack.isEmpty()) {
        scope = getCurrentFunctionScope();
      } else {
        scope = globalScope;
      }
      return scope.declareTemporary();
    }

    /**
     * Creates a temporary variable and registers it, so that an declaration statement is
     * emitted.
     * @return the JsName of the temporary.
     */
    @Override
    public JsName createTemporary() {
      JsName temp = createNonVarTempory();
      registerForDeclaration(temp);
      return temp;
    }

    /**
     * Returns the JsName for the given element. If the element is global and
     * hasn't been declared yet, it is done now.
     */
    private JsName getJsName(Symbol symbol) {
      return translationContext.getNames().getName(symbol);
    }

    /**
     * Creates a JS function with JS calling conventions and a deterministic name
     * so that it can be invoked from JS. The function will then forward
     * the call to the given method (with Dart calling conventions).
     */
    private void generateJsExportedFunction(MethodElement element, JsName name) {
      JsFunction fn = new JsFunction(globalScope);

      JsNameRef dartTarget = makeMethodJsReference(element, name);
      JsInvocation callIntoDart = AstUtil.newInvocation(dartTarget);

      List<JsParameter> parameters = fn.getParameters();
      List<JsExpression> arguments = callIntoDart.getArguments();
      for (VariableElement p : element.getParameters()) {
        JsName parameter = fn.getScope().declareFreshName(p.getName());
        parameters.add(new JsParameter(parameter));
        arguments.add(parameter.makeRef());
      }
      JsBlock jsBlock = new JsBlock();
      jsBlock.getStatements().add(new JsReturn(callIntoDart));
      jsBlock.setSourceRef(element.getNode());

      fn.setBody(jsBlock);

      String exportedFunctionName = mangler.mangleNativeMethod(element);
      JsName exportedFunctionJsName = globalScope.declareName(exportedFunctionName,
                                                              exportedFunctionName,
                                                              exportedFunctionName);
      fn.setName(exportedFunctionJsName);
      fn.setSourceRef(element.getNode());
      globalBlock.getStatements().add(fn.makeStmt());
    }

    /**
     * Makes the default-constructor accessible under a deterministic name and
     * with JavaScript calling conventions so that it can be invoked from JS.
     */
    private void generateIsolateDefaultFactoryMember(MethodElement element, JsName funcName) {
      JsName className = getJsName(element.getEnclosingElement());
      JsNameRef unmangledName = AstUtil.newNameRef(className.makeRef(), ISOLATE_DEFAULT_FACTORY);
      JsNameRef factoryName = AstUtil.newNameRef(className.makeRef(), funcName);
      JsBinaryOperation defaultAsg = AstUtil.newAssignment(unmangledName, factoryName);
      defaultAsg.setSourceRef(element.getNode());
      globalBlock.getStatements().add(defaultAsg.makeStmt());
    }

    @Override
    public JsNode visitClass(DartClass x) {
      assert ElementKind.of(currentHolder).equals(ElementKind.LIBRARY)
          : "Nested classes should be impossible";
      Element previousHolder = currentHolder;
      currentHolder = x.getSymbol();

      ClassElement classElement = x.getSymbol();
      JsName classJsName = getJsName(classElement);

      // If there is already a native class we must not create the JS function.
      if (classElement.getNativeName() == null) {
        if (optStrategy.canEmitOptimizedClassConstructor(classElement)) {
          createInlinedClassConstructor(x);
        } else {
          JsFunction jsClass = new JsFunction(globalScope, classJsName).setSourceRef(x);
          jsClass.setIsConstructor(true);
          jsClass.setBody(new JsBlock());
          globalBlock.getStatements().add(jsClass.makeStmt());
        }
      }

      rtt.generateRuntimeTypeInfo(x);
      maybeInjectIsolateMethods(classElement);

      if (classElement.isInterface()) {
        // Emit only static final fields for interfaces.
        for (Element member : classElement.getMembers()) {
          if (ElementKind.of(member).equals(ElementKind.FIELD)) {
            Modifiers modifiers = member.getModifiers();
            if (modifiers.isStatic() && !modifiers.isAbstractField()) {
              assert modifiers.isFinal();
              generateField((FieldElement) member);
            }
          }
        }
      } else {
        // Inherits.
        if (x.getSuperSymbol() != null) {
          JsNameRef superRef = getJsName(x.getSuperSymbol()).makeRef();
          JsInvocation inherits = AstUtil.newInvocation(
              new JsNameRef("$inherits"),
              classJsName.makeRef(),
              superRef);
          inherits.setSourceRef(x);
          globalBlock.getStatements().add(inherits.makeStmt());
        }

        List<Element> classMembers = new ArrayList<Element>();
        classMembers.addAll(classElement.getConstructors());
        for (Element element : classElement.getMembers()) {
          classMembers.add(element);
        }
        
        if (Elements.needsImplicitDefaultConstructor(classElement)) {
          addImplicitDefaultConstructor(x, classElement, classMembers);
        }
        
        for (Element member : classMembers) {
          switch(ElementKind.of(member)) {
            case METHOD: {
              MethodElement methodElement = (MethodElement) member;
              generateMethodDefinition(methodElement);
              if (!methodElement.getModifiers().isOperator()) {
                generateMethodGetter(methodElement);
              }
              break;
            }

            case CONSTRUCTOR:
              generateMethodDefinition((MethodElement) member);
              break;

            case FIELD:
              generateField((FieldElement) member);
              break;

            default:
              throw new AssertionError("Invalid member " + member);
          }
        }

        // TODO(johnlenz): should we create a stub method to catch
        // class without const constructors? As is, the a non-const
        // class with get the id of an "const Object".
        if (hasConstConstructor(classElement)) {
          makeConstIdMethod(classElement);
        }

        // Add temporary variable declarations, if any.
        // TODO(johnlenz): This isn't always correct: an incremental compile
        // might reuse temps, which we don't want. However, static initializations
        // (where the temps would be used) aren't quite right either yet. Double
        // check this when its done.
        Set<JsName> temps = jsNewDeclarationsStack.peek();
        declareTempsInBlock(globalBlock, temps);

        // Clear the set for the next class.
        temps.clear();
      }

      assert currentHolder == x.getSymbol() : "Unbalanced class visitation";
      currentHolder = previousHolder;

      return null;
    }

    private void addImplicitDefaultConstructor(DartClass x, ClassElement classElement, 
        List<Element> classElementMembers) {
      for (DartNode member : x.getMembers()) {
        if (member instanceof DartMethodDefinition) {
          DartMethodDefinition method = (DartMethodDefinition) member;
          MethodElement symbol = method.getSymbol();
          if (symbol.isConstructor() && "".equals(symbol.getName())) {
            classElementMembers.add(symbol);
          }
        }
      }
    }

    /**
     * @param classElement
     *
     */
    private void maybeInjectIsolateMethods(ClassElement classElement) {
      if (isIsolateClass(classElement)) {
        // In order to construct an isolate in another worker, it must be
        // referrable by name, this requires a top level method.
        generateIsolateFactory(classElement);

        // ... and a way to get the factory from a isolate instance
        generateIsolateFactoryGetter(classElement);
      }
    }

    private JsName getIsolateFactoryFunctionName(ClassElement classElement) {
      String fnNameStr = getJsName(classElement).getShortIdent() + "$" + ISOLATE_ISOLATE_FACTORY;
      return globalScope.declareName(fnNameStr);
    }

    private JsNameRef getIsolateFactoryGetterName(ClassElement classElement) {
      return AstUtil.newNameRef(
          AstUtil.newPrototypeNameRef(getJsName(classElement).makeRef()),
          ISOLATE_ISOLATE_FACTORY_GETTER);
    }

    private void generateIsolateFactory(ClassElement classElement) {
      // Create static factory function:
      // function Foo$IsolateFactory() {
      //   return Foo.default$Factory();
      // }

      // Build the function
      JsName fnName = getIsolateFactoryFunctionName(classElement);

      JsNameRef defaultFactory = AstUtil.newNameRef(
          getJsName(classElement).makeRef(), ISOLATE_DEFAULT_FACTORY);
      JsInvocation invokeFactory = AstUtil.newInvocation(defaultFactory);

      // TODO(johnlenz): Add runtime type information if necessary.
      JsFunction factoryFn = AstUtil.newFunction(globalScope, fnName, null,
          new JsReturn(invokeFactory));

      globalBlock.getStatements().add(factoryFn.makeStmt());
    }

    private void generateIsolateFactoryGetter(ClassElement classElement) {
      // Create static factory function:
      // function Foo.prototype.getFactory() {
      //   return Foo$IsolateFactory;
      // }

      // Build the function
      JsName fnName = getIsolateFactoryFunctionName(classElement);
      JsFunction getterFn = AstUtil.newFunction(globalScope, null, null,
          new JsReturn(fnName.makeRef()));

      // Declare it.
      JsExpression declStmt = AstUtil.newAssignment(
          getIsolateFactoryGetterName(classElement), getterFn);
      globalBlock.getStatements().add(declStmt.makeStmt());
    }

    private boolean isIsolateClass(ClassElement classElement) {
      InterfaceType classType = classElement.getType();
      return TypeKind.of(classType) == TypeKind.INTERFACE
          && typeUtils.isSubtype(classType, typeProvider.getIsolateType());
    }

    /**
     * Creates a $getter for a method of a class, returning $method as a closure
     * bound to the current instance if it is an instance method.
     */
    private void generateMethodGetter(MethodElement methodElement) {
      // Generate a getter for method binding to a variable
      JsNameRef classJsNameRef = getJsName(methodElement.getEnclosingElement()).makeRef();
      String getterName = mangler.createGetterSyntax(methodElement, unitLibrary);
      String methodName = methodElement.getName();
      JsName getterJsName = globalScope.declareName(getterName, getterName, methodName);
      getterJsName.setObfuscatable(false);
      String mangledMethodName = mangler.mangleNamedMethod(methodElement, unitLibrary);
      JsFunction func = new JsFunction(globalScope);
      JsNameRef getterJsNameRef;
      JsExpression methodToCall;
      if (methodElement.getModifiers().isStatic()) {
        // function() { return <class><member>$member; }
        getterJsNameRef = AstUtil.newNameRef(classJsNameRef, getterJsName);
        methodToCall = AstUtil.newNameRef(classJsNameRef, mangledMethodName);
        func.setBody(AstUtil.newBlock(new JsReturn(methodToCall)));
      } else {
        // function() { return $bind(<class>.prototype.<member>$member, this); }
        JsNameRef prototypeRef = AstUtil.newPrototypeNameRef(classJsNameRef);
        getterJsNameRef = AstUtil.newNameRef(prototypeRef, getterJsName);
        methodToCall = AstUtil.newNameRef(prototypeRef, mangledMethodName);
        JsExpression bindMethodCall = AstUtil.newInvocation(
            new JsNameRef("$bind"), methodToCall, new JsThisRef());
        func.setBody(AstUtil.newBlock(new JsReturn(bindMethodCall)));
      }
      func.setName(getterJsNameRef.getName());
      func.setSourceRef(methodElement.getNode());
      JsBinaryOperation asg = AstUtil.newAssignment(getterJsNameRef, func);
      asg.setSourceRef(methodElement.getNode());
      globalBlock.getStatements().add(asg.makeStmt());
    }

    private boolean hasConstConstructor(ClassElement element) {
      for (ConstructorElement ctr : element.getConstructors()) {
        if (ctr.getModifiers().isConstant()) {
          return true;
        }
      }
      return false;
    }

    private void makeConstIdMethod(ClassElement classElement) {
      JsNameRef methodRef = makeConstIdMethodRef(classElement);
      JsStatement decl = AstUtil.newAssignment(methodRef,
          makeConstIdMethodFunction(classElement)).makeStmt();
      this.globalBlock.getStatements().add(decl);
    }

    private JsNameRef makeConstIdMethodRef(ClassElement classElement) {
      // Instance methods hang from the prototype.
      JsNameRef qualifier = AstUtil.newPrototypeNameRef(getJsName(classElement).makeRef());
      JsNameRef methodRef = AstUtil.newNameRef(qualifier, CONST_ID_JS_METHOD_NAME);
      return methodRef;
    }

    private JsFunction makeConstIdMethodFunction(ClassElement classElement) {
      JsFunction func = new JsFunction(this.globalScope);
      // Make an id like:
      //   <type>:field1:field2:...-<supertype>:field1:field2:...
      JsExpression idExpr = rtt.getRTTClassId(classElement);
      for (Element member : classElement.getMembers()) {
        if (member.getKind() == ElementKind.FIELD) {
          if (!member.getModifiers().isStatic()) {
            idExpr = addConstIdFieldExpr((FieldElement) member, idExpr);
          }
        }
      }
      idExpr = addConstIdSuperExpr(classElement, idExpr);
      func.setBody(AstUtil.newBlock(new JsReturn(idExpr)));
      return func;
    }

    private JsExpression addConstIdFieldExpr(
         FieldElement element, JsExpression prevPart) {
      JsExpression qualifier = getGetterSetterQualifier(element);
      JsName fieldJsName = getJsName(element);
      JsNameRef ref = AstUtil.newNameRef(qualifier, fieldJsName);

      // example:  prevPart + ":" + $const_id(this.field)
      return add(prevPart, add(string(":"),
                 AstUtil.newInvocation(new JsNameRef(DART_CONST_ID_JS_FUNC), ref)));
    }

    private JsExpression addConstIdSuperExpr(ClassElement element, JsExpression prevPart) {
      InterfaceType superType = element.getSupertype();
      if (superType == null || superType.getElement().isObject()) {
        // The root object doesn't add anything.
        return prevPart;
      }
      JsNameRef superConstIdRef = makeConstIdMethodRef(superType.getElement());
      JsNameRef callRef = AstUtil.newNameRef(superConstIdRef, "call");
      JsInvocation superCall = AstUtil.newInvocation(callRef, new JsThisRef());

      // example:  prevPart + "-" + super.prototype.$const_id.call(this);
      return add(prevPart, add(string("-"), superCall));
    }

    private JsExpression add(JsExpression first, JsExpression second) {
      return new JsBinaryOperation(JsBinaryOperator.ADD, first, second);
    }

    private void generateField(FieldElement element) {
      generate(element.getNode());
    }

    private void generateMethodDefinition(MethodElement element) {
      JsFunction func = (JsFunction) generate(element.getNode());

      // makeMethod clears the name of the function.
      JsName funcName = func.getName();
      makeMethod(element, func);

      // If the method is the default factory we add the same method under an unmangled name.
      // This is necessary for the isolate code.
      if (Elements.isNonFactoryConstructor(element)
          && "".equals(element.getName())
          && func.getParameters().size() == 0
          && isIsolateClass((ClassElement)element.getEnclosingElement())) {
        generateIsolateDefaultFactoryMember(element, funcName);
      }

      // If the function is exported to JavaScript make it accessible under its
      // (more or less) unmangled name.
      DartMethodDefinition method = (DartMethodDefinition) element.getNode();
      DartBlock body = method.getFunction().getBody();
      if (element.getModifiers().isNative() && !(body instanceof DartNativeBlock)) {
        generateJsExportedFunction(element, funcName);
      }
    }

    private void createInlinedClassConstructor(DartClass x) {
      ClassElement classElement = x.getSymbol();
      assert classElement.getNativeName() == null;
      JsName classJsName = getJsName(classElement);
      JsFunction jsClass = new JsFunction(globalScope, classJsName).setSourceRef(x);
      jsClass.setIsConstructor(true);
      JsBlock block = new JsBlock();
      JsScope scope = new JsScope(globalScope, "temp");
      for (FieldElement fieldElement : getFieldsInClassHierarchy(classElement)) {
        String fieldName = translationContext.getMangler().mangleField(fieldElement, unitLibrary);
        JsNameRef fieldRef = AstUtil.newNameRef(new JsThisRef(), fieldName);
        JsName paramName = scope.declareName("p$" + fieldName);
        jsClass.getParameters().add(new JsParameter(paramName));
        JsBinaryOperation asg = AstUtil.newAssignment(fieldRef, new JsNameRef(paramName));
        block.getStatements().add(asg.makeStmt());
      }
      jsClass.setBody(block);
      globalBlock.getStatements().add(jsClass.makeStmt());
    }

    private List<FieldElement> getFieldsInClassHierarchy(ClassElement classElement) {
      InterfaceType current = classElement.getType();
      Stack<ClassElement> classes = new Stack<ClassElement>();
      while ((current != null) && !current.getElement().isObject()) {
        classElement = current.getElement();
        classes.push(classElement);
        current = classElement.getSupertype();
      }
      List<FieldElement> fields = Lists.newArrayList();
      while (!classes.isEmpty()) {
        classElement = classes.pop();
        for (Element elem : classElement.getMembers()) {
          Modifiers modifiers = elem.getModifiers();
          if (ElementKind.of(elem).equals(ElementKind.FIELD) && !modifiers.isStatic()
              && !modifiers.isAbstractField()) {
            fields.add((FieldElement) elem);
          }
        }
      }
      return fields;
    }

    private void generateAbstractField(FieldElement fieldElement) {
      if (fieldElement.getGetter() != null) {
        generateMethodDefinition(fieldElement.getGetter());
      }
      if (fieldElement.getSetter() != null) {
        generateMethodDefinition(fieldElement.getSetter());
      }
    }

    private void declareTempsInBlock(JsBlock block, Collection<JsName> tempCollection) {
      // Add temporary variable declarations, if any.
      Iterator<JsName> temps = tempCollection.iterator();
      if (temps.hasNext()) {
        JsVars jsVars = new JsVars();
        while (temps.hasNext()) {
          JsName name = temps.next();
          JsVars.JsVar jsVar = new JsVars.JsVar(name);
          jsVars.insert(jsVar);
        }
        block.getStatements().add(0, jsVars);
      }
    }

    private List<DartField> getInlineFieldInitializers(ConstructorElement element) {
      List<DartField> fieldInitializers = new ArrayList<DartField>();
      Iterable<Element> classMembers = element.getEnclosingElement().getMembers();
      for (Element member : classMembers) {
        Modifiers modifiers = member.getModifiers();
        if (!modifiers.isStatic()
            && !modifiers.isAbstractField()
            && ElementKind.of(member).equals(ElementKind.FIELD)) {
          DartField field = (DartField) member.getNode();
          if (field.getValue() != null) {
            fieldInitializers.add(field);
          }
        }
      }
      return fieldInitializers;
    }

    private JsExpression generateInlineFieldInitializer(DartField field) {
      JsNameRef fieldName = AstUtil.newNameRef(new JsThisRef(), getJsName(field.getSymbol()));
      JsExpression initExpr = (JsExpression) generate(field.getValue());
      return AstUtil.newAssignment(fieldName, initExpr);
    }

    /**
     * For a constructor B whose super is A we generate:
     *
     * FactoryB() {
     *   var tmp = new B;
     *   InitB(tmp);
     *   BodyB(tmp);
     * }
     *
     * BodyB() {
     *   BodyA();
     * }
     *
     * InitB() {
     *   InitA();
     * }
     *
     * This method creates the InitB method and adds the BodyA call in the BodyB method.
     */
    private void addInitializers(DartMethodDefinition constructor,
                                 JsFunction factory,
                                 JsName tempVar) {
      ConstructorElement element = (ConstructorElement) constructor.getSymbol();
      JsScope classMemberScope = translationContext.getMemberScopes().get(element.getEnclosingElement());
      JsName curClassJsName = getJsName(element.getEnclosingElement());

      // Create the initializer function.
      String constructorName = element.getName();
      String initName = mangler.createInitializerSyntax(constructorName, unitLibrary);
      JsName initJsName = classMemberScope.declareName(initName, initName, constructorName);
      // Initializers are called from other class (as part of the super initialization).
      initJsName.setObfuscatable(false);
      JsFunction initFunction = new JsFunction(globalScope, initJsName).setSourceRef(constructor);
      initFunction.setBody(new JsBlock());

      // Add the initializer as a member of the current class.
      makeMethod(element, initFunction);

      // Add the parameters to the initializer function.
      List<DartParameter> params = constructor.getFunction().getParams();
      for (DartParameter p : params) {
        initFunction.getParameters().add(
            new JsParameter(getJsName(p.getNormalizedNode().getSymbol())));
      }

      // If there are initializers, or inline field initializers, populate the
      // initializer function.
      List<DartInitializer> initializers = constructor.getInitializers();
      List<DartField> fieldInitializers = getInlineFieldInitializers(element);

      if (!initializers.isEmpty() || !fieldInitializers.isEmpty()) {
        // TODO(johnlenz): move this block shares the some of the same setup
        // and tear down as the visitFunction method.

        // Give the initializer expressions access to the function parameters
        functionStack.push(constructor.getFunction());
        jsNewDeclarationsStack.push(new HashSet<JsName>());

        JsInvocation constructorInvocation = maybeGenerateSuperOrRedirectCall(constructor);
        boolean hasConstructorInvocation = constructorInvocation != null;
        Iterator<DartInitializer> iterator = initializers.iterator();
        Iterator<DartField> fieldIterator = fieldInitializers.iterator();

        List<JsStatement> jsInitializers = initFunction.getBody().getStatements();

        // Do the field inline initializers first. If there are any assignments in the initializer
        // list, they will be the last assignments.
        while (fieldIterator.hasNext()) {
          JsExpression initializer = generateInlineFieldInitializer(fieldIterator.next());
          jsInitializers.add(initializer.makeStmt());
        }

        DartInvocation initInvocation = null;
        while (iterator.hasNext()) {
          DartInitializer initializer = iterator.next();
          if (!initializer.isInvocation()) {
            jsInitializers.add((JsStatement) generate(initializer));
          } else {
            initInvocation = (DartInvocation) initializer.getValue();
          }
        }

        if (hasConstructorInvocation) {
          // Call the super initializer function in the initializer.
          // Compute the super constructor initializer to call.
          ConstructorElement superElement = (ConstructorElement) initInvocation.getSymbol();
          // TODO(floitsch): it would be better if we had a js-name and not just a string.
          // This way the debugging information would be better.
          // We need to generate the JsName (for the initializer/factory) once only and store it
          // in some hashtable. Then instead of reusing the mangler, we should reuse those JsNames.
          // The debugging information would then contain a link from the property-access to the
          // constructor. Without JsName the debugger just assumes we access some random property.
          String mangledSuperConstructorName =
              mangler.createInitializerSyntax(superElement.getName(), unitLibrary);
          Element superClassElement = superElement.getEnclosingElement();
          JsNameRef superInitRef = AstUtil.newNameRef(getJsName(superClassElement).makeRef(),
                                                      mangledSuperConstructorName);
          JsNameRef callRef = AstUtil.newNameRef(superInitRef, "call");
          JsInvocation superInitCall = AstUtil.newInvocation(callRef);
          initFunction.getBody().getStatements().add(0, superInitCall.makeStmt());
          // TODO(floitsch): don't copy the arguments from the super call for the initializer call.
          // This will evaluate side-effects twice, and we are reusing nodes (thereby creating a
          // DAG instead of a tree).
          superInitCall.getArguments().addAll(constructorInvocation.getArguments());
        }

        // Call the initializer in the factory. This must be executed
        // before calling the super constructor: <class>.<name>$Initializer.call(this, ...)
        JsNameRef initRef = AstUtil.newNameRef(curClassJsName.makeRef(), initJsName);
        JsNameRef initCallRef = AstUtil.newNameRef(initRef, "call");
        JsInvocation initCall = AstUtil.newInvocation(initCallRef, tempVar.makeRef());
        for (DartParameter p : params) {
          initCall.getArguments().add(getJsName(p.getNormalizedNode().getSymbol()).makeRef());
        }

        factory.getBody().getStatements().add(0, initCall.makeStmt());

        // Dart does not have an implicit call to a super constructor.

        // Add temporary variable declarations, if any.
        declareTempsInBlock(initFunction.getBody(), jsNewDeclarationsStack.pop());

        // setup the scope alias for the init function
        maybeAddFunctionScopeAlias(
            currentScopeInfo.getScope(constructor.getFunction()), initFunction);

        // Remove the containing function scope.
        functionStack.pop();
      }
    }

    private void addSuperOrRedirectConstructorCall(DartMethodDefinition constructor) {
      JsInvocation superCall = maybeGenerateSuperOrRedirectCall(constructor);
      if (superCall != null) {
        // If we have a super constructor call, add it as the first statement
        // in the constructor body.
        // <super-class>.<name>$Constructor.call(this, ...).
        JsFunction constructorFunction = translationContext.getMethods().get(constructor.getFunction());
        constructorFunction.getBody().getStatements().add(0, superCall.makeStmt());
      }
    }

    private JsInvocation maybeGenerateSuperOrRedirectCall(DartMethodDefinition constructor) {
      // If there are initializers, populate the initializer function.
      List<DartInitializer> initializers = constructor.getInitializers();
      if (!initializers.isEmpty()) {
        for (DartInitializer init : initializers) {
          if (init.isInvocation()) {
            JsExprStmt statement = (JsExprStmt) generate(init);
            return (JsInvocation) statement.getExpression();
          }  
        }
      }
      return null;
    }

    private JsNode generateConstructorDefinition(DartMethodDefinition x) {
      assert currentScopeInfo == null : "Nesting a constructor in a method should be impossible";
      currentScopeInfo = ScopeRootInfo.makeScopeInfo(x, !shouldGenerateDeveloperModeChecks());
      ConstructorElement element = (ConstructorElement) x.getSymbol();
      ClassElement classElement = (ClassElement) element.getEnclosingElement();
      JsScope classMemberScope = translationContext.getMemberScopes().get(classElement);
      String constructorName = element.getName();
      JsName curClassJsName = getJsName(classElement);

      JsFunction dartCtor = (JsFunction) generate(x.getFunction());

      // Add the constructor as a member of the current class.
      makeMethod(element, dartCtor);

      // Create the static factory function that allocates the object
      // and calls the constructor.
      // <class>.ConstructorName$Factory = function (args ...) {
      //    var tmp = new <class>();
      //    tmp.$typeInfo = runtimeType;
      //    <class>.ConstructorName$Constructor.call(tmp, args ...);
      //    return tmp;
      // }
      // Attaching the factory to <class> is done outside this method. We just provide the
      // factory-name ("ConstructorName$Factory" here).

      // The factory becomes a member of <class> and should therefore be declared in the same
      // scope as all other members.
      String className = element.getConstructorType().getName();
      String factoryName = mangler.createFactorySyntax(className, constructorName, unitLibrary);
      JsName factoryJsName =
          classMemberScope.declareName(factoryName, factoryName, constructorName);
      // Factories are globally accessible.
      factoryJsName.setObfuscatable(false);

      JsFunction factoryFunction = new JsFunction(globalScope, factoryJsName).setSourceRef(x);
      JsScope factoryScope = factoryFunction.getScope();

      // We do the constructor invocation before we declare the temporary variable. This is
      // necessary to ensure that the created temporary does not conflict with the parameters.
      JsInvocation constructorInvocation = new JsInvocation();
      JsName constructorJsName = getJsName(element);
      JsNameRef constructorRef = AstUtil.newNameRef(curClassJsName.makeRef(), constructorJsName);
      constructorInvocation.setQualifier(AstUtil.newNameRef(constructorRef, "call"));

      // Add the arguments to the constructor invocation. Note that the constructor call is still
      // missing the 'tmp' variable. We will add it later.
      List<DartParameter> params = x.getFunction().getParams();
      for (DartParameter p : params) {
        // TODO(ngeoffray): We should actually copy the arguments. See b/4424659.
        JsName argName = getJsName(p.getNormalizedNode().getSymbol());
        constructorInvocation.getArguments().add(argName.makeRef());
      }

      JsName tempVar = factoryScope.declareTemporary();
      // Add the 'tmp' var to the constructor call.
      constructorInvocation.getArguments().add(0, tempVar.makeRef());

      factoryFunction.setBody(AstUtil.newBlock(
          constructorInvocation.makeStmt(),
          new JsReturn(tempVar.makeRef())));

      if (optStrategy.canInlineInitializers(element)) {
        rtt.maybeAddClassRuntimeTypeToConstructor(classElement, factoryFunction, tempVar.makeRef());
        generateInitializersInlined(x, factoryFunction, factoryScope, tempVar);
      } else {
        addInitializers(x, factoryFunction, tempVar);
        rtt.maybeAddClassRuntimeTypeToConstructor(classElement, factoryFunction, tempVar.makeRef());
        JsNew jsNew = new JsNew(curClassJsName.makeRef());
        factoryFunction.getBody().getStatements().add(0, AstUtil.newVar(x, tempVar, jsNew));
      }

      generateAll(x.getFunction().getParams(), factoryFunction.getParameters(), JsParameter.class);

      assert currentScopeInfo != null;
      inFactoryOrStaticContext = false;
      currentScopeInfo = null;

      return factoryFunction;
    }

    private void generateInitializersInlined(DartMethodDefinition x, JsFunction factoryFunction,
                                             JsScope factoryScope, JsName tempVar) {
      ConstructorElement element = (ConstructorElement) x.getSymbol();
      JsName curClassJsName = getJsName(element.getEnclosingElement());
      Map<FieldElement, JsExpression> initMap = new HashMap<FieldElement, JsExpression>();
      JsExpression superInvocation = null;
      for (DartInitializer init : x.getInitializers()) {
        JsExpression initValue = (JsExpression) generate(init.getValue());
        if (init.isInvocation()) {
          superInvocation = initValue;
          continue;
        } else {
          assert ElementKind.of(init.getName().getTargetSymbol()).equals(ElementKind.FIELD);
          FieldElement fieldElement = (FieldElement) init.getName().getTargetSymbol();
          initMap.put(fieldElement, initValue);
        }
      }
      List<JsStatement> stmts = Lists.newArrayList();
      JsNew jsNew = new JsNew(curClassJsName.makeRef());
      ClassElement classElement = (ClassElement) element.getEnclosingElement();
      for (FieldElement fieldElement : getFieldsInClassHierarchy(classElement)) {
        String fieldName = translationContext.getMangler().mangleField(fieldElement, unitLibrary);
        JsName tmp = factoryScope.declareName("init$" + fieldName);
        JsExpression initValue = initMap.get(fieldElement);
        if (initValue == null) {
          DartField fieldNode = (DartField) fieldElement.getNode();
          if (fieldNode.getValue() != null) {
            initValue = (JsExpression) generate(fieldNode.getValue());
          } else {
            initValue = undefined();
          }
        }
        stmts.add(AstUtil.newVar(x, tmp, initValue));
        jsNew.getArguments().add(new JsNameRef(tmp));
      }
      if (superInvocation != null) {
        factoryFunction.getBody().getStatements().add(0, new JsExprStmt(superInvocation));
      }
      stmts.add(AstUtil.newVar(x, tempVar, jsNew));
      factoryFunction.getBody().getStatements().addAll(0, stmts);
    }

    @Override
    public JsNode visitMethodDefinition(DartMethodDefinition x) {
      assert x == x.getNormalizedNode();
      if (Elements.isNonFactoryConstructor(x.getSymbol())) {
        return generateConstructorDefinition(x);
      }

      assert currentScopeInfo == null : "Nested methods should be impossible";
      inFactoryOrStaticContext = x.getModifiers().isFactory()
          || x.getModifiers().isStatic();
      currentScopeInfo = ScopeRootInfo.makeScopeInfo(x, !shouldGenerateDeveloperModeChecks());

      JsFunction func = (JsFunction) generate(x.getFunction());

      assert currentScopeInfo != null;
      inFactoryOrStaticContext = false;
      currentScopeInfo = null;

      if (Elements.isTopLevel(x.getSymbol())) {
        JsFunction tramp = generateNamedParameterMethodTrampoline(x, func.getName().makeRef());
        String mangled = mangler.mangleNamedMethod(x.getSymbol(), unitLibrary);
        JsName trampName = globalScope.declareName(mangled);
        tramp.setName(trampName);

        globalBlock.getStatements().add(func.makeStmt());
        globalBlock.getStatements().add(tramp.makeStmt());
      }

      return func;
    }

    private JsFunction generateNamedParameterMethodTrampoline(DartMethodDefinition method,
        JsNameRef origJsName) {
      boolean preserveThis = !(method.getModifiers().isStatic() ||
                               method.getModifiers().isFactory() ||
                               Elements.isTopLevel(method.getSymbol()));

      return generateNamedParameterTrampoline(method.getFunction(), origJsName, 0, preserveThis);
    }

    private JsFunction generateNamedParameterTrampoline(DartFunction func,
        JsNameRef origJsName, int numClosureScopes, boolean preserveThis) {
      // function([$s0, $s1, ...], $n, $o, P0, P1, P2, P3, ...) {
      JsFunction tramp = new JsFunction(globalScope);
      JsScope scope = tramp.getScope();

      // Create fresh parameters for the explicit and synthetic parameters.
      List<JsParameter> explicitJsParams = new ArrayList<JsParameter>();
      for (DartParameter dartParam : func.getParams()) {
        String paramName = ((DartIdentifier) dartParam.getName()).getTargetName();
        JsParameter param = new JsParameter(scope.declareName(paramName));
        explicitJsParams.add(param);
      }

      List<JsParameter> closureScopeParams = new ArrayList<JsParameter>();
      for (int i = 0; i < numClosureScopes; ++i) {
        JsParameter param = new JsParameter(scope.declareFreshName("$s" + i));
        closureScopeParams.add(param);
      }
      JsParameter countParam = new JsParameter(scope.declareFreshName("$n"));
      JsParameter namedParam = new JsParameter(scope.declareFreshName("$o"));

      // Declare parameters in the proper order.
      for (int i = 0; i < numClosureScopes; ++i) {
        tramp.getParameters().add(closureScopeParams.get(i));
      }
      tramp.getParameters().add(countParam);
      tramp.getParameters().add(namedParam);
      for (int i = 0; i < explicitJsParams.size(); ++i) {
        tramp.getParameters().add(explicitJsParams.get(i));
      }

      // var seen = 0, def = 0;
      JsBlock body = new JsBlock();
      tramp.setBody(body);
      List<JsStatement> stmts = body.getStatements();

      JsName seen = scope.declareFreshName("seen");
      JsName def = scope.declareFreshName("def");
      stmts.add(AstUtil.newVar(null, seen, number(0)));
      stmts.add(AstUtil.newVar(null, def, number(0)));

      // switch ($n) {
      //   case 1: P0 = $o.P0 ? (++seen, $o.P0) : null;             // no default value
      //   case 2: P1 = $o.P1 ? (++seen, $o.P1) : (++def, DEFAULT); // explicit default value
      //   ...
      // }
      JsSwitch jsSwitch = new JsSwitch();
      jsSwitch.setExpr(countParam.getName().makeRef());
      for (int i = 0; i < func.getParams().size(); ++i) {
        DartParameter param = func.getParams().get(i);
        JsParameter jsParam = tramp.getParameters().get(i + 2);
        if (!param.getModifiers().isNamed()) {
          continue;
        }

        JsNameRef ifExpr = AstUtil.newNameRef(namedParam.getName().makeRef(),
            jsParam.getName());

        JsPrefixOperation ppSeen = new JsPrefixOperation(JsUnaryOperator.INC, seen.makeRef());
        JsBinaryOperation thenExpr = new JsBinaryOperation(JsBinaryOperator.COMMA, ppSeen,
            AstUtil.newNameRef(namedParam.getName().makeRef(), jsParam.getName()));

        JsExpression elseExpr;

        DartExpression defaultValue = param.getDefaultExpr();
        if (defaultValue != null) {
          JsPrefixOperation ppDef = new JsPrefixOperation(JsUnaryOperator.INC, def.makeRef());
          elseExpr = new JsBinaryOperation(JsBinaryOperator.COMMA, ppDef,
            generateDefaultValue(defaultValue));
        } else {
          elseExpr = nulle();
        }

        JsBinaryOperation asg = assign(
            jsParam.getName().makeRef(),
            new JsConditional(ifExpr, thenExpr, elseExpr));

        jsSwitch.getCases().add(AstUtil.newCase(number(i), asg.makeStmt()));
      }
      if (jsSwitch.getCases().size() > 0) {
        stmts.add(jsSwitch);
      }

      // if ((seen != $o.$count) || (seen + def + $n != TOTAL)) {
      //   $nsme();
      // }
      {
        JsBinaryOperation ifLeft = neq(seen.makeRef(),
            AstUtil.newNameRef(namedParam.getName().makeRef(), "count"));

        JsExpression add1 = add(seen.makeRef(), def.makeRef());
        JsExpression add2 = add(add1, countParam.getName().makeRef());
        JsExpression ifRight = neq(add2, number(func.getParams().size()));

        JsExpression ifExpr = or(ifLeft, ifRight);
        JsStatement thenStmt = AstUtil.newInvocation(new JsNameRef("$nsme")).makeStmt();

        stmts.add(new JsIf(ifExpr, thenStmt, null));
      }

      JsInvocation jsInvoke = AstUtil.newInvocation(
          AstUtil.newNameRef(origJsName.getQualifier(), origJsName.getName()));
      if (preserveThis) {
        JsNameRef call = AstUtil.newNameRef(jsInvoke.getQualifier(), "call");
        jsInvoke = AstUtil.newInvocation(call, new JsThisRef());
      }
      for (int i = 0; i < numClosureScopes; ++i) {
        jsInvoke.getArguments().add(closureScopeParams.get(i).getName().makeRef());
      }
      for (JsParameter jsParam : explicitJsParams) {
        jsInvoke.getArguments().add(jsParam.getName().makeRef());
      }
      stmts.add(new JsReturn(jsInvoke));

      return tramp;
    }

    /**
     * If necessary, add object holding aliases for any parameters
     * captured by function closures.
     */
    private void maybeAddFunctionScopeAlias(DartScope scope, JsFunction function) {
      if (scope.definesClosureReferencedSymbols()) {
        JsScope jsScope = function.getScope();
        JsBlock body = function.getBody();

        // Example:
        //   function f(a,b) { ... }
        // to:
        //   function f(a,b) {var s0={f:f,a:a,b:b} ... };
        JsObjectLiteral aliasInit = new JsObjectLiteral();
        for (Entry<Symbol, DartScope.DartSymbolInfo> entry : scope.getSymbols().entrySet()) {
          if (entry.getValue().isReferencedFromClosure()) {
            JsName param = getJsName(entry.getKey());
            aliasInit.getPropertyInitializers().add(
                new JsPropertyInitializer(string(param.getIdent()), new JsNameRef(param)));
          }
        }

        JsName aliasName = scope.getAliasForJsScope(jsScope);
        // Scope objects are declared (in the JsScope) at first use. By construction scope-objects
        // are only created when they are used. Therefore the scope-object must exist in the
        // JsScope.
        assert aliasName != null;
        JsStatement aliasDecl = AstUtil.newVar(null, aliasName, aliasInit);
        body.getStatements().add(0, aliasDecl);
      }
    }

    private JsName getTraceCounter() {
      if (traceCounter == null) {
        traceCounter = globalScope.declareTemporary();
        JsStatement counterDecl = AstUtil.newVar(null, traceCounter, number(0));
        globalBlock.getStatements().add(0, counterDecl);
      }
      return traceCounter;
    }

    private JsNameRef makeMethodJsReference(Element element, JsName name) {
      JsNameRef qualifier;
      boolean isNonFactoryConstructor = Elements.isNonFactoryConstructor(element);
      Modifiers modifiers = element.getModifiers();
      JsNameRef classJsName = getJsName(element.getEnclosingElement()).makeRef();
      if (modifiers.isStatic() || modifiers.isFactory() || isNonFactoryConstructor) {
        // Static methods hang directly from the constructor.
        qualifier = classJsName;
      } else {
        // Instance methods hang from the prototype.
        qualifier = AstUtil.newPrototypeNameRef(classJsName);
      }

      JsNameRef prop = AstUtil.newNameRef(qualifier, name);
      // TODO(johnlenz): This should be the name node reference
      prop.setSourceRef(element.getNode());
      return prop;
    }

    /**
     * Turns a method into a prototype assignment on the JS class. Clears the
     * name from the given function.
     */
    private void makeMethod(Element element, JsFunction func) {
      if (element.getEnclosingElement().getKind().equals(ElementKind.CLASS)) {
        JsNameRef prop = makeMethodJsReference(element, func.getName());
        func.setName(null);
        JsBinaryOperation asg = AstUtil.newAssignment(prop, func);

        // TODO(johnlenz): This should be the stmt node reference
        asg.setSourceRef(element.getNode());
        globalBlock.getStatements().add(asg.makeStmt());

        // If it's a (non-operator, non-property) method, generate its named trampoline.
        if (element.getKind().equals(ElementKind.METHOD) &&
            !element.getModifiers().isOperator() &&
            !element.getModifiers().isGetter() &&
            !element.getModifiers().isSetter()) {
          // Declare the mangled trampoline's name in the same scope as its target.
          String mangled = mangler.mangleNamedMethod((MethodElement) element, unitLibrary);
          JsName namedName = prop.getName().getEnclosing().declareName(mangled);
          JsNameRef namedProp = makeMethodJsReference(element, namedName);

          DartMethodDefinition method = (DartMethodDefinition) element.getNode();
          JsFunction tramp = generateNamedParameterMethodTrampoline(method, prop);

          asg = assign(namedProp, tramp);
          globalBlock.getStatements().add(asg.makeStmt());
        }
      } else {
        globalBlock.getStatements().add(func.makeStmt());
      }
    }

    private JsExpression getGetterSetterQualifier(Element element) {
      if (isDeclaredAsStaticOrImplicitlyStatic(element)) {
        // The mangler makes sure that the mangled version of static
        // fields names encode the class name so we do not have to
        // read the fields through the class function.
        return new JsNameRef(ISOLATE_CURRENT);
      } else if (Elements.isTopLevel(element)) {
        return null;
      } else {
        return new JsThisRef();
      }
    }

    /**
     * Creates a getter that returns a JavaScript property.
     */
    private void makePropertyGetter(FieldElement element) {
      JsExpression qualifier = getGetterSetterQualifier(element);
      JsName fieldJsName = getJsName(element);
      JsNameRef ref = AstUtil.newNameRef(qualifier, fieldJsName);
      makeGetter(element, ref);
    }

    /**
     * Creates a getter that returns a constant (simple) JavaScript value.
     */
    private void makeConstantValueGetter(FieldElement element, JsExpression value) {
      assert element.getModifiers().isFinal();
      makeGetter(element, value);
    }

    private void makeGetter(FieldElement element, JsExpression expression) {
      String getterName = mangler.createGetterSyntax(element, unitLibrary);
      String fieldName = element.getName();
      JsName getterJsName = globalScope.declareName(getterName, getterName, fieldName);
      getterJsName.setObfuscatable(false);
      JsFunction func = new JsFunction(globalScope, getterJsName);
      func.setBody(AstUtil.newBlock(new JsReturn(expression)));
      makeMethod(element, func);
    }

    /**
     * Create a shim method for invoking a method through a field.  Invoke the
     * getter to get the field value, then apply the shim's arguments to
     * the returned closure object.
     */
    private void makeMethodCallThroughFieldShim(DartField x) {
      FieldElement element = x.getSymbol();
      if (Elements.isTopLevel(element)) {
        // Don't bother making a call-though-field shim for global methods. They're always
        // statically resolved, so we'll never generate a call to one.
        return;
      }

      String shimName = mangler.mangleNamedMethod(element.getName(), unitLibrary);
      String fieldName = element.getName();
      JsName shimJsName = globalScope.declareName(shimName, shimName, fieldName);
      shimJsName.setObfuscatable(false);
      JsFunction func = new JsFunction(globalScope, shimJsName);
      JsExpression qualifier;
      if (element.getModifiers().isStatic()) {
        Element enclosingElement = element.getEnclosingElement();
        switch (enclosingElement.getKind()) {
          case CLASS:
            qualifier = AstUtil.newNameRef(null,
                mangler.mangleClassName((ClassElement) enclosingElement));
            break;
          case LIBRARY:
            qualifier = null;
            break;
          default:
            throw new InternalCompilerException(
                "Unhandled type of static element making method shim.");
        }
      } else {
        qualifier = getGetterSetterQualifier(element);
      }
      String getterName = mangler.createGetterSyntax(element, unitLibrary);
      JsExpression expression = AstUtil.newInvocation(AstUtil.newNameRef(qualifier, getterName));
      expression = AstUtil.newNameRef(expression, "apply");
      expression = AstUtil.newInvocation(expression, new JsThisRef(),
          AstUtil.newNameRef(null, "arguments"));
      func.setBody(AstUtil.newBlock(new JsReturn(expression)));
      makeMethod(element, func);
    }

    /**
     * Creates a getter method that lazily initializes the field (if necessary).
     */
    private void makeInitializingGetter(FieldElement element, JsExpression initExpression) {
      String getterName = mangler.createGetterSyntax(element, unitLibrary);
      String fieldName = element.getName();
      JsName getterJsName = globalScope.declareName(getterName, getterName, fieldName);
      getterJsName.setObfuscatable(false);

      JsFunction func = new JsFunction(globalScope, getterJsName);
      JsScope scope = new JsScope(globalScope, "temp");

      //   Foo.x$getter = function() {
      //     var t0 = isolate$current.Foo$x;
      //     var t1 = $initializing;
      //     if (t0 === t1) throw "circular initialization";
      //     if (t0 !== $uninitialized) return t0;
      //     isolate$current.Foo$x = t1;
      //     var t2 = ...  // initialization expression
      //     isolate$current.Foo$x = t2;
      //     return t2;
      //   }

      JsExpression fieldQualifier = getGetterSetterQualifier(element);
      JsName fieldJsName = getJsName(element);

      JsName t0 = scope.declareTemporary();
      JsName t1 = scope.declareTemporary();
      JsName t2 = scope.declareTemporary();

      JsVars initializeT0 = AstUtil.newVar(
          null, t0, AstUtil.newNameRef(fieldQualifier, fieldJsName));
      JsVars initializeT1 = AstUtil.newVar(
          null, t1, new JsNameRef(STATIC_INITIALIZING));
      JsStatement checkIfCircular = new JsIf(
          new JsBinaryOperation(
              JsBinaryOperator.REF_EQ,
              t0.makeRef(),
              t1.makeRef()),
          new JsThrow(string("circular initialization")),
          null);
      JsStatement checkIfInitialized = new JsIf(
          new JsBinaryOperation(
              JsBinaryOperator.REF_NEQ,
              t0.makeRef(),
              new JsNameRef(STATIC_UNINITIALIZED)),
          new JsReturn(t0.makeRef()),
          null);
      JsStatement markField = AstUtil.newAssignment(
          AstUtil.newNameRef(fieldQualifier, fieldJsName), t1.makeRef()).makeStmt();
      JsStatement initializeT2 = AstUtil.newVar(
          null, t2, initExpression);
      JsStatement initializeField = AstUtil.newAssignment(
          AstUtil.newNameRef(fieldQualifier, fieldJsName), t2.makeRef()).makeStmt();
      JsStatement returnT2 = new JsReturn(t2.makeRef());

      // Construct the method from the statements.
      func.setBody(AstUtil.newBlock(
          initializeT0,
          initializeT1,
          checkIfCircular,
          checkIfInitialized,
          markField,
          initializeT2,
          initializeField,
          returnT2));
      makeMethod(element, func);
    }

    /**
     * Creates a setter and turns it into a prototype assignment on the
     * JS class.
     */
    private void makeSetter(FieldElement element) {
      String fieldName = element.getName();
      String setterName = mangler.createSetterSyntax(element, unitLibrary);
      JsName setterJsName = globalScope.declareName(setterName, setterName, fieldName);
      setterJsName.setObfuscatable(false);
      JsFunction func = new JsFunction(globalScope, setterJsName);

      JsScope scope = new JsScope(globalScope, "temp");
      JsName parameter = scope.declareTemporary();
      func.getParameters().add(0, new JsParameter(parameter));

      JsExpression qualifier = getGetterSetterQualifier(element);

      JsName fieldJsName = getJsName(element);
      JsNameRef ref = AstUtil.newNameRef(qualifier, fieldJsName);
      JsBinaryOperation asg = AstUtil.newAssignment(ref, parameter.makeRef());
      func.setBody(AstUtil.newBlock(new JsExprStmt(asg)));

      makeMethod(element, func);
    }

    @Override
    public JsNode visitInitializer(DartInitializer x) {
      JsExpression e = (JsExpression) generate(x.getValue());
      if (!x.isInvocation()) {
        JsName fieldJsName = getJsName(x.getName().getTargetSymbol());
        assert fieldJsName != null : "Field name must have been resolved.";
        JsNameRef field = AstUtil.newNameRef(new JsThisRef(), fieldJsName);
        e = AstUtil.newAssignment(field, e);
        e.setSourceRef(x);
      }
      return new JsExprStmt(e);
    }

    @Override
    public JsNode visitFieldDefinition(DartFieldDefinition node) {
      assert ElementKind.of(currentHolder).equals(ElementKind.LIBRARY);
      for (DartField field : node.getFields()) {
        generateTopLevelField(field);
      }
      return null;
    }

    private void generateTopLevelField(DartField field) {
      if (field.getSymbol().getModifiers().isAbstractField()) {
        generate(field.getAccessor());
      } else {
        generate(field);
      }
    }

    @Override
    public JsNode visitField(DartField x) {
      makeMethodCallThroughFieldShim(x);
      FieldElement element = x.getSymbol();
      Modifiers modifiers = element.getModifiers();
      if (modifiers.isAbstractField()) {
        generateAbstractField(element);
        return null;
      }

      DartExpression initializer = x.getValue();
      JsExprStmt result = null;

      if (initializer != null || Elements.isTopLevel(element)) {
        currentScopeInfo = ScopeRootInfo.makeScopeInfo(x, !shouldGenerateDeveloperModeChecks());
        inFactoryOrStaticContext = true;

        // There's an initializer, so emit an assignment statement.
        JsNameRef fieldName;
        if (isDeclaredAsStaticOrImplicitlyStatic(element)) {
          JsExpression qualifier = getGetterSetterQualifier(element);
          fieldName = AstUtil.newNameRef(qualifier, translationContext.getNames().getName(element));
        } else {
          fieldName = AstUtil.newNameRef(new JsThisRef(), getJsName(element));
        }

        JsExpression initExpr;
        if (initializer == null) {
          initExpr = undefined();
        } else {
          initExpr = (JsExpression) generate(initializer);
        }

        boolean emitStaticInitialization = true;
        if (x.getModifiers().isFinal() &&
            (initializer == null || initExpr instanceof JsValueLiteral)) {
          makeConstantValueGetter(element, initExpr);
          emitStaticInitialization = false;
        } else if (initializer == null || initExpr instanceof JsLiteral) {
          makePropertyGetter(element);
        } else {
          makeInitializingGetter(element, initExpr);
          initExpr = new JsNameRef(STATIC_UNINITIALIZED);
        }

        if (emitStaticInitialization) {
          JsBinaryOperation assignment = AstUtil.newAssignment(fieldName, initExpr);
          assignment.setSourceRef(x);
          result = new JsExprStmt(assignment);
          staticInit.add(result);
        }

        assert currentScopeInfo != null;
        currentScopeInfo = null;
        inFactoryOrStaticContext = false;
      } else {
        makePropertyGetter(element);
      }

      if (!element.getModifiers().isFinal()) {
        makeSetter(element);
      }
      return result;
    }

    @Override
    public JsNode visitFunction(DartFunction x) {
      if (x.getBody() == null) {
        if (ElementKind.of(currentHolder).equals(ElementKind.CLASS)
            && ((ClassElement) currentHolder).isInterface()) {
          return null;
        }
      }

      functionStack.push(x);
      jsNewDeclarationsStack.push(new HashSet<JsName>());

      // The JsFunction was already created and pushed in visit(DartFunction).
      JsFunction jsFunc = translationContext.getMethods().get(x);

      // Generate and set the body.
      JsBlock body;
      if (x.getBody() == null) {
        // The resolution has checked already that it is valid for this method
        // to not have a body.
        body = new JsBlock();
      } else {
        body = (JsBlock) generate(x.getBody());
      }
      jsFunc.setBody(body);

      // Create JS parameters
      List<DartParameter> params = x.getParams();
      List<JsParameter> jsParams = jsFunc.getParameters();
      generateAll(params, jsParams, JsParameter.class);

      // Create the runtime type checks that will be inserted later
      List<JsStatement> checks = Lists.newArrayList();
      int numParams = params.size();
      for (int i = 0; i < numParams; ++i) {
        JsNameRef jsParam = jsParams.get(i).getName().makeRef();
        JsExpression expr = rtt.addTypeCheck(getCurrentClass(), jsParam,
            typeOf(params.get(i).getTypeNode()), null, params.get(i));
        if (expr != jsParam) {
          // if the expression was returned unchanged, omit the check
          checks.add(new JsExprStmt(expr));
        }
      }

      // Add temporary variable declarations, if any.
      declareTempsInBlock(body, jsNewDeclarationsStack.pop());

      DartNode parent = x.getParent();
      assert parent != null;
      if (parent instanceof DartMethodDefinition) {
        DartMethodDefinition method = (DartMethodDefinition) parent;
        if (isFactory(method)) {
          rtt.maybeAddTypeParameterToFactory(method, jsFunc);
        }
        if (Elements.isNonFactoryConstructor((Element) parent.getSymbol())) {
          this.addSuperOrRedirectConstructorCall(method);
        }
      }

      // Call the function prologue setup functions in the reserve order that
      // their output need to appear as each adds to the front of the function
      // body.
      // 3. setup the scope aliases (after default init)
      maybeAddFunctionScopeAlias(currentScopeInfo.getScope(x),
          translationContext.getMethods().get(x));

      // 2. call function trace before anything else.
      maybeAddFunctionTracing(x);

      // 1. insert parameter type checks at the beginning of the method
      body.getStatements().addAll(0, checks);

      functionStack.pop();
      return jsFunc.setSourceRef(x);
    }

    /**
     * Get the type associated with a type node
     * 
     * @param typeNode a {@link DartTypeNode}, which may be null
     * @return a {@link Type} corresponding to the type node or null to indicate unknown
     */
    private Type typeOf(DartTypeNode typeNode) {
      if (typeNode == null) {
        return null;
      }
      return typeNode.getType();
    }

    private boolean isFactory(DartMethodDefinition method) {
      return method.getModifiers().isFactory();
    }

    private void maybeAddFunctionTracing(DartFunction dartFunction) {
      // TODO(floitsch): temporary way to enable tracing is by setting a system property.
      String tracingCallTarget = System.getProperty("Trace");
      if (tracingCallTarget != null) {
        JsFunction function = translationContext.getMethods().get(dartFunction);

        // Example:
        //   function f(a,b) { ... }
        // to:
        //   function f(a, b) {
        //      nestingCounter++;
        //      <tracingCallTarget>(nestingCounter, "f(a, b)", a, b);
        //      try { ... }
        //      finally { nestingCounter--; }
        //   }
        JsExpression increment = new JsPostfixOperation(JsUnaryOperator.INC,
                                                        new JsNameRef(getTraceCounter()));
        JsExpression decrement = new JsPostfixOperation(JsUnaryOperator.DEC,
                                                        new JsNameRef(getTraceCounter()));

        JsInvocation tracerCall = new JsInvocation();
        tracerCall.setQualifier(new JsNameRef(tracingCallTarget));
        List<JsExpression> traceArguments = tracerCall.getArguments();
        traceArguments.add(new JsNameRef(getTraceCounter()));
        traceArguments.add(null);  // Reserve space for string description.
        StringBuffer description = new StringBuffer();
        JsName name = function.getName();
        if (name != null) {
          description.append(function.getName().toString());
        } else {
          description.append("<anonymous-" + function.hashCode() + ">");
        }
        description.append("(");
        dartFunction.getParams();
        for (DartParameter param : dartFunction.getParams()) {
          JsName paramName = getJsName(param.getSymbol());
          description.append(paramName.toString());
          traceArguments.add(new JsNameRef(paramName));
        }
        description.append(")");
        // Update string description in argument list.
        traceArguments.set(1, string(description.toString()));

        JsTry countingTry = new JsTry();
        countingTry.setTryBlock(function.getBody());
        countingTry.setFinallyBlock(AstUtil.newBlock(decrement.makeStmt()));
        JsBlock newBody = AstUtil.newBlock(increment.makeStmt(),
                                           tracerCall.makeStmt(),
                                           countingTry);
        function.setBody(newBody);
      }
    }

    @Override
    public JsNode visitParameter(DartParameter x) {
      if (x.getSymbol() != null) {
        return new JsParameter(getJsName(x.getSymbol())).setSourceRef(x);
      } else {
        // TODO(ngeoffray): A parameter in a function type does not have a symbol.
        return null;
      }
    }

    @Override
    public JsNode visitBlock(DartBlock x) {
      // Basic block handling
      JsBlock jsBlock = new JsBlock();
      // TODO(johnlenz): merge redundant JsBlock nodes.
      generateAll(x.getStatements(), jsBlock.getStatements(), JsStatement.class);

      //
      // For names defined in this scope that are captured by a function
      // closure rewrite, inject an object to hold the aliases for the
      // value for use by the closure.  This simulates lexically scoped names
      // in JavaScript and once the closures are hoisted out of the scope
      // prevents the capture of value that would otherwise be protected in
      // another scope.
      //

      // Inject scope alias initialization and clean up.
      ScopeRootInfo methodInfo = currentScopeInfo;
      if (methodInfo != null) {
        DartScope scope = methodInfo.getScope(x);
        if (scope.definesClosureReferencedSymbols()) {
          // Make sure the alias is defined in the scope.
          JsScope currentFunctionScope = getCurrentFunctionScope();
          JsName aliasName = scope.findAliasForJsScope(currentFunctionScope);
          // Scope objects are declared (in the JsScope) at first use. By construction scope-objects
          // are only created when they are used. Therefore the scope-object must exist in the
          // JsScope.
          assert aliasName != null;
          registerForDeclaration(aliasName);

          // Init and clean up the scope alias
          // TODO(johnlenz): this really should be in a finally block,
          // debate the runtime cost of doing this, version the possibility of
          // a memory leak (It is only really needed if there are closures
          // outside this DartScope).
          // Alternately, once the closures have been hoisted out, the cleanup
          // code can be removed completely.
          List<JsStatement> list = jsBlock.getStatements();
          JsStatement init = AstUtil.newAssignment(
              new JsNameRef(aliasName), new JsObjectLiteral())
              .makeStmt();
          JsStatement cleanup = AstUtil.newAssignment(
              new JsNameRef(aliasName), undefined())
              .makeStmt();
          list.add(0, init);
          list.add(cleanup);
        }
      }
      return jsBlock.setSourceRef(x);
    }

    @Override
    public JsNode visitIfStatement(DartIfStatement x) {
      JsExpression jsCondition = (JsExpression) generate(x.getCondition());
      JsStatement jsThenStmt = (JsStatement) generate(x.getThenStatement());
      JsStatement jsElseStmt = null;
      if (x.getElseStatement() != null) {
        jsElseStmt = (JsStatement) generate(x.getElseStatement());
      }
      return new JsIf(jsCondition, jsThenStmt, jsElseStmt).setSourceRef(x);
    }

    @Override
    public JsNode visitSwitchStatement(DartSwitchStatement x) {
      JsSwitch jsSwitch = new JsSwitch();
      jsSwitch.setExpr((JsExpression) generate(x.getExpression()));
      generateAll(x.getMembers(), jsSwitch.getCases(), JsSwitchMember.class);
      return jsSwitch.setSourceRef(x);
    }

    @Override
    public JsNode visitCase(DartCase x) {
      JsCase jsCase = new JsCase();
      jsCase.setCaseExpr((JsExpression) generate(x.getExpr()));
      generateAll(x.getStatements(), jsCase.getStmts(), JsStatement.class);
      return jsCase.setSourceRef(x);
    }

    @Override
    public JsNode visitDefault(DartDefault x) {
      JsDefault jsDefault = new JsDefault();
      generateAll(x.getStatements(), jsDefault.getStmts(), JsStatement.class);
      return jsDefault.setSourceRef(x);
    }

    @Override
    public JsNode visitWhileStatement(DartWhileStatement x) {
      JsExpression condition = (JsExpression) generate(x.getCondition());
      JsBlock body = (JsBlock) generate(x.getBody());
      return new JsWhile(condition, body).setSourceRef(x);
    }

    @Override
    public JsNode visitDoWhileStatement(DartDoWhileStatement x) {
      JsExpression condition = (JsExpression) generate(x.getCondition());
      JsBlock body = (JsBlock) generate(x.getBody());
      return new JsDoWhile(condition, body).setSourceRef(x);
    }

    @Override
    public JsNode visitForStatement(DartForStatement x) {
      // Dart AST normalization removes init expressions.
      assert x.getInit() == null;

      JsFor jsFor = new JsFor().setSourceRef(x);
      if (x.getCondition() != null) {
        jsFor.setCondition((JsExpression) generate(x.getCondition()));
      }
      if (x.getIncrement() != null) {
        jsFor.setIncrExpr((JsExpression) generate(x.getIncrement()));
      }
      jsFor.setBody((JsStatement) generate(x.getBody()));
      return jsFor.setSourceRef(x);
    }

    @Override
    public JsNode visitForInStatement(DartForInStatement x) {
      DartStatement normalizedNode = x.getNormalizedNode();
      if (normalizedNode == null) {
        throw new InternalCompilerException("For-in statement should have been normalized.");
      }
      return normalizedNode.accept(this);
    }

    @Override
    public JsNode visitContinueStatement(DartContinueStatement x) {
      JsContinue jsContinue = null;
      if (x.getTargetSymbol() != null) {
        jsContinue = new JsContinue(getJsName(x.getTargetSymbol()).makeRef());
      } else {
        jsContinue = new JsContinue();
      }
      return jsContinue.setSourceRef(x);
    }

    @Override
    public JsNode visitBreakStatement(DartBreakStatement x) {
      JsBreak jsBreak = null;
      if (x.getTargetSymbol() != null) {
        jsBreak = new JsBreak(getJsName(x.getTargetSymbol()).makeRef());
      } else {
        jsBreak = new JsBreak();
      }
      return jsBreak.setSourceRef(x);
    }

    @Override
    public JsNode visitReturnStatement(DartReturnStatement x) {
      JsReturn jsRet = new JsReturn();
      DartExpression returnValue = x.getValue();
      if (returnValue != null) {
        JsExpression expr = (JsExpression) generate(returnValue);
        DartFunction function = functionStack.peek();
        if (function != null) {
          // NOTE: FunctionExpressionInliner might be leaving return statements around
          DartTypeNode returnType = function.getReturnTypeNode();
          expr = rtt.addTypeCheck(getCurrentClass(), expr, typeOf(returnType),
              returnValue.getType(), x);
        }
        jsRet.setExpr(expr);
      }
      return jsRet.setSourceRef(x);
    }

    @Override
    public JsNode visitTryStatement(DartTryStatement x) {
      JsTry jsTry = new JsTry();
      jsTry.setTryBlock((JsBlock) generate(x.getTryBlock()));

      // TODO(jgw): The Javascript AST allows multiple catch blocks for some reason,
      // even though that makes no sense. Sort this out once structured exceptions are
      // worked out in Dart.
      List<DartCatchBlock> catchBlocks = x.getCatchBlocks();
      if (catchBlocks != null && !catchBlocks.isEmpty()) {
        // Transform a sequence of catch blocks into nested if-statements.
        // Example:
        //   try { <try-body>
        //   } catch (SomeException e1) { <body1>
        //   }  catch (OtherException e2) { <body2>
        //   }
        // becomes
        //   try { <try-body>
        //   } catch(tmpVar) {
        //     if (tmpVar instanceof SomeException) { var e1 = tmpVar; <body1>
        //     } else if (tmpVar instanceof OtherException) { var e2 = tmpVar; <body2>
        //     } else { throw tmpVar; }
        //   }
        //
        // Note that when no type is given for the Dart exception, it catches always. Then we
        // don't need a rethrow.
        // The JsCatch scope only contains one variable. There is hence no clash possible.
        JsCatch jsCatch = new JsCatch(getCurrentFunctionScope(), "e");
        JsName exceptionVar = jsCatch.getScope().findExistingName("e");

        jsTry.getCatches().add(jsCatch);
        JsBlock jsCatchBody = new JsBlock();
        // Tease out browser built-in exceptions
        JsExpression filterBuiltin = AstUtil.newAssignment(exceptionVar.makeRef(),
          AstUtil.newInvocation(AstUtil.newNameRef(null, "$transformBrowserException"),
            exceptionVar.makeRef()));
        jsCatchBody.getStatements().add(filterBuiltin.makeStmt());
        jsCatch.setBody(jsCatchBody);
        JsStatement jsElse = new JsThrow(new JsNameRef(exceptionVar));

        for (int i = catchBlocks.size() - 1; i >= 0; i--) {
          DartCatchBlock catchBlock = catchBlocks.get(i);
          JsBlock jsClauseBody = (JsBlock) generate(catchBlock.getBlock());
          if (catchBlock.getStackTrace() != null) {
            // TODO(ngeoffray): do something with the stackTrace.
            JsParameter jsStackParam = (JsParameter) generate(catchBlock.getStackTrace());
            registerForDeclaration(jsStackParam.getName());
          }
          JsParameter jsClauseParam = (JsParameter) generate(catchBlock.getException());
          JsName jsClauseParamName = jsClauseParam.getName();

          JsExpression assignment = AstUtil.newAssignment(new JsNameRef(jsClauseParamName),
                                                          new JsNameRef(exceptionVar));
          jsClauseBody.getStatements().add(0, assignment.makeStmt());
          // The exception variable is not declared by the catch-block anymore. Register for
          // declaration so that it becomes a local variable.
          // Note that the name could already be in the list (if two catch-clauses share the same
          // name). In this case the declaration-clause will declare the same variable multiple
          // times (ex: var e, e, e;).
          registerForDeclaration(jsClauseParamName);

          DartParameter exception = catchBlock.getException();
          DartTypeNode exceptionType = exception.getTypeNode();
          if (exceptionType == null) {
            // No type has been given. This clause catches everything.
            jsElse = jsClauseBody;
            continue;
          }

          JsExpression instanceCheck = rtt.generateInstanceOfComparison(
              getCurrentClass(),
              new JsNameRef(exceptionVar),
              exceptionType,
              exceptionType).setSourceRef(exception);
          jsElse = new JsIf(instanceCheck, jsClauseBody, jsElse);
        }
        jsCatchBody.getStatements().add(jsElse);
      }

      if (x.getFinallyBlock() != null) {
        JsBlock jsFinallyBlock = (JsBlock) generate(x.getFinallyBlock());
        jsTry.setFinallyBlock(jsFinallyBlock);
      }

      // Allow a try block to be a target of a label by surrounding it with a block.
      JsNode result = jsTry.setSourceRef(x);
      if (x.getParent() instanceof DartLabel) {
        result = new JsBlock(jsTry).setSourceRef(x);
      }
      return result;
    }

    @Override
    public JsNode visitThrowStatement(DartThrowStatement x) {
      JsNameRef error = new JsNameRef("$Dart$ThrowException");
      JsInvocation invoc = AstUtil.newInvocation(error);
      if (x.getException() != null) {
        invoc.getArguments().add((JsExpression) generate(x.getException()));
      }
      return new JsExprStmt(invoc.setSourceRef(x));
    }

    @Override
    public JsNode visitVariableStatement(DartVariableStatement x) {

      // Dart AST Normalization creates one declaration per VAR.
      assert x.getVariables().size() == 1;

      JsNode node = generate(x.getVariables().get(0));
      if (node instanceof JsVar) {
        JsVars jsVars = new JsVars();
        jsVars.insert((JsVar)node);
        return jsVars.setSourceRef(x);
      } else {

        // Variables captured by closures may be transformed to property
        // assignments.
        assert node instanceof JsStatement;

        return node;
      }
    }

    @Override
    public JsNode visitVariable(DartVariable x) {
      Symbol targetSymbol = x.getSymbol();

      // If the name is referenced by a closure use the scope alias.
      JsNameRef scopeAliasRef = maybeMakeScopeAliasReference(targetSymbol);
      JsNode result = null;
      DartExpression value = x.getValue();
      if (scopeAliasRef != null) {
        if (value != null) {
          JsExpression initExpr = (JsExpression) generate(value);
          Type type = getTypeOfIdentifier(x.getName());
          initExpr = rtt.addTypeCheck(getCurrentClass(), initExpr, type, value.getType(), x);
          result = AstUtil.newAssignment(scopeAliasRef, initExpr).setSourceRef(x).makeStmt();
        } else {
          // we need to put some statement in to keep the expected number
          // of values on the stack.
          result = translationContext.getProgram().getEmptyStmt();
        }
      } else {
        JsVars.JsVar jsVar = new JsVars.JsVar(getJsName(targetSymbol));
        if (value != null) {
          JsExpression initExpr = (JsExpression) generate(value);
          Type type = getTypeOfIdentifier(x.getName());
          initExpr = rtt.addTypeCheck(getCurrentClass(), initExpr, type, value.getType(), x);
          jsVar.setInitExpr(initExpr);
        } else {
          jsVar.setInitExpr(undefined());
        }
        result = jsVar.setSourceRef(x);
      }

      return result;
    }

    @Override
    public JsNode visitEmptyStatement(DartEmptyStatement x) {
      x.visitChildren(this);
      // TODO(johnlenz): Set source info?
      return translationContext.getProgram().getEmptyStmt();
    }

    @Override
    public JsNode visitSyntheticErrorExpression(DartSyntheticErrorExpression node) {
      String name = node.getSource().getName();
      int line = node.getSourceLine();
      int col = node.getSourceColumn();
      throw new AssertionError("Generating JS with parse error at " + name + ":"
          + line + ":" + col);
    }

    @Override
    public JsNode visitSyntheticErrorStatement(DartSyntheticErrorStatement node) {
      String name = node.getSource().getName();
      int line = node.getSourceLine();
      int col = node.getSourceColumn();
      throw new AssertionError("Generating JS with parse error at " + name + ":"
          + line + ":" + col);
    }

    @Override
    public JsNode visitLabel(DartLabel x) {
      JsStatement jsStmt = (JsStatement) generate(x.getStatement());
      JsLabel jsLabel = new JsLabel(getJsName(x.getSymbol()));
      jsLabel.setStmt(jsStmt);
      return jsLabel.setSourceRef(x);
    }

    @Override
    public JsNode visitExprStmt(DartExprStmt x) {
      JsNode node = generate(x.getExpression());
      if (node instanceof JsVars) {
        // Function statements maybe transformed to var statements.
        // TODO(johnlenz): Create a JsFunctionStatement so that those statements
        // aren't wrapped in expressions.
        // Note(floitsch): When removing this special case please update the comments
        // in 'endVisit(DartFunctionExpression, ...)'.
        return node;
      } else {
        JsExpression expr = (JsExpression) node;
        return new JsExprStmt(expr).setSourceRef(x);
      }
    }

    @Override
    public JsNode visitConditional(DartConditional x) {
      JsExpression testExpr = (JsExpression) generate(x.getCondition());
      JsExpression thenExpr = (JsExpression) generate(x.getThenExpression());
      JsExpression elseExpr = (JsExpression) generate(x.getElseExpression());
      return new JsConditional(testExpr, thenExpr, elseExpr).setSourceRef(x);
    }

    @Override
    public JsNode visitBinaryExpression(DartBinaryExpression x) {
      assert x == x.getNormalizedNode();

      Token operator = x.getOperator();

      if (operator == Token.IS) {
        return generateInstanceOfComparison(x);
      }

      DartExpression arg2 = x.getArg2();
      JsExpression rhs = (JsExpression) generate(arg2);
      if (operator == Token.ASSIGN) {
        return x.getArg1().accept(new Assignment(x, rhs, arg2.getType()));
      }

      assert !operator.isUserDefinableOperator() || !operator.isAssignmentOperator() : x;

      // We can skip shims for non-user-definable operators (NE is a special case because it's not
      // user-definable, but still has to be shimmed).
      boolean skipShim = (!operator.isUserDefinableOperator() && (operator != Token.NE));
      if (!skipShim) {
        // For user-defined operators, the optimization strategy can choose to skip the shim.
        skipShim = optStrategy.canSkipOperatorShim(x);
      }

      JsExpression lhs = (JsExpression) generate(x.getArg1());
      Token op = x.getOperator();
      if (skipShim) {
        if (op.isEqualityOperator()) {
          op = mapToStrictEquals(op);
          // TODO (fabiomfv) - This optimization targets a v8 perf issue. V8 double equals
          // comparison to undefined is up to 4 times slower than == null. It seems that it was
          // fixed on v8 3.5. once we move to 3.5 and the fix confirmed, this should be revisited.
          if (arg2 instanceof DartNullLiteral) {
            op = mapToNonStrictEquals(op);
            rhs = nulle();
          }
          if (x.getArg1() instanceof DartNullLiteral) {
            JsExpression tmp = lhs;
            lhs = rhs;
            rhs = tmp;
            op = mapToNonStrictEquals(op);
            rhs = nulle();
          }
        }
        JsExpression binOp = new JsBinaryOperation(mapBinaryOp(op), lhs, rhs);
        binOp.setSourceRef(x);
        return binOp;
      } else {
        JsNameRef ref = new JsNameRef(mangler.createOperatorSyntax(operator));
        return AstUtil.newInvocation(ref, lhs, rhs).setSourceRef(x);
      }
    }

    private Type getTypeOfIdentifier(DartIdentifier ident) {
      Element element = ident.getReferencedElement();
      DartTypeNode typeNode = null;
      if (element == null) {
        DartNode parent = ident.getParent();
        if (parent instanceof DartVariable) {
          DartVariableStatement varStmt = (DartVariableStatement) parent.getParent();
          typeNode = varStmt.getTypeNode();
        } else {
          throw new InternalCompilerException("Unexpected identifier type: " + ident);          
        }
      } else {
        switch (element.getKind()) {
          case VARIABLE:
            DartVariableStatement varStmt = (DartVariableStatement) element.getNode().getParent();
            typeNode = varStmt.getTypeNode();
            break;
          case PARAMETER:
            DartParameter param = (DartParameter) element.getNode();
            typeNode = param.getTypeNode();
            break;
          case FIELD:
            DartFieldDefinition fieldDef = (DartFieldDefinition) element.getNode().getParent();
            typeNode = fieldDef.getTypeNode();
            break;
          default:
            throw new InternalCompilerException("Unexpected identifier element type " + element);
        }
      }
      if (typeNode != null) {
        return typeNode.getType();
      }
      return null;
    }

    private JsExpression generateInstanceOfComparison(DartBinaryExpression x) {
      JsExpression lhs = (JsExpression) generate(x.getArg1());
      DartExpression rhs = x.getArg2();
      boolean isNot = false;
      if (rhs instanceof DartUnaryExpression) {
        isNot = true;
        rhs = ((DartUnaryExpression) rhs).getArg();
      }
      JsExpression expr = rtt.generateInstanceOfComparison(getCurrentClass(),
          lhs, ((DartTypeExpression) rhs).getTypeNode(), rhs).setSourceRef(x);
      if (isNot) {
        expr = new JsPrefixOperation(JsUnaryOperator.NOT, expr);
      }
      return expr;
    }

    private JsBinaryOperation assign(JsNameRef op1, JsExpression op2) {
      return AstUtil.newAssignment(op1, op2);
    }

    private JsBinaryOperation neq(JsExpression op1, JsExpression op2) {
      return new JsBinaryOperation(JsBinaryOperator.NEQ, op1, op2);
    }

    private JsBinaryOperation or(JsExpression op1, JsExpression op2) {
      return new JsBinaryOperation(JsBinaryOperator.OR, op1, op2);
    }

    private JsNumberLiteral number(double num) {
      return translationContext.getProgram().getNumberLiteral(num);
    }

    private JsStringLiteral string(String str) {
      return translationContext.getProgram().getStringLiteral(str);
    }

    private JsNullLiteral nulle() {
      return translationContext.getProgram().getNullLiteral();
    }

    private JsNameRef undefined() {
      return translationContext.getProgram().getUndefinedLiteral();
    }

    @Override
    public JsNode visitTypeNode(DartTypeNode x) {
      // This backend does not need types.
      return null;
    }

    @Override
    public JsNode visitTypeParameter(DartTypeParameter x) {
      // This backend does not need types.
      return null;
    }

    @Override
    public JsNode visitTypeExpression(DartTypeExpression x) {
      throw new AssertionError("Unreachable");
    }

    @Override
    public JsNode visitUnaryExpression(DartUnaryExpression x) {
      assert x == x.getNormalizedNode();
      Token operator = x.getOperator();
      JsNode result;
      JsExpression arg = (JsExpression) generate(x.getArg());
      boolean canSkipUnaryOpShim = optStrategy.canSkipOperatorShim(x);
      if (operator == Token.SUB) {
        if (canSkipUnaryOpShim) {
          JsExpression unaryMinus = new JsPrefixOperation(JsUnaryOperator.NEG, arg);
          unaryMinus.setSourceRef(x);
          return unaryMinus;
        } else {
          JsNameRef ref =
            new JsNameRef(mangler.createOperatorSyntax(DartMangler.NEGATE_OPERATOR_NAME));
          result = (AstUtil.newInvocation(ref, arg));
          return result.setSourceRef(x);
        }
      } else if (operator.isUserDefinableOperator()) {
        if (canSkipUnaryOpShim) {
          JsExpression expr = new JsPrefixOperation(mapUnaryOp(operator), arg);
          expr.setSourceRef(x);
          return expr;
        } else {
          JsNameRef ref = new JsNameRef(mangler.createOperatorSyntax(operator));
          result = (AstUtil.newInvocation(ref, arg));
          return result.setSourceRef(x);
        }
      } else {
        JsUnaryOperator jsUnaryOperator;
        switch (operator) {
          case INC:
            jsUnaryOperator = JsUnaryOperator.INC;
            break;
          case DEC:
            jsUnaryOperator = JsUnaryOperator.DEC;
            break;
          case NOT:
            jsUnaryOperator = JsUnaryOperator.NOT;
            break;
          default:
            throw new AssertionError("Unexpected unary operator " + operator.name());
        }

        if (x.isPrefix()) {
          result = new JsPrefixOperation(jsUnaryOperator, arg);
        } else {
          result = new JsPostfixOperation(jsUnaryOperator, arg);
        }

        return result.setSourceRef(x);
      }
    }

    @Override
    public JsNode visitPropertyAccess(DartPropertyAccess x) {
      Element element = optStrategy.findOptimizableFieldElementFor(x, FieldKind.GETTER);
      return generateLoad(x.getQualifier(), x.getName(), element).setSourceRef(x);
    }

    @Override
    public JsNode visitArrayAccess(DartArrayAccess x) {
      JsExpression target = (JsExpression) generate(x.getTarget());
      JsExpression key = (JsExpression) generate(x.getKey());
      if (optStrategy.canSkipArrayAccessShim(x, false /* isAssignee */)) {
        return AstUtil.newArrayAccess(target, inlineArrayIndexCheck(target, key));
      } else {
        JsNameRef ref = AstUtil.newNameRef(target, mangler.createOperatorSyntax(Token.INDEX));
        JsInvocation invoke = AstUtil.newInvocation(ref, key);
        return invoke.setSourceRef(x);
      }
    }

    @Override
    public JsNode visitUnqualifiedInvocation(DartUnqualifiedInvocation x) {
      DartIdentifier target = x.getTarget();
      Element element = target.getTargetSymbol();
      ElementKind kind = ElementKind.of(element);
      JsExpression qualifier;
      String mangledName;
      MethodElement method = null;
      switch (kind) {
        case FIELD:
        case FUNCTION_OBJECT:
        case PARAMETER:
        case VARIABLE:
          mangledName = null;
          qualifier = (JsExpression) generate(target);
          EnclosingElement enclosingElement = element.getEnclosingElement();
          if ((kind == ElementKind.FUNCTION_OBJECT) && (element.getEnclosingElement() != null)) {
            // Function-object invocations can be made directly, unless they're closures (in which
            // case their enclosing-element will be null).
            method = (MethodElement) element;
          }
          break;

        case NONE:
          mangledName = mangler.mangleMethod(x.getTarget().getTargetName(), unitLibrary);
          qualifier = new JsThisRef();
          break;

        case METHOD:
          method = (MethodElement) element;
          mangledName = mangler.mangleMethod(method, unitLibrary);
          if (element.getModifiers().isStatic()) {
            qualifier = referenceName(element.getEnclosingElement(), x.getTarget());
          } else if (Elements.isTopLevel(element)) {
            qualifier = null;
          } else {
            qualifier = new JsThisRef();
          }
          break;

        default:
          throw new AssertionError("Cannot be an unqualified invocation " + kind);
      }
      return generateInvocation(x, qualifier, false, mangledName, method);
    }

    @Override
    public JsNode visitFunctionObjectInvocation(DartFunctionObjectInvocation x) {
      DartExpression target = x.getTarget();
      if (target instanceof DartFunctionExpression) {
        DartFunctionExpression functionExpression = (DartFunctionExpression) target;
        if (functionExpression.getSymbol().getModifiers().isInlinable() && 
            !shouldGenerateDeveloperModeChecks()) {
          // TODO FunctionExpressionInliner conflics with developer mode checks
          return new FunctionExpressionInliner(functionExpression, x.getArgs()).call();
        }
      }
      JsExpression qualifier = (JsExpression) generate(target);
      return generateInvocation(x, qualifier, false, null, null);
    }

    /**
     * Takes a function expression and inlines it with the given arguments, for
     * example:
     * <pre>{@code
     *   function(parameter) &#123; return parameter; &#125;(argument)
     * }</pre>
     * becomes:
     * <pre>{@code
     *   ($1 = argument, $1)
     * }</pre>
     */
    private class FunctionExpressionInliner implements Callable<JsExpression> {
      private final List<DartExpression> arguments;
      private final List<DartParameter> parameters;
      private final Map<Symbol, Element> parameterMap = new HashMap<Symbol, Element>();
      private final List<DartStatement> statements;
      private final JsExpression[] expressions;

      FunctionExpressionInliner(DartFunctionExpression functionExpression,
                                List<DartExpression> arguments) {
        final DartFunction function = functionExpression.getFunction();
        this.arguments = arguments;
        parameters = function.getParams();
        assert arguments.size() == parameters.size();
        statements = function.getBody().getStatements();
        expressions = new JsExpression[parameters.size() + statements.size()];
      }

      @Override
      public JsExpression call() {
        int i = 0;
        Iterator<DartExpression> argumentsIterator = arguments.iterator();
        for (DartParameter parameter : parameters) {
          // Assign each argument to a new temporary.
          // For example: "arg" becomes: "$i = arg"
          expressions[i++] = rewriteArgument(parameter, argumentsIterator.next());
        }
        for (DartStatement statement : statements) {
          // Inline each statement after rewriting references to the parameters.
          // For example: "return parameter_i;" becomes: "$i"
          expressions[i++] = rewriteStatement(statement);
        }
        if (i == 1) {
          return expressions[0];
        } else {
          return AstUtil.newSequence(expressions);
        }
      }

      private JsExpression rewriteArgument(DartParameter parameter, DartExpression argument) {
        JsName temporary = createTemporary();
        VariableElement element = Elements.makeVariable(temporary.getIdent());
        parameterMap.put(parameter.getSymbol(), element);
        translationContext.getNames().setName(element, temporary);
        return AstUtil.newAssignment(temporary.makeRef(), (JsExpression) generate(argument));
      }

      private JsExpression rewriteStatement(DartStatement node) {
        node.accept(new ParameterRewriter());
        JsNode jsNode = generate(node);
        if (jsNode instanceof JsExprStmt) {
          return ((JsExprStmt) jsNode).getExpression();
        } else if (jsNode instanceof JsReturn) {
          return ((JsReturn) jsNode).getExpr();
        } else {
          throw new AssertionError(node);
        }
      }

      private class ParameterRewriter extends DartNodeTraverser<Void> {
        @Override
        public Void visitIdentifier(DartIdentifier node) {
          Element element = parameterMap.get(node.getTargetSymbol());
          if (element != null) {
            DartIdentifier identifier = new DartIdentifier(element.getName());
            identifier.setSourceInfo(node);
            identifier.setSymbol(element);
            node.setNormalizedNode(identifier);
          }
          return null;
        }
      }
    }

    @Override
    public JsNode visitMethodInvocation(DartMethodInvocation x) {
      Element element = optStrategy.findElementFor(x);
      MethodElement method = null;
      JsExpression qualifier;
      String mangledName;

      if (element == null) {
        mangledName = mangler.mangleNamedMethod(x.getFunctionNameString(), unitLibrary);
        qualifier = (JsExpression)generate(x.getTarget());
      } else {
        switch (element.getKind()) {
          case METHOD: {
            mangledName = mangler.mangleMethod((MethodElement) element, unitLibrary);
            if (element.getModifiers().isStatic()) {
              qualifier = referenceName(element.getEnclosingElement(), x.getTarget());
            } else if (Elements.isTopLevel(element)) {
              qualifier = null;
            } else {
              qualifier = (JsExpression) generate(x.getTarget());
            }
            method = (MethodElement) element;
            break;
          }

          case FIELD: {
            mangledName = mangler.mangleNamedMethod(x.getFunctionNameString(), unitLibrary);
            qualifier = (JsExpression)generate(x.getTarget());
            break;
          }

          default: {
            throw new AssertionError("Unexpected invocation target.");
          }
        }
      }

      boolean isSuperCall = isSuperCall(x.getTarget().getSymbol());
      return generateInvocation(x, qualifier, isSuperCall, mangledName, method);
    }

    private JsExpression generateConstructorInvocation(
        DartNewExpression x, JsExpression qualifier,
        MethodElement method) {
      JsInvocation invoke = (JsInvocation)generateInvocation(x, qualifier, false, null, method);
      // TODO(johnlenz): if generateInvocation generates a "noSuchMethod" call. This will add
      // useless parameters to the call, this is harmless at the moment.
      rtt.mayAddRuntimeTypeToConstrutorOrFactoryCall(getCurrentClass(), x, invoke);
      return invoke;
    }

    private JsExpression generateInvocation(DartInvocation x,
                                      JsExpression qualifier,
                                      boolean isSuperCall,
                                      String mangledName,
                                      MethodElement method) {
      JsInvocation jsInvoke = new JsInvocation();

      if (method != null) {
        if (!generateDirectCallArgs(x, method, jsInvoke)) {
          // Call cannot succeed. Return false to generate $nsme() in its place.
          return AstUtil.newInvocation(new JsNameRef("$nsme"));
        }
      } else {
        generateNamedCallArgs(x, jsInvoke);
      }

      JsExpression explicitReceiver = null;
      int argsLength = jsInvoke.getArguments().size();
      qualifier = referenceMethodMember(qualifier, mangledName);

      // If it's a super-call, and we need to adjust the 'this'.
      if (isSuperCall) {
        qualifier = AstUtil.newNameRef(qualifier, "call");
      }

      if (isSuperCall) {
        assert explicitReceiver == null;
        explicitReceiver = new JsThisRef();
      }
      if (explicitReceiver != null) {
        jsInvoke.getArguments().add(0, explicitReceiver);
      }
      jsInvoke.setQualifier(qualifier);
      return jsInvoke.setSourceRef(x);
    }

    /**
     * @return <code>false</code> if the invocation cannot succeed
     */
    private boolean generateDirectCallArgs(DartInvocation x, MethodElement target,
                                           JsInvocation jsInvoke) {
      // Direct call. Standard calling convention.
      List<DartExpression> args = x.getArgs();
      List<JsExpression> jsArgs = jsInvoke.getArguments();

      // Reorder named parameters.
      List<DartExpression> posArgs = new ArrayList<DartExpression>();
      Map<String, DartExpression> namedArgs = new HashMap<String, DartExpression>();
      for (DartExpression arg : args) {
        if (arg instanceof DartNamedExpression) {
          DartNamedExpression named = (DartNamedExpression) arg;
          namedArgs.put(named.getName().getTargetName(), named.getExpression());
        } else {
          posArgs.add(arg);
        }
      }

      int idx = 0, posUsed = 0;
      for (VariableElement param : target.getParameters()) {
        String name = param.getName();
        if (name != null) {
          DartExpression namedArg = namedArgs.get(param.getName());
          if (namedArg != null) {
            if (!param.getModifiers().isNamed()) {
              // Provided a named argument to a positional parameter.
              return false;
            }
            jsArgs.add((JsExpression) generate(namedArg));
          } else if (idx < posArgs.size()) {
            ++posUsed;
            jsArgs.add((JsExpression) generate(posArgs.get(idx)));
          } else if (param.getDefaultValue() != null) {
            jsArgs.add(generateDefaultValue(param.getDefaultValue()));
          } else {
            // Call cannot succeed; bail out.
            return false;
          }
        }
        ++idx;
      }

      if (posUsed != posArgs.size()) {
        // Unused positional arguments.
        return false;
      }

      return true;
    }

    private JsExpression generateDefaultValue(DartExpression defaultValue) {
      if (defaultValue != null) {
        if (defaultValue instanceof DartFunctionExpression) {
          // This should be caught much earlier and rejected. This check avoids an NPE later.
          return nulle();
        }
      }
      return (JsExpression) generate(defaultValue);
    }

    private void generateNamedCallArgs(DartInvocation invoke, JsInvocation jsInvoke) {
      // Indirect call. Named-parameter calling convention.
      // method(parg_count, { na0:NA0, na1:NA1, ..., count:N }, pa0, pa1, ...);
      List<DartExpression> args = invoke.getArgs();
      List<JsExpression> jsArgs = jsInvoke.getArguments();

      int namedCount = 0;
      for (DartExpression arg : args) {
        if (arg instanceof DartNamedExpression) {
          ++namedCount;
        }
      }

      JsExpression argmap;
      if (namedCount == 0) {
        argmap = new JsNameRef("$noargs");
      } else {
        JsObjectLiteral bag = new JsObjectLiteral();
        for (DartExpression arg : args) {
          if (arg instanceof DartNamedExpression) {
            DartNamedExpression namedExpr = ((DartNamedExpression) arg);
            String targetName = namedExpr.getName().getTargetName();
            JsPropertyInitializer propInit = new JsPropertyInitializer(
                string(targetName),
                (JsExpression) generate(namedExpr.getExpression()));
            bag.getPropertyInitializers().add(propInit);
          }
        }
        JsPropertyInitializer countProp = new JsPropertyInitializer(string("count"),
            number(namedCount));
        bag.getPropertyInitializers().add(countProp);
        argmap = bag;
      }

      jsArgs.add(number(args.size() - namedCount));
      jsArgs.add(argmap);
      for (DartExpression arg : args) {
        if (!(arg instanceof DartNamedExpression)) {
          jsArgs.add((JsExpression) generate(arg));
        }
      }
    }

    private JsExpression referenceMethodMember(JsExpression qualifier,
                                               String mangledName) {
      if (mangledName != null) {
        qualifier = AstUtil.newNameRef(qualifier, mangledName);
      }
      return qualifier;
    }

    @Override
    public JsNode visitThisExpression(DartThisExpression x) {
      return new JsThisRef().setSourceRef(x);
    }

    @Override
    public JsNode visitSuperExpression(DartSuperExpression x) {
      ClassElement element = x.getSymbol().getClassElement();
      JsNameRef superRef = AstUtil.newPrototypeNameRef(getJsName(element).makeRef());
      return superRef.setSourceRef(x);
    }

    @Override
    public JsNode visitSuperConstructorInvocation(DartSuperConstructorInvocation x) {
      return generateSuperConstructorInvocation(x);
    }

    @Override
    public JsNode visitNativeBlock(DartNativeBlock x) {
      JsBlock jsBlock = new JsBlock();

      DartMethodDefinition method =
          (DartMethodDefinition) currentScopeInfo.getContainingClassMember();
      String name = mangler.mangleNativeMethod(method.getSymbol());

      JsNameRef nativeRef = new JsNameRef(name);
      JsInvocation nativeCall;
      if (method.getModifiers().isStatic()) {
        nativeCall = AstUtil.newInvocation(nativeRef);
      } else {
        JsNameRef callRef = AstUtil.newNameRef(nativeRef, "call");
        nativeCall = AstUtil.newInvocation(callRef, new JsThisRef());
      }

      for (DartParameter p : method.getFunction().getParams()) {
        nativeCall.getArguments().add(getJsName(p.getSymbol()).makeRef());
      }

      jsBlock.getStatements().add(new JsReturn(nativeCall));
      return jsBlock.setSourceRef(x);
    }

    @Override
    public JsNode visitNewExpression(DartNewExpression x) {
      ConstructorElement element = x.getSymbol();
      String className = element.getConstructorType().getName();
      // TODO(floitsch): We should have a JsNames instead of creating the string representations.
      String name = mangler.createFactorySyntax(className, element.getName(), unitLibrary);
      // We add the class name of the holder of the constructor as a qualifier.
      JsName classJsName = getJsName(element.getEnclosingElement());
      JsNameRef consName = AstUtil.newNameRef(classJsName.makeRef(), name);

      JsExpression newExpr = generateConstructorInvocation(x, consName, element);
      if (x.isConst()) {
        newExpr = maybeInternConst(newExpr, Types.constructorType(x).getArguments());
      }
      return newExpr;
    }

    // Compile time constants expressions must be canonicalized.
    // We do this with the javascript native "$intern" method.
    private JsExpression maybeInternConst(JsExpression newExpr, List<? extends Type> typeParams) {
      JsInvocation intern = AstUtil.newInvocation(new JsNameRef(INTERN_CONST_FUNCTION), newExpr);
      if (typeParams != null && typeParams.size() != 0) {
        JsArrayLiteral arr = new JsArrayLiteral();
        for (Type t : typeParams) {
          JsExpression typeName;
          if (t.getKind() != TypeKind.DYNAMIC) {
            typeName = rtt.getRTTClassId((ClassElement)t.getElement());
          } else {
            typeName = string("");
          }
          arr.getExpressions().add(typeName);
        }
        intern.getArguments().add(arr);
      }
      return intern;
    }

    private boolean shouldBindThis(ScopeRootInfo.ClosureInfo info) {
      if (shouldGenerateDeveloperModeChecks()) {
        return true;
      }
      
      return !inFactoryOrStaticContext && info.referencesThis;
    }

    private boolean shouldGenerateDeveloperModeChecks() {
      return context.getCompilerConfiguration().developerModeChecks();
    }
    
    @Override
    public JsNode visitFunctionExpression(DartFunctionExpression x) {
      JsFunction fn = (JsFunction) generate(x.getFunction());

      JsName fnDeclaredName;
      JsName hoistedName;

      // TODO(johnlenz): values used in super class init methods are currently
      // evaluated twice (once for the init and once for the constructor), but
      // this is problematic.  We won't need to keep track of the hoisted
      // state once the re-evaluation problem is fixed.
      boolean fnWasPreviouslyHoisted = fn.isHoisted();
      if (fnWasPreviouslyHoisted) {
        fnDeclaredName = fn.getName();
        hoistedName = fn.getName();
      } else {

        // 0) Save off the original name
        fnDeclaredName = fn.getName();

        // 1) Create a global name for this method
        hoistedName = makeClosureHoistedJsName(currentHolder, currentScopeInfo, x);

        // 2) Give it a unique name.
        fn.setName(hoistedName);

        // 3) Insert it into global scope
        fn.rebaseScope(globalScope);

        // 4) Make it statement, if it isn't already
        globalBlock.getStatements().add(fn.makeStmt());

        // 5) Mark the function as hoisted
        fn.setHoisted();
      }

      ScopeRootInfo.ClosureInfo info = currentScopeInfo.getClosureInfo(x.getFunction());
      List<DartScope> list = info.getSortedReferencedScopeList();

      // TODO(jgw): See johnlenz' comment above about re-evaluation. This guard can go away once
      // that problem is fixed.
      if (!fnWasPreviouslyHoisted) {
        // Generate the named-parameter trampoline.
        boolean includesClosureScope = !list.isEmpty();
        boolean preserveThis = shouldBindThis(info);
        JsFunction tramp = generateNamedParameterTrampoline(x.getFunction(),
                                                            hoistedName.makeRef(),
                                                            list.size(), preserveThis);
        String mangled = mangler.mangleNamedMethod(hoistedName.getIdent(), unitLibrary);
        hoistedName = globalScope.declareName(mangled);
        tramp.setName(hoistedName);
        globalBlock.getStatements().add(tramp.makeStmt());
      }

      // 5) Bind the necessary scope references and possibly "this".
      JsExpression replacement;

      if (list.isEmpty() && inFactoryOrStaticContext) {

        // Simply replace the function
        replacement = new JsNameRef(hoistedName);

      } else {
        // Replace "function (){}" with "bind(hoistedName, this, scope1, scope2, ...)"
        // so that references to class fields can be resolved.

        JsExpression thisRef = undefined();
        // Only bind 'this' if 'this' is referenced
        if (shouldBindThis(info)) {
          thisRef = new JsThisRef();
        }

        // Replace the definition with a reference to the
        // hoisted function, and bind the necessary values
        // to it.
        int scopeCount = list.size();
        int argCount = fn.getParameters().size() + 2; // +2 => Named-parameter calling convention
        String jsBindName = "$bind";
        if (optStrategy.canOptimizeFunctionExpressionBind(x)) {
          if (scopeCount <= MAX_SPECIALIZED_BIND_SCOPES && argCount <= MAX_SPECIALIZED_BIND_ARGS) {
            // Use specialized forms.
            jsBindName = "$bind" + scopeCount + "_" + argCount;
          }
        }

        JsInvocation invoke =
          AstUtil.newInvocation(new JsNameRef(jsBindName), new JsNameRef(hoistedName), thisRef);

        // Add the scope alias to the bind call and function parameter list
        int parameterIndex = 0;
        for (DartScope s : list) {
          // Add the scope-object as argument to the bind call. The scope-object is referenced
          // in the outer function (currentFunctionScope).
          JsName aliasJsName = s.getAliasForJsScope(getCurrentFunctionScope());
          invoke.getArguments().add(new JsNameRef(aliasJsName));
          // Add the scope-object as parameter to the hoisted signature. The scope-object is
          // referenced from the inner function.
          JsName jsName = s.findAliasForJsScope(fn.getScope());
          // Scope objects are declared (in the JsScope) at first use. By construction scope-objects
          // are only created when they are used. Therefore the scope-object must exist in the
          // JsScope.
          assert jsName != null;
          // TODO(johnlenz): remove this hoisted check once the constructor/init
          // parameters aren't reused.
          if (!fnWasPreviouslyHoisted) {
            fn.getParameters().add(parameterIndex, new JsParameter(jsName));
          }
          parameterIndex += 1;
        }

        replacement = invoke;
      }

      // 6) If this is a named function expression, then we need to build the scope object.
      if (!x.isStatement() && x.getName() != null) {
        ScopeRootInfo scopeInfo = currentScopeInfo;
        DartScope scope = scopeInfo.getScope(x);
        // If the function is not used by name, then we might not need to create a scope.
        if (scope.definesClosureReferencedSymbols()) {
          // Make sure the alias is defined in the scope.
          JsScope currentFunctionScope = getCurrentFunctionScope();
          // This must be the second use of the scope in this function scope. The first use was
          // as argument to the bind-invocation above.
          JsName aliasName = scope.findAliasForJsScope(currentFunctionScope);
          assert aliasName != null;
          registerForDeclaration(aliasName);

          // Assume that the initial expression was x = function f() { <body> }.
          // Up to this point the function has been hoisted and replaced by a binding call:
          //    x = bind(hoistedName, this, scope1, ...)
          // The variable "replacement" is equal to the bind call.
          //
          // One of the scopes - say "scope2" - is the FunctionExpressionScope that defines 'f'
          // itself. We now need to set up this scope.
          // Transform:
          //   x = bind(hoistedName, this, scope1, ...) into
          //   x = (scope2 = {}, scope2.f = bind(hoistedName, this, scope1, ...)).
          JsExpression init =
              AstUtil.newAssignment(new JsNameRef(aliasName), new JsObjectLiteral());
          JsNameRef scopeF = makeScopeAliasNameRef(scope, x.getSymbol());
          JsExpression assig = AstUtil.newAssignment(scopeF, replacement);
          replacement = new JsBinaryOperation(JsBinaryOperator.COMMA, init, assig);
          // TODO(floitsch): we need to clear the scope object.
        }
      }

      if (x.isStatement()) {
        // If the name is referenced by a closure use the scope alias.
        JsNameRef scopeAliasRef = maybeMakeScopeAliasReference(x.getSymbol());
        if (scopeAliasRef != null) {
          JsExpression assig = AstUtil.newAssignment(scopeAliasRef, replacement);
          // We must not return a statement. The parent has a check and handles JsVars differently.
          // By default it actually expects an expression.
          return assig.setSourceRef(x);
        } else {
          // The parent expects an expression, but handles Var statements separately.
          assert !hoistedName.equals(fnDeclaredName);
          JsVars vars = AstUtil.newVar(x.getName(), fnDeclaredName, replacement);
          return vars.setSourceRef(x);
        }
      } else {
        return replacement.setSourceRef(x);
      }
    }

    private JsName makeClosureHoistedJsName(
        Element holder, ScopeRootInfo info, DartFunctionExpression x) {
      Element element = info.getContainingElement();
      String closureIdentifier = info.getNextClosureName();
      String closureName = x.getFunctionName();
      String hoistedName =
          mangler.createHoistedFunctionName(holder, element, closureIdentifier, closureName);
      return globalScope.declareName(hoistedName, hoistedName, closureName);
    }

    @Override
    public JsNode visitIdentifier(DartIdentifier x) {
      DartExpression normalizedNode = x.getNormalizedNode();
      if (normalizedNode != x) {
        return normalizedNode.accept(this);
      }

      Element element = optStrategy.findOptimizableFieldElementFor(x, FieldKind.GETTER);
      return generateLoad(null, x, element).setSourceRef(x);
    }

    /**
     * @return A NameRef to the scoped alias if needed.
     */
    private JsNameRef maybeMakeScopeAliasReference(Symbol targetSymbol) {
      if (!functionStack.isEmpty()) {
        /*
         * Currently, you must be inside of a DartFunction in order to be able to generate a
         * scope alias.
         */
        ScopeRootInfo methodInfo = currentScopeInfo;
        if (methodInfo != null) {
          DartScope.DartSymbolInfo symbolInfo = methodInfo.getSymbolInfo(targetSymbol);
          if (symbolInfo != null && symbolInfo.isReferencedFromClosure()) {
            return makeScopeAliasNameRef(symbolInfo.getOwningScope(), targetSymbol);
          }
        }
      }
      return null;
    }

    private JsNameRef makeScopeAliasNameRef(DartScope scope, Symbol targetSymbol) {
      JsName qualifier = scope.getAliasForJsScope(getCurrentFunctionScope());
      return AstUtil.newNameRef(new JsNameRef(qualifier), getJsName(targetSymbol).getIdent());
    }

    @Override
    public JsNode visitNullLiteral(DartNullLiteral x) {
      // TODO(johnlenz): set source location?
      return undefined();
    }

    @Override
    public JsNode visitStringLiteral(DartStringLiteral x) {
      // TODO(johnlenz): properly set source location?
      return string(x.getValue()).setSourceRef(x);
    }

    @Override
    public JsNode visitStringInterpolation(DartStringInterpolation x) {
      List<DartStringLiteral> strings = x.getStrings();
      List<DartExpression> expressions = x.getExpressions();

      JsExpression res = null;
      Iterator<DartExpression> eIter = expressions.iterator();
      boolean first = true;
      for (DartStringLiteral lit : strings) {
        if (first) {
          first = false;
          res = (JsExpression) generate(lit);
        } else {
          assert eIter.hasNext() : "DartStringInterpolation invariant broken.";
          JsExpression expr = (JsExpression) generate(eIter.next());
          JsInvocation exprToString = new JsInvocation();
          exprToString.setQualifier(new JsNameRef("$toString"));
          exprToString.getArguments().add(expr);
          res = new JsBinaryOperation(JsBinaryOperator.ADD,
              new JsBinaryOperation(JsBinaryOperator.ADD, res, exprToString),
              (JsExpression) generate(lit)).setSourceRef(x);
        }
      }
      assert res != null;
      return res;
    }

    @Override
    public JsNode visitBooleanLiteral(DartBooleanLiteral x) {
      // TODO(johnlenz): set source location?
      return x.getValue() ? translationContext.getProgram().getTrueLiteral() : translationContext.getProgram().getFalseLiteral();
    }

    @Override
    public JsNode visitIntegerLiteral(DartIntegerLiteral x) {
      // TODO(johnlenz): set source location?
      return number(x.getValue().doubleValue());
    }

    @Override
    public JsNode visitDoubleLiteral(DartDoubleLiteral x) {
      // TODO(johnlenz): set source location?
      return number(x.getValue());
    }

    @Override
    public JsNode visitArrayLiteral(DartArrayLiteral x) {
      JsArrayLiteral jsArray = new JsArrayLiteral();
      generateAll(x.getExpressions(), jsArray.getExpressions(), JsExpression.class);
      jsArray.setSourceRef(x);
      JsExpression result = rtt.maybeAddRuntimeTypeForArrayLiteral(getCurrentClass(), x, jsArray);
      if (x.isConst()) {
        result = this.maybeInternConst(result, x.getType().getArguments());
      }
      return result;
    }

    @Override
    @SuppressWarnings("deprecation")
    public JsNode visitMapLiteral(DartMapLiteral x) {
      // Map { 'a': 3, 'b': "foo" } to
      // (tmp = new Map(), tmp.a = 3, tmp.b = "foo", tmp)
      // TODO(floitsch): optimize map-literal creation.
      JsName tmpVar = createTemporary();
      // TODO(floitsch): hardcoded reference to "LinkedHashMapImplementation".
      // We should instead get the element from the DartMapLiteral x.
      String name = "LinkedHashMapImplementation";
      String mangledMap = mangler.mangleClassNameHack(null, name);
      String mangledFactory = mangler.createFactorySyntax(name, "", unitLibrary);
      JsNameRef runtimeMap = AstUtil.newNameRef(new JsNameRef(mangledMap), mangledFactory);
      JsInvocation invoke = AstUtil.newInvocation(runtimeMap);
      rtt.maybeAddRuntimeTypeToMapLiteralConstructor(getCurrentClass(), x, invoke);
      JsExpression assig = AstUtil.newAssignment(tmpVar.makeRef(), invoke.setSourceRef(x));
      JsExpression result = assig;
      for (DartMapLiteralEntry entry : x.getEntries()) {
        result = AstUtil.newSequence(result, visitMapLiteralEntry(entry, tmpVar));
      }
      result = AstUtil.newSequence(result, tmpVar.makeRef());
      if (x.isConst()) {
        result = this.maybeInternConst(result, x.getType().getArguments());
      }
      return result;
    }

    private JsExpression visitMapLiteralEntry(DartMapLiteralEntry x, JsName map) {
      String addMethod = mangler.createOperatorSyntax(Token.ASSIGN_INDEX);
      JsExpression value = (JsExpression) generate(x.getValue());
      JsExpression key = (JsExpression) generate(x.getKey());
      JsNameRef methodName = AstUtil.newNameRef(map.makeRef(), addMethod);
      return AstUtil.newInvocation(methodName, key, value).setSourceRef(x);
    }

    @Override
    public JsNode visitMapLiteralEntry(DartMapLiteralEntry x) {
      throw new InternalCompilerException("MapLiteralEntries are handled by the 2-arg variant.");
    }

    @Override
    public JsNode visitNamedExpression(DartNamedExpression node) {
      return generate(node.getExpression());
    }

    @Override
    public JsNode visitRedirectConstructorInvocation(DartRedirectConstructorInvocation x) {
      return generateSuperConstructorInvocation(x);
    }

    private JsNode generateSuperConstructorInvocation(DartInvocation x) {
      // Must use SuperClass.call(this, ...) to get the correct 'this' context in the callee:
      //   <super-class>.<name>$Constructor.call(this, ...).
      ConstructorElement element = (ConstructorElement) x.getSymbol();
      Element classElement;
      String elementName;
      if (element == null) {
        classElement = ((ClassElement) currentHolder).getSupertype().getElement();
        elementName = classElement.getName();
      } else {
        classElement = element.getEnclosingElement();
        elementName = element.getName();
      }
      
      // TODO(floitsch): it would be good, if we could get a js-name instead of just a string.
      // This way the debugging information would be better.
      // We need to generate the JsName (for the initializer/factory) once only and store it
      // in some hashtable. Then instead of reusing the mangler, we should reuse those JsNames.
      // The debugging information would then contain a link from the property-access to the
      // constructor. Without JsName the debugger just assumes we access some random property.
      String name = mangler.mangleConstructor(elementName, unitLibrary);
      JsNameRef constructorRef = AstUtil.newNameRef(getJsName(classElement).makeRef(), name);
      return generateInvocation(x, constructorRef, true, null, element);
    }

    private JsBinaryOperator mapBinaryOp(Token operator) {
      switch (operator) {
        /* Assignment operators. */
        case ASSIGN: return JsBinaryOperator.ASG;
        case ASSIGN_BIT_OR: return JsBinaryOperator.ASG_BIT_OR;
        case ASSIGN_BIT_XOR: return JsBinaryOperator.ASG_BIT_XOR;
        case ASSIGN_BIT_AND: return JsBinaryOperator.ASG_BIT_AND;
        case ASSIGN_SHL: return JsBinaryOperator.ASG_SHL;
        case ASSIGN_SAR: return JsBinaryOperator.ASG_SHR;
        case ASSIGN_SHR: return JsBinaryOperator.ASG_SHRU;
        case ASSIGN_ADD: return JsBinaryOperator.ASG_ADD;
        case ASSIGN_SUB: return JsBinaryOperator.ASG_SUB;
        case ASSIGN_MUL: return JsBinaryOperator.ASG_MUL;
        case ASSIGN_DIV: return JsBinaryOperator.ASG_DIV;
        case ASSIGN_MOD: return JsBinaryOperator.ASG_MOD;

        /* Binary operators sorted by precedence. */
        case OR: return JsBinaryOperator.OR;
        case AND: return JsBinaryOperator.AND;
        case BIT_OR: return JsBinaryOperator.BIT_OR;
        case BIT_XOR: return JsBinaryOperator.BIT_XOR;
        case BIT_AND: return JsBinaryOperator.BIT_AND;
        case SHL: return JsBinaryOperator.SHL;
        case SAR: return JsBinaryOperator.SHR;
        case SHR: return JsBinaryOperator.SHRU;
        case ADD: return JsBinaryOperator.ADD;
        case SUB: return JsBinaryOperator.SUB;
        case MUL: return JsBinaryOperator.MUL;
        case DIV: return JsBinaryOperator.DIV;
        case MOD: return JsBinaryOperator.MOD;

        /* Compare operators sorted by precedence. */
        case EQ: return JsBinaryOperator.EQ;
        case NE: return JsBinaryOperator.NEQ;
        case EQ_STRICT: return JsBinaryOperator.REF_EQ;
        case NE_STRICT: return JsBinaryOperator.REF_NEQ;
        case LT: return JsBinaryOperator.LT;
        case GT: return JsBinaryOperator.GT;
        case LTE: return JsBinaryOperator.LTE;
        case GTE: return JsBinaryOperator.GTE;

        // Only used by 'for'.
        case COMMA: return JsBinaryOperator.COMMA;

        default:
          throw new InternalCompilerException("Invalid binary operator");
      }
    }

    private JsUnaryOperator mapUnaryOp(Token operator) {
      switch (operator) {
        case BIT_NOT:
          return JsUnaryOperator.BIT_NOT;
        case NOT:
          return JsUnaryOperator.NOT;
        case SUB:
          return JsUnaryOperator.NEG;
        case INC:
          return JsUnaryOperator.INC;
        case DEC:
          return JsUnaryOperator.DEC;
        default:
          throw new InternalCompilerException("Invalid unary operator.");
      }
    }

    private Token mapToStrictEquals(Token op) {
      switch (op) {
        case EQ:
          return Token.EQ_STRICT;
        case NE:
          return Token.NE_STRICT;
        case EQ_STRICT:
          return Token.EQ_STRICT;
        case NE_STRICT:
          return Token.NE_STRICT;
        default:
          throw new InternalCompilerException("Invalid equals operator.");
      }
    }

    private Token mapToNonStrictEquals(Token op) {
      switch (op) {
        case EQ_STRICT:
          return Token.EQ;
        case NE_STRICT:
          return Token.NE;
        case EQ:
          return Token.EQ;
        case NE:
          return Token.NE;
        default:
          throw new InternalCompilerException("Invalid equals operator.");
      }
    }

    class Assignment extends DartNodeTraverser<JsNode> {
      private final DartNode info;
      private final JsExpression rhs;
      private final Type rhsType;

      public Assignment(DartNode info, JsExpression rhs, Type rhsType) {
        this.info = info;
        this.rhs = rhs;
        this.rhsType = rhsType;
      }

      @Override
      public JsNode visitNode(DartNode lhs) {
        throw new AssertionError(lhs.getClass().getSimpleName());
      }

      @Override
      public JsNode visitIdentifier(DartIdentifier lhs) {
        DartExpression normalizedNode = lhs.getNormalizedNode();
        if (lhs != normalizedNode) {
          return normalizedNode.accept(this);
        }
        Type type = getTypeOfIdentifier(lhs);
        JsExpression wrapped =  rtt.addTypeCheck(getCurrentClass(), rhs, type, rhsType, info);
        Element element = optStrategy.findOptimizableFieldElementFor(lhs, FieldKind.SETTER);
        // On the form e1.name = rhs.
        return generateStore(null, lhs, wrapped, element).setSourceRef(info);
      }

      @Override
      public JsNode visitPropertyAccess(DartPropertyAccess lhs) {
        Element element = optStrategy.findOptimizableFieldElementFor(lhs, FieldKind.SETTER);
        // On the form e1.name = rhs.
        Type type = lhs.getType();
        JsExpression wrapped =  rtt.addTypeCheck(getCurrentClass(), rhs, type, rhsType, info);
        return generateStore(lhs.getQualifier(), lhs.getName(), wrapped,
            element).setSourceRef(info);
      }

      @Override
      public JsNode visitArrayAccess(DartArrayAccess lhs) {
        // On the form e1[key] = argument.
        // Generate: e1.$set(key, $0 = argument), $0

        JsExpression key = (JsExpression) generate(lhs.getKey());
        JsExpression e1 = (JsExpression) generate(lhs.getTarget());
        Type type = lhs.getType();
        JsExpression wrapped =  rtt.addTypeCheck(getCurrentClass(), rhs, type, rhsType, info);
        if (optStrategy.canSkipArrayAccessShim(lhs, true /* isAssignee */)) {
          JsBinaryOperation assign = new JsBinaryOperation(JsBinaryOperator.ASG);
          assign.setArg1(AstUtil.newArrayAccess(e1, inlineArrayIndexCheck(e1, key)));
          assign.setArg2(wrapped);
          return assign.setSourceRef(info);
        } else {
          JsNameRef $0 = new JsNameRef(createTemporary());
          String $set = mangler.createOperatorSyntax(Token.ASSIGN_INDEX);
          // Generate: $0 = rhs
          JsExpression e = AstUtil.newAssignment($0, wrapped);
          // Generate: e1.$set(key, $0 = rhs)
          e = AstUtil.newInvocation(AstUtil.newNameRef(e1, $set), key, e);
          // Generate: e, $0
          return new JsBinaryOperation(JsBinaryOperator.COMMA, e, $0).setSourceRef(info);
        }
      }
    }

    private final JsNode generate(DartNode node) {
      if (node != null) {
        try {
          return node.getNormalizedNode().accept(this);
        } catch (AssertionError e) {
          reportError(node, e);
          // Wrap assertion error to prevent repeated messages for the same error.
          throw new RuntimeException(e);
        }
      } else {
        return null;
      }
    }

    private JsExpression inlineArrayIndexCheck(JsExpression array, JsExpression index) {
      return AstUtil.newInvocation(new JsNameRef("$inlineArrayIndexCheck"), array, index);
    }

    private void reportError(DartNode node, Throwable exception) {
      context.compilationError(new DartCompilationError(node, DartCompilerErrorCode.INTERNAL_ERROR,
                                                        exception.getLocalizedMessage()));
    }

    private final <T> void generateAll(List<? extends DartNode> nodes, List<T> result,
                                       Class<? extends T> cls) {
      for (DartNode node : nodes) {
        result.add(cls.cast(generate(node)));
      }
    }

    JsNameRef referenceName(Symbol symbol, SourceInfo info) {
      // If the value if captured by a closure, change the reference to
      // use the alias of the value.
      JsNameRef jsNode = maybeMakeScopeAliasReference(symbol);
      if (jsNode == null) {
        jsNode = getJsName(symbol).makeRef();
      }
      jsNode.setSourceRef(info);
      return jsNode;
    }

    @Override
    public void visit(List<? extends DartNode> nodes) {
      if (nodes != null) {
        for (DartNode node : nodes) {
          node.accept(this);
        }
      }
    }

    @Override
    public JsNode visitAssertion(DartAssertion node) {
      JsExpression expression = (JsExpression) generate(node.getExpression());
      JsExpression message = (JsExpression) generate(node.getMessage());
      JsNameRef assertName = new JsNameRef("assert");
      JsInvocation jsInvoke;
      if (message == null) {
        jsInvoke = AstUtil.newInvocation(assertName, expression);
      } else {
        jsInvoke = AstUtil.newInvocation(assertName, expression, message);
      }
      return new JsExprStmt(jsInvoke).setSourceRef(node);
    }

    @Override
    public JsNode visitParenthesizedExpression(DartParenthesizedExpression node) {
      return node.getExpression().accept(this);
    }

    @Override
    public JsNode visitCatchBlock(DartCatchBlock node) {
      throw new AssertionError("should never be called directly");
    }

    @Override
    public JsNode visitUnit(DartUnit unit) {
      throw new AssertionError("should never be called directly");
      /*
      unit.visitChildren(this);
      // Initialize static fields after declaring every method, getters &
      // setters (b/4101270)
      // TODO(johnlenz): canonicalize statics values
      globalBlock.getStatements().addAll(staticInit);
      */
    }

    @Override
    public JsNode visitFunctionTypeAlias(DartFunctionTypeAlias node) {
      return null;
    }

    private JsExpression generateQualifiedFieldAccess(DartNode qualifier,
        String accessorName, boolean accessThroughShim) {
      // Generate this.ACCESSOR();
      JsExpression jsQualifier;
      if (qualifier == null || (qualifier instanceof DartThisExpression)) {
        jsQualifier = new JsThisRef();
      } else {
        jsQualifier = (JsExpression) generate(qualifier);
      }

      jsQualifier.setSourceRef(qualifier);
      JsNameRef nameRef = AstUtil.newNameRef(jsQualifier, accessorName);
      if (accessThroughShim) {
        return AstUtil.newInvocation(nameRef);
      } else {
        return nameRef;
      }
    }

    private JsExpression generateUnresolvedAccess(DartNode qualifier,
                                                  String accessorName) {
      if (qualifier == null) {
        return generateQualifiedFieldAccess(qualifier, accessorName, true);
      }
      // Generate qualifier.ACCESSOR();
      JsExpression jsQualifier = (JsExpression) generate(qualifier);
      jsQualifier.setSourceRef(qualifier);
      JsNameRef method = AstUtil.newNameRef(jsQualifier, accessorName);
      return AstUtil.newInvocation(method);
    }

    private JsInvocation generateSuperFieldAccess(DartNode qualifier,
                                                  String accessorName) {
      // Generate CLASS.prototype.ACCESSOR.call(this);
      ClassElement superClass = ((SuperElement) qualifier.getSymbol()).getClassElement();
      JsExpression jsQualifier = AstUtil.newPrototypeNameRef(getJsName(superClass).makeRef());
      jsQualifier.setSourceRef(qualifier);
      JsNameRef method = AstUtil.newNameRef(jsQualifier, accessorName);
      method = AstUtil.newNameRef(method, "call");
      JsInvocation jsInvoke = AstUtil.newInvocation(method);
      jsInvoke.getArguments().add(0, new JsThisRef());
      return jsInvoke;
    }

    private JsInvocation generateStaticFieldAccess(FieldElement element,
                                                   DartNode qualifier,
                                                   String accessorName) {
      // Generate CLASS.ACCESSOR();
      JsExpression jsQualifier = referenceName(element.getEnclosingElement(), qualifier);
      jsQualifier.setSourceRef(qualifier);
      JsNameRef method = AstUtil.newNameRef(jsQualifier, accessorName);
      return AstUtil.newInvocation(method);
    }

    private JsInvocation generateLibraryFieldAccess(String accessorName) {
      // Generate ACCESSOR();
      return AstUtil.newInvocation(new JsNameRef(accessorName));
    }

    private JsExpression generateFieldAccess(FieldElement field, DartNode qualifier,
        String accessorName, boolean accessThroughShim) {
      boolean isSuperCall = (qualifier != null) && isSuperCall(qualifier.getSymbol());
      if (isSuperCall) {
        return generateSuperFieldAccess(qualifier, accessorName);
      } else if (Elements.isTopLevel(field)) {
        return generateLibraryFieldAccess(accessorName);
      } else if (field.isStatic()) {
        return generateStaticFieldAccess(field, qualifier, accessorName);
      } else {
        return generateQualifiedFieldAccess(qualifier, accessorName, accessThroughShim);
      }
    }

    /*
     * A method is accessed as if a closure object
     * class A { foo() { return 1;  })
     * Function f = A.foo;
     */
    private JsExpression generateMethodBoundToVariable(DartIdentifier methodNode,
        MethodElement methodElement, DartNode qualifier) {
      JsExpression boundMethod;
      String mangledName = mangler.mangleNamedMethod(methodElement, unitLibrary);
      boolean isSuperCall = (qualifier != null) && isSuperCall(qualifier.getSymbol());
      if (isSuperCall) {
        boundMethod = generateSuperFieldAccess(qualifier,
          mangler.createGetterSyntax(methodElement.getName(), unitLibrary));
      } else if (Elements.isTopLevel(methodElement)) {
        boundMethod = AstUtil.newNameRef(null, mangledName);
      } else if (methodElement.isStatic()) {
        if (qualifier == null) {
          qualifier = methodElement.getEnclosingElement().getNode();
          assert (qualifier instanceof DartClass);
          boundMethod = AstUtil.newNameRef(getJsName(qualifier.getSymbol()).makeRef(), mangledName);
        } else {
          assert (qualifier instanceof DartIdentifier);
          boundMethod = AstUtil.newNameRef((JsExpression) generate(qualifier), mangledName);
        }
      } else {
        // Should be an invocation on an instance
        if (qualifier == null) {
          qualifier = DartThisExpression.get();
        }
        JsExpression methodQualifier = (JsExpression) generate(qualifier);
        ClassElement classElement = (ClassElement) methodElement.getEnclosingElement();
        String className = mangler.mangleClassName(classElement);
        JsNameRef prototypeRef = AstUtil.newPrototypeNameRef(new JsNameRef(className));
        JsExpression methodToCall = AstUtil.newNameRef(prototypeRef, mangledName);
        boundMethod = AstUtil.newInvocation(new JsNameRef("$bind"), methodToCall, methodQualifier);
      }
      boundMethod.setSourceRef(methodNode);
      return boundMethod;
    }

    private JsExpression generateLoadTemporary(Element element, DartIdentifier node) {
      return referenceName(element, node);
    }

    private JsExpression generateLoad(DartNode qualifier, DartIdentifier node, Element element) {
      boolean accessThroughShim = true;
      if (element != null) {
        accessThroughShim = false;
      } else {
        element = node.getTargetSymbol();
      }

      switch (ElementKind.of(element)) {
        case VARIABLE:
        case PARAMETER:
        case FUNCTION_OBJECT:
          // TODO(5089961): we should not generate code for class expressions.
        case CLASS:
          return generateLoadTemporary(element, node);

        case NONE:
          if (qualifier != null && isSuperCall(qualifier.getSymbol())) {
            return generateSuperFieldAccess(qualifier,
              mangler.createGetterSyntax(node.getTargetName(), unitLibrary));
          }
          return generateUnresolvedAccess(qualifier,
              mangler.createGetterSyntax(node.getTargetName(), unitLibrary));

        case FIELD: {
          FieldElement field = (FieldElement) element;
          String accessorName;
          if (accessThroughShim) {
            accessorName = mangler.createGetterSyntax(field, unitLibrary);
          } else {
            if (optStrategy.isWhitelistedNativeField(field, FieldKind.GETTER)) {
              accessorName = field.getName();
            } else {
              accessorName = mangler.mangleField(field, unitLibrary);
            }
          }
          return generateFieldAccess(field, qualifier, accessorName, accessThroughShim);
        }

        case METHOD: {
          MethodElement method = (MethodElement) element;
          return generateMethodBoundToVariable(node, method, qualifier);
        }

        default:
          throw new AssertionError("I do not know how to load: " + ElementKind.of(element));
      }
    }

    private JsExpression generateStoreTemporary(Element element,
                                                DartIdentifier node,
                                                JsExpression rhs) {
      JsNameRef jsName = referenceName(element, node);
      return AstUtil.newAssignment(jsName, rhs);
    }

    private JsExpression generateStoreField(JsExpression fieldAccess,
                                            JsExpression rhs) {
      if (fieldAccess instanceof JsInvocation) {
        JsNameRef $0 = new JsNameRef(createTemporary());
        // Generate: $0 = rhs
        JsExpression e = AstUtil.newAssignment($0, rhs);

        // Add ($0 = rhs) as parameter of the field access.
        ((JsInvocation) fieldAccess).getArguments().add(e);
        // Generate: e1.set$name($0 = rhs), $0
        return new JsBinaryOperation(JsBinaryOperator.COMMA, fieldAccess, $0);
      } else {
        assert (fieldAccess instanceof JsNameRef);
        return AstUtil.newAssignment((JsNameRef) fieldAccess, rhs);
      }
    }

    private JsExpression generateStore(DartNode qualifier, DartIdentifier node, JsExpression rhs,
        Element element) {
      boolean accessThroughShim = true;
      if (element != null) {
        accessThroughShim = false;
      } else {
        element = node.getTargetSymbol();
      }

      switch (ElementKind.of(element)) {
        case VARIABLE:
        case PARAMETER:
          return generateStoreTemporary(element, node, rhs);

        case NONE: {
          JsExpression invoke =
              generateUnresolvedAccess(qualifier,
                  mangler.createSetterSyntax(node.getTargetName(), unitLibrary));
          return generateStoreField(invoke, rhs);
        }

        case FIELD: {
          FieldElement field = (FieldElement) element;
          String accessorName;

          if (accessThroughShim) {
            accessorName = mangler.createSetterSyntax(field, unitLibrary);
          } else {
            if (optStrategy.isWhitelistedNativeField(field, FieldKind.SETTER)) {
              accessorName = field.getName();
            } else {
              accessorName = mangler.mangleField(field, unitLibrary);
            }
          }

          JsExpression invoke =
              generateFieldAccess(field, qualifier, accessorName, accessThroughShim);
          return generateStoreField(invoke, rhs);
        }

        default:
          throw new AssertionError("I do not know how to store into: " + ElementKind.of(element));
      }
    }

    @Override
    public JsNode visitParameterizedNode(DartParameterizedNode node) {
      return node.getExpression().accept(this);
    }

    @Override
    public JsNode visitImportDirective(DartImportDirective node) {
      throw new AssertionError("should never be called directly");
    }

    @Override
    public JsNode visitLibraryDirective(DartLibraryDirective node) {
      throw new AssertionError("should never be called directly");
    }

    @Override
    public JsNode visitNativeDirective(DartNativeDirective node) {
      throw new AssertionError("should never be called directly");
    }

    @Override
    public JsNode visitResourceDirective(DartResourceDirective node) {
      throw new AssertionError("should never be called directly");
    }

    @Override
    public JsNode visitSourceDirective(DartSourceDirective node) {
      throw new AssertionError("should never be called directly");
    }

    @Override
    public DartClassMember<?> getCurrentClassMember() {
      if (this.currentScopeInfo != null) {
        return currentScopeInfo.getContainingClassMember();
      }
      return null;
    }

    private ClassElement getCurrentClass() {
      if (currentHolder.getKind() == ElementKind.CLASS) {
        return (ClassElement) currentHolder;
      }
      return null;
    }
  }

  GenerateJavascriptAST(DartUnit unit, CoreTypeProvider typeProvider, DartCompilerContext context,
                        OptimizationStrategy optimizationStrategy) {
    this.unit = unit;
    this.context = context;
    this.optStrategy = optimizationStrategy;
    this.typeProvider = typeProvider;
  }

  public void translateNode(TranslationContext translationContext, DartNode node,
      JsBlock blockStatics) {
    GenerateJavascriptVisitor generator =
        new GenerateJavascriptVisitor(unit, context, translationContext,
            optStrategy, typeProvider);
    // Generate the Javascript AST.
    node.accept(generator);
    // Set aside the static initializations
    generator.addStaticInitsToBlock(blockStatics);
  }
}
