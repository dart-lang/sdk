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

class RuntimeTypeInformation {
  final Compiler compiler;
  final TypeRepresentation typeRepresentation;

  RuntimeTypeInformation(Compiler compiler)
      : this.compiler = compiler,
        typeRepresentation = new TypeRepresentation(compiler);

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

  TypeChecks cachedRequiredChecks;

  TypeChecks getRequiredChecks() {
    if (cachedRequiredChecks != null) return cachedRequiredChecks;

    // Get all types used in type arguments of instantiated types.
    Set<ClassElement> instantiatedArguments = getInstantiatedArguments();

    // Collect all type arguments used in is-checks.
    Set<ClassElement> checkedArguments = getCheckedArguments();

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
  Set<ClassElement> getInstantiatedArguments() {
    ArgumentCollector collector = new ArgumentCollector();
    for (DartType type in instantiatedTypes) {
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
  Set<ClassElement> getCheckedArguments() {
    ArgumentCollector collector = new ArgumentCollector();
    for (DartType type in isChecks) {
      collector.collect(type);
    }
    return collector.classes;
  }

  Iterable<DartType> get isChecks {
    return compiler.enqueuer.resolution.universe.isChecks;
  }

  Iterable<DartType> get instantiatedTypes {
    return compiler.codegenWorld.instantiatedTypes;
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
    String arguments = variables.map((_) => 'dynamic').join(', ');
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
    String substitution = target.typeArguments
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
    return typeRepresentation.getTypeRepresentation(type, onVariable);
  }

  static bool hasTypeArguments(DartType type) {
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      return !interfaceType.isRaw;
    }
    return false;
  }

  static int getTypeVariableIndex(TypeVariableType variable) {
    ClassElement classElement = variable.element.getEnclosingClass();
    Link<DartType> variables = classElement.typeVariables;
    for (int index = 0; !variables.isEmpty;
         index++, variables = variables.tail) {
      if (variables.head == variable) return index;
    }
  }
}

typedef String OnVariableCallback(TypeVariableType type);

class TypeRepresentation extends DartTypeVisitor {
  final Compiler compiler;
  OnVariableCallback onVariable;
  StringBuffer builder;

  TypeRepresentation(Compiler this.compiler);

  String getJsName(Element element) {
    JavaScriptBackend backend = compiler.backend;
    Namer namer = backend.namer;
    return namer.isolateAccess(element);
  }

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

  visit(DartType type) {
    type.accept(this, true);
  }

  visitList(Link<DartType> types) {
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

  visitInterfaceType(InterfaceType type, bool isTypeArgument) {
    if (isTypeArgument) {
      classes.add(type.element);
    }
    visitList(type.typeArguments);
  }

  visitFunctionType(FunctionType type, _) {
    visit(type.returnType);
    visitList(type.parameterTypes);
    visitList(type.optionalParameterTypes);
    visitList(type.namedParameterTypes);
  }
}
