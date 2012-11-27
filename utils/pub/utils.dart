// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Generic utility functions. Stuff that should possibly be in core.
 */
library utils;

import 'dart:crypto';
import 'dart:isolate';

/** A pair of values. */
class Pair<E, F> {
  E first;
  F last;

  Pair(this.first, this.last);

  String toString() => '($first, $last)';

  bool operator==(other) {
    if (other is! Pair) return false;
    return other.first == first && other.last == last;
  }
}

// TODO(rnystrom): Move into String?
/** Pads [source] to [length] by adding spaces at the end. */
String padRight(String source, int length) {
  final result = new StringBuffer();
  result.add(source);

  while (result.length < length) {
    result.add(' ');
  }

  return result.toString();
}

/**
 * Runs [fn] after [future] completes, whether it completes successfully or not.
 * Essentially an asynchronous `finally` block.
 */
always(Future future, fn()) {
  var completer = new Completer();
  future.then((_) => fn());
  future.handleException((_) {
    fn();
    return false;
  });
}

/**
 * Flattens nested lists into a single list containing only non-list elements.
 */
List flatten(List nested) {
  var result = [];
  helper(list) {
    for (var element in list) {
      if (element is List) {
        helper(element);
      } else {
        result.add(element);
      }
    }
  }
  helper(nested);
  return result;
}

/**
 * Asserts that [iter] contains only one element, and returns it.
 */
only(Iterable iter) {
  var iterator = iter.iterator();
  assert(iterator.hasNext);
  var obj = iterator.next();
  assert(!iterator.hasNext);
  return obj;
}

/**
 * Returns a set containing all elements in [minuend] that are not in
 * [subtrahend].
 */
Set setMinus(Collection minuend, Collection subtrahend) {
  var minuendSet = new Set.from(minuend);
  minuendSet.removeAll(subtrahend);
  return minuendSet;
}

/**
 * Replace each instance of [matcher] in [source] with the return value of [fn].
 */
String replace(String source, Pattern matcher, String fn(Match)) {
  var buffer = new StringBuffer();
  var start = 0;
  for (var match in matcher.allMatches(source)) {
    buffer.add(source.substring(start, match.start));
    start = match.end;
    buffer.add(fn(match));
  }
  buffer.add(source.substring(start));
  return buffer.toString();
}

/**
 * Returns whether or not [str] ends with [matcher].
 */
bool endsWithPattern(String str, Pattern matcher) {
  for (var match in matcher.allMatches(str)) {
    if (match.end == str.length) return true;
  }
  return false;
}

/**
 * Returns the hex-encoded sha1 hash of [source].
 */
String sha1(String source) =>
  CryptoUtils.bytesToHex(new SHA1().update(source.charCodes).digest());

/**
 * Returns a [Future] that completes in [milliSeconds].
 */
Future sleep(int milliSeconds) {
  var completer = new Completer();
  new Timer(milliSeconds, completer.complete);
  return completer.future;
}

/// Configures [future] so that its result (success or exception) is passed on
/// to [completer].
void chainToCompleter(Future future, Completer completer) {
  future.handleException((e) {
    completer.completeException(e, future.stackTrace);
    return true;
  });
  future.then(completer.complete);
}

/// Like [String.split], but only splits on the first occurrence of the pattern.
/// This will always return an array of two elements or fewer.
List<String> split1(String toSplit, String pattern) {
  if (toSplit.isEmpty) return <String>[];

  var index = toSplit.indexOf(pattern);
  if (index == -1) return [toSplit];
  return [toSplit.substring(0, index),
    toSplit.substring(index + pattern.length)];
}
