// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dwarf.h"

#include "vm/code_descriptors.h"
#include "vm/object_store.h"

namespace dart {

#ifdef DART_PRECOMPILER

#if defined(ARCH_IS_32_BIT)
#define FORM_ADDR ".4byte"
#elif defined(ARCH_IS_64_BIT)
#define FORM_ADDR ".8byte"
#endif

class InliningNode : public ZoneAllocated {
 public:
  InliningNode(const Function& function,
               TokenPosition call_pos,
               int32_t start_pc_offset)
      : function(function),
        call_pos(call_pos),
        start_pc_offset(start_pc_offset),
        end_pc_offset(-1),
        children_head(NULL),
        children_tail(NULL),
        children_next(NULL) {}

  void AppendChild(InliningNode* child) {
    if (children_tail == NULL) {
      children_head = children_tail = child;
    } else {
      children_tail->children_next = child;
      children_tail = child;
    }
  }

  const Function& function;
  TokenPosition call_pos;
  int32_t start_pc_offset;
  int32_t end_pc_offset;
  InliningNode* children_head;
  InliningNode* children_tail;
  InliningNode* children_next;
};

Dwarf::Dwarf(Zone* zone, WriteStream* stream)
    : zone_(zone),
      stream_(stream),
      codes_(zone, 1024),
      code_to_index_(zone),
      functions_(zone, 1024),
      function_to_index_(zone),
      scripts_(zone, 1024),
      script_to_index_(zone),
      temp_(0) {}

intptr_t Dwarf::AddCode(const Code& code) {
  ASSERT(!code.IsNull());
  CodeIndexPair* pair = code_to_index_.Lookup(&code);
  if (pair != NULL) {
    return pair->index_;
  }
  intptr_t index = codes_.length();
  const Code& zone_code = Code::ZoneHandle(zone_, code.raw());
  code_to_index_.Insert(CodeIndexPair(&zone_code, index));
  codes_.Add(&zone_code);
  if (code.IsFunctionCode()) {
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
  return index;
}

intptr_t Dwarf::AddFunction(const Function& function) {
  ASSERT(!function.IsNull());
  FunctionIndexPair* pair = function_to_index_.Lookup(&function);
  if (pair != NULL) {
    return pair->index_;
  }
  intptr_t index = functions_.length();
  const Function& zone_func = Function::ZoneHandle(zone_, function.raw());
  function_to_index_.Insert(FunctionIndexPair(&zone_func, index));
  functions_.Add(&zone_func);
  const Script& script = Script::Handle(zone_, function.script());
  AddScript(script);
  return index;
}

intptr_t Dwarf::AddScript(const Script& script) {
  ASSERT(!script.IsNull());
  ScriptIndexPair* pair = script_to_index_.Lookup(&script);
  if (pair != NULL) {
    return pair->index_;
  }
  // DWARF file numbers start from 1.
  intptr_t index = scripts_.length() + 1;
  const Script& zone_script = Script::ZoneHandle(zone_, script.raw());
  script_to_index_.Insert(ScriptIndexPair(&zone_script, index));
  scripts_.Add(&zone_script);
  return index;
}

intptr_t Dwarf::LookupFunction(const Function& function) {
  ASSERT(!function.IsNull());
  FunctionIndexPair* pair = function_to_index_.Lookup(&function);
  if (pair == NULL) {
    FATAL1("Function detected too late during DWARF generation: %s",
           function.ToCString());
  }
  return pair->index_;
}

intptr_t Dwarf::LookupScript(const Script& script) {
  ASSERT(!script.IsNull());
  ScriptIndexPair* pair = script_to_index_.Lookup(&script);
  if (pair == NULL) {
    FATAL1("Script detected too late during DWARF generation: %s",
           script.ToCString());
  }
  return pair->index_;
}

void Dwarf::Print(const char* format, ...) {
  va_list args;
  va_start(args, format);
  stream_->VPrint(format, args);
  va_end(args);
}

void Dwarf::WriteAbbreviations() {
// Dwarf data mostly takes the form of a tree, whose nodes are called
// DIEs. Each DIE begins with an abbreviation code, and the abbreviation
// describes the attributes of that DIE and their representation.

#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
  Print(".section __DWARF,__debug_abbrev,regular,debug\n");
#elif defined(TARGET_OS_LINUX) || defined(TARGET_OS_ANDROID) ||                \
    defined(TARGET_OS_FUCHSIA)
  Print(".section .debug_abbrev,\"\"\n");
#else
  UNIMPLEMENTED();
#endif

  uleb128(kCompilationUnit);     // Abbrev code.
  uleb128(DW_TAG_compile_unit);  // Type.
  u1(DW_CHILDREN_yes);
  uleb128(DW_AT_name);  // Start of attributes.
  uleb128(DW_FORM_string);
  uleb128(DW_AT_producer);
  uleb128(DW_FORM_string);
  uleb128(DW_AT_comp_dir);
  uleb128(DW_FORM_string);
  uleb128(DW_AT_low_pc);
  uleb128(DW_FORM_addr);
  uleb128(DW_AT_high_pc);
  uleb128(DW_FORM_addr);
  uleb128(DW_AT_stmt_list);
  uleb128(DW_FORM_sec_offset);
  uleb128(0);
  uleb128(0);  // End of attributes.

  uleb128(kAbstractFunction);  // Abbrev code.
  uleb128(DW_TAG_subprogram);  // Type.
  u1(DW_CHILDREN_yes);
  uleb128(DW_AT_name);  // Start of attributes.
  uleb128(DW_FORM_string);
  uleb128(DW_AT_decl_file);
  uleb128(DW_FORM_udata);
  uleb128(DW_AT_decl_line);
  uleb128(DW_FORM_udata);
  uleb128(DW_AT_inline);
  uleb128(DW_FORM_udata);
  uleb128(0);
  uleb128(0);  // End of attributes.

  uleb128(kConcreteFunction);  // Abbrev code.
  uleb128(DW_TAG_subprogram);  // Type.
  u1(DW_CHILDREN_yes);
  uleb128(DW_AT_abstract_origin);  // Start of attributes.
  uleb128(DW_FORM_ref4);
  uleb128(DW_AT_low_pc);
  uleb128(DW_FORM_addr);
  uleb128(DW_AT_high_pc);
  uleb128(DW_FORM_addr);
  uleb128(0);
  uleb128(0);  // End of attributes.

  uleb128(kInlinedFunction);           // Abbrev code.
  uleb128(DW_TAG_inlined_subroutine);  // Type.
  u1(DW_CHILDREN_yes);
  uleb128(DW_AT_abstract_origin);  // Start of attributes.
  uleb128(DW_FORM_ref4);
  uleb128(DW_AT_low_pc);
  uleb128(DW_FORM_addr);
  uleb128(DW_AT_high_pc);
  uleb128(DW_FORM_addr);
  uleb128(DW_AT_call_file);
  uleb128(DW_FORM_udata);
  uleb128(DW_AT_call_line);
  uleb128(DW_FORM_udata);
  uleb128(0);
  uleb128(0);  // End of attributes.

  uleb128(0);  // End of abbreviations.
}

void Dwarf::WriteCompilationUnit() {
// 7.5.1.1 Compilation Unit Header

#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
  Print(".section __DWARF,__debug_info,regular,debug\n");
#elif defined(TARGET_OS_LINUX) || defined(TARGET_OS_ANDROID) ||                \
    defined(TARGET_OS_FUCHSIA)
  Print(".section .debug_info,\"\"\n");
#else
  UNIMPLEMENTED();
#endif
  Print(".Ldebug_info:\n");

  // Unit length. Assignment to temp works around buggy Mac assembler.
  Print("Lcu_size = .Lcu_end - .Lcu_start\n");
  Print(".4byte Lcu_size\n");
  Print(".Lcu_start:\n");

  u2(2);              // DWARF version 2
  u4(0);              // debug_abbrev_offset
  u1(sizeof(void*));  // address_size

  // Compilation Unit DIE. We describe the entire Dart program as a single
  // compilation unit. Note we write attributes in the same order we declared
  // them in our abbreviation above in WriteAbbreviations.
  uleb128(kCompilationUnit);
  const Library& root_library = Library::Handle(
      zone_, Isolate::Current()->object_store()->root_library());
  const String& root_uri = String::Handle(zone_, root_library.url());
  Print(".string \"%s\"\n", root_uri.ToCString());  // DW_AT_name
  Print(".string \"Dart VM\"\n");                   // DW_AT_producer
  Print(".string \"\"\n");                          // DW_AT_comp_dir

  // DW_AT_low_pc
  // The lowest instruction address in this object file that is part of our
  // compilation unit. Dwarf consumers use this to quickly decide which
  // compilation unit DIE to consult for a given pc.
  Print(FORM_ADDR " _kDartIsolateSnapshotInstructions\n");

  // DW_AT_high_pc
  // The highest instruction address in this object file that is part of our
  // compilation unit. Dwarf consumers use this to quickly decide which
  // compilation unit DIE to consult for a given pc.
  intptr_t last_code_index = codes_.length() - 1;
  const Code& last_code = *(codes_[last_code_index]);
  Print(FORM_ADDR " .Lcode%" Pd " + %" Pd "\n", last_code_index,
        last_code.Size());

  // DW_AT_stmt_list (offset into .debug_line)
  // Indicates which line number program is associated with this compilation
  // unit. We only emit a single line number program.
  u4(0);

  WriteAbstractFunctions();
  WriteConcreteFunctions();

  uleb128(0);  // End of children.

  uleb128(0);  // End of entries.
  Print(".Lcu_end:\n");
}

void Dwarf::WriteAbstractFunctions() {
  Script& script = Script::Handle(zone_);
  String& name = String::Handle(zone_);
  for (intptr_t i = 0; i < functions_.length(); i++) {
    const Function& function = *(functions_[i]);
    name = function.QualifiedUserVisibleName();
    script = function.script();
    intptr_t file = LookupScript(script);
    intptr_t line = 0;  // Not known. Script has already lost its token stream.

    Print(".Lfunc%" Pd ":\n", i);  // Label for DW_AT_abstract_origin references
    uleb128(kAbstractFunction);
    Print(".string \"%s\"\n", name.ToCString());  // DW_AT_name
    uleb128(file);                                // DW_AT_decl_file
    uleb128(line);                                // DW_AT_decl_line
    uleb128(DW_INL_inlined);                      // DW_AT_inline
    uleb128(0);                                   // End of children.
  }
}

void Dwarf::WriteConcreteFunctions() {
  Function& function = Function::Handle(zone_);
  Script& script = Script::Handle(zone_);
  for (intptr_t i = 0; i < codes_.length(); i++) {
    const Code& code = *(codes_[i]);
    if (!code.IsFunctionCode()) {
      continue;
    }
    function = code.function();
    intptr_t function_index = LookupFunction(function);
    script = function.script();

    uleb128(kConcreteFunction);
    // DW_AT_abstract_origin
    // References a node written above in WriteAbstractFunctions.
    // Assignment to temp works around buggy Mac assembler.
    intptr_t temp = temp_++;
    Print("Ltemp%" Pd " = .Lfunc%" Pd " - .Ldebug_info\n", temp,
          function_index);
    Print(".4byte Ltemp%" Pd "\n", temp);

    // DW_AT_low_pc
    Print(FORM_ADDR " .Lcode%" Pd "\n", i);
    // DW_AT_high_pc
    Print(FORM_ADDR " .Lcode%" Pd " + %" Pd "\n", i, code.Size());

    InliningNode* node = ExpandInliningTree(code);
    if (node != NULL) {
      for (InliningNode* child = node->children_head; child != NULL;
           child = child->children_next) {
        WriteInliningNode(child, i, script);
      }
    }

    uleb128(0);  // End of children.
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
  const Function& root_function = Function::Handle(zone_, code.function());

  GrowableArray<InliningNode*> node_stack(zone_, 4);
  GrowableArray<TokenPosition> token_positions(zone_, 4);

  NoSafepointScope no_safepoint;
  ReadStream stream(map.Data(), map.Length());

  int32_t current_pc_offset = 0;
  InliningNode* root_node =
      new (zone_) InliningNode(root_function, TokenPosition(), 0);
  root_node->end_pc_offset = code.Size();
  node_stack.Add(root_node);
  token_positions.Add(CodeSourceMapBuilder::kInitialPosition);

  while (stream.PendingBytes() > 0) {
    uint8_t opcode = stream.Read<uint8_t>();
    switch (opcode) {
      case CodeSourceMapBuilder::kChangePosition: {
        int32_t position = stream.Read<int32_t>();
        token_positions[token_positions.length() - 1] = TokenPosition(position);
        break;
      }
      case CodeSourceMapBuilder::kAdvancePC: {
        int32_t delta = stream.Read<int32_t>();
        current_pc_offset += delta;
        break;
      }
      case CodeSourceMapBuilder::kPushFunction: {
        int32_t func = stream.Read<int32_t>();
        const Function& child_func =
            Function::Handle(zone_, Function::RawCast(functions.At(func)));
        TokenPosition call_pos = token_positions.Last();
        InliningNode* child_node =
            new (zone_) InliningNode(child_func, call_pos, current_pc_offset);
        node_stack.Last()->AppendChild(child_node);
        node_stack.Add(child_node);
        token_positions.Add(CodeSourceMapBuilder::kInitialPosition);
        break;
      }
      case CodeSourceMapBuilder::kPopFunction: {
        // We never pop the root function.
        ASSERT(node_stack.length() > 1);
        ASSERT(token_positions.length() > 1);
        node_stack.Last()->end_pc_offset = current_pc_offset;
        node_stack.RemoveLast();
        token_positions.RemoveLast();
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

void Dwarf::WriteInliningNode(InliningNode* node,
                              intptr_t root_code_index,
                              const Script& parent_script) {
  intptr_t file = LookupScript(parent_script);
  intptr_t line = node->call_pos.value();
  intptr_t function_index = LookupFunction(node->function);
  const Script& script = Script::Handle(zone_, node->function.script());

  uleb128(kInlinedFunction);
  // DW_AT_abstract_origin
  // References a node written above in WriteAbstractFunctions.
  // Assignment to temp works around buggy Mac assembler.
  intptr_t temp = temp_++;
  Print("Ltemp%" Pd " = .Lfunc%" Pd " - .Ldebug_info\n", temp, function_index);
  Print(".4byte Ltemp%" Pd "\n", temp);
  // DW_AT_low_pc
  Print(FORM_ADDR " .Lcode%" Pd " + %" Pd "\n", root_code_index,
        node->start_pc_offset);
  // DW_AT_high_pc
  Print(FORM_ADDR " .Lcode%" Pd " + %" Pd "\n", root_code_index,
        node->end_pc_offset);
  // DW_AT_call_file
  uleb128(file);
  // DW_AT_call_line
  uleb128(line);

  for (InliningNode* child = node->children_head; child != NULL;
       child = child->children_next) {
    WriteInliningNode(child, root_code_index, script);
  }

  uleb128(0);  // End of children.
}

void Dwarf::WriteLines() {
#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
  Print(".section __DWARF,__debug_line,regular,debug\n");
#elif defined(TARGET_OS_LINUX) || defined(TARGET_OS_ANDROID) ||                \
    defined(TARGET_OS_FUCHSIA)
  Print(".section .debug_line,\"\"\n");
#else
  UNIMPLEMENTED();
#endif

  // 6.2.4 The Line Number Program Header

  // 1. unit_length. This encoding implies 32-bit DWARF.
  Print("Lline_size = .Lline_end - .Lline_start\n");
  Print(".4byte Lline_size\n");

  Print(".Lline_start:\n");

  u2(2);  // 2. DWARF version 2

  // 3. header_length
  // Assignment to temp works around buggy Mac assembler.
  Print("Llineheader_size = .Llineheader_end - .Llineheader_start\n");
  Print(".4byte Llineheader_size\n");
  Print(".Llineheader_start:\n");

  u1(1);   // 4. minimum_instruction_length
  u1(0);   // 5. default_is_stmt
  u1(0);   // 6. line_base
  u1(1);   // 7. line_range
  u1(13);  // 8. opcode_base (12 standard opcodes in Dwarf 2)

  // 9. standard_opcode_lengths
  u1(0);  // DW_LNS_copy, 0 operands
  u1(1);  // DW_LNS_advance_pc, 1 operands
  u1(1);  // DW_LNS_advance_list, 1 operands
  u1(1);  // DW_LNS_set_file, 1 operands
  u1(1);  // DW_LNS_set_column, 1 operands
  u1(0);  // DW_LNS_negate_stmt, 0 operands
  u1(0);  // DW_LNS_set_basic_block, 0 operands
  u1(0);  // DW_LNS_const_add_pc, 0 operands
  u1(1);  // DW_LNS_fixed_advance_pc, 1 operands
  u1(0);  // DW_LNS_set_prolog_end, 0 operands
  u1(0);  // DW_LNS_set_epligoue_begin, 0 operands
  u1(1);  // DW_LNS_set_isa, 1 operands

  // 10. include_directories (sequence of path names)
  // We don't emit any because we use full paths below.
  u1(0);

  // 11. file_names (sequence of file entries)
  String& uri = String::Handle(zone_);
  for (intptr_t i = 0; i < scripts_.length(); i++) {
    const Script& script = *(scripts_[i]);
    uri ^= script.url();
    Print(".string \"%s\"\n", uri.ToCString());
    uleb128(0);  // Include directory index.
    uleb128(0);  // File modification time.
    uleb128(0);  // File length.
  }
  u1(0);  // End of file names.

  Print(".Llineheader_end:\n");

  // 6.2.5 The Line Number Program

  intptr_t previous_file = 1;
  intptr_t previous_line = 1;
  intptr_t previous_code_index = -1;
  intptr_t previous_pc_offset = 0;

  Function& root_function = Function::Handle(zone_);
  Script& script = Script::Handle(zone_);
  CodeSourceMap& map = CodeSourceMap::Handle(zone_);
  Array& functions = Array::Handle(zone_);
  GrowableArray<const Function*> function_stack(zone_, 8);
  GrowableArray<TokenPosition> token_positions(zone_, 8);

  for (intptr_t i = 0; i < codes_.length(); i++) {
    const Code& code = *(codes_[i]);
    map = code.code_source_map();
    if (map.IsNull()) {
      continue;
    }
    root_function = code.function();
    functions = code.inlined_id_to_function();

    NoSafepointScope no_safepoint;
    ReadStream stream(map.Data(), map.Length());

    function_stack.Clear();
    token_positions.Clear();

    int32_t current_pc_offset = 0;
    function_stack.Add(&root_function);
    token_positions.Add(CodeSourceMapBuilder::kInitialPosition);

    while (stream.PendingBytes() > 0) {
      uint8_t opcode = stream.Read<uint8_t>();
      switch (opcode) {
        case CodeSourceMapBuilder::kChangePosition: {
          int32_t position = stream.Read<int32_t>();
          token_positions[token_positions.length() - 1] =
              TokenPosition(position);
          break;
        }
        case CodeSourceMapBuilder::kAdvancePC: {
          int32_t delta = stream.Read<int32_t>();
          current_pc_offset += delta;

          const Function& function = *(function_stack.Last());
          script = function.script();
          intptr_t file = LookupScript(script);

          // 1. Update LNP file.
          if (file != previous_file) {
            u1(DW_LNS_set_file);
            uleb128(file);
            previous_file = file;
          }

          // 2. Update LNP line.
          TokenPosition pos = token_positions.Last();
          intptr_t line = pos.value();
          if (line != previous_line) {
            u1(DW_LNS_advance_line);
            sleb128(line - previous_line);
            previous_line = line;
          }

          // 3. Emit LNP row.
          u1(DW_LNS_copy);

          // 4. Update LNP pc.
          if (previous_code_index == -1) {
            // This variant is relocatable.
            u1(0);                  // This is an extended opcode
            u1(1 + sizeof(void*));  // that is 5 or 9 bytes long
            u1(DW_LNE_set_address);
            Print(FORM_ADDR " .Lcode%" Pd " + %" Pd "\n", i, current_pc_offset);
          } else {
            u1(DW_LNS_advance_pc);
            Print(".uleb128 .Lcode%" Pd " - .Lcode%" Pd " + %" Pd "\n", i,
                  previous_code_index, current_pc_offset - previous_pc_offset);
          }
          previous_code_index = i;
          previous_pc_offset = current_pc_offset;
          break;
        }
        case CodeSourceMapBuilder::kPushFunction: {
          int32_t func_index = stream.Read<int32_t>();
          const Function& child_func = Function::Handle(
              zone_, Function::RawCast(functions.At(func_index)));
          function_stack.Add(&child_func);
          token_positions.Add(CodeSourceMapBuilder::kInitialPosition);
          break;
        }
        case CodeSourceMapBuilder::kPopFunction: {
          // We never pop the root function.
          ASSERT(function_stack.length() > 1);
          ASSERT(token_positions.length() > 1);
          function_stack.RemoveLast();
          token_positions.RemoveLast();
          break;
        }
        default:
          UNREACHABLE();
      }
    }
  }

  // Advance pc to end of the compilation unit.
  intptr_t last_code_index = codes_.length() - 1;
  const Code& last_code = *(codes_[last_code_index]);
  u1(DW_LNS_advance_pc);
  Print(".uleb128 .Lcode%" Pd " - .Lcode%" Pd " + %" Pd "\n", last_code_index,
        previous_code_index, last_code.Size() - previous_pc_offset);

  // End of contiguous machine code.
  u1(0);  // This is an extended opcode
  u1(1);  // that is 1 byte long
  u1(DW_LNE_end_sequence);

  Print(".Lline_end:\n");
}

#endif  // DART_PRECOMPILER

}  // namespace dart
