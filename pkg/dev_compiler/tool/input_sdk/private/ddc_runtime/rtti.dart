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

/// Tag a closure with a type, using one of two forms:
///
/// `dart.fn(cls)` marks cls has having no optional or named
/// parameters, with all argument and return types as dynamic.
///
/// `dart.fn(cls, rType, argsT, extras)` marks cls as having the
/// runtime type dart.functionType(rType, argsT, extras).
///
/// Note that since we are producing a type for a concrete function,
/// it is sound to use the definite arrow type.
///
fn(closure, t) {
  if (t == null) {
    // No type arguments, it's all dynamic
    t = fnType(JS('', '#', dynamic),
        JS('', 'Array(#.length).fill(#)', closure, dynamic), JS('', 'void 0'));
  }
  tag(closure, t);
  return closure;
}

lazyFn(closure, computeType) {
  tagLazy(closure, computeType);
  return closure;
}

// TODO(vsm): How should we encode the runtime type?
final _runtimeType = JS('', 'Symbol("_runtimeType")');

final _moduleName = JS('', 'Symbol("_moduleName")');

_checkPrimitiveType(obj) {
  // TODO(jmesserly): JS is used to prevent type literal wrapping.  Is there a
  // better way we can handle this?  (sra: It is super dodgy that the values
  // passed to JS are different to the values passed to a regular function - the
  // semantics are not longer that of calling an interpreter. dart2js has other
  // special functions, we could do the same.)

  // Check for null and undefined
  if (obj == null) return JS('', '#', Null);

  if (JS('bool', 'typeof # == "number"', obj)) {
    if (JS('bool', 'Math.floor(#) == #', obj, obj)) {
      return JS('', '#', int);
    }
    return JS('', '#', double);
  }

  if (JS('bool', 'typeof # == "boolean"', obj)) {
    return JS('', '#', bool);
  }

  if (JS('bool', 'typeof # == "string"', obj)) {
    return JS('', '#', String);
  }

  if (JS('bool', 'typeof # == "symbol"', obj)) {
    // Note: this is a JS Symbol, not a Dart one.
    return JS('', '#', jsobject);
  }

  return null;
}

getFunctionType(obj) {
  // TODO(vsm): Encode this properly on the function for Dart-generated code.
  var args = JS('List', 'Array(#.length).fill(#)', obj, dynamic);
  return fnType(bottom, args, JS('', 'void 0'));
}

/// Returns the runtime representation of the type of obj.
///
/// The resulting object is used internally for runtime type checking. This is
/// different from the user-visible Type object returned by calling
/// `runtimeType` on some Dart object.
getReifiedType(obj) {
  var result = _checkPrimitiveType(obj);
  if (result != null) return result;
  return _nonPrimitiveRuntimeType(obj);
}

_nonPrimitiveRuntimeType(obj) {
  // Lookup recorded *real* type (not user definable runtimeType)
  // TODO(vsm): Should we treat Dart and JS objects differently here?
  // E.g., we can check if obj instanceof core.Object to differentiate.
  var result = _getRuntimeType(obj);
  if (result != null) return result;

  // Lookup extension type
  result = getExtensionType(obj);
  if (result != null) return result;

  // Fallback on constructor for class types
  result = JS('', '#.constructor', obj);
  if (JS('bool', '# === Function', result)) {
    // An undecorated Function should have come from JavaScript.
    // Treat as untyped.
    return JS('', '#', jsobject);
  }
  if (result == null) {
    return JS('', '#', jsobject);
  }
  return result;
}

/// Given an internal runtime type object, wraps it in a `WrappedType` object
/// that implements the dart:core Type interface.
wrapType(type) {
  // If we've already wrapped this type once, use the previous wrapper. This
  // way, multiple references to the same type return an identical Type.
  if (JS('bool', '#.hasOwnProperty(#)', type, _typeObject)) {
    return JS('', '#[#]', type, _typeObject);
  }
  return JS('', '#[#] = #', type, _typeObject, new WrappedType(type));
}

var _lazyJSTypes = JS('', 'new Map()');

lazyJSType(getJSTypeCallback, name) {
  var key = JS('String', '#.toString()', getJSTypeCallback);
  if (JS('bool', '#.has(#)', _lazyJSTypes, key)) {
    return JS('', '#.get(#)', _lazyJSTypes, key);
  }
  var ret = new LazyJSType(getJSTypeCallback, name);
  JS('', '#.set(#, #)', _lazyJSTypes, key, ret);
  return ret;
}

// TODO(jacobr): do not use the same LazyJSType object for anonymous JS types
// from different libraries.
lazyAnonymousJSType(name) {
  if (JS('bool', '#.has(#)', _lazyJSTypes, name)) {
    return JS('', '#.get(#)', _lazyJSTypes, name);
  }
  var ret = new LazyJSType(null, name);
  JS('', '#.set(#, #)', _lazyJSTypes, name, ret);
  return ret;
}

/// Given a WrappedType, return the internal runtime type object.
unwrapType(WrappedType obj) => obj._wrappedType;

_getRuntimeType(value) => JS('', '#[#]', value, _runtimeType);

/// Return the module name for a raw library object.
getModuleName(value) => JS('', '#[#]', value, _moduleName);

/// Tag the runtime type of [value] to be type [t].
void tag(value, t) {
  JS('', '#[#] = #', value, _runtimeType, t);
}

void tagComputed(value, compute) {
  JS('', '#(#, #, { get: # })', defineProperty, value, _runtimeType, compute);
}

void tagLazy(value, compute) {
  JS('', '#(#, #, { get: # })', defineLazyProperty, value, _runtimeType,
      compute);
}

var _loadedModules = JS('', 'new Map()');
var _loadedSourceMaps = JS('', 'new Map()');

List getModuleNames() {
  return JS('', 'Array.from(#.keys())', _loadedModules);
}

String getSourceMap(module) {
  return JS('String', '#.get(#)', _loadedSourceMaps, module);
}

/// Return all library objects in the specified module.
getModuleLibraries(String name) {
  var module = JS('', '#.get(#)', _loadedModules, name);
  if (module == null) return null;
  JS('', '#[#] = #', module, _moduleName, name);
  return module;
}

/// Track all libraries
void trackLibraries(String moduleName, libraries, sourceMap) {
  JS('', '#.set(#, #)', _loadedSourceMaps, moduleName, sourceMap);
  JS('', '#.set(#, #)', _loadedModules, moduleName, libraries);
}
