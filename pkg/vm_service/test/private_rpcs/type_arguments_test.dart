// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import '../common/test_helper.dart';

class TypeArgumentsList {
  static TypeArgumentsList? parse(Map<String, dynamic>? json) =>
      json == null ? null : TypeArgumentsList._fromJson(json);

  TypeArgumentsList._fromJson(Map<String, dynamic> json)
      : type = json['type'],
        canonicalTypeArgumentsTableSize =
            json['canonicalTypeArgumentsTableSize'],
        canonicalTypeArgumentsTableUsed =
            json['canonicalTypeArgumentsTableUsed'],
        typeArguments = [
          for (final e in json['typeArguments']) TypeArgumentsRef.parse(e)!,
        ];

  final String type;
  final int canonicalTypeArgumentsTableSize;
  final int canonicalTypeArgumentsTableUsed;
  final List<TypeArgumentsRef> typeArguments;
}

extension on VmService {
  Future<TypeArgumentsList> getTypeArgumentsList(
    String isolateId,
    bool onlyWithInstantiations,
  ) async {
    final response = await callMethod('_getTypeArgumentsList',
        isolateId: isolateId,
        // Only native metrics are supported.
        args: {
          'onlyWithInstantiations': onlyWithInstantiations,
        });
    return TypeArgumentsList.parse(response.json)!;
  }
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final result = await service.getTypeArgumentsList(
      isolateId,
      false,
    );

    expect(result.typeArguments, isNotEmpty);
    expect(
      result.canonicalTypeArgumentsTableSize,
      greaterThanOrEqualTo(result.canonicalTypeArgumentsTableUsed),
    );

    final resultWithInstantiations = await service.getTypeArgumentsList(
      isolateId,
      true,
    );
    expect(resultWithInstantiations.typeArguments, isNotEmpty);
    expect(
      resultWithInstantiations.canonicalTypeArgumentsTableSize,
      greaterThanOrEqualTo(
        resultWithInstantiations.canonicalTypeArgumentsTableUsed,
      ),
    );

    // Check that |instantiated| <= |all|
    expect(
      resultWithInstantiations.typeArguments.length,
      lessThanOrEqualTo(result.typeArguments.length),
    );

    // Check that we can retrieve the type argument again.
    final firstType = result.typeArguments.first;
    final type =
        await service.getObject(isolateId, firstType.id!) as TypeArguments;
    expect(firstType.name, type.name);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'type_arguments_test.dart',
    );
