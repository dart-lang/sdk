// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'dart:async';
import 'dart:io';
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirror.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart';
import 'mock_compiler.dart';

const String SOURCE = 'source';
const Uri SOURCE_URI = const Uri.fromComponents(scheme: SOURCE, path: SOURCE);

MirrorSystem createMirrorSystem(String source) {
  MockCompiler compiler = new MockCompiler(
      analyzeOnly: true,
      analyzeAll: true,
      preserveComments: true);
  compiler.registerSource(SOURCE_URI, source);
  compiler.librariesToAnalyzeWhenRun = <Uri>[SOURCE_URI];
  compiler.runCompiler(null);
  return new Dart2JsMirrorSystem(compiler);
}

void validateDeclarationComment(String code,
                                String text,
                                String trimmedText,
                                bool isDocComment,
                                List<String> declarationNames) {
  MirrorSystem mirrors = createMirrorSystem(code);
  LibraryMirror library = mirrors.libraries[SOURCE_URI];
  Expect.isNotNull(library);
  for (String declarationName in declarationNames) {
    DeclarationMirror declaration = library.members[declarationName];
    Expect.isNotNull(declaration);
    List<InstanceMirror> metadata = declaration.metadata;
    Expect.isNotNull(metadata);
    Expect.equals(1, metadata.length);
    Expect.isTrue(metadata[0] is CommentInstanceMirror);
    CommentInstanceMirror commentMetadata = metadata[0];
    Expect.equals(text, commentMetadata.text);
    Expect.equals(trimmedText, commentMetadata.trimmedText);
    Expect.equals(isDocComment, commentMetadata.isDocComment);
  }
}

void testDeclarationComment(String declaration, List<String> declarationNames) {
  String text = 'Single line comment';
  String comment = '// $text';
  String code = '$comment\n$declaration';
  validateDeclarationComment(code, comment, text, false, declarationNames);

  comment = '/// $text';
  code = '$comment\n$declaration';
  validateDeclarationComment(code, comment, text, true, declarationNames);

  text = 'Multiline comment';
  comment = '/* $text*/';
  code = '$comment$declaration';
  validateDeclarationComment(code, comment, text, false, declarationNames);

  comment = '/** $text*/';
  code = '$comment$declaration';
  validateDeclarationComment(code, comment, text, true, declarationNames);
}

void main() {
  testDeclarationComment('var field;', ['field']);
  testDeclarationComment('int field;', ['field']);
  testDeclarationComment('int field = 0;', ['field']);
  testDeclarationComment('int field1, field2;', ['field1', 'field2']);
  testDeclarationComment('final field = 0;', ['field']);
  testDeclarationComment('final int field = 0;', ['field']);
  testDeclarationComment('final field1 = 0, field2 = 0;', ['field1', 'field2']);
  testDeclarationComment('final int field1 = 0, field2 = 0;',
                         ['field1', 'field2']);
  testDeclarationComment('const field = 0;', ['field']);
  testDeclarationComment('const int field = 0;', ['field']);
  testDeclarationComment('const field1 = 0, field2 = 0;', ['field1', 'field2']);
  testDeclarationComment('const int field1 = 0, field2 = 0;',
                         ['field1', 'field2']);
}
