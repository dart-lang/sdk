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

import 'package:front_end/src/fasta/util/direct_parser_ast_helper.dart'
    show
        AbstractDirectParserASTListener,
        DirectParserASTContent,
        DirectParserASTType;

DirectParserASTContent getAST(List<int> rawBytes, {bool includeBody: true}) {
  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  Utf8BytesScanner scanner =
      new Utf8BytesScanner(bytes, includeComments: false);
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
  void seen(
      String what, DirectParserASTType type, Map<String, Object> arguments) {
    switch (type) {
      case DirectParserASTType.BEGIN:
      case DirectParserASTType.HANDLE:
        // This just adds stuff.
        data.add(new DirectParserASTContent(what, type, arguments));
        break;
      case DirectParserASTType.DONE:
        // This shouldn't be seen. It's artificial.
        throw new StateError("Saw type 'DONE'");
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
          throw "Couldn't find a begin for $what. Has:\n"
              "${data.map((e) => "${e.what}: ${e.type}").join("\n")}";
        }
        String begin = data[beginIndex].what;
        String end = what;
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
        List<DirectParserASTContent> content = data.sublist(beginIndex);
        data.length = beginIndex;
        data.add(new DirectParserASTContent(
            what, DirectParserASTType.DONE, arguments)
          ..content = content);
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
