// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_typedef_builder;

import 'package:kernel/ast.dart' show DartType, InvalidType, NullType, Typedef;
import 'package:kernel/core_types.dart';

import '../builder/library_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';

import '../problems.dart' show unimplemented;

import '../util/helpers.dart';

import 'dill_class_builder.dart' show computeTypeVariableBuilders;
import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillTypeAliasBuilder extends TypeAliasBuilderImpl {
  final Typedef typedef;

  List<TypeVariableBuilder>? _typeVariables;
  TypeBuilder? _type;

  DartType? thisType;

  DillTypeAliasBuilder(this.typedef, DillLibraryBuilder parent)
      : super(null, typedef.name, parent, typedef.fileOffset);

  List<MetadataBuilder> get metadata {
    return unimplemented("metadata", -1, null);
  }

  List<TypeVariableBuilder>? get typeVariables {
    if (_typeVariables == null && typedef.typeParameters.isNotEmpty) {
      _typeVariables =
          computeTypeVariableBuilders(library, typedef.typeParameters);
    }
    return _typeVariables;
  }

  int varianceAt(int index) {
    return typedef.typeParameters[index].variance;
  }

  bool get fromDill => true;

  @override
  int get typeVariablesCount => typedef.typeParameters.length;

  @override
  TypeBuilder? get type {
    if (_type == null && typedef.type is! InvalidType) {
      _type = library.loader.computeTypeBuilder(typedef.type!);
    }
    // TODO(johnniwinther): Support TypeBuilder for InvalidType.
    return _type;
  }

  @override
  DartType buildThisType() {
    return thisType ??= typedef.type!;
  }

  @override
  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder>? arguments,
      {bool? nonInstanceContext}) {
    // For performance reasons, [typeVariables] aren't restored from [target].
    // So, if [arguments] is null, the default types should be retrieved from
    // [cls.typeParameters].
    if (arguments == null) {
      List<DartType> result =
          new List<DartType>.generate(typedef.typeParameters.length, (int i) {
        return typedef.typeParameters[i].defaultType;
      }, growable: true);
      return result;
    }

    // [arguments] != null
    List<DartType> result =
        new List<DartType>.generate(arguments.length, (int i) {
      return arguments[i].build(library);
    }, growable: true);
    return result;
  }

  @override
  bool get isNullAlias => typedef.type is NullType;

  @override
  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes,
      List<DelayedActionPerformer> delayedActionPerformers) {
    // TODO(johnniwinther): Remove the need for this.
  }
}
