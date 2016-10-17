// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

// Function signatures used in the generation of runtime type information.
typedef void FunctionTypeSignatureEmitter(
    Element method, FunctionType methodType);

typedef void SubstitutionEmitter(Element element, {bool emitNull});

class TypeTestProperties {
  /// The index of the function type into the metadata.
  ///
  /// If the class doesn't have a function type this field is `null`.
  ///
  /// If the is tests were generated with `storeFunctionTypeInMetadata` set to
  /// `false`, this field is `null`, and the [properties] contain a property
  /// that encodes the function type.
  jsAst.Expression functionTypeIndex;

  /// The properties that must be installed on the prototype of the
  /// JS constructor of the [ClassElement] for which the is checks were
  /// generated.
  final Map<jsAst.Name, jsAst.Node> properties = <jsAst.Name, jsAst.Node>{};
}

class RuntimeTypeGenerator {
  final Compiler compiler;
  final CodeEmitterTask emitterTask;
  final Namer namer;

  RuntimeTypeGenerator(this.compiler, this.emitterTask, this.namer);

  JavaScriptBackend get backend => compiler.backend;
  TypeTestRegistry get typeTestRegistry => emitterTask.typeTestRegistry;
  CoreClasses get coreClasses => compiler.coreClasses;

  Set<ClassElement> get checkedClasses => typeTestRegistry.checkedClasses;

  Iterable<ClassElement> get classesUsingTypeVariableTests =>
      typeTestRegistry.classesUsingTypeVariableTests;
  Iterable<ClassElement> get classesUsingTypeVariableExpression =>
      backend.rti.classesUsingTypeVariableExpression;

  Set<FunctionType> get checkedFunctionTypes =>
      typeTestRegistry.checkedFunctionTypes;

  /// Generates all properties necessary for is-checks on the [classElement].
  ///
  /// Returns an instance of [TypeTestProperties] that contains the properties
  /// that must be installed on the prototype of the JS constructor of the
  /// [classElement].
  ///
  /// If [storeFunctionTypeInMetadata] is `true`, stores the reified function
  /// type (if class has one) in the metadata object and stores its index in
  /// the result. This is only possible for function types that do not contain
  /// type variables.
  TypeTestProperties generateIsTests(ClassElement classElement,
      {bool storeFunctionTypeInMetadata: true}) {
    assert(invariant(classElement, classElement.isDeclaration));

    TypeTestProperties result = new TypeTestProperties();

    /// Generates an is-test if the test is not inherited from a superclass
    /// This assumes that for every class an is-tests is generated
    /// dynamically at runtime. We also always generate tests against
    /// native classes.
    /// TODO(herhut): Generate tests for native classes dynamically, as well.
    void generateIsTest(Element other) {
      if (backend.isNative(classElement) || !classElement.isSubclassOf(other)) {
        result.properties[namer.operatorIs(other)] = js('1');
      }
    }

    void generateFunctionTypeSignature(
        FunctionElement method, FunctionType type) {
      assert(method.isImplementation);
      jsAst.Expression thisAccess = new jsAst.This();
      if (!method.isAbstract) {
        ClosureClassMap closureData = compiler.closureToClassMapper
            .getClosureToClassMapping(method.resolvedAst);
        ClosureFieldElement thisLocal =
            closureData.freeVariableMap[closureData.thisLocal];
        if (thisLocal != null) {
          jsAst.Name thisName = namer.instanceFieldPropertyName(thisLocal);
          thisAccess = js('this.#', thisName);
        }
      }

      if (storeFunctionTypeInMetadata && !type.containsTypeVariables) {
        result.functionTypeIndex =
            emitterTask.metadataCollector.reifyType(type);
      } else {
        RuntimeTypesEncoder rtiEncoder = backend.rtiEncoder;
        jsAst.Expression encoding =
            rtiEncoder.getSignatureEncoding(type, thisAccess);
        jsAst.Name operatorSignature = namer.asName(namer.operatorSignature);
        result.properties[operatorSignature] = encoding;
      }
    }

    void generateSubstitution(ClassElement cls, {bool emitNull: false}) {
      if (cls.typeVariables.isEmpty) return;
      RuntimeTypes rti = backend.rti;
      RuntimeTypesEncoder rtiEncoder = backend.rtiEncoder;
      jsAst.Expression expression;
      bool needsNativeCheck =
          emitterTask.nativeEmitter.requiresNativeIsCheck(cls);
      Substitution substitution = rti.getSubstitution(classElement, cls);
      if (substitution != null) {
        expression = rtiEncoder.getSubstitutionCode(substitution);
      }
      if (expression == null && (emitNull || needsNativeCheck)) {
        expression = new jsAst.LiteralNull();
      }
      if (expression != null) {
        result.properties[namer.substitutionName(cls)] = expression;
      }
    }

    void generateTypeCheck(TypeCheck check) {
      ClassElement checkedClass = check.cls;
      generateIsTest(checkedClass);
      Substitution substitution = check.substitution;
      if (substitution != null) {
        jsAst.Expression body =
            backend.rtiEncoder.getSubstitutionCode(substitution);
        result.properties[namer.substitutionName(checkedClass)] = body;
      }
    }

    _generateIsTestsOn(classElement, generateIsTest,
        generateFunctionTypeSignature, generateSubstitution, generateTypeCheck);

    if (classElement == backend.helpers.jsJavaScriptFunctionClass) {
      var type = backend.jsInteropAnalysis.buildJsFunctionType();
      if (type != null) {
        jsAst.Expression thisAccess = new jsAst.This();
        RuntimeTypesEncoder rtiEncoder = backend.rtiEncoder;
        jsAst.Expression encoding =
            rtiEncoder.getSignatureEncoding(type, thisAccess);
        jsAst.Name operatorSignature = namer.asName(namer.operatorSignature);
        result.properties[operatorSignature] = encoding;
      }
    }
    return result;
  }

  /**
   * Generate "is tests" for [cls] itself, and the "is tests" for the
   * classes it implements and type argument substitution functions for these
   * tests.   We don't need to add the "is tests" of the super class because
   * they will be inherited at runtime, but we may need to generate the
   * substitutions, because they may have changed.
   */
  void _generateIsTestsOn(
      ClassElement cls,
      void generateIsTest(Element element),
      FunctionTypeSignatureEmitter generateFunctionTypeSignature,
      SubstitutionEmitter generateSubstitution,
      void emitTypeCheck(TypeCheck check)) {
    Setlet<Element> generated = new Setlet<Element>();

    if (checkedClasses.contains(cls)) {
      generateIsTest(cls);
      generateSubstitution(cls);
      generated.add(cls);
    }

    // Precomputed is checks.
    TypeChecks typeChecks = backend.rti.requiredChecks;
    Iterable<TypeCheck> classChecks = typeChecks[cls];
    if (classChecks != null) {
      for (TypeCheck check in classChecks) {
        if (!generated.contains(check.cls)) {
          emitTypeCheck(check);
          generated.add(check.cls);
        }
      }
    }

    ClassElement superclass = cls.superclass;

    bool haveSameTypeVariables(ClassElement a, ClassElement b) {
      if (a.isClosure) return true;
      return backend.rti.isTrivialSubstitution(a, b);
    }

    bool supertypesNeedSubstitutions = false;

    if (superclass != null &&
        superclass != coreClasses.objectClass &&
        !haveSameTypeVariables(cls, superclass)) {
      // We cannot inherit the generated substitutions, because the type
      // variable layout for this class is different.  Instead we generate
      // substitutions for all checks and make emitSubstitution a NOP for the
      // rest of this function.

      // TODO(karlklose): move the computation of these checks to
      // RuntimeTypeInformation.
      while (superclass != null) {
        if (backend.classNeedsRti(superclass)) {
          generateSubstitution(superclass, emitNull: true);
          generated.add(superclass);
        }
        superclass = superclass.superclass;
      }
      supertypesNeedSubstitutions = true;
    }

    if (cls is MixinApplicationElement) {
      supertypesNeedSubstitutions = true;
    }

    if (supertypesNeedSubstitutions) {
      for (DartType supertype in cls.allSupertypes) {
        ClassElement superclass = supertype.element;
        if (generated.contains(superclass)) continue;

        if (classesUsingTypeVariableTests.contains(superclass) ||
            classesUsingTypeVariableExpression.contains(superclass) ||
            checkedClasses.contains(superclass)) {
          // Generate substitution.  If no substitution is necessary, emit
          // `null` to overwrite a (possibly) existing substitution from the
          // super classes.
          generateSubstitution(superclass, emitNull: true);
        }
      }

      void emitNothing(_, {emitNull}) {}

      generateSubstitution = emitNothing;
    }

    // A class that defines a `call` method implicitly implements
    // [Function] and needs checks for all typedefs that are used in is-checks.
    if (checkedClasses.contains(coreClasses.functionClass) ||
        checkedFunctionTypes.isNotEmpty) {
      Element call = cls.lookupLocalMember(Identifiers.call);
      if (call == null) {
        // If [cls] is a closure, it has a synthetic call operator method.
        call = cls.lookupBackendMember(Identifiers.call);
      }
      if (call != null && call.isFunction) {
        FunctionElement callFunction = call;
        // A superclass might already implement the Function interface. In such
        // a case, we can avoid emiting the is test here.
        if (!cls.superclass.implementsFunction(coreClasses)) {
          _generateInterfacesIsTests(coreClasses.functionClass, generateIsTest,
              generateSubstitution, generated);
        }
        FunctionType callType = callFunction.computeType(compiler.resolution);
        generateFunctionTypeSignature(callFunction, callType);
      }
    }

    for (DartType interfaceType in cls.interfaces) {
      _generateInterfacesIsTests(interfaceType.element, generateIsTest,
          generateSubstitution, generated);
    }
  }

  /**
   * Generate "is tests" where [cls] is being implemented.
   */
  void _generateInterfacesIsTests(
      ClassElement cls,
      void generateIsTest(ClassElement element),
      SubstitutionEmitter generateSubstitution,
      Set<Element> alreadyGenerated) {
    void tryEmitTest(ClassElement check) {
      if (!alreadyGenerated.contains(check) && checkedClasses.contains(check)) {
        alreadyGenerated.add(check);
        generateIsTest(check);
        generateSubstitution(check);
      }
    }

    tryEmitTest(cls);

    for (DartType interfaceType in cls.interfaces) {
      Element element = interfaceType.element;
      tryEmitTest(element);
      _generateInterfacesIsTests(
          element, generateIsTest, generateSubstitution, alreadyGenerated);
    }

    // We need to also emit "is checks" for the superclass and its supertypes.
    ClassElement superclass = cls.superclass;
    if (superclass != null) {
      tryEmitTest(superclass);
      _generateInterfacesIsTests(
          superclass, generateIsTest, generateSubstitution, alreadyGenerated);
    }
  }

  List<StubMethod> generateTypeVariableReaderStubs(ClassElement classElement) {
    List<StubMethod> stubs = <StubMethod>[];
    ClassElement superclass = classElement;
    while (superclass != null) {
      for (TypeVariableType parameter in superclass.typeVariables) {
        if (backend.emitter.readTypeVariables.contains(parameter.element)) {
          stubs.add(
              _generateTypeVariableReader(classElement, parameter.element));
        }
      }
      superclass = superclass.superclass;
    }

    return stubs;
  }

  StubMethod _generateTypeVariableReader(
      ClassElement cls, TypeVariableElement element) {
    jsAst.Name name = namer.nameForReadTypeVariable(element);
    int index = element.index;
    jsAst.Expression computeTypeVariable;

    Substitution substitution =
        backend.rti.getSubstitution(cls, element.typeDeclaration);
    jsAst.Name rtiFieldName = backend.namer.rtiFieldName;
    if (substitution != null) {
      computeTypeVariable = js(r'#.apply(null, this.#)', [
        backend.rtiEncoder.getSubstitutionCodeForVariable(substitution, index),
        rtiFieldName
      ]);
    } else {
      // TODO(ahe): These can be generated dynamically.
      computeTypeVariable = js(r'this.# && this.#[#]',
          [rtiFieldName, rtiFieldName, js.number(index)]);
    }
    jsAst.Expression convertRtiToRuntimeType = backend.emitter
        .staticFunctionAccess(backend.helpers.convertRtiToRuntimeType);

    return new StubMethod(
        name,
        js('function () { return #(#) }',
            [convertRtiToRuntimeType, computeTypeVariable]));
  }
}
