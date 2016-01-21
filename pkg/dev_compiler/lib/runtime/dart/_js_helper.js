dart_library.library('dart/_js_helper', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/collection',
  'dart/_interceptors',
  'dart/_foreign_helper'
], /* Lazy imports */[
], function(exports, dart, core, collection, _interceptors, _foreign_helper) {
  'use strict';
  let dartx = dart.dartx;
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
  class Native extends core.Object {
    Native(name) {
      this.name = name;
    }
  }
  dart.setSignature(Native, {
    constructors: () => ({Native: [Native, [core.String]]})
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
  function defineProperty(obj, property, value) {
    Object.defineProperty(obj, property, {value: value, enumerable: false, writable: true, configurable: true});
  }
  dart.fn(defineProperty, dart.void, [dart.dynamic, core.String, dart.dynamic]);
  const _nativeRegExp = Symbol('_nativeRegExp');
  function regExpGetNative(regexp) {
    return regexp[_nativeRegExp];
  }
  dart.fn(regExpGetNative, () => dart.definiteFunctionType(dart.dynamic, [JSSyntaxRegExp]));
  const _nativeGlobalVersion = Symbol('_nativeGlobalVersion');
  function regExpGetGlobalNative(regexp) {
    let nativeRegexp = regexp[_nativeGlobalVersion];
    nativeRegexp.lastIndex = 0;
    return nativeRegexp;
  }
  dart.fn(regExpGetGlobalNative, () => dart.definiteFunctionType(dart.dynamic, [JSSyntaxRegExp]));
  const _nativeAnchoredVersion = Symbol('_nativeAnchoredVersion');
  function regExpCaptureCount(regexp) {
    let nativeAnchoredRegExp = regexp[_nativeAnchoredVersion];
    let match = nativeAnchoredRegExp.exec('');
    return dart.as(dart.dsend(dart.dload(match, 'length'), '-', 2), core.int);
  }
  dart.fn(regExpCaptureCount, () => dart.definiteFunctionType(core.int, [JSSyntaxRegExp]));
  const _nativeGlobalRegExp = Symbol('_nativeGlobalRegExp');
  const _nativeAnchoredRegExp = Symbol('_nativeAnchoredRegExp');
  const _isMultiLine = Symbol('_isMultiLine');
  const _isCaseSensitive = Symbol('_isCaseSensitive');
  const _execGlobal = Symbol('_execGlobal');
  const _execAnchored = Symbol('_execAnchored');
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
      if (this[_nativeGlobalRegExp] != null) return this[_nativeGlobalRegExp];
      return this[_nativeGlobalRegExp] = JSSyntaxRegExp.makeNative(this.pattern, this[_isMultiLine], this[_isCaseSensitive], true);
    }
    get [_nativeAnchoredVersion]() {
      if (this[_nativeAnchoredRegExp] != null) return this[_nativeAnchoredRegExp];
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
      let m = dart.notNull(multiLine) ? 'm' : '';
      let i = dart.notNull(caseSensitive) ? '' : 'i';
      let g = dart.notNull(global) ? 'g' : '';
      let regexp = (function() {
        try {
          return new RegExp(source, m + i + g);
        } catch (e) {
          return e;
        }

      })();
      if (regexp instanceof RegExp) return regexp;
      let errorMessage = String(regexp);
      dart.throw(new core.FormatException(`Illegal RegExp pattern: ${source}, ${errorMessage}`));
    }
    firstMatch(string) {
      let m = dart.as(this[_nativeRegExp].exec(checkString(string)), core.List$(core.String));
      if (m == null) return null;
      return new _MatchImplementation(this, m);
    }
    hasMatch(string) {
      return this[_nativeRegExp].test(checkString(string));
    }
    stringMatch(string) {
      let match = this.firstMatch(string);
      if (match != null) return match.group(0);
      return null;
    }
    allMatches(string, start) {
      if (start === void 0) start = 0;
      checkString(string);
      checkInt(start);
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(string[dartx.length])) {
        dart.throw(new core.RangeError.range(start, 0, string[dartx.length]));
      }
      return new _AllMatchesIterable(this, string, start);
    }
    [_execGlobal](string, start) {
      let regexp = this[_nativeGlobalVersion];
      regexp.lastIndex = start;
      let match = dart.as(regexp.exec(string), core.List);
      if (match == null) return null;
      return new _MatchImplementation(this, dart.as(match, core.List$(core.String)));
    }
    [_execAnchored](string, start) {
      let regexp = this[_nativeAnchoredVersion];
      regexp.lastIndex = start;
      let match = dart.as(regexp.exec(string), core.List);
      if (match == null) return null;
      if (match[dartx.get](dart.notNull(match[dartx.length]) - 1) != null) return null;
      match[dartx.length] = dart.notNull(match[dartx.length]) - 1;
      return new _MatchImplementation(this, dart.as(match, core.List$(core.String)));
    }
    matchAsPrefix(string, start) {
      if (start === void 0) start = 0;
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(string[dartx.length])) {
        dart.throw(new core.RangeError.range(start, 0, string[dartx.length]));
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
    statics: () => ({makeNative: [dart.dynamic, [core.String, core.bool, core.bool, core.bool]]}),
    names: ['makeNative']
  });
  dart.defineExtensionMembers(JSSyntaxRegExp, ['allMatches', 'matchAsPrefix']);
  const _match = Symbol('_match');
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
      return dart.notNull(this.start) + dart.notNull(this[_match][dartx.get](0)[dartx.length]);
    }
    group(index) {
      return this[_match][dartx.get](index);
    }
    get(index) {
      return this.group(index);
    }
    get groupCount() {
      return dart.notNull(this[_match][dartx.length]) - 1;
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
  const _re = Symbol('_re');
  const _string = Symbol('_string');
  const _start = Symbol('_start');
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
  dart.defineExtensionMembers(_AllMatchesIterable, ['iterator']);
  const _regExp = Symbol('_regExp');
  const _nextIndex = Symbol('_nextIndex');
  const _current = Symbol('_current');
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
      if (this[_string] == null) return false;
      if (dart.notNull(this[_nextIndex]) <= dart.notNull(this[_string][dartx.length])) {
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
      return dart.notNull(this.start) + dart.notNull(this.pattern[dartx.length]);
    }
    get(g) {
      return this.group(g);
    }
    get groupCount() {
      return 0;
    }
    group(group_) {
      if (group_ != 0) {
        dart.throw(new core.RangeError.value(group_));
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
    let length = haystack[dartx.length];
    let patternLength = needle[dartx.length];
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
    if (match == null) return receiver;
    let start = dart.dload(match, 'start');
    let end = dart.dload(match, 'end');
    return `${dart.dsend(receiver, 'substring', 0, start)}${to}${dart.dsend(receiver, 'substring', end)}`;
  }
  dart.fn(stringReplaceFirstRE);
  const ESCAPE_REGEXP = '[[\\]{}()*+?.\\\\^$|]';
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
      dart.throw("String.replaceAll(Pattern) UNIMPLEMENTED");
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
      dart.throw(new core.ArgumentError(`${pattern} is not a Pattern`));
    }
    if (onMatch == null) onMatch = _matchString;
    if (onNonMatch == null) onNonMatch = _stringIdentity;
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
    if (startIndex === void 0) startIndex = 0;
    if (typeof from == 'string') {
      let index = dart.dsend(receiver, 'indexOf', from, startIndex);
      if (dart.notNull(dart.as(dart.dsend(index, '<', 0), core.bool))) return receiver;
      return `${dart.dsend(receiver, 'substring', 0, index)}${to}` + `${dart.dsend(receiver, 'substring', dart.dsend(index, '+', dart.dload(from, 'length')))}`;
    } else if (dart.is(from, JSSyntaxRegExp)) {
      return startIndex == 0 ? stringReplaceJS(receiver, regExpGetNative(dart.as(from, JSSyntaxRegExp)), to) : stringReplaceFirstRE(receiver, from, to, startIndex);
    } else {
      checkNull(from);
      dart.throw("String.replace(Pattern) UNIMPLEMENTED");
    }
  }
  dart.fn(stringReplaceFirstUnchecked, dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic], [core.int]);
  function stringJoinUnchecked(array, separator) {
    return array.join(separator);
  }
  dart.fn(stringJoinUnchecked);
  function getRuntimeType(object) {
    return dart.as(dart.realRuntimeType(object), core.Type);
  }
  dart.fn(getRuntimeType, core.Type, [dart.dynamic]);
  function getIndex(array, index) {
    dart.assert(isJsArray(array));
    return array[index];
  }
  dart.fn(getIndex, dart.dynamic, [dart.dynamic, core.int]);
  function getLength(array) {
    dart.assert(isJsArray(array));
    return array.length;
  }
  dart.fn(getLength, core.int, [dart.dynamic]);
  function isJsArray(value) {
    return dart.is(value, _interceptors.JSArray);
  }
  dart.fn(isJsArray, core.bool, [dart.dynamic]);
  class _Patch extends core.Object {
    _Patch() {
    }
  }
  dart.setSignature(_Patch, {
    constructors: () => ({_Patch: [_Patch, []]})
  });
  const patch = dart.const(new _Patch());
  class InternalMap extends core.Object {}
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
      dart.throw(new core.FormatException(string));
    }
    static parseInt(source, radix, handleError) {
      if (handleError == null) handleError = dart.fn(s => dart.as(Primitives._throwFormatException(s), core.int), core.int, [core.String]);
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
        if (!(typeof radix == 'number')) dart.throw(new core.ArgumentError("Radix is not an integer"));
        if (dart.notNull(radix) < 2 || dart.notNull(radix) > 36) {
          dart.throw(new core.RangeError(`Radix ${radix} not in range 2..36`));
        }
        if (match != null) {
          if (radix == 10 && dart.dindex(match, decimalIndex) != null) {
            return parseInt(source, 10);
          }
          if (dart.notNull(radix) < 10 || dart.dindex(match, decimalIndex) == null) {
            let maxCharCode = null;
            if (dart.notNull(radix) <= 10) {
              maxCharCode = 48 + dart.notNull(radix) - 1;
            } else {
              maxCharCode = 97 + dart.notNull(radix) - 10 - 1;
            }
            let digitsPart = dart.as(dart.dindex(match, digitsIndex), core.String);
            for (let i = 0; dart.notNull(i) < dart.notNull(digitsPart[dartx.length]); i = dart.notNull(i) + 1) {
              let characterCode = dart.notNull(digitsPart[dartx.codeUnitAt](0)) | 32;
              if (dart.notNull(digitsPart[dartx.codeUnitAt](i)) > dart.notNull(maxCharCode)) {
                return handleError(source);
              }
            }
          }
        }
      }
      if (match == null) return handleError(source);
      return parseInt(source, radix);
    }
    static parseDouble(source, handleError) {
      checkString(source);
      if (handleError == null) handleError = dart.fn(s => dart.as(Primitives._throwFormatException(s), core.double), core.double, [core.String]);
      if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(source)) {
        return handleError(source);
      }
      let result = parseFloat(source);
      if (dart.notNull(result[dartx.isNaN])) {
        let trimmed = source[dartx.trim]();
        if (trimmed == 'NaN' || trimmed == '+NaN' || trimmed == '-NaN') {
          return result;
        }
        return handleError(source);
      }
      return result;
    }
    static objectTypeName(object) {
      return dart.toString(getRuntimeType(object));
    }
    static objectToString(object) {
      let name = dart.typeName(dart.realRuntimeType(object));
      return `Instance of '${name}'`;
    }
    static dateNow() {
      return Date.now();
    }
    static initTicker() {
      if (Primitives.timerFrequency != null) return;
      Primitives.timerFrequency = 1000;
      Primitives.timerTicks = Primitives.dateNow;
      if (typeof window == "undefined") return;
      let jsWindow = window;
      if (jsWindow == null) return;
      let performance = jsWindow.performance;
      if (performance == null) return;
      if (typeof performance.now != "function") return;
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
      if (!!self.location) {
        return self.location.href;
      }
      return null;
    }
    static _fromCharCodeApply(array) {
      let result = "";
      let kMaxApply = 500;
      let end = array[dartx.length];
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
        if (!(typeof i == 'number')) dart.throw(new core.ArgumentError(i));
        if (dart.notNull(dart.as(dart.dsend(i, '<=', 65535), core.bool))) {
          a[dartx.add](dart.as(i, core.int));
        } else if (dart.notNull(dart.as(dart.dsend(i, '<=', 1114111), core.bool))) {
          a[dartx.add](dart.asInt((55296)[dartx['+']](dart.as(dart.dsend(dart.dsend(dart.dsend(i, '-', 65536), '>>', 10), '&', 1023), core.num))));
          a[dartx.add](dart.asInt((56320)[dartx['+']](dart.as(dart.dsend(i, '&', 1023), core.num))));
        } else {
          dart.throw(new core.ArgumentError(i));
        }
      }
      return Primitives._fromCharCodeApply(a);
    }
    static stringFromCharCodes(charCodes) {
      for (let i of dart.as(charCodes, core.Iterable)) {
        if (!(typeof i == 'number')) dart.throw(new core.ArgumentError(i));
        if (dart.notNull(dart.as(dart.dsend(i, '<', 0), core.bool))) dart.throw(new core.ArgumentError(i));
        if (dart.notNull(dart.as(dart.dsend(i, '>', 65535), core.bool))) return Primitives.stringFromCodePoints(charCodes);
      }
      return Primitives._fromCharCodeApply(dart.as(charCodes, core.List$(core.int)));
    }
    static stringFromCharCode(charCode) {
      if (0 <= dart.notNull(dart.as(charCode, core.num))) {
        if (dart.notNull(dart.as(dart.dsend(charCode, '<=', 65535), core.bool))) {
          return String.fromCharCode(charCode);
        }
        if (dart.notNull(dart.as(dart.dsend(charCode, '<=', 1114111), core.bool))) {
          let bits = dart.dsend(charCode, '-', 65536);
          let low = (56320)[dartx['|']](dart.as(dart.dsend(bits, '&', 1023), core.int));
          let high = (55296)[dartx['|']](dart.as(dart.dsend(bits, '>>', 10), core.int));
          return String.fromCharCode(high, low);
        }
      }
      dart.throw(new core.RangeError.range(dart.as(charCode, core.num), 0, 1114111));
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
      if (match != null) return dart.as(match[dartx.get](1), core.String);
      match = dart.as(/^[A-Z,a-z]{3}\s[A-Z,a-z]{3}\s\d+\s\d{2}:\d{2}:\d{2}\s([A-Z]{3,5})\s\d{4}$/.exec(d.toString()), core.List);
      if (match != null) return dart.as(match[dartx.get](1), core.String);
      match = dart.as(/(?:GMT|UTC)[+-]\d{4}/.exec(d.toString()), core.List);
      if (match != null) return dart.as(match[dartx.get](0), core.String);
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
      if (dart.notNull(dart.as(isUtc, core.bool))) {
        value = Date.UTC(years, jsMonth, day, hours, minutes, seconds, milliseconds);
      } else {
        value = new Date(years, jsMonth, day, hours, minutes, seconds, milliseconds).valueOf();
      }
      if (dart.notNull(dart.as(dart.dload(value, 'isNaN'), core.bool)) || dart.notNull(dart.as(dart.dsend(value, '<', -dart.notNull(MAX_MILLISECONDS_SINCE_EPOCH)), core.bool)) || dart.notNull(dart.as(dart.dsend(value, '>', MAX_MILLISECONDS_SINCE_EPOCH), core.bool))) {
        return null;
      }
      if (dart.notNull(dart.as(dart.dsend(years, '<=', 0), core.bool)) || dart.notNull(dart.as(dart.dsend(years, '<', 100), core.bool))) return Primitives.patchUpY2K(value, years, isUtc);
      return value;
    }
    static patchUpY2K(value, years, isUtc) {
      let date = new Date(value);
      if (dart.notNull(dart.as(isUtc, core.bool))) {
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
      return dart.notNull(dart.as(dart.dload(receiver, 'isUtc'), core.bool)) ? Primitives.lazyAsJsDate(receiver).getUTCFullYear() + 0 : Primitives.lazyAsJsDate(receiver).getFullYear() + 0;
    }
    static getMonth(receiver) {
      return dart.notNull(dart.as(dart.dload(receiver, 'isUtc'), core.bool)) ? Primitives.lazyAsJsDate(receiver).getUTCMonth() + 1 : Primitives.lazyAsJsDate(receiver).getMonth() + 1;
    }
    static getDay(receiver) {
      return dart.notNull(dart.as(dart.dload(receiver, 'isUtc'), core.bool)) ? Primitives.lazyAsJsDate(receiver).getUTCDate() + 0 : Primitives.lazyAsJsDate(receiver).getDate() + 0;
    }
    static getHours(receiver) {
      return dart.notNull(dart.as(dart.dload(receiver, 'isUtc'), core.bool)) ? Primitives.lazyAsJsDate(receiver).getUTCHours() + 0 : Primitives.lazyAsJsDate(receiver).getHours() + 0;
    }
    static getMinutes(receiver) {
      return dart.notNull(dart.as(dart.dload(receiver, 'isUtc'), core.bool)) ? Primitives.lazyAsJsDate(receiver).getUTCMinutes() + 0 : Primitives.lazyAsJsDate(receiver).getMinutes() + 0;
    }
    static getSeconds(receiver) {
      return dart.notNull(dart.as(dart.dload(receiver, 'isUtc'), core.bool)) ? Primitives.lazyAsJsDate(receiver).getUTCSeconds() + 0 : Primitives.lazyAsJsDate(receiver).getSeconds() + 0;
    }
    static getMilliseconds(receiver) {
      return dart.notNull(dart.as(dart.dload(receiver, 'isUtc'), core.bool)) ? Primitives.lazyAsJsDate(receiver).getUTCMilliseconds() + 0 : Primitives.lazyAsJsDate(receiver).getMilliseconds() + 0;
    }
    static getWeekday(receiver) {
      let weekday = dart.notNull(dart.as(dart.dload(receiver, 'isUtc'), core.bool)) ? Primitives.lazyAsJsDate(receiver).getUTCDay() + 0 : Primitives.lazyAsJsDate(receiver).getDay() + 0;
      return (dart.notNull(weekday) + 6) % 7 + 1;
    }
    static valueFromDateString(str) {
      if (!(typeof str == 'string')) dart.throw(new core.ArgumentError(str));
      let value = Date.parse(str);
      if (dart.notNull(value[dartx.isNaN])) dart.throw(new core.ArgumentError(str));
      return value;
    }
    static getProperty(object, key) {
      if (object == null || typeof object == 'boolean' || typeof object == 'number' || typeof object == 'string') {
        dart.throw(new core.ArgumentError(object));
      }
      return object[key];
    }
    static setProperty(object, key, value) {
      if (object == null || typeof object == 'boolean' || typeof object == 'number' || typeof object == 'string') {
        dart.throw(new core.ArgumentError(object));
      }
      object[key] = value;
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
      objectHashCode: [core.int, [dart.dynamic]],
      _throwFormatException: [dart.dynamic, [core.String]],
      parseInt: [core.int, [core.String, core.int, dart.functionType(core.int, [core.String])]],
      parseDouble: [core.double, [core.String, dart.functionType(core.double, [core.String])]],
      objectTypeName: [core.String, [core.Object]],
      objectToString: [core.String, [core.Object]],
      dateNow: [core.int, []],
      initTicker: [dart.void, []],
      currentUri: [core.String, []],
      _fromCharCodeApply: [core.String, [core.List$(core.int)]],
      stringFromCodePoints: [core.String, [dart.dynamic]],
      stringFromCharCodes: [core.String, [dart.dynamic]],
      stringFromCharCode: [core.String, [dart.dynamic]],
      stringConcatUnchecked: [core.String, [core.String, core.String]],
      flattenString: [core.String, [core.String]],
      getTimeZoneName: [core.String, [dart.dynamic]],
      getTimeZoneOffsetInMinutes: [core.int, [dart.dynamic]],
      valueFromDecomposedDate: [dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]],
      patchUpY2K: [dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic]],
      lazyAsJsDate: [dart.dynamic, [dart.dynamic]],
      getYear: [dart.dynamic, [dart.dynamic]],
      getMonth: [dart.dynamic, [dart.dynamic]],
      getDay: [dart.dynamic, [dart.dynamic]],
      getHours: [dart.dynamic, [dart.dynamic]],
      getMinutes: [dart.dynamic, [dart.dynamic]],
      getSeconds: [dart.dynamic, [dart.dynamic]],
      getMilliseconds: [dart.dynamic, [dart.dynamic]],
      getWeekday: [dart.dynamic, [dart.dynamic]],
      valueFromDateString: [dart.dynamic, [dart.dynamic]],
      getProperty: [dart.dynamic, [dart.dynamic, dart.dynamic]],
      setProperty: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]],
      identicalImplementation: [core.bool, [dart.dynamic, dart.dynamic]],
      extractStackTrace: [core.StackTrace, [core.Error]]
    }),
    names: ['initializeStatics', 'objectHashCode', '_throwFormatException', 'parseInt', 'parseDouble', 'objectTypeName', 'objectToString', 'dateNow', 'initTicker', 'currentUri', '_fromCharCodeApply', 'stringFromCodePoints', 'stringFromCharCodes', 'stringFromCharCode', 'stringConcatUnchecked', 'flattenString', 'getTimeZoneName', 'getTimeZoneOffsetInMinutes', 'valueFromDecomposedDate', 'patchUpY2K', 'lazyAsJsDate', 'getYear', 'getMonth', 'getDay', 'getHours', 'getMinutes', 'getSeconds', 'getMilliseconds', 'getWeekday', 'valueFromDateString', 'getProperty', 'setProperty', 'identicalImplementation', 'extractStackTrace']
  });
  Primitives.mirrorFunctionCacheName = '$cachedFunction';
  Primitives.mirrorInvokeCacheName = '$cachedInvocation';
  Primitives.DOLLAR_CHAR_VALUE = 36;
  Primitives.timerFrequency = null;
  Primitives.timerTicks = null;
  function stringLastIndexOfUnchecked(receiver, element, start) {
    return receiver.lastIndexOf(element, start);
  }
  dart.fn(stringLastIndexOfUnchecked);
  function checkNull(object) {
    if (object == null) dart.throw(new core.ArgumentError(null));
    return object;
  }
  dart.fn(checkNull);
  function checkNum(value) {
    if (!(typeof value == 'number')) {
      dart.throw(new core.ArgumentError(value));
    }
    return value;
  }
  dart.fn(checkNum);
  function checkInt(value) {
    if (!(typeof value == 'number')) {
      dart.throw(new core.ArgumentError(value));
    }
    return value;
  }
  dart.fn(checkInt);
  function checkBool(value) {
    if (!(typeof value == 'boolean')) {
      dart.throw(new core.ArgumentError(value));
    }
    return value;
  }
  dart.fn(checkBool);
  function checkString(value) {
    if (!(typeof value == 'string')) {
      dart.throw(new core.ArgumentError(value));
    }
    return value;
  }
  dart.fn(checkString);
  function throwRuntimeError(message) {
    dart.throw(new RuntimeError(message));
  }
  dart.fn(throwRuntimeError);
  function throwAbstractClassInstantiationError(className) {
    dart.throw(new core.AbstractClassInstantiationError(dart.as(className, core.String)));
  }
  dart.fn(throwAbstractClassInstantiationError);
  const _message = Symbol('_message');
  const _method = Symbol('_method');
  class NullError extends core.Error {
    NullError(message, match) {
      this[_message] = message;
      this[_method] = dart.as(match == null ? null : match.method, core.String);
      super.Error();
    }
    toString() {
      if (this[_method] == null) return `NullError: ${this[_message]}`;
      return `NullError: Cannot call "${this[_method]}" on null`;
    }
  }
  NullError[dart.implements] = () => [core.NoSuchMethodError];
  dart.setSignature(NullError, {
    constructors: () => ({NullError: [NullError, [core.String, dart.dynamic]]})
  });
  const _receiver = Symbol('_receiver');
  class JsNoSuchMethodError extends core.Error {
    JsNoSuchMethodError(message, match) {
      this[_message] = message;
      this[_method] = dart.as(match == null ? null : match.method, core.String);
      this[_receiver] = dart.as(match == null ? null : match.receiver, core.String);
      super.Error();
    }
    toString() {
      if (this[_method] == null) return `NoSuchMethodError: ${this[_message]}`;
      if (this[_receiver] == null) {
        return `NoSuchMethodError: Cannot call "${this[_method]}" (${this[_message]})`;
      }
      return `NoSuchMethodError: Cannot call "${this[_method]}" on "${this[_receiver]}" ` + `(${this[_message]})`;
    }
  }
  JsNoSuchMethodError[dart.implements] = () => [core.NoSuchMethodError];
  dart.setSignature(JsNoSuchMethodError, {
    constructors: () => ({JsNoSuchMethodError: [JsNoSuchMethodError, [core.String, dart.dynamic]]})
  });
  class UnknownJsTypeError extends core.Error {
    UnknownJsTypeError(message) {
      this[_message] = message;
      super.Error();
    }
    toString() {
      return dart.notNull(this[_message][dartx.isEmpty]) ? 'Error' : `Error: ${this[_message]}`;
    }
  }
  dart.setSignature(UnknownJsTypeError, {
    constructors: () => ({UnknownJsTypeError: [UnknownJsTypeError, [core.String]]})
  });
  function getTraceFromException(exception) {
    return new _StackTrace(exception);
  }
  dart.fn(getTraceFromException, core.StackTrace, [dart.dynamic]);
  const _exception = Symbol('_exception');
  const _trace = Symbol('_trace');
  class _StackTrace extends core.Object {
    _StackTrace(exception) {
      this[_exception] = exception;
      this[_trace] = null;
    }
    toString() {
      if (this[_trace] != null) return this[_trace];
      let trace = null;
      if (typeof this[_exception] === "object") {
        trace = dart.as(this[_exception].stack, core.String);
      }
      return this[_trace] = trace == null ? '' : trace;
    }
  }
  _StackTrace[dart.implements] = () => [core.StackTrace];
  dart.setSignature(_StackTrace, {
    constructors: () => ({_StackTrace: [_StackTrace, [dart.dynamic]]})
  });
  function objectHashCode(object) {
    if (object == null || typeof object != 'object') {
      return dart.hashCode(object);
    } else {
      return Primitives.objectHashCode(object);
    }
  }
  dart.fn(objectHashCode, core.int, [dart.dynamic]);
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
  dart.fn(fillLiteralMap, dart.dynamic, [dart.dynamic, core.Map]);
  function jsHasOwnProperty(jsObject, property) {
    return jsObject.hasOwnProperty(property);
  }
  dart.fn(jsHasOwnProperty, core.bool, [dart.dynamic, core.String]);
  function jsPropertyAccess(jsObject, property) {
    return jsObject[property];
  }
  dart.fn(jsPropertyAccess, dart.dynamic, [dart.dynamic, core.String]);
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
  class JavaScriptIndexingBehavior extends _interceptors.JSMutableIndexable {}
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
    constructors: () => ({RuntimeError: [RuntimeError, [dart.dynamic]]})
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
  const _jsIterator = Symbol('_jsIterator');
  const SyncIterator$ = dart.generic(function(E) {
    class SyncIterator extends core.Object {
      SyncIterator(jsIterator) {
        this[_jsIterator] = jsIterator;
        this[_current] = null;
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        let ret = this[_jsIterator].next();
        this[_current] = dart.as(ret.value, E);
        return !ret.done;
      }
    }
    SyncIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setSignature(SyncIterator, {
      constructors: () => ({SyncIterator: [SyncIterator$(E), [dart.dynamic]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return SyncIterator;
  });
  let SyncIterator = SyncIterator$();
  const _generator = Symbol('_generator');
  const _args = Symbol('_args');
  const SyncIterable$ = dart.generic(function(E) {
    class SyncIterable extends collection.IterableBase$(E) {
      SyncIterable(generator, args) {
        this[_generator] = generator;
        this[_args] = args;
        super.IterableBase();
      }
      [_jsIterator]() {
        return this[_generator](...this[_args]);
      }
      get iterator() {
        return new (SyncIterator$(E))(this[_jsIterator]());
      }
    }
    dart.setSignature(SyncIterable, {
      constructors: () => ({SyncIterable: [SyncIterable$(E), [dart.dynamic, dart.dynamic]]}),
      methods: () => ({[_jsIterator]: [dart.dynamic, []]})
    });
    dart.defineExtensionMembers(SyncIterable, ['iterator']);
    return SyncIterable;
  });
  let SyncIterable = SyncIterable$();
  // Exports:
  exports.NoThrows = NoThrows;
  exports.NoInline = NoInline;
  exports.Native = Native;
  exports.JsPeerInterface = JsPeerInterface;
  exports.SupportJsExtensionMethods = SupportJsExtensionMethods;
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
  exports.getRuntimeType = getRuntimeType;
  exports.getIndex = getIndex;
  exports.getLength = getLength;
  exports.isJsArray = isJsArray;
  exports.patch = patch;
  exports.InternalMap = InternalMap;
  exports.Primitives = Primitives;
  exports.stringLastIndexOfUnchecked = stringLastIndexOfUnchecked;
  exports.checkNull = checkNull;
  exports.checkNum = checkNum;
  exports.checkInt = checkInt;
  exports.checkBool = checkBool;
  exports.checkString = checkString;
  exports.throwRuntimeError = throwRuntimeError;
  exports.throwAbstractClassInstantiationError = throwAbstractClassInstantiationError;
  exports.NullError = NullError;
  exports.JsNoSuchMethodError = JsNoSuchMethodError;
  exports.UnknownJsTypeError = UnknownJsTypeError;
  exports.getTraceFromException = getTraceFromException;
  exports.objectHashCode = objectHashCode;
  exports.fillLiteralMap = fillLiteralMap;
  exports.jsHasOwnProperty = jsHasOwnProperty;
  exports.jsPropertyAccess = jsPropertyAccess;
  exports.getFallThroughError = getFallThroughError;
  exports.Creates = Creates;
  exports.Returns = Returns;
  exports.JSName = JSName;
  exports.JavaScriptIndexingBehavior = JavaScriptIndexingBehavior;
  exports.TypeErrorImplementation = TypeErrorImplementation;
  exports.CastErrorImplementation = CastErrorImplementation;
  exports.FallThroughErrorImplementation = FallThroughErrorImplementation;
  exports.RuntimeError = RuntimeError;
  exports.random64 = random64;
  exports.jsonEncodeNative = jsonEncodeNative;
  exports.SyncIterator$ = SyncIterator$;
  exports.SyncIterator = SyncIterator;
  exports.SyncIterable$ = SyncIterable$;
  exports.SyncIterable = SyncIterable;
});
