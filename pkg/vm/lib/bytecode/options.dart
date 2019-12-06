// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.options;

/// Collection of options for bytecode generator.
class BytecodeOptions {
  static Map<String, String> commandLineFlags = {
    'annotations': 'Emit Dart annotations',
    'local-var-info': 'Emit debug information about local variables',
    'debugger-stops': 'Emit bytecode instructions for stopping in the debugger',
    'show-bytecode-size-stat': 'Show bytecode size breakdown',
    'source-positions': 'Emit source positions',
    'instance-field-initializers': 'Emit separate instance field initializers',
    'keep-unreachable-code':
        'Do not remove unreachable code (useful if collecting code coverage)',
    'avoid-closure-call-instructions':
        'Do not emit closure call instructions (useful if collecting code '
            'coverage, as closure call instructions are not tracked by code '
            'coverage)',
  };

  bool enableAsserts;
  bool causalAsyncStacks;
  bool emitSourcePositions;
  bool emitSourceFiles;
  bool emitLocalVarInfo;
  bool emitDebuggerStops;
  bool emitAnnotations;
  bool emitInstanceFieldInitializers;
  bool omitAssertSourcePositions;
  bool keepUnreachableCode;
  bool avoidClosureCallInstructions;
  bool showBytecodeSizeStatistics;
  Map<String, String> environmentDefines;

  BytecodeOptions(
      {this.enableAsserts = false,
      this.causalAsyncStacks,
      this.emitSourcePositions = false,
      this.emitSourceFiles = false,
      this.emitLocalVarInfo = false,
      this.emitDebuggerStops = false,
      this.emitAnnotations = false,
      this.emitInstanceFieldInitializers = false,
      this.omitAssertSourcePositions = false,
      this.keepUnreachableCode = false,
      this.avoidClosureCallInstructions = false,
      this.showBytecodeSizeStatistics = false,
      bool aot = false,
      this.environmentDefines = const <String, String>{}}) {
    causalAsyncStacks ??=
        environmentDefines['dart.developer.causal_async_stacks'] == 'true';
    if (aot) {
      emitSourcePositions = true;
      emitLocalVarInfo = true;
      causalAsyncStacks = true;
    }
  }

  void parseCommandLineFlags(List<String> flags) {
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
        case 'debugger-stops':
          emitDebuggerStops = true;
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
        case 'avoid-closure-call-instructions':
          avoidClosureCallInstructions = true;
          break;
        case 'show-bytecode-size-stat':
          showBytecodeSizeStatistics = true;
          break;
        default:
          throw 'Unexpected bytecode flag $flag';
      }
    }
  }
}
