// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/utilities/strings.dart';
import 'package:collection/collection.dart';

import 'meta_model.dart';

/// Reads the LSP 'meta_model.json' file and returns its types.
class LspMetaModelReader {
  final _types = <LspEntity>[];

  /// A set of names already used (or reserved) by types that have been read.
  final Set<String> _typeNames = {};

  /// Characters to strip from member names.
  final _memberNameInvalidCharPattern = RegExp(r'\$_?');

  /// Patterns to replace with '_' in member names.
  final _memberNameSeparatorPattern = RegExp(r'/');

  /// Gets all types that have been read from the model JSON.
  List<LspEntity> get types => _types.toList();

  /// Reads all spec types from [file].
  LspMetaModel readFile(File file) {
    final modelJson = file.readAsStringSync();
    final model = jsonDecode(modelJson) as Map<String, Object?>;
    return readMap(model);
  }

  /// Reads all spec types from [model].
  LspMetaModel readMap(Map<String, dynamic> model) {
    final requests = model['requests'] as List?;
    final notifications = model['notifications'] as List?;
    final structures = model['structures'] as List?;
    final enums = model['enumerations'] as List?;
    final typeAliases = model['typeAliases'] as List?;
    final methods = [...?requests, ...?notifications].toList();
    [
      ...?structures?.map(_readStructure),
      ...?enums?.map((e) => _readEnum(e)),
      ...?typeAliases?.map(_readTypeAlias),
    ].forEach(_addType);

    // Requests and notifications may have inline union types as their
    // params/result. We can create TypeAliases for those using sensible
    // names to simplify their use in the handlers.
    requests?.forEach(_readRequest);
    notifications?.forEach(_readNotification);

    final methodsEnum = _createMethodsEnum(methods);
    if (methodsEnum != null) {
      _addType(methodsEnum);
    }

    return LspMetaModel(
      types: types,
      methods: methodsEnum?.members.cast<Constant>().toList() ?? [],
    );
  }

  /// Adds [type] to the current list and prevents its name from being used
  /// by generated interfaces.
  void _addType(LspEntity type) {
    _typeNames.add(type.name);
    _types.add(type);
  }

  String _camelCase(String str) =>
      str.substring(0, 1).toLowerCase() + str.substring(1);

  /// Creates an enum for all LSP method names.
  LspEnum? _createMethodsEnum(List<Object?> methods) {
    Constant toConstant(Map<String, Object?> item) {
      final name = item['method'] as String;
      // We use documentation from the request/notification for things like
      // proposed check, but we don't put the full request/notification docs
      // on the method enum member.
      final documentation = item['documentation'] as String?;
      final comment = '''Constant for the '$name' method.''';
      return Constant(
        name: _generateMemberName(name, camelCase: true),
        comment: comment,
        isProposed: _isProposed(documentation),
        type: TypeReference.string,
        value: name,
      );
    }

    final methodConstants =
        methods.cast<Map<String, Object?>>().map(toConstant).toList();

    if (methodConstants.isEmpty) {
      return null;
    }

    final comment = 'All standard LSP Methods read from the JSON spec.';
    return LspEnum(
      name: 'Method',
      comment: comment,
      typeOfValues: TypeReference.string,
      members: methodConstants,
    );
  }

  /// Creates a type alias for a top-level union, such as those used for
  /// request parameters/results that don't have named types in the spec.
  void _createUnionAlias(String name, dynamic model, String? documentation) {
    if (model == null) {
      return;
    }

    // We don't currently support reading the two top-level intersection types.
    // These can just be skipped because the types we're generating here are
    // just for convenience (to produce better names for use in handlers rather
    // than referencing `EitherX<Y>` everywhere).
    if (model['kind'] == 'and') {
      return;
    }

    final type = _extractType(name, '', model);
    if (type is UnionType) {
      _addType(TypeAlias(
        name: name,
        comment: documentation,
        isProposed: _isProposed(documentation),
        baseType: type,
        isRename: false,
      ));
    }
  }

  Constant _extractEnumValue(TypeBase parentType, dynamic model) {
    final name = model['name'] as String;
    final documentation = model['documentation'] as String?;
    return Constant(
      name: _generateMemberName(name),
      comment: documentation,
      isProposed: _isProposed(documentation),
      type: parentType,
      value: model['value'].toString(),
    );
  }

  Member _extractMember(String parentName, dynamic model) {
    final name = model['name'] as String;
    final documentation = model['documentation'] as String?;
    var type = _extractType(parentName, name, model['type']);

    // Unions may contain `null` types which we promote up to the field.
    var allowsNull = false;
    if (type is UnionType) {
      final types = type.types;

      // Extract and strip `null`s from the union.
      if (types.any(isNullType)) {
        allowsNull = true;
        type = UnionType(types.whereNot(isNullType).toList());
      }
    }

    return Field(
      name: _generateMemberName(name),
      comment: documentation,
      isProposed: _isProposed(documentation),
      type: type,
      allowsNull: allowsNull,
      allowsUndefined: model['optional'] == true,
    );
  }

  /// Reads the type of [model].
  TypeBase _extractType(String parentName, String? fieldName, dynamic model) {
    if (model['kind'] == 'reference' || model['kind'] == 'base') {
      // Reference kinds are other named interfaces defined in the spec, base are
      // other named types defined elsewhere.
      return TypeReference(model['name'] as String);
    } else if (model['kind'] == 'array') {
      return ArrayType(
        _extractType(parentName, fieldName, model['element']!),
      );
    } else if (model['kind'] == 'map') {
      final name = fieldName ?? '';
      return MapType(
        _extractType(parentName, '${name}Key', model['key']!),
        _extractType(parentName, '${name}Value', model['value']!),
      );
    } else if (model['kind'] == 'literal') {
      // "Literal" here means an inline/anonymous type.
      final inlineTypeName = _generateTypeName(
        parentName,
        fieldName ?? '',
      );

      // First record the definition of the anonymous type itself.
      final members = (model['value']['properties'] as List)
          .map((p) => _extractMember(inlineTypeName, p))
          .toList();
      _addType(Interface.inline(inlineTypeName, members));

      // Then return its name.
      return TypeReference(inlineTypeName);
    } else if (model['kind'] == 'stringLiteral') {
      return LiteralType(
        TypeReference.string,
        model['value'] as String,
      );
    } else if (model['kind'] == 'or') {
      // Ensure the parent name is reserved so we don't try to reuse its name
      // if we're parsing something without a field name.
      _typeNames.add(parentName);

      final itemTypes = model['items'] as List;
      final types = itemTypes.map((item) {
        final generatedName = _generateAvailableTypeName(parentName, fieldName);
        return _extractType(generatedName, null, item);
      }).toList();

      return UnionType(types);
    } else if (model['kind'] == 'tuple') {
      // We currently just map tuples to an array of any of the types. The
      // LSP 3.17 spec only has one tuple which is `[number, number]`.
      final itemTypes = model['items'] as List;
      final types = itemTypes.mapIndexed((index, item) {
        final suffix = index + 1;
        final name = fieldName ?? '';
        final thisName = '$name$suffix';
        return _extractType(parentName, thisName, item);
      }).toList();
      return ArrayType(UnionType(types));
    } else {
      throw 'Unable to extract type from $model';
    }
  }

  /// Generates an available name for a node.
  ///
  /// If the computed name is already used, a number will be appended to the
  /// end.
  String _generateAvailableTypeName(String containerName, String? fieldName) {
    final name = _generateTypeName(containerName, fieldName ?? '');
    final requiresSuffix = fieldName == null;
    // If the name has already been taken, try appending a number and try
    // again.
    String generatedName;
    var suffixIndex = 1;
    do {
      if (suffixIndex > 20) {
        throw 'Failed to generate an available name for $name';
      }
      generatedName =
          requiresSuffix || suffixIndex > 1 ? '$name$suffixIndex' : name;
      suffixIndex++;
    } while (_typeNames.contains(generatedName));
    return generatedName;
  }

  /// Generates a valid name for a member.
  String _generateMemberName(String name, {bool camelCase = false}) {
    // Replace any separators like `/` with `_`.
    name = name.replaceAll(_memberNameSeparatorPattern, '_');

    // Replace out any characters we don't want in member names.
    name = name.replaceAll(_memberNameInvalidCharPattern, '');

    // TODO(dantup): Remove this condition and always do camelCase in a future
    //   CL to reduce the migration diff.
    if (camelCase) {
      name = _camelCase(name);
    }
    return name;
  }

  /// Generates a valid name for a type.
  String _generateTypeName(String parent, String child) {
    // Some classes are private (`_InitializeParams`) but still exposed via
    // other classes (`InitializeParams`) but the child types still need to be
    // exposed, so remove any leading underscores.
    if (parent.startsWith('_')) {
      parent = parent.substring(1);
    }
    return '${capitalize(parent)}${capitalize(child)}';
  }

  bool _isProposed(String? documentation) {
    return documentation?.contains('@proposed') ?? false;
  }

  LspEnum _readEnum(dynamic model) {
    final name = model['name'] as String;
    final type = TypeReference(name);
    final baseType = _extractType(name, null, model['type']);
    final documentation = model['documentation'] as String?;

    return LspEnum(
      name: name,
      comment: documentation,
      isProposed: _isProposed(documentation),
      typeOfValues: baseType,
      members: [
        ...?(model['values'] as List?)?.map((p) => _extractEnumValue(type, p)),
      ],
    );
  }

  void _readNotification(dynamic model) {
    final method = model['method'] as String;
    final namePrefix = method.split('/').map(capitalize).join();
    final documentation = model['documentation'] as String?;

    final paramsDoc = documentation != null
        ? 'Parameters for ${_camelCase(documentation)}'
        : null;

    _createUnionAlias('${namePrefix}Params', model['params'], paramsDoc);
  }

  void _readRequest(dynamic model) {
    final method = model['method'] as String;
    final namePrefix = method.split('/').map(capitalize).join();
    final documentation = model['documentation'] as String?;

    final paramsDoc = documentation != null
        ? 'Parameters for ${_camelCase(documentation)}'
        : null;

    final resultDoc = documentation != null
        ? 'Result for ${_camelCase(documentation)}'
        : null;

    _createUnionAlias('${namePrefix}Params', model['params'], paramsDoc);
    _createUnionAlias('${namePrefix}Result', model['result'], resultDoc);
  }

  LspEntity _readStructure(dynamic model) {
    final name = model['name'] as String;
    final documentation = model['documentation'] as String?;
    return Interface(
      name: name,
      comment: documentation,
      isProposed: _isProposed(documentation),
      baseTypes: [
        ...?(model['extends'] as List?)
            ?.map((e) => TypeReference(e['name'] as String)),
        ...?(model['mixins'] as List?)
            ?.map((e) => TypeReference(e['name'] as String)),
      ],
      members: [
        ...?(model['properties'] as List?)?.map((p) => _extractMember(name, p)),
      ],
    );
  }

  TypeAlias _readTypeAlias(dynamic model) {
    final name = model['name'] as String;
    final documentation = model['documentation'] as String?;
    return TypeAlias(
      name: name,
      comment: documentation,
      isProposed: _isProposed(documentation),
      baseType: _extractType(name, null, model['type']),
      isRename: false,
    );
  }
}
