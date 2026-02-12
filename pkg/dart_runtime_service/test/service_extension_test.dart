// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/src/dart_runtime_service_options.dart';
import 'package:dart_runtime_service/src/dart_runtime_service_rpcs.dart';
import 'package:dart_runtime_service/src/rpc_exceptions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'utils/matchers.dart';
import 'utils/utilities.dart';

void main() {
  group('$DartRuntimeServiceRpcs:', () {
    test('register and invoke service extensions', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );

      final client1 = await vmServiceConnectUri(service.uri.toString());
      final client2 = await vmServiceConnectUri(service.uri.toString());

      const kServiceName = 'service';
      const kServiceAlias = 'My custom service extension';
      const kParameter = 'parameter';
      const kValue = 'value';

      client1.registerServiceCallback(kServiceName, (parameters) async {
        expect(parameters[kParameter], kValue);
        return {'result': Success().toJson()};
      });
      await client1.registerService(kServiceName, kServiceAlias);

      final result = await client2.callServiceExtension(
        // TODO(bkonyi): requires stream support to get service name with the
        // correct namespace.
        's0.$kServiceName',
        args: {kParameter: kValue},
      );
      expect(result, isA<Success>());
    });

    test('register and invoke error throwing service extension', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );

      final client1 = await vmServiceConnectUri(service.uri.toString());
      final client2 = await vmServiceConnectUri(service.uri.toString());

      const kServiceName = 'service';
      // TODO(bkonyi): requires stream support to get service name with the
      // correct namespace.
      const kMethod = 's0.$kServiceName';
      const kServiceAlias = 'My custom service extension';
      const kError = 'Error!';

      client1.registerServiceCallback(kServiceName, (parameters) {
        throw Exception(kError);
      });
      await client1.registerService(kServiceName, kServiceAlias);

      try {
        await client2.callServiceExtension(kMethod);
      } on RPCError catch (e) {
        expect(e.callingMethod, kMethod);
        expect(e.message, 'Exception: $kError');
        expect(e.code, RpcException.serverError.code);
      }
    });

    test('a client registering an identical service extension name returns an '
        'error', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );

      final client = await vmServiceConnectUri(service.uri.toString());

      const kServiceName = 'service';
      const kServiceAlias = 'My custom service extension';

      await client.registerService(kServiceName, kServiceAlias);
      expect(
        () async => await client.registerService(kServiceName, kServiceAlias),
        throwsServiceAlreadyRegisteredRPCError,
      );
    });

    test(
      'two clients registering an identical service extension name is valid',
      () async {
        final service = await createDartRuntimeServiceForTest(
          config: const DartRuntimeServiceOptions(enableLogging: true),
        );

        final client1 = await vmServiceConnectUri(service.uri.toString());
        final client2 = await vmServiceConnectUri(service.uri.toString());
        final client3 = await vmServiceConnectUri(service.uri.toString());

        const kServiceName = 'service';
        const kServiceAlias = 'My custom service extension';
        const kParameter = 'parameter';
        const kValue1 = 'abc';
        const kValue2 = 'def';
        const kResult = 'result';

        client1.registerServiceCallback(kServiceName, (parameters) async {
          expect(parameters[kParameter], kValue1);
          return {kResult: parameters};
        });
        client2.registerServiceCallback(kServiceName, (parameters) async {
          expect(parameters[kParameter], kValue2);
          return {kResult: parameters};
        });
        await client1.registerService(kServiceName, kServiceAlias);
        await client2.registerService(kServiceName, kServiceAlias);

        var result = await client3.callServiceExtension(
          // TODO(bkonyi): requires stream support to get service name with the
          // correct namespace.
          's0.$kServiceName',
          args: {kParameter: kValue1},
        );
        expect(result.json![kParameter], kValue1);

        result = await client3.callServiceExtension(
          // TODO(bkonyi): requires stream support to get service name with the
          // correct namespace.
          's1.$kServiceName',
          args: {kParameter: kValue2},
        );
        expect(result.json![kParameter], kValue2);
      },
    );
  });
}
