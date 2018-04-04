// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_incremental_target;

import 'package:kernel/ast.dart' show Component, Source;

import '../../api_prototype/file_system.dart' show FileSystem;

import '../dill/dill_target.dart' show DillTarget;

import '../uri_translator.dart' show UriTranslator;

import 'kernel_target.dart' show KernelTarget;

class KernelIncrementalTarget extends KernelTarget {
  Component component;

  KernelIncrementalTarget(FileSystem fileSystem, bool includeComments,
      DillTarget dillTarget, UriTranslator uriTranslator,
      {Map<Uri, Source> uriToSource})
      : super(fileSystem, includeComments, dillTarget, uriTranslator,
            uriToSource: uriToSource);

  @override
  Component erroneousComponent(bool isFullComponent) {
    component = super.erroneousComponent(isFullComponent);
    throw const KernelIncrementalTargetErroneousComponent();
  }
}

class KernelIncrementalTargetErroneousComponent {
  const KernelIncrementalTargetErroneousComponent();
}
