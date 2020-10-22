// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import '../helpers/memory_compiler.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/apiimpl.dart' show CompilerImpl;
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/entities.dart'
    show LibraryEntity, ClassEntity;
import 'package:compiler/src/kernel/dart2js_target.dart';
import 'package:compiler/src/kernel/loader.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;
import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
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

    DiagnosticCollector diagnostics = new DiagnosticCollector();
    OutputCollector output = new OutputCollector();
    Uri entryPoint = Uri.parse('memory:c.dill');
    CompilerImpl compiler = compilerFor(
        entryPoint: entryPoint,
        options: ['--dill-dependencies=memory:a.dill,memory:b.dill'],
        memorySourceFiles: {'a.dill': aDill, 'b.dill': bDill, 'c.dill': cDill},
        diagnosticHandler: diagnostics,
        outputProvider: output);
    await compiler.setupSdk();
    KernelResult result = await compiler.kernelLoader.load(entryPoint);
    compiler.frontendStrategy.registerLoadedLibraries(result);

    Expect.equals(0, diagnostics.errors.length);
    Expect.equals(0, diagnostics.warnings.length);

    ElementEnvironment environment =
        compiler.frontendStrategy.elementEnvironment;
    LibraryEntity library = environment.lookupLibrary(toTestUri('b1.dart'));
    Expect.isNotNull(library);
    ClassEntity clss = environment.lookupClass(library, 'B1');
    Expect.isNotNull(clss);
    var member = environment.lookupClassMember(clss, 'foo');
    Expect.isNotNull(member);
  });
}

/// Generate a component for a modular complation unit.
Future<List<int>> compileUnit(List<String> inputs, Map<String, dynamic> sources,
    {List<String> deps: const []}) async {
  var fs = new MemoryFileSystem(_defaultDir);
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
  fs.entityForUri(toTestUri('.packages')).writeAsStringSync('');
  var options = new CompilerOptions()
    ..target = new Dart2jsTarget("dart2js", new TargetFlags())
    ..fileSystem = new TestFileSystem(fs)
    ..additionalDills = additionalDills
    ..packagesFileUri = toTestUri('.packages')
    ..explicitExperimentalFlags = {ExperimentalFlag.nonNullable: true};
  var inputUris = inputs.map(toTestUri).toList();
  var inputUriSet = inputUris.toSet();
  var component = (await kernelForModule(inputUris, options)).component;
  for (var lib in component.libraries) {
    if (!inputUriSet.contains(lib.importUri)) {
      component.root.getChildFromUri(lib.importUri).bindTo(lib.reference);
      lib.computeCanonicalNames();
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
    if (uri.scheme == 'file') return physical.entityForUri(uri);
    return memory.entityForUri(uri);
  }
}

const sourceA = '''
// @dart=2.7
class A0 {
  StringBuffer buffer = new StringBuffer();
}
''';

const sourceB = '''
// @dart=2.7
import 'a0.dart';

class B1 extends A0 {
  A0 get foo => null;
}

A0 createA0() => new A0();
''';

const sourceC = '''
// @dart=2.7
import 'b1.dart';

class C2 extends B1 {
  final foo = createA0();
}

main() => print(new C2().foo.buffer.toString());
''';
