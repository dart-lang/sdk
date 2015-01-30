var core;
(function (core) {
  'use strict';
  class Deprecated {
    constructor(expires) {
      this.expires = expires;
    }
    toString() { return "Deprecated feature. Will be removed " + (this.expires) + ""; }
  }

  class _Override {
    constructor() {
    }
  }

  let deprecated = new Deprecated("next release");
  let override = new _Override();
  class _Proxy {
    constructor() {
    }
  }

  let proxy = new _Proxy();
  class bool {
    __init_fromEnvironment(name, opt$) {
      let defaultValue = opt$.defaultValue === undefined ? false : opt$.defaultValue;
    }
    toString() {
      return this ? "true" : "false";
    }
  }
  bool.fromEnvironment = function(name, opt$) { this.__init_fromEnvironment(name, opt$) };
  bool.fromEnvironment.prototype = bool.prototype;

  class Comparable/* Unimplemented <T> */ {
    static compare(a, b) { return a.this.compareTo(b); }
  }

  class DateTime {
    constructor(year, month, day, hour, minute, second, millisecond) {
      if (month === undefined) month = 1;
      if (day === undefined) day = 1;
      if (hour === undefined) hour = 0;
      if (minute === undefined) minute = 0;
      if (second === undefined) second = 0;
      if (millisecond === undefined) millisecond = 0;
      DateTime.call(this, year, month, day, hour, minute, second, millisecond, false);
    }
    __init_utc(year, month, day, hour, minute, second, millisecond) {
      if (month === undefined) month = 1;
      if (day === undefined) day = 1;
      if (hour === undefined) hour = 0;
      if (minute === undefined) minute = 0;
      if (second === undefined) second = 0;
      if (millisecond === undefined) millisecond = 0;
      utc.call(this, year, month, day, hour, minute, second, millisecond, true);
    }
    __init_now() {
      now.call(this);
    }
    static parse(formattedString) {
      let re = new RegExp("^([+-]?\d{4,6})-?(\d\d)-?(\d\d)" + "(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(.\d{1,6})?)?)?" + "( ?[zZ]| ?([-+])(\d\d)(?::?(\d\d))?)?)?$");
      let match = re.firstMatch(formattedString);
      if (match !== null) {
        // Function parseIntOrZero: (String) → int
        function parseIntOrZero(matched) {
          if (matched === null) return 0;
          return int.parse(matched);
        }
        // Function parseDoubleOrZero: (String) → double
        function parseDoubleOrZero(matched) {
          if (matched === null) return 0.0;
          return double.parse(matched);
        }
        let years = int.parse(match[1]);
        let month = int.parse(match[2]);
        let day = int.parse(match[3]);
        let hour = parseIntOrZero(match[4]);
        let minute = parseIntOrZero(match[5]);
        let second = parseIntOrZero(match[6]);
        let addOneMillisecond = false;
        let millisecond = (parseDoubleOrZero(match[7]) * 1000).round();
        if (millisecond === 1000) {
          addOneMillisecond = true;
          millisecond = 999;
        }
        let isUtc = false;
        if (match[8] !== null) {
          isUtc = true;
          if (match[9] !== null) {
            let sign = (dart.equals(match[9], "-")) ? -1 : 1;
            let hourDifference = int.parse(match[10]);
            let minuteDifference = parseIntOrZero(match[11]);
            minuteDifference = 60 * hourDifference;
            minute = sign * minuteDifference;
          }
        }
        let millisecondsSinceEpoch = _brokenDownDateToMillisecondsSinceEpoch(years, month, day, hour, minute, second, millisecond, isUtc);
        if (millisecondsSinceEpoch === null) {
          throw new FormatException("Time out of range", formattedString);
        }
        if (addOneMillisecond) millisecondsSinceEpoch++;
        return new DateTime.this.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, /* Unimplemented NamedExpression: isUtc: isUtc */);
      }
       else {
        throw new FormatException("Invalid date format", formattedString);
      }
    }
    __init_fromMillisecondsSinceEpoch(millisecondsSinceEpoch, opt$) {
      let isUtc = opt$.isUtc === undefined ? false : opt$.isUtc;
      this.millisecondsSinceEpoch = millisecondsSinceEpoch;
      this.isUtc = isUtc;
      this.MONDAY = 1;
      this.TUESDAY = 2;
      this.WEDNESDAY = 3;
      this.THURSDAY = 4;
      this.FRIDAY = 5;
      this.SATURDAY = 6;
      this.SUNDAY = 7;
      this.DAYS_PER_WEEK = 7;
      this.JANUARY = 1;
      this.FEBRUARY = 2;
      this.MARCH = 3;
      this.APRIL = 4;
      this.MAY = 5;
      this.JUNE = 6;
      this.JULY = 7;
      this.AUGUST = 8;
      this.SEPTEMBER = 9;
      this.OCTOBER = 10;
      this.NOVEMBER = 11;
      this.DECEMBER = 12;
      this.MONTHS_PER_YEAR = 12;
      this._MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;
      if (millisecondsSinceEpoch.abs() > _MAX_MILLISECONDS_SINCE_EPOCH) {
        throw new ArgumentError(millisecondsSinceEpoch);
      }
      if (isUtc === null) throw new ArgumentError(isUtc);
    }
    ==(other) {
      if (!(/* Unimplemented IsExpression: other is DateTime */)) return false;
      return (this.millisecondsSinceEpoch === dart.dload(other, "millisecondsSinceEpoch") && this.isUtc === dart.dload(other, "isUtc"));
    }
    isBefore(other) {
      return this.millisecondsSinceEpoch < other.millisecondsSinceEpoch;
    }
    isAfter(other) {
      return this.millisecondsSinceEpoch > other.millisecondsSinceEpoch;
    }
    isAtSameMomentAs(other) {
      return this.millisecondsSinceEpoch === other.millisecondsSinceEpoch;
    }
    compareTo(other) { return this.millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch); }
    get hashCode() { return this.millisecondsSinceEpoch; }
    toLocal() {
      if (this.isUtc) {
        return new DateTime.this.fromMillisecondsSinceEpoch(this.millisecondsSinceEpoch, /* Unimplemented NamedExpression: isUtc: false */);
      }
      return this;
    }
    toUtc() {
      if (this.isUtc) return this;
      return new DateTime.this.fromMillisecondsSinceEpoch(this.millisecondsSinceEpoch, /* Unimplemented NamedExpression: isUtc: true */);
    }
    static _fourDigits(n) {
      let absN = n.abs();
      let sign = n < 0 ? "-" : "";
      if (absN >= 1000) return "" + (n) + "";
      if (absN >= 100) return "" + (sign) + "0" + (absN) + "";
      if (absN >= 10) return "" + (sign) + "00" + (absN) + "";
      return "" + (sign) + "000" + (absN) + "";
    }
    static _sixDigits(n) {
      dart.assert(n < -9999 || n > 9999);
      let absN = n.abs();
      let sign = n < 0 ? "-" : "+";
      if (absN >= 100000) return "" + (sign) + "" + (absN) + "";
      return "" + (sign) + "0" + (absN) + "";
    }
    static _threeDigits(n) {
      if (n >= 100) return "" + (n) + "";
      if (n >= 10) return "0" + (n) + "";
      return "00" + (n) + "";
    }
    static _twoDigits(n) {
      if (n >= 10) return "" + (n) + "";
      return "0" + (n) + "";
    }
    toString() {
      let y = _fourDigits(this.year);
      let m = _twoDigits(this.month);
      let d = _twoDigits(this.day);
      let h = _twoDigits(this.hour);
      let min = _twoDigits(this.minute);
      let sec = _twoDigits(this.second);
      let ms = _threeDigits(this.millisecond);
      if (this.isUtc) {
        return "" + (y) + "-" + (m) + "-" + (d) + " " + (h) + ":" + (min) + ":" + (sec) + "." + (ms) + "Z";
      }
       else {
        return "" + (y) + "-" + (m) + "-" + (d) + " " + (h) + ":" + (min) + ":" + (sec) + "." + (ms) + "";
      }
    }
    toIso8601String() {
      let y = (this.year >= -9999 && this.year <= 9999) ? _fourDigits(this.year) : _sixDigits(this.year);
      let m = _twoDigits(this.month);
      let d = _twoDigits(this.day);
      let h = _twoDigits(this.hour);
      let min = _twoDigits(this.minute);
      let sec = _twoDigits(this.second);
      let ms = _threeDigits(this.millisecond);
      if (this.isUtc) {
        return "" + (y) + "-" + (m) + "-" + (d) + "T" + (h) + ":" + (min) + ":" + (sec) + "." + (ms) + "Z";
      }
       else {
        return "" + (y) + "-" + (m) + "-" + (d) + "T" + (h) + ":" + (min) + ":" + (sec) + "." + (ms) + "";
      }
    }
    add(duration) {
      let ms = this.millisecondsSinceEpoch;
      return new DateTime.this.fromMillisecondsSinceEpoch(ms + duration.inMilliseconds, /* Unimplemented NamedExpression: isUtc: isUtc */);
    }
    subtract(duration) {
      let ms = this.millisecondsSinceEpoch;
      return new DateTime.this.fromMillisecondsSinceEpoch(ms - duration.inMilliseconds, /* Unimplemented NamedExpression: isUtc: isUtc */);
    }
    difference(other) {
      let ms = this.millisecondsSinceEpoch;
      let otherMs = other.millisecondsSinceEpoch;
      return new Duration(/* Unimplemented NamedExpression: milliseconds: ms - otherMs */);
    }
    __init__internal(year, month, day, hour, minute, second, millisecond, isUtc) {
      this.MONDAY = 1;
      this.TUESDAY = 2;
      this.WEDNESDAY = 3;
      this.THURSDAY = 4;
      this.FRIDAY = 5;
      this.SATURDAY = 6;
      this.SUNDAY = 7;
      this.DAYS_PER_WEEK = 7;
      this.JANUARY = 1;
      this.FEBRUARY = 2;
      this.MARCH = 3;
      this.APRIL = 4;
      this.MAY = 5;
      this.JUNE = 6;
      this.JULY = 7;
      this.AUGUST = 8;
      this.SEPTEMBER = 9;
      this.OCTOBER = 10;
      this.NOVEMBER = 11;
      this.DECEMBER = 12;
      this.MONTHS_PER_YEAR = 12;
      this.millisecondsSinceEpoch = null;
      this.isUtc = null;
      this._MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;
    }
    __init__now() {
      this.MONDAY = 1;
      this.TUESDAY = 2;
      this.WEDNESDAY = 3;
      this.THURSDAY = 4;
      this.FRIDAY = 5;
      this.SATURDAY = 6;
      this.SUNDAY = 7;
      this.DAYS_PER_WEEK = 7;
      this.JANUARY = 1;
      this.FEBRUARY = 2;
      this.MARCH = 3;
      this.APRIL = 4;
      this.MAY = 5;
      this.JUNE = 6;
      this.JULY = 7;
      this.AUGUST = 8;
      this.SEPTEMBER = 9;
      this.OCTOBER = 10;
      this.NOVEMBER = 11;
      this.DECEMBER = 12;
      this.MONTHS_PER_YEAR = 12;
      this.millisecondsSinceEpoch = null;
      this.isUtc = null;
      this._MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;
    }
    static _brokenDownDateToMillisecondsSinceEpoch(year, month, day, hour, minute, second, millisecond, isUtc) {}
    get timeZoneName() {}
    get timeZoneOffset() {}
    get year() {}
    get month() {}
    get day() {}
    get hour() {}
    get minute() {}
    get second() {}
    get millisecond() {}
    get weekday() {}
  }
  DateTime.utc = function(year, month, day, hour, minute, second, millisecond) { this.__init_utc(year, month, day, hour, minute, second, millisecond) };
  DateTime.utc.prototype = DateTime.prototype;
  DateTime.now = function() { this.__init_now() };
  DateTime.now.prototype = DateTime.prototype;
  DateTime.fromMillisecondsSinceEpoch = function(millisecondsSinceEpoch, opt$) { this.__init_fromMillisecondsSinceEpoch(millisecondsSinceEpoch, opt$) };
  DateTime.fromMillisecondsSinceEpoch.prototype = DateTime.prototype;
  DateTime._internal = function(year, month, day, hour, minute, second, millisecond, isUtc) { this.__init__internal(year, month, day, hour, minute, second, millisecond, isUtc) };
  DateTime._internal.prototype = DateTime.prototype;
  DateTime._now = function() { this.__init__now() };
  DateTime._now.prototype = DateTime.prototype;

  class double extends num {
    constructor() {
      this.NAN = 0.0 / 0.0;
      this.INFINITY = 1.0 / 0.0;
      this.NEGATIVE_INFINITY = -INFINITY;
      this.MIN_POSITIVE = 5e-324;
      this.MAX_FINITE = 1.7976931348623157e+308;
      super();
    }
    static parse(source, onError) {}
  }

  class Duration {
    constructor(opt$) {
      let days = opt$.days === undefined ? 0 : opt$.days;
      let hours = opt$.hours === undefined ? 0 : opt$.hours;
      let minutes = opt$.minutes === undefined ? 0 : opt$.minutes;
      let seconds = opt$.seconds === undefined ? 0 : opt$.seconds;
      let milliseconds = opt$.milliseconds === undefined ? 0 : opt$.milliseconds;
      let microseconds = opt$.microseconds === undefined ? 0 : opt$.microseconds;
      Duration.call(this, days * MICROSECONDS_PER_DAY + hours * MICROSECONDS_PER_HOUR + minutes * MICROSECONDS_PER_MINUTE + seconds * MICROSECONDS_PER_SECOND + milliseconds * MICROSECONDS_PER_MILLISECOND + microseconds);
    }
    __init__microseconds(_duration) {
      this._duration = _duration;
      this.MICROSECONDS_PER_MILLISECOND = 1000;
      this.MILLISECONDS_PER_SECOND = 1000;
      this.SECONDS_PER_MINUTE = 60;
      this.MINUTES_PER_HOUR = 60;
      this.HOURS_PER_DAY = 24;
      this.MICROSECONDS_PER_SECOND = MICROSECONDS_PER_MILLISECOND * MILLISECONDS_PER_SECOND;
      this.MICROSECONDS_PER_MINUTE = MICROSECONDS_PER_SECOND * SECONDS_PER_MINUTE;
      this.MICROSECONDS_PER_HOUR = MICROSECONDS_PER_MINUTE * MINUTES_PER_HOUR;
      this.MICROSECONDS_PER_DAY = MICROSECONDS_PER_HOUR * HOURS_PER_DAY;
      this.MILLISECONDS_PER_MINUTE = MILLISECONDS_PER_SECOND * SECONDS_PER_MINUTE;
      this.MILLISECONDS_PER_HOUR = MILLISECONDS_PER_MINUTE * MINUTES_PER_HOUR;
      this.MILLISECONDS_PER_DAY = MILLISECONDS_PER_HOUR * HOURS_PER_DAY;
      this.SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR;
      this.SECONDS_PER_DAY = SECONDS_PER_HOUR * HOURS_PER_DAY;
      this.MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;
      this.ZERO = new Duration(/* Unimplemented NamedExpression: seconds: 0 */);
    }
    +(other) {
      return new Duration.this._microseconds(this._duration + other._duration);
    }
    -(other) {
      return new Duration.this._microseconds(this._duration - other._duration);
    }
    *(factor) {
      return new Duration.this._microseconds((this._duration * factor).round());
    }
    ~/(quotient) {
      if (quotient === 0) throw new IntegerDivisionByZeroException();
      return new Duration.this._microseconds((this._duration / quotient).truncate());
    }
    <(other) { return this._duration < other._duration; }
    >(other) { return this._duration > other._duration; }
    <=(other) { return this._duration <= other._duration; }
    >=(other) { return this._duration >= other._duration; }
    get inDays() { return (this._duration / Duration.MICROSECONDS_PER_DAY).truncate(); }
    get inHours() { return (this._duration / Duration.MICROSECONDS_PER_HOUR).truncate(); }
    get inMinutes() { return (this._duration / Duration.MICROSECONDS_PER_MINUTE).truncate(); }
    get inSeconds() { return (this._duration / Duration.MICROSECONDS_PER_SECOND).truncate(); }
    get inMilliseconds() { return (this._duration / Duration.MICROSECONDS_PER_MILLISECOND).truncate(); }
    get inMicroseconds() { return this._duration; }
    ==(other) {
      if (/* Unimplemented IsExpression: other is! Duration */) return false;
      return this._duration === dart.dload(other, "_duration");
    }
    get hashCode() { return this._duration.hashCode; }
    compareTo(other) { return this._duration.compareTo(other._duration); }
    toString() {
      // Function sixDigits: (int) → String
      function sixDigits(n) {
        if (n >= 100000) return "" + (n) + "";
        if (n >= 10000) return "0" + (n) + "";
        if (n >= 1000) return "00" + (n) + "";
        if (n >= 100) return "000" + (n) + "";
        if (n >= 10) return "0000" + (n) + "";
        return "00000" + (n) + "";
      }
      // Function twoDigits: (int) → String
      function twoDigits(n) {
        if (n >= 10) return "" + (n) + "";
        return "0" + (n) + "";
      }
      if (this.inMicroseconds < 0) {
        return "-" + (/* Unimplemented postfix operator: -this */) + "";
      }
      let twoDigitMinutes = twoDigits(dart.notNull(this.inMinutes.remainder(MINUTES_PER_HOUR)));
      let twoDigitSeconds = twoDigits(dart.notNull(this.inSeconds.remainder(SECONDS_PER_MINUTE)));
      let sixDigitUs = sixDigits(dart.notNull(this.inMicroseconds.remainder(MICROSECONDS_PER_SECOND)));
      return "" + (this.inHours) + ":" + (twoDigitMinutes) + ":" + (twoDigitSeconds) + "." + (sixDigitUs) + "";
    }
    get isNegative() { return this._duration < 0; }
    abs() { return new Duration.this._microseconds(this._duration.abs()); }
    -() { return new Duration.this._microseconds(-this._duration); }
  }
  Duration._microseconds = function(_duration) { this.__init__microseconds(_duration) };
  Duration._microseconds.prototype = Duration.prototype;

  class Error {
    constructor() {
    }
    static safeToString(object) {
      if (/* Unimplemented IsExpression: object is num */ || /* Unimplemented IsExpression: object is bool */ || null === object) {
        return object.toString();
      }
      if (/* Unimplemented IsExpression: object is String */) {
        return _stringToSafeString(/* Unimplemented: DownCast: Object to String */ object);
      }
      return _objectToString(object);
    }
    static _stringToSafeString(string) {}
    static _objectToString(object) {}
    get stackTrace() {}
  }

  class AssertionError extends Error {
  }

  class TypeError extends AssertionError {
  }

  class CastError extends Error {
  }

  class NullThrownError extends Error {
    toString() { return "Throw of null."; }
  }

  class ArgumentError extends Error {
    constructor(message) {
      if (message === undefined) message = null;
      this.message = message;
      this.invalidValue = null;
      this._hasValue = false;
      this.name = null;
      super();
    }
    __init_value(value, name, message) {
      if (name === undefined) name = null;
      if (message === undefined) message = "Invalid argument";
      this.name = name;
      this.message = message;
      this.invalidValue = value;
      this._hasValue = true;
      Error.call(this);
    }
    __init_notNull(name) {
      if (name === undefined) name = null;
      notNull.call(this, null, name, "Must not be null");
    }
    toString() {
      if (!this._hasValue) {
        let result = "Invalid arguments(s)";
        if (this.message !== null) {
          result = "" + (result) + ": " + (this.message) + "";
        }
        return result;
      }
      let nameString = "";
      if (this.name !== null) {
        nameString = " (" + (this.name) + ")";
      }
      return "" + (this.message) + "" + (nameString) + ": " + (Error.safeToString(this.invalidValue)) + "";
    }
  }
  ArgumentError.value = function(value, name, message) { this.__init_value(value, name, message) };
  ArgumentError.value.prototype = ArgumentError.prototype;
  ArgumentError.notNull = function(name) { this.__init_notNull(name) };
  ArgumentError.notNull.prototype = ArgumentError.prototype;

  class RangeError extends ArgumentError {
    constructor(message) {
      this.start = null;
      this.end = null;
      super(message);
    }
    __init_value(value, name, message) {
      if (name === undefined) name = null;
      if (message === undefined) message = null;
      this.start = null;
      this.end = null;
      super.__init_value(value, name, (message !== null) ? message : "Value not in range");
    }
    __init_range(invalidValue, minValue, maxValue, name, message) {
      if (name === undefined) name = null;
      if (message === undefined) message = null;
      this.start = minValue;
      this.end = maxValue;
      super.__init_value(invalidValue, name, (message !== null) ? message : "Invalid value");
    }
    __init_index(index, indexable, name, message, length) {
      return new IndexError(index, indexable, name, message, length);
    }
    static checkValueInInterval(value, minValue, maxValue, name, message) {
      if (name === undefined) name = null;
      if (message === undefined) message = null;
      if (value < minValue || value > maxValue) {
        throw new RangeError.this.range(value, minValue, maxValue, name, message);
      }
    }
    static checkValidIndex(index, indexable, name, length, message) {
      if (name === undefined) name = null;
      if (length === undefined) length = null;
      if (message === undefined) message = null;
      if (length === null) length = /* Unimplemented: DownCast: dynamic to int */ dart.dload(indexable, "length");
      if (index < 0 || index >= length) {
        if (name === null) name = "index";
        throw new RangeError.this.index(index, indexable, name, message, length);
      }
    }
    static checkValidRange(start, end, length, startName, endName, message) {
      if (startName === undefined) startName = null;
      if (endName === undefined) endName = null;
      if (message === undefined) message = null;
      if (start < 0 || start > length) {
        if (startName === null) startName = "start";
        throw new RangeError.this.range(start, 0, length, startName, message);
      }
      if (end !== null && (end < start || end > length)) {
        if (endName === null) endName = "end";
        throw new RangeError.this.range(end, start, length, endName, message);
      }
    }
    static checkNotNegative(value, name, message) {
      if (name === undefined) name = null;
      if (message === undefined) message = null;
      if (value < 0) throw new RangeError.this.range(value, 0, null, name, message);
    }
    toString() {
      if (!_hasValue) return "RangeError: " + (message) + "";
      let value = Error.safeToString(invalidValue);
      let explanation = "";
      if (this.start === null) {
        if (this.end !== null) {
          explanation = ": Not less than or equal to " + (this.end) + "";
        }
      }
       else if (this.end === null) {
        explanation = ": Not greater than or equal to " + (this.start) + "";
      }
       else if (this.end > this.start) {
        explanation = ": Not in range " + (this.start) + ".." + (this.end) + ", inclusive.";
      }
       else if (this.end < this.start) {
        explanation = ": Valid value range is empty";
      }
       else {
        explanation = ": Only valid value is " + (this.start) + "";
      }
      return "RangeError: " + (message) + " (" + (value) + ")" + (explanation) + "";
    }
  }
  RangeError.value = function(value, name, message) { this.__init_value(value, name, message) };
  RangeError.value.prototype = RangeError.prototype;
  RangeError.range = function(invalidValue, minValue, maxValue, name, message) { this.__init_range(invalidValue, minValue, maxValue, name, message) };
  RangeError.range.prototype = RangeError.prototype;
  RangeError.index = function(index, indexable, name, message, length) { this.__init_index(index, indexable, name, message, length) };
  RangeError.index.prototype = RangeError.prototype;

  class IndexError extends ArgumentError {
    constructor(invalidValue, indexable, name, message, length) {
      if (name === undefined) name = null;
      if (message === undefined) message = null;
      if (length === undefined) length = null;
      this.indexable = indexable;
      this.length = (length !== null) ? length : dart.dload(indexable, "length");
      super.__init_value(invalidValue, name, (message !== null) ? message : "Index out of range");
    }
    get start() { return 0; }
    get end() { return this.length - 1; }
    toString() {
      dart.assert(_hasValue);
      let target = Error.safeToString(this.indexable);
      let explanation = "index should be less than " + (this.length) + "";
      if (/* Unimplemented binary operator: invalidValue < 0 */) {
        explanation = "index must not be negative";
      }
      return "RangeError: " + (message) + " (" + (target) + "[" + (invalidValue) + "]): " + (explanation) + "";
    }
  }

  class FallThroughError extends Error {
    constructor() {
      super();
    }
  }

  class AbstractClassInstantiationError extends Error {
    constructor(_className) {
      this._className = _className;
      super();
    }
    toString() { return "Cannot instantiate abstract class: '" + (this._className) + "'"; }
  }

  class NoSuchMethodError extends Error {
    constructor(receiver, memberName, positionalArguments, namedArguments, existingArgumentNames) {
      if (existingArgumentNames === undefined) existingArgumentNames = null;
      this._receiver = receiver;
      this._memberName = memberName;
      this._arguments = positionalArguments;
      this._namedArguments = namedArguments;
      this._existingArgumentNames = existingArgumentNames;
      super();
    }
    toString() {}
  }

  class UnsupportedError extends Error {
    constructor(message) {
      this.message = message;
      super();
    }
    toString() { return "Unsupported operation: " + (this.message) + ""; }
  }

  class UnimplementedError extends Error {
    constructor(message) {
      if (message === undefined) message = null;
      this.message = message;
      super();
    }
    toString() { return (this.message !== null ? "UnimplementedError: " + (this.message) + "" : "UnimplementedError"); }
  }

  class StateError extends Error {
    constructor(message) {
      this.message = message;
      super();
    }
    toString() { return "Bad state: " + (this.message) + ""; }
  }

  class ConcurrentModificationError extends Error {
    constructor(modifiedObject) {
      if (modifiedObject === undefined) modifiedObject = null;
      this.modifiedObject = modifiedObject;
      super();
    }
    toString() {
      if (this.modifiedObject === null) {
        return "Concurrent modification during iteration.";
      }
      return "Concurrent modification during iteration: " + "" + (Error.safeToString(this.modifiedObject)) + ".";
    }
  }

  class OutOfMemoryError {
    constructor() {
    }
    toString() { return "Out of Memory"; }
    get stackTrace() { return null; }
  }

  class StackOverflowError {
    constructor() {
    }
    toString() { return "Stack Overflow"; }
    get stackTrace() { return null; }
  }

  class CyclicInitializationError extends Error {
    constructor(variableName) {
      if (variableName === undefined) variableName = null;
      this.variableName = variableName;
      super();
    }
    toString() { return this.variableName === null ? "Reading static variable during its initialization" : "Reading static variable '" + (this.variableName) + "' during its initialization"; }
  }

  class Exception {
    constructor(message) {
      if (message === undefined) message = null;
      return new _ExceptionImplementation(message);
    }
  }

  class _ExceptionImplementation {
    constructor(message) {
      if (message === undefined) message = null;
      this.message = message;
    }
    toString() {
      if (this.message === null) return "Exception";
      return "Exception: " + (this.message) + "";
    }
  }

  class FormatException {
    constructor(message, source, offset) {
      if (message === undefined) message = "";
      if (source === undefined) source = null;
      if (offset === undefined) offset = null;
      this.message = message;
      this.source = source;
      this.offset = offset;
    }
    toString() {
      let report = "FormatException";
      if (this.message !== null && !dart.equals("", this.message)) {
        report = "" + (report) + ": " + (this.message) + "";
      }
      let offset = this.offset;
      if (/* Unimplemented IsExpression: source is! String */) {
        if (offset !== null) {
          report = " (at offset " + (offset) + ")";
        }
        return report;
      }
      if (offset !== null && (offset < 0 || /* Unimplemented binary operator: offset > source.length */)) {
        offset = null;
      }
      if (offset === null) {
        let source = /* Unimplemented: DownCast: dynamic to String */ this.source;
        if (source.length > 78) {
          source = /* Unimplemented binary operator: source.substring(0, 75) + "..." */;
        }
        return "" + (report) + "
        " + (source) + "";
      }
      let lineNum = 1;
      let lineStart = 0;
      let lastWasCR = null;
      for (let i = 0; i < offset; i++) {
        let char = /* Unimplemented: DownCast: dynamic to int */ /* Unimplemented dynamic method call: source.codeUnitAt(i) */;
        if (char === 10) {
          if (lineStart !== i || !lastWasCR) {
            lineNum++;
          }
          lineStart = i + 1;
          lastWasCR = false;
        }
         else if (char === 13) {
          lineNum++;
          lineStart = i + 1;
          lastWasCR = true;
        }
      }
      if (lineNum > 1) {
        report = " (at line " + (lineNum) + ", character " + (offset - lineStart + 1) + ")
        ";
      }
       else {
        report = " (at character " + (offset + 1) + ")
        ";
      }
      let lineEnd = /* Unimplemented: DownCast: dynamic to int */ dart.dload(this.source, "length");
      for (let i = offset; /* Unimplemented binary operator: i < source.length */; i++) {
        let char = /* Unimplemented: DownCast: dynamic to int */ /* Unimplemented dynamic method call: source.codeUnitAt(i) */;
        if (char === 10 || char === 13) {
          lineEnd = i;
          /* Unimplemented BreakStatement: break; */}
      }
      let length = lineEnd - lineStart;
      let start = lineStart;
      let end = lineEnd;
      let prefix = "";
      let postfix = "";
      if (length > 78) {
        let index = offset - lineStart;
        if (index < 75) {
          end = start + 75;
          postfix = "...";
        }
         else if (end - offset < 75) {
          start = end - 75;
          prefix = "...";
        }
         else {
          start = offset - 36;
          end = offset + 36;
          prefix = postfix = "...";
        }
      }
      let slice = /* Unimplemented: DownCast: dynamic to String */ /* Unimplemented dynamic method call: source.substring(start, end) */;
      let markOffset = offset - start + prefix.length;
      return "" + (report) + "" + (prefix) + "" + (slice) + "" + (postfix) + "
      " + (/* Unimplemented binary operator: " " * markOffset */) + "^
      ";
    }
  }

  class IntegerDivisionByZeroException {
    constructor() {
    }
    toString() { return "IntegerDivisionByZeroException"; }
  }

  class Expando/* Unimplemented <T> */ {
    constructor(name) {
      if (name === undefined) name = null;
      this.name = null;
    }
    toString() { return "Expando:" + (this.name) + ""; }
    [](object) {}
    []=(object, value) {}
  }

  class Function {
    static apply(function, positionalArguments, namedArguments) {}
  }

  // Function identical: (Object, Object) → bool
  function identical(a, b) {}

  // Function identityHashCode: (Object) → int
  function identityHashCode(object) {}

  class int extends num {
    __init_fromEnvironment(name, opt$) {
      let defaultValue = opt$.defaultValue === undefined ? null : opt$.defaultValue;
    }
    static parse(source, opt$) {}
  }
  int.fromEnvironment = function(name, opt$) { this.__init_fromEnvironment(name, opt$) };
  int.fromEnvironment.prototype = int.prototype;

  class Invocation {
    get isAccessor() { return this.isGetter || this.isSetter; }
  }

  class Iterable/* Unimplemented <E> */ {
    constructor() {
    }
    __init_generate(count, generator) {
      if (generator === undefined) generator = null;
      if (count <= 0) return new _internal.EmptyIterable();
      return new _GeneratorIterable(count, generator);
    }
    join(separator) {
      if (separator === undefined) separator = "";
      let buffer = new StringBuffer();
      buffer.writeAll(this, separator);
      return buffer.toString();
    }
  }
  Iterable.generate = function(count, generator) { this.__init_generate(count, generator) };
  Iterable.generate.prototype = Iterable.prototype;

  class _GeneratorIterable/* Unimplemented <E> */ extends collection.IterableBase/* Unimplemented <E> */ {
    constructor(_end, /* Unimplemented FunctionTypedFormalParameter: E generator(int n) */) {
      this._end = _end;
      this._start = 0;
      this._generator = (generator !== null) ? generator : _id;
      super();
    }
    __init_slice(_start, _end, _generator) {
      this._start = _start;
      this._end = _end;
      this._generator = _generator;
      collection.IterableBase.call(this);
    }
    get iterator() { return new _GeneratorIterator(this._start, this._end, this._generator); }
    get length() { return this._end - this._start; }
    skip(count) {
      RangeError.checkNotNegative(count, "count");
      if (count === 0) return this;
      let newStart = this._start + count;
      if (newStart >= this._end) return new _internal.EmptyIterable();
      return new _GeneratorIterable.this.slice(newStart, this._end, this._generator);
    }
    take(count) {
      RangeError.checkNotNegative(count, "count");
      if (count === 0) return new _internal.EmptyIterable();
      let newEnd = this._start + count;
      if (newEnd >= this._end) return this;
      return new _GeneratorIterable.this.slice(this._start, newEnd, this._generator);
    }
    static _id(n) { return n; }
  }
  _GeneratorIterable.slice = function(_start, _end, _generator) { this.__init_slice(_start, _end, _generator) };
  _GeneratorIterable.slice.prototype = _GeneratorIterable.prototype;

  class _GeneratorIterator/* Unimplemented <E> */ {
    constructor(_index, _end, _generator) {
      this._index = _index;
      this._end = _end;
      this._generator = _generator;
      this._current = null;
    }
    moveNext() {
      if (this._index < this._end) {
        this._current = this._generator(this._index);
        this._index++;
        return true;
      }
       else {
        this._current = null;
        return false;
      }
    }
    get current() { return this._current; }
  }

  class BidirectionalIterator/* Unimplemented <E> */ {
  }

  class Iterator/* Unimplemented <E> */ {
  }

  class List/* Unimplemented <E> */ {
    constructor(length) {
      if (length === undefined) length = null;
    }
    __init_filled(length, fill) {
    }
    __init_from(elements, opt$) {
      let growable = opt$.growable === undefined ? true : opt$.growable;
    }
    __init_generate(length, /* Unimplemented FunctionTypedFormalParameter: E generator(int index) */, opt$) {
      let growable = opt$.growable === undefined ? true : opt$.growable;
      let result = null;
      if (growable) {
        result = /* Unimplemented cascade on non-simple identifier: <E> []..length = length */;
      }
       else {
        result = new List(length);
      }
      for (let i = 0; i < length; i++) {
        result[i] = generator(i);
      }
      return result;
    }
  }
  List.filled = function(length, fill) { this.__init_filled(length, fill) };
  List.filled.prototype = List.prototype;
  List.from = function(elements, opt$) { this.__init_from(elements, opt$) };
  List.from.prototype = List.prototype;
  List.generate = function(length, /* Unimplemented FunctionTypedFormalParameter: E generator(int index) */, opt$) { this.__init_generate(length, /* Unimplemented FunctionTypedFormalParameter: E generator(int index) */, opt$) };
  List.generate.prototype = List.prototype;

  class Map/* Unimplemented <K, V> */ {
    constructor() {
      return new collection.LinkedHashMap();
    }
    __init_from(other) {
      return new collection.LinkedHashMap.from(other);
    }
    __init_identity() {
      return new collection.LinkedHashMap.identity();
    }
    __init_fromIterable(iterable, opt$) {
      return new collection.LinkedHashMap.fromIterable(iterable, opt$);
    }
    __init_fromIterables(keys, values) {
      return new collection.LinkedHashMap.fromIterables(keys, values);
    }
  }
  Map.from = function(other) { this.__init_from(other) };
  Map.from.prototype = Map.prototype;
  Map.identity = function() { this.__init_identity() };
  Map.identity.prototype = Map.prototype;
  Map.fromIterable = function(iterable, opt$) { this.__init_fromIterable(iterable, opt$) };
  Map.fromIterable.prototype = Map.prototype;
  Map.fromIterables = function(keys, values) { this.__init_fromIterables(keys, values) };
  Map.fromIterables.prototype = Map.prototype;

  class Null {
    __init__uninstantiable() {
      throw new UnsupportedError("class Null cannot be instantiated");
    }
    toString() { return "null"; }
  }
  Null._uninstantiable = function() { this.__init__uninstantiable() };
  Null._uninstantiable.prototype = Null.prototype;

  class num {
    static parse(input, onError) {
      if (onError === undefined) onError = null;
      let source = input.trim();
      let result = int.parse(source, /* Unimplemented: ClosureWrap: (dynamic) → dynamic to (String) → int */ /* Unimplemented NamedExpression: onError: _returnNull */);
      if (result !== null) return result;
      result = double.parse(source, /* Unimplemented: ClosureWrap: (dynamic) → dynamic to (String) → double */ _returnNull);
      if (result !== null) return result;
      if (onError === null) throw new FormatException(input);
      return onError(input);
    }
    static _returnNull(_) { return null; }
  }

  class Object {
    constructor() {
    }
    ==(other) { return identical(this, other); }
    get hashCode() {}
    toString() {}
    noSuchMethod(invocation) {}
    get runtimeType() {}
  }

  class Pattern {
  }

  // Function print: (Object) → void
  function print(object) {
    let line = "" + (object) + "";
    if (_internal.printToZone === null) {
      _internal.printToConsole(line);
    }
     else {
      /* Unimplemented dynamic method call: printToZone(line) */;
    }
  }

  class Match {
  }

  class RegExp {
    constructor(source, opt$) {
      let multiLine = opt$.multiLine === undefined ? false : opt$.multiLine;
      let caseSensitive = opt$.caseSensitive === undefined ? true : opt$.caseSensitive;
    }
  }

  class Set/* Unimplemented <E> */ extends collection.IterableBase/* Unimplemented <E> */ {
    constructor() {
      return new collection.LinkedHashSet();
    }
    __init_identity() {
      return new collection.LinkedHashSet.identity();
    }
    __init_from(elements) {
      return new collection.LinkedHashSet.from(elements);
    }
  }
  Set.identity = function() { this.__init_identity() };
  Set.identity.prototype = Set.prototype;
  Set.from = function(elements) { this.__init_from(elements) };
  Set.from.prototype = Set.prototype;

  class Sink/* Unimplemented <T> */ {
  }

  class StackTrace {
  }

  class Stopwatch {
    get frequency() { return _frequency; }
    constructor() {
      this._start = null;
      this._stop = null;
      this._frequency = null;
      _initTicker();
    }
    start() {
      if (this.isRunning) return;
      if (this._start === null) {
        this._start = _now();
      }
       else {
        this._start = _now() - (this._stop - this._start);
        this._stop = null;
      }
    }
    stop() {
      if (!this.isRunning) return;
      this._stop = _now();
    }
    reset() {
      if (this._start === null) return;
      this._start = _now();
      if (this._stop !== null) {
        this._stop = this._start;
      }
    }
    get elapsedTicks() {
      if (this._start === null) {
        return 0;
      }
      return (this._stop === null) ? (_now() - this._start) : (this._stop - this._start);
    }
    get elapsed() {
      return new Duration(/* Unimplemented NamedExpression: microseconds: elapsedMicroseconds */);
    }
    get elapsedMicroseconds() {
      return ((this.elapsedTicks * 1000000) / this.frequency).truncate();
    }
    get elapsedMilliseconds() {
      return ((this.elapsedTicks * 1000) / this.frequency).truncate();
    }
    get isRunning() { return this._start !== null && this._stop === null; }
    static _initTicker() {}
    static _now() {}
  }

  class String {
    __init_fromCharCodes(charCodes, start, end) {
      if (start === undefined) start = 0;
      if (end === undefined) end = null;
    }
    __init_fromCharCode(charCode) {
    }
    __init_fromEnvironment(name, opt$) {
      let defaultValue = opt$.defaultValue === undefined ? null : opt$.defaultValue;
    }
  }
  String.fromCharCodes = function(charCodes, start, end) { this.__init_fromCharCodes(charCodes, start, end) };
  String.fromCharCodes.prototype = String.prototype;
  String.fromCharCode = function(charCode) { this.__init_fromCharCode(charCode) };
  String.fromCharCode.prototype = String.prototype;
  String.fromEnvironment = function(name, opt$) { this.__init_fromEnvironment(name, opt$) };
  String.fromEnvironment.prototype = String.prototype;

  class Runes extends collection.IterableBase/* Unimplemented <int> */ {
    constructor(string) {
      this.string = string;
      super();
    }
    get iterator() { return new RuneIterator(this.string); }
    get last() {
      if (this.string.length === 0) {
        throw new StateError("No elements.");
      }
      let length = this.string.length;
      let code = this.string.codeUnitAt(length - 1);
      if (_isTrailSurrogate(code) && this.string.length > 1) {
        let previousCode = this.string.codeUnitAt(length - 2);
        if (_isLeadSurrogate(previousCode)) {
          return _combineSurrogatePair(previousCode, code);
        }
      }
      return code;
    }
  }

  // Function _isLeadSurrogate: (int) → bool
  function _isLeadSurrogate(code) { return (code & 64512) === 55296; }

  // Function _isTrailSurrogate: (int) → bool
  function _isTrailSurrogate(code) { return (code & 64512) === 56320; }

  // Function _combineSurrogatePair: (int, int) → int
  function _combineSurrogatePair(start, end) {
    return 65536 + ((start & 1023) << 10) + (end & 1023);
  }

  class RuneIterator {
    constructor(string) {
      this.string = string;
      this._position = 0;
      this._nextPosition = 0;
      this._currentCodePoint = null;
    }
    __init_at(string, index) {
      this.string = string;
      this._position = index;
      this._nextPosition = index;
      this._currentCodePoint = null;
      RangeError.checkValueInInterval(index, 0, string.length);
      this._checkSplitSurrogate(index);
    }
    _checkSplitSurrogate(index) {
      if (index > 0 && index < this.string.length && _isLeadSurrogate(this.string.codeUnitAt(index - 1)) && _isTrailSurrogate(this.string.codeUnitAt(index))) {
        throw new ArgumentError("Index inside surrogate pair: " + (index) + "");
      }
    }
    get rawIndex() { return /* Unimplemented: DownCast: dynamic to int */ (this._position !== this._nextPosition) ? this._position : null; }
    set rawIndex(rawIndex) {
      RangeError.checkValidIndex(rawIndex, this.string, "rawIndex");
      this.reset(rawIndex);
      this.moveNext();
    }
    reset(rawIndex) {
      if (rawIndex === undefined) rawIndex = 0;
      RangeError.checkValueInInterval(rawIndex, 0, this.string.length, "rawIndex");
      this._checkSplitSurrogate(rawIndex);
      this._position = this._nextPosition = rawIndex;
      this._currentCodePoint = null;
    }
    get current() { return this._currentCodePoint; }
    get currentSize() { return this._nextPosition - this._position; }
    get currentAsString() {
      if (this._position === this._nextPosition) return null;
      if (this._position + 1 === this._nextPosition) return this.string[this._position];
      return this.string.substring(this._position, this._nextPosition);
    }
    moveNext() {
      this._position = this._nextPosition;
      if (this._position === this.string.length) {
        this._currentCodePoint = null;
        return false;
      }
      let codeUnit = this.string.codeUnitAt(this._position);
      let nextPosition = this._position + 1;
      if (_isLeadSurrogate(codeUnit) && nextPosition < this.string.length) {
        let nextCodeUnit = this.string.codeUnitAt(nextPosition);
        if (_isTrailSurrogate(nextCodeUnit)) {
          this._nextPosition = nextPosition + 1;
          this._currentCodePoint = _combineSurrogatePair(codeUnit, nextCodeUnit);
          return true;
        }
      }
      this._nextPosition = nextPosition;
      this._currentCodePoint = codeUnit;
      return true;
    }
    movePrevious() {
      this._nextPosition = this._position;
      if (this._position === 0) {
        this._currentCodePoint = null;
        return false;
      }
      let position = this._position - 1;
      let codeUnit = this.string.codeUnitAt(position);
      if (_isTrailSurrogate(codeUnit) && position > 0) {
        let prevCodeUnit = this.string.codeUnitAt(position - 1);
        if (_isLeadSurrogate(prevCodeUnit)) {
          this._position = position - 1;
          this._currentCodePoint = _combineSurrogatePair(prevCodeUnit, codeUnit);
          return true;
        }
      }
      this._position = position;
      this._currentCodePoint = codeUnit;
      return true;
    }
  }
  RuneIterator.at = function(string, index) { this.__init_at(string, index) };
  RuneIterator.at.prototype = RuneIterator.prototype;

  class StringBuffer {
    constructor(content) {
      if (content === undefined) content = "";
    }
    get length() {}
    get isEmpty() { return this.length === 0; }
    get isNotEmpty() { return !this.isEmpty; }
    write(obj) {}
    writeCharCode(charCode) {}
    writeAll(objects, separator) {
      if (separator === undefined) separator = "";
      let iterator = objects.iterator;
      if (!iterator.moveNext()) return;
      if (separator.isEmpty) {
        do {
          this.write(iterator.current);
        }
        while (iterator.moveNext());
      }
       else {
        this.write(iterator.current);
        while (iterator.moveNext()) {
          this.write(separator);
          this.write(iterator.current);
        }
      }
    }
    writeln(obj) {
      if (obj === undefined) obj = "";
      this.write(obj);
      this.write("
      ");
    }
    clear() {}
    toString() {}
  }

  class StringSink {
  }

  class Symbol {
    constructor(name) {
      return new _internal.Symbol(name);
    }
  }

  class Type {
  }

  class Uri {
    get authority() {
      if (!this.hasAuthority) return "";
      let sb = new StringBuffer();
      this._writeAuthority(sb);
      return sb.toString();
    }
    get userInfo() { return this._userInfo; }
    get host() {
      if (this._host === null) return "";
      if (this._host.startsWith("[")) {
        return this._host.substring(1, this._host.length - 1);
      }
      return this._host;
    }
    get port() {
      if (this._port === null) return _defaultPort(this.scheme);
      return this._port;
    }
    static _defaultPort(scheme) {
      if (dart.equals(scheme, "http")) return 80;
      if (dart.equals(scheme, "https")) return 443;
      return 0;
    }
    get path() { return this._path; }
    get query() { return (this._query === null) ? "" : this._query; }
    get fragment() { return (this._fragment === null) ? "" : this._fragment; }
    static parse(uri) {
      // Function isRegName: (int) → bool
      function isRegName(ch) {
        return ch < 128 && (!dart.equals((/* Unimplemented binary operator: _regNameTable[ch >> 4] & (1 << (ch & 0x0f)) */), 0));
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
        if (index === uri.length) {
          char = EOI;
          return;
        }
        let authStart = index;
        let lastColon = -1;
        let lastAt = -1;
        char = uri.codeUnitAt(index);
        while (index < uri.length) {
          char = uri.codeUnitAt(index);
          if (char === _SLASH || char === _QUESTION || char === _NUMBER_SIGN) {
            /* Unimplemented BreakStatement: break; */}
          if (char === _AT_SIGN) {
            lastAt = index;
            lastColon = -1;
          }
           else if (char === _COLON) {
            lastColon = index;
          }
           else if (char === _LEFT_BRACKET) {
            lastColon = -1;
            let endBracket = uri.indexOf("]", index + 1);
            if (endBracket === -1) {
              index = uri.length;
              char = EOI;
              /* Unimplemented BreakStatement: break; */}
             else {
              index = endBracket;
            }
          }
          index++;
          char = EOI;
        }
        let hostStart = authStart;
        let hostEnd = index;
        if (lastAt >= 0) {
          userinfo = _makeUserInfo(uri, authStart, lastAt);
          hostStart = lastAt + 1;
        }
        if (lastColon >= 0) {
          let portNumber = null;
          if (lastColon + 1 < index) {
            portNumber = 0;
            for (let i = lastColon + 1; i < index; i++) {
              let digit = uri.codeUnitAt(i);
              if (_ZERO > digit || _NINE < digit) {
                _fail(uri, i, "Invalid port number");
              }
              portNumber = portNumber * 10 + (digit - _ZERO);
            }
          }
          port = _makePort(portNumber, scheme);
          hostEnd = lastColon;
        }
        host = _makeHost(uri, hostStart, hostEnd, true);
        if (index < uri.length) {
          char = uri.codeUnitAt(index);
        }
      }
      let NOT_IN_PATH = 0;
      let IN_PATH = 1;
      let ALLOW_AUTH = 2;
      let state = NOT_IN_PATH;
      let i = index;
      while (i < uri.length) {
        char = uri.codeUnitAt(i);
        if (char === _QUESTION || char === _NUMBER_SIGN) {
          state = NOT_IN_PATH;
          /* Unimplemented BreakStatement: break; */}
        if (char === _SLASH) {
          state = (i === 0) ? ALLOW_AUTH : IN_PATH;
          /* Unimplemented BreakStatement: break; */}
        if (char === _COLON) {
          if (i === 0) _fail(uri, 0, "Invalid empty scheme");
          scheme = _makeScheme(uri, i);
          i++;
          pathStart = i;
          if (i === uri.length) {
            char = EOI;
            state = NOT_IN_PATH;
          }
           else {
            char = uri.codeUnitAt(i);
            if (char === _QUESTION || char === _NUMBER_SIGN) {
              state = NOT_IN_PATH;
            }
             else if (char === _SLASH) {
              state = ALLOW_AUTH;
            }
             else {
              state = IN_PATH;
            }
          }
          /* Unimplemented BreakStatement: break; */}
        i++;
        char = EOI;
      }
      index = i;
      if (state === ALLOW_AUTH) {
        dart.assert(char === _SLASH);
        index++;
        if (index === uri.length) {
          char = EOI;
          state = NOT_IN_PATH;
        }
         else {
          char = uri.codeUnitAt(index);
          if (char === _SLASH) {
            index++;
            parseAuth();
            pathStart = index;
          }
          if (char === _QUESTION || char === _NUMBER_SIGN || char === EOI) {
            state = NOT_IN_PATH;
          }
           else {
            state = IN_PATH;
          }
        }
      }
      dart.assert(state === IN_PATH || state === NOT_IN_PATH);
      if (state === IN_PATH) {
        while (++index < uri.length) {
          char = uri.codeUnitAt(index);
          if (char === _QUESTION || char === _NUMBER_SIGN) {
            /* Unimplemented BreakStatement: break; */}
          char = EOI;
        }
        state = NOT_IN_PATH;
      }
      dart.assert(state === NOT_IN_PATH);
      let isFile = (dart.equals(scheme, "file"));
      let ensureLeadingSlash = host !== null;
      path = _makePath(uri, pathStart, index, null, ensureLeadingSlash, isFile);
      if (char === _QUESTION) {
        let numberSignIndex = uri.indexOf("#", index + 1);
        if (numberSignIndex < 0) {
          query = _makeQuery(uri, index + 1, uri.length, null);
        }
         else {
          query = _makeQuery(uri, index + 1, numberSignIndex, null);
          fragment = _makeFragment(uri, numberSignIndex + 1, uri.length);
        }
      }
       else if (char === _NUMBER_SIGN) {
        fragment = _makeFragment(uri, index + 1, uri.length);
      }
      return new Uri.this._internal(scheme, userinfo, host, port, path, query, fragment);
    }
    static _fail(uri, index, message) {
      throw new FormatException(message, uri, index);
    }
    __init__internal(scheme, _userInfo, _host, _port, _path, _query, _fragment) {
      this.scheme = scheme;
      this._userInfo = _userInfo;
      this._host = _host;
      this._port = _port;
      this._path = _path;
      this._query = _query;
      this._fragment = _fragment;
      this._pathSegments = null;
      this._queryParameters = null;
      this._SPACE = 32;
      this._DOUBLE_QUOTE = 34;
      this._NUMBER_SIGN = 35;
      this._PERCENT = 37;
      this._ASTERISK = 42;
      this._PLUS = 43;
      this._DOT = 46;
      this._SLASH = 47;
      this._ZERO = 48;
      this._NINE = 57;
      this._COLON = 58;
      this._LESS = 60;
      this._GREATER = 62;
      this._QUESTION = 63;
      this._AT_SIGN = 64;
      this._UPPER_CASE_A = 65;
      this._UPPER_CASE_F = 70;
      this._UPPER_CASE_Z = 90;
      this._LEFT_BRACKET = 91;
      this._BACKSLASH = 92;
      this._RIGHT_BRACKET = 93;
      this._LOWER_CASE_A = 97;
      this._LOWER_CASE_F = 102;
      this._LOWER_CASE_Z = 122;
      this._BAR = 124;
      this._unreservedTable = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 24576, 1023, 65534, 34815, 65534, 18431];
      this._unreserved2396Table = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 26498, 1023, 65534, 34815, 65534, 18431];
      this._encodeFullTable = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 65498, 45055, 65535, 34815, 65534, 18431];
      this._schemeTable = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 26624, 1023, 65534, 2047, 65534, 2047];
      this._schemeLowerTable = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 26624, 1023, 0, 0, 65534, 2047];
      this._subDelimitersTable = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 32722, 11263, 65534, 34815, 65534, 18431];
      this._genDelimitersTable = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 32776, 33792, 1, 10240, 0, 0];
      this._userinfoTable = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 32722, 12287, 65534, 34815, 65534, 18431];
      this._regNameTable = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 32754, 11263, 65534, 34815, 65534, 18431];
      this._pathCharTable = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 32722, 12287, 65535, 34815, 65534, 18431];
      this._pathCharOrSlashTable = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 65490, 12287, 65535, 34815, 65534, 18431];
      this._queryCharTable = /* Unimplemented const *//* Unimplemented ArrayList */[0, 0, 65490, 45055, 65535, 34815, 65534, 18431];
    }
    constructor(opt$) {
      let scheme = opt$.scheme === undefined ? "" : opt$.scheme;
      let userInfo = opt$.userInfo === undefined ? "" : opt$.userInfo;
      let host = opt$.host === undefined ? null : opt$.host;
      let port = opt$.port === undefined ? null : opt$.port;
      let path = opt$.path === undefined ? null : opt$.path;
      let pathSegments = opt$.pathSegments === undefined ? null : opt$.pathSegments;
      let query = opt$.query === undefined ? null : opt$.query;
      let queryParameters = opt$.queryParameters === undefined ? null : opt$.queryParameters;
      let fragment = opt$.fragment === undefined ? null : opt$.fragment;
      scheme = _makeScheme(scheme, _stringOrNullLength(scheme));
      userInfo = _makeUserInfo(userInfo, 0, _stringOrNullLength(userInfo));
      host = _makeHost(host, 0, _stringOrNullLength(host), false);
      if (dart.equals(query, "")) query = null;
      query = _makeQuery(query, 0, _stringOrNullLength(query), queryParameters);
      fragment = _makeFragment(fragment, 0, _stringOrNullLength(fragment));
      port = _makePort(port, scheme);
      let isFile = (dart.equals(scheme, "file"));
      if (host === null && (userInfo.isNotEmpty || port !== null || isFile)) {
        host = "";
      }
      let ensureLeadingSlash = host !== null;
      path = _makePath(path, 0, _stringOrNullLength(path), pathSegments, ensureLeadingSlash, isFile);
      return new Uri.this._internal(scheme, userInfo, host, port, path, query, fragment);
    }
    __init_http(authority, unencodedPath, queryParameters) {
      if (queryParameters === undefined) queryParameters = null;
      return _makeHttpUri("http", authority, unencodedPath, queryParameters);
    }
    __init_https(authority, unencodedPath, queryParameters) {
      if (queryParameters === undefined) queryParameters = null;
      return _makeHttpUri("https", authority, unencodedPath, queryParameters);
    }
    static _makeHttpUri(scheme, authority, unencodedPath, queryParameters) {
      let userInfo = "";
      let host = null;
      let port = null;
      if (authority !== null && authority.isNotEmpty) {
        let hostStart = 0;
        let hasUserInfo = false;
        for (let i = 0; i < authority.length; i++) {
          if (authority.codeUnitAt(i) === _AT_SIGN) {
            hasUserInfo = true;
            userInfo = authority.substring(0, i);
            hostStart = i + 1;
            /* Unimplemented BreakStatement: break; */}
        }
        let hostEnd = hostStart;
        if (hostStart < authority.length && authority.codeUnitAt(hostStart) === _LEFT_BRACKET) {
          for (; hostEnd < authority.length; hostEnd++) {
            if (authority.codeUnitAt(hostEnd) === _RIGHT_BRACKET) /* Unimplemented BreakStatement: break; */}
          if (hostEnd === authority.length) {
            throw new FormatException("Invalid IPv6 host entry.", authority, hostStart);
          }
          parseIPv6Address(authority, hostStart + 1, hostEnd);
          hostEnd++;
          if (hostEnd !== authority.length && authority.codeUnitAt(hostEnd) !== _COLON) {
            throw new FormatException("Invalid end of authority", authority, hostEnd);
          }
        }
        let hasPort = false;
        for (; hostEnd < authority.length; hostEnd++) {
          if (authority.codeUnitAt(hostEnd) === _COLON) {
            let portString = authority.substring(hostEnd + 1);
            if (portString.isNotEmpty) port = int.parse(portString);
            /* Unimplemented BreakStatement: break; */}
        }
        host = authority.substring(hostStart, hostEnd);
      }
      return new Uri(/* Unimplemented NamedExpression: scheme: scheme */, /* Unimplemented NamedExpression: userInfo: userInfo */, /* Unimplemented NamedExpression: host: host */, /* Unimplemented NamedExpression: port: port */, /* Unimplemented NamedExpression: pathSegments: unencodedPath.split("/") */, /* Unimplemented NamedExpression: queryParameters: queryParameters */);
    }
    __init_file(path, opt$) {
      let windows = opt$.windows === undefined ? null : opt$.windows;
      windows = windows === null ? Uri._isWindows : windows;
      return /* Unimplemented: DownCast: dynamic to Uri */ windows ? _makeWindowsFileUrl(path) : _makeFileUri(path);
    }
    static get base() {}
    static get _isWindows() {}
    static _checkNonWindowsPathReservedCharacters(segments, argumentError) {
      segments.forEach((segment) => {
        if (/* Unimplemented dynamic method call: segment.contains("/") */) {
          if (argumentError) {
            throw new ArgumentError("Illegal path character " + (segment) + "");
          }
           else {
            throw new UnsupportedError("Illegal path character " + (segment) + "");
          }
        }
      });
    }
    static _checkWindowsPathReservedCharacters(segments, argumentError, firstSegment) {
      if (firstSegment === undefined) firstSegment = 0;
      segments.skip(firstSegment).forEach((segment) => {
        if (/* Unimplemented dynamic method call: segment.contains(new RegExp(r'["*/:<>?\\|]')) */) {
          if (argumentError) {
            throw new ArgumentError("Illegal character in path");
          }
           else {
            throw new UnsupportedError("Illegal character in path");
          }
        }
      });
    }
    static _checkWindowsDriveLetter(charCode, argumentError) {
      if ((_UPPER_CASE_A <= charCode && charCode <= _UPPER_CASE_Z) || (_LOWER_CASE_A <= charCode && charCode <= _LOWER_CASE_Z)) {
        return;
      }
      if (argumentError) {
        throw new ArgumentError(/* Unimplemented binary operator: "Illegal drive letter " + new String.fromCharCode(charCode) */);
      }
       else {
        throw new UnsupportedError(/* Unimplemented binary operator: "Illegal drive letter " + new String.fromCharCode(charCode) */);
      }
    }
    static _makeFileUri(path) {
      let sep = "/";
      if (path.startsWith(sep)) {
        return new Uri(/* Unimplemented NamedExpression: scheme: "file" */, /* Unimplemented NamedExpression: pathSegments: path.split(sep) */);
      }
       else {
        return new Uri(/* Unimplemented NamedExpression: pathSegments: path.split(sep) */);
      }
    }
    static _makeWindowsFileUrl(path) {
      if (path.startsWith("\\?\")) {
        if (path.startsWith("\\?\UNC\")) {
          path = "\" + (path.substring(7)) + "";
        }
         else {
          path = path.substring(4);
          if (path.length < 3 || path.codeUnitAt(1) !== _COLON || path.codeUnitAt(2) !== _BACKSLASH) {
            throw new ArgumentError("Windows paths with \\?\ prefix must be absolute");
          }
        }
      }
       else {
        path = path.replaceAll("/", "\");
      }
      let sep = "\";
      if (path.length > 1 && dart.equals(path[1], ":")) {
        _checkWindowsDriveLetter(path.codeUnitAt(0), true);
        if (path.length === 2 || path.codeUnitAt(2) !== _BACKSLASH) {
          throw new ArgumentError("Windows paths with drive letter must be absolute");
        }
        let pathSegments = path.split(sep);
        _checkWindowsPathReservedCharacters(pathSegments, true, 1);
        return new Uri(/* Unimplemented NamedExpression: scheme: "file" */, /* Unimplemented NamedExpression: pathSegments: pathSegments */);
      }
      if (path.length > 0 && dart.equals(path[0], sep)) {
        if (path.length > 1 && dart.equals(path[1], sep)) {
          let pathStart = path.indexOf("\", 2);
          let hostPart = pathStart === -1 ? path.substring(2) : path.substring(2, pathStart);
          let pathPart = pathStart === -1 ? "" : path.substring(pathStart + 1);
          let pathSegments = pathPart.split(sep);
          _checkWindowsPathReservedCharacters(pathSegments, true);
          return new Uri(/* Unimplemented NamedExpression: scheme: "file" */, /* Unimplemented NamedExpression: host: hostPart */, /* Unimplemented NamedExpression: pathSegments: pathSegments */);
        }
         else {
          let pathSegments = path.split(sep);
          _checkWindowsPathReservedCharacters(pathSegments, true);
          return new Uri(/* Unimplemented NamedExpression: scheme: "file" */, /* Unimplemented NamedExpression: pathSegments: pathSegments */);
        }
      }
       else {
        let pathSegments = path.split(sep);
        _checkWindowsPathReservedCharacters(pathSegments, true);
        return new Uri(/* Unimplemented NamedExpression: pathSegments: pathSegments */);
      }
    }
    replace(opt$) {
      let scheme = opt$.scheme === undefined ? null : opt$.scheme;
      let userInfo = opt$.userInfo === undefined ? null : opt$.userInfo;
      let host = opt$.host === undefined ? null : opt$.host;
      let port = opt$.port === undefined ? null : opt$.port;
      let path = opt$.path === undefined ? null : opt$.path;
      let pathSegments = opt$.pathSegments === undefined ? null : opt$.pathSegments;
      let query = opt$.query === undefined ? null : opt$.query;
      let queryParameters = opt$.queryParameters === undefined ? null : opt$.queryParameters;
      let fragment = opt$.fragment === undefined ? null : opt$.fragment;
      let schemeChanged = false;
      if (scheme !== null) {
        scheme = _makeScheme(scheme, scheme.length);
        schemeChanged = true;
      }
       else {
        scheme = this.scheme;
      }
      let isFile = (dart.equals(scheme, "file"));
      if (userInfo !== null) {
        userInfo = _makeUserInfo(userInfo, 0, userInfo.length);
      }
       else {
        userInfo = this.userInfo;
      }
      if (port !== null) {
        port = _makePort(port, scheme);
      }
       else {
        port = this._port;
        if (schemeChanged) {
          port = _makePort(port, scheme);
        }
      }
      if (host !== null) {
        host = _makeHost(host, 0, host.length, false);
      }
       else if (this.hasAuthority) {
        host = this.host;
      }
       else if (userInfo.isNotEmpty || port !== null || isFile) {
        host = "";
      }
      let ensureLeadingSlash = (host !== null);
      if (path !== null || pathSegments !== null) {
        path = _makePath(path, 0, _stringOrNullLength(path), pathSegments, ensureLeadingSlash, isFile);
      }
       else {
        path = this.path;
        if ((isFile || (ensureLeadingSlash && !path.isEmpty)) && !path.startsWith("/")) {
          path = "/" + (path) + "";
        }
      }
      if (query !== null || queryParameters !== null) {
        query = _makeQuery(query, 0, _stringOrNullLength(query), queryParameters);
      }
       else if (this.hasQuery) {
        query = this.query;
      }
      if (fragment !== null) {
        fragment = _makeFragment(fragment, 0, fragment.length);
      }
       else if (this.hasFragment) {
        fragment = this.fragment;
      }
      return new Uri.this._internal(scheme, userInfo, host, port, path, query, fragment);
    }
    get pathSegments() {
      if (this._pathSegments === null) {
        let pathToSplit = !this.path.isEmpty && this.path.codeUnitAt(0) === _SLASH ? this.path.substring(1) : this.path;
        this._pathSegments = /* Unimplemented: DownCastExact: UnmodifiableListView<dynamic> to List<String> */ new collection.UnmodifiableListView(dart.equals(pathToSplit, "") ? /* Unimplemented const *//* Unimplemented ArrayList */[] : pathToSplit.split("/").map(Uri.decodeComponent).toList(/* Unimplemented NamedExpression: growable: false */));
      }
      return this._pathSegments;
    }
    get queryParameters() {
      if (this._queryParameters === null) {
        this._queryParameters = /* Unimplemented: DownCastExact: UnmodifiableMapView<dynamic, dynamic> to Map<String, String> */ new collection.UnmodifiableMapView(splitQueryString(this.query));
      }
      return this._queryParameters;
    }
    static _makePort(port, scheme) {
      if (port !== null && port === _defaultPort(scheme)) return null;
      return port;
    }
    static _makeHost(host, start, end, strictIPv6) {
      if (host === null) return null;
      if (start === end) return "";
      if (host.codeUnitAt(start) === _LEFT_BRACKET) {
        if (host.codeUnitAt(end - 1) !== _RIGHT_BRACKET) {
          _fail(host, start, "Missing end `]` to match `[` in host");
        }
        parseIPv6Address(host, start + 1, end - 1);
        return host.substring(start, end).toLowerCase();
      }
      if (!strictIPv6) {
        for (let i = start; i < end; i++) {
          if (host.codeUnitAt(i) === _COLON) {
            parseIPv6Address(host, start, end);
            return "[" + (host) + "]";
          }
        }
      }
      return _normalizeRegName(host, start, end);
    }
    static _isRegNameChar(char) {
      return char < 127 && !dart.equals((/* Unimplemented binary operator: _regNameTable[char >> 4] & (1 << (char & 0xf)) */), 0);
    }
    static _normalizeRegName(host, start, end) {
      let buffer = null;
      let sectionStart = start;
      let index = start;
      let isNormalized = true;
      while (index < end) {
        let char = host.codeUnitAt(index);
        if (char === _PERCENT) {
          let replacement = _normalizeEscape(host, index, true);
          if (replacement === null && isNormalized) {
            index = 3;
            /* Unimplemented ContinueStatement: continue; */}
          if (buffer === null) buffer = new StringBuffer();
          let slice = host.substring(sectionStart, index);
          if (!isNormalized) slice = slice.toLowerCase();
          buffer.write(slice);
          let sourceLength = 3;
          if (replacement === null) {
            replacement = host.substring(index, index + 3);
          }
           else if (dart.equals(replacement, "%")) {
            replacement = "%25";
            sourceLength = 1;
          }
          buffer.write(replacement);
          index = sourceLength;
          sectionStart = index;
          isNormalized = true;
        }
         else if (_isRegNameChar(char)) {
          if (isNormalized && _UPPER_CASE_A <= char && _UPPER_CASE_Z >= char) {
            if (buffer === null) buffer = new StringBuffer();
            if (sectionStart < index) {
              buffer.write(host.substring(sectionStart, index));
              sectionStart = index;
            }
            isNormalized = false;
          }
          index++;
        }
         else if (_isGeneralDelimiter(char)) {
          _fail(host, index, "Invalid character");
        }
         else {
          let sourceLength = 1;
          if ((char & 64512) === 55296 && (index + 1) < end) {
            let tail = host.codeUnitAt(index + 1);
            if ((tail & 64512) === 56320) {
              char = 65536 | ((char & 1023) << 10) | (tail & 1023);
              sourceLength = 2;
            }
          }
          if (buffer === null) buffer = new StringBuffer();
          let slice = host.substring(sectionStart, index);
          if (!isNormalized) slice = slice.toLowerCase();
          buffer.write(slice);
          buffer.write(_escapeChar(char));
          index = sourceLength;
          sectionStart = index;
        }
      }
      if (buffer === null) return host.substring(start, end);
      if (sectionStart < end) {
        let slice = host.substring(sectionStart, end);
        if (!isNormalized) slice = slice.toLowerCase();
        buffer.write(slice);
      }
      return buffer.toString();
    }
    static _makeScheme(scheme, end) {
      if (end === 0) return "";
      let firstCodeUnit = scheme.codeUnitAt(0);
      if (!_isAlphabeticCharacter(firstCodeUnit)) {
        _fail(scheme, 0, "Scheme not starting with alphabetic character");
      }
      let allLowercase = firstCodeUnit >= _LOWER_CASE_A;
      for (let i = 0; i < end; i++) {
        let codeUnit = scheme.codeUnitAt(i);
        if (!_isSchemeCharacter(codeUnit)) {
          _fail(scheme, i, "Illegal scheme character");
        }
        if (codeUnit < _LOWER_CASE_A || codeUnit > _LOWER_CASE_Z) {
          allLowercase = false;
        }
      }
      scheme = scheme.substring(0, end);
      if (!allLowercase) scheme = scheme.toLowerCase();
      return scheme;
    }
    static _makeUserInfo(userInfo, start, end) {
      if (userInfo === null) return "";
      return _normalize(userInfo, start, end, /* Unimplemented: DownCast: dynamic to List<int> */ _userinfoTable);
    }
    static _makePath(path, start, end, pathSegments, ensureLeadingSlash, isFile) {
      if (path === null && pathSegments === null) return isFile ? "/" : "";
      if (path !== null && pathSegments !== null) {
        throw new ArgumentError("Both path and pathSegments specified");
      }
      let result = null;
      if (path !== null) {
        result = _normalize(path, start, end, /* Unimplemented: DownCast: dynamic to List<int> */ _pathCharOrSlashTable);
      }
       else {
        result = pathSegments.map((s) => _uriEncode(/* Unimplemented: DownCast: dynamic to List<int> */ _pathCharTable, /* Unimplemented: DownCast: dynamic to String */ s)).join("/");
      }
      if (dart.dload(result, "isEmpty")) {
        if (isFile) return "/";
      }
       else if ((isFile || ensureLeadingSlash) && !dart.equals(/* Unimplemented dynamic method call: result.codeUnitAt(0) */, _SLASH)) {
        return "/" + (result) + "";
      }
      return /* Unimplemented: DownCast: dynamic to String */ result;
    }
    static _makeQuery(query, start, end, queryParameters) {
      if (query === null && queryParameters === null) return null;
      if (query !== null && queryParameters !== null) {
        throw new ArgumentError("Both query and queryParameters specified");
      }
      if (query !== null) return _normalize(query, start, end, /* Unimplemented: DownCast: dynamic to List<int> */ _queryCharTable);
      let result = new StringBuffer();
      let first = true;
      queryParameters.forEach((key, value) => {
        if (!first) {
          result.write("&");
        }
        first = false;
        result.write(Uri.encodeQueryComponent(/* Unimplemented: DownCast: dynamic to String */ key));
        if (value !== null && /* Unimplemented postfix operator: !value.isEmpty */) {
          result.write("=");
          result.write(Uri.encodeQueryComponent(/* Unimplemented: DownCast: dynamic to String */ value));
        }
      });
      return result.toString();
    }
    static _makeFragment(fragment, start, end) {
      if (fragment === null) return null;
      return _normalize(fragment, start, end, /* Unimplemented: DownCast: dynamic to List<int> */ _queryCharTable);
    }
    static _stringOrNullLength(s) { return (s === null) ? 0 : s.length; }
    static _isHexDigit(char) {
      if (_NINE >= char) return _ZERO <= char;
      char = 32;
      return _LOWER_CASE_A <= char && _LOWER_CASE_F >= char;
    }
    static _hexValue(char) {
      dart.assert(_isHexDigit(char));
      if (_NINE >= char) return char - _ZERO;
      char = 32;
      return char - (_LOWER_CASE_A - 10);
    }
    static _normalizeEscape(source, index, lowerCase) {
      dart.assert(source.codeUnitAt(index) === _PERCENT);
      if (index + 2 >= source.length) {
        return "%";
      }
      let firstDigit = source.codeUnitAt(index + 1);
      let secondDigit = source.codeUnitAt(index + 2);
      if (!_isHexDigit(firstDigit) || !_isHexDigit(secondDigit)) {
        return "%";
      }
      let value = _hexValue(firstDigit) * 16 + _hexValue(secondDigit);
      if (_isUnreservedChar(value)) {
        if (lowerCase && _UPPER_CASE_A <= value && _UPPER_CASE_Z >= value) {
          value = 32;
        }
        return new String.fromCharCode(value);
      }
      if (firstDigit >= _LOWER_CASE_A || secondDigit >= _LOWER_CASE_A) {
        return source.substring(index, index + 3).toUpperCase();
      }
      return null;
    }
    static _isUnreservedChar(ch) {
      return ch < 127 && (!dart.equals((/* Unimplemented binary operator: _unreservedTable[ch >> 4] & (1 << (ch & 0x0f)) */), 0));
    }
    static _escapeChar(char) {
      dart.assert(/* Unimplemented binary operator: char <= 0x10ffff */);
      let hexDigits = "0123456789ABCDEF";
      let codeUnits = null;
      if (/* Unimplemented binary operator: char < 0x80 */) {
        codeUnits = new List(3);
        codeUnits[0] = _PERCENT;
        codeUnits[1] = hexDigits.codeUnitAt(/* Unimplemented: DownCast: dynamic to int */ /* Unimplemented binary operator: char >> 4 */);
        codeUnits[2] = hexDigits.codeUnitAt(/* Unimplemented: DownCast: dynamic to int */ /* Unimplemented binary operator: char & 0xf */);
      }
       else {
        let flag = 192;
        let encodedBytes = 2;
        if (/* Unimplemented binary operator: char > 0x7ff */) {
          flag = 224;
          encodedBytes = 3;
          if (/* Unimplemented binary operator: char > 0xffff */) {
            encodedBytes = 4;
            flag = 240;
          }
        }
        codeUnits = new List(3 * encodedBytes);
        let index = 0;
        while (--encodedBytes >= 0) {
          let byte = /* Unimplemented: DownCast: dynamic to int */ /* Unimplemented binary operator: ((char >> (6 * encodedBytes)) & 0x3f) | flag */;
          codeUnits[index] = _PERCENT;
          codeUnits[index + 1] = hexDigits.codeUnitAt(byte >> 4);
          codeUnits[index + 2] = hexDigits.codeUnitAt(byte & 15);
          index = 3;
          flag = 128;
        }
      }
      return new String.fromCharCodes(codeUnits);
    }
    static _normalize(component, start, end, charTable) {
      let buffer = null;
      let sectionStart = start;
      let index = start;
      while (index < end) {
        let char = component.codeUnitAt(index);
        if (char < 127 && (charTable[char >> 4] & (1 << (char & 15))) !== 0) {
          index++;
        }
         else {
          let replacement = null;
          let sourceLength = null;
          if (char === _PERCENT) {
            replacement = _normalizeEscape(component, index, false);
            if (replacement === null) {
              index = 3;
              /* Unimplemented ContinueStatement: continue; */}
            if (dart.equals("%", replacement)) {
              replacement = "%25";
              sourceLength = 1;
            }
             else {
              sourceLength = 3;
            }
          }
           else if (_isGeneralDelimiter(char)) {
            _fail(component, index, "Invalid character");
          }
           else {
            sourceLength = 1;
            if ((char & 64512) === 55296) {
              if (index + 1 < end) {
                let tail = component.codeUnitAt(index + 1);
                if ((tail & 64512) === 56320) {
                  sourceLength = 2;
                  char = 65536 | ((char & 1023) << 10) | (tail & 1023);
                }
              }
            }
            replacement = _escapeChar(char);
          }
          if (buffer === null) buffer = new StringBuffer();
          buffer.write(component.substring(sectionStart, index));
          buffer.write(replacement);
          index = sourceLength;
          sectionStart = index;
        }
      }
      if (buffer === null) {
        return component.substring(start, end);
      }
      if (sectionStart < end) {
        buffer.write(component.substring(sectionStart, end));
      }
      return buffer.toString();
    }
    static _isSchemeCharacter(ch) {
      return ch < 128 && (!dart.equals((/* Unimplemented binary operator: _schemeTable[ch >> 4] & (1 << (ch & 0x0f)) */), 0));
    }
    static _isGeneralDelimiter(ch) {
      return ch <= _RIGHT_BRACKET && (!dart.equals((/* Unimplemented binary operator: _genDelimitersTable[ch >> 4] & (1 << (ch & 0x0f)) */), 0));
    }
    get isAbsolute() { return !dart.equals(this.scheme, "") && dart.equals(this.fragment, ""); }
    _merge(base, reference) {
      if (base.isEmpty) return "/" + (reference) + "";
      let backCount = 0;
      let refStart = 0;
      while (reference.startsWith("../", refStart)) {
        refStart = 3;
        backCount++;
      }
      let baseEnd = base.lastIndexOf("/");
      while (baseEnd > 0 && backCount > 0) {
        let newEnd = base.lastIndexOf("/", baseEnd - 1);
        if (newEnd < 0) {
          /* Unimplemented BreakStatement: break; */}
        let delta = baseEnd - newEnd;
        if ((delta === 2 || delta === 3) && base.codeUnitAt(newEnd + 1) === _DOT && (delta === 2 || base.codeUnitAt(newEnd + 2) === _DOT)) {
          /* Unimplemented BreakStatement: break; */}
        baseEnd = newEnd;
        backCount--;
      }
      return /* Unimplemented binary operator: base.substring(0, baseEnd + 1) + reference.substring(refStart - 3 * backCount) */;
    }
    _hasDotSegments(path) {
      if (path.length > 0 && path.codeUnitAt(0) === _DOT) return true;
      let index = path.indexOf("/.");
      return index !== -1;
    }
    _removeDotSegments(path) {
      if (!this._hasDotSegments(path)) return path;
      let output = /* Unimplemented: DownCastLiteral: List<dynamic> to List<String> */ /* Unimplemented ArrayList */[];
      let appendSlash = false;
      /* Unimplemented ForEachStatement: for (String segment in path.split("/")) {appendSlash = false; if (segment == "..") {if (!output.isEmpty && ((output.length != 1) || (output[0] != ""))) output.removeLast(); appendSlash = true;} else if ("." == segment) {appendSlash = true;} else {output.add(segment);}} */if (appendSlash) output.add("");
      return output.join("/");
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
          targetPort = /* Unimplemented: DownCast: dynamic to int */ reference.hasPort ? reference.port : null;
        }
        targetPath = this._removeDotSegments(reference.path);
        if (reference.hasQuery) {
          targetQuery = reference.query;
        }
      }
       else {
        targetScheme = this.scheme;
        if (reference.hasAuthority) {
          targetUserInfo = reference.userInfo;
          targetHost = reference.host;
          targetPort = _makePort(/* Unimplemented: DownCast: dynamic to int */ reference.hasPort ? reference.port : null, targetScheme);
          targetPath = this._removeDotSegments(reference.path);
          if (reference.hasQuery) targetQuery = reference.query;
        }
         else {
          if (dart.equals(reference.path, "")) {
            targetPath = this._path;
            if (reference.hasQuery) {
              targetQuery = reference.query;
            }
             else {
              targetQuery = this._query;
            }
          }
           else {
            if (reference.path.startsWith("/")) {
              targetPath = this._removeDotSegments(reference.path);
            }
             else {
              targetPath = this._removeDotSegments(this._merge(this._path, reference.path));
            }
            if (reference.hasQuery) targetQuery = reference.query;
          }
          targetUserInfo = this._userInfo;
          targetHost = this._host;
          targetPort = this._port;
        }
      }
      let fragment = /* Unimplemented: DownCast: dynamic to String */ reference.hasFragment ? reference.fragment : null;
      return new Uri.this._internal(targetScheme, targetUserInfo, targetHost, targetPort, targetPath, targetQuery, fragment);
    }
    get hasAuthority() { return this._host !== null; }
    get hasPort() { return this._port !== null; }
    get hasQuery() { return this._query !== null; }
    get hasFragment() { return this._fragment !== null; }
    get origin() {
      if (dart.equals(this.scheme, "") || this._host === null || dart.equals(this._host, "")) {
        throw new StateError("Cannot use origin without a scheme: " + (this) + "");
      }
      if (!dart.equals(this.scheme, "http") && !dart.equals(this.scheme, "https")) {
        throw new StateError("Origin is only applicable schemes http and https: " + (this) + "");
      }
      if (this._port === null) return "" + (this.scheme) + "://" + (this._host) + "";
      return "" + (this.scheme) + "://" + (this._host) + ":" + (this._port) + "";
    }
    toFilePath(opt$) {
      let windows = opt$.windows === undefined ? null : opt$.windows;
      if (!dart.equals(this.scheme, "") && !dart.equals(this.scheme, "file")) {
        throw new UnsupportedError("Cannot extract a file path from a " + (this.scheme) + " URI");
      }
      if (!dart.equals(this.query, "")) {
        throw new UnsupportedError("Cannot extract a file path from a URI with a query component");
      }
      if (!dart.equals(this.fragment, "")) {
        throw new UnsupportedError("Cannot extract a file path from a URI with a fragment component");
      }
      if (windows === null) windows = _isWindows;
      return windows ? this._toWindowsFilePath() : this._toFilePath();
    }
    _toFilePath() {
      if (!dart.equals(this.host, "")) {
        throw new UnsupportedError("Cannot extract a non-Windows file path from a file URI " + "with an authority");
      }
      _checkNonWindowsPathReservedCharacters(this.pathSegments, false);
      let result = new StringBuffer();
      if (this._isPathAbsolute) result.write("/");
      result.writeAll(this.pathSegments, "/");
      return result.toString();
    }
    _toWindowsFilePath() {
      let hasDriveLetter = false;
      let segments = this.pathSegments;
      if (segments.length > 0 && segments[0].length === 2 && segments[0].codeUnitAt(1) === _COLON) {
        _checkWindowsDriveLetter(segments[0].codeUnitAt(0), false);
        _checkWindowsPathReservedCharacters(segments, false, 1);
        hasDriveLetter = true;
      }
       else {
        _checkWindowsPathReservedCharacters(segments, false);
      }
      let result = new StringBuffer();
      if (this._isPathAbsolute && !hasDriveLetter) result.write("\");
      if (!dart.equals(this.host, "")) {
        result.write("\");
        result.write(this.host);
        result.write("\");
      }
      result.writeAll(segments, "\");
      if (hasDriveLetter && segments.length === 1) result.write("\");
      return result.toString();
    }
    get _isPathAbsolute() {
      if (this.path === null || this.path.isEmpty) return false;
      return this.path.startsWith("/");
    }
    _writeAuthority(ss) {
      if (this._userInfo.isNotEmpty) {
        ss.write(this._userInfo);
        ss.write("@");
      }
      if (this._host !== null) ss.write(this._host);
      if (this._port !== null) {
        ss.write(":");
        ss.write(this._port);
      }
    }
    toString() {
      let sb = new StringBuffer();
      _addIfNonEmpty(sb, this.scheme, this.scheme, ":");
      if (this.hasAuthority || this.path.startsWith("//") || (dart.equals(this.scheme, "file"))) {
        sb.write("//");
        this._writeAuthority(sb);
      }
      sb.write(this.path);
      if (this._query !== null) {
        (sb.write("?"),
          sb.write(this._query));
      }
      if (this._fragment !== null) {
        (sb.write("#"),
          sb.write(this._fragment));
      }
      return sb.toString();
    }
    ==(other) {
      if (/* Unimplemented IsExpression: other is! Uri */) return false;
      let uri = /* Unimplemented: DownCast: dynamic to Uri */ other;
      return dart.equals(this.scheme, uri.scheme) && this.hasAuthority === uri.hasAuthority && dart.equals(this.userInfo, uri.userInfo) && dart.equals(this.host, uri.host) && this.port === uri.port && dart.equals(this.path, uri.path) && this.hasQuery === uri.hasQuery && dart.equals(this.query, uri.query) && this.hasFragment === uri.hasFragment && dart.equals(this.fragment, uri.fragment);
    }
    get hashCode() {
      // Function combine: (dynamic, dynamic) → int
      function combine(part, current) {
        return /* Unimplemented: DownCast: dynamic to int */ /* Unimplemented binary operator: (current * 31 + part.hashCode) & 0x3FFFFFFF */;
      }
      return combine(this.scheme, combine(this.userInfo, combine(this.host, combine(this.port, combine(this.path, combine(this.query, combine(this.fragment, 1)))))));
    }
    static _addIfNonEmpty(sb, test, first, second) {
      if (!dart.equals("", test)) {
        sb.write(first);
        sb.write(second);
      }
    }
    static encodeComponent(component) {
      return _uriEncode(/* Unimplemented: DownCast: dynamic to List<int> */ _unreserved2396Table, component);
    }
    static encodeQueryComponent(component, opt$) {
      let encoding = opt$.encoding === undefined ? convert.UTF8 : opt$.encoding;
      return _uriEncode(/* Unimplemented: DownCast: dynamic to List<int> */ _unreservedTable, component, /* Unimplemented NamedExpression: encoding: encoding */, /* Unimplemented NamedExpression: spaceToPlus: true */);
    }
    static decodeComponent(encodedComponent) {
      return _uriDecode(encodedComponent);
    }
    static decodeQueryComponent(encodedComponent, opt$) {
      let encoding = opt$.encoding === undefined ? convert.UTF8 : opt$.encoding;
      return _uriDecode(encodedComponent, /* Unimplemented NamedExpression: plusToSpace: true */, /* Unimplemented NamedExpression: encoding: encoding */);
    }
    static encodeFull(uri) {
      return _uriEncode(/* Unimplemented: DownCast: dynamic to List<int> */ _encodeFullTable, uri);
    }
    static decodeFull(uri) {
      return _uriDecode(uri);
    }
    static splitQueryString(query, opt$) {
      let encoding = opt$.encoding === undefined ? convert.UTF8 : opt$.encoding;
      return /* Unimplemented: DownCast: dynamic to Map<String, String> */ query.split("&").fold(/* Unimplemented MapLiteral: {} */, (map, element) => {
        let index = /* Unimplemented: DownCast: dynamic to int */ /* Unimplemented dynamic method call: element.indexOf("=") */;
        if (index === -1) {
          if (!dart.equals(element, "")) {
            /* Unimplemented dynamic IndexExpression: map[decodeQueryComponent(element, encoding: encoding)] */ = "";
          }
        }
         else if (index !== 0) {
          let key = /* Unimplemented dynamic method call: element.substring(0, index) */;
          let value = /* Unimplemented dynamic method call: element.substring(index + 1) */;
          /* Unimplemented dynamic IndexExpression: map[Uri.decodeQueryComponent(key, encoding: encoding)] */ = decodeQueryComponent(/* Unimplemented: DownCast: dynamic to String */ value, /* Unimplemented NamedExpression: encoding: encoding */);
        }
        return map;
      });
    }
    static parseIPv4Address(host) {
      // Function error: (String) → void
      function error(msg) {
        throw new FormatException("Illegal IPv4 address, " + (msg) + "");
      }
      let bytes = host.split(".");
      if (bytes.length !== 4) {
        error("IPv4 address should contain exactly 4 parts");
      }
      return /* Unimplemented: DownCastDynamic: List<dynamic> to List<int> */ bytes.map((byteString) => {
        let byte = int.parse(/* Unimplemented: DownCast: dynamic to String */ byteString);
        if (byte < 0 || byte > 255) {
          error("each part must be in the range of `0..255`");
        }
        return byte;
      }).toList();
    }
    static parseIPv6Address(host, start, end) {
      if (start === undefined) start = 0;
      if (end === undefined) end = null;
      if (end === null) end = host.length;
      // Function error: (String, [dynamic]) → void
      function error(msg, position) {
        if (position === undefined) position = null;
        throw new FormatException("Illegal IPv6 address, " + (msg) + "", host, position);
      }
      // Function parseHex: (int, int) → int
      function parseHex(start, end) {
        if (end - start > 4) {
          error("an IPv6 part can only contain a maximum of 4 hex digits", start);
        }
        let value = int.parse(host.substring(start, end), /* Unimplemented NamedExpression: radix: 16 */);
        if (value < 0 || value > (1 << 16) - 1) {
          error("each part must be in the range of `0x0..0xFFFF`", start);
        }
        return value;
      }
      if (host.length < 2) error("address is too short");
      let parts = /* Unimplemented: DownCastLiteral: List<dynamic> to List<int> */ /* Unimplemented ArrayList */[];
      let wildcardSeen = false;
      let partStart = start;
      for (let i = start; i < end; i++) {
        if (host.codeUnitAt(i) === _COLON) {
          if (i === start) {
            i++;
            if (host.codeUnitAt(i) !== _COLON) {
              error("invalid start colon.", i);
            }
            partStart = i;
          }
          if (i === partStart) {
            if (wildcardSeen) {
              error("only one wildcard `::` is allowed", i);
            }
            wildcardSeen = true;
            parts.add(-1);
          }
           else {
            parts.add(parseHex(partStart, i));
          }
          partStart = i + 1;
        }
      }
      if (parts.length === 0) error("too few parts");
      let atEnd = (partStart === end);
      let isLastWildcard = (parts.last === -1);
      if (atEnd && !isLastWildcard) {
        error("expected a part after last `:`", end);
      }
      if (!atEnd) {
        /* Unimplemented TryStatement: try {parts.add(parseHex(partStart, end));} catch (e) {try {List<int> last = parseIPv4Address(host.substring(partStart, end)); parts.add(last[0] << 8 | last[1]); parts.add(last[2] << 8 | last[3]);} catch (e) {error('invalid end of IPv6 address.', partStart);}} */}
      if (wildcardSeen) {
        if (parts.length > 7) {
          error("an address with a wildcard must have less than 7 parts");
        }
      }
       else if (parts.length !== 8) {
        error("an address without a wildcard must contain exactly 8 parts");
      }
      let bytes = new List(16);
      for (let i = 0, index = 0; i < parts.length; i++) {
        let value = parts[i];
        if (value === -1) {
          let wildCardLength = 9 - parts.length;
          for (let j = 0; j < wildCardLength; j++) {
            bytes[index] = 0;
            bytes[index + 1] = 0;
            index = 2;
          }
        }
         else {
          bytes[index] = value >> 8;
          bytes[index + 1] = value & 255;
          index = 2;
        }
      }
      return /* Unimplemented: DownCastDynamic: List<dynamic> to List<int> */ bytes;
    }
    static _uriEncode(canonicalTable, text, opt$) {
      let encoding = opt$.encoding === undefined ? convert.UTF8 : opt$.encoding;
      let spaceToPlus = opt$.spaceToPlus === undefined ? false : opt$.spaceToPlus;
      // Function byteToHex: (dynamic, dynamic) → dynamic
      function byteToHex(byte, buffer) {
        let hex = "0123456789ABCDEF";
        /* Unimplemented dynamic method call: buffer.writeCharCode(hex.codeUnitAt(byte >> 4)) */;
        /* Unimplemented dynamic method call: buffer.writeCharCode(hex.codeUnitAt(byte & 0x0f)) */;
      }
      let result = new StringBuffer();
      let bytes = encoding.encode(text);
      for (let i = 0; i < bytes.length; i++) {
        let byte = bytes[i];
        if (byte < 128 && ((canonicalTable[byte >> 4] & (1 << (byte & 15))) !== 0)) {
          result.writeCharCode(byte);
        }
         else if (spaceToPlus && byte === _SPACE) {
          result.writeCharCode(_PLUS);
        }
         else {
          result.writeCharCode(_PERCENT);
          byteToHex(byte, result);
        }
      }
      return result.toString();
    }
    static _hexCharPairToByte(s, pos) {
      let byte = 0;
      for (let i = 0; i < 2; i++) {
        let charCode = s.codeUnitAt(pos + i);
        if (48 <= charCode && charCode <= 57) {
          byte = byte * 16 + charCode - 48;
        }
         else {
          charCode = 32;
          if (97 <= charCode && charCode <= 102) {
            byte = byte * 16 + charCode - 87;
          }
           else {
            throw new ArgumentError("Invalid URL encoding");
          }
        }
      }
      return byte;
    }
    static _uriDecode(text, opt$) {
      let plusToSpace = opt$.plusToSpace === undefined ? false : opt$.plusToSpace;
      let encoding = opt$.encoding === undefined ? convert.UTF8 : opt$.encoding;
      let simple = true;
      for (let i = 0; i < text.length && simple; i++) {
        let codeUnit = text.codeUnitAt(i);
        simple = codeUnit !== _PERCENT && codeUnit !== _PLUS;
      }
      let bytes = null;
      if (simple) {
        if (dart.equals(encoding, convert.UTF8) || dart.equals(encoding, convert.LATIN1)) {
          return text;
        }
         else {
          bytes = text.codeUnits;
        }
      }
       else {
        bytes = /* Unimplemented: DownCastExact: List<dynamic> to List<int> */ new List();
        for (let i = 0; i < text.length; i++) {
          let codeUnit = text.codeUnitAt(i);
          if (codeUnit > 127) {
            throw new ArgumentError("Illegal percent encoding in URI");
          }
          if (codeUnit === _PERCENT) {
            if (i + 3 > text.length) {
              throw new ArgumentError("Truncated URI");
            }
            bytes.add(_hexCharPairToByte(text, i + 1));
            i = 2;
          }
           else if (plusToSpace && codeUnit === _PLUS) {
            bytes.add(_SPACE);
          }
           else {
            bytes.add(codeUnit);
          }
        }
      }
      return encoding.decode(bytes);
    }
    static _isAlphabeticCharacter(codeUnit) { return (codeUnit >= _LOWER_CASE_A && codeUnit <= _LOWER_CASE_Z) || (codeUnit >= _UPPER_CASE_A && codeUnit <= _UPPER_CASE_Z); }
  }
  Uri._internal = function(scheme, _userInfo, _host, _port, _path, _query, _fragment) { this.__init__internal(scheme, _userInfo, _host, _port, _path, _query, _fragment) };
  Uri._internal.prototype = Uri.prototype;
  Uri.http = function(authority, unencodedPath, queryParameters) { this.__init_http(authority, unencodedPath, queryParameters) };
  Uri.http.prototype = Uri.prototype;
  Uri.https = function(authority, unencodedPath, queryParameters) { this.__init_https(authority, unencodedPath, queryParameters) };
  Uri.https.prototype = Uri.prototype;
  Uri.file = function(path, opt$) { this.__init_file(path, opt$) };
  Uri.file.prototype = Uri.prototype;

  // Exports:
  core.Deprecated = Deprecated;
  core.deprecated = deprecated;
  core.override = override;
  core.proxy = proxy;
  core.bool = bool;
  core.Comparable = Comparable;
  core.DateTime = DateTime;
  core.double = double;
  core.Duration = Duration;
  core.Error = Error;
  core.AssertionError = AssertionError;
  core.TypeError = TypeError;
  core.CastError = CastError;
  core.NullThrownError = NullThrownError;
  core.ArgumentError = ArgumentError;
  core.RangeError = RangeError;
  core.IndexError = IndexError;
  core.FallThroughError = FallThroughError;
  core.AbstractClassInstantiationError = AbstractClassInstantiationError;
  core.NoSuchMethodError = NoSuchMethodError;
  core.UnsupportedError = UnsupportedError;
  core.UnimplementedError = UnimplementedError;
  core.StateError = StateError;
  core.ConcurrentModificationError = ConcurrentModificationError;
  core.OutOfMemoryError = OutOfMemoryError;
  core.StackOverflowError = StackOverflowError;
  core.CyclicInitializationError = CyclicInitializationError;
  core.Exception = Exception;
  core.FormatException = FormatException;
  core.IntegerDivisionByZeroException = IntegerDivisionByZeroException;
  core.Expando = Expando;
  core.Function = Function;
  core.identical = identical;
  core.identityHashCode = identityHashCode;
  core.int = int;
  core.Invocation = Invocation;
  core.Iterable = Iterable;
  core.BidirectionalIterator = BidirectionalIterator;
  core.Iterator = Iterator;
  core.List = List;
  core.Map = Map;
  core.Null = Null;
  core.num = num;
  core.Object = Object;
  core.Pattern = Pattern;
  core.print = print;
  core.Match = Match;
  core.RegExp = RegExp;
  core.Set = Set;
  core.Sink = Sink;
  core.StackTrace = StackTrace;
  core.Stopwatch = Stopwatch;
  core.String = String;
  core.Runes = Runes;
  core.RuneIterator = RuneIterator;
  core.StringBuffer = StringBuffer;
  core.StringSink = StringSink;
  core.Symbol = Symbol;
  core.Type = Type;
  core.Uri = Uri;
})(core || (core = {}));
