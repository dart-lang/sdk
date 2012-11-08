// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library streamed_request_test;

import 'dart:io';

import '../../unittest/lib/unittest.dart';
import '../lib/http.dart' as http;
import 'utils.dart';

void main() {
  test('#finalize freezes contentLength', () {
    var request = new http.StreamedRequest('POST', dummyUrl);
    request.finalize();

    expect(request.contentLength, equals(-1));
    expect(() => request.contentLength = 10, throwsStateError);
  });
}