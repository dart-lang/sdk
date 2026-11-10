// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns [url] modified if necessary so that, if the current page is served
/// over `https`, then the URL is converted to `https` (or `wss`).
String fixProtocol(String url, {required String windowLocationProtocol}) {
  var uri = Uri.parse(url);
  if (windowLocationProtocol == 'https:' &&
      // Chrome allows mixed content on localhost. It is not safe to assume the
      // server is also listening on https.
      uri.host != 'localhost') {
    if (uri.scheme == 'http') {
      uri = uri.replace(scheme: 'https');
    } else if (uri.scheme == 'ws') {
      uri = uri.replace(scheme: 'wss');
    }
  }
  return uri.toString();
}
