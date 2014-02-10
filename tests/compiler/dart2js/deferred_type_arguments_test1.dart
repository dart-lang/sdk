// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that elements only mentioned as type arguments to super classes are
// handled correctly by the deferred loading program segmentation.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';
import "dart:async";

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
    as dart2js;

class FakeOutputStream<T> extends EventSink<T> {
  void add(T event) {}
  void addError(T event, [StackTrace stackTrace]) {}
  void close() {}
}

void main() {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  var handler = new FormattingDiagnosticHandler(provider);

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   (name, extension) => new FakeOutputStream(),
                                   handler.diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   [],
                                   {});
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    Expect.isFalse(compiler.compilationFailed, "Compilation failed.");
    var outputUnitForElement = compiler.deferredLoadTask.outputUnitForElement;
    var mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;
    var lib = compiler.libraries["memory:lib.dart"];
    var lib2 = compiler.libraries["memory:lib2.dart"];
    var c = lib.find("C");
    for (String className in ["D", "E", "F", "G", "H", "I", "J", "K", "L"]) {
      var cls = lib2.find(className);
      Expect.equals(outputUnitForElement(c), outputUnitForElement(cls));
    }
  }));
}

// The classes of lib2 are only mentioned in type arguments of C. They should
// get an output unit assigned.
const Map MEMORY_SOURCE_FILES = const {"main.dart": """
import "dart:async";
@a import "lib.dart";

const a = const DeferredLibrary("lib");

main() {
  new C().foo();
}
""", "lib.dart": """
import "lib2.dart";

typedef A<F> g<T1, T2>(A<G> a, A<T1> b, [B<H, A<I>, T1, int> c]);
typedef void h(int l(J j, {K k}));

class A3<T> {}

class A2<T> implements A3<L> {}

class A<T> extends A2 {}

class B<T1, T2, T3, T4> {}

// Use g with one type argument to create a BadTypedefType.
// Use B with too few type arguments to create a BadTypedefType.
class C<T> extends A<E> implements B<A<D>, A<g<T>>, h, B<T>>{
  foo() {
    () {};
  }
}
""", "lib2.dart": """
class D {}
class E {}
class F {}
class G {}
class H {}
class I {}
class J {}
class K {}
class L {}
""",};
