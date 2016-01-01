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
 * The following expression creats a new JavaScript object with the properties
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
import 'dart:html_common' as html_common;
import 'dart:indexed_db' as indexed_db;
import 'dart:typed_data';

// Pretend we are always in checked mode as we aren't interested in users
// running Dartium code outside of checked mode.
@Deprecated("Internal Use Only")
final bool CHECK_JS_INVOCATIONS = true;

final _allowedMethods = new Map<Symbol, _DeclarationSet>();
final _allowedGetters = new Map<Symbol, _DeclarationSet>();
final _allowedSetters = new Map<Symbol, _DeclarationSet>();

final _jsInterfaceTypes = new Set<mirrors.ClassMirror>();
@Deprecated("Internal Use Only")
Iterable<mirrors.ClassMirror> get jsInterfaceTypes => _jsInterfaceTypes;

/// A collection of methods where all methods have the same name.
/// This class is intended to optimize whether a specific invocation is
/// appropritate for at least some of the methods in the collection.
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
      if (!_checkType(
          invocation.positionalArguments[i], parameters[i].type)) return false;
    }
    if (invocation.namedArguments.isNotEmpty) {
      var startNamed;
      for (startNamed = parameters.length - 1; startNamed >= 0; startNamed--) {
        if (!parameters[startNamed].isNamed) break;
      }
      startNamed++;

      // TODO(jacobr): we are unneccessarily using an O(n^2) algorithm here.
      // If we have JS APIs with a lange number of named parameters we should
      // optimize this. Either use a HashSet or invert this, walking over
      // parameters, querying invocation, and making sure we match
      //invocation.namedArguments.size keys.
      for (var name in invocation.namedArguments.keys) {
        bool match = false;
        for (var j = startNamed; j < parameters.length; j++) {
          var p = parameters[j];
          if (p.simpleName == name) {
            if (!_checkType(invocation.namedArguments[name],
                parameters[j].type)) return false;
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
  for (var annotation in mirror.metadata) {
    if (mirrors.MirrorSystem.getName(annotation.type.simpleName) == "JS") {
      mirrors.LibraryMirror library = annotation.type.owner;
      var uri = library.uri;
      // make sure the annotation is from package://js
      if (uri.scheme == 'package' && uri.path == 'js/js.dart') {
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

bool _hasJsName(mirrors.DeclarationMirror mirror) => _getJsName(mirror) != null;

_getJsMemberName(mirrors.DeclarationMirror mirror) {
  var name = _getJsName(mirror);
  return name == null || name.isEmpty ? _getDeclarationName(mirror) : name;
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
    sb.write(", '$p')");
  }
  return sb.toString();
}

String _accessJsPathSetter(String path) {
  var parts = path.split(".");
  return "${_JS_LIBRARY_PREFIX}.JsNative.setProperty(${_accessJsPathHelper(parts.getRange(0, parts.length - 1))
      }, '${parts.last}', v)";
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
    sb.write("patch");
  }
  sb.write(" ");
  if (declaration.isGetter) {
    sb.write("get $name => ${_JS_LIBRARY_PREFIX}.maybeWrapTypedInterop(${_accessJsPath(path)});");
  } else if (declaration.isSetter) {
    sb.write("set $name(v) => ${_JS_LIBRARY_PREFIX}.maybeWrapTypedInterop(${_accessJsPathSetter(path)});");
  } else {
    sb.write("$name(");
    bool hasOptional = false;
    int i = 0;
    var args = <String>[];
    for (var p in declaration.parameters) {
      assert(!p.isNamed); // XXX throw
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
    sb.write(") => ");
    sb.write('${_JS_LIBRARY_PREFIX}.maybeWrapTypedInterop(');
    if (declaration.isConstructor) {
      sb.write("new ${_JS_LIBRARY_PREFIX}.JsObject(");
    }
    sb
      ..write(_accessJsPath(path))
      ..write(declaration.isConstructor ? "," : ".apply(")
      ..write("[${args.join(",")}]");

    if (hasOptional) {
      sb.write(".takeWhile((i) => i != ${_UNDEFINED_VAR}).toList()");
    }
    sb.write("));");
  }
  sb.write("\n");
}

bool _isExternal(mirrors.MethodMirror mirror) {
  // This try-catch block is a workaround for BUG:24834.
  try {
    return mirror.isExternal;
  } catch (e) { }
  return false;
}

List<String> _generateExternalMethods() {
  var staticCodegen = <String>[];
  mirrors.currentMirrorSystem().libraries.forEach((uri, library) {
    var sb = new StringBuffer();
    String jsLibraryName = _getJsName(library);
    library.declarations.forEach((name, declaration) {
      if (declaration is mirrors.MethodMirror) {
        if ((_hasJsName(declaration) || jsLibraryName != null) &&
            _isExternal(declaration)) {
          addMemberHelper(declaration, jsLibraryName, sb);
        }
      } else if (declaration is mirrors.ClassMirror) {
        mirrors.ClassMirror clazz = declaration;
        if (_hasJsName(clazz)) {
          // TODO(jacobr): verify class implements JavaScriptObject.
          String jsClassName = _getJsMemberName(clazz);
          var className = mirrors.MirrorSystem.getName(clazz.simpleName);
          var sbPatch = new StringBuffer();
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
                    "    var ret = new ${_JS_LIBRARY_PREFIX}.JsObject.jsify({});\n");
              i = 0;
              for (var p in declaration.parameters) {
                assert(p.isNamed); // XXX throw
                var name = args[i];
                var jsName = mirrors.MirrorSystem.getName(p.simpleName);
                // XXX apply name conversion rules.
                sbPatch.write(
                    "    if($name != ${_UNDEFINED_VAR}) ret['$jsName'] = $name;\n");
                i++;
              }

              sbPatch.write("    return ret;\n"
                  "  }\n");
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
          });

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
          var typeVariablesClause = '';
          if (!clazz.typeVariables.isEmpty) {
            typeVariablesClause =
                '<${clazz.typeVariables.map((m) => mirrors.MirrorSystem.getName(m.simpleName)).join(',')}>';
          }
          if (sbPatch.isNotEmpty) {
            sb.write("""
patch class $className$typeVariablesClause {
$sbPatch
}
""");
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
  });

  return staticCodegen;
}

List<String> _generateExternalMethods2() {
  var staticCodegen = <String>[];
  mirrors.currentMirrorSystem().libraries.forEach((uri, library) {
    var sb = new StringBuffer();
    String jsLibraryName = _getJsName(library);
    library.declarations.forEach((name, declaration) {
      var isExternal = _isExternal(declaration);
      if (declaration is mirrors.MethodMirror) {
        if (isExternal && (_hasJsName(declaration) || jsLibraryName != null)) {
          addMemberHelper(declaration, jsLibraryName, sb);
        }
      } else if (declaration is mirrors.ClassMirror) {
        mirrors.ClassMirror clazz = declaration;
        if (_hasJsName(clazz)) {
          // TODO(jacobr): verify class implements JavaScriptObject.
          String jsClassName = _getJsMemberName(clazz);
          var className = mirrors.MirrorSystem.getName(clazz.simpleName);
          var sbPatch = new StringBuffer();
          jsInterfaceTypes.add(clazz);
          clazz.declarations.forEach((name, declaration) {
            if (declaration is! mirrors.MethodMirror ||
                !declaration.isAbstract ||
                !isExternal) return;
            if (_hasLiteralAnnotation(declaration) &&
                declaration.isFactoryConstructor) {
              sbPatch.write("  factory ${className}({");
              int i = 0;
              var args = <String>[];
              for (var p in declaration.parameters) {
                assert(p.isNamed); // XXX throw
                args.add(mirrors.MirrorSystem.getName(p.simpleName));
                i++;
              }
              sbPatch
                ..write(
                    args.map((name) => '$name:${_UNDEFINED_VAR}').join(", "))
                ..write("}) {\n"
                    "    var ret = new ${_JS_LIBRARY_PREFIX}.JsObject.jsify({});\n");
              i = 0;
              for (var p in declaration.parameters) {
                assert(p.isNamed); // XXX throw
                var name = args[i];
                var jsName = mirrors.MirrorSystem.getName(p.simpleName);
                // XXX apply name conversion rules.
                sbPatch.write(
                    "    if($name != ${_UNDEFINED_VAR}) ret['$jsName'] = $name;\n");
                i++;
              }

              sbPatch.write("    return ret;\n"
                  "  }\n");
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
          });

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
          var typeVariablesClause = '';
          if (!clazz.typeVariables.isEmpty) {
            typeVariablesClause =
                '<${clazz.typeVariables.map((m) => mirrors.MirrorSystem.getName(m.simpleName)).join(',')}>';
          }
          if (sbPatch.isNotEmpty) {
            sb.write("""
patch class $className$typeVariablesClause {
$sbPatch
}
""");
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
  });

  return staticCodegen;
}

/**
 * Generates a part file defining source code for JsObjectImpl and related
 * classes. This calass is needed so that type checks for all registered JavaScript
 * interop classes pass.
 */
List<String> _generateInteropPatchFiles() {
  var ret = _generateExternalMethods();
  var libraryPrefixes = new Map<mirrors.LibraryMirror, String>();
  var prefixNames = new Set<String>();
  var sb = new StringBuffer();

  var implements = <String>[];
  var implementsArray = <String>[];
  var listMirror = mirrors.reflectType(List);

  for (var typeMirror in jsInterfaceTypes) {
    mirrors.LibraryMirror libraryMirror = typeMirror.owner;
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
    (isArray ? implementsArray : implements).add(
        '${prefixName}.${mirrors.MirrorSystem.getName(typeMirror.simpleName)}');
  }
  libraryPrefixes.forEach((libraryMirror, prefix) {
    sb.writeln('import "${libraryMirror.uri}" as $prefix;');
  });
  buildImplementsClause(classes) =>
      classes.isEmpty ? "" : "implements ${classes.join(', ')}";
  var implementsClause = buildImplementsClause(implements);
  // TODO(jacobr): only certain classes need to be implemented by
  // JsFunctionImpl.
  var allTypes = []..addAll(implements)..addAll(implementsArray);
  sb.write('''
class JsObjectImpl extends JsObject $implementsClause {
  JsObjectImpl.internal() : super.internal();
}

class JsFunctionImpl extends JsFunction $implementsClause {
  JsFunctionImpl.internal() : super.internal();
}

class JsArrayImpl<E> extends JsArray<E> ${buildImplementsClause(implementsArray)} {
  JsArrayImpl.internal() : super.internal();
}

_registerAllJsInterfaces() {
  _registerJsInterfaces([${allTypes.join(", ")}]);
}

''');
  ret..addAll(["dart:js", "JsInteropImpl.dart", sb.toString()]);
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

@Deprecated("Internal Use Only")
maybeWrapTypedInterop(o) =>
    html_common.wrap_jso_no_SerializedScriptvalue(o);

_maybeWrap(o) {
  var wrapped = html_common.wrap_jso_no_SerializedScriptvalue(o);
  if (identical(wrapped, o)) return o;
  return (wrapped is html.Blob ||
      wrapped is html.Event ||
      wrapped is indexed_db.KeyRange ||
      wrapped is html.ImageData ||
      wrapped is html.Node ||
      wrapped is TypedData ||
      wrapped is html.Window) ? wrapped : o;
}

/**
 * Get the dart wrapper object for object. Top-level so we
 * we can access it from other libraries without it being
 * a public instance field on JsObject.
 */
@Deprecated("Internal Use Only")
getDartHtmlWrapperFor(JsObject object) => object._dartHtmlWrapper;

/**
 * Set the dart wrapper object for object. Top-level so we
 * we can access it from other libraries without it being
 * a public instance field on JsObject.
 */
@Deprecated("Internal Use Only")
void setDartHtmlWrapperFor(JsObject object, wrapper) {
  object._dartHtmlWrapper = wrapper;
}

/**
 * Used by callMethod to get the JS object for each argument passed if the
 * argument is a Dart class instance that delegates to a DOM object.  See
 * wrap_jso defined in dart:html.
 */
@Deprecated("Internal Use Only")
unwrap_jso(dartClass_instance) {
  if (dartClass_instance is html.DartHtmlDomObject &&
      dartClass_instance is! JsObject) return dartClass_instance.blink_jsObject;
  else return dartClass_instance;
}

/**
 * Proxies a JavaScript object to Dart.
 *
 * The properties of the JavaScript object are accessible via the `[]` and
 * `[]=` operators. Methods are callable via [callMethod].
 */
class JsObject extends NativeFieldWrapperClass2 {
  JsObject.internal();

  /**
   * If this JsObject is wrapped, e.g. DOM objects, then we can save the
   * wrapper here and preserve its identity.
   */
  var _dartHtmlWrapper;

  /**
   * Constructs a new JavaScript object from [constructor] and returns a proxy
   * to it.
   */
  factory JsObject(JsFunction constructor, [List arguments]) {
    try {
      return html_common.unwrap_jso(_create(constructor, arguments));
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new html.DomException.jsInterop(e);
    }
  }

  static JsObject _create(JsFunction constructor, arguments)
      native "JsObject_constructorCallback";

  _buildArgs(Invocation invocation) {
    if (invocation.namedArguments.isEmpty) {
      return invocation.positionalArguments;
    } else {
      var varArgs = new Map<String, Object>();
      invocation.namedArguments.forEach((symbol, val) {
        varArgs[mirrors.MirrorSystem.getName(symbol)] = val;
      });
      return invocation.positionalArguments.toList()
        ..add(new JsObject.jsify(varArgs));
    }
  }

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

  static JsObject _fromBrowserObject(object) => html_common.unwrap_jso(object);

  /**
   * Returns the value associated with [property] from the proxied JavaScript
   * object.
   *
   * The type of [property] must be either [String] or [num].
   */
  operator [](property) {
    try {
      return _maybeWrap(_operator_getter(property));
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new html.DomException.jsInterop(e);
    }
  }

  _operator_getter(property) native "JsObject_[]";

  /**
   * Sets the value associated with [property] on the proxied JavaScript
   * object.
   *
   * The type of [property] must be either [String] or [num].
   */
  operator []=(property, value) {
    try {
      _operator_setter(property, value);
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new html.DomException.jsInterop(e);
    }
  }

  _operator_setter(property, value) native "JsObject_[]=";

  int get hashCode native "JsObject_hashCode";

  operator ==(other) {
    var is_JsObject = other is JsObject;
    if (!is_JsObject) {
      other = html_common.unwrap_jso(other);
      is_JsObject = other is JsObject;
    }
    return is_JsObject && _identityEquality(this, other);
  }

  static bool _identityEquality(JsObject a, JsObject b)
      native "JsObject_identityEquality";

  /**
   * Returns `true` if the JavaScript object contains the specified property
   * either directly or though its prototype chain.
   *
   * This is the equivalent of the `in` operator in JavaScript.
   */
  bool hasProperty(String property) native "JsObject_hasProperty";

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
  bool instanceof(JsFunction type) native "JsObject_instanceof";

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
      return _maybeWrap(_callMethod(method, args));
    } catch (e) {
      if (hasProperty(method)) {
        // Return a DomException if DOM call returned an error.
        throw new html.DomException.jsInterop(e);
      } else {
        throw new NoSuchMethodError(this, new Symbol(method), args, null);
      }
    }
  }

  noSuchMethod(Invocation invocation) {
    throwError() {
      throw new NoSuchMethodError(this, invocation.memberName,
          invocation.positionalArguments, invocation.namedArguments);
    }

    String name = mirrors.MirrorSystem.getName(invocation.memberName);
    if (invocation.isGetter) {
      if (CHECK_JS_INVOCATIONS) {
        var matches = _allowedGetters[invocation.memberName];
        if (matches == null &&
            !_allowedMethods.containsKey(invocation.memberName)) {
          throwError();
        }
        var ret = this[name];
        if (matches != null && matches._checkReturnType(ret)) return ret;
        if (ret is Function ||
            (ret is JsFunction /* shouldn't be needed in the future*/) &&
                _allowedMethods.containsKey(
                    invocation.memberName)) return ret; // Warning: we have not bound "this"... we could type check on the Function but that is of little value in Dart.
        throwError();
      } else {
        // TODO(jacobr): should we throw if the JavaScript object doesn't have the property?
        return maybeWrapTypedInterop(this._operator_getter(name));
      }
    } else if (invocation.isSetter) {
      if (CHECK_JS_INVOCATIONS) {
        var matches = _allowedSetters[invocation.memberName];
        if (matches == null ||
            !matches.checkInvocation(invocation)) throwError();
      }
      assert(name.endsWith("="));
      name = name.substring(0, name.length - 1);
      return maybeWrapTypedInterop(_operator_setter(
          name, invocation.positionalArguments.first));
    } else {
      // TODO(jacobr): also allow calling getters that look like functions.
      var matches;
      if (CHECK_JS_INVOCATIONS) {
        matches = _allowedMethods[invocation.memberName];
        if (matches == null ||
            !matches.checkInvocation(invocation)) throwError();
      }
      var ret = maybeWrapTypedInterop(this._callMethod(name, _buildArgs(invocation)));
      if (CHECK_JS_INVOCATIONS) {
        if (!matches._checkReturnType(ret)) throwError();
      }
      return ret;
    }
  }

  _callMethod(String name, List args) native "JsObject_callMethod";
}

// JavaScript interop methods that do not automatically wrap to dart:html types.
// Warning: this API is not exposed to dart:js.
@Deprecated("Internal Use Only")
class JsNative {
  static getProperty(o, name) {
    o = unwrap_jso(o);
    return o != null ? o._operator_getter(name) : null;
  }

  static setProperty(o, name, value) {
    return unwrap_jso(o)._operator_setter(name, value);
  }

  static callMethod(o, String method, List args) {
    return unwrap_jso(o)._callMethod(method, args);
  }

  static getArrayIndex(JsArray array, int index) {
    array._checkIndex(index);
    return getProperty(array, index);
  }

  /**
   * Same behavior as new JsFunction.withThis except that JavaScript "this" is not
   * wrapped.
   */
  static JsFunction withThis(Function f) native "JsFunction_withThisNoWrap";
}

/**
 * Proxies a JavaScript Function object.
 */
class JsFunction extends JsObject implements Function {
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
  dynamic apply(List args, {thisArg}) =>
      _maybeWrap(_apply(args, thisArg: thisArg));

  dynamic _apply(List args, {thisArg}) native "JsFunction_apply";

  call([a1 = _UNDEFINED,
        a2 = _UNDEFINED,
        a3 = _UNDEFINED,
        a4 = _UNDEFINED,
        a5 = _UNDEFINED,
        a6 = _UNDEFINED,
        a7 = _UNDEFINED,
        a8 = _UNDEFINED,
        a9 = _UNDEFINED,
        a10 = _UNDEFINED]) {
    return apply(
        _stripUndefinedArgs([a1, a2, a3, a4, a5, a6, a7, a8, a9, a10]));
  }

  noSuchMethod(Invocation invocation) {
    if (invocation.isMethod && invocation.memberName == #call) {
      return apply(_buildArgs(invocation));
    }
    return super.noSuchMethod(invocation);
  }

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

  // Methods overriden for better performance

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

// The allowInterop method is a no-op in Dartium.
// TODO(jacobr): tag methods so we can throw if a Dart method is passed to
// JavaScript using the new interop without calling allowInterop.

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
Function allowInterop(Function f) => f;

Expando<JsFunction> _interopCaptureThisExpando = new Expando<JsFunction>();

/// Returns a [Function] that when called from JavaScript captures its 'this'
/// binding and calls [f] with the value of this passed as the first argument.
/// When called from Dart, [null] will be passed as the first argument.
///
/// See the documention for [allowInterop]. This method should only be used with
/// package:js Dart-JavaScript interop.
Function allowInteropCaptureThis(Function f) {
  if (f is JsFunction) {
    // Behavior when the function is already a JS function is unspecified.
    throw new ArgumentError(
        "Function is already a JS function so cannot capture this.");
    return f;
  } else {
    var ret = _interopCaptureThisExpando[f];
    if (ret == null) {
      ret = new JsFunction.withThis(f);
      _interopCaptureThisExpando[f] = ret;
    }
    return ret;
  }
}
