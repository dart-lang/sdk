// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage, DiagnosticMessageHandler, getMessageUri;

export 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

export '../api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalArguments, parseExperimentalFlags;

export '../api_prototype/experimental_flags.dart'
    show defaultExperimentalFlags, ExperimentalFlag;

export '../api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;

export '../api_prototype/front_end.dart' show CompilerResult;

export '../api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator, IncrementalSerializer, isLegalIdentifier;

export '../api_prototype/kernel_generator.dart'
    show kernelForModule, kernelForProgram;

export '../api_prototype/memory_file_system.dart' show MemoryFileSystem;

export '../api_prototype/standard_file_system.dart' show StandardFileSystem;

export '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;

export '../base/nnbd_mode.dart' show NnbdMode;

export '../base/processed_options.dart' show ProcessedOptions;

export '../compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

export '../fasta/compiler_context.dart' show CompilerContext;

export '../fasta/fasta_codes.dart'
    show
        LocatedMessage,
        messageFfiExceptionalReturnNull,
        messageFfiExpectedConstant,
        noLength,
        templateFfiDartTypeMismatch,
        templateFfiEmptyStruct,
        templateFfiExpectedExceptionalReturn,
        templateFfiExpectedNoExceptionalReturn,
        templateFfiExtendsOrImplementsSealedClass,
        templateFfiFieldAnnotation,
        templateFfiFieldCyclic,
        templateFfiFieldInitializer,
        templateFfiFieldNoAnnotation,
        templateFfiNotStatic,
        templateFfiStructGeneric,
        templateFfiTypeInvalid,
        templateFfiTypeMismatch;

export '../fasta/hybrid_file_system.dart' show HybridFileSystem;

export '../fasta/kernel/redirecting_factory_body.dart'
    show getRedirectingFactoryBody, isRedirectingFactoryField;

export '../fasta/kernel/utils.dart'
    show
        createExpressionEvaluationComponent,
        serializeComponent,
        serializeProcedure;

export '../fasta/resolve_input_uri.dart' show resolveInputUri;
