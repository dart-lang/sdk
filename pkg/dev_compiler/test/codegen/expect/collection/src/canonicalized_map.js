dart_library.library('collection/src/canonicalized_map', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'collection/src/utils',
  'dart/collection'
], /* Lazy imports */[
], function(exports, dart, core, utils, collection) {
  'use strict';
  let dartx = dart.dartx;
  const _base = Symbol('_base');
  const _canonicalize = Symbol('_canonicalize');
  const _isValidKeyFn = Symbol('_isValidKeyFn');
  const _isValidKey = Symbol('_isValidKey');
  const CanonicalizedMap$ = dart.generic(function(C, K, V) {
    class CanonicalizedMap extends core.Object {
      CanonicalizedMap(canonicalize, opts) {
        let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
        this[_base] = core.Map$(C, utils.Pair$(K, V)).new();
        this[_canonicalize] = canonicalize;
        this[_isValidKeyFn] = isValidKey;
      }
      from(other, canonicalize, opts) {
        let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
        this[_base] = core.Map$(C, utils.Pair$(K, V)).new();
        this[_canonicalize] = canonicalize;
        this[_isValidKeyFn] = isValidKey;
        this.addAll(other);
      }
      get(key) {
        if (!dart.notNull(this[_isValidKey](key))) return null;
        let pair = this[_base].get(dart.dcall(this[_canonicalize], key));
        return pair == null ? null : pair.last;
      }
      set(key, value) {
        (() => {
          dart.as(key, K);
          dart.as(value, V);
          if (!dart.notNull(this[_isValidKey](key))) return;
          this[_base].set(dart.as(dart.dcall(this[_canonicalize], key), C), new (utils.Pair$(K, V))(key, value));
        })();
        return value;
      }
      addAll(other) {
        dart.as(other, core.Map$(K, V));
        other.forEach(dart.fn((key, value) => this.set(key, value), V, [K, V]));
      }
      clear() {
        this[_base].clear();
      }
      containsKey(key) {
        if (!dart.notNull(this[_isValidKey](key))) return false;
        return this[_base].containsKey(dart.dcall(this[_canonicalize], key));
      }
      containsValue(value) {
        return this[_base].values[dartx.any](dart.fn(pair => dart.equals(pair.last, value), core.bool, [utils.Pair$(K, V)]));
      }
      forEach(f) {
        dart.as(f, dart.functionType(dart.void, [K, V]));
        this[_base].forEach(dart.fn((key, pair) => f(pair.first, pair.last), dart.void, [C, utils.Pair$(K, V)]));
      }
      get isEmpty() {
        return this[_base].isEmpty;
      }
      get isNotEmpty() {
        return this[_base].isNotEmpty;
      }
      get keys() {
        return this[_base].values[dartx.map](dart.fn(pair => pair.first, K, [utils.Pair$(K, V)]));
      }
      get length() {
        return this[_base].length;
      }
      putIfAbsent(key, ifAbsent) {
        dart.as(key, K);
        dart.as(ifAbsent, dart.functionType(V, []));
        return this[_base].putIfAbsent(dart.as(dart.dcall(this[_canonicalize], key), C), dart.fn(() => new (utils.Pair$(K, V))(key, ifAbsent()), utils.Pair$(K, V), [])).last;
      }
      remove(key) {
        if (!dart.notNull(this[_isValidKey](key))) return null;
        let pair = this[_base].remove(dart.dcall(this[_canonicalize], key));
        return pair == null ? null : pair.last;
      }
      get values() {
        return this[_base].values[dartx.map](dart.fn(pair => pair.last, V, [utils.Pair$(K, V)]));
      }
      toString() {
        return collection.Maps.mapToString(this);
      }
      [_isValidKey](key) {
        return (key == null || dart.is(key, K)) && (this[_isValidKeyFn] == null || dart.notNull(dart.as(dart.dcall(this[_isValidKeyFn], key), core.bool)));
      }
    }
    CanonicalizedMap[dart.implements] = () => [core.Map$(K, V)];
    dart.defineNamedConstructor(CanonicalizedMap, 'from');
    dart.setSignature(CanonicalizedMap, {
      constructors: () => ({
        CanonicalizedMap: [CanonicalizedMap$(C, K, V), [dart.functionType(C, [K])], {isValidKey: dart.functionType(core.bool, [core.Object])}],
        from: [CanonicalizedMap$(C, K, V), [core.Map$(K, V), dart.functionType(C, [K])], {isValidKey: dart.functionType(core.bool, [core.Object])}]
      }),
      methods: () => ({
        get: [V, [core.Object]],
        set: [dart.void, [K, V]],
        addAll: [dart.void, [core.Map$(K, V)]],
        clear: [dart.void, []],
        containsKey: [core.bool, [core.Object]],
        containsValue: [core.bool, [core.Object]],
        forEach: [dart.void, [dart.functionType(dart.void, [K, V])]],
        putIfAbsent: [V, [K, dart.functionType(V, [])]],
        remove: [V, [core.Object]],
        [_isValidKey]: [core.bool, [core.Object]]
      })
    });
    return CanonicalizedMap;
  });
  let CanonicalizedMap = CanonicalizedMap$();
  // Exports:
  exports.CanonicalizedMap$ = CanonicalizedMap$;
  exports.CanonicalizedMap = CanonicalizedMap;
});
