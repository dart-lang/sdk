// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show
        Arguments,
        Combinator,
        DartType,
        DynamicType,
        FunctionNode,
        InterfaceType,
        LibraryDependency,
        LoadLibrary,
        Name,
        Nullability,
        Procedure,
        ProcedureKind,
        Reference,
        ReturnStatement;

import '../builder/builder.dart';
import '../builder/compilation_unit.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import 'forest.dart' show Forest;

/// Builder to represent the `deferLibrary.loadLibrary` calls and tear-offs.
class LoadLibraryBuilder extends NamedBuilderImpl {
  @override
  String get name => 'loadLibrary';

  @override
  final SourceLibraryBuilder parent;

  late final LibraryDependency importDependency =
      new LibraryDependency.deferredImport(
        _imported.libraryBuilder.library,
        _prefix,
        combinators: _combinators,
      )..fileOffset = _importCharOffset;

  /// Offset of the import prefix.
  @override
  final int fileOffset;

  /// Synthetic static method to represent the tear-off of 'loadLibrary'.  If
  /// null, no tear-offs were seen in the code and no method is generated.
  Procedure? tearoff;

  final CompilationUnit _imported;

  final String _prefix;

  final int _importCharOffset;

  final List<Combinator>? _combinators;

  LoadLibraryBuilder(
    this.parent,
    this.fileOffset,
    this._imported,
    this._prefix,
    this._importCharOffset,
    this._combinators,
  );

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => parent.fileUri;

  LoadLibrary createLoadLibrary(
    int charOffset,
    Forest forest,
    Arguments? arguments,
  ) {
    return forest.createLoadLibrary(charOffset, importDependency, arguments);
  }

  Procedure createTearoffMethod(Forest forest) {
    if (tearoff != null) {
      // Coverage-ignore-block(suite): Not run.
      return tearoff!;
    }
    LoadLibrary expression = createLoadLibrary(fileOffset, forest, null);
    String prefix = expression.import.name!;
    Name name = new Name('_#loadLibrary_$prefix', parent.library);
    Reference? reference = parent.indexedLibrary?.lookupGetterReference(name);
    return tearoff =
        new Procedure(
            name,
            ProcedureKind.Method,
            new FunctionNode(
              new ReturnStatement(expression),
              returnType: new InterfaceType(
                parent.loader.coreTypes.futureClass,
                Nullability.nonNullable,
                <DartType>[const DynamicType()],
              ),
            ),
            fileUri: parent.library.fileUri,
            isStatic: true,
            reference: reference,
          )
          ..fileStartOffset = fileOffset
          ..fileOffset = fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => name;
}
