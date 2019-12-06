// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.incremental_dynamic_test;

import "package:_fe_analyzer_shared/src/messages/diagnostic_message.dart"
    show
        DiagnosticMessage,
        DiagnosticMessageHandler,
        getMessageCodeObject,
        getMessageArguments;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:async_helper/async_helper.dart' show asyncTest;

import 'package:expect/expect.dart' show Expect;

import 'package:kernel/target/targets.dart' show NoneTarget, TargetFlags;

import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions;

import 'package:front_end/src/testing/compiler_common.dart' show compileScript;

import 'package:front_end/src/fasta/fasta_codes.dart'
    show codeSuperclassHasNoMethod;

/// A subclass of NoneTarget that enables Flutter style super-mixin semantics.
///
/// See dartbug.com/31542 for details of the semantics.
class NoneTargetWithSuperMixins extends NoneTarget {
  NoneTargetWithSuperMixins(TargetFlags flags) : super(flags);

  @override
  bool get enableSuperMixins => true;
}

const String testSource = '''
abstract class A {
  void foo(String value);
}

abstract class B {
  void bar(String value);
}

abstract class Mixin extends A with B {
  void bar(String value) {
    // CFE should report an error on the line below under the normal
    // Dart 2 semantics, because super invocation targets abstract
    // member. However when enableSuperMixins is set
    // in the Target the error should be suppressed.
    super.bar(value);
    // This line should always trigger an error, irrespective of
    // whether super-mixins semantics is enabled or disabled.
    super.baz();
  }
}

class NotMixin extends A with B {
  void bar(String value) {
    // Both of these should be reported as error independently
    // of super-mixins semantics because NotMixin is not an abstract
    // class.
    super.foo(value);
    super.quux();
  }

  void foo(String value) {}
}

void main() {
  // Dummy main to avoid warning.
}
''';

DiagnosticMessageHandler _makeDiagnosticMessageHandler(Set<String> names) {
  return (DiagnosticMessage message) {
    Expect.equals(Severity.error, message.severity);
    Expect.identical(codeSuperclassHasNoMethod, getMessageCodeObject(message));
    Expect.isTrue(message.plainTextFormatted.length == 1);
    names.add(getMessageArguments(message)['name']);
  };
}

/// Check that by default an error is reported for all unresolved super
/// invocations: independently of weather they target abstract super members
/// or nonexistent targets.
testDisabledSuperMixins() async {
  var missingSuperMethodNames = new Set<String>();
  var options = new CompilerOptions()
    ..onDiagnostic = _makeDiagnosticMessageHandler(missingSuperMethodNames);
  await compileScript(testSource, options: options);
  Expect.setEquals(
      const <String>['bar', 'baz', 'foo', 'quux'], missingSuperMethodNames);
}

/// Check that in an abstract class an error is reported only for a
/// super-invocation that targets an non-existent method, a super-invocation
/// that targets an abstract member of the super-class should not be reported.
/// In non-abstract class we should report both cases as an error.
testEnabledSuperMixins() async {
  var missingSuperMethodNames = new Set<String>();
  var options = new CompilerOptions()
    ..onDiagnostic = _makeDiagnosticMessageHandler(missingSuperMethodNames)
    ..target = new NoneTargetWithSuperMixins(new TargetFlags());
  await compileScript(testSource, options: options);
  Expect.setEquals(
      const <String>['baz', 'foo', 'quux'], missingSuperMethodNames);
}

void main() {
  asyncTest(() async {
    await testDisabledSuperMixins();
    await testEnabledSuperMixins();
  });
}
