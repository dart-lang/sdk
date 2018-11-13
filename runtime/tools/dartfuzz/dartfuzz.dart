// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';

// Version of DartFuzz. Increase this each time changes are made
// to preserve the property that a given version of DartFuzz yields
// the same fuzzed program for a deterministic random seed.
const String version = '1.2';

// Restriction on statement and expression depths.
const int stmtDepth = 5;
const int exprDepth = 2;

// Interesting integer values.
const List<int> interestingIntegers = [
  0x0000000000000000,
  0x0000000000000001,
  0x000000007fffffff,
  0x0000000080000000,
  0x0000000080000001,
  0x00000000ffffffff,
  0x0000000100000000,
  0x0000000100000001,
  0x000000017fffffff,
  0x0000000180000000,
  0x0000000180000001,
  0x00000001ffffffff,
  0x7fffffff00000000,
  0x7fffffff00000001,
  0x7fffffff7fffffff,
  0x7fffffff80000000,
  0x7fffffff80000001,
  0x7fffffffffffffff,
  0x8000000000000000,
  0x8000000000000001,
  0x800000007fffffff,
  0x8000000080000000,
  0x8000000080000001,
  0x80000000ffffffff,
  0x8000000100000000,
  0x8000000100000001,
  0x800000017fffffff,
  0x8000000180000000,
  0x8000000180000001,
  0x80000001ffffffff,
  0xffffffff00000000,
  0xffffffff00000001,
  0xffffffff7fffffff,
  0xffffffff80000000,
  0xffffffff80000001,
  0xffffffffffffffff
];

// Interesting characters.
const interestingChars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#&()+- ';

// Class that represents Dart types.
class DartType {
  final String name;

  const DartType._withName(this.name);

  static const VOID = const DartType._withName('void');
  static const BOOL = const DartType._withName('bool');
  static const INT = const DartType._withName('int');
  static const DOUBLE = const DartType._withName('double');
  static const STRING = const DartType._withName('String');
  static const INT_LIST = const DartType._withName('List<int>');
  static const INT_STRING_MAP = const DartType._withName('Map<int, String>');
}

// All value types.
const allTypes = [
  DartType.BOOL,
  DartType.INT,
  DartType.DOUBLE,
  DartType.STRING,
  DartType.INT_LIST,
  DartType.INT_STRING_MAP
];

// Class that represents Dart library methods.
class DartLib {
  final String name;
  final List<DartType> proto;
  const DartLib(this.name, this.proto);
}

// Naming conventions.
const varName = 'var';
const paramName = 'par';
const localName = 'loc';
const fieldName = 'fld';
const methodName = 'foo';

/// Class that generates a random, but runnable Dart program for fuzz testing.
class DartFuzz {
  DartFuzz(this.seed, this.file);

  void run() {
    // Initialize program variables.
    rand = new Random(seed);
    indent = 0;
    currentClass = null;
    currentMethod = null;
    // Setup the types.
    localVars = new List<DartType>();
    globalVars = fillTypes1();
    globalVars.addAll(allTypes); // always one each
    globalMethods = fillTypes2();
    classFields = fillTypes2();
    classMethods = fillTypes3(classFields.length);
    // Generate.
    emitHeader();
    emitVarDecls(varName, globalVars);
    emitMethods(methodName, globalMethods);
    emitClasses();
    emitMain();
    // Sanity.
    assert(currentClass == null);
    assert(currentMethod == null);
    assert(indent == 0);
    assert(localVars.length == 0);
  }

  //
  // Program components.
  //

  void emitHeader() {
    emitLn('// The Dart Project Fuzz Tester ($version).');
    emitLn('// Program generated as:');
    emitLn('//   dart dartfuzz.dart --seed $seed');
  }

  void emitMethods(String name, List<List<DartType>> methods) {
    for (int i = 0; i < methods.length; i++) {
      List<DartType> method = methods[i];
      currentMethod = i;
      emitLn('${method[0].name} $name$i(', newline: false);
      emitParDecls(method);
      emit(') {', newline: true);
      indent += 2;
      assert(localVars.length == 0);
      if (emitStatements(0)) {
        emitReturn();
      }
      assert(localVars.length == 0);
      indent -= 2;
      emitLn('}');
      emit('', newline: true);
      currentMethod = null;
    }
  }

  void emitClasses() {
    assert(classFields.length == classMethods.length);
    for (int i = 0; i < classFields.length; i++) {
      currentClass = i;
      emitLn('class X$i ${i == 0 ? "" : "extends X${i - 1}"} {');
      indent += 2;
      emitVarDecls('$fieldName${i}_', classFields[i]);
      emitMethods('$methodName${i}_', classMethods[i]);
      emitLn('void run() {');
      indent += 2;
      if (i > 0) {
        emitLn('super.run();');
      }
      assert(localVars.length == 0);
      emitStatements(0);
      assert(localVars.length == 0);
      indent -= 2;
      emitLn('}');
      indent -= 2;
      emitLn('}');
      emit('', newline: true);
      currentClass = null;
    }
  }

  void emitMain() {
    emitLn('main() {');
    indent += 2;
    emitLn('try {');
    indent += 2;
    emitLn('new X${classFields.length - 1}().run();');
    indent -= 2;
    emitLn('} catch (e) {');
    indent += 2;
    emitLn("print('throws');");
    indent -= 2;
    emitLn('} finally {');
    indent += 2;
    emitLn("print('", newline: false);
    for (int i = 0; i < globalVars.length; i++) {
      emit('\$$varName$i\\n');
    }
    emit("');", newline: true);
    indent -= 2;
    emitLn('}');
    indent -= 2;
    emitLn('}');
  }

  //
  // Declarations.
  //

  void emitVarDecls(String name, List<DartType> vars) {
    emit('', newline: true);
    for (int i = 0; i < vars.length; i++) {
      DartType tp = vars[i];
      emitLn('${tp.name} $name$i = ', newline: false);
      emitLiteral(tp);
      emit(';', newline: true);
    }
    emit('', newline: true);
  }

  void emitParDecls(List<DartType> pars) {
    for (int i = 1; i < pars.length; i++) {
      DartType tp = pars[i];
      emit('${tp.name} $paramName$i');
      if (i != (pars.length - 1)) {
        emit(', ');
      }
    }
  }

  //
  // Statements.
  //

  // Emit an assignment statement.
  bool emitAssign() {
    DartType tp = getType();
    emitLn('', newline: false);
    emitVar(tp);
    emitAssignOp(tp);
    emitExpr(0, tp);
    emit(';', newline: true);
    return true;
  }

  // Emit a print statement.
  bool emitPrint() {
    DartType tp = getType();
    emitLn('print(', newline: false);
    emitExpr(0, tp);
    emit(');', newline: true);
    return true;
  }

  // Emit a return statement.
  bool emitReturn() {
    List<DartType> proto = getCurrentProto();
    if (proto == null) {
      emitLn('return;');
    } else {
      emitLn('return ', newline: false);
      emitExpr(0, proto[0]);
      emit(';', newline: true);
    }
    return false;
  }

  // Emit a one-way if statement.
  bool emitIf1(int depth) {
    emitLn('if (', newline: false);
    emitExpr(0, DartType.BOOL);
    emit(') {', newline: true);
    indent += 2;
    bool b = emitStatements(depth + 1);
    indent -= 2;
    emitLn('}');
    return b;
  }

  // Emit a two-way if statement.
  bool emitIf2(int depth) {
    emitLn('if (', newline: false);
    emitExpr(0, DartType.BOOL);
    emit(') {', newline: true);
    indent += 2;
    bool b1 = emitStatements(depth + 1);
    indent -= 2;
    emitLn('} else {');
    indent += 2;
    bool b2 = emitStatements(depth + 1);
    indent -= 2;
    emitLn('}');
    return b1 || b2;
  }

  // Emit a simple increasing for-loop.
  bool emitFor(int depth) {
    int i = localVars.length;
    emitLn('for (int $localName$i = 0; $localName$i < ', newline: false);
    emitSmallPositiveInt();
    emit('; $localName$i++) {', newline: true);
    indent += 2;
    localVars.add(DartType.INT);
    bool b = emitStatements(depth + 1);
    localVars.removeLast();
    indent -= 2;
    emitLn('}');
    return b;
  }

  // Emit a new program scope that introduces a new local variable.
  bool emitScope(int depth) {
    DartType tp = getType();
    emitLn('{ ${tp.name} $localName${localVars.length} = ', newline: false);
    emitExpr(0, tp);
    emit(';', newline: true);
    indent += 2;
    localVars.add(tp);
    bool b = emitStatements(depth + 1);
    localVars.removeLast();
    indent -= 2;
    emitLn('}');
    return b;
  }

  // Emit a statement. Returns true if code may fall-through.
  // TODO: add many more constructs
  bool emitStatement(int depth) {
    // Continuing nested statements becomes less likely as the depth grows.
    if (rand.nextInt(depth + 1) > stmtDepth) {
      return emitAssign();
    }
    // Possibly nested statement.
    switch (rand.nextInt(8)) {
      // favors assignment
      case 0:
        return emitIf1(depth);
      case 1:
        return emitIf2(depth);
      case 2:
        return emitFor(depth);
      case 3:
        return emitScope(depth);
      case 4:
        return emitPrint();
      case 5:
        return emitReturn();
      default:
        return emitAssign();
    }
  }

  // Emit statements. Returns true if code may fall-through.
  bool emitStatements(int depth) {
    int s = 1 + rand.nextInt(4);
    for (int i = 0; i < s; i++) {
      if (!emitStatement(depth)) {
        return false; // rest would be dead code
      }
    }
    return true;
  }

  //
  // Expressions.
  //

  void emitBool() {
    emit(rand.nextInt(2) == 0 ? 'true' : 'false');
  }

  void emitSmallPositiveInt() {
    emit('${rand.nextInt(100)}');
  }

  void emitSmallNegativeInt() {
    emit('-${rand.nextInt(100)}');
  }

  void emitInt() {
    switch (rand.nextInt(4)) {
      // favors small positive int
      case 0:
        emit(
            '${interestingIntegers[rand.nextInt(interestingIntegers.length)]}');
        break;
      case 1:
        emitSmallNegativeInt();
        break;
      default:
        emitSmallPositiveInt();
        break;
    }
  }

  void emitDouble() {
    switch (rand.nextInt(7)) {
      // favors small double
      case 0:
        emit('double.infinity');
        break;
      case 1:
        emit('double.maxFinite');
        break;
      case 2:
        emit('double.minPositive');
        break;
      case 3:
        emit('double.nan');
        break;
      case 4:
        emit('double.negativeInfinity');
        break;
      default:
        emit('${rand.nextDouble()}');
        break;
    }
  }

  void emitChar() {
    switch (rand.nextInt(10)) {
      // favors regular char
      case 0:
        emit('\\u2665');
        break;
      case 1:
        emit('\\u{1f600}'); // rune
        break;
      default:
        emit(interestingChars[rand.nextInt(interestingChars.length)]);
        break;
    }
  }

  void emitString() {
    emit("'");
    int l = rand.nextInt(8);
    for (int i = 0; i < l; i++) {
      emitChar();
    }
    emit("'");
  }

  void emitIntList() {
    emit('[ ');
    int l = 1 + rand.nextInt(4);
    for (int i = 0; i < l; i++) {
      emitInt();
      if (i != (l - 1)) {
        emit(', ');
      }
    }
    emit(' ]');
  }

  void emitIntStringMap() {
    emit('{ ');
    int l = 1 + rand.nextInt(4);
    for (int i = 0; i < l; i++) {
      emit('$i : ');
      emitString();
      if (i != (l - 1)) {
        emit(', ');
      }
    }
    emit(' }');
  }

  void emitLiteral(DartType tp) {
    if (tp == DartType.BOOL) {
      emitBool();
    } else if (tp == DartType.INT) {
      emitInt();
    } else if (tp == DartType.DOUBLE) {
      emitDouble();
    } else if (tp == DartType.STRING) {
      emitString();
    } else if (tp == DartType.INT_LIST) {
      emitIntList();
    } else if (tp == DartType.INT_STRING_MAP) {
      emitIntStringMap();
    } else {
      assert(false);
    }
  }

  void emitScalarVar(DartType tp) {
    // Collect all choices from globals, fields, locals, and parameters.
    List<String> choices = new List<String>();
    for (int i = 0; i < globalVars.length; i++) {
      if (tp == globalVars[i]) choices.add('$varName$i');
    }
    for (int i = 0; i < localVars.length; i++) {
      if (tp == localVars[i]) choices.add('$localName$i');
    }
    List<DartType> fields = getCurrentFields();
    if (fields != null) {
      for (int i = 0; i < fields.length; i++) {
        if (tp == fields[i]) choices.add('$fieldName${currentClass}_$i');
      }
    }
    List<DartType> proto = getCurrentProto();
    if (proto != null) {
      for (int i = 1; i < proto.length; i++) {
        if (tp == proto[i]) choices.add('$paramName$i');
      }
    }
    // Then pick one.
    assert(choices.length > 0);
    emit('${choices[rand.nextInt(choices.length)]}');
  }

  void emitVar(DartType tp) {
    // TODO: add subscripted var
    emitScalarVar(tp);
  }

  void emitTerminal(DartType tp) {
    switch (rand.nextInt(2)) {
      case 0:
        emitLiteral(tp);
        break;
      default:
        emitVar(tp);
        break;
    }
  }

  void emitExprList(int depth, List<DartType> proto) {
    emit('(');
    for (int i = 1; i < proto.length; i++) {
      emitExpr(depth, proto[i]);
      if (i != (proto.length - 1)) {
        emit(', ');
      }
    }
    emit(')');
  }

  // Emit expression with unary operator: (~(x))
  void emitUnaryExpr(int depth, DartType tp) {
    if (tp == DartType.BOOL || tp == DartType.INT || tp == DartType.DOUBLE) {
      emit('(');
      emitUnaryOp(tp);
      emit('(');
      emitExpr(depth + 1, tp);
      emit('))');
    } else {
      emitTerminal(tp); // resort to terminal
    }
  }

  // Emit expression with binary operator: (x + y)
  void emitBinaryExpr(int depth, DartType tp) {
    if (tp == DartType.BOOL) {
      // For boolean, allow type switch with relational op.
      if (rand.nextInt(2) == 0) {
        DartType deeper_tp = getType();
        emit('(');
        emitExpr(depth + 1, deeper_tp);
        emitRelOp(deeper_tp);
        emitExpr(depth + 1, deeper_tp);
        emit(')');
        return;
      }
    }
    emit('(');
    emitExpr(depth + 1, tp);
    emitBinaryOp(tp);
    emitExpr(depth + 1, tp);
    emit(')');
  }

  // Emit expression with ternary operator: (b ? x : y)
  void emitTernaryExpr(int depth, DartType tp) {
    emit('(');
    emitExpr(depth + 1, DartType.BOOL);
    emit(' ? ');
    emitExpr(depth + 1, tp);
    emit(' : ');
    emitExpr(depth + 1, tp);
    emit(')');
  }

  // Emit expression with pre/post-increment/decrement operator: (x++)
  void emitPreOrPostExpr(int depth, DartType tp) {
    if (tp == DartType.INT) {
      int r = rand.nextInt(2);
      emit('(');
      if (r == 0) emitPreOrPostOp(tp);
      emitScalarVar(tp);
      if (r == 1) emitPreOrPostOp(tp);
      emit(')');
    } else {
      emitTerminal(tp); // resort to terminal
    }
  }

  // Emit library call.
  void emitLibraryCall(int depth, DartType tp) {
    if (tp == DartType.INT_STRING_MAP) {
      emitTerminal(tp); // resort to terminal
      return;
    }
    DartLib lib = oneOf(getLibrary(tp));
    List<DartType> proto = lib.proto;
    // Receiver.
    if (proto[0] != null) {
      DartType deeper_tp = proto[0];
      emit('(');
      emitExpr(depth + 1, deeper_tp);
      emit(').');
    }
    // Call.
    emit('${lib.name}');
    // Parameters.
    if (proto.length == 1) {
      emit('()');
    } else if (proto[1] != null) {
      emitExprList(depth + 1, proto);
    }
  }

  // Helper for a method call.
  bool pickedCall(
      int depth, DartType tp, String name, List<List<DartType>> protos, int m) {
    for (int i = m - 1; i >= 0; i--) {
      if (tp == protos[i][0]) {
        emit('$name$i');
        emitExprList(depth + 1, protos[i]);
        return true;
      }
    }
    return false;
  }

  // Emit method call within the program.
  void emitMethodCall(int depth, DartType tp) {
    // Only call backward to avoid infinite recursion.
    if (currentClass == null) {
      // Outside a class: call backward in global methods.
      if (pickedCall(depth, tp, methodName, globalMethods, currentMethod)) {
        return;
      }
    } else {
      // Inside a class: try to call backwards in class methods first.
      int m1 = currentMethod == null
          ? classMethods[currentClass].length
          : currentMethod;
      int m2 = globalMethods.length;
      if (pickedCall(depth, tp, '$methodName${currentClass}_',
              classMethods[currentClass], m1) ||
          pickedCall(depth, tp, methodName, globalMethods, m2)) {
        return;
      }
    }
    emitTerminal(tp); // resort to terminal.
  }

  // Emit expression.
  void emitExpr(int depth, DartType tp) {
    // Continuing nested expressions becomes less likely as the depth grows.
    if (rand.nextInt(depth + 1) > exprDepth) {
      emitTerminal(tp);
      return;
    }
    // Possibly nested expression.
    switch (rand.nextInt(7)) {
      case 0:
        emitUnaryExpr(depth, tp);
        break;
      case 1:
        emitBinaryExpr(depth, tp);
        break;
      case 2:
        emitTernaryExpr(depth, tp);
        break;
      case 3:
        emitPreOrPostExpr(depth, tp);
        break;
      case 4:
        emitLibraryCall(depth, tp);
        break;
      case 5:
        emitMethodCall(depth, tp);
        break;
      default:
        emitTerminal(tp);
        break;
    }
  }

  //
  // Operators.
  //

  // Emit same type in-out assignment operator.
  void emitAssignOp(DartType tp) {
    if (tp == DartType.INT) {
      emit(oneOf(const <String>[
        ' += ',
        ' -= ',
        ' *= ',
        ' ~/= ',
        ' %= ',
        ' &= ',
        ' |= ',
        ' ^= ',
        ' >>= ',
        ' <<= ',
        ' ??= ',
        ' = '
      ]));
    } else if (tp == DartType.DOUBLE) {
      emit(oneOf(
          const <String>[' += ', ' -= ', ' *= ', ' /= ', ' ??= ', ' = ']));
    } else {
      emit(oneOf(const <String>[' ??= ', ' = ']));
    }
  }

  // Emit same type in-out unary operator.
  void emitUnaryOp(DartType tp) {
    if (tp == DartType.BOOL) {
      emit('!');
    } else if (tp == DartType.INT) {
      emit(oneOf(const <String>['-', '~']));
    } else if (tp == DartType.DOUBLE) {
      emit('-');
    } else {
      assert(false);
    }
  }

  // Emit same type in-out binary operator.
  void emitBinaryOp(DartType tp) {
    if (tp == DartType.BOOL) {
      emit(oneOf(const <String>[' && ', ' || ']));
    } else if (tp == DartType.INT) {
      emit(oneOf(const <String>[
        ' + ',
        ' - ',
        ' * ',
        ' ~/ ',
        ' % ',
        ' & ',
        ' | ',
        ' ^ ',
        ' >> ',
        ' << ',
        ' ?? '
      ]));
    } else if (tp == DartType.DOUBLE) {
      emit(oneOf(const <String>[' + ', ' - ', ' * ', ' / ', ' ?? ']));
    } else if (tp == DartType.STRING || tp == DartType.INT_LIST) {
      emit(oneOf(const <String>[' + ', ' ?? ']));
    } else {
      emit(' ?? ');
    }
  }

  // Emit same type in-out increment operator.
  void emitPreOrPostOp(DartType tp) {
    if (tp == DartType.INT) {
      emit(oneOf(const <String>['++', '--']));
    } else {
      assert(false);
    }
  }

  // Emit one type in, boolean out operator.
  void emitRelOp(DartType tp) {
    if (tp == DartType.INT || tp == DartType.DOUBLE) {
      emit(oneOf(const <String>[' > ', ' >= ', ' < ', ' <= ', ' != ', ' == ']));
    } else {
      emit(oneOf(const <String>[' != ', ' == ']));
    }
  }

  //
  // Library methods.
  //

  // Get list of library methods, organized by return type.
  // Proto list:
  //   [ receiver-type (null denotes none),
  //     param1 type (null denotes getter),
  //     param2 type,
  //     ...
  //   ]
  List<DartLib> getLibrary(DartType tp) {
    if (tp == DartType.BOOL) {
      return const [
        DartLib('isEven', [DartType.INT, null]),
        DartLib('isOdd', [DartType.INT, null]),
        DartLib('isEmpty', [DartType.STRING, null]),
        DartLib('isEmpty', [DartType.INT_STRING_MAP, null]),
        DartLib('isNotEmpty', [DartType.STRING, null]),
        DartLib('isNotEmpty', [DartType.INT_STRING_MAP, null]),
        DartLib('endsWith', [DartType.STRING, DartType.STRING]),
        DartLib('remove', [DartType.INT_LIST, DartType.INT]),
        DartLib('containsValue', [DartType.INT_STRING_MAP, DartType.STRING]),
        DartLib('containsKey', [DartType.INT_STRING_MAP, DartType.INT]),
      ];
    } else if (tp == DartType.INT) {
      return const [
        DartLib('bitLength', [DartType.INT, null]),
        DartLib('sign', [DartType.INT, null]),
        DartLib('abs', [DartType.INT]),
        DartLib('round', [DartType.INT]),
        DartLib('round', [DartType.DOUBLE]),
        DartLib('floor', [DartType.INT]),
        DartLib('floor', [DartType.DOUBLE]),
        DartLib('ceil', [DartType.INT]),
        DartLib('ceil', [DartType.DOUBLE]),
        DartLib('truncate', [DartType.INT]),
        DartLib('truncate', [DartType.DOUBLE]),
        DartLib('toInt', [DartType.DOUBLE]),
        DartLib('toUnsigned', [DartType.INT, DartType.INT]),
        DartLib('toSigned', [DartType.INT, DartType.INT]),
        DartLib('modInverse', [DartType.INT, DartType.INT]),
        DartLib('modPow', [DartType.INT, DartType.INT, DartType.INT]),
        DartLib('length', [DartType.STRING, null]),
        DartLib('length', [DartType.INT_LIST, null]),
        DartLib('length', [DartType.INT_STRING_MAP, null]),
        DartLib('codeUnitAt', [DartType.STRING, DartType.INT]),
        DartLib('compareTo', [DartType.STRING, DartType.STRING]),
        DartLib('removeLast', [DartType.INT_LIST]),
        DartLib('removeAt', [DartType.INT_LIST, DartType.INT]),
        DartLib('indexOf', [DartType.INT_LIST, DartType.INT]),
        DartLib('lastIndexOf', [DartType.INT_LIST, DartType.INT]),
      ];
    } else if (tp == DartType.DOUBLE) {
      return const [
        DartLib('sign', [DartType.DOUBLE, null]),
        DartLib('abs', [DartType.DOUBLE]),
        DartLib('toDouble', [DartType.INT]),
        DartLib('roundToDouble', [DartType.INT]),
        DartLib('roundToDouble', [DartType.DOUBLE]),
        DartLib('floorToDouble', [DartType.INT]),
        DartLib('floorToDouble', [DartType.DOUBLE]),
        DartLib('ceilToDouble', [DartType.INT]),
        DartLib('ceilToDouble', [DartType.DOUBLE]),
        DartLib('truncateToDouble', [DartType.INT]),
        DartLib('truncateToDouble', [DartType.DOUBLE]),
        DartLib('remainder', [DartType.DOUBLE, DartType.DOUBLE]),
      ];
    } else if (tp == DartType.STRING) {
      return const [
        DartLib('toString', [DartType.BOOL]),
        DartLib('toString', [DartType.INT]),
        DartLib('toString', [DartType.DOUBLE]),
        DartLib('toRadixString', [DartType.INT, DartType.INT]),
        DartLib('trim', [DartType.STRING]),
        DartLib('trimLeft', [DartType.STRING]),
        DartLib('trimRight', [DartType.STRING]),
        DartLib('toLowerCase', [DartType.STRING]),
        DartLib('toUpperCase', [DartType.STRING]),
        DartLib('substring', [DartType.STRING, DartType.INT]),
        DartLib('replaceRange',
            [DartType.STRING, DartType.INT, DartType.INT, DartType.STRING]),
        DartLib('remove', [DartType.INT_STRING_MAP, DartType.INT]),
        // Avoid (OOM divergences, unless we restrict parameters):
        // DartLib('padLeft', [DartType.STRING, DartType.INT]),
        // DartLib('padRight', [DartType.STRING, DartType.INT]),
      ];
    } else if (tp == DartType.INT_LIST) {
      return const [
        DartLib('sublist', [DartType.INT_LIST, DartType.INT])
      ];
    } else {
      assert(false);
    }
  }

  //
  // Types.
  //

  // Get a random value type.
  DartType getType() {
    switch (rand.nextInt(6)) {
      case 0:
        return DartType.BOOL;
      case 1:
        return DartType.INT;
      case 2:
        return DartType.DOUBLE;
      case 3:
        return DartType.STRING;
      case 4:
        return DartType.INT_LIST;
      case 5:
        return DartType.INT_STRING_MAP;
    }
  }

  List<DartType> fillTypes1() {
    List<DartType> list = new List<DartType>();
    int n = 1 + rand.nextInt(4);
    for (int i = 0; i < n; i++) {
      list.add(getType());
    }
    return list;
  }

  List<List<DartType>> fillTypes2() {
    List<List<DartType>> list = new List<List<DartType>>();
    int n = 1 + rand.nextInt(4);
    for (int i = 0; i < n; i++) {
      list.add(fillTypes1());
    }
    return list;
  }

  List<List<List<DartType>>> fillTypes3(int n) {
    List<List<List<DartType>>> list = new List<List<List<DartType>>>();
    for (int i = 0; i < n; i++) {
      list.add(fillTypes2());
    }
    return list;
  }

  List<DartType> getCurrentProto() {
    if (currentClass != null) {
      if (currentMethod != null) {
        return classMethods[currentClass][currentMethod];
      }
    } else if (currentMethod != null) {
      return globalMethods[currentMethod];
    }
    return null;
  }

  List<DartType> getCurrentFields() {
    if (currentClass != null) {
      return classFields[currentClass];
    }
    return null;
  }

  //
  // Output.
  //

  // Emits indented line to append to program.
  void emitLn(String line, {bool newline = true}) {
    file.writeStringSync(' ' * indent);
    emit(line, newline: newline);
  }

  // Emits text to append to program.
  void emit(String txt, {bool newline = false}) {
    file.writeStringSync(txt);
    if (newline) {
      file.writeStringSync('\n');
    }
  }

  // Emits one of the given choices.
  T oneOf<T>(List<T> choices) {
    return choices[rand.nextInt(choices.length)];
  }

  // Random seed used to generate program.
  final int seed;

  // File used for output.
  final RandomAccessFile file;

  // Program variables.
  Random rand;
  int indent;
  int currentClass;
  int currentMethod;

  // Types of local variables currently in scope.
  List<DartType> localVars;

  // Types of global variables.
  List<DartType> globalVars;

  // Prototypes of all global methods (first element is return type).
  List<List<DartType>> globalMethods;

  // Types of fields over all classes.
  List<List<DartType>> classFields;

  // Prototypes of all methods over all classes (first element is return type).
  List<List<List<DartType>>> classMethods;
}

// Generate seed. By default (no user-defined nonzero seed given),
// pick the system's best way of seeding randomness and then pick
// a user-visible nonzero seed.
int getSeed(String userSeed) {
  int seed = int.parse(userSeed);
  if (seed == 0) {
    Random rand = new Random();
    while (seed == 0) {
      seed = rand.nextInt(1 << 32);
    }
  }
  return seed;
}

/// Main driver when dartfuzz.dart is run stand-alone.
main(List<String> arguments) {
  final parser = new ArgParser()
    ..addOption('seed',
        help: 'random seed (0 forces time-based seed)', defaultsTo: '0');
  try {
    final results = parser.parse(arguments);
    final seed = getSeed(results['seed']);
    final file = new File(results.rest.single).openSync(mode: FileMode.write);
    new DartFuzz(seed, file).run();
    file.closeSync();
  } catch (e) {
    print('Usage: dart dartfuzz.dart [OPTIONS] FILENAME\n${parser.usage}\n$e');
    exitCode = 255;
  }
}
