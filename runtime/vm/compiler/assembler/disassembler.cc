// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/assembler/disassembler.h"

#include "vm/code_patcher.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/deopt_instructions.h"
#include "vm/globals.h"
#include "vm/instructions.h"
#include "vm/json_stream.h"
#include "vm/log.h"
#include "vm/os.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, trace_inlining_intervals);
DEFINE_FLAG(bool, trace_source_positions, false, "Source position diagnostics");

void DisassembleToStdout::ConsumeInstruction(const Code& code,
                                             char* hex_buffer,
                                             intptr_t hex_size,
                                             char* human_buffer,
                                             intptr_t human_size,
                                             Object* object,
                                             uword pc) {
  static const int kHexColumnWidth = 23;
  uint8_t* pc_ptr = reinterpret_cast<uint8_t*>(pc);
  THR_Print("%p    %s", pc_ptr, hex_buffer);
  int hex_length = strlen(hex_buffer);
  if (hex_length < kHexColumnWidth) {
    for (int i = kHexColumnWidth - hex_length; i > 0; i--) {
      THR_Print(" ");
    }
  }
  THR_Print("%s", human_buffer);
  if (object != NULL) {
    THR_Print("   %s", object->ToCString());
  }
  THR_Print("\n");
}

void DisassembleToStdout::Print(const char* format, ...) {
  va_list args;
  va_start(args, format);
  THR_VPrint(format, args);
  va_end(args);
}

void DisassembleToJSONStream::ConsumeInstruction(const Code& code,
                                                 char* hex_buffer,
                                                 intptr_t hex_size,
                                                 char* human_buffer,
                                                 intptr_t human_size,
                                                 Object* object,
                                                 uword pc) {
  // Instructions are represented as four consecutive values in a JSON array.
  // The first is the address of the instruction, the second is the hex string,
  // of the code, and the third is a human readable string, and the fourth is
  // the object loaded by the instruction.
  jsarr_.AddValueF("%" Pp "", pc);
  jsarr_.AddValue(hex_buffer);
  jsarr_.AddValue(human_buffer);

  if (object != NULL) {
    jsarr_.AddValue(*object);
  } else {
    jsarr_.AddValueNull();  // Not a reference to null.
  }
}

void DisassembleToJSONStream::Print(const char* format, ...) {
  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);
  char* p = reinterpret_cast<char*>(malloc(len + 1));
  va_start(args, format);
  intptr_t len2 = OS::VSNPrint(p, len, format, args);
  va_end(args);
  ASSERT(len == len2);
  for (intptr_t i = 0; i < len; i++) {
    if (p[i] == '\n' || p[i] == '\r') {
      p[i] = ' ';
    }
  }
  // Instructions are represented as four consecutive values in a JSON array.
  // Comments only use the third slot. See above comment for more information.
  jsarr_.AddValueNull();
  jsarr_.AddValueNull();
  jsarr_.AddValue(p);
  jsarr_.AddValueNull();
  free(p);
}

void Disassembler::Disassemble(uword start,
                               uword end,
                               DisassemblyFormatter* formatter,
                               const Code& code) {
  const Code::Comments& comments =
      code.IsNull() ? Code::Comments::New(0) : code.comments();
  ASSERT(formatter != NULL);
  char hex_buffer[kHexadecimalBufferSize];  // Instruction in hexadecimal form.
  char human_buffer[kUserReadableBufferSize];  // Human-readable instruction.
  uword pc = start;
  intptr_t comment_finger = 0;
  GrowableArray<const Function*> inlined_functions;
  GrowableArray<TokenPosition> token_positions;
  while (pc < end) {
    const intptr_t offset = pc - start;
    const intptr_t old_comment_finger = comment_finger;
    while (comment_finger < comments.Length() &&
           comments.PCOffsetAt(comment_finger) <= offset) {
      formatter->Print(
          "        ;; %s\n",
          String::Handle(comments.CommentAt(comment_finger)).ToCString());
      comment_finger++;
    }
    if (old_comment_finger != comment_finger) {
      char str[4000];
      BufferFormatter f(str, sizeof(str));
      // Comment emitted, emit inlining information.
      code.GetInlinedFunctionsAtInstruction(offset, &inlined_functions,
                                            &token_positions);
      // Skip top scope function printing (last entry in 'inlined_functions').
      bool first = true;
      for (intptr_t i = 1; i < inlined_functions.length(); i++) {
        const char* name = inlined_functions[i]->ToQualifiedCString();
        if (first) {
          f.Print("        ;; Inlined [%s", name);
          first = false;
        } else {
          f.Print(" -> %s", name);
        }
      }
      if (!first) {
        f.Print("]\n");
        formatter->Print(str);
      }
    }
    int instruction_length;
    Object* object;
    DecodeInstruction(hex_buffer, sizeof(hex_buffer), human_buffer,
                      sizeof(human_buffer), &instruction_length, code, &object,
                      pc);
    formatter->ConsumeInstruction(code, hex_buffer, sizeof(hex_buffer),
                                  human_buffer, sizeof(human_buffer), object,
                                  pc);
    pc += instruction_length;
  }
}

void Disassembler::DisassembleCodeHelper(const char* function_fullname,
                                         const Code& code,
                                         bool optimized) {
  Zone* zone = Thread::Current()->zone();
  LocalVarDescriptors& var_descriptors = LocalVarDescriptors::Handle(zone);
  if (FLAG_print_variable_descriptors) {
    var_descriptors = code.GetLocalVarDescriptors();
  }
  THR_Print("Code for %sfunction '%s' {\n", optimized ? "optimized " : "",
            function_fullname);
  code.Disassemble();
  THR_Print("}\n");

#if defined(TARGET_ARCH_IA32)
  THR_Print("Pointer offsets for function: {\n");
  // Pointer offsets are stored in descending order.
  Object& obj = Object::Handle(zone);
  for (intptr_t i = code.pointer_offsets_length() - 1; i >= 0; i--) {
    const uword addr = code.GetPointerOffsetAt(i) + code.PayloadStart();
    obj = *reinterpret_cast<RawObject**>(addr);
    THR_Print(" %d : %#" Px " '%s'\n", code.GetPointerOffsetAt(i), addr,
              obj.ToCString());
  }
  THR_Print("}\n");
#else
  ASSERT(code.pointer_offsets_length() == 0);
#endif

  const ObjectPool& object_pool =
      ObjectPool::Handle(zone, code.GetObjectPool());
  object_pool.DebugPrint();

  THR_Print("PC Descriptors for function '%s' {\n", function_fullname);
  PcDescriptors::PrintHeaderString();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(zone, code.pc_descriptors());
  THR_Print("%s}\n", descriptors.ToCString());

  uword start = Instructions::Handle(zone, code.instructions()).PayloadStart();

#if !defined(DART_PRECOMPILED_RUNTIME)
  const Array& deopt_table = Array::Handle(zone, code.deopt_info_array());
  intptr_t deopt_table_length = DeoptTable::GetLength(deopt_table);
  if (deopt_table_length > 0) {
    THR_Print("DeoptInfo: {\n");
    Smi& offset = Smi::Handle(zone);
    TypedData& info = TypedData::Handle(zone);
    Smi& reason_and_flags = Smi::Handle(zone);
    for (intptr_t i = 0; i < deopt_table_length; ++i) {
      DeoptTable::GetEntry(deopt_table, i, &offset, &info, &reason_and_flags);
      const intptr_t reason =
          DeoptTable::ReasonField::decode(reason_and_flags.Value());
      ASSERT((0 <= reason) && (reason < ICData::kDeoptNumReasons));
      THR_Print(
          "%4" Pd ": 0x%" Px "  %s  (%s)\n", i, start + offset.Value(),
          DeoptInfo::ToCString(deopt_table, info),
          DeoptReasonToCString(static_cast<ICData::DeoptReasonId>(reason)));
    }
    THR_Print("}\n");
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  THR_Print("StackMaps for function '%s' {\n", function_fullname);
  if (code.stackmaps() != Array::null()) {
    const Array& stackmap_table = Array::Handle(zone, code.stackmaps());
    StackMap& map = StackMap::Handle(zone);
    for (intptr_t i = 0; i < stackmap_table.Length(); ++i) {
      map ^= stackmap_table.At(i);
      THR_Print("%s\n", map.ToCString());
    }
  }
  THR_Print("}\n");

  if (FLAG_print_variable_descriptors) {
    THR_Print("Variable Descriptors for function '%s' {\n", function_fullname);
    intptr_t var_desc_length =
        var_descriptors.IsNull() ? 0 : var_descriptors.Length();
    String& var_name = String::Handle(zone);
    for (intptr_t i = 0; i < var_desc_length; i++) {
      var_name = var_descriptors.GetName(i);
      RawLocalVarDescriptors::VarInfo var_info;
      var_descriptors.GetInfo(i, &var_info);
      const int8_t kind = var_info.kind();
      if (kind == RawLocalVarDescriptors::kSavedCurrentContext) {
        THR_Print("  saved current CTX reg offset %d\n", var_info.index());
      } else {
        if (kind == RawLocalVarDescriptors::kContextLevel) {
          THR_Print("  context level %d scope %d", var_info.index(),
                    var_info.scope_id);
        } else if (kind == RawLocalVarDescriptors::kStackVar) {
          THR_Print("  stack var '%s' offset %d", var_name.ToCString(),
                    var_info.index());
        } else {
          ASSERT(kind == RawLocalVarDescriptors::kContextVar);
          THR_Print("  context var '%s' level %d offset %d",
                    var_name.ToCString(), var_info.scope_id, var_info.index());
        }
        THR_Print(" (valid %s-%s)\n", var_info.begin_pos.ToCString(),
                  var_info.end_pos.ToCString());
      }
    }
    THR_Print("}\n");
  }

  THR_Print("Exception Handlers for function '%s' {\n", function_fullname);
  const ExceptionHandlers& handlers =
      ExceptionHandlers::Handle(zone, code.exception_handlers());
  THR_Print("%s}\n", handlers.ToCString());

  {
    THR_Print("Static call target functions {\n");
    const Array& table = Array::Handle(zone, code.static_calls_target_table());
    Smi& offset = Smi::Handle(zone);
    Function& function = Function::Handle(zone);
    Code& code = Code::Handle(zone);
    for (intptr_t i = 0; i < table.Length();
         i += Code::kSCallTableEntryLength) {
      offset ^= table.At(i + Code::kSCallTableOffsetEntry);
      function ^= table.At(i + Code::kSCallTableFunctionEntry);
      code ^= table.At(i + Code::kSCallTableCodeEntry);
      if (function.IsNull()) {
        Class& cls = Class::Handle(zone);
        cls ^= code.owner();
        if (cls.IsNull()) {
          THR_Print("  0x%" Px ": %s, %p\n", start + offset.Value(),
                    code.QualifiedName(), code.raw());
        } else {
          THR_Print("  0x%" Px ": allocation stub for %s, %p\n",
                    start + offset.Value(), cls.ToCString(), code.raw());
        }
      } else {
        THR_Print("  0x%" Px ": %s, %p\n", start + offset.Value(),
                  function.ToFullyQualifiedCString(), code.raw());
      }
    }
    THR_Print("}\n");
  }
  if (optimized && FLAG_trace_inlining_intervals) {
    code.DumpInlineIntervals();
  }
  if (FLAG_trace_source_positions) {
    code.DumpSourcePositions();
  }
}

void Disassembler::DisassembleCode(const Function& function,
                                   const Code& code,
                                   bool optimized) {
  const char* function_fullname = function.ToFullyQualifiedCString();
  DisassembleCodeHelper(function_fullname, code, optimized);
}

#endif  // !PRODUCT

}  // namespace dart
