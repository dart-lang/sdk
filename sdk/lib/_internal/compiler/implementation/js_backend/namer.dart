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
      const <String>["__proto__", "prototype", "constructor", "call"];

  // Symbols that we might be using in our JS snippets.
  static const reservedGlobalSymbols = const <String>[
    // Section references are from Ecma-262
    // (http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-262.pdf)

    // 15.1.1 Value Properties of the Global Object
    "NaN", "Infinity", "undefined",

    // 15.1.2 Function Properties of the Global Object
    "eval", "parseInt", "parseFloat", "isNaN", "isFinite",

    // 15.1.3 URI Handling Function Properties
    "decodeURI", "decodeURIComponent",
    "encodeURI",
    "encodeURIComponent",

    // 15.1.4 Constructor Properties of the Global Object
    "Object", "Function", "Array", "String", "Boolean", "Number", "Date",
    "RegExp", "Error", "EvalError", "RangeError", "ReferenceError",
    "SyntaxError", "TypeError", "URIError",

    // 15.1.5 Other Properties of the Global Object
    "Math",

    // 10.1.6 Activation Object
    "arguments",

    // B.2 Additional Properties (non-normative)
    "escape", "unescape",

    // Window props (https://developer.mozilla.org/en/DOM/window)
    "applicationCache", "closed", "Components", "content", "controllers",
    "crypto", "defaultStatus", "dialogArguments", "directories",
    "document", "frameElement", "frames", "fullScreen", "globalStorage",
    "history", "innerHeight", "innerWidth", "length",
    "location", "locationbar", "localStorage", "menubar",
    "mozInnerScreenX", "mozInnerScreenY", "mozScreenPixelsPerCssPixel",
    "name", "navigator", "opener", "outerHeight", "outerWidth",
    "pageXOffset", "pageYOffset", "parent", "personalbar", "pkcs11",
    "returnValue", "screen", "scrollbars", "scrollMaxX", "scrollMaxY",
    "self", "sessionStorage", "sidebar", "status", "statusbar", "toolbar",
    "top", "window",

    // Window methods (https://developer.mozilla.org/en/DOM/window)
    "alert", "addEventListener", "atob", "back", "blur", "btoa",
    "captureEvents", "clearInterval", "clearTimeout", "close", "confirm",
    "disableExternalCapture", "dispatchEvent", "dump",
    "enableExternalCapture", "escape", "find", "focus", "forward",
    "GeckoActiveXObject", "getAttention", "getAttentionWithCycleCount",
    "getComputedStyle", "getSelection", "home", "maximize", "minimize",
    "moveBy", "moveTo", "open", "openDialog", "postMessage", "print",
    "prompt", "QueryInterface", "releaseEvents", "removeEventListener",
    "resizeBy", "resizeTo", "restore", "routeEvent", "scroll", "scrollBy",
    "scrollByLines", "scrollByPages", "scrollTo", "setInterval",
    "setResizeable", "setTimeout", "showModalDialog", "sizeToContent",
    "stop", "uuescape", "updateCommands", "XPCNativeWrapper",
    "XPCSafeJSOjbectWrapper",

    // Mozilla Window event handlers, same cite
    "onabort", "onbeforeunload", "onchange", "onclick", "onclose",
    "oncontextmenu", "ondragdrop", "onerror", "onfocus", "onhashchange",
    "onkeydown", "onkeypress", "onkeyup", "onload", "onmousedown",
    "onmousemove", "onmouseout", "onmouseover", "onmouseup",
    "onmozorientation", "onpaint", "onreset", "onresize", "onscroll",
    "onselect", "onsubmit", "onunload",

    // Safari Web Content Guide
    // http://developer.apple.com/library/safari/#documentation/AppleApplications/Reference/SafariWebContent/SafariWebContent.pdf
    // WebKit Window member data, from WebKit DOM Reference
    // (http://developer.apple.com/safari/library/documentation/AppleApplications/Reference/WebKitDOMRef/DOMWindow_idl/Classes/DOMWindow/index.html)
    "ontouchcancel", "ontouchend", "ontouchmove", "ontouchstart",
    "ongesturestart", "ongesturechange", "ongestureend",

    // extra window methods
    "uneval",

    // keywords https://developer.mozilla.org/en/New_in_JavaScript_1.7,
    // https://developer.mozilla.org/en/New_in_JavaScript_1.8.1
    "getPrototypeOf", "let", "yield",

    // "future reserved words"
    "abstract", "int", "short", "boolean", "interface", "static", "byte",
    "long", "char", "final", "native", "synchronized", "float", "package",
    "throws", "goto", "private", "transient", "implements", "protected",
    "volatile", "double", "public",

    // IE methods
    // (http://msdn.microsoft.com/en-us/library/ms535873(VS.85).aspx#)
    "attachEvent", "clientInformation", "clipboardData", "createPopup",
    "dialogHeight", "dialogLeft", "dialogTop", "dialogWidth",
    "onafterprint", "onbeforedeactivate", "onbeforeprint",
    "oncontrolselect", "ondeactivate", "onhelp", "onresizeend",

    // Common browser-defined identifiers not defined in ECMAScript
    "event", "external", "Debug", "Enumerator", "Global", "Image",
    "ActiveXObject", "VBArray", "Components",

    // Functions commonly defined on Object
    "toString", "getClass", "constructor", "prototype", "valueOf",

    // Client-side JavaScript identifiers
    "Anchor", "Applet", "Attr", "Canvas", "CanvasGradient",
    "CanvasPattern", "CanvasRenderingContext2D", "CDATASection",
    "CharacterData", "Comment", "CSS2Properties", "CSSRule",
    "CSSStyleSheet", "Document", "DocumentFragment", "DocumentType",
    "DOMException", "DOMImplementation", "DOMParser", "Element", "Event",
    "ExternalInterface", "FlashPlayer", "Form", "Frame", "History",
    "HTMLCollection", "HTMLDocument", "HTMLElement", "IFrame", "Image",
    "Input", "JSObject", "KeyEvent", "Link", "Location", "MimeType",
    "MouseEvent", "Navigator", "Node", "NodeList", "Option", "Plugin",
    "ProcessingInstruction", "Range", "RangeException", "Screen", "Select",
    "Table", "TableCell", "TableRow", "TableSelection", "Text", "TextArea",
    "UIEvent", "Window", "XMLHttpRequest", "XMLSerializer",
    "XPathException", "XPathResult", "XSLTProcessor",

    // These keywords trigger the loading of the java-plugin. For the
    // next-generation plugin, this results in starting a new Java process.
    "java", "Packages", "netscape", "sun", "JavaObject", "JavaClass",
    "JavaArray", "JavaMember"
  ];

  Set<String> _jsReserved = null;
  /// Names that cannot be used by members, top level and static
  /// methods.
  Set<String> get jsReserved {
    if (_jsReserved == null) {
      _jsReserved = new Set<String>();
      _jsReserved.addAll(javaScriptKeywords);
      _jsReserved.addAll(reservedPropertySymbols);
    }
    return _jsReserved;
  }

  Set<String> _jsVariableReserved = null;
  /// Names that cannot be used by local variables and parameters.
  Set<String> get jsVariableReserved {
    if (_jsVariableReserved == null) {
      _jsVariableReserved = new Set<String>();
      _jsVariableReserved.addAll(javaScriptKeywords);
      _jsVariableReserved.addAll(reservedPropertySymbols);
      _jsVariableReserved.addAll(reservedGlobalSymbols);
    }
    return _jsVariableReserved;
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
  final Map<String, String> suggestedGlobalNames;
  final Map<String, String> instanceNameMap;
  final Map<String, String> suggestedInstanceNames;
      
  final Map<String, String> operatorNameMap;
  final Map<String, int> popularNameCounters;

  final Map<Element, String> bailoutNames;

  final Map<Constant, String> constantNames;

  Namer(this.compiler)
      : globals = new Map<Element, String>(),
        oneShotInterceptorNames = new Map<Selector, String>(),
        shortPrivateNameOwners = new Map<String, LibraryElement>(),
        bailoutNames = new Map<Element, String>(),
        usedGlobalNames = new Set<String>(),
        usedInstanceNames = new Set<String>(),
        instanceNameMap = new Map<String, String>(),
        operatorNameMap = new Map<String, String>(),
        globalNameMap = new Map<String, String>(),
        suggestedGlobalNames = new Map<String, String>(),
        suggestedInstanceNames = new Map<String, String>(),
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
      result = getFreshName(longName, usedGlobalNames, suggestedGlobalNames,
                            ensureSafe: true);
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
      newName = getFreshName(proposedName, usedGlobalNames,
                             suggestedGlobalNames, ensureSafe: true);
      globalNameMap[proposedName] = newName;
    }
    return newName;
  }

  String getMappedInstanceName(String proposedName) {
    var newName = instanceNameMap[proposedName];
    if (newName == null) {
      newName = getFreshName(proposedName, usedInstanceNames,
                             suggestedInstanceNames, ensureSafe: true);
      instanceNameMap[proposedName] = newName;
    }
    return newName;
  }

  String getMappedOperatorName(String proposedName) {
    var newName = operatorNameMap[proposedName];
    if (newName == null) {
      newName = getFreshName(proposedName, usedInstanceNames,
                             suggestedInstanceNames, ensureSafe: false);
      operatorNameMap[proposedName] = newName;
    }
    return newName;
  }

  String getFreshName(String proposedName,
                      Set<String> usedNames,
                      Map<String, String> suggestedNames,
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
    // Use the unminified names here to construct the interceptor names.  This
    // helps ensure that they don't all suddenly change names due to a name
    // clash in the minifier, which would affect the diff size.
    StringBuffer buffer = new StringBuffer('${element.name.slowToString()}\$');
    for (ClassElement cls in classes) {
      buffer.add(cls.name.slowToString());
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
      // Make sure two bailout methods on the same inheritance chain do not have
      // the same name to prevent a subclass bailout method being accidentally
      // called from the superclass main method.  Use the count of the number of
      // elements with the same name on the superclass chain to disambiguate
      // based on 'level'.
      int level = 0;
      ClassElement classElement = element.getEnclosingClass().superclass;
      while (classElement != null) {
        if (classElement.localLookup(element.name) != null) level++;
        classElement = classElement.superclass;
      }
      name = unminifiedName;
      if (level != 0) {
        name = '$unminifiedName$level';
      }
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
            : getFreshName(guess, usedGlobalNames, suggestedGlobalNames,
                           ensureSafe: true);
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
  String _safeName(String name, Set<String> reserved) {
    if (reserved.contains(name) || name.startsWith(r'$')) {
      name = '\$$name';
    }
    assert(!reserved.contains(name));
    return name;
  }

  String safeName(String name) => _safeName(name, jsReserved);
  String safeVariableName(String name) => _safeName(name, jsVariableReserved);

  String oneShotInterceptorName(Selector selector) {
    // TODO(ngeoffray): What to do about typed selectors? We could
    // filter them out, or keep them and hope the generated one shot
    // interceptor takes advantage of the type.
    String cached = oneShotInterceptorNames[selector];
    if (cached != null) return cached;
    SourceString name = operatorNameToIdentifier(selector.name);
    String result = getFreshName(name.slowToString(), usedGlobalNames,
                                 suggestedGlobalNames);
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
