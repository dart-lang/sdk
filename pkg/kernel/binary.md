<!--
Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file.
-->

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

type UInt32 = big endian 32-bit unsigned integer

type Double = Double-precision floating-point number.

type List<T> {
  UInt length;
  T[length] items;
}

type RList<T> {
  T[length] elements;
  UInt32 length;
}

// Untagged pairs.
type Pair<T0, T1> {
  T0 first;
  T1 second;
}
```

A string table consists of an array of end offsets and a payload array of
strings encoded as WTF-8.  The array of end offsets maps a string index to the
offset of the _next_ string in the table or the offset of the end of the array
for the last string.  These offsets are relative to the string payload array.
Thus, string number 0 consists of the WTF-8 encoded string stretching from
offset 0 (inclusive) to endOffset[0] (exclusive); and string number N for N > 0
consists of the WTF-8 encoded string stretching from offset endOffset[N-1]
(inclusive) to endOffset[N] (exclusive).

``` scala
type StringTable {
  List<UInt> endOffsets;
  Byte[endOffsets.last] utf8Bytes;
}

type StringReference {
  UInt index; // Index into the Component's strings.
}

type ConstantReference {
  UInt offset; // Byte offset into the Component's constants.
}

type SourceInfo {
  List<Byte> uriUtf8Bytes;
  List<Byte> sourceUtf8Bytes;

  // Line starts are delta-encoded (they are encoded as line lengths).  The list
  // [0, 10, 25, 32, 42] is encoded as [0, 10, 15, 7, 10].
  List<UInt> lineStarts;

  List<Byte> importUriUtf8Bytes;

  // List of constructors evaluated *by* this library. Note that these can be
  // in other libraries.
  List<ConstructorReference> constructorCoverage;
}

type String {
  List<Byte> utf8Bytes;
}

type UriSource {
  UInt32 length;
  SourceInfo[length] source;
  // The ith entry is byte-offset to the ith Source.
  UInt32[length] sourceIndex;
}

type UriReference {
  UInt index; // Index into the UriSource uris.
}

type FileOffset {
  // Encoded as offset + 1 to accommodate -1 indicating no offset.
  UInt fileOffset;
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

type CanonicalNameReference {
  UInt biasedIndex; // 0 if null, otherwise N+1 where N is index of parent
}

type CanonicalName {
  CanonicalNameReference parent;
  StringReference name;
}

type ComponentFile {
  UInt32 magic = 0x90ABCDEF;
  UInt32 formatVersion = 53;
  Byte[10] shortSdkHash;
  List<String> problemsAsJson; // Described in problems.md.
  Library[] libraries;
  UriSource sourceMap;
  List<CanonicalName> canonicalNames;
  MetadataPayload[] metadataPayloads;
  RList<MetadataMapping> metadataMappings;
  StringTable strings;
  List<Constant> constants;
  ComponentIndex componentIndex;
}

// Backend specific metadata section.
type MetadataPayload {
  Byte[] opaquePayload;
}

type MetadataMapping {
  UInt32 tag;  // StringReference of a fixed size.
  // Node offsets are absolute, while metadata offsets are relative to metadataPayloads.
  RList<Pair<UInt32, UInt32>> nodeOffsetToMetadataOffset;
}

// Component index with all fixed-size-32-bit integers.
// This gives "semi-random-access" to certain parts of the binary.
// By reading the last 4 bytes one knows the number of libaries,
// which allows to skip to any other field in this component index,
// which again allows to skip to what it points to.
type ComponentIndex {
  Byte[] 8bitAlignment; // 0-bytes to make the entire component (!) 8-byte aligned.
  UInt32 binaryOffsetForSourceTable;
  UInt32 binaryOffsetForCanonicalNames;
  UInt32 binaryOffsetForMetadataPayloads;
  UInt32 binaryOffsetForMetadataMappings;
  UInt32 binaryOffsetForStringTable;
  UInt32 binaryOffsetForConstantTable;
  UInt32 mainMethodReference; // This is a ProcedureReference with a fixed-size integer.
  UInt32 compilationMode; // enum NonNullableByDefaultCompiledMode { Disabled = 0, Weak = 1, Strong = 2, Agnostic = 3 } with a fixed-size integer.
  UInt32[libraryCount + 1] libraryOffsets;
  UInt32 libraryCount;
  UInt32 componentFileSizeInBytes;
}

type LibraryReference {
  // Must be populated by a library (possibly later in the file).
  CanonicalNameReference canonicalName;
}

type ClassReference {
  // Must be populated by a class (possibly later in the file).
  CanonicalNameReference canonicalName;
}

type MemberReference {
  // Must be populated by a member (possibly later in the file).
  CanonicalNameReference canonicalName;
}

type FieldReference {
  // Must be populated by a field (possibly later in the file).
  CanonicalNameReference canonicalName;
}

type ConstructorReference {
  // Must be populated by a constructor (possibly later in the file).
  CanonicalNameReference canonicalName;
}

type ProcedureReference {
  // Must be populated by a procedure (possibly later in the file).
  CanonicalNameReference canonicalName;
}

type TypedefReference {
  // Must be populated by a typedef (possibly later in the file).
  CanonicalNameReference canonicalName;
}

type Name {
  StringReference name;
  if name begins with '_' {
    LibraryReference library;
  }
}

type Library {
  Byte flags (isSynthetic, isNonNullableByDefault, nnbdModeBit1, nnbdModeBit2);
  UInt languageVersionMajor;
  UInt languageVersionMinor;
  CanonicalNameReference canonicalName;
  StringReference name;
  // An absolute path URI to the .dart file from which the library was created.
  UriReference fileUri;
  List<String> problemsAsJson; // Described in problems.md.
  List<Expression> annotations;
  List<LibraryDependency> libraryDependencies;
  List<CanonicalNameReference> additionalExports;
  List<LibraryPart> libraryParts;
  List<Typedef> typedefs;
  List<Class> classes;
  List<Extension> extensions;
  List<Field> fields;
  List<Procedure> procedures;

  List<UInt> sourceReferences; // list of sources used by library, indexes into UriSource on Component.

  // Library index. Offsets are used to get start (inclusive) and end (exclusive) byte positions for
  // a specific class or procedure. Note the "+1" to account for needing the end of the last entry.
  UInt32 sourceReferencesOffset;
  UInt32[classes.length + 1] classOffsets;
  UInt32 classCount = classes.length;
  UInt32[procedures.length + 1] procedureOffsets;
  UInt32 procedureCount = procedures.length;
}

type LibraryDependency {
  FileOffset fileOffset;
  Byte flags (isExport, isDeferred);
  List<Expression> annotations;
  LibraryReference targetLibrary;
  StringReference name;
  List<Combinator> combinators;
}

type LibraryPart {
  List<Expression> annotations;
  StringReference partUri;
}

type Typedef {
  CanonicalNameReference canonicalName;
  UriReference fileUri;
  FileOffset fileOffset;
  StringReference name;
  List<Expression> annotations;
  List<TypeParameter> typeParameters;
  DartType type;
  List<TypeParameter> typeParametersOfFunctionType;
  List<VariableDeclarationPlain> positionalParameters;
  List<VariableDeclarationPlain> namedParameters;
}

type Combinator {
  Byte flags (isShow);
  List<StringReference> names;
}

type LibraryDependencyReference {
  // Index into libraryDependencies in the enclosing Library.
  UInt index;
}

abstract type Node {
  Byte tag;
}

type Class extends Node {
  Byte tag = 2;
  CanonicalNameReference canonicalName;
  // An absolute path URI to the .dart file from which the class was created.
  UriReference fileUri;
  FileOffset startFileOffset; // Offset of the start of the class including any annotations.
  FileOffset fileOffset; // Offset of the name of the class.
  FileOffset fileEndOffset;
  Byte flags (isAbstract, isEnum, isAnonymousMixin, isEliminatedMixin,
              isMixinDeclaration, hasConstConstructor);
  StringReference name;
  List<Expression> annotations;
  List<TypeParameter> typeParameters;
  Option<DartType> superClass;
  // For transformed mixin application classes (isEliminatedMixin),
  // original mixedInType is pulled into the end of implementedClasses.
  Option<DartType> mixedInType;
  List<DartType> implementedClasses;
  List<Field> fields;
  List<Constructor> constructors;
  List<Procedure> procedures;
  List<RedirectingFactoryConstructor> redirectingFactoryConstructors;

  // Class index. Offsets are used to get start (inclusive) and end (exclusive) byte positions for
  // a specific procedure. Note the "+1" to account for needing the end of the last entry.
  UInt32[procedures.length + 1] procedureOffsets;
  UInt32 procedureCount = procedures.length;
}

type Extension extends Node {
  Byte tag = 115;
  CanonicalNameReference canonicalName;
  StringReference name;
  UriReference fileUri;
  FileOffset fileOffset;
  List<TypeParameter> typeParameters;
  DartType onType;
  List<ExtensionMemberDescriptor> members;
}

enum ExtensionMemberKind { Field = 0, Method = 1, Getter = 2, Setter = 3, Operator = 4, TearOff = 5, }

type ExtensionMemberDescriptor {
  Name name;
  ExtensionMemberKind kind;
  Byte flags (isStatic);
  MemberReference member;
}

abstract type Member extends Node {}

type Field extends Member {
  Byte tag = 4;
  CanonicalNameReference canonicalNameGetter;
  CanonicalNameReference canonicalNameSetter;
  // An absolute path URI to the .dart file from which the field was created.
  UriReference fileUri;
  FileOffset fileOffset;
  FileOffset fileEndOffset;
  UInt flags (isFinal, isConst, isStatic, hasImplicitGetter, hasImplicitSetter,
                isCovariant, isGenericCovariantImpl, isLate, isExtensionMember,
                isNonNullableByDefault, isInternalImplementation);
  Name name;
  List<Expression> annotations;
  DartType type;
  Option<Expression> initializer;
}

type Constructor extends Member {
  Byte tag = 5;
  CanonicalNameReference canonicalName;
  UriReference fileUri;
  FileOffset startFileOffset; // Offset of the start of the constructor including any annotations.
  FileOffset fileOffset; // Offset of the constructor name.
  FileOffset fileEndOffset;
  Byte flags (isConst, isExternal, isSynthetic, isNonNullableByDefault);
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

/*
enum ProcedureStubKind {
  Regular,
  ForwardingStub,
  ForwardingSuperStub,
  NoSuchMethodForwarder,
  MemberSignature,
  MixinStub,
  MixinSuperStub,
}
*/

type Procedure extends Member {
  Byte tag = 6;
  CanonicalNameReference canonicalName;
  // An absolute path URI to the .dart file from which the class was created.
  UriReference fileUri;
  FileOffset startFileOffset; // Offset of the start of the procedure including any annotations.
  FileOffset fileOffset; // Offset of the procedure name.
  FileOffset fileEndOffset;
  Byte kind; // Index into the ProcedureKind enum above.
  Byte stubKind; // Index into the ProcedureStubKind enum above.
  UInt flags (isStatic, isAbstract, isExternal, isConst,
              isRedirectingFactoryConstructor, isExtensionMember,
              isNonNullableByDefault);
  Name name;
  List<Expression> annotations;
  MemberReference stubTarget; // May be NullReference.
  // Can only be absent if abstract, but tag is there anyway.
  Option<FunctionNode> function;
}

type RedirectingFactoryConstructor extends Member {
  Byte tag = 108;
  CanonicalNameReference canonicalName;
  UriReference fileUri;
  FileOffset fileOffset;
  FileOffset fileEndOffset;
  Byte flags;
  Name name;
  List<Expression> annotations;
  MemberReference targetReference;
  List<DartType> typeArguments;
  List<TypeParameter> typeParameters;
  UInt parameterCount; // positionalParameters.length + namedParameters.length.
  UInt requiredParameterCount;
  List<VariableDeclarationPlain> positionalParameters;
  List<VariableDeclarationPlain> namedParameters;
}

abstract type Initializer extends Node {}

type InvalidInitializer extends Initializer {
  Byte tag = 7;
  Byte isSynthetic;
}

type FieldInitializer extends Initializer {
  Byte tag = 8;
  Byte isSynthetic;
  FieldReference field;
  Expression value;
}

type SuperInitializer extends Initializer {
  Byte tag = 9;
  Byte isSynthetic;
  FileOffset fileOffset;
  ConstructorReference target;
  Arguments arguments;
}

type RedirectingInitializer extends Initializer {
  Byte tag = 10;
  Byte isSynthetic;
  FileOffset fileOffset;
  ConstructorReference target;
  Arguments arguments;
}

type LocalInitializer extends Initializer {
  Byte tag = 11;
  Byte isSynthetic;
  VariableDeclarationPlain variable;
}

type AssertInitializer extends Initializer {
  Byte tag = 12;
  Byte isSynthetic;
  AssertStatement statement;
}

/*
enum AsyncMarker {
  Sync,
  SyncStar,
  Async,
  AsyncStar,
  SyncYielding
}
*/

type FunctionNode {
  Byte tag = 3;
  FileOffset fileOffset;
  FileOffset fileEndOffset;
  Byte asyncMarker; // Index into AsyncMarker above.
  Byte dartAsyncMarker; // Index into AsyncMarker above.
  List<TypeParameter> typeParameters;
  UInt parameterCount; // positionalParameters.length + namedParameters.length.
  UInt requiredParameterCount;
  List<VariableDeclarationPlain> positionalParameters;
  List<VariableDeclarationPlain> namedParameters;
  DartType returnType;
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
  FileOffset fileOffset;
  StringReference message;
}

type VariableGet extends Expression {
  Byte tag = 20;
  FileOffset fileOffset;
  // Byte offset in the binary for the variable declaration (without tag).
  UInt variableDeclarationPosition;
  VariableReference variable;
  Option<DartType> promotedType;
}

type SpecializedVariableGet extends Expression {
  Byte tag = 128 + N; // Where 0 <= N < 8.
  // Equivalent to a VariableGet with index N.
  FileOffset fileOffset;
  // Byte offset in the binary for the variable declaration (without tag).
  UInt variableDeclarationPosition;
}

type VariableSet extends Expression {
  Byte tag = 21;
  FileOffset fileOffset;
  // Byte offset in the binary for the variable declaration (without tag).
  UInt variableDeclarationPosition;
  VariableReference variable;
  Expression value;
}

type SpecializedVariableSet extends Expression {
  Byte tag = 136 + N; // Where 0 <= N < 8.
  FileOffset fileOffset;
  // Byte offset in the binary for the variable declaration (without tag).
  UInt variableDeclarationPosition;
  Expression value;
  // Equivalent to VariableSet with index N.
}

type PropertyGet extends Expression {
  Byte tag = 22;
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  MemberReference interfaceTarget; // May be NullReference.
  MemberReference interfaceTargetOrigin; // May be NullReference.
}

type PropertySet extends Expression {
  Byte tag = 23;
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  Expression value;
  MemberReference interfaceTarget; // May be NullReference.
  MemberReference interfaceTargetOrigin; // May be NullReference.
}

type SuperPropertyGet extends Expression {
  Byte tag = 24;
  FileOffset fileOffset;
  Name name;
  MemberReference interfaceTarget; // May be NullReference.
  MemberReference interfaceTargetOrigin; // May be NullReference.
}

type SuperPropertySet extends Expression {
  Byte tag = 25;
  FileOffset fileOffset;
  Name name;
  Expression value;
  MemberReference interfaceTarget; // May be NullReference.
  MemberReference interfaceTargetOrigin; // May be NullReference.
}

/*
enum InstanceAccessKind {
  Instance,
  Object,
  Inapplicable,
  Nullable,
}
*/

type InstanceGet extends Expression {
  Byte tag = 118;
  Byte kind; // Index into InstanceAccessKind above.
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  DartType resultType;
  MemberReference interfaceTarget;
  MemberReference interfaceTargetOrigin; // May be NullReference.
}

type InstanceSet extends Expression {
  Byte tag = 119;
  Byte kind; // Index into InstanceAccessKind above.
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  Expression value;
  MemberReference interfaceTarget;
  MemberReference interfaceTargetOrigin; // May be NullReference.
}

type InstanceTearOff extends Expression {
  Byte tag = 121;
  Byte kind; // Index into InstanceAccessKind above.
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  DartType resultType;
  MemberReference interfaceTarget;
  MemberReference interfaceTargetOrigin; // May be NullReference.
}

/*
enum DynamicAccessKind {
  Dynamic,
  Never,
  Invalid,
  Unresolved,
}
*/

type DynamicGet extends Expression {
  Byte tag = 122;
  Byte kind; // Index into DynamicAccessKind above.
  FileOffset fileOffset;
  Expression receiver;
  Name name;
}

type DynamicSet extends Expression {
  Byte tag = 123;
  Byte kind; // Index into DynamicAccessKind above.
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  Expression value;
}

type StaticGet extends Expression {
  Byte tag = 26;
  FileOffset fileOffset;
  MemberReference target;
}

type StaticTearOff extends Expression {
  Byte tag = 17;
  FileOffset fileOffset;
  MemberReference target;
}

type StaticSet extends Expression {
  Byte tag = 27;
  FileOffset fileOffset;
  MemberReference target;
  Expression value;
}

type Arguments {
  // Note: there is no tag on Arguments.
  UInt numArguments; // equals positional.length + named.length
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
  Byte flags (isInvariant, isBoundsSafe);
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  Arguments arguments;
  MemberReference interfaceTarget; // May be NullReference.
  MemberReference interfaceTargetOrigin; // May be NullReference.
}

type InstanceInvocation extends Expression {
  Byte tag = 120;
  Byte kind; // Index into InstanceAccessKind above.
  Byte flags (isInvariant, isBoundsSafe);
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  Arguments arguments;
  DartType functionType;
  MemberReference interfaceTarget;
  MemberReference interfaceTargetOrigin; // May be NullReference.
}

type DynamicInvocation extends Expression {
  Byte tag = 124;
  Byte kind; // Index into DynamicAccessKind above.
  FileOffset fileOffset;
  Expression receiver;
  Name name;
  Arguments arguments;
}

/*
enum FunctionAccessKind {
  Function,
  FunctionType,
  Inapplicable,
  Nullable,
}
*/

type FunctionInvocation extends Expression {
  Byte tag = 125;
  Byte kind; // Index into FunctionAccessKind above.
  FileOffset fileOffset;
  Expression receiver;
  Arguments arguments;
  DartType functionType; // Use `const DynamicType()` as `null`.
}

type FunctionTearOff extends Expression {
  Byte tag = 126;
  FileOffset fileOffset;
  Expression receiver;
  DartType functionType;
}

type LocalFunctionInvocation extends Expression {
  Byte tag = 127;
  FileOffset fileOffset;
  // Byte offset in the binary for the variable declaration (without tag).
  UInt variableDeclarationPosition;
  VariableReference variable;
  Arguments arguments;
  DartType functionType;
}

type EqualsNull extends Expression {
  Byte tag = 15;
  FileOffset fileOffset;
  Expression expression;
  Byte isNot;
}

type EqualsCall extends Expression {
  Byte tag = 16;
  FileOffset fileOffset;
  Expression left;
  Expression right;
  Byte isNot;
  DartType functionType;
  MemberReference interfaceTarget;
  MemberReference interfaceTargetOrigin; // May be NullReference.
}

type SuperMethodInvocation extends Expression {
  Byte tag = 29;
  FileOffset fileOffset;
  Name name;
  Arguments arguments;
  MemberReference interfaceTarget; // May be NullReference.
  MemberReference interfaceTargetOrigin; // May be NullReference.
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

type NullCheck extends Expression {
  Byte tag = 117;
  FileOffset fileOffset;
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
  FileOffset fileOffset;
  List<Expression> expressions;
}

type ListConcatenation extends Expression {
  Byte tag = 111;
  FileOffset fileOffset;
  DartType typeArgument;
  List<Expression> lists;
}

type SetConcatenation extends Expression {
  Byte tag = 112;
  FileOffset fileOffset;
  DartType typeArgument;
  List<Expression> sets;
}

type MapConcatenation extends Expression {
  Byte tag = 113;
  FileOffset fileOffset;
  DartType keyType;
  DartType valueType;
  List<Expression> maps;
}

type InstanceCreation extends Expression {
  Byte tag = 114;
  FileOffset fileOffset;
  CanonicalNameReference class;
  List<DartType> typeArguments;
  List<Pair<FieldReference, Expression>> fieldValues;
  List<AssertStatement> asserts;
  List<Expression> unusedArguments;
}

type FileUriExpression extends Expression {
  Byte tag = 116;
  UriReference fileUri;
  FileOffset fileOffset;
  Expression expression;
}

type IsExpression extends Expression {
  Byte tag = 37;
  FileOffset fileOffset;
  Byte flags (isForNonNullableByDefault);
  Expression operand;
  DartType type;
}

type AsExpression extends Expression {
  Byte tag = 38;
  FileOffset fileOffset;
  Byte flags (isTypeError,isCovarianceCheck,isForDynamic,isForNonNullableByDefault);
  Expression operand;
  DartType type;
}

type StringLiteral extends Expression {
  Byte tag = 39;
  StringReference value;
}

type IntegerLiteral extends Expression {}

type SpecializedIntLiteral extends IntegerLiteral {
  Byte tag = 144 + N; // Where 0 <= N < 8.
  // Integer literal with value (N - 3), that is, an integer in range -3..4.
}

type PositiveIntLiteral extends IntegerLiteral {
  Byte tag = 55;
  UInt value;
}

type NegativeIntLiteral extends IntegerLiteral {
  Byte tag = 56;
  UInt absoluteValue;
}

type BigIntLiteral extends IntegerLiteral {
  Byte tag = 57;
  StringReference valueString;
}

type DoubleLiteral extends Expression {
  Byte tag = 40;
  Double value;
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
  FileOffset fileOffset;
}

type Throw extends Expression {
  Byte tag = 48;
  FileOffset fileOffset;
  Expression value;
}

type ListLiteral extends Expression {
  Byte tag = 49;
  FileOffset fileOffset;
  DartType typeArgument;
  List<Expression> values;
}

type ConstListLiteral extends Expression {
  Byte tag = 58; // Note: tag is out of order.
  FileOffset fileOffset;
  DartType typeArgument;
  List<Expression> values;
}

type SetLiteral extends Expression {
  Byte tag = 109; // Note: tag is out of order.
  FileOffset fileOffset;
  DartType typeArgument;
  List<Expression> values;
}

type ConstSetLiteral extends Expression {
  Byte tag = 110; // Note: tag is out of order.
  FileOffset fileOffset;
  DartType typeArgument;
  List<Expression> values;
}

type MapLiteral extends Expression {
  Byte tag = 50;
  FileOffset fileOffset;
  DartType keyType;
  DartType valueType;
  List<MapEntry> entries;
}

type ConstMapLiteral extends Expression {
  Byte tag = 59; // Note: tag is out of order.
  FileOffset fileOffset;
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
  FileOffset fileOffset;
  FunctionNode function;
}

type Let extends Expression {
  Byte tag = 53;
  VariableDeclarationPlain variable;
  Expression body;
}

type BlockExpression extends Expression {
  Byte tag = 82;
  List<Statement> body;
  Expression value;
}

type Instantiation extends Expression {
  Byte tag = 54;
  Expression expression;
  List<DartType> typeArguments;
}

type LoadLibrary extends Expression {
  Byte tag = 14;
  LibraryDependencyReference deferredImport;
}

type CheckLibraryIsLoaded extends Expression {
  Byte tag = 13;
  LibraryDependencyReference deferredImport;
}

type ConstantExpression extends Expression {
  Byte tag = 106;
  FileOffset fileOffset;
  DartType type;
  ConstantReference constantReference;
}

abstract type Constant extends Node {
  Byte tag;
}

type NullConstant extends Constant {
  Byte tag = 0;
}

type BoolConstant extends Constant {
  Byte tag = 1;
  Byte value;
}

type IntConstant extends Constant {
  Byte tag = 2;
  IntegerLiteral value;
}

type DoubleConstant extends Constant {
  Byte tag = 3;
  Double value;
}

type StringConstant extends Constant {
  Byte tag = 4;
  StringReference value;
}

type SymbolConstant extends Constant {
  Byte tag = 5;
  LibraryReference library; // May be NullReference.
  StringReference name;
}

type MapConstant extends Constant {
  Byte tag = 6;
  DartType keyType;
  DartType valueType;
  List<Pair<ConstantReference, ConstantReference>> keyValueList;
}

type ListConstant extends Constant {
  Byte tag = 7;
  DartType type;
  List<ConstantReference> values;
}

type SetConstant extends Constant {
  Byte tag = 13; // Note: tag is out of order.
  DartType type;
  List<ConstantReference> values;
}

type InstanceConstant extends Constant {
  Byte tag = 8;
  CanonicalNameReference class;
  List<DartType> typeArguments;
  List<Pair<FieldReference, ConstantReference>> values;
}

type PartialInstantiationConstant extends Constant {
  Byte tag = 9;
  ConstantReference tearOffConstant;
  List<DartType> typeArguments;
}

type TearOffConstant extends Constant {
  Byte tag = 10;
  CanonicalNameReference staticProcedureReference;
}

type TypeLiteralConstant extends Constant {
  Byte tag = 11;
  DartType type;
}

type UnevaluatedConstant extends Constant {
  Byte tag = 12;
  Expression expression;
}

abstract type Statement extends Node {}

type ExpressionStatement extends Statement {
  Byte tag = 61;
  Expression expression;
}

type Block extends Statement {
  Byte tag = 62;
  FileOffset fileOffset;
  FileOffset fileEndOffset;
  List<Statement> statements;
}

type AssertBlock extends Statement {
  Byte tag = 81;
  List<Statement> statements;
}

type EmptyStatement extends Statement {
  Byte tag = 63;
}

type AssertStatement extends Statement {
  Byte tag = 64;
  Expression condition;
  FileOffset conditionStartOffset;
  FileOffset conditionEndOffset;
  Option<Expression> message;
}

type LabeledStatement extends Statement {
  Byte tag = 65;
  Statement body;
}

type BreakStatement extends Statement {
  Byte tag = 66;
  FileOffset fileOffset;

  // Reference to the Nth LabeledStatement in scope, with 0 being the
  // outermost enclosing labeled statement within the same FunctionNode.
  //
  // Labels are not in scope across function boundaries.
  UInt labelIndex;
}

type WhileStatement extends Statement {
  Byte tag = 67;
  FileOffset fileOffset;
  Expression condition;
  Statement body;
}

type DoStatement extends Statement {
  Byte tag = 68;
  FileOffset fileOffset;
  Statement body;
  Expression condition;
}

type ForStatement extends Statement {
  Byte tag = 69;
  FileOffset fileOffset;
  List<VariableDeclarationPlain> variables;
  Option<Expression> condition;
  List<Expression> updates;
  Statement body;
}

type ForInStatement extends Statement {
  Byte tag = 70;
  FileOffset fileOffset;
  FileOffset bodyOffset;
  VariableDeclarationPlain variable;
  Expression iterable;
  Statement body;
}

type AsyncForInStatement extends Statement {
  Byte tag = 80; // Note: tag is out of order.
  FileOffset fileOffset;
  FileOffset bodyOffset;
  VariableDeclarationPlain variable;
  Expression iterable;
  Statement body;
}

type SwitchStatement extends Statement {
  Byte tag = 71;
  FileOffset fileOffset;
  Expression expression;
  List<SwitchCase> cases;
}

type SwitchCase {
  // Note: there is no tag on SwitchCase
  List<Pair<FileOffset, Expression>> expressions;
  Byte isDefault; // 1 if default, 0 is not default.
  Statement body;
}

type ContinueSwitchStatement extends Statement {
  Byte tag = 72;
  FileOffset fileOffset;

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
  FileOffset fileOffset;
  Expression condition;
  Statement then;
  Statement otherwise; // Empty statement if there was no else part.
}

type ReturnStatement extends Statement {
  Byte tag = 74;
  FileOffset fileOffset;
  Option<Expression> expression;
}

type TryCatch extends Statement {
  Byte tag = 75;
  Statement body;
  // "any catch needs a stacktrace" means it has a stacktrace variable.
  Byte flags (anyCatchNeedsStackTrace, isSynthesized);
  List<Catch> catches;
}

type Catch {
  FileOffset fileOffset;
  DartType guard;
  Option<VariableDeclarationPlain> exception;
  Option<VariableDeclarationPlain> stackTrace;
  Statement body;
}

type TryFinally extends Statement {
  Byte tag = 76;
  Statement body;
  Statement finalizer;
}

type YieldStatement extends Statement {
  Byte tag = 77;
  FileOffset fileOffset;
  Byte flags (isYieldStar);
  Expression expression;
}

type VariableDeclaration extends Statement {
  Byte tag = 78;
  VariableDeclarationPlain variable;
}

type VariableDeclarationPlain {
  // The offset for the variable declaration, i.e. the offset of the start of
  // the declaration.
  FileOffset fileOffset;

  // The offset for the equal sign in the declaration (if it contains one).
  // If it does not contain one this should be -1.
  FileOffset fileEqualsOffset;

  List<Expression> annotations;

  Byte flags (isFinal, isConst, isFieldFormal, isCovariant,
              isGenericCovariantImpl, isLate, isRequired, isLowered);
  // For named parameters, this is the parameter name.
  // For other variables, the name is cosmetic, may be empty,
  // and is not necessarily unique.
  StringReference name;
  DartType type;

  // For statements and for-loops, this is the initial value.
  // For optional parameters, this is the default value (if given).
  // In all other contexts, it must be Nothing.
  Option<Expression> initializer;
}

type FunctionDeclaration extends Statement {
  Byte tag = 79;
  FileOffset fileOffset;
  // The variable binding the function.  The variable is in scope
  // within the function for use as a self-reference.
  // Some of the fields in the variable are redundant, but its presence here
  // simplifies the rule for variable indexing.
  VariableDeclarationPlain variable;
  FunctionNode function;
}

enum Nullability { nullable = 0, nonNullable = 1, neither = 2, legacy = 3, }

enum Variance { unrelated = 0, covariant = 1, contravariant = 2, invariant = 3, legacyCovariant = 4, }

abstract type DartType extends Node {}

type BottomType extends DartType {
  Byte tag = 89;
}

type NeverType extends DartType {
  Byte tag = 98;
  Byte nullability; // Index into the Nullability enum above.
}

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
  Byte nullability; // Index into the Nullability enum above.
  ClassReference class;
  List<DartType> typeArguments;
}

type SimpleInterfaceType extends DartType {
  Byte tag = 96; // Note: tag is out of order.
  Byte nullability; // Index into the Nullability enum above.
  ClassReference class;
  // Equivalent to InterfaceType with empty list of type arguments.
}

type FunctionType extends DartType {
  Byte tag = 94;
  Byte nullability; // Index into the Nullability enum above.
  List<TypeParameter> typeParameters;
  UInt requiredParameterCount;
  // positionalParameters.length + namedParameters.length
  UInt totalParameterCount;
  List<DartType> positionalParameters;
  List<NamedDartType> namedParameters;
  Option<TypedefType> typedef;
  DartType returnType;
}

type SimpleFunctionType extends DartType {
  Byte tag = 97; // Note: tag is out of order.
  Byte nullability; // Index into the Nullability enum above.
  List<DartType> positionalParameters;
  DartType returnType;
  // Equivalent to a FunctionType with no type parameters or named parameters,
  // and where all positional parameters are required.
}

type NamedDartType {
  StringReference name;
  DartType type;
  Byte flags (isRequired);
}

type TypeParameterType extends DartType {
  Byte tag = 95;
  Byte nullability; // Index into the Nullability enum above.

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
  Option<DartType> bound;
}

type TypedefType {
  Byte tag = 87;
  Byte nullability; // Index into the Nullability enum above.
  TypedefReference typedefReference;
  List<DartType> typeArguments;
}

type TypeParameter {
  // Note: there is no tag on TypeParameter
  Byte flags (isGenericCovariantImpl);
  List<Expression> annotations;
  Byte variance; // Index into the Variance enum above
  StringReference name; // Cosmetic, may be empty, not unique.
  DartType bound; // 'dynamic' if no explicit bound was given.
  Option<DartType> defaultType; // type used when the parameter is not passed
}

```
