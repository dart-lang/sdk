// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library is injected into the applications under coverage.
library coverage_lib;

import 'dart:io';
import 'dart:typed_data';

const PORT = 0; // replaced during rewrite
final _executedIds = new Uint8List(1024 * 64);

touch(int id) {
  int listIndex = id ~/ 8;
  int bitIndex = id % 8;
  _executedIds[listIndex] |= 1 << bitIndex;
}

postStatistics() {
  var httpClient = new HttpClient();
  return httpClient.post('127.0.0.1', PORT, '/statistics')
      .then((request) {
        request.add(_executedIds);
        return request.close();
      });
}
