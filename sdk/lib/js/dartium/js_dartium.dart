// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for interoperating with JavaScript.
 *
 * This library provides access to JavaScript objects from Dart, allowing
 * Dart code to get and set properties, and call methods of JavaScript objects
 * and invoke JavaScript functions. The library takes care of converting
 * between Dart and JavaScript objects where possible, or providing proxies if
 * conversion isn't possible.
 *
 * This library does not yet make Dart objects usable from JavaScript, their
 * methods and proeprties are not accessible, though it does allow Dart
 * functions to be passed into and called from JavaScript.
 *
 * [JsObject] is the core type and represents a proxy of a JavaScript object.
 * JsObject gives access to the underlying JavaScript objects properties and
 * methods. `JsObject`s can be acquired by calls to JavaScript, or they can be
 * created from proxies to JavaScript constructors.
 *
 * The top-level getter [context] provides a [JsObject] that represents the
 * global object in JavaScript, usually `window`.
 *
 * The following example shows an alert dialog via a JavaScript call to the
 * global function `alert()`:
 *
 *     import 'dart:js';
 *
 *     main() => context.callMethod('alert', ['Hello from Dart!']);
 *
 * This example shows how to create a [JsObject] from a JavaScript constructor
 * and access its properties:
 *
 *     import 'dart:js';
 *
 *     main() {
 *       var object = new JsObject(context['Object']);
 *       object['greeting'] = 'Hello';
 *       object['greet'] = (name) => "${object['greeting']} $name";
 *       var message = object.callMethod('greet', ['JavaScript']);
 *       context['console'].callMethod('log', [message]);
 *     }
 *
 * ## Proxying and automatic conversion
 *
 * When setting properties on a JsObject or passing arguments to a Javascript
 * method or function, Dart objects are automatically converted or proxied to
 * JavaScript objects. When accessing JavaScript properties, or when a Dart
 * closure is invoked from JavaScript, the JavaScript objects are also
 * converted to Dart.
 *
 * Functions and closures are proxied in such a way that they are callable. A
 * Dart closure assigned to a JavaScript property is proxied by a function in
 * JavaScript. A JavaScript function accessed from Dart is proxied by a
 * [JsFunction], which has a [apply] method to invoke it.
 *
 * The following types are transferred directly and not proxied:
 *
 * * "Basic" types: `null`, `bool`, `num`, `String`, `DateTime`
 * * `Blob`
 * * `Event`
 * * `HtmlCollection`
 * * `ImageData`
 * * `KeyRange`
 * * `Node`
 * * `NodeList`
 * * `TypedData`, including its subclasses like `Int32List`, but _not_
 *   `ByteBuffer`
 * * `Window`
 *
 * ## Converting collections with JsObject.jsify()
 *
 * To create a JavaScript collection from a Dart collection use the
 * [JsObject.jsify] constructor, which converts Dart [Map]s and [Iterable]s
 * into JavaScript Objects and Arrays.
 *
 * The following expression creates a new JavaScript object with the properties
 * `a` and `b` defined:
 *
 *     var jsMap = new JsObject.jsify({'a': 1, 'b': 2});
 *
 * This expression creates a JavaScript array:
 *
 *     var jsArray = new JsObject.jsify([1, 2, 3]);
 */
library dart.js;

import 'dart:collection' show ListMixin;
import 'dart:nativewrappers';
import 'dart:math' as math;
import 'dart:mirrors' as mirrors;
import 'dart:html' as html;
import 'dart:_blink' as _blink;
import 'dart:html_common' as html_common;
import 'dart:indexed_db' as indexed_db;
import 'dart:typed_data';
import 'dart:core';

import 'cached_patches.dart';

// Pretend we are always in checked mode as we aren't interested in users
// running Dartium code outside of checked mode.
@Deprecated("Internal Use Only")
final bool CHECK_JS_INVOCATIONS = true;

final String _DART_RESERVED_NAME_PREFIX = r'JS$';
// If a private class is defined to use @JS we need to inject a non-private
// class with a name that will not cause collisions in the library so we can
// make JSObject implement that interface even though it is in a different
// library.
final String escapePrivateClassPrefix = r'$JSImplClass23402893498';

String _stripReservedNamePrefix(String name) =>
    name.startsWith(_DART_RESERVED_NAME_PREFIX)
        ? name.substring(_DART_RESERVED_NAME_PREFIX.length)
        : name;

_buildArgs(Invocation invocation) {
  if (invocation.namedArguments.isEmpty) {
    return invocation.positionalArguments;
  } else {
    var varArgs = new Map<String, Object>();
    invocation.namedArguments.forEach((symbol, val) {
      varArgs[mirrors.MirrorSystem.getName(symbol)] = val;
    });
    return invocation.positionalArguments.toList()
      ..add(JsNative.jsify(varArgs));
  }
}

final _allowedMethods = new Map<Symbol, _DeclarationSet>();
final _allowedGetters = new Map<Symbol, _DeclarationSet>();
final _allowedSetters = new Map<Symbol, _DeclarationSet>();

final _jsInterfaceTypes = new Set<mirrors.ClassMirror>();
@Deprecated("Internal Use Only")
Iterable<mirrors.ClassMirror> get jsInterfaceTypes => _jsInterfaceTypes;

class _StringLiteralEscape {
  // Character code constants.
  static const int BACKSPACE = 0x08;
  static const int TAB = 0x09;
  static const int NEWLINE = 0x0a;
  static const int CARRIAGE_RETURN = 0x0d;
  static const int FORM_FEED = 0x0c;
  static const int QUOTE = 0x22;
  static const int CHAR_$ = 0x24;
  static const int CHAR_0 = 0x30;
  static const int BACKSLASH = 0x5c;
  static const int CHAR_b = 0x62;
  static const int CHAR_f = 0x66;
  static const int CHAR_n = 0x6e;
  static const int CHAR_r = 0x72;
  static const int CHAR_t = 0x74;
  static const int CHAR_u = 0x75;

  final StringSink _sink;

  _StringLiteralEscape(this._sink);

  void writeString(String string) {
    _sink.write(string);
  }

  void writeStringSlice(String string, int start, int end) {
    _sink.write(string.substring(start, end));
  }

  void writeCharCode(int charCode) {
    _sink.writeCharCode(charCode);
  }

  /// ('0' + x) or ('a' + x - 10)
  static int hexDigit(int x) => x < 10 ? 48 + x : 87 + x;

  /// Write, and suitably escape, a string's content as a JSON string literal.
  void writeStringContent(String s) {
    // Identical to JSON string literal escaping except that we also escape $.
    int offset = 0;
    final int length = s.length;
    for (int i = 0; i < length; i++) {
      int charCode = s.codeUnitAt(i);
      if (charCode > BACKSLASH) continue;
      if (charCode < 32) {
        if (i > offset) writeStringSlice(s, offset, i);
        offset = i + 1;
        writeCharCode(BACKSLASH);
        switch (charCode) {
          case BACKSPACE:
            writeCharCode(CHAR_b);
            break;
          case TAB:
            writeCharCode(CHAR_t);
            break;
          case NEWLINE:
            writeCharCode(CHAR_n);
            break;
          case FORM_FEED:
            writeCharCode(CHAR_f);
            break;
          case CARRIAGE_RETURN:
            writeCharCode(CHAR_r);
            break;
          default:
            writeCharCode(CHAR_u);
            writeCharCode(CHAR_0);
            writeCharCode(CHAR_0);
            writeCharCode(hexDigit((charCode >> 4) & 0xf));
            writeCharCode(hexDigit(charCode & 0xf));
            break;
        }
      } else if (charCode == QUOTE ||
          charCode == BACKSLASH ||
          charCode == CHAR_$) {
        if (i > offset) writeStringSlice(s, offset, i);
        offset = i + 1;
        writeCharCode(BACKSLASH);
        writeCharCode(charCode);
      }
    }
    if (offset == 0) {
      writeString(s);
    } else if (offset < length) {
      writeStringSlice(s, offset, length);
    }
  }

  /**
   * Serialize a [num], [String], [bool], [Null], [List] or [Map] value.
   *
   * Returns true if the value is one of these types, and false if not.
   * If a value is both a [List] and a [Map], it's serialized as a [List].
   */
  bool writeStringLiteral(String str) {
    writeString('"');
    writeStringContent(str);
    writeString('"');
  }
}

String _escapeString(String str) {
  StringBuffer output = new StringBuffer();
  new _StringLiteralEscape(output)..writeStringLiteral(str);
  return output.toString();
}

/// A collection of methods where all methods have the same name.
/// This class is intended to optimize whether a specific invocation is
/// appropriate for at least some of the methods in the collection.
class _DeclarationSet {
  _DeclarationSet() : _members = <mirrors.DeclarationMirror>[];

  static bool _checkType(obj, mirrors.TypeMirror type) {
    if (obj == null) return true;
    return mirrors.reflectType(obj.runtimeType).isSubtypeOf(type);
  }

  /// Returns whether the return [value] has a type is consistent with the
  /// return type from at least one of the members matching the DeclarationSet.
  bool _checkReturnType(value) {
    if (value == null) return true;
    var valueMirror = mirrors.reflectType(value.runtimeType);
    for (var member in _members) {
      if (member is mirrors.VariableMirror || member.isGetter) {
        // TODO(jacobr): actually check return types for getters that return
        // function types.
        return true;
      } else {
        if (valueMirror.isSubtypeOf(member.returnType)) return true;
      }
    }
    return false;
  }

  /**
   * Check whether the [invocation] is consistent with the [member] mirror.
   */
  bool _checkDeclaration(
      Invocation invocation, mirrors.DeclarationMirror member) {
    if (member is mirrors.VariableMirror || (member as dynamic).isGetter) {
      // TODO(jacobr): actually check method types against the function type
      // returned by the getter or field.
      return true;
    }
    var parameters = (member as dynamic).parameters;
    var positionalArguments = invocation.positionalArguments;
    // Too many arguments
    if (parameters.length < positionalArguments.length) return false;
    // Too few required arguments.
    if (parameters.length > positionalArguments.length &&
        !parameters[positionalArguments.length].isOptional) return false;
    for (var i = 0; i < positionalArguments.length; i++) {
      if (parameters[i].isNamed) {
        // Not enough positional arguments.
        return false;
      }
      if (!_checkType(invocation.positionalArguments[i], parameters[i].type))
        return false;
    }
    if (invocation.namedArguments.isNotEmpty) {
      var startNamed;
      for (startNamed = parameters.length - 1; startNamed >= 0; startNamed--) {
        if (!parameters[startNamed].isNamed) break;
      }
      startNamed++;

      // TODO(jacobr): we are unnecessarily using an O(n^2) algorithm here.
      // If we have JS APIs with a large number of named parameters we should
      // optimize this. Either use a HashSet or invert this, walking over
      // parameters, querying invocation, and making sure we match
      //invocation.namedArguments.size keys.
      for (var name in invocation.namedArguments.keys) {
        bool match = false;
        for (var j = startNamed; j < parameters.length; j++) {
          var p = parameters[j];
          if (p.simpleName == name) {
            if (!_checkType(
                invocation.namedArguments[name], parameters[j].type))
              return false;
            match = true;
            break;
          }
        }
        if (match == false) return false;
      }
    }
    return true;
  }

  bool checkInvocation(Invocation invocation) {
    for (var member in _members) {
      if (_checkDeclaration(invocation, member)) return true;
    }
    return false;
  }

  void add(mirrors.DeclarationMirror mirror) {
    _members.add(mirror);
  }

  final List<mirrors.DeclarationMirror> _members;
}

/**
 * Temporary method that we hope to remove at some point. This method should
 * generally only be called by machine generated code.
 */
@Deprecated("Internal Use Only")
void registerJsInterfaces([List<Type> classes]) {
  // This method is now obsolete in Dartium.
}

void _registerJsInterfaces(List<Type> classes) {
  for (Type type in classes) {
    mirrors.ClassMirror typeMirror = mirrors.reflectType(type);
    typeMirror.declarations.forEach((symbol, declaration) {
      if (declaration is mirrors.MethodMirror ||
          declaration is mirrors.VariableMirror && !declaration.isStatic) {
        bool treatAsGetter = false;
        bool treatAsSetter = false;
        if (declaration is mirrors.VariableMirror) {
          treatAsGetter = true;
          if (!declaration.isConst && !declaration.isFinal) {
            treatAsSetter = true;
          }
        } else {
          if (declaration.isGetter) {
            treatAsGetter = true;
          } else if (declaration.isSetter) {
            treatAsSetter = true;
          } else if (!declaration.isConstructor) {
            _allowedMethods
                .putIfAbsent(symbol, () => new _DeclarationSet())
                .add(declaration);
          }
        }
        if (treatAsGetter) {
          _allowedGetters
              .putIfAbsent(symbol, () => new _DeclarationSet())
              .add(declaration);
          _allowedMethods
              .putIfAbsent(symbol, () => new _DeclarationSet())
              .add(declaration);
        }
        if (treatAsSetter) {
          _allowedSetters
              .putIfAbsent(symbol, () => new _DeclarationSet())
              .add(declaration);
        }
      }
    });
  }
}

_finalizeJsInterfaces() native "Js_finalizeJsInterfaces";

String _getJsName(mirrors.DeclarationMirror mirror) {
  if (_atJsType != null) {
    for (var annotation in mirror.metadata) {
      if (annotation.type.reflectedType == _atJsType) {
        try {
          var name = annotation.reflectee.name;
          return name != null ? name : "";
        } catch (e) {}
      }
    }
  }
  return null;
}

bool _isAnonymousClass(mirrors.ClassMirror mirror) {
  for (var annotation in mirror.metadata) {
    if (mirrors.MirrorSystem.getName(annotation.type.simpleName) ==
        "_Anonymous") {
      mirrors.LibraryMirror library = annotation.type.owner;
      var uri = library.uri;
      // make sure the annotation is from package://js
      if (uri.scheme == 'package' && uri.path == 'js/js.dart') {
        return true;
      }
    }
  }
  return false;
}

bool _hasJsName(mirrors.DeclarationMirror mirror) {
  if (_atJsType != null) {
    for (var annotation in mirror.metadata) {
      if (annotation.type.reflectedType == _atJsType) {
        return true;
      }
    }
  }
  return false;
}

var _domNameType;

bool hasDomName(mirrors.DeclarationMirror mirror) {
  var location = mirror.location;
  if (location == null || location.sourceUri.scheme != 'dart') return false;
  for (var annotation in mirror.metadata) {
    if (mirrors.MirrorSystem.getName(annotation.type.simpleName) == "DomName") {
      // We can't make sure the annotation is in dart: as Dartium believes it
      // is file://dart/sdk/lib/html/html_common/metadata.dart
      // instead of a proper dart: location.
      return true;
    }
  }
  return false;
}

_getJsMemberName(mirrors.DeclarationMirror mirror) {
  var name = _getJsName(mirror);
  return name == null || name.isEmpty
      ? _stripReservedNamePrefix(_getDeclarationName(mirror))
      : name;
}

// TODO(jacobr): handle setters correctyl.
String _getDeclarationName(mirrors.DeclarationMirror declaration) {
  var name = mirrors.MirrorSystem.getName(declaration.simpleName);
  if (declaration is mirrors.MethodMirror && declaration.isSetter) {
    assert(name.endsWith("="));
    name = name.substring(0, name.length - 1);
  }
  return name;
}

final _JS_LIBRARY_PREFIX = "js_library";
final _UNDEFINED_VAR = "_UNDEFINED_JS_CONST";

String _accessJsPath(String path) => _accessJsPathHelper(path.split("."));

String _accessJsPathHelper(Iterable<String> parts) {
  var sb = new StringBuffer();
  sb
    ..write('${_JS_LIBRARY_PREFIX}.JsNative.getProperty(' * parts.length)
    ..write("${_JS_LIBRARY_PREFIX}.context");
  for (var p in parts) {
    sb.write(", ${_escapeString(p)})");
  }
  return sb.toString();
}

// TODO(jacobr): remove these helpers and add JsNative.setPropertyDotted,
// getPropertyDotted, and callMethodDotted helpers that would be simpler
// and more efficient.
String _accessJsPathSetter(String path) {
  var parts = path.split(".");
  return "${_JS_LIBRARY_PREFIX}.JsNative.setProperty(${_accessJsPathHelper(parts.getRange(0, parts.length - 1))
      }, ${_escapeString(parts.last)}, v)";
}

String _accessJsPathCallMethodHelper(String path) {
  var parts = path.split(".");
  return "${_JS_LIBRARY_PREFIX}.JsNative.callMethod(${_accessJsPathHelper(parts.getRange(0, parts.length - 1))
      }, ${_escapeString(parts.last)},";
}

@Deprecated("Internal Use Only")
void addMemberHelper(
    mirrors.MethodMirror declaration, String path, StringBuffer sb,
    {bool isStatic: false, String memberName}) {
  if (!declaration.isConstructor) {
    var jsName = _getJsMemberName(declaration);
    path = (path != null && path.isNotEmpty) ? "${path}.${jsName}" : jsName;
  }
  var name = memberName != null ? memberName : _getDeclarationName(declaration);
  if (declaration.isConstructor) {
    sb.write("factory");
  } else if (isStatic) {
    sb.write("static");
  } else {
    sb.write("@patch");
  }
  sb.write(" ");
  if (declaration.isGetter) {
    sb.write("get $name => ${_accessJsPath(path)};");
  } else if (declaration.isSetter) {
    sb.write("set $name(v) {\n"
        "  ${_JS_LIBRARY_PREFIX}.safeForTypedInterop(v);\n"
        "  return ${_accessJsPathSetter(path)};\n"
        "}\n");
  } else {
    sb.write("$name(");
    bool hasOptional = false;
    int i = 0;
    var args = <String>[];
    for (var p in declaration.parameters) {
      assert(!p.isNamed); // TODO(jacobr): throw.
      assert(!p.hasDefaultValue);
      if (i > 0) {
        sb.write(", ");
      }
      if (p.isOptional && !hasOptional) {
        sb.write("[");
        hasOptional = true;
      }
      var arg = "p$i";
      args.add(arg);
      sb.write(arg);
      if (p.isOptional) {
        sb.write("=${_UNDEFINED_VAR}");
      }
      i++;
    }
    if (hasOptional) {
      sb.write("]");
    }
    // TODO(jacobr):
    sb.write(") {\n");
    for (var arg in args) {
      sb.write("  ${_JS_LIBRARY_PREFIX}.safeForTypedInterop($arg);\n");
    }
    sb.write("  return ");
    if (declaration.isConstructor) {
      sb.write("${_JS_LIBRARY_PREFIX}.JsNative.callConstructor(");
      sb..write(_accessJsPath(path))..write(",");
    } else {
      sb.write(_accessJsPathCallMethodHelper(path));
    }
    sb.write("[${args.join(",")}]");

    if (hasOptional) {
      sb.write(".takeWhile((i) => i != ${_UNDEFINED_VAR}).toList()");
    }
    sb.write(");");
    sb.write("}\n");
  }
  sb.write("\n");
}

bool _isExternal(mirrors.MethodMirror mirror) {
  // This try-catch block is a workaround for BUG:24834.
  try {
    return mirror.isExternal;
  } catch (e) {}
  return false;
}

List<String> _generateExternalMethods(
    List<String> libraryPaths, bool useCachedPatches) {
  var staticCodegen = <String>[];

  if (libraryPaths.length == 0) {
    mirrors.currentMirrorSystem().libraries.forEach((uri, library) {
      var library_name = "${uri.scheme}:${uri.path}";
      if (useCachedPatches && cached_patches.containsKey(library_name)) {
        // Use the pre-generated patch files for DOM dart:nnnn libraries.
        var patch = cached_patches[library_name];
        staticCodegen.addAll(patch);
      } else if (_hasJsName(library)) {
        // Library marked with @JS
        _generateLibraryCodegen(uri, library, staticCodegen);
      } else if (!useCachedPatches) {
        // Can't use the cached patches file, instead this is a signal to generate
        // the patches for this file.
        _generateLibraryCodegen(uri, library, staticCodegen);
      }
    }); // End of library foreach
  } else {
    // Used to generate cached_patches.dart file for all IDL generated dart:
    // files to the WebKit DOM.
    for (var library_name in libraryPaths) {
      var parts = library_name.split(':');
      var uri = new Uri(scheme: parts[0], path: parts[1]);
      var library = mirrors.currentMirrorSystem().libraries[uri];
      _generateLibraryCodegen(uri, library, staticCodegen);
    }
  }

  return staticCodegen;
}

_generateLibraryCodegen(uri, library, staticCodegen) {
  // Is it a dart generated library?
  var dartLibrary = uri.scheme == 'dart';

  var sb = new StringBuffer();
  String jsLibraryName = _getJsName(library);

  // Sort by patch file by its declaration name.
  var sortedDeclKeys = library.declarations.keys.toList();
  sortedDeclKeys.sort((a, b) => mirrors.MirrorSystem
      .getName(a)
      .compareTo(mirrors.MirrorSystem.getName(b)));

  sortedDeclKeys.forEach((name) {
    var declaration = library.declarations[name];
    if (declaration is mirrors.MethodMirror) {
      if ((_hasJsName(declaration) || jsLibraryName != null) &&
          _isExternal(declaration)) {
        addMemberHelper(declaration, jsLibraryName, sb);
      }
    } else if (declaration is mirrors.ClassMirror) {
      mirrors.ClassMirror clazz = declaration;
      var isDom = dartLibrary ? hasDomName(clazz) : false;
      var isJsInterop = _hasJsName(clazz);
      if (isDom || isJsInterop) {
        // TODO(jacobr): verify class implements JavaScriptObject.
        var className = mirrors.MirrorSystem.getName(clazz.simpleName);
        bool isPrivateUserDefinedClass =
            className.startsWith('_') && !dartLibrary;
        var classNameImpl = '${className}Impl';
        var sbPatch = new StringBuffer();
        if (isJsInterop) {
          String jsClassName = _getJsMemberName(clazz);

          jsInterfaceTypes.add(clazz);
          clazz.declarations.forEach((name, declaration) {
            if (declaration is! mirrors.MethodMirror ||
                !_isExternal(declaration)) return;
            if (declaration.isFactoryConstructor && _isAnonymousClass(clazz)) {
              sbPatch.write("  factory ${className}(");
              int i = 0;
              var args = <String>[];
              for (var p in declaration.parameters) {
                args.add(mirrors.MirrorSystem.getName(p.simpleName));
                i++;
              }
              if (args.isNotEmpty) {
                sbPatch
                  ..write('{')
                  ..write(
                      args.map((name) => '$name:${_UNDEFINED_VAR}').join(", "))
                  ..write('}');
              }
              sbPatch.write(") {\n"
                  "    var ret = ${_JS_LIBRARY_PREFIX}.JsNative.newObject();\n");
              i = 0;
              for (var p in declaration.parameters) {
                assert(p.isNamed); // TODO(jacobr): throw.
                var name = args[i];
                var jsName = _stripReservedNamePrefix(
                    mirrors.MirrorSystem.getName(p.simpleName));
                sbPatch.write("    if($name != ${_UNDEFINED_VAR}) {\n"
                    "      ${_JS_LIBRARY_PREFIX}.safeForTypedInterop($name);\n"
                    "      ${_JS_LIBRARY_PREFIX}.JsNative.setProperty(ret, ${_escapeString(jsName)}, $name);\n"
                    "    }\n");
                i++;
              }

              sbPatch.write("  return ret;"
                  "}\n");
            } else if (declaration.isConstructor ||
                declaration.isFactoryConstructor) {
              sbPatch.write("  ");
              addMemberHelper(
                  declaration,
                  (jsLibraryName != null && jsLibraryName.isNotEmpty)
                      ? "${jsLibraryName}.${jsClassName}"
                      : jsClassName,
                  sbPatch,
                  isStatic: true,
                  memberName: className);
            }
          }); // End of clazz.declarations.forEach

          clazz.staticMembers.forEach((memberName, member) {
            if (_isExternal(member)) {
              sbPatch.write("  ");
              addMemberHelper(
                  member,
                  (jsLibraryName != null && jsLibraryName.isNotEmpty)
                      ? "${jsLibraryName}.${jsClassName}"
                      : jsClassName,
                  sbPatch,
                  isStatic: true);
            }
          });
        }
        if (isDom) {
          sbPatch.write(
              "  static Type get instanceRuntimeType => ${classNameImpl};\n");
        }
        if (isPrivateUserDefinedClass) {
          sb.write("""
class ${escapePrivateClassPrefix}${className} implements $className {}
""");
        }

        if (sbPatch.isNotEmpty) {
          var typeVariablesClause = '';
          if (!clazz.typeVariables.isEmpty) {
            typeVariablesClause =
                '<${clazz.typeVariables.map((m) => mirrors.MirrorSystem.getName(m.simpleName)).join(',')}>';
          }
          sb.write("""
@patch class $className$typeVariablesClause {
$sbPatch
}
""");
          if (isDom) {
            sb.write("""
class $classNameImpl$typeVariablesClause extends $className implements ${_JS_LIBRARY_PREFIX}.JSObjectInterfacesDom {
  ${classNameImpl}.internal_() : super.internal_();
  get runtimeType => $className;
  toString() => super.toString();
}
""");
          }
        }
      }
    }
  });
  if (sb.isNotEmpty) {
    staticCodegen
      ..add(uri.toString())
      ..add("${uri}_js_interop_patch.dart")
      ..add("""
import 'dart:js' as ${_JS_LIBRARY_PREFIX};

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const ${_UNDEFINED_VAR} = const Object();

${sb}
""");
  }
}

// Remember the @JS type to compare annotation type.
var _atJsType = -1;

void setupJsTypeCache() {
  // Cache the @JS Type.
  if (_atJsType == -1) {
    var uri = new Uri(scheme: "package", path: "js/js.dart");
    var jsLibrary = mirrors.currentMirrorSystem().libraries[uri];
    if (jsLibrary != null) {
      // @ JS used somewhere.
      var jsDeclaration = jsLibrary.declarations[new Symbol("JS")];
      _atJsType = jsDeclaration.reflectedType;
    } else {
      // @ JS not used in any library.
      _atJsType = null;
    }
  }
}

/**
 * Generates part files defining source code for JSObjectImpl, all DOM classes
 * classes. This codegen  is needed so that type checks for all registered
 * JavaScript interop classes pass.
 * If genCachedPatches is true then the patch files don't exist this is a special
 * signal to generate and emit the patches to stdout to be captured and put into
 * the file sdk/lib/js/dartium/cached_patches.dart
 */
List<String> _generateInteropPatchFiles(
    List<String> libraryPaths, genCachedPatches) {
  // Cache the @JS Type.
  if (_atJsType == -1) setupJsTypeCache();

  var ret =
      _generateExternalMethods(libraryPaths, genCachedPatches ? false : true);
  var libraryPrefixes = new Map<mirrors.LibraryMirror, String>();
  var prefixNames = new Set<String>();
  var sb = new StringBuffer();

  var implements = <String>[];
  var implementsArray = <String>[];
  var implementsDom = <String>[];
  var listMirror = mirrors.reflectType(List);
  var functionMirror = mirrors.reflectType(Function);
  var jsObjectMirror = mirrors.reflectType(JSObject);

  for (var typeMirror in jsInterfaceTypes) {
    mirrors.LibraryMirror libraryMirror = typeMirror.owner;
    var location = libraryMirror.location;
    var dartLibrary = location != null && location.sourceUri.scheme == 'dart';

    var prefixName;
    if (libraryPrefixes.containsKey(libraryMirror)) {
      prefixName = libraryPrefixes[libraryMirror];
    } else {
      var basePrefixName =
          mirrors.MirrorSystem.getName(libraryMirror.simpleName);
      basePrefixName = basePrefixName.replaceAll('.', '_');
      if (basePrefixName.isEmpty) basePrefixName = "lib";
      prefixName = basePrefixName;
      var i = 1;
      while (prefixNames.contains(prefixName)) {
        prefixName = '$basePrefixName$i';
        i++;
      }
      prefixNames.add(prefixName);
      libraryPrefixes[libraryMirror] = prefixName;
    }
    var isArray = typeMirror.isSubtypeOf(listMirror);
    var isFunction = typeMirror.isSubtypeOf(functionMirror);
    var isJSObject = typeMirror.isSubtypeOf(jsObjectMirror);
    var className = mirrors.MirrorSystem.getName(typeMirror.simpleName);
    var isPrivateUserDefinedClass = className.startsWith('_') && !dartLibrary;
    if (isPrivateUserDefinedClass)
      className = '${escapePrivateClassPrefix}${className}';
    var fullName = '${prefixName}.${className}';
    (isArray ? implementsArray : implements).add(fullName);
    if (!isArray && !isFunction && !isJSObject) {
      // For DOM classes we need to be a bit more conservative at tagging them
      // as implementing JS interop classes risks strange unintended
      // consequences as unrleated code may have instanceof checks.  Checking
      // for isJSObject ensures we do not accidentally pull in existing
      // dart:html classes as they all have JSObject as a base class.
      // Note that methods from these classes can still be called on a
      // dart:html instance but checked mode type checks will fail. This is
      // not ideal but is better than causing strange breaks in existing
      // code that uses dart:html.
      // TODO(jacobr): consider throwing compile time errors if @JS classes
      // extend JSObject as that case cannot be safely handled in Dartium.
      implementsDom.add(fullName);
    }
  }
  libraryPrefixes.forEach((libraryMirror, prefix) {
    sb.writeln('import "${libraryMirror.uri}" as $prefix;');
  });
  buildImplementsClause(classes) =>
      classes.isEmpty ? "" : "implements ${classes.join(', ')}";
  var implementsClause = buildImplementsClause(implements);
  var implementsClauseDom = buildImplementsClause(implementsDom);
  // TODO(jacobr): only certain classes need to be implemented by
  // JsFunctionImpl.
  var allTypes = []..addAll(implements)..addAll(implementsArray);
  sb.write('''
class JSObjectImpl extends JSObject $implementsClause {
  JSObjectImpl.internal() : super.internal();
}

class JSFunctionImpl extends JSFunction $implementsClause {
  JSFunctionImpl.internal() : super.internal();
}

class JSArrayImpl extends JSArray ${buildImplementsClause(implementsArray)} {
  JSArrayImpl.internal() : super.internal();
}

// Interfaces that are safe to slam on all DOM classes.
// Adding implementsClause would be risky as it could contain Function which
// is likely to break a lot of instanceof checks.
abstract class JSObjectInterfacesDom $implementsClauseDom {
}

@patch class JSObject {
  static Type get instanceRuntimeType => JSObjectImpl;
}

@patch class JSFunction {
  static Type get instanceRuntimeType => JSFunctionImpl;
}

@patch class JSArray {
  static Type get instanceRuntimeType => JSArrayImpl;
}

_registerAllJsInterfaces() {
  _registerJsInterfaces([${allTypes.join(", ")}]);
}

''');
  ret..addAll(["dart:js", "JSInteropImpl.dart", sb.toString()]);
  return ret;
}

// Start of block of helper methods facilitating emulating JavaScript Array
// methods on Dart List objects passed to JavaScript via JS interop.
// TODO(jacobr): match JS more closely.
String _toStringJs(obj) => '$obj';

// TODO(jacobr): this might not exactly match JS semantics but should be
// adequate for now.
int _toIntJs(obj) {
  if (obj is int) return obj;
  if (obj is num) return obj.toInt();
  return num.parse('$obj'.trim(), (_) => 0).toInt();
}

// TODO(jacobr): this might not exactly match JS semantics but should be
// adequate for now.
num _toNumJs(obj) {
  return obj is num ? obj : num.parse('$obj'.trim(), (_) => 0);
}

/// Match the behavior of setting List length in JavaScript with the exception
/// that Dart does not distinguish undefined and null.
_setListLength(List list, rawlen) {
  num len = _toNumJs(rawlen);
  if (len is! int || len < 0) {
    throw new RangeError("Invalid array length");
  }
  if (len > list.length) {
    _arrayExtend(list, len);
  } else if (len < list.length) {
    list.removeRange(len, list.length);
  }
  return rawlen;
}

// TODO(jacobr): should we really bother with this method instead of just
// shallow copying to a JS array and calling the JavaScript join method?
String _arrayJoin(List list, sep) {
  if (sep == null) {
    sep = ",";
  }
  return list.map((e) => e == null ? "" : e.toString()).join(sep.toString());
}

// TODO(jacobr): should we really bother with this method instead of just
// shallow copying to a JS array and using the toString method?
String _arrayToString(List list) => _arrayJoin(list, ",");

int _arrayPush(List list, List args) {
  for (var e in args) {
    list.add(e);
  }
  return list.length;
}

_arrayPop(List list) {
  if (list.length > 0) return list.removeLast();
}

// TODO(jacobr): would it be better to just copy input to a JS List
// and call Array.concat?
List _arrayConcat(List input, List args) {
  var ret = new List.from(input);
  for (var e in args) {
    // TODO(jacobr): technically in ES6 we should use
    // Symbol.isConcatSpreadable to determine whether call addAll. Once v8
    // supports it, we can make all Dart classes implementing Iterable
    // specify isConcatSpreadable and tweak this behavior to allow Iterable.
    if (e is List) {
      ret.addAll(e);
    } else {
      ret.add(e);
    }
  }
  return ret;
}

List _arraySplice(List input, List args) {
  int start = 0;
  if (args.length > 0) {
    var rawStart = _toIntJs(args[0]);
    if (rawStart < 0) {
      start = math.max(0, input.length - rawStart);
    } else {
      start = math.min(input.length, rawStart);
    }
  }
  var end = start;
  if (args.length > 1) {
    var rawDeleteCount = _toIntJs(args[1]);
    if (rawDeleteCount < 0) rawDeleteCount = 0;
    end = math.min(input.length, start + rawDeleteCount);
  }
  var replacement = [];
  var removedElements = input.getRange(start, end).toList();
  if (args.length > 2) {
    replacement = args.getRange(2, args.length);
  }
  input.replaceRange(start, end, replacement);
  return removedElements;
}

List _arrayReverse(List l) {
  for (var i = 0, j = l.length - 1; i < j; i++, j--) {
    var tmp = l[i];
    l[i] = l[j];
    l[j] = tmp;
  }
  return l;
}

_arrayShift(List l) {
  if (l.isEmpty) return null; // Technically we should return undefined.
  return l.removeAt(0);
}

int _arrayUnshift(List l, List args) {
  l.insertAll(0, args);
  return l.length;
}

_arrayExtend(List l, int newLength) {
  for (var i = l.length; i < newLength; i++) {
    // TODO(jacobr): we'd really like to add undefined to better match
    // JavaScript semantics.
    l.add(null);
  }
}

List _arraySort(List l, rawCompare) {
  // TODO(jacobr): alternately we could just copy the Array to JavaScript,
  // invoke the JS sort method and then copy the result back to Dart.
  Comparator compare;
  if (rawCompare == null) {
    compare = (a, b) => _toStringJs(a).compareTo(_toStringJs(b));
  } else if (rawCompare is JsFunction) {
    compare = (a, b) => rawCompare.apply([a, b]);
  } else {
    compare = rawCompare;
  }
  l.sort(compare);
  return l;
}
// End of block of helper methods to emulate JavaScript Array methods on Dart List.

/**
 * Can be called to provide a predictable point where no more JS interfaces can
 * be added. Creating an instance of JsObject will also automatically trigger
 * all JsObjects to be finalized.
 */
@Deprecated("Internal Use Only")
void finalizeJsInterfaces() {
  if (_finalized == true) {
    throw 'JSInterop class registration already finalized';
  }
  _finalizeJsInterfaces();
}

JsObject _cachedContext;

JsObject get _context native "Js_context_Callback";

bool get _finalized native "Js_interfacesFinalized_Callback";

JsObject get context {
  if (_cachedContext == null) {
    _cachedContext = _context;
  }
  return _cachedContext;
}

_lookupType(o, bool isCrossFrame, bool isElement) {
  try {
    var type = html_common.lookupType(o, isElement);
    var typeMirror = mirrors.reflectType(type);
    var legacyInteropConvertToNative =
        typeMirror.isSubtypeOf(mirrors.reflectType(html.Blob)) ||
            typeMirror.isSubtypeOf(mirrors.reflectType(html.Event)) ||
            typeMirror.isSubtypeOf(mirrors.reflectType(indexed_db.KeyRange)) ||
            typeMirror.isSubtypeOf(mirrors.reflectType(html.ImageData)) ||
            typeMirror.isSubtypeOf(mirrors.reflectType(html.Node)) ||
//        TypedData is removed from this list as it is converted directly
//        rather than flowing through the interceptor code path.
//        typeMirror.isSubtypeOf(mirrors.reflectType(typed_data.TypedData)) ||
            typeMirror.isSubtypeOf(mirrors.reflectType(html.Window));
    if (isCrossFrame &&
        !typeMirror.isSubtypeOf(mirrors.reflectType(html.Window))) {
      // TODO(jacobr): evaluate using the true cross frame Window class, etc.
      // as well as triggering that legacy JS Interop returns raw JsObject
      // instances.
      legacyInteropConvertToNative = false;
    }
    return [type, legacyInteropConvertToNative];
  } catch (e) {}
  return [JSObject.instanceRuntimeType, false];
}

/**
 * Base class for both the legacy JsObject class and the modern JSObject class.
 * This allows the JsNative utility class tobehave identically whether it is
 * called on a JsObject or a JSObject.
 */
class _JSObjectBase extends NativeFieldWrapperClass2 {
  String _toString() native "JSObject_toString";
  _callMethod(String name, List args) native "JSObject_callMethod";
  _operator_getter(String property) native "JSObject_[]";
  _operator_setter(String property, value) native "JSObject_[]=";
  bool _hasProperty(String property) native "JsObject_hasProperty";
  bool _instanceof(/*JsFunction|JSFunction*/ type) native "JsObject_instanceof";

  int get hashCode native "JSObject_hashCode";
}

/**
 * Proxies a JavaScript object to Dart.
 *
 * The properties of the JavaScript object are accessible via the `[]` and
 * `[]=` operators. Methods are callable via [callMethod].
 */
class JsObject extends _JSObjectBase {
  JsObject.internal();

  /**
   * Constructs a new JavaScript object from [constructor] and returns a proxy
   * to it.
   */
  factory JsObject(JsFunction constructor, [List arguments]) {
    try {
      return _create(constructor, arguments);
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new html.DomException.jsInterop(e);
    }
  }

  static JsObject _create(JsFunction constructor, arguments)
      native "JsObject_constructorCallback";

  /**
   * Constructs a [JsObject] that proxies a native Dart object; _for expert use
   * only_.
   *
   * Use this constructor only if you wish to get access to JavaScript
   * properties attached to a browser host object, such as a Node or Blob, that
   * is normally automatically converted into a native Dart object.
   *
   * An exception will be thrown if [object] either is `null` or has the type
   * `bool`, `num`, or `String`.
   */
  factory JsObject.fromBrowserObject(object) {
    if (object is num || object is String || object is bool || object == null) {
      throw new ArgumentError("object cannot be a num, string, bool, or null");
    }
    if (object is JsObject) return object;
    return _fromBrowserObject(object);
  }

  /**
   * Recursively converts a JSON-like collection of Dart objects to a
   * collection of JavaScript objects and returns a [JsObject] proxy to it.
   *
   * [object] must be a [Map] or [Iterable], the contents of which are also
   * converted. Maps and Iterables are copied to a new JavaScript object.
   * Primitives and other transferrable values are directly converted to their
   * JavaScript type, and all other objects are proxied.
   */
  factory JsObject.jsify(object) {
    if ((object is! Map) && (object is! Iterable)) {
      throw new ArgumentError("object must be a Map or Iterable");
    }
    return _jsify(object);
  }

  static JsObject _jsify(object) native "JsObject_jsify";

  static JsObject _fromBrowserObject(object)
      native "JsObject_fromBrowserObject";

  /**
   * Returns the value associated with [property] from the proxied JavaScript
   * object.
   *
   * The type of [property] must be either [String] or [num].
   */
  operator [](property) {
    try {
      return _operator_getterLegacy(property);
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new html.DomException.jsInterop(e);
    }
  }

  _operator_getterLegacy(property) native "JsObject_[]Legacy";

  /**
   * Sets the value associated with [property] on the proxied JavaScript
   * object.
   *
   * The type of [property] must be either [String] or [num].
   */
  operator []=(property, value) {
    try {
      _operator_setterLegacy(property, value);
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new html.DomException.jsInterop(e);
    }
  }

  _operator_setterLegacy(property, value) native "JsObject_[]=Legacy";

  int get hashCode native "JsObject_hashCode";

  operator ==(other) {
    if (other is! JsObject && other is! JSObject) return false;
    return _identityEquality(this, other);
  }

  static bool _identityEquality(a, b) native "JsObject_identityEquality";

  /**
   * Returns `true` if the JavaScript object contains the specified property
   * either directly or though its prototype chain.
   *
   * This is the equivalent of the `in` operator in JavaScript.
   */
  bool hasProperty(String property) => _hasProperty(property);

  /**
   * Removes [property] from the JavaScript object.
   *
   * This is the equivalent of the `delete` operator in JavaScript.
   */
  void deleteProperty(String property) native "JsObject_deleteProperty";

  /**
   * Returns `true` if the JavaScript object has [type] in its prototype chain.
   *
   * This is the equivalent of the `instanceof` operator in JavaScript.
   */
  bool instanceof(JsFunction type) => _instanceof(type);

  /**
   * Returns the result of the JavaScript objects `toString` method.
   */
  String toString() {
    try {
      return _toString();
    } catch (e) {
      return super.toString();
    }
  }

  String _toString() native "JsObject_toString";

  /**
   * Calls [method] on the JavaScript object with the arguments [args] and
   * returns the result.
   *
   * The type of [method] must be either [String] or [num].
   */
  callMethod(String method, [List args]) {
    try {
      return _callMethodLegacy(method, args);
    } catch (e) {
      if (hasProperty(method)) {
        // Return a DomException if DOM call returned an error.
        throw new html.DomException.jsInterop(e);
      } else {
        throw new NoSuchMethodError(this, new Symbol(method), args, null);
      }
    }
  }

  _callMethodLegacy(String name, List args) native "JsObject_callMethodLegacy";
}

/// Base class for all JS objects used through dart:html and typed JS interop.
@Deprecated("Internal Use Only")
class JSObject extends _JSObjectBase {
  JSObject.internal() {}
  external static Type get instanceRuntimeType;

  /**
   * Returns the result of the JavaScript objects `toString` method.
   */
  String toString() {
    try {
      return _toString();
    } catch (e) {
      return super.toString();
    }
  }

  noSuchMethod(Invocation invocation) {
    throwError() {
      super.noSuchMethod(invocation);
    }

    String name = _stripReservedNamePrefix(
        mirrors.MirrorSystem.getName(invocation.memberName));
    argsSafeForTypedInterop(invocation.positionalArguments);
    if (invocation.isGetter) {
      if (CHECK_JS_INVOCATIONS) {
        var matches = _allowedGetters[invocation.memberName];
        if (matches == null &&
            !_allowedMethods.containsKey(invocation.memberName)) {
          throwError();
        }
        var ret = _operator_getter(name);
        if (matches != null) return ret;
        if (ret is Function ||
            (ret is JsFunction /* shouldn't be needed in the future*/) &&
                _allowedMethods.containsKey(invocation.memberName))
          return ret; // Warning: we have not bound "this"... we could type check on the Function but that is of little value in Dart.
        throwError();
      } else {
        // TODO(jacobr): should we throw if the JavaScript object doesn't have the property?
        return _operator_getter(name);
      }
    } else if (invocation.isSetter) {
      if (CHECK_JS_INVOCATIONS) {
        var matches = _allowedSetters[invocation.memberName];
        if (matches == null || !matches.checkInvocation(invocation))
          throwError();
      }
      assert(name.endsWith("="));
      name = name.substring(0, name.length - 1);
      return _operator_setter(name, invocation.positionalArguments.first);
    } else {
      // TODO(jacobr): also allow calling getters that look like functions.
      var matches;
      if (CHECK_JS_INVOCATIONS) {
        matches = _allowedMethods[invocation.memberName];
        if (matches == null || !matches.checkInvocation(invocation))
          throwError();
      }
      var ret = _callMethod(name, _buildArgs(invocation));
      if (CHECK_JS_INVOCATIONS) {
        if (!matches._checkReturnType(ret)) {
          html.window.console.error("Return value for method: ${name} is "
              "${ret.runtimeType} which is inconsistent with all typed "
              "JS interop definitions for method ${name}.");
        }
      }
      return ret;
    }
  }
}

@Deprecated("Internal Use Only")
class JSArray extends JSObject with ListMixin {
  JSArray.internal() : super.internal();
  external static Type get instanceRuntimeType;

  // Reuse JsArray_length as length behavior is unchanged.
  int get length native "JsArray_length";

  set length(int length) {
    _operator_setter('length', length);
  }

  _checkIndex(int index, {bool insert: false}) {
    int length = insert ? this.length + 1 : this.length;
    if (index is int && (index < 0 || index >= length)) {
      throw new RangeError.range(index, 0, length);
    }
  }

  _checkRange(int start, int end) {
    int cachedLength = this.length;
    if (start < 0 || start > cachedLength) {
      throw new RangeError.range(start, 0, cachedLength);
    }
    if (end < start || end > cachedLength) {
      throw new RangeError.range(end, start, cachedLength);
    }
  }

  _indexed_getter(int index) native "JSArray_indexed_getter";
  _indexed_setter(int index, o) native "JSArray_indexed_setter";

  // Methods required by ListMixin

  operator [](index) {
    if (index is int) {
      _checkIndex(index);
    }

    return _indexed_getter(index);
  }

  void operator []=(int index, value) {
    _checkIndex(index);
    _indexed_setter(index, value);
  }
}

@Deprecated("Internal Use Only")
class JSFunction extends JSObject implements Function {
  JSFunction.internal() : super.internal();

  external static Type get instanceRuntimeType;

  call(
      [a1 = _UNDEFINED,
      a2 = _UNDEFINED,
      a3 = _UNDEFINED,
      a4 = _UNDEFINED,
      a5 = _UNDEFINED,
      a6 = _UNDEFINED,
      a7 = _UNDEFINED,
      a8 = _UNDEFINED,
      a9 = _UNDEFINED,
      a10 = _UNDEFINED]) {
    return _apply(
        _stripUndefinedArgs([a1, a2, a3, a4, a5, a6, a7, a8, a9, a10]));
  }

  noSuchMethod(Invocation invocation) {
    if (invocation.isMethod && invocation.memberName == #call) {
      return _apply(_buildArgs(invocation));
    }
    return super.noSuchMethod(invocation);
  }

  dynamic _apply(List args, {thisArg}) native "JSFunction_apply";

  static JSFunction _createWithThis(Function f)
      native "JSFunction_createWithThis";
  static JSFunction _create(Function f) native "JSFunction_create";
}

// JavaScript interop methods that do not automatically wrap to dart:html types.
// Warning: this API is not exposed to dart:js.
// TODO(jacobr): rename to JSNative and make at least part of this API public.
@Deprecated("Internal Use Only")
class JsNative {
  static JSObject jsify(object) native "JSObject_jsify";
  static JSObject newObject() native "JSObject_newObject";
  static JSArray newArray() native "JSObject_newArray";

  static hasProperty(_JSObjectBase o, name) => o._hasProperty(name);
  static getProperty(_JSObjectBase o, name) => o._operator_getter(name);
  static setProperty(_JSObjectBase o, name, value) =>
      o._operator_setter(name, value);
  static callMethod(_JSObjectBase o, String method, List args) =>
      o._callMethod(method, args);
  static instanceof(_JSObjectBase o, /*JsFunction|JSFunction*/ type) =>
      o._instanceof(type);
  static callConstructor0(_JSObjectBase constructor)
      native "JSNative_callConstructor0";
  static callConstructor(_JSObjectBase constructor, List args)
      native "JSNative_callConstructor";

  static toTypedObject(JsObject o) native "JSNative_toTypedObject";

  /**
   * Same behavior as new JsFunction.withThis except that JavaScript "this" is not
   * wrapped.
   */
  static JSFunction withThis(Function f) native "JsFunction_withThisNoWrap";
}

/**
 * Proxies a JavaScript Function object.
 */
class JsFunction extends JsObject {
  JsFunction.internal() : super.internal();

  /**
   * Returns a [JsFunction] that captures its 'this' binding and calls [f]
   * with the value of this passed as the first argument.
   */
  factory JsFunction.withThis(Function f) => _withThis(f);

  /**
   * Invokes the JavaScript function with arguments [args]. If [thisArg] is
   * supplied it is the value of `this` for the invocation.
   */
  dynamic apply(List args, {thisArg}) => _apply(args, thisArg: thisArg);

  dynamic _apply(List args, {thisArg}) native "JsFunction_apply";

  /**
   * Internal only version of apply which uses debugger proxies of Dart objects
   * rather than opaque handles. This method is private because it cannot be
   * efficiently implemented in Dart2Js so should only be used by internal
   * tools.
   */
  _applyDebuggerOnly(List args, {thisArg})
      native "JsFunction_applyDebuggerOnly";

  static JsFunction _withThis(Function f) native "JsFunction_withThis";
}

/**
 * A [List] proxying a JavaScript Array.
 */
class JsArray<E> extends JsObject with ListMixin<E> {
  JsArray.internal() : super.internal();

  factory JsArray() => _newJsArray();

  static JsArray _newJsArray() native "JsArray_newJsArray";

  factory JsArray.from(Iterable<E> other) =>
      _newJsArrayFromSafeList(new List.from(other));

  static JsArray _newJsArrayFromSafeList(List list)
      native "JsArray_newJsArrayFromSafeList";

  _checkIndex(int index, {bool insert: false}) {
    int length = insert ? this.length + 1 : this.length;
    if (index is int && (index < 0 || index >= length)) {
      throw new RangeError.range(index, 0, length);
    }
  }

  _checkRange(int start, int end) {
    int cachedLength = this.length;
    if (start < 0 || start > cachedLength) {
      throw new RangeError.range(start, 0, cachedLength);
    }
    if (end < start || end > cachedLength) {
      throw new RangeError.range(end, start, cachedLength);
    }
  }

  // Methods required by ListMixin

  E operator [](index) {
    if (index is int) {
      _checkIndex(index);
    }

    return super[index];
  }

  void operator []=(index, E value) {
    if (index is int) {
      _checkIndex(index);
    }
    super[index] = value;
  }

  int get length native "JsArray_length";

  set length(int length) {
    super['length'] = length;
  }

  // Methods overridden for better performance

  void add(E value) {
    callMethod('push', [value]);
  }

  void addAll(Iterable<E> iterable) {
    // TODO(jacobr): this can be optimized slightly.
    callMethod('push', new List.from(iterable));
  }

  void insert(int index, E element) {
    _checkIndex(index, insert: true);
    callMethod('splice', [index, 0, element]);
  }

  E removeAt(int index) {
    _checkIndex(index);
    return callMethod('splice', [index, 1])[0];
  }

  E removeLast() {
    if (length == 0) throw new RangeError(-1);
    return callMethod('pop');
  }

  void removeRange(int start, int end) {
    _checkRange(start, end);
    callMethod('splice', [start, end - start]);
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _checkRange(start, end);
    int length = end - start;
    if (length == 0) return;
    if (skipCount < 0) throw new ArgumentError(skipCount);
    var args = [start, length]..addAll(iterable.skip(skipCount).take(length));
    callMethod('splice', args);
  }

  void sort([int compare(E a, E b)]) {
    callMethod('sort', [compare]);
  }
}

/**
 * Placeholder object for cases where we need to determine exactly how many
 * args were passed to a function.
 */
const _UNDEFINED = const Object();

// TODO(jacobr): this method is a hack to work around the lack of proper dart
// support for varargs methods.
List _stripUndefinedArgs(List args) =>
    args.takeWhile((i) => i != _UNDEFINED).toList();

/**
 * Check that that if [arg] is a [Function] it is safe to pass to JavaScript.
 * To make a function safe, call [allowInterop] or [allowInteropCaptureThis].
 */
@Deprecated("Internal Use Only")
safeForTypedInterop(arg) {
  if (CHECK_JS_INVOCATIONS && arg is Function && arg is! JSFunction) {
    throw new ArgumentError(
        "Attempt to pass Function '$arg' to JavaScript via without calling allowInterop or allowInteropCaptureThis");
  }
}

/**
 * Check that that if any elements of [args] are [Function] it is safe to pass
 * to JavaScript. To make a function safe, call [allowInterop] or
 * [allowInteropCaptureThis].
 */
@Deprecated("Internal Use Only")
void argsSafeForTypedInterop(Iterable args) {
  for (var arg in args) {
    safeForTypedInterop(arg);
  }
}

/**
 * Returns a method that can be called with an arbitrary number (for n less
 * than 11) of arguments without violating Dart type checks.
 */
Function _wrapAsDebuggerVarArgsFunction(JsFunction jsFunction) => (
        [a1 = _UNDEFINED,
        a2 = _UNDEFINED,
        a3 = _UNDEFINED,
        a4 = _UNDEFINED,
        a5 = _UNDEFINED,
        a6 = _UNDEFINED,
        a7 = _UNDEFINED,
        a8 = _UNDEFINED,
        a9 = _UNDEFINED,
        a10 = _UNDEFINED]) =>
    jsFunction._applyDebuggerOnly(
        _stripUndefinedArgs([a1, a2, a3, a4, a5, a6, a7, a8, a9, a10]));

/// Returns a wrapper around function [f] that can be called from JavaScript
/// using the package:js Dart-JavaScript interop.
///
/// For performance reasons in Dart2Js, by default Dart functions cannot be
/// passed directly to JavaScript unless this method is called to create
/// a Function compatible with both Dart and JavaScript.
/// Calling this method repeatedly on a function will return the same function.
/// The [Function] returned by this method can be used from both Dart and
/// JavaScript. We may remove the need to call this method completely in the
/// future if Dart2Js is refactored so that its function calling conventions
/// are more compatible with JavaScript.
Function/*=F*/ allowInterop/*<F extends Function>*/(Function/*=F*/ f) {
  if (f is JSFunction) {
    // The function is already a JSFunction... no need to do anything.
    return f;
  } else {
    return JSFunction._create(f);
  }
}

/// Cached JSFunction associated with the Dart function when "this" is
/// captured.
Expando<JSFunction> _interopCaptureThisExpando = new Expando<JSFunction>();

/// Returns a [Function] that when called from JavaScript captures its 'this'
/// binding and calls [f] with the value of this passed as the first argument.
/// When called from Dart, [null] will be passed as the first argument.
///
/// See the documentation for [allowInterop]. This method should only be used
/// with package:js Dart-JavaScript interop.
JSFunction allowInteropCaptureThis(Function f) {
  if (f is JSFunction) {
    // Behavior when the function is already a JS function is unspecified.
    throw new ArgumentError(
        "Function is already a JS function so cannot capture this.");
    return f;
  } else {
    var ret = _interopCaptureThisExpando[f];
    if (ret == null) {
      // TODO(jacobr): we could optimize this.
      ret = JSFunction._createWithThis(f);
      _interopCaptureThisExpando[f] = ret;
    }
    return ret;
  }
}
