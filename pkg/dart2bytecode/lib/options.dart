// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Collection of options for bytecode generator.
class BytecodeOptions {
  static Map<String, String> commandLineFlags = {
    'annotations': 'Emit Dart annotations',
    'local-var-info': 'Emit debug information about local variables',
    'show-bytecode-size-stat': 'Show bytecode size breakdown',
    'source-positions': 'Emit source positions',
    'instance-field-initializers': 'Emit separate instance field initializers',
    'keep-unreachable-code':
        'Do not remove unreachable code (useful if collecting code coverage)',
    'closure-context-lowering':
        'Use the closure context lowering in Kernel AST instead of computing it',
    'embed-source-text': 'Embed the source text of scripts',
  };

  bool enableAsserts;
  bool emitSourcePositions;
  bool emitLocalVarInfo;
  bool emitAnnotations;
  bool emitInstanceFieldInitializers;
  bool omitAssertSourcePositions;
  bool keepUnreachableCode;
  bool showBytecodeSizeStatistics;
  bool isClosureContextLoweringEnabled;
  bool embedSourceText;

  BytecodeOptions({
    this.enableAsserts = false,
    this.emitSourcePositions = false,
    this.emitLocalVarInfo = false,
    this.emitAnnotations = false,
    this.emitInstanceFieldInitializers = false,
    this.omitAssertSourcePositions = false,
    this.keepUnreachableCode = false,
    this.showBytecodeSizeStatistics = false,
    this.isClosureContextLoweringEnabled = false,
    this.embedSourceText = false,
  }) {}

  void parseCommandLineFlags(List<String>? flags) {
    if (flags == null) {
      return;
    }
    for (String flag in flags) {
      switch (flag) {
        case 'source-positions':
          emitSourcePositions = true;
          break;
        case 'local-var-info':
          emitLocalVarInfo = true;
          break;
        case 'annotations':
          emitAnnotations = true;
          break;
        case 'instance-field-initializers':
          emitInstanceFieldInitializers = true;
          break;
        case 'keep-unreachable-code':
          keepUnreachableCode = true;
          break;
        case 'show-bytecode-size-stat':
          showBytecodeSizeStatistics = true;
          break;
        case 'closure-context-lowering':
          isClosureContextLoweringEnabled = true;
          break;
        case 'embed-source-text':
          embedSourceText = true;
          break;
        default:
          throw 'Unexpected bytecode flag $flag';
      }
    }
  }
}
