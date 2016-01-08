// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_builder.h"
#include "vm/intermediate_language.h"
#include "vm/unit_test.h"

namespace dart {

#define DUMP_EXPECT(condition)                                                 \
  if (!(condition)) {                                                          \
    dart::Expect(__FILE__, __LINE__).Fail("expected: %s", #condition);         \
    THR_Print(">>> BEGIN source position table for `%s`\n", graph_name_);      \
    Dump();                                                                    \
    THR_Print("<<< END source position table for `%s`\n", graph_name_);        \
  }

class SourcePositionTest : public ValueObject {
 public:
  SourcePositionTest(Thread* thread,
                     const char* script)
      : thread_(thread),
        isolate_(thread->isolate()),
        script_(script),
        root_lib_(Library::Handle()),
        root_script_(Script::Handle()),
        graph_(NULL),
        blocks_(NULL) {
    EXPECT(thread_ != NULL);
    EXPECT(isolate_ != NULL);
    EXPECT(script_ != NULL);
    Dart_Handle lib = TestCase::LoadTestScript(script, NULL);
    EXPECT_VALID(lib);
    root_lib_ ^= Api::UnwrapHandle(lib);
    EXPECT(!root_lib_.IsNull());
    root_script_ ^= root_lib_.LookupScript(
        String::Handle(String::New(USER_TEST_URI)));
    EXPECT(!root_script_.IsNull());
  }

  void BuildGraphFor(const char* function_name) {
    graph_ = NULL;
    blocks_ = NULL;
    graph_name_ = NULL;

    // Only support unoptimized code for now.
    const bool optimized = false;

    const Function& function =
        Function::Handle(GetFunction(root_lib_, function_name));
    ZoneGrowableArray<const ICData*>* ic_data_array =
        new ZoneGrowableArray<const ICData*>();
    ParsedFunction* parsed_function = new ParsedFunction(
        thread_, Function::ZoneHandle(function.raw()));
    Parser::ParseFunction(parsed_function);
    parsed_function->AllocateVariables();
    FlowGraphBuilder builder(
        *parsed_function,
        *ic_data_array,
        NULL,
        Compiler::kNoOSRDeoptId);
    graph_ = builder.BuildGraph();
    EXPECT(graph_ != NULL);
    blocks_ = graph_->CodegenBlockOrder(optimized);
    EXPECT(blocks_ != NULL);
    graph_name_ = function_name;
    EXPECT(graph_name_ != NULL);
  }

  // Expect to find an instance call at |line| and |column|.
  void InstanceCallAt(intptr_t line,
                      intptr_t column = -1,
                      Token::Kind kind = Token::kNumTokens) {
    Instruction* instr = FindFirstInstructionAt(line, column);
    DUMP_EXPECT(instr->IsInstanceCall());
    if (kind != Token::kNumTokens) {
      DUMP_EXPECT(instr->AsInstanceCall()->token_kind() == kind);
    }
  }

  // Expect that at least one of the instructions found at |line| and |column|
  // contain |needle| in their |ToCString| representation.
  void FuzzyInstructionMatchAt(const char* needle,
                               intptr_t line,
                               intptr_t column = -1) {
    ZoneGrowableArray<Instruction*>* instructions =
        FindInstructionsAt(line, column);
    DUMP_EXPECT(instructions->length() > 0);
    intptr_t count = 0;
    for (intptr_t i = 0; i < instructions->length(); i++) {
      Instruction* instr = instructions->At(i);
      const char* haystack = instr->ToCString();
      if (strstr(haystack, needle) != NULL) {
        count++;
      }
    }
    DUMP_EXPECT(count > 0);
  }

  // Utility to dump the instructions with token positions or line numbers.
  void Dump() {
    for (intptr_t i = 0; i < blocks_->length(); i++) {
      BlockEntryInstr* entry = (*blocks_)[i];
      for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
        Instruction* instr = it.Current();
        const intptr_t token_pos = instr->token_pos();
        if (token_pos < 0) {
          THR_Print("%5d -- %s\n",
                    static_cast<int>(token_pos), instr->ToCString());
          continue;
        }
        intptr_t token_line = -1;
        intptr_t token_column = -1;
        root_script_.GetTokenLocation(token_pos,
                                      &token_line,
                                      &token_column,
                                      NULL);
        THR_Print("%02d:%02d -- %s\n",
                  static_cast<int>(token_line),
                  static_cast<int>(token_column),
                  instr->ToCString());
      }
    }
  }

 private:
  Instruction* FindFirstInstructionAt(intptr_t line, intptr_t column) {
    ZoneGrowableArray<Instruction*>* instructions =
        FindInstructionsAt(line, column);
    DUMP_EXPECT(instructions->length() > 0);
    return instructions->At(0);
  }

  ZoneGrowableArray<Instruction*>* FindInstructionsAt(
      intptr_t line, intptr_t column) {
    ZoneGrowableArray<Instruction*>* instructions =
        new ZoneGrowableArray<Instruction*>();
    for (intptr_t i = 0; i < blocks_->length(); i++) {
      BlockEntryInstr* entry = (*blocks_)[i];
      for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
        Instruction* instr = it.Current();
        intptr_t token_pos = instr->token_pos();
        if (token_pos < 0) {
          continue;
        }
        intptr_t token_line = -1;
        intptr_t token_column = -1;
        root_script_.GetTokenLocation(token_pos,
                                      &token_line,
                                      &token_column,
                                      NULL);
        if (token_line == line) {
          if ((column < 0) || (column == token_column)) {
            instructions->Add(instr);
          }
        }
      }
    }
    return instructions;
  }

  ZoneGrowableArray<Instruction*>* FindInstructionsAt(intptr_t token_pos) {
    ZoneGrowableArray<Instruction*>* instructions =
        new ZoneGrowableArray<Instruction*>();
    for (intptr_t i = 0; i < blocks_->length(); i++) {
      BlockEntryInstr* entry = (*blocks_)[i];
      for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
        Instruction* instr = it.Current();
        if (instr->token_pos() == token_pos) {
          instructions->Add(instr);
        }
      }
    }
    return instructions;
  }

  RawFunction* GetFunction(const Library& lib, const char* name) {
    const Function& result = Function::Handle(lib.LookupFunctionAllowPrivate(
        String::Handle(String::New(name))));
    EXPECT(!result.IsNull());
    return result.raw();
  }

  RawFunction* GetFunction(const Class& cls, const char* name) {
    const Function& result = Function::Handle(cls.LookupFunctionAllowPrivate(
        String::Handle(String::New(name))));
    EXPECT(!result.IsNull());
    return result.raw();
  }

  RawClass* GetClass(const Library& lib, const char* name) {
    const Class& cls = Class::Handle(
        lib.LookupClass(String::Handle(Symbols::New(name))));
    EXPECT(!cls.IsNull());  // No ambiguity error expected.
    return cls.raw();
  }

  Thread* thread_;
  Isolate* isolate_;
  const char* script_;
  Library& root_lib_;
  Script& root_script_;
  const char* graph_name_;
  FlowGraph* graph_;
  GrowableArray<BlockEntryInstr*>* blocks_;
};


TEST_CASE(SourcePosition_InstanceCalls) {
  const char* kScript =
      "var x = 5;\n"
      "var y = 5;\n"
      "main() {\n"
      "  var z = x + y;\n"
      "  return z;\n"
      "}\n";

  SourcePositionTest spt(thread, kScript);
  spt.BuildGraphFor("main");
  spt.FuzzyInstructionMatchAt("DebugStepCheck", 3, 5);
  spt.FuzzyInstructionMatchAt("CheckStackOverflow", 3, 5);
  spt.InstanceCallAt(4, 13, Token::kADD);
  spt.FuzzyInstructionMatchAt("DebugStepCheck", 5, 3);
  spt.FuzzyInstructionMatchAt("Return", 5, 3);
}

}  // namespace dart
