// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.outline_builder;

import 'package:kernel/ast.dart' show
    AsyncMarker,
    ProcedureKind;

import '../parser/parser.dart' show
    FormalParameterType,
    optional;

import '../scanner/token.dart' show
    Token;

import '../util/link.dart' show
    Link;

import '../combinator.dart' show
    Combinator;

import '../errors.dart' show
    internalError;

import '../builder/builder.dart';

import '../modifier.dart' show
    Modifier;

import 'source_library_builder.dart' show
    SourceLibraryBuilder;

import 'unhandled_listener.dart' show
    NullValue,
    Unhandled,
    UnhandledListener;

import '../parser/error_kind.dart' show
    ErrorKind;

import '../parser/dart_vm_native.dart' show
    removeNativeClause,
    skipNativeClause;

import '../operator.dart' show
    Operator,
    operatorFromString,
    operatorToString;

import '../quote.dart' show
    unescapeString;

enum MethodBody {
  Abstract,
  Regular,
  RedirectingFactoryBody,
}

AsyncMarker asyncMarkerFromTokens(Token asyncToken, Token starToken) {
  if (asyncToken == null || identical(asyncToken.stringValue, "sync")) {
    if (starToken == null) {
      return AsyncMarker.Sync;
    } else {
      assert(identical(starToken.stringValue, "*"));
      return AsyncMarker.SyncStar;
    }
  } else  if (identical(asyncToken.stringValue, "async")) {
    if (starToken == null) {
      return AsyncMarker.Async;
    } else {
      assert(identical(starToken.stringValue, "*"));
      return AsyncMarker.AsyncStar;
    }
  } else {
    return internalError("Unknown async modifier: $asyncToken");
  }
}

class OutlineBuilder extends UnhandledListener {
  final SourceLibraryBuilder library;

  final bool isDartLibrary;

  String nativeMethodName;

  OutlineBuilder(SourceLibraryBuilder library)
      : library = library,
        isDartLibrary = library.uri.scheme == "dart";

  @override
  Uri get uri => library.fileUri;

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    List arguments = pop();
    String postfix = popIfNotNull(periodBeforeName);
    List<TypeBuilder> typeArguments = pop();
    if (arguments == null) {
      String expression = pop();
      push(new MetadataBuilder.fromExpression(expression, postfix, library,
              beginToken.charOffset));
    } else {
      String typeName = pop();
      push(new MetadataBuilder.fromConstructor(
               library.addConstructorReference(
                   typeName, typeArguments, postfix,
                   beginToken.next.charOffset),
               arguments, library, beginToken.charOffset));
    }
  }

  @override
  void endHide(Token hideKeyword) {
    debugEvent("Hide");
    List<String> names = pop();
    push(new Combinator.hide(names, hideKeyword.charOffset, library.fileUri));
  }

  @override
  void endShow(Token showKeyword) {
    debugEvent("Show");
    List<String> names = pop();
    push(new Combinator.show(names, showKeyword.charOffset, library.fileUri));
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators");
    push(popList(count) ?? NullValue.Combinators);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");
    List<Combinator> combinators = pop();
    Unhandled conditionalUris = pop();
    String uri = pop();
    List<MetadataBuilder> metadata = pop();
    library.addExport(
        metadata, uri, conditionalUris, combinators, exportKeyword.charOffset);
    checkEmpty(exportKeyword.charOffset);
  }

  @override
  void endImport(Token importKeyword, Token deferredKeyword, Token asKeyword,
      Token semicolon) {
    debugEvent("endImport");
    List<Combinator> combinators = pop();
    String prefix = popIfNotNull(asKeyword);
    Unhandled conditionalUris = pop();
    String uri = pop();
    List<MetadataBuilder> metadata = pop();
    library.addImport(metadata, uri, conditionalUris, prefix, combinators,
        deferredKeyword != null, importKeyword.charOffset,
        asKeyword?.next?.charOffset ?? -1);
    checkEmpty(importKeyword.charOffset);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("Part");
    String uri = pop();
    List<MetadataBuilder> metadata = pop();
    library.addPart(metadata, uri);
    checkEmpty(partKeyword.charOffset);
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    debugEvent("OperatorName");
    push(operatorFromString(token.stringValue));
  }

  @override
  void endIdentifierList(int count) {
    debugEvent("endIdentifierList");
    push(popList(count) ?? NullValue.IdentifierList);
  }

  @override
  void handleQualified(Token period) {
    debugEvent("handleQualified");
    String name = pop();
    String receiver = pop();
    push("$receiver.$name");
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("endLibraryName");
    String name = pop();
    List<MetadataBuilder> metadata = pop();
    library.name = name;
    library.metadata = metadata;
  }

  @override
  void beginClassDeclaration(Token begin, Token name) {
    library.beginNestedDeclaration(name.value);
  }

  @override
  void endClassDeclaration(int interfacesCount, Token beginToken,
      Token classKeyword, Token extendsKeyword, Token implementsKeyword,
      Token endToken) {
    debugEvent("endClassDeclaration");
    List<TypeBuilder> interfaces = popList(interfacesCount);
    TypeBuilder supertype = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    String name = pop();
    if (typeVariables != null && supertype is MixinApplicationBuilder) {
      supertype.typeVariables = typeVariables;
      supertype.subclassName = name;
    }
    int modifiers = Modifier.validate(pop());
    List<MetadataBuilder> metadata = pop();
    library.addClass(metadata, modifiers, name, typeVariables, supertype,
        interfaces, beginToken.charOffset);
    checkEmpty(beginToken.charOffset);
  }

  ProcedureKind computeProcedureKind(Token token) {
    if (token == null) return ProcedureKind.Method;
    if (optional("get", token)) return ProcedureKind.Getter;
    if (optional("set", token)) return ProcedureKind.Setter;
    return internalError("Unhandled: ${token.value}");
  }

  @override
  void beginTopLevelMethod(Token token, Token name) {
    library.beginNestedDeclaration(name.value, hasMembers: false);
  }

  @override
  void endTopLevelMethod(
      Token beginToken, Token getOrSet, Token endToken) {
    debugEvent("endTopLevelMethod");
    MethodBody kind = pop();
    AsyncMarker asyncModifier = pop();
    List<FormalParameterBuilder> formals = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    String name = pop();
    TypeBuilder returnType = pop();
    int modifiers = Modifier.validate(pop(),
        isAbstract: kind == MethodBody.Abstract);
    List<MetadataBuilder> metadata = pop();
    checkEmpty(beginToken.charOffset);
    library.addProcedure(metadata, modifiers, returnType, name,
        typeVariables, formals, asyncModifier, computeProcedureKind(getOrSet),
        beginToken.charOffset, nativeMethodName, isTopLevel: true);
    nativeMethodName = null;
  }

  @override
  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
    push(MethodBody.Abstract);
  }

  @override
  void handleFunctionBodySkipped(Token token) {
    debugEvent("handleFunctionBodySkipped");
    push(MethodBody.Regular);
  }

  @override
  void beginMethod(Token token, Token name) {
    library.beginNestedDeclaration(name.value, hasMembers: false);
  }

  @override
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    debugEvent("Method");
    MethodBody bodyKind = pop();
    if (bodyKind == MethodBody.RedirectingFactoryBody) {
      // This will cause an error later.
      pop();
    }
    AsyncMarker asyncModifier = pop();
    List<FormalParameterBuilder> formals = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    dynamic nameOrOperator = pop();
    if (Operator.subtract == nameOrOperator && formals == null) {
      nameOrOperator = Operator.unaryMinus;
    }
    String name;
    ProcedureKind kind;
    if (nameOrOperator is Operator) {
      name = operatorToString(nameOrOperator);
      kind = ProcedureKind.Operator;
    } else {
      name = nameOrOperator;
      kind = computeProcedureKind(getOrSet);
    }
    TypeBuilder returnType = pop();
    int modifiers = Modifier.validate(pop(),
        isAbstract: bodyKind == MethodBody.Abstract);
    List<MetadataBuilder> metadata = pop();
    library.addProcedure(metadata, modifiers, returnType, name, typeVariables,
        formals, asyncModifier, kind, beginToken.charOffset, nativeMethodName,
        isTopLevel: false);
    nativeMethodName = null;
  }

  @override
  void endMixinApplication() {
    debugEvent("MixinApplication");
    List<TypeBuilder> mixins = pop();
    TypeBuilder supertype = pop();
    push(library.addMixinApplication(supertype, mixins, -1));
  }

  @override
  void beginNamedMixinApplication(Token begin, Token name) {
    library.beginNestedDeclaration(name.value, hasMembers: false);
  }

  @override
  void endNamedMixinApplication(
      Token beginToken, Token classKeyword, Token equals,
      Token implementsKeyword, Token endToken) {
    debugEvent("endNamedMixinApplication");
    List<TypeBuilder> interfaces = popIfNotNull(implementsKeyword);
    TypeBuilder mixinApplication = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    String name = pop();
    if (typeVariables != null && mixinApplication is MixinApplicationBuilder) {
      mixinApplication.typeVariables = typeVariables;
      mixinApplication.subclassName = name;
    }
    int modifiers = Modifier.validate(pop());
    List<MetadataBuilder> metadata = pop();
    library.addNamedMixinApplication(
        metadata, name, typeVariables, modifiers, mixinApplication, interfaces,
        beginToken.charOffset);
    checkEmpty(beginToken.charOffset);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(popList(count) ?? NullValue.TypeArguments);
  }

  @override
  void handleType(Token beginToken, Token endToken) {
    debugEvent("Type");
    List<TypeBuilder> arguments = pop();
    String name = pop();
    push(library.addNamedType(name, arguments, beginToken.charOffset));
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
    push(popList(count) ?? NullValue.TypeList);
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
    push(popList(count) ?? NullValue.TypeVariables);
  }

  @override
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    push(library.addVoidType(token.charOffset));
  }

  @override
  void endFormalParameter(Token covariantKeyword, Token thisKeyword,
      FormalParameterType kind) {
    debugEvent("FormalParameter");
    String name = pop();
    TypeBuilder type = pop();
    int modifiers = Modifier.validate(pop());
    List<MetadataBuilder> metadata = pop();
    // TODO(ahe): Needs begin token.
    push(library.addFormalParameter(metadata, modifiers, type, name,
             thisKeyword != null, thisKeyword?.charOffset ?? -1));
  }

  @override
  void handleValuedFormalParameter(Token equals, Token token) {
    debugEvent("ValuedFormalParameter");
    // Ignored for now.
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
    // Ignored for now.
  }

  @override
  void endFunctionTypedFormalParameter(Token covariantKeyword,
      Token thisKeyword, FormalParameterType kind) {
    debugEvent("FunctionTypedFormalParameter");
    pop(); // Function type parameters.
    pop(); // Type variables.
    String name = pop();
    pop(); // Return type.
    push(NullValue.Type);
    push(name);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("OptionalFormalParameters");
    FormalParameterType kind = optional("{", beginToken)
        ? FormalParameterType.NAMED : FormalParameterType.POSITIONAL;
    List parameters = popList(count);
    for (FormalParameterBuilder parameter in parameters) {
      parameter.kind = kind;
    }
    push(parameters);
  }

  @override
  void endFormalParameters(int count, Token beginToken, Token endToken) {
    debugEvent("FormalParameters");
    List formals = popList(count);
    if (formals != null && formals.isNotEmpty) {
      var last = formals.last;
      if (last is List) {
        // TODO(sigmund): change `List newList` back to `var` (this is a
        // workaround for issue #28651). Eventually, make optional
        // formals a separate stack entry (#28673).
        List newList =
            new List<FormalParameterBuilder>(formals.length - 1 + last.length);
        newList.setRange(0, formals.length - 1, formals);
        newList.setRange(formals.length - 1, newList.length, last);
        for (int i = 0; i < last.length; i++) {
          newList[i + formals.length - 1] = last[i];
        }
        formals = newList;
      }
    }
    if (formals != null) {
      for (var formal in formals) {
        if (formal is! FormalParameterBuilder) {
          internalError(formals);
        }
      }
      formals = new List<FormalParameterBuilder>.from(formals);
    }
    push(formals ?? NullValue.FormalParameters);
  }

  @override
  void endEnum(Token enumKeyword, Token endBrace, int count) {
    List<String> constants = popList(count);
    String name = pop();
    List<MetadataBuilder> metadata = pop();
    library.addEnum(metadata, name, constants, enumKeyword.charOffset);
    checkEmpty(enumKeyword.charOffset);
  }

  @override
  void beginFunctionTypeAlias(Token token) {
    library.beginNestedDeclaration(null, hasMembers: false);
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    debugEvent("endFunctionTypeAlias");
    List<FormalParameterBuilder> formals = pop();
    List<TypeVariableBuilder> typeVariables = pop();
    String name = pop();
    TypeBuilder returnType = pop();
    List<MetadataBuilder> metadata = pop();
    library.addFunctionTypeAlias(
        metadata, returnType, name, typeVariables, formals,
        typedefKeyword.charOffset);
    checkEmpty(typedefKeyword.charOffset);
  }

  @override
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    debugEvent("endTopLevelFields");
    List<String> names = popList(count);
    TypeBuilder type = pop();
    int modifiers = Modifier.validate(pop());
    List<MetadataBuilder> metadata = pop();
    library.addFields(metadata, modifiers, type, names);
    checkEmpty(beginToken.charOffset);
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    List<String> names = popList(count);
    TypeBuilder type = pop();
    int modifiers = Modifier.validate(pop());
    List<MetadataBuilder> metadata = pop();
    library.addFields(metadata, modifiers, type, names);
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    debugEvent("endTypeVariable");
    TypeBuilder bound = pop();
    String name = pop();
    push(library.addTypeVariable(name, bound, token.charOffset));
  }

  @override
  void endPartOf(Token partKeyword, Token semicolon) {
    debugEvent("endPartOf");
    String name = pop();
    List<MetadataBuilder> metadata = pop();
    library.addPartOf(metadata, name);
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    debugEvent("ConstructorReference");
    String suffix = popIfNotNull(periodBeforeName);
    List<TypeBuilder> typeArguments = pop();
    String name = pop();
    push(library.addConstructorReference(
            name, typeArguments, suffix, start.charOffset));
  }

  @override
  void beginFactoryMethod(Token token) {
    library.beginNestedDeclaration(null, hasMembers: false);
  }

  @override
  void endFactoryMethod(Token beginToken, Token endToken) {
    debugEvent("FactoryMethod");
    MethodBody kind = pop();
    ConstructorReferenceBuilder redirectionTarget;
    if (kind == MethodBody.RedirectingFactoryBody) {
      redirectionTarget = pop();
    }
    AsyncMarker asyncModifier = pop();
    List<FormalParameterBuilder> formals = pop();
    var name = pop();
    List<MetadataBuilder> metadata = pop();
    library.addFactoryMethod(metadata, name, formals, asyncModifier,
        redirectionTarget, beginToken.charOffset, nativeMethodName);
    nativeMethodName = null;
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    debugEvent("RedirectingFactoryBody");
    push(MethodBody.RedirectingFactoryBody);
  }

  @override
  void endFieldInitializer(Token assignmentOperator) {
    debugEvent("FieldInitializer");
    // Ignoring field initializers for now.
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers");
    // Ignored for now.
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers");
    // This is a constructor initializer and it's ignored for now.
  }

  @override
  void endMember() {
    debugEvent("Member");
    assert(nativeMethodName == null);
  }

  @override
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassBody");
  }

  @override
  void handleAsyncModifier(Token asyncToken, Token starToken) {
    debugEvent("AsyncModifier");
    push(asyncMarkerFromTokens(asyncToken, starToken));
  }

  @override
  void handleModifier(Token token) {
    debugEvent("Modifier");
    push(new Modifier.fromString(token.stringValue));
  }

  @override
  void handleModifiers(int count) {
    debugEvent("Modifiers");
    push(popList(count) ?? NullValue.Modifiers);
  }

  @override
  Token handleUnrecoverableError(Token token, ErrorKind kind, Map arguments) {
    if (isDartLibrary && kind == ErrorKind.ExpectedBlockToSkip) {
      Token recover = skipNativeClause(token);
      if (recover != null) {
        nativeMethodName = unescapeString(token.next.value);
        return recover;
      }
    }
    return super.handleUnrecoverableError(token, kind, arguments);
  }

  @override
  Link<Token> handleMemberName(Link<Token> identifiers) {
    if (!isDartLibrary || identifiers.isEmpty) return identifiers;
    return removeNativeClause(identifiers);
  }

  @override
  void debugEvent(String name) {
    // printEvent(name);
  }
}
