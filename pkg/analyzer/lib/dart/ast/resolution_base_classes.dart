// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Abstract base class for a resolved element maintained in an AST data
 * structure.
 *
 * This abstract type decouples the AST representation from depending on the
 * element model.
 */
abstract class ResolutionTarget {}

/**
 * Abstract base class for a resolved type maintained in AST data structure.
 *
 * This abstract type decouples the AST representation from depending on the
 * type model.
 */
abstract class ResolutionType {}
