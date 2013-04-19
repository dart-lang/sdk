// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/// For each class, stores the possible class subtype tests that could succeed.
abstract class TypeChecks {
  /// Get the set of checks required for class [element].
  Iterable<ClassElement> operator[](ClassElement element);
  /// Get the iterator for all classes that need type checks.
  Iterator<ClassElement> get iterator;
}

class RuntimeTypes {
  final Compiler compiler;
  final TypeRepresentationGenerator representationGenerator;

  final Map<ClassElement, Set<ClassElement>> rtiDependencies;
  final Set<ClassElement> classesNeedingRti;
  // The set of classes that use one of their type variables as expressions
  // to get the runtime type.
  final Set<ClassElement> classesUsingTypeVariableExpression;

  JavaScriptBackend get backend => compiler.backend;

  RuntimeTypes(Compiler compiler)
      : this.compiler = compiler,
        representationGenerator = new TypeRepresentationGenerator(compiler),
        classesNeedingRti = new Set<ClassElement>(),
        rtiDependencies = new Map<ClassElement, Set<ClassElement>>(),
        classesUsingTypeVariableExpression = new Set<ClassElement>();

  /// Contains the classes of all arguments that have been used in
  /// instantiations and checks.
  Set<ClassElement> allArguments;

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
    if (universe.usingFactoryWithTypeArguments) {
      for (DartType type in universe.instantiatedTypes) {
        if (type.kind != TypeKind.INTERFACE) continue;
        InterfaceType interface = type;
        for (DartType argument in interface.typeArguments) {
          universe.isChecks.add(argument);
        }
      }
    } else {
      // Find all instantiated types that are a subtype of a class that uses
      // one of its type arguments in an is-check and add the arguments to the
      // set of is-checks.
      // TODO(karlklose): replace this with code that uses a subtype lookup
      // datastructure in the world.
      for (DartType type in universe.instantiatedTypes) {
        if (type.kind != TypeKind.INTERFACE) continue;
        InterfaceType classType = type;
        for (ClassElement cls in classesUsingChecks) {
          // We need the type as instance of its superclass anyway, so we just
          // try to compute the substitution; if the result is [:null:], the
          // classes are not related.
          InterfaceType instance = classType.asInstanceOf(cls);
          if (instance == null) continue;
          Link<DartType> typeArguments = instance.typeArguments;
          for (DartType argument in typeArguments) {
            universe.isChecks.add(argument);
          }
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
      Set<ClassElement> classes = compiler.world.subtypes[cls];
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
    // Compute the set of all classes that need runtime type information.
    compiler.resolverWorld.isChecks.forEach((DartType type) {
      if (type.kind == TypeKind.INTERFACE) {
        InterfaceType itf = type;
        if (!itf.isRaw) {
          potentiallyAddForRti(itf.element);
        }
      } else if (type.kind == TypeKind.TYPE_VARIABLE) {
        TypeVariableElement variable = type.element;
        potentiallyAddForRti(variable.enclosingElement);
      }
    });
    // Add the classes that need RTI because they use a type variable as
    // expression.
    classesUsingTypeVariableExpression.forEach(potentiallyAddForRti);
  }

  TypeChecks cachedRequiredChecks;

  TypeChecks getRequiredChecks() {
    if (cachedRequiredChecks != null) return cachedRequiredChecks;

    // Get all types used in type arguments of instantiated types.
    Set<ClassElement> instantiatedArguments =
        getInstantiatedArguments(compiler.codegenWorld);

    // Collect all type arguments used in is-checks.
    Set<ClassElement> checkedArguments =
        getCheckedArguments(compiler.codegenWorld);

    // Precompute the set of all seen type arguments for use in the emitter.
    allArguments = new Set<ClassElement>.from(instantiatedArguments)
        ..addAll(checkedArguments);

    // Finally, run through the combination of instantiated and checked
    // arguments and record all combination where the element of a checked
    // argument is a superclass of the element of an instantiated type.
    TypeCheckMapping requiredChecks = new TypeCheckMapping();
    for (ClassElement element in instantiatedArguments) {
      if (element == compiler.dynamicClass) continue;
      if (checkedArguments.contains(element)) {
        requiredChecks.add(element, element);
      }
      // Find all supertypes of [element] in [checkedArguments] and add checks.
      for (DartType supertype in element.allSupertypes) {
        ClassElement superelement = supertype.element;
        if (checkedArguments.contains(superelement)) {
          requiredChecks.add(element, superelement);
        }
      }
    }

    return cachedRequiredChecks = requiredChecks;
  }

  /**
   * Collects all types used in type arguments of instantiated types.
   *
   * This includes type arguments used in supertype relations, because we may
   * have a type check against this supertype that includes a check against
   * the type arguments.
   */
  Set<ClassElement> getInstantiatedArguments(Universe universe) {
    ArgumentCollector collector = new ArgumentCollector();
    for (DartType type in universe.instantiatedTypes) {
      collector.collect(type);
      ClassElement cls = type.element;
      for (DartType supertype in cls.allSupertypes) {
        collector.collect(supertype);
      }
    }
    for (ClassElement cls in collector.classes.toList()) {
      for (DartType supertype in cls.allSupertypes) {
        collector.collect(supertype);
      }
    }
    return collector.classes;
  }

  /// Collects all type arguments used in is-checks.
  Set<ClassElement> getCheckedArguments(Universe universe) {
    ArgumentCollector collector = new ArgumentCollector();
    for (DartType type in universe.isChecks) {
      collector.collect(type);
    }
    return collector.classes;
  }

  /// Return the unique name for the element as an unquoted string.
  String getNameAsString(Element element) {
    JavaScriptBackend backend = compiler.backend;
    return backend.namer.getName(element);
  }

  /// Return the unique JS name for the element, which is a quoted string for
  /// native classes and the isolate acccess to the constructor for classes.
  String getJsName(Element element) {
    JavaScriptBackend backend = compiler.backend;
    Namer namer = backend.namer;
    return namer.isolateAccess(element);
  }

  String getRawTypeRepresentation(DartType type) {
    String name = getNameAsString(type.element);
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
    if (isTrivialSubstitution(cls, check)) return null;

    // TODO(karlklose): maybe precompute this value and store it in typeChecks?
    bool usesTypeVariables = false;
    String onVariable(TypeVariableType v) {
      usesTypeVariables = true;
      return v.toString();
    };
    InterfaceType type = cls.computeType(compiler);
    InterfaceType target = type.asInstanceOf(check);
    String substitution = target.typeArguments.toList()
        .map((type) => _getTypeRepresentation(type, onVariable))
        .join(', ');
    substitution = '[$substitution]';
    if (!usesTypeVariables && !alwaysGenerateFunction) {
      return substitution;
    } else {
      String parameters = cls.typeVariables.toList().join(', ');
      return 'function ($parameters) { return $substitution; }';
    }
  }

  String getTypeRepresentation(DartType type, void onVariable(variable)) {
    // Create a type representation.  For type variables call the original
    // callback for side effects and return a template placeholder.
    return _getTypeRepresentation(type, (variable) {
      onVariable(variable);
      return '#';
    });
  }

  // TODO(karlklose): rewrite to use js.Expressions.
  String _getTypeRepresentation(DartType type, String onVariable(variable)) {
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
    JavaScriptBackend backend = compiler.backend;
    Namer namer = backend.namer;
    return namer.isolateAccess(element);
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
    builder.write('{func: true');
    if (type.returnType.isVoid) {
      builder.write(', retvoid: true');
    } else if (!type.returnType.isDynamic) {
      builder.write(', ret: ');
      visit(type.returnType);
    }
    if (!type.parameterTypes.isEmpty) {
      builder.write(', args: [');
      visitList(type.parameterTypes);
      builder.write(']');
    }
    if (!type.optionalParameterTypes.isEmpty) {
      builder.write(', opt: [');
      visitList(type.optionalParameterTypes);
      builder.write(']');
    }
    if (!type.namedParameterTypes.isEmpty) {
      builder.write(', named: {');
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

  visitType(DartType type, _) {
    compiler.internalError('Unexpected type: $type');
  }
}

class TypeCheckMapping implements TypeChecks {
  final Map<ClassElement, Set<ClassElement>> map =
      new Map<ClassElement, Set<ClassElement>>();

  Iterable<ClassElement> operator[](ClassElement element) {
    Set<ClassElement> result = map[element];
    return result != null ? result : const <ClassElement>[];
  }

  void add(ClassElement cls, ClassElement check) {
    map.putIfAbsent(cls, () => new Set<ClassElement>());
    map[cls].add(check);
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
  final Set<ClassElement> classes = new Set<ClassElement>();

  collect(DartType type) {
    type.accept(this, false);
  }

  visitType(DartType type, _) {
    // Do nothing.
  }

  visitDynamicType(DynamicType type, _) {
    // Do not collect [:dynamic:].
  }

  visitInterfaceType(InterfaceType type, bool isTypeArgument) {
    if (isTypeArgument) {
      classes.add(type.element);
    }
    type.visitChildren(this, true);
  }

  visitFunctionType(FunctionType type, _) {
    type.visitChildren(this, true);
  }
}
