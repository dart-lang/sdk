var _interceptors;
(function(exports) {
  'use strict';
  let JSArray = Array;
  let JSMutableArray$ = dart.generic(function(E) {
    class JSMutableArray extends JSArray$(E) {}
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
  let _MIN_INT32 = Symbol('_MIN_INT32');
  let _MAX_INT32 = Symbol('_MAX_INT32');
  let _handleIEtoString = Symbol('_handleIEtoString');
  let _isInt32 = Symbol('_isInt32');
  let _tdivFast = Symbol('_tdivFast');
  let _tdivSlow = Symbol('_tdivSlow');
  let _shlPositive = Symbol('_shlPositive');
  let _shrReceiverPositive = Symbol('_shrReceiverPositive');
  let _shrOtherPositive = Symbol('_shrOtherPositive');
  let _shrBothPositive = Symbol('_shrBothPositive');
  class Interceptor extends core.Object {
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
          if (this.isNegative == bIsNegative)
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
      return dart.equals(this, 0) ? core.int['/'](1, this) < 0 : this['<'](0);
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
      return this['>'](0) ? 1 : this['<'](0) ? -1 : this;
    }
    toInt() {
      if (dart.notNull(this['>='](JSNumber[_MIN_INT32])) && dart.notNull(this['<='](JSNumber[_MAX_INT32]))) {
        return this | 0;
      }
      if (isFinite(this)) {
        return this.truncateToDouble() + 0;
      }
      throw new core.UnsupportedError('' + this);
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
      return Math.ceil(this);
    }
    floorToDouble() {
      return Math.floor(this);
    }
    roundToDouble() {
      if (this['<'](0)) {
        return -Math.round(-this);
      } else {
        return Math.round(this);
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
      if (dart.dsend(dart.dsend(lowerLimit, 'compareTo', upperLimit), '>', 0)) {
        throw new core.ArgumentError(lowerLimit);
      }
      if (dart.notNull(this.compareTo(dart.as(lowerLimit, core.num))) < 0)
        return dart.as(lowerLimit, core.num);
      if (dart.notNull(this.compareTo(dart.as(upperLimit, core.num))) > 0)
        return dart.as(upperLimit, core.num);
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
      if (dart.notNull(dart.equals(this, 0)) && dart.notNull(this.isNegative))
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
      if (dart.notNull(dart.equals(this, 0)) && dart.notNull(this.isNegative))
        return `-${result}`;
      return result;
    }
    toStringAsPrecision(precision) {
      _js_helper.checkInt(precision);
      if (dart.notNull(precision) < 1 || dart.notNull(precision) > 21) {
        throw new core.RangeError(precision);
      }
      let result = this.toPrecision(precision);
      if (dart.notNull(dart.equals(this, 0)) && dart.notNull(this.isNegative))
        return `-${result}`;
      return result;
    }
    toRadixString(radix) {
      _js_helper.checkInt(radix);
      if (dart.notNull(radix) < 2 || dart.notNull(radix) > 36)
        throw new core.RangeError(radix);
      let result = this.toString(radix);
      let rightParenCode = 41;
      if (result.codeUnitAt(dart.notNull(result.length) - 1) != rightParenCode) {
        return result;
      }
      return JSNumber[_handleIEtoString](result);
    }
    static [_handleIEtoString](result) {
      let match = /^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(result);
      if (match == null) {
        throw new core.UnsupportedError(`Unexpected toString result: ${result}`);
      }
      let result = dart.dindex(match, 1);
      let exponent = +dart.dindex(match, 3);
      if (dart.dindex(match, 2) != null) {
        result = result + dart.dindex(match, 2);
        exponent = dart.notNull(exponent) - dart.dindex(match, 2).length;
      }
      return dart.notNull(result) + core.String['*']("0", exponent);
    }
    toString() {
      if (dart.notNull(dart.equals(this, 0)) && 1 / this < 0) {
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
      return this[_isInt32](this) ? this / other | 0 : (this / other).toInt();
    }
    [_tdivSlow](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      return (this / other).toInt();
    }
    ['<<'](other) {
      if (!dart.is(other, core.num))
        throw new core.ArgumentError(other);
      if (other < 0)
        throw new core.ArgumentError(other);
      return this[_shlPositive](other);
    }
    [_shlPositive](other) {
      return dart.as(other > 31 ? 0 : this << other >>> 0, core.num);
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
      return dart.as(this > 0 ? this[_shrBothPositive](other) : this >> (dart.notNull(other) > 31 ? 31 : other) >>> 0, core.num);
    }
    [_shrReceiverPositive](other) {
      if (other < 0)
        throw new core.ArgumentError(other);
      return this[_shrBothPositive](other);
    }
    [_shrBothPositive](other) {
      return dart.as(other > 31 ? 0 : this >>> other, core.num);
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
  JSNumber._MIN_INT32 = -2147483648;
  JSNumber._MAX_INT32 = 2147483647;
  let _bitCount = Symbol('_bitCount');
  let _spread = Symbol('_spread');
  let _shru = Symbol('_shru');
  let _shrs = Symbol('_shrs');
  let _ors = Symbol('_ors');
  class JSInt extends JSNumber {
    JSInt() {
      super.JSNumber();
    }
    get isEven() {
      return this['&'](1) == 0;
    }
    get isOdd() {
      return this['&'](1) == 1;
    }
    toUnsigned(width) {
      return this['&']((1 << dart.notNull(width)) - 1);
    }
    toSigned(width) {
      let signMask = 1 << dart.notNull(width) - 1;
      return dart.notNull(this['&'](dart.notNull(signMask) - 1)) - dart.notNull(this['&'](signMask));
    }
    get bitLength() {
      let nonneg = this['<'](0) ? dart.notNull(this['unary-']()) - 1 : this;
      if (dart.notNull(nonneg) >= 4294967296) {
        nonneg = (dart.notNull(nonneg) / 4294967296).truncate();
        return dart.notNull(JSInt[_bitCount](JSInt[_spread](nonneg))) + 32;
      }
      return JSInt[_bitCount](JSInt[_spread](nonneg));
    }
    static [_bitCount](i) {
      i = dart.as(dart.dsend(JSInt[_shru](i, 0), '-', dart.dsend(JSInt[_shru](i, 1), '&', 1431655765)), core.int);
      i = core.int['+'](dart.notNull(i) & 858993459, dart.dsend(JSInt[_shru](i, 2), '&', 858993459));
      i = 252645135 & core.int['+'](i, JSInt[_shru](i, 4));
      i = dart.notNull(i) + dart.notNull(dart.as(JSInt[_shru](i, 8), core.int));
      i = dart.notNull(i) + dart.notNull(dart.as(JSInt[_shru](i, 16), core.int));
      return dart.notNull(i) & 63;
    }
    static [_shru](value, shift) {
      return value >>> shift;
    }
    static [_shrs](value, shift) {
      return value >> shift;
    }
    static [_ors](a, b) {
      return a | b;
    }
    static [_spread](i) {
      i = dart.as(JSInt[_ors](i, dart.as(JSInt[_shrs](i, 1), core.int)), core.int);
      i = dart.as(JSInt[_ors](i, dart.as(JSInt[_shrs](i, 2), core.int)), core.int);
      i = dart.as(JSInt[_ors](i, dart.as(JSInt[_shrs](i, 4), core.int)), core.int);
      i = dart.as(JSInt[_ors](i, dart.as(JSInt[_shrs](i, 8), core.int)), core.int);
      i = dart.as(JSInt[_shru](dart.as(JSInt[_ors](i, dart.as(JSInt[_shrs](i, 16), core.int)), core.int), 0), core.int);
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
  class JSDouble extends JSNumber {
    JSDouble() {
      super.JSNumber();
    }
    get runtimeType() {
      return core.double;
    }
  }
  JSDouble[dart.implements] = () => [core.double];
  class JSPositiveInt extends JSInt {}
  class JSUInt32 extends JSPositiveInt {}
  class JSUInt31 extends JSUInt32 {}
  let _defaultSplit = Symbol('_defaultSplit');
  let _isWhitespace = Symbol('_isWhitespace');
  let _skipLeadingWhitespace = Symbol('_skipLeadingWhitespace');
  let _skipTrailingWhitespace = Symbol('_skipTrailingWhitespace');
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
        if (string.codeUnitAt(dart.notNull(start) + dart.notNull(i)) != this.codeUnitAt(i)) {
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
      return other == this.substring(dart.notNull(this.length) - dart.notNull(otherLength));
    }
    replaceAll(from, to) {
      _js_helper.checkString(to);
      return dart.as(_js_helper.stringReplaceAllUnchecked(this, from, to), core.String);
    }
    replaceAllMapped(from, convert) {
      return this.splitMapJoin(from, {onMatch: convert});
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
      let result = dart.setType([], core.List$(core.String));
      let start = 0;
      let length = 1;
      for (let match of pattern.allMatches(this)) {
        let matchStart = match.start;
        let matchEnd = match.end;
        length = dart.notNull(matchEnd) - dart.notNull(matchStart);
        if (length == 0 && start == matchStart) {
          continue;
        }
        let end = matchStart;
        result[core.$add](this.substring(start, end));
        start = matchEnd;
      }
      if (dart.notNull(start) < dart.notNull(this.length) || dart.notNull(length) > 0) {
        result[core.$add](this.substring(start));
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
      return pattern.matchAsPrefix(this, index) != null;
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
    static [_isWhitespace](codeUnit) {
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
    static [_skipLeadingWhitespace](string, index) {
      let SPACE = 32;
      let CARRIAGE_RETURN = 13;
      while (dart.notNull(index) < dart.notNull(string.length)) {
        let codeUnit = string.codeUnitAt(index);
        if (codeUnit != SPACE && codeUnit != CARRIAGE_RETURN && !dart.notNull(JSString[_isWhitespace](codeUnit))) {
          break;
        }
        index = dart.notNull(index) + 1;
      }
      return index;
    }
    static [_skipTrailingWhitespace](string, index) {
      let SPACE = 32;
      let CARRIAGE_RETURN = 13;
      while (dart.notNull(index) > 0) {
        let codeUnit = string.codeUnitAt(dart.notNull(index) - 1);
        if (codeUnit != SPACE && codeUnit != CARRIAGE_RETURN && !dart.notNull(JSString[_isWhitespace](codeUnit))) {
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
      let firstCode = result.codeUnitAt(0);
      let startIndex = 0;
      if (firstCode == NEL) {
        startIndex = JSString[_skipLeadingWhitespace](result, 1);
        if (startIndex == result.length)
          return "";
      }
      let endIndex = result.length;
      let lastCode = result.codeUnitAt(dart.notNull(endIndex) - 1);
      if (lastCode == NEL) {
        endIndex = JSString[_skipTrailingWhitespace](result, dart.notNull(endIndex) - 1);
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
        let firstCode = result.codeUnitAt(0);
        if (firstCode == NEL) {
          startIndex = JSString[_skipLeadingWhitespace](result, 1);
        }
      } else {
        result = this;
        startIndex = JSString[_skipLeadingWhitespace](this, 0);
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
        let lastCode = result.codeUnitAt(dart.notNull(endIndex) - 1);
        if (lastCode == NEL) {
          endIndex = JSString[_skipTrailingWhitespace](result, dart.notNull(endIndex) - 1);
        }
      } else {
        result = this;
        endIndex = JSString[_skipTrailingWhitespace](this, this.length);
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
        throw new core.OutOfMemoryError();
      }
      let result = '';
      let s = this;
      while (true) {
        if ((dart.notNull(times) & 1) == 1)
          result = s['+'](result);
        times = dart.as(times >>> 1, core.int);
        if (times == 0)
          break;
        s = s['+'](s);
      }
      return result;
    }
    padLeft(width, padding) {
      if (padding === void 0)
        padding = ' ';
      let delta = dart.notNull(width) - dart.notNull(this.length);
      if (dart.notNull(delta) <= 0)
        return this;
      return core.String['*'](padding, delta) + dart.notNull(this);
    }
    padRight(width, padding) {
      if (padding === void 0)
        padding = ' ';
      let delta = dart.notNull(width) - dart.notNull(this.length);
      if (dart.notNull(delta) <= 0)
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
        if (pattern.matchAsPrefix(this, i) != null)
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
        if (pattern.matchAsPrefix(this, i) != null)
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
      return !dart.notNull(this.isEmpty);
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
  let _string = Symbol('_string');
  class _CodeUnits extends _internal.UnmodifiableListBase$(core.int) {
    _CodeUnits(string) {
      this[_string] = string;
    }
    get [core.$length]() {
      return this[_string].length;
    }
    [core.$get](i) {
      return this[_string].codeUnitAt(i);
    }
  }
  // Function _symbolToString: (Symbol) → String
  function _symbolToString(symbol) {
    return _internal.Symbol.getName(dart.as(symbol, _internal.Symbol));
  }
  // Function _symbolMapToStringMap: (Map<Symbol, dynamic>) → dynamic
  function _symbolMapToStringMap(map) {
    if (map == null)
      return null;
    let result = new (core.Map$(core.String, dart.dynamic))();
    map.forEach((key, value) => {
      result.set(_symbolToString(key), value);
    });
    return result;
  }
  // Function getInterceptor: (dynamic) → dynamic
  function getInterceptor(object) {
    return void 0;
  }
  // Function getDispatchProperty: (dynamic) → dynamic
  function getDispatchProperty(object) {
    return object[_foreign_helper.JS_EMBEDDED_GLOBAL('String', _js_embedded_names.DISPATCH_PROPERTY_NAME)];
  }
  // Function setDispatchProperty: (dynamic, dynamic) → dynamic
  function setDispatchProperty(object, value) {
    _js_helper.defineProperty(object, dart.as(_foreign_helper.JS_EMBEDDED_GLOBAL('String', _js_embedded_names.DISPATCH_PROPERTY_NAME), core.String), value);
  }
  // Function makeDispatchRecord: (dynamic, dynamic, dynamic, dynamic) → dynamic
  function makeDispatchRecord(interceptor, proto, extension, indexability) {
    return {i: interceptor, p: proto, e: extension, x: indexability};
  }
  // Function dispatchRecordInterceptor: (dynamic) → dynamic
  function dispatchRecordInterceptor(record) {
    return record.i;
  }
  // Function dispatchRecordProto: (dynamic) → dynamic
  function dispatchRecordProto(record) {
    return record.p;
  }
  // Function dispatchRecordExtension: (dynamic) → dynamic
  function dispatchRecordExtension(record) {
    return record.e;
  }
  // Function dispatchRecordIndexability: (dynamic) → dynamic
  function dispatchRecordIndexability(record) {
    return record.x;
  }
  // Function getNativeInterceptor: (dynamic) → dynamic
  function getNativeInterceptor(object) {
    let record = getDispatchProperty(object);
    if (record == null) {
      if (_js_helper.initNativeDispatchFlag == null) {
        _js_helper.initNativeDispatch();
        record = getDispatchProperty(object);
      }
    }
    if (record != null) {
      let proto = dispatchRecordProto(record);
      if (dart.equals(false, proto))
        return dispatchRecordInterceptor(record);
      if (dart.equals(true, proto))
        return object;
      let objectProto = Object.getPrototypeOf(object);
      if (proto === objectProto) {
        return dispatchRecordInterceptor(record);
      }
      let extension = dispatchRecordExtension(record);
      if (extension === objectProto) {
        let discriminatedTag = proto(object, record);
        throw new core.UnimplementedError(`Return interceptor for ${discriminatedTag}`);
      }
    }
    let interceptor = _js_helper.lookupAndCacheInterceptor(object);
    if (interceptor == null) {
      let proto = Object.getPrototypeOf(object);
      if (proto == null || proto === Object.prototype) {
        return _foreign_helper.JS_INTERCEPTOR_CONSTANT(PlainJavaScriptObject);
      } else {
        return _foreign_helper.JS_INTERCEPTOR_CONSTANT(UnknownJavaScriptObject);
      }
    }
    return interceptor;
  }
  dart.copyProperties(exports, {
    get mapTypeToInterceptor() {
      return _foreign_helper.JS_EMBEDDED_GLOBAL('', _js_embedded_names.MAP_TYPE_TO_INTERCEPTOR);
    }
  });
  // Function findIndexForNativeSubclassType: (Type) → int
  function findIndexForNativeSubclassType(type) {
    if (exports.mapTypeToInterceptor == null)
      return null;
    let map = dart.as(exports.mapTypeToInterceptor, core.List);
    for (let i = 0; dart.notNull(i) + 1 < dart.notNull(map[core.$length]); i = dart.notNull(i) + 3) {
      if (dart.equals(type, map[core.$get](i))) {
        return i;
      }
    }
    return null;
  }
  // Function findInterceptorConstructorForType: (Type) → dynamic
  function findInterceptorConstructorForType(type) {
    let index = findIndexForNativeSubclassType(type);
    if (index == null)
      return null;
    let map = dart.as(exports.mapTypeToInterceptor, core.List);
    return map[core.$get](dart.notNull(index) + 1);
  }
  // Function findConstructorForNativeSubclassType: (Type, String) → dynamic
  function findConstructorForNativeSubclassType(type, name) {
    let index = findIndexForNativeSubclassType(type);
    if (index == null)
      return null;
    let map = dart.as(exports.mapTypeToInterceptor, core.List);
    let constructorMap = map[core.$get](dart.notNull(index) + 2);
    let constructorFn = constructorMap[name];
    return constructorFn;
  }
  // Function findInterceptorForType: (Type) → dynamic
  function findInterceptorForType(type) {
    let constructor = findInterceptorConstructorForType(type);
    if (constructor == null)
      return null;
    return constructor.prototype;
  }
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
  JSNull[dart.implements] = () => [core.Null];
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
      return String(this);
    }
  }
  // Exports:
  exports.JSArray = JSArray;
  exports.JSMutableArray$ = JSMutableArray$;
  exports.JSMutableArray = JSMutableArray;
  exports.JSFixedArray$ = JSFixedArray$;
  exports.JSFixedArray = JSFixedArray;
  exports.JSExtendableArray$ = JSExtendableArray$;
  exports.JSExtendableArray = JSExtendableArray;
  exports.JSNumber = JSNumber;
  exports.Interceptor = Interceptor;
  exports.JSInt = JSInt;
  exports.JSDouble = JSDouble;
  exports.JSPositiveInt = JSPositiveInt;
  exports.JSUInt32 = JSUInt32;
  exports.JSUInt31 = JSUInt31;
  exports.JSString = JSString;
  exports.getInterceptor = getInterceptor;
  exports.getDispatchProperty = getDispatchProperty;
  exports.setDispatchProperty = setDispatchProperty;
  exports.makeDispatchRecord = makeDispatchRecord;
  exports.dispatchRecordInterceptor = dispatchRecordInterceptor;
  exports.dispatchRecordProto = dispatchRecordProto;
  exports.dispatchRecordExtension = dispatchRecordExtension;
  exports.dispatchRecordIndexability = dispatchRecordIndexability;
  exports.getNativeInterceptor = getNativeInterceptor;
  exports.findIndexForNativeSubclassType = findIndexForNativeSubclassType;
  exports.findInterceptorConstructorForType = findInterceptorConstructorForType;
  exports.findConstructorForNativeSubclassType = findConstructorForNativeSubclassType;
  exports.findInterceptorForType = findInterceptorForType;
  exports.JSBool = JSBool;
  exports.JSNull = JSNull;
  exports.JSIndexable = JSIndexable;
  exports.JSMutableIndexable = JSMutableIndexable;
  exports.JSObject = JSObject;
  exports.JavaScriptObject = JavaScriptObject;
  exports.PlainJavaScriptObject = PlainJavaScriptObject;
  exports.UnknownJavaScriptObject = UnknownJavaScriptObject;
})(_interceptors || (_interceptors = {}));
