// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint8List;

import 'dart:io' show File;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show ClassMemberParser, Parser;

import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:front_end/src/fasta/util/direct_parser_ast_helper.dart';

DirectParserASTContentCompilationUnitEnd getAST(List<int> rawBytes,
    {bool includeBody: true, bool includeComments: false}) {
  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  Utf8BytesScanner scanner =
      new Utf8BytesScanner(bytes, includeComments: includeComments);
  Token firstToken = scanner.tokenize();
  if (firstToken == null) {
    throw "firstToken is null";
  }

  DirectParserASTListener listener = new DirectParserASTListener();
  Parser parser;
  if (includeBody) {
    parser = new Parser(listener);
  } else {
    parser = new ClassMemberParser(listener);
  }
  parser.parseUnit(firstToken);
  return listener.data.single;
}

extension GeneralASTContentExtension on DirectParserASTContent {
  bool isClass() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentClassOrNamedMixinApplicationPreludeBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentClassDeclarationEnd) {
      return false;
    }

    return true;
  }

  List<E> recursivelyFind<E extends DirectParserASTContent>() {
    Set<E> result = {};
    _recursivelyFindInternal(this, result);
    return result.toList();
  }

  static void _recursivelyFindInternal<E extends DirectParserASTContent>(
      DirectParserASTContent node, Set<E> result) {
    if (node is E) {
      result.add(node);
      return;
    }
    if (node.children == null) return;
    for (DirectParserASTContent child in node.children) {
      _recursivelyFindInternal(child, result);
    }
  }
}

extension CompilationUnitExtension on DirectParserASTContentCompilationUnitEnd {
  List<DirectParserASTContentTopLevelDeclarationEnd> getClasses() {
    List<DirectParserASTContentTopLevelDeclarationEnd> result = [];
    for (DirectParserASTContent topLevel in children) {
      if (!topLevel.isClass()) continue;
      result.add(topLevel);
    }
    return result;
  }

  DirectParserASTContentCompilationUnitBegin getBegin() {
    return children.first;
  }
}

extension TopLevelDeclarationExtension
    on DirectParserASTContentTopLevelDeclarationEnd {
  DirectParserASTContentIdentifierHandle getClassIdentifier() {
    if (!isClass()) {
      throw "Not a class";
    }
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentIdentifierHandle) return child;
    }
    throw "Not found.";
  }

  DirectParserASTContentClassDeclarationEnd getClassDeclaration() {
    if (!isClass()) {
      throw "Not a class";
    }
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentClassDeclarationEnd) {
        return child;
      }
    }
    throw "Not found.";
  }
}

extension ClassDeclaration on DirectParserASTContentClassDeclarationEnd {
  DirectParserASTContentClassOrMixinBodyEnd getClassOrMixinBody() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentClassOrMixinBodyEnd) return child;
    }
    throw "Not found.";
  }

  DirectParserASTContentClassExtendsHandle getClassExtends() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentClassExtendsHandle) return child;
    }
    throw "Not found.";
  }
}

extension ClassOrMixinBodyExtension
    on DirectParserASTContentClassOrMixinBodyEnd {
  List<DirectParserASTContentMemberEnd> getMembers() {
    List<DirectParserASTContentMemberEnd> members = [];
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentMemberEnd) {
        members.add(child);
      }
    }
    return members;
  }
}

extension MemberExtension on DirectParserASTContentMemberEnd {
  bool isClassConstructor() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentClassConstructorEnd) return true;
    return false;
  }

  DirectParserASTContentClassConstructorEnd getClassConstructor() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentClassConstructorEnd) return child;
    throw "Not found";
  }

  bool isClassFields() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentClassFieldsEnd) return true;
    return false;
  }

  DirectParserASTContentClassFieldsEnd getClassFields() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentClassFieldsEnd) return child;
    throw "Not found";
  }
}

extension ClassFieldsExtension on DirectParserASTContentClassFieldsEnd {
  List<DirectParserASTContentIdentifierHandle> getFieldIdentifiers() {
    // For now blindly assume that the last count identifiers are the names
    // of the fields.
    int countLeft = count;
    List<DirectParserASTContentIdentifierHandle> identifiers =
        new List<DirectParserASTContentIdentifierHandle>(count);
    for (int i = children.length - 1; i >= 0; i--) {
      DirectParserASTContent child = children[i];
      if (child is DirectParserASTContentIdentifierHandle) {
        countLeft--;
        identifiers[countLeft] = child;
        if (countLeft == 0) break;
      }
    }
    if (countLeft != 0) throw "Didn't find the expected number of identifiers";
    return identifiers;
  }

  DirectParserASTContentTypeHandle getFirstType() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentTypeHandle) return child;
    }
    return null;
  }

  DirectParserASTContentFieldInitializerEnd getFieldInitializer() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentFieldInitializerEnd) return child;
    }
    return null;
  }
}

extension ClassConstructorExtension
    on DirectParserASTContentClassConstructorEnd {
  DirectParserASTContentFormalParametersEnd getFormalParameters() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentFormalParametersEnd) {
        return child;
      }
    }
    throw "Not found";
  }

  DirectParserASTContentInitializersEnd getInitializers() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentInitializersEnd) {
        return child;
      }
    }
    return null;
  }

  DirectParserASTContentBlockFunctionBodyEnd getBlockFunctionBody() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentBlockFunctionBodyEnd) {
        return child;
      }
    }
    return null;
  }
}

extension FormalParametersExtension
    on DirectParserASTContentFormalParametersEnd {
  List<DirectParserASTContentFormalParameterEnd> getFormalParameters() {
    List<DirectParserASTContentFormalParameterEnd> result = [];
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentFormalParameterEnd) {
        result.add(child);
      }
    }
    return result;
  }

  DirectParserASTContentOptionalFormalParametersEnd
      getOptionalFormalParameters() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentOptionalFormalParametersEnd) {
        return child;
      }
    }
    return null;
  }
}

extension FormalParameterExtension on DirectParserASTContentFormalParameterEnd {
  DirectParserASTContentFormalParameterBegin getBegin() {
    return children.first;
  }
}

extension OptionalFormalParametersExtension
    on DirectParserASTContentOptionalFormalParametersEnd {
  List<DirectParserASTContentFormalParameterEnd> getFormalParameters() {
    List<DirectParserASTContentFormalParameterEnd> result = [];
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentFormalParameterEnd) {
        result.add(child);
      }
    }
    return result;
  }
}

extension InitializersExtension on DirectParserASTContentInitializersEnd {
  List<DirectParserASTContentInitializerEnd> getInitializers() {
    List<DirectParserASTContentInitializerEnd> result = [];
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentInitializerEnd) {
        result.add(child);
      }
    }
    return result;
  }

  DirectParserASTContentInitializersBegin getBegin() {
    return children.first;
  }
}

extension InitializerExtension on DirectParserASTContentInitializerEnd {
  DirectParserASTContentInitializerBegin getBegin() {
    return children.first;
  }
}

main(List<String> args) {
  File f = new File(args[0]);
  Uint8List data = f.readAsBytesSync();
  DirectParserASTContent ast = getAST(data);
  if (args.length > 1 && args[1] == "--benchmark") {
    Stopwatch stopwatch = new Stopwatch()..start();
    int numRuns = 100;
    for (int i = 0; i < numRuns; i++) {
      DirectParserASTContent ast2 = getAST(data);
      if (ast.what != ast2.what) {
        throw "Not the same result every time";
      }
    }
    stopwatch.stop();
    print("First $numRuns took ${stopwatch.elapsedMilliseconds} ms "
        "(i.e. ${stopwatch.elapsedMilliseconds / numRuns}ms/iteration)");
    stopwatch = new Stopwatch()..start();
    numRuns = 2500;
    for (int i = 0; i < numRuns; i++) {
      DirectParserASTContent ast2 = getAST(data);
      if (ast.what != ast2.what) {
        throw "Not the same result every time";
      }
    }
    stopwatch.stop();
    print("Next $numRuns took ${stopwatch.elapsedMilliseconds} ms "
        "(i.e. ${stopwatch.elapsedMilliseconds / numRuns}ms/iteration)");
  } else {
    print(ast);
  }
}

class DirectParserASTListener extends AbstractDirectParserASTListener {
  void seen(DirectParserASTContent entry) {
    switch (entry.type) {
      case DirectParserASTType.BEGIN:
      case DirectParserASTType.HANDLE:
        // This just adds stuff.
        data.add(entry);
        break;
      case DirectParserASTType.END:
        // End should gobble up everything until the corresponding begin (which
        // should be the latest begin).
        int beginIndex;
        for (int i = data.length - 1; i >= 0; i--) {
          if (data[i].type == DirectParserASTType.BEGIN) {
            beginIndex = i;
            break;
          }
        }
        if (beginIndex == null) {
          throw "Couldn't find a begin for ${entry.what}. Has:\n"
              "${data.map((e) => "${e.what}: ${e.type}").join("\n")}";
        }
        String begin = data[beginIndex].what;
        String end = entry.what;
        if (begin == end) {
          // Exact match.
        } else if (end == "TopLevelDeclaration" &&
            (begin == "ExtensionDeclarationPrelude" ||
                begin == "ClassOrNamedMixinApplicationPrelude" ||
                begin == "TopLevelMember" ||
                begin == "UncategorizedTopLevelDeclaration")) {
          // endTopLevelDeclaration is started by one of
          // beginExtensionDeclarationPrelude,
          // beginClassOrNamedMixinApplicationPrelude
          // beginTopLevelMember or beginUncategorizedTopLevelDeclaration.
        } else if (begin == "Method" &&
            (end == "ClassConstructor" ||
                end == "ClassMethod" ||
                end == "ExtensionConstructor" ||
                end == "ExtensionMethod" ||
                end == "MixinConstructor" ||
                end == "MixinMethod")) {
          // beginMethod is ended by one of endClassConstructor, endClassMethod,
          // endExtensionMethod, endMixinConstructor or endMixinMethod.
        } else if (begin == "Fields" &&
            (end == "TopLevelFields" ||
                end == "ClassFields" ||
                end == "MixinFields" ||
                end == "ExtensionFields")) {
          // beginFields is ended by one of endTopLevelFields, endMixinFields or
          // endExtensionFields.
        } else if (begin == "ForStatement" && end == "ForIn") {
          // beginForStatement is ended by either endForStatement or endForIn.
        } else if (begin == "FactoryMethod" &&
            (end == "ClassFactoryMethod" ||
                end == "MixinFactoryMethod" ||
                end == "ExtensionFactoryMethod")) {
          // beginFactoryMethod is ended by either endClassFactoryMethod,
          // endMixinFactoryMethod or endExtensionFactoryMethod.
        } else if (begin == "ForControlFlow" && (end == "ForInControlFlow")) {
          // beginForControlFlow is ended by either endForControlFlow or
          // endForInControlFlow.
        } else if (begin == "IfControlFlow" && (end == "IfElseControlFlow")) {
          // beginIfControlFlow is ended by either endIfControlFlow or
          // endIfElseControlFlow.
        } else if (begin == "AwaitExpression" &&
            (end == "InvalidAwaitExpression")) {
          // beginAwaitExpression is ended by either endAwaitExpression or
          // endInvalidAwaitExpression.
        } else if (begin == "YieldStatement" &&
            (end == "InvalidYieldStatement")) {
          // beginYieldStatement is ended by either endYieldStatement or
          // endInvalidYieldStatement.
        } else {
          throw "Unknown combination: begin$begin and end$end";
        }
        List<DirectParserASTContent> children = data.sublist(beginIndex);
        data.length = beginIndex;
        data.add(entry..children = children);
        break;
    }
  }

  @override
  void reportVarianceModifierNotEnabled(Token variance) {
    throw new UnimplementedError();
  }

  @override
  Uri get uri => throw new UnimplementedError();

  @override
  void logEvent(String name) {
    throw new UnimplementedError();
  }
}
