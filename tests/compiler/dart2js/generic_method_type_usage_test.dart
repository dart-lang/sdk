// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart test verifying that method type variables are considered to denote
/// the type `dynamic`.
///
/// NB: This test is intended to succeed with a `dart2js` with the option
/// '--generic-method-syntax', but it should fail with a full implementation
/// of generic method support, and it should fail with every other tool than
/// `dart2js`.

library dart2js.test.generic_method_type_usage;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import "package:compiler/src/diagnostics/messages.dart";
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'type_variable_is_dynamic.dart': '''
class C {
  bool aMethod<X>(X x) {
    // `dynamic` is assignable to both `int` and `String`: no warnings.
    int i = x;
    String s = x;
    try {
      // Only `dynamic` allows unknown member lookup without a warning.
      var y = x.undefinedMember;
    } on NoSuchMethodError catch (_) {
      return true;
    }
    return false;
  }
}

bool aFunction<X>(X x) {
  // `dynamic` is assignable to both `int` and `String`: no warnings.
  int i = x;
  String s = x;
  try {
    // Only `dynamic` allows unknown member lookup without a warning.
    var y = x.undefinedMember;
  } on NoSuchMethodError catch (_) {
    return true;
  }
  return false;
}

main() {
  print(new C().aMethod<Set>(null));
  print(aFunction<Set>(null));
}
''',
  'cannot_new_method_type_variable.dart': '''
class C {
  X aMethod<X>() => new X();
}

main() {
  new C().aMethod<Set>();
}
''',
  'cannot_new_function_type_variable.dart': '''
X aFunction<X>() => new X(42);

main() {
  aFunction<Set>();
}
''',
  'dynamic_as_type_argument.dart': '''
main() {
  method<dynamic>();
}
method<T>() {}
''',
  'malformed_type_argument.dart': '''
main() {
  method<Unresolved>();
}
method<T>() {}
''',
};

Future runTest(Uri main, {MessageKind warning, MessageKind info}) async {
  print("----\nentry-point: $main\n");

  DiagnosticCollector diagnostics = new DiagnosticCollector();
  OutputCollector output = new OutputCollector();
  await runCompiler(
      entryPoint: main,
      options: const <String>["--generic-method-syntax"],
      memorySourceFiles: MEMORY_SOURCE_FILES,
      diagnosticHandler: diagnostics,
      outputProvider: output);

  Expect.isFalse(output.hasExtraOutput);
  Expect.equals(0, diagnostics.errors.length, "Unexpected errors.");
  Expect.equals(warning != null ? 1 : 0, diagnostics.warnings.length);
  if (warning != null) {
    Expect.equals(warning, diagnostics.warnings.first.message.kind);
  }
  Expect.equals(info != null ? 1 : 0, diagnostics.infos.length);
  if (info != null) {
    Expect.equals(info, diagnostics.infos.first.message.kind);
  }
  Expect.equals(0, diagnostics.hints.length);
}

void main() {
  asyncTest(() async {
    await runTest(Uri.parse('memory:type_variable_is_dynamic.dart'));

    await runTest(Uri.parse('memory:cannot_new_method_type_variable.dart'),
        warning: MessageKind.CANNOT_INSTANTIATE_TYPE_VARIABLE);

    await runTest(Uri.parse('memory:cannot_new_function_type_variable.dart'),
        warning: MessageKind.CANNOT_INSTANTIATE_TYPE_VARIABLE);

    await runTest(Uri.parse('memory:dynamic_as_type_argument.dart'));

    await runTest(Uri.parse('memory:malformed_type_argument.dart'),
        warning: MessageKind.CANNOT_RESOLVE_TYPE);
  });
}
