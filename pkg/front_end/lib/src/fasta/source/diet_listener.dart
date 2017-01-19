// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.diet_listener;

import 'package:kernel/ast.dart' show
    AsyncMarker;

import 'package:kernel/class_hierarchy.dart' show
    ClassHierarchy;

import 'package:kernel/core_types.dart' show
    CoreTypes;

import 'package:front_end/src/fasta/parser/parser.dart' show
    Parser,
    optional;

import 'package:front_end/src/fasta/scanner/token.dart' show
    BeginGroupToken,
    Token;

import '../errors.dart' show
    Crash,
    InputError,
    inputError,
    internalError;

import 'stack_listener.dart' show
    StackListener;

import '../kernel/body_builder.dart' show
    BodyBuilder;

import '../builder/builder.dart';

import '../analyzer/analyzer.dart';

import '../builder/scope.dart' show
    Scope;

import '../ast_kind.dart' show
    AstKind;

import 'source_library_builder.dart' show
    SourceLibraryBuilder;

import 'source_class_builder.dart' show
    isConstructorName;

class DietListener extends StackListener {
  final SourceLibraryBuilder library;

  final ElementStore elementStore;

  final ClassHierarchy hierarchy;

  final CoreTypes coreTypes;

  final AstKind astKind;

  ClassBuilder currentClass;

  /// For top-level declarations, this is the library scope. For class members,
  /// this is the instance scope of [currentClass].
  Scope memberScope;

  DietListener(SourceLibraryBuilder library, this.elementStore, this.hierarchy,
      this.coreTypes, this.astKind)
      : library = library,
        memberScope = library.scope;

  Uri get uri => library.uri;

  void discard(int n) {
    for (int i =0; i < n; i++) {
      pop();
    }
  }

  void endMetadataStar(int count, bool forParameter) {
    debugEvent("MetadataStar");
  }

  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    popIfNotNull(periodBeforeName);
    discard(1);
  }

  void endPartOf(Token partKeyword, Token semicolon) {
    debugEvent("PartOf");
    discard(1);
  }

  void handleNoArguments(Token token) {
    debugEvent("NoArguments");
  }

  void handleModifiers(int count) {
    debugEvent("Modifiers");
  }

  void handleNoTypeArguments(Token token) {
    debugEvent("NoTypeArguments");
  }

  void handleNoType(Token token) {
    debugEvent("NoType");
  }

  void endType(Token beginToken, Token endToken) {
    debugEvent("Type");
    discard(1);
  }

  void endTypeList(int count) {
    debugEvent("TypeList");
  }

  void endMixinApplication() {
    debugEvent("MixinApplication");
  }

  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
  }

  void endInitializer(Token assignmentOperator) {
    debugEvent("Initializer");
  }

  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
  }

  void endFormalParameters(int count, Token beginToken, Token endToken) {
    debugEvent("FormalParameters");
    assert(count == 0); // Count is always 0 as the diet parser skips formals.
    if (identical(peek(), "-") && identical(beginToken.next, endToken)) {
      pop();
      push("unary-");
    }
    push(beginToken);
  }

  void handleNoFormalParameters(Token token) {
    debugEvent("NoFormalParameters");
    if (identical(peek(), "-")) {
      pop();
      push("unary-");
    }
    push(token);
  }

  void endFunctionTypeAlias(Token typedefKeyword, Token endToken) {
    debugEvent("FunctionTypeAlias");
    discard(2); // Name + endToken.
    checkEmpty();
  }

  void endFields(int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    List<String> names = popList(count);
    Builder builder = lookupBuilder(beginToken, null, names.first);
    buildFields(beginToken, false, builder.isInstanceMember);
  }

  void handleAsyncModifier(Token asyncToken, Token startToken) {
    debugEvent("AsyncModifier");
  }

  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    debugEvent("TopLevelMethod");
    Token bodyToken = pop();
    String name = pop();
    checkEmpty();
    buildFunctionBody(bodyToken, lookupBuilder(beginToken, getOrSet, name));
  }

  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
  }

  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    debugEvent("TopLevelFields");
    discard(count);
    buildFields(beginToken, true, false);
  }

  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
  }

  void handleNoInitializers() {
    debugEvent("NoInitializers");
  }

  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers");
  }

  void handleQualified(Token period) {
    debugEvent("handleQualified");
    // TODO(ahe): Shared with outline_builder.dart.
    String name = pop();
    String receiver = pop();
    push("$receiver.$name");
  }

  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("endLibraryName");
    discard(1);
  }

  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
  }

  void endLiteralString(int interpolationCount) {
    debugEvent("endLiteralString");
    discard(interpolationCount);
  }

  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");
  }

  void endDottedName(int count, Token firstIdentifier) {
    debugEvent("DottedName");
    discard(count);
  }

  void endConditionalUri(Token ifKeyword, Token equalitySign) {
    debugEvent("ConditionalUri");
  }

  void endConditionalUris(int count) {
    debugEvent("ConditionalUris");
  }

  void handleOperatorName(Token operatorKeyword, Token token) {
    debugEvent("OperatorName");
    push(token.stringValue);
  }

  void endIdentifierList(int count) {
    debugEvent("IdentifierList");
    discard(count);
  }

  void endShow(Token showKeyword) {
    debugEvent("Show");
  }

  void endHide(Token hideKeyword) {
    debugEvent("Hide");
  }

  void endCombinators(int count) {
    debugEvent("Combinators");
  }

  void endImport(Token importKeyword, Token DeferredKeyword, Token asKeyword,
      Token semicolon) {
    debugEvent("Import");
    popIfNotNull(asKeyword);
  }

  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");
  }

  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("Part");
  }

  void endTypeVariable(Token token, Token extendsOrSuper) {
    debugEvent("TypeVariable");
    discard(1);
  }

  void endTypeVariables(int count, Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
  }

  void handleModifier(Token token) {
    debugEvent("Modifier");
  }

  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    debugEvent("ConstructorReference");
    popIfNotNull(periodBeforeName);
  }

  void endFactoryMethod(Token beginToken, Token endToken) {
    debugEvent("FactoryMethod");
    BeginGroupToken bodyToken = pop();
    String name = pop();
    checkEmpty();
    if (bodyToken == null || optional("=", bodyToken.endGroup.next)) {
      return;
    }
    buildFunctionBody(bodyToken, lookupBuilder(beginToken, null, name));
  }

  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    debugEvent("RedirectingFactoryBody");
    discard(1); // ConstructorReference.
  }

  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    debugEvent("Method");
    Token bodyToken = pop();
    String name = pop();
    checkEmpty();
    if (bodyToken == null) {
      return;
    }
    buildFunctionBody(bodyToken, lookupBuilder(beginToken, getOrSet, name));
  }

  StackListener createListener(MemberBuilder builder, Scope memberScope,
      bool isInstanceMember, [Scope formalParameterScope]) {
    switch (astKind) {
      case AstKind.Kernel:
        return new BodyBuilder(library, builder, memberScope,
            formalParameterScope, hierarchy, coreTypes, currentClass,
            isInstanceMember);

      case AstKind.Analyzer:
        return new AstBuilder(library, builder, elementStore, memberScope);
    }

    return internalError("Unknown $astKind");
  }

  void buildFunctionBody(Token token, ProcedureBuilder builder) {
    Scope typeParameterScope = builder.computeTypeParameterScope(memberScope);
    Scope formalParameterScope =
        builder.computeFormalParameterScope(typeParameterScope);
    assert(typeParameterScope != null);
    assert(formalParameterScope != null);
    parseFunctionBody(
        createListener(builder, typeParameterScope, builder.isInstanceMember,
            formalParameterScope),
        token);
  }

  void buildFields(Token token, bool isTopLevel, bool isInstanceMember) {
    parseFields(createListener(null, memberScope, isInstanceMember),
        token, isTopLevel);
  }

  void endMember() {
    debugEvent("Member");
    checkEmpty();
  }

  void beginClassBody(Token token) {
    debugEvent("beginClassBody");
    String name = pop();
    assert(currentClass == null);
    currentClass = lookupBuilder(token, null, name);
    assert(memberScope == library.scope);
    memberScope = currentClass.computeInstanceScope(memberScope);
  }

  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassBody");
    currentClass = null;
    checkEmpty();
    memberScope = library.scope;
  }

  void endClassDeclaration(int interfacesCount, Token beginToken,
      Token extendsKeyword, Token implementsKeyword, Token endToken) {
    debugEvent("ClassDeclaration");
    checkEmpty();
  }

  void endEnum(Token enumKeyword, Token endBrace, int count) {
    debugEvent("Enum");
    discard(count);
    pop(); // Name.
    checkEmpty();
  }

  void endNamedMixinApplication(
      Token classKeyword, Token implementsKeyword, Token endToken) {
    debugEvent("NamedMixinApplication");
    pop(); // Name.
    checkEmpty();
  }

  void parseFunctionBody(StackListener listener, Token token) {
    try {
      Parser parser = new Parser(listener);
      token = parser.parseFormalParametersOpt(token);
      var formals = listener.pop();
      listener.checkEmpty();
      listener.prepareInitializers();
      token = parser.parseInitializersOpt(token);
      token = parser.parseAsyncModifier(token);
      AsyncMarker asyncModifier = listener.pop();
      bool isExpression = false;
      bool allowAbstract = true;
      parser.parseFunctionBody(token, isExpression, allowAbstract);
      var body = listener.pop();
      listener.checkEmpty();
      listener.finishFunction(formals, asyncModifier, body);
    } on InputError {
      rethrow;
    } catch (e, s) {
      throw new Crash(uri, token.charOffset, e, s);
    }
  }

  void parseFields(StackListener listener, Token token, bool isTopLevel) {
    Parser parser = new Parser(listener);
    if (isTopLevel) {
      token = parser.parseTopLevelMember(token);
    } else {
      token = parser.parseMember(token);
    }
    listener.checkEmpty();
  }

  Builder lookupBuilder(Token token, Token getOrSet, String name) {
    Builder builder;
    if (currentClass != null) {
      builder = currentClass.members[name];
      if (builder == null && isConstructorName(name, currentClass.name)) {
        int index = name.indexOf(".");
        name = index == -1 ? "" : name.substring(index + 1);
        builder = currentClass.members[name];
      }
    } else {
      builder = library.members[name];
    }
    if (builder == null) {
      return internalError("@${token.charOffset}: builder not found: $name");
    }
    if (builder.next != null) {
      Builder getterBuilder;
      Builder setterBuilder;
      Builder current = builder;
      while (current != null) {
        if (current.isGetter && getterBuilder == null) {
          getterBuilder = current;
        } else if (current.isSetter && setterBuilder == null) {
          setterBuilder = current;
        } else {
          return inputError(uri, token.charOffset, "Duplicated name: $name");
        }
        current = current.next;
      }
      assert(getOrSet != null);
      if (optional("get", getOrSet)) return getterBuilder;
      if (optional("set", getOrSet)) return setterBuilder;
    }
    return builder;
  }

  void debugEvent(String name) {
    // print("  ${stack.join('\n  ')}");
    // print(name);
  }
}
