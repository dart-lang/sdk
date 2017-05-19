// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:charcode/ascii.dart';
import 'package:path/path.dart' as path;

/**
 * A [ChangeBuilder] used to build changes in Dart files.
 */
class DartChangeBuilderImpl extends ChangeBuilderImpl
    implements DartChangeBuilder {
  /**
   * The analysis driver in which the files being edited were analyzed.
   */
  final AnalysisDriver driver;

  /**
   * Initialize a newly created change builder.
   */
  DartChangeBuilderImpl(this.driver);

  @override
  Future<DartFileEditBuilderImpl> createFileEditBuilder(
      String path, int fileStamp) async {
    AnalysisResult result = await driver.getResult(path);
    return new DartFileEditBuilderImpl(this, path, fileStamp, result.unit);
  }
}

/**
 * An [EditBuilder] used to build edits in Dart files.
 */
class DartEditBuilderImpl extends EditBuilderImpl implements DartEditBuilder {
  List<String> _KNOWN_METHOD_NAME_PREFIXES = ['get', 'is', 'to'];

  /**
   * Initialize a newly created builder to build a source edit.
   */
  DartEditBuilderImpl(
      DartFileEditBuilderImpl sourceFileEditBuilder, int offset, int length)
      : super(sourceFileEditBuilder, offset, length);

  DartFileEditBuilderImpl get dartFileEditBuilder => fileEditBuilder;

  @override
  LinkedEditBuilderImpl createLinkedEditBuilder() {
    return new DartLinkedEditBuilderImpl(this);
  }

  /**
   * Returns the indentation with the given [level].
   */
  String getIndent(int level) => '  ' * level;

  /**
   * Arrange to have an import added for the given [library].
   */
  void importLibrary(Source library) {
    dartFileEditBuilder.librariesToImport.add(library);
  }

  @override
  void writeClassDeclaration(String name,
      {Iterable<DartType> interfaces,
      bool isAbstract: false,
      void memberWriter(),
      Iterable<DartType> mixins,
      String nameGroupName,
      DartType superclass,
      String superclassGroupName}) {
    // TODO(brianwilkerson) Add support for type parameters, probably as a
    // parameterWriter parameter.
    if (isAbstract) {
      write(Keyword.ABSTRACT.lexeme);
      write(' ');
    }
    write('class ');
    if (nameGroupName == null) {
      write(name);
    } else {
      addLinkedEdit(nameGroupName, (LinkedEditBuilder builder) {
        write(name);
      });
    }
    if (superclass != null) {
      write(' extends ');
      writeType(superclass, groupName: superclassGroupName);
    } else if (mixins != null && mixins.isNotEmpty) {
      write(' extends Object ');
    }
    writeTypes(mixins, prefix: ' with ');
    writeTypes(interfaces, prefix: ' implements ');
    writeln(' {');
    if (memberWriter != null) {
      writeln();
      memberWriter();
      writeln();
    }
    write('}');
  }

  @override
  void writeConstructorDeclaration(String className,
      {ArgumentList argumentList,
      SimpleIdentifier constructorName,
      String constructorNameGroupName,
      List<String> fieldNames,
      bool isConst: false}) {
    if (isConst) {
      write(Keyword.CONST.lexeme);
      write(' ');
    }
    write(className);
    if (constructorName != null) {
      write('.');
      if (constructorNameGroupName == null) {
        write(constructorName.name);
      } else {
        addLinkedEdit(constructorNameGroupName, (LinkedEditBuilder builder) {
          write(constructorName.name);
        });
      }
    }
    write('(');
    if (argumentList != null) {
      writeParametersMatchingArguments(argumentList);
    } else if (fieldNames != null) {
      for (int i = 0; i < fieldNames.length; i++) {
        if (i > 0) {
          write(', ');
        }
        write('this.');
        write(fieldNames[i]);
      }
    }
    write(');');
  }

  @override
  void writeFieldDeclaration(String name,
      {void initializerWriter(),
      bool isConst: false,
      bool isFinal: false,
      bool isStatic: false,
      String nameGroupName,
      DartType type,
      String typeGroupName}) {
    if (isStatic) {
      write(Keyword.STATIC.lexeme);
      write(' ');
    }
    bool typeRequired = true;
    if (isConst) {
      write(Keyword.CONST.lexeme);
      typeRequired = false;
    } else if (isFinal) {
      write(Keyword.FINAL.lexeme);
      typeRequired = false;
    }
    if (type != null) {
      writeType(type, groupName: typeGroupName, required: true);
    } else if (typeRequired) {
      write(Keyword.VAR.lexeme);
    }
    write(' ');
    if (nameGroupName != null) {
      addLinkedEdit(nameGroupName, (LinkedEditBuilder builder) {
        write(name);
      });
    } else {
      write(name);
    }
    if (initializerWriter != null) {
      write(' = ');
      initializerWriter();
    }
    write(';');
  }

  @override
  void writeFunctionDeclaration(String name,
      {void bodyWriter(),
      bool isStatic: false,
      String nameGroupName,
      void parameterWriter(),
      DartType returnType,
      String returnTypeGroupName}) {
    if (isStatic) {
      write(Keyword.STATIC.lexeme);
      write(' ');
    }
    if (returnType != null) {
      writeType(returnType, groupName: returnTypeGroupName);
      write(' ');
    }
    if (nameGroupName != null) {
      addLinkedEdit(nameGroupName, (LinkedEditBuilder builder) {
        write(name);
      });
    } else {
      write(name);
    }
    write('(');
    if (parameterWriter != null) {
      parameterWriter();
    }
    write(')');
    if (bodyWriter == null) {
      if (returnType != null) {
        write(' => null;');
      } else {
        write(' {}');
      }
    } else {
      write(' ');
      bodyWriter();
    }
  }

  @override
  void writeGetterDeclaration(String name,
      {void bodyWriter(),
      bool isStatic: false,
      String nameGroupName,
      DartType returnType,
      String returnTypeGroupName}) {
    if (isStatic) {
      write(Keyword.STATIC.lexeme);
      write(' ');
    }
    if (returnType != null && !returnType.isDynamic) {
      writeType(returnType, groupName: returnTypeGroupName);
      write(' ');
    }
    write(Keyword.GET.lexeme);
    write(' ');
    if (nameGroupName != null) {
      addLinkedEdit(nameGroupName, (LinkedEditBuilder builder) {
        write(name);
      });
    } else {
      write(name);
    }
    if (bodyWriter == null) {
      write(' => null;');
    } else {
      write(' ');
      bodyWriter();
    }
  }

  @override
  void writeLocalVariableDeclaration(String name,
      {void initializerWriter(),
      bool isConst: false,
      bool isFinal: false,
      String nameGroupName,
      DartType type,
      String typeGroupName}) {
    bool typeRequired = true;
    if (isConst) {
      write(Keyword.CONST.lexeme);
      typeRequired = false;
    } else if (isFinal) {
      write(Keyword.FINAL.lexeme);
      typeRequired = false;
    }
    if (type != null) {
      if (!typeRequired) {
        // The type is required unless we're written a keyword.
        write(' ');
      }
      writeType(type, groupName: typeGroupName);
    } else if (typeRequired) {
      write(Keyword.VAR.lexeme);
    }
    write(' ');
    if (nameGroupName != null) {
      addLinkedEdit(nameGroupName, (LinkedEditBuilder builder) {
        write(name);
      });
    } else {
      write(name);
    }
    if (initializerWriter != null) {
      write(' = ');
      initializerWriter();
    }
    write(';');
  }

  @override
  void writeOverrideOfInheritedMember(ExecutableElement member,
      {String returnTypeGroupName}) {
    // prepare environment
    String prefix = getIndent(1);
    // may be property
    String prefix2 = getIndent(2);
    ElementKind elementKind = member.kind;
    bool isGetter = elementKind == ElementKind.GETTER;
    bool isSetter = elementKind == ElementKind.SETTER;
    bool isMethod = elementKind == ElementKind.METHOD;
    bool isOperator = isMethod && (member as MethodElement).isOperator;
    write(prefix);
    if (isGetter) {
      writeln('// TODO: implement ${member.displayName}');
      write(prefix);
    }
    // @override
    writeln('@override');
    write(prefix);
    // return type
    bool shouldReturn =
        writeType(member.type.returnType, groupName: returnTypeGroupName);
    write(' ');
    if (isGetter) {
      write(Keyword.GET.lexeme);
      write(' ');
    } else if (isSetter) {
      write(Keyword.SET.lexeme);
      write(' ');
    } else if (isOperator) {
      write(Keyword.OPERATOR.lexeme);
      write(' ');
    }
    // name
    write(member.displayName);
    // parameters + body
    if (isGetter) {
      writeln(' => null;');
    } else {
      List<ParameterElement> parameters = member.parameters;
      writeParameters(parameters);
      writeln(' {');
      // TO-DO
      write(prefix2);
      writeln('// TODO: implement ${member.displayName}');
      // REVIEW: Added return statement.
      if (shouldReturn) {
        write(prefix2);
        writeln('return null;');
      }
      // close method
      write(prefix);
      writeln('}');
    }
  }

  @override
  void writeParameterMatchingArgument(
      Expression argument, int index, Set<String> usedNames) {
    // append type name
    DartType type = argument.bestType;
    if (writeType(type, addSupertypeProposals: true, groupName: 'TYPE$index')) {
      write(' ');
    }
    // append parameter name
    if (argument is NamedExpression) {
      write(argument.name.label.name);
    } else {
      List<String> suggestions =
          _getParameterNameSuggestions(usedNames, type, argument, index);
      String favorite = suggestions[0];
      usedNames.add(favorite);
      addLinkedEdit('PARAM$index', (LinkedEditBuilder builder) {
        write(favorite);
        builder.addSuggestions(LinkedEditSuggestionKind.PARAMETER, suggestions);
      });
    }
  }

  @override
  void writeParameters(Iterable<ParameterElement> parameters) {
    write('(');
    bool sawNamed = false;
    bool sawPositional = false;
    for (int i = 0; i < parameters.length; i++) {
      ParameterElement parameter = parameters.elementAt(i);
      if (i > 0) {
        write(', ');
      }
      // may be optional
      ParameterKind parameterKind = parameter.parameterKind;
      if (parameterKind == ParameterKind.NAMED) {
        if (!sawNamed) {
          write('{');
          sawNamed = true;
        }
      }
      if (parameterKind == ParameterKind.POSITIONAL) {
        if (!sawPositional) {
          write('[');
          sawPositional = true;
        }
      }
      // parameter
      writeParameterSource(parameter.type, parameter.name);
      // default value
      String defaultCode = parameter.defaultValueCode;
      if (defaultCode != null) {
        if (sawPositional) {
          write(' = ');
        } else {
          write(': ');
        }
        write(defaultCode);
      }
    }
    // close parameters
    if (sawNamed) {
      write('}');
    }
    if (sawPositional) {
      write(']');
    }
    write(')');
  }

  @override
  void writeParametersMatchingArguments(ArgumentList argumentList) {
    // TODO(brianwilkerson) Handle the case when there are required parameters
    // after named parameters.
    Set<String> usedNames = new Set<String>();
    List<Expression> arguments = argumentList.arguments;
    bool hasNamedParameters = false;
    for (int i = 0; i < arguments.length; i++) {
      Expression argument = arguments[i];
      if (i > 0) {
        write(', ');
      }
      if (argument is NamedExpression && !hasNamedParameters) {
        hasNamedParameters = true;
        write('{');
      }
      writeParameterMatchingArgument(argument, i, usedNames);
    }
    if (hasNamedParameters) {
      write('}');
    }
  }

  @override
  void writeParameterSource(DartType type, String name) {
    _EnclosingElementFinder finder = new _EnclosingElementFinder();
    finder.find(dartFileEditBuilder.unit, offset);
    String parameterSource = _getParameterSource(
        type, name, finder.enclosingClass, finder.enclosingExecutable);
    write(parameterSource);
  }

  @override
  bool writeType(DartType type,
      {bool addSupertypeProposals: false,
      String groupName,
      bool required: false}) {
    if (type != null && !type.isDynamic) {
      _EnclosingElementFinder finder = new _EnclosingElementFinder();
      finder.find(dartFileEditBuilder.unit, offset);
      String typeSource = _getTypeSource(
          type, finder.enclosingClass, finder.enclosingExecutable);
      if (typeSource != 'dynamic') {
        if (groupName != null) {
          addLinkedEdit(groupName, (LinkedEditBuilder builder) {
            write(typeSource);
            if (addSupertypeProposals) {
              _addSuperTypeProposals(builder, type, new Set<DartType>());
            }
          });
        } else {
          write(typeSource);
        }
        return true;
      }
    }
    if (required) {
      write(Keyword.VAR.lexeme);
      return true;
    }
    return false;
  }

  @override
  void writeTypeParameter(TypeParameterElement typeParameter) {
    write(typeParameter.name);
    if (typeParameter.bound != null) {
      write(' extends ');
      writeType(typeParameter.bound);
    }
  }

  @override
  void writeTypeParameters(List<TypeParameterElement> typeParameters) {
    if (typeParameters.isNotEmpty) {
      write('<');
      bool isFirst = true;
      for (TypeParameterElement typeParameter in typeParameters) {
        if (!isFirst) {
          write(', ');
        }
        isFirst = false;
        writeTypeParameter(typeParameter);
      }
      write('>');
    }
  }

  /**
   * Write the code for a comma-separated list of [types], optionally prefixed
   * by a [prefix]. If the list of [types] is `null` or does not return any
   * types, then nothing will be written.
   */
  void writeTypes(Iterable<DartType> types, {String prefix}) {
    if (types == null || types.isEmpty) {
      return;
    }
    bool first = true;
    for (DartType type in types) {
      if (first) {
        if (prefix != null) {
          write(prefix);
        }
        first = false;
      } else {
        write(', ');
      }
      writeType(type);
    }
  }

  /**
   * Adds [toAdd] items which are not excluded.
   */
  void _addAll(
      Set<String> excluded, Set<String> result, Iterable<String> toAdd) {
    for (String item in toAdd) {
      // add name based on "item", but not "excluded"
      for (int suffix = 1;; suffix++) {
        // prepare name, just "item" or "item2", "item3", etc
        String name = item;
        if (suffix > 1) {
          name += suffix.toString();
        }
        // add once found not excluded
        if (!excluded.contains(name)) {
          result.add(name);
          break;
        }
      }
    }
  }

  /**
   * Adds to [result] either [c] or the first ASCII character after it.
   */
  void _addSingleCharacterName(
      Set<String> excluded, Set<String> result, int c) {
    while (c < $z) {
      String name = new String.fromCharCode(c);
      // may be done
      if (!excluded.contains(name)) {
        result.add(name);
        break;
      }
      // next character
      c = c + 1;
    }
  }

  void _addSuperTypeProposals(
      LinkedEditBuilder builder, DartType type, Set<DartType> alreadyAdded) {
    if (type != null &&
        type.element is ClassElement &&
        alreadyAdded.add(type)) {
      ClassElement element = type.element as ClassElement;
      builder.addSuggestion(LinkedEditSuggestionKind.TYPE, element.name);
      _addSuperTypeProposals(builder, element.supertype, alreadyAdded);
      for (InterfaceType interfaceType in element.interfaces) {
        _addSuperTypeProposals(builder, interfaceType, alreadyAdded);
      }
    }
  }

  String _getBaseNameFromExpression(Expression expression) {
    String name = null;
    // e as Type
    if (expression is AsExpression) {
      AsExpression asExpression = expression as AsExpression;
      expression = asExpression.expression;
    }
    // analyze expressions
    if (expression is SimpleIdentifier) {
      SimpleIdentifier node = expression;
      return node.name;
    } else if (expression is PrefixedIdentifier) {
      PrefixedIdentifier node = expression;
      return node.identifier.name;
    } else if (expression is PropertyAccess) {
      PropertyAccess node = expression;
      return node.propertyName.name;
    } else if (expression is MethodInvocation) {
      name = expression.methodName.name;
    } else if (expression is InstanceCreationExpression) {
      InstanceCreationExpression creation = expression;
      ConstructorName constructorName = creation.constructorName;
      TypeName typeName = constructorName.type;
      if (typeName != null) {
        Identifier typeNameIdentifier = typeName.name;
        // new ClassName()
        if (typeNameIdentifier is SimpleIdentifier) {
          return typeNameIdentifier.name;
        }
        // new prefix.name();
        if (typeNameIdentifier is PrefixedIdentifier) {
          PrefixedIdentifier prefixed = typeNameIdentifier;
          // new prefix.ClassName()
          if (prefixed.prefix.staticElement is PrefixElement) {
            return prefixed.identifier.name;
          }
          // new ClassName.constructorName()
          return prefixed.prefix.name;
        }
      }
    }
    // strip known prefixes
    if (name != null) {
      for (int i = 0; i < _KNOWN_METHOD_NAME_PREFIXES.length; i++) {
        String prefix = _KNOWN_METHOD_NAME_PREFIXES[i];
        if (name.startsWith(prefix)) {
          if (name == prefix) {
            return null;
          } else if (isUpperCase(name.codeUnitAt(prefix.length))) {
            return name.substring(prefix.length);
          }
        }
      }
    }
    // done
    return name;
  }

  String _getBaseNameFromLocationInParent(Expression expression) {
    // value in named expression
    if (expression.parent is NamedExpression) {
      NamedExpression namedExpression = expression.parent as NamedExpression;
      if (namedExpression.expression == expression) {
        return namedExpression.name.label.name;
      }
    }
    // positional argument
    ParameterElement parameter = expression.propagatedParameterElement;
    if (parameter == null) {
      parameter = expression.staticParameterElement;
    }
    if (parameter != null) {
      return parameter.displayName;
    }

    // unknown
    return null;
  }

  /**
   * Returns all variants of names by removing leading words one by one.
   */
  List<String> _getCamelWordCombinations(String name) {
    List<String> result = [];
    List<String> parts = getCamelWords(name);
    for (int i = 0; i < parts.length; i++) {
      String s1 = parts[i].toLowerCase();
      String s2 = parts.skip(i + 1).join();
      String suggestion = '$s1$s2';
      result.add(suggestion);
    }
    return result;
  }

  /**
   * Return the import element used to import the given [element] into the given
   * [library], or `null` if the element was not imported, such as when the
   * element is declared in the same library.
   */
  ImportElement _getImportElement(Element element, LibraryElement library) {
    for (ImportElement importElement in library.imports) {
      Map<String, Element> definedNames = _getImportNamespace(importElement);
      if (definedNames.containsValue(element)) {
        return importElement;
      }
    }
    return null;
  }

  /**
   * Return the namespace added by the given import [element].
   */
  Map<String, Element> _getImportNamespace(ImportElement element) {
    NamespaceBuilder builder = new NamespaceBuilder();
    Namespace namespace = builder.createImportNamespaceForDirective(element);
    return namespace.definedNames;
  }

  /**
   * Return a list containing the suggested names for a parameter with the given
   * [type] whose value in one location is computed by the given [expression].
   * The list will not contain any names in the set of [excluded] names. The
   * [index] is the index of the argument, used to create a name if no better
   * name could be created. The first name in the list will be the best name.
   */
  List<String> _getParameterNameSuggestions(
      Set<String> usedNames, DartType type, Expression expression, int index) {
    List<String> suggestions =
        _getVariableNameSuggestionsForExpression(type, expression, usedNames);
    if (suggestions.length != 0) {
      return suggestions;
    }
    // TODO(brianwilkerson) Verify that the name below is not in the set of used names.
    return <String>['param$index'];
  }

  /**
   * Return the source for the parameter with the given [type] and [name].
   */
  String _getParameterSource(DartType type, String name,
      ClassElement enclosingClass, ExecutableElement enclosingExecutable) {
    // no type
    if (type == null || type.isDynamic) {
      return name;
    }
    // function type
    if (type is FunctionType && type.element.isSynthetic) {
      FunctionType functionType = type;
      StringBuffer sb = new StringBuffer();
      // return type
      DartType returnType = functionType.returnType;
      if (returnType != null && !returnType.isDynamic) {
        String returnTypeSource =
            _getTypeSource(returnType, enclosingClass, enclosingExecutable);
        sb.write(returnTypeSource);
        sb.write(' ');
      }
      // parameter name
      sb.write(name);
      // parameters
      sb.write('(');
      List<ParameterElement> fParameters = functionType.parameters;
      for (int i = 0; i < fParameters.length; i++) {
        ParameterElement fParameter = fParameters[i];
        if (i != 0) {
          sb.write(", ");
        }
        sb.write(_getParameterSource(fParameter.type, fParameter.name,
            enclosingClass, enclosingExecutable));
      }
      sb.write(')');
      // done
      return sb.toString();
    }
    // simple type
    String typeSource =
        _getTypeSource(type, enclosingClass, enclosingExecutable);
    return '$typeSource $name';
  }

  /**
   * Returns the source to reference [type] in this [CompilationUnit].
   *
   * Fills [librariesToImport] with [LibraryElement]s whose elements are
   * used by the generated source, but not imported.
   */
  String _getTypeSource(DartType type, ClassElement enclosingClass,
      ExecutableElement enclosingExecutable,
      {StringBuffer parametersBuffer}) {
    StringBuffer sb = new StringBuffer();
    // type parameter
    if (!_isTypeVisible(type, enclosingClass, enclosingExecutable)) {
      return 'dynamic';
    }
    // just a Function, not FunctionTypeAliasElement
    if (type is FunctionType && type.element is! FunctionTypeAliasElement) {
      if (parametersBuffer == null) {
        return "Function";
      }
      parametersBuffer.write('(');
      for (ParameterElement parameter in type.parameters) {
        String parameterType =
            _getTypeSource(parameter.type, enclosingClass, enclosingExecutable);
        if (parametersBuffer.length != 1) {
          parametersBuffer.write(', ');
        }
        parametersBuffer.write(parameterType);
        parametersBuffer.write(' ');
        parametersBuffer.write(parameter.name);
      }
      parametersBuffer.write(')');
      return _getTypeSource(
          type.returnType, enclosingClass, enclosingExecutable);
    }
    // <Bottom>, Null
    if (type.isBottom || type.isDartCoreNull) {
      return 'dynamic';
    }
    // prepare element
    Element element = type.element;
    if (element == null) {
      String source = type.toString();
      source = source.replaceAll('<dynamic>', '');
      source = source.replaceAll('<dynamic, dynamic>', '');
      return source;
    }
    // check if imported
    LibraryElement definingLibrary = element.library;
    LibraryElement importingLibrary = dartFileEditBuilder.unit.element.library;
    if (definingLibrary != null && definingLibrary != importingLibrary) {
      // no source, if private
      if (element.isPrivate) {
        return null;
      }
      // ensure import
      ImportElement importElement =
          _getImportElement(element, importingLibrary);
      if (importElement != null) {
        if (importElement.prefix != null) {
          sb.write(importElement.prefix.displayName);
          sb.write(".");
        }
      } else {
        importLibrary(definingLibrary.source);
      }
    }
    // append simple name
    String name = element.displayName;
    sb.write(name);
    // may be type arguments
    if (type is ParameterizedType) {
      List<DartType> arguments = type.typeArguments;
      // check if has arguments
      bool hasArguments = false;
      bool allArgumentsVisible = true;
      for (DartType argument in arguments) {
        hasArguments = hasArguments || !argument.isDynamic;
        allArgumentsVisible = allArgumentsVisible &&
            _isTypeVisible(argument, enclosingClass, enclosingExecutable);
      }
      // append type arguments
      if (hasArguments && allArgumentsVisible) {
        sb.write("<");
        for (int i = 0; i < arguments.length; i++) {
          DartType argument = arguments[i];
          if (i != 0) {
            sb.write(", ");
          }
          String argumentSrc =
              _getTypeSource(argument, enclosingClass, enclosingExecutable);
          if (argumentSrc != null) {
            sb.write(argumentSrc);
          } else {
            return null;
          }
        }
        sb.write(">");
      }
    }
    // done
    return sb.toString();
  }

  /**
   * Returns possible names for a variable with the given expected type and
   * expression assigned.
   */
  List<String> _getVariableNameSuggestionsForExpression(DartType expectedType,
      Expression assignedExpression, Set<String> excluded) {
    Set<String> res = new Set();
    // use expression
    if (assignedExpression != null) {
      String nameFromExpression =
          _getBaseNameFromExpression(assignedExpression);
      if (nameFromExpression != null) {
        nameFromExpression = removeStart(nameFromExpression, '_');
        _addAll(excluded, res, _getCamelWordCombinations(nameFromExpression));
      }
      String nameFromParent =
          _getBaseNameFromLocationInParent(assignedExpression);
      if (nameFromParent != null) {
        _addAll(excluded, res, _getCamelWordCombinations(nameFromParent));
      }
    }
    // use type
    if (expectedType != null && !expectedType.isDynamic) {
      String typeName = expectedType.name;
      if ('int' == typeName) {
        _addSingleCharacterName(excluded, res, $i);
      } else if ('double' == typeName) {
        _addSingleCharacterName(excluded, res, $d);
      } else if ('String' == typeName) {
        _addSingleCharacterName(excluded, res, $s);
      } else {
        _addAll(excluded, res, _getCamelWordCombinations(typeName));
      }
      res.remove(typeName);
    }
    // done
    return new List.from(res);
  }

  /**
   * Checks if [type] is visible in either the [enclosingExecutable] or
   * [enclosingClass].
   */
  bool _isTypeVisible(DartType type, ClassElement enclosingClass,
      ExecutableElement enclosingExecutable) {
    if (type is TypeParameterType) {
      TypeParameterElement parameterElement = type.element;
      Element parameterParent = parameterElement.enclosingElement;
      // TODO(brianwilkerson) This needs to compare the parameterParent with
      // each of the parents of the enclosingElement. (That means that we only
      // need the most closely enclosing element.)
      return identical(parameterParent, enclosingExecutable) ||
          identical(parameterParent, enclosingClass);
    }
    return true;
  }
}

/**
 * A [FileEditBuilder] used to build edits for Dart files.
 */
class DartFileEditBuilderImpl extends FileEditBuilderImpl
    implements DartFileEditBuilder {
  /**
   * The compilation unit to which the code will be added.
   */
  CompilationUnit unit;

  /**
   * A set containing the sources of the libraries that need to be imported in
   * order to make visible the names used in generated code.
   */
  Set<Source> librariesToImport = new Set<Source>();

//  /**
//   * The content of the file being edited.
//   */
//  String _content;

  /**
   * Initialize a newly created builder to build a source file edit within the
   * change being built by the given [changeBuilder]. The file being edited has
   * the given [source] and [timeStamp], and the given fully resolved [unit].
   */
  DartFileEditBuilderImpl(DartChangeBuilderImpl changeBuilder, String path,
      int timeStamp, this.unit)
      : super(changeBuilder, path, timeStamp);

  @override
  void convertFunctionFromSyncToAsync(
      FunctionBody body, TypeProvider typeProvider) {
    if (body == null && body.keyword != null) {
      throw new ArgumentError(
          'The function must have a synchronous, non-generator body.');
    }
    addInsertion(body.offset, (EditBuilder builder) {
      builder.write('async ');
    });
    _replaceReturnTypeWithFuture(body, typeProvider);
  }

  @override
  DartEditBuilderImpl createEditBuilder(int offset, int length) {
    return new DartEditBuilderImpl(this, offset, length);
  }

  @override
  void finalize() {
    _addLibraryImports(
        changeBuilder.sourceChange, unit.element.library, librariesToImport);
  }

  @override
  void importLibraries(Iterable<Source> libraries) {
    librariesToImport.addAll(libraries);
  }

  @override
  void replaceTypeWithFuture(
      TypeAnnotation typeAnnotation, TypeProvider typeProvider) {
    InterfaceType futureType = typeProvider.futureType;
    //
    // Check whether the type needs to be replaced.
    //
    DartType type = typeAnnotation?.type;
    if (type == null ||
        type.isDynamic ||
        type is InterfaceType && type.element == futureType.element) {
      return;
    }
    futureType = futureType.instantiate(<DartType>[type]);
    // prepare code for the types
    addReplacement(range.node(typeAnnotation), (EditBuilder builder) {
      if (!(builder as DartEditBuilder).writeType(futureType)) {
        builder.write('void');
      }
    });
  }

  /**
   * Adds edits to the given [change] that ensure that all the [libraries] are
   * imported into the given [targetLibrary].
   */
  void _addLibraryImports(SourceChange change, LibraryElement targetLibrary,
      Set<Source> libraries) {
    // Prepare information about existing imports.
    LibraryDirective libraryDirective;
    List<ImportDirective> importDirectives = <ImportDirective>[];
    for (Directive directive in unit.directives) {
      if (directive is LibraryDirective) {
        libraryDirective = directive;
      } else if (directive is ImportDirective) {
        importDirectives.add(directive);
      }
    }

    // Prepare all URIs to import.
    List<String> uriList = libraries
        .map((library) => _getLibrarySourceUri(targetLibrary, library))
        .toList();
    uriList.sort((a, b) => a.compareTo(b));

    // Insert imports: between existing imports.
    if (importDirectives.isNotEmpty) {
      bool isFirstPackage = true;
      for (String importUri in uriList) {
        bool inserted = false;
        bool isPackage = importUri.startsWith('package:');
        bool isAfterDart = false;
        for (ImportDirective existingImport in importDirectives) {
          if (existingImport.uriContent.startsWith('dart:')) {
            isAfterDart = true;
          }
          if (existingImport.uriContent.startsWith('package:')) {
            isFirstPackage = false;
          }
          if (importUri.compareTo(existingImport.uriContent) < 0) {
            addInsertion(existingImport.offset, (EditBuilder builder) {
              builder.write("import '");
              builder.write(importUri);
              builder.writeln("';");
            });
            inserted = true;
            break;
          }
        }
        if (!inserted) {
          addInsertion(importDirectives.last.end, (EditBuilder builder) {
            if (isPackage && isFirstPackage && isAfterDart) {
              builder.writeln();
            }
            builder.writeln();
            builder.write("import '");
            builder.write(importUri);
            builder.write("';");
          });
        }
        if (isPackage) {
          isFirstPackage = false;
        }
      }
      return;
    }

    // Insert imports: after the library directive.
    if (libraryDirective != null) {
      for (int i = 0; i < uriList.length; i++) {
        String importUri = uriList[i];
        addInsertion(libraryDirective.end, (EditBuilder builder) {
          if (i == 0) {
            builder.writeln();
          }
          builder.writeln();
          builder.write("import '");
          builder.write(importUri);
          builder.writeln("';");
        });
      }
      return;
    }

    // If still at the beginning of the file, skip shebang and line comments.
    _InsertionDescription desc = _getInsertDescTop();
    int offset = desc.offset;
    for (int i = 0; i < uriList.length; i++) {
      String importUri = uriList[i];
      addInsertion(offset, (EditBuilder builder) {
        if (i == 0 && desc.insertEmptyLineBefore) {
          builder.writeln();
        }
        builder.write("import '");
        builder.write(importUri);
        builder.writeln("';");
        if (i == uriList.length - 1 && desc.insertEmptyLineAfter) {
          builder.writeln();
        }
      });
    }
  }

  /**
   * Returns a [InsertDesc] describing where to insert a new directive or a
   * top-level declaration at the top of the file.
   */
  _InsertionDescription _getInsertDescTop() {
    // skip leading line comments
    int offset = 0;
    bool insertEmptyLineBefore = false;
    bool insertEmptyLineAfter = false;
    String source = unit.element.context.getContents(unit.element.source).data;
    var lineInfo = unit.lineInfo;
    // skip hash-bang
    if (offset < source.length - 2) {
      String linePrefix = _getText(source, offset, 2);
      if (linePrefix == "#!") {
        insertEmptyLineBefore = true;
        offset = lineInfo.getOffsetOfLineAfter(offset);
        // skip empty lines to first line comment
        int emptyOffset = offset;
        while (emptyOffset < source.length - 2) {
          int nextLineOffset = lineInfo.getOffsetOfLineAfter(emptyOffset);
          String line = source.substring(emptyOffset, nextLineOffset);
          if (line.trim().isEmpty) {
            emptyOffset = nextLineOffset;
            continue;
          } else if (line.startsWith("//")) {
            offset = emptyOffset;
            break;
          } else {
            break;
          }
        }
      }
    }
    // skip line comments
    while (offset < source.length - 2) {
      String linePrefix = _getText(source, offset, 2);
      if (linePrefix == "//") {
        insertEmptyLineBefore = true;
        offset = lineInfo.getOffsetOfLineAfter(offset);
      } else {
        break;
      }
    }
    // determine if empty line is required after
    int currentLine = lineInfo.getLocation(offset).lineNumber;
    if (currentLine < lineInfo.lineCount) {
      int nextLineOffset = lineInfo.getOffsetOfLine(currentLine + 1);
      String insertLine = source.substring(offset, nextLineOffset);
      if (!insertLine.trim().isEmpty) {
        insertEmptyLineAfter = true;
      }
    }
    return new _InsertionDescription(
        offset, insertEmptyLineBefore, insertEmptyLineAfter);
  }

//  /**
//   * Return the content of the file being edited.
//   */
//  String getContent() {
//    if (_content == null) {
//      CompilationUnitElement unitElement = unit.element;
//      AnalysisContext context = unitElement.context;
//      if (context == null) {
//        throw new CancelCorrectionException();
//      }
//      _content = context.getContents(unitElement.source).data;
//    }
//    return _content;
//  }

  /**
   * Computes the best URI to import [what] into [from].
   */
  String _getLibrarySourceUri(LibraryElement from, Source what) {
    String whatPath = what.fullName;
    // check if an absolute URI (such as 'dart:' or 'package:')
    Uri whatUri = what.uri;
    String whatUriScheme = whatUri.scheme;
    if (whatUriScheme != '' && whatUriScheme != 'file') {
      return whatUri.toString();
    }
    // compute a relative URI
    String fromFolder = path.dirname(from.source.fullName);
    String relativeFile = path.relative(whatPath, from: fromFolder);
    return path.split(relativeFile).join('/');
  }

  /**
   * Returns the text of the given range in the unit.
   */
  String _getText(String content, int offset, int length) {
    return content.substring(offset, offset + length);
  }

//  /**
//   * Returns the text of the given [AstNode] in the unit.
//   */
//  String _getNodeText(AstNode node) {
//    return _getText(node.offset, node.length);
//  }
//
//  /**
//   * Returns the text of the given range in the unit.
//   */
//  String _getText(int offset, int length) {
//    return getContent().substring(offset, offset + length);
//  }

  /**
   * Create an edit to replace the return type of the innermost function
   * containing the given [node] with the type `Future`. The [typeProvider] is
   * used to check the current return type, because if it is already `Future` no
   * edit will be added.
   */
  void _replaceReturnTypeWithFuture(AstNode node, TypeProvider typeProvider) {
    while (node != null) {
      node = node.parent;
      if (node is FunctionDeclaration) {
        replaceTypeWithFuture(node.returnType, typeProvider);
        return;
      } else if (node is MethodDeclaration) {
        replaceTypeWithFuture(node.returnType, typeProvider);
        return;
      }
    }
  }
}

/**
 * A [LinkedEditBuilder] used to build linked edits for Dart files.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class DartLinkedEditBuilderImpl extends LinkedEditBuilderImpl
    implements DartLinkedEditBuilder {
  /**
   * Initialize a newly created linked edit builder.
   */
  DartLinkedEditBuilderImpl(EditBuilderImpl editBuilder) : super(editBuilder);

  @override
  void addSuperTypesAsSuggestions(DartType type) {
    _addSuperTypesAsSuggestions(type, new Set<DartType>());
  }

  /**
   * Safely implement [addSuperTypesAsSuggestions] by using the set of
   * [alreadyAdded] types to prevent infinite loops.
   */
  void _addSuperTypesAsSuggestions(DartType type, Set<DartType> alreadyAdded) {
    if (type is InterfaceType && alreadyAdded.add(type)) {
      addSuggestion(LinkedEditSuggestionKind.TYPE, type.displayName);
      _addSuperTypesAsSuggestions(type.superclass, alreadyAdded);
      for (InterfaceType interfaceType in type.interfaces) {
        _addSuperTypesAsSuggestions(interfaceType, alreadyAdded);
      }
    }
  }
}

class _EnclosingElementFinder {
  ClassElement enclosingClass;
  ExecutableElement enclosingExecutable;

  _EnclosingElementFinder();

  void find(AstNode target, int offset) {
    AstNode node = new NodeLocator2(offset).searchWithin(target);
    while (node != null) {
      if (node is ClassDeclaration) {
        enclosingClass = node.element;
      } else if (node is ConstructorDeclaration) {
        enclosingExecutable = node.element;
      } else if (node is MethodDeclaration) {
        enclosingExecutable = node.element;
      } else if (node is FunctionDeclaration) {
        enclosingExecutable = node.element;
      }
      node = node.parent;
    }
  }
}

class _InsertionDescription {
  final int offset;
  final bool insertEmptyLineBefore;
  final bool insertEmptyLineAfter;
  _InsertionDescription(
      this.offset, this.insertEmptyLineBefore, this.insertEmptyLineAfter);
}
