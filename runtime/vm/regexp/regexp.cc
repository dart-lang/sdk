// Copyright 2012 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vm/regexp/regexp.h"

#include <algorithm>
#include <bitset>
#include <memory>
#include <utility>

#include "vm/regexp/regexp-bytecode-generator.h"
#include "vm/regexp/regexp-bytecodes.h"
#include "vm/regexp/regexp-compiler.h"
#include "vm/regexp/regexp-interpreter.h"
#include "vm/regexp/regexp-macro-assembler.h"
#include "vm/regexp/regexp-parser.h"
#include "vm/symbols.h"

namespace dart {

using namespace regexp_compiler_constants;  // NOLINT(build/namespaces)

class RegExpImpl final : public AllStatic {
 public:
  // Returns a string representation of a regular expression.
  // Implements RegExp.prototype.toString, see ECMA-262 section 15.10.6.4.
  // This function calls the garbage collector if necessary.
  static const StringPtr ToString(const Object& value);

  // Prepares a JSRegExp object with Irregexp-specific data.
  static void IrregexpInitialize(Isolate* isolate,
                                 const RegExp& re,
                                 const String& pattern,
                                 RegExpFlags flags,
                                 int capture_count,
                                 uint32_t backtrack_limit,
                                 uint32_t bit_field);

  // Prepare a RegExp for being executed one or more times (using
  // IrregexpExecOnce) on the subject.
  // This ensures that the regexp is compiled for the subject, and that
  // the subject is flat.
  // Returns the number of integer spaces required by IrregexpExecOnce
  // as its "registers" argument.  If the regexp cannot be compiled,
  // an exception is thrown as indicated by a negative return value.
  static int IrregexpPrepare(Isolate* isolate,
                             const RegExp& regexp_data,
                             const String& subject,
                             bool is_sticky);

  // Execute a regular expression on the subject, starting from index.
  // If matching succeeds, return the number of matches.  This can be larger
  // than one in the case of global regular expressions.
  // The captures and subcaptures are stored into the registers vector.
  // If matching fails, returns RE_FAILURE.
  // If execution fails, sets an exception and returns RE_EXCEPTION.
  static int IrregexpExecRaw(Isolate* isolate,
                             const RegExp& regexp_data,
                             const String& subject,
                             int index,
                             int32_t* output,
                             int output_size);

  // Execute an Irregexp bytecode pattern. Returns the number of matches, or an
  // empty handle in case of an exception.
  V8_WARN_UNUSED_RESULT static std::optional<int> IrregexpExec(
      Isolate* isolate,
      const RegExp& regexp_data,
      const String& subject,
      int index,
      int32_t* result_offsets_vector,
      uint32_t result_offsets_vector_length);

  static bool CompileIrregexpFromSource(
      Thread* thread,
      const RegExp& re_data,
      const String& sample_subject,
      bool is_one_byte,
      bool sticky,
      RegExpCompilationTarget compilation_target);
  static bool CompileIrregexpFromBytecode(Isolate* isolate,
                                          const RegExp& re_data,
                                          const String& sample_subject,
                                          bool is_one_byte);
  static inline bool EnsureCompiledIrregexp(Thread* thread,
                                            const RegExp& re_data,
                                            const String& sample_subject,
                                            bool is_one_byte,
                                            bool sticky);

  // Returns true on success, false on failure.
  static bool Compile(Isolate* isolate,
                      Zone* zone,
                      RegExpCompileData* input,
                      RegExpFlags flags,
                      const String& pattern,
                      const String& sample_subject,
                      const RegExp& re_data,
                      bool is_one_byte);
};

// static
bool RegExpStatics::CanGenerateBytecode() {
  return true;
}

// static
bool RegExpStatics::VerifyFlags(RegExpFlags flags) {
  if (IsUnicode(flags) && IsUnicodeSets(flags)) return false;
  return true;
}

// static
template <class CharT>
bool RegExpStatics::VerifySyntax(Zone* zone,
                                 uintptr_t stack_limit,
                                 const CharT* input,
                                 int input_length,
                                 RegExpFlags flags,
                                 RegExpError* regexp_error_out) {
  RegExpCompileData data;
  bool pattern_is_valid = RegExpParser::VerifyRegExpSyntax(
      zone, stack_limit, input, input_length, flags, &data);
  *regexp_error_out = data.error;
  return pattern_is_valid;
}

template bool RegExpStatics::VerifySyntax<uint8_t>(
    Zone*,
    uintptr_t,
    const uint8_t*,
    int,
    RegExpFlags,
    RegExpError* regexp_error_out);
template bool RegExpStatics::VerifySyntax<uint16_t>(
    Zone*,
    uintptr_t,
    const uint16_t*,
    int,
    RegExpFlags,
    RegExpError* regexp_error_out);

ObjectPtr RegExpStatics::ThrowRegExpException(Isolate* isolate,
                                              RegExpFlags flags,
                                              const String& pattern,
                                              RegExpError error) {
  Array& args = Array::Handle();
  String& str = String::Handle();
  str ^= String::New(RegExpErrorString(error));
  args ^= Array::New(2);
  args.SetAt(0, str);
  args.SetAt(1, pattern);
  // TODO(regexp) args.SetAt(2, position) sometimes available but not used by V8
  Exceptions::ThrowByType(Exceptions::kFormat, args);
}

void RegExpStatics::ThrowRegExpException(Isolate* isolate,
                                         const RegExp& re_data,
                                         RegExpError error_text) {
  USE(ThrowRegExpException(isolate, re_data.flags(),
                           String::Handle(re_data.pattern()), error_text));
}

bool RegExpStatics::IsUnmodifiedRegExp(Isolate* isolate, const RegExp& regexp) {
  // Can't monkey patch in Dart.
  return true;
}

// Irregexp implementation.

// Ensures that the regexp object contains a compiled version of the
// source for either one-byte or two-byte subject strings.
// If the compiled version doesn't already exist, it is compiled
// from the source pattern.
// If compilation fails, an exception is thrown and this function
// returns false.
bool RegExpImpl::EnsureCompiledIrregexp(Thread* thread,
                                        const RegExp& re_data,
                                        const String& sample_subject,
                                        bool is_one_byte,
                                        bool sticky) {
  if (re_data.bytecode(is_one_byte, sticky) != TypedData::null()) return true;

  return CompileIrregexpFromSource(thread, re_data, sample_subject, is_one_byte,
                                   sticky, RegExpCompilationTarget::kBytecode);
}

namespace {

struct RegExpCaptureIndexLess {
  bool operator()(const RegExpCapture* lhs, const RegExpCapture* rhs) const {
    DCHECK_NOT_NULL(lhs);
    DCHECK_NOT_NULL(rhs);
    return lhs->index() < rhs->index();
  }
};

}  // namespace

// static
ArrayPtr RegExpStatics::CreateCaptureNameMap(
    Isolate* isolate,
    ZoneVector<RegExpCapture*>* named_captures) {
  if (named_captures == nullptr) return Array::null();

  ASSERT(!named_captures->empty());

  // Named captures are sorted by name (because the set is used to ensure
  // name uniqueness). But the capture name map must to be sorted by index.

  std::sort(named_captures->begin(), named_captures->end(),
            RegExpCaptureIndexLess{});

  int len = static_cast<int>(named_captures->size()) * 2;
  const Array& array = Array::Handle(Array::New(len));

  int i = 0;
  for (const RegExpCapture* capture : *named_captures) {
    const String& name = String::Handle(
        String::FromUTF16(capture->name()->data(), capture->name()->size()));
    array.SetAt(i * 2, name);
    array.SetAt(i * 2 + 1, Smi::Handle(Smi::New(capture->index())));
    i++;
  }
  DCHECK_EQ(i * 2, len);

  return array.ptr();
}

bool RegExpImpl::CompileIrregexpFromSource(
    Thread* thread,
    const RegExp& re_data,
    const String& sample_subject,
    bool is_one_byte,
    bool sticky,
    RegExpCompilationTarget compilation_target) {
  // Since we can't abort gracefully during compilation, check for sufficient
  // stack space (including the additional gap as used for Turbofan
  // compilation) here in advance.
  if (!OSThread::Current()->HasStackHeadroom()) {
    RegExpStatics::ThrowRegExpException(thread->isolate(), re_data,
                                        RegExpError::kAnalysisStackOverflow);
    return false;
  }

  // Compile the RegExp.
  // Zone zone(isolate->allocator(), ZONE_NAME);
  // PostponeInterruptsScope postpone(isolate);

  // ASSERT(RegExpCodeIsValidForPreCompilation(isolate, re_data, is_one_byte));

  RegExpFlags flags = re_data.flags();
  if (sticky) {
    flags |= RegExpFlag::kSticky;
  }
  Zone* zone = thread->zone();
  const String& pattern = String::Handle(zone, re_data.pattern());

  RegExpCompileData compile_data;
  if (!RegExpParser::ParseRegExpFromHeapString(thread->isolate(), zone, pattern,
                                               flags, &compile_data)) {
    // Throw an exception if we fail to parse the pattern.
    // THIS SHOULD NOT HAPPEN. We already pre-parsed it successfully once.
    USE(RegExpStatics::ThrowRegExpException(thread->isolate(), flags, pattern,
                                            compile_data.error));
    return false;
  }
  compile_data.compilation_target = compilation_target;
  const bool compilation_succeeded =
      Compile(thread->isolate(), zone, &compile_data, flags, pattern,
              sample_subject, re_data, is_one_byte);
  if (!compilation_succeeded) {
    ASSERT(compile_data.error != RegExpError::kNone);
    RegExpStatics::ThrowRegExpException(thread->isolate(), re_data,
                                        compile_data.error);
    return false;
  }

  // Set num_bracket_expression after setting capture_name_map.
  // RegExp_getGroupNameMap will read num_bracket_expression first and assume
  // capture_name_map is available if the count is not -1.
  const Array& capture_name_map =
      Array::Handle(zone, RegExpStatics::CreateCaptureNameMap(
                              thread->isolate(), compile_data.named_captures));
  re_data.set_capture_name_map(capture_name_map);
  re_data.set_num_bracket_expressions<std::memory_order_release>(
      compile_data.capture_count);

  // Set bytecode after setting num_registers. RegExpStatics::Interpret will
  // read bytecode first and assume num_register is available if bytecode is not
  // null.
  re_data.set_num_registers(is_one_byte, compile_data.register_count);
  DCHECK_EQ(compile_data.compilation_target,
            RegExpCompilationTarget::kBytecode);
  re_data.set_bytecode(is_one_byte, sticky,
                       TypedData::Cast(*compile_data.code));

  return true;
}

namespace {

void SetBacktrackAndExperimentalFallback(RegExpMacroAssembler* macro_assembler,
                                         const RegExp& re_data) {
  uint32_t backtrack_limit = JSRegExp::kNoBacktrackLimit;
  macro_assembler->set_backtrack_limit(backtrack_limit);
  macro_assembler->set_can_fallback(false);
}

}  // namespace

namespace {

// Returns true if we've either generated too much irregex code within this
// isolate, or the pattern string is too long.
bool TooMuchRegExpCode(Isolate* isolate, const String& pattern) {
  // Limit the space regexps take up on the heap.  In order to limit this we
  // would like to keep track of the amount of regexp code on the heap.  This
  // is not tracked, however.  As a conservative approximation we track the
  // total regexp code compiled including code that has subsequently been freed
  // and the total executable memory at any point.
  // static constexpr size_t kRegExpExecutableMemoryLimit = 16 * MB;
  // static constexpr size_t kRegExpCompiledLimit = 1 * MB;

  // Heap* heap = isolate->heap();
  if (pattern.Length() > RegExpStatics::kRegExpTooLargeToOptimize) return true;
  // TODO(regexp): Not relevant for Dart if we're only ever doing bytecode?
  // return (isolate->total_regexp_code_generated() > kRegExpCompiledLimit &&
  //         heap->CommittedMemoryExecutable() > kRegExpExecutableMemoryLimit);
  return false;
}

}  // namespace

bool RegExpImpl::Compile(Isolate* isolate,
                         Zone* zone,
                         RegExpCompileData* data,
                         RegExpFlags flags,
                         const String& pattern,
                         const String& sample_subject,
                         const RegExp& re_data,
                         bool is_one_byte) {
  if (JSRegExp::RegistersForCaptureCount(data->capture_count) >
      RegExpMacroAssembler::kMaxRegisterCount) {
    data->error = RegExpError::kTooLarge;
    return false;
  }

  RegExpCompiler compiler(isolate, zone, data->capture_count, flags,
                          is_one_byte);
#ifdef V8_ENABLE_REGEXP_DIAGNOSTICS
  const bool needs_graph_printer = v8_flags.print_regexp_graph ||
                                   v8_flags.trace_regexp_graph_building ||
                                   v8_flags.trace_regexp_compiler;
  const bool needs_ast_printer = v8_flags.trace_regexp_graph_building;
  std::unique_ptr<RegExpDiagnostics> diagnostics;
  if (UNLIKELY(needs_ast_printer || needs_graph_printer)) {
    diagnostics = std::make_unique<RegExpDiagnostics>(std::cout, zone);
  }
  if (UNLIKELY(needs_ast_printer)) {
    diagnostics->set_tree_labeller(
        std::make_unique<RegExpGraphLabeller<RegExpTree>>());
    diagnostics->set_ast_printer(std::make_unique<RegExpAstNodePrinter>(
        diagnostics->os(), diagnostics->tree_labeller(), diagnostics->zone()));
  }
  if (UNLIKELY(needs_graph_printer)) {
    diagnostics->set_graph_labeller(
        std::make_unique<RegExpGraphLabeller<RegExpNode>>());
    diagnostics->set_graph_printer(std::make_unique<RegExpGraphPrinter>(
        std::make_unique<RegExpGraphNodePrinter>(diagnostics->os(),
                                                 diagnostics->graph_labeller(),
                                                 diagnostics->zone())));
  }
  if (UNLIKELY(needs_ast_printer || needs_graph_printer)) {
    compiler.set_diagnostics(std::move(diagnostics));
  }
#endif

  if (compiler.optimize()) {
    compiler.set_optimize(!TooMuchRegExpCode(isolate, pattern));
  }

  data->node = compiler.PreprocessRegExp(data, is_one_byte);
  if (data->error != RegExpError::kNone) {
    return false;
  }
  data->error = AnalyzeRegExp(isolate, is_one_byte, flags, data->node);
  if (data->error != RegExpError::kNone) {
    return false;
  }

#ifdef V8_ENABLE_REGEXP_DIAGNOSTICS
  if (UNLIKELY(v8_flags.print_regexp_graph))
    compiler.diagnostics()->graph_printer()->PrintGraph(data->node);
  if (v8_flags.trace_regexp_graph) DotPrinter::DotPrint("Start", data->node);
#endif

  std::unique_ptr<RegExpMacroAssembler> macro_assembler;
  if (data->compilation_target == RegExpCompilationTarget::kNative) {
    UNREACHABLE();
  } else {
    DCHECK_EQ(data->compilation_target, RegExpCompilationTarget::kBytecode);
    // Interpreted regexp implementation.
    macro_assembler.reset(
        new RegExpBytecodeGenerator(isolate, zone,
                                    is_one_byte ? RegExpMacroAssembler::LATIN1
                                                : RegExpMacroAssembler::UC16));
#ifdef V8_ENABLE_REGEXP_DIAGNOSTICS
    if (UNLIKELY(v8_flags.trace_regexp_assembler)) {
      std::unique_ptr<RegExpMacroAssembler> tracer_macro_assembler =
          std::make_unique<RegExpMacroAssemblerTracer>(
              std::move(macro_assembler));
      macro_assembler = std::move(tracer_macro_assembler);
    }
#endif
  }

  macro_assembler->set_slow_safe(TooMuchRegExpCode(isolate, pattern));
  SetBacktrackAndExperimentalFallback(macro_assembler.get(), re_data);

  // Inserted here, instead of in Assembler, because it depends on information
  // in the AST that isn't replicated in the Node structure.
  bool is_end_anchored = data->tree->IsAnchoredAtEnd();
  bool is_start_anchored = data->tree->IsAnchoredAtStart();
  int max_length = data->tree->max_match();
  static const int kMaxBacksearchLimit = 1024;
  if (is_end_anchored && !is_start_anchored && !IsSticky(flags) &&
      max_length < kMaxBacksearchLimit) {
    macro_assembler->SetCurrentPositionFromEnd(max_length);
  }

  if (IsGlobal(flags)) {
    RegExpMacroAssembler::GlobalMode mode = RegExpMacroAssembler::GLOBAL;
    if (data->tree->min_match() > 0) {
      mode = RegExpMacroAssembler::GLOBAL_NO_ZERO_LENGTH_CHECK;
    } else if (IsEitherUnicode(flags)) {
      mode = RegExpMacroAssembler::GLOBAL_UNICODE;
    }
    macro_assembler->set_global_mode(mode);
  }

  RegExpCompiler::CompilationResult result = compiler.Assemble(
      isolate, macro_assembler.get(), data->node, data->capture_count, pattern);

  // Code / bytecode printing.
  {
#ifdef ENABLE_DISASSEMBLER
    if (UNLIKELY(v8_flags.print_regexp_code &&
                 data->compilation_target == RegExpCompilationTarget::kNative &&
                 result.Succeeded())) {
      CodeTracer::Scope trace_scope(isolate->GetCodeTracer());
      OFStream os(trace_scope.file());
      auto code = CheckedCast<Code>(result.code);
      std::unique_ptr<char[]> pattern_cstring = pattern->ToCString();
      code->Disassemble(pattern_cstring.get(), os, isolate);
    }
    if (UNLIKELY(v8_flags.print_regexp_bytecode &&
                 data->compilation_target ==
                     RegExpCompilationTarget::kBytecode &&
                 result.Succeeded())) {
      auto bytecode = CheckedCast<TrustedByteArray>(result.code);
      std::unique_ptr<char[]> pattern_cstring = pattern->ToCString();
      RegExpBytecodeDisassemble(bytecode->begin(), bytecode->length(),
                                pattern_cstring.get());
    }
#endif
  }

  if (result.error != RegExpError::kNone) {
    if (FLAG_correctness_fuzzer_suppressions &&
        result.error == RegExpError::kStackOverflow) {
      FATAL("Aborting on stack overflow");
    }
    data->error = result.error;
  }

  data->code = result.code;
  data->register_count = result.num_registers;

  return result.Succeeded();
}

std::ostream& operator<<(std::ostream& os, RegExpFlags flags) {
#define V(Lower, Camel, LowerCamel, Char, Bit)                                 \
  if (flags & RegExpFlag::k##Camel) os << Char;
  REGEXP_FLAG_LIST(V)
#undef V
  return os;
}

ObjectPtr RegExpStatics::Interpret(Thread* thread,
                                   const RegExp& regexp,
                                   const String& subject,
                                   int start_index,
                                   bool sticky) {
  bool is_one_byte = subject.IsOneByteString();
  if (regexp.bytecode(is_one_byte, sticky) == TypedData::null()) {
    if (!RegExpImpl::CompileIrregexpFromSource(
            thread, regexp, subject, is_one_byte, sticky,
            RegExpCompilationTarget::kBytecode)) {
      // RegExp was verified at construction.
      UNREACHABLE();
    }
  }

  int register_count = regexp.num_registers(is_one_byte);
  ASSERT(register_count >= 2);
  int32_t* registers = thread->zone()->Alloc<int32_t>(register_count);

  for (intptr_t i = 0; i < register_count; i++) {
    registers[i] = -1;
  }

  int r = IrregexpInterpreter::MatchForCallFromRuntime(
      thread, regexp, subject, registers, register_count, start_index, sticky);
  if (r == IrregexpInterpreter::SUCCESS) {
    const TypedData& result = TypedData::Handle(
        thread->zone(),
        TypedData::New(kTypedDataInt32ArrayCid, register_count));
    {
#ifdef DEBUG
      // These indices will be used with substring operations that don't check
      // bounds, so sanity check them here.
      for (intptr_t i = 0; i < register_count; i++) {
        int32_t val = registers[i];
        ASSERT(val == -1 || (val >= 0 && val <= subject.Length()));
      }
#endif

      NoSafepointScope no_safepoint(thread);
      memcpy(result.DataAddr(0), registers,
             register_count * sizeof(int32_t));  // NOLINT
    }

    return result.ptr();
  } else if (r == IrregexpInterpreter::FAILURE) {
    return Instance::null();
  } else if (r == IrregexpInterpreter::EXCEPTION) {
    const Error& error = Error::Handle(thread->StealStickyError());
    Exceptions::PropagateError(error);
    UNREACHABLE();
  } else if (r == IrregexpInterpreter::RETRY) {
    UNREACHABLE();  // No tier up in Dart.
  } else if (r == IrregexpInterpreter::FALLBACK_TO_EXPERIMENTAL) {
    UNREACHABLE();  // No alt implementation for Dart.
  } else {
    UNREACHABLE();
  }
  return Instance::null();
}

}  // namespace dart
