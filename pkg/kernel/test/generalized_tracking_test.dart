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
        new NamedParameter(parameterName: 'file'),
        new NamedParameter(parameterName: 'line'),
        new NamedParameter(parameterName: 'column'),
        new NamedParameter(parameterName: 'name'),
      ],
    ),
    name: new Name('_', developerLib),
    fileUri: developerUri,
  );
  creationLocationClass.addConstructor(creationLocationConstructor);
  developerLib.addClass(creationLocationClass);

  final Uri coreUri = Uri.parse('dart:core');
  final Library coreLib = new Library(coreUri, fileUri: coreUri);
  final Class pragmaClass = new Class(name: 'pragma', fileUri: coreUri);
  coreLib.addClass(pragmaClass);
  final Field pragmaNameField = new Field.immutable(
    new Name('name'),
    fileUri: coreUri,
  );
  pragmaClass.addField(pragmaNameField);

  final Uri testUri = Uri.parse('package:test/test.dart');
  final Library testLib = new Library(testUri, fileUri: testUri);

  final Class myWidgetClass = new Class(name: 'MyWidget', fileUri: testUri);
  myWidgetClass.addAnnotation(
    new ConstantExpression(
      new InstanceConstant(
        pragmaClass.reference,
        <DartType>[],
        <Reference, Constant>{
          pragmaNameField.fieldReference: new StringConstant(
            'track-creation-locations',
          ),
        },
      ),
    ),
  );
  myWidgetClass.addConstructor(
    new Constructor(
      new FunctionNode(new Block([])),
      name: new Name(''),
      fileUri: testUri,
    ),
  );
  testLib.addClass(myWidgetClass);

  const int fileOffset = 100;
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

  final Extension extension =
      new Extension(name: 'MyExtension', fileUri: testUri)
        ..fileOffset = fileOffset
        ..onType = const DynamicType();
  testLib.addExtension(extension);

  final Procedure factoryMethod =
      new Procedure(
          new Name('myFactory'),
          ProcedureKind.Method,
          new FunctionNode(
            new Block([
              new ReturnStatement(
                new ConstructorInvocation(
                  myWidgetClass.constructors.first,
                  new Arguments([]),
                )..fileOffset = fileOffset,
              ),
            ]),
            returnType: new InterfaceType(
              myWidgetClass,
              Nullability.nonNullable,
            ),
          ),
          isStatic: true,
          fileUri: testUri,
        )
        ..fileOffset = fileOffset
        ..isExtensionMember = true;
  factoryMethod.addAnnotation(
    new ConstantExpression(
      new InstanceConstant(
        pragmaClass.reference,
        <DartType>[],
        <Reference, Constant>{
          pragmaNameField.fieldReference: new StringConstant(
            'track-creation-locations',
          ),
        },
      ),
    ),
  );
  testLib.addProcedure(factoryMethod);

  extension.memberDescriptors.add(
    new ExtensionMemberDescriptor(
      name: new Name('myFactory'),
      kind: ExtensionMemberKind.Method,
      memberReference: factoryMethod.reference,
      tearOffReference: null,
    ),
  );

  final Block newBody = new Block([
    new ExpressionStatement(
      new ConstructorInvocation(
        myWidgetClass.constructors.first,
        new Arguments([]),
      )..fileOffset = fileOffset,
    ),
    new ExpressionStatement(
      new StaticInvocation(factoryMethod, new Arguments([]))
        ..fileOffset = fileOffset,
    ),
  ]);
  newBody.parent = mainProcedure.function;
  mainProcedure.function.body = newBody;

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
      (p) => p.parameterName.startsWith(creationLocationPrefix),
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

  Expect.isTrue(
    factoryMethod.function.namedParameters.any(
      (p) => p.parameterName.startsWith(creationLocationPrefix),
    ),
  );

  final ExpressionStatement stmt2 = body.statements[1] as ExpressionStatement;
  final StaticInvocation staticInv = stmt2.expression as StaticInvocation;
  Expect.isTrue(
    staticInv.arguments.named.any(
      (n) => n.name.startsWith(creationLocationPrefix),
    ),
  );
  final NamedExpression namedArg2 = staticInv.arguments.named.firstWhere(
    (n) => n.name.startsWith(creationLocationPrefix),
  );
  Expect.isTrue(namedArg2.value is ConstructorInvocation);
  final ConstructorInvocation locInvocation2 =
      namedArg2.value as ConstructorInvocation;
  Expect.equals(creationLocationClass, locInvocation2.target.enclosingClass);
}
