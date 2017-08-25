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
  switch (JS('String', 'typeof #', obj)) {
    case "object":
      if (obj == null) return JS('', '#', Null);
      if (JS('bool', '# instanceof #', obj, Object)) {
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

/// Given an internal runtime type object, wraps it in a `WrappedType` object
/// that implements the dart:core Type interface.
Type wrapType(type) {
  // If we've already wrapped this type once, use the previous wrapper. This
  // way, multiple references to the same type return an identical Type.
  if (JS('bool', '#.hasOwnProperty(#)', type, _typeObject)) {
    return JS('', '#[#]', type, _typeObject);
  }
  return JS('Type', '#[#] = #', type, _typeObject, new WrappedType(type));
}

/// Given a WrappedType, return the internal runtime type object.
unwrapType(WrappedType obj) => obj._wrappedType;

/// Assumes that value is non-null
_getRuntimeType(value) => JS('', '#[#]', value, _runtimeType);

/// Return the module name for a raw library object.
getModuleName(value) => JS('', '#[#]', value, _moduleName);

/// Tag the runtime type of [value] to be type [t].
void tag(value, t) {
  JS('', '#[#] = #', value, _runtimeType, t);
}

void tagComputed(value, compute) {
  defineGetter(value, _runtimeType, compute);
}

void tagLazy(value, compute) {
  defineMemoizedGetter(value, _runtimeType, compute);
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
