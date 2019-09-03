// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export '../api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalArguments, parseExperimentalFlags;

export '../api_prototype/diagnostic_message.dart'
    show DiagnosticMessage, DiagnosticMessageHandler, getMessageUri;

export '../api_prototype/experimental_flags.dart'
    show defaultExperimentalFlags, ExperimentalFlag;

export '../api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;

export '../api_prototype/front_end.dart' show CompilerResult;

export '../api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator, isLegalIdentifier;

export '../api_prototype/kernel_generator.dart'
    show kernelForModule, kernelForProgram;

export '../api_prototype/memory_file_system.dart' show MemoryFileSystem;

export '../api_prototype/standard_file_system.dart' show StandardFileSystem;

export '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;

export '../base/processed_options.dart' show ProcessedOptions;

export '../compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

export '../fasta/compiler_context.dart' show CompilerContext;

export '../fasta/fasta_codes.dart'
    show
        LocatedMessage,
        messageBytecodeLimitExceededTooManyArguments,
        messageFfiExceptionalReturnNull,
        messageFfiExpectedConstant,
        noLength,
        templateFfiDartTypeMismatch,
        templateFfiExpectedExceptionalReturn,
        templateFfiExpectedNoExceptionalReturn,
        templateFfiExtendsOrImplementsSealedClass,
        templateFfiFieldAnnotation,
        templateFfiFieldInitializer,
        templateFfiFieldNoAnnotation,
        templateFfiNotStatic,
        templateFfiStructGeneric,
        templateFfiTypeInvalid,
        templateFfiTypeMismatch,
        templateFfiTypeUnsized,
        templateFfiWrongStructInheritance,
        templateIllegalRecursiveType;

export '../fasta/hybrid_file_system.dart' show HybridFileSystem;

export '../fasta/kernel/utils.dart'
    show
        createExpressionEvaluationComponent,
        serializeComponent,
        serializeProcedure;

export '../fasta/resolve_input_uri.dart' show resolveInputUri;

export '../fasta/severity.dart' show Severity;
