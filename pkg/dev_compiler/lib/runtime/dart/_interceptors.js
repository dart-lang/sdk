var _interceptors = dart.defineLibrary(_interceptors, {});
var core = dart.import(core);
var _internal = dart.import(_internal);
var _js_helper = dart.lazyImport(_js_helper);
var collection = dart.import(collection);
var math = dart.import(math);
(function(exports, core, _internal, _js_helper, collection, math) {
  'use strict';
  let JSArray$ = dart.generic(function(E) {
    class JSArray extends core.Object {
      JSArray() {
      }
      static typed(allocation) {
        return dart.list(allocation, E);
      }
      static markFixed(allocation) {
        return JSArray$(E).typed(JSArray$().markFixedList(dart.as(allocation, core.List)));
      }
      static markGrowable(allocation) {
        return JSArray$().typed(allocation);
      }
      static markFixedList(list) {
        list.fixed$length = Array;
        return list;
      }
      checkGrowable(reason) {
        if (this.fixed$length) {
          throw new core.UnsupportedError(dart.as(reason, core.String));
        }
      }
      add(value) {
        dart.as(value, E);
        this[dartx.checkGrowable]('add');
        this.push(value);
      }
      removeAt(index) {
        if (!(typeof index == 'number'))
          throw new core.ArgumentError(index);
        if (dart.notNull(index) < 0 || dart.notNull(index) >= dart.notNull(this.length)) {
          throw new core.RangeError.value(index);
        }
        this[dartx.checkGrowable]('removeAt');
        return this.splice(index, 1)[0];
      }
      insert(index, value) {
        dart.as(value, E);
        if (!(typeof index == 'number'))
          throw new core.ArgumentError(index);
        if (dart.notNull(index) < 0 || dart.notNull(index) > dart.notNull(this.length)) {
          throw new core.RangeError.value(index);
        }
        this[dartx.checkGrowable]('insert');
        this.splice(index, 0, value);
      }
      insertAll(index, iterable) {
        dart.as(iterable, core.Iterable$(E));
        this[dartx.checkGrowable]('insertAll');
        _internal.IterableMixinWorkaround.insertAllList(this, index, iterable);
      }
      setAll(index, iterable) {
        dart.as(iterable, core.Iterable$(E));
        _internal.IterableMixinWorkaround.setAllList(this, index, iterable);
      }
      removeLast() {
        this[dartx.checkGrowable]('removeLast');
        if (this.length == 0)
          throw new core.RangeError.value(-1);
        return dart.as(this.pop(), E);
      }
      remove(element) {
        this[dartx.checkGrowable]('remove');
        for (let i = 0; dart.notNull(i) < dart.notNull(this.length); i = dart.notNull(i) + 1) {
          if (dart.equals(this[dartx.get](i), element)) {
            this.splice(i, 1);
            return true;
          }
        }
        return false;
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        _internal.IterableMixinWorkaround.removeWhereList(this, test);
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        _internal.IterableMixinWorkaround.removeWhereList(this, dart.fn(element => !dart.notNull(test(element)), core.bool, [E]));
      }
      where(f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        return new (_internal.IterableMixinWorkaround$(E))().where(this, f);
      }
      expand(f) {
        dart.as(f, dart.functionType(core.Iterable, [E]));
        return _internal.IterableMixinWorkaround.expand(this, f);
      }
      addAll(collection) {
        dart.as(collection, core.Iterable$(E));
        for (let e of collection) {
          this[dartx.add](e);
        }
      }
      clear() {
        this.length = 0;
      }
      forEach(f) {
        dart.as(f, dart.functionType(dart.void, [E]));
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          f(dart.as(this[i], E));
          if (length != this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
      }
      map(f) {
        dart.as(f, dart.functionType(core.Object, [E]));
        return _internal.IterableMixinWorkaround.mapList(this, f);
      }
      join(separator) {
        if (separator === void 0)
          separator = "";
        let list = core.List.new(this.length);
        for (let i = 0; dart.notNull(i) < dart.notNull(this.length); i = dart.notNull(i) + 1) {
          list[dartx.set](i, `${this[dartx.get](i)}`);
        }
        return list.join(separator);
      }
      take(n) {
        return new (_internal.IterableMixinWorkaround$(E))().takeList(this, n);
      }
      takeWhile(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.IterableMixinWorkaround$(E))().takeWhile(this, test);
      }
      skip(n) {
        return new (_internal.IterableMixinWorkaround$(E))().skipList(this, n);
      }
      skipWhile(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.IterableMixinWorkaround$(E))().skipWhile(this, test);
      }
      reduce(combine) {
        dart.as(combine, dart.functionType(E, [E, E]));
        return dart.as(_internal.IterableMixinWorkaround.reduce(this, combine), E);
      }
      fold(initialValue, combine) {
        dart.as(combine, dart.functionType(core.Object, [dart.bottom, E]));
        return _internal.IterableMixinWorkaround.fold(this, initialValue, combine);
      }
      firstWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        return dart.as(_internal.IterableMixinWorkaround.firstWhere(this, test, orElse), E);
      }
      lastWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        return dart.as(_internal.IterableMixinWorkaround.lastWhereList(this, test, orElse), E);
      }
      singleWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return dart.as(_internal.IterableMixinWorkaround.singleWhere(this, test), E);
      }
      elementAt(index) {
        return this[dartx.get](index);
      }
      sublist(start, end) {
        if (end === void 0)
          end = null;
        _js_helper.checkNull(start);
        if (!(typeof start == 'number'))
          throw new core.ArgumentError(start);
        if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(this.length)) {
          throw new core.RangeError.range(start, 0, this.length);
        }
        if (end == null) {
          end = this.length;
        } else {
          if (!(typeof end == 'number'))
            throw new core.ArgumentError(end);
          if (dart.notNull(end) < dart.notNull(start) || dart.notNull(end) > dart.notNull(this.length)) {
            throw new core.RangeError.range(end, start, this.length);
          }
        }
        if (start == end)
          return dart.list([], E);
        return JSArray$(E).typed(this.slice(start, end));
      }
      getRange(start, end) {
        return new (_internal.IterableMixinWorkaround$(E))().getRangeList(this, start, end);
      }
      get first() {
        if (dart.notNull(this.length) > 0)
          return this[dartx.get](0);
        throw new core.StateError("No elements");
      }
      get last() {
        if (dart.notNull(this.length) > 0)
          return this[dartx.get](dart.notNull(this.length) - 1);
        throw new core.StateError("No elements");
      }
      get single() {
        if (this.length == 1)
          return this[dartx.get](0);
        if (this.length == 0)
          throw new core.StateError("No elements");
        throw new core.StateError("More than one element");
      }
      removeRange(start, end) {
        this[dartx.checkGrowable]('removeRange');
        let receiverLength = this.length;
        if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(receiverLength)) {
          throw new core.RangeError.range(start, 0, receiverLength);
        }
        if (dart.notNull(end) < dart.notNull(start) || dart.notNull(end) > dart.notNull(receiverLength)) {
          throw new core.RangeError.range(end, start, receiverLength);
        }
        _internal.Lists.copy(this, end, this, start, dart.notNull(receiverLength) - dart.notNull(end));
        this.length = dart.notNull(receiverLength) - (dart.notNull(end) - dart.notNull(start));
      }
      setRange(start, end, iterable, skipCount) {
        dart.as(iterable, core.Iterable$(E));
        if (skipCount === void 0)
          skipCount = 0;
        _internal.IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
      }
      fillRange(start, end, fillValue) {
        if (fillValue === void 0)
          fillValue = null;
        dart.as(fillValue, E);
        _internal.IterableMixinWorkaround.fillRangeList(this, start, end, fillValue);
      }
      replaceRange(start, end, iterable) {
        dart.as(iterable, core.Iterable$(E));
        _internal.IterableMixinWorkaround.replaceRangeList(this, start, end, iterable);
      }
      any(f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        return _internal.IterableMixinWorkaround.any(this, f);
      }
      every(f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        return _internal.IterableMixinWorkaround.every(this, f);
      }
      get reversed() {
        return new (_internal.IterableMixinWorkaround$(E))().reversedList(this);
      }
      sort(compare) {
        if (compare === void 0)
          compare = null;
        dart.as(compare, dart.functionType(core.int, [E, E]));
        _internal.IterableMixinWorkaround.sortList(this, compare);
      }
      shuffle(random) {
        if (random === void 0)
          random = null;
        _internal.IterableMixinWorkaround.shuffleList(this, random);
      }
      indexOf(element, start) {
        if (start === void 0)
          start = 0;
        return _internal.IterableMixinWorkaround.indexOfList(this, element, start);
      }
      lastIndexOf(element, start) {
        if (start === void 0)
          start = null;
        return _internal.IterableMixinWorkaround.lastIndexOfList(this, element, start);
      }
      contains(other) {
        for (let i = 0; dart.notNull(i) < dart.notNull(this.length); i = dart.notNull(i) + 1) {
          if (dart.equals(this[dartx.get](i), other))
            return true;
        }
        return false;
      }
      get isEmpty() {
        return this.length == 0;
      }
      get isNotEmpty() {
        return !dart.notNull(this[dartx.isEmpty]);
      }
      toString() {
        return collection.ListBase.listToString(this);
      }
      toList(opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        let list = this.slice();
        if (!dart.notNull(growable))
          JSArray$().markFixedList(dart.as(list, core.List));
        return JSArray$(E).typed(list);
      }
      toSet() {
        return core.Set$(E).from(this);
      }
      get iterator() {
        return new (_internal.ListIterator$(E))(this);
      }
      get hashCode() {
        return _js_helper.Primitives.objectHashCode(this);
      }
      get length() {
        return dart.as(this.length, core.int);
      }
      set length(newLength) {
        if (!(typeof newLength == 'number'))
          throw new core.ArgumentError(newLength);
        if (dart.notNull(newLength) < 0)
          throw new core.RangeError.value(newLength);
        this[dartx.checkGrowable]('set length');
        this.length = newLength;
      }
      get(index) {
        if (!(typeof index == 'number'))
          throw new core.ArgumentError(index);
        if (dart.notNull(index) >= dart.notNull(this.length) || dart.notNull(index) < 0)
          throw new core.RangeError.value(index);
        return dart.as(this[index], E);
      }
      set(index, value) {
        dart.as(value, E);
        if (!(typeof index == 'number'))
          throw new core.ArgumentError(index);
        if (dart.notNull(index) >= dart.notNull(this.length) || dart.notNull(index) < 0)
          throw new core.RangeError.value(index);
        this[index] = value;
      }
      asMap() {
        return new (_internal.IterableMixinWorkaround$(E))().asMapList(this);
      }
    }
    dart.setBaseClass(JSArray, dart.global.Array);
    JSArray[dart.implements] = () => [core.List$(E), JSIndexable];
    dart.setSignature(JSArray, {
      constructors: () => ({
        JSArray: [JSArray$(E), []],
        typed: [JSArray$(E), [core.Object]],
        markFixed: [JSArray$(E), [core.Object]],
        markGrowable: [JSArray$(E), [core.Object]]
      }),
      methods: () => ({
        checkGrowable: [core.Object, [core.Object]],
        add: [dart.void, [E]],
        removeAt: [E, [core.int]],
        insert: [dart.void, [core.int, E]],
        insertAll: [dart.void, [core.int, core.Iterable$(E)]],
        setAll: [dart.void, [core.int, core.Iterable$(E)]],
        removeLast: [E, []],
        remove: [core.bool, [core.Object]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        where: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        expand: [core.Iterable, [dart.functionType(core.Iterable, [E])]],
        addAll: [dart.void, [core.Iterable$(E)]],
        clear: [dart.void, []],
        forEach: [dart.void, [dart.functionType(dart.void, [E])]],
        map: [core.Iterable, [dart.functionType(core.Object, [E])]],
        join: [core.String, [], [core.String]],
        take: [core.Iterable$(E), [core.int]],
        takeWhile: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        skip: [core.Iterable$(E), [core.int]],
        skipWhile: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        reduce: [E, [dart.functionType(E, [E, E])]],
        fold: [core.Object, [core.Object, dart.functionType(core.Object, [dart.bottom, E])]],
        firstWhere: [E, [dart.functionType(core.bool, [E])], {orElse: dart.functionType(E, [])}],
        lastWhere: [E, [dart.functionType(core.bool, [E])], {orElse: dart.functionType(E, [])}],
        singleWhere: [E, [dart.functionType(core.bool, [E])]],
        elementAt: [E, [core.int]],
        sublist: [core.List$(E), [core.int], [core.int]],
        getRange: [core.Iterable$(E), [core.int, core.int]],
        removeRange: [dart.void, [core.int, core.int]],
        setRange: [dart.void, [core.int, core.int, core.Iterable$(E)], [core.int]],
        fillRange: [dart.void, [core.int, core.int], [E]],
        replaceRange: [dart.void, [core.int, core.int, core.Iterable$(E)]],
        any: [core.bool, [dart.functionType(core.bool, [E])]],
        every: [core.bool, [dart.functionType(core.bool, [E])]],
        sort: [dart.void, [], [dart.functionType(core.int, [E, E])]],
        shuffle: [dart.void, [], [math.Random]],
        indexOf: [core.int, [core.Object], [core.int]],
        lastIndexOf: [core.int, [core.Object], [core.int]],
        contains: [core.bool, [core.Object]],
        toList: [core.List$(E), [], {growable: core.bool}],
        toSet: [core.Set$(E), []],
        get: [E, [core.int]],
        set: [dart.void, [core.int, E]],
        asMap: [core.Map$(core.int, E), []]
      }),
      statics: () => ({markFixedList: [core.List, [core.List]]}),
      names: ['markFixedList']
    });
    return JSArray;
  });
  let JSArray = JSArray$();
  dart.registerExtension(dart.global.Array, JSArray);
  let JSMutableArray$ = dart.generic(function(E) {
    class JSMutableArray extends JSArray$(E) {
      JSMutableArray() {
        super.JSArray();
      }
    }
    JSMutableArray[dart.implements] = () => [JSMutableIndexable];
    return JSMutableArray;
  });
  let JSMutableArray = JSMutableArray$();
  let JSFixedArray$ = dart.generic(function(E) {
    class JSFixedArray extends JSMutableArray$(E) {}
    return JSFixedArray;
  });
  let JSFixedArray = JSFixedArray$();
  let JSExtendableArray$ = dart.generic(function(E) {
    class JSExtendableArray extends JSMutableArray$(E) {}
    return JSExtendableArray;
  });
  let JSExtendableArray = JSExtendableArray$();
  class Interceptor extends core.Object {
    Interceptor() {
    }
  }
  dart.setSignature(Interceptor, {
    constructors: () => ({Interceptor: [Interceptor, []]})
  });
  let _isInt32 = Symbol('_isInt32');
  let _tdivFast = Symbol('_tdivFast');
  let _tdivSlow = Symbol('_tdivSlow');
  let _shlPositive = Symbol('_shlPositive');
  let _shrReceiverPositive = Symbol('_shrReceiverPositive');
  let _shrOtherPositive = Symbol('_shrOtherPositive');
  let _shrBothPositive = Symbol('_shrBothPositive');
  class JSNumber extends Interceptor {
    JSNumber() {
      super.Interceptor();
    }
    compareTo(b) {
      if (!dart.is(b, core.num))
        throw new core.ArgumentError(b);
      if (dart.notNull(this[dartx['<']](b))) {
        return -1;
      } else if (dart.notNull(this[dartx['>']](b))) {
        return 1;
      } else if (dart.equals(this, b)) {
        if (dart.equals(this, 0)) {
          let bIsNegative = b[dartx.isNegative];
          if (this[dartx.isNegative] == bIsNegative)
            return 0;
          if (dart.notNull(this[dartx.isNegative]))
            return -1;
          return 1;
        }
        return 0;
      } else if (dart.notNull(this[dartx.isNaN])) {
        if (dart.notNull(b[dartx.isNaN])) {
          return 0;
        }
        return 1;
      } else {
        return -1;
      }
    }
    get isNegative() {
      return dart.equals(this, 0) ? (1)[dartx['/']](this) < 0 : this[dartx['<']](0);
    }
    get isNaN() {
      return isNaN(this);
    }
    get isInfinite() {
      return this == Infinity || this == -Infinity;
    }
    get isFinite() {
      return isFinite(this);
    }
    remainder(b) {
      _js_helper.checkNull(b);
      if (!dart.is(b, core.num))
        throw new core.ArgumentError(b);
      return this % b;
    }
    abs() {
      return Math.abs(this);
    }
    get sign() {
      return dart.notNull(this[dartx['>']](0)) ? 1 : dart.notNull(this[dartx['<']](0)) ? -1 : this;
    }
    toInt() {
      if (dart.notNull(this[dartx['>=']](JSNumber._MIN_INT32)) && dart.notNull(this[dartx['<=']](JSNumber._MAX_INT32))) {
        return this | 0;
      }
      if (isFinite(this)) {
        return this[dartx.truncateToDouble]() + 0;
      }
      throw new core.UnsupportedError('' + this);
    }
    truncate() {
      return this[dartx.toInt]();
    }
    ceil() {
      return this[dartx.ceilToDouble]()[dartx.toInt]();
    }
    floor() {
      return this[dartx.floorToDouble]()[dartx.toInt]();
    }
    round() {
      return this[dartx.roundToDouble]()[dartx.toInt]();
    }
    ceilToDouble() {
      return Math.ceil(this);
    }
    floorToDouble() {
      return Math.floor(this);
    }
    roundToDouble() {
      if (dart.notNull(this[dartx['<']](0))) {
        return -Math.round(-this);
      } else {
        return Math.round(this);
      }
    }
    truncateToDouble() {
      return dart.notNull(this[dartx['<']](0)) ? this[dartx.ceilToDouble]() : this[dartx.floorToDouble]();
    }
    clamp(lowerLimit, upperLimit) {
      if (!dart.is(lowerLimit, core.num))
        throw new core.ArgumentError(lowerLimit);
      if (!dart.is(upperLimit, core.num))
        throw new core.ArgumentError(upperLimit);
      if (dart.notNull(lowerLimit[dartx.compareTo](upperLimit)) > 0) {
        throw new core.ArgumentError(lowerLimit);
      }
      if (dart.notNull(this[dartx.compareTo](lowerLimit)) < 0)
        return lowerLimit;
      if (dart.notNull(this[dartx.compareTo](upperLimit)) > 0)
        return upperLimit;
      return this;
    }
    toDouble() {
      return this;
    }
    toStringAsFixed(fractionDigits) {
      _js_helper.checkInt(fractionDigits);
      if (dart.notNull(fractionDigits) < 0 || dart.notNull(fractionDigits) > 20) {
        throw new core.RangeError(fractionDigits);
      }
      let result = this.toFixed(fractionDigits);
      if (dart.equals(this, 0) && dart.notNull(this[dartx.isNegative]))
        return `-${result}`;
      return result;
    }
    toStringAsExponential(fractionDigits) {
      if (fractionDigits === void 0)
        fractionDigits = null;
      let result = null;
      if (fractionDigits != null) {
        _js_helper.checkInt(fractionDigits);
        if (dart.notNull(fractionDigits) < 0 || dart.notNull(fractionDigits) > 20) {
          throw new core.RangeError(fractionDigits);
        }
        result = this.toExponential(fractionDigits);
      } else {
        result = this.toExponential();
      }
      if (dart.equals(this, 0) && dart.notNull(this[dartx.isNegative]))
        return `-${result}`;
      return result;
    }
    toStringAsPrecision(precision) {
      _js_helper.checkInt(precision);
      if (dart.notNull(precision) < 1 || dart.notNull(precision) > 21) {
        throw new core.RangeError(precision);
      }
      let result = this.toPrecision(precision);
      if (dart.equals(this, 0) && dart.notNull(this[dartx.isNegative]))
        return `-${result}`;
      return result;
    }
    toRadixString(radix) {
      _js_helper.checkInt(radix);
      if (dart.notNull(radix) < 2 || dart.notNull(radix) > 36)
        throw new core.RangeError(radix);
      let result = this.toString(radix);
      let rightParenCode = 41;
      if (result[dartx.codeUnitAt](dart.notNull(result.length) - 1) != rightParenCode) {
        return result;
      }
      return JSNumber._handleIEtoString(result);
    }
    static _handleIEtoString(result) {
      let match = /^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(result);
      if (match == null) {
        throw new core.UnsupportedError(`Unexpected toString result: ${result}`);
      }
      result = dart.dindex(match, 1);
      let exponent = +dart.dindex(match, 3);
      if (dart.dindex(match, 2) != null) {
        result = result + dart.dindex(match, 2);
        exponent = dart.notNull(exponent) - dart.dindex(match, 2).length;
      }
      return dart.notNull(result) + "0"[dartx['*']](exponent);
    }
    toString() {
      if (dart.equals(this, 0) && 1 / this < 0) {
        return '-0.0';
      } else {
        return "" + this;
      }
    }
    get hashCode() {
      return this & 0x1FFFFFFF;
    }
    ['unary-']() {
      return -this;
    }
    ['+'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return this + other;
    }
    ['-'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return this - other;
    }
    ['/'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return this / other;
    }
    ['*'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return this * other;
    }
    ['%'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      let result = this % other;
      if (result == 0)
        return 0;
      if (dart.notNull(result) > 0)
        return result;
      if (other < 0) {
        return dart.notNull(result) - other;
      } else {
        return dart.notNull(result) + other;
      }
    }
    [_isInt32](value) {
      return (value | 0) === value;
    }
    ['~/'](other) {
      if (false)
        this[_tdivFast](other);
      if (dart.notNull(this[_isInt32](this)) && dart.notNull(this[_isInt32](other)) && 0 != other && -1 != other) {
        return this / other | 0;
      } else {
        return this[_tdivSlow](other);
      }
    }
    [_tdivFast](other) {
      return dart.notNull(this[_isInt32](this)) ? this / other | 0 : (this / other)[dartx.toInt]();
    }
    [_tdivSlow](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return (this / other)[dartx.toInt]();
    }
    ['<<'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      if (other < 0)
        throw new core.ArgumentError(other);
      return this[_shlPositive](other);
    }
    [_shlPositive](other) {
      return other > 31 ? 0 : dart.as(this << other >>> 0, core.num);
    }
    ['>>'](other) {
      if (false)
        this[_shrReceiverPositive](other);
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      if (other < 0)
        throw new core.ArgumentError(other);
      return this[_shrOtherPositive](other);
    }
    [_shrOtherPositive](other) {
      return this > 0 ? this[_shrBothPositive](other) : dart.as(this >> (dart.notNull(other) > 31 ? 31 : other) >>> 0, core.num);
    }
    [_shrReceiverPositive](other) {
      if (other < 0)
        throw new core.ArgumentError(other);
      return this[_shrBothPositive](other);
    }
    [_shrBothPositive](other) {
      return other > 31 ? 0 : dart.as(this >>> other, core.num);
    }
    ['&'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as((this & other) >>> 0, core.num);
    }
    ['|'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as((this | other) >>> 0, core.num);
    }
    ['^'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as((this ^ other) >>> 0, core.num);
    }
    ['<'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return this < other;
    }
    ['>'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return this > other;
    }
    ['<='](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return this <= other;
    }
    ['>='](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return this >= other;
    }
    get runtimeType() {
      return core.num;
    }
  }
  JSNumber[dart.implements] = () => [core.num];
  dart.setSignature(JSNumber, {
    constructors: () => ({JSNumber: [JSNumber, []]}),
    methods: () => ({
      compareTo: [core.int, [core.num]],
      remainder: [core.num, [core.num]],
      abs: [core.num, []],
      toInt: [core.int, []],
      truncate: [core.int, []],
      ceil: [core.int, []],
      floor: [core.int, []],
      round: [core.int, []],
      ceilToDouble: [core.double, []],
      floorToDouble: [core.double, []],
      roundToDouble: [core.double, []],
      truncateToDouble: [core.double, []],
      clamp: [core.num, [core.num, core.num]],
      toDouble: [core.double, []],
      toStringAsFixed: [core.String, [core.int]],
      toStringAsExponential: [core.String, [], [core.int]],
      toStringAsPrecision: [core.String, [core.int]],
      toRadixString: [core.String, [core.int]],
      'unary-': [core.num, []],
      '+': [core.num, [core.num]],
      '-': [core.num, [core.num]],
      '/': [core.double, [core.num]],
      '*': [core.num, [core.num]],
      '%': [core.num, [core.num]],
      [_isInt32]: [core.bool, [core.Object]],
      '~/': [core.int, [core.num]],
      [_tdivFast]: [core.int, [core.num]],
      [_tdivSlow]: [core.int, [core.num]],
      '<<': [core.num, [core.num]],
      [_shlPositive]: [core.num, [core.num]],
      '>>': [core.num, [core.num]],
      [_shrOtherPositive]: [core.num, [core.num]],
      [_shrReceiverPositive]: [core.num, [core.num]],
      [_shrBothPositive]: [core.num, [core.num]],
      '&': [core.num, [core.num]],
      '|': [core.num, [core.num]],
      '^': [core.num, [core.num]],
      '<': [core.bool, [core.num]],
      '>': [core.bool, [core.num]],
      '<=': [core.bool, [core.num]],
      '>=': [core.bool, [core.num]]
    }),
    statics: () => ({_handleIEtoString: [core.String, [core.String]]}),
    names: ['_handleIEtoString']
  });
  JSNumber._MIN_INT32 = -2147483648;
  JSNumber._MAX_INT32 = 2147483647;
  class JSInt extends JSNumber {
    JSInt() {
      super.JSNumber();
    }
    get isEven() {
      return this[dartx['&']](1) == 0;
    }
    get isOdd() {
      return this[dartx['&']](1) == 1;
    }
    toUnsigned(width) {
      return this[dartx['&']]((1 << dart.notNull(width)) - 1);
    }
    toSigned(width) {
      let signMask = 1 << dart.notNull(width) - 1;
      return dart.notNull(this[dartx['&']](dart.notNull(signMask) - 1)) - dart.notNull(this[dartx['&']](signMask));
    }
    get bitLength() {
      let nonneg = dart.notNull(this[dartx['<']](0)) ? dart.notNull(this[dartx['unary-']]()) - 1 : this;
      if (dart.notNull(nonneg) >= 4294967296) {
        nonneg = (dart.notNull(nonneg) / 4294967296).truncate();
        return dart.notNull(JSInt._bitCount(JSInt._spread(nonneg))) + 32;
      }
      return JSInt._bitCount(JSInt._spread(nonneg));
    }
    static _bitCount(i) {
      i = dart.notNull(JSInt._shru(i, 0)) - (dart.notNull(JSInt._shru(i, 1)) & 1431655765);
      i = (dart.notNull(i) & 858993459) + (dart.notNull(JSInt._shru(i, 2)) & 858993459);
      i = 252645135 & dart.notNull(i) + dart.notNull(JSInt._shru(i, 4));
      i = dart.notNull(i) + dart.notNull(JSInt._shru(i, 8));
      i = dart.notNull(i) + dart.notNull(JSInt._shru(i, 16));
      return dart.notNull(i) & 63;
    }
    static _shru(value, shift) {
      return value >>> shift;
    }
    static _shrs(value, shift) {
      return value >> shift;
    }
    static _ors(a, b) {
      return a | b;
    }
    static _spread(i) {
      i = JSInt._ors(i, JSInt._shrs(i, 1));
      i = JSInt._ors(i, JSInt._shrs(i, 2));
      i = JSInt._ors(i, JSInt._shrs(i, 4));
      i = JSInt._ors(i, JSInt._shrs(i, 8));
      i = JSInt._shru(JSInt._ors(i, JSInt._shrs(i, 16)), 0);
      return i;
    }
    get runtimeType() {
      return core.int;
    }
    ['~']() {
      return dart.as(~this >>> 0, core.int);
    }
  }
  JSInt[dart.implements] = () => [core.int, core.double];
  dart.setSignature(JSInt, {
    constructors: () => ({JSInt: [JSInt, []]}),
    methods: () => ({
      toUnsigned: [core.int, [core.int]],
      toSigned: [core.int, [core.int]],
      '~': [core.int, []]
    }),
    statics: () => ({
      _bitCount: [core.int, [core.int]],
      _shru: [core.int, [core.int, core.int]],
      _shrs: [core.int, [core.int, core.int]],
      _ors: [core.int, [core.int, core.int]],
      _spread: [core.int, [core.int]]
    }),
    names: ['_bitCount', '_shru', '_shrs', '_ors', '_spread']
  });
  dart.registerExtension(dart.global.Number, JSInt);
  class JSDouble extends JSNumber {
    JSDouble() {
      super.JSNumber();
    }
    get runtimeType() {
      return core.double;
    }
  }
  JSDouble[dart.implements] = () => [core.double];
  dart.setSignature(JSDouble, {
    constructors: () => ({JSDouble: [JSDouble, []]})
  });
  class JSPositiveInt extends JSInt {
    JSPositiveInt() {
      super.JSInt();
    }
  }
  class JSUInt32 extends JSPositiveInt {}
  class JSUInt31 extends JSUInt32 {}
  let _defaultSplit = Symbol('_defaultSplit');
  class JSString extends Interceptor {
    JSString() {
      super.Interceptor();
    }
    codeUnitAt(index) {
      if (!(typeof index == 'number'))
        throw new core.ArgumentError(index);
      if (dart.notNull(index) < 0)
        throw new core.RangeError.value(index);
      if (dart.notNull(index) >= dart.notNull(this.length))
        throw new core.RangeError.value(index);
      return dart.as(this.charCodeAt(index), core.int);
    }
    allMatches(string, start) {
      if (start === void 0)
        start = 0;
      _js_helper.checkString(string);
      _js_helper.checkInt(start);
      if (0 > dart.notNull(start) || dart.notNull(start) > dart.notNull(string.length)) {
        throw new core.RangeError.range(start, 0, string.length);
      }
      return _js_helper.allMatchesInStringUnchecked(this, string, start);
    }
    matchAsPrefix(string, start) {
      if (start === void 0)
        start = 0;
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(string.length)) {
        throw new core.RangeError.range(start, 0, string.length);
      }
      if (dart.notNull(start) + dart.notNull(this.length) > dart.notNull(string.length))
        return null;
      for (let i = 0; dart.notNull(i) < dart.notNull(this.length); i = dart.notNull(i) + 1) {
        if (string[dartx.codeUnitAt](dart.notNull(start) + dart.notNull(i)) != this[dartx.codeUnitAt](i)) {
          return null;
        }
      }
      return new _js_helper.StringMatch(start, string, this);
    }
    ['+'](other) {
      if (!(typeof other == 'string'))
        throw new core.ArgumentError(other);
      return this + other;
    }
    endsWith(other) {
      _js_helper.checkString(other);
      let otherLength = other.length;
      if (dart.notNull(otherLength) > dart.notNull(this.length))
        return false;
      return other == this[dartx.substring](dart.notNull(this.length) - dart.notNull(otherLength));
    }
    replaceAll(from, to) {
      _js_helper.checkString(to);
      return dart.as(_js_helper.stringReplaceAllUnchecked(this, from, to), core.String);
    }
    replaceAllMapped(from, convert) {
      return this[dartx.splitMapJoin](from, {onMatch: convert});
    }
    splitMapJoin(from, opts) {
      let onMatch = opts && 'onMatch' in opts ? opts.onMatch : null;
      let onNonMatch = opts && 'onNonMatch' in opts ? opts.onNonMatch : null;
      return dart.as(_js_helper.stringReplaceAllFuncUnchecked(this, from, onMatch, onNonMatch), core.String);
    }
    replaceFirst(from, to, startIndex) {
      if (startIndex === void 0)
        startIndex = 0;
      _js_helper.checkString(to);
      _js_helper.checkInt(startIndex);
      if (dart.notNull(startIndex) < 0 || dart.notNull(startIndex) > dart.notNull(this.length)) {
        throw new core.RangeError.range(startIndex, 0, this.length);
      }
      return dart.as(_js_helper.stringReplaceFirstUnchecked(this, from, to, startIndex), core.String);
    }
    split(pattern) {
      _js_helper.checkNull(pattern);
      if (typeof pattern == 'string') {
        return dart.as(this.split(pattern), core.List$(core.String));
      } else if (dart.is(pattern, _js_helper.JSSyntaxRegExp) && _js_helper.regExpCaptureCount(pattern) == 0) {
        let re = _js_helper.regExpGetNative(pattern);
        return dart.as(this.split(re), core.List$(core.String));
      } else {
        return this[_defaultSplit](pattern);
      }
    }
    [_defaultSplit](pattern) {
      let result = dart.list([], core.String);
      let start = 0;
      let length = 1;
      for (let match of pattern[dartx.allMatches](this)) {
        let matchStart = match.start;
        let matchEnd = match.end;
        length = dart.notNull(matchEnd) - dart.notNull(matchStart);
        if (length == 0 && start == matchStart) {
          continue;
        }
        let end = matchStart;
        result[dartx.add](this[dartx.substring](start, end));
        start = matchEnd;
      }
      if (dart.notNull(start) < dart.notNull(this.length) || dart.notNull(length) > 0) {
        result[dartx.add](this[dartx.substring](start));
      }
      return result;
    }
    startsWith(pattern, index) {
      if (index === void 0)
        index = 0;
      _js_helper.checkInt(index);
      if (dart.notNull(index) < 0 || dart.notNull(index) > dart.notNull(this.length)) {
        throw new core.RangeError.range(index, 0, this.length);
      }
      if (typeof pattern == 'string') {
        let other = pattern;
        let otherLength = other.length;
        let endIndex = dart.notNull(index) + dart.notNull(otherLength);
        if (dart.notNull(endIndex) > dart.notNull(this.length))
          return false;
        return other == this.substring(index, endIndex);
      }
      return pattern[dartx.matchAsPrefix](this, index) != null;
    }
    substring(startIndex, endIndex) {
      if (endIndex === void 0)
        endIndex = null;
      _js_helper.checkInt(startIndex);
      if (endIndex == null)
        endIndex = this.length;
      _js_helper.checkInt(endIndex);
      if (dart.notNull(startIndex) < 0)
        throw new core.RangeError.value(startIndex);
      if (dart.notNull(startIndex) > dart.notNull(endIndex))
        throw new core.RangeError.value(startIndex);
      if (dart.notNull(endIndex) > dart.notNull(this.length))
        throw new core.RangeError.value(endIndex);
      return this.substring(startIndex, endIndex);
    }
    toLowerCase() {
      return this.toLowerCase();
    }
    toUpperCase() {
      return this.toUpperCase();
    }
    static _isWhitespace(codeUnit) {
      if (dart.notNull(codeUnit) < 256) {
        switch (codeUnit) {
          case 9:
          case 10:
          case 11:
          case 12:
          case 13:
          case 32:
          case 133:
          case 160:
          {
            return true;
          }
          default:
          {
            return false;
          }
        }
      }
      switch (codeUnit) {
        case 5760:
        case 6158:
        case 8192:
        case 8193:
        case 8194:
        case 8195:
        case 8196:
        case 8197:
        case 8198:
        case 8199:
        case 8200:
        case 8201:
        case 8202:
        case 8232:
        case 8233:
        case 8239:
        case 8287:
        case 12288:
        case 65279:
        {
          return true;
        }
        default:
        {
          return false;
        }
      }
    }
    static _skipLeadingWhitespace(string, index) {
      let SPACE = 32;
      let CARRIAGE_RETURN = 13;
      while (dart.notNull(index) < dart.notNull(string.length)) {
        let codeUnit = string[dartx.codeUnitAt](index);
        if (codeUnit != SPACE && codeUnit != CARRIAGE_RETURN && !dart.notNull(JSString._isWhitespace(codeUnit))) {
          break;
        }
        index = dart.notNull(index) + 1;
      }
      return index;
    }
    static _skipTrailingWhitespace(string, index) {
      let SPACE = 32;
      let CARRIAGE_RETURN = 13;
      while (dart.notNull(index) > 0) {
        let codeUnit = string[dartx.codeUnitAt](dart.notNull(index) - 1);
        if (codeUnit != SPACE && codeUnit != CARRIAGE_RETURN && !dart.notNull(JSString._isWhitespace(codeUnit))) {
          break;
        }
        index = dart.notNull(index) - 1;
      }
      return index;
    }
    trim() {
      let NEL = 133;
      let result = this.trim();
      if (result.length == 0)
        return result;
      let firstCode = result[dartx.codeUnitAt](0);
      let startIndex = 0;
      if (firstCode == NEL) {
        startIndex = JSString._skipLeadingWhitespace(result, 1);
        if (startIndex == result.length)
          return "";
      }
      let endIndex = result.length;
      let lastCode = result[dartx.codeUnitAt](dart.notNull(endIndex) - 1);
      if (lastCode == NEL) {
        endIndex = JSString._skipTrailingWhitespace(result, dart.notNull(endIndex) - 1);
      }
      if (startIndex == 0 && endIndex == result.length)
        return result;
      return result.substring(startIndex, endIndex);
    }
    trimLeft() {
      let NEL = 133;
      let result = null;
      let startIndex = 0;
      if (typeof this.trimLeft != "undefined") {
        result = this.trimLeft();
        if (result.length == 0)
          return result;
        let firstCode = result[dartx.codeUnitAt](0);
        if (firstCode == NEL) {
          startIndex = JSString._skipLeadingWhitespace(result, 1);
        }
      } else {
        result = this;
        startIndex = JSString._skipLeadingWhitespace(this, 0);
      }
      if (startIndex == 0)
        return result;
      if (startIndex == result.length)
        return "";
      return result.substring(startIndex);
    }
    trimRight() {
      let NEL = 133;
      let result = null;
      let endIndex = null;
      if (typeof this.trimRight != "undefined") {
        result = this.trimRight();
        endIndex = result.length;
        if (endIndex == 0)
          return result;
        let lastCode = result[dartx.codeUnitAt](dart.notNull(endIndex) - 1);
        if (lastCode == NEL) {
          endIndex = JSString._skipTrailingWhitespace(result, dart.notNull(endIndex) - 1);
        }
      } else {
        result = this;
        endIndex = JSString._skipTrailingWhitespace(this, this.length);
      }
      if (endIndex == result.length)
        return result;
      if (endIndex == 0)
        return "";
      return result.substring(0, endIndex);
    }
    ['*'](times) {
      if (0 >= dart.notNull(times))
        return '';
      if (times == 1 || this.length == 0)
        return this;
      if (!dart.equals(times, times >>> 0)) {
        throw dart.const(new core.OutOfMemoryError());
      }
      let result = '';
      let s = this;
      while (true) {
        if ((dart.notNull(times) & 1) == 1)
          result = s[dartx['+']](result);
        times = dart.as(times >>> 1, core.int);
        if (times == 0)
          break;
        s = s[dartx['+']](s);
      }
      return result;
    }
    padLeft(width, padding) {
      if (padding === void 0)
        padding = ' ';
      let delta = dart.notNull(width) - dart.notNull(this.length);
      if (dart.notNull(delta) <= 0)
        return this;
      return padding[dartx['*']](delta) + this;
    }
    padRight(width, padding) {
      if (padding === void 0)
        padding = ' ';
      let delta = dart.notNull(width) - dart.notNull(this.length);
      if (dart.notNull(delta) <= 0)
        return this;
      return this[dartx['+']](padding[dartx['*']](delta));
    }
    get codeUnits() {
      return new _CodeUnits(this);
    }
    get runes() {
      return new core.Runes(this);
    }
    indexOf(pattern, start) {
      if (start === void 0)
        start = 0;
      _js_helper.checkNull(pattern);
      if (!(typeof start == 'number'))
        throw new core.ArgumentError(start);
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(this.length)) {
        throw new core.RangeError.range(start, 0, this.length);
      }
      if (typeof pattern == 'string') {
        return this.indexOf(pattern, start);
      }
      if (dart.is(pattern, _js_helper.JSSyntaxRegExp)) {
        let re = pattern;
        let match = _js_helper.firstMatchAfter(re, this, start);
        return match == null ? -1 : match.start;
      }
      for (let i = start; dart.notNull(i) <= dart.notNull(this.length); i = dart.notNull(i) + 1) {
        if (pattern[dartx.matchAsPrefix](this, i) != null)
          return i;
      }
      return -1;
    }
    lastIndexOf(pattern, start) {
      if (start === void 0)
        start = null;
      _js_helper.checkNull(pattern);
      if (start == null) {
        start = this.length;
      } else if (!(typeof start == 'number')) {
        throw new core.ArgumentError(start);
      } else if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(this.length)) {
        throw new core.RangeError.range(start, 0, this.length);
      }
      if (typeof pattern == 'string') {
        let other = pattern;
        if (dart.notNull(start) + dart.notNull(other.length) > dart.notNull(this.length)) {
          start = dart.notNull(this.length) - dart.notNull(other.length);
        }
        return dart.as(_js_helper.stringLastIndexOfUnchecked(this, other, start), core.int);
      }
      for (let i = start; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
        if (pattern[dartx.matchAsPrefix](this, i) != null)
          return i;
      }
      return -1;
    }
    contains(other, startIndex) {
      if (startIndex === void 0)
        startIndex = 0;
      _js_helper.checkNull(other);
      if (dart.notNull(startIndex) < 0 || dart.notNull(startIndex) > dart.notNull(this.length)) {
        throw new core.RangeError.range(startIndex, 0, this.length);
      }
      return dart.as(_js_helper.stringContainsUnchecked(this, other, startIndex), core.bool);
    }
    get isEmpty() {
      return this.length == 0;
    }
    get isNotEmpty() {
      return !dart.notNull(this[dartx.isEmpty]);
    }
    compareTo(other) {
      if (!(typeof other == 'string'))
        throw new core.ArgumentError(other);
      return dart.equals(this, other) ? 0 : this < other ? -1 : 1;
    }
    toString() {
      return this;
    }
    get hashCode() {
      let hash = 0;
      for (let i = 0; dart.notNull(i) < dart.notNull(this.length); i = dart.notNull(i) + 1) {
        hash = 536870911 & dart.notNull(hash) + this.charCodeAt(i);
        hash = 536870911 & dart.notNull(hash) + ((524287 & dart.notNull(hash)) << 10);
        hash = hash ^ hash >> 6;
      }
      hash = 536870911 & dart.notNull(hash) + ((67108863 & dart.notNull(hash)) << 3);
      hash = hash ^ hash >> 11;
      return 536870911 & dart.notNull(hash) + ((16383 & dart.notNull(hash)) << 15);
    }
    get runtimeType() {
      return core.String;
    }
    get length() {
      return this.length;
    }
    get(index) {
      if (!(typeof index == 'number'))
        throw new core.ArgumentError(index);
      if (dart.notNull(index) >= dart.notNull(this.length) || dart.notNull(index) < 0)
        throw new core.RangeError.value(index);
      return this[index];
    }
  }
  JSString[dart.implements] = () => [core.String, JSIndexable];
  dart.setSignature(JSString, {
    constructors: () => ({JSString: [JSString, []]}),
    methods: () => ({
      codeUnitAt: [core.int, [core.int]],
      allMatches: [core.Iterable$(core.Match), [core.String], [core.int]],
      matchAsPrefix: [core.Match, [core.String], [core.int]],
      '+': [core.String, [core.String]],
      endsWith: [core.bool, [core.String]],
      replaceAll: [core.String, [core.Pattern, core.String]],
      replaceAllMapped: [core.String, [core.Pattern, dart.functionType(core.String, [core.Match])]],
      splitMapJoin: [core.String, [core.Pattern], {onMatch: dart.functionType(core.String, [core.Match]), onNonMatch: dart.functionType(core.String, [core.String])}],
      replaceFirst: [core.String, [core.Pattern, core.String], [core.int]],
      split: [core.List$(core.String), [core.Pattern]],
      [_defaultSplit]: [core.List$(core.String), [core.Pattern]],
      startsWith: [core.bool, [core.Pattern], [core.int]],
      substring: [core.String, [core.int], [core.int]],
      toLowerCase: [core.String, []],
      toUpperCase: [core.String, []],
      trim: [core.String, []],
      trimLeft: [core.String, []],
      trimRight: [core.String, []],
      '*': [core.String, [core.int]],
      padLeft: [core.String, [core.int], [core.String]],
      padRight: [core.String, [core.int], [core.String]],
      indexOf: [core.int, [core.Pattern], [core.int]],
      lastIndexOf: [core.int, [core.Pattern], [core.int]],
      contains: [core.bool, [core.Pattern], [core.int]],
      compareTo: [core.int, [core.String]],
      get: [core.String, [core.int]]
    }),
    statics: () => ({
      _isWhitespace: [core.bool, [core.int]],
      _skipLeadingWhitespace: [core.int, [core.String, core.int]],
      _skipTrailingWhitespace: [core.int, [core.String, core.int]]
    }),
    names: ['_isWhitespace', '_skipLeadingWhitespace', '_skipTrailingWhitespace']
  });
  dart.registerExtension(dart.global.String, JSString);
  let _string = Symbol('_string');
  class _CodeUnits extends _internal.UnmodifiableListBase$(core.int) {
    _CodeUnits(string) {
      this[_string] = string;
    }
    get length() {
      return this[_string].length;
    }
    get(i) {
      return this[_string][dartx.codeUnitAt](i);
    }
  }
  dart.setSignature(_CodeUnits, {
    constructors: () => ({_CodeUnits: [_CodeUnits, [core.String]]}),
    methods: () => ({get: [core.int, [core.int]]})
  });
  function getInterceptor(obj) {
    return obj;
  }
  dart.fn(getInterceptor);
  class JSBool extends Interceptor {
    JSBool() {
      super.Interceptor();
    }
    toString() {
      return String(this);
    }
    get hashCode() {
      return this ? 2 * 3 * 23 * 3761 : 269 * 811;
    }
    get runtimeType() {
      return core.bool;
    }
  }
  JSBool[dart.implements] = () => [core.bool];
  dart.setSignature(JSBool, {
    constructors: () => ({JSBool: [JSBool, []]})
  });
  dart.registerExtension(dart.global.Boolean, JSBool);
  class JSIndexable extends core.Object {}
  class JSMutableIndexable extends JSIndexable {}
  class JSObject extends core.Object {}
  class JavaScriptObject extends Interceptor {
    JavaScriptObject() {
      super.Interceptor();
    }
    get hashCode() {
      return 0;
    }
    get runtimeType() {
      return JSObject;
    }
  }
  JavaScriptObject[dart.implements] = () => [JSObject];
  dart.setSignature(JavaScriptObject, {
    constructors: () => ({JavaScriptObject: [JavaScriptObject, []]})
  });
  class PlainJavaScriptObject extends JavaScriptObject {
    PlainJavaScriptObject() {
      super.JavaScriptObject();
    }
  }
  dart.setSignature(PlainJavaScriptObject, {
    constructors: () => ({PlainJavaScriptObject: [PlainJavaScriptObject, []]})
  });
  class UnknownJavaScriptObject extends JavaScriptObject {
    UnknownJavaScriptObject() {
      super.JavaScriptObject();
    }
    toString() {
      return String(this);
    }
  }
  dart.setSignature(UnknownJavaScriptObject, {
    constructors: () => ({UnknownJavaScriptObject: [UnknownJavaScriptObject, []]})
  });
  // Exports:
  exports.JSArray$ = JSArray$;
  exports.JSArray = JSArray;
  exports.JSMutableArray$ = JSMutableArray$;
  exports.JSMutableArray = JSMutableArray;
  exports.JSFixedArray$ = JSFixedArray$;
  exports.JSFixedArray = JSFixedArray;
  exports.JSExtendableArray$ = JSExtendableArray$;
  exports.JSExtendableArray = JSExtendableArray;
  exports.Interceptor = Interceptor;
  exports.JSNumber = JSNumber;
  exports.JSInt = JSInt;
  exports.JSDouble = JSDouble;
  exports.JSPositiveInt = JSPositiveInt;
  exports.JSUInt32 = JSUInt32;
  exports.JSUInt31 = JSUInt31;
  exports.JSString = JSString;
  exports.getInterceptor = getInterceptor;
  exports.JSBool = JSBool;
  exports.JSIndexable = JSIndexable;
  exports.JSMutableIndexable = JSMutableIndexable;
  exports.JSObject = JSObject;
  exports.JavaScriptObject = JavaScriptObject;
  exports.PlainJavaScriptObject = PlainJavaScriptObject;
  exports.UnknownJavaScriptObject = UnknownJavaScriptObject;
})(_interceptors, core, _internal, _js_helper, collection, math);
