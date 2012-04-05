// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("../../../css/css.dart");

class ExpressionTest {

  static testMain() {
    initCssWorld();

    testClass();
    testId();
    testElement();
    testNamespace();
    testSelectorGroups();
    testCombinator();
    testWildcard();
    testPseudo();
    testAttribute();
    testNegation();
  }

  static void testClass() {
    Parser parser = new Parser(new SourceFile(
        SourceFile.IN_MEMORY_FILE, ".foobar {}"));

    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);
    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    RuleSet ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    List<SimpleSelectorSequence> simpleSeqs =
        ruleset.selectorGroup.selectors[0].simpleSelectorSequences;
    Expect.equals(simpleSeqs.length, 1);
    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      Expect.isTrue(simpSelector is ClassSelector);
      Expect.isTrue(selector.isCombinatorNone());
      Expect.equals(simpSelector.name, "foobar");
    }

    parser = new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE,
        ".foobar .bar .no-story {}"));

    stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);
    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    simpleSeqs = ruleset.selectorGroup.selectors[0].simpleSelectorSequences;
  
    var idx = 0;
    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      if (idx == 0) {
        Expect.isTrue(simpSelector is ClassSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.equals(simpSelector.name, "foobar");
      } else if (idx == 1) {
        Expect.isTrue(simpSelector is ClassSelector);
        Expect.isTrue(selector.isCombinatorDescendant());
        Expect.equals(simpSelector.name, "bar");
      } else if (idx == 2) {
        Expect.isTrue(simpSelector is ClassSelector);
        Expect.isTrue(selector.isCombinatorDescendant());
        Expect.equals(simpSelector.name, "no-story");
      } else {
        Expect.fail("unexpected expression");
      }

      idx++;
    }

    Expect.equals(simpleSeqs.length, idx);
  }

  static void testId() {
    Parser parser = new Parser(new SourceFile(
        SourceFile.IN_MEMORY_FILE, "#elemId {}"));

    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);
    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    RuleSet ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    List<SimpleSelectorSequence> simpleSeqs =
        ruleset.selectorGroup.selectors[0].simpleSelectorSequences;
  
    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      Expect.isTrue(simpSelector is IdSelector);
      Expect.isTrue(selector.isCombinatorNone());
      Expect.equals(simpSelector.name, "elemId");
    }
  }

  static void testElement() {
    Parser parser = new Parser(new SourceFile(
        SourceFile.IN_MEMORY_FILE, "div {}"));
    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);
    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    RuleSet ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    List<SimpleSelectorSequence> simpleSeqs =
        ruleset.selectorGroup.selectors[0].simpleSelectorSequences;

    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      Expect.isTrue(simpSelector is ElementSelector);
      Expect.isTrue(selector.isCombinatorNone());
      Expect.equals(simpSelector.name, "div");
    }

    parser = new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE,
        "div div span {}"));
    stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);
    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    simpleSeqs = ruleset.selectorGroup.selectors[0].simpleSelectorSequences;

    var idx = 0;
    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      if (idx == 0) {
        Expect.isTrue(simpSelector is ElementSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.equals(simpSelector.name, "div");
      } else if (idx == 1) {
        Expect.isTrue(simpSelector is ElementSelector);
        Expect.isTrue(selector.isCombinatorDescendant());
        Expect.equals(simpSelector.name, "div");
      } else if (idx == 2) {
        Expect.isTrue(simpSelector is ElementSelector);
        Expect.isTrue(selector.isCombinatorDescendant());
        Expect.equals(simpSelector.name, "span");
      } else {
        Expect.fail("unexpected expression");
      }
  
      idx++;
    }
    Expect.equals(simpleSeqs.length, idx);
  }

  static void testNamespace() {
    Parser parser = new Parser(new SourceFile(
        SourceFile.IN_MEMORY_FILE, "ns1|div {}"));
    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);
    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    RuleSet ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    List<SimpleSelectorSequence> simpleSeqs =
        ruleset.selectorGroup.selectors[0].simpleSelectorSequences;

    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      Expect.isTrue(simpSelector is NamespaceSelector);
      Expect.isTrue(selector.isCombinatorNone());
      Expect.isFalse(simpSelector.isNamespaceWildcard());
      Expect.equals(simpSelector.namespace, "ns1");
      ElementSelector elementSelector = simpSelector.nameAsSimpleSelector;
      Expect.isTrue(elementSelector is ElementSelector);
      Expect.isFalse(elementSelector.isWildcard());
      Expect.equals(elementSelector.name, "div");
    }

    parser = new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE,
        "ns1|div div ns2|span .foobar {}"));
    stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);

    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    simpleSeqs = ruleset.selectorGroup.selectors[0].simpleSelectorSequences;

    var idx = 0;
    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      if (idx == 0) {
        Expect.isTrue(simpSelector is NamespaceSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.equals(simpSelector.namespace, "ns1");
        ElementSelector elementSelector = simpSelector.nameAsSimpleSelector;
        Expect.isTrue(elementSelector is ElementSelector);
        Expect.isFalse(elementSelector.isWildcard());
        Expect.equals(elementSelector.name, "div");
      } else if (idx == 1) {
        Expect.isTrue(simpSelector is ElementSelector);
        Expect.isTrue(selector.isCombinatorDescendant());
        Expect.equals(simpSelector.name, "div");
      } else if (idx == 2) {
        Expect.isTrue(simpSelector is NamespaceSelector);
        Expect.isTrue(selector.isCombinatorDescendant());
        Expect.equals(simpSelector.namespace, "ns2");
        ElementSelector elementSelector = simpSelector.nameAsSimpleSelector;
        Expect.isTrue(elementSelector is ElementSelector);
        Expect.isFalse(elementSelector.isWildcard());
        Expect.equals(elementSelector.name, "span");
      } else if (idx == 3) {
        Expect.isTrue(simpSelector is ClassSelector);
        Expect.isTrue(selector.isCombinatorDescendant());
        Expect.equals(simpSelector.name, "foobar");
      } else {
        Expect.fail("unexpected expression");
      }
  
      idx++;
    }

    Expect.equals(simpleSeqs.length, idx);
  }

  static void testSelectorGroups() {
    Parser parser = new Parser(new SourceFile(
        SourceFile.IN_MEMORY_FILE,
        "div, .foobar ,#elemId, .xyzzy .test, ns1|div div #elemId .foobar {}"));
    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);

    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    RuleSet ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 5);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    var groupIdx = 0;
    for (final selectorGroup in ruleset.selectorGroup.selectors) {
      var idx = 0;
      for (final selector in selectorGroup.simpleSelectorSequences) {
        final simpSelector = selector.simpleSelector;
        switch (groupIdx) {
          case 0:                       // First selector group.
            Expect.isTrue(simpSelector is ElementSelector);
            Expect.isTrue(selector.isCombinatorNone());
            Expect.equals(simpSelector.name, "div");
            break;
          case 1:                       // Second selector group.
            Expect.isTrue(simpSelector is ClassSelector);
            Expect.isTrue(selector.isCombinatorNone());
            Expect.equals(simpSelector.name, "foobar");
            break;
          case 2:                       // Third selector group.
            Expect.isTrue(simpSelector is IdSelector);
            Expect.isTrue(selector.isCombinatorNone());
            Expect.equals(simpSelector.name, "elemId");
            break;
          case 3:                       // Fourth selector group.
            Expect.equals(selectorGroup.simpleSelectorSequences.length, 2);
            if (idx == 0) {
              Expect.isTrue(simpSelector is ClassSelector);
              Expect.isTrue(selector.isCombinatorNone());
              Expect.equals(simpSelector.name, "xyzzy");
            } else if (idx == 1) {
              Expect.isTrue(simpSelector is ClassSelector);
              Expect.isTrue(selector.isCombinatorDescendant());
              Expect.equals(simpSelector.name, "test");
            } else {
              Expect.fail("unexpected expression");
            }
            break;
          case 4:                       // Fifth selector group.
            Expect.equals(selectorGroup.simpleSelectorSequences.length, 4);
            if (idx == 0) {
              Expect.isTrue(simpSelector is NamespaceSelector);
              Expect.isTrue(selector.isCombinatorNone());
              Expect.equals(simpSelector.namespace, "ns1");
              ElementSelector elementSelector = simpSelector.nameAsSimpleSelector;
              Expect.isTrue(elementSelector is ElementSelector);
              Expect.isFalse(elementSelector.isWildcard());
              Expect.equals(elementSelector.name, "div");
            } else if (idx == 1) {
              Expect.isTrue(simpSelector is ElementSelector);
              Expect.isTrue(selector.isCombinatorDescendant());
              Expect.equals(simpSelector.name, "div");
            } else if (idx == 2) {
              Expect.isTrue(simpSelector is IdSelector);
              Expect.isTrue(selector.isCombinatorDescendant());
              Expect.equals(simpSelector.name, "elemId");
            } else if (idx == 3) {
              Expect.isTrue(simpSelector is ClassSelector);
              Expect.isTrue(selector.isCombinatorDescendant());
              Expect.equals(simpSelector.name, "foobar");
            } else {
              Expect.fail("unexpected expression");
            }
            break;
        }
        idx++;
      }
      groupIdx++;
    }
  }

  static void testCombinator() {
    Parser parser = new Parser(new SourceFile(
        SourceFile.IN_MEMORY_FILE,
        ".foobar > .bar + .no-story ~ myNs|div #elemId {}"));

    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);
    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    RuleSet ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    List<SimpleSelectorSequence> simpleSeqs =
      ruleset.selectorGroup.selectors[0].simpleSelectorSequences;

    Expect.equals(simpleSeqs.length, 5);
    var idx = 0;
    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      if (idx == 0) {
        Expect.isTrue(simpSelector is ClassSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.equals(simpSelector.name, "foobar");
      } else if (idx == 1) {
        Expect.isTrue(simpSelector is ClassSelector);
        Expect.isTrue(selector.isCombinatorGreater());
        Expect.equals(simpSelector.name, "bar");
      } else if (idx == 2) {
        Expect.isTrue(simpSelector is ClassSelector);
        Expect.isTrue(selector.isCombinatorPlus());
        Expect.equals(simpSelector.name, "no-story");
      } else if (idx == 3) {
        Expect.isTrue(simpSelector is NamespaceSelector);
        Expect.isTrue(selector.isCombinatorTilde());
        Expect.equals(simpSelector.namespace, "myNs");
        ElementSelector elementSelector = simpSelector.nameAsSimpleSelector;
        Expect.isTrue(elementSelector is ElementSelector);
        Expect.isFalse(elementSelector.isWildcard());
        Expect.equals(elementSelector.name, "div");
      } else if (idx == 4) {
        Expect.isTrue(simpSelector is IdSelector);
        Expect.isTrue(selector.isCombinatorDescendant());
        Expect.equals(simpSelector.name, "elemId");
      } else {
        Expect.fail("unexpected expression");
      }

      idx++;
    }
  }

  static void testWildcard() {
    Parser parser = new Parser(new SourceFile(
        SourceFile.IN_MEMORY_FILE, "* {}"));

    Stylesheet stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);
    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    RuleSet ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    List<SimpleSelectorSequence> simpleSeqs =
        ruleset.selectorGroup.selectors[0].simpleSelectorSequences;

    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      Expect.isTrue(simpSelector is ElementSelector);
      Expect.isTrue(selector.isCombinatorNone());
      Expect.isTrue(simpSelector.isWildcard());
      Expect.equals(simpSelector.name, "*");
    }

    parser = new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE,
        "*.foobar {}"));

    stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);
    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    simpleSeqs = ruleset.selectorGroup.selectors[0].simpleSelectorSequences;
    
    Expect.equals(simpleSeqs.length, 2);
    var idx = 0;
    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      if (idx == 0) {
        Expect.isTrue(simpSelector is ElementSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.isTrue(simpSelector.isWildcard());
        Expect.equals(simpSelector.name, "*");
      } else if (idx == 1) {
        Expect.isTrue(simpSelector is ClassSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.equals(simpSelector.name, "foobar");
      } else {
        Expect.fail("unexpected expression");
      }

      idx++;
    }

    parser = new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE,
        "myNs|*.foobar {}"));

    stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);
    Expect.equals(stylesheet.topLevels.length, 1);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    simpleSeqs = ruleset.selectorGroup.selectors[0].simpleSelectorSequences;

    Expect.equals(simpleSeqs.length, 2);
    idx = 0;
    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      if (idx == 0) {
        Expect.isTrue(simpSelector is NamespaceSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.isFalse(simpSelector.isNamespaceWildcard());
        ElementSelector elementSelector = simpSelector.nameAsSimpleSelector;
        Expect.equals("myNs", simpSelector.namespace);
        Expect.isTrue(elementSelector.isWildcard());
        Expect.equals("*", elementSelector.name);
      } else if (idx == 1) {
        Expect.isTrue(simpSelector is ClassSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.equals("foobar", simpSelector.name);
      } else {
        Expect.fail("unexpected expression");
      }

      idx++;
    }

    parser = new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE,
        "*|*.foobar {}"));

    stylesheet = parser.parse();
    Expect.isNotNull(stylesheet);

    Expect.isTrue(stylesheet.topLevels[0] is RuleSet);
    ruleset = stylesheet.topLevels[0];
    Expect.equals(ruleset.selectorGroup.selectors.length, 1);
    Expect.equals(ruleset.declarationGroup.declarations.length, 0);

    simpleSeqs = ruleset.selectorGroup.selectors[0].simpleSelectorSequences;
    
    Expect.equals(simpleSeqs.length, 2);
    idx = 0;
    for (final selector in simpleSeqs) {
      final simpSelector = selector.simpleSelector;
      if (idx == 0) {
        Expect.isTrue(simpSelector is NamespaceSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.isTrue(simpSelector.isNamespaceWildcard());
        Expect.equals("*", simpSelector.namespace);
        ElementSelector elementSelector = simpSelector.nameAsSimpleSelector;
        Expect.isTrue(elementSelector.isWildcard());
        Expect.equals("*", elementSelector.name);
      } else if (idx == 1) {
        Expect.isTrue(simpSelector is ClassSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.equals("foobar", simpSelector.name);
      } else {
        Expect.fail("unexpected expression");
      }

      idx++;
    }

  }

  static void testPseudo() {
    // TODO(terry): Implement
  }

  static void testAttribute() {
    // TODO(terry): Implement
  }

  static void testNegation() {
    // TODO(terry): Implement
  }

}


main() {
  ExpressionTest.testMain();
}
