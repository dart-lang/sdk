// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/parser.h"

#include "vm/bigint_operations.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/compiler_stats.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/longjump.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/scopes.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, enable_asserts, false, "Enable assert statements.");
DEFINE_FLAG(bool, enable_type_checks, false, "Enable type checks.");
DEFINE_FLAG(bool, trace_parser, false, "Trace parser operations.");
DEFINE_FLAG(bool, warning_as_error, false, "Treat warnings as errors.");
DEFINE_FLAG(bool, silent_warnings, false, "Silence warnings.");
DEFINE_FLAG(bool, warn_legacy_map_literal, false,
            "Warning on legacy map literal syntax (single type argument)");
DEFINE_FLAG(bool, warn_legacy_getters, false,
            "Warning on legacy getter syntax");
DEFINE_FLAG(bool, strict_function_literals, false,
            "enforce new function literal rules");
DEFINE_FLAG(bool, fail_legacy_abstract, false,
            "error on explicit use of abstract on class members");

static void CheckedModeHandler(bool value) {
  FLAG_enable_asserts = value;
  FLAG_enable_type_checks = value;
}

// --enable-checked-mode and --checked both enable checked mode which is
// equivalent to setting --enable-asserts and --enable-type-checks.
DEFINE_FLAG_HANDLER(CheckedModeHandler,
                    enable_checked_mode,
                    "Enable checked mode.");

DEFINE_FLAG_HANDLER(CheckedModeHandler,
                    checked,
                    "Enable checked mode.");

#if defined(DEBUG)
class TraceParser : public ValueObject {
 public:
  TraceParser(intptr_t token_pos, const Script& script, const char* msg) {
    if (FLAG_trace_parser) {
      // Skips tracing of bootstrap libraries.
      if (script.HasSource()) {
        intptr_t line, column;
        script.GetTokenLocation(token_pos, &line, &column);
        PrintIndent();
        OS::Print("%s (line %"Pd", col %"Pd", token %"Pd")\n",
                  msg, line, column, token_pos);
      }
      indent_++;
    }
  }
  ~TraceParser() { indent_--; }
 private:
  void PrintIndent() {
    for (int i = 0; i < indent_; i++) { OS::Print(". "); }
  }
  static int indent_;
};

int TraceParser::indent_ = 0;

#define TRACE_PARSER(s) \
  TraceParser __p__(this->TokenPos(), this->script_, s)

#else  // not DEBUG
#define TRACE_PARSER(s)
#endif  // DEBUG


static RawTypeArguments* NewTypeArguments(const GrowableObjectArray& objs) {
  const TypeArguments& a =
      TypeArguments::Handle(TypeArguments::New(objs.Length()));
  AbstractType& type = AbstractType::Handle();
  for (int i = 0; i < objs.Length(); i++) {
    type ^= objs.At(i);
    a.SetTypeAt(i, type);
  }
  // Cannot canonicalize TypeArgument yet as its types may not have been
  // finalized yet.
  return a.raw();
}


static ThrowNode* GenerateRethrow(intptr_t token_pos, const Object& obj) {
  const UnhandledException& excp = UnhandledException::Cast(obj);
  Instance& exception = Instance::ZoneHandle(excp.exception());
  if (exception.IsNew()) {
    exception ^= Object::Clone(exception, Heap::kOld);
  }
  Instance& stack_trace = Instance::ZoneHandle(excp.stacktrace());
  if (stack_trace.IsNew()) {
    stack_trace ^= Object::Clone(stack_trace, Heap::kOld);
  }
  return new ThrowNode(token_pos,
                       new LiteralNode(token_pos, exception),
                       new LiteralNode(token_pos, stack_trace));
}


LocalVariable* ParsedFunction::CreateExpressionTempVar(intptr_t token_pos) {
  return new LocalVariable(token_pos,
                           String::ZoneHandle(Symbols::ExprTemp()),
                           Type::ZoneHandle(Type::DynamicType()));
}


void ParsedFunction::SetNodeSequence(SequenceNode* node_sequence) {
  ASSERT(node_sequence_ == NULL);
  ASSERT(node_sequence != NULL);
  node_sequence_ = node_sequence;
}


LocalVariable* ParsedFunction::GetSavedArgumentsDescriptorVar() const {
  const int num_parameters = function().NumParameters();
  LocalScope* scope = node_sequence()->scope();
  if (scope->num_variables() > num_parameters) {
    LocalVariable* saved_args_desc_var = scope->VariableAt(num_parameters);
    ASSERT(saved_args_desc_var != NULL);
    // The scope of the formal parameters may also contain at this position
    // an alias for the saved arguments descriptor variable of the enclosing
    // function (check its scope owner) or an internal variable such as the
    // expression temp variable or the saved entry context variable (check its
    // name).
    if ((saved_args_desc_var->owner() == scope) &&
        saved_args_desc_var->name().StartsWith(
            String::Handle(Symbols::SavedArgDescVarPrefix()))) {
      return saved_args_desc_var;
    }
  }
  return NULL;
}


void ParsedFunction::AllocateVariables() {
  LocalScope* scope = node_sequence()->scope();
  const intptr_t num_fixed_params = function().num_fixed_parameters();
  const intptr_t num_opt_params = function().NumOptionalParameters();
  intptr_t num_params = num_fixed_params + num_opt_params;
  // Compute start indices to parameters and locals, and the number of
  // parameters to copy.
  if (num_opt_params == 0) {
    // Parameter i will be at fp[1 + num_params - i] and local variable
    // j will be at fp[kFirstLocalSlotIndex - j].
    ASSERT(GetSavedArgumentsDescriptorVar() == NULL);
    first_parameter_index_ = 1 + num_params;
    first_stack_local_index_ = kFirstLocalSlotIndex;
    num_copied_params_ = 0;
  } else {
    // Parameter i will be at fp[kFirstLocalSlotIndex - i] and local variable
    // j will be at fp[kFirstLocalSlotIndex - num_params - j].
    // The saved argument descriptor variable must be allocated similarly to
    // a parameter, so that it gets both a frame slot and a context slot when
    // captured.
    if (GetSavedArgumentsDescriptorVar() != NULL) {
      num_params += 1;
    }
    first_parameter_index_ = kFirstLocalSlotIndex;
    first_stack_local_index_ = first_parameter_index_ - num_params;
    num_copied_params_ = num_params;
  }

  // Allocate parameters and local variables, either in the local frame or
  // in the context(s).
  LocalScope* context_owner = NULL;  // No context needed yet.
  int next_free_frame_index =
      scope->AllocateVariables(first_parameter_index_,
                               num_params,
                               first_stack_local_index_,
                               scope,
                               &context_owner);

  // If this function is not a closure function and if it contains captured
  // variables, the context needs to be saved on entry and restored on exit.
  // Add and allocate a local variable to this purpose.
  if ((context_owner != NULL) && !function().IsClosureFunction()) {
    const String& context_var_name =
        String::ZoneHandle(Symbols::SavedEntryContextVar());
    LocalVariable* context_var =
        new LocalVariable(function().token_pos(),
                          context_var_name,
                          Type::ZoneHandle(Type::DynamicType()));
    context_var->set_index(next_free_frame_index--);
    scope->AddVariable(context_var);
    set_saved_context_var(context_var);
  }

  // Frame indices are relative to the frame pointer and are decreasing.
  ASSERT(next_free_frame_index <= first_stack_local_index_);
  num_stack_locals_ = first_stack_local_index_ - next_free_frame_index;
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
class Parser::TryBlocks : public ZoneAllocated {
 public:
  TryBlocks(Block* try_block, TryBlocks* outer_try_block)
      : try_block_(try_block),
        inlined_finally_nodes_(),
        outer_try_block_(outer_try_block) { }

  TryBlocks* outer_try_block() const { return outer_try_block_; }
  Block* try_block() const { return try_block_; }

  void AddNodeForFinallyInlining(AstNode* node);
  AstNode* GetNodeToInlineFinally(int index) {
    if (0 <= index && index < inlined_finally_nodes_.length()) {
      return inlined_finally_nodes_[index];
    }
    return NULL;
  }

 private:
  Block* try_block_;
  GrowableArray<AstNode*> inlined_finally_nodes_;
  TryBlocks* outer_try_block_;

  DISALLOW_COPY_AND_ASSIGN(TryBlocks);
};


void Parser::TryBlocks::AddNodeForFinallyInlining(AstNode* node) {
  inlined_finally_nodes_.Add(node);
}


// For parsing a compilation unit.
Parser::Parser(const Script& script, const Library& library)
    : script_(script),
      tokens_iterator_(TokenStream::Handle(script.tokens()), 0),
      token_kind_(Token::kILLEGAL),
      current_block_(NULL),
      is_top_level_(false),
      current_member_(NULL),
      allow_function_literals_(true),
      current_function_(Function::Handle()),
      innermost_function_(Function::Handle()),
      current_class_(Class::Handle()),
      library_(library),
      try_blocks_list_(NULL),
      expression_temp_(NULL) {
  ASSERT(tokens_iterator_.IsValid());
  ASSERT(!library.IsNull());
}


// For parsing a function.
Parser::Parser(const Script& script,
               const Function& function,
               intptr_t token_position)
    : script_(script),
      tokens_iterator_(TokenStream::Handle(script.tokens()), token_position),
      token_kind_(Token::kILLEGAL),
      current_block_(NULL),
      is_top_level_(false),
      current_member_(NULL),
      allow_function_literals_(true),
      current_function_(function),
      innermost_function_(Function::Handle(function.raw())),
      current_class_(Class::Handle(current_function_.Owner())),
      library_(Library::Handle(current_class_.library())),
      try_blocks_list_(NULL),
      expression_temp_(NULL) {
  ASSERT(tokens_iterator_.IsValid());
  ASSERT(!function.IsNull());
  if (FLAG_enable_type_checks) {
    EnsureExpressionTemp();
  }
}


bool Parser::SetAllowFunctionLiterals(bool value) {
  bool current_value = allow_function_literals_;
  allow_function_literals_ = value;
  return current_value;
}


const Function& Parser::current_function() const {
  return current_function_;
}


const Function& Parser::innermost_function() const {
  return innermost_function_;
}


const Class& Parser::current_class() const {
  return current_class_;
}


void Parser::set_current_class(const Class& value) {
  current_class_ = value.raw();
}


void Parser::SetPosition(intptr_t position) {
  if (position < TokenPos() && position != 0) {
    CompilerStats::num_tokens_rewind += (TokenPos() - position);
  }
  tokens_iterator_.SetCurrentPosition(position);
  token_kind_ = Token::kILLEGAL;
}


void Parser::ParseCompilationUnit(const Library& library,
                                  const Script& script) {
  ASSERT(Isolate::Current()->long_jump_base()->IsSafeToJump());
  TimerScope timer(FLAG_compiler_stats, &CompilerStats::parser_timer);
  Parser parser(script, library);
  parser.ParseTopLevel();
}


Token::Kind Parser::CurrentToken() {
  if (token_kind_ == Token::kILLEGAL) {
    token_kind_ = tokens_iterator_.CurrentTokenKind();
    if (token_kind_ == Token::kERROR) {
      ErrorMsg(TokenPos(), "%s", CurrentLiteral()->ToCString());
    }
  }
  CompilerStats::num_token_checks++;
  return token_kind_;
}


Token::Kind Parser::LookaheadToken(int num_tokens) {
  CompilerStats::num_tokens_lookahead++;
  CompilerStats::num_token_checks++;
  return tokens_iterator_.LookaheadTokenKind(num_tokens);
}


String* Parser::CurrentLiteral() const {
  String& result = String::ZoneHandle();
  result ^= tokens_iterator_.CurrentLiteral();
  return &result;
}


RawDouble* Parser::CurrentDoubleLiteral() const {
  LiteralToken& token = LiteralToken::Handle();
  token ^= tokens_iterator_.CurrentToken();
  ASSERT(token.kind() == Token::kDOUBLE);
  return reinterpret_cast<RawDouble*>(token.value());
}


RawInteger* Parser::CurrentIntegerLiteral() const {
  LiteralToken& token = LiteralToken::Handle();
  token ^= tokens_iterator_.CurrentToken();
  ASSERT(token.kind() == Token::kINTEGER);
  return reinterpret_cast<RawInteger*>(token.value());
}


// A QualIdent is an optionally qualified identifier.
struct QualIdent {
  QualIdent() {
    Clear();
  }
  void Clear() {
    lib_prefix = NULL;
    ident_pos = 0;
    ident = NULL;
  }
  LibraryPrefix* lib_prefix;
  intptr_t ident_pos;
  String* ident;
};


struct ParamDesc {
  ParamDesc()
      : type(NULL),
        name_pos(0),
        name(NULL),
        default_value(NULL),
        is_final(false),
        is_field_initializer(false) { }
  const AbstractType* type;
  intptr_t name_pos;
  const String* name;
  const Object* default_value;  // NULL if not an optional parameter.
  bool is_final;
  bool is_field_initializer;
};


struct ParamList {
  ParamList() {
    Clear();
  }

  void Clear() {
    num_fixed_parameters = 0;
    num_optional_parameters = 0;
    has_optional_positional_parameters = false;
    has_optional_named_parameters = false;
    has_field_initializer = false;
    implicitly_final = false;
    this->parameters = new ZoneGrowableArray<ParamDesc>();
  }

  void AddFinalParameter(intptr_t name_pos,
                         String* name,
                         const AbstractType* type) {
    this->num_fixed_parameters++;
    ParamDesc param;
    param.name_pos = name_pos;
    param.name = name;
    param.is_final = true;
    param.type = type;
    this->parameters->Add(param);
  }

  void AddReceiver(const Type* receiver_type) {
    ASSERT(this->parameters->is_empty());
    AddFinalParameter(receiver_type->token_pos(),
                      &String::ZoneHandle(Symbols::This()),
                      receiver_type);
  }

  void SetImplicitlyFinal() {
    implicitly_final = true;
  }

  int num_fixed_parameters;
  int num_optional_parameters;
  bool has_optional_positional_parameters;
  bool has_optional_named_parameters;
  bool has_field_initializer;
  bool implicitly_final;
  ZoneGrowableArray<ParamDesc>* parameters;
};


struct MemberDesc {
  MemberDesc() {
    Clear();
  }
  void Clear() {
    has_abstract = false;
    has_external = false;
    has_final = false;
    has_const = false;
    has_static = false;
    has_var = false;
    has_factory = false;
    has_operator = false;
    operator_token = Token::kILLEGAL;
    type = NULL;
    name_pos = 0;
    name = NULL;
    redirect_name = NULL;
    constructor_name = NULL;
    params.Clear();
    kind = RawFunction::kRegularFunction;
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
  bool IsGetter() const {
    return kind == RawFunction::kGetterFunction;
  }
  bool IsSetter() const {
    return kind == RawFunction::kSetterFunction;
  }
  bool has_abstract;
  bool has_external;
  bool has_final;
  bool has_const;
  bool has_static;
  bool has_var;
  bool has_factory;
  bool has_operator;
  Token::Kind operator_token;
  const AbstractType* type;
  intptr_t name_pos;
  String* name;
  // For constructors: NULL or name of redirected to constructor.
  String* redirect_name;
  // For constructors: NULL for unnamed constructor,
  // identifier after classname for named constructors.
  String* constructor_name;
  ParamList params;
  RawFunction::Kind kind;
};


class ClassDesc : public ValueObject {
 public:
  ClassDesc(const Class& cls,
            const String& cls_name,
            bool is_interface,
            intptr_t token_pos)
      : clazz_(cls),
        class_name_(cls_name),
        is_interface_(is_interface),
        token_pos_(token_pos),
        functions_(GrowableObjectArray::Handle(GrowableObjectArray::New())),
        fields_(GrowableObjectArray::Handle(GrowableObjectArray::New())) {
  }

  // Parameter 'name' is the unmangled name, i.e. without the setter
  // name mangling.
  bool FunctionNameExists(const String& name, RawFunction::Kind kind) const {
    // First check if a function or field of same name exists.
    if ((kind != RawFunction::kSetterFunction) && FunctionExists(name)) {
      return true;
    }
    // Now check whether there is a field and whether its implicit getter
    // or setter collides with the name.
    Field* field = LookupField(name);
    if (field != NULL) {
      if (kind == RawFunction::kSetterFunction) {
        // It's ok to have an implicit getter, it does not collide with
        // this setter function.
        if (!field->is_final()) {
          return true;
        }
      } else {
        // The implicit getter of the field collides with the name.
        return true;
      }
    }

    String& accessor_name = String::Handle();
    if (kind == RawFunction::kSetterFunction) {
      // Check if a setter function of same name exists.
      accessor_name = Field::SetterName(name);
      if (FunctionExists(accessor_name)) {
        return true;
      }
    } else {
      // Check if a getter function of same name exists.
      accessor_name = Field::GetterName(name);
      if (FunctionExists(accessor_name)) {
        return true;
      }
    }
    return false;
  }

  bool FieldNameExists(const String& name, bool check_setter) const {
    // First check if a function or field of same name exists.
    if (FunctionExists(name) || FieldExists(name)) {
      return true;
    }
    // Now check if a getter/setter function of same name exists.
    String& getter_name = String::Handle(Field::GetterName(name));
    if (FunctionExists(getter_name)) {
      return true;
    }
    if (check_setter) {
      String& setter_name = String::Handle(Field::SetterName(name));
      if (FunctionExists(setter_name)) {
        return true;
      }
    }
    return false;
  }

  void AddFunction(const Function& function) {
    ASSERT(!FunctionExists(String::Handle(function.name())));
    functions_.Add(function);
  }

  const GrowableObjectArray& functions() const {
    return functions_;
  }

  void AddField(const Field& field) {
    ASSERT(!FieldExists(String::Handle(field.name())));
    fields_.Add(field);
  }

  const GrowableObjectArray& fields() const {
    return fields_;
  }

  RawClass* clazz() const {
    return clazz_.raw();
  }

  const String& class_name() const {
    return class_name_;
  }

  bool is_interface() const {
    return is_interface_;
  }

  bool has_constructor() const {
    Function& func = Function::Handle();
    for (int i = 0; i < functions_.Length(); i++) {
      func ^= functions_.At(i);
      if (func.kind() == RawFunction::kConstructor) {
        return true;
      }
    }
    return false;
  }

  intptr_t token_pos() const {
    return token_pos_;
  }

  void AddMember(const MemberDesc& member) {
    members_.Add(member);
  }

  const GrowableArray<MemberDesc>& members() const {
    return members_;
  }

  MemberDesc* LookupMember(const String& name) const {
    for (int i = 0; i < members_.length(); i++) {
      if (name.Equals(*members_[i].name)) {
        return &members_[i];
      }
    }
    return NULL;
  }

 private:
  Field* LookupField(const String& name) const {
    String& test_name = String::Handle();
    Field& field = Field::Handle();
    for (int i = 0; i < fields_.Length(); i++) {
      field ^= fields_.At(i);
      test_name = field.name();
      if (name.Equals(test_name)) {
        return &field;
      }
    }
    return NULL;
  }

  bool FieldExists(const String& name) const {
    return LookupField(name) != NULL;
  }

  Function* LookupFunction(const String& name) const {
    String& test_name = String::Handle();
    Function& func = Function::Handle();
    for (int i = 0; i < functions_.Length(); i++) {
      func ^= functions_.At(i);
      test_name = func.name();
      if (name.Equals(test_name)) {
        return &func;
      }
    }
    return NULL;
  }

  bool FunctionExists(const String& name) const {
    return LookupFunction(name) != NULL;
  }

  const Class& clazz_;
  const String& class_name_;
  const bool is_interface_;
  intptr_t token_pos_;   // Token index of "class" keyword.
  GrowableObjectArray& functions_;
  GrowableObjectArray& fields_;
  GrowableArray<MemberDesc> members_;
};


struct TopLevel {
  TopLevel() :
      fields(GrowableObjectArray::Handle(GrowableObjectArray::New())),
      functions(GrowableObjectArray::Handle(GrowableObjectArray::New())) { }

  GrowableObjectArray& fields;
  GrowableObjectArray& functions;
};


static bool HasReturnNode(SequenceNode* seq) {
  if (seq->length() == 0) {
    return false;
  } else if ((seq->length()) == 1 &&
             (seq->NodeAt(seq->length() - 1)->IsSequenceNode())) {
    return HasReturnNode(seq->NodeAt(seq->length() - 1)->AsSequenceNode());
  } else {
    return seq->NodeAt(seq->length() - 1)->IsReturnNode();
  }
}


void Parser::ParseFunction(ParsedFunction* parsed_function) {
  TimerScope timer(FLAG_compiler_stats, &CompilerStats::parser_timer);
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate->long_jump_base()->IsSafeToJump());
  ASSERT(parsed_function != NULL);
  const Function& func = parsed_function->function();
  const Script& script = Script::Handle(isolate, func.script());
  Parser parser(script, func, func.token_pos());
  SequenceNode* node_sequence = NULL;
  Array& default_parameter_values = Array::ZoneHandle(isolate, Array::null());
  switch (func.kind()) {
    case RawFunction::kRegularFunction:
    case RawFunction::kClosureFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction:
    case RawFunction::kConstructor:
      // The call to a redirecting factory is redirected.
      ASSERT(!func.IsRedirectingFactory());
      node_sequence = parser.ParseFunc(func, default_parameter_values);
      break;
    case RawFunction::kImplicitGetter:
      ASSERT(!func.is_static());
      node_sequence = parser.ParseInstanceGetter(func);
      break;
    case RawFunction::kImplicitSetter:
      ASSERT(!func.is_static());
      node_sequence = parser.ParseInstanceSetter(func);
      break;
    case RawFunction::kConstImplicitGetter:
      node_sequence = parser.ParseStaticConstGetter(func);
      break;
    default:
      UNREACHABLE();
  }

  if (!HasReturnNode(node_sequence)) {
    // Add implicit return node.
    node_sequence->Add(new ReturnNode(parser.TokenPos()));
  }
  if (parser.expression_temp_ != NULL) {
    parsed_function->set_expression_temp_var(parser.expression_temp_);
  }
  if (parsed_function->has_expression_temp_var()) {
    node_sequence->scope()->AddVariable(parsed_function->expression_temp_var());
  }
  parsed_function->SetNodeSequence(node_sequence);

  // The instantiator may be required at run time for generic type checks or
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
      parsed_function->set_instantiator(
          new LoadLocalNode(node_sequence->token_pos(), instantiator));
    }
  }

  parsed_function->set_default_parameter_values(default_parameter_values);
}


// TODO(regis): Since a const variable is implicitly final,
// rename ParseStaticConstGetter to ParseStaticFinalGetter and
// rename kConstImplicitGetter to kImplicitFinalGetter.
SequenceNode* Parser::ParseStaticConstGetter(const Function& func) {
  TRACE_PARSER("ParseStaticConstGetter");
  ParamList params;
  ASSERT(func.num_fixed_parameters() == 0);  // static.
  ASSERT(!func.HasOptionalParameters());
  ASSERT(AbstractType::Handle(func.result_type()).IsResolved());

  // Build local scope for function and populate with the formal parameters.
  OpenFunctionBlock(func);
  AddFormalParamsToScope(&params, current_block_->scope);

  const String& field_name = *ExpectIdentifier("field name expected");
  const Class& field_class = Class::Handle(func.Owner());
  const Field& field =
      Field::ZoneHandle(field_class.LookupStaticField(field_name));

  // Static const fields must have an initializer.
  ExpectToken(Token::kASSIGN);

  // We don't want to use ParseConstExpr() here because we don't want
  // the constant folding code to create, compile and execute a code
  // fragment to evaluate the expression. Instead, we just make sure
  // the static const field initializer is a constant expression and
  // leave the evaluation to the getter function.
  const intptr_t expr_pos = TokenPos();
  AstNode* expr = ParseExpr(kAllowConst, kConsumeCascades);

  if (field.is_const()) {
    // This getter will only be called once at compile time.
    if (expr->EvalConstExpr() == NULL) {
      ErrorMsg(expr_pos, "initializer must be a compile-time constant");
    }
    ReturnNode* return_node = new ReturnNode(TokenPos(), expr);
    current_block_->statements->Add(return_node);
  } else {
    // This getter may be called each time the static field is accessed.
    // The following generated code lazily initializes the field:
    // if (field.value === transition_sentinel) {
    //   field.value = null;
    //   throw("circular dependency in field initialization");
    // }
    // if (field.value === sentinel) {
    //   field.value = transition_sentinel;
    //   field.value = expr;
    // }
    // return field.value;  // Type check is executed here in checked mode.

    // Generate code checking for circular dependency in field initialization.
    AstNode* compare_circular = new ComparisonNode(
        TokenPos(),
        Token::kEQ_STRICT,
        new LoadStaticFieldNode(TokenPos(), field),
        new LiteralNode(TokenPos(),
                        Instance::ZoneHandle(Object::transition_sentinel())));
    // Set field to null prior to throwing exception, so that subsequent
    // accesses to the field do not throw again, since initializers should only
    // be executed once.
    SequenceNode* report_circular = new SequenceNode(TokenPos(), NULL);
    report_circular->Add(
        new StoreStaticFieldNode(
            TokenPos(),
            field,
            new LiteralNode(TokenPos(), Instance::ZoneHandle())));
    // TODO(regis): Exception to throw is not specified by spec.
    const String& circular_error = String::ZoneHandle(
        Symbols::New("circular dependency in field initialization"));
    report_circular->Add(
        new ThrowNode(TokenPos(),
                      new LiteralNode(TokenPos(), circular_error),
                      NULL));
    AstNode* circular_check =
        new IfNode(TokenPos(), compare_circular, report_circular, NULL);
    current_block_->statements->Add(circular_check);

    // Generate code checking for uninitialized field.
    AstNode* compare_uninitialized = new ComparisonNode(
        TokenPos(),
        Token::kEQ_STRICT,
        new LoadStaticFieldNode(TokenPos(), field),
        new LiteralNode(TokenPos(),
                        Instance::ZoneHandle(Object::sentinel())));
    SequenceNode* initialize_field = new SequenceNode(TokenPos(), NULL);
    initialize_field->Add(
        new StoreStaticFieldNode(
            TokenPos(),
            field,
            new LiteralNode(
                TokenPos(),
                Instance::ZoneHandle(Object::transition_sentinel()))));
    // TODO(hausner): If evaluation of the field value throws an exception,
    // we leave the field value as 'transition_sentinel', which is wrong.
    // A second reference to the field later throws a circular dependency
    // exception. The field should instead be set to null after an exception.
    initialize_field->Add(new StoreStaticFieldNode(TokenPos(), field, expr));
    AstNode* uninitialized_check =
        new IfNode(TokenPos(), compare_uninitialized, initialize_field, NULL);
    current_block_->statements->Add(uninitialized_check);

    // Generate code returning the field value.
    ReturnNode* return_node =
        new ReturnNode(TokenPos(),
                       new LoadStaticFieldNode(TokenPos(), field));
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
  ASSERT(current_class().raw() == func.Owner());
  params.AddReceiver(ReceiverType(TokenPos()));
  ASSERT(func.num_fixed_parameters() == 1);  // receiver.
  ASSERT(!func.HasOptionalParameters());
  ASSERT(AbstractType::Handle(func.result_type()).IsResolved());

  // Build local scope for function and populate with the formal parameters.
  OpenFunctionBlock(func);
  AddFormalParamsToScope(&params, current_block_->scope);

  // Receiver is local 0.
  LocalVariable* receiver = current_block_->scope->VariableAt(0);
  LoadLocalNode* load_receiver = new LoadLocalNode(TokenPos(), receiver);
  // TokenPos() returns the function's token position which points to the
  // name of the field;
  ASSERT(IsIdentifier());
  const String& field_name = *CurrentLiteral();
  const Class& field_class = Class::Handle(func.Owner());
  const Field& field =
      Field::ZoneHandle(field_class.LookupInstanceField(field_name));

  LoadInstanceFieldNode* load_field =
      new LoadInstanceFieldNode(TokenPos(), load_receiver, field);

  ReturnNode* return_node = new ReturnNode(TokenPos(), load_field);
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
  // TokenPos() returns the function's token position which points to
  // the name of the field; we can use it to form the field_name.
  const String& field_name = *CurrentLiteral();
  const Class& field_class = Class::ZoneHandle(func.Owner());
  const Field& field =
      Field::ZoneHandle(field_class.LookupInstanceField(field_name));
  const AbstractType& field_type = AbstractType::ZoneHandle(field.type());

  ParamList params;
  ASSERT(current_class().raw() == func.Owner());
  params.AddReceiver(ReceiverType(TokenPos()));
  params.AddFinalParameter(TokenPos(),
                           &String::ZoneHandle(Symbols::Value()),
                           &field_type);
  ASSERT(func.num_fixed_parameters() == 2);  // receiver, value.
  ASSERT(!func.HasOptionalParameters());
  ASSERT(AbstractType::Handle(func.result_type()).IsVoidType());

  // Build local scope for function and populate with the formal parameters.
  OpenFunctionBlock(func);
  AddFormalParamsToScope(&params, current_block_->scope);

  LoadLocalNode* receiver =
      new LoadLocalNode(TokenPos(), current_block_->scope->VariableAt(0));
  LoadLocalNode* value =
      new LoadLocalNode(TokenPos(), current_block_->scope->VariableAt(1));

  StoreInstanceFieldNode* store_field =
      new StoreInstanceFieldNode(TokenPos(), receiver, field, value);

  current_block_->statements->Add(store_field);
  current_block_->statements->Add(new ReturnNode(TokenPos()));
  return CloseBlock();
}


void Parser::SkipBlock() {
  ASSERT(CurrentToken() == Token::kLBRACE);
  GrowableArray<Token::Kind> token_stack(8);
  const intptr_t block_start_pos = TokenPos();
  bool is_match = true;
  bool unexpected_token_found = false;
  Token::Kind token;
  intptr_t token_pos;
  do {
    token = CurrentToken();
    token_pos = TokenPos();
    switch (token) {
      case Token::kLBRACE:
      case Token::kLPAREN:
      case Token::kLBRACK:
        token_stack.Add(token);
        break;
      case Token::kRBRACE:
        is_match = token_stack.RemoveLast() == Token::kLBRACE;
        break;
      case Token::kRPAREN:
        is_match = token_stack.RemoveLast() == Token::kLPAREN;
        break;
      case Token::kRBRACK:
        is_match = token_stack.RemoveLast() == Token::kLBRACK;
        break;
      case Token::kEOS:
        unexpected_token_found = true;
        break;
      default:
        // nothing.
        break;
    }
    ConsumeToken();
  } while (!token_stack.is_empty() && is_match && !unexpected_token_found);
  if (!is_match) {
    ErrorMsg(token_pos, "unbalanced '%s'", Token::Str(token));
  } else if (unexpected_token_found) {
    ErrorMsg(block_start_pos, "unterminated block");
  }
}


void Parser::ParseFormalParameter(bool allow_explicit_default_value,
                                  ParamList* params) {
  TRACE_PARSER("ParseFormalParameter");
  ParamDesc parameter;
  bool var_seen = false;
  bool this_seen = false;

  SkipMetadata();
  if (CurrentToken() == Token::kFINAL) {
    ConsumeToken();
    parameter.is_final = true;
  } else if (CurrentToken() == Token::kVAR) {
    ConsumeToken();
    var_seen = true;
    // The parameter type is the 'dynamic' type.
    parameter.type = &Type::ZoneHandle(Type::DynamicType());
  }
  if (CurrentToken() == Token::kTHIS) {
    ConsumeToken();
    ExpectToken(Token::kPERIOD);
    this_seen = true;
    parameter.is_field_initializer = true;
  }
  if (params->implicitly_final) {
    parameter.is_final = true;
  }
  if ((parameter.type == NULL) && (CurrentToken() == Token::kVOID)) {
    ConsumeToken();
    // This must later be changed to a closure type if we recognize
    // a closure/function type parameter. We check this at the end
    // of ParseFormalParameter.
    parameter.type = &Type::ZoneHandle(Type::VoidType());
  }
  if (parameter.type == NULL) {
    // At this point, we must see an identifier for the type or the
    // function parameter.
    if (!IsIdentifier()) {
      ErrorMsg("parameter name or type expected");
    }
    // We have not seen a parameter type yet, so we check if the next
    // identifier could represent a type before parsing it.
    Token::Kind follower = LookaheadToken(1);
    // We have an identifier followed by a 'follower' token.
    // We either parse a type or assume that no type is specified.
    if ((follower == Token::kLT) ||  // Parameterized type.
        (follower == Token::kPERIOD) ||  // Qualified class name of type.
        Token::IsIdentifier(follower) ||  // Parameter name following a type.
        (follower == Token::kTHIS)) {  // Field parameter following a type.
      // The types of formal parameters are never ignored, even in unchecked
      // mode, because they are part of the function type of closurized
      // functions appearing in type tests with typedefs.
      parameter.type = &AbstractType::ZoneHandle(
          ParseType(is_top_level_ ? ClassFinalizer::kTryResolve :
                                    ClassFinalizer::kCanonicalize));
    } else {
      parameter.type = &Type::ZoneHandle(Type::DynamicType());
    }
  }
  if (!this_seen && (CurrentToken() == Token::kTHIS)) {
    ConsumeToken();
    ExpectToken(Token::kPERIOD);
    this_seen = true;
    parameter.is_field_initializer = true;
  }

  // At this point, we must see an identifier for the parameter name.
  parameter.name_pos = TokenPos();
  parameter.name = ExpectIdentifier("parameter name expected");
  if (parameter.is_field_initializer) {
    params->has_field_initializer = true;
  }

  // Check for duplicate formal parameters.
  const intptr_t num_existing_parameters =
      params->num_fixed_parameters + params->num_optional_parameters;
  for (intptr_t i = 0; i < num_existing_parameters; i++) {
    ParamDesc& existing_parameter = (*params->parameters)[i];
    if (existing_parameter.name->Equals(*parameter.name)) {
      ErrorMsg(parameter.name_pos, "duplicate formal parameter '%s'",
               parameter.name->ToCString());
    }
  }

  if (CurrentToken() == Token::kLPAREN) {
    // This parameter is probably a closure. If we saw the keyword 'var'
    // or 'final', a closure is not legal here and we ignore the
    // opening parens.
    if (!var_seen && !parameter.is_final) {
      // The parsed parameter type is actually the function result type.
      const AbstractType& result_type =
          AbstractType::Handle(parameter.type->raw());

      // Finish parsing the function type parameter.
      ParamList func_params;

      // Add implicit closure object parameter.
      func_params.AddFinalParameter(
          TokenPos(),
          &String::ZoneHandle(Symbols::ClosureParameter()),
          &Type::ZoneHandle(Type::DynamicType()));

      const bool no_explicit_default_values = false;
      ParseFormalParameterList(no_explicit_default_values, &func_params);

      // The field 'is_static' has no meaning for signature functions.
      const Function& signature_function = Function::Handle(
          Function::New(*parameter.name,
                        RawFunction::kSignatureFunction,
                        /* is_static = */ false,
                        /* is_const = */ false,
                        /* is_abstract = */ false,
                        /* is_external = */ false,
                        current_class(),
                        parameter.name_pos));
      signature_function.set_result_type(result_type);
      AddFormalParamsToFunction(&func_params, signature_function);
      const String& signature = String::Handle(signature_function.Signature());
      // Lookup the signature class, i.e. the class whose name is the signature.
      // We only lookup in the current library, but not in its imports, and only
      // create a new canonical signature class if it does not exist yet.
      Class& signature_class = Class::ZoneHandle(
          library_.LookupLocalClass(signature));
      if (signature_class.IsNull()) {
        signature_class = Class::NewSignatureClass(signature,
                                                   signature_function,
                                                   script_);
        // Record the function signature class in the current library.
        library_.AddClass(signature_class);
      } else {
        signature_function.set_signature_class(signature_class);
      }
      ASSERT(signature_function.signature_class() == signature_class.raw());
      Type& signature_type = Type::ZoneHandle(signature_class.SignatureType());
      if (!is_top_level_ && !signature_type.IsFinalized()) {
        signature_type ^= ClassFinalizer::FinalizeType(
            signature_class, signature_type, ClassFinalizer::kCanonicalize);
      }
      // The type of the parameter is now the signature type.
      parameter.type = &signature_type;
    }
  }

  if ((CurrentToken() == Token::kASSIGN) || (CurrentToken() == Token::kCOLON)) {
    if ((!params->has_optional_positional_parameters &&
         !params->has_optional_named_parameters) ||
        !allow_explicit_default_value) {
      ErrorMsg("parameter must not specify a default value");
    }
    if (params->has_optional_positional_parameters) {
      ExpectToken(Token::kASSIGN);
    } else {
      ExpectToken(Token::kCOLON);
    }
    params->num_optional_parameters++;
    if (is_top_level_) {
      // Skip default value parsing.
      SkipExpr();
    } else {
      const Object& const_value = ParseConstExpr()->literal();
      parameter.default_value = &const_value;
    }
  } else {
    if (params->has_optional_positional_parameters ||
        params->has_optional_named_parameters) {
      // Implicit default value is null.
      params->num_optional_parameters++;
      parameter.default_value = &Object::ZoneHandle();
    } else {
      params->num_fixed_parameters++;
      ASSERT(params->num_optional_parameters == 0);
    }
  }
  if (parameter.type->IsVoidType()) {
    ErrorMsg("parameter '%s' may not be 'void'", parameter.name->ToCString());
  }
  params->parameters->Add(parameter);
}


// Parses a sequence of normal or optional formal parameters.
void Parser::ParseFormalParameters(bool allow_explicit_default_values,
                                   ParamList* params) {
  TRACE_PARSER("ParseFormalParameters");
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
    ParseFormalParameter(allow_explicit_default_values, params);
  } while (CurrentToken() == Token::kCOMMA);
}


void Parser::ParseFormalParameterList(bool allow_explicit_default_values,
                                      ParamList* params) {
  TRACE_PARSER("ParseFormalParameterList");
  ASSERT(CurrentToken() == Token::kLPAREN);

  if (LookaheadToken(1) != Token::kRPAREN) {
    // Parse fixed parameters.
    ParseFormalParameters(allow_explicit_default_values, params);
    if (params->has_optional_positional_parameters ||
        params->has_optional_named_parameters) {
      // Parse optional parameters.
      ParseFormalParameters(allow_explicit_default_values, params);
      if (params->has_optional_positional_parameters) {
        if (CurrentToken() != Token::kRBRACK) {
          ErrorMsg("',' or ']' expected");
        }
      } else {
        if (CurrentToken() != Token::kRBRACE) {
          ErrorMsg("',' or '}' expected");
        }
      }
      ConsumeToken();  // ']' or '}'.
    }
    if ((CurrentToken() != Token::kRPAREN) &&
        !params->has_optional_positional_parameters &&
        !params->has_optional_named_parameters) {
      ErrorMsg("',' or ')' expected");
    }
  } else {
    ConsumeToken();
  }
  ExpectToken(Token::kRPAREN);
}


String& Parser::ParseNativeDeclaration() {
  TRACE_PARSER("ParseNativeDeclaration");
  ASSERT(IsLiteral("native"));
  ConsumeToken();
  if (CurrentToken() != Token::kSTRING) {
    ErrorMsg("string literal expected");
  }
  String& native_name = *CurrentLiteral();
  ConsumeToken();
  ExpectSemicolon();
  return native_name;
}


void Parser::CheckFunctionIsCallable(intptr_t token_pos,
                                     const Function& function) {
  if (Class::Handle(function.Owner()).is_interface()) {
    ErrorMsg(token_pos, "cannot call function of interface '%s'",
        function.ToFullyQualifiedCString());
  }
}


// Resolve and return the dynamic function of the given name in the superclass.
// If it is not found, and resolve_getter is true, try to resolve a getter of
// the same name. If it is still not found, return noSuchMethod and
// set is_no_such_method to true..
RawFunction* Parser::GetSuperFunction(intptr_t token_pos,
                                      const String& name,
                                      bool resolve_getter,
                                      bool* is_no_such_method) {
  const Class& super_class = Class::Handle(current_class().SuperClass());
  if (super_class.IsNull()) {
    ErrorMsg(token_pos, "class '%s' does not have a superclass",
             String::Handle(current_class().Name()).ToCString());
  }
  Function& super_func =
      Function::Handle(Resolver::ResolveDynamicAnyArgs(super_class, name));
  if (super_func.IsNull() && resolve_getter) {
    const String& getter_name = String::ZoneHandle(Field::GetterName(name));
    super_func = Resolver::ResolveDynamicAnyArgs(super_class, getter_name);
    ASSERT(super_func.IsNull() ||
           (super_func.kind() != RawFunction::kConstImplicitGetter));
  }
  if (super_func.IsNull()) {
    const String& no_such_method_name = String::Handle(Symbols::NoSuchMethod());
    super_func =
        Resolver::ResolveDynamicAnyArgs(super_class, no_such_method_name);
    ASSERT(!super_func.IsNull());
    *is_no_such_method = true;
  } else {
    *is_no_such_method = false;
  }
  CheckFunctionIsCallable(token_pos, super_func);
  return super_func.raw();
}


// Lookup class in the core lib which also contains various VM
// helper methods and classes. Allow look up of private classes.
static RawClass* LookupCoreClass(const String& class_name) {
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  String& name = String::Handle(class_name.raw());
  if (class_name.CharAt(0) == Scanner::kPrivateIdentifierStart) {
    // Private identifiers are mangled on a per script basis.
    name = String::Concat(name, String::Handle(core_lib.private_key()));
    name = Symbols::New(name);
  }
  return core_lib.LookupClass(name);
}


StaticCallNode* Parser::BuildInvocationMirrorAllocation(
    intptr_t call_pos,
    const String& function_name,
    const ArgumentListNode& function_args) {
  const intptr_t args_pos = function_args.token_pos();
  // Build arguments to the call to the static
  // InvocationMirror._allocateInvocationMirror method.
  ArgumentListNode* arguments = new ArgumentListNode(args_pos);
  // The first argument is the original function name.
  arguments->Add(new LiteralNode(args_pos, function_name));
  // The second argument is an array containing the original function arguments.
  ArrayNode* args_array = new ArrayNode(
      args_pos, Type::ZoneHandle(Type::ArrayType()));
  for (intptr_t i = 1; i < function_args.length(); i++) {
    args_array->AddElement(function_args.NodeAt(i));
  }
  arguments->Add(args_array);
  // Lookup the static InvocationMirror._allocateInvocationMirror method.
  const Class& mirror_class = Class::Handle(
      LookupCoreClass(String::Handle(Symbols::InvocationMirror())));
  ASSERT(!mirror_class.IsNull());
  const String& allocation_function_name =
      String::Handle(Symbols::AllocateInvocationMirror());
  const Function& allocation_function = Function::ZoneHandle(
      mirror_class.LookupStaticFunction(allocation_function_name));
  ASSERT(!allocation_function.IsNull());
  return new StaticCallNode(call_pos, allocation_function, arguments);
}


ArgumentListNode* Parser::BuildNoSuchMethodArguments(
    intptr_t call_pos,
    const String& function_name,
    const ArgumentListNode& function_args) {
  ASSERT(function_args.length() >= 1);  // The receiver is the first argument.
  const intptr_t args_pos = function_args.token_pos();
  ArgumentListNode* arguments = new ArgumentListNode(args_pos);
  arguments->Add(function_args.NodeAt(0));
  // The second argument is the invocation mirror.
  arguments->Add(BuildInvocationMirrorAllocation(
      call_pos, function_name, function_args));
  return arguments;
}


AstNode* Parser::ParseSuperCall(const String& function_name) {
  TRACE_PARSER("ParseSuperCall");
  ASSERT(CurrentToken() == Token::kLPAREN);
  const intptr_t supercall_pos = TokenPos();

  const bool kResolveGetter = true;
  bool is_no_such_method = false;
  const Function& super_function = Function::ZoneHandle(
      GetSuperFunction(supercall_pos,
                       function_name,
                       kResolveGetter,
                       &is_no_such_method));
  ArgumentListNode* arguments = new ArgumentListNode(supercall_pos);
  if (super_function.IsGetterFunction() ||
      super_function.IsImplicitGetterFunction()) {
    // 'this' is not passed as parameter to the closure.
    ParseActualParameters(arguments, kAllowConst);
    const Class& super_class = Class::ZoneHandle(current_class().SuperClass());
    AstNode* closure = new StaticGetterNode(supercall_pos,
                                            LoadReceiver(supercall_pos),
                                            /* is_super_getter */ true,
                                            super_class,
                                            function_name);
    EnsureExpressionTemp();
    return new ClosureCallNode(supercall_pos, closure, arguments);
  }
  // 'this' parameter is the first argument to super call.
  AstNode* receiver = LoadReceiver(supercall_pos);
  arguments->Add(receiver);
  ParseActualParameters(arguments, kAllowConst);
  if (is_no_such_method) {
    arguments = BuildNoSuchMethodArguments(
        supercall_pos, function_name, *arguments);
  }
  return new StaticCallNode(supercall_pos, super_function, arguments);
}


// Simple test if a node is side effect free.
static bool IsSimpleLocalOrLiteralNode(AstNode* node) {
  if (node->IsLiteralNode()) {
    return true;
  }
  if (node->IsLoadLocalNode() && !node->AsLoadLocalNode()->HasPseudo()) {
    return true;
  }
  return false;
}


AstNode* Parser::BuildUnarySuperOperator(Token::Kind op, PrimaryNode* super) {
  ASSERT(super->IsSuper());
  AstNode* super_op = NULL;
  const intptr_t super_pos = super->token_pos();
  if ((op == Token::kNEGATE) ||
      (op == Token::kBIT_NOT)) {
    // Resolve the operator function in the superclass.
    const String& operator_function_name =
        String::ZoneHandle(Symbols::New(Token::Str(op)));
    const bool kResolveGetter = false;
    bool is_no_such_method = false;
    const Function& super_operator = Function::ZoneHandle(
        GetSuperFunction(super_pos,
                         operator_function_name,
                         kResolveGetter,
                         &is_no_such_method));
    ArgumentListNode* op_arguments = new ArgumentListNode(super_pos);
    AstNode* receiver = LoadReceiver(super_pos);
    op_arguments->Add(receiver);
    CheckFunctionIsCallable(super_pos, super_operator);
    if (is_no_such_method) {
      op_arguments = BuildNoSuchMethodArguments(
          super_pos, operator_function_name, *op_arguments);
    }
    super_op = new StaticCallNode(super_pos, super_operator, op_arguments);
  } else {
    ErrorMsg(super_pos, "illegal super operator call");
  }
  return super_op;
}


AstNode* Parser::ParseSuperOperator() {
  TRACE_PARSER("ParseSuperOperator");
  AstNode* super_op = NULL;
  const intptr_t operator_pos = TokenPos();

  if (CurrentToken() == Token::kLBRACK) {
    ConsumeToken();
    AstNode* index_expr = ParseExpr(kAllowConst, kConsumeCascades);
    ExpectToken(Token::kRBRACK);
    AstNode* receiver = LoadReceiver(operator_pos);
    const Class& super_class = Class::ZoneHandle(current_class().SuperClass());
    ASSERT(!super_class.IsNull());
    super_op =
        new LoadIndexedNode(operator_pos, receiver, index_expr, super_class);
  } else if (Token::CanBeOverloaded(CurrentToken()) ||
             (CurrentToken() == Token::kNE)) {
    Token::Kind op = CurrentToken();
    ConsumeToken();

    bool negate_result = false;
    if (op == Token::kNE) {
      op = Token::kEQ;
      negate_result = true;
    }

    // Resolve the operator function in the superclass.
    const String& operator_function_name =
        String::Handle(Symbols::New(Token::Str(op)));
    const bool kResolveGetter = false;
    bool is_no_such_method = false;
    const Function& super_operator = Function::ZoneHandle(
        GetSuperFunction(operator_pos,
                         operator_function_name,
                         kResolveGetter,
                         &is_no_such_method));

    ASSERT(Token::Precedence(op) >= Token::Precedence(Token::kBIT_OR));
    AstNode* other_operand = ParseBinaryExpr(Token::Precedence(op) + 1);

    ArgumentListNode* op_arguments = new ArgumentListNode(operator_pos);
    AstNode* receiver = LoadReceiver(operator_pos);
    op_arguments->Add(receiver);
    op_arguments->Add(other_operand);

    CheckFunctionIsCallable(operator_pos, super_operator);
    if (is_no_such_method) {
      op_arguments = BuildNoSuchMethodArguments(
          operator_pos, operator_function_name, *op_arguments);
    }
    super_op = new StaticCallNode(operator_pos, super_operator, op_arguments);
    if (negate_result) {
      super_op = new UnaryOpNode(operator_pos, Token::kNOT, super_op);
    }
  }
  return super_op;
}


AstNode* Parser::CreateImplicitClosureNode(const Function& func,
                                           intptr_t token_pos,
                                           AstNode* receiver) {
  Function& implicit_closure_function =
      Function::ZoneHandle(func.ImplicitClosureFunction());
  if (receiver != NULL) {
    // If we create an implicit instance closure from inside a closure of a
    // parameterized class, make sure that the receiver is captured as
    // instantiator.
    if (current_block_->scope->function_level() > 0) {
      const Class& signature_class = Class::Handle(func.signature_class());
      if (signature_class.NumTypeParameters() > 0) {
        CaptureInstantiator();
      }
    }
  }
  return new ClosureNode(token_pos, implicit_closure_function, receiver, NULL);
}


AstNode* Parser::ParseSuperFieldAccess(const String& field_name) {
  TRACE_PARSER("ParseSuperFieldAccess");
  const intptr_t field_pos = TokenPos();
  const Class& super_class = Class::ZoneHandle(current_class().SuperClass());
  if (super_class.IsNull()) {
    ErrorMsg("class '%s' does not have a superclass",
             String::Handle(current_class().Name()).ToCString());
  }
  AstNode* implicit_argument = LoadReceiver(field_pos);

  const String& getter_name =
      String::ZoneHandle(Field::GetterName(field_name));
  const Function& super_getter = Function::ZoneHandle(
      Resolver::ResolveDynamicAnyArgs(super_class, getter_name));
  if (super_getter.IsNull()) {
    const String& setter_name =
        String::ZoneHandle(Field::SetterName(field_name));
    const Function& super_setter = Function::ZoneHandle(
        Resolver::ResolveDynamicAnyArgs(super_class, setter_name));
    if (!super_setter.IsNull()) {
      return new StaticGetterNode(
          field_pos, implicit_argument, true, super_class, field_name);
    }
  }
  if (super_getter.IsNull()) {
    // Check if this is an access to an implicit closure using 'super'.
    // If a function exists of the specified field_name then try
    // accessing it as a getter, at runtime we will handle this by
    // creating an implicit closure of the function and returning it.
    const Function& super_function = Function::ZoneHandle(
        Resolver::ResolveDynamicAnyArgs(super_class, field_name));
    if (super_function.IsNull()) {
      ErrorMsg(field_pos, "field or getter '%s' not found in superclass",
               field_name.ToCString());
    }
    return CreateImplicitClosureNode(super_function,
                                     field_pos,
                                     implicit_argument);
  }

  return new StaticGetterNode(
      field_pos, implicit_argument, true, super_class, field_name);
}


void Parser::GenerateSuperConstructorCall(const Class& cls,
                                          LocalVariable* receiver) {
  const intptr_t supercall_pos = TokenPos();
  const Class& super_class = Class::Handle(cls.SuperClass());
  // Omit the implicit super() if there is no super class (i.e.
  // we're not compiling class Object), or if the super class is an
  // artificially generated "wrapper class" that has no constructor.
  if (super_class.IsNull() ||
      (super_class.num_native_fields() > 0 &&
       Class::Handle(super_class.SuperClass()).IsObjectClass())) {
    return;
  }
  String& ctor_name = String::Handle(super_class.Name());
  String& ctor_suffix = String::Handle(Symbols::Dot());
  ctor_name = String::Concat(ctor_name, ctor_suffix);
  ArgumentListNode* arguments = new ArgumentListNode(supercall_pos);
  // Implicit 'this' parameter is the first argument.
  AstNode* implicit_argument = new LoadLocalNode(supercall_pos, receiver);
  arguments->Add(implicit_argument);
  // Implicit construction phase parameter is second argument.
  AstNode* phase_parameter =
      new LiteralNode(supercall_pos,
                      Smi::ZoneHandle(Smi::New(Function::kCtorPhaseAll)));
  arguments->Add(phase_parameter);
  const Function& super_ctor = Function::ZoneHandle(
      super_class.LookupConstructor(ctor_name));
  if (super_ctor.IsNull()) {
      ErrorMsg(supercall_pos,
               "unresolved implicit call to super constructor '%s()'",
               String::Handle(super_class.Name()).ToCString());
  }
  String& error_message = String::Handle();
  if (!super_ctor.AreValidArguments(arguments->length(),
                                    arguments->names(),
                                    &error_message)) {
    ErrorMsg(supercall_pos,
             "invalid arguments passed to super constructor '%s()': %s",
             String::Handle(super_class.Name()).ToCString(),
             error_message.ToCString());
  }
  CheckFunctionIsCallable(supercall_pos, super_ctor);
  current_block_->statements->Add(
      new StaticCallNode(supercall_pos, super_ctor, arguments));
}


AstNode* Parser::ParseSuperInitializer(const Class& cls,
                                       LocalVariable* receiver) {
  TRACE_PARSER("ParseSuperInitializer");
  ASSERT(CurrentToken() == Token::kSUPER);
  const intptr_t supercall_pos = TokenPos();
  ConsumeToken();
  const Class& super_class = Class::Handle(cls.SuperClass());
  ASSERT(!super_class.IsNull());
  String& ctor_name = String::Handle(super_class.Name());
  String& ctor_suffix = String::Handle(Symbols::Dot());
  if (CurrentToken() == Token::kPERIOD) {
    ConsumeToken();
    ctor_suffix = String::Concat(
        ctor_suffix, *ExpectIdentifier("constructor name expected"));
  }
  ctor_name = String::Concat(ctor_name, ctor_suffix);
  if (CurrentToken() != Token::kLPAREN) {
    ErrorMsg("parameter list expected");
  }

  ArgumentListNode* arguments = new ArgumentListNode(supercall_pos);
  // 'this' parameter is the first argument to super class constructor.
  AstNode* implicit_argument = new LoadLocalNode(supercall_pos, receiver);
  arguments->Add(implicit_argument);
  // Second implicit parameter is the construction phase. We optimistically
  // assume that we can execute both the super initializer and the super
  // constructor body. We may later change this to only execute the
  // super initializer.
  AstNode* phase_parameter =
      new LiteralNode(supercall_pos,
                      Smi::ZoneHandle(Smi::New(Function::kCtorPhaseAll)));
  arguments->Add(phase_parameter);
  // 'this' parameter must not be accessible to the other super call arguments.
  receiver->set_invisible(true);
  ParseActualParameters(arguments, kAllowConst);
  receiver->set_invisible(false);

  // Resolve the constructor.
  const Function& super_ctor = Function::ZoneHandle(
      super_class.LookupConstructor(ctor_name));
  if (super_ctor.IsNull()) {
    ErrorMsg(supercall_pos,
             "super class constructor '%s' not found",
             ctor_name.ToCString());
  }
  String& error_message = String::Handle();
  if (!super_ctor.AreValidArguments(arguments->length(),
                                    arguments->names(),
                                    &error_message)) {
    ErrorMsg(supercall_pos,
             "invalid arguments passed to super class constructor '%s': %s",
             ctor_name.ToCString(),
             error_message.ToCString());
  }
  CheckFunctionIsCallable(supercall_pos, super_ctor);
  return new StaticCallNode(supercall_pos, super_ctor, arguments);
}


AstNode* Parser::ParseInitializer(const Class& cls,
                                  LocalVariable* receiver,
                                  GrowableArray<Field*>* initialized_fields) {
  TRACE_PARSER("ParseInitializer");
  const intptr_t field_pos = TokenPos();
  if (CurrentToken() == Token::kTHIS) {
    ConsumeToken();
    ExpectToken(Token::kPERIOD);
  }
  const String& field_name = *ExpectIdentifier("field name expected");
  ExpectToken(Token::kASSIGN);

  const bool saved_mode = SetAllowFunctionLiterals(false);
  // "this" must not be accessible in initializer expressions.
  receiver->set_invisible(true);
  AstNode* init_expr = ParseConditionalExpr();
  receiver->set_invisible(false);
  SetAllowFunctionLiterals(saved_mode);
  Field& field = Field::ZoneHandle(cls.LookupInstanceField(field_name));
  if (field.IsNull()) {
    ErrorMsg(field_pos, "unresolved reference to instance field '%s'",
             field_name.ToCString());
  }
  CheckDuplicateFieldInit(field_pos, initialized_fields, &field);
  AstNode* instance = new LoadLocalNode(field_pos, receiver);
  return new StoreInstanceFieldNode(field_pos, instance, field, init_expr);
}


void Parser::CheckConstFieldsInitialized(const Class& cls) {
  const Array& fields = Array::Handle(cls.fields());
  Field& field = Field::Handle();
  SequenceNode* initializers = current_block_->statements;
  for (int field_num = 0; field_num < fields.Length(); field_num++) {
    field ^= fields.At(field_num);
    if (field.is_static() || !field.is_final()) {
      continue;
    }
    bool found = false;
    for (int i = 0; i < initializers->length(); i++) {
      found = false;
      if (initializers->NodeAt(i)->IsStoreInstanceFieldNode()) {
        StoreInstanceFieldNode* initializer =
            initializers->NodeAt(i)->AsStoreInstanceFieldNode();
        if (initializer->field().raw() == field.raw()) {
          found = true;
          break;
        }
      }
    }
    if (!found) {
      ErrorMsg("final field '%s' not initialized",
               String::Handle(field.name()).ToCString());
    }
  }
}


void Parser::ParseInitializedInstanceFields(const Class& cls,
                 LocalVariable* receiver,
                 GrowableArray<Field*>* initialized_fields) {
  TRACE_PARSER("ParseInitializedInstanceFields");
  const Array& fields = Array::Handle(cls.fields());
  Field& f = Field::Handle();
  const intptr_t saved_pos = TokenPos();
  for (int i = 0; i < fields.Length(); i++) {
    f ^= fields.At(i);
    if (!f.is_static() && f.has_initializer()) {
      Field& field = Field::ZoneHandle();
      field ^= fields.At(i);
      if (field.is_final()) {
        // Final fields with initializer expression may not be initialized
        // again by constructors. Remember that this field is already
        // initialized.
        initialized_fields->Add(&field);
      }
      intptr_t field_pos = field.token_pos();
      SetPosition(field_pos);
      ASSERT(IsIdentifier());
      ConsumeToken();
      ExpectToken(Token::kASSIGN);

      AstNode* init_expr = NULL;
      if (field.is_const()) {
        init_expr = ParseConstExpr();
      } else {
        init_expr = ParseExpr(kAllowConst, kConsumeCascades);
        if (init_expr->EvalConstExpr() != NULL) {
          init_expr = new LiteralNode(field_pos, EvaluateConstExpr(init_expr));
        }
      }
      ASSERT(init_expr != NULL);
      AstNode* instance = new LoadLocalNode(field.token_pos(), receiver);
      AstNode* field_init =
          new StoreInstanceFieldNode(field.token_pos(),
                                     instance,
                                     field,
                                     init_expr);
      current_block_->statements->Add(field_init);
    }
  }
  SetPosition(saved_pos);
}


void Parser::CheckDuplicateFieldInit(intptr_t init_pos,
                                    GrowableArray<Field*>* initialized_fields,
                                    Field* field) {
  ASSERT(!field->is_static());
  for (int i = 0; i < initialized_fields->length(); i++) {
    Field* initialized_field = (*initialized_fields)[i];
    if (initialized_field->raw() == field->raw()) {
      ErrorMsg(init_pos,
               "duplicate initialization for field %s",
               String::Handle(field->name()).ToCString());
    }
  }
  initialized_fields->Add(field);
}


void Parser::ParseInitializers(const Class& cls,
                               LocalVariable* receiver,
                               GrowableArray<Field*>* initialized_fields) {
  TRACE_PARSER("ParseInitializers");
  bool super_init_seen = false;
  if (CurrentToken() == Token::kCOLON) {
    if ((LookaheadToken(1) == Token::kTHIS) &&
        ((LookaheadToken(2) == Token::kLPAREN) ||
        ((LookaheadToken(2) == Token::kPERIOD) &&
            (LookaheadToken(4) == Token::kLPAREN)))) {
      // Either we see this(...) or this.xxx(...) which is a
      // redirected constructor. We don't need to check whether
      // const fields are initialized. The other constructor will
      // guarantee that.
      ConsumeToken();  // Colon.
      ParseConstructorRedirection(cls, receiver);
      return;
    }
    do {
      ConsumeToken();  // Colon or comma.
      AstNode* init_statement;
      if (CurrentToken() == Token::kSUPER) {
        if (super_init_seen) {
          ErrorMsg("duplicate call to super constructor");
        }
        init_statement = ParseSuperInitializer(cls, receiver);
        super_init_seen = true;
      } else {
        init_statement = ParseInitializer(cls, receiver, initialized_fields);
      }
      current_block_->statements->Add(init_statement);
    } while (CurrentToken() == Token::kCOMMA);
  }
  if (!super_init_seen) {
    // Generate implicit super() if we haven't seen an explicit super call
    // or constructor redirection.
    GenerateSuperConstructorCall(cls, receiver);
  }
  CheckConstFieldsInitialized(cls);
}


void Parser::ParseConstructorRedirection(const Class& cls,
                                         LocalVariable* receiver) {
  TRACE_PARSER("ParseConstructorRedirection");
  ASSERT(CurrentToken() == Token::kTHIS);
  const intptr_t call_pos = TokenPos();
  ConsumeToken();
  String& ctor_name = String::Handle(cls.Name());
  String& ctor_suffix = String::Handle(Symbols::Dot());

  if (CurrentToken() == Token::kPERIOD) {
    ConsumeToken();
    ctor_suffix = String::Concat(
        ctor_suffix, *ExpectIdentifier("constructor name expected"));
  }
  ctor_name = String::Concat(ctor_name, ctor_suffix);
  if (CurrentToken() != Token::kLPAREN) {
    ErrorMsg("parameter list expected");
  }

  ArgumentListNode* arguments = new ArgumentListNode(call_pos);
  // 'this' parameter is the first argument to constructor.
  AstNode* implicit_argument = new LoadLocalNode(call_pos, receiver);
  arguments->Add(implicit_argument);
  // Construction phase parameter is second argument.
  LocalVariable* phase_param = LookupPhaseParameter();
  ASSERT(phase_param != NULL);
  AstNode* phase_argument = new LoadLocalNode(call_pos, phase_param);
  arguments->Add(phase_argument);
  receiver->set_invisible(true);
  ParseActualParameters(arguments, kAllowConst);
  receiver->set_invisible(false);
  // Resolve the constructor.
  const Function& redirect_ctor = Function::ZoneHandle(
      cls.LookupConstructor(ctor_name));
  if (redirect_ctor.IsNull()) {
    ErrorMsg(call_pos, "constructor '%s' not found", ctor_name.ToCString());
  }
  String& error_message = String::Handle();
  if (!redirect_ctor.AreValidArguments(arguments->length(),
                                       arguments->names(),
                                       &error_message)) {
    ErrorMsg(call_pos,
             "invalid arguments passed to constructor '%s': %s",
             ctor_name.ToCString(),
             error_message.ToCString());
  }
  CheckFunctionIsCallable(call_pos, redirect_ctor);
  current_block_->statements->Add(
      new StaticCallNode(call_pos, redirect_ctor, arguments));
}


SequenceNode* Parser::MakeImplicitConstructor(const Function& func) {
  ASSERT(func.IsConstructor());
  const intptr_t ctor_pos = TokenPos();
  OpenFunctionBlock(func);
  const Class& cls = Class::Handle(func.Owner());
  LocalVariable* receiver = new LocalVariable(
      ctor_pos,
      String::ZoneHandle(Symbols::This()),
      Type::ZoneHandle(Type::DynamicType()));
  current_block_->scope->AddVariable(receiver);

  LocalVariable* phase_parameter = new LocalVariable(
       ctor_pos,
       String::ZoneHandle(Symbols::PhaseParameter()),
       Type::ZoneHandle(Type::SmiType()));
  current_block_->scope->AddVariable(phase_parameter);

  // Parse expressions of instance fields that have an explicit
  // initializer expression.
  // The receiver must not be visible to field initializer expressions.
  receiver->set_invisible(true);
  GrowableArray<Field*> initialized_fields;
  ParseInitializedInstanceFields(cls, receiver, &initialized_fields);
  receiver->set_invisible(false);

  GenerateSuperConstructorCall(cls, receiver);
  CheckConstFieldsInitialized(cls);

  // Empty constructor body.
  SequenceNode* statements = CloseBlock();
  return statements;
}


// Helper function to make the first num_variables variables in the
// given scope visible/invisible.
static void SetInvisible(LocalScope* scope, int num_variables, bool invisible) {
  ASSERT(num_variables <= scope->num_variables());
  for (int i = 0; i < num_variables; i++) {
    scope->VariableAt(i)->set_invisible(invisible);
  }
}


// Parser is at the opening parenthesis of the formal parameter declaration
// of function. Parse the formal parameters, initializers and code.
SequenceNode* Parser::ParseConstructor(const Function& func,
                                       Array& default_parameter_values) {
  TRACE_PARSER("ParseConstructor");
  ASSERT(func.IsConstructor());
  ASSERT(!func.IsFactory());
  ASSERT(!func.is_static());
  ASSERT(!func.IsLocalFunction());
  const Class& cls = Class::Handle(func.Owner());
  ASSERT(!cls.IsNull());

  if (CurrentToken() == Token::kCLASS) {
    // Special case: implicit constructor.
    // The parser adds an implicit default constructor when a class
    // does not have any explicit constructor or factory (see
    // Parser::AddImplicitConstructor). The token position of this implicit
    // constructor points to the 'class' keyword, which is followed
    // by the name of the class (which is also the constructor name).
    // There is no source text to parse. We just build the
    // sequence node by hand.
    return MakeImplicitConstructor(func);
  }

  OpenFunctionBlock(func);
  ParamList params;
  const bool allow_explicit_default_values = true;
  ASSERT(CurrentToken() == Token::kLPAREN);

  // Add implicit receiver parameter which is passed the allocated
  // but uninitialized instance to construct.
  ASSERT(current_class().raw() == func.Owner());
  params.AddReceiver(ReceiverType(TokenPos()));

  // Add implicit parameter for construction phase.
  params.AddFinalParameter(
      TokenPos(),
      &String::ZoneHandle(Symbols::PhaseParameter()),
      &Type::ZoneHandle(Type::SmiType()));

  if (func.is_const()) {
    params.SetImplicitlyFinal();
  }
  ParseFormalParameterList(allow_explicit_default_values, &params);

  SetupDefaultsForOptionalParams(&params, default_parameter_values);
  ASSERT(AbstractType::Handle(func.result_type()).IsResolved());
  ASSERT(func.NumParameters() == params.parameters->length());

  // Now populate function scope with the formal parameters.
  AddFormalParamsToScope(&params, current_block_->scope);

  // Initialize instance fields that have an explicit initializer expression.
  // The formal parameter names must not be visible to the instance
  // field initializer expressions, yet the parameters must be added to
  // the scope so the expressions use the correct offsets for 'this' when
  // storing values. We make the formal parameters temporarily invisible
  // while parsing the instance field initializer expressions.
  SetInvisible(current_block_->scope, params.parameters->length(), true);
  GrowableArray<Field*> initialized_fields;
  LocalVariable* receiver = current_block_->scope->VariableAt(0);
  OpenBlock();
  ParseInitializedInstanceFields(cls, receiver, &initialized_fields);
  // Make the parameters (which are in the outer scope) visible again.
  SetInvisible(current_block_->scope->parent(),
               params.parameters->length(), false);

  // Turn formal field parameters into field initializers or report error
  // if the function is not a constructor.
  if (params.has_field_initializer) {
    for (int i = 0; i < params.parameters->length(); i++) {
      ParamDesc& param = (*params.parameters)[i];
      if (param.is_field_initializer) {
        const String& field_name = *param.name;
        Field& field = Field::ZoneHandle(cls.LookupInstanceField(field_name));
        if (field.IsNull()) {
          ErrorMsg(param.name_pos,
                   "unresolved reference to instance field '%s'",
                   field_name.ToCString());
        }
        CheckDuplicateFieldInit(param.name_pos, &initialized_fields, &field);
        AstNode* instance = new LoadLocalNode(param.name_pos, receiver);
        LocalVariable* p =
            current_block_->scope->LookupVariable(*param.name, false);
        ASSERT(p != NULL);
        // Initializing formals cannot be used in the explicit initializer
        // list, nor can they be used in the constructor body.
        // Thus, make the parameter invisible.
        p->set_invisible(true);
        AstNode* value = new LoadLocalNode(param.name_pos, p);
        AstNode* initializer = new StoreInstanceFieldNode(
            param.name_pos, instance, field, value);
        current_block_->statements->Add(initializer);
      }
    }
  }

  // Now parse the explicit initializer list or constructor redirection.
  ParseInitializers(cls, receiver, &initialized_fields);

  SequenceNode* init_statements = CloseBlock();
  if (init_statements->length() > 0) {
    // Generate guard around the initializer code.
    LocalVariable* phase_param = LookupPhaseParameter();
    AstNode* phase_value = new LoadLocalNode(TokenPos(), phase_param);
    AstNode* phase_check = new BinaryOpNode(
        TokenPos(), Token::kBIT_AND, phase_value,
        new LiteralNode(TokenPos(),
                        Smi::ZoneHandle(Smi::New(Function::kCtorPhaseInit))));
    AstNode* comparison =
        new ComparisonNode(TokenPos(), Token::kNE_STRICT,
                           phase_check,
                           new LiteralNode(TokenPos(),
                                           Smi::ZoneHandle(Smi::New(0))));
    AstNode* guarded_init_statements =
        new IfNode(TokenPos(), comparison, init_statements, NULL);
    current_block_->statements->Add(guarded_init_statements);
  }

  // Parsing of initializers done. Now we parse the constructor body
  // and add the implicit super call to the super constructor's body
  // if necessary.
  StaticCallNode* super_call = NULL;
  // Look for the super initializer call in the sequence of initializer
  // statements. If it exists and is not the last initializer statement,
  // we need to create an implicit super call to the super constructor's
  // body.
  // Thus, iterate over all but the last initializer to see whether
  // it's a super constructor call.
  for (int i = 0; i < init_statements->length() - 1; i++) {
    if (init_statements->NodeAt(i)->IsStaticCallNode()) {
      StaticCallNode* static_call =
      init_statements->NodeAt(i)->AsStaticCallNode();
      if (static_call->function().IsConstructor()) {
        super_call = static_call;
        break;
      }
    }
  }
  if (super_call != NULL) {
    // Generate an implicit call to the super constructor's body.
    // We need to patch the super _initializer_ call so that it
    // saves the evaluated actual arguments in temporary variables.
    // The temporary variables are necessary so that the argument
    // expressions are not evaluated twice.
    ArgumentListNode* ctor_args = super_call->arguments();
    // The super initializer call has at least 2 arguments: the
    // implicit receiver, and the hidden construction phase.
    ASSERT(ctor_args->length() >= 2);
    for (int i = 2; i < ctor_args->length(); i++) {
      AstNode* arg = ctor_args->NodeAt(i);
      if (!IsSimpleLocalOrLiteralNode(arg)) {
        LocalVariable* temp =
            CreateTempConstVariable(arg->token_pos(), "sca");
        AstNode* save_temp = new StoreLocalNode(arg->token_pos(), temp, arg);
        ctor_args->SetNodeAt(i, save_temp);
      }
    }
  }
  OpenBlock();  // Block to collect constructor body nodes.

  // Insert the implicit super call to the super constructor body.
  if (super_call != NULL) {
    ArgumentListNode* initializer_args = super_call->arguments();
    const Function& super_ctor = super_call->function();
    // Patch the initializer call so it only executes the super initializer.
    initializer_args->SetNodeAt(1,
                        new LiteralNode(TokenPos(),
                        Smi::ZoneHandle(Smi::New(Function::kCtorPhaseInit))));

    ArgumentListNode* super_call_args = new ArgumentListNode(TokenPos());
    // First argument is the receiver.
    super_call_args->Add(new LoadLocalNode(TokenPos(), receiver));
    // Second argument is the construction phase argument.
    AstNode* phase_parameter =
        new LiteralNode(TokenPos(),
                        Smi::ZoneHandle(Smi::New(Function::kCtorPhaseBody)));
    super_call_args->Add(phase_parameter);
    super_call_args->set_names(initializer_args->names());
    for (int i = 2; i < initializer_args->length(); i++) {
      AstNode* arg = initializer_args->NodeAt(i);
      if (arg->IsLiteralNode()) {
        LiteralNode* lit = arg->AsLiteralNode();
        super_call_args->Add(new LiteralNode(TokenPos(), lit->literal()));
      } else {
        ASSERT(arg->IsLoadLocalNode() || arg->IsStoreLocalNode());
        if (arg->IsLoadLocalNode()) {
          const LocalVariable& temp = arg->AsLoadLocalNode()->local();
          super_call_args->Add(new LoadLocalNode(TokenPos(), &temp));
        } else if (arg->IsStoreLocalNode()) {
          const LocalVariable& temp = arg->AsStoreLocalNode()->local();
          super_call_args->Add(new LoadLocalNode(TokenPos(), &temp));
        }
      }
    }
    ASSERT(super_ctor.AreValidArguments(super_call_args->length(),
                                        super_call_args->names(),
                                        NULL));
    current_block_->statements->Add(
        new StaticCallNode(TokenPos(), super_ctor, super_call_args));
  }

  if (CurrentToken() == Token::kLBRACE) {
    ConsumeToken();
    ParseStatementSequence();
    ExpectToken(Token::kRBRACE);
  } else if (CurrentToken() == Token::kARROW) {
    ErrorMsg("constructors may not return a value");
  } else if (IsLiteral("native")) {
    ErrorMsg("native constructors not supported");
  } else if (CurrentToken() == Token::kSEMICOLON) {
    // Some constructors have no function body.
    ConsumeToken();
  } else {
    UnexpectedToken();
  }

  SequenceNode* ctor_block = CloseBlock();
  if (ctor_block->length() > 0) {
    // Generate guard around the constructor body code.
    LocalVariable* phase_param = LookupPhaseParameter();
    AstNode* phase_value = new LoadLocalNode(TokenPos(), phase_param);
    AstNode* phase_check =
        new BinaryOpNode(TokenPos(), Token::kBIT_AND,
            phase_value,
            new LiteralNode(TokenPos(),
                Smi::ZoneHandle(Smi::New(Function::kCtorPhaseBody))));
    AstNode* comparison =
       new ComparisonNode(TokenPos(), Token::kNE_STRICT,
                         phase_check,
                         new LiteralNode(TokenPos(),
                                         Smi::ZoneHandle(Smi::New(0))));
    AstNode* guarded_block_statements =
        new IfNode(TokenPos(), comparison, ctor_block, NULL);
    current_block_->statements->Add(guarded_block_statements);
  }

  SequenceNode* statements = CloseBlock();
  return statements;
}


// Parser is at the opening parenthesis of the formal parameter
// declaration of the function or constructor.
// Parse the formal parameters and code.
SequenceNode* Parser::ParseFunc(const Function& func,
                                Array& default_parameter_values) {
  TRACE_PARSER("ParseFunc");
  Function& saved_innermost_function =
      Function::Handle(innermost_function().raw());
  innermost_function_ = func.raw();

  // Check to ensure we don't have classes with native fields in libraries
  // which do not have a native resolver. This check is delayed until the class
  // is actually used. Invocation of a function in the class is the first point
  // of use. Access of const static fields in the class do not trigger an error.
  if (current_class().num_native_fields() != 0) {
    const Library& lib = Library::Handle(current_class().library());
    if (lib.native_entry_resolver() == NULL) {
      const String& cls_name = String::Handle(current_class().Name());
      const String& lib_name = String::Handle(lib.url());
      ErrorMsg(current_class().token_pos(),
               "class '%s' is trying to extend a native fields class, "
               "but library '%s' has no native resolvers",
               cls_name.ToCString(), lib_name.ToCString());
    }
  }

  if (func.IsConstructor()) {
    SequenceNode* statements = ParseConstructor(func, default_parameter_values);
    innermost_function_ = saved_innermost_function.raw();
    return statements;
  }

  ASSERT(!func.IsConstructor());
  OpenFunctionBlock(func);  // Build local scope for function.

  ParamList params;
  // An instance closure function may capture and access the receiver, but via
  // the context and not via the first formal parameter.
  if (func.IsClosureFunction()) {
    // The first parameter of a closure function is the closure object.
    ASSERT(!func.is_const());  // Closure functions cannot be const.
    params.AddFinalParameter(
        TokenPos(),
        &String::ZoneHandle(Symbols::ClosureParameter()),
        &Type::ZoneHandle(Type::DynamicType()));
  } else if (!func.is_static()) {
    // Static functions do not have a receiver.
    ASSERT(current_class().raw() == func.Owner());
    params.AddReceiver(ReceiverType(TokenPos()));
  } else if (func.IsFactory()) {
    // The first parameter of a factory is the AbstractTypeArguments vector of
    // the type of the instance to be allocated.
    params.AddFinalParameter(
        TokenPos(),
        &String::ZoneHandle(Symbols::TypeArgumentsParameter()),
        &Type::ZoneHandle(Type::DynamicType()));
  }
  ASSERT((CurrentToken() == Token::kLPAREN) || func.IsGetterFunction());
  const bool allow_explicit_default_values = true;
  if (!func.IsGetterFunction()) {
    ParseFormalParameterList(allow_explicit_default_values, &params);
  } else {
    // TODO(hausner): Remove this once we no longer support the old
    // getter syntax with explicit empty parameter list.
    if (CurrentToken() == Token::kLPAREN) {
      ConsumeToken();
      ExpectToken(Token::kRPAREN);
    }
  }

  // The number of parameters and their type are not yet set in local functions,
  // since they are not 'top-level' parsed.
  if (func.IsLocalFunction()) {
    AddFormalParamsToFunction(&params, func);
  }
  SetupDefaultsForOptionalParams(&params, default_parameter_values);
  ASSERT(AbstractType::Handle(func.result_type()).IsResolved());
  ASSERT(func.NumParameters() == params.parameters->length());

  // Check whether the function has any field initializer formal parameters,
  // which are not allowed in non-constructor functions.
  if (params.has_field_initializer) {
    for (int i = 0; i < params.parameters->length(); i++) {
      ParamDesc& param = (*params.parameters)[i];
      if (param.is_field_initializer) {
        ErrorMsg(param.name_pos,
                 "field initializer only allowed in constructors");
      }
    }
  }
  // Populate function scope with the formal parameters.
  AddFormalParamsToScope(&params, current_block_->scope);

  if (FLAG_enable_type_checks &&
      (current_block_->scope->function_level() > 0)) {
    // We are parsing, but not compiling, a local function.
    // The instantiator may be required at run time for generic type checks.
    if (IsInstantiatorRequired()) {
      // Make sure that the receiver of the enclosing instance function
      // (or implicit first parameter of an enclosing factory) is marked as
      // captured if type checks are enabled, because they may access it to
      // instantiate types.
      CaptureInstantiator();
    }
  }

  OpenBlock();  // Open a nested scope for the outermost function block.
  if (CurrentToken() == Token::kLBRACE) {
    ConsumeToken();
    ParseStatementSequence();
    ExpectToken(Token::kRBRACE);
  } else if (CurrentToken() == Token::kARROW) {
    ConsumeToken();
    const intptr_t expr_pos = TokenPos();
    AstNode* expr = ParseExpr(kAllowConst, kConsumeCascades);
    ASSERT(expr != NULL);
    current_block_->statements->Add(new ReturnNode(expr_pos, expr));
  } else if (IsLiteral("native")) {
    ParseNativeFunctionBlock(&params, func);
  } else if (func.is_external()) {
    // Body of an external method contains a single throw.
    const String& function_name = String::ZoneHandle(func.name());
    current_block_->statements->Add(
        ThrowNoSuchMethodError(TokenPos(), function_name));
  } else {
    UnexpectedToken();
  }
  SequenceNode* body = CloseBlock();
  current_block_->statements->Add(body);
  innermost_function_ = saved_innermost_function.raw();
  return CloseBlock();
}


void Parser::SkipIf(Token::Kind token) {
  if (CurrentToken() == token) {
    ConsumeToken();
  }
}


// Skips tokens up to matching closing parenthesis.
void Parser::SkipToMatchingParenthesis() {
  ASSERT(CurrentToken() == Token::kLPAREN);
  int level = 0;
  do {
    if (CurrentToken() == Token::kLPAREN) {
      level++;
    } else if (CurrentToken() == Token::kRPAREN) {
      level--;
    }
    ConsumeToken();
  } while ((level > 0) && (CurrentToken() != Token::kEOS));
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
      if (CurrentToken() != Token::kLPAREN) {
        ErrorMsg("'(' expected");
      }
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


void Parser::ParseQualIdent(QualIdent* qual_ident) {
  TRACE_PARSER("ParseQualIdent");
  ASSERT(IsIdentifier());
  ASSERT(!current_class().IsNull());
  qual_ident->ident_pos = TokenPos();
  qual_ident->ident = CurrentLiteral();
  qual_ident->lib_prefix = NULL;
  ConsumeToken();
  if (CurrentToken() == Token::kPERIOD) {
    // An identifier cannot be resolved in a local scope when top level parsing.
    if (is_top_level_ ||
        !ResolveIdentInLocalScope(qual_ident->ident_pos,
                                  *(qual_ident->ident),
                                  NULL)) {
      LibraryPrefix& lib_prefix = LibraryPrefix::ZoneHandle();
      lib_prefix = current_class().LookupLibraryPrefix(*(qual_ident->ident));
      if (!lib_prefix.IsNull()) {
        // We have a library prefix qualified identifier, unless the prefix is
        // shadowed by a type parameter in scope.
        if (current_class().IsNull() ||
            (current_class().LookupTypeParameter(*(qual_ident->ident),
                                                 TokenPos()) ==
             TypeParameter::null())) {
          ConsumeToken();  // Consume the kPERIOD token.
          qual_ident->lib_prefix = &lib_prefix;
          qual_ident->ident_pos = TokenPos();
          qual_ident->ident =
              ExpectIdentifier("identifier expected after '.'");
        }
      }
    }
  }
}


void Parser::ParseMethodOrConstructor(ClassDesc* members, MemberDesc* method) {
  TRACE_PARSER("ParseMethodOrConstructor");
  ASSERT(CurrentToken() == Token::kLPAREN || method->IsGetter());
  intptr_t method_pos = this->TokenPos();
  ASSERT(method->type != NULL);
  ASSERT(method->name_pos > 0);
  ASSERT(current_member_ == method);

  if (method->has_var) {
    ErrorMsg(method->name_pos, "keyword var not allowed for methods");
  }
  if (method->has_final) {
    ErrorMsg(method->name_pos, "'final' not allowed for methods");
  }
  if (method->has_abstract && method->has_static) {
    ErrorMsg(method->name_pos,
             "static method '%s' cannot be abstract",
             method->name->ToCString());
  }
  if (method->has_const && !method->IsFactoryOrConstructor()) {
    ErrorMsg(method->name_pos, "'const' not allowed for methods");
  }
  if (method->has_abstract && method->IsFactoryOrConstructor()) {
    ErrorMsg(method->name_pos, "constructor cannot be abstract");
  }
  if (method->has_const && method->IsConstructor()) {
    Class& cls = Class::Handle(library_.LookupClass(members->class_name()));
    cls.set_is_const();
  }
  if (method->has_abstract && members->is_interface()) {
    ErrorMsg(method->name_pos,
             "'abstract' method only allowed in class definition");
  }
  if (method->has_external && members->is_interface()) {
    ErrorMsg(method->name_pos,
             "'external' method only allowed in class definition");
  }

  // Parse the formal parameters.
  const bool are_implicitly_final = method->has_const;
  const bool allow_explicit_default_values = true;
  const intptr_t formal_param_pos = TokenPos();
  method->params.Clear();
  // Static functions do not have a receiver.
  // The first parameter of a factory is the AbstractTypeArguments vector of
  // the type of the instance to be allocated.
  if (!method->has_static || method->IsConstructor()) {
    method->params.AddReceiver(ReceiverType(formal_param_pos));
  } else if (method->IsFactory()) {
    method->params.AddFinalParameter(
        formal_param_pos,
        &String::ZoneHandle(Symbols::TypeArgumentsParameter()),
        &Type::ZoneHandle(Type::DynamicType()));
  }
  // Constructors have an implicit parameter for the construction phase.
  if (method->IsConstructor()) {
    method->params.AddFinalParameter(
        TokenPos(),
        &String::ZoneHandle(Symbols::PhaseParameter()),
        &Type::ZoneHandle(Type::SmiType()));
  }
  if (are_implicitly_final) {
    method->params.SetImplicitlyFinal();
  }
  if (!method->IsGetter()) {
    ParseFormalParameterList(allow_explicit_default_values, &method->params);
  } else {
    // TODO(hausner): Remove this once the old getter syntax with
    // empty parameter list is no longer supported.
    if (CurrentToken() == Token::kLPAREN) {
      if (FLAG_warn_legacy_getters) {
        Warning("legacy getter syntax, remove parenthesis");
      }
      ConsumeToken();
      ExpectToken(Token::kRPAREN);
    }
  }

  // Now that we know the parameter list, we can distinguish between the
  // unary and binary operator -.
  if (method->has_operator) {
    if ((method->operator_token == Token::kSUB) &&
       (method->params.num_fixed_parameters == 1)) {
      // Patch up name for unary operator - so it does not clash with the
      // name for binary operator -.
      method->operator_token = Token::kNEGATE;
      *method->name = Symbols::New(Token::Str(Token::kNEGATE));
    }
    CheckOperatorArity(*method);
  }

  if (members->FunctionNameExists(*method->name, method->kind)) {
    ErrorMsg(method->name_pos,
             "field or method '%s' already defined", method->name->ToCString());
  }

  // Mangle the name for getter and setter functions and check function
  // arity.
  if (method->IsGetter() || method->IsSetter()) {
    int expected_num_parameters = 0;
    if (method->IsGetter()) {
      expected_num_parameters = (method->has_static) ? 0 : 1;
      method->name = &String::ZoneHandle(Field::GetterSymbol(*method->name));
    } else {
      ASSERT(method->IsSetter());
      expected_num_parameters = (method->has_static) ? 1 : 2;
      method->name = &String::ZoneHandle(Field::SetterSymbol(*method->name));
    }
    if ((method->params.num_fixed_parameters != expected_num_parameters) ||
        (method->params.num_optional_parameters != 0)) {
      ErrorMsg(method->name_pos, "illegal %s parameters",
               method->IsGetter() ? "getter" : "setter");
    }
  }

  // Parse redirecting factory constructor.
  Type& redirection_type = Type::Handle();
  String& redirection_identifier = String::Handle();
  if (method->IsFactory() && (CurrentToken() == Token::kASSIGN)) {
    ConsumeToken();
    const intptr_t type_pos = TokenPos();
    const AbstractType& type = AbstractType::Handle(
        ParseType(ClassFinalizer::kTryResolve));
    if (!type.IsMalformed() &&
        (type.IsTypeParameter() || type.IsDynamicType())) {
      // Replace the type with a malformed type and compile a throw when called.
      redirection_type = ClassFinalizer::NewFinalizedMalformedType(
          Error::Handle(),  // No previous error.
          current_class(),
          type_pos,
          ClassFinalizer::kTryResolve,  // No compile-time error.
          "factory '%s' may not redirect to %s'%s'",
          method->name->ToCString(),
          type.IsTypeParameter() ? "type parameter " : "",
          type.IsTypeParameter() ?
              String::Handle(type.UserVisibleName()).ToCString() : "dynamic");
    } else {
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
      ErrorMsg("initializers only allowed on constructors");
    }
    if ((LookaheadToken(1) == Token::kTHIS) &&
        ((LookaheadToken(2) == Token::kLPAREN) ||
         LookaheadToken(4) == Token::kLPAREN)) {
      // Redirected constructor: either this(...) or this.xxx(...).
      if (method->params.has_field_initializer) {
        // Constructors that redirect to another constructor must not
        // initialize any fields using field initializer parameters.
        ErrorMsg(formal_param_pos, "Redirecting constructor "
                 "may not use field initializer parameters");
      }
      ConsumeToken();  // Colon.
      ExpectToken(Token::kTHIS);
      String& redir_name = String::ZoneHandle(
          String::Concat(members->class_name(),
                         String::Handle(Symbols::Dot())));
      if (CurrentToken() == Token::kPERIOD) {
        ConsumeToken();
        redir_name = String::Concat(redir_name,
            *ExpectIdentifier("constructor name expected"));
      }
      method->redirect_name = &redir_name;
      if (CurrentToken() != Token::kLPAREN) {
        ErrorMsg("'(' expected");
      }
      SkipToMatchingParenthesis();
    } else {
      SkipInitializers();
    }
  }

  // Only constructors can redirect to another method.
  ASSERT((method->redirect_name == NULL) || method->IsConstructor());

  intptr_t method_end_pos = method_pos;
  if ((CurrentToken() == Token::kLBRACE) ||
      (CurrentToken() == Token::kARROW)) {
    if (method->has_abstract) {
      ErrorMsg(method->name_pos,
               "abstract method '%s' may not have a function body",
               method->name->ToCString());
    } else if (method->has_external) {
      ErrorMsg(method->name_pos,
               "external method '%s' may not have a function body",
               method->name->ToCString());
    } else if (method->IsFactoryOrConstructor() && method->has_const) {
      ErrorMsg(method->name_pos,
               "const constructor or factory '%s' may not have a function body",
               method->name->ToCString());
    } else if (members->is_interface()) {
      ErrorMsg(method->name_pos,
               "function body not allowed in interface declaration");
    }
    if (method->redirect_name != NULL) {
      ErrorMsg(method->name_pos,
               "Constructor with redirection may not have a function body");
    }
    if (CurrentToken() == Token::kLBRACE) {
      SkipBlock();
    } else {
      ConsumeToken();
      SkipExpr();
      ExpectSemicolon();
    }
    method_end_pos = TokenPos();
  } else if (IsLiteral("native")) {
    if (method->has_abstract) {
      ErrorMsg(method->name_pos,
               "abstract method '%s' may not have a function body",
               method->name->ToCString());
    } else if (members->is_interface()) {
      ErrorMsg(method->name_pos,
               "function body not allowed in interface declaration");
    } else if (method->IsFactoryOrConstructor() && method->has_const) {
      ErrorMsg(method->name_pos,
               "const constructor or factory '%s' may not be native",
               method->name->ToCString());
    }
    if (method->redirect_name != NULL) {
      ErrorMsg(method->name_pos,
               "Constructor with redirection may not have a function body");
    }
    ParseNativeDeclaration();
  } else {
    // We haven't found a method body. Issue error if one is required.
    const bool must_have_body =
        !members->is_interface() &&
        method->has_static &&
        !method->has_external &&
        redirection_type.IsNull();
    if (must_have_body) {
      ErrorMsg(method->name_pos,
               "function body expected for method '%s'",
               method->name->ToCString());
    }

    if (CurrentToken() == Token::kSEMICOLON) {
      ConsumeToken();
      if (!members->is_interface() &&
          !method->has_static &&
          !method->has_external &&
          !method->IsConstructor()) {
          // Methods, getters and setters without a body are
          // implicitly abstract.
        method->has_abstract = true;
      }
    } else {
      // Signature is not followed by semicolon or body. Issue an
      // appropriate error.
      const bool must_have_semicolon =
          members->is_interface() ||
          (method->redirect_name != NULL) ||
          (method->IsConstructor() && method->has_const) ||
          method->has_external;
      if (must_have_semicolon) {
        ExpectSemicolon();
      } else {
        ErrorMsg(method->name_pos,
                 "function body or semicolon expected for method '%s'",
                 method->name->ToCString());
      }
    }
  }

  RawFunction::Kind function_kind;
  if (method->IsFactoryOrConstructor()) {
    function_kind = RawFunction::kConstructor;
  } else if (method->IsGetter()) {
    function_kind = RawFunction::kGetterFunction;
  } else if (method->IsSetter()) {
    function_kind = RawFunction::kSetterFunction;
  } else {
    function_kind = RawFunction::kRegularFunction;
  }
  Function& func = Function::Handle(
      Function::New(*method->name,
                    function_kind,
                    method->has_static,
                    method->has_const,
                    method->has_abstract,
                    method->has_external,
                    current_class(),
                    method_pos));
  func.set_result_type(*method->type);
  func.set_end_token_pos(method_end_pos);

  // If this method is a redirecting factory, set the redirection information.
  if (!redirection_type.IsNull()) {
    ASSERT(func.IsFactory());
    func.SetRedirectionType(redirection_type);
    if (!redirection_identifier.IsNull()) {
      func.SetRedirectionIdentifier(redirection_identifier);
    }
  }

  // No need to resolve parameter types yet, or add parameters to local scope.
  ASSERT(is_top_level_);
  AddFormalParamsToFunction(&method->params, func);
  members->AddFunction(func);
}


void Parser::ParseFieldDefinition(ClassDesc* members, MemberDesc* field) {
  TRACE_PARSER("ParseFieldDefinition");
  // The parser has read the first field name and is now at the token
  // after the field name.
  ASSERT(CurrentToken() == Token::kSEMICOLON ||
         CurrentToken() == Token::kCOMMA ||
         CurrentToken() == Token::kASSIGN);
  ASSERT(field->type != NULL);
  ASSERT(field->name_pos > 0);
  ASSERT(current_member_ == field);
  // All const fields are also final.
  ASSERT(!field->has_const || field->has_final);

  if (field->has_abstract) {
    ErrorMsg("keyword 'abstract' not allowed in field declaration");
  }
  if (field->has_external) {
    ErrorMsg("keyword 'external' not allowed in field declaration");
  }
  if (field->has_factory) {
    ErrorMsg("keyword 'factory' not allowed in field declaration");
  }
  if (members->FieldNameExists(*field->name, !field->has_final)) {
    ErrorMsg(field->name_pos,
             "'%s' field/method already defined\n", field->name->ToCString());
  }
  Function& getter = Function::Handle();
  Function& setter = Function::Handle();
  Field& class_field = Field::Handle();
  Instance& init_value = Instance::Handle();
  while (true) {
    bool has_initializer = CurrentToken() == Token::kASSIGN;
    bool has_simple_literal = false;
    if (has_initializer) {
      ConsumeToken();
      init_value = Object::sentinel();
      // For static const fields, the initialization expression
      // will be parsed through the kConstImplicitGetter method
      // invocation/compilation.
      // For instance fields, the expression is parsed when a constructor
      // is compiled.
      // For static fields with very simple initializer expressions
      // (e.g. a literal number or string) we optimize away the
      // kConstImplicitGetter and initialize the field here.

      if (field->has_static && (field->has_final || field->has_const) &&
          (LookaheadToken(1) == Token::kSEMICOLON)) {
        has_simple_literal = IsSimpleLiteral(*field->type, &init_value);
      }
      SkipExpr();
    } else {
      if (field->has_const || (field->has_static && field->has_final)) {
        ErrorMsg(field->name_pos,
                 "%s%s field '%s' must have an initializer expression",
                 field->has_static ? "static " : "",
                 field->has_const ? "const" : "final",
                 field->name->ToCString());
      }
    }

    // Create the field object.
    class_field = Field::New(*field->name,
                             field->has_static,
                             field->has_final,
                             field->has_const,
                             current_class(),
                             field->name_pos);
    class_field.set_type(*field->type);
    class_field.set_has_initializer(has_initializer);
    members->AddField(class_field);

    // For static const fields, set value to "uninitialized" and
    // create a kConstImplicitGetter getter method.
    if (field->has_static && has_initializer) {
      class_field.set_value(init_value);
      if (!has_simple_literal) {
        String& getter_name = String::Handle(Field::GetterSymbol(*field->name));
        getter = Function::New(getter_name,
                               RawFunction::kConstImplicitGetter,
                               field->has_static,
                               field->has_const,
                               /* is_abstract = */ false,
                               /* is_external = */ false,
                               current_class(),
                               field->name_pos);
        getter.set_result_type(*field->type);
        members->AddFunction(getter);
      }
    }

    // For instance fields, we create implicit getter and setter methods.
    if (!field->has_static) {
      String& getter_name = String::Handle(Field::GetterSymbol(*field->name));
      getter = Function::New(getter_name, RawFunction::kImplicitGetter,
                             field->has_static,
                             field->has_final,
                             /* is_abstract = */ false,
                             /* is_external = */ false,
                             current_class(),
                             field->name_pos);
      ParamList params;
      ASSERT(current_class().raw() == getter.Owner());
      params.AddReceiver(ReceiverType(TokenPos()));
      getter.set_result_type(*field->type);
      AddFormalParamsToFunction(&params, getter);
      members->AddFunction(getter);
      if (!field->has_final) {
        // Build a setter accessor for non-const fields.
        String& setter_name = String::Handle(Field::SetterSymbol(*field->name));
        setter = Function::New(setter_name, RawFunction::kImplicitSetter,
                               field->has_static,
                               field->has_final,
                               /* is_abstract = */ false,
                               /* is_external = */ false,
                               current_class(),
                               field->name_pos);
        ParamList params;
        ASSERT(current_class().raw() == setter.Owner());
        params.AddReceiver(ReceiverType(TokenPos()));
        params.AddFinalParameter(TokenPos(),
                                 &String::ZoneHandle(Symbols::Value()),
                                 field->type);
        setter.set_result_type(Type::Handle(Type::VoidType()));
        AddFormalParamsToFunction(&params, setter);
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
    ErrorMsg(member.name_pos, "operator %s expects %"Pd" argument(s)",
        member.name->ToCString(), (expected_num_parameters - 1));
  }
}


void Parser::ParseClassMemberDefinition(ClassDesc* members) {
  TRACE_PARSER("ParseClassMemberDefinition");
  MemberDesc member;
  current_member_ = &member;
  if ((CurrentToken() == Token::kABSTRACT) &&
      (LookaheadToken(1) != Token::kLPAREN)) {
    if (FLAG_fail_legacy_abstract) {
      ErrorMsg("illegal use of abstract");
    }
    ConsumeToken();
    member.has_abstract = true;
  }
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
  if (CurrentToken() == Token::kCONST) {
    ConsumeToken();
    member.has_const = true;
  } else if (CurrentToken() == Token::kFINAL) {
    ConsumeToken();
    member.has_final = true;
  }
  if (CurrentToken() == Token::kVAR) {
    if (member.has_const) {
      ErrorMsg("identifier expected after 'const'");
    }
    if (member.has_final) {
      ErrorMsg("identifier expected after 'final'");
    }
    ConsumeToken();
    member.has_var = true;
    // The member type is the 'dynamic' type.
    member.type = &Type::ZoneHandle(Type::DynamicType());
  } else if (CurrentToken() == Token::kFACTORY) {
    ConsumeToken();
    if (member.has_static) {
      ErrorMsg("factory method cannot be explicitly marked static");
    }
    member.has_factory = true;
    member.has_static = true;
    // The result type depends on the name of the factory method.
  }
  // Optionally parse a type.
  if (CurrentToken() == Token::kVOID) {
    if (member.has_var || member.has_factory) {
      ErrorMsg("void not expected");
    }
    ConsumeToken();
    ASSERT(member.type == NULL);
    member.type = &Type::ZoneHandle(Type::VoidType());
  } else if (CurrentToken() == Token::kIDENT) {
    // This is either a type name or the name of a method/constructor/field.
    if ((member.type == NULL) && !member.has_factory) {
      // We have not seen a member type yet, so we check if the next
      // identifier could represent a type before parsing it.
      Token::Kind follower = LookaheadToken(1);
      // We have an identifier followed by a 'follower' token.
      // We either parse a type or assume that no type is specified.
      if ((follower == Token::kLT) ||  // Parameterized type.
          (follower == Token::kGET) ||  // Getter following a type.
          (follower == Token::kSET) ||  // Setter following a type.
          (follower == Token::kOPERATOR) ||  // Operator following a type.
          (Token::IsIdentifier(follower)) ||  // Member name following a type.
          ((follower == Token::kPERIOD) &&    // Qualified class name of type,
           (LookaheadToken(3) != Token::kLPAREN))) {  // but not a named constr.
        ASSERT(is_top_level_);
        // The declared type of fields is never ignored, even in unchecked mode,
        // because getters and setters could be closurized at some time (not
        // supported yet).
        member.type = &AbstractType::ZoneHandle(
            ParseType(ClassFinalizer::kTryResolve));
      }
    }
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
        ErrorMsg(member.name_pos, "factory name must be '%s'",
                 members->class_name().ToCString());
      }
      const Object& result_type_class = Object::Handle(
          UnresolvedClass::New(LibraryPrefix::Handle(),
                               *member.name,
                               member.name_pos));
      // The type arguments of the result type are set during finalization.
      member.type = &Type::ZoneHandle(Type::New(result_type_class,
                                                TypeArguments::Handle(),
                                                member.name_pos));
    } else if (member.has_static) {
      ErrorMsg(member.name_pos, "constructor cannot be static");
    }
    // We must be dealing with a constructor or named constructor.
    member.kind = RawFunction::kConstructor;
    String& ctor_suffix = String::ZoneHandle(Symbols::Dot());
    if (CurrentToken() == Token::kPERIOD) {
      // Named constructor.
      ConsumeToken();
      member.constructor_name = ExpectIdentifier("identifier expected");
      ctor_suffix = String::Concat(ctor_suffix, *member.constructor_name);
    }
    *member.name = String::Concat(*member.name, ctor_suffix);
    // Ensure that names are symbols.
    *member.name = Symbols::New(*member.name);
    if (member.type == NULL) {
      ASSERT(!member.has_factory);
      // The body of the constructor cannot modify the type arguments of the
      // constructed instance, which is passed in as a hidden parameter.
      // Therefore, there is no need to set the result type to be checked.
      member.type = &Type::ZoneHandle(Type::DynamicType());
    } else {
      // The type can only be already set in the factory case.
      if (!member.has_factory) {
        ErrorMsg(member.name_pos, "constructor must not specify return type");
      }
    }
    if (CurrentToken() != Token::kLPAREN) {
      ErrorMsg("left parenthesis expected");
    }
  } else if ((CurrentToken() == Token::kGET) && !member.has_var &&
             (LookaheadToken(1) != Token::kLPAREN) &&
             (LookaheadToken(1) != Token::kASSIGN) &&
             (LookaheadToken(1) != Token::kCOMMA)  &&
             (LookaheadToken(1) != Token::kSEMICOLON)) {
    ConsumeToken();
    member.kind = RawFunction::kGetterFunction;
    member.name_pos = this->TokenPos();
    member.name = ExpectIdentifier("identifier expected");
    // If the result type was not specified, it will be set to DynamicType.
  } else if ((CurrentToken() == Token::kSET) && !member.has_var &&
             (LookaheadToken(1) != Token::kLPAREN) &&
             (LookaheadToken(1) != Token::kASSIGN) &&
             (LookaheadToken(1) != Token::kCOMMA)  &&
             (LookaheadToken(1) != Token::kSEMICOLON))  {
    ConsumeToken();
    member.kind = RawFunction::kSetterFunction;
    member.name_pos = this->TokenPos();
    member.name = ExpectIdentifier("identifier expected");
    if (CurrentToken() != Token::kLPAREN) {
      ErrorMsg("'(' expected");
    }
    // The grammar allows a return type, so member.type is not always NULL here.
    // If no return type is specified, the return type of the setter is dynamic.
    if (member.type == NULL) {
      member.type = &Type::ZoneHandle(Type::DynamicType());
    }
  } else if ((CurrentToken() == Token::kOPERATOR) && !member.has_var &&
             (LookaheadToken(1) != Token::kLPAREN) &&
             (LookaheadToken(1) != Token::kASSIGN) &&
             (LookaheadToken(1) != Token::kCOMMA)  &&
             (LookaheadToken(1) != Token::kSEMICOLON)) {
    ConsumeToken();
    if (!Token::CanBeOverloaded(CurrentToken())) {
      ErrorMsg("invalid operator overloading");
    }
    if (member.has_static) {
      ErrorMsg("operator overloading functions cannot be static");
    }
    member.operator_token = CurrentToken();
    member.has_operator = true;
    member.kind = RawFunction::kRegularFunction;
    member.name_pos = this->TokenPos();
    member.name =
        &String::ZoneHandle(Symbols::New(Token::Str(member.operator_token)));
    ConsumeToken();
  } else if (IsIdentifier()) {
    member.name = CurrentLiteral();
    member.name_pos = TokenPos();
    ConsumeToken();
  } else {
    ErrorMsg("identifier expected");
  }

  ASSERT(member.name != NULL);
  if (CurrentToken() == Token::kLPAREN || member.IsGetter()) {
    if (members->is_interface() && member.has_static) {
      if (member.has_factory) {
        ErrorMsg("factory constructors are not allowed in interfaces");
      } else {
        ErrorMsg("static methods are not allowed in interfaces");
      }
    }
    // Constructor or method.
    if (member.type == NULL) {
      member.type = &Type::ZoneHandle(Type::DynamicType());
    }
    ASSERT(member.IsFactory() == member.has_factory);
    ParseMethodOrConstructor(members, &member);
  } else if (CurrentToken() ==  Token::kSEMICOLON ||
             CurrentToken() == Token::kCOMMA ||
             CurrentToken() == Token::kASSIGN) {
    // Field definition.
    if (member.has_const) {
      // const fields are implicitly final.
      member.has_final = true;
    }
    if (member.type == NULL) {
      if (member.has_final) {
        member.type = &Type::ZoneHandle(Type::DynamicType());
      } else {
        ErrorMsg("missing 'var', 'final', 'const' or type"
                 " in field declaration");
      }
    }
    if (members->is_interface() && member.has_static && !member.has_final) {
      ErrorMsg("static non-final fields are not allowed in interfaces");
    }
    ParseFieldDefinition(members, &member);
  } else {
    UnexpectedToken();
  }
  current_member_ = NULL;
  members->AddMember(member);
}


void Parser::ParseClassDefinition(const GrowableObjectArray& pending_classes) {
  TRACE_PARSER("ParseClassDefinition");
  bool is_patch = false;
  bool is_abstract = false;
  if (is_patch_source() &&
      (CurrentToken() == Token::kIDENT) &&
      CurrentLiteral()->Equals("patch")) {
    ConsumeToken();
    is_patch = true;
  } else if (CurrentToken() == Token::kABSTRACT) {
    is_abstract = true;
    ConsumeToken();
  }
  const intptr_t class_pos = TokenPos();
  ExpectToken(Token::kCLASS);
  const intptr_t classname_pos = TokenPos();
  String& class_name = *ExpectUserDefinedTypeIdentifier("class name expected");
  if (FLAG_trace_parser) {
    OS::Print("TopLevel parsing class '%s'\n", class_name.ToCString());
  }
  Class& cls = Class::Handle();
  Object& obj = Object::Handle(library_.LookupLocalObject(class_name));
  if (obj.IsNull()) {
    if (is_patch) {
      ErrorMsg(classname_pos, "missing class '%s' cannot be patched",
               class_name.ToCString());
    }
    cls = Class::New(class_name, script_, classname_pos);
    library_.AddClass(cls);
  } else {
    if (!obj.IsClass()) {
      ErrorMsg(classname_pos, "'%s' is already defined",
               class_name.ToCString());
    }
    cls ^= obj.raw();
    if (cls.is_interface()) {
      ErrorMsg(classname_pos, "'%s' %s",
               class_name.ToCString(),
               is_patch ?
                   "interface cannot be patched" :
                   "is already defined as interface");
    } else if (is_patch) {
      String& patch = String::Handle(Symbols::New("patch "));
      patch = String::Concat(patch, class_name);
      patch = Symbols::New(patch);
      cls = Class::New(patch, script_, classname_pos);
      cls.set_library(library_);
    } else {
      // Not patching a class, but it has been found. This must be one of the
      // pre-registered classes from object.cc or a duplicate definition.
      if (cls.functions() != Object::empty_array()) {
        ErrorMsg(classname_pos, "class '%s' is already defined",
                 class_name.ToCString());
      }
      // Pre-registered classes need their scripts connected at this time.
      cls.set_script(script_);
    }
  }
  ASSERT(!cls.IsNull());
  ASSERT(cls.functions() == Object::empty_array());
  set_current_class(cls);
  ParseTypeParameters(cls);
  Type& super_type = Type::Handle();
  if (CurrentToken() == Token::kEXTENDS) {
    ConsumeToken();
    const intptr_t type_pos = TokenPos();
    const AbstractType& type = AbstractType::Handle(
        ParseType(ClassFinalizer::kTryResolve));
    if (type.IsTypeParameter()) {
      ErrorMsg(type_pos,
               "class '%s' may not extend type parameter '%s'",
               class_name.ToCString(),
               String::Handle(type.UserVisibleName()).ToCString());
    }
    super_type ^= type.raw();
    if (super_type.IsInterfaceType()) {
      ErrorMsg(type_pos,
               "class '%s' may implement, but cannot extend interface '%s'",
               class_name.ToCString(),
               String::Handle(super_type.UserVisibleName()).ToCString());
    }
  } else {
    // No extends clause: Implicitly extend Object.
    super_type = Type::ObjectType();
  }
  ASSERT(!super_type.IsNull());
  cls.set_super_type(super_type);

  if (CurrentToken() == Token::kIMPLEMENTS) {
    Array& interfaces = Array::Handle();
    const intptr_t interfaces_pos = TokenPos();
    interfaces = ParseInterfaceList();
    AddInterfaces(interfaces_pos, cls, interfaces);
  }

  ExpectToken(Token::kLBRACE);
  ClassDesc members(cls, class_name, false, class_pos);
  while (CurrentToken() != Token::kRBRACE) {
    SkipMetadata();
    ParseClassMemberDefinition(&members);
  }
  ExpectToken(Token::kRBRACE);

  if (is_abstract) {
    cls.set_is_abstract();
  }

  // Add an implicit constructor if no explicit constructor is present. No
  // implicit constructors are needed for patch classes.
  if (!members.has_constructor() && !is_patch) {
    AddImplicitConstructor(&members);
  }
  CheckConstructors(&members);

  Array& array = Array::Handle();
  array = Array::MakeArray(members.fields());
  cls.SetFields(array);

  // Creating a new array for functions marks the class as parsed.
  array = Array::MakeArray(members.functions());
  cls.SetFunctions(array);

  if (!is_patch) {
    pending_classes.Add(cls, Heap::kOld);
  } else {
    // Lookup the patched class and apply the changes.
    obj = library_.LookupLocalObject(class_name);
    const char* err_msg = Class::Cast(obj).ApplyPatch(cls);
    if (err_msg != NULL) {
      ErrorMsg(classname_pos, "applying patch failed with '%s'", err_msg);
    }
  }
}


// Add an implicit constructor if no explicit constructor is present.
void Parser::AddImplicitConstructor(ClassDesc* class_desc) {
  // The implicit constructor is unnamed, has no explicit parameter,
  // and contains a supercall in the initializer list.
  String& ctor_name = String::ZoneHandle(
    String::Concat(class_desc->class_name(), String::Handle(Symbols::Dot())));
  ctor_name = Symbols::New(ctor_name);
  // The token position for the implicit constructor is the 'class'
  // keyword of the constructor's class.
  Function& ctor = Function::Handle(
      Function::New(ctor_name,
                    RawFunction::kConstructor,
                    /* is_static = */ false,
                    /* is_const = */ false,
                    /* is_abstract = */ false,
                    /* is_external = */ false,
                    current_class(),
                    class_desc->token_pos()));
  ParamList params;
  // Add implicit 'this' parameter.
  ASSERT(current_class().raw() == ctor.Owner());
  params.AddReceiver(ReceiverType(TokenPos()));
  // Add implicit parameter for construction phase.
  params.AddFinalParameter(TokenPos(),
                           &String::ZoneHandle(Symbols::PhaseParameter()),
                           &Type::ZoneHandle(Type::SmiType()));

  AddFormalParamsToFunction(&params, ctor);
  // The body of the constructor cannot modify the type of the constructed
  // instance, which is passed in as the receiver.
  ctor.set_result_type(*((*params.parameters)[0].type));
  class_desc->AddFunction(ctor);
}


// Check for cycles in constructor redirection. Also check whether a
// named constructor collides with the name of another class member.
void Parser::CheckConstructors(ClassDesc* class_desc) {
  // Check for cycles in constructor redirection.
  const GrowableArray<MemberDesc>& members = class_desc->members();
  for (int i = 0; i < members.length(); i++) {
    MemberDesc* member = &members[i];

    if (member->constructor_name != NULL) {
      // Check whether constructor name conflicts with a member name.
      if (class_desc->FunctionNameExists(
          *member->constructor_name, member->kind)) {
        ErrorMsg(member->name_pos,
                 "Named constructor '%s' conflicts with method or field '%s'",
                 member->name->ToCString(),
                 member->constructor_name->ToCString());
      }
    }

    GrowableArray<MemberDesc*> ctors;
    while ((member != NULL) && (member->redirect_name != NULL)) {
      ASSERT(member->IsConstructor());
      // Check whether we have already seen this member.
      for (int i = 0; i < ctors.length(); i++) {
        if (ctors[i] == member) {
          ErrorMsg(member->name_pos,
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


// Look ahead to detect if we are seeing ident [ TypeParameters ] "(".
// We need this lookahead to distinguish between the optional return type
// and the alias name of a function type alias.
// Token position remains unchanged.
bool Parser::IsFunctionTypeAliasName() {
  if (IsIdentifier() && (LookaheadToken(1) == Token::kLPAREN)) {
    return true;
  }
  const intptr_t saved_pos = TokenPos();
  bool is_alias_name = false;
  if (IsIdentifier() && (LookaheadToken(1) == Token::kLT)) {
    ConsumeToken();
    if (TryParseTypeParameter() && (CurrentToken() == Token::kLPAREN)) {
      is_alias_name = true;
    }
  }
  SetPosition(saved_pos);
  return is_alias_name;
}


void Parser::ParseFunctionTypeAlias(
    const GrowableObjectArray& pending_classes) {
  TRACE_PARSER("ParseFunctionTypeAlias");
  ExpectToken(Token::kTYPEDEF);

  // Allocate an interface to hold the type parameters and their bounds.
  // Make it the owner of the function type descriptor.
  const Class& alias_owner = Class::Handle(
      Class::New(String::Handle(Symbols::New(":alias_owner")),
                 Script::Handle(),
                 TokenPos()));
  alias_owner.set_is_interface();
  alias_owner.set_library(library_);
  set_current_class(alias_owner);

  // Parse the result type of the function type.
  AbstractType& result_type = Type::Handle(Type::DynamicType());
  if (CurrentToken() == Token::kVOID) {
    ConsumeToken();
    result_type = Type::VoidType();
  } else if (!IsFunctionTypeAliasName()) {
    // Type annotations in typedef are never ignored, even in unchecked mode.
    // Wait until we have an owner class before resolving the result type.
    result_type = ParseType(ClassFinalizer::kDoNotResolve);
  }

  const intptr_t alias_name_pos = TokenPos();
  const String* alias_name =
      ExpectUserDefinedTypeIdentifier("function alias name expected");

  // Parse the type parameters of the function type.
  ParseTypeParameters(alias_owner);
  // At this point, the type parameters have been parsed, so we can resolve the
  // result type.
  if (!result_type.IsNull()) {
    ResolveTypeFromClass(alias_owner,
                         ClassFinalizer::kTryResolve,
                         &result_type);
  }
  // Parse the formal parameters of the function type.
  if (CurrentToken() != Token::kLPAREN) {
    ErrorMsg("formal parameter list expected");
  }
  ParamList func_params;

  // Add implicit closure object parameter.
  func_params.AddFinalParameter(
      TokenPos(),
      &String::ZoneHandle(Symbols::ClosureParameter()),
      &Type::ZoneHandle(Type::DynamicType()));

  const bool no_explicit_default_values = false;
  ParseFormalParameterList(no_explicit_default_values, &func_params);
  // The field 'is_static' has no meaning for signature functions.
  Function& signature_function = Function::Handle(
      Function::New(*alias_name,
                    RawFunction::kSignatureFunction,
                    /* is_static = */ false,
                    /* is_const = */ false,
                    /* is_abstract = */ false,
                    /* is_external = */ false,
                    alias_owner,
                    alias_name_pos));
  signature_function.set_result_type(result_type);
  AddFormalParamsToFunction(&func_params, signature_function);
  const String& signature = String::Handle(signature_function.Signature());
  if (FLAG_trace_parser) {
    OS::Print("TopLevel parsing function type alias '%s'\n",
              signature.ToCString());
  }
  // Lookup the signature class, i.e. the class whose name is the signature.
  // We only lookup in the current library, but not in its imports, and only
  // create a new canonical signature class if it does not exist yet.
  Class& signature_class = Class::ZoneHandle(
      library_.LookupLocalClass(signature));
  if (signature_class.IsNull()) {
    signature_class = Class::NewSignatureClass(signature,
                                               signature_function,
                                               script_);
    // Record the function signature class in the current library.
    library_.AddClass(signature_class);
  } else {
    // Forget the just created signature function and use the existing one.
    signature_function = signature_class.signature_function();
  }
  ASSERT(signature_function.signature_class() == signature_class.raw());

  // Lookup alias name and report an error if it is already defined in
  // the library scope.
  const Object& obj = Object::Handle(library_.LookupLocalObject(*alias_name));
  if (!obj.IsNull()) {
    ErrorMsg(alias_name_pos,
             "'%s' is already defined", alias_name->ToCString());
  }

  // Create the function type alias, but share the signature function of the
  // canonical signature class.
  Class& function_type_alias = Class::Handle(
      Class::NewSignatureClass(*alias_name,
                               signature_function,
                               script_));
  // This alias should not be marked as finalized yet, since it needs to be
  // checked in the class finalizer for illegal self references.
  ASSERT(!function_type_alias.IsCanonicalSignatureClass());
  ASSERT(!function_type_alias.is_finalized());
  library_.AddClass(function_type_alias);
  ExpectSemicolon();
  pending_classes.Add(function_type_alias, Heap::kOld);
}


void Parser::ParseInterfaceDefinition(
    const GrowableObjectArray& pending_classes) {
  TRACE_PARSER("ParseInterfaceDefinition");
  const intptr_t interface_pos = TokenPos();
  ExpectToken(Token::kINTERFACE);
  const intptr_t interfacename_pos = TokenPos();
  String& interface_name =
      *ExpectUserDefinedTypeIdentifier("interface name expected");
  if (FLAG_trace_parser) {
    OS::Print("TopLevel parsing interface '%s'\n", interface_name.ToCString());
  }
  Class& interface = Class::Handle();
  Object& obj = Object::Handle(library_.LookupLocalObject(interface_name));
  if (obj.IsNull()) {
    interface = Class::NewInterface(interface_name, script_, interfacename_pos);
    library_.AddClass(interface);
  } else {
    if (!obj.IsClass()) {
      ErrorMsg(interfacename_pos, "'%s' is already defined",
               interface_name.ToCString());
    }
    interface ^= obj.raw();
    if (!interface.is_interface()) {
      ErrorMsg(interfacename_pos,
               "'%s' is already defined as class",
               interface_name.ToCString());
    } else if (interface.functions() != Object::empty_array()) {
      ErrorMsg(interfacename_pos,
               "interface '%s' is already defined",
               interface_name.ToCString());
    }
  }
  ASSERT(!interface.IsNull());
  ASSERT(interface.functions() == Object::empty_array());
  set_current_class(interface);
  ParseTypeParameters(interface);

  if (CurrentToken() == Token::kEXTENDS) {
    Array& interfaces = Array::Handle();
    const intptr_t interfaces_pos = TokenPos();
    interfaces = ParseInterfaceList();
    AddInterfaces(interfaces_pos, interface, interfaces);
  }

  if (CurrentToken() == Token::kDEFAULT) {
    ConsumeToken();
    if (CurrentToken() != Token::kIDENT) {
      ErrorMsg("class name expected");
    }
    QualIdent factory_name;
    ParseQualIdent(&factory_name);
    LibraryPrefix& lib_prefix = LibraryPrefix::Handle();
    if (factory_name.lib_prefix != NULL) {
      lib_prefix = factory_name.lib_prefix->raw();
    }
    const UnresolvedClass& unresolved_factory_class = UnresolvedClass::Handle(
        UnresolvedClass::New(lib_prefix,
                             *factory_name.ident,
                             factory_name.ident_pos));
    const Class& factory_class = Class::Handle(
        Class::New(String::Handle(Symbols::New(":factory_signature")),
                   script_,
                   factory_name.ident_pos));
    factory_class.set_library(library_);
    factory_class.set_is_finalized();
    ParseTypeParameters(factory_class);
    unresolved_factory_class.set_factory_signature_class(factory_class);
    interface.set_factory_class(unresolved_factory_class);
    // If a type parameter list is included in the default factory clause (it
    // can be omitted), verify that it matches the list of type parameters of
    // the interface in number and names, but not necessarily in bounds.
    if (factory_class.NumTypeParameters() > 0) {
      const bool check_type_parameter_bounds = false;
      if (!AbstractTypeArguments::AreIdentical(
          AbstractTypeArguments::Handle(interface.type_parameters()),
          AbstractTypeArguments::Handle(factory_class.type_parameters()),
          check_type_parameter_bounds)) {
        const String& interface_name = String::Handle(interface.Name());
        ErrorMsg(factory_name.ident_pos,
                 "mismatch in number or names of type parameters between "
                 "interface '%s' and default factory class '%s'.\n",
                 interface_name.ToCString(),
                 factory_name.ident->ToCString());
      }
    }
  }

  ExpectToken(Token::kLBRACE);
  ClassDesc members(interface, interface_name, true, interface_pos);
  while (CurrentToken() != Token::kRBRACE) {
    ParseClassMemberDefinition(&members);
  }
  ExpectToken(Token::kRBRACE);

  if (members.has_constructor() && !interface.HasFactoryClass()) {
    ErrorMsg(interfacename_pos,
             "interface '%s' with constructor must declare a factory class",
             interface_name.ToCString());
  }

  Array& array = Array::Handle();
  array = Array::MakeArray(members.fields());
  interface.SetFields(array);

  // Creating a new array for functions marks the interface as parsed.
  array = Array::MakeArray(members.functions());
  interface.SetFunctions(array);
  ASSERT(interface.is_interface());

  pending_classes.Add(interface, Heap::kOld);
}


// Consumes exactly one right angle bracket. If the current token is a single
// bracket token, it is consumed normally. However, if it is a double or triple
// bracket, it is replaced by a single or double bracket token without
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


void Parser::SkipMetadata() {
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
}


void Parser::SkipTypeArguments() {
  if (CurrentToken() == Token::kLT) {
    do {
      ConsumeToken();
      SkipType(false);
    } while (CurrentToken() == Token::kCOMMA);
    Token::Kind token = CurrentToken();
    if ((token == Token::kGT) || (token == Token::kSHR)) {
      ConsumeRightAngleBracket();
    } else {
      ErrorMsg("right angle bracket expected");
    }
  }
}


void Parser::SkipType(bool allow_void) {
  if (CurrentToken() == Token::kVOID) {
    if (!allow_void) {
      ErrorMsg("'void' not allowed here");
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


void Parser::ParseTypeParameters(const Class& cls) {
  TRACE_PARSER("ParseTypeParameters");
  if (CurrentToken() == Token::kLT) {
    Isolate* isolate = Isolate::Current();
    const GrowableObjectArray& type_parameters_array =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    intptr_t index = 0;
    TypeParameter& type_parameter = TypeParameter::Handle();
    TypeParameter& existing_type_parameter = TypeParameter::Handle();
    String& existing_type_parameter_name = String::Handle();
    AbstractType& type_parameter_bound = Type::Handle();
    do {
      ConsumeToken();
      SkipMetadata();
      const intptr_t type_parameter_pos = TokenPos();
      String& type_parameter_name =
          *ExpectUserDefinedTypeIdentifier("type parameter expected");
      // Check for duplicate type parameters.
      for (intptr_t i = 0; i < index; i++) {
        existing_type_parameter ^= type_parameters_array.At(i);
        existing_type_parameter_name = existing_type_parameter.name();
        if (existing_type_parameter_name.Equals(type_parameter_name)) {
          ErrorMsg(type_parameter_pos, "duplicate type parameter '%s'",
                   type_parameter_name.ToCString());
        }
      }
      if (CurrentToken() == Token::kEXTENDS) {
        ConsumeToken();
        // A bound may refer to the owner of the type parameter it applies to,
        // i.e. to the class or interface currently being parsed.
        // Postpone resolution in order to avoid resolving the class and its
        // type parameters, as they are not fully parsed yet.
        type_parameter_bound = ParseType(ClassFinalizer::kDoNotResolve);
      } else {
        type_parameter_bound = isolate->object_store()->object_type();
      }
      type_parameter = TypeParameter::New(cls,
                                          index,
                                          type_parameter_name,
                                          type_parameter_bound,
                                          type_parameter_pos);
      type_parameters_array.Add(type_parameter);
      index++;
    } while (CurrentToken() == Token::kCOMMA);
    Token::Kind token = CurrentToken();
    if ((token == Token::kGT) || (token == Token::kSHR)) {
      ConsumeRightAngleBracket();
    } else {
      ErrorMsg("right angle bracket expected");
    }
    const TypeArguments& type_parameters =
        TypeArguments::Handle(NewTypeArguments(type_parameters_array));
    cls.set_type_parameters(type_parameters);
    // Try to resolve the upper bounds, which will at least resolve the
    // referenced type parameters.
    const intptr_t num_types = type_parameters.Length();
    for (intptr_t i = 0; i < num_types; i++) {
      type_parameter ^= type_parameters.TypeAt(i);
      type_parameter_bound = type_parameter.bound();
      ResolveTypeFromClass(cls,
                           ClassFinalizer::kTryResolve,
                           &type_parameter_bound);
      type_parameter.set_bound(type_parameter_bound);
    }
  }
}


RawAbstractTypeArguments* Parser::ParseTypeArguments(
    Error* malformed_error,
    ClassFinalizer::FinalizationKind finalization) {
  TRACE_PARSER("ParseTypeArguments");
  if (CurrentToken() == Token::kLT) {
    const GrowableObjectArray& types =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    AbstractType& type = AbstractType::Handle();
    do {
      ConsumeToken();
      type = ParseType(finalization);
      // Only keep the error for the first malformed type argument.
      if (malformed_error->IsNull() && type.IsMalformed()) {
        *malformed_error = type.malformed_error();
      }
      // Map a malformed type argument to dynamic, so that malformed types with
      // a resolved type class are handled properly in production mode.
      if (type.IsMalformed()) {
        ASSERT(finalization < ClassFinalizer::kCanonicalizeWellFormed);
        type = Type::DynamicType();
      }
      types.Add(type);
    } while (CurrentToken() == Token::kCOMMA);
    Token::Kind token = CurrentToken();
    if ((token == Token::kGT) || (token == Token::kSHR)) {
      ConsumeRightAngleBracket();
    } else {
      ErrorMsg("right angle bracket expected");
    }
    if (finalization != ClassFinalizer::kIgnore) {
      return NewTypeArguments(types);
    }
  }
  return TypeArguments::null();
}


// Parse and return an array of interface types.
RawArray* Parser::ParseInterfaceList() {
  TRACE_PARSER("ParseInterfaceList");
  ASSERT((CurrentToken() == Token::kIMPLEMENTS) ||
         (CurrentToken() == Token::kEXTENDS));
  const GrowableObjectArray& interfaces =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  String& interface_name = String::Handle();
  AbstractType& interface = AbstractType::Handle();
  String& other_name = String::Handle();
  AbstractType& other_interface = AbstractType::Handle();
  do {
    ConsumeToken();
    intptr_t interface_pos = TokenPos();
    interface = ParseType(ClassFinalizer::kTryResolve);
    interface_name = interface.UserVisibleName();
    for (int i = 0; i < interfaces.Length(); i++) {
      other_interface ^= interfaces.At(i);
      other_name = other_interface.UserVisibleName();
      if (interface_name.Equals(other_name)) {
        ErrorMsg(interface_pos, "duplicate interface '%s'",
                 interface_name.ToCString());
      }
    }
    interfaces.Add(interface);
  } while (CurrentToken() == Token::kCOMMA);
  return Array::MakeArray(interfaces);
}


// Add 'interface' to 'interface_list' if it is not already in the list.
// An error is reported if the interface conflicts with an interface already in
// the list with the same class, but different type arguments.
// Non-conflicting duplicates are ignored without error.
void Parser::AddInterfaceIfUnique(intptr_t interfaces_pos,
                                  const GrowableObjectArray& interface_list,
                                  const AbstractType& interface) {
  String& interface_class_name = String::Handle(interface.ClassName());
  String& existing_interface_class_name = String::Handle();
  String& interface_name = String::Handle();
  String& existing_interface_name = String::Handle();
  AbstractType& other_interface = AbstractType::Handle();
  for (intptr_t i = 0; i < interface_list.Length(); i++) {
    other_interface ^= interface_list.At(i);
    existing_interface_class_name = other_interface.ClassName();
    if (interface_class_name.Equals(existing_interface_class_name)) {
      // Same interface class name, now check names of type arguments.
      interface_name = interface.Name();
      existing_interface_name = other_interface.Name();
      // TODO(regis): Revisit depending on the outcome of issue 4905685.
      if (!interface_name.Equals(existing_interface_name)) {
        ErrorMsg(interfaces_pos,
                 "interface '%s' conflicts with interface '%s'",
                 String::Handle(interface.UserVisibleName()).ToCString(),
                 String::Handle(other_interface.UserVisibleName()).ToCString());
      }
    }
  }
  interface_list.Add(interface);
}


void Parser::AddInterfaces(intptr_t interfaces_pos,
                           const Class& cls,
                           const Array& interfaces) {
  const GrowableObjectArray& all_interfaces =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  AbstractType& interface = AbstractType::Handle();
  // First get all the interfaces already implemented by class.
  Array& cls_interfaces = Array::Handle(cls.interfaces());
  for (intptr_t i = 0; i < cls_interfaces.Length(); i++) {
    interface ^= cls_interfaces.At(i);
    all_interfaces.Add(interface);
  }
  // Now add the new interfaces.
  for (intptr_t i = 0; i < interfaces.Length(); i++) {
    AbstractType& interface = AbstractType::ZoneHandle();
    interface ^= interfaces.At(i);
    if (interface.IsTypeParameter()) {
      if (cls.is_interface()) {
        ErrorMsg(interfaces_pos,
                 "interface '%s' may not extend type parameter '%s'",
                 String::Handle(cls.Name()).ToCString(),
                 String::Handle(interface.UserVisibleName()).ToCString());
      } else {
        ErrorMsg(interfaces_pos,
                 "class '%s' may not implement type parameter '%s'",
                 String::Handle(cls.Name()).ToCString(),
                 String::Handle(interface.UserVisibleName()).ToCString());
      }
    }
    AddInterfaceIfUnique(interfaces_pos, all_interfaces, interface);
  }
  cls_interfaces = Array::MakeArray(all_interfaces);
  cls.set_interfaces(cls_interfaces);
}


void Parser::ParseTopLevelVariable(TopLevel* top_level) {
  TRACE_PARSER("ParseTopLevelVariable");
  const bool is_const = (CurrentToken() == Token::kCONST);
  // Const fields are implicitly final.
  const bool is_final = is_const || (CurrentToken() == Token::kFINAL);
  const bool is_static = true;
  const AbstractType& type =
      AbstractType::ZoneHandle(ParseConstFinalVarOrType(
          FLAG_enable_type_checks ? ClassFinalizer::kTryResolve :
                                    ClassFinalizer::kIgnore));
  Field& field = Field::Handle();
  Function& getter = Function::Handle();
  while (true) {
    const intptr_t name_pos = TokenPos();
    String& var_name = *ExpectIdentifier("variable name expected");

    if (library_.LookupLocalObject(var_name) != Object::null()) {
      ErrorMsg(name_pos, "'%s' is already defined", var_name.ToCString());
    }
    String& accessor_name = String::Handle(Field::GetterName(var_name));
    if (library_.LookupLocalObject(accessor_name) != Object::null()) {
      ErrorMsg(name_pos, "getter for '%s' is already defined",
               var_name.ToCString());
    }
    // A const or final variable does not define an implicit setter,
    // so we only check setters for non-final variables.
    if (!is_final) {
      accessor_name = Field::SetterName(var_name);
      if (library_.LookupLocalObject(accessor_name) != Object::null()) {
        ErrorMsg(name_pos, "setter for '%s' is already defined",
                 var_name.ToCString());
      }
    }

    field = Field::New(var_name, is_static, is_final, is_const,
                       current_class(), name_pos);
    field.set_type(type);
    field.set_value(Instance::Handle(Instance::null()));
    top_level->fields.Add(field);
    library_.AddObject(field, var_name);
    if (CurrentToken() == Token::kASSIGN) {
      ConsumeToken();
      Instance& field_value = Instance::Handle(Object::sentinel());
      bool has_simple_literal = false;
      if (is_final && (LookaheadToken(1) == Token::kSEMICOLON)) {
        has_simple_literal = IsSimpleLiteral(type, &field_value);
      }
      SkipExpr();
      field.set_value(field_value);
      if (!has_simple_literal) {
        // Create a static const getter.
        String& getter_name = String::ZoneHandle(Field::GetterSymbol(var_name));
        getter = Function::New(getter_name,
                               RawFunction::kConstImplicitGetter,
                               is_static,
                               is_const,
                               /* is_abstract = */ false,
                               /* is_external = */ false,
                               current_class(),
                               name_pos);
        getter.set_result_type(type);
        top_level->functions.Add(getter);
      }
    } else if (is_final) {
      ErrorMsg(name_pos, "missing initializer for final or const variable");
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


void Parser::ParseTopLevelFunction(TopLevel* top_level) {
  TRACE_PARSER("ParseTopLevelFunction");
  AbstractType& result_type = Type::Handle(Type::DynamicType());
  const bool is_static = true;
  bool is_external = false;
  bool is_patch = false;
  if (is_patch_source() &&
      (CurrentToken() == Token::kIDENT) &&
      CurrentLiteral()->Equals("patch") &&
      (LookaheadToken(1) != Token::kLPAREN)) {
    ConsumeToken();
    is_patch = true;
  } else if (CurrentToken() == Token::kEXTERNAL) {
    ConsumeToken();
    is_external = true;
  }
  if (CurrentToken() == Token::kVOID) {
    ConsumeToken();
    result_type = Type::VoidType();
  } else {
    // Parse optional type.
    if ((CurrentToken() == Token::kIDENT) &&
        (LookaheadToken(1) != Token::kLPAREN)) {
      result_type = ParseType(ClassFinalizer::kTryResolve);
    }
  }
  const intptr_t name_pos = TokenPos();
  const String& func_name = *ExpectIdentifier("function name expected");

  bool found = library_.LookupLocalObject(func_name) != Object::null();
  if (found && !is_patch) {
    ErrorMsg(name_pos, "'%s' is already defined", func_name.ToCString());
  } else if (!found && is_patch) {
    ErrorMsg(name_pos, "missing '%s' cannot be patched", func_name.ToCString());
  }
  String& accessor_name = String::Handle(Field::GetterName(func_name));
  if (library_.LookupLocalObject(accessor_name) != Object::null()) {
    ErrorMsg(name_pos, "'%s' is already defined as getter",
             func_name.ToCString());
  }
  // A setter named x= may co-exist with a function named x, thus we do
  // not need to check setters.

  if (CurrentToken() != Token::kLPAREN) {
    ErrorMsg("'(' expected");
  }
  const intptr_t function_pos = TokenPos();
  ParamList params;
  const bool allow_explicit_default_values = true;
  ParseFormalParameterList(allow_explicit_default_values, &params);

  intptr_t function_end_pos = function_pos;
  if (is_external) {
    ExpectSemicolon();
  } else if (CurrentToken() == Token::kLBRACE) {
    SkipBlock();
    function_end_pos = TokenPos();
  } else if (CurrentToken() == Token::kARROW) {
    ConsumeToken();
    SkipExpr();
    ExpectSemicolon();
    function_end_pos = TokenPos();
  } else if (IsLiteral("native")) {
    ParseNativeDeclaration();
  } else {
    ErrorMsg("function block expected");
  }
  Function& func = Function::Handle(
      Function::New(func_name,
                    RawFunction::kRegularFunction,
                    is_static,
                    /* is_const = */ false,
                    /* is_abstract = */ false,
                    is_external,
                    current_class(),
                    function_pos));
  func.set_result_type(result_type);
  func.set_end_token_pos(function_end_pos);
  AddFormalParamsToFunction(&params, func);
  top_level->functions.Add(func);
  if (!is_patch) {
    library_.AddObject(func, func_name);
  } else {
    library_.ReplaceObject(func, func_name);
  }
}


void Parser::ParseTopLevelAccessor(TopLevel* top_level) {
  TRACE_PARSER("ParseTopLevelAccessor");
  const bool is_static = true;
  bool is_external = false;
  bool is_patch = false;
  AbstractType& result_type = AbstractType::Handle();
  if (is_patch_source() &&
      (CurrentToken() == Token::kIDENT) &&
      CurrentLiteral()->Equals("patch")) {
    ConsumeToken();
    is_patch = true;
  } else if (CurrentToken() == Token::kEXTERNAL) {
    ConsumeToken();
    is_external = true;
  }
  bool is_getter = (CurrentToken() == Token::kGET);
  if (CurrentToken() == Token::kGET ||
      CurrentToken() == Token::kSET) {
    ConsumeToken();
    result_type = Type::DynamicType();
  } else {
    if (CurrentToken() == Token::kVOID) {
      ConsumeToken();
      result_type = Type::VoidType();
    } else {
      result_type = ParseType(ClassFinalizer::kTryResolve);
    }
    is_getter = (CurrentToken() == Token::kGET);
    if (CurrentToken() == Token::kGET || CurrentToken() == Token::kSET) {
      ConsumeToken();
    } else {
      UnexpectedToken();
    }
  }
  const intptr_t name_pos = TokenPos();
  const String* field_name = ExpectIdentifier("accessor name expected");

  const intptr_t accessor_pos = TokenPos();
  ParamList params;
  if (FLAG_warn_legacy_getters &&
      is_getter && (CurrentToken() == Token::kLPAREN)) {
    Warning("legacy getter syntax, remove parenthesis");
  }
  // TODO(hausner): Remove the kLPAREN check once we remove old getter syntax.
  if (!is_getter || (CurrentToken() == Token::kLPAREN)) {
    const bool allow_explicit_default_values = true;
    ParseFormalParameterList(allow_explicit_default_values, &params);
  }
  String& accessor_name = String::ZoneHandle();
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
    ErrorMsg(name_pos, "illegal %s parameters",
             is_getter ? "getter" : "setter");
  }

  if (is_getter && library_.LookupLocalObject(*field_name) != Object::null()) {
    ErrorMsg(name_pos, "'%s' is already defined in this library",
             field_name->ToCString());
  }
  if (!is_getter) {
    // Check whether there is a field with the same name that has an implicit
    // setter.
    const Field& field = Field::Handle(library_.LookupLocalField(*field_name));
    if (!field.IsNull() && !field.is_final()) {
      ErrorMsg(name_pos, "Variable '%s' is already defined in this library",
               field_name->ToCString());
    }
  }
  bool found = library_.LookupLocalObject(accessor_name) != Object::null();
  if (found && !is_patch) {
    ErrorMsg(name_pos, "%s for '%s' is already defined",
             is_getter ? "getter" : "setter",
             field_name->ToCString());
  } else if (!found && is_patch) {
    ErrorMsg(name_pos, "missing %s for '%s' cannot be patched",
             is_getter ? "getter" : "setter",
             field_name->ToCString());
  }

  if (is_external) {
    ExpectSemicolon();
  } else if (CurrentToken() == Token::kLBRACE) {
    SkipBlock();
  } else if (CurrentToken() == Token::kARROW) {
    ConsumeToken();
    SkipExpr();
    ExpectSemicolon();
  } else if (IsLiteral("native")) {
    ParseNativeDeclaration();
  } else {
    ErrorMsg("function block expected");
  }
  Function& func = Function::Handle(
      Function::New(accessor_name,
                    is_getter? RawFunction::kGetterFunction :
                               RawFunction::kSetterFunction,
                    is_static,
                    /* is_const = */ false,
                    /* is_abstract = */ false,
                    is_external,
                    current_class(),
                    accessor_pos));
  func.set_result_type(result_type);
  AddFormalParamsToFunction(&params, func);
  top_level->functions.Add(func);
  if (!is_patch) {
    library_.AddObject(func, accessor_name);
  } else {
    library_.ReplaceObject(func, accessor_name);
  }
}


// TODO(hausner): Remove support for old library definition syntax.
void Parser::ParseLibraryNameObsoleteSyntax() {
  if ((script_.kind() == RawScript::kLibraryTag) &&
      (CurrentToken() != Token::kLEGACY_LIBRARY)) {
    // Handle error case early to get consistent error message.
    ExpectToken(Token::kLEGACY_LIBRARY);
  }
  if (CurrentToken() == Token::kLEGACY_LIBRARY) {
    ConsumeToken();
    ExpectToken(Token::kLPAREN);
    if (CurrentToken() != Token::kSTRING) {
      ErrorMsg("library name expected");
    }
    const String& name = *CurrentLiteral();
    ConsumeToken();
    ExpectToken(Token::kRPAREN);
    ExpectToken(Token::kSEMICOLON);
    library_.SetName(name);
  }
}


Dart_Handle Parser::CallLibraryTagHandler(Dart_LibraryTag tag,
                                          intptr_t token_pos,
                                          const String& url) {
  Isolate* isolate = Isolate::Current();
  Dart_LibraryTagHandler handler = isolate->library_tag_handler();
  if (handler == NULL) {
    ErrorMsg(token_pos, "no library handler registered");
  }
  Dart_Handle result = handler(tag,
                               Api::NewHandle(isolate, library_.raw()),
                               Api::NewHandle(isolate, url.raw()));
  if (Dart_IsError(result)) {
    Error& prev_error = Error::Handle();
    prev_error ^= Api::UnwrapHandle(result);
    AppendErrorMsg(prev_error, token_pos, "library handler failed");
  }
  return result;
}


// TODO(hausner): Remove support for old library definition syntax.
void Parser::ParseLibraryImportObsoleteSyntax() {
  while (CurrentToken() == Token::kLEGACY_IMPORT) {
    const intptr_t import_pos = TokenPos();
    ConsumeToken();
    ExpectToken(Token::kLPAREN);
    if (CurrentToken() != Token::kSTRING) {
      ErrorMsg("library url expected");
    }
    const String& url = *CurrentLiteral();
    ConsumeToken();
    String& prefix = String::Handle();
    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
      if (!IsLiteral("prefix")) {
        ErrorMsg("prefix: expected");
      }
      ConsumeToken();
      ExpectToken(Token::kCOLON);
      if (CurrentToken() != Token::kSTRING) {
        ErrorMsg("prefix expected");
      }
      prefix = CurrentLiteral()->raw();
      // TODO(asiva): Need to also check that prefix is not a reserved keyword.
      if (!Scanner::IsIdent(prefix)) {
        ErrorMsg("prefix should be an identifier");
      }
      ConsumeToken();
    }
    ExpectToken(Token::kRPAREN);
    ExpectToken(Token::kSEMICOLON);
    Dart_Handle handle = CallLibraryTagHandler(kCanonicalizeUrl,
                                               import_pos,
                                               url);
    const String& canon_url = String::CheckedHandle(Api::UnwrapHandle(handle));
    // Lookup the library URL.
    Library& library = Library::Handle(Library::LookupLibrary(canon_url));
    if (library.IsNull()) {
      // Call the library tag handler to load the library.
      CallLibraryTagHandler(kImportTag, import_pos, canon_url);
      // If the library tag handler succeded without registering the
      // library we create an empty library to import.
      library = Library::LookupLibrary(canon_url);
      if (library.IsNull()) {
        library = Library::New(canon_url);
        library.Register();
      }
    }
    // Add the import to the library.
    const Namespace& import = Namespace::Handle(
        Namespace::New(library, Array::Handle(), Array::Handle()));
    if (prefix.IsNull() || (prefix.Length() == 0)) {
      library_.AddImport(import);
    } else {
      LibraryPrefix& library_prefix = LibraryPrefix::Handle();
      library_prefix = library_.LookupLocalLibraryPrefix(prefix);
      if (!library_prefix.IsNull()) {
        library_prefix.AddImport(import);
      } else {
        library_prefix = LibraryPrefix::New(prefix, import);
        library_.AddObject(library_prefix, prefix);
      }
    }
  }
}


// TODO(hausner): Remove support for old library definition syntax.
void Parser::ParseLibraryIncludeObsoleteSyntax() {
  while (CurrentToken() == Token::kLEGACY_SOURCE) {
    const intptr_t source_pos = TokenPos();
    ConsumeToken();
    ExpectToken(Token::kLPAREN);
    if (CurrentToken() != Token::kSTRING) {
      ErrorMsg("source url expected");
    }
    const String& url = *CurrentLiteral();
    ConsumeToken();
    ExpectToken(Token::kRPAREN);
    ExpectToken(Token::kSEMICOLON);
    Dart_Handle handle = CallLibraryTagHandler(kCanonicalizeUrl,
                                               source_pos,
                                               url);
    const String& canon_url = String::CheckedHandle(Api::UnwrapHandle(handle));
    CallLibraryTagHandler(kSourceTag, source_pos, canon_url);
  }
}


void Parser::ParseLibraryName() {
  ASSERT(CurrentToken() == Token::kLIBRARY);
  ConsumeToken();
  // TODO(hausner): Exact syntax of library name still unclear: identifier,
  // qualified identifier or even multiple dots allowed? For now we just
  // accept simple identifiers.
  const String& lib_name = *ExpectIdentifier("library name expected");
  library_.SetName(lib_name);
  ExpectSemicolon();
}


void Parser::ParseIdentList(GrowableObjectArray* names) {
  if (!IsIdentifier()) {
    ErrorMsg("identifier expected");
  }
  while (IsIdentifier()) {
    names->Add(*CurrentLiteral());
    ConsumeToken();  // Identifier.
    if (CurrentToken() != Token::kCOMMA) {
      return;
    }
    ConsumeToken();  // Comma.
  }
}


void Parser::ParseLibraryImportExport() {
  bool is_import = (CurrentToken() == Token::kIMPORT);
  bool is_export = (CurrentToken() == Token::kEXPORT);
  ASSERT(is_import || is_export);
  const intptr_t import_pos = TokenPos();
  ConsumeToken();
  if (CurrentToken() != Token::kSTRING) {
    ErrorMsg("library url expected");
  }
  const String& url = *CurrentLiteral();
  if (url.Length() == 0) {
    ErrorMsg("library url expected");
  }
  ConsumeToken();
  String& prefix = String::Handle();
  if (is_import && IsLiteral("as")) {
    ConsumeToken();
    prefix = ExpectIdentifier("prefix expected")->raw();
  }

  Array& show_names = Array::Handle();
  Array& hide_names = Array::Handle();
  if (IsLiteral("show") || IsLiteral("hide")) {
    GrowableObjectArray& show_list =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    GrowableObjectArray& hide_list =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    for (;;) {
      if (IsLiteral("show")) {
        ConsumeToken();
        ParseIdentList(&show_list);
      } else if (IsLiteral("hide")) {
        ConsumeToken();
        ParseIdentList(&hide_list);
      } else {
        break;
      }
    }
    if (show_list.Length() > 0) {
      show_names = Array::MakeArray(show_list);
    }
    if (hide_list.Length() > 0) {
      hide_names = Array::MakeArray(hide_list);
    }
  }
  ExpectSemicolon();

  // Canonicalize library URL.
  Dart_Handle handle =
      CallLibraryTagHandler(kCanonicalizeUrl, import_pos, url);
  const String& canon_url = String::CheckedHandle(Api::UnwrapHandle(handle));
  // Lookup the library URL.
  Library& library = Library::Handle(Library::LookupLibrary(canon_url));
  if (library.IsNull()) {
    // Call the library tag handler to load the library.
    CallLibraryTagHandler(kImportTag, import_pos, canon_url);
    // If the library tag handler succeded without registering the
    // library we create an empty library to import.
    library = Library::LookupLibrary(canon_url);
    if (library.IsNull()) {
      library = Library::New(canon_url);
      library.Register();
    }
  }
  const Namespace& ns =
    Namespace::Handle(Namespace::New(library, show_names, hide_names));
  if (is_import) {
    if (prefix.IsNull() || (prefix.Length() == 0)) {
      library_.AddImport(ns);
    } else {
      LibraryPrefix& library_prefix = LibraryPrefix::Handle();
      library_prefix = library_.LookupLocalLibraryPrefix(prefix);
      if (!library_prefix.IsNull()) {
        library_prefix.AddImport(ns);
      } else {
        library_prefix = LibraryPrefix::New(prefix, ns);
        library_.AddObject(library_prefix, prefix);
      }
    }
  } else {
    ASSERT(is_export);
    library_.AddExport(ns);
  }
}


void Parser::ParseLibraryPart() {
  const intptr_t source_pos = TokenPos();
  ConsumeToken();  // Consume "part".
  if (CurrentToken() != Token::kSTRING) {
    ErrorMsg("url expected");
  }
  const String& url = *CurrentLiteral();
  ConsumeToken();
  ExpectSemicolon();
  Dart_Handle handle =
      CallLibraryTagHandler(kCanonicalizeUrl, source_pos, url);
  const String& canon_url = String::CheckedHandle(Api::UnwrapHandle(handle));
  CallLibraryTagHandler(kSourceTag, source_pos, canon_url);
}


void Parser::ParseLibraryDefinition() {
  TRACE_PARSER("ParseLibraryDefinition");

  // Handle the script tag.
  if (CurrentToken() == Token::kSCRIPTTAG) {
    // Nothing to do for script tags except to skip them.
    ConsumeToken();
  }

  // TODO(hausner): Remove support for old library definition syntax.
  if ((CurrentToken() == Token::kLEGACY_LIBRARY) ||
      (CurrentToken() == Token::kLEGACY_IMPORT) ||
      (CurrentToken() == Token::kLEGACY_SOURCE)) {
    ParseLibraryNameObsoleteSyntax();
    ParseLibraryImportObsoleteSyntax();
    ParseLibraryIncludeObsoleteSyntax();
    // Core lib has not been explicitly imported, so we implicitly
    // import it here.
    if (!library_.ImportsCorelib()) {
      Library& core_lib = Library::Handle(Library::CoreLibrary());
      ASSERT(!core_lib.IsNull());
      const Namespace& core_ns = Namespace::Handle(
          Namespace::New(core_lib, Array::Handle(), Array::Handle()));
      library_.AddImport(core_ns);
    }
    return;
  }

  const bool is_script = (script_.kind() == RawScript::kScriptTag);
  const bool is_library = (script_.kind() == RawScript::kLibraryTag);
  ASSERT(script_.kind() != RawScript::kSourceTag);

  // We may read metadata tokens that are part of the toplevel
  // declaration that follows the library definitions. Therefore, we
  // need to remember the position of the last token that was
  // successfully consumed.
  intptr_t metadata_pos = TokenPos();
  SkipMetadata();
  if (CurrentToken() == Token::kLIBRARY) {
    ParseLibraryName();
    metadata_pos = TokenPos();
    SkipMetadata();
  } else if (is_library) {
    ErrorMsg("library name definition expected");
  }
  while ((CurrentToken() == Token::kIMPORT) ||
      (CurrentToken() == Token::kEXPORT)) {
    if (is_script && (CurrentToken() == Token::kEXPORT)) {
      ErrorMsg("export not allowed in scripts");
    }
    ParseLibraryImportExport();
    metadata_pos = TokenPos();
    SkipMetadata();
  }
  // Core lib has not been explicitly imported, so we implicitly
  // import it here.
  if (!library_.ImportsCorelib()) {
    Library& core_lib = Library::Handle(Library::CoreLibrary());
    ASSERT(!core_lib.IsNull());
    const Namespace& core_ns = Namespace::Handle(
        Namespace::New(core_lib, Array::Handle(), Array::Handle()));
    library_.AddImport(core_ns);
  }
  while (CurrentToken() == Token::kPART) {
    ParseLibraryPart();
    metadata_pos = TokenPos();
    SkipMetadata();
  }
  SetPosition(metadata_pos);
}


void Parser::ParsePartHeader() {
  intptr_t metadata_pos = TokenPos();
  SkipMetadata();
  // TODO(hausner): Once support for old #source directive is removed
  // from the compiler, add an error message here if we don't find
  // a 'part of' directive.
  if (CurrentToken() == Token::kPART) {
    ConsumeToken();
    if (!IsLiteral("of")) {
      ErrorMsg("'part of' expected");
    }
    ConsumeToken();
    // TODO(hausner): Exact syntax of library name still unclear: identifier,
    // qualified identifier or even multiple dots allowed? For now we just
    // accept simple identifiers.
    // The VM is not required to check that the library name matches the
    // name of the current library, so we ignore it.
    ExpectIdentifier("library name expected");
    ExpectSemicolon();
  } else {
    SetPosition(metadata_pos);
  }
}


void Parser::ParseTopLevel() {
  TRACE_PARSER("ParseTopLevel");
  // Collect the classes found at the top level in this growable array.
  // They need to be registered with class finalization after parsing
  // has been completed.
  Isolate* isolate = Isolate::Current();
  ObjectStore* object_store = isolate->object_store();
  const GrowableObjectArray& pending_classes =
      GrowableObjectArray::Handle(isolate, object_store->pending_classes());
  SetPosition(0);
  is_top_level_ = true;
  TopLevel top_level;
  Class& toplevel_class = Class::Handle(
      Class::New(String::Handle(Symbols::TopLevel()), script_, TokenPos()));
  toplevel_class.set_library(library_);

  if (is_library_source()) {
    ParseLibraryDefinition();
  } else if (is_part_source()) {
    ParsePartHeader();
  }

  while (true) {
    set_current_class(Class::Handle());  // No current class.
    SkipMetadata();
    if (CurrentToken() == Token::kCLASS) {
      ParseClassDefinition(pending_classes);
    } else if ((CurrentToken() == Token::kTYPEDEF) &&
               (LookaheadToken(1) != Token::kLPAREN)) {
      ParseFunctionTypeAlias(pending_classes);
    } else if (CurrentToken() == Token::kINTERFACE) {
      ParseInterfaceDefinition(pending_classes);
    } else if ((CurrentToken() == Token::kABSTRACT) &&
        (LookaheadToken(1) == Token::kCLASS)) {
      ParseClassDefinition(pending_classes);
    } else if (is_patch_source() && IsLiteral("patch") &&
               (LookaheadToken(1) == Token::kCLASS)) {
      ParseClassDefinition(pending_classes);
    } else {
      set_current_class(toplevel_class);
      if (IsVariableDeclaration()) {
        ParseTopLevelVariable(&top_level);
      } else if (IsFunctionDeclaration()) {
        ParseTopLevelFunction(&top_level);
      } else if (IsTopLevelAccessor()) {
        ParseTopLevelAccessor(&top_level);
      } else if (CurrentToken() == Token::kEOS) {
        break;
      } else {
        UnexpectedToken();
      }
    }
  }
  if ((top_level.fields.Length() > 0) || (top_level.functions.Length() > 0)) {
    Array& array = Array::Handle();

    array = Array::MakeArray(top_level.fields);
    toplevel_class.SetFields(array);

    array = Array::MakeArray(top_level.functions);
    toplevel_class.SetFunctions(array);

    library_.AddAnonymousClass(toplevel_class);
    pending_classes.Add(toplevel_class, Heap::kOld);
  }
}


void Parser::ChainNewBlock(LocalScope* outer_scope) {
  Block* block = new Block(current_block_,
                           outer_scope,
                           new SequenceNode(TokenPos(), outer_scope));
  current_block_ = block;
}


void Parser::OpenBlock() {
  ASSERT(current_block_ != NULL);
  LocalScope* outer_scope = current_block_->scope;
  ChainNewBlock(new LocalScope(outer_scope,
                               outer_scope->function_level(),
                               outer_scope->loop_level()));
}


void Parser::OpenLoopBlock() {
  ASSERT(current_block_ != NULL);
  LocalScope* outer_scope = current_block_->scope;
  ChainNewBlock(new LocalScope(outer_scope,
                               outer_scope->function_level(),
                               outer_scope->loop_level() + 1));
}


void Parser::OpenFunctionBlock(const Function& func) {
  LocalScope* outer_scope;
  if (current_block_ == NULL) {
    if (!func.IsLocalFunction()) {
      // We are compiling a non-nested function.
      outer_scope = new LocalScope(NULL, 0, 0);
    } else {
      // We are compiling the function of an invoked closure.
      // Restore the outer scope containing all captured variables.
      const ContextScope& context_scope =
          ContextScope::Handle(func.context_scope());
      ASSERT(!context_scope.IsNull());
      outer_scope =
          new LocalScope(LocalScope::RestoreOuterScope(context_scope), 0, 0);
    }
  } else {
    // We are parsing a nested function while compiling the enclosing function.
    outer_scope = new LocalScope(current_block_->scope,
                                 current_block_->scope->function_level() + 1,
                                 0);
  }
  ChainNewBlock(outer_scope);
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


// Set up default values for all optional parameters to the function.
void Parser::SetupDefaultsForOptionalParams(const ParamList* params,
                                            Array& default_values) {
  if (params->num_optional_parameters > 0) {
    // Build array of default parameter values.
    ParamDesc* param =
      params->parameters->data() + params->num_fixed_parameters;
    default_values = Array::New(params->num_optional_parameters);
    for (int i = 0; i < params->num_optional_parameters; i++) {
      ASSERT(param->default_value != NULL);
      default_values.SetAt(i, *param->default_value);
      param++;
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
    ErrorMsg("too many formal parameters");
  }
  func.set_num_fixed_parameters(params->num_fixed_parameters);
  func.SetNumOptionalParameters(params->num_optional_parameters,
                                params->has_optional_positional_parameters);
  const int num_parameters = params->parameters->length();
  ASSERT(num_parameters == func.NumParameters());
  func.set_parameter_types(Array::Handle(Array::New(num_parameters,
                                                    Heap::kOld)));
  func.set_parameter_names(Array::Handle(Array::New(num_parameters,
                                                    Heap::kOld)));
  for (int i = 0; i < num_parameters; i++) {
    ParamDesc& param_desc = (*params->parameters)[i];
    ASSERT(is_top_level_ || param_desc.type->IsResolved());
    func.SetParameterTypeAt(i, *param_desc.type);
    func.SetParameterNameAt(i, *param_desc.name);
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
    ASSERT(!is_top_level_ || param_desc.type->IsResolved());
    const String* name = param_desc.name;
    LocalVariable* parameter = new LocalVariable(
        param_desc.name_pos, *name, *param_desc.type);
    if (!scope->AddVariable(parameter)) {
      ErrorMsg(param_desc.name_pos,
               "name '%s' already exists in scope",
               param_desc.name->ToCString());
    }
    if (param_desc.is_final) {
      parameter->set_is_final();
    }
  }
}


// Builds ReturnNode/NativeBodyNode for a native function.
void Parser::ParseNativeFunctionBlock(const ParamList* params,
                                      const Function& func) {
  func.set_is_native(true);
  TRACE_PARSER("ParseNativeFunctionBlock");
  const Class& cls = Class::Handle(func.Owner());
  ASSERT(func.NumParameters() == params->parameters->length());

  // Parse the function name out.
  const intptr_t native_pos = TokenPos();
  const String& native_name = ParseNativeDeclaration();

  // Now resolve the native function to the corresponding native entrypoint.
  const int num_params = NativeArguments::ParameterCountForResolution(func);
  NativeFunction native_function = NativeEntry::ResolveNative(
      cls, native_name, num_params);
  if (native_function == NULL) {
    ErrorMsg(native_pos, "native function '%s' cannot be found",
        native_name.ToCString());
  }

  // Now add the NativeBodyNode and return statement.
  current_block_->statements->Add(
      new ReturnNode(TokenPos(),
                     new NativeBodyNode(TokenPos(),
                                        Function::ZoneHandle(func.raw()),
                                        native_name,
                                        native_function)));
}


LocalVariable* Parser::LookupReceiver(LocalScope* from_scope, bool test_only) {
  ASSERT(!current_function().is_static());
  const String& this_name = String::Handle(Symbols::This());
  return from_scope->LookupVariable(this_name, test_only);
}


LocalVariable* Parser::LookupTypeArgumentsParameter(LocalScope* from_scope,
                                                    bool test_only) {
  ASSERT(current_function().IsInFactoryScope());
  const String& param_name = String::Handle(Symbols::TypeArgumentsParameter());
  return from_scope->LookupVariable(param_name, test_only);
}
LocalVariable* Parser::LookupPhaseParameter() {
  const String& phase_name =
      String::Handle(Symbols::PhaseParameter());
  const bool kTestOnly = false;
  return current_block_->scope->LookupVariable(phase_name, kTestOnly);
}


void Parser::CaptureInstantiator() {
  ASSERT(current_block_->scope->function_level() > 0);
  const bool kTestOnly = false;
  // Side effect of lookup captures the instantiator variable.
  LocalVariable* instantiator = NULL;
  if (current_function().IsInFactoryScope()) {
    instantiator = LookupTypeArgumentsParameter(current_block_->scope,
                                                kTestOnly);
  } else {
    instantiator = LookupReceiver(current_block_->scope, kTestOnly);
  }
  ASSERT(instantiator != NULL);
}


AstNode* Parser::LoadReceiver(intptr_t token_pos) {
  // A nested function may access 'this', referring to the receiver of the
  // outermost enclosing function.
  const bool kTestOnly = false;
  LocalVariable* receiver = LookupReceiver(current_block_->scope, kTestOnly);
  if (receiver == NULL) {
    ErrorMsg(token_pos, "illegal implicit access to receiver 'this'");
  }
  return new LoadLocalNode(TokenPos(), receiver);
}


AstNode* Parser::LoadTypeArgumentsParameter(intptr_t token_pos) {
  // A nested function may access ':type_arguments' to use as instantiator,
  // referring to the implicit first parameter of the outermost enclosing
  // factory function.
  const bool kTestOnly = false;
  LocalVariable* param = LookupTypeArgumentsParameter(current_block_->scope,
                                                      kTestOnly);
  ASSERT(param != NULL);
  return new LoadLocalNode(TokenPos(), param);
}


AstNode* Parser::CallGetter(intptr_t token_pos,
                            AstNode* object,
                            const String& name) {
  return new InstanceGetterNode(token_pos, object, name);
}


// Returns ast nodes of the variable initialization.
AstNode* Parser::ParseVariableDeclaration(const AbstractType& type,
                                          bool is_final,
                                          bool is_const) {
  TRACE_PARSER("ParseVariableDeclaration");
  ASSERT(IsIdentifier());
  const intptr_t ident_pos = TokenPos();
  LocalVariable* variable =
      new LocalVariable(ident_pos, *CurrentLiteral(), type);
  ASSERT(current_block_ != NULL);
  ASSERT(current_block_->scope != NULL);
  ConsumeToken();  // Variable identifier.
  AstNode* initialization = NULL;
  if (CurrentToken() == Token::kASSIGN) {
    // Variable initialization.
    const intptr_t assign_pos = TokenPos();
    ConsumeToken();
    AstNode* expr = ParseExpr(is_const, kConsumeCascades);
    initialization = new StoreLocalNode(assign_pos, variable, expr);
    if (is_const) {
      ASSERT(expr->IsLiteralNode());
      variable->SetConstValue(expr->AsLiteralNode()->literal());
    }
  } else if (is_final || is_const) {
    ErrorMsg(ident_pos,
    "missing initialization of 'final' or 'const' variable");
  } else {
    // Initialize variable with null.
    AstNode* null_expr = new LiteralNode(ident_pos, Instance::ZoneHandle());
    initialization = new StoreLocalNode(ident_pos, variable, null_expr);
  }
  // Add variable to scope after parsing the initalizer expression.
  // The expression must not be able to refer to the variable.
  if (!current_block_->scope->AddVariable(variable)) {
    ErrorMsg(ident_pos, "identifier '%s' already defined",
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
  if (CurrentToken() != Token::kIDENT) {
    if (type_is_optional) {
      return Type::DynamicType();
    } else {
      ErrorMsg("type name expected");
    }
  }
  if (type_is_optional) {
    Token::Kind follower = LookaheadToken(1);
    // We have an identifier followed by a 'follower' token.
    // We either parse a type or return now.
    if ((follower != Token::kLT) &&  // Parameterized type.
        (follower != Token::kPERIOD) &&  // Qualified class name of type.
        !Token::IsIdentifier(follower) &&  // Variable name following a type.
        (follower != Token::kTHIS)) {  // Field parameter following a type.
      return Type::DynamicType();
    }
  }
  return ParseType(finalization);
}


// Returns ast nodes of the variable initialization. Variables without an
// explicit initializer are initialized to null. If several variables are
// declared, the individual initializers are collected in a sequence node.
AstNode* Parser::ParseVariableDeclarationList() {
  TRACE_PARSER("ParseVariableDeclarationList");
  SkipMetadata();
  bool is_final = (CurrentToken() == Token::kFINAL);
  bool is_const = (CurrentToken() == Token::kCONST);
  const AbstractType& type = AbstractType::ZoneHandle(ParseConstFinalVarOrType(
      FLAG_enable_type_checks ? ClassFinalizer::kCanonicalize :
                                ClassFinalizer::kIgnore));
  if (!IsIdentifier()) {
    ErrorMsg("identifier expected");
  }

  AstNode* initializers = ParseVariableDeclaration(type, is_final, is_const);
  ASSERT(initializers != NULL);
  while (CurrentToken() == Token::kCOMMA) {
    ConsumeToken();
    if (!IsIdentifier()) {
      ErrorMsg("identifier expected after comma");
    }
    // We have a second initializer. Allocate a sequence node now.
    // The sequence does not own the current scope. Set its own scope to NULL.
    SequenceNode* sequence = NodeAsSequenceNode(initializers->token_pos(),
                                                initializers,
                                                NULL);
    sequence->Add(ParseVariableDeclaration(type, is_final, is_const));
    initializers = sequence;
  }
  return initializers;
}


AstNode* Parser::ParseFunctionStatement(bool is_literal) {
  TRACE_PARSER("ParseFunctionStatement");
  AbstractType& result_type = AbstractType::Handle();
  const String* variable_name = NULL;
  const String* function_name = NULL;

  result_type = Type::DynamicType();

  intptr_t ident_pos = TokenPos();
  if (FLAG_strict_function_literals) {
    if (is_literal) {
      ASSERT(CurrentToken() == Token::kLPAREN);
      function_name = &String::ZoneHandle(Symbols::AnonymousClosure());
    } else {
      if (CurrentToken() == Token::kVOID) {
        ConsumeToken();
        result_type = Type::VoidType();
      } else if ((CurrentToken() == Token::kIDENT) &&
                 (LookaheadToken(1) != Token::kLPAREN)) {
        result_type = ParseType(ClassFinalizer::kCanonicalize);
      }
      ident_pos = TokenPos();
      variable_name = ExpectIdentifier("function name expected");
      function_name = variable_name;
    }
  } else {
    // TODO(hausner) remove this block once support for old-style function
    // literals is gone.
    if (CurrentToken() == Token::kVOID) {
      ConsumeToken();
      result_type = Type::VoidType();
    } else if ((CurrentToken() == Token::kIDENT) &&
               (LookaheadToken(1) != Token::kLPAREN)) {
      result_type = ParseType(ClassFinalizer::kCanonicalize);
    }
    ident_pos = TokenPos();
    if (IsIdentifier()) {
      variable_name = CurrentLiteral();
      function_name = variable_name;
      ConsumeToken();
    } else {
      if (!is_literal) {
        ErrorMsg("function name expected");
      }
      function_name = &String::ZoneHandle(Symbols::AnonymousClosure());
    }
  }

  if (CurrentToken() != Token::kLPAREN) {
    ErrorMsg("'(' expected");
  }
  intptr_t function_pos = TokenPos();

  // Check whether we have parsed this closure function before, in a previous
  // compilation. If so, reuse the function object, else create a new one
  // and register it in the current class.
  // Note that we cannot share the same closure function between the closurized
  // and non-closurized versions of the same parent function.
  Function& function = Function::ZoneHandle();
  bool is_new_closure = false;
  // TODO(hausner): There could be two different closures at the given
  // function_pos, one enclosed in a closurized function and one enclosed in the
  // non-closurized version of this same function.
  function = current_class().LookupClosureFunction(function_pos);
  if (function.IsNull() || (function.token_pos() != function_pos) ||
      (function.parent_function() != innermost_function().raw())) {
    is_new_closure = true;
    function = Function::NewClosureFunction(*function_name,
                                            innermost_function(),
                                            function_pos);
    function.set_result_type(result_type);
    current_class().AddClosureFunction(function);
  }

  // The function type needs to be finalized at compile time, since the closure
  // may be type checked at run time when assigned to a function variable,
  // passed as a function argument, or returned as a function result.

  LocalVariable* function_variable = NULL;
  Type& function_type = Type::ZoneHandle();
  if (variable_name != NULL) {
    // Since the function type depends on the signature of the closure function,
    // it cannot be determined before the formal parameter list of the closure
    // function is parsed. Therefore, we set the function type to a new
    // parameterized type to be patched after the actual type is known.
    // We temporarily use the class of the Function interface.
    const Class& unknown_signature_class = Class::Handle(
        Type::Handle(Type::Function()).type_class());
    function_type = Type::New(
        unknown_signature_class, TypeArguments::Handle(), ident_pos);
    function_type.set_is_finalized_instantiated();  // No finalization needed.

    // Add the function variable to the scope before parsing the function in
    // order to allow self reference from inside the function.
    function_variable = new LocalVariable(ident_pos,
                                          *variable_name,
                                          function_type);
    function_variable->set_is_final();
    ASSERT(current_block_ != NULL);
    ASSERT(current_block_->scope != NULL);
    if (!current_block_->scope->AddVariable(function_variable)) {
      ErrorMsg(ident_pos, "identifier '%s' already defined",
               function_variable->name().ToCString());
    }
  }

  // Parse the local function.
  Array& default_parameter_values = Array::Handle();
  SequenceNode* statements = Parser::ParseFunc(function,
                                               default_parameter_values);
  ASSERT(is_new_closure || (function.end_token_pos() == TokenPos()));
  function.set_end_token_pos(TokenPos());

  // Now that the local function has formal parameters, lookup the signature
  // class in the current library (but not in its imports) and only create a new
  // canonical signature class if it does not exist yet.
  const String& signature = String::Handle(function.Signature());
  Class& signature_class = Class::ZoneHandle();
  if (!is_new_closure) {
    signature_class = function.signature_class();
  }
  if (signature_class.IsNull()) {
    signature_class = library_.LookupLocalClass(signature);
  }
  if (signature_class.IsNull()) {
    // If we don't have a signature class yet, this must be a closure we
    // have not parsed before.
    ASSERT(is_new_closure);
    signature_class = Class::NewSignatureClass(signature,
                                               function,
                                               script_);
    // Record the function signature class in the current library.
    library_.AddClass(signature_class);
  } else if (is_new_closure) {
    function.set_signature_class(signature_class);
  }
  ASSERT(function.signature_class() == signature_class.raw());

  // Local functions are registered in the enclosing class, but
  // ignored during class finalization. The enclosing class has
  // already been finalized.
  ASSERT(current_class().is_finalized());

  // Make sure that the instantiator is captured.
  if ((signature_class.NumTypeParameters() > 0) &&
      (current_block_->scope->function_level() > 0)) {
    CaptureInstantiator();
  }

  // Since the signature type is cached by the signature class, it may have
  // been finalized already.
  Type& signature_type = Type::Handle(signature_class.SignatureType());
  AbstractTypeArguments& signature_type_arguments =
      AbstractTypeArguments::Handle(signature_type.arguments());

  if (!signature_type.IsFinalized()) {
    signature_type ^= ClassFinalizer::FinalizeType(
        signature_class, signature_type, ClassFinalizer::kCanonicalize);

    // The call to ClassFinalizer::FinalizeType may have
    // extended the vector of type arguments.
    signature_type_arguments = signature_type.arguments();
    ASSERT(signature_type.IsMalformed() ||
           signature_type_arguments.IsNull() ||
           (signature_type_arguments.Length() ==
            signature_class.NumTypeArguments()));

    // The signature_class should not have changed.
    ASSERT(signature_type.IsMalformed() ||
           (signature_type.type_class() == signature_class.raw()));
  }

  if (variable_name != NULL) {
    // Patch the function type of the variable now that the signature is known.
    function_type.set_type_class(signature_class);
    function_type.set_arguments(signature_type_arguments);

    // Mark the function type as malformed if the signature type is malformed.
    if (signature_type.IsMalformed()) {
      const Error& error = Error::Handle(signature_type.malformed_error());
      function_type.set_malformed_error(error);
    }

    // The function variable type should have been patched above.
    ASSERT((function_variable == NULL) ||
           (function_variable->type().raw() == function_type.raw()));
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
      new ClosureNode(ident_pos, function, NULL, statements->scope());

  if (function_variable == NULL) {
    ASSERT(is_literal);
    return closure;
  } else {
    AstNode* initialization =
        new StoreLocalNode(ident_pos, function_variable, closure);
    return initialization;
  }
}


// Returns true if the current and next tokens can be parsed as type
// parameters. Current token position is not saved and restored.
bool Parser::TryParseTypeParameter() {
  if (CurrentToken() == Token::kLT) {
    // We are possibly looking at type parameters. Find closing ">".
    int nesting_level = 0;
    do {
      if (CurrentToken() == Token::kLT) {
        nesting_level++;
      } else if (CurrentToken() == Token::kGT) {
        nesting_level--;
      } else if (CurrentToken() == Token::kSHR) {
        nesting_level -= 2;
      } else if (CurrentToken() == Token::kIDENT) {
        // Check to see if it is a qualified identifier.
        if (LookaheadToken(1) == Token::kPERIOD) {
          // Consume the identifier, the period will be consumed below.
          ConsumeToken();
        }
      } else if (CurrentToken() != Token::kCOMMA &&
                 CurrentToken() != Token::kEXTENDS) {
        // We are looking at something other than type parameters.
        return false;
      }
      ConsumeToken();
    } while (nesting_level > 0);
    if (nesting_level < 0) {
      return false;
    }
  }
  return true;
}


bool Parser::IsSimpleLiteral(const AbstractType& type, Instance* value) {
  bool no_check = type.IsDynamicType();
  if ((CurrentToken() == Token::kINTEGER) &&
      (no_check || type.IsIntType() || type.IsNumberType())) {
    *value = CurrentIntegerLiteral();
    return true;
  } else if ((CurrentToken() == Token::kDOUBLE) &&
      (no_check || type.IsDoubleType() || type.IsNumberType())) {
    *value = CurrentDoubleLiteral();
    return true;
  } else if ((CurrentToken() == Token::kSTRING) &&
      (no_check || type.IsStringType())) {
    *value = CurrentLiteral()->raw();
    return true;
  } else if ((CurrentToken() == Token::kTRUE) &&
      (no_check || type.IsBoolType())) {
    *value = Bool::True();
    return true;
  } else if ((CurrentToken() == Token::kFALSE) &&
      (no_check || type.IsBoolType())) {
    *value = Bool::False();
    return true;
  } else if (CurrentToken() == Token::kNULL) {
    *value = Instance::null();
    return true;
  }
  return false;
}


// Returns true if the current token is kIDENT or a pseudo-keyword.
bool Parser::IsIdentifier() {
  return Token::IsIdentifier(CurrentToken());
}


// Returns true if the next tokens can be parsed as a type with optional
// type parameters. Current token position is not restored.
bool Parser::TryParseOptionalType() {
  if (CurrentToken() == Token::kIDENT) {
    QualIdent type_name;
    ParseQualIdent(&type_name);
    if ((CurrentToken() == Token::kLT) && !TryParseTypeParameter()) {
      return false;
    }
  }
  return true;
}


// Returns true if the next tokens can be parsed as a type with optional
// type parameters, or keyword "void".
// Current token position is not restored.
bool Parser::TryParseReturnType() {
  if (CurrentToken() == Token::kVOID) {
    ConsumeToken();
    return true;
  } else if (CurrentToken() == Token::kIDENT) {
    return TryParseOptionalType();
  }
  return false;
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
  if ((CurrentToken() == Token::kVAR) ||
      (CurrentToken() == Token::kFINAL)) {
    return true;
  }
  // Skip optional metadata.
  if (CurrentToken() == Token::kAT) {
    const intptr_t saved_pos = TokenPos();
    SkipMetadata();
    const bool is_var_decl = IsVariableDeclaration();
    SetPosition(saved_pos);
    return is_var_decl;
  }
  if ((CurrentToken() != Token::kIDENT) && (CurrentToken() != Token::kCONST)) {
    // Not a legal type identifier or const keyword or metadata.
    return false;
  }
  const intptr_t saved_pos = TokenPos();
  bool is_var_decl = false;
  bool have_type = false;
  if (CurrentToken() == Token::kCONST) {
    ConsumeToken();
    have_type = true;  // Type is dynamic.
  }
  if (IsIdentifier()) {  // Type or variable name.
    Token::Kind follower = LookaheadToken(1);
    if ((follower == Token::kLT) ||  // Parameterized type.
        (follower == Token::kPERIOD) ||  // Qualified class name of type.
        Token::IsIdentifier(follower)) {  // Variable name following a type.
      // We see the beginning of something that could be a type.
      const intptr_t type_pos = TokenPos();
      if (TryParseOptionalType()) {
        have_type = true;
      } else {
        SetPosition(type_pos);
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
  }
  SetPosition(saved_pos);
  return is_var_decl;
}


// Look ahead to detect whether the next tokens should be parsed as
// a function declaration. Token position remains unchanged.
bool Parser::IsFunctionDeclaration() {
  const intptr_t saved_pos = TokenPos();
  bool is_external = false;
  if (is_top_level_) {
    if (is_patch_source() &&
        (CurrentToken() == Token::kIDENT) &&
        CurrentLiteral()->Equals("patch") &&
        (LookaheadToken(1) != Token::kLPAREN)) {
      // Skip over 'patch' for top-level function declarations in patch sources.
      ConsumeToken();
    } else if (CurrentToken() == Token::kEXTERNAL) {
      // Skip over 'external' for top-level function declarations.
      is_external = true;
      ConsumeToken();
    }
  }
  if (IsIdentifier() && (LookaheadToken(1) == Token::kLPAREN)) {
    // Possibly a function without explicit return type.
    ConsumeToken();  // Consume function identifier.
  } else if (TryParseReturnType()) {
    if (!IsIdentifier()) {
      SetPosition(saved_pos);
      return false;
    }
    ConsumeToken();  // Consume function identifier.
  } else {
    SetPosition(saved_pos);
    return false;
  }
  // Check parameter list and the following token.
  if (CurrentToken() == Token::kLPAREN) {
    SkipToMatchingParenthesis();
    if ((CurrentToken() == Token::kLBRACE) ||
        (CurrentToken() == Token::kARROW) ||
        (is_top_level_ && IsLiteral("native")) ||
        is_external) {
      SetPosition(saved_pos);
      return true;
    }
  }
  SetPosition(saved_pos);
  return false;
}


bool Parser::IsTopLevelAccessor() {
  const intptr_t saved_pos = TokenPos();
  if (is_patch_source() &&
      (CurrentToken() == Token::kIDENT) &&
      (CurrentLiteral()->Equals("patch"))) {
    ConsumeToken();
  } else if (CurrentToken() == Token::kEXTERNAL) {
    ConsumeToken();
  }
  if ((CurrentToken() == Token::kGET) || (CurrentToken() == Token::kSET)) {
    SetPosition(saved_pos);
    return true;
  }
  if (TryParseReturnType()) {
    if ((CurrentToken() == Token::kGET) || (CurrentToken() == Token::kSET)) {
      if (Token::IsIdentifier(LookaheadToken(1))) {  // Accessor name.
        SetPosition(saved_pos);
        return true;
      }
    }
  }
  SetPosition(saved_pos);
  return false;
}


bool Parser::IsFunctionLiteral() {
  // TODO(hausner): Remove code block that supports old-style function
  // literals.
  if (FLAG_strict_function_literals) {
    if (CurrentToken() != Token::kLPAREN || !allow_function_literals_) {
      return false;
    }
    const intptr_t saved_pos = TokenPos();
    bool is_function_literal = false;
    SkipToMatchingParenthesis();
    if ((CurrentToken() == Token::kLBRACE) ||
        (CurrentToken() == Token::kARROW)) {
      is_function_literal = true;
    }
    SetPosition(saved_pos);
    return is_function_literal;
  } else {
    if (!allow_function_literals_) {
      return false;
    }
    const intptr_t saved_pos = TokenPos();
    bool is_function_literal = false;
    if (IsIdentifier() && (LookaheadToken(1) == Token::kLPAREN)) {
      ConsumeToken();  // Consume function identifier.
    } else if (TryParseReturnType()) {
      if (!IsIdentifier()) {
        SetPosition(saved_pos);
        return false;
      }
      ConsumeToken();  // Comsume function identifier.
    }
    if (CurrentToken() == Token::kLPAREN) {
      SkipToMatchingParenthesis();
      if ((CurrentToken() == Token::kLBRACE) ||
          (CurrentToken() == Token::kARROW)) {
        is_function_literal = true;
      }
    }
    SetPosition(saved_pos);
    return is_function_literal;
  }
}


// Current token position is the token after the opening ( of the for
// statement. Returns true if we recognize a for ( .. in expr)
// statement.
bool Parser::IsForInStatement() {
  const intptr_t saved_pos = TokenPos();
  bool result = false;
  // Allow const modifier as well when recognizing a for-in statement
  // pattern. We will get an error later if the loop variable is
  // declared with const.
  if (CurrentToken() == Token::kVAR ||
      CurrentToken() == Token::kFINAL ||
      CurrentToken() == Token::kCONST) {
    ConsumeToken();
  }
  if (IsIdentifier()) {
    if (LookaheadToken(1) == Token::kIN) {
      result = true;
    } else if (TryParseOptionalType()) {
      if (IsIdentifier()) {
        ConsumeToken();
      }
      result = (CurrentToken() == Token::kIN);
    }
  }
  SetPosition(saved_pos);
  return result;
}


static bool ContainsAbruptCompletingStatement(SequenceNode* seq);

static bool IsAbruptCompleting(AstNode* statement) {
  return statement->IsReturnNode() ||
         statement->IsJumpNode()   ||
         statement->IsThrowNode()  ||
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
  while (CurrentToken() != Token::kRBRACE) {
    const intptr_t statement_pos = TokenPos();
    AstNode* statement = ParseStatement();
    // Do not add statements with no effect (e.g., LoadLocalNode).
    if ((statement != NULL) && statement->IsLoadLocalNode()) {
      // Skip load local.
      statement = statement->AsLoadLocalNode()->pseudo();
    }
    if (statement != NULL) {
      if (!dead_code_allowed && abrupt_completing_seen) {
        ErrorMsg(statement_pos, "dead code after abrupt completing statement");
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
  const intptr_t if_pos = TokenPos();
  SourceLabel* label = NULL;
  if (label_name != NULL) {
    label = SourceLabel::New(if_pos, label_name, SourceLabel::kStatement);
    OpenBlock();
    current_block_->scope->AddLabel(label);
  }
  ConsumeToken();
  ExpectToken(Token::kLPAREN);
  AstNode* cond_expr = ParseExpr(kAllowConst, kConsumeCascades);
  ExpectToken(Token::kRPAREN);
  const bool parsing_loop_body = false;
  SequenceNode* true_branch = ParseNestedStatement(parsing_loop_body, NULL);
  SequenceNode* false_branch = NULL;
  if (CurrentToken() == Token::kELSE) {
    ConsumeToken();
    false_branch = ParseNestedStatement(parsing_loop_body, NULL);
  }
  AstNode* if_node = new IfNode(if_pos, cond_expr, true_branch, false_branch);
  if (label != NULL) {
    current_block_->statements->Add(if_node);
    SequenceNode* sequence = CloseBlock();
    sequence->set_label(label);
    if_node = sequence;
  }
  return if_node;
}


CaseNode* Parser::ParseCaseClause(LocalVariable* switch_expr_value,
                                  SourceLabel* case_label) {
  TRACE_PARSER("ParseCaseStatement");
  bool default_seen = false;
  const intptr_t case_pos = TokenPos();
  // The case expressions node sequence does not own the enclosing scope.
  SequenceNode* case_expressions = new SequenceNode(case_pos, NULL);
  while (CurrentToken() == Token::kCASE || CurrentToken() == Token::kDEFAULT) {
    if (CurrentToken() == Token::kCASE) {
      if (default_seen) {
        ErrorMsg("default clause must be last case");
      }
      ConsumeToken();  // Keyword case.
      const intptr_t expr_pos = TokenPos();
      AstNode* expr = ParseExpr(kAllowConst, kConsumeCascades);
      AstNode* switch_expr_load = new LoadLocalNode(case_pos,
                                                    switch_expr_value);
      AstNode* case_comparison = new ComparisonNode(expr_pos,
                                                    Token::kEQ,
                                                    expr,
                                                    switch_expr_load);
      case_expressions->Add(case_comparison);
    } else {
      if (default_seen) {
        ErrorMsg("only one default clause is allowed");
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
        ArgumentListNode* arguments = new ArgumentListNode(TokenPos());
        arguments->Add(new LiteralNode(
            TokenPos(), Integer::ZoneHandle(Integer::New(TokenPos()))));
        const String& cls_name = String::Handle(Symbols::FallThroughError());
        const String& func_name = String::Handle(Symbols::ThrowNew());
        current_block_->statements->Add(
            MakeStaticCall(cls_name, func_name, arguments));
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
  return new CaseNode(case_pos, case_label,
      case_expressions, default_seen, switch_expr_value, statements);
}


AstNode* Parser::ParseSwitchStatement(String* label_name) {
  TRACE_PARSER("ParseSwitchStatement");
  ASSERT(CurrentToken() == Token::kSWITCH);
  const intptr_t switch_pos = TokenPos();
  SourceLabel* label =
      SourceLabel::New(switch_pos, label_name, SourceLabel::kSwitch);
  ConsumeToken();
  const bool parens_are_mandatory = false;
  bool paren_found = false;
  if (CurrentToken() == Token::kLPAREN) {
    paren_found = true;
    ConsumeToken();
  } else if (parens_are_mandatory) {
    ErrorMsg("'(' expected");
  }
  const intptr_t expr_pos = TokenPos();
  AstNode* switch_expr = ParseExpr(kAllowConst, kConsumeCascades);
  if (paren_found) {
    ExpectToken(Token::kRPAREN);
  }
  ExpectToken(Token::kLBRACE);
  OpenBlock();
  current_block_->scope->AddLabel(label);

  // Store switch expression in temporary local variable.
  LocalVariable* temp_variable =
      new LocalVariable(expr_pos,
                        String::ZoneHandle(Symbols::New(":switch_expr")),
                        Type::ZoneHandle(Type::DynamicType()));
  current_block_->scope->AddVariable(temp_variable);
  AstNode* save_switch_expr =
      new StoreLocalNode(expr_pos, temp_variable, switch_expr);
  current_block_->statements->Add(save_switch_expr);

  // Parse case clauses
  bool default_seen = false;
  while (true) {
    // Check for statement label
    SourceLabel* case_label = NULL;
    if (IsIdentifier() && LookaheadToken(1) == Token::kCOLON) {
      // Case statements start with a label.
      String* label_name = CurrentLiteral();
      const intptr_t label_pos = TokenPos();
      ConsumeToken();  // Consume label identifier.
      ConsumeToken();  // Consume colon.
      case_label = current_block_->scope->LocalLookupLabel(*label_name);
      if (case_label == NULL) {
        // Label does not exist yet. Add it to scope of switch statement.
        case_label =
            new SourceLabel(label_pos, *label_name, SourceLabel::kCase);
        current_block_->scope->AddLabel(case_label);
      } else if (case_label->kind() == SourceLabel::kForward) {
        // We have seen a 'continue' with this label name. Resolve
        // the forward reference.
        case_label->ResolveForwardReference();
      } else {
        ErrorMsg(label_pos, "name '%s' already exists in scope",
                 label_name->ToCString());
      }
      ASSERT(case_label->kind() == SourceLabel::kCase);
    }
    if (CurrentToken() == Token::kCASE ||
        CurrentToken() == Token::kDEFAULT) {
      if (default_seen) {
        ErrorMsg("no case clauses allowed after default clause");
      }
      CaseNode* case_clause = ParseCaseClause(temp_variable, case_label);
      default_seen = case_clause->contains_default();
      current_block_->statements->Add(case_clause);
    } else if (CurrentToken() != Token::kRBRACE) {
      ErrorMsg("'case' or '}' expected");
    } else if (case_label != NULL) {
      ErrorMsg("expecting at least one case clause after label");
    } else {
      break;
    }
  }

  // Check for unresolved label references.
  SourceLabel* unresolved_label =
      current_block_->scope->CheckUnresolvedLabels();
  if (unresolved_label != NULL) {
    ErrorMsg("unresolved reference to label '%s'",
             unresolved_label->name().ToCString());
  }

  SequenceNode* switch_body = CloseBlock();
  ExpectToken(Token::kRBRACE);
  return new SwitchNode(switch_pos, label, switch_body);
}


AstNode* Parser::ParseWhileStatement(String* label_name) {
  TRACE_PARSER("ParseWhileStatement");
  const intptr_t while_pos = TokenPos();
  SourceLabel* label =
      SourceLabel::New(while_pos, label_name, SourceLabel::kWhile);
  ConsumeToken();
  ExpectToken(Token::kLPAREN);
  AstNode* cond_expr = ParseExpr(kAllowConst, kConsumeCascades);
  ExpectToken(Token::kRPAREN);
  const bool parsing_loop_body =  true;
  SequenceNode* while_body = ParseNestedStatement(parsing_loop_body, label);
  return new WhileNode(while_pos, label, cond_expr, while_body);
}


AstNode* Parser::ParseDoWhileStatement(String* label_name) {
  TRACE_PARSER("ParseDoWhileStatement");
  const intptr_t do_pos = TokenPos();
  SourceLabel* label =
      SourceLabel::New(do_pos, label_name, SourceLabel::kDoWhile);
  ConsumeToken();
  const bool parsing_loop_body =  true;
  SequenceNode* dowhile_body = ParseNestedStatement(parsing_loop_body, label);
  ExpectToken(Token::kWHILE);
  ExpectToken(Token::kLPAREN);
  AstNode* cond_expr = ParseExpr(kAllowConst, kConsumeCascades);
  ExpectToken(Token::kRPAREN);
  ExpectSemicolon();
  return new DoWhileNode(do_pos, label, cond_expr, dowhile_body);
}


AstNode* Parser::ParseForInStatement(intptr_t forin_pos,
                                     SourceLabel* label) {
  TRACE_PARSER("ParseForInStatement");
  bool is_final = (CurrentToken() == Token::kFINAL);
  if (CurrentToken() == Token::kCONST) {
    ErrorMsg("Loop variable cannot be 'const'");
  }
  const String* loop_var_name = NULL;
  LocalVariable* loop_var = NULL;
  intptr_t loop_var_pos = 0;
  if (LookaheadToken(1) == Token::kIN) {
    loop_var_pos = TokenPos();
    loop_var_name = ExpectIdentifier("variable name expected");
  } else {
    // The case without a type is handled above, so require a type here.
    const AbstractType& type =
        AbstractType::ZoneHandle(ParseConstFinalVarOrType(
            FLAG_enable_type_checks ? ClassFinalizer::kCanonicalize :
                                      ClassFinalizer::kIgnore));
    loop_var_pos = TokenPos();
    loop_var_name = ExpectIdentifier("variable name expected");
    loop_var = new LocalVariable(loop_var_pos, *loop_var_name, type);
    if (is_final) {
      loop_var->set_is_final();
    }
  }
  ExpectToken(Token::kIN);
  const intptr_t collection_pos = TokenPos();
  AstNode* collection_expr = ParseExpr(kAllowConst, kConsumeCascades);
  ExpectToken(Token::kRPAREN);

  OpenBlock();  // Implicit block around while loop.

  // Generate implicit iterator variable and add to scope.
  const String& iterator_name = String::ZoneHandle(Symbols::ForInIter());
  // We could set the type of the implicit iterator variable to Iterator<T>
  // where T is the type of the for loop variable. However, the type error
  // would refer to the compiler generated iterator and could confuse the user.
  // It is better to leave the iterator untyped and postpone the type error
  // until the loop variable is assigned to.
  const AbstractType& iterator_type = Type::ZoneHandle(Type::DynamicType());
  LocalVariable* iterator_var =
      new LocalVariable(collection_pos, iterator_name, iterator_type);
  current_block_->scope->AddVariable(iterator_var);

  // Generate initialization of iterator variable.
  const String& iterator_method_name =
      String::ZoneHandle(Symbols::GetIterator());
  ArgumentListNode* no_args = new ArgumentListNode(collection_pos);
  AstNode* get_iterator = new InstanceCallNode(
      collection_pos, collection_expr, iterator_method_name, no_args);
  AstNode* iterator_init =
      new StoreLocalNode(collection_pos, iterator_var, get_iterator);
  current_block_->statements->Add(iterator_init);

  // Generate while loop condition.
  AstNode* iterator_has_next = new InstanceGetterNode(
      collection_pos,
      new LoadLocalNode(collection_pos, iterator_var),
      String::ZoneHandle(Symbols::HasNext()));

  // Parse the for loop body. Ideally, we would use ParseNestedStatement()
  // here, but that does not work well because we have to insert an implicit
  // variable assignment and potentially a variable declaration in the
  // loop body.
  OpenLoopBlock();
  current_block_->scope->AddLabel(label);

  AstNode* iterator_next = new InstanceCallNode(
      collection_pos,
      new LoadLocalNode(collection_pos, iterator_var),
      String::ZoneHandle(Symbols::Next()),
      no_args);

  // Generate assignment of next iterator value to loop variable.
  AstNode* loop_var_assignment = NULL;
  if (loop_var != NULL) {
    // The for loop declares a new variable. Add it to the loop body scope.
    current_block_->scope->AddVariable(loop_var);
    loop_var_assignment =
        new StoreLocalNode(loop_var_pos, loop_var, iterator_next);
  } else {
    AstNode* loop_var_primary =
        ResolveIdent(loop_var_pos, *loop_var_name, false);
    ASSERT(!loop_var_primary->IsPrimaryNode());
    loop_var_assignment =
        CreateAssignmentNode(loop_var_primary, iterator_next);
    if (loop_var_assignment == NULL) {
      ErrorMsg(loop_var_pos, "variable or field '%s' is not assignable",
               loop_var_name->ToCString());
    }
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

  AstNode* while_statement =
      new WhileNode(forin_pos, label, iterator_has_next, for_loop_statement);
  current_block_->statements->Add(while_statement);

  return CloseBlock();  // Implicit block around while loop.
}


AstNode* Parser::ParseForStatement(String* label_name) {
  TRACE_PARSER("ParseForStatement");
  const intptr_t for_pos = TokenPos();
  ConsumeToken();
  ExpectToken(Token::kLPAREN);
  SourceLabel* label = SourceLabel::New(for_pos, label_name, SourceLabel::kFor);
  if (IsForInStatement()) {
    return ParseForInStatement(for_pos, label);
  }
  OpenBlock();
  // The label is added to the implicit scope that also contains
  // the loop variable declarations.
  current_block_->scope->AddLabel(label);
  AstNode* initializer = NULL;
  const intptr_t init_pos = TokenPos();
  LocalScope* init_scope = current_block_->scope;
  if (CurrentToken() != Token::kSEMICOLON) {
    if (IsVariableDeclaration()) {
      initializer = ParseVariableDeclarationList();
    } else {
      initializer = ParseExpr(kAllowConst, kConsumeCascades);
    }
  }
  ExpectSemicolon();
  AstNode* condition = NULL;
  if (CurrentToken() != Token::kSEMICOLON) {
    condition = ParseExpr(kAllowConst, kConsumeCascades);
  }
  ExpectSemicolon();
  AstNode* increment = NULL;
  const intptr_t incr_pos = TokenPos();
  LocalScope* incr_scope = current_block_->scope;
  if (CurrentToken() != Token::kRPAREN) {
    increment = ParseExprList();
  }
  ExpectToken(Token::kRPAREN);
  const bool parsing_loop_body =  true;
  SequenceNode* body = ParseNestedStatement(parsing_loop_body, NULL);

  // Check whether any of the variables in the initializer part of
  // the for statement are captured by a closure. If so, we insert a
  // node that creates a new Context for the loop variable before
  // the increment expression is evaluated.
  for (int i = 0; i < init_scope->num_variables(); i++) {
    if (init_scope->VariableAt(i)->is_captured() &&
        (init_scope->VariableAt(i)->owner() == init_scope)) {
      SequenceNode* incr_sequence = new SequenceNode(incr_pos, incr_scope);
      incr_sequence->Add(new CloneContextNode(for_pos));
      if (increment != NULL) {
        incr_sequence->Add(increment);
      }
      increment = incr_sequence;
      break;
    }
  }
  CloseBlock();
  return new ForNode(for_pos,
                     label,
                     NodeAsSequenceNode(init_pos, initializer, init_scope),
                     condition,
                     NodeAsSequenceNode(incr_pos, increment, incr_scope),
                     body);
}


// Calling VM-internal helpers, uses implementation core library.
AstNode* Parser::MakeStaticCall(const String& cls_name,
                                const String& func_name,
                                ArgumentListNode* arguments) {
  const Class& cls = Class::Handle(LookupCoreClass(cls_name));
  ASSERT(!cls.IsNull());
  const Function& func = Function::ZoneHandle(
      Resolver::ResolveStatic(cls,
                              func_name,
                              arguments->length(),
                              arguments->names(),
                              Resolver::kIsQualified));
  ASSERT(!func.IsNull());
  CheckFunctionIsCallable(arguments->token_pos(), func);
  return new StaticCallNode(arguments->token_pos(), func, arguments);
}


AstNode* Parser::MakeAssertCall(intptr_t begin, intptr_t end) {
  ArgumentListNode* arguments = new ArgumentListNode(begin);
  arguments->Add(new LiteralNode(begin,
      Integer::ZoneHandle(Integer::New(begin))));
  arguments->Add(new LiteralNode(end,
      Integer::ZoneHandle(Integer::New(end))));
  const String& cls_name = String::Handle(Symbols::AssertionError());
  const String& func_name = String::Handle(Symbols::ThrowNew());
  return MakeStaticCall(cls_name, func_name, arguments);
}


AstNode* Parser::InsertClosureCallNodes(AstNode* condition) {
  if (condition->IsClosureNode() ||
      (condition->IsStoreLocalNode() &&
       condition->AsStoreLocalNode()->value()->IsClosureNode())) {
    EnsureExpressionTemp();
    // Function literal in assert implies a call.
    const intptr_t pos = condition->token_pos();
    condition = new ClosureCallNode(pos, condition, new ArgumentListNode(pos));
  } else if (condition->IsConditionalExprNode()) {
    ConditionalExprNode* cond_expr = condition->AsConditionalExprNode();
    cond_expr->set_true_expr(InsertClosureCallNodes(cond_expr->true_expr()));
    cond_expr->set_false_expr(InsertClosureCallNodes(cond_expr->false_expr()));
  }
  return condition;
}


AstNode* Parser::ParseAssertStatement() {
  TRACE_PARSER("ParseAssertStatement");
  ConsumeToken();  // Consume assert keyword.
  ExpectToken(Token::kLPAREN);
  const intptr_t condition_pos = TokenPos();
  if (!FLAG_enable_asserts && !FLAG_enable_type_checks) {
    SkipExpr();
    ExpectToken(Token::kRPAREN);
    return NULL;
  }
  AstNode* condition = ParseExpr(kAllowConst, kConsumeCascades);
  const intptr_t condition_end = TokenPos();
  ExpectToken(Token::kRPAREN);
  condition = InsertClosureCallNodes(condition);
  condition = new UnaryOpNode(condition_pos, Token::kNOT, condition);
  AstNode* assert_throw = MakeAssertCall(condition_pos, condition_end);
  return new IfNode(condition_pos,
                    condition,
                    NodeAsSequenceNode(condition_pos, assert_throw, NULL),
                    NULL);
}


struct CatchParamDesc {
  CatchParamDesc()
      : token_pos(0), type(NULL), var(NULL) { }
  intptr_t token_pos;
  const AbstractType* type;
  const String* var;
};


// Populate local scope of the catch block with the catch parameters.
void Parser::AddCatchParamsToScope(const CatchParamDesc& exception_param,
                                   const CatchParamDesc& stack_trace_param,
                                   LocalScope* scope) {
  if (exception_param.var != NULL) {
    LocalVariable* var = new LocalVariable(exception_param.token_pos,
                                           *exception_param.var,
                                           *exception_param.type);
    var->set_is_final();
    bool added_to_scope = scope->AddVariable(var);
    ASSERT(added_to_scope);
  }
  if (stack_trace_param.var != NULL) {
    LocalVariable* var = new LocalVariable(TokenPos(),
                                           *stack_trace_param.var,
                                           *stack_trace_param.type);
    var->set_is_final();
    bool added_to_scope = scope->AddVariable(var);
    if (!added_to_scope) {
      ErrorMsg(stack_trace_param.token_pos,
               "name '%s' already exists in scope",
               stack_trace_param.var->ToCString());
    }
  }
}


SequenceNode* Parser::ParseFinallyBlock() {
  TRACE_PARSER("ParseFinallyBlock");
  OpenBlock();
  ExpectToken(Token::kLBRACE);
  ParseStatementSequence();
  ExpectToken(Token::kRBRACE);
  SequenceNode* finally_block = CloseBlock();
  return finally_block;
}


void Parser::PushTryBlock(Block* try_block) {
  TryBlocks* block = new TryBlocks(try_block, try_blocks_list_);
  try_blocks_list_ = block;
}


Parser::TryBlocks* Parser::PopTryBlock() {
  TryBlocks* innermost_try_block = try_blocks_list_;
  try_blocks_list_ = try_blocks_list_->outer_try_block();
  return innermost_try_block;
}


void Parser::AddNodeForFinallyInlining(AstNode* node) {
  if (node == NULL) {
    return;
  }
  ASSERT(node->IsReturnNode() || node->IsJumpNode());
  TryBlocks* iterator = try_blocks_list_;
  while (iterator != NULL) {
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
      if (label->owner()->IsNestedWithin(try_scope)) {
        break;
      }
    }
    iterator->AddNodeForFinallyInlining(node);
    iterator = iterator->outer_try_block();
  }
}


// Add the inlined finally block to the specified node.
void Parser::AddFinallyBlockToNode(AstNode* node,
                                   InlinedFinallyNode* finally_node) {
  if (node->IsReturnNode()) {
    node->AsReturnNode()->AddInlinedFinallyNode(finally_node);
  } else {
    ASSERT(node->IsJumpNode());
    node->AsJumpNode()->AddInlinedFinallyNode(finally_node);
  }
}


AstNode* Parser::ParseTryStatement(String* label_name) {
  TRACE_PARSER("ParseTryStatement");

  // We create three stack slots for exceptions here:
  // ':saved_context_var' - Used to save the context before start of the try
  //                        block. The context register is restored from this
  //                        slot before processing the catch block handler.
  // ':exception_var' - Used to save the current exception object that was
  //                    thrown.
  // ':stacktrace_var' - Used to save the current stack trace object into which
  //                     the stack trace was copied into when an exception was
  //                     thrown.
  // :exception_var and :stacktrace_var get set with the exception object
  // and the stacktrace object when an exception is thrown.
  // These three implicit variables can never be captured variables.
  const String& context_var_name =
      String::ZoneHandle(Symbols::SavedContextVar());
  LocalVariable* context_var =
      current_block_->scope->LocalLookupVariable(context_var_name);
  if (context_var == NULL) {
    context_var = new LocalVariable(TokenPos(),
                                    context_var_name,
                                    Type::ZoneHandle(Type::DynamicType()));
    current_block_->scope->AddVariable(context_var);
  }
  const String& catch_excp_var_name =
      String::ZoneHandle(Symbols::ExceptionVar());
  LocalVariable* catch_excp_var =
      current_block_->scope->LocalLookupVariable(catch_excp_var_name);
  if (catch_excp_var == NULL) {
    catch_excp_var = new LocalVariable(TokenPos(),
                                       catch_excp_var_name,
                                       Type::ZoneHandle(Type::DynamicType()));
    current_block_->scope->AddVariable(catch_excp_var);
  }
  const String& catch_trace_var_name =
      String::ZoneHandle(Symbols::StacktraceVar());
  LocalVariable* catch_trace_var =
      current_block_->scope->LocalLookupVariable(catch_trace_var_name);
  if (catch_trace_var == NULL) {
    catch_trace_var = new LocalVariable(TokenPos(),
                                        catch_trace_var_name,
                                        Type::ZoneHandle(Type::DynamicType()));
    current_block_->scope->AddVariable(catch_trace_var);
  }

  const intptr_t try_pos = TokenPos();
  ConsumeToken();  // Consume the 'try'.

  SourceLabel* try_label = NULL;
  if (label_name != NULL) {
    try_label = SourceLabel::New(try_pos, label_name, SourceLabel::kStatement);
    OpenBlock();
    current_block_->scope->AddLabel(try_label);
  }

  // Now parse the 'try' block.
  OpenBlock();
  Block* current_try_block = current_block_;
  PushTryBlock(current_try_block);
  ExpectToken(Token::kLBRACE);
  ParseStatementSequence();
  ExpectToken(Token::kRBRACE);
  SequenceNode* try_block = CloseBlock();

  // Now create a label for the end of catch block processing so that we can
  // jump over the catch block code after executing the try block.
  SourceLabel* end_catch_label =
      SourceLabel::New(TokenPos(), NULL, SourceLabel::kCatch);

  // Now parse the 'catch' blocks if any and merge all of them into
  // an if-then sequence of the different types specified using the 'is'
  // operator.
  bool catch_seen = false;
  bool generic_catch_seen = false;
  SequenceNode* catch_handler_list = NULL;
  const intptr_t handler_pos = TokenPos();
  OpenBlock();  // Start the catch block sequence.
  current_block_->scope->AddLabel(end_catch_label);
  while ((CurrentToken() == Token::kCATCH) || IsLiteral("on")) {
    const intptr_t catch_pos = TokenPos();
    CatchParamDesc exception_param;
    CatchParamDesc stack_trace_param;
    catch_seen = true;
    if (IsLiteral("on")) {
      ConsumeToken();
      // TODO(regis): The spec may change in the way a malformed 'on' type is
      // treated. For now, we require the type to be wellformed.
      exception_param.type = &AbstractType::ZoneHandle(
          ParseType(ClassFinalizer::kCanonicalizeWellFormed));
    } else {
      exception_param.type =
          &AbstractType::ZoneHandle(Type::DynamicType());
    }
    if (CurrentToken() == Token::kCATCH) {
      ConsumeToken();  // Consume the 'catch'.
      ExpectToken(Token::kLPAREN);
      exception_param.token_pos = TokenPos();
      exception_param.var = ExpectIdentifier("identifier expected");
      if (CurrentToken() == Token::kCOMMA) {
        ConsumeToken();
        // TODO(hausner): Make implicit type be StackTrace, not dynamic.
        stack_trace_param.type =
            &AbstractType::ZoneHandle(Type::DynamicType());
        stack_trace_param.token_pos = TokenPos();
        stack_trace_param.var = ExpectIdentifier("identifier expected");
      }
      ExpectToken(Token::kRPAREN);
    }

    // If a generic "catch all" statement has already been seen then all
    // subsequent catch statements are dead. We issue an error for now,
    // it might make sense to turn this into a warning.
    if (generic_catch_seen) {
      ErrorMsg("a generic 'catch all' statement already exists for this "
               "try block. All subsequent catch statements are dead code");
    }
    OpenBlock();
    AddCatchParamsToScope(exception_param,
                          stack_trace_param,
                          current_block_->scope);

    // Parse the individual catch handler code and add an unconditional
    // JUMP to the end of the try block.
    ExpectToken(Token::kLBRACE);
    OpenBlock();

    if (exception_param.var != NULL) {
      // Generate code to load the exception object (:exception_var) into
      // the exception variable specified in this block.
      LocalVariable* var = LookupLocalScope(*exception_param.var);
      ASSERT(var != NULL);
      ASSERT(catch_excp_var != NULL);
      current_block_->statements->Add(
          new StoreLocalNode(catch_pos, var,
                             new LoadLocalNode(catch_pos, catch_excp_var)));
    }
    if (stack_trace_param.var != NULL) {
      // A stack trace variable is specified in this block, so generate code
      // to load the stack trace object (:stacktrace_var) into the stack trace
      // variable specified in this block.
      LocalVariable* trace = LookupLocalScope(*stack_trace_param.var);
      ASSERT(catch_trace_var != NULL);
      current_block_->statements->Add(
          new StoreLocalNode(catch_pos, trace,
                             new LoadLocalNode(catch_pos, catch_trace_var)));
    }

    ParseStatementSequence();  // Parse the catch handler code.
    current_block_->statements->Add(
        new JumpNode(catch_pos, Token::kCONTINUE, end_catch_label));
    SequenceNode* catch_handler = CloseBlock();
    ExpectToken(Token::kRBRACE);

    if (!exception_param.type->IsDynamicType()) {  // Has a type specification.
      // Now form an 'if type check' as an exception type exists in
      // the catch specifier.
      if (!exception_param.type->IsInstantiated() &&
          (current_block_->scope->function_level() > 0)) {
        // Make sure that the instantiator is captured.
        CaptureInstantiator();
      }
      TypeNode* exception_type = new TypeNode(catch_pos, *exception_param.type);
      AstNode* exception_var = new LoadLocalNode(catch_pos, catch_excp_var);
      if (!exception_type->type().IsInstantiated()) {
        EnsureExpressionTemp();
      }
      AstNode* type_cond_expr = new ComparisonNode(
          catch_pos, Token::kIS, exception_var, exception_type);
      current_block_->statements->Add(
          new IfNode(catch_pos, type_cond_expr, catch_handler, NULL));
    } else {
      // No exception type exists in the catch specifier so execute the
      // catch handler code unconditionally.
      current_block_->statements->Add(catch_handler);
      generic_catch_seen = true;
    }
    SequenceNode* catch_clause = CloseBlock();

    // Add this individual catch handler to the catch handlers list.
    current_block_->statements->Add(catch_clause);
  }
  catch_handler_list = CloseBlock();
  TryBlocks* inner_try_block = PopTryBlock();

  // Finally parse the 'finally' block.
  SequenceNode* finally_block = NULL;
  if (CurrentToken() == Token::kFINALLY) {
    current_function().set_is_optimizable(false);
    current_function().set_has_finally(true);
    ConsumeToken();  // Consume the 'finally'.
    const intptr_t finally_pos = TokenPos();
    // Add the finally block to the exit points recorded so far.
    intptr_t node_index = 0;
    AstNode* node_to_inline =
        inner_try_block->GetNodeToInlineFinally(node_index);
    while (node_to_inline != NULL) {
      finally_block = ParseFinallyBlock();
      InlinedFinallyNode* node = new InlinedFinallyNode(finally_pos,
                                                        finally_block,
                                                        context_var);
      AddFinallyBlockToNode(node_to_inline, node);
      node_index += 1;
      node_to_inline = inner_try_block->GetNodeToInlineFinally(node_index);
      tokens_iterator_.SetCurrentPosition(finally_pos);
    }
    if (!generic_catch_seen) {
      // No generic catch handler exists so execute this finally block
      // before rethrowing the exception.
      finally_block = ParseFinallyBlock();
      catch_handler_list->Add(finally_block);
      tokens_iterator_.SetCurrentPosition(finally_pos);
    }
    finally_block = ParseFinallyBlock();
  } else {
    if (!catch_seen) {
      ErrorMsg("catch or finally clause expected");
    }
  }

  if (!generic_catch_seen) {
    // No generic catch handler exists so rethrow the exception so that
    // the next catch handler can deal with it.
    catch_handler_list->Add(
        new ThrowNode(handler_pos,
                      new LoadLocalNode(handler_pos, catch_excp_var),
                      new LoadLocalNode(handler_pos, catch_trace_var)));
  }
  CatchClauseNode* catch_block = new CatchClauseNode(handler_pos,
                                                     catch_handler_list,
                                                     context_var,
                                                     catch_excp_var,
                                                     catch_trace_var);

  // Now create the try/catch ast node and return it. If there is a label
  // on the try/catch, close the block that's embedding the try statement
  // and attach the label to it.
  AstNode* try_catch_node =
      new TryCatchNode(try_pos, try_block, end_catch_label,
                       context_var, catch_block, finally_block);

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
  const intptr_t jump_pos = TokenPos();
  SourceLabel* target = NULL;
  ConsumeToken();
  if (IsIdentifier()) {
    // Explicit label after break/continue.
    const String& target_name = *CurrentLiteral();
    ConsumeToken();
    // Handle pathological cases first.
    if (label_name != NULL && target_name.Equals(*label_name)) {
      if (jump_kind == Token::kCONTINUE) {
        ErrorMsg(jump_pos, "'continue' jump to label '%s' is illegal",
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
        target = new SourceLabel(
            TokenPos(), target_name, SourceLabel::kForward);
        switch_scope->AddLabel(target);
      }
    }
    if (target == NULL) {
      ErrorMsg(jump_pos, "label '%s' not found", target_name.ToCString());
    }
  } else {
    target = current_block_->scope->LookupInnermostLabel(jump_kind);
    if (target == NULL) {
      ErrorMsg(jump_pos, "'%s' is illegal here", Token::Str(jump_kind));
    }
  }
  ASSERT(target != NULL);
  if (jump_kind == Token::kCONTINUE) {
    if (target->kind() == SourceLabel::kSwitch) {
      ErrorMsg(jump_pos, "'continue' jump to switch statement is illegal");
    } else if (target->kind() == SourceLabel::kStatement) {
      ErrorMsg(jump_pos, "'continue' jump to label '%s' is illegal",
               target->name().ToCString());
    }
  }
  if (jump_kind == Token::kBREAK && target->kind() == SourceLabel::kCase) {
    ErrorMsg(jump_pos, "'break' to case clause label is illegal");
  }
  if (target->FunctionLevel() != current_block_->scope->function_level()) {
    ErrorMsg(jump_pos, "'%s' target must be in same function context",
             Token::Str(jump_kind));
  }
  return new JumpNode(jump_pos, jump_kind, target);
}


AstNode* Parser::ParseStatement() {
  TRACE_PARSER("ParseStatement");
  AstNode* statement = NULL;
  intptr_t label_pos = 0;
  String* label_name = NULL;
  if (IsIdentifier()) {
    if (LookaheadToken(1) == Token::kCOLON) {
      // Statement starts with a label.
      label_name = CurrentLiteral();
      label_pos = TokenPos();
      ASSERT(label_pos > 0);
      ConsumeToken();  // Consume identifier.
      ConsumeToken();  // Consume colon.
    }
  }
  const intptr_t statement_pos = TokenPos();

  if (CurrentToken() == Token::kWHILE) {
    statement = ParseWhileStatement(label_name);
  } else if (CurrentToken() == Token::kFOR) {
    statement = ParseForStatement(label_name);
  } else if (CurrentToken() == Token::kDO) {
    statement = ParseDoWhileStatement(label_name);
  } else if (CurrentToken() == Token::kSWITCH) {
    statement = ParseSwitchStatement(label_name);
  } else if (CurrentToken() == Token::kTRY) {
    statement = ParseTryStatement(label_name);
  } else if (CurrentToken() == Token::kRETURN) {
    const intptr_t return_pos = TokenPos();
    ConsumeToken();
    if (CurrentToken() != Token::kSEMICOLON) {
      if (current_function().IsConstructor() &&
          (current_block_->scope->function_level() == 0)) {
        ErrorMsg(return_pos, "return of a value not allowed in constructors");
      }
      AstNode* expr = ParseExpr(kAllowConst, kConsumeCascades);
      statement = new ReturnNode(statement_pos, expr);
    } else {
      statement = new ReturnNode(statement_pos);
    }
    AddNodeForFinallyInlining(statement);
    ExpectSemicolon();
  } else if (CurrentToken() == Token::kIF) {
    statement = ParseIfStatement(label_name);
  } else if (CurrentToken() == Token::kASSERT) {
    statement = ParseAssertStatement();
    ExpectSemicolon();
  } else if (IsVariableDeclaration()) {
    statement = ParseVariableDeclarationList();
    ExpectSemicolon();
  } else if (IsFunctionDeclaration()) {
    statement = ParseFunctionStatement(false);
  } else if (CurrentToken() == Token::kLBRACE) {
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
  } else if (CurrentToken() == Token::kBREAK) {
    statement = ParseJump(label_name);
    AddNodeForFinallyInlining(statement);
    ExpectSemicolon();
  } else if (CurrentToken() == Token::kCONTINUE) {
    statement = ParseJump(label_name);
    AddNodeForFinallyInlining(statement);
    ExpectSemicolon();
  } else if (CurrentToken() == Token::kSEMICOLON) {
    // Empty statement, nothing to do.
    ConsumeToken();
  } else if ((CurrentToken() == Token::kTHROW) &&
             (LookaheadToken(1) == Token::kSEMICOLON)) {
    // Rethrow of current exception. Throwing of an exception object
    // is an expression and is handled in ParseExpr().
    ConsumeToken();
    ExpectSemicolon();
    // Check if it is ok to do a rethrow.
    SourceLabel* label = current_block_->scope->LookupInnermostCatchLabel();
    if (label == NULL ||
        label->FunctionLevel() != current_block_->scope->function_level()) {
      ErrorMsg(statement_pos, "rethrow of an exception is not valid here");
    }
    ASSERT(label->owner() != NULL);
    LocalScope* scope = label->owner()->parent();
    ASSERT(scope != NULL);
    LocalVariable* excp_var = scope->LocalLookupVariable(
        String::ZoneHandle(Symbols::ExceptionVar()));
    ASSERT(excp_var != NULL);
    LocalVariable* trace_var = scope->LocalLookupVariable(
        String::ZoneHandle(Symbols::StacktraceVar()));
    ASSERT(trace_var != NULL);
    statement = new ThrowNode(statement_pos,
                              new LoadLocalNode(statement_pos, excp_var),
                              new LoadLocalNode(statement_pos, trace_var));
  } else {
    statement = ParseExpr(kAllowConst, kConsumeCascades);
    ExpectSemicolon();
  }
  return statement;
}


RawError* Parser::FormatErrorWithAppend(const Error& prev_error,
                                        const Script& script,
                                        intptr_t token_pos,
                                        const char* message_header,
                                        const char* format,
                                        va_list args) {
  const String& msg1 = String::Handle(String::New(prev_error.ToErrorCString()));
  const String& msg2 = String::Handle(
      FormatMessage(script, token_pos, message_header, format, args));
  return LanguageError::New(String::Handle(String::Concat(msg1, msg2)));
}


RawError* Parser::FormatError(const Script& script,
                              intptr_t token_pos,
                              const char* message_header,
                              const char* format,
                              va_list args) {
  const String& msg = String::Handle(
      FormatMessage(script, token_pos, message_header, format, args));
  return LanguageError::New(msg);
}


RawError* Parser::FormatErrorMsg(const Script& script,
                                 intptr_t token_pos,
                                 const char* message_header,
                                 const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(
      FormatError(script, token_pos, message_header, format, args));
  va_end(args);
  return error.raw();
}


RawString* Parser::FormatMessage(const Script& script,
                                 intptr_t token_pos,
                                 const char* message_header,
                                 const char* format, va_list args) {
  String& result = String::Handle();
  const String& msg = String::Handle(String::NewFormattedV(format, args));
  if (!script.IsNull()) {
    const String& script_url = String::CheckedHandle(script.url());
    if (token_pos >= 0) {
      intptr_t line, column;
      script.GetTokenLocation(token_pos, &line, &column);
      result = String::NewFormatted("'%s': %s: line %"Pd" pos %"Pd": ",
                                    script_url.ToCString(),
                                    message_header,
                                    line,
                                    column);
      // Append the formatted error or warning message.
      result = String::Concat(result, msg);
      const String& new_line = String::Handle(String::New("\n"));
      // Append the source line.
      const String& script_line = String::Handle(script.GetLine(line));
      ASSERT(!script_line.IsNull());
      result = String::Concat(result, new_line);
      result = String::Concat(result, script_line);
      result = String::Concat(result, new_line);
      // Append the column marker.
      const String& column_line = String::Handle(
          String::NewFormatted("%*s\n", static_cast<int>(column), "^"));
      result = String::Concat(result, column_line);
    } else {
      // Token position is unknown.
      result = String::NewFormatted("'%s': %s: ",
                                    script_url.ToCString(),
                                    message_header);
      result = String::Concat(result, msg);
    }
  } else {
    // Script is unknown.
    // Append the formatted error or warning message.
    result = msg.raw();
  }
  return result.raw();
}


void Parser::PrintMessage(const Script& script,
                          intptr_t token_pos,
                          const char* message_header,
                          const char* format, ...) {
  va_list args;
  va_start(args, format);
  const String& buf = String::Handle(
      FormatMessage(script, token_pos, message_header, format, args));
  va_end(args);
  OS::Print("%s", buf.ToCString());
}


void Parser::ErrorMsg(intptr_t token_pos, const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(
      FormatError(script_, token_pos, "Error", format, args));
  va_end(args);
  Isolate::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}


void Parser::ErrorMsg(const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(
      FormatError(script_, TokenPos(), "Error", format, args));
  va_end(args);
  Isolate::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}


void Parser::ErrorMsg(const Error& error) {
  Isolate::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}


void Parser::AppendErrorMsg(
      const Error& prev_error, intptr_t token_pos, const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(FormatErrorWithAppend(
      prev_error, script_, token_pos, "Error", format, args));
  va_end(args);
  Isolate::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}


void Parser::Warning(intptr_t token_pos, const char* format, ...) {
  if (FLAG_silent_warnings) return;
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(
      FormatError(script_, token_pos, "Warning", format, args));
  va_end(args);
  if (FLAG_warning_as_error) {
    Isolate::Current()->long_jump_base()->Jump(1, error);
    UNREACHABLE();
  } else {
    OS::Print("%s", error.ToErrorCString());
  }
}


void Parser::Warning(const char* format, ...) {
  if (FLAG_silent_warnings) return;
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(
      FormatError(script_, TokenPos(), "Warning", format, args));
  va_end(args);
  if (FLAG_warning_as_error) {
    Isolate::Current()->long_jump_base()->Jump(1, error);
    UNREACHABLE();
  } else {
    OS::Print("%s", error.ToErrorCString());
  }
}


void Parser::Unimplemented(const char* msg) {
  ErrorMsg(TokenPos(), "%s", msg);
}


void Parser::ExpectToken(Token::Kind token_expected) {
  if (CurrentToken() != token_expected) {
    ErrorMsg("'%s' expected", Token::Str(token_expected));
  }
  ConsumeToken();
}


void Parser::ExpectSemicolon() {
  if (CurrentToken() != Token::kSEMICOLON) {
    ErrorMsg("semicolon expected");
  }
  ConsumeToken();
}


void Parser::UnexpectedToken() {
  ErrorMsg("unexpected token '%s'",
           CurrentToken() == Token::kIDENT ?
               CurrentLiteral()->ToCString() : Token::Str(CurrentToken()));
}


String* Parser::ExpectUserDefinedTypeIdentifier(const char* msg) {
  if (CurrentToken() != Token::kIDENT) {
    ErrorMsg("%s", msg);
  }
  String* ident = CurrentLiteral();
  if (ident->Equals("dynamic")) {
    ErrorMsg("%s", msg);
  }
  ConsumeToken();
  return ident;
}


// Check whether current token is an identifier or a built-in identifier.
String* Parser::ExpectIdentifier(const char* msg) {
  if (!IsIdentifier()) {
    ErrorMsg("%s", msg);
  }
  String* ident = CurrentLiteral();
  ConsumeToken();
  return ident;
}


bool Parser::IsLiteral(const char* literal) {
  return IsIdentifier() && CurrentLiteral()->Equals(literal);
}


static bool IsIncrementOperator(Token::Kind token) {
  return token == Token::kINCR || token == Token::kDECR;
}


static bool IsPrefixOperator(Token::Kind token) {
  return (token == Token::kTIGHTADD) ||   // Valid for literals only!
         (token == Token::kSUB) ||
         (token == Token::kNOT) ||
         (token == Token::kBIT_NOT);
}


SequenceNode* Parser::NodeAsSequenceNode(intptr_t sequence_pos,
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


AstNode* Parser::ThrowTypeError(intptr_t type_pos, const AbstractType& type) {
  ASSERT(type.IsMalformed());
  ArgumentListNode* arguments = new ArgumentListNode(type_pos);
  // Location argument.
  arguments->Add(new LiteralNode(
      type_pos, Integer::ZoneHandle(Integer::New(type_pos))));
  // Src value argument.
  arguments->Add(new LiteralNode(type_pos, Instance::ZoneHandle()));
  // Dst type name argument.
  arguments->Add(new LiteralNode(type_pos, String::ZoneHandle(
      Symbols::New("malformed"))));
  // Dst name argument.
  arguments->Add(new LiteralNode(type_pos,
                                 String::ZoneHandle(Symbols::Empty())));
  // Malformed type error.
  const Error& error = Error::Handle(type.malformed_error());
  arguments->Add(new LiteralNode(type_pos, String::ZoneHandle(
      Symbols::New(error.ToErrorCString()))));
  const String& cls_name = String::Handle(Symbols::TypeError());
  const String& func_name = String::Handle(Symbols::ThrowNew());
  return MakeStaticCall(cls_name, func_name, arguments);
}


AstNode* Parser::ThrowNoSuchMethodError(intptr_t call_pos, const String& name) {
  ArgumentListNode* arguments = new ArgumentListNode(call_pos);
  // Location argument.
  arguments->Add(new LiteralNode(
      call_pos, Integer::ZoneHandle(Integer::New(call_pos))));
  // Function name argument.
  arguments->Add(new LiteralNode(
      call_pos, String::ZoneHandle(Symbols::New(name))));
  const String& cls_name = String::Handle(Symbols::NoSuchMethodError());
  const String& func_name = String::Handle(Symbols::ThrowNew());
  return MakeStaticCall(cls_name, func_name, arguments);
}


AstNode* Parser::ParseBinaryExpr(int min_preced) {
  TRACE_PARSER("ParseBinaryExpr");
  ASSERT(min_preced >= 4);
  AstNode* left_operand = ParseUnaryExpr();
  if (left_operand->IsPrimaryNode() &&
      (left_operand->AsPrimaryNode()->IsSuper())) {
    ErrorMsg(left_operand->token_pos(), "illegal use of 'super'");
  }
  if (IsLiteral("as")) {  // Not a reserved word.
    token_kind_ = Token::kAS;
  }
  int current_preced = Token::Precedence(CurrentToken());
  while (current_preced >= min_preced) {
    while (Token::Precedence(CurrentToken()) == current_preced) {
      Token::Kind op_kind = CurrentToken();
      if (op_kind == Token::kTIGHTADD) {
        op_kind = Token::kADD;
      }
      const intptr_t op_pos = TokenPos();
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
        const intptr_t type_pos = TokenPos();
        const AbstractType& type = AbstractType::ZoneHandle(
            ParseType(ClassFinalizer::kCanonicalizeExpression));
        if (!type.IsInstantiated() &&
            (current_block_->scope->function_level() > 0)) {
          // Make sure that the instantiator is captured.
          CaptureInstantiator();
        }
        right_operand = new TypeNode(type_pos, type);
        if (((op_kind == Token::kIS) || (op_kind == Token::kISNOT)) &&
            type.IsMalformed()) {
          // Note that a type error is thrown even if the tested value is null
          // in a type test. However, no cast exception is thrown if the value
          // is null in a type cast.
          return ThrowTypeError(type_pos, type);
        }
      }
      if (Token::IsRelationalOperator(op_kind)
          || Token::IsTypeTestOperator(op_kind)
          || Token::IsTypeCastOperator(op_kind)
          || Token::IsEqualityOperator(op_kind)) {
        if (Token::IsTypeTestOperator(op_kind) ||
            Token::IsTypeCastOperator(op_kind)) {
          if (!right_operand->AsTypeNode()->type().IsInstantiated()) {
            EnsureExpressionTemp();
          }
        }
        left_operand = new ComparisonNode(
            op_pos, op_kind, left_operand, right_operand);
        break;  // Equality and relational operators cannot be chained.
      } else {
        left_operand = OptimizeBinaryOpNode(
            op_pos, op_kind, left_operand, right_operand);
      }
    }
    current_preced--;
  }
  return left_operand;
}


bool Parser::IsAssignableExpr(AstNode* expr) {
  return (expr->IsLoadLocalNode() && !expr->AsLoadLocalNode()->HasPseudo()
          && (!expr->AsLoadLocalNode()->local().is_final()))
      || expr->IsLoadStaticFieldNode()
      || expr->IsStaticGetterNode()
      || expr->IsInstanceGetterNode()
      || expr->IsLoadIndexedNode()
      || (expr->IsPrimaryNode() && !expr->AsPrimaryNode()->IsSuper());
}


AstNode* Parser::ParseExprList() {
  TRACE_PARSER("ParseExprList");
  AstNode* expressions = ParseExpr(kAllowConst, kConsumeCascades);
  if (CurrentToken() == Token::kCOMMA) {
    // Collect comma-separated expressions in a non scope owning sequence node.
    SequenceNode* list = new SequenceNode(TokenPos(), NULL);
    list->Add(expressions);
    while (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
      AstNode* expr = ParseExpr(kAllowConst, kConsumeCascades);
      list->Add(expr);
    }
    expressions = list;
  }
  return expressions;
}


const LocalVariable* Parser::GetIncrementTempLocal() {
  if (expression_temp_ == NULL) {
    expression_temp_ = ParsedFunction::CreateExpressionTempVar(
        current_function().token_pos());
    ASSERT(expression_temp_ != NULL);
  }
  return expression_temp_;
}


void Parser::EnsureExpressionTemp() {
  // Temporary used later by the flow_graph_builder.
  GetIncrementTempLocal();
}


LocalVariable* Parser::CreateTempConstVariable(intptr_t token_pos,
                                               const char* s) {
  char name[64];
  OS::SNPrint(name, 64, ":%s%"Pd, s, token_pos);
  LocalVariable* temp =
      new LocalVariable(token_pos,
                        String::ZoneHandle(Symbols::New(name)),
                        Type::ZoneHandle(Type::DynamicType()));
  temp->set_is_final();
  current_block_->scope->AddVariable(temp);
  return temp;
}


// TODO(srdjan): Implement other optimizations.
AstNode* Parser::OptimizeBinaryOpNode(intptr_t op_pos,
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
            Double::NewCanonical((left_double / right_double)));
        return new LiteralNode(op_pos, dbl_obj);
      }
    }
  }
  if ((binary_op == Token::kAND) || (binary_op == Token::kOR)) {
    EnsureExpressionTemp();
  }
  return new BinaryOpNode(op_pos, binary_op, lhs, rhs);
}


AstNode* Parser::ExpandAssignableOp(intptr_t op_pos,
                                    Token::Kind assignment_op,
                                    AstNode* lhs,
                                    AstNode* rhs) {
  TRACE_PARSER("ExpandAssignableOp");
  switch (assignment_op) {
    case Token::kASSIGN:
      return rhs;
    case Token::kASSIGN_ADD:
      return new BinaryOpNode(op_pos, Token::kADD, lhs, rhs);
    case Token::kASSIGN_SUB:
      return new BinaryOpNode(op_pos, Token::kSUB, lhs, rhs);
    case Token::kASSIGN_MUL:
      return new BinaryOpNode(op_pos, Token::kMUL, lhs, rhs);
    case Token::kASSIGN_TRUNCDIV:
      return new BinaryOpNode(op_pos, Token::kTRUNCDIV, lhs, rhs);
    case Token::kASSIGN_DIV:
      return new BinaryOpNode(op_pos, Token::kDIV, lhs, rhs);
    case Token::kASSIGN_MOD:
      return new BinaryOpNode(op_pos, Token::kMOD, lhs, rhs);
    case Token::kASSIGN_SHR:
      return new BinaryOpNode(op_pos, Token::kSHR, lhs, rhs);
    case Token::kASSIGN_SHL:
      return new BinaryOpNode(op_pos, Token::kSHL, lhs, rhs);
    case Token::kASSIGN_OR:
      return new BinaryOpNode(op_pos, Token::kBIT_OR, lhs, rhs);
    case Token::kASSIGN_AND:
      return new BinaryOpNode(op_pos, Token::kBIT_AND, lhs, rhs);
    case Token::kASSIGN_XOR:
      return new BinaryOpNode(op_pos, Token::kBIT_XOR, lhs, rhs);
    default:
      ErrorMsg(op_pos, "internal error: ExpandAssignableOp '%s' unimplemented",
          Token::Name(assignment_op));
      UNIMPLEMENTED();
      return NULL;
  }
}


// Evaluates the value of the compile time constant expression
// and returns a literal node for the value.
AstNode* Parser::FoldConstExpr(intptr_t expr_pos, AstNode* expr) {
  if (expr->IsLiteralNode()) {
    return expr;
  }
  if (expr->EvalConstExpr() == NULL) {
    ErrorMsg(expr_pos, "expression must be a compile-time constant");
  }
  return new LiteralNode(expr_pos, EvaluateConstExpr(expr));
}


// A compound assignment consists of a store and a load part. In order
// to control inputs with potential side effects, the store part stores any
// side effect creating inputs into locals. The load part reads then from
// those locals. If expr may have side effects, it will be split into two new
// left and right nodes. 'expr' becomes the right node, left node is returned as
// result.
AstNode* Parser::PrepareCompoundAssignmentNodes(AstNode** expr) {
  AstNode* node = *expr;
  if (node->IsLoadIndexedNode()) {
    LoadIndexedNode* left_node = node->AsLoadIndexedNode();
    LoadIndexedNode* right_node = left_node;
    intptr_t token_pos = node->token_pos();
    node = NULL;  // Do not use it.
    if (!IsSimpleLocalOrLiteralNode(left_node->array())) {
      LocalVariable* temp =
          CreateTempConstVariable(token_pos, "lia");
      StoreLocalNode* save =
          new StoreLocalNode(token_pos, temp, left_node->array());
      left_node = new LoadIndexedNode(token_pos,
                                      save,
                                      left_node->index_expr(),
                                      left_node->super_class());
      right_node = new LoadIndexedNode(token_pos,
                                       new LoadLocalNode(token_pos, temp),
                                       right_node->index_expr(),
                                       right_node->super_class());
    }
    if (!IsSimpleLocalOrLiteralNode(left_node->index_expr())) {
      LocalVariable* temp =
          CreateTempConstVariable(token_pos, "lix");
      StoreLocalNode* save =
          new StoreLocalNode(token_pos, temp, left_node->index_expr());
      left_node = new LoadIndexedNode(token_pos,
                                      left_node->array(),
                                      save,
                                      left_node->super_class());
      right_node = new LoadIndexedNode(token_pos,
                                       right_node->array(),
                                       new LoadLocalNode(token_pos, temp),
                                       right_node->super_class());
    }
    *expr = right_node;
    return left_node;
  }
  if (node->IsInstanceGetterNode()) {
    InstanceGetterNode* left_node = node->AsInstanceGetterNode();
    InstanceGetterNode* right_node = left_node;
    intptr_t token_pos = node->token_pos();
    node = NULL;  // Do not use it.
    if (!IsSimpleLocalOrLiteralNode(left_node->receiver())) {
      LocalVariable* temp =
          CreateTempConstVariable(token_pos, "igr");
      StoreLocalNode* save =
          new StoreLocalNode(token_pos, temp, left_node->receiver());
      left_node = new InstanceGetterNode(token_pos,
                                         save,
                                         left_node->field_name());
      right_node = new InstanceGetterNode(token_pos,
                                          new LoadLocalNode(token_pos, temp),
                                          right_node->field_name());
    }
    *expr = right_node;
    return left_node;
  }
  return *expr;
}


// Ensure that the expression temp is allocated for nodes that may need it.
AstNode* Parser::CreateAssignmentNode(AstNode* original, AstNode* rhs) {
  AstNode* result = original->MakeAssignmentNode(rhs);
  if ((result == NULL) && original->IsStaticGetterNode()) {
    const String& setter_name = String::ZoneHandle(
        Field::SetterSymbol(original->AsStaticGetterNode()->field_name()));
    result = ThrowNoSuchMethodError(original->token_pos(), setter_name);
  }
  // TODO(hausner): if we decide to throw a no such method error on
  // assignment to a final variable, we need to do the same as in the
  // StaticGetterNode above.
  if ((result != NULL) &&
      (result->IsStoreIndexedNode() ||
       result->IsInstanceSetterNode() ||
       result->IsStaticSetterNode() ||
       result->IsStoreStaticFieldNode() ||
       result->IsStoreLocalNode())) {
    EnsureExpressionTemp();
  }
  return result;
}


AstNode* Parser::ParseCascades(AstNode* expr) {
  intptr_t cascade_pos = TokenPos();
  LocalVariable* cascade_receiver_var =
      CreateTempConstVariable(cascade_pos, "casc");
  StoreLocalNode* save_cascade =
      new StoreLocalNode(cascade_pos, cascade_receiver_var, expr);
  current_block_->statements->Add(save_cascade);
  while (CurrentToken() == Token::kCASCADE) {
    cascade_pos = TokenPos();
    LoadLocalNode* load_cascade_receiver =
        new LoadLocalNode(cascade_pos, cascade_receiver_var);
    if (Token::IsIdentifier(LookaheadToken(1))) {
      // Replace .. with . for ParseSelectors().
      token_kind_ = Token::kPERIOD;
    } else if (LookaheadToken(1) == Token::kLBRACK) {
      ConsumeToken();
    } else {
      ErrorMsg("identifier or [ expected after ..");
    }
    expr = ParseSelectors(load_cascade_receiver, true);

    // Assignments after a cascade are part of the cascade. The
    // assigned expression must not contain cascades.
    if (Token::IsAssignmentOperator(CurrentToken())) {
      Token::Kind assignment_op = CurrentToken();
      const intptr_t assignment_pos = TokenPos();
      ConsumeToken();
      AstNode* right_expr = ParseExpr(kAllowConst, kNoCascades);
      AstNode* left_expr = expr;
      if (assignment_op != Token::kASSIGN) {
        // Compound assignment: store inputs with side effects into
        // temporary locals.
        left_expr = PrepareCompoundAssignmentNodes(&expr);
      }
      right_expr =
          ExpandAssignableOp(assignment_pos, assignment_op, expr, right_expr);
      AstNode* assign_expr = CreateAssignmentNode(left_expr, right_expr);
      if (assign_expr == NULL) {
        ErrorMsg(assignment_pos,
                 "left hand side of '%s' is not assignable",
                 Token::Str(assignment_op));
      }
      expr = assign_expr;
    }
    current_block_->statements->Add(expr);
  }
  // Result of the cascade is the receiver.
  return new LoadLocalNode(cascade_pos, cascade_receiver_var);
}


AstNode* Parser::ParseExpr(bool require_compiletime_const,
                           bool consume_cascades) {
  TRACE_PARSER("ParseExpr");
  const intptr_t expr_pos = TokenPos();

  if (CurrentToken() == Token::kTHROW) {
    ConsumeToken();
    ASSERT(CurrentToken() != Token::kSEMICOLON);
    AstNode* expr = ParseExpr(require_compiletime_const, consume_cascades);
    return new ThrowNode(expr_pos, expr, NULL);
  }
  AstNode* expr = ParseConditionalExpr();
  if (!Token::IsAssignmentOperator(CurrentToken())) {
    if ((CurrentToken() == Token::kCASCADE) && consume_cascades) {
      return ParseCascades(expr);
    }
    if (require_compiletime_const) {
      expr = FoldConstExpr(expr_pos, expr);
    }
    return expr;
  }
  // Assignment expressions.
  Token::Kind assignment_op = CurrentToken();
  const intptr_t assignment_pos = TokenPos();
  ConsumeToken();
  const intptr_t right_expr_pos = TokenPos();
  if (require_compiletime_const && (assignment_op != Token::kASSIGN)) {
    ErrorMsg(right_expr_pos, "expression must be a compile-time constant");
  }
  AstNode* right_expr = ParseExpr(require_compiletime_const, consume_cascades);
  AstNode* left_expr = expr;
  if (assignment_op != Token::kASSIGN) {
    // Compound assignment: store inputs with side effects into temp. locals.
    left_expr = PrepareCompoundAssignmentNodes(&expr);
  }
  right_expr =
      ExpandAssignableOp(assignment_pos, assignment_op, expr, right_expr);
  AstNode* assign_expr = CreateAssignmentNode(left_expr, right_expr);
  if (assign_expr == NULL) {
    ErrorMsg(assignment_pos,
             "left hand side of '%s' is not assignable",
             Token::Str(assignment_op));
  }
  return assign_expr;
}


LiteralNode* Parser::ParseConstExpr() {
  TRACE_PARSER("ParseConstExpr");
  AstNode* expr = ParseExpr(kRequireConst, kNoCascades);
  ASSERT(expr->IsLiteralNode());
  return expr->AsLiteralNode();
}


AstNode* Parser::ParseConditionalExpr() {
  TRACE_PARSER("ParseConditionalExpr");
  const intptr_t expr_pos = TokenPos();
  AstNode* expr = ParseBinaryExpr(Token::Precedence(Token::kOR));
  if (CurrentToken() == Token::kCONDITIONAL) {
    EnsureExpressionTemp();
    ConsumeToken();
    AstNode* expr1 = ParseExpr(kAllowConst, kNoCascades);
    ExpectToken(Token::kCOLON);
    AstNode* expr2 = ParseExpr(kAllowConst, kNoCascades);
    expr = new ConditionalExprNode(expr_pos, expr, expr1, expr2);
  }
  return expr;
}


AstNode* Parser::ParseUnaryExpr() {
  TRACE_PARSER("ParseUnaryExpr");
  AstNode* expr = NULL;
  const intptr_t op_pos = TokenPos();
  if (IsPrefixOperator(CurrentToken())) {
    Token::Kind unary_op = CurrentToken();
    if (unary_op == Token::kSUB) {
      unary_op = Token::kNEGATE;
    }
    ConsumeToken();
    expr = ParseUnaryExpr();
    if (unary_op == Token::kTIGHTADD) {
      // kTIGHADD is added only in front of a number literal.
      if (!expr->IsLiteralNode()) {
        ErrorMsg(op_pos, "unexpected operator '+'");
      }
      // Expression is the literal itself.
    } else if (expr->IsPrimaryNode() && (expr->AsPrimaryNode()->IsSuper())) {
      expr = BuildUnarySuperOperator(unary_op, expr->AsPrimaryNode());
    } else {
      expr = UnaryOpNode::UnaryOpOrLiteral(op_pos, unary_op, expr);
    }
  } else if (IsIncrementOperator(CurrentToken())) {
    Token::Kind incr_op = CurrentToken();
    ConsumeToken();
    expr = ParseUnaryExpr();
    if (!IsAssignableExpr(expr)) {
      ErrorMsg("expression is not assignable");
    }
    // Is prefix.
    AstNode* left_expr = PrepareCompoundAssignmentNodes(&expr);
    Token::Kind binary_op =
        (incr_op == Token::kINCR) ? Token::kADD : Token::kSUB;
    BinaryOpNode* add = new BinaryOpNode(
        op_pos,
        binary_op,
        expr,
        new LiteralNode(op_pos, Smi::ZoneHandle(Smi::New(1))));
    AstNode* store = CreateAssignmentNode(left_expr, add);
    ASSERT(store != NULL);
    expr = store;
  } else {
    expr = ParsePostfixExpr();
  }
  return expr;
}


ArgumentListNode* Parser::ParseActualParameters(
                              ArgumentListNode* implicit_arguments,
                              bool require_const) {
  TRACE_PARSER("ParseActualParameters");
  ASSERT(CurrentToken() == Token::kLPAREN);
  const bool saved_mode = SetAllowFunctionLiterals(true);
  ArgumentListNode* arguments;
  if (implicit_arguments == NULL) {
    arguments = new ArgumentListNode(TokenPos());
  } else {
    arguments = implicit_arguments;
  }
  const GrowableObjectArray& names =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  bool named_argument_seen = false;
  if (LookaheadToken(1) != Token::kRPAREN) {
    String& arg_name = String::Handle();
    do {
      ASSERT((CurrentToken() == Token::kLPAREN) ||
             (CurrentToken() == Token::kCOMMA));
      ConsumeToken();
      if (IsIdentifier() && (LookaheadToken(1) == Token::kCOLON)) {
        named_argument_seen = true;
        // The canonicalization of the argument descriptor array built in the
        // code generator requires that the names are symbols, i.e.
        // canonicalized strings.
        ASSERT(CurrentLiteral()->IsSymbol());
        for (int i = 0; i < names.Length(); i++) {
          arg_name ^= names.At(i);
          if (CurrentLiteral()->Equals(arg_name)) {
            ErrorMsg("duplicate named argument");
          }
        }
        names.Add(*CurrentLiteral());
        ConsumeToken();  // ident.
        ConsumeToken();  // colon.
      } else if (named_argument_seen) {
        ErrorMsg("named argument expected");
      }
      arguments->Add(ParseExpr(require_const, kConsumeCascades));
    } while (CurrentToken() == Token::kCOMMA);
  } else {
    ConsumeToken();
  }
  ExpectToken(Token::kRPAREN);
  SetAllowFunctionLiterals(saved_mode);
  if (named_argument_seen) {
    arguments->set_names(Array::Handle(Array::MakeArray(names)));
  }
  return arguments;
}


AstNode* Parser::ParseStaticCall(const Class& cls,
                                 const String& func_name,
                                 intptr_t ident_pos) {
  TRACE_PARSER("ParseStaticCall");
  const intptr_t call_pos = TokenPos();
  ASSERT(CurrentToken() == Token::kLPAREN);
  ArgumentListNode* arguments = ParseActualParameters(NULL, kAllowConst);
  const int num_arguments = arguments->length();
  const Function& func = Function::ZoneHandle(
      Resolver::ResolveStatic(cls,
                              func_name,
                              num_arguments,
                              arguments->names(),
                              Resolver::kIsQualified));
  if (func.IsNull()) {
    // Check if there is a static field of the same name, it could be a closure
    // and so we try and invoke the closure.
    AstNode* closure = NULL;
    const Field& field = Field::ZoneHandle(cls.LookupStaticField(func_name));
    Function& func = Function::ZoneHandle();
    if (field.IsNull()) {
      // No field, check if we have an explicit getter function.
      const String& getter_name =
          String::ZoneHandle(Field::GetterName(func_name));
      const int kNumArguments = 0;  // no arguments.
      const Array& kNoArgumentNames = Array::Handle();
      func = Resolver::ResolveStatic(cls,
                                     getter_name,
                                     kNumArguments,
                                     kNoArgumentNames,
                                     Resolver::kIsQualified);
      if (!func.IsNull()) {
        ASSERT(func.kind() != RawFunction::kConstImplicitGetter);
        EnsureExpressionTemp();
        closure = new StaticGetterNode(call_pos,
                                       NULL,
                                       false,
                                       Class::ZoneHandle(cls.raw()),
                                       func_name);
        return new ClosureCallNode(call_pos, closure, arguments);
      }
    } else {
      EnsureExpressionTemp();
      closure = GenerateStaticFieldLookup(field, call_pos);
      return new ClosureCallNode(call_pos, closure, arguments);
    }
    // Could not resolve static method: throw a NoSuchMethodError.
    return ThrowNoSuchMethodError(ident_pos, func_name);
  }
  CheckFunctionIsCallable(call_pos, func);
  return new StaticCallNode(call_pos, func, arguments);
}


AstNode* Parser::ParseInstanceCall(AstNode* receiver, const String& func_name) {
  TRACE_PARSER("ParseInstanceCall");
  const intptr_t call_pos = TokenPos();
  if (CurrentToken() != Token::kLPAREN) {
    ErrorMsg(call_pos, "left parenthesis expected");
  }
  ArgumentListNode* arguments = ParseActualParameters(NULL, kAllowConst);
  return new InstanceCallNode(call_pos, receiver, func_name, arguments);
}


AstNode* Parser::ParseClosureCall(AstNode* closure) {
  TRACE_PARSER("ParseClosureCall");
  const intptr_t call_pos = TokenPos();
  ASSERT(CurrentToken() == Token::kLPAREN);
  EnsureExpressionTemp();
  ArgumentListNode* arguments = ParseActualParameters(NULL, kAllowConst);
  return new ClosureCallNode(call_pos, closure, arguments);
}


AstNode* Parser::GenerateStaticFieldLookup(const Field& field,
                                           intptr_t ident_pos) {
  // If the static field has an initializer, initialize the field at compile
  // time, which is only possible if the field is const.
  AstNode* initializing_getter = RunStaticFieldInitializer(field);
  if (initializing_getter != NULL) {
    // The field is not yet initialized and could not be initialized at compile
    // time. The getter will initialize the field.
    return initializing_getter;
  }
  // The field is initialized.
  if (field.is_const()) {
    ASSERT(field.value() != Object::sentinel());
    ASSERT(field.value() != Object::transition_sentinel());
    return new LiteralNode(ident_pos, Instance::ZoneHandle(field.value()));
  }
  // Access the field directly.
  return new LoadStaticFieldNode(ident_pos, Field::ZoneHandle(field.raw()));
}


AstNode* Parser::ParseStaticFieldAccess(const Class& cls,
                                        const String& field_name,
                                        intptr_t ident_pos,
                                        bool consume_cascades) {
  TRACE_PARSER("ParseStaticFieldAccess");
  AstNode* access = NULL;
  const intptr_t call_pos = TokenPos();
  const Field& field = Field::ZoneHandle(cls.LookupStaticField(field_name));
  Function& func = Function::ZoneHandle();
  if (Token::IsAssignmentOperator(CurrentToken())) {
    // Make sure an assignment is legal.
    if (field.IsNull()) {
      // No field, check if we have an explicit setter function.
      const String& setter_name =
          String::ZoneHandle(Field::SetterName(field_name));
      const int kNumArguments = 1;  // value.
      const Array& kNoArgumentNames = Array::Handle();
      func = Resolver::ResolveStatic(cls,
                                     setter_name,
                                     kNumArguments,
                                     kNoArgumentNames,
                                     Resolver::kIsQualified);
      if (func.IsNull()) {
        // No field or explicit setter function, throw a NoSuchMethodError.
        return ThrowNoSuchMethodError(ident_pos, field_name);
      }

      // Explicit setter function for the field found, field does not exist.
      // Create a getter node first in case it is needed. If getter node
      // is used as part of, e.g., "+=", and the explicit getter does not
      // exist, and error will be reported by the code generator.
      access = new StaticGetterNode(call_pos,
                                    NULL,
                                    false,
                                    Class::ZoneHandle(cls.raw()),
                                    String::ZoneHandle(field_name.raw()));
    } else {
      // Field exists.
      if (field.is_final()) {
        // Field has been marked as final, report an error as the field
        // is not settable.
        ErrorMsg(ident_pos,
                 "field '%s' is const static, cannot assign to it",
                 field_name.ToCString());
      }
      access = GenerateStaticFieldLookup(field, TokenPos());
    }
  } else {  // Not Token::IsAssignmentOperator(CurrentToken()).
    if (field.IsNull()) {
      // No field, check if we have an explicit getter function.
      const String& getter_name =
          String::ZoneHandle(Field::GetterName(field_name));
      const int kNumArguments = 0;  // no arguments.
      const Array& kNoArgumentNames = Array::Handle();
      func = Resolver::ResolveStatic(cls,
                                     getter_name,
                                     kNumArguments,
                                     kNoArgumentNames,
                                     Resolver::kIsQualified);
      if (func.IsNull()) {
        // We might be referring to an implicit closure, check to see if
        // there is a function of the same name.
        func = cls.LookupStaticFunction(field_name);
        if (func.IsNull()) {
          // No field or explicit getter function, throw a NoSuchMethodError.
          return ThrowNoSuchMethodError(ident_pos, field_name);
        }
        access = CreateImplicitClosureNode(func, call_pos, NULL);
      } else {
        ASSERT(func.kind() != RawFunction::kConstImplicitGetter);
        access = new StaticGetterNode(call_pos,
                                      NULL,
                                      false,
                                      Class::ZoneHandle(cls.raw()),
                                      field_name);
      }
    } else {
      access = GenerateStaticFieldLookup(field, TokenPos());
    }
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
    String& name = String::CheckedZoneHandle(primary->primary().raw());
    if (current_function().is_static() ||
        current_function().IsInFactoryScope()) {
      return ThrowNoSuchMethodError(primary->token_pos(), name);
    } else {
      AstNode* receiver = LoadReceiver(primary->token_pos());
      return CallGetter(node->token_pos(), receiver, name);
    }
  }
  return primary;
}


AstNode* Parser::LoadClosure(PrimaryNode* primary) {
  ASSERT(primary->primary().IsFunction());
  AstNode* closure = NULL;
  const Function& func =
      Function::CheckedZoneHandle(primary->primary().raw());
  const String& funcname = String::ZoneHandle(func.name());
  if (func.is_static()) {
    // Static function access.
    closure = CreateImplicitClosureNode(func, primary->token_pos(), NULL);
  } else {
    // Instance function access.
    if (current_function().is_static() ||
        current_function().IsInFactoryScope()) {
      ErrorMsg(primary->token_pos(),
               "cannot access instance method '%s' from static method",
               funcname.ToCString());
    }
    AstNode* receiver = LoadReceiver(primary->token_pos());
    closure = CallGetter(primary->token_pos(), receiver, funcname);
  }
  return closure;
}


AstNode* Parser::ParseSelectors(AstNode* primary, bool is_cascade) {
  AstNode* left = primary;
  while (true) {
    AstNode* selector = NULL;
    if (CurrentToken() == Token::kPERIOD) {
      ConsumeToken();
      if (left->IsPrimaryNode()) {
        if (left->AsPrimaryNode()->primary().IsFunction()) {
          left = LoadClosure(left->AsPrimaryNode());
        } else {
          // Super field access handled in ParseSuperFieldAccess(),
          // super calls handled in ParseSuperCall().
          ASSERT(!left->AsPrimaryNode()->IsSuper());
          left = LoadFieldIfUnresolved(left);
        }
      }
      const intptr_t ident_pos = TokenPos();
      String* ident = ExpectIdentifier("identifier expected");
      if (CurrentToken() == Token::kLPAREN) {
        // Identifier followed by a opening paren: method call.
        if (left->IsPrimaryNode()
            && left->AsPrimaryNode()->primary().IsClass()) {
          // Static method call prefixed with class name.
          Class& cls = Class::CheckedHandle(
              left->AsPrimaryNode()->primary().raw());
          selector = ParseStaticCall(cls, *ident, ident_pos);
        } else {
          selector = ParseInstanceCall(left, *ident);
        }
      } else {
        // Field access.
        Class& cls = Class::Handle();
        if (left->IsPrimaryNode()) {
          PrimaryNode* primary_node = left->AsPrimaryNode();
          if (primary_node->primary().IsClass()) {
            // If the primary node referred to a class we are loading a
            // qualified static field.
            cls ^= primary_node->primary().raw();
          }
        }
        if (cls.IsNull()) {
          // Instance field access.
          selector = CallGetter(ident_pos, left, *ident);
        } else {
          // Static field access.
          selector =
              ParseStaticFieldAccess(cls, *ident, ident_pos, !is_cascade);
        }
      }
    } else if (CurrentToken() == Token::kLBRACK) {
      // Super index operator handled in ParseSuperOperator().
      ASSERT(!left->IsPrimaryNode() || !left->AsPrimaryNode()->IsSuper());

      const intptr_t bracket_pos = TokenPos();
      ConsumeToken();
      left = LoadFieldIfUnresolved(left);
      const bool saved_mode = SetAllowFunctionLiterals(true);
      AstNode* index = ParseExpr(kAllowConst, kConsumeCascades);
      SetAllowFunctionLiterals(saved_mode);
      ExpectToken(Token::kRBRACK);
      AstNode* array = left;
      if (left->IsPrimaryNode()) {
        PrimaryNode* primary = left->AsPrimaryNode();
        if (primary->primary().IsFunction()) {
          array = LoadClosure(primary);
        } else if (primary->primary().IsClass()) {
          ErrorMsg(bracket_pos, "cannot apply index operator to class");
        } else {
          UNREACHABLE();  // Internal parser error.
        }
      }
      selector =  new LoadIndexedNode(bracket_pos,
                                      array,
                                      index,
                                      Class::ZoneHandle());
    } else if (CurrentToken() == Token::kLPAREN) {
      if (left->IsPrimaryNode()) {
        PrimaryNode* primary = left->AsPrimaryNode();
        const intptr_t primary_pos = primary->token_pos();
        if (primary->primary().IsFunction()) {
          Function& func = Function::CheckedHandle(primary->primary().raw());
          String& func_name = String::ZoneHandle(func.name());
          if (func.is_static()) {
            // Parse static function call.
            Class& cls = Class::Handle(func.Owner());
            selector = ParseStaticCall(cls, func_name, primary_pos);
          } else {
            // Dynamic function call on implicit "this" parameter.
            if (current_function().is_static()) {
              ErrorMsg(primary_pos,
                       "cannot access instance method '%s' "
                       "from static function",
                       func_name.ToCString());
            }
            selector = ParseInstanceCall(LoadReceiver(primary_pos), func_name);
          }
        } else if (primary->primary().IsString()) {
          // Primary is an unresolved name.
          if (primary->IsSuper()) {
            ErrorMsg(primary->token_pos(), "illegal use of super");
          }
          String& name = String::CheckedZoneHandle(primary->primary().raw());
          if (current_function().is_static()) {
            selector = ThrowNoSuchMethodError(primary->token_pos(), name);
          } else {
            // Treat as call to unresolved (instance) method.
            AstNode* receiver = LoadReceiver(primary->token_pos());
            selector = ParseInstanceCall(receiver, name);
          }
        } else if (primary->primary().IsClass()) {
          ErrorMsg(left->token_pos(),
                   "must use 'new' or 'const' to construct new instance");
        } else {
          UNREACHABLE();  // Internal parser error.
        }
      } else {
        // Left is not a primary node; this must be a closure call.
        AstNode* closure = left;
        selector = ParseClosureCall(closure);
      }
    } else {
      // No (more) selectors to parse.
      left = LoadFieldIfUnresolved(left);
      if (left->IsPrimaryNode()) {
        PrimaryNode* primary = left->AsPrimaryNode();
        if (primary->primary().IsFunction()) {
          // Treat as implicit closure.
          left = LoadClosure(primary);
        } else if (left->AsPrimaryNode()->primary().IsClass()) {
          Class& cls = Class::CheckedHandle(
              left->AsPrimaryNode()->primary().raw());
          String& cls_name = String::Handle(cls.Name());
          ErrorMsg(left->token_pos(),
                   "illegal use of class name '%s'",
                   cls_name.ToCString());
        } else if (primary->IsSuper()) {
          // Return "super" to handle unary super operator calls,
          // or to report illegal use of "super" otherwise.
          left = primary;
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
  const intptr_t postfix_expr_pos = TokenPos();
  AstNode* postfix_expr = ParsePrimary();
  postfix_expr = ParseSelectors(postfix_expr, false);
  if (IsIncrementOperator(CurrentToken())) {
    TRACE_PARSER("IncrementOperator");
    Token::Kind incr_op = CurrentToken();
    if (!IsAssignableExpr(postfix_expr)) {
      ErrorMsg("expression is not assignable");
    }
    ConsumeToken();
    // Not prefix.
    AstNode* left_expr = PrepareCompoundAssignmentNodes(&postfix_expr);
    const LocalVariable* temp = GetIncrementTempLocal();
    AstNode* save =
        new StoreLocalNode(postfix_expr_pos, temp, postfix_expr);
    Token::Kind binary_op =
        (incr_op == Token::kINCR) ? Token::kADD : Token::kSUB;
    BinaryOpNode* add = new BinaryOpNode(
        postfix_expr_pos,
        binary_op,
        save,
        new LiteralNode(postfix_expr_pos, Smi::ZoneHandle(Smi::New(1))));
    AstNode* store = CreateAssignmentNode(left_expr, add);
    LoadLocalNode* load_res =
        new LoadLocalNode(postfix_expr_pos, temp, store);
    return load_res;
  }
  return postfix_expr;
}


// Resolve the given type and its type arguments from the given scope class
// according to the given type finalization mode.
// If the given scope class is null, use the current library, but do not try to
// resolve type parameters.
// Not all involved type classes may get resolved yet, but at least the type
// parameters of the given class will get resolved, thereby relieving the class
// finalizer from resolving type parameters out of context.
void Parser::ResolveTypeFromClass(const Class& scope_class,
                                  ClassFinalizer::FinalizationKind finalization,
                                  AbstractType* type) {
  ASSERT(finalization >= ClassFinalizer::kTryResolve);
  ASSERT(type != NULL);
  if (type->IsResolved()) {
    return;
  }
  // Resolve class.
  if (!type->HasResolvedTypeClass()) {
    const UnresolvedClass& unresolved_class =
        UnresolvedClass::Handle(type->unresolved_class());
    const String& unresolved_class_name =
        String::Handle(unresolved_class.ident());
    Class& resolved_type_class = Class::Handle();
    if (unresolved_class.library_prefix() == LibraryPrefix::null()) {
      if (!scope_class.IsNull()) {
        // First check if the type is a type parameter of the given scope class.
        const TypeParameter& type_parameter = TypeParameter::Handle(
            scope_class.LookupTypeParameter(unresolved_class_name,
                                            type->token_pos()));
        if (!type_parameter.IsNull()) {
          // A type parameter is considered to be a malformed type when
          // referenced by a static member.
          if (ParsingStaticMember()) {
            ASSERT(scope_class.raw() == current_class().raw());
            *type = ClassFinalizer::NewFinalizedMalformedType(
                Error::Handle(),  // No previous error.
                scope_class,
                type->token_pos(),
                finalization,
                "type parameter '%s' cannot be referenced "
                "from static member",
                String::Handle(type_parameter.name()).ToCString());
            return;
          }
          // A type parameter cannot be parameterized, so make the type
          // malformed if type arguments have previously been parsed.
          if (!AbstractTypeArguments::Handle(type->arguments()).IsNull()) {
            *type = ClassFinalizer::NewFinalizedMalformedType(
                Error::Handle(),  // No previous error.
                scope_class,
                type_parameter.token_pos(),
                finalization,
                "type parameter '%s' cannot be parameterized",
                String::Handle(type_parameter.name()).ToCString());
            return;
          }
          *type = type_parameter.raw();
          return;
        }
      }
      // Resolve classname in the scope of the current library.
      Error& error = Error::Handle();
      // If we finalize a type expression, as opposed to a type annotation, we
      // tell the resolver (by passing NULL) to immediately report an ambiguous
      // type as a compile time error.
      resolved_type_class = ResolveClassInCurrentLibraryScope(
          unresolved_class.token_pos(),
          unresolved_class_name,
          finalization >= ClassFinalizer::kCanonicalizeExpression ?
              NULL : &error);
      if (!error.IsNull()) {
        *type = ClassFinalizer::NewFinalizedMalformedType(
            error,
            scope_class,
            unresolved_class.token_pos(),
            finalization,
            "cannot resolve class '%s'",
            unresolved_class_name.ToCString());
        return;
      }
    } else {
      LibraryPrefix& lib_prefix =
          LibraryPrefix::Handle(unresolved_class.library_prefix());
      // Resolve class name in the scope of the library prefix.
      Error& error = Error::Handle();
      // If we finalize a type expression, as opposed to a type annotation, we
      // tell the resolver (by passing NULL) to immediately report an ambiguous
      // type as a compile time error.
      resolved_type_class = ResolveClassInPrefixScope(
          unresolved_class.token_pos(),
          lib_prefix,
          unresolved_class_name,
          finalization >= ClassFinalizer::kCanonicalizeExpression ?
              NULL : &error);
      if (!error.IsNull()) {
        *type = ClassFinalizer::NewFinalizedMalformedType(
            error,
            scope_class,
            unresolved_class.token_pos(),
            finalization,
            "cannot resolve class '%s'",
            unresolved_class_name.ToCString());
        return;
      }
    }
    // At this point, we can only have a parameterized_type.
    Type& parameterized_type = Type::Handle();
    parameterized_type ^= type->raw();
    if (!resolved_type_class.IsNull()) {
      // Replace unresolved class with resolved type class.
      parameterized_type.set_type_class(resolved_type_class);
    } else if (finalization >= ClassFinalizer::kCanonicalize) {
      // The type is malformed.
      ClassFinalizer::FinalizeMalformedType(
          Error::Handle(),  // No previous error.
          current_class(), parameterized_type, finalization,
          "type '%s' is not loaded",
          String::Handle(parameterized_type.UserVisibleName()).ToCString());
    }
  }
  // Resolve type arguments, if any.
  const AbstractTypeArguments& arguments =
      AbstractTypeArguments::Handle(type->arguments());
  if (!arguments.IsNull()) {
    const intptr_t num_arguments = arguments.Length();
    for (intptr_t i = 0; i < num_arguments; i++) {
      AbstractType& type_argument = AbstractType::Handle(arguments.TypeAt(i));
      ResolveTypeFromClass(scope_class, finalization, &type_argument);
      arguments.SetTypeAt(i, type_argument);
    }
  }
}


LocalVariable* Parser::LookupLocalScope(const String& ident) {
  if (current_block_ == NULL) {
    return NULL;
  }
  // A found name is treated as accessed and possibly marked as captured.
  const bool kTestOnly = false;
  return current_block_->scope->LookupVariable(ident, kTestOnly);
}


// Returns true if ident resolves to a formal parameter of the current function
// or of one of its enclosing functions.
// Make sure not to capture the formal parameter, since it is not accessed.
bool Parser::IsFormalParameter(const String& ident,
                               Function* owner_function,
                               LocalScope** owner_scope,
                               intptr_t* local_index) {
  if (current_block_ == NULL) {
    return false;
  }
  if (ident.Equals(String::Handle(Symbols::This()))) {
    // 'this' is not a formal parameter.
    return false;
  }
  // Since an argument definition test does not use the value of the formal
  // parameter, there is no reason to capture it.
  const bool kTestOnly = true;  // No capturing.
  LocalVariable* local =
      current_block_->scope->LookupVariable(ident, kTestOnly);
  if (local == NULL) {
    if (!current_function().IsLocalFunction()) {
      // We are not generating code for a local function, so all locals,
      // captured or not, are in scope. However, 'ident' was not found, so it
      // does not exist.
      return false;
    }
    // The formal parameter may belong to an enclosing function and may not have
    // been captured, so it was not included in the context scope and it cannot
    // be found by LookupVariable.
    // 'ident' necessarily refers to the formal parameter of one of the
    // enclosing functions, or a compile error would have prevented the
    // outermost enclosing function to be executed and we would not be compiling
    // this local function.
    // Therefore, look for ident directly in the formal parameter lists of the
    // enclosing functions.
    // There is no need to return the owner_scope, since the caller will not
    // create the saved_arguments_descriptor variable, which already exists.
    Function& function = Function::Handle(innermost_function().raw());
    String& param_name = String::Handle();
    do {
      const int num_parameters = function.NumParameters();
      for (intptr_t i = 0; i < num_parameters; i++) {
        param_name = function.ParameterNameAt(i);
        if (ident.Equals(param_name)) {
          *owner_function = function.raw();
          *owner_scope = NULL;
          *local_index = i;
          return true;
        }
      }
      function = function.parent_function();
    } while (!function.IsNull());
    UNREACHABLE();
  }
  // Verify that local is a formal parameter of the current function or of one
  // of its enclosing functions.
  // Note that scopes are not yet associated to functions.
  Function& function = Function::Handle(innermost_function().raw());
  LocalScope* scope = current_block_->scope;
  while (scope != NULL) {
    ASSERT(!function.IsNull());
    // Find the top scope for this function level.
    while ((scope->parent() != NULL) &&
           (scope->parent()->function_level() == scope->function_level())) {
      scope = scope->parent();
    }
    if (scope == local->owner()) {
      // Scope contains 'local' and the formal parameters of 'function'.
      const int num_parameters = function.NumParameters();
      for (intptr_t i = 0; i < num_parameters; i++) {
        if (scope->VariableAt(i) == local) {
          *owner_function = function.raw();
          *owner_scope = scope;
          *local_index = i;
          return true;
        }
      }
      // The variable 'local' is not a formal parameter.
      return false;
    }
    scope = scope->parent();
    function = function.parent_function();
  }
  // The variable 'local' does not belong to a function top scope.
  return false;
}


void Parser::CheckInstanceFieldAccess(intptr_t field_pos,
                                      const String& field_name) {
  // Fields are not accessible from a static function, except from a
  // constructor, which is considered as non-static by the compiler.
  if (current_function().is_static()) {
    ErrorMsg(field_pos,
             "cannot access instance field '%s' from a static function",
             field_name.ToCString());
  }
}


bool Parser::ParsingStaticMember() const {
  if (is_top_level_) {
    return (current_member_ != NULL) &&
           current_member_->has_static && !current_member_->has_factory;
  }
  ASSERT(!current_function().IsNull());
  return
      current_function().is_static() && !current_function().IsInFactoryScope();
}


const Type* Parser::ReceiverType(intptr_t type_pos) const {
  ASSERT(!current_class().IsNull());
  TypeArguments& type_arguments = TypeArguments::Handle();
  if (current_class().NumTypeParameters() > 0) {
    type_arguments = current_class().type_parameters();
  }
  Type& type = Type::ZoneHandle(
       Type::New(current_class(), type_arguments, type_pos));
  if (!is_top_level_) {
    type ^= ClassFinalizer::FinalizeType(
        current_class(), type, ClassFinalizer::kCanonicalizeWellFormed);
  }
  return &type;
}


bool Parser::IsInstantiatorRequired() const {
  ASSERT(!current_function().IsNull());
  if (current_function().is_static() &&
      !current_function().IsInFactoryScope()) {
    return false;
  }
  return current_class().NumTypeParameters() > 0;
}


// If the field is already initialized, return no ast (NULL).
// Otherwise, if the field is constant, initialize the field and return no ast.
// If the field is not initialized and not const, return the ast for the getter.
AstNode* Parser::RunStaticFieldInitializer(const Field& field) {
  ASSERT(field.is_static());
  const Instance& value = Instance::Handle(field.value());
  if (value.raw() == Object::transition_sentinel()) {
    if (field.is_const()) {
      ErrorMsg("circular dependency while initializing static field '%s'",
               String::Handle(field.name()).ToCString());
    } else {
      // The implicit static getter will throw the exception if necessary.
      return new StaticGetterNode(TokenPos(),
                                  NULL,
                                  false,
                                  Class::ZoneHandle(field.owner()),
                                  String::ZoneHandle(field.name()));
    }
  } else if (value.raw() == Object::sentinel()) {
    // This field has not been referenced yet and thus the value has
    // not been evaluated. If the field is const, call the static getter method
    // to evaluate the expression and canonicalize the value.
    if (field.is_const()) {
      field.set_value(Instance::Handle(Object::transition_sentinel()));
      const String& field_name = String::Handle(field.name());
      const String& getter_name =
          String::Handle(Field::GetterName(field_name));
      const Class& cls = Class::Handle(field.owner());
      GrowableArray<const Object*> arguments;  // no arguments.
      const int kNumArguments = 0;  // no arguments.
      const Array& kNoArgumentNames = Array::Handle();
      const Function& func =
          Function::Handle(Resolver::ResolveStatic(cls,
                                                   getter_name,
                                                   kNumArguments,
                                                   kNoArgumentNames,
                                                   Resolver::kIsQualified));
      ASSERT(!func.IsNull());
      ASSERT(func.kind() == RawFunction::kConstImplicitGetter);
      Object& const_value = Object::Handle(
          DartEntry::InvokeStatic(func, arguments, kNoArgumentNames));
      if (const_value.IsError()) {
        const Error& error = Error::Cast(const_value);
        if (error.IsUnhandledException()) {
          field.set_value(Instance::Handle());
          // It is a compile-time error if evaluation of a compile-time constant
          // would raise an exception.
          AppendErrorMsg(error, TokenPos(),
                         "error initializing const field '%s'",
                         String::Handle(field.name()).ToCString());
        } else {
          Isolate::Current()->long_jump_base()->Jump(1, error);
        }
      }
      ASSERT(const_value.IsNull() || const_value.IsInstance());
      Instance& instance = Instance::Handle();
      instance ^= const_value.raw();
      if (!instance.IsNull()) {
        instance ^= instance.Canonicalize();
      }
      field.set_value(instance);
    } else {
      return new StaticGetterNode(TokenPos(),
                                  NULL,
                                  false,
                                  Class::ZoneHandle(field.owner()),
                                  String::ZoneHandle(field.name()));
    }
  }
  return NULL;
}


RawObject* Parser::EvaluateConstConstructorCall(
    const Class& type_class,
    const AbstractTypeArguments& type_arguments,
    const Function& constructor,
    ArgumentListNode* arguments) {
  // +2 for implicit receiver and construction phase arguments.
  GrowableArray<const Object*> arg_values(arguments->length() + 2);
  Instance& instance = Instance::Handle();
  ASSERT(!constructor.IsFactory());
  instance = Instance::New(type_class, Heap::kOld);
  if (!type_arguments.IsNull()) {
    if (!type_arguments.IsInstantiated()) {
      ErrorMsg("type must be constant in const constructor");
    }
    instance.SetTypeArguments(
        AbstractTypeArguments::Handle(type_arguments.Canonicalize()));
  }
  arg_values.Add(&instance);
  arg_values.Add(&Smi::ZoneHandle(Smi::New(Function::kCtorPhaseAll)));
  for (int i = 0; i < arguments->length(); i++) {
    AstNode* arg = arguments->NodeAt(i);
    // Arguments have been evaluated to a literal value already.
    ASSERT(arg->IsLiteralNode());
    arg_values.Add(&arg->AsLiteralNode()->literal());
  }
  const Array& opt_arg_names = arguments->names();
  const Object& result = Object::Handle(
      DartEntry::InvokeStatic(constructor, arg_values, opt_arg_names));
  if (result.IsError()) {
      if (result.IsUnhandledException()) {
        return result.raw();
      } else {
        Isolate::Current()->long_jump_base()->Jump(1, Error::Cast(result));
        UNREACHABLE();
        return Object::null();
      }
  } else {
    if (!instance.IsNull()) {
      instance ^= instance.Canonicalize();
    }
    return instance.raw();
  }
}


// Do a lookup for the identifier in the block scope and the class scope
// return true if the identifier is found, false otherwise.
// If node is non NULL return an AST node corresponding to the identifier.
bool Parser::ResolveIdentInLocalScope(intptr_t ident_pos,
                                      const String &ident,
                                      AstNode** node) {
  TRACE_PARSER("ResolveIdentInLocalScope");
  Isolate* isolate = Isolate::Current();
  // First try to find the identifier in the nested local scopes.
  LocalVariable* local = LookupLocalScope(ident);
  if (local != NULL) {
    if (node != NULL) {
      if (local->IsConst()) {
        *node = new LiteralNode(ident_pos, *local->ConstValue());
      } else {
        *node = new LoadLocalNode(ident_pos, local);
      }
    }
    return true;
  }

  // Try to find the identifier in the class scope of the current class.
  Class& cls = Class::Handle(isolate, current_class().raw());
  Function& func = Function::Handle(isolate, Function::null());
  Field& field = Field::Handle(isolate, Field::null());

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
    return true;
  }

  // Check if an instance/static function exists.
  func = cls.LookupFunction(ident);
  if (!func.IsNull() &&
      (func.IsDynamicFunction() || func.IsStaticFunction())) {
    if (node != NULL) {
      *node = new PrimaryNode(ident_pos,
                              Function::ZoneHandle(isolate, func.raw()));
    }
    return true;
  }

  // Now check if a getter/setter method exists for it in which case
  // it is still a field.
  func = cls.LookupGetterFunction(ident);
  if (!func.IsNull()) {
    if (func.IsDynamicFunction()) {
      if (node != NULL) {
        CheckInstanceFieldAccess(ident_pos, ident);
        ASSERT(AbstractType::Handle(func.result_type()).IsResolved());
        *node = CallGetter(ident_pos, LoadReceiver(ident_pos), ident);
      }
      return true;
    } else if (func.IsStaticFunction()) {
      if (node != NULL) {
        ASSERT(AbstractType::Handle(func.result_type()).IsResolved());
        // The static getter may later be changed into a dynamically
        // resolved instance setter if no static setter can
        // be found.
        AstNode* receiver = NULL;
        const bool kTestOnly = true;
        ASSERT(!current_function().IsInFactoryScope());
        if (!current_function().is_static() &&
            (LookupReceiver(current_block_->scope, kTestOnly) != NULL)) {
          receiver = LoadReceiver(ident_pos);
        }
        *node = new StaticGetterNode(ident_pos,
                                     receiver,
                                     false,
                                     Class::ZoneHandle(isolate, cls.raw()),
                                     ident);
      }
      return true;
    }
  }
  func = cls.LookupSetterFunction(ident);
  if (!func.IsNull()) {
    if (func.IsDynamicFunction()) {
      if (node != NULL) {
        // We create a getter node even though a getter doesn't exist as
        // it could be followed by an assignment which will convert it to
        // a setter node. If there is no assignment we will get an error
        // when we try to invoke the getter.
        CheckInstanceFieldAccess(ident_pos, ident);
        ASSERT(AbstractType::Handle(func.result_type()).IsResolved());
        *node = CallGetter(ident_pos, LoadReceiver(ident_pos), ident);
      }
      return true;
    } else if (func.IsStaticFunction()) {
      if (node != NULL) {
        // We create a getter node even though a getter doesn't exist as
        // it could be followed by an assignment which will convert it to
        // a setter node. If there is no assignment we will get an error
        // when we try to invoke the getter.
        *node = new StaticGetterNode(ident_pos,
                                     NULL,
                                     false,
                                     Class::ZoneHandle(isolate, cls.raw()),
                                     ident);
      }
      return true;
    }
  }

  // Nothing found in scope of current class.
  if (node != NULL) {
    *node = NULL;
  }
  return false;  // Not an unqualified identifier.
}


static RawObject* LookupNameInLibrary(const Library& lib, const String& name) {
  Object& obj = Object::Handle();
  obj = lib.LookupLocalObject(name);
  if (!obj.IsNull()) {
    return obj.raw();
  }
  String& accessor_name = String::Handle(Field::GetterName(name));
  obj = lib.LookupLocalObject(accessor_name);
  if (!obj.IsNull()) {
    return obj.raw();
  }
  accessor_name = Field::SetterName(name);
  obj = lib.LookupLocalObject(accessor_name);
  return obj.raw();
}


static RawObject* LookupNameInImport(const Namespace& ns, const String& name) {
  Object& obj = Object::Handle();
  obj = ns.Lookup(name);
  if (!obj.IsNull()) {
    return obj.raw();
  }
  // If the given name is filtered out by the import, don't look up the
  // getter and setter names.
  if (ns.HidesName(name)) {
    return Object::null();
  }
  String& accessor_name = String::Handle(Field::GetterName(name));
  obj = ns.Lookup(accessor_name);
  if (!obj.IsNull()) {
    return obj.raw();
  }
  accessor_name = Field::SetterName(name);
  obj = ns.Lookup(accessor_name);
  return obj.raw();
}


// Resolve a name by checking the global scope of the current
// library. If not found in the current library, then look in the scopes
// of all libraries that are imported without a library prefix.
// Issue an error if the name is not found in the global scope
// of the current library, but is defined in more than one imported
// library, i.e. if the name cannot be resolved unambiguously.
RawObject* Parser::ResolveNameInCurrentLibraryScope(intptr_t ident_pos,
                                                    const String& name,
                                                    Error* error) {
  TRACE_PARSER("ResolveNameInCurrentLibraryScope");
  Object& obj = Object::Handle(LookupNameInLibrary(library_, name));
  if (obj.IsNull()) {
    // Name is not found in current library. Check scope of all
    // imported libraries.
    String& first_lib_url = String::Handle();
    Namespace& import = Namespace::Handle();
    intptr_t num_imports = library_.num_imports();
    Object& imported_obj = Object::Handle();
    for (int i = 0; i < num_imports; i++) {
      import ^= library_.ImportAt(i);
      imported_obj = LookupNameInImport(import, name);
      if (!imported_obj.IsNull()) {
        const Library& lib = Library::Handle(import.library());
        if (!first_lib_url.IsNull()) {
          // Found duplicate definition.
          Error& ambiguous_ref_error = Error::Handle();
          if (first_lib_url.raw() == lib.url()) {
            ambiguous_ref_error = FormatErrorMsg(
                script_, ident_pos, "Error",
                "ambiguous reference: "
                "'%s' as library '%s' is imported multiple times",
                name.ToCString(),
                first_lib_url.ToCString());
          } else {
            ambiguous_ref_error = FormatErrorMsg(
                script_, ident_pos, "Error",
                "ambiguous reference: "
                "'%s' is defined in library '%s' and also in '%s'",
                name.ToCString(),
                first_lib_url.ToCString(),
                String::Handle(lib.url()).ToCString());
          }
          if (error == NULL) {
            // Report a compile time error since the caller is not interested
            // in the error.
            ErrorMsg(ambiguous_ref_error);
          }
          *error = ambiguous_ref_error.raw();
          return Object::null();
        } else {
          first_lib_url = lib.url();
          obj = imported_obj.raw();
        }
      }
    }
  }
  return obj.raw();
}


RawClass* Parser::ResolveClassInCurrentLibraryScope(intptr_t ident_pos,
                                                    const String& name,
                                                    Error* error) {
  const Object& obj =
      Object::Handle(ResolveNameInCurrentLibraryScope(ident_pos, name, error));
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  return Class::null();
}


// Resolve an identifier by checking the global scope of the current
// library. If not found in the current library, then look in the scopes
// of all libraries that are imported without a library prefix.
// Issue an error if the identifier is not found in the global scope
// of the current library, but is defined in more than one imported
// library, i.e. if the identifier cannot be resolved unambiguously.
AstNode* Parser::ResolveIdentInCurrentLibraryScope(intptr_t ident_pos,
                                                   const String& ident) {
  TRACE_PARSER("ResolveIdentInCurrentLibraryScope");
  const Object& obj =
    Object::Handle(ResolveNameInCurrentLibraryScope(ident_pos, ident, NULL));
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    return new PrimaryNode(ident_pos, Class::ZoneHandle(cls.raw()));
  } else if (obj.IsField()) {
    const Field& field = Field::Cast(obj);
    ASSERT(field.is_static());
    return GenerateStaticFieldLookup(field, ident_pos);
  } else if (obj.IsFunction()) {
    const Function& func = Function::Cast(obj);
    ASSERT(func.is_static());
    if (func.IsGetterFunction() || func.IsSetterFunction()) {
      return new StaticGetterNode(ident_pos,
                                  /* receiver */ NULL,
                                  /* is_super_getter */ false,
                                  Class::ZoneHandle(func.Owner()),
                                  ident);

    } else {
      return new PrimaryNode(ident_pos, Function::ZoneHandle(func.raw()));
    }
  } else {
    ASSERT(obj.IsNull() || obj.IsLibraryPrefix());
  }
  // Lexically unresolved primary identifiers are referenced by their name.
  return new PrimaryNode(ident_pos, ident);
}


RawObject* Parser::ResolveNameInPrefixScope(intptr_t ident_pos,
                                            const LibraryPrefix& prefix,
                                            const String& name,
                                            Error* error) {
  TRACE_PARSER("ResolveNameInPrefixScope");
  Namespace& import = Namespace::Handle();
  String& first_lib_url = String::Handle();
  Object& obj = Object::Handle();
  Object& resolved_obj = Object::Handle();
  const Array& imports = Array::Handle(prefix.imports());
  for (intptr_t i = 0; i < prefix.num_imports(); i++) {
    import ^= imports.At(i);
    resolved_obj = LookupNameInImport(import, name);
    if (!resolved_obj.IsNull()) {
      obj = resolved_obj.raw();
      const Library& lib = Library::Handle(import.library());
      if (first_lib_url.IsNull()) {
        first_lib_url = lib.url();
      } else {
        // Found duplicate definition.
        Error& ambiguous_ref_error = Error::Handle();
        if (first_lib_url.raw() == lib.url()) {
          ambiguous_ref_error = FormatErrorMsg(
              script_, ident_pos, "Error",
              "ambiguous reference: '%s.%s' is imported multiple times",
              String::Handle(prefix.name()).ToCString(),
              name.ToCString());
        } else {
          ambiguous_ref_error = FormatErrorMsg(
              script_, ident_pos, "Error",
              "ambiguous reference: '%s.%s' is defined in '%s' and '%s'",
              String::Handle(prefix.name()).ToCString(),
              name.ToCString(),
              first_lib_url.ToCString(),
              String::Handle(lib.url()).ToCString());
        }
        if (error == NULL) {
          // Report a compile time error since the caller is not interested
          // in the error.
          ErrorMsg(ambiguous_ref_error);
        }
        *error = ambiguous_ref_error.raw();
        return Object::null();
      }
    }
  }
  return obj.raw();
}


RawClass* Parser::ResolveClassInPrefixScope(intptr_t ident_pos,
                                            const LibraryPrefix& prefix,
                                            const String& name,
                                            Error* error) {
  const Object& obj =
      Object::Handle(ResolveNameInPrefixScope(ident_pos, prefix, name, error));
  if (obj.IsClass()) {
    return Class::Cast(obj).raw();
  }
  return Class::null();
}


// Do a lookup for the identifier in the scope of the specified
// library prefix. This means trying to resolve it locally in all of the
// libraries present in the library prefix. If there are multiple libraries
// with the name, issue an ambiguous reference error.
AstNode* Parser::ResolveIdentInPrefixScope(intptr_t ident_pos,
                                           const LibraryPrefix& prefix,
                                           const String& ident) {
  TRACE_PARSER("ResolveIdentInPrefixScope");
  Object& obj =
      Object::Handle(ResolveNameInPrefixScope(ident_pos, prefix, ident, NULL));
  if (obj.IsNull()) {
    // Unresolved prefixed primary identifier.
    ErrorMsg(ident_pos, "identifier '%s.%s' cannot be resolved",
             String::Handle(prefix.name()).ToCString(),
             ident.ToCString());
  }
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    return new PrimaryNode(ident_pos, Class::ZoneHandle(cls.raw()));
  } else if (obj.IsField()) {
    const Field& field = Field::Cast(obj);
    ASSERT(field.is_static());
    return GenerateStaticFieldLookup(field, ident_pos);
  } else if (obj.IsFunction()) {
    const Function& func = Function::Cast(obj);
    ASSERT(func.is_static());
    if (func.IsGetterFunction() || func.IsSetterFunction()) {
      return new StaticGetterNode(ident_pos,
                                  /* receiver */ NULL,
                                  /* is_super_getter */ false,
                                  Class::ZoneHandle(func.Owner()),
                                  ident);

    } else {
      return new PrimaryNode(ident_pos, Function::ZoneHandle(func.raw()));
    }
  } else {
    // TODO(hausner): Should this be an error? It is not meaningful to
    // reference a library prefix defined in an imported library.
    ASSERT(obj.IsLibraryPrefix());
  }
  // Lexically unresolved primary identifiers are referenced by their name.
  return new PrimaryNode(ident_pos, ident);
}


// Resolve identifier, issue an error message if the name refers to
// a class/interface or a type parameter. Issue an error message if
// the ident refers to a method and allow_closure_names is false.
// If the name cannot be resolved, turn it into an instance field access
// if we're compiling an instance method, or issue an error message
// if we're compiling a static method.
AstNode* Parser::ResolveIdent(intptr_t ident_pos,
                              const String& ident,
                              bool allow_closure_names) {
  TRACE_PARSER("ResolveIdent");
  // First try to find the variable in the local scope (block scope or
  // class scope).
  AstNode* resolved = NULL;
  ResolveIdentInLocalScope(ident_pos, ident, &resolved);
  if (resolved == NULL) {
    // Check whether the identifier is a type parameter. Type parameters
    // can never be used in primary expressions.
    if (!current_class().IsNull()) {
      TypeParameter& type_param = TypeParameter::Handle(
          current_class().LookupTypeParameter(ident, ident_pos));
      if (!type_param.IsNull()) {
        String& type_param_name = String::Handle(type_param.name());
        ErrorMsg(ident_pos, "illegal use of type parameter %s",
                 type_param_name.ToCString());
      }
    }
    // Not found in the local scope, and the name is not a type parameter.
    // Try finding the variable in the library scope (current library
    // and all libraries imported by it without a library prefix).
    resolved = ResolveIdentInCurrentLibraryScope(ident_pos, ident);
  }
  if (resolved->IsPrimaryNode()) {
    PrimaryNode* primary = resolved->AsPrimaryNode();
    if (primary->primary().IsString()) {
      // We got an unresolved name. If we are compiling a static
      // method, evaluation of an unresolved identifier causes a
      // NoSuchMethodError to be thrown. In an instance method, we convert
      // the unresolved name to an instance field access, since a
      // subclass might define a field with this name.
      if (current_function().is_static()) {
        resolved = ThrowNoSuchMethodError(ident_pos, ident);
      } else {
        // Treat as call to unresolved instance field.
        resolved = CallGetter(ident_pos, LoadReceiver(ident_pos), ident);
      }
    } else if (primary->primary().IsFunction()) {
      if (allow_closure_names) {
        resolved = LoadClosure(primary);
      } else {
        ErrorMsg(ident_pos, "illegal reference to method '%s'",
                 ident.ToCString());
      }
    } else {
      ASSERT(primary->primary().IsClass());
      ErrorMsg(ident_pos, "illegal reference to class or interface '%s'",
               ident.ToCString());
    }
  }
  return resolved;
}


// Parses type = [ident "."] ident ["<" type { "," type } ">"], then resolve and
// finalize it according to the given type finalization mode.
RawAbstractType* Parser::ParseType(
    ClassFinalizer::FinalizationKind finalization) {
  TRACE_PARSER("ParseType");
  if (CurrentToken() != Token::kIDENT) {
    ErrorMsg("type name expected");
  }
  QualIdent type_name;
  if (finalization == ClassFinalizer::kIgnore) {
    SkipQualIdent();
  } else {
    ParseQualIdent(&type_name);
    // An identifier cannot be resolved in a local scope when top level parsing.
    if (!is_top_level_ &&
        (type_name.lib_prefix == NULL) &&
        ResolveIdentInLocalScope(type_name.ident_pos, *type_name.ident, NULL)) {
      ErrorMsg(type_name.ident_pos, "using '%s' in this context is invalid",
               type_name.ident->ToCString());
    }
  }
  Object& type_class = Object::Handle();
  // Leave type_class as null if type finalization mode is kIgnore.
  if (finalization != ClassFinalizer::kIgnore) {
    LibraryPrefix& lib_prefix = LibraryPrefix::Handle();
    if (type_name.lib_prefix != NULL) {
      lib_prefix = type_name.lib_prefix->raw();
    }
    type_class = UnresolvedClass::New(lib_prefix,
                                      *type_name.ident,
                                      type_name.ident_pos);
  }
  Error& malformed_error = Error::Handle();
  AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::Handle(ParseTypeArguments(&malformed_error,
                                                       finalization));
  if (finalization == ClassFinalizer::kIgnore) {
    return Type::DynamicType();
  }
  AbstractType& type = AbstractType::Handle(
      Type::New(type_class, type_arguments, type_name.ident_pos));
  // In production mode, malformed type arguments are mapped to dynamic.
  // In checked mode, a type with malformed type arguments is malformed.
  if (FLAG_enable_type_checks && !malformed_error.IsNull()) {
    Type& parameterized_type = Type::Handle();
    parameterized_type ^= type.raw();
    parameterized_type.set_type_class(Class::Handle(Object::dynamic_class()));
    parameterized_type.set_arguments(AbstractTypeArguments::Handle());
    parameterized_type.set_malformed_error(malformed_error);
  }
  if (finalization >= ClassFinalizer::kTryResolve) {
    ResolveTypeFromClass(current_class(), finalization, &type);
    if (finalization >= ClassFinalizer::kCanonicalize) {
      type ^= ClassFinalizer::FinalizeType(current_class(), type, finalization);
    }
  }
  return type.raw();
}


void Parser::CheckConstructorCallTypeArguments(
    intptr_t pos, Function& constructor,
    const AbstractTypeArguments& type_arguments) {
  if (!type_arguments.IsNull()) {
    const Class& constructor_class = Class::Handle(constructor.Owner());
    ASSERT(!constructor_class.IsNull());
    ASSERT(constructor_class.is_finalized());
    // Do not report the expected vs. actual number of type arguments, because
    // the type argument vector is flattened and raw types are allowed.
    if (type_arguments.Length() != constructor_class.NumTypeArguments()) {
      ErrorMsg(pos, "wrong number of type arguments passed to constructor");
    }
  }
}


// Parse "[" [ expr { "," expr } ["," ] "]".
// Note: if the list literal is empty and the brackets have no whitespace
// between them, the scanner recognizes the opening and closing bracket
// as one token of type Token::kINDEX.
AstNode* Parser::ParseListLiteral(intptr_t type_pos,
                                  bool is_const,
                                  const AbstractTypeArguments& type_arguments) {
  TRACE_PARSER("ParseListLiteral");
  ASSERT(type_pos >= 0);
  ASSERT(CurrentToken() == Token::kLBRACK || CurrentToken() == Token::kINDEX);
  const intptr_t literal_pos = TokenPos();
  bool is_empty_literal = CurrentToken() == Token::kINDEX;
  ConsumeToken();

  AbstractType& element_type = Type::ZoneHandle(Type::DynamicType());
  // If no type argument vector is provided, leave it as null, which is
  // equivalent to using dynamic as the type argument for the element type.
  if (!type_arguments.IsNull()) {
    ASSERT(type_arguments.Length() > 0);
    // List literals take a single type argument.
    element_type = type_arguments.TypeAt(0);
    if (type_arguments.Length() != 1) {
      ErrorMsg(type_pos,
               "a list literal takes one type argument specifying "
               "the element type");
    }
    if (is_const && !element_type.IsInstantiated()) {
      ErrorMsg(type_pos,
               "the type argument of a constant list literal cannot include "
               "a type variable");
    }
  }
  ASSERT(type_arguments.IsNull() || (type_arguments.Length() == 1));
  const Class& array_class = Class::Handle(
      Isolate::Current()->object_store()->array_class());
  Type& type = Type::ZoneHandle(
      Type::New(array_class, type_arguments, type_pos));
  type ^= ClassFinalizer::FinalizeType(
      current_class(), type, ClassFinalizer::kCanonicalize);
  ArrayNode* list = new ArrayNode(TokenPos(), type);

  // Parse the list elements. Note: there may be an optional extra
  // comma after the last element.
  if (!is_empty_literal) {
    const bool saved_mode = SetAllowFunctionLiterals(true);
    const String& dst_name = String::ZoneHandle(Symbols::ListLiteralElement());
    while (CurrentToken() != Token::kRBRACK) {
      const intptr_t element_pos = TokenPos();
      AstNode* element = ParseExpr(is_const, kConsumeCascades);
      if (FLAG_enable_type_checks &&
          !is_const &&
          !element_type.IsDynamicType()) {
        element = new AssignableNode(element_pos,
                                     element,
                                     element_type,
                                     dst_name);
      }
      list->AddElement(element);
      if (CurrentToken() == Token::kCOMMA) {
        ConsumeToken();
      } else if (CurrentToken() != Token::kRBRACK) {
        ErrorMsg("comma or ']' expected");
      }
    }
    ExpectToken(Token::kRBRACK);
    SetAllowFunctionLiterals(saved_mode);
  }

  if (is_const) {
    // Allocate and initialize the const list at compile time.
    Array& const_list =
        Array::ZoneHandle(Array::New(list->length(), Heap::kOld));
    const_list.SetTypeArguments(
        AbstractTypeArguments::Handle(type_arguments.Canonicalize()));
    Error& malformed_error = Error::Handle();
    for (int i = 0; i < list->length(); i++) {
      AstNode* elem = list->ElementAt(i);
      // Arguments have been evaluated to a literal value already.
      ASSERT(elem->IsLiteralNode());
      if (FLAG_enable_type_checks &&
          !element_type.IsDynamicType() &&
          (!elem->AsLiteralNode()->literal().IsNull() &&
           !elem->AsLiteralNode()->literal().IsInstanceOf(
               element_type, TypeArguments::Handle(), &malformed_error))) {
        // If the failure is due to a malformed type error, display it instead.
        if (!malformed_error.IsNull()) {
          ErrorMsg(malformed_error);
        } else {
          ErrorMsg(elem->AsLiteralNode()->token_pos(),
                   "list literal element at index %d must be "
                   "a constant of type '%s'",
                   i,
                   String::Handle(element_type.UserVisibleName()).ToCString());
        }
      }
      const_list.SetAt(i, elem->AsLiteralNode()->literal());
    }
    const_list ^= const_list.Canonicalize();
    const_list.MakeImmutable();
    return new LiteralNode(literal_pos, const_list);
  } else {
    // Factory call at runtime.
    String& factory_class_name = String::Handle(Symbols::List());
    const Class& factory_class =
        Class::Handle(LookupCoreClass(factory_class_name));
    ASSERT(!factory_class.IsNull());
    const String& factory_method_name =
        String::Handle(Symbols::ListLiteralFactory());
    const Function& factory_method = Function::ZoneHandle(
        factory_class.LookupFactory(factory_method_name));
    ASSERT(!factory_method.IsNull());
    if (!type_arguments.IsNull() &&
        !type_arguments.IsInstantiated() &&
        (current_block_->scope->function_level() > 0)) {
      // Make sure that the instantiator is captured.
      CaptureInstantiator();
    }
    AbstractTypeArguments& factory_type_args =
        AbstractTypeArguments::ZoneHandle(type_arguments.raw());
    // If the factory class extends other parameterized classes, adjust the
    // type argument vector.
    if (!factory_type_args.IsNull() && (factory_class.NumTypeArguments() > 1)) {
      ASSERT(factory_type_args.Length() == 1);
      Type& factory_type = Type::Handle(Type::New(
          factory_class, factory_type_args, type_pos, Heap::kNew));
      factory_type ^= ClassFinalizer::FinalizeType(
          current_class(), factory_type, ClassFinalizer::kFinalize);
      factory_type_args = factory_type.arguments();
      ASSERT(factory_type_args.Length() == factory_class.NumTypeArguments());
    }
    factory_type_args = factory_type_args.Canonicalize();
    ArgumentListNode* factory_param = new ArgumentListNode(literal_pos);
    factory_param->Add(list);
    return CreateConstructorCallNode(literal_pos,
                                     factory_type_args,
                                     factory_method,
                                     factory_param);
  }
}


ConstructorCallNode* Parser::CreateConstructorCallNode(
    intptr_t token_pos,
    const AbstractTypeArguments& type_arguments,
    const Function& constructor,
    ArgumentListNode* arguments) {
  if (!type_arguments.IsNull() && !type_arguments.IsInstantiated()) {
    EnsureExpressionTemp();
  }
  LocalVariable* allocated =
      CreateTempConstVariable(token_pos, "alloc");
  return new ConstructorCallNode(token_pos,
                                 type_arguments,
                                 constructor,
                                 arguments,
                                 allocated);
}


static void AddKeyValuePair(ArrayNode* pairs,
                            bool is_const,
                            AstNode* key,
                            AstNode* value) {
  if (is_const) {
    ASSERT(key->IsLiteralNode());
    ASSERT(key->AsLiteralNode()->literal().IsString());
    const Instance& new_key = key->AsLiteralNode()->literal();
    for (int i = 0; i < pairs->length(); i += 2) {
      const Instance& key_i =
          pairs->ElementAt(i)->AsLiteralNode()->literal();
      ASSERT(key_i.IsString());
      if (new_key.Equals(key_i)) {
        // Duplicate key found. The new value replaces the previously
        // defined value.
        pairs->SetElementAt(i + 1, value);
        return;
      }
    }
  }
  pairs->AddElement(key);
  pairs->AddElement(value);
}


AstNode* Parser::ParseMapLiteral(intptr_t type_pos,
                                 bool is_const,
                                 const AbstractTypeArguments& type_arguments) {
  TRACE_PARSER("ParseMapLiteral");
  ASSERT(type_pos >= 0);
  ASSERT(CurrentToken() == Token::kLBRACE);
  const intptr_t literal_pos = TokenPos();
  ConsumeToken();

  AbstractType& value_type = Type::ZoneHandle(Type::DynamicType());
  AbstractTypeArguments& map_type_arguments =
      AbstractTypeArguments::ZoneHandle(type_arguments.raw());
  // If no type argument vector is provided, leave it as null, which is
  // equivalent to using dynamic as the type argument for the value type.
  if (!map_type_arguments.IsNull()) {
    ASSERT(map_type_arguments.Length() > 0);
    // Map literals take two type arguments.
    if (map_type_arguments.Length() < 2) {
      // TODO(hausner): Remove legacy syntax support.
      // We temporarily accept a single type argument.
      if (FLAG_warn_legacy_map_literal) {
        Warning(type_pos,
                "a map literal takes two type arguments specifying "
                "the key type and the value type");
      }
      TypeArguments& type_array = TypeArguments::Handle(TypeArguments::New(2));
      type_array.SetTypeAt(0, Type::Handle(Type::StringType()));
      type_array.SetTypeAt(1, value_type);
      map_type_arguments = type_array.raw();
    } else if (map_type_arguments.Length() > 2) {
      ErrorMsg(type_pos,
               "a map literal takes two type arguments specifying "
               "the key type and the value type");
    } else {
      const AbstractType& key_type =
          AbstractType::Handle(map_type_arguments.TypeAt(0));
      value_type = map_type_arguments.TypeAt(1);
      if (!key_type.IsStringType()) {
        ErrorMsg(type_pos, "the key type of a map literal must be 'String'");
      }
    }
    if (is_const && !value_type.IsInstantiated()) {
      ErrorMsg(type_pos,
               "the type argument of a constant map literal cannot include "
               "a type variable");
    }
  }
  ASSERT(map_type_arguments.IsNull() || (map_type_arguments.Length() == 2));
  map_type_arguments ^= map_type_arguments.Canonicalize();

  // The kv_pair array is temporary and of element type dynamic. It is passed
  // to the factory to initialize a properly typed map.
  ArrayNode* kv_pairs = new ArrayNode(
      TokenPos(), Type::ZoneHandle(Type::ArrayType()));

  // Parse the map entries. Note: there may be an optional extra
  // comma after the last entry.
  const String& dst_name = String::ZoneHandle(Symbols::ListLiteralElement());
  while (CurrentToken() != Token::kRBRACE) {
    AstNode* key = NULL;
    if (CurrentToken() == Token::kSTRING) {
      key = ParseStringLiteral();
    }
    if (key == NULL) {
      ErrorMsg("map entry key must be string literal");
    } else if (is_const && !key->IsLiteralNode()) {
      ErrorMsg("map entry key must be compile-time constant string");
    }
    ExpectToken(Token::kCOLON);
    const bool saved_mode = SetAllowFunctionLiterals(true);
    const intptr_t value_pos = TokenPos();
    AstNode* value = ParseExpr(is_const, kConsumeCascades);
    SetAllowFunctionLiterals(saved_mode);
    if (FLAG_enable_type_checks &&
        !is_const &&
        !value_type.IsDynamicType()) {
      value = new AssignableNode(value_pos,
                                 value,
                                 value_type,
                                 dst_name);
    }
    AddKeyValuePair(kv_pairs, is_const, key, value);

    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
    } else if (CurrentToken() != Token::kRBRACE) {
      ErrorMsg("comma or '}' expected");
    }
  }
  ASSERT(kv_pairs->length() % 2 == 0);
  ExpectToken(Token::kRBRACE);

  if (is_const) {
    // Create the key-value pair array, canonicalize it and then create
    // the immutable map object with it. This all happens at compile time.
    // The resulting immutable map object is returned as a literal.

    // First, create the canonicalized key-value pair array.
    Array& key_value_array =
        Array::ZoneHandle(Array::New(kv_pairs->length(), Heap::kOld));
    Error& malformed_error = Error::Handle();
    for (int i = 0; i < kv_pairs->length(); i++) {
      AstNode* arg = kv_pairs->ElementAt(i);
      // Arguments have been evaluated to a literal value already.
      ASSERT(arg->IsLiteralNode());
      if (FLAG_enable_type_checks &&
          ((i % 2) == 1) &&  // Check values only, not keys.
          !value_type.IsDynamicType() &&
          (!arg->AsLiteralNode()->literal().IsNull() &&
           !arg->AsLiteralNode()->literal().IsInstanceOf(
               value_type, TypeArguments::Handle(), &malformed_error))) {
        // If the failure is due to a malformed type error, display it instead.
        if (!malformed_error.IsNull()) {
          ErrorMsg(malformed_error);
        } else {
          ErrorMsg(arg->AsLiteralNode()->token_pos(),
                   "map literal value at index %d must be "
                   "a constant of type '%s'",
                   i >> 1,
                   String::Handle(value_type.UserVisibleName()).ToCString());
        }
      }
      key_value_array.SetAt(i, arg->AsLiteralNode()->literal());
    }
    key_value_array ^= key_value_array.Canonicalize();
    key_value_array.MakeImmutable();

    // Construct the map object.
    const String& immutable_map_class_name =
        String::Handle(Symbols::ImmutableMap());
    const Class& immutable_map_class =
        Class::Handle(LookupCoreClass(immutable_map_class_name));
    ASSERT(!immutable_map_class.IsNull());
    // If the immutable map class extends other parameterized classes, we need
    // to adjust the type argument vector. This is currently not the case.
    ASSERT(immutable_map_class.NumTypeArguments() == 2);
    ArgumentListNode* constr_args = new ArgumentListNode(TokenPos());
    constr_args->Add(new LiteralNode(literal_pos, key_value_array));
    const String& constr_name =
        String::Handle(Symbols::ImmutableMapConstructor());
    const Function& map_constr = Function::ZoneHandle(
        immutable_map_class.LookupConstructor(constr_name));
    ASSERT(!map_constr.IsNull());
    const Object& constructor_result = Object::Handle(
        EvaluateConstConstructorCall(immutable_map_class,
                                     map_type_arguments,
                                     map_constr,
                                     constr_args));
    if (constructor_result.IsUnhandledException()) {
      return GenerateRethrow(literal_pos, constructor_result);
    } else {
      const Instance& const_instance = Instance::Cast(constructor_result);
      return new LiteralNode(literal_pos,
                             Instance::ZoneHandle(const_instance.raw()));
    }
  } else {
    // Factory call at runtime.
    String& factory_class_name = String::Handle(Symbols::Map());
    const Class& factory_class =
        Class::Handle(LookupCoreClass(factory_class_name));
    ASSERT(!factory_class.IsNull());
    const String& factory_method_name =
        String::Handle(Symbols::MapLiteralFactory());
    const Function& factory_method = Function::ZoneHandle(
        factory_class.LookupFactory(factory_method_name));
    ASSERT(!factory_method.IsNull());
    if (!map_type_arguments.IsNull() &&
        !map_type_arguments.IsInstantiated() &&
        (current_block_->scope->function_level() > 0)) {
      // Make sure that the instantiator is captured.
      CaptureInstantiator();
    }
    AbstractTypeArguments& factory_type_args =
        AbstractTypeArguments::ZoneHandle(map_type_arguments.raw());
    // If the factory class extends other parameterized classes, adjust the
    // type argument vector.
    if (!factory_type_args.IsNull() && (factory_class.NumTypeArguments() > 2)) {
      ASSERT(factory_type_args.Length() == 2);
      Type& factory_type = Type::Handle(Type::New(
          factory_class, factory_type_args, type_pos, Heap::kNew));
      factory_type ^= ClassFinalizer::FinalizeType(
          current_class(), factory_type, ClassFinalizer::kFinalize);
      factory_type_args = factory_type.arguments();
      ASSERT(factory_type_args.Length() == factory_class.NumTypeArguments());
    }
    factory_type_args = factory_type_args.Canonicalize();
    ArgumentListNode* factory_param = new ArgumentListNode(literal_pos);
    factory_param->Add(kv_pairs);
    return CreateConstructorCallNode(literal_pos,
                                     factory_type_args,
                                     factory_method,
                                     factory_param);
  }
}


AstNode* Parser::ParseCompoundLiteral() {
  TRACE_PARSER("ParseCompoundLiteral");
  bool is_const = false;
  if (CurrentToken() == Token::kCONST) {
    is_const = true;
    ConsumeToken();
  }
  const intptr_t type_pos = TokenPos();
  Error& malformed_error = Error::Handle();
  AbstractTypeArguments& type_arguments = AbstractTypeArguments::ZoneHandle(
      ParseTypeArguments(&malformed_error,
                         ClassFinalizer::kCanonicalizeWellFormed));
  // Map and List interfaces do not declare bounds on their type parameters, so
  // we should never see a malformed type error here.
  // Note that a bound error is the only possible malformed type error returned
  // when requesting kCanonicalizeWellFormed type finalization.
  ASSERT(malformed_error.IsNull());
  AstNode* primary = NULL;
  if ((CurrentToken() == Token::kLBRACK) ||
      (CurrentToken() == Token::kINDEX)) {
    primary = ParseListLiteral(type_pos, is_const, type_arguments);
  } else if (CurrentToken() == Token::kLBRACE) {
    primary = ParseMapLiteral(type_pos, is_const, type_arguments);
  } else {
    ErrorMsg("unexpected token %s", Token::Str(CurrentToken()));
  }
  return primary;
}


static const String& BuildConstructorName(const String& type_class_name,
                                          const String* named_constructor) {
  // By convention, the static function implementing a named constructor 'C'
  // for class 'A' is labeled 'A.C', and the static function implementing the
  // unnamed constructor for class 'A' is labeled 'A.'.
  // This convention prevents users from explicitly calling constructors.
  const String& period = String::Handle(Symbols::Dot());
  String& constructor_name =
      String::Handle(String::Concat(type_class_name, period));
  if (named_constructor != NULL) {
    constructor_name = String::Concat(constructor_name, *named_constructor);
  }
  return constructor_name;
}


AstNode* Parser::ParseNewOperator() {
  TRACE_PARSER("ParseNewOperator");
  const intptr_t new_pos = TokenPos();
  ASSERT((CurrentToken() == Token::kNEW) || (CurrentToken() == Token::kCONST));
  bool is_const = (CurrentToken() == Token::kCONST);
  ConsumeToken();
  if (!IsIdentifier()) {
    ErrorMsg("type name expected");
  }
  intptr_t type_pos = TokenPos();
  AbstractType& type = AbstractType::Handle(
      ParseType(ClassFinalizer::kCanonicalizeExpression));
  // In case the type is malformed, throw a dynamic type error after finishing
  // parsing the instance creation expression.
  if (!type.IsMalformed() && (type.IsTypeParameter() || type.IsDynamicType())) {
    // Replace the type with a malformed type.
    type = ClassFinalizer::NewFinalizedMalformedType(
        Error::Handle(),  // No previous error.
        current_class(),
        type_pos,
        ClassFinalizer::kTryResolve,  // No compile-time error.
        "%s'%s' cannot be instantiated",
        type.IsTypeParameter() ? "type parameter " : "",
        type.IsTypeParameter() ?
            String::Handle(type.UserVisibleName()).ToCString() : "dynamic");
  }

  // The grammar allows for an optional ('.' identifier)? after the type, which
  // is a named constructor. Note that ParseType(kMustResolve) above will not
  // consume it as part of a misinterpreted qualified identifier, because only a
  // valid library prefix is accepted as qualifier.
  String* named_constructor = NULL;
  if (CurrentToken() == Token::kPERIOD) {
    ConsumeToken();
    named_constructor = ExpectIdentifier("name of constructor expected");
  }

  // Parse constructor parameters.
  if (CurrentToken() != Token::kLPAREN) {
    ErrorMsg("'(' expected");
  }
  intptr_t call_pos = TokenPos();
  ArgumentListNode* arguments = ParseActualParameters(NULL, is_const);

  // Parsing is complete, so we can return a throw in case of a malformed type
  // or report a compile-time error if the constructor is const.
  if (type.IsMalformed()) {
    if (is_const) {
      const Error& error = Error::Handle(type.malformed_error());
      ErrorMsg(error);
    }
    return ThrowTypeError(type_pos, type);
  }

  // Resolve the type and optional identifier to a constructor or factory.
  Class& type_class = Class::Handle(type.type_class());
  const String& type_class_name = String::Handle(type_class.Name());
  AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::ZoneHandle(type.arguments());

  // The constructor class and its name are those of the parsed type, unless the
  // parsed type is an interface and a default factory class is specified, in
  // which case constructor_class and constructor_class_name are modified below.
  Class& constructor_class = Class::ZoneHandle(type_class.raw());
  String& constructor_class_name = String::Handle(type_class_name.raw());

  // A constructor has an implicit 'this' parameter (instance to construct)
  // and a factory has an implicit 'this' parameter (type_arguments).
  // A constructor has a second implicit 'phase' parameter.
  intptr_t arguments_length = arguments->length() + 2;

  if (type_class.is_interface()) {
    // We need to make sure that an appropriate constructor is
    // declared in the interface.
    const String& constructor_name =
        BuildConstructorName(type_class_name, named_constructor);
    const String& external_constructor_name =
        (named_constructor ? constructor_name : type_class_name);
    Function& constructor = Function::ZoneHandle(
        type_class.LookupConstructor(constructor_name));
    if (constructor.IsNull()) {
      // Replace the type with a malformed type and compile a throw or report
      // a compile-time error if the constructor is const.
      type = ClassFinalizer::NewFinalizedMalformedType(
          Error::Handle(),  // No previous error.
          current_class(),
          call_pos,
          ClassFinalizer::kTryResolve,  // No compile-time error.
          "interface '%s' has no constructor named '%s'",
          type_class_name.ToCString(),
          external_constructor_name.ToCString());
      if (is_const) {
        const Error& error = Error::Handle(type.malformed_error());
        ErrorMsg(error);
      }
      return ThrowNoSuchMethodError(call_pos, external_constructor_name);
    }
    String& error_message = String::Handle();
    if (!constructor.AreValidArguments(arguments_length,
                                       arguments->names(),
                                       &error_message)) {
      if (is_const) {
        ErrorMsg(call_pos,
                 "invalid arguments passed to constructor '%s' "
                 "for interface '%s': %s",
                 external_constructor_name.ToCString(),
                 type_class_name.ToCString(),
                 error_message.ToCString());
      }
      return ThrowNoSuchMethodError(call_pos, external_constructor_name);
    }
    // TODO(regis): Remove support for obsolete default factory classes.
    if (!type_class.HasFactoryClass()) {
      ErrorMsg(type_pos,
               "cannot allocate interface '%s' without factory class",
               type_class_name.ToCString());
    }
    if (!type_class.HasResolvedFactoryClass()) {
      // This error can occur only with bootstrap classes.
      const UnresolvedClass& unresolved =
          UnresolvedClass::Handle(type_class.UnresolvedFactoryClass());
      const String& missing_class_name = String::Handle(unresolved.ident());
      ErrorMsg("unresolved factory class '%s'", missing_class_name.ToCString());
    }
    // Only change the class of the constructor to the factory class if the
    // factory class implements the interface 'type'.
    const Class& factory_class = Class::Handle(type_class.FactoryClass());
    if (factory_class.IsSubtypeOf(TypeArguments::Handle(),
                                  type_class,
                                  TypeArguments::Handle(),
                                  NULL)) {
      // Class finalization verifies that the factory class has identical type
      // parameters as the interface.
      constructor_class_name = factory_class.Name();
    }
    // Always change the result type of the constructor to the factory type.
    constructor_class = factory_class.raw();
    // The finalized type_arguments are still those of the interface type.
    ASSERT(!constructor_class.is_interface());
  }

  // An additional type check of the result of a redirecting factory may be
  // required.
  AbstractType& type_bound = AbstractType::ZoneHandle();

  // Make sure that an appropriate constructor exists.
  const String& constructor_name =
      BuildConstructorName(constructor_class_name, named_constructor);
  Function& constructor = Function::ZoneHandle(
      constructor_class.LookupConstructor(constructor_name));
  if (constructor.IsNull()) {
    constructor = constructor_class.LookupFactory(constructor_name);
    if (constructor.IsNull()) {
      const String& external_constructor_name =
          (named_constructor ? constructor_name : constructor_class_name);
      // Replace the type with a malformed type and compile a throw or report a
      // compile-time error if the constructor is const.
      type = ClassFinalizer::NewFinalizedMalformedType(
          Error::Handle(),  // No previous error.
          current_class(),
          call_pos,
          ClassFinalizer::kTryResolve,  // No compile-time error.
          "class '%s' has no constructor or factory named '%s'",
          String::Handle(constructor_class.Name()).ToCString(),
          external_constructor_name.ToCString());
      if (is_const) {
        const Error& error = Error::Handle(type.malformed_error());
        ErrorMsg(error);
      }
      return ThrowNoSuchMethodError(call_pos, external_constructor_name);
    } else if (constructor.IsRedirectingFactory()) {
      Type& redirect_type = Type::Handle(constructor.RedirectionType());
      if (!redirect_type.IsMalformed() && !redirect_type.IsInstantiated()) {
        // The type arguments of the redirection type are instantiated from the
        // type arguments of the parsed type of the 'new' or 'const' expression.
        redirect_type ^= redirect_type.InstantiateFrom(type_arguments);
      }
      if (redirect_type.IsMalformed()) {
        if (is_const) {
          const Error& error = Error::Handle(redirect_type.malformed_error());
          ErrorMsg(error);
        }
        return ThrowTypeError(redirect_type.token_pos(), redirect_type);
      }
      if (FLAG_enable_type_checks && !redirect_type.IsSubtypeOf(type, NULL)) {
        // Additional type checking of the result is necessary.
        type_bound = type.raw();
      }
      type = redirect_type.raw();
      type_class = type.type_class();
      type_arguments = type.arguments();
      constructor = constructor.RedirectionTarget();
      ASSERT(!constructor.IsNull());
      constructor_class = constructor.Owner();
      ASSERT(type_class.raw() == constructor_class.raw());
    }
    if (constructor.IsFactory()) {
      // A factory does not have the implicit 'phase' parameter.
      arguments_length -= 1;
    }
  }

  // It is ok to call a factory method of an abstract class, but it is
  // a dynamic error to instantiate an abstract class.
  ASSERT(!constructor.IsNull());
  if (constructor_class.is_abstract() && !constructor.IsFactory()) {
    ArgumentListNode* arguments = new ArgumentListNode(type_pos);
    arguments->Add(new LiteralNode(
        TokenPos(), Integer::ZoneHandle(Integer::New(type_pos))));
    arguments->Add(new LiteralNode(
        TokenPos(), String::ZoneHandle(constructor_class_name.raw())));
    const String& cls_name =
        String::Handle(Symbols::AbstractClassInstantiationError());
    const String& func_name = String::Handle(Symbols::ThrowNew());
    return MakeStaticCall(cls_name, func_name, arguments);
  }
  String& error_message = String::Handle();
  if (!constructor.AreValidArguments(arguments_length,
                                     arguments->names(),
                                     &error_message)) {
    const String& external_constructor_name =
        (named_constructor ? constructor_name : constructor_class_name);
    if (is_const) {
      ErrorMsg(call_pos,
               "invalid arguments passed to constructor '%s' "
               "for class '%s': %s",
               external_constructor_name.ToCString(),
               String::Handle(constructor_class.Name()).ToCString(),
               error_message.ToCString());
    }
    return ThrowNoSuchMethodError(call_pos, external_constructor_name);
  }

  // Now that the constructor to be called is identified, finalize the type
  // argument vector to be passed.
  // The type argument vector of the parsed type was finalized in ParseType.
  // If the constructor class was changed from the interface class to the
  // factory class, we need to finalize the type argument vector again, because
  // it may be longer due to the factory class extending a class, or/and because
  // the bounds on the factory class may be tighter than on the interface.
  if (!constructor.IsNull() && (constructor_class.raw() != type_class.raw())) {
    const intptr_t num_type_parameters = constructor_class.NumTypeParameters();
    TypeArguments& temp_type_arguments = TypeArguments::Handle();
    if (!type_arguments.IsNull()) {
      // Copy the parsed type arguments starting at offset 0, because interfaces
      // have no super types.
      ASSERT(type_class.NumTypeArguments() == type_class.NumTypeParameters());
      const intptr_t num_type_arguments = type_arguments.Length();
      temp_type_arguments = TypeArguments::New(num_type_parameters, Heap::kNew);
      AbstractType& type_argument = AbstractType::Handle();
      for (intptr_t i = 0; i < num_type_parameters; i++) {
        if (i < num_type_arguments) {
          type_argument = type_arguments.TypeAt(i);
        } else {
          type_argument = Type::DynamicType();
        }
        temp_type_arguments.SetTypeAt(i, type_argument);
      }
    }
    Type& temp_type = Type::Handle(Type::New(
         constructor_class, temp_type_arguments, type.token_pos(), Heap::kNew));
    // No need to canonicalize temporary type.
    temp_type ^= ClassFinalizer::FinalizeType(
        current_class(), temp_type, ClassFinalizer::kFinalize);
    // The type argument vector may have been expanded with the type arguments
    // of the super type when finalizing the temporary type.
    type_arguments = temp_type.arguments();
    // The type parameter bounds of the factory class may be more specific than
    // the type parameter bounds of the interface class. Therefore, although
    // type was not malformed, temp_type may be malformed.
    if (!type.IsMalformed() && temp_type.IsMalformed()) {
      const Error& error = Error::Handle(temp_type.malformed_error());
      type.set_malformed_error(error);
    }
  }
  // Return a throw in case of a malformed type or report a compile-time error
  // if the constructor is const.
  if (type.IsMalformed()) {
    if (is_const) {
      const Error& error = Error::Handle(type.malformed_error());
      ErrorMsg(error);
    }
    return ThrowTypeError(type_pos, type);
  }
  type_arguments ^= type_arguments.Canonicalize();
  // Make the constructor call.
  AstNode* new_object = NULL;
  if (is_const) {
    if (!constructor.is_const()) {
      ErrorMsg("'const' requires const constructor: '%s'",
          String::Handle(constructor.name()).ToCString());
    }
    const Object& constructor_result = Object::Handle(
        EvaluateConstConstructorCall(constructor_class,
                                     type_arguments,
                                     constructor,
                                     arguments));
    if (constructor_result.IsUnhandledException()) {
      new_object = GenerateRethrow(new_pos, constructor_result);
    } else {
      const Instance& const_instance = Instance::Cast(constructor_result);
      new_object = new LiteralNode(new_pos,
                                   Instance::ZoneHandle(const_instance.raw()));
      if (!type_bound.IsNull()) {
        ASSERT(!type_bound.IsMalformed());
        Error& malformed_error = Error::Handle();
        if (!const_instance.IsInstanceOf(type_bound,
                                         TypeArguments::Handle(),
                                         &malformed_error)) {
          type_bound = ClassFinalizer::NewFinalizedMalformedType(
              malformed_error,
              current_class(),
              new_pos,
              ClassFinalizer::kTryResolve,  // No compile-time error.
              "const factory result is not an instance of '%s'",
              String::Handle(type_bound.UserVisibleName()).ToCString());
          new_object = ThrowTypeError(new_pos, type_bound);
        }
        type_bound = AbstractType::null();
      }
    }
  } else {
    CheckFunctionIsCallable(new_pos, constructor);
    CheckConstructorCallTypeArguments(new_pos, constructor, type_arguments);
    if (!type_arguments.IsNull() &&
        !type_arguments.IsInstantiated() &&
        (current_block_->scope->function_level() > 0)) {
      // Make sure that the instantiator is captured.
      CaptureInstantiator();
    }
    // If the type argument vector is not instantiated, we verify in checked
    // mode at runtime that it is within its declared bounds.
    new_object = CreateConstructorCallNode(
        new_pos, type_arguments, constructor, arguments);
  }
  if (!type_bound.IsNull()) {
    const String& dst_name = String::ZoneHandle(Symbols::FactoryResult());
    new_object = new AssignableNode(new_pos, new_object, type_bound, dst_name);
  }
  return new_object;
}


String& Parser::Interpolate(ArrayNode* values) {
  const String& class_name = String::Handle(Symbols::StringBase());
  const Class& cls = Class::Handle(LookupCoreClass(class_name));
  ASSERT(!cls.IsNull());
  const String& func_name = String::Handle(Symbols::Interpolate());
  const Function& func =
      Function::Handle(cls.LookupStaticFunction(func_name));
  ASSERT(!func.IsNull());

  // Build the array of literal values to interpolate.
  const Array& value_arr = Array::Handle(Array::New(values->length()));
  for (int i = 0; i < values->length(); i++) {
    ASSERT(values->ElementAt(i)->IsLiteralNode());
    value_arr.SetAt(i, values->ElementAt(i)->AsLiteralNode()->literal());
  }

  // Build argument array to pass to the interpolation function.
  GrowableArray<const Object*> interpolate_arg;
  interpolate_arg.Add(&value_arr);
  const Array& kNoArgumentNames = Array::Handle();

  // Call interpolation function.
  String& concatenated = String::ZoneHandle();
  concatenated ^= DartEntry::InvokeStatic(func,
                                          interpolate_arg,
                                          kNoArgumentNames);
  if (concatenated.IsUnhandledException()) {
    ErrorMsg("Exception thrown in Parser::Interpolate");
  }
  concatenated = Symbols::New(concatenated);
  return concatenated;
}


// A string literal consists of the concatenation of the next n tokens
// that satisfy the EBNF grammar:
// literal = kSTRING {{ interpol } kSTRING }
// interpol = kINTERPOL_VAR | (kINTERPOL_START expression kINTERPOL_END)
// In other words, the scanner breaks down interpolated strings so that
// a string literal always begins and ends with a kSTRING token.
AstNode* Parser::ParseStringLiteral() {
  TRACE_PARSER("ParseStringLiteral");
  AstNode* primary = NULL;
  const intptr_t literal_start = TokenPos();
  ASSERT(CurrentToken() == Token::kSTRING);
  Token::Kind l1_token = LookaheadToken(1);
  if ((l1_token != Token::kSTRING) &&
      (l1_token != Token::kINTERPOL_VAR) &&
      (l1_token != Token::kINTERPOL_START)) {
    // Common case: no interpolation.
    primary = new LiteralNode(literal_start, *CurrentLiteral());
    ConsumeToken();
    return primary;
  }
  // String interpolation needed.
  bool is_compiletime_const = true;
  ArrayNode* values = new ArrayNode(
      TokenPos(), Type::ZoneHandle(Type::ArrayType()));
  while (CurrentToken() == Token::kSTRING) {
    values->AddElement(new LiteralNode(TokenPos(), *CurrentLiteral()));
    ConsumeToken();
    while ((CurrentToken() == Token::kINTERPOL_VAR) ||
        (CurrentToken() == Token::kINTERPOL_START)) {
      AstNode* expr = NULL;
      const intptr_t expr_pos = TokenPos();
      if (CurrentToken() == Token::kINTERPOL_VAR) {
        expr = ResolveIdent(TokenPos(), *CurrentLiteral(), true);
        ConsumeToken();
      } else {
        ASSERT(CurrentToken() == Token::kINTERPOL_START);
        ConsumeToken();
        expr = ParseExpr(kAllowConst, kConsumeCascades);
        ExpectToken(Token::kINTERPOL_END);
      }
      // Check if this interpolated string is still considered a compile time
      // constant. If it is we need to evaluate if the current string part is
      // a constant or not. Only stings, numbers, booleans and null values
      // are allowed in compile time const interpolations.
      if (is_compiletime_const) {
        const Object* const_expr = expr->EvalConstExpr();
        if ((const_expr != NULL) &&
            (const_expr->IsNumber() ||
            const_expr->IsString() ||
            const_expr->IsBool() ||
            const_expr->IsNull())) {
          // Change expr into a literal.
          expr = new LiteralNode(expr_pos, EvaluateConstExpr(expr));
        } else {
          is_compiletime_const = false;
        }
      }
      values->AddElement(expr);
    }
  }
  if (is_compiletime_const) {
    primary = new LiteralNode(literal_start, Interpolate(values));
  } else {
    ArgumentListNode* interpolate_arg =
        new ArgumentListNode(values->token_pos());
    interpolate_arg->Add(values);
    const String& cls_name = String::Handle(Symbols::StringBase());
    const String& func_name = String::Handle(Symbols::Interpolate());
    primary = MakeStaticCall(cls_name, func_name, interpolate_arg);
  }
  return primary;
}


AstNode* Parser::ParseArgumentDefinitionTest() {
  const intptr_t test_pos = TokenPos();
  ConsumeToken();
  const intptr_t ident_pos = TokenPos();
  String* ident = ExpectIdentifier("parameter name expected");
  Function& owner_function = Function::Handle();
  LocalScope* owner_scope;
  intptr_t param_index;
  if (!IsFormalParameter(*ident, &owner_function, &owner_scope, &param_index)) {
    ErrorMsg(ident_pos, "formal parameter name expected");
  }
  if (param_index < owner_function.num_fixed_parameters()) {
    // The formal parameter is not optional, therefore the corresponding
    // argument is always passed and defined.
    return new LiteralNode(test_pos, Bool::ZoneHandle(Bool::True()));
  }
  char name[64];
  OS::SNPrint(name, 64, "%s_%"Pd"",
              Symbols::Name(Symbols::kSavedArgDescVarPrefix),
              owner_function.token_pos());
  const String& saved_args_desc_name = String::ZoneHandle(Symbols::New(name));
  LocalVariable* saved_args_desc_var = LookupLocalScope(saved_args_desc_name);
  if (saved_args_desc_var == NULL) {
    ASSERT(owner_scope != NULL);
    saved_args_desc_var =
        new LocalVariable(owner_function.token_pos(),
                          saved_args_desc_name,
                          Type::ZoneHandle(Type::ArrayType()));
    saved_args_desc_var->set_is_final();
    // The saved arguments descriptor variable must be added just after the
    // formal parameters. This simplifies the 2-step saving of a captured
    // arguments descriptor.
    // At this time, the owner scope should only contain formal parameters.
    ASSERT(owner_scope->num_variables() == owner_function.NumParameters());
    bool success = owner_scope->AddVariable(saved_args_desc_var);
    ASSERT(success);
    // Capture the saved argument descriptor variable if necessary.
    LocalVariable* local = LookupLocalScope(saved_args_desc_name);
    ASSERT(local == saved_args_desc_var);
  }
  // If we currently generate code for the local function of an enclosing owner
  // function, the saved arguments descriptor variable must have been captured
  // by the above lookup.
  ASSERT((owner_function.raw() == innermost_function().raw()) ||
         saved_args_desc_var->is_captured());
  const String& param_name = String::ZoneHandle(Symbols::New(*ident));
  return new ArgumentDefinitionTestNode(
      test_pos, param_index, param_name, saved_args_desc_var);
}


AstNode* Parser::ParsePrimary() {
  TRACE_PARSER("ParsePrimary");
  ASSERT(!is_top_level_);
  AstNode* primary = NULL;
  if (IsFunctionLiteral()) {
    // The name of a literal function is visible from inside the function, but
    // must not collide with names in the scope declaring the literal.
    OpenBlock();
    primary = ParseFunctionStatement(true);
    CloseBlock();
  } else if (IsIdentifier()) {
    QualIdent qual_ident;
    ParseQualIdent(&qual_ident);
    if (qual_ident.lib_prefix == NULL) {
      if (!ResolveIdentInLocalScope(qual_ident.ident_pos,
                                    *qual_ident.ident,
                                    &primary)) {
        // Check whether the identifier is a type parameter. Type parameters
        // can never be used as part of primary expressions.
        if (!current_class().IsNull()) {
          TypeParameter& type_param = TypeParameter::ZoneHandle(
              current_class().LookupTypeParameter(*(qual_ident.ident),
                                                  TokenPos()));
          if (!type_param.IsNull()) {
            const String& type_param_name = String::Handle(type_param.name());
            ErrorMsg(qual_ident.ident_pos,
                     "illegal use of type parameter %s",
                     type_param_name.ToCString());
          }
        }
        // This is a non-local unqualified identifier so resolve the
        // identifier locally in the main app library and all libraries
        // imported by it.
        primary = ResolveIdentInCurrentLibraryScope(qual_ident.ident_pos,
                                                    *qual_ident.ident);
      }
    } else {
      // This is a qualified identifier with a library prefix so resolve
      // the identifier locally in that library (we do not include the
      // libraries imported by that library).
      primary = ResolveIdentInPrefixScope(qual_ident.ident_pos,
                                          *qual_ident.lib_prefix,
                                          *qual_ident.ident);
    }
    ASSERT(primary != NULL);
  } else if (CurrentToken() == Token::kTHIS) {
    const String& this_name = String::Handle(Symbols::This());
    LocalVariable* local = LookupLocalScope(this_name);
    if (local == NULL) {
      ErrorMsg("receiver 'this' is not in scope");
    }
    primary = new LoadLocalNode(TokenPos(), local);
    ConsumeToken();
  } else if (CurrentToken() == Token::kINTEGER) {
    const Integer& literal = Integer::ZoneHandle(CurrentIntegerLiteral());
    primary = new LiteralNode(TokenPos(), literal);
    ConsumeToken();
  } else if (CurrentToken() == Token::kTRUE) {
    primary = new LiteralNode(TokenPos(), Bool::ZoneHandle(Bool::True()));
    ConsumeToken();
  } else if (CurrentToken() == Token::kFALSE) {
    primary = new LiteralNode(TokenPos(), Bool::ZoneHandle(Bool::False()));
    ConsumeToken();
  } else if (CurrentToken() == Token::kNULL) {
    primary = new LiteralNode(TokenPos(), Instance::ZoneHandle());
    ConsumeToken();
  } else if (CurrentToken() == Token::kLPAREN) {
    ConsumeToken();
    const bool saved_mode = SetAllowFunctionLiterals(true);
    primary = ParseExpr(kAllowConst, kConsumeCascades);
    SetAllowFunctionLiterals(saved_mode);
    ExpectToken(Token::kRPAREN);
  } else if (CurrentToken() == Token::kDOUBLE) {
    Double& double_value = Double::ZoneHandle(CurrentDoubleLiteral());
    if (double_value.IsNull()) {
      ErrorMsg("invalid double literal");
    }
    primary = new LiteralNode(TokenPos(), double_value);
    ConsumeToken();
  } else if (CurrentToken() == Token::kSTRING) {
    primary = ParseStringLiteral();
  } else if (CurrentToken() == Token::kNEW) {
    primary = ParseNewOperator();
  } else if (CurrentToken() == Token::kCONST) {
    if ((LookaheadToken(1) == Token::kLT) ||
        (LookaheadToken(1) == Token::kLBRACK) ||
        (LookaheadToken(1) == Token::kINDEX) ||
        (LookaheadToken(1) == Token::kLBRACE)) {
      primary = ParseCompoundLiteral();
    } else {
      primary = ParseNewOperator();
    }
  } else if (CurrentToken() == Token::kLT ||
             CurrentToken() == Token::kLBRACK ||
             CurrentToken() == Token::kINDEX ||
             CurrentToken() == Token::kLBRACE) {
    primary = ParseCompoundLiteral();
  } else if (CurrentToken() == Token::kSUPER) {
    if (current_function().is_static()) {
      ErrorMsg("cannot access superclass from static method");
    }
    if (current_class().SuperClass() == Class::null()) {
      ErrorMsg("class '%s' does not have a superclass",
               String::Handle(current_class().Name()).ToCString());
    }
    ConsumeToken();
    if (CurrentToken() == Token::kPERIOD) {
      ConsumeToken();
      const String& ident = *ExpectIdentifier("identifier expected");
      if (CurrentToken() == Token::kLPAREN) {
        primary = ParseSuperCall(ident);
      } else {
        primary = ParseSuperFieldAccess(ident);
      }
    } else if ((CurrentToken() == Token::kLBRACK) ||
        Token::CanBeOverloaded(CurrentToken()) ||
        (CurrentToken() == Token::kNE)) {
      primary = ParseSuperOperator();
    } else {
      primary = new PrimaryNode(TokenPos(),
                                String::ZoneHandle(Symbols::Super()));
    }
  } else if (CurrentToken() == Token::kCONDITIONAL) {
    primary = ParseArgumentDefinitionTest();
  } else {
    UnexpectedToken();
  }
  return primary;
}


// Evaluate expression in expr and return the value. The expression must
// be a compile time constant.
const Instance& Parser::EvaluateConstExpr(AstNode* expr) {
  if (expr->IsLiteralNode()) {
    return expr->AsLiteralNode()->literal();
  } else if (expr->IsLoadLocalNode() &&
      expr->AsLoadLocalNode()->local().IsConst()) {
    return *expr->AsLoadLocalNode()->local().ConstValue();
  } else {
    ASSERT(expr->EvalConstExpr() != NULL);
    ReturnNode* ret = new ReturnNode(expr->token_pos(), expr);
    // Compile time constant expressions cannot reference anything from a
    // local scope.
    LocalScope* empty_scope = new LocalScope(NULL, 0, 0);
    SequenceNode* seq = new SequenceNode(expr->token_pos(), empty_scope);
    seq->Add(ret);

    Object& result = Object::Handle(Compiler::ExecuteOnce(seq));
    if (result.IsError()) {
      // Propagate the compilation error.
      Isolate::Current()->long_jump_base()->Jump(1, Error::Cast(result));
      UNREACHABLE();
    }
    ASSERT(result.IsInstance());
    Instance& value = Instance::ZoneHandle();
    value ^= result.raw();
    if (!value.IsNull()) {
      value ^= value.Canonicalize();
    }
    return value;
  }
}


void Parser::SkipFunctionLiteral() {
  if (IsIdentifier()) {
    if (LookaheadToken(1) != Token::kLPAREN) {
      SkipType(true);
    }
    ExpectIdentifier("function name expected");
  }
  if (CurrentToken() == Token::kLPAREN) {
    const bool allow_explicit_default_values = true;
    ParamList ignore_params;
    ParseFormalParameterList(allow_explicit_default_values, &ignore_params);
  }
  if (CurrentToken() == Token::kLBRACE) {
    SkipBlock();
  } else if (CurrentToken() == Token::kARROW) {
    ConsumeToken();
    SkipExpr();
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
    }
  }
  ExpectToken(Token::kRBRACK);
}


void Parser::SkipMapLiteral() {
  ExpectToken(Token::kLBRACE);
  while (CurrentToken() == Token::kSTRING) {
    SkipStringLiteral();
    ExpectToken(Token::kCOLON);
    SkipNestedExpr();
    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
    }
  }
  ExpectToken(Token::kRBRACE);
}


void Parser::SkipActualParameters() {
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
  if ((CurrentToken() == Token::kLBRACK) ||
      (CurrentToken() == Token::kINDEX)) {
    SkipListLiteral();
  } else if (CurrentToken() == Token::kLBRACE) {
    SkipMapLiteral();
  }
}


void Parser::SkipNewOperator() {
  ConsumeToken();  // Skip new or const keyword.
  if (IsIdentifier()) {
    SkipType(false);
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
        SkipExpr();
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
    case Token::kCONDITIONAL:
      ConsumeToken();
      if (IsIdentifier()) {
        ConsumeToken();
      }
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
    if ((CurrentToken() == Token::kPERIOD) ||
        (CurrentToken() == Token::kCASCADE)) {
      ConsumeToken();
      ExpectIdentifier("identifier expected");
    } else if (CurrentToken() == Token::kLBRACK) {
      ConsumeToken();
      SkipNestedExpr();
      ExpectToken(Token::kRBRACK);
    } else if (CurrentToken() == Token::kLPAREN) {
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
  if (IsPrefixOperator(CurrentToken()) ||
      IsIncrementOperator(CurrentToken())) {
    ConsumeToken();
    SkipUnaryExpr();
  } else {
    SkipPostfixExpr();
  }
}


void Parser::SkipBinaryExpr() {
  SkipUnaryExpr();
  const int min_prec = Token::Precedence(Token::kOR);
  const int max_prec = Token::Precedence(Token::kMUL);
  while (((min_prec <= Token::Precedence(CurrentToken())) &&
      (Token::Precedence(CurrentToken()) <= max_prec)) ||
      IsLiteral("as")) {
    Token::Kind last_token = IsLiteral("as") ? Token::kAS : CurrentToken();
    ConsumeToken();
    if (last_token == Token::kIS) {
      if (CurrentToken() == Token::kNOT) {
        ConsumeToken();
      }
      SkipType(false);
    } else if (last_token == Token::kAS) {
      SkipType(false);
    } else {
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
