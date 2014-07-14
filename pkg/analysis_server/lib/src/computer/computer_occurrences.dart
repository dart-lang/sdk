// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.occurrences;

import 'dart:collection';

import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart' as engine;


/**
 * A computer for elements occurrences in a Dart [CompilationUnit].
 */
class DartUnitOccurrencesComputer {
  final CompilationUnit _unit;

  final Map<engine.Element, List<int>> _elementsOffsets =
      new HashMap<engine.Element, List<int>>();

  DartUnitOccurrencesComputer(this._unit);

  /**
   * Returns the computed occurrences, not `null`.
   */
  List<Occurrences> compute() {
    _unit.accept(new _DartUnitOccurrencesComputerVisitor(this));
    List<Occurrences> occurrences = <Occurrences>[];
    _elementsOffsets.forEach((engineElement, offsets) {
      Element serverElement = new Element.fromEngine(engineElement);
      int length = engineElement.displayName.length;
      occurrences.add(new Occurrences(serverElement, offsets, length));
    });
    return occurrences;
  }

  void _addOccurrence(engine.Element element, int offset) {
    List<int> offsets = _elementsOffsets[element];
    if (offsets == null) {
      offsets = <int>[];
      _elementsOffsets[element] = offsets;
    }
    offsets.add(offset);
  }
}


class Occurrences implements HasToJson {
  final Element element;
  final List<int> offsets;
  final int length;

  Occurrences(this.element, this.offsets, this.length);

  factory Occurrences.fromJson(Map<String, Object> map) {
    Element element = new Element.fromJson(map[ELEMENT]);
    List<int> offsets = map[OFFSETS];
    int length = map[LENGTH];
    return new Occurrences(element, offsets, length);
  }

  Map<String, Object> toJson() {
    Map<String, Object> json = new HashMap<String, Object>();
    json[ELEMENT] = element.toJson();
    json[OFFSETS] = offsets;
    json[LENGTH] = length;
    return json;
  }

  @override
  String toString() => toJson().toString();
}


class _DartUnitOccurrencesComputerVisitor extends RecursiveAstVisitor {
  final DartUnitOccurrencesComputer computer;

  _DartUnitOccurrencesComputerVisitor(this.computer);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    engine.Element element = node.bestElement;
    if (element != null) {
      computer._addOccurrence(element, node.offset);
    }
    return super.visitSimpleIdentifier(node);
  }
}
