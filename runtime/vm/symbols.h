// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SYMBOLS_H_
#define RUNTIME_VM_SYMBOLS_H_

#include "vm/growable_array.h"
#include "vm/object.h"

namespace dart {

// Forward declarations.
class IsolateGroup;
class ObjectPointerVisitor;

// One-character symbols are added implicitly.
#define PREDEFINED_SYMBOLS_LIST(V)                                             \
  V(AbiSpecificInteger, "AbiSpecificInteger")                                  \
  V(AbstractClassInstantiationError, "AbstractClassInstantiationError")        \
  V(AllocateInvocationMirror, "_allocateInvocationMirror")                     \
  V(AllocateInvocationMirrorForClosure, "_allocateInvocationMirrorForClosure") \
  V(AnonymousClosure, "<anonymous closure>")                                   \
  V(ApiError, "ApiError")                                                      \
  V(ArgDescVar, ":arg_desc")                                                   \
  V(ArgumentError, "ArgumentError")                                            \
  V(StateError, "StateError")                                                  \
  V(AssertionError, "_AssertionError")                                         \
  V(AssignIndexToken, "[]=")                                                   \
  V(Bool, "bool")                                                              \
  V(BooleanExpression, "boolean expression")                                   \
  V(BoundsCheckForPartialInstantiation, "_boundsCheckForPartialInstantiation") \
  V(ByteData, "ByteData")                                                      \
  V(Capability, "Capability")                                                  \
  V(CheckLoaded, "_checkLoaded")                                               \
  V(Class, "Class")                                                            \
  V(ClassID, "ClassID")                                                        \
  V(ClosureData, "ClosureData")                                                \
  V(ClosureParameter, ":closure")                                              \
  V(Code, "Code")                                                              \
  V(CodeSourceMap, "CodeSourceMap")                                            \
  V(ColonMatcher, ":matcher")                                                  \
  V(_Completer, "_Completer")                                                  \
  V(_AsyncCompleter, "_AsyncCompleter")                                        \
  V(_SyncCompleter, "_SyncCompleter")                                          \
  V(Compound, "_Compound")                                                     \
  V(CompressedStackMaps, "CompressedStackMaps")                                \
  V(Context, "Context")                                                        \
  V(ContextScope, "ContextScope")                                              \
  V(Current, "current")                                                        \
  V(CurrentContextVar, ":current_context_var")                                 \
  V(DartAsync, "dart:async")                                                   \
  V(DartCollection, "dart:collection")                                         \
  V(DartCore, "dart:core")                                                     \
  V(DartDeveloper, "dart:developer")                                           \
  V(DartDeveloperTimeline, "dart.developer.timeline")                          \
  V(DartFfi, "dart:ffi")                                                       \
  V(DartInternal, "dart:_internal")                                            \
  V(DartIsVM, "dart.isVM")                                                     \
  V(DartIsolate, "dart:isolate")                                               \
  V(DartLibrary, "dart.library.")                                              \
  V(DartLibraryFfi, "dart.library.ffi")                                        \
  V(DartLibraryMirrors, "dart.library.mirrors")                                \
  V(DartMirrors, "dart:mirrors")                                               \
  V(DartNativeWrappers, "dart:nativewrappers")                                 \
  V(DartNativeWrappersLibName, "nativewrappers")                               \
  V(DartScheme, "dart:")                                                       \
  V(DartSchemePrivate, "dart:_")                                               \
  V(DartTypedData, "dart:typed_data")                                          \
  V(DartVMProduct, "dart.vm.product")                                          \
  V(DartVMService, "dart:_vmservice")                                          \
  V(DebugProcedureName, ":Eval")                                               \
  V(Default, "Default")                                                        \
  V(DefaultLabel, ":L")                                                        \
  V(DotCreate, "._create")                                                     \
  V(DotFieldADI, ".fieldADI")                                                  \
  V(DotFieldNI, ".fieldNI")                                                    \
  V(DotRange, ".range")                                                        \
  V(DotUnder, "._")                                                            \
  V(DotValue, ".value")                                                        \
  V(DotWithType, "._withType")                                                 \
  V(Double, "double")                                                          \
  V(Dynamic, "dynamic")                                                        \
  V(DynamicCall, "dyn:call")                                                   \
  V(DynamicCallCurrentFunctionVar, ":dyn_call_current_function")               \
  V(DynamicCallCurrentNumProcessedVar, ":dyn_call_current_num_processed")      \
  V(DynamicCallCurrentParamIndexVar, ":dyn_call_current_param_index")          \
  V(DynamicCallCurrentTypeParamVar, ":dyn_call_current_type_param")            \
  V(DynamicCallFunctionTypeArgsVar, ":dyn_call_function_type_args")            \
  V(DynamicPrefix, "dyn:")                                                     \
  V(EntryPointsTemp, ":entry_points_temp")                                     \
  V(EqualOperator, "==")                                                       \
  V(Error, "Error")                                                            \
  V(EvalSourceUri, "evaluate:source")                                          \
  V(EvaluateAssertion, "_evaluateAssertion")                                   \
  V(ExceptionHandlers, "ExceptionHandlers")                                    \
  V(ExceptionVar, ":exception_var")                                            \
  V(Expando, "Expando")                                                        \
  V(ExprTemp, ":expr_temp")                                                    \
  V(ExternalOneByteString, "_ExternalOneByteString")                           \
  V(ExternalTwoByteString, "_ExternalTwoByteString")                           \
  V(FfiAbiSpecificMapping, "_FfiAbiSpecificMapping")                           \
  V(FfiAsyncCallback, "_FfiAsyncCallback")                                     \
  V(FfiBool, "Bool")                                                           \
  V(FfiCallback, "_FfiCallback")                                               \
  V(FfiDouble, "Double")                                                       \
  V(FfiDynamicLibrary, "DynamicLibrary")                                       \
  V(FfiElementType, "elementType")                                             \
  V(FfiFieldPacking, "packing")                                                \
  V(FfiFieldTypes, "fieldTypes")                                               \
  V(FfiFloat, "Float")                                                         \
  V(FfiHandle, "Handle")                                                       \
  V(FfiInt16, "Int16")                                                         \
  V(FfiInt32, "Int32")                                                         \
  V(FfiInt64, "Int64")                                                         \
  V(FfiInt8, "Int8")                                                           \
  V(FfiIntPtr, "IntPtr")                                                       \
  V(FfiIsolateLocalCallback, "_FfiIsolateLocalCallback")                       \
  V(FfiNativeFunction, "NativeFunction")                                       \
  V(FfiNativeType, "NativeType")                                               \
  V(FfiNativeTypes, "nativeTypes")                                             \
  V(FfiPointer, "Pointer")                                                     \
  V(FfiStructLayout, "_FfiStructLayout")                                       \
  V(FfiStructLayoutArray, "_FfiInlineArray")                                   \
  V(FfiTrampolineData, "FfiTrampolineData")                                    \
  V(FfiUint16, "Uint16")                                                       \
  V(FfiUint32, "Uint32")                                                       \
  V(FfiUint64, "Uint64")                                                       \
  V(FfiUint8, "Uint8")                                                         \
  V(FfiVoid, "Void")                                                           \
  V(Field, "Field")                                                            \
  V(Finalizable, "Finalizable")                                                \
  V(FinalizerBase, "FinalizerBase")                                            \
  V(FinalizerEntry, "FinalizerEntry")                                          \
  V(FinallyRetVal, ":finally_ret_val")                                         \
  V(FirstArg, "x")                                                             \
  V(Float32List, "Float32List")                                                \
  V(Float32x4, "Float32x4")                                                    \
  V(Float32x4List, "Float32x4List")                                            \
  V(Float64List, "Float64List")                                                \
  V(Float64x2, "Float64x2")                                                    \
  V(Float64x2List, "Float64x2List")                                            \
  V(FormatException, "FormatException")                                        \
  V(ForwardingCorpse, "ForwardingCorpse")                                      \
  V(FreeListElement, "FreeListElement")                                        \
  V(Function, "Function")                                                      \
  V(FunctionResult, "function result")                                         \
  V(FunctionTypeArgumentsVar, ":function_type_arguments_var")                  \
  V(Future, "Future")                                                          \
  V(_Future, "_Future")                                                        \
  V(FutureOr, "FutureOr")                                                      \
  V(FutureValue, "Future.value")                                               \
  V(GetCall, "get:call")                                                       \
  V(GetLength, "get:length")                                                   \
  V(GetRuntimeType, "get:runtimeType")                                         \
  V(GetterPrefix, "get:")                                                      \
  V(Get_fieldNames, "get:_fieldNames")                                         \
  V(GreaterEqualOperator, ">=")                                                \
  V(HaveSameRuntimeType, "_haveSameRuntimeType")                               \
  V(ICData, "ICData")                                                          \
  V(Identical, "identical")                                                    \
  V(InTypeCast, " in type cast")                                               \
  V(Index, "index")                                                            \
  V(IndexToken, "[]")                                                          \
  V(InitPrefix, "init:")                                                       \
  V(Instructions, "Instructions")                                              \
  V(InstructionsSection, "InstructionsSection")                                \
  V(InstructionsTable, "InstructionsTable")                                    \
  V(Int, "int")                                                                \
  V(Int16List, "Int16List")                                                    \
  V(Int32List, "Int32List")                                                    \
  V(Int32x4, "Int32x4")                                                        \
  V(Int32x4List, "Int32x4List")                                                \
  V(Int64List, "Int64List")                                                    \
  V(Int8List, "Int8List")                                                      \
  V(IntegerDivisionByZeroException, "IntegerDivisionByZeroException")          \
  V(Interpolate, "_interpolate")                                               \
  V(InterpolateSingle, "_interpolateSingle")                                   \
  V(InvocationMirror, "_InvocationMirror")                                     \
  V(IsolateSpawnException, "IsolateSpawnException")                            \
  V(Iterable, "Iterable")                                                      \
  V(Iterator, "iterator")                                                      \
  V(KernelProgramInfo, "KernelProgramInfo")                                    \
  V(LanguageError, "LanguageError")                                            \
  V(LateError, "LateError")                                                    \
  V(LeftShiftOperator, "<<")                                                   \
  V(Length, "length")                                                          \
  V(LessEqualOperator, "<=")                                                   \
  V(LibraryClass, "Library")                                                   \
  V(LibraryPrefix, "LibraryPrefix")                                            \
  V(List, "List")                                                              \
  V(ListFactory, "List.")                                                      \
  V(ListFilledFactory, "List.filled")                                          \
  V(LoadLibrary, "_loadLibrary")                                               \
  V(LoadingUnit, "LoadingUnit")                                                \
  V(LocalVarDescriptors, "LocalVarDescriptors")                                \
  V(Map, "Map")                                                                \
  V(MapLiteralFactory, "Map._fromLiteral")                                     \
  V(MegamorphicCache, "MegamorphicCache")                                      \
  V(MonomorphicSmiableCall, "MonomorphicSmiableCall")                          \
  V(MoveNext, "moveNext")                                                      \
  V(Namespace, "Namespace")                                                    \
  V(Never, "Never")                                                            \
  V(NoSuchMethod, "noSuchMethod")                                              \
  V(NoSuchMethodError, "NoSuchMethodError")                                    \
  V(Null, "Null")                                                              \
  V(Number, "num")                                                             \
  V(Object, "Object")                                                          \
  V(ObjectPool, "ObjectPool")                                                  \
  V(OneByteString, "_OneByteString")                                           \
  V(OptimizedOut, "<optimized out>")                                           \
  V(OriginalParam, ":original:")                                               \
  V(OutOfMemoryError, "OutOfMemoryError")                                      \
  V(PackageScheme, "package:")                                                 \
  V(Patch, "patch")                                                            \
  V(PatchClass, "PatchClass")                                                  \
  V(PcDescriptors, "PcDescriptors")                                            \
  V(Pragma, "pragma")                                                          \
  V(PrependTypeArguments, "_prependTypeArguments")                             \
  V(QuoteIsNotASubtypeOf, "' is not a subtype of ")                            \
  V(RangeError, "RangeError")                                                  \
  V(Record, "Record")                                                          \
  V(RegExp, "RegExp")                                                          \
  V(RightShiftOperator, ">>")                                                  \
  V(SavedTryContextVar, ":saved_try_context_var")                              \
  V(Script, "Script")                                                          \
  V(SecondArg, "y")                                                            \
  V(SendPort, "SendPort")                                                      \
  V(Sentinel, "Sentinel")                                                      \
  V(Set, "Set")                                                                \
  V(SetterPrefix, "set:")                                                      \
  V(SingleTargetCache, "SingleTargetCache")                                    \
  V(SpaceIsFromSpace, " is from ")                                             \
  V(SpaceOfSpace, " of ")                                                      \
  V(SpaceWhereNewLine, " where\n")                                             \
  V(StackOverflowError, "StackOverflowError")                                  \
  V(Stream, "Stream")                                                          \
  V(StringBase, "_StringBase")                                                 \
  V(Struct, "Struct")                                                          \
  V(SubtypeTestCache, "SubtypeTestCache")                                      \
  V(SuspendStateVar, ":suspend_state_var")                                     \
  V(SwitchExpr, ":switch_expr")                                                \
  V(Symbol, "Symbol")                                                          \
  V(ThrowNew, "_throwNew")                                                     \
  V(ThrowNewInvocation, "_throwNewInvocation")                                 \
  V(ThrowNewNullAssertion, "_throwNewNullAssertion")                           \
  V(TopLevel, "::")                                                            \
  V(TransferableTypedData, "TransferableTypedData")                            \
  V(TruncDivOperator, "~/")                                                    \
  V(TryFinallyReturnValue, ":try_finally_return_value")                        \
  V(TwoByteString, "_TwoByteString")                                           \
  V(TwoSpaces, "  ")                                                           \
  V(Type, "Type")                                                              \
  V(TypeArguments, "TypeArguments")                                            \
  V(TypeArgumentsParameter, ":type_arguments")                                 \
  V(TypeError, "_TypeError")                                                   \
  V(TypeParameters, "TypeParameters")                                          \
  V(TypeQuote, "type '")                                                       \
  V(Uint16List, "Uint16List")                                                  \
  V(Uint32List, "Uint32List")                                                  \
  V(Uint64List, "Uint64List")                                                  \
  V(Uint8ClampedList, "Uint8ClampedList")                                      \
  V(Uint8List, "Uint8List")                                                    \
  V(UnaryMinus, "unary-")                                                      \
  V(UnhandledException, "UnhandledException")                                  \
  V(Union, "Union")                                                            \
  V(UnlinkedCall, "UnlinkedCall")                                              \
  V(UnsafeCast, "unsafeCast")                                                  \
  V(UnsignedRightShiftOperator, ">>>")                                         \
  V(UnsupportedError, "UnsupportedError")                                      \
  V(UnwindError, "UnwindError")                                                \
  V(Value, "value")                                                            \
  V(Values, "values")                                                          \
  V(VarArgs, "VarArgs")                                                        \
  V(WeakArray, "WeakArray")                                                    \
  V(WeakSerializationReference, "WeakSerializationReference")                  \
  V(_AsyncStarStreamController, "_AsyncStarStreamController")                  \
  V(_BufferingStreamSubscription, "_BufferingStreamSubscription")              \
  V(_ByteBuffer, "_ByteBuffer")                                                \
  V(_ByteBufferDot_New, "_ByteBuffer._New")                                    \
  V(_ByteDataView, "_ByteDataView")                                            \
  V(_Capability, "_Capability")                                                \
  V(_ClassMirror, "_ClassMirror")                                              \
  V(_Closure, "_Closure")                                                      \
  V(_ClosureCall, "_Closure.call")                                             \
  V(_CombinatorMirror, "_CombinatorMirror")                                    \
  V(_CompileTimeError, "_CompileTimeError")                                    \
  V(_ConstMap, "_ConstMap")                                                    \
  V(_ConstSet, "_ConstSet")                                                    \
  V(_ControllerSubscription, "_ControllerSubscription")                        \
  V(_CyclicInitializationError, "_CyclicInitializationError")                  \
  V(_DeletedEnumPrefix, "Deleted enum value from ")                            \
  V(_DeletedEnumSentinel, "_deleted_enum_sentinel")                            \
  V(_Double, "_Double")                                                        \
  V(_Enum, "_Enum")                                                            \
  V(_ExternalFloat32Array, "_ExternalFloat32Array")                            \
  V(_ExternalFloat32x4Array, "_ExternalFloat32x4Array")                        \
  V(_ExternalFloat64Array, "_ExternalFloat64Array")                            \
  V(_ExternalFloat64x2Array, "_ExternalFloat64x2Array")                        \
  V(_ExternalInt16Array, "_ExternalInt16Array")                                \
  V(_ExternalInt32Array, "_ExternalInt32Array")                                \
  V(_ExternalInt32x4Array, "_ExternalInt32x4Array")                            \
  V(_ExternalInt64Array, "_ExternalInt64Array")                                \
  V(_ExternalInt8Array, "_ExternalInt8Array")                                  \
  V(_ExternalUint16Array, "_ExternalUint16Array")                              \
  V(_ExternalUint32Array, "_ExternalUint32Array")                              \
  V(_ExternalUint64Array, "_ExternalUint64Array")                              \
  V(_ExternalUint8Array, "_ExternalUint8Array")                                \
  V(_ExternalUint8ClampedArray, "_ExternalUint8ClampedArray")                  \
  V(_FinalizerImpl, "_FinalizerImpl")                                          \
  V(_Float32ArrayFactory, "Float32List.")                                      \
  V(_Float32ArrayView, "_Float32ArrayView")                                    \
  V(_Float32List, "_Float32List")                                              \
  V(_Float32x4, "_Float32x4")                                                  \
  V(_Float32x4ArrayFactory, "Float32x4List.")                                  \
  V(_Float32x4ArrayView, "_Float32x4ArrayView")                                \
  V(_Float32x4List, "_Float32x4List")                                          \
  V(_Float64ArrayFactory, "Float64List.")                                      \
  V(_Float64ArrayView, "_Float64ArrayView")                                    \
  V(_Float64List, "_Float64List")                                              \
  V(_Float64x2, "_Float64x2")                                                  \
  V(_Float64x2ArrayFactory, "Float64x2List.")                                  \
  V(_Float64x2ArrayView, "_Float64x2ArrayView")                                \
  V(_Float64x2List, "_Float64x2List")                                          \
  V(_FunctionType, "_FunctionType")                                            \
  V(_FunctionTypeMirror, "_FunctionTypeMirror")                                \
  V(_FutureListener, "_FutureListener")                                        \
  V(_GrowableList, "_GrowableList")                                            \
  V(_GrowableListFactory, "_GrowableList.")                                    \
  V(_GrowableListFilledFactory, "_GrowableList.filled")                        \
  V(_GrowableListGenerateFactory, "_GrowableList.generate")                    \
  V(_GrowableListLiteralFactory, "_GrowableList._literal")                     \
  V(_GrowableListWithData, "_GrowableList._withData")                          \
  V(_ImmutableList, "_ImmutableList")                                          \
  V(_Int16ArrayFactory, "Int16List.")                                          \
  V(_Int16ArrayView, "_Int16ArrayView")                                        \
  V(_Int16List, "_Int16List")                                                  \
  V(_Int32ArrayFactory, "Int32List.")                                          \
  V(_Int32ArrayView, "_Int32ArrayView")                                        \
  V(_Int32List, "_Int32List")                                                  \
  V(_Int32x4, "_Int32x4")                                                      \
  V(_Int32x4ArrayFactory, "Int32x4List.")                                      \
  V(_Int32x4ArrayView, "_Int32x4ArrayView")                                    \
  V(_Int32x4List, "_Int32x4List")                                              \
  V(_Int64ArrayFactory, "Int64List.")                                          \
  V(_Int64ArrayView, "_Int64ArrayView")                                        \
  V(_Int64List, "_Int64List")                                                  \
  V(_Int8ArrayFactory, "Int8List.")                                            \
  V(_Int8ArrayView, "_Int8ArrayView")                                          \
  V(_Int8List, "_Int8List")                                                    \
  V(_IntegerImplementation, "_IntegerImplementation")                          \
  V(_IsolateMirror, "_IsolateMirror")                                          \
  V(_LibraryDependencyMirror, "_LibraryDependencyMirror")                      \
  V(_LibraryMirror, "_LibraryMirror")                                          \
  V(_LibraryPrefix, "_LibraryPrefix")                                          \
  V(_List, "_List")                                                            \
  V(_ListFactory, "_List.")                                                    \
  V(_ListFilledFactory, "_List.filled")                                        \
  V(_ListGenerateFactory, "_List.generate")                                    \
  V(_Map, "_Map")                                                              \
  V(_MethodMirror, "_MethodMirror")                                            \
  V(_Mint, "_Mint")                                                            \
  V(_MirrorReference, "_MirrorReference")                                      \
  V(_NativeFinalizer, "_NativeFinalizer")                                      \
  V(_ParameterMirror, "_ParameterMirror")                                      \
  V(_Random, "_Random")                                                        \
  V(_RawReceivePort, "_RawReceivePort")                                        \
  V(_Record, "_Record")                                                        \
  V(_RecordType, "_RecordType")                                                \
  V(_RegExp, "_RegExp")                                                        \
  V(_SendPort, "_SendPort")                                                    \
  V(_Set, "_Set")                                                              \
  V(_Smi, "_Smi")                                                              \
  V(_SourceLocation, "_SourceLocation")                                        \
  V(_SpecialTypeMirror, "_SpecialTypeMirror")                                  \
  V(_StackTrace, "_StackTrace")                                                \
  V(_StreamController, "_StreamController")                                    \
  V(_StreamIterator, "_StreamIterator")                                        \
  V(_String, "String")                                                         \
  V(_SuspendState, "_SuspendState")                                            \
  V(_SyncStarIterator, "_SyncStarIterator")                                    \
  V(_SyncStreamController, "_SyncStreamController")                            \
  V(_TransferableTypedDataImpl, "_TransferableTypedDataImpl")                  \
  V(_Type, "_Type")                                                            \
  V(_TypeParameter, "_TypeParameter")                                          \
  V(_TypeVariableMirror, "_TypeVariableMirror")                                \
  V(_TypedListBase, "_TypedListBase")                                          \
  V(_Uint16ArrayFactory, "Uint16List.")                                        \
  V(_Uint16ArrayView, "_Uint16ArrayView")                                      \
  V(_Uint16List, "_Uint16List")                                                \
  V(_Uint32ArrayFactory, "Uint32List.")                                        \
  V(_Uint32ArrayView, "_Uint32ArrayView")                                      \
  V(_Uint32List, "_Uint32List")                                                \
  V(_Uint64ArrayFactory, "Uint64List.")                                        \
  V(_Uint64ArrayView, "_Uint64ArrayView")                                      \
  V(_Uint64List, "_Uint64List")                                                \
  V(_Uint8ArrayFactory, "Uint8List.")                                          \
  V(_Uint8ArrayView, "_Uint8ArrayView")                                        \
  V(_Uint8ClampedArrayFactory, "Uint8ClampedList.")                            \
  V(_Uint8ClampedArrayView, "_Uint8ClampedArrayView")                          \
  V(_Uint8ClampedList, "_Uint8ClampedList")                                    \
  V(_Uint8List, "_Uint8List")                                                  \
  V(_UnmodifiableByteDataView, "_UnmodifiableByteDataView")                    \
  V(_UnmodifiableFloat32ArrayView, "_UnmodifiableFloat32ArrayView")            \
  V(_UnmodifiableFloat32x4ArrayView, "_UnmodifiableFloat32x4ArrayView")        \
  V(_UnmodifiableFloat64ArrayView, "_UnmodifiableFloat64ArrayView")            \
  V(_UnmodifiableFloat64x2ArrayView, "_UnmodifiableFloat64x2ArrayView")        \
  V(_UnmodifiableInt16ArrayView, "_UnmodifiableInt16ArrayView")                \
  V(_UnmodifiableInt32ArrayView, "_UnmodifiableInt32ArrayView")                \
  V(_UnmodifiableInt32x4ArrayView, "_UnmodifiableInt32x4ArrayView")            \
  V(_UnmodifiableInt64ArrayView, "_UnmodifiableInt64ArrayView")                \
  V(_UnmodifiableInt8ArrayView, "_UnmodifiableInt8ArrayView")                  \
  V(_UnmodifiableUint16ArrayView, "_UnmodifiableUint16ArrayView")              \
  V(_UnmodifiableUint32ArrayView, "_UnmodifiableUint32ArrayView")              \
  V(_UnmodifiableUint64ArrayView, "_UnmodifiableUint64ArrayView")              \
  V(_UnmodifiableUint8ArrayView, "_UnmodifiableUint8ArrayView")                \
  V(_UnmodifiableUint8ClampedArrayView, "_UnmodifiableUint8ClampedArrayView")  \
  V(_UserTag, "_UserTag")                                                      \
  V(_Utf8Decoder, "_Utf8Decoder")                                              \
  V(_VariableMirror, "_VariableMirror")                                        \
  V(_WeakProperty, "_WeakProperty")                                            \
  V(_WeakReference, "_WeakReference")                                          \
  V(_await, "_await")                                                          \
  V(_awaitWithTypeCheck, "_awaitWithTypeCheck")                                \
  V(_backtrackingStack, "_backtrackingStack")                                  \
  V(_checkSetRangeArguments, "_checkSetRangeArguments")                        \
  V(_current, "_current")                                                      \
  V(_ensureScheduleImmediate, "_ensureScheduleImmediate")                      \
  V(future, "future")                                                          \
  V(_future, "_future")                                                        \
  V(_getRegisters, "_getRegisters")                                            \
  V(_growBacktrackingStack, "_growBacktrackingStack")                          \
  V(_handleException, "_handleException")                                      \
  V(_handleFinalizerMessage, "_handleFinalizerMessage")                        \
  V(_handleMessage, "_handleMessage")                                          \
  V(_handleNativeFinalizerMessage, "_handleNativeFinalizerMessage")            \
  V(_hasValue, "_hasValue")                                                    \
  V(_initAsync, "_initAsync")                                                  \
  V(_initAsyncStar, "_initAsyncStar")                                          \
  V(_initSyncStar, "_initSyncStar")                                            \
  V(_instanceOf, "_instanceOf")                                                \
  V(_listGetAt, "_listGetAt")                                                  \
  V(_listLength, "_listLength")                                                \
  V(_listSetAt, "_listSetAt")                                                  \
  V(_lookupHandler, "_lookupHandler")                                          \
  V(_lookupOpenPorts, "_lookupOpenPorts")                                      \
  V(_mapContainsKey, "_mapContainsKey")                                        \
  V(_mapGet, "_mapGet")                                                        \
  V(_mapKeys, "_mapKeys")                                                      \
  V(_name, "_name")                                                            \
  V(_nativeSetRange, "_nativeSetRange")                                        \
  V(_objectEquals, "_objectEquals")                                            \
  V(_objectHashCode, "_objectHashCode")                                        \
  V(_objectNoSuchMethod, "_objectNoSuchMethod")                                \
  V(_objectToString, "_objectToString")                                        \
  V(_onData, "_onData")                                                        \
  V(_rehashObjects, "_rehashObjects")                                          \
  V(_resultOrListeners, "_resultOrListeners")                                  \
  V(_returnAsync, "_returnAsync")                                              \
  V(_returnAsyncNotFuture, "_returnAsyncNotFuture")                            \
  V(_returnAsyncStar, "_returnAsyncStar")                                      \
  V(_runExtension, "_runExtension")                                            \
  V(_runPendingImmediateCallback, "_runPendingImmediateCallback")              \
  V(_scanFlags, "_scanFlags")                                                  \
  V(_simpleInstanceOf, "_simpleInstanceOf")                                    \
  V(_simpleInstanceOfFalse, "_simpleInstanceOfFalse")                          \
  V(_simpleInstanceOfTrue, "_simpleInstanceOfTrue")                            \
  V(_stackTrace, "_stackTrace")                                                \
  V(_state, "_state")                                                          \
  V(_stateData, "_stateData")                                                  \
  V(_suspendSyncStarAtStart, "_suspendSyncStarAtStart")                        \
  V(_toString, "_toString")                                                    \
  V(_typedDataBase, "_typedDataBase")                                          \
  V(_varData, "_varData")                                                      \
  V(_wordCharacterMap, "_wordCharacterMap")                                    \
  V(_yieldAsyncStar, "_yieldAsyncStar")                                        \
  V(_yieldStarIterable, "_yieldStarIterable")                                  \
  V(_yieldSyncStar, "_yieldSyncStar")                                          \
  V(absolute, "absolute")                                                      \
  V(add, "add")                                                                \
  V(addStream, "addStream")                                                    \
  V(asyncStarBody, "asyncStarBody")                                            \
  V(c_result, ":result")                                                       \
  V(call, "call")                                                              \
  V(callback, "callback")                                                      \
  V(capture_length, ":capture_length")                                         \
  V(capture_start_index, ":capture_start_index")                               \
  V(char_in_capture, ":char_in_capture")                                       \
  V(char_in_match, ":char_in_match")                                           \
  V(controller, "controller")                                                  \
  V(current_character, ":current_character")                                   \
  V(current_position, ":current_position")                                     \
  V(dynamic_assert_assignable_stc_check,                                       \
    ":dynamic_assert_assignable_stc_check")                                    \
  V(end, "end")                                                                \
  V(executable, "executable")                                                  \
  V(from, "from")                                                              \
  V(get, "get")                                                                \
  V(index_temp, ":index_temp")                                                 \
  V(isPaused, "isPaused")                                                      \
  V(match_end_index, ":match_end_index")                                       \
  V(match_start_index, ":match_start_index")                                   \
  V(name, "name")                                                              \
  V(native_assets, "native-assets")                                            \
  V(null, "null")                                                              \
  V(options, "options")                                                        \
  V(position_registers, ":position_registers")                                 \
  V(print, "print")                                                            \
  V(process, "process")                                                        \
  V(relative, "relative")                                                      \
  V(result, "result")                                                          \
  V(set, "set")                                                                \
  V(skip_count, "skipCount")                                                   \
  V(stack, ":stack")                                                           \
  V(stack_pointer, ":stack_pointer")                                           \
  V(start, "start")                                                            \
  V(start_index_param, ":start_index_param")                                   \
  V(state, "state")                                                            \
  V(string_param, ":string_param")                                             \
  V(string_param_length, ":string_param_length")                               \
  V(system, "system")                                                          \
  V(vm_always_consider_inlining, "vm:always-consider-inlining")                \
  V(vm_awaiter_link, "vm:awaiter-link")                                        \
  V(vm_entry_point, "vm:entry-point")                                          \
  V(vm_exact_result_type, "vm:exact-result-type")                              \
  V(vm_external_name, "vm:external-name")                                      \
  V(vm_ffi_abi_specific_mapping, "vm:ffi:abi-specific-mapping")                \
  V(vm_ffi_native_assets, "vm:ffi:native-assets")                              \
  V(vm_ffi_struct_fields, "vm:ffi:struct-fields")                              \
  V(vm_force_optimize, "vm:force-optimize")                                    \
  V(vm_idempotent, "vm:idempotent")                                            \
  V(vm_invisible, "vm:invisible")                                              \
  V(vm_isolate_unsendable, "vm:isolate-unsendable")                            \
  V(vm_cachable_idempotent, "vm:cachable-idempotent")                          \
  V(vm_never_inline, "vm:never-inline")                                        \
  V(vm_non_nullable_result_type, "vm:non-nullable-result-type")                \
  V(vm_notify_debugger_on_exception, "vm:notify-debugger-on-exception")        \
  V(vm_prefer_inline, "vm:prefer-inline")                                      \
  V(vm_recognized, "vm:recognized")                                            \
  V(vm_testing_print_flow_graph, "vm:testing:print-flow-graph")                \
  V(vm_trace_entrypoints, "vm:testing.unsafe.trace-entrypoints-fn")            \
  V(vm_unsafe_no_interrupts, "vm:unsafe:no-interrupts")

// Contains a list of frequently used strings in a canonicalized form. This
// list is kept in the vm_isolate in order to share the copy across isolates
// without having to maintain copies in each isolate.
class Symbols : public AllStatic {
 public:
  enum { kMaxOneCharCodeSymbol = 0xFF };

  // List of strings that are pre created in the vm isolate.
  enum SymbolId {
    // clang-format off
    kIllegal = 0,

#define DEFINE_SYMBOL_INDEX(symbol, literal) k##symbol##Id,
    PREDEFINED_SYMBOLS_LIST(DEFINE_SYMBOL_INDEX)
#undef DEFINE_SYMBOL_INDEX

    kTokenTableStart,  // First token at kTokenTableStart + 1.

#define DEFINE_TOKEN_SYMBOL_INDEX(t, s, p, a) t##Id,
    DART_TOKEN_LIST(DEFINE_TOKEN_SYMBOL_INDEX) DART_KEYWORD_LIST(
        DEFINE_TOKEN_SYMBOL_INDEX)
#undef DEFINE_TOKEN_SYMBOL_INDEX

    kNullCharId,  // One char code symbol starts here and takes up 256 entries.
    kMaxPredefinedId = kNullCharId + kMaxOneCharCodeSymbol + 1,
    // clang-format on
  };

  // Number of one character symbols being predefined in the predefined_ array.
  static constexpr int kNumberOfOneCharCodeSymbols =
      (kMaxPredefinedId - kNullCharId);

  // Offset of Null character which is the predefined character symbol.
  static constexpr int kNullCharCodeSymbolOffset = 0;

  static const String& Symbol(intptr_t index) {
    ASSERT((index > kIllegal) && (index < kMaxPredefinedId));
    return *(symbol_handles_[index]);
  }

  // Access methods for one byte character symbols stored in the vm isolate.
  static const String& Dot() { return *(symbol_handles_[kNullCharId + '.']); }
  static const String& Equals() {
    return *(symbol_handles_[kNullCharId + '=']);
  }
  static const String& Plus() { return *(symbol_handles_[kNullCharId + '+']); }
  static const String& Minus() { return *(symbol_handles_[kNullCharId + '-']); }
  static const String& BitOr() { return *(symbol_handles_[kNullCharId + '|']); }
  static const String& BitAnd() {
    return *(symbol_handles_[kNullCharId + '&']);
  }
  static const String& LAngleBracket() {
    return *(symbol_handles_[kNullCharId + '<']);
  }
  static const String& RAngleBracket() {
    return *(symbol_handles_[kNullCharId + '>']);
  }
  static const String& LParen() {
    return *(symbol_handles_[kNullCharId + '(']);
  }
  static const String& RParen() {
    return *(symbol_handles_[kNullCharId + ')']);
  }
  static const String& LBracket() {
    return *(symbol_handles_[kNullCharId + '[']);
  }
  static const String& RBracket() {
    return *(symbol_handles_[kNullCharId + ']']);
  }
  static const String& LBrace() {
    return *(symbol_handles_[kNullCharId + '{']);
  }
  static const String& RBrace() {
    return *(symbol_handles_[kNullCharId + '}']);
  }
  static const String& Blank() { return *(symbol_handles_[kNullCharId + ' ']); }
  static const String& Dollar() {
    return *(symbol_handles_[kNullCharId + '$']);
  }
  static const String& NewLine() {
    return *(symbol_handles_[kNullCharId + '\n']);
  }
  static const String& DoubleQuote() {
    return *(symbol_handles_[kNullCharId + '"']);
  }
  static const String& SingleQuote() {
    return *(symbol_handles_[kNullCharId + '\'']);
  }
  static const String& LowercaseR() {
    return *(symbol_handles_[kNullCharId + 'r']);
  }
  static const String& Dash() { return *(symbol_handles_[kNullCharId + '-']); }
  static const String& Ampersand() {
    return *(symbol_handles_[kNullCharId + '&']);
  }
  static const String& Backtick() {
    return *(symbol_handles_[kNullCharId + '`']);
  }
  static const String& Slash() { return *(symbol_handles_[kNullCharId + '/']); }
  static const String& At() { return *(symbol_handles_[kNullCharId + '@']); }
  static const String& HashMark() {
    return *(symbol_handles_[kNullCharId + '#']);
  }
  static const String& Semicolon() {
    return *(symbol_handles_[kNullCharId + ';']);
  }
  static const String& Star() { return *(symbol_handles_[kNullCharId + '*']); }
  static const String& Percent() {
    return *(symbol_handles_[kNullCharId + '%']);
  }
  static const String& QuestionMark() {
    return *(symbol_handles_[kNullCharId + '?']);
  }
  static const String& Caret() { return *(symbol_handles_[kNullCharId + '^']); }
  static const String& Tilde() { return *(symbol_handles_[kNullCharId + '~']); }

  static const String& Empty() { return *(symbol_handles_[kTokenTableStart]); }
  static const String& False() { return *(symbol_handles_[kFALSEId]); }
  static const String& Library() { return *(symbol_handles_[kLIBRARYId]); }
  static const String& Super() { return *(symbol_handles_[kSUPERId]); }
  static const String& This() { return *(symbol_handles_[kTHISId]); }
  static const String& True() { return *(symbol_handles_[kTRUEId]); }
  static const String& Void() { return *(symbol_handles_[kVOIDId]); }

// Access methods for symbol handles stored in the vm isolate for predefined
// symbols.
#define DEFINE_SYMBOL_HANDLE_ACCESSOR(symbol, literal)                         \
  static const String& symbol() { return *(symbol_handles_[k##symbol##Id]); }
  PREDEFINED_SYMBOLS_LIST(DEFINE_SYMBOL_HANDLE_ACCESSOR)
#undef DEFINE_SYMBOL_HANDLE_ACCESSOR

// Access methods for symbol handles stored in the vm isolate for keywords.
#define DEFINE_SYMBOL_HANDLE_ACCESSOR(t, s, p, a)                              \
  static const String& t() { return *(symbol_handles_[t##Id]); }
  DART_TOKEN_LIST(DEFINE_SYMBOL_HANDLE_ACCESSOR)
  DART_KEYWORD_LIST(DEFINE_SYMBOL_HANDLE_ACCESSOR)
#undef DEFINE_SYMBOL_HANDLE_ACCESSOR

  // Get symbol for scanner token.
  static const String& Token(Token::Kind token);

  // Initialize frequently used symbols in the vm isolate.
  static void Init(IsolateGroup* isolate_group);
  static void InitFromSnapshot(IsolateGroup* isolate_group);

  // Initialize and setup a symbol table for the isolate.
  static void SetupSymbolTable(IsolateGroup* isolate_group);

  // Creates a Symbol given a C string that is assumed to contain
  // UTF-8 encoded characters and '\0' is considered a termination character.
  // TODO(7123) - Rename this to FromCString(....).
  static StringPtr New(Thread* thread, const char* cstr) {
    return New(thread, cstr, strlen(cstr));
  }
  static StringPtr New(Thread* thread, const char* cstr, intptr_t length);

  // Creates a new Symbol from an array of UTF-8 encoded characters.
  static StringPtr FromUTF8(Thread* thread,
                            const uint8_t* utf8_array,
                            intptr_t len);

  // Creates a new Symbol from an array of Latin-1 encoded characters.
  static StringPtr FromLatin1(Thread* thread,
                              const uint8_t* latin1_array,
                              intptr_t len);

  // Creates a new Symbol from an array of UTF-16 encoded characters.
  static StringPtr FromUTF16(Thread* thread,
                             const uint16_t* utf16_array,
                             intptr_t len);

  static StringPtr New(Thread* thread, const String& str);
  static StringPtr New(Thread* thread,
                       const String& str,
                       intptr_t begin_index,
                       intptr_t length);

  static StringPtr NewFormatted(Thread* thread, const char* format, ...)
      PRINTF_ATTRIBUTE(2, 3);
  static StringPtr NewFormattedV(Thread* thread,
                                 const char* format,
                                 va_list args);

  static StringPtr FromConcat(Thread* thread,
                              const String& str1,
                              const String& str2);

  static StringPtr FromConcatAll(
      Thread* thread,
      const GrowableHandlePtrArray<const String>& strs);

  static StringPtr FromGet(Thread* thread, const String& str);
  static StringPtr FromSet(Thread* thread, const String& str);
  static StringPtr FromDot(Thread* thread, const String& str);

  // Returns char* of predefined symbol.
  static const char* Name(SymbolId symbol);

  static StringPtr FromCharCode(Thread* thread, uint16_t char_code);

  static StringPtr* PredefinedAddress() {
    return reinterpret_cast<StringPtr*>(&predefined_);
  }

  static void DumpStats(IsolateGroup* isolate_group);
  static void DumpTable(IsolateGroup* isolate_group);

  // Returns Symbol::Null if no symbol is found.
  template <typename StringType>
  static StringPtr Lookup(Thread* thread, const StringType& str);

  // Returns Symbol::Null if no symbol is found.
  static StringPtr LookupFromConcat(Thread* thread,
                                    const String& str1,
                                    const String& str2);

  static StringPtr LookupFromGet(Thread* thread, const String& str);
  static StringPtr LookupFromSet(Thread* thread, const String& str);
  static StringPtr LookupFromDot(Thread* thread, const String& str);

  static void GetStats(IsolateGroup* isolate_group,
                       intptr_t* size,
                       intptr_t* capacity);

 private:
  enum { kInitialVMIsolateSymtabSize = 1024, kInitialSymtabSize = 2048 };

  template <typename StringType>
  static StringPtr NewSymbol(Thread* thread, const StringType& str);

  // List of Latin1 characters stored in the vm isolate as symbols
  // in order to make Symbols::FromCharCode fast. This structure is
  // used in generated dart code for direct access to these objects.
  static StringPtr predefined_[kNumberOfOneCharCodeSymbols];

  // List of handles for predefined symbols.
  static String* symbol_handles_[kMaxPredefinedId];

  friend class Dart;
  friend class String;
  friend class Serializer;
  friend class Deserializer;

  DISALLOW_COPY_AND_ASSIGN(Symbols);
};

}  // namespace dart

#endif  // RUNTIME_VM_SYMBOLS_H_
