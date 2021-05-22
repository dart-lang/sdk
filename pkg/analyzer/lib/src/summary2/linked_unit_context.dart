// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/linked_library_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

/// The context of a unit - the context of the bundle, and the unit tokens.
class LinkedUnitContext {
  final LinkedLibraryContext libraryContext;
  final int indexInLibrary;
  final String? partUriStr;
  final String uriStr;
  final Reference reference;
  final bool isSynthetic;
  final CompilationUnitImpl unit;

  LinkedUnitContext(this.libraryContext, this.indexInLibrary, this.partUriStr,
      this.uriStr, this.reference, this.isSynthetic,
      {required this.unit});

  CompilationUnitElementImpl get element {
    return reference.element as CompilationUnitElementImpl;
  }
}
