// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http/http.dart' as http;

http.Client createPubHttpClient() => BrowserPubHttpClient(http.Client());

/// Removes Pub's User-Agent header before browser Fetch handles the request.
///
/// Firefox includes this header in its CORS preflight, which pub.dev rejects.
class BrowserPubHttpClient extends http.BaseClient {
  final http.Client _inner;

  BrowserPubHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.removeWhere(
      (name, _) => name.toLowerCase() == 'user-agent',
    );
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
