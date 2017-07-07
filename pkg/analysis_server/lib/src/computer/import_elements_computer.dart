// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

/**
 * An object used to compute the edits required to ensure that a list of
 * elements is imported into a given library.
 */
class ImportElementsComputer {
  /**
   * The analysis session used to compute the unit.
   */
  final AnalysisSession session;

  /**
   * The library element representing the library to which the imports are to be
   * added.
   */
  final LibraryElement libraryElement;

  /**
   * The path of the defining compilation unit of the library.
   */
  final String path;

  /**
   * The elements that are to be imported into the library.
   */
  final List<ImportedElements> elements;

  /**
   * Initialize a newly created computer to compute the edits required to ensure
   * that the given list of [elements] is imported into a given [library].
   */
  ImportElementsComputer(ResolveResult result, this.path, this.elements)
      : session = result.session,
        libraryElement = result.libraryElement;

  /**
   * Compute and return the list of edits.
   */
  List<SourceEdit> compute() {
    DartChangeBuilder builder = new DartChangeBuilder(session);
    builder.addFileEdit(path, (DartFileEditBuilder builder) {
      // TODO(brianwilkerson) Implement this.
    });
    return <SourceEdit>[]; // builder.sourceChange
  }
}
