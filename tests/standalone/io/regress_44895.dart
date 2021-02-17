// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

void main() {
  final client = HttpClient();
  client.connectionTimeout = Duration.zero;
  // Should not throw a type error.
  client.openUrl(
    'get',
    Uri.parse(
      'https://localhost/',
    ),
  );
}
