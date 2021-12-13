// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:kernel/ast.dart';
import 'text_representation_test.dart';

void testExpression(Expression node, String normal,
    {String? verbose, String? limited}) {
  Expect.stringEquals(normal, node.toText(normalStrategy),
      "Unexpected normal strategy text for ${node.runtimeType}");
  Expect.stringEquals(verbose ?? normal, node.toText(verboseStrategy),
      "Unexpected verbose strategy text for ${node.runtimeType}");
  Expect.stringEquals(limited ?? normal, node.toText(limitedStrategy),
      "Unexpected limited strategy text for ${node.runtimeType}");
}

void testType(DartType node, String normal,
    {String? verbose, String? limited}) {
  Expect.stringEquals(normal, node.toText(normalStrategy),
      "Unexpected normal strategy text for ${node.runtimeType}");
  Expect.stringEquals(verbose ?? normal, node.toText(verboseStrategy),
      "Unexpected verbose strategy text for ${node.runtimeType}");
  Expect.stringEquals(limited ?? normal, node.toText(limitedStrategy),
      "Unexpected limited strategy text for ${node.runtimeType}");
}

void main() {
  testTypes();
  testMembers();
}

void testTypes() {
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
  Reference unlinkedMemberName = new Reference();
  testExpression(
      new InstanceGet.byReference(
          InstanceAccessKind.Instance, new IntLiteral(0), new Name('foo'),
          interfaceTargetReference: unlinkedMemberName,
          resultType: const DynamicType()),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(unlinkedMemberName), '''
<unlinked-member-reference>''');

  CanonicalName root = new CanonicalName.root();
  Reference rootReference = new Reference()..canonicalName = root;
  testExpression(
      new InstanceGet.byReference(
          InstanceAccessKind.Instance, new IntLiteral(0), new Name('foo'),
          interfaceTargetReference: rootReference,
          resultType: const DynamicType()),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(rootReference), '''
<root>''');

  CanonicalName library = root.getChild('library');
  Reference libraryReference = new Reference()..canonicalName = library;
  testExpression(
      new InstanceGet.byReference(
          InstanceAccessKind.Instance, new IntLiteral(0), new Name('foo'),
          interfaceTargetReference: libraryReference,
          resultType: const DynamicType()),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(libraryReference), '''
library''');

  CanonicalName topLevelMemberName = library.getChild('member');
  Reference topLevelMemberNameReference = new Reference()
    ..canonicalName = topLevelMemberName;
  testExpression(
      new InstanceGet.byReference(
          InstanceAccessKind.Instance, new IntLiteral(0), new Name('foo'),
          interfaceTargetReference: topLevelMemberNameReference,
          resultType: const DynamicType()),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(topLevelMemberNameReference), '''
member''', verbose: '''
library::member''');

  CanonicalName className = library.getChild('Class');
  Reference classNameReference = new Reference()..canonicalName = className;
  testExpression(
      new InstanceGet.byReference(
          InstanceAccessKind.Instance, new IntLiteral(0), new Name('foo'),
          interfaceTargetReference: classNameReference,
          resultType: const DynamicType()),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(classNameReference), '''
Class''', verbose: '''
library::Class''');

  CanonicalName classMemberName = className.getChild('member');
  Reference classMemberNameReference = new Reference()
    ..canonicalName = classMemberName;
  testExpression(
      new InstanceGet.byReference(
          InstanceAccessKind.Instance, new IntLiteral(0), new Name('foo'),
          interfaceTargetReference: classMemberNameReference,
          resultType: const DynamicType()),
      '''
0.foo''');
  testExpression(new StaticGet.byReference(classMemberNameReference), '''
Class.member''', verbose: '''
library::Class.member''');
}
