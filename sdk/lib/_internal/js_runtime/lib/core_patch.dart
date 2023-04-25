// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:core classes.
import 'dart:_internal' hide Symbol, LinkedList, LinkedListEntry;
import 'dart:_internal' as _symbol_dev;
import 'dart:_interceptors';
import 'dart:_js_helper'
    show
        assertUnreachable,
        boolConversionCheck,
        checkInt,
        Closure,
        ConstantMap,
        convertDartClosureToJS,
        getRuntimeType,
        JsLinkedHashMap,
        jsonEncodeNative,
        JSSyntaxRegExp,
        objectHashCode,
        Primitives,
        quoteStringForRegExp,
        getTraceFromException,
        RuntimeError,
        wrapException,
        wrapZoneUnaryCallback,
        TrustedGetRuntimeType;

import 'dart:_foreign_helper' show JS;
import 'dart:_native_typed_data' show NativeUint8List;
import 'dart:_rti' show getRuntimeTypeOfDartObject;

import 'dart:convert' show Encoding, utf8;
import 'dart:typed_data' show Endian, Uint8List, Uint16List;

// These are the additional parts of this patch library:
part 'bigint_patch.dart';

String _symbolToString(Symbol symbol) =>
    _symbol_dev.Symbol.getName(symbol as _symbol_dev.Symbol);

Map<String, dynamic>? _symbolMapToStringMap(Map<Symbol, dynamic>? map) {
  if (map == null) return null;
  var result = new Map<String, dynamic>();
  map.forEach((Symbol key, value) {
    result[_symbolToString(key)] = value;
  });
  return result;
}

@patch
int identityHashCode(Object? object) => objectHashCode(object);

// Patch for Object implementation.
@patch
class Object {
  @patch
  bool operator ==(Object other) => identical(this, other);

  @patch
  int get hashCode => Primitives.objectHashCode(this);

  @patch
  String toString() => Primitives.objectToHumanReadableString(this);

  @patch
  dynamic noSuchMethod(Invocation invocation) {
    throw new NoSuchMethodError.withInvocation(this, invocation);
  }

  @patch
  Type get runtimeType => getRuntimeTypeOfDartObject(this);
}

@patch
class Null {
  @patch
  int get hashCode => super.hashCode;
}

// Patch for Function implementation.
@patch
class Function {
  @patch
  static apply(Function function, List<dynamic>? positionalArguments,
      [Map<Symbol, dynamic>? namedArguments]) {
    return Primitives.applyFunction(
        function,
        positionalArguments,
        // Use this form so that if namedArguments is always null, we can
        // tree-shake _symbolMapToStringMap.
        namedArguments == null ? null : _symbolMapToStringMap(namedArguments));
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
    // `WeakMap.prototype.get` does not check on reading.
    _checkType(object);
    return JS('', '#.get(#)', _jsWeakMap, object);
  }

  @patch
  void operator []=(Object object, T? value) {
    // `WeakMap.prototype.set` checks for null, bool, num and string, but not
    // the classes we use for records.
    // TODO(51366): Make `is Record` more efficient.
    if (object is Record) {
      _badExpandoKey(object);
    }
    JS('void', '#.set(#, #)', _jsWeakMap, object, value);
  }

  static void _checkType(object) {
    if (object == null ||
        object is bool ||
        object is num ||
        object is String ||
        // TODO(51366): Make `is Record` more efficient.
        object is Record) {
      _badExpandoKey(object);
    }
  }

  static Never _badExpandoKey(object) {
    throw ArgumentError.value(object, 'object',
        "Expandos are not allowed on strings, numbers, bools, records or null");
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

  _WeakReferenceWrapper(T object) : _weakRef = JS('', 'new WeakRef(#)', object);

  T? get target => JS('', '#.deref()', _weakRef);
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
      : _registry = JS('', 'new FinalizationRegistry(#)',
            convertDartClosureToJS(wrapZoneUnaryCallback(callback), 1));

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
    int? value = tryParse(source, radix: radix);
    if (value != null) return value;
    if (onError != null) return onError(source);
    throw new FormatException(source);
  }

  @patch
  static int? tryParse(String source, {int? radix}) {
    return Primitives.parseInt(source, radix);
  }
}

@patch
class double {
  @patch
  static double parse(String source,
      [@deprecated double onError(String source)?]) {
    double? value = tryParse(source);
    if (value != null) return value;
    if (onError != null) return onError(source);
    throw new FormatException('Invalid double', source);
  }

  @patch
  static double? tryParse(String source) {
    return Primitives.parseDouble(source);
  }
}

@patch
class Error {
  @patch
  static String _objectToString(Object object) {
    return Primitives.safeToString(object);
  }

  @patch
  static String _stringToSafeString(String string) {
    return Primitives.stringSafeToString(string);
  }

  @patch
  StackTrace? get stackTrace => Primitives.extractStackTrace(this);

  @patch
  static Never _throw(Object error, StackTrace stackTrace) {
    error = wrapException(error);
    JS('void', '#.stack = #', error, stackTrace.toString());
    JS('', 'throw #', error);
    throw "unreachable";
  }
}

// Patch for DateTime implementation.
@patch
class DateTime {
  @patch
  DateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc = false})
      // `0 + millisecondsSinceEpoch` forces the inferred result to be non-null.
      : this._withValue(0 + millisecondsSinceEpoch, isUtc: isUtc);

  @patch
  DateTime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch,
      {bool isUtc = false})
      : this._withValue(
            _microsecondInRoundedMilliseconds(microsecondsSinceEpoch),
            isUtc: isUtc);

  @patch
  DateTime._internal(int year, int month, int day, int hour, int minute,
      int second, int millisecond, int microsecond, bool isUtc)
      // checkBool is manually inlined here because dart2js doesn't inline it
      // and [isUtc] is usually a constant.
      : this.isUtc = isUtc is bool
            ? isUtc
            : throw new ArgumentError.value(isUtc, 'isUtc'),
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
    if (isUtc) return new Duration();
    return new Duration(minutes: Primitives.getTimeZoneOffsetInMinutes(this));
  }

  @patch
  DateTime add(Duration duration) {
    return new DateTime._withValue(_value + duration.inMilliseconds,
        isUtc: isUtc);
  }

  @patch
  DateTime subtract(Duration duration) {
    return new DateTime._withValue(_value - duration.inMilliseconds,
        isUtc: isUtc);
  }

  @patch
  Duration difference(DateTime other) {
    return new Duration(milliseconds: _value - other.millisecondsSinceEpoch);
  }

  @patch
  int get millisecondsSinceEpoch => _value;

  @patch
  int get microsecondsSinceEpoch => 1000 * _value;

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
  factory List.filled(int length, E fill, {bool growable = false}) {
    var result = growable
        ? new JSArray<E>.growable(length)
        : new JSArray<E>.fixed(length);
    if (length != 0 && fill != null) {
      // TODO(sra): Consider using `Array.fill`.
      for (int i = 0; i < result.length; i++) {
        // Unchecked assignment equivalent to `result[i] = fill`;
        // `fill` is checked statically at call site.
        JS('', '#[#] = #', result, i, fill);
      }
    }
    return result;
  }

  @patch
  factory List.empty({bool growable = false}) {
    return growable ? new JSArray<E>.growable(0) : new JSArray<E>.fixed(0);
  }

  @patch
  factory List.from(Iterable elements, {bool growable = true}) {
    List<E> list = <E>[];
    for (E e in elements) {
      list.add(e);
    }
    if (growable) return list;
    return makeListFixedLength(list);
  }

  @patch
  factory List.of(Iterable<E> elements, {bool growable = true}) {
    if (growable == true) return List._of(elements);
    if (growable == false) return List._fixedOf(elements);

    // [growable] may be `null` in legacy mode. Fail with the same error as if
    // [growable] was used in a condition position in spec mode.
    boolConversionCheck(growable);
    assertUnreachable();
  }

  factory List._ofArray(Iterable<E> elements) {
    return JSArray<E>.markGrowable(
        JS('effects:none;depends:no-static', '#.slice(0)', elements));
  }

  factory List._of(Iterable<E> elements) {
    if (elements is JSArray) return List._ofArray(elements);
    // This is essentially `<E>[]..addAll(elements)`, but without a check for
    // modifiability or ConcurrentModificationError on the receiver.
    List<E> list = <E>[];
    for (final e in elements) {
      list.add(e);
    }
    return list;
  }

  factory List._fixedOf(Iterable<E> elements) {
    return makeListFixedLength(List._of(elements));
  }

  @patch
  factory List.generate(int length, E generator(int index),
      {bool growable = true}) {
    final result = growable
        ? new JSArray<E>.growable(length)
        : new JSArray<E>.fixed(length);
    for (int i = 0; i < length; i++) {
      result[i] = generator(i);
    }
    return result;
  }

  @patch
  factory List.unmodifiable(Iterable elements) {
    var result = List<E>.from(elements, growable: false);
    return makeFixedListUnmodifiable(result);
  }
}

@patch
class Map<K, V> {
  @patch
  factory Map.unmodifiable(Map other) = ConstantMap<K, V>.from;

  @patch
  factory Map() = JsLinkedHashMap<K, V>;
}

@patch
class String {
  @patch
  factory String.fromCharCodes(Iterable<int> charCodes,
      [int start = 0, int? end]) {
    if (charCodes is JSArray) {
      // Type promotion doesn't work unless the check is `is JSArray<int>`,
      // which is more expensive.
      // TODO(41383): Optimize `is JSArray<int>` rather than do weird 'casts'.
      JSArray array = JS('JSArray', '#', charCodes);
      return _stringFromJSArray(array, start, end);
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

  static String _stringFromJSArray(JSArray list, int start, int? endOrNull) {
    int len = list.length;
    int end = RangeError.checkValidRange(start, endOrNull, len);
    if (start > 0 || end < len) {
      list = JS('JSArray', '#.slice(#, #)', list, start, end);
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
  int get hashCode => super.hashCode;

  @patch
  static bool parse(String source, {bool caseSensitive = true}) =>
      tryParse(source, caseSensitive: caseSensitive) ??
      (throw FormatException("Invalid boolean", source));

  @patch
  static bool? tryParse(String source, {bool caseSensitive = true}) {
    return Primitives.parseBool(source, caseSensitive);
  }
}

@patch
class RegExp {
  @pragma('dart2js:noInline')
  @patch
  factory RegExp(String source,
          {bool multiLine = false,
          bool caseSensitive = true,
          bool unicode = false,
          bool dotAll = false}) =>
      new JSSyntaxRegExp(source,
          multiLine: multiLine,
          caseSensitive: caseSensitive,
          unicode: unicode,
          dotAll: dotAll);

  @patch
  static String escape(String text) => quoteStringForRegExp(text);
}

// Patch for 'identical' function.
@pragma(
    'dart2js:noInline') // No inlining since we recognize the call in optimizer.
@patch
bool identical(Object? a, Object? b) {
  return JS('bool', '(# == null ? # == null : # === #)', a, b, a, b);
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
    _writeString(new String.fromCharCode(charCode));
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

  void _writeString(String str) {
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

  static String _writeOne(String string, Object? obj) {
    return Primitives.stringConcatUnchecked(string, '$obj');
  }
}

@patch
class NoSuchMethodError {
  final Object? _receiver;
  final Symbol _memberName;
  final List? _arguments;
  final Map<Symbol, dynamic>? _namedArguments;
  final List? _existingArgumentNames;

  @patch
  factory NoSuchMethodError.withInvocation(
          Object? receiver, Invocation invocation) =>
      NoSuchMethodError._(receiver, invocation.memberName,
          invocation.positionalArguments, invocation.namedArguments);

  @patch
  NoSuchMethodError(Object? receiver, Symbol memberName,
      List? positionalArguments, Map<Symbol, dynamic>? namedArguments,
      [List? existingArgumentNames = null])
      : this._(receiver, memberName, positionalArguments, namedArguments,
            existingArgumentNames);

  NoSuchMethodError._(Object? receiver, Symbol memberName,
      List? positionalArguments, Map<Symbol, dynamic>? namedArguments,
      [List? existingArgumentNames = null])
      : _receiver = receiver,
        _memberName = memberName,
        _arguments = positionalArguments,
        _namedArguments = namedArguments,
        _existingArgumentNames = existingArgumentNames;

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
    var existingArgumentNames = _existingArgumentNames;
    if (existingArgumentNames == null) {
      return "NoSuchMethodError: method not found: '$memberName'\n"
          "Receiver: ${receiverText}\n"
          "Arguments: [$actualParameters]";
    } else {
      String formalParameters = existingArgumentNames.join(', ');
      return "NoSuchMethodError: incorrect number of arguments passed to "
          "method named '$memberName'\n"
          "Receiver: ${receiverText}\n"
          "Tried calling: $memberName($actualParameters)\n"
          "Found: $memberName($formalParameters)";
    }
  }
}

class _CompileTimeError extends Error {
  final String _errorMsg;
  // TODO(sigmund): consider calling `JS('', 'debugger')`.
  _CompileTimeError(this._errorMsg);
  String toString() => _errorMsg;
}

@patch
class Uri {
  @patch
  static Uri get base {
    String? uri = Primitives.currentUri();
    if (uri != null) return Uri.parse(uri);
    throw new UnsupportedError("'Uri.base' is not supported");
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
  static final RegExp _needsNoEncoding = new RegExp(r'^[\-\.0-9A-Z_a-z~]*$');

  /// This is the internal implementation of JavaScript's encodeURI function.
  /// It encodes all characters in the string [text] except for those
  /// that appear in [canonicalTable], and returns the escaped string.
  @patch
  static String _uriEncode(List<int> canonicalTable, String text,
      Encoding encoding, bool spaceToPlus) {
    if (identical(encoding, utf8) && _needsNoEncoding.hasMatch(text)) {
      return text;
    }

    // Encode the string into bytes then generate an ASCII only string
    // by percent encoding selected bytes.
    StringBuffer result = new StringBuffer('');
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

bool _hasErrorStackProperty = JS('bool', 'new Error().stack != void 0');

@patch
class StackTrace {
  @patch
  @pragma('dart2js:noInline')
  static StackTrace get current {
    if (_hasErrorStackProperty) {
      return getTraceFromException(JS('', 'new Error()'));
    }
    // Fallback if new Error().stack does not exist.
    // Currently only required for IE 11.
    try {
      throw '';
    } catch (_, stackTrace) {
      return stackTrace;
    }
  }
}

/// Used by Fasta to report a runtime error when a final field with an
/// initializer is also initialized in a generative constructor.
///
/// Note: in strong mode, this is a compile-time error and this class becomes
/// obsolete.
class _DuplicatedFieldInitializerError extends Error {
  final String _name;

  _DuplicatedFieldInitializerError(this._name);

  toString() => "Error: field '$_name' is already initialized.";
}

/// Creates an invocation object used in noSuchMethod forwarding stubs.
///
/// The signature is hardwired to the kernel nodes generated in the
/// `Dart2jsTarget` and read in the `KernelSsaGraphBuilder`.
external Invocation _createInvocationMirror(
    String memberName,
    List typeArguments,
    List positionalArguments,
    Map<String, dynamic> namedArguments,
    int kind);
