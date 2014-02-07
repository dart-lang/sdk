// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A utility function for test and tools that compensates (at least for very
 * simple cases) for file-dependent programs being run from different
 * directories. The important cases are
 *   -running in the directory that contains the test itself, i.e.
 *    pkg/intl/test or a sub-directory.
 *   -running in pkg/intl, which is where the editor will run things by default
 *   -running in the top-level dart directory, where the build tests run
 */
library data_directory;

import "dart:io";
import "package:path/path.dart" as path;

String get dataDirectory {
  return path.join(intlDirectory, datesRelativeToIntl);
}

String get intlDirectory {
  var components = path.split(path.current);
  var foundIntlDir = false;

  /**
   * A helper function that returns false (indicating we should stop iterating)
   * if the argument to the previous call was 'intl' and also sets
   * the outer scope [foundIntlDir].
   */
  bool checkForIntlDir(String each) {
    if (foundIntlDir) return false;
    foundIntlDir = (each == 'intl') ? true : false;
    return true;
  }

  var pathUpToIntl = components.takeWhile(checkForIntlDir).toList();
  // We assume that if we're not somewhere underneath the intl hierarchy
  // that we are in the dart root.
  if (foundIntlDir) {
    return path.joinAll(pathUpToIntl);
  } else {
    if (new Directory(path.join(path.current, 'pkg', 'intl')).existsSync()) {
      return path.join(path.current, 'pkg', 'intl');
    }
    if (new Directory(
        path.join(path.current, '..', 'pkg', 'intl')).existsSync()) {
      return path.join(path.current, '..', 'pkg', 'intl');
    }
  }
  throw new UnsupportedError(
      'Cannot find ${path.join('pkg','intl')} directory.');
}

String get datesRelativeToIntl => path.join('lib', 'src', 'data', 'dates');
