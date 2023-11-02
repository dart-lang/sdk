// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/test_helper.dart';

Future<Response> getImplementationFields(
    VmService service, String isolateId, String objectId) async {
  return await service.callMethod("_getImplementationFields",
      isolateId: isolateId, args: {"objectId": objectId});
}

var tests = <IsolateTest>[
  // A null object.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final objectId = 'objects/null';
    final result = await getImplementationFields(service, isolateId, objectId);
    expect(result.json!["type"]!, "ImplementationFields");
    expect(result.json!["fields"]!, isEmpty);
  },
];

main([args = const <String>[]]) async =>
    runIsolateTests(args, tests, 'get_implementation_fields_rpc_test.dart');
