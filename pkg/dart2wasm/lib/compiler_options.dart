// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/vm.dart' as fe;

import 'translator.dart';

class WasmCompilerOptions {
  final TranslatorOptions translatorOptions = TranslatorOptions();

  Uri? platformPath;
  Uri? librariesSpecPath;
  Uri? packagesPath;
  Uri mainUri;
  String outputFile;
  String? depFile;
  String? outputJSRuntimeFile;
  Map<String, String> environment = {};
  Map<fe.ExperimentalFlag, bool> feExperimentalFlags = const {};
  String? multiRootScheme;
  List<Uri> multiRoots = const [];
  List<String> deleteToStringPackageUri = const [];
  String? dumpKernelAfterCfe;
  String? dumpKernelBeforeTfa;
  String? dumpKernelAfterTfa;

  factory WasmCompilerOptions.defaultOptions() =>
      WasmCompilerOptions(mainUri: Uri(), outputFile: '');

  WasmCompilerOptions({required this.mainUri, required this.outputFile});

  void validate() {
    if (translatorOptions.importSharedMemory &&
        translatorOptions.sharedMemoryMaxPages == null) {
      throw ArgumentError("--shared-memory-max-pages must be specified if "
          "--import-shared-memory is used.");
    }
  }
}
