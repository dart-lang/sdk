// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../helper.dart';
import 'constant.dart';

final class InstanceConstant {
  final Map<String, Constant> fields;

  const InstanceConstant({
    required this.fields,
  });

  factory InstanceConstant.fromJson(
    Map<String, dynamic> json,
    List<Constant> constants,
  ) {
    return InstanceConstant(
      fields: (json['fields'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, constants[value as int]),
      ),
    );
  }

  Map<String, dynamic> toJson(List<Constant> constants) => {
        if (fields.isNotEmpty)
          'fields': fields
              .map((key, value) => MapEntry(key, constants.indexOf(value))),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InstanceConstant && deepEquals(other.fields, fields);
  }

  @override
  int get hashCode => deepHash(fields);
}
