// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:charcode/ascii.dart';
import 'package:meta/meta.dart';

/**
 * A [ChangeBuilder] used to build changes in Dart files.
 */
class DartChangeBuilderImpl extends ChangeBuilderImpl
    implements DartChangeBuilder {
  /**
   * The analysis session in which the files being edited were analyzed.
   */
  final AnalysisSession session;

  /**
   * Initialize a newly created change builder.
   */
  DartChangeBuilderImpl(this.session);

  @override
  Future<Null> addFileEdit(
      String path, void buildFileEdit(DartFileEditBuilder builder),
      {ImportPrefixGenerator importPrefixGenerator}) {
    return super.addFileEdit(path, (builder) {
      DartFileEditBuilderImpl dartBuilder = builder;
      dartBuilder.importPrefixGenerator = importPrefixGenerator;
      buildFileEdit(dartBuilder);
    });
  }

  @override
  Future<DartFileEditBuilderImpl> createFileEditBuilder(String path) async {
    ResolveResult result = await session.getResolvedAst(path);
    ResultState state = result?.state ?? ResultState.INVALID_FILE_TYPE;
    if (state == ResultState.INVALID_FILE_TYPE) {
      throw new AnalysisException('Cannot analyze "$path"');
    }
    int timeStamp = state == ResultState.VALID ? 0 : -1;
    return new DartFileEditBuilderImpl(this, path, timeStamp, result.unit);
  }
}

/**
 * An [EditBuilder] used to build edits in Dart files.
 */
class DartEditBuilderImpl extends EditBuilderImpl implements DartEditBuilder {
  List<String> _KNOWN_METHOD_NAME_PREFIXES = ['get', 'is', 'to'];

  /**
   * Whether [_enclosingClass] and [_enclosingExecutable] have been initialized.
   */
  bool _hasEnclosingElementsInitialized = false;

  /**
   * The enclosing class element, possibly `null`.
   * This field is lazily initialized in [_initializeEnclosingElements].
   */
  ClassElement _enclosingClass;

  /**
   * The enclosing executable element, possibly `null`.
   * This field is lazily initialized in [_initializeEnclosingElements].
   */
  ExecutableElement _enclosingExecutable;

  /**
   * If not `null`, [write] will copy everything into this buffer.
   */
  StringBuffer _carbonCopyBuffer;

  /**
   * Initialize a newly created builder to build a source edit.
   */
  DartEditBuilderImpl(
      DartFileEditBuilderImpl sourceFileEditBuilder, int offset, int length)
      : super(sourceFileEditBuilder, offset, length);

  DartFileEditBuilderImpl get dartFileEditBuilder => fileEditBuilder;

  @override
  void addLinkedEdit(String groupName,
          void buildLinkedEdit(DartLinkedEditBuilder builder)) =>
      super.addLinkedEdit(groupName, (builder) => buildLinkedEdit(builder));

  @override
  LinkedEditBuilderImpl createLinkedEditBuilder() {
    return new DartLinkedEditBuilderImpl(this);
  }

  /**
   * Returns the indentation with the given [level].
   */
  String getIndent(int level) => '  ' * level;

  @override
  void write(String string) {
    super.write(string);
    _carbonCopyBuffer?.write(string);
  }

  @override
  void writeClassDeclaration(String name,
      {Iterable<DartType> interfaces,
      bool isAbstract: false,
      void membersWriter(),
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
      addSimpleLinkedEdit(nameGroupName, name);
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
    if (membersWriter != null) {
      membersWriter();
    }
    write('}');
  }

  @override
  void writeConstructorDeclaration(String className,
      {ArgumentList argumentList,
      void bodyWriter(),
      SimpleIdentifier constructorName,
      String constructorNameGroupName,
      List<String> fieldNames,
      void initializerWriter(),
      bool isConst: false,
      void parameterWriter()}) {
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
        addSimpleLinkedEdit(constructorNameGroupName, constructorName.name);
      }
    }
    write('(');
    if (parameterWriter != null) {
      parameterWriter();
    } else if (argumentList != null) {
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
    write(')');

    if (initializerWriter != null) {
      write(' : ');
      initializerWriter();
    }

    if (bodyWriter != null) {
      bodyWriter();
    } else {
      write(';');
    }
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
      write(' ');
      typeRequired = false;
    } else if (isFinal) {
      write(Keyword.FINAL.lexeme);
      write(' ');
      typeRequired = false;
    }
    if (type != null) {
      writeType(type, groupName: typeGroupName, required: true);
      write(' ');
    } else if (typeRequired) {
      write(Keyword.VAR.lexeme);
      write(' ');
    }
    if (nameGroupName != null) {
      addSimpleLinkedEdit(nameGroupName, name);
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
      if (writeType(returnType, groupName: returnTypeGroupName)) {
        write(' ');
      }
    }
    if (nameGroupName != null) {
      addSimpleLinkedEdit(nameGroupName, name);
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
      if (writeType(returnType, groupName: returnTypeGroupName)) {
        write(' ');
      }
    }
    write(Keyword.GET.lexeme);
    write(' ');
    if (nameGroupName != null) {
      addSimpleLinkedEdit(nameGroupName, name);
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
        // The type is required unless we've written a keyword.
        write(' ');
      }
      writeType(type, groupName: typeGroupName);
    } else if (typeRequired) {
      write(Keyword.VAR.lexeme);
    }
    write(' ');
    if (nameGroupName != null) {
      addSimpleLinkedEdit(nameGroupName, name);
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
      {StringBuffer displayTextBuffer, String returnTypeGroupName}) {
    void withCarbonCopyBuffer(f()) {
      this._carbonCopyBuffer = displayTextBuffer;
      try {
        f();
      } finally {
        this._carbonCopyBuffer = null;
      }
    }

    String prefix = getIndent(1);
    String prefix2 = getIndent(2);
    ElementKind elementKind = member.kind;
    // TODO(brianwilkerson) Look for a non-abstract inherited member farther up
    // in the superclass chain that we could invoke.
    bool isAbstract = member.isAbstract;
    bool isGetter = elementKind == ElementKind.GETTER;
    bool isSetter = elementKind == ElementKind.SETTER;
    bool isMethod = elementKind == ElementKind.METHOD;
    bool isOperator = isMethod && (member as MethodElement).isOperator;
    String memberName = member.displayName;
    write(prefix);

    // @override
    writeln('@override');
    write(prefix);

    if (isGetter) {
      writeln('// TODO: implement ${member.displayName}');
      write(prefix);
    }

    // return type
    DartType returnType = member.type.returnType;
    bool typeWritten = writeType(returnType,
        groupName: returnTypeGroupName, methodBeingCopied: member);
    if (typeWritten) {
      write(' ');
    }
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
    withCarbonCopyBuffer(() {
      write(memberName);
    });

    // parameters + body
    if (isGetter) {
      if (isAbstract) {
        write(' => ');
        selectAll(() {
          write('null');
        });
        writeln(';');
      } else {
        write(' => ');
        selectAll(() {
          write('super.');
          write(memberName);
        });
        writeln(';');
      }
      displayTextBuffer?.write(' => …');
    } else {
      List<ParameterElement> parameters = member.parameters;
      withCarbonCopyBuffer(() {
        writeTypeParameters(member.typeParameters, methodBeingCopied: member);
        writeParameters(parameters, methodBeingCopied: member);
      });
      writeln(' {');

      // TO-DO
      write(prefix2);
      writeln('// TODO: implement $memberName');

      if (isSetter) {
        if (!isAbstract) {
          write(prefix2);
          selectAll(() {
            write('super.');
            write(memberName);
            write(' = ');
            write(parameters[0].name);
            write(';');
          });
          writeln();
        }
      } else if (returnType.isVoid) {
        if (!isAbstract) {
          write(prefix2);
          selectAll(() {
            write('super.');
            write(memberName);
            write('(');
            for (int i = 0; i < parameters.length; i++) {
              if (i > 0) {
                write(', ');
              }
              write(parameters[i].name);
            }
            write(');');
          });
          writeln();
        }
      } else {
        write(prefix2);
        if (isAbstract) {
          selectAll(() {
            write('return null;');
          });
        } else {
          selectAll(() {
            write('return super.');
            write(memberName);
            write('(');
            for (int i = 0; i < parameters.length; i++) {
              if (i > 0) {
                write(', ');
              }
              write(parameters[i].name);
            }
            write(');');
          });
        }
        writeln();
      }
      // close method
      write(prefix);
      writeln('}');
      displayTextBuffer?.write(' { … }');
    }
  }

  @override
  void writeParameter(String name,
      {ExecutableElement methodBeingCopied, DartType type}) {
    if (type != null) {
      bool hasType = _writeType(type, methodBeingCopied: methodBeingCopied);
      if (name.isNotEmpty) {
        if (hasType) {
          write(' ');
        }
        write(name);
      }
    } else {
      write(name);
    }
  }

  @override
  void writeParameterMatchingArgument(
      Expression argument, int index, Set<String> usedNames) {
    // append type name
    DartType type = argument.bestType;
    if (type == null || type.isBottom || type.isDartCoreNull) {
      type = DynamicTypeImpl.instance;
    }
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
      addSimpleLinkedEdit('PARAM$index', favorite,
          kind: LinkedEditSuggestionKind.PARAMETER, suggestions: suggestions);
    }
  }

  @override
  void writeParameters(Iterable<ParameterElement> parameters,
      {ExecutableElement methodBeingCopied}) {
    write('(');
    bool sawNamed = false;
    bool sawPositional = false;
    for (int i = 0; i < parameters.length; i++) {
      ParameterElement parameter = parameters.elementAt(i);
      if (i > 0) {
        write(', ');
      }
      // Might be optional
      if (parameter.isNamed) {
        if (!sawNamed) {
          write('{');
          sawNamed = true;
        }
      } else if (parameter.isOptionalPositional) {
        if (!sawPositional) {
          write('[');
          sawPositional = true;
        }
      }
      // parameter
      writeParameter(parameter.name,
          methodBeingCopied: methodBeingCopied, type: parameter.type);
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
  void writeReference(Element element) {
    if (element.enclosingElement is CompilationUnitElement) {
      _writeLibraryReference(element);
    }
    write(element.displayName);
  }

  @override
  bool writeType(DartType type,
      {bool addSupertypeProposals: false,
      String groupName,
      ExecutableElement methodBeingCopied,
      bool required: false}) {
    if (type != null && !type.isDynamic) {
      if (groupName != null) {
        bool wroteType;
        addLinkedEdit(groupName, (LinkedEditBuilder builder) {
          // TODO(scheglov) ensure that no linked edit if nothing written
          wroteType = _writeType(type, methodBeingCopied: methodBeingCopied);
          if (wroteType && addSupertypeProposals) {
            _addSuperTypeProposals(builder, type, new Set<DartType>());
          }
        });
        return wroteType;
      } else {
        return _writeType(type, methodBeingCopied: methodBeingCopied);
      }
    }
    if (required) {
      write(Keyword.VAR.lexeme);
      return true;
    }
    return false;
  }

  @override
  void writeTypeParameter(TypeParameterElement typeParameter,
      {ExecutableElement methodBeingCopied}) {
    write(typeParameter.name);
    if (typeParameter.bound != null) {
      write(' extends ');
      _writeType(typeParameter.bound, methodBeingCopied: methodBeingCopied);
    }
  }

  @override
  void writeTypeParameters(List<TypeParameterElement> typeParameters,
      {ExecutableElement methodBeingCopied}) {
    if (typeParameters.isNotEmpty) {
      write('<');
      bool isFirst = true;
      for (TypeParameterElement typeParameter in typeParameters) {
        if (!isFirst) {
          write(', ');
        }
        isFirst = false;
        writeTypeParameter(typeParameter, methodBeingCopied: methodBeingCopied);
      }
      write('>');
    }
  }

  /**
   * Write the code for a comma-separated list of [types], optionally prefixed
   * by a [prefix]. If the list of [types] is `null` or does not contain any
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
    if (type is InterfaceType && alreadyAdded.add(type)) {
      builder.addSuggestion(LinkedEditSuggestionKind.TYPE, type.displayName);
      _addSuperTypeProposals(builder, type.superclass, alreadyAdded);
      for (InterfaceType interfaceType in type.interfaces) {
        _addSuperTypeProposals(builder, interfaceType, alreadyAdded);
      }
    }
  }

  String _getBaseNameFromExpression(Expression expression) {
    if (expression is AsExpression) {
      return _getBaseNameFromExpression(expression.expression);
    } else if (expression is ParenthesizedExpression) {
      return _getBaseNameFromExpression(expression.expression);
    }
    return _getBaseNameFromUnwrappedExpression(expression);
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

  String _getBaseNameFromUnwrappedExpression(Expression expression) {
    String name = null;
    // analyze expressions
    if (expression is SimpleIdentifier) {
      return expression.name;
    } else if (expression is PrefixedIdentifier) {
      return expression.identifier.name;
    } else if (expression is PropertyAccess) {
      return expression.propertyName.name;
    } else if (expression is MethodInvocation) {
      name = expression.methodName.name;
    } else if (expression is InstanceCreationExpression) {
      ConstructorName constructorName = expression.constructorName;
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
    } else if (expression is IndexExpression) {
      name = _getBaseNameFromExpression(expression.realTarget);
      if (name.endsWith('es')) {
        name = name.substring(0, name.length - 2);
      } else if (name.endsWith('s')) {
        name = name.substring(0, name.length - 1);
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
   * If the given [type] is visible in either the [_enclosingExecutable] or
   * [_enclosingClass], or if there is a local equivalent to the type (such as
   * in the case of a type parameter from a superclass), then return the type
   * that is locally visible. Otherwise, return `null`.
   */
  DartType _getVisibleType(DartType type,
      {ExecutableElement methodBeingCopied}) {
    if (type is TypeParameterType) {
      _initializeEnclosingElements();
      TypeParameterElement parameterElement = type.element;
      Element parameterParent = parameterElement.enclosingElement;
      while (parameterParent is GenericFunctionTypeElement ||
          parameterParent is ParameterElement) {
        parameterParent = parameterParent.enclosingElement;
      }
      // TODO(brianwilkerson) This needs to compare the parameterParent with
      // each of the parents of the _enclosingExecutable. (That means that we
      // only need the most closely enclosing element.)
      if (parameterParent == _enclosingExecutable ||
          parameterParent == _enclosingClass ||
          parameterParent == methodBeingCopied) {
        return type;
      }
      if (_enclosingClass != null &&
          methodBeingCopied != null &&
          parameterParent is ClassElement &&
          parameterParent == methodBeingCopied.enclosingElement) {
        // The parameter is from the class enclosing the methodBeingCopied. That
        // means that somewhere along the inheritance chain there must be a type
        // argument corresponding to the type parameter (either a concrete type
        // or a type parameter of the _enclosingClass). That's the visible type
        // that needs to be returned.
        _InheritanceChain chain = new _InheritanceChain(
            subtype: _enclosingClass, supertype: parameterParent);
        while (chain != null) {
          DartType mappedType = chain.mapParameter(parameterElement);
          if (mappedType is TypeParameterType) {
            parameterElement = mappedType.element;
            chain = chain.next;
          } else {
            return mappedType;
          }
        }
        return parameterElement.type;
      }
      return null;
    }
    Element element = type.element;
    if (element == null) {
      return type;
    }
    if (element.isPrivate && !dartFileEditBuilder._isDefinedLocally(element)) {
      return null;
    }
    return type;
  }

  /**
   * Initialize the [_enclosingClass] and [_enclosingExecutable].
   */
  void _initializeEnclosingElements() {
    if (!_hasEnclosingElementsInitialized) {
      _EnclosingElementFinder finder = new _EnclosingElementFinder();
      finder.find(dartFileEditBuilder.unit, offset);
      _enclosingClass = finder.enclosingClass;
      _enclosingExecutable = finder.enclosingExecutable;
      _hasEnclosingElementsInitialized = true;
    }
  }

  /**
   * Write the import prefix to reference the [element], if needed.
   *
   * The prefix is not needed if the [element] is defined in the target library,
   * or there is already an import without prefix that exports the [element].
   * If there there are no existing import that exports the [element], a library
   * that exports the [element] is scheduled for import, possibly with a prefix.
   */
  void _writeLibraryReference(Element element) {
    // If the element is defined in the library, then no prefix needed.
    if (dartFileEditBuilder._isDefinedLocally(element)) {
      return;
    }

    ImportElement import = dartFileEditBuilder._getImportElement(element);
    if (import != null) {
      if (import.prefix != null) {
        write(import.prefix.displayName);
        write('.');
      }
    } else {
      Uri library = element.library.source.uri;
      _LibraryToImport import = dartFileEditBuilder._importLibrary(library);
      if (import.prefix != null) {
        write(import.prefix);
        write('.');
      }
    }
  }

  /**
   * Write the code to reference [type] in this compilation unit.
   *
   * If a [methodBeingCopied] is provided, then the type parameters of that
   * method will be duplicated in the copy and will therefore be visible.
   *
   * Causes any libraries whose elements are used by the generated code, to be
   * imported.
   */
  bool _writeType(DartType type, {ExecutableElement methodBeingCopied}) {
    type = _getVisibleType(type, methodBeingCopied: methodBeingCopied);

    // If not a useful type, don't write it.
    if (type == null || type.isDynamic || type.isBottom) {
      return false;
    }

    Element element = type.element;

    // No element, e.g. "void".
    if (element == null) {
      write(type.displayName);
      return true;
    }

    // Typedef(s) are represented as GenericFunctionTypeElement(s).
    if (element is GenericFunctionTypeElement &&
        element.typeParameters.isEmpty &&
        element.enclosingElement is GenericTypeAliasElement) {
      element = element.enclosingElement;
    }

    // Just a Function, not FunctionTypeAliasElement.
    if (type is FunctionType &&
        element is FunctionTypedElement &&
        element is! FunctionTypeAliasElement) {
      if (_writeType(type.returnType, methodBeingCopied: methodBeingCopied)) {
        write(' ');
      }
      write('Function');
      writeTypeParameters(element.typeParameters,
          methodBeingCopied: methodBeingCopied);
      writeParameters(type.parameters, methodBeingCopied: methodBeingCopied);
      return true;
    }

    // Ensure that the element is imported.
    _writeLibraryReference(element);

    // Write the simple name.
    String name = element.displayName;
    write(name);

    // Write type arguments.
    if (type is ParameterizedType) {
      List<DartType> arguments = type.typeArguments;
      // Check if has arguments.
      bool hasArguments = false;
      bool allArgumentsVisible = true;
      for (DartType argument in arguments) {
        hasArguments = hasArguments || !argument.isDynamic;
        allArgumentsVisible = allArgumentsVisible &&
            _getVisibleType(argument, methodBeingCopied: methodBeingCopied) !=
                null;
      }
      // Write type arguments only if they are useful.
      if (hasArguments && allArgumentsVisible) {
        write('<');
        for (int i = 0; i < arguments.length; i++) {
          DartType argument = arguments[i];
          if (i != 0) {
            write(', ');
          }
          _writeType(argument, methodBeingCopied: methodBeingCopied);
        }
        write('>');
      }
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
  final CompilationUnit unit;

  /**
   * The target library, which contains the [unit].
   */
  final LibraryElement libraryElement;

  /**
   * The optional generator of prefixes for new imports.
   */
  ImportPrefixGenerator importPrefixGenerator;

  /**
   * A mapping from libraries that need to be imported in order to make visible
   * the names used in generated code, to information about these imports.
   */
  Map<Uri, _LibraryToImport> librariesToImport = {};

  /**
   * Initialize a newly created builder to build a source file edit within the
   * change being built by the given [changeBuilder]. The file being edited has
   * the given [path] and [timeStamp], and the given fully resolved [unit].
   */
  DartFileEditBuilderImpl(DartChangeBuilderImpl changeBuilder, String path,
      int timeStamp, this.unit)
      : libraryElement = unit.element.library,
        super(changeBuilder, path, timeStamp);

  @override
  void addInsertion(int offset, void buildEdit(DartEditBuilder builder)) =>
      super.addInsertion(offset, (builder) => buildEdit(builder));

  @override
  void addReplacement(
          SourceRange range, void buildEdit(DartEditBuilder builder)) =>
      super.addReplacement(range, (builder) => buildEdit(builder));

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
  Future<Null> finalize() async {
    if (librariesToImport.isNotEmpty) {
      CompilationUnitElement definingUnitElement =
          libraryElement.definingCompilationUnit;
      if (definingUnitElement == unit.element) {
        _addLibraryImports(librariesToImport.values);
      } else {
        await (changeBuilder as DartChangeBuilder).addFileEdit(
            definingUnitElement.source.fullName, (DartFileEditBuilder builder) {
          (builder as DartFileEditBuilderImpl)
              ._addLibraryImports(librariesToImport.values);
        });
      }
    }
  }

  @override
  String importLibrary(Uri uri) {
    return _importLibrary(uri).uriText;
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
    // TODO(brianwilkerson) Unconditionally execute the body of the 'if' when
    // Future<void> is fully supported.
    if (!type.isVoid) {
      futureType = futureType.instantiate(<DartType>[type]);
    }
    // prepare code for the types
    addReplacement(range.node(typeAnnotation), (EditBuilder builder) {
      if (!(builder as DartEditBuilder).writeType(futureType)) {
        builder.write('void');
      }
    });
  }

  /**
   * Adds edits ensure that all the [imports] are imported into the library.
   */
  void _addLibraryImports(Iterable<_LibraryToImport> imports) {
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

    // Sort imports by URIs.
    List<_LibraryToImport> importList = imports.toList();
    importList.sort((a, b) => a.uriText.compareTo(b.uriText));

    void writeImport(EditBuilder builder, _LibraryToImport import) {
      builder.write("import '");
      builder.write(import.uriText);
      builder.write("'");
      if (import.prefix != null) {
        builder.write(' as ');
        builder.write(import.prefix);
      }
      builder.write(';');
    }

    // Insert imports: between existing imports.
    if (importDirectives.isNotEmpty) {
      for (var import in importList) {
        bool isDart = import.uriText.startsWith('dart:');
        bool isPackage = import.uriText.startsWith('package:');
        bool inserted = false;

        void insert(
            {ImportDirective prev,
            ImportDirective next,
            bool trailingNewLine: false}) {
          LineInfo lineInfo = unit.lineInfo;
          if (prev != null) {
            int offset = prev.end;
            int line = lineInfo.getLocation(offset).lineNumber;
            Token comment = prev.endToken.next.precedingComments;
            while (comment != null) {
              if (lineInfo.getLocation(comment.offset).lineNumber == line) {
                offset = comment.end;
              }
              comment = comment.next;
            }
            addInsertion(offset, (EditBuilder builder) {
              builder.writeln();
              writeImport(builder, import);
            });
          } else {
            int offset = next.offset;
            addInsertion(offset, (EditBuilder builder) {
              writeImport(builder, import);
              builder.writeln();
              if (trailingNewLine) {
                builder.writeln();
              }
            });
          }
          inserted = true;
        }

        ImportDirective lastExisting;
        ImportDirective lastExistingDart;
        ImportDirective lastExistingPackage;
        bool isLastExistingDart = false;
        bool isLastExistingPackage = false;
        for (ImportDirective existingImport in importDirectives) {
          String existingUri = existingImport.uriContent;

          bool isExistingDart = existingUri.startsWith('dart:');
          bool isExistingPackage = existingUri.startsWith('package:');
          bool isExistingRelative = !existingUri.contains(':');

          bool isNewBeforeExisting = import.uriText.compareTo(existingUri) < 0;

          if (isDart) {
            if (!isExistingDart || isNewBeforeExisting) {
              insert(
                  prev: lastExistingDart,
                  next: existingImport,
                  trailingNewLine: !isExistingDart);
              break;
            }
          } else if (isPackage) {
            if (isExistingRelative || isNewBeforeExisting) {
              insert(
                  prev: lastExistingPackage,
                  next: existingImport,
                  trailingNewLine: isExistingRelative);
              break;
            }
          } else {
            if (!isExistingDart && !isExistingPackage && isNewBeforeExisting) {
              insert(next: existingImport);
              break;
            }
          }

          lastExisting = existingImport;
          if (isExistingDart) {
            lastExistingDart = existingImport;
          } else if (isExistingPackage) {
            lastExistingPackage = existingImport;
          }
          isLastExistingDart = isExistingDart;
          isLastExistingPackage = isExistingPackage;
        }
        if (!inserted) {
          addInsertion(lastExisting.end, (EditBuilder builder) {
            if (isPackage) {
              if (isLastExistingDart) {
                builder.writeln();
              }
            } else {
              if (isLastExistingDart || isLastExistingPackage) {
                builder.writeln();
              }
            }
            builder.writeln();
            writeImport(builder, import);
          });
        }
      }
      return;
    }

    // Insert imports: after the library directive.
    if (libraryDirective != null) {
      addInsertion(libraryDirective.end, (EditBuilder builder) {
        for (int i = 0; i < importList.length; i++) {
          var import = importList[i];
          if (i == 0) {
            builder.writeln();
          }
          builder.writeln();
          writeImport(builder, import);
          builder.writeln();
        }
      });
      return;
    }

    // If still at the beginning of the file, add before the first declaration.
    int offset;
    bool insertEmptyLineAfter = false;
    if (unit.declarations.isNotEmpty) {
      offset = unit.declarations.first.offset;
      insertEmptyLineAfter = true;
    } else {
      offset = unit.end;
    }
    addInsertion(offset, (EditBuilder builder) {
      for (int i = 0; i < importList.length; i++) {
        var import = importList[i];
        writeImport(builder, import);
        builder.writeln();
        if (i == importList.length - 1 && insertEmptyLineAfter) {
          builder.writeln();
        }
      }
    });
  }

  /**
   * Return the import element used to import the given [element] into the
   * target library, or `null` if the element was not imported, such as when
   * the element is declared in the same library.
   */
  ImportElement _getImportElement(Element element) {
    for (ImportElement import in libraryElement.imports) {
      Map<String, Element> definedNames = import.namespace.definedNames;
      if (definedNames.containsValue(element)) {
        return import;
      }
    }
    return null;
  }

  /**
   * Computes the best URI to import [what] into the target library.
   */
  String _getLibraryUriText(Uri what) {
    if (what.scheme == 'file') {
      var session = (changeBuilder as DartChangeBuilderImpl).session;
      var pathContext = session.resourceProvider.pathContext;
      String whatPath = pathContext.fromUri(what);
      String libraryPath = libraryElement.source.fullName;
      String libraryFolder = pathContext.dirname(libraryPath);
      String relativeFile = pathContext.relative(whatPath, from: libraryFolder);
      return pathContext.split(relativeFile).join('/');
    }
    return what.toString();
  }

  /**
   * Arrange to have an import added for the library with the given [uri].
   */
  _LibraryToImport _importLibrary(Uri uri) {
    var import = librariesToImport[uri];
    if (import == null) {
      String uriText = _getLibraryUriText(uri);
      String prefix =
          importPrefixGenerator != null ? importPrefixGenerator(uri) : null;
      import = new _LibraryToImport(uriText, prefix);
      librariesToImport[uri] = import;
    }
    return import;
  }

  /**
   * Return `true` if the [element] is defined in the target library.
   */
  bool _isDefinedLocally(Element element) {
    return element.library == libraryElement;
  }

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
      } else if (node is FunctionExpression &&
          node.parent is! FunctionDeclaration) {
        // Closures don't have a return type.
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

class _InheritanceChain {
  final _InheritanceChain next;

  final InterfaceType supertype;

  /**
   * Return the shortest inheritance chain from a [subtype] to a [supertype], or
   * `null` if [subtype] does not inherit from [supertype].
   */
  factory _InheritanceChain(
      {@required ClassElement subtype, @required ClassElement supertype}) {
    List<_InheritanceChain> allChainsFrom(
        _InheritanceChain next, ClassElement subtype) {
      List<_InheritanceChain> chains = <_InheritanceChain>[];
      InterfaceType supertypeType = subtype.supertype;
      ClassElement supertypeElement = supertypeType.element;
      if (supertypeElement == supertype) {
        chains.add(new _InheritanceChain._(next, supertypeType));
      } else if (supertypeType.isObject) {
        // Don't add this chain and don't recurse.
      } else {
        chains.addAll(allChainsFrom(
            new _InheritanceChain._(next, supertypeType), supertypeElement));
      }
      for (InterfaceType mixinType in subtype.mixins) {
        ClassElement mixinElement = mixinType.element;
        if (mixinElement == supertype) {
          chains.add(new _InheritanceChain._(next, mixinType));
        }
      }
      for (InterfaceType interfaceType in subtype.interfaces) {
        ClassElement interfaceElement = interfaceType.element;
        if (interfaceElement == supertype) {
          chains.add(new _InheritanceChain._(next, interfaceType));
        } else if (supertypeType.isObject) {
          // Don't add this chain and don't recurse.
        } else {
          chains.addAll(allChainsFrom(
              new _InheritanceChain._(next, interfaceType), interfaceElement));
        }
      }
      return chains;
    }

    List<_InheritanceChain> chains = allChainsFrom(null, subtype);
    if (chains.isEmpty) {
      return null;
    }
    _InheritanceChain shortestChain = chains.removeAt(0);
    int shortestLength = shortestChain.length;
    for (_InheritanceChain chain in chains) {
      int length = chain.length;
      if (length < shortestLength) {
        shortestChain = chain;
        shortestLength = length;
      }
    }
    return shortestChain;
  }

  /**
   * Initialize a newly created link in an inheritance chain.
   */
  _InheritanceChain._(this.next, this.supertype);

  /**
   * Return the number of links in the chain starting with this link.
   */
  int get length {
    if (next == null) {
      return 1;
    }
    return next.length + 1;
  }

  DartType mapParameter(TypeParameterElement typeParameter) {
    Element parameterParent = typeParameter.enclosingElement;
    if (parameterParent is ClassElement) {
      int index = parameterParent.typeParameters.indexOf(typeParameter);
      return supertype.typeArguments[index];
    }
    return null;
  }
}

/**
 * Information about a new library to import.
 */
class _LibraryToImport {
  final String uriText;
  final String prefix;

  _LibraryToImport(this.uriText, this.prefix);

  @override
  int get hashCode => uriText.hashCode;

  @override
  bool operator ==(other) {
    return other is _LibraryToImport &&
        other.uriText == uriText &&
        other.prefix == prefix;
  }
}
