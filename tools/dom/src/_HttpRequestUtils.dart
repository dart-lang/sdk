// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class _HttpRequestUtils {

  // Helper for factory HttpRequest.get
  static HttpRequest get(String url,
                            onComplete(HttpRequest request),
                            bool withCredentials) {
    final request = new HttpRequest();
    request.open('GET', url, true);

    request.withCredentials = withCredentials;

    request.on.readyStateChange.add((e) {
      if (request.readyState == HttpRequest.DONE) {
        // TODO(efortuna): Previously HttpRequest.get only invoked the callback
        // when request.status was 0 or 200. This
        // causes two problems 1) request.status = 0 for ANY local XHR request
        // (file found or not found) 2) the user facing function claims that the
        // callback is called on completion of the request, regardless of
        // status. Because the new event model is coming in soon, rather than
        // fixing the callbacks version, we just need to revisit the desired
        // behavior when we're using streams/futures.
        // Status 0 is for local XHR request.
        onComplete(request);
      }
    });

    request.send();

    return request;
  }
}
