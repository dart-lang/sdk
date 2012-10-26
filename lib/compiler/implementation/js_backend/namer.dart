// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/**
 * Assigns JavaScript identifiers to Dart variables, class-names and members.
 */
class Namer {
  static Set<String> _jsReserved = null;
  Set<String> get jsReserved {
    if (_jsReserved == null) {
      _jsReserved = new Set<String>();
      _jsReserved.addAll(JsNames.javaScriptKeywords);
      _jsReserved.addAll(JsNames.reservedPropertySymbols);
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
  final Map<String, LibraryElement> shortPrivateNameOwners;
  final Set<String> usedGlobalNames;
  final Set<String> usedInstanceNames;
  final Map<String, String> instanceNameMap;
  final Map<String, String> globalNameMap;
  final Map<String, int> popularNameCounters;

  final Map<Constant, String> constantNames;

  Namer(this.compiler)
      : globals = new Map<Element, String>(),
        shortPrivateNameOwners = new Map<String, LibraryElement>(),
        usedGlobalNames = new Set<String>(),
        usedInstanceNames = new Set<String>(),
        instanceNameMap = new Map<String, String>(),
        globalNameMap = new Map<String, String>(),
        constantNames = new Map<Constant, String>(),
        popularNameCounters = new Map<String, int>();

  String get ISOLATE => 'Isolate';
  String get ISOLATE_PROPERTIES => r'$isolateProperties';
  /** Some closures must contain their name. The name is stored in
    * [STATIC_CLOSURE_NAME_NAME]. */
  String get STATIC_CLOSURE_NAME_NAME => r'$name';
  SourceString get CLOSURE_INVOCATION_NAME => Compiler.CALL_OPERATOR_NAME;
  bool get shouldMinify => false;

  bool isReserved(String name) => name == ISOLATE;

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
          longName = stringConstant.value.slowToString();
        } else {
          longName = "C";
        }
      } else {
        longName = "CTC";
      }
      result = getFreshName(longName, usedGlobalNames);
      constantNames[constant] = result;
    }
    return result;
  }

  String closureInvocationName(Selector selector) {
    return
        instanceMethodInvocationName(null, CLOSURE_INVOCATION_NAME, selector);
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
  String privateName(LibraryElement lib, SourceString name) {
    String result;
    if (name.isPrivate()) {
      String nameString = name.slowToString();
      // The first library asking for a short private name wins.
      LibraryElement owner =
          shortPrivateNameOwners.putIfAbsent(nameString, () => lib);
      // If a private name could clash with a mangled private name we don't
      // use the short name. For example a private name "_lib3_foo" would
      // clash with "_foo" from "lib3".
      if (owner == lib &&
          !nameString.startsWith('_$LIBRARY_PREFIX') &&
          !shouldMinify) {
        result = nameString;
      } else {
        String libName = getName(lib);
        // If a library name does not start with the [LIBRARY_PREFIX] then our
        // assumptions about clashing with mangled private members do not hold.
        assert(shouldMinify || libName.startsWith(LIBRARY_PREFIX));
        // TODO(erikcorry): Fix this with other manglings to avoid clashes.
        result = '_lib$libName\$$nameString';
      }
    } else {
      result = name.slowToString();
    }
    return result;
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
    if (signature.optionalParametersAreNamed &&
        !signature.optionalParameters.isEmpty) {
      StringBuffer buffer = new StringBuffer();
      signature.orderedOptionalParameters.forEach((Element element) {
        buffer.add('\$${JsNames.getValid(element.name.slowToString())}');
      });
      methodName = '$methodName$buffer';
    }
    return getMappedInstanceName(methodName);
  }

  String publicInstanceMethodNameByArity(SourceString name, int arity) {
    assert(!name.isPrivate());
    var proposedName = '${name.slowToString()}\$$arity';
    return getMappedInstanceName(proposedName);
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
    return getMappedInstanceName(
        '${privateName(lib, name)}\$${selector.argumentCount}$buffer');
  }

  String instanceFieldName(LibraryElement libraryElement, SourceString name) {
    String proposedName = privateName(libraryElement, name);
    return getMappedInstanceName(proposedName);
  }

  String shadowedFieldName(Element fieldElement) {
    ClassElement cls = fieldElement.getEnclosingClass();
    LibraryElement libraryElement = fieldElement.getLibrary();
    String libName = getName(libraryElement);
    String clsName = getName(cls);
    String instanceName = instanceFieldName(libraryElement, fieldElement.name);
    return getMappedInstanceName('$libName\$$clsName\$$instanceName');
  }

  String setterName(LibraryElement lib, SourceString name) {
    // We dynamically create setters from the field-name. The setter name must
    // therefore be derived from the instance field-name.
    String fieldName = getMappedInstanceName(privateName(lib, name));
    return 'set\$$fieldName';
  }

  String publicGetterName(SourceString name) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    String fieldName = getMappedInstanceName(name.slowToString());
    return 'get\$$fieldName';
  }

  String getterName(LibraryElement lib, SourceString name) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    String fieldName = getMappedInstanceName(privateName(lib, name));
    return 'get\$$fieldName';
  }

  String getMappedGlobalName(String proposedName) {
    var newName = globalNameMap[proposedName];
    if (newName == null) {
      newName = getFreshName(proposedName, usedGlobalNames);
      globalNameMap[proposedName] = newName;
    }
    return newName;
  }

  String getMappedInstanceName(String proposedName) {
    var newName = instanceNameMap[proposedName];
    if (newName == null) {
      newName = getFreshName(proposedName, usedInstanceNames);
      instanceNameMap[proposedName] = newName;
    }
    return newName;
  }

  String getFreshName(String proposedName, Set<String> usedNames) {
    var candidate;
    proposedName = safeName(proposedName);
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
    } else if (element.isLibrary()) {
      name = LIBRARY_PREFIX;
    } else {
      name = element.name.slowToString();
    }
    // Prefix the name with '$' if it is reserved.
    return name;
  }

  String getBailoutName(Element element) {
    bool global = !element.isInstanceMember();
    var unminifiedName = '${getName(element)}\$bailout';
    if (global) {
      return getMappedGlobalName(unminifiedName);
    } else {
      return getMappedInstanceName(unminifiedName);
    }
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
        return safeName(guess);
      }
      if (kind == ElementKind.GENERATIVE_CONSTRUCTOR ||
          kind == ElementKind.FUNCTION ||
          kind == ElementKind.CLASS ||
          kind == ElementKind.FIELD ||
          kind == ElementKind.GETTER ||
          kind == ElementKind.SETTER ||
          kind == ElementKind.TYPEDEF ||
          kind == ElementKind.LIBRARY) {
        bool isNative = false;
        if (identical(kind, ElementKind.CLASS)) {
          ClassElement class_elt = element;
          isNative = class_elt.isNative();
        }
        if (Elements.isInstanceField(element)) {
          isNative = element.isNative();
        }
        String result = isNative ? guess : getFreshName(guess, usedGlobalNames);
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
    return "$ISOLATE.$ISOLATE_PROPERTIES.${getName(element)}";
  }

  String isolatePropertiesAccessForConstant(String constantName) {
    return "$ISOLATE.$ISOLATE_PROPERTIES.$constantName";
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

  String operatorIs(Element element) {
    // TODO(erikcorry): Reduce from is$x to ix when we are minifying.
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
