// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.correction.fix;

import 'dart:collection';

import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/correction/fix.dart';
import 'package:analysis_services/search/hierarchy.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/correction/levenshtein.dart';
import 'package:analysis_services/src/correction/name_suggestion.dart';
import 'package:analysis_services/src/correction/source_buffer.dart';
import 'package:analysis_services/src/correction/source_range.dart' as rf;
import 'package:analysis_services/src/correction/strings.dart';
import 'package:analysis_services/src/correction/util.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:path/path.dart';


/**
 * A predicate is a one-argument function that returns a boolean value.
 */
typedef bool Predicate<E>(E argument);


/**
 * The computer for Dart fixes.
 */
class FixProcessor {
  static const int MAX_LEVENSHTEIN_DISTANCE = 3;

  final SearchEngine searchEngine;
  final Source source;
  final String file;
  final CompilationUnit unit;
  final AnalysisError error;
  CompilationUnitElement unitElement;
  Source unitSource;
  LibraryElement unitLibraryElement;
  String unitLibraryFile;
  String unitLibraryFolder;

  final List<Edit> edits = <Edit>[];
  final Map<String, LinkedEditGroup> linkedPositionGroups = <String,
      LinkedEditGroup>{};
  Position exitPosition = null;
  final List<Fix> fixes = <Fix>[];

  CorrectionUtils utils;
  int errorOffset;
  int errorLength;
  int errorEnd;
  AstNode node;
  AstNode coveredNode;

  FixProcessor(this.searchEngine, this.source, this.file, this.unit, this.error)
      {
    unitElement = unit.element;
    unitSource = unitElement.source;
    unitLibraryElement = unitElement.library;
    unitLibraryFile = unitLibraryElement.source.fullName;
    unitLibraryFolder = dirname(unitLibraryFile);
  }

  DartType get coreTypeBool => _getCoreType("bool");

  /**
   * Returns the EOL to use for this [CompilationUnit].
   */
  String get eol => utils.endOfLine;

  List<Fix> compute() {
    utils = new CorrectionUtils(unit);
    errorOffset = error.offset;
    errorLength = error.length;
    errorEnd = errorOffset + errorLength;
    node = new NodeLocator.con1(errorOffset).searchWithin(unit);
    coveredNode = new NodeLocator.con2(
        errorOffset,
        errorOffset + errorLength).searchWithin(unit);
    // analyze ErrorCode
    ErrorCode errorCode = error.errorCode;
    if (errorCode == StaticWarningCode.UNDEFINED_CLASS_BOOLEAN) {
      _addFix_boolInsteadOfBoolean();
    }
    if (errorCode ==
        CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE) {
      _addFix_replaceWithConstInstanceCreation();
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
    if (errorCode == HintCode.DIVISION_OPTIMIZATION) {
      _addFix_useEffectiveIntegerDivision();
    }
    if (errorCode == HintCode.TYPE_CHECK_IS_NOT_NULL) {
      _addFix_isNotNull();
    }
    if (errorCode == HintCode.TYPE_CHECK_IS_NULL) {
      _addFix_isNull();
    }
    if (errorCode == HintCode.UNNECESSARY_CAST) {
      _addFix_removeUnnecessaryCast();
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
    if (errorCode == StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER) {
      _addFix_makeEnclosingClassAbstract();
    }
    if (errorCode == StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS) {
      _addFix_createConstructor_insteadOfSyntheticDefault();
    }
    if (errorCode == StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR) {
      _addFix_createConstructor_named();
    }
    if (errorCode ==
        StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE ||
        errorCode ==
            StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO ||
        errorCode ==
            StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE ||
        errorCode ==
            StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR ||
        errorCode ==
            StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS) {
      // make class abstract
      _addFix_makeEnclosingClassAbstract();
      // implement methods
      AnalysisErrorWithProperties errorWithProperties =
          error as AnalysisErrorWithProperties;
      Object property =
          errorWithProperties.getProperty(ErrorProperty.UNIMPLEMENTED_METHODS);
      List<ExecutableElement> missingOverrides =
          property as List<ExecutableElement>;
      _addFix_createMissingOverrides(missingOverrides);
      _addFix_createNoSuchMethod();
    }
    if (errorCode == StaticWarningCode.UNDEFINED_CLASS) {
      _addFix_importLibrary_withType();
      _addFix_createClass();
      _addFix_undefinedClass_useSimilar();
    }
    if (errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER) {
      _addFix_createFunction_forFunctionType();
      _addFix_importLibrary_withType();
      _addFix_importLibrary_withTopLevelVariable();
    }
    if (errorCode == StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER) {
      _addFix_useStaticAccess_method();
      _addFix_useStaticAccess_property();
    }
    if (errorCode == StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION) {
      _addFix_removeParentheses_inGetterInvocation();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_FUNCTION) {
      _addFix_importLibrary_withFunction();
      _addFix_undefinedFunction_useSimilar();
      _addFix_undefinedFunction_create();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_GETTER) {
      _addFix_createFunction_forFunctionType();
    }
    if (errorCode == HintCode.UNDEFINED_METHOD ||
        errorCode == StaticTypeWarningCode.UNDEFINED_METHOD) {
      _addFix_undefinedMethod_useSimilar();
      _addFix_undefinedMethod_create();
      _addFix_undefinedFunction_create();
    }
    // done
    return fixes;
  }

  void _addFix(FixKind kind, List args, {String fixFile}) {
    if (fixFile == null) {
      fixFile = file;
    }
    FileEdit fileEdit = new FileEdit(file);
    edits.forEach((edit) => fileEdit.add(edit));
    // prepare Change
    String message = JavaString.format(kind.message, args);
    Change change = new Change(message);
    change.addFileEdit(fileEdit);
    linkedPositionGroups.values.forEach(
        (group) => change.addLinkedEditGroup(group));
    change.selection = exitPosition;
    // add Fix
    Fix fix = new Fix(kind, change);
    fixes.add(fix);
    // clear
    edits.clear();
    linkedPositionGroups.clear();
    exitPosition = null;
  }

  void _addFix_boolInsteadOfBoolean() {
    SourceRange range = rf.rangeError(error);
    _addReplaceEdit(range, "bool");
    _addFix(FixKind.REPLACE_BOOLEAN_WITH_BOOL, []);
  }

  void _addFix_createClass() {
    if (_mayBeTypeIdentifier(node)) {
      String name = (node as SimpleIdentifier).name;
      // prepare environment
      CompilationUnitMember enclosingMember =
          node.getAncestor((node) => node is CompilationUnitMember);
      int offset = enclosingMember.end;
      String prefix = "";
      // prepare source
      SourceBuilder sb = new SourceBuilder(file, offset);
      {
        sb.append("${eol}${eol}");
        sb.append(prefix);
        // "class"
        sb.append("class ");
        // append name
        {
          sb.startPosition("NAME");
          sb.append(name);
          sb.endPosition();
        }
        // no members
        sb.append(" {");
        sb.append(eol);
        sb.append("}");
      }
      // insert source
      _insertBuilder(sb);
      _addLinkedPosition("NAME", rf.rangeNode(node));
      // add proposal
      _addFix(FixKind.CREATE_CLASS, [name]);
    }
  }

  void _addFix_createConstructorSuperExplicit() {
    ConstructorDeclaration targetConstructor =
        node.parent as ConstructorDeclaration;
    ClassDeclaration targetClassNode =
        targetConstructor.parent as ClassDeclaration;
    ClassElement targetClassElement = targetClassNode.element;
    ClassElement superClassElement = targetClassElement.supertype.element;
    // add proposals for all super constructors
    List<ConstructorElement> superConstructors = superClassElement.constructors;
    for (ConstructorElement superConstructor in superConstructors) {
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
          sb.append(" : ");
        } else {
          ConstructorInitializer lastInitializer =
              initializers[initializers.length - 1];
          int insertOffset = lastInitializer.end;
          sb = new SourceBuilder(file, insertOffset);
          sb.append(", ");
        }
      }
      // add super constructor name
      sb.append("super");
      if (!StringUtils.isEmpty(constructorName)) {
        sb.append(".");
        sb.append(constructorName);
      }
      // add arguments
      sb.append("(");
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
          sb.append(", ");
        }
        // default value
        DartType parameterType = parameter.type;
        sb.startPosition(parameter.name);
        sb.append(getDefaultValueCode(parameterType));
        sb.endPosition();
      }
      sb.append(")");
      // insert proposal
      _insertBuilder(sb);
      // add proposal
      String proposalName = _getConstructorProposalName(superConstructor);
      _addFix(FixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION, [proposalName]);
    }
  }

  void _addFix_createConstructorSuperImplicit() {
    ClassDeclaration targetClassNode = node.parent as ClassDeclaration;
    ClassElement targetClassElement = targetClassNode.element;
    ClassElement superClassElement = targetClassElement.supertype.element;
    String targetClassName = targetClassElement.name;
    // add proposals for all super constructors
    List<ConstructorElement> superConstructors = superClassElement.constructors;
    for (ConstructorElement superConstructor in superConstructors) {
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
      _ConstructorLocation targetLocation =
          _prepareNewConstructorLocation(targetClassNode);
      SourceBuilder sb = new SourceBuilder(file, targetLocation._offset);
      {
        String indent = utils.getIndent(1);
        sb.append(targetLocation._prefix);
        sb.append(indent);
        sb.append(targetClassName);
        if (!constructorName.isEmpty) {
          sb.startPosition('NAME');
          sb.append('.');
          sb.append(constructorName);
          sb.endPosition();
        }
        sb.append("(");
        sb.append(parametersBuffer.toString());
        sb.append(') : super');
        if (!constructorName.isEmpty) {
          sb.append('.');
          sb.append(constructorName);
        }
        sb.append('(');
        sb.append(argumentsBuffer.toString());
        sb.append(');');
        sb.append(targetLocation._suffix);
      }
      _insertBuilder(sb);
      // add proposal
      String proposalName = _getConstructorProposalName(superConstructor);
      _addFix(FixKind.CREATE_CONSTRUCTOR_SUPER, [proposalName]);
    }
  }

  void _addFix_createConstructor_insteadOfSyntheticDefault() {
    TypeName typeName = null;
    ConstructorName constructorName = null;
    InstanceCreationExpression instanceCreation = null;
    if (node is SimpleIdentifier) {
      if (node.parent is TypeName) {
        typeName = node.parent as TypeName;
        if (typeName.name == node && typeName.parent is ConstructorName) {
          constructorName = typeName.parent as ConstructorName;
          // should be synthetic default constructor
          {
            ConstructorElement constructorElement =
                constructorName.staticElement;
            if (constructorElement == null ||
                !constructorElement.isDefaultConstructor ||
                !constructorElement.isSynthetic) {
              return;
            }
          }
          // prepare InstanceCreationExpression
          if (constructorName.parent is InstanceCreationExpression) {
            instanceCreation = constructorName.parent as
                InstanceCreationExpression;
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
    // prepare target
    DartType targetType = typeName.type;
    if (targetType is! InterfaceType) {
      return;
    }
    ClassElement targetElement = targetType.element as ClassElement;
    String targetFile = targetElement.source.fullName;
    ClassDeclaration targetClass = targetElement.node;
    _ConstructorLocation targetLocation =
        _prepareNewConstructorLocation(targetClass);
    // build method source
    SourceBuilder sb = new SourceBuilder(targetFile, targetLocation._offset);
    {
      String indent = "  ";
      sb.append(targetLocation._prefix);
      sb.append(indent);
      sb.append(targetElement.name);
      _addFix_undefinedMethod_create_parameters(
          sb,
          instanceCreation.argumentList);
      sb.append(") {${eol}${indent}}");
      sb.append(targetLocation._suffix);
    }
    // insert source
    _insertBuilder(sb);
    // add proposal
    _addFix(FixKind.CREATE_CONSTRUCTOR, [constructorName], fixFile: targetFile);
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
            instanceCreation = constructorName.parent as
                InstanceCreationExpression;
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
    ClassElement targetElement = targetType.element as ClassElement;
    String targetFile = targetElement.source.fullName;
    ClassDeclaration targetClass = targetElement.node;
    _ConstructorLocation targetLocation =
        _prepareNewConstructorLocation(targetClass);
    // build method source
    SourceBuilder sb = new SourceBuilder(targetFile, targetLocation._offset);
    {
      String indent = "  ";
      sb.append(targetLocation._prefix);
      sb.append(indent);
      sb.append(targetElement.name);
      sb.append(".");
      // append name
      {
        sb.startPosition("NAME");
        sb.append(name.name);
        sb.endPosition();
      }
      _addFix_undefinedMethod_create_parameters(
          sb,
          instanceCreation.argumentList);
      sb.append(") {${eol}${indent}}");
      sb.append(targetLocation._suffix);
    }
    // insert source
    _insertBuilder(sb);
    if (targetFile == file) {
      _addLinkedPosition("NAME", rf.rangeNode(name));
    }
    // add proposal
    _addFix(FixKind.CREATE_CONSTRUCTOR, [constructorName], fixFile: targetFile);
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
          targetElement = enclosingClass != null ?
              enclosingClass.element :
              null;
          argument = nameNode;
        }
      }
      // should be argument of some invocation
      ParameterElement parameterElement = argument.bestParameterElement;
      if (parameterElement == null) {
        return;
      }
      // should be parameter of function type
      DartType parameterType = parameterElement.type;
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

  void
      _addFix_createMissingOverrides(List<ExecutableElement> missingOverrides) {
    // sort by name
    missingOverrides.sort((Element firstElement, Element secondElement) {
      return compareStrings(
          firstElement.displayName,
          secondElement.displayName);
    });
    ClassDeclaration targetClass = node.parent as ClassDeclaration;
    int insertOffset = targetClass.end - 1;
    SourceBuilder sb = new SourceBuilder(file, insertOffset);
    // add elements
    bool isFirst = true;
    for (ExecutableElement missingOverride in missingOverrides) {
      if (!isFirst || !targetClass.members.isEmpty) {
        sb.append(eol);
      }
      _addFix_createMissingOverrides_single(sb, targetClass, missingOverride);
      isFirst = false;
    }
    // add proposal
    exitPosition = new Position(file, insertOffset);
    _insertBuilder(sb);
    _addFix(FixKind.CREATE_MISSING_OVERRIDES, [missingOverrides.length]);
  }

  void _addFix_createMissingOverrides_single(SourceBuilder sb,
      ClassDeclaration targetClass, ExecutableElement missingOverride) {
    // prepare environment
    String prefix = utils.getIndent(1);
    String prefix2 = utils.getIndent(2);
    // may be property
    ElementKind elementKind = missingOverride.kind;
    bool isGetter = elementKind == ElementKind.GETTER;
    bool isSetter = elementKind == ElementKind.SETTER;
    bool isMethod = elementKind == ElementKind.METHOD;
    bool isOperator = isMethod && (missingOverride as MethodElement).isOperator;
    sb.append(prefix);
    if (isGetter) {
      sb.append('// TODO: implement ${missingOverride.displayName}');
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
    _appendType(sb, missingOverride.type.returnType);
    if (isGetter) {
      sb.append('get ');
    } else if (isSetter) {
      sb.append('set ');
    } else if (isOperator) {
      sb.append('operator ');
    }
    // name
    sb.append(missingOverride.displayName);
    // parameters + body
    if (isGetter) {
      sb.append(' => null;');
    } else {
      List<ParameterElement> parameters = missingOverride.parameters;
      _appendParameters(sb, parameters, _getDefaultValueMap(parameters));
      sb.append(' {');
      // TO-DO
      sb.append(eol);
      sb.append(prefix2);
      sb.append('// TODO: implement ${missingOverride.displayName}');
      sb.append(eol);
      // close method
      sb.append(prefix);
      sb.append('}');
    }
    sb.append(eol);
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
          "noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);");
      sb.append(eol);
    }
    // done
    _insertBuilder(sb);
    exitPosition = new Position(file, insertOffset);
    // add proposal
    _addFix(FixKind.CREATE_NO_SUCH_METHOD, []);
  }

  void _addFix_importLibrary(FixKind kind, String importPath) {
    CompilationUnitElement libraryUnitElement =
        unitLibraryElement.definingCompilationUnit;
    CompilationUnit libraryUnit = libraryUnitElement.node;
    // prepare new import location
    int offset = 0;
    String prefix;
    String suffix;
    {
      // if no directives
      prefix = "";
      suffix = eol;
      CorrectionUtils libraryUtils = new CorrectionUtils(libraryUnit);
      // after last directive in library
      for (Directive directive in libraryUnit.directives) {
        if (directive is LibraryDirective || directive is ImportDirective) {
          offset = directive.end;
          prefix = eol;
          suffix = "";
        }
      }
      // if still beginning of file, skip shebang and line comments
      if (offset == 0) {
        CorrectionUtils_InsertDesc desc = libraryUtils.getInsertDescTop();
        offset = desc.offset;
        prefix = desc.prefix;
        suffix = "${desc.suffix}${eol}";
      }
    }
    // insert new import
    String importSource = "${prefix}import '${importPath}';${suffix}";
    _addInsertEdit(offset, importSource);
    // add proposal
    _addFix(kind, [importPath], fixFile: libraryUnitElement.source.fullName);
  }

  void _addFix_importLibrary_withElement(String name, ElementKind kind) {
    // ignore if private
    if (name.startsWith("_")) {
      return;
    }

    // may be there is an existing import,
    // but it is with prefix and we don't use this prefix
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
      if (element.kind != kind) {
        continue;
      }
      // may be apply prefix
      PrefixElement prefix = imp.prefix;
      if (prefix != null) {
        SourceRange range = rf.rangeStartLength(node, 0);
        _addReplaceEdit(range, "${prefix.displayName}.");
        _addFix(
            FixKind.IMPORT_LIBRARY_PREFIX,
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
        // update library
        String newShowCode = "show ${StringUtils.join(showNames, ", ")}";
        _addReplaceEdit(rf.rangeOffsetEnd(showCombinator), newShowCode);
        _addFix(
            FixKind.IMPORT_LIBRARY_SHOW,
            [libraryName],
            fixFile: unitLibraryFile);
        // we support only one import without prefix
        return;
      }
    }
    // check SDK libraries
    AnalysisContext context = unitLibraryElement.context;
    {
      DartSdk sdk = context.sourceFactory.dartSdk;
      List<SdkLibrary> sdkLibraries = sdk.sdkLibraries;
      for (SdkLibrary sdkLibrary in sdkLibraries) {
        SourceFactory sdkSourceFactory = context.sourceFactory;
        String libraryUri = 'dart:' + sdkLibrary.shortName;
        Source librarySource =
            sdkSourceFactory.resolveUri(unitSource, libraryUri);
        // prepare LibraryElement
        LibraryElement libraryElement =
            context.getLibraryElement(librarySource);
        if (libraryElement == null) {
          continue;
        }
        // prepare exported Element
        Element element = getExportedElement(libraryElement, name);
        if (element == null) {
          continue;
        }
        if (element is PropertyAccessorElement) {
          element = (element as PropertyAccessorElement).variable;
        }
        if (element.kind != kind) {
          continue;
        }
        // add import
        _addFix_importLibrary(FixKind.IMPORT_LIBRARY_SDK, libraryUri);
      }
    }
    // check project libraries
    {
      List<Source> librarySources = context.librarySources;
      for (Source librarySource in librarySources) {
        // we don't need SDK libraries here
        if (librarySource.isInSystemLibrary) {
          continue;
        }
        // prepare LibraryElement
        LibraryElement libraryElement =
            context.getLibraryElement(librarySource);
        if (libraryElement == null) {
          continue;
        }
        // prepare exported Element
        Element element = getExportedElement(libraryElement, name);
        if (element == null) {
          continue;
        }
        if (element is PropertyAccessorElement) {
          element = (element as PropertyAccessorElement).variable;
        }
        if (element.kind != kind) {
          continue;
        }
        // prepare "library" file
        String libraryFile = librarySource.fullName;
        // may be "package:" URI
        {
          String libraryPackageUri = _findPackageUri(context, libraryFile);
          if (libraryPackageUri != null) {
            _addFix_importLibrary(
                FixKind.IMPORT_LIBRARY_PROJECT,
                libraryPackageUri);
            continue;
          }
        }
        // relative URI
        String relativeFile = relative(libraryFile, from: unitLibraryFolder);
        relativeFile = split(relativeFile).join('/');
        _addFix_importLibrary(FixKind.IMPORT_LIBRARY_PROJECT, relativeFile);
      }
    }
  }

  void _addFix_importLibrary_withFunction() {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      if (invocation.realTarget == null && invocation.methodName == node) {
        String name = (node as SimpleIdentifier).name;
        _addFix_importLibrary_withElement(name, ElementKind.FUNCTION);
      }
    }
  }

  void _addFix_importLibrary_withTopLevelVariable() {
    if (node is SimpleIdentifier) {
      String name = (node as SimpleIdentifier).name;
      _addFix_importLibrary_withElement(name, ElementKind.TOP_LEVEL_VARIABLE);
    }
  }

  void _addFix_importLibrary_withType() {
    if (_mayBeTypeIdentifier(node)) {
      String typeName = (node as SimpleIdentifier).name;
      _addFix_importLibrary_withElement(typeName, ElementKind.CLASS);
    }
  }

  void _addFix_insertSemicolon() {
    if (error.message.contains("';'")) {
      int insertOffset = error.offset + error.length;
      _addInsertEdit(insertOffset, ";");
      _addFix(FixKind.INSERT_SEMICOLON, []);
    }
  }

  void _addFix_isNotNull() {
    if (coveredNode is IsExpression) {
      IsExpression isExpression = coveredNode as IsExpression;
      _addReplaceEdit(
          rf.rangeEndEnd(isExpression.expression, isExpression),
          " != null");
      _addFix(FixKind.USE_NOT_EQ_NULL, []);
    }
  }

  void _addFix_isNull() {
    if (coveredNode is IsExpression) {
      IsExpression isExpression = coveredNode as IsExpression;
      _addReplaceEdit(
          rf.rangeEndEnd(isExpression.expression, isExpression),
          " == null");
      _addFix(FixKind.USE_EQ_EQ_NULL, []);
    }
  }

  void _addFix_makeEnclosingClassAbstract() {
    ClassDeclaration enclosingClass =
        node.getAncestor((node) => node is ClassDeclaration);
    String className = enclosingClass.name.name;
    _addInsertEdit(enclosingClass.classKeyword.offset, "abstract ");
    _addFix(FixKind.MAKE_CLASS_ABSTRACT, [className]);
  }

  void _addFix_removeParameters_inGetterDeclaration() {
    if (node is SimpleIdentifier && node.parent is MethodDeclaration) {
      MethodDeclaration method = node.parent as MethodDeclaration;
      FunctionBody body = method.body;
      if (method.name == node && body != null) {
        _addReplaceEdit(rf.rangeEndStart(node, body), " ");
        _addFix(FixKind.REMOVE_PARAMETERS_IN_GETTER_DECLARATION, []);
      }
    }
  }

  void _addFix_removeParentheses_inGetterInvocation() {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      if (invocation.methodName == node && invocation.target != null) {
        _addRemoveEdit(rf.rangeEndEnd(node, invocation));
        _addFix(FixKind.REMOVE_PARENTHESIS_IN_GETTER_INVOCATION, []);
      }
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
    _addRemoveEdit(rf.rangeEndEnd(expression, asExpression));
    _removeEnclosingParentheses(asExpression, expressionPrecedence);
    // done
    _addFix(FixKind.REMOVE_UNNECASSARY_CAST, []);
  }

  void _addFix_removeUnusedImport() {
    // prepare ImportDirective
    ImportDirective importDirective =
        node.getAncestor((node) => node is ImportDirective);
    if (importDirective == null) {
      return;
    }
    // remove the whole line with import
    _addRemoveEdit(utils.getLinesRange(rf.rangeNode(importDirective)));
    // done
    _addFix(FixKind.REMOVE_UNUSED_IMPORT, []);
  }

  void _addFix_replaceWithConstInstanceCreation() {
    if (coveredNode is InstanceCreationExpression) {
      var instanceCreation = coveredNode as InstanceCreationExpression;
      _addReplaceEdit(rf.rangeToken(instanceCreation.keyword), "const");
      _addFix(FixKind.USE_CONST, []);
    }
  }

  void _addFix_undefinedClass_useSimilar() {
    if (_mayBeTypeIdentifier(node)) {
      String name = (node as SimpleIdentifier).name;
      _ClosestElementFinder finder =
          new _ClosestElementFinder(
              name,
              (Element element) => element is ClassElement,
              MAX_LEVENSHTEIN_DISTANCE);
      // find closest element
      {
        // elements of this library
        for (CompilationUnitElement unit in unitLibraryElement.units) {
          finder._updateList(unit.types);
        }
        // elements from imports
        for (ImportElement importElement in unitLibraryElement.imports) {
          if (importElement.prefix == null) {
            Map<String, Element> namespace = getImportNamespace(importElement);
            finder._updateList(namespace.values);
          }
        }
      }
      // if we have close enough element, suggest to use it
      if (finder._element != null) {
        String closestName = finder._element.name;
        _addReplaceEdit(rf.rangeNode(node), closestName);
        // add proposal
        if (closestName != null) {
          _addFix(FixKind.CHANGE_TO, [closestName]);
        }
      }
    }
  }

  void _addFix_undefinedFunction_create() {
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
        node.getAncestor((node) => node is CompilationUnitMember);
    insertOffset = enclosingMember.end;
    sourcePrefix = "${eol}${eol}";
    // build method source
    SourceBuilder sb = new SourceBuilder(file, insertOffset);
    {
      sb.append(sourcePrefix);
      // append return type
      {
        DartType type = _inferReturnType(invocation);
        _appendType(sb, type, 'RETURN_TYPE');
      }
      // append name
      {
        sb.startPosition("NAME");
        sb.append(name);
        sb.endPosition();
      }
      _addFix_undefinedMethod_create_parameters(sb, invocation.argumentList);
      sb.append(") {${eol}}");
    }
    // insert source
    _insertBuilder(sb);
    _addLinkedPosition3('NAME', sb, rf.rangeNode(node));
    // add proposal
    _addFix(FixKind.CREATE_FUNCTION, [name]);
  }

  void _addFix_undefinedFunction_useSimilar() {
    if (node is SimpleIdentifier) {
      String name = (node as SimpleIdentifier).name;
      _ClosestElementFinder finder =
          new _ClosestElementFinder(
              name,
              (Element element) => element is FunctionElement,
              MAX_LEVENSHTEIN_DISTANCE);
      // this library
      for (CompilationUnitElement unit in unitLibraryElement.units) {
        finder._updateList(unit.functions);
      }
      // imports
      for (ImportElement importElement in unitLibraryElement.imports) {
        if (importElement.prefix == null) {
          Map<String, Element> namespace = getImportNamespace(importElement);
          finder._updateList(namespace.values);
        }
      }
      // if we have close enough element, suggest to use it
      if (finder._element != null) {
        String closestName = finder._element.name;
        _addReplaceEdit(rf.rangeNode(node), closestName);
        _addFix(FixKind.CHANGE_TO, [closestName]);
      }
    }
  }

  void _addFix_undefinedMethod_create() {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      String name = (node as SimpleIdentifier).name;
      MethodInvocation invocation = node.parent as MethodInvocation;
      // prepare environment
      Source targetSource;
      String prefix;
      int insertOffset;
      String sourcePrefix;
      String sourceSuffix;
      bool staticModifier = false;
      Expression target = invocation.realTarget;
      if (target == null) {
        targetSource = source;
        ClassMember enclosingMember =
            node.getAncestor((node) => node is ClassMember);
        staticModifier = _inStaticContext();
        prefix = utils.getNodePrefix(enclosingMember);
        insertOffset = enclosingMember.end;
        sourcePrefix = "${eol}${eol}";
        sourceSuffix = "";
      } else {
        // prepare target interface type
        DartType targetType = target.bestType;
        if (targetType is! InterfaceType) {
          return;
        }
        ClassElement targetElement = targetType.element as ClassElement;
        targetSource = targetElement.source;
        // may be static
        if (target is Identifier) {
          staticModifier = target.bestElement.kind == ElementKind.CLASS;
        }
        // prepare insert offset
        ClassDeclaration targetClass = targetElement.node;
        prefix = "  ";
        insertOffset = targetClass.end - 1;
        if (targetClass.members.isEmpty) {
          sourcePrefix = "";
        } else {
          sourcePrefix = eol;
        }
        sourceSuffix = eol;
      }
      String targetFile = targetSource.fullName;
      // build method source
      SourceBuilder sb = new SourceBuilder(targetFile, insertOffset);
      {
        sb.append(sourcePrefix);
        sb.append(prefix);
        // maybe "static"
        if (staticModifier) {
          sb.append("static ");
        }
        // append return type
        _appendType(sb, _inferReturnType(invocation), 'RETURN_TYPE');
        // append name
        {
          sb.startPosition("NAME");
          sb.append(name);
          sb.endPosition();
        }
        _addFix_undefinedMethod_create_parameters(sb, invocation.argumentList);
        sb.append(") {${eol}${prefix}}");
        sb.append(sourceSuffix);
      }
      // insert source
      _insertBuilder(sb);
      // add linked positions
      if (targetSource == source) {
        _addLinkedPosition3('NAME', sb, rf.rangeNode(node));
      }
      // add proposal
      _addFix(FixKind.CREATE_METHOD, [name], fixFile: targetFile);
    }
  }

  void _addFix_undefinedMethod_create_parameters(SourceBuilder sb,
      ArgumentList argumentList) {
    // append parameters
    sb.append("(");
    Set<String> excluded = new Set();
    List<Expression> arguments = argumentList.arguments;
    for (int i = 0; i < arguments.length; i++) {
      Expression argument = arguments[i];
      // append separator
      if (i != 0) {
        sb.append(", ");
      }
      // append type name
      DartType type = argument.bestType;
      String typeSource = utils.getTypeSource(type);
      {
        sb.startPosition("TYPE${i}");
        sb.append(typeSource);
        _addSuperTypeProposals(sb, new Set(), type);
        sb.endPosition();
      }
      sb.append(" ");
      // append parameter name
      {
        List<String> suggestions =
            _getArgumentNameSuggestions(excluded, type, argument, i);
        String favorite = suggestions[0];
        excluded.add(favorite);
        sb.startPosition("ARG${i}");
        sb.append(favorite);
        sb.addSuggestions(LinkedEditSuggestionKind.PARAMETER, suggestions);
        sb.endPosition();
      }
    }
  }

  void _addFix_undefinedMethod_useSimilar() {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      String name = (node as SimpleIdentifier).name;
      _ClosestElementFinder finder =
          new _ClosestElementFinder(
              name,
              (Element element) => element is MethodElement && !element.isOperator,
              MAX_LEVENSHTEIN_DISTANCE);
      // unqualified invocation
      Expression target = invocation.realTarget;
      if (target == null) {
        ClassDeclaration clazz =
            invocation.getAncestor((node) => node is ClassDeclaration);
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
        _addReplaceEdit(rf.rangeNode(node), closestName);
        _addFix(FixKind.CHANGE_TO, [closestName]);
      }
    }
  }

  void _addFix_useEffectiveIntegerDivision() {
    for (AstNode n = node; n != null; n = n.parent) {
      if (n is MethodInvocation &&
          n.offset == errorOffset &&
          n.length == errorLength) {
        MethodInvocation invocation = n as MethodInvocation;
        Expression target = invocation.target;
        while (target is ParenthesizedExpression) {
          target = (target as ParenthesizedExpression).expression;
        }
        // replace "/" with "~/"
        BinaryExpression binary = target as BinaryExpression;
        _addReplaceEdit(rf.rangeToken(binary.operator), "~/");
        // remove everything before and after
        _addRemoveEdit(rf.rangeStartStart(invocation, binary.leftOperand));
        _addRemoveEdit(rf.rangeEndEnd(binary.rightOperand, invocation));
        // add proposal
        _addFix(FixKind.USE_EFFECTIVE_INTEGER_DIVISION, []);
        // done
        break;
      }
    }
  }

  void _addFix_useStaticAccess_method() {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      MethodInvocation invocation = node.parent as MethodInvocation;
      if (invocation.methodName == node) {
        Expression target = invocation.target;
        String targetType = utils.getExpressionTypeSource(target);
        // replace "target" with class name
        SourceRange range = rf.rangeNode(target);
        _addReplaceEdit(range, targetType);
        // add proposal
        _addFix(FixKind.CHANGE_TO_STATIC_ACCESS, [targetType]);
      }
    }
  }

  void _addFix_useStaticAccess_property() {
    if (node is SimpleIdentifier) {
      if (node.parent is PrefixedIdentifier) {
        PrefixedIdentifier prefixed = node.parent as PrefixedIdentifier;
        if (prefixed.identifier == node) {
          Expression target = prefixed.prefix;
          String targetType = utils.getExpressionTypeSource(target);
          // replace "target" with class name
          SourceRange range = rf.rangeNode(target);
          _addReplaceEdit(range, targetType);
          // add proposal
          _addFix(FixKind.CHANGE_TO_STATIC_ACCESS, [targetType]);
        }
      }
    }
  }

  /**
   * Adds a new [Edit] to [edits].
   */
  void _addInsertEdit(int offset, String text) {
    Edit edit = new Edit(offset, 0, text);
    edits.add(edit);
  }

  /**
   * Adds a single linked position to [groupId].
   */
  void _addLinkedPosition(String groupId, SourceRange range) {
    Position position = new Position(file, range.offset);
    LinkedEditGroup group = _getLinkedPosition(groupId);
    group.addPosition(position, range.length);
  }

  /**
   * Adds a single linked position to [groupId].
   */
  void _addLinkedPosition3(String groupId, SourceBuilder sb,
      SourceRange range) {
    if (sb.offset < range.offset) {
      int delta = sb.length;
      range = range.getTranslated(delta);
    }
    _addLinkedPosition(groupId, range);
  }

  /**
   * Prepares proposal for creating function corresponding to the given [FunctionType].
   */
  void _addProposal_createFunction(FunctionType functionType, String name,
      Source targetSource, int insertOffset, bool isStatic, String prefix,
      String sourcePrefix, String sourceSuffix) {
    // build method source
    String targetFile = targetSource.fullName;
    SourceBuilder sb = new SourceBuilder(targetFile, insertOffset);
    {
      sb.append(sourcePrefix);
      sb.append(prefix);
      // may be static
      if (isStatic) {
        sb.append("static ");
      }
      // append return type
      _appendType(sb, functionType.returnType, 'RETURN_TYPE');
      // append name
      {
        sb.startPosition("NAME");
        sb.append(name);
        sb.endPosition();
      }
      // append parameters
      sb.append("(");
      List<ParameterElement> parameters = functionType.parameters;
      for (int i = 0; i < parameters.length; i++) {
        ParameterElement parameter = parameters[i];
        // append separator
        if (i != 0) {
          sb.append(", ");
        }
        // append type name
        DartType type = parameter.type;
        if (!type.isDynamic) {
          String typeSource = utils.getTypeSource(type);
          {
            sb.startPosition("TYPE${i}");
            sb.append(typeSource);
            _addSuperTypeProposals(sb, new Set(), type);
            sb.endPosition();
          }
          sb.append(" ");
        }
        // append parameter name
        {
          sb.startPosition("ARG${i}");
          sb.append(parameter.displayName);
          sb.endPosition();
        }
      }
      sb.append(")");
      // close method
      sb.append(" {${eol}${prefix}}");
      sb.append(sourceSuffix);
    }
    // insert source
    _insertBuilder(sb);
    // add linked positions
    if (targetSource == source) {
      _addLinkedPosition3("NAME", sb, rf.rangeNode(node));
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
    String prefix = "";
    String sourcePrefix = "${eol}";
    String sourceSuffix = eol;
    _addProposal_createFunction(
        functionType,
        name,
        source,
        insertOffset,
        false,
        prefix,
        sourcePrefix,
        sourceSuffix);
    // add proposal
    _addFix(FixKind.CREATE_FUNCTION, [name], fixFile: file);
  }

  /**
   * Adds proposal for creating method corresponding to the given [FunctionType] in the given
   * [ClassElement].
   */
  void _addProposal_createFunction_method(ClassElement targetClassElement,
      FunctionType functionType) {
    String name = (node as SimpleIdentifier).name;
    // prepare environment
    Source targetSource = targetClassElement.source;
    String targetFile = targetSource.fullName;
    // prepare insert offset
    ClassDeclaration targetClassNode = targetClassElement.node;
    int insertOffset = targetClassNode.end - 1;
    // prepare prefix
    String prefix = "  ";
    String sourcePrefix;
    if (targetClassNode.members.isEmpty) {
      sourcePrefix = "";
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
        sourceSuffix);
    // add proposal
    _addFix(FixKind.CREATE_METHOD, [name], fixFile: targetFile);
  }

  /**
   * Adds a new [Edit] to [edits].
   */
  void _addRemoveEdit(SourceRange range) {
    _addReplaceEdit(range, '');
  }

  /**
   * Adds a new [Edit] to [edits].
   */
  void _addReplaceEdit(SourceRange range, String text) {
    Edit edit = new Edit(range.offset, range.length, text);
    edits.add(edit);
  }

  void _appendParameterSource(SourceBuilder sb, DartType type, String name) {
    String parameterSource = utils.getParameterSource(type, name);
    sb.append(parameterSource);
  }

  void _appendParameters(SourceBuilder sb, List<ParameterElement> parameters,
      Map<ParameterElement, String> defaultValueMap) {
    sb.append("(");
    bool firstParameter = true;
    bool sawNamed = false;
    bool sawPositional = false;
    for (ParameterElement parameter in parameters) {
      if (!firstParameter) {
        sb.append(", ");
      } else {
        firstParameter = false;
      }
      // may be optional
      ParameterKind parameterKind = parameter.parameterKind;
      if (parameterKind == ParameterKind.NAMED) {
        if (!sawNamed) {
          sb.append("{");
          sawNamed = true;
        }
      }
      if (parameterKind == ParameterKind.POSITIONAL) {
        if (!sawPositional) {
          sb.append("[");
          sawPositional = true;
        }
      }
      // parameter
      _appendParameterSource(sb, parameter.type, parameter.name);
      // default value
      if (defaultValueMap != null) {
        String defaultSource = defaultValueMap[parameter];
        if (defaultSource != null) {
          if (sawPositional) {
            sb.append(" = ");
          } else {
            sb.append(": ");
          }
          sb.append(defaultSource);
        }
      }
    }
    // close parameters
    if (sawNamed) {
      sb.append("}");
    }
    if (sawPositional) {
      sb.append("]");
    }
    sb.append(")");
  }

  void _appendType(SourceBuilder sb, DartType type, [String groupId]) {
    if (type != null && !type.isDynamic) {
      String typeSource = utils.getTypeSource(type);
      if (groupId != null) {
        sb.startPosition(groupId);
        sb.append(typeSource);
        sb.endPosition();
      } else {
        sb.append(typeSource);
      }
      sb.append(' ');
    }
  }

  /**
   * @return the string to display as the name of the given constructor in a proposal name.
   */
  String _getConstructorProposalName(ConstructorElement constructor) {
    SourceBuilder proposalNameBuffer = new SourceBuilder.buffer();
    proposalNameBuffer.append("super");
    // may be named
    String constructorName = constructor.displayName;
    if (!constructorName.isEmpty) {
      proposalNameBuffer.append(".");
      proposalNameBuffer.append(constructorName);
    }
    // parameters
    _appendParameters(proposalNameBuffer, constructor.parameters, null);
    // done
    return proposalNameBuffer.toString();
  }

  /**
   * Returns the [Type] with given name from the `dart:core` library.
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

  Map<ParameterElement, String>
      _getDefaultValueMap(List<ParameterElement> parameters) {
    Map<ParameterElement, String> defaultSourceMap = {};
    Map<Source, String> sourceContentMap = {};
    for (ParameterElement parameter in parameters) {
      SourceRange valueRange = parameter.defaultValueRange;
      if (valueRange != null) {
        Source source = parameter.source;
        String sourceContent = sourceContentMap[source];
        if (sourceContent == null) {
          sourceContent = getSourceContent(parameter.context, source);
          sourceContentMap[source] = sourceContent;
        }
        String valueSource =
            sourceContent.substring(valueRange.offset, valueRange.end);
        defaultSourceMap[parameter] = valueSource;
      }
    }
    return defaultSourceMap;
  }

  /**
   * Returns an existing or just added [LinkedEditGroup] with [groupId].
   */
  LinkedEditGroup _getLinkedPosition(String groupId) {
    LinkedEditGroup group = linkedPositionGroups[groupId];
    if (group == null) {
      group = new LinkedEditGroup(groupId);
      linkedPositionGroups[groupId] = group;
    }
    return group;
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

  /**
   * Returns a possible return [Type], may be `null` if cannot be inferred.
   */
  DartType _inferReturnType(MethodInvocation invocation) {
    AstNode parent = invocation.parent;
    // myFunction();
    if (parent is ExpressionStatement) {
      return VoidTypeImpl.instance;
    }
    // return myFunction();
    if (parent is ReturnStatement) {
      ExecutableElement executable = getEnclosingExecutableElement(invocation);
      return executable != null ? executable.returnType : null;
    }
    // int v = myFunction();
    if (parent is VariableDeclaration) {
      VariableDeclaration variableDeclaration = parent;
      if (variableDeclaration.initializer == invocation) {
        VariableElement variableElement = variableDeclaration.element;
        if (variableElement != null) {
          return variableElement.type;
        }
      }
    }
    // v = myFunction();
    if (parent is AssignmentExpression) {
      AssignmentExpression assignment = parent;
      if (assignment.rightHandSide == invocation) {
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
        if (binary.rightOperand == invocation) {
          List<ParameterElement> parameters = method.parameters;
          return parameters.length == 1 ? parameters[0].type : null;
        }
      }
    }
    // foo( myFunction() );
    if (parent is ArgumentList) {
      ParameterElement parameter = invocation.bestParameterElement;
      return parameter != null ? parameter.type : null;
    }
    // bool
    {
      // assert( myFunction() );
      if (parent is AssertStatement) {
        AssertStatement statement = parent;
        if (statement.condition == invocation) {
          return coreTypeBool;
        }
      }
      // if ( myFunction() ) {}
      if (parent is IfStatement) {
        IfStatement statement = parent;
        if (statement.condition == invocation) {
          return coreTypeBool;
        }
      }
      // while ( myFunction() ) {}
      if (parent is WhileStatement) {
        WhileStatement statement = parent;
        if (statement.condition == invocation) {
          return coreTypeBool;
        }
      }
      // do {} while ( myFunction() );
      if (parent is DoStatement) {
        DoStatement statement = parent;
        if (statement.condition == invocation) {
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
  void _insertBuilder(SourceBuilder builder) {
    String text = builder.toString();
    _addInsertEdit(builder.offset, text);
    // add linked positions
    builder.linkedPositionGroups.forEach((LinkedEditGroup group) {
      LinkedEditGroup fixGroup = _getLinkedPosition(group.id);
      group.positions.forEach((Position position) {
        fixGroup.addPosition(position, group.length);
      });
      group.suggestions.forEach((LinkedEditSuggestion suggestion) {
        fixGroup.addSuggestion(suggestion);
      });
    });
  }

//  void _addLinkedPositionProposal(String group,
//      LinkedPositionProposal proposal) {
//    List<LinkedPositionProposal> nodeProposals = linkedPositionProposals[group];
//    if (nodeProposals == null) {
//      nodeProposals = <LinkedPositionProposal>[];
//      linkedPositionProposals[group] = nodeProposals;
//    }
//    nodeProposals.add(proposal);
//  }

//  /**
//   * Returns `true` if the given [ClassMember] is a part of a static method or
//   * a field initializer.
//   */
//  bool _inStaticMemberContext2(ClassMember member) {
//    if (member is MethodDeclaration) {
//      return member.isStatic;
//    }
//    // field initializer cannot reference "this"
//    if (member is FieldDeclaration) {
//      return true;
//    }
//    return false;
//  }

  _ConstructorLocation
      _prepareNewConstructorLocation(ClassDeclaration classDeclaration) {
    List<ClassMember> members = classDeclaration.members;
    // find the last field/constructor
    ClassMember lastFieldOrConstructor = null;
    for (ClassMember member in members) {
      if (member is FieldDeclaration || member is ConstructorDeclaration) {
        lastFieldOrConstructor = member;
      } else {
        break;
      }
    }
    // after the field/constructor
    if (lastFieldOrConstructor != null) {
      return new _ConstructorLocation(
          "${eol}${eol}",
          lastFieldOrConstructor.end,
          "");
    }
    // at the beginning of the class
    String suffix = members.isEmpty ? "" : eol;
    return new _ConstructorLocation(
        eol,
        classDeclaration.leftBracket.end,
        suffix);
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
      _addRemoveEdit(rf.rangeToken(parenthesized.leftParenthesis));
      _addRemoveEdit(rf.rangeToken(parenthesized.rightParenthesis));
      expr = parenthesized;
    }
  }

  void _updateFinderWithClassMembers(_ClosestElementFinder finder,
      ClassElement clazz) {
    if (clazz != null) {
      List<Element> members = getMembers(clazz);
      finder._updateList(members);
    }
  }

  static void _addSuperTypeProposals(SourceBuilder sb,
      Set<DartType> alreadyAdded, DartType type) {
    if (type != null &&
        !alreadyAdded.contains(type) &&
        type.element is ClassElement) {
      alreadyAdded.add(type);
      ClassElement element = type.element as ClassElement;
      sb.addSuggestion(LinkedEditSuggestionKind.TYPE, element.name);
      _addSuperTypeProposals(sb, alreadyAdded, element.supertype);
      for (InterfaceType interfaceType in element.interfaces) {
        _addSuperTypeProposals(sb, alreadyAdded, interfaceType);
      }
    }
  }

  /**
   * Attempts to convert the given absolute path into a "package" URI.
   *
   * [context] - the [AnalysisContext] to work in.
   * [path] - the absolute path, not `null`.
   *
   * Returns the "package" URI, may be `null`.
   */
  static String _findPackageUri(AnalysisContext context, String path) {
//    Source fileSource = new FileBasedSource.con1(path);
    Source fileSource = new NonExistingSource(path, UriKind.FILE_URI);
    Uri uri = context.sourceFactory.restoreUri(fileSource);
    if (uri == null) {
      return null;
    }
    return uri.toString();
  }

  /**
   * @return the suggestions for given [Type] and [DartExpression], not empty.
   */
  static List<String> _getArgumentNameSuggestions(Set<String> excluded,
      DartType type, Expression expression, int index) {
    List<String> suggestions =
        getVariableNameSuggestionsForExpression(type, expression, excluded);
    if (suggestions.length != 0) {
      return suggestions;
    }
    return <String>["arg${index}"];
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
      if (parent is MethodInvocation) {
        return parent.realTarget == node;
      }
      if (parent is PrefixedIdentifier) {
        return parent.prefix == node;
      }
    }
    return false;
  }
}

/**
 * Helper for finding [Element] with name closest to the given.
 */
class _ClosestElementFinder {
  final String _targetName;
  final Predicate<Element> _predicate;

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

/**
 * Describes the location for a newly created [ConstructorDeclaration].
 */
class _ConstructorLocation {
  final String _prefix;
  final int _offset;
  final String _suffix;

  _ConstructorLocation(this._prefix, this._offset, this._suffix);
}
