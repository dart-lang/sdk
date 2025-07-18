// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;

import 'package:expect/async_helper.dart' show asyncTest;
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;
import 'package:front_end/src/api_prototype/kernel_generator.dart'
    show kernelForModule;
import 'package:front_end/src/api_prototype/memory_file_system.dart'
    show MemoryFileSystem;
import 'package:front_end/src/base/compiler_context.dart' show CompilerContext;
import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/kernel/utils.dart' show serializeComponent;
import 'package:front_end/src/kernel/cfe_verifier.dart' show verifyComponent;
import 'package:kernel/ast.dart' show Component;
import 'package:kernel/target/targets.dart';
import 'package:kernel/verifier.dart' show VerificationStage;

const Map<String, String> files = const <String, String>{
  "repro.dart": """

import 'lib.dart';

abstract class M<M_K, M_V> implements Map<M_K, Set<M_V>> {}

abstract class C<C_K, C_V> extends UnmodifiableMapView<C_K, Set<C_V>>
    with M<C_K, C_V> {
  C._() : super(null);
}
""",
  "lib.dart": """abstract class MapView<K, V> {
  const MapView(Map<K, V> map);
}

abstract class _UnmodifiableMapMixin<K, V> {}

abstract class UnmodifiableMapView<K, V> extends MapView<K, V>
    with _UnmodifiableMapMixin<K, V> {
  UnmodifiableMapView(Map<K, V> map) : super(map);
}""",
};

Future<void> test() async {
  final String platformBaseName = "vm_platform.dill";
  final Uri base = Uri.parse("org-dartlang-test:///");
  final Uri platformDill = base.resolve(platformBaseName);
  final List<int> platformDillBytes = await new File.fromUri(
          computePlatformBinariesLocation(forceBuildDir: true)
              .resolve(platformBaseName))
      .readAsBytes();
  MemoryFileSystem fs = new MemoryFileSystem(base);
  fs.entityForUri(platformDill).writeAsBytesSync(platformDillBytes);
  fs
      .entityForUri(base.resolve("lib.dart"))
      .writeAsStringSync(files["lib.dart"]!);
  CompilerOptions options = new CompilerOptions()
    ..fileSystem = fs
    ..sdkSummary = platformDill;

  Component component =
      (await kernelForModule(<Uri>[base.resolve("lib.dart")], options))
          .component!;

  fs = new MemoryFileSystem(base);
  fs.entityForUri(platformDill).writeAsBytesSync(platformDillBytes);
  fs
      .entityForUri(base.resolve("lib.dart.dill"))
      .writeAsBytesSync(serializeComponent(component));
  fs
      .entityForUri(base.resolve("repro.dart"))
      .writeAsStringSync(files["repro.dart"]!);

  options = new CompilerOptions()
    ..fileSystem = fs
    ..additionalDills = <Uri>[base.resolve("lib.dart.dill")]
    ..sdkSummary = platformDill
    ..target = new NoneTarget(new TargetFlags());

  List<Uri> inputs = <Uri>[base.resolve("repro.dart")];

  component = (await kernelForModule(inputs, options)).component!;

  List<Object> errors = await CompilerContext.runWithOptions(
      new ProcessedOptions(options: options, inputs: inputs),
      (CompilerContext c) => new Future<List<Object>>.value(verifyComponent(
          c, VerificationStage.afterModularTransformations, component,
          skipPlatform: true)));

  serializeComponent(component);

  if (errors.isNotEmpty) {
    throw "Verification failed";
  }
}

void main() {
  asyncTest(test);
}
