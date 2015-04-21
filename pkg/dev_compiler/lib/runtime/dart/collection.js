var collection;
(function(exports) {
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
    return UnmodifiableListView;
  });
  dart.defineLazyClassGeneric(exports, 'UnmodifiableListView', {get: UnmodifiableListView$});
  // Function _defaultEquals: (dynamic, dynamic) → bool
  function _defaultEquals(a, b) {
    return dart.equals(a, b);
  }
  // Function _defaultHashCode: (dynamic) → int
  function _defaultHashCode(a) {
    return a.hashCode;
  }
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
  let _fillMapWithMappedIterable = Symbol('_fillMapWithMappedIterable');
  let _fillMapWithIterables = Symbol('_fillMapWithIterables');
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
            hashCode = dart.as(_defaultHashCode, __CastType0);
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new (_IdentityHashMap$(K, V))();
            }
            if (equals == null) {
              equals = dart.as(_defaultEquals, __CastType2);
            }
          }
        } else {
          if (hashCode == null) {
            hashCode = dart.as(_defaultHashCode, dart.functionType(core.int, [K]));
          }
          if (equals == null) {
            equals = dart.as(_defaultEquals, dart.functionType(core.bool, [K, K]));
          }
        }
        return new (_CustomHashMap$(K, V))(equals, hashCode, isValidKey);
      }
      identity() {
        return new (_IdentityHashMap$(K, V))();
      }
      from(other) {
        let result = new (HashMap$(K, V))();
        other.forEach((k, v) => {
          result.set(k, dart.as(v, V));
        });
        return result;
      }
      fromIterable(iterable, opts) {
        let key = opts && 'key' in opts ? opts.key : null;
        let value = opts && 'value' in opts ? opts.value : null;
        let map = new (HashMap$(K, V))();
        Maps[_fillMapWithMappedIterable](map, iterable, key, value);
        return map;
      }
      fromIterables(keys, values) {
        let map = new (HashMap$(K, V))();
        Maps[_fillMapWithIterables](map, keys, values);
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
  let __CastType0$ = dart.generic(function(K) {
    let __CastType0 = dart.typedef('__CastType0', () => dart.functionType(core.int, [K]));
    return __CastType0;
  });
  let __CastType0 = __CastType0$();
  let __CastType2$ = dart.generic(function(K) {
    let __CastType2 = dart.typedef('__CastType2', () => dart.functionType(core.bool, [K, K]));
    return __CastType2;
  });
  let __CastType2 = __CastType2$();
  let _newSet = Symbol('_newSet');
  let SetMixin$ = dart.generic(function(E) {
    class SetMixin extends core.Object {
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
        let toRemove = [];
        for (let element of this) {
          if (test(element))
            toRemove[core.$add](element);
        }
        this.removeAll(toRemove);
      }
      retainWhere(test) {
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
        return new (_internal.EfficientLengthMappedIterable$(E, dart.dynamic))(this, f);
      }
      get [core.$single]() {
        if (dart.notNull(this[core.$length]) > 1)
          throw _internal.IterableElementError.tooMany();
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext()))
          throw _internal.IterableElementError.noElement();
        let result = dart.as(it.current, E);
        return result;
      }
      toString() {
        return IterableBase.iterableToFullString(this, '{', '}');
      }
      [core.$where](f) {
        return new (_internal.WhereIterable$(E))(this, f);
      }
      [core.$expand](f) {
        return new (_internal.ExpandIterable$(E, dart.dynamic))(this, f);
      }
      [core.$forEach](f) {
        for (let element of this)
          f(element);
      }
      [core.$reduce](combine) {
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
        let value = initialValue;
        for (let element of this)
          value = dart.dcall(combine, value, element);
        return value;
      }
      [core.$every](f) {
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
        return buffer.toString();
      }
      [core.$any](test) {
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
        return new (_internal.TakeWhileIterable$(E))(this, test);
      }
      [core.$skip](n) {
        return new (_internal.SkipIterable$(E))(this, n);
      }
      [core.$skipWhile](test) {
        return new (_internal.SkipWhileIterable$(E))(this, test);
      }
      get [core.$first]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        return dart.as(it.current, E);
      }
      get [core.$last]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let result = null;
        do {
          result = dart.as(it.current, E);
        } while (it.moveNext());
        return result;
      }
      [core.$firstWhere](test, opts) {
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        for (let element of this) {
          if (test(element))
            return element;
        }
        if (orElse != null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      [core.$lastWhere](test, opts) {
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
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
    return SetMixin;
  });
  let SetMixin = SetMixin$();
  let SetBase$ = dart.generic(function(E) {
    class SetBase extends SetMixin$(E) {
      static setToString(set) {
        return IterableBase.iterableToFullString(set, '{', '}');
      }
    }
    return SetBase;
  });
  let SetBase = SetBase$();
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
            hashCode = dart.as(_defaultHashCode, __CastType5);
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new (_IdentityHashSet$(E))();
            }
            if (equals == null) {
              equals = dart.as(_defaultEquals, __CastType7);
            }
          }
        } else {
          if (hashCode == null) {
            hashCode = dart.as(_defaultHashCode, dart.functionType(core.int, [E]));
          }
          if (equals == null) {
            equals = dart.as(_defaultEquals, dart.functionType(core.bool, [E, E]));
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
    }
    HashSet[dart.implements] = () => [core.Set$(E)];
    dart.defineNamedConstructor(HashSet, 'identity');
    dart.defineNamedConstructor(HashSet, 'from');
    return HashSet;
  });
  let HashSet = HashSet$();
  let __CastType5$ = dart.generic(function(E) {
    let __CastType5 = dart.typedef('__CastType5', () => dart.functionType(core.int, [E]));
    return __CastType5;
  });
  let __CastType5 = __CastType5$();
  let __CastType7$ = dart.generic(function(E) {
    let __CastType7 = dart.typedef('__CastType7', () => dart.functionType(core.bool, [E, E]));
    return __CastType7;
  });
  let __CastType7 = __CastType7$();
  let IterableMixin$ = dart.generic(function(E) {
    class IterableMixin extends core.Object {
      [core.$map](f) {
        return new (_internal.MappedIterable$(E, dart.dynamic))(this, f);
      }
      [core.$where](f) {
        return new (_internal.WhereIterable$(E))(this, f);
      }
      [core.$expand](f) {
        return new (_internal.ExpandIterable$(E, dart.dynamic))(this, f);
      }
      [core.$contains](element) {
        for (let e of this) {
          if (dart.equals(e, element))
            return true;
        }
        return false;
      }
      [core.$forEach](f) {
        for (let element of this)
          f(element);
      }
      [core.$reduce](combine) {
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
        let value = initialValue;
        for (let element of this)
          value = dart.dcall(combine, value, element);
        return value;
      }
      [core.$every](f) {
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
        return buffer.toString();
      }
      [core.$any](f) {
        for (let element of this) {
          if (f(element))
            return true;
        }
        return false;
      }
      [core.$toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        return new core.List$(E).from(this, {growable: growable});
      }
      [core.$toSet]() {
        return new core.Set$(E).from(this);
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
        return new (_internal.TakeWhileIterable$(E))(this, test);
      }
      [core.$skip](n) {
        return new (_internal.SkipIterable$(E))(this, n);
      }
      [core.$skipWhile](test) {
        return new (_internal.SkipWhileIterable$(E))(this, test);
      }
      get [core.$first]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        return dart.as(it.current, E);
      }
      get [core.$last]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let result = null;
        do {
          result = dart.as(it.current, E);
        } while (it.moveNext());
        return result;
      }
      get [core.$single]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext()))
          throw _internal.IterableElementError.noElement();
        let result = dart.as(it.current, E);
        if (it.moveNext())
          throw _internal.IterableElementError.tooMany();
        return result;
      }
      [core.$firstWhere](test, opts) {
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        for (let element of this) {
          if (test(element))
            return element;
        }
        if (orElse != null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      [core.$lastWhere](test, opts) {
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
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
    }
    IterableMixin[dart.implements] = () => [core.Iterable$(E)];
    return IterableMixin;
  });
  let IterableMixin = IterableMixin$();
  let _isToStringVisiting = Symbol('_isToStringVisiting');
  let _toStringVisiting = Symbol('_toStringVisiting');
  let _iterablePartsToStrings = Symbol('_iterablePartsToStrings');
  let IterableBase$ = dart.generic(function(E) {
    class IterableBase extends core.Object {
      IterableBase() {
      }
      [core.$map](f) {
        return new (_internal.MappedIterable$(E, dart.dynamic))(this, f);
      }
      [core.$where](f) {
        return new (_internal.WhereIterable$(E))(this, f);
      }
      [core.$expand](f) {
        return new (_internal.ExpandIterable$(E, dart.dynamic))(this, f);
      }
      [core.$contains](element) {
        for (let e of this) {
          if (dart.equals(e, element))
            return true;
        }
        return false;
      }
      [core.$forEach](f) {
        for (let element of this)
          f(element);
      }
      [core.$reduce](combine) {
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
        let value = initialValue;
        for (let element of this)
          value = dart.dcall(combine, value, element);
        return value;
      }
      [core.$every](f) {
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
        return buffer.toString();
      }
      [core.$any](f) {
        for (let element of this) {
          if (f(element))
            return true;
        }
        return false;
      }
      [core.$toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        return new core.List$(E).from(this, {growable: growable});
      }
      [core.$toSet]() {
        return new core.Set$(E).from(this);
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
        return new (_internal.TakeWhileIterable$(E))(this, test);
      }
      [core.$skip](n) {
        return new (_internal.SkipIterable$(E))(this, n);
      }
      [core.$skipWhile](test) {
        return new (_internal.SkipWhileIterable$(E))(this, test);
      }
      get [core.$first]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        return dart.as(it.current, E);
      }
      get [core.$last]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let result = null;
        do {
          result = dart.as(it.current, E);
        } while (it.moveNext());
        return result;
      }
      get [core.$single]() {
        let it = this[core.$iterator];
        if (!dart.notNull(it.moveNext()))
          throw _internal.IterableElementError.noElement();
        let result = dart.as(it.current, E);
        if (it.moveNext())
          throw _internal.IterableElementError.tooMany();
        return result;
      }
      [core.$firstWhere](test, opts) {
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        for (let element of this) {
          if (test(element))
            return element;
        }
        if (orElse != null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      [core.$lastWhere](test, opts) {
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
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
      static iterableToShortString(iterable, leftDelimiter, rightDelimiter) {
        if (leftDelimiter === void 0)
          leftDelimiter = '(';
        if (rightDelimiter === void 0)
          rightDelimiter = ')';
        if (IterableBase[_isToStringVisiting](iterable)) {
          if (leftDelimiter == "(" && rightDelimiter == ")") {
            return "(...)";
          }
          return `${leftDelimiter}...${rightDelimiter}`;
        }
        let parts = [];
        IterableBase[_toStringVisiting][core.$add](iterable);
        try {
          IterableBase[_iterablePartsToStrings](iterable, parts);
        } finally {
          dart.assert(core.identical(IterableBase[_toStringVisiting][core.$last], iterable));
          IterableBase[_toStringVisiting][core.$removeLast]();
        }
        return (() => {
          let _ = new core.StringBuffer(leftDelimiter);
          _.writeAll(parts, ", ");
          _.write(rightDelimiter);
          return _;
        })().toString();
      }
      static iterableToFullString(iterable, leftDelimiter, rightDelimiter) {
        if (leftDelimiter === void 0)
          leftDelimiter = '(';
        if (rightDelimiter === void 0)
          rightDelimiter = ')';
        if (IterableBase[_isToStringVisiting](iterable)) {
          return `${leftDelimiter}...${rightDelimiter}`;
        }
        let buffer = new core.StringBuffer(leftDelimiter);
        IterableBase[_toStringVisiting][core.$add](iterable);
        try {
          buffer.writeAll(iterable, ", ");
        } finally {
          dart.assert(core.identical(IterableBase[_toStringVisiting][core.$last], iterable));
          IterableBase[_toStringVisiting][core.$removeLast]();
        }
        buffer.write(rightDelimiter);
        return buffer.toString();
      }
      static [_isToStringVisiting](o) {
        for (let i = 0; dart.notNull(i) < dart.notNull(IterableBase[_toStringVisiting][core.$length]); i = dart.notNull(i) + 1) {
          if (core.identical(o, IterableBase[_toStringVisiting][core.$get](i)))
            return true;
        }
        return false;
      }
      static [_iterablePartsToStrings](iterable, parts) {
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
    }
    IterableBase[dart.implements] = () => [core.Iterable$(E)];
    dart.defineLazyProperties(IterableBase, {
      get _toStringVisiting() {
        return [];
      }
    });
    return IterableBase;
  });
  let IterableBase = IterableBase$();
  let _NOT_MOVED_YET = Symbol('_NOT_MOVED_YET');
  let _iterator = Symbol('_iterator');
  let _state = Symbol('_state');
  let _move = Symbol('_move');
  let _HAS_NEXT_AND_NEXT_IN_CURRENT = Symbol('_HAS_NEXT_AND_NEXT_IN_CURRENT');
  let _NO_NEXT = Symbol('_NO_NEXT');
  let HasNextIterator$ = dart.generic(function(E) {
    class HasNextIterator extends core.Object {
      HasNextIterator(iterator) {
        this[_iterator] = iterator;
        this[_state] = HasNextIterator[_NOT_MOVED_YET];
      }
      get hasNext() {
        if (this[_state] == HasNextIterator[_NOT_MOVED_YET])
          this[_move]();
        return this[_state] == HasNextIterator[_HAS_NEXT_AND_NEXT_IN_CURRENT];
      }
      next() {
        if (!dart.notNull(this.hasNext))
          throw new core.StateError("No more elements");
        dart.assert(this[_state] == HasNextIterator[_HAS_NEXT_AND_NEXT_IN_CURRENT]);
        let result = dart.as(this[_iterator].current, E);
        this[_move]();
        return result;
      }
      [_move]() {
        if (this[_iterator].moveNext()) {
          this[_state] = HasNextIterator[_HAS_NEXT_AND_NEXT_IN_CURRENT];
        } else {
          this[_state] = HasNextIterator[_NO_NEXT];
        }
      }
    }
    HasNextIterator._HAS_NEXT_AND_NEXT_IN_CURRENT = 0;
    HasNextIterator._NO_NEXT = 1;
    HasNextIterator._NOT_MOVED_YET = 2;
    return HasNextIterator;
  });
  let HasNextIterator = HasNextIterator$();
  let _literal = Symbol('_literal');
  let _empty = Symbol('_empty');
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
            hashCode = dart.as(_defaultHashCode, __CastType10);
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new (_LinkedIdentityHashMap$(K, V))();
            }
            if (equals == null) {
              equals = dart.as(_defaultEquals, __CastType12);
            }
          }
        } else {
          if (hashCode == null) {
            hashCode = dart.as(_defaultHashCode, dart.functionType(core.int, [K]));
          }
          if (equals == null) {
            equals = dart.as(_defaultEquals, dart.functionType(core.bool, [K, K]));
          }
        }
        return new (_LinkedCustomHashMap$(K, V))(equals, hashCode, isValidKey);
      }
      identity() {
        return new (_LinkedIdentityHashMap$(K, V))();
      }
      from(other) {
        let result = new (LinkedHashMap$(K, V))();
        other.forEach((k, v) => {
          result.set(k, dart.as(v, V));
        });
        return result;
      }
      fromIterable(iterable, opts) {
        let key = opts && 'key' in opts ? opts.key : null;
        let value = opts && 'value' in opts ? opts.value : null;
        let map = new (LinkedHashMap$(K, V))();
        Maps[_fillMapWithMappedIterable](map, iterable, key, value);
        return map;
      }
      fromIterables(keys, values) {
        let map = new (LinkedHashMap$(K, V))();
        Maps[_fillMapWithIterables](map, keys, values);
        return map;
      }
      [_literal](keyValuePairs) {
        return dart.as(_js_helper.fillLiteralMap(keyValuePairs, new (_LinkedHashMap$(K, V))()), LinkedHashMap$(K, V));
      }
      [_empty]() {
        return new (_LinkedHashMap$(K, V))();
      }
    }
    LinkedHashMap[dart.implements] = () => [HashMap$(K, V)];
    dart.defineNamedConstructor(LinkedHashMap, 'identity');
    dart.defineNamedConstructor(LinkedHashMap, 'from');
    dart.defineNamedConstructor(LinkedHashMap, 'fromIterable');
    dart.defineNamedConstructor(LinkedHashMap, 'fromIterables');
    dart.defineNamedConstructor(LinkedHashMap, _literal);
    dart.defineNamedConstructor(LinkedHashMap, _empty);
    return LinkedHashMap;
  });
  let LinkedHashMap = LinkedHashMap$();
  let __CastType10$ = dart.generic(function(K) {
    let __CastType10 = dart.typedef('__CastType10', () => dart.functionType(core.int, [K]));
    return __CastType10;
  });
  let __CastType10 = __CastType10$();
  let __CastType12$ = dart.generic(function(K) {
    let __CastType12 = dart.typedef('__CastType12', () => dart.functionType(core.bool, [K, K]));
    return __CastType12;
  });
  let __CastType12 = __CastType12$();
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
            hashCode = dart.as(_defaultHashCode, __CastType15);
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new (_LinkedIdentityHashSet$(E))();
            }
            if (equals == null) {
              equals = dart.as(_defaultEquals, __CastType17);
            }
          }
        } else {
          if (hashCode == null) {
            hashCode = dart.as(_defaultHashCode, dart.functionType(core.int, [E]));
          }
          if (equals == null) {
            equals = dart.as(_defaultEquals, dart.functionType(core.bool, [E, E]));
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
    }
    LinkedHashSet[dart.implements] = () => [HashSet$(E)];
    dart.defineNamedConstructor(LinkedHashSet, 'identity');
    dart.defineNamedConstructor(LinkedHashSet, 'from');
    return LinkedHashSet;
  });
  let LinkedHashSet = LinkedHashSet$();
  let __CastType15$ = dart.generic(function(E) {
    let __CastType15 = dart.typedef('__CastType15', () => dart.functionType(core.int, [E]));
    return __CastType15;
  });
  let __CastType15 = __CastType15$();
  let __CastType17$ = dart.generic(function(E) {
    let __CastType17 = dart.typedef('__CastType17', () => dart.functionType(core.bool, [E, E]));
    return __CastType17;
  });
  let __CastType17 = __CastType17$();
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
        this[_insertAfter](this, entry);
      }
      add(entry) {
        this[_insertAfter](this[_previous], entry);
      }
      addAll(entries) {
        entries[core.$forEach]((entry => this[_insertAfter](this[_previous], dart.as(entry, E))).bind(this));
      }
      remove(entry) {
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
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        entry[_next][_previous] = entry[_previous];
        entry[_previous][_next] = entry[_next];
        this[_length] = dart.notNull(this[_length]) - 1;
        entry[_list] = entry[_next] = entry[_previous] = null;
      }
    }
    LinkedList[dart.implements] = () => [_LinkedListLink];
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
        this[_list][_insertAfter](this, entry);
      }
      insertBefore(entry) {
        this[_list][_insertAfter](this[_previous], entry);
      }
    }
    LinkedListEntry[dart.implements] = () => [_LinkedListLink];
    return LinkedListEntry;
  });
  let LinkedListEntry = LinkedListEntry$();
  let _filter = Symbol('_filter');
  let ListMixin$ = dart.generic(function(E) {
    class ListMixin extends core.Object {
      get [core.$iterator]() {
        return new (_internal.ListIterator$(E))(this);
      }
      [core.$elementAt](index) {
        return this[core.$get](index);
      }
      [core.$forEach](action) {
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
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
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
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
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
        return buffer.toString();
      }
      [core.$where](test) {
        return new (_internal.WhereIterable$(E))(this, test);
      }
      [core.$map](f) {
        return new _internal.MappedListIterable(this, f);
      }
      [core.$expand](f) {
        return new (_internal.ExpandIterable$(E, dart.dynamic))(this, f);
      }
      [core.$reduce](combine) {
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
        return new (_internal.SkipWhileIterable$(E))(this, test);
      }
      [core.$take](count) {
        return new (_internal.SubListIterable$(E))(this, 0, count);
      }
      [core.$takeWhile](test) {
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
        this[core.$set]((() => {
          let o = this, x = o[core.$length];
          o[core.$length] = dart.notNull(x) + 1;
          return x;
        }).bind(this)(), element);
      }
      [core.$addAll](iterable) {
        for (let element of iterable) {
          this[core.$set]((() => {
            let o = this, x = o[core.$length];
            o[core.$length] = dart.notNull(x) + 1;
            return x;
          }).bind(this)(), element);
        }
      }
      [core.$remove](element) {
        for (let i = 0; dart.notNull(i) < dart.notNull(this[core.$length]); i = dart.notNull(i) + 1) {
          if (dart.equals(this[core.$get](i), element)) {
            this[core.$setRange](i, dart.notNull(this[core.$length]) - 1, this, dart.notNull(i) + 1);
            let o = this;
            o[core.$length] = dart.notNull(o[core.$length]) - 1;
            return true;
          }
        }
        return false;
      }
      [core.$removeWhere](test) {
        ListMixin[_filter](this, test, false);
      }
      [core.$retainWhere](test) {
        ListMixin[_filter](this, test, true);
      }
      static [_filter](source, test, retainMatching) {
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
        if (compare == null) {
          let defaultCompare = dart.bind(core.Comparable, 'compare');
          compare = defaultCompare;
        }
        _internal.Sort.sort(this, compare);
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
        let o = this;
        o[core.$length] = dart.notNull(o[core.$length]) - dart.notNull(length);
      }
      [core.$fillRange](start, end, fill) {
        if (fill === void 0)
          fill = null;
        core.RangeError.checkValidRange(start, end, this[core.$length]);
        for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
          this[core.$set](i, fill);
        }
      }
      [core.$setRange](start, end, iterable, skipCount) {
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
        core.RangeError.checkValueInInterval(index, 0, this[core.$length], "index");
        if (index == this[core.$length]) {
          this[core.$add](element);
          return;
        }
        if (!(typeof index == 'number'))
          throw new core.ArgumentError(index);
        let o = this;
        o[core.$length] = dart.notNull(o[core.$length]) + 1;
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
        core.RangeError.checkValueInInterval(index, 0, this[core.$length], "index");
        if (dart.is(iterable, _internal.EfficientLength)) {
          iterable = iterable[core.$toList]();
        }
        let insertionLength = iterable[core.$length];
        let o = this;
        o[core.$length] = dart.notNull(o[core.$length]) + dart.notNull(insertionLength);
        this[core.$setRange](dart.notNull(index) + dart.notNull(insertionLength), this[core.$length], this, index);
        this[core.$setAll](index, iterable);
      }
      [core.$setAll](index, iterable) {
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
      toString() {
        return IterableBase.iterableToFullString(this, '[', ']');
      }
    }
    ListMixin[dart.implements] = () => [core.List$(E)];
    return ListMixin;
  });
  let ListMixin = ListMixin$();
  let ListBase$ = dart.generic(function(E) {
    class ListBase extends dart.mixin(core.Object, ListMixin$(E)) {
      static listToString(list) {
        return IterableBase.iterableToFullString(list, '[', ']');
      }
    }
    return ListBase;
  });
  let ListBase = ListBase$();
  let MapMixin$ = dart.generic(function(K, V) {
    class MapMixin extends core.Object {
      forEach(action) {
        for (let key of this.keys) {
          action(key, this.get(key));
        }
      }
      addAll(other) {
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
    return MapMixin;
  });
  let MapMixin = MapMixin$();
  let MapBase$ = dart.generic(function(K, V) {
    class MapBase extends dart.mixin(MapMixin$(K, V)) {}
    return MapBase;
  });
  let MapBase = MapBase$();
  let _UnmodifiableMapMixin$ = dart.generic(function(K, V) {
    class _UnmodifiableMapMixin extends core.Object {
      set(key, value) {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      addAll(other) {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      clear() {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      remove(key) {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      putIfAbsent(key, ifAbsent) {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
    }
    _UnmodifiableMapMixin[dart.implements] = () => [core.Map$(K, V)];
    return _UnmodifiableMapMixin;
  });
  let _UnmodifiableMapMixin = _UnmodifiableMapMixin$();
  let UnmodifiableMapBase$ = dart.generic(function(K, V) {
    class UnmodifiableMapBase extends dart.mixin(_UnmodifiableMapMixin$(K, V)) {}
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
        this[_map].set(key, value);
      }
      addAll(other) {
        this[_map].addAll(other);
      }
      clear() {
        this[_map].clear();
      }
      putIfAbsent(key, ifAbsent) {
        return this[_map].putIfAbsent(key, ifAbsent);
      }
      containsKey(key) {
        return this[_map].containsKey(key);
      }
      containsValue(value) {
        return this[_map].containsValue(value);
      }
      forEach(action) {
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
        return this[_map].toString();
      }
      get values() {
        return this[_map].values;
      }
    }
    MapView[dart.implements] = () => [core.Map$(K, V)];
    return MapView;
  });
  let MapView = MapView$();
  let UnmodifiableMapView$ = dart.generic(function(K, V) {
    class UnmodifiableMapView extends dart.mixin(_UnmodifiableMapMixin$(K, V)) {}
    return UnmodifiableMapView;
  });
  let UnmodifiableMapView = UnmodifiableMapView$();
  let _id = Symbol('_id');
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
      return map.keys[core.$map](key => map.get(key));
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
      if (IterableBase[_isToStringVisiting](m)) {
        return '{...}';
      }
      let result = new core.StringBuffer();
      try {
        IterableBase[_toStringVisiting][core.$add](m);
        result.write('{');
        let first = true;
        m.forEach((k, v) => {
          if (!dart.notNull(first)) {
            result.write(', ');
          }
          first = false;
          result.write(k);
          result.write(': ');
          result.write(v);
        });
        result.write('}');
      } finally {
        dart.assert(core.identical(IterableBase[_toStringVisiting][core.$last], m));
        IterableBase[_toStringVisiting][core.$removeLast]();
      }
      return result.toString();
    }
    static [_id](x) {
      return x;
    }
    static [_fillMapWithMappedIterable](map, iterable, key, value) {
      if (key == null)
        key = Maps[_id];
      if (value == null)
        value = Maps[_id];
      for (let element of iterable) {
        map.set(dart.dcall(key, element), dart.dcall(value, element));
      }
    }
    static [_fillMapWithIterables](map, keys, values) {
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
  let Queue$ = dart.generic(function(E) {
    class Queue extends core.Object {
      Queue() {
        return new (ListQueue$(E))();
      }
      from(elements) {
        return new ListQueue$(E).from(elements);
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
        this[_next] = next;
        this[_previous] = previous;
        previous[_next] = this;
        next[_previous] = this;
      }
      append(e) {
        new (DoubleLinkedQueueEntry$(E))(e)[_link](this, this[_next]);
      }
      prepend(e) {
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
        this[_element] = e;
      }
    }
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
        dart.assert(false);
      }
      get element() {
        throw _internal.IterableElementError.noElement();
      }
    }
    return _DoubleLinkedQueueEntrySentinel;
  });
  let _DoubleLinkedQueueEntrySentinel = _DoubleLinkedQueueEntrySentinel$();
  let _sentinel = Symbol('_sentinel');
  let _elementCount = Symbol('_elementCount');
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
        this[_sentinel].prepend(value);
        this[_elementCount] = dart.notNull(this[_elementCount]) + 1;
      }
      addFirst(value) {
        this[_sentinel].append(value);
        this[_elementCount] = dart.notNull(this[_elementCount]) + 1;
      }
      add(value) {
        this[_sentinel].prepend(value);
        this[_elementCount] = dart.notNull(this[_elementCount]) + 1;
      }
      addAll(iterable) {
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
        this[_filter](test, true);
      }
      retainWhere(test) {
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
    return _DoubleLinkedQueueIterator;
  });
  let _DoubleLinkedQueueIterator = _DoubleLinkedQueueIterator$();
  let _head = Symbol('_head');
  let _tail = Symbol('_tail');
  let _table = Symbol('_table');
  let _INITIAL_CAPACITY = Symbol('_INITIAL_CAPACITY');
  let _isPowerOf2 = Symbol('_isPowerOf2');
  let _nextPowerOf2 = Symbol('_nextPowerOf2');
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
        if (initialCapacity == null || dart.notNull(initialCapacity) < dart.notNull(ListQueue[_INITIAL_CAPACITY])) {
          initialCapacity = ListQueue[_INITIAL_CAPACITY];
        } else if (!dart.notNull(ListQueue[_isPowerOf2](initialCapacity))) {
          initialCapacity = ListQueue[_nextPowerOf2](initialCapacity);
        }
        dart.assert(ListQueue[_isPowerOf2](initialCapacity));
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
          let capacity = ListQueue[_INITIAL_CAPACITY];
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
        this[_add](element);
      }
      addAll(elements) {
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
        this[_filterWhere](test, true);
      }
      retainWhere(test) {
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
        this[_add](element);
      }
      addFirst(element) {
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
      static [_isPowerOf2](number) {
        return (dart.notNull(number) & dart.notNull(number) - 1) == 0;
      }
      static [_nextPowerOf2](number) {
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
        let newCapacity = ListQueue[_nextPowerOf2](newElementCount);
        let newTable = new (core.List$(E))(newCapacity);
        this[_tail] = this[_writeToList](newTable);
        this[_table] = newTable;
        this[_head] = 0;
      }
    }
    ListQueue[dart.implements] = () => [Queue$(E)];
    dart.defineNamedConstructor(ListQueue, 'from');
    ListQueue._INITIAL_CAPACITY = 8;
    return ListQueue;
  });
  let ListQueue = ListQueue$();
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
    return _SplayTree;
  });
  let _SplayTree = _SplayTree$();
  let _TypeTest$ = dart.generic(function(T) {
    class _TypeTest extends core.Object {
      test(v) {
        return dart.is(v, T);
      }
    }
    return _TypeTest;
  });
  let _TypeTest = _TypeTest$();
  let _comparator = Symbol('_comparator');
  let _validKey = Symbol('_validKey');
  let _internal = Symbol('_internal');
  let SplayTreeMap$ = dart.generic(function(K, V) {
    class SplayTreeMap extends _SplayTree$(K) {
      SplayTreeMap(compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        this[_comparator] = dart.as(compare == null ? dart.bind(core.Comparable, 'compare') : compare, core.Comparator$(K));
        this[_validKey] = dart.as(isValidKey != null ? isValidKey : v => dart.is(v, K), _Predicate);
        super._SplayTree();
      }
      from(other, compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        let result = new (SplayTreeMap$(K, V))();
        other.forEach((k, v) => {
          result.set(k, dart.as(v, V));
        });
        return result;
      }
      fromIterable(iterable, opts) {
        let key = opts && 'key' in opts ? opts.key : null;
        let value = opts && 'value' in opts ? opts.value : null;
        let compare = opts && 'compare' in opts ? opts.compare : null;
        let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
        let map = new (SplayTreeMap$(K, V))(compare, isValidKey);
        Maps[_fillMapWithMappedIterable](map, iterable, key, value);
        return map;
      }
      fromIterables(keys, values, compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        let map = new (SplayTreeMap$(K, V))(compare, isValidKey);
        Maps[_fillMapWithIterables](map, keys, values);
        return map;
      }
      [_compare](key1, key2) {
        return this[_comparator](key1, key2);
      }
      [_internal]() {
        this[_comparator] = null;
        this[_validKey] = null;
        super._SplayTree();
      }
      get(key) {
        if (key == null)
          throw new core.ArgumentError(key);
        if (!dart.notNull(dart.dcall(this[_validKey], key)))
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
        if (!dart.notNull(dart.dcall(this[_validKey], key)))
          return null;
        let mapRoot = dart.as(this[_remove](dart.as(key, K)), _SplayTreeMapNode);
        if (mapRoot != null)
          return dart.as(mapRoot.value, V);
        return null;
      }
      set(key, value) {
        if (key == null)
          throw new core.ArgumentError(key);
        let comp = this[_splay](key);
        if (comp == 0) {
          let mapRoot = dart.as(this[_root], _SplayTreeMapNode);
          mapRoot.value = value;
          return;
        }
        this[_addNewRoot](new (_SplayTreeMapNode$(K, dart.dynamic))(key, value), comp);
      }
      putIfAbsent(key, ifAbsent) {
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
        this[_addNewRoot](new (_SplayTreeMapNode$(K, dart.dynamic))(key, value), comp);
        return value;
      }
      addAll(other) {
        other.forEach(((key, value) => {
          this.set(key, value);
        }).bind(this));
      }
      get isEmpty() {
        return this[_root] == null;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      forEach(f) {
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
        return dart.notNull(dart.dcall(this[_validKey], key)) && this[_splay](dart.as(key, K)) == 0;
      }
      containsValue(value) {
        let found = false;
        let initialSplayCount = this[_splayCount];
        // Function visit: (_SplayTreeMapNode<dynamic, dynamic>) → bool
        function visit(node) {
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
        }
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
    dart.defineNamedConstructor(SplayTreeMap, _internal);
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
        return this[_getValue](this[_currentNode]);
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
        let set = new (SplayTreeSet$(K))(dart.as(setOrMap[_comparator], __CastType20), dart.as(setOrMap[_validKey], __CastType23));
        set[_count] = this[_tree][_count];
        set[_root] = set[_copyNode](this[_tree][_root]);
        return set;
      }
    }
    _SplayTreeKeyIterable[dart.implements] = () => [_internal.EfficientLength];
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
        this[_comparator] = dart.as(compare == null ? dart.bind(core.Comparable, 'compare') : compare, core.Comparator);
        this[_validKey] = dart.as(isValidKey != null ? isValidKey : v => dart.is(v, E), _Predicate);
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
        return dart.dcall(this[_comparator], e1, e2);
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
        return dart.notNull(dart.dcall(this[_validKey], object)) && this[_splay](dart.as(object, E)) == 0;
      }
      add(element) {
        let compare = this[_splay](element);
        if (compare == 0)
          return false;
        this[_addNewRoot](new (_SplayTreeNode$(E))(element), compare);
        return true;
      }
      remove(object) {
        if (!dart.notNull(dart.dcall(this[_validKey], object)))
          return false;
        return this[_remove](dart.as(object, E)) != null;
      }
      addAll(elements) {
        for (let element of elements) {
          let compare = this[_splay](element);
          if (compare != 0) {
            this[_addNewRoot](new (_SplayTreeNode$(E))(element), compare);
          }
        }
      }
      removeAll(elements) {
        for (let element of elements) {
          if (dart.dcall(this[_validKey], element))
            this[_remove](dart.as(element, E));
        }
      }
      retainAll(elements) {
        let retainSet = new (SplayTreeSet$(E))(dart.as(this[_comparator], __CastType25), this[_validKey]);
        let modificationCount = this[_modificationCount];
        for (let object of elements) {
          if (modificationCount != this[_modificationCount]) {
            throw new core.ConcurrentModificationError(this);
          }
          if (dart.notNull(dart.dcall(this[_validKey], object)) && this[_splay](dart.as(object, E)) == 0)
            retainSet.add(this[_root].key);
        }
        if (retainSet[_count] != this[_count]) {
          this[_root] = retainSet[_root];
          this[_count] = retainSet[_count];
          this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        }
      }
      lookup(object) {
        if (!dart.notNull(dart.dcall(this[_validKey], object)))
          return null;
        let comp = this[_splay](dart.as(object, E));
        if (comp != 0)
          return null;
        return this[_root].key;
      }
      intersection(other) {
        let result = new (SplayTreeSet$(E))(dart.as(this[_comparator], dart.functionType(core.int, [E, E])), this[_validKey]);
        for (let element of this) {
          if (other[core.$contains](element))
            result.add(element);
        }
        return result;
      }
      difference(other) {
        let result = new (SplayTreeSet$(E))(dart.as(this[_comparator], dart.functionType(core.int, [E, E])), this[_validKey]);
        for (let element of this) {
          if (!dart.notNull(other[core.$contains](element)))
            result.add(element);
        }
        return result;
      }
      union(other) {
        let _ = this[_clone]();
        _.addAll(other);
        return _;
      }
      [_clone]() {
        let set = new (SplayTreeSet$(E))(dart.as(this[_comparator], dart.functionType(core.int, [E, E])), this[_validKey]);
        set[_count] = this[_count];
        set[_root] = this[_copyNode](this[_root]);
        return set;
      }
      [_copyNode](node) {
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
    return SplayTreeSet;
  });
  let SplayTreeSet = SplayTreeSet$();
  let __CastType20$ = dart.generic(function(K) {
    let __CastType20 = dart.typedef('__CastType20', () => dart.functionType(core.int, [K, K]));
    return __CastType20;
  });
  let __CastType20 = __CastType20$();
  let __CastType23 = dart.typedef('__CastType23', () => dart.functionType(core.bool, [dart.dynamic]));
  let __CastType25$ = dart.generic(function(E) {
    let __CastType25 = dart.typedef('__CastType25', () => dart.functionType(core.int, [E, E]));
    return __CastType25;
  });
  let __CastType25 = __CastType25$();
  let _strings = Symbol('_strings');
  let _nums = Symbol('_nums');
  let _rest = Symbol('_rest');
  let _isStringKey = Symbol('_isStringKey');
  let _hasTableEntry = Symbol('_hasTableEntry');
  let _isNumericKey = Symbol('_isNumericKey');
  let _containsKey = Symbol('_containsKey');
  let _getBucket = Symbol('_getBucket');
  let _findBucketIndex = Symbol('_findBucketIndex');
  let _computeKeys = Symbol('_computeKeys');
  let _getTableEntry = Symbol('_getTableEntry');
  let _get = Symbol('_get');
  let _newHashTable = Symbol('_newHashTable');
  let _addHashTableEntry = Symbol('_addHashTableEntry');
  let _set = Symbol('_set');
  let _computeHashCode = Symbol('_computeHashCode');
  let _setTableEntry = Symbol('_setTableEntry');
  let _removeHashTableEntry = Symbol('_removeHashTableEntry');
  let _deleteTableEntry = Symbol('_deleteTableEntry');
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
        return new (_internal.MappedIterable$(K, V))(this.keys, (each => this.get(each)).bind(this));
      }
      containsKey(key) {
        if (_HashMap[_isStringKey](key)) {
          let strings = this[_strings];
          return strings == null ? false : _HashMap[_hasTableEntry](strings, key);
        } else if (_HashMap[_isNumericKey](key)) {
          let nums = this[_nums];
          return nums == null ? false : _HashMap[_hasTableEntry](nums, key);
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
        return this[_computeKeys]()[core.$any]((each => dart.equals(this.get(each), value)).bind(this));
      }
      addAll(other) {
        other.forEach(((key, value) => {
          this.set(key, value);
        }).bind(this));
      }
      get(key) {
        if (_HashMap[_isStringKey](key)) {
          let strings = this[_strings];
          return dart.as(strings == null ? null : _HashMap[_getTableEntry](strings, key), V);
        } else if (_HashMap[_isNumericKey](key)) {
          let nums = this[_nums];
          return dart.as(nums == null ? null : _HashMap[_getTableEntry](nums, key), V);
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
        return dart.as(dart.notNull(index) < 0 ? null : bucket[dart.notNull(index) + 1], V);
      }
      set(key, value) {
        if (_HashMap[_isStringKey](key)) {
          let strings = this[_strings];
          if (strings == null)
            this[_strings] = strings = _HashMap[_newHashTable]();
          this[_addHashTableEntry](strings, key, value);
        } else if (_HashMap[_isNumericKey](key)) {
          let nums = this[_nums];
          if (nums == null)
            this[_nums] = nums = _HashMap[_newHashTable]();
          this[_addHashTableEntry](nums, key, value);
        } else {
          this[_set](key, value);
        }
      }
      [_set](key, value) {
        let rest = this[_rest];
        if (rest == null)
          this[_rest] = rest = _HashMap[_newHashTable]();
        let hash = this[_computeHashCode](key);
        let bucket = rest[hash];
        if (bucket == null) {
          _HashMap[_setTableEntry](rest, hash, [key, value]);
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
        if (this.containsKey(key))
          return this.get(key);
        let value = ifAbsent();
        this.set(key, value);
        return value;
      }
      remove(key) {
        if (_HashMap[_isStringKey](key)) {
          return this[_removeHashTableEntry](this[_strings], key);
        } else if (_HashMap[_isNumericKey](key)) {
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
        if (!dart.notNull(_HashMap[_hasTableEntry](table, key))) {
          this[_length] = dart.notNull(this[_length]) + 1;
          this[_keys] = null;
        }
        _HashMap[_setTableEntry](table, key, value);
      }
      [_removeHashTableEntry](table, key) {
        if (dart.notNull(table != null) && dart.notNull(_HashMap[_hasTableEntry](table, key))) {
          let value = dart.as(_HashMap[_getTableEntry](table, key), V);
          _HashMap[_deleteTableEntry](table, key);
          this[_length] = dart.notNull(this[_length]) - 1;
          this[_keys] = null;
          return value;
        } else {
          return null;
        }
      }
      static [_isStringKey](key) {
        return typeof key == 'string' && dart.notNull(!dart.equals(key, '__proto__'));
      }
      static [_isNumericKey](key) {
        return dart.is(key, core.num) && (key & 0x3ffffff) === key;
      }
      [_computeHashCode](key) {
        return key.hashCode & 0x3ffffff;
      }
      static [_hasTableEntry](table, key) {
        let entry = table[key];
        return entry != null;
      }
      static [_getTableEntry](table, key) {
        let entry = table[key];
        return entry === table ? null : entry;
      }
      static [_setTableEntry](table, key, value) {
        if (value == null) {
          table[key] = table;
        } else {
          table[key] = value;
        }
      }
      static [_deleteTableEntry](table, key) {
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
      static [_newHashTable]() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _HashMap[_setTableEntry](table, temporaryKey, table);
        _HashMap[_deleteTableEntry](table, temporaryKey);
        return table;
      }
    }
    _HashMap[dart.implements] = () => [HashMap$(K, V)];
    return _HashMap;
  });
  let _HashMap = _HashMap$();
  let _IdentityHashMap$ = dart.generic(function(K, V) {
    class _IdentityHashMap extends _HashMap$(K, V) {
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
        this[_validKey] = dart.as(validKey != null ? validKey : v => dart.is(v, K), _Predicate);
        super._HashMap();
      }
      get(key) {
        if (!dart.notNull(dart.dcall(this[_validKey], key)))
          return null;
        return super[_get](key);
      }
      set(key, value) {
        super[_set](key, value);
      }
      containsKey(key) {
        if (!dart.notNull(dart.dcall(this[_validKey], key)))
          return false;
        return super[_containsKey](key);
      }
      remove(key) {
        if (!dart.notNull(dart.dcall(this[_validKey], key)))
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
        return new (_internal.MappedIterable$(K, V))(this.keys, (each => this.get(each)).bind(this));
      }
      containsKey(key) {
        if (_LinkedHashMap[_isStringKey](key)) {
          let strings = this[_strings];
          if (strings == null)
            return false;
          let cell = dart.as(_LinkedHashMap[_getTableEntry](strings, key), LinkedHashMapCell);
          return cell != null;
        } else if (_LinkedHashMap[_isNumericKey](key)) {
          let nums = this[_nums];
          if (nums == null)
            return false;
          let cell = dart.as(_LinkedHashMap[_getTableEntry](nums, key), LinkedHashMapCell);
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
        return this.keys[core.$any]((each => dart.equals(this.get(each), value)).bind(this));
      }
      addAll(other) {
        other.forEach(((key, value) => {
          this.set(key, value);
        }).bind(this));
      }
      get(key) {
        if (_LinkedHashMap[_isStringKey](key)) {
          let strings = this[_strings];
          if (strings == null)
            return null;
          let cell = dart.as(_LinkedHashMap[_getTableEntry](strings, key), LinkedHashMapCell);
          return dart.as(cell == null ? null : cell[_value], V);
        } else if (_LinkedHashMap[_isNumericKey](key)) {
          let nums = this[_nums];
          if (nums == null)
            return null;
          let cell = dart.as(_LinkedHashMap[_getTableEntry](nums, key), LinkedHashMapCell);
          return dart.as(cell == null ? null : cell[_value], V);
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
        if (_LinkedHashMap[_isStringKey](key)) {
          let strings = this[_strings];
          if (strings == null)
            this[_strings] = strings = _LinkedHashMap[_newHashTable]();
          this[_addHashTableEntry](strings, key, value);
        } else if (_LinkedHashMap[_isNumericKey](key)) {
          let nums = this[_nums];
          if (nums == null)
            this[_nums] = nums = _LinkedHashMap[_newHashTable]();
          this[_addHashTableEntry](nums, key, value);
        } else {
          this[_set](key, value);
        }
      }
      [_set](key, value) {
        let rest = this[_rest];
        if (rest == null)
          this[_rest] = rest = _LinkedHashMap[_newHashTable]();
        let hash = this[_computeHashCode](key);
        let bucket = rest[hash];
        if (bucket == null) {
          let cell = this[_newLinkedCell](key, value);
          _LinkedHashMap[_setTableEntry](rest, hash, [cell]);
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
        if (this.containsKey(key))
          return this.get(key);
        let value = ifAbsent();
        this.set(key, value);
        return value;
      }
      remove(key) {
        if (_LinkedHashMap[_isStringKey](key)) {
          return this[_removeHashTableEntry](this[_strings], key);
        } else if (_LinkedHashMap[_isNumericKey](key)) {
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
        let cell = dart.as(_LinkedHashMap[_getTableEntry](table, key), LinkedHashMapCell);
        if (cell == null) {
          _LinkedHashMap[_setTableEntry](table, key, this[_newLinkedCell](key, value));
        } else {
          cell[_value] = value;
        }
      }
      [_removeHashTableEntry](table, key) {
        if (table == null)
          return null;
        let cell = dart.as(_LinkedHashMap[_getTableEntry](table, key), LinkedHashMapCell);
        if (cell == null)
          return null;
        this[_unlinkCell](cell);
        _LinkedHashMap[_deleteTableEntry](table, key);
        return dart.as(cell[_value], V);
      }
      [_modified]() {
        this[_modifications] = dart.notNull(this[_modifications]) + 1 & 67108863;
      }
      [_newLinkedCell](key, value) {
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
      static [_isStringKey](key) {
        return typeof key == 'string' && dart.notNull(!dart.equals(key, '__proto__'));
      }
      static [_isNumericKey](key) {
        return dart.is(key, core.num) && (key & 0x3ffffff) === key;
      }
      [_computeHashCode](key) {
        return key.hashCode & 0x3ffffff;
      }
      static [_getTableEntry](table, key) {
        return table[key];
      }
      static [_setTableEntry](table, key, value) {
        dart.assert(value != null);
        table[key] = value;
      }
      static [_deleteTableEntry](table, key) {
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
      static [_newHashTable]() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _LinkedHashMap[_setTableEntry](table, temporaryKey, table);
        _LinkedHashMap[_deleteTableEntry](table, temporaryKey);
        return table;
      }
      toString() {
        return Maps.mapToString(this);
      }
    }
    _LinkedHashMap[dart.implements] = () => [LinkedHashMap$(K, V), _js_helper.InternalMap];
    return _LinkedHashMap;
  });
  let _LinkedHashMap = _LinkedHashMap$();
  let _LinkedIdentityHashMap$ = dart.generic(function(K, V) {
    class _LinkedIdentityHashMap extends _LinkedHashMap$(K, V) {
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
        this[_validKey] = dart.as(validKey != null ? validKey : v => dart.is(v, K), _Predicate);
        super._LinkedHashMap();
      }
      get(key) {
        if (!dart.notNull(dart.dcall(this[_validKey], key)))
          return null;
        return super[_get](key);
      }
      set(key, value) {
        super[_set](key, value);
      }
      containsKey(key) {
        if (!dart.notNull(dart.dcall(this[_validKey], key)))
          return false;
        return super[_containsKey](key);
      }
      remove(key) {
        if (!dart.notNull(dart.dcall(this[_validKey], key)))
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
    return LinkedHashMapKeyIterator;
  });
  let LinkedHashMapKeyIterator = LinkedHashMapKeyIterator$();
  let _elements = Symbol('_elements');
  let _computeElements = Symbol('_computeElements');
  let _isStringElement = Symbol('_isStringElement');
  let _isNumericElement = Symbol('_isNumericElement');
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
        if (_HashSet[_isStringElement](object)) {
          let strings = this[_strings];
          return strings == null ? false : _HashSet[_hasTableEntry](strings, object);
        } else if (_HashSet[_isNumericElement](object)) {
          let nums = this[_nums];
          return nums == null ? false : _HashSet[_hasTableEntry](nums, object);
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
        if (dart.notNull(_HashSet[_isStringElement](object)) || dart.notNull(_HashSet[_isNumericElement](object))) {
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
        if (_HashSet[_isStringElement](element)) {
          let strings = this[_strings];
          if (strings == null)
            this[_strings] = strings = _HashSet[_newHashTable]();
          return this[_addHashTableEntry](strings, element);
        } else if (_HashSet[_isNumericElement](element)) {
          let nums = this[_nums];
          if (nums == null)
            this[_nums] = nums = _HashSet[_newHashTable]();
          return this[_addHashTableEntry](nums, element);
        } else {
          return this[_add](element);
        }
      }
      [_add](element) {
        let rest = this[_rest];
        if (rest == null)
          this[_rest] = rest = _HashSet[_newHashTable]();
        let hash = this[_computeHashCode](element);
        let bucket = rest[hash];
        if (bucket == null) {
          _HashSet[_setTableEntry](rest, hash, [element]);
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
        for (let each of objects) {
          this.add(each);
        }
      }
      remove(object) {
        if (_HashSet[_isStringElement](object)) {
          return this[_removeHashTableEntry](this[_strings], object);
        } else if (_HashSet[_isNumericElement](object)) {
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
        if (_HashSet[_hasTableEntry](table, element))
          return false;
        _HashSet[_setTableEntry](table, element, 0);
        this[_length] = dart.notNull(this[_length]) + 1;
        this[_elements] = null;
        return true;
      }
      [_removeHashTableEntry](table, element) {
        if (dart.notNull(table != null) && dart.notNull(_HashSet[_hasTableEntry](table, element))) {
          _HashSet[_deleteTableEntry](table, element);
          this[_length] = dart.notNull(this[_length]) - 1;
          this[_elements] = null;
          return true;
        } else {
          return false;
        }
      }
      static [_isStringElement](element) {
        return typeof element == 'string' && dart.notNull(!dart.equals(element, '__proto__'));
      }
      static [_isNumericElement](element) {
        return dart.is(element, core.num) && (element & 0x3ffffff) === element;
      }
      [_computeHashCode](element) {
        return element.hashCode & 0x3ffffff;
      }
      static [_hasTableEntry](table, key) {
        let entry = table[key];
        return entry != null;
      }
      static [_setTableEntry](table, key, value) {
        dart.assert(value != null);
        table[key] = value;
      }
      static [_deleteTableEntry](table, key) {
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
      static [_newHashTable]() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _HashSet[_setTableEntry](table, temporaryKey, table);
        _HashSet[_deleteTableEntry](table, temporaryKey);
        return table;
      }
    }
    _HashSet[dart.implements] = () => [HashSet$(E)];
    return _HashSet;
  });
  let _HashSet = _HashSet$();
  let _IdentityHashSet$ = dart.generic(function(E) {
    class _IdentityHashSet extends _HashSet$(E) {
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
        this[_validKey] = dart.as(validKey != null ? validKey : x => dart.is(x, E), _Predicate);
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
        return super[_add](object);
      }
      [core.$contains](object) {
        if (!dart.notNull(dart.dcall(this[_validKey], object)))
          return false;
        return super[_contains](object);
      }
      lookup(object) {
        if (!dart.notNull(dart.dcall(this[_validKey], object)))
          return null;
        return super[_lookup](object);
      }
      remove(object) {
        if (!dart.notNull(dart.dcall(this[_validKey], object)))
          return false;
        return super[_remove](object);
      }
    }
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
        if (_LinkedHashSet[_isStringElement](object)) {
          let strings = this[_strings];
          if (strings == null)
            return false;
          let cell = dart.as(_LinkedHashSet[_getTableEntry](strings, object), LinkedHashSetCell);
          return cell != null;
        } else if (_LinkedHashSet[_isNumericElement](object)) {
          let nums = this[_nums];
          if (nums == null)
            return false;
          let cell = dart.as(_LinkedHashSet[_getTableEntry](nums, object), LinkedHashSetCell);
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
        if (dart.notNull(_LinkedHashSet[_isStringElement](object)) || dart.notNull(_LinkedHashSet[_isNumericElement](object))) {
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
        if (_LinkedHashSet[_isStringElement](element)) {
          let strings = this[_strings];
          if (strings == null)
            this[_strings] = strings = _LinkedHashSet[_newHashTable]();
          return this[_addHashTableEntry](strings, element);
        } else if (_LinkedHashSet[_isNumericElement](element)) {
          let nums = this[_nums];
          if (nums == null)
            this[_nums] = nums = _LinkedHashSet[_newHashTable]();
          return this[_addHashTableEntry](nums, element);
        } else {
          return this[_add](element);
        }
      }
      [_add](element) {
        let rest = this[_rest];
        if (rest == null)
          this[_rest] = rest = _LinkedHashSet[_newHashTable]();
        let hash = this[_computeHashCode](element);
        let bucket = rest[hash];
        if (bucket == null) {
          let cell = this[_newLinkedCell](element);
          _LinkedHashSet[_setTableEntry](rest, hash, [cell]);
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
        if (_LinkedHashSet[_isStringElement](object)) {
          return this[_removeHashTableEntry](this[_strings], object);
        } else if (_LinkedHashSet[_isNumericElement](object)) {
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
        this[_filterWhere](test, true);
      }
      retainWhere(test) {
        this[_filterWhere](test, false);
      }
      [_filterWhere](test, removeMatching) {
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
        let cell = dart.as(_LinkedHashSet[_getTableEntry](table, element), LinkedHashSetCell);
        if (cell != null)
          return false;
        _LinkedHashSet[_setTableEntry](table, element, this[_newLinkedCell](element));
        return true;
      }
      [_removeHashTableEntry](table, element) {
        if (table == null)
          return false;
        let cell = dart.as(_LinkedHashSet[_getTableEntry](table, element), LinkedHashSetCell);
        if (cell == null)
          return false;
        this[_unlinkCell](cell);
        _LinkedHashSet[_deleteTableEntry](table, element);
        return true;
      }
      [_modified]() {
        this[_modifications] = dart.notNull(this[_modifications]) + 1 & 67108863;
      }
      [_newLinkedCell](element) {
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
      static [_isStringElement](element) {
        return typeof element == 'string' && dart.notNull(!dart.equals(element, '__proto__'));
      }
      static [_isNumericElement](element) {
        return dart.is(element, core.num) && (element & 0x3ffffff) === element;
      }
      [_computeHashCode](element) {
        return element.hashCode & 0x3ffffff;
      }
      static [_getTableEntry](table, key) {
        return table[key];
      }
      static [_setTableEntry](table, key, value) {
        dart.assert(value != null);
        table[key] = value;
      }
      static [_deleteTableEntry](table, key) {
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
      static [_newHashTable]() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _LinkedHashSet[_setTableEntry](table, temporaryKey, table);
        _LinkedHashSet[_deleteTableEntry](table, temporaryKey);
        return table;
      }
    }
    _LinkedHashSet[dart.implements] = () => [LinkedHashSet$(E)];
    return _LinkedHashSet;
  });
  let _LinkedHashSet = _LinkedHashSet$();
  let _LinkedIdentityHashSet$ = dart.generic(function(E) {
    class _LinkedIdentityHashSet extends _LinkedHashSet$(E) {
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
    return _LinkedIdentityHashSet;
  });
  let _LinkedIdentityHashSet = _LinkedIdentityHashSet$();
  let _LinkedCustomHashSet$ = dart.generic(function(E) {
    class _LinkedCustomHashSet extends _LinkedHashSet$(E) {
      _LinkedCustomHashSet(equality, hasher, validKey) {
        this[_equality] = equality;
        this[_hasher] = hasher;
        this[_validKey] = dart.as(validKey != null ? validKey : x => dart.is(x, E), _Predicate);
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
        return super[_add](element);
      }
      [core.$contains](object) {
        if (!dart.notNull(dart.dcall(this[_validKey], object)))
          return false;
        return super[_contains](object);
      }
      lookup(object) {
        if (!dart.notNull(dart.dcall(this[_validKey], object)))
          return null;
        return super[_lookup](object);
      }
      remove(object) {
        if (!dart.notNull(dart.dcall(this[_validKey], object)))
          return false;
        return super[_remove](object);
      }
      containsAll(elements) {
        for (let element of elements) {
          if (!dart.notNull(dart.dcall(this[_validKey], element)) || !dart.notNull(this[core.$contains](element)))
            return false;
        }
        return true;
      }
      removeAll(elements) {
        for (let element of elements) {
          if (dart.dcall(this[_validKey], element)) {
            super[_remove](element);
          }
        }
      }
    }
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
    return LinkedHashSetIterator;
  });
  let LinkedHashSetIterator = LinkedHashSetIterator$();
  // Exports:
  exports.UnmodifiableListView$ = UnmodifiableListView$;
  exports.HashMap$ = HashMap$;
  exports.HashMap = HashMap;
  exports.SetBase$ = SetBase$;
  exports.SetBase = SetBase;
  exports.SetMixin$ = SetMixin$;
  exports.SetMixin = SetMixin;
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
  exports.ListBase$ = ListBase$;
  exports.ListBase = ListBase;
  exports.ListMixin$ = ListMixin$;
  exports.ListMixin = ListMixin;
  exports.MapBase$ = MapBase$;
  exports.MapBase = MapBase;
  exports.MapMixin$ = MapMixin$;
  exports.MapMixin = MapMixin;
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
})(collection || (collection = {}));
