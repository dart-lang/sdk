// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('../../../../frog/lang.dart', prefix:'lang');
#import("../../../css/css.dart");

class SelectorLiteralTest {

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
    Parser parser = new Parser(new lang.SourceFile(
        lang.SourceFile.IN_MEMORY_FILE, ".foobar"));

    List<SelectorGroup> exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    for (selectorGroup in exprTree) {
      Expect.equals(selectorGroup.selectors.length, 1);
      for (selector in selectorGroup.selectors) {
        Expect.isTrue(selector is ClassSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.equals(selector.name, "foobar");
      }
    }

    parser = new Parser(new lang.SourceFile(lang.SourceFile.IN_MEMORY_FILE,
        ".foobar .bar .no-story"));

    exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    for (selectorGroup in exprTree) {
      var idx = 0;
      for (selector in selectorGroup.selectors) {
        if (idx == 0) {
          Expect.isTrue(selector is ClassSelector);
          Expect.isTrue(selector.isCombinatorNone());
          Expect.equals(selector.name, "foobar");
        } else if (idx == 1) {
          Expect.isTrue(selector is ClassSelector);
          Expect.isTrue(selector.isCombinatorDescendant());
          Expect.equals(selector.name, "bar");
        } else if (idx == 2) {
          Expect.isTrue(selector is ClassSelector);
          Expect.isTrue(selector.isCombinatorDescendant());
          Expect.equals(selector.name, "no-story");
        } else {
          Expect.fail("unexpected expression");
        }

        idx++;
      }
    }
  }

  static void testId() {
    Parser parser = new Parser(new lang.SourceFile(
        lang.SourceFile.IN_MEMORY_FILE, "#elemId"));

    List<SelectorGroup> exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    Expect.isNotNull(exprTree);
    for (selectorGroup in exprTree) {
      Expect.equals(selectorGroup.selectors.length, 1);
      for (selector in selectorGroup.selectors) {
        Expect.isTrue(selector is IdSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.equals(selector.name, "elemId");
      }
    }
  }

  static void testElement() {
    Parser parser = new Parser(new lang.SourceFile(
        lang.SourceFile.IN_MEMORY_FILE, "div"));
    List<SelectorGroup> exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    for (selectorGroup in exprTree) {
      Expect.equals(selectorGroup.selectors.length, 1);
      for (selector in selectorGroup.selectors) {
        Expect.isTrue(selector is ElementSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.equals(selector.name, "div");
      }
    }

    parser = new Parser(new lang.SourceFile(lang.SourceFile.IN_MEMORY_FILE,
        "div div span"));
    exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    for (selectorGroup in exprTree) {
      var idx = 0;
      for (selector in selectorGroup.selectors) {
        if (idx == 0) {
          Expect.isTrue(selector is ElementSelector);
          Expect.isTrue(selector.isCombinatorNone());
          Expect.equals(selector.name, "div");
        } else if (idx == 1) {
          Expect.isTrue(selector is ElementSelector);
          Expect.isTrue(selector.isCombinatorDescendant());
          Expect.equals(selector.name, "div");
        } else if (idx == 2) {
          Expect.isTrue(selector is ElementSelector);
          Expect.isTrue(selector.isCombinatorDescendant());
          Expect.equals(selector.name, "span");
        } else {
          Expect.fail("unexpected expression");
        }
  
        idx++;
      }
    }
  }

  static void testNamespace() {
    Parser parser = new Parser(new lang.SourceFile(
        lang.SourceFile.IN_MEMORY_FILE, "ns1|div"));
    List<SelectorGroup> exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    for (selectorGroup in exprTree) {
      Expect.equals(selectorGroup.selectors.length, 1);
      for (selector in selectorGroup.selectors) {
        Expect.isTrue(selector is NamespaceSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.isFalse(selector.isNamespaceWildcard());
        Expect.equals(selector.namespace, "ns1");
        ElementSelector elementSelector = selector.nameAsSimpleSelector;
        Expect.isTrue(elementSelector is ElementSelector);
        Expect.isFalse(elementSelector.isWildcard());
        Expect.equals(elementSelector.name, "div");
      }
    }

    parser = new Parser(new lang.SourceFile(lang.SourceFile.IN_MEMORY_FILE,
        "ns1|div div ns2|span .foobar"));
    exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    for (selectorGroup in exprTree) {
      var idx = 0;
      for (selector in selectorGroup.selectors) {
        if (idx == 0) {
          Expect.isTrue(selector is NamespaceSelector);
          Expect.isTrue(selector.isCombinatorNone());
          Expect.equals(selector.namespace, "ns1");
          ElementSelector elementSelector = selector.nameAsSimpleSelector;
          Expect.isTrue(elementSelector is ElementSelector);
          Expect.isFalse(elementSelector.isWildcard());
          Expect.equals(elementSelector.name, "div");
        } else if (idx == 1) {
          Expect.isTrue(selector is ElementSelector);
          Expect.isTrue(selector.isCombinatorDescendant());
          Expect.equals(selector.name, "div");
        } else if (idx == 2) {
          Expect.isTrue(selector is NamespaceSelector);
          Expect.isTrue(selector.isCombinatorDescendant());
          Expect.equals(selector.namespace, "ns2");
          ElementSelector elementSelector = selector.nameAsSimpleSelector;
          Expect.isTrue(elementSelector is ElementSelector);
          Expect.isFalse(elementSelector.isWildcard());
          Expect.equals(elementSelector.name, "span");
        } else if (idx == 3) {
          Expect.isTrue(selector is ClassSelector);
          Expect.isTrue(selector.isCombinatorDescendant());
          Expect.equals(selector.name, "foobar");
        } else {
          Expect.fail("unexpected expression");
        }
  
        idx++;
      }
    }
  }

  static void testSelectorGroups() {
    Parser parser = new Parser(new lang.SourceFile(
        lang.SourceFile.IN_MEMORY_FILE,
        "div, .foobar ,#elemId, .xyzzy .test, ns1|div div #elemId .foobar"));
    List<SelectorGroup> exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 5);
    var groupIdx = 0;
    for (selectorGroup in exprTree) {
      var idx = 0;
      for (selector in selectorGroup.selectors) {
        switch (groupIdx) {
          case 0:                       // First selector group.
            Expect.equals(selectorGroup.selectors.length, 1);
            Expect.isTrue(selector is ElementSelector);
            Expect.isTrue(selector.isCombinatorNone());
            Expect.equals(selector.name, "div");
            break;
          case 1:                       // Second selector group.
            Expect.equals(selectorGroup.selectors.length, 1);
            Expect.isTrue(selector is ClassSelector);
            Expect.isTrue(selector.isCombinatorNone());
            Expect.equals(selector.name, "foobar");
            break;
          case 2:                       // Third selector group.
            Expect.equals(selectorGroup.selectors.length, 1);
            Expect.isTrue(selector is IdSelector);
            Expect.isTrue(selector.isCombinatorNone());
            Expect.equals(selector.name, "elemId");
            break;
          case 3:                       // Fourth selector group.
            Expect.equals(selectorGroup.selectors.length, 2);
            if (idx == 0) {
              Expect.isTrue(selector is ClassSelector);
              Expect.isTrue(selector.isCombinatorNone());
              Expect.equals(selector.name, "xyzzy");
            } else if (idx == 1) {
              Expect.isTrue(selector is ClassSelector);
              Expect.isTrue(selector.isCombinatorDescendant());
              Expect.equals(selector.name, "test");
            } else {
              Expect.fail("unexpected expression");
            }
            break;
          case 4:                       // Fifth selector group.
            Expect.equals(selectorGroup.selectors.length, 4);
            if (idx == 0) {
              Expect.isTrue(selector is NamespaceSelector);
              Expect.isTrue(selector.isCombinatorNone());
              Expect.equals(selector.namespace, "ns1");
              ElementSelector elementSelector = selector.nameAsSimpleSelector;
              Expect.isTrue(elementSelector is ElementSelector);
              Expect.isFalse(elementSelector.isWildcard());
              Expect.equals(elementSelector.name, "div");
            } else if (idx == 1) {
              Expect.isTrue(selector is ElementSelector);
              Expect.isTrue(selector.isCombinatorDescendant());
              Expect.equals(selector.name, "div");
            } else if (idx == 2) {
              Expect.isTrue(selector is IdSelector);
              Expect.isTrue(selector.isCombinatorDescendant());
              Expect.equals(selector.name, "elemId");
            } else if (idx == 3) {
              Expect.isTrue(selector is ClassSelector);
              Expect.isTrue(selector.isCombinatorDescendant());
              Expect.equals(selector.name, "foobar");
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
    Parser parser = new Parser(new lang.SourceFile(
        lang.SourceFile.IN_MEMORY_FILE,
        ".foobar > .bar + .no-story ~ myNs|div #elemId"));

    List<SelectorGroup> exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    for (selectorGroup in exprTree) {
      var idx = 0;
      Expect.equals(selectorGroup.selectors.length, 5);
      for (selector in selectorGroup.selectors) {
        if (idx == 0) {
          Expect.isTrue(selector is ClassSelector);
          Expect.isTrue(selector.isCombinatorNone());
          Expect.equals(selector.name, "foobar");
        } else if (idx == 1) {
          Expect.isTrue(selector is ClassSelector);
          Expect.isTrue(selector.isCombinatorGreater());
          Expect.equals(selector.name, "bar");
        } else if (idx == 2) {
          Expect.isTrue(selector is ClassSelector);
          Expect.isTrue(selector.isCombinatorPlus());
          Expect.equals(selector.name, "no-story");
        } else if (idx == 3) {
          Expect.isTrue(selector is NamespaceSelector);
          Expect.isTrue(selector.isCombinatorTilde());
          Expect.equals(selector.namespace, "myNs");
          ElementSelector elementSelector = selector.nameAsSimpleSelector;
          Expect.isTrue(elementSelector is ElementSelector);
          Expect.isFalse(elementSelector.isWildcard());
          Expect.equals(elementSelector.name, "div");
        } else if (idx == 4) {
          Expect.isTrue(selector is IdSelector);
          Expect.isTrue(selector.isCombinatorDescendant());
          Expect.equals(selector.name, "elemId");
        } else {
          Expect.fail("unexpected expression");
        }

        idx++;
      }
    }
  }

  static void testWildcard() {
    Parser parser = new Parser(new lang.SourceFile(
        lang.SourceFile.IN_MEMORY_FILE, "*"));

    List<SelectorGroup> exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    for (selectorGroup in exprTree) {
      Expect.equals(selectorGroup.selectors.length, 1);
      for (selector in selectorGroup.selectors) {
        Expect.isTrue(selector is ElementSelector);
        Expect.isTrue(selector.isCombinatorNone());
        Expect.isTrue(selector.isWildcard());
        Expect.equals(selector.name, "*");
      }
    }

    parser = new Parser(new lang.SourceFile(lang.SourceFile.IN_MEMORY_FILE,
        "*.foobar"));

    exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    for (selectorGroup in exprTree) {
      var idx = 0;
      for (selector in selectorGroup.selectors) {
        Expect.equals(selectorGroup.selectors.length, 2);
        if (idx == 0) {
          Expect.isTrue(selector is ElementSelector);
          Expect.isTrue(selector.isCombinatorNone());
          Expect.isTrue(selector.isWildcard());
          Expect.equals(selector.name, "*");
        } else if (idx == 1) {
          Expect.isTrue(selector is ClassSelector);
          Expect.isTrue(selector.isCombinatorNone());
          Expect.equals(selector.name, "foobar");
        } else {
          Expect.fail("unexpected expression");
        }

        idx++;
      }
    }

    parser = new Parser(new lang.SourceFile(lang.SourceFile.IN_MEMORY_FILE,
        "myNs|*.foobar"));

    exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    for (selectorGroup in exprTree) {
      var idx = 0;
      for (selector in selectorGroup.selectors) {
        Expect.equals(selectorGroup.selectors.length, 2);
        if (idx == 0) {
          Expect.isTrue(selector is NamespaceSelector);
          Expect.isTrue(selector.isCombinatorNone());
          Expect.isFalse(selector.isNamespaceWildcard());
          ElementSelector elementSelector = selector.nameAsSimpleSelector;
          Expect.equals("myNs", selector.namespace);
          Expect.isTrue(elementSelector.isWildcard());
          Expect.equals("*", elementSelector.name);
        } else if (idx == 1) {
          Expect.isTrue(selector is ClassSelector);
          Expect.isTrue(selector.isCombinatorNone());
          Expect.equals("foobar", selector.name);
        } else {
          Expect.fail("unexpected expression");
        }

        idx++;
      }
    }

    parser = new Parser(new lang.SourceFile(lang.SourceFile.IN_MEMORY_FILE,
        "*|*.foobar"));

    exprTree = parser.preprocess();
    Expect.isNotNull(exprTree);
    Expect.equals(exprTree.length, 1);
    for (selectorGroup in exprTree) {
      var idx = 0;
      for (selector in selectorGroup.selectors) {
        Expect.equals(selectorGroup.selectors.length, 2);
        if (idx == 0) {
          Expect.isTrue(selector is NamespaceSelector);
          Expect.isTrue(selector.isCombinatorNone());
          Expect.isTrue(selector.isNamespaceWildcard());
          Expect.equals("*", selector.namespace);
          ElementSelector elementSelector = selector.nameAsSimpleSelector;
          Expect.isTrue(elementSelector.isWildcard());
          Expect.equals("*", elementSelector.name);
        } else if (idx == 1) {
          Expect.isTrue(selector is ClassSelector);
          Expect.isTrue(selector.isCombinatorNone());
          Expect.equals("foobar", selector.name);
        } else {
          Expect.fail("unexpected expression");
        }

        idx++;
      }
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
  SelectorLiteralTest.testMain();
}
