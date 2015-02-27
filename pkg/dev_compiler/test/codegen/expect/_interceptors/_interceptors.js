var _interceptors;
(function(_interceptors) {
  'use strict';
  // Function _symbolToString: (Symbol) → String
  function _symbolToString(symbol) {
    return _internal.Symbol.getName(dart.as(symbol, _internal.Symbol));
  }
  // Function _symbolMapToStringMap: (Map<Symbol, dynamic>) → dynamic
  function _symbolMapToStringMap(map) {
    if (map === null)
      return null;
    let result = new core.Map();
    map.forEach((key, value) => {
      result.set(_symbolToString(key), value);
    });
    return result;
  }
  // Function getInterceptor: (dynamic) → dynamic
  function getInterceptor(object) {
    return _foreign_helper.JS('', 'void 0');
  }
  // Function getDispatchProperty: (dynamic) → dynamic
  function getDispatchProperty(object) {
    return _foreign_helper.JS('', '#[#]', object, _foreign_helper.JS_EMBEDDED_GLOBAL('String', dart.as(_js_embedded_names.DISPATCH_PROPERTY_NAME, core.String)));
  }
  // Function setDispatchProperty: (dynamic, dynamic) → dynamic
  function setDispatchProperty(object, value) {
    _js_helper.defineProperty(object, dart.as(_foreign_helper.JS_EMBEDDED_GLOBAL('String', dart.as(_js_embedded_names.DISPATCH_PROPERTY_NAME, core.String)), core.String), value);
  }
  // Function makeDispatchRecord: (dynamic, dynamic, dynamic, dynamic) → dynamic
  function makeDispatchRecord(interceptor, proto, extension, indexability) {
    return _foreign_helper.JS('', '{i: #, p: #, e: #, x: #}', interceptor, proto, extension, indexability);
  }
  // Function dispatchRecordInterceptor: (dynamic) → dynamic
  function dispatchRecordInterceptor(record) {
    return _foreign_helper.JS('', '#.i', record);
  }
  // Function dispatchRecordProto: (dynamic) → dynamic
  function dispatchRecordProto(record) {
    return _foreign_helper.JS('', '#.p', record);
  }
  // Function dispatchRecordExtension: (dynamic) → dynamic
  function dispatchRecordExtension(record) {
    return _foreign_helper.JS('', '#.e', record);
  }
  // Function dispatchRecordIndexability: (dynamic) → dynamic
  function dispatchRecordIndexability(record) {
    return _foreign_helper.JS('bool|Null', '#.x', record);
  }
  // Function getNativeInterceptor: (dynamic) → dynamic
  function getNativeInterceptor(object) {
    let record = getDispatchProperty(object);
    if (record === null) {
      if (_js_helper.initNativeDispatchFlag === null) {
        _js_helper.initNativeDispatch();
        record = getDispatchProperty(object);
      }
    }
    if (record !== null) {
      let proto = dispatchRecordProto(record);
      if (false === proto)
        return dispatchRecordInterceptor(record);
      if (true === proto)
        return object;
      let objectProto = _foreign_helper.JS('', 'Object.getPrototypeOf(#)', object);
      if (_foreign_helper.JS('bool', '# === #', proto, objectProto)) {
        return dispatchRecordInterceptor(record);
      }
      let extension = dispatchRecordExtension(record);
      if (_foreign_helper.JS('bool', '# === #', extension, objectProto)) {
        let discriminatedTag = _foreign_helper.JS('', '(#)(#, #)', proto, object, record);
        throw new core.UnimplementedError(`Return interceptor for ${discriminatedTag}`);
      }
    }
    let interceptor = _js_helper.lookupAndCacheInterceptor(object);
    if (interceptor === null) {
      let proto = _foreign_helper.JS('', 'Object.getPrototypeOf(#)', object);
      if (_foreign_helper.JS('bool', '# == null || # === Object.prototype', proto, proto)) {
        return _foreign_helper.JS_INTERCEPTOR_CONSTANT(PlainJavaScriptObject);
      } else {
        return _foreign_helper.JS_INTERCEPTOR_CONSTANT(UnknownJavaScriptObject);
      }
    }
    return interceptor;
  }
  dart.copyProperties(_interceptors, {
    get mapTypeToInterceptor() {
      return _foreign_helper.JS_EMBEDDED_GLOBAL('', dart.as(_js_embedded_names.MAP_TYPE_TO_INTERCEPTOR, core.String));
    }
  });
  // Function findIndexForNativeSubclassType: (Type) → int
  function findIndexForNativeSubclassType(type) {
    if (_foreign_helper.JS('bool', '# == null', _interceptors.mapTypeToInterceptor))
      return dart.as(null, core.int);
    let map = dart.as(_foreign_helper.JS('JSFixedArray', '#', _interceptors.mapTypeToInterceptor), core.List);
    for (let i = 0; i + 1 < map.length; i = 3) {
      if (dart.equals(type, map.get(i))) {
        return i;
      }
    }
    return dart.as(null, core.int);
  }
  // Function findInterceptorConstructorForType: (Type) → dynamic
  function findInterceptorConstructorForType(type) {
    let index = findIndexForNativeSubclassType(type);
    if (index === null)
      return null;
    let map = dart.as(_foreign_helper.JS('JSFixedArray', '#', _interceptors.mapTypeToInterceptor), core.List);
    return map.get(index + 1);
  }
  // Function findConstructorForNativeSubclassType: (Type, String) → dynamic
  function findConstructorForNativeSubclassType(type, name) {
    let index = findIndexForNativeSubclassType(type);
    if (index === null)
      return null;
    let map = dart.as(_foreign_helper.JS('JSFixedArray', '#', _interceptors.mapTypeToInterceptor), core.List);
    let constructorMap = map.get(index + 2);
    let constructorFn = _foreign_helper.JS('', '#[#]', constructorMap, name);
    return constructorFn;
  }
  // Function findInterceptorForType: (Type) → dynamic
  function findInterceptorForType(type) {
    let constructor = findInterceptorConstructorForType(type);
    if (constructor === null)
      return null;
    return _foreign_helper.JS('', '#.prototype', constructor);
  }
  class Interceptor extends dart.Object {
    Interceptor() {
    }
    ['=='](other) {
      return core.identical(this, other);
    }
    get hashCode() {
      return _js_helper.Primitives.objectHashCode(this);
    }
    toString() {
      return _js_helper.Primitives.objectToString(this);
    }
    noSuchMethod(invocation) {
      throw new core.NoSuchMethodError(this, invocation.memberName, invocation.positionalArguments, invocation.namedArguments);
    }
    get runtimeType() {
      return _js_helper.getRuntimeType(this);
    }
  }
  class JSBool extends Interceptor {
    JSBool() {
      super.Interceptor();
    }
    toString() {
      return dart.as(_foreign_helper.JS('String', 'String(#)', this), core.String);
    }
    get hashCode() {
      return this ? 2 * 3 * 23 * 3761 : 269 * 811;
    }
    get runtimeType() {
      return core.bool;
    }
  }
  class JSNull extends Interceptor {
    JSNull() {
      super.Interceptor();
    }
    ['=='](other) {
      return core.identical(null, other);
    }
    toString() {
      return 'null';
    }
    get hashCode() {
      return 0;
    }
    get runtimeType() {
      return core.Null;
    }
    noSuchMethod(invocation) {
      return super.noSuchMethod(invocation);
    }
  }
  class JSIndexable extends dart.Object {
  }
  class JSMutableIndexable extends JSIndexable {
  }
  class JSObject extends dart.Object {
  }
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
  class PlainJavaScriptObject extends JavaScriptObject {
    PlainJavaScriptObject() {
      super.JavaScriptObject();
    }
  }
  class UnknownJavaScriptObject extends JavaScriptObject {
    UnknownJavaScriptObject() {
      super.JavaScriptObject();
    }
    toString() {
      return dart.as(_foreign_helper.JS('String', 'String(#)', this), core.String);
    }
  }
  let JSArray$ = dart.generic(function(E) {
    class JSArray extends Interceptor {
      JSArray() {
        super.Interceptor();
      }
      JSArray$fixed(length) {
        if (dart.notNull(!(typeof length == number)) || dart.notNull(length < 0)) {
          throw new core.ArgumentError(`Length must be a non-negative integer: ${length}`);
        }
        return new JSArray.markFixed(_foreign_helper.JS('', 'new Array(#)', length));
      }
      JSArray$emptyGrowable() {
        return new JSArray.markGrowable(_foreign_helper.JS('', '[]'));
      }
      JSArray$growable(length) {
        if (dart.notNull(!(typeof length == number)) || dart.notNull(length < 0)) {
          throw new core.ArgumentError(`Length must be a non-negative integer: ${length}`);
        }
        return new JSArray.markGrowable(_foreign_helper.JS('', 'new Array(#)', length));
      }
      JSArray$typed(allocation) {
        return dart.as(_foreign_helper.JS('JSArray', '#', allocation), JSArray$(E));
      }
      JSArray$markFixed(allocation) {
        return dart.as(_foreign_helper.JS('JSFixedArray', '#', markFixedList(new JSArray.typed(allocation))), JSArray$(E));
      }
      JSArray$markGrowable(allocation) {
        return dart.as(_foreign_helper.JS('JSExtendableArray', '#', new JSArray.typed(allocation)), JSArray$(E));
      }
      static markFixedList(list) {
        _foreign_helper.JS('void', '#.fixed$length = Array', list);
        return dart.as(_foreign_helper.JS('JSFixedArray', '#', list), core.List);
      }
      checkMutable(reason) {
        if (!dart.is(this, JSMutableArray)) {
          throw new core.UnsupportedError(dart.as(reason, core.String));
        }
      }
      checkGrowable(reason) {
        if (!dart.is(this, JSExtendableArray)) {
          throw new core.UnsupportedError(dart.as(reason, core.String));
        }
      }
      add(value) {
        this.checkGrowable('add');
        _foreign_helper.JS('void', '#.push(#)', this, value);
      }
      removeAt(index) {
        if (!(typeof index == number))
          throw new core.ArgumentError(index);
        if (dart.notNull(index < 0) || dart.notNull(index >= this.length)) {
          throw new core.RangeError.value(index);
        }
        this.checkGrowable('removeAt');
        return dart.as(_foreign_helper.JS('var', '#.splice(#, 1)[0]', this, index), E);
      }
      insert(index, value) {
        if (!(typeof index == number))
          throw new core.ArgumentError(index);
        if (dart.notNull(index < 0) || dart.notNull(index > this.length)) {
          throw new core.RangeError.value(index);
        }
        this.checkGrowable('insert');
        _foreign_helper.JS('void', '#.splice(#, 0, #)', this, index, value);
      }
      insertAll(index, iterable) {
        this.checkGrowable('insertAll');
        _internal.IterableMixinWorkaround.insertAllList(this, index, iterable);
      }
      setAll(index, iterable) {
        this.checkMutable('setAll');
        _internal.IterableMixinWorkaround.setAllList(this, index, iterable);
      }
      removeLast() {
        this.checkGrowable('removeLast');
        if (this.length === 0)
          throw new core.RangeError.value(-1);
        return dart.as(_foreign_helper.JS('var', '#.pop()', this), E);
      }
      remove(element) {
        this.checkGrowable('remove');
        for (let i = 0; i < this.length; i++) {
          if (dart.equals(this.get(i), element)) {
            _foreign_helper.JS('var', '#.splice(#, 1)', this, i);
            return true;
          }
        }
        return false;
      }
      removeWhere(test) {
        _internal.IterableMixinWorkaround.removeWhereList(this, dart.as(test, dart.throw_("Unimplemented type (dynamic) → bool")));
      }
      retainWhere(test) {
        _internal.IterableMixinWorkaround.removeWhereList(this, dart.as((element) => !dart.notNull(test(element)), dart.throw_("Unimplemented type (dynamic) → bool")));
      }
      where(f) {
        return new _internal.IterableMixinWorkaround().where(this, dart.as(f, dart.throw_("Unimplemented type (dynamic) → bool")));
      }
      expand(f) {
        return _internal.IterableMixinWorkaround.expand(this, dart.as(f, dart.throw_("Unimplemented type (dynamic) → Iterable<dynamic>")));
      }
      addAll(collection) {
        for (let e of collection) {
          this.add(e);
        }
      }
      clear() {
        this.length = 0;
      }
      forEach(f) {
        let length = this.length;
        for (let i = 0; i < length; i++) {
          f(dart.as(_foreign_helper.JS('', '#[#]', this, i), E));
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
      }
      map(f) {
        return _internal.IterableMixinWorkaround.mapList(this, dart.as(f, dart.throw_("Unimplemented type (dynamic) → dynamic")));
      }
      join(separator) {
        if (separator === void 0)
          separator = "";
        let list = new core.List(this.length);
        for (let i = 0; i < this.length; i++) {
          list.set(i, `${this.get(i)}`);
        }
        return dart.as(_foreign_helper.JS('String', "#.join(#)", list, separator), core.String);
      }
      take(n) {
        return new _internal.IterableMixinWorkaround().takeList(this, n);
      }
      takeWhile(test) {
        return new _internal.IterableMixinWorkaround().takeWhile(this, dart.as(test, dart.throw_("Unimplemented type (dynamic) → bool")));
      }
      skip(n) {
        return new _internal.IterableMixinWorkaround().skipList(this, n);
      }
      skipWhile(test) {
        return new _internal.IterableMixinWorkaround().skipWhile(this, dart.as(test, dart.throw_("Unimplemented type (dynamic) → bool")));
      }
      reduce(combine) {
        return dart.as(_internal.IterableMixinWorkaround.reduce(this, dart.as(combine, dart.throw_("Unimplemented type (dynamic, dynamic) → dynamic"))), E);
      }
      fold(initialValue, combine) {
        return _internal.IterableMixinWorkaround.fold(this, initialValue, dart.as(combine, dart.throw_("Unimplemented type (dynamic, dynamic) → dynamic")));
      }
      firstWhere(test, opt$) {
        let orElse = opt$.orElse === void 0 ? null : opt$.orElse;
        return dart.as(_internal.IterableMixinWorkaround.firstWhere(this, dart.as(test, dart.throw_("Unimplemented type (dynamic) → bool")), orElse), E);
      }
      lastWhere(test, opt$) {
        let orElse = opt$.orElse === void 0 ? null : opt$.orElse;
        return dart.as(_internal.IterableMixinWorkaround.lastWhereList(this, dart.as(test, dart.throw_("Unimplemented type (dynamic) → bool")), orElse), E);
      }
      singleWhere(test) {
        return dart.as(_internal.IterableMixinWorkaround.singleWhere(this, dart.as(test, dart.throw_("Unimplemented type (dynamic) → bool"))), E);
      }
      elementAt(index) {
        return this.get(index);
      }
      sublist(start, end) {
        if (end === void 0)
          end = null;
        _js_helper.checkNull(start);
        if (!(typeof start == number))
          throw new core.ArgumentError(start);
        if (dart.notNull(start < 0) || dart.notNull(start > this.length)) {
          throw new core.RangeError.range(start, 0, this.length);
        }
        if (end === null) {
          end = this.length;
        } else {
          if (!(typeof end == number))
            throw new core.ArgumentError(end);
          if (dart.notNull(end < start) || dart.notNull(end > this.length)) {
            throw new core.RangeError.range(end, start, this.length);
          }
        }
        if (start === end)
          return new List.from([]);
        return new JSArray.markGrowable(_foreign_helper.JS('', '#.slice(#, #)', this, start, end));
      }
      getRange(start, end) {
        return new _internal.IterableMixinWorkaround().getRangeList(this, start, end);
      }
      get first() {
        if (this.length > 0)
          return this.get(0);
        throw new core.StateError("No elements");
      }
      get last() {
        if (this.length > 0)
          return this.get(this.length - 1);
        throw new core.StateError("No elements");
      }
      get single() {
        if (this.length === 1)
          return this.get(0);
        if (this.length === 0)
          throw new core.StateError("No elements");
        throw new core.StateError("More than one element");
      }
      removeRange(start, end) {
        this.checkGrowable('removeRange');
        let receiverLength = this.length;
        if (dart.notNull(start < 0) || dart.notNull(start > receiverLength)) {
          throw new core.RangeError.range(start, 0, receiverLength);
        }
        if (dart.notNull(end < start) || dart.notNull(end > receiverLength)) {
          throw new core.RangeError.range(end, start, receiverLength);
        }
        _internal.Lists.copy(this, end, this, start, receiverLength - end);
        this.length = receiverLength - (end - start);
      }
      setRange(start, end, iterable, skipCount) {
        if (skipCount === void 0)
          skipCount = 0;
        this.checkMutable('set range');
        _internal.IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
      }
      fillRange(start, end, fillValue) {
        if (fillValue === void 0)
          fillValue = null;
        this.checkMutable('fill range');
        _internal.IterableMixinWorkaround.fillRangeList(this, start, end, fillValue);
      }
      replaceRange(start, end, iterable) {
        this.checkGrowable('removeRange');
        _internal.IterableMixinWorkaround.replaceRangeList(this, start, end, iterable);
      }
      any(f) {
        return _internal.IterableMixinWorkaround.any(this, dart.as(f, dart.throw_("Unimplemented type (dynamic) → bool")));
      }
      every(f) {
        return _internal.IterableMixinWorkaround.every(this, dart.as(f, dart.throw_("Unimplemented type (dynamic) → bool")));
      }
      get reversed() {
        return new _internal.IterableMixinWorkaround().reversedList(this);
      }
      sort(compare) {
        if (compare === void 0)
          compare = null;
        this.checkMutable('sort');
        _internal.IterableMixinWorkaround.sortList(this, dart.as(compare, dart.throw_("Unimplemented type (dynamic, dynamic) → int")));
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
        for (let i = 0; i < this.length; i++) {
          if (dart.equals(this.get(i), other))
            return true;
        }
        return false;
      }
      get isEmpty() {
        return this.length === 0;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      toString() {
        return collection.ListBase.listToString(this);
      }
      toList(opt$) {
        let growable = opt$.growable === void 0 ? true : opt$.growable;
        if (growable) {
          return new JSArray.markGrowable(_foreign_helper.JS('', '#.slice()', this));
        } else {
          return new JSArray.markFixed(_foreign_helper.JS('', '#.slice()', this));
        }
      }
      toSet() {
        return new core.Set.from(this);
      }
      get iterator() {
        return new _internal.ListIterator(this);
      }
      get hashCode() {
        return _js_helper.Primitives.objectHashCode(this);
      }
      get length() {
        return dart.as(_foreign_helper.JS('JSUInt32', '#.length', this), core.int);
      }
      set length(newLength) {
        if (!(typeof newLength == number))
          throw new core.ArgumentError(newLength);
        if (newLength < 0)
          throw new core.RangeError.value(newLength);
        this.checkGrowable('set length');
        _foreign_helper.JS('void', '#.length = #', this, newLength);
      }
      get(index) {
        if (!(typeof index == number))
          throw new core.ArgumentError(index);
        if (dart.notNull(index >= this.length) || dart.notNull(index < 0))
          throw new core.RangeError.value(index);
        return dart.as(_foreign_helper.JS('var', '#[#]', this, index), E);
      }
      set(index, value) {
        this.checkMutable('indexed set');
        if (!(typeof index == number))
          throw new core.ArgumentError(index);
        if (dart.notNull(index >= this.length) || dart.notNull(index < 0))
          throw new core.RangeError.value(index);
        _foreign_helper.JS('void', '#[#] = #', this, index, value);
      }
      asMap() {
        return new _internal.IterableMixinWorkaround().asMapList(this);
      }
    }
    dart.defineNamedConstructor(JSArray, 'fixed');
    dart.defineNamedConstructor(JSArray, 'emptyGrowable');
    dart.defineNamedConstructor(JSArray, 'growable');
    dart.defineNamedConstructor(JSArray, 'typed');
    dart.defineNamedConstructor(JSArray, 'markFixed');
    dart.defineNamedConstructor(JSArray, 'markGrowable');
    return JSArray;
  });
  let JSArray = JSArray$(dynamic);
  let JSMutableArray$ = dart.generic(function(E) {
    class JSMutableArray extends JSArray$(E) {
    }
    return JSMutableArray;
  });
  let JSMutableArray = JSMutableArray$(dynamic);
  let JSFixedArray$ = dart.generic(function(E) {
    class JSFixedArray extends JSMutableArray$(E) {
    }
    return JSFixedArray;
  });
  let JSFixedArray = JSFixedArray$(dynamic);
  let JSExtendableArray$ = dart.generic(function(E) {
    class JSExtendableArray extends JSMutableArray$(E) {
    }
    return JSExtendableArray;
  });
  let JSExtendableArray = JSExtendableArray$(dynamic);
  class JSNumber extends Interceptor {
    JSNumber() {
      super.Interceptor();
    }
    compareTo(b) {
      if (!dart.is(b, core.num))
        throw new core.ArgumentError(b);
      if (this['<'](b)) {
        return -1;
      } else if (this['>'](b)) {
        return 1;
      } else if (dart.equals(this, b)) {
        if (dart.equals(this, 0)) {
          let bIsNegative = b.isNegative;
          if (this.isNegative === bIsNegative)
            return 0;
          if (this.isNegative)
            return -1;
          return 1;
        }
        return 0;
      } else if (this.isNaN) {
        if (b.isNaN) {
          return 0;
        }
        return 1;
      } else {
        return -1;
      }
    }
    get isNegative() {
      return dart.equals(this, 0) ? 1['/'](this) < 0 : this['<'](0);
    }
    get isNaN() {
      return dart.as(_foreign_helper.JS('bool', 'isNaN(#)', this), core.bool);
    }
    get isInfinite() {
      return dart.dbinary(_foreign_helper.JS('bool', '# == Infinity', this), '||', _foreign_helper.JS('bool', '# == -Infinity', this));
    }
    get isFinite() {
      return dart.as(_foreign_helper.JS('bool', 'isFinite(#)', this), core.bool);
    }
    remainder(b) {
      _js_helper.checkNull(b);
      if (!dart.is(b, core.num))
        throw new core.ArgumentError(b);
      return dart.as(_foreign_helper.JS('num', '# % #', this, b), core.num);
    }
    abs() {
      return dart.as(_foreign_helper.JS('num', 'Math.abs(#)', this), core.num);
    }
    get sign() {
      return this['>'](0) ? 1 : this['<'](0) ? -1 : this;
    }
    toInt() {
      if (dart.notNull(this['>='](_MIN_INT32)) && dart.notNull(this['<='](_MAX_INT32))) {
        return dart.as(_foreign_helper.JS('int', '# | 0', this), core.int);
      }
      if (_foreign_helper.JS('bool', 'isFinite(#)', this)) {
        return dart.as(_foreign_helper.JS('int', '# + 0', this.truncateToDouble()), core.int);
      }
      throw new core.UnsupportedError(dart.as(_foreign_helper.JS("String", "''+#", this), core.String));
    }
    truncate() {
      return this.toInt();
    }
    ceil() {
      return this.ceilToDouble().toInt();
    }
    floor() {
      return this.floorToDouble().toInt();
    }
    round() {
      return this.roundToDouble().toInt();
    }
    ceilToDouble() {
      return dart.as(_foreign_helper.JS('num', 'Math.ceil(#)', this), core.double);
    }
    floorToDouble() {
      return dart.as(_foreign_helper.JS('num', 'Math.floor(#)', this), core.double);
    }
    roundToDouble() {
      if (this['<'](0)) {
        return dart.as(_foreign_helper.JS('num', '-Math.round(-#)', this), core.double);
      } else {
        return dart.as(_foreign_helper.JS('num', 'Math.round(#)', this), core.double);
      }
    }
    truncateToDouble() {
      return this['<'](0) ? this.ceilToDouble() : this.floorToDouble();
    }
    clamp(lowerLimit, upperLimit) {
      if (!dart.is(lowerLimit, core.num))
        throw new core.ArgumentError(lowerLimit);
      if (!dart.is(upperLimit, core.num))
        throw new core.ArgumentError(upperLimit);
      if (dart.dbinary(dart.dinvoke(lowerLimit, 'compareTo', upperLimit), '>', 0)) {
        throw new core.ArgumentError(lowerLimit);
      }
      if (this.compareTo(dart.as(lowerLimit, core.num)) < 0)
        return dart.as(lowerLimit, core.num);
      if (this.compareTo(dart.as(upperLimit, core.num)) > 0)
        return dart.as(upperLimit, core.num);
      return this;
    }
    toDouble() {
      return this;
    }
    toStringAsFixed(fractionDigits) {
      _js_helper.checkInt(fractionDigits);
      if (dart.notNull(fractionDigits < 0) || dart.notNull(fractionDigits > 20)) {
        throw new core.RangeError(fractionDigits);
      }
      let result = dart.as(_foreign_helper.JS('String', '#.toFixed(#)', this, fractionDigits), core.String);
      if (dart.notNull(dart.equals(this, 0)) && dart.notNull(this.isNegative))
        return `-${result}`;
      return result;
    }
    toStringAsExponential(fractionDigits) {
      if (fractionDigits === void 0)
        fractionDigits = null;
      let result = null;
      if (fractionDigits !== null) {
        _js_helper.checkInt(fractionDigits);
        if (dart.notNull(fractionDigits < 0) || dart.notNull(fractionDigits > 20)) {
          throw new core.RangeError(fractionDigits);
        }
        result = dart.as(_foreign_helper.JS('String', '#.toExponential(#)', this, fractionDigits), core.String);
      } else {
        result = dart.as(_foreign_helper.JS('String', '#.toExponential()', this), core.String);
      }
      if (dart.notNull(dart.equals(this, 0)) && dart.notNull(this.isNegative))
        return `-${result}`;
      return result;
    }
    toStringAsPrecision(precision) {
      _js_helper.checkInt(precision);
      if (dart.notNull(precision < 1) || dart.notNull(precision > 21)) {
        throw new core.RangeError(precision);
      }
      let result = dart.as(_foreign_helper.JS('String', '#.toPrecision(#)', this, precision), core.String);
      if (dart.notNull(dart.equals(this, 0)) && dart.notNull(this.isNegative))
        return `-${result}`;
      return result;
    }
    toRadixString(radix) {
      _js_helper.checkInt(radix);
      if (dart.notNull(radix < 2) || dart.notNull(radix > 36))
        throw new core.RangeError(radix);
      let result = dart.as(_foreign_helper.JS('String', '#.toString(#)', this, radix), core.String);
      let rightParenCode = 41;
      if (result.codeUnitAt(result.length - 1) !== rightParenCode) {
        return result;
      }
      return _handleIEtoString(result);
    }
    static _handleIEtoString(result) {
      let match = _foreign_helper.JS('List|Null', '/^([\\da-z]+)(?:\\.([\\da-z]+))?\\(e\\+(\\d+)\\)$/.exec(#)', result);
      if (match === null) {
        throw new core.UnsupportedError(`Unexpected toString result: ${result}`);
      }
      let result = dart.as(_foreign_helper.JS('String', '#', dart.dindex(match, 1)), core.String);
      let exponent = dart.as(_foreign_helper.JS("int", "+#", dart.dindex(match, 3)), core.int);
      if (dart.dindex(match, 2) !== null) {
        result = dart.as(_foreign_helper.JS('String', '# + #', result, dart.dindex(match, 2)), core.String);
        exponent = dart.as(_foreign_helper.JS('int', '#.length', dart.dindex(match, 2)), core.int);
      }
      return core.String['+'](result, core.String['*']("0", exponent));
    }
    toString() {
      if (core.bool['&&'](dart.equals(this, 0), _foreign_helper.JS('bool', '(1 / #) < 0', this))) {
        return '-0.0';
      } else {
        return dart.as(_foreign_helper.JS('String', '"" + (#)', this), core.String);
      }
    }
    get hashCode() {
      return dart.as(_foreign_helper.JS('int', '# & 0x1FFFFFFF', this), core.int);
    }
    ['-']() {
      return dart.as(_foreign_helper.JS('num', '-#', this), core.num);
    }
    ['+'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('num', '# + #', this, other), core.num);
    }
    ['-'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('num', '# - #', this, other), core.num);
    }
    ['/'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('num', '# / #', this, other), core.num);
    }
    ['*'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('num', '# * #', this, other), core.num);
    }
    ['%'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      let result = dart.as(_foreign_helper.JS('num', '# % #', this, other), core.num);
      if (result === 0)
        return 0;
      if (dart.notNull(result) > 0)
        return result;
      if (dart.dbinary(_foreign_helper.JS('num', '#', other), '<', 0)) {
        return core.num['-'](result, _foreign_helper.JS('num', '#', other));
      } else {
        return core.num['+'](result, _foreign_helper.JS('num', '#', other));
      }
    }
    _isInt32(value) {
      return dart.as(_foreign_helper.JS('bool', '(# | 0) === #', value, value), core.bool);
    }
    ['~/'](other) {
      if (false)
        this._tdivFast(other);
      if (dart.notNull(dart.notNull(dart.notNull(this._isInt32(this)) && dart.notNull(this._isInt32(other))) && dart.notNull(0 !== other)) && dart.notNull(-1 !== other)) {
        return dart.as(_foreign_helper.JS('int', '(# / #) | 0', this, other), core.int);
      } else {
        return this._tdivSlow(other);
      }
    }
    _tdivFast(other) {
      return dart.as(this._isInt32(this) ? _foreign_helper.JS('int', '(# / #) | 0', this, other) : dart.dinvoke(_foreign_helper.JS('num', '# / #', this, other), 'toInt'), core.int);
    }
    _tdivSlow(other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(dart.dinvoke(_foreign_helper.JS('num', '# / #', this, other), 'toInt'), core.int);
    }
    ['<<'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      if (dart.dbinary(_foreign_helper.JS('num', '#', other), '<', 0))
        throw new core.ArgumentError(other);
      return this._shlPositive(other);
    }
    _shlPositive(other) {
      return dart.as(_foreign_helper.JS('bool', '# > 31', other) ? 0 : _foreign_helper.JS('JSUInt32', '(# << #) >>> 0', this, other), core.num);
    }
    ['>>'](other) {
      if (false)
        this._shrReceiverPositive(other);
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      if (dart.dbinary(_foreign_helper.JS('num', '#', other), '<', 0))
        throw new core.ArgumentError(other);
      return this._shrOtherPositive(other);
    }
    _shrOtherPositive(other) {
      return dart.as(dart.dbinary(_foreign_helper.JS('num', '#', this), '>', 0) ? this._shrBothPositive(other) : _foreign_helper.JS('JSUInt32', '(# >> #) >>> 0', this, dart.notNull(other) > 31 ? 31 : other), core.num);
    }
    _shrReceiverPositive(other) {
      if (dart.dbinary(_foreign_helper.JS('num', '#', other), '<', 0))
        throw new core.ArgumentError(other);
      return this._shrBothPositive(other);
    }
    _shrBothPositive(other) {
      return dart.as(_foreign_helper.JS('bool', '# > 31', other) ? 0 : _foreign_helper.JS('JSUInt32', '# >>> #', this, other), core.num);
    }
    ['&'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('JSUInt32', '(# & #) >>> 0', this, other), core.num);
    }
    ['|'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('JSUInt32', '(# | #) >>> 0', this, other), core.num);
    }
    ['^'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('JSUInt32', '(# ^ #) >>> 0', this, other), core.num);
    }
    ['<'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('bool', '# < #', this, other), core.bool);
    }
    ['>'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('bool', '# > #', this, other), core.bool);
    }
    ['<='](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('bool', '# <= #', this, other), core.bool);
    }
    ['>='](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('bool', '# >= #', this, other), core.bool);
    }
    get runtimeType() {
      return core.num;
    }
  }
  JSNumber._MIN_INT32 = -2147483648;
  JSNumber._MAX_INT32 = 2147483647;
  class JSInt extends JSNumber {
    JSInt() {
      super.JSNumber();
    }
    get isEven() {
      return this['&'](1) === 0;
    }
    get isOdd() {
      return this['&'](1) === 1;
    }
    toUnsigned(width) {
      return dart.notNull(this['&']((1 << width) - 1));
    }
    toSigned(width) {
      let signMask = 1 << width - 1;
      return dart.notNull(dart.notNull(this['&'](signMask - 1)) - dart.notNull(this['&'](signMask)));
    }
    get bitLength() {
      let nonneg = dart.notNull(this['<'](0) ? dart.notNull(dart.throw_("Unimplemented PrefixExpression: -this")) - 1 : this);
      if (nonneg >= 4294967296) {
        nonneg = (nonneg / 4294967296).truncate();
        return _bitCount(_spread(nonneg)) + 32;
      }
      return _bitCount(_spread(nonneg));
    }
    static _bitCount(i) {
      i = dart.as(dart.dbinary(_shru(i, 0), '-', dart.dbinary(_shru(i, 1), '&', 1431655765)), core.int);
      i = dart.notNull((i & 858993459)['+'](dart.dbinary(_shru(i, 2), '&', 858993459)));
      i = 252645135 & dart.notNull(i['+'](_shru(i, 4)));
      i = dart.as(_shru(i, 8), core.int);
      i = dart.as(_shru(i, 16), core.int);
      return i & 63;
    }
    static _shru(value, shift) {
      return _foreign_helper.JS('int', '# >>> #', value, shift);
    }
    static _shrs(value, shift) {
      return _foreign_helper.JS('int', '# >> #', value, shift);
    }
    static _ors(a, b) {
      return _foreign_helper.JS('int', '# | #', a, b);
    }
    static _spread(i) {
      i = dart.as(_ors(i, dart.as(_shrs(i, 1), core.int)), core.int);
      i = dart.as(_ors(i, dart.as(_shrs(i, 2), core.int)), core.int);
      i = dart.as(_ors(i, dart.as(_shrs(i, 4), core.int)), core.int);
      i = dart.as(_ors(i, dart.as(_shrs(i, 8), core.int)), core.int);
      i = dart.as(_shru(dart.as(_ors(i, dart.as(_shrs(i, 16), core.int)), core.int), 0), core.int);
      return i;
    }
    get runtimeType() {
      return core.int;
    }
    ['~']() {
      return dart.as(_foreign_helper.JS('JSUInt32', '(~#) >>> 0', this), core.int);
    }
  }
  class JSDouble extends JSNumber {
    JSDouble() {
      super.JSNumber();
    }
    get runtimeType() {
      return core.double;
    }
  }
  class JSPositiveInt extends JSInt {
  }
  class JSUInt32 extends JSPositiveInt {
  }
  class JSUInt31 extends JSUInt32 {
  }
  class JSString extends Interceptor {
    JSString() {
      super.Interceptor();
    }
    codeUnitAt(index) {
      if (!(typeof index == number))
        throw new core.ArgumentError(index);
      if (index < 0)
        throw new core.RangeError.value(index);
      if (index >= this.length)
        throw new core.RangeError.value(index);
      return dart.as(_foreign_helper.JS('JSUInt31', '#.charCodeAt(#)', this, index), core.int);
    }
    allMatches(string, start) {
      if (start === void 0)
        start = 0;
      _js_helper.checkString(string);
      _js_helper.checkInt(start);
      if (dart.notNull(0 > start) || dart.notNull(start > string.length)) {
        throw new core.RangeError.range(start, 0, string.length);
      }
      return _js_helper.allMatchesInStringUnchecked(this, string, start);
    }
    matchAsPrefix(string, start) {
      if (start === void 0)
        start = 0;
      if (dart.notNull(start < 0) || dart.notNull(start > string.length)) {
        throw new core.RangeError.range(start, 0, string.length);
      }
      if (start + this.length > string.length)
        return null;
      for (let i = 0; i < this.length; i++) {
        if (string.codeUnitAt(start + i) !== this.codeUnitAt(i)) {
          return null;
        }
      }
      return new _js_helper.StringMatch(start, string, this);
    }
    ['+'](other) {
      if (!(typeof other == string))
        throw new core.ArgumentError(other);
      return dart.as(_foreign_helper.JS('String', '# + #', this, other), core.String);
    }
    endsWith(other) {
      _js_helper.checkString(other);
      let otherLength = other.length;
      if (otherLength > this.length)
        return false;
      return dart.equals(other, this.substring(this.length - otherLength));
    }
    replaceAll(from, to) {
      _js_helper.checkString(to);
      return dart.as(_js_helper.stringReplaceAllUnchecked(this, from, to), core.String);
    }
    replaceAllMapped(from, convert) {
      return this.splitMapJoin(from, {onMatch: convert});
    }
    splitMapJoin(from, opt$) {
      let onMatch = opt$.onMatch === void 0 ? null : opt$.onMatch;
      let onNonMatch = opt$.onNonMatch === void 0 ? null : opt$.onNonMatch;
      return dart.as(_js_helper.stringReplaceAllFuncUnchecked(this, from, onMatch, onNonMatch), core.String);
    }
    replaceFirst(from, to, startIndex) {
      if (startIndex === void 0)
        startIndex = 0;
      _js_helper.checkString(to);
      _js_helper.checkInt(startIndex);
      if (dart.notNull(startIndex < 0) || dart.notNull(startIndex > this.length)) {
        throw new core.RangeError.range(startIndex, 0, this.length);
      }
      return dart.as(_js_helper.stringReplaceFirstUnchecked(this, from, to, startIndex), core.String);
    }
    split(pattern) {
      _js_helper.checkNull(pattern);
      if (typeof pattern == string) {
        return dart.as(_foreign_helper.JS('JSExtendableArray', '#.split(#)', this, pattern), core.List$(core.String));
      } else if (dart.notNull(dart.is(pattern, _js_helper.JSSyntaxRegExp)) && dart.notNull(_js_helper.regExpCaptureCount(pattern) === 0)) {
        let re = _js_helper.regExpGetNative(pattern);
        return dart.as(_foreign_helper.JS('JSExtendableArray', '#.split(#)', this, re), core.List$(core.String));
      } else {
        return this._defaultSplit(pattern);
      }
    }
    _defaultSplit(pattern) {
      let result = new List.from([]);
      let start = 0;
      let length = 1;
      for (let match of pattern.allMatches(this)) {
        let matchStart = dart.as(dart.dload(match, 'start'), core.int);
        let matchEnd = dart.as(dart.dload(match, 'end'), core.int);
        length = matchEnd - matchStart;
        if (dart.notNull(length === 0) && dart.notNull(start === matchStart)) {
          continue;
        }
        let end = matchStart;
        result.add(this.substring(start, end));
        start = matchEnd;
      }
      if (dart.notNull(start < this.length) || dart.notNull(length > 0)) {
        result.add(this.substring(start));
      }
      return result;
    }
    startsWith(pattern, index) {
      if (index === void 0)
        index = 0;
      _js_helper.checkInt(index);
      if (dart.notNull(index < 0) || dart.notNull(index > this.length)) {
        throw new core.RangeError.range(index, 0, this.length);
      }
      if (typeof pattern == string) {
        let other = pattern;
        let otherLength = other.length;
        let endIndex = index + otherLength;
        if (endIndex > this.length)
          return false;
        return dart.equals(other, _foreign_helper.JS('String', '#.substring(#, #)', this, index, endIndex));
      }
      return pattern.matchAsPrefix(this, index) !== null;
    }
    substring(startIndex, endIndex) {
      if (endIndex === void 0)
        endIndex = null;
      _js_helper.checkInt(startIndex);
      if (endIndex === null)
        endIndex = this.length;
      _js_helper.checkInt(endIndex);
      if (startIndex < 0)
        throw new core.RangeError.value(startIndex);
      if (startIndex > endIndex)
        throw new core.RangeError.value(startIndex);
      if (endIndex > this.length)
        throw new core.RangeError.value(endIndex);
      return dart.as(_foreign_helper.JS('String', '#.substring(#, #)', this, startIndex, endIndex), core.String);
    }
    toLowerCase() {
      return dart.as(_foreign_helper.JS('String', '#.toLowerCase()', this), core.String);
    }
    toUpperCase() {
      return dart.as(_foreign_helper.JS('String', '#.toUpperCase()', this), core.String);
    }
    static _isWhitespace(codeUnit) {
      if (codeUnit < 256) {
        switch (codeUnit) {
          case 9:
          case 10:
          case 11:
          case 12:
          case 13:
          case 32:
          case 133:
          case 160:
            return true;
          default:
            return false;
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
          return true;
        default:
          return false;
      }
    }
    static _skipLeadingWhitespace(string, index) {
      let SPACE = 32;
      let CARRIAGE_RETURN = 13;
      while (index < string.length) {
        let codeUnit = string.codeUnitAt(index);
        if (dart.notNull(dart.notNull(codeUnit !== SPACE) && dart.notNull(codeUnit !== CARRIAGE_RETURN)) && dart.notNull(!dart.notNull(_isWhitespace(codeUnit)))) {
          break;
        }
        index++;
      }
      return index;
    }
    static _skipTrailingWhitespace(string, index) {
      let SPACE = 32;
      let CARRIAGE_RETURN = 13;
      while (index > 0) {
        let codeUnit = string.codeUnitAt(index - 1);
        if (dart.notNull(dart.notNull(codeUnit !== SPACE) && dart.notNull(codeUnit !== CARRIAGE_RETURN)) && dart.notNull(!dart.notNull(_isWhitespace(codeUnit)))) {
          break;
        }
        index--;
      }
      return index;
    }
    trim() {
      let NEL = 133;
      let result = dart.as(_foreign_helper.JS('String', '#.trim()', this), core.String);
      if (result.length === 0)
        return result;
      let firstCode = result.codeUnitAt(0);
      let startIndex = 0;
      if (firstCode === NEL) {
        startIndex = _skipLeadingWhitespace(result, 1);
        if (startIndex === result.length)
          return "";
      }
      let endIndex = result.length;
      let lastCode = result.codeUnitAt(endIndex - 1);
      if (lastCode === NEL) {
        endIndex = _skipTrailingWhitespace(result, endIndex - 1);
      }
      if (dart.notNull(startIndex === 0) && dart.notNull(endIndex === result.length))
        return result;
      return dart.as(_foreign_helper.JS('String', '#.substring(#, #)', result, startIndex, endIndex), core.String);
    }
    trimLeft() {
      let NEL = 133;
      let result = null;
      let startIndex = 0;
      if (_foreign_helper.JS('bool', 'typeof #.trimLeft != "undefined"', this)) {
        result = dart.as(_foreign_helper.JS('String', '#.trimLeft()', this), core.String);
        if (result.length === 0)
          return result;
        let firstCode = result.codeUnitAt(0);
        if (firstCode === NEL) {
          startIndex = _skipLeadingWhitespace(result, 1);
        }
      } else {
        result = this;
        startIndex = _skipLeadingWhitespace(this, 0);
      }
      if (startIndex === 0)
        return result;
      if (startIndex === result.length)
        return "";
      return dart.as(_foreign_helper.JS('String', '#.substring(#)', result, startIndex), core.String);
    }
    trimRight() {
      let NEL = 133;
      let result = null;
      let endIndex = null;
      if (_foreign_helper.JS('bool', 'typeof #.trimRight != "undefined"', this)) {
        result = dart.as(_foreign_helper.JS('String', '#.trimRight()', this), core.String);
        endIndex = result.length;
        if (endIndex === 0)
          return result;
        let lastCode = result.codeUnitAt(endIndex - 1);
        if (lastCode === NEL) {
          endIndex = _skipTrailingWhitespace(result, endIndex - 1);
        }
      } else {
        result = this;
        endIndex = _skipTrailingWhitespace(this, this.length);
      }
      if (endIndex === result.length)
        return result;
      if (endIndex === 0)
        return "";
      return dart.as(_foreign_helper.JS('String', '#.substring(#, #)', result, 0, endIndex), core.String);
    }
    ['*'](times) {
      if (0 >= times)
        return '';
      if (dart.notNull(times === 1) || dart.notNull(this.length === 0))
        return this;
      if (times !== _foreign_helper.JS('JSUInt32', '# >>> 0', times)) {
        throw new core.OutOfMemoryError();
      }
      let result = '';
      let s = this;
      while (true) {
        if ((times & 1) === 1)
          result = s['+'](result);
        times = dart.as(_foreign_helper.JS('JSUInt31', '# >>> 1', times), core.int);
        if (times === 0)
          break;
        s = s;
      }
      return result;
    }
    padLeft(width, padding) {
      if (padding === void 0)
        padding = ' ';
      let delta = width - this.length;
      if (delta <= 0)
        return this;
      return core.String['+'](core.String['*'](padding, delta), this);
    }
    padRight(width, padding) {
      if (padding === void 0)
        padding = ' ';
      let delta = width - this.length;
      if (delta <= 0)
        return this;
      return this['+'](core.String['*'](padding, delta));
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
      if (!(typeof start == number))
        throw new core.ArgumentError(start);
      if (dart.notNull(start < 0) || dart.notNull(start > this.length)) {
        throw new core.RangeError.range(start, 0, this.length);
      }
      if (typeof pattern == string) {
        return dart.as(_foreign_helper.JS('int', '#.indexOf(#, #)', this, pattern, start), core.int);
      }
      if (dart.is(pattern, _js_helper.JSSyntaxRegExp)) {
        let re = pattern;
        let match = _js_helper.firstMatchAfter(re, this, start);
        return match === null ? -1 : match.start;
      }
      for (let i = start; i <= this.length; i++) {
        if (pattern.matchAsPrefix(this, i) !== null)
          return i;
      }
      return -1;
    }
    lastIndexOf(pattern, start) {
      if (start === void 0)
        start = null;
      _js_helper.checkNull(pattern);
      if (start === null) {
        start = this.length;
      } else if (!(typeof start == number)) {
        throw new core.ArgumentError(start);
      } else if (dart.notNull(start < 0) || dart.notNull(start > this.length)) {
        throw new core.RangeError.range(start, 0, this.length);
      }
      if (typeof pattern == string) {
        let other = pattern;
        if (start + other.length > this.length) {
          start = this.length - other.length;
        }
        return dart.as(_js_helper.stringLastIndexOfUnchecked(this, other, start), core.int);
      }
      for (let i = start; i >= 0; i--) {
        if (pattern.matchAsPrefix(this, i) !== null)
          return i;
      }
      return -1;
    }
    contains(other, startIndex) {
      if (startIndex === void 0)
        startIndex = 0;
      _js_helper.checkNull(other);
      if (dart.notNull(startIndex < 0) || dart.notNull(startIndex > this.length)) {
        throw new core.RangeError.range(startIndex, 0, this.length);
      }
      return dart.as(_js_helper.stringContainsUnchecked(this, other, startIndex), core.bool);
    }
    get isEmpty() {
      return this.length === 0;
    }
    get isNotEmpty() {
      return !dart.notNull(this.isEmpty);
    }
    compareTo(other) {
      if (!(typeof other == string))
        throw new core.ArgumentError(other);
      return dart.equals(this, other) ? 0 : _foreign_helper.JS('bool', '# < #', this, other) ? -1 : 1;
    }
    toString() {
      return this;
    }
    get hashCode() {
      let hash = 0;
      for (let i = 0; i < this.length; i++) {
        hash = 536870911 & dart.notNull(hash['+'](_foreign_helper.JS('int', '#.charCodeAt(#)', this, i)));
        hash = 536870911 & hash + ((524287 & hash) << 10);
        hash = dart.as(_foreign_helper.JS('int', '# ^ (# >> 6)', hash, hash), core.int);
      }
      hash = 536870911 & hash + ((67108863 & hash) << 3);
      hash = dart.as(_foreign_helper.JS('int', '# ^ (# >> 11)', hash, hash), core.int);
      return 536870911 & hash + ((16383 & hash) << 15);
    }
    get runtimeType() {
      return core.String;
    }
    get length() {
      return dart.as(_foreign_helper.JS('int', '#.length', this), core.int);
    }
    get(index) {
      if (!(typeof index == number))
        throw new core.ArgumentError(index);
      if (dart.notNull(index >= this.length) || dart.notNull(index < 0))
        throw new core.RangeError.value(index);
      return dart.as(_foreign_helper.JS('String', '#[#]', this, index), core.String);
    }
  }
  class _CodeUnits extends _internal.UnmodifiableListBase$(core.int) {
    _CodeUnits(_string) {
      this._string = _string;
      super.UnmodifiableListBase();
    }
    get length() {
      return this._string.length;
    }
    get(i) {
      return this._string.codeUnitAt(i);
    }
  }
  // Exports:
  _interceptors.getInterceptor = getInterceptor;
  _interceptors.getDispatchProperty = getDispatchProperty;
  _interceptors.setDispatchProperty = setDispatchProperty;
  _interceptors.makeDispatchRecord = makeDispatchRecord;
  _interceptors.dispatchRecordInterceptor = dispatchRecordInterceptor;
  _interceptors.dispatchRecordProto = dispatchRecordProto;
  _interceptors.dispatchRecordExtension = dispatchRecordExtension;
  _interceptors.dispatchRecordIndexability = dispatchRecordIndexability;
  _interceptors.getNativeInterceptor = getNativeInterceptor;
  _interceptors.mapTypeToInterceptor = mapTypeToInterceptor;
  _interceptors.findIndexForNativeSubclassType = findIndexForNativeSubclassType;
  _interceptors.findInterceptorConstructorForType = findInterceptorConstructorForType;
  _interceptors.findConstructorForNativeSubclassType = findConstructorForNativeSubclassType;
  _interceptors.findInterceptorForType = findInterceptorForType;
  _interceptors.Interceptor = Interceptor;
  _interceptors.JSBool = JSBool;
  _interceptors.JSNull = JSNull;
  _interceptors.JSIndexable = JSIndexable;
  _interceptors.JSMutableIndexable = JSMutableIndexable;
  _interceptors.JSObject = JSObject;
  _interceptors.JavaScriptObject = JavaScriptObject;
  _interceptors.PlainJavaScriptObject = PlainJavaScriptObject;
  _interceptors.UnknownJavaScriptObject = UnknownJavaScriptObject;
  _interceptors.JSArray = JSArray;
  _interceptors.JSArray$ = JSArray$;
  _interceptors.JSMutableArray = JSMutableArray;
  _interceptors.JSMutableArray$ = JSMutableArray$;
  _interceptors.JSFixedArray = JSFixedArray;
  _interceptors.JSFixedArray$ = JSFixedArray$;
  _interceptors.JSExtendableArray = JSExtendableArray;
  _interceptors.JSExtendableArray$ = JSExtendableArray$;
  _interceptors.JSNumber = JSNumber;
  _interceptors.JSInt = JSInt;
  _interceptors.JSDouble = JSDouble;
  _interceptors.JSPositiveInt = JSPositiveInt;
  _interceptors.JSUInt32 = JSUInt32;
  _interceptors.JSUInt31 = JSUInt31;
  _interceptors.JSString = JSString;
})(_interceptors || (_interceptors = {}));
