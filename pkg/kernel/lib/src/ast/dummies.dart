// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

/// Almost const <NamedExpression>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<NamedExpression> emptyListOfNamedExpression =
    List.filled(0, dummyNamedExpression, growable: false);

/// Almost const <VariableDeclaration>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<VariableDeclaration> emptyListOfVariableDeclaration =
    List.filled(0, dummyVariableDeclaration, growable: false);

/// Almost const <Combinator>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Combinator> emptyListOfCombinator =
    List.filled(0, dummyCombinator, growable: false);

/// Almost const <Expression>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Expression> emptyListOfExpression =
    List.filled(0, dummyExpression, growable: false);

/// Almost const <AssertStatement>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<AssertStatement> emptyListOfAssertStatement =
    List.filled(0, dummyAssertStatement, growable: false);

/// Almost const <SwitchCase>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<SwitchCase> emptyListOfSwitchCase =
    List.filled(0, dummySwitchCase, growable: false);

/// Almost const <SwitchExpressionCase>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<SwitchExpressionCase> emptyListOfSwitchExpressionCase =
    List.filled(0, dummySwitchExpressionCase, growable: false);

/// Almost const <PatternSwitchCase>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<PatternSwitchCase> emptyListOfPatternSwitchCase =
    List.filled(0, dummyPatternSwitchCase, growable: false);

/// Almost const <Catch>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Catch> emptyListOfCatch =
    List.filled(0, dummyCatch, growable: false);

/// Almost const <Supertype>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Supertype> emptyListOfSupertype =
    List.filled(0, dummySupertype, growable: false);

/// Almost const <DartType>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<DartType> emptyListOfDartType =
    List.filled(0, dummyDartType, growable: false);

/// Almost const <NamedType>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<NamedType> emptyListOfNamedType =
    List.filled(0, dummyNamedType, growable: false);

/// Almost const <TypeParameter>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<TypeParameter> emptyListOfTypeParameter =
    List.filled(0, dummyTypeParameter, growable: false);

/// Almost const <StructuralParameter>[], but not const in an attempt to
/// avoid polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<StructuralParameter> emptyListOfStructuralParameter =
    List.filled(0, dummyStructuralParameter, growable: false);

/// Almost const <Constant>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Constant> emptyListOfConstant =
    List.filled(0, dummyConstant, growable: false);

/// Almost const <String>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<String> emptyListOfString = List.filled(0, '', growable: false);

/// Almost const <Typedef>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Typedef> emptyListOfTypedef =
    List.filled(0, dummyTypedef, growable: false);

/// Almost const <Extension>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Extension> emptyListOfExtension =
    List.filled(0, dummyExtension, growable: false);

/// Almost const <ExtensionTypeDeclaration>[], but not const in an attempt to
/// avoid polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<ExtensionTypeDeclaration> emptyListOfExtensionTypeDeclaration =
    List.filled(0, dummyExtensionTypeDeclaration, growable: false);

/// Almost const <Field>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Field> emptyListOfField =
    List.filled(0, dummyField, growable: false);

/// Almost const <LibraryPart>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<LibraryPart> emptyListOfLibraryPart =
    List.filled(0, dummyLibraryPart, growable: false);

/// Almost const <LibraryDependency>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<LibraryDependency> emptyListOfLibraryDependency =
    List.filled(0, dummyLibraryDependency, growable: false);

/// Almost const <Procedure>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Procedure> emptyListOfProcedure =
    List.filled(0, dummyProcedure, growable: false);

/// Almost const <MapLiteralEntry>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<MapLiteralEntry> emptyListOfMapLiteralEntry =
    List.filled(0, dummyMapLiteralEntry, growable: false);

/// Almost const <Class>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Class> emptyListOfClass =
    List.filled(0, dummyClass, growable: false);

/// Almost const <ExtensionMemberDescriptor>[], but not const in an attempt to
/// avoid polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<ExtensionMemberDescriptor> emptyListOfExtensionMemberDescriptor =
    List.filled(0, dummyExtensionMemberDescriptor, growable: false);

/// Almost const <ExtensionTypeMemberDescriptor>[], but not const in an attempt
/// to avoid polymorphism. See
/// https://dart-review.googlesource.com/c/sdk/+/185828.
final List<ExtensionTypeMemberDescriptor>
    emptyListOfExtensionTypeMemberDescriptor =
    List.filled(0, dummyExtensionTypeMemberDescriptor, growable: false);

/// Almost const <TypeDeclarationType>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<TypeDeclarationType> emptyListOfTypeDeclarationType =
    List.filled(0, dummyExtensionType, growable: false);

/// Almost const <Constructor>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Constructor> emptyListOfConstructor =
    List.filled(0, dummyConstructor, growable: false);

/// Almost const <Initializer>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Initializer> emptyListOfInitializer =
    List.filled(0, dummyInitializer, growable: false);

/// Non-nullable [DartType] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final DartType dummyDartType = new DynamicType();

/// Non-nullable [Supertype] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Supertype dummySupertype = new Supertype(dummyClass, const []);

/// Non-nullable [NamedType] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final NamedType dummyNamedType =
    new NamedType('', dummyDartType, isRequired: false);

/// Non-nullable [Uri] dummy value.
final Uri dummyUri = new Uri(scheme: 'dummy');

/// Non-nullable [Name] dummy value.
final Name dummyName = new _PublicName('');

/// Non-nullable [Reference] dummy value.
final Reference dummyReference = new Reference();

/// Non-nullable [Component] dummy value.
///
/// This can be used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Component dummyComponent = new Component();

/// Non-nullable [Library] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Library dummyLibrary = new Library(dummyUri, fileUri: dummyUri);

/// Non-nullable [LibraryDependency] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final LibraryDependency dummyLibraryDependency =
    new LibraryDependency.import(dummyLibrary);

/// Non-nullable [Combinator] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Combinator dummyCombinator = new Combinator(false, const []);

/// Non-nullable [LibraryPart] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final LibraryPart dummyLibraryPart = new LibraryPart(const [], '');

/// Non-nullable [Class] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Class dummyClass = new Class(name: '', fileUri: dummyUri);

/// Non-nullable [Constructor] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Constructor dummyConstructor =
    new Constructor(dummyFunctionNode, name: dummyName, fileUri: dummyUri);

/// Non-nullable [Extension] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Extension dummyExtension = new Extension(name: '', fileUri: dummyUri);

/// Non-nullable [ExtensionMemberDescriptor] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final ExtensionMemberDescriptor dummyExtensionMemberDescriptor =
    new ExtensionMemberDescriptor(
        name: dummyName,
        kind: ExtensionMemberKind.Getter,
        memberReference: dummyReference,
        tearOffReference: null);

/// Non-nullable [ExtensionTypeDeclaration] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final ExtensionTypeDeclaration dummyExtensionTypeDeclaration =
    new ExtensionTypeDeclaration(name: '', fileUri: dummyUri);

/// Non-nullable [ExtensionTypeMemberDescriptor] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final ExtensionTypeMemberDescriptor dummyExtensionTypeMemberDescriptor =
    new ExtensionTypeMemberDescriptor(
        name: dummyName,
        kind: ExtensionTypeMemberKind.Getter,
        memberReference: dummyReference,
        tearOffReference: null);

/// Non-nullable [ExtensionType] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final ExtensionType dummyExtensionType =
    new ExtensionType(dummyExtensionTypeDeclaration, Nullability.nonNullable);

/// Non-nullable [Member] dummy value.
///
/// This can be used for instance as a dummy initial value for the
/// `List.filled` constructor.
final Member dummyMember = new Field.mutable(dummyName, fileUri: dummyUri);

/// Non-nullable [Procedure] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Procedure dummyProcedure = new Procedure(
    dummyName, ProcedureKind.Method, dummyFunctionNode,
    fileUri: dummyUri);

/// Non-nullable [Field] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Field dummyField = new Field.mutable(dummyName, fileUri: dummyUri);

/// Non-nullable [Typedef] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Typedef dummyTypedef = new Typedef('', null, fileUri: dummyUri);

/// Non-nullable [Initializer] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Initializer dummyInitializer = new InvalidInitializer();

/// Non-nullable [FunctionNode] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final FunctionNode dummyFunctionNode = new FunctionNode(null);

/// Non-nullable [Statement] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Statement dummyStatement = new EmptyStatement();

/// Non-nullable [Expression] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Expression dummyExpression = new NullLiteral();

/// Non-nullable [NamedExpression] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final NamedExpression dummyNamedExpression =
    new NamedExpression('', dummyExpression);

/// Almost const <Pattern>[], but not const in an attempt to avoid
/// polymorphism. See
/// https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Pattern> emptyListOfPattern =
    List.filled(0, dummyPattern, growable: false);

/// Almost const <NamedPattern>[], but not const in an attempt to avoid
/// polymorphism. See
/// https://dart-review.googlesource.com/c/sdk/+/185828.
final List<NamedPattern> emptyListOfNamedPattern =
    List.filled(0, dummyNamedPattern, growable: false);

/// Almost const <MapPatternEntry>[], but not const in an attempt to avoid
/// polymorphism. See
/// https://dart-review.googlesource.com/c/sdk/+/185828.
final List<MapPatternEntry> emptyListOfMapPatternEntry =
    List.filled(0, dummyMapPatternEntry, growable: false);

/// Non-nullable [VariableDeclaration] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final VariableDeclaration dummyVariableDeclaration =
    new VariableDeclaration(null, isSynthesized: true);

/// Non-nullable [TypeParameter] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final TypeParameter dummyTypeParameter = new TypeParameter();

/// Non-nullable [StructuralParameter] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final StructuralParameter dummyStructuralParameter = new StructuralParameter();

/// Non-nullable [MapLiteralEntry] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final MapLiteralEntry dummyMapLiteralEntry =
    new MapLiteralEntry(dummyExpression, dummyExpression);

/// Non-nullable [Arguments] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Arguments dummyArguments = new Arguments(const []);

/// Non-nullable [AssertStatement] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final AssertStatement dummyAssertStatement = new AssertStatement(
    dummyExpression,
    conditionStartOffset: TreeNode.noOffset,
    conditionEndOffset: TreeNode.noOffset);

/// Non-nullable [SwitchCase] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final SwitchCase dummySwitchCase = new SwitchCase.defaultCase(dummyStatement);

/// Non-nullable [Catch] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Catch dummyCatch = new Catch(null, dummyStatement);

/// Non-nullable [Constant] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Constant dummyConstant = new NullConstant();

/// Non-nullable [LabeledStatement] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final LabeledStatement dummyLabeledStatement = new LabeledStatement(null);

/// Of the dummy nodes, some are tree nodes. `TreeNode`s has a parent pointer
/// and that can be set when the dummy is used. This means that we can leak
/// through them. This list will (at least as a stopgap) allow us to null-out
/// the parent pointer when/if needed.
///
/// This should manually be kept up to date.
final List<TreeNode> dummyTreeNodes = [
  dummyComponent,
  dummyLibrary,
  dummyLibraryDependency,
  dummyCombinator,
  dummyLibraryPart,
  dummyClass,
  dummyConstructor,
  dummyExtension,
  dummyMember,
  dummyProcedure,
  dummyField,
  dummyTypedef,
  dummyInitializer,
  dummyFunctionNode,
  dummyStatement,
  dummyExpression,
  dummyNamedExpression,
  dummyVariableDeclaration,
  dummyTypeParameter,
  dummyMapLiteralEntry,
  dummyArguments,
  dummyAssertStatement,
  dummySwitchCase,
  dummyCatch,
  dummyLabeledStatement,
];

void clearDummyTreeNodesParentPointer() {
  for (TreeNode treeNode in dummyTreeNodes) {
    treeNode.parent = null;
  }
}
