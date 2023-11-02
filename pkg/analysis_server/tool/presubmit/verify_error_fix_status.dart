// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;
import 'package:linter/src/rules.dart';
import 'package:yaml/yaml.dart';

void main() {
  var errors = verifyErrorFixStatus();
  if (errors != null) {
    print(errors);
    exitCode = 1;
  }
}

PhysicalResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

/// Returns the path to the file containing the status information.
String statusFilePath() {
  var pathContext = resourceProvider.pathContext;
  var packageRoot = pathContext.normalize(package_root.packageRoot);
  return pathContext.join(packageRoot, 'analysis_server', 'lib', 'src',
      'services', 'correction', 'error_fix_status.yaml');
}

/// Verifies that the "error fix status" file is up-to-date and returns an error
/// string describing how the file is out-of-date, or `null` if the file is
/// up-to-date.
String? verifyErrorFixStatus() {
  var (error, statusInfo) = _statusInfo();
  if (error != null) {
    return error;
  }
  statusInfo!; // This is non-null when `error` is `null`.
  registerLintRules();
  var errorCodeNames = {
    for (var code in errorCodeValues) code.uniqueName,
  };
  var lintRuleCodes = {
    for (var rule in Registry.ruleRegistry.rules) ...rule.lintCodes,
  };
  var lintRuleNames = {
    for (var lintCode in lintRuleCodes) lintCode.uniqueName,
  };

  var errorData = ErrorData();
  for (var code in errorCodeValues) {
    var name = code.uniqueName;
    if (name.startsWith('TodoCode.')) {
      // To-do codes are ignored.
      continue;
    }

    var info = statusInfo.nodes[name];
    if (info == null) {
      errorData.codesWithNoEntry.add(name);
    } else if (info is YamlMap) {
      var markedAsHavingFix = info['status'] == 'hasFix';
      if (hasFix(code)) {
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
    var name = lintCode.uniqueName;
    var info = statusInfo.nodes[name];
    if (info == null) {
      errorData.codesWithNoEntry.add(name);
    } else if (info is YamlMap) {
      var markedAsHavingFix = info['status'] == 'hasFix';
      if (hasFix(lintCode)) {
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

  for (var key in statusInfo.keys) {
    if (key is String) {
      if (!errorCodeNames.contains(key) && !lintRuleNames.contains(key)) {
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
(String? error, YamlMap? info) _statusInfo() {
  var statusFile = resourceProvider.getFile(statusFilePath());
  var document = loadYamlDocument(statusFile.readAsStringSync());
  var statusInfo = document.contents;
  if (statusInfo is! YamlMap) {
    return ('Expected a YamlMap, found ${statusInfo.runtimeType}', null);
  }
  return (null, statusInfo);
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
