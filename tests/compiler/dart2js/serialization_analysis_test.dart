// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_analysis_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/serialization/element_serialization.dart';
import 'package:compiler/src/serialization/impact_serialization.dart';
import 'package:compiler/src/serialization/json_serializer.dart';
import 'package:compiler/src/serialization/serialization.dart';
import 'package:compiler/src/serialization/task.dart';
import 'package:compiler/src/universe/world_impact.dart';
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

  const Test(const {
    'main.dart': r'''
import 'dart:math';

class MyRandom implements Random {
  int nextInt(int max) {
    return max.length;
  }
  bool nextBool() => true;
  double nextDouble() => 0.0;
}
main() {
  new MyRandom().nextInt(0);
}'''
  },
  expectedWarningCount: 1,
  expectedInfoCount: 0),

  const Test(const {
    'main.dart': r'''
import 'dart:math';

class MyRandom implements Random {
  int nextInt(int max) {
    return max.length;
  }
  bool nextBool() => true;
  double nextDouble() => 0.0;
}
main() {
  new MyRandom();
}'''
  }),

  const Test(const {
    'main.dart': r'''
import 'dart:math';

class MyRandom implements Random {
  int nextInt(int max) {
    return max.length;
  }
  bool nextBool() => true;
  double nextDouble() => 0.0;
}
main() {
  // Invocation of `MyRandom.nextInt` is only detected knowing the actual 
  // implementation class for `List` and the world impact of its `shuffle` 
  // method.  
  [].shuffle(new MyRandom());
}'''
  },
  expectedWarningCount: 1,
  expectedInfoCount: 0),
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
  DiagnosticCollector diagnosticCollector = new DiagnosticCollector();
  await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: test != null ? test.sourceFiles : const {},
      options: [Flags.analyzeOnly],
      diagnosticHandler: diagnosticCollector,
      beforeRun: (Compiler compiler) {
        Deserializer deserializer = new Deserializer.fromText(
            serializedData,
            const JsonSerializationDecoder());
        deserializer.plugins.add(compiler.backend.serialization.deserializer);
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
  Compiler compiler = compilerFor(
      options: [Flags.analyzeAll]);
  compiler.serialization.supportSerialization = true;
  await compiler.run(Uris.dart_core);
  return serialize(compiler);
}

String serialize(Compiler compiler) {
  Serializer serializer = new Serializer(const JsonSerializationEncoder());
  serializer.plugins.add(compiler.backend.serialization.serializer);
  serializer.plugins.add(new WorldImpactSerializer(compiler.resolution));

  for (LibraryElement library in compiler.libraryLoader.libraries) {
    serializer.serialize(library);
  }
  return serializer.toText();
}

const String WORLD_IMPACT_TAG = 'worldImpact';

class WorldImpactSerializer extends SerializerPlugin {
  final Resolution resolution;

  WorldImpactSerializer(this.resolution);

  @override
  void onElement(Element element, ObjectEncoder createEncoder(String tag)) {
    if (resolution.hasBeenResolved(element)) {
      WorldImpact impact = resolution.getWorldImpact(element);
      ObjectEncoder encoder = createEncoder(WORLD_IMPACT_TAG);
      impact.apply(new ImpactSerializer(encoder));
    }
  }
}

class WorldImpactDeserializer extends DeserializerPlugin {
  Map<Element, WorldImpact> impactMap = <Element, WorldImpact>{};

  @override
  void onElement(Element element, ObjectDecoder getDecoder(String tag)) {
    ObjectDecoder decoder = getDecoder(WORLD_IMPACT_TAG);
    if (decoder != null) {
      impactMap[element] = ImpactDeserializer.deserializeImpact(decoder);
    }
  }
}

class _DeserializerSystem extends DeserializerSystem {
  final Deserializer _deserializer;
  final List<LibraryElement> deserializedLibraries = <LibraryElement>[];
  final WorldImpactDeserializer _worldImpactDeserializer =
      new WorldImpactDeserializer();

  _DeserializerSystem(this._deserializer) {
    _deserializer.plugins.add(_worldImpactDeserializer);
  }

  LibraryElement readLibrary(Uri resolvedUri) {
    LibraryElement library = _deserializer.lookupLibrary(resolvedUri);
    if (library != null) {
      deserializedLibraries.add(library);
    }
    return library;
  }

  @override
  WorldImpact computeWorldImpact(Element element) {
    WorldImpact impact = _worldImpactDeserializer.impactMap[element];
    if (impact == null) {
      print('No impact found for $element (${element.library})');
      impact = const WorldImpact();
    }
    return impact;
  }

  @override
  bool isDeserialized(Element element) {
    return deserializedLibraries.contains(element.library);
  }
}
