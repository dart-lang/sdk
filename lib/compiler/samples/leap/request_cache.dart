// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library request_cache;

import 'dart:html';

/** File system implementation using HTML5's Web Storage. */
class HttpRequestCache {
  final Storage storage;

  HttpRequestCache() : storage = window.sessionStorage;

  String readAll(String filename) {
    String response = storage[filename];

    if (response == null) {
      HttpRequest xr = new HttpRequest();
      xr.open("GET", filename, false);
      xr.send();
      response = xr.responseText;
      storage[filename] = response;
    }
    return response;
  }
}
