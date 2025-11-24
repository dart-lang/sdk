// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'util/path_utils.dart';

const _categoryNames = {
  'binarySize',
  'brevity',
  'documentationCommentMaintenance',
  'effectiveDart',
  'errorProne',
  'flutter',
  'languageFeatureUsage',
  'memoryLeaks',
  'nonPerformant',
  'pub',
  'publicInterface',
  'style',
  'unintentional',
  'unusedCode',
  'web',
};

const String _messagesFileName = 'pkg/linter/messages.yaml';

const _stateNames = {
  'experimental',
  'stable',
  'internal',
  'deprecated',
  'removed',
};

final Map<String, RuleInfo> messagesRuleInfo = () {
  var messagesYaml = loadYamlNode(File(_messagesYamlPath).readAsStringSync());
  if (messagesYaml is! YamlMap) {
    throw StateError("The '$_messagesFileName' file is not a YAML map.");
  }
  var lintCodes = messagesYaml['LinterLintCode'] as YamlMap?;
  if (lintCodes == null) {
    throw StateError(
      "The '$_messagesFileName' file does not have a 'LinterLintCode' section.",
    );
  }

  {
    var lintCodeKeys = lintCodes.keys.cast<String>().toList(growable: false);
    var lintCodeKeysSorted = lintCodeKeys.sorted();
    for (var i = 0; i < lintCodeKeys.length; i++) {
      if (lintCodeKeys[i] != lintCodeKeysSorted[i]) {
        throw StateError(
          "The LintCode entries in '$_messagesFileName' "
          "are not sorted alphabetically, starting at '${lintCodeKeys[i]}'.",
        );
      }
    }
  }

  var builders = <String, _RuleBuilder>{};
  for (var MapEntry(key: String uniqueName, value: YamlMap data)
      in lintCodes.entries) {
    String sharedName;
    if (data.containsKey('sharedName')) {
      sharedName = data['sharedName'] as String;
    } else {
      sharedName = uniqueName;
    }
    var rule = builders.putIfAbsent(sharedName, () => _RuleBuilder(sharedName));
    rule.addEntry(uniqueName, data);
  }

  return builders.map((key, value) {
    try {
      return MapEntry(key, value.build());
    } catch (e, st) {
      Error.throwWithStackTrace('Problem with lint code $key: $e', st);
    }
  });
}();

final String _messagesYamlPath = pathRelativeToPackageRoot(['messages.yaml']);

class CodeInfo {
  final String uniqueName;
  final String problemMessage;
  final String? correctionMessage;

  CodeInfo(
    this.uniqueName, {
    required this.problemMessage,
    this.correctionMessage,
  });
}

class RuleInfo {
  final String name;
  final List<CodeInfo> codes;
  final List<RuleState> states;
  final Set<String> categories;
  final bool hasPublishedDocs;
  final String? documentation;
  final String deprecatedDetails;
  final bool removed;

  RuleInfo({
    required this.name,
    required this.codes,
    required this.categories,
    required this.hasPublishedDocs,
    required this.documentation,
    required this.deprecatedDetails,
    required this.states,
    required this.removed,
  });
}

// TODO(parlough): Clean up and simplify this validation
// once the `messages.yaml` format is more stabilized.
class _RuleBuilder {
  final String sharedName;
  final List<
    ({String uniqueName, String? problemMessage, String? correctionMessage})
  >
  _codes = [];
  List<({String name, Version version})>? _stateEntries;
  Set<String>? _categories;
  bool? _hasPublishedDocs;
  String? _documentation;
  String? _deprecatedDetails;

  _RuleBuilder(this.sharedName);

  bool get _wasRemoved =>
      _stateEntries?.any((state) => state.name == 'removed') ?? false;

  void addEntry(String uniqueName, YamlMap data) {
    _addCode(uniqueName, data);

    _setStates(data);
    _setCategories(data);
    _setDeprecatedDetails(data);
    _setDocumentation(data);
    _setHasPublishedDocs(data);
  }

  RuleInfo build() => RuleInfo(
    name: sharedName,
    codes: _validateCodes(),
    states: _validateStates(),
    categories: _requireSpecified(
      'categories',
      _categories,
      ifNotRemovedFallback: const {},
    ),
    hasPublishedDocs: _hasPublishedDocs ?? false,
    documentation: _documentation,
    deprecatedDetails: _requireSpecified(
      'deprecatedDetails',
      _deprecatedDetails,
    ),
    removed: _wasRemoved,
  );

  void _addCode(String name, Map<Object?, Object?> data) {
    if (_codes.map((code) => code.uniqueName).any((n) => n == name)) {
      _throwLintError(
        "Has more than one LintCode with '$name' as its 'uniqueName'.",
      );
    }

    String? problemMessage;
    if (data.containsKey('problemMessage')) {
      problemMessage = _requireType('problemMessage', data['problemMessage']);
    }

    String? correctionMessage;
    if (data.containsKey('correctionMessage')) {
      correctionMessage = _requireType(
        'correctionMessage',
        data['correctionMessage'],
      );
    }

    _codes.add((
      uniqueName: name,
      problemMessage: problemMessage,
      correctionMessage: correctionMessage,
    ));
  }

  Never _alreadySpecified(String propertyName) {
    _throwLintError(
      "More than one LintCode specified the '$propertyName' property.",
    );
  }

  void _requireNotEmpty(String propertyName, String value) {
    if (value.trim().isEmpty) {
      _throwLintError("The '$propertyName' value must not be empty.");
    }
  }

  T _requireSpecified<T extends Object>(
    String propertyName,
    T? value, {
    T? ifNotRemovedFallback,
  }) {
    if (value == null) {
      if (_wasRemoved && ifNotRemovedFallback != null) {
        return ifNotRemovedFallback;
      }
      _throwLintError("The '$propertyName' property must be specified.");
    }

    return value;
  }

  T _requireType<T extends Object?>(String propertyName, Object? value) {
    if (value is! T) {
      _throwLintError("The '$propertyName' property must be of type '$T'.");
    }

    return value;
  }

  Iterable<T> _requireTypeForItems<T extends Object?>(
    String propertyName,
    Iterable<Object?> items,
  ) {
    for (var item in items) {
      if (item is! T) {
        _throwLintError(
          "The items in the '$propertyName' collection must "
          "each be of type '$T'.",
        );
      }
    }

    return items.cast<T>();
  }

  void _setCategories(Map<Object?, Object?> data) {
    const propertyName = 'categories';
    if (!data.containsKey(propertyName)) return;

    var value = data[propertyName];
    if (_categories != null) _alreadySpecified(propertyName);

    var categoryValues = _requireType<Iterable<Object?>>(propertyName, value);
    var categoryStrings = _requireTypeForItems<String>(
      propertyName,
      categoryValues,
    );

    var countWithDuplicates = categoryStrings.length;
    var categoriesSet = categoryStrings.toSet();
    if (countWithDuplicates != categoriesSet.length) {
      _throwLintError("The '$propertyName' property must not have duplicates.");
    }

    for (var category in categoriesSet) {
      if (!_categoryNames.contains(category)) {
        _throwLintError("The specified '$category' category is invalid.");
      }
    }

    _categories = categoriesSet;
  }

  void _setDeprecatedDetails(Map<Object?, Object?> data) {
    const propertyName = 'deprecatedDetails';
    if (!data.containsKey(propertyName)) return;

    var value = data[propertyName];
    if (_deprecatedDetails != null) _alreadySpecified(propertyName);

    var deprecatedDetails = _requireType<String>(propertyName, value);
    _requireNotEmpty(propertyName, deprecatedDetails);
    _deprecatedDetails = deprecatedDetails;
  }

  void _setDocumentation(Map<Object?, Object?> data) {
    const propertyName = 'documentation';
    if (!data.containsKey(propertyName)) return;

    var value = data[propertyName];
    if (_documentation != null) _alreadySpecified(propertyName);

    var documentationValue = _requireType<String>(propertyName, value);
    _requireNotEmpty(propertyName, documentationValue);
    _documentation = documentationValue;
  }

  void _setHasPublishedDocs(Map<Object?, Object?> data) {
    const propertyName = 'hasPublishedDocs';
    if (!data.containsKey(propertyName)) return;

    var value = data[propertyName];
    var hasPublishedValue = _requireType<bool>(propertyName, value);
    _hasPublishedDocs = hasPublishedValue || (_hasPublishedDocs ?? false);
  }

  void _setStates(Map<Object?, Object?> data) {
    const propertyName = 'state';
    if (!data.containsKey(propertyName)) return;

    var value = data[propertyName];
    if (_stateEntries != null) _alreadySpecified(propertyName);

    var stateValue = _requireType<Map<Object?, Object?>>(propertyName, value);

    _stateEntries = stateValue.entries.map((state) {
      var stateName = state.key;
      var version = state.value;
      if (stateName is! String || version is! String) {
        _throwLintError('Each state key and value must be a string.');
      }

      if (!_stateNames.contains(stateName)) {
        _throwLintError('$stateName is not a valid state name.');
      }

      try {
        var parsedVersion = Version.parse('$version.0');
        return (name: stateName, version: parsedVersion);
      } on Exception {
        _throwLintError(
          'The state versions must be in '
          "'major.minor' format, but found '$version'.",
        );
      }
    }).toList();
  }

  Never _throwLintError(String message) {
    throw StateError('$sharedName - $message');
  }

  List<CodeInfo> _validateCodes() {
    if (_wasRemoved) return const [];

    if (_codes.isEmpty) {
      throw StateError('Tried to call build a RuleInfo without a code added!');
    }

    var codeInfos = <CodeInfo>[];
    for (var code in _codes) {
      var problemMessage = code.problemMessage;
      if (problemMessage == null) {
        _throwLintError(
          "'LintCode.${code.uniqueName}' is missing a 'problemMessage'.",
        );
      }

      // TODO(parlough): Eventually require that codes have a correction message.
      // var correctionMessage = code.correctionMessage;
      // if (code.correctionMessage == null) {
      //   _throwLintError("'LintCode.${code.uniqueName}' is missing a 'correctionMessage'.");
      // }

      codeInfos.add(
        CodeInfo(
          code.uniqueName,
          problemMessage: problemMessage,
          correctionMessage: code.correctionMessage,
        ),
      );
    }

    return codeInfos;
  }

  List<RuleState> _validateStates() {
    var states = _stateEntries;
    if (states == null || states.isEmpty) {
      throw StateError('Tried to build a RuleInfo without a state added!');
    }

    var sortedStates = states
        .map(
          (state) => switch (state.name) {
            'experimental' => RuleState.experimental(since: state.version),
            'stable' => RuleState.stable(since: state.version),
            'internal' => RuleState.internal(since: state.version),
            'deprecated' => RuleState.deprecated(since: state.version),
            // Note: the reason `RuleState.removed` is deprecated is to
            // encourage clients to use `AbstractAnalysisRule`, so this
            // reference is ok.
            // ignore: deprecated_member_use
            'removed' => RuleState.removed(since: state.version),
            _ => _throwLintError('Unexpected state name: ${state.name}.'),
          },
        )
        .sortedBy<VersionRange>((state) => state.since ?? Version.none);

    return sortedStates;
  }
}
