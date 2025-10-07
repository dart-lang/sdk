// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class ConstructorName {
  /// The name of the constructor itself.
  ///
  /// For an unnamed constructor, this is ''.
  final String name;

  /// The offset of the name of the constructor, if the constructor is not
  /// unnamed.
  final int? nameOffset;

  /// The name of the constructor including the enclosing declaration name.
  ///
  /// For unnamed constructors the full name is normalized to be the class name,
  /// regardless of whether the constructor was declared with 'new'.
  ///
  /// For invalid constructor names, the full name is normalized to use the
  /// class name as prefix, regardless of whether the declaration did so.
  ///
  /// This means that not in all cases is the text pointed to by
  /// [fullNameOffset] and [fullNameLength] the same as the [fullName].
  final String fullName;

  /// The offset at which the full name occurs.
  ///
  /// This is used in messages to put the `^` at the start of the [fullName].
  final int fullNameOffset;

  /// The number of characters of full name that occurs at [fullNameOffset].
  ///
  /// This is used in messages to put the right amount of `^` under the name.
  final int fullNameLength;

  ConstructorName({
    required this.name,
    required this.nameOffset,
    required this.fullName,
    required this.fullNameOffset,
    required this.fullNameLength,
  }) : assert(name != 'new');
}

void buildMetadataForOutlineExpressions({
  required SourceLibraryBuilder libraryBuilder,
  required ExtensionScope extensionScope,
  required LookupScope scope,
  required BodyBuilderContext bodyBuilderContext,
  required Annotatable annotatable,
  required Uri annotatableFileUri,
  required Uri annotationsFileUri,
  required List<MetadataBuilder>? metadata,
}) {
  MetadataBuilder.buildAnnotations(
    annotatable: annotatable,
    annotatableFileUri: annotatableFileUri,
    annotationsFileUri: annotationsFileUri,
    metadata: metadata,
    bodyBuilderContext: bodyBuilderContext,
    libraryBuilder: libraryBuilder,
    extensionScope: extensionScope,
    scope: scope,
  );
}

void buildTypeParametersForOutlineExpressions(
  ClassHierarchy classHierarchy,
  SourceLibraryBuilder libraryBuilder,
  BodyBuilderContext bodyBuilderContext,
  List<SourceNominalParameterBuilder>? typeParameters,
) {
  if (typeParameters != null) {
    for (int i = 0; i < typeParameters.length; i++) {
      typeParameters[i].buildOutlineExpressions(
        libraryBuilder,
        bodyBuilderContext,
        classHierarchy,
      );
    }
  }
}

void buildFormalsForOutlineExpressions(
  SourceLibraryBuilder libraryBuilder,
  DeclarationBuilder? declarationBuilder,
  List<FormalParameterBuilder>? formals, {
  required ExtensionScope extensionScope,
  required LookupScope scope,
  required bool isClassInstanceMember,
}) {
  if (formals != null) {
    for (int i = 0; i < formals.length; i++) {
      FormalParameterBuilder formal = formals[i];
      buildFormalForOutlineExpressions(
        libraryBuilder,
        declarationBuilder,
        formal,
        extensionScope: extensionScope,
        scope: scope,
        isClassInstanceMember: isClassInstanceMember,
      );
    }
  }
}

void buildFormalForOutlineExpressions(
  SourceLibraryBuilder libraryBuilder,
  DeclarationBuilder? declarationBuilder,
  FormalParameterBuilder formal, {
  required ExtensionScope extensionScope,
  required LookupScope scope,
  required bool isClassInstanceMember,
}) {
  // For const constructors we need to include default parameter values
  // into the outline. For all other formals we need to call
  // buildOutlineExpressions to clear initializerToken to prevent
  // consuming too much memory.
  formal.buildOutlineExpressions(
    libraryBuilder,
    declarationBuilder,
    extensionScope: extensionScope,
    scope: scope,
    buildDefaultValue: isClassInstanceMember,
  );
}

sealed class PropertyEncodingStrategy {
  factory PropertyEncodingStrategy(
    DeclarationBuilder? declarationBuilder, {
    required bool isInstanceMember,
  }) {
    switch (declarationBuilder) {
      case null:
      case ClassBuilder():
        return const RegularPropertyEncodingStrategy();
      case ExtensionBuilder():
        if (isInstanceMember) {
          return const ExtensionInstancePropertyEncodingStrategy();
        } else {
          return const ExtensionStaticPropertyEncodingStrategy();
        }
      case ExtensionTypeDeclarationBuilder():
        if (isInstanceMember) {
          return const ExtensionTypeInstancePropertyEncodingStrategy();
        } else {
          return const ExtensionTypeStaticPropertyEncodingStrategy();
        }
    }
  }

  GetterEncoding createGetterEncoding(
    SourcePropertyBuilder builder,
    GetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  );

  SetterEncoding createSetterEncoding(
    SourcePropertyBuilder builder,
    SetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  );
}

class RegularPropertyEncodingStrategy implements PropertyEncodingStrategy {
  const RegularPropertyEncodingStrategy();

  @override
  GetterEncoding createGetterEncoding(
    SourcePropertyBuilder builder,
    GetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  ) {
    return new RegularGetterEncoding(fragment);
  }

  @override
  SetterEncoding createSetterEncoding(
    SourcePropertyBuilder builder,
    SetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  ) {
    return new RegularSetterEncoding(fragment);
  }
}

class ExtensionInstancePropertyEncodingStrategy
    implements PropertyEncodingStrategy {
  const ExtensionInstancePropertyEncodingStrategy();

  @override
  GetterEncoding createGetterEncoding(
    SourcePropertyBuilder builder,
    GetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  ) {
    ExtensionBuilder declarationBuilder =
        builder.declarationBuilder as ExtensionBuilder;
    SynthesizedExtensionSignature signature = new SynthesizedExtensionSignature(
      declarationBuilder: declarationBuilder,
      extensionTypeParameterFragments:
          fragment.enclosingDeclaration!.typeParameters,
      typeParameterFactory: typeParameterFactory,
      onTypeBuilder: declarationBuilder.onType,
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
    );
    return new ExtensionInstanceGetterEncoding(
      fragment,
      signature.clonedDeclarationTypeParameters,
      signature.thisFormal,
    );
  }

  @override
  SetterEncoding createSetterEncoding(
    SourcePropertyBuilder builder,
    SetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  ) {
    ExtensionBuilder declarationBuilder =
        builder.declarationBuilder as ExtensionBuilder;
    SynthesizedExtensionSignature signature = new SynthesizedExtensionSignature(
      declarationBuilder: declarationBuilder,
      extensionTypeParameterFragments:
          fragment.enclosingDeclaration!.typeParameters,
      typeParameterFactory: typeParameterFactory,
      onTypeBuilder: declarationBuilder.onType,
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
    );
    return new ExtensionInstanceSetterEncoding(
      fragment,
      signature.clonedDeclarationTypeParameters,
      signature.thisFormal,
    );
  }
}

class ExtensionStaticPropertyEncodingStrategy
    implements PropertyEncodingStrategy {
  const ExtensionStaticPropertyEncodingStrategy();

  @override
  GetterEncoding createGetterEncoding(
    SourcePropertyBuilder builder,
    GetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  ) {
    return new ExtensionStaticGetterEncoding(fragment);
  }

  @override
  SetterEncoding createSetterEncoding(
    SourcePropertyBuilder builder,
    SetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  ) {
    return new ExtensionStaticSetterEncoding(fragment);
  }
}

class ExtensionTypeInstancePropertyEncodingStrategy
    implements PropertyEncodingStrategy {
  const ExtensionTypeInstancePropertyEncodingStrategy();

  @override
  GetterEncoding createGetterEncoding(
    SourcePropertyBuilder builder,
    GetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  ) {
    ExtensionTypeDeclarationBuilder declarationBuilder =
        builder.declarationBuilder as ExtensionTypeDeclarationBuilder;
    SynthesizedExtensionTypeSignature signature =
        new SynthesizedExtensionTypeSignature(
          extensionTypeDeclarationBuilder: declarationBuilder,
          extensionTypeTypeParameters:
              fragment.enclosingDeclaration!.typeParameters,
          typeParameterFactory: typeParameterFactory,
          fileUri: fragment.fileUri,
          fileOffset: fragment.nameOffset,
        );
    return new ExtensionTypeInstanceGetterEncoding(
      fragment,
      signature.clonedDeclarationTypeParameters,
      signature.thisFormal,
    );
  }

  @override
  SetterEncoding createSetterEncoding(
    SourcePropertyBuilder builder,
    SetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  ) {
    ExtensionTypeDeclarationBuilder declarationBuilder =
        builder.declarationBuilder as ExtensionTypeDeclarationBuilder;
    SynthesizedExtensionTypeSignature signature =
        new SynthesizedExtensionTypeSignature(
          extensionTypeDeclarationBuilder: declarationBuilder,
          extensionTypeTypeParameters:
              fragment.enclosingDeclaration!.typeParameters,
          typeParameterFactory: typeParameterFactory,
          fileUri: fragment.fileUri,
          fileOffset: fragment.nameOffset,
        );
    return new ExtensionTypeInstanceSetterEncoding(
      fragment,
      signature.clonedDeclarationTypeParameters,
      signature.thisFormal,
    );
  }
}

class ExtensionTypeStaticPropertyEncodingStrategy
    implements PropertyEncodingStrategy {
  const ExtensionTypeStaticPropertyEncodingStrategy();

  @override
  GetterEncoding createGetterEncoding(
    SourcePropertyBuilder builder,
    GetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  ) {
    return new ExtensionTypeStaticGetterEncoding(fragment);
  }

  @override
  SetterEncoding createSetterEncoding(
    SourcePropertyBuilder builder,
    SetterFragment fragment,
    TypeParameterFactory typeParameterFactory,
  ) {
    return new ExtensionTypeStaticSetterEncoding(fragment);
  }
}
