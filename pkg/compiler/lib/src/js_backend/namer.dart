// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.namer;

import 'dart:collection' show HashMap;

import 'package:front_end/src/api_unstable/dart2js.dart'
    show $0, $9, $A, $Z, $_, $a, $g, $s, $z;

import 'package:js_runtime/shared/embedded_names.dart' show JsGetName;

import '../closure.dart';
import '../common.dart';
import '../common/codegen.dart';
import '../common/names.dart' show Identifiers, Names, Selectors;
import '../common_elements.dart' show JElementEnvironment;
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../diagnostics/invariant.dart' show DEBUG_MODE;
import '../elements/entities.dart';
import '../elements/entity_utils.dart' as utils;
import '../elements/jumps.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../js/js.dart' as jsAst;
import '../js_backend/field_analysis.dart';
import '../js_model/closure.dart';
import '../js_model/elements.dart' show JGeneratorBody;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector, SelectorKind;
import '../util/util.dart';
import '../world.dart' show JClosedWorld;
import 'native_data.dart';

part 'field_naming_mixin.dart';
part 'frequency_namer.dart';
part 'minify_namer.dart';
part 'namer_names.dart';

/// Assigns JavaScript identifiers to Dart variables, class-names and members.
///
/// Names are generated through three stages:
///
/// 1. Original names and proposed names
/// 2. Disambiguated names (also known as "mangled names")
/// 3. Annotated names
///
/// Original names are names taken directly from the input.
///
/// Proposed names are either original names or synthesized names for input
/// elements that do not have original names.
///
/// Disambiguated names are derived from the above, but are mangled to ensure
/// uniqueness within some namespace (e.g. as fields on the same JS object).
/// In [MinifyNamer], disambiguated names are also minified.
///
/// Annotated names are names generated from a disambiguated name. Annotated
/// names must be computable at runtime by prefixing/suffixing constant strings
/// onto the disambiguated name.
///
/// For example, some entity called `x` might be associated with these names:
///
///     Original name: `x`
///
///     Disambiguated name: `x1` (if something else was called `x`)
///
///     Annotated names: `x1`     (field name)
///                      `get$x1` (getter name)
///                      `set$x1` (setter name)
///
/// The [Namer] can choose the disambiguated names, and to some degree the
/// prefix/suffix constants used to construct annotated names. It cannot choose
/// annotated names with total freedom, for example, it cannot choose that the
/// getter for `x1` should be called `getX` -- the annotated names are always
/// built by concatenation.
///
/// Disambiguated names must be chosen such that none of the annotated names can
/// clash with each other. This may happen even if the disambiguated names are
/// distinct, for example, suppose a field `x` and `get$x` exists in the input:
///
///     Original names: `x` and `get$x`
///
///     Disambiguated names: `x` and `get$x` (the two names a different)
///
///     Annotated names: `x` (field for `x`)
///                      `get$x` (getter for `x`)
///                      `get$x` (field for `get$x`)
///                      `get$get$x` (getter for `get$x`)
///
/// The getter for `x` clashes with the field name for `get$x`, so the
/// disambiguated names are invalid.
///
/// Additionally, disambiguated names must be chosen such that all annotated
/// names are valid JavaScript identifiers and do not coincide with a native
/// JavaScript property such as `__proto__`.
///
/// The following annotated names are generated for instance members, where
/// <NAME> denotes the disambiguated name.
///
/// 0. The disambiguated name can itself be seen as an annotated name.
///
/// 1. Multiple annotated names exist for the `call` method, encoding arity and
///    named parameters with the pattern:
///
///       call$<N>$namedParam1...$namedParam<M>
///
///    where <N> is the number of parameters (required and optional) and <M> is
///    the number of named parameters, and namedParam<n> are the names of the
///    named parameters in alphabetical order.
///
///    Note that the same convention is used for the *proposed name* of other
///    methods. Thus, for ordinary methods, the suffix becomes embedded in the
///    disambiguated name (and can be minified), whereas for the 'call' method,
///    the suffix is an annotation that must be computable at runtime
///    (and thus cannot be minified).
///
///    Note that the ordering of named parameters is not encapsulated in the
///    [Namer], and is hardcoded into other components, such as [Element] and
///    [Selector].
///
/// 2. The getter/setter for a field:
///
///        get$<NAME>
///        set$<NAME>
///
///    (The [getterPrefix] and [setterPrefix] are different in [MinifyNamer]).
///
/// 3. The `is` and operator uses the following names:
///
///        $is<NAME>
///        $as<NAME>
///
/// For local variables, the [Namer] only provides *proposed names*. These names
/// must be disambiguated elsewhere.
class Namer extends ModularNamer {
  static const List<String> javaScriptKeywords = const <String>[
    // ES5 7.6.1.1 Keywords.
    'break',
    'do',
    'instanceof',
    'typeof',
    'case',
    'else',
    'new',
    'var',
    'catch',
    'finally',
    'return',
    'void',
    'continue',
    'for',
    'switch',
    'while',
    'debugger',
    'function',
    'this',
    'with',
    'default',
    'if',
    'throw',
    'delete',
    'in',
    'try',

    // ES5 7.6.1.2 Future Reserved Words.
    'class',
    'enum',
    'extends',
    'super',
    'const',
    'export',
    'import',

    // ES5 7.6.1.2 Words with semantic restrictions.
    'implements',
    'let',
    'private',
    'public',
    'yield',
    'interface',
    'package',
    'protected',
    'static',

    // ES6 11.6.2.1 Keywords (including repeats of ES5 to ease comparison with
    // documents).
    'break',
    'do',
    'in',
    'typeof',
    'case',
    'else',
    'instanceof',
    'var',
    'catch',
    'export',
    'new',
    'void',
    'class',
    'extends',
    'return',
    'while',
    'const',
    'finally',
    'super',
    'with',
    'continue',
    'for',
    'switch',
    'yield',
    'debugger',
    'function',
    'this',
    'default',
    'if',
    'throw',
    'delete',
    'import',
    'try',

    // ES6 11.6.2.1 Words with semantic restrictions.
    'yield', 'let', 'static',

    // ES6 11.6.2.2 Future Reserved Words.
    'enum',
    'await',

    // ES6 11.6.2.2 / ES6 12.1.1 Words with semantic restrictions.
    'implements',
    'package',
    'protected',
    'interface',
    'private',
    'public',

    // Other words to avoid due to non-standard keyword-like behavior.
  ];

  static const List<String> reservedPropertySymbols = const <String>[
    "__proto__", "prototype", "constructor", "call",
    // "use strict" disallows the use of "arguments" and "eval" as
    // variable names or property names. See ECMA-262, Edition 5.1,
    // section 11.1.5 (for the property names).
    "eval", "arguments"
  ];

  // Symbols that we might be using in our JS snippets.
  static const List<String> reservedGlobalSymbols = const <String>[
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
    "RegExp", "Symbol", "Error", "EvalError", "RangeError", "ReferenceError",
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

    // ES6 collections.
    "Map", "Set",
  ];

  static const List<String> reservedGlobalObjectNames = const <String>[
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

  static const List<String> reservedGlobalHelperFunctions = const <String>[
    "init",
    "Isolate",
  ];

  static final List<String> userGlobalObjects =
      new List.from(reservedGlobalObjectNames)
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

  final String lazyGetterPrefix = r'$get$';
  final String superPrefix = r'super$';
  final String metadataField = '@';
  final String stubNameField = r'$stubName';
  final String reflectionInfoField = r'$reflectionInfo';
  final String reflectionNameField = r'$reflectionName';
  final String metadataIndexField = r'$metadataIndex';
  final String methodsWithOptionalArgumentsField =
      r'$methodsWithOptionalArguments';

  @override
  final FixedNames fixedNames;

  /// The non-minifying namer's [callPrefix] with a dollar after it.
  static const String _callPrefixDollar = r'call$';

  static final jsAst.Name _literalDollar = new StringBackedName(r'$');
  static final jsAst.Name _literalUnderscore = new StringBackedName('_');
  static final jsAst.Name literalPlus = new StringBackedName('+');
  static final jsAst.Name _literalDynamic = new StringBackedName("dynamic");

  jsAst.Name _literalGetterPrefix;
  jsAst.Name _literalSetterPrefix;

  jsAst.Name _staticsPropertyName;

  jsAst.Name get staticsPropertyName =>
      _staticsPropertyName ??= new StringBackedName('static');

  jsAst.Name _rtiFieldJsName;

  @override
  jsAst.Name get rtiFieldJsName =>
      _rtiFieldJsName ??= new StringBackedName(fixedNames.rtiName);

  // Name of property in a class description for the native dispatch metadata.
  final String nativeSpecProperty = '%';

  static final RegExp IDENTIFIER = new RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$');
  static final RegExp NON_IDENTIFIER_CHAR = new RegExp(r'[^A-Za-z_0-9$]');

  final JClosedWorld _closedWorld;

  /// Used disambiguated names in the global namespace, issued by
  /// [_disambiguateGlobal], and [_disambiguateInternalGlobal].
  ///
  /// Although global names are distributed across a number of global objects,
  /// (see [globalObjectFor]), we currently use a single namespace for all these
  /// names.
  final NamingScope globalScope = NamingScope();
  final Map<Entity, jsAst.Name> userGlobals = {};
  // [userGlobalsSecondName] is used when an entity has a second name, e.g. a
  // lazily initialized static variable has a location and a getter.
  final Map<Entity, jsAst.Name> userGlobalsSecondName = {};
  final Map<String, jsAst.Name> internalGlobals = {};

  _registerName(
      Map<String, String> map, jsAst.Name jsName, String originalName) {
    // Non-finalized names are not present in the output program
    if (jsName is TokenName && !jsName.isFinalized) return;
    map[jsName.name] = originalName;
    var getterName = userGetters[jsName];
    if (getterName != null) map[getterName.name] = originalName;
    var setterName = userSetters[jsName];
    if (setterName != null) map[setterName.name] = originalName;
  }

  Map<String, String> createMinifiedGlobalNameMap() {
    var map = <String, String>{};
    userGlobals.forEach((entity, jsName) {
      _registerName(map, jsName, entity.name);
    });
    userGlobalsSecondName.forEach((entity, jsName) {
      _registerName(map, jsName, entity.name);
    });
    internalGlobals.forEach((name, jsName) {
      _registerName(map, jsName, name);
    });
    return map;
  }

  /// Used disambiguated names in the instance namespace, issued by
  /// [_disambiguateMember], [_disambiguateInternalMember],
  /// [_disambiguateOperator], and [reservePublicMemberName].
  final NamingScope instanceScope = NamingScope();
  final Map<String, jsAst.Name> userInstanceMembers = HashMap();
  final Map<String, String> userInstanceMembersOriginalName = HashMap();
  final Map<MemberEntity, jsAst.Name> internalInstanceMembers = HashMap();
  final Map<String, jsAst.Name> userInstanceOperators = HashMap();
  final Map<jsAst.Name, jsAst.Name> userGetters = HashMap();
  final Map<jsAst.Name, jsAst.Name> userSetters = HashMap();
  final Map<TypeVariableEntity, jsAst.Name> _typeVariableNames = {};

  Map<String, String> createMinifiedInstanceNameMap() {
    var map = <String, String>{};
    internalInstanceMembers.forEach((entity, jsName) {
      _registerName(map, jsName, entity.name);
    });
    userInstanceMembers.forEach((name, jsName) {
      _registerName(map, jsName, userInstanceMembersOriginalName[name] ?? name);
    });

    // TODO(sigmund): reverse the operator names back to the original Dart
    // names.
    userInstanceOperators.forEach((name, jsName) {
      _registerName(map, jsName, name);
    });
    return map;
  }

  /// Used to disambiguate names for constants in [constantName].
  final NamingScope _constantScope = new NamingScope();

  /// Used to store scopes for instances of [PrivatelyNamedJsEntity]
  final Map<Entity, NamingScope> _privateNamingScopes = {};

  final Map<String, int> popularNameCounters = {};

  final Map<LibraryEntity, String> libraryLongNames = HashMap();

  final Map<ConstantValue, jsAst.Name> _constantNames = HashMap();
  final Map<ConstantValue, String> _constantLongNames = {};
  ConstantCanonicalHasher _constantHasher;

  /// Maps private names to a library that may use that name without prefixing
  /// itself. Used for building proposed names.
  final Map<String, LibraryEntity> shortPrivateNameOwners = {};

  /// Used to store unique keys for library names. Keys are not used as names,
  /// nor are they visible in the output. The only serve as an internal
  /// key into maps.
  final Map<LibraryEntity, String> _libraryKeys = HashMap();

  Namer(this._closedWorld, this.fixedNames) {
    _literalGetterPrefix = new StringBackedName(fixedNames.getterPrefix);
    _literalSetterPrefix = new StringBackedName(fixedNames.setterPrefix);
  }

  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;

  @override
  CommonElements get _commonElements => _closedWorld.commonElements;

  NativeData get _nativeData => _closedWorld.nativeData;

  String get deferredMetadataName => 'deferredMetadata';
  String get deferredTypesName => 'deferredTypes';
  String get isolateName => 'Isolate';
  String get isolatePropertiesName => r'$isolateProperties';
  jsAst.Name get noSuchMethodName => invocationName(Selectors.noSuchMethod_);

  /// Some closures must contain their name. The name is stored in
  /// [STATIC_CLOSURE_NAME_NAME].
  String get STATIC_CLOSURE_NAME_NAME => r'$name';
  String get closureInvocationSelectorName => Identifiers.call;
  bool get shouldMinify => false;

  NamingScope _getPrivateScopeFor(PrivatelyNamedJSEntity entity) {
    return _privateNamingScopes.putIfAbsent(
        entity.rootOfScope, () => new NamingScope());
  }

  /// Return a reference to the given [name].
  ///
  /// This is used to ensure that every use site of a name has a unique node so
  /// that we can properly attribute source information.
  jsAst.Name _newReference(jsAst.Name name) {
    return new _NameReference(name);
  }

  /// Disambiguated name for [constant].
  ///
  /// Unique within the global-member namespace.
  jsAst.Name constantName(ConstantValue constant) {
    // In the current implementation it doesn't make sense to give names to
    // function constants since the function-implementation itself serves as
    // constant and can be accessed directly.
    assert(!constant.isFunction);
    jsAst.Name result = _constantNames[constant];
    if (result == null) {
      String longName = constantLongName(constant);
      result = getFreshName(_constantScope, longName);
      _constantNames[constant] = result;
    }
    return _newReference(result);
  }

  /// Proposed name for [constant].
  String constantLongName(ConstantValue constant) {
    String longName = _constantLongNames[constant];
    if (longName == null) {
      _constantHasher ??= new ConstantCanonicalHasher(this, _closedWorld);
      longName = new ConstantNamingVisitor(this, _closedWorld, _constantHasher)
          .getName(constant);
      _constantLongNames[constant] = longName;
    }
    return longName;
  }

  /// If the [originalName] is not private returns [originalName]. Otherwise
  /// mangles the [originalName] so that each library has its own distinguished
  /// version of the name.
  ///
  /// Although the name is not guaranteed to be unique within any namespace,
  /// clashes are very unlikely in practice. Therefore, it can be used in cases
  /// where uniqueness is nice but not a strict requirement.
  ///
  /// The resulting name is a *proposed name* and is never minified.
  String privateName(Name originalName) {
    String text = originalName.text;

    text = text.replaceAll(_nonIdentifierRE, '_');

    // Public names are easy.
    if (!originalName.isPrivate) return text;

    LibraryEntity library = originalName.library;

    // The first library asking for a short private name wins.
    LibraryEntity owner =
        shortPrivateNameOwners.putIfAbsent(text, () => library);

    if (owner == library) {
      return text;
    } else {
      // Make sure to return a private name that starts with _ so it
      // cannot clash with any public names.
      // The name is still not guaranteed to be unique, since both the library
      // name and originalName could contain $ symbols and as the library
      // name itself might clash.
      String libraryName = _proposeNameForLibrary(library);
      return "_$libraryName\$$text";
    }
  }

  String _proposeNameForConstructorBody(ConstructorBodyEntity method) {
    String name = utils.reconstructConstructorNameSourceString(method);
    // We include the method suffix on constructor bodies. It has no purpose,
    // but this way it produces the same names as previous versions of the
    // Namer class did.
    List<String> suffix = callSuffixForSignature(method.parameterStructure);
    return '$name\$${suffix.join(r'$')}';
  }

  /// Name for a constructor body.
  jsAst.Name constructorBodyName(ConstructorBodyEntity ctor) {
    return _disambiguateInternalMember(
        ctor, () => _proposeNameForConstructorBody(ctor));
  }

  /// Name for a generator body.
  jsAst.Name generatorBodyInstanceMethodName(JGeneratorBody method) {
    assert(method.isInstanceMember);
    // TODO(sra): Except for methods declared in mixins, we can use a compact
    // naming scheme like we do for [ConstructorBodyEntity].
    FunctionEntity function = method.function;
    return _disambiguateInternalMember(method, () {
      String invocationName = operatorNameToIdentifier(function.name);
      // TODO(sra): If the generator is for a closure's 'call' method, we don't
      // need to incorporate the enclosing class.
      String className =
          method.enclosingClass.name.replaceAll(_nonIdentifierRE, '_');
      return '${invocationName}\$body\$${className}';
    });
  }

  @override
  jsAst.Name instanceMethodName(FunctionEntity method) {
    // TODO(johnniwinther): Avoid the use of [ConstructorBodyEntity] and
    // [JGeneratorBody]. The codegen model should be explicit about its
    // constructor body elements.
    if (method is ConstructorBodyEntity) {
      return constructorBodyName(method);
    }
    if (method is JGeneratorBody) {
      return generatorBodyInstanceMethodName(method);
    }
    return invocationName(new Selector.fromElement(method));
  }

  /// Returns the annotated name for a variant of `call`.
  /// The result has the form:
  ///
  ///     call$<N>$namedParam1...$namedParam<M>
  ///
  /// This name cannot be minified because it is generated by string
  /// concatenation at runtime, by applyFunction in js_helper.dart.
  jsAst.Name deriveCallMethodName(List<String> suffix) {
    // TODO(asgerf): Avoid clashes when named parameters contain $ symbols.
    return new StringBackedName(
        '${fixedNames.callPrefix}\$${suffix.join(r'$')}');
  }

  /// The suffix list for the pattern:
  ///
  ///     $<T>$<N>$namedParam1...$namedParam<M>
  ///
  /// Where <T> is the number of type arguments, <N> is the number of positional
  /// arguments and <M> is the number of named arguments.
  ///
  /// If there are no type arguments the `$<T>` is omitted.
  ///
  /// This is used for the annotated names of `call`, and for the proposed name
  /// for other instance methods.
  static List<String> callSuffixForStructure(CallStructure callStructure) {
    List<String> suffixes = [];
    if (callStructure.typeArgumentCount > 0) {
      suffixes.add('${callStructure.typeArgumentCount}');
    }
    suffixes.add('${callStructure.argumentCount}');
    suffixes.addAll(callStructure.getOrderedNamedArguments());
    return suffixes;
  }

  /// The suffix list for the pattern:
  ///
  ///     $<N>$namedParam1...$namedParam<M>
  ///
  /// This is used for the annotated names of `call`, and for the proposed name
  /// for other instance methods.
  List<String> callSuffixForSignature(ParameterStructure parameterStructure) {
    List<String> suffixes = ['${parameterStructure.totalParameters}'];
    suffixes.addAll(parameterStructure.namedParameters);
    return suffixes;
  }

  @override
  jsAst.Name invocationName(Selector selector) {
    switch (selector.kind) {
      case SelectorKind.GETTER:
        jsAst.Name disambiguatedName = _disambiguateMember(selector.memberName);
        return deriveGetterName(disambiguatedName);

      case SelectorKind.SETTER:
        jsAst.Name disambiguatedName = _disambiguateMember(selector.memberName);
        return deriveSetterName(disambiguatedName);

      case SelectorKind.OPERATOR:
      case SelectorKind.INDEX:
        String operatorIdentifier = operatorNameToIdentifier(selector.name);
        jsAst.Name disambiguatedName =
            _disambiguateOperator(operatorIdentifier);
        return disambiguatedName; // Operators are not annotated.

      case SelectorKind.CALL:
        List<String> suffix = callSuffixForStructure(selector.callStructure);
        if (selector.name == Identifiers.call) {
          // Derive the annotated name for this variant of 'call'.
          return deriveCallMethodName(suffix);
        }
        jsAst.Name disambiguatedName =
            _disambiguateMember(selector.memberName, suffix);
        return disambiguatedName; // Methods other than call are not annotated.

      case SelectorKind.SPECIAL:
        return specialSelectorName(selector);

      default:
        throw failedAt(CURRENT_ELEMENT_SPANNABLE,
            'Unexpected selector kind: ${selector.kind}');
    }
  }

  jsAst.Name specialSelectorName(Selector selector) {
    assert(selector.kind == SelectorKind.SPECIAL);
    if (selector.memberName == Names.genericInstantiation) {
      return new StringBackedName('${genericInstantiationPrefix}'
          '${selector.callStructure.typeArgumentCount}');
    }

    throw failedAt(
        CURRENT_ELEMENT_SPANNABLE, 'Unexpected special selector: $selector');
  }

  /// Returns the internal name used for an invocation mirror of this selector.
  jsAst.Name invocationMirrorInternalName(Selector selector) =>
      invocationName(selector);

  /// Returns the disambiguated name for the given field, used for constructing
  /// the getter and setter names.
  jsAst.Name fieldAccessorName(FieldEntity element) {
    return element.isInstanceMember
        ? _disambiguateMember(element.memberName)
        : _disambiguateGlobalMember(element);
  }

  /// Returns name of the JavaScript property used to store a static or instance
  /// field.
  jsAst.Name fieldPropertyName(FieldEntity element) {
    return element.isInstanceMember
        ? instanceFieldPropertyName(element)
        : _disambiguateGlobalMember(element);
  }

  @override
  jsAst.Name globalPropertyNameForMember(MemberEntity element) =>
      _disambiguateGlobalMember(element);

  @override
  jsAst.Name globalPropertyNameForClass(ClassEntity element) =>
      _disambiguateGlobalType(element);

  @override
  jsAst.Name globalPropertyNameForType(Entity element) =>
      _disambiguateGlobalType(element);

  @override
  jsAst.Name globalNameForInterfaceTypeVariable(TypeVariableEntity element) {
    return _typeVariableNames[element] ??=
        _globalNameForInterfaceTypeVariable(element);
  }

  jsAst.Name _globalNameForInterfaceTypeVariable(TypeVariableEntity element) {
    // Construct a name from the class name and type variable,
    // e.g. "ListMixin.E". The class name is unique which ensures the type
    // variable name is unique.
    //
    // TODO(sra): Better minified naming. Type variable names are used in type
    // recipes and must contain a period ('.'). They can be frequency-assigned
    // independently of the class name, e.g. '.a', '.2', 'a.', etc.
    String name = element.name;
    if (name.length > 1) name = '${element.index}'; // Avoid long names (rare).
    return CompoundName([
      globalPropertyNameForClass(element.typeDeclaration),
      StringBackedName('.$name')
    ]);
  }

  @override
  jsAst.Name instanceFieldPropertyName(FieldEntity element) {
    ClassEntity enclosingClass = element.enclosingClass;

    if (_nativeData.hasFixedBackendName(element)) {
      return new StringBackedName(_nativeData.getFixedBackendName(element));
    }

    // Some elements, like e.g. instances of BoxFieldElement are special.
    // They are created with a unique and safe name for the element model.
    // While their name is unique, it is not very readable. So we try to
    // preserve the original, proposed name.
    // However, as boxes are not really instances of classes, the usual naming
    // scheme that tries to avoid name clashes with super classes does not
    // apply. So we can directly grab a name.
    if (element is JSEntity) {
      return _disambiguateInternalMember(
          element,
          () => (element as JSEntity)
              .declaredName
              .replaceAll(_nonIdentifierRE, '_'));
    }

    // If the name of the field might clash with another field,
    // use a mangled field name to avoid potential clashes.
    // Note that if the class extends a native class, that native class might
    // have fields with fixed backend names, so we assume the worst and always
    // mangle the field names of classes extending native classes.
    // Methods on such classes are stored on the interceptor, not the instance,
    // so only fields have the potential to clash with a native property name.
    if (_closedWorld.isUsedAsMixin(enclosingClass) ||
        _isShadowingSuperField(element) ||
        _isUserClassExtendingNative(enclosingClass)) {
      String proposeName() => '${enclosingClass.name}_${element.name}'
          .replaceAll(_nonIdentifierRE, '_');
      return _disambiguateInternalMember(element, proposeName);
    }

    // No superclass uses the disambiguated name as a property name, so we can
    // use it for this field. This generates nicer field names since otherwise
    // the field name would have to be mangled.
    return _disambiguateMember(new Name(element.name, element.library));
  }

  bool _isShadowingSuperField(FieldEntity element) {
    assert(element.isField);
    String fieldName = element.name;
    bool isPrivate = Name.isPrivateName(fieldName);
    LibraryEntity memberLibrary = element.library;
    ClassEntity lookupClass =
        _elementEnvironment.getSuperClass(element.enclosingClass);
    while (lookupClass != null) {
      MemberEntity foundMember =
          _elementEnvironment.lookupLocalClassMember(lookupClass, fieldName);
      if (foundMember != null) {
        if (foundMember.isField) {
          if (!isPrivate || memberLibrary == foundMember.library) {
            // Private fields can only be shadowed by a field declared in the
            // same library.
            return true;
          }
        }
      }
      lookupClass = _elementEnvironment.getSuperClass(lookupClass);
    }
    return false;
  }

  /// True if [class_] is a non-native class that inherits from a native class.
  bool _isUserClassExtendingNative(ClassEntity class_) {
    return !_nativeData.isNativeClass(class_) &&
        _nativeData.isNativeOrExtendsNative(class_);
  }

  /// Annotated name for the setter of [element].
  jsAst.Name setterForMember(MemberEntity element) {
    // We dynamically create setters from the field-name. The setter name must
    // therefore be derived from the instance field-name.
    jsAst.Name name = _disambiguateMember(element.memberName);
    return deriveSetterName(name);
  }

  /// Annotated name for the setter of any member with [disambiguatedName].
  jsAst.Name deriveSetterName(jsAst.Name disambiguatedName) {
    // We dynamically create setters from the field-name. The setter name must
    // therefore be derived from the instance field-name.
    return userSetters[disambiguatedName] ??=
        new SetterName(_literalSetterPrefix, disambiguatedName);
  }

  /// Annotated name for the setter of any member with [disambiguatedName].
  jsAst.Name deriveGetterName(jsAst.Name disambiguatedName) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    return userGetters[disambiguatedName] ??=
        new GetterName(_literalGetterPrefix, disambiguatedName);
  }

  /// Annotated name for the getter of [element].
  jsAst.Name getterForElement(MemberEntity element) {
    // We dynamically create getters from the field-name. The getter name must
    // therefore be derived from the instance field-name.
    jsAst.Name name = _disambiguateMember(element.memberName);
    return deriveGetterName(name);
  }

  /// Property name for the getter of an instance member with [originalName].
  jsAst.Name getterForMember(Name originalName) {
    jsAst.Name disambiguatedName = _disambiguateMember(originalName);
    return deriveGetterName(disambiguatedName);
  }

  /// Disambiguated name for a compiler-owned global variable.
  ///
  /// The resulting name is unique within the global-member namespace.
  jsAst.Name _disambiguateInternalGlobal(String name) {
    jsAst.Name newName = internalGlobals[name];
    if (newName == null) {
      newName = getFreshName(globalScope, name);
      internalGlobals[name] = newName;
    }
    return _newReference(newName);
  }

  /// Returns the property name to use for a compiler-owner global variable,
  /// i.e. one that does not correspond to any element but is used as a utility
  /// global by code generation.
  ///
  /// [name] functions as both the proposed name for the global, and as a key
  /// identifying the global. The [name] must not contain `$` symbols, since
  /// the [Namer] uses those names internally.
  ///
  /// This provides an easy mechanism of avoiding a name-clash with user-space
  /// globals, although the callers of must still take care not to accidentally
  /// pass in the same [name] for two different internal globals.
  jsAst.Name internalGlobal(String name) {
    assert(!name.contains(r'$'));
    return _disambiguateInternalGlobal(name);
  }

  /// Generates a unique key for [library].
  ///
  /// Keys are meant to be used in maps and should not be visible in the output.
  String _generateLibraryKey(LibraryEntity library) {
    return _libraryKeys.putIfAbsent(library, () {
      String keyBase = library.name;
      int counter = 0;
      String key = keyBase;
      while (_libraryKeys.values.contains(key)) {
        key = "$keyBase${counter++}";
      }
      return key;
    });
  }

  jsAst.Name _disambiguateGlobalMember(MemberEntity element) {
    return _disambiguateGlobal<MemberEntity>(
        element, _proposeNameForMember, userGlobals);
  }

  jsAst.Name _disambiguateGlobalType(Entity element) {
    return _disambiguateGlobal(element, _proposeNameForType, userGlobals);
  }

  /// Returns the disambiguated name for a top-level or static element.
  ///
  /// The resulting name is unique within the global-member namespace.
  jsAst.Name _disambiguateGlobal<T extends Entity>(T element,
      String proposeName(T element), Map<Entity, jsAst.Name> globals) {
    // TODO(asgerf): We can reuse more short names if we disambiguate with
    // a separate namespace for each of the global holder objects.
    jsAst.Name newName = globals[element];
    if (newName == null) {
      String proposedName = proposeName(element);
      newName = getFreshName(globalScope, proposedName);
      globals[element] = newName;
    }
    return _newReference(newName);
  }

  /// Returns the disambiguated name for an instance method or field
  /// with [originalName] in [library].
  ///
  /// [library] may be `null` if [originalName] is known to be public.
  ///
  /// This is the name used for deriving property names of accessors (getters
  /// and setters) and as property name for storing methods and method stubs.
  ///
  /// [suffixes] denote an extension of [originalName] to distinguish it from
  /// other members with that name. These are used to encode the arity and
  /// named parameters to a method. Disambiguating the same [originalName] with
  /// different [suffixes] will yield different disambiguated names.
  ///
  /// The resulting name, and its associated annotated names, are unique
  /// to the ([originalName], [suffixes]) pair within the instance-member
  /// namespace.
  jsAst.Name _disambiguateMember(Name originalName,
      [List<String> suffixes = const []]) {
    // Build a string encoding the library name, if the name is private.
    String libraryKey =
        originalName.isPrivate ? _generateLibraryKey(originalName.library) : '';

    // In the unique key, separate the name parts by '@'.
    // This avoids clashes since the original names cannot contain that symbol.
    String key = '$libraryKey@${originalName.text}@${suffixes.join('@')}';
    jsAst.Name newName = userInstanceMembers[key];
    if (newName == null) {
      String proposedName = privateName(originalName);
      if (!suffixes.isEmpty) {
        // In the proposed name, separate the name parts by '$', because the
        // proposed name must be a valid identifier, but not necessarily unique.
        proposedName += r'$' + suffixes.join(r'$');
      }
      newName = getFreshName(instanceScope, proposedName,
          sanitizeForAnnotations: true);
      userInstanceMembers[key] = newName;
      userInstanceMembersOriginalName[key] = '$originalName';
    }
    return _newReference(newName);
  }

  /// Returns the disambiguated name for the instance member identified by
  /// [key].
  ///
  /// When a name for an element is requested by key, it may not be requested
  /// by element at the same time, as two different names would be returned.
  ///
  /// If key has not yet been registered, [proposeName] is used to generate
  /// a name proposal for the given key.
  ///
  /// [key] must not clash with valid instance names. This is typically
  /// achieved by using at least one character in [key] that is not valid in
  /// identifiers, for example the @ symbol.
  jsAst.Name _disambiguateMemberByKey(String key, String proposeName()) {
    jsAst.Name newName = userInstanceMembers[key];
    if (newName == null) {
      String name = proposeName();
      newName = getFreshName(instanceScope, name, sanitizeForAnnotations: true);
      userInstanceMembers[key] = newName;
      // TODO(sigmund): consider plumbing the original name instead.
      userInstanceMembersOriginalName[key] = name;
    }
    return _newReference(newName);
  }

  /// Forces the public instance member with [originalName] to have the given
  /// [disambiguatedName].
  ///
  /// The [originalName] must not have been disambiguated before, and the
  /// [disambiguatedName] must not have been used.
  ///
  /// Using [_disambiguateMember] with the given [originalName] and no suffixes
  /// will subsequently return [disambiguatedName].
  void reservePublicMemberName(String originalName, String disambiguatedName) {
    // Build a key that corresponds to the one built in disambiguateMember.
    String libraryPrefix = ''; // Public names have an empty library prefix.
    String suffix = ''; // We don't need any suffixes.
    String key = '$libraryPrefix@$originalName@$suffix';
    assert(!userInstanceMembers.containsKey(key));
    assert(!instanceScope.isUsed(disambiguatedName));
    userInstanceMembers[key] = new StringBackedName(disambiguatedName);
    userInstanceMembersOriginalName[key] = originalName;
    instanceScope.registerUse(disambiguatedName);
  }

  /// Disambiguated name unique to [element].
  ///
  /// This is used as the property name for fields, type variables,
  /// constructor bodies, and super-accessors.
  ///
  /// The resulting name is unique within the instance-member namespace.
  jsAst.Name _disambiguateInternalMember(
      MemberEntity element, String proposeName()) {
    jsAst.Name newName = internalInstanceMembers[element];
    if (newName == null) {
      String name = proposeName();

      if (element is PrivatelyNamedJSEntity) {
        NamingScope scope = _getPrivateScopeFor(element);
        newName = getFreshName(scope, name,
            sanitizeForAnnotations: true, sanitizeForNatives: false);
        internalInstanceMembers[element] = newName;
      } else {
        bool mayClashNative =
            _isUserClassExtendingNative(element.enclosingClass);
        newName = getFreshName(instanceScope, name,
            sanitizeForAnnotations: true, sanitizeForNatives: mayClashNative);
        internalInstanceMembers[element] = newName;
      }
    }
    return _newReference(newName);
  }

  /// Disambiguated name for the given operator.
  ///
  /// [operatorIdentifier] must be the operator's identifier, e.g.
  /// `$add` and not `+`.
  ///
  /// The resulting name is unique within the instance-member namespace.
  jsAst.Name _disambiguateOperator(String operatorIdentifier) {
    jsAst.Name newName = userInstanceOperators[operatorIdentifier];
    if (newName == null) {
      newName = getFreshName(instanceScope, operatorIdentifier);
      userInstanceOperators[operatorIdentifier] = newName;
    }
    return _newReference(newName);
  }

  String _generateFreshStringForName(String proposedName, NamingScope scope,
      {bool sanitizeForAnnotations: false, bool sanitizeForNatives: false}) {
    if (sanitizeForAnnotations) {
      proposedName = _sanitizeForAnnotations(proposedName);
    }
    if (sanitizeForNatives) {
      proposedName = _sanitizeForNatives(proposedName);
    }
    proposedName = _sanitizeForKeywords(proposedName);
    String candidate;
    if (scope.isUnused(proposedName)) {
      candidate = proposedName;
    } else {
      int counter = popularNameCounters[proposedName];
      int i = (counter == null) ? 0 : counter;
      while (scope.isUsed("$proposedName$i")) {
        i++;
      }
      popularNameCounters[proposedName] = i + 1;
      candidate = "$proposedName$i";
    }
    scope.registerUse(candidate);
    return candidate;
  }

  /// Returns an unused name.
  ///
  /// [proposedName] must be a valid JavaScript identifier.
  ///
  /// If [sanitizeForAnnotations] is `true`, then the result is guaranteed not
  /// to have the form of an annotated name.
  ///
  /// If [sanitizeForNatives] it `true`, then the result is guaranteed not to
  /// clash with a property name on a native object.
  ///
  /// Note that [MinifyNamer] overrides this method with one that produces
  /// minified names.
  jsAst.Name getFreshName(NamingScope scope, String proposedName,
      {bool sanitizeForAnnotations: false, bool sanitizeForNatives: false}) {
    String candidate = _generateFreshStringForName(proposedName, scope,
        sanitizeForAnnotations: sanitizeForAnnotations,
        sanitizeForNatives: sanitizeForNatives);
    return new StringBackedName(candidate);
  }

  /// Returns a variant of [name] that cannot clash with the annotated
  /// version of another name, that is, the resulting name can never be returned
  /// by [deriveGetterName], [deriveSetterName], [deriveCallMethodName],
  /// [operatorIs], or [substitutionName].
  ///
  /// For example, a name `get$x` would be converted to `$get$x` to ensure it
  /// cannot clash with the getter for `x`.
  ///
  /// We don't want to register all potential annotated names in
  /// [usedInstanceNames] (there are too many), so we use this step to avoid
  /// clashes between annotated and unannotated names.
  String _sanitizeForAnnotations(String name) {
    // Ensure name does not clash with a getter or setter of another name,
    // one of the other special names that start with `$`, such as `$is`,
    // or with one of the `call` stubs, such as `call$1`.
    assert(this is! MinifyNamer);
    if (name.startsWith(r'$') ||
        name.startsWith(fixedNames.getterPrefix) ||
        name.startsWith(fixedNames.setterPrefix) ||
        name.startsWith(_callPrefixDollar)) {
      name = '\$$name';
    }
    return name;
  }

  /// Returns a variant of [name] that cannot clash with a native property name
  /// (e.g. the name of a method on a JS DOM object).
  ///
  /// If [name] is not an annotated name, the result will not be an annotated
  /// name either.
  String _sanitizeForNatives(String name) {
    if (!name.contains(r'$')) {
      // Prepend $$. The result must not coincide with an annotated name.
      name = '\$\$$name';
    }
    return name;
  }

  /// Returns a proposed name for the given typedef or class [element].
  /// The returned id is guaranteed to be a valid JavaScript identifier.
  String _proposeNameForType(Entity element) {
    return element.name.replaceAll(_nonIdentifierRE, '_');
  }

  static RegExp _nonIdentifierRE = new RegExp(r'[^A-Za-z0-9_$]');

  /// Returns a proposed name for the given top-level or static member
  /// [element]. The returned id is guaranteed to be a valid JavaScript
  /// identifier.
  String _proposeNameForMember(MemberEntity element) {
    if (element.isConstructor) {
      return _proposeNameForConstructor(element);
    } else if (element is JGeneratorBody) {
      return _proposeNameForMember(element.function) + r'$body';
    } else if (element.enclosingClass != null) {
      ClassEntity enclosingClass = element.enclosingClass;
      return '${enclosingClass.name}_${element.name}'
          .replaceAll(_nonIdentifierRE, '_');
    }
    return element.name.replaceAll(_nonIdentifierRE, '_');
  }

  String _proposeNameForLazyStaticGetter(MemberEntity element) {
    return r'$get$' + _proposeNameForMember(element);
  }

  String _proposeNameForConstructor(ConstructorEntity element) {
    String className = element.enclosingClass.name;
    if (element.isGenerativeConstructor) {
      return '${className}\$${element.name}';
    } else {
      // TODO(johnniwinther): Change factory name encoding as to not include
      // the class-name twice.
      return '${className}_${utils.reconstructConstructorName(element)}';
    }
  }

  /// Returns a proposed name for the given [LibraryElement].
  /// The returned id is guaranteed to be a valid JavaScript identifier.
  // TODO(sra): Pre-process libraries to assign [libraryLongNames] in a way that
  // is independent of the order of calls to namer.
  String _proposeNameForLibrary(LibraryEntity library) {
    String name = libraryLongNames[library];
    if (name != null) return name;
    // Use the 'file' name, e.g. "package:expect/expect.dart" -> "expect"
    name = library.canonicalUri.path;
    name = name.substring(name.lastIndexOf('/') + 1);
    if (name.contains('.')) {
      // Drop file extension.
      name = name.substring(0, name.lastIndexOf('.'));
    }
    // The filename based name can contain all kinds of nasty characters. Make
    // sure it is an identifier.
    if (!IDENTIFIER.hasMatch(name)) {
      String replacer(Match match) {
        String s = match[0];
        if (s == '.') return '_';
        return s.codeUnitAt(0).toRadixString(16);
      }

      name = name.replaceAllMapped(NON_IDENTIFIER_CHAR, replacer);
      if (!IDENTIFIER.hasMatch(name)) {
        // e.g. starts with digit.
        name = 'lib_$name';
      }
    }
    // Names constructed based on a libary name will be further disambiguated.
    // However, as names from the same libary should have the same library
    // name part, we disambiguate the library name here.
    String disambiguated = name;
    for (int c = 0; libraryLongNames.containsValue(disambiguated); c++) {
      disambiguated = "$name$c";
    }
    libraryLongNames[library] = disambiguated;
    return disambiguated;
  }

  String _getSuffixForInterceptedClasses(Iterable<ClassEntity> classes) {
    if (classes.isEmpty) {
      // TODO(johnniwinther,sra): If [classes] is empty it should either have
      // its own suffix (like here), or always be equated with the set of
      // classes that contain `Interceptor`. For the latter to work we need to
      // update `OneShotInterceptorData.registerSpecializedGetInterceptor`,
      // since it currently would otherwise potentially overwrite the all
      // intercepted classes case with the empty case.
      return 'z';
    } else if (classes.contains(_commonElements.jsInterceptorClass)) {
      // If the base Interceptor class is in the set of intercepted classes,
      // this is the most general specialization which uses the generic
      // getInterceptor method.
      // TODO(sra): Find a way to get the simple name when Object is not in the
      // set of classes for most general variant, e.g. "$lt$n" could be "$lt".
      return '';
    } else {
      return suffixForGetInterceptor(_commonElements, _nativeData, classes);
    }
  }

  @override
  jsAst.Name nameForGetInterceptor(Iterable<ClassEntity> classes) {
    // If the base Interceptor class is in the set of intercepted classes, we
    // need to go through the generic getInterceptor method (any subclass of the
    // base Interceptor could match), which is encoded as an empty suffix.
    String suffix = _getSuffixForInterceptedClasses(classes);
    return _disambiguateInternalGlobal('getInterceptor\$$suffix');
  }

  @override
  jsAst.Name nameForOneShotInterceptor(
      Selector selector, Iterable<ClassEntity> classes) {
    // The one-shot name is a global name derived from the invocation name.  To
    // avoid instability we would like the names to be unique and not clash with
    // other global names.
    jsAst.Name root = invocationName(selector);

    String suffix = _getSuffixForInterceptedClasses(classes);
    return new CompoundName(
        [root, _literalDollar, new StringBackedName(suffix)]);
  }

  @override
  jsAst.Name runtimeTypeName(Entity element) {
    if (element == null) return _literalDynamic;
    // The returned name affects both the global and instance member namespaces:
    //
    // - If given a class, this must coincide with the class name, which
    //   is also the GLOBAL property name of its constructor.
    //
    // - The result is used to derive `$isX` and `$asX` names, which are used
    //   as INSTANCE property names.
    //
    // To prevent clashes in both namespaces at once, we disambiguate the name
    // as a global here, and in [_sanitizeForAnnotations] we ensure that
    // ordinary instance members cannot start with `$is` or `$as`.
    return _disambiguateGlobalType(element);
  }

  @override
  jsAst.Name className(ClassEntity class_) => _disambiguateGlobalType(class_);

  @override
  jsAst.Name aliasedSuperMemberPropertyName(MemberEntity member) {
    assert(!member.isField); // Fields do not need super aliases.
    return _disambiguateInternalMember(member, () {
      String className = member.enclosingClass.name.replaceAll('&', '_');
      String invocationName = operatorNameToIdentifier(member.name);
      return "super\$${className}\$$invocationName";
    });
  }

  @override
  jsAst.Name methodPropertyName(FunctionEntity method) {
    return method.isInstanceMember
        ? instanceMethodName(method)
        : globalPropertyNameForMember(method);
  }

  /// Returns true if [element] is stored in the static state holder
  /// ([staticStateHolder]).  We intend to store only mutable static state
  /// there, whereas constants are stored in 'C'. Functions, accessors,
  /// classes, etc. are stored in one of the other objects in
  /// [reservedGlobalObjectNames].
  bool _isPropertyOfStaticStateHolder(MemberEntity element) {
    // TODO(ahe): Make sure this method's documentation is always true and
    // remove the word "intend".
    return element.isField;
  }

  /// Returns [staticStateHolder] or one of [reservedGlobalObjectNames].
  String globalObjectForMember(MemberEntity element) {
    if (_isPropertyOfStaticStateHolder(element)) return staticStateHolder;
    return globalObjectForLibrary(element.library);
  }

  @override
  jsAst.VariableUse readGlobalObjectForMember(MemberEntity element) {
    if (_isPropertyOfStaticStateHolder(element)) {
      return new jsAst.VariableUse(staticStateHolder);
    }
    return readGlobalObjectForLibrary(element.library);
  }

  String globalObjectForClass(ClassEntity element) {
    return globalObjectForLibrary(element.library);
  }

  @override
  jsAst.VariableUse readGlobalObjectForClass(ClassEntity element) {
    return readGlobalObjectForLibrary(element.library);
  }

  String globalObjectForType(Entity element) {
    return globalObjectForClass(element);
  }

  @override
  jsAst.VariableUse readGlobalObjectForType(Entity element) {
    return readGlobalObjectForClass(element);
  }

  /// Returns the [reservedGlobalObjectNames] for [library].
  String globalObjectForLibrary(LibraryEntity library) {
    if (library == _commonElements.interceptorsLibrary) return 'J';
    Uri uri = library.canonicalUri;
    if (uri.scheme == 'dart') {
      if (uri.path == 'html') return 'W';
      if (uri.path.startsWith('_')) return 'H';
      return 'P';
    }
    return userGlobalObjects[library.name.hashCode % userGlobalObjects.length];
  }

  @override
  jsAst.VariableUse readGlobalObjectForLibrary(LibraryEntity library) {
    return new jsAst.VariableUse(globalObjectForLibrary(library));
  }

  @override
  jsAst.Name lazyInitializerName(FieldEntity element) {
    assert(element.isTopLevel || element.isStatic);
    jsAst.Name name = _disambiguateGlobal<MemberEntity>(
        element, _proposeNameForLazyStaticGetter, userGlobalsSecondName);
    return name;
  }

  @override
  jsAst.Name staticClosureName(FunctionEntity element) {
    assert(element.isTopLevel || element.isStatic);
    String enclosing =
        element.enclosingClass == null ? "" : element.enclosingClass.name;
    String library = _proposeNameForLibrary(element.library);
    String name = element.name.replaceAll(_nonIdentifierRE, '_');
    return _disambiguateInternalGlobal(
        "${library}_${enclosing}_${name}\$closure");
  }

  // This name is used as part of the name of a TypeConstant
  String uniqueNameForTypeConstantElement(
      LibraryEntity library, Entity element) {
    // TODO(sra): If we replace the period with an identifier character,
    // TypeConstants will have better names in unminified code.
    String libraryName = _proposeNameForLibrary(library);
    return "${libraryName}.${element.name}";
  }

  String globalObjectForConstant(ConstantValue constant) => 'C';

  String get genericInstantiationPrefix => r'$instantiate';

  // The name of the variable used to offset function signatures in deferred
  // parts with the fast-startup emitter.
  String get typesOffsetName => r'typesOffset';

  Map<FunctionType, jsAst.Name> functionTypeNameMap = HashMap();

  FunctionTypeNamer _functionTypeNamer;

  jsAst.Name getFunctionTypeName(FunctionType functionType) {
    return functionTypeNameMap.putIfAbsent(functionType, () {
      _functionTypeNamer ??= new FunctionTypeNamer();
      String proposedName = _functionTypeNamer.computeName(functionType);
      return getFreshName(instanceScope, proposedName);
    });
  }

  @override
  jsAst.Name operatorIsType(DartType type) {
    if (type is FunctionType) {
      // TODO(erikcorry): Reduce from $isx to ix when we are minifying.
      return new CompoundName([
        new StringBackedName(fixedNames.operatorIsPrefix),
        _literalUnderscore,
        getFunctionTypeName(type)
      ]);
    }
    InterfaceType interfaceType = type;
    return operatorIs(interfaceType.element);
  }

  @override
  jsAst.Name operatorIs(ClassEntity element) {
    // TODO(erikcorry): Reduce from $isx to ix when we are minifying.
    return new CompoundName([
      new StringBackedName(fixedNames.operatorIsPrefix),
      runtimeTypeName(element)
    ]);
  }

  /// Returns a name that does not clash with reserved JS keywords.
  String _sanitizeForKeywords(String name) {
    if (jsReserved.contains(name)) {
      name = '\$$name';
    }
    assert(!jsReserved.contains(name));
    return name;
  }

  @override
  jsAst.Name substitutionName(ClassEntity element) {
    return new CompoundName([
      new StringBackedName(fixedNames.operatorAsPrefix),
      runtimeTypeName(element)
    ]);
  }

  @override
  jsAst.Name asName(String name) {
    if (name.startsWith(fixedNames.getterPrefix) &&
        name.length > fixedNames.getterPrefix.length) {
      return new GetterName(_literalGetterPrefix,
          new StringBackedName(name.substring(fixedNames.getterPrefix.length)));
    }
    if (name.startsWith(fixedNames.setterPrefix) &&
        name.length > fixedNames.setterPrefix.length) {
      return new GetterName(_literalSetterPrefix,
          new StringBackedName(name.substring(fixedNames.setterPrefix.length)));
    }

    return new StringBackedName(name);
  }

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
    } else if (name == '>>>') {
      return r'$shru';
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

  String getTypeRepresentationForTypeConstant(DartType type) {
    type = type.withoutNullability;
    if (type is DynamicType) return "dynamic";
    if (type is NeverType) return "Never";
    if (type is FutureOrType) {
      return "FutureOr<dynamic>";
    }
    if (type is FunctionType) {
      // TODO(johnniwinther): Add naming scheme for function type literals.
      // These currently only occur from kernel.
      return '()->';
    }
    InterfaceType interface = type;
    String name = uniqueNameForTypeConstantElement(
        interface.element.library, interface.element);

    // Type constants can currently only be raw types, so there is no point
    // adding ground-term type parameters, as they would just be 'dynamic'.
    // TODO(sra): Since the result string is used only in constructing constant
    // names, it would result in more readable names if the final string was a
    // legal JavaScript identifier.
    if (interface.typeArguments.isEmpty) return name;
    String arguments =
        new List.filled(interface.typeArguments.length, 'dynamic').join(', ');
    return '$name<$arguments>';
  }
}

/// Returns a unique suffix for an intercepted accesses to [classes]. This is
/// used as the suffix for emitted interceptor methods and as the unique key
/// used to distinguish equivalences of sets of intercepted classes.
String suffixForGetInterceptor(CommonElements commonElements,
    NativeData nativeData, Iterable<ClassEntity> classes) {
  String abbreviate(ClassEntity cls) {
    if (cls == commonElements.objectClass) return "o";
    if (cls == commonElements.jsStringClass) return "s";
    if (cls == commonElements.jsArrayClass) return "a";
    if (cls == commonElements.jsDoubleClass) return "d";
    if (cls == commonElements.jsIntClass) return "i";
    if (cls == commonElements.jsNumberClass) return "n";
    if (cls == commonElements.jsNullClass) return "u";
    if (cls == commonElements.jsBoolClass) return "b";
    if (cls == commonElements.jsInterceptorClass) return "I";
    return cls.name;
  }

  List<String> names = classes
      .where((cls) => !nativeData.isNativeOrExtendsNative(cls))
      .map(abbreviate)
      .toList();
  // There is one dispatch mechanism for all native classes.
  if (classes.any((cls) => nativeData.isNativeOrExtendsNative(cls))) {
    names.add("x");
  }
  // Sort the names of the classes after abbreviating them to ensure
  // the suffix is stable and predictable for the suggested names.
  names.sort();
  return names.join();
}

/// Generator of names for [ConstantValue] values.
///
/// The names are stable under perturbations of the source.  The name is either
/// a short sequence of words, if this can be found from the constant, or a type
/// followed by a hash tag.
///
///     List_imX                // A List, with hash tag.
///     C_Sentinel              // const Sentinel(),  "C_" added to avoid clash
///                             //   with class name.
///     JSInt_methods           // an interceptor.
///     Duration_16000          // const Duration(milliseconds: 16)
///     EventKeyProvider_keyup  // const EventKeyProvider('keyup')
///
class ConstantNamingVisitor implements ConstantValueVisitor {
  static final RegExp IDENTIFIER = new RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$');
  static const MAX_FRAGMENTS = 5;
  static const MAX_EXTRA_LENGTH = 30;
  static const DEFAULT_TAG_LENGTH = 3;

  final Namer _namer;
  final JClosedWorld _closedWorld;
  final ConstantCanonicalHasher _hasher;

  String root = null; // First word, usually a type name.
  bool failed = false; // Failed to generate something pretty.
  List<String> fragments = <String>[];
  int length = 0;

  ConstantNamingVisitor(this._namer, this._closedWorld, this._hasher);

  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;
  JFieldAnalysis get _fieldAnalysis => _closedWorld.fieldAnalysis;

  String getName(ConstantValue constant) {
    _visit(constant);
    if (root == null) return 'CONSTANT';
    if (failed) return '${root}_${getHashTag(constant, DEFAULT_TAG_LENGTH)}';
    if (fragments.length == 1) return 'C_${root}';
    return fragments.join('_');
  }

  String getHashTag(ConstantValue constant, int width) =>
      hashWord(_hasher.getHash(constant), width);

  String hashWord(int hash, int length) {
    hash &= 0x1fffffff;
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < length; i++) {
      int digit = hash % 62;
      sb.write('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'[
          digit]);
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

  void _visit(ConstantValue constant) {
    constant.accept(this, null);
  }

  @override
  void visitFunction(FunctionConstantValue constant, [_]) {
    add(constant.element.name);
  }

  @override
  void visitInstantiation(InstantiationConstantValue constant, [_]) {
    _visit(constant.function);
  }

  @override
  void visitNull(NullConstantValue constant, [_]) {
    add('null');
  }

  @override
  void visitNonConstant(NonConstantValue constant, [_]) {
    add('null');
  }

  @override
  void visitInt(IntConstantValue constant, [_]) {
    // No `addRoot` since IntConstants are always inlined.
    if (constant.intValue < BigInt.zero) {
      add('m${-constant.intValue}');
    } else {
      add('${constant.intValue}');
    }
  }

  @override
  void visitDouble(DoubleConstantValue constant, [_]) {
    failed = true;
  }

  @override
  void visitBool(BoolConstantValue constant, [_]) {
    add(constant.isTrue ? 'true' : 'false');
  }

  @override
  void visitString(StringConstantValue constant, [_]) {
    // No `addRoot` since string constants are always inlined.
    addIdentifier(constant.stringValue);
  }

  @override
  void visitList(ListConstantValue constant, [_]) {
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

  @override
  void visitSet(SetConstantValue constant, [_]) {
    // TODO(9476): Incorporate type parameters into name.
    addRoot('Set');
    if (constant.length == 0) {
      add('empty');
    } else {
      add(getHashTag(constant, 5));
    }
  }

  @override
  void visitMap(covariant constant_system.JavaScriptMapConstant constant, [_]) {
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

  @override
  void visitConstructed(ConstructedConstantValue constant, [_]) {
    addRoot(constant.type.element.name);

    // Recognize enum constants and only include the index.
    final Map<FieldEntity, ConstantValue> fieldMap = constant.fields;
    int size = fieldMap.length;
    if (size == 1 || size == 2) {
      FieldEntity indexField;
      for (FieldEntity field in fieldMap.keys) {
        String name = field.name;
        if (name == 'index') {
          indexField = field;
        } else if (name == '_name') {
          // Ignore _name field.
        } else {
          indexField = null;
          break;
        }
      }
      if (indexField != null) {
        _visit(constant.fields[indexField]);
        return;
      }
    }

    // TODO(johnniwinther): This should be accessed from a codegen closed world.
    _elementEnvironment.forEachInstanceField(constant.type.element,
        (_, FieldEntity field) {
      if (failed) return;
      if (_fieldAnalysis.getFieldData(field).isElided) return;
      _visit(constant.fields[field]);
    });
  }

  @override
  void visitType(TypeConstantValue constant, [_]) {
    // Generates something like 'Type_String_k8F', using the simple name of the
    // type and a hash to disambiguate the same name in different libraries.
    addRoot('Type');
    DartType type = constant.representedType;
    String name;
    if (type is InterfaceType) {
      name = type.element.name;
    }
    if (name == null) {
      // e.g. DartType 'dynamic' has no element.
      name = _namer.getTypeRepresentationForTypeConstant(type);
    }
    addIdentifier(name);
    add(getHashTag(constant, 3));
  }

  @override
  void visitInterceptor(InterceptorConstantValue constant, [_]) {
    // The class name for mixin applications contain '+' signs (issue 28196).
    addRoot(constant.cls.name.replaceAll('+', '_'));
    add('methods');
  }

  @override
  void visitDummyInterceptor(DummyInterceptorConstantValue constant, [_]) {
    add('dummy_interceptor');
  }

  @override
  void visitUnreachable(UnreachableConstantValue constant, [_]) {
    add('unreachable');
  }

  @override
  void visitJsName(JsNameConstantValue constant, [_]) {
    add('name');
  }

  @override
  void visitDeferredGlobal(DeferredGlobalConstantValue constant, [_]) {
    addRoot('Deferred');
  }
}

/// Generates canonical hash values for [ConstantValue]s.
///
/// Unfortunately, [Constant.hashCode] is not stable under minor perturbations,
/// so it can't be used for generating names.  This hasher keeps consistency
/// between runs by basing hash values of the names of elements, rather than
/// their hashCodes.
class ConstantCanonicalHasher implements ConstantValueVisitor<int, Null> {
  static const _MASK = 0x1fffffff;
  static const _UINT32_LIMIT = 4 * 1024 * 1024 * 1024;

  final Namer _namer;
  final JClosedWorld _closedWorld;
  final Map<ConstantValue, int> _hashes = {};

  ConstantCanonicalHasher(this._namer, this._closedWorld);

  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;
  JFieldAnalysis get _fieldAnalysis => _closedWorld.fieldAnalysis;

  int getHash(ConstantValue constant) => _visit(constant);

  int _visit(ConstantValue constant) {
    int hash = _hashes[constant];
    if (hash == null) {
      hash = _finish(constant.accept(this, null));
      _hashes[constant] = hash;
    }
    return hash;
  }

  @override
  int visitNull(NullConstantValue constant, [_]) => 1;

  @override
  int visitNonConstant(NonConstantValue constant, [_]) => 1;

  @override
  int visitBool(BoolConstantValue constant, [_]) {
    return constant.isTrue ? 2 : 3;
  }

  @override
  int visitFunction(FunctionConstantValue constant, [_]) {
    return _hashString(1, constant.element.name);
  }

  @override
  int visitInstantiation(InstantiationConstantValue constant, [_]) {
    return _visit(constant.function);
  }

  @override
  int visitInt(IntConstantValue constant, [_]) {
    BigInt value = constant.intValue;
    if (value.toSigned(32) == value) {
      return value.toUnsigned(32).toInt() & _MASK;
    }
    return _hashDouble(value.toDouble());
  }

  @override
  int visitDouble(DoubleConstantValue constant, [_]) {
    return _hashDouble(constant.doubleValue);
  }

  @override
  int visitString(StringConstantValue constant, [_]) {
    return _hashString(2, constant.stringValue);
  }

  @override
  int visitList(ListConstantValue constant, [_]) {
    return _hashList(constant.length, constant.entries);
  }

  @override
  int visitSet(SetConstantValue constant, [_]) {
    return _hashList(constant.length, constant.values);
  }

  @override
  int visitMap(MapConstantValue constant, [_]) {
    int hash = _hashList(constant.length, constant.keys);
    return _hashList(hash, constant.values);
  }

  @override
  int visitConstructed(ConstructedConstantValue constant, [_]) {
    int hash = _hashString(3, constant.type.element.name);
    _elementEnvironment.forEachInstanceField(constant.type.element,
        (_, FieldEntity field) {
      if (_fieldAnalysis.getFieldData(field).isElided) return;
      hash = _combine(hash, _visit(constant.fields[field]));
    });
    return hash;
  }

  @override
  int visitType(TypeConstantValue constant, [_]) {
    DartType type = constant.representedType;
    // This name includes the library name and type parameters.
    String name = _namer.getTypeRepresentationForTypeConstant(type);
    return _hashString(4, name);
  }

  @override
  int visitInterceptor(InterceptorConstantValue constant, [_]) {
    String typeName = constant.cls.name;
    return _hashString(5, typeName);
  }

  @override
  int visitDummyInterceptor(DummyInterceptorConstantValue constant, [_]) {
    throw failedAt(
        NO_LOCATION_SPANNABLE,
        'DummyInterceptorConstantValue should never be named and '
        'never be subconstant');
  }

  @override
  int visitUnreachable(UnreachableConstantValue constant, [_]) {
    throw failedAt(
        NO_LOCATION_SPANNABLE,
        'UnreachableConstantValue should never be named and '
        'never be subconstant');
  }

  @override
  int visitJsName(JsNameConstantValue constant, [_]) {
    throw failedAt(
        NO_LOCATION_SPANNABLE,
        'JsNameConstantValue should never be named and '
        'never be subconstant');
  }

  @override
  int visitDeferredGlobal(DeferredGlobalConstantValue constant, [_]) {
    int hash = constant.unit.hashCode;
    return _combine(hash, _visit(constant.referenced));
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

  int _hashList(int hash, List<ConstantValue> constants) {
    for (ConstantValue constant in constants) {
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
    if (magnitude < _UINT32_LIMIT) {
      // 2^32
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

  /// [_combine] and [_finish] are parts of the [Jenkins hash function][1],
  /// modified by using masking to keep values in SMI range.
  ///
  /// [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
  static int _combine(int hash, int value) {
    hash = _MASK & (hash + value);
    hash = _MASK & (hash + (((_MASK >> 10) & hash) << 10));
    hash = hash ^ (hash >> 6);
    return hash;
  }

  static int _finish(int hash) {
    hash = _MASK & (hash + (((_MASK >> 3) & hash) << 3));
    hash = hash & (hash >> 11);
    return _MASK & (hash + (((_MASK >> 15) & hash) << 15));
  }
}

class FunctionTypeNamer extends BaseDartTypeVisitor {
  StringBuffer sb;

  FunctionTypeNamer();

  String computeName(DartType type) {
    sb = new StringBuffer();
    visit(type);
    return sb.toString();
  }

  @override
  visit(DartType type, [_]) {
    type.accept(this, null);
  }

  @override
  visitType(DartType type, _) {}

  @override
  visitInterfaceType(InterfaceType type, _) {
    sb.write(type.element.name);
  }

  @override
  visitTypeVariableType(TypeVariableType type, _) {
    sb.write(type.element.name);
  }

  bool _isSimpleFunctionType(FunctionType type) {
    if (type.returnType is! DynamicType) return false;
    if (!type.optionalParameterTypes.isEmpty) return false;
    if (!type.namedParameterTypes.isEmpty) return false;
    for (DartType parameter in type.parameterTypes) {
      if (parameter is! DynamicType) return false;
    }
    return true;
  }

  @override
  visitFunctionType(FunctionType type, _) {
    if (_isSimpleFunctionType(type)) {
      sb.write('args${type.parameterTypes.length}');
      return;
    }
    visit(type.returnType);
    sb.write('_');
    for (DartType parameter in type.parameterTypes) {
      sb.write('_');
      visit(parameter);
    }
    bool first = false;
    for (DartType parameter in type.optionalParameterTypes) {
      if (!first) {
        sb.write('_');
      }
      sb.write('_');
      visit(parameter);
      first = true;
    }
    if (!type.namedParameterTypes.isEmpty) {
      first = false;
      for (DartType parameter in type.namedParameterTypes) {
        if (!first) {
          sb.write('_');
        }
        sb.write('_');
        visit(parameter);
        first = true;
      }
    }
  }
}

class NamingScope {
  /// Maps proposed names to *suggested* disambiguated names.
  ///
  /// Suggested names are hints to the [MinifyNamer], suggesting that a specific
  /// names be given to the first item with the given proposed name.
  ///
  /// This is currently used in [MinifyNamer] to assign very short minified
  /// names to things that tend to be used very often.
  final Map<String, String> _suggestedNames = {};
  final Set<String> _usedNames = Set();

  bool isUsed(String name) => _usedNames.contains(name);
  bool isUnused(String name) => !_usedNames.contains(name);
  bool registerUse(String name) => _usedNames.add(name);

  String suggestName(String original) => _suggestedNames[original];
  void addSuggestion(String original, String suggestion) {
    assert(!_suggestedNames.containsKey(original));
    _suggestedNames[original] = suggestion;
  }

  bool hasSuggestion(String original) => _suggestedNames.containsKey(original);
  bool isSuggestion(String candidate) {
    return _suggestedNames.containsValue(candidate);
  }
}

/// Fixed names usage by the namer.
class FixedNames {
  const FixedNames();

  String get getterPrefix => r'get$';
  String get setterPrefix => r'set$';
  String get callPrefix => 'call';
  String get callCatchAllName => r'call*';
  String get callNameField => r'$callName';
  String get defaultValuesField => r'$defaultValues';
  String get deferredAction => r'$deferredAction';
  String get operatorIsPrefix => r'$is';
  String get operatorAsPrefix => r'$as';
  String get operatorSignature => r'$signature';
  String get requiredParameterField => r'$requiredArgCount';
  String get rtiName => r'$ti';
}

/// Minified version of the fixed names usage by the namer.
// TODO(johnniwinther): This should implement [FixedNames] and minify all fixed
// names.
class MinifiedFixedNames extends FixedNames {
  const MinifiedFixedNames();

  @override
  String get getterPrefix => 'g';
  @override
  String get setterPrefix => 's';
  @override
  String get callPrefix => ''; // this will create function names $<n>
  @override
  String get operatorIsPrefix => r'$i';
  @override
  String get operatorAsPrefix => r'$a';
  @override
  String get callCatchAllName => r'$C';
  @override
  String get requiredParameterField => r'$R';
  @override
  String get defaultValuesField => r'$D';
  @override
  String get operatorSignature => r'$S';
}

/// Namer interface that can be used in modular code generation.
abstract class ModularNamer {
  FixedNames get fixedNames;

  /// Returns a variable use for accessing [library].
  ///
  /// This is one of the [reservedGlobalObjectNames]
  jsAst.Expression readGlobalObjectForLibrary(LibraryEntity library);

  /// Returns a variable use for accessing the class [element].
  ///
  /// This is one of the [reservedGlobalObjectNames]
  jsAst.Expression readGlobalObjectForClass(ClassEntity element);

  /// Returns a variable use for accessing the type [element].
  ///
  /// This is one of the [reservedGlobalObjectNames]
  jsAst.Expression readGlobalObjectForType(Entity element);

  /// Returns a variable use for accessing the member [element].
  ///
  /// This is either the [staticStateHolder] or one of the
  /// [reservedGlobalObjectNames]
  jsAst.Expression readGlobalObjectForMember(MemberEntity element);

  /// Returns a JavaScript property name used to store the class [element] on
  /// one of the global objects.
  ///
  /// Should be used together with [globalObjectForClass], which denotes the
  /// object on which the returned property name should be used.
  jsAst.Name globalPropertyNameForClass(ClassEntity element);

  /// Returns a JavaScript property name used to store the member [element] on
  /// one of the global objects.
  ///
  /// Should be used together with [globalObjectForMember], which denotes the
  /// object on which the returned property name should be used.
  jsAst.Name globalPropertyNameForMember(MemberEntity element);

  /// Returns a JavaScript property name used to store the type (typedef)
  /// [element] on one of the global objects.
  ///
  /// Should be used together with [globalObjectForType], which denotes the
  /// object on which the returned property name should be used.
  jsAst.Name globalPropertyNameForType(Entity element);

  /// Returns a name, the string of which is a globally unique key distinct from
  /// other global property names.
  ///
  /// The name is not necessarily a valid JavaScript identifier, so it needs to
  /// be quoted.
  jsAst.Name globalNameForInterfaceTypeVariable(
      TypeVariableEntity typeVariable);

  /// Returns the name for the instance field that holds runtime type arguments
  /// on generic classes.
  jsAst.Name get rtiFieldJsName;

  /// Property name on which [member] can be accessed directly,
  /// without clashing with another JS property name.
  ///
  /// This is used for implementing super-calls, where ordinary dispatch
  /// semantics must be circumvented. For example:
  ///
  ///     class A { foo() }
  ///     class B extends A {
  ///         foo() { super.foo() }
  ///     }
  ///
  /// Example translation to JS:
  ///
  ///     A.prototype.super$A$foo = function() {...}
  ///     A.prototype.foo$0 = A.prototype.super$A$foo
  ///
  ///     B.prototype.foo$0 = function() {
  ///         this.super$A$foo(); // super.foo()
  ///     }
  ///
  jsAst.Name aliasedSuperMemberPropertyName(MemberEntity member);

  /// Returns the JavaScript property name used to store an instance field.
  jsAst.Name instanceFieldPropertyName(FieldEntity element);

  /// Annotated name for [method] encoding arity and named parameters.
  jsAst.Name instanceMethodName(FunctionEntity method);

  /// Translates a [String] into the corresponding [Name] data structure as
  /// used by the namer.
  ///
  /// If [name] is a setter or getter name, the corresponding [GetterName] or
  /// [SetterName] data structure is used.
  jsAst.Name asName(String name);

  /// Annotated name for the member being invoked by [selector].
  jsAst.Name invocationName(Selector selector);

  /// Property name used for a specialization of `getInterceptor`.
  ///
  /// js_runtime contains a top-level `getInterceptor` method. The
  /// specializations have the same name, but with a suffix to avoid name
  /// collisions.
  jsAst.Name nameForGetInterceptor(Set<ClassEntity> classes);

  /// Property name used for the one-shot interceptor method for the given
  /// [selector] and return-type specialization.
  jsAst.Name nameForOneShotInterceptor(
      Selector selector, Set<ClassEntity> classes);

  /// Returns the runtime name for [element].
  ///
  /// This name is used as the basis for deriving `is` and `as` property names
  /// for the given type.
  ///
  /// The result is not always safe as a property name unless prefixing
  /// [operatorIsPrefix] or [operatorAsPrefix]. If this is a function type,
  /// then by convention, an underscore must also separate [operatorIsPrefix]
  /// from the type name.
  jsAst.Name runtimeTypeName(Entity element);

  /// Property name in which to store the given static or instance [method].
  /// For instance methods, this includes the suffix encoding arity and named
  /// parameters.
  ///
  /// The name is not necessarily unique to [method], since a static method
  /// may share its name with an instance method.
  jsAst.Name methodPropertyName(FunctionEntity method);

  /// Returns the name of the `isX` property for classes that implement
  /// [element].
  jsAst.Name operatorIs(ClassEntity element);

  /// Return the name of the `isX` property for classes that implement [type].
  jsAst.Name operatorIsType(DartType type);

  /// Returns the name of the `asX` function for classes that implement the
  /// generic class [element].
  jsAst.Name substitutionName(ClassEntity element);

  /// Returns the name of the lazy initializer for the static field [element].
  jsAst.Name lazyInitializerName(FieldEntity element);

  /// Returns the name of the closure of the static method [element].
  jsAst.Name staticClosureName(FunctionEntity element);

  /// Returns the disambiguated name of [class_].
  ///
  /// This is both the *runtime type* of the class (see [runtimeTypeName])
  /// and a global property name in which to store its JS constructor.
  jsAst.Name className(ClassEntity class_);

  /// The prefix used for encoding async properties.
  final String asyncPrefix = r"$async$";

  /// Returns the name for the holder of static state.
  ///
  /// This is used for mutable static fields.
  final String staticStateHolder = r'$';

  jsAst.Name _literalAsyncPrefix;

  ModularNamer() {
    _literalAsyncPrefix = new StringBackedName(asyncPrefix);
  }

  /// Returns a safe variable name for use in async rewriting.
  ///
  /// Has the same property as [safeVariableName] but does not clash with
  /// names returned from there.
  /// Additionally, when used as a prefix to a variable name, the result
  /// will be safe to use, as well.
  String safeVariablePrefixForAsyncRewrite(String name) {
    return "$asyncPrefix$name";
  }

  /// Returns the name for the async body of the method with the [original]
  /// name.
  jsAst.Name deriveAsyncBodyName(jsAst.Name original) {
    return new AsyncName(_literalAsyncPrefix, original);
  }

  /// Returns the label name for [label] used as a break target.
  String breakLabelName(LabelDefinition label) {
    return '\$${label.labelName}\$${label.target.nestingLevel}';
  }

  /// Returns the label name for the implicit break label needed for the jump
  /// [target].
  String implicitBreakLabelName(JumpTarget target) {
    return '\$${target.nestingLevel}';
  }

  /// Returns the label name for [label] used as a continue target.
  ///
  /// We sometimes handle continue targets differently from break targets,
  /// so we have special continue-only labels.
  String continueLabelName(LabelDefinition label) {
    return 'c\$${label.labelName}\$${label.target.nestingLevel}';
  }

  /// Returns the label name for the implicit continue label needed for the jump
  /// [target].
  String implicitContinueLabelName(JumpTarget target) {
    return 'c\$${target.nestingLevel}';
  }

  Set<String> _jsVariableReservedCache = null;

  /// Names that cannot be used by local variables and parameters.
  Set<String> get _jsVariableReserved {
    if (_jsVariableReservedCache == null) {
      _jsVariableReservedCache = new Set<String>();
      _jsVariableReservedCache.addAll(Namer.javaScriptKeywords);
      _jsVariableReservedCache.addAll(Namer.reservedPropertySymbols);
      _jsVariableReservedCache.addAll(Namer.reservedGlobalSymbols);
      _jsVariableReservedCache.addAll(Namer.reservedGlobalObjectNames);
      // 26 letters in the alphabet, 25 not counting I.
      assert(Namer.reservedGlobalObjectNames.length == 25);
      _jsVariableReservedCache.addAll(Namer.reservedGlobalHelperFunctions);
    }
    return _jsVariableReservedCache;
  }

  /// Returns a variable name that cannot clash with a keyword, a global
  /// variable, or any name starting with a single '$'.
  ///
  /// Furthermore, this function is injective, that is, it never returns the
  /// same name for two different inputs.
  String safeVariableName(String name) {
    name = name.replaceAll('#', '_');
    if (_jsVariableReserved.contains(name) || name.startsWith(r'$')) {
      return '\$$name';
    }
    return name;
  }

  CommonElements get _commonElements;

  /// Returns the string that is to be used as the result of a call to
  /// [JS_GET_NAME] at [node] with argument [name].
  jsAst.Name getNameForJsGetName(Spannable spannable, JsGetName name) {
    switch (name) {
      case JsGetName.GETTER_PREFIX:
        return asName(fixedNames.getterPrefix);
      case JsGetName.SETTER_PREFIX:
        return asName(fixedNames.setterPrefix);
      case JsGetName.CALL_PREFIX:
        return asName(fixedNames.callPrefix);
      case JsGetName.CALL_PREFIX0:
        return asName('${fixedNames.callPrefix}\$0');
      case JsGetName.CALL_PREFIX1:
        return asName('${fixedNames.callPrefix}\$1');
      case JsGetName.CALL_PREFIX2:
        return asName('${fixedNames.callPrefix}\$2');
      case JsGetName.CALL_PREFIX3:
        return asName('${fixedNames.callPrefix}\$3');
      case JsGetName.CALL_PREFIX4:
        return asName('${fixedNames.callPrefix}\$4');
      case JsGetName.CALL_PREFIX5:
        return asName('${fixedNames.callPrefix}\$5');
      case JsGetName.CALL_CATCH_ALL:
        return asName(fixedNames.callCatchAllName);
      case JsGetName.REQUIRED_PARAMETER_PROPERTY:
        return asName(fixedNames.requiredParameterField);
      case JsGetName.DEFAULT_VALUES_PROPERTY:
        return asName(fixedNames.defaultValuesField);
      case JsGetName.CALL_NAME_PROPERTY:
        return asName(fixedNames.callNameField);
      case JsGetName.DEFERRED_ACTION_PROPERTY:
        return asName(fixedNames.deferredAction);
      case JsGetName.OPERATOR_AS_PREFIX:
        return asName(fixedNames.operatorAsPrefix);
      case JsGetName.OPERATOR_IS_PREFIX:
        return asName(fixedNames.operatorIsPrefix);
      case JsGetName.SIGNATURE_NAME:
        return asName(fixedNames.operatorSignature);
      case JsGetName.RTI_NAME:
        return asName(fixedNames.rtiName);
      case JsGetName.IS_INDEXABLE_FIELD_NAME:
        return operatorIs(_commonElements.jsIndexingBehaviorInterface);
      case JsGetName.NULL_CLASS_TYPE_NAME:
        return runtimeTypeName(_commonElements.nullClass);
      case JsGetName.OBJECT_CLASS_TYPE_NAME:
        return runtimeTypeName(_commonElements.objectClass);
      case JsGetName.FUTURE_CLASS_TYPE_NAME:
        return runtimeTypeName(_commonElements.futureClass);
      case JsGetName.RTI_FIELD_AS:
        return instanceFieldPropertyName(_commonElements.rtiAsField);
      case JsGetName.RTI_FIELD_IS:
        return instanceFieldPropertyName(_commonElements.rtiIsField);
      default:
        throw failedAt(spannable, 'Error: Namer has no name for "$name".');
    }
  }
}

class ModularNamerImpl extends ModularNamer {
  final CodegenRegistry _registry;
  @override
  final FixedNames fixedNames;

  @override
  final CommonElements _commonElements;

  ModularNamerImpl(this._registry, this._commonElements, this.fixedNames);

  @override
  jsAst.Name get rtiFieldJsName {
    jsAst.Name name = new ModularName(ModularNameKind.rtiField);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name runtimeTypeName(Entity element) {
    jsAst.Name name =
        new ModularName(ModularNameKind.runtimeTypeName, data: element);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name className(ClassEntity element) {
    jsAst.Name name = new ModularName(ModularNameKind.className, data: element);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Expression readGlobalObjectForLibrary(LibraryEntity library) {
    jsAst.Expression expression = new ModularExpression(
        ModularExpressionKind.globalObjectForLibrary, library);
    _registry.registerModularExpression(expression);
    return expression;
  }

  @override
  jsAst.Expression readGlobalObjectForClass(ClassEntity element) {
    jsAst.Expression expression = new ModularExpression(
        ModularExpressionKind.globalObjectForClass, element);
    _registry.registerModularExpression(expression);
    return expression;
  }

  @override
  jsAst.Expression readGlobalObjectForType(Entity element) {
    jsAst.Expression expression = new ModularExpression(
        ModularExpressionKind.globalObjectForType, element);
    _registry.registerModularExpression(expression);
    return expression;
  }

  @override
  jsAst.Expression readGlobalObjectForMember(MemberEntity element) {
    jsAst.Expression expression = new ModularExpression(
        ModularExpressionKind.globalObjectForMember, element);
    _registry.registerModularExpression(expression);
    return expression;
  }

  @override
  jsAst.Name aliasedSuperMemberPropertyName(MemberEntity member) {
    jsAst.Name name =
        new ModularName(ModularNameKind.aliasedSuperMember, data: member);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name staticClosureName(FunctionEntity element) {
    jsAst.Name name =
        new ModularName(ModularNameKind.staticClosure, data: element);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name methodPropertyName(FunctionEntity method) {
    jsAst.Name name =
        new ModularName(ModularNameKind.methodProperty, data: method);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name instanceFieldPropertyName(FieldEntity element) {
    jsAst.Name name =
        new ModularName(ModularNameKind.instanceField, data: element);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name operatorIsType(DartType type) {
    jsAst.Name name =
        new ModularName(ModularNameKind.operatorIsType, data: type);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name instanceMethodName(FunctionEntity method) {
    jsAst.Name name =
        new ModularName(ModularNameKind.instanceMethod, data: method);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name invocationName(Selector selector) {
    jsAst.Name name =
        new ModularName(ModularNameKind.invocation, data: selector);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name lazyInitializerName(FieldEntity element) {
    jsAst.Name name =
        new ModularName(ModularNameKind.lazyInitializer, data: element);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name operatorIs(ClassEntity element) {
    jsAst.Name name =
        new ModularName(ModularNameKind.operatorIs, data: element);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name globalPropertyNameForType(Entity element) {
    jsAst.Name name = new ModularName(ModularNameKind.globalPropertyNameForType,
        data: element);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name globalPropertyNameForClass(ClassEntity element) {
    jsAst.Name name = new ModularName(
        ModularNameKind.globalPropertyNameForClass,
        data: element);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name globalPropertyNameForMember(MemberEntity element) {
    jsAst.Name name = new ModularName(
        ModularNameKind.globalPropertyNameForMember,
        data: element);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name globalNameForInterfaceTypeVariable(TypeVariableEntity element) {
    jsAst.Name name = new ModularName(
        ModularNameKind.globalNameForInterfaceTypeVariable,
        data: element);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name nameForGetInterceptor(Set<ClassEntity> classes) {
    jsAst.Name name =
        new ModularName(ModularNameKind.nameForGetInterceptor, set: classes);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name nameForOneShotInterceptor(
      Selector selector, Set<ClassEntity> classes) {
    jsAst.Name name = new ModularName(ModularNameKind.nameForOneShotInterceptor,
        data: selector, set: classes);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name asName(String text) {
    jsAst.Name name = new ModularName(ModularNameKind.asName, data: text);
    _registry.registerModularName(name);
    return name;
  }

  @override
  jsAst.Name substitutionName(ClassEntity element) {
    jsAst.Name name =
        new ModularName(ModularNameKind.substitution, data: element);
    _registry.registerModularName(name);
    return name;
  }
}
