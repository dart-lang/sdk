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
    "JavaArray", "JavaMember",
  ];

  static const reservedGlobalObjectNames = const <String>[
      "A",
      "B",
      "C", // Global object for *C*onstants.
      "D",
      "E",
      "F",
      "G",
      "H", // Global object for internal (*H*elper) libraries.
      // I is used for used for the Isolate function.
      "J", // Global object for the interceptor library.
      "K",
      "L",
      "M",
      "N",
      "O",
      "P", // Global object for other *P*latform libraries.
      "Q",
      "R",
      "S",
      "T",
      "U",
      "V",
      "W", // Global object for *W*eb libraries (dart:html).
      "X",
      "Y",
      "Z",
  ];

  static const reservedGlobalHelperFunctions = const <String>[
      "init",
      "Isolate",
  ];

  static final userGlobalObjects = new List.from(reservedGlobalObjectNames)
      ..remove('C')
      ..remove('H')
      ..remove('J')
      ..remove('P')
      ..remove('W');

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
      _jsVariableReserved.addAll(reservedGlobalObjectNames);
      // 26 letters in the alphabet, 25 not counting I.
      assert(reservedGlobalObjectNames.length == 25);
      _jsVariableReserved.addAll(reservedGlobalHelperFunctions);
    }
    return _jsVariableReserved;
  }

  final String currentIsolate = r'$';
  final String getterPrefix = r'get$';
  final String setterPrefix = r'set$';
  final String metadataField = '@';
  final String callPrefix = 'call';
  final String callCatchAllName = r'call$catchAll';
  final String reflectableField = r'$reflectable';
  final String defaultValuesField = r'$defaultValues';
  final String methodsWithOptionalArgumentsField =
      r'$methodsWithOptionalArguments';

  final String classDescriptorProperty = r'^';

  // Name of property in a class description for the native dispatch metadata.
  final String nativeSpecProperty = '%';

  static final RegExp IDENTIFIER = new RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$');
  static final RegExp NON_IDENTIFIER_CHAR = new RegExp(r'[^A-Za-z_0-9$]');

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

  final Map<Constant, String> constantNames;
  final Map<Constant, String> constantLongNames;
  ConstantCanonicalHasher constantHasher;

  Namer(Compiler compiler)
      : compiler = compiler,
        globals = new Map<Element, String>(),
        shortPrivateNameOwners = new Map<String, LibraryElement>(),
        usedGlobalNames = new Set<String>(),
        usedInstanceNames = new Set<String>(),
        instanceNameMap = new Map<String, String>(),
        operatorNameMap = new Map<String, String>(),
        globalNameMap = new Map<String, String>(),
        suggestedGlobalNames = new Map<String, String>(),
        suggestedInstanceNames = new Map<String, String>(),
        popularNameCounters = new Map<String, int>(),
        constantNames = new Map<Constant, String>(),
        constantLongNames = new Map<Constant, String>(),
        constantHasher = new ConstantCanonicalHasher(compiler),
        functionTypeNamer = new FunctionTypeNamer(compiler);

  String get isolateName => 'Isolate';
  String get isolatePropertiesName => r'$isolateProperties';
  /**
   * Some closures must contain their name. The name is stored in
   * [STATIC_CLOSURE_NAME_NAME].
   */
  String get STATIC_CLOSURE_NAME_NAME => r'$name';
  String get closureInvocationSelectorName => Compiler.CALL_OPERATOR_NAME;
  bool get shouldMinify => false;

  String getNameForJsGetName(Node node, String name) {
    switch (name) {
      case 'GETTER_PREFIX': return getterPrefix;
      case 'SETTER_PREFIX': return setterPrefix;
      case 'CALL_PREFIX': return callPrefix;
      case 'CALL_CATCH_ALL': return callCatchAllName;
      case 'REFLECTABLE': return reflectableField;
      case 'CLASS_DESCRIPTOR_PROPERTY': return classDescriptorProperty;
      default:
        compiler.reportError(
            node, MessageKind.GENERIC,
            {'text': 'Error: Namer has no name for "$name".'});
        return 'BROKEN';
    }
  }

  String constantName(Constant constant) {
    // In the current implementation it doesn't make sense to give names to
    // function constants since the function-implementation itself serves as
    // constant and can be accessed directly.
    assert(!constant.isFunction);
    String result = constantNames[constant];
    if (result == null) {
      String longName = constantLongName(constant);
      result = getFreshName(longName, usedGlobalNames, suggestedGlobalNames,
                            ensureSafe: true);
      constantNames[constant] = result;
    }
    return result;
  }

  // The long name is unminified and may have collisions.
  String constantLongName(Constant constant) {
    String longName = constantLongNames[constant];
    if (longName == null) {
      longName = new ConstantNamingVisitor(compiler, constantHasher)
          .getName(constant);
      constantLongNames[constant] = longName;
    }
    return longName;
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
   * If the [name] is not private returns [:name:]. Otherwise
   * mangles the [name] so that each library has a unique name.
   */
  String privateName(LibraryElement library, String name) {
    // Public names are easy.
    String nameString = name;
    if (!isPrivateName(name)) return nameString;

    // The first library asking for a short private name wins.
    LibraryElement owner = shouldMinify
        ? library
        : shortPrivateNameOwners.putIfAbsent(nameString, () => library);

    if (owner == library && !shouldMinify && !nameString.contains('\$')) {
      // Since the name doesn't contain $ it doesn't clash with any
      // of the private names that have the library name as the prefix.
      return nameString;
    } else {
      // Make sure to return a private name that starts with _ so it
      // cannot clash with any public names.
      String libraryName = getNameOfLibrary(library);
      return '_$libraryName\$$nameString';
    }
  }

  String instanceMethodName(FunctionElement element) {
    // TODO(ahe): Could this be: return invocationName(new
    // Selector.fromElement(element))?
    String elementName = element.name;
    String name = operatorNameToIdentifier(elementName);
    if (name != elementName) return getMappedOperatorName(name);

    LibraryElement library = element.library;
    if (element.isGenerativeConstructorBody) {
      name = Elements.reconstructConstructorNameSourceString(element);
    }
    FunctionSignature signature = element.functionSignature;
    // We don't mangle the closure invoking function name because it
    // is generated by string concatenation in applyFunction from
    // js_helper.dart. To keep code size down, we potentially shorten
    // the prefix though.
    String methodName;
    if (name == closureInvocationSelectorName) {
      methodName = '$callPrefix\$${signature.parameterCount}';
    } else {
      methodName = '${privateName(library, name)}\$${signature.parameterCount}';
    }
    if (signature.optionalParametersAreNamed &&
        !signature.optionalParameters.isEmpty) {
      StringBuffer buffer = new StringBuffer();
      signature.orderedOptionalParameters.forEach((Element element) {
        buffer.write('\$${safeName(element.name)}');
      });
      methodName = '$methodName$buffer';
    }
    if (name == closureInvocationSelectorName) return methodName;
    return getMappedInstanceName(methodName);
  }

  String publicInstanceMethodNameByArity(String name, int arity) {
    String newName = operatorNameToIdentifier(name);
    if (newName != name) return getMappedOperatorName(newName);
    assert(!isPrivateName(name));
    // We don't mangle the closure invoking function name because it
    // is generated by string concatenation in applyFunction from
    // js_helper.dart. To keep code size down, we potentially shorten
    // the prefix though.
    if (name == closureInvocationSelectorName) return '$callPrefix\$$arity';

    return getMappedInstanceName('$name\$$arity');
  }

  String invocationName(Selector selector) {
    if (selector.isGetter) {
      String proposedName = privateName(selector.library, selector.name);
      return '$getterPrefix${getMappedInstanceName(proposedName)}';
    } else if (selector.isSetter) {
      String proposedName = privateName(selector.library, selector.name);
      return '$setterPrefix${getMappedInstanceName(proposedName)}';
    } else {
      String name = selector.name;
      if (selector.kind == SelectorKind.OPERATOR
          || selector.kind == SelectorKind.INDEX) {
        name = operatorNameToIdentifier(name);
        assert(name != selector.name);
        return getMappedOperatorName(name);
      }
      assert(name == operatorNameToIdentifier(name));
      StringBuffer buffer = new StringBuffer();
      for (String argumentName in selector.getOrderedNamedArguments()) {
        buffer.write('\$${safeName(argumentName)}');
      }
      String suffix = '\$${selector.argumentCount}$buffer';
      // We don't mangle the closure invoking function name because it
      // is generated by string concatenation in applyFunction from
      // js_helper.dart. We potentially shorten the prefix though.
      if (selector.isClosureCall) {
        return "$callPrefix$suffix";
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

  /**
   * Returns name of accessor (root to getter and setter) for a static or
   * instance field.
   */
  String fieldAccessorName(Element element) {
    return element.isInstanceMember
        ? instanceFieldAccessorName(element)
        : getNameOfField(element);
  }

  /**
   * Returns name of the JavaScript property used to store a static or instance
   * field.
   */
  String fieldPropertyName(Element element) {
    return element.isInstanceMember
        ? instanceFieldPropertyName(element)
        : getNameOfField(element);
  }

  /**
   * Returns name of accessor (root to getter and setter) for an instance field.
   */
  String instanceFieldAccessorName(Element element) {
    String proposedName = privateName(element.library, element.name);
    return getMappedInstanceName(proposedName);
  }

  String readTypeVariableName(TypeVariableElement element) {
    return '\$tv_${instanceFieldAccessorName(element)}';
  }

  /**
   * Returns name of the JavaScript property used to store an instance field.
   */
  String instanceFieldPropertyName(Element element) {
    if (element.hasFixedBackendName) {
      return element.fixedBackendName;
    }
    // If a class is used anywhere as a mixin, we must make the name unique so
    // that it does not accidentally shadow.  Also, the mixin name must be
    // constant over all mixins.
    if (compiler.world.isUsedAsMixin(element.enclosingClass) ||
        shadowingAnotherField(element)) {
      // Construct a new name for the element based on the library and class it
      // is in.  The name here is not important, we just need to make sure it is
      // unique.  If we are minifying, we actually construct the name from the
      // minified version of the class name, but the result is minified once
      // again, so that is not visible in the end result.
      String libraryName = getNameOfLibrary(element.library);
      String className = getNameOfClass(element.enclosingClass);
      String instanceName = privateName(element.library, element.name);
      return getMappedInstanceName('$libraryName\$$className\$$instanceName');
    }

    String proposedName = privateName(element.library, element.name);
    return getMappedInstanceName(proposedName);
  }


  bool shadowingAnotherField(Element element) {
    return element.enclosingClass.hasFieldShadowedBy(element);
  }

  String setterName(Element element) {
    // We dynamically create setters from the field-name. The setter name must
    // therefore be derived from the instance field-name.
    LibraryElement library = element.library;
    String name = getMappedInstanceName(privateName(library, element.name));
    return '$setterPrefix$name';
  }

  String setterNameFromAccessorName(String name) {
    // We dynamically create setters from the field-name. The setter name must
    // therefore be derived from the instance field-name.
    return '$setterPrefix$name';
  }

  String getterNameFromAccessorName(String name) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    return '$getterPrefix$name';
  }

  String getterName(Element element) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    LibraryElement library = element.library;
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

  String getClosureVariableName(String name, int id) {
    return "${name}_$id";
  }

  /**
   * Returns a preferred JS-id for the given top-level or static element.
   * The returned id is guaranteed to be a valid JS-id.
   */
  String _computeGuess(Element element) {
    assert(!element.isInstanceMember);
    String name;
    if (element.isGenerativeConstructor) {
      name = "${element.enclosingClass.name}\$"
             "${element.name}";
    } else if (element.isFactoryConstructor) {
      // TODO(johnniwinther): Change factory name encoding as to not include
      // the class-name twice.
      String className = element.enclosingClass.name;
      name = '${className}_${Elements.reconstructConstructorName(element)}';
    } else if (Elements.isStaticOrTopLevel(element)) {
      if (element.isMember) {
        ClassElement enclosingClass = element.enclosingClass;
        name = "${enclosingClass.name}_"
               "${element.name}";
      } else {
        name = element.name.replaceAll('+', '_');
      }
    } else if (element.isLibrary) {
      LibraryElement library = element;
      name = library.getLibraryOrScriptName();
      if (name.contains('.')) {
        // For libraries that have a library tag, we use the last part
        // of the fully qualified name as their base name. For all other
        // libraries, we use the first part of their filename.
        name = library.hasLibraryName()
            ? name.substring(name.lastIndexOf('.') + 1)
            : name.substring(0, name.indexOf('.'));
      }
      // The filename based name can contain all kinds of nasty characters. Make
      // sure it is an identifier.
      if (!IDENTIFIER.hasMatch(name)) {
        name = name.replaceAllMapped(NON_IDENTIFIER_CHAR,
            (match) => match[0].codeUnitAt(0).toRadixString(16));
        if (!IDENTIFIER.hasMatch(name)) {  // e.g. starts with digit.
          name = 'lib_$name';
        }
      }
    } else {
      name = element.name;
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
      if (cls == backend.jsBoolClass) return "b";
      if (cls == backend.jsInterceptorClass) return "I";
      return cls.name;
    }
    List<String> names = classes
        .where((cls) => !Elements.isNativeOrExtendsNative(cls))
        .map(abbreviate)
        .toList();
    // There is one dispatch mechanism for all native classes.
    if (classes.any((cls) => Elements.isNativeOrExtendsNative(cls))) {
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
      return getNameOfInstanceMember(element);
    }
    String suffix = getInterceptorSuffix(classes);
    return getMappedGlobalName("${element.name}\$$suffix");
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
      if (selector.isGetter || selector.isSetter) root = '$root\$';
      return getMappedGlobalName(root, ensureSafe: false);
    } else {
      String suffix = getInterceptorSuffix(classes);
      return getMappedGlobalName("$root\$$suffix", ensureSafe: false);
    }
  }

  /// Returns the runtime name for [element].  The result is not safe as an id.
  String getRuntimeTypeName(Element element) {
    if (element == null) return 'dynamic';
    return getNameForRti(element);
  }

  /**
   * Returns a preferred JS-id for the given element. The returned id is
   * guaranteed to be a valid JS-id. Globals and static fields are furthermore
   * guaranteed to be unique.
   *
   * For accessing statics consider calling [elementAccess] instead.
   */
  // TODO(ahe): This is an internal method to the Namer (and its subclasses)
  // and should not be call from outside.
  String getNameX(Element element) {
    if (element.isInstanceMember) {
      if (element.kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY
          || element.kind == ElementKind.FUNCTION) {
        return instanceMethodName(element);
      } else if (element.kind == ElementKind.GETTER) {
        return getterName(element);
      } else if (element.kind == ElementKind.SETTER) {
        return setterName(element);
      } else if (element.kind == ElementKind.FIELD) {
        compiler.internalError(element,
            'Use instanceFieldPropertyName or instanceFieldAccessorName.');
        return null;
      } else {
        compiler.internalError(element,
            'getName for bad kind: ${element.kind}.');
        return null;
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
          kind == ElementKind.LIBRARY) {
        bool fixedName = false;
        if (Elements.isInstanceField(element)) {
          fixedName = element.hasFixedBackendName;
        }
        String result = fixedName
            ? guess
            : getFreshName(guess, usedGlobalNames, suggestedGlobalNames,
                           ensureSafe: true);
        globals[element] = result;
        return result;
      }
      compiler.internalError(element,
          'getName for unknown kind: ${element.kind}.');
      return null;
    }
  }

  String getNameForRti(Element element) => getNameX(element);

  String getNameOfLibrary(LibraryElement library) => getNameX(library);

  String getNameOfClass(ClassElement cls) => getNameX(cls);

  String getNameOfField(VariableElement field) => getNameX(field);

  // TODO(ahe): Remove this method. Use get getNameOfMember instead.
  String getNameOfInstanceMember(Element member) => getNameX(member);

  String getNameOfMember(Element member) => getNameX(member);

  String getNameOfGlobalField(VariableElement field) => getNameX(field);

  /// Returns true if [element] is stored on current isolate ('$').  We intend
  /// to store only mutable static state in [currentIsolate], constants are
  /// stored in 'C', and functions, accessors, classes, etc. are stored in one
  /// of the other objects in [reservedGlobalObjectNames].
  bool isPropertyOfCurrentIsolate(Element element) {
    // TODO(ahe): Make sure this method's documentation is always true and
    // remove the word "intend".
    return
        // TODO(ahe): Re-write these tests to be positive (so it only returns
        // true for static/top-level mutable fields). Right now, a number of
        // other elements, such as bound closures also live in [currentIsolate].
        !element.isAccessor &&
        !element.isClass &&
        !element.isConstructor &&
        !element.isFunction &&
        !element.isLibrary;
  }

  /// Returns [currentIsolate] or one of [reservedGlobalObjectNames].
  String globalObjectFor(Element element) {
    if (isPropertyOfCurrentIsolate(element)) return currentIsolate;
    LibraryElement library = element.library;
    if (library == compiler.interceptorsLibrary) return 'J';
    if (library.isInternalLibrary) return 'H';
    if (library.isPlatformLibrary) {
      if ('${library.canonicalUri}' == 'dart:html') return 'W';
      return 'P';
    }
    return userGlobalObjects[
        library.getLibraryOrScriptName().hashCode % userGlobalObjects.length];
  }

  jsAst.PropertyAccess elementAccess(Element element) {
    String name = getNameX(element);
    return new jsAst.PropertyAccess.field(
        new jsAst.VariableUse(globalObjectFor(element)),
        name);
  }

  String getLazyInitializerName(Element element) {
    assert(Elements.isStaticOrTopLevelField(element));
    return getMappedGlobalName("$getterPrefix${getNameX(element)}");
  }

  String getStaticClosureName(Element element) {
    assert(Elements.isStaticOrTopLevelFunction(element));
    return getMappedGlobalName("${getNameX(element)}\$closure");
  }

  jsAst.Expression isolateLazyInitializerAccess(Element element) {
    return js('#.#',
        [globalObjectFor(element), getLazyInitializerName(element)]);
  }

  jsAst.Expression isolateStaticClosureAccess(Element element) {
    return js('#.#()',
        [globalObjectFor(element), getStaticClosureName(element)]);
  }

  // This name is used as part of the name of a TypeConstant
  String uniqueNameForTypeConstantElement(Element element) {
    // TODO(sra): If we replace the period with an identifier character,
    // TypeConstants will have better names in unminified code.
    return "${globalObjectFor(element)}.${getNameX(element)}";
  }

  String globalObjectForConstant(Constant constant) => 'C';

  String operatorIsPrefix() => r'$is';

  String operatorAsPrefix() => r'$as';

  String operatorSignature() => r'$signature';

  String functionTypeTag() => r'func';

  String functionTypeVoidReturnTag() => r'void';

  String functionTypeReturnTypeTag() => r'ret';

  String functionTypeRequiredParametersTag() => r'args';

  String functionTypeOptionalParametersTag() => r'opt';

  String functionTypeNamedParametersTag() => r'named';

  Map<FunctionType,String> functionTypeNameMap =
      new Map<FunctionType,String>();
  final FunctionTypeNamer functionTypeNamer;

  String getFunctionTypeName(FunctionType functionType) {
    return functionTypeNameMap.putIfAbsent(functionType, () {
      String proposedName = functionTypeNamer.computeName(functionType);
      String freshName = getFreshName(proposedName, usedInstanceNames,
                                      suggestedInstanceNames, ensureSafe: true);
      return freshName;
    });
  }

  String operatorIsType(DartType type) {
    if (type.isFunctionType) {
      // TODO(erikcorry): Reduce from $isx to ix when we are minifying.
      return '${operatorIsPrefix()}_${getFunctionTypeName(type)}';
    }
    return operatorIs(type.element);
  }

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
    // TODO(ahe): Creating a string here is unfortunate. It is slow (due to
    // string concatenation in the implementation), and may prevent
    // segmentation of '$'.
    return '${operatorAsPrefix()}${getNameForRti(element)}';
  }

  String safeName(String name) => _safeName(name, jsReserved);
  String safeVariableName(String name) => _safeName(name, jsVariableReserved);

  String operatorNameToIdentifier(String name) {
    if (name == null) return null;
    if (name == '==') {
      return r'$eq';
    } else if (name == '~') {
      return r'$not';
    } else if (name == '[]') {
      return r'$index';
    } else if (name == '[]=') {
      return r'$indexSet';
    } else if (name == '*') {
      return r'$mul';
    } else if (name == '/') {
      return r'$div';
    } else if (name == '%') {
      return r'$mod';
    } else if (name == '~/') {
      return r'$tdiv';
    } else if (name == '+') {
      return r'$add';
    } else if (name == '<<') {
      return r'$shl';
    } else if (name == '>>') {
      return r'$shr';
    } else if (name == '>=') {
      return r'$ge';
    } else if (name == '>') {
      return r'$gt';
    } else if (name == '<=') {
      return r'$le';
    } else if (name == '<') {
      return r'$lt';
    } else if (name == '&') {
      return r'$and';
    } else if (name == '^') {
      return r'$xor';
    } else if (name == '|') {
      return r'$or';
    } else if (name == '-') {
      return r'$sub';
    } else if (name == 'unary-') {
      return r'$negate';
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

  visitFunction(FunctionConstant constant) {
    add(constant.element.name);
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

  visitMap(JavaScriptMapConstant constant) {
    // TODO(9476): Incorporate type parameters into name.
    addRoot('Map');
    if (constant.length == 0) {
      add('empty');
    } else {
      // Using some bits from the keys hash tag groups the names Maps with the
      // same structure.
      add(getHashTag(constant.keyList, 2) + getHashTag(constant, 3));
    }
  }

  visitConstructed(ConstructedConstant constant) {
    addRoot(constant.type.element.name);
    for (int i = 0; i < constant.fields.length; i++) {
      _visit(constant.fields[i]);
      if (failed) return;
    }
  }

  visitType(TypeConstant constant) {
    addRoot('Type');
    DartType type = constant.representedType;
    JavaScriptBackend backend = compiler.backend;
    String name = backend.rti.getTypeRepresentationForTypeConstant(type);
    addIdentifier(name);
  }

  visitInterceptor(InterceptorConstant constant) {
    addRoot(constant.dispatchedType.element.name);
    add('methods');
  }

  visitDummy(DummyConstant constant) {
    add('dummy_receiver');
  }

  visitDeferred(DeferredConstant constant) {
    addRoot('Deferred');
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

  int visitNull(NullConstant constant) => 1;
  int visitTrue(TrueConstant constant) => 2;
  int visitFalse(FalseConstant constant) => 3;

  int visitFunction(FunctionConstant constant) {
    return _hashString(1, constant.element.name);
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
    int hash = _hashList(constant.length, constant.keys);
    return _hashList(hash, constant.values);
  }

  int visitConstructed(ConstructedConstant constant) {
    int hash = _hashString(3, constant.type.element.name);
    for (int i = 0; i < constant.fields.length; i++) {
      hash = _combine(hash, _visit(constant.fields[i]));
    }
    return hash;
  }

  int visitType(TypeConstant constant) {
    DartType type = constant.representedType;
    JavaScriptBackend backend = compiler.backend;
    String name = backend.rti.getTypeRepresentationForTypeConstant(type);
    return _hashString(4, name);
  }

  visitInterceptor(InterceptorConstant constant) {
    String typeName = constant.dispatchedType.element.name;
    return _hashString(5, typeName);
  }

  visitDummy(DummyConstant constant) {
    compiler.internalError(NO_LOCATION_SPANNABLE,
        'DummyReceiverConstant should never be named and never be subconstant');
  }

  visitDeferred(DeferredConstant constant) {
    int hash = constant.prefix.hashCode;
    return _combine(hash, constant.referenced.accept(this));
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

class FunctionTypeNamer extends DartTypeVisitor {
  final Compiler compiler;
  StringBuffer sb;

  FunctionTypeNamer(this.compiler);

  JavaScriptBackend get backend => compiler.backend;

  String computeName(DartType type) {
    sb = new StringBuffer();
    visit(type);
    return sb.toString();
  }

  visit(DartType type) {
    type.accept(this, null);
  }

  visitType(DartType type, _) {
    sb.write(type.name);
  }

  visitFunctionType(FunctionType type, _) {
    if (backend.rti.isSimpleFunctionType(type)) {
      sb.write('args${type.parameterTypes.slowLength()}');
      return;
    }
    visit(type.returnType);
    sb.write('_');
    for (Link<DartType> link = type.parameterTypes;
         !link.isEmpty;
         link = link.tail) {
      sb.write('_');
      visit(link.head);
    }
    bool first = false;
    for (Link<DartType> link = type.optionalParameterTypes;
         !link.isEmpty;
         link = link.tail) {
      if (!first) {
        sb.write('_');
      }
      sb.write('_');
      visit(link.head);
      first = true;
    }
    if (!type.namedParameterTypes.isEmpty) {
      first = false;
      for (Link<DartType> link = type.namedParameterTypes;
          !link.isEmpty;
          link = link.tail) {
        if (!first) {
          sb.write('_');
        }
        sb.write('_');
        visit(link.head);
        first = true;
      }
    }
  }
}
