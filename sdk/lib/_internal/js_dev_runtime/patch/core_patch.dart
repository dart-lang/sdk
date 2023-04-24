// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:core classes.
import 'dart:_internal' as _symbol_dev;
import 'dart:_internal' show patch;
import 'dart:_interceptors';
import 'dart:_js_helper'
    show
        checkInt,
        LinkedMap,
        JSSyntaxRegExp,
        notNull,
        nullCheck,
        Primitives,
        PrivateSymbol,
        quoteStringForRegExp,
        undefined,
        wrapZoneUnaryCallback;
import 'dart:_runtime' as dart;
import 'dart:_foreign_helper' show JS, JS_GET_FLAG, JSExportName;
import 'dart:_native_typed_data' show NativeUint8List;
import 'dart:_rti' as rti show createRuntimeType, Rti;
import 'dart:collection' show UnmodifiableMapView;
import 'dart:convert' show Encoding, utf8;
import 'dart:typed_data' show Endian, Uint8List, Uint16List;

// These are the additional parts of this patch library:
part 'bigint_patch.dart';

String _symbolToString(Symbol symbol) => symbol is PrivateSymbol
    ? PrivateSymbol.getName(symbol)
    : _symbol_dev.Symbol.getName(symbol as _symbol_dev.Symbol);

@patch
int identityHashCode(Object? object) {
  if (object == null) return 0;
  // Note: this works for primitives because we define the `identityHashCode`
  // for them to be equivalent to their computed hashCode function.
  int? hash = JS<int?>('int|Null', r'#[#]', object, dart.identityHashCode_);
  if (hash == null) {
    hash = JS<int>('!', '(Math.random() * 0x3fffffff) | 0');
    JS('void', r'#[#] = #', object, dart.identityHashCode_, hash);
  }
  return JS<int>('!', '#', hash);
}

// Patch for Object implementation.
@patch
class Object {
  @patch
  bool operator ==(Object other) => identical(this, other);

  @patch
  int get hashCode => identityHashCode(this);

  @patch
  String toString() =>
      "Instance of '${dart.typeName(dart.getReifiedType(this))}'";

  @patch
  dynamic noSuchMethod(Invocation invocation) {
    return dart.defaultNoSuchMethod(this, invocation);
  }

  @patch
  Type get runtimeType => JS_GET_FLAG('NEW_RUNTIME_TYPES')
      ? rti.createRuntimeType(JS<rti.Rti>('!', '#', dart.getReifiedType(this)))
      : dart.wrapType(dart.getReifiedType(this));

  // Everything is an Object.
  @JSExportName('is')
  static bool _is_Object(Object? o) => o != null;

  @JSExportName('as')
  static Object? _as_Object(Object? o) =>
      o == null ? dart.cast(o, dart.unwrapType(Object)) : o;
}

@patch
class Null {
  @patch
  int get hashCode => super.hashCode;

  @JSExportName('is')
  static bool _is_Null(Object? o) => o == null;

  @JSExportName('as')
  static Object? _as_Null(Object? o) {
    // Avoid extra function call to core.Null.is() by manually inlining.
    if (o == null) return o;
    return dart.cast(o, dart.unwrapType(Null));
  }
}

// Patch for Function implementation.
@patch
class Function {
  @patch
  static apply(Function function, List<dynamic>? positionalArguments,
      [Map<Symbol, dynamic>? namedArguments]) {
    // Whether positionalArguments needs to be copied to ensure
    // dcall doesn't modify the original list of positional arguments
    // (currently only true when named arguments are provided too).
    var needsCopy = namedArguments != null && namedArguments.isNotEmpty;
    if (positionalArguments == null) {
      positionalArguments = [];
    } else if (needsCopy ||
        // dcall expects the positionalArguments as a JS array.
        JS<bool>('!', '!Array.isArray(#)', positionalArguments)) {
      positionalArguments = List.of(positionalArguments);
    }

    // dcall expects the namedArguments as a JS map in the last slot.
    if (namedArguments != null && namedArguments.isNotEmpty) {
      var map = JS('', '{}');
      namedArguments.forEach((symbol, arg) {
        JS('', '#[#] = #', map, _symbolToString(symbol), arg);
      });
      return dart.dcall(function, positionalArguments, map);
    }
    return dart.dcall(function, positionalArguments);
  }

  static Map<String, dynamic> _toMangledNames(
      Map<Symbol, dynamic> namedArguments) {
    Map<String, dynamic> result = {};
    namedArguments.forEach((symbol, value) {
      result[_symbolToString(symbol)] = value;
    });
    return result;
  }

  @JSExportName('is')
  static bool _is_Function(Object? o) =>
      JS<bool>('!', 'typeof $o == "function"');

  @JSExportName('as')
  static Object? _as_Function(Object? o) {
    // Avoid extra function call to core.Function.is() by manually inlining.
    if (JS<bool>('!', 'typeof $o == "function"')) return o;
    return dart.cast(o, dart.unwrapType(Function));
  }
}

// Patch for Expando implementation.
@patch
class Expando<T extends Object> {
  final Object _jsWeakMap = JS('=Object', 'new WeakMap()');

  @patch
  Expando([this.name]);

  @patch
  T? operator [](Object object) {
    // JavaScript's WeakMap semantics return 'undefined' for invalid getter
    // keys, so we must check them explicitly.
    if (object == null ||
        object is bool ||
        object is num ||
        object is String ||
        object is Record) {
      throw new ArgumentError.value(
          object,
          "Expandos are not allowed on strings, numbers, booleans, records,"
          " or null");
    }
    return JS('', '#.get(#)', _jsWeakMap, object);
  }

  @patch
  void operator []=(Object object, T? value) {
    // JavaScript's WeakMap already throws on non-Object setter keys, so
    // we can rely on the underlying behavior for all non-Records.
    if (object is Record) {
      throw new ArgumentError.value(
          object,
          "Expandos are not allowed on strings, numbers, booleans, records,"
          " or null");
    }
    JS('void', '#.set(#, #)', _jsWeakMap, object, value);
  }
}

// Patch for WeakReference implementation.
@patch
class WeakReference<T extends Object> {
  @patch
  factory WeakReference(T object) {
    return _WeakReferenceWrapper<T>(object);
  }
}

class _WeakReferenceWrapper<T extends Object> implements WeakReference<T> {
  final Object _weakRef;

  _WeakReferenceWrapper(T object)
      : _weakRef = JS('!', 'new WeakRef(#)', object);

  T? get target {
    var target = JS<T?>('', '#.deref()', _weakRef);
    // Coerce to null if JavaScript returns undefined.
    if (JS<bool>('!', 'target === void 0')) return null;
    return target;
  }
}

// Patch for Finalizer implementation.
@patch
class Finalizer<T> {
  @patch
  factory Finalizer(void Function(T) object) {
    return _FinalizationRegistryWrapper<T>(object);
  }
}

class _FinalizationRegistryWrapper<T> implements Finalizer<T> {
  final Object _registry;

  _FinalizationRegistryWrapper(void Function(T) callback)
      : _registry = JS('!', 'new FinalizationRegistry(#)',
            wrapZoneUnaryCallback(callback));

  void attach(Object value, T token, {Object? detach}) {
    if (detach != null) {
      JS('', '#.register(#, #, #)', _registry, value, token, detach);
    } else {
      JS('', '#.register(#, #)', _registry, value, token);
    }
  }

  void detach(Object detachToken) {
    JS('', '#.unregister(#)', _registry, detachToken);
  }
}

@patch
class int {
  @patch
  static int parse(String source,
      {int? radix, @deprecated int onError(String source)?}) {
    var value = tryParse(source, radix: radix);
    if (value != null) return value;
    if (onError != null) return onError(source);
    throw new FormatException(source);
  }

  @patch
  static int? tryParse(String source, {int? radix}) {
    return Primitives.parseInt(source, radix);
  }

  @patch
  factory int.fromEnvironment(String name, {int defaultValue = 0}) {
    // ignore: const_constructor_throws_exception
    throw UnsupportedError(
        'int.fromEnvironment can only be used as a const constructor');
  }

  @JSExportName('is')
  static bool _is_int(Object? o) {
    return JS<bool>('!', 'typeof $o == "number" && Math.floor($o) == $o');
  }

  @JSExportName('as')
  static Object? _as_int(Object? o) {
    // Avoid extra function call to core.int.is() by manually inlining.
    if (JS<bool>('!', '(typeof $o == "number" && Math.floor($o) == $o)')) {
      return o;
    }
    return dart.cast(o, dart.unwrapType(int));
  }
}

@patch
class double {
  @patch
  static double parse(String source,
      [@deprecated double onError(String source)?]) {
    var value = tryParse(source);
    if (value != null) return value;
    if (onError != null) return onError(source);
    throw new FormatException('Invalid double', source);
  }

  @patch
  static double? tryParse(String source) {
    return Primitives.parseDouble(source);
  }

  @JSExportName('is')
  static bool _is_double(Object? o) {
    return JS<bool>('!', 'typeof $o == "number"');
  }

  @JSExportName('as')
  static Object? _as_double(Object? o) {
    // Avoid extra function call to core.double.is() by manually inlining.
    if (JS<bool>('!', 'typeof $o == "number"')) return o;
    return dart.cast(o, dart.unwrapType(double));
  }
}

@patch
abstract class num implements Comparable<num> {
  @JSExportName('is')
  static bool _is_num(Object? o) {
    return JS<bool>('!', 'typeof $o == "number"');
  }

  @JSExportName('as')
  static Object? _as_num(Object? o) {
    // Avoid extra function call to core.num.is() by manually inlining.
    if (JS<bool>('!', 'typeof $o == "number"')) return o;
    return dart.cast(o, dart.unwrapType(num));
  }
}

@patch
class Error {
  @patch
  static String _objectToString(Object object) {
    return "Instance of '${dart.typeName(dart.getReifiedType(object))}'";
  }

  @patch
  static String _stringToSafeString(String string) {
    return JS("String", "JSON.stringify(#)", string);
  }

  @patch
  StackTrace? get stackTrace => dart.stackTraceForError(this);

  @patch
  static Never _throw(Object error, StackTrace stackTrace) {
    JS("", "throw #", dart.createErrorWithStack(error, stackTrace));
    throw "unreachable";
  }
}

// Patch for DateTime implementation.
@patch
class DateTime {
  @patch
  DateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc = false})
      : this._withValue(millisecondsSinceEpoch, isUtc: isUtc);

  @patch
  DateTime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch,
      {bool isUtc = false})
      : this._withValue(
            _microsecondInRoundedMilliseconds(microsecondsSinceEpoch),
            isUtc: isUtc);

  @patch
  DateTime._internal(int year, int month, int day, int hour, int minute,
      int second, int millisecond, int microsecond, bool isUtc)
      : isUtc = isUtc,
        _value = checkInt(Primitives.valueFromDecomposedDate(
            year,
            month,
            day,
            hour,
            minute,
            second,
            millisecond + _microsecondInRoundedMilliseconds(microsecond),
            isUtc));

  @patch
  DateTime._now()
      : isUtc = false,
        _value = Primitives.dateNow();

  @patch
  DateTime._nowUtc()
      : isUtc = true,
        _value = Primitives.dateNow();

  /// Rounds the given [microsecond] to the nearest milliseconds value.
  ///
  /// For example, invoked with argument `2600` returns `3`.
  static int _microsecondInRoundedMilliseconds(int microsecond) {
    return (microsecond / 1000).round();
  }

  @patch
  static int? _brokenDownDateToValue(int year, int month, int day, int hour,
      int minute, int second, int millisecond, int microsecond, bool isUtc) {
    return Primitives.valueFromDecomposedDate(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond + _microsecondInRoundedMilliseconds(microsecond),
        isUtc);
  }

  @patch
  String get timeZoneName {
    if (isUtc) return "UTC";
    return Primitives.getTimeZoneName(this);
  }

  @patch
  Duration get timeZoneOffset {
    if (isUtc) return Duration.zero;
    return Duration(minutes: Primitives.getTimeZoneOffsetInMinutes(this));
  }

  @patch
  DateTime add(Duration duration) {
    return DateTime._withValue(_value + duration.inMilliseconds, isUtc: isUtc);
  }

  @patch
  DateTime subtract(Duration duration) {
    return DateTime._withValue(_value - duration.inMilliseconds, isUtc: isUtc);
  }

  @patch
  Duration difference(DateTime other) {
    return Duration(milliseconds: _value - other.millisecondsSinceEpoch);
  }

  @patch
  int get millisecondsSinceEpoch => _value;

  @patch
  int get microsecondsSinceEpoch => _value * 1000;

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
  int get microsecond => 0;

  @patch
  int get weekday => Primitives.getWeekday(this);

  @patch
  bool operator ==(Object other) =>
      other is DateTime &&
      _value == other.millisecondsSinceEpoch &&
      isUtc == other.isUtc;

  @patch
  bool isBefore(DateTime other) => _value < other.millisecondsSinceEpoch;

  @patch
  bool isAfter(DateTime other) => _value > other.millisecondsSinceEpoch;

  @patch
  bool isAtSameMomentAs(DateTime other) =>
      _value == other.millisecondsSinceEpoch;

  @patch
  int compareTo(DateTime other) =>
      _value.compareTo(other.millisecondsSinceEpoch);
}

// Patch for Stopwatch implementation.
@patch
class Stopwatch {
  @patch
  static int _initTicker() {
    Primitives.initTicker();
    return Primitives.timerFrequency;
  }

  @patch
  static int _now() => Primitives.timerTicks();

  @patch
  int get elapsedMicroseconds {
    int ticks = elapsedTicks;
    if (_frequency == 1000000) return ticks;
    assert(_frequency == 1000);
    return ticks * 1000;
  }

  @patch
  int get elapsedMilliseconds {
    int ticks = elapsedTicks;
    if (_frequency == 1000) return ticks;
    assert(_frequency == 1000000);
    return ticks ~/ 1000;
  }
}

// Patch for List implementation.
@patch
class List<E> {
  @patch
  factory List.empty({bool growable = false}) {
    var list = JSArray<E>.of(JS('', 'new Array()'));
    if (!growable) JSArray.markFixedList(list);
    return list;
  }

  @patch
  factory List.filled(@nullCheck int length, E fill, {bool growable = false}) {
    var list = JSArray<E>.of(JS('', 'new Array(#)', length));
    JS('', '#.fill(#)', list, fill);
    if (!growable) JSArray.markFixedList(list);
    return list;
  }

  @patch
  factory List.from(Iterable elements, {bool growable = true}) {
    var list = JSArray<E>.of(JS('', '[]'));
    // Specialize the copy loop for the case that doesn't need a
    // runtime check.
    if (elements is Iterable<E>) {
      for (var e in elements) {
        // Unsafe add here to avoid extra casts and growable checks enforced by
        // the exposed add method.
        JS('', '#.push(#)', list, e);
      }
    } else {
      for (var e in elements) {
        // Unsafe add here to avoid extra casts and growable checks enforced by
        // the exposed add method.
        JS('', '#.push(#)', list, e as E);
      }
    }
    if (!growable) JSArray.markFixedList(list);
    return list;
  }

  @patch
  factory List.of(Iterable<E> elements, {bool growable = true}) {
    var list = JSArray<E>.of(JS('', '[]'));
    for (var e in elements) {
      // Unsafe add here to avoid extra casts and growable checks enforced by
      // the exposed add method.
      JS('', '#.push(#)', list, e);
    }
    if (!growable) JSArray.markFixedList(list);
    return list;
  }

  @patch
  factory List.generate(int length, E generator(int index),
      {bool growable = true}) {
    final result = JSArray<E>.of(JS('', 'new Array(#)', length));
    if (!growable) JSArray.markFixedList(result);
    for (int i = 0; i < length; i++) {
      // Unsafe assignment here to avoid extra casts enforced by the exposed
      // []= operator.
      JS('', '#[#] = #', result, i, generator(i));
    }
    return result;
  }

  @patch
  factory List.unmodifiable(Iterable elements) {
    var list = List<E>.from(elements);
    JSArray.markUnmodifiableList(list);
    return list;
  }
}

@patch
class Map<K, V> {
  @patch
  factory Map.unmodifiable(Map<dynamic, dynamic> other) {
    return UnmodifiableMapView<K, V>(Map<K, V>.from(other));
  }

  @patch
  factory Map() = LinkedMap<K, V>;
}

@patch
class String {
  @patch
  factory String.fromCharCodes(Iterable<int> charCodes,
      [int start = 0, int? end]) {
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
  factory String.fromEnvironment(String name, {String defaultValue = ""}) {
    // ignore: const_constructor_throws_exception
    throw UnsupportedError(
        'String.fromEnvironment can only be used as a const constructor');
  }

  static String _stringFromJSArray(
      /*=JSArray<int>*/ list, int start, int? endOrNull) {
    int len = list.length;
    int end = RangeError.checkValidRange(start, endOrNull, len);
    if (start > 0 || end < len) {
      list = list.sublist(start, end);
    }
    return Primitives.stringFromCharCodes(list);
  }

  static String _stringFromUint8List(
      NativeUint8List charCodes, int start, int? endOrNull) {
    int len = charCodes.length;
    int end = RangeError.checkValidRange(start, endOrNull, len);
    return Primitives.stringFromNativeUint8List(charCodes, start, end);
  }

  static String _stringFromIterable(
      Iterable<int> charCodes, int start, int? end) {
    if (start < 0) throw RangeError.range(start, 0, charCodes.length);
    if (end != null && end < start) {
      throw RangeError.range(end, start, charCodes.length);
    }
    var it = charCodes.iterator;
    for (int i = 0; i < start; i++) {
      if (!it.moveNext()) {
        throw RangeError.range(start, 0, i);
      }
    }
    var list = JSArray<int>.of(JS('', 'new Array()'));
    if (end == null) {
      while (it.moveNext()) list.add(it.current);
    } else {
      for (int i = start; i < end; i++) {
        if (!it.moveNext()) {
          throw RangeError.range(end, start, i);
        }
        list.add(it.current);
      }
    }
    return Primitives.stringFromCharCodes(list);
  }

  @JSExportName('is')
  static bool _is_String(Object? o) {
    return JS<bool>('!', 'typeof $o == "string"');
  }

  @JSExportName('as')
  static Object? _as_String(Object? o) {
    // Avoid extra function call to core.String.is() by manually inlining.
    if (JS<bool>('!', 'typeof $o == "string"')) return o;
    return dart.cast(o, dart.unwrapType(String));
  }
}

@patch
class bool {
  @patch
  factory bool.fromEnvironment(String name, {bool defaultValue = false}) {
    // ignore: const_constructor_throws_exception
    throw UnsupportedError(
        'bool.fromEnvironment can only be used as a const constructor');
  }

  @patch
  factory bool.hasEnvironment(String name) {
    // ignore: const_constructor_throws_exception
    throw UnsupportedError(
        'bool.hasEnvironment can only be used as a const constructor');
  }

  @patch
  static bool parse(String source, {bool caseSensitive = true}) =>
      Primitives.parseBool(source, caseSensitive) ??
      (throw FormatException("Invalid boolean", source));

  @patch
  static bool? tryParse(String source, {bool caseSensitive = true}) {
    return Primitives.parseBool(source, caseSensitive);
  }

  @patch
  int get hashCode => super.hashCode;

  @JSExportName('is')
  static bool _is_bool(Object? o) =>
      JS<bool>('!', '$o === true || $o === false');

  @JSExportName('as')
  static Object? _as_bool(Object? o) {
    // Avoid extra function call to core.bool.is() by manually inlining.
    if (JS<bool>("!", '$o === true || $o === false')) return o;
    return dart.cast(o, dart.unwrapType(bool));
  }
}

@patch
class RegExp {
  @patch
  factory RegExp(String source,
          {bool multiLine = false,
          bool caseSensitive = true,
          bool unicode = false,
          bool dotAll = false}) =>
      JSSyntaxRegExp(source,
          multiLine: multiLine,
          caseSensitive: caseSensitive,
          unicode: unicode,
          dotAll: dotAll);

  @patch
  static String escape(String text) => quoteStringForRegExp(text);
}

// Patch for 'identical' function.
@patch
bool identical(Object? a, Object? b) {
  return JS<bool>('!', '(# == null ? # == null : # === #)', a, b, a, b);
}

@patch
class StringBuffer {
  String _contents;

  @patch
  StringBuffer([Object content = ""]) : _contents = '$content';

  @patch
  int get length => _contents.length;

  @patch
  void write(Object? obj) {
    _writeString('$obj');
  }

  @patch
  void writeCharCode(int charCode) {
    _writeString(String.fromCharCode(charCode));
  }

  @patch
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    _contents = _writeAll(_contents, objects, separator);
  }

  @patch
  void writeln([Object? obj = ""]) {
    _writeString('$obj\n');
  }

  @patch
  void clear() {
    _contents = "";
  }

  @patch
  String toString() => Primitives.flattenString(_contents);

  void _writeString(@notNull String str) {
    _contents = JS<String>('!', '# + #', _contents, str);
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

  static String _writeOne(@notNull String string, Object? obj) {
    return JS<String>('!', '# + #', string, '$obj');
  }
}

// TODO(jmesserly): kernel expects to find this in our SDK.
class _CompileTimeError extends Error {
  final String _errorMsg;
  _CompileTimeError(this._errorMsg);
  String toString() => _errorMsg;
}

@patch
class NoSuchMethodError {
  final Object? _receiver;
  final Symbol _memberName;
  final List? _arguments;
  final Map<Symbol, dynamic>? _namedArguments;
  final Invocation? _invocation;

  @patch
  NoSuchMethodError(Object? receiver, Symbol memberName,
      List? positionalArguments, Map<Symbol, dynamic>? namedArguments)
      : _receiver = receiver,
        _memberName = memberName,
        _arguments = positionalArguments,
        _namedArguments = namedArguments,
        _invocation = null;

  @patch
  factory NoSuchMethodError.withInvocation(
          Object? receiver, Invocation invocation) =
      NoSuchMethodError._withInvocation;

  NoSuchMethodError._withInvocation(this._receiver, Invocation invocation)
      : _memberName = invocation.memberName,
        _arguments = invocation.positionalArguments,
        _namedArguments = invocation.namedArguments,
        _invocation = invocation;

  @patch
  String toString() {
    StringBuffer sb = StringBuffer('');
    String comma = '';
    var arguments = _arguments;
    if (arguments != null) {
      for (var argument in arguments) {
        sb.write(comma);
        sb.write(Error.safeToString(argument));
        comma = ', ';
      }
    }
    var namedArguments = _namedArguments;
    if (namedArguments != null) {
      namedArguments.forEach((Symbol key, var value) {
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
    var invocation = _invocation;
    var failureMessage = (invocation is dart.InvocationImpl)
        ? invocation.failureMessage
        : 'method not found';
    return "NoSuchMethodError: '$memberName'\n"
        "$failureMessage\n"
        "Receiver: ${receiverText}\n"
        "Arguments: [$actualParameters]";
  }
}

@patch
class Uri {
  @patch
  static Uri get base {
    String uri = Primitives.currentUri();
    if (uri != null) return Uri.parse(uri);
    throw UnsupportedError("'Uri.base' is not supported");
  }
}

@patch
class _Uri {
  @patch
  static bool get _isWindows => _isWindowsCached;

  static final bool _isWindowsCached = JS(
      'bool',
      'typeof process != "undefined" && '
          'Object.prototype.toString.call(process) == "[object process]" && '
          'process.platform == "win32"');

  // Matches a String that _uriEncodes to itself regardless of the kind of
  // component.  This corresponds to [_unreservedTable], i.e. characters that
  // are not encoded by any encoding table.
  static final RegExp _needsNoEncoding = RegExp(r'^[\-\.0-9A-Z_a-z~]*$');

  /**
   * This is the internal implementation of JavaScript's encodeURI function.
   * It encodes all characters in the string [text] except for those
   * that appear in [canonicalTable], and returns the escaped string.
   */
  @patch
  static String _uriEncode(List<int> canonicalTable, String text,
      Encoding encoding, bool spaceToPlus) {
    if (identical(encoding, utf8) && _needsNoEncoding.hasMatch(text)) {
      return text;
    }

    // Encode the string into bytes then generate an ASCII only string
    // by percent encoding selected bytes.
    StringBuffer result = StringBuffer('');
    var bytes = encoding.encode(text);
    for (int i = 0; i < bytes.length; i++) {
      int byte = bytes[i];
      if (byte < 128 &&
          ((canonicalTable[byte >> 4] & (1 << (byte & 0x0f))) != 0)) {
        result.writeCharCode(byte);
      } else if (spaceToPlus && byte == _SPACE) {
        result.write('+');
      } else {
        const String hexDigits = '0123456789ABCDEF';
        result.write('%');
        result.write(hexDigits[(byte >> 4) & 0x0f]);
        result.write(hexDigits[byte & 0x0f]);
      }
    }
    return result.toString();
  }
}

@patch
class StackTrace {
  @patch
  static StackTrace get current {
    return dart.stackTrace(JS('', 'Error()'));
  }
}

// TODO(jmesserly): this class is supposed to be obsolete in Strong Mode, but
// the front-end crashes without it
class _DuplicatedFieldInitializerError {
  final String _name;

  _DuplicatedFieldInitializerError(this._name);

  toString() => "Error: field '$_name' is already initialized.";
}
