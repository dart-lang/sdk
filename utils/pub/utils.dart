// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Generic utility functions. Stuff that should possibly be in core.
 */
#library('pub_utils');

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
  assert(iterator.hasNext());
  var obj = iterator.next();
  assert(!iterator.hasNext());
  return obj;
}
