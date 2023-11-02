// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show DartType, InvalidType, NamedType, RecordType, Supertype;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/unaliasing.dart';

import '../fasta_codes.dart'
    show
        messageNamedFieldClashesWithPositionalFieldInRecord,
        messageObjectMemberNameUsedForRecordField,
        messageRecordFieldsCantBePrivate,
        messageSupertypeIsFunction,
        noLength,
        templateDuplicatedRecordTypeFieldName,
        templateDuplicatedRecordTypeFieldNameContext;
import '../kernel/implicit_field_type.dart';
import '../source/source_library_builder.dart';
import '../util/helpers.dart';
import 'inferable_type_builder.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

abstract class RecordTypeBuilderImpl extends RecordTypeBuilder {
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

  factory RecordTypeBuilderImpl(
      List<RecordTypeFieldBuilder>? positional,
      List<RecordTypeFieldBuilder>? named,
      NullabilityBuilder nullabilityBuilder,
      Uri fileUri,
      int charOffset) {
    bool isExplicit = true;
    if (positional != null) {
      for (RecordTypeFieldBuilder field in positional) {
        if (!field.type.isExplicit) {
          isExplicit = false;
          break;
        }
      }
    }
    if (isExplicit && named != null) {
      for (RecordTypeFieldBuilder field in named) {
        if (!field.type.isExplicit) {
          isExplicit = false;
          break;
        }
      }
    }
    return isExplicit
        ? new _ExplicitRecordTypeBuilder(
            positional, named, nullabilityBuilder, fileUri, charOffset)
        : new _InferredRecordTypeBuilder(
            positional, named, nullabilityBuilder, fileUri, charOffset);
  }

  RecordTypeBuilderImpl._(this.positionalFields, this.namedFields,
      this.nullabilityBuilder, this.fileUri, this.charOffset);

  @override
  TypeName? get typeName => null;

  @override
  String get debugName => "Record";

  @override
  bool get isVoidType => false;

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
          buffer.write(" ");
          buffer.write(field.name);
        }
      }
    }
    if (namedFields != null) {
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
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    DartType aliasedType = buildAliased(library, typeUse, hierarchy);
    return unalias(aliasedType,
        legacyEraseAliases: !library.isNonNullableByDefault);
  }

  @override
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    assert(hierarchy != null || isExplicit, "Cannot build $this.");
    const List<String> forbiddenObjectMemberNames = [
      "noSuchMethod",
      "toString",
      "hashCode",
      "runtimeType"
    ];
    List<DartType> positionalEntries = <DartType>[];
    Map<String, RecordTypeFieldBuilder> fieldsMap =
        <String, RecordTypeFieldBuilder>{};
    bool hasErrors = false;
    if (positionalFields != null) {
      for (RecordTypeFieldBuilder field in positionalFields!) {
        DartType type = field.type
            .buildAliased(library, TypeUse.recordEntryType, hierarchy);
        positionalEntries.add(type);
        String? fieldName = field.name;
        if (fieldName != null) {
          if (fieldName.startsWith("_")) {
            library.addProblem(messageRecordFieldsCantBePrivate,
                field.charOffset, fieldName.length, fileUri);
            hasErrors = true;
            continue;
          }
          if (forbiddenObjectMemberNames.contains(fieldName)) {
            library.addProblem(messageObjectMemberNameUsedForRecordField,
                field.charOffset, fieldName.length, fileUri);
            hasErrors = true;
            continue;
          }
          RecordTypeFieldBuilder? existingField = fieldsMap[fieldName];
          if (existingField != null) {
            library.addProblem(
                templateDuplicatedRecordTypeFieldName.withArguments(fieldName),
                field.charOffset,
                fieldName.length,
                fileUri,
                context: [
                  templateDuplicatedRecordTypeFieldNameContext
                      .withArguments(fieldName)
                      .withLocation(
                          fileUri, existingField.charOffset, fieldName.length)
                ]);
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
        DartType type = field.type
            .buildAliased(library, TypeUse.recordEntryType, hierarchy);
        String? name = field.name;
        if (name == null) {
          hasErrors = true;
          continue;
        }
        if (forbiddenObjectMemberNames.contains(name)) {
          library.addProblem(messageObjectMemberNameUsedForRecordField,
              field.charOffset, name.length, fileUri);
          hasErrors = true;
          continue;
        }
        if (name.startsWith("_")) {
          library.addProblem(messageRecordFieldsCantBePrivate, field.charOffset,
              name.length, fileUri);
          hasErrors = true;
          continue;
        }
        if (tryParseRecordPositionalGetterName(
                name, positionalFields?.length ?? 0) !=
            null) {
          library.addProblem(
              messageNamedFieldClashesWithPositionalFieldInRecord,
              field.charOffset,
              name.length,
              fileUri);
          hasErrors = true;
          continue;
        }
        RecordTypeFieldBuilder? existingField = fieldsMap[name];
        if (existingField != null) {
          library.addProblem(
              templateDuplicatedRecordTypeFieldName.withArguments(name),
              field.charOffset,
              name.length,
              fileUri,
              context: [
                templateDuplicatedRecordTypeFieldNameContext
                    .withArguments(name)
                    .withLocation(
                        fileUri, existingField.charOffset, name.length)
              ]);
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
    return new RecordType(positionalEntries, namedEntries ?? [],
        nullabilityBuilder.build(library));
  }

  @override
  Supertype? buildSupertype(LibraryBuilder library) {
    library.addProblem(
        messageSupertypeIsFunction, charOffset, noLength, fileUri);
    return null;
  }

  @override
  Supertype? buildMixedInType(LibraryBuilder library) {
    return buildSupertype(library);
  }

  @override
  RecordTypeBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    List<RecordTypeFieldBuilder>? clonedPositional;
    if (positionalFields != null) {
      clonedPositional = new List<RecordTypeFieldBuilder>.generate(
          positionalFields!.length, (int i) {
        RecordTypeFieldBuilder entry = positionalFields![i];
        return entry.clone(newTypes, contextLibrary, contextDeclaration);
      }, growable: false);
    }
    List<RecordTypeFieldBuilder>? clonedNamed;
    if (namedFields != null) {
      clonedNamed = new List<RecordTypeFieldBuilder>.generate(
          namedFields!.length, (int i) {
        RecordTypeFieldBuilder entry = namedFields![i];
        return entry.clone(newTypes, contextLibrary, contextDeclaration);
      }, growable: false);
    }
    return new RecordTypeBuilderImpl(
        clonedPositional, clonedNamed, nullabilityBuilder, fileUri, charOffset);
  }

  @override
  RecordTypeBuilder withNullabilityBuilder(
      NullabilityBuilder nullabilityBuilder) {
    return new RecordTypeBuilderImpl(
        positionalFields, namedFields, nullabilityBuilder, fileUri, charOffset);
  }
}

/// A record type that is defined without the need for type inference.
///
/// This is the normal record type whose field types are either explicit or
/// omitted.
class _ExplicitRecordTypeBuilder extends RecordTypeBuilderImpl {
  _ExplicitRecordTypeBuilder(
      List<RecordTypeFieldBuilder>? positionalFields,
      List<RecordTypeFieldBuilder>? namedFields,
      NullabilityBuilder nullabilityBuilder,
      Uri fileUri,
      int charOffset)
      : super._(positionalFields, namedFields, nullabilityBuilder, fileUri,
            charOffset);

  @override
  bool get isExplicit => true;

  DartType? _type;

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    return _type ??= _buildInternal(library, typeUse, hierarchy);
  }
}

/// A record type that needs type inference to be fully defined.
///
/// This occurs through macros where field types can be defined in terms of
/// inferred types, making this type indirectly depend on type inference.
class _InferredRecordTypeBuilder extends RecordTypeBuilderImpl
    with InferableTypeBuilderMixin {
  _InferredRecordTypeBuilder(
      List<RecordTypeFieldBuilder>? positionalFields,
      List<RecordTypeFieldBuilder>? namedFields,
      NullabilityBuilder nullabilityBuilder,
      Uri fileUri,
      int charOffset)
      : super._(positionalFields, namedFields, nullabilityBuilder, fileUri,
            charOffset);

  @override
  bool get isExplicit => false;

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    if (hasType) {
      return type;
    } else if (hierarchy != null) {
      return registerType(_buildInternal(library, typeUse, hierarchy));
    } else {
      InferableTypeUse inferableTypeUse =
          new InferableTypeUse(library as SourceLibraryBuilder, this, typeUse);
      library.registerInferableType(inferableTypeUse);
      return new InferredType.fromInferableTypeUse(inferableTypeUse);
    }
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

  RecordTypeFieldBuilder(this.metadata, this.type, this.name, this.charOffset);

  RecordTypeFieldBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    // TODO(cstefantsova):  It's not clear how [metadata] is used currently,
    // and how it should be cloned.  Consider cloning it instead of reusing it.
    return new RecordTypeFieldBuilder(
        metadata,
        type.clone(newTypes, contextLibrary, contextDeclaration),
        name,
        charOffset);
  }

  @override
  String toString() {
    return 'RecordTypeFieldBuilder(type=$type,name=$name)';
  }
}
