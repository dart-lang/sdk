// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/type_builder.dart';
import 'dill_class_builder.dart' show computeTypeParameterBuilders;
import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillTypeAliasBuilder extends TypeAliasBuilderImpl {
  @override
  final DillLibraryBuilder parent;

  @override
  final Typedef typedef;

  @override
  final Map<Name, Procedure>? tearOffs;

  List<NominalParameterBuilder>? _typeParameters;
  TypeBuilder? _type;

  @override
  DartType? thisType;

  DillTypeAliasBuilder(this.typedef, this.tearOffs, this.parent);

  @override
  int get fileOffset => typedef.fileOffset;

  @override
  String get name => typedef.name;

  @override
  Uri get fileUri => typedef.fileUri;

  @override
  Reference get reference => typedef.reference;

  @override
  List<NominalParameterBuilder>? get typeParameters {
    if (_typeParameters == null && typedef.typeParameters.isNotEmpty) {
      _typeParameters = computeTypeParameterBuilders(
        typedef.typeParameters,
        libraryBuilder.loader,
      );
    }
    return _typeParameters;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get fromDill => true;

  @override
  int get typeParametersCount => typedef.typeParameters.length;

  @override
  TypeBuilder get type {
    return _type ??= libraryBuilder.loader.computeTypeBuilder(typedef.type!);
  }

  @override
  DartType buildThisType() {
    return thisType ??= typedef.type!;
  }

  @override
  List<DartType> buildAliasedTypeArguments(
    LibraryBuilder library,
    List<TypeBuilder>? arguments,
    ClassHierarchyBase? hierarchy,
  ) {
    // For performance reasons, [typeParameters] aren't restored from [target].
    // So, if [arguments] is null, the default types should be retrieved from
    // [cls.typeParameters].
    if (arguments == null) {
      // TODO(johnniwinther): Use i2b here when needed.
      List<DartType> result = new List<DartType>.generate(
        typedef.typeParameters.length,
        (int i) {
          return typedef.typeParameters[i].defaultType;
        },
        growable: true,
      );
      return result;
    }

    // [arguments] != null
    List<DartType> result = new List<DartType>.generate(arguments.length, (
      int i,
    ) {
      return arguments[i].buildAliased(
        library,
        TypeUse.typeArgument,
        hierarchy,
      );
    }, growable: true);
    return result;
  }
}
