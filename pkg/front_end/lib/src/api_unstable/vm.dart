// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage, DiagnosticMessageHandler, getMessageUri;
export 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
export 'package:_fe_analyzer_shared/src/util/options.dart';
export 'package:_fe_analyzer_shared/src/util/resolve_input_uri.dart'
    show resolveInputUri;

export '../api_prototype/compiler_options.dart'
    show
        CompilerOptions,
        InvocationMode,
        Verbosity,
        parseExperimentalArguments,
        parseExperimentalFlags;
export '../api_prototype/experimental_flags.dart'
    show defaultExperimentalFlags, ExperimentalFlag;
export '../api_prototype/expression_compilation_tools.dart'
    show createDefinitionsWithTypes, createTypeParametersWithBounds;
export '../api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;
export '../api_prototype/front_end.dart' show CompilerResult;
export '../api_prototype/incremental_kernel_generator.dart'
    show
        IncrementalCompilerResult,
        IncrementalKernelGenerator,
        IncrementalSerializer,
        isLegalIdentifier;
export '../api_prototype/kernel_generator.dart'
    show kernelForModule, kernelForProgram;
export '../api_prototype/lowering_predicates.dart'
    show isExtensionThisName, isExtensionTypeThis;
export '../api_prototype/memory_file_system.dart' show MemoryFileSystem;
export '../api_prototype/standard_file_system.dart' show StandardFileSystem;
export '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage, enableColors;
export '../base/compiler_context.dart' show CompilerContext;
export '../base/hybrid_file_system.dart' show HybridFileSystem;
export '../base/nnbd_mode.dart' show NnbdMode;
export '../base/processed_options.dart' show ProcessedOptions;
export '../codes/cfe_codes.dart'
    show
        LocatedMessage,
        messageFfiAbiSpecificIntegerInvalid,
        messageFfiAbiSpecificIntegerMappingInvalid,
        messageFfiAddressOfMustBeNative,
        messageFfiCreateOfStructOrUnion,
        messageFfiDeeplyImmutableClassesMustBeFinalOrSealed,
        messageFfiDeeplyImmutableFieldsModifiers,
        messageFfiDeeplyImmutableFieldsMustBeDeeplyImmutable,
        messageFfiDeeplyImmutableSubtypesMustBeDeeplyImmutable,
        messageFfiDeeplyImmutableSupertypeMustBeDeeplyImmutable,
        messageFfiDefaultAssetDuplicate,
        messageFfiExceptionalReturnNull,
        messageFfiExpectedConstant,
        messageFfiLeafCallMustNotReturnHandle,
        messageFfiLeafCallMustNotTakeHandle,
        messageFfiNativeDuplicateAnnotations,
        messageFfiNativeFieldMissingType,
        messageFfiNativeFieldMustBeStatic,
        messageFfiNativeFieldType,
        messageFfiNativeMustBeExternal,
        messageFfiNativeOnlyNativeFieldWrapperClassCanBePointer,
        messageFfiPackedAnnotationAlignment,
        messageNonPositiveArrayDimensions,
        messageWeakReferenceMismatchReturnAndArgumentTypes,
        messageWeakReferenceNotOneArgument,
        messageWeakReferenceNotStatic,
        messageWeakReferenceReturnTypeNotNullable,
        messageWeakReferenceTargetHasParameters,
        messageWeakReferenceTargetNotStaticTearoff,
        noLength,
        templateCantHaveNamedParameters,
        templateCantHaveOptionalParameters,
        templateFfiNativeCallableListenerReturnVoid,
        templateFfiCompoundImplementsFinalizable,
        templateFfiDartTypeMismatch,
        templateFfiEmptyStruct,
        templateFfiExpectedConstantArg,
        templateFfiExpectedExceptionalReturn,
        templateFfiExpectedNoExceptionalReturn,
        templateFfiExtendsOrImplementsSealedClass,
        templateFfiFieldAnnotation,
        templateFfiFieldCyclic,
        templateFfiFieldInitializer,
        templateFfiFieldNoAnnotation,
        templateFfiFieldNull,
        templateFfiNativeUnexpectedNumberOfParameters,
        templateFfiNativeUnexpectedNumberOfParametersWithReceiver,
        templateFfiNotStatic,
        templateFfiPackedAnnotation,
        templateFfiSizeAnnotation,
        templateFfiSizeAnnotationDimensions,
        templateFfiStructGeneric,
        templateFfiTypeInvalid,
        templateFfiTypeMismatch;
export '../compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
export '../kernel/utils.dart'
    show
        createExpressionEvaluationComponent,
        serializeComponent,
        serializeProcedure;
