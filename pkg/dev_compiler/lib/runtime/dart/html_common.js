dart_library.library('dart/html_common', null, /* Imports */[
  'dart/_runtime',
  'dart/_metadata',
  'dart/core',
  'dart/html',
  'dart/typed_data',
  'dart/_js_helper',
  'dart/_native_typed_data',
  'dart/async',
  'dart/collection',
  'dart/_internal'
], /* Lazy imports */[
  'dart/web_gl'
], function(exports, dart, _metadata, core, html, typed_data, _js_helper, _native_typed_data, async, collection, _internal, web_gl) {
  'use strict';
  let dartx = dart.dartx;
  dart.export(exports, _metadata);
  const _validateToken = Symbol('_validateToken');
  class CssClassSetImpl extends core.Object {
    [_validateToken](value) {
      if (dart.notNull(CssClassSetImpl._validTokenRE.hasMatch(value))) return value;
      dart.throw(new core.ArgumentError.value(value, 'value', 'Not a valid class token'));
    }
    toString() {
      return this.readClasses().join(' ');
    }
    toggle(value, shouldAdd) {
      if (shouldAdd === void 0) shouldAdd = null;
      this[_validateToken](value);
      let s = this.readClasses();
      let result = false;
      if (shouldAdd == null) shouldAdd = !dart.notNull(s.contains(value));
      if (dart.notNull(shouldAdd)) {
        s.add(value);
        result = true;
      } else {
        s.remove(value);
      }
      this.writeClasses(s);
      return result;
    }
    get frozen() {
      return false;
    }
    get iterator() {
      return this.readClasses().iterator;
    }
    [Symbol.iterator]() {
      return new dart.JsIterator(this.iterator);
    }
    forEach(f) {
      this.readClasses().forEach(f);
    }
    join(separator) {
      if (separator === void 0) separator = "";
      return this.readClasses().join(separator);
    }
    map(f) {
      return this.readClasses().map(f);
    }
    where(f) {
      return this.readClasses().where(f);
    }
    expand(f) {
      return this.readClasses().expand(f);
    }
    every(f) {
      return this.readClasses().every(f);
    }
    any(f) {
      return this.readClasses().any(f);
    }
    get isEmpty() {
      return this.readClasses().isEmpty;
    }
    get isNotEmpty() {
      return this.readClasses().isNotEmpty;
    }
    get length() {
      return this.readClasses().length;
    }
    reduce(combine) {
      return this.readClasses().reduce(combine);
    }
    fold(initialValue, combine) {
      return this.readClasses().fold(initialValue, combine);
    }
    contains(value) {
      if (!(typeof value == 'string')) return false;
      this[_validateToken](dart.as(value, core.String));
      return this.readClasses().contains(value);
    }
    lookup(value) {
      return dart.as(dart.notNull(this.contains(value)) ? value : null, core.String);
    }
    add(value) {
      this[_validateToken](value);
      return dart.as(this.modify(dart.fn(s => s.add(value), core.bool, [core.Set$(core.String)])), core.bool);
    }
    remove(value) {
      this[_validateToken](dart.as(value, core.String));
      if (!(typeof value == 'string')) return false;
      let s = this.readClasses();
      let result = s.remove(value);
      this.writeClasses(s);
      return result;
    }
    addAll(iterable) {
      this.modify(dart.fn(s => s.addAll(iterable[dartx.map](dart.bind(this, _validateToken))), dart.void, [core.Set$(core.String)]));
    }
    removeAll(iterable) {
      this.modify(dart.fn(s => s.removeAll(iterable[dartx.map](dart.as(dart.bind(this, _validateToken), __CastType0))), dart.void, [core.Set$(core.String)]));
    }
    toggleAll(iterable, shouldAdd) {
      if (shouldAdd === void 0) shouldAdd = null;
      iterable[dartx.forEach](dart.fn(e => this.toggle(e, shouldAdd), core.bool, [core.String]));
    }
    retainAll(iterable) {
      this.modify(dart.fn(s => s.retainAll(iterable), dart.void, [core.Set$(core.String)]));
    }
    removeWhere(test) {
      this.modify(dart.fn(s => s.removeWhere(test), dart.void, [core.Set$(core.String)]));
    }
    retainWhere(test) {
      this.modify(dart.fn(s => s.retainWhere(test), dart.void, [core.Set$(core.String)]));
    }
    containsAll(collection) {
      return this.readClasses().containsAll(collection);
    }
    intersection(other) {
      return this.readClasses().intersection(other);
    }
    union(other) {
      return this.readClasses().union(other);
    }
    difference(other) {
      return this.readClasses().difference(other);
    }
    get first() {
      return this.readClasses().first;
    }
    get last() {
      return this.readClasses().last;
    }
    get single() {
      return this.readClasses().single;
    }
    toList(opts) {
      let growable = opts && 'growable' in opts ? opts.growable : true;
      return this.readClasses().toList({growable: growable});
    }
    toSet() {
      return this.readClasses().toSet();
    }
    take(n) {
      return this.readClasses().take(n);
    }
    takeWhile(test) {
      return this.readClasses().takeWhile(test);
    }
    skip(n) {
      return this.readClasses().skip(n);
    }
    skipWhile(test) {
      return this.readClasses().skipWhile(test);
    }
    firstWhere(test, opts) {
      let orElse = opts && 'orElse' in opts ? opts.orElse : null;
      return this.readClasses().firstWhere(test, {orElse: orElse});
    }
    lastWhere(test, opts) {
      let orElse = opts && 'orElse' in opts ? opts.orElse : null;
      return this.readClasses().lastWhere(test, {orElse: orElse});
    }
    singleWhere(test) {
      return this.readClasses().singleWhere(test);
    }
    elementAt(index) {
      return this.readClasses().elementAt(index);
    }
    clear() {
      this.modify(dart.fn(s => s.clear(), dart.void, [core.Set$(core.String)]));
    }
    modify(f) {
      let s = this.readClasses();
      let ret = f(s);
      this.writeClasses(s);
      return ret;
    }
  }
  CssClassSetImpl[dart.implements] = () => [html.CssClassSet];
  dart.setSignature(CssClassSetImpl, {
    methods: () => ({
      [_validateToken]: [core.String, [core.String]],
      toggle: [core.bool, [core.String], [core.bool]],
      forEach: [dart.void, [dart.functionType(dart.void, [core.String])]],
      join: [core.String, [], [core.String]],
      map: [core.Iterable, [dart.functionType(dart.dynamic, [core.String])]],
      where: [core.Iterable$(core.String), [dart.functionType(core.bool, [core.String])]],
      expand: [core.Iterable, [dart.functionType(core.Iterable, [core.String])]],
      every: [core.bool, [dart.functionType(core.bool, [core.String])]],
      any: [core.bool, [dart.functionType(core.bool, [core.String])]],
      reduce: [core.String, [dart.functionType(core.String, [core.String, core.String])]],
      fold: [dart.dynamic, [dart.dynamic, dart.functionType(dart.dynamic, [dart.dynamic, core.String])]],
      contains: [core.bool, [core.Object]],
      lookup: [core.String, [core.Object]],
      add: [core.bool, [core.String]],
      remove: [core.bool, [core.Object]],
      addAll: [dart.void, [core.Iterable$(core.String)]],
      removeAll: [dart.void, [core.Iterable$(core.Object)]],
      toggleAll: [dart.void, [core.Iterable$(core.String)], [core.bool]],
      retainAll: [dart.void, [core.Iterable$(core.Object)]],
      removeWhere: [dart.void, [dart.functionType(core.bool, [core.String])]],
      retainWhere: [dart.void, [dart.functionType(core.bool, [core.String])]],
      containsAll: [core.bool, [core.Iterable$(core.Object)]],
      intersection: [core.Set$(core.String), [core.Set$(core.Object)]],
      union: [core.Set$(core.String), [core.Set$(core.String)]],
      difference: [core.Set$(core.String), [core.Set$(core.String)]],
      toList: [core.List$(core.String), [], {growable: core.bool}],
      toSet: [core.Set$(core.String), []],
      take: [core.Iterable$(core.String), [core.int]],
      takeWhile: [core.Iterable$(core.String), [dart.functionType(core.bool, [core.String])]],
      skip: [core.Iterable$(core.String), [core.int]],
      skipWhile: [core.Iterable$(core.String), [dart.functionType(core.bool, [core.String])]],
      firstWhere: [core.String, [dart.functionType(core.bool, [core.String])], {orElse: dart.functionType(core.String, [])}],
      lastWhere: [core.String, [dart.functionType(core.bool, [core.String])], {orElse: dart.functionType(core.String, [])}],
      singleWhere: [core.String, [dart.functionType(core.bool, [core.String])]],
      elementAt: [core.String, [core.int]],
      clear: [dart.void, []],
      modify: [dart.dynamic, [dart.functionType(dart.dynamic, [core.Set$(core.String)])]]
    })
  });
  dart.defineExtensionMembers(CssClassSetImpl, [
    'forEach',
    'join',
    'map',
    'where',
    'expand',
    'every',
    'any',
    'reduce',
    'fold',
    'contains',
    'toList',
    'toSet',
    'take',
    'takeWhile',
    'skip',
    'skipWhile',
    'firstWhere',
    'lastWhere',
    'singleWhere',
    'elementAt',
    'iterator',
    'isEmpty',
    'isNotEmpty',
    'length',
    'first',
    'last',
    'single'
  ]);
  dart.defineLazyProperties(CssClassSetImpl, {
    get _validTokenRE() {
      return core.RegExp.new('^\\S+$');
    }
  });
  const __CastType0 = dart.typedef('__CastType0', () => dart.functionType(core.String, [core.Object]));
  function convertDartToNative_SerializedScriptValue(value) {
    return convertDartToNative_PrepareForStructuredClone(value);
  }
  dart.fn(convertDartToNative_SerializedScriptValue);
  function convertNativeToDart_SerializedScriptValue(object) {
    return convertNativeToDart_AcceptStructuredClone(object, {mustCopy: true});
  }
  dart.fn(convertNativeToDart_SerializedScriptValue);
  class _StructuredClone extends core.Object {
    _StructuredClone() {
      this.values = [];
      this.copies = [];
    }
    findSlot(value) {
      let length = this.values[dartx.length];
      for (let i = 0; i < dart.notNull(length); i++) {
        if (dart.notNull(core.identical(this.values[dartx.get](i), value))) return i;
      }
      this.values[dartx.add](value);
      this.copies[dartx.add](null);
      return length;
    }
    readSlot(i) {
      return this.copies[dartx.get](i);
    }
    writeSlot(i, x) {
      this.copies[dartx.set](i, x);
    }
    cleanupSlots() {}
    walk(e) {
      if (e == null) return e;
      if (typeof e == 'boolean') return e;
      if (typeof e == 'number') return e;
      if (typeof e == 'string') return e;
      if (dart.is(e, core.DateTime)) {
        return convertDartToNative_DateTime(e);
      }
      if (dart.is(e, core.RegExp)) {
        dart.throw(new core.UnimplementedError('structured clone of RegExp'));
      }
      if (dart.is(e, html.File)) return e;
      if (dart.is(e, html.Blob)) return e;
      if (dart.is(e, html.FileList)) return e;
      if (dart.is(e, html.ImageData)) return e;
      if (dart.notNull(this.cloneNotRequired(e))) return e;
      if (dart.is(e, core.Map)) {
        let slot = this.findSlot(e);
        let copy = this.readSlot(slot);
        if (copy != null) return copy;
        copy = this.newJsMap();
        this.writeSlot(slot, copy);
        e[dartx.forEach](dart.fn((key, value) => {
          this.putIntoMap(copy, key, this.walk(value));
        }, dart.void, [dart.dynamic, dart.dynamic]));
        return copy;
      }
      if (dart.is(e, core.List)) {
        let slot = this.findSlot(e);
        let copy = this.readSlot(slot);
        if (copy != null) return copy;
        copy = this.copyList(e, slot);
        return copy;
      }
      dart.throw(new core.UnimplementedError('structured clone of other type'));
    }
    copyList(e, slot) {
      let i = 0;
      let length = e[dartx.length];
      let copy = this.newJsList(length);
      this.writeSlot(slot, copy);
      for (; i < dart.notNull(length); i++) {
        dart.dsetindex(copy, i, this.walk(e[dartx.get](i)));
      }
      return copy;
    }
    convertDartToNative_PrepareForStructuredClone(value) {
      let copy = this.walk(value);
      this.cleanupSlots();
      return copy;
    }
  }
  dart.setSignature(_StructuredClone, {
    methods: () => ({
      findSlot: [core.int, [dart.dynamic]],
      readSlot: [dart.dynamic, [core.int]],
      writeSlot: [dart.dynamic, [core.int, dart.dynamic]],
      cleanupSlots: [dart.dynamic, []],
      walk: [dart.dynamic, [dart.dynamic]],
      copyList: [dart.dynamic, [core.List, core.int]],
      convertDartToNative_PrepareForStructuredClone: [dart.dynamic, [dart.dynamic]]
    })
  });
  class _AcceptStructuredClone extends core.Object {
    _AcceptStructuredClone() {
      this.values = [];
      this.copies = [];
      this.mustCopy = false;
    }
    findSlot(value) {
      let length = this.values[dartx.length];
      for (let i = 0; i < dart.notNull(length); i++) {
        if (dart.notNull(this.identicalInJs(this.values[dartx.get](i), value))) return i;
      }
      this.values[dartx.add](value);
      this.copies[dartx.add](null);
      return length;
    }
    readSlot(i) {
      return this.copies[dartx.get](i);
    }
    writeSlot(i, x) {
      this.copies[dartx.set](i, x);
    }
    walk(e) {
      if (e == null) return e;
      if (typeof e == 'boolean') return e;
      if (typeof e == 'number') return e;
      if (typeof e == 'string') return e;
      if (dart.notNull(isJavaScriptDate(e))) {
        return convertNativeToDart_DateTime(e);
      }
      if (dart.notNull(isJavaScriptRegExp(e))) {
        dart.throw(new core.UnimplementedError('structured clone of RegExp'));
      }
      if (dart.notNull(isJavaScriptPromise(e))) {
        return convertNativePromiseToDartFuture(e);
      }
      if (dart.notNull(isJavaScriptSimpleObject(e))) {
        let slot = this.findSlot(e);
        let copy = this.readSlot(slot);
        if (copy != null) return copy;
        copy = dart.map();
        this.writeSlot(slot, copy);
        this.forEachJsField(e, dart.fn((key, value) => dart.dsetindex(copy, key, this.walk(value))));
        return copy;
      }
      if (dart.notNull(isJavaScriptArray(e))) {
        let slot = this.findSlot(e);
        let copy = this.readSlot(slot);
        if (copy != null) return copy;
        let length = dart.as(dart.dload(e, 'length'), core.int);
        copy = dart.notNull(this.mustCopy) ? this.newDartList(length) : e;
        this.writeSlot(slot, copy);
        for (let i = 0; i < dart.notNull(length); i++) {
          dart.dsetindex(copy, i, this.walk(dart.dindex(e, i)));
        }
        return copy;
      }
      return e;
    }
    convertNativeToDart_AcceptStructuredClone(object, opts) {
      let mustCopy = opts && 'mustCopy' in opts ? opts.mustCopy : false;
      this.mustCopy = dart.as(mustCopy, core.bool);
      let copy = this.walk(object);
      return copy;
    }
  }
  dart.setSignature(_AcceptStructuredClone, {
    methods: () => ({
      findSlot: [core.int, [dart.dynamic]],
      readSlot: [dart.dynamic, [core.int]],
      writeSlot: [dart.dynamic, [core.int, dart.dynamic]],
      walk: [dart.dynamic, [dart.dynamic]],
      convertNativeToDart_AcceptStructuredClone: [dart.dynamic, [dart.dynamic], {mustCopy: dart.dynamic}]
    })
  });
  class _TypedContextAttributes extends core.Object {
    _TypedContextAttributes(alpha, antialias, depth, failIfMajorPerformanceCaveat, premultipliedAlpha, preserveDrawingBuffer, stencil) {
      this.alpha = alpha;
      this.antialias = antialias;
      this.depth = depth;
      this.failIfMajorPerformanceCaveat = failIfMajorPerformanceCaveat;
      this.premultipliedAlpha = premultipliedAlpha;
      this.preserveDrawingBuffer = preserveDrawingBuffer;
      this.stencil = stencil;
    }
  }
  _TypedContextAttributes[dart.implements] = () => [web_gl.ContextAttributes];
  dart.setSignature(_TypedContextAttributes, {
    constructors: () => ({_TypedContextAttributes: [_TypedContextAttributes, [core.bool, core.bool, core.bool, core.bool, core.bool, core.bool, core.bool]]})
  });
  dart.defineExtensionMembers(_TypedContextAttributes, [
    'alpha',
    'alpha',
    'antialias',
    'antialias',
    'depth',
    'depth',
    'premultipliedAlpha',
    'premultipliedAlpha',
    'preserveDrawingBuffer',
    'preserveDrawingBuffer',
    'stencil',
    'stencil',
    'failIfMajorPerformanceCaveat',
    'failIfMajorPerformanceCaveat'
  ]);
  function convertNativeToDart_ContextAttributes(nativeContextAttributes) {
    if (dart.is(nativeContextAttributes, web_gl.ContextAttributes)) {
      return nativeContextAttributes;
    }
    return new _TypedContextAttributes(dart.as(nativeContextAttributes.alpha, core.bool), dart.as(nativeContextAttributes.antialias, core.bool), dart.as(nativeContextAttributes.depth, core.bool), dart.as(nativeContextAttributes.failIfMajorPerformanceCaveat, core.bool), dart.as(nativeContextAttributes.premultipliedAlpha, core.bool), dart.as(nativeContextAttributes.preserveDrawingBuffer, core.bool), dart.as(nativeContextAttributes.stencil, core.bool));
  }
  dart.fn(convertNativeToDart_ContextAttributes, () => dart.definiteFunctionType(web_gl.ContextAttributes, [dart.dynamic]));
  class _TypedImageData extends core.Object {
    _TypedImageData(data, height, width) {
      this.data = data;
      this.height = height;
      this.width = width;
    }
  }
  _TypedImageData[dart.implements] = () => [html.ImageData];
  dart.setSignature(_TypedImageData, {
    constructors: () => ({_TypedImageData: [_TypedImageData, [typed_data.Uint8ClampedList, core.int, core.int]]})
  });
  dart.defineExtensionMembers(_TypedImageData, ['data', 'height', 'width']);
  function convertNativeToDart_ImageData(nativeImageData) {
    0;
    if (dart.is(nativeImageData, html.ImageData)) {
      let data = nativeImageData[dartx.data];
      if (data.constructor === Array) {
        if (typeof CanvasPixelArray !== "undefined") {
          data.constructor = CanvasPixelArray;
          data.BYTES_PER_ELEMENT = 1;
        }
      }
      return nativeImageData;
    }
    return new _TypedImageData(dart.as(nativeImageData.data, typed_data.Uint8ClampedList), dart.as(nativeImageData.height, core.int), dart.as(nativeImageData.width, core.int));
  }
  dart.fn(convertNativeToDart_ImageData, html.ImageData, [dart.dynamic]);
  function convertDartToNative_ImageData(imageData) {
    if (dart.is(imageData, _TypedImageData)) {
      return {data: imageData.data, height: imageData.height, width: imageData.width};
    }
    return imageData;
  }
  dart.fn(convertDartToNative_ImageData, dart.dynamic, [html.ImageData]);
  const _serializedScriptValue = 'num|String|bool|' + 'JSExtendableArray|=Object|' + 'Blob|File|NativeByteBuffer|NativeTypedData';
  const annotation_Creates_SerializedScriptValue = dart.const(new _js_helper.Creates(_serializedScriptValue));
  const annotation_Returns_SerializedScriptValue = dart.const(new _js_helper.Returns(_serializedScriptValue));
  function convertNativeToDart_Dictionary(object) {
    if (object == null) return null;
    let dict = dart.map();
    let keys = Object.getOwnPropertyNames(object);
    for (let key of dart.as(keys, core.Iterable)) {
      dict[dartx.set](key, object[key]);
    }
    return dict;
  }
  dart.fn(convertNativeToDart_Dictionary, core.Map, [dart.dynamic]);
  function convertDartToNative_Dictionary(dict, postCreate) {
    if (postCreate === void 0) postCreate = null;
    if (dict == null) return null;
    let object = {};
    if (postCreate != null) {
      dart.dcall(postCreate, object);
    }
    dict[dartx.forEach](dart.fn((key, value) => {
      object[key] = value;
    }, dart.void, [core.String, dart.dynamic]));
    return object;
  }
  dart.fn(convertDartToNative_Dictionary, dart.dynamic, [core.Map], [dart.functionType(dart.void, [dart.dynamic])]);
  function convertDartToNative_StringArray(input) {
    return input;
  }
  dart.fn(convertDartToNative_StringArray, core.List, [core.List$(core.String)]);
  function convertNativeToDart_DateTime(date) {
    let millisSinceEpoch = date.getTime();
    return new core.DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch, {isUtc: true});
  }
  dart.fn(convertNativeToDart_DateTime, core.DateTime, [dart.dynamic]);
  function convertDartToNative_DateTime(date) {
    return new Date(date.millisecondsSinceEpoch);
  }
  dart.fn(convertDartToNative_DateTime, dart.dynamic, [core.DateTime]);
  function convertDartToNative_PrepareForStructuredClone(value) {
    return new _StructuredCloneDart2Js().convertDartToNative_PrepareForStructuredClone(value);
  }
  dart.fn(convertDartToNative_PrepareForStructuredClone);
  function convertNativeToDart_AcceptStructuredClone(object, opts) {
    let mustCopy = opts && 'mustCopy' in opts ? opts.mustCopy : false;
    return new _AcceptStructuredCloneDart2Js().convertNativeToDart_AcceptStructuredClone(object, {mustCopy: mustCopy});
  }
  dart.fn(convertNativeToDart_AcceptStructuredClone, dart.dynamic, [dart.dynamic], {mustCopy: dart.dynamic});
  class _StructuredCloneDart2Js extends _StructuredClone {
    _StructuredCloneDart2Js() {
      super._StructuredClone();
    }
    newJsMap() {
      return {};
    }
    putIntoMap(map, key, value) {
      return map[key] = value;
    }
    newJsList(length) {
      return new Array(length);
    }
    cloneNotRequired(e) {
      return dart.is(e, _native_typed_data.NativeByteBuffer) || dart.is(e, _native_typed_data.NativeTypedData);
    }
  }
  dart.setSignature(_StructuredCloneDart2Js, {
    methods: () => ({
      newJsMap: [dart.dynamic, []],
      putIntoMap: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]],
      newJsList: [dart.dynamic, [dart.dynamic]],
      cloneNotRequired: [core.bool, [dart.dynamic]]
    })
  });
  class _AcceptStructuredCloneDart2Js extends _AcceptStructuredClone {
    _AcceptStructuredCloneDart2Js() {
      super._AcceptStructuredClone();
    }
    newJsList(length) {
      return new Array(length);
    }
    newDartList(length) {
      return this.newJsList(length);
    }
    identicalInJs(a, b) {
      return core.identical(a, b);
    }
    forEachJsField(object, action) {
      for (let key of dart.as(Object.keys(object), core.Iterable)) {
        dart.dcall(action, key, object[key]);
      }
    }
  }
  dart.setSignature(_AcceptStructuredCloneDart2Js, {
    methods: () => ({
      newJsList: [dart.dynamic, [dart.dynamic]],
      newDartList: [dart.dynamic, [dart.dynamic]],
      identicalInJs: [core.bool, [dart.dynamic, dart.dynamic]],
      forEachJsField: [dart.void, [dart.dynamic, dart.dynamic]]
    })
  });
  function isJavaScriptDate(value) {
    return value instanceof Date;
  }
  dart.fn(isJavaScriptDate, core.bool, [dart.dynamic]);
  function isJavaScriptRegExp(value) {
    return value instanceof RegExp;
  }
  dart.fn(isJavaScriptRegExp, core.bool, [dart.dynamic]);
  function isJavaScriptArray(value) {
    return value instanceof Array;
  }
  dart.fn(isJavaScriptArray, core.bool, [dart.dynamic]);
  function isJavaScriptSimpleObject(value) {
    let proto = Object.getPrototypeOf(value);
    return proto === Object.prototype || proto === null;
  }
  dart.fn(isJavaScriptSimpleObject, core.bool, [dart.dynamic]);
  function isImmutableJavaScriptArray(value) {
    return !!value.immutable$list;
  }
  dart.fn(isImmutableJavaScriptArray, core.bool, [dart.dynamic]);
  function isJavaScriptPromise(value) {
    return typeof Promise != "undefined" && value instanceof Promise;
  }
  dart.fn(isJavaScriptPromise, core.bool, [dart.dynamic]);
  function convertNativePromiseToDartFuture(promise) {
    let completer = async.Completer.new();
    let then = dart.dcall(/* Unimplemented unknown name */convertDartClosureToJS, dart.fn(result => completer.complete(result), dart.void, [dart.dynamic]), 1);
    let error = dart.dcall(/* Unimplemented unknown name */convertDartClosureToJS, dart.fn(result => completer.completeError(result), dart.void, [dart.dynamic]), 1);
    let newPromise = promise.then(then).catch(error);
    return completer.future;
  }
  dart.fn(convertNativePromiseToDartFuture, async.Future, [dart.dynamic]);
  function wrap_jso(jsObject) {
    return jsObject;
  }
  dart.fn(wrap_jso);
  function unwrap_jso(dartClass_instance) {
    return dartClass_instance;
  }
  dart.fn(unwrap_jso);
  class Device extends core.Object {
    static get userAgent() {
      return html.window[dartx.navigator][dartx.userAgent];
    }
    static get isOpera() {
      if (Device._isOpera == null) {
        Device._isOpera = Device.userAgent[dartx.contains]("Opera", 0);
      }
      return Device._isOpera;
    }
    static get isIE() {
      if (Device._isIE == null) {
        Device._isIE = !dart.notNull(Device.isOpera) && dart.notNull(Device.userAgent[dartx.contains]("Trident/", 0));
      }
      return Device._isIE;
    }
    static get isFirefox() {
      if (Device._isFirefox == null) {
        Device._isFirefox = Device.userAgent[dartx.contains]("Firefox", 0);
      }
      return Device._isFirefox;
    }
    static get isWebKit() {
      if (Device._isWebKit == null) {
        Device._isWebKit = !dart.notNull(Device.isOpera) && dart.notNull(Device.userAgent[dartx.contains]("WebKit", 0));
      }
      return Device._isWebKit;
    }
    static get cssPrefix() {
      let prefix = Device._cachedCssPrefix;
      if (prefix != null) return prefix;
      if (dart.notNull(Device.isFirefox)) {
        prefix = '-moz-';
      } else if (dart.notNull(Device.isIE)) {
        prefix = '-ms-';
      } else if (dart.notNull(Device.isOpera)) {
        prefix = '-o-';
      } else {
        prefix = '-webkit-';
      }
      return Device._cachedCssPrefix = prefix;
    }
    static get propertyPrefix() {
      let prefix = Device._cachedPropertyPrefix;
      if (prefix != null) return prefix;
      if (dart.notNull(Device.isFirefox)) {
        prefix = 'moz';
      } else if (dart.notNull(Device.isIE)) {
        prefix = 'ms';
      } else if (dart.notNull(Device.isOpera)) {
        prefix = 'o';
      } else {
        prefix = 'webkit';
      }
      return Device._cachedPropertyPrefix = prefix;
    }
    static isEventTypeSupported(eventType) {
      try {
        let e = html.Event.eventType(eventType, '');
        return dart.is(e, html.Event);
      } catch (_) {
      }

      return false;
    }
  }
  dart.setSignature(Device, {
    statics: () => ({isEventTypeSupported: [core.bool, [core.String]]}),
    names: ['isEventTypeSupported']
  });
  Device._isOpera = null;
  Device._isIE = null;
  Device._isFirefox = null;
  Device._isWebKit = null;
  Device._cachedCssPrefix = null;
  Device._cachedPropertyPrefix = null;
  const _childNodes = Symbol('_childNodes');
  const _node = Symbol('_node');
  const _iterable = Symbol('_iterable');
  const _filtered = Symbol('_filtered');
  class FilteredElementList extends collection.ListBase$(html.Element) {
    FilteredElementList(node) {
      this[_childNodes] = node[dartx.nodes];
      this[_node] = node;
    }
    get [_iterable]() {
      return new (_internal.WhereIterable$(html.Element))(this[_childNodes], dart.fn(n => dart.is(n, html.Element), core.bool, [html.Element]));
    }
    get [_filtered]() {
      return core.List$(html.Element).from(this[_iterable], {growable: false});
    }
    forEach(f) {
      this[_filtered][dartx.forEach](f);
    }
    set(index, value) {
      this.get(index)[dartx.replaceWith](value);
      return value;
    }
    set length(newLength) {
      let len = this.length;
      if (dart.notNull(newLength) >= dart.notNull(len)) {
        return;
      } else if (dart.notNull(newLength) < 0) {
        dart.throw(new core.ArgumentError("Invalid list length"));
      }
      this.removeRange(newLength, len);
    }
    add(value) {
      this[_childNodes][dartx.add](value);
    }
    addAll(iterable) {
      for (let element of iterable) {
        this.add(element);
      }
    }
    contains(needle) {
      if (!dart.is(needle, html.Element)) return false;
      let element = dart.as(needle, html.Element);
      return dart.equals(element[dartx.parentNode], this[_node]);
    }
    get reversed() {
      return this[_filtered][dartx.reversed];
    }
    sort(compare) {
      if (compare === void 0) compare = null;
      dart.throw(new core.UnsupportedError('Cannot sort filtered list'));
    }
    setRange(start, end, iterable, skipCount) {
      if (skipCount === void 0) skipCount = 0;
      dart.throw(new core.UnsupportedError('Cannot setRange on filtered list'));
    }
    fillRange(start, end, fillValue) {
      if (fillValue === void 0) fillValue = null;
      dart.throw(new core.UnsupportedError('Cannot fillRange on filtered list'));
    }
    replaceRange(start, end, iterable) {
      dart.throw(new core.UnsupportedError('Cannot replaceRange on filtered list'));
    }
    removeRange(start, end) {
      core.List.from(this[_iterable][dartx.skip](start)[dartx.take](dart.notNull(end) - dart.notNull(start)))[dartx.forEach](dart.fn(el => dart.dsend(el, 'remove'), dart.void, [dart.dynamic]));
    }
    clear() {
      this[_childNodes][dartx.clear]();
    }
    removeLast() {
      let result = this[_iterable][dartx.last];
      if (result != null) {
        result[dartx.remove]();
      }
      return result;
    }
    insert(index, value) {
      if (index == this.length) {
        this.add(value);
      } else {
        let element = this[_iterable][dartx.elementAt](index);
        element[dartx.parentNode][dartx.insertBefore](value, element);
      }
    }
    insertAll(index, iterable) {
      if (index == this.length) {
        this.addAll(iterable);
      } else {
        let element = this[_iterable][dartx.elementAt](index);
        element[dartx.parentNode][dartx.insertAllBefore](iterable, element);
      }
    }
    removeAt(index) {
      let result = this.get(index);
      result[dartx.remove]();
      return result;
    }
    remove(element) {
      if (!dart.is(element, html.Element)) return false;
      if (dart.notNull(this.contains(element))) {
        dart.as(element, html.Element)[dartx.remove]();
        return true;
      } else {
        return false;
      }
    }
    get length() {
      return this[_iterable][dartx.length];
    }
    get(index) {
      return this[_iterable][dartx.elementAt](index);
    }
    get iterator() {
      return this[_filtered][dartx.iterator];
    }
    get rawList() {
      return this[_node][dartx.childNodes];
    }
  }
  FilteredElementList[dart.implements] = () => [NodeListWrapper];
  dart.setSignature(FilteredElementList, {
    constructors: () => ({FilteredElementList: [FilteredElementList, [html.Node]]}),
    methods: () => ({
      forEach: [dart.void, [dart.functionType(dart.void, [html.Element])]],
      set: [dart.void, [core.int, html.Element]],
      add: [dart.void, [html.Element]],
      addAll: [dart.void, [core.Iterable$(html.Element)]],
      sort: [dart.void, [], [dart.functionType(core.int, [html.Element, html.Element])]],
      setRange: [dart.void, [core.int, core.int, core.Iterable$(html.Element)], [core.int]],
      fillRange: [dart.void, [core.int, core.int], [html.Element]],
      replaceRange: [dart.void, [core.int, core.int, core.Iterable$(html.Element)]],
      removeLast: [html.Element, []],
      insert: [dart.void, [core.int, html.Element]],
      insertAll: [dart.void, [core.int, core.Iterable$(html.Element)]],
      removeAt: [html.Element, [core.int]],
      get: [html.Element, [core.int]]
    })
  });
  dart.defineExtensionMembers(FilteredElementList, [
    'forEach',
    'set',
    'add',
    'addAll',
    'contains',
    'sort',
    'setRange',
    'fillRange',
    'replaceRange',
    'removeRange',
    'clear',
    'removeLast',
    'insert',
    'insertAll',
    'removeAt',
    'remove',
    'get',
    'length',
    'reversed',
    'length',
    'iterator'
  ]);
  class Lists extends core.Object {
    static indexOf(a, element, startIndex, endIndex) {
      if (dart.notNull(startIndex) >= dart.notNull(a[dartx.length])) {
        return -1;
      }
      if (dart.notNull(startIndex) < 0) {
        startIndex = 0;
      }
      for (let i = startIndex; dart.notNull(i) < dart.notNull(endIndex); i = dart.notNull(i) + 1) {
        if (dart.equals(a[dartx.get](i), element)) {
          return i;
        }
      }
      return -1;
    }
    static lastIndexOf(a, element, startIndex) {
      if (dart.notNull(startIndex) < 0) {
        return -1;
      }
      if (dart.notNull(startIndex) >= dart.notNull(a[dartx.length])) {
        startIndex = dart.notNull(a[dartx.length]) - 1;
      }
      for (let i = startIndex; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
        if (dart.equals(a[dartx.get](i), element)) {
          return i;
        }
      }
      return -1;
    }
    static getRange(a, start, end, accumulator) {
      if (dart.notNull(start) < 0) dart.throw(new core.RangeError.value(start));
      if (dart.notNull(end) < dart.notNull(start)) dart.throw(new core.RangeError.value(end));
      if (dart.notNull(end) > dart.notNull(a[dartx.length])) dart.throw(new core.RangeError.value(end));
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        accumulator[dartx.add](a[dartx.get](i));
      }
      return accumulator;
    }
  }
  dart.setSignature(Lists, {
    statics: () => ({
      indexOf: [core.int, [core.List, core.Object, core.int, core.int]],
      lastIndexOf: [core.int, [core.List, core.Object, core.int]],
      getRange: [core.List, [core.List, core.int, core.int, core.List]]
    }),
    names: ['indexOf', 'lastIndexOf', 'getRange']
  });
  class NodeListWrapper extends core.Object {}
  // Exports:
  exports.CssClassSetImpl = CssClassSetImpl;
  exports.convertDartToNative_SerializedScriptValue = convertDartToNative_SerializedScriptValue;
  exports.convertNativeToDart_SerializedScriptValue = convertNativeToDart_SerializedScriptValue;
  exports.convertNativeToDart_ContextAttributes = convertNativeToDart_ContextAttributes;
  exports.convertNativeToDart_ImageData = convertNativeToDart_ImageData;
  exports.convertDartToNative_ImageData = convertDartToNative_ImageData;
  exports.annotation_Creates_SerializedScriptValue = annotation_Creates_SerializedScriptValue;
  exports.annotation_Returns_SerializedScriptValue = annotation_Returns_SerializedScriptValue;
  exports.convertNativeToDart_Dictionary = convertNativeToDart_Dictionary;
  exports.convertDartToNative_Dictionary = convertDartToNative_Dictionary;
  exports.convertDartToNative_StringArray = convertDartToNative_StringArray;
  exports.convertNativeToDart_DateTime = convertNativeToDart_DateTime;
  exports.convertDartToNative_DateTime = convertDartToNative_DateTime;
  exports.convertDartToNative_PrepareForStructuredClone = convertDartToNative_PrepareForStructuredClone;
  exports.convertNativeToDart_AcceptStructuredClone = convertNativeToDart_AcceptStructuredClone;
  exports.isJavaScriptDate = isJavaScriptDate;
  exports.isJavaScriptRegExp = isJavaScriptRegExp;
  exports.isJavaScriptArray = isJavaScriptArray;
  exports.isJavaScriptSimpleObject = isJavaScriptSimpleObject;
  exports.isImmutableJavaScriptArray = isImmutableJavaScriptArray;
  exports.isJavaScriptPromise = isJavaScriptPromise;
  exports.convertNativePromiseToDartFuture = convertNativePromiseToDartFuture;
  exports.wrap_jso = wrap_jso;
  exports.unwrap_jso = unwrap_jso;
  exports.Device = Device;
  exports.FilteredElementList = FilteredElementList;
  exports.Lists = Lists;
  exports.NodeListWrapper = NodeListWrapper;
});
