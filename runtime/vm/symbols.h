// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SYMBOLS_H_
#define RUNTIME_VM_SYMBOLS_H_

#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/symbol_list.h"

namespace dart {

// Forward declarations.
class IsolateGroup;
class ObjectPointerVisitor;

// Contains a list of frequently used strings in a canonicalized form. This
// list is kept in the vm_isolate in order to share the copy across isolates
// without having to maintain copies in each isolate.
class Symbols : public AllStatic {
 public:
  enum { kMaxOneCharCodeSymbol = 0xFF };

  // List of strings that are pre created in the vm isolate.
  // clang-format off
  enum SymbolId {
#define DEFINE_SYMBOL_INDEX(symbol, literal) k##symbol##Id,
PREDEFINED_SYMBOLS_LIST(DEFINE_SYMBOL_INDEX)
#undef DEFINE_SYMBOL_INDEX
    kNullCharId,  // One char code symbol starts here and takes up 256 entries.
    kMaxPredefinedId = kNullCharId + kMaxOneCharCodeSymbol + 1,
  };
  // clang-format on

  // Number of one character symbols being predefined in the predefined_ array.
  static constexpr int kNumberOfOneCharCodeSymbols =
      (kMaxPredefinedId - kNullCharId);

  // Offset of Null character which is the predefined character symbol.
  static constexpr int kNullCharCodeSymbolOffset = 0;

  static const String& Symbol(intptr_t index) {
    ASSERT((index >= 0) && (index < kMaxPredefinedId));
    return Roots::symbol_handle(index);
  }
  static void InitSymbol(intptr_t index, StringPtr symbol) {
    ASSERT((index >= 0) && (index < kMaxPredefinedId));
    Roots::symbol_handle(index).initRO(symbol);
  }

  // Access methods for one byte character symbols stored in the vm isolate.
  static const String& Dot() { return Symbol(kNullCharId + '.'); }
  static const String& Equals() { return Symbol(kNullCharId + '='); }
  static const String& Plus() { return Symbol(kNullCharId + '+'); }
  static const String& Minus() { return Symbol(kNullCharId + '-'); }
  static const String& BitOr() { return Symbol(kNullCharId + '|'); }
  static const String& BitAnd() { return Symbol(kNullCharId + '&'); }
  static const String& LAngleBracket() { return Symbol(kNullCharId + '<'); }
  static const String& RAngleBracket() { return Symbol(kNullCharId + '>'); }
  static const String& LParen() { return Symbol(kNullCharId + '('); }
  static const String& RParen() { return Symbol(kNullCharId + ')'); }
  static const String& LBracket() { return Symbol(kNullCharId + '['); }
  static const String& RBracket() { return Symbol(kNullCharId + ']'); }
  static const String& LBrace() { return Symbol(kNullCharId + '{'); }
  static const String& RBrace() { return Symbol(kNullCharId + '}'); }
  static const String& Blank() { return Symbol(kNullCharId + ' '); }
  static const String& Dollar() { return Symbol(kNullCharId + '$'); }
  static const String& NewLine() { return Symbol(kNullCharId + '\n'); }
  static const String& DoubleQuote() { return Symbol(kNullCharId + '"'); }
  static const String& SingleQuote() { return Symbol(kNullCharId + '\''); }
  static const String& LowercaseR() { return Symbol(kNullCharId + 'r'); }
  static const String& Dash() { return Symbol(kNullCharId + '-'); }
  static const String& Ampersand() { return Symbol(kNullCharId + '&'); }
  static const String& Backtick() { return Symbol(kNullCharId + '`'); }
  static const String& Slash() { return Symbol(kNullCharId + '/'); }
  static const String& At() { return Symbol(kNullCharId + '@'); }
  static const String& HashMark() { return Symbol(kNullCharId + '#'); }
  static const String& Semicolon() { return Symbol(kNullCharId + ';'); }
  static const String& Star() { return Symbol(kNullCharId + '*'); }
  static const String& Percent() { return Symbol(kNullCharId + '%'); }
  static const String& QuestionMark() { return Symbol(kNullCharId + '?'); }
  static const String& Caret() { return Symbol(kNullCharId + '^'); }
  static const String& Tilde() { return Symbol(kNullCharId + '~'); }

// Access methods for symbol handles stored in the vm isolate for predefined
// symbols.
#define DEFINE_SYMBOL_HANDLE_ACCESSOR(symbol, literal)                         \
  static const String& symbol() { return Symbol(k##symbol##Id); }
  PREDEFINED_SYMBOLS_LIST(DEFINE_SYMBOL_HANDLE_ACCESSOR)
#undef DEFINE_SYMBOL_HANDLE_ACCESSOR

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

  static StringPtr FromCharCode(Thread* thread, uint16_t char_code);

  static StringPtr* PredefinedAddress() { return Roots::one_char_symbols(); }

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

  static void GetStats(IsolateGroup* isolate_group,
                       intptr_t* size,
                       intptr_t* capacity);

 private:
  enum { kInitialVMIsolateSymtabSize = 1024, kInitialSymtabSize = 2048 };

  template <typename StringType>
  static StringPtr NewSymbol(Thread* thread, const StringType& str);

  friend class Dart;
  friend class String;
  friend class Serializer;
  friend class Deserializer;

  DISALLOW_COPY_AND_ASSIGN(Symbols);
};

}  // namespace dart

#endif  // RUNTIME_VM_SYMBOLS_H_
