// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions;

import 'package:front_end/src/testing/compiler_common.dart' show compileScript;

import 'package:front_end/src/fasta/fasta_codes.dart'
    show codeSuperclassHasNoMethod;

const String testSource = '''
//@dart=2.19
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
    // member.
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
    names.add(getMessageArguments(message)!['name']);
  };
}

/// Check that by default an error is reported for all unresolved super
/// invocations: independently of weather they target abstract super members
/// or nonexistent targets.
Future<void> testSuperMixins() async {
  var missingSuperMethodNames = new Set<String>();
  var options = new CompilerOptions()
    ..onDiagnostic = _makeDiagnosticMessageHandler(missingSuperMethodNames);
  await compileScript(testSource, options: options);
  Expect.setEquals(
      const <String>['bar', 'baz', 'foo', 'quux'], missingSuperMethodNames);
}

void main() {
  asyncTest(() async {
    await testSuperMixins();
  });
}
