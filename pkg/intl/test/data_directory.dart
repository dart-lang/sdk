// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A utility function for test and tools that compensates (at least for very
 * simple cases) for file-dependent programs being run from different
 * directories.
 */
library data_directory;

import 'dart:io';

String get _sep => Platform.pathSeparator;

get dataDirectory {
  var current = new Directory.current().path;
  if (new RegExp('.*${_sep}test').hasMatch(current)) {
    return '..${_sep}lib${_sep}src${_sep}data${_sep}dates${_sep}';
  }
  if (new RegExp('.*${_sep}intl').hasMatch(current)) {
    return 'lib${_sep}src${_sep}data${_sep}dates${_sep}';
  }
  return 'pkg${_sep}intl${_sep}lib${_sep}src${_sep}data${_sep}dates${_sep}';
}