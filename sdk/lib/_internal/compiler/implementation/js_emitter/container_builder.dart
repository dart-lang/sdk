// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

/// This class should morph into something that makes it easy to build
/// JavaScript representations of libraries, class-sides, and instance-sides.
/// Initially, it is just a placeholder for code that is moved from
/// [CodeEmitterTask].
class ContainerBuilder extends CodeEmitterHelper {
  final Map<Element, Element> staticGetters = new Map<Element, Element>();

  /// A cache of synthesized closures for top-level, static or
  /// instance methods.
  final Map<String, Element> methodClosures = <String, Element>{};

  /**
   * Generate stubs to handle invocation of methods with optional
   * arguments.
   *
   * A method like [: foo([x]) :] may be invoked by the following
   * calls: [: foo(), foo(1), foo(x: 1) :]. See the sources of this
   * function for detailed examples.
   */
  void addParameterStub(FunctionElement member,
                        Selector selector,
                        DefineStubFunction defineStub,
                        Set<String> alreadyGenerated) {
    FunctionSignature parameters = member.computeSignature(compiler);
    int positionalArgumentCount = selector.positionalArgumentCount;
    if (positionalArgumentCount == parameters.parameterCount) {
      assert(selector.namedArgumentCount == 0);
      return;
    }
    if (parameters.optionalParametersAreNamed
        && selector.namedArgumentCount == parameters.optionalParameterCount) {
      // If the selector has the same number of named arguments as the element,
      // we don't need to add a stub. The call site will hit the method
      // directly.
      return;
    }
    ConstantHandler handler = compiler.constantHandler;
    List<String> names = selector.getOrderedNamedArguments();

    String invocationName = namer.invocationName(selector);
    if (alreadyGenerated.contains(invocationName)) return;
    alreadyGenerated.add(invocationName);

    bool isInterceptedMethod = backend.isInterceptedMethod(member);

    // If the method is intercepted, we need to also pass the actual receiver.
    int extraArgumentCount = isInterceptedMethod ? 1 : 0;
    // Use '$receiver' to avoid clashes with other parameter names. Using
    // '$receiver' works because [:namer.safeName:] used for getting parameter
    // names never returns a name beginning with a single '$'.
    String receiverArgumentName = r'$receiver';

    // The parameters that this stub takes.
    List<jsAst.Parameter> parametersBuffer =
        new List<jsAst.Parameter>(selector.argumentCount + extraArgumentCount);
    // The arguments that will be passed to the real method.
    List<jsAst.Expression> argumentsBuffer =
        new List<jsAst.Expression>(
            parameters.parameterCount + extraArgumentCount);

    int count = 0;
    if (isInterceptedMethod) {
      count++;
      parametersBuffer[0] = new jsAst.Parameter(receiverArgumentName);
      argumentsBuffer[0] = js(receiverArgumentName);
      task.interceptorEmitter.interceptorInvocationNames.add(invocationName);
    }

    int optionalParameterStart = positionalArgumentCount + extraArgumentCount;
    // Includes extra receiver argument when using interceptor convention
    int indexOfLastOptionalArgumentInParameters = optionalParameterStart - 1;

    TreeElements elements =
        compiler.enqueuer.resolution.getCachedElements(member);

    int parameterIndex = 0;
    parameters.orderedForEachParameter((Element element) {
      // Use generic names for closures to facilitate code sharing.
      String jsName = member is ClosureInvocationElement
          ? 'p${parameterIndex++}'
          : backend.namer.safeName(element.name);
      assert(jsName != receiverArgumentName);
      if (count < optionalParameterStart) {
        parametersBuffer[count] = new jsAst.Parameter(jsName);
        argumentsBuffer[count] = js(jsName);
      } else {
        int index = names.indexOf(element.name);
        if (index != -1) {
          indexOfLastOptionalArgumentInParameters = count;
          // The order of the named arguments is not the same as the
          // one in the real method (which is in Dart source order).
          argumentsBuffer[count] = js(jsName);
          parametersBuffer[optionalParameterStart + index] =
              new jsAst.Parameter(jsName);
        } else {
          Constant value = handler.initialVariableValues[element];
          if (value == null) {
            argumentsBuffer[count] = task.constantReference(new NullConstant());
          } else {
            if (!value.isNull()) {
              // If the value is the null constant, we should not pass it
              // down to the native method.
              indexOfLastOptionalArgumentInParameters = count;
            }
            argumentsBuffer[count] = task.constantReference(value);
          }
        }
      }
      count++;
    });

    List body;
    if (member.hasFixedBackendName()) {
      body = task.nativeEmitter.generateParameterStubStatements(
          member, isInterceptedMethod, invocationName,
          parametersBuffer, argumentsBuffer,
          indexOfLastOptionalArgumentInParameters);
    } else {
      body = [js.return_(
          js('this')[namer.getNameOfInstanceMember(member)](argumentsBuffer))];
    }

    jsAst.Fun function = js.fun(parametersBuffer, body);

    defineStub(invocationName, function);

    String reflectionName = task.getReflectionName(selector, invocationName);
    if (reflectionName != null) {
      var reflectable =
          js(backend.isAccessibleByReflection(member) ? '1' : '0');
      defineStub('+$reflectionName', reflectable);
    }
  }

  void addParameterStubs(FunctionElement member,
                         DefineStubFunction defineStub) {
    // We fill the lists depending on the selector. For example,
    // take method foo:
    //    foo(a, b, {c, d});
    //
    // We may have multiple ways of calling foo:
    // (1) foo(1, 2);
    // (2) foo(1, 2, c: 3);
    // (3) foo(1, 2, d: 4);
    // (4) foo(1, 2, c: 3, d: 4);
    // (5) foo(1, 2, d: 4, c: 3);
    //
    // What we generate at the call sites are:
    // (1) foo$2(1, 2);
    // (2) foo$3$c(1, 2, 3);
    // (3) foo$3$d(1, 2, 4);
    // (4) foo$4$c$d(1, 2, 3, 4);
    // (5) foo$4$c$d(1, 2, 3, 4);
    //
    // The stubs we generate are (expressed in Dart):
    // (1) foo$2(a, b) => foo$4$c$d(a, b, null, null)
    // (2) foo$3$c(a, b, c) => foo$4$c$d(a, b, c, null);
    // (3) foo$3$d(a, b, d) => foo$4$c$d(a, b, null, d);
    // (4) No stub generated, call is direct.
    // (5) No stub generated, call is direct.

    // Keep a cache of which stubs have already been generated, to
    // avoid duplicates. Note that even if selectors are
    // canonicalized, we would still need this cache: a typed selector
    // on A and a typed selector on B could yield the same stub.
    Set<String> generatedStubNames = new Set<String>();
    bool isClosureInvocation =
        member.name == namer.closureInvocationSelectorName;
    if (backend.isNeededForReflection(member) ||
        (compiler.enabledFunctionApply && isClosureInvocation)) {
      // If [Function.apply] is called, we pessimistically compile all
      // possible stubs for this closure.
      FunctionSignature signature = member.computeSignature(compiler);
      Set<Selector> selectors = signature.optionalParametersAreNamed
          ? computeSeenNamedSelectors(member)
          : computeOptionalSelectors(signature, member);
      for (Selector selector in selectors) {
        addParameterStub(member, selector, defineStub, generatedStubNames);
      }
      if (signature.optionalParametersAreNamed && isClosureInvocation) {
        addCatchAllParameterStub(member, signature, defineStub);
      }
    } else {
      Set<Selector> selectors = compiler.codegenWorld.invokedNames[member.name];
      if (selectors == null) return;
      for (Selector selector in selectors) {
        if (!selector.applies(member, compiler)) continue;
        addParameterStub(member, selector, defineStub, generatedStubNames);
      }
    }
  }

  Set<Selector> computeSeenNamedSelectors(FunctionElement element) {
    Set<Selector> selectors = compiler.codegenWorld.invokedNames[element.name];
    Set<Selector> result = new Set<Selector>();
    if (selectors == null) return result;
    for (Selector selector in selectors) {
      if (!selector.applies(element, compiler)) continue;
      result.add(selector);
    }
    return result;
  }

  void addCatchAllParameterStub(FunctionElement member,
                                FunctionSignature signature,
                                DefineStubFunction defineStub) {
    // See Primities.applyFunction in js_helper.dart for details.
    List<jsAst.Property> properties = <jsAst.Property>[];
    for (Element element in signature.orderedOptionalParameters) {
      String jsName = backend.namer.safeName(element.name);
      Constant value = compiler.constantHandler.initialVariableValues[element];
      jsAst.Expression reference = null;
      if (value == null) {
        reference = new jsAst.LiteralNull();
      } else {
        reference = task.constantReference(value);
      }
      properties.add(new jsAst.Property(js.string(jsName), reference));
    }
    defineStub(
        backend.namer.callCatchAllName,
        js.fun([], js.return_(new jsAst.ObjectInitializer(properties))));
  }

  /**
   * Compute the set of possible selectors in the presence of optional
   * non-named parameters.
   */
  Set<Selector> computeOptionalSelectors(FunctionSignature signature,
                                         FunctionElement element) {
    Set<Selector> selectors = new Set<Selector>();
    // Add the selector that does not have any optional argument.
    selectors.add(new Selector(SelectorKind.CALL,
                               element.name,
                               element.getLibrary(),
                               signature.requiredParameterCount,
                               <String>[]));

    // For each optional parameter, we increment the number of passed
    // argument.
    for (int i = 1; i <= signature.optionalParameterCount; i++) {
      selectors.add(new Selector(SelectorKind.CALL,
                                 element.name,
                                 element.getLibrary(),
                                 signature.requiredParameterCount + i,
                                 <String>[]));
    }
    return selectors;
  }

  void emitStaticFunctionGetters(CodeBuffer eagerBuffer) {
    task.addComment('Static function getters', task.mainBuffer);
    for (FunctionElement element in
             Elements.sortedByPosition(staticGetters.keys)) {
      Element closure = staticGetters[element];
      CodeBuffer buffer =
          task.isDeferred(element) ? task.deferredConstants : eagerBuffer;
      String closureClass = namer.isolateAccess(closure);
      String name = namer.getStaticClosureName(element);

      String closureName = namer.getStaticClosureName(element);
      jsAst.Node assignment = js(
          'init.globalFunctions["$closureName"] ='
          ' ${namer.globalObjectFor(element)}.$name ='
          ' new $closureClass(#, "$closureName")',
          namer.elementAccess(element));
      buffer.write(jsAst.prettyPrint(assignment, compiler));
      buffer.write('$N');
    }
  }

  void emitStaticFunctionClosures() {
    Set<FunctionElement> functionsNeedingGetter =
        compiler.codegenWorld.staticFunctionsNeedingGetter;
    for (FunctionElement element in
             Elements.sortedByPosition(functionsNeedingGetter)) {
      String superName = namer.getNameOfClass(compiler.closureClass);
      int parameterCount = element.functionSignature.parameterCount;
      String name = 'Closure\$$parameterCount';
      assert(task.instantiatedClasses.contains(compiler.closureClass));

      ClassElement closureClassElement = new ClosureClassElement(
          null, name, compiler, element,
          element.getCompilationUnit());
      // Now add the methods on the closure class. The instance method does not
      // have the correct name. Since [addParameterStubs] use the name to create
      // its stubs we simply create a fake element with the correct name.
      // Note: the callElement will not have any enclosingElement.
      FunctionElement callElement =
          new ClosureInvocationElement(namer.closureInvocationSelectorName,
                                       element);

      String invocationName = namer.instanceMethodName(callElement);
      String mangledName = namer.getNameOfClass(closureClassElement);

      // Define the constructor with a name so that Object.toString can
      // find the class name of the closure class.
      ClassBuilder closureBuilder = new ClassBuilder();
      // If a static function is used as a closure we need to add its name
      // in case it is used in spawnFunction.
      String methodName = namer.STATIC_CLOSURE_NAME_NAME;
      List<String> fieldNames = <String>[invocationName, methodName];
      closureBuilder.addProperty('',
          js.string("$superName;${fieldNames.join(',')}"));

      addParameterStubs(callElement, closureBuilder.addProperty);

      void emitFunctionTypeSignature(Element method, FunctionType methodType) {
        RuntimeTypes rti = backend.rti;
        // [:() => null:] is dummy encoding of [this] which is never needed for
        // the encoding of the type of the static [method].
        jsAst.Expression encoding =
            rti.getSignatureEncoding(methodType, js('null'));
        String operatorSignature = namer.operatorSignature();
        // TODO(johnniwinther): Make MiniJsParser support function expressions.
        closureBuilder.addProperty(operatorSignature, encoding);
      }

      void emitIsFunctionTypeTest(FunctionType functionType) {
        String operator = namer.operatorIsType(functionType);
        closureBuilder.addProperty(operator, js('true'));
      }

      FunctionType methodType = element.computeType(compiler);
      Map<FunctionType, bool> functionTypeChecks =
          task.typeTestEmitter.getFunctionTypeChecksOn(methodType);
      task.typeTestEmitter.generateFunctionTypeTests(
          element, methodType, functionTypeChecks,
          emitFunctionTypeSignature, emitIsFunctionTypeTest);

      closureClassElement =
          addClosureIfNew(closureBuilder, closureClassElement, fieldNames);
      staticGetters[element] = closureClassElement;

    }
  }

  ClassElement addClosureIfNew(ClassBuilder builder,
                               ClassElement closure,
                               List<String> fieldNames) {
    String key =
        jsAst.prettyPrint(builder.toObjectInitializer(), compiler).getText();
    return methodClosures.putIfAbsent(key, () {
      String mangledName = namer.getNameOfClass(closure);
      emitClosureInPrecompiledFunction(mangledName, fieldNames);
      return closure;
    });
  }

  void emitClosureInPrecompiledFunction(String mangledName,
                                        List<String> fieldNames) {
    List<String> fields = fieldNames;
    String constructorName = mangledName;
    task.precompiledFunction.add(new jsAst.FunctionDeclaration(
        new jsAst.VariableDeclaration(constructorName),
        js.fun(fields, fields.map(
            (name) => js('this.$name = $name')).toList())));
    task.precompiledFunction.addAll([
        js('$constructorName.builtin\$cls = "$constructorName"'),
        js('\$desc=\$collectedClasses.$constructorName'),
        js.if_('\$desc instanceof Array', js('\$desc = \$desc[1]')),
        js('$constructorName.prototype = \$desc'),
    ]);

    task.precompiledConstructorNames.add(js(constructorName));
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [member] must be a declaration element.
   */
  void emitDynamicFunctionGetter(FunctionElement member,
                                 DefineStubFunction defineStub) {
    assert(invariant(member, member.isDeclaration));
    assert(task.instantiatedClasses.contains(compiler.boundClosureClass));
    // For every method that has the same name as a property-get we create a
    // getter that returns a bound closure. Say we have a class 'A' with method
    // 'foo' and somewhere in the code there is a dynamic property get of
    // 'foo'. Then we generate the following code (in pseudo Dart/JavaScript):
    //
    // class A {
    //    foo(x, y, z) { ... } // Original function.
    //    get foo { return new BoundClosure499(this, "foo"); }
    // }
    // class BoundClosure499 extends BoundClosure {
    //   BoundClosure499(this.self, this.name);
    //   $call3(x, y, z) { return self[name](x, y, z); }
    // }

    bool hasOptionalParameters = member.optionalParameterCount(compiler) != 0;
    int parameterCount = member.parameterCount(compiler);

    // Intercepted methods take an extra parameter, which is the
    // receiver of the call.
    bool inInterceptor = backend.isInterceptedMethod(member);
    List<String> fieldNames = <String>[];
    compiler.boundClosureClass.forEachInstanceField((_, Element field) {
      fieldNames.add(namer.getNameOfInstanceMember(field));
    });

    ClassElement classElement = member.getEnclosingClass();
    String name = inInterceptor
        ? 'BoundClosure\$i${parameterCount}'
        : 'BoundClosure\$${parameterCount}';

    ClassElement closureClassElement = new ClosureClassElement(
        null, name, compiler, member,
        member.getCompilationUnit());
    String superName = namer.getNameOfClass(closureClassElement.superclass);

    // Define the constructor with a name so that Object.toString can
    // find the class name of the closure class.
    ClassBuilder boundClosureBuilder = new ClassBuilder();
    boundClosureBuilder.addProperty('',
        js.string("$superName;${fieldNames.join(',')}"));
    // Now add the methods on the closure class. The instance method does not
    // have the correct name. Since [addParameterStubs] use the name to create
    // its stubs we simply create a fake element with the correct name.
    // Note: the callElement will not have any enclosingElement.
    FunctionElement callElement = new ClosureInvocationElement(
        namer.closureInvocationSelectorName, member);

    String invocationName = namer.instanceMethodName(callElement);

    List<String> parameters = <String>[];
    List<jsAst.Expression> arguments =
        <jsAst.Expression>[js('this')[fieldNames[0]]];
    if (inInterceptor) {
      arguments.add(js('this')[fieldNames[2]]);
    }
    for (int i = 0; i < parameterCount; i++) {
      String name = 'p$i';
      parameters.add(name);
      arguments.add(js(name));
    }

    jsAst.Expression fun = js.fun(
        parameters,
        js.return_(
            js('this')[fieldNames[1]]['call'](arguments)));
    boundClosureBuilder.addProperty(invocationName, fun);

    addParameterStubs(callElement, boundClosureBuilder.addProperty);

    void emitFunctionTypeSignature(Element method, FunctionType methodType) {
      jsAst.Expression encoding = backend.rti.getSignatureEncoding(
          methodType, js('this')[fieldNames[0]]);
      String operatorSignature = namer.operatorSignature();
      boundClosureBuilder.addProperty(operatorSignature, encoding);
    }

    void emitIsFunctionTypeTest(FunctionType functionType) {
      String operator = namer.operatorIsType(functionType);
      boundClosureBuilder.addProperty(operator,
          new jsAst.LiteralBool(true));
    }

    DartType memberType = member.computeType(compiler);
    Map<FunctionType, bool> functionTypeChecks =
        task.typeTestEmitter.getFunctionTypeChecksOn(memberType);

    task.typeTestEmitter.generateFunctionTypeTests(
        member, memberType, functionTypeChecks,
        emitFunctionTypeSignature, emitIsFunctionTypeTest);

    closureClassElement =
        addClosureIfNew(boundClosureBuilder, closureClassElement, fieldNames);

    String closureClass = namer.isolateAccess(closureClassElement);

    // And finally the getter.
    String getterName = namer.getterName(member);
    String targetName = namer.instanceMethodName(member);

    parameters = <String>[];
    jsAst.PropertyAccess method =
        backend.namer.elementAccess(classElement)['prototype'][targetName];
    arguments = <jsAst.Expression>[js('this'), method];

    if (inInterceptor) {
      String receiverArg = fieldNames[2];
      parameters.add(receiverArg);
      arguments.add(js(receiverArg));
    } else {
      // Put null in the intercepted receiver field.
      arguments.add(new jsAst.LiteralNull());
    }

    arguments.add(js.string(targetName));

    jsAst.Expression getterFunction = js.fun(
        parameters, js.return_(js(closureClass).newWith(arguments)));

    defineStub(getterName, getterFunction);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [member] must be a declaration element.
   */
  void emitCallStubForGetter(Element member,
                             Set<Selector> selectors,
                             DefineStubFunction defineStub) {
    assert(invariant(member, member.isDeclaration));
    LibraryElement memberLibrary = member.getLibrary();
    // If the method is intercepted, the stub gets the
    // receiver explicitely and we need to pass it to the getter call.
    bool isInterceptedMethod = backend.isInterceptedMethod(member);

    const String receiverArgumentName = r'$receiver';

    jsAst.Expression buildGetter() {
      if (member.isGetter()) {
        String getterName = namer.getterName(member);
        return js('this')[getterName](
            isInterceptedMethod
                ? <jsAst.Expression>[js(receiverArgumentName)]
                : <jsAst.Expression>[]);
      } else {
        String fieldName = member.hasFixedBackendName()
            ? member.fixedBackendName()
            : namer.instanceFieldName(member);
        return js('this')[fieldName];
      }
    }

    // Two selectors may match but differ only in type.  To avoid generating
    // identical stubs for each we track untyped selectors which already have
    // stubs.
    Set<Selector> generatedSelectors = new Set<Selector>();
    for (Selector selector in selectors) {
      if (selector.applies(member, compiler)) {
        selector = selector.asUntyped;
        if (generatedSelectors.contains(selector)) continue;
        generatedSelectors.add(selector);

        String invocationName = namer.invocationName(selector);
        Selector callSelector = new Selector.callClosureFrom(selector);
        String closureCallName = namer.invocationName(callSelector);

        List<jsAst.Parameter> parameters = <jsAst.Parameter>[];
        List<jsAst.Expression> arguments = <jsAst.Expression>[];
        if (isInterceptedMethod) {
          parameters.add(new jsAst.Parameter(receiverArgumentName));
        }

        for (int i = 0; i < selector.argumentCount; i++) {
          String name = 'arg$i';
          parameters.add(new jsAst.Parameter(name));
          arguments.add(js(name));
        }

        jsAst.Fun function = js.fun(
            parameters,
            js.return_(buildGetter()[closureCallName](arguments)));

        defineStub(invocationName, function);
      }
    }
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [member] must be a declaration element.
   */
  void emitExtraAccessors(Element member, ClassBuilder builder) {
    assert(invariant(member, member.isDeclaration));
    if (member.isGetter() || member.isField()) {
      Set<Selector> selectors = compiler.codegenWorld.invokedNames[member.name];
      if (selectors != null && !selectors.isEmpty) {
        emitCallStubForGetter(member, selectors, builder.addProperty);
      }
    } else if (member.isFunction()) {
      if (compiler.codegenWorld.hasInvokedGetter(member, compiler)) {
        emitDynamicFunctionGetter(member, builder.addProperty);
      }
    }
  }

  void addMember(Element member, ClassBuilder builder) {
    assert(invariant(member, member.isDeclaration));

    if (member.isField()) {
      addMemberField(member, builder);
    } else if (member.isFunction() ||
               member.isGenerativeConstructorBody() ||
               member.isGenerativeConstructor() ||
               member.isAccessor()) {
      addMemberMethod(member, builder);
    } else {
      compiler.internalErrorOnElement(
          member, 'unexpected kind: "${member.kind}"');
    }
    if (member.isInstanceMember()) emitExtraAccessors(member, builder);
  }

  void addMemberMethod(FunctionElement member, ClassBuilder builder) {
    if (member.isAbstract(compiler)) return;
    jsAst.Expression code = backend.generatedCode[member];
    if (code == null) return;
    String name = namer.getNameOfMember(member);
    if (backend.isInterceptedMethod(member)) {
      task.interceptorEmitter.interceptorInvocationNames.add(name);
    }
    code = task.metadataEmitter.extendWithMetadata(member, code);
    builder.addProperty(name, code);
    String reflectionName = task.getReflectionName(member, name);
    if (reflectionName != null) {
      var reflectable =
          js(backend.isAccessibleByReflection(member) ? '1' : '0');
      builder.addProperty('+$reflectionName', reflectable);
      jsAst.Node defaultValues =
          task.metadataEmitter.reifyDefaultArguments(member);
      if (defaultValues != null) {
        String unmangledName = member.name;
        builder.addProperty('*$unmangledName', defaultValues);
      }
    }
    if (member.isInstanceMember()) {
      // TODO(ahe): Where is this done for static/top-level methods?
      FunctionSignature parameters = member.computeSignature(compiler);
      if (!parameters.optionalParameters.isEmpty) {
        addParameterStubs(member, builder.addProperty);
      }
    }
  }

  void addMemberField(VariableElement member, ClassBuilder builder) {
    // For now, do nothing.
  }
}
