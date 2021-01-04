// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SYMBOLS_H_
#define RUNTIME_VM_SYMBOLS_H_

#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/snapshot_ids.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;

// One-character symbols are added implicitly.
#define PREDEFINED_SYMBOLS_LIST(V)                                             \
  V(AbstractClassInstantiationError, "AbstractClassInstantiationError")        \
  V(AllocateInvocationMirror, "_allocateInvocationMirror")                     \
  V(AllocateInvocationMirrorForClosure, "_allocateInvocationMirrorForClosure") \
  V(AnonymousClosure, "<anonymous closure>")                                   \
  V(AnonymousSignature, "<anonymous signature>")                               \
  V(ApiError, "ApiError")                                                      \
  V(ArgDescVar, ":arg_desc")                                                   \
  V(ArgumentError, "ArgumentError")                                            \
  V(AsFunctionInternal, "_asFunctionInternal")                                 \
  V(AssertionError, "_AssertionError")                                         \
  V(AssignIndexToken, "[]=")                                                   \
  V(AsyncFuture, ":async_future")                                              \
  V(AsyncOperation, ":async_op")                                               \
  V(AsyncStarMoveNextHelper, "_asyncStarMoveNextHelper")                       \
  V(AwaitContextVar, ":await_ctx_var")                                         \
  V(AwaitJumpVar, ":await_jump_var")                                           \
  V(Bool, "bool")                                                              \
  V(BooleanExpression, "boolean expression")                                   \
  V(BoundsCheckForPartialInstantiation, "_boundsCheckForPartialInstantiation") \
  V(ByteData, "ByteData")                                                      \
  V(ByteDataDot, "ByteData.")                                                  \
  V(ByteDataDot_view, "ByteData._view")                                        \
  V(Call, "call")                                                              \
  V(Cancel, "cancel")                                                          \
  V(CastError, "_CastError")                                                   \
  V(CheckLoaded, "_checkLoaded")                                               \
  V(Class, "Class")                                                            \
  V(ClassID, "ClassID")                                                        \
  V(ClosureData, "ClosureData")                                                \
  V(ClosureParameter, ":closure")                                              \
  V(Code, "Code")                                                              \
  V(CodeSourceMap, "CodeSourceMap")                                            \
  V(ColonMatcher, ":matcher")                                                  \
  V(CommaSpace, ", ")                                                          \
  V(Completer, "Completer")                                                    \
  V(CompleterFuture, "future")                                                 \
  V(CompleterGetFuture, "get:future")                                          \
  V(CompleterSyncConstructor, "Completer.sync")                                \
  V(CompressedStackMaps, "CompressedStackMaps")                                \
  V(ConstructorStacktracePrefix, "new ")                                       \
  V(Context, "Context")                                                        \
  V(ContextScope, "ContextScope")                                              \
  V(Controller, ":controller")                                                 \
  V(ControllerStream, ":controller_stream")                                    \
  V(Current, "current")                                                        \
  V(CurrentContextVar, ":current_context_var")                                 \
  V(CyclicInitializationError, "CyclicInitializationError")                    \
  V(DartAsync, "dart:async")                                                   \
  V(DartCollection, "dart:collection")                                         \
  V(DartCore, "dart:core")                                                     \
  V(DartDeveloper, "dart:developer")                                           \
  V(DartDeveloperTimeline, "dart.developer.timeline")                          \
  V(DartExtensionScheme, "dart-ext:")                                          \
  V(DartFfi, "dart:ffi")                                                       \
  V(DartFfiLibName, "ffi")                                                     \
  V(DartIOLibName, "dart.io")                                                  \
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
  V(DartVMServiceIO, "dart:vmservice_io")                                      \
  V(DebugClassName, "#DebugClass")                                             \
  V(DebugProcedureName, ":Eval")                                               \
  V(Default, "Default")                                                        \
  V(DefaultLabel, ":L")                                                        \
  V(DotCreate, "._create")                                                     \
  V(DotFieldNI, ".fieldNI")                                                    \
  V(DotFieldADI, ".fieldADI")                                                  \
  V(DotRange, ".range")                                                        \
  V(DotUnder, "._")                                                            \
  V(DotValue, ".value")                                                        \
  V(DotWithType, "._withType")                                                 \
  V(Double, "double")                                                          \
  V(Dynamic, "dynamic")                                                        \
  V(DynamicCall, "dyn:call")                                                   \
  V(DynamicCallCurrentNumProcessedVar, ":dyn_call_current_num_processed")      \
  V(DynamicCallCurrentFunctionVar, ":dyn_call_current_function")               \
  V(DynamicCallCurrentParamIndexVar, ":dyn_call_current_param_index")          \
  V(DynamicCallFunctionTypeArgsVar, ":dyn_call_function_type_args")            \
  V(DynamicPrefix, "dyn:")                                                     \
  V(EntryPointsTemp, ":entry_points_temp")                                     \
  V(EqualOperator, "==")                                                       \
  V(Error, "Error")                                                            \
  V(EvalSourceUri, "evaluate:source")                                          \
  V(EvaluateAssertion, "_evaluateAssertion")                                   \
  V(ExceptionHandlers, "ExceptionHandlers")                                    \
  V(ExceptionParameter, ":exception")                                          \
  V(ExceptionVar, ":exception_var")                                            \
  V(ExprTemp, ":expr_temp")                                                    \
  V(ExternalName, "ExternalName")                                              \
  V(ExternalOneByteString, "_ExternalOneByteString")                           \
  V(ExternalTwoByteString, "_ExternalTwoByteString")                           \
  V(FactoryResult, "factory result")                                           \
  V(FallThroughError, "FallThroughError")                                      \
  V(FfiCallback, "_FfiCallback")                                               \
  V(FfiDouble, "Double")                                                       \
  V(FfiDynamicLibrary, "DynamicLibrary")                                       \
  V(FfiFloat, "Float")                                                         \
  V(FfiInt16, "Int16")                                                         \
  V(FfiInt32, "Int32")                                                         \
  V(FfiInt64, "Int64")                                                         \
  V(FfiInt8, "Int8")                                                           \
  V(FfiIntPtr, "IntPtr")                                                       \
  V(FfiNativeFunction, "NativeFunction")                                       \
  V(FfiNativeType, "NativeType")                                               \
  V(FfiPointer, "Pointer")                                                     \
  V(FfiTrampolineData, "FfiTrampolineData")                                    \
  V(FfiUint16, "Uint16")                                                       \
  V(FfiUint32, "Uint32")                                                       \
  V(FfiUint64, "Uint64")                                                       \
  V(FfiUint8, "Uint8")                                                         \
  V(FfiVoid, "Void")                                                           \
  V(FfiHandle, "Handle")                                                       \
  V(Field, "Field")                                                            \
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
  V(FutureCatchError, "catchError")                                            \
  V(FutureImpl, "_Future")                                                     \
  V(FutureMicrotask, "Future.microtask")                                       \
  V(FutureOr, "FutureOr")                                                      \
  V(FutureThen, "then")                                                        \
  V(FutureValue, "Future.value")                                               \
  V(Get, "get")                                                                \
  V(GetCall, "get:call")                                                       \
  V(GetLength, "get:length")                                                   \
  V(GetRuntimeType, "get:runtimeType")                                         \
  V(GetterPrefix, "get:")                                                      \
  V(GreaterEqualOperator, ">=")                                                \
  V(GrowRegExpStack, "_growRegExpStack")                                       \
  V(HandleExposedException, "_handleExposedException")                         \
  V(HaveSameRuntimeType, "_haveSameRuntimeType")                               \
  V(ICData, "ICData")                                                          \
  V(Identical, "identical")                                                    \
  V(ImmutableMap, "_ImmutableMap")                                             \
  V(ImmutableMapConstructor, "_ImmutableMap._create")                          \
  V(InTypeCast, " in type cast")                                               \
  V(Index, "index")                                                            \
  V(IndexToken, "[]")                                                          \
  V(InitPrefix, "init:")                                                       \
  V(Instructions, "Instructions")                                              \
  V(InstructionsSection, "InstructionsSection")                                \
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
  V(Iterator, "iterator")                                                      \
  V(IteratorParameter, ":iterator")                                            \
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
  V(ListLiteralFactory, "List._fromLiteral")                                   \
  V(LoadLibrary, "_loadLibrary")                                               \
  V(LocalVarDescriptors, "LocalVarDescriptors")                                \
  V(Map, "Map")                                                                \
  V(MapLiteralFactory, "Map._fromLiteral")                                     \
  V(MegamorphicCache, "MegamorphicCache")                                      \
  V(MonomorphicSmiableCall, "MonomorphicSmiableCall")                          \
  V(MoveNext, "moveNext")                                                      \
  V(Namespace, "Namespace")                                                    \
  V(Native, "native")                                                          \
  V(Never, "Never")                                                            \
  V(NoSuchMethod, "noSuchMethod")                                              \
  V(NoSuchMethodError, "NoSuchMethodError")                                    \
  V(NotInitialized, "<not initialized>")                                       \
  V(NotNamed, "<not named>")                                                   \
  V(Null, "Null")                                                              \
  V(NullThrownError, "NullThrownError")                                        \
  V(Number, "num")                                                             \
  V(Object, "Object")                                                          \
  V(ObjectPool, "ObjectPool")                                                  \
  V(OneByteString, "_OneByteString")                                           \
  V(OptimizedOut, "<optimized out>")                                           \
  V(OriginalParam, ":original:")                                               \
  V(Other, "other")                                                            \
  V(OutOfMemoryError, "OutOfMemoryError")                                      \
  V(PackageScheme, "package:")                                                 \
  V(Patch, "patch")                                                            \
  V(PatchClass, "PatchClass")                                                  \
  V(PcDescriptors, "PcDescriptors")                                            \
  V(Pragma, "pragma")                                                          \
  V(PrependTypeArguments, "_prependTypeArguments")                             \
  V(QuoteIsNotASubtypeOf, "' is not a subtype of ")                            \
  V(RParenArrow, ") => ")                                                      \
  V(RangeError, "RangeError")                                                  \
  V(RegExp, "RegExp")                                                          \
  V(RightShiftOperator, ">>")                                                  \
  V(SavedTryContextVar, ":saved_try_context_var")                              \
  V(Script, "Script")                                                          \
  V(SecondArg, "y")                                                            \
  V(Set, "set")                                                                \
  V(SetterPrefix, "set:")                                                      \
  V(SignatureData, "SignatureData")                                            \
  V(SingleTargetCache, "SingleTargetCache")                                    \
  V(SizeOfStructField, "#sizeOf")                                              \
  V(SpaceExtendsSpace, " extends ")                                            \
  V(SpaceIsFromSpace, " is from ")                                             \
  V(SpaceOfSpace, " of ")                                                      \
  V(SpaceWhereNewLine, " where\n")                                             \
  V(StackOverflowError, "StackOverflowError")                                  \
  V(StackTraceParameter, ":stack_trace")                                       \
  V(Stream, "stream")                                                          \
  V(StreamController, "StreamController")                                      \
  V(StreamIterator, "StreamIterator")                                          \
  V(StreamIteratorConstructor, "StreamIterator.")                              \
  V(StringBase, "_StringBase")                                                 \
  V(Struct, "Struct")                                                          \
  V(StructFromTypedDataBase, "#fromTypedDataBase")                             \
  V(SubtypeTestCache, "SubtypeTestCache")                                      \
  V(LoadingUnit, "LoadingUnit")                                                \
  V(SwitchExpr, ":switch_expr")                                                \
  V(Symbol, "Symbol")                                                          \
  V(SymbolCtor, "Symbol.")                                                     \
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
  V(TypeQuote, "type '")                                                       \
  V(Uint16List, "Uint16List")                                                  \
  V(Uint32List, "Uint32List")                                                  \
  V(Uint64List, "Uint64List")                                                  \
  V(Uint8ClampedList, "Uint8ClampedList")                                      \
  V(Uint8List, "Uint8List")                                                    \
  V(UnaryMinus, "unary-")                                                      \
  V(UnhandledException, "UnhandledException")                                  \
  V(UnlinkedCall, "UnlinkedCall")                                              \
  V(UnsafeCast, "unsafeCast")                                                  \
  V(UnsupportedError, "UnsupportedError")                                      \
  V(UnwindError, "UnwindError")                                                \
  V(Value, "value")                                                            \
  V(Values, "values")                                                          \
  V(YieldKw, "yield")                                                          \
  V(_AsyncAwaitStart, "start")                                                 \
  V(_AsyncStarStreamController, "_AsyncStarStreamController")                  \
  V(_AsyncStarStreamControllerConstructor, "_AsyncStarStreamController.")      \
  V(_AsyncStreamController, "_AsyncStreamController")                          \
  V(_Awaiter, "_awaiter")                                                      \
  V(_BufferingStreamSubscription, "_BufferingStreamSubscription")              \
  V(_ByteBuffer, "_ByteBuffer")                                                \
  V(_ByteBufferDot_New, "_ByteBuffer._New")                                    \
  V(_ByteDataView, "_ByteDataView")                                            \
  V(_CapabilityImpl, "_CapabilityImpl")                                        \
  V(_ClassMirror, "_ClassMirror")                                              \
  V(_Closure, "_Closure")                                                      \
  V(_ClosureCall, "_Closure.call")                                             \
  V(_CombinatorMirror, "_CombinatorMirror")                                    \
  V(_CompileTimeError, "_CompileTimeError")                                    \
  V(_CompleteOnAsyncReturn, "_completeOnAsyncReturn")                          \
  V(_ControllerSubscription, "_ControllerSubscription")                        \
  V(_CompleteOnAsyncError, "_completeOnAsyncError")                            \
  V(_DeletedEnumPrefix, "Deleted enum value from ")                            \
  V(_DeletedEnumSentinel, "_deleted_enum_sentinel")                            \
  V(_Double, "_Double")                                                        \
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
  V(_FunctionTypeMirror, "_FunctionTypeMirror")                                \
  V(_FutureListener, "_FutureListener")                                        \
  V(_GrowableList, "_GrowableList")                                            \
  V(_GrowableListFactory, "_GrowableList.")                                    \
  V(_GrowableListFilledFactory, "_GrowableList.filled")                        \
  V(_GrowableListGenerateFactory, "_GrowableList.generate")                    \
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
  V(_LinkedHashMap, "_InternalLinkedHashMap")                                  \
  V(_LinkedHashSet, "_CompactLinkedHashSet")                                   \
  V(_List, "_List")                                                            \
  V(_ListFactory, "_List.")                                                    \
  V(_ListFilledFactory, "_List.filled")                                        \
  V(_ListGenerateFactory, "_List.generate")                                    \
  V(_MethodMirror, "_MethodMirror")                                            \
  V(_Mint, "_Mint")                                                            \
  V(_MirrorReference, "_MirrorReference")                                      \
  V(_MirrorSystem, "_MirrorSystem")                                            \
  V(_ParameterMirror, "_ParameterMirror")                                      \
  V(_Random, "_Random")                                                        \
  V(_RawReceivePortImpl, "_RawReceivePortImpl")                                \
  V(_RegExp, "_RegExp")                                                        \
  V(_SendPortImpl, "_SendPortImpl")                                            \
  V(_Smi, "_Smi")                                                              \
  V(_SourceLocation, "_SourceLocation")                                        \
  V(_SpecialTypeMirror, "_SpecialTypeMirror")                                  \
  V(_StackTrace, "_StackTrace")                                                \
  V(_StreamController, "_StreamController")                                    \
  V(_StreamImpl, "_StreamImpl")                                                \
  V(_StreamIterator, "_StreamIterator")                                        \
  V(_String, "String")                                                         \
  V(_SyncIterable, "_SyncIterable")                                            \
  V(_SyncIterableConstructor, "_SyncIterable.")                                \
  V(_SyncIterator, "_SyncIterator")                                            \
  V(_TransferableTypedDataImpl, "_TransferableTypedDataImpl")                  \
  V(_Type, "_Type")                                                            \
  V(_TypeParameter, "_TypeParameter")                                          \
  V(_TypeRef, "_TypeRef")                                                      \
  V(_TypeVariableMirror, "_TypeVariableMirror")                                \
  V(_TypedefMirror, "_TypedefMirror")                                          \
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
  V(_UserTag, "_UserTag")                                                      \
  V(_Utf8Decoder, "_Utf8Decoder")                                              \
  V(_VariableMirror, "_VariableMirror")                                        \
  V(_WeakProperty, "_WeakProperty")                                            \
  V(_addressOf, "_addressOf")                                                  \
  V(_classRangeCheck, "_classRangeCheck")                                      \
  V(_current, "_current")                                                      \
  V(_ensureScheduleImmediate, "_ensureScheduleImmediate")                      \
  V(_future, "_future")                                                        \
  V(_get, "_get")                                                              \
  V(_handleMessage, "_handleMessage")                                          \
  V(_instanceOf, "_instanceOf")                                                \
  V(_lookupHandler, "_lookupHandler")                                          \
  V(_lookupOpenPorts, "_lookupOpenPorts")                                      \
  V(_name, "_name")                                                            \
  V(_onData, "_onData")                                                        \
  V(_rehashObjects, "_rehashObjects")                                          \
  V(_resultOrListeners, "_resultOrListeners")                                  \
  V(_runExtension, "_runExtension")                                            \
  V(_runPendingImmediateCallback, "_runPendingImmediateCallback")              \
  V(_scanFlags, "_scanFlags")                                                  \
  V(_setLength, "_setLength")                                                  \
  V(_simpleInstanceOf, "_simpleInstanceOf")                                    \
  V(_simpleInstanceOfFalse, "_simpleInstanceOfFalse")                          \
  V(_simpleInstanceOfTrue, "_simpleInstanceOfTrue")                            \
  V(_stackTrace, "_stackTrace")                                                \
  V(_state, "_state")                                                          \
  V(_stateData, "_stateData")                                                  \
  V(_varData, "_varData")                                                      \
  V(_wordCharacterMap, "_wordCharacterMap")                                    \
  V(add, "add")                                                                \
  V(callback, "callback")                                                      \
  V(capture_length, ":capture_length")                                         \
  V(capture_start_index, ":capture_start_index")                               \
  V(char_in_capture, ":char_in_capture")                                       \
  V(char_in_match, ":char_in_match")                                           \
  V(clear, "clear")                                                            \
  V(controller, "controller")                                                  \
  V(current_character, ":current_character")                                   \
  V(current_position, ":current_position")                                     \
  V(dynamic_assert_assignable_stc_check,                                       \
    ":dynamic_assert_assignable_stc_check")                                    \
  V(getID, "getID")                                                            \
  V(hashCode, "get:hashCode")                                                  \
  V(identityHashCode, "identityHashCode")                                      \
  V(index_temp, ":index_temp")                                                 \
  V(is_sync, ":is_sync")                                                       \
  V(isPaused, "isPaused")                                                      \
  V(isSync, "isSync")                                                          \
  V(last, "last")                                                              \
  V(match_end_index, ":match_end_index")                                       \
  V(match_start_index, ":match_start_index")                                   \
  V(name, "name")                                                              \
  V(null, "null")                                                              \
  V(options, "options")                                                        \
  V(position_registers, ":position_registers")                                 \
  V(print, "print")                                                            \
  V(removeLast, "removeLast")                                                  \
  V(c_result, ":result")                                                       \
  V(result, "result")                                                          \
  V(stack, ":stack")                                                           \
  V(stack_pointer, ":stack_pointer")                                           \
  V(start_index_param, ":start_index_param")                                   \
  V(state, "state")                                                            \
  V(string_param, ":string_param")                                             \
  V(string_param_length, ":string_param_length")                               \
  V(toString, "toString")                                                      \
  V(vm_prefer_inline, "vm:prefer-inline")                                      \
  V(vm_entry_point, "vm:entry-point")                                          \
  V(vm_exact_result_type, "vm:exact-result-type")                              \
  V(vm_inferred_type_metadata, "vm.inferred-type.metadata")                    \
  V(vm_never_inline, "vm:never-inline")                                        \
  V(vm_non_nullable_result_type, "vm:non-nullable-result-type")                \
  V(vm_recognized, "vm:recognized")                                            \
  V(vm_trace_entrypoints, "vm:testing.unsafe.trace-entrypoints-fn")            \
  V(vm_procedure_attributes_metadata, "vm.procedure-attributes.metadata")      \
  V(vm_ffi_struct_fields, "vm:ffi:struct-fields")

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
  static const int kNumberOfOneCharCodeSymbols =
      (kMaxPredefinedId - kNullCharId);

  // Offset of Null character which is the predefined character symbol.
  static const int kNullCharCodeSymbolOffset = 0;

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
  static void Init(Isolate* isolate);
  static void InitFromSnapshot(Isolate* isolate);

  // Initialize and setup a symbol table for the isolate.
  static void SetupSymbolTable(Isolate* isolate);

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

  static void DumpStats(Isolate* isolate);
  static void DumpTable(Isolate* isolate);

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

  static void GetStats(Isolate* isolate, intptr_t* size, intptr_t* capacity);

 private:
  enum { kInitialVMIsolateSymtabSize = 1024, kInitialSymtabSize = 2048 };

  template <typename StringType>
  static StringPtr NewSymbol(Thread* thread, const StringType& str);

  static intptr_t LookupPredefinedSymbol(ObjectPtr obj);
  static ObjectPtr GetPredefinedSymbol(intptr_t object_id);
  static bool IsPredefinedSymbolId(intptr_t object_id) {
    return (object_id >= kMaxPredefinedObjectIds &&
            object_id < (kMaxPredefinedObjectIds + kMaxPredefinedId));
  }

  // List of Latin1 characters stored in the vm isolate as symbols
  // in order to make Symbols::FromCharCode fast. This structure is
  // used in generated dart code for direct access to these objects.
  static StringPtr predefined_[kNumberOfOneCharCodeSymbols];

  // List of handles for predefined symbols.
  static String* symbol_handles_[kMaxPredefinedId];

  friend class Dart;
  friend class String;
  friend class SnapshotReader;
  friend class SnapshotWriter;
  friend class Serializer;
  friend class Deserializer;
  friend class ApiMessageReader;

  DISALLOW_COPY_AND_ASSIGN(Symbols);
};

}  // namespace dart

#endif  // RUNTIME_VM_SYMBOLS_H_
