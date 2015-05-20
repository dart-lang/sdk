var collection = dart.defineLibrary(collection, {});
var _internal = dart.lazyImport(_internal);
var core = dart.import(core);
var _js_helper = dart.lazyImport(_js_helper);
var math = dart.lazyImport(math);
(function(exports, _internal, core, _js_helper, math) {
  'use strict';
  let _source = Symbol('_source');
  let UnmodifiableListView$ = dart.generic(function(E) {
    class UnmodifiableListView extends _internal.UnmodifiableListBase$(E) {
      UnmodifiableListView(source) {
        this[_source] = source;
      }
      get [core.$length]() {
        return this[_source][core.$length];
      }
      [core.$get](index) {
        return this[_source][core.$elementAt](index);
      }
    }
    dart.setSignature(UnmodifiableListView, {
      methods: () => ({[core.$get]: [E, [core.int]]})
    });
    return UnmodifiableListView;
  });
  dart.defineLazyClassGeneric(exports, 'UnmodifiableListView', {get: UnmodifiableListView$});
  function _defaultEquals(a, b) {
    return dart.equals(a, b);
  }
  dart.fn(_defaultEquals, core.bool, [core.Object, core.Object]);
  function _defaultHashCode(a) {
    return dart.hashCode(a);
  }
  dart.fn(_defaultHashCode, core.int, [core.Object]);
  let _Equality$ = dart.generic(function(K) {
    let _Equality = dart.typedef('_Equality', () => dart.functionType(core.bool, [K, K]));
    return _Equality;
  });
  let _Equality = _Equality$();
  let _Hasher$ = dart.generic(function(K) {
    let _Hasher = dart.typedef('_Hasher', () => dart.functionType(core.int, [K]));
    return _Hasher;
  });
  let _Hasher = _Hasher$();
  let HashMap$ = dart.generic(function(K, V) {
    class HashMap extends core.Object {
      HashMap(opts) {
        let equals = opts && 'equals' in opts ? opts.equals : null;
        let hashCode = opts && 'hashCode' in opts ? opts.hashCode : null;
        let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
        if (isValidKey == null) {
          if (hashCode == null) {
            if (equals == null) {
              return new (_HashMap$(K, V))();
            }
            hashCode = _defaultHashCode;
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new (_IdentityHashMap$(K, V))();
            }
            if (equals == null) {
              equals = _defaultEquals;
            }
          }
        } else {
          if (hashCode == null) {
            hashCode = _defaultHashCode;
          }
          if (equals == null) {
            equals = _defaultEquals;
          }
        }
        return new (_CustomHashMap$(K, V))(equals, hashCode, isValidKey);
      }
      identity() {
        return new (_IdentityHashMap$(K, V))();
      }
      from(other) {
        let result = new (HashMap$(K, V))();
        other.forEach(dart.fn((k, v) => {
          result.set(k, dart.as(v, V));
        }));
        return result;
      }
      fromIterable(iterable, opts) {
        let key = opts && 'key' in opts ? opts.key : null;
        let value = opts && 'value' in opts ? opts.value : null;
        let map = new (HashMap$(K, V))();
        Maps._fillMapWithMappedIterable(map, iterable, key, value);
        return map;
      }
      fromIterables(keys, values) {
        let map = new (HashMap$(K, V))();
        Maps._fillMapWithIterables(map, keys, values);
        return map;
      }
    }
    HashMap[dart.implements] = () => [core.Map$(K, V)];
    dart.defineNamedConstructor(HashMap, 'identity');
    dart.defineNamedConstructor(HashMap, 'from');
    dart.defineNamedConstructor(HashMap, 'fromIterable');
    dart.defineNamedConstructor(HashMap, 'fromIterables');
    return HashMap;
  });
  let HashMap = HashMap$();
  let SetMixin$ = dart.generic(function(E) {
    class SetMixin extends core.Object {
      [Symbol.iterator]() {
        return new dart.JsIterator(this[core.$iterator]);
      }
      get [core.$isEmpty]() {
        return this[core.$length] == 0;
      }
      get [core.$isNotEmpty]() {
        return this[core.$length] != 0;
      }
      clear() {
        this.removeAll(this[core.$toList]());
      }
      addAll(elements) {
        dart.as(elements, core.Iterable$(E));
        for (let element of elements)
          this.add(element);
      }
      removeAll(elements) {
        for (let element of elements)
          this.remove(element);
      }
      retainAll(elements) {
        let toRemove = this[core.$toSet]();
        for (let o of elements) {
          toRemove.remove(o);
        }
        this.removeAll(toRemove);
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let toRemove = [];
        for (let element of this) {
          if (test(element))
            toRemove[core.$add](element);
        }
        this.removeAll(toRemove);
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let toRemove = [];
        for (let element of this) {
          if (!dart.notNull(test(element)))
            toRemove[core.$add](element);
        }
        this.removeAll(toRemove);
      }
      containsAll(other) {
        for (let o of other) {
          if (!dart.notNull(this[core.$contains](o)))
            return false;
        }
        return true;
      }
      union(other) {
        dart.as(other, core.Set$(E));
        let _ = this[core.$toSet]();
        _.addAll(other);
        return _;
      }
      intersection(other) {
        let result = this[core.$toSet]();
        for (let element of this) {
          if (!dart.notNull(other[core.$contains](element)))
            result.remove(element);
        }
        return result;
      }
      difference(other) {
        let result = this[core.$toSet]();
        for (let element of this) {
          if (other[core.$contains](element))
            result.remove(element);
        }
        return result;
      }
      [core.$toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        let result = growable ? (() => {
          let _ = new (core.List$(E))();
          _[core.$length] = this[core.$length];
          return _;
        }).bind(this)() : new (core.List$(E))(this[core.$length]);
        let i = 0;
        for (let element of this)
          result[core.$set]((() => {
            let x = i;
            i = dart.notNull(x) + 1;
            return x;
          })(), element);
        return result;
      }
      [core.$map](f) {
        dart.as(f, dart.functionType(core.Object, [E]));
        return new (_internal.EfficientLengthMappedIterable$(E, core.Object))(this, f);
      }
      get [core.$single]() {
        if (dart.notNull(this[core.$length]) > 1)
          throw _internal.IterableElementError.tooMany();
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext()))
          throw _internal.IterableElementError.noElement();
        let result = it.current;
        return result;
      }
      toString() {
        return IterableBase.iterableToFullString(this, '{', '}');
      }
      [core.$where](f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        return new (_internal.WhereIterable$(E))(this, f);
      }
      [core.$expand](f) {
        dart.as(f, dart.functionType(core.Iterable, [E]));
        return new (_internal.ExpandIterable$(E, core.Object))(this, f);
      }
      [core.$forEach](f) {
        dart.as(f, dart.functionType(dart.void, [E]));
        for (let element of this)
          f(element);
      }
      [core.$reduce](combine) {
        dart.as(combine, dart.functionType(E, [E, E]));
        let iterator = this[core.$iterator];
        if (!dart.notNull(iterator.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let value = iterator.current;
        while (iterator.moveNext()) {
          value = combine(value, iterator.current);
        }
        return value;
      }
      [core.$fold](initialValue, combine) {
        dart.as(combine, dart.functionType(core.Object, [dart.bottom, E]));
        let value = initialValue;
        for (let element of this)
          value = dart.dcall(combine, value, element);
        return value;
      }
      [core.$every](f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        for (let element of this) {
          if (!dart.notNull(f(element)))
            return false;
        }
        return true;
      }
      [core.$join](separator) {
        if (separator === void 0)
          separator = "";
        let iterator = this[core.$iterator];
        if (!dart.notNull(iterator.moveNext()))
          return "";
        let buffer = new core.StringBuffer();
        if (separator == null || separator == "") {
          do {
            buffer.write(`${iterator.current}`);
          } while (iterator.moveNext());
        } else {
          buffer.write(`${iterator.current}`);
          while (iterator.moveNext()) {
            buffer.write(separator);
            buffer.write(`${iterator.current}`);
          }
        }
        return dart.toString(buffer);
      }
      [core.$any](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        for (let element of this) {
          if (test(element))
            return true;
        }
        return false;
      }
      [core.$take](n) {
        return new (_internal.TakeIterable$(E))(this, n);
      }
      [core.$takeWhile](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.TakeWhileIterable$(E))(this, test);
      }
      [core.$skip](n) {
        return new (_internal.SkipIterable$(E))(this, n);
      }
      [core.$skipWhile](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.SkipWhileIterable$(E))(this, test);
      }
      get [core.$first]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        return it.current;
      }
      get [core.$last]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let result = null;
        do {
          result = it.current;
        } while (it.moveNext());
        return result;
      }
      [core.$firstWhere](test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        for (let element of this) {
          if (test(element))
            return element;
        }
        if (orElse != null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      [core.$lastWhere](test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        if (orElse != null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      [core.$singleWhere](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            if (foundMatching) {
              throw _internal.IterableElementError.tooMany();
            }
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        throw _internal.IterableElementError.noElement();
      }
      [core.$elementAt](index) {
        if (!(typeof index == 'number'))
          throw new core.ArgumentError.notNull("index");
        core.RangeError.checkNotNegative(index, "index");
        let elementIndex = 0;
        for (let element of this) {
          if (index == elementIndex)
            return element;
          elementIndex = dart.notNull(elementIndex) + 1;
        }
        throw new core.RangeError.index(index, this, "index", null, elementIndex);
      }
    }
    SetMixin[dart.implements] = () => [core.Set$(E)];
    dart.setSignature(SetMixin, {
      methods: () => ({
        clear: [dart.void, []],
        addAll: [dart.void, [core.Iterable$(E)]],
        removeAll: [dart.void, [core.Iterable$(core.Object)]],
        retainAll: [dart.void, [core.Iterable$(core.Object)]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        containsAll: [core.bool, [core.Iterable$(core.Object)]],
        union: [core.Set$(E), [core.Set$(E)]],
        intersection: [core.Set$(E), [core.Set$(core.Object)]],
        difference: [core.Set$(E), [core.Set$(core.Object)]],
        [core.$toList]: [core.List$(E), [], {rowabl: core.bool}],
        [core.$map]: [core.Iterable, [dart.functionType(core.Object, [E])]],
        [core.$where]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$expand]: [core.Iterable, [dart.functionType(core.Iterable, [E])]],
        [core.$forEach]: [dart.void, [dart.functionType(dart.void, [E])]],
        [core.$reduce]: [E, [dart.functionType(E, [E, E])]],
        [core.$fold]: [core.Object, [core.Object, dart.functionType(core.Object, [dart.bottom, E])]],
        [core.$every]: [core.bool, [dart.functionType(core.bool, [E])]],
        [core.$join]: [core.String, [], [core.String]],
        [core.$any]: [core.bool, [dart.functionType(core.bool, [E])]],
        [core.$take]: [core.Iterable$(E), [core.int]],
        [core.$takeWhile]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$skip]: [core.Iterable$(E), [core.int]],
        [core.$skipWhile]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$firstWhere]: [E, [dart.functionType(core.bool, [E])], {rEls: dart.functionType(E, [])}],
        [core.$lastWhere]: [E, [dart.functionType(core.bool, [E])], {rEls: dart.functionType(E, [])}],
        [core.$singleWhere]: [E, [dart.functionType(core.bool, [E])]],
        [core.$elementAt]: [E, [core.int]]
      })
    });
    return SetMixin;
  });
  let SetMixin = SetMixin$();
  let SetBase$ = dart.generic(function(E) {
    class SetBase extends SetMixin$(E) {
      static setToString(set) {
        return IterableBase.iterableToFullString(set, '{', '}');
      }
    }
    dart.setSignature(SetBase, {
      statics: () => ({setToString: [core.String, [core.Set]]}),
      names: ['setToString']
    });
    return SetBase;
  });
  let SetBase = SetBase$();
  let _newSet = Symbol('_newSet');
  let _HashSetBase$ = dart.generic(function(E) {
    class _HashSetBase extends SetBase$(E) {
      difference(other) {
        let result = this[_newSet]();
        for (let element of this) {
          if (!dart.notNull(other[core.$contains](element)))
            result.add(element);
        }
        return result;
      }
      intersection(other) {
        let result = this[_newSet]();
        for (let element of this) {
          if (other[core.$contains](element))
            result.add(element);
        }
        return result;
      }
      [core.$toSet]() {
        return (() => {
          let _ = this[_newSet]();
          _.addAll(this);
          return _;
        }).bind(this)();
      }
    }
    dart.setSignature(_HashSetBase, {
      methods: () => ({
        difference: [core.Set$(E), [core.Set$(core.Object)]],
        intersection: [core.Set$(E), [core.Set$(core.Object)]],
        [core.$toSet]: [core.Set$(E), []]
      })
    });
    return _HashSetBase;
  });
  let _HashSetBase = _HashSetBase$();
  let HashSet$ = dart.generic(function(E) {
    class HashSet extends core.Object {
      HashSet(opts) {
        let equals = opts && 'equals' in opts ? opts.equals : null;
        let hashCode = opts && 'hashCode' in opts ? opts.hashCode : null;
        let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
        if (isValidKey == null) {
          if (hashCode == null) {
            if (equals == null) {
              return new (_HashSet$(E))();
            }
            hashCode = _defaultHashCode;
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new (_IdentityHashSet$(E))();
            }
            if (equals == null) {
              equals = _defaultEquals;
            }
          }
        } else {
          if (hashCode == null) {
            hashCode = _defaultHashCode;
          }
          if (equals == null) {
            equals = _defaultEquals;
          }
        }
        return new (_CustomHashSet$(E))(equals, hashCode, isValidKey);
      }
      identity() {
        return new (_IdentityHashSet$(E))();
      }
      from(elements) {
        let result = new (HashSet$(E))();
        for (let e of dart.as(elements, core.Iterable$(E)))
          result.add(e);
        return result;
      }
      [Symbol.iterator]() {
        return new dart.JsIterator(this[core.$iterator]);
      }
    }
    HashSet[dart.implements] = () => [core.Set$(E)];
    dart.defineNamedConstructor(HashSet, 'identity');
    dart.defineNamedConstructor(HashSet, 'from');
    return HashSet;
  });
  let HashSet = HashSet$();
  let IterableMixin$ = dart.generic(function(E) {
    class IterableMixin extends core.Object {
      [core.$map](f) {
        dart.as(f, dart.functionType(core.Object, [E]));
        return new (_internal.MappedIterable$(E, core.Object))(this, f);
      }
      [core.$where](f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        return new (_internal.WhereIterable$(E))(this, f);
      }
      [core.$expand](f) {
        dart.as(f, dart.functionType(core.Iterable, [E]));
        return new (_internal.ExpandIterable$(E, core.Object))(this, f);
      }
      [core.$contains](element) {
        for (let e of this) {
          if (dart.equals(e, element))
            return true;
        }
        return false;
      }
      [core.$forEach](f) {
        dart.as(f, dart.functionType(dart.void, [E]));
        for (let element of this)
          f(element);
      }
      [core.$reduce](combine) {
        dart.as(combine, dart.functionType(E, [E, E]));
        let iterator = this[core.$iterator];
        if (!dart.notNull(iterator.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let value = iterator.current;
        while (iterator.moveNext()) {
          value = combine(value, iterator.current);
        }
        return value;
      }
      [core.$fold](initialValue, combine) {
        dart.as(combine, dart.functionType(core.Object, [dart.bottom, E]));
        let value = initialValue;
        for (let element of this)
          value = dart.dcall(combine, value, element);
        return value;
      }
      [core.$every](f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        for (let element of this) {
          if (!dart.notNull(f(element)))
            return false;
        }
        return true;
      }
      [core.$join](separator) {
        if (separator === void 0)
          separator = "";
        let iterator = this[core.$iterator];
        if (!dart.notNull(iterator.moveNext()))
          return "";
        let buffer = new core.StringBuffer();
        if (separator == null || separator == "") {
          do {
            buffer.write(`${iterator.current}`);
          } while (iterator.moveNext());
        } else {
          buffer.write(`${iterator.current}`);
          while (iterator.moveNext()) {
            buffer.write(separator);
            buffer.write(`${iterator.current}`);
          }
        }
        return dart.toString(buffer);
      }
      [core.$any](f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        for (let element of this) {
          if (f(element))
            return true;
        }
        return false;
      }
      [core.$toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        return new (core.List$(E)).from(this, {growable: growable});
      }
      [core.$toSet]() {
        return new (core.Set$(E)).from(this);
      }
      get [core.$length]() {
        dart.assert(!dart.is(this, _internal.EfficientLength));
        let count = 0;
        let it = this[core.$iterator];
        while (it.moveNext()) {
          count = dart.notNull(count) + 1;
        }
        return count;
      }
      get [core.$isEmpty]() {
        return !dart.notNull(this[core.$iterator].moveNext());
      }
      get [core.$isNotEmpty]() {
        return !dart.notNull(this[core.$isEmpty]);
      }
      [core.$take](n) {
        return new (_internal.TakeIterable$(E))(this, n);
      }
      [core.$takeWhile](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.TakeWhileIterable$(E))(this, test);
      }
      [core.$skip](n) {
        return new (_internal.SkipIterable$(E))(this, n);
      }
      [core.$skipWhile](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.SkipWhileIterable$(E))(this, test);
      }
      get [core.$first]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        return it.current;
      }
      get [core.$last]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let result = null;
        do {
          result = it.current;
        } while (it.moveNext());
        return result;
      }
      get [core.$single]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext()))
          throw _internal.IterableElementError.noElement();
        let result = it.current;
        if (it.moveNext())
          throw _internal.IterableElementError.tooMany();
        return result;
      }
      [core.$firstWhere](test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        for (let element of this) {
          if (test(element))
            return element;
        }
        if (orElse != null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      [core.$lastWhere](test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        if (orElse != null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      [core.$singleWhere](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            if (foundMatching) {
              throw _internal.IterableElementError.tooMany();
            }
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        throw _internal.IterableElementError.noElement();
      }
      [core.$elementAt](index) {
        if (!(typeof index == 'number'))
          throw new core.ArgumentError.notNull("index");
        core.RangeError.checkNotNegative(index, "index");
        let elementIndex = 0;
        for (let element of this) {
          if (index == elementIndex)
            return element;
          elementIndex = dart.notNull(elementIndex) + 1;
        }
        throw new core.RangeError.index(index, this, "index", null, elementIndex);
      }
      toString() {
        return IterableBase.iterableToShortString(this, '(', ')');
      }
      [Symbol.iterator]() {
        return new dart.JsIterator(this[core.$iterator]);
      }
    }
    IterableMixin[dart.implements] = () => [core.Iterable$(E)];
    dart.setSignature(IterableMixin, {
      methods: () => ({
        [core.$map]: [core.Iterable, [dart.functionType(core.Object, [E])]],
        [core.$where]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$expand]: [core.Iterable, [dart.functionType(core.Iterable, [E])]],
        [core.$contains]: [core.bool, [core.Object]],
        [core.$forEach]: [dart.void, [dart.functionType(dart.void, [E])]],
        [core.$reduce]: [E, [dart.functionType(E, [E, E])]],
        [core.$fold]: [core.Object, [core.Object, dart.functionType(core.Object, [dart.bottom, E])]],
        [core.$every]: [core.bool, [dart.functionType(core.bool, [E])]],
        [core.$join]: [core.String, [], [core.String]],
        [core.$any]: [core.bool, [dart.functionType(core.bool, [E])]],
        [core.$toList]: [core.List$(E), [], {rowabl: core.bool}],
        [core.$toSet]: [core.Set$(E), []],
        [core.$take]: [core.Iterable$(E), [core.int]],
        [core.$takeWhile]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$skip]: [core.Iterable$(E), [core.int]],
        [core.$skipWhile]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$firstWhere]: [E, [dart.functionType(core.bool, [E])], {rEls: dart.functionType(E, [])}],
        [core.$lastWhere]: [E, [dart.functionType(core.bool, [E])], {rEls: dart.functionType(E, [])}],
        [core.$singleWhere]: [E, [dart.functionType(core.bool, [E])]],
        [core.$elementAt]: [E, [core.int]]
      })
    });
    return IterableMixin;
  });
  let IterableMixin = IterableMixin$();
  let IterableBase$ = dart.generic(function(E) {
    class IterableBase extends core.Object {
      IterableBase() {
      }
      [core.$map](f) {
        dart.as(f, dart.functionType(core.Object, [E]));
        return new (_internal.MappedIterable$(E, core.Object))(this, f);
      }
      [core.$where](f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        return new (_internal.WhereIterable$(E))(this, f);
      }
      [core.$expand](f) {
        dart.as(f, dart.functionType(core.Iterable, [E]));
        return new (_internal.ExpandIterable$(E, core.Object))(this, f);
      }
      [core.$contains](element) {
        for (let e of this) {
          if (dart.equals(e, element))
            return true;
        }
        return false;
      }
      [core.$forEach](f) {
        dart.as(f, dart.functionType(dart.void, [E]));
        for (let element of this)
          f(element);
      }
      [core.$reduce](combine) {
        dart.as(combine, dart.functionType(E, [E, E]));
        let iterator = this[core.$iterator];
        if (!dart.notNull(iterator.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let value = iterator.current;
        while (iterator.moveNext()) {
          value = combine(value, iterator.current);
        }
        return value;
      }
      [core.$fold](initialValue, combine) {
        dart.as(combine, dart.functionType(core.Object, [dart.bottom, E]));
        let value = initialValue;
        for (let element of this)
          value = dart.dcall(combine, value, element);
        return value;
      }
      [core.$every](f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        for (let element of this) {
          if (!dart.notNull(f(element)))
            return false;
        }
        return true;
      }
      [core.$join](separator) {
        if (separator === void 0)
          separator = "";
        let iterator = this[core.$iterator];
        if (!dart.notNull(iterator.moveNext()))
          return "";
        let buffer = new core.StringBuffer();
        if (separator == null || separator == "") {
          do {
            buffer.write(`${iterator.current}`);
          } while (iterator.moveNext());
        } else {
          buffer.write(`${iterator.current}`);
          while (iterator.moveNext()) {
            buffer.write(separator);
            buffer.write(`${iterator.current}`);
          }
        }
        return dart.toString(buffer);
      }
      [core.$any](f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        for (let element of this) {
          if (f(element))
            return true;
        }
        return false;
      }
      [core.$toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        return new (core.List$(E)).from(this, {growable: growable});
      }
      [core.$toSet]() {
        return new (core.Set$(E)).from(this);
      }
      get [core.$length]() {
        dart.assert(!dart.is(this, _internal.EfficientLength));
        let count = 0;
        let it = this[core.$iterator];
        while (it.moveNext()) {
          count = dart.notNull(count) + 1;
        }
        return count;
      }
      get [core.$isEmpty]() {
        return !dart.notNull(this[core.$iterator].moveNext());
      }
      get [core.$isNotEmpty]() {
        return !dart.notNull(this[core.$isEmpty]);
      }
      [core.$take](n) {
        return new (_internal.TakeIterable$(E))(this, n);
      }
      [core.$takeWhile](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.TakeWhileIterable$(E))(this, test);
      }
      [core.$skip](n) {
        return new (_internal.SkipIterable$(E))(this, n);
      }
      [core.$skipWhile](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.SkipWhileIterable$(E))(this, test);
      }
      get [core.$first]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        return it.current;
      }
      get [core.$last]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let result = null;
        do {
          result = it.current;
        } while (it.moveNext());
        return result;
      }
      get [core.$single]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext()))
          throw _internal.IterableElementError.noElement();
        let result = it.current;
        if (it.moveNext())
          throw _internal.IterableElementError.tooMany();
        return result;
      }
      [core.$firstWhere](test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        for (let element of this) {
          if (test(element))
            return element;
        }
        if (orElse != null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      [core.$lastWhere](test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        if (orElse != null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      [core.$singleWhere](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            if (foundMatching) {
              throw _internal.IterableElementError.tooMany();
            }
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        throw _internal.IterableElementError.noElement();
      }
      [core.$elementAt](index) {
        if (!(typeof index == 'number'))
          throw new core.ArgumentError.notNull("index");
        core.RangeError.checkNotNegative(index, "index");
        let elementIndex = 0;
        for (let element of this) {
          if (index == elementIndex)
            return element;
          elementIndex = dart.notNull(elementIndex) + 1;
        }
        throw new core.RangeError.index(index, this, "index", null, elementIndex);
      }
      toString() {
        return IterableBase$().iterableToShortString(this, '(', ')');
      }
      static iterableToShortString(iterable, leftDelimiter, rightDelimiter) {
        if (leftDelimiter === void 0)
          leftDelimiter = '(';
        if (rightDelimiter === void 0)
          rightDelimiter = ')';
        if (IterableBase$()._isToStringVisiting(iterable)) {
          if (leftDelimiter == "(" && rightDelimiter == ")") {
            return "(...)";
          }
          return `${leftDelimiter}...${rightDelimiter}`;
        }
        let parts = [];
        IterableBase$()._toStringVisiting[core.$add](iterable);
        try {
          IterableBase$()._iterablePartsToStrings(iterable, parts);
        } finally {
          dart.assert(core.identical(IterableBase$()._toStringVisiting[core.$last], iterable));
          IterableBase$()._toStringVisiting[core.$removeLast]();
        }
        return dart.toString((() => {
          let _ = new core.StringBuffer(leftDelimiter);
          _.writeAll(parts, ", ");
          _.write(rightDelimiter);
          return _;
        })());
      }
      static iterableToFullString(iterable, leftDelimiter, rightDelimiter) {
        if (leftDelimiter === void 0)
          leftDelimiter = '(';
        if (rightDelimiter === void 0)
          rightDelimiter = ')';
        if (IterableBase$()._isToStringVisiting(iterable)) {
          return `${leftDelimiter}...${rightDelimiter}`;
        }
        let buffer = new core.StringBuffer(leftDelimiter);
        IterableBase$()._toStringVisiting[core.$add](iterable);
        try {
          buffer.writeAll(iterable, ", ");
        } finally {
          dart.assert(core.identical(IterableBase$()._toStringVisiting[core.$last], iterable));
          IterableBase$()._toStringVisiting[core.$removeLast]();
        }
        buffer.write(rightDelimiter);
        return dart.toString(buffer);
      }
      static _isToStringVisiting(o) {
        for (let i = 0; dart.notNull(i) < dart.notNull(IterableBase$()._toStringVisiting[core.$length]); i = dart.notNull(i) + 1) {
          if (core.identical(o, IterableBase$()._toStringVisiting[core.$get](i)))
            return true;
        }
        return false;
      }
      static _iterablePartsToStrings(iterable, parts) {
        let LENGTH_LIMIT = 80;
        let HEAD_COUNT = 3;
        let TAIL_COUNT = 2;
        let MAX_COUNT = 100;
        let OVERHEAD = 2;
        let ELLIPSIS_SIZE = 3;
        let length = 0;
        let count = 0;
        let it = iterable[core.$iterator];
        while (dart.notNull(length) < dart.notNull(LENGTH_LIMIT) || dart.notNull(count) < dart.notNull(HEAD_COUNT)) {
          if (!dart.notNull(it.moveNext()))
            return;
          let next = `${it.current}`;
          parts[core.$add](next);
          length = dart.notNull(length) + (dart.notNull(next.length) + dart.notNull(OVERHEAD));
          count = dart.notNull(count) + 1;
        }
        let penultimateString = null;
        let ultimateString = null;
        let penultimate = null;
        let ultimate = null;
        if (!dart.notNull(it.moveNext())) {
          if (dart.notNull(count) <= dart.notNull(HEAD_COUNT) + dart.notNull(TAIL_COUNT))
            return;
          ultimateString = dart.as(parts[core.$removeLast](), core.String);
          penultimateString = dart.as(parts[core.$removeLast](), core.String);
        } else {
          penultimate = it.current;
          count = dart.notNull(count) + 1;
          if (!dart.notNull(it.moveNext())) {
            if (dart.notNull(count) <= dart.notNull(HEAD_COUNT) + 1) {
              parts[core.$add](`${penultimate}`);
              return;
            }
            ultimateString = `${penultimate}`;
            penultimateString = dart.as(parts[core.$removeLast](), core.String);
            length = dart.notNull(length) + (dart.notNull(ultimateString.length) + dart.notNull(OVERHEAD));
          } else {
            ultimate = it.current;
            count = dart.notNull(count) + 1;
            dart.assert(dart.notNull(count) < dart.notNull(MAX_COUNT));
            while (it.moveNext()) {
              penultimate = ultimate;
              ultimate = it.current;
              count = dart.notNull(count) + 1;
              if (dart.notNull(count) > dart.notNull(MAX_COUNT)) {
                while (dart.notNull(length) > dart.notNull(LENGTH_LIMIT) - dart.notNull(ELLIPSIS_SIZE) - dart.notNull(OVERHEAD) && dart.notNull(count) > dart.notNull(HEAD_COUNT)) {
                  length = dart.notNull(length) - dart.notNull(dart.as(dart.dsend(dart.dload(parts[core.$removeLast](), 'length'), '+', OVERHEAD), core.int));
                  count = dart.notNull(count) - 1;
                }
                parts[core.$add]("...");
                return;
              }
            }
            penultimateString = `${penultimate}`;
            ultimateString = `${ultimate}`;
            length = dart.notNull(length) + (dart.notNull(ultimateString.length) + dart.notNull(penultimateString.length) + 2 * dart.notNull(OVERHEAD));
          }
        }
        let elision = null;
        if (dart.notNull(count) > dart.notNull(parts[core.$length]) + dart.notNull(TAIL_COUNT)) {
          elision = "...";
          length = dart.notNull(length) + (dart.notNull(ELLIPSIS_SIZE) + dart.notNull(OVERHEAD));
        }
        while (dart.notNull(length) > dart.notNull(LENGTH_LIMIT) && dart.notNull(parts[core.$length]) > dart.notNull(HEAD_COUNT)) {
          length = dart.notNull(length) - dart.notNull(dart.as(dart.dsend(dart.dload(parts[core.$removeLast](), 'length'), '+', OVERHEAD), core.int));
          if (elision == null) {
            elision = "...";
            length = dart.notNull(length) + (dart.notNull(ELLIPSIS_SIZE) + dart.notNull(OVERHEAD));
          }
        }
        if (elision != null) {
          parts[core.$add](elision);
        }
        parts[core.$add](penultimateString);
        parts[core.$add](ultimateString);
      }
      [Symbol.iterator]() {
        return new dart.JsIterator(this[core.$iterator]);
      }
    }
    IterableBase[dart.implements] = () => [core.Iterable$(E)];
    dart.setSignature(IterableBase, {
      methods: () => ({
        [core.$map]: [core.Iterable, [dart.functionType(core.Object, [E])]],
        [core.$where]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$expand]: [core.Iterable, [dart.functionType(core.Iterable, [E])]],
        [core.$contains]: [core.bool, [core.Object]],
        [core.$forEach]: [dart.void, [dart.functionType(dart.void, [E])]],
        [core.$reduce]: [E, [dart.functionType(E, [E, E])]],
        [core.$fold]: [core.Object, [core.Object, dart.functionType(core.Object, [dart.bottom, E])]],
        [core.$every]: [core.bool, [dart.functionType(core.bool, [E])]],
        [core.$join]: [core.String, [], [core.String]],
        [core.$any]: [core.bool, [dart.functionType(core.bool, [E])]],
        [core.$toList]: [core.List$(E), [], {rowabl: core.bool}],
        [core.$toSet]: [core.Set$(E), []],
        [core.$take]: [core.Iterable$(E), [core.int]],
        [core.$takeWhile]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$skip]: [core.Iterable$(E), [core.int]],
        [core.$skipWhile]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$firstWhere]: [E, [dart.functionType(core.bool, [E])], {rEls: dart.functionType(E, [])}],
        [core.$lastWhere]: [E, [dart.functionType(core.bool, [E])], {rEls: dart.functionType(E, [])}],
        [core.$singleWhere]: [E, [dart.functionType(core.bool, [E])]],
        [core.$elementAt]: [E, [core.int]]
      }),
      statics: () => ({
        iterableToShortString: [core.String, [core.Iterable], [core.String, core.String]],
        iterableToFullString: [core.String, [core.Iterable], [core.String, core.String]],
        _isToStringVisiting: [core.bool, [core.Object]],
        _iterablePartsToStrings: [dart.void, [core.Iterable, core.List]]
      }),
      names: ['iterableToShortString', 'iterableToFullString', '_isToStringVisiting', '_iterablePartsToStrings']
    });
    return IterableBase;
  });
  let IterableBase = IterableBase$();
  dart.defineLazyProperties(IterableBase, {
    get _toStringVisiting() {
      return [];
    }
  });
  let _iterator = Symbol('_iterator');
  let _state = Symbol('_state');
  let _move = Symbol('_move');
  let HasNextIterator$ = dart.generic(function(E) {
    class HasNextIterator extends core.Object {
      HasNextIterator(iterator) {
        this[_iterator] = iterator;
        this[_state] = HasNextIterator$()._NOT_MOVED_YET;
      }
      get hasNext() {
        if (this[_state] == HasNextIterator$()._NOT_MOVED_YET)
          this[_move]();
        return this[_state] == HasNextIterator$()._HAS_NEXT_AND_NEXT_IN_CURRENT;
      }
      next() {
        if (!dart.notNull(this.hasNext))
          throw new core.StateError("No more elements");
        dart.assert(this[_state] == HasNextIterator$()._HAS_NEXT_AND_NEXT_IN_CURRENT);
        let result = dart.as(this[_iterator].current, E);
        this[_move]();
        return result;
      }
      [_move]() {
        if (this[_iterator].moveNext()) {
          this[_state] = HasNextIterator$()._HAS_NEXT_AND_NEXT_IN_CURRENT;
        } else {
          this[_state] = HasNextIterator$()._NO_NEXT;
        }
      }
    }
    dart.setSignature(HasNextIterator, {
      methods: () => ({
        next: [E, []],
        [_move]: [dart.void, []]
      })
    });
    return HasNextIterator;
  });
  let HasNextIterator = HasNextIterator$();
  HasNextIterator._HAS_NEXT_AND_NEXT_IN_CURRENT = 0;
  HasNextIterator._NO_NEXT = 1;
  HasNextIterator._NOT_MOVED_YET = 2;
  let LinkedHashMap$ = dart.generic(function(K, V) {
    class LinkedHashMap extends core.Object {
      LinkedHashMap(opts) {
        let equals = opts && 'equals' in opts ? opts.equals : null;
        let hashCode = opts && 'hashCode' in opts ? opts.hashCode : null;
        let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
        if (isValidKey == null) {
          if (hashCode == null) {
            if (equals == null) {
              return new (_LinkedHashMap$(K, V))();
            }
            hashCode = _defaultHashCode;
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new (_LinkedIdentityHashMap$(K, V))();
            }
            if (equals == null) {
              equals = _defaultEquals;
            }
          }
        } else {
          if (hashCode == null) {
            hashCode = _defaultHashCode;
          }
          if (equals == null) {
            equals = _defaultEquals;
          }
        }
        return new (_LinkedCustomHashMap$(K, V))(equals, hashCode, isValidKey);
      }
      identity() {
        return new (_LinkedIdentityHashMap$(K, V))();
      }
      from(other) {
        let result = new (LinkedHashMap$(K, V))();
        other.forEach(dart.fn((k, v) => {
          result.set(k, dart.as(v, V));
        }));
        return result;
      }
      fromIterable(iterable, opts) {
        let key = opts && 'key' in opts ? opts.key : null;
        let value = opts && 'value' in opts ? opts.value : null;
        let map = new (LinkedHashMap$(K, V))();
        Maps._fillMapWithMappedIterable(map, iterable, key, value);
        return map;
      }
      fromIterables(keys, values) {
        let map = new (LinkedHashMap$(K, V))();
        Maps._fillMapWithIterables(map, keys, values);
        return map;
      }
      _literal(keyValuePairs) {
        return dart.as(_js_helper.fillLiteralMap(keyValuePairs, new (_LinkedHashMap$(K, V))()), LinkedHashMap$(K, V));
      }
      _empty() {
        return new (_LinkedHashMap$(K, V))();
      }
    }
    LinkedHashMap[dart.implements] = () => [HashMap$(K, V)];
    dart.defineNamedConstructor(LinkedHashMap, 'identity');
    dart.defineNamedConstructor(LinkedHashMap, 'from');
    dart.defineNamedConstructor(LinkedHashMap, 'fromIterable');
    dart.defineNamedConstructor(LinkedHashMap, 'fromIterables');
    dart.defineNamedConstructor(LinkedHashMap, '_literal');
    dart.defineNamedConstructor(LinkedHashMap, '_empty');
    return LinkedHashMap;
  });
  let LinkedHashMap = LinkedHashMap$();
  let LinkedHashSet$ = dart.generic(function(E) {
    class LinkedHashSet extends core.Object {
      LinkedHashSet(opts) {
        let equals = opts && 'equals' in opts ? opts.equals : null;
        let hashCode = opts && 'hashCode' in opts ? opts.hashCode : null;
        let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
        if (isValidKey == null) {
          if (hashCode == null) {
            if (equals == null) {
              return new (_LinkedHashSet$(E))();
            }
            hashCode = _defaultHashCode;
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new (_LinkedIdentityHashSet$(E))();
            }
            if (equals == null) {
              equals = _defaultEquals;
            }
          }
        } else {
          if (hashCode == null) {
            hashCode = _defaultHashCode;
          }
          if (equals == null) {
            equals = _defaultEquals;
          }
        }
        return new (_LinkedCustomHashSet$(E))(equals, hashCode, isValidKey);
      }
      identity() {
        return new (_LinkedIdentityHashSet$(E))();
      }
      from(elements) {
        let result = new (LinkedHashSet$(E))();
        for (let element of elements) {
          result.add(element);
        }
        return result;
      }
      [Symbol.iterator]() {
        return new dart.JsIterator(this[core.$iterator]);
      }
    }
    LinkedHashSet[dart.implements] = () => [HashSet$(E)];
    dart.defineNamedConstructor(LinkedHashSet, 'identity');
    dart.defineNamedConstructor(LinkedHashSet, 'from');
    return LinkedHashSet;
  });
  let LinkedHashSet = LinkedHashSet$();
  let _modificationCount = Symbol('_modificationCount');
  let _length = Symbol('_length');
  let _next = Symbol('_next');
  let _previous = Symbol('_previous');
  let _insertAfter = Symbol('_insertAfter');
  let _list = Symbol('_list');
  let _unlink = Symbol('_unlink');
  let LinkedList$ = dart.generic(function(E) {
    class LinkedList extends IterableBase$(E) {
      LinkedList() {
        this[_modificationCount] = 0;
        this[_length] = 0;
        this[_next] = null;
        this[_previous] = null;
        super.IterableBase();
        this[_next] = this[_previous] = this;
      }
      addFirst(entry) {
        dart.as(entry, E);
        this[_insertAfter](this, entry);
      }
      add(entry) {
        dart.as(entry, E);
        this[_insertAfter](this[_previous], entry);
      }
      addAll(entries) {
        dart.as(entries, core.Iterable$(E));
        entries[core.$forEach](dart.fn((entry => this[_insertAfter](this[_previous], dart.as(entry, E))).bind(this), dart.void, [core.Object]));
      }
      remove(entry) {
        dart.as(entry, E);
        if (!dart.equals(entry[_list], this))
          return false;
        this[_unlink](entry);
        return true;
      }
      get [core.$iterator]() {
        return new (_LinkedListIterator$(E))(this);
      }
      get [core.$length]() {
        return this[_length];
      }
      clear() {
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        let next = this[_next];
        while (!dart.notNull(core.identical(next, this))) {
          let entry = dart.as(next, E);
          next = entry[_next];
          entry[_next] = entry[_previous] = entry[_list] = null;
        }
        this[_next] = this[_previous] = this;
        this[_length] = 0;
      }
      get [core.$first]() {
        if (core.identical(this[_next], this)) {
          throw new core.StateError('No such element');
        }
        return dart.as(this[_next], E);
      }
      get [core.$last]() {
        if (core.identical(this[_previous], this)) {
          throw new core.StateError('No such element');
        }
        return dart.as(this[_previous], E);
      }
      get [core.$single]() {
        if (core.identical(this[_previous], this)) {
          throw new core.StateError('No such element');
        }
        if (!dart.notNull(core.identical(this[_previous], this[_next]))) {
          throw new core.StateError('Too many elements');
        }
        return dart.as(this[_next], E);
      }
      [core.$forEach](action) {
        dart.as(action, dart.functionType(dart.void, [E]));
        let modificationCount = this[_modificationCount];
        let current = this[_next];
        while (!dart.notNull(core.identical(current, this))) {
          action(dart.as(current, E));
          if (modificationCount != this[_modificationCount]) {
            throw new core.ConcurrentModificationError(this);
          }
          current = current[_next];
        }
      }
      get [core.$isEmpty]() {
        return this[_length] == 0;
      }
      [_insertAfter](entry, newEntry) {
        dart.as(newEntry, E);
        if (newEntry.list != null) {
          throw new core.StateError('LinkedListEntry is already in a LinkedList');
        }
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        newEntry[_list] = this;
        let predecessor = entry;
        let successor = entry[_next];
        successor[_previous] = newEntry;
        newEntry[_previous] = predecessor;
        newEntry[_next] = successor;
        predecessor[_next] = newEntry;
        this[_length] = dart.notNull(this[_length]) + 1;
      }
      [_unlink](entry) {
        dart.as(entry, LinkedListEntry$(E));
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        entry[_next][_previous] = entry[_previous];
        entry[_previous][_next] = entry[_next];
        this[_length] = dart.notNull(this[_length]) - 1;
        entry[_list] = entry[_next] = entry[_previous] = null;
      }
    }
    LinkedList[dart.implements] = () => [_LinkedListLink];
    dart.setSignature(LinkedList, {
      methods: () => ({
        addFirst: [dart.void, [E]],
        add: [dart.void, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        remove: [core.bool, [E]],
        clear: [dart.void, []],
        [core.$forEach]: [dart.void, [dart.functionType(dart.void, [E])]],
        [_insertAfter]: [dart.void, [_LinkedListLink, E]],
        [_unlink]: [dart.void, [LinkedListEntry$(E)]]
      })
    });
    return LinkedList;
  });
  let LinkedList = LinkedList$();
  let _current = Symbol('_current');
  let _LinkedListIterator$ = dart.generic(function(E) {
    class _LinkedListIterator extends core.Object {
      _LinkedListIterator(list) {
        this[_list] = list;
        this[_modificationCount] = list[_modificationCount];
        this[_next] = list[_next];
        this[_current] = null;
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        if (core.identical(this[_next], this[_list])) {
          this[_current] = null;
          return false;
        }
        if (this[_modificationCount] != this[_list][_modificationCount]) {
          throw new core.ConcurrentModificationError(this);
        }
        this[_current] = dart.as(this[_next], E);
        this[_next] = this[_next][_next];
        return true;
      }
    }
    _LinkedListIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setSignature(_LinkedListIterator, {
      methods: () => ({moveNext: [core.bool, []]})
    });
    return _LinkedListIterator;
  });
  let _LinkedListIterator = _LinkedListIterator$();
  class _LinkedListLink extends core.Object {
    _LinkedListLink() {
      this[_next] = null;
      this[_previous] = null;
    }
  }
  let LinkedListEntry$ = dart.generic(function(E) {
    class LinkedListEntry extends core.Object {
      LinkedListEntry() {
        this[_list] = null;
        this[_next] = null;
        this[_previous] = null;
      }
      get list() {
        return this[_list];
      }
      unlink() {
        this[_list][_unlink](this);
      }
      get next() {
        if (core.identical(this[_next], this[_list]))
          return null;
        let result = dart.as(this[_next], E);
        return result;
      }
      get previous() {
        if (core.identical(this[_previous], this[_list]))
          return null;
        return dart.as(this[_previous], E);
      }
      insertAfter(entry) {
        dart.as(entry, E);
        this[_list][_insertAfter](this, entry);
      }
      insertBefore(entry) {
        dart.as(entry, E);
        this[_list][_insertAfter](this[_previous], entry);
      }
    }
    LinkedListEntry[dart.implements] = () => [_LinkedListLink];
    dart.setSignature(LinkedListEntry, {
      methods: () => ({
        unlink: [dart.void, []],
        insertAfter: [dart.void, [E]],
        insertBefore: [dart.void, [E]]
      })
    });
    return LinkedListEntry;
  });
  let LinkedListEntry = LinkedListEntry$();
  let ListMixin$ = dart.generic(function(E) {
    class ListMixin extends core.Object {
      get [core.$iterator]() {
        return new (_internal.ListIterator$(E))(this);
      }
      [Symbol.iterator]() {
        return new dart.JsIterator(this[core.$iterator]);
      }
      [core.$elementAt](index) {
        return this[core.$get](index);
      }
      [core.$forEach](action) {
        dart.as(action, dart.functionType(dart.void, [E]));
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          action(this[core.$get](i));
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
      }
      get [core.$isEmpty]() {
        return this[core.$length] == 0;
      }
      get [core.$isNotEmpty]() {
        return !dart.notNull(this[core.$isEmpty]);
      }
      get [core.$first]() {
        if (this[core.$length] == 0)
          throw _internal.IterableElementError.noElement();
        return this[core.$get](0);
      }
      get [core.$last]() {
        if (this[core.$length] == 0)
          throw _internal.IterableElementError.noElement();
        return this[core.$get](dart.notNull(this[core.$length]) - 1);
      }
      get [core.$single]() {
        if (this[core.$length] == 0)
          throw _internal.IterableElementError.noElement();
        if (dart.notNull(this[core.$length]) > 1)
          throw _internal.IterableElementError.tooMany();
        return this[core.$get](0);
      }
      [core.$contains](element) {
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(this[core.$length]); i = dart.notNull(i) + 1) {
          if (dart.equals(this[core.$get](i), element))
            return true;
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return false;
      }
      [core.$every](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          if (!dart.notNull(test(this[core.$get](i))))
            return false;
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return true;
      }
      [core.$any](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          if (test(this[core.$get](i)))
            return true;
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return false;
      }
      [core.$firstWhere](test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let element = this[core.$get](i);
          if (test(element))
            return element;
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (orElse != null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      [core.$lastWhere](test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        let length = this[core.$length];
        for (let i = dart.notNull(length) - 1; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
          let element = this[core.$get](i);
          if (test(element))
            return element;
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (orElse != null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      [core.$singleWhere](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let length = this[core.$length];
        let match = null;
        let matchFound = false;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let element = this[core.$get](i);
          if (test(element)) {
            if (matchFound) {
              throw _internal.IterableElementError.tooMany();
            }
            matchFound = true;
            match = element;
          }
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (matchFound)
          return match;
        throw _internal.IterableElementError.noElement();
      }
      [core.$join](separator) {
        if (separator === void 0)
          separator = "";
        if (this[core.$length] == 0)
          return "";
        let buffer = new core.StringBuffer();
        buffer.writeAll(this, separator);
        return dart.toString(buffer);
      }
      [core.$where](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.WhereIterable$(E))(this, test);
      }
      [core.$map](f) {
        dart.as(f, dart.functionType(core.Object, [E]));
        return new _internal.MappedListIterable(this, f);
      }
      [core.$expand](f) {
        dart.as(f, dart.functionType(core.Iterable, [E]));
        return new (_internal.ExpandIterable$(E, core.Object))(this, f);
      }
      [core.$reduce](combine) {
        dart.as(combine, dart.functionType(E, [E, E]));
        let length = this[core.$length];
        if (length == 0)
          throw _internal.IterableElementError.noElement();
        let value = this[core.$get](0);
        for (let i = 1; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          value = combine(value, this[core.$get](i));
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return value;
      }
      [core.$fold](initialValue, combine) {
        dart.as(combine, dart.functionType(core.Object, [dart.bottom, E]));
        let value = initialValue;
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          value = dart.dcall(combine, value, this[core.$get](i));
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return value;
      }
      [core.$skip](count) {
        return new (_internal.SubListIterable$(E))(this, count, null);
      }
      [core.$skipWhile](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.SkipWhileIterable$(E))(this, test);
      }
      [core.$take](count) {
        return new (_internal.SubListIterable$(E))(this, 0, count);
      }
      [core.$takeWhile](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.TakeWhileIterable$(E))(this, test);
      }
      [core.$toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        let result = null;
        if (growable) {
          result = new (core.List$(E))();
          result[core.$length] = this[core.$length];
        } else {
          result = new (core.List$(E))(this[core.$length]);
        }
        for (let i = 0; dart.notNull(i) < dart.notNull(this[core.$length]); i = dart.notNull(i) + 1) {
          result[core.$set](i, this[core.$get](i));
        }
        return result;
      }
      [core.$toSet]() {
        let result = new (core.Set$(E))();
        for (let i = 0; dart.notNull(i) < dart.notNull(this[core.$length]); i = dart.notNull(i) + 1) {
          result.add(this[core.$get](i));
        }
        return result;
      }
      [core.$add](element) {
        dart.as(element, E);
        this[core.$set]((() => {
          let x = this[core.$length];
          this[core.$length] = dart.notNull(x) + 1;
          return x;
        }).bind(this)(), element);
      }
      [core.$addAll](iterable) {
        dart.as(iterable, core.Iterable$(E));
        for (let element of iterable) {
          this[core.$set]((() => {
            let x = this[core.$length];
            this[core.$length] = dart.notNull(x) + 1;
            return x;
          }).bind(this)(), element);
        }
      }
      [core.$remove](element) {
        for (let i = 0; dart.notNull(i) < dart.notNull(this[core.$length]); i = dart.notNull(i) + 1) {
          if (dart.equals(this[core.$get](i), element)) {
            this[core.$setRange](i, dart.notNull(this[core.$length]) - 1, this, dart.notNull(i) + 1);
            this[core.$length] = dart.notNull(this[core.$length]) - 1;
            return true;
          }
        }
        return false;
      }
      [core.$removeWhere](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        ListMixin$()._filter(this, test, false);
      }
      [core.$retainWhere](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        ListMixin$()._filter(this, test, true);
      }
      static _filter(source, test, retainMatching) {
        dart.as(test, dart.functionType(core.bool, [dart.bottom]));
        let retained = [];
        let length = source[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let element = source[core.$get](i);
          if (dart.dcall(test, element) == retainMatching) {
            retained[core.$add](element);
          }
          if (length != source[core.$length]) {
            throw new core.ConcurrentModificationError(source);
          }
        }
        if (retained[core.$length] != source[core.$length]) {
          source[core.$setRange](0, retained[core.$length], retained);
          source[core.$length] = retained[core.$length];
        }
      }
      [core.$clear]() {
        this[core.$length] = 0;
      }
      [core.$removeLast]() {
        if (this[core.$length] == 0) {
          throw _internal.IterableElementError.noElement();
        }
        let result = this[core.$get](dart.notNull(this[core.$length]) - 1);
        this[core.$length] = dart.notNull(this[core.$length]) - 1;
        return result;
      }
      [core.$sort](compare) {
        if (compare === void 0)
          compare = null;
        dart.as(compare, dart.functionType(core.int, [E, E]));
        _internal.Sort.sort(this, compare == null ? core.Comparable.compare : compare);
      }
      [core.$shuffle](random) {
        if (random === void 0)
          random = null;
        if (random == null)
          random = new math.Random();
        let length = this[core.$length];
        while (dart.notNull(length) > 1) {
          let pos = random.nextInt(length);
          length = dart.notNull(length) - 1;
          let tmp = this[core.$get](length);
          this[core.$set](length, this[core.$get](pos));
          this[core.$set](pos, tmp);
        }
      }
      [core.$asMap]() {
        return new (_internal.ListMapView$(E))(this);
      }
      [core.$sublist](start, end) {
        if (end === void 0)
          end = null;
        let listLength = this[core.$length];
        if (end == null)
          end = listLength;
        core.RangeError.checkValidRange(start, end, listLength);
        let length = dart.notNull(end) - dart.notNull(start);
        let result = new (core.List$(E))();
        result[core.$length] = length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          result[core.$set](i, this[core.$get](dart.notNull(start) + dart.notNull(i)));
        }
        return result;
      }
      [core.$getRange](start, end) {
        core.RangeError.checkValidRange(start, end, this[core.$length]);
        return new (_internal.SubListIterable$(E))(this, start, end);
      }
      [core.$removeRange](start, end) {
        core.RangeError.checkValidRange(start, end, this[core.$length]);
        let length = dart.notNull(end) - dart.notNull(start);
        this[core.$setRange](start, dart.notNull(this[core.$length]) - dart.notNull(length), this, end);
        this[core.$length] = dart.notNull(this[core.$length]) - dart.notNull(length);
      }
      [core.$fillRange](start, end, fill) {
        if (fill === void 0)
          fill = null;
        dart.as(fill, E);
        core.RangeError.checkValidRange(start, end, this[core.$length]);
        for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
          this[core.$set](i, fill);
        }
      }
      [core.$setRange](start, end, iterable, skipCount) {
        dart.as(iterable, core.Iterable$(E));
        if (skipCount === void 0)
          skipCount = 0;
        core.RangeError.checkValidRange(start, end, this[core.$length]);
        let length = dart.notNull(end) - dart.notNull(start);
        if (length == 0)
          return;
        core.RangeError.checkNotNegative(skipCount, "skipCount");
        let otherList = null;
        let otherStart = null;
        if (dart.is(iterable, core.List)) {
          otherList = dart.as(iterable, core.List);
          otherStart = skipCount;
        } else {
          otherList = iterable[core.$skip](skipCount)[core.$toList]({growable: false});
          otherStart = 0;
        }
        if (dart.notNull(otherStart) + dart.notNull(length) > dart.notNull(otherList[core.$length])) {
          throw _internal.IterableElementError.tooFew();
        }
        if (dart.notNull(otherStart) < dart.notNull(start)) {
          for (let i = dart.notNull(length) - 1; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
            this[core.$set](dart.notNull(start) + dart.notNull(i), dart.as(otherList[core.$get](dart.notNull(otherStart) + dart.notNull(i)), E));
          }
        } else {
          for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
            this[core.$set](dart.notNull(start) + dart.notNull(i), dart.as(otherList[core.$get](dart.notNull(otherStart) + dart.notNull(i)), E));
          }
        }
      }
      [core.$replaceRange](start, end, newContents) {
        dart.as(newContents, core.Iterable$(E));
        core.RangeError.checkValidRange(start, end, this[core.$length]);
        if (!dart.is(newContents, _internal.EfficientLength)) {
          newContents = newContents[core.$toList]();
        }
        let removeLength = dart.notNull(end) - dart.notNull(start);
        let insertLength = newContents[core.$length];
        if (dart.notNull(removeLength) >= dart.notNull(insertLength)) {
          let delta = dart.notNull(removeLength) - dart.notNull(insertLength);
          let insertEnd = dart.notNull(start) + dart.notNull(insertLength);
          let newLength = dart.notNull(this[core.$length]) - dart.notNull(delta);
          this[core.$setRange](start, insertEnd, newContents);
          if (delta != 0) {
            this[core.$setRange](insertEnd, newLength, this, end);
            this[core.$length] = newLength;
          }
        } else {
          let delta = dart.notNull(insertLength) - dart.notNull(removeLength);
          let newLength = dart.notNull(this[core.$length]) + dart.notNull(delta);
          let insertEnd = dart.notNull(start) + dart.notNull(insertLength);
          this[core.$length] = newLength;
          this[core.$setRange](insertEnd, newLength, this, end);
          this[core.$setRange](start, insertEnd, newContents);
        }
      }
      [core.$indexOf](element, startIndex) {
        if (startIndex === void 0)
          startIndex = 0;
        if (dart.notNull(startIndex) >= dart.notNull(this[core.$length])) {
          return -1;
        }
        if (dart.notNull(startIndex) < 0) {
          startIndex = 0;
        }
        for (let i = startIndex; dart.notNull(i) < dart.notNull(this[core.$length]); i = dart.notNull(i) + 1) {
          if (dart.equals(this[core.$get](i), element)) {
            return i;
          }
        }
        return -1;
      }
      [core.$lastIndexOf](element, startIndex) {
        if (startIndex === void 0)
          startIndex = null;
        if (startIndex == null) {
          startIndex = dart.notNull(this[core.$length]) - 1;
        } else {
          if (dart.notNull(startIndex) < 0) {
            return -1;
          }
          if (dart.notNull(startIndex) >= dart.notNull(this[core.$length])) {
            startIndex = dart.notNull(this[core.$length]) - 1;
          }
        }
        for (let i = startIndex; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
          if (dart.equals(this[core.$get](i), element)) {
            return i;
          }
        }
        return -1;
      }
      [core.$insert](index, element) {
        dart.as(element, E);
        core.RangeError.checkValueInInterval(index, 0, this[core.$length], "index");
        if (index == this[core.$length]) {
          this[core.$add](element);
          return;
        }
        if (!(typeof index == 'number'))
          throw new core.ArgumentError(index);
        this[core.$length] = dart.notNull(this[core.$length]) + 1;
        this[core.$setRange](dart.notNull(index) + 1, this[core.$length], this, index);
        this[core.$set](index, element);
      }
      [core.$removeAt](index) {
        let result = this[core.$get](index);
        this[core.$setRange](index, dart.notNull(this[core.$length]) - 1, this, dart.notNull(index) + 1);
        this[core.$length] = dart.notNull(this[core.$length]) - 1;
        return result;
      }
      [core.$insertAll](index, iterable) {
        dart.as(iterable, core.Iterable$(E));
        core.RangeError.checkValueInInterval(index, 0, this[core.$length], "index");
        if (dart.is(iterable, _internal.EfficientLength)) {
          iterable = iterable[core.$toList]();
        }
        let insertionLength = iterable[core.$length];
        this[core.$length] = dart.notNull(this[core.$length]) + dart.notNull(insertionLength);
        this[core.$setRange](dart.notNull(index) + dart.notNull(insertionLength), this[core.$length], this, index);
        this[core.$setAll](index, iterable);
      }
      [core.$setAll](index, iterable) {
        dart.as(iterable, core.Iterable$(E));
        if (dart.is(iterable, core.List)) {
          this[core.$setRange](index, dart.notNull(index) + dart.notNull(iterable[core.$length]), iterable);
        } else {
          for (let element of iterable) {
            this[core.$set]((() => {
              let x = index;
              index = dart.notNull(x) + 1;
              return x;
            })(), element);
          }
        }
      }
      get [core.$reversed]() {
        return new (_internal.ReversedListIterable$(E))(this);
      }
      [core.$toString]() {
        return IterableBase.iterableToFullString(this, '[', ']');
      }
    }
    ListMixin[dart.implements] = () => [core.List$(E)];
    dart.setSignature(ListMixin, {
      methods: () => ({
        [core.$elementAt]: [E, [core.int]],
        [core.$forEach]: [dart.void, [dart.functionType(dart.void, [E])]],
        [core.$contains]: [core.bool, [core.Object]],
        [core.$every]: [core.bool, [dart.functionType(core.bool, [E])]],
        [core.$any]: [core.bool, [dart.functionType(core.bool, [E])]],
        [core.$firstWhere]: [E, [dart.functionType(core.bool, [E])], {rEls: dart.functionType(E, [])}],
        [core.$lastWhere]: [E, [dart.functionType(core.bool, [E])], {rEls: dart.functionType(E, [])}],
        [core.$singleWhere]: [E, [dart.functionType(core.bool, [E])]],
        [core.$join]: [core.String, [], [core.String]],
        [core.$where]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$map]: [core.Iterable, [dart.functionType(core.Object, [E])]],
        [core.$expand]: [core.Iterable, [dart.functionType(core.Iterable, [E])]],
        [core.$reduce]: [E, [dart.functionType(E, [E, E])]],
        [core.$fold]: [core.Object, [core.Object, dart.functionType(core.Object, [dart.bottom, E])]],
        [core.$skip]: [core.Iterable$(E), [core.int]],
        [core.$skipWhile]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$take]: [core.Iterable$(E), [core.int]],
        [core.$takeWhile]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [core.$toList]: [core.List$(E), [], {rowabl: core.bool}],
        [core.$toSet]: [core.Set$(E), []],
        [core.$add]: [dart.void, [E]],
        [core.$addAll]: [dart.void, [core.Iterable$(E)]],
        [core.$remove]: [core.bool, [core.Object]],
        [core.$removeWhere]: [dart.void, [dart.functionType(core.bool, [E])]],
        [core.$retainWhere]: [dart.void, [dart.functionType(core.bool, [E])]],
        [core.$clear]: [dart.void, []],
        [core.$removeLast]: [E, []],
        [core.$sort]: [dart.void, [], [dart.functionType(core.int, [E, E])]],
        [core.$shuffle]: [dart.void, [], [math.Random]],
        [core.$asMap]: [core.Map$(core.int, E), []],
        [core.$sublist]: [core.List$(E), [core.int], [core.int]],
        [core.$getRange]: [core.Iterable$(E), [core.int, core.int]],
        [core.$removeRange]: [dart.void, [core.int, core.int]],
        [core.$fillRange]: [dart.void, [core.int, core.int], [E]],
        [core.$setRange]: [dart.void, [core.int, core.int, core.Iterable$(E)], [core.int]],
        [core.$replaceRange]: [dart.void, [core.int, core.int, core.Iterable$(E)]],
        [core.$indexOf]: [core.int, [core.Object], [core.int]],
        [core.$lastIndexOf]: [core.int, [core.Object], [core.int]],
        [core.$insert]: [dart.void, [core.int, E]],
        [core.$removeAt]: [E, [core.int]],
        [core.$insertAll]: [dart.void, [core.int, core.Iterable$(E)]],
        [core.$setAll]: [dart.void, [core.int, core.Iterable$(E)]]
      }),
      statics: () => ({_filter: [dart.void, [core.List, dart.functionType(core.bool, [dart.bottom]), core.bool]]}),
      names: ['_filter']
    });
    return ListMixin;
  });
  let ListMixin = ListMixin$();
  let ListBase$ = dart.generic(function(E) {
    class ListBase extends dart.mixin(core.Object, ListMixin$(E)) {
      static listToString(list) {
        return IterableBase.iterableToFullString(list, '[', ']');
      }
    }
    dart.setSignature(ListBase, {
      statics: () => ({listToString: [core.String, [core.List]]}),
      names: ['listToString']
    });
    return ListBase;
  });
  let ListBase = ListBase$();
  let MapMixin$ = dart.generic(function(K, V) {
    class MapMixin extends core.Object {
      forEach(action) {
        dart.as(action, dart.functionType(dart.void, [K, V]));
        for (let key of this.keys) {
          action(key, this.get(key));
        }
      }
      addAll(other) {
        dart.as(other, core.Map$(K, V));
        for (let key of other.keys) {
          this.set(key, other.get(key));
        }
      }
      containsValue(value) {
        for (let key of this.keys) {
          if (dart.equals(this.get(key), value))
            return true;
        }
        return false;
      }
      putIfAbsent(key, ifAbsent) {
        dart.as(key, K);
        dart.as(ifAbsent, dart.functionType(V, []));
        if (this.keys[core.$contains](key)) {
          return this.get(key);
        }
        return this.set(key, ifAbsent());
      }
      containsKey(key) {
        return this.keys[core.$contains](key);
      }
      get length() {
        return this.keys[core.$length];
      }
      get isEmpty() {
        return this.keys[core.$isEmpty];
      }
      get isNotEmpty() {
        return this.keys[core.$isNotEmpty];
      }
      get values() {
        return new (_MapBaseValueIterable$(V))(this);
      }
      toString() {
        return Maps.mapToString(this);
      }
    }
    MapMixin[dart.implements] = () => [core.Map$(K, V)];
    dart.setSignature(MapMixin, {
      methods: () => ({
        forEach: [dart.void, [dart.functionType(dart.void, [K, V])]],
        addAll: [dart.void, [core.Map$(K, V)]],
        containsValue: [core.bool, [core.Object]],
        putIfAbsent: [V, [K, dart.functionType(V, [])]],
        containsKey: [core.bool, [core.Object]]
      })
    });
    return MapMixin;
  });
  let MapMixin = MapMixin$();
  let MapBase$ = dart.generic(function(K, V) {
    class MapBase extends dart.mixin(core.Object, MapMixin$(K, V)) {}
    return MapBase;
  });
  let MapBase = MapBase$();
  let _UnmodifiableMapMixin$ = dart.generic(function(K, V) {
    class _UnmodifiableMapMixin extends core.Object {
      set(key, value) {
        dart.as(key, K);
        dart.as(value, V);
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      addAll(other) {
        dart.as(other, core.Map$(K, V));
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      clear() {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      remove(key) {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      putIfAbsent(key, ifAbsent) {
        dart.as(key, K);
        dart.as(ifAbsent, dart.functionType(V, []));
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
    }
    _UnmodifiableMapMixin[dart.implements] = () => [core.Map$(K, V)];
    dart.setSignature(_UnmodifiableMapMixin, {
      methods: () => ({
        set: [dart.void, [K, V]],
        addAll: [dart.void, [core.Map$(K, V)]],
        clear: [dart.void, []],
        remove: [V, [core.Object]],
        putIfAbsent: [V, [K, dart.functionType(V, [])]]
      })
    });
    return _UnmodifiableMapMixin;
  });
  let _UnmodifiableMapMixin = _UnmodifiableMapMixin$();
  let UnmodifiableMapBase$ = dart.generic(function(K, V) {
    class UnmodifiableMapBase extends dart.mixin(MapBase$(K, V), _UnmodifiableMapMixin$(K, V)) {}
    return UnmodifiableMapBase;
  });
  let UnmodifiableMapBase = UnmodifiableMapBase$();
  let _map = Symbol('_map');
  let _MapBaseValueIterable$ = dart.generic(function(V) {
    class _MapBaseValueIterable extends IterableBase$(V) {
      _MapBaseValueIterable(map) {
        this[_map] = map;
        super.IterableBase();
      }
      get [core.$length]() {
        return this[_map].length;
      }
      get [core.$isEmpty]() {
        return this[_map].isEmpty;
      }
      get [core.$isNotEmpty]() {
        return this[_map].isNotEmpty;
      }
      get [core.$first]() {
        return dart.as(this[_map].get(this[_map].keys[core.$first]), V);
      }
      get [core.$single]() {
        return dart.as(this[_map].get(this[_map].keys[core.$single]), V);
      }
      get [core.$last]() {
        return dart.as(this[_map].get(this[_map].keys[core.$last]), V);
      }
      get [core.$iterator]() {
        return new (_MapBaseValueIterator$(V))(this[_map]);
      }
    }
    _MapBaseValueIterable[dart.implements] = () => [_internal.EfficientLength];
    return _MapBaseValueIterable;
  });
  let _MapBaseValueIterable = _MapBaseValueIterable$();
  let _keys = Symbol('_keys');
  let _MapBaseValueIterator$ = dart.generic(function(V) {
    class _MapBaseValueIterator extends core.Object {
      _MapBaseValueIterator(map) {
        this[_map] = map;
        this[_keys] = map.keys[core.$iterator];
        this[_current] = null;
      }
      moveNext() {
        if (this[_keys].moveNext()) {
          this[_current] = dart.as(this[_map].get(this[_keys].current), V);
          return true;
        }
        this[_current] = null;
        return false;
      }
      get current() {
        return this[_current];
      }
    }
    _MapBaseValueIterator[dart.implements] = () => [core.Iterator$(V)];
    dart.setSignature(_MapBaseValueIterator, {
      methods: () => ({moveNext: [core.bool, []]})
    });
    return _MapBaseValueIterator;
  });
  let _MapBaseValueIterator = _MapBaseValueIterator$();
  let MapView$ = dart.generic(function(K, V) {
    class MapView extends core.Object {
      MapView(map) {
        this[_map] = map;
      }
      get(key) {
        return this[_map].get(key);
      }
      set(key, value) {
        dart.as(key, K);
        dart.as(value, V);
        this[_map].set(key, value);
      }
      addAll(other) {
        dart.as(other, core.Map$(K, V));
        this[_map].addAll(other);
      }
      clear() {
        this[_map].clear();
      }
      putIfAbsent(key, ifAbsent) {
        dart.as(key, K);
        dart.as(ifAbsent, dart.functionType(V, []));
        return this[_map].putIfAbsent(key, ifAbsent);
      }
      containsKey(key) {
        return this[_map].containsKey(key);
      }
      containsValue(value) {
        return this[_map].containsValue(value);
      }
      forEach(action) {
        dart.as(action, dart.functionType(dart.void, [K, V]));
        this[_map].forEach(action);
      }
      get isEmpty() {
        return this[_map].isEmpty;
      }
      get isNotEmpty() {
        return this[_map].isNotEmpty;
      }
      get length() {
        return this[_map].length;
      }
      get keys() {
        return this[_map].keys;
      }
      remove(key) {
        return this[_map].remove(key);
      }
      toString() {
        return dart.toString(this[_map]);
      }
      get values() {
        return this[_map].values;
      }
    }
    MapView[dart.implements] = () => [core.Map$(K, V)];
    dart.setSignature(MapView, {
      methods: () => ({
        get: [V, [core.Object]],
        set: [dart.void, [K, V]],
        addAll: [dart.void, [core.Map$(K, V)]],
        clear: [dart.void, []],
        putIfAbsent: [V, [K, dart.functionType(V, [])]],
        containsKey: [core.bool, [core.Object]],
        containsValue: [core.bool, [core.Object]],
        forEach: [dart.void, [dart.functionType(dart.void, [K, V])]],
        remove: [V, [core.Object]]
      })
    });
    return MapView;
  });
  let MapView = MapView$();
  let UnmodifiableMapView$ = dart.generic(function(K, V) {
    class UnmodifiableMapView extends dart.mixin(MapView$(K, V), _UnmodifiableMapMixin$(K, V)) {}
    return UnmodifiableMapView;
  });
  let UnmodifiableMapView = UnmodifiableMapView$();
  class Maps extends core.Object {
    static containsValue(map, value) {
      for (let v of map.values) {
        if (dart.equals(value, v)) {
          return true;
        }
      }
      return false;
    }
    static containsKey(map, key) {
      for (let k of map.keys) {
        if (dart.equals(key, k)) {
          return true;
        }
      }
      return false;
    }
    static putIfAbsent(map, key, ifAbsent) {
      if (map.containsKey(key)) {
        return map.get(key);
      }
      let v = ifAbsent();
      map.set(key, v);
      return v;
    }
    static clear(map) {
      for (let k of map.keys[core.$toList]()) {
        map.remove(k);
      }
    }
    static forEach(map, f) {
      for (let k of map.keys) {
        dart.dcall(f, k, map.get(k));
      }
    }
    static getValues(map) {
      return map.keys[core.$map](dart.fn(key => map.get(key)));
    }
    static length(map) {
      return map.keys[core.$length];
    }
    static isEmpty(map) {
      return map.keys[core.$isEmpty];
    }
    static isNotEmpty(map) {
      return map.keys[core.$isNotEmpty];
    }
    static mapToString(m) {
      if (IterableBase._isToStringVisiting(m)) {
        return '{...}';
      }
      let result = new core.StringBuffer();
      try {
        IterableBase._toStringVisiting[core.$add](m);
        result.write('{');
        let first = true;
        m.forEach(dart.fn((k, v) => {
          if (!dart.notNull(first)) {
            result.write(', ');
          }
          first = false;
          result.write(k);
          result.write(': ');
          result.write(v);
        }));
        result.write('}');
      } finally {
        dart.assert(core.identical(IterableBase._toStringVisiting[core.$last], m));
        IterableBase._toStringVisiting[core.$removeLast]();
      }
      return dart.toString(result);
    }
    static _id(x) {
      return x;
    }
    static _fillMapWithMappedIterable(map, iterable, key, value) {
      if (key == null)
        key = Maps._id;
      if (value == null)
        value = Maps._id;
      for (let element of iterable) {
        map.set(dart.dcall(key, element), dart.dcall(value, element));
      }
    }
    static _fillMapWithIterables(map, keys, values) {
      let keyIterator = keys[core.$iterator];
      let valueIterator = values[core.$iterator];
      let hasNextKey = keyIterator.moveNext();
      let hasNextValue = valueIterator.moveNext();
      while (dart.notNull(hasNextKey) && dart.notNull(hasNextValue)) {
        map.set(keyIterator.current, valueIterator.current);
        hasNextKey = keyIterator.moveNext();
        hasNextValue = valueIterator.moveNext();
      }
      if (dart.notNull(hasNextKey) || dart.notNull(hasNextValue)) {
        throw new core.ArgumentError("Iterables do not have same length.");
      }
    }
  }
  dart.setSignature(Maps, {
    statics: () => ({
      containsValue: [core.bool, [core.Map, core.Object]],
      containsKey: [core.bool, [core.Map, core.Object]],
      putIfAbsent: [core.Object, [core.Map, core.Object, dart.functionType(core.Object, [])]],
      clear: [core.Object, [core.Map]],
      forEach: [core.Object, [core.Map, dart.functionType(dart.void, [dart.bottom, dart.bottom])]],
      getValues: [core.Iterable, [core.Map]],
      length: [core.int, [core.Map]],
      isEmpty: [core.bool, [core.Map]],
      isNotEmpty: [core.bool, [core.Map]],
      mapToString: [core.String, [core.Map]],
      _id: [core.Object, [core.Object]],
      _fillMapWithMappedIterable: [dart.void, [core.Map, core.Iterable, dart.functionType(core.Object, [dart.bottom]), dart.functionType(core.Object, [dart.bottom])]],
      _fillMapWithIterables: [dart.void, [core.Map, core.Iterable, core.Iterable]]
    }),
    names: ['containsValue', 'containsKey', 'putIfAbsent', 'clear', 'forEach', 'getValues', 'length', 'isEmpty', 'isNotEmpty', 'mapToString', '_id', '_fillMapWithMappedIterable', '_fillMapWithIterables']
  });
  let Queue$ = dart.generic(function(E) {
    class Queue extends core.Object {
      Queue() {
        return new (ListQueue$(E))();
      }
      from(elements) {
        return new (ListQueue$(E)).from(elements);
      }
      [Symbol.iterator]() {
        return new dart.JsIterator(this[core.$iterator]);
      }
    }
    Queue[dart.implements] = () => [core.Iterable$(E), _internal.EfficientLength];
    dart.defineNamedConstructor(Queue, 'from');
    return Queue;
  });
  let Queue = Queue$();
  let _element = Symbol('_element');
  let _link = Symbol('_link');
  let _asNonSentinelEntry = Symbol('_asNonSentinelEntry');
  let DoubleLinkedQueueEntry$ = dart.generic(function(E) {
    class DoubleLinkedQueueEntry extends core.Object {
      DoubleLinkedQueueEntry(e) {
        this[_element] = e;
        this[_previous] = null;
        this[_next] = null;
      }
      [_link](previous, next) {
        dart.as(previous, DoubleLinkedQueueEntry$(E));
        dart.as(next, DoubleLinkedQueueEntry$(E));
        this[_next] = next;
        this[_previous] = previous;
        previous[_next] = this;
        next[_previous] = this;
      }
      append(e) {
        dart.as(e, E);
        new (DoubleLinkedQueueEntry$(E))(e)[_link](this, this[_next]);
      }
      prepend(e) {
        dart.as(e, E);
        new (DoubleLinkedQueueEntry$(E))(e)[_link](this[_previous], this);
      }
      remove() {
        this[_previous][_next] = this[_next];
        this[_next][_previous] = this[_previous];
        this[_next] = null;
        this[_previous] = null;
        return this[_element];
      }
      [_asNonSentinelEntry]() {
        return this;
      }
      previousEntry() {
        return this[_previous][_asNonSentinelEntry]();
      }
      nextEntry() {
        return this[_next][_asNonSentinelEntry]();
      }
      get element() {
        return this[_element];
      }
      set element(e) {
        dart.as(e, E);
        this[_element] = e;
      }
    }
    dart.setSignature(DoubleLinkedQueueEntry, {
      methods: () => ({
        [_link]: [dart.void, [DoubleLinkedQueueEntry$(E), DoubleLinkedQueueEntry$(E)]],
        append: [dart.void, [E]],
        prepend: [dart.void, [E]],
        remove: [E, []],
        [_asNonSentinelEntry]: [DoubleLinkedQueueEntry$(E), []],
        previousEntry: [DoubleLinkedQueueEntry$(E), []],
        nextEntry: [DoubleLinkedQueueEntry$(E), []]
      })
    });
    return DoubleLinkedQueueEntry;
  });
  let DoubleLinkedQueueEntry = DoubleLinkedQueueEntry$();
  let _DoubleLinkedQueueEntrySentinel$ = dart.generic(function(E) {
    class _DoubleLinkedQueueEntrySentinel extends DoubleLinkedQueueEntry$(E) {
      _DoubleLinkedQueueEntrySentinel() {
        super.DoubleLinkedQueueEntry(null);
        this[_link](this, this);
      }
      remove() {
        throw _internal.IterableElementError.noElement();
      }
      [_asNonSentinelEntry]() {
        return null;
      }
      set element(e) {
        dart.as(e, E);
        dart.assert(false);
      }
      get element() {
        throw _internal.IterableElementError.noElement();
      }
    }
    dart.setSignature(_DoubleLinkedQueueEntrySentinel, {
      methods: () => ({
        remove: [E, []],
        [_asNonSentinelEntry]: [DoubleLinkedQueueEntry$(E), []]
      })
    });
    return _DoubleLinkedQueueEntrySentinel;
  });
  let _DoubleLinkedQueueEntrySentinel = _DoubleLinkedQueueEntrySentinel$();
  let _sentinel = Symbol('_sentinel');
  let _elementCount = Symbol('_elementCount');
  let _filter = Symbol('_filter');
  let DoubleLinkedQueue$ = dart.generic(function(E) {
    class DoubleLinkedQueue extends IterableBase$(E) {
      DoubleLinkedQueue() {
        this[_sentinel] = null;
        this[_elementCount] = 0;
        super.IterableBase();
        this[_sentinel] = new (_DoubleLinkedQueueEntrySentinel$(E))();
      }
      from(elements) {
        let list = new (DoubleLinkedQueue$(E))();
        for (let e of dart.as(elements, core.Iterable$(E))) {
          list.addLast(e);
        }
        return dart.as(list, DoubleLinkedQueue$(E));
      }
      get [core.$length]() {
        return this[_elementCount];
      }
      addLast(value) {
        dart.as(value, E);
        this[_sentinel].prepend(value);
        this[_elementCount] = dart.notNull(this[_elementCount]) + 1;
      }
      addFirst(value) {
        dart.as(value, E);
        this[_sentinel].append(value);
        this[_elementCount] = dart.notNull(this[_elementCount]) + 1;
      }
      add(value) {
        dart.as(value, E);
        this[_sentinel].prepend(value);
        this[_elementCount] = dart.notNull(this[_elementCount]) + 1;
      }
      addAll(iterable) {
        dart.as(iterable, core.Iterable$(E));
        for (let value of iterable) {
          this[_sentinel].prepend(value);
          this[_elementCount] = dart.notNull(this[_elementCount]) + 1;
        }
      }
      removeLast() {
        let result = this[_sentinel][_previous].remove();
        this[_elementCount] = dart.notNull(this[_elementCount]) - 1;
        return result;
      }
      removeFirst() {
        let result = this[_sentinel][_next].remove();
        this[_elementCount] = dart.notNull(this[_elementCount]) - 1;
        return result;
      }
      remove(o) {
        let entry = this[_sentinel][_next];
        while (!dart.notNull(core.identical(entry, this[_sentinel]))) {
          if (dart.equals(entry.element, o)) {
            entry.remove();
            this[_elementCount] = dart.notNull(this[_elementCount]) - 1;
            return true;
          }
          entry = entry[_next];
        }
        return false;
      }
      [_filter](test, removeMatching) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let entry = this[_sentinel][_next];
        while (!dart.notNull(core.identical(entry, this[_sentinel]))) {
          let next = entry[_next];
          if (core.identical(removeMatching, test(entry.element))) {
            entry.remove();
            this[_elementCount] = dart.notNull(this[_elementCount]) - 1;
          }
          entry = next;
        }
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_filter](test, true);
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_filter](test, false);
      }
      get [core.$first]() {
        return this[_sentinel][_next].element;
      }
      get [core.$last]() {
        return this[_sentinel][_previous].element;
      }
      get [core.$single]() {
        if (core.identical(this[_sentinel][_next], this[_sentinel][_previous])) {
          return this[_sentinel][_next].element;
        }
        throw _internal.IterableElementError.tooMany();
      }
      lastEntry() {
        return this[_sentinel].previousEntry();
      }
      firstEntry() {
        return this[_sentinel].nextEntry();
      }
      get [core.$isEmpty]() {
        return core.identical(this[_sentinel][_next], this[_sentinel]);
      }
      clear() {
        this[_sentinel][_next] = this[_sentinel];
        this[_sentinel][_previous] = this[_sentinel];
        this[_elementCount] = 0;
      }
      forEachEntry(f) {
        dart.as(f, dart.functionType(dart.void, [DoubleLinkedQueueEntry$(E)]));
        let entry = this[_sentinel][_next];
        while (!dart.notNull(core.identical(entry, this[_sentinel]))) {
          let nextEntry = entry[_next];
          f(entry);
          entry = nextEntry;
        }
      }
      get [core.$iterator]() {
        return new (_DoubleLinkedQueueIterator$(E))(this[_sentinel]);
      }
      toString() {
        return IterableBase.iterableToFullString(this, '{', '}');
      }
    }
    DoubleLinkedQueue[dart.implements] = () => [Queue$(E)];
    dart.defineNamedConstructor(DoubleLinkedQueue, 'from');
    dart.setSignature(DoubleLinkedQueue, {
      methods: () => ({
        addLast: [dart.void, [E]],
        addFirst: [dart.void, [E]],
        add: [dart.void, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        removeLast: [E, []],
        removeFirst: [E, []],
        remove: [core.bool, [core.Object]],
        [_filter]: [dart.void, [dart.functionType(core.bool, [E]), core.bool]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        lastEntry: [DoubleLinkedQueueEntry$(E), []],
        firstEntry: [DoubleLinkedQueueEntry$(E), []],
        clear: [dart.void, []],
        forEachEntry: [dart.void, [dart.functionType(dart.void, [DoubleLinkedQueueEntry$(E)])]]
      })
    });
    return DoubleLinkedQueue;
  });
  let DoubleLinkedQueue = DoubleLinkedQueue$();
  let _nextEntry = Symbol('_nextEntry');
  let _DoubleLinkedQueueIterator$ = dart.generic(function(E) {
    class _DoubleLinkedQueueIterator extends core.Object {
      _DoubleLinkedQueueIterator(sentinel) {
        this[_sentinel] = sentinel;
        this[_nextEntry] = sentinel[_next];
        this[_current] = null;
      }
      moveNext() {
        if (!dart.notNull(core.identical(this[_nextEntry], this[_sentinel]))) {
          this[_current] = this[_nextEntry][_element];
          this[_nextEntry] = this[_nextEntry][_next];
          return true;
        }
        this[_current] = null;
        this[_nextEntry] = this[_sentinel] = null;
        return false;
      }
      get current() {
        return this[_current];
      }
    }
    _DoubleLinkedQueueIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setSignature(_DoubleLinkedQueueIterator, {
      methods: () => ({moveNext: [core.bool, []]})
    });
    return _DoubleLinkedQueueIterator;
  });
  let _DoubleLinkedQueueIterator = _DoubleLinkedQueueIterator$();
  let _head = Symbol('_head');
  let _tail = Symbol('_tail');
  let _table = Symbol('_table');
  let _checkModification = Symbol('_checkModification');
  let _writeToList = Symbol('_writeToList');
  let _add = Symbol('_add');
  let _preGrow = Symbol('_preGrow');
  let _remove = Symbol('_remove');
  let _filterWhere = Symbol('_filterWhere');
  let _grow = Symbol('_grow');
  let ListQueue$ = dart.generic(function(E) {
    class ListQueue extends IterableBase$(E) {
      ListQueue(initialCapacity) {
        if (initialCapacity === void 0)
          initialCapacity = null;
        this[_head] = 0;
        this[_tail] = 0;
        this[_table] = null;
        this[_modificationCount] = 0;
        super.IterableBase();
        if (initialCapacity == null || dart.notNull(initialCapacity) < dart.notNull(ListQueue$()._INITIAL_CAPACITY)) {
          initialCapacity = ListQueue$()._INITIAL_CAPACITY;
        } else if (!dart.notNull(ListQueue$()._isPowerOf2(initialCapacity))) {
          initialCapacity = ListQueue$()._nextPowerOf2(initialCapacity);
        }
        dart.assert(ListQueue$()._isPowerOf2(initialCapacity));
        this[_table] = new (core.List$(E))(initialCapacity);
      }
      from(elements) {
        if (dart.is(elements, core.List)) {
          let length = elements[core.$length];
          let queue = new (ListQueue$(E))(dart.notNull(length) + 1);
          dart.assert(dart.notNull(queue[_table][core.$length]) > dart.notNull(length));
          let sourceList = elements;
          queue[_table][core.$setRange](0, length, dart.as(sourceList, core.Iterable$(E)), 0);
          queue[_tail] = length;
          return queue;
        } else {
          let capacity = ListQueue$()._INITIAL_CAPACITY;
          if (dart.is(elements, _internal.EfficientLength)) {
            capacity = elements[core.$length];
          }
          let result = new (ListQueue$(E))(capacity);
          for (let element of dart.as(elements, core.Iterable$(E))) {
            result.addLast(element);
          }
          return result;
        }
      }
      get [core.$iterator]() {
        return new (_ListQueueIterator$(E))(this);
      }
      [core.$forEach](action) {
        dart.as(action, dart.functionType(dart.void, [E]));
        let modificationCount = this[_modificationCount];
        for (let i = this[_head]; i != this[_tail]; i = dart.notNull(i) + 1 & dart.notNull(this[_table][core.$length]) - 1) {
          action(this[_table][core.$get](i));
          this[_checkModification](modificationCount);
        }
      }
      get [core.$isEmpty]() {
        return this[_head] == this[_tail];
      }
      get [core.$length]() {
        return dart.notNull(this[_tail]) - dart.notNull(this[_head]) & dart.notNull(this[_table][core.$length]) - 1;
      }
      get [core.$first]() {
        if (this[_head] == this[_tail])
          throw _internal.IterableElementError.noElement();
        return this[_table][core.$get](this[_head]);
      }
      get [core.$last]() {
        if (this[_head] == this[_tail])
          throw _internal.IterableElementError.noElement();
        return this[_table][core.$get](dart.notNull(this[_tail]) - 1 & dart.notNull(this[_table][core.$length]) - 1);
      }
      get [core.$single]() {
        if (this[_head] == this[_tail])
          throw _internal.IterableElementError.noElement();
        if (dart.notNull(this[core.$length]) > 1)
          throw _internal.IterableElementError.tooMany();
        return this[_table][core.$get](this[_head]);
      }
      [core.$elementAt](index) {
        core.RangeError.checkValidIndex(index, this);
        return this[_table][core.$get](dart.notNull(this[_head]) + dart.notNull(index) & dart.notNull(this[_table][core.$length]) - 1);
      }
      [core.$toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        let list = null;
        if (growable) {
          list = new (core.List$(E))();
          list[core.$length] = this[core.$length];
        } else {
          list = new (core.List$(E))(this[core.$length]);
        }
        this[_writeToList](list);
        return list;
      }
      add(element) {
        dart.as(element, E);
        this[_add](element);
      }
      addAll(elements) {
        dart.as(elements, core.Iterable$(E));
        if (dart.is(elements, core.List)) {
          let list = dart.as(elements, core.List);
          let addCount = list[core.$length];
          let length = this[core.$length];
          if (dart.notNull(length) + dart.notNull(addCount) >= dart.notNull(this[_table][core.$length])) {
            this[_preGrow](dart.notNull(length) + dart.notNull(addCount));
            this[_table][core.$setRange](length, dart.notNull(length) + dart.notNull(addCount), dart.as(list, core.Iterable$(E)), 0);
            this[_tail] = dart.notNull(this[_tail]) + dart.notNull(addCount);
          } else {
            let endSpace = dart.notNull(this[_table][core.$length]) - dart.notNull(this[_tail]);
            if (dart.notNull(addCount) < dart.notNull(endSpace)) {
              this[_table][core.$setRange](this[_tail], dart.notNull(this[_tail]) + dart.notNull(addCount), dart.as(list, core.Iterable$(E)), 0);
              this[_tail] = dart.notNull(this[_tail]) + dart.notNull(addCount);
            } else {
              let preSpace = dart.notNull(addCount) - dart.notNull(endSpace);
              this[_table][core.$setRange](this[_tail], dart.notNull(this[_tail]) + dart.notNull(endSpace), dart.as(list, core.Iterable$(E)), 0);
              this[_table][core.$setRange](0, preSpace, dart.as(list, core.Iterable$(E)), endSpace);
              this[_tail] = preSpace;
            }
          }
          this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        } else {
          for (let element of elements)
            this[_add](element);
        }
      }
      remove(object) {
        for (let i = this[_head]; i != this[_tail]; i = dart.notNull(i) + 1 & dart.notNull(this[_table][core.$length]) - 1) {
          let element = this[_table][core.$get](i);
          if (dart.equals(element, object)) {
            this[_remove](i);
            this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
            return true;
          }
        }
        return false;
      }
      [_filterWhere](test, removeMatching) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let index = this[_head];
        let modificationCount = this[_modificationCount];
        let i = this[_head];
        while (i != this[_tail]) {
          let element = this[_table][core.$get](i);
          let remove = core.identical(removeMatching, test(element));
          this[_checkModification](modificationCount);
          if (remove) {
            i = this[_remove](i);
            modificationCount = this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
          } else {
            i = dart.notNull(i) + 1 & dart.notNull(this[_table][core.$length]) - 1;
          }
        }
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_filterWhere](test, true);
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_filterWhere](test, false);
      }
      clear() {
        if (this[_head] != this[_tail]) {
          for (let i = this[_head]; i != this[_tail]; i = dart.notNull(i) + 1 & dart.notNull(this[_table][core.$length]) - 1) {
            this[_table][core.$set](i, null);
          }
          this[_head] = this[_tail] = 0;
          this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        }
      }
      toString() {
        return IterableBase.iterableToFullString(this, "{", "}");
      }
      addLast(element) {
        dart.as(element, E);
        this[_add](element);
      }
      addFirst(element) {
        dart.as(element, E);
        this[_head] = dart.notNull(this[_head]) - 1 & dart.notNull(this[_table][core.$length]) - 1;
        this[_table][core.$set](this[_head], element);
        if (this[_head] == this[_tail])
          this[_grow]();
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
      }
      removeFirst() {
        if (this[_head] == this[_tail])
          throw _internal.IterableElementError.noElement();
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        let result = this[_table][core.$get](this[_head]);
        this[_table][core.$set](this[_head], null);
        this[_head] = dart.notNull(this[_head]) + 1 & dart.notNull(this[_table][core.$length]) - 1;
        return result;
      }
      removeLast() {
        if (this[_head] == this[_tail])
          throw _internal.IterableElementError.noElement();
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        this[_tail] = dart.notNull(this[_tail]) - 1 & dart.notNull(this[_table][core.$length]) - 1;
        let result = this[_table][core.$get](this[_tail]);
        this[_table][core.$set](this[_tail], null);
        return result;
      }
      static _isPowerOf2(number) {
        return (dart.notNull(number) & dart.notNull(number) - 1) == 0;
      }
      static _nextPowerOf2(number) {
        dart.assert(dart.notNull(number) > 0);
        number = (dart.notNull(number) << 1) - 1;
        for (;;) {
          let nextNumber = dart.notNull(number) & dart.notNull(number) - 1;
          if (nextNumber == 0)
            return number;
          number = nextNumber;
        }
      }
      [_checkModification](expectedModificationCount) {
        if (expectedModificationCount != this[_modificationCount]) {
          throw new core.ConcurrentModificationError(this);
        }
      }
      [_add](element) {
        dart.as(element, E);
        this[_table][core.$set](this[_tail], element);
        this[_tail] = dart.notNull(this[_tail]) + 1 & dart.notNull(this[_table][core.$length]) - 1;
        if (this[_head] == this[_tail])
          this[_grow]();
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
      }
      [_remove](offset) {
        let mask = dart.notNull(this[_table][core.$length]) - 1;
        let startDistance = dart.notNull(offset) - dart.notNull(this[_head]) & dart.notNull(mask);
        let endDistance = dart.notNull(this[_tail]) - dart.notNull(offset) & dart.notNull(mask);
        if (dart.notNull(startDistance) < dart.notNull(endDistance)) {
          let i = offset;
          while (i != this[_head]) {
            let prevOffset = dart.notNull(i) - 1 & dart.notNull(mask);
            this[_table][core.$set](i, this[_table][core.$get](prevOffset));
            i = prevOffset;
          }
          this[_table][core.$set](this[_head], null);
          this[_head] = dart.notNull(this[_head]) + 1 & dart.notNull(mask);
          return dart.notNull(offset) + 1 & dart.notNull(mask);
        } else {
          this[_tail] = dart.notNull(this[_tail]) - 1 & dart.notNull(mask);
          let i = offset;
          while (i != this[_tail]) {
            let nextOffset = dart.notNull(i) + 1 & dart.notNull(mask);
            this[_table][core.$set](i, this[_table][core.$get](nextOffset));
            i = nextOffset;
          }
          this[_table][core.$set](this[_tail], null);
          return offset;
        }
      }
      [_grow]() {
        let newTable = new (core.List$(E))(dart.notNull(this[_table][core.$length]) * 2);
        let split = dart.notNull(this[_table][core.$length]) - dart.notNull(this[_head]);
        newTable[core.$setRange](0, split, this[_table], this[_head]);
        newTable[core.$setRange](split, dart.notNull(split) + dart.notNull(this[_head]), this[_table], 0);
        this[_head] = 0;
        this[_tail] = this[_table][core.$length];
        this[_table] = newTable;
      }
      [_writeToList](target) {
        dart.as(target, core.List$(E));
        dart.assert(dart.notNull(target[core.$length]) >= dart.notNull(this[core.$length]));
        if (dart.notNull(this[_head]) <= dart.notNull(this[_tail])) {
          let length = dart.notNull(this[_tail]) - dart.notNull(this[_head]);
          target[core.$setRange](0, length, this[_table], this[_head]);
          return length;
        } else {
          let firstPartSize = dart.notNull(this[_table][core.$length]) - dart.notNull(this[_head]);
          target[core.$setRange](0, firstPartSize, this[_table], this[_head]);
          target[core.$setRange](firstPartSize, dart.notNull(firstPartSize) + dart.notNull(this[_tail]), this[_table], 0);
          return dart.notNull(this[_tail]) + dart.notNull(firstPartSize);
        }
      }
      [_preGrow](newElementCount) {
        dart.assert(dart.notNull(newElementCount) >= dart.notNull(this[core.$length]));
        newElementCount = dart.notNull(newElementCount) + (dart.notNull(newElementCount) >> 1);
        let newCapacity = ListQueue$()._nextPowerOf2(newElementCount);
        let newTable = new (core.List$(E))(newCapacity);
        this[_tail] = this[_writeToList](newTable);
        this[_table] = newTable;
        this[_head] = 0;
      }
    }
    ListQueue[dart.implements] = () => [Queue$(E)];
    dart.defineNamedConstructor(ListQueue, 'from');
    dart.setSignature(ListQueue, {
      methods: () => ({
        [core.$forEach]: [dart.void, [dart.functionType(dart.void, [E])]],
        [core.$elementAt]: [E, [core.int]],
        [core.$toList]: [core.List$(E), [], {rowabl: core.bool}],
        add: [dart.void, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        remove: [core.bool, [core.Object]],
        [_filterWhere]: [dart.void, [dart.functionType(core.bool, [E]), core.bool]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        clear: [dart.void, []],
        addLast: [dart.void, [E]],
        addFirst: [dart.void, [E]],
        removeFirst: [E, []],
        removeLast: [E, []],
        [_checkModification]: [dart.void, [core.int]],
        [_add]: [dart.void, [E]],
        [_remove]: [core.int, [core.int]],
        [_grow]: [dart.void, []],
        [_writeToList]: [core.int, [core.List$(E)]],
        [_preGrow]: [dart.void, [core.int]]
      }),
      statics: () => ({
        _isPowerOf2: [core.bool, [core.int]],
        _nextPowerOf2: [core.int, [core.int]]
      }),
      names: ['_isPowerOf2', '_nextPowerOf2']
    });
    return ListQueue;
  });
  let ListQueue = ListQueue$();
  ListQueue._INITIAL_CAPACITY = 8;
  let _queue = Symbol('_queue');
  let _end = Symbol('_end');
  let _position = Symbol('_position');
  let _ListQueueIterator$ = dart.generic(function(E) {
    class _ListQueueIterator extends core.Object {
      _ListQueueIterator(queue) {
        this[_queue] = queue;
        this[_end] = queue[_tail];
        this[_modificationCount] = queue[_modificationCount];
        this[_position] = queue[_head];
        this[_current] = null;
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        this[_queue][_checkModification](this[_modificationCount]);
        if (this[_position] == this[_end]) {
          this[_current] = null;
          return false;
        }
        this[_current] = dart.as(this[_queue][_table][core.$get](this[_position]), E);
        this[_position] = dart.notNull(this[_position]) + 1 & dart.notNull(this[_queue][_table][core.$length]) - 1;
        return true;
      }
    }
    _ListQueueIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setSignature(_ListQueueIterator, {
      methods: () => ({moveNext: [core.bool, []]})
    });
    return _ListQueueIterator;
  });
  let _ListQueueIterator = _ListQueueIterator$();
  let _Predicate$ = dart.generic(function(T) {
    let _Predicate = dart.typedef('_Predicate', () => dart.functionType(core.bool, [T]));
    return _Predicate;
  });
  let _Predicate = _Predicate$();
  let _SplayTreeNode$ = dart.generic(function(K) {
    class _SplayTreeNode extends core.Object {
      _SplayTreeNode(key) {
        this.key = key;
        this.left = null;
        this.right = null;
      }
    }
    return _SplayTreeNode;
  });
  let _SplayTreeNode = _SplayTreeNode$();
  let _SplayTreeMapNode$ = dart.generic(function(K, V) {
    class _SplayTreeMapNode extends _SplayTreeNode$(K) {
      _SplayTreeMapNode(key, value) {
        this.value = value;
        super._SplayTreeNode(key);
      }
    }
    return _SplayTreeMapNode;
  });
  let _SplayTreeMapNode = _SplayTreeMapNode$();
  let _dummy = Symbol('_dummy');
  let _root = Symbol('_root');
  let _count = Symbol('_count');
  let _splayCount = Symbol('_splayCount');
  let _splay = Symbol('_splay');
  let _compare = Symbol('_compare');
  let _splayMin = Symbol('_splayMin');
  let _splayMax = Symbol('_splayMax');
  let _addNewRoot = Symbol('_addNewRoot');
  let _first = Symbol('_first');
  let _last = Symbol('_last');
  let _clear = Symbol('_clear');
  let _SplayTree$ = dart.generic(function(K) {
    class _SplayTree extends core.Object {
      _SplayTree() {
        this[_dummy] = new (_SplayTreeNode$(K))(null);
        this[_root] = null;
        this[_count] = 0;
        this[_modificationCount] = 0;
        this[_splayCount] = 0;
      }
      [_splay](key) {
        dart.as(key, K);
        if (this[_root] == null)
          return -1;
        let left = this[_dummy];
        let right = this[_dummy];
        let current = this[_root];
        let comp = null;
        while (true) {
          comp = this[_compare](current.key, key);
          if (dart.notNull(comp) > 0) {
            if (current.left == null)
              break;
            comp = this[_compare](current.left.key, key);
            if (dart.notNull(comp) > 0) {
              let tmp = current.left;
              current.left = tmp.right;
              tmp.right = current;
              current = tmp;
              if (current.left == null)
                break;
            }
            right.left = current;
            right = current;
            current = current.left;
          } else if (dart.notNull(comp) < 0) {
            if (current.right == null)
              break;
            comp = this[_compare](current.right.key, key);
            if (dart.notNull(comp) < 0) {
              let tmp = current.right;
              current.right = tmp.left;
              tmp.left = current;
              current = tmp;
              if (current.right == null)
                break;
            }
            left.right = current;
            left = current;
            current = current.right;
          } else {
            break;
          }
        }
        left.right = current.left;
        right.left = current.right;
        current.left = this[_dummy].right;
        current.right = this[_dummy].left;
        this[_root] = current;
        this[_dummy].right = null;
        this[_dummy].left = null;
        this[_splayCount] = dart.notNull(this[_splayCount]) + 1;
        return comp;
      }
      [_splayMin](node) {
        dart.as(node, _SplayTreeNode$(K));
        let current = node;
        while (current.left != null) {
          let left = current.left;
          current.left = left.right;
          left.right = current;
          current = left;
        }
        return dart.as(current, _SplayTreeNode$(K));
      }
      [_splayMax](node) {
        dart.as(node, _SplayTreeNode$(K));
        let current = node;
        while (current.right != null) {
          let right = current.right;
          current.right = right.left;
          right.left = current;
          current = right;
        }
        return dart.as(current, _SplayTreeNode$(K));
      }
      [_remove](key) {
        dart.as(key, K);
        if (this[_root] == null)
          return null;
        let comp = this[_splay](key);
        if (comp != 0)
          return null;
        let result = this[_root];
        this[_count] = dart.notNull(this[_count]) - 1;
        if (this[_root].left == null) {
          this[_root] = this[_root].right;
        } else {
          let right = this[_root].right;
          this[_root] = this[_splayMax](this[_root].left);
          this[_root].right = right;
        }
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        return result;
      }
      [_addNewRoot](node, comp) {
        dart.as(node, _SplayTreeNode$(K));
        this[_count] = dart.notNull(this[_count]) + 1;
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        if (this[_root] == null) {
          this[_root] = node;
          return;
        }
        if (dart.notNull(comp) < 0) {
          node.left = this[_root];
          node.right = this[_root].right;
          this[_root].right = null;
        } else {
          node.right = this[_root];
          node.left = this[_root].left;
          this[_root].left = null;
        }
        this[_root] = node;
      }
      get [_first]() {
        if (this[_root] == null)
          return null;
        this[_root] = this[_splayMin](this[_root]);
        return this[_root];
      }
      get [_last]() {
        if (this[_root] == null)
          return null;
        this[_root] = this[_splayMax](this[_root]);
        return this[_root];
      }
      [_clear]() {
        this[_root] = null;
        this[_count] = 0;
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
      }
    }
    dart.setSignature(_SplayTree, {
      methods: () => ({
        [_splay]: [core.int, [K]],
        [_splayMin]: [_SplayTreeNode$(K), [_SplayTreeNode$(K)]],
        [_splayMax]: [_SplayTreeNode$(K), [_SplayTreeNode$(K)]],
        [_remove]: [_SplayTreeNode, [K]],
        [_addNewRoot]: [dart.void, [_SplayTreeNode$(K), core.int]],
        [_clear]: [dart.void, []]
      })
    });
    return _SplayTree;
  });
  let _SplayTree = _SplayTree$();
  let _comparator = Symbol('_comparator');
  let _validKey = Symbol('_validKey');
  let SplayTreeMap$ = dart.generic(function(K, V) {
    class SplayTreeMap extends _SplayTree$(K) {
      SplayTreeMap(compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        this[_comparator] = dart.as(compare == null ? core.Comparable.compare : compare, core.Comparator$(K));
        this[_validKey] = isValidKey != null ? isValidKey : dart.fn(v => dart.is(v, K), core.bool, [core.Object]);
        super._SplayTree();
      }
      from(other, compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        let result = new (SplayTreeMap$(K, V))();
        other.forEach(dart.fn((k, v) => {
          result.set(k, dart.as(v, V));
        }));
        return result;
      }
      fromIterable(iterable, opts) {
        let key = opts && 'key' in opts ? opts.key : null;
        let value = opts && 'value' in opts ? opts.value : null;
        let compare = opts && 'compare' in opts ? opts.compare : null;
        let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
        let map = new (SplayTreeMap$(K, V))(compare, isValidKey);
        Maps._fillMapWithMappedIterable(map, iterable, key, value);
        return map;
      }
      fromIterables(keys, values, compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        let map = new (SplayTreeMap$(K, V))(compare, isValidKey);
        Maps._fillMapWithIterables(map, keys, values);
        return map;
      }
      [_compare](key1, key2) {
        dart.as(key1, K);
        dart.as(key2, K);
        return this[_comparator](key1, key2);
      }
      _internal() {
        this[_comparator] = null;
        this[_validKey] = null;
        super._SplayTree();
      }
      get(key) {
        if (key == null)
          throw new core.ArgumentError(key);
        if (!dart.notNull(this[_validKey](key)))
          return null;
        if (this[_root] != null) {
          let comp = this[_splay](dart.as(key, K));
          if (comp == 0) {
            let mapRoot = dart.as(this[_root], _SplayTreeMapNode);
            return dart.as(mapRoot.value, V);
          }
        }
        return null;
      }
      remove(key) {
        if (!dart.notNull(this[_validKey](key)))
          return null;
        let mapRoot = dart.as(this[_remove](dart.as(key, K)), _SplayTreeMapNode);
        if (mapRoot != null)
          return dart.as(mapRoot.value, V);
        return null;
      }
      set(key, value) {
        dart.as(key, K);
        dart.as(value, V);
        if (key == null)
          throw new core.ArgumentError(key);
        let comp = this[_splay](key);
        if (comp == 0) {
          let mapRoot = dart.as(this[_root], _SplayTreeMapNode);
          mapRoot.value = value;
          return;
        }
        this[_addNewRoot](new (_SplayTreeMapNode$(K, core.Object))(key, value), comp);
      }
      putIfAbsent(key, ifAbsent) {
        dart.as(key, K);
        dart.as(ifAbsent, dart.functionType(V, []));
        if (key == null)
          throw new core.ArgumentError(key);
        let comp = this[_splay](key);
        if (comp == 0) {
          let mapRoot = dart.as(this[_root], _SplayTreeMapNode);
          return dart.as(mapRoot.value, V);
        }
        let modificationCount = this[_modificationCount];
        let splayCount = this[_splayCount];
        let value = ifAbsent();
        if (modificationCount != this[_modificationCount]) {
          throw new core.ConcurrentModificationError(this);
        }
        if (splayCount != this[_splayCount]) {
          comp = this[_splay](key);
          dart.assert(comp != 0);
        }
        this[_addNewRoot](new (_SplayTreeMapNode$(K, core.Object))(key, value), comp);
        return value;
      }
      addAll(other) {
        dart.as(other, core.Map$(K, V));
        other.forEach(dart.fn(((key, value) => {
          dart.as(key, K);
          dart.as(value, V);
          this.set(key, value);
        }).bind(this), core.Object, [K, V]));
      }
      get isEmpty() {
        return this[_root] == null;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      forEach(f) {
        dart.as(f, dart.functionType(dart.void, [K, V]));
        let nodes = new (_SplayTreeNodeIterator$(K))(this);
        while (nodes.moveNext()) {
          let node = dart.as(nodes.current, _SplayTreeMapNode$(K, V));
          f(node.key, node.value);
        }
      }
      get length() {
        return this[_count];
      }
      clear() {
        this[_clear]();
      }
      containsKey(key) {
        return dart.notNull(this[_validKey](key)) && this[_splay](dart.as(key, K)) == 0;
      }
      containsValue(value) {
        let found = false;
        let initialSplayCount = this[_splayCount];
        let visit = (node => {
          while (node != null) {
            if (dart.equals(node.value, value))
              return true;
            if (initialSplayCount != this[_splayCount]) {
              throw new core.ConcurrentModificationError(this);
            }
            if (dart.notNull(node.right != null) && dart.notNull(visit(dart.as(node.right, _SplayTreeMapNode))))
              return true;
            node = dart.as(node.left, _SplayTreeMapNode);
          }
          return false;
        }).bind(this);
        dart.fn(visit, core.bool, [_SplayTreeMapNode]);
        return visit(dart.as(this[_root], _SplayTreeMapNode));
      }
      get keys() {
        return new (_SplayTreeKeyIterable$(K))(this);
      }
      get values() {
        return new (_SplayTreeValueIterable$(K, V))(this);
      }
      toString() {
        return Maps.mapToString(this);
      }
      firstKey() {
        if (this[_root] == null)
          return null;
        return dart.as(this[_first].key, K);
      }
      lastKey() {
        if (this[_root] == null)
          return null;
        return dart.as(this[_last].key, K);
      }
      lastKeyBefore(key) {
        dart.as(key, K);
        if (key == null)
          throw new core.ArgumentError(key);
        if (this[_root] == null)
          return null;
        let comp = this[_splay](key);
        if (dart.notNull(comp) < 0)
          return this[_root].key;
        let node = this[_root].left;
        if (node == null)
          return null;
        while (node.right != null) {
          node = node.right;
        }
        return node.key;
      }
      firstKeyAfter(key) {
        dart.as(key, K);
        if (key == null)
          throw new core.ArgumentError(key);
        if (this[_root] == null)
          return null;
        let comp = this[_splay](key);
        if (dart.notNull(comp) > 0)
          return this[_root].key;
        let node = this[_root].right;
        if (node == null)
          return null;
        while (node.left != null) {
          node = node.left;
        }
        return node.key;
      }
    }
    SplayTreeMap[dart.implements] = () => [core.Map$(K, V)];
    dart.defineNamedConstructor(SplayTreeMap, 'from');
    dart.defineNamedConstructor(SplayTreeMap, 'fromIterable');
    dart.defineNamedConstructor(SplayTreeMap, 'fromIterables');
    dart.defineNamedConstructor(SplayTreeMap, '_internal');
    dart.setSignature(SplayTreeMap, {
      methods: () => ({
        [_compare]: [core.int, [K, K]],
        get: [V, [core.Object]],
        remove: [V, [core.Object]],
        set: [dart.void, [K, V]],
        putIfAbsent: [V, [K, dart.functionType(V, [])]],
        addAll: [dart.void, [core.Map$(K, V)]],
        forEach: [dart.void, [dart.functionType(dart.void, [K, V])]],
        clear: [dart.void, []],
        containsKey: [core.bool, [core.Object]],
        containsValue: [core.bool, [core.Object]],
        firstKey: [K, []],
        lastKey: [K, []],
        lastKeyBefore: [K, [K]],
        firstKeyAfter: [K, [K]]
      })
    });
    return SplayTreeMap;
  });
  let SplayTreeMap = SplayTreeMap$();
  let _workList = Symbol('_workList');
  let _tree = Symbol('_tree');
  let _currentNode = Symbol('_currentNode');
  let _findLeftMostDescendent = Symbol('_findLeftMostDescendent');
  let _getValue = Symbol('_getValue');
  let _rebuildWorkList = Symbol('_rebuildWorkList');
  let _SplayTreeIterator$ = dart.generic(function(T) {
    class _SplayTreeIterator extends core.Object {
      _SplayTreeIterator(tree) {
        this[_workList] = dart.setType([], core.List$(_SplayTreeNode));
        this[_tree] = tree;
        this[_modificationCount] = tree[_modificationCount];
        this[_splayCount] = tree[_splayCount];
        this[_currentNode] = null;
        this[_findLeftMostDescendent](tree[_root]);
      }
      startAt(tree, startKey) {
        this[_workList] = dart.setType([], core.List$(_SplayTreeNode));
        this[_tree] = tree;
        this[_modificationCount] = tree[_modificationCount];
        this[_splayCount] = null;
        this[_currentNode] = null;
        if (tree[_root] == null)
          return;
        let compare = tree[_splay](startKey);
        this[_splayCount] = tree[_splayCount];
        if (dart.notNull(compare) < 0) {
          this[_findLeftMostDescendent](tree[_root].right);
        } else {
          this[_workList][core.$add](tree[_root]);
        }
      }
      get current() {
        if (this[_currentNode] == null)
          return null;
        return this[_getValue](dart.as(this[_currentNode], _SplayTreeMapNode));
      }
      [_findLeftMostDescendent](node) {
        while (node != null) {
          this[_workList][core.$add](node);
          node = node.left;
        }
      }
      [_rebuildWorkList](currentNode) {
        dart.assert(!dart.notNull(this[_workList][core.$isEmpty]));
        this[_workList][core.$clear]();
        if (currentNode == null) {
          this[_findLeftMostDescendent](this[_tree][_root]);
        } else {
          this[_tree][_splay](currentNode.key);
          this[_findLeftMostDescendent](this[_tree][_root].right);
          dart.assert(!dart.notNull(this[_workList][core.$isEmpty]));
        }
      }
      moveNext() {
        if (this[_modificationCount] != this[_tree][_modificationCount]) {
          throw new core.ConcurrentModificationError(this[_tree]);
        }
        if (this[_workList][core.$isEmpty]) {
          this[_currentNode] = null;
          return false;
        }
        if (this[_tree][_splayCount] != this[_splayCount] && dart.notNull(this[_currentNode] != null)) {
          this[_rebuildWorkList](this[_currentNode]);
        }
        this[_currentNode] = this[_workList][core.$removeLast]();
        this[_findLeftMostDescendent](this[_currentNode].right);
        return true;
      }
    }
    _SplayTreeIterator[dart.implements] = () => [core.Iterator$(T)];
    dart.defineNamedConstructor(_SplayTreeIterator, 'startAt');
    dart.setSignature(_SplayTreeIterator, {
      methods: () => ({
        [_findLeftMostDescendent]: [dart.void, [_SplayTreeNode]],
        [_rebuildWorkList]: [dart.void, [_SplayTreeNode]],
        moveNext: [core.bool, []]
      })
    });
    return _SplayTreeIterator;
  });
  let _SplayTreeIterator = _SplayTreeIterator$();
  let _copyNode = Symbol('_copyNode');
  let _SplayTreeKeyIterable$ = dart.generic(function(K) {
    class _SplayTreeKeyIterable extends IterableBase$(K) {
      _SplayTreeKeyIterable(tree) {
        this[_tree] = tree;
        super.IterableBase();
      }
      get [core.$length]() {
        return this[_tree][_count];
      }
      get [core.$isEmpty]() {
        return this[_tree][_count] == 0;
      }
      get [core.$iterator]() {
        return new (_SplayTreeKeyIterator$(K))(this[_tree]);
      }
      [core.$toSet]() {
        let setOrMap = this[_tree];
        let set = new (SplayTreeSet$(K))(dart.as(setOrMap[_comparator], __CastType0), dart.as(setOrMap[_validKey], __CastType3));
        set[_count] = this[_tree][_count];
        set[_root] = set[_copyNode](this[_tree][_root]);
        return set;
      }
    }
    _SplayTreeKeyIterable[dart.implements] = () => [_internal.EfficientLength];
    dart.setSignature(_SplayTreeKeyIterable, {
      methods: () => ({[core.$toSet]: [core.Set$(K), []]})
    });
    return _SplayTreeKeyIterable;
  });
  let _SplayTreeKeyIterable = _SplayTreeKeyIterable$();
  let _SplayTreeValueIterable$ = dart.generic(function(K, V) {
    class _SplayTreeValueIterable extends IterableBase$(V) {
      _SplayTreeValueIterable(map) {
        this[_map] = map;
        super.IterableBase();
      }
      get [core.$length]() {
        return this[_map][_count];
      }
      get [core.$isEmpty]() {
        return this[_map][_count] == 0;
      }
      get [core.$iterator]() {
        return new (_SplayTreeValueIterator$(K, V))(this[_map]);
      }
    }
    _SplayTreeValueIterable[dart.implements] = () => [_internal.EfficientLength];
    return _SplayTreeValueIterable;
  });
  let _SplayTreeValueIterable = _SplayTreeValueIterable$();
  let _SplayTreeKeyIterator$ = dart.generic(function(K) {
    class _SplayTreeKeyIterator extends _SplayTreeIterator$(K) {
      _SplayTreeKeyIterator(map) {
        super._SplayTreeIterator(map);
      }
      [_getValue](node) {
        return dart.as(node.key, K);
      }
    }
    dart.setSignature(_SplayTreeKeyIterator, {
      methods: () => ({[_getValue]: [K, [_SplayTreeNode]]})
    });
    return _SplayTreeKeyIterator;
  });
  let _SplayTreeKeyIterator = _SplayTreeKeyIterator$();
  let _SplayTreeValueIterator$ = dart.generic(function(K, V) {
    class _SplayTreeValueIterator extends _SplayTreeIterator$(V) {
      _SplayTreeValueIterator(map) {
        super._SplayTreeIterator(map);
      }
      [_getValue](node) {
        return dart.as(node.value, V);
      }
    }
    dart.setSignature(_SplayTreeValueIterator, {
      methods: () => ({[_getValue]: [V, [_SplayTreeMapNode]]})
    });
    return _SplayTreeValueIterator;
  });
  let _SplayTreeValueIterator = _SplayTreeValueIterator$();
  let _SplayTreeNodeIterator$ = dart.generic(function(K) {
    class _SplayTreeNodeIterator extends _SplayTreeIterator$(_SplayTreeNode$(K)) {
      _SplayTreeNodeIterator(tree) {
        super._SplayTreeIterator(tree);
      }
      startAt(tree, startKey) {
        super.startAt(tree, startKey);
      }
      [_getValue](node) {
        return dart.as(node, _SplayTreeNode$(K));
      }
    }
    dart.defineNamedConstructor(_SplayTreeNodeIterator, 'startAt');
    dart.setSignature(_SplayTreeNodeIterator, {
      methods: () => ({[_getValue]: [_SplayTreeNode$(K), [_SplayTreeNode]]})
    });
    return _SplayTreeNodeIterator;
  });
  let _SplayTreeNodeIterator = _SplayTreeNodeIterator$();
  let _clone = Symbol('_clone');
  let SplayTreeSet$ = dart.generic(function(E) {
    class SplayTreeSet extends dart.mixin(_SplayTree$(E), IterableMixin$(E), SetMixin$(E)) {
      SplayTreeSet(compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        this[_comparator] = dart.as(compare == null ? core.Comparable.compare : compare, core.Comparator$(E));
        this[_validKey] = isValidKey != null ? isValidKey : dart.fn(v => dart.is(v, E), core.bool, [core.Object]);
        super._SplayTree();
      }
      from(elements, compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        let result = new (SplayTreeSet$(E))(compare, isValidKey);
        for (let element of dart.as(elements, core.Iterable$(E))) {
          result.add(element);
        }
        return result;
      }
      [_compare](e1, e2) {
        dart.as(e1, E);
        dart.as(e2, E);
        return this[_comparator](e1, e2);
      }
      get [core.$iterator]() {
        return new (_SplayTreeKeyIterator$(E))(this);
      }
      get [core.$length]() {
        return this[_count];
      }
      get [core.$isEmpty]() {
        return this[_root] == null;
      }
      get [core.$isNotEmpty]() {
        return this[_root] != null;
      }
      get [core.$first]() {
        if (this[_count] == 0)
          throw _internal.IterableElementError.noElement();
        return dart.as(this[_first].key, E);
      }
      get [core.$last]() {
        if (this[_count] == 0)
          throw _internal.IterableElementError.noElement();
        return dart.as(this[_last].key, E);
      }
      get [core.$single]() {
        if (this[_count] == 0)
          throw _internal.IterableElementError.noElement();
        if (dart.notNull(this[_count]) > 1)
          throw _internal.IterableElementError.tooMany();
        return this[_root].key;
      }
      [core.$contains](object) {
        return dart.notNull(this[_validKey](object)) && this[_splay](dart.as(object, E)) == 0;
      }
      add(element) {
        dart.as(element, E);
        let compare = this[_splay](element);
        if (compare == 0)
          return false;
        this[_addNewRoot](new (_SplayTreeNode$(E))(element), compare);
        return true;
      }
      remove(object) {
        if (!dart.notNull(this[_validKey](object)))
          return false;
        return this[_remove](dart.as(object, E)) != null;
      }
      addAll(elements) {
        dart.as(elements, core.Iterable$(E));
        for (let element of elements) {
          let compare = this[_splay](element);
          if (compare != 0) {
            this[_addNewRoot](new (_SplayTreeNode$(E))(element), compare);
          }
        }
      }
      removeAll(elements) {
        for (let element of elements) {
          if (this[_validKey](element))
            this[_remove](dart.as(element, E));
        }
      }
      retainAll(elements) {
        let retainSet = new (SplayTreeSet$(E))(this[_comparator], this[_validKey]);
        let modificationCount = this[_modificationCount];
        for (let object of elements) {
          if (modificationCount != this[_modificationCount]) {
            throw new core.ConcurrentModificationError(this);
          }
          if (dart.notNull(this[_validKey](object)) && this[_splay](dart.as(object, E)) == 0)
            retainSet.add(this[_root].key);
        }
        if (retainSet[_count] != this[_count]) {
          this[_root] = retainSet[_root];
          this[_count] = retainSet[_count];
          this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        }
      }
      lookup(object) {
        if (!dart.notNull(this[_validKey](object)))
          return null;
        let comp = this[_splay](dart.as(object, E));
        if (comp != 0)
          return null;
        return this[_root].key;
      }
      intersection(other) {
        let result = new (SplayTreeSet$(E))(this[_comparator], this[_validKey]);
        for (let element of this) {
          if (other[core.$contains](element))
            result.add(element);
        }
        return result;
      }
      difference(other) {
        let result = new (SplayTreeSet$(E))(this[_comparator], this[_validKey]);
        for (let element of this) {
          if (!dart.notNull(other[core.$contains](element)))
            result.add(element);
        }
        return result;
      }
      union(other) {
        dart.as(other, core.Set$(E));
        let _ = this[_clone]();
        _.addAll(other);
        return _;
      }
      [_clone]() {
        let set = new (SplayTreeSet$(E))(this[_comparator], this[_validKey]);
        set[_count] = this[_count];
        set[_root] = this[_copyNode](this[_root]);
        return set;
      }
      [_copyNode](node) {
        dart.as(node, _SplayTreeNode$(E));
        if (node == null)
          return null;
        let _ = new (_SplayTreeNode$(E))(node.key);
        _.left = this[_copyNode](node.left);
        _.right = this[_copyNode](node.right);
        return _;
      }
      clear() {
        this[_clear]();
      }
      [core.$toSet]() {
        return this[_clone]();
      }
      toString() {
        return IterableBase.iterableToFullString(this, '{', '}');
      }
    }
    dart.defineNamedConstructor(SplayTreeSet, 'from');
    dart.setSignature(SplayTreeSet, {
      methods: () => ({
        [_compare]: [core.int, [E, E]],
        [core.$contains]: [core.bool, [core.Object]],
        add: [core.bool, [E]],
        remove: [core.bool, [core.Object]],
        addAll: [dart.void, [core.Iterable$(E)]],
        lookup: [E, [core.Object]],
        intersection: [core.Set$(E), [core.Set$(core.Object)]],
        difference: [core.Set$(E), [core.Set$(core.Object)]],
        union: [core.Set$(E), [core.Set$(E)]],
        [_clone]: [SplayTreeSet$(E), []],
        [_copyNode]: [_SplayTreeNode$(E), [_SplayTreeNode$(E)]],
        [core.$toSet]: [core.Set$(E), []]
      })
    });
    return SplayTreeSet;
  });
  let SplayTreeSet = SplayTreeSet$();
  let __CastType0$ = dart.generic(function(K) {
    let __CastType0 = dart.typedef('__CastType0', () => dart.functionType(core.int, [K, K]));
    return __CastType0;
  });
  let __CastType0 = __CastType0$();
  let __CastType3 = dart.typedef('__CastType3', () => dart.functionType(core.bool, [core.Object]));
  let _strings = Symbol('_strings');
  let _nums = Symbol('_nums');
  let _rest = Symbol('_rest');
  let _containsKey = Symbol('_containsKey');
  let _getBucket = Symbol('_getBucket');
  let _findBucketIndex = Symbol('_findBucketIndex');
  let _computeKeys = Symbol('_computeKeys');
  let _get = Symbol('_get');
  let _addHashTableEntry = Symbol('_addHashTableEntry');
  let _set = Symbol('_set');
  let _computeHashCode = Symbol('_computeHashCode');
  let _removeHashTableEntry = Symbol('_removeHashTableEntry');
  let _HashMap$ = dart.generic(function(K, V) {
    class _HashMap extends core.Object {
      _HashMap() {
        this[_length] = 0;
        this[_strings] = null;
        this[_nums] = null;
        this[_rest] = null;
        this[_keys] = null;
      }
      get length() {
        return this[_length];
      }
      get isEmpty() {
        return this[_length] == 0;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      get keys() {
        return new (HashMapKeyIterable$(K))(this);
      }
      get values() {
        return new (_internal.MappedIterable$(K, V))(this.keys, dart.fn((each => this.get(each)).bind(this), V, [core.Object]));
      }
      containsKey(key) {
        if (_HashMap$()._isStringKey(key)) {
          let strings = this[_strings];
          return strings == null ? false : _HashMap$()._hasTableEntry(strings, key);
        } else if (_HashMap$()._isNumericKey(key)) {
          let nums = this[_nums];
          return nums == null ? false : _HashMap$()._hasTableEntry(nums, key);
        } else {
          return this[_containsKey](key);
        }
      }
      [_containsKey](key) {
        let rest = this[_rest];
        if (rest == null)
          return false;
        let bucket = this[_getBucket](rest, key);
        return dart.notNull(this[_findBucketIndex](bucket, key)) >= 0;
      }
      containsValue(value) {
        return this[_computeKeys]()[core.$any](dart.fn((each => dart.equals(this.get(each), value)).bind(this), core.bool, [core.Object]));
      }
      addAll(other) {
        dart.as(other, core.Map$(K, V));
        other.forEach(dart.fn(((key, value) => {
          dart.as(key, K);
          dart.as(value, V);
          this.set(key, value);
        }).bind(this), core.Object, [K, V]));
      }
      get(key) {
        if (_HashMap$()._isStringKey(key)) {
          let strings = this[_strings];
          return strings == null ? null : dart.as(_HashMap$()._getTableEntry(strings, key), V);
        } else if (_HashMap$()._isNumericKey(key)) {
          let nums = this[_nums];
          return nums == null ? null : dart.as(_HashMap$()._getTableEntry(nums, key), V);
        } else {
          return this[_get](key);
        }
      }
      [_get](key) {
        let rest = this[_rest];
        if (rest == null)
          return null;
        let bucket = this[_getBucket](rest, key);
        let index = this[_findBucketIndex](bucket, key);
        return dart.notNull(index) < 0 ? null : dart.as(bucket[dart.notNull(index) + 1], V);
      }
      set(key, value) {
        dart.as(key, K);
        dart.as(value, V);
        if (_HashMap$()._isStringKey(key)) {
          let strings = this[_strings];
          if (strings == null)
            this[_strings] = strings = _HashMap$()._newHashTable();
          this[_addHashTableEntry](strings, key, value);
        } else if (_HashMap$()._isNumericKey(key)) {
          let nums = this[_nums];
          if (nums == null)
            this[_nums] = nums = _HashMap$()._newHashTable();
          this[_addHashTableEntry](nums, key, value);
        } else {
          this[_set](key, value);
        }
      }
      [_set](key, value) {
        dart.as(key, K);
        dart.as(value, V);
        let rest = this[_rest];
        if (rest == null)
          this[_rest] = rest = _HashMap$()._newHashTable();
        let hash = this[_computeHashCode](key);
        let bucket = rest[hash];
        if (bucket == null) {
          _HashMap$()._setTableEntry(rest, hash, [key, value]);
          this[_length] = dart.notNull(this[_length]) + 1;
          this[_keys] = null;
        } else {
          let index = this[_findBucketIndex](bucket, key);
          if (dart.notNull(index) >= 0) {
            bucket[dart.notNull(index) + 1] = value;
          } else {
            bucket.push(key, value);
            this[_length] = dart.notNull(this[_length]) + 1;
            this[_keys] = null;
          }
        }
      }
      putIfAbsent(key, ifAbsent) {
        dart.as(key, K);
        dart.as(ifAbsent, dart.functionType(V, []));
        if (this.containsKey(key))
          return this.get(key);
        let value = ifAbsent();
        this.set(key, value);
        return value;
      }
      remove(key) {
        if (_HashMap$()._isStringKey(key)) {
          return this[_removeHashTableEntry](this[_strings], key);
        } else if (_HashMap$()._isNumericKey(key)) {
          return this[_removeHashTableEntry](this[_nums], key);
        } else {
          return this[_remove](key);
        }
      }
      [_remove](key) {
        let rest = this[_rest];
        if (rest == null)
          return null;
        let bucket = this[_getBucket](rest, key);
        let index = this[_findBucketIndex](bucket, key);
        if (dart.notNull(index) < 0)
          return null;
        this[_length] = dart.notNull(this[_length]) - 1;
        this[_keys] = null;
        return dart.as(bucket.splice(index, 2)[1], V);
      }
      clear() {
        if (dart.notNull(this[_length]) > 0) {
          this[_strings] = this[_nums] = this[_rest] = this[_keys] = null;
          this[_length] = 0;
        }
      }
      forEach(action) {
        dart.as(action, dart.functionType(dart.void, [K, V]));
        let keys = this[_computeKeys]();
        for (let i = 0, length = keys[core.$length]; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let key = keys[i];
          action(dart.as(key, K), this.get(key));
          if (keys !== this[_keys]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
      }
      [_computeKeys]() {
        if (this[_keys] != null)
          return this[_keys];
        let result = new core.List(this[_length]);
        let index = 0;
        let strings = this[_strings];
        if (strings != null) {
          let names = Object.getOwnPropertyNames(strings);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); i = dart.notNull(i) + 1) {
            let key = names[i];
            result[index] = key;
            index = dart.notNull(index) + 1;
          }
        }
        let nums = this[_nums];
        if (nums != null) {
          let names = Object.getOwnPropertyNames(nums);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); i = dart.notNull(i) + 1) {
            let key = +names[i];
            result[index] = key;
            index = dart.notNull(index) + 1;
          }
        }
        let rest = this[_rest];
        if (rest != null) {
          let names = Object.getOwnPropertyNames(rest);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); i = dart.notNull(i) + 1) {
            let key = names[i];
            let bucket = rest[key];
            let length = bucket.length;
            for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 2) {
              let key = bucket[i];
              result[index] = key;
              index = dart.notNull(index) + 1;
            }
          }
        }
        dart.assert(index == this[_length]);
        return this[_keys] = result;
      }
      [_addHashTableEntry](table, key, value) {
        dart.as(key, K);
        dart.as(value, V);
        if (!dart.notNull(_HashMap$()._hasTableEntry(table, key))) {
          this[_length] = dart.notNull(this[_length]) + 1;
          this[_keys] = null;
        }
        _HashMap$()._setTableEntry(table, key, value);
      }
      [_removeHashTableEntry](table, key) {
        if (dart.notNull(table != null) && dart.notNull(_HashMap$()._hasTableEntry(table, key))) {
          let value = dart.as(_HashMap$()._getTableEntry(table, key), V);
          _HashMap$()._deleteTableEntry(table, key);
          this[_length] = dart.notNull(this[_length]) - 1;
          this[_keys] = null;
          return value;
        } else {
          return null;
        }
      }
      static _isStringKey(key) {
        return typeof key == 'string' && dart.notNull(!dart.equals(key, '__proto__'));
      }
      static _isNumericKey(key) {
        return dart.is(key, core.num) && (key & 0x3ffffff) === key;
      }
      [_computeHashCode](key) {
        return dart.hashCode(key) & 0x3ffffff;
      }
      static _hasTableEntry(table, key) {
        let entry = table[key];
        return entry != null;
      }
      static _getTableEntry(table, key) {
        let entry = table[key];
        return entry === table ? null : entry;
      }
      static _setTableEntry(table, key, value) {
        if (value == null) {
          table[key] = table;
        } else {
          table[key] = value;
        }
      }
      static _deleteTableEntry(table, key) {
        delete table[key];
      }
      [_getBucket](table, key) {
        let hash = this[_computeHashCode](key);
        return dart.as(table[hash], core.List);
      }
      [_findBucketIndex](bucket, key) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 2) {
          if (dart.equals(bucket[i], key))
            return i;
        }
        return -1;
      }
      static _newHashTable() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _HashMap$()._setTableEntry(table, temporaryKey, table);
        _HashMap$()._deleteTableEntry(table, temporaryKey);
        return table;
      }
    }
    _HashMap[dart.implements] = () => [HashMap$(K, V)];
    dart.setSignature(_HashMap, {
      methods: () => ({
        containsKey: [core.bool, [core.Object]],
        [_containsKey]: [core.bool, [core.Object]],
        containsValue: [core.bool, [core.Object]],
        addAll: [dart.void, [core.Map$(K, V)]],
        get: [V, [core.Object]],
        [_get]: [V, [core.Object]],
        set: [dart.void, [K, V]],
        [_set]: [dart.void, [K, V]],
        putIfAbsent: [V, [K, dart.functionType(V, [])]],
        remove: [V, [core.Object]],
        [_remove]: [V, [core.Object]],
        clear: [dart.void, []],
        forEach: [dart.void, [dart.functionType(dart.void, [K, V])]],
        [_computeKeys]: [core.List, []],
        [_addHashTableEntry]: [dart.void, [core.Object, K, V]],
        [_removeHashTableEntry]: [V, [core.Object, core.Object]],
        [_computeHashCode]: [core.int, [core.Object]],
        [_getBucket]: [core.List, [core.Object, core.Object]],
        [_findBucketIndex]: [core.int, [core.Object, core.Object]]
      }),
      statics: () => ({
        _isStringKey: [core.bool, [core.Object]],
        _isNumericKey: [core.bool, [core.Object]],
        _hasTableEntry: [core.bool, [core.Object, core.Object]],
        _getTableEntry: [core.Object, [core.Object, core.Object]],
        _setTableEntry: [dart.void, [core.Object, core.Object, core.Object]],
        _deleteTableEntry: [dart.void, [core.Object, core.Object]],
        _newHashTable: [core.Object, []]
      }),
      names: ['_isStringKey', '_isNumericKey', '_hasTableEntry', '_getTableEntry', '_setTableEntry', '_deleteTableEntry', '_newHashTable']
    });
    return _HashMap;
  });
  let _HashMap = _HashMap$();
  let _IdentityHashMap$ = dart.generic(function(K, V) {
    class _IdentityHashMap extends _HashMap$(K, V) {
      _IdentityHashMap() {
        super._HashMap();
      }
      [_computeHashCode](key) {
        return core.identityHashCode(key) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, key) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 2) {
          if (core.identical(bucket[i], key))
            return i;
        }
        return -1;
      }
    }
    return _IdentityHashMap;
  });
  let _IdentityHashMap = _IdentityHashMap$();
  let _equals = Symbol('_equals');
  let _hashCode = Symbol('_hashCode');
  let _CustomHashMap$ = dart.generic(function(K, V) {
    class _CustomHashMap extends _HashMap$(K, V) {
      _CustomHashMap(equals, hashCode, validKey) {
        this[_equals] = equals;
        this[_hashCode] = hashCode;
        this[_validKey] = validKey != null ? validKey : dart.fn(v => dart.is(v, K), core.bool, [core.Object]);
        super._HashMap();
      }
      get(key) {
        if (!dart.notNull(this[_validKey](key)))
          return null;
        return super[_get](key);
      }
      set(key, value) {
        dart.as(key, K);
        dart.as(value, V);
        super[_set](key, value);
      }
      containsKey(key) {
        if (!dart.notNull(this[_validKey](key)))
          return false;
        return super[_containsKey](key);
      }
      remove(key) {
        if (!dart.notNull(this[_validKey](key)))
          return null;
        return super[_remove](key);
      }
      [_computeHashCode](key) {
        return this[_hashCode](dart.as(key, K)) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, key) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 2) {
          if (this[_equals](dart.as(bucket[i], K), dart.as(key, K)))
            return i;
        }
        return -1;
      }
      toString() {
        return Maps.mapToString(this);
      }
    }
    dart.setSignature(_CustomHashMap, {
      methods: () => ({
        get: [V, [core.Object]],
        set: [dart.void, [K, V]],
        remove: [V, [core.Object]]
      })
    });
    return _CustomHashMap;
  });
  let _CustomHashMap = _CustomHashMap$();
  let HashMapKeyIterable$ = dart.generic(function(E) {
    class HashMapKeyIterable extends IterableBase$(E) {
      HashMapKeyIterable(map) {
        this[_map] = map;
        super.IterableBase();
      }
      get [core.$length]() {
        return dart.as(dart.dload(this[_map], _length), core.int);
      }
      get [core.$isEmpty]() {
        return dart.equals(dart.dload(this[_map], _length), 0);
      }
      get [core.$iterator]() {
        return new (HashMapKeyIterator$(E))(this[_map], dart.as(dart.dsend(this[_map], _computeKeys), core.List));
      }
      [core.$contains](element) {
        return dart.as(dart.dsend(this[_map], 'containsKey', element), core.bool);
      }
      [core.$forEach](f) {
        dart.as(f, dart.functionType(dart.void, [E]));
        let keys = dart.as(dart.dsend(this[_map], _computeKeys), core.List);
        for (let i = 0, length = keys.length; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          f(dart.as(keys[i], E));
          if (keys !== dart.dload(this[_map], _keys)) {
            throw new core.ConcurrentModificationError(this[_map]);
          }
        }
      }
    }
    HashMapKeyIterable[dart.implements] = () => [_internal.EfficientLength];
    dart.setSignature(HashMapKeyIterable, {
      methods: () => ({[core.$forEach]: [dart.void, [dart.functionType(dart.void, [E])]]})
    });
    return HashMapKeyIterable;
  });
  let HashMapKeyIterable = HashMapKeyIterable$();
  let _offset = Symbol('_offset');
  let HashMapKeyIterator$ = dart.generic(function(E) {
    class HashMapKeyIterator extends core.Object {
      HashMapKeyIterator(map, keys) {
        this[_map] = map;
        this[_keys] = keys;
        this[_offset] = 0;
        this[_current] = null;
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        let keys = this[_keys];
        let offset = this[_offset];
        if (keys !== dart.dload(this[_map], _keys)) {
          throw new core.ConcurrentModificationError(this[_map]);
        } else if (dart.notNull(offset) >= keys.length) {
          this[_current] = null;
          return false;
        } else {
          this[_current] = dart.as(keys[offset], E);
          this[_offset] = dart.notNull(offset) + 1;
          return true;
        }
      }
    }
    HashMapKeyIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setSignature(HashMapKeyIterator, {
      methods: () => ({moveNext: [core.bool, []]})
    });
    return HashMapKeyIterator;
  });
  let HashMapKeyIterator = HashMapKeyIterator$();
  let _modifications = Symbol('_modifications');
  let _value = Symbol('_value');
  let _newLinkedCell = Symbol('_newLinkedCell');
  let _unlinkCell = Symbol('_unlinkCell');
  let _modified = Symbol('_modified');
  let _key = Symbol('_key');
  let _LinkedHashMap$ = dart.generic(function(K, V) {
    class _LinkedHashMap extends core.Object {
      _LinkedHashMap() {
        this[_length] = 0;
        this[_strings] = null;
        this[_nums] = null;
        this[_rest] = null;
        this[_first] = null;
        this[_last] = null;
        this[_modifications] = 0;
      }
      get length() {
        return this[_length];
      }
      get isEmpty() {
        return this[_length] == 0;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      get keys() {
        return new (LinkedHashMapKeyIterable$(K))(this);
      }
      get values() {
        return new (_internal.MappedIterable$(K, V))(this.keys, dart.fn((each => this.get(each)).bind(this), V, [core.Object]));
      }
      containsKey(key) {
        if (_LinkedHashMap$()._isStringKey(key)) {
          let strings = this[_strings];
          if (strings == null)
            return false;
          let cell = dart.as(_LinkedHashMap$()._getTableEntry(strings, key), LinkedHashMapCell);
          return cell != null;
        } else if (_LinkedHashMap$()._isNumericKey(key)) {
          let nums = this[_nums];
          if (nums == null)
            return false;
          let cell = dart.as(_LinkedHashMap$()._getTableEntry(nums, key), LinkedHashMapCell);
          return cell != null;
        } else {
          return this[_containsKey](key);
        }
      }
      [_containsKey](key) {
        let rest = this[_rest];
        if (rest == null)
          return false;
        let bucket = this[_getBucket](rest, key);
        return dart.notNull(this[_findBucketIndex](bucket, key)) >= 0;
      }
      containsValue(value) {
        return this.keys[core.$any](dart.fn((each => dart.equals(this.get(each), value)).bind(this), core.bool, [core.Object]));
      }
      addAll(other) {
        dart.as(other, core.Map$(K, V));
        other.forEach(dart.fn(((key, value) => {
          dart.as(key, K);
          dart.as(value, V);
          this.set(key, value);
        }).bind(this), core.Object, [K, V]));
      }
      get(key) {
        if (_LinkedHashMap$()._isStringKey(key)) {
          let strings = this[_strings];
          if (strings == null)
            return null;
          let cell = dart.as(_LinkedHashMap$()._getTableEntry(strings, key), LinkedHashMapCell);
          return cell == null ? null : dart.as(cell[_value], V);
        } else if (_LinkedHashMap$()._isNumericKey(key)) {
          let nums = this[_nums];
          if (nums == null)
            return null;
          let cell = dart.as(_LinkedHashMap$()._getTableEntry(nums, key), LinkedHashMapCell);
          return cell == null ? null : dart.as(cell[_value], V);
        } else {
          return this[_get](key);
        }
      }
      [_get](key) {
        let rest = this[_rest];
        if (rest == null)
          return null;
        let bucket = this[_getBucket](rest, key);
        let index = this[_findBucketIndex](bucket, key);
        if (dart.notNull(index) < 0)
          return null;
        let cell = dart.as(bucket[index], LinkedHashMapCell);
        return dart.as(cell[_value], V);
      }
      set(key, value) {
        dart.as(key, K);
        dart.as(value, V);
        if (_LinkedHashMap$()._isStringKey(key)) {
          let strings = this[_strings];
          if (strings == null)
            this[_strings] = strings = _LinkedHashMap$()._newHashTable();
          this[_addHashTableEntry](strings, key, value);
        } else if (_LinkedHashMap$()._isNumericKey(key)) {
          let nums = this[_nums];
          if (nums == null)
            this[_nums] = nums = _LinkedHashMap$()._newHashTable();
          this[_addHashTableEntry](nums, key, value);
        } else {
          this[_set](key, value);
        }
      }
      [_set](key, value) {
        dart.as(key, K);
        dart.as(value, V);
        let rest = this[_rest];
        if (rest == null)
          this[_rest] = rest = _LinkedHashMap$()._newHashTable();
        let hash = this[_computeHashCode](key);
        let bucket = rest[hash];
        if (bucket == null) {
          let cell = this[_newLinkedCell](key, value);
          _LinkedHashMap$()._setTableEntry(rest, hash, [cell]);
        } else {
          let index = this[_findBucketIndex](bucket, key);
          if (dart.notNull(index) >= 0) {
            let cell = dart.as(bucket[index], LinkedHashMapCell);
            cell[_value] = value;
          } else {
            let cell = this[_newLinkedCell](key, value);
            bucket.push(cell);
          }
        }
      }
      putIfAbsent(key, ifAbsent) {
        dart.as(key, K);
        dart.as(ifAbsent, dart.functionType(V, []));
        if (this.containsKey(key))
          return this.get(key);
        let value = ifAbsent();
        this.set(key, value);
        return value;
      }
      remove(key) {
        if (_LinkedHashMap$()._isStringKey(key)) {
          return this[_removeHashTableEntry](this[_strings], key);
        } else if (_LinkedHashMap$()._isNumericKey(key)) {
          return this[_removeHashTableEntry](this[_nums], key);
        } else {
          return this[_remove](key);
        }
      }
      [_remove](key) {
        let rest = this[_rest];
        if (rest == null)
          return null;
        let bucket = this[_getBucket](rest, key);
        let index = this[_findBucketIndex](bucket, key);
        if (dart.notNull(index) < 0)
          return null;
        let cell = dart.as(bucket.splice(index, 1)[0], LinkedHashMapCell);
        this[_unlinkCell](cell);
        return dart.as(cell[_value], V);
      }
      clear() {
        if (dart.notNull(this[_length]) > 0) {
          this[_strings] = this[_nums] = this[_rest] = this[_first] = this[_last] = null;
          this[_length] = 0;
          this[_modified]();
        }
      }
      forEach(action) {
        dart.as(action, dart.functionType(dart.void, [K, V]));
        let cell = this[_first];
        let modifications = this[_modifications];
        while (cell != null) {
          action(dart.as(cell[_key], K), dart.as(cell[_value], V));
          if (modifications != this[_modifications]) {
            throw new core.ConcurrentModificationError(this);
          }
          cell = cell[_next];
        }
      }
      [_addHashTableEntry](table, key, value) {
        dart.as(key, K);
        dart.as(value, V);
        let cell = dart.as(_LinkedHashMap$()._getTableEntry(table, key), LinkedHashMapCell);
        if (cell == null) {
          _LinkedHashMap$()._setTableEntry(table, key, this[_newLinkedCell](key, value));
        } else {
          cell[_value] = value;
        }
      }
      [_removeHashTableEntry](table, key) {
        if (table == null)
          return null;
        let cell = dart.as(_LinkedHashMap$()._getTableEntry(table, key), LinkedHashMapCell);
        if (cell == null)
          return null;
        this[_unlinkCell](cell);
        _LinkedHashMap$()._deleteTableEntry(table, key);
        return dart.as(cell[_value], V);
      }
      [_modified]() {
        this[_modifications] = dart.notNull(this[_modifications]) + 1 & 67108863;
      }
      [_newLinkedCell](key, value) {
        dart.as(key, K);
        dart.as(value, V);
        let cell = new LinkedHashMapCell(key, value);
        if (this[_first] == null) {
          this[_first] = this[_last] = cell;
        } else {
          let last = this[_last];
          cell[_previous] = last;
          this[_last] = last[_next] = cell;
        }
        this[_length] = dart.notNull(this[_length]) + 1;
        this[_modified]();
        return cell;
      }
      [_unlinkCell](cell) {
        let previous = cell[_previous];
        let next = cell[_next];
        if (previous == null) {
          dart.assert(dart.equals(cell, this[_first]));
          this[_first] = next;
        } else {
          previous[_next] = next;
        }
        if (next == null) {
          dart.assert(dart.equals(cell, this[_last]));
          this[_last] = previous;
        } else {
          next[_previous] = previous;
        }
        this[_length] = dart.notNull(this[_length]) - 1;
        this[_modified]();
      }
      static _isStringKey(key) {
        return typeof key == 'string' && dart.notNull(!dart.equals(key, '__proto__'));
      }
      static _isNumericKey(key) {
        return dart.is(key, core.num) && (key & 0x3ffffff) === key;
      }
      [_computeHashCode](key) {
        return dart.hashCode(key) & 0x3ffffff;
      }
      static _getTableEntry(table, key) {
        return table[key];
      }
      static _setTableEntry(table, key, value) {
        dart.assert(value != null);
        table[key] = value;
      }
      static _deleteTableEntry(table, key) {
        delete table[key];
      }
      [_getBucket](table, key) {
        let hash = this[_computeHashCode](key);
        return dart.as(table[hash], core.List);
      }
      [_findBucketIndex](bucket, key) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let cell = dart.as(bucket[i], LinkedHashMapCell);
          if (dart.equals(cell[_key], key))
            return i;
        }
        return -1;
      }
      static _newHashTable() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _LinkedHashMap$()._setTableEntry(table, temporaryKey, table);
        _LinkedHashMap$()._deleteTableEntry(table, temporaryKey);
        return table;
      }
      toString() {
        return Maps.mapToString(this);
      }
    }
    _LinkedHashMap[dart.implements] = () => [LinkedHashMap$(K, V), _js_helper.InternalMap];
    dart.setSignature(_LinkedHashMap, {
      methods: () => ({
        containsKey: [core.bool, [core.Object]],
        [_containsKey]: [core.bool, [core.Object]],
        containsValue: [core.bool, [core.Object]],
        addAll: [dart.void, [core.Map$(K, V)]],
        get: [V, [core.Object]],
        [_get]: [V, [core.Object]],
        set: [dart.void, [K, V]],
        [_set]: [dart.void, [K, V]],
        putIfAbsent: [V, [K, dart.functionType(V, [])]],
        remove: [V, [core.Object]],
        [_remove]: [V, [core.Object]],
        clear: [dart.void, []],
        forEach: [dart.void, [dart.functionType(dart.void, [K, V])]],
        [_addHashTableEntry]: [dart.void, [core.Object, K, V]],
        [_removeHashTableEntry]: [V, [core.Object, core.Object]],
        [_modified]: [dart.void, []],
        [_newLinkedCell]: [LinkedHashMapCell, [K, V]],
        [_unlinkCell]: [dart.void, [LinkedHashMapCell]],
        [_computeHashCode]: [core.int, [core.Object]],
        [_getBucket]: [core.List, [core.Object, core.Object]],
        [_findBucketIndex]: [core.int, [core.Object, core.Object]]
      }),
      statics: () => ({
        _isStringKey: [core.bool, [core.Object]],
        _isNumericKey: [core.bool, [core.Object]],
        _getTableEntry: [core.Object, [core.Object, core.Object]],
        _setTableEntry: [dart.void, [core.Object, core.Object, core.Object]],
        _deleteTableEntry: [dart.void, [core.Object, core.Object]],
        _newHashTable: [core.Object, []]
      }),
      names: ['_isStringKey', '_isNumericKey', '_getTableEntry', '_setTableEntry', '_deleteTableEntry', '_newHashTable']
    });
    return _LinkedHashMap;
  });
  let _LinkedHashMap = _LinkedHashMap$();
  let _LinkedIdentityHashMap$ = dart.generic(function(K, V) {
    class _LinkedIdentityHashMap extends _LinkedHashMap$(K, V) {
      _LinkedIdentityHashMap() {
        super._LinkedHashMap();
      }
      [_computeHashCode](key) {
        return core.identityHashCode(key) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, key) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let cell = dart.as(bucket[i], LinkedHashMapCell);
          if (core.identical(cell[_key], key))
            return i;
        }
        return -1;
      }
    }
    return _LinkedIdentityHashMap;
  });
  let _LinkedIdentityHashMap = _LinkedIdentityHashMap$();
  let _LinkedCustomHashMap$ = dart.generic(function(K, V) {
    class _LinkedCustomHashMap extends _LinkedHashMap$(K, V) {
      _LinkedCustomHashMap(equals, hashCode, validKey) {
        this[_equals] = equals;
        this[_hashCode] = hashCode;
        this[_validKey] = validKey != null ? validKey : dart.fn(v => dart.is(v, K), core.bool, [core.Object]);
        super._LinkedHashMap();
      }
      get(key) {
        if (!dart.notNull(this[_validKey](key)))
          return null;
        return super[_get](key);
      }
      set(key, value) {
        dart.as(key, K);
        dart.as(value, V);
        super[_set](key, value);
      }
      containsKey(key) {
        if (!dart.notNull(this[_validKey](key)))
          return false;
        return super[_containsKey](key);
      }
      remove(key) {
        if (!dart.notNull(this[_validKey](key)))
          return null;
        return super[_remove](key);
      }
      [_computeHashCode](key) {
        return this[_hashCode](dart.as(key, K)) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, key) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let cell = dart.as(bucket[i], LinkedHashMapCell);
          if (this[_equals](dart.as(cell[_key], K), dart.as(key, K)))
            return i;
        }
        return -1;
      }
    }
    dart.setSignature(_LinkedCustomHashMap, {
      methods: () => ({
        get: [V, [core.Object]],
        set: [dart.void, [K, V]],
        remove: [V, [core.Object]]
      })
    });
    return _LinkedCustomHashMap;
  });
  let _LinkedCustomHashMap = _LinkedCustomHashMap$();
  class LinkedHashMapCell extends core.Object {
    LinkedHashMapCell(key, value) {
      this[_key] = key;
      this[_value] = value;
      this[_next] = null;
      this[_previous] = null;
    }
  }
  let LinkedHashMapKeyIterable$ = dart.generic(function(E) {
    class LinkedHashMapKeyIterable extends IterableBase$(E) {
      LinkedHashMapKeyIterable(map) {
        this[_map] = map;
        super.IterableBase();
      }
      get [core.$length]() {
        return dart.as(dart.dload(this[_map], _length), core.int);
      }
      get [core.$isEmpty]() {
        return dart.equals(dart.dload(this[_map], _length), 0);
      }
      get [core.$iterator]() {
        return new (LinkedHashMapKeyIterator$(E))(this[_map], dart.as(dart.dload(this[_map], _modifications), core.int));
      }
      [core.$contains](element) {
        return dart.as(dart.dsend(this[_map], 'containsKey', element), core.bool);
      }
      [core.$forEach](f) {
        dart.as(f, dart.functionType(dart.void, [E]));
        let cell = dart.as(dart.dload(this[_map], _first), LinkedHashMapCell);
        let modifications = dart.as(dart.dload(this[_map], _modifications), core.int);
        while (cell != null) {
          f(dart.as(cell[_key], E));
          if (!dart.equals(modifications, dart.dload(this[_map], _modifications))) {
            throw new core.ConcurrentModificationError(this[_map]);
          }
          cell = cell[_next];
        }
      }
    }
    LinkedHashMapKeyIterable[dart.implements] = () => [_internal.EfficientLength];
    dart.setSignature(LinkedHashMapKeyIterable, {
      methods: () => ({[core.$forEach]: [dart.void, [dart.functionType(dart.void, [E])]]})
    });
    return LinkedHashMapKeyIterable;
  });
  let LinkedHashMapKeyIterable = LinkedHashMapKeyIterable$();
  let _cell = Symbol('_cell');
  let LinkedHashMapKeyIterator$ = dart.generic(function(E) {
    class LinkedHashMapKeyIterator extends core.Object {
      LinkedHashMapKeyIterator(map, modifications) {
        this[_map] = map;
        this[_modifications] = modifications;
        this[_cell] = null;
        this[_current] = null;
        this[_cell] = dart.as(dart.dload(this[_map], _first), LinkedHashMapCell);
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        if (!dart.equals(this[_modifications], dart.dload(this[_map], _modifications))) {
          throw new core.ConcurrentModificationError(this[_map]);
        } else if (this[_cell] == null) {
          this[_current] = null;
          return false;
        } else {
          this[_current] = dart.as(this[_cell][_key], E);
          this[_cell] = this[_cell][_next];
          return true;
        }
      }
    }
    LinkedHashMapKeyIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setSignature(LinkedHashMapKeyIterator, {
      methods: () => ({moveNext: [core.bool, []]})
    });
    return LinkedHashMapKeyIterator;
  });
  let LinkedHashMapKeyIterator = LinkedHashMapKeyIterator$();
  let _elements = Symbol('_elements');
  let _computeElements = Symbol('_computeElements');
  let _contains = Symbol('_contains');
  let _lookup = Symbol('_lookup');
  let _HashSet$ = dart.generic(function(E) {
    class _HashSet extends _HashSetBase$(E) {
      _HashSet() {
        this[_length] = 0;
        this[_strings] = null;
        this[_nums] = null;
        this[_rest] = null;
        this[_elements] = null;
      }
      [_newSet]() {
        return new (_HashSet$(E))();
      }
      get [core.$iterator]() {
        return new (HashSetIterator$(E))(this, this[_computeElements]());
      }
      get [core.$length]() {
        return this[_length];
      }
      get [core.$isEmpty]() {
        return this[_length] == 0;
      }
      get [core.$isNotEmpty]() {
        return !dart.notNull(this[core.$isEmpty]);
      }
      [core.$contains](object) {
        if (_HashSet$()._isStringElement(object)) {
          let strings = this[_strings];
          return strings == null ? false : _HashSet$()._hasTableEntry(strings, object);
        } else if (_HashSet$()._isNumericElement(object)) {
          let nums = this[_nums];
          return nums == null ? false : _HashSet$()._hasTableEntry(nums, object);
        } else {
          return this[_contains](object);
        }
      }
      [_contains](object) {
        let rest = this[_rest];
        if (rest == null)
          return false;
        let bucket = this[_getBucket](rest, object);
        return dart.notNull(this[_findBucketIndex](bucket, object)) >= 0;
      }
      lookup(object) {
        if (dart.notNull(_HashSet$()._isStringElement(object)) || dart.notNull(_HashSet$()._isNumericElement(object))) {
          return dart.as(this[core.$contains](object) ? object : null, E);
        }
        return this[_lookup](object);
      }
      [_lookup](object) {
        let rest = this[_rest];
        if (rest == null)
          return null;
        let bucket = this[_getBucket](rest, object);
        let index = this[_findBucketIndex](bucket, object);
        if (dart.notNull(index) < 0)
          return null;
        return dart.as(bucket[core.$get](index), E);
      }
      add(element) {
        dart.as(element, E);
        if (_HashSet$()._isStringElement(element)) {
          let strings = this[_strings];
          if (strings == null)
            this[_strings] = strings = _HashSet$()._newHashTable();
          return this[_addHashTableEntry](strings, element);
        } else if (_HashSet$()._isNumericElement(element)) {
          let nums = this[_nums];
          if (nums == null)
            this[_nums] = nums = _HashSet$()._newHashTable();
          return this[_addHashTableEntry](nums, element);
        } else {
          return this[_add](element);
        }
      }
      [_add](element) {
        dart.as(element, E);
        let rest = this[_rest];
        if (rest == null)
          this[_rest] = rest = _HashSet$()._newHashTable();
        let hash = this[_computeHashCode](element);
        let bucket = rest[hash];
        if (bucket == null) {
          _HashSet$()._setTableEntry(rest, hash, [element]);
        } else {
          let index = this[_findBucketIndex](bucket, element);
          if (dart.notNull(index) >= 0)
            return false;
          bucket.push(element);
        }
        this[_length] = dart.notNull(this[_length]) + 1;
        this[_elements] = null;
        return true;
      }
      addAll(objects) {
        dart.as(objects, core.Iterable$(E));
        for (let each of objects) {
          this.add(each);
        }
      }
      remove(object) {
        if (_HashSet$()._isStringElement(object)) {
          return this[_removeHashTableEntry](this[_strings], object);
        } else if (_HashSet$()._isNumericElement(object)) {
          return this[_removeHashTableEntry](this[_nums], object);
        } else {
          return this[_remove](object);
        }
      }
      [_remove](object) {
        let rest = this[_rest];
        if (rest == null)
          return false;
        let bucket = this[_getBucket](rest, object);
        let index = this[_findBucketIndex](bucket, object);
        if (dart.notNull(index) < 0)
          return false;
        this[_length] = dart.notNull(this[_length]) - 1;
        this[_elements] = null;
        bucket.splice(index, 1);
        return true;
      }
      clear() {
        if (dart.notNull(this[_length]) > 0) {
          this[_strings] = this[_nums] = this[_rest] = this[_elements] = null;
          this[_length] = 0;
        }
      }
      [_computeElements]() {
        if (this[_elements] != null)
          return this[_elements];
        let result = new core.List(this[_length]);
        let index = 0;
        let strings = this[_strings];
        if (strings != null) {
          let names = Object.getOwnPropertyNames(strings);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); i = dart.notNull(i) + 1) {
            let element = names[i];
            result[index] = element;
            index = dart.notNull(index) + 1;
          }
        }
        let nums = this[_nums];
        if (nums != null) {
          let names = Object.getOwnPropertyNames(nums);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); i = dart.notNull(i) + 1) {
            let element = +names[i];
            result[index] = element;
            index = dart.notNull(index) + 1;
          }
        }
        let rest = this[_rest];
        if (rest != null) {
          let names = Object.getOwnPropertyNames(rest);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); i = dart.notNull(i) + 1) {
            let entry = names[i];
            let bucket = rest[entry];
            let length = bucket.length;
            for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
              result[index] = bucket[i];
              index = dart.notNull(index) + 1;
            }
          }
        }
        dart.assert(index == this[_length]);
        return this[_elements] = result;
      }
      [_addHashTableEntry](table, element) {
        dart.as(element, E);
        if (_HashSet$()._hasTableEntry(table, element))
          return false;
        _HashSet$()._setTableEntry(table, element, 0);
        this[_length] = dart.notNull(this[_length]) + 1;
        this[_elements] = null;
        return true;
      }
      [_removeHashTableEntry](table, element) {
        if (dart.notNull(table != null) && dart.notNull(_HashSet$()._hasTableEntry(table, element))) {
          _HashSet$()._deleteTableEntry(table, element);
          this[_length] = dart.notNull(this[_length]) - 1;
          this[_elements] = null;
          return true;
        } else {
          return false;
        }
      }
      static _isStringElement(element) {
        return typeof element == 'string' && dart.notNull(!dart.equals(element, '__proto__'));
      }
      static _isNumericElement(element) {
        return dart.is(element, core.num) && (element & 0x3ffffff) === element;
      }
      [_computeHashCode](element) {
        return dart.hashCode(element) & 0x3ffffff;
      }
      static _hasTableEntry(table, key) {
        let entry = table[key];
        return entry != null;
      }
      static _setTableEntry(table, key, value) {
        dart.assert(value != null);
        table[key] = value;
      }
      static _deleteTableEntry(table, key) {
        delete table[key];
      }
      [_getBucket](table, element) {
        let hash = this[_computeHashCode](element);
        return dart.as(table[hash], core.List);
      }
      [_findBucketIndex](bucket, element) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          if (dart.equals(bucket[i], element))
            return i;
        }
        return -1;
      }
      static _newHashTable() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _HashSet$()._setTableEntry(table, temporaryKey, table);
        _HashSet$()._deleteTableEntry(table, temporaryKey);
        return table;
      }
    }
    _HashSet[dart.implements] = () => [HashSet$(E)];
    dart.setSignature(_HashSet, {
      methods: () => ({
        [_newSet]: [core.Set$(E), []],
        [core.$contains]: [core.bool, [core.Object]],
        [_contains]: [core.bool, [core.Object]],
        lookup: [E, [core.Object]],
        [_lookup]: [E, [core.Object]],
        add: [core.bool, [E]],
        [_add]: [core.bool, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        remove: [core.bool, [core.Object]],
        [_remove]: [core.bool, [core.Object]],
        [_computeElements]: [core.List, []],
        [_addHashTableEntry]: [core.bool, [core.Object, E]],
        [_removeHashTableEntry]: [core.bool, [core.Object, core.Object]],
        [_computeHashCode]: [core.int, [core.Object]],
        [_getBucket]: [core.List, [core.Object, core.Object]],
        [_findBucketIndex]: [core.int, [core.Object, core.Object]]
      }),
      statics: () => ({
        _isStringElement: [core.bool, [core.Object]],
        _isNumericElement: [core.bool, [core.Object]],
        _hasTableEntry: [core.bool, [core.Object, core.Object]],
        _setTableEntry: [dart.void, [core.Object, core.Object, core.Object]],
        _deleteTableEntry: [dart.void, [core.Object, core.Object]],
        _newHashTable: [core.Object, []]
      }),
      names: ['_isStringElement', '_isNumericElement', '_hasTableEntry', '_setTableEntry', '_deleteTableEntry', '_newHashTable']
    });
    return _HashSet;
  });
  let _HashSet = _HashSet$();
  let _IdentityHashSet$ = dart.generic(function(E) {
    class _IdentityHashSet extends _HashSet$(E) {
      _IdentityHashSet() {
        super._HashSet();
      }
      [_newSet]() {
        return new (_IdentityHashSet$(E))();
      }
      [_computeHashCode](key) {
        return core.identityHashCode(key) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, element) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          if (core.identical(bucket[i], element))
            return i;
        }
        return -1;
      }
    }
    dart.setSignature(_IdentityHashSet, {
      methods: () => ({[_newSet]: [core.Set$(E), []]})
    });
    return _IdentityHashSet;
  });
  let _IdentityHashSet = _IdentityHashSet$();
  let _equality = Symbol('_equality');
  let _hasher = Symbol('_hasher');
  let _CustomHashSet$ = dart.generic(function(E) {
    class _CustomHashSet extends _HashSet$(E) {
      _CustomHashSet(equality, hasher, validKey) {
        this[_equality] = equality;
        this[_hasher] = hasher;
        this[_validKey] = validKey != null ? validKey : dart.fn(x => dart.is(x, E), core.bool, [core.Object]);
        super._HashSet();
      }
      [_newSet]() {
        return new (_CustomHashSet$(E))(this[_equality], this[_hasher], this[_validKey]);
      }
      [_findBucketIndex](bucket, element) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          if (this[_equality](dart.as(bucket[i], E), dart.as(element, E)))
            return i;
        }
        return -1;
      }
      [_computeHashCode](element) {
        return this[_hasher](dart.as(element, E)) & 0x3ffffff;
      }
      add(object) {
        dart.as(object, E);
        return super[_add](object);
      }
      [core.$contains](object) {
        if (!dart.notNull(this[_validKey](object)))
          return false;
        return super[_contains](object);
      }
      lookup(object) {
        if (!dart.notNull(this[_validKey](object)))
          return null;
        return super[_lookup](object);
      }
      remove(object) {
        if (!dart.notNull(this[_validKey](object)))
          return false;
        return super[_remove](object);
      }
    }
    dart.setSignature(_CustomHashSet, {
      methods: () => ({
        [_newSet]: [core.Set$(E), []],
        add: [core.bool, [E]],
        lookup: [E, [core.Object]]
      })
    });
    return _CustomHashSet;
  });
  let _CustomHashSet = _CustomHashSet$();
  let HashSetIterator$ = dart.generic(function(E) {
    class HashSetIterator extends core.Object {
      HashSetIterator(set, elements) {
        this[_set] = set;
        this[_elements] = elements;
        this[_offset] = 0;
        this[_current] = null;
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        let elements = this[_elements];
        let offset = this[_offset];
        if (elements !== dart.dload(this[_set], _elements)) {
          throw new core.ConcurrentModificationError(this[_set]);
        } else if (dart.notNull(offset) >= elements.length) {
          this[_current] = null;
          return false;
        } else {
          this[_current] = dart.as(elements[offset], E);
          this[_offset] = dart.notNull(offset) + 1;
          return true;
        }
      }
    }
    HashSetIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setSignature(HashSetIterator, {
      methods: () => ({moveNext: [core.bool, []]})
    });
    return HashSetIterator;
  });
  let HashSetIterator = HashSetIterator$();
  let _unsupported = Symbol('_unsupported');
  let _LinkedHashSet$ = dart.generic(function(E) {
    class _LinkedHashSet extends _HashSetBase$(E) {
      _LinkedHashSet() {
        this[_length] = 0;
        this[_strings] = null;
        this[_nums] = null;
        this[_rest] = null;
        this[_first] = null;
        this[_last] = null;
        this[_modifications] = 0;
      }
      [_newSet]() {
        return new (_LinkedHashSet$(E))();
      }
      [_unsupported](operation) {
        throw `LinkedHashSet: unsupported ${operation}`;
      }
      get [core.$iterator]() {
        return new (LinkedHashSetIterator$(E))(this, this[_modifications]);
      }
      get [core.$length]() {
        return this[_length];
      }
      get [core.$isEmpty]() {
        return this[_length] == 0;
      }
      get [core.$isNotEmpty]() {
        return !dart.notNull(this[core.$isEmpty]);
      }
      [core.$contains](object) {
        if (_LinkedHashSet$()._isStringElement(object)) {
          let strings = this[_strings];
          if (strings == null)
            return false;
          let cell = dart.as(_LinkedHashSet$()._getTableEntry(strings, object), LinkedHashSetCell);
          return cell != null;
        } else if (_LinkedHashSet$()._isNumericElement(object)) {
          let nums = this[_nums];
          if (nums == null)
            return false;
          let cell = dart.as(_LinkedHashSet$()._getTableEntry(nums, object), LinkedHashSetCell);
          return cell != null;
        } else {
          return this[_contains](object);
        }
      }
      [_contains](object) {
        let rest = this[_rest];
        if (rest == null)
          return false;
        let bucket = this[_getBucket](rest, object);
        return dart.notNull(this[_findBucketIndex](bucket, object)) >= 0;
      }
      lookup(object) {
        if (dart.notNull(_LinkedHashSet$()._isStringElement(object)) || dart.notNull(_LinkedHashSet$()._isNumericElement(object))) {
          return dart.as(this[core.$contains](object) ? object : null, E);
        } else {
          return this[_lookup](object);
        }
      }
      [_lookup](object) {
        let rest = this[_rest];
        if (rest == null)
          return null;
        let bucket = this[_getBucket](rest, object);
        let index = this[_findBucketIndex](bucket, object);
        if (dart.notNull(index) < 0)
          return null;
        return dart.as(dart.dload(bucket[core.$get](index), _element), E);
      }
      [core.$forEach](action) {
        dart.as(action, dart.functionType(dart.void, [E]));
        let cell = this[_first];
        let modifications = this[_modifications];
        while (cell != null) {
          action(dart.as(cell[_element], E));
          if (modifications != this[_modifications]) {
            throw new core.ConcurrentModificationError(this);
          }
          cell = cell[_next];
        }
      }
      get [core.$first]() {
        if (this[_first] == null)
          throw new core.StateError("No elements");
        return dart.as(this[_first][_element], E);
      }
      get [core.$last]() {
        if (this[_last] == null)
          throw new core.StateError("No elements");
        return dart.as(this[_last][_element], E);
      }
      add(element) {
        dart.as(element, E);
        if (_LinkedHashSet$()._isStringElement(element)) {
          let strings = this[_strings];
          if (strings == null)
            this[_strings] = strings = _LinkedHashSet$()._newHashTable();
          return this[_addHashTableEntry](strings, element);
        } else if (_LinkedHashSet$()._isNumericElement(element)) {
          let nums = this[_nums];
          if (nums == null)
            this[_nums] = nums = _LinkedHashSet$()._newHashTable();
          return this[_addHashTableEntry](nums, element);
        } else {
          return this[_add](element);
        }
      }
      [_add](element) {
        dart.as(element, E);
        let rest = this[_rest];
        if (rest == null)
          this[_rest] = rest = _LinkedHashSet$()._newHashTable();
        let hash = this[_computeHashCode](element);
        let bucket = rest[hash];
        if (bucket == null) {
          let cell = this[_newLinkedCell](element);
          _LinkedHashSet$()._setTableEntry(rest, hash, [cell]);
        } else {
          let index = this[_findBucketIndex](bucket, element);
          if (dart.notNull(index) >= 0)
            return false;
          let cell = this[_newLinkedCell](element);
          bucket.push(cell);
        }
        return true;
      }
      remove(object) {
        if (_LinkedHashSet$()._isStringElement(object)) {
          return this[_removeHashTableEntry](this[_strings], object);
        } else if (_LinkedHashSet$()._isNumericElement(object)) {
          return this[_removeHashTableEntry](this[_nums], object);
        } else {
          return this[_remove](object);
        }
      }
      [_remove](object) {
        let rest = this[_rest];
        if (rest == null)
          return false;
        let bucket = this[_getBucket](rest, object);
        let index = this[_findBucketIndex](bucket, object);
        if (dart.notNull(index) < 0)
          return false;
        let cell = dart.as(bucket.splice(index, 1)[0], LinkedHashSetCell);
        this[_unlinkCell](cell);
        return true;
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_filterWhere](test, true);
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        this[_filterWhere](test, false);
      }
      [_filterWhere](test, removeMatching) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let cell = this[_first];
        while (cell != null) {
          let element = dart.as(cell[_element], E);
          let next = cell[_next];
          let modifications = this[_modifications];
          let shouldRemove = removeMatching == test(element);
          if (modifications != this[_modifications]) {
            throw new core.ConcurrentModificationError(this);
          }
          if (shouldRemove)
            this.remove(element);
          cell = next;
        }
      }
      clear() {
        if (dart.notNull(this[_length]) > 0) {
          this[_strings] = this[_nums] = this[_rest] = this[_first] = this[_last] = null;
          this[_length] = 0;
          this[_modified]();
        }
      }
      [_addHashTableEntry](table, element) {
        dart.as(element, E);
        let cell = dart.as(_LinkedHashSet$()._getTableEntry(table, element), LinkedHashSetCell);
        if (cell != null)
          return false;
        _LinkedHashSet$()._setTableEntry(table, element, this[_newLinkedCell](element));
        return true;
      }
      [_removeHashTableEntry](table, element) {
        if (table == null)
          return false;
        let cell = dart.as(_LinkedHashSet$()._getTableEntry(table, element), LinkedHashSetCell);
        if (cell == null)
          return false;
        this[_unlinkCell](cell);
        _LinkedHashSet$()._deleteTableEntry(table, element);
        return true;
      }
      [_modified]() {
        this[_modifications] = dart.notNull(this[_modifications]) + 1 & 67108863;
      }
      [_newLinkedCell](element) {
        dart.as(element, E);
        let cell = new LinkedHashSetCell(element);
        if (this[_first] == null) {
          this[_first] = this[_last] = cell;
        } else {
          let last = this[_last];
          cell[_previous] = last;
          this[_last] = last[_next] = cell;
        }
        this[_length] = dart.notNull(this[_length]) + 1;
        this[_modified]();
        return cell;
      }
      [_unlinkCell](cell) {
        let previous = cell[_previous];
        let next = cell[_next];
        if (previous == null) {
          dart.assert(dart.equals(cell, this[_first]));
          this[_first] = next;
        } else {
          previous[_next] = next;
        }
        if (next == null) {
          dart.assert(dart.equals(cell, this[_last]));
          this[_last] = previous;
        } else {
          next[_previous] = previous;
        }
        this[_length] = dart.notNull(this[_length]) - 1;
        this[_modified]();
      }
      static _isStringElement(element) {
        return typeof element == 'string' && dart.notNull(!dart.equals(element, '__proto__'));
      }
      static _isNumericElement(element) {
        return dart.is(element, core.num) && (element & 0x3ffffff) === element;
      }
      [_computeHashCode](element) {
        return dart.hashCode(element) & 0x3ffffff;
      }
      static _getTableEntry(table, key) {
        return table[key];
      }
      static _setTableEntry(table, key, value) {
        dart.assert(value != null);
        table[key] = value;
      }
      static _deleteTableEntry(table, key) {
        delete table[key];
      }
      [_getBucket](table, element) {
        let hash = this[_computeHashCode](element);
        return dart.as(table[hash], core.List);
      }
      [_findBucketIndex](bucket, element) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let cell = dart.as(bucket[i], LinkedHashSetCell);
          if (dart.equals(cell[_element], element))
            return i;
        }
        return -1;
      }
      static _newHashTable() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _LinkedHashSet$()._setTableEntry(table, temporaryKey, table);
        _LinkedHashSet$()._deleteTableEntry(table, temporaryKey);
        return table;
      }
    }
    _LinkedHashSet[dart.implements] = () => [LinkedHashSet$(E)];
    dart.setSignature(_LinkedHashSet, {
      methods: () => ({
        [_newSet]: [core.Set$(E), []],
        [_unsupported]: [dart.void, [core.String]],
        [core.$contains]: [core.bool, [core.Object]],
        [_contains]: [core.bool, [core.Object]],
        lookup: [E, [core.Object]],
        [_lookup]: [E, [core.Object]],
        [core.$forEach]: [dart.void, [dart.functionType(dart.void, [E])]],
        add: [core.bool, [E]],
        [_add]: [core.bool, [E]],
        remove: [core.bool, [core.Object]],
        [_remove]: [core.bool, [core.Object]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        [_filterWhere]: [dart.void, [dart.functionType(core.bool, [E]), core.bool]],
        [_addHashTableEntry]: [core.bool, [core.Object, E]],
        [_removeHashTableEntry]: [core.bool, [core.Object, core.Object]],
        [_modified]: [dart.void, []],
        [_newLinkedCell]: [LinkedHashSetCell, [E]],
        [_unlinkCell]: [dart.void, [LinkedHashSetCell]],
        [_computeHashCode]: [core.int, [core.Object]],
        [_getBucket]: [core.List, [core.Object, core.Object]],
        [_findBucketIndex]: [core.int, [core.Object, core.Object]]
      }),
      statics: () => ({
        _isStringElement: [core.bool, [core.Object]],
        _isNumericElement: [core.bool, [core.Object]],
        _getTableEntry: [core.Object, [core.Object, core.Object]],
        _setTableEntry: [dart.void, [core.Object, core.Object, core.Object]],
        _deleteTableEntry: [dart.void, [core.Object, core.Object]],
        _newHashTable: [core.Object, []]
      }),
      names: ['_isStringElement', '_isNumericElement', '_getTableEntry', '_setTableEntry', '_deleteTableEntry', '_newHashTable']
    });
    return _LinkedHashSet;
  });
  let _LinkedHashSet = _LinkedHashSet$();
  let _LinkedIdentityHashSet$ = dart.generic(function(E) {
    class _LinkedIdentityHashSet extends _LinkedHashSet$(E) {
      _LinkedIdentityHashSet() {
        super._LinkedHashSet();
      }
      [_newSet]() {
        return new (_LinkedIdentityHashSet$(E))();
      }
      [_computeHashCode](key) {
        return core.identityHashCode(key) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, element) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let cell = dart.as(bucket[i], LinkedHashSetCell);
          if (core.identical(cell[_element], element))
            return i;
        }
        return -1;
      }
    }
    dart.setSignature(_LinkedIdentityHashSet, {
      methods: () => ({[_newSet]: [core.Set$(E), []]})
    });
    return _LinkedIdentityHashSet;
  });
  let _LinkedIdentityHashSet = _LinkedIdentityHashSet$();
  let _LinkedCustomHashSet$ = dart.generic(function(E) {
    class _LinkedCustomHashSet extends _LinkedHashSet$(E) {
      _LinkedCustomHashSet(equality, hasher, validKey) {
        this[_equality] = equality;
        this[_hasher] = hasher;
        this[_validKey] = validKey != null ? validKey : dart.fn(x => dart.is(x, E), core.bool, [core.Object]);
        super._LinkedHashSet();
      }
      [_newSet]() {
        return new (_LinkedCustomHashSet$(E))(this[_equality], this[_hasher], this[_validKey]);
      }
      [_findBucketIndex](bucket, element) {
        if (bucket == null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let cell = dart.as(bucket[i], LinkedHashSetCell);
          if (this[_equality](dart.as(cell[_element], E), dart.as(element, E)))
            return i;
        }
        return -1;
      }
      [_computeHashCode](element) {
        return this[_hasher](dart.as(element, E)) & 0x3ffffff;
      }
      add(element) {
        dart.as(element, E);
        return super[_add](element);
      }
      [core.$contains](object) {
        if (!dart.notNull(this[_validKey](object)))
          return false;
        return super[_contains](object);
      }
      lookup(object) {
        if (!dart.notNull(this[_validKey](object)))
          return null;
        return super[_lookup](object);
      }
      remove(object) {
        if (!dart.notNull(this[_validKey](object)))
          return false;
        return super[_remove](object);
      }
      containsAll(elements) {
        for (let element of elements) {
          if (!dart.notNull(this[_validKey](element)) || !dart.notNull(this[core.$contains](element)))
            return false;
        }
        return true;
      }
      removeAll(elements) {
        for (let element of elements) {
          if (this[_validKey](element)) {
            super[_remove](element);
          }
        }
      }
    }
    dart.setSignature(_LinkedCustomHashSet, {
      methods: () => ({
        [_newSet]: [core.Set$(E), []],
        add: [core.bool, [E]],
        lookup: [E, [core.Object]]
      })
    });
    return _LinkedCustomHashSet;
  });
  let _LinkedCustomHashSet = _LinkedCustomHashSet$();
  class LinkedHashSetCell extends core.Object {
    LinkedHashSetCell(element) {
      this[_element] = element;
      this[_next] = null;
      this[_previous] = null;
    }
  }
  let LinkedHashSetIterator$ = dart.generic(function(E) {
    class LinkedHashSetIterator extends core.Object {
      LinkedHashSetIterator(set, modifications) {
        this[_set] = set;
        this[_modifications] = modifications;
        this[_cell] = null;
        this[_current] = null;
        this[_cell] = dart.as(dart.dload(this[_set], _first), LinkedHashSetCell);
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        if (!dart.equals(this[_modifications], dart.dload(this[_set], _modifications))) {
          throw new core.ConcurrentModificationError(this[_set]);
        } else if (this[_cell] == null) {
          this[_current] = null;
          return false;
        } else {
          this[_current] = dart.as(this[_cell][_element], E);
          this[_cell] = this[_cell][_next];
          return true;
        }
      }
    }
    LinkedHashSetIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setSignature(LinkedHashSetIterator, {
      methods: () => ({moveNext: [core.bool, []]})
    });
    return LinkedHashSetIterator;
  });
  let LinkedHashSetIterator = LinkedHashSetIterator$();
  // Exports:
  exports.UnmodifiableListView$ = UnmodifiableListView$;
  exports.HashMap$ = HashMap$;
  exports.HashMap = HashMap;
  exports.SetMixin$ = SetMixin$;
  exports.SetMixin = SetMixin;
  exports.SetBase$ = SetBase$;
  exports.SetBase = SetBase;
  exports.HashSet$ = HashSet$;
  exports.HashSet = HashSet;
  exports.IterableMixin$ = IterableMixin$;
  exports.IterableMixin = IterableMixin;
  exports.IterableBase$ = IterableBase$;
  exports.IterableBase = IterableBase;
  exports.HasNextIterator$ = HasNextIterator$;
  exports.HasNextIterator = HasNextIterator;
  exports.LinkedHashMap$ = LinkedHashMap$;
  exports.LinkedHashMap = LinkedHashMap;
  exports.LinkedHashSet$ = LinkedHashSet$;
  exports.LinkedHashSet = LinkedHashSet;
  exports.LinkedList$ = LinkedList$;
  exports.LinkedList = LinkedList;
  exports.LinkedListEntry$ = LinkedListEntry$;
  exports.LinkedListEntry = LinkedListEntry;
  exports.ListMixin$ = ListMixin$;
  exports.ListMixin = ListMixin;
  exports.ListBase$ = ListBase$;
  exports.ListBase = ListBase;
  exports.MapMixin$ = MapMixin$;
  exports.MapMixin = MapMixin;
  exports.MapBase$ = MapBase$;
  exports.MapBase = MapBase;
  exports.UnmodifiableMapBase$ = UnmodifiableMapBase$;
  exports.UnmodifiableMapBase = UnmodifiableMapBase;
  exports.MapView$ = MapView$;
  exports.MapView = MapView;
  exports.UnmodifiableMapView$ = UnmodifiableMapView$;
  exports.UnmodifiableMapView = UnmodifiableMapView;
  exports.Maps = Maps;
  exports.Queue$ = Queue$;
  exports.Queue = Queue;
  exports.DoubleLinkedQueueEntry$ = DoubleLinkedQueueEntry$;
  exports.DoubleLinkedQueueEntry = DoubleLinkedQueueEntry;
  exports.DoubleLinkedQueue$ = DoubleLinkedQueue$;
  exports.DoubleLinkedQueue = DoubleLinkedQueue;
  exports.ListQueue$ = ListQueue$;
  exports.ListQueue = ListQueue;
  exports.SplayTreeMap$ = SplayTreeMap$;
  exports.SplayTreeMap = SplayTreeMap;
  exports.SplayTreeSet$ = SplayTreeSet$;
  exports.SplayTreeSet = SplayTreeSet;
  exports.HashMapKeyIterable$ = HashMapKeyIterable$;
  exports.HashMapKeyIterable = HashMapKeyIterable;
  exports.HashMapKeyIterator$ = HashMapKeyIterator$;
  exports.HashMapKeyIterator = HashMapKeyIterator;
  exports.LinkedHashMapCell = LinkedHashMapCell;
  exports.LinkedHashMapKeyIterable$ = LinkedHashMapKeyIterable$;
  exports.LinkedHashMapKeyIterable = LinkedHashMapKeyIterable;
  exports.LinkedHashMapKeyIterator$ = LinkedHashMapKeyIterator$;
  exports.LinkedHashMapKeyIterator = LinkedHashMapKeyIterator;
  exports.HashSetIterator$ = HashSetIterator$;
  exports.HashSetIterator = HashSetIterator;
  exports.LinkedHashSetCell = LinkedHashSetCell;
  exports.LinkedHashSetIterator$ = LinkedHashSetIterator$;
  exports.LinkedHashSetIterator = LinkedHashSetIterator;
})(collection, _internal, core, _js_helper, math);
