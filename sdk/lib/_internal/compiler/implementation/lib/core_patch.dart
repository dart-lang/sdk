// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:core classes.

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
    String key = getRuntimeTypeString(this);
    return getOrCreateCachedRuntimeType(key);
  }
}

// Patch for Function implementation.
patch class Function {
  patch static apply(Function function,
                     List positionalArguments,
                     [Map<String,Dynamic> namedArguments]) {
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
  patch static int parse(String source) => Primitives.parseInt(source);
}

patch class double {
  patch static double parse(String source) => Primitives.parseDouble(source);
}

patch class NoSuchMethodError {
  patch static String _objectToString(Object object) {
    return Primitives.objectToString(object);
  }
}


// Patch for Date implementation.
patch class _DateImpl {
  patch _DateImpl(int year,
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

  patch _DateImpl.now()
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
  patch static int _frequency() => 1000;
  patch static int _now() => Primitives.dateNow();
}


// Patch for List implementation.
patch class _ListImpl<E> {
  patch factory List([int length]) => Primitives.newList(length);

  patch factory List.from(Iterable<E> other) {
    var result = new List();
    for (var element in other) {
      result.add(element);
    }
    return result;
  }
}


patch class String {
  patch factory String.fromCharCodes(List<int> charCodes) {
    checkNull(charCodes);
    if (!isJsArray(charCodes)) {
      if (charCodes is !List) throw new ArgumentError(charCodes);
      charCodes = new List.from(charCodes);
    }
    return Primitives.stringFromCharCodes(charCodes);
  }
}

// Patch for String implementation.
patch class Strings {
  patch static String join(List<String> strings, String separator) {
    checkNull(strings);
    checkNull(separator);
    if (separator is !String) throw new ArgumentError(separator);
    return stringJoinUnchecked(_toJsStringArray(strings), separator);
  }

  patch static String concatAll(List<String> strings) {
    return stringJoinUnchecked(_toJsStringArray(strings), "");
  }

  static List _toJsStringArray(List<String> strings) {
    checkNull(strings);
    var array;
    final length = strings.length;
    if (isJsArray(strings)) {
      array = strings;
      for (int i = 0; i < length; i++) {
        final string = strings[i];
        checkNull(string);
        if (string is !String) throw new ArgumentError(string);
      }
    } else {
      array = new List(length);
      for (int i = 0; i < length; i++) {
        final string = strings[i];
        checkNull(string);
        if (string is !String) throw new ArgumentError(string);
        array[i] = string;
      }
    }
    return array;
  }
}
