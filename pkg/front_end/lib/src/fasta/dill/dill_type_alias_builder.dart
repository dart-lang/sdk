// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_typedef_builder;

import 'package:kernel/ast.dart' show DartType, Typedef, InterfaceType;

import '../builder/function_type_builder.dart';
import '../builder/library_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';

import '../problems.dart' show unimplemented;

import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillTypeAliasBuilder extends TypeAliasBuilder {
  DillTypeAliasBuilder(Typedef typedef, DillLibraryBuilder parent)
      : super(null, typedef.name, null, null, parent, typedef.fileOffset,
            typedef: typedef);

  List<MetadataBuilder> get metadata {
    return unimplemented("metadata", -1, null);
  }

  List<TypeVariableBuilder> get typeVariables {
    return unimplemented("typeVariables", -1, null);
  }

  int varianceAt(int index) {
    return typedef.typeParameters[index].variance;
  }

  bool get fromDill => true;

  @override
  int get typeVariablesCount => typedef.typeParameters.length;

  @override
  FunctionTypeBuilder get type {
    return unimplemented("type", -1, null);
  }

  @override
  DartType buildThisType() {
    return thisType ??= typedef.type;
  }

  @override
  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder> arguments,
      [bool notInstanceContext]) {
    // For performance reasons, [typeVariables] aren't restored from [target].
    // So, if [arguments] is null, the default types should be retrieved from
    // [cls.typeParameters].
    if (arguments == null) {
      List<DartType> result = new List<DartType>.filled(
          typedef.typeParameters.length, null,
          growable: true);
      for (int i = 0; i < result.length; ++i) {
        result[i] = typedef.typeParameters[i].defaultType;
      }
      return result;
    }

    // [arguments] != null
    List<DartType> result =
        new List<DartType>.filled(arguments.length, null, growable: true);
    for (int i = 0; i < result.length; ++i) {
      result[i] = arguments[i].build(library);
    }
    return result;
  }

  @override
  bool get isNullAlias {
    DartType dartType = typedef.type;
    if (dartType is InterfaceType) {
      Uri importUri = dartType.classNode.enclosingLibrary.importUri;
      return dartType.classNode.name == "Null" &&
          importUri.scheme == "dart" &&
          importUri.path == "core";
    }
    return false;
  }
}
