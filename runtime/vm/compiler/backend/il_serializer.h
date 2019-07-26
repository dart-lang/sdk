// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_

#include "platform/text_buffer.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"

namespace dart {

// Flow graph serialization.
class FlowGraphSerializer : ValueObject {
 public:
  static void SerializeToBuffer(const FlowGraph* flow_graph,
                                TextBuffer* buffer);
  static void SerializeToBuffer(Zone* zone,
                                const FlowGraph* flow_graph,
                                TextBuffer* buffer);

  const FlowGraph* flow_graph() const { return flow_graph_; }
  Zone* zone() const { return zone_; }

  SExpression* FunctionToSExp();

  SExpression* BlockIdToSExp(intptr_t block_id);
  SExpression* BlockEntryToSExp(const char* entry_name, BlockEntryInstr* entry);
  SExpression* CanonicalNameToSExp(const Object& obj);
  SExpression* UseToSExp(const Definition* definition);

  void SerializeCanonicalName(TextBuffer* b, const Object& obj);

  // Methods for serializing Dart values.
  SExpression* AbstractTypeToSExp(const AbstractType& typ);
  SExpression* ClassToSExp(const Class& cls);
  SExpression* CodeToSExp(const Code& c);
  SExpression* FieldToSExp(const Field& f);
  SExpression* SlotToSExp(const Slot& s);
  SExpression* TypeArgumentsToSExp(const TypeArguments& ta);
  SExpression* DartValueToSExp(const Object& obj);

  // Helper methods for adding atoms to S-expression lists
  void AddBool(SExpList* sexp, bool b);
  void AddInteger(SExpList* sexp, intptr_t i);
  void AddString(SExpList* sexp, const char* cstr);
  void AddSymbol(SExpList* sexp, const char* cstr);
  void AddExtraBool(SExpList* sexp, const char* label, bool b);
  void AddExtraInteger(SExpList* sexp, const char* label, intptr_t i);
  void AddExtraString(SExpList* sexp, const char* label, const char* cstr);
  void AddExtraSymbol(SExpList* sexp, const char* label, const char* cstr);

 private:
  FlowGraphSerializer(Zone* zone, const FlowGraph* flow_graph)
      : flow_graph_(flow_graph),
        zone_(zone),
        tmp_type_(AbstractType::Handle(zone_)),
        tmp_class_(Class::Handle(zone_)),
        tmp_function_(Function::Handle(zone_)),
        tmp_library_(Library::Handle(zone_)),
        tmp_object_(Object::Handle(zone_)),
        tmp_string_(String::Handle(zone_)) {}

  static const char* const initial_indent;

  void AddConstantPool(SExpList* sexp);
  void AddBlocks(SExpList* sexp);

  const FlowGraph* flow_graph_;
  Zone* zone_;

  // Handles for temporary use.
  AbstractType& tmp_type_;
  Class& tmp_class_;
  Function& tmp_function_;
  Library& tmp_library_;
  Object& tmp_object_;
  String& tmp_string_;
};

// Abstract base class for S-expressions used as an intermediate form for the
// IL serializer. These aren't true (LISP-like) S-expressions, as the atoms
// are more restricted and the lists have extra information. Here is an
// illustrative BNF-style grammar of the current serialized form of
// S-expressions that includes non-whitespace literal tokens:
//
// <s-exp>      ::= <atom>   | <list>
// <atom>       ::= <symbol> | <string>
// <list>       ::= '(' <s-exp>* <extra-info>? ')'
// <extra-info> ::= '{' <extra-elem>* '}'
// <extra-elem> ::= <symbol> <s-exp> ','
//
// Here, <string>s are double-quoted strings with backslash escaping and
// <symbol>s are sequences of consecutive non-whitespace characters that do not
// include commas (,), parentheses (()), curly braces ({}), or the double-quote
// character ("). At this level, numbers such as 4, 3.0, or booleans (true,
// false) are represented as symbols instead of separate atom types.
//
// In addition, the <extra-info> is considered a map from symbol labels to
// S-expression values, and as such each symbol used as a key in an <extra-info>
// block should only appear once as a key within that block.
class SExpression : public ZoneAllocated {
 public:
  SExpression() {}
  virtual ~SExpression() {}
  virtual bool IsAtom() const = 0;
  virtual void SerializeTo(Zone* zone,
                           TextBuffer* buffer,
                           const char* indent,
                           intptr_t width = 80) const = 0;
  virtual void SerializeToLine(TextBuffer* buffer) const = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(SExpression);
};

// A single S-expression atom. Both symbols and strings are represented with
// C-style strings internally, with a boolean to distinguish.
class SExpAtom : public SExpression {
 public:
  explicit SExpAtom(const char* cstr, bool is_symbol = true)
      : cstr_(cstr), is_symbol_(is_symbol) {}

  const char* contents() const { return cstr_; }

  bool IsSymbol() const { return is_symbol_; }

  virtual bool IsAtom() const { return true; }

  virtual void SerializeTo(Zone* zone,
                           TextBuffer* buffer,
                           const char* indent,
                           intptr_t width = 80) const {
    SerializeToLine(buffer);
  }

  virtual void SerializeToLine(TextBuffer* buffer) const;

 private:
  const char* const cstr_;
  const bool is_symbol_;

  DISALLOW_COPY_AND_ASSIGN(SExpAtom);
};

// A list of S-expressions. Unlike normal S-expressions, an S-expression list
// also contains a hash map kept separate from the elements, which we use for
// extra non-argument information for IL instructions.
class SExpList : public SExpression {
 public:
  explicit SExpList(Zone* zone) : contents_(zone, 2), extra_info_(zone) {}

  // TODO(dartbug.com/36882): When we start deserializing and so are no longer
  // using in-code constant keys, change this to a trait that does full C
  // string hashing/equality, not just pointer hashing/equality.
  using ExtraInfoKeyValueTrait =
      RawPointerKeyValueTrait<const char, SExpression*>;
  using ExtraInfoHashMap = DirectChainedHashMap<ExtraInfoKeyValueTrait>;

  ExtraInfoHashMap extra_info() const { return extra_info_; }

  void Add(SExpression* sexp);
  void AddExtra(const char* label, SExpression* value);

  SExpression* At(intptr_t i) const { return contents_.At(i); }
  intptr_t Length() const { return contents_.length(); }

  virtual bool IsAtom() const { return false; }
  virtual void SerializeTo(Zone* zone,
                           TextBuffer* buffer,
                           const char* indent,
                           intptr_t width = 80) const;
  virtual void SerializeToLine(TextBuffer* buffer) const;

 private:
  static const char* const kElemIndent;
  static const char* const kExtraIndent;

  void SerializeExtraInfoTo(Zone* zone,
                            TextBuffer* buffer,
                            const char* indent,
                            intptr_t width) const;
  void SerializeExtraInfoToLine(TextBuffer* buffer) const;

  ZoneGrowableArray<SExpression*> contents_;
  ExtraInfoHashMap extra_info_;

  DISALLOW_COPY_AND_ASSIGN(SExpList);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
