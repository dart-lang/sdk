// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var secretWindow;
var secretDocument;

Window get window() {
  if (secretWindow === null) {
    LevelDom.initialize(BootstrapHacks.getWindow());
  }
  return secretWindow;
}

Document get document() {
  if (secretWindow === null) {
    LevelDom.initialize(BootstrapHacks.getWindow());
  }
  return secretDocument;
}

get _rawDocument() {
  return document.dynamic._documentPtr;
}

get _rawWindow() {
  return BootstrapHacks.getWindow();
}
