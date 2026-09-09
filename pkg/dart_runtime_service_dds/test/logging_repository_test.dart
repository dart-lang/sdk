// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service_dds/src/logging_repository.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

void main() {
  group('LoggingRepository', () {
    test('initializes with default buffer size and adds entries', () {
      final repo = LoggingRepository(10);
      expect(repo.bufferSize, 10);
      repo.add(<String, Object?>{'message': 'hello'});
      repo.add(<String, Object?>{'message': 'world'});
      expect(
        repo().toList(),
        equals(<Map<String, Object?>>[
          <String, Object?>{'message': 'hello'},
          <String, Object?>{'message': 'world'},
        ]),
      );
    });

    test('resize rejects sizes above maximum', () {
      final repo = LoggingRepository();
      expect(() => repo.resize(100_001), throwsA(isA<json_rpc.RpcException>()));
    });
  });
}
