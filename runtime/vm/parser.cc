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

namespace dart {

DEFINE_FLAG(bool, enable_asserts, false, "Enable assert statements.");
DEFINE_FLAG(bool, enable_type_checks, false, "Enable type checks.");
DEFINE_FLAG(bool, trace_parser, false, "Trace parser operations.");
DEFINE_FLAG(bool, warning_as_error, false, "Treat warnings as errors.");
DEFINE_FLAG(bool, silent_warnings, false, "Silence warnings.");
DEFINE_FLAG(bool, allow_string_plus, true, "Allow + operator on strings.");

static void CheckedModeHandler(bool value) {
  FLAG_enable_asserts = value;
  FLAG_enable_type_checks = value;
}

DEFINE_FLAG_HANDLER(CheckedModeHandler,
                    enable_checked_mode,
                    "Enabled checked mode.");

// All references to Dart names are listed here.
static const char* kAssertionErrorName = "AssertionError";
static const char* kTypeErrorName = "TypeError";
static const char* kFallThroughErrorName = "FallThroughError";
static const char* kStaticResolutionExceptionName = "StaticResolutionException";
static const char* kThrowNewName = "_throwNew";
static const char* kListLiteralFactoryClassName = "_ListLiteralFactory";
static const char* kListLiteralFactoryName = "List.fromLiteral";
static const char* kMapLiteralFactoryClassName = "_MapLiteralFactory";
static const char* kMapLiteralFactoryName = "Map.fromLiteral";
static const char* kImmutableMapName = "ImmutableMap";
static const char* kImmutableMapConstructorName = "ImmutableMap._create";
static const char* kStringClassName = "StringBase";
static const char* kInterpolateName = "_interpolate";
static const char* kThisName = "this";
static const char* kPhaseParameterName = ":phase";
static const char* kGetIteratorName = "iterator";

#if defined(DEBUG)

class TraceParser : public ValueObject {
 public:
  TraceParser(intptr_t token_index, const Script& script, const char* msg) {
    if (FLAG_trace_parser) {
      intptr_t line, column;
      script.GetTokenLocation(token_index, &line, &column);
      PrintIndent();
      OS::Print("%s (line %d, col %d, token %d)\n",
                msg, line, column, token_index);
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
  TraceParser __p__(this->token_index_, this->script_, s)

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
  UnhandledException& excp = UnhandledException::Handle();
  excp ^= obj.raw();
  const Instance& exception = Instance::ZoneHandle(excp.exception());
  const Instance& stack_trace = Instance::ZoneHandle(excp.stacktrace());
  return new ThrowNode(token_pos,
                       new LiteralNode(token_pos, exception),
                       new LiteralNode(token_pos, stack_trace));
}


LocalVariable* ParsedFunction::CreateExpressionTempVar(intptr_t token_index) {
  return new LocalVariable(token_index,
                           String::ZoneHandle(String::NewSymbol(":expr_temp")),
                           Type::ZoneHandle(Type::DynamicType()));
}


void ParsedFunction::SetNodeSequence(SequenceNode* node_sequence) {
  ASSERT(node_sequence_ == NULL);
  ASSERT(node_sequence != NULL);
  node_sequence_ = node_sequence;
  const int num_fixed_params = function().num_fixed_parameters();
  const int num_opt_params = function().num_optional_parameters();
  // Allocated ids for parameters.
  intptr_t parameter_id = AstNode::kNoId;
  for (intptr_t i = 0; i < num_fixed_params + num_opt_params; i++) {
    parameter_id = AstNode::GetNextId();
    if (i == 0) {
      node_sequence_->set_first_parameter_id(parameter_id);
    }
  }
  node_sequence_->set_last_parameter_id(parameter_id);
}


void ParsedFunction::AllocateVariables() {
  LocalScope* scope = node_sequence()->scope();
  const int fixed_parameter_count = function().num_fixed_parameters();
  const int optional_parameter_count = function().num_optional_parameters();
  const int parameter_count = fixed_parameter_count + optional_parameter_count;
  // Compute start indices to parameters and locals, and the number of
  // parameters to copy.
  if (optional_parameter_count == 0) {
    // Parameter i will be at fp[1 + parameter_count - i] and local variable
    // j will be at fp[kFirstLocalSlotIndex - j].
    first_parameter_index_ = 1 + parameter_count;
    first_stack_local_index_ = kFirstLocalSlotIndex;
    copied_parameter_count_ = 0;
  } else {
    // Parameter i will be at fp[kFirstLocalSlotIndex - i] and local variable
    // j will be at fp[kFirstLocalSlotIndex - parameter_count - j].
    first_parameter_index_ = kFirstLocalSlotIndex;
    first_stack_local_index_ = first_parameter_index_ - parameter_count;
    copied_parameter_count_ = parameter_count;
  }

  // Allocate parameters and local variables, either in the local frame or
  // in the context(s).
  LocalScope* context_owner = NULL;  // No context needed yet.
  int next_free_frame_index =
      scope->AllocateVariables(first_parameter_index_,
                               parameter_count,
                               first_stack_local_index_,
                               scope,
                               &context_owner);

  // If this function is not a closure function and if it contains captured
  // variables, the context needs to be saved on entry and restored on exit.
  // Add and allocate a local variable to this purpose.
  if ((context_owner != NULL) && !function().IsClosureFunction()) {
    const String& context_var_name =
        String::ZoneHandle(String::NewSymbol(":saved_entry_context_var"));
    LocalVariable* context_var =
        new LocalVariable(function().token_index(),
                          context_var_name,
                          Type::ZoneHandle(Type::DynamicType()));
    context_var->set_index(next_free_frame_index--);
    scope->AddVariable(context_var);
    set_saved_context_var(context_var);
  }

  // Frame indices are relative to the frame pointer and are decreasing.
  ASSERT(next_free_frame_index <= first_stack_local_index_);
  stack_local_count_ = first_stack_local_index_ - next_free_frame_index;
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
Parser::Parser(const Script& script,
               const Library& library)
    : script_(script),
      tokens_(TokenStream::Handle(script.tokens())),
      token_index_(0),
      current_block_(NULL),
      is_top_level_(false),
      current_member_(NULL),
      allow_function_literals_(true),
      current_function_(Function::Handle()),
      current_class_(Class::Handle()),
      library_(library),
      try_blocks_list_(NULL),
      expression_temp_(NULL) {
  ASSERT(!tokens_.IsNull());
  ASSERT(!library.IsNull());
  SetPosition(0);
}


// For parsing a function.
Parser::Parser(const Script& script,
               const Function& function,
               intptr_t token_index)
    : script_(script),
      tokens_(TokenStream::Handle(script.tokens())),
      token_index_(0),
      current_block_(NULL),
      is_top_level_(false),
      current_member_(NULL),
      allow_function_literals_(true),
      current_function_(function),
      current_class_(Class::Handle(current_function_.owner())),
      library_(Library::Handle(current_class_.library())),
      try_blocks_list_(NULL),
      expression_temp_(NULL)  {
  ASSERT(!tokens_.IsNull());
  ASSERT(!function.IsNull());
  SetPosition(token_index);
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


const Class& Parser::current_class() const {
  return current_class_;
}


void Parser::set_current_class(const Class& value) {
  current_class_ = value.raw();
}


void Parser::SetPosition(intptr_t position) {
  if (position < token_index_ && position != 0) {
    CompilerStats::num_tokens_rewind += (token_index_ - position);
  }
  token_index_ = position;
  token_kind_ = Token::kILLEGAL;
}


void Parser::ParseCompilationUnit(const Library& library,
                                  const Script& script) {
  ASSERT(Isolate::Current()->long_jump_base()->IsSafeToJump());
  TimerScope timer(FLAG_compiler_stats, &CompilerStats::parser_timer);
  Parser parser(script, library);
  parser.ParseTopLevel();
  if (FLAG_compiler_stats) {
    CompilerStats::num_tokens_total += parser.tokens_.Length();
  }
}


Token::Kind Parser::CurrentToken() {
  if (token_kind_ == Token::kILLEGAL) {
    token_kind_ = tokens_.KindAt(token_index_);
    if (token_kind_ == Token::kERROR) {
      ErrorMsg(token_index_, CurrentLiteral()->ToCString());
    }
  }
  CompilerStats::num_token_checks++;
  return token_kind_;
}


Token::Kind Parser::LookaheadToken(int num_tokens) {
  CompilerStats::num_tokens_lookahead++;
  CompilerStats::num_token_checks++;
  return tokens_.KindAt(token_index_ + num_tokens);
}


String* Parser::CurrentLiteral() const {
  String& result = String::ZoneHandle();
  result ^= tokens_.LiteralAt(token_index_);
  return &result;
}


RawDouble* Parser::CurrentDoubleLiteral() const {
  LiteralToken& token = LiteralToken::Handle();
  token ^= tokens_.TokenAt(token_index_);
  ASSERT(token.kind() == Token::kDOUBLE);
  return reinterpret_cast<RawDouble*>(token.value());
}


RawInteger* Parser::CurrentIntegerLiteral() const {
  LiteralToken& token = LiteralToken::Handle();
  token ^= tokens_.TokenAt(token_index_);
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
    has_named_optional_parameters = false;
    has_field_initializer = false;
    implicitly_final = false;
    this->parameters = new ZoneGrowableArray<ParamDesc>();
  }

  void AddFinalParameter(intptr_t name_pos,
                         const char* name,
                         const AbstractType* type) {
    this->num_fixed_parameters++;
    ParamDesc param;
    param.name_pos = name_pos;
    param.name = &String::ZoneHandle(String::NewSymbol(name));
    param.is_final = true;
    param.type = type;
    this->parameters->Add(param);
  }

  void AddReceiver(intptr_t name_pos) {
    ASSERT(this->parameters->length() == 0);
    // The receiver does not need to be type checked.
    AddFinalParameter(name_pos,
                      kThisName,
                      &Type::ZoneHandle(Type::DynamicType()));
  }

  void SetImplicitlyFinal() {
    implicitly_final = true;
  }

  int num_fixed_parameters;
  int num_optional_parameters;
  bool has_named_optional_parameters;  // Indicates use of the new syntax.
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
    has_final = false;
    has_const = false;
    has_static = false;
    has_var = false;
    has_factory = false;
    type = NULL;
    name_pos = 0;
    name = NULL;
    redirect_name = NULL;
    params.Clear();
    kind = RawFunction::kFunction;
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
  bool has_final;
  bool has_const;
  bool has_static;
  bool has_var;
  bool has_factory;
  const AbstractType* type;
  intptr_t name_pos;
  String* name;
  String* redirect_name;  // For constructors: NULL or redirected constructor.
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

  bool FunctionNameExists(const String& name, RawFunction::Kind kind) const {
    // First check if a function or field of same name exists.
    if (NameExists<Function>(functions_, name) ||
        NameExists<Field>(fields_, name)) {
      return true;
    }
    String& accessor_name = String::Handle();
    if (kind != RawFunction::kSetterFunction) {
      // Check if a getter function of same name exists.
      accessor_name = Field::GetterName(name);
      if (NameExists<Function>(functions_, accessor_name)) {
        return true;
      }
    }
    if (kind != RawFunction::kGetterFunction) {
      // Check if a setter function of same name exists.
      accessor_name = Field::SetterName(name);
      if (NameExists<Function>(functions_, accessor_name)) {
        return true;
      }
    }
    return false;
  }

  bool FieldNameExists(const String& name) const {
    // First check if a function or field of same name exists.
    if (NameExists<Function>(functions_, name) ||
        NameExists<Field>(fields_, name)) {
      return true;
    }
    // Now check if a getter/setter function of same name exists.
    String& getter_name = String::Handle(Field::GetterName(name));
    String& setter_name = String::Handle(Field::SetterName(name));
    if (NameExists<Function>(functions_, getter_name) ||
        NameExists<Function>(functions_, setter_name)) {
      return true;
    }
    return false;
  }

  void AddFunction(const Function& function) {
    ASSERT(!NameExists<Function>(functions_, String::Handle(function.name())));
    functions_.Add(function);
  }

  const GrowableObjectArray& functions() const {
    return functions_;
  }

  void AddField(const Field& field) {
    ASSERT(!NameExists<Field>(fields_, String::Handle(field.name())));
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
  template<typename T>
  bool NameExists(const GrowableObjectArray& list, const String& name) const {
    String& test_name = String::Handle();
    T& obj = T::Handle();
    for (int i = 0; i < list.Length(); i++) {
      obj ^= list.At(i);
      test_name = obj.name();
      if (name.Equals(test_name)) {
        return true;
      }
    }
    return false;
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
  // Compilation can be nested, preserve the ast node id.
  const intptr_t prev_ast_node_id = isolate->ast_node_id();
  isolate->set_ast_node_id(0);
  ASSERT(parsed_function != NULL);
  const Function& func = parsed_function->function();
  const Class& cls = Class::Handle(isolate, func.owner());
  const Script& script = Script::Handle(isolate, cls.script());
  Parser parser(script, func, func.token_index());
  SequenceNode* node_sequence = NULL;
  Array& default_parameter_values = Array::Handle(isolate, Array::null());
  switch (func.kind()) {
    case RawFunction::kFunction:
    case RawFunction::kClosureFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction:
    case RawFunction::kConstructor:
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
    node_sequence->Add(new ReturnNode(parser.token_index_));
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
    // receiver was captured.
    const bool kTestOnly = true;
    LocalVariable* receiver =
        parser.LookupReceiver(node_sequence->scope(),
                              kTestOnly);
    if (!parser.current_function().IsLocalFunction() ||
        ((receiver != NULL) && receiver->is_captured())) {
      parsed_function->set_instantiator(
          new LoadLocalNode(node_sequence->token_index(), *receiver));
    }
  }

  parsed_function->set_default_parameter_values(default_parameter_values);
  isolate->set_ast_node_id(prev_ast_node_id);
}


// TODO(regis): Implement support for non-const final static fields (currently
// supported "final" fields are actually const fields).
// TODO(regis): Since a const variable is implicitly final,
// rename ParseStaticConstGetter to ParseStaticFinalGetter and
// rename kConstImplicitGetter to kImplicitFinalGetter.
SequenceNode* Parser::ParseStaticConstGetter(const Function& func) {
  TRACE_PARSER("ParseStaticConstGetter");
  ParamList params;
  ASSERT(func.num_fixed_parameters() == 0);  // static.
  ASSERT(func.num_optional_parameters() == 0);
  ASSERT(AbstractType::Handle(func.result_type()).IsResolved());

  // Build local scope for function and populate with the formal parameters.
  OpenFunctionBlock(func);
  AddFormalParamsToScope(&params, current_block_->scope);

  const String& field_name = *ExpectIdentifier("field name expected");
  const Class& field_class = Class::Handle(func.owner());
  const Field& field =
      Field::ZoneHandle(field_class.LookupStaticField(field_name));

  // Static const fields must have an initializer.
  ExpectToken(Token::kASSIGN);

  // We don't want to use ParseConstExpr() here because we don't want
  // the constant folding code to create, compile and execute a code
  // fragment to evaluate the expression. Instead, we just make sure
  // the static const field initializer is a constant expression and
  // leave the evaluation to the getter function.
  const intptr_t expr_pos = token_index_;
  AstNode* expr = ParseExpr(kAllowConst);
  if (field.is_const()) {
    // This getter will only be called once at compile time.
    if (expr->EvalConstExpr() == NULL) {
      ErrorMsg(expr_pos, "initializer must be a compile time constant");
    }
    ReturnNode* return_node = new ReturnNode(token_index_, expr);
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

    // TODO(regis): Remove this check once we support proper const fields.
    if (expr->EvalConstExpr() == NULL) {
      ErrorMsg(expr_pos, "initializer must be a compile time constant");
    }

    // Generate code checking for circular dependency in field initialization.
    AstNode* compare_circular = new ComparisonNode(
        token_index_,
        Token::kEQ_STRICT,
        new LoadStaticFieldNode(token_index_, field),
        new LiteralNode(token_index_,
                        Instance::ZoneHandle(Object::transition_sentinel())));
    // Set field to null prior to throwing exception, so that subsequent
    // accesses to the field do not throw again, since initializers should only
    // be executed once.
    SequenceNode* report_circular = new SequenceNode(token_index_, NULL);
    report_circular->Add(
        new StoreStaticFieldNode(
            token_index_,
            field,
            new LiteralNode(token_index_, Instance::ZoneHandle())));
    // TODO(regis): Exception to throw is not specified by spec.
    const String& circular_error = String::ZoneHandle(
        String::NewSymbol("circular dependency in field initialization"));
    report_circular->Add(
        new ThrowNode(token_index_,
                      new LiteralNode(token_index_, circular_error),
                      NULL));
    AstNode* circular_check =
        new IfNode(token_index_, compare_circular, report_circular, NULL);
    current_block_->statements->Add(circular_check);

    // Generate code checking for uninitialized field.
    AstNode* compare_uninitialized = new ComparisonNode(
        token_index_,
        Token::kEQ_STRICT,
        new LoadStaticFieldNode(token_index_, field),
        new LiteralNode(token_index_,
                        Instance::ZoneHandle(Object::sentinel())));
    SequenceNode* initialize_field = new SequenceNode(token_index_, NULL);
    initialize_field->Add(
        new StoreStaticFieldNode(
            token_index_,
            field,
            new LiteralNode(
                token_index_,
                Instance::ZoneHandle(Object::transition_sentinel()))));
    initialize_field->Add(new StoreStaticFieldNode(token_index_, field, expr));
    AstNode* uninitialized_check =
        new IfNode(token_index_, compare_uninitialized, initialize_field, NULL);
    current_block_->statements->Add(uninitialized_check);

    // Generate code returning the field value.
    ReturnNode* return_node =
        new ReturnNode(token_index_,
                       new LoadStaticFieldNode(token_index_, field));
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
  params.AddReceiver(token_index_);
  ASSERT(func.num_fixed_parameters() == 1);  // receiver.
  ASSERT(func.num_optional_parameters() == 0);
  ASSERT(AbstractType::Handle(func.result_type()).IsResolved());

  // Build local scope for function and populate with the formal parameters.
  OpenFunctionBlock(func);
  AddFormalParamsToScope(&params, current_block_->scope);

  // Receiver is local 0.
  LocalVariable* receiver = current_block_->scope->VariableAt(0);
  LoadLocalNode* load_receiver = new LoadLocalNode(token_index_, *receiver);
  // token_index_ is the function's token position which points to the name of
  // the field;
  ASSERT(IsIdentifier());
  const String& field_name = *CurrentLiteral();
  const Class& field_class = Class::Handle(func.owner());
  const Field& field =
      Field::ZoneHandle(field_class.LookupInstanceField(field_name));

  LoadInstanceFieldNode* load_field =
      new LoadInstanceFieldNode(token_index_, load_receiver, field);

  ReturnNode* return_node = new ReturnNode(token_index_, load_field);
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
  // token_index_ is the function's token position which points to the name of
  // the field; we can use it to form the field_name.
  const String& field_name = *CurrentLiteral();
  const Class& field_class = Class::ZoneHandle(func.owner());
  const Field& field =
      Field::ZoneHandle(field_class.LookupInstanceField(field_name));
  const AbstractType& field_type = AbstractType::ZoneHandle(field.type());

  ParamList params;
  params.AddReceiver(token_index_);
  params.AddFinalParameter(token_index_, "value", &field_type);
  ASSERT(func.num_fixed_parameters() == 2);  // receiver, value.
  ASSERT(func.num_optional_parameters() == 0);
  ASSERT(AbstractType::Handle(func.result_type()).IsVoidType());

  // Build local scope for function and populate with the formal parameters.
  OpenFunctionBlock(func);
  AddFormalParamsToScope(&params, current_block_->scope);

  LoadLocalNode* receiver =
      new LoadLocalNode(token_index_, *current_block_->scope->VariableAt(0));
  LoadLocalNode* value =
      new LoadLocalNode(token_index_, *current_block_->scope->VariableAt(1));

  StoreInstanceFieldNode* store_field =
      new StoreInstanceFieldNode(token_index_, receiver, field, value);

  current_block_->statements->Add(store_field);
  current_block_->statements->Add(new ReturnNode(token_index_));
  return CloseBlock();
}


void Parser::SkipBlock() {
  ASSERT(CurrentToken() == Token::kLBRACE);
  GrowableArray<Token::Kind> token_stack(8);
  const intptr_t block_start_pos = token_index_;
  bool is_match = true;
  bool unexpected_token_found = false;
  Token::Kind token;
  intptr_t token_index;
  do {
    token = CurrentToken();
    token_index = token_index_;
    switch (token) {
      case Token::kLBRACE:
      case Token::kLPAREN:
      case Token::kLBRACK:
        token_stack.Add(token);
        break;
      case Token::kRBRACE:
        is_match = token_stack.Last() == Token::kLBRACE;
        token_stack.RemoveLast();
        break;
      case Token::kRPAREN:
        is_match = token_stack.Last() == Token::kLPAREN;
        token_stack.RemoveLast();
        break;
      case Token::kRBRACK:
        is_match = token_stack.Last() == Token::kLBRACK;
        token_stack.RemoveLast();
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
    ErrorMsg(token_index, "unbalanced '%s'", Token::Str(token));
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

  if (CurrentToken() == Token::kFINAL) {
    ConsumeToken();
    parameter.is_final = true;
  } else if (CurrentToken() == Token::kVAR) {
    ConsumeToken();
    var_seen = true;
    // The parameter type is the 'Dynamic' type.
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
                                    ClassFinalizer::kFinalize));
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
  parameter.name_pos = token_index_;
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
      const bool no_explicit_default_values = false;
      ParseFormalParameterList(no_explicit_default_values, &func_params);

      // The field 'is_static' has no meaning for signature functions.
      const Function& signature_function = Function::Handle(
          Function::New(*parameter.name,
                        RawFunction::kSignatureFunction,
                        /* is_static = */ false,
                        /* is_const = */ false,
                        parameter.name_pos));
      signature_function.set_owner(current_class());
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
            signature_class, signature_type, ClassFinalizer::kFinalize);
      }
      // The type of the parameter is now the signature type.
      parameter.type = &signature_type;
    }
  }

  if (CurrentToken() == Token::kASSIGN) {
    if (!params->has_named_optional_parameters ||
        !allow_explicit_default_value) {
      ErrorMsg("parameter must not specify a default value");
    }
    ConsumeToken();
    params->num_optional_parameters++;
    if (is_top_level_) {
      // Skip default value parsing.
      SkipExpr();
    } else {
      const Object& const_value = ParseConstExpr()->literal();
      parameter.default_value = &const_value;
    }
  } else {
    if (params->has_named_optional_parameters) {
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


void Parser::ParseFormalParameterList(bool allow_explicit_default_values,
                                      ParamList* params) {
  TRACE_PARSER("ParseFormalParameterList");
  ASSERT(CurrentToken() == Token::kLPAREN);

  if (LookaheadToken(1) != Token::kRPAREN) {
    // Parse positional parameters.
    ParseFormalParameters(allow_explicit_default_values,
                          params);
    if (params->has_named_optional_parameters) {
      // Parse named optional parameters.
      ParseFormalParameters(allow_explicit_default_values,
                            params);
      if (CurrentToken() != Token::kRBRACK) {
        ErrorMsg("',' or ']' expected");
      }
      ExpectToken(Token::kRBRACK);
    }
    if ((CurrentToken() != Token::kRPAREN) &&
        !params->has_named_optional_parameters) {
      ErrorMsg("',' or ')' expected");
    }
  } else {
    ConsumeToken();
  }
  ExpectToken(Token::kRPAREN);
}


// Parses a sequence of normal or named formal parameters.
void Parser::ParseFormalParameters(bool allow_explicit_default_values,
                                   ParamList* params) {
  TRACE_PARSER("ParseFormalParameters");
  do {
    ConsumeToken();
    if (!params->has_named_optional_parameters &&
        (CurrentToken() == Token::kLBRACK)) {
      // End of normal parameters, start of named parameters.
      params->has_named_optional_parameters = true;
      return;
    }
    ParseFormalParameter(allow_explicit_default_values, params);
  } while (CurrentToken() == Token::kCOMMA);
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


void Parser::CheckFunctionIsCallable(intptr_t token_index,
                                     const Function& function) {
  if (Class::Handle(function.owner()).is_interface()) {
    ErrorMsg(token_index, "cannot call function of interface '%s'",
        function.ToFullyQualifiedCString());
  }
}


static RawFunction* ResolveDynamicFunction(const Class& cls,
                                           const String& name) {
  Function& func = Function::Handle(cls.LookupDynamicFunction(name));
  if (func.IsNull()) {
    Class& super_cls = Class::Handle(cls.SuperClass());
    while (!super_cls.IsNull()) {
      func = super_cls.LookupDynamicFunction(name);
      if (!func.IsNull()) {
        return func.raw();
      }
      super_cls = super_cls.SuperClass();
    }
  }
  return func.raw();
}


RawFunction* Parser::GetSuperFunction(intptr_t token_pos,
                                      const String& name) {
  const Class& super_class = Class::Handle(current_class().SuperClass());
  if (super_class.IsNull()) {
    ErrorMsg(token_pos, "class '%s' does not have a superclass",
             String::Handle(current_class().Name()).ToCString());
  }

  const Function& super_func =
      Function::Handle(ResolveDynamicFunction(super_class, name));
  if (super_func.IsNull()) {
    ErrorMsg(token_pos, "function '%s' not found in super class",
             name.ToCString());
  }
  CheckFunctionIsCallable(token_pos, super_func);
  return super_func.raw();
}


AstNode* Parser::ParseSuperCall(const String& function_name) {
  TRACE_PARSER("ParseSuperCall");
  ASSERT(CurrentToken() == Token::kLPAREN);
  const intptr_t supercall_pos = token_index_;

  const Function& super_function = Function::ZoneHandle(
      GetSuperFunction(supercall_pos, function_name));

  ArgumentListNode* arguments = new ArgumentListNode(supercall_pos);
  // 'this' parameter is the first argument to super call.
  AstNode* receiver = LoadReceiver(supercall_pos);
  arguments->Add(receiver);
  ParseActualParameters(arguments, kAllowConst);
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


AstNode* Parser::ParseSuperOperator() {
  TRACE_PARSER("ParseSuperOperator");
  AstNode* super_op = NULL;
  const intptr_t operator_pos = token_index_;

  if (CurrentToken() == Token::kLBRACK) {
    ConsumeToken();
    AstNode* index_expr = ParseExpr(kAllowConst);
    ExpectToken(Token::kRBRACK);

    if (Token::IsAssignmentOperator(CurrentToken()) &&
        (CurrentToken() != Token::kASSIGN)) {
      // Compound assignment. Ensure side effects in index expression
      // only execute once. If the index is not a local variable or an
      // literal, evaluate and save in a temporary local.
      if (!IsSimpleLocalOrLiteralNode(index_expr)) {
        LocalVariable* temp =
            CreateTempConstVariable(operator_pos, index_expr->id(), "lix");
        AstNode* save =
            new StoreLocalNode(operator_pos, *temp, index_expr);
        current_block_->statements->Add(save);
        index_expr = new LoadLocalNode(operator_pos, *temp);
      }
    }

    // Resolve the [] operator function in the superclass.
    const String& index_operator_name =
        String::ZoneHandle(String::NewSymbol(Token::Str(Token::kINDEX)));
    const Function& index_operator = Function::ZoneHandle(
        GetSuperFunction(operator_pos, index_operator_name));

    ArgumentListNode* index_op_arguments = new ArgumentListNode(operator_pos);
    AstNode* receiver = LoadReceiver(operator_pos);
    index_op_arguments->Add(receiver);
    index_op_arguments->Add(index_expr);

    super_op = new StaticCallNode(
        operator_pos, index_operator, index_op_arguments);

    if (Token::IsAssignmentOperator(CurrentToken())) {
      Token::Kind assignment_op = CurrentToken();
      ConsumeToken();
      AstNode* value = ParseExpr(kAllowConst);

      value = ExpandAssignableOp(operator_pos, assignment_op, super_op, value);

      // Resolve the []= operator function in the superclass.
      const String& assign_index_operator_name = String::ZoneHandle(
          String::NewSymbol(Token::Str(Token::kASSIGN_INDEX)));
      const Function& assign_index_operator = Function::ZoneHandle(
          GetSuperFunction(operator_pos, assign_index_operator_name));

      ArgumentListNode* operator_args = new ArgumentListNode(operator_pos);
      operator_args->Add(LoadReceiver(operator_pos));
      operator_args->Add(index_expr);
      operator_args->Add(value);

      super_op = new StaticCallNode(
          operator_pos, assign_index_operator, operator_args);
    }
  } else if (Token::CanBeOverloaded(CurrentToken())) {
    Token::Kind op = CurrentToken();
    ConsumeToken();

    // Resolve the operator function in the superclass.
    const String& operator_function_name =
        String::Handle(String::NewSymbol(Token::Str(op)));
    const Function& super_operator = Function::ZoneHandle(
        GetSuperFunction(operator_pos, operator_function_name));

    ASSERT(Token::Precedence(op) >= Token::Precedence(Token::kBIT_OR));
    AstNode* other_operand = ParseBinaryExpr(Token::Precedence(op) + 1);

    ArgumentListNode* op_arguments = new ArgumentListNode(operator_pos);
    AstNode* receiver = LoadReceiver(operator_pos);
    op_arguments->Add(receiver);
    op_arguments->Add(other_operand);

    CheckFunctionIsCallable(operator_pos, super_operator);
    super_op = new StaticCallNode(operator_pos, super_operator, op_arguments);
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
        CaptureReceiver();
      }
    }
  }
  return new ClosureNode(token_pos, implicit_closure_function, receiver, NULL);
}


AstNode* Parser::ParseSuperFieldAccess(const String& field_name) {
  TRACE_PARSER("ParseSuperFieldAccess");
  const intptr_t field_pos = token_index_;
  const Class& super_class = Class::Handle(current_class().SuperClass());
  if (super_class.IsNull()) {
    ErrorMsg("class '%s' does not have a superclass",
             String::Handle(current_class().Name()).ToCString());
  }
  AstNode* implicit_argument = LoadReceiver(field_pos);

  const String& getter_name =
      String::ZoneHandle(Field::GetterName(field_name));
  const Function& super_getter = Function::ZoneHandle(
      ResolveDynamicFunction(super_class, getter_name));
  if (super_getter.IsNull()) {
    // Check if this is an access to an implicit closure using 'super'.
    // If a function exists of the specified field_name then try
    // accessing it as a getter, at runtime we will handle this by
    // creating an implicit closure of the function and returning it.
    const Function& super_function = Function::ZoneHandle(
        ResolveDynamicFunction(super_class, field_name));
    if (super_function.IsNull()) {
      ErrorMsg(field_pos, "field or getter '%s' not found in superclass",
               field_name.ToCString());
    }
    return CreateImplicitClosureNode(super_function,
                                     field_pos,
                                     implicit_argument);
  }
  // All dynamic getters take one argument and no named arguments.
  ASSERT(super_getter.AreValidArgumentCounts(1, 0));
  ArgumentListNode* getter_arguments = new ArgumentListNode(field_pos);
  getter_arguments->Add(implicit_argument);
  AstNode* super_field =
      new StaticCallNode(field_pos, super_getter, getter_arguments);

  if (Token::IsAssignmentOperator(CurrentToken())) {
    const String& setter_name =
        String::ZoneHandle(Field::SetterName(field_name));
    const Function& super_setter = Function::ZoneHandle(
        ResolveDynamicFunction(super_class, setter_name));
    if (super_setter.IsNull()) {
      ErrorMsg(field_pos,
               "field '%s' not assignable in superclass",
               field_name.ToCString());
    }
    // All dynamic setters take two arguments and no named arguments.
    ASSERT(super_setter.AreValidArgumentCounts(2, 0));

    Token::Kind assignment_op = CurrentToken();
    ConsumeToken();
    AstNode* value = ParseExpr(kAllowConst);
    value = ExpandAssignableOp(field_pos, assignment_op, super_field, value);

    ArgumentListNode* setter_arguments = new ArgumentListNode(field_pos);
    setter_arguments->Add(implicit_argument);
    setter_arguments->Add(value);
    super_field = new StaticCallNode(field_pos, super_setter, setter_arguments);
  }
  return super_field;
}


void Parser::GenerateSuperConstructorCall(const Class& cls,
                                          LocalVariable* receiver) {
  const intptr_t supercall_pos = token_index_;
  const Class& super_class = Class::Handle(cls.SuperClass());
  // Omit the implicit super() if there is no super class (i.e.
  // we're not compiling class Object), or if the super class is an
  // artificially generated "wrapper class" that has no constructor.
  if (super_class.IsNull() || (super_class.num_native_fields() > 0)) {
    return;
  }
  String& ctor_name = String::Handle(super_class.Name());
  String& ctor_suffix = String::Handle(String::NewSymbol("."));
  ctor_name = String::Concat(ctor_name, ctor_suffix);
  ArgumentListNode* arguments = new ArgumentListNode(supercall_pos);
  // Implicit 'this' parameter is the first argument.
  AstNode* implicit_argument = new LoadLocalNode(supercall_pos, *receiver);
  arguments->Add(implicit_argument);
  // Implicit construction phase parameter is second argument.
  AstNode* phase_parameter =
      new LiteralNode(supercall_pos,
                      Smi::ZoneHandle(Smi::New(Function::kCtorPhaseAll)));
  arguments->Add(phase_parameter);
  const Function& super_ctor = Function::ZoneHandle(
      super_class.LookupConstructor(ctor_name));
  if (super_ctor.IsNull() ||
      !super_ctor.AreValidArguments(arguments->length(),
                                    arguments->names())) {
    ErrorMsg(supercall_pos,
             "unresolved implicit call to super constructor '%s()'",
             String::Handle(super_class.Name()).ToCString());
  }
  CheckFunctionIsCallable(supercall_pos, super_ctor);
  current_block_->statements->Add(
      new StaticCallNode(supercall_pos, super_ctor, arguments));
}


AstNode* Parser::ParseSuperInitializer(const Class& cls,
                                       LocalVariable* receiver) {
  TRACE_PARSER("ParseSuperInitializer");
  ASSERT(CurrentToken() == Token::kSUPER);
  const intptr_t supercall_pos = token_index_;
  ConsumeToken();
  const Class& super_class = Class::Handle(cls.SuperClass());
  ASSERT(!super_class.IsNull());
  String& ctor_name = String::Handle(super_class.Name());
  String& ctor_suffix = String::Handle(String::NewSymbol("."));
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
  AstNode* implicit_argument = new LoadLocalNode(supercall_pos, *receiver);
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
  if (super_ctor.IsNull() ||
      !super_ctor.AreValidArguments(arguments->length(),
                                    arguments->names())) {
    ErrorMsg(supercall_pos,
             "super class constructor '%s' not found",
             ctor_name.ToCString());
  }
  CheckFunctionIsCallable(supercall_pos, super_ctor);
  return new StaticCallNode(supercall_pos, super_ctor, arguments);
}


AstNode* Parser::ParseInitializer(const Class& cls, LocalVariable* receiver) {
  TRACE_PARSER("ParseInitializer");
  const intptr_t field_pos = token_index_;
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
  AstNode* instance = new LoadLocalNode(field_pos, *receiver);
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


struct FieldInitExpression {
  Field* inst_field;
  AstNode* expr;
};


void Parser::ParseInitializedInstanceFields(const Class& cls,
                 GrowableArray<FieldInitExpression>* initializers) {
  TRACE_PARSER("ParseInitializedInstanceFields");
  const Array& fields = Array::Handle(cls.fields());
  Field& f = Field::Handle();
  const intptr_t saved_pos = token_index_;
  for (int i = 0; i < fields.Length(); i++) {
    f ^= fields.At(i);
    if (!f.is_static() && f.has_initializer()) {
      Field& field = Field::ZoneHandle();
      field ^= fields.At(i);
      intptr_t field_pos = field.token_index();
      SetPosition(field_pos);
      ASSERT(IsIdentifier());
      ConsumeToken();
      ExpectToken(Token::kASSIGN);
      AstNode* init_expr = ParseConstExpr();
      ASSERT(init_expr != NULL);
      FieldInitExpression initializer;
      initializer.inst_field = &field;
      initializer.expr = init_expr;
      initializers->Add(initializer);
    }
  }
  SetPosition(saved_pos);
}


void Parser::ParseInitializers(const Class& cls, LocalVariable* receiver) {
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
        init_statement = ParseInitializer(cls, receiver);
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
  const intptr_t call_pos = token_index_;
  ConsumeToken();
  String& ctor_name = String::Handle(cls.Name());
  String& ctor_suffix = String::Handle(String::NewSymbol("."));

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
  AstNode* implicit_argument = new LoadLocalNode(call_pos, *receiver);
  arguments->Add(implicit_argument);
  // Construction phase parameter is second argument.
  LocalVariable* phase_param = LookupPhaseParameter();
  ASSERT(phase_param != NULL);
  AstNode* phase_argument = new LoadLocalNode(call_pos, *phase_param);
  arguments->Add(phase_argument);
  ParseActualParameters(arguments, kAllowConst);

  // Resolve the constructor.
  const Function& redirect_ctor = Function::ZoneHandle(
      cls.LookupConstructor(ctor_name));
  if (redirect_ctor.IsNull() ||
      !redirect_ctor.AreValidArguments(arguments->length(),
                                       arguments->names())) {
    ErrorMsg(call_pos, "constructor '%s' not found",
             ctor_name.ToCString());
  }
  CheckFunctionIsCallable(call_pos, redirect_ctor);
  current_block_->statements->Add(
      new StaticCallNode(call_pos, redirect_ctor, arguments));
}


SequenceNode* Parser::MakeImplicitConstructor(const Function& func) {
  ASSERT(func.IsConstructor());
  const intptr_t ctor_pos = token_index_;

  // Implicit 'this' is the only parameter/local variable.
  OpenFunctionBlock(func);

  // Parse expressions of instance fields that have an explicit
  // initializers.
  GrowableArray<FieldInitExpression> initializers;
  Class& cls = Class::Handle(func.owner());
  ParseInitializedInstanceFields(cls, &initializers);

  LocalVariable* receiver = new LocalVariable(
      ctor_pos,
      String::ZoneHandle(String::NewSymbol(kThisName)),
      Type::ZoneHandle(Type::DynamicType()));
  current_block_->scope->AddVariable(receiver);

  LocalVariable* phase_parameter = new LocalVariable(
       ctor_pos,
       String::ZoneHandle(String::NewSymbol(kPhaseParameterName)),
       Type::ZoneHandle(Type::DynamicType()));
  current_block_->scope->AddVariable(phase_parameter);

  // Now that the "this" parameter is in scope, we can generate the code
  // to strore the initializer expressions in the respective instance fields.
  for (int i = 0; i < initializers.length(); i++) {
    const Field* field = initializers[i].inst_field;
    AstNode* instance = new LoadLocalNode(field->token_index(), *receiver);
    AstNode* field_init =
        new StoreInstanceFieldNode(field->token_index(),
                                   instance,
                                   *field,
                                   initializers[i].expr);
    current_block_->statements->Add(field_init);
  }

  GenerateSuperConstructorCall(cls, receiver);
  CheckConstFieldsInitialized(cls);

  // Empty constructor body.
  SequenceNode* statements = CloseBlock();
  return statements;
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
  const Class& cls = Class::Handle(func.owner());
  ASSERT(!cls.IsNull());

  if (CurrentToken() == Token::kCLASS) {
    // Special case: implicit constructor.
    // The parser adds an implicit default constructor when a class
    // does not have any explicit constructor or factory (see
    // Parser::CheckConstructors). The token position of this implicit
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
  params.AddReceiver(token_index_);

  // Add implicit parameter for construction phase.
  params.AddFinalParameter(
      token_index_,
      kPhaseParameterName,
      &Type::ZoneHandle(Type::DynamicType()));

  if (func.is_const()) {
    params.SetImplicitlyFinal();
  }
  ParseFormalParameterList(allow_explicit_default_values, &params);

  SetupDefaultsForOptionalParams(&params, default_parameter_values);
  ASSERT(AbstractType::Handle(func.result_type()).IsResolved());
  ASSERT(func.NumberOfParameters() == params.parameters->length());

  // Initialize instance fields that have an explicit initializer expression.
  // This has to be done before code for field initializer parameters
  // is generated.
  // NB: the instance field initializers have to be compiled before
  // the parameters are added to the scope, so that a parameter
  // name cannot shadow a name used in the field initializer expression.
  GrowableArray<FieldInitExpression> initializers;
  ParseInitializedInstanceFields(cls, &initializers);

  // Now populate function scope with the formal parameters.
  AddFormalParamsToScope(&params, current_block_->scope);
  LocalVariable* receiver = current_block_->scope->VariableAt(0);

  // Now that the "this" parameter is in scope, we can generate the code
  // to store the initializer expressions in the respective instance fields.
  // We do this before the field parameters and the initializers from the
  // constructor's initializer list get compiled.
  OpenBlock();
  for (int i = 0; i < initializers.length(); i++) {
    const Field* field = initializers[i].inst_field;
    AstNode* instance = new LoadLocalNode(field->token_index(), *receiver);
    AstNode* field_init =
        new StoreInstanceFieldNode(field->token_index(),
                                   instance,
                                   *field,
                                   initializers[i].expr);
    current_block_->statements->Add(field_init);
  }

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
        AstNode* instance = new LoadLocalNode(param.name_pos, *receiver);
        LocalVariable* p =
            current_block_->scope->LookupVariable(*param.name, false);
        ASSERT(p != NULL);
        // Initializing formals cannot be used in the explicit initializer
        // list, nor can they be used in the constructor body.
        // Thus, make the parameter invisible.
        p->set_invisible(true);
        AstNode* value = new LoadLocalNode(param.name_pos, *p);
        AstNode* initializer = new StoreInstanceFieldNode(
            param.name_pos, instance, field, value);
        current_block_->statements->Add(initializer);
      }
    }
  }

  // Now parse the explicit initializer list or constructor redirection.
  ParseInitializers(cls, receiver);

  SequenceNode* init_statements = CloseBlock();
  if (init_statements->length() > 0) {
    // Generate guard around the initializer code.
    LocalVariable* phase_param = LookupPhaseParameter();
    AstNode* phase_value = new LoadLocalNode(token_index_, *phase_param);
    AstNode* phase_check = new BinaryOpNode(
        token_index_, Token::kBIT_AND, phase_value,
        new LiteralNode(token_index_,
                        Smi::ZoneHandle(Smi::New(Function::kCtorPhaseInit))));
    AstNode* comparison =
        new ComparisonNode(token_index_, Token::kNE_STRICT,
                           phase_check,
                           new LiteralNode(token_index_,
                                           Smi::ZoneHandle(Smi::New(0))));
    AstNode* guarded_init_statements =
        new IfNode(token_index_, comparison, init_statements, NULL);
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
            CreateTempConstVariable(arg->token_index(), arg->id(), "sca");
        AstNode* save_temp =
            new StoreLocalNode(arg->token_index(), *temp, arg);
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
        new LiteralNode(token_index_,
                        Smi::ZoneHandle(Smi::New(Function::kCtorPhaseInit))));

    ArgumentListNode* super_call_args = new ArgumentListNode(token_index_);
    // First argument is the receiver.
    super_call_args->Add(new LoadLocalNode(token_index_, *receiver));
    // Second argument is the construction phase argument.
    AstNode* phase_parameter =
    new LiteralNode(token_index_,
                    Smi::ZoneHandle(Smi::New(Function::kCtorPhaseBody)));
    super_call_args->Add(phase_parameter);
    super_call_args->set_names(initializer_args->names());
    for (int i = 2; i < initializer_args->length(); i++) {
      AstNode* arg = initializer_args->NodeAt(i);
      if (arg->IsLiteralNode()) {
        LiteralNode* lit = arg->AsLiteralNode();
        super_call_args->Add(new LiteralNode(token_index_, lit->literal()));
      } else {
        ASSERT(arg->IsLoadLocalNode() || arg->IsStoreLocalNode());
        if (arg->IsLoadLocalNode()) {
          const LocalVariable& temp = arg->AsLoadLocalNode()->local();
          super_call_args->Add(new LoadLocalNode(token_index_, temp));
        } else if (arg->IsStoreLocalNode()) {
          const LocalVariable& temp = arg->AsStoreLocalNode()->local();
          super_call_args->Add(new LoadLocalNode(token_index_, temp));
        }
      }
    }
    ASSERT(super_ctor.AreValidArguments(super_call_args->length(),
                                        super_call_args->names()));
    current_block_->statements->Add(
        new StaticCallNode(token_index_, super_ctor, super_call_args));
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
    AstNode* phase_value = new LoadLocalNode(token_index_, *phase_param);
    AstNode* phase_check =
        new BinaryOpNode(token_index_, Token::kBIT_AND,
            phase_value,
            new LiteralNode(token_index_,
                Smi::ZoneHandle(Smi::New(Function::kCtorPhaseBody))));
    AstNode* comparison =
       new ComparisonNode(token_index_, Token::kNE_STRICT,
                         phase_check,
                         new LiteralNode(token_index_,
                                         Smi::ZoneHandle(Smi::New(0))));
    AstNode* guarded_block_statements =
        new IfNode(token_index_, comparison, ctor_block, NULL);
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
  if (func.IsConstructor()) {
    return ParseConstructor(func, default_parameter_values);
  }

  ASSERT(!func.IsConstructor());
  OpenFunctionBlock(func);  // Build local scope for function.

  ParamList params;
  // Static functions do not have a receiver.
  // An instance closure may capture and access the receiver, but via the
  // context and not via the first formal parameter.
  // The first parameter of a factory is the AbstractTypeArguments vector of the
  // type of the instance to be allocated. We name this hidden parameter 'this'.
  const bool has_receiver = !func.IsClosureFunction() &&
                            (!func.is_static() || func.IsFactory());
  const bool allow_explicit_default_values = true;
  if (has_receiver) {
    params.AddReceiver(token_index_);
  }
  ASSERT(CurrentToken() == Token::kLPAREN);
  ParseFormalParameterList(allow_explicit_default_values, &params);

  // The number of parameters and their type are not yet set in local functions,
  // since they are not 'top-level' parsed.
  if (func.IsLocalFunction()) {
    AddFormalParamsToFunction(&params, func);
  }
  SetupDefaultsForOptionalParams(&params, default_parameter_values);
  ASSERT(AbstractType::Handle(func.result_type()).IsResolved());
  ASSERT(func.NumberOfParameters() == params.parameters->length());

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
      // captured if type checks are enabled, because they may access the
      // receiver to instantiate types.
      CaptureReceiver();
    }
  }

  OpenBlock();  // Open a nested scope for the outermost function block.
  if (CurrentToken() == Token::kLBRACE) {
    ConsumeToken();
    ParseStatementSequence();
    ExpectToken(Token::kRBRACE);
  } else if (CurrentToken() == Token::kARROW) {
    ConsumeToken();
    const intptr_t expr_pos = token_index_;
    AstNode* expr = ParseExpr(kAllowConst);
    ASSERT(expr != NULL);
    current_block_->statements->Add(new ReturnNode(expr_pos, expr));
  } else if (IsLiteral("native")) {
    ParseNativeFunctionBlock(&params, func);
  } else {
    UnexpectedToken();
  }
  SequenceNode* body = CloseBlock();
  current_block_->statements->Add(body);
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
  qual_ident->ident_pos = token_index_;
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
        const Class& scope_class = Class::Handle(TypeParametersScopeClass());
        if (scope_class.IsNull() ||
            (scope_class.LookupTypeParameter(*(qual_ident->ident),
                                             token_index_) ==
             TypeParameter::null())) {
          ConsumeToken();  // Consume the kPERIOD token.
          qual_ident->lib_prefix = &lib_prefix;
          qual_ident->ident_pos = token_index_;
          qual_ident->ident =
              ExpectIdentifier("identifier expected after '.'");
        }
      }
    }
  }
}


void Parser::ParseMethodOrConstructor(ClassDesc* members, MemberDesc* method) {
  TRACE_PARSER("ParseMethodOrConstructor");
  ASSERT(CurrentToken() == Token::kLPAREN);
  intptr_t method_pos = this->token_index_;
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
  if (method->has_const && !(method->IsConstructor() || method->IsFactory())) {
    ErrorMsg(method->name_pos, "'const' not allowed for methods");
  }
  if (method->IsConstructor() && method->has_static) {
    ErrorMsg(method->name_pos, "constructor cannot be 'static'");
  }
  if (method->IsConstructor() && method->has_const) {
    Class& cls = Class::ZoneHandle(library_.LookupClass(members->class_name()));
    cls.set_is_const();
  }
  if (method->has_abstract && members->is_interface()) {
    ErrorMsg(method->name_pos,
             "'abstract' method only allowed in class definition");
  }

  if (members->FunctionNameExists(*method->name, method->kind)) {
    ErrorMsg(method->name_pos,
             "field or method '%s' already defined", method->name->ToCString());
  }

  // Parse the formal parameters.
  // The first parameter of factory methods is an implicit parameter called
  // 'this' of type AbstractTypeArguments.
  const bool has_this_param =
      !method->has_static || method->IsConstructor() || method->has_factory;
  const bool are_implicitly_final = method->has_const;
  const bool allow_explicit_default_values = true;
  const intptr_t formal_param_pos = token_index_;
  method->params.Clear();
  if (has_this_param) {
    method->params.AddReceiver(formal_param_pos);
  }
  // Constructors have an implicit parameter for the construction phase.
  if (method->IsConstructor()) {
    method->params.AddFinalParameter(
        token_index_,
        kPhaseParameterName,
        &Type::ZoneHandle(Type::DynamicType()));
  }
  if (are_implicitly_final) {
    method->params.SetImplicitlyFinal();
  }
  ParseFormalParameterList(allow_explicit_default_values, &method->params);
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

  // Parse initializers.
  if (CurrentToken() == Token::kCOLON) {
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
                         String::Handle(String::NewSymbol("."))));
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
               "abstract method '%s' may not have function body",
               method->name->ToCString());
    } else if (method->IsConstructor() && method->has_const) {
      ErrorMsg(method->name_pos,
               "const constructor '%s' may not have function body",
               method->name->ToCString());
    } else if (method->IsFactory() && method->has_const) {
      ErrorMsg(method->name_pos,
               "const factory '%s' may not have function body",
               method->name->ToCString());
    } else if (members->is_interface()) {
      ErrorMsg(method->name_pos,
               "function body not allowed in interface declaration");
    }
    if (CurrentToken() == Token::kLBRACE) {
      SkipBlock();
    } else {
      ConsumeToken();
      SkipExpr();
      ExpectSemicolon();
    }
    method_end_pos = token_index_;
  } else if (IsLiteral("native")) {
    if (method->has_abstract) {
      ErrorMsg(method->name_pos,
               "abstract method '%s' may not have function body",
               method->name->ToCString());
    } else if (members->is_interface()) {
      ErrorMsg(method->name_pos,
               "function body not allowed in interface declaration");
    } else if (method->IsConstructor() && method->has_const) {
      ErrorMsg(method->name_pos,
               "const constructor '%s' may not have function body",
               method->name->ToCString());
    }
    ParseNativeDeclaration();
  } else if (CurrentToken() == Token::kSEMICOLON) {
    if (members->is_interface() ||
        method->has_abstract ||
        (method->redirect_name != NULL) ||
        method->IsConstructor()) {
      ConsumeToken();
    } else {
      ErrorMsg(method->name_pos,
               "function body expected for method '%s'",
               method->name->ToCString());
    }
  } else {
    if (members->is_interface() ||
        method->has_abstract ||
        (method->redirect_name != NULL) ||
        (method->IsConstructor() && method->has_const)) {
      ExpectSemicolon();
    } else {
      ErrorMsg(method->name_pos,
               "function body expected for method '%s'",
               method->name->ToCString());
    }
  }

  RawFunction::Kind function_kind;
  if (method->IsFactoryOrConstructor()) {
    function_kind = RawFunction::kConstructor;
  } else if (method->has_abstract) {
    function_kind = RawFunction::kAbstract;
  } else if (method->IsGetter()) {
    function_kind = RawFunction::kGetterFunction;
  } else if (method->IsSetter()) {
    function_kind = RawFunction::kSetterFunction;
  } else {
    function_kind = RawFunction::kFunction;
  }
  Function& func = Function::Handle(
      Function::New(*method->name,
                    function_kind,
                    method->has_static,
                    method->has_const,
                    method_pos));
  func.set_result_type(*method->type);
  func.set_end_token_index(method_end_pos);

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

  if (field->has_const) {
    ErrorMsg("keyword 'const' not allowed in field declaration");
  }
  if (field->has_abstract) {
    ErrorMsg("keyword 'abstract' not allowed in field declaration");
  }
  if (field->has_factory) {
    ErrorMsg("keyword 'factory' not allowed in field declaration");
  }
  if (members->FieldNameExists(*field->name)) {
    ErrorMsg(field->name_pos,
             "'%s' field/method already defined\n", field->name->ToCString());
  }
  Function& getter = Function::Handle();
  Function& setter = Function::Handle();
  Field& class_field = Field::Handle();
  while (true) {
    bool has_initializer = CurrentToken() == Token::kASSIGN;
    if (has_initializer) {
      ConsumeToken();
      // For static final fields, the initialization expression
      // will be parsed through the kConstImplicitGetter method
      // invocation/compilation.
      // For instance fields, the expression is parsed when a constructor
      // is compiled.
      SkipExpr();
    } else {
      if (field->has_static && field->has_final) {
        ErrorMsg(field->name_pos,
                 "static final field '%s' must have an initializer expression",
                 field->name->ToCString());
      }
    }

    // Create the field object.
    class_field = Field::New(*field->name,
                             field->has_static,
                             field->has_final,
                             field->name_pos);
    class_field.set_type(*field->type);
    class_field.set_has_initializer(has_initializer);
    members->AddField(class_field);

    // For static final fields, set value to "uninitialized" and
    // create a kConstImplicitGetter getter method.
    if (field->has_static && has_initializer) {
      class_field.set_value(Instance::Handle(Object::sentinel()));
      String& getter_name = String::Handle(Field::GetterSymbol(*field->name));
      getter = Function::New(getter_name, RawFunction::kConstImplicitGetter,
                             field->has_static, field->has_final,
                             field->name_pos);
      getter.set_result_type(*field->type);
      members->AddFunction(getter);
    }

    // For instance fields, we create implicit getter and setter methods.
    if (!field->has_static) {
      String& getter_name = String::Handle(Field::GetterSymbol(*field->name));
      getter = Function::New(getter_name, RawFunction::kImplicitGetter,
                             field->has_static, field->has_final,
                             field->name_pos);
      ParamList params;
      params.AddReceiver(token_index_);
      getter.set_result_type(*field->type);
      AddFormalParamsToFunction(&params, getter);
      members->AddFunction(getter);
      if (!field->has_final) {
        // Build a setter accessor for non-const fields.
        String& setter_name = String::Handle(Field::SetterSymbol(*field->name));
        setter = Function::New(setter_name, RawFunction::kImplicitSetter,
                               field->has_static, field->has_final,
                               field->name_pos);
        ParamList params;
        params.AddReceiver(token_index_);
        params.AddFinalParameter(token_index_, "value", field->type);
        setter.set_result_type(Type::Handle(Type::VoidType()));
        AddFormalParamsToFunction(&params, setter);
        members->AddFunction(setter);
      }
    }

    if (CurrentToken() != Token::kCOMMA) {
      break;
    }
    ConsumeToken();
    field->name_pos = this->token_index_;
    field->name = ExpectIdentifier("field name expected");
  }
  ExpectSemicolon();
}


void Parser::CheckOperatorArity(
    const MemberDesc& member, Token::Kind operator_token) {
  intptr_t expected_num_parameters;  // Includes receiver.
  if (operator_token == Token::kASSIGN_INDEX) {
    expected_num_parameters = 3;
  } else if ((operator_token == Token::kNEGATE) ||
      (operator_token == Token::kBIT_NOT)) {
    expected_num_parameters = 1;
  } else {
    expected_num_parameters = 2;
  }
  if ((member.params.num_optional_parameters > 0) ||
      (member.params.has_named_optional_parameters) ||
      (member.params.num_fixed_parameters != expected_num_parameters)) {
    // Subtract receiver when reporting number of expected arguments.
    ErrorMsg(member.name_pos, "operator %s expects %d argument(s)",
        member.name->ToCString(), (expected_num_parameters - 1));
  }
}


void Parser::ParseClassMemberDefinition(ClassDesc* members) {
  TRACE_PARSER("ParseClassMemberDefinition");
  MemberDesc member;
  current_member_ = &member;
  if ((CurrentToken() == Token::kABSTRACT) &&
      (LookaheadToken(1) != Token::kLPAREN)) {
    ConsumeToken();
    member.has_abstract = true;
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
    // The member type is the 'Dynamic' type.
    member.type = &Type::ZoneHandle(Type::DynamicType());
  } else if (CurrentToken() == Token::kFACTORY) {
    ConsumeToken();
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
          (Token::IsIdentifier(follower))  ||  // Member name following a type.
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
  Token::Kind operator_token = Token::kILLEGAL;
  // Optionally parse a (possibly named) constructor name or factory.
  if (IsIdentifier() &&
      (CurrentLiteral()->Equals(members->class_name()) || member.has_factory)) {
    if (member.has_factory) {
      // The factory name may be qualified.
      QualIdent factory_name;
      ParseQualIdent(&factory_name);
      member.name_pos = factory_name.ident_pos;
      member.name = factory_name.ident;  // Unqualified identifier.
      // The class of the factory result type is specified by the factory name.
      LibraryPrefix& lib_prefix = LibraryPrefix::Handle();
      if (factory_name.lib_prefix != NULL) {
        lib_prefix = factory_name.lib_prefix->raw();
      }
      const Object& result_type_class = Object::Handle(
          UnresolvedClass::New(lib_prefix,
                               *factory_name.ident,
                               factory_name.ident_pos));
      // The type arguments of the result type are set during finalization.
      member.type = &Type::ZoneHandle(Type::New(result_type_class,
                                                TypeArguments::Handle(),
                                                factory_name.ident_pos));
    } else {
      member.name_pos = token_index_;
      member.name = CurrentLiteral();
      ConsumeToken();
    }
    // We must be dealing with a constructor or named constructor.
    member.kind = RawFunction::kConstructor;
    String& ctor_suffix = String::ZoneHandle(String::NewSymbol("."));
    if (CurrentToken() == Token::kPERIOD) {
      // Named constructor.
      ConsumeToken();
      const String* name = ExpectIdentifier("identifier expected");
      ctor_suffix = String::Concat(ctor_suffix, *name);
    }
    *member.name = String::Concat(*member.name, ctor_suffix);
    // Ensure that names are symbols.
    *member.name = String::NewSymbol(*member.name);
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
    member.name_pos = this->token_index_;
    member.name = ExpectIdentifier("identifier expected");
    if (CurrentToken() != Token::kLPAREN) {
      ErrorMsg("'(' expected");
    }
    // If the result type was not specified, it will be set to DynamicType.
  } else if ((CurrentToken() == Token::kSET) && !member.has_var &&
             (LookaheadToken(1) != Token::kLPAREN) &&
             (LookaheadToken(1) != Token::kASSIGN) &&
             (LookaheadToken(1) != Token::kCOMMA)  &&
             (LookaheadToken(1) != Token::kSEMICOLON))  {
    ConsumeToken();
    member.kind = RawFunction::kSetterFunction;
    member.name_pos = this->token_index_;
    member.name = ExpectIdentifier("identifier expected");
    if (CurrentToken() != Token::kLPAREN) {
      ErrorMsg("'(' expected");
    }
    // The grammar allows a return type, so member.type is not always NULL here.
    // If no return type is specified, the return type of the setter is Dynamic.
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
    operator_token = CurrentToken();
    member.kind = RawFunction::kFunction;
    member.name_pos = this->token_index_;
    member.name =
        &String::ZoneHandle(String::NewSymbol(Token::Str(operator_token)));
    ConsumeToken();
  } else if (IsIdentifier()) {
    member.name = CurrentLiteral();
    member.name_pos = token_index_;
    ConsumeToken();
  } else {
    ErrorMsg("identifier expected");
  }

  ASSERT(member.name != NULL);
  if (CurrentToken() == Token::kLPAREN) {
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
    ParseMethodOrConstructor(members, &member);
    if (operator_token != Token::kILLEGAL) {
      CheckOperatorArity(member, operator_token);
    }
  } else if (CurrentToken() ==  Token::kSEMICOLON ||
             CurrentToken() == Token::kCOMMA ||
             CurrentToken() == Token::kASSIGN) {
    // Field definition.
    if (member.type == NULL) {
      if (member.has_final) {
        member.type = &Type::ZoneHandle(Type::DynamicType());
      } else {
        ErrorMsg("missing 'var', 'final' or type in field declaration");
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
  const intptr_t class_pos = token_index_;
  ExpectToken(Token::kCLASS);
  const intptr_t classname_pos = token_index_;
  String& class_name = *ExpectTypeIdentifier("class name expected");
  if (FLAG_trace_parser) {
    OS::Print("TopLevel parsing class '%s'\n", class_name.ToCString());
  }
  Class& cls = Class::Handle();
  Object& obj = Object::Handle(library_.LookupObject(class_name));
  if (obj.IsNull()) {
    cls = Class::New(class_name, script_, classname_pos);
    library_.AddClass(cls);
  } else {
    if (!obj.IsClass()) {
      ErrorMsg(classname_pos, "'%s' is already defined",
               class_name.ToCString());
    }
    cls ^= obj.raw();
    if (cls.is_interface()) {
      ErrorMsg(classname_pos, "'%s' is already defined as interface",
               class_name.ToCString());
    } else if (cls.functions() != Array::Empty()) {
      ErrorMsg(classname_pos, "class '%s' is already defined",
               class_name.ToCString());
    }
  }
  ASSERT(!cls.IsNull());
  ASSERT(cls.functions() == Array::Empty());
  set_current_class(cls);
  ParseTypeParameters(cls);
  Type& super_type = Type::Handle();
  if (CurrentToken() == Token::kEXTENDS) {
    ConsumeToken();
    const intptr_t type_pos = token_index_;
    const AbstractType& type = AbstractType::Handle(
        ParseType(ClassFinalizer::kTryResolve));
    if (type.IsTypeParameter()) {
      ErrorMsg(type_pos,
               "class '%s' may not extend type parameter '%s'",
               class_name.ToCString(),
               String::Handle(type.Name()).ToCString());
    }
    super_type ^= type.raw();
    if (super_type.IsInterfaceType()) {
      ErrorMsg(type_pos,
               "class '%s' may implement, but cannot extend interface '%s'",
               class_name.ToCString(),
               String::Handle(super_type.Name()).ToCString());
    }
  } else {
    // No extends clause: Implicitly extend Object.
    super_type = Type::ObjectType();
  }
  ASSERT(!super_type.IsNull());
  cls.set_super_type(super_type);

  if (CurrentToken() == Token::kIMPLEMENTS) {
    Array& interfaces = Array::Handle();
    const intptr_t interfaces_pos = token_index_;
    interfaces = ParseInterfaceList();
    AddInterfaces(interfaces_pos, cls, interfaces);
  }

  ExpectToken(Token::kLBRACE);
  ClassDesc members(cls, class_name, false, class_pos);
  while (CurrentToken() != Token::kRBRACE) {
    ParseClassMemberDefinition(&members);
  }
  ExpectToken(Token::kRBRACE);

  CheckConstructors(&members);

  Array& array = Array::Handle();
  array = Array::MakeArray(members.fields());
  cls.SetFields(array);

  // Creating a new array for functions marks the class as parsed.
  array = Array::MakeArray(members.functions());
  cls.SetFunctions(array);

  pending_classes.Add(cls, Heap::kOld);
}


// 1. Add an implicit constructor if no explicit constructor is present.
// 2. Check for cycles in constructor redirection.
void Parser::CheckConstructors(ClassDesc* class_desc) {
  // Add an implicit constructor if no explicit constructor is present.
  if (!class_desc->has_constructor()) {
    // The implicit constructor is unnamed, has no explicit parameter,
    // and contains a supercall in the initializer list.
    String& ctor_name = String::ZoneHandle(
        String::Concat(class_desc->class_name(),
                       String::Handle(String::NewSymbol("."))));
    ctor_name = String::NewSymbol(ctor_name);
    // The token position for the implicit constructor is the 'class'
    // keyword of the constructor's class.
    Function& ctor = Function::Handle(
        Function::New(ctor_name,
                      RawFunction::kConstructor,
                      /* is_static = */ false,
                      /* is_const = */ false,
                      class_desc->token_pos()));
    ParamList params;
    // Add implicit 'this' parameter.
    params.AddReceiver(token_index_);
    // Add implicit parameter for construction phase.
    params.AddFinalParameter(
        token_index_,
        kPhaseParameterName,
        &Type::ZoneHandle(Type::DynamicType()));

    AddFormalParamsToFunction(&params, ctor);
    // The body of the constructor cannot modify the type arguments of the
    // constructed instance, which is passed in as a hidden parameter.
    // Therefore, there is no need to set the result type to be checked.
    const AbstractType& result_type = Type::ZoneHandle(Type::DynamicType());
    ctor.set_result_type(result_type);
    class_desc->AddFunction(ctor);
  }

  // Check for cycles in constructor redirection.
  const GrowableArray<MemberDesc>& members = class_desc->members();
  for (int i = 0; i < members.length(); i++) {
    MemberDesc* member = &members[i];
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
  const intptr_t saved_pos = token_index_;
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
      Class::New(String::Handle(String::NewSymbol(":alias_owner")),
                 Script::Handle(),
                 token_index_));
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

  const intptr_t alias_name_pos = token_index_;
  const String* alias_name =
      ExpectTypeIdentifier("function alias name expected");

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
  const bool no_explicit_default_values = false;
  ParseFormalParameterList(no_explicit_default_values, &func_params);
  // The field 'is_static' has no meaning for signature functions.
  Function& signature_function = Function::Handle(
      Function::New(*alias_name,
                    RawFunction::kSignatureFunction,
                    /* is_static = */ false,
                    /* is_const = */ false,
                    alias_name_pos));
  signature_function.set_owner(alias_owner);
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
  const Object& obj = Object::Handle(library_.LookupObject(*alias_name));
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
  const intptr_t interface_pos = token_index_;
  ExpectToken(Token::kINTERFACE);
  const intptr_t interfacename_pos = token_index_;
  String& interface_name = *ExpectTypeIdentifier("interface name expected");
  if (FLAG_trace_parser) {
    OS::Print("TopLevel parsing interface '%s'\n", interface_name.ToCString());
  }
  Class& interface = Class::Handle();
  Object& obj = Object::Handle(library_.LookupObject(interface_name));
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
    } else if (interface.functions() != Array::Empty()) {
      ErrorMsg(interfacename_pos,
               "interface '%s' is already defined",
               interface_name.ToCString());
    }
  }
  ASSERT(!interface.IsNull());
  ASSERT(interface.functions() == Array::Empty());
  set_current_class(interface);
  ParseTypeParameters(interface);

  if (CurrentToken() == Token::kEXTENDS) {
    Array& interfaces = Array::Handle();
    const intptr_t interfaces_pos = token_index_;
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
        Class::New(String::Handle(String::NewSymbol(":factory_signature")),
                   script_,
                   factory_name.ident_pos));
    factory_class.set_library(library_);
    factory_class.set_is_finalized();
    ParseTypeParameters(factory_class);
    unresolved_factory_class.set_factory_signature_class(factory_class);
    interface.set_factory_class(unresolved_factory_class);
    // If a type parameter list is included in the default factory clause (it
    // can be omitted), verify that it matches the list of type parameters of
    // the interface in number and names.
    if (factory_class.NumTypeParameters() > 0) {
      if (!AbstractTypeArguments::AreIdentical(
          AbstractTypeArguments::Handle(interface.type_parameters()),
          AbstractTypeArguments::Handle(factory_class.type_parameters()))) {
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
    const GrowableObjectArray& type_parameters_array =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    const GrowableObjectArray& bounds_array =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    intptr_t index = 0;
    TypeParameter& type_parameter = TypeParameter::Handle();
    TypeParameter& existing_type_parameter = TypeParameter::Handle();
    String& existing_type_parameter_name = String::Handle();
    AbstractType& bound = Type::Handle();
    do {
      ConsumeToken();
      if (CurrentToken() != Token::kIDENT) {
        ErrorMsg("type parameter name expected");
      }
      String& type_parameter_name = *CurrentLiteral();
      type_parameter = TypeParameter::New(cls,
                                          index,
                                          type_parameter_name,
                                          token_index_);
      // Check for duplicate type parameters.
      for (intptr_t i = 0; i < index; i++) {
        existing_type_parameter ^= type_parameters_array.At(i);
        existing_type_parameter_name = existing_type_parameter.Name();
        if (existing_type_parameter_name.Equals(type_parameter_name)) {
          ErrorMsg("duplicate type parameter '%s'",
                   type_parameter_name.ToCString());
        }
      }
      ConsumeToken();
      bound = Type::DynamicType();
      if (CurrentToken() == Token::kEXTENDS) {
        ConsumeToken();
        // A bound may refer to the owner of the type parameter it applies to,
        // i.e. to the class or interface currently being parsed.
        // Postpone resolution in order to avoid resolving the class and its
        // type parameters, as they are not fully parsed yet.
        bound = ParseType(ClassFinalizer::kDoNotResolve);
      }
      type_parameters_array.Add(type_parameter);
      bounds_array.Add(bound);
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
    const TypeArguments& bounds =
        TypeArguments::Handle(NewTypeArguments(bounds_array));
    cls.set_type_parameters(type_parameters);
    cls.set_type_parameter_bounds(bounds);
    // Try to resolve the upper bounds, which will at least resolve the
    // referenced type parameters.
    const intptr_t num_types = bounds.Length();
    for (intptr_t i = 0; i < num_types; i++) {
      bound = bounds.TypeAt(i);
      ResolveTypeFromClass(cls, ClassFinalizer::kTryResolve, &bound);
      bounds.SetTypeAt(i, bound);
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
      // Map a malformed type argument to Dynamic, so that malformed types with
      // a resolved type class are handled properly in production mode.
      if (type.IsMalformed()) {
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
    intptr_t supertype_pos = token_index_;
    interface = ParseType(ClassFinalizer::kTryResolve);
    interface_name = interface.Name();
    for (int i = 0; i < interfaces.Length(); i++) {
      other_interface ^= interfaces.At(i);
      other_name = other_interface.Name();
      if (interface_name.Equals(other_name)) {
        ErrorMsg(supertype_pos, "Duplicate supertype '%s'",
                 interface_name.ToCString());
      }
    }
    interfaces.Add(interface);
  } while (CurrentToken() == Token::kCOMMA);
  return Array::MakeArray(interfaces);
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
  AbstractType& conflicting = AbstractType::Handle();
  for (intptr_t i = 0; i < interfaces.Length(); i++) {
    AbstractType& interface = AbstractType::ZoneHandle();
    interface ^= interfaces.At(i);
    if (interface.IsTypeParameter()) {
      if (cls.is_interface()) {
        ErrorMsg(interfaces_pos,
                 "interface '%s' may not extend type parameter '%s'",
                 String::Handle(cls.Name()).ToCString(),
                 String::Handle(interface.Name()).ToCString());
      } else {
        ErrorMsg(interfaces_pos,
                 "class '%s' may not implement type parameter '%s'",
                 String::Handle(cls.Name()).ToCString(),
                 String::Handle(interface.Name()).ToCString());
      }
    }
    if (!ClassFinalizer::AddInterfaceIfUnique(all_interfaces,
                                              interface,
                                              &conflicting)) {
      ASSERT(!conflicting.IsNull());
      ErrorMsg(interfaces_pos,
               "interface '%s' conflicts with interface '%s'",
               String::Handle(interface.Name()).ToCString(),
               String::Handle(conflicting.Name()).ToCString());
    }
  }
  cls_interfaces = Array::MakeArray(all_interfaces);
  cls.set_interfaces(cls_interfaces);
}


void Parser::ParseTopLevelVariable(TopLevel* top_level) {
  TRACE_PARSER("ParseTopLevelVariable");
  const bool is_final = (CurrentToken() == Token::kFINAL);
  const bool is_static = true;
  const AbstractType& type = AbstractType::ZoneHandle(ParseFinalVarOrType(
      FLAG_enable_type_checks ? ClassFinalizer::kTryResolve :
                                ClassFinalizer::kIgnore));
  Field& field = Field::Handle();
  Function& getter = Function::Handle();
  while (true) {
    const intptr_t name_pos = token_index_;
    String& var_name = *ExpectIdentifier("variable name expected");

    if (library_.LookupObject(var_name) != Object::null()) {
      ErrorMsg(name_pos, "'%s' is already defined", var_name.ToCString());
    }
    String& accessor_name = String::Handle(Field::GetterName(var_name));
    if (library_.LookupObject(accessor_name) != Object::null()) {
      ErrorMsg(name_pos, "getter for '%s' is already defined",
               var_name.ToCString());
    }
    accessor_name = Field::SetterName(var_name);
    if (library_.LookupObject(accessor_name) != Object::null()) {
      ErrorMsg(name_pos, "setter for '%s' is already defined",
               var_name.ToCString());
    }

    field = Field::New(var_name, is_static, is_final, name_pos);
    field.set_type(type);
    field.set_value(Instance::Handle(Instance::null()));
    top_level->fields.Add(field);
    library_.AddObject(field, var_name);
    if (CurrentToken() == Token::kASSIGN) {
      ConsumeToken();
      SkipExpr();
      field.set_value(Instance::Handle(Object::sentinel()));
      // Create a static const getter.
      String& getter_name = String::ZoneHandle(Field::GetterSymbol(var_name));
      getter = Function::New(getter_name, RawFunction::kConstImplicitGetter,
                             is_static, is_final, name_pos);
      getter.set_result_type(type);
      top_level->functions.Add(getter);
    } else if (is_final) {
      ErrorMsg(name_pos, "missing initializer for final variable");
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
  const intptr_t name_pos = token_index_;
  const String& func_name = *ExpectIdentifier("function name expected");

  if (library_.LookupObject(func_name) != Object::null()) {
    ErrorMsg(name_pos, "'%s' is already defined", func_name.ToCString());
  }
  String& accessor_name = String::Handle(Field::GetterName(func_name));
  if (library_.LookupObject(accessor_name) != Object::null()) {
    ErrorMsg(name_pos, "'%s' is already defined as getter",
             func_name.ToCString());
  }
  accessor_name = Field::SetterName(func_name);
  if (library_.LookupObject(accessor_name) != Object::null()) {
    ErrorMsg(name_pos, "'%s' is already defined as setter",
             func_name.ToCString());
  }

  if (CurrentToken() != Token::kLPAREN) {
    ErrorMsg("'(' expected");
  }
  const intptr_t function_pos = token_index_;
  ParamList params;
  const bool allow_explicit_default_values = true;
  ParseFormalParameterList(allow_explicit_default_values, &params);

  intptr_t function_end_pos = function_pos;
  if (CurrentToken() == Token::kLBRACE) {
    SkipBlock();
    function_end_pos = token_index_;
  } else if (CurrentToken() == Token::kARROW) {
    ConsumeToken();
    SkipExpr();
    ExpectSemicolon();
    function_end_pos = token_index_;
  } else if (IsLiteral("native")) {
    ParseNativeDeclaration();
  } else {
    ErrorMsg("function block expected");
  }
  Function& func = Function::Handle(
      Function::New(func_name, RawFunction::kFunction,
                    is_static, false, function_pos));
  func.set_result_type(result_type);
  func.set_end_token_index(function_end_pos);
  AddFormalParamsToFunction(&params, func);
  top_level->functions.Add(func);
  library_.AddObject(func, func_name);
}


void Parser::ParseTopLevelAccessor(TopLevel* top_level) {
  TRACE_PARSER("ParseTopLevelAccessor");
  const bool is_static = true;
  AbstractType& result_type = AbstractType::Handle();
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
  const intptr_t name_pos = token_index_;
  const String* field_name = ExpectIdentifier("accessor name expected");

  if (CurrentToken() != Token::kLPAREN) {
    ErrorMsg("'(' expected");
  }
  const intptr_t accessor_pos = token_index_;
  ParamList params;
  const bool allow_explicit_default_values = true;
  ParseFormalParameterList(allow_explicit_default_values, &params);
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

  if (library_.LookupObject(*field_name) != Object::null()) {
    ErrorMsg(name_pos, "'%s' is already defined in this library",
             field_name->ToCString());
  }
  if (library_.LookupObject(accessor_name) != Object::null()) {
    ErrorMsg(name_pos, "%s for '%s' is already defined",
             is_getter ? "getter" : "setter",
             field_name->ToCString());
  }

  if (CurrentToken() == Token::kLBRACE) {
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
                    is_static, false, accessor_pos));
  func.set_result_type(result_type);
  AddFormalParamsToFunction(&params, func);
  top_level->functions.Add(func);
  library_.AddObject(func, accessor_name);
}


void Parser::ParseLibraryName() {
  TRACE_PARSER("ParseLibraryName");
  if ((script_.kind() == RawScript::kLibrary) &&
      (CurrentToken() != Token::kLIBRARY)) {
    // Handle error case early to get consistent error message.
    ExpectToken(Token::kLIBRARY);
  }
  if (CurrentToken() == Token::kLIBRARY) {
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


void Parser::ParseLibraryImport() {
  TRACE_PARSER("ParseLibraryImport");
  while (CurrentToken() == Token::kIMPORT) {
    const intptr_t import_pos = token_index_;
    ConsumeToken();
    ExpectToken(Token::kLPAREN);
    if (CurrentToken() != Token::kSTRING) {
      ErrorMsg("library url expected");
    }
    const String& url = *ParseImportStringLiteral();
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
    if (prefix.IsNull() || (prefix.Length() == 0)) {
      library_.AddImport(library);
    } else {
      LibraryPrefix& library_prefix = LibraryPrefix::Handle();
      library_prefix = library_.LookupLocalLibraryPrefix(prefix);
      if (!library_prefix.IsNull()) {
        library_prefix.AddLibrary(library);
      } else {
        library_prefix = LibraryPrefix::New(prefix, library);
        library_.AddObject(library_prefix, prefix);
      }
    }
  }
}


void Parser::ParseLibraryInclude() {
  TRACE_PARSER("ParseLibraryInclude");
  while (CurrentToken() == Token::kSOURCE) {
    const intptr_t source_pos = token_index_;
    ConsumeToken();
    ExpectToken(Token::kLPAREN);
    if (CurrentToken() != Token::kSTRING) {
      ErrorMsg("source url expected");
    }
    const String& url = *ParseImportStringLiteral();
    ExpectToken(Token::kRPAREN);
    ExpectToken(Token::kSEMICOLON);
    Dart_Handle handle = CallLibraryTagHandler(kCanonicalizeUrl,
                                               source_pos,
                                               url);
    const String& canon_url = String::CheckedHandle(Api::UnwrapHandle(handle));
    CallLibraryTagHandler(kSourceTag, source_pos, canon_url);
  }
}


void Parser::ParseLibraryResource() {
  TRACE_PARSER("ParseLibraryResource");
  while (CurrentToken() == Token::kRESOURCE) {
    // Currently the VM does ignore #resource library tags. They are only used
    // by the IDE.
    ConsumeToken();
    ExpectToken(Token::kLPAREN);
    if (CurrentToken() != Token::kSTRING) {
      ErrorMsg("resource url expected");
    }
    ConsumeToken();
    ExpectToken(Token::kRPAREN);
    ExpectToken(Token::kSEMICOLON);
  }
}


void Parser::ParseLibraryDefinition() {
  TRACE_PARSER("ParseLibraryDefinition");
  // Handle the script tag.
  if (CurrentToken() == Token::kSCRIPTTAG) {
    // Nothing to do for script tags except to skip them.
    ConsumeToken();
  }

  ParseLibraryName();
  ParseLibraryImport();
  ParseLibraryInclude();
  ParseLibraryResource();
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
      Class::New(String::ZoneHandle(String::NewSymbol("::")),
                 script_,
                 token_index_));
  toplevel_class.set_library(library_);

  if (is_library_source()) {
    ParseLibraryDefinition();
  }

  while (true) {
    set_current_class(Class::Handle());  // No current class.
    if (CurrentToken() == Token::kCLASS) {
      ParseClassDefinition(pending_classes);
    } else if ((CurrentToken() == Token::kTYPEDEF) &&
               (LookaheadToken(1) != Token::kLPAREN)) {
      ParseFunctionTypeAlias(pending_classes);
    } else if (CurrentToken() == Token::kINTERFACE) {
      ParseInterfaceDefinition(pending_classes);
    } else if ((CurrentToken() == Token::kABSTRACT) &&
        (LookaheadToken(1) == Token::kCLASS)) {
      ConsumeToken();  // Consume and ignore 'abstract'.
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
                           new SequenceNode(token_index_, outer_scope));
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
    // Record the end token index of the scope.
    current_block_->scope->set_end_token_index(token_index_);
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
  func.set_num_fixed_parameters(params->num_fixed_parameters);
  func.set_num_optional_parameters(params->num_optional_parameters);
  const int num_parameters = params->parameters->length();
  ASSERT(num_parameters == func.NumberOfParameters());
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
  TRACE_PARSER("ParseNativeFunctionBlock");
  const Class& cls = Class::Handle(func.owner());
  const int num_parameters = params->parameters->length();

  // Parse the function name out.
  const intptr_t native_pos = token_index_;
  const String& native_name = ParseNativeDeclaration();

  // Now resolve the native function to the corresponding native entrypoint.
  NativeFunction native_function = NativeEntry::ResolveNative(cls,
                                                              native_name,
                                                              num_parameters);
  if (native_function == NULL) {
    ErrorMsg(native_pos, "native function '%s' cannot be found",
        native_name.ToCString());
  }

  const bool has_opt_params = (params->num_optional_parameters > 0);

  // Now add the NativeBodyNode and return statement.
  current_block_->statements->Add(
      new ReturnNode(token_index_, new NativeBodyNode(token_index_,
                                                      native_name,
                                                      native_function,
                                                      num_parameters,
                                                      has_opt_params)));
}


LocalVariable* Parser::LookupReceiver(LocalScope* from_scope,
                                      bool test_only) {
  const String& this_name = String::Handle(String::NewSymbol(kThisName));
  return from_scope->LookupVariable(this_name, test_only);
}


LocalVariable* Parser::LookupPhaseParameter() {
  const String& phase_name =
      String::Handle(String::NewSymbol(kPhaseParameterName));
  const bool kTestOnly = false;
  return current_block_->scope->LookupVariable(phase_name, kTestOnly);
}


void Parser::CaptureReceiver() {
  ASSERT(current_block_->scope->function_level() > 0);
  const bool kTestOnly = false;
  // Side effect of lookup captures the receiver variable.
  LocalVariable* receiver = LookupReceiver(current_block_->scope, kTestOnly);
  ASSERT(receiver != NULL);
}


AstNode* Parser::LoadReceiver(intptr_t token_pos) {
  // A nested function may access 'this', referring to the receiver of the
  // outermost enclosing function.
  // We should not be loading the receiver from a static scope.
  ASSERT(!current_function().is_static() ||
         current_function().IsInFactoryScope());
  const bool kTestOnly = false;
  LocalVariable* receiver = LookupReceiver(current_block_->scope, kTestOnly);
  if (receiver == NULL) {
    ErrorMsg(token_pos, "illegal implicit access to receiver 'this'");
  }
  return new LoadLocalNode(token_index_, *receiver);
}


AstNode* Parser::CallGetter(intptr_t token_index,
                            AstNode* object,
                            const String& name) {
  return new InstanceGetterNode(token_index_, object, name);
}


// Returns ast nodes of the variable initialization.
AstNode* Parser::ParseVariableDeclaration(
    const AbstractType& type, bool is_final) {
  TRACE_PARSER("ParseVariableDeclaration");
  ASSERT(IsIdentifier());
  const intptr_t ident_pos = token_index_;
  LocalVariable* variable =
      new LocalVariable(ident_pos, *CurrentLiteral(), type);
  ASSERT(current_block_ != NULL);
  ASSERT(current_block_->scope != NULL);
  ConsumeToken();  // Variable identifier.
  AstNode* initialization = NULL;
  if (CurrentToken() == Token::kASSIGN) {
    // Variable initialization.
    const intptr_t assign_pos = token_index_;
    ConsumeToken();
    AstNode* expr = ParseExpr(kAllowConst);
    initialization = new StoreLocalNode(assign_pos, *variable, expr);
  } else if (is_final) {
    ErrorMsg(ident_pos, "missing initialization of 'final' variable");
  } else {
    // Initialize variable with null.
    AstNode* null_expr = new LiteralNode(ident_pos, Instance::ZoneHandle());
    initialization = new StoreLocalNode(ident_pos, *variable, null_expr);
  }
  // Add variable to cope after parsing the initalizer expression.
  // The expression must not be able to refer to the variable.
  if (!current_block_->scope->AddVariable(variable)) {
    ErrorMsg(ident_pos, "identifier '%s' already defined",
             variable->name().ToCString());
  }
  if (is_final) {
    variable->set_is_final();
  }
  return initialization;
}


// Parses ('var' | 'final' [type] | type).
// The presence of 'final' must be detected and remembered before the call.
// If a type is parsed, it may be resolved and finalized according to the given
// type finalization mode.
RawAbstractType* Parser::ParseFinalVarOrType(
    ClassFinalizer::FinalizationKind finalization) {
  TRACE_PARSER("ParseFinalVarOrType");
  if (CurrentToken() == Token::kVAR) {
    ConsumeToken();
    return Type::DynamicType();
  }
  bool type_is_optional = false;
  if (CurrentToken() == Token::kFINAL) {
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
  bool is_final = (CurrentToken() == Token::kFINAL);
  const AbstractType& type = AbstractType::ZoneHandle(ParseFinalVarOrType(
      FLAG_enable_type_checks ? ClassFinalizer::kFinalize :
                                ClassFinalizer::kIgnore));
  if (!IsIdentifier()) {
    ErrorMsg("identifier expected");
  }

  AstNode* initializers = ParseVariableDeclaration(type, is_final);
  ASSERT(initializers != NULL);
  while (CurrentToken() == Token::kCOMMA) {
    ConsumeToken();
    if (!IsIdentifier()) {
      ErrorMsg("identifier expected after comma");
    }
    // We have a second initializer. Allocate a sequence node now.
    // The sequence does not own the current scope. Set its own scope to NULL.
    SequenceNode* sequence = NodeAsSequenceNode(initializers->token_index(),
                                                initializers,
                                                NULL);
    sequence->Add(ParseVariableDeclaration(type, is_final));
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
  if (CurrentToken() == Token::kVOID) {
    ConsumeToken();
    result_type = Type::VoidType();
  } else if ((CurrentToken() == Token::kIDENT) &&
             (LookaheadToken(1) != Token::kLPAREN)) {
    result_type = ParseType(ClassFinalizer::kFinalize);
  }
  const intptr_t ident_pos = token_index_;
  if (IsIdentifier()) {
    variable_name = CurrentLiteral();
    function_name = variable_name;
    ConsumeToken();
  } else {
    if (!is_literal) {
      ErrorMsg("function name expected");
    }
    const String& anonymous_function_name =
        String::ZoneHandle(String::NewSymbol("function"));
    function_name = &anonymous_function_name;
  }
  ASSERT(ident_pos >= 0);

  if (CurrentToken() != Token::kLPAREN) {
    ErrorMsg("'(' expected");
  }
  intptr_t function_pos = token_index_;

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
  if (function.IsNull() || (function.token_index() != function_pos) ||
      (function.parent_function() != current_function().raw())) {
    is_new_closure = true;
    function = Function::NewClosureFunction(*function_name,
                                            current_function(),
                                            function_pos);
    function.set_result_type(result_type);
    current_class().AddClosureFunction(function);
  }

  // The function type does not need to be determined at compile time, unless
  // the closure is assigned to a function variable and type checks are enabled.
  // At run time, the function type is derived from the signature class of the
  // closure function and from the type arguments of the instantiator.

  LocalVariable* function_variable = NULL;
  Type& function_type = Type::ZoneHandle();
  if (variable_name != NULL) {
    // Since the function type depends on the signature of the closure function,
    // it cannot be determined before the formal parameter list of the closure
    // function is parsed. Therefore, we set the function type to a new
    // parameterized type to be patched after the actual type is known.
    // We temporarily use the class of the Function interface.
    const Class& unknown_signature_class = Class::Handle(
        Type::Handle(Type::FunctionInterface()).type_class());
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
  ASSERT(is_new_closure || (function.end_token_index() == token_index_));
  function.set_end_token_index(token_index_);

  // Now that the local function has formal parameters, lookup the signature
  // class in the current library (but not in its imports) and only create a new
  // canonical signature class if it does not exist yet.
  const String& signature = String::Handle(function.Signature());
  Class& signature_class = Class::ZoneHandle(
      library_.LookupLocalClass(signature));

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
    CaptureReceiver();
  }

  if (variable_name != NULL) {
    // Patch the function type now that the signature is known.
    // We need to create a new type for proper finalization, since the existing
    // type is already marked as finalized.
    Type& signature_type = Type::Handle(signature_class.SignatureType());
    const AbstractTypeArguments& signature_type_arguments =
        AbstractTypeArguments::Handle(signature_type.arguments());

    // Since the signature type is cached by the signature class, it may have
    // been finalized already.
    if (!signature_type.IsFinalized()) {
      signature_type ^= ClassFinalizer::FinalizeType(
          signature_class, signature_type, ClassFinalizer::kFinalize);
      // The call to ClassFinalizer::FinalizeType may have
      // extended the vector of type arguments.
      ASSERT(signature_type_arguments.IsNull() ||
             (signature_type_arguments.Length() ==
              signature_class.NumTypeArguments()));
      // The signature_class should not have changed.
      ASSERT(signature_type.type_class() == signature_class.raw());
    }

    // Now patch the function type of the variable.
    function_type.set_type_class(signature_class);
    function_type.set_arguments(signature_type_arguments);

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
        new StoreLocalNode(ident_pos, *function_variable, closure);
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
// a variable declaration. Returns true if we detect the token pattern:
// ('var' | 'final' | type ident (';' | '=' | ','))
// Token position remains unchanged.
bool Parser::IsVariableDeclaration() {
  if ((CurrentToken() == Token::kVAR) ||
      (CurrentToken() == Token::kFINAL)) {
    return true;
  }
  if (CurrentToken() != Token::kIDENT) {
    // Not a legal type identifier.
    return false;
  }
  const intptr_t saved_pos = token_index_;
  bool is_var_decl = false;
  if (TryParseOptionalType()) {
    if (IsIdentifier()) {
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
  const intptr_t saved_pos = token_index_;
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
        (is_top_level_ && IsLiteral("native"))) {
      SetPosition(saved_pos);
      return true;
    }
  }
  SetPosition(saved_pos);
  return false;
}


bool Parser::IsTopLevelAccessor() {
  if ((CurrentToken() == Token::kGET) || (CurrentToken() == Token::kSET)) {
    return true;
  }
  const intptr_t saved_pos = token_index_;
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
  if (!allow_function_literals_) {
    return false;
  }
  const intptr_t saved_pos = token_index_;
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


// Current token position is the token after the opening ( of the for
// statement. Returns true if we recognize a for ( .. in expr)
// statement.
bool Parser::IsForInStatement() {
  const intptr_t saved_pos = token_index_;
  bool result = false;
  if (CurrentToken() == Token::kVAR || CurrentToken() == Token::kFINAL) {
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


static bool ContainsAbruptCompletingStatement(SequenceNode *seq);

static bool IsAbruptCompleting(AstNode* statement) {
  return statement->IsReturnNode() ||
         statement->IsJumpNode()   ||
         statement->IsThrowNode()  ||
         (statement->IsSequenceNode() &&
             ContainsAbruptCompletingStatement(statement->AsSequenceNode()));
}


static bool ContainsAbruptCompletingStatement(SequenceNode *seq) {
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
    const intptr_t statement_pos = token_index_;
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
  const intptr_t if_pos = token_index_;
  SourceLabel* label = NULL;
  if (label_name != NULL) {
    label = SourceLabel::New(if_pos, label_name, SourceLabel::kStatement);
    OpenBlock();
    current_block_->scope->AddLabel(label);
  }
  ConsumeToken();
  ExpectToken(Token::kLPAREN);
  AstNode* cond_expr = ParseExpr(kAllowConst);
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
  const intptr_t case_pos = token_index_;
  // The case expressions node sequence does not own the enclosing scope.
  SequenceNode* case_expressions = new SequenceNode(case_pos, NULL);
  while (CurrentToken() == Token::kCASE || CurrentToken() == Token::kDEFAULT) {
    if (CurrentToken() == Token::kCASE) {
      if (default_seen) {
        ErrorMsg("default clause must be last case");
      }
      ConsumeToken();  // Keyword case.
      const intptr_t expr_pos = token_index_;
      AstNode* expr = ParseExpr(kAllowConst);
      AstNode* switch_expr_load = new LoadLocalNode(case_pos,
                                                    *switch_expr_value);
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
        ArgumentListNode* arguments = new ArgumentListNode(token_index_);
        arguments->Add(new LiteralNode(
            token_index_, Integer::ZoneHandle(Integer::New(token_index_))));
        current_block_->statements->Add(
            MakeStaticCall(kFallThroughErrorName, kThrowNewName, arguments));
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
  const intptr_t switch_pos = token_index_;
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
  const intptr_t expr_pos = token_index_;
  AstNode* switch_expr = ParseExpr(kAllowConst);
  if (paren_found) {
    ExpectToken(Token::kRPAREN);
  }
  ExpectToken(Token::kLBRACE);
  OpenBlock();
  current_block_->scope->AddLabel(label);

  // Store switch expression in temporary local variable.
  LocalVariable* temp_variable =
      new LocalVariable(expr_pos,
                        String::ZoneHandle(String::NewSymbol(":switch_expr")),
                        Type::ZoneHandle(Type::DynamicType()));
  current_block_->scope->AddVariable(temp_variable);
  AstNode* save_switch_expr =
      new StoreLocalNode(expr_pos, *temp_variable, switch_expr);
  current_block_->statements->Add(save_switch_expr);

  // Parse case clauses
  bool default_seen = false;
  while (true) {
    // Check for statement label
    SourceLabel* case_label = NULL;
    if (IsIdentifier() && LookaheadToken(1) == Token::kCOLON) {
      // Case statements start with a label.
      String* label_name = CurrentLiteral();
      const intptr_t label_pos = token_index_;
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
  const intptr_t while_pos = token_index_;
  SourceLabel* label =
      SourceLabel::New(while_pos, label_name, SourceLabel::kWhile);
  ConsumeToken();
  ExpectToken(Token::kLPAREN);
  AstNode* cond_expr = ParseExpr(kAllowConst);
  ExpectToken(Token::kRPAREN);
  const bool parsing_loop_body =  true;
  SequenceNode* while_body = ParseNestedStatement(parsing_loop_body, label);
  return new WhileNode(while_pos, label, cond_expr, while_body);
}


AstNode* Parser::ParseDoWhileStatement(String* label_name) {
  TRACE_PARSER("ParseDoWhileStatement");
  const intptr_t do_pos = token_index_;
  SourceLabel* label =
      SourceLabel::New(do_pos, label_name, SourceLabel::kDoWhile);
  ConsumeToken();
  const bool parsing_loop_body =  true;
  SequenceNode* dowhile_body = ParseNestedStatement(parsing_loop_body, label);
  ExpectToken(Token::kWHILE);
  ExpectToken(Token::kLPAREN);
  AstNode* cond_expr = ParseExpr(kAllowConst);
  ExpectToken(Token::kRPAREN);
  ExpectSemicolon();
  return new DoWhileNode(do_pos, label, cond_expr, dowhile_body);
}


AstNode* Parser::ParseForInStatement(intptr_t forin_pos,
                                     SourceLabel* label) {
  TRACE_PARSER("ParseForInStatement");
  bool is_final = (CurrentToken() == Token::kFINAL);
  const String* loop_var_name = NULL;
  LocalVariable* loop_var = NULL;
  intptr_t loop_var_pos = 0;
  if (LookaheadToken(1) == Token::kIN) {
    loop_var_pos = token_index_;
    loop_var_name = ExpectIdentifier("variable name expected");
  } else {
    // The case without a type is handled above, so require a type here.
    const AbstractType& type = AbstractType::ZoneHandle(ParseFinalVarOrType(
      FLAG_enable_type_checks ? ClassFinalizer::kFinalize :
                                ClassFinalizer::kIgnore));
    loop_var_pos = token_index_;
    loop_var_name = ExpectIdentifier("variable name expected");
    loop_var = new LocalVariable(loop_var_pos, *loop_var_name, type);
    if (is_final) {
      loop_var->set_is_final();
    }
  }
  ExpectToken(Token::kIN);
  const intptr_t collection_pos = token_index_;
  AstNode* collection_expr = ParseExpr(kAllowConst);
  ExpectToken(Token::kRPAREN);

  OpenBlock();  // Implicit block around while loop.

  // Generate implicit iterator variable and add to scope.
  const String& iterator_name =
      String::ZoneHandle(String::NewSymbol(":for-in-iter"));
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
      String::ZoneHandle(String::NewSymbol(kGetIteratorName));
  ArgumentListNode* no_args = new ArgumentListNode(collection_pos);
  AstNode* get_iterator = new InstanceCallNode(
      collection_pos, collection_expr, iterator_method_name, no_args);
  AstNode* iterator_init =
      new StoreLocalNode(collection_pos, *iterator_var, get_iterator);
  current_block_->statements->Add(iterator_init);

  // Generate while loop condition.
  AstNode* iterator_has_next = new InstanceCallNode(
      collection_pos,
      new LoadLocalNode(collection_pos, *iterator_var),
      String::ZoneHandle(String::NewSymbol("hasNext")),
      no_args);

  // Parse the for loop body. Ideally, we would use ParseNestedStatement()
  // here, but that does not work well because we have to insert an implicit
  // variable assignment and potentially a variable declaration in the
  // loop body.
  OpenLoopBlock();
  current_block_->scope->AddLabel(label);

  AstNode* iterator_next = new InstanceCallNode(
      collection_pos,
      new LoadLocalNode(collection_pos, *iterator_var),
      String::ZoneHandle(String::NewSymbol("next")),
      no_args);

  // Generate assignment of next iterator value to loop variable.
  AstNode* loop_var_assignment = NULL;
  if (loop_var != NULL) {
    // The for loop declares a new variable. Add it to the loop body scope.
    current_block_->scope->AddVariable(loop_var);
    loop_var_assignment =
        new StoreLocalNode(loop_var_pos, *loop_var, iterator_next);
  } else {
    AstNode* loop_var_primary = ResolveVarOrField(loop_var_pos, *loop_var_name);
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
  const intptr_t for_pos = token_index_;
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
  const intptr_t init_pos = token_index_;
  LocalScope* init_scope = current_block_->scope;
  if (CurrentToken() != Token::kSEMICOLON) {
    if (IsVariableDeclaration()) {
      initializer = ParseVariableDeclarationList();
    } else {
      initializer = ParseExpr(kAllowConst);
    }
  }
  ExpectSemicolon();
  AstNode* condition = NULL;
  if (CurrentToken() != Token::kSEMICOLON) {
    condition = ParseExpr(kAllowConst);
  }
  ExpectSemicolon();
  AstNode* increment = NULL;
  const intptr_t incr_pos = token_index_;
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


// Lookup class in the corelib implementation which contains various VM
// helper methods and classes.
static RawClass* LookupImplClass(const String& class_name) {
  return Library::Handle(Library::CoreImplLibrary()).LookupClass(class_name);
}


// Lookup class in the corelib which also contains various VM
// helper methods and classes. Allow look up of private classes.
static RawClass* LookupCoreClass(const String& class_name) {
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  String& name = String::Handle(class_name.raw());
  if (class_name.CharAt(0) == Scanner::kPrivateIdentifierStart) {
    // Private identifiers are mangled on a per script basis.
    name = String::Concat(name, String::Handle(core_lib.private_key()));
    name = String::NewSymbol(name);
  }
  return core_lib.LookupClass(name);
}


// Calling VM-internal helpers, uses implementation core library.
AstNode* Parser::MakeStaticCall(const char* class_name,
                                const char* function_name,
                                ArgumentListNode* arguments) {
  const String& cls_name =
      String::Handle(String::NewSymbol(class_name));
  const Class& cls = Class::Handle(LookupImplClass(cls_name));
  ASSERT(!cls.IsNull());
  const String& func_name =
      String::ZoneHandle(String::NewSymbol(function_name));
  const Function& func = Function::ZoneHandle(
      Resolver::ResolveStatic(cls,
                              func_name,
                              arguments->length(),
                              arguments->names(),
                              Resolver::kIsQualified));
  ASSERT(!func.IsNull());
  CheckFunctionIsCallable(arguments->token_index(), func);
  return new StaticCallNode(arguments->token_index(), func, arguments);
}


AstNode* Parser::MakeAssertCall(intptr_t begin, intptr_t end) {
  ArgumentListNode* arguments = new ArgumentListNode(begin);
  arguments->Add(new LiteralNode(begin,
      Integer::ZoneHandle(Integer::New(begin))));
  arguments->Add(new LiteralNode(end,
      Integer::ZoneHandle(Integer::New(end))));
  return MakeStaticCall(kAssertionErrorName, kThrowNewName, arguments);
}


AstNode* Parser::InsertClosureCallNodes(AstNode* condition) {
  if (condition->IsClosureNode() ||
      (condition->IsStoreLocalNode() &&
       condition->AsStoreLocalNode()->value()->IsClosureNode())) {
    EnsureExpressionTemp();
    // Function literal in assert implies a call.
    const intptr_t pos = condition->token_index();
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
  const intptr_t condition_pos = token_index_;
  if (!FLAG_enable_asserts && !FLAG_enable_type_checks) {
    SkipExpr();
    ExpectToken(Token::kRPAREN);
    return NULL;
  }
  AstNode* condition = ParseExpr(kAllowConst);
  const intptr_t condition_end = token_index_;
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
      : token_index(0), type(NULL), var(NULL), is_final(false) { }
  intptr_t token_index;
  const AbstractType* type;
  const String* var;
  bool is_final;
};


// Parse the parameter specified in the catch clause.
void Parser::ParseCatchParameter(CatchParamDesc* catch_param) {
  TRACE_PARSER("ParseCatchParameter");
  ASSERT(catch_param != NULL);
  catch_param->is_final = (CurrentToken() == Token::kFINAL);
  // The type of the catch parameter must always be resolved, even in unchecked
  // mode.
  catch_param->type = &AbstractType::ZoneHandle(
      ParseFinalVarOrType(ClassFinalizer::kFinalizeWellFormed));
  catch_param->token_index = token_index_;
  catch_param->var = ExpectIdentifier("identifier expected");
}


// Populate local scope of the catch block with the catch parameters.
void Parser::AddCatchParamsToScope(const CatchParamDesc& exception_param,
                                   const CatchParamDesc& stack_trace_param,
                                   LocalScope* scope) {
  ASSERT(exception_param.var != NULL);
  LocalVariable* var = new LocalVariable(exception_param.token_index,
                                         *exception_param.var,
                                         *exception_param.type);
  if (exception_param.is_final) {
    var->set_is_final();
  }
  bool added_to_scope = scope->AddVariable(var);
  ASSERT(added_to_scope);
  if (stack_trace_param.var != NULL) {
    var = new LocalVariable(token_index_,
                            *stack_trace_param.var,
                            *stack_trace_param.type);
    if (stack_trace_param.is_final) {
      var->set_is_final();
    }
    added_to_scope = scope->AddVariable(var);
    if (!added_to_scope) {
      ErrorMsg(stack_trace_param.token_index,
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
      String::ZoneHandle(String::NewSymbol(":saved_context_var"));
  LocalVariable* context_var =
      current_block_->scope->LocalLookupVariable(context_var_name);
  if (context_var == NULL) {
    context_var = new LocalVariable(token_index_,
                                    context_var_name,
                                    Type::ZoneHandle(Type::DynamicType()));
    current_block_->scope->AddVariable(context_var);
  }
  const String& catch_excp_var_name =
      String::ZoneHandle(String::NewSymbol(":exception_var"));
  LocalVariable* catch_excp_var =
      current_block_->scope->LocalLookupVariable(catch_excp_var_name);
  if (catch_excp_var == NULL) {
    catch_excp_var = new LocalVariable(token_index_,
                                       catch_excp_var_name,
                                       Type::ZoneHandle(Type::DynamicType()));
    current_block_->scope->AddVariable(catch_excp_var);
  }
  const String& catch_trace_var_name =
      String::ZoneHandle(String::NewSymbol(":stacktrace_var"));
  LocalVariable* catch_trace_var =
      current_block_->scope->LocalLookupVariable(catch_trace_var_name);
  if (catch_trace_var == NULL) {
    catch_trace_var = new LocalVariable(token_index_,
                                        catch_trace_var_name,
                                        Type::ZoneHandle(Type::DynamicType()));
    current_block_->scope->AddVariable(catch_trace_var);
  }

  const intptr_t try_pos = token_index_;
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
      SourceLabel::New(token_index_, NULL, SourceLabel::kCatch);

  // Now parse the 'catch' blocks if any and merge all of them into
  // an if-then sequence of the different types specified using the 'is'
  // operator.
  bool catch_seen = false;
  bool generic_catch_seen = false;
  SequenceNode* catch_handler_list = NULL;
  const intptr_t handler_pos = token_index_;
  OpenBlock();  // Start the catch block sequence.
  current_block_->scope->AddLabel(end_catch_label);
  while (CurrentToken() == Token::kCATCH) {
    catch_seen = true;
    const intptr_t catch_pos = token_index_;
    ConsumeToken();  // Consume the 'catch'.
    ExpectToken(Token::kLPAREN);
    CatchParamDesc exception_param;
    CatchParamDesc stack_trace_param;
    ParseCatchParameter(&exception_param);
    if (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
      ParseCatchParameter(&stack_trace_param);
    }
    ExpectToken(Token::kRPAREN);

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

    SequenceNode* catch_clause;

    // Parse the individual catch handler code and add an unconditional
    // JUMP to the end of the try block.
    ExpectToken(Token::kLBRACE);
    OpenBlock();

    // Generate code to load the exception object (:exception_var) into
    // the exception variable specified in this block.
    ASSERT(exception_param.var != NULL);
    LocalVariable* var = LookupLocalScope(*exception_param.var);
    ASSERT(var != NULL);
    ASSERT(catch_excp_var != NULL);
    current_block_->statements->Add(
        new StoreLocalNode(catch_pos,
                           *var,
                           new LoadLocalNode(catch_pos, *catch_excp_var)));
    if (stack_trace_param.var != NULL) {
      // A stack trace variable is specified in this block, so generate code
      // to load the stack trace object (:stacktrace_var) into the stack trace
      // variable specified in this block.
      LocalVariable* trace = LookupLocalScope(*stack_trace_param.var);
      ASSERT(catch_trace_var != NULL);
      current_block_->statements->Add(
          new StoreLocalNode(catch_pos,
                             *trace,
                             new LoadLocalNode(catch_pos, *catch_trace_var)));
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
        CaptureReceiver();
      }
      TypeNode* exception_type = new TypeNode(catch_pos, *exception_param.type);
      AstNode* exception_var = new LoadLocalNode(catch_pos, *catch_excp_var);
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
    catch_clause = CloseBlock();

    // Add this individual catch handler to the catch handlers list.
    current_block_->statements->Add(catch_clause);
  }
  catch_handler_list = CloseBlock();
  TryBlocks* inner_try_block = PopTryBlock();

  // Finally parse the 'finally' block.
  SequenceNode* finally_block = NULL;
  if (CurrentToken() == Token::kFINALLY) {
    current_function_.set_is_optimizable(false);
    ConsumeToken();  // Consume the 'finally'.
    const intptr_t finally_pos = token_index_;
    // Add the finally block to the exit points recorded so far.
    intptr_t node_index = 0;
    AstNode* node_to_inline =
        inner_try_block->GetNodeToInlineFinally(node_index);
    while (node_to_inline != NULL) {
      finally_block = ParseFinallyBlock();
      InlinedFinallyNode* node = new InlinedFinallyNode(finally_pos,
                                                        finally_block,
                                                        *context_var);
      AddFinallyBlockToNode(node_to_inline, node);
      node_index += 1;
      node_to_inline = inner_try_block->GetNodeToInlineFinally(node_index);
      token_index_ = finally_pos;
    }
    if (!generic_catch_seen) {
      // No generic catch handler exists so execute this finally block
      // before rethrowing the exception.
      finally_block = ParseFinallyBlock();
      catch_handler_list->Add(finally_block);
      token_index_ = finally_pos;
    }
    finally_block = ParseFinallyBlock();
  } else {
    if (!catch_seen) {
      ErrorMsg("'catch' or 'finally' expected");
    }
  }

  if (!generic_catch_seen) {
    // No generic catch handler exists so rethrow the exception so that
    // the next catch handler can deal with it.
    catch_handler_list->Add(
        new ThrowNode(handler_pos,
                      new LoadLocalNode(handler_pos, *catch_excp_var),
                      new LoadLocalNode(handler_pos, *catch_trace_var)));
  }
  CatchClauseNode* catch_block = new CatchClauseNode(handler_pos,
                                                     catch_handler_list,
                                                     *context_var,
                                                     *catch_excp_var,
                                                     *catch_trace_var);

  // Now create the try/catch ast node and return it. If there is a label
  // on the try/catch, close the block that's embedding the try statement
  // and attach the label to it.
  AstNode* try_catch_node =
      new TryCatchNode(try_pos, try_block, end_catch_label,
                       *context_var, catch_block, finally_block);

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
  const intptr_t jump_pos = token_index_;
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
            token_index_, target_name, SourceLabel::kForward);
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


bool Parser::IsDefinedInLexicalScope(const String& ident) {
  if (ResolveIdentInLocalScope(token_index_, ident, NULL)) {
    return true;
  }
  Object& obj = Object::Handle();
  obj = library_.LookupObject(ident);
  return !obj.IsNull();
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
      label_pos = token_index_;
      ASSERT(label_pos > 0);
      ConsumeToken();  // Consume identifier.
      ConsumeToken();  // Consume colon.
    }
  }
  const intptr_t statement_pos = token_index_;

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
    const intptr_t return_pos = token_index_;
    ConsumeToken();
    if (CurrentToken() != Token::kSEMICOLON) {
      if (current_function().IsConstructor() &&
          (current_block_->scope->function_level() == 0)) {
        ErrorMsg(return_pos, "return of a value not allowed in constructors");
      }
      AstNode* expr = ParseExpr(kAllowConst);
      statement = new ReturnNode(statement_pos, expr);
    } else {
      statement = new ReturnNode(statement_pos);
    }
    AddNodeForFinallyInlining(statement);
    ExpectSemicolon();
  } else if (CurrentToken() == Token::kIF) {
    statement = ParseIfStatement(label_name);
  } else if ((CurrentToken() == Token::kASSERT) &&
             !IsDefinedInLexicalScope(*CurrentLiteral())) {
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
  } else if (CurrentToken() == Token::kTHROW) {
    ConsumeToken();
    AstNode* expr = NULL;
    if (CurrentToken() != Token::kSEMICOLON) {
      expr = ParseExpr(kAllowConst);
      ExpectSemicolon();
      statement = new ThrowNode(statement_pos, expr, NULL);
    } else {  // No exception object seen so must be a rethrow.
      // Check if it is ok to do a rethrow.
      SourceLabel* label = current_block_->scope->LookupInnermostCatchLabel();
      if (label == NULL ||
          label->FunctionLevel() != current_block_->scope->function_level()) {
        ErrorMsg("rethrow of an exception is not valid here");
      }
      ASSERT(label->owner() != NULL);
      LocalScope* scope = label->owner()->parent();
      ASSERT(scope != NULL);
      LocalVariable* excp_var = scope->LocalLookupVariable(
          String::ZoneHandle(String::NewSymbol(":exception_var")));
      ASSERT(excp_var != NULL);
      LocalVariable* trace_var = scope->LocalLookupVariable(
          String::ZoneHandle(String::NewSymbol(":stacktrace_var")));
      ASSERT(trace_var != NULL);
      statement = new ThrowNode(statement_pos,
                                new LoadLocalNode(statement_pos, *excp_var),
                                new LoadLocalNode(statement_pos, *trace_var));
    }
  } else {
    statement = ParseExpr(kAllowConst);
    ExpectSemicolon();
  }
  return statement;
}


RawError* Parser::FormatErrorWithAppend(const Error& prev_error,
                                        const Script& script,
                                        intptr_t token_index,
                                        const char* message_header,
                                        const char* format,
                                        va_list args) {
  const intptr_t kMessageBufferSize = 512;
  char message_buffer[kMessageBufferSize];
  FormatMessage(script, token_index, message_header,
                message_buffer, kMessageBufferSize,
                format, args);
  const String& msg1 = String::Handle(String::New(prev_error.ToErrorCString()));
  const String& msg2 = String::Handle(String::New(message_buffer));
  return LanguageError::New(String::Handle(String::Concat(msg1, msg2)));
}


RawError* Parser::FormatError(const Script& script,
                              intptr_t token_index,
                              const char* message_header,
                              const char* format,
                              va_list args) {
  const intptr_t kMessageBufferSize = 512;
  char message_buffer[kMessageBufferSize];
  FormatMessage(script, token_index, message_header,
                message_buffer, kMessageBufferSize,
                format, args);
  const String& msg = String::Handle(String::New(message_buffer));
  return LanguageError::New(msg);
}


void Parser::FormatMessage(const Script& script,
                           intptr_t token_index,
                           const char* message_header,
                           char* message_buffer,
                           intptr_t message_buffer_size,
                           const char* format, va_list args) {
  intptr_t msg_len = 0;
  if (!script.IsNull()) {
    const String& script_url = String::CheckedHandle(script.url());
    if (token_index >= 0) {
      intptr_t line, column;
      script.GetTokenLocation(token_index, &line, &column);
      msg_len += OS::SNPrint(message_buffer + msg_len,
                             message_buffer_size - msg_len,
                             "'%s': %s: line %d pos %d: ",
                             script_url.ToCString(),
                             message_header,
                             line,
                             column);
      if (msg_len < message_buffer_size) {
        // Append the formatted error or warning message.
        msg_len += OS::VSNPrint(message_buffer + msg_len,
                                message_buffer_size - msg_len,
                                format,
                                args);
        if (msg_len < message_buffer_size) {
          // Append the source line.
          const String& script_line = String::Handle(script.GetLine(line));
          ASSERT(!script_line.IsNull());
          msg_len += OS::SNPrint(message_buffer + msg_len,
                                 message_buffer_size - msg_len,
                                 "\n%s\n%*s\n",
                                 script_line.ToCString(),
                                 column,
                                 "^");
        }
      }
    } else {
      // Token position is unknown.
      msg_len += OS::SNPrint(message_buffer + msg_len,
                             message_buffer_size - msg_len,
                             "'%s': %s: ",
                             script_url.ToCString(),
                             message_header);
      if (msg_len < message_buffer_size) {
        // Append the formatted error or warning message.
        msg_len += OS::VSNPrint(message_buffer + msg_len,
                                message_buffer_size - msg_len,
                                format,
                                args);
      }
    }
  } else {
    // Script is unknown.
    // Append the formatted error or warning message.
    msg_len += OS::VSNPrint(message_buffer + msg_len,
                            message_buffer_size - msg_len,
                            format,
                            args);
  }
}


void Parser::ErrorMsg(intptr_t token_index, const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(
      FormatError(script_, token_index, "Error", format, args));
  va_end(args);
  Isolate::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}


void Parser::ErrorMsg(const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(
      FormatError(script_, token_index_, "Error", format, args));
  va_end(args);
  Isolate::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}


void Parser::ErrorMsg(const Error& error) {
  Isolate::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}


void Parser::AppendErrorMsg(
      const Error& prev_error, intptr_t token_index, const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(FormatErrorWithAppend(
      prev_error, script_, token_index, "Error", format, args));
  va_end(args);
  Isolate::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}


void Parser::Warning(intptr_t token_index, const char* format, ...) {
  if (FLAG_silent_warnings) return;
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(
      FormatError(script_, token_index, "Warning", format, args));
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
      FormatError(script_, token_index_, "Warning", format, args));
  va_end(args);
  if (FLAG_warning_as_error) {
    Isolate::Current()->long_jump_base()->Jump(1, error);
    UNREACHABLE();
  } else {
    OS::Print("%s", error.ToErrorCString());
  }
}


void Parser::Unimplemented(const char* msg) {
  ErrorMsg(token_index_, msg);
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


String* Parser::ExpectTypeIdentifier(const char* msg) {
  if (CurrentToken() != Token::kIDENT) {
    ErrorMsg(msg);
  }
  String* ident = CurrentLiteral();
  ConsumeToken();
  return ident;
}

// Check whether current token is an identifier or a built-in identifier.
String* Parser::ExpectIdentifier(const char* msg) {
  if (!IsIdentifier()) {
    ErrorMsg(msg);
  }
  String* ident = CurrentLiteral();
  ConsumeToken();
  return ident;
}


bool Parser::IsLiteral(const char* literal) {
  const uint8_t* characters = reinterpret_cast<const uint8_t*>(literal);
  intptr_t len = strlen(literal);
  return IsIdentifier() && CurrentLiteral()->Equals(characters, len);
}


bool Parser::IsIncrementOperator(Token::Kind token) {
  return token == Token::kINCR || token == Token::kDECR;
}


bool Parser::IsPrefixOperator(Token::Kind token) {
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
      String::NewSymbol("malformed"))));
  // Dst name argument.
  arguments->Add(new LiteralNode(type_pos, String::ZoneHandle(
    String::NewSymbol(""))));
  // Malformed type error.
  const Error& error = Error::Handle(type.malformed_error());
  arguments->Add(new LiteralNode(type_pos, String::ZoneHandle(
      String::NewSymbol(error.ToErrorCString()))));
  return MakeStaticCall(kTypeErrorName, kThrowNewName, arguments);
}


AstNode* Parser::ParseBinaryExpr(int min_preced) {
  TRACE_PARSER("ParseBinaryExpr");
  ASSERT(min_preced >= 4);
  AstNode* left_operand = ParseUnaryExpr();
  int current_preced = Token::Precedence(CurrentToken());
  while (current_preced >= min_preced) {
    while (Token::Precedence(CurrentToken()) == current_preced) {
      Token::Kind op_kind = CurrentToken();
      if (op_kind == Token::kTIGHTADD) {
        op_kind = Token::kADD;
      }
      const intptr_t op_pos = token_index_;
      ConsumeToken();
      AstNode* right_operand = NULL;
      if (op_kind != Token::kIS) {
        right_operand = ParseBinaryExpr(current_preced + 1);
      } else {
        // For 'is' we expect the right operand to be a type.
        if (CurrentToken() == Token::kNOT) {
          ConsumeToken();
          op_kind = Token::kISNOT;
        }
        const intptr_t type_pos = token_index_;
        const AbstractType& type =
            AbstractType::ZoneHandle(ParseType(ClassFinalizer::kFinalize));
        if (!type.IsInstantiated() &&
            (current_block_->scope->function_level() > 0)) {
          // Make sure that the instantiator is captured.
          CaptureReceiver();
        }
        right_operand = new TypeNode(type_pos, type);
        if (type.IsMalformed()) {
          // Note that a type error is thrown even if the tested value is null.
          return ThrowTypeError(type_pos, type);
        }
      }
      if (Token::IsRelationalOperator(op_kind)
          || Token::IsInstanceofOperator(op_kind)
          || Token::IsEqualityOperator(op_kind)) {
        if (Token::IsInstanceofOperator(op_kind)) {
          if (!right_operand->AsTypeNode()->type().IsInstantiated()) {
            EnsureExpressionTemp();
          }
        }
        left_operand = new ComparisonNode(
            op_pos, op_kind, left_operand, right_operand);
        break;  // Equality and relational operators cannot be chained.
      } else {
        StringConcatNode* str_concat = NULL;
        if (op_kind == Token::kADD) {
          if (left_operand->IsLiteralNode()) {
            LiteralNode* lit = left_operand->AsLiteralNode();
            if (lit->literal().IsString()) {
              if (FLAG_allow_string_plus) {
                str_concat = new StringConcatNode(lit->token_index());
                str_concat->AddExpr(lit);
              } else {
                ErrorMsg(op_pos, "operator + on strings no longer allowed");
              }
            }
          } else if (left_operand->IsStringConcatNode()) {
            str_concat = left_operand->AsStringConcatNode();
          }
        }
        if (str_concat != NULL) {
          str_concat->AddExpr(right_operand);
          left_operand = str_concat;
        } else {
          left_operand = OptimizeBinaryOpNode(
              op_pos, op_kind, left_operand, right_operand);
        }
      }
    }
    current_preced--;
  }
  return left_operand;
}


bool Parser::IsAssignableExpr(AstNode* expr) {
  return expr->IsPrimaryNode()
      || (expr->IsLoadLocalNode() && !expr->AsLoadLocalNode()->HasPseudo())
      || expr->IsLoadStaticFieldNode()
      || expr->IsStaticGetterNode()
      || expr->IsInstanceGetterNode()
      || expr->IsLoadIndexedNode();
}


AstNode* Parser::ParseExprList() {
  TRACE_PARSER("ParseExprList");
  AstNode* expressions = ParseExpr(kAllowConst);
  if (CurrentToken() == Token::kCOMMA) {
    // Collect comma-separated expressions in a non scope owning sequence node.
    SequenceNode* list = new SequenceNode(token_index_, NULL);
    list->Add(expressions);
    while (CurrentToken() == Token::kCOMMA) {
      ConsumeToken();
      AstNode* expr = ParseExpr(kAllowConst);
      list->Add(expr);
    }
    expressions = list;
  }
  return expressions;
}


const LocalVariable& Parser::GetIncrementTempLocal() {
  if (expression_temp_ == NULL) {
    expression_temp_ = ParsedFunction::CreateExpressionTempVar(
        current_function().token_index());
  }
  return *expression_temp_;
}


void Parser::EnsureExpressionTemp() {
  // Temporary used later by the flow_graph_builder.
  GetIncrementTempLocal();
}


LocalVariable* Parser::CreateTempConstVariable(intptr_t token_index,
                                               intptr_t token_id,
                                               const char* s) {
  char name[64];
  OS::SNPrint(name, 64, ":%s%d", s, token_id);
  LocalVariable* temp =
      new LocalVariable(token_index,
                        String::ZoneHandle(String::NewSymbol(name)),
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
      Double& dbl_obj = Double::ZoneHandle();
      dbl_obj ^= lhs_literal->literal().raw();
      double left_double = dbl_obj.value();
      dbl_obj ^= rhs_literal->literal().raw();
      double right_double = dbl_obj.value();
      if (binary_op == Token::kDIV) {
        dbl_obj = Double::NewCanonical((left_double / right_double));
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
    ErrorMsg(expr_pos, "expression must be a compile time constant");
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
    intptr_t node_id = node->id();
    intptr_t token_index = node->token_index();
    node = NULL;  // Do not use it.
    if (!IsSimpleLocalOrLiteralNode(left_node->array())) {
      LocalVariable* temp =
          CreateTempConstVariable(token_index, node_id, "lia");
      StoreLocalNode* save =
          new StoreLocalNode(token_index, *temp, left_node->array());
      left_node =
          new LoadIndexedNode(token_index, save, left_node->index_expr());
      right_node = new LoadIndexedNode(token_index,
                                       new LoadLocalNode(token_index, *temp),
                                       right_node->index_expr());
    }
    if (!IsSimpleLocalOrLiteralNode(left_node->index_expr())) {
      LocalVariable* temp =
          CreateTempConstVariable(token_index, node_id, "lix");
      StoreLocalNode* save =
          new StoreLocalNode(token_index, *temp, left_node->index_expr());
      left_node = new LoadIndexedNode(token_index,
                                      left_node->array(),
                                      save);
      right_node = new LoadIndexedNode(token_index,
                                       right_node->array(),
                                       new LoadLocalNode(token_index, *temp));
    }
    *expr = right_node;
    return left_node;
  }
  if (node->IsInstanceGetterNode()) {
    InstanceGetterNode* left_node = node->AsInstanceGetterNode();
    InstanceGetterNode* right_node = left_node;
    intptr_t node_id = node->id();
    intptr_t token_index = node->token_index();
    node = NULL;  // Do not use it.
    if (!IsSimpleLocalOrLiteralNode(left_node->receiver())) {
      LocalVariable* temp =
          CreateTempConstVariable(token_index, node_id, "igr");
      StoreLocalNode* save =
          new StoreLocalNode(token_index, *temp, left_node->receiver());
      left_node = new InstanceGetterNode(token_index,
                                         save,
                                         left_node->field_name());
      right_node = new InstanceGetterNode(token_index,
                                          new LoadLocalNode(token_index, *temp),
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
  if ((result != NULL) && result->IsStoreIndexedNode()) {
    EnsureExpressionTemp();
  }
  return result;
}


AstNode* Parser::ParseExpr(bool require_compiletime_const) {
  TRACE_PARSER("ParseExpr");
  const intptr_t expr_pos = token_index_;
  AstNode* expr = ParseConditionalExpr();
  if (!Token::IsAssignmentOperator(CurrentToken())) {
    if (require_compiletime_const) {
      expr = FoldConstExpr(expr_pos, expr);
    }
    return expr;
  }
  // Assignment expressions.
  Token::Kind assignment_op = CurrentToken();
  const intptr_t assignment_pos = token_index_;
  ConsumeToken();
  const intptr_t right_expr_pos = token_index_;
  if (require_compiletime_const && (assignment_op != Token::kASSIGN)) {
    ErrorMsg(right_expr_pos, "expression must be a compile time constant");
  }
  AstNode* right_expr = ParseExpr(require_compiletime_const);
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
  AstNode* expr = ParseExpr(kRequireConst);
  ASSERT(expr->IsLiteralNode());
  return expr->AsLiteralNode();
}


AstNode* Parser::ParseConditionalExpr() {
  TRACE_PARSER("ParseConditionalExpr");
  const intptr_t expr_pos = token_index_;
  AstNode* expr = ParseBinaryExpr(Token::Precedence(Token::kOR));
  if (CurrentToken() == Token::kCONDITIONAL) {
    EnsureExpressionTemp();
    ConsumeToken();
    AstNode* expr1 = ParseExpr(kAllowConst);
    ExpectToken(Token::kCOLON);
    AstNode* expr2 = ParseExpr(kAllowConst);
    expr = new ConditionalExprNode(expr_pos, expr, expr1, expr2);
  }
  return expr;
}


AstNode* Parser::ParseUnaryExpr() {
  TRACE_PARSER("ParseUnaryExpr");
  AstNode* expr = NULL;
  const intptr_t op_pos = token_index_;
  if (IsPrefixOperator(CurrentToken())) {
    Token::Kind unary_op = CurrentToken();
    ConsumeToken();
    expr = ParseUnaryExpr();
    if (unary_op == Token::kTIGHTADD) {
      // kTIGHADD is added only in front of a number literal.
      if (!expr->IsLiteralNode()) {
        ErrorMsg(op_pos, "unexpected operator '+'");
      }
      // Expression is the literal itself.
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
    arguments = new ArgumentListNode(token_index_);
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
      arguments->Add(ParseExpr(require_const));
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
  const intptr_t call_pos = token_index_;
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
                                       Class::ZoneHandle(cls.raw()),
                                       func_name);
        return new ClosureCallNode(call_pos, closure, arguments);
      }
    } else {
      EnsureExpressionTemp();
      closure = GenerateStaticFieldLookup(field, call_pos);
      return new ClosureCallNode(call_pos, closure, arguments);
    }
    // Could not resolve static method: throw an exception if the arguments
    // do not match or compile time error otherwise.
    const Function& test_func = Function::Handle(
        Resolver::ResolveStaticByName(cls, func_name, Resolver::kIsQualified));
    if (test_func.IsNull()) {
      ErrorMsg(ident_pos, "unresolved static method '%s'",
          func_name.ToCString());
    } else {
      ArgumentListNode* arguments = new ArgumentListNode(ident_pos);
      arguments->Add(new LiteralNode(
          token_index_, Integer::ZoneHandle(Integer::New(ident_pos))));
      return MakeStaticCall(kStaticResolutionExceptionName,
                            kThrowNewName,
                            arguments);
    }
  }
  CheckFunctionIsCallable(call_pos, func);
  return new StaticCallNode(call_pos, func, arguments);
}


AstNode* Parser::ParseInstanceCall(AstNode* receiver, const String& func_name) {
  TRACE_PARSER("ParseInstanceCall");
  const intptr_t call_pos = token_index_;
  if (CurrentToken() != Token::kLPAREN) {
    ErrorMsg(call_pos, "left parenthesis expected");
  }
  ArgumentListNode* arguments = ParseActualParameters(NULL, kAllowConst);
  return new InstanceCallNode(call_pos, receiver, func_name, arguments);
}


AstNode* Parser::ParseClosureCall(AstNode* closure) {
  TRACE_PARSER("ParseClosureCall");
  const intptr_t call_pos = token_index_;
  ASSERT(CurrentToken() == Token::kLPAREN);
  EnsureExpressionTemp();
  ArgumentListNode* arguments = ParseActualParameters(NULL, kAllowConst);
  return new ClosureCallNode(call_pos, closure, arguments);
}


AstNode* Parser::ParseInstanceFieldAccess(AstNode* receiver,
                                          const String& field_name) {
  TRACE_PARSER("ParseInstanceFieldAccess");
  AstNode* access = NULL;
  const intptr_t call_pos = token_index_;
  if (Token::IsAssignmentOperator(CurrentToken())) {
    Token::Kind assignment_op = CurrentToken();
    ConsumeToken();
    AstNode* value = ParseExpr(kAllowConst);
    AstNode* load_access =
        new InstanceGetterNode(call_pos, receiver, field_name);
    AstNode* left_load_access = load_access;
    if (assignment_op != Token::kASSIGN) {
      // Compound assignment: store inputs with side effects into temp. locals.
      left_load_access = PrepareCompoundAssignmentNodes(&load_access);
    }
    value = ExpandAssignableOp(call_pos, assignment_op, load_access, value);
    access = CreateAssignmentNode(left_load_access, value);
  } else {
    access = CallGetter(call_pos, receiver, field_name);
  }
  return access;
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
                                        intptr_t ident_pos) {
  TRACE_PARSER("ParseStaticFieldAccess");
  AstNode* access = NULL;
  const intptr_t call_pos = token_index_;
  const Field& field = Field::ZoneHandle(cls.LookupStaticField(field_name));
  Function& func = Function::ZoneHandle();
  if (Token::IsAssignmentOperator(CurrentToken())) {
    Token::Kind assignment_op = CurrentToken();
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
        // No field or explicit setter function, this is an error.
        ErrorMsg(ident_pos, "unknown static field '%s'",
                 field_name.ToCString());
        return access;
      }
    }
    ConsumeToken();
    AstNode* value = ParseExpr(kAllowConst);
    AstNode* load_access = NULL;
    if (field.IsNull()) {
      // No field found, we must have at least a setter function defined.
      ASSERT(!func.IsNull());
      // Explicit setter function for the field found, field does not exist.
      // Create a getter node first in case it is needed. If getter node
      // is used as part of, e.g., "+=", and the explicit getter does not
      // exist, and error will be reported by the code generator.
      load_access = new StaticGetterNode(call_pos,
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
        return access;
      }
      load_access = GenerateStaticFieldLookup(field, token_index_);
    }
    value = ExpandAssignableOp(call_pos, assignment_op, load_access, value);
    access = CreateAssignmentNode(load_access, value);
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
          // No field or explicit getter function, this is an error.
          ErrorMsg(ident_pos,
                   "unknown static field '%s'", field_name.ToCString());
          return access;
        }
        access = CreateImplicitClosureNode(func, call_pos, NULL);
      } else {
        ASSERT(func.kind() != RawFunction::kConstImplicitGetter);
        access = new StaticGetterNode(call_pos,
                                      Class::ZoneHandle(cls.raw()),
                                      field_name);
      }
    } else {
      return GenerateStaticFieldLookup(field, token_index_);
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
    // In a static method, an unresolved identifier is an error.
    // In an instance method, we convert this into a getter call
    // for a field (which may be defined in a subclass.)
    String& name = String::CheckedZoneHandle(primary->primary().raw());
    if (current_function().is_static() ||
        current_function().IsInFactoryScope()) {
      ErrorMsg(primary->token_index(),
               "identifier '%s' is not declared in this scope",
               name.ToCString());
    } else {
      AstNode* receiver = LoadReceiver(primary->token_index());
      return CallGetter(node->token_index(), receiver, name);
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
    closure = CreateImplicitClosureNode(func, primary->token_index(), NULL);
  } else {
    // Instance function access.
    if (current_function().is_static() ||
        current_function().IsInFactoryScope()) {
      ErrorMsg(primary->token_index(),
               "cannot access instance method '%s' from static method",
               funcname.ToCString());
    }
    AstNode* receiver = LoadReceiver(primary->token_index());
    closure = CallGetter(primary->token_index(), receiver, funcname);
  }
  return closure;
}


AstNode* Parser::ParsePostfixExpr() {
  TRACE_PARSER("ParsePostfixExpr");
  const intptr_t postfix_expr_pos = token_index_;
  AstNode* postfix_expr = ParsePrimary();
  while (true) {
    AstNode* selector = NULL;
    AstNode* left = postfix_expr;
    if (CurrentToken() == Token::kPERIOD) {
      ConsumeToken();
      if (left->IsPrimaryNode()) {
        if (left->AsPrimaryNode()->primary().IsFunction()) {
          left = LoadClosure(left->AsPrimaryNode());
        } else {
          left = LoadFieldIfUnresolved(left);
        }
      }
      const intptr_t ident_pos = token_index_;
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
          selector = ParseInstanceFieldAccess(left, *ident);
        } else {
          // Static field access.
          selector = ParseStaticFieldAccess(cls, *ident, ident_pos);
        }
      }
    } else if (CurrentToken() == Token::kLBRACK) {
      const intptr_t bracket_pos = token_index_;
      ConsumeToken();
      left = LoadFieldIfUnresolved(left);
      const bool saved_mode = SetAllowFunctionLiterals(true);
      AstNode* index = ParseExpr(kAllowConst);
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
      selector = new LoadIndexedNode(bracket_pos, array, index);
    } else if (CurrentToken() == Token::kLPAREN) {
      if (left->IsPrimaryNode()) {
        PrimaryNode* primary = left->AsPrimaryNode();
        const intptr_t primary_pos = primary->token_index();
        if (primary->primary().IsFunction()) {
          Function& func = Function::CheckedHandle(primary->primary().raw());
          String& func_name = String::ZoneHandle(func.name());
          if (func.is_static()) {
            // Parse static function call.
            Class& cls = Class::Handle(func.owner());
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
          String& name = String::CheckedZoneHandle(primary->primary().raw());
          if (current_function().is_static()) {
            ErrorMsg(primary->token_index(),
                     "identifier '%s' is not declared in this scope",
                     name.ToCString());
          } else {
            // Treat as call to unresolved (instance) method.
            AstNode* receiver = LoadReceiver(primary->token_index());
            selector = ParseInstanceCall(receiver, name);
          }
        } else if (primary->primary().IsClass()) {
          ErrorMsg(left->token_index(),
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
      // No (more) selector to parse.
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
          ErrorMsg(left->token_index(),
                   "illegal use of class name '%s'",
                   cls_name.ToCString());
        } else {
          UNREACHABLE();  // Internal parser error.
        }
      }
      postfix_expr = left;
      // Done parsing selectors.
      break;
    }
    ASSERT(selector != NULL);
    postfix_expr = selector;
  }
  if (IsIncrementOperator(CurrentToken())) {
    TRACE_PARSER("IncrementOperator");
    Token::Kind incr_op = CurrentToken();
    if (!IsAssignableExpr(postfix_expr)) {
      ErrorMsg("expression is not assignable");
    }
    ConsumeToken();
    // Not prefix.
    AstNode* left_expr = PrepareCompoundAssignmentNodes(&postfix_expr);
    const LocalVariable& temp = GetIncrementTempLocal();
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
                                            type->token_index()));
        if (!type_parameter.IsNull()) {
          // A type parameter cannot be parameterized, so report an error if
          // type arguments have previously been parsed.
          if (!AbstractTypeArguments::Handle(type->arguments()).IsNull()) {
            ErrorMsg(type_parameter.token_index(),
                     "type parameter '%s' cannot be parameterized",
                     String::Handle(type_parameter.Name()).ToCString());
          }
          *type = type_parameter.raw();
          return;
        }
      }
      // Global lookup in current library.
      resolved_type_class = library_.LookupClass(unresolved_class_name);
    } else {
      LibraryPrefix& lib_prefix =
          LibraryPrefix::Handle(unresolved_class.library_prefix());
      // Local lookup in library prefix scope.
      resolved_type_class = lib_prefix.LookupLocalClass(unresolved_class_name);
    }
    // At this point, we can only have a parameterized_type.
    Type& parameterized_type = Type::Handle();
    parameterized_type ^= type->raw();
    if (!resolved_type_class.IsNull()) {
      Object& type_class = Object::Handle(resolved_type_class.raw());
      // Replace unresolved class with resolved type class.
      parameterized_type.set_type_class(type_class);
    } else if (finalization >= ClassFinalizer::kFinalize) {
      // The type is malformed.
      ClassFinalizer::FinalizeMalformedType(
          Error::Handle(),  // No previous error.
          current_class(), parameterized_type, finalization,
          "type '%s' is not loaded",
          String::Handle(parameterized_type.Name()).ToCString());
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


// If type parameters are currently in scope, return their declaring class,
// otherwise return null.
RawClass* Parser::TypeParametersScopeClass() {
  // Type parameters cannot be referred to from a static function, except from
  // a constructor or from a factory.
  // A constructor is considered as non-static by the compiler.
  if (is_top_level_) {
    if ((current_member_ == NULL) ||
        (current_member_->has_factory || !current_member_->has_static)) {
      return current_class().raw();
    }
  } else {
    if (!current_function().IsNull()) {
      Function& outer_function = Function::Handle(current_function().raw());
      while (outer_function.IsLocalFunction()) {
        outer_function = outer_function.parent_function();
      }
      if (outer_function.IsFactory() || !outer_function.is_static()) {
        return current_class().raw();
      }
    }
  }
  return Class::null();
}


bool Parser::IsInstantiatorRequired() const {
  ASSERT(!current_function().IsNull());
  Function& outer_function = Function::Handle(current_function().raw());
  while (outer_function.IsLocalFunction()) {
    outer_function = outer_function.parent_function();
  }
  if (outer_function.IsFactory() || !outer_function.is_static()) {
    return current_class().NumTypeParameters() > 0;
  }
  return false;
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
      return new StaticGetterNode(token_index_,
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
        Error& error = Error::Handle();
        error ^= const_value.raw();
        if (const_value.IsUnhandledException()) {
          field.set_value(Instance::Handle());
          // It is a compile-time error if evaluation of a compile-time constant
          // would raise an exception.
          AppendErrorMsg(error, token_index_,
                         "error initializing final field '%s'",
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
      return new StaticGetterNode(token_index_,
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
  if (!constructor.IsFactory()) {
    instance = Instance::New(type_class);
    if (!type_arguments.IsNull()) {
      if (!type_arguments.IsInstantiated()) {
        ErrorMsg("type must be constant in const constructor");
      }
      instance.SetTypeArguments(
          AbstractTypeArguments::Handle(type_arguments.Canonicalize()));
    }
    arg_values.Add(&instance);
    arg_values.Add(&Smi::ZoneHandle(Smi::New(Function::kCtorPhaseAll)));
  } else {
    // Prepend type_arguments to list of arguments to factory.
    ASSERT(type_arguments.IsZoneHandle());
    arg_values.Add(&type_arguments);
  }
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
        Error& error = Error::Handle();
        error ^= result.raw();
        Isolate::Current()->long_jump_base()->Jump(1, error);
        UNREACHABLE();
        return Object::null();
      }
  } else {
    if (constructor.IsFactory()) {
      // The factory method returns the allocated object.
      instance ^= result.raw();
    }
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
      *node = new LoadLocalNode(ident_pos, *local);
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
        *node = new StaticGetterNode(ident_pos,
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


// Do a lookup for the identifier in the library scope of the specified
// library. If resolve_locally is true the lookup does not consider
// the libraries imported by it for the lookup.
AstNode* Parser::ResolveIdentInLibraryScope(const Library& lib,
                                            const QualIdent& qual_ident,
                                            bool resolve_locally) {
  TRACE_PARSER("ResolveIdentInLibraryScope");
  Object& obj = Object::Handle();
  if (resolve_locally) {
    obj = lib.LookupLocalObject(*qual_ident.ident);
  } else {
    obj = lib.LookupObject(*qual_ident.ident);
  }
  if (obj.IsClass()) {
    Class& cls = Class::Handle();
    cls ^= obj.raw();
    return new PrimaryNode(qual_ident.ident_pos, Class::ZoneHandle(cls.raw()));
  }
  if (obj.IsField()) {
    Field& field = Field::Handle();
    field ^= obj.raw();
    ASSERT(field.is_static());
    return GenerateStaticFieldLookup(field, qual_ident.ident_pos);
  }
  Function& func = Function::Handle();
  if (obj.IsFunction()) {
    func ^= obj.raw();
    ASSERT(func.is_static());
    return new PrimaryNode(qual_ident.ident_pos,
                           Function::ZoneHandle(func.raw()));
  } else {
    ASSERT(obj.IsNull() || obj.IsLibraryPrefix());
  }

  // Check if there is a global getter or setter for qual_ident.
  // We create a getter node even if a getter doesn't exist since
  // qual_ident could be followed by an assignment which will convert it
  // to a setter node. If there is no assignment we will get an error
  // when we try to invoke the getter.
  String& accessor_name = String::Handle(Field::GetterName(*qual_ident.ident));
  if (resolve_locally) {
    obj = lib.LookupLocalObject(accessor_name);
  } else {
    obj = lib.LookupObject(accessor_name);
  }
  if (obj.IsNull()) {
    accessor_name = Field::SetterName(*qual_ident.ident);
    if (resolve_locally) {
      obj = lib.LookupLocalObject(accessor_name);
    } else {
      obj = lib.LookupObject(accessor_name);
    }
  }
  if (!obj.IsNull()) {
    ASSERT(obj.IsFunction());
    func ^= obj.raw();
    ASSERT(func.is_static());
    ASSERT(AbstractType::Handle(func.result_type()).IsResolved());
    return new StaticGetterNode(qual_ident.ident_pos,
                                Class::ZoneHandle(func.owner()),
                                *qual_ident.ident);
  }
  if (qual_ident.lib_prefix != NULL) {
    return NULL;
  }
  // Lexically unresolved primary identifiers are referenced by their name.
  return new PrimaryNode(qual_ident.ident_pos, *qual_ident.ident);
}


// Do a lookup for the identifier in the library prefix scope of the specified
// library prefix. This would mean trying to resolve it locally in any of the
// libraries present in the library prefix.
AstNode* Parser::ResolveIdentInLibraryPrefixScope(const LibraryPrefix& prefix,
                                                  const QualIdent& qual_ident) {
  TRACE_PARSER("ResolveIdentInLibraryPrefixScope");
  Library& lib = Library::Handle();
  AstNode* result = NULL;
  for (intptr_t i = 0; ((i < prefix.num_libs()) && (result == NULL)); i++) {
    lib = prefix.GetLibrary(i);
    ASSERT(!lib.IsNull());
    result = ResolveIdentInLibraryScope(lib, qual_ident, kResolveLocally);
  }
  if (result == NULL) {
    // This is an unresolved prefixed primary identifier, need to report
    // an error.
    ErrorMsg(qual_ident.ident_pos, "identifier '%s.%s' cannot be resolved",
             String::Handle(qual_ident.lib_prefix->name()).ToCString(),
             qual_ident.ident->ToCString());
  }
  return result;
}


// Resolve identifier, issue an error message if the name refers to
// a method or a class/interface.
// If the name cannot be resolved, turn it into an instance field access
// if we're compiling an instance method, or issue an error message
// if we're compiling a static method.
AstNode* Parser::ResolveVarOrField(intptr_t ident_pos, const String& ident) {
  TRACE_PARSER("ResolveVarOrField");
  // First try to find the variable in the local scope (block scope or
  // class scope).
  AstNode* var_or_field = NULL;
  ResolveIdentInLocalScope(ident_pos, ident, &var_or_field);
  if (var_or_field == NULL) {
    // Check whether the identifier is a type parameter. Type parameters
    // can never be used in primary expressions.
    const Class& scope_class = Class::Handle(TypeParametersScopeClass());
    if (!scope_class.IsNull()) {
      TypeParameter& type_param = TypeParameter::Handle(
          scope_class.LookupTypeParameter(ident, ident_pos));
      if (!type_param.IsNull()) {
        String& type_param_name = String::Handle(type_param.Name());
        ErrorMsg(ident_pos, "illegal use of type parameter %s",
                 type_param_name.ToCString());
      }
    }
    // Not found in the local scope, and the name is not a type parameter.
    // Try finding the variable in the library scope (current library
    // and all libraries imported by it).
    QualIdent qual_ident;
    qual_ident.lib_prefix = NULL;
    qual_ident.ident_pos = ident_pos;
    qual_ident.ident = &(String::ZoneHandle(ident.raw()));
    var_or_field = ResolveIdentInLibraryScope(library_,
                                              qual_ident,
                                              kResolveIncludingImports);
  }
  if (var_or_field->IsPrimaryNode()) {
    PrimaryNode* primary = var_or_field->AsPrimaryNode();
    if (primary->primary().IsString()) {
      // We got an unresolved name. If we are compiling a static
      // method, this is an error. In an instance method, we convert
      // the unresolved name to an instance field access, since a
      // subclass might define a field with this name.
      if (current_function().is_static()) {
        ErrorMsg(ident_pos, "identifier '%s' is not declared in this scope",
                 ident.ToCString());
      } else {
        // Treat as call to unresolved instance field.
        var_or_field = CallGetter(ident_pos, LoadReceiver(ident_pos), ident);
      }
    } else if (primary->primary().IsFunction()) {
      ErrorMsg(ident_pos, "illegal reference to method '%s'",
               ident.ToCString());
    } else {
      ASSERT(primary->primary().IsClass());
      ErrorMsg(ident_pos, "illegal reference to class or interface '%s'",
               ident.ToCString());
    }
  }
  return var_or_field;
}


// Resolve variables used in an import string literal.
// If the variable name cannot be resolved issue an error message.
// Currently we only resolve against the global map which is passed in
// when the script is loaded.
RawString* Parser::ResolveImportVar(intptr_t ident_pos, const String& ident) {
  TRACE_PARSER("ResolveImportVar");
  const Array& import_map =
      Array::Handle(Isolate::Current()->object_store()->import_map());
  if (!import_map.IsNull()) {
    intptr_t length = import_map.Length();
    intptr_t index = 0;
    String& name = String::Handle();
    while (index < (length - 1)) {
      name ^= import_map.At(index);
      if (name.Equals(ident)) {
        name ^= import_map.At(index + 1);
        return name.raw();
      }
      index += 2;
    }
  }
  ErrorMsg(ident_pos, "import variable '%s' has not been defined",
           ident.ToCString());
  return String::null();
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
  // In production mode, malformed type arguments are mapped to Dynamic.
  // In checked mode, a type with malformed type arguments is malformed.
  if (FLAG_enable_type_checks && !malformed_error.IsNull()) {
    Type& parameterized_type = Type::Handle();
    parameterized_type ^= type.raw();
    parameterized_type.set_type_class(Class::Handle(Object::dynamic_class()));
    parameterized_type.set_arguments(AbstractTypeArguments::Handle());
    parameterized_type.set_malformed_error(malformed_error);
  }
  if (finalization >= ClassFinalizer::kTryResolve) {
    const Class& scope_class = Class::Handle(TypeParametersScopeClass());
    ResolveTypeFromClass(scope_class, finalization, &type);
    if (finalization >= ClassFinalizer::kFinalize) {
      type ^= ClassFinalizer::FinalizeType(current_class(), type, finalization);
    }
  }
  return type.raw();
}


void Parser::CheckConstructorCallTypeArguments(
    intptr_t pos, Function& constructor,
    const AbstractTypeArguments& type_arguments) {
  if (!type_arguments.IsNull()) {
    const Class& constructor_class = Class::Handle(constructor.owner());
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
  const intptr_t literal_pos = token_index_;
  bool is_empty_literal = CurrentToken() == Token::kINDEX;
  ConsumeToken();

  AbstractType& element_type = Type::ZoneHandle(Type::DynamicType());
  // If no type argument vector is provided, leave it as null, which is
  // equivalent to using Dynamic as the type argument for the element type.
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

  // Parse the list elements. Note: there may be an optional extra
  // comma after the last element.
  ArrayNode* list = new ArrayNode(token_index_, type_arguments);
  if (!is_empty_literal) {
    const bool saved_mode = SetAllowFunctionLiterals(true);
    const String& dst_name = String::ZoneHandle(
        String::NewSymbol("list literal element"));
    while (CurrentToken() != Token::kRBRACK) {
      const intptr_t element_pos = token_index_;
      AstNode* element = ParseExpr(is_const);
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
          ErrorMsg(elem->AsLiteralNode()->token_index(),
                   "list literal element at index %d must be "
                   "a constant of type '%s'",
                   i,
                   String::Handle(element_type.Name()).ToCString());
        }
      }
      const_list.SetAt(i, elem->AsLiteralNode()->literal());
    }
    const_list ^= const_list.Canonicalize();
    const_list.MakeImmutable();
    return new LiteralNode(literal_pos, const_list);
  } else {
    // Factory call at runtime.
    String& list_literal_factory_class_name = String::Handle(
        String::NewSymbol(kListLiteralFactoryClassName));
    const Class& list_literal_factory_class =
        Class::Handle(LookupCoreClass(list_literal_factory_class_name));
    ASSERT(!list_literal_factory_class.IsNull());
    const String& list_literal_factory_name =
        String::Handle(String::NewSymbol(kListLiteralFactoryName));
    const Function& list_literal_factory = Function::ZoneHandle(
        list_literal_factory_class.LookupFactory(list_literal_factory_name));
    ASSERT(!list_literal_factory.IsNull());
    if (!type_arguments.IsNull() &&
        !type_arguments.IsInstantiated() &&
        (current_block_->scope->function_level() > 0)) {
      // Make sure that the instantiator is captured.
      CaptureReceiver();
    }
    ArgumentListNode* factory_param = new ArgumentListNode(literal_pos);
    factory_param->Add(list);
    AbstractTypeArguments& canonical_type_arguments =
        AbstractTypeArguments::ZoneHandle(type_arguments.Canonicalize());
    return CreateConstructorCallNode(literal_pos,
                                     canonical_type_arguments,
                                     list_literal_factory,
                                     factory_param);
  }
}


ConstructorCallNode* Parser::CreateConstructorCallNode(
    intptr_t token_index,
    const AbstractTypeArguments& type_arguments,
    const Function& constructor,
    ArgumentListNode* arguments) {
  if (!type_arguments.IsNull() && !type_arguments.IsInstantiated()) {
    EnsureExpressionTemp();
  }
  LocalVariable* allocated =
      CreateTempConstVariable(token_index, token_index, "alloc");
  return new ConstructorCallNode(token_index,
                                 type_arguments,
                                 constructor,
                                 arguments,
                                 *allocated);
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
  const intptr_t literal_pos = token_index_;
  ConsumeToken();

  AbstractType& value_type = Type::ZoneHandle(Type::DynamicType());
  AbstractTypeArguments& map_type_arguments =
      AbstractTypeArguments::ZoneHandle(type_arguments.raw());
  // If no type argument vector is provided, leave it as null, which is
  // equivalent to using Dynamic as the type argument for the value type.
  if (!map_type_arguments.IsNull()) {
    ASSERT(map_type_arguments.Length() > 0);
    // Map literals take a single type argument.
    value_type = map_type_arguments.TypeAt(0);
    if (map_type_arguments.Length() > 1) {
      // We temporarily accept two type arguments, as long as the first one is
      // type String.
      if (map_type_arguments.Length() != 2) {
        ErrorMsg(type_pos,
                 "a map literal takes one type argument specifying "
                 "the value type");
      }
      if (!value_type.IsStringInterface()) {
        ErrorMsg(type_pos,
                 "the key type of a map literal is implicitly 'String'");
      }
      Warning(type_pos,
              "a map literal takes one type argument specifying "
              "the value type");
      value_type = map_type_arguments.TypeAt(1);
    } else {
      TypeArguments& type_array = TypeArguments::Handle(TypeArguments::New(2));
      type_array.SetTypeAt(0, Type::Handle(Type::StringInterface()));
      type_array.SetTypeAt(1, value_type);
      map_type_arguments = type_array.raw();
    }
    if (is_const && !value_type.IsInstantiated()) {
      ErrorMsg(type_pos,
               "the type argument of a constant map literal cannot include "
               "a type variable");
    }
  }
  ASSERT(map_type_arguments.IsNull() || (map_type_arguments.Length() == 2));
  map_type_arguments ^= map_type_arguments.Canonicalize();

  // Parse the map entries. Note: there may be an optional extra
  // comma after the last entry.
  // The kv_pair array is temporary and of element type Dynamic. It is passed
  // to the factory to initialize a properly typed map.
  ArrayNode* kv_pairs =
      new ArrayNode(token_index_, TypeArguments::ZoneHandle());
  const String& dst_name = String::ZoneHandle(
      String::NewSymbol("list literal element"));
  while (CurrentToken() != Token::kRBRACE) {
    AstNode* key = NULL;
    if (CurrentToken() == Token::kSTRING) {
      key = ParseStringLiteral();
    }
    if (key == NULL) {
      ErrorMsg("map entry key must be string literal");
    } else if (is_const && !key->IsLiteralNode()) {
      ErrorMsg("map entry key must be compile time constant string");
    }
    ExpectToken(Token::kCOLON);
    const bool saved_mode = SetAllowFunctionLiterals(true);
    const intptr_t value_pos = token_index_;
    AstNode* value = ParseExpr(is_const);
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
          ErrorMsg(arg->AsLiteralNode()->token_index(),
                   "map literal value at index %d must be "
                   "a constant of type '%s'",
                   i >> 1,
                   String::Handle(value_type.Name()).ToCString());
        }
      }
      key_value_array.SetAt(i, arg->AsLiteralNode()->literal());
    }
    key_value_array ^= key_value_array.Canonicalize();
    key_value_array.MakeImmutable();

    // Construct the map object.
    const String& immutable_map_class_name =
        String::Handle(String::NewSymbol(kImmutableMapName));
    const Class& immutable_map_class =
        Class::Handle(LookupImplClass(immutable_map_class_name));
    ASSERT(!immutable_map_class.IsNull());
    ArgumentListNode* constr_args = new ArgumentListNode(token_index_);
    constr_args->Add(new LiteralNode(literal_pos, key_value_array));
    const String& constr_name =
        String::Handle(String::NewSymbol(kImmutableMapConstructorName));
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
      Instance& const_instance = Instance::ZoneHandle();
      const_instance ^= constructor_result.raw();
      return new LiteralNode(literal_pos, const_instance);
    }
  } else {
    // Factory call at runtime.
    String& map_literal_factory_class_name = String::Handle(
        String::NewSymbol(kMapLiteralFactoryClassName));
    const Class& map_literal_factory_class =
        Class::Handle(LookupCoreClass(map_literal_factory_class_name));
    ASSERT(!map_literal_factory_class.IsNull());
    const String& map_literal_factory_name =
        String::Handle(String::NewSymbol(kMapLiteralFactoryName));
    const Function& map_literal_factory = Function::ZoneHandle(
        map_literal_factory_class.LookupFactory(map_literal_factory_name));
    ASSERT(!map_literal_factory.IsNull());
    if (!map_type_arguments.IsNull() &&
        !map_type_arguments.IsInstantiated() &&
        (current_block_->scope->function_level() > 0)) {
      // Make sure that the instantiator is captured.
      CaptureReceiver();
    }
    ArgumentListNode* factory_param = new ArgumentListNode(literal_pos);
    factory_param->Add(kv_pairs);
    return CreateConstructorCallNode(literal_pos,
                                     map_type_arguments,
                                     map_literal_factory,
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
  const intptr_t type_pos = token_index_;
  Error& malformed_error = Error::Handle();
  AbstractTypeArguments& type_arguments = AbstractTypeArguments::ZoneHandle(
      ParseTypeArguments(&malformed_error,
                         ClassFinalizer::kFinalizeWellFormed));
  // Map and List interfaces do not declare bounds on their type parameters, so
  // we should never see a malformed type error here.
  // Note that a bound error is the only possible malformed type error returned
  // when requesting kFinalizeWellFormed type finalization.
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
  const String& period = String::Handle(String::NewSymbol("."));
  String& constructor_name =
      String::Handle(String::Concat(type_class_name, period));
  if (named_constructor != NULL) {
    constructor_name = String::Concat(constructor_name, *named_constructor);
  }
  return constructor_name;
}


AstNode* Parser::ParseNewOperator() {
  TRACE_PARSER("ParseNewOperator");
  const intptr_t new_pos = token_index_;
  ASSERT((CurrentToken() == Token::kNEW) || (CurrentToken() == Token::kCONST));
  bool is_const = (CurrentToken() == Token::kCONST);
  ConsumeToken();
  if (!IsIdentifier()) {
    ErrorMsg("type name expected");
  }
  intptr_t type_pos = token_index_;
  const AbstractType& type = AbstractType::Handle(
      ParseType(ClassFinalizer::kFinalizeWellFormed));
  // Malformed bounds never result in a compile time error, therefore, the
  // parsed type may be malformed although we requested kFinalizeWellFormed.
  // In that case, we throw a dynamic type error instead of calling the
  // constructor.
  if (type.IsTypeParameter()) {
    ErrorMsg(type_pos,
             "type parameter '%s' cannot be instantiated",
             String::Handle(type.Name()).ToCString());
  }
  if (type.IsDynamicType()) {
    ErrorMsg(type_pos, "Dynamic cannot be instantiated");
  }
  Class& type_class = Class::Handle(type.type_class());
  String& type_class_name = String::Handle(type_class.Name());
  AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::ZoneHandle(type.arguments());

  // The constructor class and its name are those of the parsed type, unless the
  // parsed type is an interface and a default factory class is specified, in
  // which case constructor_class and constructor_class_name are modified below.
  Class& constructor_class = Class::ZoneHandle(type_class.raw());
  String& constructor_class_name = String::Handle(type_class_name.raw());

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
  intptr_t call_pos = token_index_;
  ArgumentListNode* arguments = ParseActualParameters(NULL, is_const);

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
      ErrorMsg(type_pos,
               "interface '%s' has no constructor named '%s'",
               type_class_name.ToCString(),
               external_constructor_name.ToCString());
    }
    if (!constructor.AreValidArguments(arguments_length, arguments->names())) {
      ErrorMsg(call_pos,
               "invalid arguments passed to constructor '%s' "
               "for interface '%s'",
               external_constructor_name.ToCString(),
               type_class_name.ToCString());
    }
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
    Error& malformed_error = Error::Handle();
    if (factory_class.IsSubtypeOf(TypeArguments::Handle(),
                                  type_class,
                                  TypeArguments::Handle(),
                                  &malformed_error)) {
      // Class finalization verifies that the factory class has identical type
      // parameters as the interface.
      constructor_class_name = factory_class.Name();
    }
    // Always change the result type of the constructor to the factory type.
    constructor_class = factory_class.raw();
    // The finalized type_arguments are still those of the interface type.
    ASSERT(!constructor_class.is_interface());
  }

  // Make sure that an appropriate constructor exists.
  const String& constructor_name =
      BuildConstructorName(constructor_class_name, named_constructor);
  Function& constructor = Function::ZoneHandle(
      constructor_class.LookupConstructor(constructor_name));
  if (constructor.IsNull()) {
    constructor = constructor_class.LookupFactory(constructor_name);
    // A factory does not have the implicit 'phase' parameter.
    arguments_length -= 1;
  }
  if (constructor.IsNull()) {
    const String& external_constructor_name =
        (named_constructor ? constructor_name : constructor_class_name);
    ErrorMsg(type_pos,
             "class '%s' has no constructor or factory named '%s'",
             String::Handle(constructor_class.Name()).ToCString(),
             external_constructor_name.ToCString());
  }
  if (!constructor.AreValidArguments(arguments_length, arguments->names())) {
    const String& external_constructor_name =
        (named_constructor ? constructor_name : constructor_class_name);
    ErrorMsg(call_pos,
             "invalid arguments passed to constructor '%s' for class '%s'",
             external_constructor_name.ToCString(),
             String::Handle(constructor_class.Name()).ToCString());
  }

  // Now that the constructor to be called is identified, finalize the type
  // argument vector to be passed.
  // The type argument vector of the parsed type was finalized in ParseType.
  // If the constructor class was changed from the interface class to the
  // factory class, we need to finalize the type argument vector again, because
  // it may be longer due to the factory class extending a class, or/and because
  // the bounds on the factory class may be tighter than on the interface.
  if (constructor_class.raw() != type_class.raw()) {
    const intptr_t num_type_parameters = constructor_class.NumTypeParameters();
    // TODO(regis): Temporary type args should be allocated in new gen heap.
    TypeArguments& temp_type_arguments = TypeArguments::Handle();
    if (!type_arguments.IsNull()) {
      // Copy the parsed type arguments starting at offset 0, because interfaces
      // have no super types.
      ASSERT(type_class.NumTypeArguments() == type_class.NumTypeParameters());
      const intptr_t num_type_arguments = type_arguments.Length();
      temp_type_arguments = TypeArguments::New(num_type_parameters);
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
    // TODO(regis): Temporary type should be allocated in new gen heap.
    Type& temp_type = Type::Handle(
        Type::New(constructor_class, temp_type_arguments, type.token_index()));
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

  type_arguments ^= type_arguments.Canonicalize();
  // Make the constructor call.
  AstNode* new_object = NULL;
  if (is_const) {
    if (!constructor.is_const()) {
      ErrorMsg("'const' requires const constructor: '%s'",
          String::Handle(constructor.name()).ToCString());
    }
    if (type.IsMalformed()) {
      // Compile the throw of a dynamic type error due to a bound error.
      return ThrowTypeError(type_pos, type);
    }
    const Object& constructor_result = Object::Handle(
        EvaluateConstConstructorCall(constructor_class,
                                     type_arguments,
                                     constructor,
                                     arguments));
    if (constructor_result.IsUnhandledException()) {
      new_object = GenerateRethrow(new_pos, constructor_result);
    } else {
      Instance& const_instance = Instance::ZoneHandle();
      const_instance ^= constructor_result.raw();
      new_object = new LiteralNode(new_pos, const_instance);
    }
  } else {
    CheckFunctionIsCallable(new_pos, constructor);
    CheckConstructorCallTypeArguments(new_pos, constructor, type_arguments);
    if (!type_arguments.IsNull() &&
        !type_arguments.IsInstantiated() &&
        (current_block_->scope->function_level() > 0)) {
      // Make sure that the instantiator is captured.
      CaptureReceiver();
    }
    if (type.IsMalformed()) {
      // Compile the throw of a dynamic type error due to a bound error.
      return ThrowTypeError(type_pos, type);
    }
    // If the type argument vector is not instantiated, we verify in checked
    // mode at runtime that it is within its declared bounds.
    new_object = CreateConstructorCallNode(
        new_pos, type_arguments, constructor, arguments);
  }
  return new_object;
}


String& Parser::Interpolate(ArrayNode* values) {
  const String& class_name =
      String::Handle(String::NewSymbol(kStringClassName));
  const Class& cls = Class::Handle(LookupImplClass(class_name));
  ASSERT(!cls.IsNull());
  const String& func_name = String::Handle(String::NewSymbol(kInterpolateName));
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
    // TODO(regis): Report
    ErrorMsg("Exception thrown in Parser::Interpolate");
  }
  concatenated = String::NewSymbol(concatenated);
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
  const intptr_t literal_start = token_index_;
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
  ArrayNode* values = new ArrayNode(token_index_, TypeArguments::ZoneHandle());
  while (CurrentToken() == Token::kSTRING) {
    values->AddElement(new LiteralNode(token_index_, *CurrentLiteral()));
    ConsumeToken();
    while ((CurrentToken() == Token::kINTERPOL_VAR) ||
        (CurrentToken() == Token::kINTERPOL_START)) {
      AstNode* expr = NULL;
      const intptr_t expr_pos = token_index_;
      if (CurrentToken() == Token::kINTERPOL_VAR) {
        expr = ResolveVarOrField(token_index_, *CurrentLiteral());
        ASSERT(!expr->IsPrimaryNode());
        ConsumeToken();
      } else {
        ASSERT(CurrentToken() == Token::kINTERPOL_START);
        ConsumeToken();
        expr = ParseExpr(kAllowConst);
        ExpectToken(Token::kINTERPOL_END);
      }
      // Check if this interpolated string is still considered a compile time
      // constant. If it is we need to evaluate if the current string part is
      // a constant or not.
      if (is_compiletime_const) {
        const Object* const_expr = expr->EvalConstExpr();
        if (const_expr != NULL) {
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
        new ArgumentListNode(values->token_index());
    interpolate_arg->Add(values);
    primary = MakeStaticCall(kStringClassName,
                             kInterpolateName,
                             interpolate_arg);
  }
  return primary;
}


// An import string literal consists of the concatenation of the next n tokens
// that satisfy the EBNF grammar:
// literal = kSTRING {{ interpol }+ kSTRING }
// interpol = kINTERPOL_VAR
// In other words, the scanner breaks down interpolated strings so that
// a string literal always begins and ends with a kSTRING token, and
// there are never two kSTRING tokens next to each other.
String* Parser::ParseImportStringLiteral() {
  TRACE_PARSER("ParseImportStringLiteral");
  if ((CurrentToken() == Token::kSTRING) &&
      (LookaheadToken(1) != Token::kINTERPOL_VAR) &&
      (LookaheadToken(1) != Token::kINTERPOL_START)) {
    // Common case: no interpolation.
    String* result = CurrentLiteral();
    ConsumeToken();
    return result;
  }
  // String interpolation needed.
  String& result = String::ZoneHandle(String::New(""));
  String& resolved_name = String::Handle();
  while (CurrentToken() == Token::kSTRING) {
    result = String::Concat(result, *CurrentLiteral());
    ConsumeToken();
    if ((CurrentToken() != Token::kINTERPOL_VAR) &&
        (CurrentToken() != Token::kINTERPOL_START)) {
      break;
    }
    while ((CurrentToken() == Token::kINTERPOL_VAR) ||
           (CurrentToken() == Token::kINTERPOL_START)) {
      if (CurrentToken() == Token::kINTERPOL_START) {
        ConsumeToken();
        if (IsIdentifier()) {
          resolved_name = ResolveImportVar(token_index_, *CurrentLiteral());
          result = String::Concat(result, resolved_name);
          ConsumeToken();
          if (CurrentToken() != Token::kINTERPOL_END) {
            ErrorMsg("'}' expected");
          }
          ConsumeToken();
        } else {
          ErrorMsg("identifier expected");
        }
      } else {
        ASSERT(CurrentToken() == Token::kINTERPOL_VAR);
        resolved_name = ResolveImportVar(token_index_, *CurrentLiteral());
        result = String::Concat(result, resolved_name);
        ConsumeToken();
      }
    }
    // A string literal always ends with a kSTRING token.
    ASSERT(CurrentToken() == Token::kSTRING);
  }
  return &result;
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
        const Class& scope_class = Class::Handle(TypeParametersScopeClass());
        if (!scope_class.IsNull()) {
          TypeParameter& type_param = TypeParameter::ZoneHandle(
              scope_class.LookupTypeParameter(*(qual_ident.ident),
                                              token_index_));
          if (!type_param.IsNull()) {
            String& type_param_name = String::Handle(type_param.Name());
            ErrorMsg(qual_ident.ident_pos,
                     "illegal use of type parameter %s",
                     type_param_name.ToCString());
          }
        }
        // This is a non-local unqualified identifier so resolve the
        // identifier locally in the main app library and all libraries
        // imported by it.
        primary = ResolveIdentInLibraryScope(library_,
                                             qual_ident,
                                             kResolveIncludingImports);
      }
    } else {
      // This is a qualified identifier with a library prefix so resolve
      // the identifier locally in that library (we do not include the
      // libraries imported by that library).
      primary = ResolveIdentInLibraryPrefixScope(*(qual_ident.lib_prefix),
                                                 qual_ident);
    }
    ASSERT(primary != NULL);
  } else if (CurrentToken() == Token::kTHIS) {
    const String& this_name = String::Handle(String::NewSymbol(kThisName));
    LocalVariable* local = LookupLocalScope(this_name);
    if (local == NULL) {
      ErrorMsg("receiver 'this' is not in scope");
    }
    primary = new LoadLocalNode(token_index_, *local);
    ConsumeToken();
  } else if (CurrentToken() == Token::kINTEGER) {
    const Integer& literal = Integer::ZoneHandle(CurrentIntegerLiteral());
    primary = new LiteralNode(token_index_, literal);
    ConsumeToken();
  } else if (CurrentToken() == Token::kTRUE) {
    primary = new LiteralNode(token_index_, Bool::ZoneHandle(Bool::True()));
    ConsumeToken();
  } else if (CurrentToken() == Token::kFALSE) {
    primary = new LiteralNode(token_index_, Bool::ZoneHandle(Bool::False()));
    ConsumeToken();
  } else if (CurrentToken() == Token::kNULL) {
    primary = new LiteralNode(token_index_, Instance::ZoneHandle());
    ConsumeToken();
  } else if (CurrentToken() == Token::kLPAREN) {
    ConsumeToken();
    const bool saved_mode = SetAllowFunctionLiterals(true);
    primary = ParseExpr(kAllowConst);
    SetAllowFunctionLiterals(saved_mode);
    ExpectToken(Token::kRPAREN);
  } else if (CurrentToken() == Token::kDOUBLE) {
    Double& double_value = Double::ZoneHandle(CurrentDoubleLiteral());
    if (double_value.IsNull()) {
      ErrorMsg("invalid double literal");
    }
    primary = new LiteralNode(token_index_, double_value);
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
    } else if (current_function().IsLocalFunction()) {
      ErrorMsg("cannot access superclass from local function");
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
        Token::CanBeOverloaded(CurrentToken())) {
      primary = ParseSuperOperator();
    } else {
      ErrorMsg("illegal super call");
    }
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
  } else {
    ASSERT(expr->EvalConstExpr() != NULL);
    ReturnNode* ret = new ReturnNode(expr->token_index(), expr);
    // Compile time constant expressions cannot reference anything from a
    // local scope.
    LocalScope* empty_scope = new LocalScope(NULL, 0, 0);
    SequenceNode* seq = new SequenceNode(expr->token_index(), empty_scope);
    seq->Add(ret);

    Object& result = Object::Handle(Compiler::ExecuteOnce(seq));
    if (result.IsError()) {
      // Propagate the compilation error.
      Error& error = Error::Handle();
      error ^= result.raw();
      Isolate::Current()->long_jump_base()->Jump(1, error);
      UNREACHABLE();
    }
    ASSERT(result.IsInstance());
    Instance& value = Instance::ZoneHandle();
    value ^= result.raw();
    if (value.IsNull()) {
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


void Parser::SkipPostfixExpr() {
  SkipPrimary();
  while (true) {
    if (CurrentToken() == Token::kPERIOD) {
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
  while (Token::Precedence(Token::kOR) <= Token::Precedence(CurrentToken()) &&
      Token::Precedence(CurrentToken()) <= Token::Precedence(Token::kMUL)) {
    ConsumeToken();
    SkipUnaryExpr();
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
  SkipConditionalExpr();
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
