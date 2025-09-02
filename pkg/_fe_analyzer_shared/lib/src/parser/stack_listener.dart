// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.stack_listener;

import '../messages/codes.dart'
    show
        Code,
        LocatedMessage,
        Message,
        codeBuiltInIdentifierInDeclaration,
        codeCatchSyntaxExtraParameters,
        codeNativeClauseShouldBeAnnotation,
        codeInternalProblemStackNotEmpty,
        codeInternalProblemUnhandled;

import '../scanner/scanner.dart' show Token;

import '../util/stack_checker.dart';
import '../util/value_kind.dart';
import 'declaration_kind.dart';

import 'parser.dart' show Listener, MemberKind, lengthOfSpan;

import 'quote.dart' show unescapeString;

import '../util/null_value.dart';

/// Sentinel values used for typed `null` values on a stack.
///
/// This is used to avoid mixing `null` values between different kinds. For
/// instance a stack entry is meant to contain an expression or null, the
/// `NullValues.Expression` is pushed on the stack instead of `null` and when
/// popping the entry `NullValues.Expression` is passed show how `null` is
/// represented.
class NullValues {
  static const NullValue Arguments = const NullValue("Arguments");
  static const NullValue As = const NullValue("As");
  static const NullValue AwaitToken = const NullValue("AwaitToken");
  static const NullValue Block = const NullValue("Block");
  static const NullValue BreakTarget = const NullValue("BreakTarget");
  static const NullValue CascadeReceiver = const NullValue("CascadeReceiver");
  static const NullValue Combinators = const NullValue("Combinators");
  static const NullValue Comments = const NullValue("Comments");
  static const NullValue ConditionalUris = const NullValue("ConditionalUris");
  static const NullValue ConditionallySelectedImport = const NullValue(
    "ConditionallySelectedImport",
  );
  static const NullValue ConstructorInitializerSeparator = const NullValue(
    "ConstructorInitializerSeparator",
  );
  static const NullValue ConstructorInitializers = const NullValue(
    "ConstructorInitializers",
  );
  static const NullValue ConstructorReference = const NullValue(
    "ConstructorReference",
  );
  static const NullValue ConstructorReferenceContinuationAfterTypeArguments =
      const NullValue("ConstructorReferenceContinuationAfterTypeArguments");
  static const NullValue ContinueTarget = const NullValue("ContinueTarget");
  static const NullValue Deferred = const NullValue("Deferred");
  static const NullValue DocumentationComment = const NullValue(
    "DocumentationComment",
  );
  static const NullValue EnumConstantInfo = const NullValue("EnumConstantInfo");
  static const NullValue Expression = const NullValue("Expression");
  static const NullValue ExtendsClause = const NullValue("ExtendsClause");
  static const NullValue FieldInitializer = const NullValue("FieldInitializer");
  static const NullValue FormalParameters = const NullValue("FormalParameters");
  static const NullValue FunctionBody = const NullValue("FunctionBody");
  static const NullValue FunctionBodyAsyncToken = const NullValue(
    "FunctionBodyAsyncToken",
  );
  static const NullValue FunctionBodyStarToken = const NullValue(
    "FunctionBodyStarToken",
  );
  static const NullValue HideClause = const NullValue("HideClause");
  static const NullValue Identifier = const NullValue("Identifier");
  static const NullValue IdentifierList = const NullValue("IdentifierList");
  static const NullValue Initializers = const NullValue("Initializers");
  static const NullValue Labels = const NullValue("Labels");
  static const NullValue Metadata = const NullValue("Metadata");
  static const NullValue Modifiers = const NullValue("Modifiers");
  static const NullValue Name = const NullValue("Name");
  static const NullValue NominalVariable = const NullValue("NominalVariable");
  static const NullValue NominalParameters = const NullValue(
    "NominalParameters",
  );
  static const NullValue OperatorList = const NullValue("OperatorList");
  static const NullValue ParameterDefaultValue = const NullValue(
    "ParameterDefaultValue",
  );
  static const NullValue Pattern = const NullValue("Pattern");
  static const NullValue PatternList = const NullValue("PatternList");
  static const NullValue Prefix = const NullValue("Prefix");
  static const NullValue RecordTypeFieldList = const NullValue(
    "RecordTypeFieldList",
  );
  static const NullValue ShowClause = const NullValue("ShowClause");
  static const NullValue StringLiteral = const NullValue("StringLiteral");
  static const NullValue StructuralParameters = const NullValue(
    "StructuralParameters",
  );
  static const NullValue Token = const NullValue("Token");
  static const NullValue Type = const NullValue("Type");
  static const NullValue TypeArguments = const NullValue("TypeArguments");
  static const NullValue TypeBuilder = const NullValue("TypeBuilder");
  static const NullValue TypeBuilderList = const NullValue("TypeBuilderList");
  static const NullValue TypeList = const NullValue("TypeList");
  static const NullValue VarFinalOrConstToken = const NullValue(
    "VarFinalOrConstToken",
  );
  static const NullValue VariableDeclarationList = const NullValue(
    "VariableDeclarationList",
  );
  static const NullValue WithClause = const NullValue("WithClause");
}

abstract class StackListener extends Listener with StackChecker {
  static const bool debugStack = false;
  final Stack stack = debugStack ? new DebugStack() : new StackImpl();

  /// Checks that [value] matches the expected [kind].
  ///
  /// Use this in assert statements like
  ///
  ///     assert(checkValue(token, ValueKind.Token, value));
  ///
  /// to document and validate the expected value kind.
  bool checkValue(Token? token, ValueKind kind, Object? value) {
    return checkStackValue(uri, token?.charOffset, kind, value);
  }

  /// Checks the top of the current stack against [kinds]. If a mismatch is
  /// found, a top of the current stack is print along with the expected [kinds]
  /// marking the frames that don't match, and throws an exception.
  ///
  /// Use this in assert statements like
  ///
  ///     assert(checkState(token, [ValueKind.Integer, ValueKind.StringOrNull]))
  ///
  /// to document the expected stack and get earlier errors on unexpected stack
  /// content.
  bool checkState(Token? token, List<ValueKind> kinds) {
    return checkStackStateForAssert(uri, token?.charOffset, kinds);
  }

  @override
  int get stackHeight => stack.length;

  @override
  Object? lookupStack(int index) => stack[index];

  @override
  Uri get uri;

  /// Returns `true` if the current file is part of a `dart:` library.
  bool get isDartLibrary;

  void discard(int n) {
    for (int i = 0; i < n; i++) {
      pop();
    }
  }

  void push(Object? node) {
    if (node == null) {
      internalProblem(
        codeInternalProblemUnhandled.withArgumentsOld("null", "push"),
        /* charOffset = */ -1,
        uri,
      );
    }
    stack.push(node);
  }

  void pushIfNull(Token? tokenOrNull, NullValue nullValue) {
    if (tokenOrNull == null) stack.push(nullValue);
  }

  Object? peek() => stack.isNotEmpty ? stack.last : null;

  Object? pop([NullValue? nullValue]) {
    return stack.pop(nullValue);
  }

  Object? popIfNotNull(Object? value) {
    return value == null ? null : pop();
  }

  void debugEvent(String name) {
    // printEvent(name);
  }

  void printEvent(String name) {
    print('\n------------------');
    for (Object? o in stack.values) {
      String s = "  $o";
      int index = s.indexOf("\n");
      if (index != -1) {
        s = s.substring(/* start = */ 0, index) + "...";
      }
      print(s);
    }
    print("  >> $name");
  }

  @override
  void logEvent(String name) {
    printEvent(name);
    internalProblem(
      codeInternalProblemUnhandled.withArgumentsOld(name, "$runtimeType"),
      /* charOffset = */ -1,
      uri,
    );
  }

  @override
  void handleNoName(Token token) {
    debugEvent("handleNoName");
    push(NullValues.Identifier);
  }

  @override
  void endInitializer(Token endToken) {
    debugEvent("endInitializer");
  }

  void checkEmpty(int charOffset) {
    if (stack.isNotEmpty) {
      internalProblem(
        codeInternalProblemStackNotEmpty.withArgumentsOld(
          "${runtimeType}",
          stack.values.join("\n  "),
        ),
        charOffset,
        uri,
      );
    }
  }

  @override
  void endTopLevelDeclaration(Token endToken) {
    debugEvent("TopLevelDeclaration");
    checkEmpty(endToken.charOffset);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    debugEvent("CompilationUnit");
    checkEmpty(token.charOffset);
  }

  @override
  void handleClassExtends(Token? extendsKeyword, int typeCount) {
    debugEvent("ClassExtends");
  }

  @override
  void handleMixinOn(Token? onKeyword, int typeCount) {
    debugEvent("MixinOn");
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token? nativeToken) {
    debugEvent("ClassHeader");
  }

  @override
  void handleMixinHeader(Token mixinKeyword) {
    debugEvent("MixinHeader");
  }

  @override
  void handleRecoverDeclarationHeader(DeclarationHeaderKind kind) {
    debugEvent("RecoverClassHeader");
  }

  @override
  void handleRecoverMixinHeader() {
    debugEvent("RecoverMixinHeader");
  }

  @override
  void handleImplements(Token? implementsKeyword, int interfacesCount) {
    debugEvent("Implements");
  }

  @override
  void handleNoTypeArguments(Token token) {
    debugEvent("NoTypeArguments");
    push(NullValues.TypeArguments);
  }

  @override
  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
    push(NullValues.NominalParameters);
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments");
  }

  @override
  void handleNoType(Token lastConsumed) {
    debugEvent("NoType");
    push(NullValues.TypeBuilder);
  }

  @override
  void handleNoFormalParameters(Token token, MemberKind kind) {
    debugEvent("NoFormalParameters");
    push(NullValues.FormalParameters);
  }

  @override
  void handleNoArguments(Token token) {
    debugEvent("NoArguments");
    push(NullValues.Arguments);
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBody");
    push(NullValues.FunctionBody);
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodyIgnored");
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodySkipped");
  }

  @override
  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
    push(NullValues.FunctionBody);
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers");
    push(NullValues.Initializers);
  }

  @override
  void handleParenthesizedCondition(Token token, Token? case_, Token? when) {
    debugEvent("handleParenthesizedCondition");
  }

  @override
  void endRecordLiteral(Token token, int count, Token? constKeyword) {
    debugEvent("RecordLiteral");
  }

  @override
  void endParenthesizedExpression(Token token) {
    debugEvent("ParenthesizedExpression");
  }

  @override
  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    push(token);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");
    if (interpolationCount == 0) {
      Token token = pop() as Token;
      push(unescapeString(token.lexeme, token, this));
    } else {
      internalProblem(
        codeInternalProblemUnhandled.withArgumentsOld(
          "string interpolation",
          "endLiteralString",
        ),
        endToken.charOffset,
        uri,
      );
    }
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
    if (hasName) {
      pop(); // Pop the native name which is a String.
    }
  }

  @override
  void handleDirectivesOnly() {
    pop(); // Discard the metadata.
  }

  @override
  void handleExtraneousExpression(Token token, Message message) {
    debugEvent("ExtraneousExpression");
    pop(); // Discard the extraneous expression.
  }

  @override
  void endCaseExpression(Token caseKeyword, Token? when, Token colon) {
    debugEvent("CaseExpression");
  }

  @override
  void endCatchClause(Token token) {
    debugEvent("CatchClause");
  }

  @override
  void handleRecoverableError(
    Message message,
    Token startToken,
    Token endToken,
  ) {
    debugEvent("Error: ${message.problemMessage}");
    if (isIgnoredError(message.code, startToken)) return;
    addProblem(
      message,
      startToken.charOffset,
      lengthOfSpan(startToken, endToken),
    );
  }

  bool isIgnoredError(Code code, Token token) {
    if (code == codeNativeClauseShouldBeAnnotation) {
      // TODO(danrubel): Ignore this error until we deprecate `native`
      // support.
      return true;
    } else if (code == codeCatchSyntaxExtraParameters) {
      // Ignored. This error is handled by the BodyBuilder.
      return true;
    } else if (code == codeBuiltInIdentifierInDeclaration) {
      if (isDartLibrary) return true;
      return false;
    } else {
      return false;
    }
  }

  @override
  void handleUnescapeError(
    Message message,
    Token token,
    int stringOffset,
    int length,
  ) {
    addProblem(message, token.charOffset + stringOffset, length);
  }

  void addProblem(
    Message message,
    int charOffset,
    int length, {
    bool wasHandled = false,
    List<LocatedMessage> context,
  });
}

abstract class Stack {
  /// Pops [count] elements from the stack and puts it into [list].
  /// Returns `null` if a [ParserRecovery] value is found, or [list] otherwise.
  List<T?>? popList<T>(int count, List<T?> list, NullValue? nullValue);

  /// Pops [count] elements from the stack and puts it into [list].
  /// Returns `null` if a [ParserRecovery] value is found, or [list] otherwise.
  List<T>? popNonNullableList<T>(int count, List<T> list);

  void push(Object value);

  /// Will return `null` instead of [NullValue].
  Object? get last;

  bool get isNotEmpty;

  List<Object?> get values;

  Object? pop(NullValue? nullValue);

  int get length;

  /// Raw, i.e. [NullValue]s will be returned instead of `null`.
  Object? operator [](int index);
}

class StackImpl implements Stack {
  List<Object?> array = new List<Object?>.filled(
    /* length = */ 8,
    /* fill = */ null,
  );
  int arrayLength = 0;

  @override
  bool get isNotEmpty => arrayLength > 0;

  @override
  int get length => arrayLength;

  @override
  Object? get last {
    final Object? value = array[arrayLength - 1];
    return value is NullValue ? null : value;
  }

  @override
  Object? operator [](int index) {
    return array[arrayLength - 1 - index];
  }

  @override
  void push(Object value) {
    array[arrayLength++] = value;
    if (array.length == arrayLength) {
      _grow();
    }
  }

  @override
  Object? pop(NullValue? nullValue) {
    assert(arrayLength > 0);
    final Object? value = array[--arrayLength];
    array[arrayLength] = null;
    if (value is! NullValue) {
      return value;
    } else if (nullValue == null || value == nullValue) {
      return null;
    } else {
      return value;
    }
  }

  @override
  List<T?>? popList<T>(int count, List<T?> list, NullValue? nullValue) {
    assert(arrayLength >= count);
    final List<Object?> array = this.array;
    final int length = arrayLength;
    final int startIndex = length - count;
    bool isParserRecovery = false;
    for (int i = 0; i < count; i++) {
      int arrayIndex = startIndex + i;
      final Object? value = array[arrayIndex];
      array[arrayIndex] = null;
      if (value is NullValue && nullValue == null ||
          identical(value, nullValue)) {
        list[i] = null;
      } else if (value is ParserRecovery) {
        isParserRecovery = true;
      } else {
        assert(value is! NullValue);
        list[i] = value as T;
      }
    }
    arrayLength -= count;

    return isParserRecovery ? null : list;
  }

  @override
  List<T>? popNonNullableList<T>(int count, List<T> list) {
    assert(arrayLength >= count);
    final List<Object?> array = this.array;
    final int length = arrayLength;
    final int startIndex = length - count;
    bool isParserRecovery = false;
    for (int i = 0; i < count; i++) {
      int arrayIndex = startIndex + i;
      final Object? value = array[arrayIndex];
      array[arrayIndex] = null;
      if (value is ParserRecovery) {
        isParserRecovery = true;
      } else {
        list[i] = value as T;
      }
    }
    arrayLength -= count;

    return isParserRecovery ? null : list;
  }

  @override
  List<Object?> get values {
    final int length = arrayLength;
    final List<Object?> list = new List<Object?>.filled(
      length,
      /* fill = */ null,
    );
    list.setRange(/* start = */ 0, length, array);
    return list;
  }

  void _grow() {
    final int length = array.length;
    final List<Object?> newArray = new List<Object?>.filled(
      length * 2,
      /* fill = */ null,
    );
    newArray.setRange(/* start = */ 0, length, array, /* skipCount = */ 0);
    array = newArray;
  }
}

class DebugStack implements Stack {
  Stack realStack = new StackImpl();
  Stack stackTraceStack = new StackImpl();
  List<StackTrace?> latestStacktraces = <StackTrace?>[];

  @override
  Object? operator [](int index) {
    Object? result = realStack[index];
    latestStacktraces.clear();
    latestStacktraces.add(stackTraceStack[index] as StackTrace);
    return result;
  }

  @override
  bool get isNotEmpty => realStack.isNotEmpty;

  @override
  Object? get last {
    Object? result = this[0];
    if (result is NullValue) return null;
    return result;
  }

  @override
  int get length => realStack.length;

  @override
  Object? pop(NullValue? nullValue) {
    Object? result = realStack.pop(nullValue);
    latestStacktraces.clear();
    latestStacktraces.add(
      stackTraceStack.pop(/* nullValue = */ null) as StackTrace,
    );
    return result;
  }

  @override
  List<T?>? popList<T>(int count, List<T?> list, NullValue? nullValue) {
    List<T?>? result = realStack.popList(count, list, nullValue);
    latestStacktraces.length = count;
    stackTraceStack.popList(count, latestStacktraces, /* nullValue = */ null);
    return result;
  }

  @override
  List<T>? popNonNullableList<T>(int count, List<T> list) {
    List<T>? result = realStack.popNonNullableList(count, list);
    latestStacktraces.length = count;
    stackTraceStack.popList(count, latestStacktraces, /* nullValue = */ null);
    return result;
  }

  @override
  void push(Object value) {
    realStack.push(value);
    stackTraceStack.push(StackTrace.current);
  }

  @override
  List<Object?> get values => realStack.values;
}

/// Helper constant for popping a list of the top of a [Stack].  This helper
/// returns null instead of empty lists, and the lists returned are of fixed
/// length.
class FixedNullableList<T> {
  const FixedNullableList();

  List<T?>? pop(Stack stack, int count, [NullValue? nullValue]) {
    if (count == 0) return null;
    return stack.popList(
      count,
      new List<T?>.filled(count, /* fill = */ null),
      nullValue,
    );
  }

  List<T>? popNonNullable(Stack stack, int count, T dummyValue) {
    if (count == 0) return null;
    return stack.popNonNullableList(
      count,
      new List<T>.filled(count, dummyValue),
    );
  }

  List<T?>? popPadded(
    Stack stack,
    int count,
    int padding, [
    NullValue? nullValue,
  ]) {
    if (count + padding == 0) return null;
    return stack.popList(
      count,
      new List<T?>.filled(count + padding, /* fill = */ null),
      nullValue,
    );
  }

  List<T>? popPaddedNonNullable(
    Stack stack,
    int count,
    int padding,
    T dummyValue,
  ) {
    if (count + padding == 0) return null;
    return stack.popNonNullableList(
      count,
      new List<T>.filled(count + padding, dummyValue),
    );
  }
}

/// Helper constant for popping a list of the top of a [Stack].  This helper
/// returns growable lists (also when empty).
class GrowableList<T> {
  const GrowableList();

  List<T?>? pop(Stack stack, int count, [NullValue? nullValue]) {
    return stack.popList(
      count,
      new List<T?>.filled(count, /* fill = */ null, growable: true),
      nullValue,
    );
  }

  List<T>? popNonNullable(Stack stack, int count, T dummyValue) {
    if (count == 0) return null;
    return stack.popNonNullableList(
      count,
      new List<T>.filled(count, dummyValue, growable: true),
    );
  }
}

class ParserRecovery {
  final int charOffset;
  ParserRecovery(this.charOffset);

  @override
  String toString() => "ParserRecovery(@$charOffset)";
}
