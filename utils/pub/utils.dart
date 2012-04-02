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