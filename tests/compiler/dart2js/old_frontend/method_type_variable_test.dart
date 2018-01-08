import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:expect/expect.dart';
import '../memory_compiler.dart';

runTest(String code,
    {List<MessageKind> expectedWarnings: const <MessageKind>[],
    List<MessageKind> expectedHints: const <MessageKind>[]}) async {
  print('--test--------------------------------------------------------------');
  print(code);
  DiagnosticCollector collector = new DiagnosticCollector();
  await runCompiler(
      memorySourceFiles: {'main.dart': code}, diagnosticHandler: collector);
  Expect.equals(0, collector.errors.length, "Unexpected errors.");
  Expect.listEquals(
      expectedWarnings,
      collector.warnings.map((m) => m.messageKind).toList(),
      "Unexpected warnings.");
  Expect.listEquals(expectedHints,
      collector.hints.map((m) => m.messageKind).toList(), "Unexpected hints.");
}

class Test {
  final String code;
  final List<MessageKind> warnings;
  final List<MessageKind> hints;

  const Test(this.code,
      {this.warnings: const <MessageKind>[],
      this.hints: const <MessageKind>[]});
}

const List<Test> tests = const <Test>[
  /// Is-test on method type variable in unused static method.
  const Test('''
method<T>(T t) => t is T;
main() {}
'''),

  /// Is-test on method type variable in used static method.
  const Test('''
method<T>(T t) => t is T;
main() => method<int>(0);
''', warnings: const <MessageKind>[
    MessageKind.TYPE_VARIABLE_FROM_METHOD_NOT_REIFIED
  ]),

  /// Is-test on method type variable in unused instance method.
  const Test('''
class C {
  method<T>(T t) => t is T;
}
main() => new C();
'''),

  /// Is-test on method type variable in used instance method.
  const Test('''
class C {
  method<T>(T t) => t is T;
}
main() => new C().method<int>(0);
''', warnings: const <MessageKind>[
    MessageKind.TYPE_VARIABLE_FROM_METHOD_NOT_REIFIED
  ]),

  /// As-cast on method type variable in unused static method.
  const Test('''
method<T>(T t) => t as T;
main() {}
'''),

  /// As-cast on method type variable in used static method.
  const Test('''
method<T>(T t) => t as T;
main() => method<int>(0);
''', hints: const <MessageKind>[
    MessageKind.TYPE_VARIABLE_FROM_METHOD_CONSIDERED_DYNAMIC
  ]),

  /// As-cast on method type variable in unused instance method.
  const Test('''
class C {
  method<T>(T t) => t as T;
}
main() => new C();
'''),

  /// As-cast on method type variable in used instance method.
  const Test('''
class C {
  method<T>(T t) => t as T;
}
main() => new C().method<int>(0);
''', hints: const <MessageKind>[
    MessageKind.TYPE_VARIABLE_FROM_METHOD_CONSIDERED_DYNAMIC
  ]),

  /// Method type variable literal in unused static method.
  const Test('''
method<T>() => T;
main() {}
'''),

  /// Method type variable literal in used static method.
  const Test('''
method<T>() => T;
main() => method<int>();
''', warnings: const <MessageKind>[
    MessageKind.TYPE_VARIABLE_FROM_METHOD_NOT_REIFIED
  ]),

  /// Method type variable literal in unused instance method.
  const Test('''
class C {
  method<T>() => T;
}
main() => new C();
'''),

  /// Method type variable literal in used instance method.
  const Test('''
class C {
  method<T>() => T;
}
main() => new C().method<int>();
''', warnings: const <MessageKind>[
    MessageKind.TYPE_VARIABLE_FROM_METHOD_NOT_REIFIED
  ]),
];

main() {
  asyncTest(() async {
    for (Test test in tests) {
      await runTest(
        test.code,
        expectedWarnings: test.warnings,
        expectedHints: test.hints,
      );
    }
  });
}
