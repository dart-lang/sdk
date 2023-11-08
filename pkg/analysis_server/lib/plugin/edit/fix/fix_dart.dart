// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';

/// An object used to provide context information for [DartFixContributor]s.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartFixContext implements FixContext {
  /// Whether fixes were triggered automatically (for example by a save
  /// operation).
  ///
  /// Some fixes may be excluded when running automatically. For example
  /// removing unused imports or parameters is less acceptable while the code is
  /// incomplete and being worked on than when manually executing fixes ready
  /// for committing.
  bool get autoTriggered;

  /// Return the instrumentation service used to report errors that prevent a
  /// fix from being composed.
  InstrumentationService get instrumentationService;

  /// The resolution result in which fix operates.
  ResolvedUnitResult get resolveResult;

  /// The workspace in which the fix contributor operates.
  ChangeWorkspace get workspace;

  /// Return the mapping from a library (that is available to this context) to
  /// a top-level declaration that is exported (not necessary declared) by this
  /// library, and has the requested base name. For getters and setters the
  /// corresponding top-level variable is returned.
  Future<Map<LibraryElement, Element>> getTopLevelDeclarations(String name);

  /// Return libraries with extensions that declare non-static public
  /// extension members with the [memberName].
  Stream<LibraryElement> librariesWithExtensions(String memberName);
}
