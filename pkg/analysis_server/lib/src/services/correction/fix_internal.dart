// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:core';
import 'dart:math' as math;

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/services/correction/base_processor.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_contains.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_list_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_map_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_set_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_where_type.dart';
import 'package:analysis_server/src/services/correction/dart/remove_if_null_operator.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/levenshtein.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/inheritance_override.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError, Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart' hide FixContributor;
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:path/path.dart';

/// A predicate is a one-argument function that returns a boolean value.
typedef ElementPredicate = bool Function(Element argument);

/// A fix contributor that provides the default set of fixes for Dart files.
class DartFixContributor implements FixContributor {
  @override
  Future<List<Fix>> computeFixes(DartFixContext context) async {
    try {
      FixProcessor processor = FixProcessor(context);
      List<Fix> fixes = await processor.compute();
      List<Fix> fixAllFixes = await _computeFixAllFixes(context, fixes);
      return List.from(fixes)..addAll(fixAllFixes);
    } on CancelCorrectionException {
      return const <Fix>[];
    }
  }

  Future<List<Fix>> _computeFixAllFixes(
      DartFixContext context, List<Fix> fixes) async {
    final analysisError = context.error;
    final allAnalysisErrors = context.resolveResult.errors.toList();

    // Validate inputs:
    // - return if no fixes
    // - return if no other analysis errors
    if (fixes.isEmpty || allAnalysisErrors.length < 2) {
      return const <Fix>[];
    }

    // Remove any analysis errors that don't have the expected error code name
    allAnalysisErrors
        .removeWhere((e) => analysisError.errorCode.name != e.errorCode.name);
    if (allAnalysisErrors.length < 2) {
      return const <Fix>[];
    }

    // A map between each FixKind and the List of associated fixes
    final HashMap<FixKind, List<Fix>> map = HashMap();

    // Populate the HashMap by looping through all AnalysisErrors, creating a
    // new FixProcessor to compute the other fixes that can be applied with this
    // one.
    // For each fix, put the fix into the HashMap.
    for (int i = 0; i < allAnalysisErrors.length; i++) {
      final FixContext fixContextI = DartFixContextImpl(
        context.workspace,
        context.resolveResult,
        allAnalysisErrors[i],
        (name) => [],
      );
      final FixProcessor processorI = FixProcessor(fixContextI);
      final List<Fix> fixesListI = await processorI.compute();
      for (Fix f in fixesListI) {
        if (!map.containsKey(f.kind)) {
          map[f.kind] = <Fix>[]..add(f);
        } else {
          map[f.kind].add(f);
        }
      }
    }

    // For each FixKind in the HashMap, union each list together, then return
    // the set of unioned Fixes.
    final List<Fix> result = <Fix>[];
    map.forEach((FixKind kind, List<Fix> fixesListJ) {
      if (fixesListJ.first.kind.canBeAppliedTogether()) {
        Fix unionFix = _unionFixList(fixesListJ);
        if (unionFix != null) {
          result.add(unionFix);
        }
      }
    });
    return result;
  }

  Fix _unionFixList(List<Fix> fixList) {
    if (fixList == null || fixList.isEmpty) {
      return null;
    } else if (fixList.length == 1) {
      return fixList[0];
    }
    final SourceChange sourceChange =
        SourceChange(fixList[0].kind.appliedTogetherMessage);
    sourceChange.edits = List.from(fixList[0].change.edits);
    final List<SourceEdit> edits = <SourceEdit>[];
    edits.addAll(fixList[0].change.edits[0].edits);
    sourceChange.linkedEditGroups =
        List.from(fixList[0].change.linkedEditGroups);
    for (int i = 1; i < fixList.length; i++) {
      edits.addAll(fixList[i].change.edits[0].edits);
      sourceChange.linkedEditGroups..addAll(fixList[i].change.linkedEditGroups);
    }
    // Sort the list of SourceEdits so that when the edits are applied, they
    // are applied from the end of the file to the top of the file.
    edits.sort((s1, s2) => s2.offset - s1.offset);

    sourceChange.edits[0].edits = edits;

    return Fix(fixList[0].kind, sourceChange);
  }
}

/// The computer for Dart fixes.
class FixProcessor extends BaseProcessor {
  static const int MAX_LEVENSHTEIN_DISTANCE = 3;

  final DartFixContext context;
  final ResourceProvider resourceProvider;
  final TypeSystem typeSystem;

  final LibraryElement unitLibraryElement;
  final CompilationUnit unit;

  final AnalysisError error;
  final int errorOffset;
  final int errorLength;

  final List<Fix> fixes = <Fix>[];

  AstNode coveredNode;

  FixProcessor(this.context)
      : resourceProvider = context.resolveResult.session.resourceProvider,
        typeSystem = context.resolveResult.typeSystem,
        unitLibraryElement = context.resolveResult.libraryElement,
        unit = context.resolveResult.unit,
        error = context.error,
        errorOffset = context.error.offset,
        errorLength = context.error.length,
        super(
          resolvedResult: context.resolveResult,
          workspace: context.workspace,
        );

  DartType get coreTypeBool => context.resolveResult.typeProvider.boolType;

  FeatureSet get _featureSet {
    return unit.featureSet;
  }

  bool get _isNonNullable => _featureSet.isEnabled(Feature.non_nullable);

  Future<List<Fix>> compute() async {
    node = NodeLocator2(errorOffset).searchWithin(unit);
    coveredNode =
        NodeLocator2(errorOffset, math.max(errorOffset + errorLength - 1, 0))
            .searchWithin(unit);
    if (coveredNode == null) {
      // TODO(brianwilkerson) Figure out why the coveredNode is sometimes null.
      return fixes;
    }

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
        errorCode == CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT ||
        errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT) {
      await _addFix_addAsync();
    }
    if (errorCode == CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE) {
      await _addFix_changeToNearestPreciseValue();
    }

    if (errorCode == CompileTimeErrorCode.INVALID_ANNOTATION ||
        errorCode == CompileTimeErrorCode.UNDEFINED_ANNOTATION) {
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
      // TODO(brianwilkerson) The following was added because fasta produces
      // NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT in places where analyzer produced
      // NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT
      await _addFix_createConstructorSuperExplicit();
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
    if (errorCode == HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH ||
        errorCode == HintCode.DEAD_CODE_ON_CATCH_SUBTYPE) {
      await _addFix_removeDeadCode();
      // TODO(brianwilkerson) Add a fix to move the unreachable catch clause to
      //  a place where it can be reached (when possible).
    }
    // TODO(brianwilkerson) Define a syntax for deprecated members to indicate
    //  how to update the code and implement a fix to apply the update.
//    if (errorCode == HintCode.DEPRECATED_MEMBER_USE ||
//        errorCode == HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE) {
//      await _addFix_replaceDeprecatedMemberUse();
//    }
    if (errorCode == HintCode.DIVISION_OPTIMIZATION) {
      await _addFix_useEffectiveIntegerDivision();
    }
    if (errorCode == HintCode.DUPLICATE_IMPORT) {
      await _addFix_removeUnusedImport();
    }
    if (errorCode == HintCode.DUPLICATE_HIDDEN_NAME ||
        errorCode == HintCode.DUPLICATE_SHOWN_NAME) {
      await _addFix_removeNameFromCombinator();
    }
    // TODO(brianwilkerson) Add a fix to convert the path to a package: import.
//    if (errorCode == HintCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE) {
//      await _addFix_convertPathToPackageUri();
//    }
    if (errorCode == HintCode.INVALID_FACTORY_ANNOTATION ||
        errorCode == HintCode.INVALID_IMMUTABLE_ANNOTATION ||
        errorCode == HintCode.INVALID_LITERAL_ANNOTATION ||
        errorCode == HintCode.INVALID_REQUIRED_NAMED_PARAM ||
        errorCode == HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM ||
        errorCode == HintCode.INVALID_REQUIRED_POSITIONAL_PARAM ||
        errorCode == HintCode.INVALID_SEALED_ANNOTATION) {
      await _addFix_removeAnnotation();
    }
    if (errorCode == HintCode.MISSING_REQUIRED_PARAM ||
        errorCode == HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS) {
      await _addFix_addMissingRequiredArgument();
    }
    if (errorCode == HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER ||
        errorCode == HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD ||
        errorCode == HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD ||
        errorCode == HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER) {
      await _addFix_removeAnnotation();
    }
    // TODO(brianwilkerson) Add a fix to normalize the path.
//    if (errorCode == HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT) {
//      await _addFix_normalizeUri();
//    }
    if (errorCode == HintCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE) {
      await _addFix_importAsync();
      await _addFix_updateSdkConstraints('2.1.0');
    }
    if (errorCode == HintCode.SDK_VERSION_SET_LITERAL) {
      await _addFix_updateSdkConstraints('2.2.0');
    }
    if (errorCode == HintCode.SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT ||
        errorCode == HintCode.SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT ||
        errorCode == HintCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT ||
        errorCode == HintCode.SDK_VERSION_GT_GT_GT_OPERATOR ||
        errorCode == HintCode.SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT ||
        errorCode == HintCode.SDK_VERSION_UI_AS_CODE) {
      await _addFix_updateSdkConstraints('2.2.2');
    }
    if (errorCode == HintCode.SDK_VERSION_EXTENSION_METHODS) {
      await _addFix_updateSdkConstraints('2.6.0');
    }
    if (errorCode == HintCode.TYPE_CHECK_IS_NOT_NULL) {
      await _addFix_isNotNull();
    }
    if (errorCode == HintCode.TYPE_CHECK_IS_NULL) {
      await _addFix_isNull();
    }
    if (errorCode == HintCode.UNDEFINED_HIDDEN_NAME ||
        errorCode == HintCode.UNDEFINED_SHOWN_NAME) {
      await _addFix_removeNameFromCombinator();
    }
    if (errorCode == HintCode.UNNECESSARY_CAST) {
      await _addFix_removeUnnecessaryCast();
    }
    // TODO(brianwilkerson) Add a fix to remove the method.
//    if (errorCode == HintCode.UNNECESSARY_NO_SUCH_METHOD) {
//      await _addFix_removeMethodDeclaration();
//    }
    // TODO(brianwilkerson) Add a fix to remove the type check.
//    if (errorCode == HintCode.UNNECESSARY_TYPE_CHECK_FALSE ||
//        errorCode == HintCode.UNNECESSARY_TYPE_CHECK_TRUE) {
//      await _addFix_removeUnnecessaryTypeCheck();
//    }
    if (errorCode == HintCode.UNUSED_CATCH_CLAUSE) {
      await _addFix_removeUnusedCatchClause();
    }
    if (errorCode == HintCode.UNUSED_CATCH_STACK) {
      await _addFix_removeUnusedCatchStack();
    }
    if (errorCode == HintCode.UNUSED_ELEMENT) {
      await _addFix_removeUnusedElement();
    }
    if (errorCode == HintCode.UNUSED_FIELD) {
      await _addFix_removeUnusedField();
    }
    if (errorCode == HintCode.UNUSED_IMPORT) {
      await _addFix_removeUnusedImport();
    }
    if (errorCode == HintCode.UNUSED_LABEL) {
      await _addFix_removeUnusedLabel();
    }
    if (errorCode == HintCode.UNUSED_LOCAL_VARIABLE) {
      await _addFix_removeUnusedLocalVariable();
    }
    if (errorCode == HintCode.UNUSED_SHOWN_NAME) {
      await _addFix_removeNameFromCombinator();
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
    if (errorCode == ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE) {
      await _addFix_addTypeAnnotation();
    }
    if (errorCode == StaticWarningCode.ASSIGNMENT_TO_FINAL) {
      await _addFix_makeFieldNotFinal();
    }
    if (errorCode == StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL) {
      await _addFix_makeVariableNotFinal();
    }
    if (errorCode == StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER) {
      await _addFix_makeEnclosingClassAbstract();
    }
    if (errorCode == CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS ||
        errorCode ==
            CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED) {
      await _addFix_createConstructor_insteadOfSyntheticDefault();
      await _addFix_addMissingParameter();
    }
    if (errorCode == StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR) {
      await _addFix_createConstructor_named();
    }
    if (errorCode == StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER ||
        errorCode ==
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
        errorCode == StaticWarningCode.NOT_A_TYPE ||
        errorCode == StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME) {
      await _addFix_importLibrary_withType();
      await _addFix_createClass();
      await _addFix_createMixin();
      await _addFix_undefinedClass_useSimilar();
    }
    if (errorCode ==
        CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED) {
      await _addFix_convertToNamedArgument();
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
      await _addFix_createMixin();
      await _addFix_createSetter();
      await _addFix_importLibrary_withType();
      await _addFix_importLibrary_withExtension();
      await _addFix_importLibrary_withFunction();
      await _addFix_importLibrary_withTopLevelVariable();
      await _addFix_createLocalVariable();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER) {
      await _addFix_addMissingParameterNamed();
      await _addFix_changeArgumentName();
    }
    if (errorCode == StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE) {
      await _addFix_illegalAsyncReturnType();
    }
    if (errorCode == StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER) {
      await _addFix_useStaticAccess_method();
      await _addFix_useStaticAccess_property();
    }
    if (errorCode == StaticTypeWarningCode.INVALID_ASSIGNMENT) {
      await _addFix_addExplicitCast();
      await _addFix_changeTypeAnnotation();
    }
    if (errorCode ==
        StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION) {
      await _addFix_removeParentheses_inGetterInvocation();
    }
    if (errorCode == StaticTypeWarningCode.NON_BOOL_CONDITION) {
      await _addFix_nonBoolCondition_addNotNull();
    }
    if (errorCode == StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT) {
      await _addFix_importLibrary_withType();
      await _addFix_createClass();
      await _addFix_createMixin();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_FUNCTION) {
      await _addFix_createClass();
      await _addFix_importLibrary_withExtension();
      await _addFix_importLibrary_withFunction();
      await _addFix_importLibrary_withType();
      await _addFix_undefinedFunction_useSimilar();
      await _addFix_undefinedFunction_create();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_GETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createField();
      await _addFix_createGetter();
      await _addFix_createFunction_forFunctionType();
      // TODO(brianwilkerson) The following were added because fasta produces
      // UNDEFINED_GETTER in places where analyzer produced UNDEFINED_IDENTIFIER
      await _addFix_createClass();
      await _addFix_createMixin();
      await _addFix_createLocalVariable();
      await _addFix_importLibrary_withTopLevelVariable();
      await _addFix_importLibrary_withType();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createGetter();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_METHOD) {
      await _addFix_createClass();
      await _addFix_importLibrary_withFunction();
      await _addFix_importLibrary_withType();
      await _addFix_undefinedMethod_useSimilar();
      await _addFix_createMethod();
      await _addFix_undefinedFunction_create();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD) {
      await _addFix_undefinedMethod_useSimilar();
      await _addFix_createMethod();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_SETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createField();
      await _addFix_createSetter();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createSetter();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER) {
      await _addFix_convertFlutterChild();
      await _addFix_convertFlutterChildren();
    }
    if (errorCode ==
        CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD) {
      await _addFix_createField_initializingFormal();
    }
    if (errorCode == CompileTimeErrorCode.CONST_INSTANCE_FIELD) {
      await _addFix_addStatic();
    }
    if (errorCode ==
        StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR) {
      await _addFix_moveTypeArgumentsToClass();
      await _addFix_removeTypeArguments();
    }
    if (errorCode ==
        CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE) {
      await _addFix_extendClassForMixin();
    }
    if (errorCode == StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH) {
      await _addFix_addMissingEnumCaseClauses();
    }
    if (errorCode ==
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER) {
      await _addFix_replaceWithExtensionName();
    }
    if (errorCode ==
        CompileTimeErrorCode
            .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE) {
      await _addFix_qualifyReference();
      // TODO(brianwilkerson) Consider adding fixes to create a field, getter,
      //  method or setter. The existing _addFix methods would need to be
      //  updated so that only the appropriate subset is generated.
    }
    if (errorCode ==
        StaticTypeWarningCode
            .UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER) {
      await _addFix_qualifyReference();
      // TODO(brianwilkerson) Consider adding fixes to create a field, getter,
      //  method or setter. The existing _addFix methods would need to be
      //  updated so that only the appropriate subset is generated.
    }
    // lints
    if (errorCode is LintCode) {
      String name = errorCode.name;
      if (name == LintNames.always_declare_return_types) {
        await _addFix_addReturnType();
      }
      if (name == LintNames.always_specify_types ||
          name == LintNames.type_annotate_public_apis) {
        await _addFix_addTypeAnnotation();
      }
      if (name == LintNames.always_require_non_null_named_parameters) {
        await _addFix_addRequiredAnnotation();
      }
      if (name == LintNames.annotate_overrides) {
        await _addFix_addOverrideAnnotation();
      }
      if (name == LintNames.avoid_annotating_with_dynamic) {
        await _addFix_removeTypeAnnotation();
      }
      if (name == LintNames.avoid_empty_else) {
        await _addFix_removeEmptyElse();
      }
      if (name == LintNames.avoid_init_to_null) {
        await _addFix_removeInitializer();
      }
      if (name == LintNames.avoid_redundant_argument_values) {
        await _addFix_removeArgument();
      }
      if (name == LintNames.avoid_relative_lib_imports) {
        await _addFix_convertToPackageImport();
      }
      if (name == LintNames.avoid_return_types_on_setters) {
        await _addFix_removeTypeAnnotation();
      }
      if (name == LintNames.avoid_types_on_closure_parameters) {
        await _addFix_replaceWithIdentifier();
      }
      if (name == LintNames.await_only_futures) {
        await _addFix_removeAwait();
      }
      if (name == LintNames.curly_braces_in_flow_control_structures) {
        await _addFix_addCurlyBraces();
      }
      if (name == LintNames.diagnostic_describe_all_properties) {
        await _addFix_addDiagnosticPropertyReference();
      }
      if (name == LintNames.empty_catches) {
        await _addFix_removeEmptyCatch();
      }
      if (name == LintNames.empty_constructor_bodies) {
        await _addFix_removeEmptyConstructorBody();
      }
      if (name == LintNames.empty_statements) {
        await _addFix_removeEmptyStatement();
      }
      if (name == LintNames.hash_and_equals) {
        await _addFix_addMissingHashOrEquals();
      }
      if (name == LintNames.no_duplicate_case_values) {
        await _addFix_removeCaseStatement();
      }
      if (name == LintNames.non_constant_identifier_names) {
        await _addFix_renameToCamelCase();
      }
      if (name == LintNames.null_closures) {
        await _addFix_replaceNullWithClosure();
      }
      if (name == LintNames.omit_local_variable_types) {
        await _addFix_replaceWithVar();
      }
      if (name == LintNames.prefer_adjacent_string_concatenation) {
        await _addFix_removeOperator();
      }
      if (name == LintNames.prefer_conditional_assignment) {
        await _addFix_replaceWithConditionalAssignment();
      }
      if (errorCode.name == LintNames.prefer_const_declarations) {
        await _addFix_replaceFinalWithConst();
      }
      if (errorCode.name == LintNames.prefer_expression_function_bodies) {
        await _addFix_convertToExpressionBody();
      }
      if (errorCode.name == LintNames.prefer_for_elements_to_map_fromIterable) {
        await _addFix_convertMapFromIterableToForLiteral();
      }
      if (errorCode.name == LintNames.prefer_equal_for_default_values) {
        await _addFix_replaceColonWithEquals();
      }
      if (name == LintNames.prefer_final_fields) {
        await _addFix_makeVariableFinal();
      }
      if (name == LintNames.prefer_final_locals) {
        await _addFix_makeVariableFinal();
      }
      if (name == LintNames.prefer_generic_function_type_aliases) {
        await _addFix_convertToGenericFunctionSyntax();
      }
      if (errorCode.name ==
          LintNames.prefer_if_elements_to_conditional_expressions) {
        await _addFix_convertConditionalToIfElement();
      }
      if (name == LintNames.prefer_inlined_adds) {
        await _addFix_convertToInlineAdd();
      }
      if (name == LintNames.prefer_int_literals) {
        await _addFix_convertToIntLiteral();
      }
      if (name == LintNames.prefer_is_empty) {
        await _addFix_replaceWithIsEmpty();
      }
      if (name == LintNames.prefer_is_not_empty) {
        await _addFix_isNotEmpty();
      }
      if (errorCode.name == LintNames.prefer_const_constructors) {
        await _addFix_addConst();
        await _addFix_replaceNewWithConst();
      }
      if (errorCode.name == LintNames.prefer_if_null_operators) {
        await _addFix_convertToIfNullOperator();
      }
      if (name == LintNames.prefer_relative_imports) {
        await _addFix_convertToRelativeImport();
      }
      if (name == LintNames.prefer_single_quotes) {
        await _addFix_convertSingleQuotes();
      }
      if (errorCode.name == LintNames.slash_for_doc_comments) {
        await _addFix_convertDocumentationIntoLine();
      }
      if (name == LintNames.prefer_spread_collections) {
        await _addFix_convertAddAllToSpread();
      }
      if (name == LintNames.sort_child_properties_last) {
        await _addFix_sortChildPropertiesLast();
      }
      if (name == LintNames.type_init_formals) {
        await _addFix_removeTypeAnnotation();
      }
      if (name == LintNames.unawaited_futures) {
        await _addFix_addAwait();
      }
      if (name == LintNames.unnecessary_brace_in_string_interps) {
        await _addFix_removeInterpolationBraces();
      }
      if (name == LintNames.unnecessary_const) {
        await _addFix_removeConstKeyword();
      }
      if (name == LintNames.unnecessary_lambdas) {
        await _addFix_replaceWithTearOff();
      }
      if (name == LintNames.unnecessary_new) {
        await _addFix_removeNewKeyword();
      }
      if (name == LintNames.unnecessary_overrides) {
        await _addFix_removeMethodDeclaration();
      }
      if (name == LintNames.unnecessary_this) {
        await _addFix_removeThisExpression();
      }
      if (name == LintNames.use_function_type_syntax_for_parameters) {
        await _addFix_convertToGenericFunctionSyntax();
      }
      if (name == LintNames.use_rethrow_when_possible) {
        await _addFix_replaceWithRethrow();
      }
    }

    await _addFromProducers();

    // done
    return fixes;
  }

  Future<Fix> computeFix() async {
    List<Fix> fixes = await compute();
    fixes.sort(Fix.SORT_BY_RELEVANCE);
    return fixes.isNotEmpty ? fixes.first : null;
  }

  Future<void> _addFix_addAsync() async {
    FunctionBody body = node.thisOrAncestorOfType<FunctionBody>();
    if (body != null && body.keyword == null) {
      TypeProvider typeProvider = this.typeProvider;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.convertFunctionFromSyncToAsync(body, typeProvider);
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.ADD_ASYNC);
    }
  }

  Future<void> _addFix_addAwait() async {
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(node.offset, 'await ');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_AWAIT);
  }

  Future<void> _addFix_addConst() async {
    var node = coveredNode;
    if (node is ConstructorName) {
      node = node.parent;
    }
    if (node is InstanceCreationExpression) {
      if ((node as InstanceCreationExpression).keyword == null) {
        final changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleInsertion(node.offset, 'const ');
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.ADD_CONST);
      }
    }
  }

  Future<void> _addFix_addCurlyBraces() async {
    final changeBuilder = await createBuilder_useCurlyBraces();
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_CURLY_BRACES);
  }

  Future<void> _addFix_addDiagnosticPropertyReference() async {
    final changeBuilder = await createBuilder_addDiagnosticPropertyReference();
    _addFixFromBuilder(
        changeBuilder, DartFixKind.ADD_DIAGNOSTIC_PROPERTY_REFERENCE);
  }

  Future<void> _addFix_addExplicitCast() async {
    if (coveredNode is! Expression) {
      return;
    }
    Expression target = coveredNode;
    DartType fromType = target.staticType;
    DartType toType;
    AstNode parent = target.parent;
    if (parent is AssignmentExpression && target == parent.rightHandSide) {
      toType = parent.leftHandSide.staticType;
    } else if (parent is VariableDeclaration && target == parent.initializer) {
      toType = parent.declaredElement.type;
    } else {
      // TODO(brianwilkerson) Handle function arguments.
      return;
    }
    // TODO(brianwilkerson) Handle `toSet` in a manner similar to the below.
    if (_isToListMethodInvocation(target)) {
      Expression targetTarget = (target as MethodInvocation).target;
      if (targetTarget != null) {
        DartType targetTargetType = targetTarget.staticType;
        if (_isDartCoreIterable(targetTargetType) ||
            _isDartCoreList(targetTargetType) ||
            _isDartCoreMap(targetTargetType) ||
            _isDartCoreSet(targetTargetType)) {
          target = targetTarget;
          fromType = targetTargetType;
        }
      }
    }
    if (target is AsExpression) {
      // TODO(brianwilkerson) Consider updating the right operand.
      return;
    }
    bool needsParentheses = target.precedence < Precedence.postfix;
    if (((_isDartCoreIterable(fromType) || _isDartCoreList(fromType)) &&
            _isDartCoreList(toType)) ||
        (_isDartCoreSet(fromType) && _isDartCoreSet(toType))) {
      if (_isCastMethodInvocation(target)) {
        // TODO(brianwilkerson) Consider updating the type arguments to the
        // `cast` invocation.
        return;
      }
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target.offset, '(');
        }
        builder.addInsertion(target.end, (DartEditBuilder builder) {
          if (needsParentheses) {
            builder.write(')');
          }
          builder.write('.cast<');
          builder.writeType((toType as InterfaceType).typeArguments[0]);
          builder.write('>()');
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.ADD_EXPLICIT_CAST);
    } else if (_isDartCoreMap(fromType) && _isDartCoreMap(toType)) {
      if (_isCastMethodInvocation(target)) {
        // TODO(brianwilkerson) Consider updating the type arguments to the
        // `cast` invocation.
        return;
      }
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target.offset, '(');
        }
        builder.addInsertion(target.end, (DartEditBuilder builder) {
          if (needsParentheses) {
            builder.write(')');
          }
          builder.write('.cast<');
          builder.writeType((toType as InterfaceType).typeArguments[0]);
          builder.write(', ');
          builder.writeType((toType as InterfaceType).typeArguments[1]);
          builder.write('>()');
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.ADD_EXPLICIT_CAST);
    } else {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target.offset, '(');
        }
        builder.addInsertion(target.end, (DartEditBuilder builder) {
          if (needsParentheses) {
            builder.write(')');
          }
          builder.write(' as ');
          builder.writeType(toType);
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.ADD_EXPLICIT_CAST);
    }
  }

  Future<void> _addFix_addMissingEnumCaseClauses() async {
    SwitchStatement statement = node as SwitchStatement;
    String enumName;
    List<String> enumConstantNames = [];
    DartType expressionType = statement.expression.staticType;
    if (expressionType is InterfaceType) {
      ClassElement enumElement = expressionType.element;
      if (enumElement.isEnum) {
        enumName = enumElement.name;
        for (FieldElement field in enumElement.fields) {
          if (!field.isSynthetic) {
            enumConstantNames.add(field.name);
          }
        }
      }
    }
    if (enumName == null) {
      return;
    }
    for (SwitchMember member in statement.members) {
      if (member is SwitchCase) {
        Expression expression = member.expression;
        if (expression is Identifier) {
          Element element = expression.staticElement;
          if (element is PropertyAccessorElement) {
            enumConstantNames.remove(element.name);
          }
        }
      }
    }
    if (enumConstantNames.isEmpty) {
      return;
    }

    String statementIndent = utils.getLinePrefix(statement.offset);
    String singleIndent = utils.getIndent(1);

    DartChangeBuilder changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(utils.getLineThis(statement.end), (builder) {
        for (String constantName in enumConstantNames) {
          builder.write(statementIndent);
          builder.write(singleIndent);
          builder.write('case ');
          builder.write(enumName);
          builder.write('.');
          builder.write(constantName);
          builder.writeln(':');
          builder.write(statementIndent);
          builder.write(singleIndent);
          builder.write(singleIndent);
          builder.writeln('// TODO: Handle this case.');
          builder.write(statementIndent);
          builder.write(singleIndent);
          builder.write(singleIndent);
          builder.writeln('break;');
        }
      });
    });
    _addFixFromBuilder(
        changeBuilder, DartFixKind.ADD_MISSING_ENUM_CASE_CLAUSES);
  }

  Future<void> _addFix_addMissingHashOrEquals() async {
    final methodDecl = node.thisOrAncestorOfType<MethodDeclaration>();
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (methodDecl != null && classDecl != null) {
      final classElement = classDecl.declaredElement;

      var element;
      var memberName;
      if (methodDecl.name.name == 'hashCode') {
        memberName = '==';
        element = classElement.lookUpInheritedMethod(
            memberName, classElement.library);
      } else {
        memberName = 'hashCode';
        element = classElement.lookUpInheritedConcreteGetter(
            memberName, classElement.library);
      }

      final location =
          utils.prepareNewClassMemberLocation(classDecl, (_) => true);

      final changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (fileBuilder) {
        fileBuilder.addInsertion(location.offset, (builder) {
          builder.write(location.prefix);
          builder.writeOverride(element, invokeSuper: true);
          builder.write(location.suffix);
        });
      });

      changeBuilder.setSelection(Position(file, location.offset));
      _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_METHOD,
          args: [memberName]);
    }
  }

  Future<void> _addFix_addMissingParameter() async {
    // The error is reported on ArgumentList.
    if (node is! ArgumentList) {
      return;
    }
    ArgumentList argumentList = node;
    List<Expression> arguments = argumentList.arguments;

    // Prepare the invoked element.
    var context = _ExecutableParameters(sessionHelper, node.parent);
    if (context == null) {
      return;
    }

    // prepare the argument to add a new parameter for
    int numRequired = context.required.length;
    if (numRequired >= arguments.length) {
      return;
    }
    Expression argument = arguments[numRequired];

    Future<void> addParameter(
        FixKind kind, int offset, String prefix, String suffix) async {
      if (offset != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(context.file, (builder) {
          builder.addInsertion(offset, (builder) {
            builder.write(prefix);
            builder.writeParameterMatchingArgument(
                argument, numRequired, <String>{});
            builder.write(suffix);
          });
        });
        _addFixFromBuilder(changeBuilder, kind);
      }
    }

    // Suggest adding a required parameter.
    {
      var kind = DartFixKind.ADD_MISSING_PARAMETER_REQUIRED;
      if (context.required.isNotEmpty) {
        var prevNode = await context.getParameterNode(context.required.last);
        await addParameter(kind, prevNode?.end, ', ', '');
      } else {
        var parameterList = await context.getParameterList();
        var offset = parameterList?.leftParenthesis?.end;
        var suffix = context.executable.parameters.isNotEmpty ? ', ' : '';
        await addParameter(kind, offset, '', suffix);
      }
    }

    // Suggest adding the first optional positional parameter.
    if (context.optionalPositional.isEmpty && context.named.isEmpty) {
      var kind = DartFixKind.ADD_MISSING_PARAMETER_POSITIONAL;
      var prefix = context.required.isNotEmpty ? ', [' : '[';
      if (context.required.isNotEmpty) {
        var prevNode = await context.getParameterNode(context.required.last);
        await addParameter(kind, prevNode?.end, prefix, ']');
      } else {
        var parameterList = await context.getParameterList();
        var offset = parameterList?.leftParenthesis?.end;
        await addParameter(kind, offset, prefix, ']');
      }
    }
  }

  Future<void> _addFix_addMissingParameterNamed() async {
    // Prepare the name of the missing parameter.
    if (this.node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier node = this.node;
    String name = node.name;

    // We expect that the node is part of a NamedExpression.
    if (node.parent?.parent is! NamedExpression) {
      return;
    }
    NamedExpression namedExpression = node.parent.parent;

    // We should be in an ArgumentList.
    if (namedExpression.parent is! ArgumentList) {
      return;
    }
    AstNode argumentList = namedExpression.parent;

    // Prepare the invoked element.
    var context = _ExecutableParameters(sessionHelper, argumentList.parent);
    if (context == null) {
      return;
    }

    // We cannot add named parameters when there are positional positional.
    if (context.optionalPositional.isNotEmpty) {
      return;
    }

    Future<void> addParameter(int offset, String prefix, String suffix) async {
      if (offset != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(context.file, (builder) {
          builder.addInsertion(offset, (builder) {
            builder.write(prefix);
            builder
                .writeParameterMatchingArgument(namedExpression, 0, <String>{});
            builder.write(suffix);
          });
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.ADD_MISSING_PARAMETER_NAMED,
            args: [name]);
      }
    }

    if (context.named.isNotEmpty) {
      var prevNode = await context.getParameterNode(context.named.last);
      await addParameter(prevNode?.end, ', ', '');
    } else if (context.required.isNotEmpty) {
      var prevNode = await context.getParameterNode(context.required.last);
      await addParameter(prevNode?.end, ', {', '}');
    } else {
      var parameterList = await context.getParameterList();
      await addParameter(parameterList?.leftParenthesis?.end, '{', '}');
    }
  }

  Future<void> _addFix_addMissingRequiredArgument() async {
    InstanceCreationExpression creation;
    Element targetElement;
    ArgumentList argumentList;

    if (node is SimpleIdentifier) {
      AstNode invocation = node.parent;
      if (invocation is MethodInvocation) {
        targetElement = invocation.methodName.staticElement;
        argumentList = invocation.argumentList;
      } else {
        creation =
            invocation.thisOrAncestorOfType<InstanceCreationExpression>();
        if (creation != null) {
          targetElement = creation.staticElement;
          argumentList = creation.argumentList;
        }
      }
    }

    if (targetElement is ExecutableElement) {
      // Format: "Missing required argument 'foo"
      List<String> messageParts = error.message.split("'");
      if (messageParts.length < 2) {
        return;
      }
      String missingParameterName = messageParts[1];

      ParameterElement missingParameter = targetElement.parameters.firstWhere(
          (p) => p.name == missingParameterName,
          orElse: () => null);
      if (missingParameter == null) {
        return;
      }

      int offset;
      bool hasTrailingComma = false;
      bool insertBetweenParams = false;
      List<Expression> arguments = argumentList.arguments;
      if (arguments.isEmpty) {
        offset = argumentList.leftParenthesis.end;
      } else {
        Expression lastArgument = arguments.last;
        offset = lastArgument.end;
        hasTrailingComma = lastArgument.endToken.next.type == TokenType.COMMA;

        if (lastArgument is NamedExpression &&
            flutter.isWidgetExpression(creation)) {
          if (flutter.isChildArgument(lastArgument) ||
              flutter.isChildrenArgument(lastArgument)) {
            offset = lastArgument.offset;
            hasTrailingComma = true;
            insertBetweenParams = true;
          }
        }
      }

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(offset, (DartEditBuilder builder) {
          if (arguments.isNotEmpty && !insertBetweenParams) {
            builder.write(', ');
          }

          builder.write('$missingParameterName: ');

          DefaultArgument defaultValue =
              getDefaultStringParameterValue(missingParameter);
          // Use defaultValue.cursorPosition if it's not null.
          if (defaultValue?.cursorPosition != null) {
            builder.write(
                defaultValue.text.substring(0, defaultValue.cursorPosition));
            builder.selectHere();
            builder.write(
                defaultValue.text.substring(defaultValue.cursorPosition));
          } else {
            builder.addSimpleLinkedEdit('VALUE', defaultValue?.text);
          }

          if (flutter.isWidgetExpression(creation)) {
            // Insert a trailing comma after Flutter instance creation params.
            if (!hasTrailingComma) {
              builder.write(',');
            } else if (insertBetweenParams) {
              builder.writeln(',');

              // Insert indent before the child: or children: param.
              String indent = utils.getLinePrefix(offset);
              builder.write(indent);
            }
          }
        });
      });
      _addFixFromBuilder(
          changeBuilder, DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
          args: [missingParameterName]);
    }
  }

  Future<void> _addFix_addOverrideAnnotation() async {
    ClassMember member = node.thisOrAncestorOfType<ClassMember>();
    if (member == null) {
      return;
    }

    //TODO(pq): migrate annotation edit building to change_builder

    // Handle doc comments.
    Token token = member.beginToken;
    if (token is CommentToken) {
      token = (token as CommentToken).parent;
    }

    Position exitPosition = Position(file, token.offset - 1);
    String indent = utils.getIndent(1);
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
          range.startLength(token, 0), '@override$eol$indent');
    });
    changeBuilder.setSelection(exitPosition);
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_OVERRIDE);
  }

  Future<void> _addFix_addRequiredAnnotation() async {
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(node.parent.offset, '@required ');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_REQUIRED);
  }

  Future<void> _addFix_addReturnType() async {
    var changeBuilder = await createBuilder_addReturnType();
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_RETURN_TYPE);
  }

  Future<void> _addFix_addStatic() async {
    FieldDeclaration declaration =
        node.thisOrAncestorOfType<FieldDeclaration>();
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(declaration.offset, 'static ');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_STATIC);
  }

  Future<void> _addFix_addTypeAnnotation() async {
    var changeBuilder =
        await createBuilder_addTypeAnnotation_DeclaredIdentifier();
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_TYPE_ANNOTATION);

    changeBuilder =
        await createBuilder_addTypeAnnotation_SimpleFormalParameter();
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_TYPE_ANNOTATION);

    changeBuilder = await createBuilder_addTypeAnnotation_VariableDeclaration();
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_TYPE_ANNOTATION);
  }

  Future<void> _addFix_boolInsteadOfBoolean() async {
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.error(error), 'bool');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_BOOLEAN_WITH_BOOL);
  }

  Future<void> _addFix_canBeNullAfterNullAware() async {
    AstNode node = coveredNode;
    if (node is Expression) {
      var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_changeArgumentName() async {
    const int maxDistance = 4;

    List<String> getNamedParameterNames() {
      AstNode namedExpression = node?.parent?.parent;
      if (node is SimpleIdentifier &&
          namedExpression is NamedExpression &&
          namedExpression.name == node.parent &&
          namedExpression.parent is ArgumentList) {
        var parameters = _ExecutableParameters(
          sessionHelper,
          namedExpression.parent.parent,
        );
        return parameters?.namedNames;
      }
      return null;
    }

    int computeDistance(String current, String proposal) {
      if ((current == 'child' && proposal == 'children') ||
          (current == 'children' && proposal == 'child')) {
        // Special case handling for 'child' and 'children' is unnecessary if
        // `maxDistance >= 3`, but is included to prevent regression in case the
        // value is changed to improve results.
        return 1;
      }
      return levenshtein(current, proposal, maxDistance, caseSensitive: false);
    }

    List<String> names = getNamedParameterNames();
    if (names == null || names.isEmpty) {
      return;
    }

    SimpleIdentifier argumentName = node;
    String invalidName = argumentName.name;
    for (String proposedName in names) {
      int distance = computeDistance(invalidName, proposedName);
      if (distance <= maxDistance) {
        DartChangeBuilder changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.node(argumentName), proposedName);
        });
        // TODO(brianwilkerson) Create a way to use the distance as part of the
        //  computation of the priority (so that closer names sort first).
        _addFixFromBuilder(changeBuilder, DartFixKind.CHANGE_ARGUMENT_NAME,
            args: [proposedName]);
      }
    }
  }

  Future<void> _addFix_changeToNearestPreciseValue() async {
    IntegerLiteral integer = node;
    String lexeme = integer.literal.lexeme;
    BigInt precise = BigInt.from(IntegerLiteralImpl.nearestValidDouble(lexeme));
    String correction = lexeme.toLowerCase().contains('x')
        ? '0x${precise.toRadixString(16).toUpperCase()}'
        : precise.toString();
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(integer), correction);
    });
    _addFixFromBuilder(
        changeBuilder, DartFixKind.CHANGE_TO_NEAREST_PRECISE_VALUE,
        args: [correction]);
  }

  Future<void> _addFix_changeTypeAnnotation() async {
    AstNode declaration = coveredNode.parent;
    if (declaration is VariableDeclaration &&
        declaration.initializer == coveredNode) {
      AstNode variableList = declaration.parent;
      if (variableList is VariableDeclarationList &&
          variableList.variables.length == 1) {
        TypeAnnotation typeNode = variableList.type;
        if (typeNode != null) {
          Expression initializer = coveredNode;
          DartType newType = initializer.staticType;
          if (newType is InterfaceType || newType is FunctionType) {
            var changeBuilder = _newDartChangeBuilder();
            await changeBuilder.addFileEdit(file,
                (DartFileEditBuilder builder) {
              builder.addReplacement(range.node(typeNode),
                  (DartEditBuilder builder) {
                builder.writeType(newType);
              });
            });
            _addFixFromBuilder(
              changeBuilder,
              DartFixKind.CHANGE_TYPE_ANNOTATION,
              args: [
                typeNode.type.getDisplayString(withNullability: false),
                newType.getDisplayString(withNullability: false),
              ],
            );
          }
        }
      }
    }
  }

  Future<void> _addFix_convertAddAllToSpread() async {
    final change = await createBuilder_convertAddAllToSpread();
    if (change != null) {
      final kind = change.isLineInvocation
          ? DartFixKind.INLINE_INVOCATION
          : DartFixKind.CONVERT_TO_SPREAD;
      _addFixFromBuilder(change.builder, kind, args: change.args);
    }
  }

  Future<void> _addFix_convertConditionalToIfElement() async {
    final changeBuilder =
        await createBuilder_convertConditionalExpressionToIfElement();
    _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_TO_IF_ELEMENT);
  }

  Future<void> _addFix_convertDocumentationIntoLine() async {
    final changeBuilder = await createBuilder_convertDocumentationIntoLine();
    _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_TO_LINE_COMMENT);
  }

  Future<void> _addFix_convertFlutterChild() async {
    NamedExpression named = flutter.findNamedExpression(node, 'child');
    if (named == null) {
      return;
    }

    // child: widget
    Expression expression = named.expression;
    if (flutter.isWidgetExpression(expression)) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        flutter.convertChildToChildren2(
            builder,
            expression,
            named,
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

    // child: [widget1, widget2]
    if (expression is ListLiteral &&
        expression.elements.every(flutter.isWidgetExpression)) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(range.node(named.name), 'children:');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_FLUTTER_CHILD);
    }
  }

  Future<void> _addFix_convertFlutterChildren() async {
    AstNode node = this.node;
    if (node is SimpleIdentifier &&
        node.name == 'children' &&
        node.parent?.parent is NamedExpression) {
      NamedExpression named = node.parent?.parent;
      Expression expression = named.expression;
      if (expression is ListLiteral && expression.elements.length == 1) {
        CollectionElement widget = expression.elements[0];
        if (flutter.isWidgetExpression(widget)) {
          String widgetText = utils.getNodeText(widget);
          String indentOld = utils.getLinePrefix(widget.offset);
          String indentNew = utils.getLinePrefix(named.offset);
          widgetText = _replaceSourceIndent(widgetText, indentOld, indentNew);

          var builder = _newDartChangeBuilder();
          await builder.addFileEdit(file, (builder) {
            builder.addReplacement(range.node(named), (builder) {
              builder.write('child: ');
              builder.write(widgetText);
            });
          });
          _addFixFromBuilder(builder, DartFixKind.CONVERT_FLUTTER_CHILDREN);
        }
      }
    }
  }

  Future<void> _addFix_convertMapFromIterableToForLiteral() async {
    final changeBuilder =
        await createBuilder_convertMapFromIterableToForLiteral();
    _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_TO_FOR_ELEMENT);
  }

  Future<void> _addFix_convertSingleQuotes() async {
    final changeBuilder = await createBuilder_convertQuotes(true);
    _addFixFromBuilder(
        changeBuilder, DartFixKind.CONVERT_TO_SINGLE_QUOTED_STRING);
  }

  Future<void> _addFix_convertToExpressionBody() async {
    final changeBuilder = await createBuilder_convertToExpressionFunctionBody();
    _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_INTO_EXPRESSION_BODY);
  }

  Future<void> _addFix_convertToGenericFunctionSyntax() async {
    var changeBuilder = await createBuilder_convertToGenericFunctionSyntax();
    _addFixFromBuilder(
        changeBuilder, DartFixKind.CONVERT_TO_GENERIC_FUNCTION_SYNTAX);
  }

  Future<void> _addFix_convertToIfNullOperator() async {
    var conditional = node.thisOrAncestorOfType<ConditionalExpression>();
    if (conditional == null) {
      return;
    }
    var condition = conditional.condition as BinaryExpression;
    Expression nullableExpression;
    Expression defaultExpression;
    if (condition.operator.type == TokenType.EQ_EQ) {
      nullableExpression = conditional.elseExpression;
      defaultExpression = conditional.thenExpression;
    } else {
      nullableExpression = conditional.thenExpression;
      defaultExpression = conditional.elseExpression;
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(conditional), (builder) {
        builder.write(utils.getNodeText(nullableExpression));
        builder.write(' ?? ');
        builder.write(utils.getNodeText(defaultExpression));
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_TO_IF_NULL);
  }

  Future<void> _addFix_convertToInlineAdd() async {
    final changeBuilder = await createBuilder_inlineAdd();
    _addFixFromBuilder(changeBuilder, DartFixKind.INLINE_INVOCATION,
        args: ['add']);
  }

  Future<void> _addFix_convertToIntLiteral() async {
    final changeBuilder = await createBuilder_convertToIntLiteral();
    _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_TO_INT_LITERAL);
  }

  Future<void> _addFix_convertToNamedArgument() async {
    var argumentList = node;
    if (argumentList is ArgumentList) {
      // Prepare parameters.
      List<ParameterElement> parameters;
      var parent = argumentList.parent;
      if (parent is FunctionExpressionInvocation) {
        var invokeType = parent.staticInvokeType;
        if (invokeType is FunctionType) {
          parameters = invokeType.parameters;
        }
      } else if (parent is InstanceCreationExpression) {
        parameters = parent.staticElement?.parameters;
      } else if (parent is MethodInvocation) {
        var invokeType = parent.staticInvokeType;
        if (invokeType is FunctionType) {
          parameters = invokeType.parameters;
        }
      }
      if (parameters == null) {
        return;
      }

      // Prepare named parameters.
      int numberOfPositionalParameters = 0;
      var namedParameters = <ParameterElement>[];
      for (var parameter in parameters) {
        if (parameter.isNamed) {
          namedParameters.add(parameter);
        } else {
          numberOfPositionalParameters++;
        }
      }
      if (argumentList.arguments.length <= numberOfPositionalParameters) {
        return;
      }

      // Find named parameters for extra arguments.
      var argumentToParameter = <Expression, ParameterElement>{};
      Iterable<Expression> extraArguments =
          argumentList.arguments.skip(numberOfPositionalParameters);
      for (var argument in extraArguments) {
        if (argument is! NamedExpression) {
          ParameterElement uniqueNamedParameter;
          for (var namedParameter in namedParameters) {
            if (typeSystem.isSubtypeOf(
                argument.staticType, namedParameter.type)) {
              if (uniqueNamedParameter == null) {
                uniqueNamedParameter = namedParameter;
              } else {
                uniqueNamedParameter = null;
                break;
              }
            }
          }
          if (uniqueNamedParameter != null) {
            argumentToParameter[argument] = uniqueNamedParameter;
            namedParameters.remove(uniqueNamedParameter);
          }
        }
      }
      if (argumentToParameter.isEmpty) {
        return;
      }

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        for (var argument in argumentToParameter.keys) {
          var parameter = argumentToParameter[argument];
          builder.addSimpleInsertion(argument.offset, '${parameter.name}: ');
        }
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_TO_NAMED_ARGUMENTS);
    }
  }

  Future<void> _addFix_convertToPackageImport() async {
    final changeBuilder = await createBuilder_convertToPackageImport();
    _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_TO_PACKAGE_IMPORT);
  }

  Future<void> _addFix_convertToRelativeImport() async {
    final changeBuilder = await createBuilder_convertToRelativeImport();
    _addFixFromBuilder(changeBuilder, DartFixKind.CONVERT_TO_RELATIVE_IMPORT);
  }

  Future<void> _addFix_createClass() async {
    Element prefixElement;
    String name;
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
      targetUnit = unit.declaredElement;
      CompilationUnitMember enclosingMember = node.thisOrAncestorMatching(
          (node) =>
              node is CompilationUnitMember && node.parent is CompilationUnit);
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
            try {
              offset = targetSource.contents.data.length;
              filePath = targetSource.fullName;
              prefix = '$eol';
              suffix = '$eol';
            } on FileSystemException {
              // If we can't read the file to get the offset, then we can't
              // create a fix.
            }
            break;
          }
        }
      }
    }
    if (offset < 0) {
      return;
    }
    var changeBuilder = _newDartChangeBuilder();
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

  /// Here we handle cases when there are no constructors in a class, and the
  /// class has uninitialized final fields.
  Future<void> _addFix_createConstructor_forUninitializedFinalFields() async {
    if (node is! SimpleIdentifier || node.parent is! VariableDeclaration) {
      return;
    }

    ClassDeclaration classDeclaration =
        node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration == null) {
      return;
    }
    String className = classDeclaration.name.name;
    InterfaceType superType = classDeclaration.declaredElement.supertype;

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

    var changeBuilder = _newDartChangeBuilder();
    if (flutter.isExactlyStatelessWidgetType(superType) ||
        flutter.isExactlyStatefulWidgetType(superType)) {
      // Specialize for Flutter widgets.
      ClassElement keyClass =
          await sessionHelper.getClass(flutter.widgetsUri, 'Key');
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
          builder.write(targetLocation.prefix);
          builder.write('const ');
          builder.write(className);
          builder.write('({');
          builder.writeType(
            keyClass.instantiate(
              typeArguments: const [],
              nullabilitySuffix: _isNonNullable
                  ? NullabilitySuffix.question
                  : NullabilitySuffix.star,
            ),
          );
          builder.write(' key');

          List<String> childrenFields = [];
          for (String fieldName in fieldNames) {
            if (fieldName == 'child' || fieldName == 'children') {
              childrenFields.add(fieldName);
              continue;
            }
            builder.write(', this.');
            builder.write(fieldName);
          }
          for (String fieldName in childrenFields) {
            builder.write(', this.');
            builder.write(fieldName);
          }

          builder.write('}) : super(key: key);');
          builder.write(targetLocation.suffix);
        });
      });
    } else {
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
          builder.write(targetLocation.prefix);
          builder.writeConstructorDeclaration(className,
              fieldNames: fieldNames);
          builder.write(targetLocation.suffix);
        });
      });
    }
    _addFixFromBuilder(
        changeBuilder, DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS);
  }

  Future<void> _addFix_createConstructor_insteadOfSyntheticDefault() async {
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

    // prepare target ClassDeclaration
    var targetElement = constructorElement.enclosingElement;
    var targetResult = await sessionHelper.getElementDeclaration(targetElement);
    if (targetResult.node is! ClassOrMixinDeclaration) {
      return;
    }
    ClassOrMixinDeclaration targetNode = targetResult.node;

    // prepare location
    var targetLocation = CorrectionUtils(targetResult.resolvedUnit)
        .prepareNewConstructorLocation(targetNode);

    Source targetSource = targetElement.source;
    String targetFile = targetSource.fullName;
    var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_createConstructor_named() async {
    SimpleIdentifier name;
    ConstructorName constructorName;
    InstanceCreationExpression instanceCreation;
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

    // prepare target ClassDeclaration
    ClassElement targetElement = targetType.element;
    var targetResult = await sessionHelper.getElementDeclaration(targetElement);
    if (targetResult.node is! ClassOrMixinDeclaration) {
      return;
    }
    ClassOrMixinDeclaration targetNode = targetResult.node;

    // prepare location
    var targetLocation = CorrectionUtils(targetResult.resolvedUnit)
        .prepareNewConstructorLocation(targetNode);

    String targetFile = targetElement.source.fullName;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
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

  Future<void> _addFix_createConstructorSuperExplicit() async {
    if (node.parent is! ConstructorDeclaration ||
        node.parent.parent is! ClassDeclaration) {
      return;
    }
    ConstructorDeclaration targetConstructor =
        node.parent as ConstructorDeclaration;
    ClassDeclaration targetClassNode =
        targetConstructor.parent as ClassDeclaration;
    ClassElement targetClassElement = targetClassNode.declaredElement;
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
      var changeBuilder = _newDartChangeBuilder();
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
            if (parameter.isOptional) {
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

  Future<void> _addFix_createConstructorSuperImplicit() async {
    ClassDeclaration targetClassNode =
        node.thisOrAncestorOfType<ClassDeclaration>();
    ClassElement targetClassElement = targetClassNode.declaredElement;
    InterfaceType superType = targetClassElement.supertype;
    String targetClassName = targetClassElement.name;
    // add proposals for all super constructors
    for (ConstructorElement superConstructor in superType.constructors) {
      String constructorName = superConstructor.name;
      // skip private
      if (Identifier.isPrivateName(constructorName)) {
        continue;
      }
      // prepare parameters and arguments
      Iterable<ParameterElement> requiredParameters = superConstructor
          .parameters
          .where((parameter) => parameter.isRequiredPositional);
      // add proposal
      ClassMemberLocation targetLocation =
          utils.prepareNewConstructorLocation(targetClassNode);
      String proposalName = _getConstructorProposalName(superConstructor);
      var changeBuilder = _newDartChangeBuilder();
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
          if (constructorName.isNotEmpty) {
            builder.write('.');
            builder.addSimpleLinkedEdit('NAME', constructorName);
          }
          builder.write('(');
          writeParameters(true);
          builder.write(') : super');
          if (constructorName.isNotEmpty) {
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

  Future<void> _addFix_createField() async {
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
      targetClassElement = _getTargetClassElement(target);
      // maybe static
      if (target is Identifier) {
        Identifier targetIdentifier = target;
        Element targetElement = targetIdentifier.staticElement;
        if (targetElement == null) {
          return;
        }
        staticModifier = targetElement.kind == ElementKind.CLASS;
      }
    } else {
      targetClassElement = getEnclosingClassElement(node);
      staticModifier = _inStaticContext();
    }
    if (targetClassElement == null) {
      return;
    }
    if (targetClassElement.librarySource.isInSystemLibrary) {
      return;
    }
    utils.targetClassElement = targetClassElement;
    // prepare target ClassDeclaration
    var targetDeclarationResult =
        await sessionHelper.getElementDeclaration(targetClassElement);
    if (targetDeclarationResult.node is! ClassOrMixinDeclaration) {
      return;
    }
    ClassOrMixinDeclaration targetNode = targetDeclarationResult.node;
    // prepare location
    ClassMemberLocation targetLocation =
        CorrectionUtils(targetDeclarationResult.resolvedUnit)
            .prepareNewFieldLocation(targetNode);
    // build field source
    Source targetSource = targetClassElement.source;
    String targetFile = targetSource.fullName;
    var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_createField_initializingFormal() async {
    //
    // Ensure that we are in an initializing formal parameter.
    //
    FieldFormalParameter parameter =
        node.thisOrAncestorOfType<FieldFormalParameter>();
    if (parameter == null) {
      return;
    }
    ClassDeclaration targetClassNode =
        parameter.thisOrAncestorOfType<ClassDeclaration>();
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
    var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_createFunction_forFunctionType() async {
    if (node is SimpleIdentifier) {
      SimpleIdentifier nameNode = node as SimpleIdentifier;
      // prepare argument expression (to get parameter)
      ClassElement targetElement;
      Expression argument;
      {
        Expression target = getQualifiedPropertyTarget(node);
        if (target != null) {
          DartType targetType = target.staticType;
          if (targetType != null && targetType.element is ClassElement) {
            targetElement = targetType.element as ClassElement;
            argument = target.parent as Expression;
          } else {
            return;
          }
        } else {
          ClassOrMixinDeclaration enclosingClass =
              node.thisOrAncestorOfType<ClassOrMixinDeclaration>();
          targetElement = enclosingClass?.declaredElement;
          argument = nameNode;
        }
      }
      argument = stepUpNamedExpression(argument);
      // should be argument of some invocation
      ParameterElement parameterElement = argument.staticParameterElement;
      if (parameterElement == null) {
        return;
      }
      // should be parameter of function type
      DartType parameterType = parameterElement.type;
      if (parameterType is InterfaceType && parameterType.isDartCoreFunction) {
        parameterType = FunctionTypeImpl(
          typeFormals: const [],
          parameters: const [],
          returnType: typeProvider.dynamicType,
          nullabilitySuffix: NullabilitySuffix.none,
        );
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

  Future<void> _addFix_createGetter() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier nameNode = node;
    String name = nameNode.name;
    if (!nameNode.inGetterContext()) {
      return;
    }
    // prepare target
    Expression target;
    {
      AstNode nameParent = nameNode.parent;
      if (nameParent is PrefixedIdentifier) {
        target = nameParent.prefix;
      } else if (nameParent is PropertyAccess) {
        target = nameParent.realTarget;
      }
    }
    // prepare target element
    bool staticModifier = false;
    Element targetElement;
    if (target is ExtensionOverride) {
      targetElement = target.staticElement;
    } else if (target is Identifier &&
        target.staticElement is ExtensionElement) {
      targetElement = target.staticElement;
      staticModifier = true;
    } else if (target != null) {
      // prepare target interface type
      DartType targetType = target.staticType;
      if (targetType is! InterfaceType) {
        return;
      }
      targetElement = targetType.element;
      // maybe static
      if (target is Identifier) {
        Identifier targetIdentifier = target;
        Element targetElement = targetIdentifier.staticElement;
        staticModifier = targetElement?.kind == ElementKind.CLASS;
      }
    } else {
      targetElement =
          getEnclosingClassElement(node) ?? getEnclosingExtensionElement(node);
      if (targetElement == null) {
        return;
      }
      staticModifier = _inStaticContext();
    }
    if (targetElement.librarySource.isInSystemLibrary) {
      return;
    }
    // prepare target declaration
    var targetDeclarationResult =
        await sessionHelper.getElementDeclaration(targetElement);
    if (targetDeclarationResult == null) {
      return;
    }
    if (targetDeclarationResult.node is! ClassOrMixinDeclaration &&
        targetDeclarationResult.node is! ExtensionDeclaration) {
      return;
    }
    CompilationUnitMember targetNode = targetDeclarationResult.node;
    // prepare location
    ClassMemberLocation targetLocation =
        CorrectionUtils(targetDeclarationResult.resolvedUnit)
            .prepareNewGetterLocation(targetNode);
    // build method source
    Source targetSource = targetElement.source;
    String targetFile = targetSource.fullName;
    var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_createImportUri() async {
    // TODO(brianwilkerson) Generalize this to allow other valid string literals.
    // TODO(brianwilkerson) Support the case where the node's parent is a Configuration.
    if (node is SimpleStringLiteral && node.parent is ImportDirective) {
      ImportDirective importDirective = node.parent;
      Source source = importDirective.uriSource;
      if (source != null) {
        String file = source.fullName;
        if (isAbsolute(file) && AnalysisEngine.isDartFileName(file)) {
          var changeBuilder = _newDartChangeBuilder();
          await changeBuilder.addFileEdit(source.fullName, (builder) {
            builder.addSimpleInsertion(0, '// TODO Implement this library.');
          });
          _addFixFromBuilder(
            changeBuilder,
            DartFixKind.CREATE_FILE,
            args: [source.shortName],
          );
        }
      }
    }
  }

  Future<void> _addFix_createLocalVariable() async {
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
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleInsertion(node.offset, 'var ');
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_LOCAL_VARIABLE,
            args: [name]);
        return;
      }
    }
    // prepare target Statement
    Statement target = node.thisOrAncestorOfType<Statement>();
    if (target == null) {
      return;
    }
    String prefix = utils.getNodePrefix(target);
    // compute type
    DartType type = _inferUndefinedExpressionType(node);
    if (!(type == null || type is InterfaceType || type is FunctionType)) {
      return;
    }
    // build variable declaration source
    var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_createMethod() async {
    if (node is! SimpleIdentifier || node.parent is! MethodInvocation) {
      return;
    }
    String name = (node as SimpleIdentifier).name;
    MethodInvocation invocation = node.parent as MethodInvocation;
    // prepare environment
    Element targetElement;
    bool staticModifier = false;

    CompilationUnitMember targetNode;
    Expression target = invocation.realTarget;
    CorrectionUtils utils = this.utils;
    if (target is ExtensionOverride) {
      targetElement = target.staticElement;
      targetNode = await _getExtensionDeclaration(targetElement);
      if (targetNode == null) {
        return;
      }
    } else if (target is Identifier &&
        target.staticElement is ExtensionElement) {
      targetElement = target.staticElement;
      targetNode = await _getExtensionDeclaration(targetElement);
      if (targetNode == null) {
        return;
      }
      staticModifier = true;
    } else if (target == null) {
      targetElement = unit.declaredElement;
      ClassMember enclosingMember = node.thisOrAncestorOfType<ClassMember>();
      if (enclosingMember == null) {
        // If the undefined identifier isn't inside a class member, then it
        // doesn't make sense to create a method.
        return;
      }
      targetNode = enclosingMember.parent;
      staticModifier = _inStaticContext();
    } else {
      var targetClassElement = _getTargetClassElement(target);
      if (targetClassElement == null) {
        return;
      }
      targetElement = targetClassElement;
      if (targetClassElement.librarySource.isInSystemLibrary) {
        return;
      }
      // prepare target ClassDeclaration
      targetNode = await _getClassDeclaration(targetClassElement);
      if (targetNode == null) {
        return;
      }
      // maybe static
      if (target is Identifier) {
        staticModifier = target.staticElement.kind == ElementKind.CLASS;
      }
      // use different utils
      var targetPath = targetClassElement.source.fullName;
      var targetResolveResult = await session.getResolvedUnit(targetPath);
      utils = CorrectionUtils(targetResolveResult);
    }
    ClassMemberLocation targetLocation =
        utils.prepareNewMethodLocation(targetNode);
    String targetFile = targetElement.source.fullName;
    // build method source
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
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
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_METHOD, args: [name]);
  }

  Future<void> _addFix_createMissingOverrides() async {
    if (node.parent is! ClassDeclaration) {
      return;
    }
    ClassDeclaration targetClass = node.parent as ClassDeclaration;
    ClassElement targetClassElement = targetClass.declaredElement;
    utils.targetClassElement = targetClassElement;
    List<ExecutableElement> signatures =
        InheritanceOverrideVerifier.missingOverrides(targetClass).toList();
    // sort by name, getters before setters
    signatures.sort((ExecutableElement a, ExecutableElement b) {
      int names = compareStrings(a.displayName, b.displayName);
      if (names != 0) {
        return names;
      }
      if (a.kind == ElementKind.GETTER) {
        return -1;
      }
      return 1;
    });
    int numElements = signatures.length;

    ClassMemberLocation location =
        utils.prepareNewClassMemberLocation(targetClass, (_) => true);

    String prefix = utils.getIndent(1);
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(location.offset, (DartEditBuilder builder) {
        // Separator management.
        int numOfMembersWritten = 0;
        void addSeparatorBetweenDeclarations() {
          if (numOfMembersWritten == 0) {
            builder.write(location.prefix);
          } else {
            builder.write(eol); // after the previous member
            builder.write(eol); // empty line separator
            builder.write(prefix);
          }
          numOfMembersWritten++;
        }

        // merge getter/setter pairs into fields
        for (int i = 0; i < signatures.length; i++) {
          ExecutableElement element = signatures[i];
          if (element.kind == ElementKind.GETTER && i + 1 < signatures.length) {
            ExecutableElement nextElement = signatures[i + 1];
            if (nextElement.kind == ElementKind.SETTER) {
              // remove this and the next elements, adjust iterator
              signatures.removeAt(i + 1);
              signatures.removeAt(i);
              i--;
              numElements--;
              // separator
              addSeparatorBetweenDeclarations();
              // @override
              builder.write('@override');
              builder.write(eol);
              // add field
              builder.write(prefix);
              builder.writeType(element.returnType, required: true);
              builder.write(' ');
              builder.write(element.name);
              builder.write(';');
            }
          }
        }
        // add elements
        for (ExecutableElement element in signatures) {
          addSeparatorBetweenDeclarations();
          builder.writeOverride(element);
        }
        builder.write(location.suffix);
      });
    });
    changeBuilder.setSelection(Position(file, location.offset));
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_MISSING_OVERRIDES,
        args: [numElements]);
  }

  Future<void> _addFix_createMixin() async {
    Element prefixElement;
    String name;
    SimpleIdentifier nameNode;
    if (node is SimpleIdentifier) {
      AstNode parent = node.parent;
      if (parent is PrefixedIdentifier) {
        if (parent.parent is InstanceCreationExpression) {
          return;
        }
        PrefixedIdentifier prefixedIdentifier = parent;
        prefixElement = prefixedIdentifier.prefix.staticElement;
        if (prefixElement == null) {
          return;
        }
        parent = prefixedIdentifier.parent;
        nameNode = prefixedIdentifier.identifier;
        name = prefixedIdentifier.identifier.name;
      } else if (parent is TypeName &&
          parent.parent is ConstructorName &&
          parent.parent.parent is InstanceCreationExpression) {
        return;
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
      targetUnit = unit.declaredElement;
      CompilationUnitMember enclosingMember = node.thisOrAncestorMatching(
          (node) =>
              node is CompilationUnitMember && node.parent is CompilationUnit);
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
            try {
              offset = targetSource.contents.data.length;
              filePath = targetSource.fullName;
              prefix = '$eol';
              suffix = '$eol';
            } on FileSystemException {
              // If we can't read the file to get the offset, then we can't
              // create a fix.
            }
            break;
          }
        }
      }
    }
    if (offset < 0) {
      return;
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(filePath, (DartFileEditBuilder builder) {
      builder.addInsertion(offset, (DartEditBuilder builder) {
        builder.write(prefix);
        builder.writeMixinDeclaration(name, nameGroupName: 'NAME');
        builder.write(suffix);
      });
      if (prefixElement == null) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_MIXIN, args: [name]);
  }

  Future<void> _addFix_createNoSuchMethod() async {
    if (node.parent is! ClassDeclaration) {
      return;
    }
    ClassDeclaration targetClass = node.parent as ClassDeclaration;
    // prepare environment
    String prefix = utils.getIndent(1);
    int insertOffset = targetClass.end - 1;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(insertOffset, (DartEditBuilder builder) {
        builder.selectHere();
        // insert empty line before existing member
        if (targetClass.members.isNotEmpty) {
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

  Future<void> _addFix_createPartUri() async {
    // TODO(brianwilkerson) Generalize this to allow other valid string literals.
    if (node is SimpleStringLiteral && node.parent is PartDirective) {
      PartDirective partDirective = node.parent;
      Source source = partDirective.uriSource;
      if (source != null) {
        String libName = unitLibraryElement.name;
        var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_createSetter() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier nameNode = node;
    if (!nameNode.inSetterContext()) {
      return;
    }
    // prepare target
    Expression target;
    {
      AstNode nameParent = nameNode.parent;
      if (nameParent is PrefixedIdentifier) {
        target = nameParent.prefix;
      } else if (nameParent is PropertyAccess) {
        target = nameParent.realTarget;
      }
    }
    // prepare target element
    bool staticModifier = false;
    Element targetElement;
    if (target is ExtensionOverride) {
      targetElement = target.staticElement;
    } else if (target is Identifier &&
        target.staticElement is ExtensionElement) {
      targetElement = target.staticElement;
      staticModifier = true;
    } else if (target != null) {
      // prepare target interface type
      DartType targetType = target.staticType;
      if (targetType is! InterfaceType) {
        return;
      }
      targetElement = targetType.element;
      // maybe static
      if (target is Identifier) {
        Identifier targetIdentifier = target;
        Element targetElement = targetIdentifier.staticElement;
        staticModifier = targetElement?.kind == ElementKind.CLASS;
      }
    } else {
      targetElement =
          getEnclosingClassElement(node) ?? getEnclosingExtensionElement(node);
      if (targetElement == null) {
        return;
      }
      staticModifier = _inStaticContext();
    }
    if (targetElement.librarySource.isInSystemLibrary) {
      return;
    }
    // prepare target declaration
    var targetDeclarationResult =
        await sessionHelper.getElementDeclaration(targetElement);
    if (targetDeclarationResult.node is! ClassOrMixinDeclaration &&
        targetDeclarationResult.node is! ExtensionDeclaration) {
      return;
    }
    CompilationUnitMember targetNode = targetDeclarationResult.node;
    // prepare location
    ClassMemberLocation targetLocation = CorrectionUtils(
            targetDeclarationResult.resolvedUnit)
        .prepareNewGetterLocation(targetNode); // Rename to "AccessorLocation"
    // build method source
    Source targetSource = targetElement.source;
    String targetFile = targetSource.fullName;
    String name = nameNode.name;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        Expression parameterTypeNode = climbPropertyAccess(nameNode);
        DartType parameterType =
            _inferUndefinedExpressionType(parameterTypeNode);
        builder.write(targetLocation.prefix);
        builder.writeSetterDeclaration(name,
            isStatic: staticModifier,
            nameGroupName: 'NAME',
            parameterType: parameterType,
            parameterTypeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_SETTER, args: [name]);
  }

  Future<void> _addFix_extendClassForMixin() async {
    ClassDeclaration declaration =
        node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration != null && declaration.extendsClause == null) {
      // TODO(brianwilkerson) Find a way to pass in the name of the class
      //  without needing to parse the message.
      String message = error.message;
      int endIndex = message.lastIndexOf("'");
      int startIndex = message.lastIndexOf("'", endIndex - 1) + 1;
      String typeName = message.substring(startIndex, endIndex);
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleInsertion(
            declaration.typeParameters?.end ?? declaration.name.end,
            ' extends $typeName');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.EXTEND_CLASS_FOR_MIXIN,
          args: [typeName]);
    }
  }

  Future<void> _addFix_illegalAsyncReturnType() async {
    // prepare the existing type
    TypeAnnotation typeName = node.thisOrAncestorOfType<TypeAnnotation>();
    TypeProvider typeProvider = this.typeProvider;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.replaceTypeWithFuture(typeName, typeProvider);
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_RETURN_TYPE_FUTURE);
  }

  Future<void> _addFix_importAsync() async {
    await _addFix_importLibrary(
        DartFixKind.IMPORT_ASYNC, Uri.parse('dart:async'));
  }

  Future<void> _addFix_importLibrary(FixKind kind, Uri library,
      [String relativeURI]) async {
    String uriText;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      uriText = builder.importLibrary(library);
    });
    _addFixFromBuilder(changeBuilder, kind, args: [uriText]);

    if (relativeURI != null && relativeURI.isNotEmpty) {
      var changeBuilder2 = _newDartChangeBuilder();
      await changeBuilder2.addFileEdit(file, (DartFileEditBuilder builder) {
        if (builder is DartFileEditBuilderImpl) {
          builder.importLibraryWithRelativeUri(relativeURI);
        }
      });
      _addFixFromBuilder(changeBuilder2, kind, args: [relativeURI]);
    }
  }

  Future<void> _addFix_importLibrary_withElement(
      String name,
      List<ElementKind> elementKinds,
      List<TopLevelDeclarationKind> kinds2) async {
    // ignore if private
    if (name.startsWith('_')) {
      return;
    }
    // may be there is an existing import,
    // but it is with prefix and we don't use this prefix
    var alreadyImportedWithPrefix = <String>{};
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
        var changeBuilder = _newDartChangeBuilder();
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
        Set<String> showNames = SplayTreeSet<String>();
        showNames.addAll(showCombinator.shownNames);
        showNames.add(name);
        // prepare library name - unit name or 'dart:name' for SDK library
        String libraryName =
            libraryElement.definingCompilationUnit.source.uri.toString();
        if (libraryElement.isInSdk) {
          libraryName = libraryElement.source.shortName;
        }
        // don't add this library again
        alreadyImportedWithPrefix.add(libraryElement.source.fullName);
        // update library
        String newShowCode = 'show ${showNames.join(', ')}';
        int offset = showCombinator.offset;
        int length = showCombinator.end - offset;
        String libraryFile =
            context.resolveResult.libraryElement.source.fullName;
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(libraryFile,
            (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(
              SourceRange(offset, length), newShowCode);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.IMPORT_LIBRARY_SHOW,
            args: [libraryName]);
      }
    }
    // Find new top-level declarations.
    {
      var declarations = context.getTopLevelDeclarations(name);
      for (var declaration in declarations) {
        // Check the kind.
        if (!kinds2.contains(declaration.kind)) {
          continue;
        }
        // Check the source.
        if (alreadyImportedWithPrefix.contains(declaration.path)) {
          continue;
        }
        // Check that the import doesn't end with '.template.dart'
        if (declaration.uri.path.endsWith('.template.dart')) {
          continue;
        }
        // Compute the fix kind.
        FixKind fixKind;
        if (declaration.uri.isScheme('dart')) {
          fixKind = DartFixKind.IMPORT_LIBRARY_SDK;
        } else if (_isLibSrcPath(declaration.path)) {
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
        var relativeURI =
            _getRelativeURIFromLibrary(unitLibraryElement, declaration.path);
        await _addFix_importLibrary(fixKind, declaration.uri, relativeURI);
      }
    }
  }

  Future<void> _addFix_importLibrary_withExtension() async {
    if (node is SimpleIdentifier) {
      String extensionName = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(
          extensionName,
          const [ElementKind.EXTENSION],
          const [TopLevelDeclarationKind.extension]);
    }
  }

  Future<void> _addFix_importLibrary_withFunction() async {
    if (node is SimpleIdentifier) {
      if (node.parent is MethodInvocation) {
        MethodInvocation invocation = node.parent as MethodInvocation;
        if (invocation.realTarget != null || invocation.methodName != node) {
          return;
        }
      }

      String name = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(name, const [
        ElementKind.FUNCTION,
        ElementKind.TOP_LEVEL_VARIABLE
      ], const [
        TopLevelDeclarationKind.function,
        TopLevelDeclarationKind.variable
      ]);
    }
  }

  Future<void> _addFix_importLibrary_withTopLevelVariable() async {
    if (node is SimpleIdentifier) {
      String name = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(
          name,
          const [ElementKind.TOP_LEVEL_VARIABLE],
          const [TopLevelDeclarationKind.variable]);
    }
  }

  Future<void> _addFix_importLibrary_withType() async {
    if (_mayBeTypeIdentifier(node)) {
      String typeName = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(
          typeName,
          const [ElementKind.CLASS, ElementKind.FUNCTION_TYPE_ALIAS],
          const [TopLevelDeclarationKind.type]);
    } else if (_mayBeImplicitConstructor(node)) {
      String typeName = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(typeName,
          const [ElementKind.CLASS], const [TopLevelDeclarationKind.type]);
    }
  }

  Future<void> _addFix_insertSemicolon() async {
    if (error.message.contains("';'")) {
      if (_isAwaitNode()) {
        return;
      }
      int insertOffset = error.offset + error.length;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleInsertion(insertOffset, ';');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.INSERT_SEMICOLON);
    }
  }

  Future<void> _addFix_isNotEmpty() async {
    if (node is! PrefixExpression) {
      return;
    }
    PrefixExpression prefixExpression = node;
    Token negation = prefixExpression.operator;
    if (negation.type != TokenType.BANG) {
      return;
    }
    SimpleIdentifier identifier;
    Expression expression = prefixExpression.operand;
    if (expression is PrefixedIdentifier) {
      identifier = expression.identifier;
    } else if (expression is PropertyAccess) {
      identifier = expression.propertyName;
    } else {
      return;
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(range.token(negation));
      builder.addSimpleReplacement(range.node(identifier), 'isNotEmpty');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.USE_IS_NOT_EMPTY);
  }

  Future<void> _addFix_isNotNull() async {
    if (coveredNode is IsExpression) {
      IsExpression isExpression = coveredNode as IsExpression;
      var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_isNull() async {
    if (coveredNode is IsExpression) {
      IsExpression isExpression = coveredNode as IsExpression;
      var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_makeEnclosingClassAbstract() async {
    ClassDeclaration enclosingClass =
        node.thisOrAncestorOfType<ClassDeclaration>();
    if (enclosingClass == null) {
      return;
    }
    String className = enclosingClass.name.name;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(
          enclosingClass.classKeyword.offset, 'abstract ');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.MAKE_CLASS_ABSTRACT,
        args: [className]);
  }

  Future<void> _addFix_makeFieldNotFinal() async {
    AstNode node = this.node;
    if (node is SimpleIdentifier &&
        node.staticElement is PropertyAccessorElement) {
      PropertyAccessorElement getter = node.staticElement;
      if (getter.isGetter &&
          getter.isSynthetic &&
          !getter.variable.isSynthetic &&
          getter.variable.setter == null &&
          getter.enclosingElement is ClassElement) {
        var declarationResult =
            await sessionHelper.getElementDeclaration(getter.variable);
        AstNode variable = declarationResult.node;
        if (variable is VariableDeclaration &&
            variable.parent is VariableDeclarationList &&
            variable.parent.parent is FieldDeclaration) {
          VariableDeclarationList declarationList = variable.parent;
          Token keywordToken = declarationList.keyword;
          if (declarationList.variables.length == 1 &&
              keywordToken.keyword == Keyword.FINAL) {
            var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_makeVariableFinal() async {
    AstNode node = this.node;
    if (node is SimpleIdentifier && node.parent is VariableDeclaration) {
      VariableDeclaration declaration = node.parent;
      VariableDeclarationList list = declaration.parent;
      if (list.variables.length == 1) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          if (list.keyword == null) {
            builder.addSimpleInsertion(list.offset, 'final ');
          } else if (list.keyword.keyword == Keyword.VAR) {
            builder.addSimpleReplacement(range.token(list.keyword), 'final');
          }
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.MAKE_FINAL);
      }
    }
  }

  Future<void> _addFix_makeVariableNotFinal() async {
    AstNode node = this.node;
    if (node is SimpleIdentifier &&
        node.staticElement is LocalVariableElement) {
      LocalVariableElement variable = node.staticElement;
      var id = NodeLocator(variable.nameOffset).searchWithin(unit);
      var decl = id?.parent;
      if (decl is VariableDeclaration &&
          decl.parent is VariableDeclarationList) {
        VariableDeclarationList declarationList = decl.parent;
        var keywordToken = declarationList.keyword;
        if (declarationList.variables.length == 1 &&
            keywordToken.keyword == Keyword.FINAL) {
          var changeBuilder = _newDartChangeBuilder();
          await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
            if (declarationList.type != null) {
              builder.addDeletion(
                  range.startStart(keywordToken, declarationList.type));
            } else {
              builder.addSimpleReplacement(range.token(keywordToken), 'var');
            }
          });
          declarationList.variables[0].name.name;
          var varName = declarationList.variables[0].name.name;
          _addFixFromBuilder(changeBuilder, DartFixKind.MAKE_VARIABLE_NOT_FINAL,
              args: [varName]);
        }
      }
    }
  }

  Future<void> _addFix_moveTypeArgumentsToClass() async {
    if (coveredNode is TypeArgumentList) {
      TypeArgumentList typeArguments = coveredNode;
      if (typeArguments.parent is! InstanceCreationExpression) {
        return;
      }
      InstanceCreationExpression creation = typeArguments.parent;
      TypeName typeName = creation.constructorName.type;
      if (typeName.typeArguments != null) {
        return;
      }
      Element element = typeName.type.element;
      if (element is ClassElement &&
          element.typeParameters != null &&
          element.typeParameters.length == typeArguments.arguments.length) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          String argumentText = utils.getNodeText(typeArguments);
          builder.addSimpleInsertion(typeName.end, argumentText);
          builder.addDeletion(range.node(typeArguments));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.MOVE_TYPE_ARGUMENTS_TO_CLASS);
      }
    }
  }

  Future<void> _addFix_nonBoolCondition_addNotNull() async {
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(error.offset + error.length, ' != null');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_NE_NULL);
  }

  Future<void> _addFix_qualifyReference() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier memberName = node;
    AstNode parent = node.parent;
    AstNode target;
    if (parent is MethodInvocation && node == parent.methodName) {
      target = parent.target;
    } else if (parent is PropertyAccess && node == parent.propertyName) {
      target = parent.target;
    }
    if (target != null) {
      return;
    }
    Element enclosingElement = memberName.staticElement.enclosingElement;
    if (enclosingElement.library != unitLibraryElement) {
      // TODO(brianwilkerson) Support qualifying references to members defined
      //  in other libraries. `DartEditBuilder` currently defines the method
      //  `writeType`, which is close, but we also need to handle extensions,
      //  which don't have a type.
      return;
    }
    String containerName = enclosingElement.name;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(node.offset, '$containerName.');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.QUALIFY_REFERENCE,
        args: ['$containerName.${memberName.name}']);
  }

  Future<void> _addFix_removeAnnotation() async {
    void addFix(Annotation node) async {
      if (node == null) {
        return;
      }
      Token followingToken = node.endToken.next;
      followingToken = followingToken.precedingComments ?? followingToken;
      DartChangeBuilder changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(node, followingToken));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_ANNOTATION,
          args: [node.name.name]);
    }

    Annotation findAnnotation(
        NodeList<Annotation> metadata, String targetName) {
      return metadata.firstWhere(
          (annotation) => annotation.name.name == targetName,
          orElse: () => null);
    }

    AstNode node = coveredNode;
    if (node is Annotation) {
      await addFix(node);
    } else if (node is DefaultFormalParameter) {
      await addFix(findAnnotation(node.parameter.metadata, 'required'));
    } else if (node is NormalFormalParameter) {
      await addFix(findAnnotation(node.metadata, 'required'));
    } else if (node is DeclaredSimpleIdentifier) {
      AstNode parent = node.parent;
      if (parent is MethodDeclaration) {
        await addFix(findAnnotation(parent.metadata, 'override'));
      } else if (parent is VariableDeclaration) {
        FieldDeclaration fieldDeclaration =
            parent.thisOrAncestorOfType<FieldDeclaration>();
        if (fieldDeclaration != null) {
          await addFix(findAnnotation(fieldDeclaration.metadata, 'override'));
        }
      }
    }
  }

  Future<void> _addFix_removeArgument() async {
    var arg = node;
    if (arg.parent is NamedExpression) {
      arg = arg.parent;
    }

    final ArgumentList argumentList =
        arg.parent.thisOrAncestorOfType<ArgumentList>();
    if (argumentList != null) {
      final changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        final sourceRange = range.nodeInList(argumentList.arguments, arg);
        builder.addDeletion(sourceRange);
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_ARGUMENT);
    }
  }

  Future<void> _addFix_removeAwait() async {
    final awaitExpression = node;
    if (awaitExpression is AwaitExpression) {
      final awaitToken = awaitExpression.awaitKeyword;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(awaitToken, awaitToken.next));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_AWAIT);
    }
  }

  Future<void> _addFix_removeCaseStatement() async {
    if (coveredNode is SwitchCase) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(utils.getLinesRange(range.node(coveredNode)));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DUPLICATE_CASE);
    }
  }

  Future<void> _addFix_removeConstKeyword() async {
    final expression = node;
    if (expression is InstanceCreationExpression) {
      final constToken = expression.keyword;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(constToken, constToken.next));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNNECESSARY_CONST);
    } else if (expression is TypedLiteralImpl) {
      final constToken = expression.constKeyword;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(constToken, constToken.next));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNNECESSARY_CONST);
    }
  }

  Future<void> _addFix_removeDeadCode() async {
    AstNode coveringNode = coveredNode;
    if (coveringNode is Expression) {
      AstNode parent = coveredNode.parent;
      if (parent is BinaryExpression) {
        if (parent.rightOperand == coveredNode) {
          var changeBuilder = _newDartChangeBuilder();
          await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
            builder.addDeletion(range.endEnd(parent.leftOperand, coveredNode));
          });
          _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DEAD_CODE);
        }
      }
    } else if (coveringNode is Block) {
      Block block = coveringNode;
      List<Statement> statementsToRemove = <Statement>[];
      var errorRange = SourceRange(errorOffset, errorLength);
      for (Statement statement in block.statements) {
        if (range.node(statement).intersects(errorRange)) {
          statementsToRemove.add(statement);
        }
      }
      if (statementsToRemove.isNotEmpty) {
        SourceRange rangeToRemove =
            utils.getLinesRangeStatements(statementsToRemove);
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addDeletion(rangeToRemove);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DEAD_CODE);
      }
    } else if (coveringNode is Statement) {
      SourceRange rangeToRemove =
          utils.getLinesRangeStatements(<Statement>[coveringNode]);
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(rangeToRemove);
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DEAD_CODE);
    } else if (coveringNode is CatchClause) {
      TryStatement tryStatement = coveringNode.parent;
      NodeList<CatchClause> catchClauses = tryStatement.catchClauses;
      int index = catchClauses.indexOf(coveringNode);
      AstNode previous =
          index == 0 ? tryStatement.body : catchClauses[index - 1];
      DartChangeBuilder changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.endEnd(previous, coveringNode));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DEAD_CODE);
    }
  }

  Future<void> _addFix_removeEmptyCatch() async {
    var catchClause = node.parent as CatchClause;
    var tryStatement = catchClause.parent as TryStatement;
    if (tryStatement.catchClauses.length == 1 &&
        tryStatement.finallyBlock == null) {
      return;
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(utils.getLinesRange(range.node(catchClause)));
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_EMPTY_CATCH);
  }

  Future<void> _addFix_removeEmptyConstructorBody() async {
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
          utils.getLinesRange(range.node(node.parent)), ';');
    });
    _addFixFromBuilder(
        changeBuilder, DartFixKind.REMOVE_EMPTY_CONSTRUCTOR_BODY);
  }

  Future<void> _addFix_removeEmptyElse() async {
    IfStatement ifStatement = node.parent;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(utils.getLinesRange(
          range.startEnd(ifStatement.elseKeyword, ifStatement.elseStatement)));
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_EMPTY_ELSE);
  }

  Future<void> _addFix_removeEmptyStatement() async {
    EmptyStatement emptyStatement = node;
    if (emptyStatement.parent is Block) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(utils.getLinesRange(range.node(emptyStatement)));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_EMPTY_STATEMENT);
    } else {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        Token previous = emptyStatement.findPrevious(emptyStatement.beginToken);
        if (previous != null) {
          builder.addSimpleReplacement(
              range.endEnd(previous, emptyStatement), ' {}');
        }
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_BRACKETS);
    }
  }

  Future<void> _addFix_removeInitializer() async {
    // Handle formal parameters with default values.
    var parameter = node.thisOrAncestorOfType<DefaultFormalParameter>();
    if (parameter != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(
            range.endEnd(parameter.identifier, parameter.defaultValue));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_INITIALIZER);
      return;
    }
    // Handle variable declarations with default values.
    var variable = node.thisOrAncestorOfType<VariableDeclaration>();
    if (variable != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.endEnd(variable.name, variable.initializer));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_INITIALIZER);
    }
  }

  Future<void> _addFix_removeInterpolationBraces() async {
    AstNode node = this.node;
    if (node is InterpolationExpression) {
      Token right = node.rightBracket;
      if (node.expression != null && right != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(
              range.startStart(node, node.expression), r'$');
          builder.addDeletion(range.token(right));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_INTERPOLATION_BRACES);
      } else {}
    }
  }

  Future<void> _addFix_removeMethodDeclaration() async {
    MethodDeclaration declaration =
        node.thisOrAncestorOfType<MethodDeclaration>();
    if (declaration != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(utils.getLinesRange(range.node(declaration)));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_METHOD_DECLARATION);
    }
  }

  Future<void> _addFix_removeNameFromCombinator() async {
    SourceRange rangeForCombinator(Combinator combinator) {
      AstNode parent = combinator.parent;
      if (parent is NamespaceDirective) {
        NodeList<Combinator> combinators = parent.combinators;
        if (combinators.length == 1) {
          Token previousToken =
              combinator.parent.findPrevious(combinator.beginToken);
          return range.endEnd(previousToken, combinator);
        }
        int index = combinators.indexOf(combinator);
        if (index < 0) {
          return null;
        } else if (index == combinators.length - 1) {
          return range.endEnd(combinators[index - 1], combinator);
        }
        return range.startStart(combinator, combinators[index + 1]);
      }
      return null;
    }

    SourceRange rangeForNameInCombinator(
        Combinator combinator, SimpleIdentifier name) {
      NodeList<SimpleIdentifier> names;
      if (combinator is HideCombinator) {
        names = combinator.hiddenNames;
      } else if (combinator is ShowCombinator) {
        names = combinator.shownNames;
      } else {
        return null;
      }
      if (names.length == 1) {
        return rangeForCombinator(combinator);
      }
      int index = names.indexOf(name);
      if (index < 0) {
        return null;
      } else if (index == names.length - 1) {
        return range.endEnd(names[index - 1], name);
      }
      return range.startStart(name, names[index + 1]);
    }

    AstNode node = coveredNode;
    if (node is SimpleIdentifier) {
      AstNode parent = coveredNode.parent;
      if (parent is Combinator) {
        SourceRange rangeToRemove = rangeForNameInCombinator(parent, node);
        if (rangeToRemove == null) {
          return;
        }
        DartChangeBuilder changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addDeletion(rangeToRemove);
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_NAME_FROM_COMBINATOR,
            args: [parent is HideCombinator ? 'hide' : 'show']);
      }
    }
  }

  Future<void> _addFix_removeNewKeyword() async {
    final instanceCreationExpression = node;
    if (instanceCreationExpression is InstanceCreationExpression) {
      final newToken = instanceCreationExpression.keyword;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(newToken, newToken.next));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNNECESSARY_NEW);
    }
  }

  Future<void> _addFix_removeOperator() async {
    if (node is BinaryExpression) {
      var expression = node as BinaryExpression;
      var operator = expression.operator;
      var rightOperand = expression.rightOperand;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(operator, rightOperand));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_OPERATOR);
    }
  }

  Future<void> _addFix_removeParameters_inGetterDeclaration() async {
    if (node is MethodDeclaration) {
      // Support for the analyzer error.
      MethodDeclaration method = node as MethodDeclaration;
      SimpleIdentifier name = method.name;
      FunctionBody body = method.body;
      if (name != null && body != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(range.endStart(name, body), ' ');
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_PARAMETERS_IN_GETTER_DECLARATION);
      }
    } else if (node is FormalParameterList) {
      // Support for the fasta error.
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.node(node));
      });
      _addFixFromBuilder(
          changeBuilder, DartFixKind.REMOVE_PARAMETERS_IN_GETTER_DECLARATION);
    }
  }

  Future<void> _addFix_removeParentheses_inGetterInvocation() async {
    var invocation = coveredNode?.parent;
    if (invocation is FunctionExpressionInvocation) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.node(invocation.argumentList));
      });
      _addFixFromBuilder(
          changeBuilder, DartFixKind.REMOVE_PARENTHESIS_IN_GETTER_INVOCATION);
    }
  }

  Future<void> _addFix_removeThisExpression() async {
    if (node is ConstructorFieldInitializer) {
      var initializer = node as ConstructorFieldInitializer;
      var thisKeyword = initializer.thisKeyword;
      if (thisKeyword != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          var fieldName = initializer.fieldName;
          builder.addDeletion(range.startStart(thisKeyword, fieldName));
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_THIS_EXPRESSION);
      }
      return;
    }
    final thisExpression = node is ThisExpression
        ? node
        : node.thisOrAncestorOfType<ThisExpression>();
    final parent = thisExpression?.parent;
    if (parent is PropertyAccess) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startEnd(parent, parent.operator));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_THIS_EXPRESSION);
    } else if (parent is MethodInvocation) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startEnd(parent, parent.operator));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_THIS_EXPRESSION);
    }
  }

  Future<void> _addFix_removeTypeAnnotation() async {
    final TypeAnnotation type = node.thisOrAncestorOfType<TypeAnnotation>();
    if (type != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(type, type.endToken.next));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_TYPE_ANNOTATION);
    }
  }

  Future<void> _addFix_removeTypeArguments() async {
    if (coveredNode is TypeArgumentList) {
      TypeArgumentList typeArguments = coveredNode;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.node(typeArguments));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_TYPE_ARGUMENTS);
    }
  }

  Future<void> _addFix_removeUnnecessaryCast() async {
    if (coveredNode is! AsExpression) {
      return;
    }
    AsExpression asExpression = coveredNode as AsExpression;
    Expression expression = asExpression.expression;
    Precedence expressionPrecedence = getExpressionPrecedence(expression);
    // remove 'as T' from 'e as T'
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(range.endEnd(expression, asExpression));
      _removeEnclosingParentheses(builder, asExpression, expressionPrecedence);
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNNECESSARY_CAST);
  }

  Future<void> _addFix_removeUnusedCatchClause() async {
    if (node is SimpleIdentifier) {
      AstNode catchClause = node.parent;
      if (catchClause is CatchClause &&
          catchClause.exceptionParameter == node) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addDeletion(
              range.startStart(catchClause.catchKeyword, catchClause.body));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_UNUSED_CATCH_CLAUSE);
      }
    }
  }

  Future<void> _addFix_removeUnusedCatchStack() async {
    if (node is SimpleIdentifier) {
      AstNode catchClause = node.parent;
      if (catchClause is CatchClause &&
          catchClause.stackTraceParameter == node &&
          catchClause.exceptionParameter != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder
              .addDeletion(range.endEnd(catchClause.exceptionParameter, node));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_UNUSED_CATCH_STACK);
      }
    }
  }

  Future<void> _addFix_removeUnusedElement() async {
    final sourceRanges = <SourceRange>[];
    final referencedNode = node.parent;
    if (referencedNode is ClassDeclaration ||
        referencedNode is EnumDeclaration ||
        referencedNode is FunctionDeclaration ||
        referencedNode is FunctionTypeAlias ||
        referencedNode is MethodDeclaration ||
        referencedNode is VariableDeclaration) {
      final element = referencedNode is Declaration
          ? referencedNode.declaredElement
          : (referencedNode as NamedCompilationUnitMember).declaredElement;
      final references = _findAllReferences(unit, element);
      // todo (pq): consider filtering for references that are limited to within the class.
      if (references.length == 1) {
        var sourceRange;
        if (referencedNode is VariableDeclaration) {
          VariableDeclarationList parent = referencedNode.parent;
          if (parent.variables.length == 1) {
            sourceRange = utils.getLinesRange(range.node(parent.parent));
          } else {
            sourceRange = range.nodeInList(parent.variables, node);
          }
        } else {
          sourceRange = utils.getLinesRange(range.node(referencedNode));
        }
        sourceRanges.add(sourceRange);
      }
    }

    if (sourceRanges.isNotEmpty) {
      final changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        for (var sourceRange in sourceRanges) {
          builder.addDeletion(sourceRange);
        }
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNUSED_ELEMENT);
    }
  }

  Future<void> _addFix_removeUnusedField() async {
    final declaration = node.parent;
    if (declaration is! VariableDeclaration) {
      return;
    }
    final element = (declaration as VariableDeclaration).declaredElement;
    if (element is! FieldElement) {
      return;
    }

    final sourceRanges = <SourceRange>[];
    final references = _findAllReferences(unit, element);
    for (var reference in references) {
      // todo (pq): consider scoping this to parent or parent.parent.
      final referenceNode = reference.thisOrAncestorMatching((node) =>
          node is VariableDeclaration ||
          node is ExpressionStatement ||
          node is ConstructorFieldInitializer ||
          node is FieldFormalParameter);
      if (referenceNode == null) {
        return;
      }
      var sourceRange;
      if (referenceNode is VariableDeclaration) {
        VariableDeclarationList parent = referenceNode.parent;
        if (parent.variables.length == 1) {
          sourceRange = utils.getLinesRange(range.node(parent.parent));
        } else {
          sourceRange = range.nodeInList(parent.variables, referenceNode);
        }
      } else if (referenceNode is ConstructorFieldInitializer) {
        ConstructorDeclaration cons =
            referenceNode.parent as ConstructorDeclaration;
        // A() : _f = 0;
        if (cons.initializers.length == 1) {
          sourceRange = range.endEnd(cons.parameters, referenceNode);
        } else {
          sourceRange = range.nodeInList(cons.initializers, referenceNode);
        }
      } else if (referenceNode is FieldFormalParameter) {
        FormalParameterList params =
            referenceNode.parent as FormalParameterList;
        if (params.parameters.length == 1) {
          sourceRange =
              range.endStart(params.leftParenthesis, params.rightParenthesis);
        } else {
          sourceRange = range.nodeInList(params.parameters, referenceNode);
        }
      } else {
        sourceRange = utils.getLinesRange(range.node(referenceNode));
      }
      sourceRanges.add(sourceRange);
    }

    final changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      for (var sourceRange in sourceRanges) {
        builder.addDeletion(sourceRange);
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNUSED_FIELD);
  }

  Future<void> _addFix_removeUnusedImport() async {
    // prepare ImportDirective
    ImportDirective importDirective =
        node.thisOrAncestorOfType<ImportDirective>();
    if (importDirective == null) {
      return;
    }
    // remove the whole line with import
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(utils.getLinesRange(range.node(importDirective)));
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNUSED_IMPORT);
  }

  Future<void> _addFix_removeUnusedLabel() async {
    final parent = node.parent;
    if (parent is Label) {
      var nextToken = parent.endToken.next;
      final changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(parent, nextToken));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNUSED_LABEL);
    }
  }

  Future<void> _addFix_removeUnusedLocalVariable() async {
    final declaration = node.parent;
    if (!(declaration is VariableDeclaration && declaration.name == node)) {
      return;
    }
    Element element = (declaration as VariableDeclaration).declaredElement;
    if (element is! LocalElement) {
      return;
    }

    final sourceRanges = <SourceRange>[];

    final functionBody = declaration.thisOrAncestorOfType<FunctionBody>();
    final references = findLocalElementReferences(functionBody, element);
    for (var reference in references) {
      final node = reference.thisOrAncestorMatching((node) =>
          node is VariableDeclaration || node is AssignmentExpression);
      var sourceRange;
      if (node is VariableDeclaration) {
        VariableDeclarationList parent = node.parent;
        if (parent.variables.length == 1) {
          sourceRange = utils.getLinesRange(range.node(parent.parent));
        } else {
          sourceRange = range.nodeInList(parent.variables, node);
        }
      } else if (node is AssignmentExpression) {
        // todo (pq): consider node.parent is! ExpressionStatement to handle
        // assignments in parens, etc.
        if (node.parent is ArgumentList) {
          sourceRange = range.startStart(node, node.operator.next);
        } else {
          sourceRange = utils.getLinesRange(range.node(node.parent));
        }
      } else {
        return;
      }
      sourceRanges.add(sourceRange);
    }

    final changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      for (var sourceRange in sourceRanges) {
        builder.addDeletion(sourceRange);
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNUSED_LOCAL_VARIABLE);
  }

  Future<void> _addFix_renameToCamelCase() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier identifier = node;

    // Prepare the new name.
    List<String> words = identifier.name.split('_');
    if (words.length < 2) {
      return;
    }
    var newName = words.first + words.skip(1).map((w) => capitalize(w)).join();

    // Find references to the identifier.
    List<SimpleIdentifier> references;
    Element element = identifier.staticElement;
    if (element is LocalVariableElement) {
      AstNode root = node.thisOrAncestorOfType<Block>();
      references = findLocalElementReferences(root, element);
    } else if (element is ParameterElement) {
      if (!element.isNamed) {
        AstNode root = node.thisOrAncestorMatching((node) =>
            node.parent is ClassOrMixinDeclaration ||
            node.parent is CompilationUnit);
        references = findLocalElementReferences(root, element);
      }
    }
    if (references == null) {
      return;
    }

    // Compute the change.
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      for (var reference in references) {
        builder.addSimpleReplacement(range.node(reference), newName);
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.RENAME_TO_CAMEL_CASE,
        args: [newName]);
  }

  Future<void> _addFix_replaceColonWithEquals() async {
    if (node is DefaultFormalParameter) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(
            range.token((node as DefaultFormalParameter).separator), ' =');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_COLON_WITH_EQUALS);
    }
  }

  Future<void> _addFix_replaceFinalWithConst() async {
    if (node is VariableDeclarationList) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(
            range.token((node as VariableDeclarationList).keyword), 'const');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_FINAL_WITH_CONST);
    }
  }

  Future<void> _addFix_replaceNewWithConst() async {
    var node = coveredNode;
    if (node is ConstructorName) {
      node = node.parent;
    }
    if (node is InstanceCreationExpression) {
      final keyword = node.keyword;
      if (keyword != null) {
        final changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(range.token(keyword), 'const');
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_NEW_WITH_CONST);
      }
    }
  }

  Future<void> _addFix_replaceNullWithClosure() async {
    var nodeToFix;
    var parameters = const <ParameterElement>[];
    if (coveredNode is NamedExpression) {
      NamedExpression namedExpression = coveredNode;
      var expression = namedExpression.expression;
      if (expression is NullLiteral) {
        var element = namedExpression.element;
        if (element is ParameterElement) {
          var type = element.type;
          if (type is FunctionType) {
            parameters = type.parameters;
          }
        }
        nodeToFix = expression;
      }
    } else if (coveredNode is NullLiteral) {
      nodeToFix = coveredNode;
    }

    if (nodeToFix != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(range.node(nodeToFix),
            (DartEditBuilder builder) {
          builder.writeParameters(parameters);
          builder.write(' => null');
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_NULL_WITH_CLOSURE);
    }
  }

  Future<void> _addFix_replaceVarWithDynamic() async {
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.error(error), 'dynamic');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_VAR_WITH_DYNAMIC);
  }

  Future<void> _addFix_replaceWithConditionalAssignment() async {
    IfStatement ifStatement =
        node is IfStatement ? node : node.thisOrAncestorOfType<IfStatement>();
    if (ifStatement == null) {
      return;
    }
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
        var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_replaceWithConstInstanceCreation() async {
    if (coveredNode is InstanceCreationExpression) {
      var instanceCreation = coveredNode as InstanceCreationExpression;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        if (instanceCreation.keyword == null) {
          builder.addSimpleInsertion(
              instanceCreation.constructorName.offset, 'const');
        } else {
          builder.addSimpleReplacement(
              range.token(instanceCreation.keyword), 'const');
        }
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.USE_CONST);
    }
  }

  Future<void> _addFix_replaceWithExtensionName() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    AstNode parent = node.parent;
    AstNode target;
    if (parent is MethodInvocation && node == parent.methodName) {
      target = parent.target;
    } else if (parent is PropertyAccess && node == parent.propertyName) {
      target = parent.target;
    }
    if (target is! ExtensionOverride) {
      return;
    }
    ExtensionOverride override = target;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
          range.node(override), utils.getNodeText(override.extensionName));
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_EXTENSION_NAME,
        args: [override.extensionName.name]);
  }

  Future<void> _addFix_replaceWithIdentifier() async {
    final FunctionTypedFormalParameter functionTyped =
        node.thisOrAncestorOfType<FunctionTypedFormalParameter>();
    if (functionTyped != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(range.node(functionTyped),
            utils.getNodeText(functionTyped.identifier));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_IDENTIFIER);
    } else {
      await _addFix_removeTypeAnnotation();
    }
  }

  Future<void> _addFix_replaceWithIsEmpty() async {
    /// Return the value of an integer literal or prefix expression with a
    /// minus and then an integer literal. For anything else, returns `null`.
    int getIntValue(Expression expressions) {
      // Copied from package:linter/src/rules/prefer_is_empty.dart.
      if (expressions is IntegerLiteral) {
        return expressions.value;
      } else if (expressions is PrefixExpression) {
        var operand = expressions.operand;
        if (expressions.operator.type == TokenType.MINUS &&
            operand is IntegerLiteral) {
          return -operand.value;
        }
      }
      return null;
    }

    /// Return the expression producing the object on which `length` is being
    /// invoked, or `null` if there is no such expression.
    Expression getLengthTarget(Expression expression) {
      if (expression is PropertyAccess &&
          expression.propertyName.name == 'length') {
        return expression.target;
      } else if (expression is PrefixedIdentifier &&
          expression.identifier.name == 'length') {
        return expression.prefix;
      }
      return null;
    }

    BinaryExpression binary = node.thisOrAncestorOfType();
    TokenType operator = binary.operator.type;
    String getter;
    FixKind kind;
    Expression lengthTarget;
    int rightValue = getIntValue(binary.rightOperand);
    if (rightValue != null) {
      lengthTarget = getLengthTarget(binary.leftOperand);
      if (rightValue == 0) {
        if (operator == TokenType.EQ_EQ || operator == TokenType.LT_EQ) {
          getter = 'isEmpty';
          kind = DartFixKind.REPLACE_WITH_IS_EMPTY;
        } else if (operator == TokenType.GT || operator == TokenType.BANG_EQ) {
          getter = 'isNotEmpty';
          kind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
        }
      } else if (rightValue == 1) {
        // 'length >= 1' is same as 'isNotEmpty',
        // and 'length < 1' is same as 'isEmpty'
        if (operator == TokenType.GT_EQ) {
          getter = 'isNotEmpty';
          kind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
        } else if (operator == TokenType.LT) {
          getter = 'isEmpty';
          kind = DartFixKind.REPLACE_WITH_IS_EMPTY;
        }
      }
    } else {
      int leftValue = getIntValue(binary.leftOperand);
      if (leftValue != null) {
        lengthTarget = getLengthTarget(binary.rightOperand);
        if (leftValue == 0) {
          if (operator == TokenType.EQ_EQ || operator == TokenType.GT_EQ) {
            getter = 'isEmpty';
            kind = DartFixKind.REPLACE_WITH_IS_EMPTY;
          } else if (operator == TokenType.LT ||
              operator == TokenType.BANG_EQ) {
            getter = 'isNotEmpty';
            kind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
          }
        } else if (leftValue == 1) {
          // '1 <= length' is same as 'isNotEmpty',
          // and '1 > length' is same as 'isEmpty'
          if (operator == TokenType.LT_EQ) {
            getter = 'isNotEmpty';
            kind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
          } else if (operator == TokenType.GT) {
            getter = 'isEmpty';
            kind = DartFixKind.REPLACE_WITH_IS_EMPTY;
          }
        }
      }
    }
    if (lengthTarget == null || getter == null || kind == null) {
      return;
    }
    String target = utils.getNodeText(lengthTarget);
    DartChangeBuilder changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(binary), '$target.$getter');
    });
    _addFixFromBuilder(changeBuilder, kind);
  }

  Future<void> _addFix_replaceWithRethrow() async {
    if (coveredNode is ThrowExpression) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(range.node(coveredNode), 'rethrow');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.USE_RETHROW);
    }
  }

  Future<void> _addFix_replaceWithTearOff() async {
    FunctionExpression ancestor =
        node.thisOrAncestorOfType<FunctionExpression>();
    if (ancestor == null) {
      return;
    }
    Future<void> addFixOfExpression(InvocationExpression expression) async {
      var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_replaceWithVar() async {
    var changeBuilder = await createBuilder_replaceWithVar();
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_VAR);
  }

  Future<void> _addFix_sortChildPropertiesLast() async {
    final changeBuilder = await createBuilder_sortChildPropertyLast();
    _addFixFromBuilder(changeBuilder, DartFixKind.SORT_CHILD_PROPERTY_LAST);
  }

  Future<void> _addFix_undefinedClass_useSimilar() async {
    AstNode node = this.node;
    // Prepare the optional import prefix name.
    String prefixName;
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
      _ClosestElementFinder finder = _ClosestElementFinder(
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
          var changeBuilder = _newDartChangeBuilder();
          await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
            builder.addSimpleReplacement(range.node(node), closestName);
          });
          _addFixFromBuilder(changeBuilder, DartFixKind.CHANGE_TO,
              args: [closestName]);
        }
      }
    }
  }

  Future<void> _addFix_undefinedClassAccessor_useSimilar() async {
    AstNode node = this.node;
    if (node is SimpleIdentifier) {
      // prepare target
      Expression target;
      if (node.parent is PrefixedIdentifier) {
        target = (node.parent as PrefixedIdentifier).prefix;
      } else if (node.parent is PropertyAccess) {
        target = (node.parent as PropertyAccess).target;
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

  Future<void> _addFix_undefinedClassMember_useSimilar(
      Expression target, ElementPredicate predicate) async {
    if (node is SimpleIdentifier) {
      String name = (node as SimpleIdentifier).name;
      _ClosestElementFinder finder =
          _ClosestElementFinder(name, predicate, MAX_LEVENSHTEIN_DISTANCE);
      // unqualified invocation
      if (target == null) {
        ClassDeclaration clazz = node.thisOrAncestorOfType<ClassDeclaration>();
        if (clazz != null) {
          ClassElement classElement = clazz.declaredElement;
          _updateFinderWithClassMembers(finder, classElement);
        }
      } else if (target is ExtensionOverride) {
        _updateFinderWithExtensionMembers(finder, target.staticElement);
      } else if (target is Identifier &&
          target.staticElement is ExtensionElement) {
        _updateFinderWithExtensionMembers(finder, target.staticElement);
      } else {
        var classElement = _getTargetClassElement(target);
        if (classElement != null) {
          _updateFinderWithClassMembers(finder, classElement);
        }
      }
      // if we have close enough element, suggest to use it
      if (finder._element != null) {
        String closestName = finder._element.displayName;
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(range.node(node), closestName);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.CHANGE_TO,
            args: [closestName]);
      }
    }
  }

  Future<void> _addFix_undefinedFunction_create() async {
    // should be the name of the invocation
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
    } else {
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
        node.thisOrAncestorOfType<CompilationUnitMember>();
    insertOffset = enclosingMember.end;
    sourcePrefix = '$eol$eol';
    utils.targetClassElement = null;
    // build method source
    var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_undefinedFunction_useSimilar() async {
    AstNode node = this.node;
    if (node is SimpleIdentifier) {
      // Prepare the optional import prefix name.
      String prefixName;
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
      _ClosestElementFinder finder = _ClosestElementFinder(
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
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(range.node(node), closestName);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.CHANGE_TO,
            args: [closestName]);
      }
    }
  }

  Future<void> _addFix_undefinedMethod_useSimilar() async {
    if (node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      await _addFix_undefinedClassMember_useSimilar(invocation.realTarget,
          (Element element) => element is MethodElement && !element.isOperator);
    }
  }

  /// Here we handle cases when a constructors does not initialize all of the
  /// final fields.
  Future<void> _addFix_updateConstructor_forUninitializedFinalFields() async {
    if (node is! SimpleIdentifier || node.parent is! ConstructorDeclaration) {
      return;
    }
    ConstructorDeclaration constructor = node.parent;
    List<FormalParameter> parameters = constructor.parameters.parameters;

    ClassDeclaration classNode = constructor.parent;
    InterfaceType superType = classNode.declaredElement.supertype;

    // Compute uninitialized final fields.
    List<FieldElement> fields =
        ErrorVerifier.computeNotInitializedFields(constructor);
    fields.retainWhere((FieldElement field) => field.isFinal);

    // Prepare new parameters code.
    fields.sort((a, b) => a.nameOffset - b.nameOffset);
    String fieldParametersCode =
        fields.map((field) => 'this.${field.name}').join(', ');

    // Specialize for Flutter widgets.
    if (flutter.isExactlyStatelessWidgetType(superType) ||
        flutter.isExactlyStatefulWidgetType(superType)) {
      if (parameters.isNotEmpty && parameters.last.isNamed) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleInsertion(
              parameters.last.end, ', $fieldParametersCode');
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.ADD_FIELD_FORMAL_PARAMETERS);
        return;
      }
    }

    // Prepare the last required parameter.
    FormalParameter lastRequiredParameter;
    for (FormalParameter parameter in parameters) {
      if (parameter.isRequiredPositional) {
        lastRequiredParameter = parameter;
      }
    }

    var changeBuilder = _newDartChangeBuilder();
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

  Future<void> _addFix_updateSdkConstraints(String minimumVersion) async {
    Context context = resourceProvider.pathContext;
    File pubspecFile;
    Folder folder = resourceProvider.getFolder(context.dirname(file));
    while (folder != null) {
      pubspecFile = folder.getChildAssumingFile('pubspec.yaml');
      if (pubspecFile.exists) {
        break;
      }
      pubspecFile = null;
      folder = folder.parent;
    }
    if (pubspecFile == null) {
      return;
    }
    SdkConstraintExtractor extractor = SdkConstraintExtractor(pubspecFile);
    String text = extractor.constraintText();
    int offset = extractor.constraintOffset();
    if (text == null || offset < 0) {
      return;
    }
    int length = text.length;
    String newText;
    int spaceOffset = text.indexOf(' ');
    if (spaceOffset >= 0) {
      length = spaceOffset;
    }
    if (text == 'any') {
      newText = '^$minimumVersion';
    } else if (text.startsWith('^')) {
      newText = '^$minimumVersion';
    } else if (text.startsWith('>=')) {
      newText = '>=$minimumVersion';
    } else if (text.startsWith('>')) {
      newText = '>=$minimumVersion';
    }
    if (newText == null) {
      return;
    }
    var changeBuilder = ChangeBuilder();
    await changeBuilder.addFileEdit(pubspecFile.path, (builder) {
      builder.addSimpleReplacement(SourceRange(offset, length), newText);
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.UPDATE_SDK_CONSTRAINTS);
  }

  Future<void> _addFix_useEffectiveIntegerDivision() async {
    for (AstNode n = node; n != null; n = n.parent) {
      if (n is MethodInvocation &&
          n.offset == errorOffset &&
          n.length == errorLength) {
        Expression target = (n as MethodInvocation).target.unParenthesized;
        var changeBuilder = _newDartChangeBuilder();
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

  /// Adds a fix that replaces [target] with a reference to the class declaring
  /// the given [element].
  Future<void> _addFix_useStaticAccess(AstNode target, Element element) async {
    var declaringElement = element.enclosingElement;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(target), (DartEditBuilder builder) {
        builder.writeReference(declaringElement);
      });
    });
    _addFixFromBuilder(
      changeBuilder,
      DartFixKind.CHANGE_TO_STATIC_ACCESS,
      args: [declaringElement.name],
    );
  }

  Future<void> _addFix_useStaticAccess_method() async {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      if (invocation.methodName == node) {
        Expression target = invocation.target;
        Element invokedElement = invocation.methodName.staticElement;
        await _addFix_useStaticAccess(target, invokedElement);
      }
    }
  }

  Future<void> _addFix_useStaticAccess_property() async {
    if (node is SimpleIdentifier && node.parent is PrefixedIdentifier) {
      PrefixedIdentifier prefixed = node.parent as PrefixedIdentifier;
      if (prefixed.identifier == node) {
        Expression target = prefixed.prefix;
        Element invokedElement = prefixed.identifier.staticElement;
        await _addFix_useStaticAccess(target, invokedElement);
      }
    }
  }

  void _addFixFromBuilder(ChangeBuilder builder, FixKind kind,
      {List args, bool importsOnly = false}) {
    if (builder == null) return;
    SourceChange change = builder.sourceChange;
    if (change.edits.isEmpty && !importsOnly) {
      return;
    }
    change.message = formatList(kind.message, args);
    fixes.add(Fix(kind, change));
  }

  Future<void> _addFromProducers() async {
    var context = CorrectionProducerContext(
      selectionOffset: errorOffset,
      selectionLength: 0,
      resolvedResult: resolvedResult,
      workspace: workspace,
    );

    var setupSuccess = context.setupCompute();
    if (!setupSuccess) {
      return;
    }

    Future<void> compute(CorrectionProducer producer, FixKind kind) async {
      producer.configure(context);

      var builder = _newDartChangeBuilder();
      await producer.compute(builder);

      _addFixFromBuilder(builder, kind);
    }

    var errorCode = error.errorCode;
    if (errorCode is LintCode) {
      String name = errorCode.name;
      if (name == LintNames.prefer_collection_literals) {
        await compute(
          ConvertToListLiteral(),
          DartFixKind.CONVERT_TO_LIST_LITERAL,
        );
        await compute(
          ConvertToMapLiteral(),
          DartFixKind.CONVERT_TO_MAP_LITERAL,
        );
        await compute(
          ConvertToSetLiteral(),
          DartFixKind.CONVERT_TO_SET_LITERAL,
        );
      } else if (name == LintNames.prefer_contains) {
        await compute(
          ConvertToContains(),
          DartFixKind.CONVERT_TO_CONTAINS,
        );
      } else if (name == LintNames.prefer_iterable_whereType) {
        await compute(
          ConvertToWhereType(),
          DartFixKind.CONVERT_TO_WHERE_TYPE,
        );
      } else if (name == LintNames.prefer_null_aware_operators) {
        await compute(
          ConvertToNullAware(),
          DartFixKind.CONVERT_TO_NULL_AWARE,
        );
      } else if (name == LintNames.unnecessary_null_in_if_null_operators) {
        await compute(
          RemoveIfNullOperator(),
          DartFixKind.REMOVE_IF_NULL_OPERATOR,
        );
      }
    }
  }

  /// Prepares proposal for creating function corresponding to the given
  /// [FunctionType].
  Future<DartChangeBuilder> _addProposal_createFunction(
      FunctionType functionType,
      String name,
      String targetFile,
      int insertOffset,
      bool isStatic,
      String prefix,
      String sourcePrefix,
      String sourceSuffix,
      Element target) async {
    // build method source
    var changeBuilder = _newDartChangeBuilder();
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
        var parameterNames = <String>{};
        for (int i = 0; i < parameters.length; i++) {
          var name = parameters[i].name;
          if (name.isNotEmpty) {
            parameterNames.add(name);
          }
        }
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
            var name = parameter.name;
            if (name.isEmpty) {
              name = _generateUniqueName(parameterNames, 'p');
              parameterNames.add(name);
            }
            builder.write(name);
          });
        }
        builder.write(')');
        // close method
        builder.write(' {$eol$prefix}');
        builder.write(sourceSuffix);
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
    return changeBuilder;
  }

  /// Adds proposal for creating method corresponding to the given
  /// [FunctionType] in the given [ClassElement].
  Future<void> _addProposal_createFunction_function(
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
        file,
        insertOffset,
        false,
        prefix,
        sourcePrefix,
        sourceSuffix,
        unit.declaredElement);
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FUNCTION,
        args: [name]);
  }

  /// Adds proposal for creating method corresponding to the given
  /// [FunctionType] in the given [ClassElement].
  Future<void> _addProposal_createFunction_method(
      ClassElement targetClassElement, FunctionType functionType) async {
    String name = (node as SimpleIdentifier).name;
    // prepare environment
    Source targetSource = targetClassElement.source;
    // prepare insert offset
    var targetNode = await _getClassDeclaration(targetClassElement);
    if (targetNode == null) {
      return;
    }
    int insertOffset = targetNode.end - 1;
    // prepare prefix
    String prefix = '  ';
    String sourcePrefix;
    if (targetNode.members.isEmpty) {
      sourcePrefix = '';
    } else {
      sourcePrefix = eol;
    }
    String sourceSuffix = eol;
    DartChangeBuilder changeBuilder = await _addProposal_createFunction(
        functionType,
        name,
        targetSource.fullName,
        insertOffset,
        _inStaticContext(),
        prefix,
        sourcePrefix,
        sourceSuffix,
        targetClassElement);
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_METHOD, args: [name]);
  }

  List<SimpleIdentifier> _findAllReferences(AstNode root, Element element) {
    var collector = _ElementReferenceCollector(element);
    root.accept(collector);
    return collector.references;
  }

  /// Generate a name that does not occur in [existingNames] that begins with
  /// the given [prefix].
  String _generateUniqueName(Set<String> existingNames, String prefix) {
    var index = 1;
    var name = '$prefix$index';
    while (existingNames.contains(name)) {
      index++;
      name = '$prefix$index';
    }
    return name;
  }

  /// Return the class, enum or mixin declaration for the given [element].
  Future<ClassOrMixinDeclaration> _getClassDeclaration(
      ClassElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    if (result.node is ClassOrMixinDeclaration) {
      return result.node;
    }
    return null;
  }

  /// Return the string to display as the name of the given constructor in a
  /// proposal name.
  String _getConstructorProposalName(ConstructorElement constructor) {
    StringBuffer buffer = StringBuffer();
    buffer.write('super');
    String constructorName = constructor.displayName;
    if (constructorName.isNotEmpty) {
      buffer.write('.');
      buffer.write(constructorName);
    }
    buffer.write('(...)');
    return buffer.toString();
  }

  /// Return the extension declaration for the given [element].
  Future<ExtensionDeclaration> _getExtensionDeclaration(
      ExtensionElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    if (result.node is ExtensionDeclaration) {
      return result.node;
    }
    return null;
  }

  /// Return the relative uri from the passed [library] to the given [path].
  /// If the [path] is not in the LibraryElement, `null` is returned.
  String _getRelativeURIFromLibrary(LibraryElement library, String path) {
    var librarySource = library?.librarySource;
    if (librarySource == null) {
      return null;
    }
    var pathCtx = resourceProvider.pathContext;
    var libraryDirectory = pathCtx.dirname(librarySource.fullName);
    var sourceDirectory = pathCtx.dirname(path);
    if (pathCtx.isWithin(libraryDirectory, path) ||
        pathCtx.isWithin(sourceDirectory, libraryDirectory)) {
      String relativeFile = pathCtx.relative(path, from: libraryDirectory);
      return pathCtx.split(relativeFile).join('/');
    }
    return null;
  }

  /// Returns an expected [DartType] of [expression], may be `null` if cannot be
  /// inferred.
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
        VariableElement variableElement = variableDeclaration.declaredElement;
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
          return rhs.staticType;
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
            return lhs.staticType;
          }
        } else {
          // v += myFunction();
          MethodElement method = assignment.staticElement;
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
      MethodElement method = binary.staticElement;
      if (method != null) {
        if (binary.rightOperand == expression) {
          List<ParameterElement> parameters = method.parameters;
          return parameters.length == 1 ? parameters[0].type : null;
        }
      }
    }
    // foo( myFunction() );
    if (parent is ArgumentList) {
      ParameterElement parameter = expression.staticParameterElement;
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

  /// Returns `true` if [node] is in static context.
  bool _inStaticContext() {
    // constructor initializer cannot reference "this"
    if (node.thisOrAncestorOfType<ConstructorInitializer>() != null) {
      return true;
    }
    // field initializer cannot reference "this"
    if (node.thisOrAncestorOfType<FieldDeclaration>() != null) {
      return true;
    }
    // static method
    MethodDeclaration method = node.thisOrAncestorOfType<MethodDeclaration>();
    return method != null && method.isStatic;
  }

  bool _isAwaitNode() {
    AstNode node = this.node;
    return node is SimpleIdentifier && node.name == 'await';
  }

  bool _isCastMethodElement(MethodElement method) {
    if (method.name != 'cast') {
      return false;
    }
    ClassElement definingClass = method.enclosingElement;
    return _isDartCoreIterableElement(definingClass) ||
        _isDartCoreListElement(definingClass) ||
        _isDartCoreMapElement(definingClass) ||
        _isDartCoreSetElement(definingClass);
  }

  bool _isCastMethodInvocation(Expression expression) {
    if (expression is MethodInvocation) {
      Element element = expression.methodName.staticElement;
      return element is MethodElement && _isCastMethodElement(element);
    }
    return false;
  }

  bool _isDartCoreIterable(DartType type) =>
      type is InterfaceType && _isDartCoreIterableElement(type.element);

  bool _isDartCoreIterableElement(ClassElement element) =>
      element != null &&
      element.name == 'Iterable' &&
      element.library.isDartCore;

  bool _isDartCoreList(DartType type) =>
      type is InterfaceType && _isDartCoreListElement(type.element);

  bool _isDartCoreListElement(ClassElement element) =>
      element != null && element.name == 'List' && element.library.isDartCore;

  bool _isDartCoreMap(DartType type) =>
      type is InterfaceType && _isDartCoreMapElement(type.element);

  bool _isDartCoreMapElement(ClassElement element) =>
      element != null && element.name == 'Map' && element.library.isDartCore;

  bool _isDartCoreSet(DartType type) =>
      type is InterfaceType && _isDartCoreSetElement(type.element);

  bool _isDartCoreSetElement(ClassElement element) =>
      element != null && element.name == 'Set' && element.library.isDartCore;

  bool _isLibSrcPath(String path) {
    List<String> parts = resourceProvider.pathContext.split(path);
    for (int i = 0; i < parts.length - 2; i++) {
      if (parts[i] == 'lib' && parts[i + 1] == 'src') {
        return true;
      }
    }
    return false;
  }

  bool _isToListMethodElement(MethodElement method) {
    if (method.name != 'toList') {
      return false;
    }
    ClassElement definingClass = method.enclosingElement;
    return _isDartCoreIterableElement(definingClass) ||
        _isDartCoreListElement(definingClass);
  }

  bool _isToListMethodInvocation(Expression expression) {
    if (expression is MethodInvocation) {
      Element element = expression.methodName.staticElement;
      return element is MethodElement && _isToListMethodElement(element);
    }
    return false;
  }

  DartChangeBuilder _newDartChangeBuilder() {
    return DartChangeBuilderImpl.forWorkspace(context.workspace);
  }

  /// Removes any [ParenthesizedExpression] enclosing [expr].
  ///
  /// [exprPrecedence] - the effective precedence of [expr].
  void _removeEnclosingParentheses(
      DartFileEditBuilder builder, Expression expr, Precedence exprPrecedence) {
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

  void _updateFinderWithExtensionMembers(
      _ClosestElementFinder finder, ExtensionElement element) {
    if (element != null) {
      finder._updateList(getExtensionMembers(element));
    }
  }

  static ClassElement _getTargetClassElement(Expression target) {
    var type = target.staticType;
    if (type is InterfaceType) {
      return type.element;
    } else if (target is Identifier) {
      var element = target.staticElement;
      if (element is ClassElement) {
        return element;
      }
    }
    return null;
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

  /// Return `true` if the given [node] is in a location where an implicit
  /// constructor invocation would be allowed.
  static bool _mayBeImplicitConstructor(AstNode node) {
    if (node is SimpleIdentifier) {
      AstNode parent = node.parent;
      if (parent is MethodInvocation) {
        return parent.realTarget == null;
      }
    }
    return false;
  }

  /// Returns `true` if [node] is a type name.
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

  static String _replaceSourceIndent(
      String source, String indentOld, String indentNew) {
    return source.replaceAll(RegExp('^$indentOld', multiLine: true), indentNew);
  }
}

/// Helper for finding [Element] with name closest to the given.
class _ClosestElementFinder {
  final String _targetName;
  final ElementPredicate _predicate;

  Element _element;
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

class _ElementReferenceCollector extends RecursiveAstVisitor<void> {
  final Element element;
  final List<SimpleIdentifier> references = [];

  _ElementReferenceCollector(this.element);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final staticElement = node.staticElement;
    if (staticElement == element) {
      references.add(node);
    }
    // Implicit Setter.
    else if (staticElement is PropertyAccessorElement) {
      if (staticElement.variable == element) {
        references.add(node);
      }
      // Field Formals.
    } else if (staticElement is FieldFormalParameterElement) {
      if (staticElement.field == element) {
        references.add(node);
      }
    }
  }
}

/// [ExecutableElement], its parameters, and operations on them.
class _ExecutableParameters {
  final AnalysisSessionHelper sessionHelper;
  final ExecutableElement executable;

  final List<ParameterElement> required = [];
  final List<ParameterElement> optionalPositional = [];
  final List<ParameterElement> named = [];

  factory _ExecutableParameters(
      AnalysisSessionHelper sessionHelper, AstNode invocation) {
    Element element;
    // This doesn't handle FunctionExpressionInvocation.
    if (invocation is Annotation) {
      element = invocation.element;
    } else if (invocation is InstanceCreationExpression) {
      element = invocation.staticElement;
    } else if (invocation is MethodInvocation) {
      element = invocation.methodName.staticElement;
    } else if (invocation is ConstructorReferenceNode) {
      element = invocation.staticElement;
    }
    if (element is ExecutableElement && !element.isSynthetic) {
      return _ExecutableParameters._(sessionHelper, element);
    } else {
      return null;
    }
  }

  _ExecutableParameters._(this.sessionHelper, this.executable) {
    for (var parameter in executable.parameters) {
      if (parameter.isRequiredPositional) {
        required.add(parameter);
      } else if (parameter.isOptionalPositional) {
        optionalPositional.add(parameter);
      } else if (parameter.isNamed) {
        named.add(parameter);
      }
    }
  }

  String get file => executable.source.fullName;

  List<String> get namedNames {
    return named.map((parameter) => parameter.name).toList();
  }

  /// Return the [FormalParameterList] of the [executable], or `null` is cannot
  /// be found.
  Future<FormalParameterList> getParameterList() async {
    var result = await sessionHelper.getElementDeclaration(executable);
    var targetDeclaration = result.node;
    if (targetDeclaration is ConstructorDeclaration) {
      return targetDeclaration.parameters;
    } else if (targetDeclaration is FunctionDeclaration) {
      FunctionExpression function = targetDeclaration.functionExpression;
      return function.parameters;
    } else if (targetDeclaration is MethodDeclaration) {
      return targetDeclaration.parameters;
    }
    return null;
  }

  /// Return the [FormalParameter] of the [element] in [FormalParameterList],
  /// or `null` is cannot be found.
  Future<FormalParameter> getParameterNode(ParameterElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    var declaration = result.node;
    for (AstNode node = declaration; node != null; node = node.parent) {
      if (node is FormalParameter && node.parent is FormalParameterList) {
        return node;
      }
    }
    return null;
  }
}
