// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/service_test_common.dart';
import 'native_metrics_lib.dart' as testee_lib;

class Metric {
  static Metric? parse(Map<String, dynamic>? json) =>
      json == null ? null : Metric._fromJson(json);

  Metric._fromJson(Map<String, dynamic> json)
      : type = json['type'],
        id = json['id'],
        name = json['name'],
        description = json['description'],
        unit = json['unit'],
        value = json['value'];

  final String type;
  final String id;
  final String name;
  final String description;
  final String unit;
  final double value;
}

class MetricList {
  static MetricList? parse(Map<String, dynamic>? json) =>
      json == null ? null : MetricList._fromJson(json);

  MetricList._fromJson(Map<String, dynamic> json)
      : metrics = <Metric>[
          for (final metric in json['metrics']!) Metric.parse(metric)!,
        ];

  final List<Metric> metrics;
}

extension on VmService {
  Future<MetricList> getIsolateMetricList(String isolateId) async {
    final response = await callMethod(
      '_getIsolateMetricList',
      isolateId: isolateId,
      // Only native metrics are supported.
      args: {
        'type': 'Native',
      },
    );
    return MetricList.parse(response.json)!;
  }

  Future<Metric> getIsolateMetric(String isolateId, String metricId) async {
    final response = await callMethod(
      '_getIsolateMetric',
      isolateId: isolateId,
      args: {
        'metricId': metricId,
      },
    );
    return Metric.parse(response.json)!;
  }
}

const kTestMetric = 'heap.old.capacity';

void main([args = const <String>[]]) => IsolateTestHarness(
      'native_metrics_lib.dart',
      args,
    ).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final metricList = await service.getIsolateMetricList(isolateId);
      expect(metricList.metrics.length, greaterThan(1));
      final foundOldHeapCapacity = metricList.metrics.any(
        (m) => m.name == kTestMetric,
      );
      expect(foundOldHeapCapacity, true);
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final metric = await service.getIsolateMetric(
        isolateId,
        'metrics/native/$kTestMetric',
      );
      expect(metric.type, 'Counter');
      expect(metric.name, kTestMetric);
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      bool caughtException = false;
      try {
        await service.getIsolateMetric(
          isolateId,
          'metrics/native/doesnotexist',
        );
        fail('Unreachable');
      } on RPCError catch (e) {
        caughtException = true;
        expect(e.code, RPCErrorKind.kInvalidParams.code);
        expect(
          e.details,
          "_getIsolateMetric: invalid 'metricId' "
          'parameter: metrics/native/doesnotexist',
        );
      }
      expect(caughtException, true);
    }).run(testeeMain: testee_lib.main);
