// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This contains a reader that accesses data from local files, so it can't
 * be run in the browser.
 */

library file_data_reader;

import 'dart:async';
import 'package:path/path.dart';
import 'dart:io';
import 'intl_helpers.dart';

class FileDataReader implements LocaleDataReader {

  /// The base path from which we will read data.
  String path;

  FileDataReader(this.path);

  /// Read the locale data found for [locale] on our [path].
  Future read(String locale) {
    var file = new File(join(path, '$locale.json'));
    return file.readAsString();
  }
}
