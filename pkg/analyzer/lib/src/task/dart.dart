// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.dart;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/dart/ast/ast.dart'
    show NamespaceDirectiveImpl, UriBasedDirectiveImpl, UriValidationCode;
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/dart/sdk/patch.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/pending_error.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/declaration_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/incremental_resolver.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/plugin/engine_plugin.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/src/task/inputs.dart';
import 'package:analyzer/src/task/model.dart';
import 'package:analyzer/src/task/strong/checker.dart';
import 'package:analyzer/src/task/strong_mode.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';

/**
 * The [ResultCachingPolicy] for ASTs.
 */
const ResultCachingPolicy<CompilationUnit> AST_CACHING_POLICY =
    const SimpleResultCachingPolicy(16384, 32);

/**
 * The [ResultCachingPolicy] for fully resolved ASTs.  It is separated from
 * [AST_CACHING_POLICY] because we want to keep some number of fully resolved
 * ASTs when users switch between contexts, and they should not be pushed out
 * of the cache by temporary partially resolved ASTs.
 */
const ResultCachingPolicy<CompilationUnit> AST_RESOLVED_CACHING_POLICY =
    const SimpleResultCachingPolicy(1024, 32);

/**
 * The [ResultCachingPolicy] for ASTs that can be reused when a library
 * on which the source depends is changed.  It is worth to keep some number
 * of these ASTs in memory in order to avoid parsing sources.  In contrast,
 * none of [AST_CACHING_POLICY] managed ASTs can be reused after a change, so
 * it is worth to keep them in memory while analysis is being performed, but
 * once analysis is done, they can be flushed.
 */
const ResultCachingPolicy<CompilationUnit> AST_REUSABLE_CACHING_POLICY =
    const SimpleResultCachingPolicy(1024, 64);

/**
 * The [ResultCachingPolicy] for lists of [ConstantEvaluationTarget]s.
 */
const ResultCachingPolicy<List<ConstantEvaluationTarget>>
    CONSTANT_EVALUATION_TARGET_LIST_POLICY =
    const SimpleResultCachingPolicy(-1, -1);

/**
 * The [ResultCachingPolicy] for [ConstantEvaluationTarget]s.
 */
const ResultCachingPolicy<ConstantEvaluationTarget>
    CONSTANT_EVALUATION_TARGET_POLICY = const SimpleResultCachingPolicy(-1, -1);

/**
 * The [ResultCachingPolicy] for [Element]s.
 */
const ResultCachingPolicy<Element> ELEMENT_CACHING_POLICY =
    const SimpleResultCachingPolicy(-1, -1);

/**
 * The [ResultCachingPolicy] for [TOKEN_STREAM].
 */
const ResultCachingPolicy<Token> TOKEN_STREAM_CACHING_POLICY =
    const SimpleResultCachingPolicy(1, 1);

/**
 * The [ResultCachingPolicy] for [UsedImportedElements]s.
 */
const ResultCachingPolicy<UsedImportedElements> USED_IMPORTED_ELEMENTS_POLICY =
    const SimpleResultCachingPolicy(-1, -1);

/**
 * The [ResultCachingPolicy] for [UsedLocalElements]s.
 */
const ResultCachingPolicy<UsedLocalElements> USED_LOCAL_ELEMENTS_POLICY =
    const SimpleResultCachingPolicy(-1, -1);

/**
 * The errors produced while building a library's directives.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<AnalysisError> BUILD_DIRECTIVES_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'BUILD_DIRECTIVES_ERRORS', AnalysisError.NO_ERRORS);
/**
 * The errors produced while building a library element.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<AnalysisError> BUILD_LIBRARY_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'BUILD_LIBRARY_ERRORS', AnalysisError.NO_ERRORS);

/**
 * A list of the [ConstantEvaluationTarget]s defined in a unit.  This includes
 * constants defined at top level, statically inside classes, and local to
 * functions, as well as constant constructors, annotations, and default values
 * of parameters.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<ConstantEvaluationTarget>
    COMPILATION_UNIT_CONSTANTS =
    new ListResultDescriptor<ConstantEvaluationTarget>(
        'COMPILATION_UNIT_CONSTANTS', null,
        cachingPolicy: CONSTANT_EVALUATION_TARGET_LIST_POLICY);

/**
 * The element model associated with a single compilation unit.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnitElement> COMPILATION_UNIT_ELEMENT =
    new ResultDescriptor<CompilationUnitElement>(
        'COMPILATION_UNIT_ELEMENT', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The list of [ConstantEvaluationTarget]s on which the target constant element
 * depends.
 *
 * The result is only available for targets representing a
 * [ConstantEvaluationTarget] (i.e. a constant variable declaration, a constant
 * constructor, or a parameter element with a default value).
 */
final ListResultDescriptor<ConstantEvaluationTarget> CONSTANT_DEPENDENCIES =
    new ListResultDescriptor<ConstantEvaluationTarget>(
        'CONSTANT_DEPENDENCIES', const <ConstantEvaluationTarget>[]);

/**
 * The flag specifying that the target constant element expression AST is
 * resolved, i.e. identifiers have all required elements set.
 *
 * The result is only available for targets representing a
 * [ConstantEvaluationTarget] (i.e. a constant variable declaration, a constant
 * constructor, or a parameter element with a default value).
 */
final ResultDescriptor<bool> CONSTANT_EXPRESSION_RESOLVED =
    new ResultDescriptor<bool>('CONSTANT_EXPRESSION_RESOLVED', false);

/**
 * The list of [ConstantEvaluationTarget]s on which constant expressions of a
 * unit depend.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<ConstantEvaluationTarget>
    CONSTANT_EXPRESSIONS_DEPENDENCIES =
    new ListResultDescriptor<ConstantEvaluationTarget>(
        'CONSTANT_EXPRESSIONS_DEPENDENCIES',
        const <ConstantEvaluationTarget>[]);

/**
 * A [ConstantEvaluationTarget] that has been successfully constant-evaluated.
 *
 * TODO(paulberry): is ELEMENT_CACHING_POLICY the correct caching policy?
 *
 * The result is only available for [ConstantEvaluationTarget]s.
 *
 */
final ResultDescriptor<ConstantEvaluationTarget> CONSTANT_VALUE =
    new ResultDescriptor<ConstantEvaluationTarget>('CONSTANT_VALUE', null,
        cachingPolicy: CONSTANT_EVALUATION_TARGET_POLICY);

/**
 * The sources representing the libraries that include a given source as a part.
 *
 * The result is only available for [Source]s representing a compilation unit.
 */
final ListResultDescriptor<Source> CONTAINING_LIBRARIES =
    new ListResultDescriptor<Source>('CONTAINING_LIBRARIES', Source.EMPTY_LIST);

/**
 * The flag specifying that [RESOLVED_UNIT] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT', false);

/**
 * The flag specifying that [RESOLVED_UNIT1] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT1 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT1', false);

/**
 * The flag specifying that [RESOLVED_UNIT10] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT10 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT10', false);

/**
 * The flag specifying that [RESOLVED_UNIT11] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT11 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT11', false);

/**
 * The flag specifying that [RESOLVED_UNIT12] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT12 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT12', false);

/**
 * The flag specifying that [RESOLVED_UNIT2] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT2 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT2', false);

/**
 * The flag specifying that [RESOLVED_UNIT3] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT3 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT3', false);

/**
 * The flag specifying that [RESOLVED_UNIT4] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT4 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT4', false);

/**
 * The flag specifying that [RESOLVED_UNIT5] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT5 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT5', false);

/**
 * The flag specifying that [RESOLVED_UNIT6] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT6 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT6', false);

/**
 * The flag specifying that [RESOLVED_UNIT7] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT7 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT7', false);

/**
 * The flag specifying that [RESOLVED_UNIT8] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT8 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT8', false);

/**
 * The flag specifying that [RESOLVED_UNIT9] has been been computed for this
 * compilation unit (without requiring that the AST for it still be in cache).
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<bool> CREATED_RESOLVED_UNIT9 =
    new ResultDescriptor<bool>('CREATED_RESOLVED_UNIT9', false);

/**
 * All [AnalysisError]s results for [Source]s.
 */
final List<ListResultDescriptor<AnalysisError>> ERROR_SOURCE_RESULTS =
    <ListResultDescriptor<AnalysisError>>[
  BUILD_DIRECTIVES_ERRORS,
  BUILD_LIBRARY_ERRORS,
  PARSE_ERRORS,
  SCAN_ERRORS,
];

/**
 * All [AnalysisError]s results in for [LibrarySpecificUnit]s.
 */
final List<ListResultDescriptor<AnalysisError>> ERROR_UNIT_RESULTS =
    <ListResultDescriptor<AnalysisError>>[
  HINTS,
  LIBRARY_UNIT_ERRORS,
  LINTS,
  RESOLVE_DIRECTIVES_ERRORS,
  RESOLVE_TYPE_BOUNDS_ERRORS,
  RESOLVE_TYPE_NAMES_ERRORS,
  RESOLVE_UNIT_ERRORS,
  STRONG_MODE_ERRORS,
  VARIABLE_REFERENCE_ERRORS,
  VERIFY_ERRORS
];

/**
 * The sources representing the export closure of a library.
 * The [Source]s include only library sources, not their units.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<Source> EXPORT_SOURCE_CLOSURE =
    new ListResultDescriptor<Source>('EXPORT_SOURCE_CLOSURE', null);

/**
 * The errors produced while generating hints a compilation unit.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<AnalysisError> HINTS =
    new ListResultDescriptor<AnalysisError>(
        'HINT_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The ignore information for a [Source].
 */
final ResultDescriptor<IgnoreInfo> IGNORE_INFO =
    new ResultDescriptor<IgnoreInfo>('IGNORE_INFO', null);

/**
 * A list of the [VariableElement]s whose type should be inferred that another
 * inferable static variable (the target) depends on.
 *
 * The result is only available for [VariableElement]s, and only when strong
 * mode is enabled.
 */
final ListResultDescriptor<VariableElement>
    INFERABLE_STATIC_VARIABLE_DEPENDENCIES =
    new ListResultDescriptor<VariableElement>(
        'INFERABLE_STATIC_VARIABLE_DEPENDENCIES', null);

/**
 * A list of the [VariableElement]s defined in a unit whose type should be
 * inferred. This includes variables defined at the library level as well as
 * static members inside classes.
 *
 * The result is only available for [LibrarySpecificUnit]s, and only when strong
 * mode is enabled.
 */
final ListResultDescriptor<VariableElement> INFERABLE_STATIC_VARIABLES_IN_UNIT =
    new ListResultDescriptor<VariableElement>(
        'INFERABLE_STATIC_VARIABLES_IN_UNIT', null);

/**
 * An inferable static variable ([VariableElement]) whose type has been
 * inferred.
 *
 * The result is only available for [VariableElement]s, and only when strong
 * mode is enabled.
 */
final ResultDescriptor<VariableElement> INFERRED_STATIC_VARIABLE =
    new ResultDescriptor<VariableElement>('INFERRED_STATIC_VARIABLE', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * A list of the [LibraryElement]s that make up the strongly connected
 * component in the import/export graph in which the target resides.
 *
 * Only non-empty in strongMode.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<LibraryElement> LIBRARY_CYCLE =
    new ListResultDescriptor<LibraryElement>('LIBRARY_CYCLE', null);

/**
 * A list of the [LibrarySpecificUnit]s that comprise all of the parts and
 * libraries in the direct import/export dependencies of the library cycle
 * of the target, with the intra-component dependencies excluded.
 *
 * Only non-empty in strongMode.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<LibrarySpecificUnit> LIBRARY_CYCLE_DEPENDENCIES =
    new ListResultDescriptor<LibrarySpecificUnit>(
        'LIBRARY_CYCLE_DEPENDENCIES', null);

/**
 * A list of the [LibrarySpecificUnit]s (including all parts) that make up
 * the strongly connected component in the import/export graph in which the
 * target resides.
 *
 * Only non-empty in strongMode.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<LibrarySpecificUnit> LIBRARY_CYCLE_UNITS =
    new ListResultDescriptor<LibrarySpecificUnit>('LIBRARY_CYCLE_UNITS', null);

/**
 * The partial [LibraryElement] associated with a library.
 *
 * The [LibraryElement] and its [CompilationUnitElement]s are attached to each
 * other. Directives 'library', 'part' and 'part of' are resolved.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT1 =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT1', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The partial [LibraryElement] associated with a library.
 *
 * In addition to [LIBRARY_ELEMENT1] also [LibraryElement.imports] and
 * [LibraryElement.exports] are set.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT2 =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT2', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The partial [LibraryElement] associated with a library.
 *
 * In addition to [LIBRARY_ELEMENT2] the [LibraryElement.publicNamespace] is set.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT3 =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT3', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The partial [LibraryElement] associated with a library.
 *
 * In addition to [LIBRARY_ELEMENT3] the [LibraryElement.entryPoint] is set,
 * if the library does not declare one already and one of the exported
 * libraries exports one.
 *
 * Also [LibraryElement.exportNamespace] is set.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT4 =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT4', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The partial [LibraryElement] associated with a library.
 *
 * [LIBRARY_ELEMENT5] plus resolved types type parameter bounds.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT5 =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT5', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The partial [LibraryElement] associated with a library.
 *
 * [LIBRARY_ELEMENT5] plus resolved types for every element.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT6 =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT6', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The partial [LibraryElement] associated with a library.
 *
 * [LIBRARY_ELEMENT6] plus [RESOLVED_UNIT7] for all library units.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT7 =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT7', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The partial [LibraryElement] associated with a library.
 *
 * [LIBRARY_ELEMENT7] for the library and its import/export closure.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT8 =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT8', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The partial [LibraryElement] associated with a library.
 *
 * The same as a [LIBRARY_ELEMENT8].
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT9 =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT9', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * List of all `LIBRARY_ELEMENT` results.
 */
final List<ResultDescriptor<LibraryElement>> LIBRARY_ELEMENT_RESULTS =
    <ResultDescriptor<LibraryElement>>[
  LIBRARY_ELEMENT1,
  LIBRARY_ELEMENT2,
  LIBRARY_ELEMENT3,
  LIBRARY_ELEMENT4,
  LIBRARY_ELEMENT5,
  LIBRARY_ELEMENT6,
  LIBRARY_ELEMENT7,
  LIBRARY_ELEMENT8,
  LIBRARY_ELEMENT9,
  LIBRARY_ELEMENT
];

/**
 * The flag specifying whether all analysis errors are computed in a specific
 * library.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<bool> LIBRARY_ERRORS_READY =
    new ResultDescriptor<bool>('LIBRARY_ERRORS_READY', false);

/**
 * The [LibrarySpecificUnit]s that a library consists of.
 *
 * The list will include the defining unit and units for [INCLUDED_PARTS].
 * So, it is never empty or `null`.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<LibrarySpecificUnit> LIBRARY_SPECIFIC_UNITS =
    new ListResultDescriptor<LibrarySpecificUnit>(
        'LIBRARY_SPECIFIC_UNITS', LibrarySpecificUnit.EMPTY_LIST);

/**
 * The analysis errors associated with a compilation unit in a specific library.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<AnalysisError> LIBRARY_UNIT_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'LIBRARY_UNIT_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The errors produced while generating lints for a compilation unit.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<AnalysisError> LINTS =
    new ListResultDescriptor<AnalysisError>(
        'LINT_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The errors produced while parsing a compilation unit.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [Source]s representing a compilation unit.
 */
final ListResultDescriptor<AnalysisError> PARSE_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'PARSE_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The list of [PendingError]s for a compilation unit.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<PendingError> PENDING_ERRORS =
    new ListResultDescriptor<PendingError>(
        'PENDING_ERRORS', const <PendingError>[]);

/**
 * The flag specifying that [LIBRARY_ELEMENT2] is ready for a library and its
 * import/export closure.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<bool> READY_LIBRARY_ELEMENT2 =
    new ResultDescriptor<bool>('READY_LIBRARY_ELEMENT2', false);

/**
 * The flag specifying that [LIBRARY_ELEMENT6] is ready for a library and its
 * import/export closure.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<bool> READY_LIBRARY_ELEMENT6 =
    new ResultDescriptor<bool>('READY_LIBRARY_ELEMENT6', false);

/**
 * The flag specifying that [LIBRARY_ELEMENT7] is ready for a library and its
 * import/export closure.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<bool> READY_LIBRARY_ELEMENT7 =
    new ResultDescriptor<bool>('READY_LIBRARY_ELEMENT7', false);

/**
 * The flag specifying that [RESOLVED_UNIT] is ready for all of the units of a
 * library.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<bool> READY_RESOLVED_UNIT =
    new ResultDescriptor<bool>('READY_RESOLVED_UNIT', false);

/**
 * The sources of the Dart files that a library references.
 *
 * The list is the union of [IMPORTED_LIBRARIES], [EXPORTED_LIBRARIES] and
 * [UNITS] of the defining unit and [INCLUDED_PARTS]. Never empty or `null`.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<Source> REFERENCED_SOURCES =
    new ListResultDescriptor<Source>('REFERENCED_SOURCES', Source.EMPTY_LIST);

/**
 * The list of [ConstantEvaluationTarget]s on which error verification depends.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<ConstantEvaluationTarget> REQUIRED_CONSTANTS =
    new ListResultDescriptor<ConstantEvaluationTarget>(
        'REQUIRED_CONSTANTS', const <ConstantEvaluationTarget>[]);

/**
 * The errors produced while resolving a library's directives.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<AnalysisError> RESOLVE_DIRECTIVES_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'RESOLVE_DIRECTIVES_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The errors produced while resolving bounds of type parameters of classes,
 * class and function aliases.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<AnalysisError> RESOLVE_TYPE_BOUNDS_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'RESOLVE_TYPE_BOUNDS_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The errors produced while resolving type names.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<AnalysisError> RESOLVE_TYPE_NAMES_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'RESOLVE_TYPE_NAMES_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The errors produced while resolving a full compilation unit.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<AnalysisError> RESOLVE_UNIT_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'RESOLVE_UNIT_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The partially resolved [CompilationUnit] associated with a compilation unit.
 *
 * Tasks that use this value as an input can assume that the [SimpleIdentifier]s
 * at all declaration sites have been bound to the element defined by the
 * declaration, except for the constants defined in an 'enum' declaration.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT1 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT1', null,
        cachingPolicy: AST_REUSABLE_CACHING_POLICY);

/**
 * The resolved [CompilationUnit] associated with a compilation unit in which
 * the types of class members have been inferred in addition to everything that
 * is true of a [RESOLVED_UNIT9].
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT10 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT10', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The resolved [CompilationUnit] associated with a compilation unit, with
 * constants not yet resolved.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT11 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT11', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The resolved [CompilationUnit] associated with a compilation unit, with
 * constants resolved.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT12 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT12', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a compilation unit.
 *
 * In addition to what is true of a [RESOLVED_UNIT1], tasks that use this value
 * as an input can assume that its directives have been resolved.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT2 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT2', null,
        cachingPolicy: AST_REUSABLE_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a compilation unit.
 *
 * Tasks that use this value as an input can assume that the [SimpleIdentifier]s
 * at all declaration sites have been bound to the element defined by the
 * declaration, including the constants defined in an 'enum' declaration.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT3 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT3', null,
        cachingPolicy: AST_REUSABLE_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a compilation unit.
 *
 * In addition to what is true of a [RESOLVED_UNIT3], tasks that use this value
 * as an input can assume that the types associated with type bounds have been
 * resolved.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT4 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT4', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a compilation unit.
 *
 * In addition to what is true of a [RESOLVED_UNIT4], tasks that use this value
 * as an input can assume that the types associated with declarations have been
 * resolved. This includes the types of superclasses, mixins, interfaces,
 * fields, return types, parameters, and local variables.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT5 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT5', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a compilation unit.
 *
 * In addition to what is true of a [RESOLVED_UNIT5], tasks that use this value
 * as an input can assume that references to local variables and formal
 * parameters have been resolved.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT6 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT6', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a compilation unit.
 *
 * In addition to what is true of a [RESOLVED_UNIT6], tasks that use this value
 * as an input can assume that elements and types associated with expressions
 * outside of method bodies (essentially initializers) have been initially
 * resolved.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT7 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT7', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a compilation unit.
 *
 * In addition to what is true of a [RESOLVED_UNIT7], tasks that use this value
 * as an input can assume that the types of static variables have been inferred.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT8 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT8', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a compilation unit.
 *
 * In addition to what is true of a [RESOLVED_UNIT8], tasks that use this value
 * as an input can assume that the initializers of instance variables have been
 * re-resolved.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT9 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT9', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * List of all `RESOLVED_UNITx` results.
 */
final List<ResultDescriptor<CompilationUnit>> RESOLVED_UNIT_RESULTS =
    <ResultDescriptor<CompilationUnit>>[
  RESOLVED_UNIT1,
  RESOLVED_UNIT2,
  RESOLVED_UNIT3,
  RESOLVED_UNIT4,
  RESOLVED_UNIT5,
  RESOLVED_UNIT6,
  RESOLVED_UNIT7,
  RESOLVED_UNIT8,
  RESOLVED_UNIT9,
  RESOLVED_UNIT10,
  RESOLVED_UNIT11,
  RESOLVED_UNIT12,
  RESOLVED_UNIT
];

/**
 * The errors produced while scanning a compilation unit.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [Source]s representing a compilation unit.
 */
final ListResultDescriptor<AnalysisError> SCAN_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'SCAN_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The errors produced while resolving a static [VariableElement] initializer.
 *
 * The result is only available for [VariableElement]s, and only when strong
 * mode is enabled.
 */
final ListResultDescriptor<AnalysisError> STATIC_VARIABLE_RESOLUTION_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'STATIC_VARIABLE_RESOLUTION_ERRORS', AnalysisError.NO_ERRORS);

/**
 * A list of the [AnalysisError]s reported while resolving static
 * [INFERABLE_STATIC_VARIABLES_IN_UNIT] defined in a unit.
 *
 * The result is only available for [LibrarySpecificUnit]s, and only when strong
 * mode is enabled.
 */
final ListResultDescriptor<AnalysisError>
    STATIC_VARIABLE_RESOLUTION_ERRORS_IN_UNIT =
    new ListResultDescriptor<AnalysisError>(
        'STATIC_VARIABLE_RESOLUTION_ERRORS_IN_UNIT', AnalysisError.NO_ERRORS);

/**
 * The additional strong mode errors produced while verifying a
 * compilation unit.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [LibrarySpecificUnits]s representing a
 * compilation unit.
 *
 */
final ListResultDescriptor<AnalysisError> STRONG_MODE_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'STRONG_MODE_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The [TypeProvider] of the [AnalysisContext].
 */
final ResultDescriptor<TypeProvider> TYPE_PROVIDER =
    new ResultDescriptor<TypeProvider>('TYPE_PROVIDER', null);

/**
 * The [UsedImportedElements] of a [LibrarySpecificUnit].
 */
final ResultDescriptor<UsedImportedElements> USED_IMPORTED_ELEMENTS =
    new ResultDescriptor<UsedImportedElements>('USED_IMPORTED_ELEMENTS', null,
        cachingPolicy: USED_IMPORTED_ELEMENTS_POLICY);

/**
 * The [UsedLocalElements] of a [LibrarySpecificUnit].
 */
final ResultDescriptor<UsedLocalElements> USED_LOCAL_ELEMENTS =
    new ResultDescriptor<UsedLocalElements>('USED_LOCAL_ELEMENTS', null,
        cachingPolicy: USED_LOCAL_ELEMENTS_POLICY);

/**
 * The errors produced while resolving variable references in a compilation unit.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<AnalysisError> VARIABLE_REFERENCE_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'VARIABLE_REFERENCE_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The errors produced while verifying a compilation unit.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<AnalysisError> VERIFY_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'VERIFY_ERRORS', AnalysisError.NO_ERRORS);

/**
 * Return a list of unique errors for the [Source] of the given [target].
 */
List<AnalysisError> getTargetSourceErrors(
    RecordingErrorListener listener, AnalysisTarget target) {
  Source source = target.source;
  List<AnalysisError> errors = listener.getErrorsForSource(source);
  return getUniqueErrors(errors);
}

/**
 * Return a list of errors containing the errors from the given [errors] list
 * but with duplications removed.
 */
List<AnalysisError> getUniqueErrors(List<AnalysisError> errors) {
  if (errors.isEmpty) {
    return errors;
  }
  return errors.toSet().toList();
}

/**
 * A task that builds a compilation unit element for a single compilation unit.
 */
class BuildCompilationUnitElementTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the AST for the compilation unit.
   */
  static const String PARSED_UNIT_INPUT_NAME = 'PARSED_UNIT_INPUT_NAME';

  /**
   * The name of the input whose value is the source line info.
   */
  static const String LINE_INFO_INPUT_NAME = 'LINE_INFO_INPUT_NAME';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildCompilationUnitElementTask',
      createTask,
      buildInputs, <ResultDescriptor>[
    COMPILATION_UNIT_CONSTANTS,
    COMPILATION_UNIT_ELEMENT,
    CREATED_RESOLVED_UNIT1,
    RESOLVED_UNIT1
  ]);

  /**
   * Initialize a newly created task to build a compilation unit element for
   * the given [target] in the given [context].
   */
  BuildCompilationUnitElementTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    LibrarySpecificUnit librarySpecificUnit = target;
    Source source = getRequiredSource();
    CompilationUnit unit = getRequiredInput(PARSED_UNIT_INPUT_NAME);
    LineInfo lineInfo = getRequiredInput(LINE_INFO_INPUT_NAME);
    //
    // Try to get the existing CompilationUnitElement.
    //
    CompilationUnitElement element;
    {
      InternalAnalysisContext internalContext =
          context as InternalAnalysisContext;
      AnalysisCache analysisCache = internalContext.analysisCache;
      CacheEntry cacheEntry = internalContext.getCacheEntry(target);
      element = analysisCache.getValue(target, COMPILATION_UNIT_ELEMENT);
      if (element == null &&
          internalContext.aboutToComputeResult(
              cacheEntry, COMPILATION_UNIT_ELEMENT)) {
        element = analysisCache.getValue(target, COMPILATION_UNIT_ELEMENT);
      }
    }
    //
    // Build or reuse CompilationUnitElement.
    //
    if (element == null) {
      CompilationUnitBuilder builder = new CompilationUnitBuilder();
      element = builder.buildCompilationUnit(
          source, unit, librarySpecificUnit.library);
      (element as CompilationUnitElementImpl).lineInfo = lineInfo;
    } else {
      new DeclarationResolver().resolve(unit, element);
    }
    //
    // Prepare constants.
    //
    ConstantFinder constantFinder = new ConstantFinder();
    unit.accept(constantFinder);
    List<ConstantEvaluationTarget> constants =
        constantFinder.constantsToCompute.toList();
    //
    // Record outputs.
    //
    outputs[COMPILATION_UNIT_CONSTANTS] = constants;
    outputs[COMPILATION_UNIT_ELEMENT] = element;
    outputs[RESOLVED_UNIT1] = unit;
    outputs[CREATED_RESOLVED_UNIT1] = true;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      PARSED_UNIT_INPUT_NAME: PARSED_UNIT.of(unit.unit, flushOnAccess: true),
      LINE_INFO_INPUT_NAME: LINE_INFO.of(unit.unit)
    };
  }

  /**
   * Create a [BuildCompilationUnitElementTask] based on the given [target] in
   * the given [context].
   */
  static BuildCompilationUnitElementTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildCompilationUnitElementTask(context, target);
  }
}

/**
 * A task that builds imports and export directive elements for a library.
 */
class BuildDirectiveElementsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the defining [LIBRARY_ELEMENT1].
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The name of the input for [RESOLVED_UNIT1] of a library unit.
   */
  static const String UNIT_INPUT_NAME = 'UNIT_INPUT_NAME';

  /**
   * The input with a map from referenced sources to their modification times.
   */
  static const String SOURCES_MODIFICATION_TIME_INPUT_NAME =
      'SOURCES_MODIFICATION_TIME_INPUT_NAME';

  /**
   * The input with a list of [LIBRARY_ELEMENT3]s of imported libraries.
   */
  static const String IMPORTS_LIBRARY_ELEMENT_INPUT_NAME =
      'IMPORTS_LIBRARY_ELEMENT1_INPUT_NAME';

  /**
   * The input with a list of [LIBRARY_ELEMENT3]s of exported libraries.
   */
  static const String EXPORTS_LIBRARY_ELEMENT_INPUT_NAME =
      'EXPORTS_LIBRARY_ELEMENT_INPUT_NAME';

  /**
   * The input with a list of [SOURCE_KIND]s of imported libraries.
   */
  static const String IMPORTS_SOURCE_KIND_INPUT_NAME =
      'IMPORTS_SOURCE_KIND_INPUT_NAME';

  /**
   * The input with a list of [SOURCE_KIND]s of exported libraries.
   */
  static const String EXPORTS_SOURCE_KIND_INPUT_NAME =
      'EXPORTS_SOURCE_KIND_INPUT_NAME';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildDirectiveElementsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT2, BUILD_DIRECTIVES_ERRORS]);

  BuildDirectiveElementsTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    LibraryElementImpl libraryElement = getRequiredInput(LIBRARY_INPUT);
    CompilationUnit libraryUnit = getRequiredInput(UNIT_INPUT_NAME);
    Map<Source, int> sourceModificationTimeMap =
        getRequiredInput(SOURCES_MODIFICATION_TIME_INPUT_NAME);
    Map<Source, LibraryElement> importLibraryMap =
        getRequiredInput(IMPORTS_LIBRARY_ELEMENT_INPUT_NAME);
    Map<Source, LibraryElement> exportLibraryMap =
        getRequiredInput(EXPORTS_LIBRARY_ELEMENT_INPUT_NAME);
    Map<Source, SourceKind> importSourceKindMap =
        getRequiredInput(IMPORTS_SOURCE_KIND_INPUT_NAME);
    Map<Source, SourceKind> exportSourceKindMap =
        getRequiredInput(EXPORTS_SOURCE_KIND_INPUT_NAME);
    //
    // Try to get the existing LibraryElement.
    //
    LibraryElement element;
    {
      InternalAnalysisContext internalContext =
          context as InternalAnalysisContext;
      AnalysisCache analysisCache = internalContext.analysisCache;
      CacheEntry cacheEntry = internalContext.getCacheEntry(target);
      element = analysisCache.getValue(target, LIBRARY_ELEMENT2);
      if (element == null &&
          internalContext.aboutToComputeResult(cacheEntry, LIBRARY_ELEMENT2)) {
        element = analysisCache.getValue(target, LIBRARY_ELEMENT2);
      }
    }
    //
    // Build or reuse the directive elements.
    //
    List<AnalysisError> errors;
    if (element == null) {
      DirectiveElementBuilder builder = new DirectiveElementBuilder(
          context,
          libraryElement,
          sourceModificationTimeMap,
          importLibraryMap,
          importSourceKindMap,
          exportLibraryMap,
          exportSourceKindMap);
      libraryUnit.accept(builder);
      // See the commentary in the computation of the LIBRARY_CYCLE result
      // for details on library cycle invalidation.
      libraryElement.invalidateLibraryCycles();
      errors = builder.errors;
    } else {
      DirectiveResolver resolver = new DirectiveResolver(
          sourceModificationTimeMap, importSourceKindMap, exportSourceKindMap);
      libraryUnit.accept(resolver);
      errors = resolver.errors;
    }
    //
    // Record outputs.
    //
    outputs[LIBRARY_ELEMENT2] = libraryElement;
    outputs[BUILD_DIRECTIVES_ERRORS] = errors;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given library [libSource].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT1.of(source),
      UNIT_INPUT_NAME:
          RESOLVED_UNIT1.of(new LibrarySpecificUnit(source, source)),
      SOURCES_MODIFICATION_TIME_INPUT_NAME:
          REFERENCED_SOURCES.of(source).toMapOf(MODIFICATION_TIME),
      IMPORTS_LIBRARY_ELEMENT_INPUT_NAME:
          IMPORTED_LIBRARIES.of(source).toMapOf(LIBRARY_ELEMENT1),
      EXPORTS_LIBRARY_ELEMENT_INPUT_NAME:
          EXPORTED_LIBRARIES.of(source).toMapOf(LIBRARY_ELEMENT1),
      IMPORTS_SOURCE_KIND_INPUT_NAME:
          IMPORTED_LIBRARIES.of(source).toMapOf(SOURCE_KIND),
      EXPORTS_SOURCE_KIND_INPUT_NAME:
          EXPORTED_LIBRARIES.of(source).toMapOf(SOURCE_KIND)
    };
  }

  /**
   * Create a [BuildDirectiveElementsTask] based on the given [target] in
   * the given [context].
   */
  static BuildDirectiveElementsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildDirectiveElementsTask(context, target);
  }
}

/**
 * A task that builds the elements representing the members of enum
 * declarations.
 */
class BuildEnumMemberElementsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The name of the [RESOLVED_UNIT1] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildEnumMemberElementsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[CREATED_RESOLVED_UNIT3, RESOLVED_UNIT3]);

  BuildEnumMemberElementsTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    //
    // Build the enum members if they have not already been created.
    //
    EnumDeclaration findFirstEnum() {
      NodeList<CompilationUnitMember> members = unit.declarations;
      int length = members.length;
      for (int i = 0; i < length; i++) {
        CompilationUnitMember member = members[i];
        if (member is EnumDeclaration) {
          return member;
        }
      }
      return null;
    }

    EnumDeclaration firstEnum = findFirstEnum();
    if (firstEnum != null &&
        resolutionMap
            .elementDeclaredByEnumDeclaration(firstEnum)
            .accessors
            .isEmpty) {
      EnumMemberBuilder builder = new EnumMemberBuilder(typeProvider);
      unit.accept(builder);
    }
    //
    // Record outputs.
    //
    outputs[CREATED_RESOLVED_UNIT3] = true;
    outputs[RESOLVED_UNIT3] = unit;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request),
      UNIT_INPUT: RESOLVED_UNIT2.of(unit)
    };
  }

  /**
   * Create a [BuildEnumMemberElementsTask] based on the given [target] in
   * the given [context].
   */
  static BuildEnumMemberElementsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildEnumMemberElementsTask(context, target);
  }
}

/**
 * A task that builds [EXPORT_NAMESPACE] and [LIBRARY_ELEMENT4] for a library.
 */
class BuildExportNamespaceTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input for [LIBRARY_ELEMENT3] of a library.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildExportNamespaceTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT4]);

  BuildExportNamespaceTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibraryElementImpl library = getRequiredInput(LIBRARY_INPUT);
    //
    // Compute export namespace.
    //
    library.exportNamespace = null;
    NamespaceBuilder builder = new NamespaceBuilder();
    Namespace namespace = builder.createExportNamespaceForLibrary(library);
    library.exportNamespace = namespace;
    //
    // Update entry point.
    //
    if (library.entryPoint == null) {
      Iterable<Element> exportedElements = namespace.definedNames.values;
      library.entryPoint = exportedElements.firstWhere(
          (element) => element is FunctionElement && element.isEntryPoint,
          orElse: () => null);
    }
    //
    // Record outputs.
    //
    outputs[LIBRARY_ELEMENT4] = library;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given library [libSource].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT3.of(source),
      'exportsLibraryPublicNamespace':
          EXPORT_SOURCE_CLOSURE.of(source).toMapOf(LIBRARY_ELEMENT3)
    };
  }

  /**
   * Create a [BuildExportNamespaceTask] based on the given [target] in
   * the given [context].
   */
  static BuildExportNamespaceTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildExportNamespaceTask(context, target);
  }
}

/**
 * A task that builds a library element for a Dart library.
 */
class BuildLibraryElementTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the defining [RESOLVED_UNIT1].
   */
  static const String DEFINING_UNIT_INPUT = 'DEFINING_UNIT_INPUT';

  /**
   * The name of the input whose value is a list of built [RESOLVED_UNIT1]s
   * of the parts sourced by a library.
   */
  static const String PARTS_UNIT_INPUT = 'PARTS_UNIT_INPUT';

  /**
   * The name of the input whose value is the modification time of the source.
   */
  static const String MODIFICATION_TIME_INPUT = 'MODIFICATION_TIME_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildLibraryElementTask', createTask, buildInputs, <ResultDescriptor>[
    BUILD_LIBRARY_ERRORS,
    LIBRARY_ELEMENT1,
    IS_LAUNCHABLE
  ]);

  /**
   * The constant used as an unknown common library name in parts.
   */
  static const String _UNKNOWN_LIBRARY_NAME = 'unknown-library-name';

  /**
   * Initialize a newly created task to build a library element for the given
   * [target] in the given [context].
   */
  BuildLibraryElementTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    List<AnalysisError> errors = <AnalysisError>[];
    //
    // Prepare inputs.
    //
    Source librarySource = getRequiredSource();
    CompilationUnit definingCompilationUnit =
        getRequiredInput(DEFINING_UNIT_INPUT);
    List<CompilationUnit> partUnits = getRequiredInput(PARTS_UNIT_INPUT);
    int modificationTime = getRequiredInput(MODIFICATION_TIME_INPUT);
    //
    // Process inputs.
    //
    CompilationUnitElementImpl definingCompilationUnitElement =
        definingCompilationUnit.element;
    Map<Source, CompilationUnit> partUnitMap =
        new HashMap<Source, CompilationUnit>();
    int partLength = partUnits.length;
    for (int i = 0; i < partLength; i++) {
      CompilationUnit partUnit = partUnits[i];
      Source partSource =
          resolutionMap.elementDeclaredByCompilationUnit(partUnit).source;
      partUnitMap[partSource] = partUnit;
    }
    //
    // Update "part" directives.
    //
    LibraryIdentifier libraryNameNode = null;
    String partsLibraryName = _UNKNOWN_LIBRARY_NAME;
    bool hasPartDirective = false;
    Set<Source> seenPartSources = new Set<Source>();
    FunctionElement entryPoint =
        _findEntryPoint(definingCompilationUnitElement);
    List<Directive> directivesToResolve = <Directive>[];
    List<CompilationUnitElementImpl> sourcedCompilationUnits =
        <CompilationUnitElementImpl>[];
    NodeList<Directive> directives = definingCompilationUnit.directives;
    int directiveLength = directives.length;
    for (int i = 0; i < directiveLength; i++) {
      Directive directive = directives[i];
      if (directive is LibraryDirective) {
        libraryNameNode = directive.name;
        directivesToResolve.add(directive);
      } else if (directive is PartDirective) {
        StringLiteral partUri = directive.uri;
        Source partSource = directive.uriSource;
        hasPartDirective = true;
        CompilationUnit partUnit = partUnitMap[partSource];
        if (partUnit != null) {
          CompilationUnitElementImpl partElement = partUnit.element;
          partElement.uriOffset = partUri.offset;
          partElement.uriEnd = partUri.end;
          partElement.uri = directive.uriContent;
          //
          // Validate that the part source is unique in the library.
          //
          if (!seenPartSources.add(partSource)) {
            errors.add(new AnalysisError(
                librarySource,
                partUri.offset,
                partUri.length,
                CompileTimeErrorCode.DUPLICATE_PART,
                [partSource.uri]));
          }
          //
          // Validate that the part contains a part-of directive with the same
          // name as the library.
          //
          if (context.exists(partSource)) {
            _NameOrSource nameOrSource = _getPartLibraryNameOrUri(
                context, partSource, partUnit, directivesToResolve);
            if (nameOrSource == null) {
              errors.add(new AnalysisError(
                  librarySource,
                  partUri.offset,
                  partUri.length,
                  CompileTimeErrorCode.PART_OF_NON_PART,
                  [partUri.toSource()]));
            } else {
              String name = nameOrSource.name;
              if (name != null) {
                if (libraryNameNode == null) {
                  if (partsLibraryName == _UNKNOWN_LIBRARY_NAME) {
                    partsLibraryName = name;
                  } else if (partsLibraryName != name) {
                    partsLibraryName = null;
                  }
                } else if (libraryNameNode.name != name) {
                  errors.add(new AnalysisError(
                      librarySource,
                      partUri.offset,
                      partUri.length,
                      StaticWarningCode.PART_OF_DIFFERENT_LIBRARY,
                      [libraryNameNode.name, name]));
                }
              } else {
                Source source = nameOrSource.source;
                if (source != librarySource) {
                  errors.add(new AnalysisError(
                      librarySource,
                      partUri.offset,
                      partUri.length,
                      StaticWarningCode.PART_OF_DIFFERENT_LIBRARY,
                      [librarySource.uri.toString(), source.uri.toString()]));
                }
              }
            }
          }
          if (entryPoint == null) {
            entryPoint = _findEntryPoint(partElement);
          }
          directive.element = partElement;
          sourcedCompilationUnits.add(partElement);
        }
      }
    }
    if (hasPartDirective &&
        libraryNameNode == null &&
        !context.analysisOptions.enableUriInPartOf) {
      errors.add(new AnalysisError(librarySource, 0, 0,
          ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART));
    }
    //
    // Create and populate the library element.
    //
    AnalysisContext owningContext = context;
    if (context is InternalAnalysisContext) {
      InternalAnalysisContext internalContext = context;
      owningContext = internalContext.getContextFor(librarySource);
    }
    //
    // Try to get the existing LibraryElement.
    //
    LibraryElementImpl libraryElement;
    {
      InternalAnalysisContext internalContext =
          context as InternalAnalysisContext;
      AnalysisCache analysisCache = internalContext.analysisCache;
      CacheEntry cacheEntry = internalContext.getCacheEntry(target);
      libraryElement = analysisCache.getValue(target, LIBRARY_ELEMENT1)
          as LibraryElementImpl;
      if (libraryElement == null &&
          internalContext.aboutToComputeResult(cacheEntry, LIBRARY_ELEMENT1)) {
        libraryElement = analysisCache.getValue(target, LIBRARY_ELEMENT1)
            as LibraryElementImpl;
      }
    }
    //
    // Create a new LibraryElement.
    //
    if (libraryElement == null) {
      libraryElement =
          new LibraryElementImpl.forNode(owningContext, libraryNameNode);
      libraryElement.isSynthetic = modificationTime < 0;
      libraryElement.definingCompilationUnit = definingCompilationUnitElement;
      libraryElement.entryPoint = entryPoint;
      libraryElement.parts = sourcedCompilationUnits;
      libraryElement.hasExtUri = _hasExtUri(definingCompilationUnit);
      BuildLibraryElementUtils.patchTopLevelAccessors(libraryElement);
      // set the library documentation to the docs associated with the first
      // directive in the compilation unit.
      if (definingCompilationUnit.directives.isNotEmpty) {
        setElementDocumentationComment(
            libraryElement, definingCompilationUnit.directives.first);
      }
    }
    //
    // Resolve the relevant directives to the library element.
    //
    // TODO(brianwilkerson) This updates the state of the AST structures but
    // does not associate a new result with it.
    //
    int length = directivesToResolve.length;
    for (int i = 0; i < length; i++) {
      Directive directive = directivesToResolve[i];
      directive.element = libraryElement;
    }
    //
    // Record outputs.
    //
    outputs[BUILD_LIBRARY_ERRORS] = errors;
    outputs[LIBRARY_ELEMENT1] = libraryElement;
    outputs[IS_LAUNCHABLE] = entryPoint != null;
  }

  /**
   * Return the top-level [FunctionElement] entry point, or `null` if the given
   * [element] does not define an entry point.
   */
  FunctionElement _findEntryPoint(CompilationUnitElementImpl element) {
    List<FunctionElement> functions = element.functions;
    int length = functions.length;
    for (int i = 0; i < length; i++) {
      FunctionElement function = functions[i];
      if (function.isEntryPoint) {
        return function;
      }
    }
    return null;
  }

  /**
   * Return the name of the library that the given part is declared to be a
   * part of, or `null` if the part does not contain a part-of directive.
   */
  _NameOrSource _getPartLibraryNameOrUri(
      AnalysisContext context,
      Source partSource,
      CompilationUnit partUnit,
      List<Directive> directivesToResolve) {
    NodeList<Directive> directives = partUnit.directives;
    int length = directives.length;
    for (int i = 0; i < length; i++) {
      Directive directive = directives[i];
      if (directive is PartOfDirective) {
        directivesToResolve.add(directive);
        LibraryIdentifier libraryName = directive.libraryName;
        if (libraryName != null) {
          return new _NameOrSource(libraryName.name, null);
        }
        String uri = directive.uri?.stringValue;
        if (uri != null) {
          Source librarySource =
              context.sourceFactory.resolveUri(partSource, uri);
          if (librarySource != null) {
            return new _NameOrSource(null, librarySource);
          }
        }
      }
    }
    return null;
  }

  /**
   * Return `true` if the given compilation [unit] contains at least one
   * import directive with a `dart-ext:` URI.
   */
  bool _hasExtUri(CompilationUnit unit) {
    NodeList<Directive> directives = unit.directives;
    int length = directives.length;
    for (int i = 0; i < length; i++) {
      Directive directive = directives[i];
      if (directive is ImportDirective) {
        if (DartUriResolver.isDartExtUri(directive.uriContent)) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [libSource].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      DEFINING_UNIT_INPUT:
          RESOLVED_UNIT1.of(new LibrarySpecificUnit(source, source)),
      PARTS_UNIT_INPUT: INCLUDED_PARTS.of(source).toList((Source unit) {
        return RESOLVED_UNIT1.of(new LibrarySpecificUnit(source, unit));
      }),
      MODIFICATION_TIME_INPUT: MODIFICATION_TIME.of(source)
    };
  }

  /**
   * Create a [BuildLibraryElementTask] based on the given [target] in the
   * given [context].
   */
  static BuildLibraryElementTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildLibraryElementTask(context, target);
  }
}

/**
 * A task that builds [PUBLIC_NAMESPACE] for a library.
 */
class BuildPublicNamespaceTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input for [LIBRARY_ELEMENT2] of a library.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildPublicNamespaceTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT3]);

  BuildPublicNamespaceTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibraryElementImpl library = getRequiredInput(LIBRARY_INPUT);
    NamespaceBuilder builder = new NamespaceBuilder();
    library.publicNamespace = builder.createPublicNamespaceForLibrary(library);
    outputs[LIBRARY_ELEMENT3] = library;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given library [libSource].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{LIBRARY_INPUT: LIBRARY_ELEMENT2.of(source)};
  }

  /**
   * Create a [BuildPublicNamespaceTask] based on the given [target] in
   * the given [context].
   */
  static BuildPublicNamespaceTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildPublicNamespaceTask(context, target);
  }
}

/**
 * A task that builds [EXPORT_SOURCE_CLOSURE] of a library.
 */
class BuildSourceExportClosureTask extends SourceBasedAnalysisTask {
  /**
   * The name of the export closure.
   */
  static const String EXPORT_INPUT = 'EXPORT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildSourceExportClosureTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[EXPORT_SOURCE_CLOSURE]);

  BuildSourceExportClosureTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    List<Source> exportClosure = getRequiredInput(EXPORT_INPUT);
    //
    // Record output.
    //
    outputs[EXPORT_SOURCE_CLOSURE] = exportClosure;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given library [libSource].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      EXPORT_INPUT: new _ExportSourceClosureTaskInput(source, LIBRARY_ELEMENT2)
    };
  }

  /**
   * Create a [BuildSourceExportClosureTask] based on the given [target] in
   * the given [context].
   */
  static BuildSourceExportClosureTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildSourceExportClosureTask(context, target);
  }
}

/**
 * A task that builds [TYPE_PROVIDER] for a context.
 */
class BuildTypeProviderTask extends SourceBasedAnalysisTask {
  /**
   * The [PUBLIC_NAMESPACE] input of the `dart:core` library.
   */
  static const String CORE_INPUT = 'CORE_INPUT';

  /**
   * The [PUBLIC_NAMESPACE] input of the `dart:async` library.
   */
  static const String ASYNC_INPUT = 'ASYNC_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildTypeProviderTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[TYPE_PROVIDER]);

  BuildTypeProviderTask(
      InternalAnalysisContext context, AnalysisContextTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibraryElement coreLibrary = getRequiredInput(CORE_INPUT);
    LibraryElement asyncLibrary = getOptionalInput(ASYNC_INPUT);
    Namespace coreNamespace = coreLibrary.publicNamespace;
    Namespace asyncNamespace = asyncLibrary.publicNamespace;
    //
    // Record outputs.
    //
    TypeProvider typeProvider =
        new TypeProviderImpl.forNamespaces(coreNamespace, asyncNamespace);
    (context as InternalAnalysisContext).typeProvider = typeProvider;
    outputs[TYPE_PROVIDER] = typeProvider;
  }

  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    AnalysisContextTarget contextTarget = target;
    SourceFactory sourceFactory = contextTarget.context.sourceFactory;
    Source coreSource = sourceFactory.forUri(DartSdk.DART_CORE);
    Source asyncSource = sourceFactory.forUri(DartSdk.DART_ASYNC);
    if (asyncSource == null) {
      return <String, TaskInput>{CORE_INPUT: LIBRARY_ELEMENT3.of(coreSource)};
    }
    return <String, TaskInput>{
      CORE_INPUT: LIBRARY_ELEMENT3.of(coreSource),
      ASYNC_INPUT: LIBRARY_ELEMENT3.of(asyncSource)
    };
  }

  /**
   * Create a [BuildTypeProviderTask] based on the given [context].
   */
  static BuildTypeProviderTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildTypeProviderTask(context, target);
  }
}

/**
 * A task that computes [CONSTANT_DEPENDENCIES] for a constant.
 */
class ComputeConstantDependenciesTask extends ConstantEvaluationAnalysisTask {
  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ComputeConstantDependenciesTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[CONSTANT_DEPENDENCIES]);

  ComputeConstantDependenciesTask(
      InternalAnalysisContext context, ConstantEvaluationTarget constant)
      : super(context, constant);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    ConstantEvaluationTarget constant = target;
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Compute dependencies.
    //
    List<ConstantEvaluationTarget> dependencies = <ConstantEvaluationTarget>[];
    new ConstantEvaluationEngine(typeProvider, context.declaredVariables,
            typeSystem: context.typeSystem)
        .computeDependencies(constant, dependencies.add);
    //
    // Record outputs.
    //
    outputs[CONSTANT_DEPENDENCIES] = dependencies;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{
      'constantExpressionResolved': CONSTANT_EXPRESSION_RESOLVED.of(target),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request)
    };
  }

  /**
   * Create a [ComputeConstantDependenciesTask] based on the given [target] in
   * the given [context].
   */
  static ComputeConstantDependenciesTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ComputeConstantDependenciesTask(context, target);
  }
}

/**
 * A task that computes the value of a constant ([CONSTANT_VALUE]) and
 * stores it in the element model.
 */
class ComputeConstantValueTask extends ConstantEvaluationAnalysisTask {
  /**
   * The name of the input which ensures that dependent constants are evaluated
   * before the target.
   */
  static const String DEPENDENCIES_INPUT = 'DEPENDENCIES_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ComputeConstantValueTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[CONSTANT_VALUE]);

  ComputeConstantValueTask(
      InternalAnalysisContext context, ConstantEvaluationTarget constant)
      : super(context, constant);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  bool get handlesDependencyCycles => true;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    // Note: DEPENDENCIES_INPUT is not needed.  It is merely a bookkeeping
    // dependency to ensure that the constants that this constant depends on
    // are computed first.
    ConstantEvaluationTarget constant = target;
    AnalysisContext context = constant.context;
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Compute the value of the constant, or report an error if there was a
    // cycle.
    //
    ConstantEvaluationEngine constantEvaluationEngine =
        new ConstantEvaluationEngine(typeProvider, context.declaredVariables,
            typeSystem: context.typeSystem);
    if (dependencyCycle == null) {
      constantEvaluationEngine.computeConstantValue(constant);
    } else {
      List<ConstantEvaluationTarget> constantsInCycle =
          <ConstantEvaluationTarget>[];
      int length = dependencyCycle.length;
      for (int i = 0; i < length; i++) {
        WorkItem workItem = dependencyCycle[i];
        if (workItem.descriptor == DESCRIPTOR) {
          constantsInCycle.add(workItem.target);
        }
      }
      assert(constantsInCycle.isNotEmpty);
      constantEvaluationEngine.generateCycleError(constantsInCycle, constant);
    }
    //
    // Record outputs.
    //
    outputs[CONSTANT_VALUE] = constant;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    ConstantEvaluationTarget evaluationTarget = target;
    return <String, TaskInput>{
      DEPENDENCIES_INPUT:
          CONSTANT_DEPENDENCIES.of(evaluationTarget).toListOf(CONSTANT_VALUE),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request)
    };
  }

  /**
   * Create a [ComputeConstantValueTask] based on the given [target] in the
   * given [context].
   */
  static ComputeConstantValueTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ComputeConstantValueTask(context, target);
  }
}

/**
 * A task that computes the [INFERABLE_STATIC_VARIABLE_DEPENDENCIES] for a
 * static variable whose type should be inferred.
 */
class ComputeInferableStaticVariableDependenciesTask
    extends InferStaticVariableTask {
  /**
   * The name of the [RESOLVED_UNIT7] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ComputeInferableStaticVariableDependenciesTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[INFERABLE_STATIC_VARIABLE_DEPENDENCIES]);

  ComputeInferableStaticVariableDependenciesTask(
      InternalAnalysisContext context, VariableElement variable)
      : super(context, variable);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    //
    // Compute dependencies.
    //
    VariableDeclaration declaration = getDeclaration(unit);
    VariableGatherer gatherer = new VariableGatherer(_isInferableStatic);
    declaration.initializer.accept(gatherer);
    //
    // Record outputs.
    //
    outputs[INFERABLE_STATIC_VARIABLE_DEPENDENCIES] = gatherer.results.toList();
  }

  /**
   * Return `true` if the given [variable] is a static variable whose type
   * should be inferred.
   */
  bool _isInferableStatic(VariableElement variable) =>
      variable.isStatic &&
      variable.hasImplicitType &&
      variable.initializer != null;

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    if (target is VariableElement) {
      CompilationUnitElementImpl unit = target
          .getAncestor((Element element) => element is CompilationUnitElement);
      return <String, TaskInput>{
        UNIT_INPUT: RESOLVED_UNIT7
            .of(new LibrarySpecificUnit(unit.librarySource, unit.source))
      };
    }
    throw new AnalysisException(
        'Cannot build inputs for a ${target.runtimeType}');
  }

  /**
   * Create a [ComputeInferableStaticVariableDependenciesTask] based on the
   * given [target] in the given [context].
   */
  static ComputeInferableStaticVariableDependenciesTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ComputeInferableStaticVariableDependenciesTask(context, target);
  }
}

/**
 * A task that computes the [LIBRARY_CYCLE] for a
 * library element.  Also computes the [LIBRARY_CYCLE_UNITS] and the
 * [LIBRARY_CYCLE_DEPENDENCIES].
 */
class ComputeLibraryCycleTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT2] input.
   */
  static const String LIBRARY_ELEMENT_INPUT = 'LIBRARY_ELEMENT_INPUT';

  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ComputeLibraryCycleForUnitTask',
      createTask,
      buildInputs, <ResultDescriptor>[
    LIBRARY_CYCLE,
    LIBRARY_CYCLE_UNITS,
    LIBRARY_CYCLE_DEPENDENCIES
  ]);

  ComputeLibraryCycleTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    // The computation of library cycles is necessarily non-local, since we
    // in general have to look at all of the reachable libraries
    // in order to find the strongly connected components.  Repeating this
    // computation for every node would be quadratic.  The libraryCycle getter
    // will avoid this by computing the library cycles for every reachable
    // library and recording it in the element model.  This means that this
    // task implicitly produces the output for many other targets.  This
    // can't be expressed in the task model right now: instead, we just
    // run tasks for those other targets, and they pick up the recorded
    // version off of the element model.  Unfortunately, this means that
    // the task model will not handle the invalidation of the recorded
    // results for us.  Instead, we must explicitly invalidate the recorded
    // library cycle information when we add or subtract edges from the
    // import/export graph.  Any update that changes the
    // import/export graph will induce a recomputation of the LIBRARY_ELEMENT2
    // result for the changed node. This recomputation is responsible for
    // conservatively invalidating the library cycle information recorded
    // in the element model.  The LIBRARY_CYCLE results that have been cached
    // by the task model are conservatively invalidated by the
    // IMPORT_EXPORT_SOURCE_CLOSURE dependency below.  If anything reachable
    // from a node is changed, its LIBRARY_CYCLE results will be re-computed
    // here (possibly re-using the result from the element model if invalidation
    // did not cause it to be erased).  In summary, task model dependencies
    // on the import/export source closure ensure that this method will be
    // re-run if anything reachable from this target has been invalidated,
    // and the invalidation code (invalidateLibraryCycles) will ensure that
    // element model results will be re-used here only if they are still valid.
    LibraryElement library = getRequiredInput(LIBRARY_ELEMENT_INPUT);
    if (context.analysisOptions.strongMode &&
        !LibraryElementImpl.hasResolutionCapability(
            library, LibraryResolutionCapability.resolvedTypeNames)) {
      List<LibraryElement> component = library.libraryCycle;
      Set<LibraryElement> filter = component.toSet();
      Set<CompilationUnitElement> deps = new Set<CompilationUnitElement>();
      void addLibrary(LibraryElement l) {
        if (!filter.contains(l)) {
          deps.addAll(l.units);
        }
      }

      int length = component.length;
      for (int i = 0; i < length; i++) {
        LibraryElement library = component[i];
        library.importedLibraries.forEach(addLibrary);
        library.exportedLibraries.forEach(addLibrary);
      }
      //
      // Record outputs.
      //
      LibrarySpecificUnit unitToLSU(CompilationUnitElement unit) =>
          new LibrarySpecificUnit(unit.librarySource, unit.source);
      outputs[LIBRARY_CYCLE] = component;
      outputs[LIBRARY_CYCLE_UNITS] =
          component.expand((l) => l.units).map(unitToLSU).toList();
      outputs[LIBRARY_CYCLE_DEPENDENCIES] = deps.map(unitToLSU).toList();
    } else {
      outputs[LIBRARY_CYCLE] = [];
      outputs[LIBRARY_CYCLE_UNITS] = [];
      outputs[LIBRARY_CYCLE_DEPENDENCIES] = [];
    }
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source librarySource = target;
    return <String, TaskInput>{
      LIBRARY_ELEMENT_INPUT: LIBRARY_ELEMENT2.of(librarySource),
      'resolveReachableLibraries': READY_LIBRARY_ELEMENT2.of(librarySource),
    };
  }

  /**
   * Create a [ComputeLibraryCycleTask] based on the
   * given [target] in the given [context].
   */
  static ComputeLibraryCycleTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ComputeLibraryCycleTask(context, target);
  }
}

/**
 * A task that builds [REQUIRED_CONSTANTS] for a unit.
 */
class ComputeRequiredConstantsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ComputeRequiredConstantsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[PENDING_ERRORS, REQUIRED_CONSTANTS]);

  ComputeRequiredConstantsTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    Source source = getRequiredSource();
    //
    // Prepare inputs.
    //
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    //
    // Use the ErrorVerifier to compute errors.
    //
    RequiredConstantsComputer computer = new RequiredConstantsComputer(source);
    unit.accept(computer);
    List<PendingError> pendingErrors = computer.pendingErrors;
    List<ConstantEvaluationTarget> requiredConstants =
        computer.requiredConstants;
    //
    // Record outputs.
    //
    outputs[PENDING_ERRORS] = pendingErrors;
    outputs[REQUIRED_CONSTANTS] = requiredConstants;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{UNIT_INPUT: RESOLVED_UNIT.of(unit)};
  }

  /**
   * Create a [ComputeRequiredConstantsTask] based on the given [target] in
   * the given [context].
   */
  static ComputeRequiredConstantsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ComputeRequiredConstantsTask(context, target);
  }
}

/**
 * A base class for analysis tasks whose target is expected to be a
 * [ConstantEvaluationTarget].
 */
abstract class ConstantEvaluationAnalysisTask extends AnalysisTask {
  /**
   * Initialize a newly created task to perform analysis within the given
   * [context] in order to produce results for the given [constant].
   */
  ConstantEvaluationAnalysisTask(
      AnalysisContext context, ConstantEvaluationTarget constant)
      : super(context, constant);

  @override
  String get description {
    Source source = target.source;
    String sourceName = source == null ? '<unknown source>' : source.fullName;
    return '${descriptor.name} for element $target in source $sourceName';
  }
}

/**
 * Interface for [AnalysisTarget]s for which constant evaluation can be
 * performed.
 */
abstract class ConstantEvaluationTarget extends AnalysisTarget {
  /**
   * Return the [AnalysisContext] which should be used to evaluate this
   * constant.
   */
  AnalysisContext get context;
}

/**
 * A task that computes a list of the libraries containing the target source.
 */
class ContainingLibrariesTask extends SourceBasedAnalysisTask {
  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ContainingLibrariesTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[CONTAINING_LIBRARIES]);

  ContainingLibrariesTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    // TODO(brianwilkerson) This value can change as new libraries are analyzed
    // so we need some way of making sure that this result is removed from the
    // cache appropriately.
    Source source = getRequiredSource();
    outputs[CONTAINING_LIBRARIES] = context.getLibrariesContaining(source);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{};
  }

  /**
   * Create a [ContainingLibrariesTask] based on the given [target] in the given
   * [context].
   */
  static ContainingLibrariesTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ContainingLibrariesTask(context, target);
  }
}

/**
 * A task that merges all of the errors for a single source into a single list
 * of errors.
 */
class DartErrorsTask extends SourceBasedAnalysisTask {
  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor('DartErrorsTask',
      createTask, buildInputs, <ResultDescriptor>[DART_ERRORS]);

  /**
   * The name of the [IGNORE_INFO_INPUT] input.
   */
  static const String IGNORE_INFO_INPUT = 'IGNORE_INFO_INPUT';

  /**
   * The name of the [LINE_INFO_INPUT] input.
   */
  static const String LINE_INFO_INPUT = 'LINE_INFO_INPUT';

  DartErrorsTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    List<List<AnalysisError>> errorLists = <List<AnalysisError>>[];
    //
    // Prepare inputs.
    //
    EnginePlugin enginePlugin = AnalysisEngine.instance.enginePlugin;
    List<ResultDescriptor> errorsForSource = enginePlugin.dartErrorsForSource;
    int sourceLength = errorsForSource.length;
    for (int i = 0; i < sourceLength; i++) {
      ResultDescriptor result = errorsForSource[i];
      String inputName = result.name + '_input';
      errorLists.add(getRequiredInput(inputName));
    }
    List<ResultDescriptor> errorsForUnit = enginePlugin.dartErrorsForUnit;
    int unitLength = errorsForUnit.length;
    for (int i = 0; i < unitLength; i++) {
      ResultDescriptor result = errorsForUnit[i];
      String inputName = result.name + '_input';
      Map<Source, List<AnalysisError>> errorMap = getRequiredInput(inputName);
      for (List<AnalysisError> errors in errorMap.values) {
        errorLists.add(errors);
      }
    }

    //
    // Filter ignored errors.
    //
    List<AnalysisError> errors =
        _filterIgnores(AnalysisError.mergeLists(errorLists));

    //
    // Record outputs.
    //
    outputs[DART_ERRORS] = errors;
  }

  List<AnalysisError> _filterIgnores(List<AnalysisError> errors) {
    if (errors.isEmpty) {
      return errors;
    }

    IgnoreInfo ignoreInfo = getRequiredInput(IGNORE_INFO_INPUT);
    if (!ignoreInfo.hasIgnores) {
      return errors;
    }

    LineInfo lineInfo = getRequiredInput(LINE_INFO_INPUT);

    return filterIgnored(errors, ignoreInfo, lineInfo);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    Map<String, TaskInput> inputs = <String, TaskInput>{};
    inputs[LINE_INFO_INPUT] = LINE_INFO.of(source);
    inputs[IGNORE_INFO_INPUT] = IGNORE_INFO.of(source);
    EnginePlugin enginePlugin = AnalysisEngine.instance.enginePlugin;
    // for Source
    List<ResultDescriptor> errorsForSource = enginePlugin.dartErrorsForSource;
    int sourceLength = errorsForSource.length;
    for (int i = 0; i < sourceLength; i++) {
      ResultDescriptor result = errorsForSource[i];
      String inputName = result.name + '_input';
      inputs[inputName] = result.of(source);
    }
    // for LibrarySpecificUnit
    List<ResultDescriptor> errorsForUnit = enginePlugin.dartErrorsForUnit;
    int unitLength = errorsForUnit.length;
    for (int i = 0; i < unitLength; i++) {
      ResultDescriptor result = errorsForUnit[i];
      String inputName = result.name + '_input';
      inputs[inputName] =
          CONTAINING_LIBRARIES.of(source).toMap((Source library) {
        LibrarySpecificUnit unit = new LibrarySpecificUnit(library, source);
        return result.of(unit);
      });
    }
    return inputs;
  }

  /**
   * Create a [DartErrorsTask] based on the given [target] in the given
   * [context].
   */
  static DartErrorsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new DartErrorsTask(context, target);
  }

  /**
   * Return a new list with items from [errors] which are not filtered out by
   * the [ignoreInfo].
   */
  static List<AnalysisError> filterIgnored(
      List<AnalysisError> errors, IgnoreInfo ignoreInfo, LineInfo lineInfo) {
    if (errors.isEmpty || !ignoreInfo.hasIgnores) {
      return errors;
    }

    bool isIgnored(AnalysisError error) {
      int errorLine = lineInfo.getLocation(error.offset).lineNumber;
      String errorCode = error.errorCode.name.toLowerCase();
      // Ignores can be on the line or just preceding the error.
      return ignoreInfo.ignoredAt(errorCode, errorLine) ||
          ignoreInfo.ignoredAt(errorCode, errorLine - 1);
    }

    return errors.where((AnalysisError e) => !isIgnored(e)).toList();
  }
}

/**
 * A task that builds [RESOLVED_UNIT12] for a unit.
 */
class EvaluateUnitConstantsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT11] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The name of the [CONSTANT_VALUE] input.
   */
  static const String CONSTANT_VALUES = 'CONSTANT_VALUES';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'EvaluateUnitConstantsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[CREATED_RESOLVED_UNIT12, RESOLVED_UNIT12]);

  EvaluateUnitConstantsTask(AnalysisContext context, LibrarySpecificUnit target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    // No actual work needs to be performed; the task manager will ensure that
    // all constants are evaluated before this method is called.
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    outputs[RESOLVED_UNIT12] = unit;
    outputs[CREATED_RESOLVED_UNIT12] = true;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      'libraryElement': LIBRARY_ELEMENT9.of(unit.library),
      UNIT_INPUT: RESOLVED_UNIT11.of(unit),
      CONSTANT_VALUES:
          COMPILATION_UNIT_CONSTANTS.of(unit).toListOf(CONSTANT_VALUE),
      'constantExpressionsDependencies':
          CONSTANT_EXPRESSIONS_DEPENDENCIES.of(unit).toListOf(CONSTANT_VALUE)
    };
  }

  /**
   * Create an [EvaluateUnitConstantsTask] based on the given [target] in
   * the given [context].
   */
  static EvaluateUnitConstantsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new EvaluateUnitConstantsTask(context, target);
  }
}

/**
 * A task that builds [USED_IMPORTED_ELEMENTS] for a unit.
 */
class GatherUsedImportedElementsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT11] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'GatherUsedImportedElementsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[USED_IMPORTED_ELEMENTS]);

  GatherUsedImportedElementsTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    CompilationUnitElement unitElement = unit.element;
    LibraryElement libraryElement = unitElement.library;
    //
    // Prepare used imported elements.
    //
    GatherUsedImportedElementsVisitor visitor =
        new GatherUsedImportedElementsVisitor(libraryElement);
    unit.accept(visitor);
    //
    // Record outputs.
    //
    outputs[USED_IMPORTED_ELEMENTS] = visitor.usedElements;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{UNIT_INPUT: RESOLVED_UNIT11.of(unit)};
  }

  /**
   * Create a [GatherUsedImportedElementsTask] based on the given [target] in
   * the given [context].
   */
  static GatherUsedImportedElementsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new GatherUsedImportedElementsTask(context, target);
  }
}

/**
 * A task that builds [USED_LOCAL_ELEMENTS] for a unit.
 */
class GatherUsedLocalElementsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT11] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'GatherUsedLocalElementsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[USED_LOCAL_ELEMENTS]);

  GatherUsedLocalElementsTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    CompilationUnitElement unitElement = unit.element;
    LibraryElement libraryElement = unitElement.library;
    //
    // Prepare used local elements.
    //
    GatherUsedLocalElementsVisitor visitor =
        new GatherUsedLocalElementsVisitor(libraryElement);
    unit.accept(visitor);
    //
    // Record outputs.
    //
    outputs[USED_LOCAL_ELEMENTS] = visitor.usedElements;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{UNIT_INPUT: RESOLVED_UNIT11.of(unit)};
  }

  /**
   * Create a [GatherUsedLocalElementsTask] based on the given [target] in
   * the given [context].
   */
  static GatherUsedLocalElementsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new GatherUsedLocalElementsTask(context, target);
  }
}

/**
 * A task that generates [HINTS] for a unit.
 */
class GenerateHintsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT11] input.
   */
  static const String RESOLVED_UNIT_INPUT = 'RESOLVED_UNIT';

  /**
   * The name of a list of [USED_LOCAL_ELEMENTS] for each library unit input.
   */
  static const String USED_LOCAL_ELEMENTS_INPUT = 'USED_LOCAL_ELEMENTS';

  /**
   * The name of a list of [USED_IMPORTED_ELEMENTS] for each library unit input.
   */
  static const String USED_IMPORTED_ELEMENTS_INPUT = 'USED_IMPORTED_ELEMENTS';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'GenerateHintsTask', createTask, buildInputs, <ResultDescriptor>[HINTS]);

  GenerateHintsTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    AnalysisOptions analysisOptions = context.analysisOptions;
    if (!analysisOptions.hint) {
      outputs[HINTS] = AnalysisError.NO_ERRORS;
      return;
    }
    //
    // Prepare collectors.
    //
    RecordingErrorListener errorListener = new RecordingErrorListener();
    Source source = getRequiredSource();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, source);
    //
    // Prepare inputs.
    //
    CompilationUnit unit = getRequiredInput(RESOLVED_UNIT_INPUT);
    List<UsedImportedElements> usedImportedElementsList =
        getRequiredInput(USED_IMPORTED_ELEMENTS_INPUT);
    List<UsedLocalElements> usedLocalElementsList =
        getRequiredInput(USED_LOCAL_ELEMENTS_INPUT);
    CompilationUnitElement unitElement = unit.element;
    LibraryElement libraryElement = unitElement.library;
    TypeSystem typeSystem = context.typeSystem;

    //
    // Generate errors.
    //
    unit.accept(new DeadCodeVerifier(errorReporter, typeSystem: typeSystem));
    // Verify imports.
    {
      ImportsVerifier verifier = new ImportsVerifier();
      verifier.addImports(unit);
      usedImportedElementsList.forEach(verifier.removeUsedElements);
      verifier.generateDuplicateImportHints(errorReporter);
      verifier.generateUnusedImportHints(errorReporter);
      verifier.generateUnusedShownNameHints(errorReporter);
    }
    // Unused local elements.
    {
      UsedLocalElements usedElements =
          new UsedLocalElements.merge(usedLocalElementsList);
      UnusedLocalElementsVerifier visitor =
          new UnusedLocalElementsVerifier(errorListener, usedElements);
      unitElement.accept(visitor);
    }
    // Dart2js analysis.
    if (analysisOptions.dart2jsHint) {
      unit.accept(new Dart2JSVerifier(errorReporter));
    }
    // Dart best practices.
    InheritanceManager inheritanceManager = new InheritanceManager(
        libraryElement,
        includeAbstractFromSuperclasses: true);
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);

    unit.accept(new BestPracticesVerifier(
        errorReporter, typeProvider, libraryElement, inheritanceManager,
        typeSystem: typeSystem));
    unit.accept(new OverrideVerifier(errorReporter, inheritanceManager));
    // Find to-do comments.
    new ToDoFinder(errorReporter).findIn(unit);
    //
    // Record outputs.
    //
    outputs[HINTS] = errorListener.errors;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    Source libSource = unit.library;
    return <String, TaskInput>{
      RESOLVED_UNIT_INPUT: RESOLVED_UNIT.of(unit),
      USED_LOCAL_ELEMENTS_INPUT:
          LIBRARY_SPECIFIC_UNITS.of(libSource).toListOf(USED_LOCAL_ELEMENTS),
      USED_IMPORTED_ELEMENTS_INPUT:
          LIBRARY_SPECIFIC_UNITS.of(libSource).toListOf(USED_IMPORTED_ELEMENTS),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request)
    };
  }

  /**
   * Create a [GenerateHintsTask] based on the given [target] in
   * the given [context].
   */
  static GenerateHintsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new GenerateHintsTask(context, target);
  }
}

/**
 * A task that generates [LINTS] for a unit.
 */
class GenerateLintsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT] input.
   */
  static const String RESOLVED_UNIT_INPUT = 'RESOLVED_UNIT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'GenerateLintsTask', createTask, buildInputs, <ResultDescriptor>[LINTS]);

  GenerateLintsTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    AnalysisOptions analysisOptions = context.analysisOptions;
    if (!analysisOptions.lint) {
      outputs[LINTS] = AnalysisError.NO_ERRORS;
      return;
    }
    //
    // Prepare collectors.
    //
    RecordingErrorListener errorListener = new RecordingErrorListener();
    Source source = getRequiredSource();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, source);
    //
    // Prepare inputs.
    //
    CompilationUnit unit = getRequiredInput(RESOLVED_UNIT_INPUT);
    //
    // Generate lints.
    //
    List<AstVisitor> visitors = <AstVisitor>[];
    bool timeVisits = analysisOptions.enableTiming;
    List<Linter> linters = getLints(context);
    int length = linters.length;
    for (int i = 0; i < length; i++) {
      Linter linter = linters[i];
      AstVisitor visitor = linter.getVisitor();
      if (visitor != null) {
        linter.reporter = errorReporter;
        if (timeVisits) {
          visitor = new TimedAstVisitor(visitor, lintRegistry.getTimer(linter));
        }
        visitors.add(visitor);
      }
    }
    AstVisitor visitor = new ExceptionHandlingDelegatingAstVisitor(
        visitors, ExceptionHandlingDelegatingAstVisitor.logException);
    unit.accept(visitor);
    //
    // Record outputs.
    //
    outputs[LINTS] = errorListener.errors;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) =>
      <String, TaskInput>{RESOLVED_UNIT_INPUT: RESOLVED_UNIT.of(target)};

  /**
   * Create a [GenerateLintsTask] based on the given [target] in
   * the given [context].
   */
  static GenerateLintsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new GenerateLintsTask(context, target);
  }
}

/**
 * Information about analysis `//ignore:` and `//ignore_for_file` comments
 * within a source file.
 */
class IgnoreInfo {
  /**
   *  Instance shared by all cases without matches.
   */
  static final IgnoreInfo _EMPTY_INFO = new IgnoreInfo();

  /**
   * A regular expression for matching 'ignore' comments.  Produces matches
   * containing 2 groups.  For example:
   *
   *     * ['//ignore: error_code', 'error_code']
   *
   * Resulting codes may be in a list ('error_code_1,error_code2').
   */
  static final RegExp _IGNORE_MATCHER =
      new RegExp(r'//[ ]*ignore:(.*)$', multiLine: true);

  /**
   * A regular expression for matching 'ignore_for_file' comments.  Produces
   * matches containing 2 groups.  For example:
   *
   *     * ['//ignore_for_file: error_code', 'error_code']
   *
   * Resulting codes may be in a list ('error_code_1,error_code2').
   */
  static final RegExp _IGNORE_FOR_FILE_MATCHER =
      new RegExp(r'//[ ]*ignore_for_file:(.*)$', multiLine: true);

  final Map<int, List<String>> _ignoreMap = new HashMap<int, List<String>>();

  final Set<String> _ignoreForFileSet = new HashSet<String>();

  /**
   * Whether this info object defines any ignores.
   */
  bool get hasIgnores => ignores.isNotEmpty || _ignoreForFileSet.isNotEmpty;

  /**
   * Iterable of error codes ignored for the whole file.
   */
  Iterable<String> get ignoreForFiles => _ignoreForFileSet;

  /**
   * Map of line numbers to associated ignored error codes.
   */
  Map<int, Iterable<String>> get ignores => _ignoreMap;

  /**
   * Ignore this [errorCode] at [line].
   */
  void add(int line, String errorCode) {
    _ignoreMap.putIfAbsent(line, () => new List<String>()).add(errorCode);
  }

  /**
   * Ignore these [errorCodes] at [line].
   */
  void addAll(int line, Iterable<String> errorCodes) {
    _ignoreMap.putIfAbsent(line, () => new List<String>()).addAll(errorCodes);
  }

  /**
   * Ignore these [errorCodes] in the whole file.
   */
  void addAllForFile(Iterable<String> errorCodes) {
    _ignoreForFileSet.addAll(errorCodes);
  }

  /**
   * Test whether this [errorCode] is ignored at the given [line].
   */
  bool ignoredAt(String errorCode, int line) =>
      _ignoreForFileSet.contains(errorCode) ||
      _ignoreMap[line]?.contains(errorCode) == true;

  /**
   * Calculate ignores for the given [content] with line [info].
   */
  static IgnoreInfo calculateIgnores(String content, LineInfo info) {
    Iterable<Match> matches = _IGNORE_MATCHER.allMatches(content);
    Iterable<Match> fileMatches = _IGNORE_FOR_FILE_MATCHER.allMatches(content);
    if (matches.isEmpty && fileMatches.isEmpty) {
      return _EMPTY_INFO;
    }

    IgnoreInfo ignoreInfo = new IgnoreInfo();
    for (Match match in matches) {
      // See _IGNORE_MATCHER for format --- note the possibility of error lists.
      Iterable<String> codes = match
          .group(1)
          .split(',')
          .map((String code) => code.trim().toLowerCase());
      ignoreInfo.addAll(info.getLocation(match.start).lineNumber, codes);
    }
    for (Match match in fileMatches) {
      Iterable<String> codes = match
          .group(1)
          .split(',')
          .map((String code) => code.trim().toLowerCase());
      ignoreInfo.addAllForFile(codes);
    }
    return ignoreInfo;
  }
}

/**
 * A task that ensures that all of the inferable instance members in a
 * compilation unit have had their type inferred.
 */
class InferInstanceMembersInUnitTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The name of the input whose value is the [RESOLVED_UNIT8] for the
   * compilation unit.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'InferInstanceMembersInUnitTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[CREATED_RESOLVED_UNIT10, RESOLVED_UNIT10]);

  /**
   * Initialize a newly created task to build a library element for the given
   * [unit] in the given [context].
   */
  InferInstanceMembersInUnitTask(
      InternalAnalysisContext context, LibrarySpecificUnit unit)
      : super(context, unit);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);

    //
    // Prepare fields for which inference should be disabled.
    //
    Set<FieldElement> fieldsWithDisabledInference = new Set<FieldElement>();
    for (CompilationUnitMember classDeclaration in unit.declarations) {
      if (classDeclaration is ClassDeclaration) {
        for (ClassMember fieldDeclaration in classDeclaration.members) {
          if (fieldDeclaration is FieldDeclaration) {
            if (!fieldDeclaration.isStatic) {
              for (VariableDeclaration field
                  in fieldDeclaration.fields.variables) {
                Expression initializer = field.initializer;
                if (initializer != null &&
                    !isValidForTypeInference(initializer)) {
                  fieldsWithDisabledInference.add(field.element);
                }
              }
            }
          }
        }
      }
    }

    //
    // Infer instance members.
    //
    if (context.analysisOptions.strongMode) {
      var inheritanceManager = new InheritanceManager(
          resolutionMap.elementDeclaredByCompilationUnit(unit).library);
      InstanceMemberInferrer inferrer = new InstanceMemberInferrer(
          typeProvider, (_) => inheritanceManager, fieldsWithDisabledInference,
          typeSystem: context.typeSystem);
      inferrer.inferCompilationUnit(unit.element);
    }
    //
    // Record outputs.
    //
    outputs[RESOLVED_UNIT10] = unit;
    outputs[CREATED_RESOLVED_UNIT10] = true;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [libSource].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      UNIT_INPUT: RESOLVED_UNIT9.of(unit),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request),
      // In strong mode, add additional dependencies to enforce inference
      // ordering.

      // Require that field re-resolution be complete for all units in the
      // current library cycle.
      'orderLibraryCycleTasks':
          LIBRARY_CYCLE_UNITS.of(unit.library).toListOf(CREATED_RESOLVED_UNIT9),
      // Require that full inference be complete for all dependencies of the
      // current library cycle.
      'orderLibraryCycles': LIBRARY_CYCLE_DEPENDENCIES
          .of(unit.library)
          .toListOf(CREATED_RESOLVED_UNIT10)
    };
  }

  /**
   * Create a [InferInstanceMembersInUnitTask] based on the given [target] in
   * the given [context].
   */
  static InferInstanceMembersInUnitTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new InferInstanceMembersInUnitTask(context, target);
  }
}

/**
 * An abstract class that defines utility methods that are useful for tasks
 * operating on static variables.
 */
abstract class InferStaticVariableTask extends ConstantEvaluationAnalysisTask {
  InferStaticVariableTask(
      InternalAnalysisContext context, VariableElement variable)
      : super(context, variable);

  /**
   * Return the declaration of the target within the given compilation [unit].
   * Throw an exception if the declaration cannot be found.
   */
  VariableDeclaration getDeclaration(CompilationUnit unit) {
    VariableElement variable = target;
    int offset = variable.nameOffset;
    AstNode node = new NodeLocator2(offset).searchWithin(unit);
    if (node == null) {
      Source variableSource = variable.source;
      Source unitSource =
          resolutionMap.elementDeclaredByCompilationUnit(unit).source;
      if (variableSource != unitSource) {
        throw new AnalysisException(
            "Failed to find the AST node for the variable "
            "${variable.displayName} at $offset in $variableSource "
            "because we were looking in $unitSource");
      }
      throw new AnalysisException(
          "Failed to find the AST node for the variable "
          "${variable.displayName} at $offset in $variableSource");
    }
    VariableDeclaration declaration =
        node.getAncestor((AstNode ancestor) => ancestor is VariableDeclaration);
    if (declaration == null || declaration.name != node) {
      Source variableSource = variable.source;
      Source unitSource =
          resolutionMap.elementDeclaredByCompilationUnit(unit).source;
      if (variableSource != unitSource) {
        if (declaration == null) {
          throw new AnalysisException(
              "Failed to find the declaration of the variable "
              "${variable.displayName} at $offset in $variableSource "
              "because the node was not in a variable declaration "
              "possibly because we were looking in $unitSource");
        }
        throw new AnalysisException(
            "Failed to find the declaration of the variable "
            "${variable.displayName} at $offset in $variableSource "
            "because we were looking in $unitSource");
      }
      if (declaration == null) {
        throw new AnalysisException(
            "Failed to find the declaration of the variable "
            "${variable.displayName} at $offset in $variableSource "
            "because the node was not in a variable declaration");
      }
      throw new AnalysisException(
          "Failed to find the declaration of the variable "
          "${variable.displayName} at $offset in $variableSource "
          "because the node was not the name in a variable declaration");
    }
    return declaration;
  }
}

/**
 * A task that ensures that all of the inferable static variables in a
 * compilation unit have had their type inferred.
 */
class InferStaticVariableTypesInUnitTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the [RESOLVED_UNIT8] for the
   * compilation unit.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The name of the [STATIC_VARIABLE_RESOLUTION_ERRORS] for all static
   * variables in the compilation unit.
   */
  static const String ERRORS_LIST_INPUT = 'INFERRED_VARIABLES_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'InferStaticVariableTypesInUnitTask',
      createTask,
      buildInputs, <ResultDescriptor>[
    CREATED_RESOLVED_UNIT8,
    RESOLVED_UNIT8,
    STATIC_VARIABLE_RESOLUTION_ERRORS_IN_UNIT
  ]);

  /**
   * Initialize a newly created task to build a library element for the given
   * [unit] in the given [context].
   */
  InferStaticVariableTypesInUnitTask(
      InternalAnalysisContext context, LibrarySpecificUnit unit)
      : super(context, unit);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    List<List<AnalysisError>> errorLists = getRequiredInput(ERRORS_LIST_INPUT);
    //
    // Record outputs. There is no additional work to be done at this time
    // because the work has implicitly been done by virtue of the task model
    // preparing all of the inputs.
    //
    outputs[RESOLVED_UNIT8] = unit;
    outputs[CREATED_RESOLVED_UNIT8] = true;
    outputs[STATIC_VARIABLE_RESOLUTION_ERRORS_IN_UNIT] =
        AnalysisError.mergeLists(errorLists);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [libSource].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      'inferredTypes': INFERABLE_STATIC_VARIABLES_IN_UNIT
          .of(unit)
          .toListOf(INFERRED_STATIC_VARIABLE),
      ERRORS_LIST_INPUT: INFERABLE_STATIC_VARIABLES_IN_UNIT
          .of(unit)
          .toListOf(STATIC_VARIABLE_RESOLUTION_ERRORS),
      UNIT_INPUT: RESOLVED_UNIT7.of(unit)
    };
  }

  /**
   * Create a [InferStaticVariableTypesInUnitTask] based on the given [target]
   * in the given [context].
   */
  static InferStaticVariableTypesInUnitTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new InferStaticVariableTypesInUnitTask(context, target);
  }
}

/**
 * A task that computes the type of an inferable static variable and
 * stores it in the element model.
 */
class InferStaticVariableTypeTask extends InferStaticVariableTask {
  /**
   * The name of the input which ensures that dependent values have their type
   * inferred before the target.
   */
  static const String DEPENDENCIES_INPUT = 'DEPENDENCIES_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The name of the [RESOLVED_UNIT8] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'InferStaticVariableTypeTask',
      createTask,
      buildInputs, <ResultDescriptor>[
    INFERRED_STATIC_VARIABLE,
    STATIC_VARIABLE_RESOLUTION_ERRORS
  ]);

  InferStaticVariableTypeTask(
      InternalAnalysisContext context, VariableElement variable)
      : super(context, variable);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  bool get handlesDependencyCycles => true;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    // Note: DEPENDENCIES_INPUT is not needed.  It is merely a bookkeeping
    // dependency to ensure that the variables that this variable references
    // have types inferred before inferring the type of this variable.
    //
    VariableElementImpl variable = target;

    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);

    // If we're not in a dependency cycle, and we have no type annotation,
    // re-resolve the right hand side and do inference.
    List<AnalysisError> errors = AnalysisError.NO_ERRORS;
    if (dependencyCycle == null && variable.hasImplicitType) {
      VariableDeclaration declaration = getDeclaration(unit);
      //
      // Re-resolve the variable's initializer so that the inferred types
      // of other variables will be propagated.
      //
      RecordingErrorListener errorListener = new RecordingErrorListener();
      Expression initializer = declaration.initializer;

      DartType newType;
      if (!isValidForTypeInference(initializer)) {
        newType = typeProvider.dynamicType;
      } else {
        ResolutionContext resolutionContext =
            ResolutionContextBuilder.contextFor(initializer);
        ResolverVisitor visitor = new ResolverVisitor(
            variable.library, variable.source, typeProvider, errorListener,
            nameScope: resolutionContext.scope);
        if (resolutionContext.enclosingClassDeclaration != null) {
          visitor.prepareToResolveMembersInClass(
              resolutionContext.enclosingClassDeclaration);
        }
        visitor.initForIncrementalResolution();
        initializer.accept(visitor);
        newType = initializer.staticType;
        if (newType == null || newType.isBottom || newType.isDartCoreNull) {
          newType = typeProvider.dynamicType;
        }
      }

      //
      // Record the type of the variable.
      //
      setFieldType(variable, newType);
      errors = getUniqueErrors(errorListener.errors);
    } else {
      // TODO(brianwilkerson) For now we simply don't infer any type for
      // variables or fields involved in a cycle. We could try to be smarter
      // by re-resolving the initializer in a context in which the types of all
      // of the variables in the cycle are assumed to be `null`, but it isn't
      // clear to me that this would produce better results often enough to
      // warrant the extra effort.
    }
    //
    // Record outputs.
    //
    outputs[INFERRED_STATIC_VARIABLE] = variable;
    outputs[STATIC_VARIABLE_RESOLUTION_ERRORS] = errors;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    VariableElement variable = target;
    LibrarySpecificUnit unit =
        new LibrarySpecificUnit(variable.library.source, variable.source);
    return <String, TaskInput>{
      DEPENDENCIES_INPUT: INFERABLE_STATIC_VARIABLE_DEPENDENCIES
          .of(variable)
          .toListOf(INFERRED_STATIC_VARIABLE),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request),
      UNIT_INPUT: RESOLVED_UNIT7.of(unit),
      // In strong mode, add additional dependencies to enforce inference
      // ordering.

      // Require that full inference be complete for all dependencies of the
      // current library cycle.
      'orderLibraryCycles': LIBRARY_CYCLE_DEPENDENCIES
          .of(unit.library)
          .toListOf(CREATED_RESOLVED_UNIT10)
    };
  }

  /**
   * Create a [InferStaticVariableTypeTask] based on the given [target] in the
   * given [context].
   */
  static InferStaticVariableTypeTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new InferStaticVariableTypeTask(context, target);
  }
}

/**
 * A task computes all of the errors of all of the units for a single
 * library source and sets the [LIBRARY_ERRORS_READY] flag.
 */
class LibraryErrorsReadyTask extends SourceBasedAnalysisTask {
  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'LibraryErrorsReadyTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[LIBRARY_ERRORS_READY]);

  LibraryErrorsReadyTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    outputs[LIBRARY_ERRORS_READY] = true;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      'allErrors': UNITS.of(source).toListOf(DART_ERRORS),
      'libraryElement': LIBRARY_ELEMENT.of(source)
    };
  }

  /**
   * Create a [LibraryErrorsReadyTask] based on the given [target] in the given
   * [context].
   */
  static LibraryErrorsReadyTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new LibraryErrorsReadyTask(context, target);
  }
}

/**
 * A task that merges all of the errors for a single source into a single list
 * of errors.
 */
class LibraryUnitErrorsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [BUILD_DIRECTIVES_ERRORS] input.
   */
  static const String BUILD_DIRECTIVES_ERRORS_INPUT = 'BUILD_DIRECTIVES_ERRORS';

  /**
   * The name of the [BUILD_LIBRARY_ERRORS] input.
   */
  static const String BUILD_LIBRARY_ERRORS_INPUT = 'BUILD_LIBRARY_ERRORS';

  /**
   * The name of the [HINTS] input.
   */
  static const String HINTS_INPUT = 'HINTS';

  /**
   * The name of the [LINTS] input.
   */
  static const String LINTS_INPUT = 'LINTS';

  /**
   * The name of the [STATIC_VARIABLE_RESOLUTION_ERRORS_IN_UNIT] input.
   */
  static const String STATIC_VARIABLE_RESOLUTION_ERRORS_INPUT =
      'STATIC_VARIABLE_RESOLUTION_ERRORS_INPUT';

  /**
   * The name of the [RESOLVE_DIRECTIVES_ERRORS] input.
   */
  static const String RESOLVE_DIRECTIVES_ERRORS_INPUT =
      'RESOLVE_DIRECTIVES_ERRORS';

  /**
   * The name of the [STRONG_MODE_ERRORS] input.
   */
  static const String STRONG_MODE_ERRORS_INPUT = 'STRONG_MODE_ERRORS';

  /**
   * The name of the [RESOLVE_TYPE_NAMES_ERRORS] input.
   */
  static const String RESOLVE_TYPE_NAMES_ERRORS_INPUT =
      'RESOLVE_TYPE_NAMES_ERRORS';

  /**
   * The name of the [RESOLVE_TYPE_BOUNDS_ERRORS] input.
   */
  static const String RESOLVE_TYPE_NAMES_ERRORS2_INPUT =
      'RESOLVE_TYPE_NAMES_ERRORS2';

  /**
   * The name of the [RESOLVE_UNIT_ERRORS] input.
   */
  static const String RESOLVE_UNIT_ERRORS_INPUT = 'RESOLVE_UNIT_ERRORS';

  /**
   * The name of the [VARIABLE_REFERENCE_ERRORS] input.
   */
  static const String VARIABLE_REFERENCE_ERRORS_INPUT =
      'VARIABLE_REFERENCE_ERRORS';

  /**
   * The name of the [VERIFY_ERRORS] input.
   */
  static const String VERIFY_ERRORS_INPUT = 'VERIFY_ERRORS';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'LibraryUnitErrorsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[LIBRARY_UNIT_ERRORS]);

  LibraryUnitErrorsTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    List<List<AnalysisError>> errorLists = <List<AnalysisError>>[];
    errorLists.add(getRequiredInput(BUILD_DIRECTIVES_ERRORS_INPUT));
    errorLists.add(getRequiredInput(BUILD_LIBRARY_ERRORS_INPUT));
    errorLists.add(getRequiredInput(HINTS_INPUT));
    errorLists.add(getRequiredInput(LINTS_INPUT));
    errorLists.add(getRequiredInput(RESOLVE_DIRECTIVES_ERRORS_INPUT));
    errorLists.add(getRequiredInput(RESOLVE_TYPE_NAMES_ERRORS_INPUT));
    errorLists.add(getRequiredInput(RESOLVE_TYPE_NAMES_ERRORS2_INPUT));
    errorLists.add(getRequiredInput(RESOLVE_UNIT_ERRORS_INPUT));
    errorLists.add(getRequiredInput(STATIC_VARIABLE_RESOLUTION_ERRORS_INPUT));
    errorLists.add(getRequiredInput(STRONG_MODE_ERRORS_INPUT));
    errorLists.add(getRequiredInput(VARIABLE_REFERENCE_ERRORS_INPUT));
    errorLists.add(getRequiredInput(VERIFY_ERRORS_INPUT));
    //
    // Record outputs.
    //
    outputs[LIBRARY_UNIT_ERRORS] = AnalysisError.mergeLists(errorLists);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [unit].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    Map<String, TaskInput> inputs = <String, TaskInput>{
      HINTS_INPUT: HINTS.of(unit),
      LINTS_INPUT: LINTS.of(unit),
      RESOLVE_DIRECTIVES_ERRORS_INPUT: RESOLVE_DIRECTIVES_ERRORS.of(unit),
      RESOLVE_TYPE_NAMES_ERRORS_INPUT: RESOLVE_TYPE_NAMES_ERRORS.of(unit),
      RESOLVE_TYPE_NAMES_ERRORS2_INPUT: RESOLVE_TYPE_BOUNDS_ERRORS.of(unit),
      RESOLVE_UNIT_ERRORS_INPUT: RESOLVE_UNIT_ERRORS.of(unit),
      STATIC_VARIABLE_RESOLUTION_ERRORS_INPUT:
          STATIC_VARIABLE_RESOLUTION_ERRORS_IN_UNIT.of(unit),
      STRONG_MODE_ERRORS_INPUT: STRONG_MODE_ERRORS.of(unit),
      VARIABLE_REFERENCE_ERRORS_INPUT: VARIABLE_REFERENCE_ERRORS.of(unit),
      VERIFY_ERRORS_INPUT: VERIFY_ERRORS.of(unit)
    };
    Source source = unit.source;
    if (unit.library == source) {
      inputs[BUILD_DIRECTIVES_ERRORS_INPUT] =
          BUILD_DIRECTIVES_ERRORS.of(source);
      inputs[BUILD_LIBRARY_ERRORS_INPUT] = BUILD_LIBRARY_ERRORS.of(source);
    } else {
      inputs[BUILD_DIRECTIVES_ERRORS_INPUT] =
          new ConstantTaskInput(AnalysisError.NO_ERRORS);
      inputs[BUILD_LIBRARY_ERRORS_INPUT] =
          new ConstantTaskInput(AnalysisError.NO_ERRORS);
    }
    return inputs;
  }

  /**
   * Create a [LibraryUnitErrorsTask] based on the given [target] in the given
   * [context].
   */
  static LibraryUnitErrorsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new LibraryUnitErrorsTask(context, target);
  }
}

/**
 * A task that parses the content of a Dart file, producing an AST structure,
 * any lexical errors found in the process, the kind of the file (library or
 * part), and several lists based on the AST.
 */
class ParseDartTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the line information produced for the
   * file.
   */
  static const String LINE_INFO_INPUT_NAME = 'LINE_INFO_INPUT_NAME';

  /**
   * The name of the input whose value is the modification time of the file.
   */
  static const String MODIFICATION_TIME_INPUT_NAME =
      'MODIFICATION_TIME_INPUT_NAME';

  /**
   * The name of the input whose value is the token stream produced for the file.
   */
  static const String TOKEN_STREAM_INPUT_NAME = 'TOKEN_STREAM_INPUT_NAME';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ParseDartTask', createTask, buildInputs, <ResultDescriptor>[
    EXPLICITLY_IMPORTED_LIBRARIES,
    EXPORTED_LIBRARIES,
    IMPORTED_LIBRARIES,
    INCLUDED_PARTS,
    LIBRARY_SPECIFIC_UNITS,
    PARSE_ERRORS,
    PARSED_UNIT,
    REFERENCED_SOURCES,
    SOURCE_KIND,
    UNITS,
  ]);

  /**
   * The source that is being parsed.
   */
  Source _source;

  /**
   * The [ErrorReporter] to report errors to.
   */
  ErrorReporter _errorReporter;

  /**
   * Initialize a newly created task to parse the content of the Dart file
   * associated with the given [target] in the given [context].
   */
  ParseDartTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    _source = getRequiredSource();
    LineInfo lineInfo = getRequiredInput(LINE_INFO_INPUT_NAME);
    int modificationTime = getRequiredInput(MODIFICATION_TIME_INPUT_NAME);
    Token tokenStream = getRequiredInput(TOKEN_STREAM_INPUT_NAME);

    RecordingErrorListener errorListener = new RecordingErrorListener();
    _errorReporter = new ErrorReporter(errorListener, _source);

    Parser parser = new Parser(_source, errorListener);
    AnalysisOptions options = context.analysisOptions;
    parser.enableAssertInitializer = options.enableAssertInitializer;
    parser.parseFunctionBodies =
        options.analyzeFunctionBodiesPredicate(_source);
    parser.parseGenericMethodComments = options.strongMode;
    parser.enableUriInPartOf = options.enableUriInPartOf;
    CompilationUnit unit = parser.parseCompilationUnit(tokenStream);
    unit.lineInfo = lineInfo;

    if (options.patchPaths.isNotEmpty && _source.uri.scheme == 'dart') {
      var resourceProvider =
          (context.sourceFactory.dartSdk as FolderBasedDartSdk)
              .resourceProvider;
      new SdkPatcher().patch(
          resourceProvider,
          context.analysisOptions.strongMode,
          context.analysisOptions.patchPaths,
          errorListener,
          _source,
          unit);
    }

    bool hasNonPartOfDirective = false;
    bool hasPartOfDirective = false;
    HashSet<Source> explicitlyImportedSourceSet = new HashSet<Source>();
    HashSet<Source> exportedSourceSet = new HashSet<Source>();
    HashSet<Source> includedSourceSet = new HashSet<Source>();
    NodeList<Directive> directives = unit.directives;
    int length = directives.length;
    for (int i = 0; i < length; i++) {
      Directive directive = directives[i];
      if (directive is PartOfDirective) {
        hasPartOfDirective = true;
      } else {
        hasNonPartOfDirective = true;
        if (directive is UriBasedDirective) {
          Source referencedSource = _resolveDirective(directive);
          if (referencedSource != null) {
            if (directive is ExportDirective) {
              exportedSourceSet.add(referencedSource);
            } else if (directive is ImportDirective) {
              explicitlyImportedSourceSet.add(referencedSource);
            } else if (directive is PartDirective) {
              includedSourceSet.add(referencedSource);
            } else {
              throw new AnalysisException(
                  '$runtimeType failed to handle a ${directive.runtimeType}');
            }
          }
        }
      }
    }
    //
    // Always include "dart:core" source.
    //
    HashSet<Source> importedSourceSet =
        new HashSet.from(explicitlyImportedSourceSet);
    Source coreLibrarySource = context.sourceFactory.forUri(DartSdk.DART_CORE);
    if (coreLibrarySource == null) {
      String message;
      DartSdk sdk = context.sourceFactory.dartSdk;
      if (sdk == null) {
        message = 'Could not resolve "dart:core": SDK not defined';
      } else {
        message = 'Could not resolve "dart:core": SDK incorrectly configured';
      }
      throw new AnalysisException(message);
    }
    importedSourceSet.add(coreLibrarySource);
    //
    // Compute kind.
    //
    SourceKind sourceKind = SourceKind.LIBRARY;
    if (modificationTime == -1) {
      sourceKind = SourceKind.UNKNOWN;
    } else if (hasPartOfDirective && !hasNonPartOfDirective) {
      sourceKind = SourceKind.PART;
    }
    //
    // Compute source lists.
    //
    List<Source> explicitlyImportedSources =
        explicitlyImportedSourceSet.toList();
    List<Source> exportedSources = exportedSourceSet.toList();
    List<Source> importedSources = importedSourceSet.toList();
    List<Source> includedSources = includedSourceSet.toList();
    List<Source> unitSources = <Source>[_source]..addAll(includedSourceSet);
    List<LibrarySpecificUnit> librarySpecificUnits =
        unitSources.map((s) => new LibrarySpecificUnit(_source, s)).toList();
    //
    // Compute referenced sources.
    //
    Set<Source> referencedSources = new Set<Source>();
    referencedSources.add(coreLibrarySource);
    referencedSources.addAll(unitSources);
    for (Directive directive in unit.directives) {
      if (directive is NamespaceDirective) {
        referencedSources.add(directive.uriSource);
        for (Configuration configuration in directive.configurations) {
          referencedSources.add(configuration.uriSource);
        }
      }
    }
    referencedSources.removeWhere((source) => source == null);
    //
    // Record outputs.
    //
    List<AnalysisError> parseErrors = getUniqueErrors(errorListener.errors);
    outputs[EXPLICITLY_IMPORTED_LIBRARIES] = explicitlyImportedSources;
    outputs[EXPORTED_LIBRARIES] = exportedSources;
    outputs[IMPORTED_LIBRARIES] = importedSources;
    outputs[INCLUDED_PARTS] = includedSources;
    outputs[LIBRARY_SPECIFIC_UNITS] = librarySpecificUnits;
    outputs[PARSE_ERRORS] = parseErrors;
    outputs[PARSED_UNIT] = unit;
    outputs[REFERENCED_SOURCES] = referencedSources.toList();
    outputs[SOURCE_KIND] = sourceKind;
    outputs[UNITS] = unitSources;
  }

  /**
   * Return the result of resolving the URI of the given URI-based [directive]
   * against the URI of the given library, or `null` if the URI is not valid.
   */
  Source _resolveDirective(UriBasedDirective directive) {
    bool isImport = directive is ImportDirective;

    // Resolve the default URI.
    Source defaultSource;
    {
      StringLiteral uriLiteral = directive.uri;
      String uriContent = uriLiteral.stringValue;
      if (uriContent != null) {
        uriContent = uriContent.trim();
        directive.uriContent = uriContent;
      }
      defaultSource = _resolveUri(isImport, uriLiteral, uriContent);
      directive.uriSource = defaultSource;
    }

    // Resolve all configurations and try to choose one.
    if (directive is NamespaceDirectiveImpl) {
      String configuredUriContent;
      Source configuredSource;
      for (Configuration configuration in directive.configurations) {
        String uriContent = configuration.uri.stringValue;
        Source source = _resolveUri(isImport, configuration.uri, uriContent);
        configuration.uriSource = source;
        if (configuredSource == null) {
          String variableName =
              configuration.name.components.map((i) => i.name).join('.');
          String variableValue = context.declaredVariables.get(variableName);
          if (configuration.value != null &&
                  variableValue == configuration.value.stringValue ||
              variableValue == 'true') {
            configuredUriContent = configuration.uri.stringValue;
            configuredSource = source;
          }
        }
      }
      String selectedContentUri = configuredUriContent ?? directive.uriContent;
      Source selectedSource = configuredSource ?? defaultSource;
      directive.selectedUriContent = selectedContentUri;
      directive.selectedSource = selectedSource;
      return selectedSource;
    }
    return defaultSource;
  }

  /**
   * Return the result of resolve the given [uriContent], reporting errors
   * against the [uriLiteral].
   */
  Source _resolveUri(
      bool isImport, StringLiteral uriLiteral, String uriContent) {
    UriValidationCode code =
        UriBasedDirectiveImpl.validateUri(isImport, uriLiteral, uriContent);
    if (code == null) {
      try {
        Uri.parse(uriContent);
      } on FormatException {
        return null;
      }
      return context.sourceFactory.resolveUri(_source, uriContent);
    } else if (code == UriValidationCode.URI_WITH_DART_EXT_SCHEME) {
      return null;
    } else if (code == UriValidationCode.URI_WITH_INTERPOLATION) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.URI_WITH_INTERPOLATION, uriLiteral);
      return null;
    } else if (code == UriValidationCode.INVALID_URI) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_URI, uriLiteral, [uriContent]);
      return null;
    }
    throw new AnalysisException('Failed to handle validation code: $code');
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{
      LINE_INFO_INPUT_NAME: LINE_INFO.of(target),
      MODIFICATION_TIME_INPUT_NAME: MODIFICATION_TIME.of(target),
      TOKEN_STREAM_INPUT_NAME: TOKEN_STREAM.of(target, flushOnAccess: true)
    };
  }

  /**
   * Create a [ParseDartTask] based on the given [target] in the given
   * [context].
   */
  static ParseDartTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ParseDartTask(context, target);
  }
}

/**
 * A task that builds [RESOLVED_UNIT7] for a unit.
 */
class PartiallyResolveUnitReferencesTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT6] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The name of the [RESOLVED_UNIT6] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'PartiallyResolveUnitReferencesTask',
      createTask,
      buildInputs, <ResultDescriptor>[
    INFERABLE_STATIC_VARIABLES_IN_UNIT,
    CREATED_RESOLVED_UNIT7,
    RESOLVED_UNIT7
  ]);

  PartiallyResolveUnitReferencesTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    LibraryElement libraryElement = getRequiredInput(LIBRARY_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    CompilationUnitElement unitElement = unit.element;
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Resolve references and record outputs.
    //
    PartialResolverVisitor visitor = new PartialResolverVisitor(libraryElement,
        unitElement.source, typeProvider, AnalysisErrorListener.NULL_LISTENER);
    unit.accept(visitor);
    //
    // Record outputs.
    //
    if (context.analysisOptions.strongMode) {
      outputs[INFERABLE_STATIC_VARIABLES_IN_UNIT] = visitor.staticVariables;
    } else {
      outputs[INFERABLE_STATIC_VARIABLES_IN_UNIT] = VariableElement.EMPTY_LIST;
    }
    outputs[RESOLVED_UNIT7] = unit;
    outputs[CREATED_RESOLVED_UNIT7] = true;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      'fullyBuiltLibraryElements': READY_LIBRARY_ELEMENT6.of(unit.library),
      LIBRARY_INPUT: LIBRARY_ELEMENT6.of(unit.library),
      UNIT_INPUT: RESOLVED_UNIT6.of(unit),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request),
      // In strong mode, add additional dependencies to enforce inference
      // ordering.

      // Require that full inference be complete for all dependencies of the
      // current library cycle.
      'orderLibraryCycles': LIBRARY_CYCLE_DEPENDENCIES
          .of(unit.library)
          .toListOf(CREATED_RESOLVED_UNIT10)
    };
  }

  /**
   * Create a [PartiallyResolveUnitReferencesTask] based on the given [target]
   * in the given [context].
   */
  static PartiallyResolveUnitReferencesTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new PartiallyResolveUnitReferencesTask(context, target);
  }
}

/**
 * A task that ensures that [LIBRARY_ELEMENT2] is ready for the target library
 * source and its import/export closure.
 */
class ReadyLibraryElement2Task extends SourceBasedAnalysisTask {
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ReadyLibraryElement2Task',
      createTask,
      buildInputs,
      <ResultDescriptor>[READY_LIBRARY_ELEMENT2]);

  ReadyLibraryElement2Task(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  bool get handlesDependencyCycles => true;

  @override
  void internalPerform() {
    outputs[READY_LIBRARY_ELEMENT2] = true;
  }

  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      'thisLibraryElementReady': LIBRARY_ELEMENT2.of(source),
      'directlyImportedLibrariesReady':
          IMPORTED_LIBRARIES.of(source).toListOf(READY_LIBRARY_ELEMENT2),
      'directlyExportedLibrariesReady':
          EXPORTED_LIBRARIES.of(source).toListOf(READY_LIBRARY_ELEMENT2),
    };
  }

  static ReadyLibraryElement2Task createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ReadyLibraryElement2Task(context, target);
  }
}

/**
 * A task that ensures that [LIBRARY_ELEMENT6] is ready for the target library
 * source and its import/export closure.
 */
class ReadyLibraryElement5Task extends SourceBasedAnalysisTask {
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ReadyLibraryElement5Task',
      createTask,
      buildInputs,
      <ResultDescriptor>[READY_LIBRARY_ELEMENT6]);

  ReadyLibraryElement5Task(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  bool get handlesDependencyCycles => true;

  @override
  void internalPerform() {
    outputs[READY_LIBRARY_ELEMENT6] = true;
  }

  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      'thisLibraryElementReady': LIBRARY_ELEMENT6.of(source),
      'directlyImportedLibrariesReady':
          IMPORTED_LIBRARIES.of(source).toListOf(READY_LIBRARY_ELEMENT6),
      'directlyExportedLibrariesReady':
          EXPORTED_LIBRARIES.of(source).toListOf(READY_LIBRARY_ELEMENT6),
    };
  }

  static ReadyLibraryElement5Task createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ReadyLibraryElement5Task(context, target);
  }
}

/**
 * A task that ensures that [LIBRARY_ELEMENT7] is ready for the target library
 * source and its import/export closure.
 */
class ReadyLibraryElement7Task extends SourceBasedAnalysisTask {
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ReadyLibraryElement7Task',
      createTask,
      buildInputs,
      <ResultDescriptor>[READY_LIBRARY_ELEMENT7]);

  ReadyLibraryElement7Task(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  bool get handlesDependencyCycles => true;

  @override
  void internalPerform() {
    outputs[READY_LIBRARY_ELEMENT7] = true;
  }

  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      'thisLibraryElementReady': LIBRARY_ELEMENT7.of(source),
      'directlyImportedLibrariesReady':
          IMPORTED_LIBRARIES.of(source).toListOf(READY_LIBRARY_ELEMENT7),
      'directlyExportedLibrariesReady':
          EXPORTED_LIBRARIES.of(source).toListOf(READY_LIBRARY_ELEMENT7),
    };
  }

  static ReadyLibraryElement7Task createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ReadyLibraryElement7Task(context, target);
  }
}

/**
 * A task that ensures that [RESOLVED_UNIT] is ready for every unit of the
 * target library source and its import/export closure.
 */
class ReadyResolvedUnitTask extends SourceBasedAnalysisTask {
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ReadyResolvedUnitTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[READY_RESOLVED_UNIT]);

  ReadyResolvedUnitTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  bool get handlesDependencyCycles => true;

  @override
  void internalPerform() {
    outputs[READY_RESOLVED_UNIT] = true;
  }

  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      'thisLibraryUnitsReady':
          LIBRARY_SPECIFIC_UNITS.of(source).toListOf(RESOLVED_UNIT),
    };
  }

  static ReadyResolvedUnitTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ReadyResolvedUnitTask(context, target);
  }
}

/**
 * A task that ensures that the expression AST for a constant is resolved and
 * sets the [CONSTANT_EXPRESSION_RESOLVED] result.
 */
class ResolveConstantExpressionTask extends ConstantEvaluationAnalysisTask {
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveConstantExpressionTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[CONSTANT_EXPRESSION_RESOLVED]);

  ResolveConstantExpressionTask(
      InternalAnalysisContext context, ConstantEvaluationTarget constant)
      : super(context, constant);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Record outputs.
    //
    outputs[CONSTANT_EXPRESSION_RESOLVED] = true;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source librarySource;
    if (target is Element) {
      CompilationUnitElementImpl unit = target
          .getAncestor((Element element) => element is CompilationUnitElement);
      librarySource = unit.librarySource;
    } else if (target is ElementAnnotationImpl) {
      librarySource = target.librarySource;
    } else {
      throw new AnalysisException(
          'Cannot build inputs for a ${target.runtimeType}');
    }
    return <String, TaskInput>{
      'createdResolvedUnit': CREATED_RESOLVED_UNIT11
          .of(new LibrarySpecificUnit(librarySource, target.source))
    };
  }

  /**
   * Create a [ResolveConstantExpressionTask] based on the given [target] in
   * the given [context].
   */
  static ResolveConstantExpressionTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveConstantExpressionTask(context, target);
  }
}

/**
 * A task that resolves imports and export directives to already built elements.
 */
class ResolveDirectiveElementsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the defining [LIBRARY_ELEMENT2].
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The name of the input for [RESOLVED_UNIT1] of a unit.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  static const String SOURCES_MODIFICATION_TIME_INPUT =
      'SOURCES_MODIFICATION_TIME_INPUT';
  static const String IMPORTS_SOURCE_KIND_INPUT = 'IMPORTS_SOURCE_KIND_INPUT';
  static const String EXPORTS_SOURCE_KIND_INPUT = 'EXPORTS_SOURCE_KIND_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveDirectiveElementsTask',
      createTask,
      buildInputs, <ResultDescriptor>[
    CREATED_RESOLVED_UNIT2,
    RESOLVED_UNIT2,
    RESOLVE_DIRECTIVES_ERRORS
  ]);

  ResolveDirectiveElementsTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibrarySpecificUnit targetUnit = target;
    //
    // Prepare inputs.
    //
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    Map<Source, int> sourceModificationTimeMap =
        getRequiredInput(SOURCES_MODIFICATION_TIME_INPUT);
    Map<Source, SourceKind> importSourceKindMap =
        getRequiredInput(IMPORTS_SOURCE_KIND_INPUT);
    Map<Source, SourceKind> exportSourceKindMap =
        getRequiredInput(EXPORTS_SOURCE_KIND_INPUT);
    //
    // Resolve directive AST nodes to elements.
    //
    List<AnalysisError> errors = const <AnalysisError>[];
    if (targetUnit.unit == targetUnit.library) {
      DirectiveResolver resolver = new DirectiveResolver(
          sourceModificationTimeMap, importSourceKindMap, exportSourceKindMap);
      unit.accept(resolver);
      errors = resolver.errors;
    }
    //
    // Record outputs.
    //
    outputs[CREATED_RESOLVED_UNIT2] = true;
    outputs[RESOLVED_UNIT2] = unit;
    outputs[RESOLVE_DIRECTIVES_ERRORS] = errors;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT2.of(unit.library),
      UNIT_INPUT: RESOLVED_UNIT1.of(unit),
      SOURCES_MODIFICATION_TIME_INPUT:
          REFERENCED_SOURCES.of(unit.library).toMapOf(MODIFICATION_TIME),
      IMPORTS_SOURCE_KIND_INPUT:
          IMPORTED_LIBRARIES.of(unit.library).toMapOf(SOURCE_KIND),
      EXPORTS_SOURCE_KIND_INPUT:
          EXPORTED_LIBRARIES.of(unit.library).toMapOf(SOURCE_KIND)
    };
  }

  /**
   * Create a [ResolveDirectiveElementsTask] based on the given [target] in
   * the given [context].
   */
  static ResolveDirectiveElementsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveDirectiveElementsTask(context, target);
  }
}

/**
 * An artificial task that does nothing except to force [LIBRARY_ELEMENT7] for
 * the target library and its import/export closure.
 */
class ResolvedUnit7InLibraryClosureTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT7] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolvedUnit7InLibraryClosureTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT8]);

  ResolvedUnit7InLibraryClosureTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibraryElement library = getRequiredInput(LIBRARY_INPUT);
    outputs[LIBRARY_ELEMENT8] = library;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      'readyForClosure': READY_LIBRARY_ELEMENT7.of(source),
      LIBRARY_INPUT: LIBRARY_ELEMENT7.of(source),
    };
  }

  /**
   * Create a [ResolvedUnit7InLibraryClosureTask] based on the given
   * [target] in the given [context].
   */
  static ResolvedUnit7InLibraryClosureTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolvedUnit7InLibraryClosureTask(context, target);
  }
}

/**
 * An artificial task that does nothing except to force [LIBRARY_ELEMENT6] and
 * [RESOLVED_UNIT7] in the defining and part units of a library.
 */
class ResolvedUnit7InLibraryTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT6] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolvedUnit7InLibraryTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT7]);

  ResolvedUnit7InLibraryTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibraryElement library = getRequiredInput(LIBRARY_INPUT);
    outputs[LIBRARY_ELEMENT7] = library;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      'resolvedUnits':
          LIBRARY_SPECIFIC_UNITS.of(source).toListOf(RESOLVED_UNIT7),
      LIBRARY_INPUT: LIBRARY_ELEMENT6.of(source),
    };
  }

  /**
   * Create a [ResolvedUnit7InLibraryTask] based on the given [target]
   * in the given [context].
   */
  static ResolvedUnit7InLibraryTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolvedUnit7InLibraryTask(context, target);
  }
}

/**
 * A task that ensures that all of the inferable instance members in a
 * compilation unit have had their right hand sides re-resolved
 */
class ResolveInstanceFieldsInUnitTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT6] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The name of the input whose value is the [RESOLVED_UNIT8] for the
   * compilation unit.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveInstanceFieldsInUnitTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[CREATED_RESOLVED_UNIT9, RESOLVED_UNIT9]);

  /**
   * Initialize a newly created task to build a library element for the given
   * [unit] in the given [context].
   */
  ResolveInstanceFieldsInUnitTask(
      InternalAnalysisContext context, LibrarySpecificUnit unit)
      : super(context, unit);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    LibraryElement libraryElement = getRequiredInput(LIBRARY_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);

    CompilationUnitElement unitElement = unit.element;
    if (context.analysisOptions.strongMode) {
      //
      // Resolve references.
      //
      InstanceFieldResolverVisitor visitor = new InstanceFieldResolverVisitor(
          libraryElement,
          unitElement.source,
          typeProvider,
          AnalysisErrorListener.NULL_LISTENER);
      visitor.resolveCompilationUnit(unit);
    }
    //
    // Record outputs.
    //
    outputs[RESOLVED_UNIT9] = unit;
    outputs[CREATED_RESOLVED_UNIT9] = true;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [libSource].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      UNIT_INPUT: RESOLVED_UNIT8.of(unit),
      LIBRARY_INPUT: LIBRARY_ELEMENT6.of(unit.library),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request),
      // In strong mode, add additional dependencies to enforce inference
      // ordering.

      // Require that static variable inference  be complete for all units in
      // the current library cycle.
      'orderLibraryCycleTasks':
          LIBRARY_CYCLE_UNITS.of(unit.library).toListOf(CREATED_RESOLVED_UNIT8),
      // Require that full inference be complete for all dependencies of the
      // current library cycle.
      'orderLibraryCycles': LIBRARY_CYCLE_DEPENDENCIES
          .of(unit.library)
          .toListOf(CREATED_RESOLVED_UNIT10)
    };
  }

  /**
   * Create a [ResolveInstanceFieldsInUnitTask] based on the given [target] in
   * the given [context].
   */
  static ResolveInstanceFieldsInUnitTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveInstanceFieldsInUnitTask(context, target);
  }
}

/**
 * A task that finishes resolution by requesting [RESOLVED_UNIT11] for every
 * unit in the libraries closure and produces [LIBRARY_ELEMENT9].
 */
class ResolveLibraryReferencesTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT8] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveLibraryReferencesTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT9]);

  ResolveLibraryReferencesTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibraryElement library = getRequiredInput(LIBRARY_INPUT);
    outputs[LIBRARY_ELEMENT9] = library;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT8.of(source),
      'resolvedUnits':
          LIBRARY_SPECIFIC_UNITS.of(source).toListOf(RESOLVED_UNIT11),
    };
  }

  /**
   * Create a [ResolveLibraryReferencesTask] based on the given [target] in
   * the given [context].
   */
  static ResolveLibraryReferencesTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveLibraryReferencesTask(context, target);
  }
}

/**
 * A task that finishes resolution by requesting [RESOLVED_UNIT12] for every
 * unit in the libraries closure and produces [LIBRARY_ELEMENT].
 */
class ResolveLibraryTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT9] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The name of the list of [RESOLVED_UNIT12] input.
   */
  static const String UNITS_INPUT = 'UNITS_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveLibraryTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT]);

  ResolveLibraryTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    LibraryElement library = getRequiredInput(LIBRARY_INPUT);
    //
    // Record outputs.
    //
    outputs[LIBRARY_ELEMENT] = library;
  }

/**
 * Return a map from the names of the inputs of this kind of task to the task
 * input descriptors describing those inputs for a task with the
 * given [target].
 */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT9.of(source),
      'thisLibraryClosureIsReady': READY_RESOLVED_UNIT.of(source),
    };
  }

/**
 * Create a [ResolveLibraryTask] based on the given [target] in the given
 * [context].
 */
  static ResolveLibraryTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveLibraryTask(context, target);
  }
}

/**
 * An artificial task that does nothing except to force type names resolution
 * for the defining and part units of a library.
 */
class ResolveLibraryTypeNamesTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT5] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveLibraryTypeNamesTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT6]);

  ResolveLibraryTypeNamesTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    LibraryElement library = getRequiredInput(LIBRARY_INPUT);
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Create the synthetic element for `loadLibrary`.
    //
    (library as LibraryElementImpl).createLoadLibraryFunction(typeProvider);
    //
    // Record outputs.
    //
    outputs[LIBRARY_ELEMENT6] = library;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      'resolvedUnit':
          LIBRARY_SPECIFIC_UNITS.of(source).toListOf(RESOLVED_UNIT5),
      LIBRARY_INPUT: LIBRARY_ELEMENT5.of(source),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request)
    };
  }

  /**
   * Create a [ResolveLibraryTypeNamesTask] based on the given [target] in
   * the given [context].
   */
  static ResolveLibraryTypeNamesTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveLibraryTypeNamesTask(context, target);
  }
}

/**
 * An artificial task that does nothing except to force type parameter bounds
 * type names resolution for the defining and part units of a library.
 */
class ResolveTopLevelLibraryTypeBoundsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT4] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveTopLevelLibraryTypeBoundsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT5]);

  ResolveTopLevelLibraryTypeBoundsTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  bool get handlesDependencyCycles => true;

  @override
  void internalPerform() {
    LibraryElement library = getRequiredInput(LIBRARY_INPUT);
    outputs[LIBRARY_ELEMENT5] = library;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT4.of(source),
      'thisLibraryUnitsReady':
          LIBRARY_SPECIFIC_UNITS.of(source).toListOf(RESOLVED_UNIT4),
      'directlyImportedLibrariesReady':
          IMPORTED_LIBRARIES.of(source).toListOf(LIBRARY_ELEMENT5),
      'directlyExportedLibrariesReady':
          EXPORTED_LIBRARIES.of(source).toListOf(LIBRARY_ELEMENT5),
    };
  }

  /**
   * Create a [ResolveTopLevelLibraryTypeBoundsTask] based on the given [target]
   * in the given [context].
   */
  static ResolveTopLevelLibraryTypeBoundsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveTopLevelLibraryTypeBoundsTask(context, target);
  }
}

/**
 * A task that builds [RESOLVED_UNIT4] for a unit.
 */
class ResolveTopLevelUnitTypeBoundsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the defining [LIBRARY_ELEMENT4].
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The name of the [RESOLVED_UNIT3] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveTopLevelUnitTypeBoundsTask',
      createTask,
      buildInputs, <ResultDescriptor>[
    RESOLVE_TYPE_BOUNDS_ERRORS,
    CREATED_RESOLVED_UNIT4,
    RESOLVED_UNIT4
  ]);

  ResolveTopLevelUnitTypeBoundsTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    LibraryElement library = getRequiredInput(LIBRARY_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    CompilationUnitElement unitElement = unit.element;
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Resolve TypeName nodes.
    //
    RecordingErrorListener errorListener = new RecordingErrorListener();
    new TypeParameterBoundsResolver(
            typeProvider, library, unitElement.source, errorListener)
        .resolveTypeBounds(unit);
    //
    // Record outputs.
    //
    outputs[RESOLVE_TYPE_BOUNDS_ERRORS] =
        getTargetSourceErrors(errorListener, target);
    outputs[RESOLVED_UNIT4] = unit;
    outputs[CREATED_RESOLVED_UNIT4] = true;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    // TODO(brianwilkerson) This task updates the element model to have type
    // information and updates the class hierarchy. It should produce a new
    // version of the element model in order to record those changes.
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      'importsExportNamespace':
          IMPORTED_LIBRARIES.of(unit.library).toMapOf(LIBRARY_ELEMENT4),
      'dependOnAllExportedSources':
          IMPORTED_LIBRARIES.of(unit.library).toMapOf(EXPORT_SOURCE_CLOSURE),
      LIBRARY_INPUT: LIBRARY_ELEMENT4.of(unit.library),
      UNIT_INPUT: RESOLVED_UNIT3.of(unit),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request)
    };
  }

  /**
   * Create a [ResolveTopLevelUnitTypeBoundsTask] based on the given [target] in
   * the given [context].
   */
  static ResolveTopLevelUnitTypeBoundsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveTopLevelUnitTypeBoundsTask(context, target);
  }
}

/**
 * A task that resolves the bodies of top-level functions, constructors, and
 * methods within a single compilation unit.
 */
class ResolveUnitTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the defining [LIBRARY_ELEMENT8].
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The name of the [RESOLVED_UNIT10] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveUnitTask', createTask, buildInputs, <ResultDescriptor>[
    CONSTANT_EXPRESSIONS_DEPENDENCIES,
    RESOLVE_UNIT_ERRORS,
    CREATED_RESOLVED_UNIT11,
    RESOLVED_UNIT11
  ]);

  ResolveUnitTask(
      InternalAnalysisContext context, LibrarySpecificUnit compilationUnit)
      : super(context, compilationUnit);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    LibrarySpecificUnit target = this.target;
    LibraryElement libraryElement = getRequiredInput(LIBRARY_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Resolve everything.
    //
    CompilationUnitElement unitElement = unit.element;
    RecordingErrorListener errorListener = new RecordingErrorListener();
    ResolverVisitor visitor = new ResolverVisitor(
        libraryElement, unitElement.source, typeProvider, errorListener);
    unit.accept(visitor);
    //
    // Compute constant expressions' dependencies.
    //
    List<ConstantEvaluationTarget> constExprDependencies;
    {
      ConstantExpressionsDependenciesFinder finder =
          new ConstantExpressionsDependenciesFinder();
      unit.accept(finder);
      constExprDependencies = finder.dependencies.toList();
    }
    //
    // Record outputs.
    //
    // TODO(brianwilkerson) This task modifies the element model (by copying the
    // AST's for constructor initializers into it) but does not produce an
    // updated version of the element model.
    //
    outputs[CONSTANT_EXPRESSIONS_DEPENDENCIES] = constExprDependencies;
    outputs[RESOLVE_UNIT_ERRORS] = getTargetSourceErrors(errorListener, target);
    outputs[RESOLVED_UNIT11] = unit;
    outputs[CREATED_RESOLVED_UNIT11] = true;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT8.of(unit.library),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request),
      UNIT_INPUT: RESOLVED_UNIT10.of(unit),
      // In strong mode, add additional dependencies to enforce inference
      // ordering.

      // Require that inference be complete for all units in the
      // current library cycle.
      'orderLibraryCycleTasks':
          LIBRARY_CYCLE_UNITS.of(unit.library).toListOf(CREATED_RESOLVED_UNIT10)
    };
  }

  /**
   * Create a [ResolveUnitTask] based on the given [target] in
   * the given [context].
   */
  static ResolveUnitTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveUnitTask(context, target);
  }
}

/**
 * A task that builds [RESOLVED_UNIT5] for a unit.
 */
class ResolveUnitTypeNamesTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the defining [LIBRARY_ELEMENT5].
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The name of the [RESOLVED_UNIT4] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveUnitTypeNamesTask', createTask, buildInputs, <ResultDescriptor>[
    RESOLVE_TYPE_NAMES_ERRORS,
    CREATED_RESOLVED_UNIT5,
    RESOLVED_UNIT5
  ]);

  ResolveUnitTypeNamesTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    LibraryElement library = getRequiredInput(LIBRARY_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    CompilationUnitElement unitElement = unit.element;
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Resolve TypeName nodes.
    //
    RecordingErrorListener errorListener = new RecordingErrorListener();
    TypeResolverVisitor visitor = new TypeResolverVisitor(
        library, unitElement.source, typeProvider, errorListener);
    unit.accept(visitor);
    //
    // Record outputs.
    //
    outputs[RESOLVE_TYPE_NAMES_ERRORS] =
        getTargetSourceErrors(errorListener, target);
    outputs[RESOLVED_UNIT5] = unit;
    outputs[CREATED_RESOLVED_UNIT5] = true;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    // TODO(brianwilkerson) This task updates the element model to have type
    // information and updates the class hierarchy. It should produce a new
    // version of the element model in order to record those changes.
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT5.of(unit.library),
      UNIT_INPUT: RESOLVED_UNIT4.of(unit),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request)
    };
  }

  /**
   * Create a [ResolveUnitTypeNamesTask] based on the given [target] in
   * the given [context].
   */
  static ResolveUnitTypeNamesTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveUnitTypeNamesTask(context, target);
  }
}

/**
 * A task that builds [RESOLVED_UNIT6] for a unit.
 */
class ResolveVariableReferencesTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT1] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The name of the [RESOLVED_UNIT5] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveVariableReferencesTask',
      createTask,
      buildInputs, <ResultDescriptor>[
    CREATED_RESOLVED_UNIT6,
    RESOLVED_UNIT6,
    VARIABLE_REFERENCE_ERRORS
  ]);

  ResolveVariableReferencesTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    LibraryElement libraryElement = getRequiredInput(LIBRARY_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    CompilationUnitElement unitElement = unit.element;
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Resolve local variables.
    //
    RecordingErrorListener errorListener = new RecordingErrorListener();
    Scope nameScope = new LibraryScope(libraryElement);
    VariableResolverVisitor visitor = new VariableResolverVisitor(
        libraryElement, unitElement.source, typeProvider, errorListener,
        nameScope: nameScope);
    unit.accept(visitor);
    //
    // Record outputs.
    //
    outputs[RESOLVED_UNIT6] = unit;
    outputs[CREATED_RESOLVED_UNIT6] = true;
    outputs[VARIABLE_REFERENCE_ERRORS] =
        getTargetSourceErrors(errorListener, target);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT1.of(unit.library),
      UNIT_INPUT: RESOLVED_UNIT5.of(unit),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request)
    };
  }

  /**
   * Create a [ResolveVariableReferencesTask] based on the given [target] in
   * the given [context].
   */
  static ResolveVariableReferencesTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveVariableReferencesTask(context, target);
  }
}

/**
 * A task that scans the content of a Dart file, producing a stream of Dart
 * tokens, line information, and any lexical errors encountered in the process.
 */
class ScanDartTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the content of the file.
   */
  static const String CONTENT_INPUT_NAME = 'CONTENT_INPUT_NAME';

  /**
   * The name of the input whose value is the modification time of the file.
   */
  static const String MODIFICATION_TIME_INPUT = 'MODIFICATION_TIME_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ScanDartTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[IGNORE_INFO, LINE_INFO, SCAN_ERRORS, TOKEN_STREAM],
      suitabilityFor: suitabilityFor);

  /**
   * Initialize a newly created task to access the content of the source
   * associated with the given [target] in the given [context].
   */
  ScanDartTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    Source source = getRequiredSource();
    RecordingErrorListener errorListener = new RecordingErrorListener();

    int modificationTime = getRequiredInput(MODIFICATION_TIME_INPUT);
    if (modificationTime < 0) {
      String message = 'Content could not be read';
      if (context is InternalAnalysisContext) {
        CacheEntry entry =
            (context as InternalAnalysisContext).getCacheEntry(target);
        CaughtException exception = entry.exception;
        if (exception != null) {
          message = exception.toString();
        }
      }
      if (source.exists()) {
        errorListener.onError(new AnalysisError(
            source, 0, 0, ScannerErrorCode.UNABLE_GET_CONTENT, [message]));
      }
    }
    if (target is DartScript) {
      DartScript script = target;
      List<ScriptFragment> fragments = script.fragments;
      if (fragments.length < 1) {
        throw new AnalysisException('Cannot scan scripts with no fragments');
      } else if (fragments.length > 1) {
        throw new AnalysisException(
            'Cannot scan scripts with multiple fragments');
      }
      ScriptFragment fragment = fragments[0];

      Scanner scanner = new Scanner(
          source,
          new SubSequenceReader(fragment.content, fragment.offset),
          errorListener);
      scanner.setSourceStart(fragment.line, fragment.column);
      scanner.preserveComments = context.analysisOptions.preserveComments;
      scanner.scanGenericMethodComments = context.analysisOptions.strongMode;
      scanner.scanLazyAssignmentOperators =
          context.analysisOptions.enableLazyAssignmentOperators;

      LineInfo lineInfo = new LineInfo(scanner.lineStarts);

      outputs[TOKEN_STREAM] = scanner.tokenize();
      outputs[LINE_INFO] = lineInfo;
      outputs[IGNORE_INFO] =
          IgnoreInfo.calculateIgnores(fragment.content, lineInfo);
      outputs[SCAN_ERRORS] = getUniqueErrors(errorListener.errors);
    } else if (target is Source) {
      String content = getRequiredInput(CONTENT_INPUT_NAME);

      Scanner scanner =
          new Scanner(source, new CharSequenceReader(content), errorListener);
      scanner.preserveComments = context.analysisOptions.preserveComments;
      scanner.scanGenericMethodComments = context.analysisOptions.strongMode;
      scanner.scanLazyAssignmentOperators =
          context.analysisOptions.enableLazyAssignmentOperators;

      LineInfo lineInfo = new LineInfo(scanner.lineStarts);

      outputs[TOKEN_STREAM] = scanner.tokenize();
      outputs[LINE_INFO] = lineInfo;
      outputs[IGNORE_INFO] = IgnoreInfo.calculateIgnores(content, lineInfo);
      outputs[SCAN_ERRORS] = getUniqueErrors(errorListener.errors);
    } else {
      throw new AnalysisException(
          'Cannot scan Dart code from a ${target.runtimeType}');
    }
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    if (target is Source) {
      return <String, TaskInput>{
        CONTENT_INPUT_NAME: CONTENT.of(target, flushOnAccess: true),
        MODIFICATION_TIME_INPUT: MODIFICATION_TIME.of(target)
      };
    } else if (target is DartScript) {
      // This task does not use the following input; it is included only to add
      // a dependency between this value and the containing source so that when
      // the containing source is modified these results will be invalidated.
      Source source = target.source;
      return <String, TaskInput>{
        '-': DART_SCRIPTS.of(source),
        MODIFICATION_TIME_INPUT: MODIFICATION_TIME.of(source)
      };
    }
    throw new AnalysisException(
        'Cannot build inputs for a ${target.runtimeType}');
  }

  /**
   * Create a [ScanDartTask] based on the given [target] in the given [context].
   */
  static ScanDartTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ScanDartTask(context, target);
  }

  /**
   * Return an indication of how suitable this task is for the given [target].
   */
  static TaskSuitability suitabilityFor(AnalysisTarget target) {
    if (target is Source) {
      if (target.shortName.endsWith(AnalysisEngine.SUFFIX_DART)) {
        return TaskSuitability.HIGHEST;
      }
      return TaskSuitability.LOWEST;
    } else if (target is DartScript) {
      return TaskSuitability.HIGHEST;
    }
    return TaskSuitability.NONE;
  }
}

/**
 * A task that builds [STRONG_MODE_ERRORS] for a unit.  Also builds
 * [RESOLVED_UNIT] for a unit.
 */
class StrongModeVerifyUnitTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT12] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'StrongModeVerifyUnitTask', createTask, buildInputs, <ResultDescriptor>[
    STRONG_MODE_ERRORS,
    CREATED_RESOLVED_UNIT,
    RESOLVED_UNIT
  ]);

  StrongModeVerifyUnitTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    //
    // Prepare inputs.
    //
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    AnalysisOptionsImpl options = context.analysisOptions;
    if (options.strongMode) {
      CodeChecker checker = new CodeChecker(
          typeProvider,
          new StrongTypeSystemImpl(typeProvider,
              implicitCasts: options.implicitCasts,
              nonnullableTypes: options.nonnullableTypes),
          errorListener,
          options);
      checker.visitCompilationUnit(unit);
    }
    //
    // Record outputs.
    //
    outputs[STRONG_MODE_ERRORS] = getUniqueErrors(errorListener.errors);
    outputs[CREATED_RESOLVED_UNIT] = true;
    outputs[RESOLVED_UNIT] = unit;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      UNIT_INPUT: RESOLVED_UNIT12.of(unit),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request),
    };
  }

  /**
   * Create a [StrongModeVerifyUnitTask] based on the given [target] in
   * the given [context].
   */
  static StrongModeVerifyUnitTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new StrongModeVerifyUnitTask(context, target);
  }
}

/**
 * A task that builds [VERIFY_ERRORS] for a unit.
 */
class VerifyUnitTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [PENDING_ERRORS] input.
   */
  static const String PENDING_ERRORS_INPUT = 'PENDING_ERRORS_INPUT';

  /**
   * The name of the input of a mapping from [REFERENCED_SOURCES] to their
   * [MODIFICATION_TIME]s.
   */
  static const String REFERENCED_SOURCE_MODIFICATION_TIME_MAP_INPUT =
      'REFERENCED_SOURCE_MODIFICATION_TIME_MAP_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The name of the [RESOLVED_UNIT] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor('VerifyUnitTask',
      createTask, buildInputs, <ResultDescriptor>[VERIFY_ERRORS]);

  /**
   * The [ErrorReporter] to report errors to.
   */
  ErrorReporter errorReporter;

  /**
   * The mapping from the current library referenced sources to their
   * modification times.
   */
  Map<Source, int> sourceTimeMap;

  VerifyUnitTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    Source source = getRequiredSource();
    errorReporter = new ErrorReporter(errorListener, source);
    //
    // Prepare inputs.
    //
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    CompilationUnitElement unitElement = unit.element;
    LibraryElement libraryElement = unitElement.library;
    if (libraryElement == null) {
      throw new AnalysisException(
          'VerifyUnitTask verifying a unit with no library: '
          '${unitElement.source.fullName}');
    }
    List<PendingError> pendingErrors = getRequiredInput(PENDING_ERRORS_INPUT);
    sourceTimeMap =
        getRequiredInput(REFERENCED_SOURCE_MODIFICATION_TIME_MAP_INPUT);
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Validate the directives.
    //
    validateDirectives(unit);
    //
    // Use the ConstantVerifier to compute errors.
    //
    ConstantVerifier constantVerifier = new ConstantVerifier(
        errorReporter, libraryElement, typeProvider, context.declaredVariables);
    unit.accept(constantVerifier);
    //
    // Use the ErrorVerifier to compute errors.
    //
    ErrorVerifier errorVerifier = new ErrorVerifier(
        errorReporter,
        libraryElement,
        typeProvider,
        new InheritanceManager(libraryElement),
        context.analysisOptions.enableSuperMixins);
    unit.accept(errorVerifier);
    //
    // Convert the pending errors into actual errors.
    //
    for (PendingError pendingError in pendingErrors) {
      errorListener.onError(pendingError.toAnalysisError());
    }
    //
    // Record outputs.
    //
    outputs[VERIFY_ERRORS] = getUniqueErrors(errorListener.errors);
  }

  /**
   * Check each directive in the given [unit] to see if the referenced source
   * exists and report an error if it does not.
   */
  void validateDirectives(CompilationUnit unit) {
    NodeList<Directive> directives = unit.directives;
    int length = directives.length;
    for (int i = 0; i < length; i++) {
      Directive directive = directives[i];
      if (directive is UriBasedDirective) {
        validateReferencedSource(directive);
      }
    }
  }

  /**
   * Check the given [directive] to see if the referenced source exists and
   * report an error if it does not.
   */
  void validateReferencedSource(UriBasedDirectiveImpl directive) {
    if (directive is NamespaceDirectiveImpl) {
      for (Configuration configuration in directive.configurations) {
        Source source = configuration.uriSource;
        StringLiteral uriLiteral = configuration.uri;
        String uriContent = uriLiteral?.stringValue?.trim();
        if (source != null) {
          int modificationTime = sourceTimeMap[source] ?? -1;
          if (modificationTime >= 0) {
            continue;
          }
        } else {
          // Don't report errors already reported by ParseDartTask.resolveDirective
          if (UriBasedDirectiveImpl.validateUri(
                  directive is ImportDirective, uriLiteral, uriContent) !=
              null) {
            continue;
          }
        }
        CompileTimeErrorCode errorCode =
            CompileTimeErrorCode.URI_DOES_NOT_EXIST;
        if (_isGenerated(source)) {
          errorCode = CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED;
        }
        errorReporter.reportErrorForNode(errorCode, uriLiteral, [uriContent]);
      }
    }
    Source source = directive.uriSource;
    if (source != null) {
      int modificationTime = sourceTimeMap[source] ?? -1;
      if (modificationTime >= 0) {
        return;
      }
    } else {
      // Don't report errors already reported by ParseDartTask.resolveDirective
      if (directive.validate() != null) {
        return;
      }
    }
    StringLiteral uriLiteral = directive.uri;
    CompileTimeErrorCode errorCode = CompileTimeErrorCode.URI_DOES_NOT_EXIST;
    if (_isGenerated(source)) {
      errorCode = CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED;
    }
    errorReporter
        .reportErrorForNode(errorCode, uriLiteral, [directive.uriContent]);
  }

  /**
   * Return `true` if the given [source] refers to a file that is assumed to be
   * generated.
   */
  bool _isGenerated(Source source) {
    if (source == null) {
      return false;
    }
    // TODO(brianwilkerson) Generalize this mechanism.
    const List<String> suffixes = const <String>[
      '.g.dart',
      '.pb.dart',
      '.pbenum.dart',
      '.pbserver.dart',
      '.pbjson.dart',
      '.template.dart'
    ];
    String fullName = source.fullName;
    for (String suffix in suffixes) {
      if (fullName.endsWith(suffix)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      'thisLibraryClosureIsReady': READY_RESOLVED_UNIT.of(unit.library),
      UNIT_INPUT: RESOLVED_UNIT.of(unit),
      REFERENCED_SOURCE_MODIFICATION_TIME_MAP_INPUT:
          REFERENCED_SOURCES.of(unit.library).toMapOf(MODIFICATION_TIME),
      PENDING_ERRORS_INPUT: PENDING_ERRORS.of(unit),
      'requiredConstants': REQUIRED_CONSTANTS.of(unit).toListOf(CONSTANT_VALUE),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request)
    };
  }

  /**
   * Create a [VerifyUnitTask] based on the given [target] in
   * the given [context].
   */
  static VerifyUnitTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new VerifyUnitTask(context, target);
  }
}

/**
 * A [TaskInput] whose value is a list of library sources exported directly
 * or indirectly by the target [Source].
 *
 * [resultDescriptor] is the type of result which should be produced for each
 * target [Source].
 */
class _ExportSourceClosureTaskInput extends TaskInputImpl<List<Source>> {
  final Source target;
  final ResultDescriptor resultDescriptor;

  _ExportSourceClosureTaskInput(this.target, this.resultDescriptor);

  @override
  TaskInputBuilder<List<Source>> createBuilder() =>
      new _SourceClosureTaskInputBuilder(
          target, _SourceClosureKind.EXPORT, resultDescriptor);
}

/**
 * A [TaskInput] whose value is a list of library sources imported directly
 * or indirectly by the target [Source].
 *
 * [resultDescriptor] is the type of result which should be produced for each
 * target [Source].
 */
class _ImportSourceClosureTaskInput extends TaskInputImpl<List<Source>> {
  final Source target;
  final ResultDescriptor resultDescriptor;

  _ImportSourceClosureTaskInput(this.target, this.resultDescriptor);

  @override
  TaskInputBuilder<List<Source>> createBuilder() =>
      new _SourceClosureTaskInputBuilder(
          target, _SourceClosureKind.IMPORT, resultDescriptor);
}

/**
 * An object holding either the name or the source associated with a part-of
 * directive.
 */
class _NameOrSource {
  final String name;

  final Source source;

  _NameOrSource(this.name, this.source);
}

/**
 * The kind of the source closure to build.
 */
enum _SourceClosureKind { IMPORT, EXPORT, IMPORT_EXPORT }

/**
 * A [TaskInputBuilder] to build values for [_ImportSourceClosureTaskInput].
 */
class _SourceClosureTaskInputBuilder implements TaskInputBuilder<List<Source>> {
  final _SourceClosureKind kind;
  final Set<LibraryElement> _libraries = new HashSet<LibraryElement>();
  final List<Source> _newSources = <Source>[];

  @override
  final ResultDescriptor currentResult;

  Source currentTarget;

  _SourceClosureTaskInputBuilder(
      Source librarySource, this.kind, this.currentResult) {
    _newSources.add(librarySource);
  }

  @override
  void set currentValue(Object value) {
    LibraryElement library = value;
    if (_libraries.add(library)) {
      if (kind == _SourceClosureKind.IMPORT ||
          kind == _SourceClosureKind.IMPORT_EXPORT) {
        List<ImportElement> imports = library.imports;
        int length = imports.length;
        for (int i = 0; i < length; i++) {
          ImportElement importElement = imports[i];
          Source importedSource = importElement.importedLibrary?.source;
          if (importedSource != null) {
            _newSources.add(importedSource);
          }
        }
      }
      if (kind == _SourceClosureKind.EXPORT ||
          kind == _SourceClosureKind.IMPORT_EXPORT) {
        List<ExportElement> exports = library.exports;
        int length = exports.length;
        for (int i = 0; i < length; i++) {
          ExportElement exportElement = exports[i];
          Source exportedSource = exportElement.exportedLibrary?.source;
          if (exportedSource != null) {
            _newSources.add(exportedSource);
          }
        }
      }
    }
  }

  @override
  bool get flushOnAccess => false;

  @override
  List<Source> get inputValue {
    return _libraries.map((LibraryElement library) => library.source).toList();
  }

  @override
  void currentValueNotAvailable() {
    // Nothing needs to be done.  moveNext() will simply go on to the next new
    // source.
  }

  @override
  bool moveNext() {
    if (_newSources.isEmpty) {
      return false;
    }
    currentTarget = _newSources.removeLast();
    return true;
  }
}
