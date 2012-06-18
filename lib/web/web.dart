// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("web");

// Web related functions and data that are not specific to a single environment
// (e.g., only in a browser or only on a server).

/**
 * Escapes HTML-special characters of [text] so that the result can be
 * included verbatim in HTML source code, either in an element body or in an
 * attribute value.
 */
String htmlEscape(String text) {
  // TODO(efortuna): A more efficient implementation.
  return text.replaceAll("&", "&amp;")
             .replaceAll("<", "&lt;")
             .replaceAll(">", "&gt;")
             .replaceAll('"', "&quot;")
             .replaceAll("'", "&apos;");
}
