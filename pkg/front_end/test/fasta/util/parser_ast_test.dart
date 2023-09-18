// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:front_end/src/fasta/util/parser_ast.dart';
import 'package:front_end/src/fasta/util/parser_ast_helper.dart';

late Uri base;

void main(List<String> args) {
  File script = new File.fromUri(Platform.script);
  base = script.parent.uri;

  testTopLevelStuff();
  testClassStuff();
  testMixinStuff();

  if (!args.contains("--fast")) {
    canParseTopLevelIshOfAllFrontendFiles();
  }
}

void canParseTopLevelIshOfAllFrontendFiles() {
  Directory directory = new Directory.fromUri(base.resolve("../../../"));
  int processed = 0;
  int errors = 0;
  for (FileSystemEntity entry in directory.listSync(recursive: true)) {
    if (entry is File) {
      if (!entry.path.endsWith(".dart")) continue;
      try {
        processed++;
        List<int> data = entry.readAsBytesSync();
        CompilationUnitEnd ast = getAST(data,
            includeBody: true,
            includeComments: true,
            enableExtensionMethods: true,
            enableNonNullable: false);
        splitIntoChunks(ast, data);
        for (ParserAstNode child in ast.children!) {
          if (child.isClass()) {
            splitIntoChunks(
                child.asClass().getClassOrMixinOrExtensionBody(), data);
          } else if (child.isMixinDeclaration()) {
            splitIntoChunks(
                child.asMixinDeclaration().getClassOrMixinOrExtensionBody(),
                data);
          }
        }
      } catch (e, st) {
        print("Failure on $entry:\n$e\n\n$st\n\n--------------\n\n");
        errors++;
      }
    }
  }
  print("Processed $processed files in $directory. "
      "Encountered $errors errors.");
}

void testTopLevelStuff() {
  File file = new File.fromUri(
      base.resolve("parser_ast_test_data/top_level_stuff.txt"));
  List<int> data = file.readAsBytesSync();
  CompilationUnitEnd ast = getAST(data,
      includeBody: true,
      includeComments: true,
      enableExtensionMethods: true,
      enableNonNullable: false);
  expect(2, ast.getImports().length);
  expect(2, ast.getExports().length);

  List<String> foundChunks = splitIntoChunks(ast, data);
  expect(22, foundChunks.length);
  expect("library top_level_stuff;", foundChunks[0]);
  expect('import "top_level_stuff_helper.dart";', foundChunks[1]);
  expect('export "top_level_stuff_helper.dart";', foundChunks[2]);
  expect(
      'import "top_level_stuff_helper.dart" show a, b, '
      'c hide d, e, f show foo;',
      foundChunks[3]);
  expect(
      'export "top_level_stuff_helper.dart" show a, b, '
      'c hide d, e, f show foo;',
      foundChunks[4]);
  expect("part 'top_level_stuff_helper.dart';", foundChunks[5]);
  expect('@metadataOneOnThisOne("bla")\n', foundChunks[6]);
  expect("@metadataTwoOnThisOne\n", foundChunks[7]);
  expect("""void toplevelMethod() {
  // no content
}""", foundChunks[8]);
  expect("""List<E> anotherTopLevelMethod<E>() {
  return null;
}""", foundChunks[9]);
  expect("enum FooEnum { A, B, Bla }", foundChunks[10]);
  expect("""class FooClass {
  // no content.
}""", foundChunks[11]);
  expect("""mixin FooMixin {
  // no content.
}""", foundChunks[12]);
  expect("""class A<T> {
  // no content.
}""", foundChunks[13]);
  expect("typedef B = Function();", foundChunks[14]);
  expect("""mixin C<T> on A<T> {
  // no content.
}""", foundChunks[15]);
  expect("""extension D<T> on A<T> {
  // no content.
}""", foundChunks[16]);
  expect("class E = A with FooClass;", foundChunks[17]);
  expect("int field1;", foundChunks[18]);
  expect("int field2, field3;", foundChunks[19]);
  expect("int field4 = 42;", foundChunks[20]);
  expect("@AnnotationAtEOF", foundChunks[21]);

  file = new File.fromUri(
      base.resolve("parser_ast_test_data/top_level_stuff_helper.txt"));
  data = file.readAsBytesSync();
  ast = getAST(data,
      includeBody: true,
      includeComments: true,
      enableExtensionMethods: true,
      enableNonNullable: false);
  foundChunks = splitIntoChunks(ast, data);
  expect(1, foundChunks.length);
  expect("part of 'top_level_stuff.txt';", foundChunks[0]);

  file =
      new File.fromUri(base.resolve("parser_ast_test_data/script_handle.txt"));
  data = file.readAsBytesSync();
  ast = getAST(data,
      includeBody: true,
      includeComments: true,
      enableExtensionMethods: true,
      enableNonNullable: false);
  foundChunks = splitIntoChunks(ast, data);
  expect(1, foundChunks.length);
  expect("#!/usr/bin/env dart -c", foundChunks[0]);
}

void testClassStuff() {
  File file = new File.fromUri(base.resolve("parser_ast_test_data/class.txt"));
  List<int> data = file.readAsBytesSync();
  CompilationUnitEnd ast = getAST(data,
      includeBody: true,
      includeComments: true,
      enableExtensionMethods: true,
      enableNonNullable: false);
  List<TopLevelDeclarationEnd> classes = ast.getClasses();
  expect(2, classes.length);

  TopLevelDeclarationEnd decl = classes[0];
  ClassDeclarationEnd cls = decl.asClass();
  expect("Foo", decl.getIdentifier().token.lexeme);
  ClassExtendsHandle extendsDecl = cls.getClassExtends();
  expect("extends", extendsDecl.extendsKeyword?.lexeme);
  ImplementsHandle implementsDecl = cls.getClassImplements();
  expect("implements", implementsDecl.implementsKeyword?.lexeme);
  ClassWithClauseHandle? withClauseDecl = cls.getClassWithClause();
  expect(null, withClauseDecl);
  List<MemberEnd> members = cls.getClassOrMixinOrExtensionBody().getMembers();
  expect(5, members.length);
  expect(members[0].isClassConstructor(), true);
  expect(members[1].isClassFactoryMethod(), true);
  expect(members[2].isClassMethod(), true);
  expect(members[3].isClassMethod(), true);
  expect(members[4].isClassFields(), true);

  List<String> chunks =
      splitIntoChunks(cls.getClassOrMixinOrExtensionBody(), data);
  expect(5, chunks.length);
  expect("""Foo() {
    // Constructor
  }""", chunks[0]);
  expect("factory Foo.factory() => Foo();", chunks[1]);
  expect("""void method() {
    // instance method.
  }""", chunks[2]);
  expect("""static void staticMethod() {
    // static method.
  }""", chunks[3]);
  expect("int field1, field2 = 42;", chunks[4]);

  chunks = processItem(
      members[0].getClassConstructor().getBlockFunctionBody()!, data);
  expect(1, chunks.length);
  expect("""{
    // Constructor
  }""", chunks[0]);
  chunks =
      processItem(members[2].getClassMethod().getBlockFunctionBody()!, data);
  expect(1, chunks.length);
  expect("""{
    // instance method.
  }""", chunks[0]);
  chunks =
      processItem(members[3].getClassMethod().getBlockFunctionBody()!, data);
  expect(1, chunks.length);
  expect("""{
    // static method.
  }""", chunks[0]);

  // TODO: Move (something like) this into the check-all-files-thing.
  for (MemberEnd member in cls.getClassOrMixinOrExtensionBody().getMembers()) {
    if (member.isClassConstructor()) continue;
    if (member.isClassFactoryMethod()) continue;
    if (member.isClassFields()) continue;
    if (member.isClassMethod()) continue;
    throw "$member --- ${member.children}";
  }

  decl = classes[1];
  cls = decl.asClass();
  expect("Foo2", decl.getIdentifier().token.lexeme);
  extendsDecl = cls.getClassExtends();
  expect(null, extendsDecl.extendsKeyword?.lexeme);
  implementsDecl = cls.getClassImplements();
  expect(null, implementsDecl.implementsKeyword?.lexeme);
  withClauseDecl = cls.getClassWithClause();
  expect("with", withClauseDecl!.withKeyword.lexeme);
  members = cls.getClassOrMixinOrExtensionBody().getMembers();
  expect(0, members.length);
}

void testMixinStuff() {
  File file = new File.fromUri(base.resolve("parser_ast_test_data/mixin.txt"));
  List<int> data = file.readAsBytesSync();
  CompilationUnitEnd ast = getAST(data,
      includeBody: true,
      includeComments: true,
      enableExtensionMethods: true,
      enableNonNullable: false);
  List<TopLevelDeclarationEnd> mixins = ast.getMixinDeclarations();
  expect(mixins.length, 1);

  TopLevelDeclarationEnd decl = mixins[0];
  MixinDeclarationEnd mxn = decl.asMixinDeclaration();
  expect("B", decl.getIdentifier().token.lexeme);

  List<MemberEnd> members = mxn.getClassOrMixinOrExtensionBody().getMembers();
  expect(4, members.length);
  expect(members[0].isMixinFields(), true);
  expect(members[1].isMixinMethod(), true);
  expect(members[2].isMixinFactoryMethod(), true);
  expect(members[3].isMixinConstructor(), true);

  List<String> chunks =
      splitIntoChunks(mxn.getClassOrMixinOrExtensionBody(), data);
  expect(4, chunks.length);
  expect("static int staticField = 0;", chunks[0]);
  expect("""void foo() {
    // empty
  }""", chunks[1]);
  expect("""factory B() {
    // empty
  }""", chunks[2]);
  expect("""B.foo() {
    // empty
  }""", chunks[3]);
}

void expect<E>(E expect, E actual) {
  if (expect != actual) throw "Expected '$expect' but got '$actual'";
}

List<String> splitIntoChunks(ParserAstNode ast, List<int> data) {
  List<String> foundChunks = [];
  for (ParserAstNode child in ast.children!) {
    foundChunks.addAll(processItem(child, data));
  }
  return foundChunks;
}

List<String> processItem(ParserAstNode item, List<int> data) {
  if (item.isClass()) {
    ClassDeclarationEnd cls = item.asClass();
    return [
      getCutContent(data, cls.beginToken.offset,
          cls.endToken.offset + cls.endToken.length)
    ];
  } else if (item.isMetadata()) {
    MetadataStarEnd metadataStar = item.asMetadata();
    List<MetadataEnd> entries = metadataStar.getMetadataEntries();
    if (entries.isNotEmpty) {
      List<String> chunks = [];
      for (MetadataEnd metadata in entries) {
        chunks.add(getCutContent(
            data, metadata.beginToken.offset, metadata.endToken.offset));
      }
      return chunks;
    }
    return const [];
  } else if (item.isImport()) {
    ImportEnd import = item.asImport();
    return [
      getCutContent(data, import.importKeyword.offset,
          import.semicolon!.offset + import.semicolon!.length)
    ];
  } else if (item.isExport()) {
    ExportEnd export = item.asExport();
    return [
      getCutContent(data, export.exportKeyword.offset,
          export.semicolon.offset + export.semicolon.length)
    ];
  } else if (item.isLibraryName()) {
    LibraryNameEnd name = item.asLibraryName();
    return [
      getCutContent(data, name.libraryKeyword.offset,
          name.semicolon.offset + name.semicolon.length)
    ];
  } else if (item.isPart()) {
    PartEnd part = item.asPart();
    return [
      getCutContent(data, part.partKeyword.offset,
          part.semicolon.offset + part.semicolon.length)
    ];
  } else if (item.isPartOf()) {
    PartOfEnd partOf = item.asPartOf();
    return [
      getCutContent(data, partOf.partKeyword.offset,
          partOf.semicolon.offset + partOf.semicolon.length)
    ];
  } else if (item.isTopLevelMethod()) {
    TopLevelMethodEnd method = item.asTopLevelMethod();
    return [
      getCutContent(data, method.beginToken.offset,
          method.endToken.offset + method.endToken.length)
    ];
  } else if (item.isTopLevelFields()) {
    TopLevelFieldsEnd fields = item.asTopLevelFields();
    return [
      getCutContent(data, fields.beginToken.offset,
          fields.endToken.offset + fields.endToken.length)
    ];
  } else if (item.isEnum()) {
    EnumEnd declaration = item.asEnum();
    return [
      getCutContent(
          data,
          declaration.enumKeyword.offset,
          declaration.leftBrace.endGroup!.offset +
              declaration.leftBrace.endGroup!.length)
    ];
  } else if (item.isMixinDeclaration()) {
    MixinDeclarationEnd mixinDecl = item.asMixinDeclaration();
    return [
      getCutContent(data, mixinDecl.beginToken.offset,
          mixinDecl.endToken.offset + mixinDecl.endToken.length)
    ];
  } else if (item.isNamedMixinDeclaration()) {
    NamedMixinApplicationEnd namedMixinDecl = item.asNamedMixinDeclaration();
    return [
      getCutContent(data, namedMixinDecl.begin.offset,
          namedMixinDecl.endToken.offset + namedMixinDecl.endToken.length)
    ];
  } else if (item.isTypedef()) {
    TypedefEnd typedefDecl = item.asTypedef();
    return [
      getCutContent(data, typedefDecl.typedefKeyword.offset,
          typedefDecl.endToken.offset + typedefDecl.endToken.length)
    ];
  } else if (item.isExtension()) {
    ExtensionDeclarationEnd extensionDecl = item.asExtension();
    return [
      getCutContent(data, extensionDecl.extensionKeyword.offset,
          extensionDecl.endToken.offset + extensionDecl.endToken.length)
    ];
  } else if (item.isScript()) {
    ScriptHandle script = item.asScript();
    return [
      getCutContent(
          data, script.token.offset, script.token.offset + script.token.length)
    ];
  } else if (item is MemberEnd) {
    if (item.isClassConstructor()) {
      ClassConstructorEnd decl = item.getClassConstructor();
      return [
        getCutContent(data, decl.beginToken.offset,
            decl.endToken.offset + decl.endToken.length)
      ];
    } else if (item.isClassFactoryMethod()) {
      ClassFactoryMethodEnd decl = item.getClassFactoryMethod();
      return [
        getCutContent(data, decl.beginToken.offset,
            decl.endToken.offset + decl.endToken.length)
      ];
    } else if (item.isClassMethod()) {
      ClassMethodEnd decl = item.getClassMethod();
      return [
        getCutContent(data, decl.beginToken.offset,
            decl.endToken.offset + decl.endToken.length)
      ];
    } else if (item.isClassFields()) {
      ClassFieldsEnd decl = item.getClassFields();
      return [
        getCutContent(data, decl.beginToken.offset,
            decl.endToken.offset + decl.endToken.length)
      ];
    } else if (item.isClassFields()) {
      ClassFieldsEnd decl = item.getClassFields();
      return [
        getCutContent(data, decl.beginToken.offset,
            decl.endToken.offset + decl.endToken.length)
      ];
    } else if (item.isMixinFields()) {
      MixinFieldsEnd decl = item.getMixinFields();
      return [
        getCutContent(data, decl.beginToken.offset,
            decl.endToken.offset + decl.endToken.length)
      ];
    } else if (item.isMixinMethod()) {
      MixinMethodEnd decl = item.getMixinMethod();
      return [
        getCutContent(data, decl.beginToken.offset,
            decl.endToken.offset + decl.endToken.length)
      ];
    } else if (item.isMixinFactoryMethod()) {
      MixinFactoryMethodEnd decl = item.getMixinFactoryMethod();
      return [
        getCutContent(data, decl.beginToken.offset,
            decl.endToken.offset + decl.endToken.length)
      ];
    } else if (item.isMixinConstructor()) {
      MixinConstructorEnd decl = item.getMixinConstructor();
      return [
        getCutContent(data, decl.beginToken.offset,
            decl.endToken.offset + decl.endToken.length)
      ];
    } else {
      if (item.type == ParserAstType.BEGIN) return const [];
      if (item.type == ParserAstType.HANDLE) return const [];
      if (item.isClassRecoverableError()) return const [];
      if (item.isRecoverableError()) return const [];
      if (item.isRecoverImport()) return const [];
      throw "Unknown: $item --- ${item.children}";
    }
  } else if (item.isFunctionBody()) {
    BlockFunctionBodyEnd decl = item.asFunctionBody();
    return [
      getCutContent(data, decl.beginToken.offset,
          decl.endToken.offset + decl.endToken.length)
    ];
  } else {
    if (item.type == ParserAstType.BEGIN) return const [];
    if (item.type == ParserAstType.HANDLE) return const [];
    if (item.isInvalidTopLevelDeclaration()) return const [];
    if (item.isRecoverableError()) return const [];
    if (item.isRecoverImport()) return const [];

    throw "Unknown: $item --- ${item.children}";
  }
}

List<int>? _contentCache;
String? _contentCacheString;
String getCutContent(List<int> content, int from, int to) {
  if (identical(content, _contentCache)) {
    // cache up to date.
  } else {
    _contentCache = content;
    _contentCacheString = utf8.decode(content);
  }
  return _contentCacheString!.substring(from, to);
}
