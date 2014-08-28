// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.poi.diff;

import 'dart:async' show
    Completer,
    Future,
    Stream;

import 'dart:convert' show
    LineSplitter,
    UTF8;

import 'package:compiler/compiler.dart' as api;

import 'package:compiler/implementation/dart2jslib.dart' show
    Compiler,
    Enqueuer,
    QueueFilter,
    Script,
    WorkItem;

import 'package:compiler/implementation/elements/visitor.dart' show
    ElementVisitor;

import 'package:compiler/implementation/elements/elements.dart' show
    AbstractFieldElement,
    ClassElement,
    CompilationUnitElement,
    Element,
    ElementCategory,
    FunctionElement,
    LibraryElement,
    ScopeContainerElement;

import 'package:compiler/implementation/elements/modelx.dart' as modelx;

import 'package:compiler/implementation/dart_types.dart' show
    DartType;

import 'package:compiler/implementation/scanner/scannerlib.dart' show
    EOF_TOKEN,
    ErrorToken,
    IDENTIFIER_TOKEN,
    KEYWORD_TOKEN,
    PartialClassElement,
    PartialElement,
    Token;

import 'package:compiler/implementation/source_file.dart' show
    StringSourceFile;

class Difference {
  final Element before;
  final Element after;
  Token token;

  Difference(this.before, this.after);

  String toString() {
    if (before == null) return 'Added($after)';
    if (after == null) return 'Removed($before)';
    return 'Modified($after -> $before)';
  }
}

List<Difference> computeDifference(
    ScopeContainerElement before,
    ScopeContainerElement after) {
  Map<String, Element> beforeMap = <String, Element>{};
  before.forEachLocalMember((Element element) {
    beforeMap[element.name] = element;
  });
  List<Difference> modifications = <Difference>[];
  List<Difference> potentiallyChanged = <Difference>[];
  after.forEachLocalMember((Element element) {
    Element existing = beforeMap.remove(element.name);
    if (existing == null) {
      modifications.add(new Difference(null, element));
    } else {
      potentiallyChanged.add(new Difference(existing, element));
    }
  });

  modifications.addAll(
      beforeMap.values.map((Element element) => new Difference(element, null)));

  modifications.addAll(
      potentiallyChanged.where(areDifferentElements));

  return modifications;
}

bool areDifferentElements(Difference diff) {
  Element beforeElement = diff.before;
  Element afterElement = diff.after;
  var before = (beforeElement is modelx.VariableElementX)
      ? beforeElement.variables : beforeElement;
  var after = (afterElement is modelx.VariableElementX)
      ? afterElement.variables : afterElement;
  if (before is PartialElement && after is PartialElement) {
    Token beforeToken = before.beginToken;
    Token afterToken = after.beginToken;
    Token stop = before.endToken;
    int beforeKind = beforeToken.kind;
    int afterKind = afterToken.kind;
    while (beforeKind != EOF_TOKEN && afterKind != EOF_TOKEN) {

      if (beforeKind != afterKind) {
        diff.token = afterToken;
        return true;
      }

      if (beforeToken is! ErrorToken && afterToken is! ErrorToken) {
        if (beforeToken.value != afterToken.value) {
          diff.token = afterToken;
          return true;
        }
      }

      if (beforeToken == stop) return false;

      beforeToken = beforeToken.next;
      afterToken = afterToken.next;
      beforeKind = beforeToken.kind;
      afterKind = afterToken.kind;
    }
    return beforeKind != afterKind;
  }
  print("$before isn't a PartialElement");
  return true;
}
