// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../base/messages.dart';
import '../base/scope.dart';
import '../builder/declaration_builders.dart';
import 'source_type_parameter_builder.dart';

class NominalParameterNameSpace {
  Map<String, SourceNominalParameterBuilder> _typeParametersByName = {};

  void addTypeParameters(
    ProblemReporting _problemReporting,
    List<SourceNominalParameterBuilder>? typeParameters, {
    required String? ownerName,
    required bool allowNameConflict,
  }) {
    if (typeParameters == null || typeParameters.isEmpty) return;
    for (SourceNominalParameterBuilder tv in typeParameters) {
      SourceNominalParameterBuilder? existing = _typeParametersByName[tv.name];
      if (tv.isWildcard) continue;
      if (existing != null) {
        if (existing.kind == TypeParameterKind.extensionSynthesized) {
          // The type parameter from the extension is shadowed by the type
          // parameter from the member. Rename the shadowed type parameter.
          existing.parameter.name = '#${existing.name}';
          _typeParametersByName[tv.name] = tv;
        } else {
          _problemReporting.addProblem(
            codeTypeParameterDuplicatedName,
            tv.fileOffset,
            tv.name.length,
            tv.fileUri,
            context: [
              codeTypeParameterDuplicatedNameCause
                  .withArguments(tv.name)
                  .withLocation(
                    existing.fileUri,
                    existing.fileOffset,
                    existing.name.length,
                  ),
            ],
          );
        }
      } else {
        _typeParametersByName[tv.name] = tv;
        // Only classes and extension types and type parameters can't have the
        // same name. See
        // [#29555](https://github.com/dart-lang/sdk/issues/29555) and
        // [#54602](https://github.com/dart-lang/sdk/issues/54602).
        if (tv.name == ownerName && !allowNameConflict) {
          _problemReporting.addProblem(
            codeTypeParameterSameNameAsEnclosing,
            tv.fileOffset,
            tv.name.length,
            tv.fileUri,
          );
        }
      }
    }
  }

  SourceNominalParameterBuilder? getTypeParameter(String name) =>
      _typeParametersByName[name];
}

class NominalParameterScope extends AbstractTypeParameterScope {
  final NominalParameterNameSpace _nameSpace;

  NominalParameterScope(super._parent, this._nameSpace);

  @override
  TypeParameterBuilder? getTypeParameter(String name) =>
      _nameSpace.getTypeParameter(name);
}
