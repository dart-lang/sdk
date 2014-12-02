// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class TypeTestEmitter extends CodeEmitterHelper {
  Set<ClassElement> get checkedClasses =>
      emitter.typeTestRegistry.checkedClasses;

  Iterable<ClassElement> get classesUsingTypeVariableTests =>
      emitter.typeTestRegistry.classesUsingTypeVariableTests;

  Set<FunctionType> get checkedFunctionTypes =>
      emitter.typeTestRegistry.checkedFunctionTypes;

  void emitIsTests(ClassElement classElement, ClassBuilder builder) {
    assert(invariant(classElement, classElement.isDeclaration));

    void generateIsTest(Element other) {
      if (other == compiler.objectClass && other != classElement) {
        // Avoid emitting [:$isObject:] on all classes but [Object].
        return;
      }
      builder.addProperty(namer.operatorIs(other), js('true'));
    }

    void generateFunctionTypeSignature(FunctionElement method,
                                       FunctionType type) {
      assert(method.isImplementation);
      jsAst.Expression thisAccess = new jsAst.This();
      Node node = method.node;
      ClosureClassMap closureData =
          compiler.closureToClassMapper.closureMappingCache[node];
      if (closureData != null) {
        ClosureFieldElement thisLocal =
            closureData.getFreeVariableElement(closureData.thisLocal);
        if (thisLocal != null) {
          String thisName = namer.instanceFieldPropertyName(thisLocal);
          thisAccess = js('this.#', thisName);
        }
      }
      RuntimeTypes rti = backend.rti;
      jsAst.Expression encoding = rti.getSignatureEncoding(type, thisAccess);
      String operatorSignature = namer.operatorSignature;
      if (!type.containsTypeVariables) {
        builder.functionType = '${emitter.metadataEmitter.reifyType(type)}';
      } else {
        builder.addProperty(operatorSignature, encoding);
      }
    }

    void generateSubstitution(ClassElement cls, {bool emitNull: false}) {
      if (cls.typeVariables.isEmpty) return;
      RuntimeTypes rti = backend.rti;
      jsAst.Expression expression;
      bool needsNativeCheck = emitter.nativeEmitter.requiresNativeIsCheck(cls);
      expression = rti.getSupertypeSubstitution(classElement, cls);
      if (expression == null && (emitNull || needsNativeCheck)) {
        expression = new jsAst.LiteralNull();
      }
      if (expression != null) {
        builder.addProperty(namer.substitutionName(cls), expression);
      }
    }

    generateIsTestsOn(classElement, generateIsTest,
        generateFunctionTypeSignature,
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
                         FunctionTypeSignatureEmitter emitFunctionTypeSignature,
                         SubstitutionEmitter emitSubstitution) {
    if (checkedClasses.contains(cls)) {
      emitIsTest(cls);
      emitSubstitution(cls);
    }

    RuntimeTypes rti = backend.rti;
    ClassElement superclass = cls.superclass;

    bool haveSameTypeVariables(ClassElement a, ClassElement b) {
      if (a.isClosure) return true;
      return backend.rti.isTrivialSubstitution(a, b);
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
      while (superclass != null) {
        if (backend.classNeedsRti(superclass)) {
          emitSubstitution(superclass, emitNull: true);
          emitted.add(superclass);
        }
        superclass = superclass.superclass;
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
      if (call != null && call.isFunction) {
        // A superclass might already implement the Function interface. In such
        // a case, we can avoid emiting the is test here.
        if (!cls.superclass.implementsFunction(compiler)) {
          generateInterfacesIsTests(compiler.functionClass,
                                    emitIsTest,
                                    emitSubstitution,
                                    generated);
        }
        FunctionType callType = call.computeType(compiler);
        emitFunctionTypeSignature(call, callType);
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

  void emitRuntimeTypeSupport(CodeBuffer buffer, OutputUnit outputUnit) {
    emitter.addComment('Runtime type support', buffer);
    RuntimeTypes rti = backend.rti;
    TypeChecks typeChecks = rti.requiredChecks;

    // Add checks to the constructors of instantiated classes.
    // TODO(sigurdm): We should avoid running through this list for each
    // output unit.

    jsAst.Statement variables = js.statement('var TRUE = !0, _;');
    List<jsAst.Statement> statements = <jsAst.Statement>[];

    for (ClassElement cls in typeChecks) {
      OutputUnit destination =
          compiler.deferredLoadTask.outputUnitForElement(cls);
      if (destination != outputUnit) continue;
      // TODO(9556).  The properties added to 'holder' should be generated
      // directly as properties of the class object, not added later.

      // Each element is a pair: [propertyName, valueExpression]
      List<List> properties = <List>[];

      for (TypeCheck check in typeChecks[cls]) {
        ClassElement checkedClass = check.cls;
        properties.add([namer.operatorIs(checkedClass), js('TRUE')]);
        Substitution substitution = check.substitution;
        if (substitution != null) {
          jsAst.Expression body = substitution.getCode(rti);
          properties.add([namer.substitutionName(checkedClass), body]);
        }
      }

      jsAst.Expression holder = namer.elementAccess(cls);
      if (properties.length > 1) {
        // Use temporary shortened reference.
        statements.add(js.statement('_ = #;', holder));
        holder = js('#', '_');
      }
      for (List nameAndValue in properties) {
        statements.add(
            js.statement('#.# = #',
                [holder, nameAndValue[0], nameAndValue[1]]));
      }
    }

    if (statements.isNotEmpty) {
      buffer.write(';');
      buffer.write(
          jsAst.prettyPrint(
              js.statement('(function() { #; #; })()', [variables, statements]),
              compiler));
      buffer.write('$N');
    }
  }
}
