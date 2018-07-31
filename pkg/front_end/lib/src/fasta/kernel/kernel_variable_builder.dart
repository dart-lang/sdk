// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_variable_builder;

import 'package:kernel/ast.dart' show VariableDeclaration;

import 'kernel_builder.dart' show Declaration;

class KernelVariableBuilder extends Declaration {
  @override
  final Declaration parent;

  @override
  final Uri fileUri;

  final VariableDeclaration variable;

  KernelVariableBuilder(this.variable, this.parent, this.fileUri);

  @override
  int get charOffset => variable.fileOffset;

  bool get isLocal => true;

  bool get isConst => variable.isConst;

  bool get isFinal => variable.isFinal;

  @override
  bool get hasTarget => true;

  VariableDeclaration get target => variable;

  @override
  String get fullNameForErrors => variable.name ?? "<unnamed>";
}
