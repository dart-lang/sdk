// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.binary.tag;

class Tag {
  static const int Nothing = 0;
  static const int Something = 1;

  static const int Class = 2;
  static const int Extension = 115;
  static const int InlineClass = 85;

  static const int FunctionNode = 3;

  // Members
  static const int Field = 4;
  static const int Constructor = 5;
  static const int Procedure = 6;

  // Initializers
  static const int InvalidInitializer = 7;
  static const int FieldInitializer = 8;
  static const int SuperInitializer = 9;
  static const int RedirectingInitializer = 10;
  static const int LocalInitializer = 11;
  static const int AssertInitializer = 12;

  // Expressions
  static const int CheckLibraryIsLoaded = 13;
  static const int LoadLibrary = 14;
  static const int EqualsNull = 15;
  static const int EqualsCall = 16;
  static const int StaticTearOff = 17;
  static const int ConstStaticInvocation = 18;
  static const int InvalidExpression = 19;
  static const int VariableGet = 20;
  static const int VariableSet = 21;
  static const int AbstractSuperPropertyGet = 22;
  static const int AbstractSuperPropertySet = 23;
  static const int SuperPropertyGet = 24;
  static const int SuperPropertySet = 25;
  static const int StaticGet = 26;
  static const int StaticSet = 27;
  static const int AbstractSuperMethodInvocation = 28;
  static const int SuperMethodInvocation = 29;
  static const int StaticInvocation = 30;
  static const int ConstructorInvocation = 31;
  static const int ConstConstructorInvocation = 32;
  static const int Not = 33;
  static const int LogicalExpression = 34;
  static const int ConditionalExpression = 35;
  static const int StringConcatenation = 36;
  static const int IsExpression = 37;
  static const int AsExpression = 38;
  static const int StringLiteral = 39;
  static const int DoubleLiteral = 40;
  static const int TrueLiteral = 41;
  static const int FalseLiteral = 42;
  static const int NullLiteral = 43;
  static const int SymbolLiteral = 44;
  static const int TypeLiteral = 45;
  static const int ThisExpression = 46;
  static const int Rethrow = 47;
  static const int Throw = 48;
  static const int ListLiteral = 49;
  static const int MapLiteral = 50;
  static const int AwaitExpression = 51;
  static const int FunctionExpression = 52;
  static const int Let = 53;
  static const int Instantiation = 54;
  static const int PositiveIntLiteral = 55;
  static const int NegativeIntLiteral = 56;
  static const int BigIntLiteral = 57;
  static const int ConstListLiteral = 58;
  static const int ConstMapLiteral = 59;
  static const int ConstructorTearOff = 60;
  // 61-81 are occupied by various [Statement]s
  static const int BlockExpression = 82;
  static const int TypedefTearOff = 83;
  static const int RedirectingFactoryTearOff = 84;
  // 85 is occupied by [InlineClass].

  static const int RecordIndexGet = 101;
  static const int RecordNameGet = 102;
  static const int RecordLiteral = 104;
  static const int ConstRecordLiteral = 105;
  static const int ConstantExpression = 106;
  static const int SetLiteral = 109;
  static const int ConstSetLiteral = 110;
  static const int ListConcatenation = 111;
  static const int SetConcatenation = 112;
  static const int MapConcatenation = 113;
  static const int InstanceCreation = 114;
  // 115 is occupied by [Extension].
  static const int FileUriExpression = 116;

  static const int NullCheck = 117;
  static const int InstanceGet = 118;
  static const int InstanceSet = 119;
  static const int InstanceInvocation = 120;
  static const int InstanceGetterInvocation = 89;
  static const int InstanceTearOff = 121;
  static const int DynamicGet = 122;
  static const int DynamicSet = 123;
  static const int DynamicInvocation = 124;
  static const int FunctionInvocation = 125;
  static const int FunctionTearOff = 126;
  static const int LocalFunctionInvocation = 127;

  // Statements
  static const int ExpressionStatement = 61;
  static const int Block = 62;
  static const int EmptyStatement = 63;
  static const int AssertStatement = 64;
  static const int LabeledStatement = 65;
  static const int BreakStatement = 66;
  static const int WhileStatement = 67;
  static const int DoStatement = 68;
  static const int ForStatement = 69;
  static const int ForInStatement = 70;
  static const int SwitchStatement = 71;
  static const int ContinueSwitchStatement = 72;
  static const int IfStatement = 73;
  static const int ReturnStatement = 74;
  static const int TryCatch = 75;
  static const int TryFinally = 76;
  static const int YieldStatement = 77;
  static const int VariableDeclaration = 78;
  static const int FunctionDeclaration = 79;
  static const int AsyncForInStatement = 80;
  static const int AssertBlock = 81;
  // 82 is occupied by [BlockExpression] (expression).
  // 83 is occupied by [TypedefTearOff] (expression).
  // 84 is occupied by [RedirectingFactoryTearOff] (expression).
  // 85 is occupied by [InlineClass].

  // Types
  static const int TypedefType = 87;
  // 89 is occupied by [InstanceGetterInvocation] (expression).
  static const int InvalidType = 90;
  static const int DynamicType = 91;
  static const int VoidType = 92;
  static const int InterfaceType = 93;
  static const int FunctionType = 94;
  static const int TypeParameterType = 95;
  static const int SimpleInterfaceType = 96;
  static const int SimpleFunctionType = 97;
  static const int NeverType = 98;
  static const int IntersectionType = 99;
  static const int RecordType = 100;
  // 101 is occupied by [RecordIndexGet] (expression).
  // 102 is occupied by [RecordNameGet] (expression).
  static const int InlineType = 103;

  // 104 is occupied by [RecordLiteral] (expression).
  // 105 is occupied by [ConstRecordLiteral] (expression).
  // 106 is occupied by [ConstantExpression].
  static const int FutureOrType = 107;

  // 108 is occupied by [RedirectingFactory] (member).
  // 109 is occupied by [SetLiteral] (expression).
  // 110 is occupied by [ConstSetLiteral] (expression).
  // 111 is occupied by [ListConcatenation] (expression).
  // 112 is occupied by [SetConcatenation] (expression).
  // 113 is occupied by [MapConcatenation] (expression).
  // 114 is occupied by [InstanceCreation] (expression).
  // 115 is occupied by [Extension].
  // 116 is occupied by [FileUriExpression] (expression).
  // 117 is occupied by [NullCheck] (expression).
  // 118 is occupied by [InstanceGet] (expression).
  // 119 is occupied by [InstanceSet] (expression).
  // 120 is occupied by [InstanceInvocation] (expression).
  // 121 is occupied by [InstanceTearOff] (expression).
  // 122 is occupied by [DynamicGet] (expression).
  // 123 is occupied by [DynamicSet] (expression).
  // 124 is occupied by [DynamicInvocation] (expression).
  // 125 is occupied by [FunctionInvocation] (expression).
  // 126 is occupied by [FunctionTearOff] (expression).
  // 127 is occupied by [LocalFunctionInvocation] (expression).

  // Patterns and patterns-related nodes
  static const int AndPattern = 128;
  static const int AssignedVariablePattern = 129;
  static const int CastPattern = 130;
  static const int ConstantPattern = 131;
  static const int InvalidPattern = 132;
  static const int ListPattern = 133;
  static const int MapPattern = 134;
  static const int NamedPattern = 135;
  static const int NullAssertPattern = 136;
  static const int NullCheckPattern = 137;
  static const int ObjectPattern = 138;
  static const int OrPattern = 139;
  static const int RecordPattern = 140;
  static const int RelationalPattern = 141;
  static const int RestPattern = 142;
  static const int VariablePattern = 143;
  static const int WildcardPattern = 144;
  static const int MapPatternEntry = 145;
  static const int MapPatternRestEntry = 146;
  static const int PatternSwitchStatement = 147;
  static const int SwitchExpression = 148;
  static const int IfCaseStatement = 149;
  static const int PatternAssignment = 150;
  static const int PatternVariableDeclaration = 151;

  static const int NullType = 152;

  static const int SpecializedTagHighBits = 0xE0; // 0b11100000
  static const int SpecializedTagMask = 0xF8; //    0b11111000
  static const int SpecializedPayloadMask = 0x7; // 0b00000111

  static const int SpecializedVariableGet = 224; // 0b11100000
  static const int SpecializedVariableSet = 232; // 0b11101000
  static const int SpecializedIntLiteral = 240; //  0b11110000
  // TODO: There's space for another special here (248, 0b11111000)

  static const int SpecializedIntLiteralBias = 3;

  static const int ComponentFile = 0x90ABCDEF;

  /// Internal version of kernel binary format.
  /// Bump it when making incompatible changes in kernel binaries.
  /// Keep in sync with runtime/vm/kernel_binary.h, pkg/kernel/binary.md.
  static const int BinaryFormatVersion = 105;
}

abstract class ConstantTag {
  static const int NullConstant = 0;
  static const int BoolConstant = 1;
  static const int IntConstant = 2;
  static const int DoubleConstant = 3;
  static const int StringConstant = 4;
  static const int SymbolConstant = 5;
  static const int MapConstant = 6;
  static const int ListConstant = 7;
  static const int SetConstant = 13;
  static const int InstanceConstant = 8;
  static const int InstantiationConstant = 9;
  static const int StaticTearOffConstant = 10;
  static const int TypeLiteralConstant = 11;
  static const int UnevaluatedConstant = 12;
  // 13 is occupied by [SetConstant]
  static const int TypedefTearOffConstant = 14;
  static const int ConstructorTearOffConstant = 15;
  static const int RedirectingFactoryTearOffConstant = 16;
  static const int RecordConstant = 17;
}

const int sdkHashLength = 10; // Bytes, a Git "short hash".

const String sdkHashNull = '0000000000';

// Will be correct hash for Flutter SDK / Dart SDK we distribute.
// If non-null we will validate when consuming kernel, will use when producing
// kernel.
// If null, local development setting (e.g. run gen_kernel.dart from source),
// we put 0x00..00 into when producing, do not validate when consuming.
String get expectedSdkHash {
  final String sdkHash =
      const String.fromEnvironment('sdk_hash', defaultValue: sdkHashNull);
  if (sdkHash.length != sdkHashLength) {
    throw '-Dsdk_hash=<hash> must be a ${sdkHashLength} byte string!';
  }
  return sdkHash;
}

bool isValidSdkHash(String sdkHash) {
  return (sdkHash == sdkHashNull ||
      expectedSdkHash == sdkHashNull ||
      sdkHash == expectedSdkHash);
}
