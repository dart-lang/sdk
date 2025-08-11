// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/vm.dart' as fe;

import 'dynamic_modules.dart' show DynamicModuleType;
import 'translator.dart';

class WasmCompilerOptions {
  final TranslatorOptions translatorOptions = TranslatorOptions();

  Uri? platformPath;
  Uri? librariesSpecPath;
  Uri? packagesPath;
  Uri mainUri;
  String outputFile;
  String? depFile;
  DynamicModuleType? dynamicModuleType;
  Uri? dynamicMainModuleUri;
  Uri? dynamicInterfaceUri;
  Uri? dynamicModuleMetadataFile;
  bool validateDynamicModules = true;
  Map<String, String> environment = {};
  Map<fe.ExperimentalFlag, bool> feExperimentalFlags = const {};
  String? multiRootScheme;
  List<Uri> multiRoots = const [];
  List<String> deleteToStringPackageUri = const [];
  String? dumpKernelAfterCfe;
  String? dumpKernelBeforeTfa;
  String? dumpKernelAfterTfa;
  bool dryRun = false;

  factory WasmCompilerOptions.defaultOptions() =>
      WasmCompilerOptions(mainUri: Uri(), outputFile: '');

  WasmCompilerOptions({required this.mainUri, required this.outputFile});

  bool get enableDynamicModules => dynamicModuleType != null;

  void validate() {
    if (translatorOptions.importSharedMemory &&
        translatorOptions.sharedMemoryMaxPages == null) {
      throw ArgumentError("--shared-memory-max-pages must be specified if "
          "--import-shared-memory is used.");
    }

    if (enableDynamicModules) {
      if (dynamicMainModuleUri == null) {
        throw ArgumentError("--dynamic-module-main must be specified if "
            "compiling dynamic modules.");
      }

      if (dynamicInterfaceUri == null) {
        throw ArgumentError("--dynamic-module-interface must be specified if "
            "compiling dynamic modules.");
      }
    }
  }
}
