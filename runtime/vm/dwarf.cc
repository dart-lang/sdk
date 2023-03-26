// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dwarf.h"

#include "vm/code_comments.h"
#include "vm/code_descriptors.h"
#include "vm/elf.h"
#include "vm/image_snapshot.h"
#include "vm/object_store.h"

namespace dart {

#if defined(DART_PRECOMPILER)

DEFINE_FLAG(bool,
            resolve_dwarf_paths,
            false,
            "Resolve script URIs to absolute or relative file paths in DWARF");

DEFINE_FLAG(charp,
            write_code_comments_as_synthetic_source_to,
            nullptr,
            "Print comments associated with instructions into the given file");

class DwarfPosition {
 public:
  DwarfPosition(int32_t line, int32_t column) : line_(line), column_(column) {
    // Should only have no line information if also no column information.
    ASSERT(line_ > kNoLine || column_ <= kNoColumn);
  }
  // CodeSourceMaps start the line and column registers at -1, not at 0, and
  // the arguments passed to ChangePosition are retrieved from CodeSourceMaps.
  explicit DwarfPosition(int32_t line) : DwarfPosition(line, -1) {}
  constexpr DwarfPosition() : line_(-1), column_(-1) {}

  // The DWARF standard uses 0 to denote missing line or column
  // information.
  static constexpr int32_t kNoLine = 0;
  static constexpr int32_t kNoColumn = 0;

  int32_t line() const { return line_ > kNoLine ? line_ : kNoLine; }
  int32_t column() const { return column_ > kNoColumn ? column_ : kNoColumn; }

  // Adjusts the contents given the arguments to a ChangePosition instruction
  // from CodeSourceMaps.
  void ChangePosition(int32_t line_delta, int32_t new_column) {
    line_ = Utils::AddWithWrapAround(line_, line_delta);
    column_ = new_column;
  }

 private:
  int32_t line_;
  int32_t column_;
};

static constexpr auto kNoDwarfPositionInfo = DwarfPosition();

class InliningNode : public ZoneAllocated {
 public:
  InliningNode(const Function& function,
               const DwarfPosition& position,
               int32_t start_pc_offset)
      : function(function),
        position(position),
        start_pc_offset(start_pc_offset),
        end_pc_offset(-1),
        children_head(NULL),
        children_tail(NULL),
        children_next(NULL) {
    ASSERT(!function.IsNull());
    DEBUG_ASSERT(function.IsNotTemporaryScopedHandle());
  }

  void AppendChild(InliningNode* child) {
    if (children_tail == NULL) {
      children_head = children_tail = child;
    } else {
      children_tail->children_next = child;
      children_tail = child;
    }
  }

  const Function& function;
  DwarfPosition position;
  int32_t start_pc_offset;
  int32_t end_pc_offset;
  InliningNode* children_head;
  InliningNode* children_tail;
  InliningNode* children_next;
};

template <typename T>
Trie<T>* Trie<T>::AddString(Zone* zone,
                            Trie<T>* trie,
                            const char* key,
                            const T* value) {
  ASSERT(key != nullptr);
  if (trie == nullptr) {
    trie = new (zone) Trie<T>();
  }
  if (*key == '\0') {
    ASSERT(trie->value_ == nullptr);
    trie->value_ = value;
  } else {
    auto const index = ChildIndex(*key);
    ASSERT(index >= 0 && index < kNumValidChars);
    trie->children_[index] =
        AddString(zone, trie->children_[index], key + 1, value);
  }

  return trie;
}

template <typename T>
const T* Trie<T>::Lookup(const Trie<T>* trie, const char* key, intptr_t* end) {
  intptr_t i = 0;
  for (; key[i] != '\0'; i++) {
    auto const index = ChildIndex(key[i]);
    ASSERT(index < kNumValidChars);
    if (index < 0) {
      if (end == nullptr) return nullptr;
      break;
    }
    // Still find the longest valid trie prefix when no stored value.
    if (trie == nullptr) continue;
    trie = trie->children_[index];
  }
  if (end != nullptr) {
    *end = i;
  }
  if (trie == nullptr) return nullptr;
  return trie->value_;
}

Dwarf::Dwarf(Zone* zone)
    : zone_(zone),
      reverse_obfuscation_trie_(CreateReverseObfuscationTrie(zone)),
      codes_(zone, 1024),
      code_to_label_(zone),
      functions_(zone, 1024),
      function_to_index_(zone),
      scripts_(zone, 1024),
      script_to_index_(zone) {}

void Dwarf::AddCode(const Code& orig_code, intptr_t label) {
  ASSERT(!orig_code.IsNull());
  ASSERT(label > 0);

  if (auto const old_pair = code_to_label_.Lookup(&orig_code)) {
    // Dwarf objects can be shared, so we may get the same information for a
    // given code object in different calls. In DEBUG mode, make sure the
    // information is the same before returning.
    ASSERT_EQUAL(label, old_pair->value);
    return;
  }

  // Generate an appropriately zoned ZoneHandle for storing.
  const auto& code = Code::ZoneHandle(zone_, orig_code.ptr());
  codes_.Add(&code);
  // Currently assumes the name has the same lifetime as the Zone of the
  // Dwarf object (which is currently true).  Otherwise, need to copy.
  code_to_label_.Insert({&code, label});

  if (code.IsFunctionCode() && !code.IsUnknownDartCode()) {
    const Function& function = Function::Handle(zone_, code.function());
    AddFunction(function);
  }
  const Array& inline_functions =
      Array::Handle(zone_, code.inlined_id_to_function());
  if (!inline_functions.IsNull()) {
    Function& function = Function::Handle(zone_);
    for (intptr_t i = 0; i < inline_functions.Length(); i++) {
      function ^= inline_functions.At(i);
      AddFunction(function);
    }
  }
}

intptr_t Dwarf::AddFunction(const Function& function) {
  RELEASE_ASSERT(!function.IsNull());
  FunctionIndexPair* pair = function_to_index_.Lookup(&function);
  if (pair != NULL) {
    return pair->index_;
  }
  intptr_t index = functions_.length();
  const Function& zone_func = Function::ZoneHandle(zone_, function.ptr());
  function_to_index_.Insert(FunctionIndexPair(&zone_func, index));
  functions_.Add(&zone_func);
  const Script& script = Script::Handle(zone_, function.script());
  AddScript(script);
  return index;
}

intptr_t Dwarf::AddScript(const Script& script) {
  RELEASE_ASSERT(!script.IsNull());
  ScriptIndexPair* pair = script_to_index_.Lookup(&script);
  if (pair != NULL) {
    return pair->index_;
  }
  // DWARF file numbers start from 1.
  intptr_t index = scripts_.length() + 1;
  const Script& zone_script = Script::ZoneHandle(zone_, script.ptr());
  script_to_index_.Insert(ScriptIndexPair(&zone_script, index));
  scripts_.Add(&zone_script);
  return index;
}

intptr_t Dwarf::LookupFunction(const Function& function) {
  RELEASE_ASSERT(!function.IsNull());
  FunctionIndexPair* pair = function_to_index_.Lookup(&function);
  if (pair == NULL) {
    FATAL("Function detected too late during DWARF generation: %s",
          function.ToCString());
  }
  return pair->index_;
}

intptr_t Dwarf::LookupScript(const Script& script) {
  RELEASE_ASSERT(!script.IsNull());
  ScriptIndexPair* pair = script_to_index_.Lookup(&script);
  if (pair == NULL) {
    FATAL("Script detected too late during DWARF generation: %s",
          script.ToCString());
  }
  return pair->index_;
}

void Dwarf::WriteAbbreviations(DwarfWriteStream* stream) {
  // Dwarf data mostly takes the form of a tree, whose nodes are called
  // DIEs. Each DIE begins with an abbreviation code, and the abbreviation
  // describes the attributes of that DIE and their representation.

  stream->uleb128(kCompilationUnit);     // Abbrev code.
  stream->uleb128(DW_TAG_compile_unit);  // Type.
  stream->u1(DW_CHILDREN_yes);
  stream->uleb128(DW_AT_name);  // Start of attributes.
  stream->uleb128(DW_FORM_string);
  stream->uleb128(DW_AT_producer);
  stream->uleb128(DW_FORM_string);
  stream->uleb128(DW_AT_comp_dir);
  stream->uleb128(DW_FORM_string);
  stream->uleb128(DW_AT_low_pc);
  stream->uleb128(DW_FORM_addr);
  stream->uleb128(DW_AT_high_pc);
  stream->uleb128(DW_FORM_addr);
  stream->uleb128(DW_AT_stmt_list);
  stream->uleb128(DW_FORM_sec_offset);
  stream->uleb128(0);
  stream->uleb128(0);  // End of attributes.

  stream->uleb128(kAbstractFunction);  // Abbrev code.
  stream->uleb128(DW_TAG_subprogram);  // Type.
  stream->u1(DW_CHILDREN_yes);
  stream->uleb128(DW_AT_name);  // Start of attributes.
  stream->uleb128(DW_FORM_string);
  stream->uleb128(DW_AT_decl_file);
  stream->uleb128(DW_FORM_udata);
  stream->uleb128(DW_AT_inline);
  stream->uleb128(DW_FORM_udata);
  stream->uleb128(0);
  stream->uleb128(0);  // End of attributes.

  stream->uleb128(kConcreteFunction);  // Abbrev code.
  stream->uleb128(DW_TAG_subprogram);  // Type.
  stream->u1(DW_CHILDREN_yes);
  stream->uleb128(DW_AT_abstract_origin);  // Start of attributes.
  stream->uleb128(DW_FORM_ref4);
  stream->uleb128(DW_AT_low_pc);
  stream->uleb128(DW_FORM_addr);
  stream->uleb128(DW_AT_high_pc);
  stream->uleb128(DW_FORM_addr);
  stream->uleb128(DW_AT_artificial);
  stream->uleb128(DW_FORM_flag);
  stream->uleb128(0);
  stream->uleb128(0);  // End of attributes.

  stream->uleb128(kInlinedFunction);           // Abbrev code.
  stream->uleb128(DW_TAG_inlined_subroutine);  // Type.
  stream->u1(DW_CHILDREN_yes);
  stream->uleb128(DW_AT_abstract_origin);  // Start of attributes.
  stream->uleb128(DW_FORM_ref4);
  stream->uleb128(DW_AT_low_pc);
  stream->uleb128(DW_FORM_addr);
  stream->uleb128(DW_AT_high_pc);
  stream->uleb128(DW_FORM_addr);
  stream->uleb128(DW_AT_call_file);
  stream->uleb128(DW_FORM_udata);
  stream->uleb128(DW_AT_call_line);
  stream->uleb128(DW_FORM_udata);
  stream->uleb128(DW_AT_call_column);
  stream->uleb128(DW_FORM_udata);
  stream->uleb128(0);
  stream->uleb128(0);  // End of attributes.

  stream->uleb128(0);  // End of abbreviations.
}

void Dwarf::WriteDebugInfo(DwarfWriteStream* stream) {
  // 7.5.1.1 Compilation Unit Header

  // Unit length.
  stream->WritePrefixedLength("cu", [&]() {
    stream->u2(2);                            // DWARF version 2
    stream->u4(0);                            // debug_abbrev_offset
    stream->u1(compiler::target::kWordSize);  // address_size

    // Compilation Unit DIE. We describe the entire Dart program as a single
    // compilation unit. Note we write attributes in the same order we declared
    // them in our abbreviation above in WriteAbbreviations.
    stream->uleb128(kCompilationUnit);
    const Library& root_library = Library::Handle(
        zone_, IsolateGroup::Current()->object_store()->root_library());
    const String& root_uri = String::Handle(zone_, root_library.url());
    stream->string(root_uri.ToCString());  // DW_AT_name
    stream->string("Dart VM");             // DW_AT_producer
    stream->string("");                    // DW_AT_comp_dir

    // DW_AT_low_pc
    // The lowest instruction address in this object file that is part of our
    // compilation unit. Dwarf consumers use this to quickly decide which
    // compilation unit DIE to consult for a given pc.
    auto const isolate_instructions_label = ImageWriter::SectionLabel(
        ImageWriter::ProgramSection::Text, /*vm=*/false);
    stream->OffsetFromSymbol(isolate_instructions_label, 0);

    // DW_AT_high_pc
    // The highest instruction address in this object file that is part of our
    // compilation unit. Dwarf consumers use this to quickly decide which
    // compilation unit DIE to consult for a given pc.
    if (codes_.is_empty()) {
      // No code objects in this program, so set high_pc to same as low_pc.
      stream->OffsetFromSymbol(isolate_instructions_label, 0);
    } else {
      const Code& last_code = *codes_.Last();
      auto const last_code_label = code_to_label_.LookupValue(&last_code);
      ASSERT(last_code_label > 0);
      stream->OffsetFromSymbol(last_code_label, last_code.Size());
    }

    // DW_AT_stmt_list (offset into .debug_line)
    // Indicates which line number program is associated with this compilation
    // unit. We only emit a single line number program.
    stream->u4(0);

    WriteAbstractFunctions(stream);
    WriteConcreteFunctions(stream);

    stream->uleb128(0);  // End of children.

    stream->uleb128(0);  // End of entries.
  });
}

void Dwarf::WriteAbstractFunctions(DwarfWriteStream* stream) {
  Script& script = Script::Handle(zone_);
  String& name = String::Handle(zone_);
  stream->InitializeAbstractOrigins(functions_.length());
  // By the point we're creating DWARF information, scripts have already lost
  // their token stream and we can't look up their line number or column
  // information, hence the lack of DW_AT_decl_line and DW_AT_decl_column.
  for (intptr_t i = 0; i < functions_.length(); i++) {
    const Function& function = *(functions_[i]);
    name = function.QualifiedUserVisibleName();
    script = function.script();
    const intptr_t file = LookupScript(script);
    auto const name_cstr = Deobfuscate(name.ToCString());

    stream->RegisterAbstractOrigin(i);
    stream->uleb128(kAbstractFunction);
    stream->string(name_cstr);        // DW_AT_name
    stream->uleb128(file);            // DW_AT_decl_file
    stream->uleb128(DW_INL_inlined);  // DW_AT_inline
    stream->uleb128(0);               // End of children.
  }
}

void Dwarf::WriteConcreteFunctions(DwarfWriteStream* stream) {
  Function& function = Function::Handle(zone_);
  Script& script = Script::Handle(zone_);
  for (intptr_t i = 0; i < codes_.length(); i++) {
    const Code& code = *(codes_[i]);
    RELEASE_ASSERT(!code.IsNull());
    if (!code.IsFunctionCode() || code.IsUnknownDartCode()) {
      continue;
    }

    function = code.function();
    intptr_t function_index = LookupFunction(function);
    script = function.script();
    intptr_t label = code_to_label_.LookupValue(&code);
    ASSERT(label > 0);

    stream->uleb128(kConcreteFunction);
    // DW_AT_abstract_origin
    // References a node written above in WriteAbstractFunctions.
    stream->AbstractOrigin(function_index);

    // DW_AT_low_pc
    stream->OffsetFromSymbol(label, 0);
    // DW_AT_high_pc
    stream->OffsetFromSymbol(label, code.Size());
    // DW_AT_artificial
    stream->u1(function.is_visible() ? 0 : 1);

    InliningNode* node = ExpandInliningTree(code);
    if (node != NULL) {
      for (InliningNode* child = node->children_head; child != NULL;
           child = child->children_next) {
        WriteInliningNode(stream, child, label, script);
      }
    }

    stream->uleb128(0);  // End of children.
  }
}

// Our state machine encodes position metadata such that we don't know the
// end pc for an inlined function until it is popped, but DWARF DIEs encode
// it where the function is pushed. We expand the state transitions into
// an in-memory tree to do the conversion.
InliningNode* Dwarf::ExpandInliningTree(const Code& code) {
  const CodeSourceMap& map =
      CodeSourceMap::Handle(zone_, code.code_source_map());
  if (map.IsNull()) {
    return NULL;
  }
  const Array& functions = Array::Handle(zone_, code.inlined_id_to_function());
  const Function& root_function = Function::ZoneHandle(zone_, code.function());
  if (root_function.IsNull()) {
    FATAL("Wherefore art thou functionless code, %s?\n", code.ToCString());
  }

  GrowableArray<InliningNode*> node_stack(zone_, 4);
  GrowableArray<DwarfPosition> token_positions(zone_, 4);

  NoSafepointScope no_safepoint;
  ReadStream stream(map.Data(), map.Length());

  int32_t current_pc_offset = 0;
  token_positions.Add(kNoDwarfPositionInfo);
  InliningNode* root_node =
      new (zone_) InliningNode(root_function, token_positions.Last(), 0);
  root_node->end_pc_offset = code.Size();
  node_stack.Add(root_node);

  while (stream.PendingBytes() > 0) {
    int32_t arg1;
    int32_t arg2 = -1;
    const uint8_t opcode = CodeSourceMapOps::Read(&stream, &arg1, &arg2);
    switch (opcode) {
      case CodeSourceMapOps::kChangePosition: {
        DwarfPosition& pos = token_positions[token_positions.length() - 1];
        pos.ChangePosition(arg1, arg2);
        break;
      }
      case CodeSourceMapOps::kAdvancePC: {
        current_pc_offset += arg1;
        break;
      }
      case CodeSourceMapOps::kPushFunction: {
        const Function& child_func =
            Function::ZoneHandle(zone_, Function::RawCast(functions.At(arg1)));
        InliningNode* child_node = new (zone_)
            InliningNode(child_func, token_positions.Last(), current_pc_offset);
        node_stack.Last()->AppendChild(child_node);
        node_stack.Add(child_node);
        token_positions.Add(kNoDwarfPositionInfo);
        break;
      }
      case CodeSourceMapOps::kPopFunction: {
        // We never pop the root function.
        ASSERT(node_stack.length() > 1);
        ASSERT(token_positions.length() > 1);
        node_stack.Last()->end_pc_offset = current_pc_offset;
        node_stack.RemoveLast();
        token_positions.RemoveLast();
        break;
      }
      case CodeSourceMapOps::kNullCheck: {
        break;
      }
      default:
        UNREACHABLE();
    }
  }

  while (node_stack.length() > 1) {
    node_stack.Last()->end_pc_offset = current_pc_offset;
    node_stack.RemoveLast();
    token_positions.RemoveLast();
  }
  ASSERT(node_stack[0] == root_node);
  return root_node;
}

void Dwarf::WriteInliningNode(DwarfWriteStream* stream,
                              InliningNode* node,
                              intptr_t root_label,
                              const Script& parent_script) {
  ASSERT(root_label > 0);
  intptr_t file = LookupScript(parent_script);
  intptr_t function_index = LookupFunction(node->function);
  const Script& script = Script::Handle(zone_, node->function.script());

  stream->uleb128(kInlinedFunction);
  // DW_AT_abstract_origin
  // References a node written above in WriteAbstractFunctions.
  stream->AbstractOrigin(function_index);

  // DW_AT_low_pc
  stream->OffsetFromSymbol(root_label, node->start_pc_offset);
  // DW_AT_high_pc
  stream->OffsetFromSymbol(root_label, node->end_pc_offset);
  // DW_AT_call_file
  stream->uleb128(file);

  // DW_AT_call_line
  stream->uleb128(node->position.line());
  // DW_at_call_column
  stream->uleb128(node->position.column());

  for (InliningNode* child = node->children_head; child != NULL;
       child = child->children_next) {
    WriteInliningNode(stream, child, root_label, script);
  }

  stream->uleb128(0);  // End of children.
}

// Helper class for tracking state of DWARF registers and emitting
// line number program commands to set these registers to the right
// state.
class LineNumberProgramWriter {
 public:
  explicit LineNumberProgramWriter(DwarfWriteStream* stream)
      : stream_(stream) {}

  void EmitRow(intptr_t file,
               intptr_t line,
               intptr_t column,
               intptr_t label,
               intptr_t pc_offset) {
    if (AddRow(file, line, column, label, pc_offset)) {
      // Address register must be updated from 0 before emitting an LNP row
      // (dartbug.com/41756).
      stream_->u1(Dwarf::DW_LNS_copy);
    }
  }

  // Associates the given file, line, and column information for the instruction
  // at the pc_offset into the instructions payload of the Code object with the
  // symbol asm_name. Returns whether any changes were made to the stream.
  DART_WARN_UNUSED_RESULT bool AddRow(intptr_t file,
                                      intptr_t line,
                                      intptr_t column,
                                      intptr_t label,
                                      intptr_t pc_offset) {
    ASSERT_EQUAL(end_sequence_, false);
    bool source_info_changed = false;
    // Note that files are 1-indexed.
    ASSERT(file >= 1);
    if (file != file_) {
      stream_->u1(Dwarf::DW_LNS_set_file);
      stream_->uleb128(file);
      file_ = file;
      source_info_changed = true;
    }
    ASSERT(line >= DwarfPosition::kNoLine);
    if (line != line_) {
      stream_->u1(Dwarf::DW_LNS_advance_line);
      stream_->sleb128(line - line_);
      line_ = line;
      source_info_changed = true;
    }
    ASSERT(column >= DwarfPosition::kNoColumn);
    if (column != column_) {
      stream_->u1(Dwarf::DW_LNS_set_column);
      stream_->uleb128(column);
      column_ = column;
      source_info_changed = true;
    }
    // If the file, line, and column information match that for the previous
    // AddRow call, no change is made to the stream. This is because all
    // addresses between two line number program rows inherit the source
    // information from the first.
    if (source_info_changed) {
      SetCurrentPosition(label, pc_offset);
    }
    return source_info_changed;
  }

  void MarkEnd() {
    ASSERT_EQUAL(end_sequence_, false);
    // End of contiguous machine code.
    stream_->u1(0);  // This is an extended opcode
    stream_->u1(1);  // that is 1 byte long
    stream_->u1(Dwarf::DW_LNE_end_sequence);
    end_sequence_ = true;
  }

  void MarkEnd(intptr_t label, intptr_t pc_offset) {
    ASSERT_EQUAL(end_sequence_, false);
    SetCurrentPosition(label, pc_offset);
    MarkEnd();
  }

 private:
  void SetCurrentPosition(intptr_t label, intptr_t pc_offset) {
    // Each LNP row is either in a different function from the previous row
    // or is at an increasing PC offset into the same function.
    ASSERT(label > 0);
    ASSERT(pc_offset >= 0);
    ASSERT(label_ != label || pc_offset > pc_offset_);
    if (label_ != label) {
      // Set the address register to the given offset into the new code payload.
      auto const instr_size = 1 + compiler::target::kWordSize;
      stream_->u1(0);           // This is an extended opcode
      stream_->u1(instr_size);  // that is 5 or 9 bytes long
      stream_->u1(Dwarf::DW_LNE_set_address);
      stream_->OffsetFromSymbol(label, pc_offset);
    } else {
      // Change the address register by the difference in the two offsets.
      stream_->u1(Dwarf::DW_LNS_advance_pc);
      stream_->uleb128(pc_offset - pc_offset_);
    }
    label_ = label;
    pc_offset_ = pc_offset;
  }

  DwarfWriteStream* const stream_;
  // The initial values for the line number program state machine registers
  // according to the DWARF standard.
  intptr_t pc_offset_ = 0;
  intptr_t file_ = 1;
  intptr_t line_ = 1;
  intptr_t column_ = 0;
  intptr_t end_sequence_ = false;

  // Other info not stored in the state machine registers.
  intptr_t label_ = 0;
};

void Dwarf::WriteSyntheticLineNumberProgram(LineNumberProgramWriter* writer) {
  // We emit it last after all other scripts.
  const intptr_t comments_file_index = scripts_.length() + 1;

  auto file_open = Dart::file_open_callback();
  auto file_write = Dart::file_write_callback();
  auto file_close = Dart::file_close_callback();
  if ((file_open == nullptr) || (file_write == nullptr) ||
      (file_close == nullptr)) {
    OS::PrintErr("warning: Could not access file callbacks.");
    return;
  }

  TextBuffer comments_buffer(128 * KB);

  const char* filename = FLAG_write_code_comments_as_synthetic_source_to;
  void* comments_file = file_open(filename, /*write=*/true);
  if (comments_file == nullptr) {
    OS::PrintErr("warning: Failed to write code comments source: %s\n",
                 filename);
    return;
  }

  // Lines in DWARF are 1-indexed.
  intptr_t current_line = 1;

  for (intptr_t i = 0; i < codes_.length(); i++) {
    const Code& code = *(codes_[i]);
    auto const label = code_to_label_.LookupValue(&code);
    ASSERT(label > 0);

    auto& comments = code.comments();
    for (intptr_t i = 0, len = comments.Length(); i < len;) {
      intptr_t current_pc_offset = comments.PCOffsetAt(i);
      writer->EmitRow(comments_file_index, current_line,
                      DwarfPosition::kNoColumn, label, current_pc_offset);
      while (i < len && current_pc_offset == comments.PCOffsetAt(i)) {
        comments_buffer.AddString(comments.CommentAt(i));
        comments_buffer.AddChar('\n');
        current_line++;
        i++;
      }
    }
  }

  file_write(comments_buffer.buffer(), comments_buffer.length(), comments_file);
  file_close(comments_file);
}

void Dwarf::WriteLineNumberProgramFromCodeSourceMaps(
    LineNumberProgramWriter* writer) {
  Function& root_function = Function::Handle(zone_);
  Script& script = Script::Handle(zone_);
  CodeSourceMap& map = CodeSourceMap::Handle(zone_);
  Array& functions = Array::Handle(zone_);
  GrowableArray<const Function*> function_stack(zone_, 8);
  GrowableArray<DwarfPosition> token_positions(zone_, 8);

  for (intptr_t i = 0; i < codes_.length(); i++) {
    const Code& code = *(codes_[i]);
    auto const label = code_to_label_.LookupValue(&code);
    ASSERT(label > 0);

    map = code.code_source_map();
    if (map.IsNull()) {
      continue;
    }
    root_function = code.function();
    functions = code.inlined_id_to_function();

    NoSafepointScope no_safepoint;
    ReadStream code_map_stream(map.Data(), map.Length());

    function_stack.Clear();
    token_positions.Clear();

    // CodeSourceMap might start in the following way:
    //
    //   ChangePosition function.token_pos()
    //   AdvancePC 0
    //   ChangePosition x
    //   AdvancePC y
    //
    // This entry is emitted to ensure correct symbolization of
    // function listener frames produced by async unwinding.
    // (See EmitFunctionEntrySourcePositionDescriptorIfNeeded).
    // Directly interpreting this sequence would cause us to emit
    // multiple with the same pc into line number table and different
    // position information. To avoid this will make an adjustment for
    // the second record we emit: if position x is a synthetic one we will
    // simply drop the second record, if position x is real then we will
    // emit row with a slightly adjusted PC (by 1 byte). This would not
    // affect symbolization (you can't have a call that is 1 byte long)
    // but will avoid line number table entries with the same PC.
    bool function_entry_position_was_emitted = false;

    int32_t current_pc_offset = 0;
    function_stack.Add(&root_function);
    token_positions.Add(kNoDwarfPositionInfo);

    while (code_map_stream.PendingBytes() > 0) {
      int32_t arg1;
      int32_t arg2 = -1;
      const uint8_t opcode =
          CodeSourceMapOps::Read(&code_map_stream, &arg1, &arg2);
      switch (opcode) {
        case CodeSourceMapOps::kChangePosition: {
          DwarfPosition& pos = token_positions[token_positions.length() - 1];
          pos.ChangePosition(arg1, arg2);
          break;
        }
        case CodeSourceMapOps::kAdvancePC: {
          // Emit a row for the previous PC value if the source location
          // changed since the last row was emitted.
          const Function& function = *(function_stack.Last());
          script = function.script();
          const intptr_t file = LookupScript(script);
          const intptr_t line = token_positions.Last().line();
          const intptr_t column = token_positions.Last().column();
          intptr_t pc_offset_adjustment = 0;
          bool should_emit = true;

          // If we are at the function entry and have already emitted a row
          // then adjust current_pc_offset to avoid duplicated entries.
          // See the comment below which explains why this code is here.
          if (current_pc_offset == 0 && function_entry_position_was_emitted) {
            pc_offset_adjustment = 1;
            // Ignore synthetic positions. Function entry position gives
            // more information anyway.
            should_emit = !(line == 0 && column == 0);
          }

          if (should_emit) {
            writer->EmitRow(file, line, column, label,
                            current_pc_offset + pc_offset_adjustment);
          }

          current_pc_offset += arg1;
          if (arg1 == 0) {  // Special case of AdvancePC 0.
            ASSERT(current_pc_offset == 0);
            ASSERT(!function_entry_position_was_emitted);
            function_entry_position_was_emitted = true;
          }
          break;
        }
        case CodeSourceMapOps::kPushFunction: {
          auto child_func =
              &Function::Handle(zone_, Function::RawCast(functions.At(arg1)));
          function_stack.Add(child_func);
          token_positions.Add(kNoDwarfPositionInfo);
          break;
        }
        case CodeSourceMapOps::kPopFunction: {
          // We never pop the root function.
          ASSERT(function_stack.length() > 1);
          ASSERT(token_positions.length() > 1);
          function_stack.RemoveLast();
          token_positions.RemoveLast();
          break;
        }
        case CodeSourceMapOps::kNullCheck: {
          break;
        }
        default:
          UNREACHABLE();
      }
    }
  }
}

static constexpr char kResolvedFileRoot[] = "file:///";
static constexpr intptr_t kResolvedFileRootLen = sizeof(kResolvedFileRoot) - 1;
static constexpr char kResolvedFlutterRoot[] = "org-dartlang-sdk:///flutter/";
static constexpr intptr_t kResolvedFlutterRootLen =
    sizeof(kResolvedFlutterRoot) - 1;
static constexpr char kResolvedSdkRoot[] = "org-dartlang-sdk:///";
static constexpr intptr_t kResolvedSdkRootLen = sizeof(kResolvedSdkRoot) - 1;
static constexpr char kResolvedGoogle3Root[] = "google3:///";
static constexpr intptr_t kResolvedGoogle3RootLen =
    sizeof(kResolvedGoogle3Root) - 1;

static const char* ConvertResolvedURI(const char* str) {
  const intptr_t len = strlen(str);
  if (len > kResolvedFileRootLen &&
      strncmp(str, kResolvedFileRoot, kResolvedFileRootLen) == 0) {
#if defined(DART_HOST_OS_WINDOWS)
    return str + kResolvedFileRootLen;  // Strip off the entire prefix.
#else
    return str + kResolvedFileRootLen - 1;  // Leave a '/' on the front.
#endif
  }
  // Must do kResolvedFlutterRoot before kResolvedSdkRoot, since the latter is
  // a prefix of the former.
  if (len > kResolvedFlutterRootLen &&
      strncmp(str, kResolvedFlutterRoot, kResolvedFlutterRootLen) == 0) {
    return str + kResolvedFlutterRootLen;  // Strip off the entire prefix.
  }
  if (len > kResolvedSdkRootLen &&
      strncmp(str, kResolvedSdkRoot, kResolvedSdkRootLen) == 0) {
    return str + kResolvedSdkRootLen;  // Strip off the entire prefix.
  }
  if (len > kResolvedGoogle3RootLen &&
      strncmp(str, kResolvedGoogle3Root, kResolvedGoogle3RootLen) == 0) {
    return str + kResolvedGoogle3RootLen;  // Strip off the entire prefix.
  }
  return nullptr;
}

void Dwarf::WriteLineNumberProgram(DwarfWriteStream* stream) {
  // 6.2.4 The Line Number Program Header

  // 1. unit_length. This encoding implies 32-bit DWARF.
  stream->WritePrefixedLength("line", [&]() {
    stream->u2(2);  // 2. DWARF version 2

    // 3. header_length
    stream->WritePrefixedLength("lineheader", [&]() {
      stream->u1(1);   // 4. minimum_instruction_length
      stream->u1(1);   // 5. default_is_stmt (true for dsymutil compatibility).
      stream->u1(0);   // 6. line_base
      stream->u1(1);   // 7. line_range
      stream->u1(13);  // 8. opcode_base (12 standard opcodes in Dwarf 2)

      // 9. standard_opcode_lengths
      stream->u1(0);  // DW_LNS_copy, 0 operands
      stream->u1(1);  // DW_LNS_advance_pc, 1 operands
      stream->u1(1);  // DW_LNS_advance_list, 1 operands
      stream->u1(1);  // DW_LNS_set_file, 1 operands
      stream->u1(1);  // DW_LNS_set_column, 1 operands
      stream->u1(0);  // DW_LNS_negate_stmt, 0 operands
      stream->u1(0);  // DW_LNS_set_basic_block, 0 operands
      stream->u1(0);  // DW_LNS_const_add_pc, 0 operands
      stream->u1(1);  // DW_LNS_fixed_advance_pc, 1 operands
      stream->u1(0);  // DW_LNS_set_prolog_end, 0 operands
      stream->u1(0);  // DW_LNS_set_epilogue_begin, 0 operands
      stream->u1(1);  // DW_LNS_set_isa, 1 operands

      // 10. include_directories (sequence of path names)
      // We don't emit any because we use full paths below.
      stream->u1(0);

      // 11. file_names (sequence of file entries)
      String& uri = String::Handle(zone_);
      for (intptr_t i = 0; i < scripts_.length(); i++) {
        const Script& script = *(scripts_[i]);
        const char* uri_cstr = nullptr;
        if (FLAG_resolve_dwarf_paths) {
          uri = script.resolved_url();
          // Strictly enforce this to catch unresolvable cases.
          if (uri.IsNull()) {
            FATAL("no resolved URI for Script %s available",
                  script.ToCString());
          }
          // resolved_url is never obfuscated, so just convert the prefix.
          auto const orig_cstr = uri.ToCString();
          auto const converted_cstr = ConvertResolvedURI(orig_cstr);
          // Strictly enforce this to catch inconvertible cases.
          if (converted_cstr == nullptr) {
            FATAL("cannot convert resolved URI %s", orig_cstr);
          }
          uri_cstr = converted_cstr;
        } else {
          uri = script.url();
          ASSERT(!uri.IsNull());
          uri_cstr = Deobfuscate(uri.ToCString());
        }
        RELEASE_ASSERT(strlen(uri_cstr) != 0);

        stream->string(uri_cstr);  // NOLINT
        stream->uleb128(0);        // Include directory index.
        stream->uleb128(0);        // File modification time.
        stream->uleb128(0);        // File length.
      }
      if (FLAG_write_code_comments_as_synthetic_source_to != nullptr) {
        stream->string(  // NOLINT
            FLAG_write_code_comments_as_synthetic_source_to);
        stream->uleb128(0);  // Include directory index.
        stream->uleb128(0);  // File modification time.
        stream->uleb128(0);  // File length.
      }
      stream->u1(0);  // End of file names.
    });

    // 6.2.5 The Line Number Program
    LineNumberProgramWriter lnp_writer(stream);
    if (FLAG_write_code_comments_as_synthetic_source_to != nullptr) {
      WriteSyntheticLineNumberProgram(&lnp_writer);
    } else {
      WriteLineNumberProgramFromCodeSourceMaps(&lnp_writer);
    }

    // Advance pc to end of the compilation unit if not already there.
    if (codes_.length() != 0) {
      const intptr_t last_code_index = codes_.length() - 1;
      const Code& last_code = *(codes_[last_code_index]);
      const intptr_t last_pc_offset = last_code.Size();
      auto const last_label = code_to_label_.LookupValue(&last_code);
      ASSERT(last_label > 0);
      lnp_writer.MarkEnd(last_label, last_pc_offset);
    } else {
      lnp_writer.MarkEnd();
    }
  });
}

const char* Dwarf::Deobfuscate(const char* cstr) {
  if (reverse_obfuscation_trie_ == nullptr) return cstr;
  TextBuffer buffer(256);
  // Used to avoid Zone-allocating strings if no deobfuscation was performed.
  bool changed = false;
  intptr_t i = 0;
  while (cstr[i] != '\0') {
    intptr_t offset;
    auto const value = reverse_obfuscation_trie_->Lookup(cstr + i, &offset);
    if (offset == 0) {
      // The first character was an invalid key element (that isn't the null
      // terminator due to the while condition), copy it and skip to the next.
      buffer.AddChar(cstr[i++]);
    } else if (value != nullptr) {
      changed = true;
      buffer.AddString(value);
    } else {
      buffer.AddRaw(reinterpret_cast<const uint8_t*>(cstr + i), offset);
    }
    i += offset;
  }
  if (!changed) return cstr;
  return OS::SCreate(zone_, "%s", buffer.buffer());
}

Trie<const char>* Dwarf::CreateReverseObfuscationTrie(Zone* zone) {
  auto const map_array = IsolateGroup::Current()->obfuscation_map();
  if (map_array == nullptr) return nullptr;

  Trie<const char>* trie = nullptr;
  for (intptr_t i = 0; map_array[i] != nullptr; i += 2) {
    auto const key = map_array[i];
    auto const value = map_array[i + 1];
    ASSERT(value != nullptr);
    // Don't include identity mappings.
    if (strcmp(key, value) == 0) continue;
    // Otherwise, any value in the obfuscation map should be a valid key.
    ASSERT(Trie<const char>::IsValidKey(value));
    trie = Trie<const char>::AddString(zone, trie, value, key);
  }
  return trie;
}

#endif  // DART_PRECOMPILER

}  // namespace dart
