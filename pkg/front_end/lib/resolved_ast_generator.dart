// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines a front-end API for converting source code to resolved ASTs.
///
/// Note: this entire library is deprecated.  It is provided as a migration path
/// until dev_compiler supports Dart Kernel.  Once dev_compiler has been
/// converted to use Dart Kernel, this functionality will be removed.
@deprecated
library front_end.resolved_ast_generator;

import 'dart:async';
import 'compiler_options.dart';
import 'package:analyzer/dart/ast/ast.dart' show CompilationUnit;
import 'package:analyzer/dart/element/element.dart' show LibraryElement;

/// Processes the build unit whose source files are in [sources].
///
/// Intended for modular compilation.
///
/// [sources] should be the complete set of source files for a build unit
/// (including both library and part files).  All of the library files are
/// compiled to resolved ASTs.
///
/// The compilation process is hermetic, meaning that the only files which will
/// be read are those listed in [sources], [CompilerOptions.inputSummaries], and
/// [CompilerOptions.sdkSummary].  If a source file attempts to refer to a file
/// which is not obtainable from these paths, that will result in an error, even
/// if the file exists on the filesystem.
///
/// Any `part` declarations found in [sources] must refer to part files which
/// are also listed in [sources], otherwise an error results.  (It is not
/// permitted to refer to a part file declared in another build unit).
@deprecated
Future<ResolvedAsts> resolvedAstsFor(
        List<Uri> sources, CompilerOptions options) =>
    throw new UnimplementedError();

/// Representation of the resolved ASTs of a build unit.
///
/// Not intended to be implemented or extended by clients.
@deprecated
abstract class ResolvedAsts {
  /// The resolved ASTs of the build unit's source libraries.
  ///
  /// There is one sub-list per source library; each sub-list consists of the
  /// resolved AST for the library's defining compilation unit, followed by the
  /// resolved ASTs for any of the library's part files.
  List<List<CompilationUnit>> get compilationUnits;

  /// Given a [LibraryElement] referred to by [compilationUnits], determine the
  /// path to the summary that the library originated from.  If the
  /// [LibraryElement] did not originate from a summary (i.e. because it
  /// originated from one of the source files of *this* build unit), return
  /// `null`.
  ///
  /// This can be used by the client to determine which build unit any
  /// referenced element originated from.
  String getOriginatingSummary(LibraryElement element);
}
