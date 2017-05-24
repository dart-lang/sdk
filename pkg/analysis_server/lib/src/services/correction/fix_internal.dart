// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/protocol_server.dart'
    show doSourceChange_addElementEdit, doSourceChange_addSourceEdit;
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/flutter_util.dart';
import 'package:analysis_server/src/services/correction/levenshtein.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/correction/source_buffer.dart';
import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError, Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:path/path.dart';

/**
 * A predicate is a one-argument function that returns a boolean value.
 */
typedef bool ElementPredicate(Element argument);

/**
 * The implementation of [DartFixContext].
 *
 * Clients may not extend, implement or mix-in this class.
 */
class DartFixContextImpl extends FixContextImpl implements DartFixContext {
  @override
  final AstProvider astProvider;

  @override
  final CompilationUnit unit;

  DartFixContextImpl(FixContext fixContext, this.astProvider, this.unit)
      : super.from(fixContext);

  GetTopLevelDeclarations get getTopLevelDeclarations =>
      analysisDriver.getTopLevelNameDeclarations;
}

/**
 * A [FixContributor] that provides the default set of fixes.
 */
class DefaultFixContributor extends DartFixContributor {
  @override
  Future<List<Fix>> internalComputeFixes(DartFixContext context) async {
    try {
      FixProcessor processor = new FixProcessor(context);
      List<Fix> fixes = await processor.compute();
      return fixes;
    } on CancelCorrectionException {
      return Fix.EMPTY_LIST;
    }
  }
}

/**
 * The computer for Dart fixes.
 */
class FixProcessor {
  static const int MAX_LEVENSHTEIN_DISTANCE = 3;

  ResourceProvider resourceProvider;
  AstProvider astProvider;
  GetTopLevelDeclarations getTopLevelDeclarations;
  CompilationUnit unit;
  AnalysisError error;

  /**
   * The analysis driver being used to perform analysis.
   */
  AnalysisDriver driver;

  String file;
  int fileStamp;
  CompilationUnitElement unitElement;
  Source unitSource;
  LibraryElement unitLibraryElement;
  File unitLibraryFile;
  Folder unitLibraryFolder;

  final List<Fix> fixes = <Fix>[];

  SourceChange change = new SourceChange('<message>');
  final LinkedHashMap<String, LinkedEditGroup> linkedPositionGroups =
      new LinkedHashMap<String, LinkedEditGroup>();
  Position exitPosition = null;
  Set<Source> librariesToImport = new Set<Source>();

  CorrectionUtils utils;
  int errorOffset;
  int errorLength;
  int errorEnd;
  SourceRange errorRange;
  AstNode node;
  AstNode coveredNode;

  TypeProvider _typeProvider;
  TypeSystem _typeSystem;

  FixProcessor(DartFixContext dartContext) {
    resourceProvider = dartContext.resourceProvider;
    astProvider = dartContext.astProvider;
    getTopLevelDeclarations = dartContext.getTopLevelDeclarations;
    driver = dartContext.analysisDriver;
    // unit
    unit = dartContext.unit;
    unitElement = unit.element;
    unitSource = unitElement.source;
    // file
    file = unitSource.fullName;
    fileStamp = _modificationStamp(file);
    // library
    unitLibraryElement = unitElement.library;
    String unitLibraryPath = unitLibraryElement.source.fullName;
    unitLibraryFile = resourceProvider.getFile(unitLibraryPath);
    unitLibraryFolder = unitLibraryFile.parent;
    // error
    error = dartContext.error;
  }

  DartType get coreTypeBool => _getCoreType('bool');

  /**
   * Returns the EOL to use for this [CompilationUnit].
   */
  String get eol => utils.endOfLine;

  TypeProvider get typeProvider {
    if (_typeProvider == null) {
      _typeProvider = unitElement.context.typeProvider;
    }
    return _typeProvider;
  }

  TypeSystem get typeSystem {
    if (_typeSystem == null) {
      if (driver.analysisOptions.strongMode) {
        _typeSystem = new StrongTypeSystemImpl(typeProvider);
      } else {
        _typeSystem = new TypeSystemImpl(typeProvider);
      }
    }
    return _typeSystem;
  }

  Future<List<Fix>> compute() async {
    // If the source was changed between the constructor and running
    // this asynchronous method, it is not safe to use the unit.
    if (_modificationStamp(unitSource.fullName) != fileStamp) {
      return const <Fix>[];
    }

    try {
      utils = new CorrectionUtils(unit);
    } catch (e) {
      throw new CancelCorrectionException(exception: e);
    }

    errorOffset = error.offset;
    errorLength = error.length;
    errorEnd = errorOffset + errorLength;
    errorRange = new SourceRange(errorOffset, errorLength);
    node = new NodeLocator2(errorOffset).searchWithin(unit);
    coveredNode =
        new NodeLocator2(errorOffset, errorEnd - 1).searchWithin(unit);
    // analyze ErrorCode
    ErrorCode errorCode = error.errorCode;
    if (errorCode == StaticWarningCode.UNDEFINED_CLASS_BOOLEAN) {
      _addFix_boolInsteadOfBoolean();
    }
    if (errorCode ==
        CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE) {
      _addFix_replaceWithConstInstanceCreation();
    }
    if (errorCode == CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT) {
      _addFix_addAsync();
    }
    if (errorCode == CompileTimeErrorCode.INVALID_ANNOTATION) {
      if (node is Annotation) {
        Annotation annotation = node;
        Identifier name = annotation.name;
        if (name != null && name.staticElement == null) {
          node = name;
          if (annotation.arguments == null) {
            await _addFix_importLibrary_withTopLevelVariable();
          } else {
            await _addFix_importLibrary_withType();
            _addFix_createClass();
            _addFix_undefinedClass_useSimilar();
          }
        }
      }
    }
    if (errorCode ==
        CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT) {
      _addFix_createConstructorSuperExplicit();
    }
    if (errorCode ==
        CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT) {
      _addFix_createConstructorSuperImplicit();
    }
    if (errorCode ==
        CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT) {
      _addFix_createConstructorSuperExplicit();
    }
    if (errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST) {
      _addFix_createImportUri();
      _addFix_createPartUri();
    }
    if (errorCode == HintCode.CAN_BE_NULL_AFTER_NULL_AWARE) {
      _addFix_canBeNullAfterNullAware();
    }
    if (errorCode == HintCode.DEAD_CODE) {
      _addFix_removeDeadCode();
    }
    if (errorCode == HintCode.DIVISION_OPTIMIZATION) {
      _addFix_useEffectiveIntegerDivision();
    }
    if (errorCode == HintCode.TYPE_CHECK_IS_NOT_NULL) {
      _addFix_isNotNull();
    }
    if (errorCode == HintCode.TYPE_CHECK_IS_NULL) {
      _addFix_isNull();
    }
    if (errorCode == HintCode.UNDEFINED_GETTER) {
      _addFix_undefinedClassAccessor_useSimilar();
      _addFix_createField();
      _addFix_createGetter();
    }
    if (errorCode == HintCode.UNDEFINED_SETTER) {
      _addFix_undefinedClassAccessor_useSimilar();
      _addFix_createField();
    }
    if (errorCode == HintCode.UNNECESSARY_CAST) {
      _addFix_removeUnnecessaryCast();
    }
    if (errorCode == HintCode.UNUSED_CATCH_CLAUSE) {
      _addFix_removeUnusedCatchClause();
    }
    if (errorCode == HintCode.UNUSED_CATCH_STACK) {
      _addFix_removeUnusedCatchStack();
    }
    if (errorCode == HintCode.UNUSED_IMPORT) {
      _addFix_removeUnusedImport();
    }
    if (errorCode == ParserErrorCode.EXPECTED_TOKEN) {
      _addFix_insertSemicolon();
    }
    if (errorCode == ParserErrorCode.GETTER_WITH_PARAMETERS) {
      _addFix_removeParameters_inGetterDeclaration();
    }
    if (errorCode == ParserErrorCode.VAR_AS_TYPE_NAME) {
      _addFix_replaceVarWithDynamic();
    }
    if (errorCode == StaticWarningCode.ASSIGNMENT_TO_FINAL) {
      await _addFix_makeFieldNotFinal();
    }
    if (errorCode == StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER) {
      _addFix_makeEnclosingClassAbstract();
    }
    if (errorCode == StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS ||
        errorCode ==
            StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED) {
      _addFix_createConstructor_insteadOfSyntheticDefault();
      await _addFix_addMissingParameter();
    }
    if (errorCode == HintCode.MISSING_REQUIRED_PARAM ||
        errorCode == HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS) {
      _addFix_addMissingRequiredArgument();
    }
    if (errorCode == StaticWarningCode.FUNCTION_WITHOUT_CALL) {
      _addFix_addMissingMethodCall();
    }
    if (errorCode == StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR) {
      _addFix_createConstructor_named();
    }
    if (errorCode ==
            StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE ||
        errorCode ==
            StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO ||
        errorCode ==
            StaticWarningCode
                .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE ||
        errorCode ==
            StaticWarningCode
                .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR ||
        errorCode ==
            StaticWarningCode
                .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS) {
      // make class abstract
      _addFix_makeEnclosingClassAbstract();
      _addFix_createNoSuchMethod();
      // implement methods
      _addFix_createMissingOverrides();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_CLASS ||
        errorCode == StaticWarningCode.CAST_TO_NON_TYPE ||
        errorCode == StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME ||
        errorCode == StaticWarningCode.UNDEFINED_CLASS) {
      await _addFix_importLibrary_withType();
      _addFix_createClass();
      _addFix_undefinedClass_useSimilar();
    }
    if (errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED) {
      _addFix_createConstructor_forUninitializedFinalFields();
    }
    if (errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1 ||
        errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2 ||
        errorCode ==
            StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS) {
      _addFix_updateConstructor_forUninitializedFinalFields();
    }
    if (errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER) {
      _addFix_undefinedClassAccessor_useSimilar();
      _addFix_createClass();
      _addFix_createField();
      _addFix_createGetter();
      _addFix_createFunction_forFunctionType();
      await _addFix_importLibrary_withType();
      await _addFix_importLibrary_withTopLevelVariable();
      _addFix_createLocalVariable();
    }
    if (errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT) {
      _addFix_addAsync();
    }
    if (errorCode == StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE) {
      _addFix_illegalAsyncReturnType();
    }
    if (errorCode == StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER) {
      _addFix_useStaticAccess_method();
      _addFix_useStaticAccess_property();
    }
    if (errorCode == StaticTypeWarningCode.INVALID_ASSIGNMENT) {
      _addFix_changeTypeAnnotation();
    }
    if (errorCode == StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION) {
      _addFix_removeParentheses_inGetterInvocation();
    }
    if (errorCode == StaticTypeWarningCode.NON_BOOL_CONDITION) {
      _addFix_nonBoolCondition_addNotNull();
    }
    if (errorCode == StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT) {
      await _addFix_importLibrary_withType();
      _addFix_createClass();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_FUNCTION) {
      await _addFix_importLibrary_withFunction();
      _addFix_undefinedFunction_useSimilar();
      _addFix_undefinedFunction_create();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_GETTER) {
      _addFix_undefinedClassAccessor_useSimilar();
      _addFix_createField();
      _addFix_createGetter();
      _addFix_createFunction_forFunctionType();
    }
    if (errorCode == HintCode.UNDEFINED_METHOD ||
        errorCode == StaticTypeWarningCode.UNDEFINED_METHOD) {
      await _addFix_importLibrary_withFunction();
      _addFix_undefinedMethod_useSimilar();
      _addFix_undefinedMethod_create();
      _addFix_undefinedFunction_create();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_SETTER) {
      _addFix_undefinedClassAccessor_useSimilar();
      _addFix_createField();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER ||
        errorCode == StaticWarningCode.UNDEFINED_NAMED_PARAMETER) {
      _addFix_convertFlutterChild();
      _addFix_convertFlutterChildren();
    }
    // lints
    if (errorCode is LintCode) {
      if (errorCode.name == LintNames.annotate_overrides) {
        _addLintFixAddOverrideAnnotation();
      }
      if (errorCode.name == LintNames.avoid_annotating_with_dynamic) {
        _addFix_removeTypeName();
      }
      if (errorCode.name == LintNames.avoid_init_to_null) {
        _addFix_removeInitializer();
      }
      if (errorCode.name == LintNames.avoid_return_types_on_setters) {
        _addFix_removeTypeName();
      }
      if (errorCode.name == LintNames.avoid_types_on_closure_parameters) {
        _addFix_replaceWithIdentifier();
      }
      if (errorCode.name == LintNames.await_only_futures) {
        _addFix_removeAwait();
      }
      if (errorCode.name == LintNames.empty_statements) {
        _addFix_removeEmptyStatement();
      }
      if (errorCode.name == LintNames.prefer_collection_literals) {
        _addFix_replaceWithLiteral();
      }
      if (errorCode.name == LintNames.prefer_conditional_assignment) {
        _addFix_replaceWithConditionalAssignment();
      }
      if (errorCode.name == LintNames.unnecessary_brace_in_string_interp) {
        _addLintRemoveInterpolationBraces();
      }
      if (errorCode.name == LintNames.unnecessary_lambdas) {
        _addFix_replaceWithTearOff();
      }
      if (errorCode.name == LintNames.unnecessary_override) {
        _addFix_removeMethodDeclaration();
      }
      if (errorCode.name == LintNames.unnecessary_this) {
        _addFix_removeThisExpression();
      }
    }
    // done
    return fixes;
  }

  /**
   * Adds a new [SourceEdit] to [change].
   */
  void _addEdit(Element target, SourceEdit edit) {
    if (target == null) {
      target = unitElement;
    }
    Source source = target.source;
    if (source.isInSystemLibrary) {
      return;
    }
    doSourceChange_addElementEdit(change, target, edit);
  }

  void _addFix(FixKind kind, List args, {bool importsOnly: false}) {
    if (change.edits.isEmpty && !importsOnly) {
      return;
    }
    // configure Change
    change.message = formatList(kind.message, args);
    linkedPositionGroups.values
        .forEach((group) => change.addLinkedEditGroup(group));
    change.selection = exitPosition;
    // add imports
    addLibraryImports(change, unitLibraryElement, librariesToImport);
    // add Fix
    Fix fix = new Fix(kind, change);
    fixes.add(fix);
    // clear
    change = new SourceChange('<message>');
    linkedPositionGroups.clear();
    exitPosition = null;
    librariesToImport.clear();
  }

  /**
   * Returns `true` if the `async` proposal was added.
   */
  void _addFix_addAsync() {
    AstNode node = this.node;
    FunctionBody body = node.getAncestor((n) => n is FunctionBody);
    if (body != null && body.keyword == null) {
      _addReplaceEdit(range.startLength(body, 0), 'async ');
      _replaceReturnTypeWithFuture(body, typeProvider);
      _addFix(DartFixKind.ADD_ASYNC, []);
    }
  }

  void _addFix_addMissingMethodCall() {
    ClassDeclaration targetClass = node.parent as ClassDeclaration;
    // prepare SourceBuilder
    int insertOffset = targetClass.end - 1;
    SourceBuilder sb = new SourceBuilder(file, insertOffset);
    // prepare environment
    String prefix = utils.getIndent(1);
    String prefix2 = utils.getIndent(2);
    // start method
    sb.append(prefix);
    sb.append('call() {');
    // TO-DO
    sb.append(eol);
    sb.append(prefix2);
    sb.append('// TODO: implement call');
    sb.append(eol);
    // close method
    sb.append(prefix);
    sb.append('}');
    sb.append(eol);
    // add proposal
    exitPosition = new Position(file, insertOffset);
    _insertBuilder(sb, unitElement);
    _addFix(DartFixKind.CREATE_MISSING_METHOD_CALL, []);
  }

  Future<Null> _addFix_addMissingParameter() async {
    if (node is ArgumentList && node.parent is MethodInvocation) {
      ArgumentList argumentList = node;
      MethodInvocation invocation = node.parent;
      SimpleIdentifier methodName = invocation.methodName;
      Element targetElement = methodName.bestElement;
      List<Expression> arguments = argumentList.arguments;
      if (targetElement is ExecutableElement) {
        List<ParameterElement> parameters = targetElement.parameters;
        int numParameters = parameters.length;
        Iterable<ParameterElement> requiredParameters = parameters
            .takeWhile((p) => p.parameterKind == ParameterKind.REQUIRED);
        Iterable<ParameterElement> optionalParameters = parameters
            .skipWhile((p) => p.parameterKind == ParameterKind.REQUIRED);
        // prepare the argument to add a new parameter for
        int numRequired = requiredParameters.length;
        if (numRequired >= arguments.length) {
          return;
        }
        Expression argument = arguments[numRequired];
        // prepare target
        int targetOffset;
        if (numRequired != 0) {
          SimpleIdentifier lastName = await astProvider
              .getParsedNameForElement(requiredParameters.last);
          if (lastName != null) {
            targetOffset = lastName.end;
          } else {
            return;
          }
        } else {
          SimpleIdentifier targetName =
              await astProvider.getParsedNameForElement(targetElement);
          AstNode targetDeclaration = targetName?.parent;
          if (targetDeclaration is FunctionDeclaration) {
            FunctionExpression function = targetDeclaration.functionExpression;
            Token paren = function.parameters?.leftParenthesis;
            if (paren == null) {
              return;
            }
            targetOffset = paren.end;
          } else if (targetDeclaration is MethodDeclaration) {
            Token paren = targetDeclaration.parameters?.leftParenthesis;
            if (paren == null) {
              return;
            }
            targetOffset = paren.end;
          } else {
            return;
          }
        }
        String targetFile = targetElement.source.fullName;
        // required
        {
          SourceBuilder sb = new SourceBuilder(targetFile, targetOffset);
          // append source
          if (numRequired != 0) {
            sb.append(', ');
          }
          _appendParameterForArgument(
              sb, new Set<String>(), numRequired, argument);
          if (numRequired != numParameters) {
            sb.append(', ');
          }
          // add proposal
          _insertBuilder(sb, targetElement);
          _addFix(DartFixKind.ADD_MISSING_PARAMETER_REQUIRED, []);
        }
        // optional positional
        if (optionalParameters.isEmpty) {
          SourceBuilder sb = new SourceBuilder(targetFile, targetOffset);
          // append source
          if (numRequired != 0) {
            sb.append(', ');
          }
          sb.append('[');
          _appendParameterForArgument(
              sb, new Set<String>(), numRequired, argument);
          sb.append(']');
          // add proposal
          _insertBuilder(sb, targetElement);
          _addFix(DartFixKind.ADD_MISSING_PARAMETER_POSITIONAL, []);
        }
      }
    }
  }

  void _addFix_addMissingRequiredArgument() {
    Element targetElement;
    ArgumentList argumentList;

    if (node is SimpleIdentifier) {
      AstNode invocation = node.parent;
      if (invocation is MethodInvocation) {
        targetElement = invocation.methodName.bestElement;
        argumentList = invocation.argumentList;
      } else {
        AstNode ancestor =
            invocation.getAncestor((p) => p is InstanceCreationExpression);
        if (ancestor is InstanceCreationExpression) {
          targetElement = ancestor.staticElement;
          argumentList = ancestor.argumentList;
        }
      }
    }

    if (targetElement is ExecutableElement) {
      // Format: "Missing required argument 'foo"
      List<String> parts = error.message.split("'");
      if (parts.length < 2) {
        return;
      }

      // Grab just the name.
      String paramName = parts[1];

      // add proposal

      SourceBuilder sb;

      final List<Expression> args = argumentList.arguments;
      if (args.isEmpty) {
        sb = new SourceBuilder(file, argumentList.leftParenthesis.end);
      } else {
        sb = new SourceBuilder(file, args.last.end);
        sb.append(', ');
      }

      List<ParameterElement> parameters = targetElement.parameters;
      ParameterElement element =
          parameters.firstWhere((p) => p.name == paramName, orElse: () => null);
      String defaultValue = getDefaultStringParameterValue(element);
      sb.append('$paramName: $defaultValue');

      // Insert a trailing comma after Flutter instance creation params.
      InstanceCreationExpression newExpr = identifyNewExpression(node);
      if (newExpr != null && isFlutterInstanceCreationExpression(newExpr)) {
        sb.append(',');
      }

      _insertBuilder(sb, null);
      _addFix(DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT, [paramName]);
    }
  }

  void _addFix_boolInsteadOfBoolean() {
    _addReplaceEdit(range.error(error), 'bool');
    _addFix(DartFixKind.REPLACE_BOOLEAN_WITH_BOOL, []);
  }

  void _addFix_canBeNullAfterNullAware() {
    AstNode node = coveredNode;
    if (node is Expression) {
      AstNode parent = node.parent;
      while (parent != null) {
        if (parent is MethodInvocation && parent.target == node) {
          _addReplaceEdit(range.token(parent.operator), '?.');
        } else if (parent is PropertyAccess && parent.target == node) {
          _addReplaceEdit(range.token(parent.operator), '?.');
        } else {
          break;
        }
        node = parent;
        parent = node.parent;
      }
      _addFix(DartFixKind.REPLACE_WITH_NULL_AWARE, []);
    }
  }

  void _addFix_changeTypeAnnotation() {
    AstNode declaration = coveredNode.parent;
    if (declaration is VariableDeclaration &&
        declaration.initializer == coveredNode) {
      AstNode variableList = declaration.parent;
      if (variableList is VariableDeclarationList &&
          variableList.variables.length == 1) {
        TypeAnnotation typeNode = variableList.type;
        if (typeNode != null) {
          Expression initializer = coveredNode;
          DartType newType = initializer.bestType;
          if (newType is InterfaceType || newType is FunctionType) {
            String newTypeSource =
                utils.getTypeSource(newType, librariesToImport);
            _addReplaceEdit(range.node(typeNode), newTypeSource);
            _addFix(DartFixKind.CHANGE_TYPE_ANNOTATION,
                [resolutionMap.typeForTypeName(typeNode), newTypeSource]);
          }
        }
      }
    }
  }

  void _addFix_convertFlutterChild() {
    NamedExpression namedExp = findFlutterNamedExpression(node, 'child');
    if (namedExp == null) {
      return;
    }
    InstanceCreationExpression childArg = getChildWidget(namedExp, false);
    if (childArg != null) {
      convertFlutterChildToChildren(
          childArg,
          namedExp,
          eol,
          utils.getNodeText,
          utils.getLinePrefix,
          utils.getIndent,
          utils.getText,
          _addInsertEdit,
          _addRemoveEdit,
          _addReplaceEdit,
          range.node);
      _addFix(DartFixKind.CONVERT_FLUTTER_CHILD, []);
      return;
    }
    ListLiteral listArg = getChildList(namedExp);
    if (listArg != null) {
      _addInsertEdit(namedExp.offset + 'child'.length, 'ren');
      if (listArg.typeArguments == null) {
        _addInsertEdit(listArg.offset, '<Widget>');
      }
      _addFix(DartFixKind.CONVERT_FLUTTER_CHILD, []);
    }
  }

  void _addFix_convertFlutterChildren() {
    // TODO(messick) Implement _addFix_convertFlutterChildren()
  }

  void _addFix_createClass() {
    Element prefixElement = null;
    String name = null;
    SimpleIdentifier nameNode;
    if (node is SimpleIdentifier) {
      AstNode parent = node.parent;
      if (parent is PrefixedIdentifier) {
        PrefixedIdentifier prefixedIdentifier = parent;
        prefixElement = prefixedIdentifier.prefix.staticElement;
        if (prefixElement == null) {
          return;
        }
        parent = prefixedIdentifier.parent;
        nameNode = prefixedIdentifier.identifier;
        name = prefixedIdentifier.identifier.name;
      } else {
        nameNode = node;
        name = nameNode.name;
      }
      if (!_mayBeTypeIdentifier(nameNode)) {
        return;
      }
    } else {
      return;
    }
    // prepare environment
    Element targetUnit;
    SourceBuilder sb;
    String prefix = '';
    String suffix = '';
    if (prefixElement == null) {
      targetUnit = unitElement;
      CompilationUnitMember enclosingMember =
          node.getAncestor((node) => node.parent is CompilationUnit);
      if (enclosingMember == null) {
        return;
      }
      int offset = enclosingMember.end;
      sb = new SourceBuilder(file, offset);
      prefix = '$eol$eol';
    } else {
      for (ImportElement import in unitLibraryElement.imports) {
        if (prefixElement is PrefixElement && import.prefix == prefixElement) {
          LibraryElement library = import.importedLibrary;
          if (library != null) {
            targetUnit = library.definingCompilationUnit;
            Source targetSource = targetUnit.source;
            int offset = targetSource.contents.data.length;
            sb = new SourceBuilder(targetSource.fullName, offset);
            prefix = '$eol';
            suffix = '$eol';
            break;
          }
        }
      }
      if (sb == null) {
        return;
      }
    }
    // prepare source
    {
      sb.append(prefix);
      // "class"
      sb.append('class ');
      // append name
      if (prefixElement == null) {
        sb.startPosition('NAME');
        sb.append(name);
        sb.endPosition();
      } else {
        sb.append(name);
      }
      // no members
      sb.append(' {');
      sb.append(eol);
      sb.append('}');
      sb.append(suffix);
    }
    // insert source
    _insertBuilder(sb, targetUnit);
    if (prefixElement == null) {
      _addLinkedPosition('NAME', sb, range.node(node));
    }
    // add proposal
    _addFix(DartFixKind.CREATE_CLASS, [name]);
  }

  /**
   * Here we handle cases when there are no constructors in a class, and the
   * class has uninitialized final fields.
   */
  void _addFix_createConstructor_forUninitializedFinalFields() {
    if (node is! SimpleIdentifier || node.parent is! VariableDeclaration) {
      return;
    }
    ClassDeclaration classDeclaration =
        node.getAncestor((node) => node is ClassDeclaration);
    if (classDeclaration == null) {
      return;
    }
    // prepare names of uninitialized final fields
    List<String> fieldNames = <String>[];
    for (ClassMember member in classDeclaration.members) {
      if (member is FieldDeclaration) {
        VariableDeclarationList variableList = member.fields;
        if (variableList.isFinal) {
          fieldNames.addAll(variableList.variables
              .where((v) => v.initializer == null)
              .map((v) => v.name.name));
        }
      }
    }
    // prepare location for a new constructor
    ClassMemberLocation targetLocation =
        utils.prepareNewConstructorLocation(classDeclaration);
    // build constructor source
    SourceBuilder sb = new SourceBuilder(file, targetLocation.offset);
    {
      sb.append(targetLocation.prefix);
      sb.append(classDeclaration.name.name);
      sb.append('(');
      sb.append(fieldNames.map((name) => 'this.$name').join(', '));
      sb.append(');');
      sb.append(targetLocation.suffix);
    }
    // insert source
    _insertBuilder(sb, unitElement);
    // add proposal
    _addFix(DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS, []);
  }

  void _addFix_createConstructor_insteadOfSyntheticDefault() {
    if (node is! ArgumentList) {
      return;
    }
    if (node.parent is! InstanceCreationExpression) {
      return;
    }
    InstanceCreationExpression instanceCreation = node.parent;
    ConstructorName constructorName = instanceCreation.constructorName;
    // should be synthetic default constructor
    ConstructorElement constructorElement = constructorName.staticElement;
    if (constructorElement == null ||
        !constructorElement.isDefaultConstructor ||
        !constructorElement.isSynthetic) {
      return;
    }
    // prepare target
    if (constructorElement.enclosingElement is! ClassElement) {
      return;
    }
    ClassElement targetElement = constructorElement.enclosingElement;
    // prepare location for a new constructor
    AstNode targetTypeNode = getParsedClassElementNode(targetElement);
    if (targetTypeNode is! ClassDeclaration) {
      return;
    }
    ClassMemberLocation targetLocation =
        utils.prepareNewConstructorLocation(targetTypeNode);
    String targetFile = targetElement.source.fullName;
    // build method source
    SourceBuilder sb = new SourceBuilder(targetFile, targetLocation.offset);
    {
      sb.append(targetLocation.prefix);
      sb.append(targetElement.name);
      _addFix_undefinedMethod_create_parameters(
          sb, instanceCreation.argumentList);
      sb.append(');');
      sb.append(targetLocation.suffix);
    }
    // insert source
    _insertBuilder(sb, targetElement);
    // add proposal
    _addFix(DartFixKind.CREATE_CONSTRUCTOR, [constructorName]);
  }

  void _addFix_createConstructor_named() {
    SimpleIdentifier name = null;
    ConstructorName constructorName = null;
    InstanceCreationExpression instanceCreation = null;
    if (node is SimpleIdentifier) {
      // name
      name = node as SimpleIdentifier;
      if (name.parent is ConstructorName) {
        constructorName = name.parent as ConstructorName;
        if (constructorName.name == name) {
          // Type.name
          if (constructorName.parent is InstanceCreationExpression) {
            instanceCreation =
                constructorName.parent as InstanceCreationExpression;
            // new Type.name()
            if (instanceCreation.constructorName != constructorName) {
              return;
            }
          }
        }
      }
    }
    // do we have enough information?
    if (instanceCreation == null) {
      return;
    }
    // prepare target interface type
    DartType targetType = constructorName.type.type;
    if (targetType is! InterfaceType) {
      return;
    }
    // prepare location for a new constructor
    ClassElement targetElement = targetType.element as ClassElement;
    AstNode targetTypeNode = getParsedClassElementNode(targetElement);
    if (targetTypeNode is! ClassDeclaration) {
      return;
    }
    ClassMemberLocation targetLocation =
        utils.prepareNewConstructorLocation(targetTypeNode);
    String targetFile = targetElement.source.fullName;
    // build method source
    SourceBuilder sb = new SourceBuilder(targetFile, targetLocation.offset);
    {
      sb.append(targetLocation.prefix);
      sb.append(targetElement.name);
      sb.append('.');
      // append name
      {
        sb.startPosition('NAME');
        sb.append(name.name);
        sb.endPosition();
      }
      _addFix_undefinedMethod_create_parameters(
          sb, instanceCreation.argumentList);
      sb.append(');');
      sb.append(targetLocation.suffix);
    }
    // insert source
    _insertBuilder(sb, targetElement);
    if (targetFile == file) {
      _addLinkedPosition('NAME', sb, range.node(name));
    }
    // add proposal
    _addFix(DartFixKind.CREATE_CONSTRUCTOR, [constructorName]);
  }

  void _addFix_createConstructorSuperExplicit() {
    if (node.parent is! ConstructorDeclaration ||
        node.parent.parent is! ClassDeclaration) {
      return;
    }
    ConstructorDeclaration targetConstructor =
        node.parent as ConstructorDeclaration;
    ClassDeclaration targetClassNode =
        targetConstructor.parent as ClassDeclaration;
    ClassElement targetClassElement = targetClassNode.element;
    InterfaceType superType = targetClassElement.supertype;
    // add proposals for all super constructors
    for (ConstructorElement superConstructor in superType.constructors) {
      String constructorName = superConstructor.name;
      // skip private
      if (Identifier.isPrivateName(constructorName)) {
        continue;
      }
      // prepare SourceBuilder
      SourceBuilder sb;
      {
        List<ConstructorInitializer> initializers =
            targetConstructor.initializers;
        if (initializers.isEmpty) {
          int insertOffset = targetConstructor.parameters.end;
          sb = new SourceBuilder(file, insertOffset);
          sb.append(' : ');
        } else {
          ConstructorInitializer lastInitializer =
              initializers[initializers.length - 1];
          int insertOffset = lastInitializer.end;
          sb = new SourceBuilder(file, insertOffset);
          sb.append(', ');
        }
      }
      // add super constructor name
      sb.append('super');
      if (!isEmpty(constructorName)) {
        sb.append('.');
        sb.append(constructorName);
      }
      // add arguments
      sb.append('(');
      bool firstParameter = true;
      for (ParameterElement parameter in superConstructor.parameters) {
        // skip non-required parameters
        if (parameter.parameterKind != ParameterKind.REQUIRED) {
          break;
        }
        // comma
        if (firstParameter) {
          firstParameter = false;
        } else {
          sb.append(', ');
        }
        // default value
        DartType parameterType = parameter.type;
        sb.startPosition(parameter.name);
        sb.append(getDefaultValueCode(parameterType));
        sb.endPosition();
      }
      sb.append(')');
      // insert proposal
      _insertBuilder(sb, unitElement);
      // add proposal
      String proposalName = _getConstructorProposalName(superConstructor);
      _addFix(DartFixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION, [proposalName]);
    }
  }

  void _addFix_createConstructorSuperImplicit() {
    ClassDeclaration targetClassNode = node.parent as ClassDeclaration;
    ClassElement targetClassElement = targetClassNode.element;
    InterfaceType superType = targetClassElement.supertype;
    String targetClassName = targetClassElement.name;
    // add proposals for all super constructors
    for (ConstructorElement superConstructor in superType.constructors) {
      superConstructor = ConstructorMember.from(superConstructor, superType);
      String constructorName = superConstructor.name;
      // skip private
      if (Identifier.isPrivateName(constructorName)) {
        continue;
      }
      // prepare parameters and arguments
      SourceBuilder parametersBuffer = new SourceBuilder.buffer();
      SourceBuilder argumentsBuffer = new SourceBuilder.buffer();
      bool firstParameter = true;
      for (ParameterElement parameter in superConstructor.parameters) {
        // skip non-required parameters
        if (parameter.parameterKind != ParameterKind.REQUIRED) {
          break;
        }
        // comma
        if (firstParameter) {
          firstParameter = false;
        } else {
          parametersBuffer.append(', ');
          argumentsBuffer.append(', ');
        }
        // name
        String parameterName = parameter.displayName;
        if (parameterName.length > 1 && parameterName.startsWith('_')) {
          parameterName = parameterName.substring(1);
        }
        // parameter & argument
        _appendParameterSource(parametersBuffer, parameter.type, parameterName);
        argumentsBuffer.append(parameterName);
      }
      // add proposal
      ClassMemberLocation targetLocation =
          utils.prepareNewConstructorLocation(targetClassNode);
      SourceBuilder sb = new SourceBuilder(file, targetLocation.offset);
      {
        sb.append(targetLocation.prefix);
        sb.append(targetClassName);
        if (!constructorName.isEmpty) {
          sb.startPosition('NAME');
          sb.append('.');
          sb.append(constructorName);
          sb.endPosition();
        }
        sb.append('(');
        sb.append(parametersBuffer.toString());
        sb.append(') : super');
        if (!constructorName.isEmpty) {
          sb.append('.');
          sb.append(constructorName);
        }
        sb.append('(');
        sb.append(argumentsBuffer.toString());
        sb.append(');');
        sb.append(targetLocation.suffix);
      }
      _insertBuilder(sb, unitElement);
      // add proposal
      String proposalName = _getConstructorProposalName(superConstructor);
      _addFix(DartFixKind.CREATE_CONSTRUCTOR_SUPER, [proposalName]);
    }
  }

  void _addFix_createField() {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier nameNode = node;
    String name = nameNode.name;
    // prepare target Expression
    Expression target;
    {
      AstNode nameParent = nameNode.parent;
      if (nameParent is PrefixedIdentifier) {
        target = nameParent.prefix;
      }
      if (nameParent is PropertyAccess) {
        target = nameParent.realTarget;
      }
    }
    // prepare target ClassElement
    bool staticModifier = false;
    ClassElement targetClassElement;
    if (target != null) {
      // prepare target interface type
      DartType targetType = target.bestType;
      if (targetType is! InterfaceType) {
        return;
      }
      targetClassElement = targetType.element;
      // maybe static
      if (target is Identifier) {
        Identifier targetIdentifier = target;
        Element targetElement = targetIdentifier.bestElement;
        if (targetElement == null) {
          return;
        }
        staticModifier = targetElement.kind == ElementKind.CLASS;
      }
    } else {
      targetClassElement = getEnclosingClassElement(node);
      if (targetClassElement == null) {
        return;
      }
      staticModifier = _inStaticContext();
    }
    if (targetClassElement.librarySource.isInSystemLibrary) {
      return;
    }
    utils.targetClassElement = targetClassElement;
    // prepare target ClassDeclaration
    AstNode targetTypeNode = getParsedClassElementNode(targetClassElement);
    if (targetTypeNode is! ClassDeclaration) {
      return;
    }
    ClassDeclaration targetClassNode = targetTypeNode;
    // prepare location
    ClassMemberLocation targetLocation =
        utils.prepareNewFieldLocation(targetClassNode);
    // build method source
    String targetFile = targetClassElement.source.fullName;
    SourceBuilder sb = new SourceBuilder(targetFile, targetLocation.offset);
    {
      sb.append(targetLocation.prefix);
      // maybe "static"
      if (staticModifier) {
        sb.append('static ');
      }
      // append type
      Expression fieldTypeNode = climbPropertyAccess(nameNode);
      DartType fieldType = _inferUndefinedExpressionType(fieldTypeNode);
      _appendType(sb, fieldType, groupId: 'TYPE', orVar: true);
      // append name
      {
        sb.startPosition('NAME');
        sb.append(name);
        sb.endPosition();
      }
      sb.append(';');
      sb.append(targetLocation.suffix);
    }
    // insert source
    _insertBuilder(sb, targetClassElement);
    // add linked positions
    if (targetFile == file) {
      _addLinkedPosition('NAME', sb, range.node(node));
    }
    // add proposal
    _addFix(DartFixKind.CREATE_FIELD, [name]);
  }

  void _addFix_createFunction_forFunctionType() {
    if (node is SimpleIdentifier) {
      SimpleIdentifier nameNode = node as SimpleIdentifier;
      // prepare argument expression (to get parameter)
      ClassElement targetElement;
      Expression argument;
      {
        Expression target = getQualifiedPropertyTarget(node);
        if (target != null) {
          DartType targetType = target.bestType;
          if (targetType != null && targetType.element is ClassElement) {
            targetElement = targetType.element as ClassElement;
            argument = target.parent as Expression;
          } else {
            return;
          }
        } else {
          ClassDeclaration enclosingClass =
              node.getAncestor((node) => node is ClassDeclaration);
          targetElement = enclosingClass?.element;
          argument = nameNode;
        }
      }
      argument = stepUpNamedExpression(argument);
      // should be argument of some invocation
      ParameterElement parameterElement = argument.bestParameterElement;
      if (parameterElement == null) {
        return;
      }
      // should be parameter of function type
      DartType parameterType = parameterElement.type;
      if (parameterType is InterfaceType && parameterType.isDartCoreFunction) {
        ExecutableElement element = new MethodElementImpl('', -1);
        parameterType = new FunctionTypeImpl(element);
      }
      if (parameterType is! FunctionType) {
        return;
      }
      FunctionType functionType = parameterType as FunctionType;
      // add proposal
      if (targetElement != null) {
        _addProposal_createFunction_method(targetElement, functionType);
      } else {
        _addProposal_createFunction_function(functionType);
      }
    }
  }

  void _addFix_createGetter() {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier nameNode = node;
    String name = nameNode.name;
    if (!nameNode.inGetterContext()) {
      return;
    }
    // prepare target Expression
    Expression target;
    {
      AstNode nameParent = nameNode.parent;
      if (nameParent is PrefixedIdentifier) {
        target = nameParent.prefix;
      }
      if (nameParent is PropertyAccess) {
        target = nameParent.realTarget;
      }
    }
    // prepare target ClassElement
    bool staticModifier = false;
    ClassElement targetClassElement;
    if (target != null) {
      // prepare target interface type
      DartType targetType = target.bestType;
      if (targetType is! InterfaceType) {
        return;
      }
      targetClassElement = targetType.element;
      // maybe static
      if (target is Identifier) {
        Identifier targetIdentifier = target;
        Element targetElement = targetIdentifier.bestElement;
        staticModifier = targetElement.kind == ElementKind.CLASS;
      }
    } else {
      targetClassElement = getEnclosingClassElement(node);
      if (targetClassElement == null) {
        return;
      }
      staticModifier = _inStaticContext();
    }
    if (targetClassElement.librarySource.isInSystemLibrary) {
      return;
    }
    utils.targetClassElement = targetClassElement;
    // prepare target ClassDeclaration
    AstNode targetTypeNode = getParsedClassElementNode(targetClassElement);
    if (targetTypeNode is! ClassDeclaration) {
      return;
    }
    ClassDeclaration targetClassNode = targetTypeNode;
    // prepare location
    ClassMemberLocation targetLocation =
        utils.prepareNewGetterLocation(targetClassNode);
    // build method source
    String targetFile = targetClassElement.source.fullName;
    SourceBuilder sb = new SourceBuilder(targetFile, targetLocation.offset);
    {
      sb.append(targetLocation.prefix);
      // maybe "static"
      if (staticModifier) {
        sb.append('static ');
      }
      // append type
      Expression fieldTypeNode = climbPropertyAccess(nameNode);
      DartType fieldType = _inferUndefinedExpressionType(fieldTypeNode);
      _appendType(sb, fieldType, groupId: 'TYPE');
      sb.append('get ');
      // append name
      {
        sb.startPosition('NAME');
        sb.append(name);
        sb.endPosition();
      }
      sb.append(' => null;');
      sb.append(targetLocation.suffix);
    }
    // insert source
    _insertBuilder(sb, targetClassElement);
    // add linked positions
    if (targetFile == file) {
      _addLinkedPosition('NAME', sb, range.node(node));
    }
    // add proposal
    _addFix(DartFixKind.CREATE_GETTER, [name]);
  }

  void _addFix_createImportUri() {
    // TODO(brianwilkerson) Generalize this to allow other valid string literals.
    // TODO(brianwilkerson) Support the case where the node's parent is a Configuration.
    if (node is SimpleStringLiteral && node.parent is ImportDirective) {
      ImportDirective importDirective = node.parent;
      Source source = importDirective.uriSource;
      if (source != null) {
        String file = source.fullName;
        if (isAbsolute(file) && AnalysisEngine.isDartFileName(file)) {
          String libName = _computeLibraryName(file);
          SourceEdit edit = new SourceEdit(0, 0, 'library $libName;$eol$eol');
          doSourceChange_addSourceEdit(change, source, edit, isNewFile: true);
          _addFix(DartFixKind.CREATE_FILE, [source.shortName]);
        }
      }
    }
  }

  void _addFix_createLocalVariable() {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier nameNode = node;
    String name = nameNode.name;
    // if variable is assigned, convert assignment into declaration
    if (node.parent is AssignmentExpression) {
      AssignmentExpression assignment = node.parent;
      if (assignment.leftHandSide == node &&
          assignment.operator.type == TokenType.EQ &&
          assignment.parent is ExpressionStatement) {
        _addInsertEdit(node.offset, 'var ');
        _addFix(DartFixKind.CREATE_LOCAL_VARIABLE, [name]);
        return;
      }
    }
    // prepare target Statement
    Statement target = node.getAncestor((x) => x is Statement);
    if (target == null) {
      return;
    }
    String prefix = utils.getNodePrefix(target);
    // build variable declaration source
    SourceBuilder sb = new SourceBuilder(file, target.offset);
    {
      // append type
      DartType type = _inferUndefinedExpressionType(node);
      if (!(type == null ||
          type is InterfaceType ||
          type is FunctionType &&
              type.element != null &&
              !type.element.isSynthetic)) {
        return;
      }
      _appendType(sb, type, groupId: 'TYPE', orVar: true);
      // append name
      {
        sb.startPosition('NAME');
        sb.append(name);
        sb.endPosition();
      }
      sb.append(';');
      sb.append(eol);
      sb.append(prefix);
    }
    // insert source
    _insertBuilder(sb, unitElement);
    // add linked positions
    _addLinkedPosition('NAME', sb, range.node(node));
    // add proposal
    _addFix(DartFixKind.CREATE_LOCAL_VARIABLE, [name]);
  }

  void _addFix_createMissingOverrides() {
    // prepare target
    ClassDeclaration targetClass = node.parent as ClassDeclaration;
    ClassElement targetClassElement = targetClass.element;
    utils.targetClassElement = targetClassElement;
    List<ExecutableElement> elements = ErrorVerifier
        .computeMissingOverrides(
            driver.analysisOptions.strongMode,
            typeProvider,
            typeSystem,
            new InheritanceManager(unitLibraryElement),
            targetClassElement)
        .toList();
    // sort by name, getters before setters
    elements.sort((Element a, Element b) {
      int names = compareStrings(a.displayName, b.displayName);
      if (names != 0) {
        return names;
      }
      if (a.kind == ElementKind.GETTER) {
        return -1;
      }
      return 1;
    });
    // prepare SourceBuilder
    int insertOffset = targetClass.end - 1;
    SourceBuilder sb = new SourceBuilder(file, insertOffset);
    // EOL management
    bool isFirst = true;
    void addEolIfNotFirst() {
      if (!isFirst || utils.isClassWithEmptyBody(targetClass)) {
        sb.append(eol);
      }
      isFirst = false;
    }

    // merge getter/setter pairs into fields
    String prefix = utils.getIndent(1);
    int numElements = elements.length;
    for (int i = 0; i < elements.length; i++) {
      ExecutableElement element = elements[i];
      if (element.kind == ElementKind.GETTER && i + 1 < elements.length) {
        ExecutableElement nextElement = elements[i + 1];
        if (nextElement.kind == ElementKind.SETTER) {
          // remove this and the next elements, adjust iterator
          elements.removeAt(i + 1);
          elements.removeAt(i);
          i--;
          numElements--;
          // separator
          addEolIfNotFirst();
          // @override
          {
            sb.append(prefix);
            sb.append('@override');
            sb.append(eol);
          }
          // add field
          sb.append(prefix);
          _appendType(sb, element.type.returnType, orVar: true);
          sb.append(element.name);
          sb.append(';');
          sb.append(eol);
        }
      }
    }
    // add elements
    for (ExecutableElement element in elements) {
      addEolIfNotFirst();
      _addFix_createMissingOverrides_single(sb, targetClass, element);
    }
    // add proposal
    exitPosition = new Position(file, insertOffset);
    _insertBuilder(sb, unitElement);
    _addFix(DartFixKind.CREATE_MISSING_OVERRIDES, [numElements]);
  }

  void _addFix_createMissingOverrides_single(SourceBuilder sb,
      ClassDeclaration targetClass, ExecutableElement element) {
    utils.targetExecutableElement = element;
    // prepare environment
    String prefix = utils.getIndent(1);
    String prefix2 = utils.getIndent(2);
    // may be property
    ElementKind elementKind = element.kind;
    bool isGetter = elementKind == ElementKind.GETTER;
    bool isSetter = elementKind == ElementKind.SETTER;
    bool isMethod = elementKind == ElementKind.METHOD;
    bool isOperator = isMethod && (element as MethodElement).isOperator;
    sb.append(prefix);
    if (isGetter) {
      sb.append('// TODO: implement ${element.displayName}');
      sb.append(eol);
      sb.append(prefix);
    }
    // @override
    {
      sb.append('@override');
      sb.append(eol);
      sb.append(prefix);
    }
    // return type
    if (!isSetter) {
      _appendType(sb, element.type.returnType);
    }
    // keyword
    if (isGetter) {
      sb.append('get ');
    } else if (isSetter) {
      sb.append('set ');
    } else if (isOperator) {
      sb.append('operator ');
    }
    // name
    sb.append(element.displayName);
    _appendTypeParameters(sb, element.typeParameters);
    // parameters + body
    if (isGetter) {
      sb.append(' => null;');
    } else {
      List<ParameterElement> parameters = element.parameters;
      _appendParameters(sb, parameters);
      sb.append(' {');
      // TO-DO
      sb.append(eol);
      sb.append(prefix2);
      sb.append('// TODO: implement ${element.displayName}');
      sb.append(eol);
      // close method
      sb.append(prefix);
      sb.append('}');
    }
    sb.append(eol);
    utils.targetExecutableElement = null;
  }

  void _addFix_createNoSuchMethod() {
    ClassDeclaration targetClass = node.parent as ClassDeclaration;
    // prepare environment
    String prefix = utils.getIndent(1);
    int insertOffset = targetClass.end - 1;
    // prepare source
    SourceBuilder sb = new SourceBuilder(file, insertOffset);
    {
      // insert empty line before existing member
      if (!targetClass.members.isEmpty) {
        sb.append(eol);
      }
      // append method
      sb.append(prefix);
      sb.append(
          'noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);');
      sb.append(eol);
    }
    // done
    _insertBuilder(sb, unitElement);
    exitPosition = new Position(file, insertOffset);
    // add proposal
    _addFix(DartFixKind.CREATE_NO_SUCH_METHOD, []);
  }

  void _addFix_createPartUri() {
    // TODO(brianwilkerson) Generalize this to allow other valid string literals.
    if (node is SimpleStringLiteral && node.parent is PartDirective) {
      PartDirective partDirective = node.parent;
      Source source = partDirective.uriSource;
      if (source != null) {
        String libName = unitLibraryElement.name;
        SourceEdit edit = new SourceEdit(0, 0, 'part of $libName;$eol$eol');
        doSourceChange_addSourceEdit(change, source, edit, isNewFile: true);
        _addFix(DartFixKind.CREATE_FILE, [source.shortName]);
      }
    }
  }

  void _addFix_illegalAsyncReturnType() {
    // prepare the existing type
    TypeAnnotation typeName = node.getAncestor((n) => n is TypeAnnotation);
    _replaceTypeWithFuture(typeName, typeProvider);
    // add proposal
    _addFix(DartFixKind.REPLACE_RETURN_TYPE_FUTURE, []);
  }

  void _addFix_importLibrary(FixKind kind, Source library) {
    librariesToImport.add(library);
    String libraryUri = getLibrarySourceUri(unitLibraryElement, library);
    _addFix(kind, [libraryUri], importsOnly: true);
  }

  Future<Null> _addFix_importLibrary_withElement(String name,
      List<ElementKind> elementKinds, TopLevelDeclarationKind kind2) async {
    // ignore if private
    if (name.startsWith('_')) {
      return;
    }
    // may be there is an existing import,
    // but it is with prefix and we don't use this prefix
    Set<Source> alreadyImportedWithPrefix = new Set<Source>();
    for (ImportElement imp in unitLibraryElement.imports) {
      // prepare element
      LibraryElement libraryElement = imp.importedLibrary;
      Element element = getExportedElement(libraryElement, name);
      if (element == null) {
        continue;
      }
      if (element is PropertyAccessorElement) {
        element = (element as PropertyAccessorElement).variable;
      }
      if (!elementKinds.contains(element.kind)) {
        continue;
      }
      // may be apply prefix
      PrefixElement prefix = imp.prefix;
      if (prefix != null) {
        _addReplaceEdit(range.startLength(node, 0), '${prefix.displayName}.');
        _addFix(DartFixKind.IMPORT_LIBRARY_PREFIX,
            [libraryElement.displayName, prefix.displayName]);
        continue;
      }
      // may be update "show" directive
      List<NamespaceCombinator> combinators = imp.combinators;
      if (combinators.length == 1 && combinators[0] is ShowElementCombinator) {
        ShowElementCombinator showCombinator =
            combinators[0] as ShowElementCombinator;
        // prepare new set of names to show
        Set<String> showNames = new SplayTreeSet<String>();
        showNames.addAll(showCombinator.shownNames);
        showNames.add(name);
        // prepare library name - unit name or 'dart:name' for SDK library
        String libraryName = libraryElement.definingCompilationUnit.displayName;
        if (libraryElement.isInSdk) {
          libraryName = imp.uri;
        }
        // don't add this library again
        alreadyImportedWithPrefix.add(libraryElement.source);
        // update library
        String newShowCode = 'show ${showNames.join(', ')}';
        int offset = showCombinator.offset;
        int length = showCombinator.end - offset;
        _addReplaceEdit(
            new SourceRange(offset, length), newShowCode, unitLibraryElement);
        _addFix(DartFixKind.IMPORT_LIBRARY_SHOW, [libraryName]);
      }
    }
    // Find new top-level declarations.
    {
      List<TopLevelDeclarationInSource> declarations =
          await getTopLevelDeclarations(name);
      for (TopLevelDeclarationInSource declaration in declarations) {
        // Check the kind.
        if (declaration.declaration.kind != kind2) {
          continue;
        }
        // Check the source.
        Source librarySource = declaration.source;
        if (alreadyImportedWithPrefix.contains(librarySource)) {
          continue;
        }
        if (!_isSourceVisibleToLibrary(librarySource)) {
          continue;
        }
        // Compute the fix kind.
        FixKind fixKind;
        if (librarySource.isInSystemLibrary) {
          fixKind = DartFixKind.IMPORT_LIBRARY_SDK;
        } else if (_isLibSrcPath(librarySource.fullName)) {
          // Bad: non-API.
          fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT3;
        } else if (declaration.isExported) {
          // Ugly: exports.
          fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT2;
        } else {
          // Good: direct declaration.
          fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT1;
        }
        // Add the fix.
        _addFix_importLibrary(fixKind, librarySource);
      }
    }
  }

  Future<Null> _addFix_importLibrary_withFunction() async {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      if (invocation.realTarget == null && invocation.methodName == node) {
        String name = (node as SimpleIdentifier).name;
        await _addFix_importLibrary_withElement(name,
            const [ElementKind.FUNCTION], TopLevelDeclarationKind.function);
      }
    }
  }

  Future<Null> _addFix_importLibrary_withTopLevelVariable() async {
    if (node is SimpleIdentifier) {
      String name = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(
          name,
          const [ElementKind.TOP_LEVEL_VARIABLE],
          TopLevelDeclarationKind.variable);
    }
  }

  Future<Null> _addFix_importLibrary_withType() async {
    if (_mayBeTypeIdentifier(node)) {
      String typeName = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(
          typeName,
          const [ElementKind.CLASS, ElementKind.FUNCTION_TYPE_ALIAS],
          TopLevelDeclarationKind.type);
    }
  }

  void _addFix_insertSemicolon() {
    if (error.message.contains("';'")) {
      if (_isAwaitNode()) {
        return;
      }
      int insertOffset = error.offset + error.length;
      _addInsertEdit(insertOffset, ';');
      _addFix(DartFixKind.INSERT_SEMICOLON, []);
    }
  }

  void _addFix_isNotNull() {
    if (coveredNode is IsExpression) {
      IsExpression isExpression = coveredNode as IsExpression;
      _addReplaceEdit(
          range.endEnd(isExpression.expression, isExpression), ' != null');
      _addFix(DartFixKind.USE_NOT_EQ_NULL, []);
    }
  }

  void _addFix_isNull() {
    if (coveredNode is IsExpression) {
      IsExpression isExpression = coveredNode as IsExpression;
      _addReplaceEdit(
          range.endEnd(isExpression.expression, isExpression), ' == null');
      _addFix(DartFixKind.USE_EQ_EQ_NULL, []);
    }
  }

  void _addFix_makeEnclosingClassAbstract() {
    ClassDeclaration enclosingClass =
        node.getAncestor((node) => node is ClassDeclaration);
    if (enclosingClass == null) {
      return;
    }
    String className = enclosingClass.name.name;
    _addInsertEdit(enclosingClass.classKeyword.offset, 'abstract ');
    _addFix(DartFixKind.MAKE_CLASS_ABSTRACT, [className]);
  }

  Future<Null> _addFix_makeFieldNotFinal() async {
    AstNode node = this.node;
    if (node is SimpleIdentifier &&
        node.bestElement is PropertyAccessorElement) {
      PropertyAccessorElement getter = node.bestElement;
      if (getter.isGetter &&
          getter.isSynthetic &&
          !getter.variable.isSynthetic &&
          getter.variable.setter == null &&
          getter.enclosingElement is ClassElement) {
        AstNode name =
            await astProvider.getParsedNameForElement(getter.variable);
        AstNode variable = name?.parent;
        if (variable is VariableDeclaration &&
            variable.parent is VariableDeclarationList &&
            variable.parent.parent is FieldDeclaration) {
          VariableDeclarationList declarationList = variable.parent;
          Token keywordToken = declarationList.keyword;
          if (declarationList.variables.length == 1 &&
              keywordToken.keyword == Keyword.FINAL) {
            if (declarationList.type != null) {
              _addRemoveEdit(
                  range.startStart(keywordToken, declarationList.type));
            } else {
              _addReplaceEdit(range.startStart(keywordToken, variable), 'var ');
            }
            String fieldName = getter.variable.displayName;
            _addFix(DartFixKind.MAKE_FIELD_NOT_FINAL, [fieldName]);
          }
        }
      }
    }
  }

  void _addFix_nonBoolCondition_addNotNull() {
    _addInsertEdit(error.offset + error.length, ' != null');
    _addFix(DartFixKind.ADD_NE_NULL, []);
  }

  void _addFix_removeAwait() {
    final awaitExpression = node;
    if (awaitExpression is AwaitExpression) {
      final awaitToken = awaitExpression.awaitKeyword;
      _addRemoveEdit(range.startStart(awaitToken, awaitToken.next));
      _addFix(DartFixKind.REMOVE_AWAIT, []);
    }
  }

  void _addFix_removeDeadCode() {
    AstNode coveringNode = this.coveredNode;
    if (coveringNode is Expression) {
      AstNode parent = coveredNode.parent;
      if (parent is BinaryExpression) {
        if (parent.rightOperand == coveredNode) {
          _addRemoveEdit(range.endEnd(parent.leftOperand, coveredNode));
          _addFix(DartFixKind.REMOVE_DEAD_CODE, []);
        }
      }
    } else if (coveringNode is Block) {
      Block block = coveringNode;
      List<Statement> statementsToRemove = <Statement>[];
      for (Statement statement in block.statements) {
        if (range.node(statement).intersects(errorRange)) {
          statementsToRemove.add(statement);
        }
      }
      if (statementsToRemove.isNotEmpty) {
        SourceRange rangeToRemove =
            utils.getLinesRangeStatements(statementsToRemove);
        _addRemoveEdit(rangeToRemove);
        _addFix(DartFixKind.REMOVE_DEAD_CODE, []);
      }
    } else if (coveringNode is Statement) {
      SourceRange rangeToRemove =
          utils.getLinesRangeStatements(<Statement>[coveringNode]);
      _addRemoveEdit(rangeToRemove);
      _addFix(DartFixKind.REMOVE_DEAD_CODE, []);
    }
  }

  void _addFix_removeEmptyStatement() {
    EmptyStatement emptyStatement = node;
    if (emptyStatement.parent is Block) {
      _addRemoveEdit(utils.getLinesRange(range.node(emptyStatement)));
      _addFix(DartFixKind.REMOVE_EMPTY_STATEMENT, []);
    } else {
      _addReplaceEdit(
          range.endEnd(emptyStatement.beginToken.previous, emptyStatement),
          ' {}');
      _addFix(DartFixKind.REPLACE_WITH_BRACKETS, []);
    }
  }

  void _addFix_removeInitializer() {
    // Retrieve the linted node.
    VariableDeclaration ancestor =
        node.getAncestor((a) => a is VariableDeclaration);
    if (ancestor == null) {
      return;
    }
    _addRemoveEdit(range.endEnd(ancestor.name, ancestor.initializer));
    _addFix(DartFixKind.REMOVE_INITIALIZER, []);
  }

  void _addFix_removeMethodDeclaration() {
    MethodDeclaration declaration =
        node.getAncestor((node) => node is MethodDeclaration);
    if (declaration != null) {
      _addRemoveEdit(utils.getLinesRange(range.node(declaration)));
      _addFix(DartFixKind.REMOVE_METHOD_DECLARATION, []);
    }
  }

  void _addFix_removeParameters_inGetterDeclaration() {
    if (node is MethodDeclaration) {
      MethodDeclaration method = node as MethodDeclaration;
      SimpleIdentifier name = method.name;
      FunctionBody body = method.body;
      if (name != null && body != null) {
        _addReplaceEdit(range.endStart(name, body), ' ');
        _addFix(DartFixKind.REMOVE_PARAMETERS_IN_GETTER_DECLARATION, []);
      }
    }
  }

  void _addFix_removeParentheses_inGetterInvocation() {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      if (invocation.methodName == node && invocation.target != null) {
        _addRemoveEdit(range.endEnd(node, invocation));
        _addFix(DartFixKind.REMOVE_PARENTHESIS_IN_GETTER_INVOCATION, []);
      }
    }
  }

  void _addFix_removeThisExpression() {
    final thisExpression = node is ThisExpression
        ? node
        : node.getAncestor((node) => node is ThisExpression);
    final parent = thisExpression.parent;
    if (parent is PropertyAccess) {
      _addRemoveEdit(range.startEnd(parent, parent.operator));
      _addFix(DartFixKind.REMOVE_THIS_EXPRESSION, []);
    } else if (parent is MethodInvocation) {
      _addRemoveEdit(range.startEnd(parent, parent.operator));
      _addFix(DartFixKind.REMOVE_THIS_EXPRESSION, []);
    }
  }

  void _addFix_removeTypeName() {
    final TypeName type = node.getAncestor((node) => node is TypeName);
    if (type != null) {
      _addRemoveEdit(range.startStart(type, type.endToken.next));
      _addFix(DartFixKind.REMOVE_TYPE_NAME, []);
    }
  }

  void _addFix_removeUnnecessaryCast() {
    if (coveredNode is! AsExpression) {
      return;
    }
    AsExpression asExpression = coveredNode as AsExpression;
    Expression expression = asExpression.expression;
    int expressionPrecedence = getExpressionPrecedence(expression);
    // remove 'as T' from 'e as T'
    _addRemoveEdit(range.endEnd(expression, asExpression));
    _removeEnclosingParentheses(asExpression, expressionPrecedence);
    // done
    _addFix(DartFixKind.REMOVE_UNNECESSARY_CAST, []);
  }

  void _addFix_removeUnusedCatchClause() {
    if (node is SimpleIdentifier) {
      AstNode catchClause = node.parent;
      if (catchClause is CatchClause &&
          catchClause.exceptionParameter == node) {
        _addRemoveEdit(
            range.startStart(catchClause.catchKeyword, catchClause.body));
        _addFix(DartFixKind.REMOVE_UNUSED_CATCH_CLAUSE, []);
      }
    }
  }

  void _addFix_removeUnusedCatchStack() {
    if (node is SimpleIdentifier) {
      AstNode catchClause = node.parent;
      if (catchClause is CatchClause &&
          catchClause.stackTraceParameter == node &&
          catchClause.exceptionParameter != null) {
        _addRemoveEdit(range.endEnd(catchClause.exceptionParameter, node));
        _addFix(DartFixKind.REMOVE_UNUSED_CATCH_STACK, []);
      }
    }
  }

  void _addFix_removeUnusedImport() {
    // prepare ImportDirective
    ImportDirective importDirective =
        node.getAncestor((node) => node is ImportDirective);
    if (importDirective == null) {
      return;
    }
    // remove the whole line with import
    _addRemoveEdit(utils.getLinesRange(range.node(importDirective)));
    // done
    _addFix(DartFixKind.REMOVE_UNUSED_IMPORT, []);
  }

  void _addFix_replaceVarWithDynamic() {
    _addReplaceEdit(range.error(error), 'dynamic');
    _addFix(DartFixKind.REPLACE_VAR_WITH_DYNAMIC, []);
  }

  void _addFix_replaceWithConditionalAssignment() {
    IfStatement ifStatement = node is IfStatement
        ? node
        : node.getAncestor((node) => node is IfStatement);
    var thenStatement = ifStatement.thenStatement;
    Statement uniqueStatement(Statement statement) {
      if (statement is Block) {
        return uniqueStatement(statement.statements.first);
      }
      return statement;
    }

    thenStatement = uniqueStatement(thenStatement);
    if (thenStatement is ExpressionStatement) {
      final expression = thenStatement.expression.unParenthesized;
      if (expression is AssignmentExpression) {
        final buffer = new StringBuffer();
        buffer.write(utils.getNodeText(expression.leftHandSide));
        buffer.write(' ??= ');
        buffer.write(utils.getNodeText(expression.rightHandSide));
        buffer.write(';');
        _addReplaceEdit(range.node(ifStatement), buffer.toString());
        _addFix(DartFixKind.REPLACE_WITH_CONDITIONAL_ASSIGNMENT, []);
      }
    }
  }

  void _addFix_replaceWithConstInstanceCreation() {
    if (coveredNode is InstanceCreationExpression) {
      var instanceCreation = coveredNode as InstanceCreationExpression;
      _addReplaceEdit(range.token(instanceCreation.keyword), 'const');
      _addFix(DartFixKind.USE_CONST, []);
    }
  }

  void _addFix_replaceWithIdentifier() {
    final FunctionTypedFormalParameter functionTyped =
        node.getAncestor((node) => node is FunctionTypedFormalParameter);
    if (functionTyped != null) {
      _addReplaceEdit(range.node(functionTyped),
          utils.getNodeText(functionTyped.identifier));
      _addFix(DartFixKind.REPLACE_WITH_IDENTIFIER, []);
    } else {
      _addFix_removeTypeName();
    }
  }

  void _addFix_replaceWithLiteral() {
    final InstanceCreationExpression instanceCreation =
        node.getAncestor((node) => node is InstanceCreationExpression);
    final InterfaceType type = instanceCreation.staticType;
    final buffer = new StringBuffer();
    final generics = instanceCreation.constructorName.type.typeArguments;
    if (generics != null) {
      buffer.write(utils.getNodeText(generics));
    }
    if (type.name == 'List') {
      buffer.write('[]');
    } else {
      buffer.write('{}');
    }
    _addReplaceEdit(range.node(instanceCreation), buffer.toString());
    _addFix(DartFixKind.REPLACE_WITH_LITERAL, []);
  }

  void _addFix_replaceWithTearOff() {
    FunctionExpression ancestor =
        node.getAncestor((a) => a is FunctionExpression);
    if (ancestor == null) {
      return;
    }
    void addFixOfExpression(InvocationExpression expression) {
      final buffer = new StringBuffer();
      if (expression is MethodInvocation && expression.target != null) {
        buffer.write(utils.getNodeText(expression.target));
        buffer.write('.');
      }
      buffer.write(utils.getNodeText(expression.function));
      _addReplaceEdit(range.node(ancestor), buffer.toString());
      _addFix(DartFixKind.REPLACE_WITH_TEAR_OFF, []);
    }

    final body = ancestor.body;
    if (body is ExpressionFunctionBody) {
      final expression = body.expression;
      addFixOfExpression(expression.unParenthesized);
    } else if (body is BlockFunctionBody) {
      final statement = body.block.statements.first;
      if (statement is ExpressionStatement) {
        final expression = statement.expression;
        addFixOfExpression(expression.unParenthesized);
      } else if (statement is ReturnStatement) {
        final expression = statement.expression;
        addFixOfExpression(expression.unParenthesized);
      }
    }
  }

  void _addFix_undefinedClass_useSimilar() {
    AstNode node = this.node;
    // Prepare the optional import prefix name.
    String prefixName = null;
    if (node is SimpleIdentifier && node.staticElement is PrefixElement) {
      AstNode parent = node.parent;
      if (parent is PrefixedIdentifier &&
          parent.prefix == node &&
          parent.parent is TypeName) {
        prefixName = (node as SimpleIdentifier).name;
        node = parent.identifier;
      }
    }
    // Process if looks like a type.
    if (_mayBeTypeIdentifier(node)) {
      // Prepare for selecting the closest element.
      String name = (node as SimpleIdentifier).name;
      _ClosestElementFinder finder = new _ClosestElementFinder(
          name,
          (Element element) => element is ClassElement,
          MAX_LEVENSHTEIN_DISTANCE);
      // Check elements of this library.
      if (prefixName == null) {
        for (CompilationUnitElement unit in unitLibraryElement.units) {
          finder._updateList(unit.types);
        }
      }
      // Check elements from imports.
      for (ImportElement importElement in unitLibraryElement.imports) {
        if (importElement.prefix?.name == prefixName) {
          Map<String, Element> namespace = getImportNamespace(importElement);
          finder._updateList(namespace.values);
        }
      }
      // If we have a close enough element, suggest to use it.
      if (finder._element != null) {
        String closestName = finder._element.name;
        _addReplaceEdit(range.node(node), closestName);
        // Add proposal.
        if (closestName != null) {
          _addFix(DartFixKind.CHANGE_TO, [closestName]);
        }
      }
    }
  }

  void _addFix_undefinedClassAccessor_useSimilar() {
    AstNode node = this.node;
    if (node is SimpleIdentifier) {
      // prepare target
      Expression target = null;
      if (node.parent is PrefixedIdentifier) {
        PrefixedIdentifier invocation = node.parent as PrefixedIdentifier;
        target = invocation.prefix;
      }
      // find getter
      if (node.inGetterContext()) {
        _addFix_undefinedClassMember_useSimilar(target, (Element element) {
          return element is PropertyAccessorElement && element.isGetter ||
              element is FieldElement && element.getter != null;
        });
      }
      // find setter
      if (node.inSetterContext()) {
        _addFix_undefinedClassMember_useSimilar(target, (Element element) {
          return element is PropertyAccessorElement && element.isSetter ||
              element is FieldElement && element.setter != null;
        });
      }
    }
  }

  void _addFix_undefinedClassMember_useSimilar(
      Expression target, ElementPredicate predicate) {
    if (node is SimpleIdentifier) {
      String name = (node as SimpleIdentifier).name;
      _ClosestElementFinder finder =
          new _ClosestElementFinder(name, predicate, MAX_LEVENSHTEIN_DISTANCE);
      // unqualified invocation
      if (target == null) {
        ClassDeclaration clazz =
            node.getAncestor((node) => node is ClassDeclaration);
        if (clazz != null) {
          ClassElement classElement = clazz.element;
          _updateFinderWithClassMembers(finder, classElement);
        }
      } else {
        DartType type = target.bestType;
        if (type is InterfaceType) {
          ClassElement classElement = type.element;
          _updateFinderWithClassMembers(finder, classElement);
        }
      }
      // if we have close enough element, suggest to use it
      if (finder._element != null) {
        String closestName = finder._element.name;
        _addReplaceEdit(range.node(node), closestName);
        _addFix(DartFixKind.CHANGE_TO, [closestName]);
      }
    }
  }

  void _addFix_undefinedFunction_create() {
    // should be the name of the invocation
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {} else {
      return;
    }
    String name = (node as SimpleIdentifier).name;
    MethodInvocation invocation = node.parent as MethodInvocation;
    // function invocation has no target
    Expression target = invocation.realTarget;
    if (target != null) {
      return;
    }
    // prepare environment
    int insertOffset;
    String sourcePrefix;
    AstNode enclosingMember =
        node.getAncestor((node) => node is CompilationUnitMember);
    insertOffset = enclosingMember.end;
    sourcePrefix = '$eol$eol';
    utils.targetClassElement = null;
    // build method source
    SourceBuilder sb = new SourceBuilder(file, insertOffset);
    {
      sb.append(sourcePrefix);
      // append return type
      {
        DartType type = _inferUndefinedExpressionType(invocation);
        _appendType(sb, type, groupId: 'RETURN_TYPE');
      }
      // append name
      {
        sb.startPosition('NAME');
        sb.append(name);
        sb.endPosition();
      }
      _addFix_undefinedMethod_create_parameters(sb, invocation.argumentList);
      sb.append(') {$eol}');
    }
    // insert source
    _insertBuilder(sb, unitElement);
    _addLinkedPosition('NAME', sb, range.node(node));
    // add proposal
    _addFix(DartFixKind.CREATE_FUNCTION, [name]);
  }

  void _addFix_undefinedFunction_useSimilar() {
    AstNode node = this.node;
    if (node is SimpleIdentifier) {
      // Prepare the optional import prefix name.
      String prefixName = null;
      {
        AstNode invocation = node.parent;
        if (invocation is MethodInvocation && invocation.methodName == node) {
          Expression target = invocation.target;
          if (target is SimpleIdentifier &&
              target.staticElement is PrefixElement) {
            prefixName = target.name;
          }
        }
      }
      // Prepare for selecting the closest element.
      _ClosestElementFinder finder = new _ClosestElementFinder(
          node.name,
          (Element element) => element is FunctionElement,
          MAX_LEVENSHTEIN_DISTANCE);
      // Check to this library units.
      if (prefixName == null) {
        for (CompilationUnitElement unit in unitLibraryElement.units) {
          finder._updateList(unit.functions);
        }
      }
      // Check unprefixed imports.
      for (ImportElement importElement in unitLibraryElement.imports) {
        if (importElement.prefix?.name == prefixName) {
          Map<String, Element> namespace = getImportNamespace(importElement);
          finder._updateList(namespace.values);
        }
      }
      // If we have a close enough element, suggest to use it.
      if (finder._element != null) {
        String closestName = finder._element.name;
        _addReplaceEdit(range.node(node), closestName);
        _addFix(DartFixKind.CHANGE_TO, [closestName]);
      }
    }
  }

  void _addFix_undefinedMethod_create() {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      String name = (node as SimpleIdentifier).name;
      MethodInvocation invocation = node.parent as MethodInvocation;
      // prepare environment
      Element targetElement;
      bool staticModifier = false;

      ClassDeclaration targetClassNode;
      Expression target = invocation.realTarget;
      if (target == null) {
        targetElement = unitElement;
        ClassMember enclosingMember =
            node.getAncestor((node) => node is ClassMember);
        targetClassNode = enclosingMember.parent;
        utils.targetClassElement = targetClassNode.element;
        staticModifier = _inStaticContext();
      } else {
        // prepare target interface type
        DartType targetType = target.bestType;
        if (targetType is! InterfaceType) {
          return;
        }
        ClassElement targetClassElement = targetType.element as ClassElement;
        if (targetClassElement.librarySource.isInSystemLibrary) {
          return;
        }
        targetElement = targetClassElement;
        // prepare target ClassDeclaration
        AstNode targetTypeNode = getParsedClassElementNode(targetClassElement);
        if (targetTypeNode is! ClassDeclaration) {
          return;
        }
        targetClassNode = targetTypeNode;
        // maybe static
        if (target is Identifier) {
          staticModifier =
              resolutionMap.bestElementForIdentifier(target).kind ==
                  ElementKind.CLASS;
        }
        // use different utils
        CompilationUnitElement targetUnitElement =
            getCompilationUnitElement(targetClassElement);
        CompilationUnit targetUnit = getParsedUnit(targetUnitElement);
        utils = new CorrectionUtils(targetUnit);
      }
      ClassMemberLocation targetLocation =
          utils.prepareNewMethodLocation(targetClassNode);
      String targetFile = targetElement.source.fullName;
      // build method source
      SourceBuilder sb = new SourceBuilder(targetFile, targetLocation.offset);
      {
        sb.append(targetLocation.prefix);
        // maybe "static"
        if (staticModifier) {
          sb.append('static ');
        }
        // append return type
        {
          DartType type = _inferUndefinedExpressionType(invocation);
          _appendType(sb, type, groupId: 'RETURN_TYPE');
        }
        // append name
        {
          sb.startPosition('NAME');
          sb.append(name);
          sb.endPosition();
        }
        _addFix_undefinedMethod_create_parameters(sb, invocation.argumentList);
        sb.append(') {}');
        sb.append(targetLocation.suffix);
      }
      // insert source
      _insertBuilder(sb, targetElement);
      // add linked positions
      if (targetFile == file) {
        _addLinkedPosition('NAME', sb, range.node(node));
      }
      // add proposal
      _addFix(DartFixKind.CREATE_METHOD, [name]);
    }
  }

  void _addFix_undefinedMethod_create_parameters(
      SourceBuilder sb, ArgumentList argumentList) {
    Set<String> usedNames = new Set<String>();
    // append parameters
    sb.append('(');
    List<Expression> arguments = argumentList.arguments;
    bool hasNamedParameters = false;
    for (int i = 0; i < arguments.length; i++) {
      Expression argument = arguments[i];
      // append separator
      if (i != 0) {
        sb.append(', ');
      }
      // append parameter
      if (argument is NamedExpression && !hasNamedParameters) {
        hasNamedParameters = true;
        sb.append('{');
      }
      _appendParameterForArgument(sb, usedNames, i, argument);
    }
    if (hasNamedParameters) {
      sb.append('}');
    }
  }

  void _addFix_undefinedMethod_useSimilar() {
    if (node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      _addFix_undefinedClassMember_useSimilar(invocation.realTarget,
          (Element element) => element is MethodElement && !element.isOperator);
    }
  }

  /**
   * Here we handle cases when a constructors does not initialize all of the
   * final fields.
   */
  void _addFix_updateConstructor_forUninitializedFinalFields() {
    if (node is! SimpleIdentifier || node.parent is! ConstructorDeclaration) {
      return;
    }
    ConstructorDeclaration constructor = node.parent;
    // add these fields
    List<FieldElement> fields =
        ErrorVerifier.computeNotInitializedFields(constructor);
    // prepare new parameters code
    fields.sort((a, b) => a.nameOffset - b.nameOffset);
    String fieldParametersCode =
        fields.map((field) => 'this.${field.name}').join(', ');
    // prepare the last required parameter
    FormalParameter lastRequiredParameter;
    List<FormalParameter> parameters = constructor.parameters.parameters;
    for (FormalParameter parameter in parameters) {
      if (parameter.kind == ParameterKind.REQUIRED) {
        lastRequiredParameter = parameter;
      }
    }
    // append new field formal initializers
    if (lastRequiredParameter != null) {
      _addInsertEdit(lastRequiredParameter.end, ', $fieldParametersCode');
    } else {
      int offset = constructor.parameters.leftParenthesis.end;
      if (parameters.isNotEmpty) {
        fieldParametersCode += ', ';
      }
      _addInsertEdit(offset, fieldParametersCode);
    }
    // add proposal
    _addFix(DartFixKind.ADD_FIELD_FORMAL_PARAMETERS, []);
  }

  void _addFix_useEffectiveIntegerDivision() {
    for (AstNode n = node; n != null; n = n.parent) {
      if (n is MethodInvocation &&
          n.offset == errorOffset &&
          n.length == errorLength) {
        Expression target = n.target.unParenthesized;
        // replace "/" with "~/"
        BinaryExpression binary = target as BinaryExpression;
        _addReplaceEdit(range.token(binary.operator), '~/');
        // remove everything before and after
        _addRemoveEdit(range.startStart(n, binary.leftOperand));
        _addRemoveEdit(range.endEnd(binary.rightOperand, n));
        // add proposal
        _addFix(DartFixKind.USE_EFFECTIVE_INTEGER_DIVISION, []);
        // done
        break;
      }
    }
  }

  /**
   * Adds a fix that replaces [target] with a reference to the class declaring
   * the given [element].
   */
  void _addFix_useStaticAccess(AstNode target, Element element) {
    Element declaringElement = element.enclosingElement;
    if (declaringElement is ClassElement) {
      DartType declaringType = declaringElement.type;
      String declaringTypeCode =
          utils.getTypeSource(declaringType, librariesToImport);
      // replace "target" with class name
      _addReplaceEdit(range.node(target), declaringTypeCode);
      // add proposal
      _addFix(DartFixKind.CHANGE_TO_STATIC_ACCESS, [declaringType]);
    }
  }

  void _addFix_useStaticAccess_method() {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      if (invocation.methodName == node) {
        Expression target = invocation.target;
        Element invokedElement = invocation.methodName.bestElement;
        _addFix_useStaticAccess(target, invokedElement);
      }
    }
  }

  void _addFix_useStaticAccess_property() {
    if (node is SimpleIdentifier && node.parent is PrefixedIdentifier) {
      PrefixedIdentifier prefixed = node.parent as PrefixedIdentifier;
      if (prefixed.identifier == node) {
        Expression target = prefixed.prefix;
        Element invokedElement = prefixed.identifier.bestElement;
        _addFix_useStaticAccess(target, invokedElement);
      }
    }
  }

  /**
   * Adds a new [SourceEdit] to [change].
   */
  void _addInsertEdit(int offset, String text, [Element target]) {
    SourceEdit edit = new SourceEdit(offset, 0, text);
    _addEdit(target, edit);
  }

  /**
   * Adds a single linked position to [groupId].
   */
  void _addLinkedPosition(String groupId, SourceBuilder sb, SourceRange range) {
    // prepare offset
    int offset = range.offset;
    if (sb.offset <= offset) {
      int delta = sb.length;
      offset += delta;
    }
    // prepare group
    LinkedEditGroup group = _getLinkedPosition(groupId);
    // add position
    Position position = new Position(file, offset);
    group.addPosition(position, range.length);
  }

  void _addLintFixAddOverrideAnnotation() {
    ClassMember member = node.getAncestor((n) => n is ClassMember);
    if (member == null) {
      return;
    }

    //TODO(pq): migrate annotation edit building to change_builder

    // Handle doc comments.
    Token token = member.beginToken;
    if (token is CommentToken) {
      token = (token as CommentToken).parent;
    }

    exitPosition = new Position(file, token.offset - 1);
    String indent = utils.getIndent(1);
    _addReplaceEdit(range.startLength(token, 0), '@override$eol$indent');
    _addFix(DartFixKind.LINT_ADD_OVERRIDE, []);
  }

  void _addLintRemoveInterpolationBraces() {
    AstNode node = this.node;
    if (node is InterpolationExpression) {
      Token right = node.rightBracket;
      if (node.expression != null && right != null) {
        _addReplaceEdit(range.startStart(node, node.expression), r'$');
        _addRemoveEdit(range.token(right));
        _addFix(DartFixKind.LINT_REMOVE_INTERPOLATION_BRACES, []);
      }
    }
  }

  /**
   * Prepares proposal for creating function corresponding to the given
   * [FunctionType].
   */
  void _addProposal_createFunction(
      FunctionType functionType,
      String name,
      Source targetSource,
      int insertOffset,
      bool isStatic,
      String prefix,
      String sourcePrefix,
      String sourceSuffix,
      Element target) {
    // build method source
    String targetFile = targetSource.fullName;
    SourceBuilder sb = new SourceBuilder(targetFile, insertOffset);
    {
      sb.append(sourcePrefix);
      sb.append(prefix);
      // may be static
      if (isStatic) {
        sb.append('static ');
      }
      // append return type
      _appendType(sb, functionType.returnType, groupId: 'RETURN_TYPE');
      // append name
      {
        sb.startPosition('NAME');
        sb.append(name);
        sb.endPosition();
      }
      // append parameters
      sb.append('(');
      List<ParameterElement> parameters = functionType.parameters;
      for (int i = 0; i < parameters.length; i++) {
        ParameterElement parameter = parameters[i];
        // append separator
        if (i != 0) {
          sb.append(', ');
        }
        // append type name
        DartType type = parameter.type;
        if (!type.isDynamic) {
          String typeSource = utils.getTypeSource(type, librariesToImport);
          {
            sb.startPosition('TYPE$i');
            sb.append(typeSource);
            _addSuperTypeProposals(sb, type);
            sb.endPosition();
          }
          sb.append(' ');
        }
        // append parameter name
        {
          sb.startPosition('ARG$i');
          sb.append(parameter.displayName);
          sb.endPosition();
        }
      }
      sb.append(')');
      // close method
      sb.append(' {$eol$prefix}');
      sb.append(sourceSuffix);
    }
    // insert source
    _insertBuilder(sb, target);
    // add linked positions
    if (targetSource == unitSource) {
      _addLinkedPosition('NAME', sb, range.node(node));
    }
  }

  /**
   * Adds proposal for creating method corresponding to the given [FunctionType] in the given
   * [ClassElement].
   */
  void _addProposal_createFunction_function(FunctionType functionType) {
    String name = (node as SimpleIdentifier).name;
    // prepare environment
    int insertOffset = unit.end;
    // prepare prefix
    String prefix = '';
    String sourcePrefix = '$eol';
    String sourceSuffix = eol;
    _addProposal_createFunction(functionType, name, unitSource, insertOffset,
        false, prefix, sourcePrefix, sourceSuffix, unitElement);
    // add proposal
    _addFix(DartFixKind.CREATE_FUNCTION, [name]);
  }

  /**
   * Adds proposal for creating method corresponding to the given [FunctionType] in the given
   * [ClassElement].
   */
  void _addProposal_createFunction_method(
      ClassElement targetClassElement, FunctionType functionType) {
    String name = (node as SimpleIdentifier).name;
    // prepare environment
    Source targetSource = targetClassElement.source;
    // prepare insert offset
    ClassDeclaration targetClassNode =
        getParsedClassElementNode(targetClassElement);
    int insertOffset = targetClassNode.end - 1;
    // prepare prefix
    String prefix = '  ';
    String sourcePrefix;
    if (targetClassNode.members.isEmpty) {
      sourcePrefix = '';
    } else {
      sourcePrefix = eol;
    }
    String sourceSuffix = eol;
    _addProposal_createFunction(
        functionType,
        name,
        targetSource,
        insertOffset,
        _inStaticContext(),
        prefix,
        sourcePrefix,
        sourceSuffix,
        targetClassElement);
    // add proposal
    _addFix(DartFixKind.CREATE_METHOD, [name]);
  }

  /**
   * Adds a new [Edit] to [edits].
   */
  void _addRemoveEdit(SourceRange range) {
    _addReplaceEdit(range, '');
  }

  /**
   * Adds a new [SourceEdit] to [change].
   */
  void _addReplaceEdit(SourceRange range, String text, [Element target]) {
    SourceEdit edit = new SourceEdit(range.offset, range.length, text);
    _addEdit(target, edit);
  }

  void _appendParameterForArgument(
      SourceBuilder sb, Set<String> excluded, int index, Expression argument) {
    DartType type = argument.bestType;
    if (type == null || type.isBottom || type.isDartCoreNull) {
      type = DynamicTypeImpl.instance;
    }
    // append type name
    String typeSource = utils.getTypeSource(type, librariesToImport);
    if (typeSource != 'dynamic') {
      sb.startPosition('TYPE$index');
      sb.append(typeSource);
      _addSuperTypeProposals(sb, type);
      sb.endPosition();
      sb.append(' ');
    }
    // append parameter name
    if (argument is NamedExpression) {
      sb.append(argument.name.label.name);
    } else {
      List<String> suggestions =
          _getArgumentNameSuggestions(excluded, type, argument, index);
      String favorite = suggestions[0];
      excluded.add(favorite);
      sb.startPosition('ARG$index');
      sb.append(favorite);
      sb.addSuggestions(LinkedEditSuggestionKind.PARAMETER, suggestions);
      sb.endPosition();
    }
  }

  void _appendParameters(SourceBuilder sb, List<ParameterElement> parameters) {
    sb.append('(');
    bool firstParameter = true;
    bool sawNamed = false;
    bool sawPositional = false;
    for (ParameterElement parameter in parameters) {
      if (!firstParameter) {
        sb.append(', ');
      } else {
        firstParameter = false;
      }
      // may be optional
      ParameterKind parameterKind = parameter.parameterKind;
      if (parameterKind == ParameterKind.NAMED) {
        if (!sawNamed) {
          sb.append('{');
          sawNamed = true;
        }
      }
      if (parameterKind == ParameterKind.POSITIONAL) {
        if (!sawPositional) {
          sb.append('[');
          sawPositional = true;
        }
      }
      // parameter
      _appendParameterSource(sb, parameter.type, parameter.name);
      // default value
      String defaultCode = parameter.defaultValueCode;
      if (defaultCode != null) {
        if (sawPositional) {
          sb.append(' = ');
        } else {
          sb.append(': ');
        }
        sb.append(defaultCode);
      }
    }
    // close parameters
    if (sawNamed) {
      sb.append('}');
    }
    if (sawPositional) {
      sb.append(']');
    }
    sb.append(')');
  }

  void _appendParameterSource(SourceBuilder sb, DartType type, String name) {
    String parameterSource =
        utils.getParameterSource(type, name, librariesToImport);
    sb.append(parameterSource);
  }

  void _appendType(SourceBuilder sb, DartType type,
      {String groupId, bool orVar: false, bool trailingSpace: true}) {
    if (type != null && !type.isDynamic) {
      String typeSource = utils.getTypeSource(type, librariesToImport);
      if (groupId != null) {
        sb.startPosition(groupId);
        sb.append(typeSource);
        sb.endPosition();
      } else {
        sb.append(typeSource);
      }
      if (trailingSpace) {
        sb.append(' ');
      }
    } else if (orVar) {
      sb.append('var ');
    }
  }

  void _appendTypeParameter(
      SourceBuilder sb, TypeParameterElement typeParameter) {
    sb.append(typeParameter.name);
    if (typeParameter.bound != null) {
      sb.append(' extends ');
      _appendType(sb, typeParameter.bound, trailingSpace: false);
    }
  }

  void _appendTypeParameters(
      SourceBuilder sb, List<TypeParameterElement> typeParameters) {
    if (typeParameters.isNotEmpty) {
      sb.append('<');
      bool isFirst = true;
      for (TypeParameterElement typeParameter in typeParameters) {
        if (!isFirst) {
          sb.append(', ');
        }
        isFirst = false;
        _appendTypeParameter(sb, typeParameter);
      }
      sb.append('>');
    }
  }

  /**
   * Computes the name of the library at the given [path].
   * See https://www.dartlang.org/articles/style-guide/#names for conventions.
   */
  String _computeLibraryName(String path) {
    Context pathContext = resourceProvider.pathContext;
    String packageFolder = _computePackageFolder(path);
    if (packageFolder == null) {
      return pathContext.basenameWithoutExtension(path);
    }
    String packageName = pathContext.basename(packageFolder);
    String relPath = pathContext.relative(path, from: packageFolder);
    List<String> relPathParts = pathContext.split(relPath);
    if (relPathParts.isNotEmpty) {
      if (relPathParts[0].toLowerCase() == 'lib') {
        relPathParts.removeAt(0);
      }
      if (relPathParts.isNotEmpty) {
        String nameWithoutExt = pathContext.withoutExtension(relPathParts.last);
        relPathParts[relPathParts.length - 1] = nameWithoutExt;
      }
    }
    return packageName + '.' + relPathParts.join('.');
  }

  /**
   * Returns the path of the folder which contains the given [path].
   */
  String _computePackageFolder(String path) {
    Context pathContext = resourceProvider.pathContext;
    String pubspecFolder = dirname(path);
    while (true) {
      if (resourceProvider
          .getResource(pathContext.join(pubspecFolder, 'pubspec.yaml'))
          .exists) {
        return pubspecFolder;
      }
      String pubspecFolderNew = pathContext.dirname(pubspecFolder);
      if (pubspecFolderNew == pubspecFolder) {
        return null;
      }
      pubspecFolder = pubspecFolderNew;
    }
  }

  /**
   * @return the string to display as the name of the given constructor in a proposal name.
   */
  String _getConstructorProposalName(ConstructorElement constructor) {
    SourceBuilder proposalNameBuffer = new SourceBuilder.buffer();
    proposalNameBuffer.append('super');
    // may be named
    String constructorName = constructor.displayName;
    if (!constructorName.isEmpty) {
      proposalNameBuffer.append('.');
      proposalNameBuffer.append(constructorName);
    }
    // parameters
    _appendParameters(proposalNameBuffer, constructor.parameters);
    // done
    return proposalNameBuffer.toString();
  }

  /**
   * Returns the [DartType] with given name from the `dart:core` library.
   */
  DartType _getCoreType(String name) {
    List<LibraryElement> libraries = unitLibraryElement.importedLibraries;
    for (LibraryElement library in libraries) {
      if (library.isDartCore) {
        ClassElement classElement = library.getType(name);
        if (classElement != null) {
          return classElement.type;
        }
        return null;
      }
    }
    return null;
  }

  /**
   * Returns an existing or just added [LinkedEditGroup] with [groupId].
   */
  LinkedEditGroup _getLinkedPosition(String groupId) {
    LinkedEditGroup group = linkedPositionGroups[groupId];
    if (group == null) {
      group = new LinkedEditGroup.empty();
      linkedPositionGroups[groupId] = group;
    }
    return group;
  }

  /**
   * Returns an expected [DartType] of [expression], may be `null` if cannot be
   * inferred.
   */
  DartType _inferUndefinedExpressionType(Expression expression) {
    AstNode parent = expression.parent;
    // myFunction();
    if (parent is ExpressionStatement) {
      if (expression is MethodInvocation) {
        return VoidTypeImpl.instance;
      }
    }
    // return myFunction();
    if (parent is ReturnStatement) {
      ExecutableElement executable = getEnclosingExecutableElement(expression);
      return executable?.returnType;
    }
    // int v = myFunction();
    if (parent is VariableDeclaration) {
      VariableDeclaration variableDeclaration = parent;
      if (variableDeclaration.initializer == expression) {
        VariableElement variableElement = variableDeclaration.element;
        if (variableElement != null) {
          return variableElement.type;
        }
      }
    }
    // myField = 42;
    if (parent is AssignmentExpression) {
      AssignmentExpression assignment = parent;
      if (assignment.leftHandSide == expression) {
        Expression rhs = assignment.rightHandSide;
        if (rhs != null) {
          return rhs.bestType;
        }
      }
    }
    // v = myFunction();
    if (parent is AssignmentExpression) {
      AssignmentExpression assignment = parent;
      if (assignment.rightHandSide == expression) {
        if (assignment.operator.type == TokenType.EQ) {
          // v = myFunction();
          Expression lhs = assignment.leftHandSide;
          if (lhs != null) {
            return lhs.bestType;
          }
        } else {
          // v += myFunction();
          MethodElement method = assignment.bestElement;
          if (method != null) {
            List<ParameterElement> parameters = method.parameters;
            if (parameters.length == 1) {
              return parameters[0].type;
            }
          }
        }
      }
    }
    // v + myFunction();
    if (parent is BinaryExpression) {
      BinaryExpression binary = parent;
      MethodElement method = binary.bestElement;
      if (method != null) {
        if (binary.rightOperand == expression) {
          List<ParameterElement> parameters = method.parameters;
          return parameters.length == 1 ? parameters[0].type : null;
        }
      }
    }
    // foo( myFunction() );
    if (parent is ArgumentList) {
      ParameterElement parameter = expression.bestParameterElement;
      return parameter?.type;
    }
    // bool
    {
      // assert( myFunction() );
      if (parent is AssertStatement) {
        AssertStatement statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // if ( myFunction() ) {}
      if (parent is IfStatement) {
        IfStatement statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // while ( myFunction() ) {}
      if (parent is WhileStatement) {
        WhileStatement statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // do {} while ( myFunction() );
      if (parent is DoStatement) {
        DoStatement statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // !myFunction()
      if (parent is PrefixExpression) {
        PrefixExpression prefixExpression = parent;
        if (prefixExpression.operator.type == TokenType.BANG) {
          return coreTypeBool;
        }
      }
      // binary expression '&&' or '||'
      if (parent is BinaryExpression) {
        BinaryExpression binaryExpression = parent;
        TokenType operatorType = binaryExpression.operator.type;
        if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
            operatorType == TokenType.BAR_BAR) {
          return coreTypeBool;
        }
      }
    }
    // we don't know
    return null;
  }

  /**
   * Inserts the given [SourceBuilder] at its offset.
   */
  void _insertBuilder(SourceBuilder builder, Element target) {
    String text = builder.toString();
    _addInsertEdit(builder.offset, text, target);
    // add linked positions
    builder.linkedPositionGroups.forEach((String id, LinkedEditGroup group) {
      LinkedEditGroup fixGroup = _getLinkedPosition(id);
      group.positions.forEach((Position position) {
        fixGroup.addPosition(position, group.length);
      });
      group.suggestions.forEach((LinkedEditSuggestion suggestion) {
        fixGroup.addSuggestion(suggestion);
      });
    });
  }

  /**
   * Returns `true` if [node] is in static context.
   */
  bool _inStaticContext() {
    // constructor initializer cannot reference "this"
    if (node.getAncestor((node) => node is ConstructorInitializer) != null) {
      return true;
    }
    // field initializer cannot reference "this"
    if (node.getAncestor((node) => node is FieldDeclaration) != null) {
      return true;
    }
    // static method
    MethodDeclaration method = node.getAncestor((node) {
      return node is MethodDeclaration;
    });
    return method != null && method.isStatic;
  }

  bool _isAwaitNode() {
    AstNode node = this.node;
    return node is SimpleIdentifier && node.name == 'await';
  }

  bool _isLibSrcPath(String path) {
    List<String> parts = resourceProvider.pathContext.split(path);
    for (int i = 0; i < parts.length - 2; i++) {
      if (parts[i] == 'lib' && parts[i + 1] == 'src') {
        return true;
      }
    }
    return false;
  }

  /**
   * Return `true` if the [source] can be imported into [unitLibraryFile].
   */
  bool _isSourceVisibleToLibrary(Source source) {
    if (!source.uri.isScheme('file')) {
      return true;
    }

    // Prepare the root of our package.
    Folder packageRoot;
    for (Folder folder = unitLibraryFolder;
        folder != null;
        folder = folder.parent) {
      if (folder.getChildAssumingFile('pubspec.yaml').exists ||
          folder.getChildAssumingFile('BUILD').exists) {
        packageRoot = folder;
        break;
      }
    }

    // This should be rare / never situation.
    if (packageRoot == null) {
      return true;
    }

    // We cannot use relative URIs to reference files outside of our package.
    return resourceProvider.pathContext
        .isWithin(packageRoot.path, source.fullName);
  }

  int _modificationStamp(String filePath) {
    // TODO(brianwilkerson) We have lost the ability for clients to know whether
    // it is safe to apply an edit.
    return driver.fsState.getFileForPath(filePath).exists ? 0 : -1;
  }

  /**
   * Removes any [ParenthesizedExpression] enclosing [expr].
   *
   * [exprPrecedence] - the effective precedence of [expr].
   */
  void _removeEnclosingParentheses(Expression expr, int exprPrecedence) {
    while (expr.parent is ParenthesizedExpression) {
      ParenthesizedExpression parenthesized =
          expr.parent as ParenthesizedExpression;
      if (getExpressionParentPrecedence(parenthesized) > exprPrecedence) {
        break;
      }
      _addRemoveEdit(range.token(parenthesized.leftParenthesis));
      _addRemoveEdit(range.token(parenthesized.rightParenthesis));
      expr = parenthesized;
    }
  }

  void _replaceReturnTypeWithFuture(AstNode node, TypeProvider typeProvider) {
    for (; node != null; node = node.parent) {
      if (node is FunctionDeclaration) {
        _replaceTypeWithFuture(node.returnType, typeProvider);
        return;
      } else if (node is MethodDeclaration) {
        _replaceTypeWithFuture(node.returnType, typeProvider);
        return;
      }
    }
  }

  void _replaceTypeWithFuture(
      TypeAnnotation typeName, TypeProvider typeProvider) {
    InterfaceType futureType = typeProvider.futureType;
    // validate the type
    DartType type = typeName?.type;
    if (type == null ||
        type.isDynamic ||
        type is InterfaceType && type.element == futureType.element) {
      return;
    }
    // prepare code for the types
    String futureTypeCode = utils.getTypeSource(futureType, librariesToImport);
    String nodeCode = utils.getNodeText(typeName);
    // wrap the existing type with Future
    String returnTypeCode;
    if (nodeCode == 'void') {
      returnTypeCode = futureTypeCode;
    } else {
      returnTypeCode = '$futureTypeCode<$nodeCode>';
    }
    _addReplaceEdit(range.node(typeName), returnTypeCode);
  }

  void _updateFinderWithClassMembers(
      _ClosestElementFinder finder, ClassElement clazz) {
    if (clazz != null) {
      List<Element> members = getMembers(clazz);
      finder._updateList(members);
    }
  }

  static void _addSuperTypeProposals(SourceBuilder sb, DartType type,
      [Set<DartType> alreadyAdded]) {
    alreadyAdded ??= new Set<DartType>();
    if (type is InterfaceType && alreadyAdded.add(type)) {
      sb.addSuggestion(LinkedEditSuggestionKind.TYPE, type.displayName);
      _addSuperTypeProposals(sb, type.superclass, alreadyAdded);
      for (InterfaceType interfaceType in type.interfaces) {
        _addSuperTypeProposals(sb, interfaceType, alreadyAdded);
      }
    }
  }

  /**
   * @return the suggestions for given [Type] and [DartExpression], not empty.
   */
  static List<String> _getArgumentNameSuggestions(
      Set<String> excluded, DartType type, Expression expression, int index) {
    List<String> suggestions =
        getVariableNameSuggestionsForExpression(type, expression, excluded);
    if (suggestions.length != 0) {
      return suggestions;
    }
    return <String>['arg$index'];
  }

  static bool _isNameOfType(String name) {
    if (name.isEmpty) {
      return false;
    }
    String firstLetter = name.substring(0, 1);
    if (firstLetter.toUpperCase() != firstLetter) {
      return false;
    }
    return true;
  }

  /**
   * Returns `true` if [node] is a type name.
   */
  static bool _mayBeTypeIdentifier(AstNode node) {
    if (node is SimpleIdentifier) {
      AstNode parent = node.parent;
      if (parent is TypeName) {
        return true;
      }
      return _isNameOfType(node.name);
    }
    return false;
  }
}

/**
 * An enumeration of lint names.
 */
class LintNames {
  static const String annotate_overrides = 'annotate_overrides';
  static const String avoid_annotating_with_dynamic =
      'avoid_annotating_with_dynamic';
  static const String avoid_init_to_null = 'avoid_init_to_null';
  static const String avoid_return_types_on_setters =
      'avoid_return_types_on_setters';
  static const String avoid_types_on_closure_parameters =
      'avoid_types_on_closure_parameters';
  static const String await_only_futures = 'await_only_futures';
  static const String empty_statements = 'empty_statements';
  static const String prefer_collection_literals = 'prefer_collection_literals';
  static const String prefer_conditional_assignment =
      'prefer_conditional_assignment';
  static const String unnecessary_brace_in_string_interp =
      'unnecessary_brace_in_string_interp';
  static const String unnecessary_lambdas = 'unnecessary_lambdas';
  static const String unnecessary_override = 'unnecessary_override';
  static const String unnecessary_this = 'unnecessary_this';
}

/**
 * Helper for finding [Element] with name closest to the given.
 */
class _ClosestElementFinder {
  final String _targetName;
  final ElementPredicate _predicate;

  Element _element = null;
  int _distance;

  _ClosestElementFinder(this._targetName, this._predicate, this._distance);

  void _update(Element element) {
    if (_predicate(element)) {
      int memberDistance = levenshtein(element.name, _targetName, _distance);
      if (memberDistance < _distance) {
        _element = element;
        _distance = memberDistance;
      }
    }
  }

  void _updateList(Iterable<Element> elements) {
    for (Element element in elements) {
      _update(element);
    }
  }
}
