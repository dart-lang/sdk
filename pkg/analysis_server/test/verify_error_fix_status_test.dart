// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VerifyErrorFixStatusTest);
  });
}

@reflectiveTest
class VerifyErrorFixStatusTest {
  PhysicalResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  void test_statusFile() {
    var statusInfo = _statusInfo();
    var errorCodeNames = _errorCodeNames();
    var lintRuleNames = _lintRuleNames();

    var errorData = _ErrorData();
    for (var code in errorCodeValues) {
      var name = code.uniqueName;
      if (name.startsWith('TodoCode.')) {
        // To-do codes are ignored.
      } else {
        var info = statusInfo.nodes[name];
        if (info == null) {
          errorData.codesWithNoEntry.add(name);
        } else if (info is YamlMap) {
          var markedAsHavingFix = info['status'] == 'hasFix';
          var hasFix = _hasCodeFix(code);
          if (hasFix) {
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
    }
    for (var name in lintRuleNames) {
      var info = statusInfo.nodes[name];
      if (info == null) {
        errorData.codesWithNoEntry.add(name);
      } else if (info is YamlMap) {
        var markedAsHavingFix = info['status'] == 'hasFix';
        var hasFix = _hasLintFix(name);
        if (hasFix) {
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
      fail(_failureMessage(errorData));
    }
  }

  /// Return the unique names of the error codes.
  Set<String> _errorCodeNames() {
    var codes = errorCodeValues;
    var codeNames = <String>{};
    for (var code in codes) {
      codeNames.add(code.uniqueName);
    }
    return codeNames;
  }

  /// Return a failure message composed from the given lists.
  String _failureMessage(_ErrorData errorData) {
    var buffer = StringBuffer();
    var needsBlankLine = false;
    if (errorData.codesWithNoEntry.isNotEmpty) {
      buffer.writeln('Add the following entries:');
      buffer.writeln();
      for (var code in errorData.codesWithNoEntry) {
        buffer.writeln('$code:');
        buffer.writeln('  status: needsEvaluation');
      }
      needsBlankLine = true;
    }
    if (errorData.entriesWithNoCode.isNotEmpty) {
      if (needsBlankLine) {
        buffer.writeln();
      }
      buffer.writeln('Remove the following entries:');
      for (var code in errorData.entriesWithNoCode) {
        buffer.writeln('- $code');
      }
      needsBlankLine = true;
    }
    if (errorData.codesWithFixes.isNotEmpty) {
      if (needsBlankLine) {
        buffer.writeln();
      }
      buffer.writeln('Mark the following entries as having fixes:');
      for (var code in errorData.codesWithFixes) {
        buffer.writeln('- $code');
      }
      needsBlankLine = true;
    }
    if (errorData.codesWithoutFixes.isNotEmpty) {
      if (needsBlankLine) {
        buffer.writeln();
      }
      buffer.writeln('Mark the following entries as not having fixes:');
      for (var code in errorData.codesWithoutFixes) {
        buffer.writeln('- $code');
      }
      needsBlankLine = true;
    }
    return buffer.toString();
  }

  /// Return `true` if the given error [code] has a fix associated with it.
  bool _hasCodeFix(ErrorCode code) {
    var producers = FixProcessor.nonLintProducerMap[code];
    if (producers != null) {
      return true;
    }
    var multiProducers = FixProcessor.nonLintMultiProducerMap[code];
    if (multiProducers != null) {
      for (var producer in multiProducers) {
        if (producer is! DataDriven) {
          return true;
        }
      }
    }
    return false;
  }

  /// Return `true` if the lint with the given name has a fix associated with
  /// it.
  bool _hasLintFix(String codeName) {
    var name = codeName.substring('LintCode.'.length);
    var producers = FixProcessor.lintProducerMap[name];
    return producers != null;
  }

  /// Return the unique names of the lint rules.
  Set<String> _lintRuleNames() {
    registerLintRules();
    var ruleNames = <String>{};
    for (var rule in Registry.ruleRegistry.rules) {
      for (var code in rule.lintCodes) {
        ruleNames.add(code.uniqueName);
      }
    }
    return ruleNames;
  }

  /// Return the path to the file containing the status information.
  String _statusFilePath() {
    var pathContext = resourceProvider.pathContext;
    var packageRoot = pathContext.normalize(package_root.packageRoot);
    return pathContext.join(packageRoot, 'analysis_server', 'lib', 'src',
        'services', 'correction', 'error_fix_status.yaml');
  }

  /// Return the content of the file containing the status information, parsed
  /// as a YAML map.
  YamlMap _statusInfo() {
    var statusFile = resourceProvider.getFile(_statusFilePath());
    var document = loadYamlDocument(statusFile.readAsStringSync());
    var statusInfo = document.contents;
    if (statusInfo is! YamlMap) {
      fail('Expected a YamlMap, found ${statusInfo.runtimeType}');
    }
    return statusInfo;
  }
}

class _ErrorData {
  final List<String> codesWithFixes = [];
  final List<String> codesWithNoEntry = [];
  final List<String> codesWithoutFixes = [];
  final List<String> entriesWithNoCode = [];

  bool get isNotEmpty =>
      codesWithFixes.isNotEmpty ||
      codesWithNoEntry.isNotEmpty ||
      codesWithoutFixes.isNotEmpty ||
      entriesWithNoCode.isNotEmpty;
}
