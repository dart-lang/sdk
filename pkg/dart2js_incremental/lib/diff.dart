// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.poi.diff;

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

import 'package:compiler/implementation/elements/modelx.dart' show
    DeclarationSite;

import 'package:compiler/implementation/scanner/scannerlib.dart' show
    EOF_TOKEN,
    ErrorToken,
    IDENTIFIER_TOKEN,
    KEYWORD_TOKEN,
    PartialClassElement,
    PartialElement,
    Token;

class Difference {
  final DeclarationSite before;
  final DeclarationSite after;
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
  Map<String, DeclarationSite> beforeMap = <String, DeclarationSite>{};
  before.forEachLocalMember((modelx.ElementX element) {
    DeclarationSite site = element.declarationSite;
    assert(site != null);
    beforeMap[element.name] = site;
  });
  List<Difference> modifications = <Difference>[];
  List<Difference> potentiallyChanged = <Difference>[];
  after.forEachLocalMember((modelx.ElementX element) {
    DeclarationSite existing = beforeMap.remove(element.name);
    if (existing == null) {
      modifications.add(new Difference(null, element.declarationSite));
    } else {
      potentiallyChanged.add(new Difference(existing, element.declarationSite));
    }
  });

  modifications.addAll(
      beforeMap.values.map(
          (DeclarationSite site) => new Difference(site, null)));

  modifications.addAll(
      potentiallyChanged.where(areDifferentElements));

  return modifications;
}

bool areDifferentElements(Difference diff) {
  DeclarationSite before = diff.before;
  DeclarationSite after = diff.after;
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
