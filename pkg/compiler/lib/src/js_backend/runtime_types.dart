// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/// For each class, stores the possible class subtype tests that could succeed.
abstract class TypeChecks {
  /// Get the set of checks required for class [element].
  Iterable<TypeCheck> operator[](ClassElement element);
  /// Get the iterator for all classes that need type checks.
  Iterator<ClassElement> get iterator;
}

typedef jsAst.Expression OnVariableCallback(TypeVariableType variable);
typedef bool ShouldEncodeTypedefCallback(TypedefType variable);

class RuntimeTypes {
  final Compiler compiler;
  final TypeRepresentationGenerator representationGenerator;

  final Map<ClassElement, Set<ClassElement>> rtiDependencies;
  final Set<ClassElement> classesNeedingRti;
  final Set<Element> methodsNeedingRti;
  // The set of classes that use one of their type variables as expressions
  // to get the runtime type.
  final Set<ClassElement> classesUsingTypeVariableExpression;
  // The set of type arguments tested against type variable bounds.
  final Set<DartType> checkedTypeArguments;
  // The set of tested type variable bounds.
  final Set<DartType> checkedBounds;

  JavaScriptBackend get backend => compiler.backend;

  RuntimeTypes(Compiler compiler)
      : this.compiler = compiler,
        representationGenerator = new TypeRepresentationGenerator(compiler),
        classesNeedingRti = new Set<ClassElement>(),
        methodsNeedingRti = new Set<Element>(),
        rtiDependencies = new Map<ClassElement, Set<ClassElement>>(),
        classesUsingTypeVariableExpression = new Set<ClassElement>(),
        checkedTypeArguments = new Set<DartType>(),
        checkedBounds = new Set<DartType>();

  Set<ClassElement> directlyInstantiatedArguments;
  Set<ClassElement> allInstantiatedArguments;
  Set<ClassElement> checkedArguments;

  void registerRtiDependency(Element element, Element dependency) {
    // We're not dealing with typedef for now.
    if (!element.isClass || !dependency.isClass) return;
    Set<ClassElement> classes =
        rtiDependencies.putIfAbsent(element, () => new Set<ClassElement>());
    classes.add(dependency);
  }

  void registerTypeVariableBoundsSubtypeCheck(DartType typeArgument,
                                              DartType bound) {
    checkedTypeArguments.add(typeArgument);
    checkedBounds.add(bound);
  }

  bool usingFactoryWithTypeArguments = false;

  /**
   * Compute type arguments of classes that use one of their type variables in
   * is-checks and add the is-checks that they imply.
   *
   * This function must be called after all is-checks have been registered.
   *
   * TODO(karlklose): move these computations into a function producing an
   * immutable datastructure.
   */
  void addImplicitChecks(Universe universe,
                         Iterable<ClassElement> classesUsingChecks) {
    // If there are no classes that use their variables in checks, there is
    // nothing to do.
    if (classesUsingChecks.isEmpty) return;
    Set<DartType> instantiatedTypes = universe.instantiatedTypes;
    if (universe.usingFactoryWithTypeArguments) {
      for (DartType type in instantiatedTypes) {
        if (type.kind != TypeKind.INTERFACE) continue;
        InterfaceType interface = type;
        do {
          for (DartType argument in interface.typeArguments) {
            universe.registerIsCheck(argument, compiler);
          }
          interface = interface.element.supertype;
        } while (interface != null && !instantiatedTypes.contains(interface));
      }
    } else {
      // Find all instantiated types that are a subtype of a class that uses
      // one of its type arguments in an is-check and add the arguments to the
      // set of is-checks.
      // TODO(karlklose): replace this with code that uses a subtype lookup
      // datastructure in the world.
      for (DartType type in instantiatedTypes) {
        if (type.kind != TypeKind.INTERFACE) continue;
        InterfaceType classType = type;
        for (ClassElement cls in classesUsingChecks) {
          InterfaceType current = classType;
          do {
            // We need the type as instance of its superclass anyway, so we just
            // try to compute the substitution; if the result is [:null:], the
            // classes are not related.
            InterfaceType instance = current.asInstanceOf(cls);
            if (instance == null) break;
            for (DartType argument in instance.typeArguments) {
              universe.registerIsCheck(argument, compiler);
            }
            current = current.element.supertype;
          } while (current != null && !instantiatedTypes.contains(current));
        }
      }
    }
  }

  void computeClassesNeedingRti() {
    // Find the classes that need runtime type information. Such
    // classes are:
    // (1) used in a is check with type variables,
    // (2) dependencies of classes in (1),
    // (3) subclasses of (2) and (3).
    void potentiallyAddForRti(ClassElement cls) {
      assert(invariant(cls, cls.isDeclaration));
      if (cls.typeVariables.isEmpty) return;
      if (classesNeedingRti.contains(cls)) return;
      classesNeedingRti.add(cls);

      // TODO(ngeoffray): This should use subclasses, not subtypes.
      Iterable<ClassElement> classes = compiler.world.subtypesOf(cls);
      classes.forEach((ClassElement sub) {
        potentiallyAddForRti(sub);
      });

      Set<ClassElement> dependencies = rtiDependencies[cls];
      if (dependencies != null) {
        dependencies.forEach((ClassElement other) {
          potentiallyAddForRti(other);
        });
      }
    }

    Set<ClassElement> classesUsingTypeVariableTests = new Set<ClassElement>();
    compiler.resolverWorld.isChecks.forEach((DartType type) {
      if (type.isTypeVariable) {
        TypeVariableElement variable = type.element;
        classesUsingTypeVariableTests.add(variable.typeDeclaration);
      }
    });
    // Add is-checks that result from classes using type variables in checks.
    addImplicitChecks(compiler.resolverWorld, classesUsingTypeVariableTests);
    // Add the rti dependencies that are implicit in the way the backend
    // generates code: when we create a new [List], we actually create
    // a JSArray in the backend and we need to add type arguments to
    // the calls of the list constructor whenever we determine that
    // JSArray needs type arguments.
    // TODO(karlklose): make this dependency visible from code.
    if (backend.jsArrayClass != null) {
      registerRtiDependency(backend.jsArrayClass, compiler.listClass);
    }
    // Compute the set of all classes and methods that need runtime type
    // information.
    compiler.resolverWorld.isChecks.forEach((DartType type) {
      if (type.isInterfaceType) {
        InterfaceType itf = type;
        if (!itf.treatAsRaw) {
          potentiallyAddForRti(itf.element);
        }
      } else {
        ClassElement contextClass = Types.getClassContext(type);
        if (contextClass != null) {
          // [type] contains type variables (declared in [contextClass]) if
          // [contextClass] is non-null. This handles checks against type
          // variables and function types containing type variables.
          potentiallyAddForRti(contextClass);
        }
        if (type.isFunctionType) {
          void analyzeMethod(TypedElement method) {
            DartType memberType = method.type;
            ClassElement contextClass = Types.getClassContext(memberType);
            if (contextClass != null &&
                compiler.types.isPotentialSubtype(memberType, type)) {
              potentiallyAddForRti(contextClass);
              methodsNeedingRti.add(method);
            }
          }
          compiler.resolverWorld.closuresWithFreeTypeVariables.forEach(
              analyzeMethod);
          compiler.resolverWorld.callMethodsWithFreeTypeVariables.forEach(
              analyzeMethod);
        }
      }
    });
    if (compiler.enableTypeAssertions) {
      void analyzeMethod(TypedElement method) {
        DartType memberType = method.type;
        ClassElement contextClass = Types.getClassContext(memberType);
        if (contextClass != null) {
          potentiallyAddForRti(contextClass);
          methodsNeedingRti.add(method);
        }
      }
      compiler.resolverWorld.closuresWithFreeTypeVariables.forEach(
          analyzeMethod);
      compiler.resolverWorld.callMethodsWithFreeTypeVariables.forEach(
          analyzeMethod);
    }
    // Add the classes that need RTI because they use a type variable as
    // expression.
    classesUsingTypeVariableExpression.forEach(potentiallyAddForRti);
  }

  TypeChecks cachedRequiredChecks;

  TypeChecks get requiredChecks {
    if (cachedRequiredChecks == null) {
      computeRequiredChecks();
    }
    assert(cachedRequiredChecks != null);
    return cachedRequiredChecks;
  }

  /// Compute the required type checkes and substitutions for the given
  /// instantitated and checked classes.
  TypeChecks computeChecks(Set<ClassElement> instantiated,
                           Set<ClassElement> checked) {
    // Run through the combination of instantiated and checked
    // arguments and record all combination where the element of a checked
    // argument is a superclass of the element of an instantiated type.
    TypeCheckMapping result = new TypeCheckMapping();
    for (ClassElement element in instantiated) {
      if (checked.contains(element)) {
        result.add(element, element, null);
      }
      // Find all supertypes of [element] in [checkedArguments] and add checks
      // and precompute the substitutions for them.
      assert(invariant(element, element.allSupertypes != null,
             message: 'Supertypes have not been computed for $element.'));
      for (DartType supertype in element.allSupertypes) {
        ClassElement superelement = supertype.element;
        if (checked.contains(superelement)) {
          Substitution substitution =
              computeSubstitution(element, superelement);
          result.add(element, superelement, substitution);
        }
      }
    }
    return result;
  }

  void computeRequiredChecks() {
    Set<DartType> isChecks = compiler.codegenWorld.isChecks;
    bool hasFunctionTypeCheck =
        isChecks.any((type) => identical(type.kind, TypeKind.FUNCTION));
    Set<DartType> instantiatedTypesAndClosures = hasFunctionTypeCheck
        ? computeInstantiatedTypesAndClosures(compiler.codegenWorld)
        : compiler.codegenWorld.instantiatedTypes;
    computeInstantiatedArguments(instantiatedTypesAndClosures, isChecks);
    computeCheckedArguments(instantiatedTypesAndClosures, isChecks);
    cachedRequiredChecks =
        computeChecks(allInstantiatedArguments, checkedArguments);
  }

  Set<DartType> computeInstantiatedTypesAndClosures(Universe universe) {
    Set<DartType> instantiatedTypes =
        new Set<DartType>.from(universe.instantiatedTypes);
    for (DartType instantiatedType in universe.instantiatedTypes) {
      if (instantiatedType.isInterfaceType) {
        InterfaceType interface = instantiatedType;
        FunctionType callType = interface.callType;
        if (callType != null) {
          instantiatedTypes.add(callType);
        }
      }
    }
    for (FunctionElement element in universe.staticFunctionsNeedingGetter) {
      instantiatedTypes.add(element.type);
    }
    // TODO(johnniwinther): We should get this information through the
    // [neededClasses] computed in the emitter instead of storing it and pulling
    // it from resolution, but currently it would introduce a cyclic dependency
    // between [computeRequiredChecks] and [computeNeededClasses].
    for (TypedElement element in compiler.resolverWorld.closurizedMembers) {
      instantiatedTypes.add(element.type);
    }
    return instantiatedTypes;
  }

  /**
   * Collects all types used in type arguments of instantiated types.
   *
   * This includes type arguments used in supertype relations, because we may
   * have a type check against this supertype that includes a check against
   * the type arguments.
   */
  void computeInstantiatedArguments(Set<DartType> instantiatedTypes,
                                    Set<DartType> isChecks) {
    ArgumentCollector superCollector = new ArgumentCollector(backend);
    ArgumentCollector directCollector = new ArgumentCollector(backend);
    FunctionArgumentCollector functionArgumentCollector =
        new FunctionArgumentCollector(backend);

    // We need to add classes occuring in function type arguments, like for
    // instance 'I' for [: o is C<f> :] where f is [: typedef I f(); :].
    void collectFunctionTypeArguments(Iterable<DartType> types) {
      for (DartType type in types) {
        functionArgumentCollector.collect(type);
      }
    }
    collectFunctionTypeArguments(isChecks);
    collectFunctionTypeArguments(checkedBounds);

    void collectTypeArguments(Iterable<DartType> types,
                              {bool isTypeArgument: false}) {
      for (DartType type in types) {
        directCollector.collect(type, isTypeArgument: isTypeArgument);
        if (type.isInterfaceType) {
          ClassElement cls = type.element;
          for (DartType supertype in cls.allSupertypes) {
            superCollector.collect(supertype, isTypeArgument: isTypeArgument);
          }
        }
      }
    }
    collectTypeArguments(instantiatedTypes);
    collectTypeArguments(checkedTypeArguments, isTypeArgument: true);

    for (ClassElement cls in superCollector.classes.toList()) {
      for (DartType supertype in cls.allSupertypes) {
        superCollector.collect(supertype);
      }
    }

    directlyInstantiatedArguments =
        directCollector.classes..addAll(functionArgumentCollector.classes);
    allInstantiatedArguments =
        superCollector.classes..addAll(directlyInstantiatedArguments);
  }

  /// Collects all type arguments used in is-checks.
  void computeCheckedArguments(Set<DartType> instantiatedTypes,
                               Set<DartType> isChecks) {
    ArgumentCollector collector = new ArgumentCollector(backend);
    FunctionArgumentCollector functionArgumentCollector =
        new FunctionArgumentCollector(backend);

    // We need to add types occuring in function type arguments, like for
    // instance 'J' for [: (J j) {} is f :] where f is
    // [: typedef void f(I i); :] and 'J' is a subtype of 'I'.
    void collectFunctionTypeArguments(Iterable<DartType> types) {
      for (DartType type in types) {
        functionArgumentCollector.collect(type);
      }
    }
    collectFunctionTypeArguments(instantiatedTypes);
    collectFunctionTypeArguments(checkedTypeArguments);

    void collectTypeArguments(Iterable<DartType> types,
                              {bool isTypeArgument: false}) {
      for (DartType type in types) {
        collector.collect(type, isTypeArgument: isTypeArgument);
      }
    }
    collectTypeArguments(isChecks);
    collectTypeArguments(checkedBounds, isTypeArgument: true);

    checkedArguments =
        collector.classes..addAll(functionArgumentCollector.classes);
  }

  Set<ClassElement> getClassesUsedInSubstitutions(JavaScriptBackend backend,
                                                  TypeChecks checks) {
    Set<ClassElement> instantiated = new Set<ClassElement>();
    ArgumentCollector collector = new ArgumentCollector(backend);
    for (ClassElement target in checks) {
      instantiated.add(target);
      for (TypeCheck check in checks[target]) {
        Substitution substitution = check.substitution;
        if (substitution != null) {
          collector.collectAll(substitution.arguments);
        }
      }
    }
    return instantiated..addAll(collector.classes);
  }

  Set<ClassElement> getRequiredArgumentClasses(JavaScriptBackend backend) {
    Set<ClassElement> requiredArgumentClasses =
        new Set<ClassElement>.from(
            getClassesUsedInSubstitutions(backend, requiredChecks));
    return requiredArgumentClasses
        ..addAll(directlyInstantiatedArguments)
        ..addAll(checkedArguments);
  }

  String getTypeRepresentationForTypeConstant(DartType type) {
    JavaScriptBackend backend = compiler.backend;
    Namer namer = backend.namer;
    if (type.isDynamic) return namer.getRuntimeTypeName(null);
    String name = namer.uniqueNameForTypeConstantElement(type.element);
    if (!type.element.isClass) return name;
    InterfaceType interface = type;
    List<DartType> variables = interface.element.typeVariables;
    // Type constants can currently only be raw types, so there is no point
    // adding ground-term type parameters, as they would just be 'dynamic'.
    // TODO(sra): Since the result string is used only in constructing constant
    // names, it would result in more readable names if the final string was a
    // legal JavaScript identifer.
    if (variables.isEmpty) return name;
    String arguments =
        new List.filled(variables.length, 'dynamic').join(', ');
    return '$name<$arguments>';
  }

  // TODO(karlklose): maybe precompute this value and store it in typeChecks?
  bool isTrivialSubstitution(ClassElement cls, ClassElement check) {
    if (cls.isClosure) {
      // TODO(karlklose): handle closures.
      return true;
    }

    // If there are no type variables or the type is the same, we do not need
    // a substitution.
    if (check.typeVariables.isEmpty || cls == check) {
      return true;
    }

    InterfaceType originalType = cls.thisType;
    InterfaceType type = originalType.asInstanceOf(check);
    // [type] is not a subtype of [check]. we do not generate a check and do not
    // need a substitution.
    if (type == null) return true;

    // Run through both lists of type variables and check if the type variables
    // are identical at each position. If they are not, we need to calculate a
    // substitution function.
    List<DartType> variables = cls.typeVariables;
    List<DartType> arguments = type.typeArguments;
    if (variables.length != arguments.length) {
      return false;
    }
    for (int index = 0; index < variables.length; index++) {
      if (variables[index].element != arguments[index].element) {
        return false;
      }
    }
    return true;
  }

  /**
   * Compute a JavaScript expression that describes the necessary substitution
   * for type arguments in a subtype test.
   *
   * The result can be:
   *  1) [:null:], if no substituted check is necessary, because the
   *     type variables are the same or there are no type variables in the class
   *     that is checked for.
   *  2) A list expression describing the type arguments to be used in the
   *     subtype check, if the type arguments to be used in the check do not
   *     depend on the type arguments of the object.
   *  3) A function mapping the type variables of the object to be checked to
   *     a list expression.
   */
  jsAst.Expression getSupertypeSubstitution(
       ClassElement cls,
       ClassElement check,
       {bool alwaysGenerateFunction: false}) {
    Substitution substitution = getSubstitution(cls, check);
    if (substitution != null) {
      return substitution.getCode(this, alwaysGenerateFunction);
    } else {
      return null;
    }
  }

  Substitution getSubstitution(ClassElement cls, ClassElement other) {
    // Look for a precomputed check.
    for (TypeCheck check in cachedRequiredChecks[cls]) {
      if (check.cls == other) {
        return check.substitution;
      }
    }
    // There is no precomputed check for this pair (because the check is not
    // done on type arguments only.  Compute a new substitution.
    return computeSubstitution(cls, other);
  }

  Substitution computeSubstitution(ClassElement cls, ClassElement check,
                                   { bool alwaysGenerateFunction: false }) {
    if (isTrivialSubstitution(cls, check)) return null;

    // Unnamed mixin application classes do not need substitutions, because they
    // are never instantiated and their checks are overwritten by the class that
    // they are mixed into.
    InterfaceType type = cls.thisType;
    InterfaceType target = type.asInstanceOf(check);
    List<DartType> typeVariables = cls.typeVariables;
    if (typeVariables.isEmpty && !alwaysGenerateFunction) {
      return new Substitution.list(target.typeArguments);
    } else {
      return new Substitution.function(target.typeArguments, typeVariables);
    }
  }

  jsAst.Expression getSubstitutionRepresentation(
      List<DartType> types,
      OnVariableCallback onVariable) {
    List<jsAst.Expression> elements = types
        .map((DartType type) => getTypeRepresentation(type, onVariable))
        .toList(growable: false);
    return new jsAst.ArrayInitializer(elements);
  }

  jsAst.Expression getTypeEncoding(DartType type,
                                   {bool alwaysGenerateFunction: false}) {
    ClassElement contextClass = Types.getClassContext(type);
    jsAst.Expression onVariable(TypeVariableType v) {
      return new jsAst.VariableUse(v.name);
    };
    jsAst.Expression encoding = getTypeRepresentation(type, onVariable);
    if (contextClass == null && !alwaysGenerateFunction) {
      return encoding;
    } else {
      List<String> parameters = const <String>[];
      if (contextClass != null) {
        parameters = contextClass.typeVariables.map((type) {
            return type.toString();
        }).toList();
      }
      return js('function(#) { return # }', [parameters, encoding]);
    }
  }

  jsAst.Expression getSignatureEncoding(DartType type, jsAst.Expression this_) {
    ClassElement contextClass = Types.getClassContext(type);
    jsAst.Expression encoding =
        getTypeEncoding(type, alwaysGenerateFunction: true);
    if (contextClass != null) {
      JavaScriptBackend backend = compiler.backend;
      String contextName = backend.namer.getNameOfClass(contextClass);
      return js('function () { return #(#, #, #); }',
          [ backend.namer.elementAccess(backend.getComputeSignature()),
              encoding, this_, js.string(contextName) ]);
    } else {
      return encoding;
    }
  }

  String getTypeRepresentationWithHashes(DartType type,
                                         OnVariableCallback onVariable) {
    // Create a type representation.  For type variables call the original
    // callback for side effects and return a template placeholder.
    jsAst.Expression representation = getTypeRepresentation(type, (variable) {
      onVariable(variable);
      return new jsAst.LiteralString('#');
    });
    return jsAst.prettyPrint(representation, compiler).buffer.toString();
  }

  jsAst.Expression getTypeRepresentation(
      DartType type,
      OnVariableCallback onVariable,
      [ShouldEncodeTypedefCallback shouldEncodeTypedef]) {
    return representationGenerator.getTypeRepresentation(
        type, onVariable, shouldEncodeTypedef);
  }

  bool isSimpleFunctionType(FunctionType type) {
    if (!type.returnType.isDynamic) return false;
    if (!type.optionalParameterTypes.isEmpty) return false;
    if (!type.namedParameterTypes.isEmpty) return false;
    for (DartType parameter in type.parameterTypes ) {
      if (!parameter.isDynamic) return false;
    }
    return true;
  }

  static bool hasTypeArguments(DartType type) {
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      return !interfaceType.treatAsRaw;
    }
    return false;
  }

  static int getTypeVariableIndex(TypeVariableElement variable) {
    ClassElement classElement = variable.enclosingClass;
    List<DartType> variables = classElement.typeVariables;
    for (int index = 0; index < variables.length; index++) {
      if (variables[index].element == variable) return index;
    }
    throw invariant(variable, false,
                    message: "Couldn't find type-variable index");
  }

  /// Return all classes that are referenced in the type of the function, i.e.,
  /// in the return type or the argument types.
  Set<ClassElement> getReferencedClasses(FunctionType type) {
    FunctionArgumentCollector collector =
        new FunctionArgumentCollector(backend);
    collector.collect(type);
    return collector.classes;
  }
}

class TypeRepresentationGenerator extends DartTypeVisitor {
  final Compiler compiler;
  OnVariableCallback onVariable;
  ShouldEncodeTypedefCallback shouldEncodeTypedef;

  JavaScriptBackend get backend => compiler.backend;
  Namer get namer => backend.namer;

  TypeRepresentationGenerator(Compiler this.compiler);

  /**
   * Creates a type representation for [type]. [onVariable] is called to provide
   * the type representation for type variables.
   */
  jsAst.Expression getTypeRepresentation(
      DartType type,
      OnVariableCallback onVariable,
      ShouldEncodeTypedefCallback encodeTypedef) {
    this.onVariable = onVariable;
    this.shouldEncodeTypedef =
        (encodeTypedef != null) ? encodeTypedef : (TypedefType type) => false;
    jsAst.Expression representation = visit(type);
    this.onVariable = null;
    this.shouldEncodeTypedef = null;
    return representation;
  }

  jsAst.Expression getJavaScriptClassName(Element element) {
    return namer.elementAccess(element);
  }

  visit(DartType type) {
    return type.accept(this, null);
  }

  visitTypeVariableType(TypeVariableType type, _) {
    return onVariable(type);
  }

  visitDynamicType(DynamicType type, _) {
    return js('null');
  }

  visitInterfaceType(InterfaceType type, _) {
    jsAst.Expression name = getJavaScriptClassName(type.element);
    return type.treatAsRaw ? name : visitList(type.typeArguments, head: name);
  }

  jsAst.Expression visitList(List<DartType> types, {jsAst.Expression head}) {
    int index = 0;
    List<jsAst.Expression> elements = <jsAst.Expression>[];
    if (head != null) {
      elements.add(head);
      index++;
    }
    for (DartType type in types) {
      elements.add(visit(type));
    }
    return new jsAst.ArrayInitializer(elements);
  }

  visitFunctionType(FunctionType type, _) {
    List<jsAst.Property> properties = <jsAst.Property>[];

    void addProperty(String name, jsAst.Expression value) {
      properties.add(new jsAst.Property(js.string(name), value));
    }

    jsAst.LiteralString name = js.string(namer.getFunctionTypeName(type));
    addProperty(namer.functionTypeTag, name);
    if (type.returnType.isVoid) {
      addProperty(namer.functionTypeVoidReturnTag, js('true'));
    } else if (!type.returnType.treatAsDynamic) {
      addProperty(namer.functionTypeReturnTypeTag, visit(type.returnType));
    }
    if (!type.parameterTypes.isEmpty) {
      addProperty(namer.functionTypeRequiredParametersTag,
                  visitList(type.parameterTypes));
    }
    if (!type.optionalParameterTypes.isEmpty) {
      addProperty(namer.functionTypeOptionalParametersTag,
                  visitList(type.optionalParameterTypes));
    }
    if (!type.namedParameterTypes.isEmpty) {
      List<jsAst.Property> namedArguments = <jsAst.Property>[];
      List<String> names = type.namedParameters;
      List<DartType> types = type.namedParameterTypes;
      assert(types.length == names.length);
      for (int index = 0; index < types.length; index++) {
        jsAst.Expression name = js.string(names[index]);
        namedArguments.add(new jsAst.Property(name, visit(types[index])));
      }
      addProperty(namer.functionTypeNamedParametersTag,
                  new jsAst.ObjectInitializer(namedArguments));
    }
    return new jsAst.ObjectInitializer(properties);
  }

  visitMalformedType(MalformedType type, _) {
    // Treat malformed types as dynamic at runtime.
    return js('null');
  }

  visitVoidType(VoidType type, _) {
    // TODO(ahe): Reify void type ("null" means "dynamic").
    return js('null');
  }

  visitTypedefType(TypedefType type, _) {
    bool shouldEncode = shouldEncodeTypedef(type);
    DartType unaliasedType = type.unalias(compiler);
    if (shouldEncode) {
      jsAst.ObjectInitializer initializer = unaliasedType.accept(this, null);
      // We have to encode the aliased type.
      jsAst.Expression name = getJavaScriptClassName(type.element);
      jsAst.Expression encodedTypedef =
          type.treatAsRaw ? name : visitList(type.typeArguments, head: name);

      // Add it to the function-type object.
      jsAst.LiteralString tag = js.string(namer.typedefTag);
      initializer.properties.add(new jsAst.Property(tag, encodedTypedef));
      return initializer;
    } else {
      return unaliasedType.accept(this, null);
    }
  }

  visitType(DartType type, _) {
    compiler.internalError(NO_LOCATION_SPANNABLE,
        'Unexpected type: $type (${type.kind}).');
  }
}


class TypeCheckMapping implements TypeChecks {
  final Map<ClassElement, Set<TypeCheck>> map =
      new Map<ClassElement, Set<TypeCheck>>();

  Iterable<TypeCheck> operator[](ClassElement element) {
    Set<TypeCheck> result = map[element];
    return result != null ? result : const <TypeCheck>[];
  }

  void add(ClassElement cls, ClassElement check, Substitution substitution) {
    map.putIfAbsent(cls, () => new Set<TypeCheck>());
    map[cls].add(new TypeCheck(check, substitution));
  }

  Iterator<ClassElement> get iterator => map.keys.iterator;

  String toString() {
    StringBuffer sb = new StringBuffer();
    for (ClassElement holder in this) {
      for (ClassElement check in [holder]) {
        sb.write('${holder.name}.' '${check.name}, ');
      }
    }
    return '[$sb]';
  }
}

class ArgumentCollector extends DartTypeVisitor {
  final JavaScriptBackend backend;
  final Set<ClassElement> classes = new Set<ClassElement>();

  ArgumentCollector(this.backend);

  collect(DartType type, {bool isTypeArgument: false}) {
    type.accept(this, isTypeArgument);
  }

  /// Collect all types in the list as if they were arguments of an
  /// InterfaceType.
  collectAll(List<DartType> types) {
    for (DartType type in types) {
      type.accept(this, true);
    }
  }

  visitType(DartType type, _) {
    // Do nothing.
  }

  visitDynamicType(DynamicType type, _) {
    // Do not collect [:dynamic:].
  }

  visitTypedefType(TypedefType type, bool isTypeArgument) {
    type.unalias(backend.compiler).accept(this, isTypeArgument);
  }

  visitInterfaceType(InterfaceType type, bool isTypeArgument) {
    if (isTypeArgument) classes.add(type.element);
    type.visitChildren(this, true);
  }

  visitFunctionType(FunctionType type, _) {
    type.visitChildren(this, true);
  }
}

class FunctionArgumentCollector extends DartTypeVisitor {
  final JavaScriptBackend backend;
  final Set<ClassElement> classes = new Set<ClassElement>();

  FunctionArgumentCollector(this.backend);

  collect(DartType type) {
    type.accept(this, false);
  }

  /// Collect all types in the list as if they were arguments of an
  /// InterfaceType.
  collectAll(Link<DartType> types) {
    for (Link<DartType> link = types; !link.isEmpty; link = link.tail) {
      link.head.accept(this, true);
    }
  }

  visitType(DartType type, _) {
    // Do nothing.
  }

  visitDynamicType(DynamicType type, _) {
    // Do not collect [:dynamic:].
  }

  visitTypedefType(TypedefType type, bool inFunctionType) {
    type.unalias(backend.compiler).accept(this, inFunctionType);
  }

  visitInterfaceType(InterfaceType type, bool inFunctionType) {
    if (inFunctionType) {
      classes.add(type.element);
    }
    type.visitChildren(this, inFunctionType);
  }

  visitFunctionType(FunctionType type, _) {
    type.visitChildren(this, true);
  }
}

/**
 * Representation of the substitution of type arguments
 * when going from the type of a class to one of its supertypes.
 *
 * For [:class B<T> extends A<List<T>, int>:], the substitution is
 * the representation of [: (T) => [<List, T>, int] :].  For more details
 * of the representation consult the documentation of
 * [getSupertypeSubstitution].
 */
class Substitution {
  final bool isFunction;
  final List<DartType> arguments;
  final List<DartType> parameters;

  Substitution.list(this.arguments)
      : isFunction = false,
        parameters = const <DartType>[];

  Substitution.function(this.arguments, this.parameters)
      : isFunction = true;

  jsAst.Expression getCode(RuntimeTypes rti, bool ensureIsFunction) {
    jsAst.Expression declaration(TypeVariableType variable) {
      return new jsAst.Parameter(
          rti.backend.namer.safeVariableName(variable.name));
    }

    jsAst.Expression use(TypeVariableType variable) {
      return new jsAst.VariableUse(
          rti.backend.namer.safeVariableName(variable.name));
    }

    jsAst.Expression value =
        rti.getSubstitutionRepresentation(arguments, use);
    if (isFunction) {
      Iterable<jsAst.Expression> formals = parameters.map(declaration);
      return js('function(#) { return # }', [formals, value]);
    } else if (ensureIsFunction) {
      return js('function() { return # }', value);
    } else {
      return value;
    }
  }
}

/**
 * A pair of a class that we need a check against and the type argument
 * substition for this check.
 */
class TypeCheck {
  final ClassElement cls;
  final Substitution substitution;
  final int hashCode = (nextHash++) & 0x3fffffff;
  static int nextHash = 49;

  TypeCheck(this.cls, this.substitution);
}
