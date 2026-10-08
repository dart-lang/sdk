// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartpad_worker/src/tools/pub_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  test('removes User-Agent without changing other request headers', () async {
    final inner = _RecordingClient();
    final client = BrowserPubHttpClient(inner);
    final request =
        http.Request('GET', Uri.https('pub.dev', '/api/packages/foo'))
          ..headers['User-Agent'] = 'Dart pub'
          ..headers['Accept'] = 'application/json';

    await client.send(request);

    expect(inner.headers, {'accept': 'application/json'});
    client.close();
    expect(inner.isClosed, isTrue);
  });
}

class _RecordingClient extends http.BaseClient {
  Map<String, String>? headers;
  bool isClosed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    headers = {
      for (final entry in request.headers.entries)
        entry.key.toLowerCase(): entry.value,
    };
    return http.StreamedResponse(const Stream.empty(), 200);
  }

  @override
  void close() => isClosed = true;
}
