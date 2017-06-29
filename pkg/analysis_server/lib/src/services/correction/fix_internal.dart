// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/flutter_util.dart';
import 'package:analysis_server/src/services/correction/levenshtein.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
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
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart' hide FixContributor;
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
  CompilationUnitElement unitElement;
  Source unitSource;
  LibraryElement unitLibraryElement;
  File unitLibraryFile;
  Folder unitLibraryFolder;

  final List<Fix> fixes = <Fix>[];

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
      await _addFix_boolInsteadOfBoolean();
    }
    if (errorCode ==
        CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE) {
      await _addFix_replaceWithConstInstanceCreation();
    }
    if (errorCode == CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT ||
        errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT) {
      await _addFix_addAsync();
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
            await _addFix_createClass();
            await _addFix_undefinedClass_useSimilar();
          }
        }
      }
    }
    if (errorCode ==
        CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT) {
      await _addFix_createConstructorSuperExplicit();
    }
    if (errorCode ==
        CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT) {
      await _addFix_createConstructorSuperImplicit();
    }
    if (errorCode ==
        CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT) {
      await _addFix_createConstructorSuperExplicit();
    }
    if (errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST) {
      await _addFix_createImportUri();
      await _addFix_createPartUri();
    }
    if (errorCode == HintCode.CAN_BE_NULL_AFTER_NULL_AWARE) {
      await _addFix_canBeNullAfterNullAware();
    }
    if (errorCode == HintCode.DEAD_CODE) {
      await _addFix_removeDeadCode();
    }
    if (errorCode == HintCode.DIVISION_OPTIMIZATION) {
      await _addFix_useEffectiveIntegerDivision();
    }
    if (errorCode == HintCode.TYPE_CHECK_IS_NOT_NULL) {
      await _addFix_isNotNull();
    }
    if (errorCode == HintCode.TYPE_CHECK_IS_NULL) {
      await _addFix_isNull();
    }
    if (errorCode == HintCode.UNDEFINED_GETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createField();
      await _addFix_createGetter();
    }
    if (errorCode == HintCode.UNDEFINED_SETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createField();
    }
    if (errorCode == HintCode.UNNECESSARY_CAST) {
      await _addFix_removeUnnecessaryCast();
    }
    if (errorCode == HintCode.UNUSED_CATCH_CLAUSE) {
      await _addFix_removeUnusedCatchClause();
    }
    if (errorCode == HintCode.UNUSED_CATCH_STACK) {
      await _addFix_removeUnusedCatchStack();
    }
    if (errorCode == HintCode.UNUSED_IMPORT) {
      await _addFix_removeUnusedImport();
    }
    if (errorCode == ParserErrorCode.EXPECTED_TOKEN) {
      await _addFix_insertSemicolon();
    }
    if (errorCode == ParserErrorCode.GETTER_WITH_PARAMETERS) {
      await _addFix_removeParameters_inGetterDeclaration();
    }
    if (errorCode == ParserErrorCode.VAR_AS_TYPE_NAME) {
      await _addFix_replaceVarWithDynamic();
    }
    if (errorCode == StaticWarningCode.ASSIGNMENT_TO_FINAL) {
      await _addFix_makeFieldNotFinal();
    }
    if (errorCode == StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER) {
      await _addFix_makeEnclosingClassAbstract();
    }
    if (errorCode == StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS ||
        errorCode ==
            StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED) {
      await _addFix_createConstructor_insteadOfSyntheticDefault();
      await _addFix_addMissingParameter();
    }
    if (errorCode == HintCode.MISSING_REQUIRED_PARAM ||
        errorCode == HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS) {
      await _addFix_addMissingRequiredArgument();
    }
    if (errorCode == StaticWarningCode.FUNCTION_WITHOUT_CALL) {
      await _addFix_addMissingMethodCall();
    }
    if (errorCode == StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR) {
      await _addFix_createConstructor_named();
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
      await _addFix_makeEnclosingClassAbstract();
      await _addFix_createNoSuchMethod();
      // implement methods
      await _addFix_createMissingOverrides();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_CLASS ||
        errorCode == StaticWarningCode.CAST_TO_NON_TYPE ||
        errorCode == StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME ||
        errorCode == StaticWarningCode.UNDEFINED_CLASS) {
      await _addFix_importLibrary_withType();
      await _addFix_createClass();
      await _addFix_undefinedClass_useSimilar();
    }
    if (errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED) {
      await _addFix_createConstructor_forUninitializedFinalFields();
    }
    if (errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1 ||
        errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2 ||
        errorCode ==
            StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS) {
      await _addFix_updateConstructor_forUninitializedFinalFields();
    }
    if (errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createClass();
      await _addFix_createField();
      await _addFix_createGetter();
      await _addFix_createFunction_forFunctionType();
      await _addFix_importLibrary_withType();
      await _addFix_importLibrary_withTopLevelVariable();
      await _addFix_createLocalVariable();
    }
    if (errorCode == StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE) {
      await _addFix_illegalAsyncReturnType();
    }
    if (errorCode == StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER) {
      await _addFix_useStaticAccess_method();
      await _addFix_useStaticAccess_property();
    }
    if (errorCode == StaticTypeWarningCode.INVALID_ASSIGNMENT) {
      await _addFix_changeTypeAnnotation();
    }
    if (errorCode == StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION) {
      await _addFix_removeParentheses_inGetterInvocation();
    }
    if (errorCode == StaticTypeWarningCode.NON_BOOL_CONDITION) {
      await _addFix_nonBoolCondition_addNotNull();
    }
    if (errorCode == StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT) {
      await _addFix_importLibrary_withType();
      await _addFix_createClass();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_FUNCTION) {
      await _addFix_importLibrary_withFunction();
      await _addFix_undefinedFunction_useSimilar();
      await _addFix_undefinedFunction_create();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_GETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createField();
      await _addFix_createGetter();
      await _addFix_createFunction_forFunctionType();
    }
    if (errorCode == HintCode.UNDEFINED_METHOD ||
        errorCode == StaticTypeWarningCode.UNDEFINED_METHOD) {
      await _addFix_importLibrary_withFunction();
      await _addFix_undefinedMethod_useSimilar();
      await _addFix_undefinedMethod_create();
      await _addFix_undefinedFunction_create();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_SETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createField();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER ||
        errorCode == StaticWarningCode.UNDEFINED_NAMED_PARAMETER) {
      await _addFix_convertFlutterChild();
      await _addFix_convertFlutterChildren();
    }
    if (errorCode ==
        CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD) {
      await _addFix_createField_initializingFormal();
    }
    // lints
    if (errorCode is LintCode) {
      if (errorCode.name == LintNames.annotate_overrides) {
        await _addFix_addOverrideAnnotation();
      }
      if (errorCode.name == LintNames.avoid_annotating_with_dynamic) {
        await _addFix_removeTypeName();
      }
      if (errorCode.name == LintNames.avoid_init_to_null) {
        await _addFix_removeInitializer();
      }
      if (errorCode.name == LintNames.avoid_return_types_on_setters) {
        await _addFix_removeTypeName();
      }
      if (errorCode.name == LintNames.avoid_types_on_closure_parameters) {
        await _addFix_replaceWithIdentifier();
      }
      if (errorCode.name == LintNames.await_only_futures) {
        await _addFix_removeAwait();
      }
      if (errorCode.name == LintNames.empty_statements) {
        await _addFix_removeEmptyStatement();
      }
      if (errorCode.name == LintNames.prefer_collection_literals) {
        await _addFix_replaceWithLiteral();
      }
      if (errorCode.name == LintNames.prefer_conditional_assignment) {
        await _addFix_replaceWithConditionalAssignment();
      }
      if (errorCode.name == LintNames.unnecessary_brace_in_string_interp) {
        await _addFix_removeInterpolationBraces();
      }
      if (errorCode.name == LintNames.unnecessary_lambdas) {
        await _addFix_replaceWithTearOff();
      }
      if (errorCode.name == LintNames.unnecessary_override) {
        await _addFix_removeMethodDeclaration();
      }
      if (errorCode.name == LintNames.unnecessary_this) {
        await _addFix_removeThisExpression();
      }
    }
    // done
    return fixes;
  }

  /**
   * Returns `true` if the `async` proposal was added.
   */
  Future<Null> _addFix_addAsync() async {
    FunctionBody body = node.getAncestor((n) => n is FunctionBody);
    if (body != null && body.keyword == null) {
      TypeProvider typeProvider = await this.typeProvider;
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.convertFunctionFromSyncToAsync(body, typeProvider);
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.ADD_ASYNC);
    }
  }

  Future<Null> _addFix_addMissingMethodCall() async {
    ClassDeclaration targetClass = node.parent as ClassDeclaration;
    int insertOffset = targetClass.end - 1;
    // prepare environment
    String prefix = utils.getIndent(1);
    String prefix2 = utils.getIndent(2);
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(insertOffset, (DartEditBuilder builder) {
        builder.selectHere();
        builder.write(prefix);
        builder.write('call() {');
        // TO-DO
        builder.write(eol);
        builder.write(prefix2);
        builder.write('// TODO: implement call');
        builder.write(eol);
        // close method
        builder.write(prefix);
        builder.write('}');
        builder.write(eol);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_MISSING_METHOD_CALL);
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
        Source targetSource = targetElement.source;
        String targetFile = targetSource.fullName;
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(targetFile,
            (DartFileEditBuilder builder) {
          builder.addInsertion(targetOffset, (DartEditBuilder builder) {
            if (numRequired != 0) {
              builder.write(', ');
            }
            builder.writeParameterMatchingArgument(
                argument, numRequired, new Set<String>());
            if (numRequired != numParameters) {
              builder.write(', ');
            }
          });
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.ADD_MISSING_PARAMETER_REQUIRED);
        if (optionalParameters.isEmpty) {
          DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
          await changeBuilder.addFileEdit(targetFile,
              (DartFileEditBuilder builder) {
            builder.addInsertion(targetOffset, (DartEditBuilder builder) {
              if (numRequired != 0) {
                builder.write(', ');
              }
              builder.write('[');
              builder.writeParameterMatchingArgument(
                  argument, numRequired, new Set<String>());
              builder.write(']');
            });
          });
          _addFixFromBuilder(
              changeBuilder, DartFixKind.ADD_MISSING_PARAMETER_POSITIONAL);
        }
      }
    }
  }

  Future<Null> _addFix_addMissingRequiredArgument() async {
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

      // add proposal
      String paramName = parts[1];
      final List<Expression> args = argumentList.arguments;
      int offset =
          args.isEmpty ? argumentList.leftParenthesis.end : args.last.end;
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(offset, (DartEditBuilder builder) {
          if (args.isNotEmpty) {
            builder.write(', ');
          }
          List<ParameterElement> parameters =
              (targetElement as ExecutableElement).parameters;
          ParameterElement element = parameters
              .firstWhere((p) => p.name == paramName, orElse: () => null);
          String defaultValue = getDefaultStringParameterValue(element);
          builder.write('$paramName: $defaultValue');
          // Insert a trailing comma after Flutter instance creation params.
          InstanceCreationExpression newExpr = identifyNewExpression(node);
          if (newExpr != null && isFlutterInstanceCreationExpression(newExpr)) {
            builder.write(',');
          }
        });
      });
      _addFixFromBuilder(
          changeBuilder, DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
          args: [paramName]);
    }
  }

  Future<Null> _addFix_addOverrideAnnotation() async {
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

    Position exitPosition = new Position(file, token.offset - 1);
    String indent = utils.getIndent(1);
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
          range.startLength(token, 0), '@override$eol$indent');
    });
    changeBuilder.setSelection(exitPosition);
    _addFixFromBuilder(changeBuilder, DartFixKind.LINT_ADD_OVERRIDE);
  }

  Future<Null> _addFix_boolInsteadOfBoolean() async {
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.error(error), 'bool');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_BOOLEAN_WITH_BOOL);
  }

  Future<Null> _addFix_canBeNullAfterNullAware() async {
    AstNode node = coveredNode;
    if (node is Expression) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        AstNode parent = node.parent;
        while (parent != null) {
          if (parent is MethodInvocation && parent.target == node) {
            builder.addSimpleReplacement(range.token(parent.operator), '?.');
          } else if (parent is PropertyAccess && parent.target == node) {
            builder.addSimpleReplacement(range.token(parent.operator), '?.');
          } else {
            break;
          }
          node = parent;
          parent = node.parent;
        }
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_NULL_AWARE);
    }
  }

  Future<Null> _addFix_changeTypeAnnotation() async {
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
            DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
            await changeBuilder.addFileEdit(file,
                (DartFileEditBuilder builder) {
              builder.addReplacement(range.node(typeNode),
                  (DartEditBuilder builder) {
                builder.writeType(newType);
              });
            });
            _addFixFromBuilder(
                changeBuilder, DartFixKind.CHANGE_TYPE_ANNOTATION, args: [
              resolutionMap.typeForTypeName(typeNode),
              newType.displayName
            ]);
          }
        }
      }
    }
  }

  Future<Null> _addFix_convertFlutterChild() async {
    NamedExpression namedExp = findFlutterNamedExpression(node, 'child');
    if (namedExp == null) {
      return;
    }
    InstanceCreationExpression childArg = getChildWidget(namedExp, false);
    if (childArg != null) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        convertFlutterChildToChildren2(
            builder,
            childArg,
            namedExp,
            eol,
            utils.getNodeText,
            utils.getLinePrefix,
            utils.getIndent,
            utils.getText,
            range.node);
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_FLUTTER_CHILD);
      return;
    }
    ListLiteral listArg = getChildList(namedExp);
    if (listArg != null) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleInsertion(namedExp.offset + 'child'.length, 'ren');
        if (listArg.typeArguments == null) {
          builder.addSimpleInsertion(listArg.offset, '<Widget>');
        }
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_FLUTTER_CHILD);
    }
  }

  Future<Null> _addFix_convertFlutterChildren() async {
    // TODO(messick) Implement _addFix_convertFlutterChildren()
  }

  Future<Null> _addFix_createClass() async {
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
    String prefix = '';
    String suffix = '';
    int offset = -1;
    String filePath;
    if (prefixElement == null) {
      targetUnit = unitElement;
      CompilationUnitMember enclosingMember =
          node.getAncestor((node) => node.parent is CompilationUnit);
      if (enclosingMember == null) {
        return;
      }
      offset = enclosingMember.end;
      filePath = file;
      prefix = '$eol$eol';
    } else {
      for (ImportElement import in unitLibraryElement.imports) {
        if (prefixElement is PrefixElement && import.prefix == prefixElement) {
          LibraryElement library = import.importedLibrary;
          if (library != null) {
            targetUnit = library.definingCompilationUnit;
            Source targetSource = targetUnit.source;
            offset = targetSource.contents.data.length;
            filePath = targetSource.fullName;
            prefix = '$eol';
            suffix = '$eol';
            break;
          }
        }
      }
    }
    if (offset < 0) {
      return;
    }
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(filePath, (DartFileEditBuilder builder) {
      builder.addInsertion(offset, (DartEditBuilder builder) {
        builder.write(prefix);
        builder.writeClassDeclaration(name, nameGroupName: 'NAME');
        builder.write(suffix);
      });
      if (prefixElement == null) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_CLASS, args: [name]);
  }

  /**
   * Here we handle cases when there are no constructors in a class, and the
   * class has uninitialized final fields.
   */
  Future<Null> _addFix_createConstructor_forUninitializedFinalFields() async {
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
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        builder.write(targetLocation.prefix);
        builder.writeConstructorDeclaration(classDeclaration.name.name,
            fieldNames: fieldNames);
        builder.write(targetLocation.suffix);
      });
    });
    _addFixFromBuilder(
        changeBuilder, DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS);
  }

  Future<Null> _addFix_createConstructor_insteadOfSyntheticDefault() async {
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
    Source targetSource = targetElement.source;
    String targetFile = targetSource.fullName;
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        builder.write(targetLocation.prefix);
        builder.writeConstructorDeclaration(targetElement.name,
            argumentList: instanceCreation.argumentList);
        builder.write(targetLocation.suffix);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_CONSTRUCTOR,
        args: [constructorName]);
  }

  Future<Null> _addFix_createConstructor_named() async {
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
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        builder.write(targetLocation.prefix);
        builder.writeConstructorDeclaration(targetElement.name,
            argumentList: instanceCreation.argumentList,
            constructorName: name,
            constructorNameGroupName: 'NAME');
        builder.write(targetLocation.suffix);
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.node(name), 'NAME');
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_CONSTRUCTOR,
        args: [constructorName]);
  }

  Future<Null> _addFix_createConstructorSuperExplicit() async {
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
      List<ConstructorInitializer> initializers =
          targetConstructor.initializers;
      int insertOffset;
      String prefix;
      if (initializers.isEmpty) {
        insertOffset = targetConstructor.parameters.end;
        prefix = ' : ';
      } else {
        ConstructorInitializer lastInitializer =
            initializers[initializers.length - 1];
        insertOffset = lastInitializer.end;
        prefix = ', ';
      }
      String proposalName = _getConstructorProposalName(superConstructor);
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(insertOffset, (DartEditBuilder builder) {
          builder.write(prefix);
          // add super constructor name
          builder.write('super');
          if (!isEmpty(constructorName)) {
            builder.write('.');
            builder.addSimpleLinkedEdit('NAME', constructorName);
          }
          // add arguments
          builder.write('(');
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
              builder.write(', ');
            }
            // default value
            builder.addSimpleLinkedEdit(
                parameter.name, getDefaultValueCode(parameter.type));
          }
          builder.write(')');
        });
      });
      _addFixFromBuilder(
          changeBuilder, DartFixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION,
          args: [proposalName]);
    }
  }

  Future<Null> _addFix_createConstructorSuperImplicit() async {
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
      Iterable<ParameterElement> requiredParameters =
          superConstructor.parameters.where(
              (parameter) => parameter.parameterKind == ParameterKind.REQUIRED);
      // add proposal
      ClassMemberLocation targetLocation =
          utils.prepareNewConstructorLocation(targetClassNode);
      String proposalName = _getConstructorProposalName(superConstructor);
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
          void writeParameters(bool includeType) {
            bool firstParameter = true;
            for (ParameterElement parameter in requiredParameters) {
              if (firstParameter) {
                firstParameter = false;
              } else {
                builder.write(', ');
              }
              String parameterName = parameter.displayName;
              if (parameterName.length > 1 && parameterName.startsWith('_')) {
                parameterName = parameterName.substring(1);
              }
              if (includeType && builder.writeType(parameter.type)) {
                builder.write(' ');
              }
              builder.write(parameterName);
            }
          }

          builder.write(targetLocation.prefix);
          builder.write(targetClassName);
          if (!constructorName.isEmpty) {
            builder.write('.');
            builder.addSimpleLinkedEdit('NAME', constructorName);
          }
          builder.write('(');
          writeParameters(true);
          builder.write(') : super');
          if (!constructorName.isEmpty) {
            builder.write('.');
            builder.addSimpleLinkedEdit('NAME', constructorName);
          }
          builder.write('(');
          writeParameters(false);
          builder.write(');');
          builder.write(targetLocation.suffix);
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_CONSTRUCTOR_SUPER,
          args: [proposalName]);
    }
  }

  Future<Null> _addFix_createField() async {
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
      } else if (nameParent is PropertyAccess) {
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
    // build field source
    Source targetSource = targetClassElement.source;
    String targetFile = targetSource.fullName;
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      Expression fieldTypeNode = climbPropertyAccess(nameNode);
      DartType fieldType = _inferUndefinedExpressionType(fieldTypeNode);
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        builder.write(targetLocation.prefix);
        builder.writeFieldDeclaration(name,
            isStatic: staticModifier,
            nameGroupName: 'NAME',
            type: fieldType,
            typeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FIELD, args: [name]);
  }

  Future<Null> _addFix_createField_initializingFormal() async {
    //
    // Ensure that we are in an initializing formal parameter.
    //
    FieldFormalParameter parameter =
        node.getAncestor((node) => node is FieldFormalParameter);
    if (parameter == null) {
      return;
    }
    ClassDeclaration targetClassNode =
        parameter.getAncestor((node) => node is ClassDeclaration);
    if (targetClassNode == null) {
      return;
    }
    SimpleIdentifier nameNode = parameter.identifier;
    String name = nameNode.name;
    ClassMemberLocation targetLocation =
        utils.prepareNewFieldLocation(targetClassNode);
    //
    // Add proposal.
    //
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      DartType fieldType = parameter.type?.type;
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        builder.write(targetLocation.prefix);
        builder.writeFieldDeclaration(name,
            nameGroupName: 'NAME', type: fieldType, typeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FIELD, args: [name]);
  }

  Future<Null> _addFix_createFunction_forFunctionType() async {
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
        await _addProposal_createFunction_method(targetElement, functionType);
      } else {
        await _addProposal_createFunction_function(functionType);
      }
    }
  }

  Future<Null> _addFix_createGetter() async {
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
      } else if (nameParent is PropertyAccess) {
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
    Source targetSource = targetClassElement.source;
    String targetFile = targetSource.fullName;
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        Expression fieldTypeNode = climbPropertyAccess(nameNode);
        DartType fieldType = _inferUndefinedExpressionType(fieldTypeNode);
        builder.write(targetLocation.prefix);
        builder.writeGetterDeclaration(name,
            isStatic: staticModifier,
            nameGroupName: 'NAME',
            returnType: fieldType,
            returnTypeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_GETTER, args: [name]);
  }

  Future<Null> _addFix_createImportUri() async {
    // TODO(brianwilkerson) Generalize this to allow other valid string literals.
    // TODO(brianwilkerson) Support the case where the node's parent is a Configuration.
    if (node is SimpleStringLiteral && node.parent is ImportDirective) {
      ImportDirective importDirective = node.parent;
      Source source = importDirective.uriSource;
      if (source != null) {
        String file = source.fullName;
        if (isAbsolute(file) && AnalysisEngine.isDartFileName(file)) {
          String libName = _computeLibraryName(file);
          DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
          await changeBuilder.addFileEdit(source.fullName,
              (DartFileEditBuilder builder) {
            builder.addSimpleInsertion(0, 'library $libName;$eol$eol');
          });
          _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FILE,
              args: [source.shortName]);
        }
      }
    }
  }

  Future<Null> _addFix_createLocalVariable() async {
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
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleInsertion(node.offset, 'var ');
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_LOCAL_VARIABLE,
            args: [name]);
        return;
      }
    }
    // prepare target Statement
    Statement target = node.getAncestor((x) => x is Statement);
    if (target == null) {
      return;
    }
    String prefix = utils.getNodePrefix(target);
    // compute type
    DartType type = _inferUndefinedExpressionType(node);
    if (!(type == null ||
        type is InterfaceType ||
        type is FunctionType &&
            type.element != null &&
            !type.element.isSynthetic)) {
      return;
    }
    // build variable declaration source
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(target.offset, (DartEditBuilder builder) {
        builder.writeLocalVariableDeclaration(name,
            nameGroupName: 'NAME', type: type, typeGroupName: 'TYPE');
        builder.write(eol);
        builder.write(prefix);
      });
      builder.addLinkedPosition(range.node(node), 'NAME');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_LOCAL_VARIABLE,
        args: [name]);
  }

  Future<Null> _addFix_createMissingOverrides() async {
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
    int numElements = elements.length;
    int insertOffset = targetClass.end - 1;
    String prefix = utils.getIndent(1);
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(insertOffset, (DartEditBuilder builder) {
        // TODO(brianwilkerson) Compare with builder.writeOverrideOfInheritedMember
        // The builder method doesn't merge getter/setter pairs into fields.
        // EOL management
        bool isFirst = true;
        void addEolIfNotFirst() {
          if (!isFirst || utils.isClassWithEmptyBody(targetClass)) {
            builder.write(eol);
          }
          isFirst = false;
        }

        // merge getter/setter pairs into fields
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
              builder.write(prefix);
              builder.write('@override');
              builder.write(eol);
              // add field
              builder.write(prefix);
              builder.writeType(element.type.returnType, required: true);
              builder.write(' ');
              builder.write(element.name);
              builder.write(';');
              builder.write(eol);
            }
          }
        }
        // add elements
        for (ExecutableElement element in elements) {
          addEolIfNotFirst();
          _addFix_createMissingOverridesForBuilder(
              builder, targetClass, element);
        }
      });
    });
    changeBuilder.setSelection(new Position(file, insertOffset));
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_MISSING_OVERRIDES,
        args: [numElements]);
  }

  void _addFix_createMissingOverridesForBuilder(DartEditBuilder builder,
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
    builder.write(prefix);
    if (isGetter) {
      builder.write('// TODO: implement ${element.displayName}');
      builder.write(eol);
      builder.write(prefix);
    }
    // @override
    builder.write('@override');
    builder.write(eol);
    builder.write(prefix);
    // return type
    if (!isSetter) {
      if (builder.writeType(element.type.returnType,
          methodBeingCopied: element)) {
        builder.write(' ');
      }
    }
    // keyword
    if (isGetter) {
      builder.write('get ');
    } else if (isSetter) {
      builder.write('set ');
    } else if (isOperator) {
      builder.write('operator ');
    }
    // name
    builder.write(element.displayName);
    builder.writeTypeParameters(element.typeParameters);
    // parameters + body
    if (isGetter) {
      builder.write(' => null;');
    } else {
      List<ParameterElement> parameters = element.parameters;
      builder.writeParameters(parameters, methodBeingCopied: element);
      builder.write(' {');
      // TO-DO
      builder.write(eol);
      builder.write(prefix2);
      builder.write('// TODO: implement ${element.displayName}');
      builder.write(eol);
      // close method
      builder.write(prefix);
      builder.write('}');
    }
    builder.write(eol);
    utils.targetExecutableElement = null;
  }

  Future<Null> _addFix_createNoSuchMethod() async {
    ClassDeclaration targetClass = node.parent as ClassDeclaration;
    // prepare environment
    String prefix = utils.getIndent(1);
    int insertOffset = targetClass.end - 1;
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(insertOffset, (DartEditBuilder builder) {
        builder.selectHere();
        // insert empty line before existing member
        if (!targetClass.members.isEmpty) {
          builder.write(eol);
        }
        // append method
        builder.write(prefix);
        builder.write(
            'noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);');
        builder.write(eol);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_NO_SUCH_METHOD);
  }

  Future<Null> _addFix_createPartUri() async {
    // TODO(brianwilkerson) Generalize this to allow other valid string literals.
    if (node is SimpleStringLiteral && node.parent is PartDirective) {
      PartDirective partDirective = node.parent;
      Source source = partDirective.uriSource;
      if (source != null) {
        String libName = unitLibraryElement.name;
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(source.fullName,
            (DartFileEditBuilder builder) {
          // TODO(brianwilkerson) Consider using the URI rather than name
          builder.addSimpleInsertion(0, 'part of $libName;$eol$eol');
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FILE,
            args: [source.shortName]);
      }
    }
  }

  Future<Null> _addFix_illegalAsyncReturnType() async {
    // prepare the existing type
    TypeAnnotation typeName = node.getAncestor((n) => n is TypeAnnotation);
    TypeProvider typeProvider = this.typeProvider;
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.replaceTypeWithFuture(typeName, typeProvider);
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_RETURN_TYPE_FUTURE);
  }

  Future<Null> _addFix_importLibrary(FixKind kind, Source library) async {
    String libraryUri = getLibrarySourceUri(unitLibraryElement, library);
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.importLibraries([library]);
    });
    _addFixFromBuilder(changeBuilder, kind, args: [libraryUri]);
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
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(
              range.startLength(node, 0), '${prefix.displayName}.');
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.IMPORT_LIBRARY_PREFIX,
            args: [libraryElement.displayName, prefix.displayName]);
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
        String libraryFile = unitLibraryElement.source.fullName;
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(libraryFile,
            (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(
              new SourceRange(offset, length), newShowCode);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.IMPORT_LIBRARY_SHOW,
            args: [libraryName]);
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
        await _addFix_importLibrary(fixKind, librarySource);
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

  Future<Null> _addFix_insertSemicolon() async {
    if (error.message.contains("';'")) {
      if (_isAwaitNode()) {
        return;
      }
      int insertOffset = error.offset + error.length;
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleInsertion(insertOffset, ';');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.INSERT_SEMICOLON);
    }
  }

  Future<Null> _addFix_isNotNull() async {
    if (coveredNode is IsExpression) {
      IsExpression isExpression = coveredNode as IsExpression;
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder
            .addReplacement(range.endEnd(isExpression.expression, isExpression),
                (DartEditBuilder builder) {
          builder.write(' != null');
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.USE_NOT_EQ_NULL);
    }
  }

  Future<Null> _addFix_isNull() async {
    if (coveredNode is IsExpression) {
      IsExpression isExpression = coveredNode as IsExpression;
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder
            .addReplacement(range.endEnd(isExpression.expression, isExpression),
                (DartEditBuilder builder) {
          builder.write(' == null');
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.USE_EQ_EQ_NULL);
    }
  }

  Future<Null> _addFix_makeEnclosingClassAbstract() async {
    ClassDeclaration enclosingClass =
        node.getAncestor((node) => node is ClassDeclaration);
    if (enclosingClass == null) {
      return;
    }
    String className = enclosingClass.name.name;
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(
          enclosingClass.classKeyword.offset, 'abstract ');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.MAKE_CLASS_ABSTRACT,
        args: [className]);
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
            DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
            await changeBuilder.addFileEdit(file,
                (DartFileEditBuilder builder) {
              if (declarationList.type != null) {
                builder.addReplacement(
                    range.startStart(keywordToken, declarationList.type),
                    (DartEditBuilder builder) {});
              } else {
                builder.addReplacement(range.startStart(keywordToken, variable),
                    (DartEditBuilder builder) {
                  builder.write('var ');
                });
              }
            });
            String fieldName = getter.variable.displayName;
            _addFixFromBuilder(changeBuilder, DartFixKind.MAKE_FIELD_NOT_FINAL,
                args: [fieldName]);
          }
        }
      }
    }
  }

  Future<Null> _addFix_nonBoolCondition_addNotNull() async {
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(error.offset + error.length, ' != null');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_NE_NULL);
  }

  Future<Null> _addFix_removeAwait() async {
    final awaitExpression = node;
    if (awaitExpression is AwaitExpression) {
      final awaitToken = awaitExpression.awaitKeyword;
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(awaitToken, awaitToken.next));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_AWAIT);
    }
  }

  Future<Null> _addFix_removeDeadCode() async {
    AstNode coveringNode = this.coveredNode;
    if (coveringNode is Expression) {
      AstNode parent = coveredNode.parent;
      if (parent is BinaryExpression) {
        if (parent.rightOperand == coveredNode) {
          DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
          await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
            builder.addDeletion(range.endEnd(parent.leftOperand, coveredNode));
          });
          _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DEAD_CODE);
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
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addDeletion(rangeToRemove);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DEAD_CODE);
      }
    } else if (coveringNode is Statement) {
      SourceRange rangeToRemove =
          utils.getLinesRangeStatements(<Statement>[coveringNode]);
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(rangeToRemove);
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DEAD_CODE);
    }
  }

  Future<Null> _addFix_removeEmptyStatement() async {
    EmptyStatement emptyStatement = node;
    if (emptyStatement.parent is Block) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(utils.getLinesRange(range.node(emptyStatement)));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_EMPTY_STATEMENT);
    } else {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(
            range.endEnd(emptyStatement.beginToken.previous, emptyStatement),
            ' {}');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_BRACKETS);
    }
  }

  Future<Null> _addFix_removeInitializer() async {
    // Retrieve the linted node.
    VariableDeclaration ancestor =
        node.getAncestor((a) => a is VariableDeclaration);
    if (ancestor == null) {
      return;
    }
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(range.endEnd(ancestor.name, ancestor.initializer));
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_INITIALIZER);
  }

  Future<Null> _addFix_removeInterpolationBraces() async {
    AstNode node = this.node;
    if (node is InterpolationExpression) {
      Token right = node.rightBracket;
      if (node.expression != null && right != null) {
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(
              range.startStart(node, node.expression), r'$');
          builder.addDeletion(range.token(right));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.LINT_REMOVE_INTERPOLATION_BRACES);
      } else {}
    }
  }

  Future<Null> _addFix_removeMethodDeclaration() async {
    MethodDeclaration declaration =
        node.getAncestor((node) => node is MethodDeclaration);
    if (declaration != null) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(utils.getLinesRange(range.node(declaration)));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_METHOD_DECLARATION);
    }
  }

  Future<Null> _addFix_removeParameters_inGetterDeclaration() async {
    if (node is MethodDeclaration) {
      MethodDeclaration method = node as MethodDeclaration;
      SimpleIdentifier name = method.name;
      FunctionBody body = method.body;
      if (name != null && body != null) {
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(range.endStart(name, body), ' ');
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_PARAMETERS_IN_GETTER_DECLARATION);
      }
    }
  }

  Future<Null> _addFix_removeParentheses_inGetterInvocation() async {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      if (invocation.methodName == node && invocation.target != null) {
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addDeletion(range.endEnd(node, invocation));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_PARENTHESIS_IN_GETTER_INVOCATION);
      }
    }
  }

  Future<Null> _addFix_removeThisExpression() async {
    final thisExpression = node is ThisExpression
        ? node
        : node.getAncestor((node) => node is ThisExpression);
    final parent = thisExpression.parent;
    if (parent is PropertyAccess) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startEnd(parent, parent.operator));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_THIS_EXPRESSION);
    } else if (parent is MethodInvocation) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startEnd(parent, parent.operator));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_THIS_EXPRESSION);
    }
  }

  Future<Null> _addFix_removeTypeName() async {
    final TypeName type = node.getAncestor((node) => node is TypeName);
    if (type != null) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(type, type.endToken.next));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_TYPE_NAME);
    }
  }

  Future<Null> _addFix_removeUnnecessaryCast() async {
    if (coveredNode is! AsExpression) {
      return;
    }
    AsExpression asExpression = coveredNode as AsExpression;
    Expression expression = asExpression.expression;
    int expressionPrecedence = getExpressionPrecedence(expression);
    // remove 'as T' from 'e as T'
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(range.endEnd(expression, asExpression));
      _removeEnclosingParentheses(builder, asExpression, expressionPrecedence);
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNNECESSARY_CAST);
  }

  Future<Null> _addFix_removeUnusedCatchClause() async {
    if (node is SimpleIdentifier) {
      AstNode catchClause = node.parent;
      if (catchClause is CatchClause &&
          catchClause.exceptionParameter == node) {
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addDeletion(
              range.startStart(catchClause.catchKeyword, catchClause.body));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_UNUSED_CATCH_CLAUSE);
      }
    }
  }

  Future<Null> _addFix_removeUnusedCatchStack() async {
    if (node is SimpleIdentifier) {
      AstNode catchClause = node.parent;
      if (catchClause is CatchClause &&
          catchClause.stackTraceParameter == node &&
          catchClause.exceptionParameter != null) {
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder
              .addDeletion(range.endEnd(catchClause.exceptionParameter, node));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_UNUSED_CATCH_STACK);
      }
    }
  }

  Future<Null> _addFix_removeUnusedImport() async {
    // prepare ImportDirective
    ImportDirective importDirective =
        node.getAncestor((node) => node is ImportDirective);
    if (importDirective == null) {
      return;
    }
    // remove the whole line with import
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(utils.getLinesRange(range.node(importDirective)));
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNUSED_IMPORT);
  }

  Future<Null> _addFix_replaceVarWithDynamic() async {
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.error(error), 'dynamic');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_VAR_WITH_DYNAMIC);
  }

  Future<Null> _addFix_replaceWithConditionalAssignment() async {
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
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addReplacement(range.node(ifStatement),
              (DartEditBuilder builder) {
            builder.write(utils.getNodeText(expression.leftHandSide));
            builder.write(' ??= ');
            builder.write(utils.getNodeText(expression.rightHandSide));
            builder.write(';');
          });
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REPLACE_WITH_CONDITIONAL_ASSIGNMENT);
      }
    }
  }

  Future<Null> _addFix_replaceWithConstInstanceCreation() async {
    if (coveredNode is InstanceCreationExpression) {
      var instanceCreation = coveredNode as InstanceCreationExpression;
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(
            range.token(instanceCreation.keyword), 'const');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.USE_CONST);
    }
  }

  Future<Null> _addFix_replaceWithIdentifier() async {
    final FunctionTypedFormalParameter functionTyped =
        node.getAncestor((node) => node is FunctionTypedFormalParameter);
    if (functionTyped != null) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(range.node(functionTyped),
            utils.getNodeText(functionTyped.identifier));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_IDENTIFIER);
    } else {
      await _addFix_removeTypeName();
    }
  }

  Future<Null> _addFix_replaceWithLiteral() async {
    final InstanceCreationExpression instanceCreation =
        node.getAncestor((node) => node is InstanceCreationExpression);
    final InterfaceType type = instanceCreation.staticType;
    final generics = instanceCreation.constructorName.type.typeArguments;
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(instanceCreation),
          (DartEditBuilder builder) {
        if (generics != null) {
          builder.write(utils.getNodeText(generics));
        }
        if (type.name == 'List') {
          builder.write('[]');
        } else {
          builder.write('{}');
        }
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_LITERAL);
  }

  Future<Null> _addFix_replaceWithTearOff() async {
    FunctionExpression ancestor =
        node.getAncestor((a) => a is FunctionExpression);
    if (ancestor == null) {
      return;
    }
    Future<Null> addFixOfExpression(InvocationExpression expression) async {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(range.node(ancestor), (DartEditBuilder builder) {
          if (expression is MethodInvocation && expression.target != null) {
            builder.write(utils.getNodeText(expression.target));
            builder.write('.');
          }
          builder.write(utils.getNodeText(expression.function));
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_TEAR_OFF);
    }

    final body = ancestor.body;
    if (body is ExpressionFunctionBody) {
      final expression = body.expression;
      await addFixOfExpression(expression.unParenthesized);
    } else if (body is BlockFunctionBody) {
      final statement = body.block.statements.first;
      if (statement is ExpressionStatement) {
        final expression = statement.expression;
        await addFixOfExpression(expression.unParenthesized);
      } else if (statement is ReturnStatement) {
        final expression = statement.expression;
        await addFixOfExpression(expression.unParenthesized);
      }
    }
  }

  Future<Null> _addFix_undefinedClass_useSimilar() async {
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
        if (closestName != null) {
          DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
          await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
            builder.addSimpleReplacement(range.node(node), closestName);
          });
          _addFixFromBuilder(changeBuilder, DartFixKind.CHANGE_TO,
              args: [closestName]);
        }
      }
    }
  }

  Future<Null> _addFix_undefinedClassAccessor_useSimilar() async {
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
        await _addFix_undefinedClassMember_useSimilar(target,
            (Element element) {
          return element is PropertyAccessorElement && element.isGetter ||
              element is FieldElement && element.getter != null;
        });
      }
      // find setter
      if (node.inSetterContext()) {
        await _addFix_undefinedClassMember_useSimilar(target,
            (Element element) {
          return element is PropertyAccessorElement && element.isSetter ||
              element is FieldElement && element.setter != null;
        });
      }
    }
  }

  Future<Null> _addFix_undefinedClassMember_useSimilar(
      Expression target, ElementPredicate predicate) async {
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
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(range.node(node), closestName);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.CHANGE_TO,
            args: [closestName]);
      }
    }
  }

  Future<Null> _addFix_undefinedFunction_create() async {
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
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(insertOffset, (DartEditBuilder builder) {
        builder.write(sourcePrefix);
        // append return type
        {
          DartType type = _inferUndefinedExpressionType(invocation);
          if (builder.writeType(type, groupName: 'RETURN_TYPE')) {
            builder.write(' ');
          }
        }
        // append name
        builder.addLinkedEdit('NAME', (DartLinkedEditBuilder builder) {
          builder.write(name);
        });
        builder.write('(');
        builder.writeParametersMatchingArguments(invocation.argumentList);
        builder.write(') {$eol}');
      });
      builder.addLinkedPosition(range.node(node), 'NAME');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FUNCTION,
        args: [name]);
  }

  Future<Null> _addFix_undefinedFunction_useSimilar() async {
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
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(range.node(node), closestName);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.CHANGE_TO,
            args: [closestName]);
      }
    }
  }

  Future<Null> _addFix_undefinedMethod_create() async {
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
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(targetFile,
          (DartFileEditBuilder builder) {
        builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
          builder.write(targetLocation.prefix);
          // maybe "static"
          if (staticModifier) {
            builder.write('static ');
          }
          // append return type
          {
            DartType type = _inferUndefinedExpressionType(invocation);
            if (builder.writeType(type, groupName: 'RETURN_TYPE')) {
              builder.write(' ');
            }
          }
          // append name
          builder.addLinkedEdit('NAME', (DartLinkedEditBuilder builder) {
            builder.write(name);
          });
          builder.write('(');
          builder.writeParametersMatchingArguments(invocation.argumentList);
          builder.write(') {}');
          builder.write(targetLocation.suffix);
        });
        if (targetFile == file) {
          builder.addLinkedPosition(range.node(node), 'NAME');
        }
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_METHOD,
          args: [name]);
    }
  }

  Future<Null> _addFix_undefinedMethod_useSimilar() async {
    if (node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      await _addFix_undefinedClassMember_useSimilar(invocation.realTarget,
          (Element element) => element is MethodElement && !element.isOperator);
    }
  }

  /**
   * Here we handle cases when a constructors does not initialize all of the
   * final fields.
   */
  Future<Null> _addFix_updateConstructor_forUninitializedFinalFields() async {
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
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      // append new field formal initializers
      if (lastRequiredParameter != null) {
        builder.addSimpleInsertion(
            lastRequiredParameter.end, ', $fieldParametersCode');
      } else {
        int offset = constructor.parameters.leftParenthesis.end;
        if (parameters.isNotEmpty) {
          fieldParametersCode += ', ';
        }
        builder.addSimpleInsertion(offset, fieldParametersCode);
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_FIELD_FORMAL_PARAMETERS);
  }

  Future<Null> _addFix_useEffectiveIntegerDivision() async {
    for (AstNode n = node; n != null; n = n.parent) {
      if (n is MethodInvocation &&
          n.offset == errorOffset &&
          n.length == errorLength) {
        Expression target = (n as MethodInvocation).target.unParenthesized;
        DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          // replace "/" with "~/"
          BinaryExpression binary = target as BinaryExpression;
          builder.addSimpleReplacement(range.token(binary.operator), '~/');
          // remove everything before and after
          builder.addDeletion(range.startStart(n, binary.leftOperand));
          builder.addDeletion(range.endEnd(binary.rightOperand, n));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.USE_EFFECTIVE_INTEGER_DIVISION);
        // done
        break;
      }
    }
  }

  /**
   * Adds a fix that replaces [target] with a reference to the class declaring
   * the given [element].
   */
  Future<Null> _addFix_useStaticAccess(AstNode target, Element element) async {
    Element declaringElement = element.enclosingElement;
    if (declaringElement is ClassElement) {
      DartType declaringType = declaringElement.type;
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        // replace "target" with class name
        builder.addReplacement(range.node(target), (DartEditBuilder builder) {
          builder.writeType(declaringType);
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.CHANGE_TO_STATIC_ACCESS,
          args: [declaringType]);
    }
  }

  Future<Null> _addFix_useStaticAccess_method() async {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      if (invocation.methodName == node) {
        Expression target = invocation.target;
        Element invokedElement = invocation.methodName.bestElement;
        await _addFix_useStaticAccess(target, invokedElement);
      }
    }
  }

  Future<Null> _addFix_useStaticAccess_property() async {
    if (node is SimpleIdentifier && node.parent is PrefixedIdentifier) {
      PrefixedIdentifier prefixed = node.parent as PrefixedIdentifier;
      if (prefixed.identifier == node) {
        Expression target = prefixed.prefix;
        Element invokedElement = prefixed.identifier.bestElement;
        await _addFix_useStaticAccess(target, invokedElement);
      }
    }
  }

  void _addFixFromBuilder(DartChangeBuilder builder, FixKind kind,
      {List args: null, bool importsOnly: false}) {
    SourceChange change = builder.sourceChange;
    if (change.edits.isEmpty && !importsOnly) {
      return;
    }
    change.message = formatList(kind.message, args);
    fixes.add(new Fix(kind, change));
  }

  /**
   * Prepares proposal for creating function corresponding to the given
   * [FunctionType].
   */
  Future<DartChangeBuilder> _addProposal_createFunction(
      FunctionType functionType,
      String name,
      Source targetSource,
      int insertOffset,
      bool isStatic,
      String prefix,
      String sourcePrefix,
      String sourceSuffix,
      Element target) async {
    // build method source
    String targetFile = targetSource.fullName;
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      builder.addInsertion(insertOffset, (DartEditBuilder builder) {
        builder.write(sourcePrefix);
        builder.write(prefix);
        // may be static
        if (isStatic) {
          builder.write('static ');
        }
        // append return type
        if (builder.writeType(functionType.returnType,
            groupName: 'RETURN_TYPE')) {
          builder.write(' ');
        }
        // append name
        builder.addLinkedEdit('NAME', (DartLinkedEditBuilder builder) {
          builder.write(name);
        });
        // append parameters
        builder.write('(');
        List<ParameterElement> parameters = functionType.parameters;
        for (int i = 0; i < parameters.length; i++) {
          ParameterElement parameter = parameters[i];
          // append separator
          if (i != 0) {
            builder.write(', ');
          }
          // append type name
          DartType type = parameter.type;
          if (!type.isDynamic) {
            builder.addLinkedEdit('TYPE$i',
                (DartLinkedEditBuilder innerBuilder) {
              builder.writeType(type);
              innerBuilder.addSuperTypesAsSuggestions(type);
            });
            builder.write(' ');
          }
          // append parameter name
          builder.addLinkedEdit('ARG$i', (DartLinkedEditBuilder builder) {
            builder.write(parameter.displayName);
          });
        }
        builder.write(')');
        // close method
        builder.write(' {$eol$prefix}');
        builder.write(sourceSuffix);
      });
      if (targetSource == unitSource) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
    return changeBuilder;
  }

  /**
   * Adds proposal for creating method corresponding to the given [FunctionType] in the given
   * [ClassElement].
   */
  Future<Null> _addProposal_createFunction_function(
      FunctionType functionType) async {
    String name = (node as SimpleIdentifier).name;
    // prepare environment
    int insertOffset = unit.end;
    // prepare prefix
    String prefix = '';
    String sourcePrefix = '$eol';
    String sourceSuffix = eol;
    DartChangeBuilder changeBuilder = await _addProposal_createFunction(
        functionType,
        name,
        unitSource,
        insertOffset,
        false,
        prefix,
        sourcePrefix,
        sourceSuffix,
        unitElement);
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FUNCTION,
        args: [name]);
  }

  /**
   * Adds proposal for creating method corresponding to the given [FunctionType] in the given
   * [ClassElement].
   */
  Future<Null> _addProposal_createFunction_method(
      ClassElement targetClassElement, FunctionType functionType) async {
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
    DartChangeBuilder changeBuilder = await _addProposal_createFunction(
        functionType,
        name,
        targetSource,
        insertOffset,
        _inStaticContext(),
        prefix,
        sourcePrefix,
        sourceSuffix,
        targetClassElement);
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_METHOD, args: [name]);
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
   * Return the string to display as the name of the given constructor in a
   * proposal name.
   */
  String _getConstructorProposalName(ConstructorElement constructor) {
    StringBuffer buffer = new StringBuffer();
    buffer.write('super');
    String constructorName = constructor.displayName;
    if (!constructorName.isEmpty) {
      buffer.write('.');
      buffer.write(constructorName);
    }
    buffer.write('(...)');
    return buffer.toString();
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

  /**
   * Removes any [ParenthesizedExpression] enclosing [expr].
   *
   * [exprPrecedence] - the effective precedence of [expr].
   */
  void _removeEnclosingParentheses(
      DartFileEditBuilder builder, Expression expr, int exprPrecedence) {
    while (expr.parent is ParenthesizedExpression) {
      ParenthesizedExpression parenthesized =
          expr.parent as ParenthesizedExpression;
      if (getExpressionParentPrecedence(parenthesized) > exprPrecedence) {
        break;
      }
      builder.addDeletion(range.token(parenthesized.leftParenthesis));
      builder.addDeletion(range.token(parenthesized.rightParenthesis));
      expr = parenthesized;
    }
  }

  void _updateFinderWithClassMembers(
      _ClosestElementFinder finder, ClassElement clazz) {
    if (clazz != null) {
      List<Element> members = getMembers(clazz);
      finder._updateList(members);
    }
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
