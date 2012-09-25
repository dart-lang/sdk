// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Collection<T> supports most of the ES 5 Array methods, but it's missing
// map and reduce.

// TODO(jmesserly): we might want a version of this that return an iterable,
// however JS, Python and Ruby versions are all eager.
List map(Iterable source, mapper(source)) {
  List result = new List();
  if (source is List) {
    List list = source; // TODO: shouldn't need this
    result.length = list.length;
    for (int i = 0; i < list.length; i++) {
      result[i] = mapper(list[i]);
    }
  } else {
    for (final item in source) {
      result.add(mapper(item));
    }
  }
  return result;
}

reduce(Iterable source, callback, [initialValue]) {
  final i = source.iterator();

  var current = initialValue;
  if (current == null && i.hasNext()) {
    current = i.next();
  }
  while (i.hasNext()) {
    current = callback(current, i.next());
  }
  return current;
}

List zip(Iterable left, Iterable right, mapper(left, right)) {
  List result = new List();
  var x = left.iterator();
  var y = right.iterator();
  while (x.hasNext() && y.hasNext()) {
    result.add(mapper(x.next(), y.next()));
  }
  if (x.hasNext() || y.hasNext()) {
    throw new ArgumentError();
  }
  return result;
}


