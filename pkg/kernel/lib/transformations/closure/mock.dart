// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure.mock;

import '../../ast.dart'
    show
        Arguments,
        Block,
        Class,
        Constructor,
        ConstructorInvocation,
        DartType,
        DynamicType,
        EmptyStatement,
        Expression,
        ExpressionStatement,
        Field,
        FieldInitializer,
        FunctionNode,
        Initializer,
        IntLiteral,
        Library,
        MethodInvocation,
        Name,
        NullLiteral,
        Procedure,
        ProcedureKind,
        Program,
        PropertyGet,
        ReturnStatement,
        Source,
        Statement,
        StaticInvocation,
        Supertype,
        TreeNode,
        VariableDeclaration,
        VariableGet;

import '../../core_types.dart' show CoreTypes;

import '../../frontend/accessors.dart'
    show
        Accessor,
        IndexAccessor,
        PropertyAccessor,
        ThisPropertyAccessor,
        VariableAccessor;

/// TODO(dmitryas): make the "[]=" operator return the value.
/// Extend the program with this mock:
///
///     class Context {
///       final List list;
///       var parent;
///       Context(int i) : list = new List(i);
///       operator[] (int i) => list[i];
///       operator[]= (int i, value) {
///         list[i] = value;
///       }
///       Context copy() {
///         Context c = new Context(list.length);
///         c.parent = parent;
///         c.list.setRange(0, list.length, list);
///         return c;
///       }
///     }
///
/// Returns the mock.
Class mockUpContext(CoreTypes coreTypes, Program program) {
  String fileUri = "dart:mock";

  ///     final List list;
  Field listField = new Field(new Name("list"),
      type: coreTypes.listClass.rawType, isFinal: true, fileUri: fileUri);
  Accessor listFieldAccessor = new ThisPropertyAccessor(
      listField.name, listField, null, TreeNode.noOffset);

  ///     var parent;
  Field parentField = new Field(new Name("parent"), fileUri: fileUri);
  Accessor parentFieldAccessor = new ThisPropertyAccessor(
      parentField.name, parentField, parentField, TreeNode.noOffset);

  List<Field> fields = <Field>[listField, parentField];

  ///     Context(int i) : list = new List(i);
  VariableDeclaration iParameter = new VariableDeclaration("i",
      type: coreTypes.intClass.rawType, isFinal: true);

  // TODO(karlklose): use the default factory when it is exposed again.
  Procedure listConstructor = coreTypes.listClass.procedures
      .firstWhere((Procedure p) => p.name.name == 'filled');

  Constructor constructor = new Constructor(
      new FunctionNode(new EmptyStatement(),
          positionalParameters: <VariableDeclaration>[iParameter]),
      name: new Name(""),
      initializers: <Initializer>[
        new FieldInitializer(
            listField,
            new StaticInvocation(
                listConstructor,
                new Arguments(<Expression>[
                  new VariableAccessor(iParameter, null, TreeNode.noOffset)
                      .buildSimpleRead(),
                  new NullLiteral(),
                ], types: <DartType>[
                  const DynamicType()
                ])))
      ]);

  ///     operator[] (int i) => list[i];
  iParameter = new VariableDeclaration("i",
      type: coreTypes.intClass.rawType, isFinal: true);
  Accessor accessor = IndexAccessor.make(
      listFieldAccessor.buildSimpleRead(),
      new VariableAccessor(iParameter, null, TreeNode.noOffset)
          .buildSimpleRead(),
      null,
      null);
  Procedure indexGet = new Procedure(
      new Name("[]"),
      ProcedureKind.Operator,
      new FunctionNode(new ReturnStatement(accessor.buildSimpleRead()),
          positionalParameters: <VariableDeclaration>[iParameter]),
      fileUri: fileUri);

  ///     operator[]= (int i, value) {
  ///       list[i] = value;
  ///     }
  iParameter = new VariableDeclaration("i",
      type: coreTypes.intClass.rawType, isFinal: true);
  VariableDeclaration valueParameter =
      new VariableDeclaration("value", isFinal: true);
  accessor = IndexAccessor.make(
      listFieldAccessor.buildSimpleRead(),
      new VariableAccessor(iParameter, null, TreeNode.noOffset)
          .buildSimpleRead(),
      null,
      null);
  Expression expression = accessor.buildAssignment(
      new VariableAccessor(valueParameter, null, TreeNode.noOffset)
          .buildSimpleRead(),
      voidContext: true);
  Procedure indexSet = new Procedure(
      new Name("[]="),
      ProcedureKind.Operator,
      new FunctionNode(new ExpressionStatement(expression),
          positionalParameters: <VariableDeclaration>[
            iParameter,
            valueParameter
          ]),
      fileUri: fileUri);

  ///       Context copy() {
  ///         Context c = new Context(list.length);
  ///         c.parent = parent;
  ///         c.list.setRange(0, list.length, list);
  ///         return c;
  ///       }
  VariableDeclaration c = new VariableDeclaration("c",
      initializer: new ConstructorInvocation(
          constructor,
          new Arguments(<Expression>[
            new PropertyGet(
                listFieldAccessor.buildSimpleRead(), new Name("length"))
          ])));
  Accessor accessCParent = PropertyAccessor.make(
      new VariableGet(c), parentField.name, parentField, parentField);
  Accessor accessCList = PropertyAccessor.make(
      new VariableGet(c), listField.name, listField, null);
  List<Statement> statements = <Statement>[
    c,
    new ExpressionStatement(accessCParent.buildAssignment(
        parentFieldAccessor.buildSimpleRead(),
        voidContext: true)),
    new ExpressionStatement(new MethodInvocation(
        accessCList.buildSimpleRead(),
        new Name("setRange"),
        new Arguments(<Expression>[
          new IntLiteral(0),
          new PropertyGet(
              listFieldAccessor.buildSimpleRead(), new Name("length")),
          listFieldAccessor.buildSimpleRead()
        ]))),
    new ReturnStatement(new VariableGet(c))
  ];
  Procedure copy = new Procedure(new Name("copy"), ProcedureKind.Method,
      new FunctionNode(new Block(statements)),
      fileUri: fileUri);

  List<Procedure> procedures = <Procedure>[indexGet, indexSet, copy];

  Class contextClass = new Class(
      name: "Context",
      supertype: new Supertype(coreTypes.objectClass, const <DartType>[]),
      constructors: [constructor],
      fields: fields,
      procedures: procedures,
      fileUri: fileUri);
  Library mock =
      new Library(Uri.parse(fileUri), name: "mock", classes: [contextClass])
        ..fileUri = fileUri;
  program.libraries.add(mock);
  mock.parent = program;
  program.uriToSource[mock.fileUri] = new Source(<int>[0], const <int>[]);
  return contextClass;
}
