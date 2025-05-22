// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_service_protocol_shared/dart_service_protocol_shared.dart';
import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

void main() {
  // TODO(kenz): add test coverage for other response types.
  group('RegisteredServicesResponse', () {
    test('fromDTDResponse and toJson', () {
      final response = DTDResponse('id', 'method', {
        'type': 'RegisteredServicesResponse',
        'dtdServices': ['service1', 'service2'],
        'clientServices': [
          ClientServiceInfo('client1', {
            'method1': ClientServiceMethodInfo('method1', {'cap1': true}),
          }).toJson(),
        ],
      });
      final servicesResponse =
          RegisteredServicesResponse.fromDTDResponse(response);
      expect(
        RegisteredServicesResponse.type,
        equals('RegisteredServicesResponse'),
      );
      expect(servicesResponse.dtdServices, equals(['service1', 'service2']));
      expect(servicesResponse.clientServices.length, equals(1));
      expect(servicesResponse.clientServices[0].name, equals('client1'));

      expect(
        servicesResponse.toJson(),
        equals(
          {
            'type': 'RegisteredServicesResponse',
            'dtdServices': ['service1', 'service2'],
            'clientServices': [
              {
                'name': 'client1',
                'methods': [
                  {
                    'name': 'method1',
                    'capabilities': {'cap1': true},
                  },
                ],
              },
            ],
          },
        ),
      );
    });

    test('fromDTDResponse throws on invalid type', () {
      final response = DTDResponse('id', 'method', {
        'type': 'InvalidType',
        'dtdServices': ['service1'],
        'clientServices': [],
      });
      expect(
        () => RegisteredServicesResponse.fromDTDResponse(response),
        throwsA(isA<json_rpc.RpcException>()),
      );
    });

    test('toString formats correctly', () {
      final response = RegisteredServicesResponse(
        dtdServices: ['service1'],
        clientServices: [
          ClientServiceInfo('client1', {
            'method1': ClientServiceMethodInfo('method1', {'cap1': true}),
          }),
        ],
      );
      expect(
        response.toString(),
        equals(
          '[RegisteredServicesResponse dtdServices: [service1], '
          'clientServices: [client1 (method1 {cap1: true})]]',
        ),
      );
    });
  });
}
