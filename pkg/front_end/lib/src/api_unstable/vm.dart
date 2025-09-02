// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show CfeDiagnosticMessage, DiagnosticMessageHandler, getMessageUri;
export 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show CfeSeverity;
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
export '../base/processed_options.dart' show ProcessedOptions;
export '../codes/cfe_codes.dart'
    show
        LocatedMessage,
        codeFfiAbiSpecificIntegerInvalid,
        codeFfiAbiSpecificIntegerMappingInvalid,
        codeFfiAddressOfMustBeNative,
        codeFfiCreateOfStructOrUnion,
        codeFfiDeeplyImmutableClassesMustBeFinalOrSealed,
        codeFfiDeeplyImmutableFieldsModifiers,
        codeFfiDeeplyImmutableFieldsMustBeDeeplyImmutable,
        codeFfiDeeplyImmutableSubtypesMustBeDeeplyImmutable,
        codeFfiDeeplyImmutableSupertypeMustBeDeeplyImmutable,
        codeFfiDefaultAssetDuplicate,
        codeFfiExceptionalReturnNull,
        codeFfiExpectedConstant,
        codeFfiLeafCallMustNotReturnHandle,
        codeFfiLeafCallMustNotTakeHandle,
        codeFfiNativeDuplicateAnnotations,
        codeFfiNativeFieldMissingType,
        codeFfiNativeFieldMustBeStatic,
        codeFfiNativeFieldType,
        codeFfiNativeMustBeExternal,
        codeFfiNativeOnlyNativeFieldWrapperClassCanBePointer,
        codeFfiPackedAnnotationAlignment,
        codeNonPositiveArrayDimensions,
        codeWeakReferenceMismatchReturnAndArgumentTypes,
        codeWeakReferenceNotOneArgument,
        codeWeakReferenceNotStatic,
        codeWeakReferenceReturnTypeNotNullable,
        codeWeakReferenceTargetHasParameters,
        codeWeakReferenceTargetNotStaticTearoff,
        noLength,
        codeCantHaveNamedParameters,
        codeCantHaveOptionalParameters,
        codeFfiNativeCallableListenerReturnVoid,
        codeFfiCompoundImplementsFinalizable,
        codeFfiDartTypeMismatch,
        codeFfiEmptyStruct,
        codeFfiExpectedConstantArg,
        codeFfiExpectedExceptionalReturn,
        codeFfiExpectedNoExceptionalReturn,
        codeFfiExtendsOrImplementsSealedClass,
        codeFfiFieldAnnotation,
        codeFfiFieldCyclic,
        codeFfiFieldInitializer,
        codeFfiFieldNoAnnotation,
        codeFfiFieldNull,
        codeFfiNativeUnexpectedNumberOfParameters,
        codeFfiNativeUnexpectedNumberOfParametersWithReceiver,
        codeFfiNotStatic,
        codeFfiPackedAnnotation,
        codeFfiSizeAnnotation,
        codeFfiSizeAnnotationDimensions,
        codeFfiStructGeneric,
        codeFfiTypeInvalid,
        codeFfiTypeMismatch;
export '../compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
export '../kernel/utils.dart'
    show
        createExpressionEvaluationComponent,
        serializeComponent,
        serializeProcedure;
