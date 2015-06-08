// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.dart;

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart'
    hide AnalysisCache, AnalysisTask;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/src/task/model.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';

/**
 * The [ResultCachingPolicy] for ASTs.
 */
const ResultCachingPolicy AST_CACHING_POLICY =
    const SimpleResultCachingPolicy(8192, 8192);

/**
 * The errors produced while resolving a library directives.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<AnalysisError> BUILD_DIRECTIVES_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'BUILD_DIRECTIVES_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The errors produced while building function type aliases.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<AnalysisError> BUILD_FUNCTION_TYPE_ALIASES_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'BUILD_FUNCTION_TYPE_ALIASES_ERRORS', AnalysisError.NO_ERRORS);

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
 * The [ClassElement]s of a [Source] representing a Dart library.
 *
 * The list contains the elements for all of the classes defined in the library,
 * not just those in the defining compilation unit. The list will be empty if
 * there are no classes, but will not be `null`.
 */
final ListResultDescriptor<ClassElement> CLASS_ELEMENTS =
    new ListResultDescriptor<ClassElement>('CLASS_ELEMENTS', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * A list of the [ConstantEvaluationTarget]s defined in a unit.  This includes
 * constants defined at top level, statically inside classes, and local to
 * functions, as well as constant constructors, annotations, and default values
 * of parameters to constant constructors.
 */
final ListResultDescriptor<ConstantEvaluationTarget> COMPILATION_UNIT_CONSTANTS =
    new ListResultDescriptor<ConstantEvaluationTarget>(
        'COMPILATION_UNIT_CONSTANTS', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

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
 * A [ConstantEvaluationTarget] that has been successfully constant-evaluated.
 *
 * TODO(paulberry): is ELEMENT_CACHING_POLICY the correct caching policy?
 */
final ResultDescriptor<ConstantEvaluationTarget> CONSTANT_VALUE =
    new ResultDescriptor<ConstantEvaluationTarget>('CONSTANT_VALUE', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The [ConstructorElement]s of a [ClassElement].
 */
final ListResultDescriptor<ConstructorElement> CONSTRUCTORS =
    new ListResultDescriptor<ConstructorElement>('CONSTRUCTORS', null);

/**
 * The errors produced while building a [ClassElement] constructors.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for targets representing a [ClassElement].
 */
final ListResultDescriptor<AnalysisError> CONSTRUCTORS_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'CONSTRUCTORS_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The sources representing the libraries that include a given source as a part.
 *
 * The result is only available for [Source]s representing a compilation unit.
 */
final ListResultDescriptor<Source> CONTAINING_LIBRARIES =
    new ListResultDescriptor<Source>('CONTAINING_LIBRARIES', Source.EMPTY_LIST);

/**
 * The [ResultCachingPolicy] for [Element]s.
 */
const ResultCachingPolicy ELEMENT_CACHING_POLICY =
    const SimpleResultCachingPolicy(-1, -1);

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
 * The sources representing the combined import/export closure of a library.
 * The [Source]s include only library sources, not their units.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<Source> IMPORT_EXPORT_SOURCE_CLOSURE =
    new ListResultDescriptor<Source>('IMPORT_EXPORT_SOURCE_CLOSURE', null);

/**
 * The sources representing the import closure of a library.
 * The [Source]s include only library sources, not their units.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<Source> IMPORT_SOURCE_CLOSURE =
    new ListResultDescriptor<Source>('IMPORT_SOURCE_CLOSURE', null);

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
 * In addition to [LIBRARY_ELEMENT1] [LibraryElement.imports] and
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
 * [LIBRARY_ELEMENT4] plus [RESOLVED_UNIT4] for every unit.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT5 =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT5', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The flag specifying whether all analysis errors are computed in a specific
 * library.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<bool> LIBRARY_ERRORS_READY =
    new ResultDescriptor<bool>('LIBRARY_ERRORS_READY', false);

/**
 * The analysis errors associated with a compilation unit in a specific library.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<AnalysisError> LIBRARY_UNIT_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'LIBRARY_UNIT_ERRORS', AnalysisError.NO_ERRORS);

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
 * The errors produced while resolving references.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ListResultDescriptor<AnalysisError> RESOLVE_REFERENCES_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'RESOLVE_REFERENCES_ERRORS', AnalysisError.NO_ERRORS);

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
 * The partially resolved [CompilationUnit] associated with a unit.
 *
 * All declarations bound to the element defined by the declaration.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT1 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT1', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a unit.
 *
 * All the enum member elements are built.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT2 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT2', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a unit.
 *
 * All the function type aliases are resolved.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT3 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT3', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a unit.
 *
 * [RESOLVED_UNIT3] with resolved type names.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT4 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT4', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The partially resolved [CompilationUnit] associated with a unit.
 *
 * [RESOLVED_UNIT4] plus resolved local variables and formal parameters.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT5 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT5', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The resolved [CompilationUnit] associated with a compilation unit, with
 * constants not yet resolved.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT6 =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT6', null,
        cachingPolicy: AST_CACHING_POLICY);

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
 * The [ResultCachingPolicy] for [TOKEN_STREAM].
 */
const ResultCachingPolicy TOKEN_STREAM_CACHING_POLICY =
    const SimpleResultCachingPolicy(1, 1);

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
        cachingPolicy: ELEMENT_CACHING_POLICY);

/**
 * The [UsedLocalElements] of a [LibrarySpecificUnit].
 */
final ResultDescriptor<UsedLocalElements> USED_LOCAL_ELEMENTS =
    new ResultDescriptor<UsedLocalElements>('USED_LOCAL_ELEMENTS', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);

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
 * A task that builds implicit constructors for a [ClassElement], or keeps
 * the existing explicit constructors if the class has them.
 */
class BuildClassConstructorsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [CONSTRUCTORS] input for the superclass.
   */
  static const String SUPER_CONSTRUCTORS = 'SUPER_CONSTRUCTORS';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildConstructorsForClassTask', createTask, buildInputs,
      <ResultDescriptor>[CONSTRUCTORS, CONSTRUCTORS_ERRORS]);

  BuildClassConstructorsTask(
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
    ClassElementImpl classElement = this.target;
    List<ConstructorElement> superConstructors = inputs[SUPER_CONSTRUCTORS];
    DartType superType = classElement.supertype;
    if (superType == null) {
      return;
    }
    //
    // Shortcut for ClassElement(s) without implicit constructors.
    //
    if (superConstructors == null) {
      outputs[CONSTRUCTORS] = classElement.constructors;
      outputs[CONSTRUCTORS_ERRORS] = AnalysisError.NO_ERRORS;
      return;
    }
    //
    // ClassTypeAlias
    //
    if (classElement.isMixinApplication) {
      List<ConstructorElement> implicitConstructors =
          new List<ConstructorElement>();
      void callback(ConstructorElement explicitConstructor,
          List<DartType> parameterTypes, List<DartType> argumentTypes) {
        implicitConstructors.add(_createImplicitContructor(classElement.type,
            explicitConstructor, parameterTypes, argumentTypes));
      }
      if (_findForwardedConstructors(classElement, superType, callback)) {
        if (implicitConstructors.isEmpty) {
          errors.add(new AnalysisError(classElement.source,
              classElement.nameOffset, classElement.name.length,
              CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS,
              [superType.element.name]));
        } else {
          classElement.constructors = implicitConstructors;
        }
      }
      outputs[CONSTRUCTORS] = classElement.constructors;
      outputs[CONSTRUCTORS_ERRORS] = errors;
    }
    //
    // ClassDeclaration
    //
    if (!classElement.isMixinApplication) {
      bool constructorFound = false;
      void callback(ConstructorElement explicitConstructor,
          List<DartType> parameterTypes, List<DartType> argumentTypes) {
        constructorFound = true;
      }
      if (_findForwardedConstructors(classElement, superType, callback) &&
          !constructorFound) {
        SourceRange withRange = classElement.withClauseRange;
        errors.add(new AnalysisError(classElement.source, withRange.offset,
            withRange.length, CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS,
            [superType.element.name]));
        classElement.mixinErrorsReported = true;
      }
      outputs[CONSTRUCTORS] = classElement.constructors;
      outputs[CONSTRUCTORS_ERRORS] = errors;
    }
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [classElement].
   */
  static Map<String, TaskInput> buildInputs(ClassElement classElement) {
    Source librarySource = classElement.library.source;
    DartType superType = classElement.supertype;
    if (superType is InterfaceType) {
      if (classElement.isMixinApplication || classElement.mixins.isNotEmpty) {
        ClassElement superElement = superType.element;
        return <String, TaskInput>{
          'libraryDep': LIBRARY_ELEMENT5.of(librarySource),
          SUPER_CONSTRUCTORS: CONSTRUCTORS.of(superElement)
        };
      }
    }
    // No implicit constructors.
    // Depend on LIBRARY_ELEMENT5 for invalidation.
    return <String, TaskInput>{
      'libraryDep': LIBRARY_ELEMENT5.of(librarySource)
    };
  }

  /**
   * Create a [BuildClassConstructorsTask] based on the given
   * [target] in the given [context].
   */
  static BuildClassConstructorsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildClassConstructorsTask(context, target);
  }

  /**
   * Create an implicit constructor that is copied from the given
   * [explicitConstructor], but that is in the given class.
   *
   * [classType] - the class in which the implicit constructor is defined.
   * [explicitConstructor] - the constructor on which the implicit constructor
   *    is modeled.
   * [parameterTypes] - the types to be replaced when creating parameters.
   * [argumentTypes] - the types with which the parameters are to be replaced.
   */
  static ConstructorElement _createImplicitContructor(InterfaceType classType,
      ConstructorElement explicitConstructor, List<DartType> parameterTypes,
      List<DartType> argumentTypes) {
    ConstructorElementImpl implicitConstructor =
        new ConstructorElementImpl(explicitConstructor.name, -1);
    implicitConstructor.synthetic = true;
    implicitConstructor.redirectedConstructor = explicitConstructor;
    implicitConstructor.const2 = explicitConstructor.isConst;
    implicitConstructor.returnType = classType;
    List<ParameterElement> explicitParameters = explicitConstructor.parameters;
    int count = explicitParameters.length;
    if (count > 0) {
      List<ParameterElement> implicitParameters =
          new List<ParameterElement>(count);
      for (int i = 0; i < count; i++) {
        ParameterElement explicitParameter = explicitParameters[i];
        ParameterElementImpl implicitParameter =
            new ParameterElementImpl(explicitParameter.name, -1);
        implicitParameter.const3 = explicitParameter.isConst;
        implicitParameter.final2 = explicitParameter.isFinal;
        implicitParameter.parameterKind = explicitParameter.parameterKind;
        implicitParameter.synthetic = true;
        implicitParameter.type =
            explicitParameter.type.substitute2(argumentTypes, parameterTypes);
        implicitParameters[i] = implicitParameter;
      }
      implicitConstructor.parameters = implicitParameters;
    }
    FunctionTypeImpl type = new FunctionTypeImpl(implicitConstructor);
    type.typeArguments = classType.typeArguments;
    implicitConstructor.type = type;
    return implicitConstructor;
  }

  /**
   * Find all the constructors that should be forwarded from the given
   * [superType], to the class or mixin application [classElement],
   * and pass information about them to [callback].
   *
   * Return `true` if some constructors were considered. (A `false` return value
   * can only happen if the supeclass is a built-in type, in which case it
   * can't be used as a mixin anyway).
   */
  static bool _findForwardedConstructors(ClassElementImpl classElement,
      InterfaceType superType, void callback(
          ConstructorElement explicitConstructor, List<DartType> parameterTypes,
          List<DartType> argumentTypes)) {
    if (superType == null) {
      return false;
    }
    ClassElement superclassElement = superType.element;
    List<ConstructorElement> constructors = superclassElement.constructors;
    int count = constructors.length;
    if (count == 0) {
      return false;
    }
    List<DartType> parameterTypes =
        TypeParameterTypeImpl.getTypes(superType.typeParameters);
    List<DartType> argumentTypes = _getArgumentTypes(superType, parameterTypes);
    for (int i = 0; i < count; i++) {
      ConstructorElement explicitConstructor = constructors[i];
      if (!explicitConstructor.isFactory &&
          classElement.isSuperConstructorAccessible(explicitConstructor)) {
        callback(explicitConstructor, parameterTypes, argumentTypes);
      }
    }
    return true;
  }

  /**
   * Return a list of argument types that corresponds to the [parameterTypes]
   * and that are derived from the type arguments of the given [superType].
   */
  static List<DartType> _getArgumentTypes(
      InterfaceType superType, List<DartType> parameterTypes) {
    DynamicTypeImpl dynamic = DynamicTypeImpl.instance;
    int parameterCount = parameterTypes.length;
    List<DartType> types = new List<DartType>(parameterCount);
    if (superType == null) {
      types = new List<DartType>.filled(parameterCount, dynamic);
    } else {
      List<DartType> typeArguments = superType.typeArguments;
      int argumentCount = math.min(typeArguments.length, parameterCount);
      for (int i = 0; i < argumentCount; i++) {
        types[i] = typeArguments[i];
      }
      for (int i = argumentCount; i < parameterCount; i++) {
        types[i] = dynamic;
      }
    }
    return types;
  }
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
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildCompilationUnitElementTask', createTask, buildInputs,
      <ResultDescriptor>[
    COMPILATION_UNIT_ELEMENT,
    RESOLVED_UNIT1,
    COMPILATION_UNIT_CONSTANTS
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
    //
    // Build or reuse CompilationUnitElement.
    //
    unit = AstCloner.clone(unit);
    AnalysisCache analysisCache =
        (context as InternalAnalysisContext).analysisCache;
    CompilationUnitElement element =
        analysisCache.getValue(target, COMPILATION_UNIT_ELEMENT);
    if (element == null) {
      CompilationUnitBuilder builder = new CompilationUnitBuilder();
      element = builder.buildCompilationUnit(
          source, unit, librarySpecificUnit.library);
    } else {
      new DeclarationResolver().resolve(unit, element);
    }
    //
    // Prepare constants.
    //
    ConstantFinder constantFinder =
        new ConstantFinder(context, source, librarySpecificUnit.library);
    unit.accept(constantFinder);
    List<ConstantEvaluationTarget> constants =
        new List<ConstantEvaluationTarget>.from(
            constantFinder.constantsToCompute);
    //
    // Record outputs.
    //
    outputs[COMPILATION_UNIT_ELEMENT] = element;
    outputs[RESOLVED_UNIT1] = unit;
    outputs[COMPILATION_UNIT_CONSTANTS] = constants;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit target) {
    return <String, TaskInput>{
      PARSED_UNIT_INPUT_NAME: PARSED_UNIT.of(target.unit)
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
      'BuildDirectiveElementsTask', createTask, buildInputs, <ResultDescriptor>[
    LIBRARY_ELEMENT2,
    BUILD_DIRECTIVES_ERRORS
  ]);

  BuildDirectiveElementsTask(
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
    LibraryElementImpl libraryElement = getRequiredInput(LIBRARY_INPUT);
    CompilationUnit libraryUnit = getRequiredInput(UNIT_INPUT_NAME);
    Map<Source, LibraryElement> importLibraryMap =
        getRequiredInput(IMPORTS_LIBRARY_ELEMENT_INPUT_NAME);
    Map<Source, LibraryElement> exportLibraryMap =
        getRequiredInput(EXPORTS_LIBRARY_ELEMENT_INPUT_NAME);
    Map<Source, SourceKind> importSourceKindMap =
        getRequiredInput(IMPORTS_SOURCE_KIND_INPUT_NAME);
    Map<Source, SourceKind> exportSourceKindMap =
        getRequiredInput(EXPORTS_SOURCE_KIND_INPUT_NAME);
    Source librarySource = libraryElement.source;
    //
    // Resolve directives.
    //
    HashMap<String, PrefixElementImpl> nameToPrefixMap =
        new HashMap<String, PrefixElementImpl>();
    List<ImportElement> imports = <ImportElement>[];
    List<ExportElement> exports = <ExportElement>[];
    bool explicitlyImportsCore = false;
    for (Directive directive in libraryUnit.directives) {
      if (directive is ImportDirective) {
        ImportDirective importDirective = directive;
        String uriContent = importDirective.uriContent;
        if (DartUriResolver.isDartExtUri(uriContent)) {
          libraryElement.hasExtUri = true;
        }
        Source importedSource = importDirective.source;
        if (importedSource != null && context.exists(importedSource)) {
          // The imported source will be null if the URI in the import
          // directive was invalid.
          LibraryElement importedLibrary = importLibraryMap[importedSource];
          if (importedLibrary != null) {
            ImportElementImpl importElement =
                new ImportElementImpl(directive.offset);
            StringLiteral uriLiteral = importDirective.uri;
            if (uriLiteral != null) {
              importElement.uriOffset = uriLiteral.offset;
              importElement.uriEnd = uriLiteral.end;
            }
            importElement.uri = uriContent;
            importElement.deferred = importDirective.deferredKeyword != null;
            importElement.combinators = _buildCombinators(importDirective);
            importElement.importedLibrary = importedLibrary;
            SimpleIdentifier prefixNode = directive.prefix;
            if (prefixNode != null) {
              importElement.prefixOffset = prefixNode.offset;
              String prefixName = prefixNode.name;
              PrefixElementImpl prefix = nameToPrefixMap[prefixName];
              if (prefix == null) {
                prefix = new PrefixElementImpl.forNode(prefixNode);
                nameToPrefixMap[prefixName] = prefix;
              }
              importElement.prefix = prefix;
              prefixNode.staticElement = prefix;
            }
            directive.element = importElement;
            imports.add(importElement);
            if (importSourceKindMap[importedSource] != SourceKind.LIBRARY) {
              ErrorCode errorCode = (importElement.isDeferred
                  ? StaticWarningCode.IMPORT_OF_NON_LIBRARY
                  : CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY);
              errors.add(new AnalysisError(importedSource, uriLiteral.offset,
                  uriLiteral.length, errorCode, [uriLiteral.toSource()]));
            }
          }
        }
      } else if (directive is ExportDirective) {
        ExportDirective exportDirective = directive;
        Source exportedSource = exportDirective.source;
        if (exportedSource != null && context.exists(exportedSource)) {
          // The exported source will be null if the URI in the export
          // directive was invalid.
          LibraryElement exportedLibrary = exportLibraryMap[exportedSource];
          if (exportedLibrary != null) {
            ExportElementImpl exportElement =
                new ExportElementImpl(directive.offset);
            StringLiteral uriLiteral = exportDirective.uri;
            if (uriLiteral != null) {
              exportElement.uriOffset = uriLiteral.offset;
              exportElement.uriEnd = uriLiteral.end;
            }
            exportElement.uri = exportDirective.uriContent;
            exportElement.combinators = _buildCombinators(exportDirective);
            exportElement.exportedLibrary = exportedLibrary;
            directive.element = exportElement;
            exports.add(exportElement);
            if (exportSourceKindMap[exportedSource] != SourceKind.LIBRARY) {
              errors.add(new AnalysisError(exportedSource, uriLiteral.offset,
                  uriLiteral.length, CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
                  [uriLiteral.toSource()]));
            }
          }
        }
      }
    }
    //
    // Ensure "dart:core" import.
    //
    Source coreLibrarySource = context.sourceFactory.forUri(DartSdk.DART_CORE);
    if (!explicitlyImportsCore && coreLibrarySource != librarySource) {
      ImportElementImpl importElement = new ImportElementImpl(-1);
      importElement.importedLibrary = importLibraryMap[coreLibrarySource];
      importElement.synthetic = true;
      imports.add(importElement);
    }
    //
    // Populate the library element.
    //
    libraryElement.imports = imports;
    libraryElement.exports = exports;
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
  static Map<String, TaskInput> buildInputs(Source libSource) {
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT1.of(libSource),
      UNIT_INPUT_NAME:
          RESOLVED_UNIT1.of(new LibrarySpecificUnit(libSource, libSource)),
      IMPORTS_LIBRARY_ELEMENT_INPUT_NAME:
          IMPORTED_LIBRARIES.of(libSource).toMapOf(LIBRARY_ELEMENT1),
      EXPORTS_LIBRARY_ELEMENT_INPUT_NAME:
          EXPORTED_LIBRARIES.of(libSource).toMapOf(LIBRARY_ELEMENT1),
      IMPORTS_SOURCE_KIND_INPUT_NAME:
          IMPORTED_LIBRARIES.of(libSource).toMapOf(SOURCE_KIND),
      EXPORTS_SOURCE_KIND_INPUT_NAME:
          EXPORTED_LIBRARIES.of(libSource).toMapOf(SOURCE_KIND)
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

  /**
   * Build the element model representing the combinators declared by
   * the given [directive].
   */
  static List<NamespaceCombinator> _buildCombinators(
      NamespaceDirective directive) {
    List<NamespaceCombinator> combinators = <NamespaceCombinator>[];
    for (Combinator combinator in directive.combinators) {
      if (combinator is ShowCombinator) {
        ShowElementCombinatorImpl show = new ShowElementCombinatorImpl();
        show.offset = combinator.offset;
        show.end = combinator.end;
        show.shownNames = _getIdentifiers(combinator.shownNames);
        combinators.add(show);
      } else if (combinator is HideCombinator) {
        HideElementCombinatorImpl hide = new HideElementCombinatorImpl();
        hide.hiddenNames = _getIdentifiers(combinator.hiddenNames);
        combinators.add(hide);
      }
    }
    return combinators;
  }

  /**
   * Return the lexical identifiers associated with the given [identifiers].
   */
  static List<String> _getIdentifiers(NodeList<SimpleIdentifier> identifiers) {
    return identifiers.map((identifier) => identifier.name).toList();
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
      'BuildEnumMemberElementsTask', createTask, buildInputs,
      <ResultDescriptor>[RESOLVED_UNIT2]);

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
    // Record outputs.
    //
    EnumMemberBuilder builder = new EnumMemberBuilder(typeProvider);
    unit.accept(builder);
    outputs[RESOLVED_UNIT2] = unit;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit target) {
    return <String, TaskInput>{
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request),
      UNIT_INPUT: RESOLVED_UNIT1.of(target)
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
      'BuildExportNamespaceTask', createTask, buildInputs,
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
    ExportNamespaceBuilder builder = new ExportNamespaceBuilder();
    Namespace namespace = builder.build(library);
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
  static Map<String, TaskInput> buildInputs(Source libSource) {
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT3.of(libSource),
      'exportsLibraryPublicNamespace':
          EXPORT_SOURCE_CLOSURE.of(libSource).toMapOf(LIBRARY_ELEMENT3)
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
 * A task that builds [RESOLVED_UNIT3] for a unit.
 */
class BuildFunctionTypeAliasesTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The name of the [LIBRARY_ELEMENT4] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The name of the [RESOLVED_UNIT2] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildFunctionTypeAliasesTask', createTask, buildInputs,
      <ResultDescriptor>[BUILD_FUNCTION_TYPE_ALIASES_ERRORS, RESOLVED_UNIT3]);

  BuildFunctionTypeAliasesTask(
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
    Source source = getRequiredSource();
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    LibraryElement libraryElement = getRequiredInput(LIBRARY_INPUT);
    //
    // Resolve FunctionTypeAlias declarations.
    //
    TypeResolverVisitor visitor = new TypeResolverVisitor.con2(
        libraryElement, source, typeProvider, errorListener);
    for (CompilationUnitMember member in unit.declarations) {
      if (member is FunctionTypeAlias) {
        member.accept(visitor);
      }
    }
    //
    // Record outputs.
    //
    outputs[BUILD_FUNCTION_TYPE_ALIASES_ERRORS] = errorListener.errors;
    outputs[RESOLVED_UNIT3] = unit;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit target) {
    return <String, TaskInput>{
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request),
      'importsExportNamespace':
          IMPORTED_LIBRARIES.of(target.library).toMapOf(LIBRARY_ELEMENT4),
      LIBRARY_INPUT: LIBRARY_ELEMENT4.of(target.library),
      UNIT_INPUT: RESOLVED_UNIT2.of(target)
    };
  }

  /**
   * Create a [BuildFunctionTypeAliasesTask] based on the given [target] in
   * the given [context].
   */
  static BuildFunctionTypeAliasesTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildFunctionTypeAliasesTask(context, target);
  }
}

/**
 * This task finishes building [LIBRARY_ELEMENT] by forcing building
 * constructors for classes in the defining and part units of a library.
 */
class BuildLibraryConstructorsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT5] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildLibraryConstructorsTask', createTask, buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT]);

  BuildLibraryConstructorsTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibraryElement library = getRequiredInput(LIBRARY_INPUT);
    outputs[LIBRARY_ELEMENT] = library;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(Source libSource) {
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT5.of(libSource),
      'resolvedConstructors':
          CLASS_ELEMENTS.of(libSource).toListOf(CONSTRUCTORS),
    };
  }

  /**
   * Create a [BuildLibraryConstructorsTask] based on the given [target] in
   * the given [context].
   */
  static BuildLibraryConstructorsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildLibraryConstructorsTask(context, target);
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
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildLibraryElementTask', createTask, buildInputs, <ResultDescriptor>[
    BUILD_LIBRARY_ERRORS,
    CLASS_ELEMENTS,
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
    //
    // Process inputs.
    //
    CompilationUnitElementImpl definingCompilationUnitElement =
        definingCompilationUnit.element;
    Map<Source, CompilationUnit> partUnitMap =
        new HashMap<Source, CompilationUnit>();
    for (CompilationUnit partUnit in partUnits) {
      Source partSource = partUnit.element.source;
      partUnitMap[partSource] = partUnit;
    }
    //
    // Update "part" directives.
    //
    LibraryIdentifier libraryNameNode = null;
    String partsLibraryName = _UNKNOWN_LIBRARY_NAME;
    bool hasPartDirective = false;
    FunctionElement entryPoint =
        _findEntryPoint(definingCompilationUnitElement);
    List<Directive> directivesToResolve = <Directive>[];
    List<CompilationUnitElementImpl> sourcedCompilationUnits =
        <CompilationUnitElementImpl>[];
    for (Directive directive in definingCompilationUnit.directives) {
      if (directive is LibraryDirective) {
        if (libraryNameNode == null) {
          libraryNameNode = directive.name;
          directivesToResolve.add(directive);
        }
      } else if (directive is PartDirective) {
        PartDirective partDirective = directive;
        StringLiteral partUri = partDirective.uri;
        Source partSource = partDirective.source;
        hasPartDirective = true;
        CompilationUnit partUnit = partUnitMap[partSource];
        if (partUnit != null) {
          CompilationUnitElementImpl partElement = partUnit.element;
          partElement.uriOffset = partUri.offset;
          partElement.uriEnd = partUri.end;
          partElement.uri = partDirective.uriContent;
          //
          // Validate that the part contains a part-of directive with the same
          // name as the library.
          //
          if (context.exists(partSource)) {
            String partLibraryName =
                _getPartLibraryName(partSource, partUnit, directivesToResolve);
            if (partLibraryName == null) {
              errors.add(new AnalysisError(librarySource, partUri.offset,
                  partUri.length, CompileTimeErrorCode.PART_OF_NON_PART,
                  [partUri.toSource()]));
            } else if (libraryNameNode == null) {
              if (partsLibraryName == _UNKNOWN_LIBRARY_NAME) {
                partsLibraryName = partLibraryName;
              } else if (partsLibraryName != partLibraryName) {
                partsLibraryName = null;
              }
            } else if (libraryNameNode.name != partLibraryName) {
              errors.add(new AnalysisError(librarySource, partUri.offset,
                  partUri.length, StaticWarningCode.PART_OF_DIFFERENT_LIBRARY, [
                libraryNameNode.name,
                partLibraryName
              ]));
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
    if (hasPartDirective && libraryNameNode == null) {
      AnalysisError error;
      if (partsLibraryName != _UNKNOWN_LIBRARY_NAME &&
          partsLibraryName != null) {
        error = new AnalysisErrorWithProperties(librarySource, 0, 0,
            ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART)
          ..setProperty(ErrorProperty.PARTS_LIBRARY_NAME, partsLibraryName);
      } else {
        error = new AnalysisError(librarySource, 0, 0,
            ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART);
      }
      errors.add(error);
    }
    //
    // Create and populate the library element.
    //
    LibraryElementImpl libraryElement =
        new LibraryElementImpl.forNode(context, libraryNameNode);
    libraryElement.definingCompilationUnit = definingCompilationUnitElement;
    libraryElement.entryPoint = entryPoint;
    libraryElement.parts = sourcedCompilationUnits;
    for (Directive directive in directivesToResolve) {
      directive.element = libraryElement;
    }
    if (sourcedCompilationUnits.isNotEmpty) {
      _patchTopLevelAccessors(libraryElement);
    }
    //
    // Prepare all class elements.
    //
    List<ClassElement> classElements = libraryElement.units
        .map((CompilationUnitElement unitElement) => unitElement.types)
        .expand((List<ClassElement> unitClassElements) => unitClassElements)
        .toList();
    //
    // Record outputs.
    //
    outputs[BUILD_LIBRARY_ERRORS] = errors;
    outputs[CLASS_ELEMENTS] = classElements;
    outputs[LIBRARY_ELEMENT1] = libraryElement;
    outputs[IS_LAUNCHABLE] = entryPoint != null;
  }

  /**
   * Add all of the non-synthetic [getters] and [setters] defined in the given
   * [unit] that have no corresponding accessor to one of the given collections.
   */
  void _collectAccessors(Map<String, PropertyAccessorElement> getters,
      List<PropertyAccessorElement> setters, CompilationUnitElement unit) {
    for (PropertyAccessorElement accessor in unit.accessors) {
      if (accessor.isGetter) {
        if (!accessor.isSynthetic && accessor.correspondingSetter == null) {
          getters[accessor.displayName] = accessor;
        }
      } else {
        if (!accessor.isSynthetic && accessor.correspondingGetter == null) {
          setters.add(accessor);
        }
      }
    }
  }

  /**
   * Return the top-level [FunctionElement] entry point, or `null` if the given
   * [element] does not define an entry point.
   */
  FunctionElement _findEntryPoint(CompilationUnitElementImpl element) {
    for (FunctionElement function in element.functions) {
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
  String _getPartLibraryName(Source partSource, CompilationUnit partUnit,
      List<Directive> directivesToResolve) {
    for (Directive directive in partUnit.directives) {
      if (directive is PartOfDirective) {
        directivesToResolve.add(directive);
        LibraryIdentifier libraryName = directive.libraryName;
        if (libraryName != null) {
          return libraryName.name;
        }
      }
    }
    return null;
  }

  /**
   * Look through all of the compilation units defined for the given [library],
   * looking for getters and setters that are defined in different compilation
   * units but that have the same names. If any are found, make sure that they
   * have the same variable element.
   */
  void _patchTopLevelAccessors(LibraryElementImpl library) {
    HashMap<String, PropertyAccessorElement> getters =
        new HashMap<String, PropertyAccessorElement>();
    List<PropertyAccessorElement> setters = <PropertyAccessorElement>[];
    _collectAccessors(getters, setters, library.definingCompilationUnit);
    for (CompilationUnitElement unit in library.parts) {
      _collectAccessors(getters, setters, unit);
    }
    for (PropertyAccessorElement setter in setters) {
      PropertyAccessorElement getter = getters[setter.displayName];
      if (getter != null) {
        TopLevelVariableElementImpl variable = getter.variable;
        TopLevelVariableElementImpl setterVariable = setter.variable;
        CompilationUnitElementImpl setterUnit = setterVariable.enclosingElement;
        setterUnit.replaceTopLevelVariable(setterVariable, variable);
        variable.setter = setter;
        (setter as PropertyAccessorElementImpl).variable = variable;
      }
    }
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [libSource].
   */
  static Map<String, TaskInput> buildInputs(Source libSource) {
    return <String, TaskInput>{
      DEFINING_UNIT_INPUT:
          RESOLVED_UNIT1.of(new LibrarySpecificUnit(libSource, libSource)),
      PARTS_UNIT_INPUT: INCLUDED_PARTS.of(libSource).toList((Source unit) {
        return RESOLVED_UNIT1.of(new LibrarySpecificUnit(libSource, unit));
      })
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
      'BuildPublicNamespaceTask', createTask, buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT3]);

  BuildPublicNamespaceTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibraryElementImpl library = getRequiredInput(LIBRARY_INPUT);
    library.publicNamespace = new PublicNamespaceBuilder().build(library);
    outputs[LIBRARY_ELEMENT3] = library;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given library [libSource].
   */
  static Map<String, TaskInput> buildInputs(Source libSource) {
    return <String, TaskInput>{LIBRARY_INPUT: LIBRARY_ELEMENT2.of(libSource)};
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
 * A task that builds [IMPORT_SOURCE_CLOSURE] and [EXPORT_SOURCE_CLOSURE] of
 * a library.
 */
class BuildSourceClosuresTask extends SourceBasedAnalysisTask {
  /**
   * The name of the import closure.
   */
  static const String IMPORT_INPUT = 'IMPORT_INPUT';

  /**
   * The name of the export closure.
   */
  static const String EXPORT_INPUT = 'EXPORT_INPUT';

  /**
   * The name of the import/export closure.
   */
  static const String IMPORT_EXPORT_INPUT = 'IMPORT_EXPORT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'BuildSourceClosuresTask', createTask, buildInputs, <ResultDescriptor>[
    IMPORT_SOURCE_CLOSURE,
    EXPORT_SOURCE_CLOSURE,
    IMPORT_EXPORT_SOURCE_CLOSURE,
    IS_CLIENT
  ]);

  BuildSourceClosuresTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    List<Source> importClosure = getRequiredInput(IMPORT_INPUT);
    List<Source> exportClosure = getRequiredInput(EXPORT_INPUT);
    List<Source> importExportClosure = getRequiredInput(IMPORT_EXPORT_INPUT);
    Source htmlSource = context.sourceFactory.forUri(DartSdk.DART_HTML);
    //
    // Record outputs.
    //
    outputs[IMPORT_SOURCE_CLOSURE] = importClosure;
    outputs[EXPORT_SOURCE_CLOSURE] = exportClosure;
    outputs[IMPORT_EXPORT_SOURCE_CLOSURE] = importExportClosure;
    outputs[IS_CLIENT] = importExportClosure.contains(htmlSource);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given library [libSource].
   */
  static Map<String, TaskInput> buildInputs(Source libSource) {
    return <String, TaskInput>{
      IMPORT_INPUT: new _ImportSourceClosureTaskInput(libSource),
      EXPORT_INPUT: new _ExportSourceClosureTaskInput(libSource),
      IMPORT_EXPORT_INPUT: new _ImportExportSourceClosureTaskInput(libSource)
    };
  }

  /**
   * Create a [BuildSourceClosuresTask] based on the given [target] in
   * the given [context].
   */
  static BuildSourceClosuresTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new BuildSourceClosuresTask(context, target);
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
      'BuildTypeProviderTask', createTask, buildInputs,
      <ResultDescriptor>[TYPE_PROVIDER]);

  BuildTypeProviderTask(
      InternalAnalysisContext context, AnalysisContextTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibraryElement coreLibrary = getRequiredInput(CORE_INPUT);
    LibraryElement asyncLibrary = getRequiredInput(ASYNC_INPUT);
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

  static Map<String, TaskInput> buildInputs(AnalysisContextTarget target) {
    SourceFactory sourceFactory = target.context.sourceFactory;
    Source coreSource = sourceFactory.forUri(DartSdk.DART_CORE);
    Source asyncSource = sourceFactory.forUri(DartSdk.DART_ASYNC);
    return <String, TaskInput>{
      CORE_INPUT: LIBRARY_ELEMENT3.of(coreSource),
      ASYNC_INPUT: LIBRARY_ELEMENT3.of(asyncSource)
    };
  }

  /**
   * Create a [BuildTypeProviderTask] based on the given [context].
   */
  static BuildTypeProviderTask createTask(
      AnalysisContext context, AnalysisContextTarget target) {
    return new BuildTypeProviderTask(context, target);
  }
}

/**
 * A task that computes [CONSTANT_DEPENDENCIES] for a constant.
 */
class ComputeConstantDependenciesTask extends ConstantEvaluationAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT6] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ComputeConstantDependenciesTask', createTask, buildInputs,
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
    // Note: UNIT_INPUT is not needed.  It is merely a bookkeeping dependency
    // to ensure that resolution has occurred before we attempt to determine
    // constant dependencies.
    //
    ConstantEvaluationTarget constant = target;
    AnalysisContext context = constant.context;
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Compute dependencies.
    //
    List<ConstantEvaluationTarget> dependencies = <ConstantEvaluationTarget>[];
    new ConstantEvaluationEngine(typeProvider, context.declaredVariables)
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
  static Map<String, TaskInput> buildInputs(ConstantEvaluationTarget target) {
    if (target is Element) {
      CompilationUnitElementImpl unit = (target as Element)
          .getAncestor((Element element) => element is CompilationUnitElement);
      return <String, TaskInput>{
        UNIT_INPUT: RESOLVED_UNIT6
            .of(new LibrarySpecificUnit(unit.librarySource, target.source)),
        TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request)
      };
    } else if (target is ConstantEvaluationTarget_Annotation) {
      return <String, TaskInput>{
        UNIT_INPUT: RESOLVED_UNIT6
            .of(new LibrarySpecificUnit(target.librarySource, target.source)),
        TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request)
      };
    } else {
      // Should never happen.
      assert(false);
      return <String, TaskInput>{};
    }
  }

  /**
   * Create a [ResolveReferencesTask] based on the given [target] in
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
      'ComputeConstantValueTask', createTask, buildInputs,
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
        new ConstantEvaluationEngine(typeProvider, context.declaredVariables);
    if (dependencyCycle == null) {
      constantEvaluationEngine.computeConstantValue(constant);
    } else {
      List<ConstantEvaluationTarget> constantsInCycle =
          <ConstantEvaluationTarget>[];
      for (WorkItem workItem in dependencyCycle) {
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
  static Map<String, TaskInput> buildInputs(ConstantEvaluationTarget target) {
    return <String, TaskInput>{
      DEPENDENCIES_INPUT:
          CONSTANT_DEPENDENCIES.of(target).toListOf(CONSTANT_VALUE),
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
      'ContainingLibrariesTask', createTask, buildInputs,
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
  static Map<String, TaskInput> buildInputs(Source target) {
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
   * The name of the [BUILD_DIRECTIVES_ERRORS] input.
   */
  static const String BUILD_DIRECTIVES_ERRORS_INPUT = 'BUILD_DIRECTIVES_ERRORS';

  /**
   * The name of the [BUILD_LIBRARY_ERRORS] input.
   */
  static const String BUILD_LIBRARY_ERRORS_INPUT = 'BUILD_LIBRARY_ERRORS';

  /**
   * The name of the [LIBRARY_UNIT_ERRORS] input.
   */
  static const String LIBRARY_UNIT_ERRORS_INPUT = 'LIBRARY_UNIT_ERRORS';

  /**
   * The name of the [PARSE_ERRORS] input.
   */
  static const String PARSE_ERRORS_INPUT = 'PARSE_ERRORS';

  /**
   * The name of the [SCAN_ERRORS] input.
   */
  static const String SCAN_ERRORS_INPUT = 'SCAN_ERRORS';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor('DartErrorsTask',
      createTask, buildInputs, <ResultDescriptor>[DART_ERRORS]);

  DartErrorsTask(InternalAnalysisContext context, AnalysisTarget target)
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
    errorLists.add(getRequiredInput(PARSE_ERRORS_INPUT));
    errorLists.add(getRequiredInput(SCAN_ERRORS_INPUT));
    Map<Source, List<AnalysisError>> unitErrors =
        getRequiredInput(LIBRARY_UNIT_ERRORS_INPUT);
    for (List<AnalysisError> errors in unitErrors.values) {
      errorLists.add(errors);
    }
    //
    // Record outputs.
    //
    outputs[DART_ERRORS] = AnalysisError.mergeLists(errorLists);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(Source target) {
    return <String, TaskInput>{
      BUILD_DIRECTIVES_ERRORS_INPUT: BUILD_DIRECTIVES_ERRORS.of(target),
      BUILD_LIBRARY_ERRORS_INPUT: BUILD_LIBRARY_ERRORS.of(target),
      PARSE_ERRORS_INPUT: PARSE_ERRORS.of(target),
      SCAN_ERRORS_INPUT: SCAN_ERRORS.of(target),
      LIBRARY_UNIT_ERRORS_INPUT: CONTAINING_LIBRARIES
          .of(target)
          .toMap((Source library) {
        LibrarySpecificUnit unit = new LibrarySpecificUnit(library, target);
        return LIBRARY_UNIT_ERRORS.of(unit);
      })
    };
  }

  /**
   * Create a [DartErrorsTask] based on the given [target] in the given
   * [context].
   */
  static DartErrorsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new DartErrorsTask(context, target);
  }
}

/**
 * A task that builds [RESOLVED_UNIT] for a unit.
 */
class EvaluateUnitConstantsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT6] input.
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
      'EvaluateUnitConstantsTask', createTask, buildInputs,
      <ResultDescriptor>[RESOLVED_UNIT]);

  EvaluateUnitConstantsTask(AnalysisContext context, LibrarySpecificUnit target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    // No actual work needs to be performed; the task manager will ensure that
    // all constants are evaluated before this method is called.
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    outputs[RESOLVED_UNIT] = unit;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit target) {
    return <String, TaskInput>{
      UNIT_INPUT: RESOLVED_UNIT6.of(target),
      CONSTANT_VALUES:
          COMPILATION_UNIT_CONSTANTS.of(target).toListOf(CONSTANT_VALUE)
    };
  }

  /**
   * Create an [EvaluateUnitConstantsTask] based on the given [target] in
   * the given [context].
   */
  static EvaluateUnitConstantsTask createTask(
      AnalysisContext context, LibrarySpecificUnit target) {
    return new EvaluateUnitConstantsTask(context, target);
  }
}

/**
 * The helper for building the export [Namespace] of a [LibraryElement].
 */
class ExportNamespaceBuilder {
  /**
   * Build the export [Namespace] of the given [LibraryElement].
   */
  Namespace build(LibraryElement library) {
    return new Namespace(
        _createExportMapping(library, new HashSet<LibraryElement>()));
  }

  /**
   * Create a mapping table representing the export namespace of the given
   * [library].
   *
   * The given [visitedElements] a set of libraries that do not need to be
   * visited when processing the export directives of the given library because
   * all of the names defined by them will be added by another library.
   */
  HashMap<String, Element> _createExportMapping(
      LibraryElement library, HashSet<LibraryElement> visitedElements) {
    visitedElements.add(library);
    try {
      HashMap<String, Element> definedNames = new HashMap<String, Element>();
      // Add names of the export directives.
      for (ExportElement element in library.exports) {
        LibraryElement exportedLibrary = element.exportedLibrary;
        if (exportedLibrary != null &&
            !visitedElements.contains(exportedLibrary)) {
          //
          // The exported library will be null if the URI does not reference a
          // valid library.
          //
          HashMap<String, Element> exportedNames =
              _createExportMapping(exportedLibrary, visitedElements);
          exportedNames = _applyCombinators(exportedNames, element.combinators);
          definedNames.addAll(exportedNames);
        }
      }
      // Add names of the public namespace.
      {
        Namespace publicNamespace = library.publicNamespace;
        if (publicNamespace != null) {
          definedNames.addAll(publicNamespace.definedNames);
        }
      }
      return definedNames;
    } finally {
      visitedElements.remove(library);
    }
  }

  /**
   * Apply the given [combinators] to all of the names in [definedNames].
   */
  static HashMap<String, Element> _applyCombinators(
      HashMap<String, Element> definedNames,
      List<NamespaceCombinator> combinators) {
    for (NamespaceCombinator combinator in combinators) {
      if (combinator is HideElementCombinator) {
        _hide(definedNames, combinator.hiddenNames);
      } else if (combinator is ShowElementCombinator) {
        definedNames = _show(definedNames, combinator.shownNames);
      }
    }
    return definedNames;
  }

  /**
   * Hide all of the [hiddenNames] by removing them from the given
   * [definedNames].
   */
  static void _hide(
      HashMap<String, Element> definedNames, List<String> hiddenNames) {
    for (String name in hiddenNames) {
      definedNames.remove(name);
      definedNames.remove('$name=');
    }
  }

  /**
   * Show only the given [shownNames] by removing all other names from the given
   * [definedNames].
   */
  static HashMap<String, Element> _show(
      HashMap<String, Element> definedNames, List<String> shownNames) {
    HashMap<String, Element> newNames = new HashMap<String, Element>();
    for (String name in shownNames) {
      Element element = definedNames[name];
      if (element != null) {
        newNames[name] = element;
      }
      String setterName = '$name=';
      element = definedNames[setterName];
      if (element != null) {
        newNames[setterName] = element;
      }
    }
    return newNames;
  }
}

/**
 * A task that builds [USED_IMPORTED_ELEMENTS] for a unit.
 */
class GatherUsedImportedElementsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT6] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'GatherUsedImportedElementsTask', createTask, buildInputs,
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
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit target) {
    return <String, TaskInput>{UNIT_INPUT: RESOLVED_UNIT6.of(target)};
  }

  /**
   * Create a [GatherUsedImportedElementsTask] based on the given [target] in
   * the given [context].
   */
  static GatherUsedImportedElementsTask createTask(
      AnalysisContext context, LibrarySpecificUnit target) {
    return new GatherUsedImportedElementsTask(context, target);
  }
}

/**
 * A task that builds [USED_LOCAL_ELEMENTS] for a unit.
 */
class GatherUsedLocalElementsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT6] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'GatherUsedLocalElementsTask', createTask, buildInputs,
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
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit target) {
    return <String, TaskInput>{UNIT_INPUT: RESOLVED_UNIT6.of(target)};
  }

  /**
   * Create a [GatherUsedLocalElementsTask] based on the given [target] in
   * the given [context].
   */
  static GatherUsedLocalElementsTask createTask(
      AnalysisContext context, LibrarySpecificUnit target) {
    return new GatherUsedLocalElementsTask(context, target);
  }
}

/**
 * A task that generates [HINTS] for a unit.
 */
class GenerateHintsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT6] input.
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
    //
    // Generate errors.
    //
    unit.accept(new DeadCodeVerifier(errorReporter));
    // Verify imports.
    {
      ImportsVerifier verifier = new ImportsVerifier();
      verifier.addImports(unit);
      usedImportedElementsList.forEach(verifier.removeUsedElements);
      verifier.generateDuplicateImportHints(errorReporter);
      verifier.generateUnusedImportHints(errorReporter);
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
    if (context.analysisOptions.dart2jsHint) {
      unit.accept(new Dart2JSVerifier(errorReporter));
    }
    // Dart best practices.
    InheritanceManager inheritanceManager =
        new InheritanceManager(libraryElement);
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    unit.accept(new BestPracticesVerifier(errorReporter, typeProvider));
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
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit target) {
    Source libSource = target.library;
    return <String, TaskInput>{
      RESOLVED_UNIT_INPUT: RESOLVED_UNIT.of(target),
      USED_LOCAL_ELEMENTS_INPUT: UNITS.of(libSource).toList((unit) {
        LibrarySpecificUnit target = new LibrarySpecificUnit(libSource, unit);
        return USED_LOCAL_ELEMENTS.of(target);
      }),
      USED_IMPORTED_ELEMENTS_INPUT: UNITS.of(libSource).toList((unit) {
        LibrarySpecificUnit target = new LibrarySpecificUnit(libSource, unit);
        return USED_IMPORTED_ELEMENTS.of(target);
      }),
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
 * A task computes all of the errors of all of the units for a single
 * library source and sets the [LIBRARY_ERRORS_READY] flag.
 */
class LibraryErrorsReadyTask extends SourceBasedAnalysisTask {
  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'LibraryErrorsReadyTask', createTask, buildInputs,
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
   * given [library].
   */
  static Map<String, TaskInput> buildInputs(Source library) {
    return <String, TaskInput>{
      'allErrors': UNITS.of(library).toListOf(DART_ERRORS)
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
   * The name of the [BUILD_FUNCTION_TYPE_ALIASES_ERRORS] input.
   */
  static const String BUILD_FUNCTION_TYPE_ALIASES_ERRORS_INPUT =
      'BUILD_FUNCTION_TYPE_ALIASES_ERRORS';

  /**
   * The name of the [HINTS] input.
   */
  static const String HINTS_INPUT = 'HINTS';

  /**
   * The name of the [RESOLVE_REFERENCES_ERRORS] input.
   */
  static const String RESOLVE_REFERENCES_ERRORS_INPUT =
      'RESOLVE_REFERENCES_ERRORS';

  /**
   * The name of the [RESOLVE_TYPE_NAMES_ERRORS] input.
   */
  static const String RESOLVE_TYPE_NAMES_ERRORS_INPUT =
      'RESOLVE_TYPE_NAMES_ERRORS';

  /**
   * The name of the [VERIFY_ERRORS] input.
   */
  static const String VERIFY_ERRORS_INPUT = 'VERIFY_ERRORS';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'LibraryUnitErrorsTask', createTask, buildInputs,
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
    errorLists.add(getRequiredInput(BUILD_FUNCTION_TYPE_ALIASES_ERRORS_INPUT));
    errorLists.add(getRequiredInput(HINTS_INPUT));
    errorLists.add(getRequiredInput(RESOLVE_REFERENCES_ERRORS_INPUT));
    errorLists.add(getRequiredInput(RESOLVE_TYPE_NAMES_ERRORS_INPUT));
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
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit unit) {
    return <String, TaskInput>{
      BUILD_FUNCTION_TYPE_ALIASES_ERRORS_INPUT:
          BUILD_FUNCTION_TYPE_ALIASES_ERRORS.of(unit),
      HINTS_INPUT: HINTS.of(unit),
      RESOLVE_REFERENCES_ERRORS_INPUT: RESOLVE_REFERENCES_ERRORS.of(unit),
      RESOLVE_TYPE_NAMES_ERRORS_INPUT: RESOLVE_TYPE_NAMES_ERRORS.of(unit),
      VERIFY_ERRORS_INPUT: VERIFY_ERRORS.of(unit)
    };
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
 * A task that parses the content of a Dart file, producing an AST structure.
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
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor('ParseDartTask',
      createTask, buildInputs, <ResultDescriptor>[
    EXPLICITLY_IMPORTED_LIBRARIES,
    EXPORTED_LIBRARIES,
    IMPORTED_LIBRARIES,
    INCLUDED_PARTS,
    PARSE_ERRORS,
    PARSED_UNIT,
    SOURCE_KIND,
    UNITS
  ]);

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
    Source source = getRequiredSource();
    LineInfo lineInfo = getRequiredInput(LINE_INFO_INPUT_NAME);
    int modificationTime = getRequiredInput(MODIFICATION_TIME_INPUT_NAME);
    Token tokenStream = getRequiredInput(TOKEN_STREAM_INPUT_NAME);

    RecordingErrorListener errorListener = new RecordingErrorListener();
    Parser parser = new Parser(source, errorListener);
    AnalysisOptions options = context.analysisOptions;
    parser.parseFunctionBodies = options.analyzeFunctionBodiesPredicate(source);
    CompilationUnit unit = parser.parseCompilationUnit(tokenStream);
    unit.lineInfo = lineInfo;

    bool hasNonPartOfDirective = false;
    bool hasPartOfDirective = false;
    HashSet<Source> explicitlyImportedSourceSet = new HashSet<Source>();
    HashSet<Source> exportedSourceSet = new HashSet<Source>();
    HashSet<Source> includedSourceSet = new HashSet<Source>();
    for (Directive directive in unit.directives) {
      if (directive is PartOfDirective) {
        hasPartOfDirective = true;
      } else {
        hasNonPartOfDirective = true;
        if (directive is UriBasedDirective) {
          Source referencedSource =
              resolveDirective(context, source, directive, errorListener);
          if (referencedSource != null) {
            if (directive is ExportDirective) {
              exportedSourceSet.add(referencedSource);
            } else if (directive is ImportDirective) {
              explicitlyImportedSourceSet.add(referencedSource);
            } else if (directive is PartDirective) {
              if (referencedSource != source) {
                includedSourceSet.add(referencedSource);
              }
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
    // Record outputs.
    //
    List<Source> explicitlyImportedSources =
        explicitlyImportedSourceSet.toList();
    List<Source> exportedSources = exportedSourceSet.toList();
    List<Source> importedSources = importedSourceSet.toList();
    List<Source> includedSources = includedSourceSet.toList();
    List<AnalysisError> parseErrors = errorListener.errors;
    List<Source> unitSources = <Source>[source]..addAll(includedSourceSet);
    outputs[EXPLICITLY_IMPORTED_LIBRARIES] = explicitlyImportedSources;
    outputs[EXPORTED_LIBRARIES] = exportedSources;
    outputs[IMPORTED_LIBRARIES] = importedSources;
    outputs[INCLUDED_PARTS] = includedSources;
    outputs[PARSE_ERRORS] = parseErrors;
    outputs[PARSED_UNIT] = unit;
    outputs[SOURCE_KIND] = sourceKind;
    outputs[UNITS] = unitSources;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [source].
   */
  static Map<String, TaskInput> buildInputs(Source source) {
    return <String, TaskInput>{
      LINE_INFO_INPUT_NAME: LINE_INFO.of(source),
      MODIFICATION_TIME_INPUT_NAME: MODIFICATION_TIME.of(source),
      TOKEN_STREAM_INPUT_NAME: TOKEN_STREAM.of(source)
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

  /**
   * Return the result of resolving the URI of the given URI-based [directive]
   * against the URI of the given library, or `null` if the URI is not valid.
   *
   * Resolution is to be performed in the given [context]. Errors should be
   * reported to the [errorListener].
   */
  static Source resolveDirective(AnalysisContext context, Source librarySource,
      UriBasedDirective directive, AnalysisErrorListener errorListener) {
    StringLiteral uriLiteral = directive.uri;
    String uriContent = uriLiteral.stringValue;
    if (uriContent != null) {
      uriContent = uriContent.trim();
      directive.uriContent = uriContent;
    }
    UriValidationCode code = directive.validate();
    if (code == null) {
      String encodedUriContent = Uri.encodeFull(uriContent);
      Source source =
          context.sourceFactory.resolveUri(librarySource, encodedUriContent);
      directive.source = source;
      return source;
    }
    if (code == UriValidationCode.URI_WITH_DART_EXT_SCHEME) {
      return null;
    }
    if (code == UriValidationCode.URI_WITH_INTERPOLATION) {
      errorListener.onError(new AnalysisError(librarySource, uriLiteral.offset,
          uriLiteral.length, CompileTimeErrorCode.URI_WITH_INTERPOLATION));
      return null;
    }
    if (code == UriValidationCode.INVALID_URI) {
      errorListener.onError(new AnalysisError(librarySource, uriLiteral.offset,
          uriLiteral.length, CompileTimeErrorCode.INVALID_URI, [uriContent]));
      return null;
    }
    throw new AnalysisException('Failed to handle validation code: $code');
  }
}

/**
 * The helper for building the public [Namespace] of a [LibraryElement].
 */
class PublicNamespaceBuilder {
  final HashMap<String, Element> definedNames = new HashMap<String, Element>();

  /**
   * Build a public [Namespace] of the given [library].
   */
  Namespace build(LibraryElement library) {
    definedNames.clear();
    _addPublicNames(library.definingCompilationUnit);
    library.parts.forEach(_addPublicNames);
    return new Namespace(definedNames);
  }

  /**
   * Add the given [element] if it has a publicly visible name.
   */
  void _addIfPublic(Element element) {
    String name = element.name;
    if (name != null && !Scope.isPrivateName(name)) {
      definedNames[name] = element;
    }
  }

  /**
   * Add all of the public top-level names that are defined in the given
   * [compilationUnit].
   */
  void _addPublicNames(CompilationUnitElement compilationUnit) {
    compilationUnit.accessors.forEach(_addIfPublic);
    compilationUnit.enums.forEach(_addIfPublic);
    compilationUnit.functions.forEach(_addIfPublic);
    compilationUnit.functionTypeAliases.forEach(_addIfPublic);
    compilationUnit.types.forEach(_addIfPublic);
  }
}

/**
 * An artifitial task that does nothing except to force type names resolution
 * for the defining and part units of a library.
 */
class ResolveLibraryTypeNamesTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT4] input.
   */
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveLibraryTypeNamesTask', createTask, buildInputs,
      <ResultDescriptor>[LIBRARY_ELEMENT5]);

  ResolveLibraryTypeNamesTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

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
  static Map<String, TaskInput> buildInputs(Source libSource) {
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT4.of(libSource),
      'resolvedUnits': IMPORT_EXPORT_SOURCE_CLOSURE
          .of(libSource)
          .toMapOf(UNITS)
          .toFlattenList((Source library, Source unit) =>
              RESOLVED_UNIT4.of(new LibrarySpecificUnit(library, unit))),
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
 * A task that builds [RESOLVED_UNIT6] for a unit.
 */
class ResolveReferencesTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT] input.
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
      'ResolveReferencesTask', createTask, buildInputs, <ResultDescriptor>[
    RESOLVE_REFERENCES_ERRORS,
    RESOLVED_UNIT6
  ]);

  ResolveReferencesTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    //
    // Prepare inputs.
    //
    LibraryElement libraryElement = getRequiredInput(LIBRARY_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    CompilationUnitElement unitElement = unit.element;
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Resolve references.
    //
    InheritanceManager inheritanceManager =
        new InheritanceManager(libraryElement);
    AstVisitor visitor = new ResolverVisitor.con2(libraryElement,
        unitElement.source, typeProvider, inheritanceManager, errorListener);
    unit.accept(visitor);
    //
    // Record outputs.
    //
    outputs[RESOLVE_REFERENCES_ERRORS] = errorListener.errors;
    outputs[RESOLVED_UNIT6] = unit;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit target) {
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT.of(target.library),
      UNIT_INPUT: RESOLVED_UNIT5.of(target),
      TYPE_PROVIDER_INPUT: TYPE_PROVIDER.of(AnalysisContextTarget.request)
    };
  }

  /**
   * Create a [ResolveReferencesTask] based on the given [target] in
   * the given [context].
   */
  static ResolveReferencesTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveReferencesTask(context, target);
  }
}

/**
 * A task that builds [RESOLVED_UNIT4] for a unit.
 */
class ResolveUnitTypeNamesTask extends SourceBasedAnalysisTask {
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
      'ResolveUnitTypeNamesTask', createTask, buildInputs, <ResultDescriptor>[
    RESOLVE_TYPE_NAMES_ERRORS,
    RESOLVED_UNIT4
  ]);

  ResolveUnitTypeNamesTask(
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
    LibraryElement library = getRequiredInput(LIBRARY_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    CompilationUnitElement unitElement = unit.element;
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Resolve TypeName nodes.
    //
    TypeResolverVisitor visitor = new TypeResolverVisitor.con2(
        library, unitElement.source, typeProvider, errorListener);
    unit.accept(visitor);
    //
    // Record outputs.
    //
    outputs[RESOLVE_TYPE_NAMES_ERRORS] = errorListener.errors;
    outputs[RESOLVED_UNIT4] = unit;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit target) {
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT4.of(target.library),
      UNIT_INPUT: RESOLVED_UNIT3.of(target),
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
 * A task that builds [RESOLVED_UNIT5] for a unit.
 */
class ResolveVariableReferencesTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [LIBRARY_ELEMENT] input.
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
      'ResolveVariableReferencesTask', createTask, buildInputs,
      <ResultDescriptor>[RESOLVED_UNIT5]);

  ResolveVariableReferencesTask(
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
    LibraryElement libraryElement = getRequiredInput(LIBRARY_INPUT);
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    CompilationUnitElement unitElement = unit.element;
    //
    // Resolve local variables.
    //
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    Scope nameScope = new LibraryScope(libraryElement, errorListener);
    AstVisitor visitor = new VariableResolverVisitor.con2(libraryElement,
        unitElement.source, typeProvider, nameScope, errorListener);
    unit.accept(visitor);
    //
    // Record outputs.
    //
    outputs[RESOLVED_UNIT5] = unit;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit target) {
    return <String, TaskInput>{
      LIBRARY_INPUT: LIBRARY_ELEMENT.of(target.library),
      UNIT_INPUT: RESOLVED_UNIT4.of(target),
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
 * A task that scans the content of a file, producing a set of Dart tokens.
 */
class ScanDartTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the content of the file.
   */
  static const String CONTENT_INPUT_NAME = 'CONTENT_INPUT_NAME';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor('ScanDartTask',
      createTask, buildInputs, <ResultDescriptor>[
    LINE_INFO,
    SCAN_ERRORS,
    TOKEN_STREAM
  ]);

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
    String content = getRequiredInput(CONTENT_INPUT_NAME);

    RecordingErrorListener errorListener = new RecordingErrorListener();
    Scanner scanner =
        new Scanner(source, new CharSequenceReader(content), errorListener);
    scanner.preserveComments = context.analysisOptions.preserveComments;
    scanner.enableNullAwareOperators =
        context.analysisOptions.enableNullAwareOperators;

    Token tokenStream = scanner.tokenize();
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);
    List<AnalysisError> errors = errorListener.errors;
    outputs[TOKEN_STREAM] = tokenStream;
    outputs[LINE_INFO] = lineInfo;
    outputs[SCAN_ERRORS] = errors;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [source].
   */
  static Map<String, TaskInput> buildInputs(Source source) {
    return <String, TaskInput>{CONTENT_INPUT_NAME: CONTENT.of(source)};
  }

  /**
   * Create a [ScanDartTask] based on the given [target] in the given [context].
   */
  static ScanDartTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ScanDartTask(context, target);
  }
}

/**
 * A task that builds [VERIFY_ERRORS] for a unit.
 */
class VerifyUnitTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [RESOLVED_UNIT] input.
   */
  static const String UNIT_INPUT = 'UNIT_INPUT';

  /**
   * The name of the [TYPE_PROVIDER] input.
   */
  static const String TYPE_PROVIDER_INPUT = 'TYPE_PROVIDER_INPUT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor('VerifyUnitTask',
      createTask, buildInputs, <ResultDescriptor>[VERIFY_ERRORS]);

  /**
   * The [ErrorReporter] to report errors to.
   */
  ErrorReporter errorReporter;

  VerifyUnitTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    RecordingErrorListener errorListener = new RecordingErrorListener();
    Source source = getRequiredSource();
    errorReporter = new ErrorReporter(errorListener, source);
    TypeProvider typeProvider = getRequiredInput(TYPE_PROVIDER_INPUT);
    //
    // Prepare inputs.
    //
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    CompilationUnitElement unitElement = unit.element;
    LibraryElement libraryElement = unitElement.library;
    //
    // Validate the directives.
    //
    validateDirectives(unit);
    //
    // Use the ErrorVerifier to compute errors.
    //
    ErrorVerifier errorVerifier = new ErrorVerifier(errorReporter,
        libraryElement, typeProvider, new InheritanceManager(libraryElement));
    unit.accept(errorVerifier);
    //
    // Record outputs.
    //
    outputs[VERIFY_ERRORS] = errorListener.errors;
  }

  /**
   * Check each directive in the given [unit] to see if the referenced source
   * exists and report an error if it does not.
   */
  void validateDirectives(CompilationUnit unit) {
    for (Directive directive in unit.directives) {
      if (directive is UriBasedDirective) {
        validateReferencedSource(directive);
      }
    }
  }

  /**
   * Check the given [directive] to see if the referenced source exists and
   * report an error if it does not.
   */
  void validateReferencedSource(UriBasedDirective directive) {
    Source source = directive.source;
    if (source != null) {
      if (context.exists(source)) {
        return;
      }
    } else {
      // Don't report errors already reported by ParseDartTask.resolveDirective
      if (directive.validate() != null) {
        return;
      }
    }
    StringLiteral uriLiteral = directive.uri;
    errorReporter.reportErrorForNode(CompileTimeErrorCode.URI_DOES_NOT_EXIST,
        uriLiteral, [directive.uriContent]);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(LibrarySpecificUnit target) {
    return <String, TaskInput>{
      UNIT_INPUT: RESOLVED_UNIT.of(target),
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
 */
class _ExportSourceClosureTaskInput implements TaskInput<List<Source>> {
  final Source target;

  _ExportSourceClosureTaskInput(this.target);

  @override
  TaskInputBuilder<List<Source>> createBuilder() =>
      new _SourceClosureTaskInputBuilder(target, _SourceClosureKind.EXPORT);
}

/**
 * A [TaskInput] whose value is a list of library sources imported or exported,
 * directly or indirectly by the target [Source].
 */
class _ImportExportSourceClosureTaskInput implements TaskInput<List<Source>> {
  final Source target;

  _ImportExportSourceClosureTaskInput(this.target);

  @override
  TaskInputBuilder<List<Source>> createBuilder() =>
      new _SourceClosureTaskInputBuilder(
          target, _SourceClosureKind.IMPORT_EXPORT);
}

/**
 * A [TaskInput] whose value is a list of library sources imported directly
 * or indirectly by the target [Source].
 */
class _ImportSourceClosureTaskInput implements TaskInput<List<Source>> {
  final Source target;

  _ImportSourceClosureTaskInput(this.target);

  @override
  TaskInputBuilder<List<Source>> createBuilder() =>
      new _SourceClosureTaskInputBuilder(target, _SourceClosureKind.IMPORT);
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
  final Set<Source> _newSources = new HashSet<Source>();

  Source currentTarget;

  _SourceClosureTaskInputBuilder(Source librarySource, this.kind) {
    _newSources.add(librarySource);
  }

  @override
  ResultDescriptor get currentResult => LIBRARY_ELEMENT2;

  @override
  void set currentValue(Object value) {
    LibraryElement library = value;
    if (_libraries.add(library)) {
      if (kind == _SourceClosureKind.IMPORT ||
          kind == _SourceClosureKind.IMPORT_EXPORT) {
        for (ImportElement importElement in library.imports) {
          Source importedSource = importElement.importedLibrary.source;
          _newSources.add(importedSource);
        }
      }
      if (kind == _SourceClosureKind.EXPORT ||
          kind == _SourceClosureKind.IMPORT_EXPORT) {
        for (ExportElement exportElement in library.exports) {
          Source exportedSource = exportElement.exportedLibrary.source;
          _newSources.add(exportedSource);
        }
      }
    }
  }

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
    currentTarget = _newSources.first;
    _newSources.remove(currentTarget);
    return true;
  }
}
