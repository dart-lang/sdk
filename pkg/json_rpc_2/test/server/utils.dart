// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.test.server.util;

import 'package:unittest/unittest.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

void expectErrorResponse(json_rpc.Server server, request, int errorCode,
    String message) {
  var id;
  if (request is Map) id = request['id'];

  expect(server.handleRequest(request), completion(equals({
    'jsonrpc': '2.0',
    'id': id,
    'error': {
      'code': errorCode,
      'message': message,
      'data': {'request': request}
    }
  })));
}

Matcher throwsInvalidParams(String message) {
  return throwsA(predicate((error) {
    expect(error, new isInstanceOf<json_rpc.RpcException>());
    expect(error.message, equals(message));
    return true;
  }));
}
