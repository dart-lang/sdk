// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.binary.tag;

class Tag {
  static const int Nothing = 0;
  static const int Something = 1;

  static const int Class = 2;

  static const int FunctionNode = 3;

  static const int Field = 4;
  static const int Constructor = 5;
  static const int Procedure = 6;

  static const int InvalidInitializer = 7;
  static const int FieldInitializer = 8;
  static const int SuperInitializer = 9;
  static const int RedirectingInitializer = 10;
  static const int LocalInitializer = 11;

  static const int CheckLibraryIsLoaded = 13;
  static const int LoadLibrary = 14;
  static const int DirectPropertyGet = 15;
  static const int DirectPropertySet = 16;
  static const int DirectMethodInvocation = 17;
  static const int ConstStaticInvocation = 18;
  static const int InvalidExpression = 19;
  static const int VariableGet = 20;
  static const int VariableSet = 21;
  static const int PropertyGet = 22;
  static const int PropertySet = 23;
  static const int SuperPropertyGet = 24;
  static const int SuperPropertySet = 25;
  static const int StaticGet = 26;
  static const int StaticSet = 27;
  static const int MethodInvocation = 28;
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
  static const int PositiveIntLiteral = 55;
  static const int NegativeIntLiteral = 56;
  static const int BigIntLiteral = 57;
  static const int ConstListLiteral = 58;
  static const int ConstMapLiteral = 59;

  static const int InvalidStatement = 60;
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

  static const int TypedefType = 87;
  static const int VectorType = 88;
  static const int BottomType = 89;
  static const int InvalidType = 90;
  static const int DynamicType = 91;
  static const int VoidType = 92;
  static const int InterfaceType = 93;
  static const int FunctionType = 94;
  static const int TypeParameterType = 95;
  static const int SimpleInterfaceType = 96;
  static const int SimpleFunctionType = 97;

  static const int NullReference = 99;
  static const int ClassReference = 100;
  static const int MemberReference = 101;

  static const int VectorCreation = 102;
  static const int VectorGet = 103;
  static const int VectorSet = 104;
  static const int VectorCopy = 105;

  static const int ClosureCreation = 106;

  static const int SpecializedTagHighBit = 0x80; // 10000000
  static const int SpecializedTagMask = 0xF8; // 11111000
  static const int SpecializedPayloadMask = 0x7; // 00000111

  static const int SpecializedVariableGet = 128;
  static const int SpecializedVariableSet = 136;
  static const int SpecializedIntLiteral = 144;

  static const int SpecializedIntLiteralBias = 3;

  static const int ProgramFile = 0x90ABCDEF;

  /// Internal version of kernel binary format.
  /// Bump it when making incompatible changes in kernel binaries.
  /// Keep in sync with runtime/vm/kernel_binary.h.
  static const int BinaryFormatVersion = 1;
}
