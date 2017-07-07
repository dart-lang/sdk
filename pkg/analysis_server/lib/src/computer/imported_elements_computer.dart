// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/dart/ast/ast.dart';

/**
 * An object used to compute the list of elements referenced within a given
 * region of a compilation unit that are imported into the compilation unit's
 * library.
 */
class ImportedElementsComputer {
  /**
   * The compilation unit in which the elements are referenced.
   */
  final CompilationUnit unit;

  /**
   * The offset of the region containing the references to be returned.
   */
  final int offset;

  /**
   * The length of the region containing the references to be returned.
   */
  final int length;

  /**
   * Initialize a newly created computer to compute the list of imported
   * elements referenced in the given [unit] within the region with the given
   * [offset] and [length].
   */
  ImportedElementsComputer(this.unit, this.offset, this.length);

  /**
   * Compute and return the list of imported elements.
   */
  List<ImportedElements> compute() {
    // TODO(brianwilkerson) Implement this.
    return <ImportedElements>[];
  }
}
