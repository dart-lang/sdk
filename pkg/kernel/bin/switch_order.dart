#!/usr/bin/env dart
// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/binary/tag.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/binary/ast_from_binary.dart';

void main(List<String> args) {
  List<int> sum = List<int>.filled(255, 0);
  List<List<double>> expressionAverages = [];
  List<List<double>> initializerAverages = [];
  List<List<double>> statementAverages = [];
  List<List<double>> typeAverages = [];
  for (String arg in args) {
    if (!new File(arg).existsSync()) {
      print("'$arg' doesn't exist. Skipping.");
      continue;
    }
    List<int> bytes = new File(arg).readAsBytesSync();
    try {
      Component p = new Component();
      WrappedBinaryBuilder wrappedBinaryBuilder =
          new WrappedBinaryBuilder(bytes)..readComponent(p);
      expressionAverages.add(average(wrappedBinaryBuilder.expressionTypes));
      initializerAverages.add(average(wrappedBinaryBuilder.initializerTypes));
      statementAverages.add(average(wrappedBinaryBuilder.statementTypes));
      typeAverages.add(average(wrappedBinaryBuilder.typeTypes));

      sumInto(sum, wrappedBinaryBuilder.expressionTypes);
      sumInto(sum, wrappedBinaryBuilder.initializerTypes);
      sumInto(sum, wrappedBinaryBuilder.statementTypes);
      sumInto(sum, wrappedBinaryBuilder.typeTypes);
    } catch (e) {
      print("Error when reading '$arg'. Dill file expected.\n"
          "Got error: '$e'.\n\n"
          "Skipping.");
      continue;
    }
  }

  printSummary("Expressions: ", expressionAverages, sum);
  print("");
  printSummary("Initializers: ", initializerAverages, sum);
  print("");
  printSummary("Statements: ", statementAverages, sum);
  print("");
  printSummary("Types: ", typeAverages, sum);
}

void printSummary(
    String headline, List<List<double>> data, List<int> totalRead) {
  if (data.isEmpty) {
    print("$headline: No data.");
    return;
  }
  int length = data.first.length;
  List<double> summedPercentages = List<double>.filled(length, 0);
  List<double> minPercentages = List<double>.filled(length, -1);
  List<double> maxPercentages = List<double>.filled(length, -1);
  for (List<double> run in data) {
    assert(run.length == length);
    for (int i = 0; i < length; i++) {
      summedPercentages[i] += run[i];
      if (run[i] < minPercentages[i] || minPercentages[i] < 0) {
        minPercentages[i] = run[i];
      }
      if (run[i] > maxPercentages[i]) {
        maxPercentages[i] = run[i];
      }
    }
  }

  print(headline);
  List<SortableDataString> printMe = [];
  for (int i = 0; i < length; i++) {
    double average = summedPercentages[i] / data.length;
    if (summedPercentages[i] == 0) continue;
    String? tagName = getNameOfTag(i);
    String tagNameExtra = tagName == null ? "" : " ($tagName) ";
    if (minPercentages[i] != maxPercentages[i]) {
      printMe.add(new SortableDataString(
          average,
          "$i$tagNameExtra: ${formatPercent(average)} ("
          "${formatPercent(minPercentages[i])} - "
          "${formatPercent(maxPercentages[i])}) ("
          "${totalRead[i]} totally recorded)."));
    } else {
      printMe.add(new SortableDataString(
          average,
          "$i$tagNameExtra: "
          "${formatPercent(average)} ("
          "${totalRead[i]} totally recorded)."));
    }
  }
  printMe.sort();
  for (int i = printMe.length - 1; i >= 0; i--) {
    SortableDataString entry = printMe[i];
    print(entry.value);
  }
}

class SortableDataString implements Comparable<SortableDataString> {
  final double data;
  final String value;

  SortableDataString(this.data, this.value);

  @override
  String toString() => value;

  @override
  int compareTo(SortableDataString other) => data.compareTo(other.data);
}

String formatPercent(double d) {
  return "${(d * 100).toStringAsFixed(2)}%";
}

List<double> average(List<int> data) {
  final int length = data.length;
  final int sum = data.fold(0, (int soFar, int value) => soFar + value);
  List<double> result = List<double>.filled(length, 0);
  if (sum <= 0) return result;
  for (int i = 0; i < length; i++) {
    int count = data[i];
    if (count > 0) result[i] = count / sum;
  }
  return result;
}

void sumInto(List<int> sumInto, List<int> addThis) {
  if (sumInto.length != addThis.length) throw "Not same size.";
  for (int i = 0; i < sumInto.length; i++) {
    sumInto[i] += addThis[i];
  }
}

class WrappedBinaryBuilder extends BinaryBuilder {
  List<int> expressionTypes = List<int>.filled(255, 0);
  List<int> initializerTypes = List<int>.filled(255, 0);
  List<int> statementTypes = List<int>.filled(255, 0);
  List<int> typeTypes = List<int>.filled(255, 0);

  WrappedBinaryBuilder(var _bytes)
      : super(_bytes,
            disableLazyReading: true,
            disableLazyClassReading: true,
            useGrowableLists: false);

  @override
  Expression readExpression() {
    int tagByte = peekByte();
    int tag = tagByte & Tag.SpecializedTagHighBits == Tag.SpecializedTagHighBits
        ? (tagByte & Tag.SpecializedTagMask)
        : tagByte;
    expressionTypes[tag]++;
    return super.readExpression();
  }

  @override
  Initializer readInitializer() {
    int tagByte = peekByte();
    initializerTypes[tagByte]++;
    return super.readInitializer();
  }

  @override
  Statement readStatement() {
    int tagByte = peekByte();
    statementTypes[tagByte]++;
    return super.readStatement();
  }

  @override
  DartType readDartType({bool forSupertype = false}) {
    int tagByte = peekByte();
    typeTypes[tagByte]++;
    return super.readDartType(forSupertype: forSupertype);
  }
}

String? getNameOfTag(int tag) {
  if (tag == Tag.InvalidInitializer) return "InvalidInitializer";
  if (tag == Tag.FieldInitializer) return "FieldInitializer";
  if (tag == Tag.SuperInitializer) return "SuperInitializer";
  if (tag == Tag.RedirectingInitializer) return "RedirectingInitializer";
  if (tag == Tag.LocalInitializer) return "LocalInitializer";
  if (tag == Tag.AssertInitializer) return "AssertInitializer";

  if (tag == Tag.CheckLibraryIsLoaded) return "CheckLibraryIsLoaded";
  if (tag == Tag.LoadLibrary) return "LoadLibrary";
  if (tag == Tag.EqualsNull) return "EqualsNull";
  if (tag == Tag.EqualsCall) return "EqualsCall";
  if (tag == Tag.StaticTearOff) return "StaticTearOff";
  if (tag == Tag.ConstStaticInvocation) return "ConstStaticInvocation";
  if (tag == Tag.InvalidExpression) return "InvalidExpression";
  if (tag == Tag.VariableGet) return "VariableGet";
  if (tag == Tag.VariableSet) return "VariableSet";
  if (tag == Tag.AbstractSuperPropertyGet) return "AbstractSuperPropertyGet";
  if (tag == Tag.AbstractSuperPropertySet) return "AbstractSuperPropertySet";
  if (tag == Tag.SuperPropertyGet) return "SuperPropertyGet";
  if (tag == Tag.SuperPropertySet) return "SuperPropertySet";
  if (tag == Tag.StaticGet) return "StaticGet";
  if (tag == Tag.StaticSet) return "StaticSet";
  if (tag == Tag.AbstractSuperMethodInvocation) {
    return "AbstractSuperMethodInvocation";
  }
  if (tag == Tag.SuperMethodInvocation) return "SuperMethodInvocation";
  if (tag == Tag.StaticInvocation) return "StaticInvocation";
  if (tag == Tag.ConstructorInvocation) return "ConstructorInvocation";
  if (tag == Tag.ConstConstructorInvocation) {
    return "ConstConstructorInvocation";
  }
  if (tag == Tag.Not) return "Not";
  if (tag == Tag.LogicalExpression) return "LogicalExpression";
  if (tag == Tag.ConditionalExpression) return "ConditionalExpression";
  if (tag == Tag.StringConcatenation) return "StringConcatenation";
  if (tag == Tag.IsExpression) return "IsExpression";
  if (tag == Tag.AsExpression) return "AsExpression";
  if (tag == Tag.StringLiteral) return "StringLiteral";
  if (tag == Tag.DoubleLiteral) return "DoubleLiteral";
  if (tag == Tag.TrueLiteral) return "TrueLiteral";
  if (tag == Tag.FalseLiteral) return "FalseLiteral";
  if (tag == Tag.NullLiteral) return "NullLiteral";
  if (tag == Tag.SymbolLiteral) return "SymbolLiteral";
  if (tag == Tag.TypeLiteral) return "TypeLiteral";
  if (tag == Tag.ThisExpression) return "ThisExpression";
  if (tag == Tag.Rethrow) return "Rethrow";
  if (tag == Tag.Throw) return "Throw";
  if (tag == Tag.ListLiteral) return "ListLiteral";
  if (tag == Tag.MapLiteral) return "MapLiteral";
  if (tag == Tag.AwaitExpression) return "AwaitExpression";
  if (tag == Tag.FunctionExpression) return "FunctionExpression";
  if (tag == Tag.Let) return "Let";
  if (tag == Tag.Instantiation) return "Instantiation";
  if (tag == Tag.PositiveIntLiteral) return "PositiveIntLiteral";
  if (tag == Tag.NegativeIntLiteral) return "NegativeIntLiteral";
  if (tag == Tag.BigIntLiteral) return "BigIntLiteral";
  if (tag == Tag.ConstListLiteral) return "ConstListLiteral";
  if (tag == Tag.ConstMapLiteral) return "ConstMapLiteral";
  if (tag == Tag.ConstructorTearOff) return "ConstructorTearOff";
  if (tag == Tag.BlockExpression) return "BlockExpression";
  if (tag == Tag.TypedefTearOff) return "TypedefTearOff";
  if (tag == Tag.RedirectingFactoryTearOff) return "RedirectingFactoryTearOff";
  if (tag == Tag.RecordIndexGet) return "RecordIndexGet";
  if (tag == Tag.RecordNameGet) return "RecordNameGet";
  if (tag == Tag.RecordLiteral) return "RecordLiteral";
  if (tag == Tag.ConstRecordLiteral) return "ConstRecordLiteral";
  if (tag == Tag.ConstantExpression) return "ConstantExpression";
  if (tag == Tag.SetLiteral) return "SetLiteral";
  if (tag == Tag.ConstSetLiteral) return "ConstSetLiteral";
  if (tag == Tag.ListConcatenation) return "ListConcatenation";
  if (tag == Tag.SetConcatenation) return "SetConcatenation";
  if (tag == Tag.MapConcatenation) return "MapConcatenation";
  if (tag == Tag.InstanceCreation) return "InstanceCreation";
  if (tag == Tag.FileUriExpression) return "FileUriExpression";
  if (tag == Tag.NullCheck) return "NullCheck";
  if (tag == Tag.InstanceGet) return "InstanceGet";
  if (tag == Tag.InstanceSet) return "InstanceSet";
  if (tag == Tag.InstanceInvocation) return "InstanceInvocation";
  if (tag == Tag.InstanceGetterInvocation) return "InstanceGetterInvocation";
  if (tag == Tag.InstanceTearOff) return "InstanceTearOff";
  if (tag == Tag.DynamicGet) return "DynamicGet";
  if (tag == Tag.DynamicSet) return "DynamicSet";
  if (tag == Tag.DynamicInvocation) return "DynamicInvocation";
  if (tag == Tag.FunctionInvocation) return "FunctionInvocation";
  if (tag == Tag.FunctionTearOff) return "FunctionTearOff";
  if (tag == Tag.LocalFunctionInvocation) return "LocalFunctionInvocation";
  if (tag == Tag.SpecializedVariableGet) return "SpecializedVariableGet";
  if (tag == Tag.SpecializedVariableSet) return "SpecializedVariableSet";
  if (tag == Tag.SpecializedIntLiteral) return "SpecializedIntLiteral";

  if (tag == Tag.ExpressionStatement) return "ExpressionStatement";
  if (tag == Tag.Block) return "Block";
  if (tag == Tag.EmptyStatement) return "EmptyStatement";
  if (tag == Tag.AssertStatement) return "AssertStatement";
  if (tag == Tag.LabeledStatement) return "LabeledStatement";
  if (tag == Tag.BreakStatement) return "BreakStatement";
  if (tag == Tag.WhileStatement) return "WhileStatement";
  if (tag == Tag.DoStatement) return "DoStatement";
  if (tag == Tag.ForStatement) return "ForStatement";
  if (tag == Tag.ForInStatement) return "ForInStatement";
  if (tag == Tag.SwitchStatement) return "SwitchStatement";
  if (tag == Tag.ContinueSwitchStatement) return "ContinueSwitchStatement";
  if (tag == Tag.IfStatement) return "IfStatement";
  if (tag == Tag.ReturnStatement) return "ReturnStatement";
  if (tag == Tag.TryCatch) return "TryCatch";
  if (tag == Tag.TryFinally) return "TryFinally";
  if (tag == Tag.YieldStatement) return "YieldStatement";
  if (tag == Tag.VariableDeclaration) return "VariableDeclaration";
  if (tag == Tag.FunctionDeclaration) return "FunctionDeclaration";
  if (tag == Tag.AsyncForInStatement) return "AsyncForInStatement";
  if (tag == Tag.AssertBlock) return "AssertBlock";

  if (tag == Tag.TypedefType) return "TypedefType";
  if (tag == Tag.InvalidType) return "InvalidType";
  if (tag == Tag.DynamicType) return "DynamicType";
  if (tag == Tag.VoidType) return "VoidType";
  if (tag == Tag.InterfaceType) return "InterfaceType";
  if (tag == Tag.FunctionType) return "FunctionType";
  if (tag == Tag.TypeParameterType) return "TypeParameterType";
  if (tag == Tag.SimpleInterfaceType) return "SimpleInterfaceType";
  if (tag == Tag.SimpleFunctionType) return "SimpleFunctionType";
  if (tag == Tag.NeverType) return "NeverType";
  if (tag == Tag.IntersectionType) return "IntersectionType";
  if (tag == Tag.RecordType) return "RecordType";
  if (tag == Tag.ExtensionType) return "ExtensionType";

  return null;
}
