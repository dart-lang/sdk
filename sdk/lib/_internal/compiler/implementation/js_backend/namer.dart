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

  final String getterPrefix = r'get$';
  final String setterPrefix = r'set$';

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
  final Map<String, String> suggestedGlobalNames;
  final Map<String, String> instanceNameMap;
  final Map<String, String> suggestedInstanceNames;

  final Map<String, String> operatorNameMap;
  final Map<String, int> popularNameCounters;

  final Map<Element, String> bailoutNames;

  final Map<Constant, String> constantNames;
  ConstantCanonicalHasher constantHasher;

  Namer(Compiler compiler)
      : compiler = compiler,
        globals = new Map<Element, String>(),
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
        popularNameCounters = new Map<String, int>(),
        constantHasher = new ConstantCanonicalHasher(compiler);

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
        longName = new ConstantNamingVisitor(compiler, constantHasher)
            .getName(constant);
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
        buffer.write('\$${safeName(element.name.slowToString())}');
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
      return '$getterPrefix${getMappedInstanceName(proposedName)}';
    } else if (selector.isSetter()) {
      String proposedName = privateName(selector.library, selector.name);
      return '$setterPrefix${getMappedInstanceName(proposedName)}';
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
        buffer.write(r'$');
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
    return '$setterPrefix$name';
  }

  String setterNameFromAccessorName(String name) {
    // We dynamically create setters from the field-name. The setter name must
    // therefore be derived from the instance field-name.
    return '$setterPrefix$name';
  }

  String publicGetterName(SourceString name) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    String fieldName = getMappedInstanceName(name.slowToString());
    return '$getterPrefix$fieldName';
  }

  String getterNameFromAccessorName(String name) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    return '$getterPrefix$name';
  }

  String getterName(Element element) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    LibraryElement library = element.getLibrary();
    String name = getMappedInstanceName(privateName(library, element.name));
    return '$getterPrefix$name';
  }

  String getMappedGlobalName(String proposedName, {bool ensureSafe: true}) {
    var newName = globalNameMap[proposedName];
    if (newName == null) {
      newName = getFreshName(proposedName, usedGlobalNames,
                             suggestedGlobalNames, ensureSafe: ensureSafe);
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

  String getInterceptorSuffix(Iterable<ClassElement> classes) {
    String abbreviate(ClassElement cls) {
      if (cls == compiler.objectClass) return "o";
      JavaScriptBackend backend = compiler.backend;
      if (cls == backend.jsStringClass) return "s";
      if (cls == backend.jsArrayClass) return "a";
      if (cls == backend.jsDoubleClass) return "d";
      if (cls == backend.jsIntClass) return "i";
      if (cls == backend.jsNumberClass) return "n";
      if (cls == backend.jsNullClass) return "u";
      if (cls == backend.jsFunctionClass) return "f";
      if (cls == backend.jsBoolClass) return "b";
      if (cls == backend.jsInterceptorClass) return "I";
      return cls.name.slowToString();
    }
    List<String> names = classes
        .where((cls) => !cls.isNative())
        .map(abbreviate)
        .toList();
    // There is one dispatch mechanism for all native classes.
    if (classes.any((cls) => cls.isNative())) {
      names.add("x");
    }
    // Sort the names of the classes after abbreviating them to ensure
    // the suffix is stable and predictable for the suggested names.
    names.sort();
    return names.join();
  }

  String getInterceptorName(Element element, Iterable<ClassElement> classes) {
    JavaScriptBackend backend = compiler.backend;
    if (classes.contains(backend.jsInterceptorClass)) {
      // If the base Interceptor class is in the set of intercepted classes, we
      // need to go through the generic getInterceptorMethod, since any subclass
      // of the base Interceptor could match.
      return getName(element);
    }
    String suffix = getInterceptorSuffix(classes);
    return getMappedGlobalName("${element.name.slowToString()}\$$suffix");
  }

  String getOneShotInterceptorName(Selector selector,
                                   Iterable<ClassElement> classes) {
    JavaScriptBackend backend = compiler.backend;
    // The one-shot name is a global name derived from the invocation name.  To
    // avoid instability we would like the names to be unique and not clash with
    // other global names.

    String root = invocationName(selector);  // Is already safe.

    if (classes.contains(backend.jsInterceptorClass)) {
      // If the base Interceptor class is in the set of intercepted classes,
      // this is the most general specialization which uses the generic
      // getInterceptor method.  To keep the name short, we add '$' only to
      // distinguish from global getters or setters; operators and methods can't
      // clash.
      // TODO(sra): Find a way to get the simple name when Object is not in the
      // set of classes for most general variant, e.g. "$lt$n" could be "$lt".
      if (selector.isGetter() || selector.isSetter()) root = '$root\$';
      return getMappedGlobalName(root, ensureSafe: false);
    } else {
      String suffix = getInterceptorSuffix(classes);
      return getMappedGlobalName("$root\$$suffix", ensureSafe: false);
    }
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

  /// Returns the runtime name for [element].  The result is not safe as an id.
  String getRuntimeTypeName(Element element) {
    if (element == compiler.intClass) {
      return 'int';
    } else if (element == compiler.doubleClass) {
      return 'double';
    } else {
      return getName(element);
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
    return getMappedGlobalName("$getterPrefix${getName(element)}");
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

  String operatorAsPrefix() => r'$as';

  String operatorIs(Element element) {
    // TODO(erikcorry): Reduce from $isx to ix when we are minifying.
    return '${operatorIsPrefix()}${getRuntimeTypeName(element)}';
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

  String substitutionName(Element element) {
    return '${operatorAsPrefix()}${getName(element)}';
  }

  String safeName(String name) => _safeName(name, jsReserved);
  String safeVariableName(String name) => _safeName(name, jsVariableReserved);

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


/**
 * Generator of names for [Constant] values.
 *
 * The names are stable under perturbations of the source.  The name is either a
 * short sequence of words, if this can be found from the constant, or a type
 * followed by a hash tag.
 *
 *     List_imX                // A List, with hash tag.
 *     C_Sentinel              // const Sentinel(),  "C_" added to avoid clash
 *                             //   with class name.
 *     JSInt_methods           // an interceptor.
 *     Duration_16000          // const Duration(milliseconds: 16)
 *     EventKeyProvider_keyup  // const EventKeyProvider('keyup')
 *
 */
class ConstantNamingVisitor implements ConstantVisitor {

  static final RegExp IDENTIFIER = new RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$');
  static const MAX_FRAGMENTS = 5;
  static const MAX_EXTRA_LENGTH = 30;
  static const DEFAULT_TAG_LENGTH = 3;

  final Compiler compiler;
  final ConstantCanonicalHasher hasher;

  String root = null;     // First word, usually a type name.
  bool failed = false;    // Failed to generate something pretty.
  List<String> fragments = <String>[];
  int length = 0;

  ConstantNamingVisitor(this.compiler, this.hasher);

  String getName(Constant constant) {
    _visit(constant);
    if (root == null) return 'CONSTANT';
    if (failed) return '${root}_${getHashTag(constant, DEFAULT_TAG_LENGTH)}';
    if (fragments.length == 1) return 'C_${root}';
    return fragments.join('_');
  }

  String getHashTag(Constant constant, int width) =>
      hashWord(hasher.getHash(constant), width);

  String hashWord(int hash, int length) {
    hash &= 0x1fffffff;
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < length; i++) {
      int digit = hash % 62;
      sb.write('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
          [digit]);
      hash ~/= 62;
      if (hash == 0) break;
    }
    return sb.toString();
  }

  void addRoot(String fragment) {
    if (root == null && fragments.isEmpty) {
      root = fragment;
    }
    add(fragment);
  }

  void add(String fragment) {
    assert(fragment.length > 0);
    fragments.add(fragment);
    length += fragment.length;
    if (fragments.length > MAX_FRAGMENTS) failed = true;
    if (root != null && length > root.length + 1 + MAX_EXTRA_LENGTH) {
      failed = true;
    }
  }

  void addIdentifier(String fragment) {
    if (fragment.length <= MAX_EXTRA_LENGTH && IDENTIFIER.hasMatch(fragment)) {
      add(fragment);
    } else {
      failed = true;
    }
  }

  _visit(Constant constant) {
    return constant.accept(this);
  }

  visitSentinel(SentinelConstant constant) {
    add(r'$');
  }

  visitFunction(FunctionConstant constant) {
    add(constant.element.name.slowToString());
  }

  visitNull(NullConstant constant) {
    add('null');
  }

  visitInt(IntConstant constant) {
    // No `addRoot` since IntConstants are always inlined.
    if (constant.value < 0) {
      add('m${-constant.value}');
    } else {
      add('${constant.value}');
    }
  }

  visitDouble(DoubleConstant constant) {
    failed = true;
  }

  visitTrue(TrueConstant constant) {
    add('true');
  }

  visitFalse(FalseConstant constant) {
    add('false');
  }

  visitString(StringConstant constant) {
    // No `addRoot` since string constants are always inlined.
    addIdentifier(constant.value.slowToString());
  }

  visitList(ListConstant constant) {
    // TODO(9476): Incorporate type parameters into name.
    addRoot('List');
    int length = constant.length;
    if (constant.length == 0) {
      add('empty');
    } else if (length >= MAX_FRAGMENTS) {
      failed = true;
    } else {
      for (int i = 0; i < length; i++) {
        _visit(constant.entries[i]);
        if (failed) break;
      }
    }
  }

  visitMap(MapConstant constant) {
    // TODO(9476): Incorporate type parameters into name.
    addRoot('Map');
    if (constant.length == 0) {
      add('empty');
    } else {
      // Using some bits from the keys hash tag groups the names Maps with the
      // same structure.
      add(getHashTag(constant.keys, 2) + getHashTag(constant, 3));
    }
  }

  visitConstructed(ConstructedConstant constant) {
    addRoot(constant.type.element.name.slowToString());
    for (int i = 0; i < constant.fields.length; i++) {
      _visit(constant.fields[i]);
      if (failed) return;
    }
  }

  visitType(TypeConstant constant) {
    addRoot('Type');
    DartType type = constant.representedType;
    JavaScriptBackend backend = compiler.backend;
    String name = backend.rti.getRawTypeRepresentation(type);
    addIdentifier(name);
  }

  visitInterceptor(InterceptorConstant constant) {
    addRoot(constant.dispatchedType.element.name.slowToString());
    add('methods');
  }
}


/**
 * Generates canonical hash values for [Constant]s.
 *
 * Unfortunately, [Constant.hashCode] is not stable under minor perturbations,
 * so it can't be used for generating names.  This hasher keeps consistency
 * between runs by basing hash values of the names of elements, rather than
 * their hashCodes.
 */
class ConstantCanonicalHasher implements ConstantVisitor<int> {

  static const _MASK = 0x1fffffff;
  static const _UINT32_LIMIT = 4 * 1024 * 1024 * 1024;


  final Compiler compiler;
  final Map<Constant, int> hashes = new Map<Constant, int>();

  ConstantCanonicalHasher(this.compiler);

  int getHash(Constant constant) => _visit(constant);

  int _visit(Constant constant) {
    int hash = hashes[constant];
    if (hash == null) {
      hash = _finish(constant.accept(this));
      hashes[constant] = hash;
    }
    return hash;
  }

  int visitSentinel(SentinelConstant constant) => 1;
  int visitNull(NullConstant constant) => 2;
  int visitTrue(TrueConstant constant) => 3;
  int visitFalse(FalseConstant constant) => 4;

  int visitFunction(FunctionConstant constant) {
    return _hashString(1, constant.element.name.slowToString());
  }

  int visitInt(IntConstant constant) => _hashInt(constant.value);

  int visitDouble(DoubleConstant constant) => _hashDouble(constant.value);

  int visitString(StringConstant constant) {
    return _hashString(2, constant.value.slowToString());
  }

  int visitList(ListConstant constant) {
    return _hashList(constant.length, constant.entries);
  }

  int visitMap(MapConstant constant) {
    int hash = _visit(constant.keys);
    return _hashList(hash, constant.values);
  }

  int visitConstructed(ConstructedConstant constant) {
    int hash = _hashString(3, constant.type.element.name.slowToString());
    for (int i = 0; i < constant.fields.length; i++) {
      hash = _combine(hash, _visit(constant.fields[i]));
    }
    return hash;
  }

  int visitType(TypeConstant constant) {
    DartType type = constant.representedType;
    JavaScriptBackend backend = compiler.backend;
    String name = backend.rti.getRawTypeRepresentation(type);
    return _hashString(4, name);
  }

  visitInterceptor(InterceptorConstant constant) {
    String typeName = constant.dispatchedType.element.name.slowToString();
    return _hashString(5, typeName);
  }

  int _hashString(int hash, String s) {
    int length = s.length;
    hash = _combine(hash, length);
    // Increasing stride is O(log N) on large strings which are unlikely to have
    // many collisions.
    for (int i = 0; i < length; i += 1 + (i >> 2)) {
      hash = _combine(hash, s.codeUnitAt(i));
    }
    return hash;
  }

  int _hashList(int hash, List<Constant> constants) {
    for (Constant constant in constants) {
      hash = _combine(hash, _visit(constant));
    }
    return hash;
  }

  static int _hashInt(int value) {
    if (value.abs() < _UINT32_LIMIT) return _MASK & value;
    return _hashDouble(value.toDouble());
  }

  static int _hashDouble(double value) {
    double magnitude = value.abs();
    int sign = value < 0 ? 1 : 0;
    if (magnitude < _UINT32_LIMIT) {  // 2^32
      int intValue = value.toInt();
      // Integer valued doubles in 32-bit range hash to the same values as ints.
      int hash = _hashInt(intValue);
      if (value == intValue) return hash;
      hash = _combine(hash, sign);
      int fraction = ((magnitude - intValue.abs()) * (_MASK + 1)).toInt();
      hash = _combine(hash, fraction);
      return hash;
    } else if (value.isInfinite) {
      return _combine(6, sign);
    } else if (value.isNaN) {
      return 7;
    } else {
      int hash = 0;
      while (magnitude >= _UINT32_LIMIT) {
        magnitude = magnitude / _UINT32_LIMIT;
        hash++;
      }
      hash = _combine(hash, sign);
      return _combine(hash, _hashDouble(magnitude));
    }
  }

  /**
   * [_combine] and [_finish] are parts of the [Jenkins hash function][1],
   * modified by using masking to keep values in SMI range.
   *
   * [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
   */
  static int _combine(int hash, int value) {
    hash = _MASK & (hash + value);
    hash = _MASK & (hash + (((_MASK >> 10) & hash) << 10));
    hash = hash ^ (hash >> 6);
    return hash;
  }

  static int _finish(int hash) {
    hash = _MASK & (hash + (((_MASK >> 3) & hash) <<  3));
    hash = hash & (hash >> 11);
    return _MASK & (hash + (((_MASK >> 15) & hash) << 15));
  }
}
