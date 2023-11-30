// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/elements/names.dart';

import 'package:compiler/src/util/memory_compiler.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/elements/entities.dart'
    show LibraryEntity, ClassEntity;
import 'package:compiler/src/kernel/dart2js_target.dart';
import 'package:compiler/src/phase/load_kernel.dart' as load_kernel;
import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/api_unstable/dart2js.dart';
import 'package:front_end/src/fasta/kernel/utils.dart' show serializeComponent;
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart' show TargetFlags;

/// Test that the compiler can load kernel in modular fragments.
main() {
  asyncTest(() async {
    var aDill = await compileUnit(['a0.dart'], {'a0.dart': sourceA});
    var bDill = await compileUnit(
        ['b1.dart'], {'b1.dart': sourceB, 'a.dill': aDill},
        deps: ['a.dill']);
    var cDill = await compileUnit(
        ['c2.dart'], {'c2.dart': sourceC, 'a.dill': aDill, 'b.dill': bDill},
        deps: ['a.dill', 'b.dill']);
    var unusedDill =
        await compileUnit(['unused0.dart'], {'unused0.dart': unusedSource});

    DiagnosticCollector diagnostics = DiagnosticCollector();
    OutputCollector output = OutputCollector();
    Uri entryPoint = Uri.parse('org-dartlang-test:///c2.dart');
    var compiler = compilerFor(
        entryPoint: entryPoint,
        options: [
          '--input-dill=memory:c.dill',
          '--dill-dependencies=memory:a.dill,memory:b.dill,memory:unused.dill',
          '--sound-null-safety',
        ],
        memorySourceFiles: {
          'a.dill': aDill,
          'b.dill': bDill,
          'c.dill': cDill,
          'unused.dill': unusedDill
        },
        diagnosticHandler: diagnostics,
        outputProvider: output);
    load_kernel.Output result = (await load_kernel.run(load_kernel.Input(
        compiler.options,
        compiler.provider,
        compiler.reporter,
        compiler.initializedCompilerState,
        false)))!;

    // Make sure we trim the unused library.
    Expect.isFalse(result.libraries!.any((l) => l.path == '/unused0.dart'));
    compiler.frontendStrategy
        .registerLoadedLibraries(result.component, result.libraries!);

    Expect.equals(0, diagnostics.errors.length);
    Expect.equals(0, diagnostics.warnings.length);

    ElementEnvironment environment =
        compiler.frontendStrategy.elementEnvironment;
    LibraryEntity? library = environment.lookupLibrary(toTestUri('b1.dart'));
    Expect.isNotNull(library);
    ClassEntity? clss = environment.lookupClass(library!, 'B1');
    Expect.isNotNull(clss);
    var member = environment.lookupClassMember(clss!, PublicName('foo'));
    Expect.isNotNull(member);
  });
}

/// Generate a component for a modular compilation unit.
Future<List<int>> compileUnit(List<String> inputs, Map<String, dynamic> sources,
    {List<String> deps = const []}) async {
  var fs = MemoryFileSystem(_defaultDir);
  sources.forEach((name, data) {
    var entity = fs.entityForUri(toTestUri(name));
    if (data is String) {
      entity.writeAsStringSync(data);
    } else {
      entity.writeAsBytesSync(data);
    }
  });
  List<Uri> additionalDills = [
    computePlatformBinariesLocation().resolve("dart2js_platform.dill"),
  ]..addAll(deps.map(toTestUri));
  fs
      .entityForUri(toTestUri('.dart_tool/package_config.json'))
      .writeAsStringSync('{"configVersion": 2, "packages": []}');
  var options = CompilerOptions()
    ..target = Dart2jsTarget("dart2js", TargetFlags())
    ..fileSystem = TestFileSystem(fs)
    ..nnbdMode = NnbdMode.Strong
    ..additionalDills = additionalDills
    ..packagesFileUri = toTestUri('.dart_tool/package_config.json')
    ..explicitExperimentalFlags = {ExperimentalFlag.nonNullable: true};
  var inputUris = inputs.map(toTestUri).toList();
  var inputUriSet = inputUris.toSet();
  var component = (await kernelForModule(inputUris, options)).component;
  for (var lib in component!.libraries) {
    if (!inputUriSet.contains(lib.importUri)) {
      lib.bindCanonicalNames(component.root);
    }
  }
  return serializeComponent(component,
      filter: (Library lib) => inputUriSet.contains(lib.importUri));
}

Uri _defaultDir = Uri.parse('org-dartlang-test:///');

Uri toTestUri(String relativePath) => _defaultDir.resolve(relativePath);

class TestFileSystem implements FileSystem {
  final MemoryFileSystem memory;
  final FileSystem physical = StandardFileSystem.instance;

  TestFileSystem(this.memory);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.isScheme('file')) return physical.entityForUri(uri);
    return memory.entityForUri(uri);
  }
}

const sourceA = '''
class A0 {
  StringBuffer buffer = StringBuffer();
}
''';

const sourceB = '''
import 'a0.dart';

class B1 extends A0 {
  A0? get foo => null;
}

A0 createA0() => A0();
''';

const sourceC = '''
import 'b1.dart';

class C2 extends B1 {
  final foo = createA0();
}

main() => print(C2().foo.buffer.toString());
''';

const unusedSource = '''
void unused() => throw 'Unused';
''';
