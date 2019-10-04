// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show
        Arguments,
        DartType,
        DynamicType,
        FunctionNode,
        InterfaceType,
        LibraryDependency,
        LoadLibrary,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        ReturnStatement;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../builder/declaration.dart';

import 'forest.dart' show Forest;

/// Builder to represent the `deferLibrary.loadLibrary` calls and tear-offs.
class LoadLibraryBuilder extends BuilderImpl {
  final SourceLibraryBuilder parent;

  final LibraryDependency importDependency;

  /// Offset of the import prefix.
  final int charOffset;

  /// Synthetic static method to represent the tear-off of 'loadLibrary'.  If
  /// null, no tear-offs were seen in the code and no method is generated.
  Member tearoff;

  LoadLibraryBuilder(this.parent, this.importDependency, this.charOffset);

  Uri get fileUri => parent.fileUri;

  LoadLibrary createLoadLibrary(
      int charOffset, Forest forest, Arguments arguments) {
    return forest.createLoadLibrary(charOffset, importDependency, arguments);
  }

  Procedure createTearoffMethod(Forest forest) {
    if (tearoff != null) return tearoff;
    LoadLibrary expression = createLoadLibrary(charOffset, forest, null);
    String prefix = expression.import.name;
    tearoff = new Procedure(
        new Name('__loadLibrary_$prefix', parent.library),
        ProcedureKind.Method,
        new FunctionNode(new ReturnStatement(expression),
            returnType: new InterfaceType(parent.loader.coreTypes.futureClass,
                <DartType>[const DynamicType()])),
        fileUri: parent.library.fileUri,
        isStatic: true)
      ..startFileOffset = charOffset
      ..fileOffset = charOffset;
    return tearoff;
  }

  @override
  String get fullNameForErrors => 'loadLibrary';
}
