// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var secretWindow;
var secretDocument;

Window get window() {
  if (secretWindow === null) {
    LevelDom.initialize(dom.window);
  }
  return secretWindow;
}

Document get document() {
  if (secretWindow === null) {
    LevelDom.initialize(dom.window);
  }
  return secretDocument;
}
