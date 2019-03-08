// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines the association between runtime objects and
/// runtime types.
part of dart._runtime;

/// Runtime type information.  This module defines the mapping from
/// runtime objects to their runtime type information.  See the types
/// module for the definition of how type information is represented.
///
/// There are two kinds of objects that represent "types" at runtime. A
/// "runtime type" contains all of the data needed to implement the runtime
/// type checking inserted by the compiler. These objects fall into four
/// categories:
///
///   - Things represented by javascript primitives, such as
///     null, numbers, booleans, strings, and symbols.  For these
///     we map directly from the javascript type (given by typeof)
///     to the appropriate class type from core, which serves as their
///     rtti.
///
///   - Functions, which are represented by javascript functions.
///     Representations of Dart functions always have a
///     _runtimeType property attached to them with the appropriate
///     rtti.
///
///   - Objects (instances) which are represented by instances of
///     javascript (ES6) classes.  Their types are given by their
///     classes, and the rtti is accessed by projecting out their
///     constructor field.
///
///   - Types objects, which are represented as described in the types
///     module.  Types always have a _runtimeType property attached to
///     them with the appropriate rtti.  The rtti for these is always
///     core.Type.  TODO(leafp): consider the possibility that we can
///     reliably recognize type objects and map directly to core.Type
///     rather than attaching this property everywhere.
///
/// The other kind of object representing a "type" is the instances of the
/// dart:core Type class. These are the user visible objects you get by calling
/// "runtimeType" on an object or using a class literal expression. These are
/// different from the above objects, and are created by calling `wrapType()`
/// on a runtime type.

/// Tag a closure with a type.
///
/// `dart.fn(closure, type)` marks [closure] with the provided runtime [type].
fn(closure, type) {
  JS('', '#[#] = #', closure, _runtimeType, type);
  return closure;
}

/// Tag a closure with a type that's computed lazily.
///
/// `dart.fn(closure, type)` marks [closure] with a getter that uses
/// [computeType] to return the runtime type.
///
/// The getter/setter replaces the property with a value property, so the
/// resulting function is compatible with [fn] and the type can be set again
/// safely.
lazyFn(closure, Object Function() computeType) {
  defineAccessor(closure, _runtimeType,
      get: () => defineValue(closure, _runtimeType, computeType()),
      set: (value) => defineValue(closure, _runtimeType, value),
      configurable: true);
  return closure;
}

// TODO(vsm): How should we encode the runtime type?
final _runtimeType = JS('', 'Symbol("_runtimeType")');

final _moduleName = JS('', 'Symbol("_moduleName")');

getFunctionType(obj) {
  // TODO(vsm): Encode this properly on the function for Dart-generated code.
  var args = JS<List>('!', 'Array(#.length).fill(#)', obj, dynamic);
  return fnType(bottom, args, JS('', 'void 0'));
}

/// Returns the runtime representation of the type of obj.
///
/// The resulting object is used internally for runtime type checking. This is
/// different from the user-visible Type object returned by calling
/// `runtimeType` on some Dart object.
getReifiedType(obj) {
  switch (JS<String>('!', 'typeof #', obj)) {
    case "object":
      if (obj == null) return JS('', '#', Null);
      if (JS('!', '# instanceof #', obj, Object)) {
        return JS('', '#.constructor', obj);
      }
      var result = JS('', '#[#]', obj, _extensionType);
      if (result == null) return JS('', '#', jsobject);
      return result;
    case "function":
      // All Dart functions and callable classes must set _runtimeType
      var result = JS('', '#[#]', obj, _runtimeType);
      if (result != null) return result;
      return JS('', '#', jsobject);
    case "undefined":
      return JS('', '#', Null);
    case "number":
      return JS('', 'Math.floor(#) == # ? # : #', obj, obj, int, double);
    case "boolean":
      return JS('', '#', bool);
    case "string":
      return JS('', '#', String);
    case "symbol":
    default:
      return JS('', '#', jsobject);
  }
}

/// Return the module name for a raw library object.
String getModuleName(Object module) => JS('', '#[#]', module, _moduleName);

final _loadedModules = JS('', 'new Map()');
final _loadedSourceMaps = JS('', 'new Map()');

List<String> getModuleNames() {
  return JSArray<String>.of(JS('', 'Array.from(#.keys())', _loadedModules));
}

String getSourceMap(String moduleName) {
  return JS('!', '#.get(#)', _loadedSourceMaps, moduleName);
}

/// Return all library objects in the specified module.
getModuleLibraries(String name) {
  var module = JS('', '#.get(#)', _loadedModules, name);
  if (module == null) return null;
  JS('', '#[#] = #', module, _moduleName, name);
  return module;
}

/// Track all libraries
void trackLibraries(String moduleName, Object libraries, String sourceMap) {
  JS('', '#.set(#, #)', _loadedSourceMaps, moduleName, sourceMap);
  JS('', '#.set(#, #)', _loadedModules, moduleName, libraries);
}

List<String> _libraries;

/// Returns a JSArray of library uris (e.g,
/// ['dart:core', 'dart:_internal', ..., 'package:foo/bar.dart', ... 'main.dart'])
/// loaded in this application.
List<String> getLibraries() {
  if (_libraries == null) {
    _libraries = [];
    var modules = getModuleNames();
    for (var name in modules) {
      var module = getModuleLibraries(name);
      List props = getOwnPropertyNames(module);
      _libraries.addAll(props.whereType());
    }
  }
  return _libraries;
}
