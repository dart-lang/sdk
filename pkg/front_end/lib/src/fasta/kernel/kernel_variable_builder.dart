// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_variable_builder;

import 'package:kernel/ast.dart' show VariableDeclaration;

import 'kernel_builder.dart' show Builder;

class KernelVariableBuilder extends Builder {
  final VariableDeclaration variable;

  KernelVariableBuilder(
      VariableDeclaration variable, Builder parent, Uri fileUri)
      : variable = variable,
        super(parent, variable.fileOffset, fileUri);

  bool get isLocal => true;

  bool get isConst => variable.isConst;

  bool get isFinal => variable.isFinal;

  VariableDeclaration get target => variable;

  @override
  String get fullNameForErrors => variable.name ?? "<unnamed>";
}
