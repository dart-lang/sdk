// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.src.correction.fix;

import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/correction/fix.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/correction/name_suggestion.dart';
import 'package:analysis_services/src/correction/source_buffer.dart';
import 'package:analysis_services/src/correction/source_range.dart' as rf;
import 'package:analysis_services/src/correction/util.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';


/**
 * The computer for Dart fixes.
 */
class FixProcessor {
  final SearchEngine searchEngine;
  final String file;
  final CompilationUnit unit;
  final AnalysisError error;

  final List<Edit> edits = <Edit>[];
  final Map<String, LinkedPositionGroup> linkedPositionGroups = <String,
      LinkedPositionGroup>{};
  final List<Fix> fixes = <Fix>[];

  CorrectionUtils utils;
  int errorOffset;
  int errorLength;
  int errorEnd;
  AstNode node;
  AstNode coveredNode;


  FixProcessor(this.searchEngine, this.file, this.unit, this.error);

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
//    if (identical(
//        errorCode,
//        CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT)) {
//      _addFix_createConstructorSuperImplicit();
//    }
    if (errorCode ==
        CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT) {
      _addFix_createConstructorSuperExplicit();
    }
//    if (identical(errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST)) {
//      _addFix_createPart();
//      _addFix_addPackageDependency();
//    }
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
//    if (identical(errorCode, StaticWarningCode.UNDEFINED_IDENTIFIER)) {
//      _addFix_createFunction_forFunctionType();
//      _addFix_importLibrary_withType();
//      _addFix_importLibrary_withTopLevelVariable();
//    }
    if (errorCode == StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER) {
      _addFix_useStaticAccess_method();
      _addFix_useStaticAccess_property();
    }
    if (errorCode == StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION) {
      _addFix_removeParentheses_inGetterInvocation();
    }
//    if (identical(errorCode, StaticTypeWarningCode.UNDEFINED_FUNCTION)) {
//      _addFix_importLibrary_withFunction();
//      _addFix_undefinedFunction_useSimilar();
//      _addFix_undefinedFunction_create();
//    }
//    if (identical(errorCode, StaticTypeWarningCode.UNDEFINED_GETTER)) {
//      _addFix_createFunction_forFunctionType();
//    }
//    if (identical(errorCode, HintCode.UNDEFINED_METHOD) ||
//        identical(errorCode, StaticTypeWarningCode.UNDEFINED_METHOD)) {
//      _addFix_undefinedMethod_useSimilar();
//      _addFix_undefinedMethod_create();
//      _addFix_undefinedFunction_create();
//    }
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
    change.add(fileEdit);
    linkedPositionGroups.values.forEach(
        (group) => change.addLinkedPositionGroup(group));
    // add Fix
    Fix fix = new Fix(kind, change);
    fixes.add(fix);
  }

  void _addFix_addPackageDependency() {
    // TODO(scheglov) implement
//    if (node is SimpleStringLiteral && node.parent is NamespaceDirective) {
//      SimpleStringLiteral uriLiteral = node as SimpleStringLiteral;
//      String uriString = uriLiteral.value;
//      // we need package: import
//      if (!uriString.startsWith("package:")) {
//        return;
//      }
//      // prepare package name
//      String packageName = StringUtils.removeStart(uriString, "package:");
//      packageName = StringUtils.substringBefore(packageName, "/");
//      // add proposal
//      _proposals.add(
//          new AddDependencyCorrectionProposal(
//              _unitFile,
//              packageName,
//              FixKind.ADD_PACKAGE_DEPENDENCY,
//              [packageName]));
//    }
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
      String eol = utils.endOfLine;
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
    // TODO(scheglov) implement
//    ClassDeclaration targetClassNode = node.parent as ClassDeclaration;
//    ClassElement targetClassElement = targetClassNode.element;
//    ClassElement superClassElement = targetClassElement.supertype.element;
//    String targetClassName = targetClassElement.name;
//    // add proposals for all super constructors
//    List<ConstructorElement> superConstructors = superClassElement.constructors;
//    for (ConstructorElement superConstructor in superConstructors) {
//      String constructorName = superConstructor.name;
//      // skip private
//      if (Identifier.isPrivateName(constructorName)) {
//        continue;
//      }
//      // prepare parameters and arguments
//      JavaStringBuilder parametersBuffer = new JavaStringBuilder();
//      JavaStringBuilder argumentsBuffer = new JavaStringBuilder();
//      bool firstParameter = true;
//      for (ParameterElement parameter in superConstructor.parameters) {
//        // skip non-required parameters
//        if (parameter.parameterKind != ParameterKind.REQUIRED) {
//          break;
//        }
//        // comma
//        if (firstParameter) {
//          firstParameter = false;
//        } else {
//          parametersBuffer.append(", ");
//          argumentsBuffer.append(", ");
//        }
//        // name
//        String parameterName = parameter.displayName;
//        if (parameterName.length > 1 && parameterName.startsWith("_")) {
//          parameterName = parameterName.substring(1);
//        }
//        // parameter & argument
//        _appendParameterSource(parametersBuffer, parameter.type, parameterName);
//        argumentsBuffer.append(parameterName);
//      }
//      // add proposal
//      String eol = utils.endOfLine;
//      QuickFixProcessorImpl_NewConstructorLocation targetLocation =
//          _prepareNewConstructorLocation(targetClassNode, eol);
//      SourceBuilder sb = new SourceBuilder.con1(targetLocation._offset);
//      {
//        String indent = utils.getIndent(1);
//        sb.append(targetLocation._prefix);
//        sb.append(indent);
//        sb.append(targetClassName);
//        if (!constructorName.isEmpty) {
//          sb.startPosition("NAME");
//          sb.append(".");
//          sb.append(constructorName);
//          sb.endPosition();
//        }
//        sb.append("(");
//        sb.append(parametersBuffer.toString());
//        sb.append(") : super");
//        if (!constructorName.isEmpty) {
//          sb.append(".");
//          sb.append(constructorName);
//        }
//        sb.append("(");
//        sb.append(argumentsBuffer.toString());
//        sb.append(");");
//        sb.append(targetLocation._suffix);
//      }
//      _addInsertEdit3(sb);
//      // add proposal
//      String proposalName = _getConstructorProposalName(superConstructor);
//      _addFix(
//          FixKind.CREATE_CONSTRUCTOR_SUPER,
//          [proposalName]);
//    }
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
    // prepare environment
    String eol = utils.endOfLine;
    // prepare target
    DartType targetType = typeName.type;
    if (targetType is! InterfaceType) {
      return;
    }
    ClassElement targetElement = targetType.element as ClassElement;
    String targetFile = targetElement.source.fullName;
    ClassDeclaration targetClass = targetElement.node;
    QuickFixProcessorImpl_NewConstructorLocation targetLocation =
        _prepareNewConstructorLocation(targetClass, eol);
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
    // prepare environment
    String eol = utils.endOfLine;
    // prepare target interface type
    DartType targetType = constructorName.type.type;
    if (targetType is! InterfaceType) {
      return;
    }
    ClassElement targetElement = targetType.element as ClassElement;
    String targetFile = targetElement.source.fullName;
    ClassDeclaration targetClass = targetElement.node;
    QuickFixProcessorImpl_NewConstructorLocation targetLocation =
        _prepareNewConstructorLocation(targetClass, eol);
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
    // TODO(scheglov) implement
//    if (node is SimpleIdentifier) {
//      SimpleIdentifier nameNode = node as SimpleIdentifier;
//      // prepare argument expression (to get parameter)
//      ClassElement targetElement;
//      Expression argument;
//      {
//        Expression target = CorrectionUtils.getQualifiedPropertyTarget(node);
//        if (target != null) {
//          DartType targetType = target.bestType;
//          if (targetType != null && targetType.element is ClassElement) {
//            targetElement = targetType.element as ClassElement;
//            argument = target.parent as Expression;
//          } else {
//            return;
//          }
//        } else {
//          ClassDeclaration enclosingClass =
//              node.getAncestor((node) => node is ClassDeclaration);
//          targetElement = enclosingClass != null ?
//              enclosingClass.element :
//              null;
//          argument = nameNode;
//        }
//      }
//      // should be argument of some invocation
//      ParameterElement parameterElement = argument.bestParameterElement;
//      if (parameterElement == null) {
//        return;
//      }
//      // should be parameter of function type
//      DartType parameterType = parameterElement.type;
//      if (parameterType is! FunctionType) {
//        return;
//      }
//      FunctionType functionType = parameterType as FunctionType;
//      // add proposal
//      if (targetElement != null) {
//        _addProposal_createFunction_method(targetElement, functionType);
//      } else {
//        _addProposal_createFunction_function(functionType);
//      }
//    }
  }

  void
      _addFix_createMissingOverrides(List<ExecutableElement> missingOverrides) {
    // TODO(scheglov) implement
//    // sort by name
//    missingOverrides.sort(
//        (Element firstElement, Element secondElement) =>
//            ObjectUtils.compare(firstElement.displayName, secondElement.displayName));
//    // add elements
//    ClassDeclaration targetClass = node.parent as ClassDeclaration;
//    bool isFirst = true;
//    for (ExecutableElement missingOverride in missingOverrides) {
//      _addFix_createMissingOverrides_single(
//          targetClass,
//          missingOverride,
//          isFirst);
//      isFirst = false;
//    }
//    // add proposal
//    _addFix(
//        FixKind.CREATE_MISSING_OVERRIDES,
//        [missingOverrides.length]);
  }

  void _addFix_createMissingOverrides_single(ClassDeclaration targetClass,
      ExecutableElement missingOverride, bool isFirst) {
    // TODO(scheglov) implement
//    // prepare environment
//    String eol = utils.endOfLine;
//    String prefix = utils.getIndent(1);
//    String prefix2 = utils.getIndent(2);
//    int insertOffset = targetClass.end - 1;
//    // prepare source
//    JavaStringBuilder sb = new JavaStringBuilder();
//    // may be empty line
//    if (!isFirst || !targetClass.members.isEmpty) {
//      sb.append(eol);
//    }
//    // may be property
//    ElementKind elementKind = missingOverride.kind;
//    bool isGetter = elementKind == ElementKind.GETTER;
//    bool isSetter = elementKind == ElementKind.SETTER;
//    bool isMethod = elementKind == ElementKind.METHOD;
//    bool isOperator = isMethod && (missingOverride as MethodElement).isOperator;
//    sb.append(prefix);
//    if (isGetter) {
//      sb.append("// TODO: implement ${missingOverride.displayName}");
//      sb.append(eol);
//      sb.append(prefix);
//    }
//    // @override
//    {
//      sb.append("@override");
//      sb.append(eol);
//      sb.append(prefix);
//    }
//    // return type
//    _appendType(sb, missingOverride.type.returnType);
//    if (isGetter) {
//      sb.append("get ");
//    } else if (isSetter) {
//      sb.append("set ");
//    } else if (isOperator) {
//      sb.append("operator ");
//    }
//    // name
//    sb.append(missingOverride.displayName);
//    // parameters + body
//    if (isGetter) {
//      sb.append(" => null;");
//    } else if (isMethod || isSetter) {
//      List<ParameterElement> parameters = missingOverride.parameters;
//      _appendParameters(sb, parameters);
//      sb.append(" {");
//      // TO-DO
//      sb.append(eol);
//      sb.append(prefix2);
//      if (isMethod) {
//        sb.append("// TODO: implement ${missingOverride.displayName}");
//      } else {
//        sb.append("// TODO: implement ${missingOverride.displayName}");
//      }
//      sb.append(eol);
//      // close method
//      sb.append(prefix);
//      sb.append("}");
//    }
//    sb.append(eol);
//    // done
//    _addInsertEdit(insertOffset, sb.toString());
//    // maybe set end range
//    if (_endRange == null) {
//      _endRange = SourceRangeFactory.rangeStartLength(insertOffset, 0);
//    }
  }

  void _addFix_createNoSuchMethod() {
    // TODO(scheglov) implement
//    ClassDeclaration targetClass = node.parent as ClassDeclaration;
//    // prepare environment
//    String eol = utils.endOfLine;
//    String prefix = utils.getIndent(1);
//    int insertOffset = targetClass.end - 1;
//    // prepare source
//    SourceBuilder sb = new SourceBuilder.con1(insertOffset);
//    {
//      // insert empty line before existing member
//      if (!targetClass.members.isEmpty) {
//        sb.append(eol);
//      }
//      // append method
//      sb.append(prefix);
//      sb.append(
//          "noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);");
//      sb.append(eol);
//    }
//    // done
//    _addInsertEdit3(sb);
//    _endRange = SourceRangeFactory.rangeStartLength(insertOffset, 0);
//    // add proposal
//    _addFix(FixKind.CREATE_NO_SUCH_METHOD, []);
  }

  void _addFix_createPart() {
    // TODO(scheglov) implement
//    if (node is SimpleStringLiteral && node.parent is PartDirective) {
//      SimpleStringLiteral uriLiteral = node as SimpleStringLiteral;
//      String uriString = uriLiteral.value;
//      // prepare referenced File
//      JavaFile newFile;
//      {
//        Uri uri = parseUriWithException(uriString);
//        if (uri.isAbsolute) {
//          return;
//        }
//        newFile = new JavaFile.relative(_unitLibraryFolder, uriString);
//      }
//      if (!newFile.exists()) {
//        // prepare new source
//        String source;
//        {
//          String eol = utils.endOfLine;
//          String libraryName = _unitLibraryElement.displayName;
//          source = "part of ${libraryName};${eol}${eol}";
//        }
//        // add proposal
//        _proposals.add(
//            new CreateFileCorrectionProposal(
//                newFile,
//                source,
//                FixKind.CREATE_PART,
//                [uriString]));
//      }
//    }
  }

  void _addFix_importLibrary(FixKind kind, String importPath) {
    // TODO(scheglov) implement
//    CompilationUnitElement libraryUnitElement =
//        _unitLibraryElement.definingCompilationUnit;
//    CompilationUnit libraryUnit = libraryUnitElement.node;
//    // prepare new import location
//    int offset = 0;
//    String prefix;
//    String suffix;
//    {
//      String eol = utils.endOfLine;
//      // if no directives
//      prefix = "";
//      suffix = eol;
//      CorrectionUtils libraryUtils = new CorrectionUtils(libraryUnit);
//      // after last directive in library
//      for (Directive directive in libraryUnit.directives) {
//        if (directive is LibraryDirective || directive is ImportDirective) {
//          offset = directive.end;
//          prefix = eol;
//          suffix = "";
//        }
//      }
//      // if still beginning of file, skip shebang and line comments
//      if (offset == 0) {
//        CorrectionUtils_InsertDesc desc = libraryUtils.insertDescTop;
//        offset = desc.offset;
//        prefix = desc.prefix;
//        suffix = "${desc.suffix}${eol}";
//      }
//    }
//    // insert new import
//    String importSource = "${prefix}import '${importPath}';${suffix}";
//    _addInsertEdit(offset, importSource);
//    // add proposal
//    _addUnitCorrectionProposal2(libraryUnitElement.source, kind, [importPath]);
  }

  void _addFix_importLibrary_withElement(String name, ElementKind kind) {
    // TODO(scheglov) implement
//    // ignore if private
//    if (name.startsWith("_")) {
//      return;
//    }
//    // may be there is an existing import, but it is with prefix and we don't use this prefix
//    for (ImportElement imp in _unitLibraryElement.imports) {
//      // prepare element
//      LibraryElement libraryElement = imp.importedLibrary;
//      Element element =
//          CorrectionUtils.getExportedElement(libraryElement, name);
//      if (element == null) {
//        continue;
//      }
//      if (element is PropertyAccessorElement) {
//        element = (element as PropertyAccessorElement).variable;
//      }
//      if (element.kind != kind) {
//        continue;
//      }
//      // may be apply prefix
//      PrefixElement prefix = imp.prefix;
//      if (prefix != null) {
//        SourceRange range = SourceRangeFactory.rangeStartLength(node, 0);
//        _addReplaceEdit(range, "${prefix.displayName}.");
//        _addFix(
//            FixKind.IMPORT_LIBRARY_PREFIX,
//            [libraryElement.displayName, prefix.displayName]);
//        continue;
//      }
//      // may be update "show" directive
//      List<NamespaceCombinator> combinators = imp.combinators;
//      if (combinators.length == 1 && combinators[0] is ShowElementCombinator) {
//        ShowElementCombinator showCombinator =
//            combinators[0] as ShowElementCombinator;
//        // prepare new set of names to show
//        Set<String> showNames = new Set<String>();
//        showNames.addAll(showCombinator.shownNames);
//        showNames.add(name);
//        // prepare library name - unit name or 'dart:name' for SDK library
//        String libraryName = libraryElement.definingCompilationUnit.displayName;
//        if (libraryElement.isInSdk) {
//          libraryName = imp.uri;
//        }
//        // update library
//        String newShowCode = "show ${StringUtils.join(showNames, ", ")}";
//        // TODO(scheglov)
//        _addReplaceEdit(
//            SourceRangeFactory.rangeShowCombinator(showCombinator),
//            newShowCode);
//        _addUnitCorrectionProposal2(
//            _unitLibraryElement.source,
//            FixKind.IMPORT_LIBRARY_SHOW,
//            [libraryName]);
//        // we support only one import without prefix
//        return;
//      }
//    }
//    // check SDK libraries
//    AnalysisContext context = _unitLibraryElement.context;
//    {
//      DartSdk sdk = context.sourceFactory.dartSdk;
//      List<SdkLibrary> sdkLibraries = sdk.sdkLibraries;
//      for (SdkLibrary sdkLibrary in sdkLibraries) {
//        SourceFactory sdkSourceFactory = context.sourceFactory;
//        String libraryUri = sdkLibrary.shortName;
//        Source librarySource = sdkSourceFactory.resolveUri(null, libraryUri);
//        // prepare LibraryElement
//        LibraryElement libraryElement =
//            context.getLibraryElement(librarySource);
//        if (libraryElement == null) {
//          continue;
//        }
//        // prepare exported Element
//        Element element =
//            CorrectionUtils.getExportedElement(libraryElement, name);
//        if (element == null) {
//          continue;
//        }
//        if (element is PropertyAccessorElement) {
//          element = (element as PropertyAccessorElement).variable;
//        }
//        if (element.kind != kind) {
//          continue;
//        }
//        // add import
//        _addFix_importLibrary(FixKind.IMPORT_LIBRARY_SDK, libraryUri);
//      }
//    }
//    // check project libraries
//    {
//      List<Source> librarySources = context.librarySources;
//      for (Source librarySource in librarySources) {
//        // we don't need SDK libraries here
//        if (librarySource.isInSystemLibrary) {
//          continue;
//        }
//        // prepare LibraryElement
//        LibraryElement libraryElement =
//            context.getLibraryElement(librarySource);
//        if (libraryElement == null) {
//          continue;
//        }
//        // prepare exported Element
//        Element element =
//            CorrectionUtils.getExportedElement(libraryElement, name);
//        if (element == null) {
//          continue;
//        }
//        if (element.kind != kind) {
//          continue;
//        }
//        // prepare "library" file
//        JavaFile libraryFile = getSourceFile(librarySource);
//        if (libraryFile == null) {
//          continue;
//        }
//        // may be "package:" URI
//        {
//          Uri libraryPackageUri = _findPackageUri(context, libraryFile);
//          if (libraryPackageUri != null) {
//            _addFix_importLibrary(
//                FixKind.IMPORT_LIBRARY_PROJECT,
//                libraryPackageUri.toString());
//            continue;
//          }
//        }
//        // relative URI
//        String relative =
//            URIUtils.computeRelativePath(
//                _unitLibraryFolder.getAbsolutePath(),
//                libraryFile.getAbsolutePath());
//        _addFix_importLibrary(
//            FixKind.IMPORT_LIBRARY_PROJECT,
//            relative);
//      }
//    }
  }

  void _addFix_importLibrary_withFunction() {
    // TODO(scheglov) implement
//    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
//      MethodInvocation invocation = node.parent as MethodInvocation;
//      if (invocation.realTarget == null &&
//          identical(invocation.methodName, node)) {
//        String name = (node as SimpleIdentifier).name;
//        _addFix_importLibrary_withElement(name, ElementKind.FUNCTION);
//      }
//    }
  }

  void _addFix_importLibrary_withTopLevelVariable() {
    // TODO(scheglov) implement
//    if (node is SimpleIdentifier) {
//      String name = (node as SimpleIdentifier).name;
//      _addFix_importLibrary_withElement(name, ElementKind.TOP_LEVEL_VARIABLE);
//    }
  }

  void _addFix_importLibrary_withType() {
    // TODO(scheglov) implement
//    if (_mayBeTypeIdentifier(node)) {
//      String typeName = (node as SimpleIdentifier).name;
//      _addFix_importLibrary_withElement(typeName, ElementKind.CLASS);
//    }
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
    // TODO(scheglov) implement
//    if (_mayBeTypeIdentifier(node)) {
//      String name = (node as SimpleIdentifier).name;
//      QuickFixProcessorImpl_ClosestElementFinder finder =
//          new QuickFixProcessorImpl_ClosestElementFinder(
//              name,
//              new Predicate_QuickFixProcessorImpl_addFix_undefinedClass_useSimilar());
//      // find closest element
//      {
//        // elements of this library
//        _unitLibraryElement.accept(
//            new RecursiveElementVisitor_QuickFixProcessorImpl_addFix_undefinedClass_useSimilar(
//                finder));
//        // elements from imports
//        for (ImportElement importElement in _unitLibraryElement.imports) {
//          if (importElement.prefix == null) {
//            Map<String, Element> namespace =
//                CorrectionUtils.getImportNamespace(importElement);
//            finder._update2(namespace.values);
//          }
//        }
//      }
//      // if we have close enough element, suggest to use it
//      if (finder != null && finder._distance < 5) {
//        String closestName = finder._element.name;
//        _addReplaceEdit(SourceRangeFactory.rangeNode(node), closestName);
//        // add proposal
//        if (closestName != null) {
//          _addFix(
//              FixKind.CHANGE_TO,
//              [closestName]);
//        }
//      }
//    }
  }

  void _addFix_undefinedFunction_create() {
    // TODO(scheglov) implement
//    // should be the name of the invocation
//    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
//    } else {
//      return;
//    }
//    String name = (node as SimpleIdentifier).name;
//    MethodInvocation invocation = node.parent as MethodInvocation;
//    // function invocation has no target
//    Expression target = invocation.realTarget;
//    if (target != null) {
//      return;
//    }
//    // prepare environment
//    String eol = utils.endOfLine;
//    int insertOffset;
//    String sourcePrefix;
//    AstNode enclosingMember =
//        node.getAncestor((node) => node is CompilationUnitMember);
//    insertOffset = enclosingMember.end;
//    sourcePrefix = "${eol}${eol}";
//    // build method source
//    SourceBuilder sb = new SourceBuilder.con1(insertOffset);
//    {
//      sb.append(sourcePrefix);
//      // may be return type
//      {
//        DartType type =
//            _addFix_undefinedMethod_create_getReturnType(invocation);
//        if (type != null) {
//          String typeSource = utils.getTypeSource2(type);
//          if (typeSource != "dynamic") {
//            sb.startPosition("RETURN_TYPE");
//            sb.append(typeSource);
//            sb.endPosition();
//            sb.append(" ");
//          }
//        }
//      }
//      // append name
//      {
//        sb.startPosition("NAME");
//        sb.append(name);
//        sb.endPosition();
//      }
//      _addFix_undefinedMethod_create_parameters(sb, invocation.argumentList);
//      sb.append(") {${eol}}");
//    }
//    // insert source
//    _addInsertEdit(insertOffset, sb.toString());
//    // add linked positions
//    _addLinkedPosition("NAME", sb, SourceRangeFactory.rangeNode(node));
//    _addLinkedPositions(sb);
//    // add proposal
//    _addFix(FixKind.CREATE_FUNCTION, [name]);
  }

  void _addFix_undefinedFunction_useSimilar() {
    // TODO(scheglov) implement
//    if (node is SimpleIdentifier) {
//      String name = (node as SimpleIdentifier).name;
//      QuickFixProcessorImpl_ClosestElementFinder finder =
//          new QuickFixProcessorImpl_ClosestElementFinder(
//              name,
//              new Predicate_QuickFixProcessorImpl_addFix_undefinedFunction_useSimilar());
//      // this library
//      _unitLibraryElement.accept(
//          new RecursiveElementVisitor_QuickFixProcessorImpl_addFix_undefinedFunction_useSimilar(
//              finder));
//      // imports
//      for (ImportElement importElement in _unitLibraryElement.imports) {
//        if (importElement.prefix == null) {
//          Map<String, Element> namespace =
//              CorrectionUtils.getImportNamespace(importElement);
//          finder._update2(namespace.values);
//        }
//      }
//      // if we have close enough element, suggest to use it
//      String closestName = null;
//      if (finder != null && finder._distance < 5) {
//        closestName = finder._element.name;
//        _addReplaceEdit(SourceRangeFactory.rangeNode(node), closestName);
//        _addFix(FixKind.CHANGE_TO, [closestName]);
//      }
//    }
  }

  void _addFix_undefinedMethod_create() {
    // TODO(scheglov) implement
//    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
//      String name = (node as SimpleIdentifier).name;
//      MethodInvocation invocation = node.parent as MethodInvocation;
//      // prepare environment
//      String eol = utils.endOfLine;
//      Source targetSource;
//      String prefix;
//      int insertOffset;
//      String sourcePrefix;
//      String sourceSuffix;
//      bool staticModifier = false;
//      Expression target = invocation.realTarget;
//      if (target == null) {
//        targetSource = _source;
//        ClassMember enclosingMember =
//            node.getAncestor((node) => node is ClassMember);
//        staticModifier = _inStaticMemberContext2(enclosingMember);
//        prefix = utils.getNodePrefix(enclosingMember);
//        insertOffset = enclosingMember.end;
//        sourcePrefix = "${eol}${prefix}${eol}";
//        sourceSuffix = "";
//      } else {
//        // prepare target interface type
//        DartType targetType = target.bestType;
//        if (targetType is! InterfaceType) {
//          return;
//        }
//        ClassElement targetElement = targetType.element as ClassElement;
//        targetSource = targetElement.source;
//        // may be static
//        if (target is Identifier) {
//          staticModifier = target.bestElement.kind == ElementKind.CLASS;
//        }
//        // prepare insert offset
//        ClassDeclaration targetClass = targetElement.node;
//        prefix = "  ";
//        insertOffset = targetClass.end - 1;
//        if (targetClass.members.isEmpty) {
//          sourcePrefix = "";
//        } else {
//          sourcePrefix = "${prefix}${eol}";
//        }
//        sourceSuffix = eol;
//      }
//      // build method source
//      SourceBuilder sb = new SourceBuilder.con1(insertOffset);
//      {
//        sb.append(sourcePrefix);
//        sb.append(prefix);
//        // may be "static"
//        if (staticModifier) {
//          sb.append("static ");
//        }
//        // may be return type
//        {
//          DartType type =
//              _addFix_undefinedMethod_create_getReturnType(invocation);
//          if (type != null) {
//            String typeSource = utils.getTypeSource2(type);
//            if (typeSource != "dynamic") {
//              sb.startPosition("RETURN_TYPE");
//              sb.append(typeSource);
//              sb.endPosition();
//              sb.append(" ");
//            }
//          }
//        }
//        // append name
//        {
//          sb.startPosition("NAME");
//          sb.append(name);
//          sb.endPosition();
//        }
//        _addFix_undefinedMethod_create_parameters(sb, invocation.argumentList);
//        sb.append(") {${eol}${prefix}}");
//        sb.append(sourceSuffix);
//      }
//      // insert source
//      _addInsertEdit(insertOffset, sb.toString());
//      // add linked positions
//      if (targetSource == _source) {
//        _addLinkedPosition("NAME", sb, SourceRangeFactory.rangeNode(node));
//      }
//      _addLinkedPositions(sb);
//      // add proposal
//      _addUnitCorrectionProposal2(
//          targetSource,
//          FixKind.CREATE_METHOD,
//          [name]);
//    }
  }

  /**
   * @return the possible return [Type], may be <code>null</code> if can not be identified.
   */
  DartType
      _addFix_undefinedMethod_create_getReturnType(MethodInvocation invocation) {
    // TODO(scheglov) implement
//    AstNode parent = invocation.parent;
//    // myFunction();
//    if (parent is ExpressionStatement) {
//      return VoidTypeImpl.instance;
//    }
//    // return myFunction();
//    if (parent is ReturnStatement) {
//      ExecutableElement executable =
//          CorrectionUtils.getEnclosingExecutableElement(invocation);
//      return executable != null ? executable.returnType : null;
//    }
//    // int v = myFunction();
//    if (parent is VariableDeclaration) {
//      VariableDeclaration variableDeclaration = parent;
//      if (identical(variableDeclaration.initializer, invocation)) {
//        VariableElement variableElement = variableDeclaration.element;
//        if (variableElement != null) {
//          return variableElement.type;
//        }
//      }
//    }
//    // v = myFunction();
//    if (parent is AssignmentExpression) {
//      AssignmentExpression assignment = parent;
//      if (identical(assignment.rightHandSide, invocation)) {
//        if (assignment.operator.type == TokenType.EQ) {
//          // v = myFunction();
//          Expression lhs = assignment.leftHandSide;
//          if (lhs != null) {
//            return lhs.bestType;
//          }
//        } else {
//          // v += myFunction();
//          MethodElement method = assignment.bestElement;
//          if (method != null) {
//            List<ParameterElement> parameters = method.parameters;
//            if (parameters.length == 1) {
//              return parameters[0].type;
//            }
//          }
//        }
//      }
//    }
//    // v + myFunction();
//    if (parent is BinaryExpression) {
//      BinaryExpression binary = parent;
//      MethodElement method = binary.bestElement;
//      if (method != null) {
//        if (identical(binary.rightOperand, invocation)) {
//          List<ParameterElement> parameters = method.parameters;
//          return parameters.length == 1 ? parameters[0].type : null;
//        }
//      }
//    }
//    // foo( myFunction() );
//    if (parent is ArgumentList) {
//      ParameterElement parameter = invocation.bestParameterElement;
//      return parameter != null ? parameter.type : null;
//    }
//    // bool
//    {
//      // assert( myFunction() );
//      if (parent is AssertStatement) {
//        AssertStatement statement = parent;
//        if (identical(statement.condition, invocation)) {
//          return coreTypeBool;
//        }
//      }
//      // if ( myFunction() ) {}
//      if (parent is IfStatement) {
//        IfStatement statement = parent;
//        if (identical(statement.condition, invocation)) {
//          return coreTypeBool;
//        }
//      }
//      // while ( myFunction() ) {}
//      if (parent is WhileStatement) {
//        WhileStatement statement = parent;
//        if (identical(statement.condition, invocation)) {
//          return coreTypeBool;
//        }
//      }
//      // do {} while ( myFunction() );
//      if (parent is DoStatement) {
//        DoStatement statement = parent;
//        if (identical(statement.condition, invocation)) {
//          return coreTypeBool;
//        }
//      }
//      // !myFunction()
//      if (parent is PrefixExpression) {
//        PrefixExpression prefixExpression = parent;
//        if (prefixExpression.operator.type == TokenType.BANG) {
//          return coreTypeBool;
//        }
//      }
//      // binary expression '&&' or '||'
//      if (parent is BinaryExpression) {
//        BinaryExpression binaryExpression = parent;
//        TokenType operatorType = binaryExpression.operator.type;
//        if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
//            operatorType == TokenType.BAR_BAR) {
//          return coreTypeBool;
//        }
//      }
//    }
    // we don't know
    return null;
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
        sb.addProposals(suggestions);
        sb.endPosition();
      }
    }
  }

  void _addFix_undefinedMethod_useSimilar() {
    // TODO(scheglov) implement
//    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
//      MethodInvocation invocation = node.parent as MethodInvocation;
//      String name = (node as SimpleIdentifier).name;
//      QuickFixProcessorImpl_ClosestElementFinder finder =
//          new QuickFixProcessorImpl_ClosestElementFinder(
//              name,
//              new Predicate_QuickFixProcessorImpl_addFix_undefinedMethod_useSimilar());
//      // unqualified invocation
//      Expression target = invocation.realTarget;
//      if (target == null) {
//        ClassDeclaration clazz =
//            invocation.getAncestor((node) => node is ClassDeclaration);
//        if (clazz != null) {
//          ClassElement classElement = clazz.element;
//          _updateFinderWithClassMembers(finder, classElement);
//        }
//      } else {
//        DartType type = target.bestType;
//        if (type is InterfaceType) {
//          ClassElement classElement = type.element;
//          _updateFinderWithClassMembers(finder, classElement);
//        }
//      }
//      // if we have close enough element, suggest to use it
//      String closestName = null;
//      if (finder != null && finder._distance < 5) {
//        closestName = finder._element.name;
//        _addReplaceEdit(SourceRangeFactory.rangeNode(node), closestName);
//        _addFix(FixKind.CHANGE_TO, [closestName]);
//      }
//    }
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
    _addLinkedPosition2(
        groupId,
        new Position(file, range.offset, range.length));
  }

  /**
   * Adds a single linked position to [groupId].
   */
  void _addLinkedPosition2(String groupId, Position position) {
    LinkedPositionGroup group = linkedPositionGroups[groupId];
    if (group == null) {
      group = new LinkedPositionGroup(groupId);
      linkedPositionGroups[groupId] = group;
    }
    group.add(position);
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

  void _appendParameterSource(StringBuffer sb, DartType type, String name) {
    String parameterSource = utils.getParameterSource(type, name);
    sb.write(parameterSource);
  }

  void _appendParameters(StringBuffer sb, List<ParameterElement> parameters,
      Map<ParameterElement, String> defaultValueMap) {
    sb.write("(");
    bool firstParameter = true;
    bool sawNamed = false;
    bool sawPositional = false;
    for (ParameterElement parameter in parameters) {
      if (!firstParameter) {
        sb.write(", ");
      } else {
        firstParameter = false;
      }
      // may be optional
      ParameterKind parameterKind = parameter.parameterKind;
      if (parameterKind == ParameterKind.NAMED) {
        if (!sawNamed) {
          sb.write("{");
          sawNamed = true;
        }
      }
      if (parameterKind == ParameterKind.POSITIONAL) {
        if (!sawPositional) {
          sb.write("[");
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
            sb.write(" = ");
          } else {
            sb.write(": ");
          }
          sb.write(defaultSource);
        }
      }
    }
    // close parameters
    if (sawNamed) {
      sb.write("}");
    }
    if (sawPositional) {
      sb.write("]");
    }
    sb.write(")");
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

  /**
   * @return the string to display as the name of the given constructor in a proposal name.
   */
  String _getConstructorProposalName(ConstructorElement constructor) {
    StringBuffer proposalNameBuffer = new StringBuffer();
    proposalNameBuffer.write("super");
    // may be named
    String constructorName = constructor.displayName;
    if (!constructorName.isEmpty) {
      proposalNameBuffer.write(".");
      proposalNameBuffer.write(constructorName);
    }
    // parameters
    _appendParameters(proposalNameBuffer, constructor.parameters, null);
    // done
    return proposalNameBuffer.toString();
  }

  /**
   * Inserts the given [SourceBuilder] at its offset.
   */
  void _insertBuilder(SourceBuilder builder) {
    String text = builder.toString();
    _addInsertEdit(builder.offset, text);
    // add linked positions
    builder.linkedPositionGroups.forEach((LinkedPositionGroup group) {
      group.positions.forEach((Position position) {
        _addLinkedPosition2(group.id, position);
      });
    });
  }

  QuickFixProcessorImpl_NewConstructorLocation
      _prepareNewConstructorLocation(ClassDeclaration classDeclaration, String eol) {
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
      return new QuickFixProcessorImpl_NewConstructorLocation(
          "${eol}${eol}",
          lastFieldOrConstructor.end,
          "");
    }
    // at the beginning of the class
    String suffix = members.isEmpty ? "" : eol;
    return new QuickFixProcessorImpl_NewConstructorLocation(
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

  static void _addSuperTypeProposals(SourceBuilder sb,
      Set<DartType> alreadyAdded, DartType type) {
    if (type != null &&
        !alreadyAdded.contains(type) &&
        type.element is ClassElement) {
      alreadyAdded.add(type);
      ClassElement element = type.element as ClassElement;
      sb.addProposal(element.name);
      _addSuperTypeProposals(sb, alreadyAdded, element.supertype);
      for (InterfaceType interfaceType in element.interfaces) {
        _addSuperTypeProposals(sb, alreadyAdded, interfaceType);
      }
    }
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
 * Describes the location for a newly created [ConstructorDeclaration].
 *
 * TODO(scheglov) rename
 */
class QuickFixProcessorImpl_NewConstructorLocation {
  final String _prefix;
  final int _offset;
  final String _suffix;

  QuickFixProcessorImpl_NewConstructorLocation(this._prefix, this._offset,
      this._suffix);
}
