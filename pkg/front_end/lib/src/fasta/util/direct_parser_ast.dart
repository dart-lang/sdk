// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint8List;

import 'dart:io' show File;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show ClassMemberParser, Parser;

import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:front_end/src/fasta/util/direct_parser_ast_helper.dart';

DirectParserASTContentCompilationUnitEnd getAST(List<int> rawBytes,
    {bool includeBody: true,
    bool includeComments: false,
    bool enableExtensionMethods: false,
    bool enableNonNullable: false,
    bool enableTripleShift: false}) {
  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  ScannerConfiguration scannerConfiguration = new ScannerConfiguration(
      enableExtensionMethods: enableExtensionMethods,
      enableNonNullable: enableNonNullable,
      enableTripleShift: enableTripleShift);

  Utf8BytesScanner scanner = new Utf8BytesScanner(bytes,
      includeComments: includeComments, configuration: scannerConfiguration);
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

  DirectParserASTContentClassDeclarationEnd asClass() {
    if (!isClass()) throw "Not class";
    return children.last;
  }

  bool isImport() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentImportEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentImportEnd asImport() {
    if (!isImport()) throw "Not import";
    return children.last;
  }

  bool isExport() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentExportEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentExportEnd asExport() {
    if (!isExport()) throw "Not export";
    return children.last;
  }

  bool isEnum() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentEnumEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentEnumEnd asEnum() {
    if (!isEnum()) throw "Not enum";
    return children.last;
  }

  bool isTypedef() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentFunctionTypeAliasEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentFunctionTypeAliasEnd asTypedef() {
    if (!isTypedef()) throw "Not typedef";
    return children.last;
  }

  bool isScript() {
    if (this is! DirectParserASTContentScriptHandle) {
      return false;
    }
    return true;
  }

  DirectParserASTContentScriptHandle asScript() {
    if (!isScript()) throw "Not script";
    return this;
  }

  bool isExtension() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentExtensionDeclarationPreludeBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentExtensionDeclarationEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentExtensionDeclarationEnd asExtension() {
    if (!isExtension()) throw "Not extension";
    return children.last;
  }

  bool isInvalidTopLevelDeclaration() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first is! DirectParserASTContentTopLevelMemberBegin) {
      return false;
    }
    if (children.last
        is! DirectParserASTContentInvalidTopLevelDeclarationHandle) {
      return false;
    }

    return true;
  }

  bool isRecoverableError() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentRecoverableErrorHandle) {
      return false;
    }

    return true;
  }

  bool isRecoverImport() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentRecoverImportHandle) {
      return false;
    }

    return true;
  }

  bool isMixinDeclaration() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentClassOrNamedMixinApplicationPreludeBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentMixinDeclarationEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentMixinDeclarationEnd asMixinDeclaration() {
    if (!isMixinDeclaration()) throw "Not mixin declaration";
    return children.last;
  }

  bool isNamedMixinDeclaration() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentClassOrNamedMixinApplicationPreludeBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentNamedMixinApplicationEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentNamedMixinApplicationEnd asNamedMixinDeclaration() {
    if (!isNamedMixinDeclaration()) throw "Not named mixin declaration";
    return children.last;
  }

  bool isTopLevelMethod() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first is! DirectParserASTContentTopLevelMemberBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentTopLevelMethodEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentTopLevelMethodEnd asTopLevelMethod() {
    if (!isTopLevelMethod()) throw "Not top level method";
    return children.last;
  }

  bool isTopLevelFields() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first is! DirectParserASTContentTopLevelMemberBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentTopLevelFieldsEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentTopLevelFieldsEnd asTopLevelFields() {
    if (!isTopLevelFields()) throw "Not top level fields";
    return children.last;
  }

  bool isLibraryName() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentLibraryNameEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentLibraryNameEnd asLibraryName() {
    if (!isLibraryName()) throw "Not library name";
    return children.last;
  }

  bool isPart() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentPartEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentPartEnd asPart() {
    if (!isPart()) throw "Not part";
    return children.last;
  }

  bool isPartOf() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children.last is! DirectParserASTContentPartOfEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentPartOfEnd asPartOf() {
    if (!isPartOf()) throw "Not part of";
    return children.last;
  }

  bool isMetadata() {
    if (this is! DirectParserASTContentMetadataStarEnd) {
      return false;
    }
    if (children.first is! DirectParserASTContentMetadataStarBegin) {
      return false;
    }
    return true;
  }

  DirectParserASTContentMetadataStarEnd asMetadata() {
    if (!isMetadata()) throw "Not metadata";
    return this;
  }

  bool isFunctionBody() {
    if (this is DirectParserASTContentBlockFunctionBodyEnd) return true;
    return false;
  }

  DirectParserASTContentBlockFunctionBodyEnd asFunctionBody() {
    if (!isFunctionBody()) throw "Not function body";
    return this;
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

  void debugDumpNodeRecursively({String indent = ""}) {
    print("$indent${runtimeType} (${what}) "
        "(${deprecatedArguments})");
    if (children == null) return;
    for (DirectParserASTContent child in children) {
      child.debugDumpNodeRecursively(indent: "  $indent");
    }
  }
}

extension MetadataStarExtension on DirectParserASTContentMetadataStarEnd {
  List<DirectParserASTContentMetadataEnd> getMetadataEntries() {
    List<DirectParserASTContentMetadataEnd> result = [];
    for (DirectParserASTContent topLevel in children) {
      if (topLevel is! DirectParserASTContentMetadataEnd) continue;
      result.add(topLevel);
    }
    return result;
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

  List<DirectParserASTContentTopLevelDeclarationEnd> getMixinDeclarations() {
    List<DirectParserASTContentTopLevelDeclarationEnd> result = [];
    for (DirectParserASTContent topLevel in children) {
      if (!topLevel.isMixinDeclaration()) continue;
      result.add(topLevel);
    }
    return result;
  }

  List<DirectParserASTContentImportEnd> getImports() {
    List<DirectParserASTContentImportEnd> result = [];
    for (DirectParserASTContent topLevel in children) {
      if (!topLevel.isImport()) continue;
      result.add(topLevel.children.last);
    }
    return result;
  }

  List<DirectParserASTContentExportEnd> getExports() {
    List<DirectParserASTContentExportEnd> result = [];
    for (DirectParserASTContent topLevel in children) {
      if (!topLevel.isExport()) continue;
      result.add(topLevel.children.last);
    }
    return result;
  }

  // List<DirectParserASTContentMetadataStarEnd> getMetadata() {
  //   List<DirectParserASTContentMetadataStarEnd> result = [];
  //   for (DirectParserASTContent topLevel in children) {
  //     if (!topLevel.isMetadata()) continue;
  //     result.add(topLevel);
  //   }
  //   return result;
  // }

  // List<DirectParserASTContentEnumEnd> getEnums() {
  //   List<DirectParserASTContentEnumEnd> result = [];
  //   for (DirectParserASTContent topLevel in children) {
  //     if (!topLevel.isEnum()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  // List<DirectParserASTContentFunctionTypeAliasEnd> getTypedefs() {
  //   List<DirectParserASTContentFunctionTypeAliasEnd> result = [];
  //   for (DirectParserASTContent topLevel in children) {
  //     if (!topLevel.isTypedef()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  // List<DirectParserASTContentMixinDeclarationEnd> getMixinDeclarations() {
  //   List<DirectParserASTContentMixinDeclarationEnd> result = [];
  //   for (DirectParserASTContent topLevel in children) {
  //     if (!topLevel.isMixinDeclaration()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  // List<DirectParserASTContentTopLevelMethodEnd> getTopLevelMethods() {
  //   List<DirectParserASTContentTopLevelMethodEnd> result = [];
  //   for (DirectParserASTContent topLevel in children) {
  //     if (!topLevel.isTopLevelMethod()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  DirectParserASTContentCompilationUnitBegin getBegin() {
    return children.first;
  }
}

extension TopLevelDeclarationExtension
    on DirectParserASTContentTopLevelDeclarationEnd {
  DirectParserASTContentIdentifierHandle getIdentifier() {
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

extension MixinDeclarationExtension
    on DirectParserASTContentMixinDeclarationEnd {
  DirectParserASTContentClassOrMixinBodyEnd getClassOrMixinBody() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentClassOrMixinBodyEnd) return child;
    }
    throw "Not found.";
  }
}

extension ClassDeclarationExtension
    on DirectParserASTContentClassDeclarationEnd {
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

  DirectParserASTContentClassOrMixinImplementsHandle getClassImplements() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentClassOrMixinImplementsHandle) {
        return child;
      }
    }
    throw "Not found.";
  }

  DirectParserASTContentClassWithClauseHandle getClassWithClause() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentClassWithClauseHandle) {
        return child;
      }
    }
    return null;
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

  bool isClassFactoryMethod() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentClassFactoryMethodEnd) return true;
    return false;
  }

  DirectParserASTContentClassFactoryMethodEnd getClassFactoryMethod() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentClassFactoryMethodEnd) return child;
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

  bool isMixinFields() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentMixinFieldsEnd) return true;
    return false;
  }

  DirectParserASTContentMixinFieldsEnd getMixinFields() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentMixinFieldsEnd) return child;
    throw "Not found";
  }

  bool isMixinMethod() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentMixinMethodEnd) return true;
    return false;
  }

  DirectParserASTContentMixinMethodEnd getMixinMethod() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentMixinMethodEnd) return child;
    throw "Not found";
  }

  bool isMixinFactoryMethod() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentMixinFactoryMethodEnd) return true;
    return false;
  }

  DirectParserASTContentMixinFactoryMethodEnd getMixinFactoryMethod() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentMixinFactoryMethodEnd) return child;
    throw "Not found";
  }

  bool isMixinConstructor() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentMixinConstructorEnd) return true;
    return false;
  }

  DirectParserASTContentMixinConstructorEnd getMixinConstructor() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentMixinConstructorEnd) return child;
    throw "Not found";
  }

  bool isClassMethod() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentClassMethodEnd) return true;
    return false;
  }

  DirectParserASTContentClassMethodEnd getClassMethod() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentClassMethodEnd) return child;
    throw "Not found";
  }

  bool isClassRecoverableError() {
    DirectParserASTContent child = children[1];
    if (child is DirectParserASTContentRecoverableErrorHandle) return true;
    return false;
  }
}

extension ClassFieldsExtension on DirectParserASTContentClassFieldsEnd {
  List<DirectParserASTContentIdentifierHandle> getFieldIdentifiers() {
    // For now blindly assume that the last count identifiers are the names
    // of the fields.
    int countLeft = count;
    List<DirectParserASTContentIdentifierHandle> identifiers =
        new List<DirectParserASTContentIdentifierHandle>.filled(count, null);
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

extension ClassMethodExtension on DirectParserASTContentClassMethodEnd {
  DirectParserASTContentBlockFunctionBodyEnd getBlockFunctionBody() {
    for (DirectParserASTContent child in children) {
      if (child is DirectParserASTContentBlockFunctionBodyEnd) {
        return child;
      }
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
