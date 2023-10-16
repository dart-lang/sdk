// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

Future<Map<String, dynamic>> callMethod(
  VmService service,
  String method, {
  Map<String, dynamic>? args,
}) async {
  final response = await service.callMethod(method, args: args);
  return response.json!;
}

void invalidResponse(Map<String, dynamic> response) {
  fail('Invalid response: $response');
}

void expectSuccess(Map<String, dynamic> response) {
  expect(response['type'], 'Success');
}
