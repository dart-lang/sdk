// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart';
import 'package:front_end/src/api_prototype/constant_evaluator.dart'
    show SimpleErrorReporter;
import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/verifier.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:vm/target_os.dart';
import 'package:vm/modular/target/vm.dart' show VmTarget;
import 'package:vm/transformations/unreachable_code_elimination.dart'
    show PlatformConstError, transformComponent;
import 'package:vm/transformations/vm_constant_evaluator.dart';

import '../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../..').toFilePath();

class TestErrorReporter extends SimpleErrorReporter {
  final reportedMessages = <String>[];

  TestErrorReporter();

  @override
  void reportMessage(Uri? uri, int offset, String message) {
    final buffer = StringBuffer();
    if (offset >= 0) {
      if (uri != null) {
        buffer
          ..write(uri.pathSegments.last)
          ..write(':');
      }
      buffer
        ..write(offset)
        ..write(' ');
    }
    buffer
      ..write('Constant evaluation error: ')
      ..write(message);
    reportedMessages.add(buffer.toString());
  }
}

class TestCase {
  final TargetOS os;
  final bool debug;
  final bool enableAsserts;
  final bool throws;

  const TestCase(this.os,
      {required this.debug, required this.enableAsserts, this.throws = false});

  String postfix() {
    String result = '.${os.name}';
    if (debug) {
      result += '.debug';
    }
    if (enableAsserts) {
      result += '.withAsserts';
    }
    return result;
  }
}

class TestOptions {
  static const Option<bool?> debug = Option('--debug', BoolValue(null));

  static const Option<bool?> enableAsserts =
      Option('--enable-asserts', BoolValue(null));

  static const Option<String?> targetOS = Option('--target-os', StringValue());

  static const List<Option> options = [debug, enableAsserts, targetOS];
}

runTestCase(Uri source, TestCase testCase) async {
  final target = new VmTarget(new TargetFlags());
  Component component = await compileTestCaseToKernelProgram(source,
      target: target,
      environmentDefines: {
        'test.define.debug': testCase.debug ? 'true' : 'false',
        'test.define.enableAsserts': testCase.enableAsserts ? 'true' : 'false',
      });

  final reporter = TestErrorReporter();
  final evaluator = VMConstantEvaluator.create(target, component, testCase.os,
      enableAsserts: testCase.enableAsserts, errorReporter: reporter);
  late String actual;
  if (testCase.throws) {
    try {
      component = transformComponent(
          target, component, evaluator, testCase.enableAsserts);
      final kernel =
          kernelLibraryToString(component.mainMethod!.enclosingLibrary);
      fail("Expected compilation failure, got:\n$kernel");
    } on PlatformConstError catch (e) {
      final buffer = StringBuffer();
      for (final message in reporter.reportedMessages) {
        buffer.writeln(message);
      }
      buffer
        ..write('Member: ')
        ..writeln(e.member.name);
      final uri = e.uri;
      if (uri != null) {
        buffer
          ..write('File: ')
          ..writeln(uri.pathSegments.last);
      }
      if (e.offset >= 0) {
        buffer
          ..write('Offset: ')
          ..writeln(e.offset);
      }
      buffer
        ..write('Message: ')
        ..writeln(e.message);
      actual = buffer.toString();
    }
  } else {
    component = transformComponent(
        target, component, evaluator, testCase.enableAsserts);
    if (reporter.reportedMessages.isNotEmpty) {
      fail('Expected no errors, got:\n${reporter.reportedMessages.join('\n')}');
    }
    verifyComponent(
        target, VerificationStage.afterGlobalTransformations, component);
    actual = kernelLibraryToString(component.mainMethod!.enclosingLibrary);
  }
  compareResultWithExpectationsFile(source, actual,
      expectFilePostfix: testCase.postfix());
}

void runWithTargetOS(ParsedOptions? parsedOptions, void Function(TargetOS) fn) {
  TargetOS? specified;
  if (parsedOptions != null) {
    final s = TestOptions.targetOS.read(parsedOptions);
    if (s != null) {
      specified = TargetOS.fromString(s);
      if (specified == null) {
        fail('Failure parsing options: unknown target OS $s');
      }
    }
  }
  if (specified != null) {
    fn(specified);
  } else {
    for (final targetOS in TargetOS.values) {
      fn(targetOS);
    }
  }
}

void runWithBool(Option<bool?> option, ParsedOptions? parsedOptions,
    void Function(bool) fn) {
  bool? specified;
  if (parsedOptions != null) {
    specified = option.read(parsedOptions);
  }
  if (specified != null) {
    fn(specified);
  } else {
    for (final value in [true, false]) {
      fn(value);
    }
  }
}

void runTest(String path, Uri uri, {bool throws = false}) {
  ParsedOptions? options;
  final optionsFile = File('$path.options');
  if (optionsFile.existsSync()) {
    options = ParsedOptions.parse(
        ParsedOptions.readOptionsFile(optionsFile.readAsStringSync()),
        TestOptions.options);
  }

  runWithTargetOS(options, (os) {
    runWithBool(TestOptions.enableAsserts, options, (enableAsserts) {
      runWithBool(TestOptions.debug, options, (debug) {
        final testCase = TestCase(os,
            debug: debug, enableAsserts: enableAsserts, throws: throws);
        test('$path${testCase.postfix()}', () => runTestCase(uri, testCase));
      });
    });
  });
}

main() {
  group('platform-use-transformation', () {
    final testCasesPath = path.join(
        pkgVmDir, 'testcases', 'transformations', 'vm_constant_evaluator');

    group('successes', () {
      final successCasesPath = path.join(testCasesPath, 'successes');
      for (var entry in Directory(successCasesPath)
          .listSync(recursive: true, followLinks: false)
          .reversed) {
        if (entry.path.endsWith('.dart')) {
          runTest(entry.path, entry.uri);
        }
      }
    });

    group('failures', () {
      final errorCasesPath = path.join(testCasesPath, 'errors');

      for (var entry in Directory(errorCasesPath)
          .listSync(recursive: true, followLinks: false)
          .reversed) {
        if (entry.path.endsWith('.dart')) {
          runTest(entry.path, entry.uri, throws: true);
        }
      }
    });
  });
}
