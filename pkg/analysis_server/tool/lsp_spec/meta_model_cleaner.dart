// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

import 'meta_model.dart';

/// Helper methods to clean the meta model to produce better Dart classes.
///
/// Cleaning includes:
///
/// - Unwrapping comments that have been wrapped in the source model
/// - Removing relative hyperlinks from comments that assume rendering in an
///     HTML page with anchors
/// - Merging types that are distinct in the meta model but we want as one
/// - Removing types in the spec that we will never use
/// - Renaming types that may have long or sub-optimal generated names
/// - Simplifying union types that contain duplicates/overlaps
class LspMetaModelCleaner {
  /// A pattern to match newlines in source comments that are likely for
  /// wrapping and not formatting. This allows us to rewrap based on our indent
  /// level/line length without potentially introducing very short lines.
  final _sourceCommentWrappingNewlinesPattern =
      RegExp(r'\w[`\]\)\}.]*\n[`\[\{\(]*\w');

  /// A pattern matching the spec's older HTML links that we can extract type
  /// references from.
  ///
  ///     A description of [SomeType[]] (#SomeType).
  final _sourceCommentDocumentLinksPattern =
      RegExp(r'\[`?([\w \-.]+)(?:\[\])?`?\]\s?\((#[^)]+)\)');

  /// A pattern matching references in the LSP meta model comments that
  /// reference other types.
  ///
  ///     {@link TypeName description}
  ///
  /// Type names may have suffixes that shouldn't be included in the group such
  /// as
  ///
  ///     {@link TypeName[] description}
  final _sourceCommentReferencesPattern =
      RegExp(r'{@link\s+([\w.]+)[\[\]]*(?:\s+[\w`. ]+[\[\]]*)?}');

  /// A pattern that matches references in the LSP meta model comments to the
  /// Thenable or Promise types.
  final _sourceCommentThenablePromisePattern =
      RegExp(r'\b(?:Thenable|Promise)\b');

  /// Whether to include proposed types and fields in generated code.
  ///
  /// The LSP meta model is often regenerated from the latest code and includes
  /// unreleased/proposed APIs that we usually don't want to pollute the
  /// generated code with until they are finalized.
  final includeProposed = false;

  /// Cleans an entire [LspMetaModel].
  LspMetaModel cleanModel(LspMetaModel model) {
    var types = cleanTypes(model.types);
    return LspMetaModel(
      types: types,
      methods: model.methods.where(_includeEntityInOutput).toList(),
    );
  }

  /// Cleans a List of types.
  List<LspEntity> cleanTypes(List<LspEntity> types) {
    types = _mergeTypes(types);
    types = types.where(_includeEntityInOutput).map(_clean).toList();
    types = _renameTypes(types).where(_includeEntityInOutput).toList();
    return types;
  }

  /// Whether a type should be retained type signatures in generated code.
  bool _allowTypeInUnions(TypeBase type) {
    // Don't allow arrays of MarkedStrings, but do allow simple MarkedStrings.
    // The only place that uses these are Hovers and we only send one value
    // (to match the MarkupString equiv) so the array just makes the types
    // unnecessarily complicated.
    if (type is ArrayType) {
      // TODO(dantup): Consider removing this, it's not adding much.
      var elementType = type.elementType;
      if (elementType is TypeReference && elementType.name == 'MarkedString') {
        return false;
      }
    }
    return true;
  }

  /// Cleans a single [LspEntity].
  LspEntity _clean(LspEntity type) {
    if (type is Interface) {
      return _cleanInterface(type);
    } else if (type is LspEnum) {
      return _cleanNamespace(type);
    } else if (type is TypeAlias) {
      return _cleanTypeAlias(type);
    } else {
      throw 'Cleaning $type is not implemented.';
    }
  }

  String? _cleanComment(String? text) {
    if (text == null) {
      return text;
    }

    // Unwrap any wrapping in the source by replacing any matching newlines with
    // spaces.
    text = text.replaceAllMapped(
      _sourceCommentWrappingNewlinesPattern,
      (match) => match.group(0)!.replaceAll('\n', ' '),
    );

    // Replace any references to other types with a format that's valid for
    // Dart.
    text = text.replaceAllMapped(
      _sourceCommentDocumentLinksPattern,
      (match) => '[${match.group(1)!}]',
    );
    text = text.replaceAllMapped(
      _sourceCommentReferencesPattern,
      (match) => '[${match.group(1)!}]',
    );

    // Replace any references to Thenable/Promise to Future.
    text = text.replaceAllMapped(
      _sourceCommentThenablePromisePattern,
      (match) => '[Future]',
    );

    return text;
  }

  Constant _cleanConst(Constant const_) {
    return Constant(
      name: const_.name,
      comment: _cleanComment(const_.comment),
      type: _cleanType(const_.type),
      value: const_.value,
    );
  }

  Field _cleanField(String parentName, Field field) {
    var improvedType = _getImprovedType(parentName, field.name);
    var type = improvedType ?? field.type;

    return Field(
      name: field.name,
      comment: _cleanComment(field.comment),
      type: _cleanType(type),
      allowsNull: field.allowsNull,
      allowsUndefined: field.allowsUndefined,
    );
  }

  Interface _cleanInterface(Interface interface) {
    return Interface(
      name: interface.name,
      comment: _cleanComment(interface.comment),
      isProposed: interface.isProposed,
      baseTypes: interface.baseTypes
          .where((type) => _includeTypeInOutput(type.name))
          .toList(),
      members: interface.members
          .where(_includeEntityInOutput)
          .map((member) => _cleanMember(interface.name, member))
          .toList(),
    );
  }

  Member _cleanMember(String parentName, Member member) {
    if (member is Field) {
      return _cleanField(parentName, member);
    } else if (member is Constant) {
      return _cleanConst(member);
    } else {
      throw 'Cleaning $member is not implemented.';
    }
  }

  LspEnum _cleanNamespace(LspEnum namespace) {
    return LspEnum(
      name: namespace.name,
      comment: _cleanComment(namespace.comment),
      isProposed: namespace.isProposed,
      typeOfValues: namespace.typeOfValues,
      members: namespace.members
          .where(_includeEntityInOutput)
          .map((member) => _cleanMember(namespace.name, member))
          .toList(),
    );
  }

  TypeBase _cleanType(TypeBase type) {
    if (type is UnionType) {
      return _cleanUnionType(type);
    } else if (type is ArrayType) {
      return ArrayType(_cleanType(type.elementType));
    } else {
      return type;
    }
  }

  TypeAlias _cleanTypeAlias(TypeAlias typeAlias) {
    return TypeAlias(
      name: typeAlias.name,
      comment: _cleanComment(typeAlias.comment),
      baseType: _cleanType(typeAlias.baseType),
      renameReferences: typeAlias.renameReferences,
    );
  }

  /// Removes any duplicate types in a union.
  ///
  /// For example, if we map multiple types into `Object?` we don't want to end
  /// up with `Either2<Object?, Object?>`.
  ///
  /// Key on `dartType` to ensure we combine different types that will map down
  /// to the same type.
  TypeBase _cleanUnionType(UnionType type) {
    var uniqueTypes = Map.fromEntries(
      type.types
          .where(_allowTypeInUnions)
          .map((t) => MapEntry(t.uniqueTypeIdentifier, t)),
    ).values.toList();

    // If our list includes something that maps to Object? as well as other
    // types, we should just treat the whole thing as Object? as we get no value
    // typing Either4<bool, String, num, Object?> but it becomes much more
    // difficult to use.
    if (uniqueTypes.any(isNullableAnyType)) {
      return uniqueTypes.firstWhere(isNullableAnyType);
    }

    // Finally, sort the types by name so that we always generate the same type
    // for the same combination to improve reuse of helper methods used in
    // multiple handlers.
    uniqueTypes.sort((t1, t2) => t1.dartType.compareTo(t2.dartType));

    // Recursively clean the inner types.
    uniqueTypes = uniqueTypes.map(_cleanType).toList();

    if (uniqueTypes.length == 1) {
      return uniqueTypes.single;
    } else if (uniqueTypes.every(isLiteralType)) {
      return LiteralUnionType(uniqueTypes.cast<LiteralType>());
    } else if (uniqueTypes.any(isNullType)) {
      var remainingTypes = uniqueTypes.whereNot(isNullType).toList();
      var nonNullType = remainingTypes.length == 1
          ? remainingTypes.single
          : UnionType(remainingTypes);
      return NullableType(nonNullType);
    } else {
      return UnionType(uniqueTypes);
    }
  }

  /// Improves types in code generated from the LSP model, including:
  ///
  /// - Making some untyped fields (like `CompletionItem.data`) strong typed for
  ///   our use.
  ///
  /// - Simplifying unions for types generated only by the server to avoid a lot
  ///   of wrapping in `EitherX<Y,Z>.tX()`.
  TypeBase? _getImprovedType(String interfaceName, String? fieldName) {
    const improvedTypeMappings = <String, Map<String, String>>{
      'Diagnostic': {
        'code': 'String',
      },
      'CompletionItem': {
        'data': 'CompletionItemResolutionInfo',
      },
      'ParameterInformation': {
        'label': 'String',
      },
      'TextDocumentEdit': {
        'edits': 'TextDocumentEditEdits',
      },
      'TypeHierarchyItem': {
        'data': 'TypeHierarchyItemInfo',
      },
    };

    var interface = improvedTypeMappings[interfaceName];

    var improvedTypeName = interface != null ? interface[fieldName] : null;

    return improvedTypeName != null
        ? improvedTypeName.endsWith('[]')
            ? ArrayType(TypeReference(
                improvedTypeName.substring(0, improvedTypeName.length - 2)))
            : improvedTypeName.endsWith('?')
                ? NullableType(TypeReference(
                    improvedTypeName.substring(0, improvedTypeName.length - 1)))
                : TypeReference(improvedTypeName)
        : null;
  }

  /// Some types are merged together. This method returns the type that [name]s
  /// members should be merged into.
  String? _getMergeTarget(String name) {
    switch (name) {
      // The meta model defines both `LSPErrorCodes` and `ErrorCodes`. The
      // intention was that one is JSONRPC and one is LSP codes, but some codes
      // were defined in the wrong enum with the wrong values, but kept for
      // backwards compatibility. For simplicity, we merge them all into `ErrorCodes`.
      case 'LSPErrorCodes':
        return 'ErrorCodes';
      // In the model, `InitializeParams` is defined as by two classes,
      // `_InitializeParams` and `WorkspaceFoldersInitializeParams`. This
      // split doesn't add anything but makes the types less clear so we
      // merge them into `InitializeParams`.
      case '_InitializeParams':
        return 'InitializeParams';
      case 'WorkspaceFoldersInitializeParams':
        return 'InitializeParams';
      default:
        return null;
    }
  }

  /// Returns whether an entity should be included in the generated code.
  bool _includeEntityInOutput(LspEntity entity) {
    if (!includeProposed && entity.isProposed) {
      return false;
    }

    if (entity is Interface || entity is LspEnum || entity is TypeAlias) {
      if (!_includeTypeInOutput(entity.name)) {
        return false;
      }
    }

    return true;
  }

  /// Returns whether the type with [name] should be included in generated code.
  ///
  /// For [LspEntity]s, [_includeEntityInOutput] should be used instead which
  /// includes this check and others.
  bool _includeTypeInOutput(String name) {
    const ignoredTypes = {
      // InitializeError is not used for v3.0 (Feb 2017) and by dropping it we
      // don't have to handle any cases where both a namespace and interfaces
      // are declared with the same name.
      'InitializeError',
      // Merged into InitializeParams.
      '_InitializeParams',
      'WorkspaceFoldersInitializeParams',
      // We don't use these classes and they weren't in the TS version of the
      // spec so continue to not generate them until required.
      'DidChangeConfigurationRegistrationOptions',
      // LSPAny/LSPObject are used by the LSP spec for unions of basic types.
      // We map these onto Object? and don't use this type (and don't support
      // unions with so many types).
      'LSPAny',
      'LSPObject',
      'LSPUri',
      // The meta model currently includes an unwanted type named 'T' that we
      // don't want to create a class for.
      // TODO(dantup): Remove this once it's gone from the JSON model.
      'T',
    };
    const ignoredPrefixes = {
      // We don't emit MarkedString because it gets mapped to a simple String
      // when getting the .dartType for it.
      'MarkedString'
    };
    var shouldIgnore = ignoredTypes.contains(name) ||
        ignoredPrefixes.any((ignore) => name.startsWith(ignore));
    return !shouldIgnore;
  }

  LspEntity _merge(LspEntity source, LspEntity dest) {
    if (source.runtimeType != dest.runtimeType) {
      throw 'Cannot merge ${source.runtimeType} into ${dest.runtimeType}';
    }
    var comment = dest.comment ?? source.comment;
    if (source is LspEnum && dest is LspEnum) {
      return LspEnum(
        name: dest.name,
        comment: comment,
        isProposed: dest.isProposed,
        typeOfValues: dest.typeOfValues,
        members: [...dest.members, ...source.members],
      );
    } else if (source is Interface && dest is Interface) {
      return Interface(
        name: dest.name,
        comment: comment,
        isProposed: dest.isProposed,
        baseTypes: [...dest.baseTypes, ...source.baseTypes],
        members: [...dest.members, ...source.members],
      );
    }
    throw 'Merging ${source.runtimeType}s is not yet supported';
  }

  List<LspEntity> _mergeTypes(List<LspEntity> types) {
    var typesByName = {
      for (final type in types) type.name: type,
    };
    assert(types.length == typesByName.length);
    var typeNames = typesByName.keys.toList();
    for (var typeName in typeNames) {
      var targetName = _getMergeTarget(typeName);
      if (targetName != null) {
        var type = typesByName[typeName]!;
        var target = typesByName[targetName]!;
        typesByName[targetName] = _merge(type, target);
        typesByName.remove(typeName);
      }
    }
    return typesByName.values.toList();
  }

  /// Renames types that may have been generated with bad (or long) names.
  Iterable<LspEntity> _renameTypes(List<LspEntity> types) sync* {
    const renames = <String, String>{
      'CompletionClientCapabilitiesCompletionItemInsertTextModeSupport':
          'CompletionItemInsertTextModeSupport',
      'CompletionClientCapabilitiesCompletionItemTagSupport':
          'CompletionItemTagSupport',
      'CompletionClientCapabilitiesCompletionItemResolveSupport':
          'CompletionItemResolveSupport',
      'SignatureHelpClientCapabilitiesSignatureInformationParameterInformation':
          'SignatureInformationParameterInformation',
      'Pattern': 'LspPattern',
      'URI': 'LSPUri',

      // In LSP 3.18, many types that were previously inline and got generated
      // names have been extracted to their own definitions with hand-written
      // names.
      // To reduce the size of the upcoming diff when this happens, these
      // renames change our 3.17 generated names to those that will be used
      // for 3.18.
      // TODO(dantup): Remove these once LSP 3.18 release and we regenerate
      // using it.
      'TextDocumentFilter2': 'TextDocumentFilterScheme',
      'PrepareRenameResult1': 'PrepareRenamePlaceholder',
      'TextDocumentContentChangeEvent1': 'TextDocumentContentChangePartial',
      'TextDocumentContentChangeEvent2':
          'TextDocumentContentChangeWholeDocument',
      'CompletionListItemDefaults': 'CompletionItemDefaults',
      'InitializeParamsClientInfo': 'ClientInfo',
      'SemanticTokensClientCapabilitiesRequests':
          'ClientSemanticTokensRequestOptions',
      'TraceValues': 'TraceValue',
      'SemanticTokensOptionsFull': 'SemanticTokensFullDelta',
      'CompletionListItemDefaultsEditRange': 'EditRangeWithInsertReplace',
      'ServerCapabilitiesWorkspace': 'WorkspaceOptions',
      'CodeActionClientCapabilitiesCodeActionLiteralSupportCodeActionKind':
          'ClientCodeActionKindOptions',
      'CompletionClientCapabilitiesCompletionItemKind':
          'ClientCompletionItemOptionsKind',
      'CompletionOptionsCompletionItem': 'ServerCompletionItemOptions',
      'InitializeResultServerInfo': 'ServerInfo',
      // End of temporary renames
    };

    // Temporary aliases for old names used in g3
    // TODO(dantup): Remove these once the internal code has been updated.
    var typeNames = types.map((type) => type.name).toSet();
    if (typeNames.contains('TextDocumentContentChangeEvent2')) {
      yield TypeAlias(
        name: 'TextDocumentContentChangeEvent2',
        baseType: TypeReference('TextDocumentContentChangeWholeDocument'),
        renameReferences: true,
        generateTypeDef: true,
      );
    }
    if (typeNames.contains(
        'CodeActionClientCapabilitiesCodeActionLiteralSupportCodeActionKind')) {
      yield TypeAlias(
        name: 'CodeActionLiteralSupportCodeActionKind',
        baseType: TypeReference('ClientCodeActionKindOptions'),
        renameReferences: true,
        generateTypeDef: true,
      );
    }
    // End temporary aliases

    for (var type in types) {
      var newName = renames[type.name];
      if (newName == null) {
        yield type;
        continue;
      }

      // Add a TypeAlias for the old name.
      yield TypeAlias(
        name: type.name,
        comment: type.comment,
        isProposed: type.isProposed,
        baseType: TypeReference(newName),
        renameReferences: true,
      );

      // Replace the type with an equivalent with the same name.
      if (type is Interface) {
        yield Interface(
          name: newName,
          comment: type.comment,
          isProposed: type.isProposed,
          baseTypes: type.baseTypes,
          members: type.members,
        );
      } else if (type is TypeAlias) {
        yield TypeAlias(
          name: newName,
          comment: type.comment,
          isProposed: type.isProposed,
          baseType: type.baseType,
          renameReferences: type.renameReferences,
        );
      } else if (type is LspEnum) {
        yield LspEnum(
          name: newName,
          comment: type.comment,
          isProposed: type.isProposed,
          typeOfValues: type.typeOfValues,
          members: type.members,
        );
      } else {
        throw 'Renaming ${type.runtimeType} is not implemented';
      }
    }
  }
}
