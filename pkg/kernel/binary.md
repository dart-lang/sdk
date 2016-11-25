This file describes the binary format of Dart Kernel.

Notation
--------
Bitmasks are described with the syntax:
```scala
    Byte flags (flag1, flag2, ..., flagN)
```
where 'flag<N>' is the N-th least significant bit,
(so flag1 is the least significant bit).

Bytes with tagging bits are described with the syntax:
```scala
    Byte byte (10xxxxxx)
```
where the x'es represent the bit positions to be extracted from the
byte and the 0'es and 1'es the bits used for tagging.  The leftmost bit
is the most significant.

Binary format
-------------
```scala
type Byte = a byte

abstract type UInt {}

type UInt7 extends UInt {
  Byte byte1(0xxxxxxx);
}

type UInt14 extends UInt {
  Byte byte1(10xxxxxx); // most significant byte, discard the high bit
  Byte byte2(xxxxxxxx); // least signficant byte
}

type UInt30 extends UInt {
  Byte byte1(11xxxxxx); // most significant byte, discard the two high bits.
  Byte byte2(xxxxxxxx);
  Byte byte3(xxxxxxxx);
  Byte byte4(xxxxxxxx); // least significant byte
}

type MagicWord = big endian 32-bit unsigned integer

type String {
  UInt num_bytes;
  Byte[num_bytes] utf8_bytes;
}

type StringTable {
  UInt num_strings;
  String[num_strings] strings;
}

type StringReference {
  UInt index; // Index into the StringTable.
}

type LineStarts {
  UInt lineCount;
  // Delta encoded, e.g. 0, 10, 15, 7, 10 means 0, 10, 25, 32, 42.
  UInt[lineCount] lineStarts;
}

type UriLineStarts {
  StringTable uris;
  LineStarts[uris.num_strings] lineStarts;
}

type UriReference {
  UInt index; // Index into the URIs StringTable.
}

type FileOffset {
  // Saved as number+1 to accommodate literal "-1".
  UInt fileOffset;
}

type List<T> {
  UInt length;
  T[length] items;
}

type Option<T> {
  Byte tag;
}
type Nothing extends Option<T> {
  Byte tag = 0;
}
type Something<T> extends Option<T> {
  Byte tag = 1;
  T value;
}

type ProgramFile {
  MagicWord magic = 0x90ABCDEF;
  StringTable strings;
  UriLineStarts lineStartsMap;
  List<Library> library;
  LibraryProcedureReference mainMethod;
}

type LibraryReference {
  // For library files, this is an index into the import table.
  // For program files, this is an index into the list of libaries.
  UInt index;
}

abstract type ClassReference {}

type NormalClassReference extends ClassReference {
  Byte tag = 100;
  LibraryReference library;
  UInt classIndex;
}

type MixinClassReference extends ClassReference {
  Byte tag = 101;
  LibraryReference library;
  UInt classIndex;
}

abstract type MemberReference {
}

type LibraryFieldReference extends MemberReference {
  Byte tag = 102;
  LibraryReference library;
  UInt fieldIndex; // Index in list of fields.
}

type ClassFieldReference extends MemberReference {
  Byte tag = 103;
  ClassReference class;
  UInt fieldIndex;
}

type ClassConstructorReference extends MemberReference {
  Byte tag = 104;
  ClassReference class;
  UInt constructorIndex; // Index in list of constructors.
}

type LibraryProcedureReference extends MemberReference {
  Byte tag = 105;
  LibraryReference library;
  UInt procedureIndex; // Index in list of procedures.
}

type ClassProcedureReference extends MemberReference {
  Byte tag = 106;
  ClassReference class;
  UInt procedureIndex;
}

// Can be used as MemberReference or ClassReference *only* if indicated that
// the given reference may be a NullReference.
type NullReference extends MemberReference, ClassReference {
  Byte tag = 99;
}

type Name {
  StringReference name;
  if name begins with '_' {
    LibraryReference library;
  }
}

type Library {
  Byte flags (isExternal);
  StringReference name;
  // A URI with the dart, package, or file scheme.  For file URIs, the path
  // is an absolute path to the .dart file from which the library was created.
  StringReference importUri;
  // An absolute path URI to the .dart file from which the library was created.
  UriReference fileUri;
  List<Class> classes;
  List<Field> fields;
  List<Procedure> procedures;
}

abstract type Node {
  Byte tag;
}

// A class can be represented at one of three levels: type, hierarchy, or body.
//
// If the enclosing library is external, a class is either at type or
// hierarchy level, depending on its isTypeLevel flag.
// If the enclosing library is not external, a class is always at body level.
//
// See ClassLevel in ast.dart for the details of each loading level.

abstract type Class extends Node {}

type NormalClass extends Class {
  Byte tag = 2;
  Byte flags (isAbstract, isTypeLevel);
  StringReference name;
  // An absolute path URI to the .dart file from which the class was created.
  UriReference fileUri;
  List<Expression> annotations;
  List<TypeParameter> typeParameters;
  Option<InterfaceType> superClass;
  List<InterfaceType> implementedClasses;
  List<Field> fields;
  List<Constructor> constructors;
  List<Procedure> procedures;
}

type MixinClass extends Class {
  Byte tag = 3;
  Byte flags (isAbstract, isTypeLevel);
  StringReference name;
  // An absolute path URI to the .dart file from which the class was created.
  UriReference fileUri;
  List<Expression> annotations;
  List<TypeParameter> typeParameters;
  InterfaceType firstSuperClass;
  InterfaceType secondSuperClass;
  List<InterfaceType> implementedClasses;
  List<Constructor> constructors;
}

abstract type Member extends Node {}

type Field extends Member {
  Byte tag = 4;
  FileOffset fileOffset;
  Byte flags (isFinal, isConst, isStatic);
  Name name;
  // An absolute path URI to the .dart file from which the field was created.
  UriReference fileUri;
  List<Expression> annotations;
  DartType type;
  Option<InferredValue> inferredValue;
  Option<Expression> initializer;
}

type Constructor extends Member {
  Byte tag = 5;
  Byte flags (isConst, isExternal);
  Name name;
  List<Expression> annotations;
  FunctionNode function;
  List<Initializer> initializers;
}

/*
enum ProcedureKind {
  Method,
  Getter,
  Setter,
  Operator,
  Factory,
}
*/

type Procedure extends Member {
  Byte tag = 6;
  Byte kind; // Index into the ProcedureKind enum above.
  Byte flags (isStatic, isAbstract, isExternal, isConst);
  Name name;
  // An absolute path URI to the .dart file from which the class was created.
  UriReference fileUri;
  List<Expression> annotations;
  // Can only be absent if abstract, but tag is there anyway.
  Option<FunctionNode> function;
}

abstract type Initializer extends Node {}

type InvalidInitializer extends Initializer {
  Byte tag = 7;
}

type FieldInitializer extends Initializer {
  Byte tag = 8;
  FieldReference field;
  Expression value;
}

type SuperInitializer extends Initializer {
  Byte tag = 9;
  ConstructorReference target;
  Arguments arguments;
}

type RedirectingInitializer extends Initializer {
  Byte tag = 10;
  ConstructorReference target;
  Arguments arguments;
}

type LocalInitializer extends Initializer {
  Byte tag = 11;
  VariableDeclaration variable;
}

/*
enum AsyncMarker {
  Sync,
  SyncStar,
  Async,
  AsyncStar
}
*/

type FunctionNode {
  // Note: there is no tag on FunctionNode.
  Byte asyncMarker; // Index into AsyncMarker above.
  List<TypeParameter> typeParameters;
  UInt requiredParameterCount;
  List<VariableDeclaration> positionalParameters;
  List<VariableDeclaration> namedParameters;
  DartType returnType;
  Option<InferredValue> inferredReturnValue;
  Option<Statement> body;
}

type VariableReference {
  // Reference to the Nth variable in scope, with 0 being the
  // first variable declared in the outermost scope, and larger
  // numbers being the variables declared later in a given scope,
  // or in a more deeply nested scope.
  //
  // Function parameters are indexed from left to right and make
  // up the outermost scope (enclosing the function body).
  // Variables ARE NOT in scope inside their own initializer.
  // Variables ARE NOT in scope before their declaration, in contrast
  // to how the Dart Specification defines scoping.
  // Variables ARE in scope across function boundaries.
  //
  // When declared, a variable remains in scope until the end of the
  // immediately enclosing Block, Let, FunctionNode, ForStatement,
  // ForInStatement, or Catch.
  //
  // A special exception is made for constructor parameters, which are
  // also in scope in the initializer list, even though the tree nesting
  // is inconsistent with the scoping.
  UInt stackIndex;
}

abstract type Expression extends Node {}

type InvalidExpression extends Expression {
  Byte tag = 19;
}

type VariableGet extends Expression {
  Byte tag = 20;
  VariableReference variable;
}

type SpecializedVariableGet extends Expression {
  Byte tag = 128 + N; // Where 0 <= N < 8.
  // Equivalent to a VariableGet with index N.
}

type VariableSet extends Expression {
  Byte tag = 21;
  VariableReference variable;
  Expression value;
}

type SpecializedVariableSet extends Expression {
  Byte tag = 136 + N; // Where 0 <= N < 8.
  Expression value;
  // Equivalent to VariableSet with index N.
}

type PropertyGet extends Expression {
  Byte tag = 22;
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  MemberReference interfaceTarget; // May be NullReference.
}

type PropertySet extends Expression {
  Byte tag = 23;
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  Expression value;
  MemberReference interfaceTarget; // May be NullReference.
}

type SuperPropertyGet extends Expression {
  Byte tag = 24;
  Name name;
  MemberReference interfaceTarget; // May be NullReference.
}

type SuperPropertySet extends Expression {
  Byte tag = 25;
  Name name;
  Expression value;
  MemberReference interfaceTarget; // May be NullReference.
}

type DirectPropertyGet extends Expression {
  Byte tag = 15; // Note: tag is out of order
  Expression receiver;
  MemberReference target;
}

type DirectPropertySet extends Expression {
  Byte tag = 16; // Note: tag is out of order
  Expression receiver;
  MemberReference target;
  Expression value;
}

type StaticGet extends Expression {
  Byte tag = 26;
  FileOffset fileOffset;
  MemberReference target;
}

type StaticSet extends Expression {
  Byte tag = 27;
  MemberReference target;
  Expression value;
}

type Arguments {
  // Note: there is no tag on Arguments.
  List<DartType> types;
  List<Expression> positional;
  List<NamedExpression> named;
}

type NamedExpression {
  // Note: there is no tag on NamedExpression.
  StringReference name;
  Expression value;
}

type MethodInvocation extends Expression {
  Byte tag = 28;
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  Arguments arguments;
  MemberReference interfaceTarget; // May be NullReference.
}

type SuperMethodInvocation extends Expression {
  Byte tag = 29;
  FileOffset fileOffset;
  Name name;
  Arguments arguments;
  MemberReference interfaceTarget; // May be NullReference.
}

type DirectMethodInvocation extends Expression {
  Byte tag = 17; // Note: tag is out of order
  Expression receiver;
  MemberReference target;
  Arguments arguments;
}

type StaticInvocation extends Expression {
  Byte tag = 30;
  FileOffset fileOffset;
  MemberReference target;
  Arguments arguments;
}

// Constant call to an external constant factory.
type ConstStaticInvocation extends Expression {
  Byte tag = 18; // Note: tag is out of order.
  FileOffset fileOffset;
  MemberReference target;
  Arguments arguments;
}

type ConstructorInvocation extends Expression {
  Byte tag = 31;
  FileOffset fileOffset;
  ConstructorReference target;
  Arguments arguments;
}

type ConstConstructorInvocation extends Expression {
  Byte tag = 32;
  FileOffset fileOffset;
  ConstructorReference target;
  Arguments arguments;
}

type Not extends Expression {
  Byte tag = 33;
  Expression operand;
}

/*
 enum LogicalOperator { &&, || }
*/

type LogicalExpression extends Expression {
  Byte tag = 34;
  Expression left;
  Byte operator; // Index into LogicalOperator enum above
  Expression right;
  Option<DartType> staticType;
}

type ConditionalExpression extends Expression {
  Byte tag = 35;
  Expression condition;
  Expression then;
  Expression otherwise;
  Option<DartType> staticType;
}

type StringConcatenation extends Expression {
  Byte tag = 36;
  List<Expression> expressions;
}

type IsExpression extends Expression {
  Byte tag = 37;
  Expression operand;
  DartType type;
}

type AsExpression extends Expression {
  Byte tag = 38;
  Expression operand;
  DartType type;
}

type StringLiteral extends Expression {
  Byte tag = 39;
  StringReference value;
}

type SpecializedIntLiteral extends Expression {
  Byte tag = 144 + N; // Where 0 <= N < 8.
  // Integer literal with value (N - 3), that is, an integer in range -3..4.
}

type PositiveIntLiteral extends Expression {
  Byte tag = 55;
  UInt value;
}

type NegativeIntLiteral extends Expression {
  Byte tag = 56;
  UInt absoluteValue;
}

type BigIntLiteral extends Expression {
  Byte tag = 57;
  StringReference valueString;
}

type DoubleLiteral extends Expression {
  Byte tag = 40;
  StringReference valueString;
}

type TrueLiteral extends Expression {
  Byte tag = 41;
}

type FalseLiteral extends Expression {
  Byte tag = 42;
}

type NullLiteral extends Expression {
  Byte tag = 43;
}

type SymbolLiteral extends Expression {
  Byte tag = 44;
  StringReference value; // Everything strictly after the '#'.
}

type TypeLiteral extends Expression {
  Byte tag = 45;
  DartType type;
}

type ThisExpression extends Expression {
  Byte tag = 46;
}

type Rethrow extends Expression {
  Byte tag = 47;
}

type Throw extends Expression {
  Byte tag = 48;
  FileOffset fileOffset;
  Expression value;
}

type ListLiteral extends Expression {
  Byte tag = 49;
  DartType typeArgument;
  List<Expression> values;
}

type ConstListLiteral extends Expression {
  Byte tag = 58; // Note: tag is out of order.
  DartType typeArgument;
  List<Expression> values;
}

type MapLiteral extends Expression {
  Byte tag = 50;
  DartType keyType;
  DartType valueType;
  List<MapEntry> entries;
}

type ConstMapLiteral extends Expression {
  Byte tag = 59; // Note: tag is out of order.
  DartType keyType;
  DartType valueType;
  List<MapEntry> entries;
}

type MapEntry {
  // Note: there is no tag on MapEntry
  Expression key;
  Expression value;
}

type AwaitExpression extends Expression {
  Byte tag = 51;
  Expression operand;
}

type FunctionExpression extends Expression {
  Byte tag = 52;
  FunctionNode function;
}

type Let extends Expression {
  Byte tag = 53;
  VariableDeclaration variable;
  Expression body;
}

abstract type Statement extends Node {}

type InvalidStatement extends Statement {
  Byte tag = 60;
}

type ExpressionStatement extends Statement {
  Byte tag = 61;
  Expression expression;
}

type Block extends Statement {
  Byte tag = 62;
  List<Expression> expressions;
}

type EmptyStatement extends Statement {
  Byte tag = 63;
}

type AssertStatement extends Statement {
  Byte tag = 64;
  Expression condition;
  Option<Expression> message;
}

type LabeledStatement extends Statement {
  Byte tag = 65;
  Statement body;
}

type BreakStatement extends Statement {
  Byte tag = 66;

  // Reference to the Nth LabeledStatement in scope, with 0 being the
  // outermost enclosing labeled statement within the same FunctionNode.
  //
  // Labels are not in scope across function boundaries.
  UInt labelIndex;
}

type WhileStatement extends Statement {
  Byte tag = 67;
  Expression condition;
  Statement body;
}

type DoStatement extends Statement {
  Byte tag = 68;
  Statement body;
  Expression condition;
}

type ForStatement extends Statement {
  Byte tag = 69;
  List<VariableDeclaration> variables;
  Option<Expression> condition;
  List<Expression> updates;
  Statement body;
}

type ForInStatement extends Statement {
  Byte tag = 70;
  VariableDeclaration variable;
  Expression iterable;
  Statement body;
}

type AsyncForInStatement extends Statement {
  Byte tag = 80; // Note: tag is out of order.
  VariableDeclaration variable;
  Expression iterable;
  Statement body;
}

type SwitchStatement extends Statement {
  Byte tag = 71;
  Expression expression;
  List<SwitchCase> cases;
}

type SwitchCase {
  // Note: there is no tag on SwitchCase
  List<Expression> expressions;
  Byte isDefault; // 1 if default, 0 is not default.
  Statement body;
}

type ContinueSwitchStatement extends Statement {
  Byte tag = 72;

  // Reference to the Nth SwitchCase in scope.
  //
  // A SwitchCase is in scope everywhere within its enclosing switch,
  // except the scope is delimited by FunctionNodes.
  //
  // Switches are ordered from outermost to innermost, and the SwitchCases
  // within a switch are consecutively indexed from first to last, so index
  // 0 is the first SwitchCase of the outermost enclosing switch in the
  // same FunctionNode.
  UInt caseIndex;
}

type IfStatement extends Statement {
  Byte tag = 73;
  Expression condition;
  Statement then;
  Statement otherwise; // Empty statement if there was no else part.
}

type ReturnStatement extends Statement {
  Byte tag = 74;
  Option<Expression> expression;
}

type TryCatch extends Statement {
  Byte tag = 75;
  Statement body;
  List<Catch> catches;
}

type Catch {
  DartType guard;
  Option<VariableDeclaration> exception;
  Option<VariableDeclaration> stackTrace;
  Statement body;
}

type TryFinally extends Statement {
  Byte tag = 76;
  Statement body;
  Statement finalizer;
}

type YieldStatement extends Statement {
  Byte tag = 77;
  Byte flags (isYieldStar);
  Expression expression;
}

type VariableDeclarationStatement extends Statement {
  Byte tag = 78;
  VariableDeclaration variable;
}

type VariableDeclaration {
  Byte flags (isFinal, isConst);
  // For named parameters, this is the parameter name.
  // For other variables, the name is cosmetic, may be empty,
  // and is not necessarily unique.
  StringReference name;
  DartType type;
  Option<InferredValue> inferredValue;

  // For statements and for-loops, this is the initial value.
  // For optional parameters, this is the default value (if given).
  // In all other contexts, it must be Nothing.
  Option<Expression> initializer;
}

type FunctionDeclaration extends Statement {
  Byte tag = 79;
  // The variable binding the function.  The variable is in scope
  // within the function for use as a self-reference.
  // Some of the fields in the variable are redundant, but its presence here
  // simplifies the rule for variable indexing.
  VariableDeclaration variable;
  FunctionNode function;
}

abstract type DartType extends Node {}

type InvalidType extends DartType {
  Byte tag = 90;
}

type DynamicType extends DartType {
  Byte tag = 91;
}

type VoidType extends DartType {
  Byte tag = 92;
}

type InterfaceType extends DartType {
  Byte tag = 93;
  ClassReference class;
  List<DartType> typeArguments;
}

type SimpleInterfaceType extends DartType {
  Byte tag = 96; // Note: tag is out of order.
  ClassReference class;
  // Equivalent to InterfaceType with empty list of type arguments.
}

type FunctionType extends DartType {
  Byte tag = 94;
  List<TypeParameter> typeParameters;
  UInt requiredParameterCount;
  List<DartType> positionalParameters;
  List<NamedDartType> namedParameters;
  DartType returnType;
}

type SimpleFunctionType extends DartType {
  Byte tag = 97; // Note: tag is out of order.
  List<DartType> positionalParameters;
  DartType returnType;
  // Equivalent to a FunctionType with no type parameters or named parameters,
  // and where all positional parameters are required.
}

type NamedDartType {
  StringReference name;
  DartType type;
}

type TypeParameterType extends DartType {
  Byte tag = 95;

  // Reference to the Nth type parameter in scope (with some caveats about
  // type parameter bounds).
  //
  // As with the other indexing schemes, outermost nodes have lower
  // indices, and a type parameter list is consecutively indexed from
  // left to right.
  //
  // In the case of type parameter bounds, this indexing diverges slightly
  // from the definition of scoping, since type parameter N+1 is not "in scope"
  // in the bound of type parameter N, but it takes up an index as if it was in
  // scope there.
  //
  // The type parameter can be bound by a Class, FunctionNode, or FunctionType.
  //
  // Note that constructors currently do not declare type parameters.  Uses of
  // the class type parameters in a constructor refer to those declared on the
  // class.
  UInt index;
}

type TypeParameter {
  // Note: there is no tag on TypeParameter
  StringReference name; // Cosmetic, may be empty, not unique.
  DartType bound; // 'dynamic' if no explicit bound was given.
}

/* enum BaseClassKind { None, Exact, Subclass, Subtype, } */

type InferredValue {
  ClassReference baseClass; // May be NullReference if kind = None.
  Byte kind; // Index into BaseClassKind.
  Byte valueBits; // See lib/type_propagation/type_propagation.dart
}

```
