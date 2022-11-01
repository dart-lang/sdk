// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart'
    show $0, $9, $A, $Z, $_, $a, $g, $s, $z;

import '../common/elements.dart';
import '../elements/entities.dart';
import '../js_backend/native_data.dart';
import '../universe/call_structure.dart' show CallStructure;

/// Returns a unique suffix for an intercepted accesses to [classes]. This is
/// used as the suffix for emitted interceptor methods and as the unique key
/// used to distinguish equivalences of sets of intercepted classes.
String suffixForGetInterceptor(CommonElements commonElements,
    NativeData nativeData, Iterable<ClassEntity> classes) {
  String abbreviate(ClassEntity cls) {
    if (cls == commonElements.objectClass) return "o";
    if (cls == commonElements.jsStringClass) return "s";
    if (cls == commonElements.jsArrayClass) return "a";
    if (cls == commonElements.jsNumNotIntClass) return "d";
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
List<String> callSuffixForStructure(CallStructure callStructure) {
  List<String> suffixes = [];
  if (callStructure.typeArgumentCount > 0) {
    suffixes.add('${callStructure.typeArgumentCount}');
  }
  suffixes.add('${callStructure.argumentCount}');
  suffixes.addAll(callStructure.getOrderedNamedArguments());
  return suffixes;
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
  String get callCatchAllName => r'$C';
  @override
  String get requiredParameterField => r'$R';
  @override
  String get defaultValuesField => r'$D';
  @override
  String get operatorSignature => r'$S';
}

String? operatorNameToIdentifier(String? name) {
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

const List<String> javaScriptKeywords = [
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

const List<String> reservedPropertySymbols = [
  "__proto__", "prototype", "constructor", "call",
  // "use strict" disallows the use of "arguments" and "eval" as
  // variable names or property names. See ECMA-262, Edition 5.1,
  // section 11.1.5 (for the property names).
  "eval", "arguments"
];

/// A set of all capitalized global symbols.
/// This set is so [DeferredHolderFinalizer] can use names like:
/// [A-Z][_0-9a-zA-Z]* without collisions
const Set<String> reservedCapitalizedGlobalSymbols = {
  // Section references are from Ecma-262
  // (http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-262.pdf)

  // 15.1.1 Value Properties of the Global Object
  "NaN", "Infinity",

  // 15.1.4 Constructor Properties of the Global Object
  "Object", "Function", "Array", "String", "Boolean", "Number", "Date",
  "RegExp", "Symbol", "Error", "EvalError", "RangeError", "ReferenceError",
  "SyntaxError", "TypeError", "URIError",

  // 15.1.5 Other Properties of the Global Object
  "Math",

  // Window props (https://developer.mozilla.org/en/DOM/window)
  "Components",

  // Window methods (https://developer.mozilla.org/en/DOM/window)
  "GeckoActiveXObject", "QueryInterface", "XPCNativeWrapper",
  "XPCSafeJSOjbectWrapper",

  // Common browser-defined identifiers not defined in ECMAScript
  "Debug", "Enumerator", "Global", "Image",
  "ActiveXObject", "VBArray",

  // Client-side JavaScript identifiers
  "Anchor", "Applet", "Attr", "Canvas", "CanvasGradient",
  "CanvasPattern", "CanvasRenderingContext2D", "CDATASection",
  "CharacterData", "Comment", "CSS2Properties", "CSSRule",
  "CSSStyleSheet", "Document", "DocumentFragment", "DocumentType",
  "DOMException", "DOMImplementation", "DOMParser", "Element", "Event",
  "ExternalInterface", "FlashPlayer", "Form", "Frame", "History",
  "HTMLCollection", "HTMLDocument", "HTMLElement", "IFrame",
  "Input", "JSObject", "KeyEvent", "Link", "Location", "MimeType",
  "MouseEvent", "Navigator", "Node", "NodeList", "Option", "Plugin",
  "ProcessingInstruction", "Range", "RangeException", "Screen", "Select",
  "Table", "TableCell", "TableRow", "TableSelection", "Text", "TextArea",
  "UIEvent", "Window", "XMLHttpRequest", "XMLSerializer",
  "XPathException", "XPathResult", "XSLTProcessor",

  // These keywords trigger the loading of the java-plugin. For the
  // next-generation plugin, this results in starting a new Java process.
  "Packages", "JavaObject", "JavaClass",
  "JavaArray", "JavaMember",

  // ES6 collections.
  "Map", "Set",

  // Some additional names
  "Isolate",
};

/// Symbols that we might be using in our JS snippets. Some of the symbols in
/// these sections are in [reservedGlobalUpperCaseSymbols] above.
const List<String> reservedGlobalSymbols = [
  // Section references are from Ecma-262
  // (http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-262.pdf)

  // 15.1.1 Value Properties of the Global Object
  "undefined",

  // 15.1.2 Function Properties of the Global Object
  "eval", "parseInt", "parseFloat", "isNaN", "isFinite",

  // 15.1.3 URI Handling Function Properties
  "decodeURI", "decodeURIComponent",
  "encodeURI",
  "encodeURIComponent",

  // 10.1.6 Activation Object
  "arguments",

  // B.2 Additional Properties (non-normative)
  "escape", "unescape",

  // Window props (https://developer.mozilla.org/en/DOM/window)
  "applicationCache", "closed", "content", "controllers",
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
  "getAttention", "getAttentionWithCycleCount",
  "getComputedStyle", "getSelection", "home", "maximize", "minimize",
  "moveBy", "moveTo", "open", "openDialog", "postMessage", "print",
  "prompt", "releaseEvents", "removeEventListener",
  "resizeBy", "resizeTo", "restore", "routeEvent", "scroll", "scrollBy",
  "scrollByLines", "scrollByPages", "scrollTo", "setInterval",
  "setResizeable", "setTimeout", "showModalDialog", "sizeToContent",
  "stop", "uuescape", "updateCommands",

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
  "event", "external",

  // Functions commonly defined on Object
  "toString", "getClass", "constructor", "prototype", "valueOf",

  // These keywords trigger the loading of the java-plugin. For the
  // next-generation plugin, this results in starting a new Java process.
  "java", "netscape", "sun",
];

// TODO(joshualitt): Stop reserving these names after local naming is updated
// to use frequencies.
const List<String> reservedGlobalObjectNames = [
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

const List<String> reservedGlobalHelperFunctions = [
  "init",
];

final List<String> userGlobalObjects = List.from(reservedGlobalObjectNames)
  ..remove('C')
  ..remove('H')
  ..remove('J')
  ..remove('P')
  ..remove('W');

final RegExp _identifierStartRE = RegExp(r'[A-Za-z_$]');
final RegExp _nonIdentifierRE = RegExp(r'[^A-Za-z0-9_$]');

/// Returns `true` iff [s] begins with an ASCII character that can begin a
/// JavaScript identifier.
///
/// In particular, [s] must begin with an ASCII letter, an underscore, or a
/// dollar sign.
bool startsWithIdentifierCharacter(String s) =>
    s.startsWith(_identifierStartRE);

/// Returns a copy of [s] in which characters which cannot be part of an ASCII
/// JavaScript identifier have been replaced by underscores.
///
/// Note that the result may not be unconditionally used as a JavaScript
/// identifier. For example, the result may still begin with a digit or it may
/// be a reserved keyword.
String replaceNonIdentifierCharacters(String s) =>
    s.replaceAll(_nonIdentifierRE, '_');

/// Names that cannot be used by members, top level and static
/// methods.
final Set<String> jsReserved = {
  ...javaScriptKeywords,
  ...reservedPropertySymbols
};

final RegExp IDENTIFIER = RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$');
final RegExp NON_IDENTIFIER_CHAR = RegExp(r'[^A-Za-z_0-9$]');
const MAX_FRAGMENTS = 5;
const MAX_EXTRA_LENGTH = 30;
const DEFAULT_TAG_LENGTH = 3;

/// Instance members starting with g and s are reserved for getters and
/// setters.
bool hasBannedMinifiedPrefix(String name) {
  int code = name.codeUnitAt(0);
  return code == $g || code == $s;
}

class TokenScope {
  final int initialChar;
  final List<int> _nextName;
  final Set<String> illegalNames;

  TokenScope({this.illegalNames = const {}, this.initialChar = $a})
      : _nextName = [initialChar];

  /// Increments the letter at [pos] in the current name. Also takes care of
  /// overflows to the left. Returns the carry bit, i.e., it returns `true`
  /// if all positions to the left have wrapped around.
  ///
  /// If [_nextName] is initially 'a', this will generate the sequence
  ///
  /// [a-zA-Z]
  /// [a-zA-Z][_0-9a-zA-Z]
  /// [a-zA-Z][_0-9a-zA-Z][_0-9a-zA-Z]
  /// ...
  bool _incrementPosition(int pos) {
    bool overflow = false;
    if (pos < 0) return true;
    int value = _nextName[pos];
    if (value == $_) {
      value = $0;
    } else if (value == $9) {
      value = $a;
    } else if (value == $z) {
      value = $A;
    } else if (value == $Z) {
      overflow = _incrementPosition(pos - 1);
      value = (pos > 0) ? $_ : initialChar;
    } else {
      value++;
    }
    _nextName[pos] = value;
    return overflow;
  }

  _incrementName() {
    if (_incrementPosition(_nextName.length - 1)) {
      _nextName.add($_);
    }
  }

  String getNextName() {
    String proposal;
    do {
      proposal = String.fromCharCodes(_nextName);
      _incrementName();
    } while (
        hasBannedMinifiedPrefix(proposal) || illegalNames.contains(proposal));

    return proposal;
  }
}
