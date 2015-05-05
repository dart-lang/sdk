// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.incremental_element_builder_test;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/incremental_element_builder.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../context/abstract_context.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(IncrementalCompilationUnitElementBuilderTest);
}

@reflectiveTest
class IncrementalCompilationUnitElementBuilderTest extends AbstractContextTest {
  Source source;
  String oldCode;
  CompilationUnit oldUnit;

  String newCode;
  CompilationUnit newUnit;

  String getNodeText(AstNode node) {
    return newCode.substring(node.offset, node.end);
  }

  test_directives_add() {
    _buildOldUnit(r'''
library test;
import 'dart:math';
''');
    _buildNewUnit(r'''
library test;
import 'dart:async';
import 'dart:math';
''');
    var oldDirectives = oldUnit.directives;
    var newDirectives = newUnit.directives;
    {
      Directive newNode = newDirectives[0];
      expect(newNode, same(oldDirectives[0]));
      expect(getNodeText(newNode), "library test;");
      LibraryElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf('test;'));
    }
    {
      Directive newNode = newDirectives[1];
      expect(getNodeText(newNode), "import 'dart:async';");
      ImportElement element = newNode.element;
      expect(element, isNull);
    }
    {
      Directive newNode = newDirectives[2];
      expect(newNode, same(oldDirectives[1]));
      expect(getNodeText(newNode), "import 'dart:math';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:math';"));
    }
  }

  test_directives_remove() {
    _buildOldUnit(r'''
library test;
import 'dart:async';
import 'dart:math';
''');
    _buildNewUnit(r'''
library test;
import 'dart:math';
''');
    var oldDirectives = oldUnit.directives;
    var newDirectives = newUnit.directives;
    {
      Directive newNode = newDirectives[0];
      expect(newNode, same(oldDirectives[0]));
      expect(getNodeText(newNode), "library test;");
      LibraryElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf('test;'));
    }
    {
      Directive newNode = newDirectives[1];
      expect(newNode, same(oldDirectives[2]));
      expect(getNodeText(newNode), "import 'dart:math';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:math';"));
    }
  }

  test_directives_reorder() {
    _buildOldUnit(r'''
library test;
import  'dart:math' as m;
import 'dart:async';
''');
    _buildNewUnit(r'''
library test;
import 'dart:async';
import 'dart:math' as m;
''');
    var oldDirectives = oldUnit.directives;
    var newDirectives = newUnit.directives;
    {
      Directive newNode = newDirectives[0];
      expect(newNode, same(oldDirectives[0]));
      expect(getNodeText(newNode), "library test;");
      LibraryElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf('test;'));
    }
    {
      Directive newNode = newDirectives[1];
      expect(newNode, same(oldDirectives[2]));
      expect(getNodeText(newNode), "import 'dart:async';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:async';"));
    }
    {
      Directive newNode = newDirectives[2];
      expect(newNode, same(oldDirectives[1]));
      expect(getNodeText(newNode), "import 'dart:math' as m;");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:math' as m;"));
      expect(element.prefix.nameOffset, newCode.indexOf("m;"));
    }
  }

  test_directives_sameOrder_insertSpaces() {
    _buildOldUnit(r'''
library test;
import 'dart:async';
import 'dart:math';
''');
    _buildNewUnit(r'''
library test;

import 'dart:async' ;
import  'dart:math';
''');
    var oldDirectives = oldUnit.directives;
    var newDirectives = newUnit.directives;
    {
      Directive newNode = newDirectives[0];
      expect(newNode, same(oldDirectives[0]));
      expect(getNodeText(newNode), "library test;");
      LibraryElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf('test;'));
    }
    {
      Directive newNode = newDirectives[1];
      expect(newNode, same(oldDirectives[1]));
      expect(getNodeText(newNode), "import 'dart:async' ;");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:async' ;"));
    }
    {
      Directive newNode = newDirectives[2];
      expect(newNode, same(oldDirectives[2]));
      expect(getNodeText(newNode), "import  'dart:math';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import  'dart:math';"));
    }
  }

  test_directives_sameOrder_removeSpaces() {
    _buildOldUnit(r'''
library test;

import 'dart:async' ;
import  'dart:math';
''');
    _buildNewUnit(r'''
library test;
import 'dart:async';
import 'dart:math';
''');
    var oldDirectives = oldUnit.directives;
    var newDirectives = newUnit.directives;
    {
      Directive newNode = newDirectives[0];
      expect(newNode, same(oldDirectives[0]));
      expect(getNodeText(newNode), "library test;");
      LibraryElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf('test;'));
    }
    {
      Directive newNode = newDirectives[1];
      expect(newNode, same(oldDirectives[1]));
      expect(getNodeText(newNode), "import 'dart:async';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:async';"));
    }
    {
      Directive newNode = newDirectives[2];
      expect(newNode, same(oldDirectives[2]));
      expect(getNodeText(newNode), "import 'dart:math';");
      ImportElement element = newNode.element;
      expect(element, isNotNull);
      expect(element.nameOffset, newCode.indexOf("import 'dart:math';"));
    }
  }

  void _buildNewUnit(String newCode) {
    this.newCode = newCode;
    context.setContents(source, newCode);
    newUnit = context.parseCompilationUnit(source);
    new IncrementalCompilationUnitElementBuilder(oldUnit, newUnit).build();
  }

  void _buildOldUnit(String oldCode) {
    this.oldCode = oldCode;
    source = newSource('/test.dart', oldCode);
    oldUnit = context.resolveCompilationUnit2(source, source);
  }
}
