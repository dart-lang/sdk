// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/* This library defines the representation of runtime types.
*/

dart_library.library('dart/_types', null, /* Imports */[
], /* Lazy Imports */[
  'dart/_utils',
  'dart/core',
  'dart/_classes',
  'dart/_rtti'
], function(exports, dart_utils, core, classes, rtti) {
  'use strict';

  const getOwnPropertyNames = Object.getOwnPropertyNames;

  const assert = dart_utils.assert_;

  /**
   * Types in dart are represented at runtime as follows.
   *   - Normal nominal types, produced from classes, are represented
   *     at runtime by the JS class of which they are an instance.
   *     If the type is the result of instantiating a generic class,
   *     then the "classes" module manages the association between the
   *     instantiated class and the original class declaration
   *     and the type arguments with which it was instantiated.  This
   *     assocation can be queried via the "classes" module".
   *
   *   - All other types are represented as instances of class TypeRep,
   *     defined in this module.
   *     - Dynamic, Void, and Bottom are singleton instances of sentinal
   *       classes.
   *     - Function types are instances of subclasses of AbstractFunctionType.
   *
   * Function types are represented in one of two ways:
   *   - As an instance of FunctionType.  These are eagerly computed.
   *   - As an instance of TypeDef.  The TypeDef representation lazily
   *     computes an instance of FunctionType, and delegates to that instance.
   *
   * All types satisfy the following interface:
   *  get String name;
   *  String toString();
   *
   */
  class TypeRep extends rtti.LazyTagged(() => core.Type) {
    get name() {return this.toString();}
  }

  class Dynamic extends TypeRep {
    toString() { return "dynamic"; }
  }
  let dynamicR = new Dynamic();
  exports.dynamic = dynamicR;

  class Void extends TypeRep {
    toString() { return "void"; }
  }

  let voidR = new Void();
  exports.void = voidR;

  class Bottom extends TypeRep {
    toString() { return "bottom"; }
  }
  let bottomR = new Bottom();
  exports.bottom = bottomR;

  class JSObject extends TypeRep {
    toString() { return "NativeJavaScriptObject"; }
  }
  let jsobjectR = new JSObject();
  exports.jsobject = jsobjectR;

  class AbstractFunctionType extends TypeRep {
    constructor() {
      super();
      this._stringValue = null;
    }

    toString() { return this.name; }

    get name() {
      if (this._stringValue) return this._stringValue;

      let buffer = '(';
      for (let i = 0; i < this.args.length; ++i) {
        if (i > 0) {
          buffer += ', ';
        }
        buffer += typeName(this.args[i]);
      }
      if (this.optionals.length > 0) {
        if (this.args.length > 0) buffer += ', ';
        buffer += '[';
        for (let i = 0; i < this.optionals.length; ++i) {
          if (i > 0) {
            buffer += ', ';
          }
          buffer += typeName(this.optionals[i]);
        }
        buffer += ']';
      } else if (Object.keys(this.named).length > 0) {
        if (this.args.length > 0) buffer += ', ';
        buffer += '{';
        let names = getOwnPropertyNames(this.named).sort();
        for (let i = 0; i < names.length; ++i) {
          if (i > 0) {
            buffer += ', ';
          }
          buffer += names[i] + ': ' + typeName(this.named[names[i]]);
        }
        buffer += '}';
      }

      buffer += ') -> ' + typeName(this.returnType);
      this._stringValue = buffer;
      return buffer;
    }
  }

  class FunctionType extends AbstractFunctionType {
    /**
     * Construct a function type. There are two arrow constructors,
     * distinguished by the "definite" flag.
     *
     * The fuzzy arrow (definite is false) treats any arguments
     * of type dynamic as having type bottom, and will always be
     * called with a dynamic invoke.
     *
     * The definite arrow (definite is true) leaves arguments unchanged.
     *
     * We eagerly canonize the argument types to avoid having to deal with
     * this logic in multiple places.
     *
     * TODO(leafp): Figure out how to present this to the user.  How
     * should these be printed out?
     */
    constructor(definite, returnType, args, optionals, named) {
      super();
      this.definite = definite;
      this.returnType = returnType;
      this.args = args;
      this.optionals = optionals;
      this.named = named;

      // TODO(vsm): This is just parameter metadata for now.
      this.metadata = [];
      function process(array, metadata) {
        var result = [];
        for (var i = 0; i < array.length; ++i) {
          var arg = array[i];
          if (arg instanceof Array) {
            metadata.push(arg.slice(1));
            result.push(arg[0]);
          } else {
            metadata.push([]);
            result.push(arg);
          }
        }
        return result;
      }
      this.args = process(this.args, this.metadata);
      this.optionals = process(this.optionals, this.metadata);
      // TODO(vsm): Add named arguments.
      this._canonize();
    }
    _canonize() {
      if (this.definite) return;

      function replace(a) {
        return (a == dynamicR) ? bottomR : a;
      }

      this.args = this.args.map(replace);

      if (this.optionals.length > 0) {
        this.optionals = this.optionals.map(replace);
      }

      if (Object.keys(this.named).length > 0) {
        let r = {};
        for (let name of getOwnPropertyNames(this.named)) {
          r[name] = replace(this.named[name]);
        }
        this.named = r;
      }
    }
  }

  class Typedef extends AbstractFunctionType {
    constructor(name, closure) {
      super();
      this._name = name;
      this._closure = closure;
      this._functionType = null;
    }

    get definite() {
      return this._functionType.definite;
    }

    get name() {
      return this._name;
    }

    get functionType() {
      if (!this._functionType) {
        this._functionType = this._closure();
      }
      return this._functionType;
    }

    get returnType() {
      return this.functionType.returnType;
    }

    get args() {
      return this.functionType.args;
    }

    get optionals() {
      return this.functionType.optionals;
    }

    get named() {
      return this.functionType.named;
    }

    get metadata() {
      return this.functionType.metadata;
    }
  }

  function _functionType(definite, returnType, args, extra) {
    // TODO(vsm): Cache / memomize?
    let optionals;
    let named;
    if (extra === void 0) {
      optionals = [];
      named = {};
    } else if (extra instanceof Array) {
      optionals = extra;
      named = {};
    } else {
      optionals = [];
      named = extra;
    }
    return new FunctionType(definite, returnType, args, optionals, named);
  }

  /**
   * Create a "fuzzy" function type.  If any arguments are dynamic
   * they will be replaced with bottom.
   */
  function functionType(returnType, args, extra) {
    return _functionType(false, returnType, args, extra);
  }
  exports.functionType = functionType;

  /**
   * Create a definite function type. No substitution of dynamic for
   * bottom occurs.
   */
  function definiteFunctionType(returnType, args, extra) {
    return _functionType(true, returnType, args, extra);
  }
  exports.definiteFunctionType = definiteFunctionType;

  function typedef(name, closure) {
    return new Typedef(name, closure);
  }
  exports.typedef = typedef;

  function isDartType(type) {
    return rtti.read(type) === core.Type;
  }
  exports.isDartType = isDartType;

  function typeName(type) {
    // Non-instance types
    if (type instanceof TypeRep) return type.toString();
    // Instance types
    let tag = rtti.read(type);
    if (tag === core.Type) {
      let name = type.name;
      let args = classes.getGenericArgs(type);
      if (args) {
        name += '<';
        for (let i = 0; i < args.length; ++i) {
          if (i > 0) name += ', ';
          name += typeName(args[i]);
        }
        name += '>';
      }
      return name;
    }
    if (tag) return "Not a type: " + tag.name;
    return "JSObject<" + type.name + ">";
  }
  exports.typeName = typeName;

  function isFunctionType(type) {
    return type instanceof AbstractFunctionType || type == core.Function;
  }

  function isFunctionSubType(ft1, ft2) {
    if (ft2 == core.Function) {
      return true;
    }

    let ret1 = ft1.returnType;
    let ret2 = ft2.returnType;

    if (!isSubtype_(ret1, ret2)) {
      // Covariant return types
      // Note, void (which can only appear as a return type) is effectively
      // treated as dynamic.  If the base return type is void, we allow any
      // subtype return type.
      // E.g., we allow:
      //   () -> int <: () -> void
      if (ret2 != voidR) {
        return false;
      }
    }

    let args1 = ft1.args;
    let args2 = ft2.args;

    if (args1.length > args2.length) {
      return false;
    }

    for (let i = 0; i < args1.length; ++i) {
      if (!isSubtype_(args2[i], args1[i])) {
        return false;
      }
    }

    let optionals1 = ft1.optionals;
    let optionals2 = ft2.optionals;

    if (args1.length + optionals1.length < args2.length + optionals2.length) {
      return false;
    }

    let j = 0;
    for (let i = args1.length; i < args2.length; ++i, ++j) {
      if (!isSubtype_(args2[i], optionals1[j])) {
        return false;
      }
    }

    for (let i = 0; i < optionals2.length; ++i, ++j) {
      if (!isSubtype_(optionals2[i], optionals1[j])) {
        return false;
      }
    }

    let named1 = ft1.named;
    let named2 = ft2.named;

    let names = getOwnPropertyNames(named2);
    for (let i = 0; i < names.length; ++i) {
      let name = names[i];
      let n1 = named1[name];
      let n2 = named2[name];
      if (n1 === void 0) {
        return false;
      }
      if (!isSubtype_(n2, n1)) {
        return false;
      }
    }

    return true;
  }

  /**
   * Computes the canonical type.
   * This maps JS types onto their corresponding Dart Type.
   */
  // TODO(jmesserly): lots more needs to be done here.
  function canonicalType(t) {
    if (t === Object) return core.Object;
    if (t === Function) return core.Function;
    if (t === Array) return core.List;

    // We shouldn't normally get here with these types, unless something strange
    // happens like subclassing Number in JS and passing it to Dart.
    if (t === String) return core.String;
    if (t === Number) return core.double;
    if (t === Boolean) return core.bool;
    return t;
  }

  const subtypeMap = new Map();
  function isSubtype(t1, t2) {
    // See if we already know the answer
    // TODO(jmesserly): general purpose memoize function?
    let map = subtypeMap.get(t1);
    let result;
    if (map) {
      result = map.get(t2);
      if (result !== void 0) return result;
    } else {
      subtypeMap.set(t1, map = new Map());
    }
    result = isSubtype_(t1, t2)
    map.set(t2, result);
    return result;
  }
  exports.isSubtype = isSubtype;

  function _isBottom(type) {
    return type == bottomR;
  }

  function _isTop(type) {
    return type == core.Object || (type == dynamicR);
  }

  function isSubtype_(t1, t2) {
    t1 = canonicalType(t1);
    t2 = canonicalType(t2);
    if (t1 == t2) return true;

    // Trivially true.
    if (_isTop(t2) || _isBottom(t1)) {
      return true;
    }

    // Trivially false.
    if (_isTop(t1) || _isBottom(t2)) {
      return false;
    }

    // "Traditional" name-based subtype check.
    if (isClassSubType(t1, t2)) {
      return true;
    }

    // Function subtyping.
    // TODO(vsm): Handle Objects with call methods.  Those are functions
    // even if they do not *nominally* subtype core.Function.
    if (isFunctionType(t1) &&
        isFunctionType(t2)) {
      return isFunctionSubType(t1, t2);
    }
    return false;
  }

  function isClassSubType(t1, t2) {
    // We support Dart's covariant generics with the caveat that we do not
    // substitute bottom for dynamic in subtyping rules.
    // I.e., given T1, ..., Tn where at least one Ti != dynamic we disallow:
    // - S !<: S<T1, ..., Tn>
    // - S<dynamic, ..., dynamic> !<: S<T1, ..., Tn>
    t1 = canonicalType(t1);
    assert(t2 == canonicalType(t2));
    if (t1 == t2) return true;

    if (t1 == core.Object) return false;

    // If t1 is a JS Object, we may not hit core.Object.
    if (t1 == null) return t2 == core.Object || t2 == dynamicR;

    // Check if t1 and t2 have the same raw type.  If so, check covariance on
    // type parameters.
    let raw1 = classes.getGenericClass(t1);
    let raw2 = classes.getGenericClass(t2);
    if (raw1 != null && raw1 == raw2) {
      let typeArguments1 = classes.getGenericArgs(t1);
      let typeArguments2 = classes.getGenericArgs(t2);
      let length = typeArguments1.length;
      if (typeArguments2.length == 0) {
        // t2 is the raw form of t1
        return true;
      } else if (length == 0) {
        // t1 is raw, but t2 is not
        return false;
      }
      assert(length == typeArguments2.length);
      for (let i = 0; i < length; ++i) {
        if (!isSubtype(typeArguments1[i], typeArguments2[i])) {
          return false;
        }
      }
      return true;
    }

    // Check superclass.
    if (isClassSubType(t1.__proto__, t2)) return true;

    // Check mixins.
    let mixins = classes.getMixins(t1);
    if (mixins) {
      for (let m1 of mixins) {
        // TODO(jmesserly): remove the != null check once we can load core libs.
        if (m1 != null && isClassSubType(m1, t2)) return true;
      }
    }

    // Check interfaces.
    let getInterfaces = classes.getImplements(t1);
    if (getInterfaces) {
      for (let i1 of getInterfaces()) {
        // TODO(jmesserly): remove the != null check once we can load core libs.
        if (i1 != null && isClassSubType(i1, t2)) return true;
      }
    }

    return false;
  }

  // TODO(jmesserly): this isn't currently used, but it could be if we want
  // `obj is NonGroundType<T,S>` to be rejected at runtime instead of compile
  // time.
  function isGroundType(type) {
    // TODO(vsm): Cache this if we start using it at runtime.

    if (type instanceof AbstractFunctionType) {
      if (!_isTop(type.returnType)) return false;
      for (let i = 0; i < type.args.length; ++i) {
        if (!_isBottom(type.args[i])) return false;
      }
      for (let i = 0; i < type.optionals.length; ++i) {
        if (!_isBottom(type.optionals[i])) return false;
      }
      let names = getOwnPropertyNames(type.named);
      for (let i = 0; i < names.length; ++i) {
        if (!_isBottom(type.named[names[i]])) return false;
      }
      return true;
    }

    let typeArgs = classes.getGenericArgs(type);
    if (!typeArgs) return true;
    for (let t of typeArgs) {
      if (t != core.Object && t != dynamicR) return false;
    }
    return true;
  }
  exports.isGroundType = isGroundType;

});
