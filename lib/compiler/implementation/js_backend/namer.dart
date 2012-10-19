// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Assigns JavaScript identifiers to Dart variables, class-names and members.
 */
class Namer {
  final Compiler compiler;

  static Set<String> _jsReserved = null;
  Set<String> get jsReserved {
    if (_jsReserved == null) {
      _jsReserved = new Set<String>();
      _jsReserved.addAll(JsNames.javaScriptKeywords);
      _jsReserved.addAll(JsNames.reservedPropertySymbols);
    }
    return _jsReserved;
  }

  /**
   * Map from top-level or static elements to their unique identifiers provided
   * by [getName].
   *
   * Invariant: Keys must be declaration elements.
   */
  final Map<Element, String> globals;
  final Map<String, int> usedGlobals;
  final Map<String, LibraryElement> shortPrivateNameOwners;

  final Map<Constant, String> constantNames;

  Namer(this.compiler)
      : globals = new Map<Element, String>(),
        usedGlobals = new Map<String, int>(),
        shortPrivateNameOwners = new Map<String, LibraryElement>(),
        constantNames = new Map<Constant, String>();

  final String CURRENT_ISOLATE = r'$';
  final String ISOLATE = 'Isolate';
  final String ISOLATE_PROPERTIES = r"$isolateProperties";
  /** Some closures must contain their name. The name is stored in
    * [STATIC_CLOSURE_NAME_NAME]. */
  final String STATIC_CLOSURE_NAME_NAME = r'$name';
  static const SourceString CLOSURE_INVOCATION_NAME =
      Compiler.CALL_OPERATOR_NAME;

  String constantName(Constant constant) {
    // In the current implementation it doesn't make sense to give names to
    // function constants since the function-implementation itself serves as
    // constant and can be accessed directly.
    assert(!constant.isFunction());
    String result = constantNames[constant];
    if (result == null) {
      result = getFreshGlobalName("CTC");
      constantNames[constant] = result;
    }
    return result;
  }

  String closureInvocationName(Selector selector) {
    // TODO(floitsch): mangle, while not conflicting with instance names.
    return instanceMethodInvocationName(null, CLOSURE_INVOCATION_NAME,
                                        selector);
  }

  String breakLabelName(LabelElement label) {
    return '\$${label.labelName}\$${label.target.nestingLevel}';
  }

  String implicitBreakLabelName(TargetElement target) {
    return '\$${target.nestingLevel}';
  }

  // We sometimes handle continue targets differently from break targets,
  // so we have special continue-only labels.
  String continueLabelName(LabelElement label) {
    return 'c\$${label.labelName}\$${label.target.nestingLevel}';
  }

  String implicitContinueLabelName(TargetElement target) {
    return 'c\$${target.nestingLevel}';
  }

  String privateName(LibraryElement lib, SourceString name) {
    if (name.isPrivate()) {
      String nameString = name.slowToString();
      // The first library asking for a short private name wins.
      LibraryElement owner =
          shortPrivateNameOwners.putIfAbsent(nameString, () => lib);
      // If a private name could clash with a mangled private name we don't
      // use the short name. For example a private name "_lib3_foo" would
      // clash with "_foo" from "lib3".
      if (identical(owner, lib) && !nameString.startsWith('_$LIBRARY_PREFIX')) {
        return nameString;
      }
      String libName = getName(lib);
      // If a library name does not start with the [LIBRARY_PREFIX] then our
      // assumptions about clashing with mangled private members do not hold.
      assert(libName.startsWith(LIBRARY_PREFIX));
      return '_$libName$nameString';
    } else {
      return name.slowToString();
    }
  }

  String instanceMethodName(FunctionElement element) {
    SourceString name = element.name;
    LibraryElement lib = element.getLibrary();
    if (element.kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY) {
      ConstructorBodyElement bodyElement = element;
      name = bodyElement.constructor.name;
    }
    FunctionSignature signature = element.computeSignature(compiler);
    String methodName =
        '${privateName(lib, name)}\$${signature.parameterCount}';
    if (!signature.optionalParametersAreNamed) {
      return methodName;
    } else if (!signature.optionalParameters.isEmpty()) {
      StringBuffer buffer = new StringBuffer();
      signature.orderedOptionalParameters.forEach((Element element) {
        buffer.add('\$${JsNames.getValid(element.name.slowToString())}');
      });
      return '$methodName$buffer';
    }
  }

  String publicInstanceMethodNameByArity(SourceString name, int arity) {
    assert(!name.isPrivate());
    return '${name.slowToString()}\$$arity';
  }

  String instanceMethodInvocationName(LibraryElement lib, SourceString name,
                                      Selector selector) {
    // TODO(floitsch): mangle, while preserving uniqueness.
    StringBuffer buffer = new StringBuffer();
    List<SourceString> names = selector.getOrderedNamedArguments();
    for (SourceString argumentName in names) {
      buffer.add(r'$');
      argumentName.printOn(buffer);
    }
    return '${privateName(lib, name)}\$${selector.argumentCount}$buffer';
  }

  String instanceFieldName(LibraryElement libraryElement, SourceString name) {
    String proposedName = privateName(libraryElement, name);
    return safeName(proposedName);
  }

  String shadowedFieldName(Element fieldElement) {
    ClassElement cls = fieldElement.getEnclosingClass();
    LibraryElement libraryElement = fieldElement.getLibrary();
    String libName = getName(libraryElement);
    String clsName = getName(cls);
    String instanceName = instanceFieldName(libraryElement, fieldElement.name);
    return safeName('$libName\$$clsName\$$instanceName');
  }

  String setterName(LibraryElement lib, SourceString name) {
    // We dynamically create setters from the field-name. The setter name must
    // therefore be derived from the instance field-name.
    String fieldName = safeName(privateName(lib, name));
    return 'set\$$fieldName';
  }

  String getterName(LibraryElement lib, SourceString name) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    String fieldName = safeName(privateName(lib, name));
    return 'get\$$fieldName';
  }

  String getFreshGlobalName(String proposedName) {
    String name = proposedName;
    int count = usedGlobals[name];
    if (count != null) {
      // Not the first time we see this name. Append a number to make it unique.
      do {
        name = '$proposedName${count++}';
      } while (usedGlobals[name] != null);
      // Record the count in case we see this name later. We
      // frequently see names multiple times, as all our closures use
      // the same name for their class.
      usedGlobals[proposedName] = count;
    }
    usedGlobals[name] = 0;
    return name;
  }

  static const String LIBRARY_PREFIX = "lib";

  /**
   * Returns a preferred JS-id for the given top-level or static element.
   * The returned id is guaranteed to be a valid JS-id.
   */
  String _computeGuess(Element element) {
    assert(!element.isInstanceMember());
    LibraryElement lib = element.getLibrary();
    String name;
    if (element.isGenerativeConstructor()) {
      if (element.name == element.getEnclosingClass().name) {
        // Keep the class name for the class and not the factory.
        name = "${element.name.slowToString()}\$";
      } else {
        name = element.name.slowToString();
      }
    } else if (Elements.isStaticOrTopLevel(element)) {
      if (element.isMember()) {
        ClassElement enclosingClass = element.getEnclosingClass();
        name = "${enclosingClass.name.slowToString()}_"
               "${element.name.slowToString()}";
      } else {
        name = element.name.slowToString();
      }
    } else if (identical(element.kind, ElementKind.LIBRARY)) {
      name = LIBRARY_PREFIX;
    } else {
      name = element.name.slowToString();
    }
    // Prefix the name with '$' if it is reserved.
    return safeName(name);
  }

  String getBailoutName(Element element) {
    return '${getName(element)}\$bailout';
  }

  /**
   * Returns a preferred JS-id for the given element. The returned id is
   * guaranteed to be a valid JS-id. Globals and static fields are furthermore
   * guaranteed to be unique.
   *
   * For accessing statics consider calling
   * [isolateAccess]/[isolateBailoutAccess] or [isolatePropertyAccess] instead.
   */
  String getName(Element element) {
    if (element.isInstanceMember()) {
      if (element.kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY
          || element.kind == ElementKind.FUNCTION) {
        return instanceMethodName(element);
      } else if (element.kind == ElementKind.GETTER) {
        return getterName(element.getLibrary(), element.name);
      } else if (element.kind == ElementKind.SETTER) {
        return setterName(element.getLibrary(), element.name);
      } else if (element.kind == ElementKind.FIELD) {
        return instanceFieldName(element.getLibrary(), element.name);
      } else {
        compiler.internalError('getName for bad kind: ${element.kind}',
                               node: element.parseNode(compiler));
      }
    } else {
      // Use declaration element to ensure invariant on [globals].
      element = element.declaration;

      // Dealing with a top-level or static element.
      String cached = globals[element];
      if (cached != null) return cached;

      String guess = _computeGuess(element);
      ElementKind kind = element.kind;
      if (identical(kind, ElementKind.VARIABLE) ||
          identical(kind, ElementKind.PARAMETER)) {
        // The name is not guaranteed to be unique.
        return guess;
      }
      if (identical(kind, ElementKind.GENERATIVE_CONSTRUCTOR) ||
          identical(kind, ElementKind.FUNCTION) ||
          identical(kind, ElementKind.CLASS) ||
          identical(kind, ElementKind.FIELD) ||
          identical(kind, ElementKind.GETTER) ||
          identical(kind, ElementKind.SETTER) ||
          identical(kind, ElementKind.TYPEDEF) ||
          identical(kind, ElementKind.LIBRARY)) {
        String result = getFreshGlobalName(guess);
        globals[element] = result;
        return result;
      }
      compiler.internalError('getName for unknown kind: ${element.kind}',
                              node: element.parseNode(compiler));
    }
  }

  String getLazyInitializerName(Element element) {
    // TODO(floitsch): mangle while not conflicting with other statics.
    assert(Elements.isStaticOrTopLevelField(element));
    return "get\$${getName(element)}";
  }

  String isolatePropertiesAccess(Element element) {
    return "$ISOLATE.$ISOLATE_PROPERTIES.${getName(element)}";
  }

  String isolatePropertiesAccessForConstant(String constantName) {
    return "$ISOLATE.$ISOLATE_PROPERTIES.$constantName";
  }

  String isolateAccess(Element element) {
    return "$CURRENT_ISOLATE.${getName(element)}";
  }

  String isolateBailoutAccess(Element element) {
    return '${isolateAccess(element)}\$bailout';
  }

  String isolateLazyInitializerAccess(Element element) {
    return "$CURRENT_ISOLATE.${getLazyInitializerName(element)}";
  }

  String operatorIs(Element element) {
    return 'is\$${getName(element)}';
  }

  String safeName(String name) {
    if (jsReserved.contains(name) || name.startsWith('\$')) {
      name = "\$$name";
      assert(!jsReserved.contains(name));
    }
    return name;
  }
}
