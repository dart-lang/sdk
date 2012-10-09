// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('dart:_interceptors');

#import('dart:coreimpl');

add$1(var receiver, var value) {
  if (isJsArray(receiver)) {
    checkGrowable(receiver, 'add');
    JS('Object', r'#.push(#)', receiver, value);
    return;
  }
  return UNINTERCEPTED(receiver.add(value));
}

removeAt$1(var receiver, var index) {
  if (isJsArray(receiver)) {
    if (index is !int) throw new ArgumentError(index);
    if (index < 0 || index >= receiver.length) {
      throw new IndexOutOfRangeException(index);
    }
    checkGrowable(receiver, 'removeAt');
    return JS("Object", r'#.splice(#, 1)[0]', receiver, index);
  }
  return UNINTERCEPTED(receiver.removeAt(index));
}

removeLast(var receiver) {
  if (isJsArray(receiver)) {
    checkGrowable(receiver, 'removeLast');
    if (receiver.length === 0) throw new IndexOutOfRangeException(-1);
    return JS('Object', r'#.pop()', receiver);
  }
  return UNINTERCEPTED(receiver.removeLast());
}

filter(var receiver, var predicate) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.filter(predicate));
  } else {
    return Collections.filter(receiver, [], predicate);
  }
}

get$length(var receiver) {
  if (receiver is String || isJsArray(receiver)) {
    return JS('num', r'#.length', receiver);
  } else {
    return UNINTERCEPTED(receiver.length);
  }
}

set$length(receiver, newLength) {
  if (isJsArray(receiver)) {
    checkNull(newLength); // TODO(ahe): This is not specified but co19 tests it.
    if (newLength is !int) throw new ArgumentError(newLength);
    if (newLength < 0) throw new IndexOutOfRangeException(newLength);
    checkGrowable(receiver, 'set length');
    JS('void', r'#.length = #', receiver, newLength);
  } else {
    UNINTERCEPTED(receiver.length = newLength);
  }
  return newLength;
}

toString(var value) {
  if (JS('bool', r'typeof # == "object" && # !== null', value, value)) {
    if (isJsArray(value)) {
      return Collections.collectionToString(value);
    } else {
      return UNINTERCEPTED(value.toString());
    }
  }
  if (JS('bool', r'# === 0 && (1 / #) < 0', value, value)) {
    return '-0.0';
  }
  if (value === null) return 'null';
  if (JS('bool', r'typeof # == "function"', value)) {
    return 'Closure';
  }
  return JS('string', r'String(#)', value);
}

iterator(receiver) {
  if (isJsArray(receiver)) {
    return new ListIterator(receiver);
  }
  return UNINTERCEPTED(receiver.iterator());
}

charCodeAt(var receiver, int index) {
  if (receiver is String) {
    if (index is !num) throw new ArgumentError(index);
    if (index < 0) throw new IndexOutOfRangeException(index);
    if (index >= receiver.length) throw new IndexOutOfRangeException(index);
    return JS('int', r'#.charCodeAt(#)', receiver, index);
  } else {
    return UNINTERCEPTED(receiver.charCodeAt(index));
  }
}

isEmpty(receiver) {
  if (receiver is String || isJsArray(receiver)) {
    return JS('bool', r'#.length === 0', receiver);
  }
  return UNINTERCEPTED(receiver.isEmpty());
}

compareTo(a, b) {
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
    if (b is !String) throw new ArgumentError(b);
    return JS('bool', r'# == #', a, b) ? 0
      : JS('bool', r'# < #', a, b) ? -1 : 1;
  } else {
    return UNINTERCEPTED(a.compareTo(b));
  }
}

addAll(receiver, collection) {
  if (!isJsArray(receiver)) return UNINTERCEPTED(receiver.addAll(collection));

  // TODO(ahe): Use for-in when it is implemented correctly.
  var iterator = collection.iterator();
  while (iterator.hasNext()) {
    receiver.add(iterator.next());
  }
}

addLast(receiver, value) {
  if (!isJsArray(receiver)) return UNINTERCEPTED(receiver.addLast(value));

  checkGrowable(receiver, 'addLast');
  JS('Object', r'#.push(#)', receiver, value);
}

clear(receiver) {
  if (!isJsArray(receiver)) return UNINTERCEPTED(receiver.clear());
  receiver.length = 0;
}

forEach(receiver, f) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.forEach(f));
  } else {
    return Collections.forEach(receiver, f);
  }
}

map(receiver, f) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.map(f));
  } else {
    return Collections.map(receiver, [], f);
  }
}

reduce(receiver, initialValue, f) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.reduce(initialValue, f));
  } else {
    return Collections.reduce(receiver, initialValue, f);
  }
}

getRange(receiver, start, length) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.getRange(start, length));
  }
  if (0 === length) return [];
  checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
  if (start is !int) throw new ArgumentError(start);
  if (length is !int) throw new ArgumentError(length);
  if (length < 0) throw new ArgumentError(length);
  if (start < 0) throw new IndexOutOfRangeException(start);
  var end = start + length;
  if (end > receiver.length) {
    throw new IndexOutOfRangeException(length);
  }
  if (length < 0) throw new ArgumentError(length);
  return JS('Object', r'#.slice(#, #)', receiver, start, end);
}

indexOf$1(receiver, element) {
  if (isJsArray(receiver)) {
    var length = JS('num', r'#.length', receiver);
    return Arrays.indexOf(receiver, element, 0, length);
  } else if (receiver is String) {
    checkNull(element);
    if (element is !String) throw new ArgumentError(element);
    return JS('int', r'#.indexOf(#)', receiver, element);
  }
  return UNINTERCEPTED(receiver.indexOf(element));
}

indexOf$2(receiver, element, start) {
  if (isJsArray(receiver)) {
    if (start is !int) throw new ArgumentError(start);
    var length = JS('num', r'#.length', receiver);
    return Arrays.indexOf(receiver, element, start, length);
  } else if (receiver is String) {
    checkNull(element);
    if (start is !int) throw new ArgumentError(start);
    if (element is !String) throw new ArgumentError(element);
    if (start < 0) return -1; // TODO(ahe): Is this correct?
    return JS('int', r'#.indexOf(#, #)', receiver, element, start);
  }
  return UNINTERCEPTED(receiver.indexOf(element, start));
}

insertRange$2(receiver, start, length) {
  if (isJsArray(receiver)) {
    return insertRange$3(receiver, start, length, null);
  }
  return UNINTERCEPTED(receiver.insertRange(start, length));
}

insertRange$3(receiver, start, length, initialValue) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.insertRange(start, length, initialValue));
  }
  return listInsertRange(receiver, start, length, initialValue);
}

last(receiver) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.last());
  }
  return receiver[receiver.length - 1];
}

lastIndexOf$1(receiver, element) {
  if (isJsArray(receiver)) {
    var start = JS('num', r'#.length', receiver);
    return Arrays.lastIndexOf(receiver, element, start);
  } else if (receiver is String) {
    checkNull(element);
    if (element is !String) throw new ArgumentError(element);
    return JS('int', r'#.lastIndexOf(#)', receiver, element);
  }
  return UNINTERCEPTED(receiver.lastIndexOf(element));
}

lastIndexOf$2(receiver, element, start) {
  if (isJsArray(receiver)) {
    return Arrays.lastIndexOf(receiver, element, start);
  } else if (receiver is String) {
    checkNull(element);
    if (element is !String) throw new ArgumentError(element);
    if (start !== null) {
      if (start is !num) throw new ArgumentError(start);
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

removeRange(receiver, start, length) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.removeRange(start, length));
  }
  checkGrowable(receiver, 'removeRange');
  if (length == 0) {
    return;
  }
  checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
  if (start is !int) throw new ArgumentError(start);
  if (length is !int) throw new ArgumentError(length);
  if (length < 0) throw new ArgumentError(length);
  var receiverLength = JS('num', r'#.length', receiver);
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

setRange$3(receiver, start, length, from) {
  if (isJsArray(receiver)) {
    return setRange$4(receiver, start, length, from, 0);
  }
  return UNINTERCEPTED(receiver.setRange(start, length, from));
}

setRange$4(receiver, start, length, from, startFrom) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.setRange(start, length, from, startFrom));
  }

  checkMutable(receiver, 'indexed set');
  if (length === 0) return;
  checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(length); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(from); // TODO(ahe): This is not specified but co19 tests it.
  checkNull(startFrom); // TODO(ahe): This is not specified but co19 tests it.
  if (start is !int) throw new ArgumentError(start);
  if (length is !int) throw new ArgumentError(length);
  if (startFrom is !int) throw new ArgumentError(startFrom);
  if (length < 0) throw new ArgumentError(length);
  if (start < 0) throw new IndexOutOfRangeException(start);
  if (start + length > receiver.length) {
    throw new IndexOutOfRangeException(start + length);
  }

  Arrays.copy(from, startFrom, receiver, start, length);
}

some(receiver, f) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.some(f));
  } else {
    return Collections.some(receiver, f);
  }
}

every(receiver, f) {
  if (!isJsArray(receiver)) {
    return UNINTERCEPTED(receiver.every(f));
  } else {
    return Collections.every(receiver, f);
  }
}

sort(receiver, compare) {
  if (!isJsArray(receiver)) return UNINTERCEPTED(receiver.sort(compare));

  checkMutable(receiver, 'sort');
  DualPivotQuicksort.sort(receiver, compare);
}

isNegative(receiver) {
  if (receiver is num) {
    return (receiver === 0) ? (1 / receiver) < 0 : receiver < 0;
  } else {
    return UNINTERCEPTED(receiver.isNegative());
  }
}

isNaN(receiver) {
  if (receiver is num) {
    return JS('bool', r'isNaN(#)', receiver);
  } else {
    return UNINTERCEPTED(receiver.isNaN());
  }
}

remainder(a, b) {
  if (checkNumbers(a, b)) {
    return JS('num', r'# % #', a, b);
  } else {
    return UNINTERCEPTED(a.remainder(b));
  }
}

abs(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.abs());

  return JS('num', r'Math.abs(#)', receiver);
}

toInt(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.toInt());

  if (receiver.isNaN()) throw new FormatException('NaN');

  if (receiver.isInfinite()) throw new FormatException('Infinity');

  var truncated = receiver.truncate();
  return JS('bool', r'# == -0.0', truncated) ? 0 : truncated;
}

ceil(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.ceil());

  return JS('num', r'Math.ceil(#)', receiver);
}

floor(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.floor());

  return JS('num', r'Math.floor(#)', receiver);
}

isInfinite(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.isInfinite());

  return JS('bool', r'# == Infinity', receiver)
    || JS('bool', r'# == -Infinity', receiver);
}

round(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.round());

  if (JS('bool', r'# < 0', receiver)) {
    return JS('num', r'-Math.round(-#)', receiver);
  } else {
    return JS('num', r'Math.round(#)', receiver);
  }
}

toDouble(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.toDouble());

  return receiver;
}

truncate(receiver) {
  if (receiver is !num) return UNINTERCEPTED(receiver.truncate());

  return receiver < 0 ? receiver.ceil() : receiver.floor();
}

toStringAsFixed(receiver, fractionDigits) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toStringAsFixed(fractionDigits));
  }
  checkNum(fractionDigits);

  String result = JS('String', r'#.toFixed(#)', receiver, fractionDigits);
  if (receiver == 0 && receiver.isNegative()) return "-$result";
  return result;
}

toStringAsExponential(receiver, fractionDigits) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toStringAsExponential(fractionDigits));
  }
  String result;
  if (fractionDigits !== null) {
    checkNum(fractionDigits);
    result = JS('String', r'#.toExponential(#)', receiver, fractionDigits);
  } else {
    result = JS('String', r'#.toExponential()', receiver);
  }
  if (receiver == 0 && receiver.isNegative()) return "-$result";
  return result;
}

toStringAsPrecision(receiver, fractionDigits) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toStringAsPrecision(fractionDigits));
  }
  checkNum(fractionDigits);

  String result = JS('String', r'#.toPrecision(#)',
                     receiver, fractionDigits);
  if (receiver == 0 && receiver.isNegative()) return "-$result";
  return result;
}

toRadixString(receiver, radix) {
  if (receiver is !num) {
    return UNINTERCEPTED(receiver.toRadixString(radix));
  }
  checkNum(radix);
  if (radix < 2 || radix > 36) throw new ArgumentError(radix);
  return JS('String', r'#.toString(#)', receiver, radix);
}

allMatches(receiver, str) {
  if (receiver is !String) return UNINTERCEPTED(receiver.allMatches(str));
  checkString(str);
  return allMatchesInStringUnchecked(receiver, str);
}

concat(receiver, other) {
  if (receiver is !String) return UNINTERCEPTED(receiver.concat(other));

  if (other is !String) throw new ArgumentError(other);
  return JS('String', r'# + #', receiver, other);
}

contains$1(receiver, other) {
  if (receiver is !String) {
    return UNINTERCEPTED(receiver.contains(other));
  }
  return contains$2(receiver, other, 0);
}

contains$2(receiver, other, startIndex) {
  if (receiver is !String) {
    return UNINTERCEPTED(receiver.contains(other, startIndex));
  }
  checkNull(other);
  return stringContainsUnchecked(receiver, other, startIndex);
}

endsWith(receiver, other) {
  if (receiver is !String) return UNINTERCEPTED(receiver.endsWith(other));

  checkString(other);
  int receiverLength = receiver.length;
  int otherLength = other.length;
  if (otherLength > receiverLength) return false;
  return other == receiver.substring(receiverLength - otherLength);
}

replaceAll(receiver, from, to) {
  if (receiver is !String) return UNINTERCEPTED(receiver.replaceAll(from, to));

  checkString(to);
  return stringReplaceAllUnchecked(receiver, from, to);
}

replaceFirst(receiver, from, to) {
  if (receiver is !String) {
    return UNINTERCEPTED(receiver.replaceFirst(from, to));
  }
  checkString(to);
  return stringReplaceFirstUnchecked(receiver, from, to);
}

split(receiver, pattern) {
  if (receiver is !String) return UNINTERCEPTED(receiver.split(pattern));
  checkNull(pattern);
  return stringSplitUnchecked(receiver, pattern);
}

splitChars(receiver) {
  if (receiver is !String) return UNINTERCEPTED(receiver.splitChars());

  return JS('List', r'#.split("")', receiver);
}

startsWith(receiver, other) {
  if (receiver is !String) return UNINTERCEPTED(receiver.startsWith(other));
  checkString(other);

  int length = other.length;
  if (length > receiver.length) return false;
  return JS('bool', r'# == #', other,
            JS('String', r'#.substring(0, #)', receiver, length));
}

substring$1(receiver, startIndex) {
  if (receiver is !String) return UNINTERCEPTED(receiver.substring(startIndex));

  return substring$2(receiver, startIndex, null);
}

substring$2(receiver, startIndex, endIndex) {
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

toLowerCase(receiver) {
  if (receiver is !String) return UNINTERCEPTED(receiver.toLowerCase());

  return JS('String', r'#.toLowerCase()', receiver);
}

toUpperCase(receiver) {
  if (receiver is !String) return UNINTERCEPTED(receiver.toUpperCase());

  return JS('String', r'#.toUpperCase()', receiver);
}

trim(receiver) {
  if (receiver is !String) return UNINTERCEPTED(receiver.trim());

  return JS('String', r'#.trim()', receiver);
}

/**
 * This is the [Jenkins hash function][1] but using masking to keep
 * values in SMI range.
 *
 * [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
 */
hashCode(receiver) {
  // TODO(ahe): This method shouldn't have to use JS. Update when our
  // optimizations are smarter.
  if (receiver === null) return 0;
  if (receiver is num) return JS('int', r'# & 0x1FFFFFFF', receiver);
  if (receiver is bool) return receiver ? 0x40377024 : 0xc18c0076;
  if (isJsArray(receiver)) return Primitives.objectHashCode(receiver);
  if (receiver is !String) return UNINTERCEPTED(receiver.hashCode());
  int hash = 0;
  int length = JS('int', r'#.length', receiver);
  for (int i = 0; i < length; i++) {
    hash = 0x1fffffff & (hash + JS('int', r'#.charCodeAt(#)', receiver, i));
    hash = 0x1fffffff & (hash + JS('int', r'# << #', 0x0007ffff & hash, 10));
    hash ^= hash >> 6;
  }
  hash = 0x1fffffff & (hash + JS('int', r'# << #', 0x03ffffff & hash, 3));
  hash ^= hash >> 11;
  return 0x1fffffff & (hash + JS('int', r'# << #', 0x00003fff & hash, 15));
}

charCodes(receiver) {
  if (receiver is !String) return UNINTERCEPTED(receiver.charCodes());
  int len = receiver.length;
  List<int> result = new List<int>(len);
  for (int i = 0; i < len; i++) {
    result[i] = receiver.charCodeAt(i);
  }
  return result;
}

isEven(receiver) {
  if (receiver is !int) return UNINTERCEPTED(receiver.isEven());
  return (receiver & 1) === 0;
}

isOdd(receiver) {
  if (receiver is !int) return UNINTERCEPTED(receiver.isOdd());
  return (receiver & 1) === 1;
}

get$runtimeType(receiver) {
  if (receiver is int) {
    return getOrCreateCachedRuntimeType('int');
  } else if (receiver is String) {
    return getOrCreateCachedRuntimeType('String');
  } else if (receiver is double) {
    return getOrCreateCachedRuntimeType('double');
  } else if (receiver is bool) {
    return getOrCreateCachedRuntimeType('bool');
  } else if (receiver === null) {
    return getOrCreateCachedRuntimeType('Null');
  } else if (isJsArray(receiver)) {
    return getOrCreateCachedRuntimeType('List');
  } else {
    return UNINTERCEPTED(receiver.runtimeType);
  }
}

// TODO(lrn): These getters should be generated automatically for all
// intercepted methods.
get$toString(receiver) => () => toString(receiver);

get$hashCode(receiver) => () => hashCode(receiver);
