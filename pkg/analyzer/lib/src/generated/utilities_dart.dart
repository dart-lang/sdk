// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.utilities.dart;

import 'java_core.dart';

/**
 * The enumeration `ParameterKind` defines the different kinds of parameters. There are two
 * basic kinds of parameters: required and optional. Optional parameters are further divided into
 * two kinds: positional optional and named optional.
 */
class ParameterKind extends Enum<ParameterKind> {
  static const ParameterKind REQUIRED = const ParameterKind('REQUIRED', 0, false);

  static const ParameterKind POSITIONAL = const ParameterKind('POSITIONAL', 1, true);

  static const ParameterKind NAMED = const ParameterKind('NAMED', 2, true);

  static const List<ParameterKind> values = const [REQUIRED, POSITIONAL, NAMED];

  /**
   * A flag indicating whether this is an optional parameter.
   */
  final bool isOptional;

  /**
   * Initialize a newly created kind with the given state.
   *
   * @param isOptional `true` if this is an optional parameter
   */
  const ParameterKind(String name, int ordinal, this.isOptional) : super(name, ordinal);
}