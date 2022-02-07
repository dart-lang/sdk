// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

void main() async {
  var documentElement = document.documentElement!;

  // `requestFullscreen` requires user interaction to succeed, so this just
  // tests that the bindings and type work.
  await documentElement.requestFullscreen().catchError((_) {});
  // Try it with an options argument.
  await documentElement
      .requestFullscreen({'navigationUI': 'show'}).catchError((_) {});
}
