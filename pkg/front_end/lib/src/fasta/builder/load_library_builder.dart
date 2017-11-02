// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show
        Member,
        LoadLibrary,
        Procedure,
        ProcedureKind,
        Name,
        FunctionNode,
        ExpressionStatement,
        LibraryDependency;

import 'builder.dart' show Builder, LibraryBuilder;

/// Builder to represent the `deferLibrary.loadLibrary` calls and tear-offs.
class LoadLibraryBuilder extends Builder {
  final LibraryBuilder parent;

  final LibraryDependency importDependency;

  /// Synthetic static method to represent the tear-off of 'loadLibrary'.  If
  /// null, no tear-offs were seen in the code and no method is generated.
  Member tearoff;

  LoadLibraryBuilder(this.parent, this.importDependency, int charOffset)
      : super(parent, charOffset, parent.fileUri);

  LoadLibrary createLoadLibrary(int charOffset) {
    return new LoadLibrary(importDependency)..fileOffset = charOffset;
  }

  Procedure createTearoffMethod() {
    if (tearoff != null) return tearoff;
    LoadLibrary expression = createLoadLibrary(charOffset);
    String prefix = expression.import.name;
    tearoff = new Procedure(
        new Name('__loadLibrary_$prefix', parent.target),
        ProcedureKind.Method,
        new FunctionNode(new ExpressionStatement(expression)));
    return tearoff;
  }

  @override
  String get fullNameForErrors => 'loadLibrary';
}
