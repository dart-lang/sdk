// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../../../options.dart';
import 'clone_mixin_methods_with_super.dart' as transformMixins;
import 'js_get_flag_lowering.dart';

void transformLibraries(
    List<Library> libraries, CoreTypes coreTypes, CompilerOptions options) {
  final transformer = _Lowering(coreTypes, options);
  libraries.forEach(transformer.visitLibrary);
}

class _Lowering extends Transformer {
  final JsGetFlagLowering _jsGetFlagLowering;

  _Lowering(CoreTypes coreTypes, CompilerOptions options)
      : _jsGetFlagLowering = JsGetFlagLowering(coreTypes, options);

  @override
  Class visitClass(Class node) {
    node.transformChildren(this);
    transformMixins.transformClass(node);
    return node;
  }

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    return _jsGetFlagLowering.transformStaticInvocation(node);
  }
}
