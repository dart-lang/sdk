// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/**
 * Assigns JavaScript identifiers to Dart variables, class-names and members.
 */
class Namer implements ClosureNamer {

  static const javaScriptKeywords = const <String>[
    // These are current keywords.
    "break", "delete", "function", "return", "typeof", "case", "do", "if",
    "switch", "var", "catch", "else", "in", "this", "void", "continue",
    "false", "instanceof", "throw", "while", "debugger", "finally", "new",
    "true", "with", "default", "for", "null", "try",

    // These are future keywords.
    "abstract", "double", "goto", "native", "static", "boolean", "enum",
    "implements", "package", "super", "byte", "export", "import", "private",
    "synchronized", "char", "extends", "int", "protected", "throws",
    "class", "final", "interface", "public", "transient", "const", "float",
    "long", "short", "volatile"
  ];

  static const reservedPropertySymbols =
      const <String>["__proto__", "prototype", "constructor"];

  static Set<String> _jsReserved = null;
  Set<String> get jsReserved {
    if (_jsReserved == null) {
      _jsReserved = new Set<String>();
      _jsReserved.addAll(javaScriptKeywords);
      _jsReserved.addAll(reservedPropertySymbols);
    }
    return _jsReserved;
  }

  final String CURRENT_ISOLATE = r'$';

  /**
   * Map from top-level or static elements to their unique identifiers provided
   * by [getName].
   *
   * Invariant: Keys must be declaration elements.
   */
  final Compiler compiler;
  final Map<Element, String> globals;
  final Map<Selector, String> oneShotInterceptorNames;
  final Map<String, LibraryElement> shortPrivateNameOwners;
  final Set<String> usedGlobalNames;
  final Set<String> usedInstanceNames;
  final Map<String, String> globalNameMap;
  final Map<String, String> instanceNameMap;
  final Map<String, String> operatorNameMap;
  final Map<String, int> popularNameCounters;

  /**
   * A cache of names used for bailout methods. We make sure two
   * bailout methods cannot have the same name because if the two
   * bailout methods are in a class and a subclass, we would
   * call the wrong bailout method at runtime. To make it
   * simple, we don't keep track of inheritance and always avoid
   * similar names.
   */
  final Set<String> usedBailoutInstanceNames;
  final Map<Element, String> bailoutNames;

  final Map<Constant, String> constantNames;

  Namer(this.compiler)
      : globals = new Map<Element, String>(),
        oneShotInterceptorNames = new Map<Selector, String>(),
        shortPrivateNameOwners = new Map<String, LibraryElement>(),
        bailoutNames = new Map<Element, String>(),
        usedBailoutInstanceNames = new Set<String>(),
        usedGlobalNames = new Set<String>(),
        usedInstanceNames = new Set<String>(),
        instanceNameMap = new Map<String, String>(),
        operatorNameMap = new Map<String, String>(),
        globalNameMap = new Map<String, String>(),
        constantNames = new Map<Constant, String>(),
        popularNameCounters = new Map<String, int>();

  String get isolateName => 'Isolate';
  String get isolatePropertiesName => r'$isolateProperties';
  /**
   * Some closures must contain their name. The name is stored in
   * [STATIC_CLOSURE_NAME_NAME].
   */
  String get STATIC_CLOSURE_NAME_NAME => r'$name';
  SourceString get closureInvocationSelectorName => Compiler.CALL_OPERATOR_NAME;
  bool get shouldMinify => false;

  bool isReserved(String name) => name == isolateName;

  String constantName(Constant constant) {
    // In the current implementation it doesn't make sense to give names to
    // function constants since the function-implementation itself serves as
    // constant and can be accessed directly.
    assert(!constant.isFunction());
    String result = constantNames[constant];
    if (result == null) {
      String longName;
      if (shouldMinify) {
        if (constant.isString()) {
          StringConstant stringConstant = constant;
          // The minifier always constructs a new name, using the argument as
          // input to its hashing algorithm.  The given name does not need to be
          // valid.
          longName = stringConstant.value.slowToString();
        } else {
          longName = "C";
        }
      } else {
        longName = "CONSTANT";
      }
      result = getFreshName(longName, usedGlobalNames, ensureSafe: true);
      constantNames[constant] = result;
    }
    return result;
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

  /**
   * If the [name] is not private returns [:name.slowToString():]. Otherwise
   * mangles the [name] so that each library has a unique name.
   */
  String privateName(LibraryElement library, SourceString name) {
    // Public names are easy.
    String nameString = name.slowToString();
    if (!name.isPrivate()) return nameString;

    // The first library asking for a short private name wins.
    LibraryElement owner = shouldMinify
        ? library
        : shortPrivateNameOwners.putIfAbsent(nameString, () => library);

    // If a private name could clash with a mangled private name we don't
    // use the short name. For example a private name "_lib3_foo" would
    // clash with "_foo" from "lib3".
    if (owner == library &&
        !nameString.startsWith('_$LIBRARY_PREFIX') &&
        !shouldMinify) {
      return nameString;
    }

    // If a library name does not start with the [LIBRARY_PREFIX] then our
    // assumptions about clashing with mangled private members do not hold.
    String libraryName = getName(library);
    assert(shouldMinify || libraryName.startsWith(LIBRARY_PREFIX));
    // TODO(erikcorry): Fix this with other manglings to avoid clashes.
    return '_lib$libraryName\$$nameString';
  }

  String instanceMethodName(FunctionElement element) {
    SourceString elementName = element.name;
    SourceString name = operatorNameToIdentifier(elementName);
    if (name != elementName) return getMappedOperatorName(name.slowToString());

    LibraryElement library = element.getLibrary();
    if (element.kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY) {
      ConstructorBodyElement bodyElement = element;
      name = bodyElement.constructor.name;
    }
    FunctionSignature signature = element.computeSignature(compiler);
    String methodName =
        '${privateName(library, name)}\$${signature.parameterCount}';
    if (signature.optionalParametersAreNamed &&
        !signature.optionalParameters.isEmpty) {
      StringBuffer buffer = new StringBuffer();
      signature.orderedOptionalParameters.forEach((Element element) {
        buffer.add('\$${safeName(element.name.slowToString())}');
      });
      methodName = '$methodName$buffer';
    }
    if (name == closureInvocationSelectorName) return methodName;
    return getMappedInstanceName(methodName);
  }

  String publicInstanceMethodNameByArity(SourceString name, int arity) {
    SourceString newName = operatorNameToIdentifier(name);
    if (newName != name) return getMappedOperatorName(newName.slowToString());
    assert(!name.isPrivate());
    var base = name.slowToString();
    // We don't mangle the closure invoking function name because it
    // is generated by string concatenation in applyFunction from
    // js_helper.dart.
    var proposedName = '$base\$$arity';
    if (name == closureInvocationSelectorName) return proposedName;
    return getMappedInstanceName(proposedName);
  }

  String invocationName(Selector selector) {
    if (selector.isGetter()) {
      String proposedName = privateName(selector.library, selector.name);
      return 'get\$${getMappedInstanceName(proposedName)}';
    } else if (selector.isSetter()) {
      String proposedName = privateName(selector.library, selector.name);
      return 'set\$${getMappedInstanceName(proposedName)}';
    } else {
      SourceString name = selector.name;
      if (selector.kind == SelectorKind.OPERATOR
          || selector.kind == SelectorKind.INDEX) {
        name = operatorNameToIdentifier(name);
        assert(name != selector.name);
        return getMappedOperatorName(name.slowToString());
      }
      assert(name == operatorNameToIdentifier(name));
      StringBuffer buffer = new StringBuffer();
      for (SourceString argumentName in selector.getOrderedNamedArguments()) {
        buffer.add(r'$');
        argumentName.printOn(buffer);
      }
      String suffix = '\$${selector.argumentCount}$buffer';
      // We don't mangle the closure invoking function name because it
      // is generated by string concatenation in applyFunction from
      // js_helper.dart.
      if (selector.isClosureCall()) {
        return "${name.slowToString()}$suffix";
      } else {
        String proposedName = privateName(selector.library, name);
        return getMappedInstanceName('$proposedName$suffix');
      }
    }
  }

  /**
   * Returns the internal name used for an invocation mirror of this selector.
   */
  String invocationMirrorInternalName(Selector selector)
      => invocationName(selector);

  String instanceFieldName(Element element) {
    String proposedName = privateName(element.getLibrary(), element.name);
    return getMappedInstanceName(proposedName);
  }

  // Construct a new name for the element based on the library and class it is
  // in.  The name here is not important, we just need to make sure it is
  // unique.  If we are minifying, we actually construct the name from the
  // minified versions of the class and instance names, but the result is
  // minified once again, so that is not visible in the end result.
  String shadowedFieldName(Element fieldElement) {
    // Check for following situation: Native field ${fieldElement.name} has
    // fixed JSName ${fieldElement.nativeName()}, but a subclass shadows this
    // name.  We normally handle that by renaming the superclass field, but we
    // can't do that because native fields have fixed JavaScript names.
    // In practice this can't happen because we can't inherit from native
    // classes.
    assert (!fieldElement.hasFixedBackendName());

    String libraryName = getName(fieldElement.getLibrary());
    String className = getName(fieldElement.getEnclosingClass());
    String instanceName = instanceFieldName(fieldElement);
    return getMappedInstanceName('$libraryName\$$className\$$instanceName');
  }

  String setterName(Element element) {
    // We dynamically create setters from the field-name. The setter name must
    // therefore be derived from the instance field-name.
    LibraryElement library = element.getLibrary();
    String name = getMappedInstanceName(privateName(library, element.name));
    return 'set\$$name';
  }

  String setterNameFromAccessorName(String name) {
    // We dynamically create setters from the field-name. The setter name must
    // therefore be derived from the instance field-name.
    return 'set\$$name';
  }

  String publicGetterName(SourceString name) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    String fieldName = getMappedInstanceName(name.slowToString());
    return 'get\$$fieldName';
  }

  String getterNameFromAccessorName(String name) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    return 'get\$$name';
  }

  String getterName(Element element) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    LibraryElement library = element.getLibrary();
    String name = getMappedInstanceName(privateName(library, element.name));
    return 'get\$$name';
  }

  String getMappedGlobalName(String proposedName) {
    var newName = globalNameMap[proposedName];
    if (newName == null) {
      newName = getFreshName(proposedName, usedGlobalNames, ensureSafe: true);
      globalNameMap[proposedName] = newName;
    }
    return newName;
  }

  String getMappedInstanceName(String proposedName) {
    var newName = instanceNameMap[proposedName];
    if (newName == null) {
      newName = getFreshName(proposedName, usedInstanceNames, ensureSafe: true);
      instanceNameMap[proposedName] = newName;
    }
    return newName;
  }

  String getMappedOperatorName(String proposedName) {
    var newName = operatorNameMap[proposedName];
    if (newName == null) {
      newName = getFreshName(
          proposedName, usedInstanceNames, ensureSafe: false);
      operatorNameMap[proposedName] = newName;
    }
    return newName;
  }

  String getFreshName(String proposedName,
                      Set<String> usedNames,
                      {bool ensureSafe: true}) {
    var candidate;
    if (ensureSafe) {
      proposedName = safeName(proposedName);
    }
    assert(!jsReserved.contains(proposedName));
    if (!usedNames.contains(proposedName)) {
      candidate = proposedName;
    } else {
      var counter = popularNameCounters[proposedName];
      var i = counter == null ? 0 : counter;
      while (usedNames.contains("$proposedName$i")) {
        i++;
      }
      popularNameCounters[proposedName] = i + 1;
      candidate = "$proposedName$i";
    }
    usedNames.add(candidate);
    return candidate;
  }

  SourceString getClosureVariableName(SourceString name, int id) {
    return new SourceString("${name.slowToString()}_$id");
  }

  static const String LIBRARY_PREFIX = "lib";

  /**
   * Returns a preferred JS-id for the given top-level or static element.
   * The returned id is guaranteed to be a valid JS-id.
   */
  String _computeGuess(Element element) {
    assert(!element.isInstanceMember());
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
    } else if (element.isLibrary()) {
      name = LIBRARY_PREFIX;
    } else {
      name = element.name.slowToString();
    }
    return name;
  }

  String getInterceptorName(Element element, Collection<ClassElement> classes) {
    if (classes.contains(compiler.objectClass)) {
      // If the object class is in the set of intercepted classes, we
      // need to go through the generic getInterceptorMethod.
      return getName(element);
    }
    // This gets the minified name, but it doesn't really make much difference.
    // The important thing is that it is a unique name.
    StringBuffer buffer = new StringBuffer('${getName(element)}\$');
    for (ClassElement cls in classes) {
      buffer.add(getName(cls));
    }
    return getMappedGlobalName(buffer.toString());
  }

  String getBailoutName(Element element) {
    String name = bailoutNames[element];
    if (name != null) return name;
    bool global = !element.isInstanceMember();
    // Despite the name of the variable, this gets the minified name when we
    // are minifying, but it doesn't really make much difference.  The
    // important thing is that it is a unique name.  We add $bailout and, if we
    // are minifying, we minify the minified name and '$bailout'.
    String unminifiedName = '${getName(element)}\$bailout';
    if (global) {
      name = getMappedGlobalName(unminifiedName);
    } else {
      name = unminifiedName;
      int i = 0;
      while (usedBailoutInstanceNames.contains(name)) {
        name = '$unminifiedName${i++}';
      }
      usedBailoutInstanceNames.add(name);
      name = getMappedInstanceName(name);
    }
    bailoutNames[element] = name;
    return name;
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
        return getterName(element);
      } else if (element.kind == ElementKind.SETTER) {
        return setterName(element);
      } else if (element.kind == ElementKind.FIELD) {
        return instanceFieldName(element);
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
      if (kind == ElementKind.VARIABLE ||
          kind == ElementKind.PARAMETER) {
        // The name is not guaranteed to be unique.
        return safeName(guess);
      }
      if (kind == ElementKind.GENERATIVE_CONSTRUCTOR ||
          kind == ElementKind.FUNCTION ||
          kind == ElementKind.CLASS ||
          kind == ElementKind.FIELD ||
          kind == ElementKind.GETTER ||
          kind == ElementKind.SETTER ||
          kind == ElementKind.TYPEDEF ||
          kind == ElementKind.LIBRARY ||
          kind == ElementKind.MALFORMED_TYPE) {
        bool fixedName = false;
        if (kind == ElementKind.CLASS) {
          ClassElement classElement = element;
        }
        if (Elements.isInstanceField(element)) {
          fixedName = element.hasFixedBackendName();
        }
        String result = fixedName
            ? guess
            : getFreshName(guess, usedGlobalNames, ensureSafe: true);
        globals[element] = result;
        return result;
      }
      compiler.internalError('getName for unknown kind: ${element.kind}',
                              node: element.parseNode(compiler));
    }
  }

  String getLazyInitializerName(Element element) {
    assert(Elements.isStaticOrTopLevelField(element));
    return getMappedGlobalName("get\$${getName(element)}");
  }

  String isolatePropertiesAccess(Element element) {
    return "$isolateName.$isolatePropertiesName.${getName(element)}";
  }

  String isolateAccess(Element element) {
    return "$CURRENT_ISOLATE.${getName(element)}";
  }

  String isolateBailoutAccess(Element element) {
    String newName = getMappedGlobalName('${getName(element)}\$bailout');
    return '$CURRENT_ISOLATE.$newName';
  }

  String isolateLazyInitializerAccess(Element element) {
    return "$CURRENT_ISOLATE.${getLazyInitializerName(element)}";
  }

  String operatorIsPrefix() => r'$is';

  String operatorIs(Element element) {
    // TODO(erikcorry): Reduce from $isx to ix when we are minifying.
    return '${operatorIsPrefix()}${getName(element)}';
  }

  /*
   * Returns a name that does not clash with reserved JS keywords,
   * and also ensures it won't clash with other identifiers.
   */
  String safeName(String name) {
    if (jsReserved.contains(name) || name.startsWith(r'$')) {
      name = '\$$name';
    }
    assert(!jsReserved.contains(name));
    return name;
  }

  String oneShotInterceptorName(Selector selector) {
    // TODO(ngeoffray): What to do about typed selectors? We could
    // filter them out, or keep them and hope the generated one shot
    // interceptor takes advantage of the type.
    String cached = oneShotInterceptorNames[selector];
    if (cached != null) return cached;
    SourceString name = operatorNameToIdentifier(selector.name);
    String result = getFreshName(name.slowToString(), usedGlobalNames);
    oneShotInterceptorNames[selector] = result;
    return result;
  }

  SourceString operatorNameToIdentifier(SourceString name) {
    if (name == null) return null;
    String value = name.stringValue;
    if (value == null) {
      return name;
    } else if (value == '==') {
      return const SourceString(r'$eq');
    } else if (value == '~') {
      return const SourceString(r'$not');
    } else if (value == '[]') {
      return const SourceString(r'$index');
    } else if (value == '[]=') {
      return const SourceString(r'$indexSet');
    } else if (value == '*') {
      return const SourceString(r'$mul');
    } else if (value == '/') {
      return const SourceString(r'$div');
    } else if (value == '%') {
      return const SourceString(r'$mod');
    } else if (value == '~/') {
      return const SourceString(r'$tdiv');
    } else if (value == '+') {
      return const SourceString(r'$add');
    } else if (value == '<<') {
      return const SourceString(r'$shl');
    } else if (value == '>>') {
      return const SourceString(r'$shr');
    } else if (value == '>=') {
      return const SourceString(r'$ge');
    } else if (value == '>') {
      return const SourceString(r'$gt');
    } else if (value == '<=') {
      return const SourceString(r'$le');
    } else if (value == '<') {
      return const SourceString(r'$lt');
    } else if (value == '&') {
      return const SourceString(r'$and');
    } else if (value == '^') {
      return const SourceString(r'$xor');
    } else if (value == '|') {
      return const SourceString(r'$or');
    } else if (value == '-') {
      return const SourceString(r'$sub');
    } else if (value == 'unary-') {
      return const SourceString(r'$negate');
    } else {
      return name;
    }
  }
}
