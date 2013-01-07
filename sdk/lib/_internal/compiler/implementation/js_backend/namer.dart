// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/**
 * Assigns JavaScript identifiers to Dart variables, class-names and members.
 */
class Namer implements ClosureNamer {
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
  final Map<String, String> globalNameMap;
  final Map<String, String> instanceNameMap;
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
        shortPrivateNameOwners = new Map<String, LibraryElement>(),
        bailoutNames = new Map<Element, String>(),
        usedBailoutInstanceNames = new Set<String>(),
        usedGlobalNames = new Set<String>(),
        usedInstanceNames = new Set<String>(),
        instanceNameMap = new Map<String, String>(),
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
      result = getFreshName(longName, usedGlobalNames);
      constantNames[constant] = result;
    }
    return result;
  }

  String closureInvocationName(Selector selector) {
    return instanceMethodInvocationName(null, closureInvocationSelectorName,
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

  /**
   * If the [name] is not private returns [:name.slowToString():]. Otherwise
   * mangles the [name] so that each library has a unique name.
   */
  String privateName(LibraryElement lib, SourceString name) {
    String result;
    if (name.isPrivate()) {
      String nameString = name.slowToString();
      // The first library asking for a short private name wins.
      LibraryElement owner = shouldMinify ?
          lib :
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
    SourceString name = Elements.operatorNameToIdentifier(element.name);
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
    if (name == closureInvocationSelectorName) return methodName;
    return getMappedInstanceName(methodName);
  }

  String publicInstanceMethodNameByArity(SourceString name, int arity) {
    name = Elements.operatorNameToIdentifier(name);
    assert(!name.isPrivate());
    var base = name.slowToString();
    // We don't mangle the closure invoking function name because it is
    // generated in by string concatenation applyFunction from js_helper.dart.
    var proposedName = '$base\$$arity';
    if (base == closureInvocationSelectorName) return proposedName;
    return getMappedInstanceName(proposedName);
  }

  String instanceMethodInvocationName(LibraryElement lib, SourceString name,
                                      Selector selector) {
    name = Elements.operatorNameToIdentifier(name);
    // TODO(floitsch): mangle, while preserving uniqueness.
    StringBuffer buffer = new StringBuffer();
    List<SourceString> names = selector.getOrderedNamedArguments();
    for (SourceString argumentName in names) {
      buffer.add(r'$');
      argumentName.printOn(buffer);
    }
    if (name == closureInvocationSelectorName) {
    // We don't mangle the closure invoking function name because it is
    // generated in by string concatenation applyFunction from js_helper.dart.
      return '$closureInvocationSelectorName\$${selector.argumentCount}$buffer';
    }
    return getMappedInstanceName(
        '${privateName(lib, name)}\$${selector.argumentCount}$buffer');
  }

  /**
   * Returns the internal name used for an invocation mirror of this selector.
   */
  String invocationMirrorInternalName(Selector selector) {
    if (selector.isGetter()) {
      return getterName(selector.library, selector.name);
    } else if (selector.isSetter()) {
      return setterName(selector.library, selector.name);
    } else {
      return instanceMethodInvocationName(
          selector.library, selector.name, selector);
    }
  }

  String instanceFieldName(LibraryElement libraryElement, SourceString name) {
    String proposedName = privateName(libraryElement, name);
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
    // can't do that because native fields have fixed JsNames.  In practice
    // this can't happen because we can't inherit from native classes.
    assert (!fieldElement.hasFixedBackendName());

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
    return name;
  }

  String getSpecializedName(Element element, Collection<ClassElement> classes) {
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
        String result =
            fixedName ? guess : getFreshName(guess, usedGlobalNames);
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
