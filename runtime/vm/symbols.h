// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SYMBOLS_H_
#define VM_SYMBOLS_H_

#include "vm/object.h"
#include "vm/snapshot_ids.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;

#define PREDEFINED_SYMBOLS_LIST(V)                                             \
  V(Empty, "")                                                                 \
  V(EqualOperator, "==")                                                       \
  V(Identical, "identical")                                                    \
  V(Length, "length")                                                          \
  V(IndexToken, "[]")                                                          \
  V(AssignIndexToken, "[]=")                                                   \
  V(TopLevel, "::")                                                            \
  V(DefaultLabel, ":L")                                                        \
  V(This, "this")                                                              \
  V(Super, "super")                                                            \
  V(Call, "call")                                                              \
  V(Current, "current")                                                        \
  V(MoveNext, "moveNext")                                                      \
  V(Value, "value")                                                            \
  V(ExprTemp, ":expr_temp")                                                    \
  V(AnonymousClosure, "<anonymous closure>")                                   \
  V(ClosureParameter, ":closure")                                              \
  V(PhaseParameter, ":phase")                                                  \
  V(TypeArgumentsParameter, ":type_arguments")                                 \
  V(AssertionError, "AssertionErrorImplementation")                            \
  V(TypeError, "TypeErrorImplementation")                                      \
  V(FallThroughError, "FallThroughErrorImplementation")                        \
  V(AbstractClassInstantiationError,                                           \
    "AbstractClassInstantiationErrorImplementation")                           \
  V(NoSuchMethodError, "NoSuchMethodError")                                    \
  V(ThrowNew, "_throwNew")                                                     \
  V(List, "List")                                                              \
  V(ListLiteralFactory, "List._fromLiteral")                                   \
  V(ListFactory, "List.")                                                      \
  V(Map, "Map")                                                                \
  V(MapLiteralFactory, "Map._fromLiteral")                                     \
  V(ImmutableMap, "ImmutableMap")                                              \
  V(ImmutableMapConstructor, "ImmutableMap._create")                           \
  V(StringBase, "_StringBase")                                                 \
  V(Interpolate, "_interpolate")                                               \
  V(GetIterator, "iterator")                                                   \
  V(NoSuchMethod, "noSuchMethod")                                              \
  V(SavedArgDescVarPrefix, ":saved_args_desc_var")                             \
  V(SavedCurrentContextVar, ":saved_current_context_var")                      \
  V(SavedEntryContextVar, ":saved_entry_context_var")                          \
  V(SavedTryContextVar, ":saved_try_context_var")                              \
  V(ExceptionVar, ":exception_var")                                            \
  V(StacktraceVar, ":stacktrace_var")                                          \
  V(ArrayLiteralVar, ":array_literal_var")                                     \
  V(ListLiteralElement, "list literal element")                                \
  V(ForInIter, ":for-in-iter")                                                 \
  V(Library, "library")                                                        \
  V(Import, "import")                                                          \
  V(Source, "source")                                                          \
  V(Class, "Class")                                                            \
  V(Null, "Null")                                                              \
  V(Dynamic, "dynamic")                                                        \
  V(Void, "void")                                                              \
  V(UnresolvedClass, "UnresolvedClass")                                        \
  V(Type, "_Type")                                                             \
  V(TypeParameter, "_TypeParameter")                                           \
  V(TypeArguments, "TypeArguments")                                            \
  V(InstantiatedTypeArguments, "InstantiatedTypeArguments")                    \
  V(PatchClass, "PatchClass")                                                  \
  V(Function, "Function")                                                      \
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
  V(ObjectArray, "_ObjectArray")                                               \
  V(ObjectArrayFactory, "_ObjectArray.")                                       \
  V(GrowableObjectArray, "_GrowableObjectArray")                               \
  V(GrowableObjectArrayFactory, "_GrowableObjectArray.")                       \
  V(GrowableObjectArrayWithData, "_GrowableObjectArray.withData")              \
  V(ImmutableArray, "_ImmutableArray")                                         \
  V(OneByteString, "_OneByteString")                                           \
  V(TwoByteString, "_TwoByteString")                                           \
  V(ExternalOneByteString, "_ExternalOneByteString")                           \
  V(ExternalTwoByteString, "_ExternalTwoByteString")                           \
  V(StackTrace, "StackTrace")                                                  \
  V(JSSyntaxRegExp, "_JSSyntaxRegExp")                                         \
  V(Object, "Object")                                                          \
  V(Int, "int")                                                                \
  V(Double, "double")                                                          \
  V(_Float32x4, "_Float32x4")                                                  \
  V(_Uint32x4, "_Uint32x4")                                                    \
  V(Float32x4, "Float32x4")                                                    \
  V(Uint32x4, "Uint32x4")                                                      \
  V(Int8List, "Int8List")                                                      \
  V(Int8ListFactory, "Int8List.")                                              \
  V(Uint8List, "Uint8List")                                                    \
  V(Uint8ListFactory, "Uint8List.")                                            \
  V(Uint8ClampedList, "Uint8ClampedList")                                      \
  V(Uint8ClampedListFactory, "Uint8ClampedList.")                              \
  V(Int16List, "Int16List")                                                    \
  V(Int16ListFactory, "Int16List.")                                            \
  V(Uint16List, "Uint16List")                                                  \
  V(Uint16ListFactory, "Uint16List.")                                          \
  V(Int32List, "Int32List")                                                    \
  V(Int32ListFactory, "Int32List.")                                            \
  V(Uint32List, "Uint32List")                                                  \
  V(Uint32ListFactory, "Uint32List.")                                          \
  V(Int64List, "Int64List")                                                    \
  V(Int64ListFactory, "Int64List.")                                            \
  V(Uint64List, "Uint64List")                                                  \
  V(Uint64ListFactory, "Uint64List.")                                          \
  V(Float32x4List, "Float32x4List")                                            \
  V(Float32List, "Float32List")                                                \
  V(Float32ListFactory, "Float32List.")                                        \
  V(Float64List, "Float64List")                                                \
  V(Float64ListFactory, "Float64List.")                                        \
  V(_Int8Array, "_Int8Array")                                                  \
  V(_Uint8Array, "_Uint8Array")                                                \
  V(_Uint8ClampedArray, "_Uint8ClampedArray")                                  \
  V(_Int16Array, "_Int16Array")                                                \
  V(_Uint16Array, "_Uint16Array")                                              \
  V(_Int32Array, "_Int32Array")                                                \
  V(_Uint32Array, "_Uint32Array")                                              \
  V(_Int64Array, "_Int64Array")                                                \
  V(_Uint64Array, "_Uint64Array")                                              \
  V(_Float32x4Array, "_Float32x4Array")                                        \
  V(_Float32Array, "_Float32Array")                                            \
  V(_Float64Array, "_Float64Array")                                            \
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
  V(_ExternalFloat32Array, "_ExternalFloat32Array")                            \
  V(_ExternalFloat64Array, "_ExternalFloat64Array")                            \
  V(ByteData, "ByteData")                                                      \
  V(ByteDataDot, "ByteData.")                                                  \
  V(ByteDataDotview, "ByteData.view")                                          \
  V(_ByteDataView, "_ByteDataView")                                            \
  V(_WeakProperty, "_WeakProperty")                                            \
  V(InvocationMirror, "_InvocationMirror")                                     \
  V(AllocateInvocationMirror, "_allocateInvocationMirror")                     \
  V(toString, "toString")                                                      \
  V(_ReceivePortImpl, "_ReceivePortImpl")                                      \
  V(_lookupReceivePort, "_lookupReceivePort")                                  \
  V(_handleMessage, "_handleMessage")                                          \
  V(_SendPortImpl, "_SendPortImpl")                                            \
  V(_create, "_create")                                                        \
  V(_id, "_id")                                                                \
  V(_get_or_create, "_get_or_create")                                          \
  V(RangeError, "RangeError")                                                  \
  V(ArgumentError, "ArgumentError")                                            \
  V(FormatException, "FormatException")                                        \
  V(UnsupportedError, "UnsupportedError")                                      \
  V(StackOverflowError, "StackOverflowError")                                  \
  V(OutOfMemoryError, "OutOfMemoryError")                                      \
  V(InternalError, "InternalError")                                            \
  V(NullThrownError, "NullThrownError")                                        \
  V(IsolateSpawnException, "IsolateSpawnException")                            \
  V(IsolateUnhandledException, "IsolateUnhandledException")                    \
  V(_setupFullStackTrace, "_setupFullStackTrace")                              \
  V(BooleanExpression, "boolean expression")                                   \
  V(Malformed, "malformed")                                                    \
  V(InstanceOf, "InstanceOf")                                                  \
  V(MegamorphicMiss, "megamorphic_miss")                                       \
  V(CommaSpace, ", ")                                                          \
  V(ColonSpace, ": ")                                                          \
  V(RParenArrow, ") => ")                                                      \
  V(SpaceExtendsSpace, " extends ")                                            \
  V(SwitchExpr, ":switch_expr")                                                \
  V(TwoNewlines, "\n\n")                                                       \
  V(TwoSpaces, "  ")                                                           \
  V(_instanceOf, "_instanceOf")                                                \
  V(_as, "_as")                                                                \
  V(PrivateGetterPrefix, "get:_")                                              \
  V(PrivateSetterPrefix, "set:_")                                              \
  V(_New, "_new")                                                              \
  V(DartScheme, "dart:")                                                       \
  V(DartSchemePrivate, "dart:_")                                               \
  V(DartCore, "dart:core")                                                     \
  V(DartCollection, "dart:collection")                                         \
  V(DartCollectionDev, "dart:_collection-dev")                                 \
  V(DartMath, "dart:math")                                                     \
  V(DartIsolate, "dart:isolate")                                               \
  V(DartMirrors, "dart:mirrors")                                               \
  V(DartTypedData, "dart:typeddata")                                           \
  V(DartNativeWrappers, "dart:nativewrappers")                                 \
  V(DartAsync, "dart:async")                                                   \
  V(DartUri, "dart:uri")                                                       \
  V(DartUtf, "dart:utf")                                                       \
  V(DartCrypto, "dart:crypto")                                                 \
  V(DartJson, "dart:json")                                                     \


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

    kNullCharId,  // One char code symbol starts here and takes up 256 entries.
    kMaxPredefinedId = kNullCharId + kMaxOneCharCodeSymbol + 1,
  };

  // Number of one character symbols being predefined in the predefined_ array.
  static const int kNumberOfOneCharCodeSymbols =
      (kMaxPredefinedId - kNullCharId);

  // Offset of Null character which is the predefined character symbol.
  static const int kNullCharCodeSymbolOffset = 0;

  // Access methods for one byte character symbols stored in the vm isolate.
  static const String& Dot() {
    return *(symbol_handles_[kNullCharId + '.']);
  }
  static const String& Equals() {
    return *(symbol_handles_[kNullCharId + '=']);
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

  // Access methods for symbol handles stored in the vm isolate.
#define DEFINE_SYMBOL_HANDLE_ACCESSOR(symbol, literal)                         \
  static const String& symbol() { return *(symbol_handles_[k##symbol##Id]); }
PREDEFINED_SYMBOLS_LIST(DEFINE_SYMBOL_HANDLE_ACCESSOR)
#undef DEFINE_SYMBOL_HANDLE_ACCESSOR

  // Initialize frequently used symbols in the vm isolate.
  static void InitOnce(Isolate* isolate);

  // Initialize and setup a symbol table for the isolate.
  static void SetupSymbolTable(Isolate* isolate);

  // Get number of symbols in an isolate's symbol table.
  static intptr_t Size(Isolate* isolate);

  // Creates a Symbol given a C string that is assumed to contain
  // UTF-8 encoded characters and '\0' is considered a termination character.
  // TODO(7123) - Rename this to FromCString(....).
  static RawString* New(const char* cstr);

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

  // Returns char* of predefined symbol.
  static const char* Name(SymbolId symbol);

  static RawString* FromCharCode(int32_t char_code);

  static RawString** PredefinedAddress() {
    return reinterpret_cast<RawString**>(&predefined_);
  }

  static void DumpStats();

 private:
  enum {
    kInitialVMIsolateSymtabSize = 512,
    kInitialSymtabSize = 2048
  };

  // Helper functions to create a symbol given a string or set of characters.
  template<typename CharacterType, typename CallbackType>
  static RawString* NewSymbol(const CharacterType* characters,
                              intptr_t len,
                              CallbackType new_string);

  // Add the string into the VM isolate symbol table.
  static void Add(const Array& symbol_table, const String& str);

  // Insert symbol into symbol table, growing it if necessary.
  static void InsertIntoSymbolTable(const Array& symbol_table,
                                    const String& symbol,
                                    intptr_t index);

  // Grow the symbol table.
  static void GrowSymbolTable(const Array& symbol_table);

  // Return index in symbol table if the symbol already exists or
  // return the index into which the new symbol can be added.
  template<typename T>
  static intptr_t FindIndex(const Array& symbol_table,
                            const T* characters,
                            intptr_t len,
                            intptr_t hash);
  static intptr_t FindIndex(const Array& symbol_table,
                            const String& str,
                            intptr_t begin_index,
                            intptr_t len,
                            intptr_t hash);
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

  // Statistics used to measure the efficiency of the symbol table.
  static const intptr_t kMaxCollisionBuckets = 10;
  static intptr_t num_of_grows_;
  static intptr_t collision_count_[kMaxCollisionBuckets];

  friend class String;
  friend class SnapshotReader;
  friend class SnapshotWriter;
  friend class ApiMessageReader;

  DISALLOW_COPY_AND_ASSIGN(Symbols);
};

}  // namespace dart

#endif  // VM_SYMBOLS_H_
