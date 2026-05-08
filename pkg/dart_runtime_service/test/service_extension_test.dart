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
      const kParameter = 'parameter';
      const kValue = 'value';

      final serviceName = await registerServiceHelper(
        client: client2,
        serviceProvider: client1,
        serviceName: kServiceName,
        callback: (parameters) async {
          expect(parameters[kParameter], kValue);
          return {'result': Success().toJson()};
        },
      );

      final result = await client2.callServiceExtension(
        serviceName,
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
      const kError = 'Error!';

      final serviceName = await registerServiceHelper(
        client: client2,
        serviceProvider: client1,
        serviceName: kServiceName,
        callback: (parameters) {
          throw Exception(kError);
        },
      );

      try {
        await client2.callServiceExtension(serviceName);
      } on RPCError catch (e) {
        expect(e.callingMethod, serviceName);
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
        const kParameter = 'parameter';
        const kValue1 = 'abc';
        const kValue2 = 'def';
        const kResult = 'result';

        final serviceName1 = await registerServiceHelper(
          client: client3,
          serviceProvider: client1,
          serviceName: kServiceName,
          callback: (parameters) async {
            expect(parameters[kParameter], kValue1);
            return {kResult: parameters};
          },
        );

        final serviceName2 = await registerServiceHelper(
          client: client3,
          serviceProvider: client2,
          serviceName: kServiceName,
          callback: (parameters) async {
            expect(parameters[kParameter], kValue2);
            return {kResult: parameters};
          },
        );

        var result = await client3.callServiceExtension(
          serviceName1,
          args: {kParameter: kValue1},
        );
        expect(result.json![kParameter], kValue1);

        result = await client3.callServiceExtension(
          serviceName2,
          args: {kParameter: kValue2},
        );
        expect(result.json![kParameter], kValue2);
      },
    );
  });
}
