// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("dom_for_unittest");
#native("dom_for_unittest.js");

class Window {
  Window();

  void postMessage(String message, String origin) {
    _postMessage(message, origin);
  }

  static void _postMessage(String message, String origin) native;
}

class HTMLDocument {
  HTMLDocument();

  HTMLBodyElement get body() { return new HTMLBodyElement(); }
}

class HTMLBodyElement {
  HTMLBodyElement();

  void set innerHTML(String html) {
    _innerHTML(html);
  }

  static void _innerHTML(String html) native;
}

Window get window() { return new Window(); }
HTMLDocument get document() { return new HTMLDocument(); }
