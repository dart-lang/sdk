// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.occurrences;

import 'dart:collection';

import 'package:analysis_server/src/computer/element.dart' as server;
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/services/json.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';


/**
 * A computer for elements occurrences in a Dart [CompilationUnit].
 */
class DartUnitOccurrencesComputer {
  final CompilationUnit _unit;

  final Map<Element, List<int>> _elementsOffsets =
      new HashMap<Element, List<int>>();

  DartUnitOccurrencesComputer(this._unit);

  /**
   * Returns the computed occurrences, not `null`.
   */
  List<Occurrences> compute() {
    _unit.accept(new _DartUnitOccurrencesComputerVisitor(this));
    List<Occurrences> occurrences = <Occurrences>[];
    _elementsOffsets.forEach((engineElement, offsets) {
      var serverElement = new server.Element.fromEngine(engineElement);
      var length = engineElement.displayName.length;
      occurrences.add(new Occurrences(serverElement, offsets, length));
    });
    return occurrences;
  }

  void _addOccurrence(Element element, int offset) {
    if (element == null || element == DynamicElementImpl.instance) {
      return;
    }
    element = _canonicalizeElement(element);
    List<int> offsets = _elementsOffsets[element];
    if (offsets == null) {
      offsets = <int>[];
      _elementsOffsets[element] = offsets;
    }
    offsets.add(offset);
  }

  Element _canonicalizeElement(Element element) {
    if (element is FieldFormalParameterElement) {
      element = (element as FieldFormalParameterElement).field;
    }
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    if (element is Member) {
      element = (element as Member).baseElement;
    }
    return element;
  }
}


class Occurrences implements HasToJson {
  final server.Element element;
  final List<int> offsets;
  final int length;

  Occurrences(this.element, this.offsets, this.length);

  factory Occurrences.fromJson(Map<String, Object> map) {
    server.Element element = new server.Element.fromJson(map[ELEMENT]);
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
    Element element = node.bestElement;
    if (element != null) {
      computer._addOccurrence(element, node.offset);
    }
    return super.visitSimpleIdentifier(node);
  }
}
