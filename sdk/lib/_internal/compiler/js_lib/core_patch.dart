// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:core classes.
import "dart:_internal" as _symbol_dev;
import 'dart:_interceptors';
import 'dart:_js_helper' show patch,
                              patch_new,
                              patch_old,
                              checkInt,
                              getRuntimeType,
                              jsonEncodeNative,
                              JSSyntaxRegExp,
                              Primitives,
                              ConstantMap,
                              stringJoinUnchecked,
                              objectHashCode,
                              Closure;

import 'dart:_native_typed_data' show NativeUint8List;

String _symbolToString(Symbol symbol) => _symbol_dev.Symbol.getName(symbol);

_symbolMapToStringMap(Map<Symbol, dynamic> map) {
  if (map == null) return null;
  var result = new Map<String, dynamic>();
  map.forEach((Symbol key, value) {
    result[_symbolToString(key)] = value;
  });
  return result;
}

@patch
int identityHashCode(Object object) => objectHashCode(object);

// Patch for Object implementation.
@patch
class Object {
  @patch
  int get hashCode => Primitives.objectHashCode(this);


  @patch
  String toString() => Primitives.objectToHumanReadableString(this);

  @patch
  dynamic noSuchMethod(Invocation invocation) {
    throw new NoSuchMethodError(
        this,
        invocation.memberName,
        invocation.positionalArguments,
        invocation.namedArguments);
  }

  @patch
  Type get runtimeType => getRuntimeType(this);
}

// Patch for Function implementation.
@patch
class Function {
  @patch_old
  static apply(Function function,
               List positionalArguments,
               [Map<Symbol, dynamic> namedArguments]) {
    return Primitives.applyFunction(
        function, positionalArguments,
        namedArguments == null ? null : _toMangledNames(namedArguments));
  }

  @patch_new
  static apply(Function function,
               List positionalArguments,
               [Map<Symbol, dynamic> namedArguments]) {
    return Primitives.applyFunctionNewEmitter(function, positionalArguments,
        namedArguments == null ? null : _symbolMapToStringMap(namedArguments));
  }

  static Map<String, dynamic> _toMangledNames(
      Map<Symbol, dynamic> namedArguments) {
    Map<String, dynamic> result = {};
    namedArguments.forEach((symbol, value) {
      result[_symbolToString(symbol)] = value;
    });
    return result;
  }
}

// Patch for Expando implementation.
@patch
class Expando<T> {
  @patch
  Expando([String name]) : this.name = name;

  @patch
  T operator[](Object object) {
    var values = Primitives.getProperty(object, _EXPANDO_PROPERTY_NAME);
    return (values == null) ? null : Primitives.getProperty(values, _getKey());
  }

  @patch
  void operator[]=(Object object, T value) {
    var values = Primitives.getProperty(object, _EXPANDO_PROPERTY_NAME);
    if (values == null) {
      values = new Object();
      Primitives.setProperty(object, _EXPANDO_PROPERTY_NAME, values);
    }
    Primitives.setProperty(values, _getKey(), value);
  }

  String _getKey() {
    String key = Primitives.getProperty(this, _KEY_PROPERTY_NAME);
    if (key == null) {
      key = "expando\$key\$${_keyCount++}";
      Primitives.setProperty(this, _KEY_PROPERTY_NAME, key);
    }
    return key;
  }

  static const String _KEY_PROPERTY_NAME = 'expando\$key';
  static const String _EXPANDO_PROPERTY_NAME = 'expando\$values';
  static int _keyCount = 0;
}

@patch
class int {
  @patch
  static int parse(String source,
                         { int radix,
                           int onError(String source) }) {
    return Primitives.parseInt(source, radix, onError);
  }

  @patch
  factory int.fromEnvironment(String name, {int defaultValue}) {
    throw new UnsupportedError(
        'int.fromEnvironment can only be used as a const constructor');
  }
}

@patch
class double {
  @patch
  static double parse(String source,
                            [double onError(String source)]) {
    return Primitives.parseDouble(source, onError);
  }
}

@patch
class Error {
  @patch
  static String _objectToString(Object object) {
    // Closures all have useful and safe toString methods.
    if (object is Closure) return object.toString();
    return Primitives.objectToHumanReadableString(object);
  }

  @patch
  static String _stringToSafeString(String string) {
    return jsonEncodeNative(string);
  }

  @patch
  StackTrace get stackTrace => Primitives.extractStackTrace(this);
}

// Patch for DateTime implementation.
@patch
class DateTime {
  @patch
  DateTime._internal(int year,
                     int month,
                     int day,
                     int hour,
                     int minute,
                     int second,
                     int millisecond,
                     bool isUtc)
        // checkBool is manually inlined here because dart2js doesn't inline it
        // and [isUtc] is usually a constant.
      : this.isUtc = isUtc is bool ? isUtc : throw new ArgumentError(isUtc),
        millisecondsSinceEpoch = checkInt(Primitives.valueFromDecomposedDate(
            year, month, day, hour, minute, second, millisecond, isUtc));

  @patch
  DateTime._now()
      : isUtc = false,
        millisecondsSinceEpoch = Primitives.dateNow();

  @patch
  static int _brokenDownDateToMillisecondsSinceEpoch(
      int year, int month, int day, int hour, int minute, int second,
      int millisecond, bool isUtc) {
    return Primitives.valueFromDecomposedDate(
        year, month, day, hour, minute, second, millisecond, isUtc);
  }

  @patch
  String get timeZoneName {
    if (isUtc) return "UTC";
    return Primitives.getTimeZoneName(this);
  }

  @patch
  Duration get timeZoneOffset {
    if (isUtc) return new Duration();
    return new Duration(minutes: Primitives.getTimeZoneOffsetInMinutes(this));
  }

  @patch
  int get year => Primitives.getYear(this);

  @patch
  int get month => Primitives.getMonth(this);

  @patch
  int get day => Primitives.getDay(this);

  @patch
  int get hour => Primitives.getHours(this);

  @patch
  int get minute => Primitives.getMinutes(this);

  @patch
  int get second => Primitives.getSeconds(this);

  @patch
  int get millisecond => Primitives.getMilliseconds(this);

  @patch
  int get weekday => Primitives.getWeekday(this);
}


// Patch for Stopwatch implementation.
@patch
class Stopwatch {
  @patch
  static void _initTicker() {
    Primitives.initTicker();
    _frequency = Primitives.timerFrequency;
  }

  @patch
  static int _now() => Primitives.timerTicks();
}

class _ListConstructorSentinel extends JSInt {
  const _ListConstructorSentinel();
}

// Patch for List implementation.
@patch
class List<E> {
  @patch
  factory List([int length = const _ListConstructorSentinel()]) {
    if (length == const _ListConstructorSentinel()) {
      return new JSArray<E>.emptyGrowable();
    }
    return new JSArray<E>.fixed(length);
  }

  @patch
  factory List.filled(int length, E fill) {
    List result = new JSArray<E>.fixed(length);
    if (length != 0 && fill != null) {
      for (int i = 0; i < result.length; i++) {
        result[i] = fill;
      }
    }
    return result;
  }

  @patch
  factory List.from(Iterable elements, { bool growable: true }) {
    List<E> list = new List<E>();
    for (E e in elements) {
      list.add(e);
    }
    if (growable) return list;
    return makeListFixedLength(list);
  }

  @patch
  factory List.unmodifiable(Iterable elements) {
    List result = new List<E>.from(elements, growable: false);
    return makeFixedListUnmodifiable(result);
  }
}

@patch
class Map<K, V> {
  @patch
  factory Map.unmodifiable(Map other) = ConstantMap<K, V>.from;
}

@patch
class String {
  @patch
  factory String.fromCharCodes(Iterable<int> charCodes,
                               [int start = 0, int end]) {

    if (charCodes is JSArray) {
      return _stringFromJSArray(charCodes, start, end);
    }
    if (charCodes is NativeUint8List) {
      return _stringFromUint8List(charCodes, start, end);
    }
    return _stringFromIterable(charCodes, start, end);
  }

  @patch
  factory String.fromCharCode(int charCode) {
    return Primitives.stringFromCharCode(charCode);
  }

  @patch
  factory String.fromEnvironment(String name, {String defaultValue}) {
    throw new UnsupportedError(
        'String.fromEnvironment can only be used as a const constructor');
  }

  static String _stringFromJSArray(List list, int start, int endOrNull) {
    int len = list.length;
    int end = RangeError.checkValidRange(start, endOrNull, len);
    if (start > 0 || end < len) {
      list = list.sublist(start, end);
    }
    return Primitives.stringFromCharCodes(list);
  }

  static String _stringFromUint8List(
      NativeUint8List charCodes, int start, int endOrNull) {
    int len = charCodes.length;
    int end = RangeError.checkValidRange(start, endOrNull, len);
    return Primitives.stringFromNativeUint8List(charCodes, start, end);
  }

  static String _stringFromIterable(Iterable<int> charCodes,
                                    int start, int end) {
    if (start < 0) throw new RangeError.range(start, 0, charCodes.length);
    if (end != null && end < start) {
      throw new RangeError.range(end, start, charCodes.length);
    }
    var it = charCodes.iterator;
    for (int i = 0; i < start; i++) {
      if (!it.moveNext()) {
        throw new RangeError.range(start, 0, i);
      }
    }
    var list = [];
    if (end == null) {
      while (it.moveNext()) list.add(it.current);
    } else {
      for (int i = start; i < end; i++) {
        if (!it.moveNext()) {
          throw new RangeError.range(end, start, i);
        }
        list.add(it.current);
      }
    }
    return Primitives.stringFromCharCodes(list);
  }
}

@patch
class bool {
  @patch
  factory bool.fromEnvironment(String name, {bool defaultValue: false}) {
    throw new UnsupportedError(
        'bool.fromEnvironment can only be used as a const constructor');
  }
}

@patch
class RegExp {
  @patch
  factory RegExp(String source,
                       {bool multiLine: false,
                        bool caseSensitive: true})
    => new JSSyntaxRegExp(source,
                          multiLine: multiLine,
                          caseSensitive: caseSensitive);
}

// Patch for 'identical' function.
@patch
bool identical(Object a, Object b) {
  return Primitives.identicalImplementation(a, b);
}

@patch
class StringBuffer {
  String _contents;

  @patch
  StringBuffer([Object content = ""]) : _contents = '$content';

  @patch
  int get length => _contents.length;

  @patch
  void write(Object obj) {
    _writeString('$obj');
  }

  @patch
  void writeCharCode(int charCode) {
    _writeString(new String.fromCharCode(charCode));
  }

  @patch
  void writeAll(Iterable objects, [String separator = ""]) {
    _contents = _writeAll(_contents, objects, separator);
  }

  @patch
  void writeln([Object obj = ""]) {
    _writeString('$obj\n');
  }

  @patch
  void clear() {
    _contents = "";
  }

  @patch
  String toString() => Primitives.flattenString(_contents);

  void _writeString(str) {
    _contents = Primitives.stringConcatUnchecked(_contents, str);
  }

  static String _writeAll(String string, Iterable objects, String separator) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return string;
    if (separator.isEmpty) {
      do {
        string = _writeOne(string, iterator.current);
      } while (iterator.moveNext());
    } else {
      string = _writeOne(string, iterator.current);
      while (iterator.moveNext()) {
        string = _writeOne(string, separator);
        string = _writeOne(string, iterator.current);
      }
    }
    return string;
  }

  static String _writeOne(String string, Object obj) {
    return Primitives.stringConcatUnchecked(string, '$obj');
  }
}

@patch
class NoSuchMethodError {
  @patch
  String toString() {
    StringBuffer sb = new StringBuffer();
    String comma = '';
    if (_arguments != null) {
      for (var argument in _arguments) {
        sb.write(comma);
        sb.write(Error.safeToString(argument));
        comma = ', ';
      }
    }
    if (_namedArguments != null) {
      _namedArguments.forEach((Symbol key, var value) {
        sb.write(comma);
        sb.write(_symbolToString(key));
        sb.write(": ");
        sb.write(Error.safeToString(value));
        comma = ', ';
      });
    }
    String memberName = _symbolToString(_memberName);
    String receiverText = Error.safeToString(_receiver);
    String actualParameters = '$sb';
    if (_existingArgumentNames == null) {
      return "NoSuchMethodError: method not found: '$memberName'\n"
          "Receiver: ${receiverText}\n"
          "Arguments: [$actualParameters]";
    } else {
      String formalParameters = _existingArgumentNames.join(', ');
      return "NoSuchMethodError: incorrect number of arguments passed to "
          "method named '$memberName'\n"
          "Receiver: ${receiverText}\n"
          "Tried calling: $memberName($actualParameters)\n"
          "Found: $memberName($formalParameters)";
    }
  }
}

@patch
class Uri {
  @patch
  static bool get _isWindows => false;

  @patch
  static Uri get base {
    String uri = Primitives.currentUri();
    if (uri != null) return Uri.parse(uri);
    throw new UnsupportedError("'Uri.base' is not supported");
  }
}
