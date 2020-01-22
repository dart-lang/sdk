// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.io_html_mutual_exclusion;

import 'dart:mirrors';

main() {
  var libraries = currentMirrorSystem().libraries;
  bool has_io = libraries[Uri.parse('dart:io')] != null;
  bool has_html = libraries[Uri.parse('dart:html')] != null;

  if (has_io && has_html) {
    throw "No embedder should have both dart:io and dart:html accessible";
  }
}
