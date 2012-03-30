// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('js_helper');

#import('coreimpl.dart');

#source('constant_map.dart');
#source('native_helper.dart');
#source('regexp_helper.dart');
#source('string_helper.dart');

/**
 * Returns true if both arguments are numbers.
 *
 * If only the first argument is a number, an
 * [IllegalArgumentException] with the other argument is thrown.
 */
bool checkNumbers(var a, var b) {
  if (a is num) {
    if (b is num) {
      return true;
    } else {
      checkNull(b);
      throw new IllegalArgumentException(b);
    }
  }
  return false;
}


bool isJsArray(var value) {
  return value !== null && JS('bool', @'#.constructor === Array', value);
}


add(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# + #', a, b);
  } else if (a is String) {
    // TODO(lrn): Remove when we disable String.operator+
    b = b.toString();
    if (b is String) {
      return JS('String', @'# + #', a, b);
    }
    checkNull(b);
    throw new IllegalArgumentException(b);
  }
  return UNINTERCEPTED(a + b);
}

div(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# / #', a, b);
  }
  return UNINTERCEPTED(a / b);
}

mul(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# * #', a, b);
  }
  return UNINTERCEPTED(a * b);
}

sub(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# - #', a, b);
  }
  return UNINTERCEPTED(a - b);
}

mod(var a, var b) {
  if (checkNumbers(a, b)) {
    // Euclidean Modulo.
    int result = JS('num', @'# % #', a, b);
    if (result == 0) return 0;  // Make sure we don't return -0.0.
    if (result > 0) return result;
    if (b < 0) {
      return result - b;
    } else {
      return result + b;
    }
  }
  return UNINTERCEPTED(a % b);
}

tdiv(var a, var b) {
  if (checkNumbers(a, b)) {
    return (a / b).truncate();
  }
  return UNINTERCEPTED(a ~/ b);
}

eq(var a, var b) {
  if (JS('bool', @'typeof # === "object"', a)) {
    if (JS_HAS_EQUALS(a)) {
      return UNINTERCEPTED(a == b) === true;
    } else {
      return JS('bool', @'# === #', a, b);
    }
  }
  // TODO(lrn): is NaN === NaN ? Is -0.0 === 0.0 ?
  return JS('bool', @'# === #', a, b);
}

eqq(var a, var b) {
  return JS('bool', @'# === #', a, b);
}

eqNull(var a) {
  if (JS('bool', @'typeof # === "object"', a)) {
    if (JS_HAS_EQUALS(a)) {
      return UNINTERCEPTED(a == null) === true;
    } else {
      return false;
    }
  } else {
    return JS('bool', @'typeof # === "undefined"', a);
  }
}

gt(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# > #', a, b);
  }
  return UNINTERCEPTED(a > b);
}

ge(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# >= #', a, b);
  }
  return UNINTERCEPTED(a >= b);
}

lt(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# < #', a, b);
  }
  return UNINTERCEPTED(a < b);
}

le(var a, var b) {
  if (checkNumbers(a, b)) {
    return JS('bool', @'# <= #', a, b);
  }
  return UNINTERCEPTED(a <= b);
}

shl(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    if (b < 0) throw new IllegalArgumentException(b);
    return JS('num', @'# << #', a, b);
  }
  return UNINTERCEPTED(a << b);
}

shr(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    if (b < 0) throw new IllegalArgumentException(b);
    return JS('num', @'# >> #', a, b);
  }
  return UNINTERCEPTED(a >> b);
}

and(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', @'# & #', a, b);
  }
  return UNINTERCEPTED(a & b);
}

or(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', @'# | #', a, b);
  }
  return UNINTERCEPTED(a | b);
}

xor(var a, var b) {
  // TODO(floitsch): inputs must be integers.
  if (checkNumbers(a, b)) {
    return JS('num', @'# ^ #', a, b);
  }
  return UNINTERCEPTED(a ^ b);
}

not(var a) {
  if (JS('bool', @'typeof # === "number"', a)) return JS('num', @'~#', a);
  return UNINTERCEPTED(~a);
}

neg(var a) {
  if (JS('bool', @'typeof # === "number"', a)) return JS('num', @'-#', a);
  return UNINTERCEPTED(-a);
}

index(var a, var index) {
  if (a is String || isJsArray(a)) {
    if (index is !int) {
      if (index is !num) throw new IllegalArgumentException(index);
      if (index.truncate() !== index) throw new IllegalArgumentException(index);
    }
    if (index < 0 || index >= a.length) {
      throw new IndexOutOfRangeException(index);
    }
    return JS('Object', @'#[#]', a, index);
  }
  return UNINTERCEPTED(a[index]);
}

void indexSet(var a, var index, var value) {
  if (isJsArray(a)) {
    if (!(index is int)) {
      throw new IllegalArgumentException(index);
    }
    if (index < 0 || index >= a.length) {
      throw new IndexOutOfRangeException(index);
    }
    checkMutable(a, 'indexed set');
    JS('Object', @'#[#] = #', a, index, value);
    return;
  }
  UNINTERCEPTED(a[index] = value);
}

checkMutable(list, reason) {
  if (JS('bool', @'!!(#.immutable$list)', list)) {
    throw new UnsupportedOperationException(reason);
  }
}

builtin$add$1(var receiver, var value) {
  if (isJsArray(receiver)) {
    checkGrowable(receiver, 'add');
    JS('Object', @'#.push(#)', receiver, value);
    return;
  }
  return UNINTERCEPTED(receiver.add(value));
}

builtin$removeLast$0(var receiver) {
  if (isJsArray(receiver)) {
    checkGrowable(receiver, 'removeLast');
    if (receiver.length === 0) throw new IndexOutOfRangeException(-1);
    return JS('Object', @'#.pop()', receiver);
  }
  return UNINTERCEPTED(receiver.removeLast());
}

builtin$filter$1(var receiver, var predicate) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.filter(predicate));
  } else {
    return Collections.filter(receiver, [], predicate);
  }
}


builtin$get$length(var receiver) {
  if (receiver is String || isJsArray(receiver)) {
    return JS('num', @'#.length', receiver);
  } else {
    return UNINTERCEPTED(receiver.length);
  }
}

builtin$set$length(receiver, newLength) {
  if (isJsArray(receiver)) {
    checkNull(newLength); // TODO(ahe): This is not specified but co19 tests it.
    if (newLength is !int) throw new IllegalArgumentException(newLength);
    if (newLength < 0) throw new IndexOutOfRangeException(newLength);
    checkGrowable(receiver, 'set length');
    JS('void', @'#.length = #', receiver, newLength);
  } else {
    UNINTERCEPTED(receiver.length = newLength);
  }
  return newLength;
}

checkGrowable(list, reason) {
  if (JS('bool', @'!!(#.fixed$length)', list)) {
    throw new UnsupportedOperationException(reason);
  }
}

builtin$toString$0(var value) {
  if (JS('bool', @'typeof # == "object"', value)) {
    if (isJsArray(value)) {
      return Collections.collectionToString(value);
    } else {
      return UNINTERCEPTED(value.toString());
    }
  }
  if (JS('bool', @'# === 0 && (1 / #) < 0', value, value)) {
    return '-0.0';
  }
  if (value === null) return 'null';
  if (JS('bool', @'typeof # == "function"', value)) {
    return 'Closure';
  }
  return JS('string', @'String(#)', value);
}


builtin$iterator$0(receiver) {
  if (isJsArray(receiver)) {
    return new ListIterator(receiver);
  }
  return UNINTERCEPTED(receiver.iterator());
}

class ListIterator<T> implements Iterator<T> {
  int i;
  List<T> list;
  ListIterator(List<T> this.list) : i = 0;
  bool hasNext() => i < JS('int', @'#.length', list);
  T next() {
    if (!hasNext()) throw new NoMoreElementsException();
    var value = JS('Object', @'#[#]', list, i);
    i += 1;
    return value;
  }
}

builtin$charCodeAt$1(var receiver, int index) {
  if (receiver is String) {
    if (index is !num) throw new IllegalArgumentException(index);
    if (index < 0) throw new IndexOutOfRangeException(index);
    if (index >= receiver.length) throw new IndexOutOfRangeException(index);
    return JS('int', @'#.charCodeAt(#)', receiver, index);
  } else {
    return UNINTERCEPTED(receiver.charCodeAt(index));
  }
}

builtin$isEmpty$0(receiver) {
  if (receiver is String || isJsArray(receiver)) {
    return JS('bool', @'#.length === 0', receiver);
  }
  return UNINTERCEPTED(receiver.isEmpty());
}

class Primitives {
  static void printString(String string) {
    var hasConsole = JS('bool', @'typeof console == "object"');
    if (hasConsole) {
      JS('void', @'console.log(#)', string);
    } else {
      JS('void', @'write(#)', string);
      JS('void', @'write("\n")');
    }
  }

  /** [: @"$".charCodeAt(0) :] */
  static final int DOLLAR_CHAR_VALUE = 36;

  static String objectToString(Object object) {
    String name = JS('String', @'#.constructor.name', object);
    if (name === null) {
      name = JS('String', @'#.match(/^\s*function\s*\$?(\S*)\s*\(/)[1]',
                JS('String', @'#.constructor.toString()', object));
    } else {
      if (name.charCodeAt(0) === DOLLAR_CHAR_VALUE) name = name.substring(1);
    }
    return "Instance of '$name'";
  }

  static List newList(length) {
    if (length === null) return JS('Object', @'new Array()');
    if ((length is !int) || (length < 0)) {
      throw new IllegalArgumentException(length);
    }
    var result = JS('Object', @'new Array(#)', length);
    JS('void', @'#.fixed$length = #', result, true);
    return result;
  }

  static num dateNow() => JS('num', @'Date.now()');

  static String stringFromCharCodes(charCodes) {
    for (var i in charCodes) {
      if (i is !int) throw new IllegalArgumentException(i);
    }
    return JS('String', @'String.fromCharCode.apply(#, #)', null, charCodes);
  }

  static valueFromDecomposedDate(years, month, day, hours, minutes, seconds,
                                 milliseconds, isUtc) {
    checkInt(years);
    checkInt(month);
    if (month < 1 || 12 < month) throw new IllegalArgumentException(month);
    checkInt(day);
    if (day < 1 || 31 < day) throw new IllegalArgumentException(day);
    checkInt(hours);
    if (hours < 0 || 24 < hours) throw new IllegalArgumentException(hours);
    checkInt(minutes);
    if (minutes < 0 || 59 < minutes) {
      throw new IllegalArgumentException(minutes);
    }
    checkInt(seconds);
    if (seconds < 0 || 59 < seconds) {
      // TODO(ahe): Leap seconds?
      throw new IllegalArgumentException(seconds);
    }
    checkInt(milliseconds);
    if (milliseconds < 0 || 999 < milliseconds) {
      throw new IllegalArgumentException(milliseconds);
    }
    checkBool(isUtc);
    var jsMonth = month - 1;
    var value;
    if (isUtc) {
      value = JS('num', @'Date.UTC(#, #, #, #, #, #, #)',
                 years, jsMonth, day, hours, minutes, seconds, milliseconds);
    } else {
      value = JS('num', @'new Date(#, #, #, #, #, #, #).valueOf()',
                 years, jsMonth, day, hours, minutes, seconds, milliseconds);
    }
    if (value.isNaN()) throw new IllegalArgumentException('');
    if (years <= 0 || years < 100) return patchUpY2K(value, years, isUtc);
    return value;
  }

  static patchUpY2K(value, years, isUtc) {
    var date = JS('Object', @'new Date(#)', value);
    if (isUtc) {
      JS('num', @'#.setUTCFullYear(#)', date, years);
    } else {
      JS('num', @'#.setFullYear(#)', date, years);
    }
    return JS('num', @'#.valueOf()', date);
  }

  // Lazily keep a JS Date stored in the JS object.
  static lazyAsJsDate(receiver) {
    if (JS('bool', @'#.date === (void 0)', receiver)) {
      JS('void', @'#.date = new Date(#)', receiver, receiver.value);
    }
    return JS('Date', @'#.date', receiver);
  }

  static getYear(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCFullYear()', lazyAsJsDate(receiver))
      : JS('int', @'#.getFullYear()', lazyAsJsDate(receiver));
  }

  static getMonth(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCMonth()', lazyAsJsDate(receiver)) + 1
      : JS('int', @'#.getMonth()', lazyAsJsDate(receiver)) + 1;
  }

  static getDay(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCDate()', lazyAsJsDate(receiver))
      : JS('int', @'#.getDate()', lazyAsJsDate(receiver));
  }

  static getHours(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCHours()', lazyAsJsDate(receiver))
      : JS('int', @'#.getHours()', lazyAsJsDate(receiver));
  }

  static getMinutes(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCMinutes()', lazyAsJsDate(receiver))
      : JS('int', @'#.getMinutes()', lazyAsJsDate(receiver));
  }

  static getSeconds(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCSeconds()', lazyAsJsDate(receiver))
      : JS('int', @'#.getSeconds()', lazyAsJsDate(receiver));
  }

  static getMilliseconds(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCMilliseconds()', lazyAsJsDate(receiver))
      : JS('int', @'#.getMilliseconds()', lazyAsJsDate(receiver));
  }

  static getWeekday(receiver) {
    return (receiver.timeZone.isUtc)
      ? JS('int', @'#.getUTCDay()', lazyAsJsDate(receiver))
      : JS('int', @'#.getDay()', lazyAsJsDate(receiver));
  }

  static valueFromDateString(str) {
    checkNull(str);
    if (str is !String) throw new IllegalArgumentException(str);
    var value = JS('num', @'Date.parse(#)', str);
    if (value.isNaN()) throw new IllegalArgumentException(str);
    return value;
  }
}

builtin$compareTo$1(a, b) {
  if (checkNumbers(a, b)) {
    if (a < b) {
      return -1;
    } else if (a > b) {
      return 1;
    } else if (a == b) {
      if (a == 0) {
        bool aIsNegative = a.isNegative();
        bool bIsNegative = b.isNegative();
        if (aIsNegative == bIsNegative) return 0;
        if (aIsNegative) return -1;
        return 1;
      }
      return 0;
    } else if (a.isNaN()) {
      if (b.isNaN()) {
        return 0;
      }
      return 1;
    } else {
      return -1;
    }
  } else if (a is String) {
    if (b is !String) throw new IllegalArgumentException(b);
    return JS('bool', @'# == #', a, b) ? 0
      : JS('bool', @'# < #', a, b) ? -1 : 1;
  } else {
    return UNINTERCEPTED(a.compareTo(b));
  }
}

/**
 * Called by generated code to throw an illegal-argument exception,
 * for example, if a non-integer index is given to an optimized
 * indexed access.
 */
iae(argument) {
  throw new IllegalArgumentException(argument);
}

/**
 * Called by generated code to throw an index-out-of-range exception,
 * for example, if a bounds check fails in an optimized indexed
 * access.
 */
ioore(index) {
  throw new IndexOutOfRangeException(index);
}

builtin$addAll$1(receiver, collection) {
  if (!isJsArray(receiver)) return UNINTERCEPTED(receiver.addAll(collection));

  // TODO(ahe): Use for-in when it is implemented correctly.
  var iterator = collection.iterator();
  while (iterator.hasNext()) {
    receiver.add(iterator.next());
  }
}

builtin$addLast$1(receiver, value) {
  if (!isJsArray(receiver)) return UNINTERCEPTED(receiver.addLast(value));

  checkGrowable(receiver, 'addLast');
  JS('Object', @'#.push(#)', receiver, value);
}

builtin$clear$0(receiver) {
  if (!isJsArray(receiver)) return UNINTERCEPTED(receiver.clear());
  receiver.length = 0;
}

builtin$forEach$1(receiver, f) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.forEach(f));
  } else {
    return Collections.forEach(receiver, f);
  }
}

builtin$map$1(receiver, f) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.map(f));
  } else {
    return Collections.map(receiver, [], f);
  }
}

builtin$getRange$2(receiver, start, length) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.getRange(start, length));
  }
  if (0 === length) return [];
  checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
  if (start is !int) throw new IllegalArgumentException(start);
  if (length is !int) throw new IllegalArgumentException(length);
  if (length < 0) throw new IllegalArgumentException(length);
  if (start < 0) throw new IndexOutOfRangeException(start);
  var end = start + length;
  if (end > receiver.length) {
    throw new IndexOutOfRangeException(length);
  }
  if (length < 0) throw new IllegalArgumentException(length);
  return JS('Object', @'#.slice(#, #)', receiver, start, end);
}

builtin$indexOf$1(receiver, element) {
  if (isJsArray(receiver) || receiver is String) {
    return builtin$indexOf$2(receiver, element, 0);
  }
  return UNINTERCEPTED(receiver.indexOf(element));
}

builtin$indexOf$2(receiver, element, start) {
  if (isJsArray(receiver)) {
    if (start is !int) throw new IllegalArgumentException(start);
    var length = JS('num', @'#.length', receiver);
    return Arrays.indexOf(receiver, element, start, length);
  } else if (receiver is String) {
    checkNull(element);
    if (start is !int) throw new IllegalArgumentException(start);
    if (element is !String) throw new IllegalArgumentException(element);
    if (start < 0) return -1; // TODO(ahe): Is this correct?
    return JS('int', @'#.indexOf(#, #)', receiver, element, start);
  }
  return UNINTERCEPTED(receiver.indexOf(element, start));
}

builtin$insertRange$2(receiver, start, length) {
  if (isJsArray(receiver)) {
    return builtin$insertRange$3(receiver, start, length, null);
  }
  return UNINTERCEPTED(receiver.insertRange(start, length));
}

builtin$insertRange$3(receiver, start, length, initialValue) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.insertRange(start, length, initialValue));
  }
  return listInsertRange(receiver, start, length, initialValue);
}

listInsertRange(receiver, start, length, initialValue) {
  if (length === 0) {
    return;
  }
  checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
  if (length is !int) throw new IllegalArgumentException(length);
  if (length < 0) throw new IllegalArgumentException(length);
  if (start is !int) throw new IllegalArgumentException(start);

  var receiverLength = JS('num', @'#.length', receiver);
  if (start < 0 || start > receiverLength) {
    throw new IndexOutOfRangeException(start);
  }
  receiver.length = receiverLength + length;
  Arrays.copy(receiver,
              start,
              receiver,
              start + length,
              receiverLength - start);
  if (initialValue !== null) {
    for (int i = start; i < start + length; i++) {
      receiver[i] = initialValue;
    }
  }
  receiver.length = receiverLength + length;
}

builtin$last$0(receiver) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.last());
  }
  return receiver[receiver.length - 1];
}

builtin$lastIndexOf$1(receiver, element) {
  if (isJsArray(receiver)) {
    var start = JS('num', @'#.length', receiver);
    return Arrays.lastIndexOf(receiver, element, start);
  } else if (receiver is String) {
    checkNull(element);
    if (element is !String) throw new IllegalArgumentException(element);
    return JS('int', @'#.lastIndexOf(#)', receiver, element);
  }
  return UNINTERCEPTED(receiver.lastIndexOf(element));
}

builtin$lastIndexOf$2(receiver, element, start) {
  if (isJsArray(receiver)) {
    return Arrays.lastIndexOf(receiver, element, start);
  } else if (receiver is String) {
    checkNull(element);
    if (element is !String) throw new IllegalArgumentException(element);
    if (start !== null) {
      if (start is !num) throw new IllegalArgumentException(start);
      if (start < 0) return -1;
      if (start >= receiver.length) {
        if (element == "") return receiver.length;
        start = receiver.length - 1;
      }
    }
    return stringLastIndexOfUnchecked(receiver, element, start);
  }
  return UNINTERCEPTED(receiver.lastIndexOf(element, start));
}

stringLastIndexOfUnchecked(receiver, element, start)
  => JS('int', @'#.lastIndexOf(#, #)', receiver, element, start);

builtin$removeRange$2(receiver, start, length) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.removeRange(start, length));
  }
  checkGrowable(receiver, 'removeRange');
  if (length == 0) {
    return;
  }
  checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
  if (start is !int) throw new IllegalArgumentException(start);
  if (length is !int) throw new IllegalArgumentException(length);
  if (length < 0) throw new IllegalArgumentException(length);
  var receiverLength = JS('num', @'#.length', receiver);
  if (start < 0 || start >= receiverLength) {
    throw new IndexOutOfRangeException(start);
  }
  if (start + length > receiverLength) {
    throw new IndexOutOfRangeException(start + length);
  }
  Arrays.copy(receiver,
              start + length,
              receiver,
              start,
              receiverLength - length - start);
  receiver.length = receiverLength - length;
}

builtin$setRange$3(receiver, start, length, from) {
  if (isJsArray(receiver)) {
    return builtin$setRange$4(receiver, start, length, from, 0);
  }
  return UNINTERCEPTED(receiver.setRange(start, length, from));
}

builtin$setRange$4(receiver, start, length, from, startFrom) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.setRange(start, length, from, startFrom));
  }

  checkMutable(receiver, 'indexed set');
  if (length === 0) return;
  checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(from); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(startFrom); // TODO(ahe): This is not specified but co19 tests it.
  if (start is !int) throw new IllegalArgumentException(start);
  if (length is !int) throw new IllegalArgumentException(length);
  if (startFrom is !int) throw new IllegalArgumentException(startFrom);
  if (length < 0) throw new IllegalArgumentException(length);
  if (start < 0) throw new IndexOutOfRangeException(start);
  if (start + length > receiver.length) {
    throw new IndexOutOfRangeException(start + length);
  }

  Arrays.copy(from, startFrom, receiver, start, length);
}

builtin$some$1(receiver, f) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.some(f));
  } else {
    return Collections.some(receiver, f);
  }
}

builtin$every$1(receiver, f) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.every(f));
  } else {
    return Collections.every(receiver, f);
  }
}

builtin$sort$1(receiver, compare) {
  if (!isJsArray(receiver)) return UNINTERCEPTED(receiver.sort(compare));

  checkMutable(receiver, 'sort');
  DualPivotQuicksort.sort(receiver, compare);
}

checkNull(object) {
  if (object === null) throw new NullPointerException();
  return object;
}

checkNum(value) {
  if (value is !num) {
    checkNull(value);
    throw new IllegalArgumentException(value);
  }
  return value;
}

checkInt(value) {
  if (value is !int) {
    checkNull(value);
    throw new IllegalArgumentException(value);
  }
  return value;
}

checkBool(value) {
  if (value is !bool) {
    checkNull(value);
    throw new IllegalArgumentException(value);
  }
  return value;
}

checkString(value) {
  if (value is !String) {
    checkNull(value);
    throw new IllegalArgumentException(value);
  }
  return value;
}

builtin$isNegative$0(receiver) {
  if (receiver is num) {
    return (receiver === 0) ? (1 / receiver) < 0 : receiver < 0;
  } else {
    return UNINTERCEPTED(receiver.isNegative());
  }
}

builtin$isNaN$0(receiver) {
  if (receiver is num) {
    return JS('bool', @'isNaN(#)', receiver);
  } else {
    return UNINTERCEPTED(receiver.isNegative());
  }
}

builtin$remainder$1(a, b) {
  if (checkNumbers(a, b)) {
    return JS('num', @'# % #', a, b);
  } else {
    return UNINTERCEPTED(a.remainder(b));
  }
}

builtin$abs$0(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.abs());

  return JS('num', @'Math.abs(#)', receiver);
}

builtin$toInt$0(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.toInt());

  if (receiver.isNaN()) throw new BadNumberFormatException('NaN');

  if (receiver.isInfinite()) throw new BadNumberFormatException('Infinity');

  var truncated = receiver.truncate();
  return JS('bool', @'# == -0.0', truncated) ? 0 : truncated;
}

builtin$ceil$0(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.ceil());

  return JS('num', @'Math.ceil(#)', receiver);
}

builtin$floor$0(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.floor());

  return JS('num', @'Math.floor(#)', receiver);
}

builtin$isInfinite$0(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.isInfinite());

  return JS('bool', @'# == Infinity', receiver)
    || JS('bool', @'# == -Infinity', receiver);
}

builtin$negate$0(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.negate());

  return JS('num', @'-#', receiver);
}

builtin$round$0(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.round());

  if (JS('bool', @'# < 0', receiver)) {
    return JS('num', @'-Math.round(-#)', receiver);
  } else {
    return JS('num', @'Math.round(#)', receiver);
  }
}

builtin$toDouble$0(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.toDouble());

  // TODO(ahe): Just return receiver?
  return JS('double', @'# + 0', receiver);
}

builtin$truncate$0(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.truncate());

  return receiver < 0 ? receiver.ceil() : receiver.floor();
}

builtin$toStringAsFixed$1(receiver, fractionDigits) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toStringAsFixed(fractionDigits));
  }
  checkNum(fractionDigits);

  String result = JS('String', @'#.toFixed(#)', receiver, fractionDigits);
  if (receiver == 0 && receiver.isNegative()) return "-$result";
  return result;
}

builtin$toStringAsExponential$1(receiver, fractionDigits) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toStringAsExponential(fractionDigits));
  }
  if (fractionDigits !== null) checkNum(fractionDigits);

  String result = JS('String', @'#.toExponential(#)',
                     receiver, fractionDigits);
  if (receiver == 0 && receiver.isNegative()) return "-$result";
  return result;
}

builtin$toStringAsPrecision$1(receiver, fractionDigits) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toStringAsPrecision(fractionDigits));
  }
  checkNum(fractionDigits);

  String result = JS('String', @'#.toPrecision(#)',
                     receiver, fractionDigits);
  if (receiver == 0 && receiver.isNegative()) return "-$result";
  return result;
}

builtin$toRadixString$1(receiver, radix) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toRadixString(radix));
  }
  checkNum(radix);

  return JS('String', @'#.toString(#)', receiver, radix);
}

builtin$allMatches$1(receiver, str) {
  if (receiver is !String) return UNINTERCEPTED(receiver.allMatches(str));
  checkString(str);
  return allMatchesInStringUnchecked(receiver, str);
}

builtin$concat$1(receiver, other) {
  if (receiver is !String) return UNINTERCEPTED(receiver.concat(other));

  if (other is !String) throw new IllegalArgumentException(other);
  return JS('String', @'# + #', receiver, other);
}

builtin$contains$1(receiver, other) {
  if (receiver is !String) {
    return UNINTERCEPTED(receiver.contains(other));
  }
  return builtin$contains$2(receiver, other, 0);
}

builtin$contains$2(receiver, other, startIndex) {
  if (receiver is !String) {
    return UNINTERCEPTED(receiver.contains(other, startIndex));
  }
  checkNull(other);
  return stringContainsUnchecked(receiver, other, startIndex);
}

builtin$endsWith$1(receiver, other) {
  if (receiver is !String) return UNINTERCEPTED(receiver.endsWith(other));

  checkString(other);
  int receiverLength = receiver.length;
  int otherLength = other.length;
  if (otherLength > receiverLength) return false;
  return other == receiver.substring(receiverLength - otherLength);
}

builtin$replaceAll$2(receiver, from, to) {
  if (receiver is !String) return UNINTERCEPTED(receiver.replaceAll(from, to));

  checkString(to);
  return stringReplaceAllUnchecked(receiver, from, to);
}

builtin$replaceFirst$2(receiver, from, to) {
  if (receiver is !String) {
    return UNINTERCEPTED(receiver.replaceFirst(from, to));
  }
  checkString(to);
  return stringReplaceFirstUnchecked(receiver, from, to);
}

builtin$split$1(receiver, pattern) {
  if (receiver is !String) return UNINTERCEPTED(receiver.split(pattern));
  checkNull(pattern);
  return stringSplitUnchecked(receiver, pattern);
}

builtin$splitChars$0(receiver) {
  if (receiver is !String) return UNINTERCEPTED(receiver.splitChars());

  return JS('List', @'#.split("")', receiver);
}

builtin$startsWith$1(receiver, other) {
  if (receiver is !String) return UNINTERCEPTED(receiver.startsWith(other));
  checkString(other);

  int length = other.length;
  if (length > receiver.length) return false;
  return JS('bool', @'# == #', other,
            JS('String', @'#.substring(0, #)', receiver, length));
}

builtin$substring$1(receiver, startIndex) {
  if (receiver is !String) return UNINTERCEPTED(receiver.substring(startIndex));

  return builtin$substring$2(receiver, startIndex, null);
}

builtin$substring$2(receiver, startIndex, endIndex) {
  if (receiver is !String) {
    return UNINTERCEPTED(receiver.substring(startIndex, endIndex));
  }
  checkNum(startIndex);
  var length = receiver.length;
  if (endIndex === null) endIndex = length;
  checkNum(endIndex);
  if (startIndex < 0 ) throw new IndexOutOfRangeException(startIndex);
  if (startIndex > endIndex) throw new IndexOutOfRangeException(startIndex);
  if (endIndex > length) throw new IndexOutOfRangeException(endIndex);
  return substringUnchecked(receiver, startIndex, endIndex);
}

substringUnchecked(receiver, startIndex, endIndex)
  => JS('String', @'#.substring(#, #)', receiver, startIndex, endIndex);


builtin$toLowerCase$0(receiver) {
  if (receiver is !String) return UNINTERCEPTED(receiver.toLowerCase());

  return JS('String', @'#.toLowerCase()', receiver);
}

builtin$toUpperCase$0(receiver) {
  if (receiver is !String) return UNINTERCEPTED(receiver.toUpperCase());

  return JS('String', @'#.toUpperCase()', receiver);
}

builtin$trim$0(receiver) {
  if (receiver is !String) return UNINTERCEPTED(receiver.trim());

  return JS('String', @'#.trim()', receiver);
}

class MathNatives {
  static int parseInt(str) {
    checkString(str);
    if (!JS('bool',
            @'/^\s*[+-]?(?:0[xX][abcdefABCDEF0-9]+|\d+)\s*$/.test(#)',
            str)) {
      throw new BadNumberFormatException(str);
    }
    var trimmed = str.trim();
    var base = 10;;
    if ((trimmed.length > 2 && (trimmed[1] == 'x' || trimmed[1] == 'X')) ||
        (trimmed.length > 3 && (trimmed[2] == 'x' || trimmed[2] == 'X'))) {
      base = 16;
    }
    var ret = JS('num', @'parseInt(#, #)', trimmed, base);
    if (ret.isNaN()) throw new BadNumberFormatException(str);
    return ret;
  }

  static double parseDouble(String str) {
    checkString(str);
    var ret = JS('num', @'parseFloat(#)', str);
    if (ret == 0 && (str.startsWith("0x") || str.startsWith("0X"))) {
      // TODO(ahe): This is unspecified, but tested by co19.
      ret = JS('num', @'parseInt(#)', str);
    }
    if (ret.isNaN() && str != 'NaN' && str != '-NaN') {
      throw new BadNumberFormatException(str);
    }
    return ret;
  }

  static double sqrt(num value)
    => JS('double', @'Math.sqrt(#)', checkNum(value));

  static double sin(num value)
    => JS('double', @'Math.sin(#)', checkNum(value));

  static double cos(num value)
    => JS('double', @'Math.cos(#)', checkNum(value));

  static double tan(num value)
    => JS('double', @'Math.tan(#)', checkNum(value));

  static double acos(num value)
    => JS('double', @'Math.acos(#)', checkNum(value));

  static double asin(num value)
    => JS('double', @'Math.asin(#)', checkNum(value));

  static double atan(num value)
    => JS('double', @'Math.atan(#)', checkNum(value));

  static double atan2(num a, num b)
    => JS('double', @'Math.atan2(#, #)', checkNum(a), checkNum(b));

  static double exp(num value)
    => JS('double', @'Math.exp(#)', checkNum(value));

  static double log(num value)
    => JS('double', @'Math.log(#)', checkNum(value));

  static num pow(num value, num exponent) {
    checkNum(value);
    checkNum(exponent);
    return JS('num', @'Math.pow(#, #)', value, exponent);
  }

  static double random() => JS('double', @'Math.random()');
}

/**
 * This is the [Jenkins hash function][1] but using masking to keep
 * values in SMI range. This was inspired by jmesserly's work in
 * Frog.
 *
 * [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
 */
builtin$hashCode$0(receiver) {
  // TODO(ahe): This method shouldn't have to use JS. Update when our
  // optimizations are smarter.
  if (receiver is num) return JS('int', @'# & 0x1FFFFFFF', receiver);
  if (receiver is !String) return UNINTERCEPTED(receiver.hashCode());
  int hash = 0;
  int length = JS('int', @'#.length', receiver);
  for (int i = 0; i < length; i++) {
    hash = 0x1fffffff & (hash + JS('int', @'#.charCodeAt(#)', receiver, i));
    hash = 0x1fffffff & (hash + JS('int', @'# << #', 0x0007ffff & hash, 10));
    hash ^= hash >> 6;
  }
  hash = 0x1fffffff & (hash + JS('int', @'# << #', 0x03ffffff & hash, 3));
  hash ^= hash >> 11;
  return 0x1fffffff & (hash + JS('int', @'# << #', 0x00003fff & hash, 15));
}

// TODO(ahe): Dynamic may be overridden.
builtin$get$dynamic(receiver) => receiver;

/**
 * Called by generated code to capture the stacktrace before throwing
 * an exception.
 */
captureStackTrace(ex) {
  var jsError = JS('Object', @'new Error()');
  JS('void', @'#.dartException = #', jsError, ex);
  JS('void', @'''#.toString = #''', jsError,
     DART_CLOSURE_TO_JS(toStringWrapper));
  return jsError;
}

/**
 * This method is installed as JavaScript toString method on exception
 * objects in [captureStackTrace]. So JavaScript 'this' binds to an
 * instance of JavaScript Error to which we have added a property
 * 'dartException' which holds a Dart object.
 */
toStringWrapper() => JS('Object', @'this.dartException').toString();

builtin$charCodes$0(receiver) {
  if (receiver is !String) return UNINTERCEPTED(receiver.charCodes());
  int len = receiver.length;
  List<int> result = new List<int>(len);
  for (int i = 0; i < len; i++) {
    result[i] = receiver.charCodeAt(i);
  }
  return result;
}

makeLiteralListConst(list) {
  JS('bool', @'#.immutable$list = #', list, true);
  JS('bool', @'#.fixed$length = #', list, true);
  return list;
}

/**
 * Called from catch blocks in generated code to extract the Dart
 * exception from the thrown value. The thrown value may have been
 * created by [captureStackTrace] or it may be a 'native' JS
 * exception.
 *
 * Some native exceptions are mapped to new Dart instances, others are
 * returned unmodified.
 */
unwrapException(ex) {
  // Note that we are checking if the object has the property. If it
  // has, it could be set to null if the thrown value is null.
  if (JS('bool', @'"dartException" in #', ex)) {
    return JS('Object', @'#.dartException', ex);
  } else if (JS('bool', @'# instanceof TypeError', ex)) {
    // TODO(ahe): ex.type is Chrome specific.
    var type = JS('String', @'#.type', ex);
    var jsArguments = JS('Object', @'#.arguments', ex);
    var name = jsArguments[0];
    if (type == 'property_not_function' ||
        type == 'called_non_callable' ||
        type == 'non_object_property_call' ||
        type == 'non_object_property_load') {
      if (name !== null && name.startsWith(@'$call$')) {
        return new ObjectNotClosureException();
      } else {
        return new NullPointerException();
      }
    } else if (type == 'undefined_method') {
      if (name is String && name.startsWith(@'$call$')) {
        return new ObjectNotClosureException();
      } else {
        return new NoSuchMethodException('', name, []);
      }
    }
  } else if (JS('bool', @'# instanceof RangeError', ex)) {
    var message = JS('String', @'#.message', ex);
    if (message.contains('call stack')) {
      return new StackOverflowException();
    }
  }
  return ex;
}

/**
 * Called by generated code to fetch the stack trace from an
 * exception.
 */
StackTrace getTraceFromException(exception) {
  return new StackTrace(JS("var", @"#.stack", exception));
}

class StackTrace {
  var stack;
  StackTrace(this.stack);
  String toString() => stack != null ? stack : '';
}


/**
 * Called by generated code to build a map literal. [keyValuePairs] is
 * a list of key, value, key, value, ..., etc.
 */
makeLiteralMap(List keyValuePairs) {
  Iterator iterator = keyValuePairs.iterator();
  Map result = new LinkedHashMap();
  while (iterator.hasNext()) {
    String key = iterator.next();
    var value = iterator.next();
    result[key] = value;
  }
  return result;
}

invokeClosure(Function closure,
              var isolate,
              int numberOfArguments,
              var arg1,
              var arg2) {
  if (numberOfArguments == 0) {
    return JS_CALL_IN_ISOLATE(isolate, () => closure());
  } else if (numberOfArguments == 1) {
    return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1));
  } else if (numberOfArguments == 2) {
    return JS_CALL_IN_ISOLATE(isolate, () => closure(arg1, arg2));
  } else {
    throw new Exception(
        'Unsupported number of arguments for wrapped closure');
  }
}

/**
 * Called by generated code to convert a Dart closure to a JS
 * closure when the Dart closure is passed to the DOM.
 */
convertDartClosureToJS(closure) {
  if (closure === null) return null;
  var function = JS('var', @'#.$identity', closure);
  if (JS('bool', @'!!#', function)) return function;

  function = JS("var", @"""function() {
    return #(#, #, arguments.length, arguments[0], arguments[1]);
  }""",
  DART_CLOSURE_TO_JS(invokeClosure),
  closure,
  JS_CURRENT_ISOLATE());

  JS('void', @'#.$identity = #', closure, function);
  return function;
}

/**
 * Super class for Dart closures.
 */
class Closure implements Function {
  String toString() => "Closure";
}

bool jsHasOwnProperty(var jsObject, String property) {
  return JS('bool', @'#.hasOwnProperty(#)', jsObject, property);
}

jsPropertyAccess(var jsObject, String property) {
  return JS('var', @'#[#]', jsObject, property);
}

/**
 * Called at the end of unaborted switch cases to get the singleton
 * FallThroughError exception that will be thrown.
 */
getFallThroughError() => const FallThroughError();

builtin$isEven$0(receiver) {
  if (receiver is !int) return UNINTERCEPTED(receiver.isEven());
  return (receiver & 1) === 0;
}

builtin$isOdd$0(receiver) {
  if (receiver is !int) return UNINTERCEPTED(receiver.isOdd());
  return (receiver & 1) === 1;
}

/**
 * Represents the type Dynamic. The compiler treats this specially.
 */
interface Dynamic {
}

/**
 * Represents the type of Null. The compiler treats this specially.
 */
class Null {
  factory Null() {
    throw new UnsupportedOperationException('new Null()');
  }
}

builtin$get$toString(receiver) => () => builtin$toString$0(receiver);
