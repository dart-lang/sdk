// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_service_protocol_shared/dart_service_protocol_shared.dart';
import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

void main() {
  group('Success', () {
    test('fromDTDResponse creates correct instance', () {
      final response = DTDResponse('id', 'method', {
        'type': 'Success',
      });
      final success = Success.fromDTDResponse(response);
      expect(success.type, equals('Success'));
      expect(success.value, isNull);
    });

    test('fromDTDResponse throws on invalid type', () {
      final response = DTDResponse('id', 'method', {
        'type': 'InvalidType',
      });
      expect(
        () => Success.fromDTDResponse(response),
        throwsA(isA<json_rpc.RpcException>()),
      );
    });
  });

  group('StringResponse', () {
    test('fromDTDResponse creates correct instance', () {
      final response = DTDResponse('id', 'method', {
        'type': 'StringResponse',
        'value': 'test string',
      });
      final stringResponse = StringResponse.fromDTDResponse(response);
      expect(stringResponse.type, equals('StringResponse'));
      expect(stringResponse.value, equals('test string'));
    });

    test('fromDTDResponse throws on invalid type', () {
      final response = DTDResponse('id', 'method', {
        'type': 'InvalidType',
        'value': 'test string',
      });
      expect(
        () => StringResponse.fromDTDResponse(response),
        throwsA(isA<json_rpc.RpcException>()),
      );
    });
  });

  group('BoolResponse', () {
    test('fromDTDResponse creates correct instance', () {
      final response = DTDResponse('id', 'method', {
        'type': 'BoolResponse',
        'value': true,
      });
      final boolResponse = BoolResponse.fromDTDResponse(response);
      expect(boolResponse.type, equals('BoolResponse'));
      expect(boolResponse.value, isTrue);
    });

    test('fromDTDResponse throws on invalid type', () {
      final response = DTDResponse('id', 'method', {
        'type': 'InvalidType',
        'value': true,
      });
      expect(
        () => BoolResponse.fromDTDResponse(response),
        throwsA(isA<json_rpc.RpcException>()),
      );
    });
  });

  group('StringListResponse', () {
    test('fromDTDResponse creates correct instance', () {
      final response = DTDResponse('id', 'method', {
        'type': 'ListResponse',
        'value': ['item1', 'item2'],
      });
      final listResponse = StringListResponse.fromDTDResponse(response);
      expect(listResponse.type, equals('ListResponse'));
      expect(listResponse.value, equals(['item1', 'item2']));
    });

    test('fromDTDResponse throws on invalid type', () {
      final response = DTDResponse('id', 'method', {
        'type': 'InvalidType',
        'value': ['item1', 'item2'],
      });
      expect(
        () => StringListResponse.fromDTDResponse(response),
        throwsA(isA<json_rpc.RpcException>()),
      );
    });
  });

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

  group('VmServicesResponse', () {
    test('fromDTDResponse and toJson', () {
      final response = DTDResponse('id', 'method', {
        'type': 'VmServicesResponse',
        'vmServices': [
          const VmServiceInfo(uri: 'uri1', name: 'name1').toJson(),
          const VmServiceInfo(uri: 'uri2', exposedUri: 'exposedUri2').toJson(),
        ],
      });
      final servicesResponse = VmServicesResponse.fromDTDResponse(response);
      expect(VmServicesResponse.type, equals('VmServicesResponse'));
      expect(servicesResponse.vmServicesInfos.length, equals(2));
      expect(servicesResponse.vmServicesInfos[0].uri, equals('uri1'));
      expect(servicesResponse.vmServicesInfos[0].name, equals('name1'));
      expect(servicesResponse.vmServicesInfos[1].uri, equals('uri2'));
      expect(
        servicesResponse.vmServicesInfos[1].exposedUri,
        equals('exposedUri2'),
      );

      expect(
        servicesResponse.toJson(),
        equals(
          {
            'type': 'VmServicesResponse',
            'vmServices': [
              {'uri': 'uri1', 'name': 'name1'},
              {'uri': 'uri2', 'exposedUri': 'exposedUri2'},
            ],
          },
        ),
      );
    });

    test('fromDTDResponse throws on invalid type', () {
      final response = DTDResponse('id', 'method', {
        'type': 'InvalidType',
        'vmServices': [],
      });
      expect(
        () => VmServicesResponse.fromDTDResponse(response),
        throwsA(isA<json_rpc.RpcException>()),
      );
    });

    test('toString formats correctly', () {
      final response = const VmServicesResponse(
        vmServicesInfos: [
          VmServiceInfo(uri: 'uri1', name: 'name1'),
          VmServiceInfo(uri: 'uri2', exposedUri: 'exposedUri2'),
        ],
      );
      expect(
        response.toString(),
        equals(
          '[VmServicesResponse vmServices: [uri1 - name1, '
          'uri2 (exposed: exposedUri2)]]',
        ),
      );
    });

    test('VmServiceInfo toString formats correctly', () {
      final serviceInfo = const VmServiceInfo(
        uri: 'uri1',
        exposedUri: 'exposedUri1',
        name: 'name1',
      );
      expect(
        serviceInfo.toString(),
        equals('uri1 (exposed: exposedUri1) - name1'),
      );
    });
  });
}
