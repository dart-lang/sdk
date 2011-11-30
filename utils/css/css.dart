// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('css');

#import('../../frog/lang.dart', prefix:'lang');
#import('../../frog/file_system_memory.dart');

#source('tokenkind.dart');
#source('tokenizer.dart');
#source('tree.dart');
#source('cssselectorexception.dart');
#source('cssworld.dart');
#source('parser.dart');


void initCssWorld() {
  var fs = new MemoryFileSystem();
  lang.parseOptions('', [], fs);
  lang.initializeWorld(fs);
  lang.world.process();
  lang.world.resolveAll();

  // TODO(terry): Should be set by arguments.  When run as a tool these aren't
  // set when run internaly set these so we can compile CSS and catch any
  // problems programmatically.
  lang.options.throwOnErrors = true;
  lang.options.throwOnFatal = true;
}

// TODO(terry): Add obfuscation mapping file.
void cssParseAndValidate(String cssExpression, CssWorld world) {
  Parser parser = new Parser(new lang.SourceFile(lang.SourceFile.IN_MEMORY_FILE,
      cssExpression));
  var tree = parser.template();
  if (tree != null) {
    parser.validateTemplate(tree.selectors, world);
  }
}

// Returns pretty printed tree of the expression.
String cssParseAndValidateDebug(String cssExpression, CssWorld world) {
  Parser parser = new Parser(new lang.SourceFile(lang.SourceFile.IN_MEMORY_FILE,
      cssExpression));
  String output = "";
  String prettyTree = "";
  try {
    var tree = parser.template();
    if (tree != null) {
      prettyTree = tree.toDebugString();
      parser.validateTemplate(tree.selectors, world);
      output = prettyTree;
    }
  } catch (var e) {
    String error = e.toString();
    output = "$error\n$prettyTree";
    throw e;
  }

  return output;
}
