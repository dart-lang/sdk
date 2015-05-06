var core = dart.defineLibrary(core, {});
var _js_helper = dart.lazyImport(_js_helper);
var _internal = dart.lazyImport(_internal);
var collection = dart.lazyImport(collection);
var _interceptors = dart.lazyImport(_interceptors);
var convert = dart.lazyImport(convert);
(function(exports, _js_helper, _internal, collection, _interceptors, convert) {
  'use strict';
  class Object {
    constructor() {
      let name = this.constructor.name;
      let init = this[name];
      let result = void 0;
      if (init)
        result = init.apply(this, arguments);
      return result === void 0 ? this : result;
    }
    ['=='](other) {
      return identical(this, other);
    }
    get hashCode() {
      return _js_helper.Primitives.objectHashCode(this);
    }
    toString() {
      return _js_helper.Primitives.objectToString(this);
    }
    noSuchMethod(invocation) {
      throw new NoSuchMethodError(this, invocation.memberName, invocation.positionalArguments, invocation.namedArguments);
    }
    get runtimeType() {
      return dart.realRuntimeType(this);
    }
  }
  class JsName extends Object {
    JsName(opts) {
      let name = opts && 'name' in opts ? opts.name : null;
      this.name = name;
    }
  }
  class JsPeerInterface extends Object {
    JsPeerInterface(opts) {
      let name = opts && 'name' in opts ? opts.name : null;
      this.name = name;
    }
  }
  class SupportJsExtensionMethod extends Object {
    SupportJsExtensionMethod() {
    }
  }
  class Deprecated extends Object {
    Deprecated(expires) {
      this.expires = expires;
    }
    toString() {
      return `Deprecated feature. Will be removed ${this.expires}`;
    }
  }
  class _Override extends Object {
    _Override() {
    }
  }
  let deprecated = dart.const(new Deprecated("next release"));
  let override = dart.const(new _Override());
  class _Proxy extends Object {
    _Proxy() {
    }
  }
  let proxy = dart.const(new _Proxy());
  class bool extends Object {
    fromEnvironment(name, opts) {
      let defaultValue = opts && 'defaultValue' in opts ? opts.defaultValue : false;
      throw new UnsupportedError('bool.fromEnvironment can only be used as a const constructor');
    }
    toString() {
      return this ? "true" : "false";
    }
  }
  dart.defineNamedConstructor(bool, 'fromEnvironment');
  class Function extends Object {
    static apply(f, positionalArguments, namedArguments) {
      if (namedArguments === void 0)
        namedArguments = null;
      return _js_helper.Primitives.applyFunction(f, positionalArguments, namedArguments == null ? null : Function._toMangledNames(namedArguments));
    }
    static _toMangledNames(namedArguments) {
      let result = dart.map();
      namedArguments.forEach((symbol, value) => {
        result.set(_symbolToString(dart.as(symbol, Symbol)), value);
      });
      return result;
    }
  }
  let Comparator$ = dart.generic(function(T) {
    let Comparator = dart.typedef('Comparator', () => dart.functionType(int, [T, T]));
    return Comparator;
  });
  let Comparator = Comparator$();
  let Comparable$ = dart.generic(function(T) {
    class Comparable extends Object {
      static compare(a, b) {
        return a.compareTo(b);
      }
    }
    return Comparable;
  });
  let Comparable = Comparable$();
  class DateTime extends Object {
    DateTime(year, month, day, hour, minute, second, millisecond) {
      if (month === void 0)
        month = 1;
      if (day === void 0)
        day = 1;
      if (hour === void 0)
        hour = 0;
      if (minute === void 0)
        minute = 0;
      if (second === void 0)
        second = 0;
      if (millisecond === void 0)
        millisecond = 0;
      this._internal(year, month, day, hour, minute, second, millisecond, false);
    }
    utc(year, month, day, hour, minute, second, millisecond) {
      if (month === void 0)
        month = 1;
      if (day === void 0)
        day = 1;
      if (hour === void 0)
        hour = 0;
      if (minute === void 0)
        minute = 0;
      if (second === void 0)
        second = 0;
      if (millisecond === void 0)
        millisecond = 0;
      this._internal(year, month, day, hour, minute, second, millisecond, true);
    }
    now() {
      this._now();
    }
    static parse(formattedString) {
      let re = new RegExp('^([+-]?\\d{4,6})-?(\\d\\d)-?(\\d\\d)' + '(?:[ T](\\d\\d)(?::?(\\d\\d)(?::?(\\d\\d)(.\\d{1,6})?)?)?' + '( ?[zZ]| ?([-+])(\\d\\d)(?::?(\\d\\d))?)?)?$');
      let match = re.firstMatch(formattedString);
      if (match != null) {
        // Function parseIntOrZero: (String) → int
        function parseIntOrZero(matched) {
          if (matched == null)
            return 0;
          return int.parse(matched);
        }
        // Function parseDoubleOrZero: (String) → double
        function parseDoubleOrZero(matched) {
          if (matched == null)
            return 0.0;
          return double.parse(matched);
        }
        let years = int.parse(match.get(1));
        let month = int.parse(match.get(2));
        let day = int.parse(match.get(3));
        let hour = parseIntOrZero(match.get(4));
        let minute = parseIntOrZero(match.get(5));
        let second = parseIntOrZero(match.get(6));
        let addOneMillisecond = false;
        let millisecond = (dart.notNull(parseDoubleOrZero(match.get(7))) * 1000).round();
        if (millisecond == 1000) {
          addOneMillisecond = true;
          millisecond = 999;
        }
        let isUtc = false;
        if (match.get(8) != null) {
          isUtc = true;
          if (match.get(9) != null) {
            let sign = match.get(9) == '-' ? -1 : 1;
            let hourDifference = int.parse(match.get(10));
            let minuteDifference = parseIntOrZero(match.get(11));
            minuteDifference = dart.notNull(minuteDifference) + 60 * dart.notNull(hourDifference);
            minute = dart.notNull(minute) - dart.notNull(sign) * dart.notNull(minuteDifference);
          }
        }
        let millisecondsSinceEpoch = DateTime._brokenDownDateToMillisecondsSinceEpoch(years, month, day, hour, minute, second, millisecond, isUtc);
        if (millisecondsSinceEpoch == null) {
          throw new FormatException("Time out of range", formattedString);
        }
        if (addOneMillisecond) {
          millisecondsSinceEpoch = dart.notNull(millisecondsSinceEpoch) + 1;
        }
        return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, {isUtc: isUtc});
      } else {
        throw new FormatException("Invalid date format", formattedString);
      }
    }
    fromMillisecondsSinceEpoch(millisecondsSinceEpoch, opts) {
      let isUtc = opts && 'isUtc' in opts ? opts.isUtc : false;
      this.millisecondsSinceEpoch = millisecondsSinceEpoch;
      this.isUtc = isUtc;
      if (dart.notNull(millisecondsSinceEpoch.abs()) > dart.notNull(DateTime._MAX_MILLISECONDS_SINCE_EPOCH)) {
        throw new ArgumentError(millisecondsSinceEpoch);
      }
      if (isUtc == null)
        throw new ArgumentError(isUtc);
    }
    ['=='](other) {
      if (!dart.is(other, DateTime))
        return false;
      return dart.equals(this.millisecondsSinceEpoch, dart.dload(other, 'millisecondsSinceEpoch')) && dart.equals(this.isUtc, dart.dload(other, 'isUtc'));
    }
    isBefore(other) {
      return dart.notNull(this.millisecondsSinceEpoch) < dart.notNull(other.millisecondsSinceEpoch);
    }
    isAfter(other) {
      return dart.notNull(this.millisecondsSinceEpoch) > dart.notNull(other.millisecondsSinceEpoch);
    }
    isAtSameMomentAs(other) {
      return this.millisecondsSinceEpoch == other.millisecondsSinceEpoch;
    }
    compareTo(other) {
      return this.millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch);
    }
    get hashCode() {
      return this.millisecondsSinceEpoch;
    }
    toLocal() {
      if (this.isUtc) {
        return new DateTime.fromMillisecondsSinceEpoch(this.millisecondsSinceEpoch, {isUtc: false});
      }
      return this;
    }
    toUtc() {
      if (this.isUtc)
        return this;
      return new DateTime.fromMillisecondsSinceEpoch(this.millisecondsSinceEpoch, {isUtc: true});
    }
    static _fourDigits(n) {
      let absN = n.abs();
      let sign = dart.notNull(n) < 0 ? "-" : "";
      if (dart.notNull(absN) >= 1000)
        return `${n}`;
      if (dart.notNull(absN) >= 100)
        return `${sign}0${absN}`;
      if (dart.notNull(absN) >= 10)
        return `${sign}00${absN}`;
      return `${sign}000${absN}`;
    }
    static _sixDigits(n) {
      dart.assert(dart.notNull(n) < -9999 || dart.notNull(n) > 9999);
      let absN = n.abs();
      let sign = dart.notNull(n) < 0 ? "-" : "+";
      if (dart.notNull(absN) >= 100000)
        return `${sign}${absN}`;
      return `${sign}0${absN}`;
    }
    static _threeDigits(n) {
      if (dart.notNull(n) >= 100)
        return `${n}`;
      if (dart.notNull(n) >= 10)
        return `0${n}`;
      return `00${n}`;
    }
    static _twoDigits(n) {
      if (dart.notNull(n) >= 10)
        return `${n}`;
      return `0${n}`;
    }
    toString() {
      let y = DateTime._fourDigits(this.year);
      let m = DateTime._twoDigits(this.month);
      let d = DateTime._twoDigits(this.day);
      let h = DateTime._twoDigits(this.hour);
      let min = DateTime._twoDigits(this.minute);
      let sec = DateTime._twoDigits(this.second);
      let ms = DateTime._threeDigits(this.millisecond);
      if (this.isUtc) {
        return `${y}-${m}-${d} ${h}:${min}:${sec}.${ms}Z`;
      } else {
        return `${y}-${m}-${d} ${h}:${min}:${sec}.${ms}`;
      }
    }
    toIso8601String() {
      let y = dart.notNull(this.year) >= -9999 && dart.notNull(this.year) <= 9999 ? DateTime._fourDigits(this.year) : DateTime._sixDigits(this.year);
      let m = DateTime._twoDigits(this.month);
      let d = DateTime._twoDigits(this.day);
      let h = DateTime._twoDigits(this.hour);
      let min = DateTime._twoDigits(this.minute);
      let sec = DateTime._twoDigits(this.second);
      let ms = DateTime._threeDigits(this.millisecond);
      if (this.isUtc) {
        return `${y}-${m}-${d}T${h}:${min}:${sec}.${ms}Z`;
      } else {
        return `${y}-${m}-${d}T${h}:${min}:${sec}.${ms}`;
      }
    }
    add(duration) {
      let ms = this.millisecondsSinceEpoch;
      return new DateTime.fromMillisecondsSinceEpoch(dart.notNull(ms) + dart.notNull(duration.inMilliseconds), {isUtc: this.isUtc});
    }
    subtract(duration) {
      let ms = this.millisecondsSinceEpoch;
      return new DateTime.fromMillisecondsSinceEpoch(dart.notNull(ms) - dart.notNull(duration.inMilliseconds), {isUtc: this.isUtc});
    }
    difference(other) {
      let ms = this.millisecondsSinceEpoch;
      let otherMs = other.millisecondsSinceEpoch;
      return new Duration({milliseconds: dart.notNull(ms) - dart.notNull(otherMs)});
    }
    _internal(year, month, day, hour, minute, second, millisecond, isUtc) {
      this.isUtc = typeof isUtc == 'boolean' ? isUtc : dart.throw_(new ArgumentError(isUtc));
      this.millisecondsSinceEpoch = dart.as(_js_helper.checkInt(_js_helper.Primitives.valueFromDecomposedDate(year, month, day, hour, minute, second, millisecond, isUtc)), int);
    }
    _now() {
      this.isUtc = false;
      this.millisecondsSinceEpoch = _js_helper.Primitives.dateNow();
    }
    static _brokenDownDateToMillisecondsSinceEpoch(year, month, day, hour, minute, second, millisecond, isUtc) {
      return dart.as(_js_helper.Primitives.valueFromDecomposedDate(year, month, day, hour, minute, second, millisecond, isUtc), int);
    }
    get timeZoneName() {
      if (this.isUtc)
        return "UTC";
      return _js_helper.Primitives.getTimeZoneName(this);
    }
    get timeZoneOffset() {
      if (this.isUtc)
        return new Duration();
      return new Duration({minutes: _js_helper.Primitives.getTimeZoneOffsetInMinutes(this)});
    }
    get year() {
      return dart.as(_js_helper.Primitives.getYear(this), int);
    }
    get month() {
      return dart.as(_js_helper.Primitives.getMonth(this), int);
    }
    get day() {
      return dart.as(_js_helper.Primitives.getDay(this), int);
    }
    get hour() {
      return dart.as(_js_helper.Primitives.getHours(this), int);
    }
    get minute() {
      return dart.as(_js_helper.Primitives.getMinutes(this), int);
    }
    get second() {
      return dart.as(_js_helper.Primitives.getSeconds(this), int);
    }
    get millisecond() {
      return dart.as(_js_helper.Primitives.getMilliseconds(this), int);
    }
    get weekday() {
      return dart.as(_js_helper.Primitives.getWeekday(this), int);
    }
  }
  DateTime[dart.implements] = () => [Comparable];
  dart.defineNamedConstructor(DateTime, 'utc');
  dart.defineNamedConstructor(DateTime, 'now');
  dart.defineNamedConstructor(DateTime, 'fromMillisecondsSinceEpoch');
  dart.defineNamedConstructor(DateTime, '_internal');
  dart.defineNamedConstructor(DateTime, '_now');
  DateTime.MONDAY = 1;
  DateTime.TUESDAY = 2;
  DateTime.WEDNESDAY = 3;
  DateTime.THURSDAY = 4;
  DateTime.FRIDAY = 5;
  DateTime.SATURDAY = 6;
  DateTime.SUNDAY = 7;
  DateTime.DAYS_PER_WEEK = 7;
  DateTime.JANUARY = 1;
  DateTime.FEBRUARY = 2;
  DateTime.MARCH = 3;
  DateTime.APRIL = 4;
  DateTime.MAY = 5;
  DateTime.JUNE = 6;
  DateTime.JULY = 7;
  DateTime.AUGUST = 8;
  DateTime.SEPTEMBER = 9;
  DateTime.OCTOBER = 10;
  DateTime.NOVEMBER = 11;
  DateTime.DECEMBER = 12;
  DateTime.MONTHS_PER_YEAR = 12;
  DateTime._MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;
  class num extends Object {
    static parse(input, onError) {
      if (onError === void 0)
        onError = null;
      let source = input.trim();
      num._parseError = false;
      let result = int.parse(source, {onError: num._onParseErrorInt});
      if (!dart.notNull(num._parseError))
        return result;
      num._parseError = false;
      result = double.parse(source, num._onParseErrorDouble);
      if (!dart.notNull(num._parseError))
        return result;
      if (onError == null)
        throw new FormatException(input);
      return onError(input);
    }
    static _onParseErrorInt(_) {
      num._parseError = true;
      return 0;
    }
    static _onParseErrorDouble(_) {
      num._parseError = true;
      return 0.0;
    }
  }
  num[dart.implements] = () => [Comparable$(num)];
  num._parseError = false;
  class double extends num {
    static parse(source, onError) {
      if (onError === void 0)
        onError = null;
      return _js_helper.Primitives.parseDouble(source, onError);
    }
  }
  double.NAN = 0.0 / 0.0;
  double.INFINITY = 1.0 / 0.0;
  double.NEGATIVE_INFINITY = -dart.notNull(double.INFINITY);
  double.MIN_POSITIVE = 5e-324;
  double.MAX_FINITE = 1.7976931348623157e+308;
  let _duration = dart.JsSymbol('_duration');
  class Duration extends Object {
    Duration(opts) {
      let days = opts && 'days' in opts ? opts.days : 0;
      let hours = opts && 'hours' in opts ? opts.hours : 0;
      let minutes = opts && 'minutes' in opts ? opts.minutes : 0;
      let seconds = opts && 'seconds' in opts ? opts.seconds : 0;
      let milliseconds = opts && 'milliseconds' in opts ? opts.milliseconds : 0;
      let microseconds = opts && 'microseconds' in opts ? opts.microseconds : 0;
      this._microseconds(dart.notNull(days) * dart.notNull(Duration.MICROSECONDS_PER_DAY) + dart.notNull(hours) * dart.notNull(Duration.MICROSECONDS_PER_HOUR) + dart.notNull(minutes) * dart.notNull(Duration.MICROSECONDS_PER_MINUTE) + dart.notNull(seconds) * dart.notNull(Duration.MICROSECONDS_PER_SECOND) + dart.notNull(milliseconds) * dart.notNull(Duration.MICROSECONDS_PER_MILLISECOND) + dart.notNull(microseconds));
    }
    _microseconds(duration) {
      this[_duration] = duration;
    }
    ['+'](other) {
      return new Duration._microseconds(dart.notNull(this[_duration]) + dart.notNull(other[_duration]));
    }
    ['-'](other) {
      return new Duration._microseconds(dart.notNull(this[_duration]) - dart.notNull(other[_duration]));
    }
    ['*'](factor) {
      return new Duration._microseconds((dart.notNull(this[_duration]) * dart.notNull(factor)).round());
    }
    ['~/'](quotient) {
      if (quotient == 0)
        throw new IntegerDivisionByZeroException();
      return new Duration._microseconds((dart.notNull(this[_duration]) / dart.notNull(quotient)).truncate());
    }
    ['<'](other) {
      return dart.notNull(this[_duration]) < dart.notNull(other[_duration]);
    }
    ['>'](other) {
      return dart.notNull(this[_duration]) > dart.notNull(other[_duration]);
    }
    ['<='](other) {
      return dart.notNull(this[_duration]) <= dart.notNull(other[_duration]);
    }
    ['>='](other) {
      return dart.notNull(this[_duration]) >= dart.notNull(other[_duration]);
    }
    get inDays() {
      return (dart.notNull(this[_duration]) / dart.notNull(Duration.MICROSECONDS_PER_DAY)).truncate();
    }
    get inHours() {
      return (dart.notNull(this[_duration]) / dart.notNull(Duration.MICROSECONDS_PER_HOUR)).truncate();
    }
    get inMinutes() {
      return (dart.notNull(this[_duration]) / dart.notNull(Duration.MICROSECONDS_PER_MINUTE)).truncate();
    }
    get inSeconds() {
      return (dart.notNull(this[_duration]) / dart.notNull(Duration.MICROSECONDS_PER_SECOND)).truncate();
    }
    get inMilliseconds() {
      return (dart.notNull(this[_duration]) / dart.notNull(Duration.MICROSECONDS_PER_MILLISECOND)).truncate();
    }
    get inMicroseconds() {
      return this[_duration];
    }
    ['=='](other) {
      if (!dart.is(other, Duration))
        return false;
      return dart.equals(this[_duration], dart.dload(other, _duration));
    }
    get hashCode() {
      return dart.hashCode(this[_duration]);
    }
    compareTo(other) {
      return this[_duration].compareTo(other[_duration]);
    }
    toString() {
      // Function sixDigits: (int) → String
      function sixDigits(n) {
        if (dart.notNull(n) >= 100000)
          return `${n}`;
        if (dart.notNull(n) >= 10000)
          return `0${n}`;
        if (dart.notNull(n) >= 1000)
          return `00${n}`;
        if (dart.notNull(n) >= 100)
          return `000${n}`;
        if (dart.notNull(n) >= 10)
          return `0000${n}`;
        return `00000${n}`;
      }
      // Function twoDigits: (int) → String
      function twoDigits(n) {
        if (dart.notNull(n) >= 10)
          return `${n}`;
        return `0${n}`;
      }
      if (dart.notNull(this.inMicroseconds) < 0) {
        return `-${this['unary-']()}`;
      }
      let twoDigitMinutes = twoDigits(this.inMinutes.remainder(Duration.MINUTES_PER_HOUR));
      let twoDigitSeconds = twoDigits(this.inSeconds.remainder(Duration.SECONDS_PER_MINUTE));
      let sixDigitUs = sixDigits(this.inMicroseconds.remainder(Duration.MICROSECONDS_PER_SECOND));
      return `${this.inHours}:${twoDigitMinutes}:${twoDigitSeconds}.${sixDigitUs}`;
    }
    get isNegative() {
      return dart.notNull(this[_duration]) < 0;
    }
    abs() {
      return new Duration._microseconds(this[_duration].abs());
    }
    ['unary-']() {
      return new Duration._microseconds(-dart.notNull(this[_duration]));
    }
  }
  Duration[dart.implements] = () => [Comparable$(Duration)];
  dart.defineNamedConstructor(Duration, '_microseconds');
  Duration.MICROSECONDS_PER_MILLISECOND = 1000;
  Duration.MILLISECONDS_PER_SECOND = 1000;
  Duration.SECONDS_PER_MINUTE = 60;
  Duration.MINUTES_PER_HOUR = 60;
  Duration.HOURS_PER_DAY = 24;
  Duration.MICROSECONDS_PER_SECOND = dart.notNull(Duration.MICROSECONDS_PER_MILLISECOND) * dart.notNull(Duration.MILLISECONDS_PER_SECOND);
  Duration.MICROSECONDS_PER_MINUTE = dart.notNull(Duration.MICROSECONDS_PER_SECOND) * dart.notNull(Duration.SECONDS_PER_MINUTE);
  Duration.MICROSECONDS_PER_HOUR = dart.notNull(Duration.MICROSECONDS_PER_MINUTE) * dart.notNull(Duration.MINUTES_PER_HOUR);
  Duration.MICROSECONDS_PER_DAY = dart.notNull(Duration.MICROSECONDS_PER_HOUR) * dart.notNull(Duration.HOURS_PER_DAY);
  Duration.MILLISECONDS_PER_MINUTE = dart.notNull(Duration.MILLISECONDS_PER_SECOND) * dart.notNull(Duration.SECONDS_PER_MINUTE);
  Duration.MILLISECONDS_PER_HOUR = dart.notNull(Duration.MILLISECONDS_PER_MINUTE) * dart.notNull(Duration.MINUTES_PER_HOUR);
  Duration.MILLISECONDS_PER_DAY = dart.notNull(Duration.MILLISECONDS_PER_HOUR) * dart.notNull(Duration.HOURS_PER_DAY);
  Duration.SECONDS_PER_HOUR = dart.notNull(Duration.SECONDS_PER_MINUTE) * dart.notNull(Duration.MINUTES_PER_HOUR);
  Duration.SECONDS_PER_DAY = dart.notNull(Duration.SECONDS_PER_HOUR) * dart.notNull(Duration.HOURS_PER_DAY);
  Duration.MINUTES_PER_DAY = dart.notNull(Duration.MINUTES_PER_HOUR) * dart.notNull(Duration.HOURS_PER_DAY);
  Duration.ZERO = dart.const(new Duration({seconds: 0}));
  class Error extends Object {
    Error() {
    }
    static safeToString(object) {
      if (dart.is(object, num) || typeof object == 'boolean' || dart.notNull(null == object)) {
        return dart.toString(object);
      }
      if (typeof object == 'string') {
        return Error._stringToSafeString(object);
      }
      return Error._objectToString(object);
    }
    static _stringToSafeString(string) {
      return _js_helper.jsonEncodeNative(string);
    }
    static _objectToString(object) {
      return _js_helper.Primitives.objectToString(object);
    }
    get stackTrace() {
      return _js_helper.Primitives.extractStackTrace(this);
    }
  }
  class AssertionError extends Error {
    AssertionError() {
      super.Error();
    }
  }
  class TypeError extends AssertionError {}
  class CastError extends Error {
    CastError() {
      super.Error();
    }
  }
  class NullThrownError extends Error {
    NullThrownError() {
      super.Error();
    }
    toString() {
      return "Throw of null.";
    }
  }
  let _hasValue = dart.JsSymbol('_hasValue');
  class ArgumentError extends Error {
    ArgumentError(message) {
      if (message === void 0)
        message = null;
      this.message = message;
      this.invalidValue = null;
      this[_hasValue] = false;
      this.name = null;
      super.Error();
    }
    value(value, name, message) {
      if (name === void 0)
        name = null;
      if (message === void 0)
        message = "Invalid argument";
      this.name = name;
      this.message = message;
      this.invalidValue = value;
      this[_hasValue] = true;
      super.Error();
    }
    notNull(name) {
      if (name === void 0)
        name = null;
      this.value(null, name, "Must not be null");
    }
    toString() {
      if (!dart.notNull(this[_hasValue])) {
        let result = "Invalid arguments(s)";
        if (this.message != null) {
          result = `${result}: ${this.message}`;
        }
        return result;
      }
      let nameString = "";
      if (this.name != null) {
        nameString = ` (${this.name})`;
      }
      return `${this.message}${nameString}: ${Error.safeToString(this.invalidValue)}`;
    }
  }
  dart.defineNamedConstructor(ArgumentError, 'value');
  dart.defineNamedConstructor(ArgumentError, 'notNull');
  class RangeError extends ArgumentError {
    RangeError(message) {
      this.start = null;
      this.end = null;
      super.ArgumentError(message);
    }
    value(value, name, message) {
      if (name === void 0)
        name = null;
      if (message === void 0)
        message = null;
      this.start = null;
      this.end = null;
      super.value(value, name, message != null ? message : "Value not in range");
    }
    range(invalidValue, minValue, maxValue, name, message) {
      if (name === void 0)
        name = null;
      if (message === void 0)
        message = null;
      this.start = minValue;
      this.end = maxValue;
      super.value(invalidValue, name, message != null ? message : "Invalid value");
    }
    index(index, indexable, name, message, length) {
      return new IndexError(index, indexable, name, message, length);
    }
    static checkValueInInterval(value, minValue, maxValue, name, message) {
      if (name === void 0)
        name = null;
      if (message === void 0)
        message = null;
      if (dart.notNull(value) < dart.notNull(minValue) || dart.notNull(value) > dart.notNull(maxValue)) {
        throw new RangeError.range(value, minValue, maxValue, name, message);
      }
    }
    static checkValidIndex(index, indexable, name, length, message) {
      if (name === void 0)
        name = null;
      if (length === void 0)
        length = null;
      if (message === void 0)
        message = null;
      if (length == null)
        length = dart.as(dart.dload(indexable, 'length'), int);
      if (dart.notNull(index) < 0 || dart.notNull(index) >= dart.notNull(length)) {
        if (name == null)
          name = "index";
        throw new RangeError.index(index, indexable, name, message, length);
      }
    }
    static checkValidRange(start, end, length, startName, endName, message) {
      if (startName === void 0)
        startName = null;
      if (endName === void 0)
        endName = null;
      if (message === void 0)
        message = null;
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(length)) {
        if (startName == null)
          startName = "start";
        throw new RangeError.range(start, 0, length, startName, message);
      }
      if (end != null && (dart.notNull(end) < dart.notNull(start) || dart.notNull(end) > dart.notNull(length))) {
        if (endName == null)
          endName = "end";
        throw new RangeError.range(end, start, length, endName, message);
      }
    }
    static checkNotNegative(value, name, message) {
      if (name === void 0)
        name = null;
      if (message === void 0)
        message = null;
      if (dart.notNull(value) < 0)
        throw new RangeError.range(value, 0, null, name, message);
    }
    toString() {
      if (!dart.notNull(this[_hasValue]))
        return `RangeError: ${this.message}`;
      let value = Error.safeToString(this.invalidValue);
      let explanation = "";
      if (this.start == null) {
        if (this.end != null) {
          explanation = `: Not less than or equal to ${this.end}`;
        }
      } else if (this.end == null) {
        explanation = `: Not greater than or equal to ${this.start}`;
      } else if (dart.notNull(this.end) > dart.notNull(this.start)) {
        explanation = `: Not in range ${this.start}..${this.end}, inclusive.`;
      } else if (dart.notNull(this.end) < dart.notNull(this.start)) {
        explanation = ": Valid value range is empty";
      } else {
        explanation = `: Only valid value is ${this.start}`;
      }
      return `RangeError: ${this.message} (${value})${explanation}`;
    }
  }
  dart.defineNamedConstructor(RangeError, 'value');
  dart.defineNamedConstructor(RangeError, 'range');
  dart.defineNamedConstructor(RangeError, 'index');
  class IndexError extends ArgumentError {
    IndexError(invalidValue, indexable, name, message, length) {
      if (name === void 0)
        name = null;
      if (message === void 0)
        message = null;
      if (length === void 0)
        length = null;
      this.indexable = indexable;
      this.length = length != null ? length : dart.as(dart.dload(indexable, 'length'), int);
      super.value(invalidValue, name, message != null ? message : "Index out of range");
    }
    get start() {
      return 0;
    }
    get end() {
      return dart.notNull(this.length) - 1;
    }
    toString() {
      dart.assert(this[_hasValue]);
      let target = Error.safeToString(this.indexable);
      let explanation = `index should be less than ${this.length}`;
      if (dart.dsend(this.invalidValue, '<', 0)) {
        explanation = "index must not be negative";
      }
      return `RangeError: ${this.message} (${target}[${this.invalidValue}]): ${explanation}`;
    }
  }
  IndexError[dart.implements] = () => [RangeError];
  class FallThroughError extends Error {
    FallThroughError() {
      super.Error();
    }
  }
  let _className = dart.JsSymbol('_className');
  class AbstractClassInstantiationError extends Error {
    AbstractClassInstantiationError(className) {
      this[_className] = className;
      super.Error();
    }
    toString() {
      return `Cannot instantiate abstract class: '${this[_className]}'`;
    }
  }
  let _receiver = dart.JsSymbol('_receiver');
  let _memberName = dart.JsSymbol('_memberName');
  let _arguments = dart.JsSymbol('_arguments');
  let _namedArguments = dart.JsSymbol('_namedArguments');
  let _existingArgumentNames = dart.JsSymbol('_existingArgumentNames');
  let $length = dart.JsSymbol('$length');
  let $get = dart.JsSymbol('$get');
  class NoSuchMethodError extends Error {
    NoSuchMethodError(receiver, memberName, positionalArguments, namedArguments, existingArgumentNames) {
      if (existingArgumentNames === void 0)
        existingArgumentNames = null;
      this[_receiver] = receiver;
      this[_memberName] = memberName;
      this[_arguments] = positionalArguments;
      this[_namedArguments] = namedArguments;
      this[_existingArgumentNames] = existingArgumentNames;
      super.Error();
    }
    toString() {
      let sb = new StringBuffer();
      let i = 0;
      if (this[_arguments] != null) {
        for (; dart.notNull(i) < dart.notNull(this[_arguments][$length]); i = dart.notNull(i) + 1) {
          if (dart.notNull(i) > 0) {
            sb.write(", ");
          }
          sb.write(Error.safeToString(this[_arguments][$get](i)));
        }
      }
      if (this[_namedArguments] != null) {
        this[_namedArguments].forEach((key, value) => {
          if (dart.notNull(i) > 0) {
            sb.write(", ");
          }
          sb.write(_symbolToString(key));
          sb.write(": ");
          sb.write(Error.safeToString(value));
          i = dart.notNull(i) + 1;
        });
      }
      if (this[_existingArgumentNames] == null) {
        return `NoSuchMethodError : method not found: '${this[_memberName]}'\n` + `Receiver: ${Error.safeToString(this[_receiver])}\n` + `Arguments: [${sb}]`;
      } else {
        let actualParameters = dart.toString(sb);
        sb = new StringBuffer();
        for (let i = 0; dart.notNull(i) < dart.notNull(this[_existingArgumentNames][$length]); i = dart.notNull(i) + 1) {
          if (dart.notNull(i) > 0) {
            sb.write(", ");
          }
          sb.write(this[_existingArgumentNames][$get](i));
        }
        let formalParameters = dart.toString(sb);
        return "NoSuchMethodError: incorrect number of arguments passed to " + `method named '${this[_memberName]}'\n` + `Receiver: ${Error.safeToString(this[_receiver])}\n` + `Tried calling: ${this[_memberName]}(${actualParameters})\n` + `Found: ${this[_memberName]}(${formalParameters})`;
      }
    }
  }
  class UnsupportedError extends Error {
    UnsupportedError(message) {
      this.message = message;
      super.Error();
    }
    toString() {
      return `Unsupported operation: ${this.message}`;
    }
  }
  class UnimplementedError extends Error {
    UnimplementedError(message) {
      if (message === void 0)
        message = null;
      this.message = message;
      super.Error();
    }
    toString() {
      return this.message != null ? `UnimplementedError: ${this.message}` : "UnimplementedError";
    }
  }
  UnimplementedError[dart.implements] = () => [UnsupportedError];
  class StateError extends Error {
    StateError(message) {
      this.message = message;
      super.Error();
    }
    toString() {
      return `Bad state: ${this.message}`;
    }
  }
  class ConcurrentModificationError extends Error {
    ConcurrentModificationError(modifiedObject) {
      if (modifiedObject === void 0)
        modifiedObject = null;
      this.modifiedObject = modifiedObject;
      super.Error();
    }
    toString() {
      if (this.modifiedObject == null) {
        return "Concurrent modification during iteration.";
      }
      return "Concurrent modification during iteration: " + `${Error.safeToString(this.modifiedObject)}.`;
    }
  }
  class OutOfMemoryError extends Object {
    OutOfMemoryError() {
    }
    toString() {
      return "Out of Memory";
    }
    get stackTrace() {
      return null;
    }
  }
  OutOfMemoryError[dart.implements] = () => [Error];
  class StackOverflowError extends Object {
    StackOverflowError() {
    }
    toString() {
      return "Stack Overflow";
    }
    get stackTrace() {
      return null;
    }
  }
  StackOverflowError[dart.implements] = () => [Error];
  class CyclicInitializationError extends Error {
    CyclicInitializationError(variableName) {
      if (variableName === void 0)
        variableName = null;
      this.variableName = variableName;
      super.Error();
    }
    toString() {
      return this.variableName == null ? "Reading static variable during its initialization" : `Reading static variable '${this.variableName}' during its initialization`;
    }
  }
  class Exception extends Object {
    Exception(message) {
      if (message === void 0)
        message = null;
      return new _ExceptionImplementation(message);
    }
  }
  class _ExceptionImplementation extends Object {
    _ExceptionImplementation(message) {
      if (message === void 0)
        message = null;
      this.message = message;
    }
    toString() {
      if (this.message == null)
        return "Exception";
      return `Exception: ${this.message}`;
    }
  }
  _ExceptionImplementation[dart.implements] = () => [Exception];
  class FormatException extends Object {
    FormatException(message, source, offset) {
      if (message === void 0)
        message = "";
      if (source === void 0)
        source = null;
      if (offset === void 0)
        offset = -1;
      this.message = message;
      this.source = source;
      this.offset = offset;
    }
    toString() {
      let report = "FormatException";
      if (this.message != null && "" != this.message) {
        report = `${report}: ${this.message}`;
      }
      let offset = this.offset;
      if (!(typeof this.source == 'string')) {
        if (offset != -1) {
          report = dart.notNull(report) + ` (at offset ${offset})`;
        }
        return report;
      }
      if (offset != -1 && (dart.notNull(offset) < 0 || int['>'](offset, dart.dload(this.source, 'length')))) {
        offset = -1;
      }
      if (offset == -1) {
        let source = dart.as(this.source, String);
        if (dart.notNull(source.length) > 78) {
          source = dart.notNull(source.substring(0, 75)) + "...";
        }
        return `${report}\n${source}`;
      }
      let lineNum = 1;
      let lineStart = 0;
      let lastWasCR = null;
      for (let i = 0; dart.notNull(i) < dart.notNull(offset); i = dart.notNull(i) + 1) {
        let char = dart.as(dart.dsend(this.source, 'codeUnitAt', i), int);
        if (char == 10) {
          if (lineStart != i || !dart.notNull(lastWasCR)) {
            lineNum = dart.notNull(lineNum) + 1;
          }
          lineStart = dart.notNull(i) + 1;
          lastWasCR = false;
        } else if (char == 13) {
          lineNum = dart.notNull(lineNum) + 1;
          lineStart = dart.notNull(i) + 1;
          lastWasCR = true;
        }
      }
      if (dart.notNull(lineNum) > 1) {
        report = dart.notNull(report) + ` (at line ${lineNum}, character ${dart.notNull(offset) - dart.notNull(lineStart) + 1})\n`;
      } else {
        report = dart.notNull(report) + ` (at character ${dart.notNull(offset) + 1})\n`;
      }
      let lineEnd = dart.as(dart.dload(this.source, 'length'), int);
      for (let i = offset; int['<'](i, dart.dload(this.source, 'length')); i = dart.notNull(i) + 1) {
        let char = dart.as(dart.dsend(this.source, 'codeUnitAt', i), int);
        if (char == 10 || char == 13) {
          lineEnd = i;
          break;
        }
      }
      let length = dart.notNull(lineEnd) - dart.notNull(lineStart);
      let start = lineStart;
      let end = lineEnd;
      let prefix = "";
      let postfix = "";
      if (dart.notNull(length) > 78) {
        let index = dart.notNull(offset) - dart.notNull(lineStart);
        if (dart.notNull(index) < 75) {
          end = dart.notNull(start) + 75;
          postfix = "...";
        } else if (dart.notNull(end) - dart.notNull(offset) < 75) {
          start = dart.notNull(end) - 75;
          prefix = "...";
        } else {
          start = dart.notNull(offset) - 36;
          end = dart.notNull(offset) + 36;
          prefix = postfix = "...";
        }
      }
      let slice = dart.as(dart.dsend(this.source, 'substring', start, end), String);
      let markOffset = dart.notNull(offset) - dart.notNull(start) + dart.notNull(prefix.length);
      return `${report}${prefix}${slice}${postfix}\n${String['*'](" ", markOffset)}^\n`;
    }
  }
  FormatException[dart.implements] = () => [Exception];
  class IntegerDivisionByZeroException extends Object {
    IntegerDivisionByZeroException() {
    }
    toString() {
      return "IntegerDivisionByZeroException";
    }
  }
  IntegerDivisionByZeroException[dart.implements] = () => [Exception];
  let _getKey = dart.JsSymbol('_getKey');
  let Expando$ = dart.generic(function(T) {
    class Expando extends Object {
      Expando(name) {
        if (name === void 0)
          name = null;
        this.name = name;
      }
      toString() {
        return `Expando:${this.name}`;
      }
      get(object) {
        let values = _js_helper.Primitives.getProperty(object, Expando._EXPANDO_PROPERTY_NAME);
        return values == null ? null : dart.as(_js_helper.Primitives.getProperty(values, this[_getKey]()), T);
      }
      set(object, value) {
        dart.as(value, T);
        let values = _js_helper.Primitives.getProperty(object, Expando._EXPANDO_PROPERTY_NAME);
        if (values == null) {
          values = new Object();
          _js_helper.Primitives.setProperty(object, Expando._EXPANDO_PROPERTY_NAME, values);
        }
        _js_helper.Primitives.setProperty(values, this[_getKey](), value);
      }
      [_getKey]() {
        let key = dart.as(_js_helper.Primitives.getProperty(this, Expando._KEY_PROPERTY_NAME), String);
        if (key == null) {
          key = `expando$key$${(() => {
            let x = Expando._keyCount;
            Expando._keyCount = dart.notNull(x) + 1;
            return x;
          })()}`;
          _js_helper.Primitives.setProperty(this, Expando._KEY_PROPERTY_NAME, key);
        }
        return key;
      }
    }
    Expando._KEY_PROPERTY_NAME = 'expando$key';
    Expando._EXPANDO_PROPERTY_NAME = 'expando$values';
    Expando._keyCount = 0;
    return Expando;
  });
  let Expando = Expando$();
  // Function identical: (Object, Object) → bool
  function identical(a, b) {
    return _js_helper.Primitives.identicalImplementation(a, b);
  }
  // Function identityHashCode: (Object) → int
  function identityHashCode(object) {
    return _js_helper.objectHashCode(object);
  }
  class int extends num {
    fromEnvironment(name, opts) {
      let defaultValue = opts && 'defaultValue' in opts ? opts.defaultValue : null;
      throw new UnsupportedError('int.fromEnvironment can only be used as a const constructor');
    }
    static parse(source, opts) {
      let radix = opts && 'radix' in opts ? opts.radix : null;
      let onError = opts && 'onError' in opts ? opts.onError : null;
      return _js_helper.Primitives.parseInt(source, radix, onError);
    }
  }
  dart.defineNamedConstructor(int, 'fromEnvironment');
  class Invocation extends Object {
    get isAccessor() {
      return dart.notNull(this.isGetter) || dart.notNull(this.isSetter);
    }
  }
  let $iterator = dart.JsSymbol('$iterator');
  let $join = dart.JsSymbol('$join');
  let Iterable$ = dart.generic(function(E) {
    class Iterable extends Object {
      Iterable() {
      }
      generate(count, generator) {
        if (generator === void 0)
          generator = null;
        if (dart.notNull(count) <= 0)
          return new (_internal.EmptyIterable$(E))();
        return new (exports._GeneratorIterable$(E))(count, generator);
      }
      [dart.JsSymbol.iterator]() {
        return new dart.JsIterator(this[$iterator]);
      }
      [$join](separator) {
        if (separator === void 0)
          separator = "";
        let buffer = new StringBuffer();
        buffer.writeAll(this, separator);
        return dart.toString(buffer);
      }
    }
    dart.defineNamedConstructor(Iterable, 'generate');
    return Iterable;
  });
  let Iterable = Iterable$();
  let _Generator$ = dart.generic(function(E) {
    let _Generator = dart.typedef('_Generator', () => dart.functionType(E, [int]));
    return _Generator;
  });
  let _Generator = _Generator$();
  let _end = dart.JsSymbol('_end');
  let _start = dart.JsSymbol('_start');
  let _generator = dart.JsSymbol('_generator');
  let $skip = dart.JsSymbol('$skip');
  let $take = dart.JsSymbol('$take');
  let _GeneratorIterable$ = dart.generic(function(E) {
    class _GeneratorIterable extends collection.IterableBase$(E) {
      _GeneratorIterable(end, generator) {
        this[_end] = end;
        this[_start] = 0;
        this[_generator] = dart.as(generator != null ? generator : _GeneratorIterable._id, _Generator$(E));
        super.IterableBase();
      }
      slice(start, end, generator) {
        this[_start] = start;
        this[_end] = end;
        this[_generator] = generator;
        super.IterableBase();
      }
      get [$iterator]() {
        return new (_GeneratorIterator$(E))(this[_start], this[_end], this[_generator]);
      }
      get [$length]() {
        return dart.notNull(this[_end]) - dart.notNull(this[_start]);
      }
      [$skip](count) {
        RangeError.checkNotNegative(count, "count");
        if (count == 0)
          return this;
        let newStart = dart.notNull(this[_start]) + dart.notNull(count);
        if (dart.notNull(newStart) >= dart.notNull(this[_end]))
          return new (_internal.EmptyIterable$(E))();
        return new (exports._GeneratorIterable$(E)).slice(newStart, this[_end], this[_generator]);
      }
      [$take](count) {
        RangeError.checkNotNegative(count, "count");
        if (count == 0)
          return new (_internal.EmptyIterable$(E))();
        let newEnd = dart.notNull(this[_start]) + dart.notNull(count);
        if (dart.notNull(newEnd) >= dart.notNull(this[_end]))
          return this;
        return new (exports._GeneratorIterable$(E)).slice(this[_start], newEnd, this[_generator]);
      }
      static _id(n) {
        return n;
      }
    }
    _GeneratorIterable[dart.implements] = () => [_internal.EfficientLength];
    dart.defineNamedConstructor(_GeneratorIterable, 'slice');
    return _GeneratorIterable;
  });
  dart.defineLazyClassGeneric(exports, '_GeneratorIterable', {get: _GeneratorIterable$});
  let _index = dart.JsSymbol('_index');
  let _current = dart.JsSymbol('_current');
  let _GeneratorIterator$ = dart.generic(function(E) {
    class _GeneratorIterator extends Object {
      _GeneratorIterator(index, end, generator) {
        this[_index] = index;
        this[_end] = end;
        this[_generator] = generator;
        this[_current] = null;
      }
      moveNext() {
        if (dart.notNull(this[_index]) < dart.notNull(this[_end])) {
          this[_current] = this[_generator](this[_index]);
          this[_index] = dart.notNull(this[_index]) + 1;
          return true;
        } else {
          this[_current] = null;
          return false;
        }
      }
      get current() {
        return this[_current];
      }
    }
    _GeneratorIterator[dart.implements] = () => [Iterator$(E)];
    return _GeneratorIterator;
  });
  let _GeneratorIterator = _GeneratorIterator$();
  let BidirectionalIterator$ = dart.generic(function(E) {
    class BidirectionalIterator extends Object {}
    BidirectionalIterator[dart.implements] = () => [Iterator$(E)];
    return BidirectionalIterator;
  });
  let BidirectionalIterator = BidirectionalIterator$();
  let Iterator$ = dart.generic(function(E) {
    class Iterator extends Object {}
    return Iterator;
  });
  let Iterator = Iterator$();
  let $set = dart.JsSymbol('$set');
  let $add = dart.JsSymbol('$add');
  let $checkMutable = dart.JsSymbol('$checkMutable');
  let $checkGrowable = dart.JsSymbol('$checkGrowable');
  let $where = dart.JsSymbol('$where');
  let $expand = dart.JsSymbol('$expand');
  let $forEach = dart.JsSymbol('$forEach');
  let $map = dart.JsSymbol('$map');
  let $takeWhile = dart.JsSymbol('$takeWhile');
  let $skipWhile = dart.JsSymbol('$skipWhile');
  let $reduce = dart.JsSymbol('$reduce');
  let $fold = dart.JsSymbol('$fold');
  let $firstWhere = dart.JsSymbol('$firstWhere');
  let $lastWhere = dart.JsSymbol('$lastWhere');
  let $singleWhere = dart.JsSymbol('$singleWhere');
  let $elementAt = dart.JsSymbol('$elementAt');
  let $first = dart.JsSymbol('$first');
  let $last = dart.JsSymbol('$last');
  let $single = dart.JsSymbol('$single');
  let $any = dart.JsSymbol('$any');
  let $every = dart.JsSymbol('$every');
  let $contains = dart.JsSymbol('$contains');
  let $isEmpty = dart.JsSymbol('$isEmpty');
  let $isNotEmpty = dart.JsSymbol('$isNotEmpty');
  let $toString = dart.JsSymbol('$toString');
  let $toList = dart.JsSymbol('$toList');
  let $toSet = dart.JsSymbol('$toSet');
  let $hashCode = dart.JsSymbol('$hashCode');
  let $addAll = dart.JsSymbol('$addAll');
  let $reversed = dart.JsSymbol('$reversed');
  let $sort = dart.JsSymbol('$sort');
  let $shuffle = dart.JsSymbol('$shuffle');
  let $indexOf = dart.JsSymbol('$indexOf');
  let $lastIndexOf = dart.JsSymbol('$lastIndexOf');
  let $clear = dart.JsSymbol('$clear');
  let $insert = dart.JsSymbol('$insert');
  let $insertAll = dart.JsSymbol('$insertAll');
  let $setAll = dart.JsSymbol('$setAll');
  let $remove = dart.JsSymbol('$remove');
  let $removeAt = dart.JsSymbol('$removeAt');
  let $removeLast = dart.JsSymbol('$removeLast');
  let $removeWhere = dart.JsSymbol('$removeWhere');
  let $retainWhere = dart.JsSymbol('$retainWhere');
  let $sublist = dart.JsSymbol('$sublist');
  let $getRange = dart.JsSymbol('$getRange');
  let $setRange = dart.JsSymbol('$setRange');
  let $removeRange = dart.JsSymbol('$removeRange');
  let $fillRange = dart.JsSymbol('$fillRange');
  let $replaceRange = dart.JsSymbol('$replaceRange');
  let $asMap = dart.JsSymbol('$asMap');
  let List$ = dart.generic(function(E) {
    class List extends Object {
      List(length) {
        if (length === void 0)
          length = null;
        let list = null;
        if (length == null) {
          list = [];
        } else {
          if (!(typeof length == 'number') || dart.notNull(length) < 0) {
            throw new ArgumentError(`Length must be a non-negative integer: ${length}`);
          }
          list = new Array(length);
          list.fixed$length = Array;
        }
        dart.setType(list, List$(E));
        return dart.as(list, List$(E));
      }
      filled(length, fill) {
        let result = new (List$(E))(length);
        if (length != 0 && dart.notNull(fill != null)) {
          for (let i = 0; dart.notNull(i) < dart.notNull(result[$length]); i = dart.notNull(i) + 1) {
            result[$set](i, fill);
          }
        }
        return result;
      }
      from(elements, opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        let list = new (List$(E))();
        for (let e of dart.as(elements, Iterable$(E))) {
          list[$add](e);
        }
        if (growable)
          return list;
        return dart.as(_internal.makeListFixedLength(list), List$(E));
      }
      generate(length, generator, opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        let result = null;
        if (growable) {
          result = dart.setType([], List$(E));
          result[$length] = length;
        } else {
          result = new (List$(E))(length);
        }
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          result[$set](i, generator(i));
        }
        return result;
      }
      [$checkMutable](reason) {}
      [$checkGrowable](reason) {}
      [$where](f) {
        dart.as(f, dart.functionType(bool, [E]));
        return new (_internal.IterableMixinWorkaround$(E))().where(this, f);
      }
      [$expand](f) {
        dart.as(f, dart.functionType(Iterable, [E]));
        return _internal.IterableMixinWorkaround.expand(this, f);
      }
      [$forEach](f) {
        dart.as(f, dart.functionType(dart.void, [E]));
        let length = this[$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          f(dart.as(this[i], E));
          if (length != this[$length]) {
            throw new ConcurrentModificationError(this);
          }
        }
      }
      [$map](f) {
        dart.as(f, dart.functionType(dart.dynamic, [E]));
        return _internal.IterableMixinWorkaround.mapList(this, f);
      }
      [$join](separator) {
        if (separator === void 0)
          separator = "";
        let list = new List(this[$length]);
        for (let i = 0; dart.notNull(i) < dart.notNull(this[$length]); i = dart.notNull(i) + 1) {
          list[$set](i, `${this[$get](i)}`);
        }
        return list.join(separator);
      }
      [$take](n) {
        return new (_internal.IterableMixinWorkaround$(E))().takeList(this, n);
      }
      [$takeWhile](test) {
        dart.as(test, dart.functionType(bool, [E]));
        return new (_internal.IterableMixinWorkaround$(E))().takeWhile(this, test);
      }
      [$skip](n) {
        return new (_internal.IterableMixinWorkaround$(E))().skipList(this, n);
      }
      [$skipWhile](test) {
        dart.as(test, dart.functionType(bool, [E]));
        return new (_internal.IterableMixinWorkaround$(E))().skipWhile(this, test);
      }
      [$reduce](combine) {
        dart.as(combine, dart.functionType(E, [E, E]));
        return dart.as(_internal.IterableMixinWorkaround.reduce(this, combine), E);
      }
      [$fold](initialValue, combine) {
        dart.as(combine, dart.functionType(dart.dynamic, [dart.dynamic, E]));
        return _internal.IterableMixinWorkaround.fold(this, initialValue, combine);
      }
      [$firstWhere](test, opts) {
        dart.as(test, dart.functionType(bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        return dart.as(_internal.IterableMixinWorkaround.firstWhere(this, test, orElse), E);
      }
      [$lastWhere](test, opts) {
        dart.as(test, dart.functionType(bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        return dart.as(_internal.IterableMixinWorkaround.lastWhereList(this, test, orElse), E);
      }
      [$singleWhere](test) {
        dart.as(test, dart.functionType(bool, [E]));
        return dart.as(_internal.IterableMixinWorkaround.singleWhere(this, test), E);
      }
      [$elementAt](index) {
        return this[$get](index);
      }
      get [$first]() {
        if (dart.notNull(this[$length]) > 0)
          return this[$get](0);
        throw new StateError("No elements");
      }
      get [$last]() {
        if (dart.notNull(this[$length]) > 0)
          return this[$get](dart.notNull(this[$length]) - 1);
        throw new StateError("No elements");
      }
      get [$single]() {
        if (this[$length] == 1)
          return this[$get](0);
        if (this[$length] == 0)
          throw new StateError("No elements");
        throw new StateError("More than one element");
      }
      [$any](f) {
        dart.as(f, dart.functionType(bool, [E]));
        return _internal.IterableMixinWorkaround.any(this, f);
      }
      [$every](f) {
        dart.as(f, dart.functionType(bool, [E]));
        return _internal.IterableMixinWorkaround.every(this, f);
      }
      [$contains](other) {
        for (let i = 0; dart.notNull(i) < dart.notNull(this[$length]); i = dart.notNull(i) + 1) {
          if (dart.equals(this[$get](i), other))
            return true;
        }
        return false;
      }
      get [$isEmpty]() {
        return this[$length] == 0;
      }
      get [$isNotEmpty]() {
        return !dart.notNull(this[$isEmpty]);
      }
      [$toString]() {
        return collection.ListBase.listToString(this);
      }
      [$toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        if (growable) {
          return new (_interceptors.JSArray$(E)).markGrowable(this.slice());
        } else {
          return new (_interceptors.JSArray$(E)).markFixed(this.slice());
        }
      }
      [$toSet]() {
        return new (exports.Set$(E)).from(this);
      }
      get [$iterator]() {
        return new (_internal.ListIterator$(E))(this);
      }
      get [$hashCode]() {
        return _js_helper.Primitives.objectHashCode(this);
      }
      [$get](index) {
        if (!(typeof index == 'number'))
          throw new ArgumentError(index);
        if (dart.notNull(index) >= dart.notNull(this[$length]) || dart.notNull(index) < 0)
          throw new RangeError.value(index);
        return dart.as(this[index], E);
      }
      [$set](index, value) {
        dart.as(value, E);
        this[$checkMutable]('indexed set');
        if (!(typeof index == 'number'))
          throw new ArgumentError(index);
        if (dart.notNull(index) >= dart.notNull(this[$length]) || dart.notNull(index) < 0)
          throw new RangeError.value(index);
        this[index] = value;
      }
      get [$length]() {
        return dart.as(this.length, int);
      }
      set [$length](newLength) {
        if (!(typeof newLength == 'number'))
          throw new ArgumentError(newLength);
        if (dart.notNull(newLength) < 0)
          throw new RangeError.value(newLength);
        this[$checkGrowable]('set length');
        this.length = newLength;
      }
      [$add](value) {
        dart.as(value, E);
        this[$checkGrowable]('add');
        this.push(value);
      }
      [$addAll](iterable) {
        dart.as(iterable, Iterable$(E));
        for (let e of iterable) {
          this[$add](e);
        }
      }
      get [$reversed]() {
        return new (_internal.IterableMixinWorkaround$(E))().reversedList(this);
      }
      [$sort](compare) {
        if (compare === void 0)
          compare = null;
        dart.as(compare, dart.functionType(int, [E, E]));
        this[$checkMutable]('sort');
        _internal.IterableMixinWorkaround.sortList(this, compare);
      }
      [$shuffle](random) {
        if (random === void 0)
          random = null;
        _internal.IterableMixinWorkaround.shuffleList(this, random);
      }
      [$indexOf](element, start) {
        dart.as(element, E);
        if (start === void 0)
          start = 0;
        return _internal.IterableMixinWorkaround.indexOfList(this, element, start);
      }
      [$lastIndexOf](element, start) {
        dart.as(element, E);
        if (start === void 0)
          start = null;
        return _internal.IterableMixinWorkaround.lastIndexOfList(this, element, start);
      }
      [$clear]() {
        this[$length] = 0;
      }
      [$insert](index, element) {
        dart.as(element, E);
        if (!(typeof index == 'number'))
          throw new ArgumentError(index);
        if (dart.notNull(index) < 0 || dart.notNull(index) > dart.notNull(this[$length])) {
          throw new RangeError.value(index);
        }
        this[$checkGrowable]('insert');
        this.splice(index, 0, element);
      }
      [$insertAll](index, iterable) {
        dart.as(iterable, Iterable$(E));
        this[$checkGrowable]('insertAll');
        _internal.IterableMixinWorkaround.insertAllList(this, index, iterable);
      }
      [$setAll](index, iterable) {
        dart.as(iterable, Iterable$(E));
        this[$checkMutable]('setAll');
        _internal.IterableMixinWorkaround.setAllList(this, index, iterable);
      }
      [$remove](element) {
        this[$checkGrowable]('remove');
        for (let i = 0; dart.notNull(i) < dart.notNull(this[$length]); i = dart.notNull(i) + 1) {
          if (dart.equals(this[$get](i), /* Unimplemented unknown name */value)) {
            this.splice(i, 1);
            return true;
          }
        }
        return false;
      }
      [$removeAt](index) {
        if (!(typeof index == 'number'))
          throw new ArgumentError(index);
        if (dart.notNull(index) < 0 || dart.notNull(index) >= dart.notNull(this[$length])) {
          throw new RangeError.value(index);
        }
        this[$checkGrowable]('removeAt');
        return dart.as(this.splice(index, 1)[0], E);
      }
      [$removeLast]() {
        this[$checkGrowable]('removeLast');
        if (this[$length] == 0)
          throw new RangeError.value(-1);
        return dart.as(this.pop(), E);
      }
      [$removeWhere](test) {
        dart.as(test, dart.functionType(bool, [E]));
        _internal.IterableMixinWorkaround.removeWhereList(this, test);
      }
      [$retainWhere](test) {
        dart.as(test, dart.functionType(bool, [E]));
        _internal.IterableMixinWorkaround.removeWhereList(this, element => !dart.notNull(test(element)));
      }
      [$sublist](start, end) {
        if (end === void 0)
          end = null;
        dart.dcall(/* Unimplemented unknown name */checkNull, start);
        if (!(typeof start == 'number'))
          throw new ArgumentError(start);
        if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(this[$length])) {
          throw new RangeError.range(start, 0, this[$length]);
        }
        if (end == null) {
          end = this[$length];
        } else {
          if (!(typeof end == 'number'))
            throw new ArgumentError(end);
          if (dart.notNull(end) < dart.notNull(start) || dart.notNull(end) > dart.notNull(this[$length])) {
            throw new RangeError.range(end, start, this[$length]);
          }
        }
        if (start == end)
          return dart.setType([], List$(E));
        return new (_interceptors.JSArray$(E)).markGrowable(this.slice(start, end));
      }
      [$getRange](start, end) {
        return new (_internal.IterableMixinWorkaround$(E))().getRangeList(this, start, end);
      }
      [$setRange](start, end, iterable, skipCount) {
        dart.as(iterable, Iterable$(E));
        if (skipCount === void 0)
          skipCount = 0;
        this[$checkMutable]('set range');
        _internal.IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
      }
      [$removeRange](start, end) {
        this[$checkGrowable]('removeRange');
        let receiverLength = this[$length];
        if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(receiverLength)) {
          throw new RangeError.range(start, 0, receiverLength);
        }
        if (dart.notNull(end) < dart.notNull(start) || dart.notNull(end) > dart.notNull(receiverLength)) {
          throw new RangeError.range(end, start, receiverLength);
        }
        _internal.Lists.copy(this, end, this, start, dart.notNull(receiverLength) - dart.notNull(end));
        this[$length] = dart.notNull(receiverLength) - (dart.notNull(end) - dart.notNull(start));
      }
      [$fillRange](start, end, fillValue) {
        if (fillValue === void 0)
          fillValue = null;
        dart.as(fillValue, E);
        this[$checkMutable]('fill range');
        _internal.IterableMixinWorkaround.fillRangeList(this, start, end, fillValue);
      }
      [$replaceRange](start, end, replacement) {
        dart.as(replacement, Iterable$(E));
        this[$checkGrowable]('removeRange');
        _internal.IterableMixinWorkaround.replaceRangeList(this, start, end, replacement);
      }
      [$asMap]() {
        return new (_internal.IterableMixinWorkaround$(E))().asMapList(this);
      }
    }
    dart.setBaseClass(List, dart.global.Array);
    List[dart.implements] = () => [Iterable$(E), _internal.EfficientLength];
    dart.defineNamedConstructor(List, 'filled');
    dart.defineNamedConstructor(List, 'from');
    dart.defineNamedConstructor(List, 'generate');
    return List;
  });
  let List = List$();
  dart.registerExtension(dart.global.Array, List);
  let Map$ = dart.generic(function(K, V) {
    class Map extends Object {
      Map() {
        return new (collection.LinkedHashMap$(K, V))();
      }
      from(other) {
        return new (collection.LinkedHashMap$(K, V)).from(other);
      }
      identity() {
        return new (collection.LinkedHashMap$(K, V)).identity();
      }
      fromIterable(iterable, opts) {
        return new (collection.LinkedHashMap$(K, V)).fromIterable(iterable, opts);
      }
      fromIterables(keys, values) {
        return new (collection.LinkedHashMap$(K, V)).fromIterables(keys, values);
      }
    }
    dart.defineNamedConstructor(Map, 'from');
    dart.defineNamedConstructor(Map, 'identity');
    dart.defineNamedConstructor(Map, 'fromIterable');
    dart.defineNamedConstructor(Map, 'fromIterables');
    return Map;
  });
  let Map = Map$();
  class Null extends Object {
    _uninstantiable() {
      throw new UnsupportedError('class Null cannot be instantiated');
    }
    toString() {
      return "null";
    }
  }
  dart.defineNamedConstructor(Null, '_uninstantiable');
  class Pattern extends Object {}
  // Function print: (Object) → void
  function print(object) {
    let line = `${object}`;
    if (_internal.printToZone == null) {
      _internal.printToConsole(line);
    } else {
      dart.dcall(_internal.printToZone, line);
    }
  }
  class Match extends Object {}
  class RegExp extends Object {
    RegExp(source, opts) {
      let multiLine = opts && 'multiLine' in opts ? opts.multiLine : false;
      let caseSensitive = opts && 'caseSensitive' in opts ? opts.caseSensitive : true;
      return new _js_helper.JSSyntaxRegExp(source, {multiLine: multiLine, caseSensitive: caseSensitive});
    }
  }
  RegExp[dart.implements] = () => [Pattern];
  let Set$ = dart.generic(function(E) {
    class Set extends collection.IterableBase$(E) {
      Set() {
        return new (collection.LinkedHashSet$(E))();
      }
      identity() {
        return new (collection.LinkedHashSet$(E)).identity();
      }
      from(elements) {
        return new (collection.LinkedHashSet$(E)).from(elements);
      }
    }
    Set[dart.implements] = () => [_internal.EfficientLength];
    dart.defineNamedConstructor(Set, 'identity');
    dart.defineNamedConstructor(Set, 'from');
    return Set;
  });
  dart.defineLazyClassGeneric(exports, 'Set', {get: Set$});
  let Sink$ = dart.generic(function(T) {
    class Sink extends Object {}
    return Sink;
  });
  let Sink = Sink$();
  class StackTrace extends Object {}
  let _stop = dart.JsSymbol('_stop');
  class Stopwatch extends Object {
    get frequency() {
      return Stopwatch._frequency;
    }
    Stopwatch() {
      this[_start] = null;
      this[_stop] = null;
      Stopwatch._initTicker();
    }
    start() {
      if (this.isRunning)
        return;
      if (this[_start] == null) {
        this[_start] = Stopwatch._now();
      } else {
        this[_start] = dart.notNull(Stopwatch._now()) - (dart.notNull(this[_stop]) - dart.notNull(this[_start]));
        this[_stop] = null;
      }
    }
    stop() {
      if (!dart.notNull(this.isRunning))
        return;
      this[_stop] = Stopwatch._now();
    }
    reset() {
      if (this[_start] == null)
        return;
      this[_start] = Stopwatch._now();
      if (this[_stop] != null) {
        this[_stop] = this[_start];
      }
    }
    get elapsedTicks() {
      if (this[_start] == null) {
        return 0;
      }
      return this[_stop] == null ? dart.notNull(Stopwatch._now()) - dart.notNull(this[_start]) : dart.notNull(this[_stop]) - dart.notNull(this[_start]);
    }
    get elapsed() {
      return new Duration({microseconds: this.elapsedMicroseconds});
    }
    get elapsedMicroseconds() {
      return (dart.notNull(this.elapsedTicks) * 1000000 / dart.notNull(this.frequency)).truncate();
    }
    get elapsedMilliseconds() {
      return (dart.notNull(this.elapsedTicks) * 1000 / dart.notNull(this.frequency)).truncate();
    }
    get isRunning() {
      return this[_start] != null && this[_stop] == null;
    }
    static _initTicker() {
      _js_helper.Primitives.initTicker();
      Stopwatch._frequency = _js_helper.Primitives.timerFrequency;
    }
    static _now() {
      return dart.as(dart.dcall(_js_helper.Primitives.timerTicks), int);
    }
  }
  Stopwatch._frequency = null;
  class String extends Object {
    fromCharCodes(charCodes, start, end) {
      if (start === void 0)
        start = 0;
      if (end === void 0)
        end = null;
      if (!dart.is(charCodes, _interceptors.JSArray)) {
        return String._stringFromIterable(charCodes, start, end);
      }
      let list = dart.as(charCodes, List);
      let len = list[$length];
      if (dart.notNull(start) < 0 || dart.notNull(start) > dart.notNull(len)) {
        throw new RangeError.range(start, 0, len);
      }
      if (end == null) {
        end = len;
      } else if (dart.notNull(end) < dart.notNull(start) || dart.notNull(end) > dart.notNull(len)) {
        throw new RangeError.range(end, start, len);
      }
      if (dart.notNull(start) > 0 || dart.notNull(end) < dart.notNull(len)) {
        list = list[$sublist](start, end);
      }
      return _js_helper.Primitives.stringFromCharCodes(list);
    }
    fromCharCode(charCode) {
      return _js_helper.Primitives.stringFromCharCode(charCode);
    }
    fromEnvironment(name, opts) {
      let defaultValue = opts && 'defaultValue' in opts ? opts.defaultValue : null;
      throw new UnsupportedError('String.fromEnvironment can only be used as a const constructor');
    }
    static _stringFromIterable(charCodes, start, end) {
      if (dart.notNull(start) < 0)
        throw new RangeError.range(start, 0, charCodes[$length]);
      if (end != null && dart.notNull(end) < dart.notNull(start)) {
        throw new RangeError.range(end, start, charCodes[$length]);
      }
      let it = charCodes[$iterator];
      for (let i = 0; dart.notNull(i) < dart.notNull(start); i = dart.notNull(i) + 1) {
        if (!dart.notNull(it.moveNext())) {
          throw new RangeError.range(start, 0, i);
        }
      }
      let list = [];
      if (end == null) {
        while (it.moveNext())
          list[$add](it.current);
      } else {
        for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
          if (!dart.notNull(it.moveNext())) {
            throw new RangeError.range(end, start, i);
          }
          list[$add](it.current);
        }
      }
      return _js_helper.Primitives.stringFromCharCodes(list);
    }
  }
  String[dart.implements] = () => [Comparable$(String), Pattern];
  dart.defineNamedConstructor(String, 'fromCharCodes');
  dart.defineNamedConstructor(String, 'fromCharCode');
  dart.defineNamedConstructor(String, 'fromEnvironment');
  dart.defineLazyClass(exports, {
    get Runes() {
      class Runes extends collection.IterableBase$(int) {
        Runes(string) {
          this.string = string;
          super.IterableBase();
        }
        get [$iterator]() {
          return new RuneIterator(this.string);
        }
        get [$last]() {
          if (this.string.length == 0) {
            throw new StateError('No elements.');
          }
          let length = this.string.length;
          let code = this.string.codeUnitAt(dart.notNull(length) - 1);
          if (dart.notNull(_isTrailSurrogate(code)) && dart.notNull(this.string.length) > 1) {
            let previousCode = this.string.codeUnitAt(dart.notNull(length) - 2);
            if (_isLeadSurrogate(previousCode)) {
              return _combineSurrogatePair(previousCode, code);
            }
          }
          return code;
        }
      }
      return Runes;
    }
  });
  // Function _isLeadSurrogate: (int) → bool
  function _isLeadSurrogate(code) {
    return (dart.notNull(code) & 64512) == 55296;
  }
  // Function _isTrailSurrogate: (int) → bool
  function _isTrailSurrogate(code) {
    return (dart.notNull(code) & 64512) == 56320;
  }
  // Function _combineSurrogatePair: (int, int) → int
  function _combineSurrogatePair(start, end) {
    return 65536 + ((dart.notNull(start) & 1023) << 10) + (dart.notNull(end) & 1023);
  }
  let _position = dart.JsSymbol('_position');
  let _nextPosition = dart.JsSymbol('_nextPosition');
  let _currentCodePoint = dart.JsSymbol('_currentCodePoint');
  let _checkSplitSurrogate = dart.JsSymbol('_checkSplitSurrogate');
  class RuneIterator extends Object {
    RuneIterator(string) {
      this.string = string;
      this[_position] = 0;
      this[_nextPosition] = 0;
      this[_currentCodePoint] = null;
    }
    at(string, index) {
      this.string = string;
      this[_position] = index;
      this[_nextPosition] = index;
      this[_currentCodePoint] = null;
      RangeError.checkValueInInterval(index, 0, string.length);
      this[_checkSplitSurrogate](index);
    }
    [_checkSplitSurrogate](index) {
      if (dart.notNull(index) > 0 && dart.notNull(index) < dart.notNull(this.string.length) && dart.notNull(_isLeadSurrogate(this.string.codeUnitAt(dart.notNull(index) - 1))) && dart.notNull(_isTrailSurrogate(this.string.codeUnitAt(index)))) {
        throw new ArgumentError(`Index inside surrogate pair: ${index}`);
      }
    }
    get rawIndex() {
      return this[_position] != this[_nextPosition] ? this[_position] : null;
    }
    set rawIndex(rawIndex) {
      RangeError.checkValidIndex(rawIndex, this.string, "rawIndex");
      this.reset(rawIndex);
      this.moveNext();
    }
    reset(rawIndex) {
      if (rawIndex === void 0)
        rawIndex = 0;
      RangeError.checkValueInInterval(rawIndex, 0, this.string.length, "rawIndex");
      this[_checkSplitSurrogate](rawIndex);
      this[_position] = this[_nextPosition] = rawIndex;
      this[_currentCodePoint] = null;
    }
    get current() {
      return this[_currentCodePoint];
    }
    get currentSize() {
      return dart.notNull(this[_nextPosition]) - dart.notNull(this[_position]);
    }
    get currentAsString() {
      if (this[_position] == this[_nextPosition])
        return null;
      if (dart.notNull(this[_position]) + 1 == this[_nextPosition])
        return String.get(this.string, this[_position]);
      return this.string.substring(this[_position], this[_nextPosition]);
    }
    moveNext() {
      this[_position] = this[_nextPosition];
      if (this[_position] == this.string.length) {
        this[_currentCodePoint] = null;
        return false;
      }
      let codeUnit = this.string.codeUnitAt(this[_position]);
      let nextPosition = dart.notNull(this[_position]) + 1;
      if (dart.notNull(_isLeadSurrogate(codeUnit)) && dart.notNull(nextPosition) < dart.notNull(this.string.length)) {
        let nextCodeUnit = this.string.codeUnitAt(nextPosition);
        if (_isTrailSurrogate(nextCodeUnit)) {
          this[_nextPosition] = dart.notNull(nextPosition) + 1;
          this[_currentCodePoint] = _combineSurrogatePair(codeUnit, nextCodeUnit);
          return true;
        }
      }
      this[_nextPosition] = nextPosition;
      this[_currentCodePoint] = codeUnit;
      return true;
    }
    movePrevious() {
      this[_nextPosition] = this[_position];
      if (this[_position] == 0) {
        this[_currentCodePoint] = null;
        return false;
      }
      let position = dart.notNull(this[_position]) - 1;
      let codeUnit = this.string.codeUnitAt(position);
      if (dart.notNull(_isTrailSurrogate(codeUnit)) && dart.notNull(position) > 0) {
        let prevCodeUnit = this.string.codeUnitAt(dart.notNull(position) - 1);
        if (_isLeadSurrogate(prevCodeUnit)) {
          this[_position] = dart.notNull(position) - 1;
          this[_currentCodePoint] = _combineSurrogatePair(prevCodeUnit, codeUnit);
          return true;
        }
      }
      this[_position] = position;
      this[_currentCodePoint] = codeUnit;
      return true;
    }
  }
  RuneIterator[dart.implements] = () => [BidirectionalIterator$(int)];
  dart.defineNamedConstructor(RuneIterator, 'at');
  let _contents = dart.JsSymbol('_contents');
  let _writeString = dart.JsSymbol('_writeString');
  class StringBuffer extends Object {
    StringBuffer(content) {
      if (content === void 0)
        content = "";
      this[_contents] = `${content}`;
    }
    get length() {
      return this[_contents].length;
    }
    get isEmpty() {
      return this.length == 0;
    }
    get isNotEmpty() {
      return !dart.notNull(this.isEmpty);
    }
    write(obj) {
      this[_writeString](`${obj}`);
    }
    writeCharCode(charCode) {
      this[_writeString](new String.fromCharCode(charCode));
    }
    writeAll(objects, separator) {
      if (separator === void 0)
        separator = "";
      let iterator = objects[$iterator];
      if (!dart.notNull(iterator.moveNext()))
        return;
      if (separator.isEmpty) {
        do {
          this.write(iterator.current);
        } while (iterator.moveNext());
      } else {
        this.write(iterator.current);
        while (iterator.moveNext()) {
          this.write(separator);
          this.write(iterator.current);
        }
      }
    }
    writeln(obj) {
      if (obj === void 0)
        obj = "";
      this.write(obj);
      this.write("\n");
    }
    clear() {
      this[_contents] = "";
    }
    toString() {
      return _js_helper.Primitives.flattenString(this[_contents]);
    }
    [_writeString](str) {
      this[_contents] = _js_helper.Primitives.stringConcatUnchecked(this[_contents], dart.as(str, String));
    }
  }
  StringBuffer[dart.implements] = () => [StringSink];
  class StringSink extends Object {}
  class Symbol extends Object {
    Symbol(name) {
      return new _internal.Symbol(name);
    }
  }
  class Type extends Object {}
  let _writeAuthority = dart.JsSymbol('_writeAuthority');
  let _userInfo = dart.JsSymbol('_userInfo');
  let _host = dart.JsSymbol('_host');
  let _port = dart.JsSymbol('_port');
  let _path = dart.JsSymbol('_path');
  let _query = dart.JsSymbol('_query');
  let _fragment = dart.JsSymbol('_fragment');
  let _pathSegments = dart.JsSymbol('_pathSegments');
  let _queryParameters = dart.JsSymbol('_queryParameters');
  let _merge = dart.JsSymbol('_merge');
  let _hasDotSegments = dart.JsSymbol('_hasDotSegments');
  let _removeDotSegments = dart.JsSymbol('_removeDotSegments');
  let _toWindowsFilePath = dart.JsSymbol('_toWindowsFilePath');
  let _toFilePath = dart.JsSymbol('_toFilePath');
  let _isPathAbsolute = dart.JsSymbol('_isPathAbsolute');
  class Uri extends Object {
    get authority() {
      if (!dart.notNull(this.hasAuthority))
        return "";
      let sb = new StringBuffer();
      this[_writeAuthority](sb);
      return dart.toString(sb);
    }
    get userInfo() {
      return this[_userInfo];
    }
    get host() {
      if (this[_host] == null)
        return "";
      if (this[_host].startsWith('[')) {
        return this[_host].substring(1, dart.notNull(this[_host].length) - 1);
      }
      return this[_host];
    }
    get port() {
      if (this[_port] == null)
        return Uri._defaultPort(this.scheme);
      return this[_port];
    }
    static _defaultPort(scheme) {
      if (scheme == "http")
        return 80;
      if (scheme == "https")
        return 443;
      return 0;
    }
    get path() {
      return this[_path];
    }
    get query() {
      return this[_query] == null ? "" : this[_query];
    }
    get fragment() {
      return this[_fragment] == null ? "" : this[_fragment];
    }
    static parse(uri) {
      // Function isRegName: (int) → bool
      function isRegName(ch) {
        return dart.notNull(ch) < 128 && dart.notNull(!dart.equals(dart.dsend(Uri._regNameTable[$get](dart.notNull(ch) >> 4), '&', 1 << (dart.notNull(ch) & 15)), 0));
      }
      let EOI = -1;
      let scheme = "";
      let userinfo = "";
      let host = null;
      let port = null;
      let path = null;
      let query = null;
      let fragment = null;
      let index = 0;
      let pathStart = 0;
      let char = EOI;
      // Function parseAuth: () → void
      function parseAuth() {
        if (index == uri.length) {
          char = EOI;
          return;
        }
        let authStart = index;
        let lastColon = -1;
        let lastAt = -1;
        char = uri.codeUnitAt(index);
        while (dart.notNull(index) < dart.notNull(uri.length)) {
          char = uri.codeUnitAt(index);
          if (char == Uri._SLASH || char == Uri._QUESTION || char == Uri._NUMBER_SIGN) {
            break;
          }
          if (char == Uri._AT_SIGN) {
            lastAt = index;
            lastColon = -1;
          } else if (char == Uri._COLON) {
            lastColon = index;
          } else if (char == Uri._LEFT_BRACKET) {
            lastColon = -1;
            let endBracket = uri.indexOf(']', dart.notNull(index) + 1);
            if (endBracket == -1) {
              index = uri.length;
              char = EOI;
              break;
            } else {
              index = endBracket;
            }
          }
          index = dart.notNull(index) + 1;
          char = EOI;
        }
        let hostStart = authStart;
        let hostEnd = index;
        if (dart.notNull(lastAt) >= 0) {
          userinfo = Uri._makeUserInfo(uri, authStart, lastAt);
          hostStart = dart.notNull(lastAt) + 1;
        }
        if (dart.notNull(lastColon) >= 0) {
          let portNumber = null;
          if (dart.notNull(lastColon) + 1 < dart.notNull(index)) {
            portNumber = 0;
            for (let i = dart.notNull(lastColon) + 1; dart.notNull(i) < dart.notNull(index); i = dart.notNull(i) + 1) {
              let digit = uri.codeUnitAt(i);
              if (dart.notNull(Uri._ZERO) > dart.notNull(digit) || dart.notNull(Uri._NINE) < dart.notNull(digit)) {
                Uri._fail(uri, i, "Invalid port number");
              }
              portNumber = dart.notNull(portNumber) * 10 + (dart.notNull(digit) - dart.notNull(Uri._ZERO));
            }
          }
          port = Uri._makePort(portNumber, scheme);
          hostEnd = lastColon;
        }
        host = Uri._makeHost(uri, hostStart, hostEnd, true);
        if (dart.notNull(index) < dart.notNull(uri.length)) {
          char = uri.codeUnitAt(index);
        }
      }
      let NOT_IN_PATH = 0;
      let IN_PATH = 1;
      let ALLOW_AUTH = 2;
      let state = NOT_IN_PATH;
      let i = index;
      while (dart.notNull(i) < dart.notNull(uri.length)) {
        char = uri.codeUnitAt(i);
        if (char == Uri._QUESTION || char == Uri._NUMBER_SIGN) {
          state = NOT_IN_PATH;
          break;
        }
        if (char == Uri._SLASH) {
          state = i == 0 ? ALLOW_AUTH : IN_PATH;
          break;
        }
        if (char == Uri._COLON) {
          if (i == 0)
            Uri._fail(uri, 0, "Invalid empty scheme");
          scheme = Uri._makeScheme(uri, i);
          i = dart.notNull(i) + 1;
          pathStart = i;
          if (i == uri.length) {
            char = EOI;
            state = NOT_IN_PATH;
          } else {
            char = uri.codeUnitAt(i);
            if (char == Uri._QUESTION || char == Uri._NUMBER_SIGN) {
              state = NOT_IN_PATH;
            } else if (char == Uri._SLASH) {
              state = ALLOW_AUTH;
            } else {
              state = IN_PATH;
            }
          }
          break;
        }
        i = dart.notNull(i) + 1;
        char = EOI;
      }
      index = i;
      if (state == ALLOW_AUTH) {
        dart.assert(char == Uri._SLASH);
        index = dart.notNull(index) + 1;
        if (index == uri.length) {
          char = EOI;
          state = NOT_IN_PATH;
        } else {
          char = uri.codeUnitAt(index);
          if (char == Uri._SLASH) {
            index = dart.notNull(index) + 1;
            parseAuth();
            pathStart = index;
          }
          if (char == Uri._QUESTION || char == Uri._NUMBER_SIGN || char == EOI) {
            state = NOT_IN_PATH;
          } else {
            state = IN_PATH;
          }
        }
      }
      dart.assert(state == IN_PATH || state == NOT_IN_PATH);
      if (state == IN_PATH) {
        while ((index = dart.notNull(index) + 1) < dart.notNull(uri.length)) {
          char = uri.codeUnitAt(index);
          if (char == Uri._QUESTION || char == Uri._NUMBER_SIGN) {
            break;
          }
          char = EOI;
        }
        state = NOT_IN_PATH;
      }
      dart.assert(state == NOT_IN_PATH);
      let isFile = scheme == "file";
      let ensureLeadingSlash = host != null;
      path = Uri._makePath(uri, pathStart, index, null, ensureLeadingSlash, isFile);
      if (char == Uri._QUESTION) {
        let numberSignIndex = uri.indexOf('#', dart.notNull(index) + 1);
        if (dart.notNull(numberSignIndex) < 0) {
          query = Uri._makeQuery(uri, dart.notNull(index) + 1, uri.length, null);
        } else {
          query = Uri._makeQuery(uri, dart.notNull(index) + 1, numberSignIndex, null);
          fragment = Uri._makeFragment(uri, dart.notNull(numberSignIndex) + 1, uri.length);
        }
      } else if (char == Uri._NUMBER_SIGN) {
        fragment = Uri._makeFragment(uri, dart.notNull(index) + 1, uri.length);
      }
      return new Uri._internal(scheme, userinfo, host, port, path, query, fragment);
    }
    static _fail(uri, index, message) {
      throw new FormatException(message, uri, index);
    }
    _internal(scheme, userInfo, host, port, path, query, fragment) {
      this.scheme = scheme;
      this[_userInfo] = userInfo;
      this[_host] = host;
      this[_port] = port;
      this[_path] = path;
      this[_query] = query;
      this[_fragment] = fragment;
      this[_pathSegments] = null;
      this[_queryParameters] = null;
    }
    Uri(opts) {
      let scheme = opts && 'scheme' in opts ? opts.scheme : "";
      let userInfo = opts && 'userInfo' in opts ? opts.userInfo : "";
      let host = opts && 'host' in opts ? opts.host : null;
      let port = opts && 'port' in opts ? opts.port : null;
      let path = opts && 'path' in opts ? opts.path : null;
      let pathSegments = opts && 'pathSegments' in opts ? opts.pathSegments : null;
      let query = opts && 'query' in opts ? opts.query : null;
      let queryParameters = opts && 'queryParameters' in opts ? opts.queryParameters : null;
      let fragment = opts && 'fragment' in opts ? opts.fragment : null;
      scheme = Uri._makeScheme(scheme, Uri._stringOrNullLength(scheme));
      userInfo = Uri._makeUserInfo(userInfo, 0, Uri._stringOrNullLength(userInfo));
      host = Uri._makeHost(host, 0, Uri._stringOrNullLength(host), false);
      if (query == "")
        query = null;
      query = Uri._makeQuery(query, 0, Uri._stringOrNullLength(query), queryParameters);
      fragment = Uri._makeFragment(fragment, 0, Uri._stringOrNullLength(fragment));
      port = Uri._makePort(port, scheme);
      let isFile = scheme == "file";
      if (host == null && (dart.notNull(userInfo.isNotEmpty) || port != null || dart.notNull(isFile))) {
        host = "";
      }
      let ensureLeadingSlash = host != null;
      path = Uri._makePath(path, 0, Uri._stringOrNullLength(path), pathSegments, ensureLeadingSlash, isFile);
      return new Uri._internal(scheme, userInfo, host, port, path, query, fragment);
    }
    http(authority, unencodedPath, queryParameters) {
      if (queryParameters === void 0)
        queryParameters = null;
      return Uri._makeHttpUri("http", authority, unencodedPath, queryParameters);
    }
    https(authority, unencodedPath, queryParameters) {
      if (queryParameters === void 0)
        queryParameters = null;
      return Uri._makeHttpUri("https", authority, unencodedPath, queryParameters);
    }
    static _makeHttpUri(scheme, authority, unencodedPath, queryParameters) {
      let userInfo = "";
      let host = null;
      let port = null;
      if (authority != null && dart.notNull(authority.isNotEmpty)) {
        let hostStart = 0;
        let hasUserInfo = false;
        for (let i = 0; dart.notNull(i) < dart.notNull(authority.length); i = dart.notNull(i) + 1) {
          if (authority.codeUnitAt(i) == Uri._AT_SIGN) {
            hasUserInfo = true;
            userInfo = authority.substring(0, i);
            hostStart = dart.notNull(i) + 1;
            break;
          }
        }
        let hostEnd = hostStart;
        if (dart.notNull(hostStart) < dart.notNull(authority.length) && authority.codeUnitAt(hostStart) == Uri._LEFT_BRACKET) {
          for (; dart.notNull(hostEnd) < dart.notNull(authority.length); hostEnd = dart.notNull(hostEnd) + 1) {
            if (authority.codeUnitAt(hostEnd) == Uri._RIGHT_BRACKET)
              break;
          }
          if (hostEnd == authority.length) {
            throw new FormatException("Invalid IPv6 host entry.", authority, hostStart);
          }
          Uri.parseIPv6Address(authority, dart.notNull(hostStart) + 1, hostEnd);
          hostEnd = dart.notNull(hostEnd) + 1;
          if (hostEnd != authority.length && authority.codeUnitAt(hostEnd) != Uri._COLON) {
            throw new FormatException("Invalid end of authority", authority, hostEnd);
          }
        }
        let hasPort = false;
        for (; dart.notNull(hostEnd) < dart.notNull(authority.length); hostEnd = dart.notNull(hostEnd) + 1) {
          if (authority.codeUnitAt(hostEnd) == Uri._COLON) {
            let portString = authority.substring(dart.notNull(hostEnd) + 1);
            if (portString.isNotEmpty)
              port = int.parse(portString);
            break;
          }
        }
        host = authority.substring(hostStart, hostEnd);
      }
      return new Uri({scheme: scheme, userInfo: userInfo, host: dart.as(host, String), port: dart.as(port, int), pathSegments: unencodedPath.split("/"), queryParameters: queryParameters});
    }
    file(path, opts) {
      let windows = opts && 'windows' in opts ? opts.windows : null;
      windows = windows == null ? Uri._isWindows : windows;
      return windows ? dart.as(Uri._makeWindowsFileUrl(path), Uri) : dart.as(Uri._makeFileUri(path), Uri);
    }
    static get base() {
      let uri = _js_helper.Primitives.currentUri();
      if (uri != null)
        return Uri.parse(uri);
      throw new UnsupportedError("'Uri.base' is not supported");
    }
    static get _isWindows() {
      return false;
    }
    static _checkNonWindowsPathReservedCharacters(segments, argumentError) {
      segments[$forEach](segment => {
        if (dart.dsend(segment, 'contains', "/")) {
          if (argumentError) {
            throw new ArgumentError(`Illegal path character ${segment}`);
          } else {
            throw new UnsupportedError(`Illegal path character ${segment}`);
          }
        }
      });
    }
    static _checkWindowsPathReservedCharacters(segments, argumentError, firstSegment) {
      if (firstSegment === void 0)
        firstSegment = 0;
      segments[$skip](firstSegment)[$forEach](segment => {
        if (dart.dsend(segment, 'contains', new RegExp('["*/:<>?\\\\|]'))) {
          if (argumentError) {
            throw new ArgumentError("Illegal character in path");
          } else {
            throw new UnsupportedError("Illegal character in path");
          }
        }
      });
    }
    static _checkWindowsDriveLetter(charCode, argumentError) {
      if (dart.notNull(Uri._UPPER_CASE_A) <= dart.notNull(charCode) && dart.notNull(charCode) <= dart.notNull(Uri._UPPER_CASE_Z) || dart.notNull(Uri._LOWER_CASE_A) <= dart.notNull(charCode) && dart.notNull(charCode) <= dart.notNull(Uri._LOWER_CASE_Z)) {
        return;
      }
      if (argumentError) {
        throw new ArgumentError("Illegal drive letter " + dart.notNull(new String.fromCharCode(charCode)));
      } else {
        throw new UnsupportedError("Illegal drive letter " + dart.notNull(new String.fromCharCode(charCode)));
      }
    }
    static _makeFileUri(path) {
      let sep = "/";
      if (path.startsWith(sep)) {
        return new Uri({scheme: "file", pathSegments: path.split(sep)});
      } else {
        return new Uri({pathSegments: path.split(sep)});
      }
    }
    static _makeWindowsFileUrl(path) {
      if (path.startsWith("\\\\?\\")) {
        if (path.startsWith("\\\\?\\UNC\\")) {
          path = `\\${path.substring(7)}`;
        } else {
          path = path.substring(4);
          if (dart.notNull(path.length) < 3 || path.codeUnitAt(1) != Uri._COLON || path.codeUnitAt(2) != Uri._BACKSLASH) {
            throw new ArgumentError("Windows paths with \\\\?\\ prefix must be absolute");
          }
        }
      } else {
        path = path.replaceAll("/", "\\");
      }
      let sep = "\\";
      if (dart.notNull(path.length) > 1 && String.get(path, 1) == ":") {
        Uri._checkWindowsDriveLetter(path.codeUnitAt(0), true);
        if (path.length == 2 || path.codeUnitAt(2) != Uri._BACKSLASH) {
          throw new ArgumentError("Windows paths with drive letter must be absolute");
        }
        let pathSegments = path.split(sep);
        Uri._checkWindowsPathReservedCharacters(pathSegments, true, 1);
        return new Uri({scheme: "file", pathSegments: pathSegments});
      }
      if (dart.notNull(path.length) > 0 && String.get(path, 0) == sep) {
        if (dart.notNull(path.length) > 1 && String.get(path, 1) == sep) {
          let pathStart = path.indexOf("\\", 2);
          let hostPart = pathStart == -1 ? path.substring(2) : path.substring(2, pathStart);
          let pathPart = pathStart == -1 ? "" : path.substring(dart.notNull(pathStart) + 1);
          let pathSegments = pathPart.split(sep);
          Uri._checkWindowsPathReservedCharacters(pathSegments, true);
          return new Uri({scheme: "file", host: hostPart, pathSegments: pathSegments});
        } else {
          let pathSegments = path.split(sep);
          Uri._checkWindowsPathReservedCharacters(pathSegments, true);
          return new Uri({scheme: "file", pathSegments: pathSegments});
        }
      } else {
        let pathSegments = path.split(sep);
        Uri._checkWindowsPathReservedCharacters(pathSegments, true);
        return new Uri({pathSegments: pathSegments});
      }
    }
    replace(opts) {
      let scheme = opts && 'scheme' in opts ? opts.scheme : null;
      let userInfo = opts && 'userInfo' in opts ? opts.userInfo : null;
      let host = opts && 'host' in opts ? opts.host : null;
      let port = opts && 'port' in opts ? opts.port : null;
      let path = opts && 'path' in opts ? opts.path : null;
      let pathSegments = opts && 'pathSegments' in opts ? opts.pathSegments : null;
      let query = opts && 'query' in opts ? opts.query : null;
      let queryParameters = opts && 'queryParameters' in opts ? opts.queryParameters : null;
      let fragment = opts && 'fragment' in opts ? opts.fragment : null;
      let schemeChanged = false;
      if (scheme != null) {
        scheme = Uri._makeScheme(scheme, scheme.length);
        schemeChanged = true;
      } else {
        scheme = this.scheme;
      }
      let isFile = scheme == "file";
      if (userInfo != null) {
        userInfo = Uri._makeUserInfo(userInfo, 0, userInfo.length);
      } else {
        userInfo = this.userInfo;
      }
      if (port != null) {
        port = Uri._makePort(port, scheme);
      } else {
        port = this[_port];
        if (schemeChanged) {
          port = Uri._makePort(port, scheme);
        }
      }
      if (host != null) {
        host = Uri._makeHost(host, 0, host.length, false);
      } else if (this.hasAuthority) {
        host = this.host;
      } else if (dart.notNull(userInfo.isNotEmpty) || port != null || dart.notNull(isFile)) {
        host = "";
      }
      let ensureLeadingSlash = host != null;
      if (path != null || dart.notNull(pathSegments != null)) {
        path = Uri._makePath(path, 0, Uri._stringOrNullLength(path), pathSegments, ensureLeadingSlash, isFile);
      } else {
        path = this.path;
        if ((dart.notNull(isFile) || dart.notNull(ensureLeadingSlash) && !dart.notNull(path.isEmpty)) && !dart.notNull(path.startsWith('/'))) {
          path = `/${path}`;
        }
      }
      if (query != null || dart.notNull(queryParameters != null)) {
        query = Uri._makeQuery(query, 0, Uri._stringOrNullLength(query), queryParameters);
      } else if (this.hasQuery) {
        query = this.query;
      }
      if (fragment != null) {
        fragment = Uri._makeFragment(fragment, 0, fragment.length);
      } else if (this.hasFragment) {
        fragment = this.fragment;
      }
      return new Uri._internal(scheme, userInfo, host, port, path, query, fragment);
    }
    get pathSegments() {
      if (this[_pathSegments] == null) {
        let pathToSplit = !dart.notNull(this.path.isEmpty) && this.path.codeUnitAt(0) == Uri._SLASH ? this.path.substring(1) : this.path;
        this[_pathSegments] = new (collection.UnmodifiableListView$(String))(pathToSplit == "" ? dart.const(dart.setType([], List$(String))) : new (List$(String)).from(pathToSplit.split("/")[$map](dart.bind(Uri, 'decodeComponent')), {growable: false}));
      }
      return this[_pathSegments];
    }
    get queryParameters() {
      if (this[_queryParameters] == null) {
        this[_queryParameters] = new (collection.UnmodifiableMapView$(String, String))(Uri.splitQueryString(this.query));
      }
      return this[_queryParameters];
    }
    static _makePort(port, scheme) {
      if (port != null && port == Uri._defaultPort(scheme))
        return null;
      return port;
    }
    static _makeHost(host, start, end, strictIPv6) {
      if (host == null)
        return null;
      if (start == end)
        return "";
      if (host.codeUnitAt(start) == Uri._LEFT_BRACKET) {
        if (host.codeUnitAt(dart.notNull(end) - 1) != Uri._RIGHT_BRACKET) {
          Uri._fail(host, start, 'Missing end `]` to match `[` in host');
        }
        Uri.parseIPv6Address(host, dart.notNull(start) + 1, dart.notNull(end) - 1);
        return host.substring(start, end).toLowerCase();
      }
      if (!dart.notNull(strictIPv6)) {
        for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
          if (host.codeUnitAt(i) == Uri._COLON) {
            Uri.parseIPv6Address(host, start, end);
            return `[${host}]`;
          }
        }
      }
      return Uri._normalizeRegName(host, start, end);
    }
    static _isRegNameChar(char) {
      return dart.notNull(char) < 127 && dart.notNull(!dart.equals(dart.dsend(Uri._regNameTable[$get](dart.notNull(char) >> 4), '&', 1 << (dart.notNull(char) & 15)), 0));
    }
    static _normalizeRegName(host, start, end) {
      let buffer = null;
      let sectionStart = start;
      let index = start;
      let isNormalized = true;
      while (dart.notNull(index) < dart.notNull(end)) {
        let char = host.codeUnitAt(index);
        if (char == Uri._PERCENT) {
          let replacement = Uri._normalizeEscape(host, index, true);
          if (replacement == null && dart.notNull(isNormalized)) {
            index = dart.notNull(index) + 3;
            continue;
          }
          if (buffer == null)
            buffer = new StringBuffer();
          let slice = host.substring(sectionStart, index);
          if (!dart.notNull(isNormalized))
            slice = slice.toLowerCase();
          buffer.write(slice);
          let sourceLength = 3;
          if (replacement == null) {
            replacement = host.substring(index, dart.notNull(index) + 3);
          } else if (replacement == "%") {
            replacement = "%25";
            sourceLength = 1;
          }
          buffer.write(replacement);
          index = dart.notNull(index) + dart.notNull(sourceLength);
          sectionStart = index;
          isNormalized = true;
        } else if (Uri._isRegNameChar(char)) {
          if (dart.notNull(isNormalized) && dart.notNull(Uri._UPPER_CASE_A) <= dart.notNull(char) && dart.notNull(Uri._UPPER_CASE_Z) >= dart.notNull(char)) {
            if (buffer == null)
              buffer = new StringBuffer();
            if (dart.notNull(sectionStart) < dart.notNull(index)) {
              buffer.write(host.substring(sectionStart, index));
              sectionStart = index;
            }
            isNormalized = false;
          }
          index = dart.notNull(index) + 1;
        } else if (Uri._isGeneralDelimiter(char)) {
          Uri._fail(host, index, "Invalid character");
        } else {
          let sourceLength = 1;
          if ((dart.notNull(char) & 64512) == 55296 && dart.notNull(index) + 1 < dart.notNull(end)) {
            let tail = host.codeUnitAt(dart.notNull(index) + 1);
            if ((dart.notNull(tail) & 64512) == 56320) {
              char = 65536 | (dart.notNull(char) & 1023) << 10 | dart.notNull(tail) & 1023;
              sourceLength = 2;
            }
          }
          if (buffer == null)
            buffer = new StringBuffer();
          let slice = host.substring(sectionStart, index);
          if (!dart.notNull(isNormalized))
            slice = slice.toLowerCase();
          buffer.write(slice);
          buffer.write(Uri._escapeChar(char));
          index = dart.notNull(index) + dart.notNull(sourceLength);
          sectionStart = index;
        }
      }
      if (buffer == null)
        return host.substring(start, end);
      if (dart.notNull(sectionStart) < dart.notNull(end)) {
        let slice = host.substring(sectionStart, end);
        if (!dart.notNull(isNormalized))
          slice = slice.toLowerCase();
        buffer.write(slice);
      }
      return dart.toString(buffer);
    }
    static _makeScheme(scheme, end) {
      if (end == 0)
        return "";
      let firstCodeUnit = scheme.codeUnitAt(0);
      if (!dart.notNull(Uri._isAlphabeticCharacter(firstCodeUnit))) {
        Uri._fail(scheme, 0, "Scheme not starting with alphabetic character");
      }
      let allLowercase = dart.notNull(firstCodeUnit) >= dart.notNull(Uri._LOWER_CASE_A);
      for (let i = 0; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        let codeUnit = scheme.codeUnitAt(i);
        if (!dart.notNull(Uri._isSchemeCharacter(codeUnit))) {
          Uri._fail(scheme, i, "Illegal scheme character");
        }
        if (dart.notNull(codeUnit) < dart.notNull(Uri._LOWER_CASE_A) || dart.notNull(codeUnit) > dart.notNull(Uri._LOWER_CASE_Z)) {
          allLowercase = false;
        }
      }
      scheme = scheme.substring(0, end);
      if (!dart.notNull(allLowercase))
        scheme = scheme.toLowerCase();
      return scheme;
    }
    static _makeUserInfo(userInfo, start, end) {
      if (userInfo == null)
        return "";
      return Uri._normalize(userInfo, start, end, dart.as(Uri._userinfoTable, List$(int)));
    }
    static _makePath(path, start, end, pathSegments, ensureLeadingSlash, isFile) {
      if (path == null && dart.notNull(pathSegments == null))
        return isFile ? "/" : "";
      if (path != null && dart.notNull(pathSegments != null)) {
        throw new ArgumentError('Both path and pathSegments specified');
      }
      let result = null;
      if (path != null) {
        result = Uri._normalize(path, start, end, dart.as(Uri._pathCharOrSlashTable, List$(int)));
      } else {
        result = pathSegments[$map](s => Uri._uriEncode(dart.as(Uri._pathCharTable, List$(int)), dart.as(s, String)))[$join]("/");
      }
      if (dart.dload(result, 'isEmpty')) {
        if (isFile)
          return "/";
      } else if ((dart.notNull(isFile) || dart.notNull(ensureLeadingSlash)) && dart.notNull(!dart.equals(dart.dsend(result, 'codeUnitAt', 0), Uri._SLASH))) {
        return `/${result}`;
      }
      return dart.as(result, String);
    }
    static _makeQuery(query, start, end, queryParameters) {
      if (query == null && dart.notNull(queryParameters == null))
        return null;
      if (query != null && dart.notNull(queryParameters != null)) {
        throw new ArgumentError('Both query and queryParameters specified');
      }
      if (query != null)
        return Uri._normalize(query, start, end, dart.as(Uri._queryCharTable, List$(int)));
      let result = new StringBuffer();
      let first = true;
      queryParameters.forEach((key, value) => {
        if (!dart.notNull(first)) {
          result.write("&");
        }
        first = false;
        result.write(Uri.encodeQueryComponent(dart.as(key, String)));
        if (dart.notNull(value != null) && dart.notNull(dart.dsend(dart.dload(value, 'isEmpty'), '!'))) {
          result.write("=");
          result.write(Uri.encodeQueryComponent(dart.as(value, String)));
        }
      });
      return dart.toString(result);
    }
    static _makeFragment(fragment, start, end) {
      if (fragment == null)
        return null;
      return Uri._normalize(fragment, start, end, dart.as(Uri._queryCharTable, List$(int)));
    }
    static _stringOrNullLength(s) {
      return s == null ? 0 : s.length;
    }
    static _isHexDigit(char) {
      if (dart.notNull(Uri._NINE) >= dart.notNull(char))
        return dart.notNull(Uri._ZERO) <= dart.notNull(char);
      char = dart.notNull(char) | 32;
      return dart.notNull(Uri._LOWER_CASE_A) <= dart.notNull(char) && dart.notNull(Uri._LOWER_CASE_F) >= dart.notNull(char);
    }
    static _hexValue(char) {
      dart.assert(Uri._isHexDigit(char));
      if (dart.notNull(Uri._NINE) >= dart.notNull(char))
        return dart.notNull(char) - dart.notNull(Uri._ZERO);
      char = dart.notNull(char) | 32;
      return dart.notNull(char) - (dart.notNull(Uri._LOWER_CASE_A) - 10);
    }
    static _normalizeEscape(source, index, lowerCase) {
      dart.assert(source.codeUnitAt(index) == Uri._PERCENT);
      if (dart.notNull(index) + 2 >= dart.notNull(source.length)) {
        return "%";
      }
      let firstDigit = source.codeUnitAt(dart.notNull(index) + 1);
      let secondDigit = source.codeUnitAt(dart.notNull(index) + 2);
      if (!dart.notNull(Uri._isHexDigit(firstDigit)) || !dart.notNull(Uri._isHexDigit(secondDigit))) {
        return "%";
      }
      let value = dart.notNull(Uri._hexValue(firstDigit)) * 16 + dart.notNull(Uri._hexValue(secondDigit));
      if (Uri._isUnreservedChar(value)) {
        if (dart.notNull(lowerCase) && dart.notNull(Uri._UPPER_CASE_A) <= dart.notNull(value) && dart.notNull(Uri._UPPER_CASE_Z) >= dart.notNull(value)) {
          value = dart.notNull(value) | 32;
        }
        return new String.fromCharCode(value);
      }
      if (dart.notNull(firstDigit) >= dart.notNull(Uri._LOWER_CASE_A) || dart.notNull(secondDigit) >= dart.notNull(Uri._LOWER_CASE_A)) {
        return source.substring(index, dart.notNull(index) + 3).toUpperCase();
      }
      return null;
    }
    static _isUnreservedChar(ch) {
      return dart.notNull(ch) < 127 && dart.notNull(!dart.equals(dart.dsend(Uri._unreservedTable[$get](dart.notNull(ch) >> 4), '&', 1 << (dart.notNull(ch) & 15)), 0));
    }
    static _escapeChar(char) {
      dart.assert(dart.dsend(char, '<=', 1114111));
      let hexDigits = "0123456789ABCDEF";
      let codeUnits = null;
      if (dart.dsend(char, '<', 128)) {
        codeUnits = new List(3);
        codeUnits[$set](0, Uri._PERCENT);
        codeUnits[$set](1, hexDigits.codeUnitAt(dart.as(dart.dsend(char, '>>', 4), int)));
        codeUnits[$set](2, hexDigits.codeUnitAt(dart.as(dart.dsend(char, '&', 15), int)));
      } else {
        let flag = 192;
        let encodedBytes = 2;
        if (dart.dsend(char, '>', 2047)) {
          flag = 224;
          encodedBytes = 3;
          if (dart.dsend(char, '>', 65535)) {
            encodedBytes = 4;
            flag = 240;
          }
        }
        codeUnits = new List(3 * dart.notNull(encodedBytes));
        let index = 0;
        while ((encodedBytes = dart.notNull(encodedBytes) - 1) >= 0) {
          let byte = dart.as(dart.dsend(dart.dsend(dart.dsend(char, '>>', 6 * dart.notNull(encodedBytes)), '&', 63), '|', flag), int);
          codeUnits[$set](index, Uri._PERCENT);
          codeUnits[$set](dart.notNull(index) + 1, hexDigits.codeUnitAt(dart.notNull(byte) >> 4));
          codeUnits[$set](dart.notNull(index) + 2, hexDigits.codeUnitAt(dart.notNull(byte) & 15));
          index = dart.notNull(index) + 3;
          flag = 128;
        }
      }
      return new String.fromCharCodes(dart.as(codeUnits, Iterable$(int)));
    }
    static _normalize(component, start, end, charTable) {
      let buffer = null;
      let sectionStart = start;
      let index = start;
      while (dart.notNull(index) < dart.notNull(end)) {
        let char = component.codeUnitAt(index);
        if (dart.notNull(char) < 127 && (dart.notNull(charTable[$get](dart.notNull(char) >> 4)) & 1 << (dart.notNull(char) & 15)) != 0) {
          index = dart.notNull(index) + 1;
        } else {
          let replacement = null;
          let sourceLength = null;
          if (char == Uri._PERCENT) {
            replacement = Uri._normalizeEscape(component, index, false);
            if (replacement == null) {
              index = dart.notNull(index) + 3;
              continue;
            }
            if ("%" == replacement) {
              replacement = "%25";
              sourceLength = 1;
            } else {
              sourceLength = 3;
            }
          } else if (Uri._isGeneralDelimiter(char)) {
            Uri._fail(component, index, "Invalid character");
          } else {
            sourceLength = 1;
            if ((dart.notNull(char) & 64512) == 55296) {
              if (dart.notNull(index) + 1 < dart.notNull(end)) {
                let tail = component.codeUnitAt(dart.notNull(index) + 1);
                if ((dart.notNull(tail) & 64512) == 56320) {
                  sourceLength = 2;
                  char = 65536 | (dart.notNull(char) & 1023) << 10 | dart.notNull(tail) & 1023;
                }
              }
            }
            replacement = Uri._escapeChar(char);
          }
          if (buffer == null)
            buffer = new StringBuffer();
          buffer.write(component.substring(sectionStart, index));
          buffer.write(replacement);
          index = dart.notNull(index) + dart.notNull(sourceLength);
          sectionStart = index;
        }
      }
      if (buffer == null) {
        return component.substring(start, end);
      }
      if (dart.notNull(sectionStart) < dart.notNull(end)) {
        buffer.write(component.substring(sectionStart, end));
      }
      return dart.toString(buffer);
    }
    static _isSchemeCharacter(ch) {
      return dart.notNull(ch) < 128 && dart.notNull(!dart.equals(dart.dsend(Uri._schemeTable[$get](dart.notNull(ch) >> 4), '&', 1 << (dart.notNull(ch) & 15)), 0));
    }
    static _isGeneralDelimiter(ch) {
      return dart.notNull(ch) <= dart.notNull(Uri._RIGHT_BRACKET) && dart.notNull(!dart.equals(dart.dsend(Uri._genDelimitersTable[$get](dart.notNull(ch) >> 4), '&', 1 << (dart.notNull(ch) & 15)), 0));
    }
    get isAbsolute() {
      return this.scheme != "" && this.fragment == "";
    }
    [_merge](base, reference) {
      if (base.isEmpty)
        return `/${reference}`;
      let backCount = 0;
      let refStart = 0;
      while (reference.startsWith("../", refStart)) {
        refStart = dart.notNull(refStart) + 3;
        backCount = dart.notNull(backCount) + 1;
      }
      let baseEnd = base.lastIndexOf('/');
      while (dart.notNull(baseEnd) > 0 && dart.notNull(backCount) > 0) {
        let newEnd = base.lastIndexOf('/', dart.notNull(baseEnd) - 1);
        if (dart.notNull(newEnd) < 0) {
          break;
        }
        let delta = dart.notNull(baseEnd) - dart.notNull(newEnd);
        if ((delta == 2 || delta == 3) && base.codeUnitAt(dart.notNull(newEnd) + 1) == Uri._DOT && (delta == 2 || base.codeUnitAt(dart.notNull(newEnd) + 2) == Uri._DOT)) {
          break;
        }
        baseEnd = newEnd;
        backCount = dart.notNull(backCount) - 1;
      }
      return dart.notNull(base.substring(0, dart.notNull(baseEnd) + 1)) + dart.notNull(reference.substring(dart.notNull(refStart) - 3 * dart.notNull(backCount)));
    }
    [_hasDotSegments](path) {
      if (dart.notNull(path.length) > 0 && path.codeUnitAt(0) == Uri._DOT)
        return true;
      let index = path.indexOf("/.");
      return index != -1;
    }
    [_removeDotSegments](path) {
      if (!dart.notNull(this[_hasDotSegments](path)))
        return path;
      let output = dart.setType([], List$(String));
      let appendSlash = false;
      for (let segment of path.split("/")) {
        appendSlash = false;
        if (segment == "..") {
          if (!dart.notNull(output[$isEmpty]) && (output[$length] != 1 || output[$get](0) != ""))
            output[$removeLast]();
          appendSlash = true;
        } else if ("." == segment) {
          appendSlash = true;
        } else {
          output[$add](segment);
        }
      }
      if (appendSlash)
        output[$add]("");
      return output[$join]("/");
    }
    resolve(reference) {
      return this.resolveUri(Uri.parse(reference));
    }
    resolveUri(reference) {
      let targetScheme = null;
      let targetUserInfo = "";
      let targetHost = null;
      let targetPort = null;
      let targetPath = null;
      let targetQuery = null;
      if (reference.scheme.isNotEmpty) {
        targetScheme = reference.scheme;
        if (reference.hasAuthority) {
          targetUserInfo = reference.userInfo;
          targetHost = reference.host;
          targetPort = reference.hasPort ? reference.port : null;
        }
        targetPath = this[_removeDotSegments](reference.path);
        if (reference.hasQuery) {
          targetQuery = reference.query;
        }
      } else {
        targetScheme = this.scheme;
        if (reference.hasAuthority) {
          targetUserInfo = reference.userInfo;
          targetHost = reference.host;
          targetPort = Uri._makePort(reference.hasPort ? reference.port : null, targetScheme);
          targetPath = this[_removeDotSegments](reference.path);
          if (reference.hasQuery)
            targetQuery = reference.query;
        } else {
          if (reference.path == "") {
            targetPath = this[_path];
            if (reference.hasQuery) {
              targetQuery = reference.query;
            } else {
              targetQuery = this[_query];
            }
          } else {
            if (reference.path.startsWith("/")) {
              targetPath = this[_removeDotSegments](reference.path);
            } else {
              targetPath = this[_removeDotSegments](this[_merge](this[_path], reference.path));
            }
            if (reference.hasQuery)
              targetQuery = reference.query;
          }
          targetUserInfo = this[_userInfo];
          targetHost = this[_host];
          targetPort = this[_port];
        }
      }
      let fragment = reference.hasFragment ? reference.fragment : null;
      return new Uri._internal(targetScheme, targetUserInfo, targetHost, targetPort, targetPath, targetQuery, fragment);
    }
    get hasAuthority() {
      return this[_host] != null;
    }
    get hasPort() {
      return this[_port] != null;
    }
    get hasQuery() {
      return this[_query] != null;
    }
    get hasFragment() {
      return this[_fragment] != null;
    }
    get origin() {
      if (this.scheme == "" || this[_host] == null || this[_host] == "") {
        throw new StateError(`Cannot use origin without a scheme: ${this}`);
      }
      if (this.scheme != "http" && this.scheme != "https") {
        throw new StateError(`Origin is only applicable schemes http and https: ${this}`);
      }
      if (this[_port] == null)
        return `${this.scheme}://${this[_host]}`;
      return `${this.scheme}://${this[_host]}:${this[_port]}`;
    }
    toFilePath(opts) {
      let windows = opts && 'windows' in opts ? opts.windows : null;
      if (this.scheme != "" && this.scheme != "file") {
        throw new UnsupportedError(`Cannot extract a file path from a ${this.scheme} URI`);
      }
      if (this.query != "") {
        throw new UnsupportedError("Cannot extract a file path from a URI with a query component");
      }
      if (this.fragment != "") {
        throw new UnsupportedError("Cannot extract a file path from a URI with a fragment component");
      }
      if (windows == null)
        windows = Uri._isWindows;
      return windows ? this[_toWindowsFilePath]() : this[_toFilePath]();
    }
    [_toFilePath]() {
      if (this.host != "") {
        throw new UnsupportedError("Cannot extract a non-Windows file path from a file URI " + "with an authority");
      }
      Uri._checkNonWindowsPathReservedCharacters(this.pathSegments, false);
      let result = new StringBuffer();
      if (this[_isPathAbsolute])
        result.write("/");
      result.writeAll(this.pathSegments, "/");
      return dart.toString(result);
    }
    [_toWindowsFilePath]() {
      let hasDriveLetter = false;
      let segments = this.pathSegments;
      if (dart.notNull(segments[$length]) > 0 && segments[$get](0).length == 2 && segments[$get](0).codeUnitAt(1) == Uri._COLON) {
        Uri._checkWindowsDriveLetter(segments[$get](0).codeUnitAt(0), false);
        Uri._checkWindowsPathReservedCharacters(segments, false, 1);
        hasDriveLetter = true;
      } else {
        Uri._checkWindowsPathReservedCharacters(segments, false);
      }
      let result = new StringBuffer();
      if (dart.notNull(this[_isPathAbsolute]) && !dart.notNull(hasDriveLetter))
        result.write("\\");
      if (this.host != "") {
        result.write("\\");
        result.write(this.host);
        result.write("\\");
      }
      result.writeAll(segments, "\\");
      if (dart.notNull(hasDriveLetter) && segments[$length] == 1)
        result.write("\\");
      return dart.toString(result);
    }
    get [_isPathAbsolute]() {
      if (this.path == null || dart.notNull(this.path.isEmpty))
        return false;
      return this.path.startsWith('/');
    }
    [_writeAuthority](ss) {
      if (this[_userInfo].isNotEmpty) {
        ss.write(this[_userInfo]);
        ss.write("@");
      }
      if (this[_host] != null)
        ss.write(this[_host]);
      if (this[_port] != null) {
        ss.write(":");
        ss.write(this[_port]);
      }
    }
    toString() {
      let sb = new StringBuffer();
      Uri._addIfNonEmpty(sb, this.scheme, this.scheme, ':');
      if (dart.notNull(this.hasAuthority) || dart.notNull(this.path.startsWith("//")) || this.scheme == "file") {
        sb.write("//");
        this[_writeAuthority](sb);
      }
      sb.write(this.path);
      if (this[_query] != null) {
        sb.write("?");
        sb.write(this[_query]);
      }
      if (this[_fragment] != null) {
        sb.write("#");
        sb.write(this[_fragment]);
      }
      return dart.toString(sb);
    }
    ['=='](other) {
      if (!dart.is(other, Uri))
        return false;
      let uri = dart.as(other, Uri);
      return this.scheme == uri.scheme && this.hasAuthority == uri.hasAuthority && this.userInfo == uri.userInfo && this.host == uri.host && this.port == uri.port && this.path == uri.path && this.hasQuery == uri.hasQuery && this.query == uri.query && this.hasFragment == uri.hasFragment && this.fragment == uri.fragment;
    }
    get hashCode() {
      // Function combine: (dynamic, dynamic) → int
      function combine(part, current) {
        return dart.as(dart.dsend(dart.dsend(dart.dsend(current, '*', 31), '+', dart.hashCode(part)), '&', 1073741823), int);
      }
      return combine(this.scheme, combine(this.userInfo, combine(this.host, combine(this.port, combine(this.path, combine(this.query, combine(this.fragment, 1)))))));
    }
    static _addIfNonEmpty(sb, test, first, second) {
      if ("" != test) {
        sb.write(first);
        sb.write(second);
      }
    }
    static encodeComponent(component) {
      return Uri._uriEncode(dart.as(Uri._unreserved2396Table, List$(int)), component);
    }
    static encodeQueryComponent(component, opts) {
      let encoding = opts && 'encoding' in opts ? opts.encoding : convert.UTF8;
      return Uri._uriEncode(dart.as(Uri._unreservedTable, List$(int)), component, {encoding: encoding, spaceToPlus: true});
    }
    static decodeComponent(encodedComponent) {
      return Uri._uriDecode(encodedComponent);
    }
    static decodeQueryComponent(encodedComponent, opts) {
      let encoding = opts && 'encoding' in opts ? opts.encoding : convert.UTF8;
      return Uri._uriDecode(encodedComponent, {plusToSpace: true, encoding: encoding});
    }
    static encodeFull(uri) {
      return Uri._uriEncode(dart.as(Uri._encodeFullTable, List$(int)), uri);
    }
    static decodeFull(uri) {
      return Uri._uriDecode(uri);
    }
    static splitQueryString(query, opts) {
      let encoding = opts && 'encoding' in opts ? opts.encoding : convert.UTF8;
      return dart.as(query.split("&")[$fold](dart.map(), (map, element) => {
        let index = dart.as(dart.dsend(element, 'indexOf', "="), int);
        if (index == -1) {
          if (!dart.equals(element, "")) {
            dart.dsetindex(map, Uri.decodeQueryComponent(dart.as(element, String), {encoding: encoding}), "");
          }
        } else if (index != 0) {
          let key = dart.dsend(element, 'substring', 0, index);
          let value = dart.dsend(element, 'substring', dart.notNull(index) + 1);
          dart.dsetindex(map, Uri.decodeQueryComponent(dart.as(key, String), {encoding: encoding}), Uri.decodeQueryComponent(dart.as(value, String), {encoding: encoding}));
        }
        return map;
      }), Map$(String, String));
    }
    static parseIPv4Address(host) {
      // Function error: (String) → void
      function error(msg) {
        throw new FormatException(`Illegal IPv4 address, ${msg}`);
      }
      let bytes = host.split('.');
      if (bytes[$length] != 4) {
        error('IPv4 address should contain exactly 4 parts');
      }
      return dart.as(bytes[$map](byteString => {
        let byte = int.parse(dart.as(byteString, String));
        if (dart.notNull(byte) < 0 || dart.notNull(byte) > 255) {
          error('each part must be in the range of `0..255`');
        }
        return byte;
      })[$toList](), List$(int));
    }
    static parseIPv6Address(host, start, end) {
      if (start === void 0)
        start = 0;
      if (end === void 0)
        end = null;
      if (end == null)
        end = host.length;
      // Function error: (String, [dynamic]) → void
      function error(msg, position) {
        if (position === void 0)
          position = null;
        throw new FormatException(`Illegal IPv6 address, ${msg}`, host, dart.as(position, int));
      }
      // Function parseHex: (int, int) → int
      function parseHex(start, end) {
        if (dart.notNull(end) - dart.notNull(start) > 4) {
          error('an IPv6 part can only contain a maximum of 4 hex digits', start);
        }
        let value = int.parse(host.substring(start, end), {radix: 16});
        if (dart.notNull(value) < 0 || dart.notNull(value) > (1 << 16) - 1) {
          error('each part must be in the range of `0x0..0xFFFF`', start);
        }
        return value;
      }
      if (dart.notNull(host.length) < 2)
        error('address is too short');
      let parts = dart.setType([], List$(int));
      let wildcardSeen = false;
      let partStart = start;
      for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
        if (host.codeUnitAt(i) == Uri._COLON) {
          if (i == start) {
            i = dart.notNull(i) + 1;
            if (host.codeUnitAt(i) != Uri._COLON) {
              error('invalid start colon.', i);
            }
            partStart = i;
          }
          if (i == partStart) {
            if (wildcardSeen) {
              error('only one wildcard `::` is allowed', i);
            }
            wildcardSeen = true;
            parts[$add](-1);
          } else {
            parts[$add](parseHex(partStart, i));
          }
          partStart = dart.notNull(i) + 1;
        }
      }
      if (parts[$length] == 0)
        error('too few parts');
      let atEnd = partStart == end;
      let isLastWildcard = parts[$last] == -1;
      if (dart.notNull(atEnd) && !dart.notNull(isLastWildcard)) {
        error('expected a part after last `:`', end);
      }
      if (!dart.notNull(atEnd)) {
        try {
          parts[$add](parseHex(partStart, end));
        } catch (e) {
          try {
            let last = Uri.parseIPv4Address(host.substring(partStart, end));
            parts[$add](dart.notNull(last[$get](0)) << 8 | dart.notNull(last[$get](1)));
            parts[$add](dart.notNull(last[$get](2)) << 8 | dart.notNull(last[$get](3)));
          } catch (e) {
            error('invalid end of IPv6 address.', partStart);
          }

        }

      }
      if (wildcardSeen) {
        if (dart.notNull(parts[$length]) > 7) {
          error('an address with a wildcard must have less than 7 parts');
        }
      } else if (parts[$length] != 8) {
        error('an address without a wildcard must contain exactly 8 parts');
      }
      let bytes = new (List$(int))(16);
      for (let i = 0, index = 0; dart.notNull(i) < dart.notNull(parts[$length]); i = dart.notNull(i) + 1) {
        let value = parts[$get](i);
        if (value == -1) {
          let wildCardLength = 9 - dart.notNull(parts[$length]);
          for (let j = 0; dart.notNull(j) < dart.notNull(wildCardLength); j = dart.notNull(j) + 1) {
            bytes[$set](index, 0);
            bytes[$set](dart.notNull(index) + 1, 0);
            index = dart.notNull(index) + 2;
          }
        } else {
          bytes[$set](index, dart.notNull(value) >> 8);
          bytes[$set](dart.notNull(index) + 1, dart.notNull(value) & 255);
          index = dart.notNull(index) + 2;
        }
      }
      return dart.as(bytes, List$(int));
    }
    static _uriEncode(canonicalTable, text, opts) {
      let encoding = opts && 'encoding' in opts ? opts.encoding : convert.UTF8;
      let spaceToPlus = opts && 'spaceToPlus' in opts ? opts.spaceToPlus : false;
      // Function byteToHex: (dynamic, dynamic) → dynamic
      function byteToHex(byte, buffer) {
        let hex = '0123456789ABCDEF';
        dart.dsend(buffer, 'writeCharCode', hex.codeUnitAt(dart.as(dart.dsend(byte, '>>', 4), int)));
        dart.dsend(buffer, 'writeCharCode', hex.codeUnitAt(dart.as(dart.dsend(byte, '&', 15), int)));
      }
      let result = new StringBuffer();
      let bytes = encoding.encode(text);
      for (let i = 0; dart.notNull(i) < dart.notNull(bytes[$length]); i = dart.notNull(i) + 1) {
        let byte = bytes[$get](i);
        if (dart.notNull(byte) < 128 && (dart.notNull(canonicalTable[$get](dart.notNull(byte) >> 4)) & 1 << (dart.notNull(byte) & 15)) != 0) {
          result.writeCharCode(byte);
        } else if (dart.notNull(spaceToPlus) && byte == Uri._SPACE) {
          result.writeCharCode(Uri._PLUS);
        } else {
          result.writeCharCode(Uri._PERCENT);
          byteToHex(byte, result);
        }
      }
      return dart.toString(result);
    }
    static _hexCharPairToByte(s, pos) {
      let byte = 0;
      for (let i = 0; dart.notNull(i) < 2; i = dart.notNull(i) + 1) {
        let charCode = s.codeUnitAt(dart.notNull(pos) + dart.notNull(i));
        if (48 <= dart.notNull(charCode) && dart.notNull(charCode) <= 57) {
          byte = dart.notNull(byte) * 16 + dart.notNull(charCode) - 48;
        } else {
          charCode = dart.notNull(charCode) | 32;
          if (97 <= dart.notNull(charCode) && dart.notNull(charCode) <= 102) {
            byte = dart.notNull(byte) * 16 + dart.notNull(charCode) - 87;
          } else {
            throw new ArgumentError("Invalid URL encoding");
          }
        }
      }
      return byte;
    }
    static _uriDecode(text, opts) {
      let plusToSpace = opts && 'plusToSpace' in opts ? opts.plusToSpace : false;
      let encoding = opts && 'encoding' in opts ? opts.encoding : convert.UTF8;
      let simple = true;
      for (let i = 0; dart.notNull(i) < dart.notNull(text.length) && dart.notNull(simple); i = dart.notNull(i) + 1) {
        let codeUnit = text.codeUnitAt(i);
        simple = codeUnit != Uri._PERCENT && codeUnit != Uri._PLUS;
      }
      let bytes = null;
      if (simple) {
        if (dart.notNull(dart.equals(encoding, convert.UTF8)) || dart.notNull(dart.equals(encoding, convert.LATIN1))) {
          return text;
        } else {
          bytes = text.codeUnits;
        }
      } else {
        bytes = new (List$(int))();
        for (let i = 0; dart.notNull(i) < dart.notNull(text.length); i = dart.notNull(i) + 1) {
          let codeUnit = text.codeUnitAt(i);
          if (dart.notNull(codeUnit) > 127) {
            throw new ArgumentError("Illegal percent encoding in URI");
          }
          if (codeUnit == Uri._PERCENT) {
            if (dart.notNull(i) + 3 > dart.notNull(text.length)) {
              throw new ArgumentError('Truncated URI');
            }
            bytes[$add](Uri._hexCharPairToByte(text, dart.notNull(i) + 1));
            i = dart.notNull(i) + 2;
          } else if (dart.notNull(plusToSpace) && codeUnit == Uri._PLUS) {
            bytes[$add](Uri._SPACE);
          } else {
            bytes[$add](codeUnit);
          }
        }
      }
      return encoding.decode(bytes);
    }
    static _isAlphabeticCharacter(codeUnit) {
      return dart.notNull(codeUnit) >= dart.notNull(Uri._LOWER_CASE_A) && dart.notNull(codeUnit) <= dart.notNull(Uri._LOWER_CASE_Z) || dart.notNull(codeUnit) >= dart.notNull(Uri._UPPER_CASE_A) && dart.notNull(codeUnit) <= dart.notNull(Uri._UPPER_CASE_Z);
    }
  }
  dart.defineNamedConstructor(Uri, '_internal');
  dart.defineNamedConstructor(Uri, 'http');
  dart.defineNamedConstructor(Uri, 'https');
  dart.defineNamedConstructor(Uri, 'file');
  Uri._SPACE = 32;
  Uri._DOUBLE_QUOTE = 34;
  Uri._NUMBER_SIGN = 35;
  Uri._PERCENT = 37;
  Uri._ASTERISK = 42;
  Uri._PLUS = 43;
  Uri._DOT = 46;
  Uri._SLASH = 47;
  Uri._ZERO = 48;
  Uri._NINE = 57;
  Uri._COLON = 58;
  Uri._LESS = 60;
  Uri._GREATER = 62;
  Uri._QUESTION = 63;
  Uri._AT_SIGN = 64;
  Uri._UPPER_CASE_A = 65;
  Uri._UPPER_CASE_F = 70;
  Uri._UPPER_CASE_Z = 90;
  Uri._LEFT_BRACKET = 91;
  Uri._BACKSLASH = 92;
  Uri._RIGHT_BRACKET = 93;
  Uri._LOWER_CASE_A = 97;
  Uri._LOWER_CASE_F = 102;
  Uri._LOWER_CASE_Z = 122;
  Uri._BAR = 124;
  Uri._unreservedTable = dart.const([0, 0, 24576, 1023, 65534, 34815, 65534, 18431]);
  Uri._unreserved2396Table = dart.const([0, 0, 26498, 1023, 65534, 34815, 65534, 18431]);
  Uri._encodeFullTable = dart.const([0, 0, 65498, 45055, 65535, 34815, 65534, 18431]);
  Uri._schemeTable = dart.const([0, 0, 26624, 1023, 65534, 2047, 65534, 2047]);
  Uri._schemeLowerTable = dart.const([0, 0, 26624, 1023, 0, 0, 65534, 2047]);
  Uri._subDelimitersTable = dart.const([0, 0, 32722, 11263, 65534, 34815, 65534, 18431]);
  Uri._genDelimitersTable = dart.const([0, 0, 32776, 33792, 1, 10240, 0, 0]);
  Uri._userinfoTable = dart.const([0, 0, 32722, 12287, 65534, 34815, 65534, 18431]);
  Uri._regNameTable = dart.const([0, 0, 32754, 11263, 65534, 34815, 65534, 18431]);
  Uri._pathCharTable = dart.const([0, 0, 32722, 12287, 65535, 34815, 65534, 18431]);
  Uri._pathCharOrSlashTable = dart.const([0, 0, 65490, 12287, 65535, 34815, 65534, 18431]);
  Uri._queryCharTable = dart.const([0, 0, 65490, 45055, 65535, 34815, 65534, 18431]);
  // Function _symbolToString: (Symbol) → String
  function _symbolToString(symbol) {
    return _internal.Symbol.getName(dart.as(symbol, _internal.Symbol));
  }
  // Function _symbolMapToStringMap: (Map<Symbol, dynamic>) → dynamic
  function _symbolMapToStringMap(map) {
    if (map == null)
      return null;
    let result = new (Map$(String, dart.dynamic))();
    map.forEach((key, value) => {
      result.set(_symbolToString(key), value);
    });
    return result;
  }
  class SupportJsExtensionMethods extends Object {
    SupportJsExtensionMethods() {
    }
  }
  class _ListConstructorSentinel extends Object {
    _ListConstructorSentinel() {
    }
  }
  // Exports:
  exports.JsName = JsName;
  exports.Object = Object;
  exports.JsPeerInterface = JsPeerInterface;
  exports.SupportJsExtensionMethod = SupportJsExtensionMethod;
  exports.Deprecated = Deprecated;
  exports.deprecated = deprecated;
  exports.override = override;
  exports.proxy = proxy;
  exports.bool = bool;
  exports.Comparator$ = Comparator$;
  exports.Comparator = Comparator;
  exports.Function = Function;
  exports.Comparable$ = Comparable$;
  exports.Comparable = Comparable;
  exports.DateTime = DateTime;
  exports.double = double;
  exports.num = num;
  exports.Duration = Duration;
  exports.Error = Error;
  exports.AssertionError = AssertionError;
  exports.TypeError = TypeError;
  exports.CastError = CastError;
  exports.NullThrownError = NullThrownError;
  exports.ArgumentError = ArgumentError;
  exports.RangeError = RangeError;
  exports.IndexError = IndexError;
  exports.FallThroughError = FallThroughError;
  exports.AbstractClassInstantiationError = AbstractClassInstantiationError;
  exports.$length = $length;
  exports.$get = $get;
  exports.NoSuchMethodError = NoSuchMethodError;
  exports.UnsupportedError = UnsupportedError;
  exports.UnimplementedError = UnimplementedError;
  exports.StateError = StateError;
  exports.ConcurrentModificationError = ConcurrentModificationError;
  exports.OutOfMemoryError = OutOfMemoryError;
  exports.StackOverflowError = StackOverflowError;
  exports.CyclicInitializationError = CyclicInitializationError;
  exports.Exception = Exception;
  exports.FormatException = FormatException;
  exports.IntegerDivisionByZeroException = IntegerDivisionByZeroException;
  exports.Expando$ = Expando$;
  exports.Expando = Expando;
  exports.identical = identical;
  exports.identityHashCode = identityHashCode;
  exports.int = int;
  exports.Invocation = Invocation;
  exports.$iterator = $iterator;
  exports.$join = $join;
  exports.Iterable$ = Iterable$;
  exports.Iterable = Iterable;
  exports.$skip = $skip;
  exports.$take = $take;
  exports.BidirectionalIterator$ = BidirectionalIterator$;
  exports.BidirectionalIterator = BidirectionalIterator;
  exports.Iterator$ = Iterator$;
  exports.Iterator = Iterator;
  exports.$set = $set;
  exports.$add = $add;
  exports.$checkMutable = $checkMutable;
  exports.$checkGrowable = $checkGrowable;
  exports.$where = $where;
  exports.$expand = $expand;
  exports.$forEach = $forEach;
  exports.$map = $map;
  exports.$takeWhile = $takeWhile;
  exports.$skipWhile = $skipWhile;
  exports.$reduce = $reduce;
  exports.$fold = $fold;
  exports.$firstWhere = $firstWhere;
  exports.$lastWhere = $lastWhere;
  exports.$singleWhere = $singleWhere;
  exports.$elementAt = $elementAt;
  exports.$first = $first;
  exports.$last = $last;
  exports.$single = $single;
  exports.$any = $any;
  exports.$every = $every;
  exports.$contains = $contains;
  exports.$isEmpty = $isEmpty;
  exports.$isNotEmpty = $isNotEmpty;
  exports.$toString = $toString;
  exports.$toList = $toList;
  exports.$toSet = $toSet;
  exports.$hashCode = $hashCode;
  exports.$addAll = $addAll;
  exports.$reversed = $reversed;
  exports.$sort = $sort;
  exports.$shuffle = $shuffle;
  exports.$indexOf = $indexOf;
  exports.$lastIndexOf = $lastIndexOf;
  exports.$clear = $clear;
  exports.$insert = $insert;
  exports.$insertAll = $insertAll;
  exports.$setAll = $setAll;
  exports.$remove = $remove;
  exports.$removeAt = $removeAt;
  exports.$removeLast = $removeLast;
  exports.$removeWhere = $removeWhere;
  exports.$retainWhere = $retainWhere;
  exports.$sublist = $sublist;
  exports.$getRange = $getRange;
  exports.$setRange = $setRange;
  exports.$removeRange = $removeRange;
  exports.$fillRange = $fillRange;
  exports.$replaceRange = $replaceRange;
  exports.$asMap = $asMap;
  exports.List$ = List$;
  exports.List = List;
  exports.Map$ = Map$;
  exports.Map = Map;
  exports.Null = Null;
  exports.Pattern = Pattern;
  exports.print = print;
  exports.Match = Match;
  exports.RegExp = RegExp;
  exports.Set$ = Set$;
  exports.Sink$ = Sink$;
  exports.Sink = Sink;
  exports.StackTrace = StackTrace;
  exports.Stopwatch = Stopwatch;
  exports.String = String;
  exports.RuneIterator = RuneIterator;
  exports.StringBuffer = StringBuffer;
  exports.StringSink = StringSink;
  exports.Symbol = Symbol;
  exports.Type = Type;
  exports.Uri = Uri;
  exports.SupportJsExtensionMethods = SupportJsExtensionMethods;
})(core, _js_helper, _internal, collection, _interceptors, convert);
