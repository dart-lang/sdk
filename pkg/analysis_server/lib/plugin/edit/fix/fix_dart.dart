// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';

/// An object used to provide context information for [DartFixContributor]s.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartFixContext implements FixContext {
  /// Return the instrumentation service used to report errors that prevent a
  /// fix from being composed.
  InstrumentationService get instrumentationService;

  /// The resolution result in which fix operates.
  ResolvedUnitResult get resolveResult;

  /// The workspace in which the fix contributor operates.
  ChangeWorkspace get workspace;

  /// Return top-level declarations with the [name] in libraries that are
  /// available to this context.
  List<TopLevelDeclaration> getTopLevelDeclarations(String name);
}
