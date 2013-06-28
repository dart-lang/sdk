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

typedef String VariableSubstitution(TypeVariableType variable);

class RuntimeTypes {
  final Compiler compiler;
  final TypeRepresentationGenerator representationGenerator;

  final Map<ClassElement, Set<ClassElement>> rtiDependencies;
  final Set<ClassElement> classesNeedingRti;
  final Set<Element> methodsNeedingRti;
  // The set of classes that use one of their type variables as expressions
  // to get the runtime type.
  final Set<ClassElement> classesUsingTypeVariableExpression;

  JavaScriptBackend get backend => compiler.backend;

  RuntimeTypes(Compiler compiler)
      : this.compiler = compiler,
        representationGenerator = new TypeRepresentationGenerator(compiler),
        classesNeedingRti = new Set<ClassElement>(),
        methodsNeedingRti = new Set<Element>(),
        rtiDependencies = new Map<ClassElement, Set<ClassElement>>(),
        classesUsingTypeVariableExpression = new Set<ClassElement>();

  Set<ClassElement> directlyInstantiatedArguments;
  Set<ClassElement> allInstantiatedArguments;
  Set<ClassElement> checkedArguments;

  bool isJsNative(Element element) {
    return (element == compiler.intClass ||
            element == compiler.boolClass ||
            element == compiler.numClass ||
            element == compiler.doubleClass ||
            element == compiler.stringClass ||
            element == compiler.listClass);
  }

  void registerRtiDependency(Element element, Element dependency) {
    // We're not dealing with typedef for now.
    if (!element.isClass() || !dependency.isClass()) return;
    Set<ClassElement> classes =
        rtiDependencies.putIfAbsent(element, () => new Set<ClassElement>());
    classes.add(dependency);
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
      Set<ClassElement> classes = compiler.world.subtypesOf(cls);
      if (classes != null) {
        classes.forEach((ClassElement sub) {
          potentiallyAddForRti(sub);
        });
      }

      Set<ClassElement> dependencies = rtiDependencies[cls];
      if (dependencies != null) {
        dependencies.forEach((ClassElement other) {
          potentiallyAddForRti(other);
        });
      }
    }

    Set<ClassElement> classesUsingTypeVariableTests = new Set<ClassElement>();
    compiler.resolverWorld.isChecks.forEach((DartType type) {
      if (type.kind == TypeKind.TYPE_VARIABLE) {
        TypeVariableElement variable = type.element;
        classesUsingTypeVariableTests.add(variable.enclosingElement);
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
      if (type.kind == TypeKind.INTERFACE) {
        InterfaceType itf = type;
        if (!itf.isRaw) {
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
        if (type.kind == TypeKind.FUNCTION) {
          void analyzeMethod(Element method) {
            DartType memberType = method.computeType(compiler);
            ClassElement contextClass = Types.getClassContext(memberType);
            if (contextClass != null &&
                compiler.types.isPotentialSubtype(memberType, type)) {
              potentiallyAddForRti(contextClass);
              methodsNeedingRti.add(method);
            }
          }
          compiler.resolverWorld.closurizedGenericMembers.forEach(
              analyzeMethod);
          compiler.resolverWorld.genericCallMethods.forEach(analyzeMethod);
        }
      }
    });
    if (compiler.enableTypeAssertions) {
      void analyzeMethod(Element method) {
        DartType memberType = method.computeType(compiler);
        ClassElement contextClass = Types.getClassContext(memberType);
        if (contextClass != null) {
          potentiallyAddForRti(contextClass);
          methodsNeedingRti.add(method);
        }
      }
      compiler.resolverWorld.closurizedGenericMembers.forEach(analyzeMethod);
      compiler.resolverWorld.genericCallMethods.forEach(analyzeMethod);
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
      if (element == compiler.dynamicClass) continue;
      if (checked.contains(element)) {
        result.add(element, element, null);
      }
      // Find all supertypes of [element] in [checkedArguments] and add checks
      // and precompute the substitutions for them.
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
      if (instantiatedType.kind == TypeKind.INTERFACE) {
        Member member =
            instantiatedType.lookupMember(Compiler.CALL_OPERATOR_NAME);
        if (member != null) {
          instantiatedTypes.add(member.computeType(compiler));
        }
      }
    }
    for (FunctionElement element in universe.staticFunctionsNeedingGetter) {
      instantiatedTypes.add(element.computeType(compiler));
    }
    // TODO(johnniwinther): We should get this information through the
    // [neededClasses] computed in the emitter instead of storing it and pulling
    // it from resolution, but currently it would introduce a cyclic dependency
    // between [computeRequiredChecks] and [computeNeededClasses].
    for (Element element in compiler.resolverWorld.closurizedMembers) {
      instantiatedTypes.add(element.computeType(compiler));
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
    for (DartType type in isChecks) {
      functionArgumentCollector.collect(type);
    }

    for (DartType type in instantiatedTypes) {
      directCollector.collect(type);
      if (type.kind == TypeKind.INTERFACE) {
        ClassElement cls = type.element;
        for (DartType supertype in cls.allSupertypes) {
          superCollector.collect(supertype);
        }
      }
    }
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
    for (DartType type in instantiatedTypes) {
      functionArgumentCollector.collect(type);
    }

    for (DartType type in isChecks) {
      collector.collect(type);
    }

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

  /// Return the unique name for the element as an unquoted string.
  String getJsName(Element element) {
    JavaScriptBackend backend = compiler.backend;
    Namer namer = backend.namer;
    return namer.isolateAccess(element);
  }

  String getRawTypeRepresentation(DartType type) {
    String name = getJsName(type.element);
    if (!type.element.isClass()) return name;
    InterfaceType interface = type;
    Link<DartType> variables = interface.element.typeVariables;
    if (variables.isEmpty) return name;
    String arguments =
        new List.filled(variables.slowLength(), 'dynamic').join(', ');
    return '$name<$arguments>';
  }

  // TODO(karlklose): maybe precompute this value and store it in typeChecks?
  bool isTrivialSubstitution(ClassElement cls, ClassElement check) {
    if (cls.isClosure()) {
      // TODO(karlklose): handle closures.
      return true;
    }

    // If there are no type variables or the type is the same, we do not need
    // a substitution.
    if (check.typeVariables.isEmpty || cls == check) {
      return true;
    }

    InterfaceType originalType = cls.computeType(compiler);
    InterfaceType type = originalType.asInstanceOf(check);
    // [type] is not a subtype of [check]. we do not generate a check and do not
    // need a substitution.
    if (type == null) return true;

    // Run through both lists of type variables and check if the type variables
    // are identical at each position. If they are not, we need to calculate a
    // substitution function.
    Link<DartType> variables = cls.typeVariables;
    Link<DartType> arguments = type.typeArguments;
    while (!variables.isEmpty && !arguments.isEmpty) {
      if (variables.head.element != arguments.head.element) {
        return false;
      }
      variables = variables.tail;
      arguments = arguments.tail;
    }
    return (variables.isEmpty == arguments.isEmpty);
  }

  // TODO(karlklose): rewrite to use js.Expressions.
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
  String getSupertypeSubstitution(ClassElement cls, ClassElement check,
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

    bool usesTypeVariables = false;
    String onVariable(TypeVariableType v) {
      usesTypeVariables = true;
      return v.toString();
    };
    InterfaceType type = cls.computeType(compiler);
    InterfaceType target = type.asInstanceOf(check);
    if (cls.typeVariables.isEmpty && !alwaysGenerateFunction) {
      return new Substitution.list(target.typeArguments);
    } else {
      return new Substitution.function(target.typeArguments, cls.typeVariables);
    }
  }

  String getSubstitutionRepresentation(Link<DartType> types,
                                       VariableSubstitution variableName) {
    String code = types.toList(growable: false)
        .map((type) => _getTypeRepresentation(type, variableName))
        .join(', ');
    return '[$code]';
  }

  String getTypeEncoding(DartType type,
                         {bool alwaysGenerateFunction: false}) {
    ClassElement contextClass = Types.getClassContext(type);
    String onVariable(TypeVariableType v) {
      return v.toString();
    };
    String encoding = _getTypeRepresentation(type, onVariable);
    if (contextClass == null && !alwaysGenerateFunction) {
      return encoding;
    } else {
      String parameters = contextClass != null
          ? contextClass.typeVariables.toList().join(', ')
          : '';
      return 'function ($parameters) { return $encoding; }';
    }
  }

  String getSignatureEncoding(DartType type, String generateThis()) {
    ClassElement contextClass = Types.getClassContext(type);
    String encoding = getTypeEncoding(type, alwaysGenerateFunction: true);
    if (contextClass != null) {
      String this_ = generateThis();
      JavaScriptBackend backend = compiler.backend;
      String computeSignature =
          backend.namer.getName(backend.getComputeSignature());
      String contextName = backend.namer.getName(contextClass);
      return 'function () {'
             ' return ${backend.namer.GLOBAL_OBJECT}.'
                  '$computeSignature($encoding, $this_, "$contextName"); '
             '}';
    } else {
      return encoding;
    }
  }

  String getTypeRepresentation(DartType type, VariableSubstitution onVariable) {
    // Create a type representation.  For type variables call the original
    // callback for side effects and return a template placeholder.
    return _getTypeRepresentation(type, (variable) {
      onVariable(variable);
      return '#';
    });
  }

  // TODO(karlklose): rewrite to use js.Expressions.
  String _getTypeRepresentation(DartType type,
                                VariableSubstitution onVariable) {
    return representationGenerator.getTypeRepresentation(type, onVariable);
  }

  static bool hasTypeArguments(DartType type) {
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      return !interfaceType.isRaw;
    }
    return false;
  }

  static int getTypeVariableIndex(TypeVariableElement variable) {
    ClassElement classElement = variable.getEnclosingClass();
    Link<DartType> variables = classElement.typeVariables;
    for (int index = 0; !variables.isEmpty;
         index++, variables = variables.tail) {
      if (variables.head.element == variable) return index;
    }
  }
}

typedef String OnVariableCallback(TypeVariableType type);

class TypeRepresentationGenerator extends DartTypeVisitor {
  final Compiler compiler;
  OnVariableCallback onVariable;
  StringBuffer builder;

  JavaScriptBackend get backend => compiler.backend;
  Namer get namer => backend.namer;

  TypeRepresentationGenerator(Compiler this.compiler);

  /**
   * Creates a type representation for [type]. [onVariable] is called to provide
   * the type representation for type variables.
   */
  String getTypeRepresentation(DartType type, OnVariableCallback onVariable) {
    this.onVariable = onVariable;
    builder = new StringBuffer();
    visit(type);
    String typeRepresentation = builder.toString();
    builder = null;
    this.onVariable = null;
    return typeRepresentation;
  }

  String getJsName(Element element) {
    return namer.isolateAccess(backend.getImplementationClass(element));
  }

  visit(DartType type) {
    type.unalias(compiler).accept(this, null);
  }

  visitTypeVariableType(TypeVariableType type, _) {
    builder.write(onVariable(type));
  }

  visitDynamicType(DynamicType type, _) {
    builder.write('null');
  }

  visitInterfaceType(InterfaceType type, _) {
    String name = getJsName(type.element);
    if (type.isRaw) {
      builder.write(name);
    } else {
      builder.write('[');
      builder.write(name);
      builder.write(', ');
      visitList(type.typeArguments);
      builder.write(']');
    }
  }

  visitList(Link<DartType> types) {
    bool first = true;
    for (Link<DartType> link = types; !link.isEmpty; link = link.tail) {
      if (!first) {
        builder.write(', ');
      }
      visit(link.head);
      first = false;
    }
  }

  visitFunctionType(FunctionType type, _) {
    builder.write('{${namer.functionTypeTag()}:'
                  ' "${namer.getFunctionTypeName(type)}"');
    if (type.returnType.isVoid) {
      builder.write(', ${namer.functionTypeVoidReturnTag()}: true');
    } else if (!type.returnType.isDynamic) {
      builder.write(', ${namer.functionTypeReturnTypeTag()}: ');
      visit(type.returnType);
    }
    if (!type.parameterTypes.isEmpty) {
      builder.write(', ${namer.functionTypeRequiredParametersTag()}: [');
      visitList(type.parameterTypes);
      builder.write(']');
    }
    if (!type.optionalParameterTypes.isEmpty) {
      builder.write(', ${namer.functionTypeOptionalParametersTag()}: [');
      visitList(type.optionalParameterTypes);
      builder.write(']');
    }
    if (!type.namedParameterTypes.isEmpty) {
      builder.write(', ${namer.functionTypeNamedParametersTag()}: {');
      bool first = true;
      Link<SourceString> names = type.namedParameters;
      Link<DartType> types = type.namedParameterTypes;
      while (!types.isEmpty) {
        assert(!names.isEmpty);
        if (!first) {
          builder.write(', ');
        }
        builder.write('${names.head.slowToString()}: ');
        visit(types.head);
        first = false;
        names = names.tail;
        types = types.tail;
      }
      builder.write('}');
    }
    builder.write('}');
  }

  visitMalformedType(MalformedType type, _) {
    // Treat malformed types as dynamic at runtime.
    builder.write('null');
  }

  visitVoidType(VoidType type, _) {
    // TODO(ahe): Reify void type ("null" means "dynamic").
    builder.write('null');
  }

  visitType(DartType type, _) {
    compiler.internalError('Unexpected type: $type (${type.kind})');
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
        sb.write('${holder.name.slowToString()}.'
                 '${check.name.slowToString()}, ');
      }
    }
    return '[$sb]';
  }
}

class ArgumentCollector extends DartTypeVisitor {
  final JavaScriptBackend backend;
  final Set<ClassElement> classes = new Set<ClassElement>();

  ArgumentCollector(this.backend);

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

  visitTypedefType(TypedefType type, bool isTypeArgument) {
    type.unalias(backend.compiler).accept(this, isTypeArgument);
  }

  visitInterfaceType(InterfaceType type, bool isTypeArgument) {
    if (isTypeArgument) {
      classes.add(backend.getImplementationClass(type.element));
    }
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
      classes.add(backend.getImplementationClass(type.element));
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
  final Link<DartType> arguments;
  final Link<TypeVariableType> parameters;

  Substitution.list(this.arguments)
      : isFunction = false,
        parameters = const Link<TypeVariableType>();

  Substitution.function(this.arguments, this.parameters)
      : isFunction = true;

  String getCode(RuntimeTypes rti, bool ensureIsFunction) {
    String variableName(TypeVariableType variable) {
      return variable.name.slowToString();
    }

    String code = rti.getSubstitutionRepresentation(arguments, variableName);
    if (isFunction) {
      String formals = parameters.toList().map(variableName).join(', ');
      return 'function ($formals) { return $code; }';
    } else if (ensureIsFunction) {
      return 'function () { return $code; }';
    } else {
      return code;
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
