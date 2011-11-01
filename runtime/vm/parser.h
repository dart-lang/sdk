// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PARSER_H_
#define VM_PARSER_H_

#include "include/dart_api.h"

#include "vm/ast.h"
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
class ParsedFunction : ValueObject {
 public:
  explicit ParsedFunction(const Function& function)
      : function_(function),
        node_sequence_(NULL),
        instantiator_(NULL),
        default_parameter_values_(Array::Handle()) { }

  const Function& function() const { return function_; }

  SequenceNode* node_sequence() const { return node_sequence_; }
  void set_node_sequence(SequenceNode* node_sequence) {
    ASSERT(node_sequence != NULL);
    node_sequence_ = node_sequence;
  }

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

 private:
  const Function& function_;
  SequenceNode* node_sequence_;
  AstNode* instantiator_;
  Array& default_parameter_values_;

  DISALLOW_COPY_AND_ASSIGN(ParsedFunction);
};


class Parser : ValueObject {
 public:
  static const int kErrorBuflen = 512;

  Parser(const Script& script, const Library& library);
  Parser(const Script& script,
         const Function& function,
         intptr_t token_index);

  // Parse the top level of a whole script file and register declared classes
  // and interfaces in the given library.
  static void ParseCompilationUnit(const Library& library,
                                   const Script& script);

  static void ParseFunction(ParsedFunction* parsed_function);

  static void ReportMsg(const Script& script,
                        intptr_t token_index,
                        const char* msg_type,
                        char* message,
                        const char* format, va_list args);

 private:
  struct Block;
  class TryBlocks;

  // The function being parsed.
  const Function& current_function() const;

  // Note that a local function may be parsed multiple times. It is first parsed
  // when its outermost enclosing function is being parsed. It is then parsed
  // again when an enclosing function calls this local function or calls
  // another local function enclosing it. Code for the local function will only
  // be generated the last time the local function is parsed, i.e. when it is
  // invoked. For example, a local function nested in another local function,
  // itself nested in a static function, is parsed 3 times (unless it does not
  // end up being invoked).
  // Now, current_function() always points to the outermost function being
  // parsed (i.e. the function that is being invoked), and is not updated while
  // parsing a nested function of that outermost function.
  // Therefore, the statements being parsed may or may not belong to the body of
  // the current_function(); they may belong to nested functions.
  // The function level of the current parsing scope reflects the function
  // nesting. The function level is zero while parsing the body of the
  // current_function(), but is greater than zero while parsing the body of
  // local functions nested in current_function().

  // The class or interface being parsed.
  const Class& current_class() const;
  void set_current_class(const Class& value);

  // Parsing a library or a regular source script.
  bool is_library_source() const {
    return (script_.kind() == RawScript::kScript) ||
        (script_.kind() == RawScript::kLibrary);
  }

  inline Token::Kind CurrentToken();
  Token::Kind LookaheadToken(int num_tokens);
  String* CurrentLiteral() const;

  // Sets parser to given token position in the stream.
  void SetPosition(intptr_t position);

  void ConsumeToken() {
    // Reset cache and advance the token.
    token_kind_ = Token::kILLEGAL;
    token_index_++;
    CompilerStats::num_tokens_consumed++;
  }
  void ConsumeRightAngleBracket();
  void ExpectToken(Token::Kind token_expected);
  void ExpectSemicolon();
  void UnexpectedToken();
  String* ExpectIdentifier(const char* msg);
  bool IsLiteral(const char* literal);

  void SkipIf(Token::Kind);
  void SkipBlock();
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
  void SkipPrimary();
  void SkipCompoundLiteral();
  void SkipNewOperator();
  void SkipActualParameters();
  void SkipMapLiteral();
  void SkipArrayLiteral();
  void SkipFunctionLiteral();
  void SkipStringLiteral();

  // Reports error message at location of current token.
  void ErrorMsg(const char* msg, ...);
  void ErrorMsg(intptr_t token_index, const char* msg, ...);
  void Warning(const char* msg, ...);
  void Unimplemented(const char* msg);

  const Instance& EvaluateConstExpr(AstNode* expr);
  void RunStaticFieldInitializer(const Field& field);
  RawInstance* EvaluateConstConstructorCall(const Class& type_class,
                                            const TypeArguments& type_arguments,
                                            const Function& constructor,
                                            ArgumentListNode* arguments);
  AstNode* FoldConstExpr(intptr_t expr_pos, AstNode* expr);

  // Support for parsing of scripts.
  void ParseTopLevel();
  void ParseClassDefinition(GrowableArray<const Class*>* classes);
  void ParseInterfaceDefinition(GrowableArray<const Class*>* classes);
  void ParseFunctionTypeAlias(GrowableArray<const Class*>* classes);
  void ParseTopLevelVariable(TopLevel* top_level);
  void ParseTopLevelFunction(TopLevel* top_level);
  void ParseTopLevelAccessor(TopLevel* top_level);

  // Support for parsing libraries.
  Dart_Handle CallLibraryTagHandler(Dart_LibraryTag tag,
                                    intptr_t token_pos,
                                    const String& url);
  void ParseLibraryDefinition();
  void ParseLibraryName();
  void ParseLibraryImport();
  void ParseLibraryInclude();

  bool ResolveTypeFromClass(intptr_t type_pos, const Class& cls, Type* type);
  enum TypeResolution {
    kDoNotResolve,  // Type resolution is postponed.
    kCanResolve,  // Type resolution is optional.
    kMustResolve  // Type resolution is required.
  };
  RawType* ParseType(TypeResolution type_resolution);
  void ParseTypeParameters(const Class& cls);
  RawTypeArguments* ParseTypeArguments(TypeResolution type_resolution);
  RawType* ParseInterface();
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
  void ParseNamedFormalParameters(bool are_implicitly_const, ParamList* params);
  void CheckConstFieldsInitialized(const Class& cls);
  void CheckConstructors(ClassDesc* members);
  void ParseInitializedInstanceFields(const Class& cls,
           GrowableArray<FieldInitExpression>* initializers);
  void GenerateSuperInitializerCall(const Class& cls, LocalVariable* receiver);
  AstNode* ParseSuperInitializer(const Class& cls, LocalVariable* receiver);
  AstNode* ParseInitializer(const Class& cls, LocalVariable* receiver);
  void ParseConstructorRedirection(const Class& cls, LocalVariable* receiver);
  void ParseInitializers(const Class& cls);
  String& ParseNativeDeclaration();
  RawArray* ParseInterfaceList();
  void AddInterfaces(intptr_t interfaces_pos,
                     const Class& cls,
                     const Array& interfaces);
  RawFunction* GetSuperFunction(intptr_t token_pos, const String& name);
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

  LocalVariable* LookupReceiver(LocalScope* from_scope, bool test_only);
  void CaptureReceiver();
  AstNode* LoadReceiver(intptr_t token_index);
  AstNode* CallGetter(intptr_t token_index,
                      AstNode* object,
                      const String& name);

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

  enum TypeSpecification {
    kIsOptional,  // Type specification is optional.
    kIsMandatory  // Type specification is mandatory.
  };
  RawType* ParseFinalVarOrType(TypeSpecification type_specification,
                               TypeResolution type_resolution);
  const Type& ParseConstVarOrType(TypeSpecification type_specification);
  AstNode* ParseVariableDeclaration(const Type& type, bool is_const);
  AstNode* ParseVariableDeclarationList();
  AstNode* ParseFunctionStatement(bool is_literal);
  AstNode* ParseStatement();
  SequenceNode* ParseNestedStatement(bool parsing_loop_body,
                                     SourceLabel* label);
  void ParseStatementSequence();
  bool IsFunctionTypeAliasName();
  bool IsTypeParameter();
  bool IsOptionalType();
  bool IsReturnType();
  bool IsVariableDeclaration();
  bool IsFunctionDeclaration();
  bool IsFunctionLiteral();
  bool IsForInStatement();
  bool IsTopLevelAccessor();
  bool IsTopLevelFunction();

  AstNode* ParseBinaryExpr(int min_preced);
  LiteralNode* ParseConstExpr();
  static const bool kRequireConst = true;
  static const bool kAllowConst = false;
  AstNode* ParseExpr(bool require_compiletime_const);
  AstNode* ParseExprList();
  AstNode* ParseConditionalExpr();
  AstNode* ParseUnaryExpr();
  AstNode* ParsePostfixExpr();
  AstNode* ParsePrimary();
  AstNode* ParseStringLiteral();
  AstNode* ParseCompoundLiteral();
  AstNode* ParseArrayLiteral(intptr_t type_pos,
                             bool is_const,
                             const TypeArguments& type_arguments);
  AstNode* ParseMapLiteral(intptr_t type_pos,
                           bool is_const,
                           const TypeArguments& type_arguments);
  AstNode* ParseNewOperator();

  const Array* BuildArgumentsDescriptor(
      int num_args,
      GrowableArray<const String*>& named_argument_names,
      GrowableArray<const Smi*>& named_argument_positions);
  // An implicit argument, if non-null, is prepended to the returned list.
  ArgumentListNode* ParseActualParameters(AstNode* implicit_argument,
                                          bool require_const);
  AstNode* ParseStaticCall(const Class& cls,
                           const String& method_name,
                           intptr_t ident_pos);
  AstNode* ParseInstanceCall(AstNode* receiver, const String& method_name);
  AstNode* ParseClosureCall(AstNode* closure);
  AstNode* ParseInstanceFieldAccess(AstNode* receiver,
                                    const String& field_name);
  AstNode* GenerateStaticFieldLookup(const Field& field,
                                     intptr_t ident_pos);
  AstNode* ParseStaticFieldAccess(const Class& cls,
                                  const String& field_name,
                                  intptr_t ident_pos);

  RawClass*  LookupClass(const String& class_name);
  RawObject* LookupTypeClass(const QualIdent& type_name,
                             TypeResolution type_resolution);
  LocalVariable* LookupLocalScope(const String& ident);
  void CheckInstanceFieldAccess(intptr_t field_pos, const String& field_name);
  void CheckTypeParameterReference(intptr_t type_parameter_pos,
                                   const String& type_parameter_name);
  bool ResolveIdentInLocalScope(intptr_t ident_pos,
                                const String &ident,
                                AstNode** node);
  static const bool kResolveLocally = true;
  static const bool kResolveIncludingImports = false;
  AstNode* ResolveIdentInLibraryScope(const Library& lib,
                                      const QualIdent& qual_ident,
                                      bool resolve_locally);
  AstNode* ResolveVarOrField(intptr_t ident_pos, const String &ident);
  AstNode* OptimizeBinaryOpNode(intptr_t op_pos,
                                Token::Kind binary_op,
                                AstNode* lhs,
                                AstNode* rhs);
  AstNode* ExpandAssignableOp(intptr_t op_pos,
                              Token::Kind assignment_op,
                              AstNode* lhs,
                              AstNode* rhs);
  AstNode* AsSideEffectFreeNode(AstNode* node);
  LocalVariable* CreateTempConstVariable(intptr_t token_index,
                                         intptr_t token_id,
                                         const char* s);

  static bool IsAssignableExpr(AstNode* expr);

  static bool IsPrefixOperator(Token::Kind token);
  static bool IsIncrementOperator(Token::Kind token);

  static SequenceNode* NodeAsSequenceNode(intptr_t sequence_pos,
                                          AstNode* node,
                                          LocalScope* scope);

  SequenceNode* MakeImplicitConstructor(const Function& func);
  AstNode* MakeStaticCall(const char* class_name,
                          const char* function_name,
                          ArgumentListNode* arguments);
  AstNode* MakeAssertCall(intptr_t begin, intptr_t end);

  void CheckFunctionIsCallable(intptr_t token_index, const Function& function);

  const Script& script_;
  const TokenStream& tokens_;
  intptr_t token_index_;
  Token::Kind token_kind_;  // Cached token kind for the token_index_.
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

  // The function currently being parsed.
  const Function& current_function_;

  // The class or interface currently being parsed, or the owner class of the
  // function currently being parsed. It is used for primary identifier lookups.
  Class& current_class_;

  // The current library (and thus class dictionary) used to resolve names.
  const Library& library_;

  // List of try blocks seen so far, this is used to generate inlined finally
  // code at all points in the try block where an exit from the block is
  // done using 'return', 'break' or 'continue' statements.
  TryBlocks* try_blocks_list_;

  char error_msg_[kErrorBuflen];

  DISALLOW_COPY_AND_ASSIGN(Parser);
};

}  // namespace dart

#endif  // VM_PARSER_H_
