// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/parser.h"
#include "vm/flags.h"

#ifndef DART_PRECOMPILED_RUNTIME

#include "lib/invocation_mirror.h"
#include "platform/utils.h"
#include "vm/ast_transformer.h"
#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/frontend/kernel_binary_flowgraph.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler_stats.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/growable_array.h"
#include "vm/handles.h"
#include "vm/hash_table.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/longjump.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/regexp_assembler.h"
#include "vm/resolver.h"
#include "vm/safepoint.h"
#include "vm/scanner.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/timeline.h"
#include "vm/timer.h"
#include "vm/zone.h"

namespace dart {

DEFINE_FLAG(bool, enable_debug_break, false, "Allow use of break \"message\".");
DEFINE_FLAG(bool, trace_parser, false, "Trace parser operations.");
// TODO(floitsch): remove the conditional-directive flag, once we publicly
// committed to the current version.
DEFINE_FLAG(bool,
            conditional_directives,
            true,
            "Enable conditional directives");
DEFINE_FLAG(bool,
            generic_method_syntax,
            true,
            "Enable generic function syntax.");
DEFINE_FLAG(bool,
            initializing_formal_access,
            true,
            "Make initializing formal parameters visible in initializer list.");
DEFINE_FLAG(bool,
            warn_super,
            false,
            "Warning if super initializer not last in initializer list.");
DEFINE_FLAG(
    bool,
    await_is_keyword,
    false,
    "await and yield are treated as proper keywords in synchronous code.");
// TODO(zra): Remove the assert_initializer flag once all references to it
// from flutter and fuchsia scripts are deleted. Flag is a no-op (always on).
DEFINE_FLAG(bool,
            assert_initializer,
            true,
            "Allow asserts in initializer lists.");

DECLARE_FLAG(bool, profile_vm);
DECLARE_FLAG(bool, trace_service);
DECLARE_FLAG(bool, ignore_patch_signature_mismatch);

// Quick access to the current thread, isolate and zone.
#define T (thread())
#define I (isolate())
#define Z (zone())

// Quick synthetic token position.
#define ST(token_pos) ((token_pos).ToSynthetic())

#if defined(DEBUG)
class TraceParser : public ValueObject {
 public:
  TraceParser(TokenPosition token_pos,
              const Script& script,
              intptr_t* trace_indent,
              const char* msg) {
    indent_ = trace_indent;
    if (FLAG_trace_parser) {
      // Skips tracing of bootstrap libraries.
      if (script.HasSource()) {
        intptr_t line, column;
        script.GetTokenLocation(token_pos, &line, &column);
        PrintIndent();
        OS::Print("%s (line %" Pd ", col %" Pd ", token %" Pd ")\n", msg, line,
                  column, token_pos.value());
      }
      (*indent_)++;
    }
  }
  ~TraceParser() {
    if (FLAG_trace_parser) {
      (*indent_)--;
      ASSERT(*indent_ >= 0);
    }
  }

 private:
  void PrintIndent() {
    for (intptr_t i = 0; i < *indent_; i++) {
      OS::Print(". ");
    }
  }
  intptr_t* indent_;
};

#define TRACE_PARSER(s)                                                        \
  TraceParser __p__(this->TokenPos(), this->script_, &this->trace_indent_, s)

#else  // not DEBUG
#define TRACE_PARSER(s)
#endif  // DEBUG

class BoolScope : public ValueObject {
 public:
  BoolScope(bool* addr, bool new_value) : _addr(addr), _saved_value(*addr) {
    *_addr = new_value;
  }
  ~BoolScope() { *_addr = _saved_value; }

 private:
  bool* _addr;
  bool _saved_value;
};

// Helper class to save and restore token position.
class Parser::TokenPosScope : public ValueObject {
 public:
  explicit TokenPosScope(Parser* p) : p_(p) { saved_pos_ = p_->TokenPos(); }
  TokenPosScope(Parser* p, TokenPosition pos) : p_(p), saved_pos_(pos) {}
  ~TokenPosScope() { p_->SetPosition(saved_pos_); }

 private:
  Parser* p_;
  TokenPosition saved_pos_;
  DISALLOW_COPY_AND_ASSIGN(TokenPosScope);
};

class RecursionChecker : public ValueObject {
 public:
  explicit RecursionChecker(Parser* p) : parser_(p) {
    parser_->recursion_counter_++;
    // No need to check the stack unless the parser is in an unusually deep
    // recurive state. Thus, we omit the more expensive stack checks in
    // the common case.
    const int kMaxUncheckedDepth = 100;  // Somewhat arbitrary.
    if (parser_->recursion_counter_ > kMaxUncheckedDepth) {
      parser_->CheckStack();
    }
  }
  ~RecursionChecker() { parser_->recursion_counter_--; }

 private:
  Parser* parser_;
};

static RawTypeArguments* NewTypeArguments(
    const GrowableArray<AbstractType*>& objs) {
  const TypeArguments& a =
      TypeArguments::Handle(TypeArguments::New(objs.length()));
  for (int i = 0; i < objs.length(); i++) {
    a.SetTypeAt(i, *objs.At(i));
  }
  // Cannot canonicalize TypeArgument yet as its types may not have been
  // finalized yet.
  return a.raw();
}

void ParsedFunction::AddToGuardedFields(const Field* field) const {
  if ((field->guarded_cid() == kDynamicCid) ||
      (field->guarded_cid() == kIllegalCid)) {
    return;
  }

  for (intptr_t j = 0; j < guarded_fields_->length(); j++) {
    const Field* other = (*guarded_fields_)[j];
    if (field->Original() == other->Original()) {
      // Abort background compilation early if the guarded state of this field
      // has changed during compilation. We will not be able to commit
      // the resulting code anyway.
      if (Compiler::IsBackgroundCompilation()) {
        if (!other->IsConsistentWith(*field)) {
          Compiler::AbortBackgroundCompilation(
              Thread::kNoDeoptId,
              "Field's guarded state changed during compilation");
        }
      }
      return;
    }
  }

  // Note: the list of guarded fields must contain copies during background
  // compilation because we will look at their guarded_cid when copying
  // the array of guarded fields from callee into the caller during
  // inlining.
  ASSERT(!field->IsOriginal() || Thread::Current()->IsMutatorThread());
  guarded_fields_->Add(&Field::ZoneHandle(Z, field->raw()));
}

void ParsedFunction::Bailout(const char* origin, const char* reason) const {
  Report::MessageF(Report::kBailout, Script::Handle(function_.script()),
                   function_.token_pos(), Report::AtLocation,
                   "%s Bailout in %s: %s", origin,
                   String::Handle(function_.name()).ToCString(), reason);
  UNREACHABLE();
}

kernel::ScopeBuildingResult* ParsedFunction::EnsureKernelScopes() {
  if (kernel_scopes_ == NULL) {
    kernel::StreamingScopeBuilder builder(this);
    kernel_scopes_ = builder.BuildScopes();
  }
  return kernel_scopes_;
}

LocalVariable* ParsedFunction::EnsureExpressionTemp() {
  if (!has_expression_temp_var()) {
    LocalVariable* temp =
        new (Z) LocalVariable(function_.token_pos(), function_.token_pos(),
                              Symbols::ExprTemp(), Object::dynamic_type());
    ASSERT(temp != NULL);
    set_expression_temp_var(temp);
  }
  ASSERT(has_expression_temp_var());
  return expression_temp_var();
}

void ParsedFunction::EnsureFinallyReturnTemp(bool is_async) {
  if (!has_finally_return_temp_var()) {
    LocalVariable* temp =
        new (Z) LocalVariable(function_.token_pos(), function_.token_pos(),
                              Symbols::FinallyRetVal(), Object::dynamic_type());
    ASSERT(temp != NULL);
    temp->set_is_final();
    if (is_async) {
      temp->set_is_captured();
    }
    set_finally_return_temp_var(temp);
  }
  ASSERT(has_finally_return_temp_var());
}

void ParsedFunction::SetNodeSequence(SequenceNode* node_sequence) {
  ASSERT(node_sequence_ == NULL);
  ASSERT(node_sequence != NULL);
  node_sequence_ = node_sequence;
}

void ParsedFunction::SetRegExpCompileData(
    RegExpCompileData* regexp_compile_data) {
  ASSERT(regexp_compile_data_ == NULL);
  ASSERT(regexp_compile_data != NULL);
  regexp_compile_data_ = regexp_compile_data;
}

void ParsedFunction::AddDeferredPrefix(const LibraryPrefix& prefix) {
  // 'deferred_prefixes_' are used to invalidate code, but no invalidation is
  // needed if --load_deferred_eagerly.
  ASSERT(!FLAG_load_deferred_eagerly);
  ASSERT(prefix.is_deferred_load());
  ASSERT(!prefix.is_loaded());
  for (intptr_t i = 0; i < deferred_prefixes_->length(); i++) {
    if ((*deferred_prefixes_)[i]->raw() == prefix.raw()) {
      return;
    }
  }
  deferred_prefixes_->Add(&LibraryPrefix::ZoneHandle(Z, prefix.raw()));
}

void ParsedFunction::AllocateVariables() {
  ASSERT(!function().IsIrregexpFunction());
  LocalScope* scope = node_sequence()->scope();
  const intptr_t num_fixed_params = function().num_fixed_parameters();
  const intptr_t num_opt_params = function().NumOptionalParameters();
  const intptr_t num_params = num_fixed_params + num_opt_params;
  // Compute start indices to parameters and locals, and the number of
  // parameters to copy.
  if (num_opt_params == 0) {
    // Parameter i will be at fp[kParamEndSlotFromFp + num_params - i] and
    // local variable j will be at fp[kFirstLocalSlotFromFp - j].
    first_parameter_index_ = kParamEndSlotFromFp + num_params;
    first_stack_local_index_ = kFirstLocalSlotFromFp;
    num_copied_params_ = 0;
  } else {
    // Parameter i will be at fp[kFirstLocalSlotFromFp - i] and local variable
    // j will be at fp[kFirstLocalSlotFromFp - num_params - j].
    first_parameter_index_ = kFirstLocalSlotFromFp;
    first_stack_local_index_ = first_parameter_index_ - num_params;
    num_copied_params_ = num_params;
  }

  // Allocate parameters and local variables, either in the local frame or
  // in the context(s).
  bool found_captured_variables = false;
  int next_free_frame_index = scope->AllocateVariables(
      first_parameter_index_, num_params, first_stack_local_index_, NULL,
      &found_captured_variables);

  // Frame indices are relative to the frame pointer and are decreasing.
  ASSERT(next_free_frame_index <= first_stack_local_index_);
  num_stack_locals_ = first_stack_local_index_ - next_free_frame_index;
}

struct CatchParamDesc {
  CatchParamDesc()
      : token_pos(TokenPosition::kNoSource),
        type(NULL),
        name(NULL),
        var(NULL) {}
  TokenPosition token_pos;
  const AbstractType* type;
  const String* name;
  LocalVariable* var;
};

void ParsedFunction::AllocateIrregexpVariables(intptr_t num_stack_locals) {
  ASSERT(function().IsIrregexpFunction());
  ASSERT(function().NumOptionalParameters() == 0);
  const intptr_t num_params = function().num_fixed_parameters();
  ASSERT(num_params == RegExpMacroAssembler::kParamCount);
  // Compute start indices to parameters and locals, and the number of
  // parameters to copy.
  // Parameter i will be at fp[kParamEndSlotFromFp + num_params - i] and
  // local variable j will be at fp[kFirstLocalSlotFromFp - j].
  first_parameter_index_ = kParamEndSlotFromFp + num_params;
  first_stack_local_index_ = kFirstLocalSlotFromFp;
  num_copied_params_ = 0;

  // Frame indices are relative to the frame pointer and are decreasing.
  num_stack_locals_ = num_stack_locals;
}

struct Parser::Block : public ZoneAllocated {
  Block(Block* outer_block, LocalScope* local_scope, SequenceNode* seq)
      : parent(outer_block), scope(local_scope), statements(seq) {
    ASSERT(scope != NULL);
    ASSERT(statements != NULL);
  }
  Block* parent;  // Enclosing block, or NULL if outermost.
  LocalScope* scope;
  SequenceNode* statements;
};

// Class which describes an inlined finally block which is used to generate
// inlined code for the finally blocks when there is an exit from a try
// block using 'return', 'break' or 'continue'.
class Parser::TryStack : public ZoneAllocated {
 public:
  TryStack(Block* try_block, TryStack* outer_try, intptr_t try_index)
      : try_block_(try_block),
        inlined_finally_nodes_(),
        outer_try_(outer_try),
        try_index_(try_index),
        inside_catch_(false),
        inside_finally_(false) {}

  TryStack* outer_try() const { return outer_try_; }
  Block* try_block() const { return try_block_; }
  intptr_t try_index() const { return try_index_; }
  bool inside_catch() const { return inside_catch_; }
  void enter_catch() { inside_catch_ = true; }
  bool inside_finally() const { return inside_finally_; }
  void enter_finally() { inside_finally_ = true; }
  void exit_finally() { inside_finally_ = false; }

  void AddNodeForFinallyInlining(AstNode* node);
  void RemoveJumpToLabel(SourceLabel* label);
  AstNode* GetNodeToInlineFinally(int index) {
    if (0 <= index && index < inlined_finally_nodes_.length()) {
      return inlined_finally_nodes_[index];
    }
    return NULL;
  }

 private:
  Block* try_block_;
  GrowableArray<AstNode*> inlined_finally_nodes_;
  TryStack* outer_try_;
  const intptr_t try_index_;
  bool inside_catch_;    // True when parsing a catch clause of this try.
  bool inside_finally_;  // True when parsing a finally clause of an inner try
                         // of this try.

  DISALLOW_COPY_AND_ASSIGN(TryStack);
};

void Parser::TryStack::AddNodeForFinallyInlining(AstNode* node) {
  inlined_finally_nodes_.Add(node);
}

void Parser::TryStack::RemoveJumpToLabel(SourceLabel* label) {
  int i = 0;
  while (i < inlined_finally_nodes_.length()) {
    if (inlined_finally_nodes_[i]->IsJumpNode()) {
      JumpNode* jump = inlined_finally_nodes_[i]->AsJumpNode();
      if (jump->label() == label) {
        // Shift remaining entries left and delete last entry.
        for (int j = i + 1; j < inlined_finally_nodes_.length(); j++) {
          inlined_finally_nodes_[j - 1] = inlined_finally_nodes_[j];
        }
        inlined_finally_nodes_.RemoveLast();
        continue;
      }
    }
    i++;
  }
}

// For parsing a compilation unit.
Parser::Parser(const Script& script,
               const Library& library,
               TokenPosition token_pos)
    : thread_(Thread::Current()),
      isolate_(thread()->isolate()),
      allocation_space_(thread_->IsMutatorThread() ? Heap::kNew : Heap::kOld),
      script_(Script::Handle(zone(), script.raw())),
      tokens_iterator_(zone(),
                       TokenStream::Handle(zone(), script.tokens()),
                       token_pos),
      token_kind_(Token::kILLEGAL),
      current_block_(NULL),
      is_top_level_(false),
      await_is_keyword_(false),
      current_member_(NULL),
      allow_function_literals_(true),
      parsed_function_(NULL),
      innermost_function_(Function::Handle(zone())),
      literal_token_(LiteralToken::Handle(zone())),
      current_class_(Class::Handle(zone())),
      library_(Library::Handle(zone(), library.raw())),
      try_stack_(NULL),
      last_used_try_index_(0),
      unregister_pending_function_(false),
      async_temp_scope_(NULL),
      trace_indent_(0),
      recursion_counter_(0) {
  ASSERT(tokens_iterator_.IsValid());
  ASSERT(!library.IsNull());
}

// For parsing a function.
Parser::Parser(const Script& script,
               ParsedFunction* parsed_function,
               TokenPosition token_pos)
    : thread_(Thread::Current()),
      isolate_(thread()->isolate()),
      allocation_space_(thread_->IsMutatorThread() ? Heap::kNew : Heap::kOld),
      script_(Script::Handle(zone(), script.raw())),
      tokens_iterator_(zone(),
                       TokenStream::Handle(zone(), script.tokens()),
                       token_pos),
      token_kind_(Token::kILLEGAL),
      current_block_(NULL),
      is_top_level_(false),
      await_is_keyword_(false),
      current_member_(NULL),
      allow_function_literals_(true),
      parsed_function_(parsed_function),
      innermost_function_(
          Function::Handle(zone(), parsed_function->function().raw())),
      literal_token_(LiteralToken::Handle(zone())),
      current_class_(
          Class::Handle(zone(), parsed_function->function().Owner())),
      library_(Library::Handle(
          zone(),
          Class::Handle(zone(), parsed_function->function().origin())
              .library())),
      try_stack_(NULL),
      last_used_try_index_(0),
      unregister_pending_function_(false),
      async_temp_scope_(NULL),
      trace_indent_(0),
      recursion_counter_(0) {
  ASSERT(tokens_iterator_.IsValid());
  ASSERT(!current_function().IsNull());
  EnsureExpressionTemp();
}

Parser::~Parser() {
  if (unregister_pending_function_) {
    const GrowableObjectArray& pending_functions =
        GrowableObjectArray::Handle(T->pending_functions());
    ASSERT(!pending_functions.IsNull());
    ASSERT(pending_functions.Length() > 0);
    ASSERT(pending_functions.At(pending_functions.Length() - 1) ==
           current_function().raw());
    pending_functions.RemoveLast();
  }
}

// Each try in this function gets its own try index.
// See definition of RawPcDescriptors::PcDescriptor.
int16_t Parser::AllocateTryIndex() {
  if (!Utils::IsInt(16, last_used_try_index_ - 1)) {
    ReportError("too many nested try statements");
  }
  return last_used_try_index_++;
}

void Parser::SetScript(const Script& script, TokenPosition token_pos) {
  script_ = script.raw();
  tokens_iterator_.SetStream(TokenStream::Handle(Z, script.tokens()),
                             token_pos);
  token_kind_ = Token::kILLEGAL;
}

bool Parser::SetAllowFunctionLiterals(bool value) {
  bool current_value = allow_function_literals_;
  allow_function_literals_ = value;
  return current_value;
}

const Function& Parser::current_function() const {
  ASSERT(parsed_function() != NULL);
  return parsed_function()->function();
}

const Function& Parser::innermost_function() const {
  return innermost_function_;
}

int Parser::FunctionLevel() const {
  if (current_block_ != NULL) {
    return current_block_->scope->function_level();
  }
  return 0;
}

const Class& Parser::current_class() const {
  return current_class_;
}

void Parser::set_current_class(const Class& value) {
  current_class_ = value.raw();
}

void Parser::SetPosition(TokenPosition position) {
  tokens_iterator_.SetCurrentPosition(position);
  token_kind_ = Token::kILLEGAL;
  prev_token_pos_ = position;
}

// Set state and increments generational count so that thge background compiler
// can detect if loading/top-level-parsing occured during compilation.
class TopLevelParsingScope : public StackResource {
 public:
  explicit TopLevelParsingScope(Thread* thread) : StackResource(thread) {
    isolate()->IncrTopLevelParsingCount();
  }
  ~TopLevelParsingScope() {
    isolate()->DecrTopLevelParsingCount();
    isolate()->IncrLoadingInvalidationGen();
  }
};

void Parser::ParseCompilationUnit(const Library& library,
                                  const Script& script) {
  Thread* thread = Thread::Current();
  ASSERT(thread->long_jump_base()->IsSafeToJump());
  CSTAT_TIMER_SCOPE(thread, parser_timer);
#ifndef PRODUCT
  VMTagScope tagScope(thread, VMTag::kCompileTopLevelTagId);
  TimelineDurationScope tds(thread, Timeline::GetCompilerStream(),
                            "CompileTopLevel");
  if (tds.enabled()) {
    tds.SetNumArguments(1);
    tds.CopyArgument(0, "script", String::Handle(script.url()).ToCString());
  }
#endif

  TopLevelParsingScope scope(thread);
  Parser parser(script, library, TokenPosition::kMinSource);
  parser.ParseTopLevel();
}

void Parser::ComputeCurrentToken() {
  ASSERT(token_kind_ == Token::kILLEGAL);
  token_kind_ = tokens_iterator_.CurrentTokenKind();
  if (token_kind_ == Token::kERROR) {
    ReportError(TokenPos(), "%s", CurrentLiteral()->ToCString());
  }
}

Token::Kind Parser::LookaheadToken(int num_tokens) {
  return tokens_iterator_.LookaheadTokenKind(num_tokens);
}

String* Parser::CurrentLiteral() const {
  String& result = String::ZoneHandle(Z, tokens_iterator_.CurrentLiteral());
  return &result;
}

RawDouble* Parser::CurrentDoubleLiteral() const {
  literal_token_ ^= tokens_iterator_.CurrentToken();
  ASSERT(literal_token_.kind() == Token::kDOUBLE);
  return Double::RawCast(literal_token_.value());
}

RawInteger* Parser::CurrentIntegerLiteral() const {
  literal_token_ ^= tokens_iterator_.CurrentToken();
  ASSERT(literal_token_.kind() == Token::kINTEGER);
  RawInteger* ri = Integer::RawCast(literal_token_.value());
  return ri;
}

struct ParamDesc {
  ParamDesc()
      : type(NULL),
        name_pos(TokenPosition::kNoSource),
        name(NULL),
        default_value(NULL),
        metadata(NULL),
        var(NULL),
        is_final(false),
        is_field_initializer(false),
        has_explicit_type(false),
        is_covariant(false) {}
  const AbstractType* type;
  TokenPosition name_pos;
  const String* name;
  const Instance* default_value;  // NULL if not an optional parameter.
  const Object* metadata;  // NULL if no metadata or metadata not evaluated.
  LocalVariable* var;      // Scope variable allocated for this parameter.
  bool is_final;
  bool is_field_initializer;
  bool has_explicit_type;
  bool is_covariant;
};

struct ParamList {
  ParamList() { Clear(); }

  void Clear() {
    num_fixed_parameters = 0;
    num_optional_parameters = 0;
    has_optional_positional_parameters = false;
    has_optional_named_parameters = false;
    has_explicit_default_values = false;
    has_field_initializer = false;
    has_covariant = false;
    implicitly_final = false;
    skipped = false;
    this->parameters = new ZoneGrowableArray<ParamDesc>();
  }

  void AddFinalParameter(TokenPosition name_pos,
                         const String* name,
                         const AbstractType* type) {
    this->num_fixed_parameters++;
    ParamDesc param;
    param.name_pos = name_pos;
    param.name = name;
    param.is_final = true;
    param.type = type;
    this->parameters->Add(param);
  }

  void AddReceiver(const AbstractType* receiver_type, TokenPosition token_pos) {
    ASSERT(this->parameters->is_empty());
    AddFinalParameter(token_pos, &Symbols::This(), receiver_type);
  }

  void EraseParameterTypes() {
    const int num_parameters = parameters->length();
    for (int i = 0; i < num_parameters; i++) {
      (*parameters)[i].type = &Object::dynamic_type();
    }
  }

  // Make the parameter variables visible/invisible.
  // Field initializer parameters are always invisible.
  void SetInvisible(bool invisible) {
    const intptr_t num_params = parameters->length();
    for (int i = 0; i < num_params; i++) {
      ParamDesc& param = (*parameters)[i];
      ASSERT(param.var != NULL);
      if (FLAG_initializing_formal_access || !param.is_field_initializer) {
        param.var->set_invisible(invisible);
      }
    }
  }

  void HideInitFormals() {
    const intptr_t num_params = parameters->length();
    for (int i = 0; i < num_params; i++) {
      ParamDesc& param = (*parameters)[i];
      if (param.is_field_initializer) {
        ASSERT(param.var != NULL);
        param.var->set_invisible(true);
      }
    }
  }

  void SetImplicitlyFinal() { implicitly_final = true; }

  int num_fixed_parameters;
  int num_optional_parameters;
  bool has_optional_positional_parameters;
  bool has_optional_named_parameters;
  bool has_explicit_default_values;
  bool has_field_initializer;
  bool has_covariant;
  bool implicitly_final;
  bool skipped;
  ZoneGrowableArray<ParamDesc>* parameters;
};

struct MemberDesc {
  MemberDesc() { Clear(); }

  void Clear() {
    has_abstract = false;
    has_external = false;
    has_covariant = false;
    has_final = false;
    has_const = false;
    has_static = false;
    has_var = false;
    has_factory = false;
    has_operator = false;
    has_native = false;
    metadata_pos = TokenPosition::kNoSource;
    operator_token = Token::kILLEGAL;
    type = NULL;
    name_pos = TokenPosition::kNoSource;
    name = NULL;
    redirect_name = NULL;
    dict_name = NULL;
    params.Clear();
    kind = RawFunction::kRegularFunction;
    field_ = NULL;
  }

  bool IsConstructor() const {
    return (kind == RawFunction::kConstructor) && !has_static;
  }
  bool IsFactory() const {
    return (kind == RawFunction::kConstructor) && has_static;
  }
  bool IsFactoryOrConstructor() const {
    return (kind == RawFunction::kConstructor);
  }
  bool IsGetter() const { return kind == RawFunction::kGetterFunction; }
  bool IsSetter() const { return kind == RawFunction::kSetterFunction; }
  const char* ToCString() const {
    if (field_ != NULL) {
      return "field";
    } else if (IsConstructor()) {
      return "constructor";
    } else if (IsFactory()) {
      return "factory";
    } else if (IsGetter()) {
      return "getter";
    } else if (IsSetter()) {
      return "setter";
    }
    return "method";
  }
  String* DictName() const { return (dict_name != NULL) ? dict_name : name; }
  bool has_abstract;
  bool has_external;
  bool has_covariant;
  bool has_final;
  bool has_const;
  bool has_static;
  bool has_var;
  bool has_factory;
  bool has_operator;
  bool has_native;
  TokenPosition metadata_pos;
  Token::Kind operator_token;
  const AbstractType* type;
  TokenPosition name_pos;
  TokenPosition decl_begin_pos;
  String* name;
  // For constructors: NULL or name of redirected to constructor.
  String* redirect_name;
  // dict_name is the name used for the class namespace, if it
  // differs from 'name'.
  // For constructors: NULL for unnamed constructor,
  // identifier after classname for named constructors.
  // For getters and setters: unmangled name.
  String* dict_name;
  ParamList params;
  RawFunction::Kind kind;
  // NULL for functions, field object for static or instance fields.
  Field* field_;
};

class ClassDesc : public ValueObject {
 public:
  ClassDesc(Zone* zone,
            const Class& cls,
            const String& cls_name,
            bool is_interface,
            TokenPosition token_pos)
      : zone_(zone),
        clazz_(cls),
        class_name_(cls_name),
        token_pos_(token_pos),
        functions_(zone, 4),
        fields_(zone, 4) {}

  void AddFunction(const Function& function) {
    functions_.Add(&Function::ZoneHandle(zone_, function.raw()));
  }

  const GrowableArray<const Function*>& functions() const { return functions_; }

  void AddField(const Field& field) {
    fields_.Add(&Field::ZoneHandle(zone_, field.raw()));
  }

  const GrowableArray<const Field*>& fields() const { return fields_; }

  const Class& clazz() const { return clazz_; }

  const String& class_name() const { return class_name_; }

  bool has_constructor() const {
    for (int i = 0; i < functions_.length(); i++) {
      const Function* func = functions_.At(i);
      if (func->kind() == RawFunction::kConstructor) {
        return true;
      }
    }
    return false;
  }

  TokenPosition token_pos() const { return token_pos_; }

  void AddMember(const MemberDesc& member) { members_.Add(member); }

  const GrowableArray<MemberDesc>& members() const { return members_; }

  MemberDesc* LookupMember(const String& name) const {
    for (int i = 0; i < members_.length(); i++) {
      if (name.Equals(*members_[i].name)) {
        return &members_[i];
      }
    }
    return NULL;
  }

  RawArray* MakeFunctionsArray() {
    const intptr_t len = functions_.length();
    const Array& res = Array::Handle(zone_, Array::New(len, Heap::kOld));
    for (intptr_t i = 0; i < len; i++) {
      res.SetAt(i, *functions_[i]);
    }
    return res.raw();
  }

 private:
  Zone* zone_;
  const Class& clazz_;
  const String& class_name_;
  TokenPosition token_pos_;  // Token index of "class" keyword.
  GrowableArray<const Function*> functions_;
  GrowableArray<const Field*> fields_;
  GrowableArray<MemberDesc> members_;
};

class TopLevel : public ValueObject {
 public:
  explicit TopLevel(Zone* zone)
      : zone_(zone), fields_(zone, 4), functions_(zone, 4) {}

  void AddField(const Field& field) {
    fields_.Add(&Field::ZoneHandle(zone_, field.raw()));
  }

  void AddFunction(const Function& function) {
    functions_.Add(&Function::ZoneHandle(zone_, function.raw()));
  }

  const GrowableArray<const Field*>& fields() const { return fields_; }

  const GrowableArray<const Function*>& functions() const { return functions_; }

 private:
  Zone* zone_;
  GrowableArray<const Field*> fields_;
  GrowableArray<const Function*> functions_;
};

void Parser::ParseClass(const Class& cls) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const int64_t num_tokes_before = STAT_VALUE(thread, num_tokens_consumed);
#ifndef PRODUCT
  TimelineDurationScope tds(thread, Timeline::GetCompilerStream(),
                            "ParseClass");
  if (tds.enabled()) {
    tds.SetNumArguments(1);
    tds.CopyArgument(0, "class", String::Handle(cls.Name()).ToCString());
  }
#endif
  if (!cls.is_synthesized_class()) {
    ASSERT(thread->long_jump_base()->IsSafeToJump());
    CSTAT_TIMER_SCOPE(thread, parser_timer);
    const Script& script = Script::Handle(zone, cls.script());
    const Library& lib = Library::Handle(zone, cls.library());
    Parser parser(script, lib, cls.token_pos());
    parser.ParseClassDefinition(cls);
  } else if (cls.is_enum_class()) {
    ASSERT(thread->long_jump_base()->IsSafeToJump());
    CSTAT_TIMER_SCOPE(thread, parser_timer);
    const Script& script = Script::Handle(zone, cls.script());
    const Library& lib = Library::Handle(zone, cls.library());
    Parser parser(script, lib, cls.token_pos());
    parser.ParseEnumDefinition(cls);
  }
  const int64_t num_tokes_after = STAT_VALUE(thread, num_tokens_consumed);
  INC_STAT(thread, num_class_tokens, num_tokes_after - num_tokes_before);
}

bool Parser::FieldHasFunctionLiteralInitializer(const Field& field,
                                                TokenPosition* start,
                                                TokenPosition* end) {
  if (!field.has_initializer()) {
    return false;
  }
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Class& cls = Class::Handle(zone, field.Owner());
  const Script& script = Script::Handle(zone, cls.script());
  const Library& lib = Library::Handle(zone, cls.library());
  Parser parser(script, lib, field.token_pos());
  return parser.GetFunctionLiteralInitializerRange(field, start, end);
}

bool Parser::GetFunctionLiteralInitializerRange(const Field& field,
                                                TokenPosition* start,
                                                TokenPosition* end) {
  ASSERT(field.has_initializer());
  // Since |field| has an initializer, skip until '='.
  while (CurrentToken() != Token::kASSIGN) {
    ConsumeToken();
  }
  // Skip past the '=' as well.
  ConsumeToken();

  *start = TokenPos();
  if (IsFunctionLiteral()) {
    SkipExpr();
    *end = PrevTokenPos();
    return true;
  }

  return false;
}

RawObject* Parser::ParseFunctionParameters(const Function& func) {
  ASSERT(!func.IsNull());
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* thread = Thread::Current();
    StackZone stack_zone(thread);
    Zone* zone = stack_zone.GetZone();
    const Script& script = Script::Handle(zone, func.script());
    const Class& owner = Class::Handle(zone, func.Owner());
    ASSERT(!owner.IsNull());
    ParsedFunction* parsed_function =
        new ParsedFunction(thread, Function::ZoneHandle(zone, func.raw()));
    Parser parser(script, parsed_function, func.token_pos());
    parser.SkipFunctionPreamble();
    const bool use_function_type_syntax = false;
    const bool allow_explicit_default_values = true;
    const bool evaluate_metadata = true;
    ParamList params;
    parser.ParseFormalParameterList(use_function_type_syntax,
                                    allow_explicit_default_values,
                                    evaluate_metadata, &params);
    ParamDesc* param = params.parameters->data();
    const int param_cnt =
        params.num_fixed_parameters + params.num_optional_parameters;
    const Array& param_descriptor =
        Array::Handle(Array::New(param_cnt * kParameterEntrySize, Heap::kOld));
    for (int i = 0, j = 0; i < param_cnt; i++, j += kParameterEntrySize) {
      param_descriptor.SetAt(j + kParameterIsFinalOffset,
                             param[i].is_final ? Bool::True() : Bool::False());
      param_descriptor.SetAt(j + kParameterDefaultValueOffset,
                             (param[i].default_value == NULL)
                                 ? Object::null_instance()
                                 : *(param[i].default_value));
      const Object* metadata = param[i].metadata;
      if ((metadata != NULL) && (*metadata).IsError()) {
        return metadata->raw();  // Error evaluating the metadata.
      }
      param_descriptor.SetAt(j + kParameterMetadataOffset,
                             (param[i].metadata == NULL)
                                 ? Object::null_instance()
                                 : *(param[i].metadata));
    }
    return param_descriptor.raw();
  } else {
    Thread* thread = Thread::Current();
    Error& error = Error::Handle();
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Object::null();
}

bool Parser::ParseFormalParameters(const Function& func, ParamList* params) {
  ASSERT(!func.IsNull());
  // This is currently only used for constructors. To handle all kinds
  // of functions, special cases for getters and possibly other kinds
  // need to be added.
  ASSERT(func.kind() == RawFunction::kConstructor);
  ASSERT(!func.IsRedirectingFactory());
  // Implicit constructors have no source, no user-defined formal parameters.
  if (func.IsImplicitConstructor()) {
    return true;
  }
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    const Script& script = Script::Handle(func.script());
    const Class& owner = Class::Handle(func.Owner());
    ASSERT(!owner.IsNull());
    ParsedFunction* parsed_function =
        new ParsedFunction(Thread::Current(), Function::ZoneHandle(func.raw()));
    Parser parser(script, parsed_function, func.token_pos());
    parser.SkipFunctionPreamble();
    const bool use_function_type_syntax = false;
    const bool allow_explicit_default_values = true;
    const bool evaluate_metadata = true;
    parser.ParseFormalParameterList(use_function_type_syntax,
                                    allow_explicit_default_values,
                                    evaluate_metadata, params);
    return true;
  } else {
    Thread::Current()->clear_sticky_error();
    params->Clear();
    return false;
  }
  UNREACHABLE();
  return false;
}

void Parser::ParseFunction(ParsedFunction* parsed_function) {
  Thread* thread = parsed_function->thread();
  ASSERT(thread == Thread::Current());
  Zone* zone = thread->zone();
  CSTAT_TIMER_SCOPE(thread, parser_timer);
  INC_STAT(thread, num_functions_parsed, 1);
#ifndef PRODUCT
  VMTagScope tagScope(thread, VMTag::kCompileParseFunctionTagId,
                      FLAG_profile_vm);
  TimelineDurationScope tds(thread, Timeline::GetCompilerStream(),
                            "ParseFunction");
#endif  // !PRODUCT
  ASSERT(thread->long_jump_base()->IsSafeToJump());
  ASSERT(parsed_function != NULL);
  const Function& func = parsed_function->function();
  const Script& script = Script::Handle(zone, func.script());
  Parser parser(script, parsed_function, func.token_pos());
#ifndef PRODUCT
  if (tds.enabled()) {
    tds.SetNumArguments(1);
    tds.CopyArgument(0, "function", String::Handle(func.name()).ToCString());
  }
#endif  // !PRODUCT
  SequenceNode* node_sequence = NULL;
  switch (func.kind()) {
    case RawFunction::kImplicitClosureFunction:
      node_sequence = parser.ParseImplicitClosure(func);
      break;
    case RawFunction::kClosureFunction:
    case RawFunction::kRegularFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction:
    case RawFunction::kConstructor:
      // The call to a redirecting factory is redirected.
      ASSERT(!func.IsRedirectingFactory());
      if (!func.IsImplicitConstructor()) {
        parser.SkipFunctionPreamble();
      }
      node_sequence = parser.ParseFunc(func, false);
      break;
    case RawFunction::kImplicitGetter:
      ASSERT(!func.is_static());
      node_sequence = parser.ParseInstanceGetter(func);
      break;
    case RawFunction::kImplicitSetter:
      ASSERT(!func.is_static());
      node_sequence = parser.ParseInstanceSetter(func);
      break;
    case RawFunction::kImplicitStaticFinalGetter:
      node_sequence = parser.ParseStaticFinalGetter(func);
      INC_STAT(thread, num_implicit_final_getters, 1);
      break;
    case RawFunction::kMethodExtractor:
      node_sequence = parser.ParseMethodExtractor(func);
      INC_STAT(thread, num_method_extractors, 1);
      break;
    case RawFunction::kNoSuchMethodDispatcher:
      node_sequence = parser.ParseNoSuchMethodDispatcher(func);
      break;
    case RawFunction::kInvokeFieldDispatcher:
      node_sequence = parser.ParseInvokeFieldDispatcher(func);
      break;
    case RawFunction::kIrregexpFunction:
      UNREACHABLE();  // Irregexp functions have their own parser.
    default:
      UNREACHABLE();
  }

  if (parsed_function->has_expression_temp_var()) {
    node_sequence->scope()->AddVariable(parsed_function->expression_temp_var());
  }
  node_sequence->scope()->AddVariable(parsed_function->current_context_var());
  if (parsed_function->has_finally_return_temp_var()) {
    node_sequence->scope()->AddVariable(
        parsed_function->finally_return_temp_var());
  }
  parsed_function->SetNodeSequence(node_sequence);

  // The instantiators may be required at run time for generic type checks or
  // allocation of generic types.
  if (parser.IsInstantiatorRequired()) {
    // In the case of a local function, only set the instantiator if the
    // receiver (or type arguments parameter of a factory) was captured.
    LocalVariable* instantiator = NULL;
    const bool kTestOnly = true;
    if (parser.current_function().IsInFactoryScope()) {
      instantiator = parser.LookupTypeArgumentsParameter(node_sequence->scope(),
                                                         kTestOnly);
    } else {
      instantiator = parser.LookupReceiver(node_sequence->scope(), kTestOnly);
    }
    if (!parser.current_function().IsLocalFunction() ||
        ((instantiator != NULL) && instantiator->is_captured())) {
      parsed_function->set_instantiator(instantiator);
    }
  }
  // ParseFunc has recorded the generic function type arguments variable.
  ASSERT(!FLAG_reify_generic_functions ||
         !parser.current_function().IsGeneric() ||
         (parsed_function->function_type_arguments() != NULL));
}

RawObject* Parser::ParseMetadata(const Field& meta_data) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* thread = Thread::Current();
    StackZone stack_zone(thread);
    Zone* zone = stack_zone.GetZone();
    const Class& owner_class = Class::Handle(zone, meta_data.Owner());
    const Script& script = Script::Handle(zone, meta_data.Script());
    const TokenPosition token_pos = meta_data.token_pos();
    // Parsing metadata can involve following paths in the parser that are
    // normally used for expressions and assume current_function is non-null,
    // so we create a fake function to use as the current_function rather than
    // scattering special cases throughout the parser.
    const Function& fake_function = Function::ZoneHandle(
        zone,
        Function::New(Symbols::At(), RawFunction::kRegularFunction,
                      true,   // is_static
                      false,  // is_const
                      false,  // is_abstract
                      false,  // is_external
                      false,  // is_native
                      Object::Handle(zone, meta_data.RawOwner()), token_pos));
    fake_function.set_is_debuggable(false);
    ParsedFunction* parsed_function = new ParsedFunction(thread, fake_function);
    Parser parser(script, parsed_function, token_pos);
    parser.set_current_class(owner_class);
    parser.OpenFunctionBlock(fake_function);

    RawObject* metadata = parser.EvaluateMetadata();
    return metadata;
  } else {
    Thread* thread = Thread::Current();
    StackZone stack_zone(thread);
    Zone* zone = stack_zone.GetZone();
    Error& error = Error::Handle(zone);
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Object::null();
}

RawArray* Parser::EvaluateMetadata() {
  CheckToken(Token::kAT, "Metadata character '@' expected");
  GrowableObjectArray& meta_values =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New(Heap::kOld));
  while (CurrentToken() == Token::kAT) {
    ConsumeToken();
    TokenPosition expr_pos = TokenPos();
    if (!IsIdentifier()) {
      ExpectIdentifier("identifier expected");
    }
    // Reject expressions with deferred library prefix eagerly.
    Object& obj =
        Object::Handle(Z, library_.LookupLocalObject(*CurrentLiteral()));
    if (!obj.IsNull() && obj.IsLibraryPrefix()) {
      if (LibraryPrefix::Cast(obj).is_deferred_load()) {
        ReportError("Metadata must be compile-time constant");
      }
    }
    AstNode* expr = NULL;
    if ((LookaheadToken(1) == Token::kLPAREN) ||
        ((LookaheadToken(1) == Token::kPERIOD) &&
         (LookaheadToken(3) == Token::kLPAREN)) ||
        ((LookaheadToken(1) == Token::kPERIOD) &&
         (LookaheadToken(3) == Token::kPERIOD) &&
         (LookaheadToken(5) == Token::kLPAREN))) {
      expr = ParseNewOperator(Token::kCONST);
    } else {
      // Can be x, C.x, or L.C.x.
      expr = ParsePrimary();  // Consumes x, C or L.C.
      Class& cls = Class::Handle(Z);
      if (expr->IsPrimaryNode()) {
        PrimaryNode* primary_node = expr->AsPrimaryNode();
        if (primary_node->primary().IsClass()) {
          // If the primary node referred to a class we are loading a
          // qualified static field.
          cls ^= primary_node->primary().raw();
        } else {
          ReportError(expr_pos,
                      "Metadata expressions must refer to a const field "
                      "or constructor");
        }
      }
      if (CurrentToken() == Token::kPERIOD) {
        // C.x or L.C.X.
        if (cls.IsNull()) {
          ReportError(expr_pos,
                      "Metadata expressions must refer to a const field "
                      "or constructor");
        }
        ConsumeToken();
        const TokenPosition ident_pos = TokenPos();
        String* ident = ExpectIdentifier("identifier expected");
        const Field& field = Field::Handle(Z, cls.LookupStaticField(*ident));
        if (field.IsNull()) {
          ReportError(ident_pos, "Class '%s' has no field '%s'",
                      cls.ToCString(), ident->ToCString());
        }
        if (!field.is_const()) {
          ReportError(ident_pos, "Field '%s' of class '%s' is not const",
                      ident->ToCString(), cls.ToCString());
        }
        expr = GenerateStaticFieldLookup(field, ident_pos);
      }
    }
    if (expr->EvalConstExpr() == NULL) {
      ReportError(expr_pos, "expression must be a compile-time constant");
    }
    const Instance& val = EvaluateConstExpr(expr_pos, expr);
    meta_values.Add(val, Heap::kOld);
  }
  return Array::MakeFixedLength(meta_values);
}

SequenceNode* Parser::ParseStaticInitializer() {
  ExpectIdentifier("field name expected");
  CheckToken(Token::kASSIGN, "field initialier expected");
  ConsumeToken();
  OpenFunctionBlock(parsed_function()->function());
  TokenPosition expr_pos = TokenPos();
  AstNode* expr = ParseExpr(kAllowConst, kConsumeCascades);
  ReturnNode* ret = new (Z) ReturnNode(expr_pos, expr);
  current_block_->statements->Add(ret);
  return CloseBlock();
}

ParsedFunction* Parser::ParseStaticFieldInitializer(const Field& field) {
  ASSERT(field.is_static());
  Thread* thread = Thread::Current();
  // TODO(koda): Should there be a StackZone here?
  Zone* zone = thread->zone();
#ifndef PRODUCT
  VMTagScope tagScope(thread, VMTag::kCompileParseFunctionTagId,
                      FLAG_profile_vm);
  TimelineDurationScope tds(thread, Timeline::GetCompilerStream(),
                            "ParseStaticFieldInitializer");
#endif  // !PRODUCT

  const String& field_name = String::Handle(zone, field.name());
  String& init_name = String::Handle(
      zone, Symbols::FromConcat(thread, Symbols::InitPrefix(), field_name));

  const Script& script = Script::Handle(zone, field.Script());
  Object& initializer_owner = Object::Handle(field.Owner());
  initializer_owner = PatchClass::New(Class::Handle(field.Owner()), script);

  const Function& initializer = Function::ZoneHandle(
      zone, Function::New(init_name, RawFunction::kImplicitStaticFinalGetter,
                          true,   // static
                          false,  // !const
                          false,  // !abstract
                          false,  // !external
                          false,  // !native
                          initializer_owner, field.token_pos()));
  initializer.set_result_type(AbstractType::Handle(zone, field.type()));
  // Static initializer functions are hidden from the user.
  // Since they are only executed once, we avoid inlining them.
  // After the field is initialized, the compiler can eliminate
  // the call to the static initializer.
  initializer.set_is_reflectable(false);
  initializer.set_is_debuggable(false);
  initializer.set_is_inlinable(false);

  ParsedFunction* parsed_function = new ParsedFunction(thread, initializer);
  Parser parser(script, parsed_function, field.token_pos());

  SequenceNode* body = parser.ParseStaticInitializer();
  parsed_function->SetNodeSequence(body);

  if (parsed_function->has_expression_temp_var()) {
    body->scope()->AddVariable(parsed_function->expression_temp_var());
  }
  body->scope()->AddVariable(parsed_function->current_context_var());
  if (parsed_function->has_finally_return_temp_var()) {
    body->scope()->AddVariable(parsed_function->finally_return_temp_var());
  }
  // The instantiator is not required in a static expression.
  ASSERT(!parser.IsInstantiatorRequired());

  return parsed_function;
}

SequenceNode* Parser::ParseStaticFinalGetter(const Function& func) {
  TRACE_PARSER("ParseStaticFinalGetter");
  ASSERT(func.num_fixed_parameters() == 0);  // static.
  ASSERT(!func.HasOptionalParameters());
  ASSERT(AbstractType::Handle(Z, func.result_type()).IsResolved());
  OpenFunctionBlock(func);
  TokenPosition ident_pos = TokenPos();
  const String& field_name = *ExpectIdentifier("field name expected");
  const Class& field_class = Class::Handle(Z, func.Owner());
  const Field& field =
      Field::ZoneHandle(Z, field_class.LookupStaticField(field_name));
  ASSERT(!field.IsNull());

  // Static final fields must have an initializer.
  ExpectToken(Token::kASSIGN);

  const TokenPosition expr_pos = TokenPos();
  if (field.is_const()) {
    // We don't want to use ParseConstExpr() here because we don't want
    // the constant folding code to create, compile and execute a code
    // fragment to evaluate the expression. Instead, we just make sure
    // the static const field initializer is a constant expression and
    // leave the evaluation to the getter function.
    AstNode* expr = ParseExpr(kAllowConst, kConsumeCascades);
    // This getter will only be called once at compile time.
    if (expr->EvalConstExpr() == NULL) {
      ReportError(expr_pos, "initializer is not a valid compile-time constant");
    }
    ReturnNode* return_node = new ReturnNode(ident_pos, expr);
    current_block_->statements->Add(return_node);
  } else {
    // This getter may be called each time the static field is accessed.
    // Call runtime support to parse and evaluate the initializer expression.
    // The runtime function will detect circular dependencies in expressions
    // and handle errors while evaluating the expression.
    current_block_->statements->Add(new (Z)
                                        InitStaticFieldNode(ident_pos, field));
    ReturnNode* return_node =
        new ReturnNode(ident_pos, new LoadStaticFieldNode(ident_pos, field));
    current_block_->statements->Add(return_node);
  }
  return CloseBlock();
}

// Create AstNodes for an implicit instance getter method:
//   LoadLocalNode 0 ('this');
//   LoadInstanceFieldNode (field_name);
//   ReturnNode (field's value);
SequenceNode* Parser::ParseInstanceGetter(const Function& func) {
  TRACE_PARSER("ParseInstanceGetter");
  ParamList params;
  // func.token_pos() points to the name of the field.
  const TokenPosition ident_pos = func.token_pos();
  ASSERT(current_class().raw() == func.Owner());
  params.AddReceiver(ReceiverType(current_class()), ident_pos);
  ASSERT(func.num_fixed_parameters() == 1);  // receiver.
  ASSERT(!func.HasOptionalParameters());
  ASSERT(AbstractType::Handle(Z, func.result_type()).IsResolved());

  // Build local scope for function and populate with the formal parameters.
  OpenFunctionBlock(func);
  AddFormalParamsToScope(&params, current_block_->scope);

  // Receiver is local 0.
  LocalVariable* receiver = current_block_->scope->VariableAt(0);
  LoadLocalNode* load_receiver = new LoadLocalNode(ident_pos, receiver);
  String& field_name = String::Handle(Z, func.name());
  field_name = Field::NameFromGetter(field_name);

  const Class& field_class = Class::Handle(Z, func.Owner());
  const Field& field =
      Field::ZoneHandle(Z, field_class.LookupInstanceField(field_name));
  ASSERT(!field.IsNull());

  LoadInstanceFieldNode* load_field =
      new LoadInstanceFieldNode(ident_pos, load_receiver, field);

  ReturnNode* return_node = new ReturnNode(ST(ident_pos), load_field);
  current_block_->statements->Add(return_node);
  return CloseBlock();
}

// Create AstNodes for an implicit instance setter method:
//   LoadLocalNode 0 ('this')
//   LoadLocalNode 1 ('value')
//   SetInstanceField (field_name);
//   ReturnNode (void);
SequenceNode* Parser::ParseInstanceSetter(const Function& func) {
  TRACE_PARSER("ParseInstanceSetter");
  // func.token_pos() points to the name of the field.
  const TokenPosition ident_pos = func.token_pos();
  const String& field_name = *CurrentLiteral();
  const Class& field_class = Class::ZoneHandle(Z, func.Owner());
  const Field& field =
      Field::ZoneHandle(Z, field_class.LookupInstanceField(field_name));
  const AbstractType& field_type = AbstractType::ZoneHandle(Z, field.type());

  ParamList params;
  ASSERT(current_class().raw() == func.Owner());
  params.AddReceiver(ReceiverType(current_class()), ident_pos);
  params.AddFinalParameter(ident_pos, &Symbols::Value(), &field_type);
  ASSERT(func.num_fixed_parameters() == 2);  // receiver, value.
  ASSERT(!func.HasOptionalParameters());
  ASSERT(AbstractType::Handle(Z, func.result_type()).IsVoidType());

  // Build local scope for function and populate with the formal parameters.
  OpenFunctionBlock(func);
  AddFormalParamsToScope(&params, current_block_->scope);

  LoadLocalNode* receiver =
      new LoadLocalNode(ident_pos, current_block_->scope->VariableAt(0));
  LoadLocalNode* value =
      new LoadLocalNode(ident_pos, current_block_->scope->VariableAt(1));

  EnsureExpressionTemp();
  StoreInstanceFieldNode* store_field =
      new StoreInstanceFieldNode(ident_pos, receiver, field, value,
                                 /* is_initializer = */ false);
  current_block_->statements->Add(store_field);
  current_block_->statements->Add(new ReturnNode(ST(ident_pos)));
  return CloseBlock();
}

SequenceNode* Parser::ParseImplicitClosure(const Function& func) {
  TRACE_PARSER("ParseImplicitClosure");
  TokenPosition token_pos = func.token_pos();

  OpenFunctionBlock(func);

  const Function& parent = Function::Handle(func.parent_function());
  intptr_t type_args_len = 0;  // Length of type args vector passed to parent.
  LocalVariable* type_args_var = NULL;
  if (FLAG_reify_generic_functions) {
    // The parent function of an implicit closure is the original function, i.e.
    // non-closurized. It is not an enclosing function in the usual sense of a
    // parent function. Do not set parent_type_arguments() in parsed_function_.
    ASSERT(func.IsGeneric() == parent.IsGeneric());

    if (func.IsGeneric()) {
      type_args_len = func.NumTypeParameters();
      // Insert function type arguments variable to scope.
      type_args_var = new (Z) LocalVariable(
          TokenPosition::kNoSource, TokenPosition::kNoSource,
          Symbols::FunctionTypeArgumentsVar(), Object::dynamic_type());
      current_block_->scope->AddVariable(type_args_var);
      ASSERT(FunctionLevel() == 0);
      parsed_function_->set_function_type_arguments(type_args_var);
    }
  }

  ParamList params;
  params.AddFinalParameter(token_pos, &Symbols::ClosureParameter(),
                           &Object::dynamic_type());

  if (parent.IsImplicitSetterFunction()) {
    const TokenPosition ident_pos = func.token_pos();
    ASSERT(IsIdentifier());
    params.AddFinalParameter(ident_pos, &Symbols::Value(),
                             &Object::dynamic_type());
    ASSERT(func.num_fixed_parameters() == 2);  // closure, value.
  } else if (!parent.IsGetterFunction() && !parent.IsImplicitGetterFunction()) {
    // NOTE: For the `kernel -> flowgraph` we don't use the parser.
    if (parent.kernel_offset() <= 0) {
      SkipFunctionPreamble();
      const bool use_function_type_syntax = false;
      const bool allow_explicit_default_values = true;
      const bool evaluate_metadata = false;
      ParseFormalParameterList(use_function_type_syntax,
                               allow_explicit_default_values, evaluate_metadata,
                               &params);
      FinalizeFormalParameterTypes(&params);
      SetupDefaultsForOptionalParams(params);
    }
  }

  // Populate function scope with the formal parameters.
  LocalScope* scope = current_block_->scope;
  AddFormalParamsToScope(&params, scope);

  ArgumentListNode* func_args =
      new ArgumentListNode(token_pos, type_args_var, type_args_len);
  if (!func.is_static()) {
    func_args->Add(LoadReceiver(token_pos));
  }
  // Skip implicit parameter at 0.
  for (intptr_t i = 1; i < func.NumParameters(); ++i) {
    func_args->Add(new LoadLocalNode(token_pos, scope->VariableAt(i)));
  }

  if (func.HasOptionalNamedParameters()) {
    // TODO(srdjan): Must allocate array in old space, since it
    // runs in background compiler. Find a better way.
    const Array& arg_names =
        Array::ZoneHandle(Array::New(func.NumOptionalParameters(), Heap::kOld));
    for (intptr_t i = 0; i < arg_names.Length(); ++i) {
      intptr_t index = func.num_fixed_parameters() + i;
      arg_names.SetAt(i, String::Handle(func.ParameterNameAt(index)));
    }
    func_args->set_names(arg_names);
  }

  const String& func_name = String::ZoneHandle(parent.name());
  const Class& owner = Class::Handle(parent.Owner());
  Function& target = Function::ZoneHandle(owner.LookupFunction(func_name));

  if (target.raw() != parent.raw()) {
    NOT_IN_PRODUCT(ASSERT(Isolate::Current()->HasAttemptedReload()));
    if (target.IsNull() || (target.is_static() != parent.is_static()) ||
        (target.kind() != parent.kind())) {
      target = Function::null();
    }
  }

  AstNode* call = NULL;
  // Check the target still exists and has compatible parameters. If not,
  // throw NSME/call nSM instead of forwarding the call. Note we compare the
  // parent not func because func has an extra parameter for the closure
  // receiver.
  if (!target.IsNull() &&
      (parent.num_fixed_parameters() == target.num_fixed_parameters())) {
    call = new StaticCallNode(token_pos, target, func_args,
                              StaticCallNode::kNoRebind);
  } else if (!parent.is_static()) {
    NOT_IN_PRODUCT(ASSERT(Isolate::Current()->HasAttemptedReload()));
    // If a subsequent reload reintroduces the target in the middle of the
    // Invocation object being constructed, we won't be able to successfully
    // deopt because the generated AST will change.
    func.SetIsOptimizable(false);

    ArgumentListNode* arguments = BuildNoSuchMethodArguments(
        token_pos, func_name, *func_args, NULL, false);
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArguments = 2;  // Receiver, InvocationMirror.
    ArgumentsDescriptor args_desc(Array::Handle(
        Z, ArgumentsDescriptor::New(kTypeArgsLen, kNumArguments)));
    Function& no_such_method =
        Function::ZoneHandle(Z, Resolver::ResolveDynamicForReceiverClass(
                                    owner, Symbols::NoSuchMethod(), args_desc));
    if (no_such_method.IsNull()) {
      // If noSuchMethod(i) is not found, call Object:noSuchMethod.
      no_such_method ^= Resolver::ResolveDynamicForReceiverClass(
          Class::Handle(Z, I->object_store()->object_class()),
          Symbols::NoSuchMethod(), args_desc);
    }
    call = new StaticCallNode(token_pos, no_such_method, arguments,
                              StaticCallNode::kStatic);
  } else {
    NOT_IN_PRODUCT(ASSERT(Isolate::Current()->HasAttemptedReload()));
    // If a subsequent reload reintroduces the target in the middle of the
    // arguments array being constructed, we won't be able to successfully
    // deopt because the generated AST will change.
    func.SetIsOptimizable(false);

    InvocationMirror::Kind im_kind;
    if (parent.IsImplicitGetterFunction()) {
      im_kind = InvocationMirror::kGetter;
    } else if (parent.IsImplicitSetterFunction()) {
      im_kind = InvocationMirror::kSetter;
    } else {
      im_kind = InvocationMirror::kMethod;
    }
    call = ThrowNoSuchMethodError(TokenPos(), owner, func_name, func_args,
                                  InvocationMirror::kStatic, im_kind,
                                  NULL);  // No existing function.
  }

  ASSERT(call != NULL);
  ReturnNode* return_node = new ReturnNode(token_pos, call);
  current_block_->statements->Add(return_node);
  return CloseBlock();
}

SequenceNode* Parser::ParseMethodExtractor(const Function& func) {
  TRACE_PARSER("ParseMethodExtractor");

  ParamList params;

  const TokenPosition ident_pos = func.token_pos();
  ASSERT(func.token_pos() == TokenPosition::kMethodExtractor);
  ASSERT(current_class().raw() == func.Owner());
  params.AddReceiver(ReceiverType(current_class()), ident_pos);
  ASSERT(func.num_fixed_parameters() == 1);  // Receiver.
  ASSERT(!func.HasOptionalParameters());

  // Build local scope for function and populate with the formal parameters.
  OpenFunctionBlock(func);
  AddFormalParamsToScope(&params, current_block_->scope);

  // Receiver is local 0.
  LocalVariable* receiver = current_block_->scope->VariableAt(0);
  LoadLocalNode* load_receiver = new LoadLocalNode(ident_pos, receiver);

  ClosureNode* closure = new ClosureNode(
      ident_pos, Function::ZoneHandle(Z, func.extracted_method_closure()),
      load_receiver, NULL);

  ReturnNode* return_node = new ReturnNode(ident_pos, closure);
  current_block_->statements->Add(return_node);
  return CloseBlock();
}

void Parser::BuildDispatcherScope(const Function& func,
                                  const ArgumentsDescriptor& desc) {
  ParamList params;
  // Receiver first.
  TokenPosition token_pos = func.token_pos();
  params.AddReceiver(ReceiverType(current_class()), token_pos);
  // Remaining positional parameters.
  intptr_t i = 1;
  for (; i < desc.PositionalCount(); ++i) {
    ParamDesc p;
    char name[64];
    OS::SNPrint(name, 64, ":p%" Pd, i);
    p.name = &String::ZoneHandle(Z, Symbols::New(T, name));
    p.type = &Object::dynamic_type();
    params.parameters->Add(p);
    params.num_fixed_parameters++;
  }
  ASSERT(desc.PositionalCount() == params.num_fixed_parameters);

  // Named parameters.
  for (; i < desc.Count(); ++i) {
    ParamDesc p;
    intptr_t index = i - desc.PositionalCount();
    p.name = &String::ZoneHandle(Z, desc.NameAt(index));
    p.type = &Object::dynamic_type();
    p.default_value = &Object::null_instance();
    params.parameters->Add(p);
    params.num_optional_parameters++;
    params.has_optional_named_parameters = true;
  }
  ASSERT(desc.NamedCount() == params.num_optional_parameters);

  SetupDefaultsForOptionalParams(params);

  // Build local scope for function and populate with the formal parameters.
  OpenFunctionBlock(func);
  AddFormalParamsToScope(&params, current_block_->scope);

  if (desc.TypeArgsLen() > 0) {
    ASSERT(func.IsGeneric() && !func.HasGenericParent());
    // Insert function type arguments variable to scope.
    LocalVariable* type_args_var = new (Z) LocalVariable(
        TokenPosition::kNoSource, TokenPosition::kNoSource,
        Symbols::FunctionTypeArgumentsVar(), Object::dynamic_type());
    current_block_->scope->AddVariable(type_args_var);
    ASSERT(FunctionLevel() == 0);
    parsed_function_->set_function_type_arguments(type_args_var);
  }
}

SequenceNode* Parser::ParseNoSuchMethodDispatcher(const Function& func) {
  TRACE_PARSER("ParseNoSuchMethodDispatcher");
  ASSERT(FLAG_lazy_dispatchers);
  ASSERT(func.IsNoSuchMethodDispatcher());
  TokenPosition token_pos = func.token_pos();
  ASSERT(func.token_pos() == TokenPosition::kMinSource);
  ASSERT(current_class().raw() == func.Owner());

  ArgumentsDescriptor desc(Array::Handle(Z, func.saved_args_desc()));
  ASSERT(desc.Count() > 0);

  // Set up scope for this function.
  BuildDispatcherScope(func, desc);

  // Receiver is local 0.
  LocalScope* scope = current_block_->scope;
  ArgumentListNode* func_args = new ArgumentListNode(
      token_pos, parsed_function_->function_type_arguments(),
      desc.TypeArgsLen());
  for (intptr_t i = 0; i < desc.Count(); ++i) {
    func_args->Add(new LoadLocalNode(token_pos, scope->VariableAt(i)));
  }

  if (desc.NamedCount() > 0) {
    const Array& arg_names =
        Array::ZoneHandle(Z, Array::New(desc.NamedCount(), Heap::kOld));
    for (intptr_t i = 0; i < arg_names.Length(); ++i) {
      arg_names.SetAt(i, String::Handle(Z, desc.NameAt(i)));
    }
    func_args->set_names(arg_names);
  }

  const String& func_name = String::ZoneHandle(Z, func.name());
  ArgumentListNode* arguments =
      BuildNoSuchMethodArguments(token_pos, func_name, *func_args, NULL, false);
  const intptr_t kTypeArgsLen = 0;
  const intptr_t kNumArguments = 2;  // Receiver, InvocationMirror.
  ArgumentsDescriptor args_desc(
      Array::Handle(Z, ArgumentsDescriptor::New(kTypeArgsLen, kNumArguments)));
  Function& no_such_method = Function::ZoneHandle(
      Z,
      Resolver::ResolveDynamicForReceiverClass(
          Class::Handle(Z, func.Owner()), Symbols::NoSuchMethod(), args_desc));
  if (no_such_method.IsNull()) {
    // If noSuchMethod(i) is not found, call Object:noSuchMethod.
    no_such_method ^= Resolver::ResolveDynamicForReceiverClass(
        Class::Handle(Z, I->object_store()->object_class()),
        Symbols::NoSuchMethod(), args_desc);
  }
  StaticCallNode* call = new StaticCallNode(
      token_pos, no_such_method, arguments, StaticCallNode::kNSMDispatch);

  ReturnNode* return_node = new ReturnNode(token_pos, call);
  current_block_->statements->Add(return_node);
  return CloseBlock();
}

SequenceNode* Parser::ParseInvokeFieldDispatcher(const Function& func) {
  TRACE_PARSER("ParseInvokeFieldDispatcher");
  ASSERT(func.IsInvokeFieldDispatcher());
  TokenPosition token_pos = func.token_pos();
  ASSERT(func.token_pos() == TokenPosition::kMinSource);
  ASSERT(current_class().raw() == func.Owner());

  const Array& args_desc = Array::Handle(Z, func.saved_args_desc());
  ArgumentsDescriptor desc(args_desc);
  ASSERT(desc.Count() > 0);

  // Set up scope for this function.
  BuildDispatcherScope(func, desc);

  // Receiver is local 0.
  LocalScope* scope = current_block_->scope;
  ArgumentListNode* no_args = new ArgumentListNode(token_pos);
  LoadLocalNode* receiver = new LoadLocalNode(token_pos, scope->VariableAt(0));

  const Class& closure_cls =
      Class::Handle(Isolate::Current()->object_store()->closure_class());

  const Class& owner = Class::Handle(Z, func.Owner());
  ASSERT(!owner.IsNull());
  const String& name = String::Handle(Z, func.name());
  AstNode* function_object = NULL;
  if (owner.raw() == closure_cls.raw() && name.Equals(Symbols::Call())) {
    function_object = receiver;
  } else {
    const String& getter_name =
        String::ZoneHandle(Z, Field::GetterSymbol(name));
    function_object =
        new (Z) InstanceCallNode(token_pos, receiver, getter_name, no_args);
  }

  // Pass arguments 1..n to the closure call.
  ArgumentListNode* args = new (Z)
      ArgumentListNode(token_pos, parsed_function_->function_type_arguments(),
                       desc.TypeArgsLen());
  const Array& names =
      Array::Handle(Z, Array::New(desc.NamedCount(), Heap::kOld));

  // Positional parameters.
  intptr_t i = 1;
  for (; i < desc.PositionalCount(); ++i) {
    args->Add(new LoadLocalNode(token_pos, scope->VariableAt(i)));
  }
  // Named parameters.
  for (; i < desc.Count(); i++) {
    args->Add(new (Z) LoadLocalNode(token_pos, scope->VariableAt(i)));
    intptr_t index = i - desc.PositionalCount();
    names.SetAt(index, String::Handle(Z, desc.NameAt(index)));
  }
  args->set_names(names);

  AstNode* result = NULL;
  if (owner.raw() == closure_cls.raw() && name.Equals(Symbols::Call())) {
    result = new ClosureCallNode(token_pos, function_object, args);
  } else {
    result = BuildClosureCall(token_pos, function_object, args);
  }

  ReturnNode* return_node = new ReturnNode(token_pos, result);
  current_block_->statements->Add(return_node);
  return CloseBlock();
}

AstNode* Parser::BuildClosureCall(TokenPosition token_pos,
                                  AstNode* closure,
                                  ArgumentListNode* arguments) {
  return new InstanceCallNode(token_pos, closure, Symbols::Call(), arguments);
}

void Parser::SkipToMatching() {
  Token::Kind opening_token = CurrentToken();
  ASSERT((opening_token == Token::kLBRACE) ||
         (opening_token == Token::kLPAREN));
  GrowableArray<Token::Kind> token_stack(8);
  GrowableArray<TokenPosition> token_pos_stack(8);
  // Adding the first opening brace here, because it will be consumed
  // in the loop right away.
  token_stack.Add(opening_token);
  const TokenPosition start_pos = TokenPos();
  TokenPosition opening_pos = start_pos;
  token_pos_stack.Add(start_pos);
  bool is_match = true;
  bool unexpected_token_found = false;
  Token::Kind token = opening_token;
  TokenPosition token_pos;
  do {
    ConsumeToken();
    token = CurrentToken();
    token_pos = TokenPos();
    switch (token) {
      case Token::kLBRACE:
      case Token::kLPAREN:
      case Token::kLBRACK:
        token_stack.Add(token);
        token_pos_stack.Add(token_pos);
        break;
      case Token::kRBRACE:
        opening_token = token_stack.RemoveLast();
        opening_pos = token_pos_stack.RemoveLast();
        is_match = opening_token == Token::kLBRACE;
        break;
      case Token::kRPAREN:
        opening_token = token_stack.RemoveLast();
        opening_pos = token_pos_stack.RemoveLast();
        is_match = opening_token == Token::kLPAREN;
        break;
      case Token::kRBRACK:
        opening_token = token_stack.RemoveLast();
        opening_pos = token_pos_stack.RemoveLast();
        is_match = opening_token == Token::kLBRACK;
        break;
      case Token::kEOS:
        opening_token = token_stack.RemoveLast();
        opening_pos = token_pos_stack.RemoveLast();
        unexpected_token_found = true;
        break;
      default:
        // nothing.
        break;
    }
  } while (!token_stack.is_empty() && is_match && !unexpected_token_found);
  if (!is_match) {
    const Error& error = Error::Handle(LanguageError::NewFormatted(
        Error::Handle(), script_, opening_pos, Report::AtLocation,
        Report::kWarning, allocation_space_, "unbalanced '%s' opens here",
        Token::Str(opening_token)));
    ReportErrors(error, script_, token_pos, "unbalanced '%s'",
                 Token::Str(token));
  } else if (unexpected_token_found) {
    ReportError(start_pos, "unterminated '%s'", Token::Str(opening_token));
  }
}

void Parser::SkipBlock() {
  ASSERT(CurrentToken() == Token::kLBRACE);
  SkipToMatching();
}

// Skips tokens up to and including matching closing parenthesis.
void Parser::SkipToMatchingParenthesis() {
  ASSERT(CurrentToken() == Token::kLPAREN);
  SkipToMatching();
  ASSERT(CurrentToken() == Token::kRPAREN);
  ConsumeToken();
}

// Parses a parameter type as defined by the 'parameterTypeList' production.
void Parser::ParseParameterType(ParamList* params) {
  TRACE_PARSER("ParseParameterType");
  ParamDesc parameter;

  parameter.has_explicit_type = true;  // The type is required by the syntax.
  // It is too early to resolve the type here, since it can be a result type
  // referring to a not yet declared function type parameter.
  parameter.type = &AbstractType::ZoneHandle(
      Z, ParseTypeOrFunctionType(false, ClassFinalizer::kDoNotResolve));

  // At this point, we must see an identifier for the parameter name, unless
  // we are using the function type syntax (in which case the name is optional,
  // unless we expect optional named parameters).
  if (IsIdentifier()) {
    parameter.name_pos = TokenPos();
    parameter.name = CurrentLiteral();
    ConsumeToken();

    if (params->has_optional_named_parameters &&
        (parameter.name->CharAt(0) == Library::kPrivateIdentifierStart)) {
      ReportError(parameter.name_pos, "named parameter must not be private");
    }

    // Check for duplicate formal parameters.
    const intptr_t num_existing_parameters =
        params->num_fixed_parameters + params->num_optional_parameters;
    for (intptr_t i = 0; i < num_existing_parameters; i++) {
      ParamDesc& existing_parameter = (*params->parameters)[i];
      if (existing_parameter.name->Equals(*parameter.name)) {
        ReportError(parameter.name_pos, "duplicate formal parameter '%s'",
                    parameter.name->ToCString());
      }
    }
  } else if (params->has_optional_named_parameters) {
    ExpectIdentifier("parameter name expected");
  } else {
    parameter.name_pos = TokenPos();
    parameter.name = &Symbols::NotNamed();
  }

  // The function type syntax does not allow the signature type syntax.
  // No need to check for IsParameterPart().

  if ((CurrentToken() == Token::kASSIGN) || (CurrentToken() == Token::kCOLON)) {
    ReportError("parameter must not specify a default value");
  } else {
    if (params->has_optional_positional_parameters ||
        params->has_optional_named_parameters) {
      // Implicit default value is null.
      params->num_optional_parameters++;
      parameter.default_value = &Object::null_instance();
    } else {
      params->num_fixed_parameters++;
      ASSERT(params->num_optional_parameters == 0);
    }
  }
  if (parameter.type->IsVoidType()) {
    ReportError("parameter '%s' may not be 'void'",
                parameter.name->ToCString());
  }
  if (params->implicitly_final) {
    parameter.is_final = true;
  }
  params->parameters->Add(parameter);
  if (parameter.is_covariant) {
    params->has_covariant = true;
  }
}

// Parses a formal parameter as defined by the 'formalParameterList' production.
void Parser::ParseFormalParameter(bool allow_explicit_default_value,
                                  bool evaluate_metadata,
                                  ParamList* params) {
  TRACE_PARSER("ParseFormalParameter");
  ParamDesc parameter;
  bool var_seen = false;
  bool final_seen = false;
  bool this_seen = false;

  if (evaluate_metadata && (CurrentToken() == Token::kAT)) {
    parameter.metadata = &Array::ZoneHandle(Z, EvaluateMetadata());
  } else {
    SkipMetadata();
  }

  if (CurrentToken() == Token::kCOVARIANT &&
      (LookaheadToken(1) == Token::kFINAL || LookaheadToken(1) == Token::kVAR ||
       Token::IsIdentifier(LookaheadToken(1)))) {
    parameter.is_covariant = true;
    ConsumeToken();
  }
  if (CurrentToken() == Token::kFINAL) {
    ConsumeToken();
    final_seen = true;
    parameter.is_final = true;
  } else if (CurrentToken() == Token::kVAR) {
    ConsumeToken();
    var_seen = true;
    // The parameter type is the 'dynamic' type.
    // If this is an initializing formal, its type will be set to the type of
    // the respective field when the constructor is fully parsed.
    parameter.type = &Object::dynamic_type();
  }
  if (CurrentToken() == Token::kTHIS) {
    ConsumeToken();
    ExpectToken(Token::kPERIOD);
    this_seen = true;
    parameter.is_field_initializer = true;
    if (FLAG_initializing_formal_access) {
      parameter.is_final = true;
    }
  }
  if ((parameter.type == NULL) && (CurrentToken() == Token::kVOID)) {
    ConsumeToken();
    // This must later be changed to a closure type if we recognize
    // a closure/function type parameter. We check this at the end
    // of ParseFormalParameter.
    parameter.type = &Object::void_type();
  }
  if ((parameter.type == NULL) || IsFunctionTypeSymbol()) {
    // At this point, we must see an identifier for the type or the
    // function parameter. The identifier may be 'Function'.
    if (!IsIdentifier()) {
      ReportError("parameter name or type expected");
    }

    // Lookahead to determine whether the next tokens are a return type
    // followed by a parameter name.
    bool found_type = false;
    {
      TokenPosScope saved_pos(this);
      if (TryParseType(true)) {
        if (IsIdentifier() || (CurrentToken() == Token::kTHIS)) {
          found_type = true;
        }
      }
    }
    if (found_type) {
      // The types of formal parameters are never ignored, even in unchecked
      // mode, because they are part of the function type of closurized
      // functions appearing in type tests with typedefs.
      parameter.has_explicit_type = true;
      // It is too early to resolve the type here, since it can be a result
      // type referring to a not yet declared function type parameter.
      if (parameter.type == NULL) {
        parameter.type = &AbstractType::ZoneHandle(
            Z, ParseTypeOrFunctionType(true, ClassFinalizer::kDoNotResolve));
      } else {
        parameter.type = &AbstractType::ZoneHandle(
            Z,
            ParseFunctionType(*parameter.type, ClassFinalizer::kDoNotResolve));
      }
    } else {
      // If this is an initializing formal, its type will be set to the type
      // of the respective field when the constructor is fully parsed.
      parameter.type = &Object::dynamic_type();
    }
  }
  if (!this_seen && (CurrentToken() == Token::kTHIS)) {
    ConsumeToken();
    ExpectToken(Token::kPERIOD);
    this_seen = true;
    parameter.is_field_initializer = true;
    if (FLAG_initializing_formal_access) {
      parameter.is_final = true;
    }
  }

  // At this point, we must see an identifier for the parameter name.
  parameter.name_pos = TokenPos();
  parameter.name = ExpectIdentifier("parameter name expected");
  if (parameter.is_field_initializer) {
    params->has_field_initializer = true;
  }

  if (params->has_optional_named_parameters &&
      (parameter.name->CharAt(0) == Library::kPrivateIdentifierStart)) {
    ReportError(parameter.name_pos, "named parameter must not be private");
  }

  // Check for duplicate formal parameters.
  const intptr_t num_existing_parameters =
      params->num_fixed_parameters + params->num_optional_parameters;
  for (intptr_t i = 0; i < num_existing_parameters; i++) {
    ParamDesc& existing_parameter = (*params->parameters)[i];
    if (existing_parameter.name->Equals(*parameter.name)) {
      ReportError(parameter.name_pos, "duplicate formal parameter '%s'",
                  parameter.name->ToCString());
    }
  }

  if (IsParameterPart()) {
    // This parameter is probably a closure. If we saw the keyword 'var'
    // or 'final', a closure is not legal here and we ignore the
    // opening parens.
    // TODO(hausner): The language spec appears to allow var and final
    // in signature types when used with initializing formals:
    // fieldFormalParameter:
    // metadata finalConstVarOrType? this ‘.’ identifier formalParameterList? ;
    if (!var_seen && !final_seen) {
      // The parsed parameter type is actually the function result type.
      AbstractType& result_type =
          AbstractType::Handle(Z, parameter.type->raw());

      // In top-level and mixin functions, the source may be in a different
      // script than the script of the current class. However, we never reparse
      // signature functions (except typedef signature functions), therefore
      // we do not need to keep the correct script via a patch class. Use the
      // actual current class as owner of the signature function.
      Function& signature_function = Function::Handle(
          Z,
          Function::NewSignatureFunction(current_class(), innermost_function(),
                                         TokenPosition::kNoSource));
      innermost_function_ = signature_function.raw();

      // Finish parsing the function type parameter.
      if (CurrentToken() == Token::kLT) {
        if (!FLAG_generic_method_syntax) {
          ReportError("generic function types not supported");
        }
        ParseTypeParameters(false);  // Not parameterizing class, but function.
      }

      ASSERT(CurrentToken() == Token::kLPAREN);
      ParamList func_params;

      // Add implicit closure object parameter.
      func_params.AddFinalParameter(TokenPos(), &Symbols::ClosureParameter(),
                                    &Object::dynamic_type());

      const bool use_function_type_syntax = false;
      const bool allow_explicit_default_values = false;
      const bool evaluate_metadata = false;
      ParseFormalParameterList(use_function_type_syntax,
                               allow_explicit_default_values, evaluate_metadata,
                               &func_params);

      signature_function.set_result_type(result_type);
      // The result type may refer to the signature function's type parameters,
      // but was not parsed in the scope of the signature function. Adjust.
      result_type.SetScopeFunction(signature_function);
      AddFormalParamsToFunction(&func_params, signature_function);

      ASSERT(innermost_function().raw() == signature_function.raw());
      innermost_function_ = signature_function.parent_function();

      Type& signature_type =
          Type::ZoneHandle(Z, signature_function.SignatureType());

      // A signature type itself cannot be malformed or malbounded, only its
      // signature function's result type or parameter types may be.
      ASSERT(!signature_type.IsMalformed());
      ASSERT(!signature_type.IsMalbounded());
      // The type of the parameter is now the signature type.
      parameter.type = &signature_type;
    }
  }

  if ((CurrentToken() == Token::kASSIGN) || (CurrentToken() == Token::kCOLON)) {
    if ((!params->has_optional_positional_parameters &&
         !params->has_optional_named_parameters) ||
        !allow_explicit_default_value) {
      ReportError("parameter must not specify a default value");
    }
    if (params->has_optional_positional_parameters) {
      ExpectToken(Token::kASSIGN);
    } else {
      ConsumeToken();
    }
    params->num_optional_parameters++;
    params->has_explicit_default_values = true;  // Also if explicitly NULL.
    if (is_top_level_) {
      // Skip default value parsing.
      SkipExpr();
    } else {
      const Instance& const_value = ParseConstExpr()->literal();
      parameter.default_value = &const_value;
    }
  } else {
    if (params->has_optional_positional_parameters ||
        params->has_optional_named_parameters) {
      // Implicit default value is null.
      params->num_optional_parameters++;
      parameter.default_value = &Object::null_instance();
    } else {
      params->num_fixed_parameters++;
      ASSERT(params->num_optional_parameters == 0);
    }
  }
  if (parameter.type->IsVoidType()) {
    ReportError("parameter '%s' may not be 'void'",
                parameter.name->ToCString());
  }
  if (params->implicitly_final) {
    parameter.is_final = true;
  }
  params->parameters->Add(parameter);
  if (parameter.is_covariant) {
    params->has_covariant = true;
  }
}

// Parses a sequence of normal or optional formal parameters.
void Parser::ParseFormalParameters(bool use_function_type_syntax,
                                   bool allow_explicit_default_values,
                                   bool evaluate_metadata,
                                   ParamList* params) {
  TRACE_PARSER("ParseFormalParameters");
  // Optional parameter lists cannot be empty.
  // The completely empty parameter list is handled before getting here.
  bool has_seen_parameter = false;
  do {
    ConsumeToken();
    if (!params->has_optional_positional_parameters &&
        !params->has_optional_named_parameters &&
        (CurrentToken() == Token::kLBRACK)) {
      // End of normal parameters, start of optional positional parameters.
      params->has_optional_positional_parameters = true;
      return;
    }
    if (!params->has_optional_positional_parameters &&
        !params->has_optional_named_parameters &&
        (CurrentToken() == Token::kLBRACE)) {
      // End of normal parameters, start of optional named parameters.
      params->has_optional_named_parameters = true;
      return;
    }
    Token::Kind terminator = params->has_optional_positional_parameters
                                 ? Token::kRBRACK
                                 : params->has_optional_named_parameters
                                       ? Token::kRBRACE
                                       : Token::kRPAREN;
    if (has_seen_parameter && CurrentToken() == terminator) {
      // Allow a trailing comma.
      break;
    }
    if (use_function_type_syntax) {
      ASSERT(!allow_explicit_default_values && !evaluate_metadata);
      ParseParameterType(params);
    } else {
      ParseFormalParameter(allow_explicit_default_values, evaluate_metadata,
                           params);
    }
    has_seen_parameter = true;
  } while (CurrentToken() == Token::kCOMMA);
}

void Parser::ParseFormalParameterList(bool use_function_type_syntax,
                                      bool allow_explicit_default_values,
                                      bool evaluate_metadata,
                                      ParamList* params) {
  TRACE_PARSER("ParseFormalParameterList");
  ASSERT(CurrentToken() == Token::kLPAREN);

  if (LookaheadToken(1) != Token::kRPAREN) {
    // Parse fixed parameters.
    ParseFormalParameters(use_function_type_syntax,
                          allow_explicit_default_values, evaluate_metadata,
                          params);
    if (params->has_optional_positional_parameters ||
        params->has_optional_named_parameters) {
      // Parse optional parameters.
      ParseFormalParameters(use_function_type_syntax,
                            allow_explicit_default_values, evaluate_metadata,
                            params);
      if (params->has_optional_positional_parameters) {
        CheckToken(Token::kRBRACK, "',' or ']' expected");
      } else {
        CheckToken(Token::kRBRACE, "',' or '}' expected");
      }
      ConsumeToken();  // ']' or '}'.
    }
    if ((CurrentToken() != Token::kRPAREN) &&
        !params->has_optional_positional_parameters &&
        !params->has_optional_named_parameters) {
      ReportError("',' or ')' expected");
    }
  } else {
    ConsumeToken();
  }
  ExpectToken(Token::kRPAREN);
}

String& Parser::ParseNativeDeclaration() {
  TRACE_PARSER("ParseNativeDeclaration");
  ASSERT(IsSymbol(Symbols::Native()));
  ConsumeToken();
  CheckToken(Token::kSTRING, "string literal expected");
  String& native_name = *CurrentLiteral();
  ConsumeToken();
  return native_name;
}

// Resolve and return the dynamic function of the given name in the superclass.
// If it is not found, and resolve_getter is true, try to resolve a getter of
// the same name. If it is still not found, return noSuchMethod and
// set is_no_such_method to true..
RawFunction* Parser::GetSuperFunction(TokenPosition token_pos,
                                      const String& name,
                                      ArgumentListNode* arguments,
                                      bool resolve_getter,
                                      bool* is_no_such_method) {
  const Class& super_class = Class::Handle(Z, current_class().SuperClass());
  if (super_class.IsNull()) {
    ReportError(token_pos, "class '%s' does not have a superclass",
                String::Handle(Z, current_class().Name()).ToCString());
  }
  Function& super_func = Function::Handle(
      Z, Resolver::ResolveDynamicAnyArgs(Z, super_class, name));
  if (!super_func.IsNull() &&
      !super_func.AreValidArguments(arguments->type_args_len(),
                                    arguments->length(), arguments->names(),
                                    NULL)) {
    super_func = Function::null();
  } else if (super_func.IsNull() && resolve_getter) {
    const String& getter_name =
        String::ZoneHandle(Z, Field::LookupGetterSymbol(name));
    if (!getter_name.IsNull()) {
      super_func = Resolver::ResolveDynamicAnyArgs(Z, super_class, getter_name);
      ASSERT(super_func.IsNull() ||
             (super_func.kind() != RawFunction::kImplicitStaticFinalGetter));
    }
  }
  if (super_func.IsNull()) {
    super_func = Resolver::ResolveDynamicAnyArgs(Z, super_class,
                                                 Symbols::NoSuchMethod());
    ASSERT(!super_func.IsNull());
    *is_no_such_method = true;
  } else {
    *is_no_such_method = false;
  }
  return super_func.raw();
}

StaticCallNode* Parser::BuildInvocationMirrorAllocation(
    TokenPosition call_pos,
    const String& function_name,
    const ArgumentListNode& function_args,
    const LocalVariable* temp_for_last_arg,
    bool is_super_invocation) {
  const TokenPosition args_pos = function_args.token_pos();
  // Build arguments to the call to the static
  // InvocationMirror._allocateInvocationMirror method.
  ArgumentListNode* arguments = new ArgumentListNode(args_pos);
  // The first argument is the original function name.
  arguments->Add(new LiteralNode(args_pos, function_name));
  // The second argument is the arguments descriptor of the original function.
  const Array& args_descriptor = Array::ZoneHandle(
      ArgumentsDescriptor::New(function_args.type_args_len(),
                               function_args.length(), function_args.names()));
  arguments->Add(new LiteralNode(args_pos, args_descriptor));
  // The third argument is an array containing the original function arguments,
  // including the function type arguments and the receiver.
  ArrayNode* args_array =
      new ArrayNode(args_pos, Type::ZoneHandle(Type::ArrayType()));
  // A type_args_var is allocated in the generated body of an implicit
  // closure and in the generated body of a noSuchMethodDispatcher.
  // Pass the type arguments to the invocation mirror as the first argument.
  if (function_args.type_args_var() != NULL) {
    ASSERT(function_args.type_arguments().IsNull());
    args_array->AddElement(
        new LoadLocalNode(args_pos, function_args.type_args_var()));
  } else if (!function_args.type_arguments().IsNull()) {
    args_array->AddElement(
        new LiteralNode(args_pos, function_args.type_arguments()));
  }
  for (intptr_t i = 0; i < function_args.length(); i++) {
    AstNode* arg = function_args.NodeAt(i);
    if ((temp_for_last_arg != NULL) && (i == function_args.length() - 1)) {
      LetNode* store_arg = new LetNode(arg->token_pos());
      store_arg->AddNode(
          new StoreLocalNode(arg->token_pos(), temp_for_last_arg, arg));
      store_arg->AddNode(
          new LoadLocalNode(arg->token_pos(), temp_for_last_arg));
      args_array->AddElement(store_arg);
    } else {
      args_array->AddElement(arg);
    }
  }
  arguments->Add(args_array);
  arguments->Add(new LiteralNode(args_pos, Bool::Get(is_super_invocation)));
  // Lookup the static InvocationMirror._allocateInvocationMirror method.
  const Class& mirror_class =
      Class::Handle(Library::LookupCoreClass(Symbols::InvocationMirror()));
  ASSERT(!mirror_class.IsNull());
  const Function& allocation_function =
      Function::ZoneHandle(mirror_class.LookupStaticFunction(
          Library::PrivateCoreLibName(Symbols::AllocateInvocationMirror())));
  ASSERT(!allocation_function.IsNull());
  return new StaticCallNode(call_pos, allocation_function, arguments,
                            StaticCallNode::kStatic);
}

ArgumentListNode* Parser::BuildNoSuchMethodArguments(
    TokenPosition call_pos,
    const String& function_name,
    const ArgumentListNode& function_args,
    const LocalVariable* temp_for_last_arg,
    bool is_super_invocation) {
  ASSERT(function_args.length() >= 1);  // The receiver is the first argument.
  const TokenPosition args_pos = function_args.token_pos();
  ArgumentListNode* arguments = new ArgumentListNode(args_pos);
  arguments->Add(function_args.NodeAt(0));
  // The second argument is the invocation mirror.
  arguments->Add(
      BuildInvocationMirrorAllocation(call_pos, function_name, function_args,
                                      temp_for_last_arg, is_super_invocation));
  return arguments;
}

AstNode* Parser::ParseSuperCall(const String& function_name,
                                const TypeArguments& func_type_args) {
  TRACE_PARSER("ParseSuperCall");
  ASSERT(CurrentToken() == Token::kLPAREN);
  const TokenPosition supercall_pos = TokenPos();

  // 'this' parameter is the first argument to super call (after the type args).
  ArgumentListNode* arguments =
      new ArgumentListNode(supercall_pos, func_type_args);
  AstNode* receiver = LoadReceiver(supercall_pos);
  arguments->Add(receiver);
  ParseActualParameters(arguments, Object::null_type_arguments(), kAllowConst);

  const bool kResolveGetter = true;
  bool is_no_such_method = false;
  const Function& super_function = Function::ZoneHandle(
      Z, GetSuperFunction(supercall_pos, function_name, arguments,
                          kResolveGetter, &is_no_such_method));
  if (super_function.IsGetterFunction() ||
      super_function.IsImplicitGetterFunction()) {
    const Class& super_class =
        Class::ZoneHandle(Z, current_class().SuperClass());
    AstNode* closure = new StaticGetterNode(
        supercall_pos, LoadReceiver(supercall_pos), super_class, function_name,
        StaticGetterSetter::kSuper);
    // 'this' is not passed as parameter to the closure.
    ArgumentListNode* closure_arguments =
        new ArgumentListNode(supercall_pos, func_type_args);
    for (int i = 1; i < arguments->length(); i++) {
      closure_arguments->Add(arguments->NodeAt(i));
    }
    return BuildClosureCall(supercall_pos, closure, closure_arguments);
  }
  if (is_no_such_method) {
    arguments = BuildNoSuchMethodArguments(supercall_pos, function_name,
                                           *arguments, NULL, true);
  }
  return new StaticCallNode(supercall_pos, super_function, arguments,
                            StaticCallNode::kSuper);
}

// Simple test if a node is side effect free.
static bool IsSimpleLocalOrLiteralNode(AstNode* node) {
  return node->IsLiteralNode() || node->IsLoadLocalNode();
}

AstNode* Parser::BuildUnarySuperOperator(Token::Kind op, PrimaryNode* super) {
  ASSERT(super->IsSuper());
  AstNode* super_op = NULL;
  const TokenPosition super_pos = super->token_pos();
  if ((op == Token::kNEGATE) || (op == Token::kBIT_NOT)) {
    // Resolve the operator function in the superclass.
    const String& operator_function_name = Symbols::Token(op);
    ArgumentListNode* op_arguments = new ArgumentListNode(super_pos);
    AstNode* receiver = LoadReceiver(super_pos);
    op_arguments->Add(receiver);
    const bool kResolveGetter = false;
    bool is_no_such_method = false;
    const Function& super_operator = Function::ZoneHandle(
        Z, GetSuperFunction(super_pos, operator_function_name, op_arguments,
                            kResolveGetter, &is_no_such_method));
    if (is_no_such_method) {
      op_arguments = BuildNoSuchMethodArguments(
          super_pos, operator_function_name, *op_arguments, NULL, true);
    }
    super_op = new StaticCallNode(super_pos, super_operator, op_arguments,
                                  StaticCallNode::kSuper);
  } else {
    ReportError(super_pos, "illegal super operator call");
  }
  return super_op;
}

AstNode* Parser::ParseSuperOperator() {
  TRACE_PARSER("ParseSuperOperator");
  AstNode* super_op = NULL;
  const TokenPosition operator_pos = TokenPos();

  if (CurrentToken() == Token::kLBRACK) {
    ConsumeToken();
    AstNode* index_expr = ParseExpr(kAllowConst, kConsumeCascades);
    ExpectToken(Token::kRBRACK);
    AstNode* receiver = LoadReceiver(operator_pos);
    const Class& super_class =
        Class::ZoneHandle(Z, current_class().SuperClass());
    ASSERT(!super_class.IsNull());
    super_op =
        new LoadIndexedNode(operator_pos, receiver, index_expr, super_class);
  } else {
    ASSERT(Token::CanBeOverloaded(CurrentToken()) ||
           (CurrentToken() == Token::kNE));
    Token::Kind op = CurrentToken();
    ConsumeToken();

    bool negate_result = false;
    if (op == Token::kNE) {
      op = Token::kEQ;
      negate_result = true;
    }

    ASSERT(Token::Precedence(op) >= Token::Precedence(Token::kEQ));
    AstNode* other_operand = ParseBinaryExpr(Token::Precedence(op) + 1);

    ArgumentListNode* op_arguments = new ArgumentListNode(operator_pos);
    AstNode* receiver = LoadReceiver(operator_pos);
    op_arguments->Add(receiver);
    op_arguments->Add(other_operand);

    // Resolve the operator function in the superclass.
    const String& operator_function_name = Symbols::Token(op);
    const bool kResolveGetter = false;
    bool is_no_such_method = false;
    const Function& super_operator = Function::ZoneHandle(
        Z, GetSuperFunction(operator_pos, operator_function_name, op_arguments,
                            kResolveGetter, &is_no_such_method));
    if (is_no_such_method) {
      op_arguments = BuildNoSuchMethodArguments(
          operator_pos, operator_function_name, *op_arguments, NULL, true);
    }
    super_op = new StaticCallNode(operator_pos, super_operator, op_arguments,
                                  StaticCallNode::kSuper);
    if (negate_result) {
      super_op = new UnaryOpNode(operator_pos, Token::kNOT, super_op);
    }
  }
  return super_op;
}

ClosureNode* Parser::CreateImplicitClosureNode(const Function& func,
                                               TokenPosition token_pos,
                                               AstNode* receiver) {
  Function& implicit_closure_function =
      Function::ZoneHandle(Z, func.ImplicitClosureFunction());
  return new ClosureNode(token_pos, implicit_closure_function, receiver, NULL);
}

AstNode* Parser::ParseSuperFieldAccess(const String& field_name,
                                       TokenPosition field_pos) {
  TRACE_PARSER("ParseSuperFieldAccess");
  const Class& super_class = Class::ZoneHandle(Z, current_class().SuperClass());
  if (super_class.IsNull()) {
    ReportError("class '%s' does not have a superclass",
                String::Handle(Z, current_class().Name()).ToCString());
  }
  AstNode* implicit_argument = LoadReceiver(field_pos);

  const String& getter_name =
      String::ZoneHandle(Z, Field::LookupGetterSymbol(field_name));
  Function& super_getter = Function::ZoneHandle(Z);
  if (!getter_name.IsNull()) {
    super_getter = Resolver::ResolveDynamicAnyArgs(Z, super_class, getter_name);
  }
  if (super_getter.IsNull()) {
    const String& setter_name =
        String::ZoneHandle(Z, Field::LookupSetterSymbol(field_name));
    Function& super_setter = Function::ZoneHandle(Z);
    if (!setter_name.IsNull()) {
      super_setter =
          Resolver::ResolveDynamicAnyArgs(Z, super_class, setter_name);
    }
    if (super_setter.IsNull()) {
      // Check if this is an access to an implicit closure using 'super'.
      // If a function exists of the specified field_name then try
      // accessing it as a getter, at runtime we will handle this by
      // creating an implicit closure of the function and returning it.
      const Function& super_function = Function::ZoneHandle(
          Z, Resolver::ResolveDynamicAnyArgs(Z, super_class, field_name));
      if (!super_function.IsNull()) {
        // In case CreateAssignmentNode is called later on this
        // CreateImplicitClosureNode, it will be replaced by a StaticSetterNode.
        return CreateImplicitClosureNode(super_function, field_pos,
                                         implicit_argument);
      }
      // No function or field exists of the specified field_name.
      // Emit a StaticGetterNode anyway, so that noSuchMethod gets called.
    }
  }
  return new (Z) StaticGetterNode(field_pos, implicit_argument, super_class,
                                  field_name, StaticGetterSetter::kSuper);
}

StaticCallNode* Parser::GenerateSuperConstructorCall(
    const Class& cls,
    TokenPosition supercall_pos,
    LocalVariable* receiver,
    ArgumentListNode* forwarding_args) {
  const Class& super_class = Class::Handle(Z, cls.SuperClass());
  // Omit the implicit super() if there is no super class (i.e.
  // we're not compiling class Object), or if the super class is an
  // artificially generated "wrapper class" that has no constructor.
  if (super_class.IsNull() ||
      (super_class.num_native_fields() > 0 &&
       Class::Handle(Z, super_class.SuperClass()).IsObjectClass())) {
    return NULL;
  }
  String& super_ctor_name = String::Handle(Z, super_class.Name());
  super_ctor_name = Symbols::FromDot(T, super_ctor_name);

  ArgumentListNode* arguments = new ArgumentListNode(supercall_pos);
  // Implicit 'this' parameter is the first argument.
  AstNode* implicit_argument = new LoadLocalNode(supercall_pos, receiver);
  arguments->Add(implicit_argument);

  // If this is a super call in a forwarding constructor, add the user-
  // defined arguments to the super call and adjust the super
  // constructor name to the respective named constructor if necessary.
  if (forwarding_args != NULL) {
    for (int i = 0; i < forwarding_args->length(); i++) {
      arguments->Add(forwarding_args->NodeAt(i));
    }
    String& ctor_name = String::Handle(Z, current_function().name());
    String& class_name = String::Handle(Z, cls.Name());
    if (ctor_name.Length() > class_name.Length() + 1) {
      // Generating a forwarding call to a named constructor 'C.n'.
      // Add the constructor name 'n' to the super constructor.
      const intptr_t kLen = class_name.Length() + 1;
      ctor_name = Symbols::New(T, ctor_name, kLen, ctor_name.Length() - kLen);
      super_ctor_name = Symbols::FromConcat(T, super_ctor_name, ctor_name);
    }
  }

  // Resolve super constructor function and check arguments.
  const Function& super_ctor =
      Function::ZoneHandle(Z, super_class.LookupConstructor(super_ctor_name));
  if (super_ctor.IsNull()) {
    if (super_class.LookupFactory(super_ctor_name) != Function::null()) {
      ReportError(supercall_pos,
                  "illegal implicit call to factory '%s()' in super class",
                  String::Handle(Z, super_class.Name()).ToCString());
    }
    ReportError(supercall_pos,
                "unresolved implicit call to super constructor '%s()'",
                String::Handle(Z, super_class.Name()).ToCString());
  }
  if (current_function().is_const() && !super_ctor.is_const()) {
    ReportError(supercall_pos, "implicit call to non-const super constructor");
  }

  String& error_message = String::Handle(Z);
  if (!super_ctor.AreValidArguments(arguments->type_args_len(),
                                    arguments->length(), arguments->names(),
                                    &error_message)) {
    ReportError(supercall_pos,
                "invalid arguments passed to super constructor '%s()': %s",
                String::Handle(Z, super_class.Name()).ToCString(),
                error_message.ToCString());
  }
  return new StaticCallNode(supercall_pos, super_ctor, arguments,
                            StaticCallNode::kSuper);
}

StaticCallNode* Parser::ParseSuperInitializer(const Class& cls,
                                              LocalVariable* receiver) {
  TRACE_PARSER("ParseSuperInitializer");
  ASSERT(CurrentToken() == Token::kSUPER);
  const TokenPosition supercall_pos = TokenPos();
  ConsumeToken();
  const Class& super_class = Class::Handle(Z, cls.SuperClass());
  ASSERT(!super_class.IsNull());
  String& ctor_name = String::Handle(Z, super_class.Name());
  ctor_name = Symbols::FromConcat(T, ctor_name, Symbols::Dot());
  if (CurrentToken() == Token::kPERIOD) {
    ConsumeToken();
    ctor_name = Symbols::FromConcat(
        T, ctor_name, *ExpectIdentifier("constructor name expected"));
  }
  CheckToken(Token::kLPAREN, "parameter list expected");

  ArgumentListNode* arguments = new ArgumentListNode(supercall_pos);
  // 'this' parameter is the first argument to super class constructor.
  AstNode* implicit_argument = new LoadLocalNode(supercall_pos, receiver);
  arguments->Add(implicit_argument);

  // 'this' parameter must not be accessible to the other super call arguments.
  receiver->set_invisible(true);
  ParseActualParameters(arguments, Object::null_type_arguments(), kAllowConst);
  receiver->set_invisible(false);

  // Resolve the constructor.
  const Function& super_ctor =
      Function::ZoneHandle(Z, super_class.LookupConstructor(ctor_name));
  if (super_ctor.IsNull()) {
    if (super_class.LookupFactory(ctor_name) != Function::null()) {
      ReportError(supercall_pos,
                  "super class constructor '%s' "
                  "must not be a factory constructor",
                  ctor_name.ToCString());
    }
    ReportError(supercall_pos, "super class constructor '%s' not found",
                ctor_name.ToCString());
  }
  if (current_function().is_const() && !super_ctor.is_const()) {
    ReportError(supercall_pos, "super constructor must be const");
  }
  String& error_message = String::Handle(Z);
  if (!super_ctor.AreValidArguments(arguments->type_args_len(),
                                    arguments->length(), arguments->names(),
                                    &error_message)) {
    ReportError(supercall_pos,
                "invalid arguments passed to super class constructor '%s': %s",
                ctor_name.ToCString(), error_message.ToCString());
  }
  return new StaticCallNode(supercall_pos, super_ctor, arguments,
                            StaticCallNode::kSuper);
}

AstNode* Parser::ParseInitializer(const Class& cls,
                                  LocalVariable* receiver,
                                  GrowableArray<Field*>* initialized_fields) {
  TRACE_PARSER("ParseInitializer");
  const TokenPosition field_pos = TokenPos();
  if (CurrentToken() == Token::kASSERT) {
    // Function literals are allowed in assertion initializer.
    // "this" must not be accessible in assertion initializer.
    receiver->set_invisible(true);
    AstNode* init_assert = ParseAssertStatement(current_function().is_const());
    receiver->set_invisible(false);
    return init_assert;
  }
  if (CurrentToken() == Token::kTHIS) {
    ConsumeToken();
    ExpectToken(Token::kPERIOD);
  }
  const String& field_name = *ExpectIdentifier("field name expected");
  ExpectToken(Token::kASSIGN);

  TokenPosition expr_pos = TokenPos();
  const bool saved_mode = SetAllowFunctionLiterals(false);
  // "this" must not be accessible in initializer expressions.
  receiver->set_invisible(true);
  AstNode* init_expr = ParseConditionalExpr();
  if (CurrentToken() == Token::kCASCADE) {
    init_expr = ParseCascades(init_expr);
  }
  receiver->set_invisible(false);
  SetAllowFunctionLiterals(saved_mode);
  if (current_function().is_const()) {
    if (!init_expr->IsPotentiallyConst()) {
      ReportError(expr_pos,
                  "initializer expression must be compile time constant.");
    }
    if (init_expr->EvalConstExpr() != NULL) {
      // If the expression is a compile-time constant, ensure that it
      // is evaluated and canonicalized. See issue 27164.
      init_expr = FoldConstExpr(expr_pos, init_expr);
    }
  }
  Field& field = Field::ZoneHandle(Z, cls.LookupInstanceField(field_name));
  if (field.IsNull()) {
    ReportError(field_pos, "unresolved reference to instance field '%s'",
                field_name.ToCString());
  }
  EnsureExpressionTemp();
  AstNode* instance = new (Z) LoadLocalNode(field_pos, receiver);
  AstNode* initializer = CheckDuplicateFieldInit(field_pos, initialized_fields,
                                                 instance, &field, init_expr);
  if (initializer == NULL) {
    initializer =
        new (Z) StoreInstanceFieldNode(field_pos, instance, field, init_expr,
                                       /* is_initializer = */ true);
  }
  return initializer;
}

void Parser::CheckFieldsInitialized(const Class& cls) {
  const Array& fields = Array::Handle(Z, cls.fields());
  Field& field = Field::Handle(Z);
  SequenceNode* initializers = current_block_->statements;
  for (int field_num = 0; field_num < fields.Length(); field_num++) {
    field ^= fields.At(field_num);
    if (field.is_static()) {
      continue;
    }

    bool found = false;
    for (int i = 0; i < initializers->length(); i++) {
      found = false;
      if (initializers->NodeAt(i)->IsStoreInstanceFieldNode()) {
        StoreInstanceFieldNode* initializer =
            initializers->NodeAt(i)->AsStoreInstanceFieldNode();
        ASSERT(field.IsOriginal());
        if (initializer->field().Original() == field.raw()) {
          found = true;
          break;
        }
      }
    }

    if (found) continue;

    field.RecordStore(Object::null_object());
  }
}

AstNode* Parser::ParseExternalInitializedField(const Field& field) {
  // Only use this function if the initialized field originates
  // from a different class. We need to save and restore the
  // library and token stream (script).
  // The current_class remains unchanged, so that type arguments
  // are resolved in the correct scope class.
  ASSERT(current_class().raw() != field.Origin());
  const Library& saved_library = Library::Handle(Z, library().raw());
  const Script& saved_script = Script::Handle(Z, script().raw());
  const TokenPosition saved_token_pos = TokenPos();

  const Class& origin_class = Class::Handle(Z, field.Origin());
  set_library(Library::Handle(Z, origin_class.library()));
  SetScript(Script::Handle(Z, origin_class.script()), field.token_pos());

  ASSERT(IsIdentifier());
  ConsumeToken();
  ExpectToken(Token::kASSIGN);
  AstNode* init_expr = NULL;
  TokenPosition expr_pos = TokenPos();
  if (field.is_const()) {
    init_expr = ParseConstExpr();
  } else {
    init_expr = ParseExpr(kAllowConst, kConsumeCascades);
    if (init_expr->EvalConstExpr() != NULL) {
      init_expr = FoldConstExpr(expr_pos, init_expr);
    }
  }
  set_library(saved_library);
  SetScript(saved_script, saved_token_pos);
  return init_expr;
}

void Parser::ParseInitializedInstanceFields(
    const Class& cls,
    LocalVariable* receiver,
    GrowableArray<Field*>* initialized_fields) {
  TRACE_PARSER("ParseInitializedInstanceFields");
  const Array& fields = Array::Handle(Z, cls.fields());
  Field& f = Field::Handle(Z);
  const TokenPosition saved_pos = TokenPos();
  for (int i = 0; i < fields.Length(); i++) {
    f ^= fields.At(i);
    if (!f.is_static() && f.has_initializer()) {
      Field& field = Field::ZoneHandle(Z);
      field ^= fields.At(i);
      if (field.is_final()) {
        // Final fields with initializer expression may not be initialized
        // again by constructors. Remember that this field is already
        // initialized.
        initialized_fields->Add(&field);
      }
      AstNode* init_expr = NULL;
      if (current_class().raw() != field.Origin()) {
        init_expr = ParseExternalInitializedField(field);
      } else {
        SetPosition(field.token_pos());
        ASSERT(IsIdentifier());
        ConsumeToken();
        ExpectToken(Token::kASSIGN);
        if (current_class().is_const()) {
          // If the class has a const contructor, the initializer
          // expression must be a compile-time constant.
          init_expr = ParseConstExpr();
        } else {
          TokenPosition expr_pos = TokenPos();
          init_expr = ParseExpr(kAllowConst, kConsumeCascades);
          if (init_expr->EvalConstExpr() != NULL) {
            init_expr = FoldConstExpr(expr_pos, init_expr);
          }
        }
      }
      ASSERT(init_expr != NULL);
      AstNode* instance = new LoadLocalNode(field.token_pos(), receiver);
      EnsureExpressionTemp();
      AstNode* field_init = new StoreInstanceFieldNode(
          field.token_pos(), instance, field, init_expr,
          /* is_initializer = */ true);
      current_block_->statements->Add(field_init);
    }
  }
  initialized_fields->Add(NULL);  // End of inline initializers.
  SetPosition(saved_pos);
}

AstNode* Parser::CheckDuplicateFieldInit(
    TokenPosition init_pos,
    GrowableArray<Field*>* initialized_fields,
    AstNode* instance,
    Field* field,
    AstNode* init_value) {
  ASSERT(!field->is_static());
  AstNode* result = NULL;
  const String& field_name = String::Handle(field->name());
  String& initialized_name = String::Handle(Z);

  // The initializer_list is divided into two sections. The sections
  // are separated by a NULL entry: [f0, ... fn, NULL, fn+1, ...]
  // The first fields f0 .. fn are final fields of the class that
  // have an initializer expression inlined in the class declaration.
  // The remaining fields are those initialized by the constructor's
  // initializing formals and initializer list
  int initializer_idx = 0;
  while (initializer_idx < initialized_fields->length()) {
    Field* initialized_field = (*initialized_fields)[initializer_idx];
    initializer_idx++;
    if (initialized_field == NULL) {
      break;
    }

    initialized_name ^= initialized_field->name();
    if (initialized_name.Equals(field_name) && field->has_initializer()) {
      ReportError(init_pos, "final field '%s' is already initialized.",
                  field_name.ToCString());
    }

    if (initialized_field->raw() == field->raw()) {
      // This final field has been initialized by an inlined
      // initializer expression. This is a runtime error.
      // Throw a NoSuchMethodError for the missing setter.
      ASSERT(field->is_final());

      // Build a call to NoSuchMethodError::_throwNew(
      //     Object receiver,
      //     String memberName,
      //     int invocation_type,
      //     Object typeArguments,
      //     List arguments,
      //     List argumentNames);

      ArgumentListNode* nsm_args = new (Z) ArgumentListNode(init_pos);
      // Object receiver.
      nsm_args->Add(instance);

      // String memberName.
      String& setter_name = String::ZoneHandle(field->name());
      setter_name = Field::SetterSymbol(setter_name);
      nsm_args->Add(new (Z) LiteralNode(init_pos, setter_name));

      // Smi invocation_type.
      const int invocation_type = InvocationMirror::EncodeType(
          InvocationMirror::kDynamic, InvocationMirror::kSetter);
      nsm_args->Add(new (Z) LiteralNode(
          init_pos, Smi::ZoneHandle(Z, Smi::New(invocation_type))));

      // Object typeArguments.
      nsm_args->Add(new (Z)
                        LiteralNode(init_pos, Object::null_type_arguments()));

      // List arguments.
      GrowableArray<AstNode*> setter_args;
      setter_args.Add(init_value);
      ArrayNode* setter_args_array = new (Z) ArrayNode(
          init_pos, Type::ZoneHandle(Z, Type::ArrayType()), setter_args);
      nsm_args->Add(setter_args_array);

      // List argumentNames.
      // The missing implicit setter of the field has no argument names.
      nsm_args->Add(new (Z) LiteralNode(init_pos, Object::null_array()));

      AstNode* nsm_call = MakeStaticCall(
          Symbols::NoSuchMethodError(),
          Library::PrivateCoreLibName(Symbols::ThrowNew()), nsm_args);

      LetNode* let = new (Z) LetNode(init_pos);
      let->AddNode(init_value);
      let->AddNode(nsm_call);
      result = let;
    }
  }
  // The remaining elements in initialized_fields are fields that
  // are initialized through initializing formal parameters, or
  // in the constructor's initializer list. If there is a duplicate,
  // it is a compile time error.
  while (initializer_idx < initialized_fields->length()) {
    Field* initialized_field = (*initialized_fields)[initializer_idx];
    initializer_idx++;
    if (initialized_field->raw() == field->raw()) {
      ReportError(init_pos, "duplicate initializer for field %s",
                  String::Handle(Z, field->name()).ToCString());
    }
  }
  initialized_fields->Add(field);
  return result;
}

void Parser::ParseInitializers(const Class& cls,
                               LocalVariable* receiver,
                               GrowableArray<Field*>* initialized_fields) {
  TRACE_PARSER("ParseInitializers");
  bool super_init_is_last = false;
  intptr_t super_init_index = -1;
  StaticCallNode* super_init_call = NULL;
  if (CurrentToken() == Token::kCOLON) {
    do {
      ConsumeToken();  // Colon or comma.
      if (CurrentToken() == Token::kSUPER) {
        if (super_init_call != NULL) {
          ReportError("duplicate call to super constructor");
        }
        super_init_call = ParseSuperInitializer(cls, receiver);
        super_init_index = current_block_->statements->length();
        current_block_->statements->Add(super_init_call);
        super_init_is_last = true;
      } else {
        AstNode* init_statement =
            ParseInitializer(cls, receiver, initialized_fields);
        super_init_is_last = false;
        if (init_statement != NULL) {
          current_block_->statements->Add(init_statement);
        }
      }
    } while (CurrentToken() == Token::kCOMMA);
  }
  if (super_init_call == NULL) {
    // Generate implicit super() if we haven't seen an explicit super call
    // or constructor redirection.
    super_init_call =
        GenerateSuperConstructorCall(cls, TokenPos(), receiver, NULL);
    if (super_init_call != NULL) {
      super_init_index = current_block_->statements->length();
      current_block_->statements->Add(super_init_call);
      super_init_is_last = true;
    }
  }
  if ((super_init_call != NULL) && !super_init_is_last) {
    // If the super initializer call is not at the end of the initializer
    // list, implicitly move it to the end. The actual parameter values
    // are evaluated at the original position in the list and preserved
    // in temporary variables. (The following initializer expressions
    // could have side effects that alter the arguments to the super
    // initializer.) E.g:
    // A(x) : super(x), f = x++ { ... }
    // is transformed to:
    // A(x) : temp = x, f = x++, super(temp) { ... }
    if (FLAG_warn_super) {
      ReportWarning("Super initializer not at end");
    }
    ASSERT(super_init_index >= 0);
    ArgumentListNode* ctor_args = super_init_call->arguments();
    LetNode* saved_args = new (Z) LetNode(super_init_call->token_pos());
    // The super initializer call has at least 1 arguments: the
    // implicit receiver.
    ASSERT(ctor_args->length() >= 1);
    for (int i = 1; i < ctor_args->length(); i++) {
      AstNode* arg = ctor_args->NodeAt(i);
      LocalVariable* temp = CreateTempConstVariable(arg->token_pos(), "sca");
      AstNode* save_temp = new (Z) StoreLocalNode(arg->token_pos(), temp, arg);
      saved_args->AddNode(save_temp);
      ctor_args->SetNodeAt(i, new (Z) LoadLocalNode(arg->token_pos(), temp));
    }
    current_block_->statements->ReplaceNodeAt(super_init_index, saved_args);
    current_block_->statements->Add(super_init_call);
  }
  CheckFieldsInitialized(cls);
}

void Parser::ParseConstructorRedirection(const Class& cls,
                                         LocalVariable* receiver) {
  TRACE_PARSER("ParseConstructorRedirection");
  ExpectToken(Token::kCOLON);
  ASSERT(CurrentToken() == Token::kTHIS);
  const TokenPosition call_pos = TokenPos();
  ConsumeToken();
  String& ctor_name = String::Handle(Z, cls.Name());
  GrowableHandlePtrArray<const String> pieces(Z, 3);
  pieces.Add(ctor_name);
  pieces.Add(Symbols::Dot());
  if (CurrentToken() == Token::kPERIOD) {
    ConsumeToken();
    pieces.Add(*ExpectIdentifier("constructor name expected"));
  }
  ctor_name = Symbols::FromConcatAll(T, pieces);
  CheckToken(Token::kLPAREN, "parameter list expected");

  ArgumentListNode* arguments = new ArgumentListNode(call_pos);
  // 'this' parameter is the first argument to constructor.
  AstNode* implicit_argument = new LoadLocalNode(call_pos, receiver);
  arguments->Add(implicit_argument);

  receiver->set_invisible(true);
  ParseActualParameters(arguments, Object::null_type_arguments(), kAllowConst);
  receiver->set_invisible(false);
  // Resolve the constructor.
  const Function& redirect_ctor =
      Function::ZoneHandle(Z, cls.LookupConstructor(ctor_name));
  if (redirect_ctor.IsNull()) {
    if (cls.LookupFactory(ctor_name) != Function::null()) {
      ReportError(call_pos,
                  "redirection constructor '%s' must not be a factory",
                  String::Handle(Z, String::ScrubName(ctor_name)).ToCString());
    }
    ReportError(call_pos, "constructor '%s' not found",
                String::Handle(Z, String::ScrubName(ctor_name)).ToCString());
  }
  if (current_function().is_const() && !redirect_ctor.is_const()) {
    ReportError(call_pos, "redirection constructor '%s' must be const",
                String::Handle(Z, redirect_ctor.UserVisibleName()).ToCString());
  }
  String& error_message = String::Handle(Z);
  if (!redirect_ctor.AreValidArguments(arguments->type_args_len(),
                                       arguments->length(), arguments->names(),
                                       &error_message)) {
    ReportError(call_pos, "invalid arguments passed to constructor '%s': %s",
                String::Handle(Z, redirect_ctor.UserVisibleName()).ToCString(),
                error_message.ToCString());
  }
  current_block_->statements->Add(new StaticCallNode(
      call_pos, redirect_ctor, arguments, StaticCallNode::kStatic));
}

SequenceNode* Parser::MakeImplicitConstructor(const Function& func) {
  ASSERT(func.IsGenerativeConstructor());
  ASSERT(func.Owner() == current_class().raw());
  const TokenPosition ctor_pos = TokenPos();
  OpenFunctionBlock(func);

  LocalVariable* receiver =
      new LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                        Symbols::This(), *ReceiverType(current_class()));
  current_block_->scope->InsertParameterAt(0, receiver);

  // Parse expressions of instance fields that have an explicit
  // initializer expression.
  // The receiver must not be visible to field initializer expressions.
  receiver->set_invisible(true);
  GrowableArray<Field*> initialized_fields;
  ParseInitializedInstanceFields(current_class(), receiver,
                                 &initialized_fields);
  receiver->set_invisible(false);

  // If the class of this implicit constructor is a mixin application alias,
  // it is a forwarding constructor of the aliased mixin application class.
  // If the class of this implicit constructor is a mixin application class,
  // it is a forwarding constructor of the mixin. The forwarding
  // constructor initializes the instance fields that have initializer
  // expressions and then calls the respective super constructor with
  // the same name and number of parameters.
  ArgumentListNode* forwarding_args = NULL;
  if (current_class().is_mixin_app_alias() ||
      current_class().IsMixinApplication()) {
    // At this point we don't support forwarding constructors
    // that have optional parameters because we don't know the default
    // values of the optional parameters. We would have to compile the super
    // constructor to get the default values. Also, the spec is not clear
    // whether optional parameters are even allowed in this situation.
    // TODO(hausner): Remove this limitation if the language spec indeed
    // allows optional parameters.
    if (func.HasOptionalParameters()) {
      const Class& super_class = Class::Handle(Z, current_class().SuperClass());
      ReportError(ctor_pos,
                  "cannot generate an implicit mixin application constructor "
                  "forwarding to a super class constructor with optional "
                  "parameters; add a constructor without optional parameters "
                  "to class '%s' that redirects to the constructor with "
                  "optional parameters and invoke it via super from a "
                  "constructor of the class extending the mixin application",
                  String::Handle(Z, super_class.Name()).ToCString());
    }

    // Prepare user-defined arguments to be forwarded to super call.
    // The first user-defined argument is at position 1.
    forwarding_args = new ArgumentListNode(ST(ctor_pos));
    for (int i = 1; i < func.NumParameters(); i++) {
      LocalVariable* param =
          new LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            String::ZoneHandle(Z, func.ParameterNameAt(i)),
                            Object::dynamic_type());
      current_block_->scope->InsertParameterAt(i, param);
      forwarding_args->Add(new LoadLocalNode(ST(ctor_pos), param));
    }
  }

  AstNode* super_call = GenerateSuperConstructorCall(current_class(), ctor_pos,
                                                     receiver, forwarding_args);
  if (super_call != NULL) {
    current_block_->statements->Add(super_call);
  }
  CheckFieldsInitialized(current_class());

  // Empty constructor body.
  current_block_->statements->Add(new ReturnNode(ST(ctor_pos)));
  SequenceNode* statements = CloseBlock();
  return statements;
}

// Returns a zone allocated string.
static char* DumpPendingFunctions(
    Zone* zone,
    const GrowableObjectArray& pending_functions) {
  ASSERT(zone != NULL);
  char* result = OS::SCreate(zone, "Pending Functions:\n");
  for (intptr_t i = 0; i < pending_functions.Length(); i++) {
    const Function& func =
        Function::Handle(zone, Function::RawCast(pending_functions.At(i)));
    const String& fname = String::Handle(zone, func.UserVisibleName());
    result = OS::SCreate(zone, "%s%" Pd ": %s\n", result, i, fname.ToCString());
  }
  return result;
}

void Parser::CheckRecursiveInvocation() {
  const GrowableObjectArray& pending_functions =
      GrowableObjectArray::Handle(Z, T->pending_functions());
  ASSERT(!pending_functions.IsNull());
  for (int i = 0; i < pending_functions.Length(); i++) {
    if (pending_functions.At(i) == current_function().raw()) {
      const String& fname =
          String::Handle(Z, current_function().UserVisibleName());
      if (FLAG_trace_service) {
        const char* pending_function_dump =
            DumpPendingFunctions(Z, pending_functions);
        ASSERT(pending_function_dump != NULL);
        ReportError("circular dependency for function %s\n%s",
                    fname.ToCString(), pending_function_dump);
      } else {
        ReportError("circular dependency for function %s", fname.ToCString());
      }
    }
  }
  ASSERT(!unregister_pending_function_);
  pending_functions.Add(current_function(), Heap::kOld);
  unregister_pending_function_ = true;
}

// Parser is at the opening parenthesis of the formal parameter declaration
// of function. Parse the formal parameters, initializers and code.
SequenceNode* Parser::ParseConstructor(const Function& func) {
  TRACE_PARSER("ParseConstructor");
  ASSERT(func.IsGenerativeConstructor());
  ASSERT(!func.IsFactory());
  ASSERT(!func.is_static());
  ASSERT(!func.IsLocalFunction());
  const Class& cls = Class::Handle(Z, func.Owner());
  ASSERT(!cls.IsNull());

  CheckRecursiveInvocation();

  if (func.IsImplicitConstructor()) {
    // Special case: implicit constructor.
    // The parser adds an implicit default constructor when a class
    // does not have any explicit constructor or factory (see
    // Parser::AddImplicitConstructor).
    // There is no source text to parse. We just build the
    // sequence node by hand.
    return MakeImplicitConstructor(func);
  }

  OpenFunctionBlock(func);
  ParamList params;
  ASSERT(CurrentToken() == Token::kLPAREN);

  // Add implicit receiver parameter which is passed the allocated
  // but uninitialized instance to construct.
  ASSERT(current_class().raw() == func.Owner());
  params.AddReceiver(ReceiverType(current_class()), func.token_pos());

  if (func.is_const()) {
    params.SetImplicitlyFinal();
  }
  const bool use_function_type_syntax = false;
  const bool allow_explicit_default_values = true;
  const bool evaluate_metadata = false;
  ParseFormalParameterList(use_function_type_syntax,
                           allow_explicit_default_values, evaluate_metadata,
                           &params);
  FinalizeFormalParameterTypes(&params);

  SetupDefaultsForOptionalParams(params);
  ASSERT(AbstractType::Handle(Z, func.result_type()).IsResolved());

  // Now populate function scope with the formal parameters.
  AddFormalParamsToScope(&params, current_block_->scope);

  const bool is_redirecting_constructor =
      (CurrentToken() == Token::kCOLON) &&
      ((LookaheadToken(1) == Token::kTHIS) &&
       ((LookaheadToken(2) == Token::kLPAREN) ||
        ((LookaheadToken(2) == Token::kPERIOD) &&
         (LookaheadToken(4) == Token::kLPAREN))));

  GrowableArray<Field*> initialized_fields;
  LocalVariable* receiver = (*params.parameters)[0].var;
  OpenBlock();

  // If this is not a redirecting constructor, initialize
  // instance fields that have an explicit initializer expression.
  if (!is_redirecting_constructor) {
    // The formal parameter names must not be visible to the instance
    // field initializer expressions, yet the parameters must be added to
    // the scope so the expressions use the correct offsets for 'this' when
    // storing values. We make the formal parameters temporarily invisible
    // while parsing the instance field initializer expressions.
    params.SetInvisible(true);
    ParseInitializedInstanceFields(cls, receiver, &initialized_fields);
    // Make the parameters (which are in the outer scope) visible again.
    params.SetInvisible(false);
  }

  // Turn formal field parameters into field initializers.
  if (params.has_field_initializer) {
    // The first parameter is the implicit receiver.
    ASSERT(params.parameters->length() >= 1);
    for (int i = 1; i < params.parameters->length(); i++) {
      ParamDesc& param = (*params.parameters)[i];
      if (param.is_field_initializer) {
        const String& field_name = *param.name;
        Field& field =
            Field::ZoneHandle(Z, cls.LookupInstanceField(field_name));
        if (field.IsNull()) {
          ReportError(param.name_pos,
                      "unresolved reference to instance field '%s'",
                      field_name.ToCString());
        }
        if (is_redirecting_constructor) {
          ReportError(param.name_pos,
                      "redirecting constructors may not have "
                      "initializing formal parameters");
        }

        if (!param.has_explicit_type) {
          const AbstractType& field_type =
              AbstractType::ZoneHandle(Z, field.type());
          param.type = &field_type;
          // Parameter type was already set to dynamic when parsing the class
          // declaration: fix it.
          func.SetParameterTypeAt(i, field_type);
        }

        AstNode* instance = new LoadLocalNode(param.name_pos, receiver);
        // Initializing formals cannot be used in the explicit initializer
        // list, nor can they be used in the constructor body.
        // Thus, they are set to be invisible when added to the scope.
        LocalVariable* p = param.var;
        ASSERT(p != NULL);
        AstNode* value = new LoadLocalNode(param.name_pos, p);
        EnsureExpressionTemp();
        AstNode* initializer = CheckDuplicateFieldInit(
            param.name_pos, &initialized_fields, instance, &field, value);
        if (initializer == NULL) {
          initializer = new (Z)
              StoreInstanceFieldNode(param.name_pos, instance, field, value,
                                     /* is_initializer = */ true);
        }
        current_block_->statements->Add(initializer);
      }
    }
  }

  if (is_redirecting_constructor) {
    ParseConstructorRedirection(cls, receiver);
  } else {
    ParseInitializers(cls, receiver, &initialized_fields);
  }

  SequenceNode* init_statements = CloseBlock();
  current_block_->statements->Add(init_statements);

  // Parsing of initializers done. Now we parse the constructor body.
  OpenBlock();  // Block to collect constructor body nodes.
  if (FLAG_initializing_formal_access) {
    params.HideInitFormals();
  }
  if (CurrentToken() == Token::kLBRACE) {
    // We checked in the top-level parse phase that a redirecting
    // constructor does not have a body.
    ASSERT(!is_redirecting_constructor);
    ConsumeToken();
    ParseStatementSequence();
    ExpectToken(Token::kRBRACE);
  } else if (CurrentToken() == Token::kARROW) {
    ReportError("constructors may not return a value");
  } else if (IsSymbol(Symbols::Native())) {
    ReportError("native constructors not supported");
  } else if (CurrentToken() == Token::kSEMICOLON) {
    // Some constructors have no function body.
    ConsumeToken();
    if (func.is_external()) {
      // Body of an external method contains a single throw.
      const String& function_name = String::ZoneHandle(func.name());
      current_block_->statements->Add(ThrowNoSuchMethodError(
          TokenPos(), cls, function_name,
          NULL,  // No arguments.
          InvocationMirror::kStatic, InvocationMirror::kMethod,
          NULL));  // No existing function.
    }
  } else {
    UnexpectedToken();
  }

  SequenceNode* ctor_block = CloseBlock();
  if (ctor_block->length() > 0) {
    current_block_->statements->Add(ctor_block);
  }
  current_block_->statements->Add(new ReturnNode(func.end_token_pos()));
  SequenceNode* statements = CloseBlock();
  return statements;
}

// Parser is at the opening parenthesis of the formal parameter
// declaration of the function or constructor.
// Parse the formal parameters and code.
SequenceNode* Parser::ParseFunc(const Function& func, bool check_semicolon) {
  TRACE_PARSER("ParseFunc");
  ASSERT(innermost_function().raw() == func.raw());

  // Save current try index. Try index starts at zero for each function.
  intptr_t saved_try_index = last_used_try_index_;
  last_used_try_index_ = 0;

  // In case of nested async functions we also need to save the scope where
  // temporaries are added.
  LocalScope* saved_async_temp_scope = async_temp_scope_;

  if (func.IsGenerativeConstructor()) {
    SequenceNode* statements = ParseConstructor(func);
    last_used_try_index_ = saved_try_index;
    return statements;
  }

  ASSERT(!func.IsGenerativeConstructor());
  OpenFunctionBlock(func);  // Build local scope for function.

  if (FLAG_reify_generic_functions) {
    // Lookup function type arguments variable in parent function scope, if any.
    if (func.HasGenericParent()) {
      const String* variable_name = &Symbols::FunctionTypeArgumentsVar();
      LocalVariable* parent_type_arguments =
          current_block_->scope->LookupVariable(*variable_name, true);
      ASSERT(parent_type_arguments != NULL);
      // TODO(regis): It may be too early to capture parent_type_arguments here.
      // In case it is never used, we could save capturing and concatenating.
      current_block_->scope->CaptureVariable(parent_type_arguments);
      if (FunctionLevel() == 0) {
        parsed_function_->set_parent_type_arguments(parent_type_arguments);
        if (!func.IsGeneric() && parent_type_arguments->is_captured()) {
          parsed_function_->set_function_type_arguments(parent_type_arguments);
        }
      }
    }
    if (func.IsGeneric()) {
      // Insert function type arguments variable to scope.
      LocalVariable* function_type_arguments = new (Z) LocalVariable(
          TokenPosition::kNoSource, TokenPosition::kNoSource,
          Symbols::FunctionTypeArgumentsVar(), Object::dynamic_type());
      current_block_->scope->AddVariable(function_type_arguments);
      if (FunctionLevel() == 0) {
        parsed_function_->set_function_type_arguments(function_type_arguments);
      }
    }
  }

  ParamList params;
  // An instance closure function may capture and access the receiver, but via
  // the context and not via the first formal parameter.
  if (func.IsClosureFunction()) {
    // The first parameter of a closure function is the closure object.
    ASSERT(!func.is_const());  // Closure functions cannot be const.
    params.AddFinalParameter(TokenPos(), &Symbols::ClosureParameter(),
                             &Object::dynamic_type());
  } else if (!func.is_static()) {
    // Static functions do not have a receiver.
    ASSERT(current_class().raw() == func.Owner());
    params.AddReceiver(ReceiverType(current_class()), func.token_pos());
  } else if (func.IsFactory()) {
    // The first parameter of a factory is the TypeArguments vector of
    // the type of the instance to be allocated.
    params.AddFinalParameter(TokenPos(), &Symbols::TypeArgumentsParameter(),
                             &Object::dynamic_type());
  }
  // Expect the parameter list unless this is a getter function, or the
  // body closure of an async or generator getter function.
  ASSERT((CurrentToken() == Token::kLPAREN) || func.IsGetterFunction() ||
         (func.is_generated_body() &&
          Function::Handle(func.parent_function()).IsGetterFunction()));
  if (func.IsGetterFunction()) {
    // Populate function scope with the formal parameters. Since in this case
    // we are compiling a getter this will at most populate the receiver.
    AddFormalParamsToScope(&params, current_block_->scope);
  } else if (func.IsAsyncClosure()) {
    AddAsyncClosureParameters(&params);
    SetupDefaultsForOptionalParams(params);
    AddFormalParamsToScope(&params, current_block_->scope);
    ASSERT(AbstractType::Handle(Z, func.result_type()).IsResolved());
    ASSERT(func.NumParameters() == params.parameters->length());
    if (!Function::Handle(func.parent_function()).IsGetterFunction()) {
      // Skip formal parameters. They are accessed as context variables.
      // Parsing them again (and discarding them) does not work in case of
      // default values with same name as already parsed formal parameter.
      SkipToMatchingParenthesis();
    }
  } else if (func.IsSyncGenClosure()) {
    AddSyncGenClosureParameters(&params);
    SetupDefaultsForOptionalParams(params);
    AddFormalParamsToScope(&params, current_block_->scope);
    ASSERT(AbstractType::Handle(Z, func.result_type()).IsResolved());
    if (!Function::Handle(func.parent_function()).IsGetterFunction()) {
      // Skip formal parameters. They are accessed as context variables.
      // Parsing them again (and discarding them) does not work in case of
      // default values with same name as already parsed formal parameter.
      SkipToMatchingParenthesis();
    }
  } else if (func.IsAsyncGenClosure()) {
    AddAsyncGenClosureParameters(&params);
    SetupDefaultsForOptionalParams(params);
    AddFormalParamsToScope(&params, current_block_->scope);
    ASSERT(AbstractType::Handle(Z, func.result_type()).IsResolved());
    ASSERT(func.NumParameters() == params.parameters->length());
    if (!Function::Handle(func.parent_function()).IsGetterFunction()) {
      // Skip formal parameters. They are accessed as context variables.
      // Parsing them again (and discarding them) does not work in case of
      // default values with same name as already parsed formal parameter.
      SkipToMatchingParenthesis();
    }
  } else {
    const bool use_function_type_syntax = false;
    const bool allow_explicit_default_values = true;
    const bool evaluate_metadata = false;
    ParseFormalParameterList(use_function_type_syntax,
                             allow_explicit_default_values, evaluate_metadata,
                             &params);
    if (!is_top_level_) {
      FinalizeFormalParameterTypes(&params);
    }

    // The number of parameters and their type are not yet set in local
    // functions, since they are not 'top-level' parsed.
    // However, they are already set when the local function is compiled, since
    // the local function was parsed when its parent was compiled.
    if (func.parameter_types() == Object::empty_array().raw()) {
      AddFormalParamsToFunction(&params, func);
    }
    ResolveSignatureTypeParameters(func);
    if (!is_top_level_) {
      ClassFinalizer::FinalizeSignature(Class::Handle(Z, func.origin()), func);
    }
    SetupDefaultsForOptionalParams(params);
    ASSERT(AbstractType::Handle(Z, func.result_type()).IsResolved());

    // Populate function scope with the formal parameters.
    AddFormalParamsToScope(&params, current_block_->scope);
  }

  const TokenPosition modifier_pos = TokenPos();
  RawFunction::AsyncModifier func_modifier = ParseFunctionModifier();
  if (!func.is_generated_body()) {
    // Don't add a modifier to the closure representing the body of
    // the asynchronous function or generator.
    func.set_modifier(func_modifier);
  }

  OpenBlock();  // Open a nested scope for the outermost function block.

  Function& generated_body_closure = Function::ZoneHandle(Z);
  if (func.IsAsyncFunction()) {
    ASSERT(!func.is_generated_body());
    // The code of an async function is synthesized. Disable debugging.
    func.set_is_debuggable(false);
    if (FLAG_causal_async_stacks) {
      // In order to collect causal asynchronous stacks efficiently we rely on
      // this function not being inlined.
      func.set_is_inlinable(false);
    }
    generated_body_closure = OpenAsyncFunction(func.token_pos());
  } else if (func.IsAsyncClosure()) {
    // The closure containing the body of an async function is debuggable.
    ASSERT(func.is_debuggable());
    if (FLAG_causal_async_stacks) {
      // In order to collect causal asynchronous stacks efficiently we rely on
      // this function not being inlined.
      func.set_is_inlinable(false);
    }
    OpenAsyncClosure();
  } else if (func.IsSyncGenerator()) {
    // The code of a sync generator is synthesized. Disable debugging.
    func.set_is_debuggable(false);
    generated_body_closure = OpenSyncGeneratorFunction(func.token_pos());
  } else if (func.IsSyncGenClosure()) {
    // The closure containing the body of a sync generator is debuggable.
    ASSERT(func.is_debuggable());
    async_temp_scope_ = current_block_->scope;
  } else if (func.IsAsyncGenerator()) {
    func.set_is_debuggable(false);
    if (FLAG_causal_async_stacks) {
      // In order to collect causal asynchronous stacks efficiently we rely on
      // this function not being inlined.
      func.set_is_inlinable(false);
    }
    generated_body_closure = OpenAsyncGeneratorFunction(func.token_pos());
  } else if (func.IsAsyncGenClosure()) {
    // The closure containing the body of an async* function is debuggable.
    ASSERT(func.is_debuggable());
    if (FLAG_causal_async_stacks) {
      // In order to collect causal asynchronous stacks efficiently we rely on
      // this function not being inlined.
      func.set_is_inlinable(false);
    }
    OpenAsyncGeneratorClosure();
  }

  // Function level is now correctly set to parse the (possibly async) body.
  if (I->type_checks() && (FunctionLevel() > 0)) {
    // We are parsing, but not compiling, a local function.
    // The instantiator may be required at run time for generic type checks.
    // Note that the source of this local function may not reference the
    // generic type explicitly. However, it may assign a value to a captured
    // variable declared with its generic type in the enclosing function.
    // Make sure that the receiver of the enclosing instance function
    // (or implicit first parameter of an enclosing factory) is marked as
    // captured if type checks are enabled, because they may access it to
    // instantiate types.
    // If any enclosing parent of the function being parsed is generic, capture
    // their function type arguments.
    CaptureAllInstantiators();
  }

  BoolScope allow_await(&this->await_is_keyword_,
                        func.IsAsyncOrGenerator() || func.is_generated_body());
  TokenPosition end_token_pos = TokenPosition::kNoSource;
  if (CurrentToken() == Token::kLBRACE) {
    ConsumeToken();
    if (String::Handle(Z, func.name()).Equals(Symbols::EqualOperator())) {
      const Class& owner = Class::Handle(Z, func.Owner());
      if (!owner.IsObjectClass()) {
        AddEqualityNullCheck();
      }
    }
    ParseStatementSequence();
    end_token_pos = TokenPos();
    ExpectToken(Token::kRBRACE);
  } else if (CurrentToken() == Token::kARROW) {
    if (func.IsGenerator()) {
      ReportError(modifier_pos,
                  "=> style function may not be sync* or async* generator");
    }
    ConsumeToken();
    if (String::Handle(Z, func.name()).Equals(Symbols::EqualOperator())) {
      const Class& owner = Class::Handle(Z, func.Owner());
      if (!owner.IsObjectClass()) {
        AddEqualityNullCheck();
      }
    }
    const TokenPosition expr_pos = TokenPos();
    AstNode* expr = ParseAwaitableExpr(kAllowConst, kConsumeCascades, NULL);
    ASSERT(expr != NULL);
    expr = AddAsyncResultTypeCheck(expr_pos, expr);
    current_block_->statements->Add(new (Z) ReturnNode(expr_pos, expr));
    end_token_pos = TokenPos();
    if (check_semicolon) {
      ExpectSemicolon();
    }
  } else if (IsSymbol(Symbols::Native())) {
    if (String::Handle(Z, func.name()).Equals(Symbols::EqualOperator())) {
      const Class& owner = Class::Handle(Z, func.Owner());
      if (!owner.IsObjectClass()) {
        AddEqualityNullCheck();
      }
    }
    ParseNativeFunctionBlock(&params, func);
    end_token_pos = TokenPos();
    ExpectSemicolon();
  } else if (func.is_external()) {
    // Body of an external method contains a single throw.
    const String& function_name = String::ZoneHandle(Z, func.name());
    current_block_->statements->Add(ThrowNoSuchMethodError(
        TokenPos(), Class::Handle(func.Owner()), function_name,
        NULL,  // Ignore arguments.
        func.is_static() ? InvocationMirror::kStatic
                         : InvocationMirror::kDynamic,
        InvocationMirror::kMethod,
        &func));  // Unpatched external function.
    end_token_pos = TokenPos();
  } else {
    UnexpectedToken();
  }

  ASSERT(func.end_token_pos() == func.token_pos() ||
         func.end_token_pos() == end_token_pos);
  func.set_end_token_pos(end_token_pos);
  SequenceNode* body = CloseBlock();
  if (FLAG_reify_generic_functions && func.IsGeneric() &&
      !generated_body_closure.IsNull()) {
    LocalVariable* existing_var = body->scope()->LookupVariable(
        Symbols::FunctionTypeArgumentsVar(), false);
    ASSERT((existing_var != NULL) && existing_var->is_captured());
  }
  if (func.IsAsyncFunction()) {
    body = CloseAsyncFunction(generated_body_closure, body);
    generated_body_closure.set_end_token_pos(end_token_pos);
  } else if (func.IsAsyncClosure()) {
    body = CloseAsyncClosure(body, end_token_pos);
  } else if (func.IsSyncGenerator()) {
    body = CloseSyncGenFunction(generated_body_closure, body);
    generated_body_closure.set_end_token_pos(end_token_pos);
  } else if (func.IsSyncGenClosure()) {
    // body is unchanged.
  } else if (func.IsAsyncGenerator()) {
    body = CloseAsyncGeneratorFunction(generated_body_closure, body);
    generated_body_closure.set_end_token_pos(end_token_pos);
  } else if (func.IsAsyncGenClosure()) {
    body = CloseAsyncGeneratorClosure(body);
  }
  EnsureHasReturnStatement(body, end_token_pos);
  current_block_->statements->Add(body);
  last_used_try_index_ = saved_try_index;
  async_temp_scope_ = saved_async_temp_scope;
  return CloseBlock();
}

void Parser::AddEqualityNullCheck() {
  AstNode* argument = new LoadLocalNode(
      TokenPosition::kNoSource, current_block_->scope->parent()->VariableAt(1));
  LiteralNode* null_operand =
      new LiteralNode(TokenPosition::kNoSource, Instance::ZoneHandle(Z));
  ComparisonNode* check_arg = new ComparisonNode(
      TokenPosition::kNoSource, Token::kEQ_STRICT, argument, null_operand);
  ComparisonNode* result =
      new ComparisonNode(TokenPosition::kNoSource, Token::kEQ_STRICT,
                         LoadReceiver(TokenPosition::kNoSource), null_operand);
  SequenceNode* arg_is_null =
      new SequenceNode(TokenPosition::kNoSource, current_block_->scope);
  arg_is_null->Add(new ReturnNode(TokenPosition::kNoSource, result));
  IfNode* if_arg_null =
      new IfNode(TokenPosition::kNoSource, check_arg, arg_is_null, NULL);
  current_block_->statements->Add(if_arg_null);
}

AstNode* Parser::AddAsyncResultTypeCheck(TokenPosition expr_pos,
                                         AstNode* expr) {
  if (I->type_checks() &&
      (((FunctionLevel() == 0) && current_function().IsAsyncClosure()))) {
    // In checked mode, when the declared result type is Future<T>, verify
    // that the returned expression is of type T or Future<T> as follows:
    // return temp = expr, temp is Future ? temp as Future<T> : temp as T;
    // In case of a mismatch, we need a TypeError and not a CastError, so
    // we do not actually implement an "as" test, but an "assignable" test.
    Function& async_func =
        Function::Handle(Z, current_function().parent_function());
    const AbstractType& result_type =
        AbstractType::ZoneHandle(Z, async_func.result_type());
    const Class& future_class =
        Class::ZoneHandle(Z, I->object_store()->future_class());
    ASSERT(!future_class.IsNull());
    if (result_type.type_class() == future_class.raw()) {
      const TypeArguments& result_type_args =
          TypeArguments::ZoneHandle(Z, result_type.arguments());
      if (!result_type_args.IsNull() && (result_type_args.Length() == 1)) {
        const AbstractType& result_type_arg =
            AbstractType::ZoneHandle(Z, result_type_args.TypeAt(0));
        LetNode* checked_expr = new (Z) LetNode(expr_pos);
        LocalVariable* temp = checked_expr->AddInitializer(expr);
        temp->set_is_final();
        const AbstractType& future_type =
            AbstractType::ZoneHandle(Z, future_class.RareType());
        AstNode* is_future = new (Z) LoadLocalNode(expr_pos, temp);
        is_future =
            new (Z) ComparisonNode(expr_pos, Token::kIS, is_future,
                                   new (Z) TypeNode(expr_pos, future_type));
        AstNode* as_future_t = new (Z) LoadLocalNode(expr_pos, temp);
        as_future_t = new (Z) AssignableNode(expr_pos, as_future_t, result_type,
                                             Symbols::FunctionResult());
        AstNode* as_t = new (Z) LoadLocalNode(expr_pos, temp);
        as_t = new (Z) AssignableNode(expr_pos, as_t, result_type_arg,
                                      Symbols::FunctionResult());
        checked_expr->AddNode(new (Z) ConditionalExprNode(expr_pos, is_future,
                                                          as_future_t, as_t));
        expr = checked_expr;
      }
    }
  }
  return expr;
}

void Parser::SkipIf(Token::Kind token) {
  if (CurrentToken() == token) {
    ConsumeToken();
  }
}

void Parser::SkipInitializers() {
  ASSERT(CurrentToken() == Token::kCOLON);
  do {
    ConsumeToken();  // Colon or comma.
    if (CurrentToken() == Token::kSUPER) {
      ConsumeToken();
      if (CurrentToken() == Token::kPERIOD) {
        ConsumeToken();
        ExpectIdentifier("identifier expected");
      }
      CheckToken(Token::kLPAREN);
      SkipToMatchingParenthesis();
    } else if (CurrentToken() == Token::kASSERT) {
      ConsumeToken();
      CheckToken(Token::kLPAREN);
      SkipToMatchingParenthesis();
    } else {
      SkipIf(Token::kTHIS);
      SkipIf(Token::kPERIOD);
      ExpectIdentifier("identifier expected");
      ExpectToken(Token::kASSIGN);
      SetAllowFunctionLiterals(false);
      SkipExpr();
      SetAllowFunctionLiterals(true);
    }
  } while (CurrentToken() == Token::kCOMMA);
}

// If the current identifier is a library prefix followed by a period,
// consume the identifier and period, and return the resolved library
// prefix.
RawLibraryPrefix* Parser::ParsePrefix() {
  ASSERT(IsIdentifier());
  // A library prefix can never stand by itself. It must be followed by
  // a period.
  Token::Kind next_token = LookaheadToken(1);
  if (next_token != Token::kPERIOD) {
    return LibraryPrefix::null();
  }
  const String& ident = *CurrentLiteral();

  // It is relatively fast to look up a name in the library dictionary,
  // compared to searching the nested local scopes. Look up the name
  // in the library scope and return in the common case where ident is
  // not a library prefix.
  LibraryPrefix& prefix =
      LibraryPrefix::Handle(Z, library_.LookupLocalLibraryPrefix(ident));
  if (prefix.IsNull()) {
    return LibraryPrefix::null();
  }

  // A library prefix with the name exists. Now check whether it is
  // shadowed by a local definition.
  if (!is_top_level_ &&
      ResolveIdentInLocalScope(TokenPos(), ident, NULL, NULL)) {
    return LibraryPrefix::null();
  }
  // Check whether the identifier is shadowed by a function type parameter.
  if (InGenericFunctionScope() && (innermost_function().LookupTypeParameter(
                                       ident, NULL) != TypeParameter::null())) {
    return LibraryPrefix::null();
  }
  // Check whether the identifier is shadowed by a class type parameter.
  ASSERT(!current_class().IsNull());
  if (current_class().LookupTypeParameter(ident) != TypeParameter::null()) {
    return LibraryPrefix::null();
  }

  // We have a name that is not shadowed, followed by a period.
  // Consume the identifier, let the caller consume the period.
  ConsumeToken();
  return prefix.raw();
}

void Parser::ParseMethodOrConstructor(ClassDesc* members, MemberDesc* method) {
  TRACE_PARSER("ParseMethodOrConstructor");
  // We are at the beginning of the formal parameters list.
  ASSERT(CurrentToken() == Token::kLPAREN || CurrentToken() == Token::kLT ||
         method->IsGetter());
  ASSERT(method->type != NULL);  // May still be unresolved.
  ASSERT(current_member_ == method);

  if (method->has_covariant) {
    ReportError(method->name_pos,
                "methods and constructors cannot be declared covariant");
  }
  if (method->has_var) {
    ReportError(method->name_pos, "keyword var not allowed for methods");
  }
  if (method->has_final) {
    ReportError(method->name_pos, "'final' not allowed for methods");
  }
  if (method->has_abstract && method->has_static) {
    ReportError(method->name_pos, "static method '%s' cannot be abstract",
                method->name->ToCString());
  }
  if (method->has_const && !method->IsFactoryOrConstructor()) {
    ReportError(method->name_pos, "'const' not allowed for methods");
  }
  if (method->has_abstract && method->IsFactoryOrConstructor()) {
    ReportError(method->name_pos, "constructor cannot be abstract");
  }
  if (method->has_const && method->IsConstructor()) {
    current_class().set_is_const();
  }

  Function& func = Function::Handle(
      Z,
      Function::New(*method->name,  // May change.
                    method->kind, method->has_static, method->has_const,
                    method->has_abstract,  // May change.
                    method->has_external,
                    method->has_native,  // May change.
                    current_class(), method->decl_begin_pos));

  ASSERT(innermost_function().IsNull());
  innermost_function_ = func.raw();

  if (CurrentToken() == Token::kLT) {
    if (!FLAG_generic_method_syntax) {
      ReportError("generic type arguments not supported.");
    }
    TokenPosition type_param_pos = TokenPos();
    if (method->IsFactoryOrConstructor()) {
      ReportError(method->name_pos, "constructor cannot be generic");
    }
    if (method->IsGetter() || method->IsSetter()) {
      ReportError(type_param_pos, "%s cannot be generic",
                  method->IsGetter() ? "getter" : "setter");
    }
    ParseTypeParameters(false);  // Not parameterizing class, but function.
  }

  // Parse the formal parameters.
  const TokenPosition formal_param_pos = TokenPos();
  method->params.Clear();
  // Static functions do not have a receiver.
  // The first parameter of a factory is the TypeArguments vector of
  // the type of the instance to be allocated.
  if (!method->has_static || method->IsConstructor()) {
    method->params.AddReceiver(ReceiverType(current_class()), formal_param_pos);
  } else if (method->IsFactory()) {
    method->params.AddFinalParameter(formal_param_pos,
                                     &Symbols::TypeArgumentsParameter(),
                                     &Object::dynamic_type());
  }
  if (method->has_const) {
    method->params.SetImplicitlyFinal();
  }
  if (!method->IsGetter()) {
    const bool use_function_type_syntax = false;
    const bool allow_explicit_default_values = true;
    const bool evaluate_metadata = false;
    ParseFormalParameterList(use_function_type_syntax,
                             allow_explicit_default_values, evaluate_metadata,
                             &method->params);
  }

  // Now that we know the parameter list, we can distinguish between the
  // unary and binary operator -.
  if (method->has_operator) {
    if ((method->operator_token == Token::kSUB) &&
        (method->params.num_fixed_parameters == 1)) {
      // Patch up name for unary operator - so it does not clash with the
      // name for binary operator -.
      method->operator_token = Token::kNEGATE;
      *method->name = Symbols::Token(Token::kNEGATE).raw();
    }
    CheckOperatorArity(*method);
  }

  // Mangle the name for getter and setter functions and check function
  // arity.
  if (method->IsGetter() || method->IsSetter()) {
    int expected_num_parameters = 0;
    if (method->IsGetter()) {
      expected_num_parameters = (method->has_static) ? 0 : 1;
      method->dict_name = method->name;
      method->name = &String::ZoneHandle(Z, Field::GetterSymbol(*method->name));
    } else {
      ASSERT(method->IsSetter());
      expected_num_parameters = (method->has_static) ? 1 : 2;
      method->dict_name = &String::ZoneHandle(
          Z, Symbols::FromConcat(T, *method->name, Symbols::Equals()));
      method->name = &String::ZoneHandle(Z, Field::SetterSymbol(*method->name));
    }
    if ((method->params.num_fixed_parameters != expected_num_parameters) ||
        (method->params.num_optional_parameters != 0)) {
      ReportError(method->name_pos, "illegal %s parameters",
                  method->IsGetter() ? "getter" : "setter");
    }
  }

  // Parse redirecting factory constructor.
  Type& redirection_type = Type::Handle(Z);
  String& redirection_identifier = String::Handle(Z);
  bool is_redirecting = false;
  if (method->IsFactory() && (CurrentToken() == Token::kASSIGN)) {
    // Default parameter values are disallowed in redirecting factories.
    if (method->params.has_explicit_default_values) {
      ReportError(
          "redirecting factory '%s' may not specify default values "
          "for optional parameters",
          method->name->ToCString());
    }
    if (method->has_external) {
      ReportError(TokenPos(),
                  "external factory constructor '%s' may not have redirection",
                  method->name->ToCString());
    }
    ConsumeToken();
    const TokenPosition type_pos = TokenPos();
    is_redirecting = true;
    const bool consume_unresolved_prefix =
        (LookaheadToken(3) == Token::kLT) ||
        (LookaheadToken(3) == Token::kPERIOD);
    const AbstractType& type = AbstractType::Handle(
        Z, ParseType(ClassFinalizer::kResolveTypeParameters, true,
                     consume_unresolved_prefix));
    if (!type.IsMalformed() && type.IsTypeParameter()) {
      // Replace the type with a malformed type and compile a throw when called.
      redirection_type = ClassFinalizer::NewFinalizedMalformedType(
          Error::Handle(Z),  // No previous error.
          script_, type_pos,
          "factory '%s' may not redirect to type parameter '%s'",
          method->name->ToCString(),
          String::Handle(Z, type.UserVisibleName()).ToCString());
    } else {
      // We handle malformed and malbounded redirection type at run time.
      redirection_type ^= type.raw();
    }
    if (CurrentToken() == Token::kPERIOD) {
      // Named constructor or factory.
      ConsumeToken();
      redirection_identifier = ExpectIdentifier("identifier expected")->raw();
    }
  } else if (CurrentToken() == Token::kCOLON) {
    // Parse initializers.
    if (!method->IsConstructor()) {
      ReportError("initializers only allowed on constructors");
    }
    if (method->has_external) {
      ReportError(TokenPos(),
                  "external constructor '%s' may not have initializers",
                  method->name->ToCString());
    }
    if ((LookaheadToken(1) == Token::kTHIS) &&
        ((LookaheadToken(2) == Token::kLPAREN) ||
         LookaheadToken(4) == Token::kLPAREN)) {
      // Redirected constructor: either this(...) or this.xxx(...).
      is_redirecting = true;
      if (method->params.has_field_initializer) {
        // Constructors that redirect to another constructor must not
        // initialize any fields using field initializer parameters.
        ReportError(formal_param_pos,
                    "Redirecting constructor "
                    "may not use field initializer parameters");
      }
      ConsumeToken();  // Colon.
      ExpectToken(Token::kTHIS);
      GrowableHandlePtrArray<const String> pieces(Z, 3);
      pieces.Add(members->class_name());
      pieces.Add(Symbols::Dot());
      if (CurrentToken() == Token::kPERIOD) {
        ConsumeToken();
        pieces.Add(*ExpectIdentifier("constructor name expected"));
      }
      String& redir_name =
          String::ZoneHandle(Z, Symbols::FromConcatAll(T, pieces));

      method->redirect_name = &redir_name;
      CheckToken(Token::kLPAREN);
      SkipToMatchingParenthesis();
    } else {
      SkipInitializers();
    }
  }

  // Only constructors can redirect to another method.
  ASSERT((method->redirect_name == NULL) || method->IsConstructor());

  if (method->IsConstructor() && method->has_external &&
      method->params.has_field_initializer) {
    ReportError(method->name_pos,
                "external constructor '%s' may not have field initializers",
                method->name->ToCString());
  }

  const TokenPosition modifier_pos = TokenPos();
  RawFunction::AsyncModifier async_modifier = ParseFunctionModifier();
  if ((method->IsFactoryOrConstructor() || method->IsSetter()) &&
      (async_modifier != RawFunction::kNoModifier)) {
    ReportError(modifier_pos, "%s '%s' may not be async, async* or sync*",
                (method->IsSetter()) ? "setter" : "constructor",
                method->name->ToCString());
  }

  TokenPosition method_end_pos = TokenPos();
  String* native_name = NULL;
  if ((CurrentToken() == Token::kLBRACE) || (CurrentToken() == Token::kARROW)) {
    if (method->has_abstract) {
      ReportError(TokenPos(),
                  "abstract method '%s' may not have a function body",
                  method->name->ToCString());
    } else if (method->has_external) {
      ReportError(TokenPos(), "external %s '%s' may not have a function body",
                  method->IsFactoryOrConstructor() ? "constructor" : "method",
                  method->name->ToCString());
    } else if (method->IsConstructor() && method->has_const) {
      ReportError(TokenPos(),
                  "const constructor '%s' may not have a function body",
                  method->name->ToCString());
    } else if (method->IsFactory() && method->has_const) {
      ReportError(TokenPos(), "const factory '%s' may not have a function body",
                  method->name->ToCString());
    }
    if (method->redirect_name != NULL) {
      ReportError(method->name_pos,
                  "Constructor with redirection may not have a function body");
    }
    if (CurrentToken() == Token::kLBRACE) {
      SkipBlock();
      method_end_pos = TokenPos();
      ExpectToken(Token::kRBRACE);
    } else {
      if ((async_modifier & RawFunction::kGeneratorBit) != 0) {
        ReportError(modifier_pos,
                    "=> style function may not be sync* or async* generator");
      }

      ConsumeToken();
      BoolScope allow_await(&this->await_is_keyword_,
                            async_modifier != RawFunction::kNoModifier);
      SkipExpr();
      method_end_pos = TokenPos();
      ExpectSemicolon();
    }
  } else if (IsSymbol(Symbols::Native())) {
    if (method->has_abstract) {
      ReportError(method->name_pos,
                  "abstract method '%s' may not have a function body",
                  method->name->ToCString());
    } else if (method->IsConstructor() && method->has_const) {
      ReportError(method->name_pos, "const constructor '%s' may not be native",
                  method->name->ToCString());
    }
    if (method->redirect_name != NULL) {
      ReportError(method->name_pos,
                  "Constructor with redirection may not have a function body");
    }
    native_name = &ParseNativeDeclaration();
    method_end_pos = TokenPos();
    ExpectSemicolon();
    method->has_native = true;
  } else {
    // We haven't found a method body. Issue error if one is required.
    const bool must_have_body = method->has_static && !method->has_external &&
                                redirection_type.IsNull();
    if (must_have_body) {
      ReportError(method->name_pos, "function body expected for method '%s'",
                  method->name->ToCString());
    }

    if (CurrentToken() == Token::kSEMICOLON) {
      ConsumeToken();
      if (!method->has_static && !method->has_external &&
          !method->IsConstructor()) {
        // Methods, getters and setters without a body are
        // implicitly abstract.
        method->has_abstract = true;
      }
    } else {
      // Signature is not followed by semicolon or body. Issue an
      // appropriate error.
      const bool must_have_semicolon =
          (method->redirect_name != NULL) ||
          (method->IsConstructor() && method->has_const) ||
          method->has_external;
      if (must_have_semicolon) {
        ExpectSemicolon();
      } else {
        ReportError(method->name_pos,
                    "function body or semicolon expected for method '%s'",
                    method->name->ToCString());
      }
    }
  }

  if (method->has_abstract && (async_modifier != RawFunction::kNoModifier)) {
    ReportError(modifier_pos,
                "abstract function '%s' may not be async, async* or sync*",
                method->name->ToCString());
  }

  // Update function object.
  func.set_name(*method->name);
  func.set_is_abstract(method->has_abstract);
  func.set_is_native(method->has_native);
  func.set_result_type(*method->type);
  // The result type may refer to func's type parameters,
  // but was not parsed in the scope of func. Adjust.
  method->type->SetScopeFunction(func);

  func.set_end_token_pos(method_end_pos);
  func.set_is_redirecting(is_redirecting);
  func.set_modifier(async_modifier);
  if (library_.is_dart_scheme() && library_.IsPrivate(*method->name)) {
    func.set_is_reflectable(false);
  }
  if (is_patch_source() && IsPatchAnnotation(method->metadata_pos)) {
    // Currently, we just ignore the patch annotation. If the function
    // name already exists in the patched class, this function will replace
    // the one in the patched class.
    method->metadata_pos = TokenPosition::kNoSource;
  }
  if (method->metadata_pos.IsReal()) {
    library_.AddFunctionMetadata(func, method->metadata_pos);
  }
  if (method->has_native) {
    func.set_native_name(*native_name);
  }

  // If this method is a redirecting factory, set the redirection information.
  if (!redirection_type.IsNull()) {
    ASSERT(func.IsFactory());
    func.SetRedirectionType(redirection_type);
    if (!redirection_identifier.IsNull()) {
      func.SetRedirectionIdentifier(redirection_identifier);
    }
  }

  ASSERT(is_top_level_);
  AddFormalParamsToFunction(&method->params, func);
  ASSERT(innermost_function().raw() == func.raw());
  innermost_function_ = Function::null();
  ResolveSignatureTypeParameters(func);
  members->AddFunction(func);
}

void Parser::ParseFieldDefinition(ClassDesc* members, MemberDesc* field) {
  TRACE_PARSER("ParseFieldDefinition");
  // The parser has read the first field name and is now at the token
  // after the field name.
  ASSERT(CurrentToken() == Token::kSEMICOLON ||
         CurrentToken() == Token::kCOMMA || CurrentToken() == Token::kASSIGN);
  ASSERT(field->type != NULL);
  ASSERT(field->name_pos.IsReal());
  ASSERT(current_member_ == field);
  // All const fields are also final.
  ASSERT(!field->has_const || field->has_final);

  if (field->has_covariant) {
    if (field->has_static) {
      ReportError("static fields cannot be declared covariant");
    } else if (field->has_final) {
      ReportError("final fields cannot be declared covariant");
    }
  }
  if (field->has_abstract) {
    ReportError("keyword 'abstract' not allowed in field declaration");
  }
  if (field->has_external) {
    ReportError("keyword 'external' not allowed in field declaration");
  }
  if (field->has_factory) {
    ReportError("keyword 'factory' not allowed in field declaration");
  }
  if (!field->has_static && field->has_const) {
    ReportError(field->name_pos, "instance field may not be 'const'");
  }
  Function& getter = Function::Handle(Z);
  Function& setter = Function::Handle(Z);
  Field& class_field = Field::ZoneHandle(Z);
  Instance& init_value = Instance::Handle(Z);
  while (true) {
    bool has_initializer = CurrentToken() == Token::kASSIGN;
    bool has_simple_literal = false;
    if (has_initializer) {
      ConsumeToken();
      init_value = Object::sentinel().raw();
      // For static fields, the initialization expression will be parsed
      // through the kImplicitStaticFinalGetter method invocation/compilation.
      // For instance fields, the expression is parsed when a constructor
      // is compiled.
      // For static fields with very simple initializer expressions
      // (e.g. a literal number or string), we optimize away the
      // kImplicitStaticFinalGetter and initialize the field here.
      // However, the class finalizer will check the value type for
      // assignability once the declared field type can be resolved. If the
      // value is not assignable (assuming checked mode and disregarding actual
      // mode), the field value is reset and a kImplicitStaticFinalGetter is
      // created at finalization time.
      if ((LookaheadToken(1) == Token::kSEMICOLON) ||
          (LookaheadToken(1) == Token::kCOMMA)) {
        has_simple_literal = IsSimpleLiteral(*field->type, &init_value);
      }
      SkipExpr();
    } else {
      // Static const and static final fields must have an initializer.
      // Static const fields are implicitly final.
      if (field->has_static && field->has_final) {
        ReportError(field->name_pos,
                    "static %s field '%s' must have an initializer expression",
                    field->has_const ? "const" : "final",
                    field->name->ToCString());
      }
    }

    TokenPosition end_token_pos = TokenPos();

    // Create the field object.
    const bool is_reflectable =
        !(library_.is_dart_scheme() && library_.IsPrivate(*field->name));
    class_field = Field::New(*field->name, field->has_static, field->has_final,
                             field->has_const, is_reflectable, current_class(),
                             *field->type, field->name_pos, end_token_pos);
    class_field.set_has_initializer(has_initializer);
    members->AddField(class_field);
    field->field_ = &class_field;
    if (is_patch_source() && IsPatchAnnotation(field->metadata_pos)) {
      // Currently, we just ignore the patch annotation on fields.
      // All fields in the patch class are added to the patched class.
      field->metadata_pos = TokenPosition::kNoSource;
    }
    if ((field->metadata_pos.IsReal())) {
      library_.AddFieldMetadata(class_field, field->metadata_pos);
    }

    // Start tracking types for fields with simple initializers in their
    // definition. This avoids some of the overhead to track this at runtime
    // and rules out many fields from being unnecessary unboxing candidates.
    if (!field->has_static && has_initializer && has_simple_literal) {
      class_field.RecordStore(init_value);
      if (!init_value.IsNull() && init_value.IsDouble()) {
        class_field.set_is_double_initialized(true);
      }
    }

    // For static final fields (this includes static const fields), set value to
    // "uninitialized" and create a kImplicitStaticFinalGetter getter method.
    if (field->has_static && has_initializer) {
      class_field.SetStaticValue(init_value, true);
      if (!has_simple_literal) {
        String& getter_name =
            String::Handle(Z, Field::GetterSymbol(*field->name));
        getter = Function::New(
            getter_name, RawFunction::kImplicitStaticFinalGetter,
            field->has_static, field->has_const,
            /* is_abstract = */ false,
            /* is_external = */ false,
            /* is_native = */ false, current_class(), field->name_pos);
        getter.set_result_type(*field->type);
        getter.set_is_debuggable(false);
        if (library_.is_dart_scheme() && library_.IsPrivate(*field->name)) {
          getter.set_is_reflectable(false);
        }
        members->AddFunction(getter);
      }
    }

    // For instance fields, we create implicit getter and setter methods.
    if (!field->has_static) {
      String& getter_name =
          String::Handle(Z, Field::GetterSymbol(*field->name));
      getter = Function::New(getter_name, RawFunction::kImplicitGetter,
                             field->has_static, field->has_final,
                             /* is_abstract = */ false,
                             /* is_external = */ false,
                             /* is_native = */ false, current_class(),
                             field->name_pos);
      ParamList params;
      ASSERT(current_class().raw() == getter.Owner());
      params.AddReceiver(ReceiverType(current_class()), field->name_pos);
      getter.set_result_type(*field->type);
      getter.set_is_debuggable(false);
      AddFormalParamsToFunction(&params, getter);
      ResolveSignatureTypeParameters(getter);
      members->AddFunction(getter);
      if (!field->has_final) {
        // Build a setter accessor for non-const fields.
        String& setter_name =
            String::Handle(Z, Field::SetterSymbol(*field->name));
        setter = Function::New(setter_name, RawFunction::kImplicitSetter,
                               field->has_static, field->has_final,
                               /* is_abstract = */ false,
                               /* is_external = */ false,
                               /* is_native = */ false, current_class(),
                               field->name_pos);
        ParamList params;
        ASSERT(current_class().raw() == setter.Owner());
        params.AddReceiver(ReceiverType(current_class()), field->name_pos);
        params.AddFinalParameter(TokenPos(), &Symbols::Value(), field->type);
        setter.set_result_type(Object::void_type());
        setter.set_is_debuggable(false);
        if (library_.is_dart_scheme() && library_.IsPrivate(*field->name)) {
          setter.set_is_reflectable(false);
        }
        AddFormalParamsToFunction(&params, setter);
        ResolveSignatureTypeParameters(setter);
        members->AddFunction(setter);
      }
    }

    if (CurrentToken() != Token::kCOMMA) {
      break;
    }
    ConsumeToken();
    field->name_pos = this->TokenPos();
    field->name = ExpectIdentifier("field name expected");
  }
  ExpectSemicolon();
}

void Parser::CheckOperatorArity(const MemberDesc& member) {
  intptr_t expected_num_parameters;  // Includes receiver.
  Token::Kind op = member.operator_token;
  if (op == Token::kASSIGN_INDEX) {
    expected_num_parameters = 3;
  } else if ((op == Token::kBIT_NOT) || (op == Token::kNEGATE)) {
    expected_num_parameters = 1;
  } else {
    expected_num_parameters = 2;
  }
  if ((member.params.num_optional_parameters > 0) ||
      member.params.has_optional_positional_parameters ||
      member.params.has_optional_named_parameters ||
      (member.params.num_fixed_parameters != expected_num_parameters)) {
    // Subtract receiver when reporting number of expected arguments.
    ReportError(member.name_pos, "operator %s expects %" Pd " argument(s)",
                member.name->ToCString(), (expected_num_parameters - 1));
  }
}

void Parser::CheckMemberNameConflict(ClassDesc* members, MemberDesc* member) {
  const String& name = *member->DictName();
  if (name.Equals(members->class_name())) {
    ReportError(member->name_pos, "%s '%s' conflicts with class name",
                member->ToCString(), name.ToCString());
  }
  if (members->clazz().LookupTypeParameter(name) != TypeParameter::null()) {
    ReportError(member->name_pos, "%s '%s' conflicts with type parameter",
                member->ToCString(), name.ToCString());
  }
  for (int i = 0; i < members->members().length(); i++) {
    MemberDesc* existing_member = &members->members()[i];
    if (name.Equals(*existing_member->DictName())) {
      ReportError(
          member->name_pos, "%s '%s' conflicts with previously declared %s",
          member->ToCString(), name.ToCString(), existing_member->ToCString());
    }
  }
}

void Parser::ParseClassMemberDefinition(ClassDesc* members,
                                        TokenPosition metadata_pos) {
  TRACE_PARSER("ParseClassMemberDefinition");
  MemberDesc member;
  current_member_ = &member;
  member.metadata_pos = metadata_pos;
  member.decl_begin_pos = TokenPos();
  if ((CurrentToken() == Token::kEXTERNAL) &&
      (LookaheadToken(1) != Token::kLPAREN)) {
    ConsumeToken();
    member.has_external = true;
  }
  if ((CurrentToken() == Token::kSTATIC) &&
      (LookaheadToken(1) != Token::kLPAREN)) {
    ConsumeToken();
    member.has_static = true;
  }
  if (CurrentToken() == Token::kCOVARIANT) {
    ConsumeToken();
    member.has_covariant = true;
  }
  if (CurrentToken() == Token::kCONST) {
    ConsumeToken();
    member.has_const = true;
  } else if (CurrentToken() == Token::kFINAL) {
    ConsumeToken();
    member.has_final = true;
  }
  if (CurrentToken() == Token::kVAR) {
    if (member.has_const) {
      ReportError("identifier expected after 'const'");
    }
    if (member.has_final) {
      ReportError("identifier expected after 'final'");
    }
    ConsumeToken();
    member.has_var = true;
    // The member type is the 'dynamic' type.
    member.type = &Object::dynamic_type();
  } else if ((CurrentToken() == Token::kFACTORY) &&
             (LookaheadToken(1) != Token::kLPAREN)) {
    ConsumeToken();
    if (member.has_static) {
      ReportError("factory method cannot be explicitly marked static");
    }
    member.has_factory = true;
    member.has_static = true;
    // The result type depends on the name of the factory method.
  }

  // Optionally parse a type.
  bool found_type = false;
  {
    // Lookahead to determine whether the next tokens are a return type.
    TokenPosScope saved_pos(this);
    if (TryParseType(true)) {
      if (IsIdentifier() || (CurrentToken() == Token::kGET) ||
          (CurrentToken() == Token::kSET) ||
          (CurrentToken() == Token::kOPERATOR)) {
        found_type = true;
      }
    }
  }
  if (found_type) {
    // It is too early to resolve the type here, since it can be a result type
    // referring to a not yet declared function type parameter.
    member.type = &AbstractType::ZoneHandle(
        Z, ParseTypeOrFunctionType(true, ClassFinalizer::kDoNotResolve));
  }

  // Optionally parse a (possibly named) constructor name or factory.
  if (IsIdentifier() &&
      (CurrentLiteral()->Equals(members->class_name()) || member.has_factory)) {
    member.name_pos = TokenPos();
    member.name = CurrentLiteral();  // Unqualified identifier.
    ConsumeToken();
    if (member.has_factory) {
      // The factory name may be qualified, but the first identifier must match
      // the name of the immediately enclosing class.
      if (!member.name->Equals(members->class_name())) {
        ReportError(member.name_pos, "factory name must be '%s'",
                    members->class_name().ToCString());
      }
    } else if (member.has_static) {
      ReportError(member.name_pos, "constructor cannot be static");
    }
    if (member.type != NULL) {
      ReportError(member.name_pos, "constructor must not specify return type");
    }
    // Do not bypass class resolution by using current_class() directly, since
    // it may be a patch class.
    const Object& result_type_class =
        Object::Handle(Z, UnresolvedClass::New(LibraryPrefix::Handle(Z),
                                               *member.name, member.name_pos));
    // The type arguments of the result type are the type parameters of the
    // current class. Note that in the case of a patch class, they are copied
    // from the class being patched.
    member.type = &Type::ZoneHandle(
        Z,
        Type::New(result_type_class,
                  TypeArguments::Handle(Z, current_class().type_parameters()),
                  member.name_pos));

    // We must be dealing with a constructor or named constructor.
    member.kind = RawFunction::kConstructor;
    GrowableHandlePtrArray<const String> to_concat(Z, 3);
    to_concat.Add(*member.name);
    to_concat.Add(Symbols::Dot());
    if (CurrentToken() == Token::kPERIOD) {
      // Named constructor.
      ConsumeToken();
      member.dict_name = ExpectIdentifier("identifier expected");
      to_concat.Add(*member.dict_name);
    }
    *member.name = Symbols::FromConcatAll(T, to_concat);
    CheckToken(Token::kLPAREN);
  } else if ((CurrentToken() == Token::kGET) && !member.has_var &&
             (LookaheadToken(1) != Token::kLPAREN) &&
             (LookaheadToken(1) != Token::kLT) &&
             (LookaheadToken(1) != Token::kASSIGN) &&
             (LookaheadToken(1) != Token::kCOMMA) &&
             (LookaheadToken(1) != Token::kSEMICOLON)) {
    ConsumeToken();
    member.kind = RawFunction::kGetterFunction;
    member.name_pos = this->TokenPos();
    member.name = ExpectIdentifier("identifier expected");
    // If the result type was not specified, it will be set to DynamicType.
  } else if ((CurrentToken() == Token::kSET) && !member.has_var &&
             (LookaheadToken(1) != Token::kLPAREN) &&
             (LookaheadToken(1) != Token::kLT) &&
             (LookaheadToken(1) != Token::kASSIGN) &&
             (LookaheadToken(1) != Token::kCOMMA) &&
             (LookaheadToken(1) != Token::kSEMICOLON)) {
    ConsumeToken();
    member.kind = RawFunction::kSetterFunction;
    member.name_pos = this->TokenPos();
    member.name = ExpectIdentifier("identifier expected");
    CheckToken(Token::kLPAREN);
    // The grammar allows a return type, so member.type is not always NULL here.
    // If no return type is specified, the return type of the setter is dynamic.
    if (member.type == NULL) {
      member.type = &Object::dynamic_type();
    }
  } else if ((CurrentToken() == Token::kOPERATOR) && !member.has_var &&
             (LookaheadToken(1) != Token::kLPAREN) &&
             (LookaheadToken(1) != Token::kASSIGN) &&
             (LookaheadToken(1) != Token::kCOMMA) &&
             (LookaheadToken(1) != Token::kSEMICOLON)) {
    // TODO(hausner): handle the case of a generic function named 'operator':
    // eg: T operator<T>(a, b) => ...
    ConsumeToken();
    if (!Token::CanBeOverloaded(CurrentToken())) {
      ReportError("invalid operator overloading");
    }
    if (member.has_static) {
      ReportError("operator overloading functions cannot be static");
    }
    member.operator_token = CurrentToken();
    member.has_operator = true;
    member.kind = RawFunction::kRegularFunction;
    member.name_pos = this->TokenPos();
    member.name =
        &String::ZoneHandle(Z, Symbols::Token(member.operator_token).raw());
    ConsumeToken();
  } else if (IsIdentifier()) {
    member.name = CurrentLiteral();
    member.name_pos = TokenPos();
    ConsumeToken();
  } else {
    ReportError("identifier expected");
  }

  ASSERT(member.name != NULL);
  if (IsParameterPart() || member.IsGetter()) {
    // Constructor or method.
    if (member.type == NULL) {
      member.type = &Object::dynamic_type();
    }
    ASSERT(member.IsFactory() == member.has_factory);
    // Note that member.type may still be unresolved and may refer to not yet
    // parsed function type parameters.
    ParseMethodOrConstructor(members, &member);
  } else if (CurrentToken() == Token::kSEMICOLON ||
             CurrentToken() == Token::kCOMMA ||
             CurrentToken() == Token::kASSIGN) {
    // Field definition.
    if (member.has_const) {
      // const fields are implicitly final.
      member.has_final = true;
    }
    if (member.type == NULL) {
      if (member.has_final) {
        member.type = &Object::dynamic_type();
      } else {
        ReportError(
            "missing 'var', 'final', 'const' or type"
            " in field declaration");
      }
    } else if (member.type->IsVoidType()) {
      ReportError(member.name_pos, "field may not be 'void'");
    }
    if (!member.type->IsResolved()) {
      AbstractType& type = AbstractType::ZoneHandle(Z, member.type->raw());
      ResolveTypeParameters(&type);
      member.type = &type;
    }
    ParseFieldDefinition(members, &member);
  } else {
    UnexpectedToken();
  }
  current_member_ = NULL;
  CheckMemberNameConflict(members, &member);
  members->AddMember(member);
}

void Parser::ParseEnumDeclaration(const GrowableObjectArray& pending_classes,
                                  const Object& tl_owner,
                                  TokenPosition metadata_pos) {
  TRACE_PARSER("ParseEnumDeclaration");
  const TokenPosition declaration_pos =
      (metadata_pos.IsReal()) ? metadata_pos : TokenPos();
  ConsumeToken();
  const TokenPosition name_pos = TokenPos();
  String* enum_name =
      ExpectUserDefinedTypeIdentifier("enum type name expected");
  if (FLAG_trace_parser) {
    OS::Print("TopLevel parsing enum '%s'\n", enum_name->ToCString());
  }
  ExpectToken(Token::kLBRACE);
  if (!IsIdentifier()) {
    ReportError("Enumeration must have at least one name");
  }
  while (IsIdentifier()) {
    ConsumeToken();
    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
      if (CurrentToken() == Token::kRBRACE) {
        break;
      }
    } else if (CurrentToken() == Token::kRBRACE) {
      break;
    } else {
      ReportError(", or } expected");
    }
  }
  ExpectToken(Token::kRBRACE);

  Object& obj = Object::Handle(Z, library_.LookupLocalObject(*enum_name));
  if (!obj.IsNull()) {
    ReportError(name_pos, "'%s' is already defined", enum_name->ToCString());
  }
  Class& cls = Class::Handle(Z);
  cls = Class::New(library_, *enum_name, script_, declaration_pos);
  library_.AddClass(cls);
  cls.set_is_synthesized_class();
  cls.set_is_enum_class();
  if (metadata_pos.IsReal()) {
    library_.AddClassMetadata(cls, tl_owner, metadata_pos);
  }
  cls.set_super_type(Type::Handle(Z, Type::ObjectType()));
  pending_classes.Add(cls, Heap::kOld);
}

void Parser::ParseClassDeclaration(const GrowableObjectArray& pending_classes,
                                   const Object& tl_owner,
                                   TokenPosition metadata_pos) {
  TRACE_PARSER("ParseClassDeclaration");
  bool is_patch = false;
  bool is_abstract = false;
  TokenPosition declaration_pos =
      metadata_pos.IsReal() ? metadata_pos : TokenPos();
  if (is_patch_source() && IsPatchAnnotation(metadata_pos)) {
    is_patch = true;
    metadata_pos = TokenPosition::kNoSource;
    declaration_pos = TokenPos();
  } else if (CurrentToken() == Token::kABSTRACT) {
    is_abstract = true;
    ConsumeToken();
  }
  ExpectToken(Token::kCLASS);
  const TokenPosition classname_pos = TokenPos();
  String& class_name = *ExpectUserDefinedTypeIdentifier("class name expected");
  if (FLAG_trace_parser) {
    OS::Print("TopLevel parsing class '%s'\n", class_name.ToCString());
  }
  Class& cls = Class::Handle(Z);
  TypeArguments& orig_type_parameters = TypeArguments::Handle(Z);
  Object& obj = Object::Handle(Z, library_.LookupLocalObject(class_name));
  if (obj.IsNull()) {
    if (is_patch) {
      ReportError(classname_pos, "missing class '%s' cannot be patched",
                  class_name.ToCString());
    }
    cls = Class::New(library_, class_name, script_, declaration_pos);
    library_.AddClass(cls);
  } else {
    if (!obj.IsClass()) {
      ReportError(classname_pos, "'%s' is already defined",
                  class_name.ToCString());
    }
    cls ^= obj.raw();
    if (is_patch) {
      // Preserve and reuse the original type parameters and bounds since the
      // ones defined in the patch class will not be finalized.
      orig_type_parameters = cls.type_parameters();
      cls = Class::New(library_, class_name, script_, declaration_pos);
    } else {
      // Not patching a class, but it has been found. This must be one of the
      // pre-registered classes from object.cc or a duplicate definition.
      if (!(cls.is_prefinalized() || cls.IsClosureClass() ||
            RawObject::IsImplicitFieldClassId(cls.id()))) {
        ReportError(classname_pos, "class '%s' is already defined",
                    class_name.ToCString());
      }
      // Pre-registered classes need their scripts connected at this time.
      cls.set_script(script_);
      cls.set_token_pos(declaration_pos);
    }
  }
  ASSERT(!cls.IsNull());
  ASSERT(cls.functions() == Object::empty_array().raw());
  set_current_class(cls);
  ParseTypeParameters(true);  // Parameterizing current class.
  if (is_patch) {
    // Check that the new type parameters are identical to the original ones.
    const TypeArguments& new_type_parameters =
        TypeArguments::Handle(Z, cls.type_parameters());
    const int new_type_params_count =
        new_type_parameters.IsNull() ? 0 : new_type_parameters.Length();
    const int orig_type_params_count =
        orig_type_parameters.IsNull() ? 0 : orig_type_parameters.Length();
    if (new_type_params_count != orig_type_params_count) {
      ReportError(classname_pos,
                  "class '%s' must be patched with identical type parameters",
                  class_name.ToCString());
    }
    if (!FLAG_ignore_patch_signature_mismatch) {
      TypeParameter& new_type_param = TypeParameter::Handle(Z);
      TypeParameter& orig_type_param = TypeParameter::Handle(Z);
      String& new_name = String::Handle(Z);
      String& orig_name = String::Handle(Z);
      AbstractType& new_bound = AbstractType::Handle(Z);
      AbstractType& orig_bound = AbstractType::Handle(Z);
      for (int i = 0; i < new_type_params_count; i++) {
        new_type_param ^= new_type_parameters.TypeAt(i);
        orig_type_param ^= orig_type_parameters.TypeAt(i);
        new_name = new_type_param.name();
        orig_name = orig_type_param.name();
        if (!new_name.Equals(orig_name)) {
          ReportError(new_type_param.token_pos(),
                      "type parameter '%s' of patch class '%s' does not match "
                      "original type parameter '%s'",
                      new_name.ToCString(), class_name.ToCString(),
                      orig_name.ToCString());
        }
        new_bound = new_type_param.bound();
        orig_bound = orig_type_param.bound();
        if (!new_bound.Equals(orig_bound)) {
          ReportError(new_type_param.token_pos(),
                      "bound '%s' of type parameter '%s' of patch class '%s' "
                      "does not match original type parameter bound '%s'",
                      String::Handle(new_bound.UserVisibleName()).ToCString(),
                      new_name.ToCString(), class_name.ToCString(),
                      String::Handle(orig_bound.UserVisibleName()).ToCString());
        }
      }
    }
    cls.set_type_parameters(orig_type_parameters);
  }

  if (is_abstract) {
    cls.set_is_abstract();
  }
  if (metadata_pos.IsReal()) {
    library_.AddClassMetadata(cls, tl_owner, metadata_pos);
  }

  const bool is_mixin_declaration = (CurrentToken() == Token::kASSIGN);
  if (is_mixin_declaration && is_patch) {
    ReportError(classname_pos,
                "mixin application '%s' may not be a patch class",
                class_name.ToCString());
  }

  AbstractType& super_type = Type::Handle(Z);
  if ((CurrentToken() == Token::kEXTENDS) || is_mixin_declaration) {
    ConsumeToken();  // extends or =
    const TokenPosition type_pos = TokenPos();
    super_type = ParseType(ClassFinalizer::kResolveTypeParameters);
    if (super_type.IsMalformedOrMalbounded()) {
      ReportError(Error::Handle(Z, super_type.error()));
    }
    if (super_type.IsDynamicType()) {
      // Unlikely here, since super type is not resolved yet.
      ReportError(type_pos, "class '%s' may not extend 'dynamic'",
                  class_name.ToCString());
    }
    if (super_type.IsTypeParameter()) {
      ReportError(type_pos, "class '%s' may not extend type parameter '%s'",
                  class_name.ToCString(),
                  String::Handle(Z, super_type.UserVisibleName()).ToCString());
    }
    // The class finalizer will check whether the super type is malbounded.
    if (is_mixin_declaration) {
      if (CurrentToken() != Token::kWITH) {
        ReportError("mixin application clause 'with type' expected");
      }
      cls.set_is_mixin_app_alias();
      cls.set_is_synthesized_class();
    }
    if (CurrentToken() == Token::kWITH) {
      super_type = ParseMixins(super_type);
    }
  } else {
    // No extends clause: implicitly extend Object, unless Object itself.
    if (!cls.IsObjectClass()) {
      super_type = Type::ObjectType();
    }
  }
  ASSERT(!super_type.IsNull() || cls.IsObjectClass());
  cls.set_super_type(super_type);

  if (CurrentToken() == Token::kIMPLEMENTS) {
    ParseInterfaceList(cls);
  }

  if (is_patch) {
    cls.set_is_patch();
    // Apply the changes to the patched class looked up above.
    ASSERT(obj.raw() == library_.LookupLocalObject(class_name));
    const Class& orig_class = Class::Cast(obj);
    if (orig_class.is_finalized()) {
      orig_class.SetRefinalizeAfterPatch();
      pending_classes.Add(orig_class, Heap::kOld);
    }
    library_.AddPatchClass(cls);
  }
  pending_classes.Add(cls, Heap::kOld);

  if (is_mixin_declaration) {
    ExpectSemicolon();
  } else {
    CheckToken(Token::kLBRACE);
    SkipBlock();
    ExpectToken(Token::kRBRACE);
  }
}

void Parser::ParseClassDefinition(const Class& cls) {
  TRACE_PARSER("ParseClassDefinition");
  INC_STAT(thread(), num_classes_parsed, 1);
  set_current_class(cls);
  is_top_level_ = true;
  String& class_name = String::Handle(Z, cls.Name());
  SkipMetadata();
  if (CurrentToken() == Token::kABSTRACT) {
    ConsumeToken();
  }
  ExpectToken(Token::kCLASS);
  const TokenPosition class_pos = TokenPos();
  ClassDesc members(Z, cls, class_name, false, class_pos);
  while (CurrentToken() != Token::kLBRACE) {
    ConsumeToken();
  }
  ExpectToken(Token::kLBRACE);
  while (CurrentToken() != Token::kRBRACE) {
    TokenPosition metadata_pos = SkipMetadata();
    ParseClassMemberDefinition(&members, metadata_pos);
  }
  ExpectToken(Token::kRBRACE);

  if (cls.LookupTypeParameter(class_name) != TypeParameter::null()) {
    ReportError(class_pos, "class name conflicts with type parameter '%s'",
                class_name.ToCString());
  }
  CheckConstructors(&members);

  // Need to compute this here since MakeFixedLength() will clear the
  // functions array in members.
  const bool need_implicit_constructor =
      !members.has_constructor() && !cls.is_patch();

  cls.AddFields(members.fields());

  // Creating a new array for functions marks the class as parsed.
  Array& array = Array::Handle(Z, members.MakeFunctionsArray());
  cls.SetFunctions(array);

  // Add an implicit constructor if no explicit constructor is present.
  // No implicit constructors are needed for patch classes.
  if (need_implicit_constructor) {
    AddImplicitConstructor(cls);
  }

  if (cls.is_patch()) {
    // Apply the changes to the patched class looked up above.
    Object& obj = Object::Handle(Z, library_.LookupLocalObject(class_name));
    // The patched class must not be finalized yet.
    const Class& orig_class = Class::Cast(obj);
    ASSERT(!orig_class.is_finalized());
    Error& error = Error::Handle(Z);
    // Check if this is a case of patching a class after it has already
    // been finalized.
    if (orig_class.is_refinalize_after_patch()) {
      if (!cls.ValidatePostFinalizePatch(orig_class, &error)) {
        Report::LongJumpF(error, script_, class_pos,
                          "patch validation failed, not applying patch.\n");
      }
    }
    if (!orig_class.ApplyPatch(cls, &error)) {
      Report::LongJumpF(error, script_, class_pos, "applying patch failed");
    }
  }
}

void Parser::ParseEnumDefinition(const Class& cls) {
  TRACE_PARSER("ParseEnumDefinition");
  INC_STAT(thread(), num_classes_parsed, 1);
  set_current_class(cls);
  const Class& helper_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::_EnumHelper()));
  ASSERT(!helper_class.IsNull());

  SkipMetadata();
  ExpectToken(Token::kENUM);

  const String& enum_name = String::Handle(Z, cls.ScrubbedName());
  ClassDesc enum_members(Z, cls, enum_name, false, cls.token_pos());

  // Add instance field 'final int index'.
  Field& index_field = Field::ZoneHandle(Z);
  const Type& int_type = Type::Handle(Z, Type::IntType());
  index_field = Field::New(Symbols::Index(),
                           false,  // Not static.
                           true,   // Field is final.
                           false,  // Not const.
                           true,   // Is reflectable.
                           cls, int_type, cls.token_pos(), cls.token_pos());
  enum_members.AddField(index_field);

  // Add implicit getter for index field.
  const String& getter_name =
      String::Handle(Z, Field::GetterSymbol(Symbols::Index()));
  Function& getter = Function::Handle(Z);
  getter = Function::New(getter_name, RawFunction::kImplicitGetter,
                         /* is_static = */ false,
                         /* is_const = */ true,
                         /* is_abstract = */ false,
                         /* is_external = */ false,
                         /* is_native = */ false, cls, cls.token_pos());
  getter.set_result_type(int_type);
  getter.set_is_debuggable(false);
  ParamList params;
  params.AddReceiver(&Object::dynamic_type(), cls.token_pos());
  AddFormalParamsToFunction(&params, getter);
  ResolveSignatureTypeParameters(getter);
  enum_members.AddFunction(getter);

  ASSERT(IsIdentifier());
  ASSERT(CurrentLiteral()->raw() == cls.Name());

  ConsumeToken();  // Enum type name.
  ExpectToken(Token::kLBRACE);
  Field& enum_value = Field::Handle(Z);
  intptr_t i = 0;
  GrowableArray<String*> declared_names(8);

  while (IsIdentifier()) {
    String* enum_ident = CurrentLiteral();

    // Check for name conflicts.
    if (enum_ident->raw() == cls.Name()) {
      ReportError("enum identifier '%s' cannot be equal to enum type name",
                  CurrentLiteral()->ToCString());
    } else if (enum_ident->raw() == Symbols::Index().raw()) {
      ReportError(
          "enum identifier conflicts with "
          "implicit instance field 'index'");
    } else if (enum_ident->raw() == Symbols::Values().raw()) {
      ReportError(
          "enum identifier conflicts with "
          "implicit static field 'values'");
    } else if (enum_ident->raw() == Symbols::toString().raw()) {
      ReportError(
          "enum identifier conflicts with "
          "implicit instance method 'toString()'");
    }
    for (intptr_t n = 0; n < declared_names.length(); n++) {
      if (enum_ident->Equals(*declared_names[n])) {
        ReportError("Duplicate name '%s' in enum definition '%s'",
                    enum_ident->ToCString(), enum_name.ToCString());
      }
    }
    declared_names.Add(enum_ident);

    // Create the static const field for the enumeration value.
    // Note that we do not set the field type to E, because we temporarily store
    // a Smi in the field. The class finalizer would detect the bad type and
    // reset the value to sentinel.
    enum_value =
        Field::New(*enum_ident,
                   /* is_static = */ true,
                   /* is_final = */ true,
                   /* is_const = */ true,
                   /* is_reflectable = */ true, cls, Object::dynamic_type(),
                   cls.token_pos(), cls.token_pos());
    enum_value.set_has_initializer(false);
    enum_members.AddField(enum_value);
    // Initialize the field with the ordinal value. It will be patched
    // later with the enum constant instance.
    const Smi& ordinal_value = Smi::Handle(Z, Smi::New(i));
    enum_value.SetStaticValue(ordinal_value, true);
    enum_value.RecordStore(ordinal_value);
    i++;

    ConsumeToken();  // Enum value name.
    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
    }
  }
  ExpectToken(Token::kRBRACE);

  const Class& array_class = Class::Handle(Z, I->object_store()->array_class());
  TypeArguments& values_type_args =
      TypeArguments::ZoneHandle(Z, TypeArguments::New(1));
  const Type& enum_type = Type::Handle(Type::NewNonParameterizedType(cls));
  values_type_args.SetTypeAt(0, enum_type);
  Type& values_type = Type::ZoneHandle(
      Z, Type::New(array_class, values_type_args, cls.token_pos(), Heap::kOld));
  values_type ^= CanonicalizeType(values_type);
  values_type_args = values_type.arguments();  // Get canonical type arguments.
  // Add static field 'const List<E> values'.
  Field& values_field = Field::ZoneHandle(Z);
  values_field = Field::New(Symbols::Values(),
                            /* is_static = */ true,
                            /* is_final = */ true,
                            /* is_const = */ true,
                            /* is_reflectable = */ true, cls, values_type,
                            cls.token_pos(), cls.token_pos());
  enum_members.AddField(values_field);

  // Add static field 'const _deleted_enum_sentinel'.
  // This field does not need to be of type E.
  Field& deleted_enum_sentinel = Field::ZoneHandle(Z);
  deleted_enum_sentinel =
      Field::New(Symbols::_DeletedEnumSentinel(),
                 /* is_static = */ true,
                 /* is_final = */ true,
                 /* is_const = */ true,
                 /* is_reflectable = */ false, cls, Object::dynamic_type(),
                 cls.token_pos(), cls.token_pos());
  enum_members.AddField(deleted_enum_sentinel);

  // Allocate the immutable array containing the enumeration values.
  // The actual enum instance values will be patched in later.
  const Array& values_array = Array::Handle(Z, Array::New(i, Heap::kOld));
  values_array.SetTypeArguments(values_type_args);
  values_field.SetStaticValue(values_array, true);
  values_field.RecordStore(values_array);

  // Clone the _name field from the helper class.
  Field& _name_field = Field::Handle(
      Z, helper_class.LookupInstanceFieldAllowPrivate(Symbols::_name()));
  ASSERT(!_name_field.IsNull());
  _name_field = _name_field.Clone(cls);
  enum_members.AddField(_name_field);

  // Add an implicit getter function for the _name field. We use the field's
  // name directly here so that the private key matches those of the other
  // cloned helper functions and fields.
  const Type& string_type = Type::Handle(Z, Type::StringType());
  const String& name_getter_name = String::Handle(
      Z, Field::GetterSymbol(String::Handle(_name_field.name())));
  Function& name_getter = Function::Handle(Z);
  name_getter = Function::New(name_getter_name, RawFunction::kImplicitGetter,
                              /* is_static = */ false,
                              /* is_const = */ true,
                              /* is_abstract = */ false,
                              /* is_external = */ false,
                              /* is_native = */ false, cls, cls.token_pos());
  name_getter.set_result_type(string_type);
  name_getter.set_is_debuggable(false);
  ParamList name_params;
  name_params.AddReceiver(&Object::dynamic_type(), cls.token_pos());
  AddFormalParamsToFunction(&name_params, name_getter);
  ResolveSignatureTypeParameters(name_getter);
  enum_members.AddFunction(name_getter);

  // Clone the toString() function from the helper class.
  Function& to_string_func = Function::Handle(
      Z, helper_class.LookupDynamicFunctionAllowPrivate(Symbols::toString()));
  ASSERT(!to_string_func.IsNull());
  to_string_func = to_string_func.Clone(cls);
  enum_members.AddFunction(to_string_func);

  // Clone the hashCode getter function from the helper class.
  Function& hash_code_func = Function::Handle(
      Z, helper_class.LookupDynamicFunctionAllowPrivate(Symbols::hashCode()));
  ASSERT(!hash_code_func.IsNull());
  hash_code_func = hash_code_func.Clone(cls);
  enum_members.AddFunction(hash_code_func);

  cls.AddFields(enum_members.fields());
  const Array& functions = Array::Handle(Z, enum_members.MakeFunctionsArray());
  cls.SetFunctions(functions);
}

// Add an implicit constructor to the given class.
void Parser::AddImplicitConstructor(const Class& cls) {
  // The implicit constructor is unnamed, has no explicit parameter.
  String& ctor_name = String::ZoneHandle(Z, cls.Name());
  ctor_name = Symbols::FromDot(T, ctor_name);
  // To indicate that this is an implicit constructor, we set the
  // token position and end token position of the function
  // to the token position of the class.
  Function& ctor = Function::Handle(
      Z, Function::New(ctor_name, RawFunction::kConstructor,
                       /* is_static = */ false,
                       /* is_const = */ false,
                       /* is_abstract = */ false,
                       /* is_external = */ false,
                       /* is_native = */ false, cls, cls.token_pos()));
  ctor.set_end_token_pos(ctor.token_pos());
  ctor.set_is_debuggable(false);
  if (library_.is_dart_scheme() && library_.IsPrivate(ctor_name)) {
    ctor.set_is_reflectable(false);
  }

  ParamList params;
  // Add implicit 'this' parameter.
  const AbstractType* receiver_type = ReceiverType(cls);
  params.AddReceiver(receiver_type, cls.token_pos());

  AddFormalParamsToFunction(&params, ctor);
  ctor.set_result_type(Object::dynamic_type());
  ResolveSignatureTypeParameters(ctor);
  // The body of the constructor cannot modify the type of the constructed
  // instance, which is passed in as the receiver.
  ctor.set_result_type(*receiver_type);
  cls.AddFunction(ctor);
}

void Parser::CheckFinalInitializationConflicts(const ClassDesc* class_desc,
                                               const MemberDesc* member) {
  const ParamList* params = &member->params;
  if (!params->has_field_initializer) {
    return;
  }

  const ZoneGrowableArray<ParamDesc>& parameters = *params->parameters;
  const GrowableArray<const Field*>& fields = class_desc->fields();
  String& field_name = String::Handle(Z);

  for (intptr_t p = 0; p < parameters.length(); p++) {
    const ParamDesc& current_param = parameters[p];
    if (!current_param.is_field_initializer) {
      continue;
    }

    const String& param_name = *current_param.name;
    for (intptr_t i = 0; i < fields.length(); i++) {
      const Field* current_field = fields.At(i);
      if (!current_field->is_final() || !current_field->has_initializer()) {
        continue;
      }

      field_name ^= current_field->name();
      if (param_name.Equals(field_name)) {
        ReportError(current_param.name_pos,
                    "final field '%s' is already initialized.",
                    param_name.ToCString());
      }
    }
  }
}

// Check for cycles in constructor redirection.
void Parser::CheckConstructors(ClassDesc* class_desc) {
  // Check for cycles in constructor redirection.
  const GrowableArray<MemberDesc>& members = class_desc->members();
  for (int i = 0; i < members.length(); i++) {
    MemberDesc* member = &members[i];
    if (member->IsConstructor()) {
      // Check that our constructors don't try and reinitialize an initialized
      // final variable.
      CheckFinalInitializationConflicts(class_desc, member);
    }
    if (member->redirect_name == NULL) {
      continue;
    }
    GrowableArray<MemberDesc*> ctors;
    while ((member != NULL) && (member->redirect_name != NULL)) {
      ASSERT(member->IsConstructor());
      // Check whether we have already seen this member.
      for (int i = 0; i < ctors.length(); i++) {
        if (ctors[i] == member) {
          ReportError(member->name_pos,
                      "cyclic reference in constructor redirection");
        }
      }
      // We haven't seen this member. Add it to the list and follow
      // the next redirection. If we can't find the constructor to
      // which the current one redirects, we ignore the unresolved
      // reference. We'll catch it later when the constructor gets
      // compiled.
      ctors.Add(member);
      member = class_desc->LookupMember(*member->redirect_name);
    }
  }
}

void Parser::ParseMixinAppAlias(const GrowableObjectArray& pending_classes,
                                const Object& tl_owner,
                                TokenPosition metadata_pos) {
  TRACE_PARSER("ParseMixinAppAlias");
  const TokenPosition classname_pos = TokenPos();
  String& class_name = *ExpectUserDefinedTypeIdentifier("class name expected");
  if (FLAG_trace_parser) {
    OS::Print("toplevel parsing mixin application alias class '%s'\n",
              class_name.ToCString());
  }
  const Object& obj = Object::Handle(Z, library_.LookupLocalObject(class_name));
  if (!obj.IsNull()) {
    ReportError(classname_pos, "'%s' is already defined",
                class_name.ToCString());
  }
  const Class& mixin_application = Class::Handle(
      Z, Class::New(library_, class_name, script_, classname_pos));
  mixin_application.set_is_mixin_app_alias();
  library_.AddClass(mixin_application);
  set_current_class(mixin_application);
  ParseTypeParameters(true);  // Parameterizing current class.

  ExpectToken(Token::kASSIGN);

  if (CurrentToken() == Token::kABSTRACT) {
    mixin_application.set_is_abstract();
    ConsumeToken();
  }

  const TokenPosition type_pos = TokenPos();
  AbstractType& type = AbstractType::Handle(
      Z, ParseType(ClassFinalizer::kResolveTypeParameters));
  if (type.IsTypeParameter()) {
    ReportError(type_pos, "class '%s' may not extend type parameter '%s'",
                class_name.ToCString(),
                String::Handle(Z, type.UserVisibleName()).ToCString());
  }

  CheckToken(Token::kWITH, "mixin application 'with Type' expected");
  type = ParseMixins(type);

  mixin_application.set_super_type(type);
  mixin_application.set_is_synthesized_class();

  // This mixin application alias needs an implicit constructor, but it is
  // too early to call 'AddImplicitConstructor(mixin_application)' here,
  // because this class should be lazily compiled.
  if (CurrentToken() == Token::kIMPLEMENTS) {
    ParseInterfaceList(mixin_application);
  }
  ExpectSemicolon();
  pending_classes.Add(mixin_application, Heap::kOld);
  if (metadata_pos.IsReal()) {
    library_.AddClassMetadata(mixin_application, tl_owner, metadata_pos);
  }
}

// Look ahead to detect if we are seeing ident [ TypeParameters ] ("(" | "=").
// We need this lookahead to distinguish between the optional return type
// and the alias name of a function type alias.
// Token position remains unchanged.
bool Parser::IsFunctionTypeAliasName(bool* use_function_type_syntax) {
  if (IsIdentifier()) {
    const Token::Kind ahead = LookaheadToken(1);
    if ((ahead == Token::kLPAREN) || (ahead == Token::kASSIGN)) {
      *use_function_type_syntax = (ahead == Token::kASSIGN);
      return true;
    }
  }
  const TokenPosScope saved_pos(this);
  if (IsIdentifier() && (LookaheadToken(1) == Token::kLT)) {
    ConsumeToken();
    if (TryParseTypeParameters()) {
      const Token::Kind current = CurrentToken();
      if ((current == Token::kLPAREN) || (current == Token::kASSIGN)) {
        *use_function_type_syntax = (current == Token::kASSIGN);
        return true;
      }
    }
  }
  *use_function_type_syntax = false;
  return false;
}

void Parser::ParseTypedef(const GrowableObjectArray& pending_classes,
                          const Object& tl_owner,
                          TokenPosition metadata_pos) {
  TRACE_PARSER("ParseTypedef");
  TokenPosition declaration_pos =
      metadata_pos.IsReal() ? metadata_pos : TokenPos();
  ExpectToken(Token::kTYPEDEF);

  // Distinguish between two possible typedef forms:
  // 1) returnType? identifier typeParameters? formalParameterList ’;’
  // 2) identifier typeParameters? '=' functionType ’;’

  bool use_function_type_syntax;  // Set to false for form 1, true for form 2.

  // If present, parse the result type of the function type.
  AbstractType& result_type = Type::Handle(Z);
  if (CurrentToken() == Token::kVOID) {
    ConsumeToken();
    result_type = Type::VoidType();
    use_function_type_syntax = false;
  } else if (!IsFunctionTypeAliasName(&use_function_type_syntax)) {
    // Type annotations in typedef are never ignored, even in production mode.
    // Wait until we have an owner class before resolving the result type.
    result_type = ParseType(ClassFinalizer::kDoNotResolve);
    ASSERT(!use_function_type_syntax);
  }

  const TokenPosition alias_name_pos = TokenPos();
  const String* alias_name =
      ExpectUserDefinedTypeIdentifier("function alias name expected");

  // Lookup alias name and report an error if it is already defined in
  // the library scope.
  const Object& obj =
      Object::Handle(Z, library_.LookupLocalObject(*alias_name));
  if (!obj.IsNull()) {
    ReportError(alias_name_pos, "'%s' is already defined",
                alias_name->ToCString());
  }

  // Create the function type alias scope class. It will be linked to its
  // signature function after it has been parsed. The type parameters, in order
  // to be properly finalized, need to be associated to this scope class as
  // they are parsed.
  const Class& function_type_alias = Class::Handle(
      Z, Class::New(library_, *alias_name, script_, declaration_pos));
  function_type_alias.set_is_synthesized_class();
  function_type_alias.set_is_abstract();
  function_type_alias.set_is_prefinalized();
  // Make sure the function type alias can be recognized as a typedef class by
  // setting its signature function. When use_function_type_syntax is true, this
  // temporary signature function is replaced while parsing the function type.
  Function& signature_function = Function::Handle(
      Z, Function::NewSignatureFunction(function_type_alias,
                                        Function::Handle(Z), alias_name_pos));
  function_type_alias.set_signature_function(signature_function);
  library_.AddClass(function_type_alias);
  ASSERT(function_type_alias.IsTypedefClass());
  ASSERT(current_class().IsTopLevel());
  set_current_class(function_type_alias);
  // Parse the type parameters of the typedef class.
  ParseTypeParameters(true);  // Parameterizing current class.
  ASSERT(innermost_function().IsNull());
  if (use_function_type_syntax) {
    ExpectToken(Token::kASSIGN);
    ASSERT(result_type.IsNull());  // Not parsed yet.
    const Type& function_type = Type::Handle(
        Z, ParseFunctionType(result_type, ClassFinalizer::kDoNotResolve));
    signature_function = function_type.signature();
  } else {
    innermost_function_ = signature_function.raw();
    ParamList params;
    // Parse the formal parameters of the function type.
    CheckToken(Token::kLPAREN, "formal parameter list expected");
    // Add implicit closure object parameter.
    params.AddFinalParameter(TokenPos(), &Symbols::ClosureParameter(),
                             &Object::dynamic_type());
    const bool allow_explicit_default_values = false;
    const bool evaluate_metadata = false;
    ParseFormalParameterList(use_function_type_syntax,
                             allow_explicit_default_values, evaluate_metadata,
                             &params);
    if (result_type.IsNull()) {
      result_type = Type::DynamicType();
    }
    signature_function.set_result_type(result_type);
    // The result type may refer to the signature function's type parameters,
    // but was not parsed in the scope of the signature function. Adjust.
    result_type.SetScopeFunction(signature_function);
    AddFormalParamsToFunction(&params, signature_function);
    ASSERT(innermost_function().raw() == signature_function.raw());
    innermost_function_ = Function::null();
  }
  ExpectSemicolon();
  ASSERT(innermost_function().IsNull());
  ASSERT(function_type_alias.signature_function() == signature_function.raw());

  // At this point, all function type parameters have been parsed and the class
  // function_type_alias is recognized as a typedef, so we can resolve all type
  // parameters in the signature type defined by the typedef.
  AbstractType& function_type =
      Type::Handle(Z, signature_function.SignatureType());
  ASSERT(current_class().raw() == function_type_alias.raw());
  ResolveTypeParameters(&function_type);
  // Resolving does not replace type or signature.
  ASSERT(function_type_alias.signature_function() ==
         Type::Cast(function_type).signature());

  if (FLAG_trace_parser) {
    OS::Print("TopLevel parsing function type alias '%s'\n",
              String::Handle(Z, signature_function.Signature()).ToCString());
  }
  // The alias should not be marked as finalized yet, since it needs to be
  // checked in the class finalizer for illegal self references.
  ASSERT(!function_type_alias.is_finalized());
  pending_classes.Add(function_type_alias, Heap::kOld);
  if (metadata_pos.IsReal()) {
    library_.AddClassMetadata(function_type_alias, tl_owner, metadata_pos);
  }
}

// Consumes exactly one right angle bracket. If the current token is
// a single bracket token, it is consumed normally. However, if it is
// a double bracket, it is replaced by a single bracket token without
// incrementing the token index.
void Parser::ConsumeRightAngleBracket() {
  if (token_kind_ == Token::kGT) {
    ConsumeToken();
  } else if (token_kind_ == Token::kSHR) {
    token_kind_ = Token::kGT;
  } else {
    UNREACHABLE();
  }
}

bool Parser::IsPatchAnnotation(TokenPosition pos) {
  if (pos == TokenPosition::kNoSource) {
    return false;
  }
  TokenPosScope saved_pos(this);
  SetPosition(pos);
  ExpectToken(Token::kAT);
  return IsSymbol(Symbols::Patch());
}

TokenPosition Parser::SkipMetadata() {
  if (CurrentToken() != Token::kAT) {
    return TokenPosition::kNoSource;
  }
  TokenPosition metadata_pos = TokenPos();
  while (CurrentToken() == Token::kAT) {
    ConsumeToken();
    ExpectIdentifier("identifier expected");
    if (CurrentToken() == Token::kPERIOD) {
      ConsumeToken();
      ExpectIdentifier("identifier expected");
      if (CurrentToken() == Token::kPERIOD) {
        ConsumeToken();
        ExpectIdentifier("identifier expected");
      }
    }
    if (CurrentToken() == Token::kLPAREN) {
      SkipToMatchingParenthesis();
    }
  }
  return metadata_pos;
}

void Parser::SkipTypeArguments() {
  if (CurrentToken() == Token::kLT) {
    do {
      ConsumeToken();
      SkipTypeOrFunctionType(true);
    } while (CurrentToken() == Token::kCOMMA);
    Token::Kind token = CurrentToken();
    if ((token == Token::kGT) || (token == Token::kSHR)) {
      ConsumeRightAngleBracket();
    } else {
      ReportError("right angle bracket expected");
    }
  }
}

void Parser::SkipTypeParameters() {
  // Function already parsed, no need to check FLAG_generic_method_syntax.
  if (IsTypeParameters()) {
    const bool skipped = TryParseTypeParameters();
    ASSERT(skipped);
  }
}

void Parser::SkipType(bool allow_void) {
  if (CurrentToken() == Token::kVOID) {
    if (!allow_void) {
      ReportError("'void' not allowed here");
    }
    ConsumeToken();
  } else {
    ExpectIdentifier("type name expected");
    if (CurrentToken() == Token::kPERIOD) {
      ConsumeToken();
      ExpectIdentifier("name expected");
    }
    SkipTypeArguments();
  }
}

void Parser::SkipTypeOrFunctionType(bool allow_void) {
  if (CurrentToken() == Token::kVOID) {
    TokenPosition void_pos = TokenPos();
    ConsumeToken();
    // 'void' is always allowed as result type of a function type.
    if (!allow_void && !IsFunctionTypeSymbol()) {
      ReportError(void_pos, "'void' not allowed here");
    }
  } else if (!IsFunctionTypeSymbol()) {
    // Including 'Function' not followed by '(' or '<'.
    SkipType(false);
  }
  while (IsFunctionTypeSymbol()) {
    ConsumeToken();
    SkipTypeArguments();
    if (CurrentToken() == Token::kLPAREN) {
      SkipToMatchingParenthesis();
    } else {
      ReportError("'(' expected");
    }
  }
}

void Parser::ParseTypeParameters(bool parameterizing_class) {
  TRACE_PARSER("ParseTypeParameters");
  if (CurrentToken() == Token::kLT) {
    GrowableArray<AbstractType*> type_parameters_array(Z, 2);
    intptr_t index = 0;
    TypeParameter& type_parameter = TypeParameter::Handle(Z);
    TypeParameter& existing_type_parameter = TypeParameter::Handle(Z);
    String& existing_type_parameter_name = String::Handle(Z);
    AbstractType& type_parameter_bound = Type::Handle(Z);
    do {
      ConsumeToken();
      const TokenPosition metadata_pos = SkipMetadata();
      const TokenPosition type_parameter_pos = TokenPos();
      const TokenPosition declaration_pos =
          metadata_pos.IsReal() ? metadata_pos : type_parameter_pos;
      String& type_parameter_name =
          *ExpectUserDefinedTypeIdentifier("type parameter expected");
      // Check for duplicate type parameters.
      for (intptr_t i = 0; i < index; i++) {
        existing_type_parameter ^= type_parameters_array.At(i)->raw();
        existing_type_parameter_name = existing_type_parameter.name();
        if (existing_type_parameter_name.Equals(type_parameter_name)) {
          ReportError(type_parameter_pos, "duplicate type parameter '%s'",
                      type_parameter_name.ToCString());
        }
      }
      if ((CurrentToken() == Token::kEXTENDS) ||
          (!parameterizing_class && (CurrentToken() == Token::kSUPER))) {
        const bool is_lower_bound = CurrentToken() == Token::kSUPER;
        ConsumeToken();
        // A bound may refer to the owner of the type parameter it applies to,
        // i.e. to the class or function currently being parsed.
        // Postpone resolution in order to avoid resolving the owner and its
        // type parameters, as they are not fully parsed yet.
        type_parameter_bound =
            ParseTypeOrFunctionType(false, ClassFinalizer::kDoNotResolve);
        if (is_lower_bound) {
          // TODO(regis): Handle 'super' differently than 'extends' if lower
          // bounds make it in the final specification and if run time support
          // for lower bounds is required.
          // For now, we parse but ignore lower bounds and only support upper
          // bounds.
          type_parameter_bound = I->object_store()->object_type();
        }
      } else {
        type_parameter_bound = I->object_store()->object_type();
      }
      // Note that we cannot yet calculate the final index of a function type
      // parameter, because we may not have parsed the parent function yet.
      type_parameter = TypeParameter::New(
          parameterizing_class ? current_class() : Class::Handle(Z),
          parameterizing_class ? Function::Handle(Z) : innermost_function(),
          index, type_parameter_name, type_parameter_bound, declaration_pos);
      type_parameters_array.Add(
          &AbstractType::ZoneHandle(Z, type_parameter.raw()));
      if (metadata_pos.IsReal()) {
        library_.AddTypeParameterMetadata(type_parameter, metadata_pos);
      }
      index++;
    } while (CurrentToken() == Token::kCOMMA);
    Token::Kind token = CurrentToken();
    if ((token == Token::kGT) || (token == Token::kSHR)) {
      ConsumeRightAngleBracket();
    } else {
      ReportError("right angle bracket expected");
    }
    const TypeArguments& type_parameters =
        TypeArguments::Handle(Z, NewTypeArguments(type_parameters_array));
    if (parameterizing_class) {
      current_class().set_type_parameters(type_parameters);
    } else {
      innermost_function().set_type_parameters(type_parameters);
    }
    // Resolve type parameters referenced by upper bounds.
    const intptr_t num_types = type_parameters.Length();
    for (intptr_t i = 0; i < num_types; i++) {
      type_parameter ^= type_parameters.TypeAt(i);
      type_parameter_bound = type_parameter.bound();
      ResolveTypeParameters(&type_parameter_bound);
      type_parameter.set_bound(type_parameter_bound);
    }
  }
}

RawTypeArguments* Parser::ParseTypeArguments(
    ClassFinalizer::FinalizationKind finalization) {
  TRACE_PARSER("ParseTypeArguments");
  if (CurrentToken() == Token::kLT) {
    GrowableArray<AbstractType*> types;
    AbstractType& type = AbstractType::Handle(Z);
    do {
      ConsumeToken();
      type = ParseTypeOrFunctionType(true, finalization);
      // Map a malformed type argument to dynamic.
      if (type.IsMalformed()) {
        type = Type::DynamicType();
      }
      types.Add(&AbstractType::ZoneHandle(Z, type.raw()));
    } while (CurrentToken() == Token::kCOMMA);
    Token::Kind token = CurrentToken();
    if ((token == Token::kGT) || (token == Token::kSHR)) {
      ConsumeRightAngleBracket();
    } else {
      ReportError("right angle bracket expected");
    }
    if (finalization != ClassFinalizer::kIgnore) {
      TypeArguments& type_args = TypeArguments::Handle(NewTypeArguments(types));
      if (finalization == ClassFinalizer::kCanonicalize) {
        type_args = type_args.Canonicalize();
      }
      return type_args.raw();
    }
  }
  return TypeArguments::null();
}

// Parse interface list and add to class cls.
void Parser::ParseInterfaceList(const Class& cls) {
  TRACE_PARSER("ParseInterfaceList");
  ASSERT(CurrentToken() == Token::kIMPLEMENTS);
  const GrowableObjectArray& all_interfaces =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New(Heap::kOld));
  AbstractType& interface = AbstractType::Handle(Z);
  // First get all the interfaces already implemented by class.
  Array& cls_interfaces = Array::Handle(Z, cls.interfaces());
  for (intptr_t i = 0; i < cls_interfaces.Length(); i++) {
    interface ^= cls_interfaces.At(i);
    all_interfaces.Add(interface, Heap::kOld);
  }
  // Now parse and add the new interfaces.
  do {
    ConsumeToken();
    TokenPosition interface_pos = TokenPos();
    interface = ParseType(ClassFinalizer::kResolveTypeParameters);
    if (interface.IsTypeParameter()) {
      ReportError(interface_pos,
                  "type parameter '%s' may not be used in interface list",
                  String::Handle(Z, interface.UserVisibleName()).ToCString());
    }
    all_interfaces.Add(interface, Heap::kOld);
  } while (CurrentToken() == Token::kCOMMA);
  cls_interfaces = Array::MakeFixedLength(all_interfaces);
  cls.set_interfaces(cls_interfaces);
}

RawAbstractType* Parser::ParseMixins(const AbstractType& super_type) {
  TRACE_PARSER("ParseMixins");
  ASSERT(CurrentToken() == Token::kWITH);
  const GrowableObjectArray& mixin_types =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New(Heap::kOld));
  AbstractType& mixin_type = AbstractType::Handle(Z);
  do {
    ConsumeToken();
    mixin_type = ParseType(ClassFinalizer::kResolveTypeParameters);
    if (mixin_type.IsDynamicType()) {
      // The string 'dynamic' is not resolved yet at this point, but a malformed
      // type mapped to dynamic can be encountered here.
      ReportError(mixin_type.token_pos(), "illegal mixin of a malformed type");
    }
    if (mixin_type.IsTypeParameter()) {
      ReportError(mixin_type.token_pos(),
                  "mixin type '%s' may not be a type parameter",
                  String::Handle(Z, mixin_type.UserVisibleName()).ToCString());
    }
    mixin_types.Add(mixin_type, Heap::kOld);
  } while (CurrentToken() == Token::kCOMMA);
  return MixinAppType::New(
      super_type, Array::Handle(Z, Array::MakeFixedLength(mixin_types)));
}

void Parser::ParseTopLevelVariable(TopLevel* top_level,
                                   const Object& owner,
                                   TokenPosition metadata_pos) {
  TRACE_PARSER("ParseTopLevelVariable");
  const bool is_const = (CurrentToken() == Token::kCONST);
  // Const fields are implicitly final.
  const bool is_final = is_const || (CurrentToken() == Token::kFINAL);
  const bool is_static = true;
  const AbstractType& type = AbstractType::ZoneHandle(
      Z, ParseConstFinalVarOrType(ClassFinalizer::kResolveTypeParameters));
  Field& field = Field::Handle(Z);
  Function& getter = Function::Handle(Z);
  while (true) {
    const TokenPosition name_pos = TokenPos();
    String& var_name = *ExpectIdentifier("variable name expected");

    if (library_.LookupLocalObject(var_name) != Object::null()) {
      ReportError(name_pos, "'%s' is already defined", var_name.ToCString());
    }

    // Check whether a getter or setter for this name exists. A const
    // or final field implies a setter which throws a NoSuchMethodError,
    // thus we need to check for conflicts with existing setters and
    // getters.
    String& accessor_name =
        String::Handle(Z, Field::LookupGetterSymbol(var_name));
    if (!accessor_name.IsNull() &&
        library_.LookupLocalObject(accessor_name) != Object::null()) {
      ReportError(name_pos, "getter for '%s' is already defined",
                  var_name.ToCString());
    }
    accessor_name = Field::LookupSetterSymbol(var_name);
    if (!accessor_name.IsNull() &&
        library_.LookupLocalObject(accessor_name) != Object::null()) {
      ReportError(name_pos, "setter for '%s' is already defined",
                  var_name.ToCString());
    }

    bool has_initializer = CurrentToken() == Token::kASSIGN;
    bool has_simple_literal = false;
    Instance& field_value = Instance::Handle(Z, Object::sentinel().raw());
    if (has_initializer) {
      ConsumeToken();
      if (LookaheadToken(1) == Token::kSEMICOLON) {
        has_simple_literal = IsSimpleLiteral(type, &field_value);
      }
      SkipExpr();
    } else if (is_final) {
      ReportError(name_pos, "missing initializer for final or const variable");
    }

    TokenPosition end_token_pos = TokenPos();

    // Create the field object.
    const bool is_reflectable =
        !(library_.is_dart_scheme() && library_.IsPrivate(var_name));
    field = Field::NewTopLevel(var_name, is_final, is_const, owner, name_pos,
                               end_token_pos);
    field.SetFieldType(type);
    field.set_has_initializer(has_initializer);
    field.set_is_reflectable(is_reflectable);
    top_level->AddField(field);
    library_.AddObject(field, var_name);
    if (metadata_pos.IsReal()) {
      library_.AddFieldMetadata(field, metadata_pos);
    }

    if (has_initializer) {
      field.SetStaticValue(field_value, true);
      if (!has_simple_literal) {
        // Create a static final getter.
        String& getter_name = String::Handle(Z, Field::GetterSymbol(var_name));
        getter =
            Function::New(getter_name, RawFunction::kImplicitStaticFinalGetter,
                          is_static, is_const,
                          /* is_abstract = */ false,
                          /* is_external = */ false,
                          /* is_native = */ false, owner, name_pos);
        getter.set_result_type(type);
        getter.set_is_debuggable(false);
        getter.set_is_reflectable(is_reflectable);
        top_level->AddFunction(getter);
      }
    }

    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
    } else if (CurrentToken() == Token::kSEMICOLON) {
      ConsumeToken();
      break;
    } else {
      ExpectSemicolon();  // Reports error.
    }
  }
}

RawFunction::AsyncModifier Parser::ParseFunctionModifier() {
  if (IsSymbol(Symbols::Async())) {
    ConsumeToken();
    if (CurrentToken() == Token::kMUL) {
      const bool enableAsyncStar = true;
      if (!enableAsyncStar) {
        ReportError("async* generator functions are not yet supported");
      }
      ConsumeToken();
      return RawFunction::kAsyncGen;
    } else {
      return RawFunction::kAsync;
    }
  } else if (IsSymbol(Symbols::Sync()) && (LookaheadToken(1) == Token::kMUL)) {
    const bool enableSyncStar = true;
    if (!enableSyncStar) {
      ReportError("sync* generator functions are not yet supported");
    }
    ConsumeToken();
    ConsumeToken();
    return RawFunction::kSyncGen;
  }
  return RawFunction::kNoModifier;
}

void Parser::ParseTopLevelFunction(TopLevel* top_level,
                                   const Object& owner,
                                   TokenPosition metadata_pos) {
  TRACE_PARSER("ParseTopLevelFunction");
  const TokenPosition decl_begin_pos = TokenPos();
  AbstractType& result_type = Type::Handle(Z, Type::DynamicType());
  bool is_external = false;
  bool is_patch = false;
  if (is_patch_source() && IsPatchAnnotation(metadata_pos)) {
    is_patch = true;
    metadata_pos = TokenPosition::kNoSource;
  } else if (CurrentToken() == Token::kEXTERNAL) {
    ConsumeToken();
    is_external = true;
  }
  // Parse optional result type.
  if (IsFunctionReturnType()) {
    // It is too early to resolve the type here, since it can be a result type
    // referring to a not yet declared function type parameter.
    result_type = ParseTypeOrFunctionType(true, ClassFinalizer::kDoNotResolve);
  }
  const TokenPosition name_pos = TokenPos();
  const String& func_name = *ExpectIdentifier("function name expected");

  bool found = library_.LookupLocalObject(func_name) != Object::null();
  if (found && !is_patch) {
    ReportError(name_pos, "'%s' is already defined", func_name.ToCString());
  } else if (!found && is_patch) {
    ReportError(name_pos, "missing '%s' cannot be patched",
                func_name.ToCString());
  }
  const String& accessor_name =
      String::Handle(Z, Field::LookupGetterSymbol(func_name));
  if (!accessor_name.IsNull() &&
      library_.LookupLocalObject(accessor_name) != Object::null()) {
    ReportError(name_pos, "'%s' is already defined as getter",
                func_name.ToCString());
  }
  // A setter named x= may co-exist with a function named x, thus we do
  // not need to check setters.

  Function& func = Function::Handle(
      Z, Function::New(func_name, RawFunction::kRegularFunction,
                       /* is_static = */ true,
                       /* is_const = */ false,
                       /* is_abstract = */ false, is_external,
                       /* is_native = */ false,  // May change.
                       owner, decl_begin_pos));

  ASSERT(innermost_function().IsNull());
  innermost_function_ = func.raw();

  if (CurrentToken() == Token::kLT) {
    if (!FLAG_generic_method_syntax) {
      ReportError("generic functions not supported");
    }
    ParseTypeParameters(false);  // Not parameterizing class, but function.
  }

  CheckToken(Token::kLPAREN);
  const TokenPosition function_pos = TokenPos();
  ParamList params;
  const bool use_function_type_syntax = false;
  const bool allow_explicit_default_values = true;
  const bool evaluate_metadata = false;
  ParseFormalParameterList(use_function_type_syntax,
                           allow_explicit_default_values, evaluate_metadata,
                           &params);

  const TokenPosition modifier_pos = TokenPos();
  RawFunction::AsyncModifier func_modifier = ParseFunctionModifier();

  TokenPosition function_end_pos = function_pos;
  bool is_native = false;
  String* native_name = NULL;
  if (is_external) {
    function_end_pos = TokenPos();
    ExpectSemicolon();
  } else if (CurrentToken() == Token::kLBRACE) {
    SkipBlock();
    function_end_pos = TokenPos();
    ExpectToken(Token::kRBRACE);
  } else if (CurrentToken() == Token::kARROW) {
    if ((func_modifier & RawFunction::kGeneratorBit) != 0) {
      ReportError(modifier_pos,
                  "=> style function may not be sync* or async* generator");
    }
    ConsumeToken();
    BoolScope allow_await(&this->await_is_keyword_,
                          func_modifier != RawFunction::kNoModifier);
    SkipExpr();
    function_end_pos = TokenPos();
    ExpectSemicolon();
  } else if (IsSymbol(Symbols::Native())) {
    native_name = &ParseNativeDeclaration();
    function_end_pos = TokenPos();
    ExpectSemicolon();
    is_native = true;
    func.set_is_native(true);
  } else {
    ReportError("function block expected");
  }
  func.set_result_type(result_type);
  // The result type may refer to func's type parameters,
  // but was not parsed in the scope of func. Adjust.
  result_type.SetScopeFunction(func);
  func.set_end_token_pos(function_end_pos);
  func.set_modifier(func_modifier);
  if (library_.is_dart_scheme() && library_.IsPrivate(func_name)) {
    func.set_is_reflectable(false);
  }
  if (is_native) {
    func.set_native_name(*native_name);
  }
  AddFormalParamsToFunction(&params, func);
  ASSERT(innermost_function().raw() == func.raw());
  innermost_function_ = Function::null();
  ResolveSignatureTypeParameters(func);
  top_level->AddFunction(func);
  if (!is_patch) {
    library_.AddObject(func, func_name);
  } else {
    // Need to remove the previously added function that is being patched.
    const Class& toplevel_cls = Class::Handle(Z, library_.toplevel_class());
    const Function& replaced_func =
        Function::Handle(Z, toplevel_cls.LookupStaticFunction(func_name));
    ASSERT(!replaced_func.IsNull());
    toplevel_cls.RemoveFunction(replaced_func);
    library_.ReplaceObject(func, func_name);
  }
  if (metadata_pos.IsReal()) {
    library_.AddFunctionMetadata(func, metadata_pos);
  }
}

void Parser::ParseTopLevelAccessor(TopLevel* top_level,
                                   const Object& owner,
                                   TokenPosition metadata_pos) {
  TRACE_PARSER("ParseTopLevelAccessor");
  const TokenPosition decl_begin_pos = TokenPos();
  const bool is_static = true;
  bool is_external = false;
  bool is_patch = false;
  AbstractType& result_type = AbstractType::Handle(Z);
  if (is_patch_source() && IsPatchAnnotation(metadata_pos)) {
    is_patch = true;
    metadata_pos = TokenPosition::kNoSource;
  } else if (CurrentToken() == Token::kEXTERNAL) {
    ConsumeToken();
    is_external = true;
  }
  bool is_getter = (CurrentToken() == Token::kGET);
  if (CurrentToken() == Token::kGET || CurrentToken() == Token::kSET) {
    ConsumeToken();
    result_type = Type::DynamicType();
  } else {
    result_type =
        ParseTypeOrFunctionType(true, ClassFinalizer::kResolveTypeParameters);
    is_getter = (CurrentToken() == Token::kGET);
    if (CurrentToken() == Token::kGET || CurrentToken() == Token::kSET) {
      ConsumeToken();
    } else {
      UnexpectedToken();
    }
  }
  const TokenPosition name_pos = TokenPos();
  const String* field_name = ExpectIdentifier("accessor name expected");

  const TokenPosition accessor_pos = TokenPos();
  ParamList params;

  if (!is_getter) {
    const bool use_function_type_syntax = false;
    const bool allow_explicit_default_values = true;
    const bool evaluate_metadata = false;
    ParseFormalParameterList(use_function_type_syntax,
                             allow_explicit_default_values, evaluate_metadata,
                             &params);
  }
  String& accessor_name = String::ZoneHandle(Z);
  int expected_num_parameters = -1;
  if (is_getter) {
    expected_num_parameters = 0;
    accessor_name = Field::GetterSymbol(*field_name);
  } else {
    expected_num_parameters = 1;
    accessor_name = Field::SetterSymbol(*field_name);
  }
  if ((params.num_fixed_parameters != expected_num_parameters) ||
      (params.num_optional_parameters != 0)) {
    ReportError(name_pos, "illegal %s parameters",
                is_getter ? "getter" : "setter");
  }

  // Check whether this getter conflicts with a function or top-level variable
  // with the same name.
  if (is_getter &&
      (library_.LookupLocalObject(*field_name) != Object::null())) {
    ReportError(name_pos, "'%s' is already defined in this library",
                field_name->ToCString());
  }
  // Check whether this setter conflicts with the implicit setter
  // of a top-level variable with the same name.
  if (!is_getter &&
      (library_.LookupLocalField(*field_name) != Object::null())) {
    ReportError(name_pos, "Variable '%s' is already defined in this library",
                field_name->ToCString());
  }
  bool found = library_.LookupLocalObject(accessor_name) != Object::null();
  if (found && !is_patch) {
    ReportError(name_pos, "%s for '%s' is already defined",
                is_getter ? "getter" : "setter", field_name->ToCString());
  } else if (!found && is_patch) {
    ReportError(name_pos, "missing %s for '%s' cannot be patched",
                is_getter ? "getter" : "setter", field_name->ToCString());
  }

  const TokenPosition modifier_pos = TokenPos();
  RawFunction::AsyncModifier func_modifier = ParseFunctionModifier();
  if (!is_getter && (func_modifier != RawFunction::kNoModifier)) {
    ReportError(modifier_pos,
                "setter function cannot be async, async* or sync*");
  }

  TokenPosition accessor_end_pos = accessor_pos;
  bool is_native = false;
  String* native_name = NULL;
  if (is_external) {
    accessor_end_pos = TokenPos();
    ExpectSemicolon();
  } else if (CurrentToken() == Token::kLBRACE) {
    SkipBlock();
    accessor_end_pos = TokenPos();
    ExpectToken(Token::kRBRACE);
  } else if (CurrentToken() == Token::kARROW) {
    if (is_getter && ((func_modifier & RawFunction::kGeneratorBit) != 0)) {
      ReportError(modifier_pos,
                  "=> style getter may not be sync* or async* generator");
    }
    ConsumeToken();
    BoolScope allow_await(&this->await_is_keyword_,
                          func_modifier != RawFunction::kNoModifier);
    SkipExpr();
    accessor_end_pos = TokenPos();
    ExpectSemicolon();
  } else if (IsSymbol(Symbols::Native())) {
    native_name = &ParseNativeDeclaration();
    accessor_end_pos = TokenPos();
    ExpectSemicolon();
    is_native = true;
  } else {
    ReportError("function block expected");
  }
  Function& func = Function::Handle(
      Z, Function::New(accessor_name,
                       is_getter ? RawFunction::kGetterFunction
                                 : RawFunction::kSetterFunction,
                       is_static,
                       /* is_const = */ false,
                       /* is_abstract = */ false, is_external, is_native, owner,
                       decl_begin_pos));
  func.set_result_type(result_type);
  // The result type may refer to func's type parameters,
  // but was not parsed in the scope of func. Adjust.
  result_type.SetScopeFunction(func);
  func.set_end_token_pos(accessor_end_pos);
  func.set_modifier(func_modifier);
  if (is_native) {
    func.set_is_debuggable(false);
    func.set_native_name(*native_name);
  }
  if (library_.is_dart_scheme() && library_.IsPrivate(accessor_name)) {
    func.set_is_reflectable(false);
  }
  AddFormalParamsToFunction(&params, func);
  ResolveSignatureTypeParameters(func);
  top_level->AddFunction(func);
  if (!is_patch) {
    library_.AddObject(func, accessor_name);
  } else {
    // Need to remove the previously added accessor that is being patched.
    const Class& toplevel_cls = Class::Handle(
        Z, owner.IsClass() ? Class::Cast(owner).raw()
                           : PatchClass::Cast(owner).patched_class());
    const Function& replaced_func =
        Function::Handle(Z, toplevel_cls.LookupFunction(accessor_name));
    ASSERT(!replaced_func.IsNull());
    toplevel_cls.RemoveFunction(replaced_func);
    library_.ReplaceObject(func, accessor_name);
  }
  if (metadata_pos.IsReal()) {
    library_.AddFunctionMetadata(func, metadata_pos);
  }
}

RawObject* Parser::CallLibraryTagHandler(Dart_LibraryTag tag,
                                         TokenPosition token_pos,
                                         const String& url) {
  Dart_LibraryTagHandler handler = I->library_tag_handler();
  if (handler == NULL) {
    if (url.StartsWith(Symbols::DartScheme())) {
      if (tag == Dart_kCanonicalizeUrl) {
        return url.raw();
      }
      return Object::null();
    }
    ReportError(token_pos, "no library handler registered");
  }
  // Block class finalization attempts when calling into the library
  // tag handler.
  I->BlockClassFinalization();
  Object& result = Object::Handle(Z);
  {
    TransitionVMToNative transition(T);
    Api::Scope api_scope(T);
    Dart_Handle retval = handler(tag, Api::NewHandle(T, library_.raw()),
                                 Api::NewHandle(T, url.raw()));
    result = Api::UnwrapHandle(retval);
  }
  I->UnblockClassFinalization();
  if (result.IsError()) {
    // In case of an error we append an explanatory error message to the
    // error obtained from the library tag handler.
    const Error& prev_error = Error::Cast(result);
    Report::LongJumpF(prev_error, script_, token_pos, "library handler failed");
  }
  if (tag == Dart_kCanonicalizeUrl) {
    if (!result.IsString()) {
      ReportError(token_pos, "library handler failed URI canonicalization");
    }
  }
  return result.raw();
}

void Parser::ParseLibraryName() {
  ASSERT(CurrentToken() == Token::kLIBRARY);
  ConsumeToken();
  String& lib_name = *ExpectIdentifier("library name expected");
  if (CurrentToken() == Token::kPERIOD) {
    GrowableHandlePtrArray<const String> pieces(Z, 3);
    pieces.Add(lib_name);
    while (CurrentToken() == Token::kPERIOD) {
      ConsumeToken();
      pieces.Add(Symbols::Dot());
      pieces.Add(*ExpectIdentifier("malformed library name"));
    }
    lib_name = Symbols::FromConcatAll(T, pieces);
  }
  library_.SetName(lib_name);
  ExpectSemicolon();
}

void Parser::ParseIdentList(GrowableObjectArray* names) {
  if (!IsIdentifier()) {
    ReportError("identifier expected");
  }
  while (IsIdentifier()) {
    names->Add(*CurrentLiteral(), allocation_space_);
    ConsumeToken();  // Identifier.
    if (CurrentToken() != Token::kCOMMA) {
      return;
    }
    ConsumeToken();  // Comma.
  }
}

void Parser::ParseLibraryImportExport(const Object& tl_owner,
                                      TokenPosition metadata_pos) {
  ASSERT(Thread::Current()->IsMutatorThread());
  bool is_import = (CurrentToken() == Token::kIMPORT);
  bool is_export = (CurrentToken() == Token::kEXPORT);
  ASSERT(is_import || is_export);
  const TokenPosition import_pos = TokenPos();
  ConsumeToken();
  CheckToken(Token::kSTRING, "library url expected");
  AstNode* url_literal = ParseStringLiteral(false);
  if (FLAG_conditional_directives) {
    bool condition_triggered = false;
    while (CurrentToken() == Token::kIF) {
      // Conditional import: if (env == val) uri.
      ConsumeToken();
      ExpectToken(Token::kLPAREN);
      // Parse dotted name.
      const GrowableObjectArray& pieces = GrowableObjectArray::Handle(
          Z, GrowableObjectArray::New(allocation_space_));
      pieces.Add(*ExpectIdentifier("identifier expected"), allocation_space_);
      while (CurrentToken() == Token::kPERIOD) {
        pieces.Add(Symbols::Dot(), allocation_space_);
        ConsumeToken();
        pieces.Add(*ExpectIdentifier("identifier expected"), allocation_space_);
      }
      if (I->obfuscate()) {
        // If we are obfuscating then we need to deobfuscate environment name.
        Obfuscator::Deobfuscate(T, pieces);
      }
      AstNode* valueNode = NULL;
      if (CurrentToken() == Token::kEQ) {
        ConsumeToken();
        CheckToken(Token::kSTRING, "string literal expected");
        valueNode = ParseStringLiteral(false);
        ASSERT(valueNode->IsLiteralNode());
        ASSERT(valueNode->AsLiteralNode()->literal().IsString());
      }
      ExpectToken(Token::kRPAREN);
      CheckToken(Token::kSTRING, "library url expected");
      AstNode* conditional_url_literal = ParseStringLiteral(false);

      // If there was already a condition that triggered, don't try to match
      // again.
      if (condition_triggered) {
        continue;
      }
      // Check if this conditional line overrides the default import.
      const String& key = String::Handle(String::ConcatAll(
          Array::Handle(Array::MakeFixedLength(pieces)), allocation_space_));
      const String& value =
          (valueNode == NULL)
              ? Symbols::True()
              : String::Cast(valueNode->AsLiteralNode()->literal());
      // Call the embedder to supply us with the environment.
      const String& env_value =
          String::Handle(Api::GetEnvironmentValue(T, key));
      if (!env_value.IsNull() && env_value.Equals(value)) {
        condition_triggered = true;
        url_literal = conditional_url_literal;
      }
    }
  }
  ASSERT(url_literal->IsLiteralNode());
  ASSERT(url_literal->AsLiteralNode()->literal().IsString());
  const String& url = String::Cast(url_literal->AsLiteralNode()->literal());
  if (url.Length() == 0) {
    ReportError("library url expected");
  }
  bool is_deferred_import = false;
  if (is_import && (IsSymbol(Symbols::Deferred()))) {
    is_deferred_import = true;
    ConsumeToken();
    CheckToken(Token::kAS, "'as' expected");
  }
  String& prefix = String::Handle(Z);
  TokenPosition prefix_pos = TokenPosition::kNoSource;
  if (is_import && (CurrentToken() == Token::kAS)) {
    ConsumeToken();
    prefix_pos = TokenPos();
    prefix = ExpectIdentifier("prefix identifier expected")->raw();
  }

  Array& show_names = Array::Handle(Z);
  Array& hide_names = Array::Handle(Z);
  if (is_deferred_import || IsSymbol(Symbols::Show()) ||
      IsSymbol(Symbols::Hide())) {
    GrowableObjectArray& show_list = GrowableObjectArray::Handle(
        Z, GrowableObjectArray::New(allocation_space_));
    GrowableObjectArray& hide_list = GrowableObjectArray::Handle(
        Z, GrowableObjectArray::New(allocation_space_));
    // Libraries imported through deferred import automatically hide
    // the name 'loadLibrary'.
    if (is_deferred_import) {
      hide_list.Add(Symbols::LoadLibrary());
    }
    for (;;) {
      if (IsSymbol(Symbols::Show())) {
        ConsumeToken();
        ParseIdentList(&show_list);
      } else if (IsSymbol(Symbols::Hide())) {
        ConsumeToken();
        ParseIdentList(&hide_list);
      } else {
        break;
      }
    }
    if (show_list.Length() > 0) {
      show_names = Array::MakeFixedLength(show_list);
    }
    if (hide_list.Length() > 0) {
      hide_names = Array::MakeFixedLength(hide_list);
    }
  }
  ExpectSemicolon();

  // Canonicalize library URL.
  const String& canon_url = String::CheckedHandle(
      CallLibraryTagHandler(Dart_kCanonicalizeUrl, import_pos, url));

  // Create a new library if it does not exist yet.
  Library& library = Library::Handle(Z, Library::LookupLibrary(T, canon_url));
  if (library.IsNull()) {
    library = Library::New(canon_url);
    library.Register(T);
  }

  // If loading hasn't been requested yet, and if this is not a deferred
  // library import, call the library tag handler to request loading
  // the library.
  if (library.LoadNotStarted() &&
      (!is_deferred_import || FLAG_load_deferred_eagerly)) {
    library.SetLoadRequested();
    CallLibraryTagHandler(Dart_kImportTag, import_pos, canon_url);
  }

  Namespace& ns =
      Namespace::Handle(Z, Namespace::New(library, show_names, hide_names));
  if (metadata_pos.IsReal()) {
    ns.AddMetadata(tl_owner, metadata_pos);
  }

  // Ensure that private dart:_ libraries are only imported into dart:
  // libraries, including indirectly through exports.
  const String& lib_url = String::Handle(Z, library_.url());
  if (canon_url.StartsWith(Symbols::DartSchemePrivate()) &&
      !lib_url.StartsWith(Symbols::DartScheme())) {
    ReportError(import_pos, "private library is not accessible");
  }

  if (!FLAG_enable_mirrors && Symbols::DartMirrors().Equals(canon_url)) {
    ReportError(import_pos,
                "import of dart:mirrors with --enable-mirrors=false");
  }

  if (is_import) {
    if (prefix.IsNull() || (prefix.Length() == 0)) {
      ASSERT(!is_deferred_import);
      library_.AddImport(ns);
    } else {
      LibraryPrefix& library_prefix = LibraryPrefix::Handle(Z);
      library_prefix = library_.LookupLocalLibraryPrefix(prefix);
      if (!library_prefix.IsNull()) {
        // Check that prefix names of deferred import clauses are
        // unique.
        if (!is_deferred_import && library_prefix.is_deferred_load()) {
          ReportError(prefix_pos,
                      "prefix '%s' already used in a deferred import clause",
                      prefix.ToCString());
        }
        if (is_deferred_import) {
          ReportError(prefix_pos, "prefix of deferred import must be unique");
        }
        library_prefix.AddImport(ns);
      } else {
        library_prefix =
            LibraryPrefix::New(prefix, ns, is_deferred_import, library_);
        library_.AddObject(library_prefix, prefix);
      }
    }
  } else {
    ASSERT(is_export);
    library_.AddExport(ns);
  }
}

void Parser::ParseLibraryPart() {
  const TokenPosition source_pos = TokenPos();
  ConsumeToken();  // Consume "part".
  if (IsSymbol(Symbols::Of())) {
    ReportError("part of declarations are not allowed in script files");
  }
  CheckToken(Token::kSTRING, "url expected");
  AstNode* url_literal = ParseStringLiteral(false);
  ASSERT(url_literal->IsLiteralNode());
  ASSERT(url_literal->AsLiteralNode()->literal().IsString());
  const String& url = String::Cast(url_literal->AsLiteralNode()->literal());
  ExpectSemicolon();
  const String& canon_url = String::CheckedHandle(
      CallLibraryTagHandler(Dart_kCanonicalizeUrl, source_pos, url));
  CallLibraryTagHandler(Dart_kSourceTag, source_pos, canon_url);
}

void Parser::ParseLibraryDefinition(const Object& tl_owner) {
  TRACE_PARSER("ParseLibraryDefinition");

  // Handle the script tag.
  if (CurrentToken() == Token::kSCRIPTTAG) {
    // Nothing to do for script tags except to skip them.
    ConsumeToken();
  }

  ASSERT(script_.kind() != RawScript::kSourceTag);

  // We may read metadata tokens that are part of the toplevel
  // declaration that follows the library definitions. Therefore, we
  // need to remember the position of the last token that was
  // successfully consumed.
  TokenPosition rewind_pos = TokenPos();
  TokenPosition metadata_pos = SkipMetadata();
  if (CurrentToken() == Token::kLIBRARY) {
    if (is_patch_source()) {
      ReportError("patch cannot override library name");
    }
    ParseLibraryName();
    if (metadata_pos.IsReal()) {
      library_.AddLibraryMetadata(tl_owner, metadata_pos);
    }
    rewind_pos = TokenPos();
    metadata_pos = SkipMetadata();
  }
  while ((CurrentToken() == Token::kIMPORT) ||
         (CurrentToken() == Token::kEXPORT)) {
    ParseLibraryImportExport(tl_owner, metadata_pos);
    rewind_pos = TokenPos();
    metadata_pos = SkipMetadata();
  }
  // Core lib has not been explicitly imported, so we implicitly
  // import it here.
  if (!library_.ImportsCorelib()) {
    Library& core_lib = Library::Handle(Z, Library::CoreLibrary());
    ASSERT(!core_lib.IsNull());
    const Namespace& core_ns = Namespace::Handle(
        Z,
        Namespace::New(core_lib, Object::null_array(), Object::null_array()));
    library_.AddImport(core_ns);
  }
  while (CurrentToken() == Token::kPART) {
    ParseLibraryPart();
    rewind_pos = TokenPos();
    metadata_pos = SkipMetadata();
  }
  SetPosition(rewind_pos);
}

void Parser::ParsePartHeader() {
  SkipMetadata();
  CheckToken(Token::kPART, "'part of' expected");
  ConsumeToken();
  if (!IsSymbol(Symbols::Of())) {
    ReportError("'part of' expected");
  }
  ConsumeToken();
  // The VM is not required to check that the library name or URI matches the
  // name or URI of the current library, so we ignore them.
  if (CurrentToken() == Token::kSTRING) {
    ParseStringLiteral(false);
  } else {
    ExpectIdentifier("library name expected");
    while (CurrentToken() == Token::kPERIOD) {
      ConsumeToken();
      ExpectIdentifier("malformed library name");
    }
  }
  ExpectSemicolon();
}

void Parser::ParseTopLevel() {
  TRACE_PARSER("ParseTopLevel");
  // Collect the classes found at the top level in this growable array.
  // They need to be registered with class finalization after parsing
  // has been completed.
  ObjectStore* object_store = I->object_store();
  const GrowableObjectArray& pending_classes =
      GrowableObjectArray::Handle(Z, object_store->pending_classes());
  SetPosition(TokenPosition::kMinSource);
  is_top_level_ = true;
  TopLevel top_level(Z);

  Object& tl_owner = Object::Handle(Z);
  Class& toplevel_class = Class::Handle(Z, library_.toplevel_class());
  if (toplevel_class.IsNull()) {
    toplevel_class =
        Class::New(library_, Symbols::TopLevel(), script_, TokenPos());
    toplevel_class.set_library(library_);
    library_.set_toplevel_class(toplevel_class);
    tl_owner = toplevel_class.raw();
  } else {
    tl_owner = PatchClass::New(toplevel_class, script_);
  }

  if (is_library_source() || is_patch_source()) {
    set_current_class(toplevel_class);
    ParseLibraryDefinition(tl_owner);
  } else if (is_part_source()) {
    ParsePartHeader();
  }

  const Class& cls = Class::Handle(Z);
  while (true) {
    set_current_class(cls);  // No current class.
    TokenPosition metadata_pos = SkipMetadata();
    if (CurrentToken() == Token::kCLASS) {
      ParseClassDeclaration(pending_classes, tl_owner, metadata_pos);
    } else if (CurrentToken() == Token::kENUM) {
      ParseEnumDeclaration(pending_classes, tl_owner, metadata_pos);
    } else if ((CurrentToken() == Token::kTYPEDEF) &&
               (LookaheadToken(1) != Token::kLPAREN)) {
      set_current_class(toplevel_class);
      ParseTypedef(pending_classes, tl_owner, metadata_pos);
    } else if ((CurrentToken() == Token::kABSTRACT) &&
               (LookaheadToken(1) == Token::kCLASS)) {
      ParseClassDeclaration(pending_classes, tl_owner, metadata_pos);
    } else {
      set_current_class(toplevel_class);
      if (IsVariableDeclaration()) {
        ParseTopLevelVariable(&top_level, tl_owner, metadata_pos);
      } else if (IsFunctionDeclaration()) {
        ParseTopLevelFunction(&top_level, tl_owner, metadata_pos);
      } else if (IsTopLevelAccessor()) {
        ParseTopLevelAccessor(&top_level, tl_owner, metadata_pos);
      } else if (CurrentToken() == Token::kEOS) {
        break;
      } else {
        UnexpectedToken();
      }
    }
  }

  if (top_level.fields().length() > 0) {
    toplevel_class.AddFields(top_level.fields());
  }
  for (intptr_t i = 0; i < top_level.functions().length(); i++) {
    toplevel_class.AddFunction(*top_level.functions()[i]);
  }
  if (toplevel_class.is_finalized()) {
    toplevel_class.ResetFinalization();
  }
  pending_classes.Add(toplevel_class, Heap::kOld);
}

void Parser::CheckStack() {
  volatile uword c_stack_pos = Thread::GetCurrentStackPointer();
  volatile uword c_stack_base = OSThread::Current()->stack_base();
  volatile uword c_stack_limit =
      c_stack_base - OSThread::GetSpecifiedStackSize();
  // Note: during early initialization the stack_base() can return 0.
  if ((c_stack_base > 0) && (c_stack_pos < c_stack_limit)) {
    ReportError("stack overflow while parsing");
  }
}

void Parser::ChainNewBlock(LocalScope* outer_scope) {
  Block* block = new (Z) Block(current_block_, outer_scope,
                               new (Z) SequenceNode(TokenPos(), outer_scope));
  current_block_ = block;
}

void Parser::OpenBlock() {
  ASSERT(current_block_ != NULL);
  LocalScope* outer_scope = current_block_->scope;
  ChainNewBlock(new (Z) LocalScope(outer_scope, outer_scope->function_level(),
                                   outer_scope->loop_level()));
}

void Parser::OpenLoopBlock() {
  ASSERT(current_block_ != NULL);
  LocalScope* outer_scope = current_block_->scope;
  ChainNewBlock(new (Z) LocalScope(outer_scope, outer_scope->function_level(),
                                   outer_scope->loop_level() + 1));
}

void Parser::OpenFunctionBlock(const Function& func) {
  LocalScope* outer_scope;
  if (current_block_ == NULL) {
    if (!func.IsLocalFunction()) {
      // We are compiling a non-nested function.
      outer_scope = new (Z) LocalScope(NULL, 0, 0);
    } else {
      // We are compiling the function of an invoked closure.
      // Restore the outer scope containing all captured variables.
      const ContextScope& context_scope =
          ContextScope::Handle(Z, func.context_scope());
      ASSERT(!context_scope.IsNull());
      outer_scope = new (Z)
          LocalScope(LocalScope::RestoreOuterScope(context_scope), 0, 0);
    }
  } else {
    // We are parsing a nested function while compiling the enclosing function.
    outer_scope = new (Z) LocalScope(
        current_block_->scope, current_block_->scope->function_level() + 1, 0);
  }
  ChainNewBlock(outer_scope);
}

void Parser::OpenAsyncClosure() {
  TRACE_PARSER("OpenAsyncClosure");
  async_temp_scope_ = current_block_->scope;
  OpenAsyncTryBlock();
}

SequenceNode* Parser::CloseAsyncGeneratorTryBlock(SequenceNode* body) {
  TRACE_PARSER("CloseAsyncGeneratorTryBlock");
  // The generated try-catch-finally that wraps the async generator function
  // body is the outermost try statement.
  ASSERT(try_stack_ != NULL);
  ASSERT(try_stack_->outer_try() == NULL);
  // We only get here when parsing an async generator body.
  ASSERT(innermost_function().IsAsyncGenClosure());

  const TokenPosition try_end_pos = innermost_function().end_token_pos();

  // The try-block (closure body code) has been parsed. We are now
  // generating the code for the catch block.
  LocalScope* try_scope = current_block_->scope;
  try_stack_->enter_catch();
  OpenBlock();  // Catch handler list.
  OpenBlock();  // Catch block.

  // Add the exception and stack trace parameters to the scope.
  CatchParamDesc exception_param;
  CatchParamDesc stack_trace_param;
  exception_param.token_pos = TokenPosition::kNoSource;
  exception_param.type = &Object::dynamic_type();
  exception_param.name = &Symbols::ExceptionParameter();
  stack_trace_param.token_pos = TokenPosition::kNoSource;
  stack_trace_param.type = &Object::dynamic_type();
  stack_trace_param.name = &Symbols::StackTraceParameter();

  AddCatchParamsToScope(&exception_param, &stack_trace_param,
                        current_block_->scope);

  // Generate code to save the exception object and stack trace
  // in local variables.
  LocalVariable* context_var =
      try_scope->LocalLookupVariable(Symbols::SavedTryContextVar());
  ASSERT(context_var != NULL);

  LocalVariable* exception_var =
      try_scope->LocalLookupVariable(Symbols::ExceptionVar());
  ASSERT(exception_var != NULL);
  if (exception_param.var != NULL) {
    // Generate code to load the exception object (:exception_var) into
    // the exception variable specified in this block.
    current_block_->statements->Add(new (Z) StoreLocalNode(
        TokenPosition::kNoSource, exception_param.var,
        new (Z) LoadLocalNode(TokenPosition::kNoSource, exception_var)));
  }

  LocalVariable* stack_trace_var =
      try_scope->LocalLookupVariable(Symbols::StackTraceVar());
  ASSERT(stack_trace_var != NULL);
  if (stack_trace_param.var != NULL) {
    // A stack trace variable is specified in this block, so generate code
    // to load the stack trace object (:stack_trace_var) into the stack
    // trace variable specified in this block.
    current_block_->statements->Add(new (Z) StoreLocalNode(
        TokenPosition::kNoSource, stack_trace_param.var,
        new (Z) LoadLocalNode(TokenPosition::kNoSource, stack_trace_var)));
  }
  LocalVariable* saved_exception_var =
      try_scope->LocalLookupVariable(Symbols::SavedExceptionVar());
  LocalVariable* saved_stack_trace_var =
      try_scope->LocalLookupVariable(Symbols::SavedStackTraceVar());
  SaveExceptionAndStackTrace(current_block_->statements, exception_var,
                             stack_trace_var, saved_exception_var,
                             saved_stack_trace_var);

  // Catch block: add the error to the stream.
  // :controller.AddError(:exception, :stack_trace);
  // return;  // The finally block will close the stream.
  LocalVariable* controller =
      current_block_->scope->LookupVariable(Symbols::ColonController(), false);
  ASSERT(controller != NULL);
  ArgumentListNode* args = new (Z) ArgumentListNode(TokenPosition::kNoSource);
  args->Add(new (Z)
                LoadLocalNode(TokenPosition::kNoSource, exception_param.var));
  args->Add(new (Z)
                LoadLocalNode(TokenPosition::kNoSource, stack_trace_param.var));
  current_block_->statements->Add(new (Z) InstanceCallNode(
      try_end_pos, new (Z) LoadLocalNode(TokenPosition::kNoSource, controller),
      Symbols::AddError(), args));
  ReturnNode* return_node = new (Z) ReturnNode(try_end_pos);
  AddNodeForFinallyInlining(return_node);
  current_block_->statements->Add(return_node);
  AstNode* catch_block = CloseBlock();
  current_block_->statements->Add(catch_block);
  SequenceNode* catch_handler_list = CloseBlock();

  TryStack* try_statement = PopTry();
  ASSERT(try_stack_ == NULL);  // We popped the outermost try block.

  // Finally block: closing the stream and returning. Instead of simply
  // returning, create an await state and suspend. There may be outstanding
  // calls to schedule the generator body. This suspension ensures that we
  // do not repeat any code of the generator body.
  // :controller.close();
  // suspend;
  // We need to inline this code in all recorded exit points.
  intptr_t node_index = 0;
  SequenceNode* finally_clause = NULL;
  if (try_stack_ != NULL) {
    try_stack_->enter_finally();
  }
  do {
    OpenBlock();
    ArgumentListNode* no_args =
        new (Z) ArgumentListNode(TokenPosition::kNoSource);
    current_block_->statements->Add(new (Z) InstanceCallNode(
        try_end_pos,
        new (Z) LoadLocalNode(TokenPosition::kNoSource, controller),
        Symbols::Close(), no_args));

    // Suspend after the close.
    AwaitMarkerNode* await_marker = new (Z) AwaitMarkerNode(
        async_temp_scope_, current_block_->scope, TokenPosition::kNoSource);
    current_block_->statements->Add(await_marker);
    ReturnNode* continuation_ret = new (Z) ReturnNode(try_end_pos);
    continuation_ret->set_return_type(ReturnNode::kContinuationTarget);
    current_block_->statements->Add(continuation_ret);

    finally_clause = CloseBlock();
    AstNode* node_to_inline = try_statement->GetNodeToInlineFinally(node_index);
    if (node_to_inline != NULL) {
      InlinedFinallyNode* node =
          new (Z) InlinedFinallyNode(try_end_pos, finally_clause, context_var,
                                     // No outer try statement
                                     CatchClauseNode::kInvalidTryIndex);
      finally_clause = NULL;
      AddFinallyClauseToNode(true, node_to_inline, node);
      node_index++;
    }
  } while (finally_clause == NULL);

  if (try_stack_ != NULL) {
    try_stack_->exit_finally();
  }

  // Catch block handles all exceptions.
  const Array& handler_types = Array::ZoneHandle(Z, Array::New(1, Heap::kOld));
  handler_types.SetAt(0, Object::dynamic_type());

  CatchClauseNode* catch_clause = new (Z) CatchClauseNode(
      TokenPosition::kNoSource, catch_handler_list, handler_types, context_var,
      exception_var, stack_trace_var, saved_exception_var,
      saved_stack_trace_var, AllocateTryIndex(), true);

  const intptr_t try_index = try_statement->try_index();

  AstNode* try_catch_node = new (Z)
      TryCatchNode(TokenPosition::kNoSource, body, context_var, catch_clause,
                   finally_clause, try_index, finally_clause);
  current_block_->statements->Add(try_catch_node);
  return CloseBlock();
}

SequenceNode* Parser::CloseAsyncTryBlock(SequenceNode* try_block,
                                         TokenPosition func_end_pos) {
  // This is the outermost try-catch of the function.
  ASSERT(try_stack_ != NULL);
  ASSERT(try_stack_->outer_try() == NULL);
  ASSERT(innermost_function().IsAsyncClosure());
  LocalScope* try_scope = current_block_->scope;

  try_stack_->enter_catch();

  OpenBlock();  // Catch handler list.
  OpenBlock();  // Catch block.
  CatchParamDesc exception_param;
  CatchParamDesc stack_trace_param;
  exception_param.token_pos = TokenPosition::kNoSource;
  exception_param.type = &Object::dynamic_type();
  exception_param.name = &Symbols::ExceptionParameter();
  stack_trace_param.token_pos = TokenPosition::kNoSource;
  stack_trace_param.type = &Object::dynamic_type();
  stack_trace_param.name = &Symbols::StackTraceParameter();

  AddCatchParamsToScope(&exception_param, &stack_trace_param,
                        current_block_->scope);

  LocalVariable* context_var =
      try_scope->LocalLookupVariable(Symbols::SavedTryContextVar());
  ASSERT(context_var != NULL);

  LocalVariable* exception_var =
      try_scope->LocalLookupVariable(Symbols::ExceptionVar());
  if (exception_param.var != NULL) {
    // Generate code to load the exception object (:exception_var) into
    // the exception variable specified in this block.
    ASSERT(exception_var != NULL);
    current_block_->statements->Add(new (Z) StoreLocalNode(
        TokenPosition::kNoSource, exception_param.var,
        new (Z) LoadLocalNode(TokenPosition::kNoSource, exception_var)));
  }

  LocalVariable* stack_trace_var =
      try_scope->LocalLookupVariable(Symbols::StackTraceVar());
  if (stack_trace_param.var != NULL) {
    // A stack trace variable is specified in this block, so generate code
    // to load the stack trace object (:stack_trace_var) into the stack
    // trace variable specified in this block.
    ASSERT(stack_trace_var != NULL);
    current_block_->statements->Add(new (Z) StoreLocalNode(
        TokenPosition::kNoSource, stack_trace_param.var,
        new (Z) LoadLocalNode(TokenPosition::kNoSource, stack_trace_var)));
  }
  LocalVariable* saved_exception_var =
      try_scope->LocalLookupVariable(Symbols::SavedExceptionVar());
  LocalVariable* saved_stack_trace_var =
      try_scope->LocalLookupVariable(Symbols::SavedStackTraceVar());
  SaveExceptionAndStackTrace(current_block_->statements, exception_var,
                             stack_trace_var, saved_exception_var,
                             saved_stack_trace_var);

  // Complete the async future with an error. This catch block executes
  // unconditionally, there is no need to generate a type check for.
  LocalVariable* async_completer =
      current_block_->scope->LookupVariable(Symbols::AsyncCompleter(), false);
  ASSERT(async_completer != NULL);
  ArgumentListNode* completer_args =
      new (Z) ArgumentListNode(TokenPosition::kNoSource);
  completer_args->Add(
      new (Z) LoadLocalNode(TokenPosition::kNoSource, exception_param.var));
  completer_args->Add(
      new (Z) LoadLocalNode(TokenPosition::kNoSource, stack_trace_param.var));
  current_block_->statements->Add(new (Z) InstanceCallNode(
      func_end_pos,
      new (Z) LoadLocalNode(TokenPosition::kNoSource, async_completer),
      Symbols::CompleterCompleteError(), completer_args));
  ReturnNode* return_node = new (Z) ReturnNode(func_end_pos);
  // Behavior like a continuation return, i.e,. don't call a completer.
  return_node->set_return_type(ReturnNode::kContinuation);
  current_block_->statements->Add(return_node);
  AstNode* catch_block = CloseBlock();
  current_block_->statements->Add(catch_block);
  SequenceNode* catch_handler_list = CloseBlock();

  const Array& handler_types = Array::ZoneHandle(Z, Array::New(1, Heap::kOld));
  handler_types.SetAt(0, *exception_param.type);

  TryStack* try_statement = PopTry();
  const intptr_t try_index = try_statement->try_index();

  CatchClauseNode* catch_clause = new (Z) CatchClauseNode(
      TokenPosition::kNoSource, catch_handler_list, handler_types, context_var,
      exception_var, stack_trace_var, saved_exception_var,
      saved_stack_trace_var, CatchClauseNode::kInvalidTryIndex, true);
  AstNode* try_catch_node = new (Z) TryCatchNode(
      TokenPosition::kNoSource, try_block, context_var, catch_clause,
      NULL,  // No finally clause.
      try_index,
      NULL);  // No rethrow-finally clause.
  current_block_->statements->Add(try_catch_node);
  return CloseBlock();
}

// Wrap the body of the async or async* closure in a try/catch block.
void Parser::OpenAsyncTryBlock() {
  ASSERT(innermost_function().IsAsyncClosure() ||
         innermost_function().IsAsyncGenClosure());
  LocalVariable* context_var = NULL;
  LocalVariable* exception_var = NULL;
  LocalVariable* stack_trace_var = NULL;
  LocalVariable* saved_exception_var = NULL;
  LocalVariable* saved_stack_trace_var = NULL;
  SetupExceptionVariables(current_block_->scope, true, &context_var,
                          &exception_var, &stack_trace_var,
                          &saved_exception_var, &saved_stack_trace_var);

  // Open the try block.
  OpenBlock();
  // This is the outermost try-catch in the function.
  ASSERT(try_stack_ == NULL);
  PushTry(current_block_);
  // Validate that we always get try index of 0.
  ASSERT(try_stack_->try_index() == CatchClauseNode::kImplicitAsyncTryIndex);

  SetupSavedTryContext(context_var);
}

void Parser::AddSyncGenClosureParameters(ParamList* params) {
  // Create the parameter list for the body closure of a sync generator:
  // 1) Implicit closure parameter;
  // 2) Iterator
  // Add implicit closure parameter if not already present.
  if (params->parameters->length() == 0) {
    params->AddFinalParameter(TokenPosition::kMinSource,
                              &Symbols::ClosureParameter(),
                              &Object::dynamic_type());
  }
  ParamDesc iterator_param;
  iterator_param.name = &Symbols::IteratorParameter();
  iterator_param.type = &Object::dynamic_type();
  params->parameters->Add(iterator_param);
  params->num_fixed_parameters++;
}

void Parser::AddAsyncGenClosureParameters(ParamList* params) {
  // Create the parameter list for the body closure of an async generator.
  // The closure has the same parameters as an asynchronous non-generator.
  AddAsyncClosureParameters(params);
}

RawFunction* Parser::OpenSyncGeneratorFunction(TokenPosition func_pos) {
  Function& body = Function::Handle(Z);
  String& body_closure_name = String::Handle(Z);
  bool is_new_closure = false;

  AddContinuationVariables();

  // Check whether a function for the body of this generator
  // function has already been created by a previous
  // compilation.
  const Function& found_func = Function::Handle(
      Z, I->LookupClosureFunction(innermost_function(), func_pos));
  if (!found_func.IsNull()) {
    ASSERT(found_func.IsSyncGenClosure());
    body = found_func.raw();
    body_closure_name = body.name();
  } else {
    // Create the closure containing the body of this generator function.
    String& generator_name = String::Handle(Z, innermost_function().name());
    body_closure_name =
        Symbols::NewFormatted(T, "<%s_sync_body>", generator_name.ToCString());
    body = Function::NewClosureFunction(body_closure_name, innermost_function(),
                                        func_pos);
    body.set_is_generated_body(true);
    body.set_result_type(Object::dynamic_type());
    is_new_closure = true;
  }

  ParamList closure_params;
  AddSyncGenClosureParameters(&closure_params);

  if (is_new_closure) {
    // Add the parameters to the newly created closure.
    AddFormalParamsToFunction(&closure_params, body);
    ResolveSignatureTypeParameters(body);
    // Finalize function type.
    Type& signature_type = Type::Handle(Z, body.SignatureType());
    signature_type ^= CanonicalizeType(signature_type);
    body.SetSignatureType(signature_type);
    ASSERT(AbstractType::Handle(Z, body.result_type()).IsResolved());
    ASSERT(body.NumParameters() == closure_params.parameters->length());
  }

  OpenFunctionBlock(body);
  AddFormalParamsToScope(&closure_params, current_block_->scope);
  async_temp_scope_ = current_block_->scope;
  return body.raw();
}

SequenceNode* Parser::CloseSyncGenFunction(const Function& closure,
                                           SequenceNode* closure_body) {
  // Explicitly reference variables of the sync generator function from the
  // closure body in order to mark them as captured.
  LocalVariable* existing_var =
      closure_body->scope()->LookupVariable(Symbols::AwaitJumpVar(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());
  existing_var =
      closure_body->scope()->LookupVariable(Symbols::AwaitContextVar(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());

  // :await_jump_var = -1;
  LocalVariable* jump_var =
      current_block_->scope->LookupVariable(Symbols::AwaitJumpVar(), false);
  LiteralNode* init_value = new (Z)
      LiteralNode(TokenPosition::kNoSource, Smi::ZoneHandle(Smi::New(-1)));
  current_block_->statements->Add(
      new (Z) StoreLocalNode(TokenPosition::kNoSource, jump_var, init_value));

  // return new SyncIterable(body_closure);
  const Class& iterable_class =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::_SyncIterable()));
  ASSERT(!iterable_class.IsNull());
  const Function& iterable_constructor =
      Function::ZoneHandle(Z, iterable_class.LookupConstructorAllowPrivate(
                                  Symbols::_SyncIterableConstructor()));
  ASSERT(!iterable_constructor.IsNull());

  const String& closure_name = String::Handle(Z, closure.name());
  ASSERT(closure_name.IsSymbol());

  ArgumentListNode* arguments =
      new (Z) ArgumentListNode(TokenPosition::kNoSource);
  ClosureNode* closure_obj = new (Z) ClosureNode(
      TokenPosition::kNoSource, closure, NULL, closure_body->scope());
  arguments->Add(closure_obj);
  ConstructorCallNode* new_iterable = new (Z) ConstructorCallNode(
      TokenPosition::kNoSource, TypeArguments::ZoneHandle(Z),
      iterable_constructor, arguments);
  ReturnNode* return_node =
      new (Z) ReturnNode(TokenPosition::kNoSource, new_iterable);
  current_block_->statements->Add(return_node);
  return CloseBlock();
}

void Parser::AddAsyncClosureParameters(ParamList* params) {
  // Async closures have three optional parameters:
  // * A continuation result.
  // * A continuation error.
  // * A continuation stack trace.
  ASSERT(params->parameters->length() <= 1);
  // Add implicit closure parameter if not yet present.
  if (params->parameters->length() == 0) {
    params->AddFinalParameter(TokenPosition::kMinSource,
                              &Symbols::ClosureParameter(),
                              &Object::dynamic_type());
  }
  ParamDesc result_param;
  result_param.name = &Symbols::AsyncOperationParam();
  result_param.default_value = &Object::null_instance();
  result_param.type = &Object::dynamic_type();
  params->parameters->Add(result_param);
  ParamDesc error_param;
  error_param.name = &Symbols::AsyncOperationErrorParam();
  error_param.default_value = &Object::null_instance();
  error_param.type = &Object::dynamic_type();
  params->parameters->Add(error_param);
  ParamDesc stack_trace_param;
  stack_trace_param.name = &Symbols::AsyncOperationStackTraceParam();
  stack_trace_param.default_value = &Object::null_instance();
  stack_trace_param.type = &Object::dynamic_type();
  params->parameters->Add(stack_trace_param);
  params->has_optional_positional_parameters = true;
  params->num_optional_parameters += 3;
}

RawFunction* Parser::OpenAsyncFunction(TokenPosition async_func_pos) {
  TRACE_PARSER("OpenAsyncFunction");
  AddContinuationVariables();
  AddAsyncClosureVariables();
  Function& closure = Function::Handle(Z);
  bool is_new_closure = false;

  // Check whether a function for the asynchronous function body of
  // this async function has already been created by a previous
  // compilation of this function.
  const Function& found_func = Function::Handle(
      Z, I->LookupClosureFunction(innermost_function(), async_func_pos));
  if (!found_func.IsNull()) {
    ASSERT(found_func.IsAsyncClosure());
    closure = found_func.raw();
  } else {
    // Create the closure containing the body of this async function.
    const String& async_func_name =
        String::Handle(Z, innermost_function().name());
    String& closure_name =
        String::Handle(Z, Symbols::NewFormatted(T, "<%s_async_body>",
                                                async_func_name.ToCString()));
    closure = Function::NewClosureFunction(closure_name, innermost_function(),
                                           async_func_pos);
    closure.set_is_generated_body(true);
    closure.set_result_type(Object::dynamic_type());
    is_new_closure = true;
  }
  // Create the parameter list for the async body closure.
  ParamList closure_params;
  AddAsyncClosureParameters(&closure_params);
  if (is_new_closure) {
    // Add the parameters to the newly created closure.
    AddFormalParamsToFunction(&closure_params, closure);
    ResolveSignatureTypeParameters(closure);

    // Finalize function type.
    Type& signature_type = Type::Handle(Z, closure.SignatureType());
    signature_type ^= CanonicalizeType(signature_type);
    closure.SetSignatureType(signature_type);
    ASSERT(AbstractType::Handle(Z, closure.result_type()).IsResolved());
    ASSERT(closure.NumParameters() == closure_params.parameters->length());
  }
  OpenFunctionBlock(closure);
  AddFormalParamsToScope(&closure_params, current_block_->scope);
  async_temp_scope_ = current_block_->scope;
  return closure.raw();
}

void Parser::AddContinuationVariables() {
  // Add to current block's scope:
  //   var :await_jump_var;
  //   var :await_ctx_var;
  LocalVariable* await_jump_var =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            Symbols::AwaitJumpVar(), Object::dynamic_type());
  current_block_->scope->AddVariable(await_jump_var);
  LocalVariable* await_ctx_var =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            Symbols::AwaitContextVar(), Object::dynamic_type());
  current_block_->scope->AddVariable(await_ctx_var);
}

void Parser::AddAsyncClosureVariables() {
  // Add to current block's scope:
  //   var :async_op;
  //   var :async_then_callback;
  //   var :async_catch_error_callback;
  //   var :async_completer;
  //   var :async_stack_trace;
  LocalVariable* async_op_var =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            Symbols::AsyncOperation(), Object::dynamic_type());
  current_block_->scope->AddVariable(async_op_var);
  LocalVariable* async_then_callback_var = new (Z)
      LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                    Symbols::AsyncThenCallback(), Object::dynamic_type());
  current_block_->scope->AddVariable(async_then_callback_var);
  LocalVariable* async_catch_error_callback_var = new (Z)
      LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                    Symbols::AsyncCatchErrorCallback(), Object::dynamic_type());
  current_block_->scope->AddVariable(async_catch_error_callback_var);
  LocalVariable* async_completer =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            Symbols::AsyncCompleter(), Object::dynamic_type());
  current_block_->scope->AddVariable(async_completer);
  LocalVariable* async_stack_trace = new (Z)
      LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                    Symbols::AsyncStackTraceVar(), Object::dynamic_type());
  current_block_->scope->AddVariable(async_stack_trace);
}

void Parser::AddAsyncGeneratorVariables() {
  // Add to current block's scope:
  //   var :controller;
  // The :controller variable is used by the async generator closure to
  // store the StreamController object to which the yielded expressions
  // are added.
  //   var :async_op;
  //   var :async_then_callback;
  //   var :async_catch_error_callback;
  //   var :async_stack_trace;
  //   var :controller_stream;
  // These variables are used to store the async generator closure containing
  // the body of the async* function. They are used by the await operator.
  LocalVariable* controller_var =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            Symbols::ColonController(), Object::dynamic_type());
  current_block_->scope->AddVariable(controller_var);
  LocalVariable* async_op_var =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            Symbols::AsyncOperation(), Object::dynamic_type());
  current_block_->scope->AddVariable(async_op_var);
  LocalVariable* async_then_callback_var = new (Z)
      LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                    Symbols::AsyncThenCallback(), Object::dynamic_type());
  current_block_->scope->AddVariable(async_then_callback_var);
  LocalVariable* async_catch_error_callback_var = new (Z)
      LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                    Symbols::AsyncCatchErrorCallback(), Object::dynamic_type());
  current_block_->scope->AddVariable(async_catch_error_callback_var);
  LocalVariable* async_stack_trace = new (Z)
      LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                    Symbols::AsyncStackTraceVar(), Object::dynamic_type());
  current_block_->scope->AddVariable(async_stack_trace);
  LocalVariable* controller_stream = new (Z)
      LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                    Symbols::ControllerStream(), Object::dynamic_type());
  current_block_->scope->AddVariable(controller_stream);
}

RawFunction* Parser::OpenAsyncGeneratorFunction(TokenPosition async_func_pos) {
  TRACE_PARSER("OpenAsyncGeneratorFunction");
  AddContinuationVariables();
  AddAsyncGeneratorVariables();

  Function& closure = Function::Handle(Z);
  bool is_new_closure = false;

  // Check whether a function for the asynchronous function body of
  // this async generator has already been created by a previous
  // compilation of this function.
  const Function& found_func = Function::Handle(
      Z, I->LookupClosureFunction(innermost_function(), async_func_pos));
  if (!found_func.IsNull()) {
    ASSERT(found_func.IsAsyncGenClosure());
    closure = found_func.raw();
  } else {
    // Create the closure containing the body of this async generator function.
    const String& async_generator_name =
        String::Handle(Z, innermost_function().name());
    const String& closure_name = String::Handle(
        Z, Symbols::NewFormatted(T, "<%s_async_gen_body>",
                                 async_generator_name.ToCString()));
    closure = Function::NewClosureFunction(closure_name, innermost_function(),
                                           async_func_pos);
    closure.set_is_generated_body(true);
    closure.set_result_type(Object::dynamic_type());
    is_new_closure = true;
  }

  ParamList closure_params;
  AddAsyncGenClosureParameters(&closure_params);

  if (is_new_closure) {
    // Add the parameters to the newly created closure.
    AddFormalParamsToFunction(&closure_params, closure);
    ResolveSignatureTypeParameters(closure);

    // Finalize function type.
    Type& signature_type = Type::Handle(Z, closure.SignatureType());
    signature_type ^= CanonicalizeType(signature_type);
    closure.SetSignatureType(signature_type);
    ASSERT(AbstractType::Handle(Z, closure.result_type()).IsResolved());
    ASSERT(closure.NumParameters() == closure_params.parameters->length());
  }

  OpenFunctionBlock(closure);
  AddFormalParamsToScope(&closure_params, current_block_->scope);
  async_temp_scope_ = current_block_->scope;
  return closure.raw();
}

// Generate the Ast nodes for the implicit code of the async* function.
//
// f(...) async* {
//   var :controller;
//   var :await_jump_var = -1;
//   var :await_context_var;
//   f_async_body() {
//     ... source code of f ...
//   }
//   var :async_op = f_async_body;
//   var :async_then_callback = _asyncThenWrapperHelper(:async_op);
//   var :async_catch_error_callback = _asyncCatchErrorWrapperHelper(:async_op);
//   :controller = new _AsyncStarStreamController(:async_op);
//   var :controller_stream = :controller.stream;
//   return :controller_stream;
// }
SequenceNode* Parser::CloseAsyncGeneratorFunction(const Function& closure_func,
                                                  SequenceNode* closure_body) {
  TRACE_PARSER("CloseAsyncGeneratorFunction");
  ASSERT(!closure_func.IsNull());
  ASSERT(closure_body != NULL);

  // Explicitly reference variables of the async generator function from the
  // closure body in order to mark them as captured.
  LocalVariable* existing_var =
      closure_body->scope()->LookupVariable(Symbols::AwaitJumpVar(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());
  existing_var =
      closure_body->scope()->LookupVariable(Symbols::AwaitContextVar(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());
  existing_var =
      closure_body->scope()->LookupVariable(Symbols::ColonController(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());
  existing_var =
      closure_body->scope()->LookupVariable(Symbols::AsyncOperation(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());
  existing_var = closure_body->scope()->LookupVariable(
      Symbols::AsyncThenCallback(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());
  existing_var = closure_body->scope()->LookupVariable(
      Symbols::AsyncCatchErrorCallback(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());
  existing_var = closure_body->scope()->LookupVariable(
      Symbols::AsyncStackTraceVar(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());
  existing_var =
      closure_body->scope()->LookupVariable(Symbols::ControllerStream(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());

  const Library& async_lib = Library::Handle(Library::AsyncLibrary());

  const Class& controller_class = Class::Handle(
      Z,
      async_lib.LookupClassAllowPrivate(Symbols::_AsyncStarStreamController()));
  ASSERT(!controller_class.IsNull());
  const Function& controller_constructor = Function::ZoneHandle(
      Z, controller_class.LookupConstructorAllowPrivate(
             Symbols::_AsyncStarStreamControllerConstructor()));

  // :await_jump_var = -1;
  LocalVariable* jump_var =
      current_block_->scope->LookupVariable(Symbols::AwaitJumpVar(), false);
  LiteralNode* init_value = new (Z)
      LiteralNode(TokenPosition::kNoSource, Smi::ZoneHandle(Smi::New(-1)));
  current_block_->statements->Add(
      new (Z) StoreLocalNode(TokenPosition::kNoSource, jump_var, init_value));

  TokenPosition token_pos = TokenPosition::kNoSource;

  // Add to AST:
  //   :async_op = <closure>;  (containing the original body)
  LocalVariable* async_op_var =
      current_block_->scope->LookupVariable(Symbols::AsyncOperation(), false);
  ClosureNode* closure_obj = new (Z) ClosureNode(
      TokenPosition::kNoSource, closure_func, NULL, closure_body->scope());
  StoreLocalNode* store_async_op = new (Z)
      StoreLocalNode(TokenPosition::kNoSource, async_op_var, closure_obj);

  current_block_->statements->Add(store_async_op);

  if (FLAG_causal_async_stacks) {
    // Add to AST:
    //   :async_stack_trace = _asyncStackTraceHelper(:async_op);
    const Function& async_stack_trace_helper = Function::ZoneHandle(
        Z,
        async_lib.LookupFunctionAllowPrivate(Symbols::AsyncStackTraceHelper()));
    ASSERT(!async_stack_trace_helper.IsNull());
    ArgumentListNode* async_stack_trace_helper_args =
        new (Z) ArgumentListNode(TokenPosition::kNoSource);
    async_stack_trace_helper_args->Add(
        new (Z) LoadLocalNode(TokenPosition::kNoSource, async_op_var));
    StaticCallNode* async_stack_trace_helper_call = new (Z)
        StaticCallNode(token_pos, async_stack_trace_helper,
                       async_stack_trace_helper_args, StaticCallNode::kStatic);
    LocalVariable* async_stack_trace_var =
        current_block_->scope->LookupVariable(Symbols::AsyncStackTraceVar(),
                                              false);
    StoreLocalNode* store_async_stack_trace = new (Z) StoreLocalNode(
        token_pos, async_stack_trace_var, async_stack_trace_helper_call);
    current_block_->statements->Add(store_async_stack_trace);
  }

  // :async_then_callback = _asyncThenWrapperHelper(:async_op)
  const Function& async_then_wrapper_helper = Function::ZoneHandle(
      Z,
      async_lib.LookupFunctionAllowPrivate(Symbols::AsyncThenWrapperHelper()));
  ASSERT(!async_then_wrapper_helper.IsNull());
  ArgumentListNode* async_then_wrapper_helper_args =
      new (Z) ArgumentListNode(TokenPosition::kNoSource);
  async_then_wrapper_helper_args->Add(
      new (Z) LoadLocalNode(TokenPosition::kNoSource, async_op_var));
  StaticCallNode* then_wrapper_call = new (Z)
      StaticCallNode(TokenPosition::kNoSource, async_then_wrapper_helper,
                     async_then_wrapper_helper_args, StaticCallNode::kStatic);
  LocalVariable* async_then_callback_var =
      current_block_->scope->LookupVariable(Symbols::AsyncThenCallback(),
                                            false);
  StoreLocalNode* store_async_then_callback = new (Z) StoreLocalNode(
      TokenPosition::kNoSource, async_then_callback_var, then_wrapper_call);

  current_block_->statements->Add(store_async_then_callback);

  // :async_catch_error_callback = _asyncErrorWrapperHelper(:async_op)

  const Function& async_error_wrapper_helper = Function::ZoneHandle(
      Z,
      async_lib.LookupFunctionAllowPrivate(Symbols::AsyncErrorWrapperHelper()));
  ASSERT(!async_error_wrapper_helper.IsNull());
  ArgumentListNode* async_error_wrapper_helper_args =
      new (Z) ArgumentListNode(TokenPosition::kNoSource);
  async_error_wrapper_helper_args->Add(
      new (Z) LoadLocalNode(TokenPosition::kNoSource, async_op_var));
  StaticCallNode* error_wrapper_call = new (Z)
      StaticCallNode(TokenPosition::kNoSource, async_error_wrapper_helper,
                     async_error_wrapper_helper_args, StaticCallNode::kStatic);
  LocalVariable* async_catch_error_callback_var =
      current_block_->scope->LookupVariable(Symbols::AsyncCatchErrorCallback(),
                                            false);
  StoreLocalNode* store_async_catch_error_callback = new (Z)
      StoreLocalNode(TokenPosition::kNoSource, async_catch_error_callback_var,
                     error_wrapper_call);

  current_block_->statements->Add(store_async_catch_error_callback);

  // :controller = new _AsyncStarStreamController(body_closure);
  ArgumentListNode* arguments =
      new (Z) ArgumentListNode(TokenPosition::kNoSource);
  arguments->Add(new (Z) LoadLocalNode(TokenPosition::kNoSource, async_op_var));
  ConstructorCallNode* controller_constructor_call =
      new (Z) ConstructorCallNode(TokenPosition::kNoSource,
                                  TypeArguments::ZoneHandle(Z),
                                  controller_constructor, arguments);
  LocalVariable* controller_var =
      current_block_->scope->LookupVariable(Symbols::ColonController(), false);
  StoreLocalNode* store_controller = new (Z) StoreLocalNode(
      TokenPosition::kNoSource, controller_var, controller_constructor_call);
  current_block_->statements->Add(store_controller);

  // Grab :controller.stream
  InstanceGetterNode* controller_stream = new (Z) InstanceGetterNode(
      TokenPosition::kNoSource,
      new (Z) LoadLocalNode(TokenPosition::kNoSource, controller_var),
      Symbols::Stream());

  // Store :controller.stream into :controller_stream inside the closure.
  // We have to remember the stream because a new instance is generated for
  // each getter invocation and in order to recreate the linkage, we need the
  // awaited on instance.
  LocalVariable* controller_stream_var =
      current_block_->scope->LookupVariable(Symbols::ControllerStream(), false);
  ASSERT(controller_stream_var != NULL);

  StoreLocalNode* store_controller_stream = new (Z) StoreLocalNode(
      TokenPosition::kNoSource, controller_stream_var, controller_stream);
  current_block_->statements->Add(store_controller_stream);

  // return :controller.stream;
  ReturnNode* return_node = new (Z) ReturnNode(
      TokenPosition::kNoSource,
      new (Z) LoadLocalNode(TokenPosition::kNoSource, controller_stream_var));
  current_block_->statements->Add(return_node);
  return CloseBlock();
}

void Parser::OpenAsyncGeneratorClosure() {
  async_temp_scope_ = current_block_->scope;
  OpenAsyncTryBlock();
}

SequenceNode* Parser::CloseAsyncGeneratorClosure(SequenceNode* body) {
  // We need a temporary expression to store intermediate return values.
  parsed_function()->EnsureExpressionTemp();

  SequenceNode* new_body = CloseAsyncGeneratorTryBlock(body);
  ASSERT(new_body != NULL);
  ASSERT(new_body->scope() != NULL);
  return new_body;
}

// Add a return node to the sequence if necessary.
void Parser::EnsureHasReturnStatement(SequenceNode* seq,
                                      TokenPosition return_pos) {
  if ((seq->length() == 0) || !seq->NodeAt(seq->length() - 1)->IsReturnNode()) {
    const Function& func = innermost_function();
    // The implicit return value of synchronous generator closures is false,
    // to indicate that there are no more elements in the iterable.
    // In other cases the implicit return value is null.
    AstNode* return_value =
        func.IsSyncGenClosure()
            ? new LiteralNode(return_pos, Bool::False())
            : new LiteralNode(return_pos, Instance::ZoneHandle());
    seq->Add(new ReturnNode(return_pos, return_value));
  }
}

SequenceNode* Parser::CloseBlock() {
  SequenceNode* statements = current_block_->statements;
  if (current_block_->scope != NULL) {
    // Record the begin and end token index of the scope.
    ASSERT(statements != NULL);
    current_block_->scope->set_begin_token_pos(statements->token_pos());
    current_block_->scope->set_end_token_pos(TokenPos());
  }
  current_block_ = current_block_->parent;
  return statements;
}

SequenceNode* Parser::CloseAsyncFunction(const Function& closure,
                                         SequenceNode* closure_body) {
  TRACE_PARSER("CloseAsyncFunction");
  ASSERT(!closure.IsNull());
  ASSERT(closure_body != NULL);

  // Explicitly reference variables of the async function from the
  // closure body in order to mark them as captured.
  LocalVariable* existing_var =
      closure_body->scope()->LookupVariable(Symbols::AwaitJumpVar(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());
  existing_var =
      closure_body->scope()->LookupVariable(Symbols::AwaitContextVar(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());
  existing_var =
      closure_body->scope()->LookupVariable(Symbols::AsyncCompleter(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());
  existing_var = closure_body->scope()->LookupVariable(
      Symbols::AsyncStackTraceVar(), false);
  ASSERT((existing_var != NULL) && existing_var->is_captured());

  // Create and return a new future that executes a closure with the current
  // body.

  // No need to capture parameters or other variables, since they have already
  // been captured in the corresponding scope as the body has been parsed within
  // a nested block (contained in the async function's block).
  const Class& future = Class::ZoneHandle(Z, I->object_store()->future_class());
  ASSERT(!future.IsNull());
  const Function& constructor = Function::ZoneHandle(
      Z, future.LookupFunction(Symbols::FutureMicrotask()));
  ASSERT(!constructor.IsNull());
  const Class& completer =
      Class::ZoneHandle(Z, I->object_store()->completer_class());
  ASSERT(!completer.IsNull());
  const Function& completer_constructor = Function::ZoneHandle(
      Z, completer.LookupFunction(Symbols::CompleterSyncConstructor()));
  ASSERT(!completer_constructor.IsNull());

  LocalVariable* async_completer =
      current_block_->scope->LookupVariable(Symbols::AsyncCompleter(), false);

  const TokenPosition token_pos = ST(closure_body->token_pos());
  // Add to AST:
  //   :async_completer = new Completer.sync();
  ArgumentListNode* empty_args = new (Z) ArgumentListNode(token_pos);
  ConstructorCallNode* completer_constructor_node =
      new (Z) ConstructorCallNode(token_pos, TypeArguments::ZoneHandle(Z),
                                  completer_constructor, empty_args);
  StoreLocalNode* store_completer = new (Z)
      StoreLocalNode(token_pos, async_completer, completer_constructor_node);
  current_block_->statements->Add(store_completer);

  // :await_jump_var = -1;
  LocalVariable* jump_var =
      current_block_->scope->LookupVariable(Symbols::AwaitJumpVar(), false);
  LiteralNode* init_value =
      new (Z) LiteralNode(token_pos, Smi::ZoneHandle(Smi::New(-1)));
  current_block_->statements->Add(
      new (Z) StoreLocalNode(token_pos, jump_var, init_value));

  // Add to AST:
  //   :async_op = <closure>;  (containing the original body)
  LocalVariable* async_op_var =
      current_block_->scope->LookupVariable(Symbols::AsyncOperation(), false);
  ClosureNode* cn =
      new (Z) ClosureNode(token_pos, closure, NULL, closure_body->scope());
  StoreLocalNode* store_async_op =
      new (Z) StoreLocalNode(token_pos, async_op_var, cn);
  current_block_->statements->Add(store_async_op);

  const Library& async_lib = Library::Handle(Library::AsyncLibrary());

  if (FLAG_causal_async_stacks) {
    // Add to AST:
    //   :async_stack_trace = _asyncStackTraceHelper();
    const Function& async_stack_trace_helper = Function::ZoneHandle(
        Z,
        async_lib.LookupFunctionAllowPrivate(Symbols::AsyncStackTraceHelper()));
    ASSERT(!async_stack_trace_helper.IsNull());
    ArgumentListNode* async_stack_trace_helper_args =
        new (Z) ArgumentListNode(token_pos);
    async_stack_trace_helper_args->Add(
        new (Z) LoadLocalNode(token_pos, async_op_var));
    StaticCallNode* async_stack_trace_helper_call = new (Z)
        StaticCallNode(token_pos, async_stack_trace_helper,
                       async_stack_trace_helper_args, StaticCallNode::kStatic);
    LocalVariable* async_stack_trace_var =
        current_block_->scope->LookupVariable(Symbols::AsyncStackTraceVar(),
                                              false);
    StoreLocalNode* store_async_stack_trace = new (Z) StoreLocalNode(
        token_pos, async_stack_trace_var, async_stack_trace_helper_call);
    current_block_->statements->Add(store_async_stack_trace);
  }

  // :async_then_callback = _asyncThenWrapperHelper(:async_op)
  const Function& async_then_wrapper_helper = Function::ZoneHandle(
      Z,
      async_lib.LookupFunctionAllowPrivate(Symbols::AsyncThenWrapperHelper()));
  ASSERT(!async_then_wrapper_helper.IsNull());
  ArgumentListNode* async_then_wrapper_helper_args =
      new (Z) ArgumentListNode(token_pos);
  async_then_wrapper_helper_args->Add(
      new (Z) LoadLocalNode(token_pos, async_op_var));
  StaticCallNode* then_wrapper_call = new (Z)
      StaticCallNode(token_pos, async_then_wrapper_helper,
                     async_then_wrapper_helper_args, StaticCallNode::kStatic);
  LocalVariable* async_then_callback_var =
      current_block_->scope->LookupVariable(Symbols::AsyncThenCallback(),
                                            false);
  StoreLocalNode* store_async_then_callback = new (Z)
      StoreLocalNode(token_pos, async_then_callback_var, then_wrapper_call);

  current_block_->statements->Add(store_async_then_callback);

  // :async_catch_error_callback = _asyncErrorWrapperHelper(:async_op)

  const Function& async_error_wrapper_helper = Function::ZoneHandle(
      Z,
      async_lib.LookupFunctionAllowPrivate(Symbols::AsyncErrorWrapperHelper()));
  ASSERT(!async_error_wrapper_helper.IsNull());
  ArgumentListNode* async_error_wrapper_helper_args =
      new (Z) ArgumentListNode(token_pos);
  async_error_wrapper_helper_args->Add(
      new (Z) LoadLocalNode(token_pos, async_op_var));
  StaticCallNode* error_wrapper_call = new (Z)
      StaticCallNode(token_pos, async_error_wrapper_helper,
                     async_error_wrapper_helper_args, StaticCallNode::kStatic);
  LocalVariable* async_catch_error_callback_var =
      current_block_->scope->LookupVariable(Symbols::AsyncCatchErrorCallback(),
                                            false);
  StoreLocalNode* store_async_catch_error_callback = new (Z) StoreLocalNode(
      token_pos, async_catch_error_callback_var, error_wrapper_call);

  current_block_->statements->Add(store_async_catch_error_callback);

  // Add to AST:
  //   new Future.microtask(:async_op);
  ArgumentListNode* arguments = new (Z) ArgumentListNode(token_pos);
  arguments->Add(new (Z) LoadLocalNode(token_pos, async_op_var));
  ConstructorCallNode* future_node = new (Z) ConstructorCallNode(
      token_pos, TypeArguments::ZoneHandle(Z), constructor, arguments);
  current_block_->statements->Add(future_node);

  // Add to AST:
  //   return :async_completer.future;
  ReturnNode* return_node = new (Z) ReturnNode(
      token_pos,
      new (Z) InstanceGetterNode(
          token_pos, new (Z) LoadLocalNode(token_pos, async_completer),
          Symbols::CompleterFuture()));
  current_block_->statements->Add(return_node);
  return CloseBlock();
}

SequenceNode* Parser::CloseAsyncClosure(SequenceNode* body,
                                        TokenPosition func_end_pos) {
  // We need a temporary expression to store intermediate return values.
  parsed_function()->EnsureExpressionTemp();

  SequenceNode* new_body = CloseAsyncTryBlock(body, func_end_pos);
  ASSERT(new_body != NULL);
  ASSERT(new_body->scope() != NULL);
  return new_body;
}

// Set up default values for all optional parameters to the function.
void Parser::SetupDefaultsForOptionalParams(const ParamList& params) {
  if ((current_function().raw() == innermost_function().raw()) &&
      (params.num_optional_parameters > 0)) {
    ZoneGrowableArray<const Instance*>* default_values =
        new ZoneGrowableArray<const Instance*>(zone(),
                                               params.num_optional_parameters);
    // Build array of default parameter values.
    const ZoneGrowableArray<ParamDesc>& parameters = *params.parameters;
    const int first_opt_param_offset = params.num_fixed_parameters;
    for (int i = 0; i < params.num_optional_parameters; i++) {
      const Instance* default_value =
          parameters[i + first_opt_param_offset].default_value;
      default_values->Add(default_value);
    }
    parsed_function()->set_default_parameter_values(default_values);
  }
}

void Parser::FinalizeFormalParameterTypes(const ParamList* params) {
  ASSERT((params != NULL) && (params->parameters != NULL));
  const int num_parameters = params->parameters->length();
  AbstractType& type = AbstractType::Handle(Z);
  for (int i = 0; i < num_parameters; i++) {
    ParamDesc& param_desc = (*params->parameters)[i];
    type = param_desc.type->raw();
    ResolveTypeParameters(&type);
    type = CanonicalizeType(type);
    if (type.raw() != param_desc.type->raw()) {
      param_desc.type = &AbstractType::ZoneHandle(Z, type.raw());
    }
  }
}

// Populate the parameter type array and parameter name array of the function
// with the formal parameter types and names.
void Parser::AddFormalParamsToFunction(const ParamList* params,
                                       const Function& func) {
  ASSERT((params != NULL) && (params->parameters != NULL));
  ASSERT((params->num_optional_parameters > 0) ==
         (params->has_optional_positional_parameters ||
          params->has_optional_named_parameters));
  if (!Utils::IsInt(16, params->num_fixed_parameters) ||
      !Utils::IsInt(16, params->num_optional_parameters)) {
    const Script& script = Script::Handle(Class::Handle(func.Owner()).script());
    Report::MessageF(Report::kError, script, func.token_pos(),
                     Report::AtLocation, "too many formal parameters");
  }
  func.set_num_fixed_parameters(params->num_fixed_parameters);
  func.SetNumOptionalParameters(params->num_optional_parameters,
                                params->has_optional_positional_parameters);
  const int num_parameters = params->parameters->length();
  ASSERT(num_parameters == func.NumParameters());
  ASSERT(func.parameter_types() == Object::empty_array().raw());
  ASSERT(func.parameter_names() == Object::empty_array().raw());
  func.set_parameter_types(
      Array::Handle(Array::New(num_parameters, Heap::kOld)));
  func.set_parameter_names(
      Array::Handle(Array::New(num_parameters, Heap::kOld)));
  AbstractType& param_type = AbstractType::Handle();
  for (int i = 0; i < num_parameters; i++) {
    ParamDesc& param_desc = (*params->parameters)[i];
    param_type = param_desc.type->raw();
    if (param_desc.is_covariant) {
      if (!func.IsDynamicFunction(true)) {
        ReportError(param_desc.name_pos,
                    "only instance functions may have "
                    "covariant parameters");
      }
      // In non-strong mode, the covariant keyword is ignored. In strong mode,
      // the parameter type is changed to Object.
      if (FLAG_strong) {
        param_type = Type::ObjectType();
      }
    }
    func.SetParameterTypeAt(i, param_type);
    func.SetParameterNameAt(i, *param_desc.name);
    if (param_desc.is_field_initializer && !func.IsGenerativeConstructor()) {
      // Redirecting constructors are detected later in ParseConstructor.
      ReportError(param_desc.name_pos,
                  "only generative constructors may have "
                  "initializing formal parameters");
    }
  }
}

// Populate local scope with the formal parameters.
void Parser::AddFormalParamsToScope(const ParamList* params,
                                    LocalScope* scope) {
  ASSERT((params != NULL) && (params->parameters != NULL));
  ASSERT(scope != NULL);
  const int num_parameters = params->parameters->length();
  for (int i = 0; i < num_parameters; i++) {
    ParamDesc& param_desc = (*params->parameters)[i];
    const String* name = param_desc.name;
    LocalVariable* parameter = new (Z) LocalVariable(
        param_desc.name_pos, param_desc.name_pos, *name, *param_desc.type);
    if (!scope->InsertParameterAt(i, parameter)) {
      ReportError(param_desc.name_pos, "name '%s' already exists in scope",
                  param_desc.name->ToCString());
    }
    param_desc.var = parameter;
    if (param_desc.is_final) {
      parameter->set_is_final();
    }
    if (FLAG_initializing_formal_access) {
      // Field initializer parameters are implicitly final.
      ASSERT(!param_desc.is_field_initializer || param_desc.is_final);
    } else if (param_desc.is_field_initializer) {
      parameter->set_invisible(true);
    }
  }
}

// Builds ReturnNode/NativeBodyNode for a native function.
void Parser::ParseNativeFunctionBlock(const ParamList* params,
                                      const Function& func) {
  ASSERT(func.is_native());
  ASSERT(func.NumParameters() == params->parameters->length());
  TRACE_PARSER("ParseNativeFunctionBlock");

  // Parse the function name out.
  const String& native_name = ParseNativeDeclaration();

  // Now add the NativeBodyNode and return statement.
  current_block_->statements->Add(new (Z) ReturnNode(
      TokenPos(),
      new (Z) NativeBodyNode(TokenPos(), Function::ZoneHandle(Z, func.raw()),
                             native_name, current_block_->scope,
                             FLAG_link_natives_lazily)));
}

LocalVariable* Parser::LookupReceiver(LocalScope* from_scope, bool test_only) {
  ASSERT(!current_function().is_static());
  return from_scope->LookupVariable(Symbols::This(), test_only);
}

LocalVariable* Parser::LookupTypeArgumentsParameter(LocalScope* from_scope,
                                                    bool test_only) {
  ASSERT(current_function().IsInFactoryScope());
  return from_scope->LookupVariable(Symbols::TypeArgumentsParameter(),
                                    test_only);
}

void Parser::CaptureInstantiator() {
  ASSERT(FunctionLevel() > 0);
  const String* variable_name = current_function().IsInFactoryScope()
                                    ? &Symbols::TypeArgumentsParameter()
                                    : &Symbols::This();
  current_block_->scope->CaptureVariable(
      current_block_->scope->LookupVariable(*variable_name, true));
}

void Parser::CaptureFunctionTypeArguments() {
  ASSERT(InGenericFunctionScope());
  ASSERT(FunctionLevel() > 0);
  if (!FLAG_reify_generic_functions) {
    return;
  }
  const String* variable_name = &Symbols::FunctionTypeArgumentsVar();
  current_block_->scope->CaptureVariable(
      current_block_->scope->LookupVariable(*variable_name, true));
}

void Parser::CaptureAllInstantiators() {
  if (IsInstantiatorRequired()) {
    CaptureInstantiator();
  }
  if (innermost_function().HasGenericParent()) {
    CaptureFunctionTypeArguments();
  }
}

AstNode* Parser::LoadReceiver(TokenPosition token_pos) {
  // A nested function may access 'this', referring to the receiver of the
  // outermost enclosing function.
  const bool kTestOnly = false;
  LocalVariable* receiver = LookupReceiver(current_block_->scope, kTestOnly);
  if (receiver == NULL) {
    ReportError(token_pos, "illegal implicit access to receiver 'this'");
  }
  return new (Z) LoadLocalNode(TokenPos(), receiver);
}

InstanceGetterNode* Parser::CallGetter(TokenPosition token_pos,
                                       AstNode* object,
                                       const String& name) {
  return new (Z) InstanceGetterNode(token_pos, object, name);
}

// Returns ast nodes of the variable initialization.
AstNode* Parser::ParseVariableDeclaration(const AbstractType& type,
                                          bool is_final,
                                          bool is_const,
                                          SequenceNode** await_preamble) {
  TRACE_PARSER("ParseVariableDeclaration");
  ASSERT(IsIdentifier());
  const TokenPosition ident_pos = TokenPos();
  const String& ident = *CurrentLiteral();
  ConsumeToken();  // Variable identifier.
  const TokenPosition assign_pos = TokenPos();
  AstNode* initialization = NULL;
  LocalVariable* variable = NULL;
  if (CurrentToken() == Token::kASSIGN) {
    // Variable initialization.
    ConsumeToken();
    AstNode* expr =
        ParseAwaitableExpr(is_const, kConsumeCascades, await_preamble);
    const TokenPosition expr_end_pos = TokenPos();
    variable = new (Z) LocalVariable(ident_pos, expr_end_pos, ident, type);
    initialization = new (Z) StoreLocalNode(assign_pos, variable, expr);
    if (is_const) {
      ASSERT(expr->IsLiteralNode());
      variable->SetConstValue(expr->AsLiteralNode()->literal());
    }
  } else if (is_final || is_const) {
    ReportError(ident_pos,
                "missing initialization of 'final' or 'const' variable");
  } else {
    // Initialize variable with null.
    variable = new (Z) LocalVariable(ident_pos, assign_pos, ident, type);
    AstNode* null_expr =
        new (Z) LiteralNode(ident_pos, Object::null_instance());
    initialization = new (Z) StoreLocalNode(ident_pos, variable, null_expr);
  }

  ASSERT(current_block_ != NULL);
  const TokenPosition previous_pos =
      current_block_->scope->PreviousReferencePos(ident);
  if (previous_pos.IsReal()) {
    ASSERT(!script_.IsNull());
    if (previous_pos > ident_pos) {
      ReportError(ident_pos, "initializer of '%s' may not refer to itself",
                  ident.ToCString());

    } else {
      intptr_t line_number;
      script_.GetTokenLocation(previous_pos, &line_number, NULL);
      ReportError(ident_pos, "identifier '%s' previously used in line %" Pd "",
                  ident.ToCString(), line_number);
    }
  }

  // Add variable to scope after parsing the initializer expression.
  // The expression must not be able to refer to the variable.
  if (!current_block_->scope->AddVariable(variable)) {
    LocalVariable* existing_var =
        current_block_->scope->LookupVariable(variable->name(), true);
    ASSERT(existing_var != NULL);
    // Use before define cases have already been detected and reported above.
    ASSERT(existing_var->owner() == current_block_->scope);
    ReportError(ident_pos, "identifier '%s' already defined",
                variable->name().ToCString());
  }
  if (is_final || is_const) {
    variable->set_is_final();
  }
  return initialization;
}

// Parses ('var' | 'final' [type] | 'const' [type] | type).
// The presence of 'final' or 'const' must be detected and remembered
// before the call. If a type is parsed, it may be resolved and finalized
// according to the given type finalization mode.
RawAbstractType* Parser::ParseConstFinalVarOrType(
    ClassFinalizer::FinalizationKind finalization) {
  TRACE_PARSER("ParseConstFinalVarOrType");
  if (CurrentToken() == Token::kVAR) {
    ConsumeToken();
    return Type::DynamicType();
  }
  bool type_is_optional = false;
  if ((CurrentToken() == Token::kFINAL) || (CurrentToken() == Token::kCONST)) {
    ConsumeToken();
    type_is_optional = true;
  }
  if ((CurrentToken() == Token::kVOID) || IsFunctionTypeSymbol()) {
    return ParseFunctionType(AbstractType::Handle(Z), finalization);
  }
  if (CurrentToken() != Token::kIDENT) {
    if (type_is_optional) {
      return Type::DynamicType();
    } else {
      ReportError("type name expected");
    }
  }
  if (type_is_optional) {
    Token::Kind follower = LookaheadToken(1);
    // We have an identifier followed by a 'follower' token.
    // We either parse a type or return now.
    if ((follower != Token::kLT) &&        // Parameterized type.
        (follower != Token::kPERIOD) &&    // Qualified class name of type.
        !Token::IsIdentifier(follower) &&  // Variable name following a type.
        (follower != Token::kTHIS)) {      // Field parameter following a type.
      return Type::DynamicType();
    }
  }
  return ParseTypeOrFunctionType(false, finalization);
}

// Returns ast nodes of the variable initialization. Variables without an
// explicit initializer are initialized to null. If several variables are
// declared, the individual initializers are collected in a sequence node.
AstNode* Parser::ParseVariableDeclarationList() {
  TRACE_PARSER("ParseVariableDeclarationList");
  SkipMetadata();
  bool is_final = (CurrentToken() == Token::kFINAL);
  bool is_const = (CurrentToken() == Token::kCONST);
  const AbstractType& type = AbstractType::ZoneHandle(
      Z,
      ParseConstFinalVarOrType(I->type_checks() ? ClassFinalizer::kCanonicalize
                                                : ClassFinalizer::kIgnore));
  if (!IsIdentifier()) {
    ReportError("identifier expected");
  }

  SequenceNode* preamble = NULL;
  AstNode* initializers =
      ParseVariableDeclaration(type, is_final, is_const, &preamble);
  ASSERT(initializers != NULL);
  if (preamble != NULL) {
    preamble->Add(initializers);
    initializers = preamble;
  }
  while (CurrentToken() == Token::kCOMMA) {
    ConsumeToken();
    if (!IsIdentifier()) {
      ReportError("identifier expected after comma");
    }
    // We have a second initializer. Allocate a sequence node now.
    // The sequence does not own the current scope. Set its own scope to NULL.
    SequenceNode* sequence =
        NodeAsSequenceNode(initializers->token_pos(), initializers, NULL);
    preamble = NULL;
    AstNode* declaration =
        ParseVariableDeclaration(type, is_final, is_const, &preamble);
    if (preamble != NULL) {
      sequence->Add(preamble);
    }
    sequence->Add(declaration);
    initializers = sequence;
  }
  return initializers;
}

AstNode* Parser::ParseFunctionStatement(bool is_literal) {
  TRACE_PARSER("ParseFunctionStatement");
  AbstractType& result_type = AbstractType::Handle(Z, Type::DynamicType());
  const String* function_name = NULL;
  const TokenPosition function_pos = TokenPos();
  TokenPosition function_name_pos = TokenPosition::kNoSource;
  TokenPosition metadata_pos = TokenPosition::kNoSource;
  if (is_literal) {
    ASSERT(CurrentToken() == Token::kLPAREN || CurrentToken() == Token::kLT);
    function_name = &Symbols::AnonymousClosure();
  } else {
    metadata_pos = SkipMetadata();
    // Parse optional result type.
    if (IsFunctionReturnType()) {
      // It is too early to resolve the type here, since it can be a result type
      // referring to a not yet declared function type parameter.
      result_type =
          ParseTypeOrFunctionType(true, ClassFinalizer::kDoNotResolve);
    }
    function_name_pos = TokenPos();
    function_name = ExpectIdentifier("function name expected");

    // Check that the function name has not been referenced
    // before this declaration.
    ASSERT(current_block_ != NULL);
    const TokenPosition previous_pos =
        current_block_->scope->PreviousReferencePos(*function_name);
    if (previous_pos.IsReal()) {
      ASSERT(!script_.IsNull());
      intptr_t line_number;
      script_.GetTokenLocation(previous_pos, &line_number, NULL);
      ReportError(function_name_pos,
                  "identifier '%s' previously used in line %" Pd "",
                  function_name->ToCString(), line_number);
    }
  }

  // Check whether we have parsed this closure function before, in a previous
  // compilation. If so, reuse the function object, else create a new one
  // and register it in the current class.
  // Note that we cannot share the same closure function between the closurized
  // and non-closurized versions of the same parent function.
  Function& function = Function::ZoneHandle(Z);
  bool found_func = true;
  // TODO(hausner): There could be two different closures at the given
  // function_pos, one enclosed in a closurized function and one enclosed in the
  // non-closurized version of this same function.
  function = I->LookupClosureFunction(innermost_function(), function_pos);
  if (function.IsNull()) {
    // The function will be registered in the lookup table by the
    // EffectGraphVisitor::VisitClosureNode when the newly allocated closure
    // function has been properly setup.
    found_func = false;
    function = Function::NewClosureFunction(*function_name,
                                            innermost_function(), function_pos);
    function.set_result_type(result_type);
    // The result type may refer to the function's type parameters,
    // but was not parsed in the scope of the function. Adjust.
    result_type.SetScopeFunction(function);
    if (metadata_pos.IsReal()) {
      library_.AddFunctionMetadata(function, metadata_pos);
    }
  }

  ASSERT(function.parent_function() == innermost_function_.raw());
  innermost_function_ = function.raw();

  if (CurrentToken() == Token::kLT) {
    if (!FLAG_generic_method_syntax) {
      ReportError("generic functions not supported");
    }
    if (!found_func) {
      ParseTypeParameters(false);  // Not parameterizing class, but function.
    } else {
      TryParseTypeParameters();
    }
  }

  CheckToken(Token::kLPAREN);

  // The function type needs to be finalized at compile time, since the closure
  // may be type checked at run time when assigned to a function variable,
  // passed as a function argument, or returned as a function result.

  LocalVariable* function_variable = NULL;
  Type& function_type = Type::ZoneHandle(Z);
  if (!is_literal) {
    // Since the function type depends on the signature of the closure function,
    // it cannot be determined before the formal parameter list of the closure
    // function is parsed. Therefore, we set the function type to a new
    // function type to be patched after the actual type is known.
    // We temporarily use the Closure class as scope class.
    const Class& unknown_scope_class =
        Class::Handle(Z, I->object_store()->closure_class());
    function_type =
        Type::New(unknown_scope_class, TypeArguments::Handle(Z), function_pos);
    function_type.set_signature(function);
    function_type.SetIsFinalized();  // No finalization needed.

    // Add the function variable to the scope before parsing the function in
    // order to allow self reference from inside the function.
    function_variable = new (Z) LocalVariable(function_name_pos, function_pos,
                                              *function_name, function_type);
    function_variable->set_is_final();
    ASSERT(current_block_ != NULL);
    ASSERT(current_block_->scope != NULL);
    if (!current_block_->scope->AddVariable(function_variable)) {
      LocalVariable* existing_var = current_block_->scope->LookupVariable(
          function_variable->name(), true);
      ASSERT(existing_var != NULL);
      // Use before define cases have already been detected and reported above.
      ASSERT(existing_var->owner() == current_block_->scope);
      ReportError(function_pos, "identifier '%s' already defined",
                  function_variable->name().ToCString());
    }
  }

  Type& signature_type = Type::ZoneHandle(Z);
  SequenceNode* statements = NULL;
  if (!found_func) {
    // Parse the local function. As a side effect of the parsing, the
    // variables of this function's scope that are referenced by the local
    // function (and its inner nested functions) will be marked as captured.

    ResolveTypeParameters(&result_type);
    function.set_result_type(result_type);  // Update type without scope change.
    // Type parameters appearing in parameter types are resolved in ParseFunc.
    statements = Parser::ParseFunc(function, !is_literal);
    INC_STAT(thread(), num_functions_parsed, 1);

    // Now that the local function has formal parameters, finalize its signature
    signature_type = function.SignatureType();
    signature_type ^= CanonicalizeType(signature_type);
    function.SetSignatureType(signature_type);
  } else {
    // The local function was parsed before. The captured variables are
    // saved in the function's context scope. Iterate over the context scope
    // and mark its variables as captured.
    const ContextScope& context_scope =
        ContextScope::Handle(Z, function.context_scope());
    ASSERT(!context_scope.IsNull());
    String& var_name = String::Handle(Z);
    for (int i = 0; i < context_scope.num_variables(); i++) {
      var_name = context_scope.NameAt(i);
      // We need to look up the name in a way that returns even hidden
      // variables, e.g. 'this' in an initializer list.
      LocalVariable* v = current_block_->scope->LookupVariable(var_name, true);
      ASSERT(v != NULL);
      current_block_->scope->CaptureVariable(v);
    }
    SkipFunctionLiteral();
    signature_type = function.SignatureType();
  }

  // Local functions are registered in the enclosing class, but
  // ignored during class finalization. The enclosing class has
  // already been finalized.
  ASSERT(current_class().is_finalized());
  ASSERT(signature_type.IsFinalized());

  // Make sure that the instantiators are captured.
  if ((FunctionLevel() > 0) && !signature_type.IsInstantiated()) {
    CaptureAllInstantiators();
  }

  // A local signature type itself cannot be malformed or malbounded, only its
  // signature function's result type or parameter types may be.
  ASSERT(!signature_type.IsMalformed());
  ASSERT(!signature_type.IsMalbounded());

  if (!is_literal) {
    // Patch the function type of the variable now that the signature is known.
    function_type.set_type_class(Class::Handle(Z, signature_type.type_class()));
    function_type.set_arguments(
        TypeArguments::Handle(Z, signature_type.arguments()));
    ASSERT(function_type.signature() == function.raw());

    // The function type was initially marked as instantiated, but it may
    // actually be uninstantiated.
    function_type.ResetIsFinalized();

    // The function variable type should have been patched above.
    ASSERT(function_variable->type().raw() == function_type.raw());
  }

  // The code generator does not compile the closure function when visiting
  // a ClosureNode. The generated code allocates a new Closure object containing
  // the current context. The type of the Closure object refers to the closure
  // function, which will be compiled on first invocation of the closure object.
  // Therefore, we ignore the parsed default_parameter_values and the
  // node_sequence representing the body of the closure function, which will be
  // parsed again when compiled later.
  // The only purpose of parsing the function now (besides reporting obvious
  // errors) is to mark referenced variables of the enclosing scopes as
  // captured. The captured variables will be recorded along with their
  // allocation information in a Scope object stored in the function object.
  // This Scope object is then provided to the compiler when compiling the local
  // function. It would be too early to record the captured variables here,
  // since further closure functions may capture more variables.
  // This Scope object is constructed after all variables have been allocated.
  // The local scope of the parsed function can be pruned, since contained
  // variables are not relevant for the compilation of the enclosing function.
  // This pruning is done by omitting to hook the local scope in its parent
  // scope in the constructor of LocalScope.
  AstNode* closure =
      new (Z) ClosureNode(function_pos, function, NULL,
                          statements != NULL ? statements->scope() : NULL);

  ASSERT(innermost_function_.raw() == function.raw());
  innermost_function_ = function.parent_function();
  return is_literal
             ? closure
             : new (Z) StoreLocalNode(function_pos, function_variable, closure);
}

// Returns true if the current and next tokens can be parsed as type
// parameters. Current token position is not saved and restored.
bool Parser::TryParseTypeParameters() {
  ASSERT(CurrentToken() == Token::kLT);
  int nesting_level = 0;
  do {
    Token::Kind ct = CurrentToken();
    if (ct == Token::kLT) {
      nesting_level++;
    } else if (ct == Token::kGT) {
      nesting_level--;
    } else if (ct == Token::kSHR) {
      nesting_level -= 2;
    } else if (ct == Token::kIDENT) {
      // Check to see if it is a qualified identifier.
      if (LookaheadToken(1) == Token::kPERIOD) {
        // Consume the identifier, the period will be consumed below.
        ConsumeToken();
      }
    } else if ((ct != Token::kCOMMA) && (ct != Token::kEXTENDS) &&
               (!FLAG_generic_method_syntax || (ct != Token::kSUPER))) {
      // We are looking at something other than type parameters.
      return false;
    }
    ConsumeToken();
  } while (nesting_level > 0);
  if (nesting_level < 0) {
    return false;
  }
  return true;
}

// Returns true if the next tokens can be parsed as type parameters.
bool Parser::IsTypeParameters() {
  if (CurrentToken() == Token::kLT) {
    TokenPosScope param_pos(this);
    if (!TryParseTypeParameters()) {
      return false;
    }
    return true;
  }
  return false;
}

// Returns true if the next tokens are [ typeParameters ] '('.
bool Parser::IsParameterPart() {
  if (CurrentToken() == Token::kLPAREN) {
    return true;
  }
  if (CurrentToken() == Token::kLT) {
    TokenPosScope type_arg_pos(this);
    if (!TryParseTypeParameters()) {
      return false;
    }
    return CurrentToken() == Token::kLPAREN;
  }
  return false;
}

// Returns true if the current and next tokens can be parsed as type
// arguments. Current token position is not saved and restored.
bool Parser::TryParseTypeArguments() {
  ASSERT(CurrentToken() == Token::kLT);
  int nesting_level = 0;
  do {
    Token::Kind ct = CurrentToken();
    if (ct == Token::kLT) {
      nesting_level++;
    } else if (ct == Token::kGT) {
      nesting_level--;
    } else if (ct == Token::kSHR) {
      nesting_level -= 2;
    } else if (ct == Token::kIDENT) {
      if (IsFunctionTypeSymbol()) {
        if (!TryParseType(false)) {
          return false;
        }
        continue;
      } else {
        // Check to see if it is a qualified identifier.
        if (LookaheadToken(1) == Token::kPERIOD) {
          // Consume the identifier, the period will be consumed below.
          ConsumeToken();
        }
      }
    } else if (ct != Token::kCOMMA) {
      return false;
    }
    ConsumeToken();
  } while (nesting_level > 0);
  if (nesting_level < 0) {
    return false;
  }
  return true;
}

// Returns true if the next tokens are [ typeArguments ] '('.
bool Parser::IsArgumentPart() {
  if (CurrentToken() == Token::kLPAREN) {
    return true;
  }
  if (CurrentToken() == Token::kLT) {
    TokenPosScope type_arg_pos(this);
    if (!TryParseTypeArguments()) {
      return false;
    }
    return CurrentToken() == Token::kLPAREN;
  }
  return false;
}

bool Parser::IsSimpleLiteral(const AbstractType& type, Instance* value) {
  // Assigning null never causes a type error.
  if (CurrentToken() == Token::kNULL) {
    *value = Instance::null();
    return true;
  }
  // If the type of the const field is guaranteed to be instantiated once
  // resolved at class finalization time, and if the type of the literal is one
  // of int, double, String, or bool, then preset the field with the value and
  // perform the type check (in checked mode only) at finalization time.
  if (type.IsTypeParameter() || (type.arguments() != TypeArguments::null())) {
    // Type parameters are always resolved eagerly by the parser and never
    // resolved later by the class finalizer. Therefore, we know here that if
    // 'type' is not a type parameter (an unresolved type will not get resolved
    // to a type parameter later) and if 'type' has no type arguments, then it
    // will be instantiated at class finalization time. Otherwise, we return
    // false, since the type test would not be possible at finalization time for
    // an uninstantiated type.
    return false;
  }
  if (CurrentToken() == Token::kINTEGER) {
    *value = CurrentIntegerLiteral();
    return true;
  } else if (CurrentToken() == Token::kDOUBLE) {
    *value = CurrentDoubleLiteral();
    return true;
  } else if (CurrentToken() == Token::kSTRING) {
    *value = CurrentLiteral()->raw();
    return true;
  } else if (CurrentToken() == Token::kTRUE) {
    *value = Bool::True().raw();
    return true;
  } else if (CurrentToken() == Token::kFALSE) {
    *value = Bool::False().raw();
    return true;
  }
  return false;
}

// Returns true if the current token is kIDENT or a pseudo-keyword.
bool Parser::IsIdentifier() {
  return Token::IsIdentifier(CurrentToken()) &&
         !(await_is_keyword_ &&
           ((CurrentLiteral()->raw() == Symbols::Await().raw()) ||
            (CurrentLiteral()->raw() == Symbols::Async().raw()) ||
            (CurrentLiteral()->raw() == Symbols::YieldKw().raw())));
}

bool Parser::IsSymbol(const String& symbol) {
  return (CurrentLiteral()->raw() == symbol.raw()) &&
         (CurrentToken() == Token::kIDENT);
}

// Returns true if the current token is 'Function' followed by '<' or '('.
// 'Function' not followed by '<' or '(' denotes the Function class.
bool Parser::IsFunctionTypeSymbol() {
  return IsSymbol(Symbols::Function()) &&
         ((LookaheadToken(1) == Token::kLPAREN) ||
          (LookaheadToken(1) == Token::kLT));
}

// Returns true if the next tokens can be parsed as a an optionally
// qualified identifier: [ident '.'] ident.
// Current token position is not restored.
bool Parser::TryParseQualIdent() {
  if (CurrentToken() != Token::kIDENT) {
    return false;
  }
  ConsumeToken();
  if (CurrentToken() == Token::kPERIOD) {
    ConsumeToken();
    if (CurrentToken() != Token::kIDENT) {
      return false;
    }
    ConsumeToken();
  }
  return true;
}

// Returns true if the next tokens can be parsed as a type with optional
// type parameters. Current token position is not restored.
// Allow 'void' as type if 'allow_void' is true.
// Note that 'void Function()' is always allowed, since it is a function type
// and not the void type.
bool Parser::TryParseType(bool allow_void) {
  bool found = false;
  if (CurrentToken() == Token::kVOID) {
    ConsumeToken();
    if (allow_void) {
      found = true;
    } else if (!IsFunctionTypeSymbol()) {
      return false;
    }
  } else if ((CurrentToken() == Token::kIDENT) && !IsFunctionTypeSymbol()) {
    // 'Function' not followed by '(' or '<' means the Function class.
    if (!TryParseQualIdent()) {
      return false;
    }
    if ((CurrentToken() == Token::kLT) && !TryParseTypeArguments()) {
      return false;
    }
    found = true;
  }
  while (IsFunctionTypeSymbol()) {
    ConsumeToken();
    if ((CurrentToken() == Token::kLT) && !TryParseTypeParameters()) {
      return false;
    }
    if (CurrentToken() == Token::kLPAREN) {
      SkipToMatchingParenthesis();
    } else {
      return false;
    }
    found = true;
  }
  return found;
}

// Look ahead to detect whether the next tokens should be parsed as
// a variable declaration. Ignores optional metadata.
// Returns true if we detect the token pattern:
//     'var'
//   | 'final'
//   | const [type] ident (';' | '=' | ',')
//   | type ident (';' | '=' | ',')
// Token position remains unchanged.
bool Parser::IsVariableDeclaration() {
  if ((CurrentToken() == Token::kVAR) || (CurrentToken() == Token::kFINAL)) {
    return true;
  }
  // Skip optional metadata.
  if (CurrentToken() == Token::kAT) {
    const TokenPosition saved_pos = TokenPos();
    SkipMetadata();
    const bool is_var_decl = IsVariableDeclaration();
    SetPosition(saved_pos);
    return is_var_decl;
  }
  if ((CurrentToken() != Token::kIDENT) && (CurrentToken() != Token::kVOID) &&
      (CurrentToken() != Token::kCONST)) {
    // Not a legal type identifier or void (result type of function type)
    // or const keyword or metadata.
    return false;
  }
  const TokenPosition saved_pos = TokenPos();
  bool is_var_decl = false;
  bool have_type = false;
  if (CurrentToken() == Token::kCONST) {
    ConsumeToken();
    have_type = true;  // Type is dynamic if 'const' is not followed by a type.
  }
  if ((CurrentToken() == Token::kVOID) || IsFunctionTypeSymbol()) {
    if (TryParseType(false)) {
      have_type = true;
    }
  } else if (IsIdentifier()) {  // Type or variable name.
    Token::Kind follower = LookaheadToken(1);
    if ((follower == Token::kLT) ||       // Parameterized type.
        (follower == Token::kPERIOD) ||   // Qualified class name of type.
        Token::IsIdentifier(follower)) {  // Variable name following a type.
      // We see the beginning of something that could be a type.
      const TokenPosition type_pos = TokenPos();
      if (TryParseType(false)) {
        have_type = true;
      } else {
        SetPosition(type_pos);
      }
    }
  }
  if (have_type && IsIdentifier()) {
    ConsumeToken();
    if ((CurrentToken() == Token::kSEMICOLON) ||
        (CurrentToken() == Token::kCOMMA) ||
        (CurrentToken() == Token::kASSIGN)) {
      is_var_decl = true;
    }
  }
  SetPosition(saved_pos);
  return is_var_decl;
}

// Look ahead to see if the following tokens are a return type followed
// by an identifier.
bool Parser::IsFunctionReturnType() {
  TokenPosScope decl_pos(this);
  if (TryParseType(true)) {
    if (IsIdentifier()) {
      // Return type followed by function name.
      return true;
    }
  }
  return false;
}

// Look ahead to detect whether the next tokens should be parsed as
// a function declaration. Token position remains unchanged.
bool Parser::IsFunctionDeclaration() {
  bool is_external = false;
  TokenPosScope decl_pos(this);
  SkipMetadata();
  if ((is_top_level_) && (CurrentToken() == Token::kEXTERNAL)) {
    // Skip over 'external' for top-level function declarations.
    is_external = true;
    ConsumeToken();
  }
  const TokenPosition type_or_name_pos = TokenPos();
  if (TryParseType(true)) {
    if (!IsIdentifier()) {
      SetPosition(type_or_name_pos);
    }
  } else {
    SetPosition(type_or_name_pos);
  }
  // Check for function name followed by optional type parameters.
  if (!IsIdentifier()) {
    return false;
  }
  ConsumeToken();
  if ((CurrentToken() == Token::kLT) && !TryParseTypeParameters()) {
    return false;
  }

  // Optional type, function name and optinal type parameters are parsed.
  if (CurrentToken() != Token::kLPAREN) {
    return false;
  }

  // Check parameter list and the following token.
  SkipToMatchingParenthesis();
  if ((CurrentToken() == Token::kLBRACE) || (CurrentToken() == Token::kARROW) ||
      (is_top_level_ && IsSymbol(Symbols::Native())) || is_external ||
      IsSymbol(Symbols::Async()) || IsSymbol(Symbols::Sync())) {
    return true;
  }
  return false;
}

bool Parser::IsTopLevelAccessor() {
  const TokenPosScope saved_pos(this);
  if (CurrentToken() == Token::kEXTERNAL) {
    ConsumeToken();
  }
  if ((CurrentToken() == Token::kGET) || (CurrentToken() == Token::kSET)) {
    return true;
  }
  if (TryParseType(true)) {
    if ((CurrentToken() == Token::kGET) || (CurrentToken() == Token::kSET)) {
      if (Token::IsIdentifier(LookaheadToken(1))) {  // Accessor name.
        return true;
      }
    }
  }
  return false;
}

bool Parser::IsFunctionLiteral() {
  if (!allow_function_literals_) {
    return false;
  }
  if ((CurrentToken() == Token::kLPAREN) || (CurrentToken() == Token::kLT)) {
    TokenPosScope saved_pos(this);
    if ((CurrentToken() == Token::kLT) && !TryParseTypeParameters()) {
      return false;
    }
    if (CurrentToken() != Token::kLPAREN) {
      return false;
    }
    SkipToMatchingParenthesis();
    ParseFunctionModifier();
    if ((CurrentToken() == Token::kLBRACE) ||
        (CurrentToken() == Token::kARROW)) {
      return true;
    }
  }
  return false;
}

// Current token position is the token after the opening ( of the for
// statement. Returns true if we recognize a for ( .. in expr)
// statement.
bool Parser::IsForInStatement() {
  const TokenPosScope saved_pos(this);
  // Allow const modifier as well when recognizing a for-in statement
  // pattern. We will get an error later if the loop variable is
  // declared with const.
  if (CurrentToken() == Token::kVAR || CurrentToken() == Token::kFINAL ||
      CurrentToken() == Token::kCONST) {
    ConsumeToken();
  }
  if (IsIdentifier()) {
    if (LookaheadToken(1) == Token::kIN) {
      return true;
    } else if (TryParseType(false)) {
      if (IsIdentifier()) {
        ConsumeToken();
      }
      return CurrentToken() == Token::kIN;
    }
  }
  return false;
}

static bool ContainsAbruptCompletingStatement(SequenceNode* seq);

static bool IsAbruptCompleting(AstNode* statement) {
  return statement->IsReturnNode() || statement->IsJumpNode() ||
         statement->IsThrowNode() ||
         (statement->IsSequenceNode() &&
          ContainsAbruptCompletingStatement(statement->AsSequenceNode()));
}

static bool ContainsAbruptCompletingStatement(SequenceNode* seq) {
  for (int i = 0; i < seq->length(); i++) {
    if (IsAbruptCompleting(seq->NodeAt(i))) {
      return true;
    }
  }
  return false;
}

void Parser::ParseStatementSequence() {
  TRACE_PARSER("ParseStatementSequence");
  const bool dead_code_allowed = true;
  bool abrupt_completing_seen = false;
  RecursionChecker rc(this);
  while (CurrentToken() != Token::kRBRACE) {
    const TokenPosition statement_pos = TokenPos();
    AstNode* statement = ParseStatement();
    // Do not add statements with no effect (e.g., LoadLocalNode).
    if ((statement != NULL) && statement->IsLoadLocalNode()) {
      // Skip load local.
      continue;
    }
    if (statement != NULL) {
      if (!dead_code_allowed && abrupt_completing_seen) {
        ReportError(statement_pos,
                    "dead code after abrupt completing statement");
      }
      current_block_->statements->Add(statement);
      abrupt_completing_seen |= IsAbruptCompleting(statement);
    }
  }
}

// Parse nested statement of if, while, for, etc. We automatically generate
// a sequence of one statement if there are no curly braces.
// The argument 'parsing_loop_body' indicates the parsing of a loop statement.
SequenceNode* Parser::ParseNestedStatement(bool parsing_loop_body,
                                           SourceLabel* label) {
  TRACE_PARSER("ParseNestedStatement");
  if (parsing_loop_body) {
    OpenLoopBlock();
  } else {
    OpenBlock();
  }
  if (label != NULL) {
    current_block_->scope->AddLabel(label);
  }
  if (CurrentToken() == Token::kLBRACE) {
    ConsumeToken();
    ParseStatementSequence();
    ExpectToken(Token::kRBRACE);
  } else {
    RecursionChecker rc(this);
    AstNode* statement = ParseStatement();
    if (statement != NULL) {
      current_block_->statements->Add(statement);
    }
  }
  SequenceNode* sequence = CloseBlock();
  return sequence;
}

AstNode* Parser::ParseIfStatement(String* label_name) {
  TRACE_PARSER("ParseIfStatement");
  ASSERT(CurrentToken() == Token::kIF);
  const TokenPosition if_pos = TokenPos();
  SourceLabel* label = NULL;
  if (label_name != NULL) {
    label = SourceLabel::New(if_pos, label_name, SourceLabel::kStatement);
    OpenBlock();
    current_block_->scope->AddLabel(label);
  }
  ConsumeToken();
  ExpectToken(Token::kLPAREN);
  AstNode* cond_expr = ParseAwaitableExpr(kAllowConst, kConsumeCascades, NULL);
  ExpectToken(Token::kRPAREN);
  const bool parsing_loop_body = false;
  SequenceNode* true_branch = ParseNestedStatement(parsing_loop_body, NULL);
  SequenceNode* false_branch = NULL;
  if (CurrentToken() == Token::kELSE) {
    ConsumeToken();
    false_branch = ParseNestedStatement(parsing_loop_body, NULL);
  }
  AstNode* if_node =
      new (Z) IfNode(if_pos, cond_expr, true_branch, false_branch);
  if (label != NULL) {
    current_block_->statements->Add(if_node);
    SequenceNode* sequence = CloseBlock();
    sequence->set_label(label);
    if_node = sequence;
  }
  return if_node;
}

// Return true if the type class of the given value implements the
// == operator.
static bool ImplementsEqualOperator(Zone* zone, const Instance& value) {
  Class& cls = Class::Handle(value.clazz());
  const Function& equal_op = Function::Handle(
      zone,
      Resolver::ResolveDynamicAnyArgs(zone, cls, Symbols::EqualOperator()));
  ASSERT(!equal_op.IsNull());
  cls = equal_op.Owner();
  return !cls.IsObjectClass();
}

// Check that all case expressions are of the same type, either int, String,
// or any other class that does not override the == operator.
// The expressions are compile-time constants and are thus in the form
// of a LiteralNode.
RawClass* Parser::CheckCaseExpressions(
    const GrowableArray<LiteralNode*>& values) {
  const intptr_t num_expressions = values.length();
  if (num_expressions == 0) {
    return Object::dynamic_class();
  }
  const Instance& first_value = values[0]->literal();
  for (intptr_t i = 0; i < num_expressions; i++) {
    const Instance& val = values[i]->literal();
    const TokenPosition val_pos = values[i]->token_pos();
    if (first_value.IsInteger()) {
      if (!val.IsInteger()) {
        ReportError(val_pos, "expected case expression of type int");
      }
      continue;
    }
    if (first_value.IsString()) {
      if (!val.IsString()) {
        ReportError(val_pos, "expected case expression of type String");
      }
      continue;
    }
    if (val.IsDouble()) {
      ReportError(val_pos, "case expression may not be of type double");
    }
    if (val.clazz() != first_value.clazz()) {
      ReportError(val_pos, "all case expressions must be of same type");
    }
    if (val.clazz() == I->object_store()->symbol_class()) {
      continue;
    }
    if (i == 0) {
      // The value is of some type other than int, String or double.
      // Check that the type class does not override the == operator.
      // Check this only in the first loop iteration since all values
      // are of the same type, which we check above.
      if (ImplementsEqualOperator(Z, val)) {
        ReportError(val_pos,
                    "type class of case expression must not "
                    "implement operator ==");
      }
    }
  }
  if (first_value.IsInteger()) {
    return Type::Handle(Z, Type::IntType()).type_class();
  } else if (first_value.IsString()) {
    return Type::Handle(Z, Type::StringType()).type_class();
  }
  return first_value.clazz();
}

CaseNode* Parser::ParseCaseClause(LocalVariable* switch_expr_value,
                                  GrowableArray<LiteralNode*>* case_expr_values,
                                  SourceLabel* case_label) {
  TRACE_PARSER("ParseCaseClause");
  bool default_seen = false;
  const TokenPosition case_pos = TokenPos();
  // The case expressions node sequence does not own the enclosing scope.
  SequenceNode* case_expressions = new (Z) SequenceNode(case_pos, NULL);
  while (CurrentToken() == Token::kCASE || CurrentToken() == Token::kDEFAULT) {
    if (CurrentToken() == Token::kCASE) {
      if (default_seen) {
        ReportError("default clause must be last case");
      }
      ConsumeToken();  // Keyword case.
      const TokenPosition expr_pos = TokenPos();
      AstNode* expr = ParseExpr(kRequireConst, kConsumeCascades);
      ASSERT(expr->IsLiteralNode());
      case_expr_values->Add(expr->AsLiteralNode());

      AstNode* switch_expr_load =
          new (Z) LoadLocalNode(case_pos, switch_expr_value);
      AstNode* case_comparison =
          new (Z) ComparisonNode(expr_pos, Token::kEQ, expr, switch_expr_load);
      case_expressions->Add(case_comparison);
    } else {
      if (default_seen) {
        ReportError("only one default clause is allowed");
      }
      ConsumeToken();  // Keyword default.
      default_seen = true;
      // The default case always succeeds.
    }
    ExpectToken(Token::kCOLON);
  }

  OpenBlock();
  bool abrupt_completing_seen = false;
  while (true) {
    // Check whether the next statement still belongs to the current case
    // clause. If we see 'case' or 'default', optionally preceeded by
    // a label, or closing brace, we stop parsing statements.
    Token::Kind next_token;
    if (IsIdentifier() && LookaheadToken(1) == Token::kCOLON) {
      next_token = LookaheadToken(2);
    } else {
      next_token = CurrentToken();
    }
    if (next_token == Token::kRBRACE) {
      // End of switch statement.
      break;
    }
    if ((next_token == Token::kCASE) || (next_token == Token::kDEFAULT)) {
      // End of this case clause. If there is a possible fall-through to
      // the next case clause, throw an implicit FallThroughError.
      if (!abrupt_completing_seen) {
        ArgumentListNode* arguments = new (Z) ArgumentListNode(TokenPos());
        arguments->Add(new (Z) LiteralNode(
            TokenPos(), Integer::ZoneHandle(
                            Z, Integer::New(TokenPos().value(), Heap::kOld))));
        current_block_->statements->Add(MakeStaticCall(
            Symbols::FallThroughError(),
            Library::PrivateCoreLibName(Symbols::ThrowNew()), arguments));
      }
      break;
    }
    // The next statement still belongs to this case.
    AstNode* statement = ParseStatement();
    if (statement != NULL) {
      current_block_->statements->Add(statement);
      abrupt_completing_seen |= IsAbruptCompleting(statement);
    }
  }
  SequenceNode* statements = CloseBlock();
  return new (Z) CaseNode(case_pos, case_label, case_expressions, default_seen,
                          switch_expr_value, statements);
}

AstNode* Parser::ParseSwitchStatement(String* label_name) {
  TRACE_PARSER("ParseSwitchStatement");
  ASSERT(CurrentToken() == Token::kSWITCH);
  const TokenPosition switch_pos = TokenPos();
  SourceLabel* label =
      SourceLabel::New(switch_pos, label_name, SourceLabel::kSwitch);
  ConsumeToken();
  ExpectToken(Token::kLPAREN);
  const TokenPosition expr_pos = TokenPos();
  AstNode* switch_expr =
      ParseAwaitableExpr(kAllowConst, kConsumeCascades, NULL);
  ExpectToken(Token::kRPAREN);
  ExpectToken(Token::kLBRACE);
  OpenBlock();
  current_block_->scope->AddLabel(label);

  // Store switch expression in temporary local variable. The type of the
  // variable is set to dynamic. It will later be patched to match the
  // type of the case clause expressions. Therefore, we have to allocate
  // a new type representing dynamic and can't reuse the canonical
  // type object for dynamic.
  const Type& temp_var_type =
      Type::ZoneHandle(Z, Type::New(Class::Handle(Z, Object::dynamic_class()),
                                    TypeArguments::Handle(Z), expr_pos));
  temp_var_type.SetIsFinalized();
  LocalVariable* temp_variable = new (Z)
      LocalVariable(expr_pos, expr_pos, Symbols::SwitchExpr(), temp_var_type);
  current_block_->scope->AddVariable(temp_variable);
  AstNode* save_switch_expr =
      new (Z) StoreLocalNode(expr_pos, temp_variable, switch_expr);
  current_block_->statements->Add(save_switch_expr);

  // Parse case clauses
  bool default_seen = false;
  GrowableArray<LiteralNode*> case_expr_values;
  while (true) {
    // Check for statement label
    SourceLabel* case_label = NULL;
    if (IsIdentifier() && LookaheadToken(1) == Token::kCOLON) {
      // Case statements start with a label.
      String* label_name = CurrentLiteral();
      const TokenPosition label_pos = TokenPos();
      ConsumeToken();  // Consume label identifier.
      ConsumeToken();  // Consume colon.
      case_label = current_block_->scope->LocalLookupLabel(*label_name);
      if (case_label == NULL) {
        // Label does not exist yet. Add it to scope of switch statement.
        case_label =
            new (Z) SourceLabel(label_pos, *label_name, SourceLabel::kCase);
        current_block_->scope->AddLabel(case_label);
      } else if (case_label->kind() == SourceLabel::kForward) {
        // We have seen a 'continue' with this label name. Resolve
        // the forward reference.
        case_label->ResolveForwardReference();
        RemoveNodesForFinallyInlining(case_label);
      } else {
        ReportError(label_pos, "label '%s' already exists in scope",
                    label_name->ToCString());
      }
      ASSERT(case_label->kind() == SourceLabel::kCase);
    }
    if (CurrentToken() == Token::kCASE || CurrentToken() == Token::kDEFAULT) {
      if (default_seen) {
        ReportError("no case clauses allowed after default clause");
      }
      CaseNode* case_clause =
          ParseCaseClause(temp_variable, &case_expr_values, case_label);
      default_seen = case_clause->contains_default();
      current_block_->statements->Add(case_clause);
    } else if (CurrentToken() != Token::kRBRACE) {
      ReportError("'case' or '}' expected");
    } else if (case_label != NULL) {
      ReportError("expecting at least one case clause after label");
    } else {
      break;
    }
  }

  // Check that all expressions in case clauses are of the same class,
  // or implement int, double or String. Patch the type of the temporary
  // variable holding the switch expression to match the type of the
  // case clause constants.
  temp_var_type.set_type_class(
      Class::Handle(Z, CheckCaseExpressions(case_expr_values)));

  // Check for unresolved label references.
  SourceLabel* unresolved_label =
      current_block_->scope->CheckUnresolvedLabels();
  if (unresolved_label != NULL) {
    ReportError("unresolved reference to label '%s'",
                unresolved_label->name().ToCString());
  }

  SequenceNode* switch_body = CloseBlock();
  ExpectToken(Token::kRBRACE);
  return new (Z) SwitchNode(switch_pos, label, switch_body);
}

AstNode* Parser::ParseWhileStatement(String* label_name) {
  TRACE_PARSER("ParseWhileStatement");
  const TokenPosition while_pos = TokenPos();
  SourceLabel* label =
      SourceLabel::New(while_pos, label_name, SourceLabel::kWhile);
  ConsumeToken();
  ExpectToken(Token::kLPAREN);
  SequenceNode* await_preamble = NULL;
  AstNode* cond_expr =
      ParseAwaitableExpr(kAllowConst, kConsumeCascades, &await_preamble);
  ExpectToken(Token::kRPAREN);
  const bool parsing_loop_body = true;
  SequenceNode* while_body = ParseNestedStatement(parsing_loop_body, label);
  WhileNode* while_node = new (Z)
      WhileNode(while_pos, label, cond_expr, await_preamble, while_body);
  return while_node;
}

AstNode* Parser::ParseDoWhileStatement(String* label_name) {
  TRACE_PARSER("ParseDoWhileStatement");
  const TokenPosition do_pos = TokenPos();
  SourceLabel* label =
      SourceLabel::New(do_pos, label_name, SourceLabel::kDoWhile);
  ConsumeToken();
  const bool parsing_loop_body = true;
  SequenceNode* dowhile_body = ParseNestedStatement(parsing_loop_body, label);
  ExpectToken(Token::kWHILE);
  ExpectToken(Token::kLPAREN);
  SequenceNode* await_preamble = NULL;
  TokenPosition expr_pos = TokenPos();
  AstNode* cond_expr =
      ParseAwaitableExpr(kAllowConst, kConsumeCascades, &await_preamble);
  if (await_preamble != NULL) {
    // Prepend the preamble to the condition.
    LetNode* await_cond = new (Z) LetNode(expr_pos);
    await_cond->AddNode(await_preamble);
    await_cond->AddNode(cond_expr);
    cond_expr = await_cond;
  }
  ExpectToken(Token::kRPAREN);
  ExpectSemicolon();
  return new (Z) DoWhileNode(do_pos, label, cond_expr, dowhile_body);
}

static LocalVariable* LookupSavedTryContextVar(LocalScope* scope) {
  LocalVariable* var =
      scope->LocalLookupVariable(Symbols::SavedTryContextVar());
  ASSERT((var != NULL) && !var->is_captured());
  return var;
}

static LocalVariable* LookupAsyncSavedTryContextVar(Thread* thread,
                                                    LocalScope* scope,
                                                    uint16_t try_index) {
  Zone* zone = thread->zone();
  const String& async_saved_try_ctx_name = String::ZoneHandle(
      zone, Symbols::NewFormatted(
                thread, "%s%d",
                Symbols::AsyncSavedTryCtxVarPrefix().ToCString(), try_index));
  LocalVariable* var = scope->LocalLookupVariable(async_saved_try_ctx_name);
  ASSERT(var != NULL);
  return var;
}

// If the await or yield being parsed is in a try block, the continuation code
// needs to restore the corresponding stack-based variable :saved_try_ctx_var,
// and the stack-based variable :saved_try_ctx_var of the outer try block.
// The inner :saved_try_ctx_var is used by a finally clause handling an
// exception thrown by the continuation code in a try block or catch block.
// If no finally clause exists, the catch or finally clause of the outer try
// block, if any, uses the outer :saved_try_ctx_var to handle the exception.
//
// * Try blocks and catch blocks:
//     Set the context variable for this try block and for the outer try block.
// * Finally blocks:
//     Set the context variable for the outer try block. Note that the try
//     declaring the finally is popped before parsing the finally clause, so the
//     outer try block is at the top of the try block list.
void Parser::CheckAsyncOpInTryBlock(
    LocalVariable** saved_try_ctx,
    LocalVariable** async_saved_try_ctx,
    LocalVariable** outer_saved_try_ctx,
    LocalVariable** outer_async_saved_try_ctx) const {
  *saved_try_ctx = NULL;
  *async_saved_try_ctx = NULL;
  *outer_saved_try_ctx = NULL;
  *outer_async_saved_try_ctx = NULL;
  if (try_stack_ != NULL) {
    LocalScope* scope = try_stack_->try_block()->scope;
    uint16_t try_index = try_stack_->try_index();
    const int current_function_level = FunctionLevel();
    if (scope->function_level() == current_function_level) {
      // The block declaring :saved_try_ctx_var variable is the parent of the
      // pushed try block.
      *saved_try_ctx = LookupSavedTryContextVar(scope->parent());
      *async_saved_try_ctx =
          LookupAsyncSavedTryContextVar(T, async_temp_scope_, try_index);
      if ((try_stack_->outer_try() != NULL) && !try_stack_->inside_finally()) {
        // Collecting the outer try scope is not necessary if we
        // are in a finally block.
        scope = try_stack_->outer_try()->try_block()->scope;
        try_index = try_stack_->outer_try()->try_index();
        if (scope->function_level() == current_function_level) {
          *outer_saved_try_ctx = LookupSavedTryContextVar(scope->parent());
          *outer_async_saved_try_ctx =
              LookupAsyncSavedTryContextVar(T, async_temp_scope_, try_index);
        }
      }
    }
  }
  // An async or async* has an implicitly created try-catch around the
  // function body, so the await or yield inside the async closure should always
  // be created with a try scope.
  ASSERT((*saved_try_ctx != NULL) || innermost_function().IsAsyncFunction() ||
         innermost_function().IsAsyncGenerator() ||
         innermost_function().IsSyncGenClosure() ||
         innermost_function().IsSyncGenerator());
}

// Build an AST node for static call to Dart function print(str).
// Used during debugging to insert print in generated dart code.
AstNode* Parser::DartPrint(const char* str) {
  const Library& lib = Library::Handle(Library::CoreLibrary());
  const Function& print_fn =
      Function::ZoneHandle(Z, lib.LookupFunctionAllowPrivate(Symbols::print()));
  ASSERT(!print_fn.IsNull());
  ArgumentListNode* one_arg =
      new (Z) ArgumentListNode(TokenPosition::kNoSource);
  String& msg = String::ZoneHandle(Symbols::NewFormatted(T, "%s", str));
  one_arg->Add(new (Z) LiteralNode(TokenPosition::kNoSource, msg));
  AstNode* print_call = new (Z) StaticCallNode(
      TokenPosition::kNoSource, print_fn, one_arg, StaticCallNode::kStatic);
  return print_call;
}

AstNode* Parser::ParseAwaitForStatement(String* label_name) {
  TRACE_PARSER("ParseAwaitForStatement");
  ASSERT(IsAwaitKeyword());
  const TokenPosition await_for_pos = TokenPos();
  ConsumeToken();  // await.
  ASSERT(CurrentToken() == Token::kFOR);
  ConsumeToken();  // for.
  ExpectToken(Token::kLPAREN);

  if (!innermost_function().IsAsyncFunction() &&
      !innermost_function().IsAsyncClosure() &&
      !innermost_function().IsAsyncGenerator() &&
      !innermost_function().IsAsyncGenClosure()) {
    ReportError(await_for_pos,
                "await for loop is only allowed in an asynchronous function");
  }

  // Parse loop variable.
  bool loop_var_is_final = (CurrentToken() == Token::kFINAL);
  if (CurrentToken() == Token::kCONST) {
    ReportError("Loop variable cannot be 'const'");
  }
  bool new_loop_var = false;
  AbstractType& loop_var_type = AbstractType::ZoneHandle(Z);
  if (LookaheadToken(1) != Token::kIN) {
    // Declaration of a new loop variable.
    // Delay creation of the local variable until we know its actual
    // position, which is inside the loop body.
    new_loop_var = true;
    loop_var_type = ParseConstFinalVarOrType(I->type_checks()
                                                 ? ClassFinalizer::kCanonicalize
                                                 : ClassFinalizer::kIgnore);
  }
  TokenPosition loop_var_pos = TokenPos();
  const String* loop_var_name = ExpectIdentifier("variable name expected");

  // Parse stream expression.
  ExpectToken(Token::kIN);

  // Open a block for the iterator variable and the try-finally statement
  // that contains the loop. Ensure that the block starts at a different
  // token position than the following loop block. Both blocks can allocate
  // contexts and if they have a matching token position range,
  // it can be an issue (cf. bug 26941).
  OpenBlock();
  const Block* await_for_block = current_block_;

  const TokenPosition stream_expr_pos = TokenPos();
  AstNode* stream_expr =
      ParseAwaitableExpr(kAllowConst, kConsumeCascades, NULL);
  ExpectToken(Token::kRPAREN);

  // Create :stream to store the stream into temporarily.
  LocalVariable* stream_var =
      new (Z) LocalVariable(stream_expr_pos, stream_expr_pos,
                            Symbols::ColonStream(), Object::dynamic_type());
  current_block_->scope->AddVariable(stream_var);

  // Store the stream expression into a variable.
  StoreLocalNode* store_stream_var =
      new (Z) StoreLocalNode(stream_expr_pos, stream_var, stream_expr);
  current_block_->statements->Add(store_stream_var);

  // Register the awaiter on the stream by invoking `_asyncStarListenHelper`.
  const Library& async_lib = Library::Handle(Library::AsyncLibrary());
  const Function& async_star_listen_helper = Function::ZoneHandle(
      Z,
      async_lib.LookupFunctionAllowPrivate(Symbols::_AsyncStarListenHelper()));
  ASSERT(!async_star_listen_helper.IsNull());
  LocalVariable* async_op_var =
      current_block_->scope->LookupVariable(Symbols::AsyncOperation(), false);
  ASSERT(async_op_var != NULL);
  ArgumentListNode* async_star_listen_helper_args =
      new (Z) ArgumentListNode(stream_expr_pos);
  async_star_listen_helper_args->Add(
      new (Z) LoadLocalNode(stream_expr_pos, stream_var));
  async_star_listen_helper_args->Add(
      new (Z) LoadLocalNode(stream_expr_pos, async_op_var));
  StaticCallNode* async_star_listen_helper_call = new (Z)
      StaticCallNode(stream_expr_pos, async_star_listen_helper,
                     async_star_listen_helper_args, StaticCallNode::kStatic);

  current_block_->statements->Add(async_star_listen_helper_call);

  // Build creation of implicit StreamIterator.
  // var :for-in-iter = new StreamIterator(stream_expr).
  const Class& stream_iterator_cls =
      Class::ZoneHandle(Z, I->object_store()->stream_iterator_class());
  ASSERT(!stream_iterator_cls.IsNull());
  const Function& iterator_ctor = Function::ZoneHandle(
      Z,
      stream_iterator_cls.LookupFunction(Symbols::StreamIteratorConstructor()));
  ASSERT(!iterator_ctor.IsNull());
  ArgumentListNode* ctor_args = new (Z) ArgumentListNode(stream_expr_pos);
  ctor_args->Add(new (Z) LoadLocalNode(stream_expr_pos, stream_var));
  ConstructorCallNode* ctor_call = new (Z) ConstructorCallNode(
      stream_expr_pos, TypeArguments::ZoneHandle(Z), iterator_ctor, ctor_args);
  const AbstractType& iterator_type = Object::dynamic_type();
  LocalVariable* iterator_var = new (Z) LocalVariable(
      stream_expr_pos, stream_expr_pos, Symbols::ForInIter(), iterator_type);
  current_block_->scope->AddVariable(iterator_var);
  AstNode* iterator_init =
      new (Z) StoreLocalNode(stream_expr_pos, iterator_var, ctor_call);
  current_block_->statements->Add(iterator_init);

  // We need to ensure that the stream is cancelled after the loop.
  // Thus, wrap the loop in a try-finally that calls :for-in-iter.close()
  // in the finally clause. It is harmless to call close() if the stream
  // is already cancelled (when moveNext() returns false).
  // Note: even though this is async code, we do not need to set up
  // the closurized saved_exception_var and saved_stack_trace_var because
  // there can not be a suspend/resume event before the exception is
  // rethrown in the catch clause. The catch block of the implicit
  // try-finally is empty.
  LocalVariable* context_var = NULL;
  LocalVariable* exception_var = NULL;
  LocalVariable* stack_trace_var = NULL;
  LocalVariable* saved_exception_var = NULL;
  LocalVariable* saved_stack_trace_var = NULL;
  SetupExceptionVariables(current_block_->scope,
                          false,  // Do not create the saved_ vars.
                          &context_var, &exception_var, &stack_trace_var,
                          &saved_exception_var, &saved_stack_trace_var);
  OpenBlock();  // try block.
  PushTry(current_block_);
  SetupSavedTryContext(context_var);

  // Build while loop condition.
  // while (await :for-in-iter.moveNext())
  LocalVariable* saved_try_ctx;
  LocalVariable* async_saved_try_ctx;
  LocalVariable* outer_saved_try_ctx;
  LocalVariable* outer_async_saved_try_ctx;
  CheckAsyncOpInTryBlock(&saved_try_ctx, &async_saved_try_ctx,
                         &outer_saved_try_ctx, &outer_async_saved_try_ctx);
  ArgumentListNode* no_args = new (Z) ArgumentListNode(stream_expr_pos);
  AstNode* iterator_moveNext = new (Z) InstanceCallNode(
      stream_expr_pos, new (Z) LoadLocalNode(stream_expr_pos, iterator_var),
      Symbols::MoveNext(), no_args);
  OpenBlock();
#if !defined(PRODUCT)
  // Call '_asyncStarMoveNextHelper' so that the debugger can intercept and
  // handle single stepping into a async* generator.
  const Function& async_star_move_next_helper = Function::ZoneHandle(
      Z, isolate()->object_store()->async_star_move_next_helper());
  ASSERT(!async_star_move_next_helper.IsNull());
  ArgumentListNode* async_star_move_next_helper_args =
      new (Z) ArgumentListNode(stream_expr_pos);
  async_star_move_next_helper_args->Add(
      new (Z) LoadLocalNode(stream_expr_pos, stream_var));
  StaticCallNode* async_star_move_next_helper_call = new (Z)
      StaticCallNode(stream_expr_pos, async_star_move_next_helper,
                     async_star_move_next_helper_args, StaticCallNode::kStatic);
  current_block_->statements->Add(async_star_move_next_helper_call);
#endif
  AstNode* await_moveNext = new (Z) AwaitNode(
      stream_expr_pos, iterator_moveNext, saved_try_ctx, async_saved_try_ctx,
      outer_saved_try_ctx, outer_async_saved_try_ctx, current_block_->scope);
  AwaitTransformer at(current_block_->statements, async_temp_scope_);
  await_moveNext = at.Transform(await_moveNext);
  SequenceNode* await_preamble = CloseBlock();

  // Parse the for loop body. Ideally, we would use ParseNestedStatement()
  // here, but that does not work well because we have to insert an implicit
  // variable assignment and potentially a variable declaration in the
  // loop body.
  OpenLoopBlock();

  SourceLabel* label =
      SourceLabel::New(await_for_pos, label_name, SourceLabel::kFor);
  current_block_->scope->AddLabel(label);
  const TokenPosition loop_var_assignment_pos = TokenPos();

  AstNode* iterator_current = new (Z) InstanceGetterNode(
      loop_var_assignment_pos,
      new (Z) LoadLocalNode(loop_var_assignment_pos, iterator_var),
      Symbols::Current());

  // Generate assignment of next iterator value to loop variable.
  AstNode* loop_var_assignment = NULL;
  if (new_loop_var) {
    // The for loop variable is new for each iteration.
    // Create a variable and add it to the loop body scope.
    // Note that the variable token position needs to be inside the
    // loop block, so it gets put in the loop context level.
    LocalVariable* loop_var =
        new (Z) LocalVariable(loop_var_assignment_pos, loop_var_assignment_pos,
                              *loop_var_name, loop_var_type);
    if (loop_var_is_final) {
      loop_var->set_is_final();
    }
    current_block_->scope->AddVariable(loop_var);
    loop_var_assignment = new (Z)
        StoreLocalNode(loop_var_assignment_pos, loop_var, iterator_current);
  } else {
    AstNode* loop_var_primary =
        ResolveIdent(loop_var_pos, *loop_var_name, false);
    ASSERT(!loop_var_primary->IsPrimaryNode());
    loop_var_assignment =
        CreateAssignmentNode(loop_var_primary, iterator_current, loop_var_name,
                             loop_var_assignment_pos);
    ASSERT(loop_var_assignment != NULL);
  }
  current_block_->statements->Add(loop_var_assignment);

  // Now parse the for-in loop statement or block.
  if (CurrentToken() == Token::kLBRACE) {
    ConsumeToken();
    ParseStatementSequence();
    ExpectToken(Token::kRBRACE);
  } else {
    AstNode* statement = ParseStatement();
    if (statement != NULL) {
      current_block_->statements->Add(statement);
    }
  }
  SequenceNode* for_loop_block = CloseBlock();

  WhileNode* while_node = new (Z) WhileNode(
      await_for_pos, label, await_moveNext, await_preamble, for_loop_block);
  // Add the while loop to the try block.
  current_block_->statements->Add(while_node);
  SequenceNode* try_block = CloseBlock();

  // Create an empty "catch all" block that rethrows the current
  // exception and stacktrace.
  try_stack_->enter_catch();
  SequenceNode* catch_block = new (Z) SequenceNode(await_for_pos, NULL);

  if (outer_saved_try_ctx != NULL) {
    catch_block->Add(new (Z) StoreLocalNode(
        TokenPosition::kNoSource, outer_saved_try_ctx,
        new (Z) LoadLocalNode(TokenPosition::kNoSource,
                              outer_async_saved_try_ctx)));
  }

  // We don't need to copy the current exception and stack trace variables
  // into :saved_exception_var and :saved_stack_trace_var here because there
  // is no code in the catch clause that could suspend the function.

  // Rethrow the exception.
  catch_block->Add(new (Z) ThrowNode(
      await_for_pos, new (Z) LoadLocalNode(await_for_pos, exception_var),
      new (Z) LoadLocalNode(await_for_pos, stack_trace_var)));

  TryStack* try_statement = PopTry();
  const intptr_t try_index = try_statement->try_index();
  TryStack* outer_try = try_stack_;
  const intptr_t outer_try_index = (outer_try != NULL)
                                       ? outer_try->try_index()
                                       : CatchClauseNode::kInvalidTryIndex;

  // The finally block contains a call to cancel the stream.
  // :for-in-iter.cancel();

  // Inline the finally block to the exit points in the try block.
  intptr_t node_index = 0;
  SequenceNode* finally_clause = NULL;
  if (try_stack_ != NULL) {
    try_stack_->enter_finally();
  }
  do {
    OpenBlock();

    // Restore the saved try context of the enclosing try block if one
    // exists.
    if (outer_saved_try_ctx != NULL) {
      current_block_->statements->Add(new (Z) StoreLocalNode(
          TokenPosition::kNoSource, outer_saved_try_ctx,
          new (Z) LoadLocalNode(TokenPosition::kNoSource,
                                outer_async_saved_try_ctx)));
    }
    // :for-in-iter.cancel();
    ArgumentListNode* no_args =
        new (Z) ArgumentListNode(TokenPosition::kNoSource);
    current_block_->statements->Add(new (Z) InstanceCallNode(
        ST(await_for_pos),
        new (Z) LoadLocalNode(TokenPosition::kNoSource, iterator_var),
        Symbols::Cancel(), no_args));
    finally_clause = CloseBlock();

    AstNode* node_to_inline = try_statement->GetNodeToInlineFinally(node_index);
    if (node_to_inline != NULL) {
      InlinedFinallyNode* node =
          new (Z) InlinedFinallyNode(TokenPosition::kNoSource, finally_clause,
                                     context_var, outer_try_index);
      finally_clause = NULL;
      AddFinallyClauseToNode(true, node_to_inline, node);
      node_index++;
    }
  } while (finally_clause == NULL);

  if (try_stack_ != NULL) {
    try_stack_->exit_finally();
  }

  // Create the try-statement and add to the current sequence, which is
  // the block around the loop statement.

  const Array& handler_types = Array::ZoneHandle(Z, Array::New(1, Heap::kOld));
  // Catch block handles all exceptions.
  handler_types.SetAt(0, Object::dynamic_type());

  CatchClauseNode* catch_clause = new (Z) CatchClauseNode(
      await_for_pos, catch_block, handler_types, context_var, exception_var,
      stack_trace_var, exception_var, stack_trace_var, AllocateTryIndex(),
      true);  // Needs stack trace.

  AstNode* try_catch_node =
      new (Z) TryCatchNode(await_for_pos, try_block, context_var, catch_clause,
                           finally_clause, try_index, finally_clause);

  ASSERT(current_block_ == await_for_block);
  await_for_block->statements->Add(try_catch_node);

  return CloseBlock();  // Implicit block around while loop.
}

AstNode* Parser::ParseForInStatement(TokenPosition forin_pos,
                                     SourceLabel* label) {
  TRACE_PARSER("ParseForInStatement");
  bool loop_var_is_final = (CurrentToken() == Token::kFINAL);
  if (CurrentToken() == Token::kCONST) {
    ReportError("Loop variable cannot be 'const'");
  }
  const String* loop_var_name = NULL;
  TokenPosition loop_var_pos = TokenPosition::kNoSource;
  bool new_loop_var = false;
  AbstractType& loop_var_type = AbstractType::ZoneHandle(Z);
  if (LookaheadToken(1) == Token::kIN) {
    loop_var_pos = TokenPos();
    loop_var_name = ExpectIdentifier("variable name expected");
  } else {
    // The case without a type is handled above, so require a type here.
    // Delay creation of the local variable until we know its actual
    // position, which is inside the loop body.
    new_loop_var = true;
    loop_var_type = ParseConstFinalVarOrType(I->type_checks()
                                                 ? ClassFinalizer::kCanonicalize
                                                 : ClassFinalizer::kIgnore);
    loop_var_pos = TokenPos();
    loop_var_name = ExpectIdentifier("variable name expected");
  }
  ExpectToken(Token::kIN);

  // Ensure that the block token range contains the call to moveNext and it
  // also starts the block at a different token position than the following
  // loop block. Both blocks can allocate contexts and if they have a matching
  // token position range, it can be an issue (cf. bug 26941).
  OpenBlock();  // Implicit block around while loop.

  const TokenPosition collection_pos = TokenPos();
  AstNode* collection_expr =
      ParseAwaitableExpr(kAllowConst, kConsumeCascades, NULL);
  ExpectToken(Token::kRPAREN);

  // Generate implicit iterator variable and add to scope.
  // We could set the type of the implicit iterator variable to Iterator<T>
  // where T is the type of the for loop variable. However, the type error
  // would refer to the compiler generated iterator and could confuse the user.
  // It is better to leave the iterator untyped and postpone the type error
  // until the loop variable is assigned to.
  const AbstractType& iterator_type = Object::dynamic_type();
  LocalVariable* iterator_var = new (Z) LocalVariable(
      collection_pos, collection_pos, Symbols::ForInIter(), iterator_type);
  current_block_->scope->AddVariable(iterator_var);

  // Generate initialization of iterator variable.
  ArgumentListNode* no_args = new (Z) ArgumentListNode(collection_pos);
  AstNode* get_iterator = new (Z)
      InstanceGetterNode(collection_pos, collection_expr, Symbols::Iterator());
  AstNode* iterator_init =
      new (Z) StoreLocalNode(collection_pos, iterator_var, get_iterator);
  current_block_->statements->Add(iterator_init);

  // Generate while loop condition.
  AstNode* iterator_moveNext = new (Z) InstanceCallNode(
      collection_pos, new (Z) LoadLocalNode(collection_pos, iterator_var),
      Symbols::MoveNext(), no_args);

  // Parse the for loop body. Ideally, we would use ParseNestedStatement()
  // here, but that does not work well because we have to insert an implicit
  // variable assignment and potentially a variable declaration in the
  // loop body.
  OpenLoopBlock();
  current_block_->scope->AddLabel(label);
  const TokenPosition loop_var_assignment_pos = TokenPos();

  AstNode* iterator_current = new (Z) InstanceGetterNode(
      loop_var_assignment_pos,
      new (Z) LoadLocalNode(loop_var_assignment_pos, iterator_var),
      Symbols::Current());

  // Generate assignment of next iterator value to loop variable.
  AstNode* loop_var_assignment = NULL;
  if (new_loop_var) {
    // The for loop variable is new for each iteration.
    // Create a variable and add it to the loop body scope.
    LocalVariable* loop_var = new (Z) LocalVariable(
        loop_var_pos, loop_var_assignment_pos, *loop_var_name, loop_var_type);
    if (loop_var_is_final) {
      loop_var->set_is_final();
    }
    current_block_->scope->AddVariable(loop_var);
    loop_var_assignment = new (Z)
        StoreLocalNode(loop_var_assignment_pos, loop_var, iterator_current);
  } else {
    AstNode* loop_var_primary =
        ResolveIdent(loop_var_pos, *loop_var_name, false);
    ASSERT(!loop_var_primary->IsPrimaryNode());
    loop_var_assignment =
        CreateAssignmentNode(loop_var_primary, iterator_current, loop_var_name,
                             loop_var_assignment_pos);
    ASSERT(loop_var_assignment != NULL);
  }
  current_block_->statements->Add(loop_var_assignment);

  // Now parse the for-in loop statement or block.
  if (CurrentToken() == Token::kLBRACE) {
    ConsumeToken();
    ParseStatementSequence();
    ExpectToken(Token::kRBRACE);
  } else {
    AstNode* statement = ParseStatement();
    if (statement != NULL) {
      current_block_->statements->Add(statement);
    }
  }

  SequenceNode* for_loop_statement = CloseBlock();

  AstNode* while_statement = new (Z)
      WhileNode(forin_pos, label, iterator_moveNext, NULL, for_loop_statement);
  current_block_->statements->Add(while_statement);

  return CloseBlock();  // Implicit block around while loop.
}

AstNode* Parser::ParseForStatement(String* label_name) {
  TRACE_PARSER("ParseForStatement");
  const TokenPosition for_pos = TokenPos();
  ConsumeToken();
  ExpectToken(Token::kLPAREN);
  SourceLabel* label = SourceLabel::New(for_pos, label_name, SourceLabel::kFor);
  if (IsForInStatement()) {
    return ParseForInStatement(for_pos, label);
  }
  // Open a block that contains the loop variable. Make it a loop block so
  // that we allocate a new context if the loop variable is captured.
  OpenLoopBlock();
  AstNode* initializer = NULL;
  const TokenPosition init_pos = TokenPos();
  LocalScope* init_scope = current_block_->scope;
  if (CurrentToken() != Token::kSEMICOLON) {
    if (IsVariableDeclaration()) {
      initializer = ParseVariableDeclarationList();
    } else {
      initializer = ParseAwaitableExpr(kAllowConst, kConsumeCascades, NULL);
    }
  }
  ExpectSemicolon();
  AstNode* condition = NULL;
  SequenceNode* condition_preamble = NULL;
  if (CurrentToken() != Token::kSEMICOLON) {
    condition =
        ParseAwaitableExpr(kAllowConst, kConsumeCascades, &condition_preamble);
  }
  ExpectSemicolon();
  AstNode* increment = NULL;
  const TokenPosition incr_pos = TokenPos();
  if (CurrentToken() != Token::kRPAREN) {
    increment = ParseAwaitableExprList();
  }
  ExpectToken(Token::kRPAREN);
  const bool parsing_loop_body = true;
  SequenceNode* body = ParseNestedStatement(parsing_loop_body, label);

  // Check whether any of the variables in the initializer part of
  // the for statement are captured by a closure. If so, we insert a
  // node that creates a new Context for the loop variable before
  // the increment expression is evaluated.
  for (int i = 0; i < init_scope->num_variables(); i++) {
    if (init_scope->VariableAt(i)->is_captured() &&
        (init_scope->VariableAt(i)->owner() == init_scope)) {
      SequenceNode* incr_sequence = new (Z) SequenceNode(incr_pos, NULL);
      incr_sequence->Add(new (Z) CloneContextNode(for_pos));
      if (increment != NULL) {
        incr_sequence->Add(increment);
      }
      increment = incr_sequence;
      break;
    }
  }
  AstNode* for_node = new (Z)
      ForNode(for_pos, label, NodeAsSequenceNode(init_pos, initializer, NULL),
              condition, condition_preamble,
              NodeAsSequenceNode(incr_pos, increment, NULL), body);
  current_block_->statements->Add(for_node);
  return CloseBlock();
}

// Calling VM-internal helpers, uses implementation core library.
AstNode* Parser::MakeStaticCall(const String& cls_name,
                                const String& func_name,
                                ArgumentListNode* arguments) {
  const Class& cls = Class::Handle(Z, Library::LookupCoreClass(cls_name));
  ASSERT(!cls.IsNull());
  const intptr_t kTypeArgsLen = 0;  // Not passing type args to generic func.
  const Function& func = Function::ZoneHandle(
      Z, Resolver::ResolveStatic(cls, func_name, kTypeArgsLen,
                                 arguments->length(), arguments->names()));
  ASSERT(!func.IsNull());
  return new (Z) StaticCallNode(arguments->token_pos(), func, arguments,
                                StaticCallNode::kStatic);
}

AstNode* Parser::ParseAssertStatement(bool is_const) {
  TRACE_PARSER("ParseAssertStatement");
  ConsumeToken();  // Consume assert keyword.
  ExpectToken(Token::kLPAREN);
  const TokenPosition condition_pos = TokenPos();
  if (!I->asserts()) {
    SkipExpr();
    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
      if (CurrentToken() != Token::kRPAREN) {
        SkipExpr();
        if (CurrentToken() == Token::kCOMMA) {
          // Allow trailing comma.
          ConsumeToken();
        }
      }
    }
    ExpectToken(Token::kRPAREN);
    return NULL;
  }

  BoolScope saved_seen_await(&parsed_function()->have_seen_await_expr_, false);
  AstNode* condition = ParseExpr(kAllowConst, kConsumeCascades);
  if (is_const && !condition->IsPotentiallyConst()) {
    ReportError(condition_pos,
                "initializer assert expression must be compile time constant.");
  }
  const TokenPosition condition_end = TokenPos();
  AstNode* message = NULL;
  TokenPosition message_pos = TokenPosition::kNoSource;
  if (CurrentToken() == Token::kCOMMA) {
    ConsumeToken();
    if (CurrentToken() != Token::kRPAREN) {
      message_pos = TokenPos();
      message = ParseExpr(kAllowConst, kConsumeCascades);
      if (is_const && !message->IsPotentiallyConst()) {
        ReportError(
            message_pos,
            "initializer assert expression must be compile time constant.");
      }
      if (CurrentToken() == Token::kCOMMA) {
        // Allow trailing comma.
        ConsumeToken();
      }
    }
  }
  ExpectToken(Token::kRPAREN);

  if (!is_const) {
    // Check for assertion condition being a function if not const.
    ArgumentListNode* arguments = new (Z) ArgumentListNode(condition_pos);
    arguments->Add(condition);
    condition = MakeStaticCall(
        Symbols::AssertionError(),
        Library::PrivateCoreLibName(Symbols::EvaluateAssertion()), arguments);
  }
  AstNode* not_condition =
      new (Z) UnaryOpNode(condition_pos, Token::kNOT, condition);

  // Build call to _AsertionError._throwNew(start, end, message)
  ArgumentListNode* arguments = new (Z) ArgumentListNode(condition_pos);
  arguments->Add(new (Z) LiteralNode(
      condition_pos,
      Integer::ZoneHandle(Z, Integer::New(condition_pos.Pos()))));
  arguments->Add(new (Z) LiteralNode(
      condition_end,
      Integer::ZoneHandle(Z, Integer::New(condition_end.Pos()))));
  if (message == NULL) {
    message = new (Z) LiteralNode(condition_end, Instance::ZoneHandle(Z));
  }
  arguments->Add(message);
  AstNode* assert_throw = MakeStaticCall(
      Symbols::AssertionError(),
      Library::PrivateCoreLibName(Symbols::ThrowNew()), arguments);

  AstNode* assertion_check = NULL;
  if (parsed_function()->have_seen_await()) {
    // The await transformation must be done manually because assertions
    // are parsed as statements, not expressions. Thus, we need to check
    // explicitly whether the arguments contain await operators. (Note that
    // we must not parse the arguments with ParseAwaitableExpr(). In the
    // corner case of assert(await a, await b), this would create two
    // sibling scopes containing the temporary values for a and b. Both
    // values would be allocated in the same internal context variable.)
    //
    // Build !condition ? _AsertionError._throwNew(...) : null;
    // We need to use a conditional expression because the await transformer
    // cannot transform if statements.
    assertion_check = new (Z) ConditionalExprNode(
        condition_pos, not_condition, assert_throw,
        new (Z) LiteralNode(condition_pos, Object::null_instance()));
    OpenBlock();
    AwaitTransformer at(current_block_->statements, async_temp_scope_);
    AstNode* transformed_assertion = at.Transform(assertion_check);
    SequenceNode* preamble = CloseBlock();
    preamble->Add(transformed_assertion);
    assertion_check = preamble;
  } else {
    // Build if (!condition) _AsertionError._throwNew(...)
    assertion_check = new (Z)
        IfNode(condition_pos, not_condition,
               NodeAsSequenceNode(condition_pos, assert_throw, NULL), NULL);
  }
  return assertion_check;
}

// Populate local scope of the catch block with the catch parameters.
void Parser::AddCatchParamsToScope(CatchParamDesc* exception_param,
                                   CatchParamDesc* stack_trace_param,
                                   LocalScope* scope) {
  if (exception_param->name != NULL) {
    LocalVariable* var = new (Z)
        LocalVariable(exception_param->token_pos, exception_param->token_pos,
                      *exception_param->name, *exception_param->type);
    var->set_is_final();
    bool added_to_scope = scope->AddVariable(var);
    ASSERT(added_to_scope);
    exception_param->var = var;
  }
  if (stack_trace_param->name != NULL) {
    LocalVariable* var = new (Z) LocalVariable(
        stack_trace_param->token_pos, stack_trace_param->token_pos,
        *stack_trace_param->name, *stack_trace_param->type);
    var->set_is_final();
    bool added_to_scope = scope->AddVariable(var);
    if (!added_to_scope) {
      // The name of the exception param is reused for the stack trace param.
      ReportError(stack_trace_param->token_pos,
                  "name '%s' already exists in scope",
                  stack_trace_param->name->ToCString());
    }
    stack_trace_param->var = var;
  }
}

// Generate code to load the exception object (:exception_var) into
// the saved exception variable (:saved_exception_var) used to rethrow.
// Generate code to load the stack trace object (:stack_trace_var) into
// the saved stacktrace variable (:saved_stack_trace_var) used to rethrow.
void Parser::SaveExceptionAndStackTrace(SequenceNode* statements,
                                        LocalVariable* exception_var,
                                        LocalVariable* stack_trace_var,
                                        LocalVariable* saved_exception_var,
                                        LocalVariable* saved_stack_trace_var) {
  ASSERT(innermost_function().IsAsyncClosure() ||
         innermost_function().IsAsyncFunction() ||
         innermost_function().IsSyncGenClosure() ||
         innermost_function().IsSyncGenerator() ||
         innermost_function().IsAsyncGenClosure() ||
         innermost_function().IsAsyncGenerator());

  ASSERT(saved_exception_var != NULL);
  ASSERT(exception_var != NULL);
  statements->Add(new (Z) StoreLocalNode(
      TokenPosition::kNoSource, saved_exception_var,
      new (Z) LoadLocalNode(TokenPosition::kNoSource, exception_var)));

  ASSERT(saved_stack_trace_var != NULL);
  ASSERT(stack_trace_var != NULL);
  statements->Add(new (Z) StoreLocalNode(
      TokenPosition::kNoSource, saved_stack_trace_var,
      new (Z) LoadLocalNode(TokenPosition::kNoSource, stack_trace_var)));
}

SequenceNode* Parser::EnsureFinallyClause(
    bool parse,
    bool is_async,
    LocalVariable* exception_var,
    LocalVariable* stack_trace_var,
    LocalVariable* rethrow_exception_var,
    LocalVariable* rethrow_stack_trace_var) {
  TRACE_PARSER("EnsureFinallyClause");
  ASSERT(parse || (is_async && (try_stack_ != NULL)));
  // Increasing the loop level prevents the reuse of a parent context and forces
  // the allocation of a local context to hold captured variables declared
  // inside the finally clause. Otherwise, a captured variable gets allocated at
  // different slots in the parent context each time the finally clause is
  // reparsed, which is done to duplicate the ast. Since only one closure is
  // kept due to canonicalization, it will access the correct slot in only one
  // copy of the finally clause and the wrong slot in all others. By allocating
  // a local context, all copies use the same slot in different local contexts.
  // See issue #26948. This is a temporary fix until we eliminate reparsing.
  OpenLoopBlock();
  if (parse) {
    ExpectToken(Token::kLBRACE);
  }

  if (try_stack_ != NULL) {
    try_stack_->enter_finally();
  }
  // In case of async closures we need to restore the saved try context of an
  // outer try block (if it exists).  The current try block has already been
  // removed from the stack of try blocks.
  if (is_async) {
    if (try_stack_ != NULL) {
      LocalScope* scope = try_stack_->try_block()->scope;
      if (scope->function_level() == current_block_->scope->function_level()) {
        LocalVariable* saved_try_ctx =
            LookupSavedTryContextVar(scope->parent());
        LocalVariable* async_saved_try_ctx = LookupAsyncSavedTryContextVar(
            T, async_temp_scope_, try_stack_->try_index());
        current_block_->statements->Add(new (Z) StoreLocalNode(
            TokenPosition::kNoSource, saved_try_ctx,
            new (Z)
                LoadLocalNode(TokenPosition::kNoSource, async_saved_try_ctx)));
      }
    }
    // We need to save the exception variables as in catch clauses, whether
    // there is an outer try or not. Note that this is only necessary if the
    // finally clause contains an await or yield.
    // TODO(hausner): Optimize.
    SaveExceptionAndStackTrace(current_block_->statements, exception_var,
                               stack_trace_var, rethrow_exception_var,
                               rethrow_stack_trace_var);
  }

  if (parse) {
    ParseStatementSequence();
    ExpectToken(Token::kRBRACE);
  }
  SequenceNode* finally_clause = CloseBlock();
  if (try_stack_ != NULL) {
    try_stack_->exit_finally();
  }
  return finally_clause;
}

void Parser::PushTry(Block* try_block) {
  intptr_t try_index = AllocateTryIndex();
  try_stack_ = new (Z) TryStack(try_block, try_stack_, try_index);
}

Parser::TryStack* Parser::PopTry() {
  TryStack* innermost_try = try_stack_;
  try_stack_ = try_stack_->outer_try();
  return innermost_try;
}

void Parser::AddNodeForFinallyInlining(AstNode* node) {
  if (node == NULL) {
    return;
  }
  ASSERT(node->IsReturnNode() || node->IsJumpNode());
  const intptr_t func_level = FunctionLevel();
  TryStack* iterator = try_stack_;
  while ((iterator != NULL) &&
         (iterator->try_block()->scope->function_level() == func_level)) {
    // For continue and break node check if the target label is in scope.
    if (node->IsJumpNode()) {
      SourceLabel* label = node->AsJumpNode()->label();
      ASSERT(label != NULL);
      LocalScope* try_scope = iterator->try_block()->scope;
      // If the label is defined in a scope which is a child (nested scope)
      // of the try scope then we are not breaking out of this try block
      // so we do not need to inline the finally code. Otherwise we need
      // to inline the finally code of this try block and then move on to the
      // next outer try block.
      // For unresolved forward jumps to switch cases, we don't yet know
      // to which scope the label will be resolved. Tentatively add the
      // jump to all nested try statements and remove the outermost ones
      // when we know the exact jump target. (See
      // RemoveNodesForFinallyInlining below.)
      if (!label->IsUnresolved() && label->owner()->IsNestedWithin(try_scope)) {
        break;
      }
    }
    iterator->AddNodeForFinallyInlining(node);
    iterator = iterator->outer_try();
  }
}

void Parser::RemoveNodesForFinallyInlining(SourceLabel* label) {
  TryStack* iterator = try_stack_;
  const intptr_t func_level = FunctionLevel();
  while ((iterator != NULL) &&
         (iterator->try_block()->scope->function_level() == func_level)) {
    iterator->RemoveJumpToLabel(label);
    iterator = iterator->outer_try();
  }
}

// Add the inlined finally clause to the specified node.
void Parser::AddFinallyClauseToNode(bool is_async,
                                    AstNode* node,
                                    InlinedFinallyNode* finally_clause) {
  ReturnNode* return_node = node->AsReturnNode();
  if (return_node != NULL) {
    if (FunctionLevel() == 0) {
      parsed_function()->EnsureFinallyReturnTemp(is_async);
    }
    return_node->AddInlinedFinallyNode(finally_clause);
    return;
  }
  JumpNode* jump_node = node->AsJumpNode();
  ASSERT(jump_node != NULL);
  jump_node->AddInlinedFinallyNode(finally_clause);
}

SequenceNode* Parser::ParseCatchClauses(
    TokenPosition handler_pos,
    bool is_async,
    LocalVariable* exception_var,
    LocalVariable* stack_trace_var,
    LocalVariable* rethrow_exception_var,
    LocalVariable* rethrow_stack_trace_var,
    const GrowableObjectArray& handler_types,
    bool* needs_stack_trace) {
  // All catch blocks are merged into an if-then-else sequence of the
  // different types specified using the 'is' operator.  While parsing
  // record the type tests (either a ComparisonNode or else the LiteralNode
  // true for a generic catch) and the catch bodies in a pair of parallel
  // lists.  Afterward, construct the nested if-then-else.
  bool generic_catch_seen = false;
  GrowableArray<AstNode*> type_tests;
  GrowableArray<SequenceNode*> catch_blocks;
  while ((CurrentToken() == Token::kCATCH) || IsSymbol(Symbols::On())) {
    // Open a block that contains the if or an unconditional body.  It's
    // closed in the loop that builds the if-then-else nest.
    OpenBlock();
    const TokenPosition catch_pos = TokenPos();
    CatchParamDesc exception_param;
    CatchParamDesc stack_trace_param;
    if (IsSymbol(Symbols::On())) {
      ConsumeToken();
      exception_param.type = &AbstractType::ZoneHandle(
          Z, ParseTypeOrFunctionType(false, ClassFinalizer::kCanonicalize));
    } else {
      exception_param.type = &Object::dynamic_type();
    }
    if (CurrentToken() == Token::kCATCH) {
      ConsumeToken();  // Consume the 'catch'.
      ExpectToken(Token::kLPAREN);
      exception_param.token_pos = TokenPos();
      exception_param.name = ExpectIdentifier("identifier expected");
      if (CurrentToken() == Token::kCOMMA) {
        ConsumeToken();
        stack_trace_param.type = &Object::dynamic_type();
        stack_trace_param.token_pos = TokenPos();
        stack_trace_param.name = ExpectIdentifier("identifier expected");
      }
      ExpectToken(Token::kRPAREN);
    }

    // Create a block containing the catch clause parameters and the
    // following code:
    // 1) Store exception object and stack trace object into user-defined
    //    variables (as needed).
    // 2) In async code, save exception object and stack trace object into
    //    captured :saved_exception_var and :saved_stack_trace_var.
    // 3) Nested block with source code from catch clause block.
    OpenBlock();
    AddCatchParamsToScope(&exception_param, &stack_trace_param,
                          current_block_->scope);

    if (exception_param.var != NULL) {
      // Generate code to load the exception object (:exception_var) into
      // the exception variable specified in this block.
      ASSERT(exception_var != NULL);
      current_block_->statements->Add(new (Z) StoreLocalNode(
          catch_pos, exception_param.var,
          new (Z) LoadLocalNode(catch_pos, exception_var)));
    }
    if (stack_trace_param.var != NULL) {
      // A stack trace variable is specified in this block, so generate code
      // to load the stack trace object (:stack_trace_var) into the stack
      // trace variable specified in this block.
      *needs_stack_trace = true;
      ASSERT(stack_trace_var != NULL);
      current_block_->statements->Add(new (Z) StoreLocalNode(
          catch_pos, stack_trace_param.var,
          new (Z) LoadLocalNode(catch_pos, stack_trace_var)));
    }

    // Add nested block with user-defined code.  This block allows
    // declarations in the body to shadow the catch parameters.
    CheckToken(Token::kLBRACE);

    current_block_->statements->Add(ParseNestedStatement(false, NULL));
    catch_blocks.Add(CloseBlock());

    const bool is_bad_type = exception_param.type->IsMalformed() ||
                             exception_param.type->IsMalbounded();
    if (exception_param.type->IsDynamicType() || is_bad_type) {
      // There is no exception type or else it is malformed or malbounded.
      // In the first case, unconditionally execute the catch body.  In the
      // second case, unconditionally throw.
      generic_catch_seen = true;
      type_tests.Add(new (Z) LiteralNode(catch_pos, Bool::True()));
      if (is_bad_type) {
        // Replace the body with one that throws.
        SequenceNode* block = new (Z) SequenceNode(catch_pos, NULL);
        block->Add(ThrowTypeError(catch_pos, *exception_param.type));
        catch_blocks.Last() = block;
      }
      // This catch clause will handle all exceptions. We can safely forget
      // all previous catch clause types.
      handler_types.SetLength(0);
      handler_types.Add(*exception_param.type, Heap::kOld);
    } else {
      // Has a type specification that is not malformed or malbounded.  Now
      // form an 'if type check' to guard the catch handler code.
      if (!exception_param.type->IsInstantiated() && (FunctionLevel() > 0)) {
        // Make sure that the instantiators are captured.
        CaptureAllInstantiators();
      }
      TypeNode* exception_type =
          new (Z) TypeNode(catch_pos, *exception_param.type);
      AstNode* exception_value =
          new (Z) LoadLocalNode(catch_pos, exception_var);
      if (!exception_type->type().IsInstantiated()) {
        EnsureExpressionTemp();
      }
      type_tests.Add(new (Z) ComparisonNode(catch_pos, Token::kIS,
                                            exception_value, exception_type));

      // Do not add uninstantiated types (e.g. type parameter T or generic
      // type List<T>), since the debugger won't be able to instantiate it
      // when walking the stack.
      //
      // This means that the debugger is not able to determine whether an
      // exception is caught if the catch clause uses generic types.  It
      // will report the exception as uncaught when in fact it might be
      // caught and handled when we unwind the stack.
      if (!generic_catch_seen && exception_param.type->IsInstantiated()) {
        handler_types.Add(*exception_param.type, Heap::kOld);
      }
    }

    ASSERT(type_tests.length() == catch_blocks.length());
  }

  // Build the if/then/else nest from the inside out.  Keep the AST simple
  // for the case of a single generic catch clause.  The initial value of
  // current is the last (innermost) else block if there were any catch
  // clauses.
  SequenceNode* current = NULL;
  if (!generic_catch_seen) {
    // There isn't a generic catch clause so create a clause body that
    // rethrows the exception.  This includes the case that there were no
    // catch clauses.
    // An await cannot possibly be executed in between the catch entry and here,
    // therefore, it is safe to rethrow the stack-based :exception_var instead
    // of the captured copy :saved_exception_var.
    current = new (Z) SequenceNode(handler_pos, NULL);
    current->Add(new (Z) ThrowNode(
        handler_pos, new (Z) LoadLocalNode(handler_pos, exception_var),
        new (Z) LoadLocalNode(handler_pos, stack_trace_var)));
  } else if (type_tests.Last()->IsLiteralNode()) {
    ASSERT(type_tests.Last()->AsLiteralNode()->literal().raw() ==
           Bool::True().raw());
    // The last body is entered unconditionally.  Start building the
    // if/then/else nest with that body as the innermost else block.
    // Note that it is nested inside an extra block which we opened
    // before we knew the body was entered unconditionally.
    type_tests.RemoveLast();
    current_block_->statements->Add(catch_blocks.RemoveLast());
    current = CloseBlock();
  }
  // If the last body was entered conditionally and there is no need to add
  // a rethrow, use an empty else body (current = NULL above).
  while (!type_tests.is_empty()) {
    AstNode* type_test = type_tests.RemoveLast();
    SequenceNode* catch_block = catch_blocks.RemoveLast();
    current_block_->statements->Add(new (Z) IfNode(
        type_test->token_pos(), type_test, catch_block, current));
    current = CloseBlock();
  }
  // In case of async closures, restore :saved_try_context_var before executing
  // the catch clauses.
  if (is_async && (current != NULL)) {
    ASSERT(try_stack_ != NULL);
    SequenceNode* async_code = new (Z) SequenceNode(handler_pos, NULL);
    const TryStack* try_block = try_stack_->outer_try();
    if (try_block != NULL) {
      LocalScope* scope = try_block->try_block()->scope;
      if (scope->function_level() == current_block_->scope->function_level()) {
        LocalVariable* saved_try_ctx =
            LookupSavedTryContextVar(scope->parent());
        LocalVariable* async_saved_try_ctx = LookupAsyncSavedTryContextVar(
            T, async_temp_scope_, try_block->try_index());
        async_code->Add(new (Z) StoreLocalNode(
            TokenPosition::kNoSource, saved_try_ctx,
            new (Z)
                LoadLocalNode(TokenPosition::kNoSource, async_saved_try_ctx)));
      }
    }
    SaveExceptionAndStackTrace(async_code, exception_var, stack_trace_var,
                               rethrow_exception_var, rethrow_stack_trace_var);
    // The async_code node sequence contains code to restore the context (if
    // an outer try block is present) and code to save the exception and
    // stack trace variables.
    // This async code is inserted before the current node sequence containing
    // the chain of if/then/else handling all catch clauses.
    async_code->Add(current);
    current = async_code;
  }
  return current;
}

void Parser::SetupSavedTryContext(LocalVariable* saved_try_context) {
  const String& async_saved_try_ctx_name = String::ZoneHandle(
      Z, Symbols::NewFormatted(T, "%s%d",
                               Symbols::AsyncSavedTryCtxVarPrefix().ToCString(),
                               last_used_try_index_ - 1));
  LocalVariable* async_saved_try_ctx =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            async_saved_try_ctx_name, Object::dynamic_type());
  ASSERT(async_temp_scope_ != NULL);
  async_temp_scope_->AddVariable(async_saved_try_ctx);
  ASSERT(saved_try_context != NULL);
  current_block_->statements->Add(new (Z) StoreLocalNode(
      TokenPosition::kNoSource, async_saved_try_ctx,
      new (Z) LoadLocalNode(TokenPosition::kNoSource, saved_try_context)));
}

// We create three variables for exceptions:
// ':saved_try_context_var' - Used to save the context before the start of
//                            the try block. The context register is
//                            restored from this variable before
//                            processing the catch block handler.
// ':exception_var' - Used to save the current exception object that was
//                    thrown.
// ':stack_trace_var' - Used to save the current stack trace object which
//                      the stack trace was copied into when an exception
//                      was thrown.
// :exception_var and :stack_trace_var get set with the exception object
// and the stack trace object when an exception is thrown.  These three
// implicit variables can never be captured.
//
// In case of async code, we create two additional variables:
// ':saved_exception_var' - Used to capture the exception object above.
// ':saved_stack_trace_var' - Used to capture the stack trace object above.
void Parser::SetupExceptionVariables(LocalScope* try_scope,
                                     bool is_async,
                                     LocalVariable** context_var,
                                     LocalVariable** exception_var,
                                     LocalVariable** stack_trace_var,
                                     LocalVariable** saved_exception_var,
                                     LocalVariable** saved_stack_trace_var) {
  // Consecutive try statements share the same set of variables.
  *context_var = try_scope->LocalLookupVariable(Symbols::SavedTryContextVar());
  if (*context_var == NULL) {
    *context_var = new (Z)
        LocalVariable(TokenPos(), TokenPos(), Symbols::SavedTryContextVar(),
                      Object::dynamic_type());
    try_scope->AddVariable(*context_var);
  }
  *exception_var = try_scope->LocalLookupVariable(Symbols::ExceptionVar());
  if (*exception_var == NULL) {
    *exception_var =
        new (Z) LocalVariable(TokenPos(), TokenPos(), Symbols::ExceptionVar(),
                              Object::dynamic_type());
    try_scope->AddVariable(*exception_var);
  }
  *stack_trace_var = try_scope->LocalLookupVariable(Symbols::StackTraceVar());
  if (*stack_trace_var == NULL) {
    *stack_trace_var =
        new (Z) LocalVariable(TokenPos(), TokenPos(), Symbols::StackTraceVar(),
                              Object::dynamic_type());
    try_scope->AddVariable(*stack_trace_var);
  }
  if (is_async) {
    *saved_exception_var =
        try_scope->LocalLookupVariable(Symbols::SavedExceptionVar());
    if (*saved_exception_var == NULL) {
      *saved_exception_var = new (Z)
          LocalVariable(TokenPos(), TokenPos(), Symbols::SavedExceptionVar(),
                        Object::dynamic_type());
      try_scope->AddVariable(*saved_exception_var);
    }
    *saved_stack_trace_var =
        try_scope->LocalLookupVariable(Symbols::SavedStackTraceVar());
    if (*saved_stack_trace_var == NULL) {
      *saved_stack_trace_var = new (Z)
          LocalVariable(TokenPos(), TokenPos(), Symbols::SavedStackTraceVar(),
                        Object::dynamic_type());
      try_scope->AddVariable(*saved_stack_trace_var);
    }
  }
}

AstNode* Parser::ParseTryStatement(String* label_name) {
  TRACE_PARSER("ParseTryStatement");

  const TokenPosition try_pos = TokenPos();
  SourceLabel* try_label = NULL;
  if (label_name != NULL) {
    try_label = SourceLabel::New(try_pos, label_name, SourceLabel::kStatement);
    OpenBlock();
    current_block_->scope->AddLabel(try_label);
  }

  const bool is_async = innermost_function().IsAsyncClosure() ||
                        innermost_function().IsAsyncFunction() ||
                        innermost_function().IsSyncGenClosure() ||
                        innermost_function().IsSyncGenerator() ||
                        innermost_function().IsAsyncGenClosure() ||
                        innermost_function().IsAsyncGenerator();
  LocalVariable* context_var = NULL;
  LocalVariable* exception_var = NULL;
  LocalVariable* stack_trace_var = NULL;
  LocalVariable* saved_exception_var = NULL;
  LocalVariable* saved_stack_trace_var = NULL;
  SetupExceptionVariables(current_block_->scope, is_async, &context_var,
                          &exception_var, &stack_trace_var,
                          &saved_exception_var, &saved_stack_trace_var);

  ConsumeToken();  // Consume the 'try'.

  // Now parse the 'try' block.
  OpenBlock();
  PushTry(current_block_);
  ExpectToken(Token::kLBRACE);

  if (is_async) {
    SetupSavedTryContext(context_var);
  }

  ParseStatementSequence();
  ExpectToken(Token::kRBRACE);
  SequenceNode* try_block = CloseBlock();

  if ((CurrentToken() != Token::kCATCH) && !IsSymbol(Symbols::On()) &&
      (CurrentToken() != Token::kFINALLY)) {
    ReportError("catch or finally clause expected");
  }

  // Now parse the 'catch' blocks if any.
  try_stack_->enter_catch();
  const TokenPosition handler_pos = TokenPos();
  const GrowableObjectArray& handler_types =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New(Heap::kOld));
  bool needs_stack_trace = false;
  SequenceNode* catch_handler_list =
      ParseCatchClauses(handler_pos, is_async, exception_var, stack_trace_var,
                        is_async ? saved_exception_var : exception_var,
                        is_async ? saved_stack_trace_var : stack_trace_var,
                        handler_types, &needs_stack_trace);

  TryStack* try_statement = PopTry();
  const intptr_t try_index = try_statement->try_index();
  TryStack* outer_try = try_stack_;
  const intptr_t outer_try_index = (outer_try != NULL)
                                       ? outer_try->try_index()
                                       : CatchClauseNode::kInvalidTryIndex;

  // Finally, parse or generate the 'finally' clause.
  // A finally clause is required in async code to restore the saved try context
  // of an existing outer try. Generate a finally clause to this purpose if it
  // is not declared.
  SequenceNode* finally_clause = NULL;
  SequenceNode* rethrow_clause = NULL;
  const bool parse = CurrentToken() == Token::kFINALLY;
  if (parse || (is_async && (try_stack_ != NULL))) {
    if (parse) {
      ConsumeToken();  // Consume the 'finally'.
    }
    const TokenPosition finally_pos = TokenPos();
    // Add the finally block to the exit points recorded so far.
    intptr_t node_index = 0;
    AstNode* node_to_inline = try_statement->GetNodeToInlineFinally(node_index);
    while (node_to_inline != NULL) {
      finally_clause = EnsureFinallyClause(
          parse, is_async, exception_var, stack_trace_var,
          is_async ? saved_exception_var : exception_var,
          is_async ? saved_stack_trace_var : stack_trace_var);
      InlinedFinallyNode* node = new (Z) InlinedFinallyNode(
          finally_pos, finally_clause, context_var, outer_try_index);
      AddFinallyClauseToNode(is_async, node_to_inline, node);
      node_index += 1;
      node_to_inline = try_statement->GetNodeToInlineFinally(node_index);
      tokens_iterator_.SetCurrentPosition(finally_pos);
    }
    finally_clause =
        EnsureFinallyClause(parse, is_async, exception_var, stack_trace_var,
                            is_async ? saved_exception_var : exception_var,
                            is_async ? saved_stack_trace_var : stack_trace_var);
    if (finally_clause != NULL) {
      // Re-parse to create a duplicate of finally clause to avoid unintended
      // sharing of try-indices if the finally-block contains a try-catch.
      // The flow graph builder emits two copies of the finally-block if the
      // try-block has a normal exit: one for the exception- and one for the
      // non-exception case (see EffectGraphVisitor::VisitTryCatchNode)
      tokens_iterator_.SetCurrentPosition(finally_pos);
      rethrow_clause = EnsureFinallyClause(
          parse, is_async, exception_var, stack_trace_var,
          is_async ? saved_exception_var : exception_var,
          is_async ? saved_stack_trace_var : stack_trace_var);
    }
  }

  CatchClauseNode* catch_clause = new (Z) CatchClauseNode(
      handler_pos, catch_handler_list,
      Array::ZoneHandle(Z, Array::MakeFixedLength(handler_types)), context_var,
      exception_var, stack_trace_var,
      is_async ? saved_exception_var : exception_var,
      is_async ? saved_stack_trace_var : stack_trace_var,
      (finally_clause != NULL) ? AllocateTryIndex()
                               : CatchClauseNode::kInvalidTryIndex,
      needs_stack_trace);

  // Now create the try/catch ast node and return it. If there is a label
  // on the try/catch, close the block that's embedding the try statement
  // and attach the label to it.
  AstNode* try_catch_node =
      new (Z) TryCatchNode(try_pos, try_block, context_var, catch_clause,
                           finally_clause, try_index, rethrow_clause);

  if (try_label != NULL) {
    current_block_->statements->Add(try_catch_node);
    SequenceNode* sequence = CloseBlock();
    sequence->set_label(try_label);
    try_catch_node = sequence;
  }

  return try_catch_node;
}

AstNode* Parser::ParseJump(String* label_name) {
  TRACE_PARSER("ParseJump");
  ASSERT(CurrentToken() == Token::kBREAK || CurrentToken() == Token::kCONTINUE);
  Token::Kind jump_kind = CurrentToken();
  const TokenPosition jump_pos = TokenPos();
  SourceLabel* target = NULL;
  ConsumeToken();
  if (IsIdentifier()) {
    // Explicit label after break/continue.
    const String& target_name = *CurrentLiteral();
    ConsumeToken();
    // Handle pathological cases first.
    if (label_name != NULL && target_name.Equals(*label_name)) {
      if (jump_kind == Token::kCONTINUE) {
        ReportError(jump_pos, "'continue' jump to label '%s' is illegal",
                    target_name.ToCString());
      }
      // L: break L; is a no-op.
      return NULL;
    }
    target = current_block_->scope->LookupLabel(target_name);
    if (target == NULL && jump_kind == Token::kCONTINUE) {
      // Either a reference to a non-existent label, or a forward reference
      // to a case label that we haven't seen yet. If we are inside a switch
      // statement, create a "forward reference" label in the scope of
      // the switch statement.
      LocalScope* switch_scope = current_block_->scope->LookupSwitchScope();
      if (switch_scope != NULL) {
        // We found a switch scope. Enter a forward reference to the label.
        target =
            new (Z) SourceLabel(TokenPos(), target_name, SourceLabel::kForward);
        switch_scope->AddLabel(target);
      }
    }
    if (target == NULL) {
      ReportError(jump_pos, "label '%s' not found", target_name.ToCString());
    }
  } else if (FLAG_enable_debug_break && (CurrentToken() == Token::kSTRING)) {
    const char* message = Z->MakeCopyOfString(CurrentLiteral()->ToCString());
    ConsumeToken();
    return new (Z) StopNode(jump_pos, message);
  } else {
    target = current_block_->scope->LookupInnermostLabel(jump_kind);
    if (target == NULL) {
      ReportError(jump_pos, "'%s' is illegal here", Token::Str(jump_kind));
    }
  }
  ASSERT(target != NULL);
  if (jump_kind == Token::kCONTINUE) {
    if (target->kind() == SourceLabel::kSwitch) {
      ReportError(jump_pos, "'continue' jump to switch statement is illegal");
    } else if (target->kind() == SourceLabel::kStatement) {
      ReportError(jump_pos, "'continue' jump to label '%s' is illegal",
                  target->name().ToCString());
    }
  }
  if (jump_kind == Token::kBREAK && target->kind() == SourceLabel::kCase) {
    ReportError(jump_pos, "'break' to case clause label is illegal");
  }
  if (target->FunctionLevel() != FunctionLevel()) {
    ReportError(jump_pos, "'%s' target must be in same function context",
                Token::Str(jump_kind));
  }
  return new (Z) JumpNode(jump_pos, jump_kind, target);
}

AstNode* Parser::ParseYieldStatement() {
  bool is_yield_each = false;
  const TokenPosition yield_pos = TokenPos();
  ConsumeToken();  // yield reserved word.
  if (CurrentToken() == Token::kMUL) {
    is_yield_each = true;
    ConsumeToken();
  }
  if (!innermost_function().IsGenerator() &&
      !innermost_function().IsGeneratorClosure()) {
    ReportError(yield_pos,
                "yield%s statement only allowed in generator functions",
                is_yield_each ? "*" : "");
  }

  AstNode* expr = ParseAwaitableExpr(kAllowConst, kConsumeCascades, NULL);

  LetNode* yield = new (Z) LetNode(yield_pos);
  if (innermost_function().IsSyncGenerator() ||
      innermost_function().IsSyncGenClosure()) {
    // Yield statement in sync* function.

    LocalVariable* iterator_param =
        LookupLocalScope(Symbols::IteratorParameter());
    ASSERT(iterator_param != NULL);
    // Generate :iterator.current = expr;
    AstNode* iterator =
        new (Z) LoadLocalNode(TokenPosition::kNoSource, iterator_param);
    AstNode* store_current = new (Z) InstanceSetterNode(
        TokenPosition::kNoSource, iterator,
        Library::PrivateCoreLibName(Symbols::_current()), expr);
    yield->AddNode(store_current);
    if (is_yield_each) {
      // Generate :iterator.isYieldEach = true;
      AstNode* set_is_yield_each = new (Z)
          InstanceSetterNode(TokenPosition::kNoSource, iterator,
                             String::ZoneHandle(Symbols::IsYieldEach().raw()),
                             new (Z) LiteralNode(TokenPos(), Bool::True()));
      yield->AddNode(set_is_yield_each);
    }
    AwaitMarkerNode* await_marker = new (Z) AwaitMarkerNode(
        async_temp_scope_, current_block_->scope, TokenPosition::kNoSource);
    yield->AddNode(await_marker);
    // Return true to indicate that a value has been generated.
    ReturnNode* return_true = new (Z)
        ReturnNode(yield_pos, new (Z) LiteralNode(TokenPos(), Bool::True()));
    return_true->set_return_type(ReturnNode::kContinuationTarget);
    yield->AddNode(return_true);

    // If this expression is part of a try block, also append the code for
    // restoring the saved try context that lives on the stack and possibly the
    // saved try context of the outer try block.
    LocalVariable* saved_try_ctx;
    LocalVariable* async_saved_try_ctx;
    LocalVariable* outer_saved_try_ctx;
    LocalVariable* outer_async_saved_try_ctx;
    CheckAsyncOpInTryBlock(&saved_try_ctx, &async_saved_try_ctx,
                           &outer_saved_try_ctx, &outer_async_saved_try_ctx);
    if (saved_try_ctx != NULL) {
      yield->AddNode(new (Z) StoreLocalNode(
          TokenPosition::kNoSource, saved_try_ctx,
          new (Z)
              LoadLocalNode(TokenPosition::kNoSource, async_saved_try_ctx)));
      if (outer_saved_try_ctx != NULL) {
        yield->AddNode(new (Z) StoreLocalNode(
            TokenPosition::kNoSource, outer_saved_try_ctx,
            new (Z) LoadLocalNode(TokenPosition::kNoSource,
                                  outer_async_saved_try_ctx)));
      }
    } else {
      ASSERT(outer_saved_try_ctx == NULL);
    }
  } else {
    // yield statement in async* function.
    ASSERT(innermost_function().IsAsyncGenerator() ||
           innermost_function().IsAsyncGenClosure());

    LocalVariable* controller_var =
        LookupLocalScope(Symbols::ColonController());
    ASSERT(controller_var != NULL);
    // :controller.add[Stream](expr);
    ArgumentListNode* add_args = new (Z) ArgumentListNode(yield_pos);
    add_args->Add(expr);
    AstNode* add_call = new (Z) InstanceCallNode(
        yield_pos,
        new (Z) LoadLocalNode(TokenPosition::kNoSource, controller_var),
        is_yield_each ? Symbols::AddStream() : Symbols::add(), add_args);

    // if (:controller.add[Stream](expr)) {
    //   return;
    // }
    // await_marker;
    // continuation_return;
    // restore saved_try_context

    SequenceNode* true_branch =
        new (Z) SequenceNode(TokenPosition::kNoSource, NULL);
    AstNode* return_from_generator = new (Z) ReturnNode(yield_pos);
    true_branch->Add(return_from_generator);
    AddNodeForFinallyInlining(return_from_generator);
    AstNode* if_is_cancelled =
        new (Z) IfNode(TokenPosition::kNoSource, add_call, true_branch, NULL);
    yield->AddNode(if_is_cancelled);

    AwaitMarkerNode* await_marker = new (Z) AwaitMarkerNode(
        async_temp_scope_, current_block_->scope, TokenPosition::kNoSource);
    yield->AddNode(await_marker);
    ReturnNode* continuation_return = new (Z) ReturnNode(yield_pos);
    continuation_return->set_return_type(ReturnNode::kContinuationTarget);
    yield->AddNode(continuation_return);

    // If this expression is part of a try block, also append the code for
    // restoring the saved try context that lives on the stack and possibly the
    // saved try context of the outer try block.
    LocalVariable* saved_try_ctx;
    LocalVariable* async_saved_try_ctx;
    LocalVariable* outer_saved_try_ctx;
    LocalVariable* outer_async_saved_try_ctx;
    CheckAsyncOpInTryBlock(&saved_try_ctx, &async_saved_try_ctx,
                           &outer_saved_try_ctx, &outer_async_saved_try_ctx);
    if (saved_try_ctx != NULL) {
      yield->AddNode(new (Z) StoreLocalNode(
          TokenPosition::kNoSource, saved_try_ctx,
          new (Z)
              LoadLocalNode(TokenPosition::kNoSource, async_saved_try_ctx)));
      if (outer_saved_try_ctx != NULL) {
        yield->AddNode(new (Z) StoreLocalNode(
            TokenPosition::kNoSource, outer_saved_try_ctx,
            new (Z) LoadLocalNode(TokenPosition::kNoSource,
                                  outer_async_saved_try_ctx)));
      }
    } else {
      ASSERT(outer_saved_try_ctx == NULL);
    }
  }
  return yield;
}

AstNode* Parser::ParseStatement() {
  TRACE_PARSER("ParseStatement");
  AstNode* statement = NULL;
  TokenPosition label_pos = TokenPosition::kNoSource;
  String* label_name = NULL;
  if (IsIdentifier()) {
    if (LookaheadToken(1) == Token::kCOLON) {
      // Statement starts with a label.
      label_name = CurrentLiteral();
      label_pos = TokenPos();
      ASSERT(label_pos.IsReal());
      ConsumeToken();  // Consume identifier.
      ConsumeToken();  // Consume colon.
    }
  }
  const TokenPosition statement_pos = TokenPos();
  const Token::Kind token = CurrentToken();

  if (token == Token::kWHILE) {
    statement = ParseWhileStatement(label_name);
  } else if (token == Token::kFOR) {
    statement = ParseForStatement(label_name);
  } else if (IsAwaitKeyword() && (LookaheadToken(1) == Token::kFOR)) {
    statement = ParseAwaitForStatement(label_name);
  } else if (token == Token::kDO) {
    statement = ParseDoWhileStatement(label_name);
  } else if (token == Token::kSWITCH) {
    statement = ParseSwitchStatement(label_name);
  } else if (token == Token::kTRY) {
    statement = ParseTryStatement(label_name);
  } else if (token == Token::kRETURN) {
    const TokenPosition return_pos = TokenPos();
    ConsumeToken();
    if (CurrentToken() != Token::kSEMICOLON) {
      const TokenPosition expr_pos = TokenPos();
      const int function_level = FunctionLevel();
      if (current_function().IsGenerativeConstructor() &&
          (function_level == 0)) {
        ReportError(expr_pos,
                    "return of a value is not allowed in constructors");
      } else if (current_function().IsGeneratorClosure() &&
                 (function_level == 0)) {
        ReportError(expr_pos, "generator functions may not return a value");
      }
      AstNode* expr = ParseAwaitableExpr(kAllowConst, kConsumeCascades, NULL);
      expr = AddAsyncResultTypeCheck(expr_pos, expr);
      statement = new (Z) ReturnNode(statement_pos, expr);
    } else {
      if (current_function().IsSyncGenClosure() && (FunctionLevel() == 0)) {
        // In a synchronous generator, return without an expression
        // returns false, signaling that the iterator terminates and
        // did not yield a value.
        statement = new (Z) ReturnNode(
            statement_pos, new (Z) LiteralNode(return_pos, Bool::False()));
      } else {
        statement = new (Z) ReturnNode(statement_pos);
      }
    }
    AddNodeForFinallyInlining(statement);
    ExpectSemicolon();
  } else if (IsYieldKeyword()) {
    statement = ParseYieldStatement();
    ExpectSemicolon();
  } else if (token == Token::kIF) {
    statement = ParseIfStatement(label_name);
  } else if (token == Token::kASSERT) {
    statement = ParseAssertStatement();
    ExpectSemicolon();
  } else if (IsVariableDeclaration()) {
    statement = ParseVariableDeclarationList();
    ExpectSemicolon();
  } else if (IsFunctionDeclaration()) {
    statement = ParseFunctionStatement(false);
  } else if (token == Token::kLBRACE) {
    SourceLabel* label = NULL;
    OpenBlock();
    if (label_name != NULL) {
      label = SourceLabel::New(label_pos, label_name, SourceLabel::kStatement);
      current_block_->scope->AddLabel(label);
    }
    ConsumeToken();
    ParseStatementSequence();
    statement = CloseBlock();
    if (label != NULL) {
      statement->AsSequenceNode()->set_label(label);
    }
    ExpectToken(Token::kRBRACE);
  } else if (token == Token::kBREAK) {
    statement = ParseJump(label_name);
    if ((statement != NULL) && !statement->IsStopNode()) {
      AddNodeForFinallyInlining(statement);
    }
    ExpectSemicolon();
  } else if (token == Token::kCONTINUE) {
    statement = ParseJump(label_name);
    AddNodeForFinallyInlining(statement);
    ExpectSemicolon();
  } else if (token == Token::kSEMICOLON) {
    // Empty statement, nothing to do.
    ConsumeToken();
  } else if (token == Token::kRETHROW) {
    // Rethrow of current exception.
    ConsumeToken();
    ExpectSemicolon();
    // Check if it is ok to do a rethrow. Find the innermost enclosing
    // catch block.
    TryStack* try_statement = try_stack_;
    while ((try_statement != NULL) && !try_statement->inside_catch()) {
      try_statement = try_statement->outer_try();
    }
    if (try_statement == NULL) {
      ReportError(statement_pos, "rethrow of an exception is not valid here");
    }

    // If in async code, use :saved_exception_var and :saved_stack_trace_var
    // instead of :exception_var and :stack_trace_var.
    // These variables are bound in the block containing the try.
    // Look in the try scope directly.
    LocalScope* scope = try_statement->try_block()->scope->parent();
    ASSERT(scope != NULL);
    LocalVariable* excp_var;
    LocalVariable* trace_var;
    if (innermost_function().IsAsyncClosure() ||
        innermost_function().IsAsyncFunction() ||
        innermost_function().IsSyncGenClosure() ||
        innermost_function().IsSyncGenerator() ||
        innermost_function().IsAsyncGenClosure() ||
        innermost_function().IsAsyncGenerator()) {
      excp_var = scope->LocalLookupVariable(Symbols::SavedExceptionVar());
      trace_var = scope->LocalLookupVariable(Symbols::SavedStackTraceVar());
    } else {
      excp_var = scope->LocalLookupVariable(Symbols::ExceptionVar());
      trace_var = scope->LocalLookupVariable(Symbols::StackTraceVar());
    }
    ASSERT(excp_var != NULL);
    ASSERT(trace_var != NULL);

    statement = new (Z)
        ThrowNode(statement_pos, new (Z) LoadLocalNode(statement_pos, excp_var),
                  new (Z) LoadLocalNode(statement_pos, trace_var));
  } else {
    statement = ParseAwaitableExpr(kAllowConst, kConsumeCascades, NULL);
    ExpectSemicolon();
  }
  return statement;
}

void Parser::ReportError(const Error& error) {
  Report::LongJump(error);
  UNREACHABLE();
}

void Parser::ReportErrors(const Error& prev_error,
                          const Script& script,
                          TokenPosition token_pos,
                          const char* format,
                          ...) {
  va_list args;
  va_start(args, format);
  Report::LongJumpV(prev_error, script, token_pos, format, args);
  va_end(args);
  UNREACHABLE();
}

void Parser::ReportError(TokenPosition token_pos,
                         const char* format,
                         ...) const {
  va_list args;
  va_start(args, format);
  Report::MessageV(Report::kError, script_, token_pos, Report::AtLocation,
                   format, args);
  va_end(args);
  UNREACHABLE();
}

void Parser::ReportErrorBefore(const char* format, ...) {
  va_list args;
  va_start(args, format);
  Report::MessageV(Report::kError, script_, PrevTokenPos(),
                   Report::AfterLocation, format, args);
  va_end(args);
  UNREACHABLE();
}

void Parser::ReportError(const char* format, ...) const {
  va_list args;
  va_start(args, format);
  Report::MessageV(Report::kError, script_, TokenPos(), Report::AtLocation,
                   format, args);
  va_end(args);
  UNREACHABLE();
}

void Parser::ReportWarning(TokenPosition token_pos,
                           const char* format,
                           ...) const {
  va_list args;
  va_start(args, format);
  Report::MessageV(Report::kWarning, script_, token_pos, Report::AtLocation,
                   format, args);
  va_end(args);
}

void Parser::ReportWarning(const char* format, ...) const {
  va_list args;
  va_start(args, format);
  Report::MessageV(Report::kWarning, script_, TokenPos(), Report::AtLocation,
                   format, args);
  va_end(args);
}

void Parser::CheckToken(Token::Kind token_expected, const char* msg) {
  if (CurrentToken() != token_expected) {
    if (msg != NULL) {
      ReportError("%s", msg);
    } else {
      ReportError("'%s' expected", Token::Str(token_expected));
    }
  }
}

void Parser::ExpectToken(Token::Kind token_expected) {
  if (CurrentToken() != token_expected) {
    ReportError("'%s' expected", Token::Str(token_expected));
  }
  ConsumeToken();
}

void Parser::ExpectSemicolon() {
  if (CurrentToken() != Token::kSEMICOLON) {
    ReportErrorBefore("semicolon expected");
  }
  ConsumeToken();
}

void Parser::UnexpectedToken() {
  ReportError("unexpected token '%s'", CurrentToken() == Token::kIDENT
                                           ? CurrentLiteral()->ToCString()
                                           : Token::Str(CurrentToken()));
}

String* Parser::ExpectUserDefinedTypeIdentifier(const char* msg) {
  if (CurrentToken() != Token::kIDENT) {
    ReportError("%s", msg);
  }
  String* ident = CurrentLiteral();
  if (ident->Equals("dynamic")) {
    ReportError("%s", msg);
  }
  ConsumeToken();
  return ident;
}

// Check whether current token is an identifier or a built-in identifier.
String* Parser::ExpectIdentifier(const char* msg) {
  if (!IsIdentifier()) {
    ReportError("%s", msg);
  }
  String* ident = CurrentLiteral();
  ConsumeToken();
  return ident;
}

bool Parser::IsAwaitKeyword() {
  return (FLAG_await_is_keyword || await_is_keyword_) &&
         IsSymbol(Symbols::Await());
}

bool Parser::IsYieldKeyword() {
  return (FLAG_await_is_keyword || await_is_keyword_) &&
         IsSymbol(Symbols::YieldKw());
}

static bool IsIncrementOperator(Token::Kind token) {
  return token == Token::kINCR || token == Token::kDECR;
}

static bool IsPrefixOperator(Token::Kind token) {
  return (token == Token::kSUB) || (token == Token::kNOT) ||
         (token == Token::kBIT_NOT);
}

SequenceNode* Parser::NodeAsSequenceNode(TokenPosition sequence_pos,
                                         AstNode* node,
                                         LocalScope* scope) {
  if ((node == NULL) || !node->IsSequenceNode()) {
    SequenceNode* sequence = new SequenceNode(sequence_pos, scope);
    if (node != NULL) {
      sequence->Add(node);
    }
    return sequence;
  }
  return node->AsSequenceNode();
}

AstNode* Parser::ThrowTypeError(TokenPosition type_pos,
                                const AbstractType& type,
                                LibraryPrefix* prefix) {
  ArgumentListNode* arguments = new (Z) ArgumentListNode(type_pos);

  String& method_name = String::Handle(Z);
  if (prefix == NULL) {
    method_name = Library::PrivateCoreLibName(Symbols::ThrowNew()).raw();
  } else {
    arguments->Add(new (Z) LiteralNode(type_pos, *prefix));
    method_name =
        Library::PrivateCoreLibName(Symbols::ThrowNewIfNotLoaded()).raw();
  }
  // Location argument.
  arguments->Add(new (Z) LiteralNode(
      type_pos,
      Integer::ZoneHandle(Z, Integer::New(type_pos.value(), Heap::kOld))));
  // Src value argument.
  arguments->Add(new (Z) LiteralNode(type_pos, Object::null_instance()));
  // Dst type argument.
  arguments->Add(new (Z) LiteralNode(type_pos, type));
  // Dst name argument.
  arguments->Add(new (Z) LiteralNode(type_pos, Symbols::Empty()));
  // Bound error msg argument.
  arguments->Add(new (Z) LiteralNode(type_pos, Object::null_instance()));
  return MakeStaticCall(Symbols::TypeError(), method_name, arguments);
}

// Call _throwNewIfNotLoaded if prefix is not NULL, otherwise call _throwNew.
AstNode* Parser::ThrowNoSuchMethodError(TokenPosition call_pos,
                                        const Class& cls,
                                        const String& function_name,
                                        ArgumentListNode* function_arguments,
                                        InvocationMirror::Level im_level,
                                        InvocationMirror::Kind im_kind,
                                        const Function* func,
                                        const LibraryPrefix* prefix) {
  ArgumentListNode* arguments = new (Z) ArgumentListNode(call_pos);

  String& method_name = String::Handle(Z);
  if (prefix == NULL || !prefix->is_deferred_load()) {
    method_name = Library::PrivateCoreLibName(Symbols::ThrowNew()).raw();
  } else {
    arguments->Add(new (Z) LiteralNode(call_pos, *prefix));
    method_name =
        Library::PrivateCoreLibName(Symbols::ThrowNewIfNotLoaded()).raw();
  }
  // Object receiver.
  // If the function is external and dynamic, pass the actual receiver,
  // otherwise, pass a class literal of the unresolved method's owner.
  if ((func != NULL) && !func->IsNull() && func->is_external() &&
      !func->is_static()) {
    arguments->Add(LoadReceiver(func->token_pos()));
  } else {
    AbstractType& type = AbstractType::ZoneHandle(Z);
    type ^= Type::New(cls, TypeArguments::Handle(Z), call_pos, Heap::kOld);
    type ^= CanonicalizeType(type);
    arguments->Add(new (Z) LiteralNode(call_pos, type));
  }
  // String memberName.
  arguments->Add(new (Z) LiteralNode(
      call_pos, String::ZoneHandle(Z, Symbols::New(T, function_name))));
  // Smi invocation_type.
  if (cls.IsTopLevel()) {
    ASSERT(im_level == InvocationMirror::kStatic ||
           im_level == InvocationMirror::kTopLevel);
    im_level = InvocationMirror::kTopLevel;
  }
  arguments->Add(new (Z) LiteralNode(
      call_pos, Smi::ZoneHandle(Z, Smi::New(InvocationMirror::EncodeType(
                                       im_level, im_kind)))));
  // Type arguments.
  arguments->Add(new (Z) LiteralNode(
      call_pos, function_arguments == NULL
                    ? TypeArguments::ZoneHandle(Z, TypeArguments::null())
                    : function_arguments->type_arguments()));
  // List arguments.
  if (function_arguments == NULL) {
    arguments->Add(new (Z) LiteralNode(call_pos, Object::null_array()));
  } else {
    ArrayNode* array =
        new (Z) ArrayNode(call_pos, Type::ZoneHandle(Z, Type::ArrayType()),
                          function_arguments->nodes());
    arguments->Add(array);
  }
  // List argumentNames.
  if (function_arguments == NULL) {
    arguments->Add(new (Z) LiteralNode(call_pos, Object::null_array()));
  } else {
    arguments->Add(new (Z) LiteralNode(call_pos, function_arguments->names()));
  }
  return MakeStaticCall(Symbols::NoSuchMethodError(), method_name, arguments);
}

AstNode* Parser::ParseBinaryExpr(int min_preced) {
  TRACE_PARSER("ParseBinaryExpr");
  ASSERT(min_preced >= Token::Precedence(Token::kIFNULL));
  AstNode* left_operand = ParseUnaryExpr();
  if (left_operand->IsPrimaryNode() &&
      (left_operand->AsPrimaryNode()->IsSuper())) {
    ReportError(left_operand->token_pos(), "illegal use of 'super'");
  }
  int current_preced = Token::Precedence(CurrentToken());
  while (current_preced >= min_preced) {
    while (Token::Precedence(CurrentToken()) == current_preced) {
      Token::Kind op_kind = CurrentToken();
      const TokenPosition op_pos = TokenPos();
      ConsumeToken();
      AstNode* right_operand = NULL;
      if ((op_kind != Token::kIS) && (op_kind != Token::kAS)) {
        right_operand = ParseBinaryExpr(current_preced + 1);
      } else {
        // For 'is' and 'as' we expect the right operand to be a type.
        if ((op_kind == Token::kIS) && (CurrentToken() == Token::kNOT)) {
          ConsumeToken();
          op_kind = Token::kISNOT;
        }
        const TokenPosition type_pos = TokenPos();
        const AbstractType& type = AbstractType::ZoneHandle(
            Z, ParseTypeOrFunctionType(false, ClassFinalizer::kCanonicalize));
        if (!type.IsInstantiated() && (FunctionLevel() > 0)) {
          // Make sure that the instantiators are captured.
          CaptureAllInstantiators();
        }
        right_operand = new (Z) TypeNode(type_pos, type);
        // In production mode, the type may be malformed.
        // In checked mode, the type may be malformed or malbounded.
        if (type.IsMalformedOrMalbounded()) {
          // Note that a type error is thrown in a type test or in
          // a type cast even if the tested value is null.
          // We need to evaluate the left operand for potential
          // side effects.
          LetNode* let = new (Z) LetNode(left_operand->token_pos());
          let->AddNode(left_operand);
          let->AddNode(ThrowTypeError(type_pos, type));
          left_operand = let;
          break;  // Type checks and casts can't be chained.
        }
      }
      if (Token::IsRelationalOperator(op_kind) ||
          Token::IsTypeTestOperator(op_kind) ||
          Token::IsTypeCastOperator(op_kind) ||
          Token::IsEqualityOperator(op_kind)) {
        left_operand = new (Z)
            ComparisonNode(op_pos, op_kind, left_operand, right_operand);
        break;  // Equality and relational operators cannot be chained.
      } else {
        left_operand =
            OptimizeBinaryOpNode(op_pos, op_kind, left_operand, right_operand);
      }
    }
    current_preced--;
  }
  return left_operand;
}

AstNode* Parser::ParseAwaitableExprList() {
  TRACE_PARSER("ParseAwaitableExprList");
  SequenceNode* preamble = NULL;
  AstNode* expressions =
      ParseAwaitableExpr(kAllowConst, kConsumeCascades, &preamble);
  if (preamble != NULL) {
    preamble->Add(expressions);
    expressions = preamble;
  }
  if (CurrentToken() == Token::kCOMMA) {
    // Collect comma-separated expressions in a non scope owning sequence node.
    SequenceNode* list = new (Z) SequenceNode(TokenPos(), NULL);
    list->Add(expressions);
    while (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
      preamble = NULL;
      AstNode* expr =
          ParseAwaitableExpr(kAllowConst, kConsumeCascades, &preamble);
      if (preamble != NULL) {
        list->Add(preamble);
      }
      list->Add(expr);
    }
    expressions = list;
  }
  return expressions;
}

void Parser::EnsureExpressionTemp() {
  // Temporary used later by the flow_graph_builder.
  parsed_function()->EnsureExpressionTemp();
}

LocalVariable* Parser::CreateTempConstVariable(TokenPosition token_pos,
                                               const char* s) {
  char name[64];
  OS::SNPrint(name, 64, ":%s%" Pd "", s, token_pos.value());
  LocalVariable* temp = new (Z) LocalVariable(
      token_pos, token_pos, String::ZoneHandle(Z, Symbols::New(T, name)),
      Object::dynamic_type());
  temp->set_is_final();
  current_block_->scope->AddVariable(temp);
  return temp;
}

AstNode* Parser::OptimizeBinaryOpNode(TokenPosition op_pos,
                                      Token::Kind binary_op,
                                      AstNode* lhs,
                                      AstNode* rhs) {
  LiteralNode* lhs_literal = lhs->AsLiteralNode();
  LiteralNode* rhs_literal = rhs->AsLiteralNode();
  if ((lhs_literal != NULL) && (rhs_literal != NULL)) {
    if (lhs_literal->literal().IsDouble() &&
        rhs_literal->literal().IsDouble()) {
      double left_double = Double::Cast(lhs_literal->literal()).value();
      double right_double = Double::Cast(rhs_literal->literal()).value();
      if (binary_op == Token::kDIV) {
        const Double& dbl_obj = Double::ZoneHandle(
            Z, Double::NewCanonical((left_double / right_double)));
        return new (Z) LiteralNode(op_pos, dbl_obj);
      }
    }
  }
  if (binary_op == Token::kBIT_AND) {
    // Normalize so that rhs is a literal if any is.
    if ((rhs_literal == NULL) && (lhs_literal != NULL)) {
      // Swap.
      LiteralNode* temp = rhs_literal;
      rhs_literal = lhs_literal;
      lhs_literal = temp;
    }
  }
  if (binary_op == Token::kIFNULL) {
    // Handle a ?? b.
    if ((lhs->EvalConstExpr() != NULL) && (rhs->EvalConstExpr() != NULL)) {
      Instance& expr_value = Instance::ZoneHandle(
          Z, EvaluateConstExpr(lhs->token_pos(), lhs).raw());
      if (expr_value.IsNull()) {
        expr_value = EvaluateConstExpr(rhs->token_pos(), rhs).raw();
      }
      return new (Z) LiteralNode(op_pos, expr_value);
    }

    LetNode* result = new (Z) LetNode(op_pos);
    LocalVariable* left_temp = result->AddInitializer(lhs);
    left_temp->set_is_final();
    const TokenPosition no_pos = TokenPosition::kNoSource;
    LiteralNode* null_operand =
        new (Z) LiteralNode(no_pos, Object::null_instance());
    LoadLocalNode* load_left_temp = new (Z) LoadLocalNode(no_pos, left_temp);
    ComparisonNode* null_compare = new (Z)
        ComparisonNode(no_pos, Token::kNE_STRICT, load_left_temp, null_operand);
    result->AddNode(
        new (Z) ConditionalExprNode(op_pos, null_compare, load_left_temp, rhs));
    return result;
  }
  return new (Z) BinaryOpNode(op_pos, binary_op, lhs, rhs);
}

AstNode* Parser::ExpandAssignableOp(TokenPosition op_pos,
                                    Token::Kind assignment_op,
                                    AstNode* lhs,
                                    AstNode* rhs) {
  TRACE_PARSER("ExpandAssignableOp");
  switch (assignment_op) {
    case Token::kASSIGN:
      return rhs;
    case Token::kASSIGN_ADD:
      return new (Z) BinaryOpNode(op_pos, Token::kADD, lhs, rhs);
    case Token::kASSIGN_SUB:
      return new (Z) BinaryOpNode(op_pos, Token::kSUB, lhs, rhs);
    case Token::kASSIGN_MUL:
      return new (Z) BinaryOpNode(op_pos, Token::kMUL, lhs, rhs);
    case Token::kASSIGN_TRUNCDIV:
      return new (Z) BinaryOpNode(op_pos, Token::kTRUNCDIV, lhs, rhs);
    case Token::kASSIGN_DIV:
      return new (Z) BinaryOpNode(op_pos, Token::kDIV, lhs, rhs);
    case Token::kASSIGN_MOD:
      return new (Z) BinaryOpNode(op_pos, Token::kMOD, lhs, rhs);
    case Token::kASSIGN_SHR:
      return new (Z) BinaryOpNode(op_pos, Token::kSHR, lhs, rhs);
    case Token::kASSIGN_SHL:
      return new (Z) BinaryOpNode(op_pos, Token::kSHL, lhs, rhs);
    case Token::kASSIGN_OR:
      return new (Z) BinaryOpNode(op_pos, Token::kBIT_OR, lhs, rhs);
    case Token::kASSIGN_AND:
      return new (Z) BinaryOpNode(op_pos, Token::kBIT_AND, lhs, rhs);
    case Token::kASSIGN_XOR:
      return new (Z) BinaryOpNode(op_pos, Token::kBIT_XOR, lhs, rhs);
    case Token::kASSIGN_COND:
      return new (Z) BinaryOpNode(op_pos, Token::kIFNULL, lhs, rhs);
    default:
      ReportError(op_pos,
                  "internal error: ExpandAssignableOp '%s' unimplemented",
                  Token::Name(assignment_op));
      UNIMPLEMENTED();
      return NULL;
  }
}

// Evaluates the value of the compile time constant expression
// and returns a literal node for the value.
LiteralNode* Parser::FoldConstExpr(TokenPosition expr_pos, AstNode* expr) {
  if (expr->IsLiteralNode()) {
    return expr->AsLiteralNode();
  }
  if (expr->EvalConstExpr() == NULL) {
    ReportError(expr_pos, "expression is not a valid compile-time constant");
  }
  return new (Z) LiteralNode(expr_pos, EvaluateConstExpr(expr_pos, expr));
}

LetNode* Parser::PrepareCompoundAssignmentNodes(AstNode** expr) {
  AstNode* node = *expr;
  TokenPosition token_pos = node->token_pos();
  LetNode* result = new (Z) LetNode(token_pos);
  if (node->IsLoadIndexedNode()) {
    LoadIndexedNode* load_indexed = node->AsLoadIndexedNode();
    AstNode* array = load_indexed->array();
    AstNode* index = load_indexed->index_expr();
    if (!IsSimpleLocalOrLiteralNode(load_indexed->array())) {
      LocalVariable* t0 = result->AddInitializer(load_indexed->array());
      array = new (Z) LoadLocalNode(token_pos, t0);
    }
    if (!IsSimpleLocalOrLiteralNode(load_indexed->index_expr())) {
      LocalVariable* t1 = result->AddInitializer(load_indexed->index_expr());
      index = new (Z) LoadLocalNode(token_pos, t1);
    }
    *expr = new (Z)
        LoadIndexedNode(token_pos, array, index, load_indexed->super_class());
    return result;
  }
  if (node->IsInstanceGetterNode()) {
    InstanceGetterNode* getter = node->AsInstanceGetterNode();
    AstNode* receiver = getter->receiver();
    if (!IsSimpleLocalOrLiteralNode(getter->receiver())) {
      LocalVariable* t0 = result->AddInitializer(getter->receiver());
      receiver = new (Z) LoadLocalNode(token_pos, t0);
    }
    *expr = new (Z) InstanceGetterNode(
        token_pos, receiver, getter->field_name(), getter->is_conditional());
    return result;
  }
  return result;
}

// Check whether the syntax of expression expr is a grammatically legal
// assignable expression. This check is used to detect situations where
// the expression itself is assignable, but the source is grammatically
// wrong. The AST representation of an expression cannot distinguish
// between x = 0 and (x) = 0. The latter is illegal.
// A syntactically legal assignable expression always ends with an
// identifier token or a ] token. We rewind the token iterator and
// check whether the token before end_pos is an identifier or ].
bool Parser::IsLegalAssignableSyntax(AstNode* expr, TokenPosition end_pos) {
  ASSERT(expr->token_pos().IsReal());
  ASSERT(expr->token_pos() < end_pos);
  SetPosition(expr->token_pos());
  Token::Kind token = Token::kILLEGAL;
  while (TokenPos() < end_pos) {
    token = CurrentToken();
    ConsumeToken();
  }
  ASSERT(TokenPos() == end_pos);
  return Token::IsIdentifier(token) || (token == Token::kRBRACK);
}

AstNode* Parser::CreateAssignmentNode(AstNode* original,
                                      AstNode* rhs,
                                      const String* left_ident,
                                      TokenPosition left_pos,
                                      bool is_compound /* = false */) {
  AstNode* result = original->MakeAssignmentNode(rhs);
  if (result == NULL) {
    String& name = String::ZoneHandle(Z);
    const Class* target_cls = &current_class();
    if (original->IsTypeNode()) {
      name = Symbols::New(T, original->AsTypeNode()->TypeName());
    } else if (original->IsLoadStaticFieldNode()) {
      name = original->AsLoadStaticFieldNode()->field().name();
      target_cls =
          &Class::Handle(Z, original->AsLoadStaticFieldNode()->field().Owner());
    } else if ((left_ident != NULL) &&
               (original->IsLiteralNode() || original->IsLoadLocalNode())) {
      name = left_ident->raw();
    }
    if (name.IsNull()) {
      ReportError(left_pos, "expression is not assignable");
    }
    ArgumentListNode* error_arguments =
        new (Z) ArgumentListNode(rhs->token_pos());
    error_arguments->Add(rhs);
    result = ThrowNoSuchMethodError(
        original->token_pos(), *target_cls,
        String::Handle(Z, Field::SetterSymbol(name)), error_arguments,
        InvocationMirror::kStatic,
        original->IsLoadLocalNode() ? InvocationMirror::kLocalVar
                                    : InvocationMirror::kSetter,
        NULL);  // No existing function.
  }
  // The compound assignment operator a ??= b is different from other
  // a op= b assignments. If a is non-null, the assignment to a must be
  // dropped:
  // normally: a op= b ==> a = a op b
  // however:  a ??= b ==> a ?? (a = b)
  // Therefore, we need to transform a = (a ?? b) into a ?? (a = b)
  if (is_compound && rhs->IsBinaryOpNode() &&
      (rhs->AsBinaryOpNode()->kind() == Token::kIFNULL)) {
    BinaryOpNode* ifnull = rhs->AsBinaryOpNode();
    AstNode* modified_assign =
        CreateAssignmentNode(original, ifnull->right(), left_ident, left_pos);
    result = OptimizeBinaryOpNode(ifnull->token_pos(), ifnull->kind(),
                                  ifnull->left(), modified_assign);
  }
  return result;
}

AstNode* Parser::ParseCascades(AstNode* expr) {
  TokenPosition cascade_pos = TokenPos();
  LetNode* cascade = new (Z) LetNode(cascade_pos);
  LocalVariable* cascade_receiver_var = cascade->AddInitializer(expr);
  while (CurrentToken() == Token::kCASCADE) {
    cascade_pos = TokenPos();
    LoadLocalNode* load_cascade_receiver =
        new (Z) LoadLocalNode(cascade_pos, cascade_receiver_var);
    if (Token::IsIdentifier(LookaheadToken(1))) {
      // Replace .. with . for ParseSelectors().
      token_kind_ = Token::kPERIOD;
    } else if (LookaheadToken(1) == Token::kLBRACK) {
      ConsumeToken();
    } else {
      ReportError("identifier or [ expected after ..");
    }
    String* expr_ident =
        Token::IsIdentifier(CurrentToken()) ? CurrentLiteral() : NULL;
    const TokenPosition expr_pos = TokenPos();
    expr = ParseSelectors(load_cascade_receiver, true);

    // Assignments after a cascade are part of the cascade. The
    // assigned expression must not contain cascades.
    if (Token::IsAssignmentOperator(CurrentToken())) {
      Token::Kind assignment_op = CurrentToken();
      const TokenPosition assignment_pos = TokenPos();
      ConsumeToken();
      AstNode* right_expr = ParseExpr(kAllowConst, kNoCascades);
      if (assignment_op != Token::kASSIGN) {
        // Compound assignment: store inputs with side effects into
        // temporary locals.
        LetNode* let_expr = PrepareCompoundAssignmentNodes(&expr);
        right_expr =
            ExpandAssignableOp(assignment_pos, assignment_op, expr, right_expr);
        AstNode* assign_expr =
            CreateAssignmentNode(expr, right_expr, expr_ident, expr_pos, true);
        ASSERT(assign_expr != NULL);
        let_expr->AddNode(assign_expr);
        expr = let_expr;
      } else {
        right_expr =
            ExpandAssignableOp(assignment_pos, assignment_op, expr, right_expr);
        AstNode* assign_expr =
            CreateAssignmentNode(expr, right_expr, expr_ident, expr_pos);
        ASSERT(assign_expr != NULL);
        expr = assign_expr;
      }
    }
    cascade->AddNode(expr);
  }
  // The result is an expression with the (side effects of the) cascade
  // sequence followed by the (value of the) receiver temp variable load.
  cascade->AddNode(new (Z) LoadLocalNode(cascade_pos, cascade_receiver_var));
  return cascade;
}

// Convert loading of a static const field into a literal node.
static AstNode* LiteralIfStaticConst(Zone* zone, AstNode* expr) {
  if (expr->IsLoadStaticFieldNode()) {
    const Field& field = expr->AsLoadStaticFieldNode()->field();
    if (field.is_const() &&
        !expr->AsLoadStaticFieldNode()->is_deferred_reference()) {
      ASSERT(field.StaticValue() != Object::sentinel().raw());
      ASSERT(field.StaticValue() != Object::transition_sentinel().raw());
      return new (zone) LiteralNode(
          expr->token_pos(), Instance::ZoneHandle(zone, field.StaticValue()));
    }
  }
  return expr;
}

AstNode* Parser::ParseAwaitableExpr(bool require_compiletime_const,
                                    bool consume_cascades,
                                    SequenceNode** await_preamble) {
  TRACE_PARSER("ParseAwaitableExpr");
  BoolScope saved_seen_await(&parsed_function()->have_seen_await_expr_, false);
  AstNode* expr = ParseExpr(require_compiletime_const, consume_cascades);
  if (parsed_function()->have_seen_await()) {
    // Make sure we do not reuse the scope to avoid creating contexts that we
    // are unaware of, i.e, creating contexts that have already been covered.
    // See FlowGraphBuilder::VisitSequenceNode() for details on when contexts
    // are created.
    OpenBlock();
    AwaitTransformer at(current_block_->statements, async_temp_scope_);
    AstNode* result = at.Transform(expr);
    SequenceNode* preamble = CloseBlock();
    if (await_preamble == NULL) {
      current_block_->statements->Add(preamble);
    } else {
      *await_preamble = preamble;
    }
    return result;
  }
  return expr;
}

AstNode* Parser::ParseExpr(bool require_compiletime_const,
                           bool consume_cascades) {
  TRACE_PARSER("ParseExpr");
  String* expr_ident =
      Token::IsIdentifier(CurrentToken()) ? CurrentLiteral() : NULL;
  const TokenPosition expr_pos = TokenPos();

  RecursionChecker rc(this);

  if (CurrentToken() == Token::kTHROW) {
    if (require_compiletime_const) {
      ReportError("'throw expr' is not a valid compile-time constant");
    }
    ConsumeToken();
    if (CurrentToken() == Token::kSEMICOLON) {
      ReportError("expression expected after throw");
    }
    AstNode* expr = ParseExpr(require_compiletime_const, consume_cascades);
    return new (Z) ThrowNode(expr_pos, expr, NULL);
  }

  if (require_compiletime_const) {
    // Check whether we already have evaluated a compile-time constant
    // at this source location.
    Instance& existing_const = Instance::ZoneHandle(Z);
    if (GetCachedConstant(expr_pos, &existing_const)) {
      SkipConditionalExpr();
      return new (Z) LiteralNode(expr_pos, existing_const);
    }
  }

  AstNode* expr = ParseConditionalExpr();
  if (!Token::IsAssignmentOperator(CurrentToken())) {
    if ((CurrentToken() == Token::kCASCADE) && consume_cascades) {
      return ParseCascades(expr);
    }
    if (require_compiletime_const) {
      expr = FoldConstExpr(expr_pos, expr);
    } else {
      expr = LiteralIfStaticConst(Z, expr);
    }
    return expr;
  }
  // Assignment expressions.
  if (!IsLegalAssignableSyntax(expr, TokenPos())) {
    ReportError(expr_pos, "expression is not assignable");
  }
  const Token::Kind assignment_op = CurrentToken();
  const TokenPosition assignment_pos = TokenPos();
  if (require_compiletime_const) {
    ReportError(assignment_pos,
                "expression is not a valid compile-time constant");
  }
  ConsumeToken();
  AstNode* right_expr = ParseExpr(require_compiletime_const, consume_cascades);
  if (assignment_op != Token::kASSIGN) {
    // Compound assignment: store inputs with side effects into temp. locals.
    LetNode* let_expr = PrepareCompoundAssignmentNodes(&expr);
    AstNode* assigned_value =
        ExpandAssignableOp(assignment_pos, assignment_op, expr, right_expr);
    AstNode* assign_expr =
        CreateAssignmentNode(expr, assigned_value, expr_ident, expr_pos, true);
    ASSERT(assign_expr != NULL);
    let_expr->AddNode(assign_expr);
    return let_expr;
  } else {
    AstNode* assigned_value = LiteralIfStaticConst(Z, right_expr);
    AstNode* assign_expr =
        CreateAssignmentNode(expr, assigned_value, expr_ident, expr_pos);
    ASSERT(assign_expr != NULL);
    return assign_expr;
  }
}

LiteralNode* Parser::ParseConstExpr() {
  TRACE_PARSER("ParseConstExpr");
  TokenPosition expr_pos = TokenPos();
  AstNode* expr = ParseExpr(kRequireConst, kNoCascades);
  if (!expr->IsLiteralNode()) {
    ReportError(expr_pos, "expression must be a compile-time constant");
  }
  return expr->AsLiteralNode();
}

AstNode* Parser::ParseConditionalExpr() {
  TRACE_PARSER("ParseConditionalExpr");
  const TokenPosition expr_pos = TokenPos();
  AstNode* expr = ParseBinaryExpr(Token::Precedence(Token::kIFNULL));
  if (CurrentToken() == Token::kCONDITIONAL) {
    EnsureExpressionTemp();
    ConsumeToken();
    AstNode* expr1 = ParseExpr(kAllowConst, kNoCascades);
    ExpectToken(Token::kCOLON);
    AstNode* expr2 = ParseExpr(kAllowConst, kNoCascades);
    expr = new (Z) ConditionalExprNode(expr_pos, expr, expr1, expr2);
  }
  return expr;
}

AstNode* Parser::ParseUnaryExpr() {
  TRACE_PARSER("ParseUnaryExpr");
  AstNode* expr = NULL;
  const TokenPosition op_pos = TokenPos();
  if (IsAwaitKeyword()) {
    TRACE_PARSER("ParseAwaitExpr");
    if (!innermost_function().IsAsyncFunction() &&
        !innermost_function().IsAsyncClosure() &&
        !innermost_function().IsAsyncGenerator() &&
        !innermost_function().IsAsyncGenClosure()) {
      ReportError("await operator is only allowed in an asynchronous function");
    }
    ConsumeToken();
    parsed_function()->record_await();

    LocalVariable* saved_try_ctx;
    LocalVariable* async_saved_try_ctx;
    LocalVariable* outer_saved_try_ctx;
    LocalVariable* outer_async_saved_try_ctx;
    CheckAsyncOpInTryBlock(&saved_try_ctx, &async_saved_try_ctx,
                           &outer_saved_try_ctx, &outer_async_saved_try_ctx);
    expr = new (Z) AwaitNode(op_pos, ParseUnaryExpr(), saved_try_ctx,
                             async_saved_try_ctx, outer_saved_try_ctx,
                             outer_async_saved_try_ctx, current_block_->scope);
  } else if (IsPrefixOperator(CurrentToken())) {
    Token::Kind unary_op = CurrentToken();
    if (unary_op == Token::kSUB) {
      unary_op = Token::kNEGATE;
    }
    ConsumeToken();
    expr = ParseUnaryExpr();
    if (expr->IsPrimaryNode() && (expr->AsPrimaryNode()->IsSuper())) {
      expr = BuildUnarySuperOperator(unary_op, expr->AsPrimaryNode());
    } else {
      expr = UnaryOpNode::UnaryOpOrLiteral(op_pos, unary_op, expr);
    }
  } else if (IsIncrementOperator(CurrentToken())) {
    Token::Kind incr_op = CurrentToken();
    ConsumeToken();
    String* expr_ident =
        Token::IsIdentifier(CurrentToken()) ? CurrentLiteral() : NULL;
    const TokenPosition expr_pos = TokenPos();
    expr = ParseUnaryExpr();
    if (!IsLegalAssignableSyntax(expr, TokenPos())) {
      ReportError(expr_pos, "expression is not assignable");
    }
    // Is prefix.
    LetNode* let_expr = PrepareCompoundAssignmentNodes(&expr);
    Token::Kind binary_op =
        (incr_op == Token::kINCR) ? Token::kADD : Token::kSUB;
    BinaryOpNode* add = new (Z) BinaryOpNode(
        op_pos, binary_op, expr,
        new (Z) LiteralNode(op_pos, Smi::ZoneHandle(Z, Smi::New(1))));
    AstNode* store =
        CreateAssignmentNode(expr, add, expr_ident, expr_pos, true);
    ASSERT(store != NULL);
    let_expr->AddNode(store);
    expr = let_expr;
  } else {
    expr = ParsePostfixExpr();
  }
  return expr;
}

ArgumentListNode* Parser::ParseActualParameters(
    ArgumentListNode* implicit_arguments,
    const TypeArguments& func_type_args,
    bool require_const) {
  TRACE_PARSER("ParseActualParameters");
  ASSERT(CurrentToken() == Token::kLPAREN);
  const bool saved_mode = SetAllowFunctionLiterals(true);
  ArgumentListNode* arguments;
  if (implicit_arguments == NULL) {
    // TODO(regis): When require_const is true, do we need to check that
    // func_type_args are null or instantiated?
    arguments = new (Z) ArgumentListNode(TokenPos(), func_type_args);
  } else {
    // If implicit arguments are provided, they include type arguments (if any).
    ASSERT(func_type_args.IsNull());
    arguments = implicit_arguments;
  }
  const GrowableObjectArray& names =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New(Heap::kOld));
  bool named_argument_seen = false;
  if (LookaheadToken(1) != Token::kRPAREN) {
    String& arg_name = String::Handle(Z);
    do {
      ASSERT((CurrentToken() == Token::kLPAREN) ||
             (CurrentToken() == Token::kCOMMA));
      ConsumeToken();
      if (CurrentToken() == Token::kRPAREN) {
        // Allow trailing comma.
        break;
      }
      if (IsIdentifier() && (LookaheadToken(1) == Token::kCOLON)) {
        named_argument_seen = true;
        // The canonicalization of the arguments descriptor array built in
        // the code generator requires that the names are symbols, i.e.
        // canonicalized strings.
        ASSERT(CurrentLiteral()->IsSymbol());
        for (int i = 0; i < names.Length(); i++) {
          arg_name ^= names.At(i);
          if (CurrentLiteral()->Equals(arg_name)) {
            ReportError("duplicate named argument");
          }
        }
        names.Add(*CurrentLiteral(), Heap::kOld);
        ConsumeToken();  // ident.
        ConsumeToken();  // colon.
      } else if (named_argument_seen) {
        ReportError("named argument expected");
      }
      arguments->Add(ParseExpr(require_const, kConsumeCascades));
    } while (CurrentToken() == Token::kCOMMA);
  } else {
    ConsumeToken();
  }
  ExpectToken(Token::kRPAREN);
  SetAllowFunctionLiterals(saved_mode);
  if (named_argument_seen) {
    arguments->set_names(Array::Handle(Z, Array::MakeFixedLength(names)));
  }
  return arguments;
}

AstNode* Parser::ParseStaticCall(const Class& cls,
                                 const String& func_name,
                                 TokenPosition ident_pos,
                                 const TypeArguments& func_type_args,
                                 const LibraryPrefix* prefix) {
  TRACE_PARSER("ParseStaticCall");
  const TokenPosition call_pos = TokenPos();
  ASSERT(CurrentToken() == Token::kLPAREN);
  ArgumentListNode* arguments =
      ParseActualParameters(NULL, func_type_args, kAllowConst);
  const int num_arguments = arguments->length();
  const Function& func = Function::ZoneHandle(
      Z, Resolver::ResolveStatic(cls, func_name, func_type_args.Length(),
                                 num_arguments, arguments->names()));
  if (func.IsNull()) {
    // Check if there is a static field of the same name, it could be a closure
    // and so we try and invoke the closure.
    AstNode* closure = NULL;
    const Field& field = Field::ZoneHandle(Z, cls.LookupStaticField(func_name));
    Function& func = Function::ZoneHandle(Z);
    if (field.IsNull()) {
      // No field, check if we have an explicit getter function.
      const String& getter_name =
          String::ZoneHandle(Z, Field::LookupGetterSymbol(func_name));
      if (!getter_name.IsNull()) {
        const int kTypeArgsLen = 0;   // no type arguments.
        const int kNumArguments = 0;  // no arguments.
        func = Resolver::ResolveStatic(cls, getter_name, kTypeArgsLen,
                                       kNumArguments, Object::empty_array());
        if (!func.IsNull()) {
          ASSERT(func.kind() != RawFunction::kImplicitStaticFinalGetter);
          closure = new (Z)
              StaticGetterNode(call_pos, NULL, Class::ZoneHandle(Z, cls.raw()),
                               func_name, StaticGetterSetter::kStatic);
          return BuildClosureCall(call_pos, closure, arguments);
        }
      }
    } else {
      closure = GenerateStaticFieldLookup(field, call_pos);
      return BuildClosureCall(call_pos, closure, arguments);
    }
    // Could not resolve static method: throw a NoSuchMethodError.
    return ThrowNoSuchMethodError(ident_pos, cls, func_name, arguments,
                                  InvocationMirror::kStatic,
                                  InvocationMirror::kMethod,
                                  NULL,  // No existing function.
                                  prefix);
  } else if (cls.IsTopLevel() && (cls.library() == Library::CoreLibrary()) &&
             (func.name() == Symbols::Identical().raw()) &&
             func_type_args.IsNull()) {
    // This is the predefined toplevel function identical(a,b).
    // Create a comparison node instead of a static call to the function.
    ASSERT(num_arguments == 2);

    // If both arguments are constant expressions of type string,
    // evaluate and canonicalize them.
    // This guarantees that identical("ab", "a"+"b") is true.
    // An alternative way to guarantee this would be to introduce
    // an AST node that canonicalizes a value.
    AstNode* arg0 = arguments->NodeAt(0);
    const Instance* val0 = arg0->EvalConstExpr();
    if ((val0 != NULL) && (val0->IsString())) {
      AstNode* arg1 = arguments->NodeAt(1);
      const Instance* val1 = arg1->EvalConstExpr();
      if ((val1 != NULL) && (val1->IsString())) {
        arguments->SetNodeAt(
            0, new (Z) LiteralNode(arg0->token_pos(),
                                   EvaluateConstExpr(arg0->token_pos(), arg0)));
        arguments->SetNodeAt(
            1, new (Z) LiteralNode(arg1->token_pos(),
                                   EvaluateConstExpr(arg1->token_pos(), arg1)));
      }
    }
    return new (Z) ComparisonNode(ident_pos, Token::kEQ_STRICT,
                                  arguments->NodeAt(0), arguments->NodeAt(1));
  }
  return new (Z)
      StaticCallNode(ident_pos, func, arguments, StaticCallNode::kStatic);
}

AstNode* Parser::ParseInstanceCall(AstNode* receiver,
                                   const String& func_name,
                                   TokenPosition ident_pos,
                                   const TypeArguments& func_type_args,
                                   bool is_conditional) {
  TRACE_PARSER("ParseInstanceCall");
  CheckToken(Token::kLPAREN);
  ArgumentListNode* arguments =
      ParseActualParameters(NULL, func_type_args, kAllowConst);
  return new (Z) InstanceCallNode(ident_pos, receiver, func_name, arguments,
                                  is_conditional);
}

AstNode* Parser::ParseClosureCall(AstNode* closure,
                                  const TypeArguments& func_type_args) {
  TRACE_PARSER("ParseClosureCall");
  const TokenPosition call_pos = TokenPos();
  ASSERT(CurrentToken() == Token::kLPAREN);
  ArgumentListNode* arguments =
      ParseActualParameters(NULL, func_type_args, kAllowConst);
  return BuildClosureCall(call_pos, closure, arguments);
}

AstNode* Parser::GenerateStaticFieldLookup(const Field& field,
                                           TokenPosition ident_pos) {
  // If the static field has an initializer, initialize the field at compile
  // time, which is only possible if the field is const.
  AstNode* initializing_getter = RunStaticFieldInitializer(field, ident_pos);
  if (initializing_getter != NULL) {
    // The field is not yet initialized and could not be initialized at compile
    // time. The getter will initialize the field.
    return initializing_getter;
  }
  // The field is initialized.
  ASSERT(field.is_static());
  const Class& field_owner = Class::ZoneHandle(Z, field.Owner());
  const String& field_name = String::ZoneHandle(Z, field.name());
  const String& getter_name =
      String::Handle(Z, Field::GetterSymbol(field_name));
  const Function& getter =
      Function::Handle(Z, field_owner.LookupStaticFunction(getter_name));
  // Never load field directly if there is a getter (deterministic AST).
  if (getter.IsNull() || field.is_const()) {
    return new (Z)
        LoadStaticFieldNode(ident_pos, Field::ZoneHandle(Z, field.raw()));
  } else {
    ASSERT(getter.kind() == RawFunction::kImplicitStaticFinalGetter);
    return new (Z)
        StaticGetterNode(ident_pos,
                         NULL,  // Receiver.
                         field_owner, field_name, StaticGetterSetter::kStatic);
  }
}

// Reference to 'field_name' with explicit class as primary.
AstNode* Parser::GenerateStaticFieldAccess(const Class& cls,
                                           const String& field_name,
                                           TokenPosition ident_pos) {
  AstNode* access = NULL;
  const Field& field = Field::ZoneHandle(Z, cls.LookupStaticField(field_name));
  Function& func = Function::ZoneHandle(Z);
  if (field.IsNull()) {
    // No field, check if we have an explicit getter function.
    func = cls.LookupGetterFunction(field_name);
    if (func.IsNull() || func.IsDynamicFunction()) {
      // We might be referring to an implicit closure, check to see if
      // there is a function of the same name.
      func = cls.LookupStaticFunction(field_name);
      if (!func.IsNull()) {
        access = CreateImplicitClosureNode(func, ident_pos, NULL);
      } else {
        // No function to closurize found found.
        // This field access may turn out to be a call to the setter.
        // Create a getter call, which may later be turned into
        // a setter call, or else the backend will generate
        // a throw NoSuchMethodError().
        access = new (Z)
            StaticGetterNode(ident_pos, NULL, Class::ZoneHandle(Z, cls.raw()),
                             field_name, StaticGetterSetter::kStatic);
      }
    } else {
      ASSERT(func.kind() != RawFunction::kImplicitStaticFinalGetter);
      access = new (Z)
          StaticGetterNode(ident_pos, NULL, Class::ZoneHandle(Z, cls.raw()),
                           field_name, StaticGetterSetter::kStatic);
    }
  } else {
    access = GenerateStaticFieldLookup(field, ident_pos);
  }
  return access;
}

AstNode* Parser::LoadFieldIfUnresolved(AstNode* node) {
  if (!node->IsPrimaryNode()) {
    return node;
  }
  PrimaryNode* primary = node->AsPrimaryNode();
  if (primary->primary().IsString()) {
    if (primary->IsSuper()) {
      return primary;
    }
    // In a static method, evaluation of an unresolved identifier causes a
    // NoSuchMethodError to be thrown.
    // In an instance method, we convert this into a getter call
    // for a field (which may be defined in a subclass.)
    const String& name =
        String::Cast(Object::ZoneHandle(primary->primary().raw()));
    if (primary->is_deferred_reference()) {
      StaticGetterNode* getter = new (Z)
          StaticGetterNode(primary->token_pos(),
                           NULL,  // No receiver.
                           Class::ZoneHandle(Z, library_.toplevel_class()),
                           name, StaticGetterSetter::kStatic);
      getter->set_is_deferred(primary->is_deferred_reference());
      return getter;
    } else if (current_function().is_static() ||
               current_function().IsInFactoryScope()) {
      StaticGetterNode* getter =
          new (Z) StaticGetterNode(primary->token_pos(),
                                   NULL,  // No receiver.
                                   Class::ZoneHandle(Z, current_class().raw()),
                                   name, StaticGetterSetter::kStatic);
      getter->set_is_deferred(primary->is_deferred_reference());
      return getter;
    } else {
      AstNode* receiver = LoadReceiver(primary->token_pos());
      return CallGetter(node->token_pos(), receiver, name);
    }
  }
  return primary;
}

AstNode* Parser::LoadClosure(PrimaryNode* primary) {
  ASSERT(primary->primary().IsFunction());
  const Function& func =
      Function::Cast(Object::ZoneHandle(primary->primary().raw()));
  const String& funcname = String::ZoneHandle(Z, func.name());
  if (func.is_static()) {
    // Static function access.
    ClosureNode* closure =
        CreateImplicitClosureNode(func, primary->token_pos(), NULL);
    closure->set_is_deferred(primary->is_deferred_reference());
    return closure;
  } else {
    // Instance function access.
    if (current_function().is_static() ||
        current_function().IsInFactoryScope()) {
      ReportError(primary->token_pos(),
                  "cannot access instance method '%s' from static method",
                  funcname.ToCString());
    }
    AstNode* receiver = LoadReceiver(primary->token_pos());
    return CallGetter(primary->token_pos(), receiver, funcname);
  }
  UNREACHABLE();
  return NULL;
}

AstNode* Parser::LoadTypeParameter(PrimaryNode* primary) {
  const TokenPosition primary_pos = primary->token_pos();
  TypeParameter& type_parameter = TypeParameter::ZoneHandle(Z);
  type_parameter = TypeParameter::Cast(primary->primary()).raw();
  if (type_parameter.IsClassTypeParameter()) {
    if (ParsingStaticMember()) {
      const String& name = String::Handle(Z, type_parameter.name());
      ReportError(primary_pos,
                  "cannot access type parameter '%s' "
                  "from static function",
                  name.ToCString());
    }
    if (FunctionLevel() > 0) {
      // Make sure that the class instantiator is captured.
      CaptureInstantiator();
    }
    type_parameter ^= CanonicalizeType(type_parameter);
  } else {
    ASSERT(type_parameter.IsFunctionTypeParameter());
    if (!FLAG_reify_generic_functions) {
      Type& type = Type::ZoneHandle(Z, Type::DynamicType());
      return new (Z) TypeNode(primary_pos, type);
    }
    if ((FunctionLevel() > 0) && innermost_function().HasGenericParent()) {
      // Make sure that the parent function type arguments are captured.
      CaptureFunctionTypeArguments();
    }
  }
  ASSERT(type_parameter.IsFinalized());
  ASSERT(!type_parameter.IsMalformed());
  return new (Z) TypeNode(primary_pos, type_parameter);
}

AstNode* Parser::ParseSelectors(AstNode* primary, bool is_cascade) {
  AstNode* left = primary;
  while (true) {
    AstNode* selector = NULL;
    if ((CurrentToken() == Token::kPERIOD) ||
        (CurrentToken() == Token::kQM_PERIOD)) {
      // Unconditional or conditional property extraction or method call.
      bool is_conditional = CurrentToken() == Token::kQM_PERIOD;
      ConsumeToken();
      if (left->IsPrimaryNode()) {
        PrimaryNode* primary_node = left->AsPrimaryNode();
        if (primary_node->primary().IsFunction()) {
          left = LoadClosure(primary_node);
        } else if (primary_node->primary().IsTypeParameter()) {
          left = LoadTypeParameter(primary_node);
        } else {
          // Super field access handled in ParseSuperFieldAccess(),
          // super calls handled in ParseSuperCall().
          ASSERT(!primary_node->IsSuper());
          left = LoadFieldIfUnresolved(left);
        }
      }
      const TokenPosition ident_pos = TokenPos();
      String* ident = ExpectIdentifier("identifier expected");
      if (IsArgumentPart()) {
        // Identifier followed by optional type arguments and opening paren:
        // method call.
        TypeArguments& func_type_args = TypeArguments::ZoneHandle(Z);
        if (CurrentToken() == Token::kLT) {
          // Type arguments.
          if (!FLAG_generic_method_syntax) {
            ReportError("generic type arguments not supported.");
          }
          func_type_args = ParseTypeArguments(ClassFinalizer::kCanonicalize);
          if (FLAG_reify_generic_functions) {
            if (!func_type_args.IsNull() && !func_type_args.IsInstantiated() &&
                (FunctionLevel() > 0)) {
              // Make sure that the instantiators are captured.
              CaptureAllInstantiators();
            }
          } else {
            func_type_args = TypeArguments::null();
          }
        }
        PrimaryNode* primary_node = left->AsPrimaryNode();
        if ((primary_node != NULL) && primary_node->primary().IsClass()) {
          // Static method call prefixed with class name.
          const Class& cls = Class::Cast(primary_node->primary());
          selector = ParseStaticCall(cls, *ident, ident_pos, func_type_args,
                                     primary_node->prefix());
        } else {
          if ((primary_node != NULL) && primary_node->is_deferred_reference()) {
            const Class& cls = Class::Handle(library_.toplevel_class());
            selector = ParseStaticCall(cls, *ident, ident_pos, func_type_args,
                                       primary_node->prefix());
          } else {
            selector = ParseInstanceCall(left, *ident, ident_pos,
                                         func_type_args, is_conditional);
          }
        }
      } else {
        // Field access.
        Class& cls = Class::Handle(Z);
        bool is_deferred = false;
        if (left->IsPrimaryNode()) {
          PrimaryNode* primary_node = left->AsPrimaryNode();
          is_deferred = primary_node->is_deferred_reference();
          if (primary_node->primary().IsClass()) {
            // If the primary node referred to a class we are loading a
            // qualified static field.
            cls ^= primary_node->primary().raw();
          } else if (is_deferred) {
            cls = library_.toplevel_class();
          }
        }
        if (cls.IsNull()) {
          // Instance field access.
          selector = new (Z)
              InstanceGetterNode(ident_pos, left, *ident, is_conditional);
        } else {
          // Static field access.
          selector = GenerateStaticFieldAccess(cls, *ident, ident_pos);
          ASSERT(selector != NULL);
          if (selector->IsLoadStaticFieldNode()) {
            selector->AsLoadStaticFieldNode()->set_is_deferred(is_deferred);
          } else if (selector->IsStaticGetterNode()) {
            selector->AsStaticGetterNode()->set_is_deferred(is_deferred);
          }
        }
      }
    } else if (CurrentToken() == Token::kLBRACK) {
      // Super index operator handled in ParseSuperOperator().
      ASSERT(!left->IsPrimaryNode() || !left->AsPrimaryNode()->IsSuper());

      const TokenPosition bracket_pos = TokenPos();
      ConsumeToken();
      left = LoadFieldIfUnresolved(left);
      const bool saved_mode = SetAllowFunctionLiterals(true);
      AstNode* index = ParseExpr(kAllowConst, kConsumeCascades);
      SetAllowFunctionLiterals(saved_mode);
      ExpectToken(Token::kRBRACK);
      AstNode* array = left;
      if (left->IsPrimaryNode()) {
        PrimaryNode* primary_node = left->AsPrimaryNode();
        const TokenPosition primary_pos = primary_node->token_pos();
        if (primary_node->primary().IsFunction()) {
          array = LoadClosure(primary_node);
        } else if (primary_node->primary().IsClass()) {
          const Class& type_class = Class::Cast(primary_node->primary());
          AbstractType& type = Type::ZoneHandle(
              Z, Type::New(type_class, TypeArguments::Handle(Z), primary_pos,
                           Heap::kOld));
          type ^= CanonicalizeType(type);
          // Type may be malbounded, but not malformed.
          ASSERT(!type.IsMalformed());
          array = new (Z) TypeNode(primary_pos, type,
                                   primary_node->is_deferred_reference());
        } else if (primary_node->primary().IsTypeParameter()) {
          array = LoadTypeParameter(primary_node);
        } else {
          UNREACHABLE();  // Internal parser error.
        }
      }
      selector = new (Z)
          LoadIndexedNode(bracket_pos, array, index, Class::ZoneHandle(Z));
    } else if (IsArgumentPart()) {
      TypeArguments& func_type_args = TypeArguments::ZoneHandle(Z);
      if (CurrentToken() == Token::kLT) {
        // Type arguments.
        if (!FLAG_generic_method_syntax) {
          ReportError("generic type arguments not supported.");
        }
        func_type_args = ParseTypeArguments(ClassFinalizer::kCanonicalize);
        if (FLAG_reify_generic_functions) {
          if (!func_type_args.IsNull() && !func_type_args.IsInstantiated() &&
              (FunctionLevel() > 0)) {
            // Make sure that the instantiators are captured.
            CaptureAllInstantiators();
          }
        } else {
          func_type_args = TypeArguments::null();
        }
      }
      if (left->IsPrimaryNode()) {
        PrimaryNode* primary_node = left->AsPrimaryNode();
        const TokenPosition primary_pos = primary_node->token_pos();
        if (primary_node->primary().IsFunction()) {
          const Function& func = Function::Cast(primary_node->primary());
          const String& func_name = String::ZoneHandle(Z, func.name());
          if (func.is_static()) {
            // Parse static function call.
            Class& cls = Class::Handle(Z, func.Owner());
            selector =
                ParseStaticCall(cls, func_name, primary_pos, func_type_args);
          } else {
            // Dynamic function call on implicit "this" parameter.
            if (current_function().is_static()) {
              ReportError(primary_pos,
                          "cannot access instance method '%s' "
                          "from static function",
                          func_name.ToCString());
            }
            selector = ParseInstanceCall(LoadReceiver(primary_pos), func_name,
                                         primary_pos, func_type_args,
                                         false /* is_conditional */);
          }
        } else if (primary_node->primary().IsString()) {
          // Primary is an unresolved name.
          if (primary_node->IsSuper()) {
            ReportError(primary_pos, "illegal use of super");
          }
          const String& name =
              String::Cast(Object::ZoneHandle(primary_node->primary().raw()));
          if (primary_node->is_deferred_reference()) {
            // The static call will be converted to throwing a NSM error.
            const Class& cls = Class::Handle(library_.toplevel_class());
            selector = ParseStaticCall(cls, name, primary_pos, func_type_args,
                                       primary_node->prefix());
          } else if (current_function().is_static()) {
            // The static call will be converted to throwing a NSM error.
            selector = ParseStaticCall(current_class(), name, primary_pos,
                                       func_type_args);
          } else {
            // Treat as call to unresolved (instance) method.
            selector =
                ParseInstanceCall(LoadReceiver(primary_pos), name, primary_pos,
                                  func_type_args, false /* is_conditional */);
          }
        } else if (primary_node->primary().IsTypeParameter()) {
          // TODO(regis): What about the parsed type arguments?
          selector = LoadTypeParameter(primary_node);
        } else if (primary_node->primary().IsClass()) {
          // TODO(regis): What about the parsed type arguments?
          const Class& type_class = Class::Cast(primary_node->primary());
          AbstractType& type = Type::ZoneHandle(
              Z, Type::New(type_class, Object::null_type_arguments(),
                           primary_pos, Heap::kOld));
          type ^= CanonicalizeType(type);
          // Type may be malbounded, but not malformed.
          ASSERT(!type.IsMalformed());
          selector = new (Z) TypeNode(primary_pos, type,
                                      primary_node->is_deferred_reference());
        } else {
          UNREACHABLE();  // Internal parser error.
        }
      } else {
        // Left is not a primary node; this must be a closure call.
        AstNode* closure = left;
        selector = ParseClosureCall(closure, func_type_args);
      }
    } else {
      // No (more) selectors to parse.
      left = LoadFieldIfUnresolved(left);
      if (left->IsPrimaryNode()) {
        PrimaryNode* primary_node = left->AsPrimaryNode();
        const TokenPosition primary_pos = primary->token_pos();
        if (primary_node->primary().IsFunction()) {
          // Treat as implicit closure.
          left = LoadClosure(primary_node);
        } else if (primary_node->primary().IsClass()) {
          const Class& type_class = Class::Cast(primary_node->primary());
          AbstractType& type = Type::ZoneHandle(
              Z, Type::New(type_class, TypeArguments::Handle(Z), primary_pos,
                           Heap::kOld));
          type = CanonicalizeType(type);
          // Type may be malbounded, but not malformed.
          ASSERT(!type.IsMalformed());
          left = new (Z) TypeNode(primary_pos, type,
                                  primary_node->is_deferred_reference());
        } else if (primary_node->primary().IsTypeParameter()) {
          left = LoadTypeParameter(primary_node);
        } else if (primary_node->IsSuper()) {
          // Return "super" to handle unary super operator calls,
          // or to report illegal use of "super" otherwise.
          left = primary_node;
        } else {
          UNREACHABLE();  // Internal parser error.
        }
      }
      // Done parsing selectors.
      return left;
    }
    ASSERT(selector != NULL);
    left = selector;
  }
}

AstNode* Parser::ParsePostfixExpr() {
  TRACE_PARSER("ParsePostfixExpr");
  String* expr_ident =
      Token::IsIdentifier(CurrentToken()) ? CurrentLiteral() : NULL;
  const TokenPosition expr_pos = TokenPos();
  AstNode* expr = ParsePrimary();
  expr = ParseSelectors(expr, false);
  if (IsIncrementOperator(CurrentToken())) {
    TRACE_PARSER("IncrementOperator");
    if (!IsLegalAssignableSyntax(expr, TokenPos())) {
      ReportError(expr_pos, "expression is not assignable");
    }
    Token::Kind incr_op = CurrentToken();
    const TokenPosition op_pos = TokenPos();
    ConsumeToken();
    // Not prefix.
    LetNode* let_expr = PrepareCompoundAssignmentNodes(&expr);
    LocalVariable* temp = let_expr->AddInitializer(expr);
    Token::Kind binary_op =
        (incr_op == Token::kINCR) ? Token::kADD : Token::kSUB;
    BinaryOpNode* add = new (Z) BinaryOpNode(
        op_pos, binary_op, new (Z) LoadLocalNode(op_pos, temp),
        new (Z) LiteralNode(op_pos, Smi::ZoneHandle(Z, Smi::New(1))));
    AstNode* store =
        CreateAssignmentNode(expr, add, expr_ident, expr_pos, true);
    ASSERT(store != NULL);
    // The result is a pair of the (side effects of the) store followed by
    // the (value of the) initial value temp variable load.
    let_expr->AddNode(store);
    let_expr->AddNode(new (Z) LoadLocalNode(op_pos, temp));
    return let_expr;
  }
  return expr;
}

// Resolve the type parameters that may appear in the given signature from the
// signature function and current class.
// Unresolved type classes get resolved later by the class finalizer.
void Parser::ResolveSignatureTypeParameters(const Function& signature) {
  const Function& saved_innermost_function =
      Function::Handle(Z, innermost_function().raw());
  innermost_function_ = signature.raw();
  AbstractType& type = AbstractType::Handle();
  // Resolve upper bounds of function type parameters.
  const intptr_t num_type_params = signature.NumTypeParameters();
  if (num_type_params > 0) {
    TypeParameter& type_param = TypeParameter::Handle();
    const TypeArguments& type_params =
        TypeArguments::Handle(signature.type_parameters());
    for (intptr_t i = 0; i < num_type_params; i++) {
      type_param ^= type_params.TypeAt(i);
      type = type_param.bound();
      ResolveTypeParameters(&type);
      type_param.set_bound(type);
    }
  }
  // Resolve result type.
  type = signature.result_type();
  ResolveTypeParameters(&type);
  signature.set_result_type(type);  // Update type without scope change.
  // Resolve formal parameter types.
  const intptr_t num_parameters = signature.NumParameters();
  for (intptr_t i = 0; i < num_parameters; i++) {
    type = signature.ParameterTypeAt(i);
    ResolveTypeParameters(&type);
    signature.SetParameterTypeAt(i, type);
  }
  innermost_function_ = saved_innermost_function.raw();
}

// Resolve the type parameters that may appear in the given type and in its type
// arguments from the current function and current class.
// Unresolved type classes get resolved later by the class finalizer.
void Parser::ResolveTypeParameters(AbstractType* type) {
  ASSERT(type != NULL);
  if (type->IsResolved()) {
    // Some types are resolved by definition, such as a TypeParameter.
    return;
  }
  // Resolve type class.
  if (!type->HasResolvedTypeClass()) {
    const UnresolvedClass& unresolved_class =
        UnresolvedClass::Handle(Z, type->unresolved_class());
    const String& unresolved_class_name =
        String::Handle(Z, unresolved_class.ident());
    if (unresolved_class.library_or_library_prefix() == Object::null()) {
      // First check if the type is a function type parameter.
      if (InGenericFunctionScope()) {
        intptr_t type_param_func_level = FunctionLevel();
        TypeParameter& type_parameter = TypeParameter::ZoneHandle(
            Z, innermost_function().LookupTypeParameter(
                   unresolved_class_name, &type_param_func_level));
        if (!type_parameter.IsNull()) {
          // A type parameter cannot be parameterized, so make the type
          // malformed if type arguments have previously been parsed.
          if (type->arguments() != TypeArguments::null()) {
            *type = ClassFinalizer::NewFinalizedMalformedType(
                Error::Handle(Z),  // No previous error.
                script_, type_parameter.token_pos(),
                "type parameter '%s' cannot be parameterized",
                String::Handle(Z, type_parameter.name()).ToCString());
            return;
          }
          if (FLAG_reify_generic_functions) {
            ASSERT(!type_parameter.IsMalformed());
            *type = type_parameter.raw();
          } else {
            *type = Type::DynamicType();
          }
          return;
        }
      }
      // Then check if the type is a class type parameter.
      const TypeParameter& type_parameter = TypeParameter::Handle(
          Z, current_class().LookupTypeParameter(unresolved_class_name));
      if (!type_parameter.IsNull()) {
        // A type parameter is considered to be a malformed type when
        // referenced by a static member.
        if (ParsingStaticMember()) {
          *type = ClassFinalizer::NewFinalizedMalformedType(
              Error::Handle(Z),  // No previous error.
              script_, type->token_pos(),
              "type parameter '%s' cannot be referenced "
              "from static member",
              String::Handle(Z, type_parameter.name()).ToCString());
          return;
        }
        // A type parameter cannot be parameterized, so make the type
        // malformed if type arguments have previously been parsed.
        if (type->arguments() != TypeArguments::null()) {
          *type = ClassFinalizer::NewFinalizedMalformedType(
              Error::Handle(Z),  // No previous error.
              script_, type_parameter.token_pos(),
              "type parameter '%s' cannot be parameterized",
              String::Handle(Z, type_parameter.name()).ToCString());
          return;
        }
        *type = type_parameter.raw();
        return;
      }
    }
  }
  // Resolve type arguments, if any.
  if (type->arguments() != TypeArguments::null()) {
    const TypeArguments& arguments =
        TypeArguments::Handle(Z, type->arguments());
    // Already resolved if canonical.
    if (!arguments.IsCanonical()) {
      const intptr_t num_arguments = arguments.Length();
      AbstractType& type_argument = AbstractType::Handle(Z);
      for (intptr_t i = 0; i < num_arguments; i++) {
        type_argument = arguments.TypeAt(i);
        ResolveTypeParameters(&type_argument);
        arguments.SetTypeAt(i, type_argument);
      }
    }
  }
  if (type->IsFunctionType()) {
    const Function& signature =
        Function::Handle(Z, Type::Cast(*type).signature());
    Type& signature_type = Type::Handle(Z, signature.SignatureType());
    if (signature_type.raw() != type->raw()) {
      ResolveTypeParameters(&signature_type);
    } else {
      ResolveSignatureTypeParameters(signature);
    }
  }
}

RawAbstractType* Parser::CanonicalizeType(const AbstractType& type) {
  // If the current class is the result of a mixin application, we must
  // use the class scope of the class from which the function originates.
  if (current_class().IsMixinApplication()) {
    return ClassFinalizer::FinalizeType(
        Class::Handle(Z, parsed_function()->function().origin()), type);
  }
  return ClassFinalizer::FinalizeType(current_class(), type);
}

LocalVariable* Parser::LookupLocalScope(const String& ident) {
  if (current_block_ == NULL) {
    return NULL;
  }
  // A found name is treated as accessed and possibly marked as captured.
  const bool kTestOnly = false;
  return current_block_->scope->LookupVariable(ident, kTestOnly);
}

void Parser::CheckInstanceFieldAccess(TokenPosition field_pos,
                                      const String& field_name) {
  // Fields are not accessible from a static function, except from a
  // constructor, which is considered as non-static by the compiler.
  if (current_function().is_static()) {
    ReportError(field_pos,
                "cannot access instance field '%s' from a static function",
                field_name.ToCString());
  }
}

bool Parser::ParsingStaticMember() const {
  if (is_top_level_) {
    return (current_member_ != NULL) && current_member_->has_static &&
           !current_member_->has_factory;
  }
  ASSERT(!current_function().IsNull());
  return current_function().is_static() &&
         !current_function().IsInFactoryScope();
}

const AbstractType* Parser::ReceiverType(const Class& cls) {
  ASSERT(!cls.IsNull());
  ASSERT(!cls.IsTypedefClass());
  // Note that if cls is _Closure, the returned type will be _Closure,
  // and not the signature type.
  Type& type = Type::ZoneHandle(Z, cls.CanonicalType());
  if (!type.IsNull()) {
    return &type;
  }
  type = Type::New(cls, TypeArguments::Handle(Z, cls.type_parameters()),
                   cls.token_pos(), Heap::kOld);
  if (cls.is_type_finalized()) {
    type ^= ClassFinalizer::FinalizeType(cls, type);
    // Note that the receiver type may now be a malbounded type.
    cls.SetCanonicalType(type);
  }
  return &type;
}

bool Parser::IsInstantiatorRequired() const {
  ASSERT(!current_function().IsNull());
  if (current_function().is_static() &&
      !current_function().IsInFactoryScope()) {
    return false;
  }
  return current_class().IsGeneric();
}

bool Parser::InGenericFunctionScope() const {
  if (!innermost_function().IsNull()) {
    // With one more free tag bit in Function, we could cache this information.
    if (innermost_function().IsGeneric() ||
        innermost_function().HasGenericParent()) {
      return true;
    }
  }
  return false;
}

void Parser::InsertCachedConstantValue(const Script& script,
                                       TokenPosition token_pos,
                                       const Instance& value) {
  ASSERT(Thread::Current()->IsMutatorThread());
  const intptr_t kInitialConstMapSize = 16;
  ASSERT(!script.InVMHeap());
  if (script.compile_time_constants() == Array::null()) {
    const Array& array = Array::Handle(
        HashTables::New<ConstantsMap>(kInitialConstMapSize, Heap::kOld));
    script.set_compile_time_constants(array);
  }
  ConstantsMap constants(script.compile_time_constants());
  constants.InsertNewOrGetValue(token_pos, value);
  script.set_compile_time_constants(constants.Release());
}

void Parser::CacheConstantValue(TokenPosition token_pos,
                                const Instance& value) {
  if (current_function().kind() == RawFunction::kImplicitStaticFinalGetter) {
    // Don't cache constants in initializer expressions. They get
    // evaluated only once.
    return;
  }
  InsertCachedConstantValue(script_, token_pos, value);
  INC_STAT(thread_, num_cached_consts, 1);
}

bool Parser::GetCachedConstant(TokenPosition token_pos, Instance* value) {
  bool is_present = false;
  ASSERT(!script_.InVMHeap());
  if (script_.compile_time_constants() == Array::null()) {
    return false;
  }
  ConstantsMap constants(script_.compile_time_constants());
  *value ^= constants.GetOrNull(token_pos, &is_present);
  // Mutator compiler thread may add constants while background compiler
  // is running, and thus change the value of 'compile_time_constants';
  // do not assert that 'compile_time_constants' has not changed.
  constants.Release();
  if (FLAG_compiler_stats && is_present) {
    thread_->compiler_stats()->num_const_cache_hits++;
  }
  return is_present;
}

RawInstance* Parser::TryCanonicalize(const Instance& instance,
                                     TokenPosition token_pos) {
  if (instance.IsNull()) {
    return instance.raw();
  }
  const char* error_str = NULL;
  Instance& result =
      Instance::Handle(Z, instance.CheckAndCanonicalize(thread(), &error_str));
  if (result.IsNull()) {
    ReportError(token_pos, "Invalid const object %s", error_str);
  }
  return result.raw();
}

// If the field is already initialized, return no ast (NULL).
// Otherwise, if the field is constant, initialize the field and return no ast.
// If the field is not initialized and not const, return the ast for the getter.
StaticGetterNode* Parser::RunStaticFieldInitializer(
    const Field& field,
    TokenPosition field_ref_pos) {
  ASSERT(field.is_static());
  const Class& field_owner = Class::ZoneHandle(Z, field.Owner());
  const String& field_name = String::ZoneHandle(Z, field.name());
  const String& getter_name =
      String::Handle(Z, Field::GetterSymbol(field_name));
  const Function& getter =
      Function::Handle(Z, field_owner.LookupStaticFunction(getter_name));
  const Instance& value = Instance::Handle(Z, field.StaticValue());
  if (value.raw() == Object::transition_sentinel().raw()) {
    if (field.is_const()) {
      ReportError("circular dependency while initializing static field '%s'",
                  field_name.ToCString());
    } else {
      // The implicit static getter will throw the exception if necessary.
      return new (Z) StaticGetterNode(field_ref_pos, NULL, field_owner,
                                      field_name, StaticGetterSetter::kStatic);
    }
  } else if (value.raw() == Object::sentinel().raw()) {
    // This field has not been referenced yet and thus the value has
    // not been evaluated. If the field is const, call the static getter method
    // to evaluate the expression and canonicalize the value.
    if (field.is_const()) {
      NoReloadScope no_reload_scope(isolate(), thread());
      NoOOBMessageScope no_msg_scope(thread());
      field.SetStaticValue(Object::transition_sentinel());
      const int kTypeArgsLen = 0;   // No type argument vector.
      const int kNumArguments = 0;  // No arguments.
      const Function& func = Function::Handle(
          Z, Resolver::ResolveStatic(field_owner, getter_name, kTypeArgsLen,
                                     kNumArguments, Object::empty_array()));
      ASSERT(!func.IsNull());
      ASSERT(func.kind() == RawFunction::kImplicitStaticFinalGetter);
      Object& const_value = Object::Handle(Z);
      const_value = DartEntry::InvokeFunction(func, Object::empty_array());
      if (const_value.IsError()) {
        const Error& error = Error::Cast(const_value);
        if (error.IsUnhandledException()) {
          // An exception may not occur in every parse attempt, i.e., the
          // generated AST is not deterministic. Therefore mark the function as
          // not optimizable.
          current_function().SetIsOptimizable(false);
          field.SetStaticValue(Object::null_instance());
          // It is a compile-time error if evaluation of a compile-time constant
          // would raise an exception.
          const String& field_name = String::Handle(Z, field.name());
          ReportErrors(error, script_, field_ref_pos,
                       "error initializing const field '%s'",
                       field_name.ToCString());
        } else {
          ReportError(error);
        }
        UNREACHABLE();
      }
      ASSERT(const_value.IsNull() || const_value.IsInstance());
      Instance& instance = Instance::Handle(Z);
      instance ^= const_value.raw();
      instance = TryCanonicalize(instance, field_ref_pos);
      field.SetStaticValue(instance);
      return NULL;  // Constant
    } else {
      return new (Z) StaticGetterNode(field_ref_pos, NULL, field_owner,
                                      field_name, StaticGetterSetter::kStatic);
    }
  }
  if (getter.IsNull() ||
      (getter.kind() == RawFunction::kImplicitStaticFinalGetter)) {
    return NULL;
  }
  ASSERT(getter.kind() == RawFunction::kImplicitGetter);
  return new (Z) StaticGetterNode(field_ref_pos, NULL, field_owner, field_name,
                                  StaticGetterSetter::kStatic);
}

RawObject* Parser::EvaluateConstConstructorCall(
    const Class& type_class,
    const TypeArguments& type_arguments,
    const Function& constructor,
    ArgumentListNode* arguments,
    bool obfuscate_symbol_instances /* = true */) {
  NoReloadScope no_reload_scope(isolate(), thread());
  NoOOBMessageScope no_msg_scope(thread());
  // Factories and constructors are not generic functions.
  const int kTypeArgsLen = 0;
  // Factories have one extra argument: the type arguments.
  // Constructors have one extra arguments: receiver.
  const int kNumExtraArgs = 1;
  const int num_arguments = arguments->length() + kNumExtraArgs;
  const Array& arg_values =
      Array::Handle(Z, Array::New(num_arguments, allocation_space_));
  Instance& instance = Instance::Handle(Z);
  if (!constructor.IsFactory()) {
    instance = Instance::New(type_class, allocation_space_);
    if (!type_arguments.IsNull()) {
      if (!type_arguments.IsInstantiated()) {
        ReportError("type must be constant in const constructor");
      }
      instance.SetTypeArguments(
          TypeArguments::Handle(Z, type_arguments.Canonicalize()));
    }
    arg_values.SetAt(0, instance);
  } else {
    // Prepend type_arguments to list of arguments to factory.
    ASSERT(type_arguments.IsZoneHandle());
    arg_values.SetAt(0, type_arguments);
  }
  for (int i = 0; i < arguments->length(); i++) {
    AstNode* arg = arguments->NodeAt(i);
    // Arguments have been evaluated to a literal value already.
    ASSERT(arg->IsLiteralNode());
    arg_values.SetAt((i + kNumExtraArgs), arg->AsLiteralNode()->literal());
  }
  const Array& args_descriptor =
      Array::Handle(Z, ArgumentsDescriptor::New(kTypeArgsLen, num_arguments,
                                                arguments->names()));
  const Object& result = Object::Handle(
      Z, DartEntry::InvokeFunction(constructor, arg_values, args_descriptor));
  if (result.IsError()) {
    // An exception may not occur in every parse attempt, i.e., the
    // generated AST is not deterministic. Therefore mark the function as
    // not optimizable.
    current_function().SetIsOptimizable(false);
    if (result.IsUnhandledException()) {
      return result.raw();
    } else {
      thread()->long_jump_base()->Jump(1, Error::Cast(result));
      UNREACHABLE();
      return Object::null();
    }
  } else {
    if (constructor.IsFactory()) {
      // The factory method returns the allocated object.
      instance ^= result.raw();
    }
    if (obfuscate_symbol_instances && I->obfuscate() &&
        (instance.clazz() == I->object_store()->symbol_class())) {
      Obfuscator::ObfuscateSymbolInstance(T, instance);
    }
    return TryCanonicalize(instance, TokenPos());
  }
}

// Do a lookup for the identifier in the block scope and the class scope
// return true if the identifier is found, false otherwise.
// If node is non NULL return an AST node corresponding to the identifier.
bool Parser::ResolveIdentInLocalScope(TokenPosition ident_pos,
                                      const String& ident,
                                      AstNode** node,
                                      intptr_t* function_level) {
  TRACE_PARSER("ResolveIdentInLocalScope");
  // First try to find the identifier in the nested local scopes.
  LocalVariable* local = LookupLocalScope(ident);
  if (current_block_ != NULL) {
    current_block_->scope->AddReferencedName(ident_pos, ident);
  }
  if (local != NULL) {
    if (node != NULL) {
      *node = new (Z) LoadLocalNode(ident_pos, local);
    }
    if (function_level != NULL) {
      *function_level = local->owner()->function_level();
    }
    return true;
  }

  // If we are compiling top-level code, we don't need to look for
  // the identifier in the current (top-level) class. The class scope
  // of the top-level class is part of the library scope.
  if (current_class().IsTopLevel()) {
    if (node != NULL) {
      *node = NULL;
    }
    return false;
  }

  // Try to find the identifier in the class scope of the current class.
  // If the current class is the result of a mixin application, we must
  // use the class scope of the class from which the function originates.
  Class& cls = Class::Handle(Z);
  if (!current_class().IsMixinApplication()) {
    cls = current_class().raw();
  } else {
    cls = parsed_function()->function().origin();
  }
  Function& func = Function::Handle(Z, Function::null());
  Field& field = Field::Handle(Z, Field::null());

  // First check if a field exists.
  field = cls.LookupField(ident);
  if (!field.IsNull()) {
    if (node != NULL) {
      if (!field.is_static()) {
        CheckInstanceFieldAccess(ident_pos, ident);
        *node = CallGetter(ident_pos, LoadReceiver(ident_pos), ident);
      } else {
        *node = GenerateStaticFieldLookup(field, ident_pos);
      }
    }
    if (function_level != NULL) {
      *function_level = 0;
    }
    return true;
  }

  // Check if an instance/static function exists.
  func = cls.LookupFunction(ident);
  if (!func.IsNull() && (func.IsDynamicFunction() || func.IsStaticFunction() ||
                         func.is_abstract())) {
    if (node != NULL) {
      *node =
          new (Z) PrimaryNode(ident_pos, Function::ZoneHandle(Z, func.raw()));
    }
    return true;
  }

  // Now check if a getter/setter method exists for it in which case
  // it is still a field.
  // A setter without a corresponding getter binds to the non-existing
  // getter. (The getter could be followed by an assignment which will
  // convert it to a setter node. If there is no assignment the non-existing
  // getter will throw a NoSuchMethodError.)
  func = cls.LookupGetterFunction(ident);
  if (func.IsNull()) {
    func = cls.LookupSetterFunction(ident);
  }
  if (!func.IsNull()) {
    if (func.IsDynamicFunction() || func.is_abstract()) {
      if (node != NULL) {
        CheckInstanceFieldAccess(ident_pos, ident);
        ASSERT(AbstractType::Handle(Z, func.result_type()).IsResolved());
        *node = CallGetter(ident_pos, LoadReceiver(ident_pos), ident);
      }
      return true;
    } else if (func.IsStaticFunction()) {
      if (node != NULL) {
        *node = new (Z)
            StaticGetterNode(ident_pos, NULL, Class::ZoneHandle(Z, cls.raw()),
                             ident, StaticGetterSetter::kStatic);
      }
      return true;
    }
  }

  // Nothing found in scope of current class.
  if (node != NULL) {
    *node = NULL;
  }
  return false;
}

// Resolve an identifier by checking the global scope of the current
// library. If not found in the current library, then look in the scopes
// of all libraries that are imported without a library prefix.
AstNode* Parser::ResolveIdentInCurrentLibraryScope(TokenPosition ident_pos,
                                                   const String& ident) {
  TRACE_PARSER("ResolveIdentInCurrentLibraryScope");
  HANDLESCOPE(thread());
  const Object& obj = Object::Handle(Z, library_.ResolveName(ident));
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    return new (Z) PrimaryNode(ident_pos, Class::ZoneHandle(Z, cls.raw()));
  } else if (obj.IsField()) {
    const Field& field = Field::Cast(obj);
    ASSERT(field.is_static());
    AstNode* get_field = GenerateStaticFieldLookup(field, ident_pos);
    if (get_field->IsStaticGetterNode()) {
      get_field->AsStaticGetterNode()->set_owner(library_);
    }
    return get_field;
  } else if (obj.IsFunction()) {
    const Function& func = Function::Cast(obj);
    ASSERT(func.is_static());
    if (func.IsGetterFunction() || func.IsSetterFunction()) {
      StaticGetterNode* getter = new (Z) StaticGetterNode(
          ident_pos,
          /* receiver */ NULL, Class::ZoneHandle(Z, func.Owner()), ident,
          StaticGetterSetter::kStatic);
      getter->set_owner(library_);
      return getter;
    } else {
      return new (Z)
          PrimaryNode(ident_pos, Function::ZoneHandle(Z, func.raw()));
    }
  } else if (obj.IsLibraryPrefix()) {
    const LibraryPrefix& prefix = LibraryPrefix::Cast(obj);
    ReportError(ident_pos, "illegal use of library prefix '%s'",
                String::Handle(prefix.name()).ToCString());
  } else {
    ASSERT(obj.IsNull());
  }
  // Lexically unresolved primary identifiers are referenced by their name.
  return new (Z) PrimaryNode(ident_pos, ident);
}

// Do a lookup for the identifier in the scope of the specified
// library prefix. This means trying to resolve it locally in all of the
// libraries present in the library prefix.
AstNode* Parser::ResolveIdentInPrefixScope(TokenPosition ident_pos,
                                           const LibraryPrefix& prefix,
                                           const String& ident) {
  TRACE_PARSER("ResolveIdentInPrefixScope");
  HANDLESCOPE(thread());
  if (ident.CharAt(0) == Library::kPrivateIdentifierStart) {
    // Private names are not exported by libraries. The name mangling
    // of private names with a library-specific suffix usually ensures
    // that _x in library A is not found when looked up from library B.
    // In the pathological case where a library imports itself with
    // a prefix, the name mangling would not help in hiding the private
    // name, so we need to explicitly reject private names here.
    return NULL;
  }
  Object& obj = Object::Handle(Z);
  if (prefix.is_loaded() || FLAG_load_deferred_eagerly) {
    obj = prefix.LookupObject(ident);
  } else {
    // Remember that this function depends on an import prefix of an
    // unloaded deferred library. Note that parsed_function() can be
    // NULL when parsing expressions outside the scope of a function.
    if (parsed_function() != NULL) {
      parsed_function()->AddDeferredPrefix(prefix);
    }
  }
  const bool is_deferred = prefix.is_deferred_load();
  if (obj.IsNull()) {
    // Unresolved prefixed primary identifier.
    return NULL;
  } else if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    PrimaryNode* primary =
        new (Z) PrimaryNode(ident_pos, Class::ZoneHandle(Z, cls.raw()));
    if (is_deferred) {
      primary->set_prefix(&prefix);
    }
    return primary;
  } else if (obj.IsField()) {
    const Field& field = Field::Cast(obj);
    ASSERT(field.is_static());
    AstNode* get_field = GenerateStaticFieldLookup(field, ident_pos);
    ASSERT(get_field != NULL);
    ASSERT(get_field->IsLoadStaticFieldNode() ||
           get_field->IsStaticGetterNode());
    if (get_field->IsLoadStaticFieldNode()) {
      get_field->AsLoadStaticFieldNode()->set_is_deferred(is_deferred);
    } else if (get_field->IsStaticGetterNode()) {
      get_field->AsStaticGetterNode()->set_is_deferred(is_deferred);
      get_field->AsStaticGetterNode()->set_owner(prefix);
    }
    return get_field;
  } else if (obj.IsFunction()) {
    const Function& func = Function::Cast(obj);
    ASSERT(func.is_static());
    if (func.IsGetterFunction() || func.IsSetterFunction()) {
      StaticGetterNode* getter = new (Z) StaticGetterNode(
          ident_pos,
          /* receiver */ NULL, Class::ZoneHandle(Z, func.Owner()), ident,
          StaticGetterSetter::kStatic);
      getter->set_is_deferred(is_deferred);
      getter->set_owner(prefix);
      return getter;
    } else {
      PrimaryNode* primary =
          new (Z) PrimaryNode(ident_pos, Function::ZoneHandle(Z, func.raw()));
      if (is_deferred) {
        primary->set_prefix(&prefix);
      }
      return primary;
    }
  }
  // All possible object types are handled above.
  UNREACHABLE();
  return NULL;
}

// Resolve identifier. Issue an error message if
// the ident refers to a method and allow_closure_names is false.
// If the name cannot be resolved, turn it into an instance field access
// if we're compiling an instance method, or generate
// throw NoSuchMethodError if we're compiling a static method.
AstNode* Parser::ResolveIdent(TokenPosition ident_pos,
                              const String& ident,
                              bool allow_closure_names) {
  TRACE_PARSER("ResolveIdent");
  // First try to find the variable in the local scope (block scope or
  // class scope).
  AstNode* resolved = NULL;
  intptr_t resolved_func_level = 0;
  ResolveIdentInLocalScope(ident_pos, ident, &resolved, &resolved_func_level);
  if (InGenericFunctionScope()) {
    intptr_t type_param_func_level = FunctionLevel();
    const TypeParameter& type_parameter =
        TypeParameter::ZoneHandle(Z, innermost_function().LookupTypeParameter(
                                         ident, &type_param_func_level));
    if (!type_parameter.IsNull()) {
      if ((resolved == NULL) || (resolved_func_level < type_param_func_level)) {
        // The identifier is a function type parameter, possibly shadowing
        // 'resolved'.
        if (!FLAG_reify_generic_functions) {
          Type& type = Type::ZoneHandle(Z, Type::DynamicType());
          return new (Z) TypeNode(ident_pos, type);
        }
        ASSERT(type_parameter.IsFinalized());
        ASSERT(!type_parameter.IsMalformed());
        if ((FunctionLevel() > 0) && innermost_function().HasGenericParent()) {
          // Make sure that the parent function type arguments are captured.
          CaptureFunctionTypeArguments();
        }
        return new (Z) TypeNode(ident_pos, type_parameter);
      }
    }
  }
  if (resolved == NULL) {
    // Check whether the identifier is a class type parameter.
    if (!current_class().IsNull()) {
      TypeParameter& type_parameter = TypeParameter::ZoneHandle(
          Z, current_class().LookupTypeParameter(ident));
      if (!type_parameter.IsNull()) {
        if (ParsingStaticMember()) {
          const String& name = String::Handle(Z, type_parameter.name());
          ReportError(ident_pos,
                      "cannot access type parameter '%s' "
                      "from static function",
                      name.ToCString());
        }
        type_parameter ^= CanonicalizeType(type_parameter);
        ASSERT(!type_parameter.IsMalformed());
        if (FunctionLevel() > 0) {
          // Make sure that the class instantiator is captured.
          CaptureInstantiator();
        }
        return new (Z) TypeNode(ident_pos, type_parameter);
      }
    }
    // Not found in the local scope, and the name is not a type parameter.
    // Try finding the variable in the library scope (current library
    // and all libraries imported by it without a library prefix).
    resolved = ResolveIdentInCurrentLibraryScope(ident_pos, ident);
  }
  if (resolved->IsPrimaryNode()) {
    PrimaryNode* primary = resolved->AsPrimaryNode();
    const TokenPosition primary_pos = primary->token_pos();
    if (primary->primary().IsString()) {
      // We got an unresolved name. If we are compiling a static
      // method, evaluation of an unresolved identifier causes a
      // NoSuchMethodError to be thrown. In an instance method, we convert
      // the unresolved name to an instance field access, since a
      // subclass might define a field with this name.
      if (current_function().is_static()) {
        resolved = ThrowNoSuchMethodError(ident_pos, current_class(), ident,
                                          NULL,  // No arguments.
                                          InvocationMirror::kStatic,
                                          InvocationMirror::kField,
                                          NULL);  // No existing function.
      } else {
        // Treat as call to unresolved instance field.
        resolved = CallGetter(ident_pos, LoadReceiver(ident_pos), ident);
      }
    } else if (primary->primary().IsFunction()) {
      if (allow_closure_names) {
        resolved = LoadClosure(primary);
      } else {
        ReportError(ident_pos, "illegal reference to method '%s'",
                    ident.ToCString());
      }
    } else if (primary->primary().IsClass()) {
      const Class& type_class = Class::Cast(primary->primary());
      AbstractType& type =
          Type::ZoneHandle(Z, Type::New(type_class, TypeArguments::Handle(Z),
                                        primary_pos, Heap::kOld));
      type ^= CanonicalizeType(type);
      // Type may be malbounded, but not malformed.
      ASSERT(!type.IsMalformed());
      resolved =
          new (Z) TypeNode(primary_pos, type, primary->is_deferred_reference());
    }
  }
  return resolved;
}

RawAbstractType* Parser::ParseType(
    ClassFinalizer::FinalizationKind finalization,
    bool allow_deferred_type,
    bool consume_unresolved_prefix) {
  LibraryPrefix& prefix = LibraryPrefix::Handle(Z);
  return ParseType(finalization, allow_deferred_type, consume_unresolved_prefix,
                   &prefix);
}

// Parses and returns a type or a function type.
RawAbstractType* Parser::ParseTypeOrFunctionType(
    bool allow_void,
    ClassFinalizer::FinalizationKind finalization) {
  TRACE_PARSER("ParseTypeOrFunctionType");
  AbstractType& type = AbstractType::Handle(Z);
  if (CurrentToken() == Token::kVOID) {
    TokenPosition void_pos = TokenPos();
    type = Type::VoidType();
    ConsumeToken();
    // 'void' is always allowed as result type of a function type.
    if (!allow_void && !IsFunctionTypeSymbol()) {
      ReportError(void_pos, "'void' not allowed here");
    }
  } else if (!IsFunctionTypeSymbol()) {
    // Including 'Function' not followed by '(' or '<'.
    // It is too early to resolve the type here, since it can
    // refer to a not yet declared function type parameter.
    type = ParseType(ClassFinalizer::kDoNotResolve);
  }
  while (IsFunctionTypeSymbol()) {
    if (type.IsNull()) {
      type = Type::DynamicType();
    }
    // 'type' is the result type of the function type.
    type = ParseFunctionType(type, ClassFinalizer::kDoNotResolve);
  }
  // At this point, all type parameters have been parsed, resolve the type.
  if (finalization == ClassFinalizer::kIgnore) {
    return Type::DynamicType();
  }
  if (finalization >= ClassFinalizer::kResolveTypeParameters) {
    ResolveTypeParameters(&type);
    if (finalization >= ClassFinalizer::kCanonicalize) {
      type ^= CanonicalizeType(type);
    }
  }
  return type.raw();
}

// Parses and returns a function type.
// If 'result_type' is not null, parsing of the result type is skipped.
RawType* Parser::ParseFunctionType(
    const AbstractType& result_type,
    ClassFinalizer::FinalizationKind finalization) {
  TRACE_PARSER("ParseFunctionType");
  AbstractType& type = AbstractType::Handle(Z, result_type.raw());
  if (type.IsNull()) {
    if (CurrentToken() == Token::kVOID) {
      ConsumeToken();
      type = Type::VoidType();
    } else if (IsFunctionTypeSymbol()) {
      type = Type::DynamicType();
    } else {
      // Including 'Function' not followed by '(' or '<'.
      // It is too early to resolve the type here, since it can
      // refer to a not yet declared function type parameter.
      type = ParseType(ClassFinalizer::kDoNotResolve);
    }
  }
  if (!IsSymbol(Symbols::Function())) {
    ReportError("'Function' expected");
  }
  do {
    ConsumeToken();
    const Function& signature_function = Function::Handle(
        Z, Function::NewSignatureFunction(current_class(), innermost_function(),
                                          TokenPosition::kNoSource));
    innermost_function_ = signature_function.raw();
    signature_function.set_result_type(type);
    // The result type may refer to the signature function's type parameters,
    // but was not parsed in the scope of the signature function. Adjust.
    type.SetScopeFunction(signature_function);
    // Parse optional type parameters.
    if (CurrentToken() == Token::kLT) {
      if (!FLAG_generic_method_syntax) {
        ReportError("generic type arguments not supported.");
      }
      ParseTypeParameters(false);  // Not parameterizing class, but function.
    }
    ParamList params;
    // We do not yet allow Function of any arity, so expect parameter list.
    CheckToken(Token::kLPAREN, "formal parameter list expected");

    // Add implicit closure object parameter. Do not specify a token position,
    // since it would make no sense after function type canonicalization.
    params.AddFinalParameter(TokenPosition::kNoSource,
                             &Symbols::ClosureParameter(),
                             &Object::dynamic_type());

    const bool use_function_type_syntax = true;
    const bool allow_explicit_default_values = false;
    const bool evaluate_metadata = false;
    ParseFormalParameterList(use_function_type_syntax,
                             allow_explicit_default_values, evaluate_metadata,
                             &params);
    AddFormalParamsToFunction(&params, signature_function);
    innermost_function_ = innermost_function_.parent_function();
    if (innermost_function().IsNull() && current_class().IsTypedefClass() &&
        !IsFunctionTypeSymbol()) {
      // The last parsed signature function is the typedef signature function.
      // Set it in the typedef class before building the signature type.
      current_class().set_signature_function(signature_function);
    }
    type = signature_function.SignatureType();
  } while (IsFunctionTypeSymbol());
  // At this point, all type parameters have been parsed, resolve the type.
  if (finalization == ClassFinalizer::kIgnore) {
    return Type::DynamicType();
  }
  if (finalization >= ClassFinalizer::kResolveTypeParameters) {
    ResolveTypeParameters(&type);
    if (finalization >= ClassFinalizer::kCanonicalize) {
      type ^= CanonicalizeType(type);
    }
  }
  return Type::RawCast(type.raw());
}

// Parses type = [ident "."] ident ["<" type { "," type } ">"], then resolve and
// finalize it according to the given type finalization mode.
// Returns type and sets prefix.
RawAbstractType* Parser::ParseType(
    ClassFinalizer::FinalizationKind finalization,
    bool allow_deferred_type,
    bool consume_unresolved_prefix,
    LibraryPrefix* prefix) {
  TRACE_PARSER("ParseType");
  CheckToken(Token::kIDENT, "type name expected");
  TokenPosition ident_pos = TokenPos();
  String& type_name = String::Handle(Z);

  if (finalization == ClassFinalizer::kIgnore) {
    if (!is_top_level_ && (current_block_ != NULL)) {
      // Add the library prefix or type class name to the list of referenced
      // names of this scope, even if the type is ignored.
      current_block_->scope->AddReferencedName(TokenPos(), *CurrentLiteral());
    }
    SkipQualIdent();
  } else {
    *prefix = ParsePrefix();
    if (!prefix->IsNull()) {
      ExpectToken(Token::kPERIOD);
    }
    type_name = CurrentLiteral()->raw();
    ConsumeToken();

    // Check whether we have a malformed qualified type name if the caller
    // requests to consume unresolved prefix names:
    // If we didn't see a valid prefix but the identifier is followed by
    // a period and another identifier, consume the qualified identifier
    // and create a malformed type.
    if (consume_unresolved_prefix && prefix->IsNull() &&
        (CurrentToken() == Token::kPERIOD) &&
        (Token::IsIdentifier(LookaheadToken(1)))) {
      if (!is_top_level_ && (current_block_ != NULL)) {
        // Add the unresolved prefix name to the list of referenced
        // names of this scope.
        current_block_->scope->AddReferencedName(TokenPos(), type_name);
      }
      ConsumeToken();  // Period token.
      ASSERT(IsIdentifier());
      String& qualified_name = String::Handle(Z, type_name.raw());
      qualified_name =
          String::Concat(qualified_name, Symbols::Dot(), allocation_space_);
      qualified_name =
          String::Concat(qualified_name, *CurrentLiteral(), allocation_space_);
      ConsumeToken();
      // The type is malformed. Skip over its type arguments.
      ParseTypeArguments(ClassFinalizer::kIgnore);
      return ClassFinalizer::NewFinalizedMalformedType(
          Error::Handle(Z),  // No previous error.
          script_, ident_pos, "qualified name '%s' does not refer to a type",
          qualified_name.ToCString());
    }

    // If parsing inside a local scope, check whether the type name
    // is shadowed by a local declaration.
    if (!is_top_level_ && (prefix->IsNull()) &&
        ResolveIdentInLocalScope(ident_pos, type_name, NULL, NULL)) {
      // The type is malformed. Skip over its type arguments.
      ParseTypeArguments(ClassFinalizer::kIgnore);
      return ClassFinalizer::NewFinalizedMalformedType(
          Error::Handle(Z),  // No previous error.
          script_, ident_pos, "using '%s' in this context is invalid",
          type_name.ToCString());
    }
    if ((!FLAG_load_deferred_eagerly || !allow_deferred_type) &&
        !prefix->IsNull() && prefix->is_deferred_load()) {
      // If deferred prefixes are allowed but it is not yet loaded,
      // remember that this function depends on the prefix.
      if (allow_deferred_type && !prefix->is_loaded()) {
        if (parsed_function() != NULL) {
          parsed_function()->AddDeferredPrefix(*prefix);
        }
      }
      // If the deferred prefixes are not allowed, or if the prefix is not yet
      // loaded when finalization is requested, return a malformed type.
      // Otherwise, handle resolution below, as needed.
      if (!allow_deferred_type ||
          (!prefix->is_loaded() &&
           (finalization > ClassFinalizer::kResolveTypeParameters))) {
        ParseTypeArguments(ClassFinalizer::kIgnore);
        return ClassFinalizer::NewFinalizedMalformedType(
            Error::Handle(Z),  // No previous error.
            script_, ident_pos,
            !prefix->is_loaded() && allow_deferred_type
                ? "deferred type '%s.%s' is not yet loaded"
                : "using deferred type '%s.%s' is invalid",
            String::Handle(Z, prefix->name()).ToCString(),
            type_name.ToCString());
      }
    }
  }
  Object& type_class = Object::Handle(Z);
  // Leave type_class as null if type finalization mode is kIgnore.
  if (finalization != ClassFinalizer::kIgnore) {
    type_class = UnresolvedClass::New(*prefix, type_name, ident_pos);
  }
  TypeArguments& type_arguments =
      TypeArguments::Handle(Z, ParseTypeArguments(finalization));
  if (finalization == ClassFinalizer::kIgnore) {
    return Type::DynamicType();
  }
  AbstractType& type = AbstractType::Handle(
      Z, Type::New(type_class, type_arguments, ident_pos, Heap::kOld));
  if (finalization >= ClassFinalizer::kResolveTypeParameters) {
    ResolveTypeParameters(&type);
    if (finalization >= ClassFinalizer::kCanonicalize) {
      type ^= CanonicalizeType(type);
    }
  }
  return type.raw();
}

void Parser::CheckConstructorCallTypeArguments(
    TokenPosition pos,
    const Function& constructor,
    const TypeArguments& type_arguments) {
  if (!type_arguments.IsNull()) {
    const Class& constructor_class = Class::Handle(Z, constructor.Owner());
    ASSERT(!constructor_class.IsNull());
    ASSERT(constructor_class.is_finalized());
    ASSERT(type_arguments.IsCanonical());
    // Do not report the expected vs. actual number of type arguments, because
    // the type argument vector is flattened and raw types are allowed.
    if (type_arguments.Length() != constructor_class.NumTypeArguments()) {
      ReportError(pos, "wrong number of type arguments passed to constructor");
    }
  }
}

// Parse "[" [ expr { "," expr } ["," ] "]".
// Note: if the list literal is empty and the brackets have no whitespace
// between them, the scanner recognizes the opening and closing bracket
// as one token of type Token::kINDEX.
AstNode* Parser::ParseListLiteral(TokenPosition type_pos,
                                  bool is_const,
                                  const TypeArguments& type_arguments) {
  TRACE_PARSER("ParseListLiteral");
  ASSERT(type_pos.IsReal());
  ASSERT(CurrentToken() == Token::kLBRACK || CurrentToken() == Token::kINDEX);
  const TokenPosition literal_pos = TokenPos();

  if (is_const) {
    Instance& existing_const = Instance::ZoneHandle(Z);
    if (GetCachedConstant(literal_pos, &existing_const)) {
      SkipListLiteral();
      return new (Z) LiteralNode(literal_pos, existing_const);
    }
  }

  bool is_empty_literal = CurrentToken() == Token::kINDEX;
  ConsumeToken();

  AbstractType& element_type = Type::ZoneHandle(Z, Type::DynamicType());
  TypeArguments& list_type_arguments =
      TypeArguments::ZoneHandle(Z, type_arguments.raw());
  // If no type argument vector is provided, leave it as null, which is
  // equivalent to using dynamic as the type argument for the element type.
  if (!list_type_arguments.IsNull()) {
    ASSERT(list_type_arguments.Length() > 0);
    // List literals take a single type argument.
    if (list_type_arguments.Length() == 1) {
      element_type = list_type_arguments.TypeAt(0);
      ASSERT(!element_type.IsMalformed());   // Would be mapped to dynamic.
      ASSERT(!element_type.IsMalbounded());  // No declared bound in List.
      if (element_type.IsDynamicType()) {
        list_type_arguments = TypeArguments::null();
      } else if (is_const && !element_type.IsInstantiated()) {
        ReportError(type_pos,
                    "the type argument of a constant list literal cannot "
                    "include a type variable");
      }
    } else {
      if (I->error_on_bad_type()) {
        ReportError(type_pos,
                    "a list literal takes one type argument specifying "
                    "the element type");
      }
      // Ignore type arguments.
      list_type_arguments = TypeArguments::null();
    }
  }
  ASSERT(list_type_arguments.IsNull() || (list_type_arguments.Length() == 1));
  const Class& array_class = Class::Handle(Z, I->object_store()->array_class());
  Type& type = Type::ZoneHandle(
      Z, Type::New(array_class, list_type_arguments, type_pos, Heap::kOld));
  type ^= CanonicalizeType(type);
  GrowableArray<AstNode*> element_list;
  // Parse the list elements. Note: there may be an optional extra
  // comma after the last element.
  if (!is_empty_literal) {
    const bool saved_mode = SetAllowFunctionLiterals(true);
    while (CurrentToken() != Token::kRBRACK) {
      const TokenPosition element_pos = TokenPos();
      AstNode* element = ParseExpr(is_const, kConsumeCascades);
      if (I->type_checks() && !is_const && !element_type.IsDynamicType()) {
        element = new (Z) AssignableNode(element_pos, element, element_type,
                                         Symbols::ListLiteralElement());
      }
      element_list.Add(element);
      if (CurrentToken() == Token::kCOMMA) {
        ConsumeToken();
      } else if (CurrentToken() != Token::kRBRACK) {
        ReportError("comma or ']' expected");
      }
    }
    ExpectToken(Token::kRBRACK);
    SetAllowFunctionLiterals(saved_mode);
  }

  if (is_const) {
    // Allocate and initialize the const list at compile time.
    if ((element_list.length() == 0) && list_type_arguments.IsNull()) {
      return new (Z) LiteralNode(literal_pos, Object::empty_array());
    }
    Array& const_list =
        Array::ZoneHandle(Z, Array::New(element_list.length(), Heap::kOld));
    const_list.SetTypeArguments(
        TypeArguments::Handle(Z, list_type_arguments.Canonicalize()));
    Error& bound_error = Error::Handle(Z);
    for (int i = 0; i < element_list.length(); i++) {
      AstNode* elem = element_list[i];
      // Arguments have been evaluated to a literal value already.
      ASSERT(elem->IsLiteralNode());
      ASSERT(!is_top_level_);  // We cannot check unresolved types.
      if (I->type_checks() && !element_type.IsDynamicType() &&
          (!elem->AsLiteralNode()->literal().IsNull() &&
           !elem->AsLiteralNode()->literal().IsInstanceOf(
               element_type, Object::null_type_arguments(),
               Object::null_type_arguments(), &bound_error))) {
        // If the failure is due to a bound error, display it instead.
        if (!bound_error.IsNull()) {
          ReportError(bound_error);
        } else {
          ReportError(
              elem->AsLiteralNode()->token_pos(),
              "list literal element at index %d must be "
              "a constant of type '%s'",
              i, String::Handle(Z, element_type.UserVisibleName()).ToCString());
        }
      }
      const_list.SetAt(i, elem->AsLiteralNode()->literal());
    }
    const_list.MakeImmutable();
    const_list ^= TryCanonicalize(const_list, literal_pos);
    CacheConstantValue(literal_pos, const_list);
    return new (Z) LiteralNode(literal_pos, const_list);
  } else {
    // Factory call at runtime.
    const Class& factory_class =
        Class::Handle(Z, Library::LookupCoreClass(Symbols::List()));
    ASSERT(!factory_class.IsNull());
    const Function& factory_method = Function::ZoneHandle(
        Z, factory_class.LookupFactory(
               Library::PrivateCoreLibName(Symbols::ListLiteralFactory())));
    ASSERT(!factory_method.IsNull());
    if (!list_type_arguments.IsNull() &&
        !list_type_arguments.IsInstantiated() && (FunctionLevel() > 0)) {
      // Make sure that the instantiators are captured.
      CaptureAllInstantiators();
    }
    TypeArguments& factory_type_args =
        TypeArguments::ZoneHandle(Z, list_type_arguments.raw());
    // If the factory class extends other parameterized classes, adjust the
    // type argument vector.
    if (!factory_type_args.IsNull() && (factory_class.NumTypeArguments() > 1)) {
      ASSERT(factory_type_args.Length() == 1);
      Type& factory_type = Type::Handle(
          Z, Type::New(factory_class, factory_type_args, type_pos, Heap::kOld));
      // It is not strictly necessary to canonicalize factory_type, but only its
      // type argument vector.
      factory_type ^= CanonicalizeType(factory_type);
      factory_type_args = factory_type.arguments();
      ASSERT(factory_type_args.Length() == factory_class.NumTypeArguments());
      ASSERT(factory_type_args.IsCanonical());
    } else {
      factory_type_args = factory_type_args.Canonicalize();
    }
    ArgumentListNode* factory_param = new (Z) ArgumentListNode(literal_pos);
    if (element_list.length() == 0) {
      LiteralNode* empty_array_literal =
          new (Z) LiteralNode(TokenPos(), Object::empty_array());
      factory_param->Add(empty_array_literal);
    } else {
      ArrayNode* list = new (Z) ArrayNode(TokenPos(), type, element_list);
      factory_param->Add(list);
    }
    return CreateConstructorCallNode(literal_pos, factory_type_args,
                                     factory_method, factory_param);
  }
}

ConstructorCallNode* Parser::CreateConstructorCallNode(
    TokenPosition token_pos,
    const TypeArguments& type_arguments,
    const Function& constructor,
    ArgumentListNode* arguments) {
  if (!type_arguments.IsNull() && !type_arguments.IsInstantiated()) {
    EnsureExpressionTemp();
  }
  return new (Z)
      ConstructorCallNode(token_pos, type_arguments, constructor, arguments);
}

static void AddKeyValuePair(GrowableArray<AstNode*>* pairs,
                            bool is_const,
                            AstNode* key,
                            AstNode* value) {
  if (is_const) {
    ASSERT(key->IsLiteralNode());
    const Instance& new_key = key->AsLiteralNode()->literal();
    for (int i = 0; i < pairs->length(); i += 2) {
      const Instance& key_i = (*pairs)[i]->AsLiteralNode()->literal();
      // The keys of a compile time constant map are compile time
      // constants, i.e. canonicalized values. Thus, we can compare
      // raw pointers to check for equality.
      if (new_key.raw() == key_i.raw()) {
        // Duplicate key found. The new value replaces the previously
        // defined value.
        (*pairs)[i + 1] = value;
        return;
      }
    }
  }
  pairs->Add(key);
  pairs->Add(value);
}

AstNode* Parser::ParseMapLiteral(TokenPosition type_pos,
                                 bool is_const,
                                 const TypeArguments& type_arguments) {
  TRACE_PARSER("ParseMapLiteral");
  ASSERT(type_pos.IsReal());
  ASSERT(CurrentToken() == Token::kLBRACE);
  const TokenPosition literal_pos = TokenPos();

  if (is_const) {
    Instance& existing_const = Instance::ZoneHandle(Z);
    if (GetCachedConstant(literal_pos, &existing_const)) {
      SkipMapLiteral();
      return new (Z) LiteralNode(literal_pos, existing_const);
    }
  }

  ConsumeToken();  // Opening brace.
  AbstractType& key_type = Type::ZoneHandle(Z, Type::DynamicType());
  AbstractType& value_type = Type::ZoneHandle(Z, Type::DynamicType());
  TypeArguments& map_type_arguments =
      TypeArguments::ZoneHandle(Z, type_arguments.raw());
  // If no type argument vector is provided, leave it as null, which is
  // equivalent to using dynamic as the type argument for the both key and value
  // types.
  if (!map_type_arguments.IsNull()) {
    ASSERT(map_type_arguments.Length() > 0);
    // Map literals take two type arguments.
    if (map_type_arguments.Length() == 2) {
      key_type = map_type_arguments.TypeAt(0);
      value_type = map_type_arguments.TypeAt(1);
      // Malformed type arguments are mapped to dynamic.
      ASSERT(!key_type.IsMalformed() && !value_type.IsMalformed());
      // No declared bounds in Map.
      ASSERT(!key_type.IsMalbounded() && !value_type.IsMalbounded());
      if (key_type.IsDynamicType() && value_type.IsDynamicType()) {
        map_type_arguments = TypeArguments::null();
      } else if (is_const && !type_arguments.IsInstantiated()) {
        ReportError(type_pos,
                    "the type arguments of a constant map literal cannot "
                    "include a type variable");
      }
    } else {
      if (I->error_on_bad_type()) {
        ReportError(type_pos,
                    "a map literal takes two type arguments specifying "
                    "the key type and the value type");
      }
      // Ignore type arguments.
      map_type_arguments = TypeArguments::null();
    }
  }
  ASSERT(map_type_arguments.IsNull() || (map_type_arguments.Length() == 2));
  map_type_arguments ^= map_type_arguments.Canonicalize();

  GrowableArray<AstNode*> kv_pairs_list;
  // Parse the map entries. Note: there may be an optional extra
  // comma after the last entry.
  while (CurrentToken() != Token::kRBRACE) {
    const bool saved_mode = SetAllowFunctionLiterals(true);
    const TokenPosition key_pos = TokenPos();
    AstNode* key = ParseExpr(is_const, kConsumeCascades);
    if (I->type_checks() && !is_const && !key_type.IsDynamicType()) {
      key = new (Z)
          AssignableNode(key_pos, key, key_type, Symbols::ListLiteralElement());
    }
    if (is_const) {
      ASSERT(key->IsLiteralNode());
      const Instance& key_value = key->AsLiteralNode()->literal();
      if (key_value.IsDouble()) {
        ReportError(key_pos, "key value must not be of type double");
      }
      if (!key_value.IsInteger() && !key_value.IsString() &&
          (key_value.clazz() != I->object_store()->symbol_class()) &&
          ImplementsEqualOperator(Z, key_value)) {
        ReportError(key_pos, "key value must not implement operator ==");
      }
    }
    ExpectToken(Token::kCOLON);
    const TokenPosition value_pos = TokenPos();
    AstNode* value = ParseExpr(is_const, kConsumeCascades);
    SetAllowFunctionLiterals(saved_mode);
    if (I->type_checks() && !is_const && !value_type.IsDynamicType()) {
      value = new (Z) AssignableNode(value_pos, value, value_type,
                                     Symbols::ListLiteralElement());
    }
    AddKeyValuePair(&kv_pairs_list, is_const, key, value);

    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
    } else if (CurrentToken() != Token::kRBRACE) {
      ReportError("comma or '}' expected");
    }
  }
  ASSERT(kv_pairs_list.length() % 2 == 0);
  ExpectToken(Token::kRBRACE);

  if (is_const) {
    // Create the key-value pair array, canonicalize it and then create
    // the immutable map object with it. This all happens at compile time.
    // The resulting immutable map object is returned as a literal.

    // First, create the canonicalized key-value pair array.
    Array& key_value_array =
        Array::ZoneHandle(Z, Array::New(kv_pairs_list.length(), Heap::kOld));
    AbstractType& arg_type = Type::Handle(Z);
    Error& bound_error = Error::Handle(Z);
    for (int i = 0; i < kv_pairs_list.length(); i++) {
      AstNode* arg = kv_pairs_list[i];
      // Arguments have been evaluated to a literal value already.
      ASSERT(arg->IsLiteralNode());
      ASSERT(!is_top_level_);  // We cannot check unresolved types.
      if (I->type_checks()) {
        if ((i % 2) == 0) {
          // Check key type.
          arg_type = key_type.raw();
        } else {
          // Check value type.
          arg_type = value_type.raw();
        }
        if (!arg_type.IsDynamicType() &&
            (!arg->AsLiteralNode()->literal().IsNull() &&
             !arg->AsLiteralNode()->literal().IsInstanceOf(
                 arg_type, Object::null_type_arguments(),
                 Object::null_type_arguments(), &bound_error))) {
          // If the failure is due to a bound error, display it.
          if (!bound_error.IsNull()) {
            ReportError(bound_error);
          } else {
            ReportError(
                arg->AsLiteralNode()->token_pos(),
                "map literal %s at index %d must be "
                "a constant of type '%s'",
                ((i % 2) == 0) ? "key" : "value", i >> 1,
                String::Handle(Z, arg_type.UserVisibleName()).ToCString());
          }
        }
      }
      key_value_array.SetAt(i, arg->AsLiteralNode()->literal());
    }
    key_value_array.MakeImmutable();
    key_value_array ^= TryCanonicalize(key_value_array, TokenPos());

    // Construct the map object.
    const Class& immutable_map_class =
        Class::Handle(Z, Library::LookupCoreClass(Symbols::ImmutableMap()));
    ASSERT(!immutable_map_class.IsNull());
    // If the immutable map class extends other parameterized classes, we need
    // to adjust the type argument vector. This is currently not the case.
    ASSERT(immutable_map_class.NumTypeArguments() == 2);
    ArgumentListNode* constr_args = new (Z) ArgumentListNode(TokenPos());
    constr_args->Add(new (Z) LiteralNode(literal_pos, key_value_array));
    const Function& map_constr = Function::ZoneHandle(
        Z, immutable_map_class.LookupConstructorAllowPrivate(
               Symbols::ImmutableMapConstructor()));
    ASSERT(!map_constr.IsNull());
    const Object& constructor_result = Object::Handle(
        Z, EvaluateConstConstructorCall(immutable_map_class, map_type_arguments,
                                        map_constr, constr_args));
    if (constructor_result.IsUnhandledException()) {
      ReportErrors(Error::Cast(constructor_result), script_, literal_pos,
                   "error executing const Map constructor");
    } else {
      const Instance& const_instance = Instance::Cast(constructor_result);
      CacheConstantValue(literal_pos, const_instance);
      return new (Z) LiteralNode(literal_pos,
                                 Instance::ZoneHandle(Z, const_instance.raw()));
    }
  } else {
    // Factory call at runtime.
    const Class& factory_class =
        Class::Handle(Z, Library::LookupCoreClass(Symbols::Map()));
    ASSERT(!factory_class.IsNull());
    const Function& factory_method = Function::ZoneHandle(
        Z, factory_class.LookupFactory(
               Library::PrivateCoreLibName(Symbols::MapLiteralFactory())));
    ASSERT(!factory_method.IsNull());
    if (!map_type_arguments.IsNull() && !map_type_arguments.IsInstantiated() &&
        (FunctionLevel() > 0)) {
      // Make sure that the instantiators are captured.
      CaptureAllInstantiators();
    }
    TypeArguments& factory_type_args =
        TypeArguments::ZoneHandle(Z, map_type_arguments.raw());
    // If the factory class extends other parameterized classes, adjust the
    // type argument vector.
    if (!factory_type_args.IsNull() && (factory_class.NumTypeArguments() > 2)) {
      ASSERT(factory_type_args.Length() == 2);
      Type& factory_type = Type::Handle(
          Z, Type::New(factory_class, factory_type_args, type_pos, Heap::kOld));
      // It is not strictly necessary to canonicalize factory_type, but only its
      // type argument vector.
      factory_type ^= CanonicalizeType(factory_type);
      factory_type_args = factory_type.arguments();
      ASSERT(factory_type_args.Length() == factory_class.NumTypeArguments());
      ASSERT(factory_type_args.IsCanonical());
    } else {
      factory_type_args = factory_type_args.Canonicalize();
    }
    ArgumentListNode* factory_param = new (Z) ArgumentListNode(literal_pos);
    // The kv_pair array is temporary and of element type dynamic. It is passed
    // to the factory to initialize a properly typed map. Pass a pre-allocated
    // array for the common empty map literal case.
    if (kv_pairs_list.length() == 0) {
      LiteralNode* empty_array_literal =
          new (Z) LiteralNode(TokenPos(), Object::empty_array());
      factory_param->Add(empty_array_literal);
    } else {
      ArrayNode* kv_pairs = new (Z) ArrayNode(
          TokenPos(), Type::ZoneHandle(Z, Type::ArrayType()), kv_pairs_list);
      factory_param->Add(kv_pairs);
    }

    return CreateConstructorCallNode(literal_pos, factory_type_args,
                                     factory_method, factory_param);
  }
  UNREACHABLE();
  return NULL;
}

AstNode* Parser::ParseCompoundLiteral() {
  TRACE_PARSER("ParseCompoundLiteral");
  bool is_const = false;
  if (CurrentToken() == Token::kCONST) {
    is_const = true;
    ConsumeToken();
  }
  const TokenPosition type_pos = TokenPos();
  TypeArguments& type_arguments = TypeArguments::Handle(
      Z, ParseTypeArguments(ClassFinalizer::kCanonicalize));
  // Malformed type arguments are mapped to dynamic, so we will not encounter
  // them here.
  // Map and List interfaces do not declare bounds on their type parameters, so
  // we will not see malbounded type arguments here.
  AstNode* primary = NULL;
  if ((CurrentToken() == Token::kLBRACK) || (CurrentToken() == Token::kINDEX)) {
    primary = ParseListLiteral(type_pos, is_const, type_arguments);
  } else if (CurrentToken() == Token::kLBRACE) {
    primary = ParseMapLiteral(type_pos, is_const, type_arguments);
  } else {
    UnexpectedToken();
  }
  return primary;
}

AstNode* Parser::ParseSymbolLiteral() {
  ASSERT(CurrentToken() == Token::kHASH);
  ConsumeToken();
  TokenPosition symbol_pos = TokenPos();
  String& symbol = String::ZoneHandle(Z);
  if (IsIdentifier()) {
    symbol = CurrentLiteral()->raw();
    ConsumeToken();
    GrowableHandlePtrArray<const String> pieces(Z, 3);
    pieces.Add(symbol);
    while (CurrentToken() == Token::kPERIOD) {
      pieces.Add(Symbols::Dot());
      ConsumeToken();
      pieces.Add(*ExpectIdentifier("identifier expected"));
    }
    symbol = Symbols::FromConcatAll(T, pieces);
  } else if (Token::CanBeOverloaded(CurrentToken())) {
    symbol = Symbols::Token(CurrentToken()).raw();
    ConsumeToken();
  } else {
    ReportError("illegal symbol literal");
  }
  ASSERT(symbol.IsSymbol());

  Instance& symbol_instance = Instance::ZoneHandle(Z);
  if (GetCachedConstant(symbol_pos, &symbol_instance)) {
    return new (Z) LiteralNode(symbol_pos, symbol_instance);
  }

  // Call Symbol class constructor to create a symbol instance.
  const Class& symbol_class = Class::Handle(I->object_store()->symbol_class());
  ASSERT(!symbol_class.IsNull());
  ArgumentListNode* constr_args = new (Z) ArgumentListNode(symbol_pos);
  constr_args->Add(new (Z) LiteralNode(symbol_pos, symbol));
  const Function& constr = Function::ZoneHandle(
      Z, symbol_class.LookupConstructor(Symbols::SymbolCtor()));
  ASSERT(!constr.IsNull());
  const Object& result =
      Object::Handle(Z, EvaluateConstConstructorCall(
                            symbol_class, TypeArguments::Handle(Z), constr,
                            constr_args, /*obfuscate_symbol_instances=*/false));
  if (result.IsUnhandledException()) {
    ReportErrors(Error::Cast(result), script_, symbol_pos,
                 "error executing const Symbol constructor");
  }
  symbol_instance ^= result.raw();
  CacheConstantValue(symbol_pos, symbol_instance);
  return new (Z) LiteralNode(symbol_pos, symbol_instance);
}

static String& BuildConstructorName(Thread* thread,
                                    const String& type_class_name,
                                    const String* named_constructor) {
  // By convention, the static function implementing a named constructor 'C'
  // for class 'A' is labeled 'A.C', and the static function implementing the
  // unnamed constructor for class 'A' is labeled 'A.'.
  // This convention prevents users from explicitly calling constructors.
  Zone* zone = thread->zone();
  String& constructor_name =
      String::Handle(zone, Symbols::FromDot(thread, type_class_name));
  if (named_constructor != NULL) {
    constructor_name =
        Symbols::FromConcat(thread, constructor_name, *named_constructor);
  }
  return constructor_name;
}

AstNode* Parser::ParseNewOperator(Token::Kind op_kind) {
  TRACE_PARSER("ParseNewOperator");
  const TokenPosition new_pos = TokenPos();
  ASSERT((op_kind == Token::kNEW) || (op_kind == Token::kCONST));
  bool is_const = (op_kind == Token::kCONST);
  if (!IsIdentifier()) {
    ReportError("type name expected");
  }
  TokenPosition type_pos = TokenPos();
  // Can't allocate const objects of a deferred type.
  const bool allow_deferred_type = !is_const;
  const Token::Kind la3 = LookaheadToken(3);
  const bool consume_unresolved_prefix =
      (la3 == Token::kLT) || (la3 == Token::kPERIOD);

  LibraryPrefix& prefix = LibraryPrefix::ZoneHandle(Z);
  AbstractType& type = AbstractType::ZoneHandle(
      Z, ParseType(ClassFinalizer::kCanonicalize, allow_deferred_type,
                   consume_unresolved_prefix, &prefix));

  if (FLAG_load_deferred_eagerly && !prefix.IsNull() &&
      prefix.is_deferred_load() && !prefix.is_loaded()) {
    // Add runtime check.
    Type& malformed_type = Type::ZoneHandle(Z);
    malformed_type = ClassFinalizer::NewFinalizedMalformedType(
        Error::Handle(Z),  // No previous error.
        script_, type_pos, "deferred type '%s.%s' is not yet loaded",
        String::Handle(Z, prefix.name()).ToCString(),
        String::Handle(type.Name()).ToCString());
    // Note: Adding a statement to current block is a hack, parsing an
    // expression should have no side-effect.
    current_block_->statements->Add(
        ThrowTypeError(type_pos, malformed_type, &prefix));
  }
  // In case the type is malformed, throw a dynamic type error after finishing
  // parsing the instance creation expression.
  if (!type.IsMalformed() && (type.IsTypeParameter() || type.IsDynamicType())) {
    // Replace the type with a malformed type.
    type = ClassFinalizer::NewFinalizedMalformedType(
        Error::Handle(Z),  // No previous error.
        script_, type_pos, "%s'%s' cannot be instantiated",
        type.IsTypeParameter() ? "type parameter " : "",
        type.IsTypeParameter()
            ? String::Handle(Z, type.UserVisibleName()).ToCString()
            : "dynamic");
  }
  // Attempting to instantiate an enum type is a compile-time error.
  Class& type_class = Class::Handle(Z, type.type_class());
  if (type_class.is_enum_class()) {
    ReportError(new_pos, "enum type '%s' can not be instantiated",
                String::Handle(Z, type_class.Name()).ToCString());
  }

  // The type can be followed by an optional named constructor identifier.
  // Note that we tell ParseType() above not to consume it as part of
  // a misinterpreted qualified identifier. Only a valid library
  // prefix is accepted as qualifier.
  String* named_constructor = NULL;
  if (CurrentToken() == Token::kPERIOD) {
    ConsumeToken();
    named_constructor = ExpectIdentifier("name of constructor expected");
  }

  // Parse constructor parameters.
  TokenPosition call_pos = TokenPos();
  CheckToken(Token::kLPAREN);
  ArgumentListNode* arguments =
      ParseActualParameters(NULL, TypeArguments::ZoneHandle(Z), is_const);

  // Parsing is complete, so we can return a throw in case of a malformed or
  // malbounded type or report a compile-time error if the constructor is const.
  if (type.IsMalformedOrMalbounded()) {
    if (is_const) {
      const Error& error = Error::Handle(Z, type.error());
      ReportError(error);
    }
    if (arguments->length() > 0) {
      // Evaluate arguments for side-effects and throw.
      LetNode* error_result = new (Z) LetNode(type_pos);
      for (intptr_t i = 0; i < arguments->length(); ++i) {
        error_result->AddNode(arguments->NodeAt(i));
      }
      error_result->AddNode(ThrowTypeError(type_pos, type));
      return error_result;
    }
    return ThrowTypeError(type_pos, type);
  }

  // Resolve the type and optional identifier to a constructor or factory.
  String& type_class_name = String::Handle(Z, type_class.Name());
  TypeArguments& type_arguments =
      TypeArguments::ZoneHandle(Z, type.arguments());

  // A constructor has an implicit 'this' parameter (instance to construct)
  // and a factory has an implicit 'this' parameter (type_arguments).
  intptr_t arguments_length = arguments->length() + 1;

  // An additional type check of the result of a redirecting factory may be
  // required.
  AbstractType& type_bound = AbstractType::ZoneHandle(Z);

  // Make sure that an appropriate constructor exists.
  String& constructor_name =
      BuildConstructorName(T, type_class_name, named_constructor);
  Function& constructor =
      Function::ZoneHandle(Z, type_class.LookupConstructor(constructor_name));
  if (constructor.IsNull()) {
    constructor = type_class.LookupFactory(constructor_name);
    if (constructor.IsNull()) {
      const String& external_constructor_name =
          (named_constructor ? constructor_name : type_class_name);
      // Replace the type with a malformed type and compile a throw or report a
      // compile-time error if the constructor is const.
      if (is_const) {
        type = ClassFinalizer::NewFinalizedMalformedType(
            Error::Handle(Z),  // No previous error.
            script_, call_pos,
            "class '%s' has no constructor or factory named '%s'",
            String::Handle(Z, type_class.Name()).ToCString(),
            external_constructor_name.ToCString());
        ReportError(Error::Handle(Z, type.error()));
      }
      return ThrowNoSuchMethodError(
          call_pos, type_class, external_constructor_name, arguments,
          InvocationMirror::kConstructor, InvocationMirror::kMethod,
          NULL);  // No existing function.
    } else if (constructor.IsRedirectingFactory()) {
      ClassFinalizer::ResolveRedirectingFactory(type_class, constructor);
      Type& redirect_type = Type::ZoneHandle(Z, constructor.RedirectionType());
      if (!redirect_type.IsMalformedOrMalbounded() &&
          !redirect_type.IsInstantiated()) {
        // No generic constructors allowed.
        ASSERT(redirect_type.IsInstantiated(kFunctions));
        // The type arguments of the redirection type are instantiated from the
        // type arguments of the parsed type of the 'new' or 'const' expression.
        Error& error = Error::Handle(Z);
        redirect_type ^= redirect_type.InstantiateFrom(
            type_arguments, Object::null_type_arguments(), kNoneFree, &error,
            NULL,  // instantiation_trail
            NULL,  // bound_trail
            Heap::kOld);
        if (!error.IsNull()) {
          redirect_type = ClassFinalizer::NewFinalizedMalformedType(
              error, script_, call_pos,
              "redirecting factory type '%s' cannot be instantiated",
              String::Handle(Z, redirect_type.UserVisibleName()).ToCString());
        }
      }
      if (!redirect_type.HasResolvedTypeClass()) {
        // If the redirection type is unresolved, we convert the allocation
        // into throwing a type error.
        const UnresolvedClass& cls =
            UnresolvedClass::Handle(Z, redirect_type.unresolved_class());
        const LibraryPrefix& prefix = LibraryPrefix::Cast(
            Object::Handle(Z, cls.library_or_library_prefix()));
        if (!prefix.IsNull() && !prefix.is_loaded() &&
            !FLAG_load_deferred_eagerly) {
          // If the redirection type is unresolved because it refers to
          // an unloaded deferred prefix, mark this function as depending
          // on the library prefix. It will then get invalidated when the
          // prefix is loaded.
          parsed_function()->AddDeferredPrefix(prefix);
        }
        redirect_type = ClassFinalizer::NewFinalizedMalformedType(
            Error::Handle(Z), script_, call_pos,
            "redirection type '%s' is not loaded",
            String::Handle(Z, redirect_type.UserVisibleName()).ToCString());
      }

      if (redirect_type.IsMalformedOrMalbounded()) {
        if (is_const) {
          ReportError(Error::Handle(Z, redirect_type.error()));
        }
        return ThrowTypeError(redirect_type.token_pos(), redirect_type);
      }
      if (I->type_checks() &&
          !redirect_type.IsSubtypeOf(type, NULL, NULL, Heap::kOld)) {
        // Additional type checking of the result is necessary.
        type_bound = type.raw();
      }
      type = redirect_type.raw();
      type_class = type.type_class();
      type_class_name = type_class.Name();
      type_arguments = type.arguments();
      constructor = constructor.RedirectionTarget();
      constructor_name = constructor.name();
      ASSERT(!constructor.IsNull());
    }
  }
  ASSERT(!constructor.IsNull());

  // It is a compile time error to instantiate a const instance of an
  // abstract class. Factory methods are ok.
  if (is_const && type_class.is_abstract() && !constructor.IsFactory()) {
    ReportError(new_pos, "cannot instantiate abstract class");
  }

  // It is ok to call a factory method of an abstract class, but it is
  // a dynamic error to instantiate an abstract class.
  if (type_class.is_abstract() && !constructor.IsFactory()) {
    // Evaluate arguments before throwing.
    LetNode* result = new (Z) LetNode(call_pos);
    for (intptr_t i = 0; i < arguments->length(); ++i) {
      result->AddNode(arguments->NodeAt(i));
    }
    ArgumentListNode* error_arguments = new (Z) ArgumentListNode(type_pos);
    error_arguments->Add(new (Z) LiteralNode(
        TokenPos(),
        Integer::ZoneHandle(Z, Integer::New(type_pos.value(), Heap::kOld))));
    error_arguments->Add(new (Z) LiteralNode(
        TokenPos(), String::ZoneHandle(Z, type_class_name.raw())));
    result->AddNode(MakeStaticCall(
        Symbols::AbstractClassInstantiationError(),
        Library::PrivateCoreLibName(Symbols::ThrowNew()), error_arguments));
    return result;
  }

  type_arguments ^= type_arguments.Canonicalize();

  const int kTypeArgsLen = 0;
  String& error_message = String::Handle(Z);
  if (!constructor.AreValidArguments(kTypeArgsLen, arguments_length,
                                     arguments->names(), &error_message)) {
    const String& external_constructor_name =
        (named_constructor ? constructor_name : type_class_name);
    if (is_const) {
      ReportError(call_pos,
                  "invalid arguments passed to constructor '%s' "
                  "for class '%s': %s",
                  external_constructor_name.ToCString(),
                  String::Handle(Z, type_class.Name()).ToCString(),
                  error_message.ToCString());
    }
    return ThrowNoSuchMethodError(call_pos, type_class,
                                  external_constructor_name, arguments,
                                  InvocationMirror::kConstructor,
                                  InvocationMirror::kMethod, &constructor);
  }

  // Return a throw in case of a malformed or malbounded type or report a
  // compile-time error if the constructor is const.
  if (type.IsMalformedOrMalbounded()) {
    if (is_const) {
      ReportError(Error::Handle(Z, type.error()));
    }
    return ThrowTypeError(type_pos, type);
  }

  // Make the constructor call.
  AstNode* new_object = NULL;
  if (is_const) {
    if (!constructor.is_const()) {
      const String& external_constructor_name =
          (named_constructor ? constructor_name : type_class_name);
      ReportError(
          "non-const constructor '%s' cannot be used in "
          "const object creation",
          external_constructor_name.ToCString());
    }

    Instance& const_instance = Instance::ZoneHandle(Z);
    if (GetCachedConstant(new_pos, &const_instance)) {
      // Cache hit, nothing else to do.
    } else {
      Object& constructor_result = Object::Handle(
          Z, EvaluateConstConstructorCall(type_class, type_arguments,
                                          constructor, arguments));
      if (constructor_result.IsUnhandledException()) {
        // It's a compile-time error if invocation of a const constructor
        // call fails.
        ReportErrors(Error::Cast(constructor_result), script_, new_pos,
                     "error while evaluating const constructor");
      }
      const_instance ^= constructor_result.raw();
      CacheConstantValue(new_pos, const_instance);
    }
    new_object = new (Z) LiteralNode(new_pos, const_instance);
    if (!type_bound.IsNull()) {
      ASSERT(!type_bound.IsMalformed());
      Error& bound_error = Error::Handle(Z);
      ASSERT(!is_top_level_);  // We cannot check unresolved types.
      if (!const_instance.IsInstanceOf(
              type_bound, Object::null_type_arguments(),
              Object::null_type_arguments(), &bound_error)) {
        type_bound = ClassFinalizer::NewFinalizedMalformedType(
            bound_error, script_, new_pos,
            "const factory result is not an instance of '%s'",
            String::Handle(Z, type_bound.UserVisibleName()).ToCString());
        new_object = ThrowTypeError(new_pos, type_bound);
      }
      type_bound = AbstractType::null();
    }
  } else {
    CheckConstructorCallTypeArguments(new_pos, constructor, type_arguments);
    if (!type_arguments.IsNull() && !type_arguments.IsInstantiated() &&
        (FunctionLevel() > 0)) {
      // Make sure that the instantiators are captured.
      CaptureAllInstantiators();
    }
    // If the type argument vector is not instantiated, we verify in checked
    // mode at runtime that it is within its declared bounds.
    new_object = CreateConstructorCallNode(new_pos, type_arguments, constructor,
                                           arguments);
  }
  if (!type_bound.IsNull()) {
    new_object = new (Z) AssignableNode(new_pos, new_object, type_bound,
                                        Symbols::FactoryResult());
  }
  return new_object;
}

String& Parser::Interpolate(const GrowableArray<AstNode*>& values) {
  NoReloadScope no_reload_scope(isolate(), thread());
  NoOOBMessageScope no_msg_scope(thread());
  const Class& cls =
      Class::Handle(Z, Library::LookupCoreClass(Symbols::StringBase()));
  ASSERT(!cls.IsNull());
  const Function& func = Function::Handle(
      Z, cls.LookupStaticFunction(
             Library::PrivateCoreLibName(Symbols::Interpolate())));
  ASSERT(!func.IsNull());

  // Build the array of literal values to interpolate.
  const Array& value_arr =
      Array::Handle(Z, Array::New(values.length(), Heap::kOld));
  for (int i = 0; i < values.length(); i++) {
    ASSERT(values[i]->IsLiteralNode());
    value_arr.SetAt(i, values[i]->AsLiteralNode()->literal());
  }

  // Build argument array to pass to the interpolation function.
  const Array& interpolate_arg = Array::Handle(Z, Array::New(1, Heap::kOld));
  interpolate_arg.SetAt(0, value_arr);

  // Call interpolation function.
  Object& result = Object::Handle(Z);
  result = DartEntry::InvokeFunction(func, interpolate_arg);
  if (result.IsUnhandledException()) {
    ReportError("%s", Error::Cast(result).ToErrorCString());
  }
  String& concatenated = String::ZoneHandle(Z);
  concatenated ^= result.raw();
  concatenated = Symbols::New(T, concatenated);
  return concatenated;
}

// A string literal consists of the concatenation of the next n tokens
// that satisfy the EBNF grammar:
// literal = kSTRING {{ interpol } kSTRING }
// interpol = kINTERPOL_VAR | (kINTERPOL_START expression kINTERPOL_END)
// In other words, the scanner breaks down interpolated strings so that
// a string literal always begins and ends with a kSTRING token.
AstNode* Parser::ParseStringLiteral(bool allow_interpolation) {
  TRACE_PARSER("ParseStringLiteral");
  AstNode* primary = NULL;
  const TokenPosition literal_start = TokenPos();
  ASSERT(CurrentToken() == Token::kSTRING);
  Token::Kind l1_token = LookaheadToken(1);
  if ((l1_token != Token::kSTRING) && (l1_token != Token::kINTERPOL_VAR) &&
      (l1_token != Token::kINTERPOL_START)) {
    // Common case: no interpolation.
    primary = new (Z) LiteralNode(literal_start, *CurrentLiteral());
    ConsumeToken();
    return primary;
  }
  // String interpolation needed.

  // First, check whether we've cached a compile-time constant for this
  // string interpolation.
  Instance& cached_string = Instance::Handle(Z);
  if (GetCachedConstant(literal_start, &cached_string)) {
    SkipStringLiteral();
    return new (Z) LiteralNode(literal_start,
                               Instance::ZoneHandle(Z, cached_string.raw()));
  }

  bool is_compiletime_const = true;
  bool has_interpolation = false;
  GrowableArray<AstNode*> values_list;
  while (CurrentToken() == Token::kSTRING) {
    if (CurrentLiteral()->Length() > 0) {
      // Only add non-empty string sections to the values list
      // that will be concatenated.
      values_list.Add(new (Z) LiteralNode(TokenPos(), *CurrentLiteral()));
    }
    ConsumeToken();
    while ((CurrentToken() == Token::kINTERPOL_VAR) ||
           (CurrentToken() == Token::kINTERPOL_START)) {
      if (!allow_interpolation) {
        ReportError("string interpolation not allowed in this context");
      }
      has_interpolation = true;
      AstNode* expr = NULL;
      const TokenPosition expr_pos = TokenPos();
      if (CurrentToken() == Token::kINTERPOL_VAR) {
        expr = ResolveIdent(TokenPos(), *CurrentLiteral(), true);
        ConsumeToken();
      } else {
        ASSERT(CurrentToken() == Token::kINTERPOL_START);
        ConsumeToken();
        const bool saved_mode = SetAllowFunctionLiterals(true);
        expr = ParseExpr(kAllowConst, kConsumeCascades);
        SetAllowFunctionLiterals(saved_mode);
        ExpectToken(Token::kINTERPOL_END);
      }
      // Check if this interpolated string is still considered a compile time
      // constant. If it is we need to evaluate if the current string part is
      // a constant or not. Only strings, numbers, booleans and null values
      // are allowed in compile time const interpolations.
      if (is_compiletime_const) {
        const Object* const_expr = expr->EvalConstExpr();
        if ((const_expr != NULL) &&
            (const_expr->IsNumber() || const_expr->IsString() ||
             const_expr->IsBool() || const_expr->IsNull())) {
          // Change expr into a literal.
          expr =
              new (Z) LiteralNode(expr_pos, EvaluateConstExpr(expr_pos, expr));
        } else {
          is_compiletime_const = false;
        }
      }
      values_list.Add(expr);
    }
  }
  if (is_compiletime_const) {
    if (has_interpolation) {
      const String& interpolated_string = Interpolate(values_list);
      primary = new (Z) LiteralNode(literal_start, interpolated_string);
      CacheConstantValue(literal_start, interpolated_string);
    } else {
      GrowableHandlePtrArray<const String> pieces(Z, values_list.length());
      for (int i = 0; i < values_list.length(); i++) {
        const Instance& part = values_list[i]->AsLiteralNode()->literal();
        ASSERT(part.IsString());
        pieces.Add(String::Cast(part));
      }
      const String& lit =
          String::ZoneHandle(Z, Symbols::FromConcatAll(T, pieces));
      primary = new (Z) LiteralNode(literal_start, lit);
      // Caching of constant not necessary because the symbol lookup will
      // find the value next time.
    }
  } else {
    ArrayNode* values = new (Z) ArrayNode(
        TokenPos(), Type::ZoneHandle(Z, Type::ArrayType()), values_list);
    primary = new (Z) StringInterpolateNode(TokenPos(), values);
  }
  return primary;
}

AstNode* Parser::ParsePrimary() {
  TRACE_PARSER("ParsePrimary");
  ASSERT(!is_top_level_);
  AstNode* primary = NULL;
  const Token::Kind token = CurrentToken();
  if (IsFunctionLiteral()) {
    primary = ParseFunctionStatement(true);
  } else if (IsIdentifier()) {
    TokenPosition qual_ident_pos = TokenPos();
    const LibraryPrefix& prefix = LibraryPrefix::ZoneHandle(Z, ParsePrefix());
    if (!prefix.IsNull()) {
      ExpectToken(Token::kPERIOD);
    }
    String& ident = *CurrentLiteral();
    ConsumeToken();
    if (prefix.IsNull()) {
      intptr_t primary_func_level = 0;
      ResolveIdentInLocalScope(qual_ident_pos, ident, &primary,
                               &primary_func_level);
      // Check whether the identifier is shadowed by a function type parameter.
      if (InGenericFunctionScope()) {
        intptr_t type_param_func_level = FunctionLevel();
        TypeParameter& type_param = TypeParameter::ZoneHandle(
            Z, innermost_function().LookupTypeParameter(
                   ident, &type_param_func_level));
        if (!type_param.IsNull()) {
          if ((primary == NULL) ||
              (primary_func_level < type_param_func_level)) {
            // The identifier is a function type parameter, possibly shadowing
            // already resolved 'primary'.
            return new (Z) PrimaryNode(qual_ident_pos, type_param);
          }
        }
      }
      if (primary == NULL) {
        // Check whether the identifier is a type parameter.
        if (!current_class().IsNull()) {
          TypeParameter& type_param = TypeParameter::ZoneHandle(
              Z, current_class().LookupTypeParameter(ident));
          if (!type_param.IsNull()) {
            return new (Z) PrimaryNode(qual_ident_pos, type_param);
          }
        }
        // This is a non-local unqualified identifier so resolve the
        // identifier locally in the main app library and all libraries
        // imported by it.
        primary = ResolveIdentInCurrentLibraryScope(qual_ident_pos, ident);
      }
    } else {
      // This is a qualified identifier with a library prefix so resolve
      // the identifier locally in that library (we do not include the
      // libraries imported by that library).
      primary = ResolveIdentInPrefixScope(qual_ident_pos, prefix, ident);

      // If the identifier could not be resolved, throw a NoSuchMethodError.
      // Note: unlike in the case of an unqualified identifier, do not
      // interpret the unresolved identifier as an instance method or
      // instance getter call when compiling an instance method.
      if (primary == NULL) {
        if (prefix.is_deferred_load() && ident.Equals(Symbols::LoadLibrary())) {
          // Hack Alert: recognize special 'loadLibrary' call on the
          // prefix object. The prefix is the primary. Rewind parser and
          // let ParseSelectors() handle the loadLibrary call.
          SetPosition(qual_ident_pos);
          ConsumeToken();  // Prefix name.
          primary = new (Z) LiteralNode(qual_ident_pos, prefix);
        } else {
          GrowableHandlePtrArray<const String> pieces(Z, 3);
          pieces.Add(String::Handle(Z, prefix.name()));
          pieces.Add(Symbols::Dot());
          pieces.Add(ident);
          const String& qualified_name =
              String::ZoneHandle(Z, Symbols::FromConcatAll(T, pieces));
          primary = new (Z) PrimaryNode(qual_ident_pos, qualified_name);
          if (prefix.is_deferred_load()) {
            primary->AsPrimaryNode()->set_prefix(&prefix);
          }
        }
      } else if (FLAG_load_deferred_eagerly && prefix.is_deferred_load()) {
        // primary != NULL.
        GrowableHandlePtrArray<const String> pieces(Z, 3);
        pieces.Add(String::Handle(Z, prefix.name()));
        pieces.Add(Symbols::Dot());
        pieces.Add(ident);
        const String& qualified_name =
            String::ZoneHandle(Z, Symbols::FromConcatAll(T, pieces));
        InvocationMirror::Kind call_kind = CurrentToken() == Token::kLPAREN
                                               ? InvocationMirror::kMethod
                                               : InvocationMirror::kGetter;
        // Note: Adding a statement to current block is a hack, parsing an
        // expression should have no side-effect.
        current_block_->statements->Add(ThrowNoSuchMethodError(
            qual_ident_pos, current_class(), qualified_name,
            NULL,  // No arguments.
            InvocationMirror::kTopLevel, call_kind,
            NULL,  // No existing function.
            &prefix));
      }
    }
    ASSERT(primary != NULL);
  } else if (token == Token::kTHIS) {
    LocalVariable* local = LookupLocalScope(Symbols::This());
    if (local == NULL) {
      ReportError("receiver 'this' is not in scope");
    }
    primary = new (Z) LoadLocalNode(TokenPos(), local);
    ConsumeToken();
  } else if (token == Token::kINTEGER) {
    const Integer& literal = Integer::ZoneHandle(Z, CurrentIntegerLiteral());
    primary = new (Z) LiteralNode(TokenPos(), literal);
    ConsumeToken();
  } else if (token == Token::kTRUE) {
    primary = new (Z) LiteralNode(TokenPos(), Bool::True());
    ConsumeToken();
  } else if (token == Token::kFALSE) {
    primary = new (Z) LiteralNode(TokenPos(), Bool::False());
    ConsumeToken();
  } else if (token == Token::kNULL) {
    primary = new (Z) LiteralNode(TokenPos(), Object::null_instance());
    ConsumeToken();
  } else if (token == Token::kLPAREN) {
    ConsumeToken();
    const bool saved_mode = SetAllowFunctionLiterals(true);
    primary = ParseExpr(kAllowConst, kConsumeCascades);
    SetAllowFunctionLiterals(saved_mode);
    ExpectToken(Token::kRPAREN);
  } else if (token == Token::kDOUBLE) {
    const Double& double_value = Double::ZoneHandle(Z, CurrentDoubleLiteral());
    if (double_value.IsNull()) {
      ReportError("invalid double literal");
    }
    primary = new (Z) LiteralNode(TokenPos(), double_value);
    ConsumeToken();
  } else if (token == Token::kSTRING) {
    primary = ParseStringLiteral(true);
  } else if (token == Token::kNEW) {
    ConsumeToken();
    primary = ParseNewOperator(Token::kNEW);
  } else if (token == Token::kCONST) {
    if ((LookaheadToken(1) == Token::kLT) ||
        (LookaheadToken(1) == Token::kLBRACK) ||
        (LookaheadToken(1) == Token::kINDEX) ||
        (LookaheadToken(1) == Token::kLBRACE)) {
      primary = ParseCompoundLiteral();
    } else {
      ConsumeToken();
      primary = ParseNewOperator(Token::kCONST);
    }
  } else if (token == Token::kLT || token == Token::kLBRACK ||
             token == Token::kINDEX || token == Token::kLBRACE) {
    primary = ParseCompoundLiteral();
  } else if (token == Token::kHASH) {
    primary = ParseSymbolLiteral();
  } else if (token == Token::kSUPER) {
    if (current_function().is_static()) {
      ReportError("cannot access superclass from static method");
    }
    if (current_class().SuperClass() == Class::null()) {
      ReportError("class '%s' does not have a superclass",
                  String::Handle(Z, current_class().Name()).ToCString());
    }
    const TokenPosition super_pos = TokenPos();
    ConsumeToken();
    if (CurrentToken() == Token::kPERIOD) {
      ConsumeToken();
      const TokenPosition ident_pos = TokenPos();
      const String& ident = *ExpectIdentifier("identifier expected");
      if (IsArgumentPart()) {
        TypeArguments& func_type_args = TypeArguments::ZoneHandle(Z);
        if (CurrentToken() == Token::kLT) {
          // Type arguments.
          if (!FLAG_generic_method_syntax) {
            ReportError("generic type arguments not supported.");
          }
          func_type_args = ParseTypeArguments(ClassFinalizer::kCanonicalize);
          if (FLAG_reify_generic_functions) {
            if (!func_type_args.IsNull() && !func_type_args.IsInstantiated() &&
                (FunctionLevel() > 0)) {
              // Make sure that the instantiators are captured.
              CaptureAllInstantiators();
            }
          } else {
            func_type_args = TypeArguments::null();
          }
        }
        primary = ParseSuperCall(ident, func_type_args);
      } else {
        primary = ParseSuperFieldAccess(ident, ident_pos);
      }
    } else if ((CurrentToken() == Token::kLBRACK) ||
               Token::CanBeOverloaded(CurrentToken()) ||
               (CurrentToken() == Token::kNE)) {
      primary = ParseSuperOperator();
    } else if (CurrentToken() == Token::kQM_PERIOD) {
      ReportError("super call or super getter may not use ?.");
    } else {
      primary = new (Z) PrimaryNode(super_pos, Symbols::Super());
    }
  } else {
    UnexpectedToken();
  }
  return primary;
}

// Evaluate expression in expr and return the value. The expression must
// be a compile time constant.
const Instance& Parser::EvaluateConstExpr(TokenPosition expr_pos,
                                          AstNode* expr) {
  NoReloadScope no_reload_scope(isolate(), thread());
  NoOOBMessageScope no_msg_scope(thread());
  if (expr->IsLiteralNode()) {
    return expr->AsLiteralNode()->literal();
  } else if (expr->IsLoadLocalNode() &&
             expr->AsLoadLocalNode()->local().IsConst()) {
    return *expr->AsLoadLocalNode()->local().ConstValue();
  } else if (expr->IsLoadStaticFieldNode()) {
    const Field& field = expr->AsLoadStaticFieldNode()->field();
    // We already checked that this field is const and has been
    // initialized.
    ASSERT(field.is_const());
    ASSERT(field.StaticValue() != Object::sentinel().raw());
    ASSERT(field.StaticValue() != Object::transition_sentinel().raw());
    return Instance::ZoneHandle(Z, field.StaticValue());
  } else if (expr->IsTypeNode()) {
    AbstractType& type =
        AbstractType::ZoneHandle(Z, expr->AsTypeNode()->type().raw());
    ASSERT(type.IsInstantiated() && !type.IsMalformedOrMalbounded());
    return type;
  } else if (expr->IsClosureNode()) {
    const Function& func = expr->AsClosureNode()->function();
    ASSERT((func.IsImplicitStaticClosureFunction()));
    Instance& closure = Instance::ZoneHandle(Z, func.ImplicitStaticClosure());
    closure = TryCanonicalize(closure, expr_pos);
    return closure;
  } else {
    ASSERT(expr->EvalConstExpr() != NULL);
    Instance& value = Instance::ZoneHandle(Z);
    if (GetCachedConstant(expr_pos, &value)) {
      return value;
    }
    ReturnNode* ret = new (Z) ReturnNode(expr_pos, expr);
    // Compile time constant expressions cannot reference anything from a
    // local scope.
    LocalScope* empty_scope = new (Z) LocalScope(NULL, 0, 0);
    SequenceNode* seq = new (Z) SequenceNode(expr_pos, empty_scope);
    seq->Add(ret);

    INC_STAT(thread_, num_execute_const, 1);
    Object& result = Object::Handle(Z, Compiler::ExecuteOnce(seq));
    if (result.IsError()) {
      ReportErrors(Error::Cast(result), script_, expr_pos,
                   "error evaluating constant expression");
    }
    ASSERT(result.IsInstance() || result.IsNull());
    value ^= result.raw();
    value = TryCanonicalize(value, expr_pos);
    CacheConstantValue(expr_pos, value);
    return value;
  }
}

void Parser::SkipFunctionLiteral() {
  if (IsIdentifier()) {
    if (LookaheadToken(1) != Token::kLPAREN) {
      SkipTypeOrFunctionType(true);
    }
    ExpectIdentifier("function name expected");
  }
  if (CurrentToken() == Token::kLPAREN) {
    SkipToMatchingParenthesis();
  }
  RawFunction::AsyncModifier async_modifier = ParseFunctionModifier();
  BoolScope allow_await(&this->await_is_keyword_,
                        async_modifier != RawFunction::kNoModifier);
  if (CurrentToken() == Token::kLBRACE) {
    SkipBlock();
    ExpectToken(Token::kRBRACE);
  } else if (CurrentToken() == Token::kARROW) {
    ConsumeToken();
    SkipExpr();
  }
}

// Skips function/method/constructor/getter/setter preambles until the formal
// parameter list. It is enough to skip the tokens, since we have already
// previously parsed the function.
void Parser::SkipFunctionPreamble() {
  while (true) {
    if (IsFunctionTypeSymbol()) {
      ConsumeToken();
      SkipTypeParameters();
      SkipToMatchingParenthesis();
      continue;
    }
    const Token::Kind token = CurrentToken();
    if (token == Token::kLPAREN) {
      return;
    }
    if (token == Token::kGET) {
      if (LookaheadToken(1) == Token::kLT) {
        // Case: Generic Function/method named get.
        ConsumeToken();  // Parse away 'get' (the function's name).
        SkipTypeParameters();
        continue;
      }
      if (LookaheadToken(1) == Token::kLPAREN) {
        // Case: Function/method named get.
        ConsumeToken();  // Parse away 'get' (the function's name).
        return;
      }
      // Case: Getter.
      ConsumeToken();  // Parse away 'get'.
      ConsumeToken();  // Parse away the getter name.
      return;
    }
    ConsumeToken();  // Can be static, factory, operator, void, ident, etc...
  }
}

void Parser::SkipListLiteral() {
  if (CurrentToken() == Token::kINDEX) {
    // Empty list literal.
    ConsumeToken();
    return;
  }
  ExpectToken(Token::kLBRACK);
  while (CurrentToken() != Token::kRBRACK) {
    SkipNestedExpr();
    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
    } else {
      break;
    }
  }
  ExpectToken(Token::kRBRACK);
}

void Parser::SkipMapLiteral() {
  ExpectToken(Token::kLBRACE);
  while (CurrentToken() != Token::kRBRACE) {
    SkipNestedExpr();
    ExpectToken(Token::kCOLON);
    SkipNestedExpr();
    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
    } else {
      break;
    }
  }
  ExpectToken(Token::kRBRACE);
}

void Parser::SkipActualParameters() {
  if (CurrentToken() == Token::kLT) {
    SkipTypeArguments();
  }
  ExpectToken(Token::kLPAREN);
  while (CurrentToken() != Token::kRPAREN) {
    if (IsIdentifier() && (LookaheadToken(1) == Token::kCOLON)) {
      // Named actual parameter.
      ConsumeToken();
      ConsumeToken();
    }
    SkipNestedExpr();
    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
    }
  }
  ExpectToken(Token::kRPAREN);
}

void Parser::SkipCompoundLiteral() {
  if (CurrentToken() == Token::kLT) {
    SkipTypeArguments();
  }
  if ((CurrentToken() == Token::kLBRACK) || (CurrentToken() == Token::kINDEX)) {
    SkipListLiteral();
  } else if (CurrentToken() == Token::kLBRACE) {
    SkipMapLiteral();
  }
}

void Parser::SkipSymbolLiteral() {
  ConsumeToken();  // Hash sign.
  if (IsIdentifier()) {
    ConsumeToken();
    while (CurrentToken() == Token::kPERIOD) {
      ConsumeToken();
      ExpectIdentifier("identifier expected");
    }
  } else if (Token::CanBeOverloaded(CurrentToken())) {
    ConsumeToken();
  } else {
    UnexpectedToken();
  }
}

void Parser::SkipNewOperator() {
  ConsumeToken();  // Skip new or const keyword.
  if (IsIdentifier()) {
    SkipType(false);
    if (CurrentToken() == Token::kPERIOD) {
      ConsumeToken();
      ExpectIdentifier("identifier expected");
    }
    if (CurrentToken() == Token::kLPAREN) {
      SkipActualParameters();
      return;
    }
  }
}

void Parser::SkipStringLiteral() {
  ASSERT(CurrentToken() == Token::kSTRING);
  while (CurrentToken() == Token::kSTRING) {
    ConsumeToken();
    while (true) {
      if (CurrentToken() == Token::kINTERPOL_VAR) {
        ConsumeToken();
      } else if (CurrentToken() == Token::kINTERPOL_START) {
        ConsumeToken();
        const bool saved_mode = SetAllowFunctionLiterals(true);
        SkipExpr();
        SetAllowFunctionLiterals(saved_mode);
        ExpectToken(Token::kINTERPOL_END);
      } else {
        break;
      }
    }
  }
}

void Parser::SkipPrimary() {
  if (IsFunctionLiteral()) {
    SkipFunctionLiteral();
    return;
  }
  switch (CurrentToken()) {
    case Token::kTHIS:
    case Token::kSUPER:
    case Token::kNULL:
    case Token::kTRUE:
    case Token::kFALSE:
    case Token::kINTEGER:
    case Token::kDOUBLE:
      ConsumeToken();
      break;
    case Token::kIDENT:
      ConsumeToken();
      break;
    case Token::kSTRING:
      SkipStringLiteral();
      break;
    case Token::kLPAREN:
      ConsumeToken();
      SkipNestedExpr();
      ExpectToken(Token::kRPAREN);
      break;
    case Token::kNEW:
      SkipNewOperator();
      break;
    case Token::kCONST:
      if ((LookaheadToken(1) == Token::kLT) ||
          (LookaheadToken(1) == Token::kLBRACE) ||
          (LookaheadToken(1) == Token::kLBRACK) ||
          (LookaheadToken(1) == Token::kINDEX)) {
        ConsumeToken();
        SkipCompoundLiteral();
      } else {
        SkipNewOperator();
      }
      break;
    case Token::kLT:
    case Token::kLBRACE:
    case Token::kLBRACK:
    case Token::kINDEX:
      SkipCompoundLiteral();
      break;
    case Token::kHASH:
      SkipSymbolLiteral();
      break;
    default:
      if (IsIdentifier()) {
        ConsumeToken();  // Handle pseudo-keyword identifiers.
      } else {
        UnexpectedToken();
        UNREACHABLE();
      }
      break;
  }
}

void Parser::SkipSelectors() {
  while (true) {
    const Token::Kind current_token = CurrentToken();
    if (current_token == Token::kCASCADE) {
      ConsumeToken();
      if (CurrentToken() == Token::kLBRACK) {
        continue;  // Consume [ in next loop iteration.
      } else {
        ExpectIdentifier("identifier or [ expected after ..");
      }
    } else if ((current_token == Token::kPERIOD) ||
               (current_token == Token::kQM_PERIOD)) {
      ConsumeToken();
      ExpectIdentifier("identifier expected");
    } else if (current_token == Token::kLBRACK) {
      ConsumeToken();
      SkipNestedExpr();
      ExpectToken(Token::kRBRACK);
    } else if (IsArgumentPart()) {
      SkipActualParameters();
    } else {
      break;
    }
  }
}

void Parser::SkipPostfixExpr() {
  SkipPrimary();
  SkipSelectors();
  if (IsIncrementOperator(CurrentToken())) {
    ConsumeToken();
  }
}

void Parser::SkipUnaryExpr() {
  if (IsPrefixOperator(CurrentToken()) || IsIncrementOperator(CurrentToken()) ||
      IsAwaitKeyword()) {
    ConsumeToken();
    SkipUnaryExpr();
  } else {
    SkipPostfixExpr();
  }
}

void Parser::SkipBinaryExpr() {
  SkipUnaryExpr();
  const int min_prec = Token::Precedence(Token::kIFNULL);
  const int max_prec = Token::Precedence(Token::kMUL);
  while (((min_prec <= Token::Precedence(CurrentToken())) &&
          (Token::Precedence(CurrentToken()) <= max_prec))) {
    if (CurrentToken() == Token::kIS) {
      ConsumeToken();
      if (CurrentToken() == Token::kNOT) {
        ConsumeToken();
      }
      SkipTypeOrFunctionType(false);
    } else if (CurrentToken() == Token::kAS) {
      ConsumeToken();
      SkipTypeOrFunctionType(false);
    } else {
      ConsumeToken();
      SkipUnaryExpr();
    }
  }
}

void Parser::SkipConditionalExpr() {
  SkipBinaryExpr();
  if (CurrentToken() == Token::kCONDITIONAL) {
    ConsumeToken();
    SkipExpr();
    ExpectToken(Token::kCOLON);
    SkipExpr();
  }
}

void Parser::SkipExpr() {
  while (CurrentToken() == Token::kTHROW) {
    ConsumeToken();
  }
  SkipConditionalExpr();
  if (CurrentToken() == Token::kCASCADE) {
    SkipSelectors();
  }
  if (Token::IsAssignmentOperator(CurrentToken())) {
    ConsumeToken();
    SkipExpr();
  }
}

void Parser::SkipNestedExpr() {
  const bool saved_mode = SetAllowFunctionLiterals(true);
  SkipExpr();
  SetAllowFunctionLiterals(saved_mode);
}

void Parser::SkipQualIdent() {
  ASSERT(IsIdentifier());
  ConsumeToken();
  if (CurrentToken() == Token::kPERIOD) {
    ConsumeToken();  // Consume the kPERIOD token.
    ExpectIdentifier("identifier expected after '.'");
  }
}

}  // namespace dart

#else  // DART_PRECOMPILED_RUNTIME

namespace dart {

void ParsedFunction::AddToGuardedFields(const Field* field) const {
  UNREACHABLE();
}

kernel::ScopeBuildingResult* ParsedFunction::EnsureKernelScopes() {
  UNREACHABLE();
  return NULL;
}

LocalVariable* ParsedFunction::EnsureExpressionTemp() {
  UNREACHABLE();
  return NULL;
}

void ParsedFunction::SetNodeSequence(SequenceNode* node_sequence) {
  UNREACHABLE();
}

void ParsedFunction::SetRegExpCompileData(
    RegExpCompileData* regexp_compile_data) {
  UNREACHABLE();
}

void ParsedFunction::AllocateVariables() {
  UNREACHABLE();
}

void ParsedFunction::AllocateIrregexpVariables(intptr_t num_stack_locals) {
  UNREACHABLE();
}

void ParsedFunction::Bailout(const char* origin, const char* reason) const {
  UNREACHABLE();
}

void Parser::ParseCompilationUnit(const Library& library,
                                  const Script& script) {
  UNREACHABLE();
}

void Parser::ParseClass(const Class& cls) {
  UNREACHABLE();
}

RawObject* Parser::ParseFunctionParameters(const Function& func) {
  UNREACHABLE();
  return Object::null();
}

void Parser::ParseFunction(ParsedFunction* parsed_function) {
  UNREACHABLE();
}

RawObject* Parser::ParseMetadata(const Field& meta_data) {
  UNREACHABLE();
  return Object::null();
}

ParsedFunction* Parser::ParseStaticFieldInitializer(const Field& field) {
  UNREACHABLE();
  return NULL;
}

void Parser::InsertCachedConstantValue(const Script& script,
                                       TokenPosition token_pos,
                                       const Instance& value) {
  UNREACHABLE();
}

ArgumentListNode* Parser::BuildNoSuchMethodArguments(
    TokenPosition call_pos,
    const String& function_name,
    const ArgumentListNode& function_args,
    const LocalVariable* temp_for_last_arg,
    bool is_super_invocation) {
  UNREACHABLE();
  return NULL;
}

bool Parser::FieldHasFunctionLiteralInitializer(const Field& field,
                                                TokenPosition* start,
                                                TokenPosition* end) {
  UNREACHABLE();
  return false;
}

}  // namespace dart

#endif  // DART_PRECOMPILED_RUNTIME
