// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer_utilities/lint_messages.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

const String _messagesFileName = 'pkg/linter/messages.yaml';

final Map<String, RuleInfo> messagesRuleInfo = () {
  {
    var lintNames = lintMessages
        .map((m) => m.analyzerCode.snakeCaseName)
        .toList(growable: false);
    var lintCodeKeysSorted = lintNames.sorted();
    for (var i = 0; i < lintNames.length; i++) {
      if (lintNames[i] != lintCodeKeysSorted[i]) {
        throw StateError(
          "The LintCode entries in '$_messagesFileName' "
          "are not sorted alphabetically, starting at '${lintNames[i]}'.",
        );
      }
    }
  }

  var builders = <String, _RuleBuilder>{};
  for (var message in lintMessages) {
    var sharedNameString =
        (message.sharedName ?? message.analyzerCode).snakeCaseName;
    var rule = builders.putIfAbsent(
      sharedNameString,
      () => _RuleBuilder(sharedNameString),
    );
    rule.addEntry(message.analyzerCode.snakeCaseName, message);
  }

  return builders.map((key, value) {
    try {
      return MapEntry(key, value.build());
    } catch (e, st) {
      Error.throwWithStackTrace('Problem with lint code $key: $e', st);
    }
  });
}();

class CodeInfo {
  final String uniqueName;
  final List<TemplatePart> problemMessage;
  final List<TemplatePart>? correctionMessage;

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
  final Set<LintCategory> categories;
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
    ({
      String uniqueName,
      List<TemplatePart> problemMessage,
      List<TemplatePart>? correctionMessage,
    })
  >
  _codes = [];
  Map<LintStateName, Version>? _states;
  Set<LintCategory>? _categories;
  bool? _hasPublishedDocs;
  String? _documentation;
  String? _deprecatedDetails;

  _RuleBuilder(this.sharedName);

  bool get _wasRemoved =>
      _states?.keys.any((key) => key == LintStateName.removed) ?? false;

  void addEntry(String uniqueName, LintMessage message) {
    _addCode(uniqueName, message);

    _setStates(message);
    _setCategories(message);
    _setDeprecatedDetails(message);
    _setDocumentation(message);
    _setHasPublishedDocs(message);
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

  void _addCode(String name, LintMessage message) {
    if (_codes.map((code) => code.uniqueName).any((n) => n == name)) {
      _throwLintError(
        "Has more than one LintCode with '$name' as its 'uniqueName'.",
      );
    }

    _codes.add((
      uniqueName: name,
      problemMessage: message.problemMessage,
      correctionMessage: message.correctionMessage,
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

  void _setCategories(LintMessage message) {
    const propertyName = 'categories';
    var value = message.categories;
    if (value == null) return;

    if (_categories != null) _alreadySpecified(propertyName);
    _categories = value;
  }

  void _setDeprecatedDetails(LintMessage message) {
    const propertyName = 'deprecatedDetails';
    var value = message.deprecatedDetails;
    if (value == null) return;

    if (_deprecatedDetails != null) _alreadySpecified(propertyName);

    _requireNotEmpty(propertyName, value);
    _deprecatedDetails = value;
  }

  void _setDocumentation(LintMessage message) {
    const propertyName = 'documentation';
    var value = message.documentation;
    if (value == null) return;

    if (_documentation != null) _alreadySpecified(propertyName);

    _requireNotEmpty(propertyName, value);
    _documentation = value;
  }

  void _setHasPublishedDocs(LintMessage message) {
    var value = message.hasPublishedDocs;

    _hasPublishedDocs = value || (_hasPublishedDocs ?? false);
  }

  void _setStates(LintMessage message) {
    const propertyName = 'state';
    var value = message.state;
    if (value == null) return;

    if (_states != null) _alreadySpecified(propertyName);

    _states = value;
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
      if (problemMessage.isEmpty) {
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
    var states = _states;
    if (states == null || states.isEmpty) {
      throw StateError('Tried to build a RuleInfo without a state added!');
    }

    var sortedStates = states.entries
        .map(
          (entry) => switch (entry.key) {
            LintStateName.experimental => RuleState.experimental(
              since: entry.value,
            ),
            LintStateName.stable => RuleState.stable(since: entry.value),
            LintStateName.internal => RuleState.internal(since: entry.value),
            LintStateName.deprecated => RuleState.deprecated(
              since: entry.value,
            ),
            // Note: the reason `RuleState.removed` is deprecated is to
            // encourage clients to use `AbstractAnalysisRule`, so this
            // reference is ok.
            // ignore: deprecated_member_use
            LintStateName.removed => RuleState.removed(since: entry.value),
          },
        )
        .sortedBy<VersionRange>((state) => state.since ?? Version.none);

    return sortedStates;
  }
}
