dart_library.library('collection/src/unmodifiable_wrappers', null, /* Imports */[
  "dart_runtime/dart",
  'dart/collection',
  'dart/core'
], /* Lazy imports */[
  'collection/wrappers'
], function(exports, dart, collection, core, wrappers) {
  'use strict';
  let dartx = dart.dartx;
  dart.export(exports, collection, ['UnmodifiableListView', 'UnmodifiableMapView'], []);
  let NonGrowableListMixin$ = dart.generic(function(E) {
    class NonGrowableListMixin extends core.Object {
      static _throw() {
        dart.throw(new core.UnsupportedError("Cannot change the length of a fixed-length list"));
      }
      set length(newLength) {
        return NonGrowableListMixin$()._throw();
      }
      add(value) {
        dart.as(value, E);
        return dart.as(NonGrowableListMixin$()._throw(), core.bool);
      }
      addAll(iterable) {
        dart.as(iterable, core.Iterable$(E));
        return NonGrowableListMixin$()._throw();
      }
      insert(index, element) {
        dart.as(element, E);
        return NonGrowableListMixin$()._throw();
      }
      insertAll(index, iterable) {
        dart.as(iterable, core.Iterable$(E));
        return NonGrowableListMixin$()._throw();
      }
      remove(value) {
        return dart.as(NonGrowableListMixin$()._throw(), core.bool);
      }
      removeAt(index) {
        return dart.as(NonGrowableListMixin$()._throw(), E);
      }
      removeLast() {
        return dart.as(NonGrowableListMixin$()._throw(), E);
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return NonGrowableListMixin$()._throw();
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return NonGrowableListMixin$()._throw();
      }
      removeRange(start, end) {
        return NonGrowableListMixin$()._throw();
      }
      replaceRange(start, end, iterable) {
        dart.as(iterable, core.Iterable$(E));
        return NonGrowableListMixin$()._throw();
      }
      clear() {
        return NonGrowableListMixin$()._throw();
      }
    }
    NonGrowableListMixin[dart.implements] = () => [core.List$(E)];
    dart.setSignature(NonGrowableListMixin, {
      methods: () => ({
        add: [core.bool, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        insert: [dart.void, [core.int, E]],
        insertAll: [dart.void, [core.int, core.Iterable$(E)]],
        remove: [core.bool, [core.Object]],
        removeAt: [E, [core.int]],
        removeLast: [E, []],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        removeRange: [dart.void, [core.int, core.int]],
        replaceRange: [dart.void, [core.int, core.int, core.Iterable$(E)]],
        clear: [dart.void, []]
      }),
      statics: () => ({_throw: [dart.dynamic, []]}),
      names: ['_throw']
    });
    dart.defineExtensionMembers(NonGrowableListMixin, [
      'add',
      'addAll',
      'insert',
      'insertAll',
      'remove',
      'removeAt',
      'removeLast',
      'removeWhere',
      'retainWhere',
      'removeRange',
      'replaceRange',
      'clear',
      'length'
    ]);
    return NonGrowableListMixin;
  });
  let NonGrowableListMixin = NonGrowableListMixin$();
  let NonGrowableListView$ = dart.generic(function(E) {
    class NonGrowableListView extends dart.mixin(wrappers.DelegatingList$(E), NonGrowableListMixin$(E)) {
      NonGrowableListView(listBase) {
        super.DelegatingList(listBase);
      }
    }
    dart.setSignature(NonGrowableListView, {
      constructors: () => ({NonGrowableListView: [exports.NonGrowableListView$(E), [core.List$(E)]]})
    });
    return NonGrowableListView;
  });
  dart.defineLazyClassGeneric(exports, 'NonGrowableListView', {get: NonGrowableListView$});
  let _throw = Symbol('_throw');
  let UnmodifiableSetMixin$ = dart.generic(function(E) {
    class UnmodifiableSetMixin extends core.Object {
      [_throw]() {
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable Set"));
      }
      add(value) {
        dart.as(value, E);
        return dart.as(this[_throw](), core.bool);
      }
      addAll(elements) {
        dart.as(elements, core.Iterable$(E));
        return this[_throw]();
      }
      remove(value) {
        return dart.as(this[_throw](), core.bool);
      }
      removeAll(elements) {
        return this[_throw]();
      }
      retainAll(elements) {
        return this[_throw]();
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return this[_throw]();
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return this[_throw]();
      }
      clear() {
        return this[_throw]();
      }
    }
    UnmodifiableSetMixin[dart.implements] = () => [core.Set$(E)];
    dart.setSignature(UnmodifiableSetMixin, {
      methods: () => ({
        [_throw]: [dart.dynamic, []],
        add: [core.bool, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        remove: [core.bool, [core.Object]],
        removeAll: [dart.void, [core.Iterable]],
        retainAll: [dart.void, [core.Iterable]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        clear: [dart.void, []]
      })
    });
    return UnmodifiableSetMixin;
  });
  let UnmodifiableSetMixin = UnmodifiableSetMixin$();
  let UnmodifiableSetView$ = dart.generic(function(E) {
    class UnmodifiableSetView extends dart.mixin(wrappers.DelegatingSet$(E), UnmodifiableSetMixin$(E)) {
      UnmodifiableSetView(setBase) {
        super.DelegatingSet(setBase);
      }
    }
    dart.setSignature(UnmodifiableSetView, {
      constructors: () => ({UnmodifiableSetView: [exports.UnmodifiableSetView$(E), [core.Set$(E)]]})
    });
    return UnmodifiableSetView;
  });
  dart.defineLazyClassGeneric(exports, 'UnmodifiableSetView', {get: UnmodifiableSetView$});
  let UnmodifiableMapMixin$ = dart.generic(function(K, V) {
    class UnmodifiableMapMixin extends core.Object {
      static _throw() {
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable Map"));
      }
      set(key, value) {
        (() => {
          dart.as(key, K);
          dart.as(value, V);
          return UnmodifiableMapMixin$()._throw();
        })();
        return value;
      }
      putIfAbsent(key, ifAbsent) {
        dart.as(key, K);
        dart.as(ifAbsent, dart.functionType(V, []));
        return dart.as(UnmodifiableMapMixin$()._throw(), V);
      }
      addAll(other) {
        dart.as(other, core.Map$(K, V));
        return UnmodifiableMapMixin$()._throw();
      }
      remove(key) {
        return dart.as(UnmodifiableMapMixin$()._throw(), V);
      }
      clear() {
        return UnmodifiableMapMixin$()._throw();
      }
    }
    UnmodifiableMapMixin[dart.implements] = () => [core.Map$(K, V)];
    dart.setSignature(UnmodifiableMapMixin, {
      methods: () => ({
        set: [dart.void, [K, V]],
        putIfAbsent: [V, [K, dart.functionType(V, [])]],
        addAll: [dart.void, [core.Map$(K, V)]],
        remove: [V, [core.Object]],
        clear: [dart.void, []]
      }),
      statics: () => ({_throw: [dart.dynamic, []]}),
      names: ['_throw']
    });
    return UnmodifiableMapMixin;
  });
  let UnmodifiableMapMixin = UnmodifiableMapMixin$();
  // Exports:
  exports.NonGrowableListMixin$ = NonGrowableListMixin$;
  exports.NonGrowableListMixin = NonGrowableListMixin;
  exports.NonGrowableListView$ = NonGrowableListView$;
  exports.UnmodifiableSetMixin$ = UnmodifiableSetMixin$;
  exports.UnmodifiableSetMixin = UnmodifiableSetMixin;
  exports.UnmodifiableSetView$ = UnmodifiableSetView$;
  exports.UnmodifiableMapMixin$ = UnmodifiableMapMixin$;
  exports.UnmodifiableMapMixin = UnmodifiableMapMixin;
});
