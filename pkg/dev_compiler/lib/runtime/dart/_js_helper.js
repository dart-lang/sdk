var _js_helper = dart.defineLibrary(_js_helper, {});
var core = dart.import(core);
var collection = dart.import(collection);
var _internal = dart.import(_internal);
var _foreign_helper = dart.import(_foreign_helper);
var _interceptors = dart.lazyImport(_interceptors);
var _js_names = dart.import(_js_names);
var _js_embedded_names = dart.import(_js_embedded_names);
var async = dart.import(async);
var _isolate_helper = dart.lazyImport(_isolate_helper);
(function(exports, core, collection, _internal, _foreign_helper, _interceptors, _js_names, _js_embedded_names, async, _isolate_helper) {
  'use strict';
  class NoSideEffects extends core.Object {
    NoSideEffects() {
    }
  }
  dart.setSignature(NoSideEffects, {
    constructors: () => ({NoSideEffects: [NoSideEffects, []]})
  });
  class NoThrows extends core.Object {
    NoThrows() {
    }
  }
  dart.setSignature(NoThrows, {
    constructors: () => ({NoThrows: [NoThrows, []]})
  });
  class NoInline extends core.Object {
    NoInline() {
    }
  }
  dart.setSignature(NoInline, {
    constructors: () => ({NoInline: [NoInline, []]})
  });
  class IrRepresentation extends core.Object {
    IrRepresentation(value) {
      this.value = value;
    }
  }
  dart.setSignature(IrRepresentation, {
    constructors: () => ({IrRepresentation: [IrRepresentation, [core.bool]]})
  });
  class Native extends core.Object {
    Native(name) {
      this.name = name;
    }
  }
  dart.setSignature(Native, {
    constructors: () => ({Native: [Native, [core.String]]})
  });
  class JsName extends core.Object {
    JsName(opts) {
      let name = opts && 'name' in opts ? opts.name : null;
      this.name = name;
    }
  }
  dart.setSignature(JsName, {
    constructors: () => ({JsName: [JsName, [], {name: core.String}]})
  });
  class JsPeerInterface extends core.Object {
    JsPeerInterface(opts) {
      let name = opts && 'name' in opts ? opts.name : null;
      this.name = name;
    }
  }
  dart.setSignature(JsPeerInterface, {
    constructors: () => ({JsPeerInterface: [JsPeerInterface, [], {name: core.String}]})
  });
  class SupportJsExtensionMethods extends core.Object {
    SupportJsExtensionMethods() {
    }
  }
  dart.setSignature(SupportJsExtensionMethods, {
    constructors: () => ({SupportJsExtensionMethods: [SupportJsExtensionMethods, []]})
  });
  let _throwUnmodifiable = Symbol('_throwUnmodifiable');
  let ConstantMap$ = dart.generic(function(K, V) {
    class ConstantMap extends core.Object {
      _() {
      }
      get isEmpty() {
        return this.length == 0;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      toString() {
        return collection.Maps.mapToString(this);
      }
      [_throwUnmodifiable]() {
        throw new core.UnsupportedError("Cannot modify unmodifiable Map");
      }
      set(key, val) {
        dart.as(key, K);
        dart.as(val, V);
        return this[_throwUnmodifiable]();
      }
      putIfAbsent(key, ifAbsent) {
        dart.as(key, K);
        dart.as(ifAbsent, dart.functionType(V, []));
        return dart.as(this[_throwUnmodifiable](), V);
      }
      remove(key) {
        return dart.as(this[_throwUnmodifiable](), V);
      }
      clear() {
        return this[_throwUnmodifiable]();
      }
      addAll(other) {
        dart.as(other, core.Map$(K, V));
        return this[_throwUnmodifiable]();
      }
    }
    ConstantMap[dart.implements] = () => [core.Map$(K, V)];
    dart.defineNamedConstructor(ConstantMap, '_');
    dart.setSignature(ConstantMap, {
      constructors: () => ({_: [ConstantMap$(K, V), []]}),
      methods: () => ({
        [_throwUnmodifiable]: [core.Object, []],
        set: [dart.void, [K, V]],
        putIfAbsent: [V, [K, dart.functionType(V, [])]],
        remove: [V, [core.Object]],
        clear: [dart.void, []],
        addAll: [dart.void, [core.Map$(K, V)]]
      })
    });
    return ConstantMap;
  });
  let ConstantMap = ConstantMap$();
  let _jsObject = Symbol('_jsObject');
  let _keys = Symbol('_keys');
  let _fetch = Symbol('_fetch');
  let ConstantStringMap$ = dart.generic(function(K, V) {
    class ConstantStringMap extends ConstantMap$(K, V) {
      _(length, jsObject, keys) {
        this.length = length;
        this[_jsObject] = jsObject;
        this[_keys] = keys;
        super._();
      }
      containsValue(needle) {
        return this.values[dartx.any](dart.fn(value => dart.equals(value, needle), core.bool, [V]));
      }
      containsKey(key) {
        if (!(typeof key == 'string'))
          return false;
        if (dart.equals('__proto__', key))
          return false;
        return jsHasOwnProperty(this[_jsObject], dart.as(key, core.String));
      }
      get(key) {
        if (!dart.notNull(this.containsKey(key)))
          return null;
        return dart.as(this[_fetch](key), V);
      }
      [_fetch](key) {
        return jsPropertyAccess(this[_jsObject], dart.as(key, core.String));
      }
      forEach(f) {
        dart.as(f, dart.functionType(dart.void, [K, V]));
        let keys = this[_keys];
        for (let i = 0; dart.notNull(i) < dart.notNull(dart.as(dart.dload(keys, 'length'), core.num)); i = dart.notNull(i) + 1) {
          let key = dart.dindex(keys, i);
          f(dart.as(key, K), dart.as(this[_fetch](key), V));
        }
      }
      get keys() {
        return new (_ConstantMapKeyIterable$(K))(this);
      }
      get values() {
        return _internal.MappedIterable$(K, V).new(this[_keys], dart.fn(key => dart.as(this[_fetch](key), V), V, [core.Object]));
      }
    }
    ConstantStringMap[dart.implements] = () => [_internal.EfficientLength];
    dart.defineNamedConstructor(ConstantStringMap, '_');
    dart.setSignature(ConstantStringMap, {
      constructors: () => ({_: [ConstantStringMap$(K, V), [core.int, core.Object, core.List$(K)]]}),
      methods: () => ({
        containsValue: [core.bool, [core.Object]],
        containsKey: [core.bool, [core.Object]],
        get: [V, [core.Object]],
        [_fetch]: [core.Object, [core.Object]],
        forEach: [dart.void, [dart.functionType(dart.void, [K, V])]]
      })
    });
    return ConstantStringMap;
  });
  let ConstantStringMap = ConstantStringMap$();
  let _protoValue = Symbol('_protoValue');
  let ConstantProtoMap$ = dart.generic(function(K, V) {
    class ConstantProtoMap extends ConstantStringMap$(K, V) {
      _(length, jsObject, keys, protoValue) {
        this[_protoValue] = protoValue;
        super._(dart.as(length, core.int), jsObject, dart.as(keys, core.List$(K)));
      }
      containsKey(key) {
        if (!(typeof key == 'string'))
          return false;
        if (dart.equals('__proto__', key))
          return true;
        return jsHasOwnProperty(this[_jsObject], dart.as(key, core.String));
      }
      [_fetch](key) {
        return dart.equals('__proto__', key) ? this[_protoValue] : jsPropertyAccess(this[_jsObject], dart.as(key, core.String));
      }
    }
    dart.defineNamedConstructor(ConstantProtoMap, '_');
    dart.setSignature(ConstantProtoMap, {
      constructors: () => ({_: [ConstantProtoMap$(K, V), [core.Object, core.Object, core.Object, V]]})
    });
    return ConstantProtoMap;
  });
  let ConstantProtoMap = ConstantProtoMap$();
  let _map = Symbol('_map');
  let _ConstantMapKeyIterable$ = dart.generic(function(K) {
    class _ConstantMapKeyIterable extends collection.IterableBase$(K) {
      _ConstantMapKeyIterable(map) {
        this[_map] = map;
        super.IterableBase();
      }
      get iterator() {
        return this[_map][_keys][dartx.iterator];
      }
      get length() {
        return this[_map][_keys].length;
      }
    }
    dart.setSignature(_ConstantMapKeyIterable, {
      constructors: () => ({_ConstantMapKeyIterable: [_ConstantMapKeyIterable$(K), [ConstantStringMap$(K, core.Object)]]})
    });
    return _ConstantMapKeyIterable;
  });
  let _ConstantMapKeyIterable = _ConstantMapKeyIterable$();
  let _jsData = Symbol('_jsData');
  let _getMap = Symbol('_getMap');
  let GeneralConstantMap$ = dart.generic(function(K, V) {
    class GeneralConstantMap extends ConstantMap$(K, V) {
      GeneralConstantMap(jsData) {
        this[_jsData] = jsData;
        super._();
      }
      [_getMap]() {
        if (!this.$map) {
          let backingMap = collection.LinkedHashMap$(K, V).new();
          this.$map = fillLiteralMap(this[_jsData], backingMap);
        }
        return dart.as(this.$map, core.Map$(K, V));
      }
      containsValue(needle) {
        return this[_getMap]().containsValue(needle);
      }
      containsKey(key) {
        return this[_getMap]().containsKey(key);
      }
      get(key) {
        return this[_getMap]().get(key);
      }
      forEach(f) {
        dart.as(f, dart.functionType(dart.void, [K, V]));
        this[_getMap]().forEach(f);
      }
      get keys() {
        return this[_getMap]().keys;
      }
      get values() {
        return this[_getMap]().values;
      }
      get length() {
        return this[_getMap]().length;
      }
    }
    dart.setSignature(GeneralConstantMap, {
      constructors: () => ({GeneralConstantMap: [GeneralConstantMap$(K, V), [core.Object]]}),
      methods: () => ({
        [_getMap]: [core.Map$(K, V), []],
        containsValue: [core.bool, [core.Object]],
        containsKey: [core.bool, [core.Object]],
        get: [V, [core.Object]],
        forEach: [dart.void, [dart.functionType(dart.void, [K, V])]]
      })
    });
    return GeneralConstantMap;
  });
  let GeneralConstantMap = GeneralConstantMap$();
  function contains(userAgent, name) {
    return userAgent.indexOf(name) != -1;
  }
  dart.fn(contains, core.bool, [core.String, core.String]);
  function arrayLength(array) {
    return array.length;
  }
  dart.fn(arrayLength, core.int, [core.List]);
  function arrayGet(array, index) {
    return array[index];
  }
  dart.fn(arrayGet, core.Object, [core.List, core.int]);
  function arraySet(array, index, value) {
    array[index] = value;
  }
  dart.fn(arraySet, dart.void, [core.List, core.int, core.Object]);
  function propertyGet(object, property) {
    return object[property];
  }
  dart.fn(propertyGet, core.Object, [core.Object, core.String]);
  function callHasOwnProperty(func, object, property) {
    return func.call(object, property);
  }
  dart.fn(callHasOwnProperty, core.bool, [core.Object, core.Object, core.String]);
  function propertySet(object, property, value) {
    object[property] = value;
  }
  dart.fn(propertySet, dart.void, [core.Object, core.String, core.Object]);
  function getPropertyFromPrototype(object, name) {
    return Object.getPrototypeOf(object)[name];
  }
  dart.fn(getPropertyFromPrototype, core.Object, [core.Object, core.String]);
  function defineProperty(obj, property, value) {
    Object.defineProperty(obj, property, {value: value, enumerable: false, writable: true, configurable: true});
  }
  dart.fn(defineProperty, dart.void, [core.Object, core.String, core.Object]);
  let _nativeRegExp = Symbol('_nativeRegExp');
  function regExpGetNative(regexp) {
    return regexp[_nativeRegExp];
  }
  dart.fn(regExpGetNative, () => dart.functionType(core.Object, [JSSyntaxRegExp]));
  let _nativeGlobalVersion = Symbol('_nativeGlobalVersion');
  function regExpGetGlobalNative(regexp) {
    let nativeRegexp = regexp[_nativeGlobalVersion];
    nativeRegexp.lastIndex = 0;
    return nativeRegexp;
  }
  dart.fn(regExpGetGlobalNative, () => dart.functionType(core.Object, [JSSyntaxRegExp]));
  let _nativeAnchoredVersion = Symbol('_nativeAnchoredVersion');
  function regExpCaptureCount(regexp) {
    let nativeAnchoredRegExp = regexp[_nativeAnchoredVersion];
    let match = nativeAnchoredRegExp.exec('');
    return dart.as(dart.dsend(dart.dload(match, 'length'), '-', 2), core.int);
  }
  dart.fn(regExpCaptureCount, () => dart.functionType(core.int, [JSSyntaxRegExp]));
  let _nativeGlobalRegExp = Symbol('_nativeGlobalRegExp');
  let _nativeAnchoredRegExp = Symbol('_nativeAnchoredRegExp');
  let _isMultiLine = Symbol('_isMultiLine');
  let _isCaseSensitive = Symbol('_isCaseSensitive');
  let _execGlobal = Symbol('_execGlobal');
  let _execAnchored = Symbol('_execAnchored');
  class JSSyntaxRegExp extends core.Object {
    toString() {
      return `RegExp/${this.pattern}/`;
    }
    JSSyntaxRegExp(source, opts) {
      let multiLine = opts && 'multiLine' in opts ? opts.multiLine : false;
      let caseSensitive = opts && 'caseSensitive' in opts ? opts.caseSensitive : true;
      this.pattern = source;
      this[_nativeRegExp] = JSSyntaxRegExp.makeNative(source, multiLine, caseSensitive, false);
      this[_nativeGlobalRegExp] = null;
      this[_nativeAnchoredRegExp] = null;
    }
    get [_nativeGlobalVersion]() {
      if (this[_nativeGlobalRegExp] != null)
        return this[_nativeGlobalRegExp];
      return this[_nativeGlobalRegExp] = JSSyntaxRegExp.makeNative(this.pattern, this[_isMultiLine], this[_isCaseSensitive], true);
    }
    get [_nativeAnchoredVersion]() {
      if (this[_nativeAnchoredRegExp] != null)
        return this[_nativeAnchoredRegExp];
      return this[_nativeAnchoredRegExp] = JSSyntaxRegExp.makeNative(`${this.pattern}|()`, this[_isMultiLine], this[_isCaseSensitive], true);
    }
    get [_isMultiLine]() {
      return this[_nativeRegExp].multiline;
    }
    get [_isCaseSensitive]() {
      return !this[_nativeRegExp].ignoreCase;
    }
    static makeNative(source, multiLine, caseSensitive, global) {
      checkString(source);
      let m = multiLine ? 'm' : '';
      let i = caseSensitive ? '' : 'i';
      let g = global ? 'g' : '';
      let regexp = function() {
        try {
          return new RegExp(source, m + i + g);
        } catch (e) {
          return e;
        }

      }();
      if (regexp instanceof RegExp)
        return regexp;
      let errorMessage = String(regexp);
      throw new core.FormatException(`Illegal RegExp pattern: ${source}, ${errorMessage}`);
    }
    firstMatch(string) {
      let m = dart.as(this[_nativeRegExp].exec(checkString(string)), core.List$(core.String));
      if (m == null)
        return null;
      return new _MatchImplementation(this, m);
    }
    hasMatch(string) {
      return this[_nativeRegExp].test(checkString(string));
    }
    stringMatch(string) {
      let match = this.firstMatch(string);
      if (match != null)
        return match.group(0);
      return null;
    }
    allMatches(string, start) {
      if (start === void 0)
        start = 0;
      checkString(string);
      checkInt(start);
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(string.length)) {
        throw new core.RangeError.range(start, 0, string.length);
      }
      return new _AllMatchesIterable(this, string, start);
    }
    [_execGlobal](string, start) {
      let regexp = this[_nativeGlobalVersion];
      regexp.lastIndex = start;
      let match = dart.as(regexp.exec(string), core.List);
      if (match == null)
        return null;
      return new _MatchImplementation(this, dart.as(match, core.List$(core.String)));
    }
    [_execAnchored](string, start) {
      let regexp = this[_nativeAnchoredVersion];
      regexp.lastIndex = start;
      let match = dart.as(regexp.exec(string), core.List);
      if (match == null)
        return null;
      if (match[dartx.get](dart.notNull(match.length) - 1) != null)
        return null;
      match.length = dart.notNull(match.length) - 1;
      return new _MatchImplementation(this, dart.as(match, core.List$(core.String)));
    }
    matchAsPrefix(string, start) {
      if (start === void 0)
        start = 0;
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(string.length)) {
        throw new core.RangeError.range(start, 0, string.length);
      }
      return this[_execAnchored](string, start);
    }
    get isMultiLine() {
      return this[_isMultiLine];
    }
    get isCaseSensitive() {
      return this[_isCaseSensitive];
    }
  }
  JSSyntaxRegExp[dart.implements] = () => [core.RegExp];
  dart.defineExtensionMembers(JSSyntaxRegExp, ['allMatches', 'matchAsPrefix']);
  dart.setSignature(JSSyntaxRegExp, {
    constructors: () => ({JSSyntaxRegExp: [JSSyntaxRegExp, [core.String], {multiLine: core.bool, caseSensitive: core.bool}]}),
    methods: () => ({
      firstMatch: [core.Match, [core.String]],
      hasMatch: [core.bool, [core.String]],
      stringMatch: [core.String, [core.String]],
      allMatches: [core.Iterable$(core.Match), [core.String], [core.int]],
      [_execGlobal]: [core.Match, [core.String, core.int]],
      [_execAnchored]: [core.Match, [core.String, core.int]],
      matchAsPrefix: [core.Match, [core.String], [core.int]]
    }),
    statics: () => ({makeNative: [core.Object, [core.String, core.bool, core.bool, core.bool]]}),
    names: ['makeNative']
  });
  let _match = Symbol('_match');
  class _MatchImplementation extends core.Object {
    _MatchImplementation(pattern, match) {
      this.pattern = pattern;
      this[_match] = match;
      dart.assert(typeof this[_match].input == 'string');
      dart.assert(typeof this[_match].index == 'number');
    }
    get input() {
      return this[_match].input;
    }
    get start() {
      return this[_match].index;
    }
    get end() {
      return dart.notNull(this.start) + dart.notNull(this[_match][dartx.get](0).length);
    }
    group(index) {
      return this[_match][dartx.get](index);
    }
    get(index) {
      return this.group(index);
    }
    get groupCount() {
      return dart.notNull(this[_match].length) - 1;
    }
    groups(groups) {
      let out = dart.list([], core.String);
      for (let i of groups) {
        out[dartx.add](this.group(i));
      }
      return out;
    }
  }
  _MatchImplementation[dart.implements] = () => [core.Match];
  dart.setSignature(_MatchImplementation, {
    constructors: () => ({_MatchImplementation: [_MatchImplementation, [core.Pattern, core.List$(core.String)]]}),
    methods: () => ({
      group: [core.String, [core.int]],
      get: [core.String, [core.int]],
      groups: [core.List$(core.String), [core.List$(core.int)]]
    })
  });
  let _re = Symbol('_re');
  let _string = Symbol('_string');
  let _start = Symbol('_start');
  class _AllMatchesIterable extends collection.IterableBase$(core.Match) {
    _AllMatchesIterable(re, string, start) {
      this[_re] = re;
      this[_string] = string;
      this[_start] = start;
      super.IterableBase();
    }
    get iterator() {
      return new _AllMatchesIterator(this[_re], this[_string], this[_start]);
    }
  }
  dart.setSignature(_AllMatchesIterable, {
    constructors: () => ({_AllMatchesIterable: [_AllMatchesIterable, [JSSyntaxRegExp, core.String, core.int]]})
  });
  let _regExp = Symbol('_regExp');
  let _nextIndex = Symbol('_nextIndex');
  let _current = Symbol('_current');
  class _AllMatchesIterator extends core.Object {
    _AllMatchesIterator(regExp, string, nextIndex) {
      this[_regExp] = regExp;
      this[_string] = string;
      this[_nextIndex] = nextIndex;
      this[_current] = null;
    }
    get current() {
      return this[_current];
    }
    moveNext() {
      if (this[_string] == null)
        return false;
      if (dart.notNull(this[_nextIndex]) <= dart.notNull(this[_string].length)) {
        let match = this[_regExp][_execGlobal](this[_string], this[_nextIndex]);
        if (match != null) {
          this[_current] = match;
          let nextIndex = match.end;
          if (match.start == nextIndex) {
            nextIndex = dart.notNull(nextIndex) + 1;
          }
          this[_nextIndex] = nextIndex;
          return true;
        }
      }
      this[_current] = null;
      this[_string] = null;
      return false;
    }
  }
  _AllMatchesIterator[dart.implements] = () => [core.Iterator$(core.Match)];
  dart.setSignature(_AllMatchesIterator, {
    constructors: () => ({_AllMatchesIterator: [_AllMatchesIterator, [JSSyntaxRegExp, core.String, core.int]]}),
    methods: () => ({moveNext: [core.bool, []]})
  });
  function firstMatchAfter(regExp, string, start) {
    return regExp[_execGlobal](string, start);
  }
  dart.fn(firstMatchAfter, core.Match, [JSSyntaxRegExp, core.String, core.int]);
  class StringMatch extends core.Object {
    StringMatch(start, input, pattern) {
      this.start = start;
      this.input = input;
      this.pattern = pattern;
    }
    get end() {
      return dart.notNull(this.start) + dart.notNull(this.pattern.length);
    }
    get(g) {
      return this.group(g);
    }
    get groupCount() {
      return 0;
    }
    group(group_) {
      if (group_ != 0) {
        throw new core.RangeError.value(group_);
      }
      return this.pattern;
    }
    groups(groups_) {
      let result = core.List$(core.String).new();
      for (let g of groups_) {
        result[dartx.add](this.group(g));
      }
      return result;
    }
  }
  StringMatch[dart.implements] = () => [core.Match];
  dart.setSignature(StringMatch, {
    constructors: () => ({StringMatch: [StringMatch, [core.int, core.String, core.String]]}),
    methods: () => ({
      get: [core.String, [core.int]],
      group: [core.String, [core.int]],
      groups: [core.List$(core.String), [core.List$(core.int)]]
    })
  });
  function allMatchesInStringUnchecked(needle, haystack, startIndex) {
    let result = core.List$(core.Match).new();
    let length = haystack.length;
    let patternLength = needle.length;
    while (true) {
      let position = haystack[dartx.indexOf](needle, startIndex);
      if (position == -1) {
        break;
      }
      result[dartx.add](new StringMatch(position, haystack, needle));
      let endIndex = dart.notNull(position) + dart.notNull(patternLength);
      if (endIndex == length) {
        break;
      } else if (position == endIndex) {
        startIndex = dart.notNull(startIndex) + 1;
      } else {
        startIndex = endIndex;
      }
    }
    return result;
  }
  dart.fn(allMatchesInStringUnchecked, core.List$(core.Match), [core.String, core.String, core.int]);
  function stringContainsUnchecked(receiver, other, startIndex) {
    if (typeof other == 'string') {
      return !dart.equals(dart.dsend(receiver, 'indexOf', other, startIndex), -1);
    } else if (dart.is(other, JSSyntaxRegExp)) {
      return dart.dsend(other, 'hasMatch', dart.dsend(receiver, 'substring', startIndex));
    } else {
      let substr = dart.dsend(receiver, 'substring', startIndex);
      return dart.dload(dart.dsend(other, 'allMatches', substr), 'isNotEmpty');
    }
  }
  dart.fn(stringContainsUnchecked);
  function stringReplaceJS(receiver, replacer, to) {
    to = to.replace(/\$/g, "$$$$");
    return receiver.replace(replacer, to);
  }
  dart.fn(stringReplaceJS);
  function stringReplaceFirstRE(receiver, regexp, to, startIndex) {
    let match = dart.dsend(regexp, _execGlobal, receiver, startIndex);
    if (match == null)
      return receiver;
    let start = dart.dload(match, 'start');
    let end = dart.dload(match, 'end');
    return `${dart.dsend(receiver, 'substring', 0, start)}${to}${dart.dsend(receiver, 'substring', end)}`;
  }
  dart.fn(stringReplaceFirstRE);
  let ESCAPE_REGEXP = '[[\\]{}()*+?.\\\\^$|]';
  function stringReplaceAllUnchecked(receiver, from, to) {
    checkString(to);
    if (typeof from == 'string') {
      if (dart.equals(from, "")) {
        if (dart.equals(receiver, "")) {
          return to;
        } else {
          let result = new core.StringBuffer();
          let length = dart.as(dart.dload(receiver, 'length'), core.int);
          result.write(to);
          for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
            result.write(dart.dindex(receiver, i));
            result.write(to);
          }
          return dart.toString(result);
        }
      } else {
        let quoter = new RegExp(ESCAPE_REGEXP, 'g');
        let quoted = from.replace(quoter, "\\$&");
        let replacer = new RegExp(quoted, 'g');
        return stringReplaceJS(receiver, replacer, to);
      }
    } else if (dart.is(from, JSSyntaxRegExp)) {
      let re = regExpGetGlobalNative(dart.as(from, JSSyntaxRegExp));
      return stringReplaceJS(receiver, re, to);
    } else {
      checkNull(from);
      throw "String.replaceAll(Pattern) UNIMPLEMENTED";
    }
  }
  dart.fn(stringReplaceAllUnchecked);
  function _matchString(match) {
    return match.get(0);
  }
  dart.fn(_matchString, core.String, [core.Match]);
  function _stringIdentity(string) {
    return string;
  }
  dart.fn(_stringIdentity, core.String, [core.String]);
  function stringReplaceAllFuncUnchecked(receiver, pattern, onMatch, onNonMatch) {
    if (!dart.is(pattern, core.Pattern)) {
      throw new core.ArgumentError(`${pattern} is not a Pattern`);
    }
    if (onMatch == null)
      onMatch = _matchString;
    if (onNonMatch == null)
      onNonMatch = _stringIdentity;
    if (typeof pattern == 'string') {
      return stringReplaceAllStringFuncUnchecked(receiver, pattern, onMatch, onNonMatch);
    }
    let buffer = new core.StringBuffer();
    let startIndex = 0;
    for (let match of dart.as(dart.dsend(pattern, 'allMatches', receiver), core.Iterable$(core.Match))) {
      buffer.write(dart.dcall(onNonMatch, dart.dsend(receiver, 'substring', startIndex, match.start)));
      buffer.write(dart.dcall(onMatch, match));
      startIndex = match.end;
    }
    buffer.write(dart.dcall(onNonMatch, dart.dsend(receiver, 'substring', startIndex)));
    return dart.toString(buffer);
  }
  dart.fn(stringReplaceAllFuncUnchecked);
  function stringReplaceAllEmptyFuncUnchecked(receiver, onMatch, onNonMatch) {
    let buffer = new core.StringBuffer();
    let length = dart.as(dart.dload(receiver, 'length'), core.int);
    let i = 0;
    buffer.write(dart.dcall(onNonMatch, ""));
    while (dart.notNull(i) < dart.notNull(length)) {
      buffer.write(dart.dcall(onMatch, new StringMatch(i, dart.as(receiver, core.String), "")));
      let code = dart.as(dart.dsend(receiver, 'codeUnitAt', i), core.int);
      if ((dart.notNull(code) & ~1023) == 55296 && dart.notNull(length) > dart.notNull(i) + 1) {
        code = dart.as(dart.dsend(receiver, 'codeUnitAt', dart.notNull(i) + 1), core.int);
        if ((dart.notNull(code) & ~1023) == 56320) {
          buffer.write(dart.dcall(onNonMatch, dart.dsend(receiver, 'substring', i, dart.notNull(i) + 2)));
          i = dart.notNull(i) + 2;
          continue;
        }
      }
      buffer.write(dart.dcall(onNonMatch, dart.dindex(receiver, i)));
      i = dart.notNull(i) + 1;
    }
    buffer.write(dart.dcall(onMatch, new StringMatch(i, dart.as(receiver, core.String), "")));
    buffer.write(dart.dcall(onNonMatch, ""));
    return dart.toString(buffer);
  }
  dart.fn(stringReplaceAllEmptyFuncUnchecked);
  function stringReplaceAllStringFuncUnchecked(receiver, pattern, onMatch, onNonMatch) {
    let patternLength = dart.as(dart.dload(pattern, 'length'), core.int);
    if (patternLength == 0) {
      return stringReplaceAllEmptyFuncUnchecked(receiver, onMatch, onNonMatch);
    }
    let length = dart.as(dart.dload(receiver, 'length'), core.int);
    let buffer = new core.StringBuffer();
    let startIndex = 0;
    while (dart.notNull(startIndex) < dart.notNull(length)) {
      let position = dart.as(dart.dsend(receiver, 'indexOf', pattern, startIndex), core.int);
      if (position == -1) {
        break;
      }
      buffer.write(dart.dcall(onNonMatch, dart.dsend(receiver, 'substring', startIndex, position)));
      buffer.write(dart.dcall(onMatch, new StringMatch(position, dart.as(receiver, core.String), dart.as(pattern, core.String))));
      startIndex = dart.notNull(position) + dart.notNull(patternLength);
    }
    buffer.write(dart.dcall(onNonMatch, dart.dsend(receiver, 'substring', startIndex)));
    return dart.toString(buffer);
  }
  dart.fn(stringReplaceAllStringFuncUnchecked);
  function stringReplaceFirstUnchecked(receiver, from, to, startIndex) {
    if (startIndex === void 0)
      startIndex = 0;
    if (typeof from == 'string') {
      let index = dart.dsend(receiver, 'indexOf', from, startIndex);
      if (dart.dsend(index, '<', 0))
        return receiver;
      return `${dart.dsend(receiver, 'substring', 0, index)}${to}` + `${dart.dsend(receiver, 'substring', dart.dsend(index, '+', dart.dload(from, 'length')))}`;
    } else if (dart.is(from, JSSyntaxRegExp)) {
      return startIndex == 0 ? stringReplaceJS(receiver, regExpGetNative(dart.as(from, JSSyntaxRegExp)), to) : stringReplaceFirstRE(receiver, from, to, startIndex);
    } else {
      checkNull(from);
      throw "String.replace(Pattern) UNIMPLEMENTED";
    }
  }
  dart.fn(stringReplaceFirstUnchecked, core.Object, [core.Object, core.Object, core.Object], [core.int]);
  function stringJoinUnchecked(array, separator) {
    return array.join(separator);
  }
  dart.fn(stringJoinUnchecked);
  function createRuntimeType(name) {
    return new TypeImpl(name);
  }
  dart.fn(createRuntimeType, core.Type, [core.String]);
  let _typeName = Symbol('_typeName');
  let _unmangledName = Symbol('_unmangledName');
  class TypeImpl extends core.Object {
    TypeImpl(typeName) {
      this[_typeName] = typeName;
      this[_unmangledName] = null;
    }
    toString() {
      if (this[_unmangledName] != null)
        return this[_unmangledName];
      let unmangledName = unmangleAllIdentifiersIfPreservedAnyways(this[_typeName]);
      return this[_unmangledName] = unmangledName;
    }
    get hashCode() {
      return dart[dartx.hashCode](this[_typeName]);
    }
    ['=='](other) {
      return dart.is(other, TypeImpl) && dart.equals(this[_typeName], dart.dload(other, _typeName));
    }
  }
  TypeImpl[dart.implements] = () => [core.Type];
  dart.setSignature(TypeImpl, {
    constructors: () => ({TypeImpl: [TypeImpl, [core.String]]})
  });
  class TypeVariable extends core.Object {
    TypeVariable(owner, name, bound) {
      this.owner = owner;
      this.name = name;
      this.bound = bound;
    }
  }
  dart.setSignature(TypeVariable, {
    constructors: () => ({TypeVariable: [TypeVariable, [core.Type, core.String, core.int]]})
  });
  function getMangledTypeName(type) {
    return type[_typeName];
  }
  dart.fn(getMangledTypeName, core.Object, [TypeImpl]);
  function setRuntimeTypeInfo(target, typeInfo) {
    dart.assert(dart.notNull(typeInfo == null) || dart.notNull(isJsArray(typeInfo)));
    if (target != null)
      target.$builtinTypeInfo = typeInfo;
    return target;
  }
  dart.fn(setRuntimeTypeInfo, core.Object, [core.Object, core.Object]);
  function getRuntimeTypeInfo(target) {
    if (target == null)
      return null;
    return target.$builtinTypeInfo;
  }
  dart.fn(getRuntimeTypeInfo, core.Object, [core.Object]);
  function getRuntimeTypeArguments(target, substitutionName) {
    let substitution = getField(target, `${_foreign_helper.JS_OPERATOR_AS_PREFIX()}${substitutionName}`);
    return substitute(substitution, getRuntimeTypeInfo(target));
  }
  dart.fn(getRuntimeTypeArguments);
  function getRuntimeTypeArgument(target, substitutionName, index) {
    let arguments$ = getRuntimeTypeArguments(target, substitutionName);
    return arguments$ == null ? null : getIndex(arguments$, index);
  }
  dart.fn(getRuntimeTypeArgument, core.Object, [core.Object, core.String, core.int]);
  function getTypeArgumentByIndex(target, index) {
    let rti = getRuntimeTypeInfo(target);
    return rti == null ? null : getIndex(rti, index);
  }
  dart.fn(getTypeArgumentByIndex, core.Object, [core.Object, core.int]);
  function copyTypeArguments(source, target) {
    target.$builtinTypeInfo = source.$builtinTypeInfo;
  }
  dart.fn(copyTypeArguments, dart.void, [core.Object, core.Object]);
  function getClassName(object) {
    return _interceptors.getInterceptor(object).constructor.builtin$cls;
  }
  dart.fn(getClassName, core.String, [core.Object]);
  function getRuntimeTypeAsString(runtimeType, opts) {
    let onTypeVariable = opts && 'onTypeVariable' in opts ? opts.onTypeVariable : null;
    dart.assert(isJsArray(runtimeType));
    let className = getConstructorName(getIndex(runtimeType, 0));
    return `${className}` + `${joinArguments(runtimeType, 1, {onTypeVariable: onTypeVariable})}`;
  }
  dart.fn(getRuntimeTypeAsString, core.String, [core.Object], {onTypeVariable: dart.functionType(core.String, [core.int])});
  function getConstructorName(type) {
    return type.builtin$cls;
  }
  dart.fn(getConstructorName, core.String, [core.Object]);
  function runtimeTypeToString(type, opts) {
    let onTypeVariable = opts && 'onTypeVariable' in opts ? opts.onTypeVariable : null;
    if (type == null) {
      return 'dynamic';
    } else if (isJsArray(type)) {
      return getRuntimeTypeAsString(type, {onTypeVariable: onTypeVariable});
    } else if (isJsFunction(type)) {
      return getConstructorName(type);
    } else if (typeof type == 'number') {
      if (onTypeVariable == null) {
        return dart.toString(type);
      } else {
        return onTypeVariable(dart.as(type, core.int));
      }
    } else {
      return null;
    }
  }
  dart.fn(runtimeTypeToString, core.String, [core.Object], {onTypeVariable: dart.functionType(core.String, [core.int])});
  function joinArguments(types, startIndex, opts) {
    let onTypeVariable = opts && 'onTypeVariable' in opts ? opts.onTypeVariable : null;
    if (types == null)
      return '';
    dart.assert(isJsArray(types));
    let firstArgument = true;
    let allDynamic = true;
    let buffer = new core.StringBuffer();
    for (let index = startIndex; dart.notNull(index) < dart.notNull(getLength(types)); index = dart.notNull(index) + 1) {
      if (firstArgument) {
        firstArgument = false;
      } else {
        buffer.write(', ');
      }
      let argument = getIndex(types, index);
      if (argument != null) {
        allDynamic = false;
      }
      buffer.write(runtimeTypeToString(argument, {onTypeVariable: onTypeVariable}));
    }
    return allDynamic ? '' : `<${buffer}>`;
  }
  dart.fn(joinArguments, core.String, [core.Object, core.int], {onTypeVariable: dart.functionType(core.String, [core.int])});
  function getRuntimeTypeString(object) {
    let className = getClassName(object);
    if (object == null)
      return className;
    let typeInfo = object.$builtinTypeInfo;
    return `${className}${joinArguments(typeInfo, 0)}`;
  }
  dart.fn(getRuntimeTypeString, core.String, [core.Object]);
  function getRuntimeType(object) {
    let type = getRuntimeTypeString(object);
    return new TypeImpl(type);
  }
  dart.fn(getRuntimeType, core.Type, [core.Object]);
  function substitute(substitution, arguments$) {
    dart.assert(dart.notNull(substitution == null) || dart.notNull(isJsFunction(substitution)));
    dart.assert(dart.notNull(arguments$ == null) || dart.notNull(isJsArray(arguments$)));
    if (isJsFunction(substitution)) {
      substitution = invoke(substitution, arguments$);
      if (isJsArray(substitution)) {
        arguments$ = substitution;
      } else if (isJsFunction(substitution)) {
        arguments$ = invoke(substitution, arguments$);
      }
    }
    return arguments$;
  }
  dart.fn(substitute);
  function checkSubtype(object, isField, checks, asField) {
    if (object == null)
      return false;
    let arguments$ = getRuntimeTypeInfo(object);
    let interceptor = _interceptors.getInterceptor(object);
    let isSubclass = getField(interceptor, isField);
    if (isSubclass == null)
      return false;
    let substitution = getField(interceptor, asField);
    return checkArguments(substitution, arguments$, checks);
  }
  dart.fn(checkSubtype, core.bool, [core.Object, core.String, core.List, core.String]);
  function computeTypeName(isField, arguments$) {
    let prefixLength = _foreign_helper.JS_OPERATOR_IS_PREFIX().length;
    return Primitives.formatType(isField[dartx.substring](prefixLength, isField.length), arguments$);
  }
  dart.fn(computeTypeName, core.String, [core.String, core.List]);
  function subtypeCast(object, isField, checks, asField) {
    if (dart.notNull(object != null) && !dart.notNull(checkSubtype(object, isField, checks, asField))) {
      let actualType = Primitives.objectTypeName(object);
      let typeName = computeTypeName(isField, checks);
      throw new CastErrorImplementation(actualType, typeName);
    }
    return object;
  }
  dart.fn(subtypeCast, core.Object, [core.Object, core.String, core.List, core.String]);
  function assertSubtype(object, isField, checks, asField) {
    if (dart.notNull(object != null) && !dart.notNull(checkSubtype(object, isField, checks, asField))) {
      let typeName = computeTypeName(isField, checks);
      throw new TypeErrorImplementation(object, typeName);
    }
    return object;
  }
  dart.fn(assertSubtype, core.Object, [core.Object, core.String, core.List, core.String]);
  function assertIsSubtype(subtype, supertype, message) {
    if (!dart.notNull(isSubtype(subtype, supertype))) {
      throwTypeError(message);
    }
  }
  dart.fn(assertIsSubtype, core.Object, [core.Object, core.Object, core.String]);
  function throwTypeError(message) {
    throw new TypeErrorImplementation.fromMessage(dart.as(message, core.String));
  }
  dart.fn(throwTypeError);
  function checkArguments(substitution, arguments$, checks) {
    return areSubtypes(substitute(substitution, arguments$), checks);
  }
  dart.fn(checkArguments, core.bool, [core.Object, core.Object, core.Object]);
  function areSubtypes(s, t) {
    if (dart.notNull(s == null) || dart.notNull(t == null))
      return true;
    dart.assert(isJsArray(s));
    dart.assert(isJsArray(t));
    dart.assert(getLength(s) == getLength(t));
    let len = getLength(s);
    for (let i = 0; dart.notNull(i) < dart.notNull(len); i = dart.notNull(i) + 1) {
      if (!dart.notNull(isSubtype(getIndex(s, i), getIndex(t, i)))) {
        return false;
      }
    }
    return true;
  }
  dart.fn(areSubtypes, core.bool, [core.Object, core.Object]);
  function computeSignature(signature, context, contextName) {
    let typeArguments = getRuntimeTypeArguments(context, contextName);
    return invokeOn(signature, context, typeArguments);
  }
  dart.fn(computeSignature);
  function isSupertypeOfNull(type) {
    return dart.notNull(type == null) || getConstructorName(type) == _foreign_helper.JS_OBJECT_CLASS_NAME() || getConstructorName(type) == _foreign_helper.JS_NULL_CLASS_NAME();
  }
  dart.fn(isSupertypeOfNull, core.bool, [core.Object]);
  function checkSubtypeOfRuntimeType(o, t) {
    if (o == null)
      return isSupertypeOfNull(t);
    if (t == null)
      return true;
    let rti = getRuntimeTypeInfo(o);
    o = _interceptors.getInterceptor(o);
    let type = o.constructor;
    if (rti != null) {
      rti = rti.slice();
      rti.splice(0, 0, type);
      type = rti;
    } else if (hasField(t, `${_foreign_helper.JS_FUNCTION_TYPE_TAG()}`)) {
      let signatureName = `${_foreign_helper.JS_OPERATOR_IS_PREFIX()}_${getField(t, _foreign_helper.JS_FUNCTION_TYPE_TAG())}`;
      if (hasField(o, signatureName))
        return true;
      let targetSignatureFunction = getField(o, `${_foreign_helper.JS_SIGNATURE_NAME()}`);
      if (targetSignatureFunction == null)
        return false;
      type = invokeOn(targetSignatureFunction, o, null);
      return isFunctionSubtype(type, t);
    }
    return isSubtype(type, t);
  }
  dart.fn(checkSubtypeOfRuntimeType, core.bool, [core.Object, core.Object]);
  function subtypeOfRuntimeTypeCast(object, type) {
    if (dart.notNull(object != null) && !dart.notNull(checkSubtypeOfRuntimeType(object, type))) {
      let actualType = Primitives.objectTypeName(object);
      throw new CastErrorImplementation(actualType, runtimeTypeToString(type));
    }
    return object;
  }
  dart.fn(subtypeOfRuntimeTypeCast, core.Object, [core.Object, core.Object]);
  function assertSubtypeOfRuntimeType(object, type) {
    if (dart.notNull(object != null) && !dart.notNull(checkSubtypeOfRuntimeType(object, type))) {
      throw new TypeErrorImplementation(object, runtimeTypeToString(type));
    }
    return object;
  }
  dart.fn(assertSubtypeOfRuntimeType, core.Object, [core.Object, core.Object]);
  function getArguments(type) {
    return isJsArray(type) ? type.slice(1) : null;
  }
  dart.fn(getArguments);
  function isSubtype(s, t) {
    if (isIdentical(s, t))
      return true;
    if (dart.notNull(s == null) || dart.notNull(t == null))
      return true;
    if (hasField(t, `${_foreign_helper.JS_FUNCTION_TYPE_TAG()}`)) {
      return isFunctionSubtype(s, t);
    }
    if (hasField(s, `${_foreign_helper.JS_FUNCTION_TYPE_TAG()}`)) {
      return getConstructorName(t) == _foreign_helper.JS_FUNCTION_CLASS_NAME();
    }
    let typeOfS = isJsArray(s) ? getIndex(s, 0) : s;
    let typeOfT = isJsArray(t) ? getIndex(t, 0) : t;
    let name = runtimeTypeToString(typeOfT);
    let substitution = null;
    if (isNotIdentical(typeOfT, typeOfS)) {
      let test = `${_foreign_helper.JS_OPERATOR_IS_PREFIX()}${name}`;
      let typeOfSPrototype = typeOfS.prototype;
      if (hasNoField(typeOfSPrototype, test))
        return false;
      let field = `${_foreign_helper.JS_OPERATOR_AS_PREFIX()}${runtimeTypeToString(typeOfT)}`;
      substitution = getField(typeOfSPrototype, field);
    }
    if (!dart.notNull(isJsArray(s)) && dart.notNull(substitution == null) || !dart.notNull(isJsArray(t))) {
      return true;
    }
    return checkArguments(substitution, getArguments(s), getArguments(t));
  }
  dart.fn(isSubtype, core.bool, [core.Object, core.Object]);
  function isAssignable(s, t) {
    return dart.notNull(isSubtype(s, t)) || dart.notNull(isSubtype(t, s));
  }
  dart.fn(isAssignable, core.bool, [core.Object, core.Object]);
  function areAssignable(s, t, allowShorter) {
    if (dart.notNull(t == null) && dart.notNull(s == null))
      return true;
    if (t == null)
      return allowShorter;
    if (s == null)
      return false;
    dart.assert(isJsArray(s));
    dart.assert(isJsArray(t));
    let sLength = getLength(s);
    let tLength = getLength(t);
    if (allowShorter) {
      if (dart.notNull(sLength) < dart.notNull(tLength))
        return false;
    } else {
      if (sLength != tLength)
        return false;
    }
    for (let i = 0; dart.notNull(i) < dart.notNull(tLength); i = dart.notNull(i) + 1) {
      if (!dart.notNull(isAssignable(getIndex(s, i), getIndex(t, i)))) {
        return false;
      }
    }
    return true;
  }
  dart.fn(areAssignable, core.bool, [core.List, core.List, core.bool]);
  function areAssignableMaps(s, t) {
    if (t == null)
      return true;
    if (s == null)
      return false;
    dart.assert(isJsObject(s));
    dart.assert(isJsObject(t));
    let names = _interceptors.JSArray.markFixedList(dart.as(Object.getOwnPropertyNames(t), core.List));
    for (let i = 0; dart.notNull(i) < dart.notNull(names.length); i = dart.notNull(i) + 1) {
      let name = names[dartx.get](i);
      if (!Object.hasOwnProperty.call(s, name)) {
        return false;
      }
      let tType = t[name];
      let sType = s[name];
      if (!dart.notNull(isAssignable(tType, sType)))
        return false;
    }
    return true;
  }
  dart.fn(areAssignableMaps, core.bool, [core.Object, core.Object]);
  function isFunctionSubtype(s, t) {
    dart.assert(hasField(t, `${_foreign_helper.JS_FUNCTION_TYPE_TAG()}`));
    if (hasNoField(s, `${_foreign_helper.JS_FUNCTION_TYPE_TAG()}`))
      return false;
    if (hasField(s, `${_foreign_helper.JS_FUNCTION_TYPE_VOID_RETURN_TAG()}`)) {
      if (dart.notNull(dart.as(hasNoField(t, `${_foreign_helper.JS_FUNCTION_TYPE_VOID_RETURN_TAG()}`), core.bool)) && dart.notNull(dart.as(hasField(t, `${_foreign_helper.JS_FUNCTION_TYPE_RETURN_TYPE_TAG()}`), core.bool))) {
        return false;
      }
    } else if (hasNoField(t, `${_foreign_helper.JS_FUNCTION_TYPE_VOID_RETURN_TAG()}`)) {
      let sReturnType = getField(s, `${_foreign_helper.JS_FUNCTION_TYPE_RETURN_TYPE_TAG()}`);
      let tReturnType = getField(t, `${_foreign_helper.JS_FUNCTION_TYPE_RETURN_TYPE_TAG()}`);
      if (!dart.notNull(isAssignable(sReturnType, tReturnType)))
        return false;
    }
    let sParameterTypes = getField(s, `${_foreign_helper.JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG()}`);
    let tParameterTypes = getField(t, `${_foreign_helper.JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG()}`);
    let sOptionalParameterTypes = getField(s, `${_foreign_helper.JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG()}`);
    let tOptionalParameterTypes = getField(t, `${_foreign_helper.JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG()}`);
    let sParametersLen = sParameterTypes != null ? getLength(sParameterTypes) : 0;
    let tParametersLen = tParameterTypes != null ? getLength(tParameterTypes) : 0;
    let sOptionalParametersLen = sOptionalParameterTypes != null ? getLength(sOptionalParameterTypes) : 0;
    let tOptionalParametersLen = tOptionalParameterTypes != null ? getLength(tOptionalParameterTypes) : 0;
    if (dart.notNull(sParametersLen) > dart.notNull(tParametersLen)) {
      return false;
    }
    if (dart.notNull(sParametersLen) + dart.notNull(sOptionalParametersLen) < dart.notNull(tParametersLen) + dart.notNull(tOptionalParametersLen)) {
      return false;
    }
    if (sParametersLen == tParametersLen) {
      if (!dart.notNull(areAssignable(dart.as(sParameterTypes, core.List), dart.as(tParameterTypes, core.List), false)))
        return false;
      if (!dart.notNull(areAssignable(dart.as(sOptionalParameterTypes, core.List), dart.as(tOptionalParameterTypes, core.List), true))) {
        return false;
      }
    } else {
      let pos = 0;
      for (; dart.notNull(pos) < dart.notNull(sParametersLen); pos = dart.notNull(pos) + 1) {
        if (!dart.notNull(isAssignable(getIndex(sParameterTypes, pos), getIndex(tParameterTypes, pos)))) {
          return false;
        }
      }
      let sPos = 0;
      let tPos = pos;
      for (; dart.notNull(tPos) < dart.notNull(tParametersLen); sPos = dart.notNull(sPos) + 1, tPos = dart.notNull(tPos) + 1) {
        if (!dart.notNull(isAssignable(getIndex(sOptionalParameterTypes, sPos), getIndex(tParameterTypes, tPos)))) {
          return false;
        }
      }
      tPos = 0;
      for (; dart.notNull(tPos) < dart.notNull(tOptionalParametersLen); sPos = dart.notNull(sPos) + 1, tPos = dart.notNull(tPos) + 1) {
        if (!dart.notNull(isAssignable(getIndex(sOptionalParameterTypes, sPos), getIndex(tOptionalParameterTypes, tPos)))) {
          return false;
        }
      }
    }
    let sNamedParameters = getField(s, `${_foreign_helper.JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG()}`);
    let tNamedParameters = getField(t, `${_foreign_helper.JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG()}`);
    return areAssignableMaps(sNamedParameters, tNamedParameters);
  }
  dart.fn(isFunctionSubtype, core.bool, [core.Object, core.Object]);
  function invoke(func, arguments$) {
    return invokeOn(func, null, arguments$);
  }
  dart.fn(invoke);
  function invokeOn(func, receiver, arguments$) {
    dart.assert(isJsFunction(func));
    dart.assert(dart.notNull(arguments$ == null) || dart.notNull(isJsArray(arguments$)));
    return func.apply(receiver, arguments$);
  }
  dart.fn(invokeOn, core.Object, [core.Object, core.Object, core.Object]);
  function call(object, name) {
    return object[name]();
  }
  dart.fn(call, core.Object, [core.Object, core.String]);
  function getField(object, name) {
    return object[name];
  }
  dart.fn(getField, core.Object, [core.Object, core.String]);
  function getIndex(array, index) {
    dart.assert(isJsArray(array));
    return array[index];
  }
  dart.fn(getIndex, core.Object, [core.Object, core.int]);
  function getLength(array) {
    dart.assert(isJsArray(array));
    return array.length;
  }
  dart.fn(getLength, core.int, [core.Object]);
  function isJsArray(value) {
    return dart.is(value, _interceptors.JSArray);
  }
  dart.fn(isJsArray, core.bool, [core.Object]);
  function hasField(object, name) {
    return name in object;
  }
  dart.fn(hasField);
  function hasNoField(object, name) {
    return dart.dsend(hasField(object, name), '!');
  }
  dart.fn(hasNoField);
  function isJsFunction(o) {
    return typeof o == "function";
  }
  dart.fn(isJsFunction, core.bool, [core.Object]);
  function isJsObject(o) {
    return typeof o == 'object';
  }
  dart.fn(isJsObject, core.bool, [core.Object]);
  function isIdentical(s, t) {
    return s === t;
  }
  dart.fn(isIdentical, core.bool, [core.Object, core.Object]);
  function isNotIdentical(s, t) {
    return s !== t;
  }
  dart.fn(isNotIdentical, core.bool, [core.Object, core.Object]);
  function unmangleGlobalNameIfPreservedAnyways(str) {
    return str;
  }
  dart.fn(unmangleGlobalNameIfPreservedAnyways, core.String, [core.String]);
  function unmangleAllIdentifiersIfPreservedAnyways(str) {
    return str;
  }
  dart.fn(unmangleAllIdentifiersIfPreservedAnyways, core.String, [core.String]);
  class _Patch extends core.Object {
    _Patch() {
    }
  }
  dart.setSignature(_Patch, {
    constructors: () => ({_Patch: [_Patch, []]})
  });
  let patch = dart.const(new _Patch());
  class InternalMap extends core.Object {}
  function requiresPreamble() {
  }
  dart.fn(requiresPreamble);
  function S(value) {
    if (typeof value == 'string')
      return dart.as(value, core.String);
    if (dart.is(value, core.num)) {
      if (!dart.equals(value, 0)) {
        return "" + value;
      }
    } else if (dart.equals(true, value)) {
      return 'true';
    } else if (dart.equals(false, value)) {
      return 'false';
    } else if (value == null) {
      return 'null';
    }
    let res = dart.toString(value);
    if (!(typeof res == 'string'))
      throw new core.ArgumentError(value);
    return res;
  }
  dart.fn(S, core.String, [core.Object]);
  function createInvocationMirror(name, internalName, kind, arguments$, argumentNames) {
    return new JSInvocationMirror(name, dart.as(internalName, core.String), dart.as(kind, core.int), dart.as(arguments$, core.List), dart.as(argumentNames, core.List));
  }
  dart.fn(createInvocationMirror, core.Object, [core.String, core.Object, core.Object, core.Object, core.Object]);
  function createUnmangledInvocationMirror(symbol, internalName, kind, arguments$, argumentNames) {
    return new JSInvocationMirror(symbol, dart.as(internalName, core.String), dart.as(kind, core.int), dart.as(arguments$, core.List), dart.as(argumentNames, core.List));
  }
  dart.fn(createUnmangledInvocationMirror, core.Object, [core.Symbol, core.Object, core.Object, core.Object, core.Object]);
  function throwInvalidReflectionError(memberName) {
    throw new core.UnsupportedError(`Can't use '${memberName}' in reflection ` + "because it is not included in a @MirrorsUsed annotation.");
  }
  dart.fn(throwInvalidReflectionError, dart.void, [core.String]);
  function traceHelper(method) {
    if (!this.cache) {
      this.cache = Object.create(null);
    }
    if (!this.cache[method]) {
      console.log(method);
      this.cache[method] = true;
    }
  }
  dart.fn(traceHelper, dart.void, [core.String]);
  let _memberName = Symbol('_memberName');
  let _internalName = Symbol('_internalName');
  let _kind = Symbol('_kind');
  let _arguments = Symbol('_arguments');
  let _namedArgumentNames = Symbol('_namedArgumentNames');
  let _namedIndices = Symbol('_namedIndices');
  let _getCachedInvocation = Symbol('_getCachedInvocation');
  class JSInvocationMirror extends core.Object {
    JSInvocationMirror(memberName, internalName, kind, arguments$, namedArgumentNames) {
      this[_memberName] = memberName;
      this[_internalName] = internalName;
      this[_kind] = kind;
      this[_arguments] = arguments$;
      this[_namedArgumentNames] = namedArgumentNames;
      this[_namedIndices] = null;
    }
    get memberName() {
      if (dart.is(this[_memberName], core.Symbol))
        return dart.as(this[_memberName], core.Symbol);
      let name = dart.as(this[_memberName], core.String);
      let unmangledName = _js_names.mangledNames.get(name);
      if (unmangledName != null) {
        name = unmangledName[dartx.split](':')[dartx.get](0);
      } else {
        if (_js_names.mangledNames.get(this[_internalName]) == null) {
          core.print(`Warning: '${name}' is used reflectively but not in MirrorsUsed. ` + "This will break minified code.");
        }
      }
      this[_memberName] = new _internal.Symbol.unvalidated(name);
      return dart.as(this[_memberName], core.Symbol);
    }
    get isMethod() {
      return this[_kind] == JSInvocationMirror.METHOD;
    }
    get isGetter() {
      return this[_kind] == JSInvocationMirror.GETTER;
    }
    get isSetter() {
      return this[_kind] == JSInvocationMirror.SETTER;
    }
    get isAccessor() {
      return this[_kind] != JSInvocationMirror.METHOD;
    }
    get positionalArguments() {
      if (this.isGetter)
        return dart.const([]);
      let argumentCount = dart.notNull(this[_arguments].length) - dart.notNull(this[_namedArgumentNames].length);
      if (argumentCount == 0)
        return dart.const([]);
      let list = [];
      for (let index = 0; dart.notNull(index) < dart.notNull(argumentCount); index = dart.notNull(index) + 1) {
        list[dartx.add](this[_arguments][dartx.get](index));
      }
      return dart.as(makeLiteralListConst(list), core.List);
    }
    get namedArguments() {
      if (this.isAccessor)
        return dart.map();
      let namedArgumentCount = this[_namedArgumentNames].length;
      let namedArgumentsStartIndex = dart.notNull(this[_arguments].length) - dart.notNull(namedArgumentCount);
      if (namedArgumentCount == 0)
        return dart.map();
      let map = core.Map$(core.Symbol, core.Object).new();
      for (let i = 0; dart.notNull(i) < dart.notNull(namedArgumentCount); i = dart.notNull(i) + 1) {
        map.set(new _internal.Symbol.unvalidated(dart.as(this[_namedArgumentNames][dartx.get](i), core.String)), this[_arguments][dartx.get](dart.notNull(namedArgumentsStartIndex) + dart.notNull(i)));
      }
      return map;
    }
    [_getCachedInvocation](object) {
      let interceptor = _interceptors.getInterceptor(object);
      let receiver = object;
      let name = this[_internalName];
      let arguments$ = this[_arguments];
      let interceptedNames = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.INTERCEPTED_NAMES);
      let isIntercepted = Object.prototype.hasOwnProperty.call(interceptedNames, name);
      if (isIntercepted) {
        receiver = interceptor;
        if (object === interceptor) {
          interceptor = null;
        }
      } else {
        interceptor = null;
      }
      let isCatchAll = false;
      let method = receiver[name];
      if (typeof method != "function") {
        let baseName = _internal.Symbol.getName(dart.as(this.memberName, _internal.Symbol));
        method = receiver[baseName + "*"];
        if (method == null) {
          interceptor = _interceptors.getInterceptor(object);
          method = interceptor[baseName + "*"];
          if (method != null) {
            isIntercepted = true;
            receiver = interceptor;
          } else {
            interceptor = null;
          }
        }
        isCatchAll = true;
      }
      if (typeof method == "function") {
        if (isCatchAll) {
          return new CachedCatchAllInvocation(name, method, isIntercepted, dart.as(interceptor, _interceptors.Interceptor));
        } else {
          return new CachedInvocation(name, method, isIntercepted, dart.as(interceptor, _interceptors.Interceptor));
        }
      } else {
        return new CachedNoSuchMethodInvocation(interceptor);
      }
    }
    static invokeFromMirror(invocation, victim) {
      let cached = invocation[_getCachedInvocation](victim);
      if (dart.dload(cached, 'isNoSuchMethod')) {
        return dart.dsend(cached, 'invokeOn', victim, invocation);
      } else {
        return dart.dsend(cached, 'invokeOn', victim, invocation[_arguments]);
      }
    }
    static getCachedInvocation(invocation, victim) {
      return invocation[_getCachedInvocation](victim);
    }
  }
  JSInvocationMirror[dart.implements] = () => [core.Invocation];
  dart.setSignature(JSInvocationMirror, {
    constructors: () => ({JSInvocationMirror: [JSInvocationMirror, [core.Object, core.String, core.int, core.List, core.List]]}),
    methods: () => ({[_getCachedInvocation]: [core.Object, [core.Object]]}),
    statics: () => ({
      invokeFromMirror: [core.Object, [JSInvocationMirror, core.Object]],
      getCachedInvocation: [core.Object, [JSInvocationMirror, core.Object]]
    }),
    names: ['invokeFromMirror', 'getCachedInvocation']
  });
  JSInvocationMirror.METHOD = 0;
  JSInvocationMirror.GETTER = 1;
  JSInvocationMirror.SETTER = 2;
  class CachedInvocation extends core.Object {
    CachedInvocation(mangledName, jsFunction, isIntercepted, cachedInterceptor) {
      this.mangledName = mangledName;
      this.jsFunction = jsFunction;
      this.isIntercepted = isIntercepted;
      this.cachedInterceptor = cachedInterceptor;
    }
    get isNoSuchMethod() {
      return false;
    }
    get isGetterStub() {
      return !!this.jsFunction.$getterStub;
    }
    invokeOn(victim, arguments$) {
      let receiver = victim;
      if (!dart.notNull(this.isIntercepted)) {
        if (!dart.is(arguments$, _interceptors.JSArray))
          arguments$ = core.List.from(arguments$);
      } else {
        let _ = [victim];
        _[dartx.addAll](arguments$);
        arguments$ = _;
        if (this.cachedInterceptor != null)
          receiver = this.cachedInterceptor;
      }
      return this.jsFunction.apply(receiver, arguments$);
    }
  }
  dart.setSignature(CachedInvocation, {
    constructors: () => ({CachedInvocation: [CachedInvocation, [core.String, core.Object, core.bool, _interceptors.Interceptor]]}),
    methods: () => ({invokeOn: [core.Object, [core.Object, core.List]]})
  });
  class CachedCatchAllInvocation extends CachedInvocation {
    CachedCatchAllInvocation(name, jsFunction, isIntercepted, cachedInterceptor) {
      this.info = ReflectionInfo.new(jsFunction);
      super.CachedInvocation(name, jsFunction, isIntercepted, cachedInterceptor);
    }
    get isGetterStub() {
      return false;
    }
    invokeOn(victim, arguments$) {
      let receiver = victim;
      let providedArgumentCount = null;
      let fullParameterCount = dart.notNull(this.info.requiredParameterCount) + dart.notNull(this.info.optionalParameterCount);
      if (!dart.notNull(this.isIntercepted)) {
        if (dart.is(arguments$, _interceptors.JSArray)) {
          providedArgumentCount = arguments$.length;
          if (dart.notNull(providedArgumentCount) < dart.notNull(fullParameterCount)) {
            arguments$ = core.List.from(arguments$);
          }
        } else {
          arguments$ = core.List.from(arguments$);
          providedArgumentCount = arguments$.length;
        }
      } else {
        let _ = [victim];
        _[dartx.addAll](arguments$);
        arguments$ = _;
        if (this.cachedInterceptor != null)
          receiver = this.cachedInterceptor;
        providedArgumentCount = dart.notNull(arguments$.length) - 1;
      }
      if (dart.notNull(this.info.areOptionalParametersNamed) && dart.notNull(providedArgumentCount) > dart.notNull(this.info.requiredParameterCount)) {
        throw new UnimplementedNoSuchMethodError(`Invocation of unstubbed method '${this.info.reflectionName}'` + ` with ${arguments$.length} arguments.`);
      } else if (dart.notNull(providedArgumentCount) < dart.notNull(this.info.requiredParameterCount)) {
        throw new UnimplementedNoSuchMethodError(`Invocation of unstubbed method '${this.info.reflectionName}'` + ` with ${providedArgumentCount} arguments (too few).`);
      } else if (dart.notNull(providedArgumentCount) > dart.notNull(fullParameterCount)) {
        throw new UnimplementedNoSuchMethodError(`Invocation of unstubbed method '${this.info.reflectionName}'` + ` with ${providedArgumentCount} arguments (too many).`);
      }
      for (let i = providedArgumentCount; dart.notNull(i) < dart.notNull(fullParameterCount); i = dart.notNull(i) + 1) {
        arguments$[dartx.add](getMetadata(this.info.defaultValue(i)));
      }
      return this.jsFunction.apply(receiver, arguments$);
    }
  }
  dart.setSignature(CachedCatchAllInvocation, {
    constructors: () => ({CachedCatchAllInvocation: [CachedCatchAllInvocation, [core.String, core.Object, core.bool, _interceptors.Interceptor]]})
  });
  class CachedNoSuchMethodInvocation extends core.Object {
    CachedNoSuchMethodInvocation(interceptor) {
      this.interceptor = interceptor;
    }
    get isNoSuchMethod() {
      return true;
    }
    get isGetterStub() {
      return false;
    }
    invokeOn(victim, invocation) {
      let receiver = this.interceptor == null ? victim : this.interceptor;
      return dart.dsend(receiver, 'noSuchMethod', invocation);
    }
  }
  dart.setSignature(CachedNoSuchMethodInvocation, {
    constructors: () => ({CachedNoSuchMethodInvocation: [CachedNoSuchMethodInvocation, [core.Object]]}),
    methods: () => ({invokeOn: [core.Object, [core.Object, core.Invocation]]})
  });
  class ReflectionInfo extends core.Object {
    internal(jsFunction, data, isAccessor, requiredParameterCount, optionalParameterCount, areOptionalParametersNamed, functionType) {
      this.jsFunction = jsFunction;
      this.data = data;
      this.isAccessor = isAccessor;
      this.requiredParameterCount = requiredParameterCount;
      this.optionalParameterCount = optionalParameterCount;
      this.areOptionalParametersNamed = areOptionalParametersNamed;
      this.functionType = functionType;
      this.cachedSortedIndices = null;
    }
    static new(jsFunction) {
      let data = dart.as(jsFunction.$reflectionInfo, core.List);
      if (data == null)
        return null;
      data = _interceptors.JSArray.markFixedList(data);
      let requiredParametersInfo = data[ReflectionInfo.REQUIRED_PARAMETERS_INFO];
      let requiredParameterCount = requiredParametersInfo >> 1;
      let isAccessor = (dart.notNull(requiredParametersInfo) & 1) == 1;
      let optionalParametersInfo = data[ReflectionInfo.OPTIONAL_PARAMETERS_INFO];
      let optionalParameterCount = optionalParametersInfo >> 1;
      let areOptionalParametersNamed = (dart.notNull(optionalParametersInfo) & 1) == 1;
      let functionType = data[ReflectionInfo.FUNCTION_TYPE_INDEX];
      return new ReflectionInfo.internal(jsFunction, data, isAccessor, requiredParameterCount, optionalParameterCount, areOptionalParametersNamed, functionType);
    }
    parameterName(parameter) {
      let metadataIndex = null;
      if (_foreign_helper.JS_GET_FLAG('MUST_RETAIN_METADATA')) {
        metadataIndex = this.data[2 * parameter + this.optionalParameterCount + ReflectionInfo.FIRST_DEFAULT_ARGUMENT];
      } else {
        metadataIndex = this.data[parameter + this.optionalParameterCount + ReflectionInfo.FIRST_DEFAULT_ARGUMENT];
      }
      let metadata = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.METADATA);
      return metadata[metadataIndex];
    }
    parameterMetadataAnnotations(parameter) {
      if (!dart.notNull(_foreign_helper.JS_GET_FLAG('MUST_RETAIN_METADATA'))) {
        throw new core.StateError('metadata has not been preserved');
      } else {
        return dart.as(this.data[2 * parameter + this.optionalParameterCount + ReflectionInfo.FIRST_DEFAULT_ARGUMENT + 1], core.List$(core.int));
      }
    }
    defaultValue(parameter) {
      if (dart.notNull(parameter) < dart.notNull(this.requiredParameterCount))
        return null;
      return this.data[ReflectionInfo.FIRST_DEFAULT_ARGUMENT + parameter - this.requiredParameterCount];
    }
    defaultValueInOrder(parameter) {
      if (dart.notNull(parameter) < dart.notNull(this.requiredParameterCount))
        return null;
      if (!dart.notNull(this.areOptionalParametersNamed) || this.optionalParameterCount == 1) {
        return this.defaultValue(parameter);
      }
      let index = this.sortedIndex(dart.notNull(parameter) - dart.notNull(this.requiredParameterCount));
      return this.defaultValue(index);
    }
    parameterNameInOrder(parameter) {
      if (dart.notNull(parameter) < dart.notNull(this.requiredParameterCount))
        return null;
      if (!dart.notNull(this.areOptionalParametersNamed) || this.optionalParameterCount == 1) {
        return this.parameterName(parameter);
      }
      let index = this.sortedIndex(dart.notNull(parameter) - dart.notNull(this.requiredParameterCount));
      return this.parameterName(index);
    }
    sortedIndex(unsortedIndex) {
      if (this.cachedSortedIndices == null) {
        this.cachedSortedIndices = core.List.new(this.optionalParameterCount);
        let positions = dart.map();
        for (let i = 0; dart.notNull(i) < dart.notNull(this.optionalParameterCount); i = dart.notNull(i) + 1) {
          let index = dart.notNull(this.requiredParameterCount) + dart.notNull(i);
          positions.set(this.parameterName(index), index);
        }
        let index = 0;
        (() => {
          let _ = positions.keys[dartx.toList]();
          _[dartx.sort]();
          return _;
        })()[dartx.forEach](dart.fn(name => {
          this.cachedSortedIndices[dartx.set]((() => {
            let x = index;
            index = dart.notNull(x) + 1;
            return x;
          })(), positions.get(name));
        }, core.Object, [core.String]));
      }
      return dart.as(this.cachedSortedIndices[dartx.get](unsortedIndex), core.int);
    }
    computeFunctionRti(jsConstructor) {
      if (typeof this.functionType == "number") {
        return getMetadata(dart.as(this.functionType, core.int));
      } else if (typeof this.functionType == "function") {
        let fakeInstance = new jsConstructor();
        setRuntimeTypeInfo(fakeInstance, fakeInstance["<>"]);
        return this.functionType.apply({$receiver: fakeInstance});
      } else {
        throw new RuntimeError('Unexpected function type');
      }
    }
    get reflectionName() {
      return this.jsFunction.$reflectionName;
    }
  }
  dart.defineNamedConstructor(ReflectionInfo, 'internal');
  dart.setSignature(ReflectionInfo, {
    constructors: () => ({
      internal: [ReflectionInfo, [core.Object, core.List, core.bool, core.int, core.int, core.bool, core.Object]],
      new: [ReflectionInfo, [core.Object]]
    }),
    methods: () => ({
      parameterName: [core.String, [core.int]],
      parameterMetadataAnnotations: [core.List$(core.int), [core.int]],
      defaultValue: [core.int, [core.int]],
      defaultValueInOrder: [core.int, [core.int]],
      parameterNameInOrder: [core.String, [core.int]],
      sortedIndex: [core.int, [core.int]],
      computeFunctionRti: [core.Object, [core.Object]]
    })
  });
  ReflectionInfo.REQUIRED_PARAMETERS_INFO = 0;
  ReflectionInfo.OPTIONAL_PARAMETERS_INFO = 1;
  ReflectionInfo.FUNCTION_TYPE_INDEX = 2;
  ReflectionInfo.FIRST_DEFAULT_ARGUMENT = 3;
  function getMetadata(index) {
    let metadata = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.METADATA);
    return metadata[index];
  }
  dart.fn(getMetadata, core.Object, [core.int]);
  class Primitives extends core.Object {
    static initializeStatics(id) {
      Primitives.mirrorFunctionCacheName = dart.notNull(Primitives.mirrorFunctionCacheName) + `_${id}`;
      Primitives.mirrorInvokeCacheName = dart.notNull(Primitives.mirrorInvokeCacheName) + `_${id}`;
    }
    static objectHashCode(object) {
      let hash = dart.as(object.$identityHash, core.int);
      if (hash == null) {
        hash = Math.random() * 0x3fffffff | 0;
        object.$identityHash = hash;
      }
      return hash;
    }
    static _throwFormatException(string) {
      throw new core.FormatException(string);
    }
    static parseInt(source, radix, handleError) {
      if (handleError == null)
        handleError = dart.fn(s => dart.as(Primitives._throwFormatException(dart.as(s, core.String)), core.int), core.int, [core.Object]);
      checkString(source);
      let match = /^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(source);
      let digitsIndex = 1;
      let hexIndex = 2;
      let decimalIndex = 3;
      let nonDecimalHexIndex = 4;
      if (radix == null) {
        radix = 10;
        if (match != null) {
          if (dart.dindex(match, hexIndex) != null) {
            return parseInt(source, 16);
          }
          if (dart.dindex(match, decimalIndex) != null) {
            return parseInt(source, 10);
          }
          return handleError(source);
        }
      } else {
        if (!(typeof radix == 'number'))
          throw new core.ArgumentError("Radix is not an integer");
        if (dart.notNull(radix) < 2 || dart.notNull(radix) > 36) {
          throw new core.RangeError(`Radix ${radix} not in range 2..36`);
        }
        if (match != null) {
          if (radix == 10 && dart.notNull(dart.dindex(match, decimalIndex) != null)) {
            return parseInt(source, 10);
          }
          if (dart.notNull(radix) < 10 || dart.notNull(dart.dindex(match, decimalIndex) == null)) {
            let maxCharCode = null;
            if (dart.notNull(radix) <= 10) {
              maxCharCode = 48 + dart.notNull(radix) - 1;
            } else {
              maxCharCode = 97 + dart.notNull(radix) - 10 - 1;
            }
            let digitsPart = dart.as(dart.dindex(match, digitsIndex), core.String);
            for (let i = 0; dart.notNull(i) < dart.notNull(digitsPart.length); i = dart.notNull(i) + 1) {
              let characterCode = dart.notNull(digitsPart[dartx.codeUnitAt](0)) | 32;
              if (dart.notNull(digitsPart[dartx.codeUnitAt](i)) > dart.notNull(maxCharCode)) {
                return handleError(source);
              }
            }
          }
        }
      }
      if (match == null)
        return handleError(source);
      return parseInt(source, radix);
    }
    static parseDouble(source, handleError) {
      checkString(source);
      if (handleError == null)
        handleError = dart.fn(s => dart.as(Primitives._throwFormatException(dart.as(s, core.String)), core.double), core.double, [core.Object]);
      if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(source)) {
        return handleError(source);
      }
      let result = parseFloat(source);
      if (result[dartx.isNaN]) {
        let trimmed = source[dartx.trim]();
        if (trimmed == 'NaN' || trimmed == '+NaN' || trimmed == '-NaN') {
          return result;
        }
        return handleError(source);
      }
      return result;
    }
    static formatType(className, typeArguments) {
      return unmangleAllIdentifiersIfPreservedAnyways(`${className}${joinArguments(typeArguments, 0)}`);
    }
    static objectTypeName(object) {
      let name = Primitives.constructorNameFallback(object);
      if (name == 'Object') {
        let decompiled = String(object.constructor).match(/^\s*function\s*(\S*)\s*\(/)[1];
        if (typeof decompiled == 'string')
          if (/^\w+$/.test(decompiled))
            name = dart.as(decompiled, core.String);
      }
      return Primitives.formatType(name, dart.as(getRuntimeTypeInfo(object), core.List));
    }
    static objectToString(object) {
      let name = dart.typeName(dart.realRuntimeType(object));
      return `Instance of '${name}'`;
    }
    static dateNow() {
      return Date.now();
    }
    static initTicker() {
      if (Primitives.timerFrequency != null)
        return;
      Primitives.timerFrequency = 1000;
      Primitives.timerTicks = Primitives.dateNow;
      if (typeof window == "undefined")
        return;
      let window = window;
      if (window == null)
        return;
      let performance = window.performance;
      if (performance == null)
        return;
      if (typeof performance.now != "function")
        return;
      Primitives.timerFrequency = 1000000;
      Primitives.timerTicks = dart.fn(() => (1000 * performance.now())[dartx.floor](), core.int, []);
    }
    static get isD8() {
      return typeof version == "function" && typeof os == "object" && "system" in os;
    }
    static get isJsshell() {
      return typeof version == "function" && typeof system == "function";
    }
    static currentUri() {
      requiresPreamble();
      if (!!self.location) {
        return self.location.href;
      }
      return null;
    }
    static _fromCharCodeApply(array) {
      let result = "";
      let kMaxApply = 500;
      let end = array.length;
      for (let i = 0; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + dart.notNull(kMaxApply)) {
        let subarray = null;
        if (dart.notNull(end) <= dart.notNull(kMaxApply)) {
          subarray = array;
        } else {
          subarray = array.slice(i, dart.notNull(i) + dart.notNull(kMaxApply) < dart.notNull(end) ? dart.notNull(i) + dart.notNull(kMaxApply) : end);
        }
        result = result + String.fromCharCode.apply(null, subarray);
      }
      return result;
    }
    static stringFromCodePoints(codePoints) {
      let a = dart.list([], core.int);
      for (let i of dart.as(codePoints, core.Iterable)) {
        if (!(typeof i == 'number'))
          throw new core.ArgumentError(i);
        if (dart.dsend(i, '<=', 65535)) {
          a[dartx.add](dart.as(i, core.int));
        } else if (dart.dsend(i, '<=', 1114111)) {
          a[dartx.add]((55296)[dartx['+']](dart.as(dart.dsend(dart.dsend(dart.dsend(i, '-', 65536), '>>', 10), '&', 1023), core.num)));
          a[dartx.add]((56320)[dartx['+']](dart.as(dart.dsend(i, '&', 1023), core.num)));
        } else {
          throw new core.ArgumentError(i);
        }
      }
      return Primitives._fromCharCodeApply(a);
    }
    static stringFromCharCodes(charCodes) {
      for (let i of dart.as(charCodes, core.Iterable)) {
        if (!(typeof i == 'number'))
          throw new core.ArgumentError(i);
        if (dart.dsend(i, '<', 0))
          throw new core.ArgumentError(i);
        if (dart.dsend(i, '>', 65535))
          return Primitives.stringFromCodePoints(charCodes);
      }
      return Primitives._fromCharCodeApply(dart.as(charCodes, core.List$(core.int)));
    }
    static stringFromCharCode(charCode) {
      if (0 <= dart.notNull(dart.as(charCode, core.num))) {
        if (dart.dsend(charCode, '<=', 65535)) {
          return String.fromCharCode(charCode);
        }
        if (dart.dsend(charCode, '<=', 1114111)) {
          let bits = dart.dsend(charCode, '-', 65536);
          let low = (56320)[dartx['|']](dart.as(dart.dsend(bits, '&', 1023), core.int));
          let high = (55296)[dartx['|']](dart.as(dart.dsend(bits, '>>', 10), core.int));
          return String.fromCharCode(high, low);
        }
      }
      throw new core.RangeError.range(dart.as(charCode, core.num), 0, 1114111);
    }
    static stringConcatUnchecked(string1, string2) {
      return _foreign_helper.JS_STRING_CONCAT(string1, string2);
    }
    static flattenString(str) {
      return str.charCodeAt(0) == 0 ? str : str;
    }
    static getTimeZoneName(receiver) {
      let d = Primitives.lazyAsJsDate(receiver);
      let match = dart.as(/\((.*)\)/.exec(d.toString()), core.List);
      if (match != null)
        return dart.as(match[dartx.get](1), core.String);
      match = dart.as(/^[A-Z,a-z]{3}\s[A-Z,a-z]{3}\s\d+\s\d{2}:\d{2}:\d{2}\s([A-Z]{3,5})\s\d{4}$/.exec(d.toString()), core.List);
      if (match != null)
        return dart.as(match[dartx.get](1), core.String);
      match = dart.as(/(?:GMT|UTC)[+-]\d{4}/.exec(d.toString()), core.List);
      if (match != null)
        return dart.as(match[dartx.get](0), core.String);
      return "";
    }
    static getTimeZoneOffsetInMinutes(receiver) {
      return -Primitives.lazyAsJsDate(receiver).getTimezoneOffset();
    }
    static valueFromDecomposedDate(years, month, day, hours, minutes, seconds, milliseconds, isUtc) {
      let MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;
      checkInt(years);
      checkInt(month);
      checkInt(day);
      checkInt(hours);
      checkInt(minutes);
      checkInt(seconds);
      checkInt(milliseconds);
      checkBool(isUtc);
      let jsMonth = dart.dsend(month, '-', 1);
      let value = null;
      if (isUtc) {
        value = Date.UTC(years, jsMonth, day, hours, minutes, seconds, milliseconds);
      } else {
        value = new Date(years, jsMonth, day, hours, minutes, seconds, milliseconds).valueOf();
      }
      if (dart.notNull(dart.as(dart.dload(value, 'isNaN'), core.bool)) || dart.notNull(dart.as(dart.dsend(value, '<', -dart.notNull(MAX_MILLISECONDS_SINCE_EPOCH)), core.bool)) || dart.notNull(dart.as(dart.dsend(value, '>', MAX_MILLISECONDS_SINCE_EPOCH), core.bool))) {
        return null;
      }
      if (dart.notNull(dart.as(dart.dsend(years, '<=', 0), core.bool)) || dart.notNull(dart.as(dart.dsend(years, '<', 100), core.bool)))
        return Primitives.patchUpY2K(value, years, isUtc);
      return value;
    }
    static patchUpY2K(value, years, isUtc) {
      let date = new Date(value);
      if (isUtc) {
        date.setUTCFullYear(years);
      } else {
        date.setFullYear(years);
      }
      return date.valueOf();
    }
    static lazyAsJsDate(receiver) {
      if (receiver.date === void 0) {
        receiver.date = new Date(dart.dload(receiver, 'millisecondsSinceEpoch'));
      }
      return receiver.date;
    }
    static getYear(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCFullYear() + 0 : Primitives.lazyAsJsDate(receiver).getFullYear() + 0;
    }
    static getMonth(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCMonth() + 1 : Primitives.lazyAsJsDate(receiver).getMonth() + 1;
    }
    static getDay(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCDate() + 0 : Primitives.lazyAsJsDate(receiver).getDate() + 0;
    }
    static getHours(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCHours() + 0 : Primitives.lazyAsJsDate(receiver).getHours() + 0;
    }
    static getMinutes(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCMinutes() + 0 : Primitives.lazyAsJsDate(receiver).getMinutes() + 0;
    }
    static getSeconds(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCSeconds() + 0 : Primitives.lazyAsJsDate(receiver).getSeconds() + 0;
    }
    static getMilliseconds(receiver) {
      return dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCMilliseconds() + 0 : Primitives.lazyAsJsDate(receiver).getMilliseconds() + 0;
    }
    static getWeekday(receiver) {
      let weekday = dart.dload(receiver, 'isUtc') ? Primitives.lazyAsJsDate(receiver).getUTCDay() + 0 : Primitives.lazyAsJsDate(receiver).getDay() + 0;
      return (dart.notNull(weekday) + 6) % 7 + 1;
    }
    static valueFromDateString(str) {
      if (!(typeof str == 'string'))
        throw new core.ArgumentError(str);
      let value = Date.parse(str);
      if (value[dartx.isNaN])
        throw new core.ArgumentError(str);
      return value;
    }
    static getProperty(object, key) {
      if (dart.notNull(object == null) || typeof object == 'boolean' || dart.is(object, core.num) || typeof object == 'string') {
        throw new core.ArgumentError(object);
      }
      return object[key];
    }
    static setProperty(object, key, value) {
      if (dart.notNull(object == null) || typeof object == 'boolean' || dart.is(object, core.num) || typeof object == 'string') {
        throw new core.ArgumentError(object);
      }
      object[key] = value;
    }
    static functionNoSuchMethod(func, positionalArguments, namedArguments) {
      let argumentCount = 0;
      let arguments$ = [];
      let namedArgumentList = [];
      if (positionalArguments != null) {
        argumentCount = dart.notNull(argumentCount) + dart.notNull(positionalArguments.length);
        arguments$[dartx.addAll](positionalArguments);
      }
      let names = '';
      if (dart.notNull(namedArguments != null) && !dart.notNull(namedArguments.isEmpty)) {
        namedArguments.forEach(dart.fn((name, argument) => {
          names = `${names}$${name}`;
          namedArgumentList[dartx.add](name);
          arguments$[dartx.add](argument);
          argumentCount = dart.notNull(argumentCount) + 1;
        }, core.Object, [core.String, core.Object]));
      }
      let selectorName = `${_foreign_helper.JS_GET_NAME("CALL_PREFIX")}$${argumentCount}${names}`;
      return dart.dsend(func, 'noSuchMethod', createUnmangledInvocationMirror(dart.const(new core.Symbol('call')), selectorName, JSInvocationMirror.METHOD, arguments$, namedArgumentList));
    }
    static applyFunction(func, positionalArguments, namedArguments) {
      return namedArguments == null ? Primitives.applyFunctionWithPositionalArguments(func, positionalArguments) : Primitives.applyFunctionWithNamedArguments(func, positionalArguments, namedArguments);
    }
    static applyFunctionWithPositionalArguments(func, positionalArguments) {
      let argumentCount = 0;
      let arguments$ = null;
      if (positionalArguments != null) {
        if (positionalArguments instanceof Array) {
          arguments$ = positionalArguments;
        } else {
          arguments$ = core.List.from(positionalArguments);
        }
        argumentCount = arguments$.length;
      } else {
        arguments$ = [];
      }
      let selectorName = `${_foreign_helper.JS_GET_NAME("CALL_PREFIX")}$${argumentCount}`;
      let jsFunction = func[selectorName];
      if (jsFunction == null) {
        return Primitives.functionNoSuchMethod(func, positionalArguments, null);
      }
      return jsFunction.apply(func, arguments$);
    }
    static applyFunctionWithNamedArguments(func, positionalArguments, namedArguments) {
      if (namedArguments.isEmpty) {
        return Primitives.applyFunctionWithPositionalArguments(func, positionalArguments);
      }
      let interceptor = _interceptors.getInterceptor(func);
      let jsFunction = interceptor["call*"];
      if (jsFunction == null) {
        return Primitives.functionNoSuchMethod(func, positionalArguments, namedArguments);
      }
      let info = ReflectionInfo.new(jsFunction);
      if (dart.notNull(info == null) || !dart.notNull(info.areOptionalParametersNamed)) {
        return Primitives.functionNoSuchMethod(func, positionalArguments, namedArguments);
      }
      if (positionalArguments != null) {
        positionalArguments = core.List.from(positionalArguments);
      } else {
        positionalArguments = [];
      }
      if (info.requiredParameterCount != positionalArguments.length) {
        return Primitives.functionNoSuchMethod(func, positionalArguments, namedArguments);
      }
      let defaultArguments = core.Map.new();
      for (let i = 0; dart.notNull(i) < dart.notNull(info.optionalParameterCount); i = dart.notNull(i) + 1) {
        let index = dart.notNull(i) + dart.notNull(info.requiredParameterCount);
        let parameterName = info.parameterNameInOrder(index);
        let value = info.defaultValueInOrder(index);
        let defaultValue = getMetadata(value);
        defaultArguments.set(parameterName, defaultValue);
      }
      let bad = false;
      namedArguments.forEach(dart.fn((parameter, value) => {
        if (defaultArguments.containsKey(parameter)) {
          defaultArguments.set(parameter, value);
        } else {
          bad = true;
        }
      }, core.Object, [core.String, core.Object]));
      if (bad) {
        return Primitives.functionNoSuchMethod(func, positionalArguments, namedArguments);
      }
      positionalArguments[dartx.addAll](defaultArguments.values);
      return jsFunction.apply(func, positionalArguments);
    }
    static _mangledNameMatchesType(mangledName, type) {
      return mangledName == type[_typeName];
    }
    static identicalImplementation(a, b) {
      return a == null ? b == null : a === b;
    }
    static extractStackTrace(error) {
      return getTraceFromException(error.$thrownJsError);
    }
  }
  dart.setSignature(Primitives, {
    statics: () => ({
      initializeStatics: [dart.void, [core.int]],
      objectHashCode: [core.int, [core.Object]],
      _throwFormatException: [core.Object, [core.String]],
      parseInt: [core.int, [core.String, core.int, dart.functionType(core.int, [core.String])]],
      parseDouble: [core.double, [core.String, dart.functionType(core.double, [core.String])]],
      formatType: [core.String, [core.String, core.List]],
      objectTypeName: [core.String, [core.Object]],
      objectToString: [core.String, [core.Object]],
      dateNow: [core.num, []],
      initTicker: [dart.void, []],
      currentUri: [core.String, []],
      _fromCharCodeApply: [core.String, [core.List$(core.int)]],
      stringFromCodePoints: [core.String, [core.Object]],
      stringFromCharCodes: [core.String, [core.Object]],
      stringFromCharCode: [core.String, [core.Object]],
      stringConcatUnchecked: [core.String, [core.String, core.String]],
      flattenString: [core.String, [core.String]],
      getTimeZoneName: [core.String, [core.Object]],
      getTimeZoneOffsetInMinutes: [core.int, [core.Object]],
      valueFromDecomposedDate: [core.Object, [core.Object, core.Object, core.Object, core.Object, core.Object, core.Object, core.Object, core.Object]],
      patchUpY2K: [core.Object, [core.Object, core.Object, core.Object]],
      lazyAsJsDate: [core.Object, [core.Object]],
      getYear: [core.Object, [core.Object]],
      getMonth: [core.Object, [core.Object]],
      getDay: [core.Object, [core.Object]],
      getHours: [core.Object, [core.Object]],
      getMinutes: [core.Object, [core.Object]],
      getSeconds: [core.Object, [core.Object]],
      getMilliseconds: [core.Object, [core.Object]],
      getWeekday: [core.Object, [core.Object]],
      valueFromDateString: [core.Object, [core.Object]],
      getProperty: [core.Object, [core.Object, core.Object]],
      setProperty: [dart.void, [core.Object, core.Object, core.Object]],
      functionNoSuchMethod: [core.Object, [core.Object, core.List, core.Map$(core.String, core.Object)]],
      applyFunction: [core.Object, [core.Function, core.List, core.Map$(core.String, core.Object)]],
      applyFunctionWithPositionalArguments: [core.Object, [core.Function, core.List]],
      applyFunctionWithNamedArguments: [core.Object, [core.Function, core.List, core.Map$(core.String, core.Object)]],
      _mangledNameMatchesType: [core.Object, [core.String, TypeImpl]],
      identicalImplementation: [core.bool, [core.Object, core.Object]],
      extractStackTrace: [core.StackTrace, [core.Error]]
    }),
    names: ['initializeStatics', 'objectHashCode', '_throwFormatException', 'parseInt', 'parseDouble', 'formatType', 'objectTypeName', 'objectToString', 'dateNow', 'initTicker', 'currentUri', '_fromCharCodeApply', 'stringFromCodePoints', 'stringFromCharCodes', 'stringFromCharCode', 'stringConcatUnchecked', 'flattenString', 'getTimeZoneName', 'getTimeZoneOffsetInMinutes', 'valueFromDecomposedDate', 'patchUpY2K', 'lazyAsJsDate', 'getYear', 'getMonth', 'getDay', 'getHours', 'getMinutes', 'getSeconds', 'getMilliseconds', 'getWeekday', 'valueFromDateString', 'getProperty', 'setProperty', 'functionNoSuchMethod', 'applyFunction', 'applyFunctionWithPositionalArguments', 'applyFunctionWithNamedArguments', '_mangledNameMatchesType', 'identicalImplementation', 'extractStackTrace']
  });
  Primitives.mirrorFunctionCacheName = '$cachedFunction';
  Primitives.mirrorInvokeCacheName = '$cachedInvocation';
  Primitives.DOLLAR_CHAR_VALUE = 36;
  Primitives.timerFrequency = null;
  Primitives.timerTicks = null;
  dart.defineLazyProperties(Primitives, {
    get constructorNameFallback() {
      return function getTagFallback(o) {
        var constructor = o.constructor;
        if (typeof constructor == "function") {
          var name = constructor.name;
          if (typeof name == "string" && name.length > 2 && name !== "Object" && name !== "Function.prototype") {
            return name;
          }
        }
        var s = Object.prototype.toString.call(o);
        return s.substring(8, s.length - 1);
      };
    },
    set constructorNameFallback(_) {}
  });
  class JsCache extends core.Object {
    static allocate() {
      let result = Object.create(null);
      result.x = 0;
      delete result.x;
      return result;
    }
    static fetch(cache, key) {
      return cache[key];
    }
    static update(cache, key, value) {
      cache[key] = value;
    }
  }
  dart.setSignature(JsCache, {
    statics: () => ({
      allocate: [core.Object, []],
      fetch: [core.Object, [core.Object, core.String]],
      update: [dart.void, [core.Object, core.String, core.Object]]
    }),
    names: ['allocate', 'fetch', 'update']
  });
  function iae(argument) {
    throw new core.ArgumentError(argument);
  }
  dart.fn(iae);
  function ioore(receiver, index) {
    if (receiver == null)
      dart.dload(receiver, 'length');
    if (!(typeof index == 'number'))
      iae(index);
    throw new core.RangeError.value(dart.as(index, core.num));
  }
  dart.fn(ioore);
  function stringLastIndexOfUnchecked(receiver, element, start) {
    return receiver.lastIndexOf(element, start);
  }
  dart.fn(stringLastIndexOfUnchecked);
  function checkNull(object) {
    if (object == null)
      throw new core.ArgumentError(null);
    return object;
  }
  dart.fn(checkNull);
  function checkNum(value) {
    if (!dart.is(value, core.num)) {
      throw new core.ArgumentError(value);
    }
    return value;
  }
  dart.fn(checkNum);
  function checkInt(value) {
    if (!(typeof value == 'number')) {
      throw new core.ArgumentError(value);
    }
    return value;
  }
  dart.fn(checkInt);
  function checkBool(value) {
    if (!(typeof value == 'boolean')) {
      throw new core.ArgumentError(value);
    }
    return value;
  }
  dart.fn(checkBool);
  function checkString(value) {
    if (!(typeof value == 'string')) {
      throw new core.ArgumentError(value);
    }
    return value;
  }
  dart.fn(checkString);
  function wrapException(ex) {
    if (ex == null)
      ex = new core.NullThrownError();
    let wrapper = new Error();
    wrapper.dartException = ex;
    if ("defineProperty" in Object) {
      Object.defineProperty(wrapper, "message", {get: _foreign_helper.DART_CLOSURE_TO_JS(toStringWrapper)});
      wrapper.name = "";
    } else {
      wrapper.toString = _foreign_helper.DART_CLOSURE_TO_JS(toStringWrapper);
    }
    return wrapper;
  }
  dart.fn(wrapException);
  function toStringWrapper() {
    return dart.toString(this.dartException);
  }
  dart.fn(toStringWrapper);
  function throwExpression(ex) {
    throw wrapException(ex);
  }
  dart.fn(throwExpression);
  function makeLiteralListConst(list) {
    list.immutable$list = true;
    list.fixed$length = true;
    return list;
  }
  dart.fn(makeLiteralListConst);
  function throwRuntimeError(message) {
    throw new RuntimeError(message);
  }
  dart.fn(throwRuntimeError);
  function throwAbstractClassInstantiationError(className) {
    throw new core.AbstractClassInstantiationError(dart.as(className, core.String));
  }
  dart.fn(throwAbstractClassInstantiationError);
  let _argumentsExpr = Symbol('_argumentsExpr');
  let _expr = Symbol('_expr');
  let _method = Symbol('_method');
  let _receiver = Symbol('_receiver');
  let _pattern = Symbol('_pattern');
  class TypeErrorDecoder extends core.Object {
    TypeErrorDecoder(arguments$, argumentsExpr, expr, method, receiver, pattern) {
      this[_arguments] = arguments$;
      this[_argumentsExpr] = argumentsExpr;
      this[_expr] = expr;
      this[_method] = method;
      this[_receiver] = receiver;
      this[_pattern] = pattern;
    }
    matchTypeError(message) {
      let match = new RegExp(this[_pattern]).exec(message);
      if (match == null)
        return null;
      let result = Object.create(null);
      if (this[_arguments] != -1) {
        result.arguments = match[this[_arguments] + 1];
      }
      if (this[_argumentsExpr] != -1) {
        result.argumentsExpr = match[this[_argumentsExpr] + 1];
      }
      if (this[_expr] != -1) {
        result.expr = match[this[_expr] + 1];
      }
      if (this[_method] != -1) {
        result.method = match[this[_method] + 1];
      }
      if (this[_receiver] != -1) {
        result.receiver = match[this[_receiver] + 1];
      }
      return result;
    }
    static buildJavaScriptObject() {
      return {
        toString: function() {
          return "$receiver$";
        }
      };
    }
    static buildJavaScriptObjectWithNonClosure() {
      return {
        $method$: null,
        toString: function() {
          return "$receiver$";
        }
      };
    }
    static extractPattern(message) {
      message = message.replace(String({}), '$receiver$');
      message = message.replace(new RegExp(ESCAPE_REGEXP, 'g'), '\\$&');
      let match = dart.as(message.match(/\\\$[a-zA-Z]+\\\$/g), core.List$(core.String));
      if (match == null)
        match = dart.list([], core.String);
      let arguments$ = match.indexOf('\\$arguments\\$');
      let argumentsExpr = match.indexOf('\\$argumentsExpr\\$');
      let expr = match.indexOf('\\$expr\\$');
      let method = match.indexOf('\\$method\\$');
      let receiver = match.indexOf('\\$receiver\\$');
      let pattern = message.replace('\\$arguments\\$', '((?:x|[^x])*)').replace('\\$argumentsExpr\\$', '((?:x|[^x])*)').replace('\\$expr\\$', '((?:x|[^x])*)').replace('\\$method\\$', '((?:x|[^x])*)').replace('\\$receiver\\$', '((?:x|[^x])*)');
      return new TypeErrorDecoder(arguments$, argumentsExpr, expr, method, receiver, pattern);
    }
    static provokeCallErrorOn(expression) {
      let func = function($expr$) {
        var $argumentsExpr$ = '$arguments$';
        try {
          $expr$.$method$($argumentsExpr$);
        } catch (e) {
          return e.message;
        }

      };
      return func(expression);
    }
    static provokeCallErrorOnNull() {
      let func = function() {
        var $argumentsExpr$ = '$arguments$';
        try {
          null.$method$($argumentsExpr$);
        } catch (e) {
          return e.message;
        }

      };
      return func();
    }
    static provokeCallErrorOnUndefined() {
      let func = function() {
        var $argumentsExpr$ = '$arguments$';
        try {
          (void 0).$method$($argumentsExpr$);
        } catch (e) {
          return e.message;
        }

      };
      return func();
    }
    static provokePropertyErrorOn(expression) {
      let func = function($expr$) {
        try {
          $expr$.$method$;
        } catch (e) {
          return e.message;
        }

      };
      return func(expression);
    }
    static provokePropertyErrorOnNull() {
      let func = function() {
        try {
          null.$method$;
        } catch (e) {
          return e.message;
        }

      };
      return func();
    }
    static provokePropertyErrorOnUndefined() {
      let func = function() {
        try {
          (void 0).$method$;
        } catch (e) {
          return e.message;
        }

      };
      return func();
    }
  }
  dart.setSignature(TypeErrorDecoder, {
    constructors: () => ({TypeErrorDecoder: [TypeErrorDecoder, [core.int, core.int, core.int, core.int, core.int, core.String]]}),
    methods: () => ({matchTypeError: [core.Object, [core.Object]]}),
    statics: () => ({
      buildJavaScriptObject: [core.Object, []],
      buildJavaScriptObjectWithNonClosure: [core.Object, []],
      extractPattern: [core.Object, [core.String]],
      provokeCallErrorOn: [core.String, [core.Object]],
      provokeCallErrorOnNull: [core.String, []],
      provokeCallErrorOnUndefined: [core.String, []],
      provokePropertyErrorOn: [core.String, [core.Object]],
      provokePropertyErrorOnNull: [core.String, []],
      provokePropertyErrorOnUndefined: [core.String, []]
    }),
    names: ['buildJavaScriptObject', 'buildJavaScriptObjectWithNonClosure', 'extractPattern', 'provokeCallErrorOn', 'provokeCallErrorOnNull', 'provokeCallErrorOnUndefined', 'provokePropertyErrorOn', 'provokePropertyErrorOnNull', 'provokePropertyErrorOnUndefined']
  });
  dart.defineLazyProperties(TypeErrorDecoder, {
    get noSuchMethodPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOn(TypeErrorDecoder.buildJavaScriptObject())), TypeErrorDecoder);
    },
    get notClosurePattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOn(TypeErrorDecoder.buildJavaScriptObjectWithNonClosure())), TypeErrorDecoder);
    },
    get nullCallPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOn(null)), TypeErrorDecoder);
    },
    get nullLiteralCallPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOnNull()), TypeErrorDecoder);
    },
    get undefinedCallPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOn(void 0)), TypeErrorDecoder);
    },
    get undefinedLiteralCallPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokeCallErrorOnUndefined()), TypeErrorDecoder);
    },
    get nullPropertyPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokePropertyErrorOn(null)), TypeErrorDecoder);
    },
    get nullLiteralPropertyPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokePropertyErrorOnNull()), TypeErrorDecoder);
    },
    get undefinedPropertyPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokePropertyErrorOn(void 0)), TypeErrorDecoder);
    },
    get undefinedLiteralPropertyPattern() {
      return dart.as(TypeErrorDecoder.extractPattern(TypeErrorDecoder.provokePropertyErrorOnUndefined()), TypeErrorDecoder);
    }
  });
  let _message = Symbol('_message');
  class NullError extends core.Error {
    NullError(message, match) {
      this[_message] = message;
      this[_method] = match == null ? null : dart.as(match.method, core.String);
      super.Error();
    }
    toString() {
      if (this[_method] == null)
        return `NullError: ${this[_message]}`;
      return `NullError: Cannot call "${this[_method]}" on null`;
    }
  }
  NullError[dart.implements] = () => [core.NoSuchMethodError];
  dart.setSignature(NullError, {
    constructors: () => ({NullError: [NullError, [core.String, core.Object]]})
  });
  class JsNoSuchMethodError extends core.Error {
    JsNoSuchMethodError(message, match) {
      this[_message] = message;
      this[_method] = match == null ? null : dart.as(match.method, core.String);
      this[_receiver] = match == null ? null : dart.as(match.receiver, core.String);
      super.Error();
    }
    toString() {
      if (this[_method] == null)
        return `NoSuchMethodError: ${this[_message]}`;
      if (this[_receiver] == null) {
        return `NoSuchMethodError: Cannot call "${this[_method]}" (${this[_message]})`;
      }
      return `NoSuchMethodError: Cannot call "${this[_method]}" on "${this[_receiver]}" ` + `(${this[_message]})`;
    }
  }
  JsNoSuchMethodError[dart.implements] = () => [core.NoSuchMethodError];
  dart.setSignature(JsNoSuchMethodError, {
    constructors: () => ({JsNoSuchMethodError: [JsNoSuchMethodError, [core.String, core.Object]]})
  });
  class UnknownJsTypeError extends core.Error {
    UnknownJsTypeError(message) {
      this[_message] = message;
      super.Error();
    }
    toString() {
      return this[_message][dartx.isEmpty] ? 'Error' : `Error: ${this[_message]}`;
    }
  }
  dart.setSignature(UnknownJsTypeError, {
    constructors: () => ({UnknownJsTypeError: [UnknownJsTypeError, [core.String]]})
  });
  function unwrapException(ex) {
    let saveStackTrace = error => {
      if (dart.is(error, core.Error)) {
        let thrownStackTrace = error.$thrownJsError;
        if (thrownStackTrace == null) {
          error.$thrownJsError = ex;
        }
      }
      return error;
    };
    dart.fn(saveStackTrace);
    if (ex == null)
      return null;
    if (typeof ex !== "object")
      return ex;
    if ("dartException" in ex) {
      return saveStackTrace(ex.dartException);
    } else if (!("message" in ex)) {
      return ex;
    }
    let message = ex.message;
    if ("number" in ex && typeof ex.number == "number") {
      let number = ex.number;
      let ieErrorCode = dart.notNull(number) & 65535;
      let ieFacilityNumber = dart.notNull(number) >> 16 & 8191;
      if (ieFacilityNumber == 10) {
        switch (ieErrorCode) {
          case 438:
          {
            return saveStackTrace(new JsNoSuchMethodError(`${message} (Error ${ieErrorCode})`, null));
          }
          case 445:
          case 5007:
          {
            return saveStackTrace(new NullError(`${message} (Error ${ieErrorCode})`, null));
          }
        }
      }
    }
    if (ex instanceof TypeError) {
      let match = null;
      let nsme = TypeErrorDecoder.noSuchMethodPattern;
      let notClosure = TypeErrorDecoder.notClosurePattern;
      let nullCall = TypeErrorDecoder.nullCallPattern;
      let nullLiteralCall = TypeErrorDecoder.nullLiteralCallPattern;
      let undefCall = TypeErrorDecoder.undefinedCallPattern;
      let undefLiteralCall = TypeErrorDecoder.undefinedLiteralCallPattern;
      let nullProperty = TypeErrorDecoder.nullPropertyPattern;
      let nullLiteralProperty = TypeErrorDecoder.nullLiteralPropertyPattern;
      let undefProperty = TypeErrorDecoder.undefinedPropertyPattern;
      let undefLiteralProperty = TypeErrorDecoder.undefinedLiteralPropertyPattern;
      if ((match = dart.dsend(nsme, 'matchTypeError', message)) != null) {
        return saveStackTrace(new JsNoSuchMethodError(dart.as(message, core.String), match));
      } else if ((match = dart.dsend(notClosure, 'matchTypeError', message)) != null) {
        match.method = "call";
        return saveStackTrace(new JsNoSuchMethodError(dart.as(message, core.String), match));
      } else if (dart.notNull((match = dart.dsend(nullCall, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(nullLiteralCall, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(undefCall, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(undefLiteralCall, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(nullProperty, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(nullLiteralCall, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(undefProperty, 'matchTypeError', message)) != null) || dart.notNull((match = dart.dsend(undefLiteralProperty, 'matchTypeError', message)) != null)) {
        return saveStackTrace(new NullError(dart.as(message, core.String), match));
      }
      return saveStackTrace(new UnknownJsTypeError(typeof message == 'string' ? dart.as(message, core.String) : ''));
    }
    if (ex instanceof RangeError) {
      if (typeof message == 'string' && dart.notNull(contains(dart.as(message, core.String), 'call stack'))) {
        return new core.StackOverflowError();
      }
      return saveStackTrace(new core.ArgumentError());
    }
    if (typeof InternalError == "function" && ex instanceof InternalError) {
      if (typeof message == 'string' && dart.notNull(dart.equals(message, 'too much recursion'))) {
        return new core.StackOverflowError();
      }
    }
    return ex;
  }
  dart.fn(unwrapException);
  function getTraceFromException(exception) {
    return new _StackTrace(exception);
  }
  dart.fn(getTraceFromException, core.StackTrace, [core.Object]);
  let _exception = Symbol('_exception');
  let _trace = Symbol('_trace');
  class _StackTrace extends core.Object {
    _StackTrace(exception) {
      this[_exception] = exception;
      this[_trace] = null;
    }
    toString() {
      if (this[_trace] != null)
        return this[_trace];
      let trace = null;
      if (typeof this[_exception] === "object") {
        trace = dart.as(this[_exception].stack, core.String);
      }
      return this[_trace] = trace == null ? '' : trace;
    }
  }
  _StackTrace[dart.implements] = () => [core.StackTrace];
  dart.setSignature(_StackTrace, {
    constructors: () => ({_StackTrace: [_StackTrace, [core.Object]]})
  });
  function objectHashCode(object) {
    if (dart.notNull(object == null) || typeof object != 'object') {
      return dart.hashCode(object);
    } else {
      return Primitives.objectHashCode(object);
    }
  }
  dart.fn(objectHashCode, core.int, [core.Object]);
  function fillLiteralMap(keyValuePairs, result) {
    let index = 0;
    let length = getLength(keyValuePairs);
    while (dart.notNull(index) < dart.notNull(length)) {
      let key = getIndex(keyValuePairs, (() => {
        let x = index;
        index = dart.notNull(x) + 1;
        return x;
      })());
      let value = getIndex(keyValuePairs, (() => {
        let x = index;
        index = dart.notNull(x) + 1;
        return x;
      })());
      result.set(key, value);
    }
    return result;
  }
  dart.fn(fillLiteralMap, core.Object, [core.Object, core.Map]);
  function invokeClosure(closure, isolate, numberOfArguments, arg1, arg2, arg3, arg4) {
    if (numberOfArguments == 0) {
      return _foreign_helper.JS_CALL_IN_ISOLATE(isolate, dart.fn(() => dart.dcall(closure)));
    } else if (numberOfArguments == 1) {
      return _foreign_helper.JS_CALL_IN_ISOLATE(isolate, dart.fn(() => dart.dcall(closure, arg1)));
    } else if (numberOfArguments == 2) {
      return _foreign_helper.JS_CALL_IN_ISOLATE(isolate, dart.fn(() => dart.dcall(closure, arg1, arg2)));
    } else if (numberOfArguments == 3) {
      return _foreign_helper.JS_CALL_IN_ISOLATE(isolate, dart.fn(() => dart.dcall(closure, arg1, arg2, arg3)));
    } else if (numberOfArguments == 4) {
      return _foreign_helper.JS_CALL_IN_ISOLATE(isolate, dart.fn(() => dart.dcall(closure, arg1, arg2, arg3, arg4)));
    } else {
      throw core.Exception.new('Unsupported number of arguments for wrapped closure');
    }
  }
  dart.fn(invokeClosure, core.Object, [core.Function, core.Object, core.int, core.Object, core.Object, core.Object, core.Object]);
  function convertDartClosureToJS(closure, arity) {
    return closure;
  }
  dart.fn(convertDartClosureToJS, core.Object, [core.Object, core.int]);
  class Closure extends core.Object {
    Closure() {
    }
    static fromTearOff(receiver, functions, reflectionInfo, isStatic, jsArguments, propertyName) {
      _foreign_helper.JS_EFFECT(dart.fn(() => {
        BoundClosure.receiverOf(dart.as(void 0, BoundClosure));
        BoundClosure.selfOf(dart.as(void 0, BoundClosure));
      }));
      let func = functions[0];
      let name = dart.as(func.$stubName, core.String);
      let callName = dart.as(func.$callName, core.String);
      func.$reflectionInfo = reflectionInfo;
      let info = ReflectionInfo.new(func);
      let functionType = info.functionType;
      let prototype = isStatic ? Object.create(new TearOffClosure().constructor.prototype) : Object.create(new BoundClosure(null, null, null, null).constructor.prototype);
      prototype.$initialize = prototype.constructor;
      let constructor = isStatic ? function() {
        this.$initialize();
      } : Closure.isCsp ? function(a, b, c, d) {
        this.$initialize(a, b, c, d);
      } : new Function("a", "b", "c", "d", "this.$initialize(a,b,c,d);" + (() => {
        let x = Closure.functionCounter;
        Closure.functionCounter = dart.notNull(x) + 1;
        return x;
      })());
      prototype.constructor = constructor;
      constructor.prototype = prototype;
      let trampoline = func;
      let isIntercepted = false;
      if (!dart.notNull(isStatic)) {
        if (jsArguments.length == 1) {
          isIntercepted = true;
        }
        trampoline = Closure.forwardCallTo(receiver, func, isIntercepted);
        trampoline.$reflectionInfo = reflectionInfo;
      } else {
        prototype.$name = propertyName;
      }
      let signatureFunction = null;
      if (typeof functionType == "number") {
        let metadata = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.METADATA);
        signatureFunction = function(s) {
          return function() {
            return metadata[s];
          };
        }(functionType);
      } else if (!dart.notNull(isStatic) && typeof functionType == "function") {
        let getReceiver = isIntercepted ? _foreign_helper.RAW_DART_FUNCTION_REF(BoundClosure.receiverOf) : _foreign_helper.RAW_DART_FUNCTION_REF(BoundClosure.selfOf);
        signatureFunction = function(f, r) {
          return function() {
            return f.apply({$receiver: r(this)}, arguments$);
          };
        }(functionType, getReceiver);
      } else {
        throw 'Error in reflectionInfo.';
      }
      prototype[_foreign_helper.JS_SIGNATURE_NAME()] = signatureFunction;
      prototype[callName] = trampoline;
      for (let i = 1; dart.notNull(i) < dart.notNull(functions.length); i = dart.notNull(i) + 1) {
        let stub = functions[dartx.get](i);
        let stubCallName = stub.$callName;
        if (stubCallName != null) {
          prototype[stubCallName] = isStatic ? stub : Closure.forwardCallTo(receiver, stub, isIntercepted);
        }
      }
      prototype["call*"] = trampoline;
      return constructor;
    }
    static cspForwardCall(arity, isSuperCall, stubName, func) {
      let getSelf = _foreign_helper.RAW_DART_FUNCTION_REF(BoundClosure.selfOf);
      if (isSuperCall)
        arity = -1;
      switch (arity) {
        case 0:
        {
          return function(n, S) {
            return function() {
              return S(this)[n]();
            };
          }(stubName, getSelf);
        }
        case 1:
        {
          return function(n, S) {
            return function(a) {
              return S(this)[n](a);
            };
          }(stubName, getSelf);
        }
        case 2:
        {
          return function(n, S) {
            return function(a, b) {
              return S(this)[n](a, b);
            };
          }(stubName, getSelf);
        }
        case 3:
        {
          return function(n, S) {
            return function(a, b, c) {
              return S(this)[n](a, b, c);
            };
          }(stubName, getSelf);
        }
        case 4:
        {
          return function(n, S) {
            return function(a, b, c, d) {
              return S(this)[n](a, b, c, d);
            };
          }(stubName, getSelf);
        }
        case 5:
        {
          return function(n, S) {
            return function(a, b, c, d, e) {
              return S(this)[n](a, b, c, d, e);
            };
          }(stubName, getSelf);
        }
        default:
        {
          return function(f, s) {
            return function() {
              return f.apply(s(this), arguments$);
            };
          }(func, getSelf);
        }
      }
    }
    static get isCsp() {
      return typeof dart_precompiled == "function";
    }
    static forwardCallTo(receiver, func, isIntercepted) {
      if (isIntercepted)
        return Closure.forwardInterceptedCallTo(receiver, func);
      let stubName = dart.as(func.$stubName, core.String);
      let arity = func.length;
      let lookedUpFunction = receiver[stubName];
      let isSuperCall = !dart.notNull(core.identical(func, lookedUpFunction));
      if (dart.notNull(Closure.isCsp) || dart.notNull(isSuperCall) || dart.notNull(arity) >= 27) {
        return Closure.cspForwardCall(arity, isSuperCall, stubName, func);
      }
      if (arity == 0) {
        return new Function('return function(){' + `return this.${BoundClosure.selfFieldName()}.${stubName}();` + `${(() => {
          let x = Closure.functionCounter;
          Closure.functionCounter = dart.notNull(x) + 1;
          return x;
        })()}` + '}')();
      }
      dart.assert(1 <= dart.notNull(arity) && dart.notNull(arity) < 27);
      let arguments$ = "abcdefghijklmnopqrstuvwxyz".split("").splice(0, arity).join(",");
      return new Function(`return function(${arguments$}){` + `return this.${BoundClosure.selfFieldName()}.${stubName}(${arguments$});` + `${(() => {
        let x = Closure.functionCounter;
        Closure.functionCounter = dart.notNull(x) + 1;
        return x;
      })()}` + '}')();
    }
    static cspForwardInterceptedCall(arity, isSuperCall, name, func) {
      let getSelf = _foreign_helper.RAW_DART_FUNCTION_REF(BoundClosure.selfOf);
      let getReceiver = _foreign_helper.RAW_DART_FUNCTION_REF(BoundClosure.receiverOf);
      if (isSuperCall)
        arity = -1;
      switch (arity) {
        case 0:
        {
          throw new RuntimeError('Intercepted function with no arguments.');
        }
        case 1:
        {
          return function(n, s, r) {
            return function() {
              return s(this)[n](r(this));
            };
          }(name, getSelf, getReceiver);
        }
        case 2:
        {
          return function(n, s, r) {
            return function(a) {
              return s(this)[n](r(this), a);
            };
          }(name, getSelf, getReceiver);
        }
        case 3:
        {
          return function(n, s, r) {
            return function(a, b) {
              return s(this)[n](r(this), a, b);
            };
          }(name, getSelf, getReceiver);
        }
        case 4:
        {
          return function(n, s, r) {
            return function(a, b, c) {
              return s(this)[n](r(this), a, b, c);
            };
          }(name, getSelf, getReceiver);
        }
        case 5:
        {
          return function(n, s, r) {
            return function(a, b, c, d) {
              return s(this)[n](r(this), a, b, c, d);
            };
          }(name, getSelf, getReceiver);
        }
        case 6:
        {
          return function(n, s, r) {
            return function(a, b, c, d, e) {
              return s(this)[n](r(this), a, b, c, d, e);
            };
          }(name, getSelf, getReceiver);
        }
        default:
        {
          return function(f, s, r, a) {
            return function() {
              a = [r(this)];
              Array.prototype.push.apply(a, arguments$);
              return f.apply(s(this), a);
            };
          }(func, getSelf, getReceiver);
        }
      }
    }
    static forwardInterceptedCallTo(receiver, func) {
      let selfField = BoundClosure.selfFieldName();
      let receiverField = BoundClosure.receiverFieldName();
      let stubName = dart.as(func.$stubName, core.String);
      let arity = func.length;
      let isCsp = typeof dart_precompiled == "function";
      let lookedUpFunction = receiver[stubName];
      let isSuperCall = !dart.notNull(core.identical(func, lookedUpFunction));
      if (dart.notNull(isCsp) || dart.notNull(isSuperCall) || dart.notNull(arity) >= 28) {
        return Closure.cspForwardInterceptedCall(arity, isSuperCall, stubName, func);
      }
      if (arity == 1) {
        return new Function('return function(){' + `return this.${selfField}.${stubName}(this.${receiverField});` + `${(() => {
          let x = Closure.functionCounter;
          Closure.functionCounter = dart.notNull(x) + 1;
          return x;
        })()}` + '}')();
      }
      dart.assert(1 < dart.notNull(arity) && dart.notNull(arity) < 28);
      let arguments$ = "abcdefghijklmnopqrstuvwxyz".split("").splice(0, dart.notNull(arity) - 1).join(",");
      return new Function(`return function(${arguments$}){` + `return this.${selfField}.${stubName}(this.${receiverField}, ${arguments$});` + `${(() => {
        let x = Closure.functionCounter;
        Closure.functionCounter = dart.notNull(x) + 1;
        return x;
      })()}` + '}')();
    }
    toString() {
      return "Closure";
    }
  }
  Closure[dart.implements] = () => [core.Function];
  dart.setSignature(Closure, {
    constructors: () => ({Closure: [Closure, []]}),
    statics: () => ({
      fromTearOff: [core.Object, [core.Object, core.List, core.List, core.bool, core.Object, core.String]],
      cspForwardCall: [core.Object, [core.int, core.bool, core.String, core.Object]],
      forwardCallTo: [core.Object, [core.Object, core.Object, core.bool]],
      cspForwardInterceptedCall: [core.Object, [core.int, core.bool, core.String, core.Object]],
      forwardInterceptedCallTo: [core.Object, [core.Object, core.Object]]
    }),
    names: ['fromTearOff', 'cspForwardCall', 'forwardCallTo', 'cspForwardInterceptedCall', 'forwardInterceptedCallTo']
  });
  Closure.FUNCTION_INDEX = 0;
  Closure.NAME_INDEX = 1;
  Closure.CALL_NAME_INDEX = 2;
  Closure.REQUIRED_PARAMETER_INDEX = 3;
  Closure.OPTIONAL_PARAMETER_INDEX = 4;
  Closure.DEFAULT_ARGUMENTS_INDEX = 5;
  Closure.functionCounter = 0;
  function closureFromTearOff(receiver, functions, reflectionInfo, isStatic, jsArguments, name) {
    return Closure.fromTearOff(receiver, _interceptors.JSArray.markFixedList(dart.as(functions, core.List)), _interceptors.JSArray.markFixedList(dart.as(reflectionInfo, core.List)), !!isStatic, jsArguments, name);
  }
  dart.fn(closureFromTearOff);
  class TearOffClosure extends Closure {
    TearOffClosure() {
      super.Closure();
    }
  }
  let _self = Symbol('_self');
  let _target = Symbol('_target');
  let _name = Symbol('_name');
  class BoundClosure extends TearOffClosure {
    BoundClosure(self, target, receiver, name) {
      this[_self] = self;
      this[_target] = target;
      this[_receiver] = receiver;
      this[_name] = name;
    }
    ['=='](other) {
      if (core.identical(this, other))
        return true;
      if (!dart.is(other, BoundClosure))
        return false;
      return this[_self] === dart.dload(other, _self) && this[_target] === dart.dload(other, _target) && this[_receiver] === dart.dload(other, _receiver);
    }
    get hashCode() {
      let receiverHashCode = null;
      if (this[_receiver] == null) {
        receiverHashCode = Primitives.objectHashCode(this[_self]);
      } else if (typeof this[_receiver] != 'object') {
        receiverHashCode = dart.hashCode(this[_receiver]);
      } else {
        receiverHashCode = Primitives.objectHashCode(this[_receiver]);
      }
      return dart.notNull(receiverHashCode) ^ dart.notNull(Primitives.objectHashCode(this[_target]));
    }
    static selfOf(closure) {
      return closure[_self];
    }
    static targetOf(closure) {
      return closure[_target];
    }
    static receiverOf(closure) {
      return closure[_receiver];
    }
    static nameOf(closure) {
      return closure[_name];
    }
    static selfFieldName() {
      if (BoundClosure.selfFieldNameCache == null) {
        BoundClosure.selfFieldNameCache = BoundClosure.computeFieldNamed('self');
      }
      return BoundClosure.selfFieldNameCache;
    }
    static receiverFieldName() {
      if (BoundClosure.receiverFieldNameCache == null) {
        BoundClosure.receiverFieldNameCache = BoundClosure.computeFieldNamed('receiver');
      }
      return BoundClosure.receiverFieldNameCache;
    }
    static computeFieldNamed(fieldName) {
      let template = new BoundClosure('self', 'target', 'receiver', 'name');
      let names = _interceptors.JSArray.markFixedList(dart.as(Object.getOwnPropertyNames(template), core.List));
      for (let i = 0; dart.notNull(i) < dart.notNull(names.length); i = dart.notNull(i) + 1) {
        let name = names[dartx.get](i);
        if (template[name] === fieldName) {
          return name;
        }
      }
    }
  }
  dart.setSignature(BoundClosure, {
    constructors: () => ({BoundClosure: [BoundClosure, [core.Object, core.Object, core.Object, core.String]]}),
    statics: () => ({
      selfOf: [core.Object, [BoundClosure]],
      targetOf: [core.Object, [BoundClosure]],
      receiverOf: [core.Object, [BoundClosure]],
      nameOf: [core.Object, [BoundClosure]],
      selfFieldName: [core.String, []],
      receiverFieldName: [core.String, []],
      computeFieldNamed: [core.String, [core.String]]
    }),
    names: ['selfOf', 'targetOf', 'receiverOf', 'nameOf', 'selfFieldName', 'receiverFieldName', 'computeFieldNamed']
  });
  BoundClosure.selfFieldNameCache = null;
  BoundClosure.receiverFieldNameCache = null;
  function jsHasOwnProperty(jsObject, property) {
    return jsObject.hasOwnProperty(property);
  }
  dart.fn(jsHasOwnProperty, core.bool, [core.Object, core.String]);
  function jsPropertyAccess(jsObject, property) {
    return jsObject[property];
  }
  dart.fn(jsPropertyAccess, core.Object, [core.Object, core.String]);
  function getFallThroughError() {
    return new FallThroughErrorImplementation();
  }
  dart.fn(getFallThroughError);
  class Creates extends core.Object {
    Creates(types) {
      this.types = types;
    }
  }
  dart.setSignature(Creates, {
    constructors: () => ({Creates: [Creates, [core.String]]})
  });
  class Returns extends core.Object {
    Returns(types) {
      this.types = types;
    }
  }
  dart.setSignature(Returns, {
    constructors: () => ({Returns: [Returns, [core.String]]})
  });
  class JSName extends core.Object {
    JSName(name) {
      this.name = name;
    }
  }
  dart.setSignature(JSName, {
    constructors: () => ({JSName: [JSName, [core.String]]})
  });
  function boolConversionCheck(value) {
    if (typeof value == 'boolean')
      return value;
    boolTypeCheck(value);
    dart.assert(value != null);
    return false;
  }
  dart.fn(boolConversionCheck);
  function stringTypeCheck(value) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    throw new TypeErrorImplementation(value, 'String');
  }
  dart.fn(stringTypeCheck);
  function stringTypeCast(value) {
    if (typeof value == 'string' || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'String');
  }
  dart.fn(stringTypeCast);
  function doubleTypeCheck(value) {
    if (value == null)
      return value;
    if (typeof value == 'number')
      return value;
    throw new TypeErrorImplementation(value, 'double');
  }
  dart.fn(doubleTypeCheck);
  function doubleTypeCast(value) {
    if (typeof value == 'number' || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'double');
  }
  dart.fn(doubleTypeCast);
  function numTypeCheck(value) {
    if (value == null)
      return value;
    if (dart.is(value, core.num))
      return value;
    throw new TypeErrorImplementation(value, 'num');
  }
  dart.fn(numTypeCheck);
  function numTypeCast(value) {
    if (dart.is(value, core.num) || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'num');
  }
  dart.fn(numTypeCast);
  function boolTypeCheck(value) {
    if (value == null)
      return value;
    if (typeof value == 'boolean')
      return value;
    throw new TypeErrorImplementation(value, 'bool');
  }
  dart.fn(boolTypeCheck);
  function boolTypeCast(value) {
    if (typeof value == 'boolean' || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'bool');
  }
  dart.fn(boolTypeCast);
  function intTypeCheck(value) {
    if (value == null)
      return value;
    if (typeof value == 'number')
      return value;
    throw new TypeErrorImplementation(value, 'int');
  }
  dart.fn(intTypeCheck);
  function intTypeCast(value) {
    if (typeof value == 'number' || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'int');
  }
  dart.fn(intTypeCast);
  function propertyTypeError(value, property) {
    let name = dart.as(dart.dsend(property, 'substring', 3, dart.dload(property, 'length')), core.String);
    throw new TypeErrorImplementation(value, name);
  }
  dart.fn(propertyTypeError, dart.void, [core.Object, core.Object]);
  function propertyTypeCastError(value, property) {
    let actualType = Primitives.objectTypeName(value);
    let expectedType = dart.as(dart.dsend(property, 'substring', 3, dart.dload(property, 'length')), core.String);
    throw new CastErrorImplementation(actualType, expectedType);
  }
  dart.fn(propertyTypeCastError, dart.void, [core.Object, core.Object]);
  function propertyTypeCheck(value, property) {
    if (value == null)
      return value;
    if (!!value[property])
      return value;
    propertyTypeError(value, property);
  }
  dart.fn(propertyTypeCheck);
  function propertyTypeCast(value, property) {
    if (dart.notNull(value == null) || !!value[property])
      return value;
    propertyTypeCastError(value, property);
  }
  dart.fn(propertyTypeCast);
  function interceptedTypeCheck(value, property) {
    if (value == null)
      return value;
    if (dart.notNull(core.identical(typeof value, 'object')) && _interceptors.getInterceptor(value)[property]) {
      return value;
    }
    propertyTypeError(value, property);
  }
  dart.fn(interceptedTypeCheck);
  function interceptedTypeCast(value, property) {
    if (dart.notNull(value == null) || typeof value === "object" && _interceptors.getInterceptor(value)[property]) {
      return value;
    }
    propertyTypeCastError(value, property);
  }
  dart.fn(interceptedTypeCast);
  function numberOrStringSuperTypeCheck(value, property) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    if (dart.is(value, core.num))
      return value;
    if (!!value[property])
      return value;
    propertyTypeError(value, property);
  }
  dart.fn(numberOrStringSuperTypeCheck);
  function numberOrStringSuperTypeCast(value, property) {
    if (typeof value == 'string')
      return value;
    if (dart.is(value, core.num))
      return value;
    return propertyTypeCast(value, property);
  }
  dart.fn(numberOrStringSuperTypeCast);
  function numberOrStringSuperNativeTypeCheck(value, property) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    if (dart.is(value, core.num))
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeError(value, property);
  }
  dart.fn(numberOrStringSuperNativeTypeCheck);
  function numberOrStringSuperNativeTypeCast(value, property) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    if (dart.is(value, core.num))
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeCastError(value, property);
  }
  dart.fn(numberOrStringSuperNativeTypeCast);
  function stringSuperTypeCheck(value, property) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    if (!!value[property])
      return value;
    propertyTypeError(value, property);
  }
  dart.fn(stringSuperTypeCheck);
  function stringSuperTypeCast(value, property) {
    if (typeof value == 'string')
      return value;
    return propertyTypeCast(value, property);
  }
  dart.fn(stringSuperTypeCast);
  function stringSuperNativeTypeCheck(value, property) {
    if (value == null)
      return value;
    if (typeof value == 'string')
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeError(value, property);
  }
  dart.fn(stringSuperNativeTypeCheck);
  function stringSuperNativeTypeCast(value, property) {
    if (typeof value == 'string' || dart.notNull(value == null))
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeCastError(value, property);
  }
  dart.fn(stringSuperNativeTypeCast);
  function listTypeCheck(value) {
    if (value == null)
      return value;
    if (dart.is(value, core.List))
      return value;
    throw new TypeErrorImplementation(value, 'List');
  }
  dart.fn(listTypeCheck);
  function listTypeCast(value) {
    if (dart.is(value, core.List) || dart.notNull(value == null))
      return value;
    throw new CastErrorImplementation(Primitives.objectTypeName(value), 'List');
  }
  dart.fn(listTypeCast);
  function listSuperTypeCheck(value, property) {
    if (value == null)
      return value;
    if (dart.is(value, core.List))
      return value;
    if (!!value[property])
      return value;
    propertyTypeError(value, property);
  }
  dart.fn(listSuperTypeCheck);
  function listSuperTypeCast(value, property) {
    if (dart.is(value, core.List))
      return value;
    return propertyTypeCast(value, property);
  }
  dart.fn(listSuperTypeCast);
  function listSuperNativeTypeCheck(value, property) {
    if (value == null)
      return value;
    if (dart.is(value, core.List))
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeError(value, property);
  }
  dart.fn(listSuperNativeTypeCheck);
  function listSuperNativeTypeCast(value, property) {
    if (dart.is(value, core.List) || dart.notNull(value == null))
      return value;
    if (_interceptors.getInterceptor(value)[property])
      return value;
    propertyTypeCastError(value, property);
  }
  dart.fn(listSuperNativeTypeCast);
  function voidTypeCheck(value) {
    if (value == null)
      return value;
    throw new TypeErrorImplementation(value, 'void');
  }
  dart.fn(voidTypeCheck);
  function checkMalformedType(value, message) {
    if (value == null)
      return value;
    throw new TypeErrorImplementation.fromMessage(dart.as(message, core.String));
  }
  dart.fn(checkMalformedType);
  function checkDeferredIsLoaded(loadId, uri) {
    if (!dart.notNull(exports._loadedLibraries.contains(loadId))) {
      throw new DeferredNotLoadedError(uri);
    }
  }
  dart.fn(checkDeferredIsLoaded, dart.void, [core.String, core.String]);
  dart.defineLazyClass(exports, {
    get JavaScriptIndexingBehavior() {
      class JavaScriptIndexingBehavior extends _interceptors.JSMutableIndexable {}
      return JavaScriptIndexingBehavior;
    }
  });
  class TypeErrorImplementation extends core.Error {
    TypeErrorImplementation(value, type) {
      this.message = `type '${Primitives.objectTypeName(value)}' is not a subtype ` + `of type '${type}'`;
      super.Error();
    }
    fromMessage(message) {
      this.message = message;
      super.Error();
    }
    toString() {
      return this.message;
    }
  }
  TypeErrorImplementation[dart.implements] = () => [core.TypeError];
  dart.defineNamedConstructor(TypeErrorImplementation, 'fromMessage');
  dart.setSignature(TypeErrorImplementation, {
    constructors: () => ({
      TypeErrorImplementation: [TypeErrorImplementation, [core.Object, core.String]],
      fromMessage: [TypeErrorImplementation, [core.String]]
    })
  });
  class CastErrorImplementation extends core.Error {
    CastErrorImplementation(actualType, expectedType) {
      this.message = `CastError: Casting value of type ${actualType} to` + ` incompatible type ${expectedType}`;
      super.Error();
    }
    toString() {
      return this.message;
    }
  }
  CastErrorImplementation[dart.implements] = () => [core.CastError];
  dart.setSignature(CastErrorImplementation, {
    constructors: () => ({CastErrorImplementation: [CastErrorImplementation, [core.Object, core.Object]]})
  });
  class FallThroughErrorImplementation extends core.FallThroughError {
    FallThroughErrorImplementation() {
      super.FallThroughError();
    }
    toString() {
      return "Switch case fall-through.";
    }
  }
  dart.setSignature(FallThroughErrorImplementation, {
    constructors: () => ({FallThroughErrorImplementation: [FallThroughErrorImplementation, []]})
  });
  function assertHelper(condition) {
    if (!(typeof condition == 'boolean')) {
      if (dart.is(condition, core.Function))
        condition = dart.dcall(condition);
      if (!(typeof condition == 'boolean')) {
        throw new TypeErrorImplementation(condition, 'bool');
      }
    }
    if (!dart.equals(true, condition))
      throw new core.AssertionError();
  }
  dart.fn(assertHelper, dart.void, [core.Object]);
  function throwNoSuchMethod(obj, name, arguments$, expectedArgumentNames) {
    let memberName = new _internal.Symbol.unvalidated(dart.as(name, core.String));
    throw new core.NoSuchMethodError(obj, memberName, dart.as(arguments$, core.List), core.Map$(core.Symbol, core.Object).new(), dart.as(expectedArgumentNames, core.List));
  }
  dart.fn(throwNoSuchMethod, dart.void, [core.Object, core.Object, core.Object, core.Object]);
  function throwCyclicInit(staticName) {
    throw new core.CyclicInitializationError(`Cyclic initialization for static ${staticName}`);
  }
  dart.fn(throwCyclicInit, dart.void, [core.String]);
  class RuntimeError extends core.Error {
    RuntimeError(message) {
      this.message = message;
      super.Error();
    }
    toString() {
      return `RuntimeError: ${this.message}`;
    }
  }
  dart.setSignature(RuntimeError, {
    constructors: () => ({RuntimeError: [RuntimeError, [core.Object]]})
  });
  class DeferredNotLoadedError extends core.Error {
    DeferredNotLoadedError(libraryName) {
      this.libraryName = libraryName;
      super.Error();
    }
    toString() {
      return `Deferred library ${this.libraryName} was not loaded.`;
    }
  }
  DeferredNotLoadedError[dart.implements] = () => [core.NoSuchMethodError];
  dart.setSignature(DeferredNotLoadedError, {
    constructors: () => ({DeferredNotLoadedError: [DeferredNotLoadedError, [core.String]]})
  });
  class RuntimeType extends core.Object {
    RuntimeType() {
    }
  }
  dart.setSignature(RuntimeType, {
    constructors: () => ({RuntimeType: [RuntimeType, []]})
  });
  let _isTest = Symbol('_isTest');
  let _extractFunctionTypeObjectFrom = Symbol('_extractFunctionTypeObjectFrom');
  let _asCheck = Symbol('_asCheck');
  let _check = Symbol('_check');
  let _assertCheck = Symbol('_assertCheck');
  class RuntimeFunctionType extends RuntimeType {
    RuntimeFunctionType(returnType, parameterTypes, optionalParameterTypes, namedParameters) {
      this.returnType = returnType;
      this.parameterTypes = parameterTypes;
      this.optionalParameterTypes = optionalParameterTypes;
      this.namedParameters = namedParameters;
      super.RuntimeType();
    }
    get isVoid() {
      return dart.is(this.returnType, VoidRuntimeType);
    }
    [_isTest](expression) {
      let functionTypeObject = this[_extractFunctionTypeObjectFrom](expression);
      return functionTypeObject == null ? false : isFunctionSubtype(functionTypeObject, this.toRti());
    }
    [_asCheck](expression) {
      return this[_check](expression, true);
    }
    [_assertCheck](expression) {
      if (RuntimeFunctionType.inAssert)
        return null;
      RuntimeFunctionType.inAssert = true;
      try {
        return this[_check](expression, false);
      } finally {
        RuntimeFunctionType.inAssert = false;
      }
    }
    [_check](expression, isCast) {
      if (expression == null)
        return null;
      if (this[_isTest](expression))
        return expression;
      let self = dart.toString(new FunctionTypeInfoDecoderRing(this.toRti()));
      if (isCast) {
        let functionTypeObject = this[_extractFunctionTypeObjectFrom](expression);
        let pretty = null;
        if (functionTypeObject != null) {
          pretty = dart.toString(new FunctionTypeInfoDecoderRing(functionTypeObject));
        } else {
          pretty = Primitives.objectTypeName(expression);
        }
        throw new CastErrorImplementation(pretty, self);
      } else {
        throw new TypeErrorImplementation(expression, self);
      }
    }
    [_extractFunctionTypeObjectFrom](o) {
      let interceptor = _interceptors.getInterceptor(o);
      return _foreign_helper.JS_SIGNATURE_NAME() in interceptor ? interceptor[_foreign_helper.JS_SIGNATURE_NAME()]() : null;
    }
    toRti() {
      let result = {[_foreign_helper.JS_FUNCTION_TYPE_TAG()]: "dynafunc"};
      if (this.isVoid) {
        result[_foreign_helper.JS_FUNCTION_TYPE_VOID_RETURN_TAG()] = true;
      } else {
        if (!dart.is(this.returnType, DynamicRuntimeType)) {
          result[_foreign_helper.JS_FUNCTION_TYPE_RETURN_TYPE_TAG()] = this.returnType.toRti();
        }
      }
      if (dart.notNull(this.parameterTypes != null) && !dart.notNull(this.parameterTypes[dartx.isEmpty])) {
        result[_foreign_helper.JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG()] = RuntimeFunctionType.listToRti(this.parameterTypes);
      }
      if (dart.notNull(this.optionalParameterTypes != null) && !dart.notNull(this.optionalParameterTypes[dartx.isEmpty])) {
        result[_foreign_helper.JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG()] = RuntimeFunctionType.listToRti(this.optionalParameterTypes);
      }
      if (this.namedParameters != null) {
        let namedRti = Object.create(null);
        let keys = _js_names.extractKeys(this.namedParameters);
        for (let i = 0; dart.notNull(i) < dart.notNull(keys.length); i = dart.notNull(i) + 1) {
          let name = keys[dartx.get](i);
          let rti = dart.dsend(this.namedParameters[name], 'toRti');
          namedRti[name] = rti;
        }
        result[_foreign_helper.JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG()] = namedRti;
      }
      return result;
    }
    static listToRti(list) {
      list = list;
      let result = [];
      for (let i = 0; dart.notNull(i) < dart.notNull(dart.as(dart.dload(list, 'length'), core.num)); i = dart.notNull(i) + 1) {
        result.push(dart.dsend(dart.dindex(list, i), 'toRti'));
      }
      return result;
    }
    toString() {
      let result = '(';
      let needsComma = false;
      if (this.parameterTypes != null) {
        for (let i = 0; dart.notNull(i) < dart.notNull(this.parameterTypes.length); i = dart.notNull(i) + 1) {
          let type = this.parameterTypes[dartx.get](i);
          if (needsComma) {
            result = dart.notNull(result) + ', ';
          }
          result = dart.notNull(result) + `${type}`;
          needsComma = true;
        }
      }
      if (dart.notNull(this.optionalParameterTypes != null) && !dart.notNull(this.optionalParameterTypes[dartx.isEmpty])) {
        if (needsComma) {
          result = dart.notNull(result) + ', ';
        }
        needsComma = false;
        result = dart.notNull(result) + '[';
        for (let i = 0; dart.notNull(i) < dart.notNull(this.optionalParameterTypes.length); i = dart.notNull(i) + 1) {
          let type = this.optionalParameterTypes[dartx.get](i);
          if (needsComma) {
            result = dart.notNull(result) + ', ';
          }
          result = dart.notNull(result) + `${type}`;
          needsComma = true;
        }
        result = dart.notNull(result) + ']';
      } else if (this.namedParameters != null) {
        if (needsComma) {
          result = dart.notNull(result) + ', ';
        }
        needsComma = false;
        result = dart.notNull(result) + '{';
        let keys = _js_names.extractKeys(this.namedParameters);
        for (let i = 0; dart.notNull(i) < dart.notNull(keys.length); i = dart.notNull(i) + 1) {
          let name = keys[dartx.get](i);
          if (needsComma) {
            result = dart.notNull(result) + ', ';
          }
          let rti = dart.dsend(this.namedParameters[name], 'toRti');
          result = dart.notNull(result) + `${rti} ${name}`;
          needsComma = true;
        }
        result = dart.notNull(result) + '}';
      }
      result = dart.notNull(result) + `) -> ${this.returnType}`;
      return result;
    }
  }
  dart.setSignature(RuntimeFunctionType, {
    constructors: () => ({RuntimeFunctionType: [RuntimeFunctionType, [RuntimeType, core.List$(RuntimeType), core.List$(RuntimeType), core.Object]]}),
    methods: () => ({
      [_isTest]: [core.bool, [core.Object]],
      [_asCheck]: [core.Object, [core.Object]],
      [_assertCheck]: [core.Object, [core.Object]],
      [_check]: [core.Object, [core.Object, core.bool]],
      [_extractFunctionTypeObjectFrom]: [core.Object, [core.Object]],
      toRti: [core.Object, []]
    }),
    statics: () => ({listToRti: [core.Object, [core.Object]]}),
    names: ['listToRti']
  });
  RuntimeFunctionType.inAssert = false;
  function buildFunctionType(returnType, parameterTypes, optionalParameterTypes) {
    return new RuntimeFunctionType(dart.as(returnType, RuntimeType), dart.as(parameterTypes, core.List$(RuntimeType)), dart.as(optionalParameterTypes, core.List$(RuntimeType)), null);
  }
  dart.fn(buildFunctionType, RuntimeFunctionType, [core.Object, core.Object, core.Object]);
  function buildNamedFunctionType(returnType, parameterTypes, namedParameters) {
    return new RuntimeFunctionType(dart.as(returnType, RuntimeType), dart.as(parameterTypes, core.List$(RuntimeType)), null, namedParameters);
  }
  dart.fn(buildNamedFunctionType, RuntimeFunctionType, [core.Object, core.Object, core.Object]);
  function buildInterfaceType(rti, typeArguments) {
    let name = dart.as(rti.name, core.String);
    if (dart.notNull(typeArguments == null) || dart.notNull(dart.as(dart.dload(typeArguments, 'isEmpty'), core.bool))) {
      return new RuntimeTypePlain(name);
    }
    return new RuntimeTypeGeneric(name, dart.as(typeArguments, core.List$(RuntimeType)), null);
  }
  dart.fn(buildInterfaceType, RuntimeType, [core.Object, core.Object]);
  class DynamicRuntimeType extends RuntimeType {
    DynamicRuntimeType() {
      super.RuntimeType();
    }
    toString() {
      return 'dynamic';
    }
    toRti() {
      return null;
    }
  }
  dart.setSignature(DynamicRuntimeType, {
    constructors: () => ({DynamicRuntimeType: [DynamicRuntimeType, []]}),
    methods: () => ({toRti: [core.Object, []]})
  });
  function getDynamicRuntimeType() {
    return dart.const(new DynamicRuntimeType());
  }
  dart.fn(getDynamicRuntimeType, RuntimeType, []);
  class VoidRuntimeType extends RuntimeType {
    VoidRuntimeType() {
      super.RuntimeType();
    }
    toString() {
      return 'void';
    }
    toRti() {
      return dart.throw_('internal error');
    }
  }
  dart.setSignature(VoidRuntimeType, {
    constructors: () => ({VoidRuntimeType: [VoidRuntimeType, []]}),
    methods: () => ({toRti: [core.Object, []]})
  });
  function getVoidRuntimeType() {
    return dart.const(new VoidRuntimeType());
  }
  dart.fn(getVoidRuntimeType, RuntimeType, []);
  function functionTypeTestMetaHelper() {
    let dyn = x;
    let dyn2 = x;
    let fixedListOrNull = dart.as(x, core.List);
    let fixedListOrNull2 = dart.as(x, core.List);
    let fixedList = dart.as(x, core.List);
    let jsObject = x;
    buildFunctionType(dyn, fixedListOrNull, fixedListOrNull2);
    buildNamedFunctionType(dyn, fixedList, jsObject);
    buildInterfaceType(dyn, fixedListOrNull);
    getDynamicRuntimeType();
    getVoidRuntimeType();
    convertRtiToRuntimeType(dyn);
    dart.dsend(dyn, _isTest, dyn2);
    dart.dsend(dyn, _asCheck, dyn2);
    dart.dsend(dyn, _assertCheck, dyn2);
  }
  dart.fn(functionTypeTestMetaHelper);
  function convertRtiToRuntimeType(rti) {
    if (rti == null) {
      return getDynamicRuntimeType();
    } else if (typeof rti == "function") {
      return new RuntimeTypePlain(rti.name);
    } else if (rti.constructor == Array) {
      let list = dart.as(rti, core.List);
      let name = list[dartx.get](0).name;
      let arguments$ = [];
      for (let i = 1; dart.notNull(i) < dart.notNull(list.length); i = dart.notNull(i) + 1) {
        arguments$[dartx.add](convertRtiToRuntimeType(list[dartx.get](i)));
      }
      return new RuntimeTypeGeneric(name, dart.as(arguments$, core.List$(RuntimeType)), rti);
    } else if ("func" in rti) {
      return new FunctionTypeInfoDecoderRing(rti).toRuntimeType();
    } else {
      throw new RuntimeError("Cannot convert " + `'${JSON.stringify(rti)}' to RuntimeType.`);
    }
  }
  dart.fn(convertRtiToRuntimeType, RuntimeType, [core.Object]);
  class RuntimeTypePlain extends RuntimeType {
    RuntimeTypePlain(name) {
      this.name = name;
      super.RuntimeType();
    }
    toRti() {
      let allClasses = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.ALL_CLASSES);
      let rti = allClasses[this.name];
      if (rti == null)
        throw `no type for '${this.name}'`;
      return rti;
    }
    toString() {
      return this.name;
    }
  }
  dart.setSignature(RuntimeTypePlain, {
    constructors: () => ({RuntimeTypePlain: [RuntimeTypePlain, [core.String]]}),
    methods: () => ({toRti: [core.Object, []]})
  });
  class RuntimeTypeGeneric extends RuntimeType {
    RuntimeTypeGeneric(name, arguments$, rti) {
      this.name = name;
      this.arguments = arguments$;
      this.rti = rti;
      super.RuntimeType();
    }
    toRti() {
      if (this.rti != null)
        return this.rti;
      let allClasses = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.ALL_CLASSES);
      let result = [allClasses[this.name]];
      if (dart.dindex(result, 0) == null) {
        throw `no type for '${this.name}<...>'`;
      }
      for (let argument of this.arguments) {
        result.push(argument.toRti());
      }
      return this.rti = result;
    }
    toString() {
      return `${this.name}<${this.arguments[dartx.join](", ")}>`;
    }
  }
  dart.setSignature(RuntimeTypeGeneric, {
    constructors: () => ({RuntimeTypeGeneric: [RuntimeTypeGeneric, [core.String, core.List$(RuntimeType), core.Object]]}),
    methods: () => ({toRti: [core.Object, []]})
  });
  let _typeData = Symbol('_typeData');
  let _cachedToString = Symbol('_cachedToString');
  let _hasReturnType = Symbol('_hasReturnType');
  let _returnType = Symbol('_returnType');
  let _isVoid = Symbol('_isVoid');
  let _hasArguments = Symbol('_hasArguments');
  let _hasOptionalArguments = Symbol('_hasOptionalArguments');
  let _optionalArguments = Symbol('_optionalArguments');
  let _hasNamedArguments = Symbol('_hasNamedArguments');
  let _namedArguments = Symbol('_namedArguments');
  let _convert = Symbol('_convert');
  class FunctionTypeInfoDecoderRing extends core.Object {
    FunctionTypeInfoDecoderRing(typeData) {
      this[_typeData] = typeData;
      this[_cachedToString] = null;
    }
    get [_hasReturnType]() {
      return "ret" in this[_typeData];
    }
    get [_returnType]() {
      return this[_typeData].ret;
    }
    get [_isVoid]() {
      return !!this[_typeData].void;
    }
    get [_hasArguments]() {
      return "args" in this[_typeData];
    }
    get [_arguments]() {
      return dart.as(this[_typeData].args, core.List);
    }
    get [_hasOptionalArguments]() {
      return "opt" in this[_typeData];
    }
    get [_optionalArguments]() {
      return dart.as(this[_typeData].opt, core.List);
    }
    get [_hasNamedArguments]() {
      return "named" in this[_typeData];
    }
    get [_namedArguments]() {
      return this[_typeData].named;
    }
    toRuntimeType() {
      return dart.const(new DynamicRuntimeType());
    }
    [_convert](type) {
      let result = runtimeTypeToString(type);
      if (result != null)
        return result;
      if ("func" in type) {
        return dart.toString(new FunctionTypeInfoDecoderRing(type));
      } else {
        throw 'bad type';
      }
    }
    toString() {
      if (this[_cachedToString] != null)
        return this[_cachedToString];
      let s = "(";
      let sep = '';
      if (this[_hasArguments]) {
        for (let argument of this[_arguments]) {
          s = dart.notNull(s) + dart.notNull(sep);
          s = dart.notNull(s) + dart.notNull(this[_convert](argument));
          sep = ', ';
        }
      }
      if (this[_hasOptionalArguments]) {
        s = dart.notNull(s) + `${sep}[`;
        sep = '';
        for (let argument of this[_optionalArguments]) {
          s = dart.notNull(s) + dart.notNull(sep);
          s = dart.notNull(s) + dart.notNull(this[_convert](argument));
          sep = ', ';
        }
        s = dart.notNull(s) + ']';
      }
      if (this[_hasNamedArguments]) {
        s = dart.notNull(s) + `${sep}{`;
        sep = '';
        for (let name of _js_names.extractKeys(this[_namedArguments])) {
          s = dart.notNull(s) + dart.notNull(sep);
          s = dart.notNull(s) + `${name}: `;
          s = dart.notNull(s) + dart.notNull(this[_convert](this[_namedArguments][name]));
          sep = ', ';
        }
        s = dart.notNull(s) + '}';
      }
      s = dart.notNull(s) + ') -> ';
      if (this[_isVoid]) {
        s = dart.notNull(s) + 'void';
      } else if (this[_hasReturnType]) {
        s = dart.notNull(s) + dart.notNull(this[_convert](this[_returnType]));
      } else {
        s = dart.notNull(s) + 'dynamic';
      }
      return this[_cachedToString] = `${s}`;
    }
  }
  dart.setSignature(FunctionTypeInfoDecoderRing, {
    constructors: () => ({FunctionTypeInfoDecoderRing: [FunctionTypeInfoDecoderRing, [core.Object]]}),
    methods: () => ({
      toRuntimeType: [RuntimeType, []],
      [_convert]: [core.String, [core.Object]]
    })
  });
  class UnimplementedNoSuchMethodError extends core.Error {
    UnimplementedNoSuchMethodError(message) {
      this[_message] = message;
      super.Error();
    }
    toString() {
      return `Unsupported operation: ${this[_message]}`;
    }
  }
  UnimplementedNoSuchMethodError[dart.implements] = () => [core.NoSuchMethodError];
  dart.setSignature(UnimplementedNoSuchMethodError, {
    constructors: () => ({UnimplementedNoSuchMethodError: [UnimplementedNoSuchMethodError, [core.String]]})
  });
  function random64() {
    let int32a = Math.random() * 0x100000000 >>> 0;
    let int32b = Math.random() * 0x100000000 >>> 0;
    return dart.notNull(int32a) + dart.notNull(int32b) * 4294967296;
  }
  dart.fn(random64, core.int, []);
  function jsonEncodeNative(string) {
    return JSON.stringify(string);
  }
  dart.fn(jsonEncodeNative, core.String, [core.String]);
  function getIsolateAffinityTag(name) {
    let isolateTagGetter = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.GET_ISOLATE_TAG);
    return isolateTagGetter(name);
  }
  dart.fn(getIsolateAffinityTag, core.String, [core.String]);
  let LoadLibraryFunctionType = dart.typedef('LoadLibraryFunctionType', () => dart.functionType(async.Future$(core.Null), []));
  function _loadLibraryWrapper(loadId) {
    return dart.fn(() => loadDeferredLibrary(loadId), async.Future$(core.Null), []);
  }
  dart.fn(_loadLibraryWrapper, LoadLibraryFunctionType, [core.String]);
  dart.defineLazyProperties(exports, {
    get _loadingLibraries() {
      return dart.map();
    },
    get _loadedLibraries() {
      return core.Set$(core.String).new();
    }
  });
  let DeferredLoadCallback = dart.typedef('DeferredLoadCallback', () => dart.functionType(dart.void, []));
  exports.deferredLoadHook = null;
  function loadDeferredLibrary(loadId) {
    let urisMap = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.DEFERRED_LIBRARY_URIS);
    let uris = dart.as(urisMap[loadId], core.List$(core.String));
    let hashesMap = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.DEFERRED_LIBRARY_HASHES);
    let hashes = dart.as(hashesMap[loadId], core.List$(core.String));
    if (uris == null)
      return async.Future$(core.Null).value(null);
    let indices = core.List$(core.int).generate(uris.length, dart.fn(i => dart.as(i, core.int), core.int, [core.Object]));
    let isHunkLoaded = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.IS_HUNK_LOADED);
    let isHunkInitialized = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.IS_HUNK_INITIALIZED);
    let indicesToLoad = indices[dartx.where](dart.fn(i => !isHunkLoaded(hashes[dartx.get](i)), core.bool, [core.int]))[dartx.toList]();
    return dart.as(async.Future.wait(dart.as(indicesToLoad[dartx.map](dart.fn(i => _loadHunk(uris[dartx.get](i)), async.Future$(core.Null), [core.int])), core.Iterable$(async.Future))).then(dart.fn(_ => {
      let indicesToInitialize = indices[dartx.where](dart.fn(i => !isHunkInitialized(hashes[dartx.get](i)), core.bool, [core.int]))[dartx.toList]();
      for (let i of indicesToInitialize) {
        let initializer = _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.INITIALIZE_LOADED_HUNK);
        initializer(hashes[dartx.get](i));
      }
      let updated = exports._loadedLibraries.add(loadId);
      if (dart.notNull(updated) && dart.notNull(exports.deferredLoadHook != null)) {
        exports.deferredLoadHook();
      }
    })), async.Future$(core.Null));
  }
  dart.fn(loadDeferredLibrary, async.Future$(core.Null), [core.String]);
  function _loadHunk(hunkName) {
    let future = exports._loadingLibraries.get(hunkName);
    if (future != null) {
      return dart.as(future.then(dart.fn(_ => null, dart.bottom, [core.Object])), async.Future$(core.Null));
    }
    let uri = _isolate_helper.IsolateNatives.thisScript;
    let index = uri[dartx.lastIndexOf]('/');
    uri = `${uri[dartx.substring](0, dart.notNull(index) + 1)}${hunkName}`;
    if (dart.notNull(Primitives.isJsshell) || dart.notNull(Primitives.isD8)) {
      return exports._loadingLibraries.set(hunkName, async.Future$(core.Null).new(dart.fn(() => {
        try {
          new Function(`load("${uri}")`)();
        } catch (error) {
          let stackTrace = dart.stackTrace(error);
          throw new async.DeferredLoadException(`Loading ${uri} failed.`);
        }

        return null;
      })));
    } else if (_isolate_helper.isWorker()) {
      return exports._loadingLibraries.set(hunkName, async.Future$(core.Null).new(dart.fn(() => {
        let completer = async.Completer$(core.Null).new();
        _isolate_helper.enterJsAsync();
        let leavingFuture = dart.as(completer.future.whenComplete(dart.fn(() => {
          _isolate_helper.leaveJsAsync();
        })), async.Future$(core.Null));
        let index = uri[dartx.lastIndexOf]('/');
        uri = `${uri[dartx.substring](0, dart.notNull(index) + 1)}${hunkName}`;
        let xhr = new XMLHttpRequest();
        xhr.open("GET", uri);
        xhr.addEventListener("load", convertDartClosureToJS(dart.fn(event => {
          if (xhr.status != 200) {
            completer.completeError(new async.DeferredLoadException(`Loading ${uri} failed.`));
            return;
          }
          let code = xhr.responseText;
          try {
            new Function(code)();
          } catch (error) {
            let stackTrace = dart.stackTrace(error);
            completer.completeError(new async.DeferredLoadException(`Evaluating ${uri} failed.`));
            return;
          }

          completer.complete(null);
        }), 1), false);
        let fail = convertDartClosureToJS(dart.fn(event => {
          new async.DeferredLoadException(`Loading ${uri} failed.`);
        }), 1);
        xhr.addEventListener("error", fail, false);
        xhr.addEventListener("abort", fail, false);
        xhr.send();
        return leavingFuture;
      })));
    }
    return exports._loadingLibraries.set(hunkName, async.Future$(core.Null).new(dart.fn(() => {
      let completer = async.Completer$(core.Null).new();
      let script = document.createElement("script");
      script.type = "text/javascript";
      script.src = uri;
      script.addEventListener("load", convertDartClosureToJS(dart.fn(event => {
        completer.complete(null);
      }), 1), false);
      script.addEventListener("error", convertDartClosureToJS(dart.fn(event => {
        completer.completeError(new async.DeferredLoadException(`Loading ${uri} failed.`));
      }), 1), false);
      document.body.appendChild(script);
      return completer.future;
    })));
  }
  dart.fn(_loadHunk, async.Future$(core.Null), [core.String]);
  class MainError extends core.Error {
    MainError(message) {
      this[_message] = message;
      super.Error();
    }
    toString() {
      return `NoSuchMethodError: ${this[_message]}`;
    }
  }
  MainError[dart.implements] = () => [core.NoSuchMethodError];
  dart.setSignature(MainError, {
    constructors: () => ({MainError: [MainError, [core.String]]})
  });
  function missingMain() {
    throw new MainError("No top-level function named 'main'.");
  }
  dart.fn(missingMain, dart.void, []);
  function badMain() {
    throw new MainError("'main' is not a function.");
  }
  dart.fn(badMain, dart.void, []);
  function mainHasTooManyParameters() {
    throw new MainError("'main' expects too many parameters.");
  }
  dart.fn(mainHasTooManyParameters, dart.void, []);
  // Exports:
  exports.NoSideEffects = NoSideEffects;
  exports.NoThrows = NoThrows;
  exports.NoInline = NoInline;
  exports.IrRepresentation = IrRepresentation;
  exports.Native = Native;
  exports.JsName = JsName;
  exports.JsPeerInterface = JsPeerInterface;
  exports.SupportJsExtensionMethods = SupportJsExtensionMethods;
  exports.ConstantMap$ = ConstantMap$;
  exports.ConstantMap = ConstantMap;
  exports.ConstantStringMap$ = ConstantStringMap$;
  exports.ConstantStringMap = ConstantStringMap;
  exports.ConstantProtoMap$ = ConstantProtoMap$;
  exports.ConstantProtoMap = ConstantProtoMap;
  exports.GeneralConstantMap$ = GeneralConstantMap$;
  exports.GeneralConstantMap = GeneralConstantMap;
  exports.contains = contains;
  exports.arrayLength = arrayLength;
  exports.arrayGet = arrayGet;
  exports.arraySet = arraySet;
  exports.propertyGet = propertyGet;
  exports.callHasOwnProperty = callHasOwnProperty;
  exports.propertySet = propertySet;
  exports.getPropertyFromPrototype = getPropertyFromPrototype;
  exports.defineProperty = defineProperty;
  exports.regExpGetNative = regExpGetNative;
  exports.regExpGetGlobalNative = regExpGetGlobalNative;
  exports.regExpCaptureCount = regExpCaptureCount;
  exports.JSSyntaxRegExp = JSSyntaxRegExp;
  exports.firstMatchAfter = firstMatchAfter;
  exports.StringMatch = StringMatch;
  exports.allMatchesInStringUnchecked = allMatchesInStringUnchecked;
  exports.stringContainsUnchecked = stringContainsUnchecked;
  exports.stringReplaceJS = stringReplaceJS;
  exports.stringReplaceFirstRE = stringReplaceFirstRE;
  exports.ESCAPE_REGEXP = ESCAPE_REGEXP;
  exports.stringReplaceAllUnchecked = stringReplaceAllUnchecked;
  exports.stringReplaceAllFuncUnchecked = stringReplaceAllFuncUnchecked;
  exports.stringReplaceAllEmptyFuncUnchecked = stringReplaceAllEmptyFuncUnchecked;
  exports.stringReplaceAllStringFuncUnchecked = stringReplaceAllStringFuncUnchecked;
  exports.stringReplaceFirstUnchecked = stringReplaceFirstUnchecked;
  exports.stringJoinUnchecked = stringJoinUnchecked;
  exports.createRuntimeType = createRuntimeType;
  exports.TypeImpl = TypeImpl;
  exports.TypeVariable = TypeVariable;
  exports.getMangledTypeName = getMangledTypeName;
  exports.setRuntimeTypeInfo = setRuntimeTypeInfo;
  exports.getRuntimeTypeInfo = getRuntimeTypeInfo;
  exports.getRuntimeTypeArguments = getRuntimeTypeArguments;
  exports.getRuntimeTypeArgument = getRuntimeTypeArgument;
  exports.getTypeArgumentByIndex = getTypeArgumentByIndex;
  exports.copyTypeArguments = copyTypeArguments;
  exports.getClassName = getClassName;
  exports.getRuntimeTypeAsString = getRuntimeTypeAsString;
  exports.getConstructorName = getConstructorName;
  exports.runtimeTypeToString = runtimeTypeToString;
  exports.joinArguments = joinArguments;
  exports.getRuntimeTypeString = getRuntimeTypeString;
  exports.getRuntimeType = getRuntimeType;
  exports.substitute = substitute;
  exports.checkSubtype = checkSubtype;
  exports.computeTypeName = computeTypeName;
  exports.subtypeCast = subtypeCast;
  exports.assertSubtype = assertSubtype;
  exports.assertIsSubtype = assertIsSubtype;
  exports.throwTypeError = throwTypeError;
  exports.checkArguments = checkArguments;
  exports.areSubtypes = areSubtypes;
  exports.computeSignature = computeSignature;
  exports.isSupertypeOfNull = isSupertypeOfNull;
  exports.checkSubtypeOfRuntimeType = checkSubtypeOfRuntimeType;
  exports.subtypeOfRuntimeTypeCast = subtypeOfRuntimeTypeCast;
  exports.assertSubtypeOfRuntimeType = assertSubtypeOfRuntimeType;
  exports.getArguments = getArguments;
  exports.isSubtype = isSubtype;
  exports.isAssignable = isAssignable;
  exports.areAssignable = areAssignable;
  exports.areAssignableMaps = areAssignableMaps;
  exports.isFunctionSubtype = isFunctionSubtype;
  exports.invoke = invoke;
  exports.invokeOn = invokeOn;
  exports.call = call;
  exports.getField = getField;
  exports.getIndex = getIndex;
  exports.getLength = getLength;
  exports.isJsArray = isJsArray;
  exports.hasField = hasField;
  exports.hasNoField = hasNoField;
  exports.isJsFunction = isJsFunction;
  exports.isJsObject = isJsObject;
  exports.isIdentical = isIdentical;
  exports.isNotIdentical = isNotIdentical;
  exports.unmangleGlobalNameIfPreservedAnyways = unmangleGlobalNameIfPreservedAnyways;
  exports.unmangleAllIdentifiersIfPreservedAnyways = unmangleAllIdentifiersIfPreservedAnyways;
  exports.patch = patch;
  exports.InternalMap = InternalMap;
  exports.requiresPreamble = requiresPreamble;
  exports.S = S;
  exports.createInvocationMirror = createInvocationMirror;
  exports.createUnmangledInvocationMirror = createUnmangledInvocationMirror;
  exports.throwInvalidReflectionError = throwInvalidReflectionError;
  exports.traceHelper = traceHelper;
  exports.JSInvocationMirror = JSInvocationMirror;
  exports.CachedInvocation = CachedInvocation;
  exports.CachedCatchAllInvocation = CachedCatchAllInvocation;
  exports.CachedNoSuchMethodInvocation = CachedNoSuchMethodInvocation;
  exports.ReflectionInfo = ReflectionInfo;
  exports.getMetadata = getMetadata;
  exports.Primitives = Primitives;
  exports.JsCache = JsCache;
  exports.iae = iae;
  exports.ioore = ioore;
  exports.stringLastIndexOfUnchecked = stringLastIndexOfUnchecked;
  exports.checkNull = checkNull;
  exports.checkNum = checkNum;
  exports.checkInt = checkInt;
  exports.checkBool = checkBool;
  exports.checkString = checkString;
  exports.wrapException = wrapException;
  exports.toStringWrapper = toStringWrapper;
  exports.throwExpression = throwExpression;
  exports.makeLiteralListConst = makeLiteralListConst;
  exports.throwRuntimeError = throwRuntimeError;
  exports.throwAbstractClassInstantiationError = throwAbstractClassInstantiationError;
  exports.TypeErrorDecoder = TypeErrorDecoder;
  exports.NullError = NullError;
  exports.JsNoSuchMethodError = JsNoSuchMethodError;
  exports.UnknownJsTypeError = UnknownJsTypeError;
  exports.unwrapException = unwrapException;
  exports.getTraceFromException = getTraceFromException;
  exports.objectHashCode = objectHashCode;
  exports.fillLiteralMap = fillLiteralMap;
  exports.invokeClosure = invokeClosure;
  exports.convertDartClosureToJS = convertDartClosureToJS;
  exports.Closure = Closure;
  exports.closureFromTearOff = closureFromTearOff;
  exports.TearOffClosure = TearOffClosure;
  exports.BoundClosure = BoundClosure;
  exports.jsHasOwnProperty = jsHasOwnProperty;
  exports.jsPropertyAccess = jsPropertyAccess;
  exports.getFallThroughError = getFallThroughError;
  exports.Creates = Creates;
  exports.Returns = Returns;
  exports.JSName = JSName;
  exports.boolConversionCheck = boolConversionCheck;
  exports.stringTypeCheck = stringTypeCheck;
  exports.stringTypeCast = stringTypeCast;
  exports.doubleTypeCheck = doubleTypeCheck;
  exports.doubleTypeCast = doubleTypeCast;
  exports.numTypeCheck = numTypeCheck;
  exports.numTypeCast = numTypeCast;
  exports.boolTypeCheck = boolTypeCheck;
  exports.boolTypeCast = boolTypeCast;
  exports.intTypeCheck = intTypeCheck;
  exports.intTypeCast = intTypeCast;
  exports.propertyTypeError = propertyTypeError;
  exports.propertyTypeCastError = propertyTypeCastError;
  exports.propertyTypeCheck = propertyTypeCheck;
  exports.propertyTypeCast = propertyTypeCast;
  exports.interceptedTypeCheck = interceptedTypeCheck;
  exports.interceptedTypeCast = interceptedTypeCast;
  exports.numberOrStringSuperTypeCheck = numberOrStringSuperTypeCheck;
  exports.numberOrStringSuperTypeCast = numberOrStringSuperTypeCast;
  exports.numberOrStringSuperNativeTypeCheck = numberOrStringSuperNativeTypeCheck;
  exports.numberOrStringSuperNativeTypeCast = numberOrStringSuperNativeTypeCast;
  exports.stringSuperTypeCheck = stringSuperTypeCheck;
  exports.stringSuperTypeCast = stringSuperTypeCast;
  exports.stringSuperNativeTypeCheck = stringSuperNativeTypeCheck;
  exports.stringSuperNativeTypeCast = stringSuperNativeTypeCast;
  exports.listTypeCheck = listTypeCheck;
  exports.listTypeCast = listTypeCast;
  exports.listSuperTypeCheck = listSuperTypeCheck;
  exports.listSuperTypeCast = listSuperTypeCast;
  exports.listSuperNativeTypeCheck = listSuperNativeTypeCheck;
  exports.listSuperNativeTypeCast = listSuperNativeTypeCast;
  exports.voidTypeCheck = voidTypeCheck;
  exports.checkMalformedType = checkMalformedType;
  exports.checkDeferredIsLoaded = checkDeferredIsLoaded;
  exports.TypeErrorImplementation = TypeErrorImplementation;
  exports.CastErrorImplementation = CastErrorImplementation;
  exports.FallThroughErrorImplementation = FallThroughErrorImplementation;
  exports.assertHelper = assertHelper;
  exports.throwNoSuchMethod = throwNoSuchMethod;
  exports.throwCyclicInit = throwCyclicInit;
  exports.RuntimeError = RuntimeError;
  exports.DeferredNotLoadedError = DeferredNotLoadedError;
  exports.RuntimeType = RuntimeType;
  exports.RuntimeFunctionType = RuntimeFunctionType;
  exports.buildFunctionType = buildFunctionType;
  exports.buildNamedFunctionType = buildNamedFunctionType;
  exports.buildInterfaceType = buildInterfaceType;
  exports.DynamicRuntimeType = DynamicRuntimeType;
  exports.getDynamicRuntimeType = getDynamicRuntimeType;
  exports.VoidRuntimeType = VoidRuntimeType;
  exports.getVoidRuntimeType = getVoidRuntimeType;
  exports.functionTypeTestMetaHelper = functionTypeTestMetaHelper;
  exports.convertRtiToRuntimeType = convertRtiToRuntimeType;
  exports.RuntimeTypePlain = RuntimeTypePlain;
  exports.RuntimeTypeGeneric = RuntimeTypeGeneric;
  exports.FunctionTypeInfoDecoderRing = FunctionTypeInfoDecoderRing;
  exports.UnimplementedNoSuchMethodError = UnimplementedNoSuchMethodError;
  exports.random64 = random64;
  exports.jsonEncodeNative = jsonEncodeNative;
  exports.getIsolateAffinityTag = getIsolateAffinityTag;
  exports.LoadLibraryFunctionType = LoadLibraryFunctionType;
  exports.DeferredLoadCallback = DeferredLoadCallback;
  exports.loadDeferredLibrary = loadDeferredLibrary;
  exports.MainError = MainError;
  exports.missingMain = missingMain;
  exports.badMain = badMain;
  exports.mainHasTooManyParameters = mainHasTooManyParameters;
})(_js_helper, core, collection, _internal, _foreign_helper, _interceptors, _js_names, _js_embedded_names, async, _isolate_helper);
