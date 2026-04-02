// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/transformations/track_widget_constructor_locations.dart';

void main() {
  final Uri developerUri = Uri.parse('dart:developer');
  final Library developerLib = new Library(developerUri, fileUri: developerUri);

  final Class hasCreationLocationClass = new Class(
    name: '_HasCreationLocation',
    isAbstract: true,
    fileUri: developerUri,
  );
  developerLib.addClass(hasCreationLocationClass);

  final Class creationLocationClass = new Class(
    name: 'CreationLocation',
    fileUri: developerUri,
  );
  final Constructor creationLocationConstructor = new Constructor(
    new FunctionNode(
      null,
      namedParameters: [
        new VariableDeclaration('file', type: const DynamicType()),
        new VariableDeclaration('line', type: const DynamicType()),
        new VariableDeclaration('column', type: const DynamicType()),
        new VariableDeclaration('name', type: const DynamicType()),
      ],
    ),
    name: new Name(''),
    fileUri: developerUri,
  );
  creationLocationClass.addConstructor(creationLocationConstructor);
  developerLib.addClass(creationLocationClass);

  final Class trackCreationLocationsAnnotationClass = new Class(
    name: '_TrackCreationLocations',
    fileUri: developerUri,
  );
  trackCreationLocationsAnnotationClass.addConstructor(
    new Constructor(
      new FunctionNode(null),
      name: new Name(''),
      fileUri: developerUri,
    ),
  );
  developerLib.addClass(trackCreationLocationsAnnotationClass);

  final Field trackCreationLocationsField = new Field.immutable(
    new Name('trackCreationLocations'),
    type: new InterfaceType(
      trackCreationLocationsAnnotationClass,
      Nullability.nonNullable,
    ),
    initializer: new ConstructorInvocation(
      trackCreationLocationsAnnotationClass.constructors.first,
      new Arguments([]),
    ),
    isStatic: true,
    fileUri: developerUri,
  );
  developerLib.addField(trackCreationLocationsField);

  final Uri testUri = Uri.parse('package:test/test.dart');
  final Library testLib = new Library(testUri, fileUri: testUri);

  final Class myWidgetClass = new Class(name: 'MyWidget', fileUri: testUri);
  myWidgetClass.addAnnotation(new StaticGet(trackCreationLocationsField));
  myWidgetClass.addConstructor(
    new Constructor(
      new FunctionNode(new Block([])),
      name: new Name(''),
      fileUri: testUri,
    ),
  );
  testLib.addClass(myWidgetClass);

  final int fileOffset = 100;
  final Procedure mainProcedure = new Procedure(
    new Name('main'),
    ProcedureKind.Method,
    new FunctionNode(
      new Block([
        new ExpressionStatement(
          new ConstructorInvocation(
            myWidgetClass.constructors.first,
            new Arguments([]),
          )..fileOffset = fileOffset,
        ),
      ]),
    ),
    isStatic: true,
    fileUri: testUri,
  );
  testLib.addProcedure(mainProcedure);

  final WidgetCreatorTracker tracker = new WidgetCreatorTracker();
  tracker.transform([testLib], [developerLib, testLib], null);

  // Verification
  Expect.isTrue(
    myWidgetClass.implementedTypes.any(
      (s) => s.classNode == hasCreationLocationClass,
    ),
  );
  Expect.isTrue(myWidgetClass.fields.any((f) => f.name.text == '_location'));

  final Constructor constructor = myWidgetClass.constructors.first;
  const String creationLocationPrefix = r'$creationLocation';
  Expect.isTrue(
    constructor.function.namedParameters.any(
      (p) => p.name!.startsWith(creationLocationPrefix),
    ),
  );

  final Block body = mainProcedure.function.body as Block;
  final ExpressionStatement stmt = body.statements.first as ExpressionStatement;
  final ConstructorInvocation invocation =
      stmt.expression as ConstructorInvocation;
  Expect.isTrue(
    invocation.arguments.named.any(
      (n) => n.name.startsWith(creationLocationPrefix),
    ),
  );

  final NamedExpression namedArg = invocation.arguments.named.firstWhere(
    (n) => n.name.startsWith(creationLocationPrefix),
  );
  Expect.isTrue(namedArg.value is ConstructorInvocation);
  final ConstructorInvocation locInvocation =
      namedArg.value as ConstructorInvocation;
  Expect.equals(creationLocationClass, locInvocation.target.enclosingClass);
}
