// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_analysis_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/enqueue.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/serialization/serialization.dart';
import 'package:compiler/src/serialization/json_serializer.dart';
import 'package:compiler/src/serialization/task.dart';
import 'memory_compiler.dart';

const List<Test> TESTS = const <Test>[
  const Test(const {
    'main.dart': 'main() => print("Hello World");'
  }),

  const Test(const {
    'main.dart': 'main() => print("Hello World", 0);'
  },
  expectedWarningCount: 1,
  expectedInfoCount: 1),

  const Test(const {
    'main.dart': r'''
main() {
  String text = "Hello World";
  print('$text');
}'''
  }),

  const Test(const {
    'main.dart': r'''
main() {
  String text = "Hello World";
  print('$text', text);
}'''
  },
  expectedWarningCount: 1,
  expectedInfoCount: 1),

  const Test(const {
    'main.dart': r'''
main(List<String> arguments) {
  print(arguments);
}'''
  }),

  const Test(const {
      'main.dart': r'''
main(List<String> arguments) {
  for (int i = 0; i < arguments.length; i++) {
    print(arguments[i]);
  }
}'''
    }),

  const Test(const {
    'main.dart': r'''
main(List<String> arguments) {
  for (String argument in arguments) {
    print(argument);
  }
}'''
  }),

  const Test(const {
    'main.dart': r'''
class Class {}
main() {
  print(new Class());
}'''
  }),

  const Test(const {
    'main.dart': r'''
class Class implements Function {}
main() {
  print(new Class());
}'''
  },
  expectedWarningCount: 1),

  const Test(const {
    'main.dart': r'''
class Class implements Function {
  call() {}
}
main() {
  print(new Class()());
}'''
  }),

  const Test(const {
    'main.dart': r'''
class Class implements Comparable<Class> {
  int compareTo(Class other) => 0;
}
main() {
  print(new Class());
}'''
  }),

  const Test(const {
    'main.dart': r'''
class Class implements Comparable<Class, Class> {
  int compareTo(other) => 0;
}
main() {
  print(new Class());
}'''
  },
  expectedWarningCount: 1),

  const Test(const {
    'main.dart': r'''
class Class implements Comparable<Class> {
  int compareTo(String other) => 0;
}
main() {
  print(new Class().compareTo(null));
}'''
  },
  expectedWarningCount: 1,
  expectedInfoCount: 1),

  const Test(const {
    'main.dart': r'''
class Class implements Comparable {
  bool compareTo(a, b) => true;
}
main() {
  print(new Class().compareTo(null, null));
}'''
  },
  expectedWarningCount: 1,
  expectedInfoCount: 1),
];

main(List<String> arguments) {
  asyncTest(() async {
    String serializedData = await serializeDartCore();

    if (arguments.isNotEmpty) {
      Uri entryPoint = Uri.base.resolve(nativeToUriPath(arguments.last));
      await analyze(serializedData, entryPoint, null);
    } else {
      Uri entryPoint = Uri.parse('memory:main.dart');
      for (Test test in TESTS) {
        await analyze(serializedData, entryPoint, test);
      }
    }
  });
}

class Test {
  final Map sourceFiles;
  final int expectedErrorCount;
  final int expectedWarningCount;
  final int expectedHintCount;
  final int expectedInfoCount;

  const Test(this.sourceFiles, {
    this.expectedErrorCount: 0,
    this.expectedWarningCount: 0,
    this.expectedHintCount: 0,
    this.expectedInfoCount: 0});
}

Future analyze(String serializedData, Uri entryPoint, Test test) async {
  Deserializer deserializer = new Deserializer.fromText(
      serializedData, const JsonSerializationDecoder());
  DiagnosticCollector diagnosticCollector = new DiagnosticCollector();
  await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: test != null ? test.sourceFiles : const {},
      options: ['--analyze-only', '--output-type=dart'],
      diagnosticHandler: diagnosticCollector,
      beforeRun: (Compiler compiler) {
        compiler.serialization.deserializer =
            new _DeserializerSystem(deserializer);
      });
  if (test != null) {
    Expect.equals(test.expectedErrorCount, diagnosticCollector.errors.length,
        "Unexpected error count.");
    Expect.equals(
        test.expectedWarningCount,
        diagnosticCollector.warnings.length,
        "Unexpected warning count.");
    Expect.equals(test.expectedHintCount, diagnosticCollector.hints.length,
        "Unexpected hint count.");
    Expect.equals(test.expectedInfoCount, diagnosticCollector.infos.length,
        "Unexpected info count.");
  }
}

Future<String> serializeDartCore() async {
  Compiler compiler = compilerFor({},
      options: ['--analyze-all', '--output-type=dart']);
  await compiler.runCompiler(Uri.parse('dart:core'));
  return serialize(compiler.libraryLoader.libraries);
}

String serialize(Iterable<LibraryElement> libraries) {
  Serializer serializer = new Serializer(const JsonSerializationEncoder());
  for (LibraryElement library in libraries) {
    serializer.serialize(library);
  }
  return serializer.toText();
}

class _DeserializerSystem extends DeserializerSystem {
  final Deserializer _deserializer;
  final List<LibraryElement> deserializedLibraries = <LibraryElement>[];

  _DeserializerSystem(this._deserializer);

  LibraryElement readLibrary(Uri resolvedUri) {
    LibraryElement library = _deserializer.lookupLibrary(resolvedUri);
    if (library != null) {
      deserializedLibraries.add(library);
    }
    return library;
  }

  @override
  WorldImpact computeWorldImpact(Element element) {
    return const WorldImpact();
  }

  @override
  bool isDeserialized(Element element) {
    return deserializedLibraries.contains(element.library);
  }
}