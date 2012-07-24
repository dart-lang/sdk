// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Renames types, identifiers before printing them out.
 * Does nothing by default.
 */
class Renamer {
  const Renamer();

  /**
   * Renames type name for given type annotation. Should not touch type
   * arguments. Returns [null] if no rename is needed.
   */
  String renameTypeName(TypeAnnotation type) => null;

  /**
   * Renames method name. Returns [null] if no rename is needed.
   */
  String renameSendMethod(Send send) => null;

  /**
   * Renames identifier. Returns [null] if no rename is needed.
   */
  String renameIdentifier(Identifier node) => null;
}
