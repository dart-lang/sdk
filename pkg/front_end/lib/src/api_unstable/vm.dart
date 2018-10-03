// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api_prototype/diagnostic_message.dart' show DiagnosticMessage;

import '../api_prototype/terminal_color_support.dart' show enableTerminalColors;

import '../fasta/fasta_codes.dart' show FormattedMessage;

export '../api_prototype/compiler_options.dart'
    show CompilerOptions, ProblemHandler;

export '../api_prototype/diagnostic_message.dart'
    show DiagnosticMessage, DiagnosticMessageHandler;

export '../api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;

export '../api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator, isLegalIdentifier;

export '../api_prototype/kernel_generator.dart'
    show kernelForComponent, kernelForProgram;

export '../api_prototype/memory_file_system.dart' show MemoryFileSystem;

export '../api_prototype/standard_file_system.dart' show StandardFileSystem;

export '../base/processed_options.dart' show ProcessedOptions;

export '../compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

export '../fasta/compiler_context.dart' show CompilerContext;

export '../fasta/fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        messageConstEvalContext,
        messageConstEvalFailedAssertion,
        noLength,
        templateConstEvalDeferredLibrary,
        templateConstEvalDuplicateKey,
        templateConstEvalFailedAssertionWithMessage,
        templateConstEvalInvalidBinaryOperandType,
        templateConstEvalInvalidMethodInvocation,
        templateConstEvalInvalidStaticInvocation,
        templateConstEvalInvalidStringInterpolationOperand,
        templateConstEvalInvalidType,
        templateConstEvalNegativeShift,
        templateConstEvalNonConstantLiteral,
        templateConstEvalNonConstantVariableGet,
        templateConstEvalZeroDivisor;

export '../fasta/hybrid_file_system.dart' show HybridFileSystem;

export '../fasta/kernel/utils.dart' show serializeComponent, serializeProcedure;

export '../fasta/severity.dart' show Severity;

Uri getMessageUri(FormattedMessage message) => message.uri;

void printDiagnosticMessage(
    DiagnosticMessage message, void Function(String) println) {
  if (enableTerminalColors) {
    message.ansiFormatted.forEach(println);
  } else {
    message.plainTextFormatted.forEach(println);
  }
}
