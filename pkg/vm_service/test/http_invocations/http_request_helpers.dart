// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

Uri buildRequestUri({
  required Uri serverUri,
  required String method,
  Map<String, dynamic> params = const {},
}) {
  final pathSegments = <String>[]..addAll(serverUri.pathSegments);
  if (pathSegments.isNotEmpty) {
    pathSegments[pathSegments.length - 1] = method;
  } else {
    pathSegments.add(method);
  }
  return serverUri.replace(
    pathSegments: pathSegments,
    queryParameters: params,
  );
}

Future<Map<String, dynamic>> makeHttpServiceRequest({
  required Uri serverUri,
  required String method,
  Map<String, dynamic> params = const {},
}) async {
  final requestUri = buildRequestUri(
    serverUri: serverUri,
    method: method,
    params: params,
  );
  final httpClient = HttpClient();
  final request = await httpClient.getUrl(requestUri);
  final response = await request.close();
  final jsonResponse = await response
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(json.decoder)
      .first as Map<String, dynamic>;
  return jsonResponse['result'];
}
