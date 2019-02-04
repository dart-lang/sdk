// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';

import 'dartfuzz_values.dart';

// Version of DartFuzz. Increase this each time changes are made
// to preserve the property that a given version of DartFuzz yields
// the same fuzzed program for a deterministic random seed.
const String version = '1.3';

// Restriction on statement and expression depths.
const int stmtDepth = 5;
const int exprDepth = 2;

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
    globalVars.addAll(DartType.allTypes); // always one each
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
  // Comments (for FE and analysis tools).
  //

  void emitComment() {
    switch (rand.nextInt(4)) {
      case 0:
        emitLn('// Single-line comment.');
        break;
      case 1:
        emitLn('/// Single-line documentation comment.');
        break;
      case 2:
        emitLn('/*');
        emitLn(' * Multi-line');
        emitLn(' * comment.');
        emitLn(' */');
        break;
      default:
        emitLn('/**');
        emitLn(' ** Multi-line');
        emitLn(' ** documentation comment.');
        emitLn(' */');
        break;
    }
  }

  //
  // Statements.
  //

  // Emit an assignment statement.
  bool emitAssign() {
    DartType tp = getType();
    emitLn('', newline: false);
    emitVar(0, tp);
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
    emitStatements(depth + 1);
    indent -= 2;
    emitLn('}');
    return true;
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
    // Throw in a comment every once in a while.
    if (rand.nextInt(10) == 0) {
      emitComment();
    }
    // Continuing nested statements becomes less likely as the depth grows.
    if (rand.nextInt(depth + 1) > stmtDepth) {
      return emitAssign();
    }
    // Possibly nested statement.
    switch (rand.nextInt(8)) {
      // Favors assignment.
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
      // Favors small positive int.
      case 0:
        emit('${oneOf(DartFuzzValues.interestingIntegers)}');
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
    switch (rand.nextInt(10)) {
      // Favors regular double.
      case 0:
        emit(oneOf(DartFuzzValues.interestingDoubles));
        break;
      default:
        emit('${rand.nextDouble()}');
        break;
    }
  }

  void emitChar() {
    switch (rand.nextInt(10)) {
      // Favors regular char.
      case 0:
        emit(oneOf(DartFuzzValues.interestingChars));
        break;
      default:
        emit(DartFuzzValues.regularChars[
            rand.nextInt(DartFuzzValues.interestingChars.length)]);
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

  void emitSubscriptedVar(int depth, DartType tp) {
    if (tp == DartType.INT) {
      emitScalarVar(DartType.INT_LIST);
      emit('[');
      emitExpr(depth + 1, DartType.INT);
      emit(']');
    } else if (tp == DartType.STRING) {
      emitScalarVar(DartType.INT_STRING_MAP);
      emit('[');
      emitExpr(depth + 1, DartType.INT);
      emit(']');
    } else {
      emitScalarVar(tp); // resort to scalar
    }
  }

  void emitVar(int depth, DartType tp) {
    switch (rand.nextInt(2)) {
      case 0:
        emitScalarVar(tp);
        break;
      default:
        emitSubscriptedVar(depth, tp);
        break;
    }
  }

  void emitTerminal(int depth, DartType tp) {
    switch (rand.nextInt(2)) {
      case 0:
        emitLiteral(tp);
        break;
      default:
        emitVar(depth, tp);
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
      emitTerminal(depth, tp); // resort to terminal
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
    } else if (tp == DartType.STRING || tp == DartType.INT_LIST) {
      // For strings and lists, a construct like x = x + x; inside a loop
      // yields an exponentially growing data structure. We avoid this
      // situation by forcing a literal on the rhs of each +.
      emit('(');
      emitExpr(depth + 1, tp);
      emitBinaryOp(tp);
      emitLiteral(tp);
      emit(')');
      return;
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
      emitTerminal(depth, tp); // resort to terminal
    }
  }

  // Emit library call.
  void emitLibraryCall(int depth, DartType tp) {
    DartLib lib = getLibraryMethod(tp);
    String proto = lib.proto;
    // Receiver.
    if (proto[0] != 'V') {
      emit('(');
      emitArg(depth + 1, proto[0]);
      emit(').');
    }
    // Call.
    emit('${lib.name}');
    // Parameters.
    if (proto[1] != 'v') {
      emit('(');
      if (proto[1] != 'V') {
        for (int i = 1; i < proto.length; i++) {
          emitArg(depth + 1, proto[i]);
          if (i != (proto.length - 1)) {
            emit(', ');
          }
        }
      }
      emit(')');
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
    emitTerminal(depth, tp); // resort to terminal.
  }

  // Emit expression.
  void emitExpr(int depth, DartType tp) {
    // Continuing nested expressions becomes less likely as the depth grows.
    if (rand.nextInt(depth + 1) > exprDepth) {
      emitTerminal(depth, tp);
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
        emitTerminal(depth, tp);
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

  // Get a library method that returns given type.
  DartLib getLibraryMethod(DartType tp) {
    if (tp == DartType.BOOL) {
      return oneOf(DartLib.boolLibs);
    } else if (tp == DartType.INT) {
      return oneOf(DartLib.intLibs);
    } else if (tp == DartType.DOUBLE) {
      return oneOf(DartLib.doubleLibs);
    } else if (tp == DartType.STRING) {
      return oneOf(DartLib.stringLibs);
    } else if (tp == DartType.INT_LIST) {
      return oneOf(DartLib.intListLibs);
    } else if (tp == DartType.INT_STRING_MAP) {
      return oneOf(DartLib.intStringMapLibs);
    } else {
      assert(false);
    }
  }

  // Emit a library argument, possibly subject to restrictions.
  void emitArg(int depth, String p) {
    switch (p) {
      case 'B':
        emitExpr(depth, DartType.BOOL);
        break;
      case 'i':
        emitSmallPositiveInt();
        break;
      case 'I':
        emitExpr(depth, DartType.INT);
        break;
      case 'D':
        emitExpr(depth, DartType.DOUBLE);
        break;
      case 'S':
        emitExpr(depth, DartType.STRING);
        break;
      case 'L':
        emitExpr(depth, DartType.INT_LIST);
        break;
      case 'M':
        emitExpr(depth, DartType.INT_STRING_MAP);
        break;
      default:
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
