// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:core classes.

import 'dart:_interceptors';
import 'dart:_js_helper' show checkNull,
                              getRuntimeTypeString,
                              isJsArray,
                              JSSyntaxRegExp,
                              Primitives,
                              TypeImpl,
                              stringJoinUnchecked,
                              JsStringBuffer;

// Patch for 'print' function.
patch void print(var object) {
  if (object is String) {
    Primitives.printString(object);
  } else {
    Primitives.printString(object.toString());
  }
}

// Patch for Object implementation.
patch class Object {
  patch int get hashCode => Primitives.objectHashCode(this);

  patch String toString() => Primitives.objectToString(this);

  patch dynamic noSuchMethod(InvocationMirror invocation) {
    throw new NoSuchMethodError(this,
                                invocation.memberName,
                                invocation.positionalArguments,
                                invocation.namedArguments);
  }

  patch Type get runtimeType {
    String type = getRuntimeTypeString(this);
    return new TypeImpl(type);
  }
}

// Patch for Function implementation.
patch class Function {
  patch static apply(Function function,
                     List positionalArguments,
                     [Map<String,dynamic> namedArguments]) {
    return Primitives.applyFunction(
        function, positionalArguments, namedArguments);
  }
}

// Patch for Expando implementation.
patch class Expando<T> {
  patch Expando([String name]) : this.name = name;

  patch T operator[](Object object) {
    var values = Primitives.getProperty(object, _EXPANDO_PROPERTY_NAME);
    return (values == null) ? null : Primitives.getProperty(values, _getKey());
  }

  patch void operator[]=(Object object, T value) {
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

patch class int {
  patch static int parse(String source,
                         { int radix,
                           int onError(String source) }) {
    return Primitives.parseInt(source, radix, onError);
  }
}

patch class double {
  patch static double parse(String source, [int handleError(String source)]) {
    return Primitives.parseDouble(source, handleError);
  }
}

patch class Error {
  patch static String _objectToString(Object object) {
    return Primitives.objectToString(object);
  }
}


// Patch for DateTime implementation.
patch class DateTime {
  patch DateTime._internal(int year,
                           int month,
                           int day,
                           int hour,
                           int minute,
                           int second,
                           int millisecond,
                           bool isUtc)
      : this.isUtc = checkNull(isUtc),
        millisecondsSinceEpoch = Primitives.valueFromDecomposedDate(
            year, month, day, hour, minute, second, millisecond, isUtc) {
    Primitives.lazyAsJsDate(this);
  }

  patch DateTime._now()
      : isUtc = false,
        millisecondsSinceEpoch = Primitives.dateNow() {
    Primitives.lazyAsJsDate(this);
  }

  patch static int _brokenDownDateToMillisecondsSinceEpoch(
      int year, int month, int day, int hour, int minute, int second,
      int millisecond, bool isUtc) {
    return Primitives.valueFromDecomposedDate(
        year, month, day, hour, minute, second, millisecond, isUtc);
  }

  patch String get timeZoneName {
    if (isUtc) return "UTC";
    return Primitives.getTimeZoneName(this);
  }

  patch Duration get timeZoneOffset {
    if (isUtc) return new Duration();
    return new Duration(minutes: Primitives.getTimeZoneOffsetInMinutes(this));
  }

  patch int get year => Primitives.getYear(this);

  patch int get month => Primitives.getMonth(this);

  patch int get day => Primitives.getDay(this);

  patch int get hour => Primitives.getHours(this);

  patch int get minute => Primitives.getMinutes(this);

  patch int get second => Primitives.getSeconds(this);

  patch int get millisecond => Primitives.getMilliseconds(this);

  patch int get weekday => Primitives.getWeekday(this);
}


// Patch for Stopwatch implementation.
patch class _StopwatchImpl {
  patch static int _frequency() => 1000000;
  patch static int _now() => Primitives.numMicroseconds();
}


// Patch for List implementation.
patch class List<E> {
  patch factory List([int length = 0]) {
    // Explicit type test is necessary to protect Primitives.newGrowableList in
    // unchecked mode.
    if ((length is !int) || (length < 0)) {
      throw new ArgumentError("Length must be a positive integer: $length.");
    }
    return Primitives.newGrowableList(length);
  }

  patch factory List.fixedLength(int length, {E fill: null}) {
    // Explicit type test is necessary to protect Primitives.newFixedList in
    // unchecked mode.
    if ((length is !int) || (length < 0)) {
      throw new ArgumentError("Length must be a positive integer: $length.");
    }
    List result = Primitives.newFixedList(length);
    if (length != 0 && fill != null) {
      for (int i = 0; i < result.length; i++) {
        result[i] = fill;
      }
    }
    return result;
  }

  /**
   * Creates an extendable list of the given [length] where each entry is
   * filled with [fill].
   */
  patch factory List.filled(int length, E fill) {
    // Explicit type test is necessary to protect Primitives.newGrowableList in
    // unchecked mode.
    if ((length is !int) || (length < 0)) {
      throw new ArgumentError("Length must be a positive integer: $length.");
    }
    List result = Primitives.newGrowableList(length);
    if (length != 0 && fill != null) {
      for (int i = 0; i < result.length; i++) {
        result[i] = fill;
      }
    }
    return result;
  }
}


patch class String {
  patch factory String.fromCharCodes(List<int> charCodes) {
    if (!isJsArray(charCodes)) {
      if (charCodes is !List) throw new ArgumentError(charCodes);
      charCodes = new List.from(charCodes);
    }
    return Primitives.stringFromCharCodes(charCodes);
  }
}

// Patch for String implementation.
patch class Strings {
  patch static String join(Iterable<String> strings, String separator) {
    checkNull(strings);
    if (separator is !String) throw new ArgumentError(separator);
    return stringJoinUnchecked(_toJsStringArray(strings), separator);
  }

  patch static String concatAll(Iterable<String> strings) {
    return stringJoinUnchecked(_toJsStringArray(strings), "");
  }

  static List _toJsStringArray(Iterable<String> strings) {
    checkNull(strings);
    var array;
    if (!isJsArray(strings)) {
      strings = new List.from(strings);
    }
    final length = strings.length;
    for (int i = 0; i < length; i++) {
      final string = strings[i];
      if (string is !String) throw new ArgumentError(string);
    }
    return strings;
  }
}

patch class RegExp {
  patch factory RegExp(String pattern,
                       {bool multiLine: false,
                        bool caseSensitive: true})
    => new JSSyntaxRegExp(pattern,
                          multiLine: multiLine,
                          caseSensitive: caseSensitive);
}

// Patch for 'identical' function.
patch bool identical(Object a, Object b) {
  return Primitives.identicalImplementation(a, b);
}

patch class StringBuffer {
  patch factory StringBuffer([Object content = ""]) {
    return new JsStringBuffer(content);
  }
}
