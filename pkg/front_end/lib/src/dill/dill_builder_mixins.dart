// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/type_builder.dart';

mixin DillDeclarationBuilderMixin implements IDeclarationBuilder {
  List<TypeParameter> get typeParameterNodes;

  @override
  int get typeVariablesCount => typeParameterNodes.length;

  @override
  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy) {
    // For performance reasons, [typeVariables] aren't restored from [target].
    // So, if [arguments] is null, the default types should be retrieved from
    // [cls.typeParameters].
    if (arguments == null) {
      // TODO(johnniwinther): Use i2b here when needed.
      return new List<DartType>.generate(typeParameterNodes.length,
          (int i) => typeParameterNodes[i].defaultType,
          growable: true);
    }

    // [arguments] != null
    return new List<DartType>.generate(
        arguments.length,
        (int i) =>
            arguments[i].buildAliased(library, TypeUse.typeArgument, hierarchy),
        growable: true);
  }
}
