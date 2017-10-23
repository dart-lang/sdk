// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that multiple inheritance created as part of mixin application reuse
// is not flagged as an error, but that user specified multiple inheritance
// still is.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/resolution/class_hierarchy.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

const Map<String, bool> TESTS = const {
  '''
class One<R> {}

class AnInterface<X> implements One<int> {}

class ADifferentInterface<Y> extends AnInterface<Y> {}

class TheMixin<Q> implements AnInterface<Q> {}

class Two<T> extends One<int> with TheMixin<T> implements AnInterface<T> {}

class Three<T> extends One<int> with TheMixin<T>
    implements ADifferentInterface<T> {}

main() {
  new Two<double>();
}
''': true,
  '''
class One<R> {}

class AnInterface<X> implements One<int> {}

class Two<U> extends One<U> implements AnInterface<double> {}

main() {
  new Two<int>();
}
''': false,
  '''
class A<T> {}

class B implements A<int>, A<double> {}

main() => new B();
''': false,
  '''
class One<R> {}

class TheMixin<Q> implements One<int> {}

class Two<T> extends One<int> with TheMixin<T> {}

main() {
  new Two<double>();
}
''': true,
  '''
class One<R> {}

class TheMixin<Q> implements One<int> {}

class Two<T> extends One<int> with TheMixin<T> {}

class Three<T> extends Two<T> implements One<double> {}

main() {
  new Three<int>();
}
''': false,
  '''
class One<R> {}

class AnInterface<X> implements One<int> {}

class ADifferentInterface<Y> extends AnInterface<Y> {}

class TheMixin<Q> implements AnInterface<Q> {}

class Two<T> extends One<double> with TheMixin<T> implements AnInterface<T> {}

class Three<T> extends One<double> with TheMixin<T>
    implements ADifferentInterface<T> {}

main() {
  new Two<double>();
}
''': false,
  '''
class One<R> {}

class AnInterface<X> implements One<int> {}

class ADifferentInterface<Y> extends AnInterface<Y> {}

class TheMixin<Q> implements AnInterface<Q> {}

class Two<T> extends One<T> with TheMixin<T> implements AnInterface<T> {}

class Three<T> extends One<T> with TheMixin<T>
    implements ADifferentInterface<T> {}

main() {
  new Two<double>();
}
''': false,
};

main() {
  asyncTest(() async {
    for (String code in TESTS.keys) {
      bool valid = TESTS[code];
      print('----------------------------------------------------------------');
      print(code);
      print('--from ast without mixin reuse----------------------------------');
      useOptimizedMixins = false;
      await test(code, valid: valid);
      print('--from ast with mixin reuse-------------------------------------');
      useOptimizedMixins = true;
      await test(code, valid: valid);
      print('--from kernel---------------------------------------------------');
      await test(code, valid: valid, options: [Flags.useKernel]);
    }
  });
}

test(String code, {bool valid, List<String> options: const <String>[]}) async {
  DiagnosticCollector collector = new DiagnosticCollector();
  await runCompiler(
      memorySourceFiles: {'main.dart': code},
      diagnosticHandler: collector,
      options: options);
  Expect.isTrue(collector.warnings.isEmpty);
  if (valid) {
    Expect.isTrue(collector.errors.isEmpty);
  } else {
    Expect.isFalse(collector.errors.isEmpty);
    for (CollectedMessage error in collector.errors) {
      Expect.equals(MessageKind.MULTI_INHERITANCE, error.messageKind);
    }
  }
}
