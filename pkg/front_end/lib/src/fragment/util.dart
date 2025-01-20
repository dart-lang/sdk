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

  ConstructorName(
      {required this.name,
      required this.nameOffset,
      required this.fullName,
      required this.fullNameOffset,
      required this.fullNameLength})
      : assert(name != 'new');
}

void _buildMetadataForOutlineExpressions(
    SourceLibraryBuilder libraryBuilder,
    LookupScope parentScope,
    BodyBuilderContext bodyBuilderContext,
    Annotatable annotatable,
    List<MetadataBuilder>? metadata,
    {required Uri fileUri,
    required bool createFileUriExpression}) {
  MetadataBuilder.buildAnnotations(annotatable, metadata, bodyBuilderContext,
      libraryBuilder, fileUri, parentScope,
      createFileUriExpression: createFileUriExpression);
}

void _buildTypeParametersForOutlineExpressions(
    ClassHierarchy classHierarchy,
    SourceLibraryBuilder libraryBuilder,
    BodyBuilderContext bodyBuilderContext,
    LookupScope typeParameterScope,
    List<NominalParameterBuilder>? typeParameters) {
  if (typeParameters != null) {
    for (int i = 0; i < typeParameters.length; i++) {
      typeParameters[i].buildOutlineExpressions(libraryBuilder,
          bodyBuilderContext, classHierarchy, typeParameterScope);
    }
  }
}

void _buildFormalsForOutlineExpressions(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder? declarationBuilder,
    List<FormalParameterBuilder>? formals,
    {required bool isClassInstanceMember}) {
  if (formals != null) {
    for (FormalParameterBuilder formal in formals) {
      _buildFormalForOutlineExpressions(
          libraryBuilder, declarationBuilder, formal,
          isClassInstanceMember: isClassInstanceMember);
    }
  }
}

void _buildFormalForOutlineExpressions(SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder? declarationBuilder, FormalParameterBuilder formal,
    {required bool isClassInstanceMember}) {
  // For const constructors we need to include default parameter values
  // into the outline. For all other formals we need to call
  // buildOutlineExpressions to clear initializerToken to prevent
  // consuming too much memory.
  formal.buildOutlineExpressions(libraryBuilder, declarationBuilder,
      buildDefaultValue: isClassInstanceMember);
}

/// Common interface for fragments that can declare a field.
abstract class FieldDeclaration {
  /// The metadata declared on this fragment.
  List<MetadataBuilder>? get metadata;

  /// Builds the core AST structures for this field declaration as needed for
  /// the outline.
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f, FieldReference references,
      {required List<TypeParameter>? classTypeParameters});

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      LookupScope parentScope,
      List<Annotatable> annotatables,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression});

  int computeDefaultTypes(ComputeDefaultTypeContext context);

  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder,
      {required bool isAbstract, required bool isExternal});

  /// Checks the variance of type parameters [sourceClassBuilder] used in the
  /// type of this field declaration.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment);

  /// The references to the members from this field declaration that are
  /// accessible in exports through the name of the builder.
  Iterable<Reference> getExportedMemberReferences(FieldReference references);

  /// Return `true` if the declaration introduces a setter.
  bool get hasSetter;

  /// Return `true` if the declaration has an initializer.
  bool get hasInitializer;

  /// Return `true` if the declaration is final.
  bool get isFinal;

  /// Return `true` if the declaration is late.
  bool get isLate;

  /// Return `true` if the declaration is in instance field declared in an
  /// extension type.
  bool get isExtensionTypeDeclaredInstanceField;

  /// Returns `true` if this field is declared by an enum element.
  bool get isEnumElement;

  /// The [ClassMember]s for the getter introduced by this field declaration.
  List<ClassMember> get localMembers;

  /// The [ClassMember]s for the setter introduced by this field declaration,
  /// if any.
  List<ClassMember> get localSetters;

  /// The [Member] uses as the target for reading from this field declaration.
  Member get readTarget;

  /// The [Member] uses as the target for writing to this field declaration, or
  /// `null` if this field declaration has no setter.
  Member? get writeTarget;

  /// The [TypeBuilder] for the declared type of this field declaration.
  TypeBuilder get type;

  /// The [DartType] of this field declaration.
  abstract DartType fieldType;

  /// Creates the [Initializer] for the invalid initialization of this field.
  ///
  /// This is only used for instance fields.
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset});

  /// Creates the AST node for this field as the default initializer.
  ///
  /// This is only used for instance fields.
  void buildImplicitDefaultValue();

  /// Creates the [Initializer] for the implicit initialization of this field
  /// in a constructor.
  ///
  /// This is only used for instance fields.
  Initializer buildImplicitInitializer();

  /// Builds the [Initializer]s for each field used to encode this field
  /// using the [fileOffset] for the created nodes and [value] as the initial
  /// field value.
  ///
  /// This is only used for instance fields.
  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {required bool isSynthetic});

  /// Ensures that the type of this field declaration has been computed.
  void ensureTypes(
      ClassMembersBuilder membersBuilder,
      Set<ClassMember>? getterOverrideDependencies,
      Set<ClassMember>? setterOverrideDependencies);

  /// Infers the type of this field declaration.
  DartType inferType(ClassHierarchyBase hierarchy);

  shared.Expression? get initializerExpression;
}

mixin FieldDeclarationMixin
    implements FieldDeclaration, Inferable, InferredTypeListener {
  Uri get fileUri;

  int get nameOffset;

  SourcePropertyBuilder get builder;

  bool get isConst;

  void _setCovariantByClassInternal();

  abstract DartType _fieldTypeInternal;

  @override
  void onInferredType(DartType type) {
    fieldType = type;
  }

  @override
  void inferTypes(ClassHierarchyBase hierarchy) {
    inferType(hierarchy);
  }

  @override
  DartType inferType(ClassHierarchyBase hierarchy) {
    if (fieldType is! InferredType) {
      // We have already inferred a type.
      return fieldType;
    }

    return builder.libraryBuilder.loader
        .withUriForCrashReporting(fileUri, nameOffset, () {
      InferredType implicitFieldType = fieldType as InferredType;
      DartType inferredType = implicitFieldType.computeType(hierarchy);
      if (fieldType is InferredType) {
        // `fieldType` may have changed if a circularity was detected when
        // [inferredType] was computed.
        type.registerInferredType(inferredType);

        // TODO(johnniwinther): Isn't this handled in the [fieldType] setter?
        IncludesTypeParametersNonCovariantly? needsCheckVisitor;
        DeclarationBuilder? declarationBuilder = builder.declarationBuilder;
        if (declarationBuilder is ClassBuilder) {
          Class enclosingClass = declarationBuilder.cls;
          if (enclosingClass.typeParameters.isNotEmpty) {
            needsCheckVisitor = new IncludesTypeParametersNonCovariantly(
                enclosingClass.typeParameters,
                // We are checking the field type as if it is the type of the
                // parameter of the implicit setter and this is a contravariant
                // position.
                initialVariance: Variance.contravariant);
          }
        }
        if (needsCheckVisitor != null) {
          if (fieldType.accept(needsCheckVisitor)) {
            _setCovariantByClassInternal();
          }
        }
      }
      return fieldType;
    });
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType get fieldType => _fieldTypeInternal;

  @override
  void set fieldType(DartType value) {
    _fieldTypeInternal = value;
    DeclarationBuilder? declarationBuilder = builder.declarationBuilder;
    // TODO(johnniwinther): Should this be `hasSetter`?
    if (!isFinal && !isConst && declarationBuilder is ClassBuilder) {
      Class enclosingClass = declarationBuilder.cls;
      if (enclosingClass.typeParameters.isNotEmpty) {
        IncludesTypeParametersNonCovariantly needsCheckVisitor =
            new IncludesTypeParametersNonCovariantly(
                enclosingClass.typeParameters,
                // We are checking the field type as if it is the type of the
                // parameter of the implicit setter and this is a contravariant
                // position.
                initialVariance: Variance.contravariant);
        if (value.accept(needsCheckVisitor)) {
          _setCovariantByClassInternal();
        }
      }
    }
  }
}
