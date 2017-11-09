// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_target;

import 'package:front_end/physical_file_system.dart';
import 'package:kernel/ast.dart' show Library, Source;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/uri_translator.dart' show UriTranslator;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'analyzer_loader.dart' show AnalyzerLoader;

class AnalyzerTarget extends KernelTarget {
  AnalyzerTarget(
      DillTarget dillTarget, UriTranslator uriTranslator, bool strongMode,
      [Map<String, Source> uriToSource])
      : super(PhysicalFileSystem.instance, false, dillTarget, uriTranslator,
            uriToSource: uriToSource);

  @override
  AnalyzerLoader<Library> createLoader() => new AnalyzerLoader<Library>(this);
}
