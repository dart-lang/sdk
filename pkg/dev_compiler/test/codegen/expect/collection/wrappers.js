dart_library.library('collection/wrappers', null, /* Imports */[
  "dart_runtime/dart",
  'collection/src/canonicalized_map',
  'dart/core',
  'dart/math',
  'dart/collection'
], /* Lazy imports */[
  'collection/src/unmodifiable_wrappers'
], function(exports, dart, canonicalized_map, core, math, collection, unmodifiable_wrappers) {
  'use strict';
  let dartx = dart.dartx;
  dart.export(exports, canonicalized_map);
  dart.export(exports, unmodifiable_wrappers);
  let _base = Symbol('_base');
  let _DelegatingIterableBase$ = dart.generic(function(E) {
    class _DelegatingIterableBase extends core.Object {
      _DelegatingIterableBase() {
      }
      any(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return this[_base][dartx.any](test);
      }
      contains(element) {
        return this[_base][dartx.contains](element);
      }
      elementAt(index) {
        return this[_base][dartx.elementAt](index);
      }
      every(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return this[_base][dartx.every](test);
      }
      expand(f) {
        dart.as(f, dart.functionType(core.Iterable, [E]));
        return this[_base][dartx.expand](f);
      }
      get first() {
        return this[_base][dartx.first];
      }
      firstWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        return this[_base][dartx.firstWhere](test, {orElse: orElse});
      }
      fold(initialValue, combine) {
        dart.as(combine, dart.functionType(dart.dynamic, [dart.dynamic, E]));
        return this[_base][dartx.fold](initialValue, combine);
      }
      forEach(f) {
        dart.as(f, dart.functionType(dart.void, [E]));
        return this[_base][dartx.forEach](f);
      }
      get isEmpty() {
        return this[_base][dartx.isEmpty];
      }
      get isNotEmpty() {
        return this[_base][dartx.isNotEmpty];
      }
      get iterator() {
        return this[_base][dartx.iterator];
      }
      [Symbol.iterator]() {
        return new dart.JsIterator(this.iterator);
      }
      join(separator) {
        if (separator === void 0)
          separator = "";
        return this[_base][dartx.join](separator);
      }
      get last() {
        return this[_base][dartx.last];
      }
      lastWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        return this[_base][dartx.lastWhere](test, {orElse: orElse});
      }
      get length() {
        return this[_base][dartx.length];
      }
      map(f) {
        dart.as(f, dart.functionType(dart.dynamic, [E]));
        return this[_base][dartx.map](f);
      }
      reduce(combine) {
        dart.as(combine, dart.functionType(E, [E, E]));
        return this[_base][dartx.reduce](combine);
      }
      get single() {
        return this[_base][dartx.single];
      }
      singleWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return this[_base][dartx.singleWhere](test);
      }
      skip(n) {
        return this[_base][dartx.skip](n);
      }
      skipWhile(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return this[_base][dartx.skipWhile](test);
      }
      take(n) {
        return this[_base][dartx.take](n);
      }
      takeWhile(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return this[_base][dartx.takeWhile](test);
      }
      toList(opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        return this[_base][dartx.toList]({growable: growable});
      }
      toSet() {
        return this[_base][dartx.toSet]();
      }
      where(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return this[_base][dartx.where](test);
      }
      toString() {
        return dart.toString(this[_base]);
      }
    }
    _DelegatingIterableBase[dart.implements] = () => [core.Iterable$(E)];
    dart.setSignature(_DelegatingIterableBase, {
      constructors: () => ({_DelegatingIterableBase: [_DelegatingIterableBase$(E), []]}),
      methods: () => ({
        any: [core.bool, [dart.functionType(core.bool, [E])]],
        contains: [core.bool, [core.Object]],
        elementAt: [E, [core.int]],
        every: [core.bool, [dart.functionType(core.bool, [E])]],
        expand: [core.Iterable, [dart.functionType(core.Iterable, [E])]],
        firstWhere: [E, [dart.functionType(core.bool, [E])], {orElse: dart.functionType(E, [])}],
        fold: [dart.dynamic, [dart.dynamic, dart.functionType(dart.dynamic, [dart.dynamic, E])]],
        forEach: [dart.void, [dart.functionType(dart.void, [E])]],
        join: [core.String, [], [core.String]],
        lastWhere: [E, [dart.functionType(core.bool, [E])], {orElse: dart.functionType(E, [])}],
        map: [core.Iterable, [dart.functionType(dart.dynamic, [E])]],
        reduce: [E, [dart.functionType(E, [E, E])]],
        singleWhere: [E, [dart.functionType(core.bool, [E])]],
        skip: [core.Iterable$(E), [core.int]],
        skipWhile: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        take: [core.Iterable$(E), [core.int]],
        takeWhile: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        toList: [core.List$(E), [], {growable: core.bool}],
        toSet: [core.Set$(E), []],
        where: [core.Iterable$(E), [dart.functionType(core.bool, [E])]]
      })
    });
    dart.defineExtensionMembers(_DelegatingIterableBase, [
      'any',
      'contains',
      'elementAt',
      'every',
      'expand',
      'firstWhere',
      'fold',
      'forEach',
      'join',
      'lastWhere',
      'map',
      'reduce',
      'singleWhere',
      'skip',
      'skipWhile',
      'take',
      'takeWhile',
      'toList',
      'toSet',
      'where',
      'toString',
      'first',
      'isEmpty',
      'isNotEmpty',
      'iterator',
      'last',
      'length',
      'single'
    ]);
    return _DelegatingIterableBase;
  });
  let _DelegatingIterableBase = _DelegatingIterableBase$();
  let DelegatingIterable$ = dart.generic(function(E) {
    class DelegatingIterable extends _DelegatingIterableBase$(E) {
      DelegatingIterable(base) {
        this[_base] = base;
        super._DelegatingIterableBase();
      }
    }
    dart.setSignature(DelegatingIterable, {
      constructors: () => ({DelegatingIterable: [DelegatingIterable$(E), [core.Iterable$(E)]]})
    });
    return DelegatingIterable;
  });
  let DelegatingIterable = DelegatingIterable$();
  let _listBase = Symbol('_listBase');
  let DelegatingList$ = dart.generic(function(E) {
    class DelegatingList extends DelegatingIterable$(E) {
      DelegatingList(base) {
        super.DelegatingIterable(base);
      }
      get [_listBase]() {
        return dart.as(this[_base], core.List$(E));
      }
      get(index) {
        return this[_listBase][dartx.get](index);
      }
      set(index, value) {
        dart.as(value, E);
        this[_listBase][dartx.set](index, value);
        return value;
      }
      add(value) {
        dart.as(value, E);
        this[_listBase][dartx.add](value);
      }
      addAll(iterable) {
        dart.as(iterable, core.Iterable$(E));
        this[_listBase][dartx.addAll](iterable);
      }
      asMap() {
        return this[_listBase][dartx.asMap]();
      }
      clear() {
        this[_listBase][dartx.clear]();
      }
      fillRange(start, end, fillValue) {
        if (fillValue === void 0)
          fillValue = null;
        dart.as(fillValue, E);
        this[_listBase][dartx.fillRange](start, end, fillValue);
      }
      getRange(start, end) {
        return this[_listBase][dartx.getRange](start, end);
      }
      indexOf(element, start) {
        dart.as(element, E);
        if (start === void 0)
          start = 0;
        return this[_listBase][dartx.indexOf](element, start);
      }
      insert(index, element) {
        dart.as(element, E);
        this[_listBase][dartx.insert](index, element);
      }
      insertAll(index, iterable) {
        dart.as(iterable, core.Iterable$(E));
        this[_listBase][dartx.insertAll](index, iterable);
      }
      lastIndexOf(element, start) {
        dart.as(element, E);
        if (start === void 0)
          start = null;
        return this[_listBase][dartx.lastIndexOf](element, start);
      }
      set length(newLength) {
        this[_listBase][dartx.length] = newLength;
      }
      remove(value) {
        return this[_listBase][dartx.remove](value);
      }
      removeAt(index) {
        return this[_listBase][dartx.removeAt](index);
      }
      removeLast() {
        return this[_listBase][dartx.removeLast]();
      }
      removeRange(start, end) {
        this[_listBase][dartx.removeRange](start, end);
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_listBase][dartx.removeWhere](test);
      }
      replaceRange(start, end, iterable) {
        dart.as(iterable, core.Iterable$(E));
        this[_listBase][dartx.replaceRange](start, end, iterable);
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_listBase][dartx.retainWhere](test);
      }
      get reversed() {
        return this[_listBase][dartx.reversed];
      }
      setAll(index, iterable) {
        dart.as(iterable, core.Iterable$(E));
        this[_listBase][dartx.setAll](index, iterable);
      }
      setRange(start, end, iterable, skipCount) {
        dart.as(iterable, core.Iterable$(E));
        if (skipCount === void 0)
          skipCount = 0;
        this[_listBase][dartx.setRange](start, end, iterable, skipCount);
      }
      shuffle(random) {
        if (random === void 0)
          random = null;
        this[_listBase][dartx.shuffle](random);
      }
      sort(compare) {
        if (compare === void 0)
          compare = null;
        dart.as(compare, dart.functionType(core.int, [E, E]));
        this[_listBase][dartx.sort](compare);
      }
      sublist(start, end) {
        if (end === void 0)
          end = null;
        return this[_listBase][dartx.sublist](start, end);
      }
    }
    DelegatingList[dart.implements] = () => [core.List$(E)];
    dart.setSignature(DelegatingList, {
      constructors: () => ({DelegatingList: [DelegatingList$(E), [core.List$(E)]]}),
      methods: () => ({
        get: [E, [core.int]],
        set: [dart.void, [core.int, E]],
        add: [dart.void, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        asMap: [core.Map$(core.int, E), []],
        clear: [dart.void, []],
        fillRange: [dart.void, [core.int, core.int], [E]],
        getRange: [core.Iterable$(E), [core.int, core.int]],
        indexOf: [core.int, [E], [core.int]],
        insert: [dart.void, [core.int, E]],
        insertAll: [dart.void, [core.int, core.Iterable$(E)]],
        lastIndexOf: [core.int, [E], [core.int]],
        remove: [core.bool, [core.Object]],
        removeAt: [E, [core.int]],
        removeLast: [E, []],
        removeRange: [dart.void, [core.int, core.int]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        replaceRange: [dart.void, [core.int, core.int, core.Iterable$(E)]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        setAll: [dart.void, [core.int, core.Iterable$(E)]],
        setRange: [dart.void, [core.int, core.int, core.Iterable$(E)], [core.int]],
        shuffle: [dart.void, [], [math.Random]],
        sort: [dart.void, [], [dart.functionType(core.int, [E, E])]],
        sublist: [core.List$(E), [core.int], [core.int]]
      })
    });
    dart.defineExtensionMembers(DelegatingList, [
      'get',
      'set',
      'add',
      'addAll',
      'asMap',
      'clear',
      'fillRange',
      'getRange',
      'indexOf',
      'insert',
      'insertAll',
      'lastIndexOf',
      'remove',
      'removeAt',
      'removeLast',
      'removeRange',
      'removeWhere',
      'replaceRange',
      'retainWhere',
      'setAll',
      'setRange',
      'shuffle',
      'sort',
      'sublist',
      'length',
      'reversed'
    ]);
    return DelegatingList;
  });
  let DelegatingList = DelegatingList$();
  let _setBase = Symbol('_setBase');
  let DelegatingSet$ = dart.generic(function(E) {
    class DelegatingSet extends DelegatingIterable$(E) {
      DelegatingSet(base) {
        super.DelegatingIterable(base);
      }
      get [_setBase]() {
        return dart.as(this[_base], core.Set$(E));
      }
      add(value) {
        dart.as(value, E);
        return this[_setBase].add(value);
      }
      addAll(elements) {
        dart.as(elements, core.Iterable$(E));
        this[_setBase].addAll(elements);
      }
      clear() {
        this[_setBase].clear();
      }
      containsAll(other) {
        return this[_setBase].containsAll(other);
      }
      difference(other) {
        dart.as(other, core.Set$(E));
        return this[_setBase].difference(other);
      }
      intersection(other) {
        return this[_setBase].intersection(other);
      }
      lookup(element) {
        return this[_setBase].lookup(element);
      }
      remove(value) {
        return this[_setBase].remove(value);
      }
      removeAll(elements) {
        this[_setBase].removeAll(elements);
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_setBase].removeWhere(test);
      }
      retainAll(elements) {
        this[_setBase].retainAll(elements);
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_setBase].retainWhere(test);
      }
      union(other) {
        dart.as(other, core.Set$(E));
        return this[_setBase].union(other);
      }
      toSet() {
        return new (DelegatingSet$(E))(this[_setBase].toSet());
      }
    }
    DelegatingSet[dart.implements] = () => [core.Set$(E)];
    dart.setSignature(DelegatingSet, {
      constructors: () => ({DelegatingSet: [DelegatingSet$(E), [core.Set$(E)]]}),
      methods: () => ({
        add: [core.bool, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        clear: [dart.void, []],
        containsAll: [core.bool, [core.Iterable$(core.Object)]],
        difference: [core.Set$(E), [core.Set$(E)]],
        intersection: [core.Set$(E), [core.Set$(core.Object)]],
        lookup: [E, [core.Object]],
        remove: [core.bool, [core.Object]],
        removeAll: [dart.void, [core.Iterable$(core.Object)]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainAll: [dart.void, [core.Iterable$(core.Object)]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        union: [core.Set$(E), [core.Set$(E)]],
        toSet: [core.Set$(E), []]
      })
    });
    dart.defineExtensionMembers(DelegatingSet, ['toSet']);
    return DelegatingSet;
  });
  let DelegatingSet = DelegatingSet$();
  let _baseQueue = Symbol('_baseQueue');
  let DelegatingQueue$ = dart.generic(function(E) {
    class DelegatingQueue extends DelegatingIterable$(E) {
      DelegatingQueue(queue) {
        super.DelegatingIterable(queue);
      }
      get [_baseQueue]() {
        return dart.as(this[_base], collection.Queue$(E));
      }
      add(value) {
        dart.as(value, E);
        this[_baseQueue].add(value);
      }
      addAll(iterable) {
        dart.as(iterable, core.Iterable$(E));
        this[_baseQueue].addAll(iterable);
      }
      addFirst(value) {
        dart.as(value, E);
        this[_baseQueue].addFirst(value);
      }
      addLast(value) {
        dart.as(value, E);
        this[_baseQueue].addLast(value);
      }
      clear() {
        this[_baseQueue].clear();
      }
      remove(object) {
        return this[_baseQueue].remove(object);
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_baseQueue].removeWhere(test);
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_baseQueue].retainWhere(test);
      }
      removeFirst() {
        return this[_baseQueue].removeFirst();
      }
      removeLast() {
        return this[_baseQueue].removeLast();
      }
    }
    DelegatingQueue[dart.implements] = () => [collection.Queue$(E)];
    dart.setSignature(DelegatingQueue, {
      constructors: () => ({DelegatingQueue: [DelegatingQueue$(E), [collection.Queue$(E)]]}),
      methods: () => ({
        add: [dart.void, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        addFirst: [dart.void, [E]],
        addLast: [dart.void, [E]],
        clear: [dart.void, []],
        remove: [core.bool, [core.Object]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        removeFirst: [E, []],
        removeLast: [E, []]
      })
    });
    return DelegatingQueue;
  });
  let DelegatingQueue = DelegatingQueue$();
  let DelegatingMap$ = dart.generic(function(K, V) {
    class DelegatingMap extends core.Object {
      DelegatingMap(base) {
        this[_base] = base;
      }
      get(key) {
        return this[_base].get(key);
      }
      set(key, value) {
        dart.as(key, K);
        dart.as(value, V);
        this[_base].set(key, value);
        return value;
      }
      addAll(other) {
        dart.as(other, core.Map$(K, V));
        this[_base].addAll(other);
      }
      clear() {
        this[_base].clear();
      }
      containsKey(key) {
        return this[_base].containsKey(key);
      }
      containsValue(value) {
        return this[_base].containsValue(value);
      }
      forEach(f) {
        dart.as(f, dart.functionType(dart.void, [K, V]));
        this[_base].forEach(f);
      }
      get isEmpty() {
        return this[_base].isEmpty;
      }
      get isNotEmpty() {
        return this[_base].isNotEmpty;
      }
      get keys() {
        return this[_base].keys;
      }
      get length() {
        return this[_base].length;
      }
      putIfAbsent(key, ifAbsent) {
        dart.as(key, K);
        dart.as(ifAbsent, dart.functionType(V, []));
        return this[_base].putIfAbsent(key, ifAbsent);
      }
      remove(key) {
        return this[_base].remove(key);
      }
      get values() {
        return this[_base].values;
      }
      toString() {
        return dart.toString(this[_base]);
      }
    }
    DelegatingMap[dart.implements] = () => [core.Map$(K, V)];
    dart.setSignature(DelegatingMap, {
      constructors: () => ({DelegatingMap: [DelegatingMap$(K, V), [core.Map$(K, V)]]}),
      methods: () => ({
        get: [V, [core.Object]],
        set: [dart.void, [K, V]],
        addAll: [dart.void, [core.Map$(K, V)]],
        clear: [dart.void, []],
        containsKey: [core.bool, [core.Object]],
        containsValue: [core.bool, [core.Object]],
        forEach: [dart.void, [dart.functionType(dart.void, [K, V])]],
        putIfAbsent: [V, [K, dart.functionType(V, [])]],
        remove: [V, [core.Object]]
      })
    });
    return DelegatingMap;
  });
  let DelegatingMap = DelegatingMap$();
  let _baseMap = Symbol('_baseMap');
  let MapKeySet$ = dart.generic(function(E) {
    class MapKeySet extends dart.mixin(_DelegatingIterableBase$(E), unmodifiable_wrappers.UnmodifiableSetMixin$(E)) {
      MapKeySet(base) {
        this[_baseMap] = base;
        super._DelegatingIterableBase();
      }
      get [_base]() {
        return this[_baseMap].keys;
      }
      contains(element) {
        return this[_baseMap].containsKey(element);
      }
      get isEmpty() {
        return this[_baseMap].isEmpty;
      }
      get isNotEmpty() {
        return this[_baseMap].isNotEmpty;
      }
      get length() {
        return this[_baseMap].length;
      }
      toString() {
        return `{${this[_base][dartx.join](', ')}}`;
      }
      containsAll(other) {
        return other[dartx.every](dart.bind(this, 'contains'));
      }
      difference(other) {
        dart.as(other, core.Set$(E));
        return this.where(dart.fn(element => !dart.notNull(other.contains(element)), core.bool, [dart.dynamic]))[dartx.toSet]();
      }
      intersection(other) {
        return this.where(dart.bind(other, 'contains'))[dartx.toSet]();
      }
      lookup(element) {
        dart.as(element, E);
        return dart.throw(new core.UnsupportedError("MapKeySet doesn't support lookup()."));
      }
      union(other) {
        dart.as(other, core.Set$(E));
        return (() => {
          let _ = this.toSet();
          _.addAll(other);
          return _;
        })();
      }
    }
    dart.setSignature(MapKeySet, {
      constructors: () => ({MapKeySet: [exports.MapKeySet$(E), [core.Map$(E, dart.dynamic)]]}),
      methods: () => ({
        containsAll: [core.bool, [core.Iterable$(core.Object)]],
        difference: [core.Set$(E), [core.Set$(E)]],
        intersection: [core.Set$(E), [core.Set$(core.Object)]],
        lookup: [E, [E]],
        union: [core.Set$(E), [core.Set$(E)]]
      })
    });
    dart.defineExtensionMembers(MapKeySet, [
      'contains',
      'toString',
      'isEmpty',
      'isNotEmpty',
      'length'
    ]);
    return MapKeySet;
  });
  dart.defineLazyClassGeneric(exports, 'MapKeySet', {get: MapKeySet$});
  let _keyForValue = Symbol('_keyForValue');
  let MapValueSet$ = dart.generic(function(K, V) {
    class MapValueSet extends _DelegatingIterableBase$(V) {
      MapValueSet(base, keyForValue) {
        this[_baseMap] = base;
        this[_keyForValue] = keyForValue;
        super._DelegatingIterableBase();
      }
      get [_base]() {
        return this[_baseMap].values;
      }
      contains(element) {
        if (element != null && !dart.is(element, V))
          return false;
        return this[_baseMap].containsKey(dart.dcall(this[_keyForValue], element));
      }
      get isEmpty() {
        return this[_baseMap].isEmpty;
      }
      get isNotEmpty() {
        return this[_baseMap].isNotEmpty;
      }
      get length() {
        return this[_baseMap].length;
      }
      toString() {
        return dart.toString(this.toSet());
      }
      add(value) {
        dart.as(value, V);
        let key = dart.as(dart.dcall(this[_keyForValue], value), K);
        let result = false;
        this[_baseMap].putIfAbsent(key, dart.as(dart.fn(() => {
          result = true;
          return value;
        }), __CastType0));
        return result;
      }
      addAll(elements) {
        dart.as(elements, core.Iterable$(V));
        return elements[dartx.forEach](dart.bind(this, 'add'));
      }
      clear() {
        return this[_baseMap].clear();
      }
      containsAll(other) {
        return other[dartx.every](dart.bind(this, 'contains'));
      }
      difference(other) {
        dart.as(other, core.Set$(V));
        return this.where(dart.fn(element => !dart.notNull(other.contains(element)), core.bool, [dart.dynamic]))[dartx.toSet]();
      }
      intersection(other) {
        return this.where(dart.bind(other, 'contains'))[dartx.toSet]();
      }
      lookup(element) {
        return this[_baseMap].get(dart.dcall(this[_keyForValue], element));
      }
      remove(value) {
        if (value != null && !dart.is(value, V))
          return false;
        let key = dart.dcall(this[_keyForValue], value);
        if (!dart.notNull(this[_baseMap].containsKey(key)))
          return false;
        this[_baseMap].remove(key);
        return true;
      }
      removeAll(elements) {
        return elements[dartx.forEach](dart.bind(this, 'remove'));
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [V]));
        let toRemove = [];
        this[_baseMap].forEach(dart.fn((key, value) => {
          if (dart.notNull(test(dart.as(value, V))))
            toRemove[dartx.add](key);
        }));
        toRemove[dartx.forEach](dart.bind(this[_baseMap], 'remove'));
      }
      retainAll(elements) {
        let valuesToRetain = core.Set$(V).identity();
        for (let element of elements) {
          if (element != null && !dart.is(element, V))
            continue;
          let key = dart.dcall(this[_keyForValue], element);
          if (!dart.notNull(this[_baseMap].containsKey(key)))
            continue;
          valuesToRetain.add(this[_baseMap].get(key));
        }
        let keysToRemove = [];
        this[_baseMap].forEach(dart.fn((k, v) => {
          if (!dart.notNull(valuesToRetain.contains(v)))
            keysToRemove[dartx.add](k);
        }));
        keysToRemove[dartx.forEach](dart.bind(this[_baseMap], 'remove'));
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [V]));
        return this.removeWhere(dart.fn(element => !dart.notNull(test(dart.as(element, V))), core.bool, [dart.dynamic]));
      }
      union(other) {
        dart.as(other, core.Set$(V));
        return (() => {
          let _ = this.toSet();
          _.addAll(other);
          return _;
        })();
      }
    }
    MapValueSet[dart.implements] = () => [core.Set$(V)];
    dart.setSignature(MapValueSet, {
      constructors: () => ({MapValueSet: [MapValueSet$(K, V), [core.Map$(K, V), dart.functionType(K, [V])]]}),
      methods: () => ({
        add: [core.bool, [V]],
        addAll: [dart.void, [core.Iterable$(V)]],
        clear: [dart.void, []],
        containsAll: [core.bool, [core.Iterable$(core.Object)]],
        difference: [core.Set$(V), [core.Set$(V)]],
        intersection: [core.Set$(V), [core.Set$(core.Object)]],
        lookup: [V, [core.Object]],
        remove: [core.bool, [core.Object]],
        removeAll: [dart.void, [core.Iterable$(core.Object)]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [V])]],
        retainAll: [dart.void, [core.Iterable$(core.Object)]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [V])]],
        union: [core.Set$(V), [core.Set$(V)]]
      })
    });
    dart.defineExtensionMembers(MapValueSet, [
      'contains',
      'toString',
      'isEmpty',
      'isNotEmpty',
      'length'
    ]);
    return MapValueSet;
  });
  let MapValueSet = MapValueSet$();
  let __CastType0$ = dart.generic(function(V) {
    let __CastType0 = dart.typedef('__CastType0', () => dart.functionType(V, []));
    return __CastType0;
  });
  let __CastType0 = __CastType0$();
  // Exports:
  exports.DelegatingIterable$ = DelegatingIterable$;
  exports.DelegatingIterable = DelegatingIterable;
  exports.DelegatingList$ = DelegatingList$;
  exports.DelegatingList = DelegatingList;
  exports.DelegatingSet$ = DelegatingSet$;
  exports.DelegatingSet = DelegatingSet;
  exports.DelegatingQueue$ = DelegatingQueue$;
  exports.DelegatingQueue = DelegatingQueue;
  exports.DelegatingMap$ = DelegatingMap$;
  exports.DelegatingMap = DelegatingMap;
  exports.MapKeySet$ = MapKeySet$;
  exports.MapValueSet$ = MapValueSet$;
  exports.MapValueSet = MapValueSet;
});
