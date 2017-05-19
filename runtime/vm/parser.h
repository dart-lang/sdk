// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PARSER_H_
#define RUNTIME_VM_PARSER_H_

#include "include/dart_api.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "lib/invocation_mirror.h"
#include "vm/allocation.h"
#include "vm/ast.h"
#include "vm/class_finalizer.h"
#include "vm/compiler_stats.h"
#include "vm/kernel.h"
#include "vm/hash_table.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/token.h"

namespace dart {

// Forward declarations.

namespace kernel {

class ScopeBuildingResult;

}  // kernel

class ArgumentsDescriptor;
class Isolate;
class LocalScope;
class LocalVariable;
struct RegExpCompileData;
class SourceLabel;
template <typename T>
class GrowableArray;
class Parser;

struct CatchParamDesc;
class ClassDesc;
struct MemberDesc;
struct ParamList;
struct QualIdent;
class TopLevel;
class RecursionChecker;

// We cache compile time constants during compilation.  This allows us
// to look them up when the same code gets compiled again.  During
// background compilation, we are not able to evaluate the constants
// so this cache is necessary to support background compilation.
//
// We cache the constants with the script itself. This is helpful during isolate
// reloading, as it allows us to reference the compile time constants associated
// with a particular version of a script. The map key is simply the
// TokenPosition where the constant is defined.
class ConstMapKeyEqualsTraits {
 public:
  static const char* Name() { return "ConstMapKeyEqualsTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    const Smi& key1 = Smi::Cast(a);
    const Smi& key2 = Smi::Cast(b);
    return (key1.Value() == key2.Value());
  }
  static bool IsMatch(const TokenPosition& key1, const Object& b) {
    const Smi& key2 = Smi::Cast(b);
    return (key1.value() == key2.Value());
  }
  static uword Hash(const Object& obj) {
    const Smi& key = Smi::Cast(obj);
    return HashValue(key.Value());
  }
  static uword Hash(const TokenPosition& key) { return HashValue(key.value()); }
  // Used by CacheConstantValue if a new constant is added to the map.
  static RawObject* NewKey(const TokenPosition& key) {
    return Smi::New(key.value());
  }

 private:
  static uword HashValue(intptr_t pos) { return pos % (Smi::kMaxValue - 13); }
};
typedef UnorderedHashMap<ConstMapKeyEqualsTraits> ConstantsMap;

// The class ParsedFunction holds the result of parsing a function.
class ParsedFunction : public ZoneAllocated {
 public:
  ParsedFunction(Thread* thread, const Function& function)
      : thread_(thread),
        function_(function),
        code_(Code::Handle(zone(), function.unoptimized_code())),
        node_sequence_(NULL),
        regexp_compile_data_(NULL),
        instantiator_(NULL),
        function_type_arguments_(NULL),
        parent_type_arguments_(NULL),
        current_context_var_(NULL),
        expression_temp_var_(NULL),
        finally_return_temp_var_(NULL),
        deferred_prefixes_(new ZoneGrowableArray<const LibraryPrefix*>()),
        guarded_fields_(new ZoneGrowableArray<const Field*>()),
        default_parameter_values_(NULL),
        first_parameter_index_(0),
        first_stack_local_index_(0),
        num_copied_params_(0),
        num_stack_locals_(0),
        have_seen_await_expr_(false),
        kernel_scopes_(NULL) {
    ASSERT(function.IsZoneHandle());
    // Every function has a local variable for the current context.
    LocalVariable* temp = new (zone())
        LocalVariable(function.token_pos(), function.token_pos(),
                      Symbols::CurrentContextVar(), Object::dynamic_type());
    ASSERT(temp != NULL);
    current_context_var_ = temp;
  }

  const Function& function() const { return function_; }
  const Code& code() const { return code_; }

  SequenceNode* node_sequence() const { return node_sequence_; }
  void SetNodeSequence(SequenceNode* node_sequence);

  RegExpCompileData* regexp_compile_data() const {
    return regexp_compile_data_;
  }
  void SetRegExpCompileData(RegExpCompileData* regexp_compile_data);

  LocalVariable* instantiator() const { return instantiator_; }
  void set_instantiator(LocalVariable* instantiator) {
    ASSERT(instantiator != NULL);
    instantiator_ = instantiator;
  }
  LocalVariable* function_type_arguments() const {
    return function_type_arguments_;
  }
  void set_function_type_arguments(LocalVariable* function_type_arguments) {
    ASSERT(function_type_arguments != NULL);
    function_type_arguments_ = function_type_arguments;
  }
  LocalVariable* parent_type_arguments() const {
    return parent_type_arguments_;
  }
  void set_parent_type_arguments(LocalVariable* parent_type_arguments) {
    ASSERT(parent_type_arguments != NULL);
    parent_type_arguments_ = parent_type_arguments;
  }

  void set_default_parameter_values(ZoneGrowableArray<const Instance*>* list) {
    default_parameter_values_ = list;
#if defined(DEBUG)
    if (list == NULL) return;
    for (intptr_t i = 0; i < list->length(); i++) {
      ASSERT(list->At(i)->IsZoneHandle() || list->At(i)->InVMHeap());
    }
#endif
  }


  const Instance& DefaultParameterValueAt(intptr_t i) const {
    ASSERT(default_parameter_values_ != NULL);
    return *default_parameter_values_->At(i);
  }

  ZoneGrowableArray<const Instance*>* default_parameter_values() const {
    return default_parameter_values_;
  }

  LocalVariable* current_context_var() const { return current_context_var_; }

  LocalVariable* expression_temp_var() const {
    ASSERT(has_expression_temp_var());
    return expression_temp_var_;
  }
  void set_expression_temp_var(LocalVariable* value) {
    ASSERT(!has_expression_temp_var());
    expression_temp_var_ = value;
  }
  bool has_expression_temp_var() const { return expression_temp_var_ != NULL; }

  LocalVariable* finally_return_temp_var() const {
    ASSERT(has_finally_return_temp_var());
    return finally_return_temp_var_;
  }
  void set_finally_return_temp_var(LocalVariable* value) {
    ASSERT(!has_finally_return_temp_var());
    finally_return_temp_var_ = value;
  }
  bool has_finally_return_temp_var() const {
    return finally_return_temp_var_ != NULL;
  }
  void EnsureFinallyReturnTemp(bool is_async);

  LocalVariable* EnsureExpressionTemp();

  bool HasDeferredPrefixes() const { return deferred_prefixes_->length() != 0; }
  ZoneGrowableArray<const LibraryPrefix*>* deferred_prefixes() const {
    return deferred_prefixes_;
  }
  void AddDeferredPrefix(const LibraryPrefix& prefix);

  ZoneGrowableArray<const Field*>* guarded_fields() const {
    return guarded_fields_;
  }

  int first_parameter_index() const { return first_parameter_index_; }
  int first_stack_local_index() const { return first_stack_local_index_; }
  int num_copied_params() const { return num_copied_params_; }
  int num_stack_locals() const { return num_stack_locals_; }
  int num_non_copied_params() const {
    return (num_copied_params_ == 0) ? function().num_fixed_parameters() : 0;
  }

  void AllocateVariables();
  void AllocateIrregexpVariables(intptr_t num_stack_locals);

  void record_await() { have_seen_await_expr_ = true; }
  bool have_seen_await() const { return have_seen_await_expr_; }

  Thread* thread() const { return thread_; }
  Isolate* isolate() const { return thread_->isolate(); }
  Zone* zone() const { return thread_->zone(); }

  // Adds only relevant fields: field must be unique and its guarded_cid()
  // relevant.
  void AddToGuardedFields(const Field* field) const;

  void Bailout(const char* origin, const char* reason) const;

  kernel::ScopeBuildingResult* EnsureKernelScopes();

 private:
  Thread* thread_;
  const Function& function_;
  Code& code_;
  SequenceNode* node_sequence_;
  RegExpCompileData* regexp_compile_data_;
  LocalVariable* instantiator_;
  LocalVariable* function_type_arguments_;
  LocalVariable* parent_type_arguments_;
  LocalVariable* current_context_var_;
  LocalVariable* expression_temp_var_;
  LocalVariable* finally_return_temp_var_;
  ZoneGrowableArray<const LibraryPrefix*>* deferred_prefixes_;
  ZoneGrowableArray<const Field*>* guarded_fields_;
  ZoneGrowableArray<const Instance*>* default_parameter_values_;

  int first_parameter_index_;
  int first_stack_local_index_;
  int num_copied_params_;
  int num_stack_locals_;
  bool have_seen_await_expr_;

  kernel::ScopeBuildingResult* kernel_scopes_;

  friend class Parser;
  DISALLOW_COPY_AND_ASSIGN(ParsedFunction);
};


class Parser : public ValueObject {
 public:
  // Parse the top level of a whole script file and register declared classes
  // in the given library.
  static void ParseCompilationUnit(const Library& library,
                                   const Script& script);

  // Parse top level of a class and register all functions/fields.
  static void ParseClass(const Class& cls);

  static void ParseFunction(ParsedFunction* parsed_function);

  // Parse and evaluate the metadata expressions at token_pos in the
  // class namespace of class cls (which can be the implicit toplevel
  // class if the metadata is at the top-level).
  static RawObject* ParseMetadata(const Field& meta_data);

  // Build a function containing the initializer expression of the
  // given static field.
  static ParsedFunction* ParseStaticFieldInitializer(const Field& field);

  static void InsertCachedConstantValue(const Script& script,
                                        TokenPosition token_pos,
                                        const Instance& value);

  // Parse a function to retrieve parameter information that is not retained in
  // the dart::Function object. Returns either an error if the parse fails
  // (which could be the case for local functions), or a flat array of entries
  // for each parameter. Each parameter entry contains:
  // * a Dart bool indicating whether the parameter was declared final
  // * its default value (or null if none was declared)
  // * an array of metadata (or null if no metadata was declared).
  enum {
    kParameterIsFinalOffset,
    kParameterDefaultValueOffset,
    kParameterMetadataOffset,
    kParameterEntrySize,
  };
  static RawObject* ParseFunctionParameters(const Function& func);

 private:
  friend class EffectGraphVisitor;  // For BuildNoSuchMethodArguments.

  struct Block;
  class TryStack;
  class TokenPosScope;

  Parser(const Script& script, const Library& library, TokenPosition token_pos);
  Parser(const Script& script,
         ParsedFunction* function,
         TokenPosition token_pos);
  ~Parser();

  // The function for which we will generate code.
  const Function& current_function() const;

  // The innermost function being parsed.
  const Function& innermost_function() const;

  // Note that a local function may be parsed multiple times. It is first parsed
  // when its outermost enclosing function is being parsed. It is then parsed
  // again when an enclosing function calls this local function or calls
  // another local function enclosing it. Code for the local function will only
  // be generated the last time the local function is parsed, i.e. when it is
  // invoked. For example, a local function nested in another local function,
  // itself nested in a static function, is parsed 3 times (unless it does not
  // end up being invoked).
  // Now, current_function() always points to the outermost function being
  // compiled (i.e. the function that is being invoked), and is not updated
  // while parsing a nested function of that outermost function.
  // Therefore, the statements being parsed may or may not belong to the body
  // of the current_function(); they may belong to nested functions.
  // innermost_function() is the function that is currently being parsed.
  // It is either the same as current_function(), or a lexically nested
  // function.
  // The function level of the current parsing scope reflects the function
  // nesting. The function level is zero while parsing the body of the
  // current_function(), but is greater than zero while parsing the body of
  // local functions nested in current_function().

  // FunctionLevel is 0 when parsing code of current_function(), and denotes
  // the relative nesting level when parsing a nested function.
  int FunctionLevel() const;

  // The class being parsed.
  const Class& current_class() const;
  void set_current_class(const Class& value);

  // ParsedFunction accessor.
  ParsedFunction* parsed_function() const { return parsed_function_; }

  const Script& script() const { return script_; }
  void SetScript(const Script& script, TokenPosition token_pos);

  const Library& library() const { return library_; }
  void set_library(const Library& value) const { library_ = value.raw(); }

  // Parsing a library or a regular source script.
  bool is_library_source() const {
    return (script_.kind() == RawScript::kScriptTag) ||
           (script_.kind() == RawScript::kLibraryTag);
  }

  bool is_part_source() const {
    return script_.kind() == RawScript::kSourceTag;
  }

  // Parsing library patch script.
  bool is_patch_source() const {
    return script_.kind() == RawScript::kPatchTag;
  }

  TokenPosition TokenPos() const { return tokens_iterator_.CurrentPosition(); }
  TokenPosition PrevTokenPos() const { return prev_token_pos_; }

  Token::Kind CurrentToken() {
    if (token_kind_ == Token::kILLEGAL) {
      ComputeCurrentToken();
    }
    return token_kind_;
  }

  void ComputeCurrentToken();

  RawLibraryPrefix* ParsePrefix();

  Token::Kind LookaheadToken(int num_tokens);
  String* CurrentLiteral() const;
  RawDouble* CurrentDoubleLiteral() const;
  RawInteger* CurrentIntegerLiteral() const;

  // Sets parser to given token position in the stream.
  void SetPosition(TokenPosition position);

  void ConsumeToken() {
    // Reset cache and advance the token.
    prev_token_pos_ = tokens_iterator_.CurrentPosition();
    token_kind_ = Token::kILLEGAL;
    tokens_iterator_.Advance();
    INC_STAT(thread(), num_tokens_consumed, 1);
  }
  void ConsumeRightAngleBracket();
  void CheckToken(Token::Kind token_expected, const char* msg = NULL);
  void ExpectToken(Token::Kind token_expected);
  void ExpectSemicolon();
  void UnexpectedToken();
  String* ExpectUserDefinedTypeIdentifier(const char* msg);
  String* ExpectIdentifier(const char* msg);
  bool IsAwaitKeyword();
  bool IsYieldKeyword();

  void SkipIf(Token::Kind);
  void SkipToMatching();
  void SkipToMatchingParenthesis();
  void SkipBlock();
  TokenPosition SkipMetadata();
  bool IsPatchAnnotation(TokenPosition pos);
  void SkipTypeArguments();
  void SkipType(bool allow_void);
  void SkipTypeOrFunctionType(bool allow_void);
  void SkipInitializers();
  void SkipExpr();
  void SkipNestedExpr();
  void SkipConditionalExpr();
  void SkipBinaryExpr();
  void SkipUnaryExpr();
  void SkipPostfixExpr();
  void SkipSelectors();
  void SkipPrimary();
  void SkipCompoundLiteral();
  void SkipSymbolLiteral();
  void SkipNewOperator();
  void SkipActualParameters();
  void SkipMapLiteral();
  void SkipListLiteral();
  void SkipFunctionLiteral();
  void SkipStringLiteral();
  void SkipQualIdent();
  void SkipFunctionPreamble();

  AstNode* DartPrint(const char* str);

  void CheckConstructorCallTypeArguments(TokenPosition pos,
                                         const Function& constructor,
                                         const TypeArguments& type_arguments);

  // Report error if parsed code is too deeply nested; avoid stack overflow.
  void CheckStack();

  // Report already formatted error.
  static void ReportError(const Error& error);

  // Concatenate and report an already formatted error and a new error message.
  static void ReportErrors(const Error& prev_error,
                           const Script& script,
                           TokenPosition token_pos,
                           const char* format,
                           ...) PRINTF_ATTRIBUTE(4, 5);

  // Report error message at location of current token in current script.
  void ReportError(const char* msg, ...) const PRINTF_ATTRIBUTE(2, 3);

  void ReportErrorBefore(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

  // Report error message at given location in current script.
  void ReportError(TokenPosition token_pos, const char* msg, ...) const
      PRINTF_ATTRIBUTE(3, 4);

  // Report warning message at location of current token in current script.
  void ReportWarning(const char* msg, ...) const PRINTF_ATTRIBUTE(2, 3);

  // Report warning message at given location in current script.
  void ReportWarning(TokenPosition token_pos, const char* msg, ...) const
      PRINTF_ATTRIBUTE(3, 4);

  void CheckRecursiveInvocation();

  const Instance& EvaluateConstExpr(TokenPosition expr_pos, AstNode* expr);
  StaticGetterNode* RunStaticFieldInitializer(const Field& field,
                                              TokenPosition field_ref_pos);
  RawObject* EvaluateConstConstructorCall(const Class& type_class,
                                          const TypeArguments& type_arguments,
                                          const Function& constructor,
                                          ArgumentListNode* arguments);
  LiteralNode* FoldConstExpr(TokenPosition expr_pos, AstNode* expr);

  // Support for parsing of scripts.
  void ParseTopLevel();
  void ParseEnumDeclaration(const GrowableObjectArray& pending_classes,
                            const Object& tl_owner,
                            TokenPosition metadata_pos);
  void ParseEnumDefinition(const Class& cls);
  void ParseClassDeclaration(const GrowableObjectArray& pending_classes,
                             const Object& tl_owner,
                             TokenPosition metadata_pos);
  void ParseClassDefinition(const Class& cls);
  void ParseMixinAppAlias(const GrowableObjectArray& pending_classes,
                          const Object& tl_owner,
                          TokenPosition metadata_pos);
  void ParseTypedef(const GrowableObjectArray& pending_classes,
                    const Object& tl_owner,
                    TokenPosition metadata_pos);
  void ParseTopLevelVariable(TopLevel* top_level,
                             const Object& owner,
                             TokenPosition metadata_pos);
  void ParseTopLevelFunction(TopLevel* top_level,
                             const Object& owner,
                             TokenPosition metadata_pos);
  void ParseTopLevelAccessor(TopLevel* top_level,
                             const Object& owner,
                             TokenPosition metadata_pos);
  RawArray* EvaluateMetadata();

  RawFunction::AsyncModifier ParseFunctionModifier();

  // Support for parsing libraries.
  RawObject* CallLibraryTagHandler(Dart_LibraryTag tag,
                                   TokenPosition token_pos,
                                   const String& url);
  void ParseIdentList(GrowableObjectArray* names);
  void ParseLibraryDefinition(const Object& tl_owner);
  void ParseLibraryName();
  void ParseLibraryImportExport(const Object& tl_owner,
                                TokenPosition metadata_pos);
  void ParseLibraryPart();
  void ParsePartHeader();
  void ParseLibraryNameObsoleteSyntax();
  void ParseLibraryImportObsoleteSyntax();
  void ParseLibraryIncludeObsoleteSyntax();

  void ResolveSignature(const Function& signature);
  void ResolveType(AbstractType* type);
  RawAbstractType* CanonicalizeType(const AbstractType& type);
  RawAbstractType* ParseType(ClassFinalizer::FinalizationKind finalization,
                             bool allow_deferred_type = false,
                             bool consume_unresolved_prefix = true);
  RawAbstractType* ParseType(ClassFinalizer::FinalizationKind finalization,
                             bool allow_deferred_type,
                             bool consume_unresolved_prefix,
                             LibraryPrefix* prefix);
  RawType* ParseFunctionType(const AbstractType& result_type,
                             ClassFinalizer::FinalizationKind finalization);
  RawAbstractType* ParseTypeOrFunctionType(
      bool allow_void,
      ClassFinalizer::FinalizationKind finalization);
  void ParseTypeParameters(bool parameterizing_class);
  RawTypeArguments* ParseTypeArguments(
      ClassFinalizer::FinalizationKind finalization);
  void ParseMethodOrConstructor(ClassDesc* members, MemberDesc* method);
  void ParseFieldDefinition(ClassDesc* members, MemberDesc* field);
  void CheckMemberNameConflict(ClassDesc* members, MemberDesc* member);
  void ParseClassMemberDefinition(ClassDesc* members,
                                  TokenPosition metadata_pos);
  void ParseParameterType(ParamList* params);
  void ParseFormalParameter(bool allow_explicit_default_value,
                            bool evaluate_metadata,
                            ParamList* params);
  void ParseFormalParameters(bool use_function_type_syntax,
                             bool allow_explicit_default_values,
                             bool evaluate_metadata,
                             ParamList* params);
  void ParseFormalParameterList(bool use_function_type_syntax,
                                bool allow_explicit_default_values,
                                bool evaluate_metadata,
                                ParamList* params);
  void CheckFieldsInitialized(const Class& cls);
  void AddImplicitConstructor(const Class& cls);
  void CheckConstructors(ClassDesc* members);
  AstNode* ParseExternalInitializedField(const Field& field);
  void ParseInitializedInstanceFields(
      const Class& cls,
      LocalVariable* receiver,
      GrowableArray<Field*>* initialized_fields);
  AstNode* CheckDuplicateFieldInit(TokenPosition init_pos,
                                   GrowableArray<Field*>* initialized_fields,
                                   AstNode* instance,
                                   Field* field,
                                   AstNode* init_value);
  StaticCallNode* GenerateSuperConstructorCall(
      const Class& cls,
      TokenPosition supercall_pos,
      LocalVariable* receiver,
      ArgumentListNode* forwarding_args);
  StaticCallNode* ParseSuperInitializer(const Class& cls,
                                        LocalVariable* receiver);
  AstNode* ParseInitializer(const Class& cls,
                            LocalVariable* receiver,
                            GrowableArray<Field*>* initialized_fields);
  void ParseConstructorRedirection(const Class& cls, LocalVariable* receiver);
  void ParseInitializers(const Class& cls,
                         LocalVariable* receiver,
                         GrowableArray<Field*>* initialized_fields);
  String& ParseNativeDeclaration();
  void ParseInterfaceList(const Class& cls);
  RawAbstractType* ParseMixins(const AbstractType& super_type);
  static StaticCallNode* BuildInvocationMirrorAllocation(
      TokenPosition call_pos,
      const String& function_name,
      const ArgumentListNode& function_args,
      const LocalVariable* temp,
      bool is_super_invocation);
  // Build arguments for a NoSuchMethodCall. If LocalVariable temp is not NULL,
  // the last argument is stored in temp.
  static ArgumentListNode* BuildNoSuchMethodArguments(
      TokenPosition call_pos,
      const String& function_name,
      const ArgumentListNode& function_args,
      const LocalVariable* temp,
      bool is_super_invocation);
  RawFunction* GetSuperFunction(TokenPosition token_pos,
                                const String& name,
                                ArgumentListNode* arguments,
                                bool resolve_getter,
                                bool* is_no_such_method);
  AstNode* ParseSuperCall(const String& function_name,
                          const TypeArguments& func_type_args);
  AstNode* ParseSuperFieldAccess(const String& field_name,
                                 TokenPosition field_pos);
  AstNode* ParseSuperOperator();
  AstNode* BuildUnarySuperOperator(Token::Kind op, PrimaryNode* super);

  static bool ParseFormalParameters(const Function& func, ParamList* params);

  void SetupDefaultsForOptionalParams(const ParamList& params);
  ClosureNode* CreateImplicitClosureNode(const Function& func,
                                         TokenPosition token_pos,
                                         AstNode* receiver);
  void FinalizeFormalParameterTypes(const ParamList* params);
  void AddFormalParamsToFunction(const ParamList* params, const Function& func);
  void AddFormalParamsToScope(const ParamList* params, LocalScope* scope);

  SequenceNode* ParseConstructor(const Function& func);
  SequenceNode* ParseFunc(const Function& func, bool check_semicolon);

  void ParseNativeFunctionBlock(const ParamList* params, const Function& func);

  SequenceNode* ParseInstanceGetter(const Function& func);
  SequenceNode* ParseInstanceSetter(const Function& func);
  SequenceNode* ParseStaticFinalGetter(const Function& func);
  SequenceNode* ParseStaticInitializer();
  SequenceNode* ParseMethodExtractor(const Function& func);
  SequenceNode* ParseNoSuchMethodDispatcher(const Function& func);
  SequenceNode* ParseInvokeFieldDispatcher(const Function& func);
  SequenceNode* ParseImplicitClosure(const Function& func);
  SequenceNode* ParseConstructorClosure(const Function& func);

  void BuildDispatcherScope(const Function& func,
                            const ArgumentsDescriptor& desc);

  void EnsureHasReturnStatement(SequenceNode* seq, TokenPosition return_pos);
  void ChainNewBlock(LocalScope* outer_scope);
  void OpenBlock();
  void OpenLoopBlock();
  void OpenFunctionBlock(const Function& func);
  void OpenAsyncClosure();
  RawFunction* OpenAsyncFunction(TokenPosition formal_param_pos);
  RawFunction* OpenSyncGeneratorFunction(TokenPosition func_pos);
  SequenceNode* CloseSyncGenFunction(const Function& closure,
                                     SequenceNode* closure_node);
  void AddSyncGenClosureParameters(ParamList* params);
  void AddAsyncGenClosureParameters(ParamList* params);

  // Support for async* functions.
  RawFunction* OpenAsyncGeneratorFunction(TokenPosition func_pos);
  SequenceNode* CloseAsyncGeneratorFunction(const Function& closure,
                                            SequenceNode* closure_node);
  void OpenAsyncGeneratorClosure();
  SequenceNode* CloseAsyncGeneratorClosure(SequenceNode* body);

  void OpenAsyncTryBlock();
  SequenceNode* CloseBlock();
  SequenceNode* CloseAsyncFunction(const Function& closure,
                                   SequenceNode* closure_node);

  SequenceNode* CloseAsyncClosure(SequenceNode* body,
                                  TokenPosition func_end_pos);
  SequenceNode* CloseAsyncTryBlock(SequenceNode* try_block,
                                   TokenPosition func_end_pos);
  SequenceNode* CloseAsyncGeneratorTryBlock(SequenceNode* body);

  void AddAsyncClosureParameters(ParamList* params);
  void AddContinuationVariables();
  void AddAsyncClosureVariables();
  void AddAsyncGeneratorVariables();

  LocalVariable* LookupReceiver(LocalScope* from_scope, bool test_only);
  LocalVariable* LookupTypeArgumentsParameter(LocalScope* from_scope,
                                              bool test_only);
  void CaptureInstantiator();
  void CaptureFunctionTypeArguments();
  void CaptureAllInstantiators();
  AstNode* LoadReceiver(TokenPosition token_pos);
  AstNode* LoadFieldIfUnresolved(AstNode* node);
  AstNode* LoadClosure(PrimaryNode* primary);
  AstNode* LoadTypeParameter(PrimaryNode* primary);
  InstanceGetterNode* CallGetter(TokenPosition token_pos,
                                 AstNode* object,
                                 const String& name);

  AstNode* ParseAssertStatement(bool is_const = false);
  AstNode* ParseJump(String* label_name);
  AstNode* ParseIfStatement(String* label_name);
  AstNode* ParseWhileStatement(String* label_name);
  AstNode* ParseDoWhileStatement(String* label_name);
  AstNode* ParseForStatement(String* label_name);
  AstNode* ParseAwaitForStatement(String* label_name);
  AstNode* ParseForInStatement(TokenPosition forin_pos, SourceLabel* label);
  RawClass* CheckCaseExpressions(const GrowableArray<LiteralNode*>& values);
  CaseNode* ParseCaseClause(LocalVariable* switch_expr_value,
                            GrowableArray<LiteralNode*>* case_expr_values,
                            SourceLabel* case_label);
  AstNode* ParseSwitchStatement(String* label_name);

  // try/catch/finally parsing.
  void AddCatchParamsToScope(CatchParamDesc* exception_param,
                             CatchParamDesc* stack_trace_param,
                             LocalScope* scope);
  void SetupExceptionVariables(LocalScope* try_scope,
                               bool is_async,
                               LocalVariable** context_var,
                               LocalVariable** exception_var,
                               LocalVariable** stack_trace_var,
                               LocalVariable** saved_exception_var,
                               LocalVariable** saved_stack_trace_var);
  void SaveExceptionAndStackTrace(SequenceNode* statements,
                                  LocalVariable* exception_var,
                                  LocalVariable* stack_trace_var,
                                  LocalVariable* saved_exception_var,
                                  LocalVariable* saved_stack_trace_var);
  // Parse all the catch clause of a try.
  SequenceNode* ParseCatchClauses(TokenPosition handler_pos,
                                  bool is_async,
                                  LocalVariable* exception_var,
                                  LocalVariable* stack_trace_var,
                                  LocalVariable* rethrow_exception_var,
                                  LocalVariable* rethrow_stack_trace_var,
                                  const GrowableObjectArray& handler_types,
                                  bool* needs_stack_trace);
  // Parse or generate a finally clause.
  SequenceNode* EnsureFinallyClause(bool parse,
                                    bool is_async,
                                    LocalVariable* exception_var,
                                    LocalVariable* stack_trace_var,
                                    LocalVariable* rethrow_exception_var,
                                    LocalVariable* rethrow_stack_trace_var);
  // Push try block onto the stack of try blocks in scope.
  void PushTry(Block* try_block);
  // Pop the inner most try block from the stack.
  TryStack* PopTry();
  // Collect saved try context variables if await or yield is in try block.
  void CheckAsyncOpInTryBlock(LocalVariable** saved_try_ctx,
                              LocalVariable** async_saved_try_ctx,
                              LocalVariable** outer_saved_try_ctx,
                              LocalVariable** outer_async_saved_try_ctx) const;
  // Add specified node to try block list so that it can be patched with
  // inlined finally code if needed.
  void AddNodeForFinallyInlining(AstNode* node);
  void RemoveNodesForFinallyInlining(SourceLabel* label);
  // Add the inlined finally clause to the specified node.
  void AddFinallyClauseToNode(bool is_async,
                              AstNode* node,
                              InlinedFinallyNode* finally_clause);
  AstNode* ParseTryStatement(String* label_name);
  RawAbstractType* ParseConstFinalVarOrType(
      ClassFinalizer::FinalizationKind finalization);
  AstNode* ParseVariableDeclaration(const AbstractType& type,
                                    bool is_final,
                                    bool is_const,
                                    SequenceNode** await_preamble);
  AstNode* ParseVariableDeclarationList();
  AstNode* ParseFunctionStatement(bool is_literal);
  AstNode* ParseYieldStatement();
  AstNode* ParseStatement();
  SequenceNode* ParseNestedStatement(bool parsing_loop_body,
                                     SourceLabel* label);
  void ParseStatementSequence();
  bool IsIdentifier();
  bool IsSymbol(const String& symbol);
  bool IsSimpleLiteral(const AbstractType& type, Instance* value);
  bool IsFunctionTypeSymbol();
  bool IsFunctionTypeAliasName(bool* use_function_type_syntax);
  bool TryParseQualIdent();
  bool TryParseTypeParameters();
  bool TryParseTypeArguments();
  bool IsTypeParameters();
  bool IsArgumentPart();
  bool IsParameterPart();
  bool TryParseType(bool allow_void);
  bool IsVariableDeclaration();
  bool IsFunctionReturnType();
  bool IsFunctionDeclaration();
  bool IsFunctionLiteral();
  bool IsForInStatement();
  bool IsTopLevelAccessor();

  AstNode* ParseBinaryExpr(int min_preced);
  LiteralNode* ParseConstExpr();
  static const bool kRequireConst = true;
  static const bool kAllowConst = false;
  static const bool kConsumeCascades = true;
  static const bool kNoCascades = false;
  AstNode* ParseAwaitableExpr(bool require_compiletime_const,
                              bool consume_cascades,
                              SequenceNode** await_preamble);
  AstNode* ParseExpr(bool require_compiletime_const, bool consume_cascades);
  AstNode* ParseAwaitableExprList();
  AstNode* ParseConditionalExpr();
  AstNode* ParseUnaryExpr();
  AstNode* ParsePostfixExpr();
  AstNode* ParseSelectors(AstNode* primary, bool is_cascade);
  AstNode* ParseClosurization(AstNode* primary);
  AstNode* ParseCascades(AstNode* expr);
  AstNode* ParsePrimary();
  AstNode* ParseStringLiteral(bool allow_interpolation);
  String* ParseImportStringLiteral();
  AstNode* ParseCompoundLiteral();
  AstNode* ParseSymbolLiteral();
  AstNode* ParseListLiteral(TokenPosition type_pos,
                            bool is_const,
                            const TypeArguments& type_arguments);
  AstNode* ParseMapLiteral(TokenPosition type_pos,
                           bool is_const,
                           const TypeArguments& type_arguments);

  RawFunction* BuildConstructorClosureFunction(const Function& ctr,
                                               TokenPosition token_pos);
  AstNode* ParseNewOperator(Token::Kind op_kind);
  void ParseConstructorClosurization(Function* constructor,
                                     TypeArguments* type_arguments);

  // An implicit argument, if non-null, is prepended to the returned list.
  ArgumentListNode* ParseActualParameters(ArgumentListNode* implicit_arguments,
                                          const TypeArguments& func_type_args,
                                          bool require_const);
  AstNode* ParseStaticCall(const Class& cls,
                           const String& method_name,
                           TokenPosition ident_pos,
                           const TypeArguments& func_type_args,
                           const LibraryPrefix* prefix = NULL);
  AstNode* ParseInstanceCall(AstNode* receiver,
                             const String& method_name,
                             TokenPosition ident_pos,
                             const TypeArguments& func_type_args,
                             bool is_conditional);
  AstNode* ParseClosureCall(AstNode* closure,
                            const TypeArguments& func_type_args);
  AstNode* GenerateStaticFieldLookup(const Field& field,
                                     TokenPosition ident_pos);
  AstNode* GenerateStaticFieldAccess(const Class& cls,
                                     const String& field_name,
                                     TokenPosition ident_pos);

  LocalVariable* LookupLocalScope(const String& ident);
  void CheckInstanceFieldAccess(TokenPosition field_pos,
                                const String& field_name);
  bool ParsingStaticMember() const;
  const AbstractType* ReceiverType(const Class& cls);
  bool IsInstantiatorRequired() const;
  bool InGenericFunctionScope() const;
  bool ResolveIdentInLocalScope(TokenPosition ident_pos,
                                const String& ident,
                                AstNode** node,
                                intptr_t* function_level);
  static const bool kResolveLocally = true;
  static const bool kResolveIncludingImports = false;

  // Resolve a primary identifier in the library or prefix scope and
  // generate the corresponding AstNode.
  AstNode* ResolveIdentInCurrentLibraryScope(TokenPosition ident_pos,
                                             const String& ident);
  AstNode* ResolveIdentInPrefixScope(TokenPosition ident_pos,
                                     const LibraryPrefix& prefix,
                                     const String& ident);

  AstNode* ResolveIdent(TokenPosition ident_pos,
                        const String& ident,
                        bool allow_closure_names);
  RawString* ResolveImportVar(TokenPosition ident_pos, const String& ident);
  AstNode* OptimizeBinaryOpNode(TokenPosition op_pos,
                                Token::Kind binary_op,
                                AstNode* lhs,
                                AstNode* rhs);
  AstNode* ExpandAssignableOp(TokenPosition op_pos,
                              Token::Kind assignment_op,
                              AstNode* lhs,
                              AstNode* rhs);
  LetNode* PrepareCompoundAssignmentNodes(AstNode** expr);
  LocalVariable* CreateTempConstVariable(TokenPosition token_pos,
                                         const char* s);

  static SequenceNode* NodeAsSequenceNode(TokenPosition sequence_pos,
                                          AstNode* node,
                                          LocalScope* scope);

  SequenceNode* MakeImplicitConstructor(const Function& func);
  AstNode* MakeStaticCall(const String& cls_name,
                          const String& func_name,
                          ArgumentListNode* arguments);
  String& Interpolate(const GrowableArray<AstNode*>& values);
  AstNode* ThrowTypeError(TokenPosition type_pos,
                          const AbstractType& type,
                          LibraryPrefix* prefix = NULL);
  AstNode* ThrowNoSuchMethodError(TokenPosition call_pos,
                                  const Class& cls,
                                  const String& function_name,
                                  ArgumentListNode* function_arguments,
                                  InvocationMirror::Call call,
                                  InvocationMirror::Type type,
                                  const Function* func,
                                  const LibraryPrefix* prefix = NULL);

  void SetupSavedTryContext(LocalVariable* saved_try_context);

  void CheckOperatorArity(const MemberDesc& member);

  void EnsureExpressionTemp();
  bool IsLegalAssignableSyntax(AstNode* expr, TokenPosition end_pos);
  AstNode* CreateAssignmentNode(AstNode* original,
                                AstNode* rhs,
                                const String* left_ident,
                                TokenPosition left_pos,
                                bool is_compound = false);

  ConstructorCallNode* CreateConstructorCallNode(
      TokenPosition token_pos,
      const TypeArguments& type_arguments,
      const Function& constructor,
      ArgumentListNode* arguments);

  void AddEqualityNullCheck();

  AstNode* BuildClosureCall(TokenPosition token_pos,
                            AstNode* closure,
                            ArgumentListNode* arguments);

  RawInstance* TryCanonicalize(const Instance& instance,
                               TokenPosition token_pos);
  void CacheConstantValue(TokenPosition token_pos, const Instance& value);
  bool GetCachedConstant(TokenPosition token_pos, Instance* value);

  Thread* thread() const { return thread_; }
  Isolate* isolate() const { return isolate_; }
  Zone* zone() const { return thread_->zone(); }

  Thread* thread_;    // Cached current thread.
  Isolate* isolate_;  // Cached current isolate.

  Script& script_;
  TokenStream::Iterator tokens_iterator_;
  Token::Kind token_kind_;  // Cached token kind for current token.
  TokenPosition prev_token_pos_;
  Block* current_block_;

  // is_top_level_ is true if parsing the "top level" of a compilation unit,
  // that is class definitions, function type aliases, global functions,
  // global variables.
  bool is_top_level_;

  // await_is_keyword_ is true if we are parsing an async or generator
  // function. In this context the identifiers await, async and yield
  // are treated as keywords.
  bool await_is_keyword_;

  // The member currently being parsed during "top level" parsing.
  MemberDesc* current_member_;

  // Parser mode to allow/disallow function literals. This is used in
  // constructor initializer expressions to handle ambiguous grammar.
  bool SetAllowFunctionLiterals(bool value);
  bool allow_function_literals_;

  // The function currently being compiled.
  ParsedFunction* parsed_function_;

  // The function currently being parsed.
  Function& innermost_function_;

  // Current literal token.
  LiteralToken& literal_token_;

  // The class currently being parsed, or the owner class of the
  // function currently being parsed. It is used for primary identifier lookups.
  Class& current_class_;

  // The current library (and thus class dictionary) used to resolve names.
  // When parsing a function, this is the library in which the function
  // is defined. This can be the library in which the current_class_ is
  // defined, or the library of a mixin class where the function originates.
  Library& library_;

  // Stack of try blocks in scope, this is used to generate inlined finally
  // code at all points in the try block where an exit from the block is
  // done using 'return', 'break' or 'continue' statements.
  TryStack* try_stack_;

  // Each try in this function gets its own try index.
  int16_t AllocateTryIndex();

  int16_t last_used_try_index_;

  bool unregister_pending_function_;

  LocalScope* async_temp_scope_;

  // Indentation of parser trace.
  intptr_t trace_indent_;

  intptr_t recursion_counter_;
  friend class RecursionChecker;

  DISALLOW_COPY_AND_ASSIGN(Parser);
};

}  // namespace dart

#endif  // RUNTIME_VM_PARSER_H_
