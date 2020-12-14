// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

class LinkedLibraryContext {
  final LinkedElementFactory elementFactory;
  final String uriStr;
  final Reference reference;
  final List<LinkedUnitContext> units = [];

  LinkedLibraryContext(this.elementFactory, this.uriStr, this.reference);

  LinkedUnitContext get definingUnit => units.first;
}
