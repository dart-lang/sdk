// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'clone_mixin_methods_with_super.dart' as transformMixins;

void transformLibraries(List<Library> libraries) {
  final transformer = _Lowering();
  libraries.forEach(transformer.visitLibrary);
}

class _Lowering extends Transformer {
  @override
  Class visitClass(Class node) {
    node.transformChildren(this);
    transformMixins.transformClass(node);
    return node;
  }
}
