// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart2wasm/translator.dart';
import 'package:front_end/src/api_unstable/vm.dart' as fe;

class CompilerOptions {
  final TranslatorOptions translatorOptions = TranslatorOptions();

  Uri sdkPath = Platform.script.resolve("../../../sdk");
  Uri? platformPath;
  Uri? librariesSpecPath;
  Uri? packagesPath;
  Uri mainUri;
  String outputFile;
  String? depFile;
  String? outputJSRuntimeFile;
  Map<String, String> environment = const {};
  Map<fe.ExperimentalFlag, bool> feExperimentalFlags = const {};
  String? multiRootScheme;
  List<Uri> multiRoots = const [];
  bool constantBranchPruning = true;

  factory CompilerOptions.defaultOptions() =>
      CompilerOptions(mainUri: Uri(), outputFile: '');

  CompilerOptions({required this.mainUri, required this.outputFile});

  void validate() {
    if (translatorOptions.importSharedMemory &&
        translatorOptions.sharedMemoryMaxPages == null) {
      throw ArgumentError("--shared-memory-max-pages must be specified if "
          "--import-shared-memory is used.");
    }
  }
}
