// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class _HttpRequestUtils {
  // Helper for factory HttpRequest.get
  static HttpRequest get(
      String url, onComplete(HttpRequest request), bool withCredentials) {
    final request = new HttpRequest();
    request.open('GET', url, async: true);

    request.withCredentials = withCredentials;

    request.onReadyStateChange.listen((e) {
      if (request.readyState == HttpRequest.DONE) {
        onComplete(request);
      }
    });

    request.send();

    return request;
  }
}
