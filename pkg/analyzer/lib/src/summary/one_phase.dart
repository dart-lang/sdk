// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';

/// Builds the summary for a build unit based on unresolved ASTs of its
/// compilation units.
///
/// The compilation units in [uriToUnit] are summarized, and the results are
/// stored in [assembler].  References to other compilation units are resolved
/// using the summaries stored in [dependencies].
///
/// [getDeclaredVariable] is used to resolve configurable imports.  If
/// [allowMissingFiles] is `false`, then failure to resolve an import will
/// result in an exception being thrown; otherwise unresolved imports will be
/// silently recovered from.
void summarize(
    Map<String, CompilationUnit> uriToUnit,
    SummaryDataStore dependencies,
    PackageBundleAssembler assembler,
    GetDeclaredVariable getDeclaredVariable,
    bool allowMissingFiles) {
  var uriToUnlinked = <String, UnlinkedUnitBuilder>{};
  uriToUnit.forEach((uri, compilationUnit) {
    var unlinkedUnit =
        serializeAstUnlinked(compilationUnit, serializeInferrableFields: false);
    uriToUnlinked[uri] = unlinkedUnit;
    assembler.addUnlinkedUnitViaUri(uri, unlinkedUnit);
  });

  LinkedLibrary getDependency(String absoluteUri) {
    var dependency = dependencies.linkedMap[absoluteUri];
    if (dependency == null && !allowMissingFiles) {
      throw new StateError('Missing dependency $absoluteUri');
    }
    return dependency;
  }

  UnlinkedUnit getUnit(String absoluteUri) {
    if (absoluteUri == null) {
      return null;
    }
    var unlinkedUnit =
        uriToUnlinked[absoluteUri] ?? dependencies.unlinkedMap[absoluteUri];
    if (unlinkedUnit == null && !allowMissingFiles) {
      throw new StateError('Missing unit $absoluteUri');
    }
    return unlinkedUnit;
  }

  // TODO(paulberry): is this bad?  Are we passing parts to link that we
  // shouldn't?
  var linkedLibraries = link(
      uriToUnlinked.keys.toSet(), getDependency, getUnit, getDeclaredVariable);

  linkedLibraries.forEach(assembler.addLinkedLibrary);
}
