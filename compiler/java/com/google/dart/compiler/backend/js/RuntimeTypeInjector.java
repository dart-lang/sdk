// Copyright 2011, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//  * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above
//    copyright notice, this list of conditions and the following
//    disclaimer in the documentation and/or other materials provided
//    with the distribution.
//  * Neither the name of Google Inc. nor the names of its
//    contributors may be used to endorse or promote products derived
//    from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package com.google.dart.compiler.backend.js;

import static com.google.dart.compiler.util.AstUtil.and;
import static com.google.dart.compiler.util.AstUtil.assign;
import static com.google.dart.compiler.util.AstUtil.call;
import static com.google.dart.compiler.util.AstUtil.comma;
import static com.google.dart.compiler.util.AstUtil.nameref;
import static com.google.dart.compiler.util.AstUtil.neq;
import static com.google.dart.compiler.util.AstUtil.newAssignment;
import static com.google.dart.compiler.util.AstUtil.newInvocation;
import static com.google.dart.compiler.util.AstUtil.newNameRef;
import static com.google.dart.compiler.util.AstUtil.newQualifiedNameRef;
import static com.google.dart.compiler.util.AstUtil.newVar;
import static com.google.dart.compiler.util.AstUtil.not;

import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import com.google.dart.compiler.InternalCompilerException;
import com.google.dart.compiler.ast.DartArrayLiteral;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartClassMember;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartMapLiteral;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.backend.js.ast.JsArrayAccess;
import com.google.dart.compiler.backend.js.ast.JsArrayLiteral;
import com.google.dart.compiler.backend.js.ast.JsBlock;
import com.google.dart.compiler.backend.js.ast.JsExpression;
import com.google.dart.compiler.backend.js.ast.JsFunction;
import com.google.dart.compiler.backend.js.ast.JsInvocation;
import com.google.dart.compiler.backend.js.ast.JsName;
import com.google.dart.compiler.backend.js.ast.JsNameRef;
import com.google.dart.compiler.backend.js.ast.JsParameter;
import com.google.dart.compiler.backend.js.ast.JsProgram;
import com.google.dart.compiler.backend.js.ast.JsReturn;
import com.google.dart.compiler.backend.js.ast.JsScope;
import com.google.dart.compiler.backend.js.ast.JsStatement;
import com.google.dart.compiler.backend.js.ast.JsStringLiteral;
import com.google.dart.compiler.backend.js.ast.JsThisRef;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ConstructorElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.DynamicElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.EnclosingElement;
import com.google.dart.compiler.resolver.FunctionAliasElementImplementation;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.VariableElement;
import com.google.dart.compiler.type.FunctionAliasType;
import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeKind;
import com.google.dart.compiler.type.TypeVariable;
import com.google.dart.compiler.type.Types;
import com.google.dart.compiler.util.AstUtil;

import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * A helper class that contains the logic necessary for injecting runtime type references.
 *
 * @author johnlenz@google.com (John Lenz)
 */
public class RuntimeTypeInjector {
  private final boolean emitTypeChecks;
  private final TraversalContextProvider context;
  private final JsBlock globalBlock;
  private final JsScope globalScope;
  // Maps builtin types to Javascript types implementations.
  private final Map<ClassElement, String> builtInTypeChecks;
  private CoreTypeProvider typeProvider;
  private final TranslationContext translationContext;
  private final Types types;
  private final DartMangler mangler;
  private final LibraryElement unitLibrary;
  private static final String RTT_DYNAMIC_LOOKUP = "RTT.dynamicType.$lookupRTT";
  private static final String RTT_NAMED_PARAMETER = "named";

  RuntimeTypeInjector(
      TraversalContextProvider context,
      CoreTypeProvider typeProvider,
      TranslationContext translationContext,
      boolean emitTypeChecks, DartMangler mangler,
      LibraryElement unitLibrary) {
    this.context = context;
    this.translationContext = translationContext;
    JsProgram program = translationContext.getProgram();
    this.globalBlock = program.getGlobalBlock();
    this.globalScope = program.getScope();
    this.builtInTypeChecks = makeBuiltinTypes(typeProvider);
    this.typeProvider = typeProvider;
    this.emitTypeChecks = emitTypeChecks;
    this.mangler = mangler;
    this.unitLibrary = unitLibrary;
    types = Types.getInstance(typeProvider);
  }

  private Map<ClassElement, String> makeBuiltinTypes(CoreTypeProvider typeProvider) {
    Map<ClassElement, String> builtinTypes = Maps.newHashMap();
    builtinTypes.put(typeProvider.getBoolType().getElement(), "$isBool");
    builtinTypes.put(typeProvider.getIntType().getElement(), "$isNum");
    builtinTypes.put(typeProvider.getDoubleType().getElement(), "$isNum");
    builtinTypes.put(typeProvider.getStringType().getElement(), "$isString");
    return builtinTypes;
  }

  /**
   * Generate the code necessary to allow for runtime type checks
   */
  void generateRuntimeTypeInfo(DartClass x) {
    generateRuntimeTypeInfoMethods(x);

    ClassElement classElement = x.getSymbol();
    if (!classElement.isInterface()) {
      injectInterfaceMarkers(classElement, x);
    }
  }

  /**
   * Generate the code necessary to allow for runtime type checks of dart typedefs
   */
  void generateRuntimeTypeInfo(DartFunctionTypeAlias x) {
    generateRTTLookupMethod(x);
  }

  /**
   * Generate the code necessary to allow for runtime type checks of dart class methods
   */
  void generateRuntimeTypeInfo(DartMethodDefinition x) {
    generateRTTLookupMethod(x);
  }

  /**
   * Generate the code necessary to allow for runtime type checks of dart function expressions
   */
  void generateRuntimeTypeInfo(DartFunctionExpression x, String lookupName) {
    generateRTTLookupMethod(x, lookupName);
  }

  private void injectInterfaceMarkers(ClassElement classElement, SourceInfo srcRef) {
    JsProgram program = translationContext.getProgram();
    JsName classJsName = translationContext.getNames().getName(classElement);
    for (InterfaceType iface : getAllInterfaces(classElement)) {
      JsStatement assignment = (JsStatement) newAssignment(
        newNameRef(
           newNameRef(new JsNameRef(classJsName), "prototype"),
           "$implements$" + translationContext.getMangler().mangleClassName(iface.getElement())),
        program.getNumberLiteral(1)).makeStmt().setSourceRef(srcRef);
      globalBlock.getStatements().add(assignment);
    }
  }

  private Set<InterfaceType> getAllInterfaces(ClassElement classElement) {
    // TODO(johnlenz): All interfaces here should not include the super class implemented interfaces
    // those are handled by the super-class definition.
    Set<InterfaceType> interfaces = Sets.newLinkedHashSet();
    if (classElement.getType() == null) {
      throw new InternalCompilerException("type is null on ClassElement " + classElement);
    }
    // A class needs to implement its own implied interface so the "is"
    // implementation works properly.
    interfaces.add(classElement.getType());

   InterfaceType current = classElement.getType();
   if (current != null) {
      addAllInterfaces(interfaces, current);
    }
    return interfaces;
  }

  private void addAllInterfaces(Set<InterfaceType> interfaces, InterfaceType t) {
    interfaces.add(t);
    for (InterfaceType current : t.getElement().getInterfaces()) {
      addAllInterfaces(interfaces, current);
    }
  }

  /**
   * Insert the function or method necessary to implement runtime type information
   * for the provided class.
   */
  private void generateRuntimeTypeInfoMethods(DartClass x) {
    // 1) create static type information lookup function
    generateRTTLookupMethod(x);

    // 2) create a method to fill in the type information for the class
    ClassElement classElement = x.getSymbol();
    if (hasRTTImplements(classElement)) {
      generateRTTImplementsMethod(x);
    }

    // 3) create "addTo" method for use by classes or interfaces that inherit from this class
    generateRTTAddToMethod(x);
  }

  private void generateRTTLookupMethod(DartClass x) {
    ClassElement classElement = x.getSymbol();
    boolean hasTypeParams = hasTypeParameters(classElement);

    // 1) create static type information construction function
    // function Foo$lookupOrCreateRTT(typeargs) {
    //   return $createRTT(name, Foo$RTTimplements, typeargs) ;
    // }

    // Build the function
    JsFunction lookupFn = new JsFunction(globalScope);
    lookupFn.setBody(new JsBlock());
    List<JsStatement> body = lookupFn.getBody().getStatements();
    JsScope scope = new JsScope(globalScope, "temp");

    JsProgram program = translationContext.getProgram();

    JsInvocation invokeCreate = call(null,
        newQualifiedNameRef("RTT.create"), getRTTClassId(classElement));
    List<JsExpression> callArgs = invokeCreate.getArguments();
    if (hasRTTImplements(classElement)) {
      callArgs.add(getRTTImplementsMethodName(classElement));
    } else {
      // need a placeholder param if the typeArgs are needed.
      callArgs.add(program.getNullLiteral());
    }

    JsName typeArgs = scope.declareName("typeArgs");
    lookupFn.getParameters().add(new JsParameter(typeArgs));
    if (hasTypeParams) {
      callArgs.add(typeArgs.makeRef());
    } else {
      callArgs.add(program.getNullLiteral());
    }

    JsName named = scope.declareName(RTT_NAMED_PARAMETER);
    lookupFn.getParameters().add(new JsParameter(named));
    callArgs.add(named.makeRef());

    body.add(new JsReturn(invokeCreate));

    // Finally, Add the function
    JsExpression fnDecl = assign(null,
        getRTTLookupMethodNameRef(classElement), lookupFn);
    globalBlock.getStatements().add(fnDecl.makeStmt());
  }

  private void generateRTTImplementsMethod(DartClass x) {
    ClassElement classElement = x.getSymbol();

    // 1) create static type information construction function
    // function Foo$lookupOrCreateRTT(rtt, typeArgs) {
    //
    //   // superclass
    //   FooSuper$addTo(rtt, superTypeArg1, ...);
    //   // interfaces
    //   FooInterface1$addTo(rtt, interface1TypeArg1, ...);
    //
    //   // fill in derived types
    //   rtt.derivedTypes = [
    //      FirstRef$lookupOrCreateRTT(typearg1, ...),
    //      ...
    //      ]
    // }

    boolean hasTypeParams = classElement.getTypeParameters().size() > 0;

    // Build the function
    JsFunction implementsFn = new JsFunction(globalScope);
    implementsFn.setBody(new JsBlock());
    List<JsStatement> body = implementsFn.getBody().getStatements();
    JsScope scope = new JsScope(globalScope, "temp");

    JsName rtt = scope.declareName("rtt");
    implementsFn.getParameters().add(new JsParameter(rtt));
    JsName typeArgs = null;
    if (hasTypeParams) {
      typeArgs = scope.declareName("typeArgs");
      implementsFn.getParameters().add(new JsParameter(typeArgs));
    }

    JsInvocation callAddTo = newInvocation(getRTTAddToMethodName(classElement), rtt.makeRef());
    if (hasTypeParams) {
      typeArgs = scope.declareName("typeArgs");
      callAddTo.getArguments().add(typeArgs.makeRef());
    }
    body.add(callAddTo.makeStmt());

    // Add the derived types

    if (hasTypeParams) {
      // Populated the list of derived types
      JsArrayLiteral derivedTypesArray = new JsArrayLiteral();
      // TODO(johnlenz): Add needed types here.
      JsExpression addDerivedTypes = assign(null,
          nameref(null, rtt.makeRef(), "derivedTypes"),
          derivedTypesArray);
      body.add(addDerivedTypes.makeStmt());
    }

    // Finally, Add the function
    JsExpression fnDecl = assign(null,
       getRTTImplementsMethodName(classElement), implementsFn);
    globalBlock.getStatements().add(fnDecl.makeStmt());
  }

  private void generateRTTAddToMethod(DartClass x) {
    ClassElement classElement = x.getSymbol();

    // 2) create "addTo" method
    // Foo$Type$addTo(target, typeargs) {
    //   var rtt = Foo$lookupOrCreateRTT(typeargs)
    //   target.implementedTypes[rtt.classkey] = rtt;
    // }

    // Build the function
    JsFunction addToFn = new JsFunction(globalScope);
    addToFn.setBody(new JsBlock());
    JsScope scope = new JsScope(globalScope, "temp");

    JsName targetType = scope.declareName("target");
    addToFn.getParameters().add(new JsParameter(targetType));

    // Get the RTT info object
    JsName rtt = scope.declareName("rtt");
    List<JsStatement> body = addToFn.getBody().getStatements();
    JsInvocation callLookup = newInvocation(
        getRTTLookupMethodNameRef(classElement));

    if (hasTypeParameters(classElement)) {
      JsName typeArgs = scope.declareName("typeArgs");
      addToFn.getParameters().add(new JsParameter(typeArgs));
      callLookup.getArguments().add(new JsNameRef(typeArgs));
    }

    JsStatement rttLookup = newVar((SourceInfo)null, rtt, callLookup);
    body.add(rttLookup);

    // store it.
    JsExpression addToTypes = newAssignment(
        new JsArrayAccess(
           newNameRef(targetType.makeRef(), "implementedTypes"),
           newNameRef(rtt.makeRef(), "classKey")),
        rtt.makeRef());
    body.add(addToTypes.makeStmt());

    InterfaceType superType = classElement.getSupertype();
    if (superType != null && !superType.getElement().isObject()) {
      ClassElement interfaceElement = superType.getElement();
      JsInvocation callAddTo = newInvocation(
          getRTTAddToMethodName(interfaceElement), targetType.makeRef());
      if (hasTypeParameters(interfaceElement) && !superType.hasDynamicTypeArgs()) {
        JsArrayLiteral superTypeArgs = new JsArrayLiteral();
        List<? extends Type> typeParams = classElement.getTypeParameters();
        for (Type arg : superType.getArguments()) {
          superTypeArgs.getExpressions().add(
              buildTypeLookupExpression(arg, typeParams,
                                        nameref(null, targetType.makeRef(), "typeArgs")));
        }
        callAddTo.getArguments().add(superTypeArgs);
      }
      body.add(callAddTo.makeStmt());
    }

    // Add the interfaces

    for (InterfaceType interfaceType : classElement.getInterfaces() ) {
      ClassElement interfaceElement = interfaceType.getElement();
      // Codefu: Random addition to keep language/BlackListed13 tests failing.
      //         RTT.dynamic could define $addTo(), but this should be treated as a
      //         a compile time error, not a run time error.
      if (interfaceElement instanceof DynamicElement) {
        continue;
      }
      JsInvocation callAddTo = call(null,
          getRTTAddToMethodName(interfaceElement), targetType.makeRef());
      if (hasTypeParameters(interfaceElement) && !interfaceType.hasDynamicTypeArgs()) {
        JsArrayLiteral interfaceTypeArgs = new JsArrayLiteral();
        List<? extends Type> typeParams = classElement.getTypeParameters();
        for (Type arg : interfaceType.getArguments()) {
          interfaceTypeArgs.getExpressions().add(
              buildTypeLookupExpression(arg, typeParams,
                                        nameref(null, targetType.makeRef(), "typeArgs")));
        }
        callAddTo.getArguments().add(interfaceTypeArgs);
      }
      body.add(callAddTo.makeStmt());
    }

    // Add the function statement
    JsExpression fnDecl = newAssignment(
        getRTTAddToMethodName(classElement), addToFn);
    globalBlock.getStatements().add(fnDecl.makeStmt());
  }

  private void generateRTTLookupMethod(DartMethodDefinition x) {
    generateRTTLookupMethod(x.getSymbol(), null);
  }

  private void generateRTTLookupMethod(DartFunctionExpression x, String overrideName) {
    generateRTTLookupMethod(x.getSymbol(), overrideName);
  }

  private ClassElement getEnclosingClassElement(EnclosingElement enclosingElement) {
    while(enclosingElement != null) {
      if (enclosingElement.getKind().equals(ElementKind.CLASS)) {
        return (ClassElement)enclosingElement;
      }
      enclosingElement = enclosingElement.getEnclosingElement();
    }
    return null;
  }

  /*
   * This function will create a lookup function that indirectly calls RTT.createFunction with
   * and array of parameter types and the return type as arguments. Example:
   *   Dart:
   *     typedef List<J> TestAliasType<K,J>(int x, K k);
   *   JS:
   *     <libraryname>$<TestAliasType>$Dart.$lookupRTT = function(typeArgs){
   *       return RTT.createFunction(
   *         [int$Dart.$lookupRTT(), RTT.getTypeArg(typeArgs, 0)],
   *         List$Dart.$lookupRTT([RTT.getTypeArg(typeArgs, 1)]));
   *     }
   */
  private void generateRTTLookupMethod(MethodElement methodElement, String overrideName) {
    boolean hasTypeArguments = false;

    if (ElementKind.of(methodElement).equals(ElementKind.CONSTRUCTOR)
        || methodElement.getModifiers().isNative()) {
      // No type lookups for constructors or natives
      return;
    }
    ClassElement classElement = getEnclosingClassElement(methodElement.getEnclosingElement());
    hasTypeArguments = classElement != null ? hasTypeParameters(classElement) : false;

    JsProgram program = translationContext.getProgram();
    JsExpression typeArgContextExpr = hasTypeArguments ? buildTypeArgsReference(classElement)
        : null;

    // Build the function
    JsFunction lookupFn = new JsFunction(globalScope);
    lookupFn.setBody(new JsBlock());
    JsScope scope = new JsScope(globalScope, "temp");

    List<JsStatement> body = lookupFn.getBody().getStatements();
    JsInvocation callLookup;

    callLookup = newInvocation(newQualifiedNameRef("RTT.createFunction"));

    JsArrayLiteral arr = generateTypeArrayFromElements(methodElement.getParameters(), classElement,
        typeArgContextExpr);

    JsExpression returnExpr = generateRTTLookupForType(methodElement,
        methodElement.getReturnType(), classElement, typeArgContextExpr);

    callLookup.getArguments().add(arr.getExpressions().isEmpty() ? program.getNullLiteral() : arr);
    callLookup.getArguments().add(returnExpr);
    body.add(new JsReturn(callLookup));

    // Finally, Add the lookup function to the global block.
    JsExpression fnDecl;
    if (overrideName == null) {
      JsNameRef methodToCall = getRTTLookupMethodNameRef(methodElement);
      if (methodElement.getEnclosingElement().getKind().equals(ElementKind.CLASS)) {
        fnDecl = assign(null, methodToCall, lookupFn);
      } else {
        // Top level method
        lookupFn.setName(scope.declareFreshName(methodToCall.getIdent()));
        fnDecl = lookupFn;
      }
    } else {
      // Special care for hoisted functions.
      lookupFn.setName(scope.declareName(overrideName));
      fnDecl = lookupFn;
    }
    globalBlock.getStatements().add(fnDecl.makeStmt());
  }

  /*
   * Create a direct lookup of types for the given element.  Useful for in-line function types, as
   * in the example:
   *   int foo( int bar(double x) );
   * No lookup method exists for the type "int bar(double x)", hence the in-line creation of:
   *   RTT.createFunction([RTT Parameter Types],RTT ReturnType))
   */
  private JsInvocation generateRTTCreate(VariableElement element, ClassElement classElement) {
    boolean hasTypes = false;
    FunctionType type = (FunctionType) element.getType();

    if (ElementKind.of(element).equals(ElementKind.CONSTRUCTOR)
        || element.getModifiers().isNative()) {
      // No type lookups for constructors or natives
      return newInvocation(newQualifiedNameRef(RTT_DYNAMIC_LOOKUP));
    }
    hasTypes = classElement != null ? hasTypeParameters(classElement) : false;

    JsProgram program = translationContext.getProgram();
    JsExpression typeArgContextExpr = hasTypes ? buildTypeArgsReference(classElement) : null;
    JsInvocation callLookup;
    callLookup = newInvocation(newQualifiedNameRef("RTT.createFunction"));

    JsArrayLiteral arr = generateTypeArrayFromTypes(type.getParameterTypes(), classElement,
        typeArgContextExpr);
    if (arr == null) {
      return newInvocation(newQualifiedNameRef(RTT_DYNAMIC_LOOKUP));
    }

    JsExpression returnExpr = generateRTTLookupForType(element, type.getReturnType(), classElement,
        typeArgContextExpr);

    callLookup.getArguments().add(arr.getExpressions().isEmpty() ? program.getNullLiteral() : arr);
    callLookup.getArguments().add(returnExpr);
    return callLookup;
  }

  private JsArrayLiteral generateTypeArrayFromTypes(List<? extends Type> parameterTypes,
      ClassElement classElement, JsExpression typeArgContextExpr) {
    JsArrayLiteral jsTypeArray = new JsArrayLiteral();
    for (Type param : parameterTypes) {
      JsExpression elementExpr;
      elementExpr = generateRTTLookupForType(param.getElement(), param, classElement,
          typeArgContextExpr);
      jsTypeArray.getExpressions().add(elementExpr);
    }
    return jsTypeArray;
  }

  private JsArrayLiteral generateTypeArrayFromParameters(List<DartParameter> params,
      ClassElement classElement, JsExpression typeArgContextExpr) {
    JsArrayLiteral jsTypeArray = new JsArrayLiteral();
    for (DartParameter param : params) {
      Type paramType = param.getTypeNode() == null ? null : param.getTypeNode().getType();
      JsInvocation elementInvoke = generateRTTLookupForType(param.getSymbol(), paramType, classElement,
          typeArgContextExpr);
      jsTypeArray.getExpressions().add(elementInvoke);
    }
    return jsTypeArray;
  }

  private JsArrayLiteral generateTypeArrayFromElements(List<VariableElement> elements,
      ClassElement classElement, JsExpression typeArgContextExpr) {
    JsArrayLiteral jsTypeArray = new JsArrayLiteral();
    for (VariableElement element : elements) {
      JsExpression rttTypeExpression = generateRTTLookupForType(element, element.getType(),
          classElement, typeArgContextExpr);
      jsTypeArray.getExpressions().add(rttTypeExpression);
    }
    return jsTypeArray;
  }

  private JsInvocation generateRTTLookupForType(Element element, Type elementType,
      ClassElement classElement, JsExpression typeArgContextExpr) {
    return generateRTTLookupForType(element, elementType, classElement, typeArgContextExpr,
        element.getModifiers().isNamed() ? element.getName() : null);
  }

  private JsInvocation generateRTTLookupForType(Element element, Type elementType,
      ClassElement classElement, JsExpression typeArgContextExpr, String named) {
    JsInvocation elementInvoke = null;
    switch (TypeKind.of(elementType)) {
      case VARIABLE:
        elementInvoke = buildTypeLookupExpression(elementType, classElement.getTypeParameters(),
            typeArgContextExpr);
        break;
      case INTERFACE:
        elementInvoke = generateRTTLookup((ClassElement) elementType.getElement(),
            (InterfaceType) elementType, classElement);
        break;
      case FUNCTION:
        elementInvoke = generateRTTCreate((VariableElement) element, classElement);
        break;
      case FUNCTION_ALIAS:
        elementInvoke = buildTypeLookupExpression(elementType,
            classElement != null ? classElement.getTypeParameters() : null, typeArgContextExpr);
        break;
      case DYNAMIC:
      case VOID:
      case NONE:
        elementInvoke = newInvocation(newQualifiedNameRef(RTT_DYNAMIC_LOOKUP));
        break;
      default:
        elementInvoke = buildTypeLookupExpression(elementType, classElement.getTypeParameters(),
            typeArgContextExpr);
        break;
    }
    if (named != null) {
      if (elementInvoke.getArguments().size() == 0) {
        elementInvoke.getArguments().add(translationContext.getProgram().getNullLiteral());
      }
      elementInvoke.getArguments().add(
          translationContext.getProgram().getStringLiteral(named));
    }
    assert elementInvoke != null;
    return elementInvoke;
  }

  private JsName getJsName(Symbol symbol) {
    return translationContext.getNames().getName(symbol);
  }

  /*
   * This function will create a lookup function that indirectly calls RTT.createFunction with
   * and array of parameter types and the return type as arguments. Example:
   *   Dart:
   *     typedef List<K> TestAliasType<K>(int x, K k);
   *   JS:
   *     <libraryname>$<TestAliasType>$Dart.$lookupRTT = function(typeArgs){
   *       return RTT.createFunction(
   *         [int$Dart.$lookupRTT(), RTT.getTypeArg(typeArgs, 0)],
   *         List$Dart.$lookupRTT([RTT.getTypeArg(typeArgs, 0)]));
   *     }
   */
  private void generateRTTLookupMethod(DartFunctionTypeAlias x) {
    FunctionAliasElementImplementation classElement =
        (FunctionAliasElementImplementation) x.getSymbol();
    FunctionType funcType = classElement.getFunctionType();

    // Build the function
    JsFunction lookupFn = new JsFunction(globalScope);
    lookupFn.setBody(new JsBlock());
    List<JsStatement> body = lookupFn.getBody().getStatements();
    JsScope scope = new JsScope(globalScope, "temp");
    JsProgram program = translationContext.getProgram();
    JsInvocation invokeCreate = call(null, newQualifiedNameRef("RTT.createFunction"));
    List<JsExpression> callArgs = invokeCreate.getArguments();

    JsName typeArgs = scope.declareName("typeArgs");
    JsExpression typeArgsExpr = new JsNameRef("typeArgs");
    lookupFn.getParameters().add(new JsParameter(typeArgs));

    JsArrayLiteral arr = generateTypeArrayFromParameters(x.getParameters(), classElement,
        typeArgsExpr);
    callArgs.add(arr.getExpressions().isEmpty() ? program.getNullLiteral() : arr);

    JsExpression returnExpr = generateRTTLookupForType(funcType.getElement(),
        funcType.getReturnType(), classElement, typeArgsExpr);
    callArgs.add(returnExpr);

    JsName named = scope.declareName(RTT_NAMED_PARAMETER);
    lookupFn.getParameters().add(new JsParameter(named));
    callArgs.add(named.makeRef());

    body.add(new JsReturn(invokeCreate));

    // Finally, Add the function to the global block of statements.
    JsExpression fnDecl = assign(null, getRTTLookupMethodNameRef(classElement), lookupFn);
    globalBlock.getStatements().add(fnDecl.makeStmt());
  }

  static JsExpression getRTTClassId(TranslationContext translationContext,
                                    ClassElement classElement) {
    JsName classJsName = translationContext.getNames().getName(classElement);
    JsProgram program = translationContext.getProgram();
    JsStringLiteral clsid = program.getStringLiteral(classJsName.getShortIdent());
    return call(null, nameref(null, "$cls"), clsid);
  }

  JsExpression getRTTClassId(ClassElement classElement) {
    return getRTTClassId(translationContext, classElement);
  }

  private JsNameRef getRTTLookupMethodNameRef(ClassElement classElement) {
    return nameref(null, translationContext.getNames().getName(classElement), "$lookupRTT");
  }

  public JsNameRef getRTTLookupMethodNameRef(MethodElement methodElement) {
    JsNameRef methodToCall;

    if (ElementKind.of(methodElement.getEnclosingElement()) == ElementKind.CLASS) {
      JsNameRef classJsNameRef = getJsName(methodElement.getEnclosingElement()).makeRef();
      String mangledMethodName = mangler.mangleRttLookupMethod(methodElement, unitLibrary);
      if (methodElement.getModifiers().isStatic()) {
        methodToCall = AstUtil.newNameRef(classJsNameRef, mangledMethodName);
      } else {
        JsNameRef prototypeRef = AstUtil.newPrototypeNameRef(classJsNameRef);
        methodToCall = AstUtil.newNameRef(prototypeRef, mangledMethodName);
      }
    } else {
      // Top level method
      methodToCall = AstUtil.newQualifiedNameRef(mangler.mangleRttLookupMethod(methodElement,
          unitLibrary));
    }
    return methodToCall;
  }

  private JsNameRef getRTTImplementsMethodName(ClassElement classElement) {
    return nameref(null, translationContext.getNames().getName(classElement), "$RTTimplements");
  }

  private JsNameRef getRTTAddToMethodName(ClassElement classElement) {
    return nameref(null, translationContext.getNames().getName(classElement), "$addTo");
  }

  /**
   * Build a class relative type arguments expression
   * @param classElement The class whose type arguments to refer to.
   */
  private JsExpression buildTypeArgsReference(ClassElement classElement) {
    JsExpression typeArgs;
    if (inFactory()) {
      if (classElement.getTypeParameters().isEmpty()) {
        typeArgs = new JsArrayLiteral();
      } else {
        typeArgs = new JsNameRef("$typeArgs");
      }
    } else {
      // build: $getTypeArgsFor(this, 'class')
      // Here build a reference to the type parameter for this class instance, this needs
      // be looked up on a per-class basis.
      typeArgs = call(null,
                      newQualifiedNameRef(
                          "RTT.getTypeArgsFor"), new JsThisRef(), getRTTClassId(classElement));
    }
    return typeArgs;
  }

  private JsExpression buildFactoryTypeInfoReference() {
    // There is no inheritence involved with generic factory methods,
    // so we simply use a hard reference to the type info parameter to the
    // factory.
    return nameref(null, "$typeArgs");
  }

  /**
   * @return a JsArrayLiteral listing the type arguments for the interface instance.
   */
  private JsExpression buildTypeArgs(
      InterfaceType instanceType,
      List<? extends Type> listTypeVars,
      JsExpression contextTypeArgs) {
    ClassElement classElement = instanceType.getElement();
    if (!hasTypeParameters(classElement)) {
      return null;
    }

    if (instanceType.hasDynamicTypeArgs()) {
      JsProgram program = translationContext.getProgram();
      return program.getNullLiteral();
    }

    JsArrayLiteral arr = new JsArrayLiteral();
    assert instanceType.getArguments().size() > 0;
    for (Type type : instanceType.getArguments()) {
      JsExpression typeExpr = buildTypeLookupExpression(
          type, listTypeVars, contextTypeArgs);
      arr.getExpressions().add(typeExpr);
    }

    return arr;
  }

  /**
   * @return a JsArrayLiteral listing the type arguments for the interface instance.
   */
  private JsExpression buildTypeArgsForFactory(
      FunctionType functionType,
      InterfaceType instanceType,
      List<? extends Type> listTypeVars,
      JsExpression contextTypeArgs) {
    if (instanceType.getElement().getTypeParameters().size() == 0) {
      return null;
    }

    if (instanceType.hasDynamicTypeArgs()) {
      return translationContext.getProgram().getNullLiteral();
    }

    JsArrayLiteral arr = new JsArrayLiteral();
    for (Type type : instanceType.getArguments()) {
      JsExpression typeExpr = buildTypeLookupExpression(
          type, listTypeVars, contextTypeArgs);
      arr.getExpressions().add(typeExpr);
    }

    return arr;
  }

  /**
   * @return an expression for looking up the RTT information for the given RAW type.
   */
  private JsExpression generateRawRTTLookup(ClassElement classElement) {
    JsInvocation invokeLookup = call(null, getRTTLookupMethodNameRef(classElement));
    return invokeLookup;
  }

  private JsExpression generateRTTLookup(
      InterfaceType instanceType, ClassElement contextClassElement) {
    return generateRTTLookup(instanceType.getElement(), instanceType, contextClassElement);
  }

  private JsInvocation generateRTTLookup(
      ClassElement classElement, InterfaceType instanceType, ClassElement contextClassElement) {
    JsInvocation invokeLookup = call(null, getRTTLookupMethodNameRef(classElement));
    if (hasTypeParameters(instanceType.getElement()) && !instanceType.hasDynamicTypeArgs()) {
      JsExpression typeArgs = generateTypeArgsArray(instanceType, contextClassElement);
      assert typeArgs != null;
      invokeLookup.getArguments().add(typeArgs);
    }
    return invokeLookup;
  }

  private JsExpression generateTypeArgsArray(
      InterfaceType instanceType, ClassElement contextClassElement) {
    JsExpression typeArgs;
    if (inStaticNotFactory(contextClassElement)) {
      if( ElementKind.of(contextClassElement) == ElementKind.FUNCTION_TYPE_ALIAS) {
        // Special case for FunctionAlias as they can have generic types.
        typeArgs = buildTypeArgs(instanceType, contextClassElement.getTypeParameters(),
                                 new JsNameRef("typeArgs"));
      } else {
        typeArgs = buildTypeArgs(instanceType, null, null);
      }
    } else {
      // Build type args in a class context:
      // When building a type list in a class instance, type variables are
      // resolved from the runtime type information on the instance of the object.
      JsExpression typeArgContextExpr = buildTypeArgsReference(contextClassElement);
      typeArgs = buildTypeArgs(
          instanceType,
          contextClassElement.getTypeParameters(),
          typeArgContextExpr);
    }
    return typeArgs;
  }

  private JsExpression generateTypeArgsArrayForFactory(FunctionType functionType,
                                             InterfaceType instanceType,
                                             ClassElement contextClassElement) {
    JsExpression typeArgs;
    if (inStaticNotFactory(contextClassElement)) {
      typeArgs = buildTypeArgsForFactory(functionType, instanceType, null, null);
    } else {
      // Build type args in a class context:
      // When building a type list in a class instance, type variables are
      // resolved from the runtime type information on the instance of the
      // object.
      JsExpression typeArgContextExpr = buildTypeArgsReference(contextClassElement);
      typeArgs = buildTypeArgsForFactory(functionType, instanceType, contextClassElement
          .getTypeParameters(), typeArgContextExpr);
    }
    return typeArgs;
  }

  /**
   * @param classElement
   * @return Whether the class has type parameters.
   */
  private boolean hasTypeParameters(ClassElement classElement) {
    return classElement.getTypeParameters().size() > 0;
  }

  private boolean hasRTTImplements(ClassElement classElement) {
    InterfaceType superType = classElement.getSupertype();
    return ((superType != null
             && !superType.getElement().isObject())
        || !classElement.getInterfaces().isEmpty());
  }

  /**
   * @return js The expression used to lookup the RTT for the given type.
   */
  private JsInvocation buildTypeLookupExpression(
      Type type, List<? extends Type> list, JsExpression contextTypeArgs) {
    switch (TypeKind.of(type)) {
      case INTERFACE:
      case FUNCTION_ALIAS:
        InterfaceType interfaceType = (InterfaceType) type;
        JsInvocation callLookup = call(null,
            getRTTLookupMethodNameRef(interfaceType.getElement()));
        if (hasTypeParameters(interfaceType.getElement()) && !interfaceType.hasDynamicTypeArgs()) {
          JsArrayLiteral typeArgs = new JsArrayLiteral();
          for (Type arg : interfaceType.getArguments()) {
            typeArgs.getExpressions().add(buildTypeLookupExpression(arg, list, contextTypeArgs));
          }
          callLookup.getArguments().add(typeArgs);
        }
        return callLookup;

      case FUNCTION:
        FunctionType functionType = (FunctionType) type;
        JsInvocation functionTypeCallLookup = call(null,
            getRTTLookupMethodNameRef(functionType.getElement()));
        if (hasTypeParameters(functionType.getElement())) {
          JsArrayLiteral typeArgs = new JsArrayLiteral();
          functionTypeCallLookup.getArguments().add(typeArgs);
        }
        return functionTypeCallLookup;

      case VARIABLE:
        TypeVariable var = (TypeVariable)type;
        JsProgram program = translationContext.getProgram();
        int varIndex = 0;
        for (Type t : list) {
          if (t.equals(type)) {
            return call(null, newQualifiedNameRef("RTT.getTypeArg"),
                        Cloner.clone(contextTypeArgs),
                        program.getNumberLiteral(varIndex));
          }
          varIndex++;
        }
        throw new AssertionError("unresolved type variable:" + var);

      default:
        throw new AssertionError("unexpected type kind:" + type.getKind());
    }
  }

  /**
   * Add the appropriate code to a class's constructing factory, if necessary.
   */
  void maybeAddClassRuntimeTypeToConstructor(
      ClassElement classElement, JsFunction factory, JsExpression thisRef) {
    // TODO(johnlenz):in optimized mode, only add this where it is needed.
    JsScope factoryScope = factory.getScope();
    JsExpression typeInfo;
    if (hasTypeParameters(classElement)) {
      JsName typeinfoParameter = factoryScope.declareName("$rtt");
      factory.getParameters().add(0, new JsParameter(typeinfoParameter));
      typeInfo = typeinfoParameter.makeRef();
    } else {
      // TODO(johnlenz): this is a constant value, it only needs to be evaluated once.
      typeInfo = generateRawRTTLookup(classElement);
    }
    JsExpression setTypeInfo = assign(null,
        nameref(null, Cloner.clone(thisRef), "$typeInfo"), typeInfo);
    factory.getBody().getStatements().add(0, setTypeInfo.makeStmt());
  }

  /**
   * Add a type arguments parameter to a factory method, if necessary.
   */
  void maybeAddTypeParameterToFactory(DartMethodDefinition method, JsFunction factory) {
    // TODO(johnlenz):in optimized mode, only add this where it is needed.
    if (isParameterizedFactoryMethod(method)) {
      JsScope scope = factory.getScope();
      JsName typeArgs = scope.declareName("$typeArgs");
      factory.getParameters().add(0, new JsParameter(typeArgs));
    }
  }

  private boolean isParameterizedFactoryMethod(DartMethodDefinition method) {
    assert method.getModifiers().isFactory();
    Element enclosingElement = method.getSymbol().getEnclosingElement();
    if (ElementKind.of(enclosingElement).equals(ElementKind.CLASS)) {
      ClassElement enclosingClass = (ClassElement) enclosingElement;
      return !enclosingClass.getTypeParameters().isEmpty();
    }
    return false;
  }

  /**
   * Add a runtime type information to a array literal, if necessary.
   */
  JsExpression maybeAddRuntimeTypeForArrayLiteral(ClassElement enclosingClass,
      DartArrayLiteral x, JsArrayLiteral jsArray) {
    // TODO(johnlenz):in optimized mode, only add this where it is needed.
    InterfaceType instanceType = typeProvider.getArrayLiteralType(
        x.getType().getArguments().get(0));
    JsExpression rtt = generateRTTLookup(instanceType, enclosingClass);
    // Bind the runtime type information to the native array expression
    return call(x, newQualifiedNameRef("RTT.setTypeInfo"), jsArray, rtt);
  }

  /**
   * Add a runtime type information to a map literal, if necessary.
   */
  void maybeAddRuntimeTypeToMapLiteralConstructor(ClassElement enclosingClass,
      DartMapLiteral x, JsInvocation invoke) {
    // TODO(johnlenz):in optimized mode, only add this where it is needed.

    // Fixup the type for map literal type to be the implementing type.
    List<? extends Type> typeArgs = x.getType().getArguments();
    InterfaceType instanceType = typeProvider.getMapLiteralType(
        typeArgs.get(0), typeArgs.get(1));
    JsExpression rtt = generateRTTLookup(instanceType, enclosingClass);
    invoke.getArguments().add(rtt);
  }

  /**
   * Add runtime type information to a "new" expression, if necessary.
   */
  void mayAddRuntimeTypeToConstrutorOrFactoryCall(
      ClassElement enclosingClass, DartNewExpression x, JsInvocation invoke) {
    // TODO(johnlenz):in optimized mode, only add this where it is needed.

    InterfaceType instanceType = Types.constructorType(x);
    if (instanceType == null) {
      // TODO(johnlenz): HackHack. Currently the "new FallThroughError" injected by the
      // Normalizer does not have the instance type attached. But in this
      // case we know it does not have any type parameters.
      // reportError(x.getParent().getParent(), new AssertionError("missing type information"));
      assert typeProvider.getFallThroughError().getElement().lookupConstructor("").equals(
          x.getSymbol());
    } else if (constructorHasTypeParameters(x)) {
      ConstructorElement constructor = x.getSymbol();
      ClassElement containingClassElement = enclosingClass;
      if (constructor.getModifiers().isFactory()) {
        // We are calling a factory, this is either in a class
        FunctionType functionType = (FunctionType) constructor.getType();
        JsExpression typeArgs = generateTypeArgsArrayForFactory(
            functionType, instanceType, containingClassElement);
        assert typeArgs != null;
        invoke.getArguments().add(0, typeArgs);
      } else {
        ClassElement constructorClassElement = constructor.getConstructorType();
        invoke.getArguments().add(0,
            generateRTTLookup(constructorClassElement, instanceType, containingClassElement));
      }
    }
  }

  private boolean constructorHasTypeParameters(DartNewExpression x) {
    ConstructorElement element = x.getSymbol();
    if (element.getModifiers().isFactory()) {
      return isParameterizedFactoryMethod((DartMethodDefinition)element.getNode());
    } else {
      InterfaceType instanceType = Types.constructorType(x);
      return hasTypeParameters(instanceType.getElement());
    }
  }

  /**
   * @return an expression that implements a runtime "is" operation
   */
  JsExpression generateInstanceOfComparison(
      ClassElement enclosingClass,
      JsExpression lhs,
      DartTypeNode typeNode,
      SourceInfo src) {
    ClassElement currentClass = enclosingClass;
    Type type = typeNode.getType();
    switch (TypeKind.of(type)) {
      case INTERFACE:
        InterfaceType interfaceType = (InterfaceType) type;
        if (hasTypeParameters(interfaceType.getElement())
            && !interfaceType.hasDynamicTypeArgs()) {
          return generateRefiedInterfaceTypeComparison(lhs, interfaceType, currentClass, src);
        } else {
          // TODO(johnlenz): special case "is Object"?
          return generateRawInterfaceTypeComparison(lhs, typeNode, src);
        }
      case VARIABLE:
        TypeVariable typeVar = (TypeVariable) type;
        return generateRefiedTypeVariableComparison(lhs, typeVar, currentClass, src);
      case DYNAMIC:
        JsProgram program = translationContext.getProgram();
        return program.getTrueLiteral();
      case FUNCTION_ALIAS:
        FunctionAliasType aliasType = (FunctionAliasType) type;
        return generateRefiedInterfaceTypeComparison(lhs, aliasType, currentClass, src);
      default:
        throw new IllegalStateException("unexpected");
    }
  }

  private JsExpression generateRefiedInterfaceTypeComparison(
      JsExpression lhs, InterfaceType type, ClassElement contextClassElement, SourceInfo src) {
    JsExpression rtt = generateRTTLookup(type, contextClassElement);
    return call(src, nameref(src, rtt, "implementedBy"), lhs);
  }

  private JsExpression getReifiedTypeVariableRTT(TypeVariable type, ClassElement contextClassElement) {
    JsExpression rttContext;
    if (!inFactory()) {
      // build: this.typeinfo.implementedTypes['class'].typeArgs;
      rttContext = buildTypeArgsReference(contextClassElement);
    } else {
      // build: $typeArgs
      rttContext = buildFactoryTypeInfoReference();
    }
    // rtt = rttContext.typeArgs[x]
    JsExpression rtt = buildTypeLookupExpression(type, contextClassElement.getTypeParameters(), rttContext);
    return rtt;
  }

  private JsExpression generateRefiedTypeVariableComparison(
      JsExpression lhs, TypeVariable type,  ClassElement contextClassElement, SourceInfo src) {
    JsExpression rtt = getReifiedTypeVariableRTT(type, contextClassElement);
    return call(src, nameref(src, rtt, "implementedBy"), lhs);
  }

  private JsExpression generateRawInterfaceTypeComparison(
      JsExpression lhs, DartTypeNode typeNode,
      SourceInfo src) {
    ClassElement element = (ClassElement) typeNode.getType().getElement();
    if (element.equals(typeProvider.getObjectType().getElement())) {
      // Everything is an object, including null
      return this.translationContext.getProgram().getTrueLiteral();
    }
    String builtin = builtInTypeChecks.get(element);
    if (builtin != null) {
      return call(src, nameref(src, builtin), lhs);
    }

    // Due to implementing implied interfaces of classes, we always have to
    // use $implements$ rather than using JS instanceof for classes.

    // Inject: !!(tmp = target, tmp && tmp.$implements$type)
    JsProgram program = translationContext.getProgram();
    JsName tmp = context.createTemporary();
    String mangledClass = translationContext.getMangler().mangleClassName(element);
    return not(src,
               not(src,
                  comma(src,
                      assign(src, tmp.makeRef(), lhs),
                      and(src,
                          neq(src, tmp.makeRef().setSourceRef(src), program.getNullLiteral()),
                          nameref(src,
                              tmp,
                              "$implements$" + mangledClass)))));
  }

  private boolean inFactory() {
    DartClassMember<?> member = context.getCurrentClassMember();
    return member != null && member.getModifiers().isFactory();
  }

  private boolean inStaticNotFactory(ClassElement containingClass) {
    return !inFactory() && inStatic(containingClass);
  }

  private boolean inStatic(ClassElement containingClass) {
    DartClassMember<?> member = context.getCurrentClassMember();
    return containingClass == null
        || containingClass.getKind() != ElementKind.CLASS
        || member == null
        || member.getModifiers().isStatic();
  }


  /**
   * Optionally emit a runtime type check, which is a call to $chk passing the
   * runtime type object for the required type and an expression.
   *
   * @param enclosingClass enclosing class element
   * @param expr expression to check
   * @param type {@link Type} to check against, null is unknown
   * @param src source info to use for the generated code
   * @return an expression wrapping the type check call
   */
  JsExpression addTypeCheck(ClassElement enclosingClass, JsExpression expr, Type type,
      Type exprType, SourceInfo src) {
    if (!emitTypeChecks || isStaticallyGoodAssignment(type, exprType)) {
      return expr;
    }
    if (isStaticallyBadAssignment(type, exprType, expr)) {
      return injectTypeError(enclosingClass, expr, type, src);
    }
    return injectTypeCheck(enclosingClass, expr, type, src);
  }

  /**
   * Check if an assignment is statically known to have a type error.
   *
   * @param type type of assignment target
   * @param exprType type of value being assigned
   * @param expr
   * @return true if the assignment is known to be bad statically
   */
  private boolean isStaticallyBadAssignment(Type type, Type exprType, JsExpression expr) {
    if (!expr.isDefinitelyNotNull() || type == null || exprType == null
          || type.getKind() == TypeKind.DYNAMIC || exprType.getKind() == TypeKind.DYNAMIC) {
      // nulls can be assigned to any type, and if either is dynamic we can't
      // reject it
      return false;
    }
    return !types.isAssignable(type, exprType);
  }

  /**
   * @param type
   * @param exprType
   * @return true if the assignment is statically known to not need a check
   */
  private boolean isStaticallyGoodAssignment(Type type, Type exprType) {
    if (type == null || type.getKind() == TypeKind.DYNAMIC) {
      // if there is no target type or it is dynamic, it is good
      return true;
    }
    if (exprType == null || exprType.getKind() == TypeKind.DYNAMIC) {
      // otherwise, if the source type is unknown or dynamic, we need a check
      return false;
    }
    return types.isAssignable(type, exprType);
  }

  /**
   * Optionally emit a type error, used when it is statically known that a
   * TypeError must be thrown.
   *
   * @param enclosingClass enclosing class element
   * @param expr expression that fails the check
   * @param type type to check against, null is unknown
   * @param src source info to use for the generated code
   * @return an expression wrapping the call to the throw helper
   */
  private JsExpression injectTypeError(ClassElement enclosingClass, JsExpression expr, Type type,
      SourceInfo src) {
    JsExpression rtt = getRtt(enclosingClass, expr, type);
    if (rtt != null) {
      expr = call(src, nameref(src, "$te"), rtt, expr);
    }
    return expr;
  }

  /**
   * Optionally emit a runtime type check, which is a call to $chk passing the
   * runtime type object for the required type and an expression.
   *
   * @param enclosingClass enclosing class element
   * @param expr expression to check
   * @param type type to check against, null is unknown
   * @param src source info to use for the generated code
   * @return an expression wrapping the type check call
   */
  private JsExpression injectTypeCheck(ClassElement enclosingClass, JsExpression expr, Type type,
      SourceInfo src) {
    JsExpression rtt = getRtt(enclosingClass, expr, type);
    if (rtt != null) {
      expr = call(src, nameref(src, "$chk"), rtt, expr);
    }
    return expr;
  }

  /**
   * Get the runtime type object for a type.
   *
   * @param enclosingClass
   * @param expr
   * @param type
   * @return a {@link JsExpression} for the runtime type, or null if no check is required/possible
   */
  private JsExpression getRtt(ClassElement enclosingClass, JsExpression expr, Type type) {
    if (!emitTypeChecks || type == null) {
      return null;
    }
    JsExpression rtt;
    switch (TypeKind.of(type)) {
      case INTERFACE:
        InterfaceType interfaceType = (InterfaceType) type;
        // TODO: do we need a special case for raw interfaces?
        return generateRTTLookup(interfaceType, enclosingClass);
      case VARIABLE:
        TypeVariable typeVar = (TypeVariable) type;
        return getReifiedTypeVariableRTT(typeVar, enclosingClass);
      case FUNCTION:
        // TODO: We need a more detailed RTT than just a generic function.
        return generateRTTLookup(typeProvider.getFunctionType(), enclosingClass);
      case VOID:
      case FUNCTION_ALIAS:
        // TODO: implement, no checks for now
      case DYNAMIC:
        // no check required
        return null;
      default:
        throw new IllegalStateException("unexpected type " + type);
    }
  }
}
