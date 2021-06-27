// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/analysis/occurrences/occurrences_core.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';

void addDartOccurrences(OccurrencesCollector collector, CompilationUnit unit) {
  var visitor = _DartUnitOccurrencesComputerVisitor();
  unit.accept(visitor);
  visitor.elementsOffsets.forEach((engineElement, offsets) {
    var length = engineElement.nameLength;
    var serverElement = protocol.convertElement(engineElement,
        withNullability: unit.isNonNullableByDefault);
    var occurrences = protocol.Occurrences(serverElement, offsets, length);
    collector.addOccurrences(occurrences);
  });
}

class _DartUnitOccurrencesComputerVisitor extends RecursiveAstVisitor<void> {
  final Map<Element, List<int>> elementsOffsets = <Element, List<int>>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element != null) {
      _addOccurrence(element, node.offset);
    }
    return super.visitSimpleIdentifier(node);
  }

  void _addOccurrence(Element element, int offset) {
    var canonicalElement = _canonicalizeElement(element);
    if (canonicalElement == null || element == DynamicElementImpl.instance) {
      return;
    }
    var offsets = elementsOffsets[canonicalElement];
    if (offsets == null) {
      offsets = <int>[];
      elementsOffsets[canonicalElement] = offsets;
    }
    offsets.add(offset);
  }

  Element? _canonicalizeElement(Element element) {
    Element? canonicalElement = element;
    if (canonicalElement is FieldFormalParameterElement) {
      canonicalElement = canonicalElement.field;
    } else if (canonicalElement is PropertyAccessorElement) {
      canonicalElement = canonicalElement.variable;
    }
    return canonicalElement?.declaration;
  }
}
