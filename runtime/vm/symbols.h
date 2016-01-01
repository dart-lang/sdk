// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SYMBOLS_H_
#define VM_SYMBOLS_H_

#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/snapshot_ids.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;

// One-character symbols are added implicitly.
#define PREDEFINED_SYMBOLS_LIST(V)                                             \
  V(EqualOperator, "==")                                                       \
  V(GreaterEqualOperator, ">=")                                                \
  V(LessEqualOperator, "<=")                                                   \
  V(LeftShiftOperator, "<<")                                                   \
  V(RightShiftOperator, ">>")                                                  \
  V(TruncDivOperator, "~/")                                                    \
  V(UnaryMinus, "unary-")                                                      \
  V(Identical, "identical")                                                    \
  V(Length, "length")                                                          \
  V(_setLength, "_setLength")                                                  \
  V(IndexToken, "[]")                                                          \
  V(AssignIndexToken, "[]=")                                                   \
  V(TopLevel, "::")                                                            \
  V(DefaultLabel, ":L")                                                        \
  V(Other, "other")                                                            \
  V(Call, "call")                                                              \
  V(Current, "current")                                                        \
  V(MoveNext, "moveNext")                                                      \
  V(IsYieldEach, "isYieldEach")                                                \
  V(Value, "value")                                                            \
  V(_EnumHelper, "_EnumHelper")                                                \
  V(_SyncIterable, "_SyncIterable")                                            \
  V(_SyncIterableConstructor, "_SyncIterable.")                                \
  V(_SyncIterator, "_SyncIterator")                                            \
  V(IteratorParameter, ":iterator")                                            \
  V(_AsyncStarStreamController, "_AsyncStarStreamController")                  \
  V(_AsyncStarStreamControllerConstructor, "_AsyncStarStreamController.")      \
  V(Controller, ":controller")                                                 \
  V(Stream, "stream")                                                          \
  V(isPaused, "isPaused")                                                      \
  V(AddError, "addError")                                                      \
  V(AddStream, "addStream")                                                    \
  V(Cancel, "cancel")                                                          \
  V(Close, "close")                                                            \
  V(Values, "values")                                                          \
  V(_EnumNames, "_enum_names")                                                 \
  V(ExprTemp, ":expr_temp")                                                    \
  V(AnonymousClosure, "<anonymous closure>")                                   \
  V(ImplicitClosure, "<implicit closure>")                                     \
  V(ClosureParameter, ":closure")                                              \
  V(PhaseParameter, ":phase")                                                  \
  V(TypeArgumentsParameter, ":type_arguments")                                 \
  V(AssertionError, "_AssertionError")                                         \
  V(CastError, "_CastError")                                                   \
  V(TypeError, "_TypeError")                                                   \
  V(FallThroughError, "FallThroughError")                                      \
  V(AbstractClassInstantiationError, "AbstractClassInstantiationError")        \
  V(NoSuchMethodError, "NoSuchMethodError")                                    \
  V(CyclicInitializationError, "CyclicInitializationError")                    \
  V(ThrowNew, "_throwNew")                                                     \
  V(ThrowNewIfNotLoaded, "_throwNewIfNotLoaded")                               \
  V(Symbol, "Symbol")                                                          \
  V(SymbolCtor, "Symbol.")                                                     \
  V(List, "List")                                                              \
  V(ListLiteralFactory, "List._fromLiteral")                                   \
  V(ListFactory, "List.")                                                      \
  V(Map, "Map")                                                                \
  V(MapLiteralFactory, "Map._fromLiteral")                                     \
  V(ImmutableMap, "ImmutableMap")                                              \
  V(ImmutableMapConstructor, "ImmutableMap._create")                           \
  V(StringBase, "_StringBase")                                                 \
  V(Interpolate, "_interpolate")                                               \
  V(InterpolateSingle, "_interpolateSingle")                                   \
  V(Iterator, "iterator")                                                      \
  V(NoSuchMethod, "noSuchMethod")                                              \
  V(CurrentContextVar, ":current_context_var")                                 \
  V(SavedTryContextVar, ":saved_try_context_var")                              \
  V(ExceptionParameter, ":exception")                                          \
  V(StackTraceParameter, ":stack_trace")                                       \
  V(ExceptionVar, ":exception_var")                                            \
  V(StackTraceVar, ":stack_trace_var")                                         \
  V(SavedExceptionVar, ":saved_exception_var")                                 \
  V(SavedStackTraceVar, ":saved_stack_trace_var")                              \
  V(ListLiteralElement, "list literal element")                                \
  V(ForInIter, ":for-in-iter")                                                 \
  V(LoadLibrary, "loadLibrary")                                                \
  V(_LibraryPrefix, "_LibraryPrefix")                                          \
  V(On, "on")                                                                  \
  V(Of, "of")                                                                  \
  V(Deferred, "deferred")                                                      \
  V(Show, "show")                                                              \
  V(Hide, "hide")                                                              \
  V(Async, "async")                                                            \
  V(Sync, "sync")                                                              \
  V(YieldKw, "yield")                                                          \
  V(AsyncCompleter, ":async_completer")                                        \
  V(AsyncOperation, ":async_op")                                               \
  V(AsyncThenCallback, ":async_op_then")                                       \
  V(AsyncCatchErrorCallback, ":async_op_catch_error")                          \
  V(AsyncOperationParam, ":async_result")                                      \
  V(AsyncOperationErrorParam, ":async_error_param")                            \
  V(AsyncOperationStackTraceParam, ":async_stack_trace_param")                 \
  V(AsyncSavedTryCtxVarPrefix, ":async_saved_try_ctx_var_")                    \
  V(AsyncCatchHelper, "_asyncCatchHelper")                                     \
  V(AsyncThenWrapperHelper, "_asyncThenWrapperHelper")                         \
  V(AsyncErrorWrapperHelper, "_asyncErrorWrapperHelper")                       \
  V(AsyncAwaitHelper, "_awaitHelper")                                          \
  V(Await, "await")                                                            \
  V(AwaitTempVarPrefix, ":await_temp_var_")                                    \
  V(AwaitContextVar, ":await_ctx_var")                                         \
  V(AwaitJumpVar, ":await_jump_var")                                           \
  V(Future, "Future")                                                          \
  V(FutureMicrotask, "Future.microtask")                                       \
  V(FutureValue, "Future.value")                                               \
  V(FutureThen, "then")                                                        \
  V(FutureCatchError, "catchError")                                            \
  V(Completer, "Completer")                                                    \
  V(CompleterComplete, "complete")                                             \
  V(CompleterCompleteError, "completeError")                                   \
  V(CompleterSyncConstructor, "Completer.sync")                                \
  V(CompleterFuture, "future")                                                 \
  V(StreamIterator, "StreamIterator")                                          \
  V(StreamIteratorConstructor, "StreamIterator.")                              \
  V(Native, "native")                                                          \
  V(Class, "Class")                                                            \
  V(Null, "Null")                                                              \
  V(Dynamic, "dynamic")                                                        \
  V(UnresolvedClass, "UnresolvedClass")                                        \
  V(Type, "_Type")                                                             \
  V(TypeRef, "_TypeRef")                                                       \
  V(TypeParameter, "_TypeParameter")                                           \
  V(BoundedType, "_BoundedType")                                               \
  V(MixinAppType, "_MixinAppType")                                             \
  V(TypeArguments, "TypeArguments")                                            \
  V(Patch, "patch")                                                            \
  V(PatchClass, "PatchClass")                                                  \
  V(Function, "Function")                                                      \
  V(FunctionImpl, "_FunctionImpl")                                             \
  V(FunctionResult, "function result")                                         \
  V(FactoryResult, "factory result")                                           \
  V(ClosureData, "ClosureData")                                                \
  V(RedirectionData, "RedirectionData")                                        \
  V(Field, "Field")                                                            \
  V(LiteralToken, "LiteralToken")                                              \
  V(TokenStream, "TokenStream")                                                \
  V(Script, "Script")                                                          \
  V(LibraryClass, "Library")                                                   \
  V(LibraryPrefix, "LibraryPrefix")                                            \
  V(Namespace, "Namespace")                                                    \
  V(Code, "Code")                                                              \
  V(Instructions, "Instructions")                                              \
  V(ObjectPool, "ObjectPool")                                                  \
  V(PcDescriptors, "PcDescriptors")                                            \
  V(Stackmap, "Stackmap")                                                      \
  V(LocalVarDescriptors, "LocalVarDescriptors")                                \
  V(ExceptionHandlers, "ExceptionHandlers")                                    \
  V(DeoptInfo, "DeoptInfo")                                                    \
  V(Context, "Context")                                                        \
  V(ContextScope, "ContextScope")                                              \
  V(ICData, "ICData")                                                          \
  V(MegamorphicCache, "MegamorphicCache")                                      \
  V(SubtypeTestCache, "SubtypeTestCache")                                      \
  V(Error, "Error")                                                            \
  V(ApiError, "ApiError")                                                      \
  V(LanguageError, "LanguageError")                                            \
  V(UnhandledException, "UnhandledException")                                  \
  V(UnwindError, "UnwindError")                                                \
  V(IntegerImplementation, "_IntegerImplementation")                           \
  V(Number, "num")                                                             \
  V(_Smi, "_Smi")                                                              \
  V(_Mint, "_Mint")                                                            \
  V(_Bigint, "_Bigint")                                                        \
  V(_Double, "_Double")                                                        \
  V(Bool, "bool")                                                              \
  V(_List, "_List")                                                            \
  V(_ListFactory, "_List.")                                                    \
  V(_GrowableList, "_GrowableList")                                            \
  V(_GrowableListFactory, "_GrowableList.")                                    \
  V(_GrowableListWithData, "_GrowableList.withData")                           \
  V(_ImmutableList, "_ImmutableList")                                          \
  V(_LinkedHashMap, "_InternalLinkedHashMap")                                  \
  V(_String, "String")                                                         \
  V(OneByteString, "_OneByteString")                                           \
  V(TwoByteString, "_TwoByteString")                                           \
  V(ExternalOneByteString, "_ExternalOneByteString")                           \
  V(ExternalTwoByteString, "_ExternalTwoByteString")                           \
  V(_CapabilityImpl, "_CapabilityImpl")                                        \
  V(_RawReceivePortImpl, "_RawReceivePortImpl")                                \
  V(_SendPortImpl, "_SendPortImpl")                                            \
  V(_StackTrace, "_StackTrace")                                                \
  V(JSSyntaxRegExp, "_JSSyntaxRegExp")                                         \
  V(RegExp, "RegExp")                                                          \
  V(Irregexp, ":irregexp")                                                     \
  V(Object, "Object")                                                          \
  V(Int, "int")                                                                \
  V(Double, "double")                                                          \
  V(_Float32x4, "_Float32x4")                                                  \
  V(_Float64x2, "_Float64x2")                                                  \
  V(_Int32x4, "_Int32x4")                                                      \
  V(Float32x4, "Float32x4")                                                    \
  V(Float64x2, "Float64x2")                                                    \
  V(Int32x4, "Int32x4")                                                        \
  V(Int8List, "Int8List")                                                      \
  V(Uint8List, "Uint8List")                                                    \
  V(Uint8ClampedList, "Uint8ClampedList")                                      \
  V(Int16List, "Int16List")                                                    \
  V(Uint16List, "Uint16List")                                                  \
  V(Int32List, "Int32List")                                                    \
  V(Uint32List, "Uint32List")                                                  \
  V(Int64List, "Int64List")                                                    \
  V(Uint64List, "Uint64List")                                                  \
  V(Float32x4List, "Float32x4List")                                            \
  V(Int32x4List, "Int32x4List")                                                \
  V(Float64x2List, "Float64x2List")                                            \
  V(Float32List, "Float32List")                                                \
  V(Float64List, "Float64List")                                                \
  V(_Int8Array, "_Int8Array")                                                  \
  V(_Int8ArrayFactory, "_Int8Array.")                                          \
  V(_Uint8Array, "_Uint8Array")                                                \
  V(_Uint8ArrayFactory, "_Uint8Array.")                                        \
  V(_Uint8ClampedArray, "_Uint8ClampedArray")                                  \
  V(_Uint8ClampedArrayFactory, "_Uint8ClampedArray.")                          \
  V(_Int16Array, "_Int16Array")                                                \
  V(_Int16ArrayFactory, "_Int16Array.")                                        \
  V(_Uint16Array, "_Uint16Array")                                              \
  V(_Uint16ArrayFactory, "_Uint16Array.")                                      \
  V(_Int32Array, "_Int32Array")                                                \
  V(_Int32ArrayFactory, "_Int32Array.")                                        \
  V(_Uint32Array, "_Uint32Array")                                              \
  V(_Uint32ArrayFactory, "_Uint32Array.")                                      \
  V(_Int64Array, "_Int64Array")                                                \
  V(_Int64ArrayFactory, "_Int64Array.")                                        \
  V(_Uint64Array, "_Uint64Array")                                              \
  V(_Uint64ArrayFactory, "_Uint64Array.")                                      \
  V(_Float32x4Array, "_Float32x4Array")                                        \
  V(_Float32x4ArrayFactory, "_Float32x4Array.")                                \
  V(_Int32x4Array, "_Int32x4Array")                                            \
  V(_Int32x4ArrayFactory, "_Int32x4Array.")                                    \
  V(_Float64x2Array, "_Float64x2Array")                                        \
  V(_Float64x2ArrayFactory, "_Float64x2Array.")                                \
  V(_Float32Array, "_Float32Array")                                            \
  V(_Float32ArrayFactory, "_Float32Array.")                                    \
  V(_Float64Array, "_Float64Array")                                            \
  V(_Float64ArrayFactory, "_Float64Array.")                                    \
  V(_Int8ArrayView, "_Int8ArrayView")                                          \
  V(_Uint8ArrayView, "_Uint8ArrayView")                                        \
  V(_Uint8ClampedArrayView, "_Uint8ClampedArrayView")                          \
  V(_Int16ArrayView, "_Int16ArrayView")                                        \
  V(_Uint16ArrayView, "_Uint16ArrayView")                                      \
  V(_Int32ArrayView, "_Int32ArrayView")                                        \
  V(_Uint32ArrayView, "_Uint32ArrayView")                                      \
  V(_Int64ArrayView, "_Int64ArrayView")                                        \
  V(_Uint64ArrayView, "_Uint64ArrayView")                                      \
  V(_Float32ArrayView, "_Float32ArrayView")                                    \
  V(_Float64ArrayView, "_Float64ArrayView")                                    \
  V(_Float32x4ArrayView, "_Float32x4ArrayView")                                \
  V(_Int32x4ArrayView, "_Int32x4ArrayView")                                    \
  V(_Float64x2ArrayView, "_Float64x2ArrayView")                                \
  V(_ExternalInt8Array, "_ExternalInt8Array")                                  \
  V(_ExternalUint8Array, "_ExternalUint8Array")                                \
  V(_ExternalUint8ClampedArray, "_ExternalUint8ClampedArray")                  \
  V(_ExternalInt16Array, "_ExternalInt16Array")                                \
  V(_ExternalUint16Array, "_ExternalUint16Array")                              \
  V(_ExternalInt32Array, "_ExternalInt32Array")                                \
  V(_ExternalUint32Array, "_ExternalUint32Array")                              \
  V(_ExternalInt64Array, "_ExternalInt64Array")                                \
  V(_ExternalUint64Array, "_ExternalUint64Array")                              \
  V(_ExternalFloat32x4Array, "_ExternalFloat32x4Array")                        \
  V(_ExternalInt32x4Array, "_ExternalInt32x4Array")                            \
  V(_ExternalFloat32Array, "_ExternalFloat32Array")                            \
  V(_ExternalFloat64Array, "_ExternalFloat64Array")                            \
  V(_ExternalFloat64x2Array, "_ExternalFloat64x2Array")                        \
  V(ByteData, "ByteData")                                                      \
  V(ByteDataDot, "ByteData.")                                                  \
  V(ByteDataDot_view, "ByteData._view")                                        \
  V(_ByteDataView, "_ByteDataView")                                            \
  V(_ByteBuffer, "_ByteBuffer")                                                \
  V(_ByteBufferDot_New, "_ByteBuffer._New")                                    \
  V(_WeakProperty, "_WeakProperty")                                            \
  V(_MirrorReference, "_MirrorReference")                                      \
  V(InvocationMirror, "_InvocationMirror")                                     \
  V(AllocateInvocationMirror, "_allocateInvocationMirror")                     \
  V(toString, "toString")                                                      \
  V(_lookupHandler, "_lookupHandler")                                          \
  V(_handleMessage, "_handleMessage")                                          \
  V(DotCreate, "._create")                                                     \
  V(DotWithType, "._withType")                                                 \
  V(_get, "_get")                                                              \
  V(RangeError, "RangeError")                                                  \
  V(DotRange, ".range")                                                        \
  V(ArgumentError, "ArgumentError")                                            \
  V(DotValue, ".value")                                                        \
  V(FormatException, "FormatException")                                        \
  V(UnsupportedError, "UnsupportedError")                                      \
  V(StackOverflowError, "StackOverflowError")                                  \
  V(OutOfMemoryError, "OutOfMemoryError")                                      \
  V(NullThrownError, "NullThrownError")                                        \
  V(IsolateSpawnException, "IsolateSpawnException")                            \
  V(IsolateUnhandledException, "_IsolateUnhandledException")                   \
  V(JavascriptIntegerOverflowError, "_JavascriptIntegerOverflowError")         \
  V(JavascriptCompatibilityError, "_JavascriptCompatibilityError")             \
  V(BooleanExpression, "boolean expression")                                   \
  V(Malformed, "malformed")                                                    \
  V(Malbounded, "malbounded")                                                  \
  V(MegamorphicMiss, "megamorphic_miss")                                       \
  V(CommaSpace, ", ")                                                          \
  V(ColonSpace, ": ")                                                          \
  V(RParenArrow, ") => ")                                                      \
  V(SpaceExtendsSpace, " extends ")                                            \
  V(SwitchExpr, ":switch_expr")                                                \
  V(TwoNewlines, "\n\n")                                                       \
  V(TwoSpaces, "  ")                                                           \
  V(_instanceOf, "_instanceOf")                                                \
  V(_instanceOfSmi, "_instanceOfSmi")                                          \
  V(_instanceOfNum, "_instanceOfNum")                                          \
  V(_instanceOfInt, "_instanceOfInt")                                          \
  V(_instanceOfDouble, "_instanceOfDouble")                                    \
  V(_instanceOfString, "_instanceOfString")                                    \
  V(_as, "_as")                                                                \
  V(GetterPrefix, "get:")                                                      \
  V(ClosurizePrefix, "get:#")                                                  \
  V(SetterPrefix, "set:")                                                      \
  V(InitPrefix, "init:")                                                       \
  V(_New, "_new")                                                              \
  V(Index, "index")                                                            \
  V(DartScheme, "dart:")                                                       \
  V(DartSchemePrivate, "dart:_")                                               \
  V(DartNativeWrappers, "dart:nativewrappers")                                 \
  V(DartNativeWrappersLibName, "dart.nativewrappers")                          \
  V(DartCore, "dart:core")                                                     \
  V(DartCollection, "dart:collection")                                         \
  V(DartDeveloper, "dart:developer")                                           \
  V(DartInternal, "dart:_internal")                                            \
  V(DartIsolate, "dart:isolate")                                               \
  V(DartMirrors, "dart:mirrors")                                               \
  V(DartTypedData, "dart:typed_data")                                          \
  V(DartVMService, "dart:_vmservice")                                          \
  V(DartIOLibName, "dart.io")                                                  \
  V(EvalSourceUri, "evaluate:source")                                          \
  V(_Random, "_Random")                                                        \
  V(_state, "_state")                                                          \
  V(_A, "_A")                                                                  \
  V(_stackTrace, "_stackTrace")                                                \
  V(_SpecialTypeMirror, "_SpecialTypeMirror")                                  \
  V(_LocalClassMirror, "_LocalClassMirror")                                    \
  V(_LocalFunctionTypeMirror, "_LocalFunctionTypeMirror")                      \
  V(_LocalLibraryMirror, "_LocalLibraryMirror")                                \
  V(_LocalLibraryDependencyMirror, "_LocalLibraryDependencyMirror")            \
  V(_LocalCombinatorMirror, "_LocalCombinatorMirror")                          \
  V(_LocalMethodMirror, "_LocalMethodMirror")                                  \
  V(_LocalVariableMirror, "_LocalVariableMirror")                              \
  V(_LocalParameterMirror, "_LocalParameterMirror")                            \
  V(_LocalIsolateMirror, "_LocalIsolateMirror")                                \
  V(_LocalMirrorSystem, "_LocalMirrorSystem")                                  \
  V(_LocalTypedefMirror, "_LocalTypedefMirror")                                \
  V(_LocalTypeVariableMirror, "_LocalTypeVariableMirror")                      \
  V(_SourceLocation, "_SourceLocation")                                        \
  V(hashCode, "get:hashCode")                                                  \
  V(_leftShiftWithMask32, "_leftShiftWithMask32")                              \
  V(OptimizedOut, "<optimized out>")                                           \
  V(NotInitialized, "<not initialized>")                                       \
  V(AllocationStubFor, "[Stub] Allocate ")                                     \
  V(TempParam, ":temp_param")                                                  \
  V(_UserTag, "_UserTag")                                                      \
  V(Default, "Default")                                                        \
  V(StubPrefix, "[Stub] ")                                                     \
  V(ClassID, "ClassID")                                                        \
  V(DartIsVM, "dart.isVM")                                                     \
  V(stack, ":stack")                                                           \
  V(stack_pointer, ":stack_pointer")                                           \
  V(current_character, ":current_character")                                   \
  V(current_position, ":current_position")                                     \
  V(string_param_length, ":string_param_length")                               \
  V(capture_length, ":capture_length")                                         \
  V(word_character_map, ":word_character_map")                                 \
  V(match_start_index, ":match_start_index")                                   \
  V(capture_start_index, ":capture_start_index")                               \
  V(match_end_index, ":match_end_index")                                       \
  V(char_in_capture, ":char_in_capture")                                       \
  V(char_in_match, ":char_in_match")                                           \
  V(index_temp, ":index_temp")                                                 \
  V(result, ":result")                                                         \
  V(position_registers, ":position_registers")                                 \
  V(string_param, ":string_param")                                             \
  V(start_index_param, ":start_index_param")                                   \
  V(clear, "clear")                                                            \
  V(_wordCharacterMap, "_wordCharacterMap")                                    \
  V(print, "print")                                                            \
  V(last, "last")                                                              \
  V(removeLast, "removeLast")                                                  \
  V(add, "add")                                                                \
  V(ConstructorClosurePrefix, "new#")                                          \
  V(_runExtension, "_runExtension")                                            \
  V(_runPendingImmediateCallback, "_runPendingImmediateCallback")              \


// Contains a list of frequently used strings in a canonicalized form. This
// list is kept in the vm_isolate in order to share the copy across isolates
// without having to maintain copies in each isolate.
class Symbols : public AllStatic {
 public:
  enum { kMaxOneCharCodeSymbol = 0xFF };

  // List of strings that are pre created in the vm isolate.
  enum SymbolId {
    kIllegal = 0,

#define DEFINE_SYMBOL_INDEX(symbol, literal)                                   \
    k##symbol##Id,
    PREDEFINED_SYMBOLS_LIST(DEFINE_SYMBOL_INDEX)
#undef DEFINE_SYMBOL_INDEX

    kKwTableStart,  // First keyword at kKwTableStart + 1.

#define DEFINE_KEYWORD_SYMBOL_INDEX(t, s, p, a)                            \
    t##Id,
    DART_KEYWORD_LIST(DEFINE_KEYWORD_SYMBOL_INDEX)
#undef DEFINE_KEYWORD_SYMBOL_INDEX

    kNullCharId,  // One char code symbol starts here and takes up 256 entries.
    kMaxPredefinedId = kNullCharId + kMaxOneCharCodeSymbol + 1,
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
  static const String& Dot() {
    return *(symbol_handles_[kNullCharId + '.']);
  }
  static const String& Equals() {
    return *(symbol_handles_[kNullCharId + '=']);
  }
  static const String& Plus() {
    return *(symbol_handles_[kNullCharId + '+']);
  }
  static const String& Minus() {
    return *(symbol_handles_[kNullCharId + '-']);
  }
  static const String& BitOr() {
    return *(symbol_handles_[kNullCharId + '|']);
  }
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
  static const String& Blank() {
    return *(symbol_handles_[kNullCharId + ' ']);
  }
  static const String& Dollar() {
    return *(symbol_handles_[kNullCharId + '$']);
  }
  static const String& NewLine() {
    return *(symbol_handles_[kNullCharId + '\n']);
  }
  static const String& DoubleQuotes() {
    return *(symbol_handles_[kNullCharId + '"']);
  }
  static const String& LowercaseR() {
    return *(symbol_handles_[kNullCharId + 'r']);
  }
  static const String& Dash() {
    return *(symbol_handles_[kNullCharId + '-']);
  }
  static const String& Ampersand() {
    return *(symbol_handles_[kNullCharId + '&']);
  }
  static const String& Backtick() {
    return *(symbol_handles_[kNullCharId + '`']);
  }
  static const String& Slash() {
    return *(symbol_handles_[kNullCharId + '/']);
  }
  static const String& At() {
    return *(symbol_handles_[kNullCharId + '@']);
  }
  static const String& HashMark() {
    return *(symbol_handles_[kNullCharId + '#']);
  }
  static const String& Semicolon() {
    return *(symbol_handles_[kNullCharId + ';']);
  }
  static const String& Star() {
    return *(symbol_handles_[kNullCharId + '*']);
  }
  static const String& Percent() {
    return *(symbol_handles_[kNullCharId + '%']);
  }
  static const String& Caret() {
    return *(symbol_handles_[kNullCharId + '^']);
  }
  static const String& Tilde() {
    return *(symbol_handles_[kNullCharId + '~']);
  }

  static const String& Empty() { return *(symbol_handles_[kKwTableStart]); }
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
  DART_KEYWORD_LIST(DEFINE_SYMBOL_HANDLE_ACCESSOR)
#undef DEFINE_SYMBOL_HANDLE_ACCESSOR

  // Get symbol for scanner keyword.
  static const String& Keyword(Token::Kind keyword);

  // Initialize frequently used symbols in the vm isolate.
  static void InitOnce(Isolate* isolate);
  static void InitOnceFromSnapshot(Isolate* isolate);

  // Add all the symbols that were cached in the VM isolate to this isolate,
  // we do this when an Isolate is not created from the snapshot so that
  // we get a unified symbol table that can be be dumped into the VM isolate
  // snapshot.
  static void AddPredefinedSymbolsToIsolate();

  // Initialize and setup a symbol table for the isolate.
  static void SetupSymbolTable(Isolate* isolate);

  // Creates a Symbol given a C string that is assumed to contain
  // UTF-8 encoded characters and '\0' is considered a termination character.
  // TODO(7123) - Rename this to FromCString(....).
  static RawString* New(const char* cstr) {
    return New(cstr, strlen(cstr));
  }
  static RawString* New(const char* cstr, intptr_t length);

  // Creates a new Symbol from an array of UTF-8 encoded characters.
  static RawString* FromUTF8(const uint8_t* utf8_array, intptr_t len);

  // Creates a new Symbol from an array of Latin-1 encoded characters.
  static RawString* FromLatin1(const uint8_t* latin1_array, intptr_t len);

  // Creates a new Symbol from an array of UTF-16 encoded characters.
  static RawString* FromUTF16(const uint16_t* utf16_array, intptr_t len);

  // Creates a new Symbol from an array of UTF-32 encoded characters.
  static RawString* FromUTF32(const int32_t* utf32_array, intptr_t len);

  static RawString* New(const String& str);
  static RawString* New(const String& str,
                        intptr_t begin_index,
                        intptr_t length);

  static RawString* NewFormatted(const char* format, ...)
      PRINTF_ATTRIBUTE(1, 2);
  static RawString* NewFormattedV(const char* format, va_list args);

  static RawString* FromConcat(const String& str1, const String& str2);

  static RawString* FromConcatAll(
      const GrowableHandlePtrArray<const String>& strs);

  // Returns char* of predefined symbol.
  static const char* Name(SymbolId symbol);

  static RawString* FromCharCode(int32_t char_code);

  static RawString** PredefinedAddress() {
    return reinterpret_cast<RawString**>(&predefined_);
  }

  static void DumpStats();

  // Returns Symbol::Null if no symbol is found.
  template<typename StringType>
  static RawString* Lookup(const StringType& str);

  // Returns Symbol::Null if no symbol is found.
  static RawString* LookupFromConcat(const String& str1, const String& str2);

 private:
  enum {
    kInitialVMIsolateSymtabSize = 1024,
    kInitialSymtabSize = 2048
  };

  static void GetStats(Isolate* isolate,
                       intptr_t* size,
                       intptr_t* capacity);

  template<typename StringType>
  static RawString* NewSymbol(const StringType& str);

  static intptr_t LookupVMSymbol(RawObject* obj);
  static RawObject* GetVMSymbol(intptr_t object_id);
  static bool IsVMSymbolId(intptr_t object_id) {
    return (object_id >= kMaxPredefinedObjectIds &&
            object_id < (kMaxPredefinedObjectIds + kMaxPredefinedId));
  }

  // List of Latin1 characters stored in the vm isolate as symbols
  // in order to make Symbols::FromCharCode fast. This structure is
  // used in generated dart code for direct access to these objects.
  static RawString* predefined_[kNumberOfOneCharCodeSymbols];

  // List of handles for predefined symbols.
  static String* symbol_handles_[kMaxPredefinedId];

  friend class Dart;
  friend class String;
  friend class SnapshotReader;
  friend class SnapshotWriter;
  friend class ApiMessageReader;

  DISALLOW_COPY_AND_ASSIGN(Symbols);
};

}  // namespace dart

#endif  // VM_SYMBOLS_H_
