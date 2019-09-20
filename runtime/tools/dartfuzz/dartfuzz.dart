// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';

import 'dartfuzz_values.dart';
import 'dartfuzz_api_table.dart';
import 'dartfuzz_ffiapi.dart';

// Version of DartFuzz. Increase this each time changes are made
// to preserve the property that a given version of DartFuzz yields
// the same fuzzed program for a deterministic random seed.
const String version = '1.50';

// Restriction on statements and expressions.
const int stmtDepth = 1;
const int exprDepth = 2;
const int numStatements = 2;
const int numGlobalVars = 4;
const int numLocalVars = 4;
const int numGlobalMethods = 4;
const int numClassMethods = 3;
const int numMethodParams = 4;
const int numClasses = 4;

// Naming conventions.
const varName = 'var';
const paramName = 'par';
const localName = 'loc';
const fieldName = 'fld';
const methodName = 'foo';

// Class that tracks the state of the filter applied to the
// right-hand-side of an assignment in order to avoid generating
// left-hand-side variables.
class RhsFilter {
  RhsFilter(this._remaining, this.lhsVar);
  factory RhsFilter.fromDartType(DartType tp, String lhsVar) {
    if (tp == DartType.STRING ||
        tp == DartType.INT_LIST ||
        tp == DartType.INT_SET ||
        tp == DartType.INT_STRING_MAP) {
      return RhsFilter(1, lhsVar);
    }
    return null;
  }
  // Clone the current RhsFilter instance and set remaining to 0.
  // This is used for parameter expressions.
  factory RhsFilter.cloneEmpty(RhsFilter rhsFilter) =>
      rhsFilter == null ? null : RhsFilter(0, rhsFilter.lhsVar);
  void consume() => _remaining--;
  bool get shouldFilter => _remaining <= 0;
  // Number of times the lhs variable can still be used on the rhs.
  int _remaining;
  // The name of the lhs variable to be filtered from the rhs.
  final String lhsVar;
}

/// Class that specifies the api for calling library and ffi functions (if
/// enabled).
class DartApi {
  DartApi(bool ffi)
      : intLibs = [
          if (ffi) ...[
            DartLib('intComputation', 'VIIII'),
            DartLib('takeMaxUint16', 'VI'),
            DartLib('sumPlus42', 'VII'),
            DartLib('returnMaxUint8', 'VV'),
            DartLib('returnMaxUint16', 'VV'),
            DartLib('returnMaxUint32', 'VV'),
            DartLib('returnMinInt8', 'VV'),
            DartLib('returnMinInt16', 'VV'),
            DartLib('returnMinInt32', 'VV'),
            DartLib('takeMinInt16', 'VI'),
            DartLib('takeMinInt32', 'VI'),
            DartLib('uintComputation', 'VIIII'),
            DartLib('sumSmallNumbers', 'VIIIIII'),
            DartLib('takeMinInt8', 'VI'),
            DartLib('takeMaxUint32', 'VI'),
            DartLib('takeMaxUint8', 'VI'),
            DartLib('minInt64', 'VV'),
            DartLib('minInt32', 'VV'),
            // Use small int to avoid overflow divergences due to size
            // differences in intptr_t on 32-bit and 64-bit platforms.
            DartLib('sumManyIntsOdd', 'Viiiiiiiiiii'),
            DartLib('sumManyInts', 'Viiiiiiiiii'),
            DartLib('regress37069', 'Viiiiiiiiiii'),
          ],
          ...DartLib.intLibs,
        ],
        doubleLibs = [
          if (ffi) ...[
            DartLib('times1_337Float', 'VD'),
            DartLib('sumManyDoubles', 'VDDDDDDDDDD'),
            DartLib('times1_337Double', 'VD'),
            DartLib('sumManyNumbers', 'VIDIDIDIDIDIDIDIDIDID'),
            DartLib('inventFloatValue', 'VV'),
            DartLib('smallDouble', 'VV'),
          ],
          ...DartLib.doubleLibs,
        ];

  final boolLibs = DartLib.boolLibs;
  final stringLibs = DartLib.stringLibs;
  final listLibs = DartLib.listLibs;
  final setLibs = DartLib.setLibs;
  final mapLibs = DartLib.mapLibs;
  final List<DartLib> intLibs;
  final List<DartLib> doubleLibs;
}

/// Class that generates a random, but runnable Dart program for fuzz testing.
class DartFuzz {
  DartFuzz(this.seed, this.fp, this.ffi, this.file);

  void run() {
    // Initialize program variables.
    rand = Random(seed);
    indent = 0;
    nest = 0;
    currentClass = null;
    currentMethod = null;
    // Setup the library and ffi api.
    api = DartApi(ffi);
    // Setup the types.
    localVars = <DartType>[];
    iterVars = <String>[];

    globalVars = fillTypes1(limit: numGlobalVars);
    globalVars.addAll(DartType.allTypes); // always one each
    globalMethods =
        fillTypes2(limit2: numGlobalMethods, limit1: numMethodParams);
    classFields = fillTypes2(limit2: numClasses, limit1: numLocalVars);
    classMethods = fillTypes3(classFields.length,
        limit2: numClassMethods, limit1: numMethodParams);

    virtualClassMethods = <Map<int, List<int>>>[];
    classParents = <int>[];
    // Setup optional ffi methods and types.
    final ffiStatus = <bool>[for (final _ in globalMethods) false];
    if (ffi) {
      List<List<DartType>> globalMethodsFfi = fillTypes2(
          limit2: numGlobalMethods, limit1: numMethodParams, isFfi: true);
      for (var m in globalMethodsFfi) {
        globalMethods.add(m);
        ffiStatus.add(true);
      }
    }
    // Generate.
    emitHeader();
    emitVarDecls(varName, globalVars);
    emitMethods(methodName, globalMethods, ffiStatus);
    emitClasses();
    emitMain();
    // Sanity.
    assert(currentClass == null);
    assert(currentMethod == null);
    assert(indent == 0);
    assert(nest == 0);
    assert(localVars.isEmpty);
  }

  //
  // Program components.
  //

  void emitHeader() {
    emitLn('// The Dart Project Fuzz Tester ($version).');
    emitLn('// Program generated as:');
    emitLn('//   dart dartfuzz.dart --seed $seed --${fp ? "" : "no-"}fp ' +
        '--${ffi ? "" : "no-"}ffi');
    emitLn('');
    emitLn("import 'dart:async';");
    emitLn("import 'dart:cli';");
    emitLn("import 'dart:collection';");
    emitLn("import 'dart:convert';");
    emitLn("import 'dart:core';");
    emitLn("import 'dart:io';");
    emitLn("import 'dart:isolate';");
    emitLn("import 'dart:math';");
    emitLn("import 'dart:typed_data';");
    if (ffi) {
      emitLn("import 'dart:ffi' as ffi;");
      emitLn(DartFuzzFfiApi.ffiapi);
    }
  }

  void emitFfiCast(String dartFuncName, String ffiFuncName, String typeName,
      List<DartType> pars) {
    emit("${pars[0].name} Function(");
    for (int i = 1; i < pars.length; i++) {
      DartType tp = pars[i];
      emit('${tp.name}');
      if (i != (pars.length - 1)) {
        emit(', ');
      }
    }
    emit(') ${dartFuncName} = ' +
        'ffi.Pointer.fromFunction<${typeName}>(${ffiFuncName}, ');
    emitLiteral(0, pars[0], smallPositiveValue: true);
    emitLn(').cast<ffi.NativeFunction<${typeName}>>().asFunction();');
  }

  void emitMethod(
      String name, int index, List<DartType> method, bool isFfiMethod) {
    if (isFfiMethod) {
      emitFfiTypedef("${name}Ffi${index}Type", method);
      emitLn('${method[0].name} ${name}Ffi$index(', newline: false);
    } else {
      emitLn('${method[0].name} $name$index(', newline: false);
    }
    emitParDecls(method);
    if (!isFfiMethod && rand.nextInt(10) == 0) {
      // Emit a method using "=>" syntax.
      emit(') => ');
      emitExpr(0, method[0]);
      emit(';', newline: true);
      return;
    }
    emit(') {', newline: true);
    indent += 2;
    assert(localVars.isEmpty);
    if (emitStatements(0)) {
      emitReturn();
    }
    assert(localVars.isEmpty);
    indent -= 2;
    emitLn('}');
    if (isFfiMethod) {
      emitFfiCast("${name}${index}", "${name}Ffi${index}",
          "${name}Ffi${index}Type", method);
    }
    emit('', newline: true);
  }

  void emitMethods(String name, List<List<DartType>> methods,
      [List<bool> ffiStatus]) {
    for (int i = 0; i < methods.length; i++) {
      List<DartType> method = methods[i];
      currentMethod = i;
      final bool isFfiMethod = ffiStatus != null && ffiStatus[i];
      emitMethod(name, i, method, isFfiMethod);
      currentMethod = null;
    }
  }

  // Randomly overwrite some methods from the parent classes.
  void emitVirtualMethods() {
    final currentClassTmp = currentClass;
    int parentClass = classParents[currentClass];
    final vcm = <int, List<int>>{};
    // Chase randomly up in class hierarchy.
    while (parentClass >= 0) {
      vcm[parentClass] = <int>[];
      for (int j = 0, n = classMethods[parentClass].length; j < n; j++) {
        if (rand.nextInt(8) == 0) {
          currentClass = parentClass;
          currentMethod = j;
          emitMethod('$methodName${parentClass}_', j,
              classMethods[parentClass][j], false);
          vcm[parentClass].add(currentMethod);
          currentMethod = null;
          currentClass = null;
        }
      }
      if (rand.nextInt(2) == 0 || classParents.length > parentClass) {
        break;
      } else {
        parentClass = classParents[parentClass];
      }
    }
    currentClass = currentClassTmp;
    virtualClassMethods.add(vcm);
  }

  void emitClasses() {
    assert(classFields.length == classMethods.length);
    for (int i = 0; i < classFields.length; i++) {
      if (i == 0) {
        classParents.add(-1);
        emitLn('class X0 {');
      } else {
        final int parentClass = rand.nextInt(i);
        classParents.add(parentClass);
        if (rand.nextInt(2) != 0) {
          // Inheritance
          emitLn('class X$i extends X${parentClass} {');
        } else {
          // Mixin
          if (classParents[parentClass] >= 0) {
            emitLn(
                'class X$i extends X${classParents[parentClass]} with X${parentClass} {');
          } else {
            emitLn('class X$i with X${parentClass} {');
          }
        }
      }
      indent += 2;
      emitVarDecls('$fieldName${i}_', classFields[i]);
      currentClass = i;
      emitVirtualMethods();
      emitMethods('$methodName${i}_', classMethods[i]);
      emitLn('void run() {');
      indent += 2;
      if (i > 0) {
        emitLn('super.run();');
      }
      assert(localVars.isEmpty);
      emitStatements(0);
      assert(localVars.isEmpty);
      indent -= 2;
      emitLn('}');
      indent -= 2;
      emitLn('}');
      emit('', newline: true);
      currentClass = null;
    }
  }

  void emitLoadFfiLib() {
    if (ffi) {
      emitLn(
          '// The following throws an uncaught exception if the ffi library ' +
              'is not found.');
      emitLn(
          '// By not catching this exception, we terminate the program with ' +
              'a full stack trace');
      emitLn('// which, in turn, flags the problem prominently');
      emitLn('if (ffiTestFunctions == null) {');
      indent += 2;
      emitLn('print(\'Did not load ffi test functions\');');
      indent -= 2;
      emitLn('}');
    }
  }

  void emitTryCatchFinally(Function tryBody, Function catchBody,
      {Function finallyBody}) {
    emitLn('try {');
    indent += 2;
    emitLn("", newline: false);
    tryBody();
    emit(";", newline: true);
    indent -= 2;
    emitLn('} catch (e, st) {');
    indent += 2;
    catchBody();
    indent -= 2;
    if (finallyBody != null) {
      emitLn('} finally {');
      indent += 2;
      finallyBody();
      indent -= 2;
    }
    emitLn('}');
  }

  void emitMain() {
    emitLn('main() {');
    indent += 2;

    emitLoadFfiLib();

    // Call each global method once.
    for (int i = 0; i < globalMethods.length; i++) {
      emitTryCatchFinally(() {
        emitCall(1, "$methodName${i}", globalMethods[i]);
      }, () {
        emitLn("print('$methodName$i throws');");
      });
    }

    // Call each class method once.
    for (int i = 0; i < classMethods.length; i++) {
      for (int j = 0; j < classMethods[i].length; j++) {
        emitTryCatchFinally(() {
          emitCall(1, "X${i}().$methodName${i}_${j}", classMethods[i][j]);
        }, () {
          emitLn("print('X${i}().$methodName${i}_${j}() throws');");
        });
      }
      // Call each virtual class method once.
      int parentClass = classParents[i];
      while (parentClass >= 0) {
        if (virtualClassMethods[i].containsKey(parentClass)) {
          for (int j = 0; j < virtualClassMethods[i][parentClass].length; j++) {
            emitTryCatchFinally(() {
              emitCall(1, "X${i}().$methodName${parentClass}_${j}",
                  classMethods[parentClass][j]);
            }, () {
              emitLn(
                  "print('X${i}().$methodName${parentClass}_${j}() throws');");
            });
          }
        }
        parentClass = classParents[parentClass];
      }
    }

    emitTryCatchFinally(() {
      emit('X${classFields.length - 1}().run()');
    }, () {
      emitLn("print('X${classFields.length - 1}().run() throws');");
    }, finallyBody: () {
      emitLn("print('", newline: false);
      for (int i = 0; i < globalVars.length; i++) {
        emit('\$$varName$i\\n');
      }
      emit("');", newline: true);
    });
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
      emitLiteral(0, tp);
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
    final emittedVar = emitVar(0, tp, isLhs: true);
    RhsFilter rhsFilter = RhsFilter.fromDartType(tp, emittedVar);
    final assignOp = emitAssignOp(tp);
    if ({'*=', '+='}.contains(assignOp)) {
      rhsFilter?.consume();
    }
    emitExpr(0, tp, rhsFilter: rhsFilter);
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

  // Emit a throw statement.
  bool emitThrow() {
    DartType tp = getType();
    emitLn('throw ', newline: false);
    emitExpr(0, tp);
    emit(';', newline: true);
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
    final int i = localVars.length;
    emitLn('for (int $localName$i = 0; $localName$i < ', newline: false);
    emitSmallPositiveInt();
    emit('; $localName$i++) {', newline: true);
    indent += 2;
    nest++;
    iterVars.add("$localName$i");
    localVars.add(DartType.INT);
    emitStatements(depth + 1);
    localVars.removeLast();
    iterVars.removeLast();
    nest--;
    indent -= 2;
    emitLn('}');
    return true;
  }

  // Emit a simple membership for-in-loop.
  bool emitForIn(int depth) {
    final int i = localVars.length;
    emitLn('for (int $localName$i in ', newline: false);
    localVars.add(null); // declared, but don't use
    emitExpr(0, rand.nextBool() ? DartType.INT_LIST : DartType.INT_SET);
    localVars.removeLast(); // will get type
    emit(') {', newline: true);
    indent += 2;
    nest++;
    localVars.add(DartType.INT);
    emitStatements(depth + 1);
    localVars.removeLast();
    nest--;
    indent -= 2;
    emitLn('}');
    return true;
  }

  // Emit a simple membership forEach loop.
  bool emitForEach(int depth) {
    final int i = localVars.length;
    final int j = i + 1;
    emitLn("", newline: false);
    final emittedVar = emitScalarVar(DartType.INT_STRING_MAP, isLhs: false);
    iterVars.add(emittedVar);
    emit('.forEach(($localName$i, $localName$j) {\n');
    indent += 2;
    final int nestTmp = nest;
    // Reset, since forEach cannot break out of own or enclosing context.
    nest = 0;
    localVars.add(DartType.INT);
    localVars.add(DartType.STRING);
    emitStatements(depth + 1);
    localVars.removeLast();
    localVars.removeLast();
    nest = nestTmp;
    indent -= 2;
    emitLn('});');
    return true;
  }

  // Emit a while-loop.
  bool emitWhile(int depth) {
    final int i = localVars.length;
    emitLn('{ int $localName$i = ', newline: false);
    emitSmallPositiveInt();
    emit(';', newline: true);
    indent += 2;
    emitLn('while (--$localName$i > 0) {');
    indent += 2;
    nest++;
    iterVars.add("$localName$i");
    localVars.add(DartType.INT);
    emitStatements(depth + 1);
    localVars.removeLast();
    iterVars.removeLast();
    nest--;
    indent -= 2;
    emitLn('}');
    indent -= 2;
    emitLn('}');
    return true;
  }

  // Emit a do-while-loop.
  bool emitDoWhile(int depth) {
    final int i = localVars.length;
    emitLn('{ int $localName$i = 0;');
    indent += 2;
    emitLn('do {');
    indent += 2;
    nest++;
    iterVars.add("$localName$i");
    localVars.add(DartType.INT);
    emitStatements(depth + 1);
    localVars.removeLast();
    iterVars.removeLast();
    nest--;
    indent -= 2;
    emitLn('} while (++$localName$i < ', newline: false);
    emitSmallPositiveInt();
    emit(');', newline: true);
    indent -= 2;
    emitLn('}');
    return true;
  }

  // Emit a break/continue when inside iteration.
  bool emitBreakOrContinue(int depth) {
    if (nest > 0) {
      switch (rand.nextInt(2)) {
        case 0:
          emitLn('continue;');
          return false;
        default:
          emitLn('break;');
          return false;
      }
    }
    return emitAssign(); // resort to assignment
  }

  // Emit a switch statement.
  bool emitSwitch(int depth) {
    emitLn('switch (', newline: false);
    emitExpr(0, DartType.INT);
    emit(') {', newline: true);
    int start = rand.nextInt(1 << 32);
    int step = 1 + rand.nextInt(10);
    for (int i = 0; i < 2; i++, start += step) {
      indent += 2;
      if (i == 2) {
        emitLn('default: {');
      } else {
        emitLn('case $start: {');
      }
      indent += 2;
      emitStatements(depth + 1);
      indent -= 2;
      emitLn('}');
      emitLn('break;'); // always generate, avoid FE complaints
      indent -= 2;
    }
    emitLn('}');
    return true;
  }

  // Emit a new program scope that introduces a new local variable.
  bool emitScope(int depth) {
    DartType tp = getType();
    final int i = localVars.length;
    emitLn('{ ${tp.name} $localName$i = ', newline: false);
    localVars.add(null); // declared, but don't use
    emitExpr(0, tp);
    localVars.removeLast(); // will get type
    emit(';', newline: true);
    indent += 2;
    localVars.add(tp);
    emitStatements(depth + 1);
    localVars.removeLast();
    indent -= 2;
    emitLn('}');
    return true;
  }

  // Emit try/catch/finally.
  bool emitTryCatch(int depth) {
    emitLn('try {');
    indent += 2;
    emitStatements(depth + 1);
    indent -= 2;
    emitLn('} catch (exception, stackTrace) {');
    indent += 2;
    emitStatements(depth + 1);
    indent -= 2;
    if (rand.nextInt(2) == 0) {
      emitLn('} finally {');
      indent += 2;
      emitStatements(depth + 1);
      indent -= 2;
    }
    emitLn('}');
    return true;
  }

  // Emit a statement. Returns true if code *may* fall-through
  // (not made too advanced to avoid FE complaints).
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
    switch (rand.nextInt(16)) {
      // Favors assignment.
      case 0:
        return emitPrint();
      case 1:
        return emitReturn();
      case 2:
        return emitThrow();
      case 3:
        return emitIf1(depth);
      case 4:
        return emitIf2(depth);
      case 5:
        return emitFor(depth);
      case 6:
        return emitForIn(depth);
      case 7:
        return emitWhile(depth);
      case 8:
        return emitDoWhile(depth);
      case 9:
        return emitBreakOrContinue(depth);
      case 10:
        return emitSwitch(depth);
      case 11:
        return emitScope(depth);
      case 12:
        return emitTryCatch(depth);
      case 13:
        return emitForEach(depth);
      default:
        return emitAssign();
    }
  }

  // Emit statements. Returns true if code may fall-through.
  bool emitStatements(int depth) {
    int s = 1 + rand.nextInt(numStatements);
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

  void emitSmallPositiveInt({int limit = 100}) {
    emit('${rand.nextInt(limit)}');
  }

  void emitSmallNegativeInt() {
    emit('-${rand.nextInt(100)}');
  }

  void emitInt() {
    switch (rand.nextInt(7)) {
      // Favors small ints.
      case 0:
      case 1:
      case 2:
        emitSmallPositiveInt();
        break;
      case 3:
      case 4:
      case 5:
        emitSmallNegativeInt();
        break;
      default:
        emit('${oneOf(DartFuzzValues.interestingIntegers)}');
        break;
    }
  }

  void emitDouble() {
    emit('${rand.nextDouble()}');
  }

  void emitChar() {
    switch (rand.nextInt(10)) {
      // Favors regular char.
      case 0:
        emit(oneOf(DartFuzzValues.interestingChars));
        break;
      default:
        emit(DartFuzzValues
            .regularChars[rand.nextInt(DartFuzzValues.regularChars.length)]);
        break;
    }
  }

  void emitString({int length = 8}) {
    emit("'");
    for (int i = 0, n = rand.nextInt(length); i < n; i++) {
      emitChar();
    }
    emit("'");
  }

  void emitElementExpr(int depth, DartType tp, {RhsFilter rhsFilter}) {
    if (currentMethod != null) {
      emitExpr(depth, tp, rhsFilter: rhsFilter);
    } else {
      emitLiteral(depth, tp, rhsFilter: rhsFilter);
    }
  }

  void emitElement(int depth, DartType tp, {RhsFilter rhsFilter}) {
    if (tp == DartType.INT_STRING_MAP) {
      emitSmallPositiveInt();
      emit(' : ');
      emitElementExpr(depth, DartType.STRING, rhsFilter: rhsFilter);
    } else {
      emitElementExpr(depth, DartType.INT, rhsFilter: rhsFilter);
    }
  }

  void emitCollectionElement(int depth, DartType tp, {RhsFilter rhsFilter}) {
    int r = depth <= exprDepth ? rand.nextInt(10) : 10;
    switch (r + 3) {
      // Favors elements over control-flow collections.
      case 0:
        // TODO (ajcbik): Remove restriction once compiler is fixed.
        if (depth < 2) {
          emit('...'); // spread
          emitCollection(depth + 1, tp, rhsFilter: rhsFilter);
        } else {
          emitElement(depth, tp, rhsFilter: rhsFilter);
        }
        break;
      case 1:
        emit('if (');
        emitElementExpr(depth + 1, DartType.BOOL, rhsFilter: rhsFilter);
        emit(') ');
        emitCollectionElement(depth + 1, tp, rhsFilter: rhsFilter);
        if (rand.nextBool()) {
          emit(' else ');
          emitCollectionElement(depth + 1, tp, rhsFilter: rhsFilter);
        }
        break;
      case 2:
        {
          final int i = localVars.length;
          emit('for (int $localName$i ');
          // For-loop (induction, list, set).
          localVars.add(null); // declared, but don't use
          switch (rand.nextInt(3)) {
            case 0:
              emit('= 0; $localName$i < ');
              emitSmallPositiveInt(limit: 16);
              emit('; $localName$i++) ');
              break;
            case 1:
              emit('in ');
              emitCollection(depth + 1, DartType.INT_LIST,
                  rhsFilter: rhsFilter);
              emit(') ');
              break;
            default:
              emit('in ');
              emitCollection(depth + 1, DartType.INT_SET, rhsFilter: rhsFilter);
              emit(') ');
              break;
          }
          localVars.removeLast(); // will get type
          nest++;
          iterVars.add("$localName$i");
          localVars.add(DartType.INT);
          emitCollectionElement(depth + 1, tp, rhsFilter: rhsFilter);
          localVars.removeLast();
          iterVars.removeLast();
          nest--;
          break;
        }
      default:
        emitElement(depth, tp, rhsFilter: rhsFilter);
        break;
    }
  }

  void emitCollection(int depth, DartType tp, {RhsFilter rhsFilter}) {
    emit(tp == DartType.INT_LIST ? '[ ' : '{ ');
    for (int i = 0, n = 1 + rand.nextInt(8); i < n; i++) {
      emitCollectionElement(depth, tp, rhsFilter: rhsFilter);
      if (i != (n - 1)) {
        emit(', ');
      }
    }
    emit(tp == DartType.INT_LIST ? ' ]' : ' }');
  }

  void emitLiteral(int depth, DartType tp,
      {bool smallPositiveValue = false, RhsFilter rhsFilter}) {
    if (tp == DartType.BOOL) {
      emitBool();
    } else if (tp == DartType.INT) {
      if (smallPositiveValue) {
        emitSmallPositiveInt();
      } else {
        emitInt();
      }
    } else if (tp == DartType.DOUBLE) {
      emitDouble();
    } else if (tp == DartType.STRING) {
      emitString();
    } else if (tp == DartType.INT_LIST ||
        tp == DartType.INT_SET ||
        tp == DartType.INT_STRING_MAP) {
      emitCollection(depth, tp, rhsFilter: RhsFilter.cloneEmpty(rhsFilter));
    } else {
      assert(false);
    }
  }

  String emitScalarVar(DartType tp, {bool isLhs = false, RhsFilter rhsFilter}) {
    // Collect all choices from globals, fields, locals, and parameters.
    Set<String> choices = <String>{};
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
    // Make modification of the iteration variable from the loop
    // body less likely.
    if (isLhs) {
      if (rand.nextInt(100) != 0) {
        Set<String> cleanChoices = choices.difference(Set.from(iterVars));
        if (cleanChoices.isNotEmpty) {
          choices = cleanChoices;
        }
      }
    }
    // Filter out the current lhs of the expression to avoid recursive
    // assignments of the form x = x * x.
    if (rhsFilter != null && rhsFilter.shouldFilter) {
      Set<String> cleanChoices = choices.difference({rhsFilter.lhsVar});
      // If we have other choices of variables, use those.
      if (cleanChoices.isNotEmpty) {
        choices = cleanChoices;
      } else if (!isLhs) {
        // If we are emitting an RHS variable, we can emit a terminal.
        // note that if the variable type is a collection, this might
        // still result in a recursion.
        emitLiteral(0, tp);
        return null;
      }
      // Otherwise we have to risk creating a recursion.
    }
    // Then pick one.
    if (choices.isEmpty) {
      throw 'No variable to emit for type ${tp.name}';
    }
    final emittedVar = '${choices.elementAt(rand.nextInt(choices.length))}';
    if (rhsFilter != null && (emittedVar == rhsFilter.lhsVar)) {
      rhsFilter.consume();
    }
    emit(emittedVar);
    return emittedVar;
  }

  String emitSubscriptedVar(int depth, DartType tp,
      {bool isLhs = false, RhsFilter rhsFilter}) {
    String ret;
    if (tp == DartType.INT) {
      ret =
          emitScalarVar(DartType.INT_LIST, isLhs: isLhs, rhsFilter: rhsFilter);
      emit('[');
      emitExpr(depth + 1, DartType.INT);
      emit(']');
    } else if (tp == DartType.STRING) {
      ret = emitScalarVar(DartType.INT_STRING_MAP,
          isLhs: isLhs, rhsFilter: rhsFilter);
      emit('[');
      emitExpr(depth + 1, DartType.INT);
      emit(']');
    } else {
      ret = emitScalarVar(tp,
          isLhs: isLhs, rhsFilter: rhsFilter); // resort to scalar
    }
    return ret;
  }

  String emitVar(int depth, DartType tp,
      {bool isLhs = false, RhsFilter rhsFilter}) {
    switch (rand.nextInt(2)) {
      case 0:
        return emitScalarVar(tp, isLhs: isLhs, rhsFilter: rhsFilter);
        break;
      default:
        return emitSubscriptedVar(depth, tp,
            isLhs: isLhs, rhsFilter: rhsFilter);
        break;
    }
  }

  void emitTerminal(int depth, DartType tp, {RhsFilter rhsFilter}) {
    switch (rand.nextInt(2)) {
      case 0:
        emitLiteral(depth, tp, rhsFilter: rhsFilter);
        break;
      default:
        emitVar(depth, tp, rhsFilter: rhsFilter);
        break;
    }
  }

  void emitExprList(int depth, List<DartType> proto, {RhsFilter rhsFilter}) {
    emit('(');
    for (int i = 1; i < proto.length; i++) {
      emitExpr(depth, proto[i], rhsFilter: rhsFilter);
      if (i != (proto.length - 1)) {
        emit(', ');
      }
    }
    emit(')');
  }

  // Emit expression with unary operator: (~(x))
  void emitUnaryExpr(int depth, DartType tp, {RhsFilter rhsFilter}) {
    if (tp == DartType.BOOL || tp == DartType.INT || tp == DartType.DOUBLE) {
      emit('(');
      emitUnaryOp(tp);
      emit('(');
      emitExpr(depth + 1, tp, rhsFilter: rhsFilter);
      emit('))');
    } else {
      emitTerminal(depth, tp, rhsFilter: rhsFilter); // resort to terminal
    }
  }

  // Emit expression with binary operator: (x + y)
  void emitBinaryExpr(int depth, DartType tp, {RhsFilter rhsFilter}) {
    if (tp == DartType.BOOL) {
      // For boolean, allow type switch with relational op.
      if (rand.nextInt(2) == 0) {
        DartType deeper_tp = getType();
        emit('(');
        emitExpr(depth + 1, deeper_tp, rhsFilter: rhsFilter);
        emitRelOp(deeper_tp);
        emitExpr(depth + 1, deeper_tp, rhsFilter: rhsFilter);
        emit(')');
        return;
      }
    }
    emit('(');
    emitExpr(depth + 1, tp, rhsFilter: rhsFilter);
    emitBinaryOp(tp);
    emitExpr(depth + 1, tp, rhsFilter: rhsFilter);
    emit(')');
  }

  // Emit expression with ternary operator: (b ? x : y)
  void emitTernaryExpr(int depth, DartType tp, {RhsFilter rhsFilter}) {
    emit('(');
    emitExpr(depth + 1, DartType.BOOL, rhsFilter: rhsFilter);
    emit(' ? ');
    emitExpr(depth + 1, tp, rhsFilter: rhsFilter);
    emit(' : ');
    emitExpr(depth + 1, tp, rhsFilter: rhsFilter);
    emit(')');
  }

  // Emit expression with pre/post-increment/decrement operator: (x++)
  void emitPreOrPostExpr(int depth, DartType tp, {RhsFilter rhsFilter}) {
    if (tp == DartType.INT) {
      int r = rand.nextInt(2);
      emit('(');
      if (r == 0) emitPreOrPostOp(tp);
      emitScalarVar(tp, isLhs: true);
      if (r == 1) emitPreOrPostOp(tp);
      emit(')');
    } else {
      emitTerminal(depth, tp, rhsFilter: rhsFilter); // resort to terminal
    }
  }

  // Emit library call.
  void emitLibraryCall(int depth, DartType tp, {RhsFilter rhsFilter}) {
    DartLib lib = getLibraryMethod(tp);
    final String proto = lib.proto;
    // Receiver.
    if (proto[0] != 'V') {
      emit('(');
      emitArg(depth + 1, proto[0], rhsFilter: rhsFilter);
      emit(').');
    }
    // Call.
    emit('${lib.name}');
    // Parameters.
    if (proto[1] != 'v') {
      emit('(');
      if (proto[1] != 'V') {
        for (int i = 1; i < proto.length; i++) {
          emitArg(depth + 1, proto[i], rhsFilter: rhsFilter);
          if (i != (proto.length - 1)) {
            emit(', ');
          }
        }
      }
      emit(')');
    }
  }

  // Emit call to a specific method.
  void emitCall(int depth, String name, List<DartType> proto,
      {RhsFilter rhsFilter}) {
    emit(name);
    emitExprList(depth + 1, proto, rhsFilter: rhsFilter);
  }

  // Helper for a method call.
  bool pickedCall(
      int depth, DartType tp, String name, List<List<DartType>> protos, int m,
      {RhsFilter rhsFilter}) {
    for (int i = m - 1; i >= 0; i--) {
      if (tp == protos[i][0]) {
        emitCall(depth + 1, "$name$i", protos[i], rhsFilter: rhsFilter);
        return true;
      }
    }
    return false;
  }

  // Emit method call within the program.
  void emitMethodCall(int depth, DartType tp, {RhsFilter rhsFilter}) {
    // Only call backward to avoid infinite recursion.
    if (currentClass == null) {
      // Outside a class but inside a method: call backward in global methods.
      if (currentMethod != null &&
          pickedCall(depth, tp, methodName, globalMethods, currentMethod,
              rhsFilter: rhsFilter)) {
        return;
      }
    } else {
      int classIndex = currentClass;
      // Chase randomly up in class hierarchy.
      while (classParents[classIndex] > 0) {
        if (rand.nextInt(2) == 0) {
          break;
        }
        classIndex = classParents[classIndex];
      }
      int m1 = 0;
      // Inside a class: try to call backwards into current or parent class
      // methods first.
      if (currentMethod == null || classIndex != currentClass) {
        // If currently emitting the 'run' method or calling into a parent class
        // pick any of the current or parent class methods respectively.
        m1 = classMethods[classIndex].length;
      } else {
        // If calling into the current class from any method other than 'run'
        // pick one of the already emitted methods
        // (to avoid infinite recursions).
        m1 = currentMethod;
      }
      final int m2 = globalMethods.length;
      if (pickedCall(depth, tp, '$methodName${classIndex}_',
              classMethods[classIndex], m1, rhsFilter: rhsFilter) ||
          pickedCall(depth, tp, methodName, globalMethods, m2,
              rhsFilter: rhsFilter)) {
        return;
      }
    }
    emitTerminal(depth, tp, rhsFilter: rhsFilter); // resort to terminal.
  }

  // Emit expression.
  void emitExpr(int depth, DartType tp, {RhsFilter rhsFilter}) {
    // Continuing nested expressions becomes less likely as the depth grows.
    if (rand.nextInt(depth + 1) > exprDepth) {
      emitTerminal(depth, tp, rhsFilter: rhsFilter);
      return;
    }
    // Possibly nested expression.
    switch (rand.nextInt(7)) {
      case 0:
        emitUnaryExpr(depth, tp, rhsFilter: rhsFilter);
        break;
      case 1:
        emitBinaryExpr(depth, tp, rhsFilter: rhsFilter);
        break;
      case 2:
        emitTernaryExpr(depth, tp, rhsFilter: rhsFilter);
        break;
      case 3:
        emitPreOrPostExpr(depth, tp, rhsFilter: rhsFilter);
        break;
      case 4:
        emitLibraryCall(depth, tp, rhsFilter: RhsFilter.cloneEmpty(rhsFilter));
        break;
      case 5:
        emitMethodCall(depth, tp, rhsFilter: RhsFilter.cloneEmpty(rhsFilter));
        break;
      default:
        emitTerminal(depth, tp, rhsFilter: rhsFilter);
        break;
    }
  }

  //
  // Operators.
  //

  // Emit same type in-out assignment operator.
  String emitAssignOp(DartType tp) {
    if (tp == DartType.INT) {
      final assignOp = oneOf(const <String>[
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
      ]);
      emit(assignOp);
      return assignOp;
    } else if (tp == DartType.DOUBLE) {
      final assignOp =
          oneOf(const <String>[' += ', ' -= ', ' *= ', ' /= ', ' ??= ', ' = ']);
      emit(assignOp);
      return assignOp;
    } else {
      final assignOp = oneOf(const <String>[' ??= ', ' = ']);
      emit(assignOp);
      return assignOp;
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
      return oneOf(api.boolLibs);
    } else if (tp == DartType.INT) {
      return oneOf(api.intLibs);
    } else if (tp == DartType.DOUBLE) {
      return oneOf(api.doubleLibs);
    } else if (tp == DartType.STRING) {
      return oneOf(api.stringLibs);
    } else if (tp == DartType.INT_LIST) {
      return oneOf(api.listLibs);
    } else if (tp == DartType.INT_SET) {
      return oneOf(api.setLibs);
    } else if (tp == DartType.INT_STRING_MAP) {
      return oneOf(api.mapLibs);
    }
    throw ArgumentError('Invalid DartType: $tp');
  }

  // Emit a library argument, possibly subject to restrictions.
  void emitArg(int depth, String p, {RhsFilter rhsFilter}) {
    switch (p) {
      case 'B':
        emitExpr(depth, DartType.BOOL);
        break;
      case 'i': // emit small int
        emitSmallPositiveInt();
        break;
      case 'I':
        emitExpr(depth, DartType.INT);
        break;
      case 'D':
        emitExpr(depth, fp ? DartType.DOUBLE : DartType.INT);
        break;
      case 'S':
        emitExpr(depth, DartType.STRING, rhsFilter: rhsFilter);
        break;
      case 's': // emit small string
        emitString(length: 2);
        break;
      case 'L':
        emitExpr(depth, DartType.INT_LIST, rhsFilter: rhsFilter);
        break;
      case 'X':
        emitExpr(depth, DartType.INT_SET, rhsFilter: rhsFilter);
        break;
      case 'M':
        emitExpr(depth, DartType.INT_STRING_MAP, rhsFilter: rhsFilter);
        break;
      default:
        throw ArgumentError('Invalid p value: $p');
    }
  }

  //
  // Types.
  //

  // Get a random value type.
  DartType getType() {
    switch (rand.nextInt(7)) {
      case 0:
        return DartType.BOOL;
      case 1:
        return DartType.INT;
      case 2:
        return fp ? DartType.DOUBLE : DartType.INT;
      case 3:
        return DartType.STRING;
      case 4:
        return DartType.INT_LIST;
      case 5:
        return DartType.INT_SET;
      default:
        return DartType.INT_STRING_MAP;
    }
  }

  List<DartType> fillTypes1({int limit = 4, bool isFfi = false}) {
    final list = <DartType>[];
    for (int i = 0, n = 1 + rand.nextInt(limit); i < n; i++) {
      if (isFfi) {
        list.add(fp ? oneOf([DartType.INT, DartType.DOUBLE]) : DartType.INT);
      } else {
        list.add(getType());
      }
    }
    return list;
  }

  List<List<DartType>> fillTypes2(
      {bool isFfi = false, int limit2 = 4, int limit1 = 4}) {
    final list = <List<DartType>>[];
    for (int i = 0, n = 1 + rand.nextInt(limit2); i < n; i++) {
      list.add(fillTypes1(limit: limit1, isFfi: isFfi));
    }
    return list;
  }

  List<List<List<DartType>>> fillTypes3(int n,
      {int limit2 = 4, int limit1 = 4}) {
    final list = <List<List<DartType>>>[];
    for (int i = 0; i < n; i++) {
      list.add(fillTypes2(limit2: limit2, limit1: limit1));
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

  void emitFfiType(DartType tp) {
    if (tp == DartType.INT) {
      emit(oneOf(['ffi.Int8', 'ffi.Int16', 'ffi.Int32', 'ffi.Int64']));
    } else if (tp == DartType.DOUBLE) {
      emit(oneOf(['ffi.Float', 'ffi.Double']));
    } else {
      throw 'Invalid FFI type ${tp.name}';
    }
  }

  void emitFfiTypedef(String typeName, List<DartType> pars) {
    emit("typedef ${typeName} = ");
    emitFfiType(pars[0]);
    emit(" Function(");
    for (int i = 1; i < pars.length; i++) {
      DartType tp = pars[i];
      emitFfiType(tp);
      if (i != (pars.length - 1)) {
        emit(', ');
      }
    }
    emitLn(');');
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

  // Enables floating-point operations.
  final bool fp;

  // Enables FFI method calls.
  final bool ffi;

  // File used for output.
  final RandomAccessFile file;

  // Library and ffi api.
  DartApi api;

  // Program variables.
  Random rand;
  int indent;
  int nest;
  int currentClass;
  int currentMethod;

  // Types of local variables currently in scope.
  List<DartType> localVars;

  // Types of global variables.
  List<DartType> globalVars;

  // Names of currently active iterator variables.
  // These are tracked to avoid modifications within the loop body,
  // which can lead to infinite loops.
  List<String> iterVars;

  // Prototypes of all global methods (first element is return type).
  List<List<DartType>> globalMethods;

  // Types of fields over all classes.
  List<List<DartType>> classFields;

  // Prototypes of all methods over all classes (first element is return type).
  List<List<List<DartType>>> classMethods;

  // List of virtual functions per class. Map is from parent class index to List
  // of overloaded functions from that parent.
  List<Map<int, List<int>>> virtualClassMethods;

  // Parent class indices for all classes.
  List<int> classParents;
}

// Generate seed. By default (no user-defined nonzero seed given),
// pick the system's best way of seeding randomness and then pick
// a user-visible nonzero seed.
int getSeed(String userSeed) {
  int seed = int.parse(userSeed);
  if (seed == 0) {
    Random rand = Random();
    while (seed == 0) {
      seed = rand.nextInt(1 << 32);
    }
  }
  return seed;
}

/// Main driver when dartfuzz.dart is run stand-alone.
main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('seed',
        help: 'random seed (0 forces time-based seed)', defaultsTo: '0')
    ..addFlag('fp', help: 'enables floating-point operations', defaultsTo: true)
    ..addFlag('ffi',
        help: 'enables FFI method calls (default: off)', defaultsTo: false);
  try {
    final results = parser.parse(arguments);
    final seed = getSeed(results['seed']);
    final fp = results['fp'];
    final ffi = results['ffi'];
    final file = File(results.rest.single).openSync(mode: FileMode.write);
    DartFuzz(seed, fp, ffi, file).run();
    file.closeSync();
  } catch (e) {
    print('Usage: dart dartfuzz.dart [OPTIONS] FILENAME\n${parser.usage}\n$e');
    exitCode = 255;
  }
}
