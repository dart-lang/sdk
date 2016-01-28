dart_library.library('dart/_interceptors', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/_internal',
  'dart/collection',
  'dart/math'
], /* Lazy imports */[
  'dart/_js_helper'
], function(exports, dart, core, _internal, collection, math, _js_helper) {
  'use strict';
  let dartx = dart.dartx;
  const JSArray$ = dart.generic(function(E) {
    dart.defineExtensionNames([
      'checkGrowable',
      'add',
      'removeAt',
      'insert',
      'insertAll',
      'setAll',
      'removeLast',
      'remove',
      'removeWhere',
      'retainWhere',
      'where',
      'expand',
      'addAll',
      'clear',
      'forEach',
      'map',
      'join',
      'take',
      'takeWhile',
      'skip',
      'skipWhile',
      'reduce',
      'fold',
      'firstWhere',
      'lastWhere',
      'singleWhere',
      'elementAt',
      'sublist',
      'getRange',
      'first',
      'last',
      'single',
      'removeRange',
      'setRange',
      'fillRange',
      'replaceRange',
      'any',
      'every',
      'reversed',
      'sort',
      'shuffle',
      'indexOf',
      'lastIndexOf',
      'contains',
      'isEmpty',
      'isNotEmpty',
      'toString',
      'toList',
      'toSet',
      'iterator',
      'hashCode',
      'length',
      'length',
      'get',
      'set',
      'asMap'
    ]);
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
        return JSArray$(E).typed(allocation);
      }
      static markFixedList(list) {
        list.fixed$length = Array;
        return list;
      }
      [dartx.checkGrowable](reason) {
        if (this.fixed$length) {
          dart.throw(new core.UnsupportedError(dart.as(reason, core.String)));
        }
      }
      [dartx.add](value) {
        dart.as(value, E);
        this[dartx.checkGrowable]('add');
        this.push(value);
      }
      [dartx.removeAt](index) {
        if (!(typeof index == 'number')) dart.throw(new core.ArgumentError(index));
        if (dart.notNull(index) < 0 || dart.notNull(index) >= dart.notNull(this[dartx.length])) {
          dart.throw(new core.RangeError.value(index));
        }
        this[dartx.checkGrowable]('removeAt');
        return this.splice(index, 1)[0];
      }
      [dartx.insert](index, value) {
        dart.as(value, E);
        if (!(typeof index == 'number')) dart.throw(new core.ArgumentError(index));
        if (dart.notNull(index) < 0 || dart.notNull(index) > dart.notNull(this[dartx.length])) {
          dart.throw(new core.RangeError.value(index));
        }
        this[dartx.checkGrowable]('insert');
        this.splice(index, 0, value);
      }
      [dartx.insertAll](index, iterable) {
        dart.as(iterable, core.Iterable$(E));
        this[dartx.checkGrowable]('insertAll');
        _internal.IterableMixinWorkaround.insertAllList(this, index, iterable);
      }
      [dartx.setAll](index, iterable) {
        dart.as(iterable, core.Iterable$(E));
        _internal.IterableMixinWorkaround.setAllList(this, index, iterable);
      }
      [dartx.removeLast]() {
        this[dartx.checkGrowable]('removeLast');
        if (this[dartx.length] == 0) dart.throw(new core.RangeError.value(-1));
        return dart.as(this.pop(), E);
      }
      [dartx.remove](element) {
        this[dartx.checkGrowable]('remove');
        for (let i = 0; i < dart.notNull(this[dartx.length]); i++) {
          if (dart.equals(this[dartx.get](i), element)) {
            this.splice(i, 1);
            return true;
          }
        }
        return false;
      }
      [dartx.removeWhere](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        _internal.IterableMixinWorkaround.removeWhereList(this, test);
      }
      [dartx.retainWhere](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        _internal.IterableMixinWorkaround.removeWhereList(this, dart.fn(element => !dart.notNull(test(element)), core.bool, [E]));
      }
      [dartx.where](f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        return new (_internal.IterableMixinWorkaround$(E))().where(this, f);
      }
      [dartx.expand](f) {
        dart.as(f, dart.functionType(core.Iterable, [E]));
        return _internal.IterableMixinWorkaround.expand(this, f);
      }
      [dartx.addAll](collection) {
        dart.as(collection, core.Iterable$(E));
        for (let e of collection) {
          this[dartx.add](e);
        }
      }
      [dartx.clear]() {
        this[dartx.length] = 0;
      }
      [dartx.forEach](f) {
        dart.as(f, dart.functionType(dart.void, [E]));
        let length = this[dartx.length];
        for (let i = 0; i < dart.notNull(length); i++) {
          f(dart.as(this[i], E));
          if (length != this[dartx.length]) {
            dart.throw(new core.ConcurrentModificationError(this));
          }
        }
      }
      [dartx.map](f) {
        dart.as(f, dart.functionType(dart.dynamic, [E]));
        return _internal.IterableMixinWorkaround.mapList(this, f);
      }
      [dartx.join](separator) {
        if (separator === void 0) separator = "";
        let list = core.List.new(this[dartx.length]);
        for (let i = 0; i < dart.notNull(this[dartx.length]); i++) {
          list[dartx.set](i, `${this[dartx.get](i)}`);
        }
        return list.join(separator);
      }
      [dartx.take](n) {
        return new (_internal.IterableMixinWorkaround$(E))().takeList(this, n);
      }
      [dartx.takeWhile](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.IterableMixinWorkaround$(E))().takeWhile(this, test);
      }
      [dartx.skip](n) {
        return new (_internal.IterableMixinWorkaround$(E))().skipList(this, n);
      }
      [dartx.skipWhile](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return new (_internal.IterableMixinWorkaround$(E))().skipWhile(this, test);
      }
      [dartx.reduce](combine) {
        dart.as(combine, dart.functionType(E, [E, E]));
        return _internal.IterableMixinWorkaround.reduce(this, combine);
      }
      [dartx.fold](initialValue, combine) {
        dart.as(combine, dart.functionType(dart.dynamic, [dart.dynamic, E]));
        return _internal.IterableMixinWorkaround.fold(this, initialValue, combine);
      }
      [dartx.firstWhere](test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        return _internal.IterableMixinWorkaround.firstWhere(this, test, orElse);
      }
      [dartx.lastWhere](test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        return _internal.IterableMixinWorkaround.lastWhereList(this, test, orElse);
      }
      [dartx.singleWhere](test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return _internal.IterableMixinWorkaround.singleWhere(this, test);
      }
      [dartx.elementAt](index) {
        return this[dartx.get](index);
      }
      [dartx.sublist](start, end) {
        if (end === void 0) end = null;
        _js_helper.checkNull(start);
        if (!(typeof start == 'number')) dart.throw(new core.ArgumentError(start));
        if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(this[dartx.length])) {
          dart.throw(new core.RangeError.range(start, 0, this[dartx.length]));
        }
        if (end == null) {
          end = this[dartx.length];
        } else {
          if (!(typeof end == 'number')) dart.throw(new core.ArgumentError(end));
          if (dart.notNull(end) < dart.notNull(start) || dart.notNull(end) > dart.notNull(this[dartx.length])) {
            dart.throw(new core.RangeError.range(end, start, this[dartx.length]));
          }
        }
        if (start == end) return dart.list([], E);
        return JSArray$(E).typed(this.slice(start, end));
      }
      [dartx.getRange](start, end) {
        return new (_internal.IterableMixinWorkaround$(E))().getRangeList(this, start, end);
      }
      get [dartx.first]() {
        if (dart.notNull(this[dartx.length]) > 0) return this[dartx.get](0);
        dart.throw(new core.StateError("No elements"));
      }
      get [dartx.last]() {
        if (dart.notNull(this[dartx.length]) > 0) return this[dartx.get](dart.notNull(this[dartx.length]) - 1);
        dart.throw(new core.StateError("No elements"));
      }
      get [dartx.single]() {
        if (this[dartx.length] == 1) return this[dartx.get](0);
        if (this[dartx.length] == 0) dart.throw(new core.StateError("No elements"));
        dart.throw(new core.StateError("More than one element"));
      }
      [dartx.removeRange](start, end) {
        this[dartx.checkGrowable]('removeRange');
        let receiverLength = this[dartx.length];
        if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(receiverLength)) {
          dart.throw(new core.RangeError.range(start, 0, receiverLength));
        }
        if (dart.notNull(end) < dart.notNull(start) || dart.notNull(end) > dart.notNull(receiverLength)) {
          dart.throw(new core.RangeError.range(end, start, receiverLength));
        }
        _internal.Lists.copy(this, end, this, start, dart.notNull(receiverLength) - dart.notNull(end));
        this[dartx.length] = dart.notNull(receiverLength) - (dart.notNull(end) - dart.notNull(start));
      }
      [dartx.setRange](start, end, iterable, skipCount) {
        dart.as(iterable, core.Iterable$(E));
        if (skipCount === void 0) skipCount = 0;
        _internal.IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
      }
      [dartx.fillRange](start, end, fillValue) {
        if (fillValue === void 0) fillValue = null;
        dart.as(fillValue, E);
        _internal.IterableMixinWorkaround.fillRangeList(this, start, end, fillValue);
      }
      [dartx.replaceRange](start, end, iterable) {
        dart.as(iterable, core.Iterable$(E));
        _internal.IterableMixinWorkaround.replaceRangeList(this, start, end, iterable);
      }
      [dartx.any](f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        return _internal.IterableMixinWorkaround.any(this, f);
      }
      [dartx.every](f) {
        dart.as(f, dart.functionType(core.bool, [E]));
        return _internal.IterableMixinWorkaround.every(this, f);
      }
      get [dartx.reversed]() {
        return new (_internal.IterableMixinWorkaround$(E))().reversedList(this);
      }
      [dartx.sort](compare) {
        if (compare === void 0) compare = null;
        dart.as(compare, dart.functionType(core.int, [E, E]));
        _internal.IterableMixinWorkaround.sortList(this, compare);
      }
      [dartx.shuffle](random) {
        if (random === void 0) random = null;
        _internal.IterableMixinWorkaround.shuffleList(this, random);
      }
      [dartx.indexOf](element, start) {
        if (start === void 0) start = 0;
        return _internal.IterableMixinWorkaround.indexOfList(this, element, start);
      }
      [dartx.lastIndexOf](element, start) {
        if (start === void 0) start = null;
        return _internal.IterableMixinWorkaround.lastIndexOfList(this, element, start);
      }
      [dartx.contains](other) {
        for (let i = 0; i < dart.notNull(this[dartx.length]); i++) {
          if (dart.equals(this[dartx.get](i), other)) return true;
        }
        return false;
      }
      get [dartx.isEmpty]() {
        return this[dartx.length] == 0;
      }
      get [dartx.isNotEmpty]() {
        return !dart.notNull(this[dartx.isEmpty]);
      }
      toString() {
        return collection.ListBase.listToString(this);
      }
      [dartx.toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        let list = this.slice();
        if (!dart.notNull(growable)) JSArray$().markFixedList(dart.as(list, core.List));
        return JSArray$(E).typed(list);
      }
      [dartx.toSet]() {
        return core.Set$(E).from(this);
      }
      get [dartx.iterator]() {
        return new (_internal.ListIterator$(E))(this);
      }
      get hashCode() {
        return _js_helper.Primitives.objectHashCode(this);
      }
      get [dartx.length]() {
        return this.length;
      }
      set [dartx.length](newLength) {
        if (!(typeof newLength == 'number')) dart.throw(new core.ArgumentError(newLength));
        if (dart.notNull(newLength) < 0) dart.throw(new core.RangeError.value(newLength));
        this[dartx.checkGrowable]('set length');
        this.length = newLength;
      }
      [dartx.get](index) {
        if (!(typeof index == 'number')) dart.throw(new core.ArgumentError(index));
        if (dart.notNull(index) >= dart.notNull(this[dartx.length]) || dart.notNull(index) < 0) dart.throw(new core.RangeError.value(index));
        return dart.as(this[index], E);
      }
      [dartx.set](index, value) {
        dart.as(value, E);
        if (!(typeof index == 'number')) dart.throw(new core.ArgumentError(index));
        if (dart.notNull(index) >= dart.notNull(this[dartx.length]) || dart.notNull(index) < 0) dart.throw(new core.RangeError.value(index));
        this[index] = value;
        return value;
      }
      [dartx.asMap]() {
        return new (_internal.IterableMixinWorkaround$(E))().asMapList(this);
      }
    }
    dart.setBaseClass(JSArray, dart.global.Array);
    JSArray[dart.implements] = () => [core.List$(E), JSIndexable];
    dart.setSignature(JSArray, {
      constructors: () => ({
        JSArray: [JSArray$(E), []],
        typed: [JSArray$(E), [dart.dynamic]],
        markFixed: [JSArray$(E), [dart.dynamic]],
        markGrowable: [JSArray$(E), [dart.dynamic]]
      }),
      methods: () => ({
        [dartx.checkGrowable]: [dart.dynamic, [dart.dynamic]],
        [dartx.add]: [dart.void, [E]],
        [dartx.removeAt]: [E, [core.int]],
        [dartx.insert]: [dart.void, [core.int, E]],
        [dartx.insertAll]: [dart.void, [core.int, core.Iterable$(E)]],
        [dartx.setAll]: [dart.void, [core.int, core.Iterable$(E)]],
        [dartx.removeLast]: [E, []],
        [dartx.remove]: [core.bool, [core.Object]],
        [dartx.removeWhere]: [dart.void, [dart.functionType(core.bool, [E])]],
        [dartx.retainWhere]: [dart.void, [dart.functionType(core.bool, [E])]],
        [dartx.where]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [dartx.expand]: [core.Iterable, [dart.functionType(core.Iterable, [E])]],
        [dartx.addAll]: [dart.void, [core.Iterable$(E)]],
        [dartx.clear]: [dart.void, []],
        [dartx.forEach]: [dart.void, [dart.functionType(dart.void, [E])]],
        [dartx.map]: [core.Iterable, [dart.functionType(dart.dynamic, [E])]],
        [dartx.join]: [core.String, [], [core.String]],
        [dartx.take]: [core.Iterable$(E), [core.int]],
        [dartx.takeWhile]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [dartx.skip]: [core.Iterable$(E), [core.int]],
        [dartx.skipWhile]: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        [dartx.reduce]: [E, [dart.functionType(E, [E, E])]],
        [dartx.fold]: [dart.dynamic, [dart.dynamic, dart.functionType(dart.dynamic, [dart.dynamic, E])]],
        [dartx.firstWhere]: [E, [dart.functionType(core.bool, [E])], {orElse: dart.functionType(E, [])}],
        [dartx.lastWhere]: [E, [dart.functionType(core.bool, [E])], {orElse: dart.functionType(E, [])}],
        [dartx.singleWhere]: [E, [dart.functionType(core.bool, [E])]],
        [dartx.elementAt]: [E, [core.int]],
        [dartx.sublist]: [core.List$(E), [core.int], [core.int]],
        [dartx.getRange]: [core.Iterable$(E), [core.int, core.int]],
        [dartx.removeRange]: [dart.void, [core.int, core.int]],
        [dartx.setRange]: [dart.void, [core.int, core.int, core.Iterable$(E)], [core.int]],
        [dartx.fillRange]: [dart.void, [core.int, core.int], [E]],
        [dartx.replaceRange]: [dart.void, [core.int, core.int, core.Iterable$(E)]],
        [dartx.any]: [core.bool, [dart.functionType(core.bool, [E])]],
        [dartx.every]: [core.bool, [dart.functionType(core.bool, [E])]],
        [dartx.sort]: [dart.void, [], [dart.functionType(core.int, [E, E])]],
        [dartx.shuffle]: [dart.void, [], [math.Random]],
        [dartx.indexOf]: [core.int, [core.Object], [core.int]],
        [dartx.lastIndexOf]: [core.int, [core.Object], [core.int]],
        [dartx.contains]: [core.bool, [core.Object]],
        [dartx.toList]: [core.List$(E), [], {growable: core.bool}],
        [dartx.toSet]: [core.Set$(E), []],
        [dartx.get]: [E, [core.int]],
        [dartx.set]: [dart.void, [core.int, E]],
        [dartx.asMap]: [core.Map$(core.int, E), []]
      }),
      statics: () => ({markFixedList: [core.List, [core.List]]}),
      names: ['markFixedList']
    });
    JSArray[dart.metadata] = () => [dart.const(new _js_helper.JsPeerInterface({name: 'Array'}))];
    return JSArray;
  });
  let JSArray = JSArray$();
  dart.registerExtension(dart.global.Array, JSArray);
  const JSMutableArray$ = dart.generic(function(E) {
    class JSMutableArray extends JSArray$(E) {
      JSMutableArray() {
        super.JSArray();
      }
    }
    JSMutableArray[dart.implements] = () => [JSMutableIndexable];
    return JSMutableArray;
  });
  let JSMutableArray = JSMutableArray$();
  const JSFixedArray$ = dart.generic(function(E) {
    class JSFixedArray extends JSMutableArray$(E) {}
    return JSFixedArray;
  });
  let JSFixedArray = JSFixedArray$();
  const JSExtendableArray$ = dart.generic(function(E) {
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
  const _isInt32 = Symbol('_isInt32');
  const _tdivSlow = Symbol('_tdivSlow');
  const _shlPositive = Symbol('_shlPositive');
  const _shrOtherPositive = Symbol('_shrOtherPositive');
  const _shrBothPositive = Symbol('_shrBothPositive');
  dart.defineExtensionNames([
    'compareTo',
    'isNegative',
    'isNaN',
    'isInfinite',
    'isFinite',
    'remainder',
    'abs',
    'sign',
    'toInt',
    'truncate',
    'ceil',
    'floor',
    'round',
    'ceilToDouble',
    'floorToDouble',
    'roundToDouble',
    'truncateToDouble',
    'clamp',
    'toDouble',
    'toStringAsFixed',
    'toStringAsExponential',
    'toStringAsPrecision',
    'toRadixString',
    'toString',
    'hashCode',
    'unary-',
    '+',
    '-',
    '/',
    '*',
    '%',
    '~/',
    '<<',
    '>>',
    '&',
    '|',
    '^',
    '<',
    '>',
    '<=',
    '>=',
    'isEven',
    'isOdd',
    'toUnsigned',
    'toSigned',
    'bitLength',
    '~'
  ]);
  class JSNumber extends Interceptor {
    JSNumber() {
      super.Interceptor();
    }
    [dartx.compareTo](b) {
      if (this < dart.notNull(b)) {
        return -1;
      } else if (this > dart.notNull(b)) {
        return 1;
      } else if (this == b) {
        if (this == 0) {
          let bIsNegative = b[dartx.isNegative];
          if (this[dartx.isNegative] == bIsNegative) return 0;
          if (dart.notNull(this[dartx.isNegative])) return -1;
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
    get [dartx.isNegative]() {
      return this == 0 ? 1 / this < 0 : this < 0;
    }
    get [dartx.isNaN]() {
      return isNaN(this);
    }
    get [dartx.isInfinite]() {
      return this == Infinity || this == -Infinity;
    }
    get [dartx.isFinite]() {
      return isFinite(this);
    }
    [dartx.remainder](b) {
      _js_helper.checkNull(b);
      return this % b;
    }
    [dartx.abs]() {
      return Math.abs(this);
    }
    get [dartx.sign]() {
      return this > 0 ? 1 : this < 0 ? -1 : this;
    }
    [dartx.toInt]() {
      if (this >= dart.notNull(JSNumber._MIN_INT32) && this <= dart.notNull(JSNumber._MAX_INT32)) {
        return this | 0;
      }
      if (isFinite(this)) {
        return this[dartx.truncateToDouble]() + 0;
      }
      dart.throw(new core.UnsupportedError('' + this));
    }
    [dartx.truncate]() {
      return this[dartx.toInt]();
    }
    [dartx.ceil]() {
      return this[dartx.ceilToDouble]()[dartx.toInt]();
    }
    [dartx.floor]() {
      return this[dartx.floorToDouble]()[dartx.toInt]();
    }
    [dartx.round]() {
      return this[dartx.roundToDouble]()[dartx.toInt]();
    }
    [dartx.ceilToDouble]() {
      return Math.ceil(this);
    }
    [dartx.floorToDouble]() {
      return Math.floor(this);
    }
    [dartx.roundToDouble]() {
      if (this < 0) {
        return -Math.round(-this);
      } else {
        return Math.round(this);
      }
    }
    [dartx.truncateToDouble]() {
      return this < 0 ? this[dartx.ceilToDouble]() : this[dartx.floorToDouble]();
    }
    [dartx.clamp](lowerLimit, upperLimit) {
      if (dart.notNull(lowerLimit[dartx.compareTo](upperLimit)) > 0) {
        dart.throw(new core.ArgumentError(lowerLimit));
      }
      if (dart.notNull(this[dartx.compareTo](lowerLimit)) < 0) return lowerLimit;
      if (dart.notNull(this[dartx.compareTo](upperLimit)) > 0) return upperLimit;
      return this;
    }
    [dartx.toDouble]() {
      return this;
    }
    [dartx.toStringAsFixed](fractionDigits) {
      _js_helper.checkInt(fractionDigits);
      if (dart.notNull(fractionDigits) < 0 || dart.notNull(fractionDigits) > 20) {
        dart.throw(new core.RangeError(fractionDigits));
      }
      let result = this.toFixed(fractionDigits);
      if (this == 0 && dart.notNull(this[dartx.isNegative])) return `-${result}`;
      return result;
    }
    [dartx.toStringAsExponential](fractionDigits) {
      if (fractionDigits === void 0) fractionDigits = null;
      let result = null;
      if (fractionDigits != null) {
        _js_helper.checkInt(fractionDigits);
        if (dart.notNull(fractionDigits) < 0 || dart.notNull(fractionDigits) > 20) {
          dart.throw(new core.RangeError(fractionDigits));
        }
        result = this.toExponential(fractionDigits);
      } else {
        result = this.toExponential();
      }
      if (this == 0 && dart.notNull(this[dartx.isNegative])) return `-${result}`;
      return result;
    }
    [dartx.toStringAsPrecision](precision) {
      _js_helper.checkInt(precision);
      if (dart.notNull(precision) < 1 || dart.notNull(precision) > 21) {
        dart.throw(new core.RangeError(precision));
      }
      let result = this.toPrecision(precision);
      if (this == 0 && dart.notNull(this[dartx.isNegative])) return `-${result}`;
      return result;
    }
    [dartx.toRadixString](radix) {
      _js_helper.checkInt(radix);
      if (dart.notNull(radix) < 2 || dart.notNull(radix) > 36) dart.throw(new core.RangeError(radix));
      let result = this.toString(radix);
      let rightParenCode = 41;
      if (result[dartx.codeUnitAt](dart.notNull(result[dartx.length]) - 1) != rightParenCode) {
        return result;
      }
      return JSNumber._handleIEtoString(result);
    }
    static _handleIEtoString(result) {
      let match = /^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(result);
      if (match == null) {
        dart.throw(new core.UnsupportedError(`Unexpected toString result: ${result}`));
      }
      result = dart.dindex(match, 1);
      let exponent = +dart.dindex(match, 3);
      if (dart.dindex(match, 2) != null) {
        result = result + dart.dindex(match, 2);
        exponent = exponent - dart.dindex(match, 2).length;
      }
      return dart.notNull(result) + "0"[dartx['*']](exponent);
    }
    toString() {
      if (this == 0 && 1 / this < 0) {
        return '-0.0';
      } else {
        return "" + this;
      }
    }
    get hashCode() {
      return this & 0x1FFFFFFF;
    }
    [dartx['unary-']]() {
      return -this;
    }
    [dartx['+']](other) {
      _js_helper.checkNull(other);
      return this + other;
    }
    [dartx['-']](other) {
      _js_helper.checkNull(other);
      return this - other;
    }
    [dartx['/']](other) {
      _js_helper.checkNull(other);
      return this / other;
    }
    [dartx['*']](other) {
      _js_helper.checkNull(other);
      return this * other;
    }
    [dartx['%']](other) {
      _js_helper.checkNull(other);
      let result = this % other;
      if (result == 0) return 0;
      if (result > 0) return result;
      if (other < 0) {
        return result - other;
      } else {
        return result + other;
      }
    }
    [_isInt32](value) {
      return (value | 0) === value;
    }
    [dartx['~/']](other) {
      if (dart.notNull(this[_isInt32](this)) && dart.notNull(this[_isInt32](other)) && 0 != other && -1 != other) {
        return this / other | 0;
      } else {
        return this[_tdivSlow](other);
      }
    }
    [_tdivSlow](other) {
      _js_helper.checkNull(other);
      return (this / other)[dartx.toInt]();
    }
    [dartx['<<']](other) {
      if (dart.notNull(other) < 0) dart.throw(new core.ArgumentError(other));
      return this[_shlPositive](other);
    }
    [_shlPositive](other) {
      return other > 31 ? 0 : this << other >>> 0;
    }
    [dartx['>>']](other) {
      if (dart.notNull(other) < 0) dart.throw(new core.ArgumentError(other));
      return this[_shrOtherPositive](other);
    }
    [_shrOtherPositive](other) {
      return this > 0 ? this[_shrBothPositive](other) : this >> (dart.notNull(other) > 31 ? 31 : other) >>> 0;
    }
    [_shrBothPositive](other) {
      return other > 31 ? 0 : this >>> other;
    }
    [dartx['&']](other) {
      _js_helper.checkNull(other);
      return (this & other) >>> 0;
    }
    [dartx['|']](other) {
      _js_helper.checkNull(other);
      return (this | other) >>> 0;
    }
    [dartx['^']](other) {
      _js_helper.checkNull(other);
      return (this ^ other) >>> 0;
    }
    [dartx['<']](other) {
      _js_helper.checkNull(other);
      return this < other;
    }
    [dartx['>']](other) {
      _js_helper.checkNull(other);
      return this > other;
    }
    [dartx['<=']](other) {
      _js_helper.checkNull(other);
      return this <= other;
    }
    [dartx['>=']](other) {
      _js_helper.checkNull(other);
      return this >= other;
    }
    get [dartx.isEven]() {
      return (this & 1) == 0;
    }
    get [dartx.isOdd]() {
      return (this & 1) == 1;
    }
    [dartx.toUnsigned](width) {
      return this & (1 << dart.notNull(width)) - 1;
    }
    [dartx.toSigned](width) {
      let signMask = 1 << dart.notNull(width) - 1;
      return (this & signMask - 1) - (this & signMask);
    }
    get [dartx.bitLength]() {
      let nonneg = this < 0 ? -this - 1 : this;
      if (nonneg >= 4294967296) {
        nonneg = (nonneg / 4294967296)[dartx.truncate]();
        return dart.notNull(JSNumber._bitCount(JSNumber._spread(nonneg))) + 32;
      }
      return JSNumber._bitCount(JSNumber._spread(nonneg));
    }
    static _bitCount(i) {
      i = dart.notNull(JSNumber._shru(i, 0)) - (dart.notNull(JSNumber._shru(i, 1)) & 1431655765);
      i = (dart.notNull(i) & 858993459) + (dart.notNull(JSNumber._shru(i, 2)) & 858993459);
      i = 252645135 & dart.notNull(i) + dart.notNull(JSNumber._shru(i, 4));
      i = dart.notNull(i) + dart.notNull(JSNumber._shru(i, 8));
      i = dart.notNull(i) + dart.notNull(JSNumber._shru(i, 16));
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
      i = JSNumber._ors(i, JSNumber._shrs(i, 1));
      i = JSNumber._ors(i, JSNumber._shrs(i, 2));
      i = JSNumber._ors(i, JSNumber._shrs(i, 4));
      i = JSNumber._ors(i, JSNumber._shrs(i, 8));
      i = JSNumber._shru(JSNumber._ors(i, JSNumber._shrs(i, 16)), 0);
      return i;
    }
    [dartx['~']]() {
      return ~this >>> 0;
    }
  }
  JSNumber[dart.implements] = () => [core.int, core.double];
  dart.setSignature(JSNumber, {
    constructors: () => ({JSNumber: [JSNumber, []]}),
    methods: () => ({
      [dartx.compareTo]: [core.int, [core.num]],
      [dartx.remainder]: [JSNumber, [core.num]],
      [dartx.abs]: [JSNumber, []],
      [dartx.toInt]: [core.int, []],
      [dartx.truncate]: [core.int, []],
      [dartx.ceil]: [core.int, []],
      [dartx.floor]: [core.int, []],
      [dartx.round]: [core.int, []],
      [dartx.ceilToDouble]: [core.double, []],
      [dartx.floorToDouble]: [core.double, []],
      [dartx.roundToDouble]: [core.double, []],
      [dartx.truncateToDouble]: [core.double, []],
      [dartx.clamp]: [core.num, [core.num, core.num]],
      [dartx.toDouble]: [core.double, []],
      [dartx.toStringAsFixed]: [core.String, [core.int]],
      [dartx.toStringAsExponential]: [core.String, [], [core.int]],
      [dartx.toStringAsPrecision]: [core.String, [core.int]],
      [dartx.toRadixString]: [core.String, [core.int]],
      [dartx['unary-']]: [JSNumber, []],
      [dartx['+']]: [JSNumber, [core.num]],
      [dartx['-']]: [JSNumber, [core.num]],
      [dartx['/']]: [core.double, [core.num]],
      [dartx['*']]: [JSNumber, [core.num]],
      [dartx['%']]: [JSNumber, [core.num]],
      [_isInt32]: [core.bool, [dart.dynamic]],
      [dartx['~/']]: [core.int, [core.num]],
      [_tdivSlow]: [core.int, [core.num]],
      [dartx['<<']]: [core.int, [core.num]],
      [_shlPositive]: [core.int, [core.num]],
      [dartx['>>']]: [core.int, [core.num]],
      [_shrOtherPositive]: [core.int, [core.num]],
      [_shrBothPositive]: [core.int, [core.num]],
      [dartx['&']]: [core.int, [core.num]],
      [dartx['|']]: [core.int, [core.num]],
      [dartx['^']]: [core.int, [core.num]],
      [dartx['<']]: [core.bool, [core.num]],
      [dartx['>']]: [core.bool, [core.num]],
      [dartx['<=']]: [core.bool, [core.num]],
      [dartx['>=']]: [core.bool, [core.num]],
      [dartx.toUnsigned]: [core.int, [core.int]],
      [dartx.toSigned]: [core.int, [core.int]],
      [dartx['~']]: [core.int, []]
    }),
    statics: () => ({
      _handleIEtoString: [core.String, [core.String]],
      _bitCount: [core.int, [core.int]],
      _shru: [core.int, [core.int, core.int]],
      _shrs: [core.int, [core.int, core.int]],
      _ors: [core.int, [core.int, core.int]],
      _spread: [core.int, [core.int]]
    }),
    names: ['_handleIEtoString', '_bitCount', '_shru', '_shrs', '_ors', '_spread']
  });
  JSNumber[dart.metadata] = () => [dart.const(new _js_helper.JsPeerInterface({name: 'Number'}))];
  JSNumber._MIN_INT32 = -2147483648;
  JSNumber._MAX_INT32 = 2147483647;
  dart.registerExtension(dart.global.Number, JSNumber);
  const _defaultSplit = Symbol('_defaultSplit');
  dart.defineExtensionNames([
    'codeUnitAt',
    'allMatches',
    'matchAsPrefix',
    '+',
    'endsWith',
    'replaceAll',
    'replaceAllMapped',
    'splitMapJoin',
    'replaceFirst',
    'split',
    'startsWith',
    'substring',
    'toLowerCase',
    'toUpperCase',
    'trim',
    'trimLeft',
    'trimRight',
    '*',
    'padLeft',
    'padRight',
    'codeUnits',
    'runes',
    'indexOf',
    'lastIndexOf',
    'contains',
    'isEmpty',
    'isNotEmpty',
    'compareTo',
    'toString',
    'hashCode',
    'runtimeType',
    'length',
    'get'
  ]);
  class JSString extends Interceptor {
    JSString() {
      super.Interceptor();
    }
    [dartx.codeUnitAt](index) {
      if (!(typeof index == 'number')) dart.throw(new core.ArgumentError(index));
      if (dart.notNull(index) < 0) dart.throw(new core.RangeError.value(index));
      if (dart.notNull(index) >= dart.notNull(this[dartx.length])) dart.throw(new core.RangeError.value(index));
      return this.charCodeAt(index);
    }
    [dartx.allMatches](string, start) {
      if (start === void 0) start = 0;
      _js_helper.checkString(string);
      _js_helper.checkInt(start);
      if (0 > dart.notNull(start) || dart.notNull(start) > dart.notNull(string[dartx.length])) {
        dart.throw(new core.RangeError.range(start, 0, string[dartx.length]));
      }
      return _js_helper.allMatchesInStringUnchecked(this, string, start);
    }
    [dartx.matchAsPrefix](string, start) {
      if (start === void 0) start = 0;
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(string[dartx.length])) {
        dart.throw(new core.RangeError.range(start, 0, string[dartx.length]));
      }
      if (dart.notNull(start) + dart.notNull(this[dartx.length]) > dart.notNull(string[dartx.length])) return null;
      for (let i = 0; i < dart.notNull(this[dartx.length]); i++) {
        if (string[dartx.codeUnitAt](dart.notNull(start) + i) != this[dartx.codeUnitAt](i)) {
          return null;
        }
      }
      return new _js_helper.StringMatch(start, string, this);
    }
    [dartx['+']](other) {
      if (!(typeof other == 'string')) dart.throw(new core.ArgumentError(other));
      return this + other;
    }
    [dartx.endsWith](other) {
      _js_helper.checkString(other);
      let otherLength = other[dartx.length];
      if (dart.notNull(otherLength) > dart.notNull(this[dartx.length])) return false;
      return other == this[dartx.substring](dart.notNull(this[dartx.length]) - dart.notNull(otherLength));
    }
    [dartx.replaceAll](from, to) {
      _js_helper.checkString(to);
      return dart.as(_js_helper.stringReplaceAllUnchecked(this, from, to), core.String);
    }
    [dartx.replaceAllMapped](from, convert) {
      return this[dartx.splitMapJoin](from, {onMatch: convert});
    }
    [dartx.splitMapJoin](from, opts) {
      let onMatch = opts && 'onMatch' in opts ? opts.onMatch : null;
      let onNonMatch = opts && 'onNonMatch' in opts ? opts.onNonMatch : null;
      return dart.as(_js_helper.stringReplaceAllFuncUnchecked(this, from, onMatch, onNonMatch), core.String);
    }
    [dartx.replaceFirst](from, to, startIndex) {
      if (startIndex === void 0) startIndex = 0;
      _js_helper.checkString(to);
      _js_helper.checkInt(startIndex);
      if (dart.notNull(startIndex) < 0 || dart.notNull(startIndex) > dart.notNull(this[dartx.length])) {
        dart.throw(new core.RangeError.range(startIndex, 0, this[dartx.length]));
      }
      return dart.as(_js_helper.stringReplaceFirstUnchecked(this, from, to, startIndex), core.String);
    }
    [dartx.split](pattern) {
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
      if (dart.notNull(start) < dart.notNull(this[dartx.length]) || length > 0) {
        result[dartx.add](this[dartx.substring](start));
      }
      return result;
    }
    [dartx.startsWith](pattern, index) {
      if (index === void 0) index = 0;
      _js_helper.checkInt(index);
      if (dart.notNull(index) < 0 || dart.notNull(index) > dart.notNull(this[dartx.length])) {
        dart.throw(new core.RangeError.range(index, 0, this[dartx.length]));
      }
      if (typeof pattern == 'string') {
        let other = pattern;
        let otherLength = other[dartx.length];
        let endIndex = dart.notNull(index) + dart.notNull(otherLength);
        if (endIndex > dart.notNull(this[dartx.length])) return false;
        return other == this.substring(index, endIndex);
      }
      return pattern[dartx.matchAsPrefix](this, index) != null;
    }
    [dartx.substring](startIndex, endIndex) {
      if (endIndex === void 0) endIndex = null;
      _js_helper.checkInt(startIndex);
      if (endIndex == null) endIndex = this[dartx.length];
      _js_helper.checkInt(endIndex);
      if (dart.notNull(startIndex) < 0) dart.throw(new core.RangeError.value(startIndex));
      if (dart.notNull(startIndex) > dart.notNull(endIndex)) dart.throw(new core.RangeError.value(startIndex));
      if (dart.notNull(endIndex) > dart.notNull(this[dartx.length])) dart.throw(new core.RangeError.value(endIndex));
      return this.substring(startIndex, endIndex);
    }
    [dartx.toLowerCase]() {
      return this.toLowerCase();
    }
    [dartx.toUpperCase]() {
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
      while (dart.notNull(index) < dart.notNull(string[dartx.length])) {
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
    [dartx.trim]() {
      let NEL = 133;
      let result = this.trim();
      if (result[dartx.length] == 0) return result;
      let firstCode = result[dartx.codeUnitAt](0);
      let startIndex = 0;
      if (firstCode == NEL) {
        startIndex = JSString._skipLeadingWhitespace(result, 1);
        if (startIndex == result[dartx.length]) return "";
      }
      let endIndex = result[dartx.length];
      let lastCode = result[dartx.codeUnitAt](dart.notNull(endIndex) - 1);
      if (lastCode == NEL) {
        endIndex = JSString._skipTrailingWhitespace(result, dart.notNull(endIndex) - 1);
      }
      if (startIndex == 0 && endIndex == result[dartx.length]) return result;
      return result.substring(startIndex, endIndex);
    }
    [dartx.trimLeft]() {
      let NEL = 133;
      let result = null;
      let startIndex = 0;
      if (typeof this.trimLeft != "undefined") {
        result = this.trimLeft();
        if (result[dartx.length] == 0) return result;
        let firstCode = result[dartx.codeUnitAt](0);
        if (firstCode == NEL) {
          startIndex = JSString._skipLeadingWhitespace(result, 1);
        }
      } else {
        result = this;
        startIndex = JSString._skipLeadingWhitespace(this, 0);
      }
      if (startIndex == 0) return result;
      if (startIndex == result[dartx.length]) return "";
      return result.substring(startIndex);
    }
    [dartx.trimRight]() {
      let NEL = 133;
      let result = null;
      let endIndex = null;
      if (typeof this.trimRight != "undefined") {
        result = this.trimRight();
        endIndex = result[dartx.length];
        if (endIndex == 0) return result;
        let lastCode = result[dartx.codeUnitAt](dart.notNull(endIndex) - 1);
        if (lastCode == NEL) {
          endIndex = JSString._skipTrailingWhitespace(result, dart.notNull(endIndex) - 1);
        }
      } else {
        result = this;
        endIndex = JSString._skipTrailingWhitespace(this, this[dartx.length]);
      }
      if (endIndex == result[dartx.length]) return result;
      if (endIndex == 0) return "";
      return result.substring(0, endIndex);
    }
    [dartx['*']](times) {
      if (0 >= dart.notNull(times)) return '';
      if (times == 1 || this[dartx.length] == 0) return this;
      if (times != times >>> 0) {
        dart.throw(dart.const(new core.OutOfMemoryError()));
      }
      let result = '';
      let s = this;
      while (true) {
        if ((dart.notNull(times) & 1) == 1) result = s + result;
        times = times >>> 1;
        if (times == 0) break;
        s = s + s;
      }
      return result;
    }
    [dartx.padLeft](width, padding) {
      if (padding === void 0) padding = ' ';
      let delta = dart.notNull(width) - dart.notNull(this[dartx.length]);
      if (delta <= 0) return this;
      return padding[dartx['*']](delta) + this;
    }
    [dartx.padRight](width, padding) {
      if (padding === void 0) padding = ' ';
      let delta = dart.notNull(width) - dart.notNull(this[dartx.length]);
      if (delta <= 0) return this;
      return this[dartx['+']](padding[dartx['*']](delta));
    }
    get [dartx.codeUnits]() {
      return new _CodeUnits(this);
    }
    get [dartx.runes]() {
      return new core.Runes(this);
    }
    [dartx.indexOf](pattern, start) {
      if (start === void 0) start = 0;
      _js_helper.checkNull(pattern);
      if (!(typeof start == 'number')) dart.throw(new core.ArgumentError(start));
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(this[dartx.length])) {
        dart.throw(new core.RangeError.range(start, 0, this[dartx.length]));
      }
      if (typeof pattern == 'string') {
        return this.indexOf(pattern, start);
      }
      if (dart.is(pattern, _js_helper.JSSyntaxRegExp)) {
        let re = pattern;
        let match = _js_helper.firstMatchAfter(re, this, start);
        return match == null ? -1 : match.start;
      }
      for (let i = start; dart.notNull(i) <= dart.notNull(this[dartx.length]); i = dart.notNull(i) + 1) {
        if (pattern[dartx.matchAsPrefix](this, i) != null) return i;
      }
      return -1;
    }
    [dartx.lastIndexOf](pattern, start) {
      if (start === void 0) start = null;
      _js_helper.checkNull(pattern);
      if (start == null) {
        start = this[dartx.length];
      } else if (!(typeof start == 'number')) {
        dart.throw(new core.ArgumentError(start));
      } else if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(this[dartx.length])) {
        dart.throw(new core.RangeError.range(start, 0, this[dartx.length]));
      }
      if (typeof pattern == 'string') {
        let other = pattern;
        if (dart.notNull(start) + dart.notNull(other[dartx.length]) > dart.notNull(this[dartx.length])) {
          start = dart.notNull(this[dartx.length]) - dart.notNull(other[dartx.length]);
        }
        return dart.as(_js_helper.stringLastIndexOfUnchecked(this, other, start), core.int);
      }
      for (let i = start; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
        if (pattern[dartx.matchAsPrefix](this, i) != null) return i;
      }
      return -1;
    }
    [dartx.contains](other, startIndex) {
      if (startIndex === void 0) startIndex = 0;
      _js_helper.checkNull(other);
      if (dart.notNull(startIndex) < 0 || dart.notNull(startIndex) > dart.notNull(this[dartx.length])) {
        dart.throw(new core.RangeError.range(startIndex, 0, this[dartx.length]));
      }
      return dart.as(_js_helper.stringContainsUnchecked(this, other, startIndex), core.bool);
    }
    get [dartx.isEmpty]() {
      return this[dartx.length] == 0;
    }
    get [dartx.isNotEmpty]() {
      return !dart.notNull(this[dartx.isEmpty]);
    }
    [dartx.compareTo](other) {
      if (!(typeof other == 'string')) dart.throw(new core.ArgumentError(other));
      return dart.equals(this, other) ? 0 : this < other ? -1 : 1;
    }
    toString() {
      return this;
    }
    get hashCode() {
      let hash = 0;
      for (let i = 0; i < dart.notNull(this[dartx.length]); i++) {
        hash = 536870911 & hash + this.charCodeAt(i);
        hash = 536870911 & hash + ((524287 & hash) << 10);
        hash = hash ^ hash >> 6;
      }
      hash = 536870911 & hash + ((67108863 & hash) << 3);
      hash = hash ^ hash >> 11;
      return 536870911 & hash + ((16383 & hash) << 15);
    }
    get runtimeType() {
      return core.String;
    }
    get [dartx.length]() {
      return this.length;
    }
    [dartx.get](index) {
      if (!(typeof index == 'number')) dart.throw(new core.ArgumentError(index));
      if (dart.notNull(index) >= dart.notNull(this[dartx.length]) || dart.notNull(index) < 0) dart.throw(new core.RangeError.value(index));
      return this[index];
    }
  }
  JSString[dart.implements] = () => [core.String, JSIndexable];
  dart.setSignature(JSString, {
    constructors: () => ({JSString: [JSString, []]}),
    methods: () => ({
      [dartx.codeUnitAt]: [core.int, [core.int]],
      [dartx.allMatches]: [core.Iterable$(core.Match), [core.String], [core.int]],
      [dartx.matchAsPrefix]: [core.Match, [core.String], [core.int]],
      [dartx['+']]: [core.String, [core.String]],
      [dartx.endsWith]: [core.bool, [core.String]],
      [dartx.replaceAll]: [core.String, [core.Pattern, core.String]],
      [dartx.replaceAllMapped]: [core.String, [core.Pattern, dart.functionType(core.String, [core.Match])]],
      [dartx.splitMapJoin]: [core.String, [core.Pattern], {onMatch: dart.functionType(core.String, [core.Match]), onNonMatch: dart.functionType(core.String, [core.String])}],
      [dartx.replaceFirst]: [core.String, [core.Pattern, core.String], [core.int]],
      [dartx.split]: [core.List$(core.String), [core.Pattern]],
      [_defaultSplit]: [core.List$(core.String), [core.Pattern]],
      [dartx.startsWith]: [core.bool, [core.Pattern], [core.int]],
      [dartx.substring]: [core.String, [core.int], [core.int]],
      [dartx.toLowerCase]: [core.String, []],
      [dartx.toUpperCase]: [core.String, []],
      [dartx.trim]: [core.String, []],
      [dartx.trimLeft]: [core.String, []],
      [dartx.trimRight]: [core.String, []],
      [dartx['*']]: [core.String, [core.int]],
      [dartx.padLeft]: [core.String, [core.int], [core.String]],
      [dartx.padRight]: [core.String, [core.int], [core.String]],
      [dartx.indexOf]: [core.int, [core.Pattern], [core.int]],
      [dartx.lastIndexOf]: [core.int, [core.Pattern], [core.int]],
      [dartx.contains]: [core.bool, [core.Pattern], [core.int]],
      [dartx.compareTo]: [core.int, [core.String]],
      [dartx.get]: [core.String, [core.int]]
    }),
    statics: () => ({
      _isWhitespace: [core.bool, [core.int]],
      _skipLeadingWhitespace: [core.int, [core.String, core.int]],
      _skipTrailingWhitespace: [core.int, [core.String, core.int]]
    }),
    names: ['_isWhitespace', '_skipLeadingWhitespace', '_skipTrailingWhitespace']
  });
  JSString[dart.metadata] = () => [dart.const(new _js_helper.JsPeerInterface({name: 'String'}))];
  dart.registerExtension(dart.global.String, JSString);
  const _string = Symbol('_string');
  class _CodeUnits extends _internal.UnmodifiableListBase$(core.int) {
    _CodeUnits(string) {
      this[_string] = string;
    }
    get length() {
      return this[_string][dartx.length];
    }
    get(i) {
      return this[_string][dartx.codeUnitAt](i);
    }
  }
  dart.setSignature(_CodeUnits, {
    constructors: () => ({_CodeUnits: [_CodeUnits, [core.String]]}),
    methods: () => ({get: [core.int, [core.int]]})
  });
  dart.defineExtensionMembers(_CodeUnits, ['get', 'length']);
  function getInterceptor(obj) {
    return obj;
  }
  dart.fn(getInterceptor);
  dart.defineExtensionNames([
    'toString',
    'hashCode',
    'runtimeType'
  ]);
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
  JSBool[dart.metadata] = () => [dart.const(new _js_helper.JsPeerInterface({name: 'Boolean'}))];
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
  exports.JSString = JSString;
  exports.getInterceptor = getInterceptor;
  exports.JSBool = JSBool;
  exports.JSIndexable = JSIndexable;
  exports.JSMutableIndexable = JSMutableIndexable;
  exports.JSObject = JSObject;
  exports.JavaScriptObject = JavaScriptObject;
  exports.PlainJavaScriptObject = PlainJavaScriptObject;
  exports.UnknownJavaScriptObject = UnknownJavaScriptObject;
});
