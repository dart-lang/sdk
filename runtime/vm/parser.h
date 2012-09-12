// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PARSER_H_
#define VM_PARSER_H_

#include "include/dart_api.h"

#include "vm/ast.h"
#include "vm/class_finalizer.h"
#include "vm/compiler_stats.h"
#include "vm/scanner.h"

namespace dart {

// Forward declarations.
class Function;
class Script;
class TokenStream;

struct TopLevel;
struct ClassDesc;
struct MemberDesc;
struct ParamList;
struct QualIdent;
struct CatchParamDesc;
struct FieldInitExpression;

// The class ParsedFunction holds the result of parsing a function.
class ParsedFunction : public ValueObject {
 public:
  static const int kFirstLocalSlotIndex = -2;

  explicit ParsedFunction(const Function& function)
      : function_(function),
        node_sequence_(NULL),
        instantiator_(NULL),
        default_parameter_values_(Array::Handle()),
        saved_context_var_(NULL),
        expression_temp_var_(NULL),
        first_parameter_index_(0),
        first_stack_local_index_(0),
        num_copied_params_(0),
        num_stack_locals_(0) { }

  const Function& function() const { return function_; }

  SequenceNode* node_sequence() const { return node_sequence_; }
  void SetNodeSequence(SequenceNode* node_sequence);

  AstNode* instantiator() const { return instantiator_; }
  void set_instantiator(AstNode* instantiator) {
    // May be NULL.
    instantiator_ = instantiator;
  }

  const Array& default_parameter_values() const {
    return default_parameter_values_;
  }
  void set_default_parameter_values(const Array& default_parameter_values) {
    default_parameter_values_ = default_parameter_values.raw();
  }

  LocalVariable* saved_context_var() const { return saved_context_var_; }
  void set_saved_context_var(LocalVariable* saved_context_var) {
    ASSERT(saved_context_var != NULL);
    saved_context_var_ = saved_context_var;
  }

  // Returns NULL if this function does not save the arguments descriptor on
  // entry.
  LocalVariable* GetSavedArgumentsDescriptorVar() const;

  LocalVariable* expression_temp_var() const {
    ASSERT(has_expression_temp_var());
    return expression_temp_var_;
  }
  void set_expression_temp_var(LocalVariable* value) {
    ASSERT(!has_expression_temp_var());
    expression_temp_var_ = value;
  }
  bool has_expression_temp_var() const {
    return expression_temp_var_ != NULL;
  }
  static LocalVariable* CreateExpressionTempVar(intptr_t token_pos);

  int first_parameter_index() const { return first_parameter_index_; }
  int first_stack_local_index() const { return first_stack_local_index_; }
  int num_copied_params() const { return num_copied_params_; }
  int num_stack_locals() const { return num_stack_locals_; }

  void AllocateVariables();

 private:
  const Function& function_;
  SequenceNode* node_sequence_;
  AstNode* instantiator_;
  Array& default_parameter_values_;
  LocalVariable* saved_context_var_;
  LocalVariable* expression_temp_var_;

  int first_parameter_index_;
  int first_stack_local_index_;
  int num_copied_params_;
  int num_stack_locals_;

  DISALLOW_COPY_AND_ASSIGN(ParsedFunction);
};


class Parser : public ValueObject {
 public:
  Parser(const Script& script, const Library& library);
  Parser(const Script& script, const Function& function, intptr_t token_pos);

  // Parse the top level of a whole script file and register declared classes
  // and interfaces in the given library.
  static void ParseCompilationUnit(const Library& library,
                                   const Script& script);

  static void ParseFunction(ParsedFunction* parsed_function);

  // Format and print a message with source location.
  // A null script means no source and a negative token_pos means no position.
  static void PrintMessage(const Script& script,
                           intptr_t token_pos,
                           const char* message_header,
                           const char* format, ...) PRINTF_ATTRIBUTE(4, 5);

  // Build an error object containing a formatted error or warning message.
  // A null script means no source and a negative token_pos means no position.
  static RawError* FormatError(const Script& script,
                               intptr_t token_pos,
                               const char* message_header,
                               const char* format,
                               va_list args);

  // Same as FormatError, but appends the new error to the 'prev_error'.
  static RawError* FormatErrorWithAppend(const Error& prev_error,
                                         const Script& script,
                                         intptr_t token_pos,
                                         const char* message_header,
                                         const char* format,
                                         va_list args);

 private:
  struct Block;
  class TryBlocks;

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

  // The class or interface being parsed.
  const Class& current_class() const;
  void set_current_class(const Class& value);

  // Parsing a library or a regular source script.
  bool is_library_source() const {
    return (script_.kind() == RawScript::kScriptTag) ||
        (script_.kind() == RawScript::kLibraryTag);
  }

  // Parsing library patch script.
  bool is_patch_source() const {
    return script_.kind() == RawScript::kPatchTag;
  }

  intptr_t TokenPos() const { return tokens_iterator_.CurrentPosition(); }
  inline Token::Kind CurrentToken();
  Token::Kind LookaheadToken(int num_tokens);
  String* CurrentLiteral() const;
  RawDouble* CurrentDoubleLiteral() const;
  RawInteger* CurrentIntegerLiteral() const;

  // Sets parser to given token position in the stream.
  void SetPosition(intptr_t position);

  void ConsumeToken() {
    // Reset cache and advance the token.
    token_kind_ = Token::kILLEGAL;
    tokens_iterator_.Advance();
    CompilerStats::num_tokens_consumed++;
  }
  void ConsumeRightAngleBracket();
  void ExpectToken(Token::Kind token_expected);
  void ExpectSemicolon();
  void UnexpectedToken();
  String* ExpectClassIdentifier(const char* msg);
  String* ExpectIdentifier(const char* msg);
  bool IsLiteral(const char* literal);

  void SkipIf(Token::Kind);
  void SkipBlock();
  void SkipMetadata();
  void SkipToMatchingParenthesis();
  void SkipTypeArguments();
  void SkipType(bool allow_void);
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
  void SkipNewOperator();
  void SkipActualParameters();
  void SkipMapLiteral();
  void SkipListLiteral();
  void SkipFunctionLiteral();
  void SkipStringLiteral();
  void SkipQualIdent();

  void CheckConstructorCallTypeArguments(
    intptr_t pos,
    Function& constructor,
    const AbstractTypeArguments& type_arguments);

  // A null script means no source and a negative token_pos means no position.
  static RawString* FormatMessage(const Script& script,
                                  intptr_t token_pos,
                                  const char* message_header,
                                  const char* format,
                                  va_list args);

  // Reports error/warning message at location of current token.
  void ErrorMsg(const char* msg, ...) PRINTF_ATTRIBUTE(2, 3);
  void Warning(const char* msg, ...)  PRINTF_ATTRIBUTE(2, 3);
  void Unimplemented(const char* msg);

  // Reports error message at given location.
  void ErrorMsg(intptr_t token_pos, const char* msg, ...)
      PRINTF_ATTRIBUTE(3, 4);
  void Warning(intptr_t token_pos, const char* msg, ...)
      PRINTF_ATTRIBUTE(3, 4);

  // Reports an already formatted error message.
  void ErrorMsg(const Error& error);

  // Concatenates two error messages, the previous and the current one.
  void AppendErrorMsg(
      const Error& prev_error, intptr_t token_pos, const char* format, ...)
      PRINTF_ATTRIBUTE(4, 5);

  const Instance& EvaluateConstExpr(AstNode* expr);
  AstNode* RunStaticFieldInitializer(const Field& field);
  RawObject* EvaluateConstConstructorCall(
      const Class& type_class,
      const AbstractTypeArguments& type_arguments,
      const Function& constructor,
      ArgumentListNode* arguments);
  AstNode* FoldConstExpr(intptr_t expr_pos, AstNode* expr);

  // Support for parsing of scripts.
  void ParseTopLevel();
  void ParseClassDefinition(const GrowableObjectArray& pending_classes);
  void ParseInterfaceDefinition(const GrowableObjectArray& pending_classes);
  void ParseFunctionTypeAlias(const GrowableObjectArray& pending_classes);
  void ParseTopLevelVariable(TopLevel* top_level);
  void ParseTopLevelFunction(TopLevel* top_level);
  void ParseTopLevelAccessor(TopLevel* top_level);

  // Support for parsing libraries.
  Dart_Handle CallLibraryTagHandler(Dart_LibraryTag tag,
                                    intptr_t token_pos,
                                    const String& url);
  void ParseLibraryDefinition();
  void ParseLibraryName();
  void ParseLibraryImportExport();
  void ParseLibraryPart();
  void ParseLibraryNameObsoleteSyntax();
  void ParseLibraryImportObsoleteSyntax();
  void ParseLibraryIncludeObsoleteSyntax();
  void ParseLibraryResourceObsoleteSyntax();

  void ResolveTypeFromClass(const Class& cls,
                            ClassFinalizer::FinalizationKind finalization,
                            AbstractType* type);
  RawAbstractType* ParseType(ClassFinalizer::FinalizationKind finalization);
  void ParseTypeParameters(const Class& cls);
  RawAbstractTypeArguments* ParseTypeArguments(
      Error* malformed_error,
      ClassFinalizer::FinalizationKind finalization);
  void ParseQualIdent(QualIdent* qual_ident);
  void ParseMethodOrConstructor(ClassDesc* members, MemberDesc* method);
  void ParseFieldDefinition(ClassDesc* members, MemberDesc* field);
  void ParseClassMemberDefinition(ClassDesc* members);
  void ParseFormalParameter(bool allow_explicit_default_value,
                            ParamList* params);
  void ParseFormalParameters(bool allow_explicit_default_values,
                             ParamList* params);
  void ParseFormalParameterList(bool allow_explicit_default_values,
                                ParamList* params);
  void CheckConstFieldsInitialized(const Class& cls);
  void AddImplicitConstructor(ClassDesc* members);
  void CheckConstructors(ClassDesc* members);
  void ParseInitializedInstanceFields(
      const Class& cls,
      LocalVariable* receiver,
      GrowableArray<Field*>* initialized_fields);
  void CheckDuplicateFieldInit(intptr_t init_pos,
                               GrowableArray<Field*>* initialized_fields,
                               Field* field);
  void GenerateSuperConstructorCall(const Class& cls,
                                    LocalVariable* receiver);
  AstNode* ParseSuperInitializer(const Class& cls, LocalVariable* receiver);
  AstNode* ParseInitializer(const Class& cls,
                            LocalVariable* receiver,
                            GrowableArray<Field*>* initialized_fields);
  void ParseConstructorRedirection(const Class& cls, LocalVariable* receiver);
  void ParseInitializers(const Class& cls,
                         LocalVariable* receiver,
                         GrowableArray<Field*>* initialized_fields);
  String& ParseNativeDeclaration();
  // TODO(srdjan): Return TypeArguments instead of Array?
  RawArray* ParseInterfaceList();
  void AddInterfaceIfUnique(intptr_t interfaces_pos,
                            const GrowableObjectArray& interface_list,
                            const AbstractType& interface);
  void AddInterfaces(intptr_t interfaces_pos,
                     const Class& cls,
                     const Array& interfaces);
  ArgumentListNode* BuildNoSuchMethodArguments(
      const String& function_name, const ArgumentListNode& function_args);
  RawFunction* GetSuperFunction(intptr_t token_pos,
                                const String& name,
                                bool* is_no_such_method);
  AstNode* ParseSuperCall(const String& function_name);
  AstNode* ParseSuperFieldAccess(const String& field_name);
  AstNode* ParseSuperOperator();

  static void SetupDefaultsForOptionalParams(const ParamList* params,
                                             Array& default_values);
  AstNode* CreateImplicitClosureNode(const Function& func,
                                     intptr_t token_pos,
                                     AstNode* receiver);
  void AddFormalParamsToFunction(const ParamList* params, const Function& func);
  void AddFormalParamsToScope(const ParamList* params, LocalScope* scope);

  SequenceNode* ParseConstructor(const Function& func,
                                 Array& default_parameter_values);
  SequenceNode* ParseFunc(const Function& func,
                          Array& default_parameter_values);

  void ParseNativeFunctionBlock(const ParamList* params, const Function& func);

  SequenceNode* ParseInstanceGetter(const Function& func);
  SequenceNode* ParseInstanceSetter(const Function& func);
  SequenceNode* ParseStaticConstGetter(const Function& func);

  void ChainNewBlock(LocalScope* outer_scope);
  void OpenBlock();
  void OpenLoopBlock();
  void OpenFunctionBlock(const Function& func);
  SequenceNode* CloseBlock();

  LocalVariable* LookupPhaseParameter();
  LocalVariable* LookupReceiver(LocalScope* from_scope, bool test_only);
  LocalVariable* LookupTypeArgumentsParameter(LocalScope* from_scope,
                                              bool test_only);
  void CaptureInstantiator();
  AstNode* LoadReceiver(intptr_t token_pos);
  AstNode* LoadTypeArgumentsParameter(intptr_t token_pos);
  AstNode* LoadFieldIfUnresolved(AstNode* node);
  AstNode* LoadClosure(PrimaryNode* primary);
  AstNode* CallGetter(intptr_t token_pos, AstNode* object, const String& name);

  AstNode* ParseAssertStatement();
  AstNode* ParseJump(String* label_name);
  AstNode* ParseIfStatement(String* label_name);
  AstNode* ParseWhileStatement(String* label_name);
  AstNode* ParseDoWhileStatement(String* label_name);
  AstNode* ParseForStatement(String* label_name);
  AstNode* ParseForInStatement(intptr_t forin_pos, SourceLabel* label);
  CaseNode* ParseCaseClause(LocalVariable* switch_expr_value,
                            SourceLabel* case_label);
  AstNode* ParseSwitchStatement(String* label_name);

  // try/catch/finally parsing.
  void ParseCatchParameter(CatchParamDesc* catch_param);
  void AddCatchParamsToScope(const CatchParamDesc& exception_param,
                             const CatchParamDesc& stack_trace_param,
                             LocalScope* scope);
  // Parse finally block and create an AST for it.
  SequenceNode* ParseFinallyBlock();
  // Adds try block to the list of try blocks seen so far.
  void PushTryBlock(Block* try_block);
  // Pops the inner most try block from the list.
  TryBlocks* PopTryBlock();
  // Add specified node to try block list so that it can be patched with
  // inlined finally code if needed.
  void AddNodeForFinallyInlining(AstNode* node);
  // Add the inlined finally block to the specified node.
  void AddFinallyBlockToNode(AstNode* node, InlinedFinallyNode* finally_node);
  AstNode* ParseTryStatement(String* label_name);
  RawAbstractType* ParseConstFinalVarOrType(
      ClassFinalizer::FinalizationKind finalization);
  AstNode* ParseVariableDeclaration(const AbstractType& type,
                                    bool is_final,
                                    bool is_const);
  AstNode* ParseVariableDeclarationList();
  AstNode* ParseFunctionStatement(bool is_literal);
  AstNode* ParseStatement();
  SequenceNode* ParseNestedStatement(bool parsing_loop_body,
                                     SourceLabel* label);
  void ParseStatementSequence();
  bool IsIdentifier();
  bool IsSimpleLiteral(const AbstractType& type, Instance* value);
  bool IsFunctionTypeAliasName();
  bool TryParseTypeParameter();
  bool TryParseOptionalType();
  bool TryParseReturnType();
  bool IsVariableDeclaration();
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
  AstNode* ParseExpr(bool require_compiletime_const, bool consume_cascades);
  AstNode* ParseExprList();
  AstNode* ParseConditionalExpr();
  AstNode* ParseUnaryExpr();
  AstNode* ParsePostfixExpr();
  AstNode* ParseSelectors(AstNode* primary, bool is_cascade);
  AstNode* ParseCascades(AstNode* expr);
  AstNode* ParsePrimary();
  AstNode* ParseStringLiteral();
  String* ParseImportStringLiteral();
  AstNode* ParseCompoundLiteral();
  AstNode* ParseListLiteral(intptr_t type_pos,
                            bool is_const,
                            const AbstractTypeArguments& type_arguments);
  AstNode* ParseMapLiteral(intptr_t type_pos,
                           bool is_const,
                           const AbstractTypeArguments& type_arguments);
  AstNode* ParseNewOperator();
  AstNode* ParseArgumentDefinitionTest();

  // An implicit argument, if non-null, is prepended to the returned list.
  ArgumentListNode* ParseActualParameters(ArgumentListNode* implicit_arguments,
                                          bool require_const);
  AstNode* ParseStaticCall(const Class& cls,
                           const String& method_name,
                           intptr_t ident_pos);
  AstNode* ParseInstanceCall(AstNode* receiver, const String& method_name);
  AstNode* ParseClosureCall(AstNode* closure);
  AstNode* GenerateStaticFieldLookup(const Field& field,
                                     intptr_t ident_pos);
  AstNode* ParseStaticFieldAccess(const Class& cls,
                                  const String& field_name,
                                  intptr_t ident_pos,
                                  bool consume_cascades);

  LocalVariable* LookupLocalScope(const String& ident);
  bool IsFormalParameter(const String& ident,
                         Function* owner_function,
                         LocalScope** owner_scope,
                         intptr_t* local_index);
  void CheckInstanceFieldAccess(intptr_t field_pos, const String& field_name);
  RawClass* TypeParametersScopeClass() const;
  const Type* ReceiverType(intptr_t type_pos) const;
  bool IsInstantiatorRequired() const;
  bool IsDefinedInLexicalScope(const String& ident);
  bool ResolveIdentInLocalScope(intptr_t ident_pos,
                                const String &ident,
                                AstNode** node);
  static const bool kResolveLocally = true;
  static const bool kResolveIncludingImports = false;

  // Resolve a primary identifier in the libary or prefix scope and
  // generate the corresponding AstNode.
  AstNode* ResolveIdentInPrefixScope(intptr_t ident_pos,
                                     const LibraryPrefix& prefix,
                                     const String& ident);
  AstNode* ResolveIdentInCurrentLibraryScope(intptr_t ident_pos,
                                             const String& ident);

  // Find class with the given name in the library or prefix scope.
  RawClass* ResolveClassInCurrentLibraryScope(intptr_t ident_pos,
                                              const String& name);
  RawClass* ResolveClassInPrefixScope(intptr_t ident_pos,
                                      const LibraryPrefix& prefix,
                                      const String& name);

  // Find name in the library or prefix scope and return the corresponding
  // object (field, class, function etc).
  RawObject* ResolveNameInCurrentLibraryScope(intptr_t ident_pos,
                                              const String& ident);
  RawObject* ResolveNameInPrefixScope(intptr_t ident_pos,
                                      const LibraryPrefix& prefix,
                                      const String& name);

  AstNode* ResolveIdent(intptr_t ident_pos,
                        const String& ident,
                        bool allow_closure_names);
  RawString* ResolveImportVar(intptr_t ident_pos, const String& ident);
  AstNode* OptimizeBinaryOpNode(intptr_t op_pos,
                                Token::Kind binary_op,
                                AstNode* lhs,
                                AstNode* rhs);
  AstNode* ExpandAssignableOp(intptr_t op_pos,
                              Token::Kind assignment_op,
                              AstNode* lhs,
                              AstNode* rhs);
  AstNode* PrepareCompoundAssignmentNodes(AstNode** expr);
  LocalVariable* CreateTempConstVariable(intptr_t token_pos, const char* s);

  static bool IsAssignableExpr(AstNode* expr);

  static bool IsPrefixOperator(Token::Kind token);
  static bool IsIncrementOperator(Token::Kind token);

  static SequenceNode* NodeAsSequenceNode(intptr_t sequence_pos,
                                          AstNode* node,
                                          LocalScope* scope);

  SequenceNode* MakeImplicitConstructor(const Function& func);
  AstNode* MakeStaticCall(const String& cls_name,
                          const String& func_name,
                          ArgumentListNode* arguments);
  String& Interpolate(ArrayNode* values);
  AstNode* MakeAssertCall(intptr_t begin, intptr_t end);
  AstNode* ThrowTypeError(intptr_t type_pos, const AbstractType& type);

  void CheckFunctionIsCallable(intptr_t token_pos, const Function& function);
  void CheckOperatorArity(const MemberDesc& member, Token::Kind operator_token);

  const LocalVariable* GetIncrementTempLocal();
  void EnsureExpressionTemp();
  AstNode* CreateAssignmentNode(AstNode* original, AstNode* rhs);
  AstNode* InsertClosureCallNodes(AstNode* condition);

  ConstructorCallNode* CreateConstructorCallNode(
      intptr_t token_pos,
      const AbstractTypeArguments& type_arguments,
      const Function& constructor,
      ArgumentListNode* arguments);


  const Script& script_;
  TokenStream::Iterator tokens_iterator_;
  Token::Kind token_kind_;  // Cached token kind for current token.
  Block* current_block_;

  // is_top_level_ is true if parsing the "top level" of a compilation unit,
  // that is interface and class definitions.
  bool is_top_level_;

  // The member currently being parsed during "top level" parsing.
  MemberDesc* current_member_;

  // Parser mode to allow/disallow function literals. This is used in
  // constructor initializer expressions to handle ambiguous grammar.
  bool SetAllowFunctionLiterals(bool value);
  bool allow_function_literals_;

  // The function currently being compiled.
  const Function& current_function_;

  // The function currently being parsed.
  Function& innermost_function_;

  // The class or interface currently being parsed, or the owner class of the
  // function currently being parsed. It is used for primary identifier lookups.
  Class& current_class_;

  // The current library (and thus class dictionary) used to resolve names.
  const Library& library_;

  // List of try blocks seen so far, this is used to generate inlined finally
  // code at all points in the try block where an exit from the block is
  // done using 'return', 'break' or 'continue' statements.
  TryBlocks* try_blocks_list_;

  // Allocate temporary only once per function.
  LocalVariable* expression_temp_;

  DISALLOW_COPY_AND_ASSIGN(Parser);
};

}  // namespace dart

#endif  // VM_PARSER_H_
