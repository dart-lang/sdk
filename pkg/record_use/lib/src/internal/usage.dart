// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../helper.dart';
import '../public/constant.dart';
import '../public/identifier.dart';
import '../public/reference.dart';
import 'definition.dart';

class Usage<T extends Reference> {
  final Definition definition;
  final List<T> references;

  const Usage({
    required this.definition,
    required this.references,
  });

  factory Usage.fromJson(
    Map<String, dynamic> json,
    List<Identifier> identifiers,
    List<String> uris,
    List<Constant> constants,
    T Function(Map<String, dynamic>, List<String>, List<Constant>) constr,
  ) =>
      Usage(
        definition: Definition.fromJson(
          json['definition'] as Map<String, dynamic>,
          identifiers,
          uris,
        ),
        references: (json['references'] as List)
            .map((x) => constr(x as Map<String, dynamic>, uris, constants))
            .toList(),
      );

  Map<String, dynamic> toJson(
    Map<Identifier, int> identifiers,
    Map<String, int> uris,
    Map<Constant, int> constants,
  ) =>
      {
        'definition': definition.toJson(identifiers, uris),
        'references': references.map((x) => x.toJson(uris, constants)).toList(),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Usage<T> &&
        other.definition == definition &&
        deepEquals(other.references, references);
  }

  @override
  int get hashCode => Object.hash(definition, deepHash(references));
}
