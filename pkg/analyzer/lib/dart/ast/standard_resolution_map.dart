// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/resolution_map.dart';
import 'package:analyzer/src/dart/ast/resolution_map.dart';

/**
 * Gets an instance of [ResolutionMap] based on the standard AST implementation.
 */
final ResolutionMap resolutionMap = new ResolutionMapImpl();
