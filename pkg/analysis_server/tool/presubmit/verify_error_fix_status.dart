// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/services/correction/fix/analysis_options/fix_generator.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_generator.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/package_root.dart' as package_root;
import 'package:analyzer_utilities/located_error.dart';
import 'package:linter/src/rules.dart';
import 'package:yaml/yaml.dart';

void main() {
  var errors = verifyErrorFixStatus();
  if (errors != null) {
    print(errors);
    exitCode = 1;
  }
}

PhysicalResourceProvider _resourceProvider = PhysicalResourceProvider.INSTANCE;

/// Returns the path to the file containing the status information.
String statusFilePath() {
  var pathContext = _resourceProvider.pathContext;
  var packageRoot = pathContext.normalize(package_root.packageRoot);
  return pathContext.join(
    packageRoot,
    'analysis_server',
    'lib',
    'src',
    'services',
    'correction',
    'error_fix_status.yaml',
  );
}

/// Verifies that the "error fix status" file is up-to-date and returns an error
/// string describing how the file is out-of-date, or `null` if the file is
/// up-to-date.
String? verifyErrorFixStatus() {
  YamlMap statusInfo;
  try {
    statusInfo = _statusInfo();
  } catch (e) {
    return e.toString();
  }
  registerLintRules();
  registerBuiltInFixGenerators();
  var lintRuleCodes = {
    for (var rule in Registry.ruleRegistry.rules) ...rule.diagnosticCodes,
  };
  var lintRuleNames = {
    for (var lintCode in lintRuleCodes) lintCode.uniqueName.suffix,
  };

  var errorData = ErrorData();
  for (var code in diagnosticCodeValues) {
    var name = code.uniqueName.suffix;
    if (code.type == .TODO) {
      // To-do codes are ignored.
      continue;
    }

    var info = statusInfo.nodes[name];
    if (info == null) {
      errorData.codesWithNoEntry.add(name);
    } else if (info is YamlMap) {
      var markedAsHavingFix = info['status'] == 'hasFix';
      if (code.hasFix) {
        if (!markedAsHavingFix) {
          errorData.codesWithFixes.add(name);
        }
      } else {
        if (markedAsHavingFix) {
          errorData.codesWithoutFixes.add(name);
        }
      }
    }
  }
  for (var lintCode in lintRuleCodes) {
    var name = lintCode.uniqueName.suffix;
    var info = statusInfo.nodes[name];
    if (info == null) {
      errorData.codesWithNoEntry.add(name);
    } else if (info is YamlMap) {
      var markedAsHavingFix = info['status'] == 'hasFix';
      if (lintCode.hasFix) {
        if (!markedAsHavingFix) {
          errorData.codesWithFixes.add(name);
        }
      } else {
        if (markedAsHavingFix) {
          errorData.codesWithoutFixes.add(name);
        }
      }
    }
  }

  var codeNames = {
    for (var code in diagnosticCodeValues) code.uniqueName.suffix,
  };
  for (var key in statusInfo.keys) {
    if (key is String) {
      if (!codeNames.contains(key) && !lintRuleNames.contains(key)) {
        errorData.entriesWithNoCode.add(key);
      }
    }
  }

  if (errorData.isNotEmpty) {
    return errorData.failureMessage;
  }

  // No errors.
  return null;
}

/// Returns the content of the file containing the status information, parsed
/// as a YAML map.
YamlMap _statusInfo() {
  var statusFile = _resourceProvider.getFile(statusFilePath());
  var document = loadYamlDocument(
    statusFile.readAsStringSync(),
    sourceUrl: Uri.file(statusFile.path),
  );
  var statusInfo = document.contents;
  if (statusInfo is! YamlMap) {
    throw LocatedError(
      'Expected a YamlMap, found ${statusInfo.runtimeType}',
      span: statusInfo.span,
    );
  }
  for (var value in statusInfo.nodes.values) {
    if (value is! YamlMap) {
      throw LocatedError('Expected a map', span: value.span);
    }
    switch (value.nodes['status']) {
      case null:
        throw LocatedError('A status entry is required', span: value.span);
      case YamlScalar(
        value: 'hasFix' || 'needsEvaluation' || 'needsFix' || 'noFix',
      ):
        // ok
        break;
      case var statusNode:
        throw LocatedError('Invalid status', span: statusNode.span);
    }
  }
  return statusInfo;
}

class ErrorData {
  final List<String> codesWithFixes = [];
  final List<String> codesWithNoEntry = [];
  final List<String> codesWithoutFixes = [];
  final List<String> entriesWithNoCode = [];

  /// A failure message composed from the various lists.
  String get failureMessage {
    var buffer = StringBuffer('In ${statusFilePath()}:\n');
    var needsBlankLine = false;
    if (codesWithNoEntry.isNotEmpty) {
      buffer.writeln('Add the following entries:');
      buffer.writeln();
      for (var code in codesWithNoEntry) {
        buffer.writeln('$code:');
        buffer.writeln('  status: needsEvaluation');
      }
      needsBlankLine = true;
    }
    if (entriesWithNoCode.isNotEmpty) {
      if (needsBlankLine) {
        buffer.writeln();
      }
      buffer.writeln('Remove the following entries:');
      for (var code in entriesWithNoCode) {
        buffer.writeln('- $code');
      }
      needsBlankLine = true;
    }
    if (codesWithFixes.isNotEmpty) {
      if (needsBlankLine) {
        buffer.writeln();
      }
      buffer.writeln('Mark the following entries as having fixes:');
      for (var code in codesWithFixes) {
        buffer.writeln('- $code');
      }
      needsBlankLine = true;
    }
    if (codesWithoutFixes.isNotEmpty) {
      if (needsBlankLine) {
        buffer.writeln();
      }
      buffer.writeln('Mark the following entries as not having fixes:');
      for (var code in codesWithoutFixes) {
        buffer.writeln('- $code');
      }
      needsBlankLine = true;
    }
    return buffer.toString();
  }

  bool get isNotEmpty =>
      codesWithFixes.isNotEmpty ||
      codesWithNoEntry.isNotEmpty ||
      codesWithoutFixes.isNotEmpty ||
      entriesWithNoCode.isNotEmpty;
}

extension on DiagnosticCode {
  /// Whether this [DiagnosticCode] is likely to have a fix associated with
  /// it.
  bool get hasFix {
    var self = this;
    if (self is LintCode) {
      return registeredFixGenerators.lintProducers.containsKey(self) ||
          registeredFixGenerators.lintMultiProducers.containsKey(self);
    }
    return registeredFixGenerators.nonLintProducers.containsKey(self) ||
        registeredFixGenerators.nonLintMultiProducers.containsKey(self) ||
        AnalysisOptionsFixGenerator.codesWithFixes.contains(self) ||
        PubspecFixGenerator.codesWithFixes.contains(self);
  }
}

extension on String {
  String get suffix => switch (split('.')) {
    [_, var s] => s,
    _ => throw 'Expected ErrorClass.ERROR_CODE, found $this',
  };
}
