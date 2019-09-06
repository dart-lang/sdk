// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_variable_builder;

import 'builder.dart' show LibraryBuilder, TypeBuilder, TypeDeclarationBuilder;

import 'package:kernel/ast.dart'
    show DartType, TypeParameter, TypeParameterType;

import '../fasta_codes.dart' show templateTypeArgumentsOnTypeVariable;

import '../kernel/kernel_builder.dart'
    show ClassBuilder, NamedTypeBuilder, LibraryBuilder, TypeBuilder;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

class TypeVariableBuilder extends TypeDeclarationBuilder {
  TypeBuilder bound;

  TypeBuilder defaultType;

  final TypeParameter actualParameter;

  TypeVariableBuilder actualOrigin;

  TypeVariableBuilder(
      String name, SourceLibraryBuilder compilationUnit, int charOffset,
      {this.bound, bool synthesizeTypeParameterName: false})
      : actualParameter = new TypeParameter(
            synthesizeTypeParameterName ? '#$name' : name, null)
          ..fileOffset = charOffset,
        super(null, 0, name, compilationUnit, charOffset);

  TypeVariableBuilder.fromKernel(
      TypeParameter parameter, LibraryBuilder compilationUnit)
      : actualParameter = parameter,
        super(null, 0, parameter.name, compilationUnit, parameter.fileOffset);

  bool get isTypeVariable => true;

  String get debugName => "TypeVariableBuilder";

  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(name);
    if (bound != null) {
      buffer.write(" extends ");
      bound.printOn(buffer);
    }
    return buffer;
  }

  String toString() => "${printOn(new StringBuffer())}";

  TypeVariableBuilder get origin => actualOrigin ?? this;

  TypeParameter get parameter => origin.actualParameter;

  TypeParameter get target => parameter;

  DartType buildType(LibraryBuilder library, List<TypeBuilder> arguments) {
    if (arguments != null) {
      int charOffset = -1; // TODO(ahe): Provide these.
      Uri fileUri = null; // TODO(ahe): Provide these.
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
    }
    return new TypeParameterType(parameter);
  }

  DartType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    if (arguments != null) {
      int charOffset = -1; // TODO(ahe): Provide these.
      Uri fileUri = null; // TODO(ahe): Provide these.
      library.addProblem(
          templateTypeArgumentsOnTypeVariable.withArguments(name),
          charOffset,
          name.length,
          fileUri);
    }
    return buildType(library, null);
  }

  TypeBuilder asTypeBuilder() {
    return new NamedTypeBuilder(name, null)..bind(this);
  }

  void finish(
      LibraryBuilder library, ClassBuilder object, TypeBuilder dynamicType) {
    if (isPatch) return;
    DartType objectType = object.buildType(library, null);
    parameter.bound ??= bound?.build(library) ?? objectType;
    // If defaultType is not set, initialize it to dynamic, unless the bound is
    // explicitly specified as Object, in which case defaultType should also be
    // Object. This makes sure instantiation of generic function types with an
    // explicit Object bound results in Object as the instantiated type.
    parameter.defaultType ??= defaultType?.build(library) ??
        (bound != null && parameter.bound == objectType
            ? objectType
            : dynamicType.build(library));
  }

  void applyPatch(covariant TypeVariableBuilder patch) {
    patch.actualOrigin = this;
  }

  TypeVariableBuilder clone(List<TypeBuilder> newTypes) {
    // TODO(dmitryas): Figure out if using [charOffset] here is a good idea.
    // An alternative is to use the offset of the node the cloned type variable
    // is declared on.
    return new TypeVariableBuilder(name, parent, charOffset,
        bound: bound.clone(newTypes));
  }

  @override
  bool operator ==(Object other) {
    return other is TypeVariableBuilder && target == other.target;
  }

  @override
  int get hashCode => target.hashCode;

  static List<TypeParameter> typeParametersFromBuilders(
      List<TypeVariableBuilder> builders) {
    if (builders == null) return null;
    List<TypeParameter> result =
        new List<TypeParameter>.filled(builders.length, null, growable: true);
    for (int i = 0; i < builders.length; i++) {
      result[i] = builders[i].target;
    }
    return result;
  }
}
