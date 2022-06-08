// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
      RegExp(r'[\w`\]\).]\n[\w`\[\(]');
  final _sourceCommentDocumentLinksPattern =
      RegExp(r'\[([`\w \-.]+)\] ?\((#[^)]+)\)');

  /// Cleans an entire [LspMetaModel].
  LspMetaModel cleanModel(LspMetaModel model) {
    final types = cleanTypes(model.types);
    return LspMetaModel(types);
  }

  /// Cleans a List of types.
  List<LspEntity> cleanTypes(List<LspEntity> types) {
    types = _mergeTypes(types);
    types = types
        .where((type) => _includeTypeInOutput(type.name))
        .map(_clean)
        .toList();
    types = _renameTypes(types).toList();
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
      final elementType = type.elementType;
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

    // Strip any relative links that are intended for displaying online in the
    // HTML spec.
    text = text.replaceAllMapped(
      _sourceCommentDocumentLinksPattern,
      (match) => match.group(1)!,
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
    final improvedType = _getImprovedType(parentName, field.name);
    final type = improvedType ?? field.type;

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
      typeArgs: interface.typeArgs,
      baseTypes: interface.baseTypes
          .where((type) => _includeTypeInOutput(type.name))
          .toList(),
      members: interface.members
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
      typeOfValues: namespace.typeOfValues,
      members: namespace.members
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
      baseType: typeAlias.baseType,
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
    if (uniqueTypes.any(isAnyType)) {
      return uniqueTypes.firstWhere(isAnyType);
    }

    // Finally, sort the types by name so that we always generate the same type
    // for the same combination to improve reuse of helper methods used in
    // multiple handlers.
    uniqueTypes.sort((t1, t2) => t1.dartType.compareTo(t2.dartType));

    // Recursively clean the inner types.
    uniqueTypes = uniqueTypes.map(_cleanType).toList();

    return uniqueTypes.length == 1
        ? uniqueTypes.single
        : uniqueTypes.every(isLiteralType)
            ? LiteralUnionType(uniqueTypes.cast<LiteralType>())
            : UnionType(uniqueTypes);
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
      }
    };

    final interface = improvedTypeMappings[interfaceName];

    final improvedTypeName = interface != null ? interface[fieldName] : null;

    return improvedTypeName != null
        ? improvedTypeName.endsWith('[]')
            ? ArrayType(TypeReference(
                improvedTypeName.substring(0, improvedTypeName.length - 2)))
            : improvedTypeName.endsWith('?')
                ? UnionType.nullable(TypeReference(
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

  /// Removes types that are in the spec that we don't want to emit.
  bool _includeTypeInOutput(String name) {
    const ignoredTypes = {
      // InitializeError is not used for v3.0 (Feb 2017) and by dropping it we
      // don't have to handle any cases where both a namespace and interfaces
      // are declared with the same name.
      'InitializeError',
      // Merged into InitializeParams.
      '_InitializeParams',
      'WorkspaceFoldersInitializeParams',
      // We don't use these clases and they weren't in the TS version of the
      // spec so continue to not generate them until required.
      'DidChangeConfigurationRegistrationOptions',
      // LSPAny/LSPObject are used by the LSP spec for unions of basic types.
      // We map these onto Object? and don't use this type (and don't support
      // unions with so many types).
      'LSPAny',
      'LSPObject',
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
    final shouldIgnore = ignoredTypes.contains(name) ||
        ignoredPrefixes.any((ignore) => name.startsWith(ignore));
    return !shouldIgnore;
  }

  LspEntity _merge(LspEntity source, LspEntity dest) {
    if (source.runtimeType != dest.runtimeType) {
      throw 'Cannot merge ${source.runtimeType} into ${dest.runtimeType}';
    }
    if (source is LspEnum && dest is LspEnum) {
      return LspEnum(
        name: dest.name,
        comment: dest.comment ?? source.comment,
        typeOfValues: dest.typeOfValues,
        members: [...dest.members, ...source.members],
      );
    } else if (source is Interface && dest is Interface) {
      return Interface(
        name: dest.name,
        comment: dest.comment ?? source.comment,
        typeArgs: dest.typeArgs,
        baseTypes: [...dest.baseTypes, ...source.baseTypes],
        members: [...dest.members, ...source.members],
      );
    }
    throw 'Merging ${source.runtimeType}s is not yet supported';
  }

  List<LspEntity> _mergeTypes(List<LspEntity> types) {
    final typesByName = {
      for (final type in types) type.name: type,
    };
    assert(types.length == typesByName.length);
    final typeNames = typesByName.keys.toList();
    for (final typeName in typeNames) {
      final targetName = _getMergeTarget(typeName);
      if (targetName != null) {
        final type = typesByName[typeName]!;
        final target = typesByName[targetName]!;
        typesByName[targetName] = _merge(type, target);
        typesByName.remove(typeName);
      }
    }
    return typesByName.values.toList();
  }

  /// Renames types that may have been generated with bad (or long) names.
  Iterable<LspEntity> _renameTypes(List<LspEntity> types) sync* {
    const renames = <String, String>{
      'CodeActionClientCapabilitiesCodeActionLiteralSupportCodeActionKind':
          'CodeActionLiteralSupportCodeActionKind',
      'CompletionClientCapabilitiesCompletionItemInsertTextModeSupport':
          'CompletionItemInsertTextModeSupport',
      'CompletionClientCapabilitiesCompletionItemTagSupport':
          'CompletionItemTagSupport',
      'CompletionClientCapabilitiesCompletionItemResolveSupport':
          'CompletionItemResolveSupport',
      'CompletionListItemDefaultsEditRange': 'CompletionItemEditRange',
      'SignatureHelpClientCapabilitiesSignatureInformationParameterInformation':
          'SignatureInformationParameterInformation',
      'TextDocumentFilter2': 'TextDocumentFilterWithScheme',
      'PrepareRenameResult1': 'PlaceholderAndRange',
    };

    for (final type in types) {
      if (type is Interface) {
        final newName = renames[type.name];
        if (newName != null) {
          // Replace with renamed interface.
          yield Interface(
            name: newName,
            comment: type.comment,
            typeArgs: type.typeArgs,
            baseTypes: type.baseTypes,
            members: type.members,
          );
          // Plus a TypeAlias for the old name.
          yield TypeAlias(
            name: type.name,
            comment: type.comment,
            baseType: TypeReference(newName),
          );
          continue;
        }
      }
      yield type;
    }
  }
}
