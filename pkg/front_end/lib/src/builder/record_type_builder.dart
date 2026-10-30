// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart'
    show
        DartType,
        DartTypeList,
        InvalidType,
        NamedDartTypeList,
        NamedType,
        Nullability,
        RecordType,
        Supertype,
        Variance;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;
import 'package:kernel/src/unaliasing.dart';

import '../codes/cfe_codes.dart' show noLength;
import '../kernel/type_algorithms.dart';
import '../source/source_library_builder.dart';
import '../source/source_loader.dart';
import '../source/type_parameter_factory.dart';
import '../util/helpers.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

class RecordTypeBuilderImpl extends RecordTypeBuilder {
  @override
  final List<RecordTypeFieldBuilder>? positionalFields;
  @override
  final List<RecordTypeFieldBuilder>? namedFields;
  @override
  final NullabilityBuilder nullabilityBuilder;
  @override
  final Uri fileUri;
  @override
  final int charOffset;

  new(
    this.positionalFields,
    this.namedFields,
    this.nullabilityBuilder,
    this.fileUri,
    this.charOffset,
  );

  @override
  // Coverage-ignore(suite): Not run.
  TypeName? get typeName => null;

  @override
  String get debugName => "Record";

  @override
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write("(");
    bool isFirst = true;
    if (positionalFields != null) {
      for (RecordTypeFieldBuilder field in positionalFields!) {
        if (!isFirst) {
          buffer.write(", ");
        } else {
          isFirst = false;
        }
        field.type.printOn(buffer);
        if (field.name != null) {
          // Coverage-ignore-block(suite): Not run.
          buffer.write(" ");
          buffer.write(field.name);
        }
      }
    }
    if (namedFields != null) {
      // Coverage-ignore-block(suite): Not run.
      if (!isFirst) {
        buffer.write(", ");
      }
      isFirst = true;
      buffer.write("{");
      for (RecordTypeFieldBuilder field in namedFields!) {
        if (!isFirst) {
          buffer.write(", ");
        } else {
          isFirst = false;
        }
        field.type.printOn(buffer);
        if (field.name != null) {
          buffer.write(" ");
          buffer.write(field.name);
        }
      }
      buffer.write("}");
    }
    buffer.write(")");
    nullabilityBuilder.writeNullabilityOn(buffer);
    return buffer;
  }

  DartType _buildInternal(
    LibraryBuilder library,
    TypeUse typeUse,
    ClassHierarchyBase? hierarchy,
  ) {
    DartType aliasedType = buildAliased(library, typeUse, hierarchy);
    return unalias(aliasedType);
  }

  @override
  DartType buildAliased(
    LibraryBuilder library,
    TypeUse typeUse,
    ClassHierarchyBase? hierarchy,
  ) {
    assert(hierarchy != null || isExplicit, "Cannot build $this.");
    const List<String> forbiddenObjectMemberNames = [
      "noSuchMethod",
      "toString",
      "hashCode",
      "runtimeType",
    ];
    List<DartType> positionalEntries = <DartType>[];
    Map<String, RecordTypeFieldBuilder> fieldsMap =
        <String, RecordTypeFieldBuilder>{};
    bool hasErrors = false;
    if (positionalFields != null) {
      for (RecordTypeFieldBuilder field in positionalFields!) {
        DartType type = field.type.buildAliased(
          library,
          TypeUse.recordEntryType,
          hierarchy,
        );
        positionalEntries.add(type);
        String? fieldName = field.name;
        if (fieldName != null) {
          if (library is SourceLibraryBuilder && field.isWildcard) {
            continue;
          }
          if (fieldName.startsWith("_")) {
            library.addProblem(
              diag.recordFieldsCantBePrivate,
              field.charOffset,
              fieldName.length,
              fileUri,
            );
            hasErrors = true;
            continue;
          }
          if (forbiddenObjectMemberNames.contains(fieldName)) {
            library.addProblem(
              diag.objectMemberNameUsedForRecordField,
              field.charOffset,
              fieldName.length,
              fileUri,
            );
            hasErrors = true;
            continue;
          }
          RecordTypeFieldBuilder? existingField = fieldsMap[fieldName];
          if (existingField != null) {
            library.addProblem(
              diag.duplicatedRecordTypeFieldName.withArguments(
                fieldName: fieldName,
              ),
              field.charOffset,
              fieldName.length,
              fileUri,
              context: [
                diag.duplicatedRecordTypeFieldNameContext
                    .withArguments(fieldName: fieldName)
                    .withLocation(
                      fileUri,
                      existingField.charOffset,
                      fieldName.length,
                    ),
              ],
            );
            hasErrors = true;
            continue;
          } else {
            fieldsMap[fieldName] = field;
          }
        }
      }
      if (hasErrors) {
        return const InvalidType();
      }
    }

    List<NamedType>? namedEntries;
    if (namedFields != null) {
      namedEntries = <NamedType>[];
      for (RecordTypeFieldBuilder field in namedFields!) {
        DartType type = field.type.buildAliased(
          library,
          TypeUse.recordEntryType,
          hierarchy,
        );
        String? name = field.name;
        if (name == null) {
          hasErrors = true;
          continue;
        }
        if (forbiddenObjectMemberNames.contains(name)) {
          library.addProblem(
            diag.objectMemberNameUsedForRecordField,
            field.charOffset,
            name.length,
            fileUri,
          );
          hasErrors = true;
          continue;
        }
        if (name.startsWith("_")) {
          library.addProblem(
            diag.recordFieldsCantBePrivate,
            field.charOffset,
            name.length,
            fileUri,
          );
          hasErrors = true;
          continue;
        }
        if (tryParseRecordPositionalGetterName(
              name,
              positionalFields?.length ?? 0,
            ) !=
            null) {
          library.addProblem(
            diag.namedFieldClashesWithPositionalFieldInRecord,
            field.charOffset,
            name.length,
            fileUri,
          );
          hasErrors = true;
          continue;
        }
        RecordTypeFieldBuilder? existingField = fieldsMap[name];
        if (existingField != null) {
          library.addProblem(
            diag.duplicatedRecordTypeFieldName.withArguments(fieldName: name),
            field.charOffset,
            name.length,
            fileUri,
            context: [
              diag.duplicatedRecordTypeFieldNameContext
                  .withArguments(fieldName: name)
                  .withLocation(fileUri, existingField.charOffset, name.length),
            ],
          );
          hasErrors = true;
          continue;
        }

        namedEntries.add(new NamedType(name, type, isRequired: true));
        fieldsMap[name] = field;
      }
      if (hasErrors) {
        // An error has already been reported in the parser.
        return const InvalidType();
      }
      namedEntries.sort();
    }

    if (library is SourceLibraryBuilder &&
        !library.libraryFeatures.records.isEnabled) {
      // TODO(johnniwinther): Remove this when backends can handle record types
      // without crashing.
      return const InvalidType();
    }

    // TODO(johnniwinther): Should we create an [InvalidType] if there is <= 1
    // entries?
    return new RecordType(
      new DartTypeList.from(positionalEntries),
      namedEntries == null
          ? NamedDartTypeList.empty
          : new NamedDartTypeList.from(namedEntries),
      nullabilityBuilder.build(),
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Supertype? buildSupertype(LibraryBuilder library, TypeUse typeUse) {
    library.addProblem(diag.supertypeIsFunction, charOffset, noLength, fileUri);
    return null;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Supertype? buildMixedInType(LibraryBuilder library) {
    return buildSupertype(library, TypeUse.classWithType);
  }

  @override
  RecordTypeBuilder withNullabilityBuilder(
    NullabilityBuilder nullabilityBuilder,
  ) {
    return new RecordTypeBuilderImpl(
      positionalFields,
      namedFields,
      nullabilityBuilder,
      fileUri,
      charOffset,
    );
  }

  @override
  Nullability computeNullability({
    required Map<TypeParameterBuilder, TraversalState>
    typeParametersTraversalState,
  }) {
    return nullabilityBuilder.build();
  }

  @override
  VarianceCalculationValue computeTypeParameterBuilderVariance(
    NominalParameterBuilder variable, {
    required SourceLoader sourceLoader,
  }) {
    List<RecordTypeFieldBuilder>? positionalFields = this.positionalFields;
    List<RecordTypeFieldBuilder>? namedFields = this.namedFields;
    Variance result = Variance.unrelated;
    if (positionalFields != null) {
      for (RecordTypeFieldBuilder field in positionalFields) {
        result = result.meet(
          field.type
              .computeTypeParameterBuilderVariance(
                variable,
                sourceLoader: sourceLoader,
              )
              .variance!,
        );
      }
    }
    if (namedFields != null) {
      for (RecordTypeFieldBuilder field in namedFields) {
        result = result.meet(
          field.type
              .computeTypeParameterBuilderVariance(
                variable,
                sourceLoader: sourceLoader,
              )
              .variance!,
        );
      }
    }
    return new VarianceCalculationValue.fromVariance(result);
  }

  @override
  TypeDeclarationBuilder? computeUnaliasedDeclaration({
    required bool isUsedAsClass,
  }) => null;

  @override
  void collectReferencesFrom(
    Map<TypeParameterBuilder, int> parameterIndices,
    List<List<int>> edges,
    int index,
  ) {
    List<RecordTypeFieldBuilder>? positionalFields = this.positionalFields;
    List<RecordTypeFieldBuilder>? namedFields = this.namedFields;
    if (positionalFields != null) {
      for (RecordTypeFieldBuilder field in positionalFields) {
        field.type.collectReferencesFrom(parameterIndices, edges, index);
      }
    }
    if (namedFields != null) {
      for (RecordTypeFieldBuilder field in namedFields) {
        field.type.collectReferencesFrom(parameterIndices, edges, index);
      }
    }
  }

  @override
  TypeBuilder? substituteRange(
    Map<TypeParameterBuilder, TypeBuilder> upperSubstitution,
    Map<TypeParameterBuilder, TypeBuilder> lowerSubstitution,
    TypeParameterFactory typeParameterFactory, {
    Variance variance = Variance.covariant,
  }) {
    List<RecordTypeFieldBuilder>? positionalFields = this.positionalFields;
    List<RecordTypeFieldBuilder>? namedFields = this.namedFields;

    List<RecordTypeFieldBuilder>? newPositionalFields;
    List<RecordTypeFieldBuilder>? newNamedFields;
    if (positionalFields != null) {
      for (int i = 0; i < positionalFields.length; i++) {
        RecordTypeFieldBuilder positionalFieldBuilder = positionalFields[i];
        TypeBuilder? positionalFieldType = positionalFieldBuilder.type
            .substituteRange(
              upperSubstitution,
              lowerSubstitution,
              typeParameterFactory,
              variance: variance,
            );
        if (positionalFieldType != null) {
          newPositionalFields ??= positionalFields.toList();
          newPositionalFields[i] = new RecordTypeFieldBuilder(
            positionalFieldBuilder.metadata,
            positionalFieldType,
            positionalFieldBuilder.name,
            positionalFieldBuilder.charOffset,
          );
        }
      }
    }
    if (namedFields != null) {
      for (int i = 0; i < namedFields.length; i++) {
        RecordTypeFieldBuilder namedFieldBuilder = namedFields[i];
        TypeBuilder? namedFieldType = namedFieldBuilder.type.substituteRange(
          upperSubstitution,
          lowerSubstitution,
          typeParameterFactory,
          variance: variance,
        );
        if (namedFieldType != null) {
          newNamedFields ??= namedFields.toList();
          newNamedFields[i] = new RecordTypeFieldBuilder(
            namedFieldBuilder.metadata,
            namedFieldType,
            namedFieldBuilder.name,
            namedFieldBuilder.charOffset,
          );
        }
      }
    }

    if (positionalFields != null || newNamedFields != null) {
      return new RecordTypeBuilderImpl(
        newPositionalFields ?? positionalFields,
        newNamedFields ?? namedFields,
        this.nullabilityBuilder,
        this.fileUri,
        this.charOffset,
      );
    }
    return null;
  }

  @override
  TypeBuilder? unaliasAndErase() => this;

  @override
  bool usesTypeParameters(Set<String> typeParameterNames) {
    if (positionalFields != null) {
      for (RecordTypeFieldBuilder fieldBuilder in positionalFields!) {
        if (fieldBuilder.type.usesTypeParameters(typeParameterNames)) {
          return true;
        }
      }
    }
    // Coverage-ignore(suite): Not run.
    if (namedFields != null) {
      for (RecordTypeFieldBuilder fieldBuilder in namedFields!) {
        if (fieldBuilder.type.usesTypeParameters(typeParameterNames)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  List<TypeWithInBoundReferences> findRawTypesWithInboundReferences() {
    List<TypeWithInBoundReferences> typesAndDependencies = [];
    List<RecordTypeFieldBuilder>? positionalFields = this.positionalFields;
    List<RecordTypeFieldBuilder>? namedFields = this.namedFields;
    if (positionalFields != null) {
      for (RecordTypeFieldBuilder field in positionalFields) {
        typesAndDependencies.addAll(
          field.type.findRawTypesWithInboundReferences(),
        );
      }
    }
    if (namedFields != null) {
      for (RecordTypeFieldBuilder field in namedFields) {
        typesAndDependencies.addAll(
          field.type.findRawTypesWithInboundReferences(),
        );
      }
    }
    return typesAndDependencies;
  }

  @override
  bool get isExplicit => true;

  DartType? _type;

  @override
  DartType build(
    LibraryBuilder library,
    TypeUse typeUse, {
    ClassHierarchyBase? hierarchy,
  }) {
    return _type ??= _buildInternal(library, typeUse, hierarchy);
  }
}

class RecordTypeFieldBuilder {
  /// List of metadata builders for the metadata declared on this record type
  /// entry.
  final List<MetadataBuilder>? metadata;

  final TypeBuilder type;

  /// The name of the record field, if provided.
  ///
  /// In case of a named record field without a name, this is `null`. An
  /// error will have been reported in the parser.
  final String? name;

  final int charOffset;

  final bool isWildcard;

  new(
    this.metadata,
    this.type,
    this.name,
    this.charOffset, {
    this.isWildcard = false,
  });

  @override
  String toString() {
    return 'RecordTypeFieldBuilder(type=$type,name=$name)';
  }
}
