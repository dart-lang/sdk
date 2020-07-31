// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:kernel/ast.dart';
import 'text_representation_test.dart';

testExpression(Expression node, String normal,
    {String verbose, String limited}) {
  Expect.stringEquals(normal, node.toText(normalStrategy),
      "Unexpected normal strategy text for ${node.runtimeType}");
  Expect.stringEquals(verbose ?? normal, node.toText(verboseStrategy),
      "Unexpected verbose strategy text for ${node.runtimeType}");
  Expect.stringEquals(limited ?? normal, node.toText(limitedStrategy),
      "Unexpected limited strategy text for ${node.runtimeType}");
}

testType(DartType node, String normal, {String verbose, String limited}) {
  Expect.stringEquals(normal, node.toText(normalStrategy),
      "Unexpected normal strategy text for ${node.runtimeType}");
  Expect.stringEquals(verbose ?? normal, node.toText(verboseStrategy),
      "Unexpected verbose strategy text for ${node.runtimeType}");
  Expect.stringEquals(limited ?? normal, node.toText(limitedStrategy),
      "Unexpected limited strategy text for ${node.runtimeType}");
}

main() {
  testTypes();
  testMembers();
}

void testTypes() {
  testType(new InterfaceType.byReference(null, Nullability.nonNullable, []),
      '<missing-class-reference>');
  testType(new TypedefType.byReference(null, Nullability.nonNullable, []),
      '<missing-typedef-reference>');

  Reference unlinkedClassName = new Reference();
  testType(
      new InterfaceType.byReference(
          unlinkedClassName, Nullability.nonNullable, []),
      '<unlinked-class-reference>');
  testType(
      new TypedefType.byReference(
          unlinkedClassName, Nullability.nonNullable, []),
      '<unlinked-typedef-reference>');

  CanonicalName root = new CanonicalName.root();
  Reference rootReference = new Reference()..canonicalName = root;
  testType(
      new InterfaceType.byReference(rootReference, Nullability.nonNullable, []),
      '<root>');
  testType(
      new TypedefType.byReference(rootReference, Nullability.nonNullable, []),
      '<root>');

  CanonicalName library = root.getChild('library');
  Reference libraryReference = new Reference()..canonicalName = library;
  testType(
      new InterfaceType.byReference(
          libraryReference, Nullability.nonNullable, []),
      'library');
  testType(
      new TypedefType.byReference(
          libraryReference, Nullability.nonNullable, []),
      'library');

  CanonicalName className = library.getChild('Class');
  Reference classNameReference = new Reference()..canonicalName = className;
  testType(
      new InterfaceType.byReference(
          classNameReference, Nullability.nonNullable, []),
      'Class',
      verbose: 'library::Class');
  testType(
      new TypedefType.byReference(
          classNameReference, Nullability.nonNullable, []),
      'Class',
      verbose: 'library::Class');
}

void testMembers() {
  testExpression(new PropertyGet(new IntLiteral(0), new Name('foo')), '''
0.foo''');
  testExpression(new StaticGet(null), '''
<missing-member-reference>''');

  Reference unlinkedMemberName = new Reference();
  testExpression(
      new PropertyGet.byReference(
          new IntLiteral(0), new Name('foo'), unlinkedMemberName),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(unlinkedMemberName), '''
<unlinked-member-reference>''');

  CanonicalName root = new CanonicalName.root();
  Reference rootReference = new Reference()..canonicalName = root;
  testExpression(
      new PropertyGet.byReference(
          new IntLiteral(0), new Name('foo'), rootReference),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(rootReference), '''
<root>''');

  CanonicalName library = root.getChild('library');
  Reference libraryReference = new Reference()..canonicalName = library;
  testExpression(
      new PropertyGet.byReference(
          new IntLiteral(0), new Name('foo'), libraryReference),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(libraryReference), '''
library''');

  CanonicalName topLevelMemberName = library.getChild('member');
  Reference topLevelMemberNameReference = new Reference()
    ..canonicalName = topLevelMemberName;
  testExpression(
      new PropertyGet.byReference(
          new IntLiteral(0), new Name('foo'), topLevelMemberNameReference),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(topLevelMemberNameReference), '''
member''', verbose: '''
library::member''');

  CanonicalName className = library.getChild('Class');
  Reference classNameReference = new Reference()..canonicalName = className;
  testExpression(
      new PropertyGet.byReference(
          new IntLiteral(0), new Name('foo'), classNameReference),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(classNameReference), '''
Class''', verbose: '''
library::Class''');

  CanonicalName classMemberName = className.getChild('member');
  Reference classMemberNameReference = new Reference()
    ..canonicalName = classMemberName;
  testExpression(
      new PropertyGet.byReference(
          new IntLiteral(0), new Name('foo'), classMemberNameReference),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(classMemberNameReference), '''
Class.member''', verbose: '''
library::Class.member''');
}
