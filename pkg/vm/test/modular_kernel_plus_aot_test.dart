// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:front_end/src/api_unstable/bazel_worker.dart' as fe;
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/verifier.dart';
import 'package:vm/target/vm.dart';
import 'package:vm/kernel_front_end.dart';

main() async {
  Uri sdkSummary =
      sdkRootFile(Platform.executable).resolve('vm_platform_strong.dill');
  if (!await File.fromUri(sdkSummary).exists()) {
    // If we run from the <build-dir>/dart-sdk/bin folder, we need to navigate two
    // levels up.
    sdkSummary = sdkRootFile(Platform.executable)
        .resolve('../../vm_platform_strong.dill');
  }

  // Tests are run in the root directory of the sdk checkout.
  final Uri packagesFile = sdkRootFile('.packages');
  final Uri librariesFile = sdkRootFile('sdk/lib/libraries.json');

  final vmTarget = VmTarget(TargetFlags());

  await withTempDirectory((Uri uri) async {
    final mixinFilename = uri.resolve('mixin.dart');
    final mixinDillFilename = uri.resolve('mixin.dart.dill');
    await File.fromUri(mixinFilename).writeAsStringSync(mixinFile);

    await compileToKernel(vmTarget, librariesFile, sdkSummary, packagesFile,
        mixinDillFilename, <Uri>[mixinFilename], <Uri>[]);

    final mainFilename = uri.resolve('main.dart');
    final mainDillFilename = uri.resolve('main.dart.dill');
    await File.fromUri(mainFilename).writeAsStringSync(mainFile);

    await compileToKernel(vmTarget, librariesFile, sdkSummary, packagesFile,
        mainDillFilename, <Uri>[mainFilename], <Uri>[mixinDillFilename]);

    final bytes = concat(
        await File.fromUri(sdkSummary).readAsBytes(),
        concat(await File.fromUri(mixinDillFilename).readAsBytes(),
            await File.fromUri(mainDillFilename).readAsBytes()));
    final component = loadComponentFromBytes(bytes);

    // Verify before running global transformations.
    verifyComponent(component, isOutline: false, afterConst: true);

    const useGlobalTypeFlowAnalysis = true;
    const enableAsserts = false;
    const useProtobufTreeShaker = false;
    const useProtobufTreeShakerV2 = false;
    await runGlobalTransformations(
        vmTarget,
        component,
        useGlobalTypeFlowAnalysis,
        enableAsserts,
        useProtobufTreeShaker,
        useProtobufTreeShakerV2,
        ErrorDetector());

    // Verify after running global transformations.
    verifyComponent(component, isOutline: false, afterConst: true);
  });
}

Future compileToKernel(
    Target target,
    Uri librariesFile,
    Uri sdkSummary,
    Uri packagesFile,
    Uri outputFile,
    List<Uri> sources,
    List<Uri> additionalDills) async {
  final state = await fe.initializeCompiler(
      null,
      sdkSummary,
      librariesFile,
      packagesFile,
      additionalDills,
      target,
      StandardFileSystem.instance, const <String>[], const <String, String>{});

  void onDiagnostic(fe.DiagnosticMessage message) {
    print(message);
  }

  final Component component =
      await fe.compileComponent(state, sources, onDiagnostic);
  final Uint8List kernel = fe.serializeComponent(component,
      filter: (library) => sources.contains(library.importUri));
  await File(outputFile.toFilePath()).writeAsBytes(kernel);
}

Future withTempDirectory(Future func(Uri dirUri)) async {
  final dir = await Directory.systemTemp.createTemp('modular-compile-test');
  try {
    await func(dir.uri);
  } finally {
    await dir.delete(recursive: true);
  }
}

Uint8List concat(List<int> a, List<int> b) {
  final bytes = Uint8List(a.length + b.length);
  bytes.setRange(0, a.length, a);
  bytes.setRange(a.length, bytes.length, b);
  return bytes;
}

Uri sdkRootFile(name) => Directory.current.uri.resolveUri(Uri.file(name));

const String mainFile = r'''
import 'mixin.dart';
class R extends A2 {
  void bar() {
    mixinProperty = '';
    mixinProperty .foo();
    mixinMethod('').foo();
    super.mixinProperty= '';
    super.mixinProperty.foo();
    super.mixinMethod('').foo();
  }
}

main() {
  A1();
  final a2 = A2();
  // The mixin deduplication will remove the anonymous mixin application class
  // from `A2 & Mixin` and instead use the one from `A1 & Mixin`.
  a2.mixinProperty= '';
  a2.mixinProperty.foo();
  a2.mixinMethod('').foo();
}
''';

const String mixinFile = r'''
class Foo {
  foo() {}
}
class Mixin {
  void set mixinProperty(v) {}
  Foo get mixinProperty{}
  Foo mixinMethod(v) {}
}
class A1 extends Object with Mixin { }
class A2 extends Object with Mixin { }
''';
