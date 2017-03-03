// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_mixin_application_builder;

import 'package:kernel/ast.dart' show InterfaceType, Supertype, setParents;

import '../modifier.dart' show abstractMask;

import 'kernel_builder.dart'
    show
        Builder,
        ConstructorReferenceBuilder,
        KernelLibraryBuilder,
        KernelNamedTypeBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MixinApplicationBuilder,
        TypeBuilder,
        TypeVariableBuilder;

import '../util/relativize.dart' show relativizeUri;

import '../source/source_class_builder.dart' show SourceClassBuilder;

class KernelMixinApplicationBuilder
    extends MixinApplicationBuilder<KernelTypeBuilder>
    implements KernelTypeBuilder {
  final int charOffset;

  final String relativeFileUri;

  final KernelLibraryBuilder library;

  Supertype builtType;

  List<TypeVariableBuilder> typeVariables;

  String subclassName;

  KernelMixinApplicationBuilder(KernelTypeBuilder supertype,
      List<KernelTypeBuilder> mixins, this.library, int charOffset, Uri fileUri)
      : charOffset = charOffset,
        relativeFileUri = relativizeUri(fileUri),
        super(supertype, mixins, charOffset, fileUri);

  InterfaceType build(LibraryBuilder library) {
    return buildSupertype(library)?.asInterfaceType;
  }

  Supertype buildSupertype(LibraryBuilder library) {
    if (builtType != null) return builtType;
    KernelTypeBuilder s = this.supertype;
    for (KernelTypeBuilder builder in mixins) {
      s = applyMixin(s, builder);
    }
    builtType = s.buildSupertype(library);
    return builtType;
  }

  TypeBuilder applyMixin(TypeBuilder supertype, TypeBuilder mixin) {
    KernelLibraryBuilder library = this.library.partOfLibrary ?? this.library;
    List<KernelTypeBuilder> typeArguments;
    List<TypeVariableBuilder> newTypeVariables;
    if (typeVariables != null) {
      assert(subclassName != null);
      newTypeVariables = library.copyTypeVariables(typeVariables);
      Map<TypeVariableBuilder, TypeBuilder> substitution =
          <TypeVariableBuilder, TypeBuilder>{};
      typeArguments = <KernelTypeBuilder>[];
      for (int i = 0; i < typeVariables.length; i++) {
        substitution[typeVariables[i]] = newTypeVariables[i].asTypeBuilder();
        typeArguments.add(typeVariables[i].asTypeBuilder());
      }
      supertype = supertype.subst(substitution);
      mixin = mixin.subst(substitution);
    }
    // To reduce diff against dartk, we create a different name for mixin
    // applications that have free type variables. We do this by setting
    // [subclassName] when setting typeVariables.
    String name = subclassName != null
        ? "${subclassName}^${mixin.name}"
        : "${supertype.name}&${mixin.name}";

    SourceClassBuilder cls =
        library.mixinApplicationClasses.putIfAbsent(name, () {
      SourceClassBuilder cls = new SourceClassBuilder(
          null,
          abstractMask,
          name,
          newTypeVariables,
          supertype,
          null,
          <String, Builder>{},
          library,
          <ConstructorReferenceBuilder>[],
          charOffset,
          null,
          mixin);
      library.addImplementationBuilder(name, cls, charOffset);
      if (newTypeVariables != null) {
        for (KernelTypeVariableBuilder t in newTypeVariables) {
          cls.cls.typeParameters.add(t.parameter);
        }
        setParents(cls.cls.typeParameters, cls.cls);
      }
      return cls;
    });
    return new KernelNamedTypeBuilder(
        name, typeArguments, charOffset, library.fileUri)..builder = cls;
  }
}
