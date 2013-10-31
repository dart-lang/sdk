// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class TypeTestEmitter extends CodeEmitterHelper {
  static const int MAX_FUNCTION_TYPE_PREDICATES = 10;

  /**
   * Raw ClassElement symbols occuring in is-checks and type assertions.  If the
   * program contains parameterized checks `x is Set<int>` and
   * `x is Set<String>` then the ClassElement `Set` will occur once in
   * [checkedClasses].
   */
  Set<ClassElement> checkedClasses;

  /**
   * The set of function types that checked, both explicity through tests of
   * typedefs and implicitly through type annotations in checked mode.
   */
  Set<FunctionType> checkedFunctionTypes;

  Map<ClassElement, Set<FunctionType>> checkedGenericFunctionTypes =
      new Map<ClassElement, Set<FunctionType>>();

  Set<FunctionType> checkedNonGenericFunctionTypes =
      new Set<FunctionType>();

  final Set<ClassElement> rtiNeededClasses = new Set<ClassElement>();

  Iterable<ClassElement> cachedClassesUsingTypeVariableTests;

  Iterable<ClassElement> get classesUsingTypeVariableTests {
    if (cachedClassesUsingTypeVariableTests == null) {
      cachedClassesUsingTypeVariableTests = compiler.codegenWorld.isChecks
          .where((DartType t) => t is TypeVariableType)
          .map((TypeVariableType v) => v.element.getEnclosingClass())
          .toList();
    }
    return cachedClassesUsingTypeVariableTests;
  }

  void emitIsTests(ClassElement classElement, ClassBuilder builder) {
    assert(invariant(classElement, classElement.isDeclaration));

    void generateIsTest(Element other) {
      if (other == compiler.objectClass && other != classElement) {
        // Avoid emitting [:$isObject:] on all classes but [Object].
        return;
      }
      other = backend.getImplementationClass(other);
      builder.addProperty(namer.operatorIs(other), js('true'));
    }

    void generateIsFunctionTypeTest(FunctionType type) {
      String operator = namer.operatorIsType(type);
      builder.addProperty(operator, new jsAst.LiteralBool(true));
    }

    void generateFunctionTypeSignature(Element method, FunctionType type) {
      assert(method.isImplementation);
      jsAst.Expression thisAccess = new jsAst.This();
      Node node = method.parseNode(compiler);
      ClosureClassMap closureData =
          compiler.closureToClassMapper.closureMappingCache[node];
      if (closureData != null) {
        Element thisElement =
            closureData.freeVariableMapping[closureData.thisElement];
        if (thisElement != null) {
          assert(thisElement.hasFixedBackendName());
          String thisName = thisElement.fixedBackendName();
          thisAccess = js('this')[js.string(thisName)];
        }
      }
      RuntimeTypes rti = backend.rti;
      jsAst.Expression encoding = rti.getSignatureEncoding(type, thisAccess);
      String operatorSignature = namer.operatorSignature();
      builder.addProperty(operatorSignature, encoding);
    }

    void generateSubstitution(ClassElement cls, {bool emitNull: false}) {
      if (cls.typeVariables.isEmpty) return;
      RuntimeTypes rti = backend.rti;
      jsAst.Expression expression;
      bool needsNativeCheck = task.nativeEmitter.requiresNativeIsCheck(cls);
      expression = rti.getSupertypeSubstitution(
          classElement, cls, alwaysGenerateFunction: true);
      if (expression == null && (emitNull || needsNativeCheck)) {
        expression = new jsAst.LiteralNull();
      }
      if (expression != null) {
        builder.addProperty(namer.substitutionName(cls), expression);
      }
    }

    generateIsTestsOn(classElement, generateIsTest,
        generateIsFunctionTypeTest, generateFunctionTypeSignature,
        generateSubstitution);
  }

  /**
   * Generate "is tests" for [cls]: itself, and the "is tests" for the
   * classes it implements and type argument substitution functions for these
   * tests.   We don't need to add the "is tests" of the super class because
   * they will be inherited at runtime, but we may need to generate the
   * substitutions, because they may have changed.
   */
  void generateIsTestsOn(ClassElement cls,
                         void emitIsTest(Element element),
                         FunctionTypeTestEmitter emitIsFunctionTypeTest,
                         FunctionTypeSignatureEmitter emitFunctionTypeSignature,
                         SubstitutionEmitter emitSubstitution) {
    if (checkedClasses.contains(cls)) {
      emitIsTest(cls);
      emitSubstitution(cls);
    }

    RuntimeTypes rti = backend.rti;
    ClassElement superclass = cls.superclass;

    bool haveSameTypeVariables(ClassElement a, ClassElement b) {
      if (a.isClosure()) return true;
      if (b.isUnnamedMixinApplication) {
        return false;
      }
      return a.typeVariables == b.typeVariables;
    }

    if (superclass != null && superclass != compiler.objectClass &&
        !haveSameTypeVariables(cls, superclass)) {
      // We cannot inherit the generated substitutions, because the type
      // variable layout for this class is different.  Instead we generate
      // substitutions for all checks and make emitSubstitution a NOP for the
      // rest of this function.
      Set<ClassElement> emitted = new Set<ClassElement>();
      // TODO(karlklose): move the computation of these checks to
      // RuntimeTypeInformation.
      if (backend.classNeedsRti(cls)) {
        emitSubstitution(superclass, emitNull: true);
        emitted.add(superclass);
      }
      for (DartType supertype in cls.allSupertypes) {
        ClassElement superclass = supertype.element;
        if (classesUsingTypeVariableTests.contains(superclass)) {
          emitSubstitution(superclass, emitNull: true);
          emitted.add(superclass);
        }
        for (ClassElement check in checkedClasses) {
          if (supertype.element == check && !emitted.contains(check)) {
            // Generate substitution.  If no substitution is necessary, emit
            // [:null:] to overwrite a (possibly) existing substitution from the
            // super classes.
            emitSubstitution(check, emitNull: true);
            emitted.add(check);
          }
        }
      }
      void emitNothing(_, {emitNull}) {};
      emitSubstitution = emitNothing;
    }

    Set<Element> generated = new Set<Element>();
    // A class that defines a [:call:] method implicitly implements
    // [Function] and needs checks for all typedefs that are used in is-checks.
    if (checkedClasses.contains(compiler.functionClass) ||
        !checkedFunctionTypes.isEmpty) {
      Element call = cls.lookupLocalMember(Compiler.CALL_OPERATOR_NAME);
      if (call == null) {
        // If [cls] is a closure, it has a synthetic call operator method.
        call = cls.lookupBackendMember(Compiler.CALL_OPERATOR_NAME);
      }
      if (call != null && call.isFunction()) {
        generateInterfacesIsTests(compiler.functionClass,
                                  emitIsTest,
                                  emitSubstitution,
                                  generated);
        FunctionType callType = call.computeType(compiler);
        Map<FunctionType, bool> functionTypeChecks =
            getFunctionTypeChecksOn(callType);
        generateFunctionTypeTests(
            call, callType, functionTypeChecks,
            emitFunctionTypeSignature, emitIsFunctionTypeTest);
     }
    }

    for (DartType interfaceType in cls.interfaces) {
      generateInterfacesIsTests(interfaceType.element, emitIsTest,
                                emitSubstitution, generated);
    }
  }

  /**
   * Generate "is tests" where [cls] is being implemented.
   */
  void generateInterfacesIsTests(ClassElement cls,
                                 void emitIsTest(ClassElement element),
                                 SubstitutionEmitter emitSubstitution,
                                 Set<Element> alreadyGenerated) {
    void tryEmitTest(ClassElement check) {
      if (!alreadyGenerated.contains(check) && checkedClasses.contains(check)) {
        alreadyGenerated.add(check);
        emitIsTest(check);
        emitSubstitution(check);
      }
    };

    tryEmitTest(cls);

    for (DartType interfaceType in cls.interfaces) {
      Element element = interfaceType.element;
      tryEmitTest(element);
      generateInterfacesIsTests(element, emitIsTest, emitSubstitution,
                                alreadyGenerated);
    }

    // We need to also emit "is checks" for the superclass and its supertypes.
    ClassElement superclass = cls.superclass;
    if (superclass != null) {
      tryEmitTest(superclass);
      generateInterfacesIsTests(superclass, emitIsTest, emitSubstitution,
                                alreadyGenerated);
    }
  }

  /**
   * Returns a mapping containing all checked function types for which [type]
   * can be a subtype. A function type is mapped to [:true:] if [type] is
   * statically known to be a subtype of it and to [:false:] if [type] might
   * be a subtype, provided with the right type arguments.
   */
  // TODO(johnniwinther): Change to return a mapping from function types to
  // a set of variable points and use this to detect statically/dynamically
  // known subtype relations.
  Map<FunctionType, bool> getFunctionTypeChecksOn(DartType type) {
    Map<FunctionType, bool> functionTypeMap = new Map<FunctionType, bool>();
    for (FunctionType functionType in checkedFunctionTypes) {
      int maybeSubtype = compiler.types.computeSubtypeRelation(type, functionType);
      if (maybeSubtype == Types.IS_SUBTYPE) {
        functionTypeMap[functionType] = true;
      } else if (maybeSubtype == Types.MAYBE_SUBTYPE) {
        functionTypeMap[functionType] = false;
      }
    }
    // TODO(johnniwinther): Ensure stable ordering of the keys.
    return functionTypeMap;
  }

  /**
   * Generates function type checks on [method] with type [methodType] against
   * the function type checks in [functionTypeChecks].
   */
  void generateFunctionTypeTests(
      Element method,
      FunctionType methodType,
      Map<FunctionType, bool> functionTypeChecks,
      FunctionTypeSignatureEmitter emitFunctionTypeSignature,
      FunctionTypeTestEmitter emitIsFunctionTypeTest) {
    bool hasDynamicFunctionTypeCheck = false;
    int neededPredicates = 0;
    functionTypeChecks.forEach((FunctionType functionType, bool knownSubtype) {
      if (!knownSubtype) {
        registerDynamicFunctionTypeCheck(functionType);
        hasDynamicFunctionTypeCheck = true;
      } else if (!backend.rti.isSimpleFunctionType(functionType)) {
        // Simple function types are always checked using predicates and should
        // not provoke generation of signatures.
        neededPredicates++;
      }
    });
    bool alwaysUseSignature = false;
    if (hasDynamicFunctionTypeCheck ||
        neededPredicates > MAX_FUNCTION_TYPE_PREDICATES) {
      emitFunctionTypeSignature(method, methodType);
      alwaysUseSignature = true;
    }
    functionTypeChecks.forEach((FunctionType functionType, bool knownSubtype) {
      if (knownSubtype) {
        if (backend.rti.isSimpleFunctionType(functionType)) {
          // Simple function types are always checked using predicates.
          emitIsFunctionTypeTest(functionType);
        } else if (alwaysUseSignature) {
          registerDynamicFunctionTypeCheck(functionType);
        } else {
          emitIsFunctionTypeTest(functionType);
        }
      }
    });
  }

  void registerDynamicFunctionTypeCheck(FunctionType functionType) {
    ClassElement classElement = Types.getClassContext(functionType);
    if (classElement != null) {
      checkedGenericFunctionTypes.putIfAbsent(classElement,
          () => new Set<FunctionType>()).add(functionType);
    } else {
      checkedNonGenericFunctionTypes.add(functionType);
    }
  }

  void emitRuntimeTypeSupport(CodeBuffer buffer) {
    task.addComment('Runtime type support', buffer);
    RuntimeTypes rti = backend.rti;
    TypeChecks typeChecks = rti.requiredChecks;

    // Add checks to the constructors of instantiated classes.
    for (ClassElement cls in typeChecks) {
      // TODO(9556).  The properties added to 'holder' should be generated
      // directly as properties of the class object, not added later.
      String holder = namer.isolateAccess(backend.getImplementationClass(cls));
      for (TypeCheck check in typeChecks[cls]) {
        ClassElement cls = check.cls;
        buffer.write('$holder.${namer.operatorIs(cls)}$_=${_}true$N');
        Substitution substitution = check.substitution;
        if (substitution != null) {
          CodeBuffer body =
             jsAst.prettyPrint(substitution.getCode(rti, false), compiler);
          buffer.write('$holder.${namer.substitutionName(cls)}$_=${_}');
          buffer.write(body);
          buffer.write('$N');
        }
      };
    }

    void addSignature(FunctionType type) {
      jsAst.Expression encoding = rti.getTypeEncoding(type);
      buffer.add('${namer.signatureName(type)}$_=${_}');
      buffer.write(jsAst.prettyPrint(encoding, compiler));
      buffer.add('$N');
    }

    checkedNonGenericFunctionTypes.forEach(addSignature);

    checkedGenericFunctionTypes.forEach((_, Set<FunctionType> functionTypes) {
      functionTypes.forEach(addSignature);
    });
  }

  /**
   * Returns the classes with constructors used as a 'holder' in
   * [emitRuntimeTypeSupport].
   * TODO(9556): Some cases will go away when the class objects are created as
   * complete.  Not all classes will go away while constructors are referenced
   * from type substitutions.
   */
  Set<ClassElement> classesModifiedByEmitRuntimeTypeSupport() {
    TypeChecks typeChecks = backend.rti.requiredChecks;
    Set<ClassElement> result = new Set<ClassElement>();
    for (ClassElement cls in typeChecks) {
      for (TypeCheck check in typeChecks[cls]) {
        result.add(backend.getImplementationClass(cls));
        break;
      }
    }
    return result;
  }

  Set<ClassElement> computeRtiNeededClasses() {
    void addClassWithSuperclasses(ClassElement cls) {
      rtiNeededClasses.add(cls);
      for (ClassElement superclass = cls.superclass;
          superclass != null;
          superclass = superclass.superclass) {
        rtiNeededClasses.add(superclass);
      }
    }

    void addClassesWithSuperclasses(Iterable<ClassElement> classes) {
      for (ClassElement cls in classes) {
        addClassWithSuperclasses(cls);
      }
    }

    // 1.  Add classes that are referenced by type arguments or substitutions in
    //     argument checks.
    // TODO(karlklose): merge this case with 2 when unifying argument and
    // object checks.
    RuntimeTypes rti = backend.rti;
    rti.getRequiredArgumentClasses(backend).forEach((ClassElement c) {
      // Types that we represent with JS native types (like int and String) do
      // not need a class definition as we use the interceptor classes instead.
      if (!rti.isJsNative(c)) {
        addClassWithSuperclasses(c);
      }
    });

    // 2.  Add classes that are referenced by substitutions in object checks and
    //     their superclasses.
    TypeChecks requiredChecks =
        rti.computeChecks(rtiNeededClasses, checkedClasses);
    Set<ClassElement> classesUsedInSubstitutions =
        rti.getClassesUsedInSubstitutions(backend, requiredChecks);
    addClassesWithSuperclasses(classesUsedInSubstitutions);

    // 3.  Add classes that contain checked generic function types. These are
    //     needed to store the signature encoding.
    for (FunctionType type in checkedFunctionTypes) {
      ClassElement contextClass = Types.getClassContext(type);
      if (contextClass != null) {
        rtiNeededClasses.add(contextClass);
      }
    }

    return rtiNeededClasses;
  }

  void computeRequiredTypeChecks() {
    assert(checkedClasses == null && checkedFunctionTypes == null);

    backend.rti.addImplicitChecks(compiler.codegenWorld,
                                  classesUsingTypeVariableTests);

    checkedClasses = new Set<ClassElement>();
    checkedFunctionTypes = new Set<FunctionType>();
    compiler.codegenWorld.isChecks.forEach((DartType t) {
      if (t is InterfaceType) {
        checkedClasses.add(t.element);
      } else if (t is FunctionType) {
        checkedFunctionTypes.add(t);
      }
    });
  }
}
