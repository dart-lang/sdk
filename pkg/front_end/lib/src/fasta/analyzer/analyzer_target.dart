// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_target;

import 'package:kernel/ast.dart' show Library, Source;

import '../kernel/kernel_target.dart' show KernelTarget;

import '../translate_uri.dart' show TranslateUri;

import '../dill/dill_target.dart' show DillTarget;

import 'analyzer_loader.dart' show AnalyzerLoader;

class AnalyzerTarget extends KernelTarget {
  AnalyzerTarget(DillTarget dillTarget, TranslateUri uriTranslator,
      [Map<String, Source> uriToSource])
      : super(dillTarget, uriTranslator, uriToSource);

  @override
  AnalyzerLoader<Library> createLoader() => new AnalyzerLoader<Library>(this);
}
