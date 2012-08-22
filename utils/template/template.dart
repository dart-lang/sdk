// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('template');

#import('dart:math', prefix: 'Math');
#import('../css/css.dart', prefix:'css');
#import('../lib/file_system_memory.dart');

#source('tokenkind.dart');
#source('token.dart');
#source('source.dart');
#source('tokenizer_base.dart');
#source('tokenizer.dart');
#source('parser.dart');
#source('codegen.dart');
#source('tree.dart');
#source('htmltree.dart');
#source('utils.dart');
#source('temploptions.dart');
#source('world.dart');


void initHtmlWorld([bool commandLine = true]) {
  var fs = new MemoryFileSystem();
  //  parseOptions([], fs);
  initializeWorld(fs);

  // TODO(terry): Should be set by arguments.  When run as a tool these aren't
  // set when run internaly set these so we can compile CSS and catch any
  // problems programmatically.
  //  options.throwOnErrors = true;
  //  options.throwOnFatal = true;
  //  options.useColors = commandLine ? true : false;
}

// TODO(terry): Add obfuscation mapping file.
List<Template> templateParseAndValidate(String template) {
  Parser parser = new Parser(new SourceFile(SourceFile.IN_MEMORY_FILE,
    template));

  return parser.parse();
//  if (tree != null) {
//    Validate.template(tree.selectors, world);
//  }
}
