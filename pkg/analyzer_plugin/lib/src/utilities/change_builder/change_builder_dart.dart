// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/src/utilities/charcodes.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:dart_style/dart_style.dart';

/// A [ChangeBuilder] used to build changes in Dart files.
@Deprecated('Use ChangeBuilder')
class DartChangeBuilderImpl extends ChangeBuilderImpl
    implements DartChangeBuilder {
  /// Initialize a newly created change builder.
  @Deprecated('Use ChangeBuilder(session: session)')
  DartChangeBuilderImpl(AnalysisSession session) : super(session: session);

  @Deprecated('Use ChangeBuilder(workspace: workspace)')
  DartChangeBuilderImpl.forWorkspace(ChangeWorkspace workspace)
      : super(workspace: workspace);

  @Deprecated('Use ChangeBuilder.addDartFileEdit')
  @override
  Future<void> addFileEdit(
      String path, void Function(DartFileEditBuilder builder) buildFileEdit,
      {ImportPrefixGenerator importPrefixGenerator}) {
    return super.addDartFileEdit(path, buildFileEdit,
        importPrefixGenerator: importPrefixGenerator);
  }

  @override
  Future<DartFileEditBuilderImpl> createGenericFileEditBuilder(
      String path) async {
    return super.createDartFileEditBuilder(path);
  }
}

/// An [EditBuilder] used to build edits in Dart files.
class DartEditBuilderImpl extends EditBuilderImpl implements DartEditBuilder {
  final List<String> _KNOWN_METHOD_NAME_PREFIXES = ['get', 'is', 'to'];

  /// Whether [_enclosingClass] and [_enclosingExecutable] have been
  /// initialized.
  bool _hasEnclosingElementsInitialized = false;

  /// The enclosing class element, possibly `null`.
  /// This field is lazily initialized in [_initializeEnclosingElements].
  ClassElement _enclosingClass;

  /// The enclosing executable element, possibly `null`.
  /// This field is lazily initialized in [_initializeEnclosingElements].
  ExecutableElement _enclosingExecutable;

  /// If not `null`, [write] will copy everything into this buffer.
  StringBuffer _carbonCopyBuffer;

  /// Initialize a newly created builder to build a source edit.
  DartEditBuilderImpl(
      DartFileEditBuilderImpl sourceFileEditBuilder, int offset, int length)
      : super(sourceFileEditBuilder, offset, length);

  DartFileEditBuilderImpl get dartFileEditBuilder =>
      fileEditBuilder as DartFileEditBuilderImpl;

  @override
  void addLinkedEdit(String groupName,
          void Function(DartLinkedEditBuilder builder) buildLinkedEdit) =>
      super.addLinkedEdit(groupName,
          (builder) => buildLinkedEdit(builder as DartLinkedEditBuilder));

  @override
  LinkedEditBuilderImpl createLinkedEditBuilder() {
    return DartLinkedEditBuilderImpl(this);
  }

  /// Returns the indentation with the given [level].
  String getIndent(int level) => '  ' * level;

  @override
  void write(String string) {
    super.write(string);
    _carbonCopyBuffer?.write(string);
  }

  @override
  void writeClassDeclaration(String name,
      {Iterable<DartType> interfaces,
      bool isAbstract = false,
      void Function() membersWriter,
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
      // TODO(brianwilkerson) Remove this branch when 2.1 semantics are
      // supported everywhere.
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
      void Function() bodyWriter,
      String classNameGroupName,
      SimpleIdentifier constructorName,
      String constructorNameGroupName,
      List<String> fieldNames,
      void Function() initializerWriter,
      bool isConst = false,
      void Function() parameterWriter}) {
    if (isConst) {
      write(Keyword.CONST.lexeme);
      write(' ');
    }
    if (classNameGroupName == null) {
      write(className);
    } else {
      addSimpleLinkedEdit(classNameGroupName, className);
    }
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
      for (var i = 0; i < fieldNames.length; i++) {
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
      {void Function() initializerWriter,
      bool isConst = false,
      bool isFinal = false,
      bool isStatic = false,
      String nameGroupName,
      DartType type,
      String typeGroupName}) {
    if (isStatic) {
      write(Keyword.STATIC.lexeme);
      write(' ');
    }
    var typeRequired = true;
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
      {void Function() bodyWriter,
      bool isStatic = false,
      String nameGroupName,
      void Function() parameterWriter,
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
      {void Function() bodyWriter,
      bool isStatic = false,
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
  void writeImportedName(List<Uri> uris, String name) {
    assert(uris.isNotEmpty);
    var imports = <ImportElement>[];
    for (var uri in uris) {
      imports.addAll(dartFileEditBuilder._getImportsForUri(uri));
    }
    var import = _getBestImportForName(imports, name);
    if (import == null) {
      var library = dartFileEditBuilder._importLibrary(uris[0]);
      if (library.prefix != null) {
        write(library.prefix);
        write('.');
      }
    } else {
      if (import.prefix != null) {
        write(import.prefix.displayName);
        write('.');
      }
    }
    write(name);
  }

  @override
  void writeLocalVariableDeclaration(String name,
      {void Function() initializerWriter,
      bool isConst = false,
      bool isFinal = false,
      String nameGroupName,
      DartType type,
      String typeGroupName}) {
    var typeRequired = true;
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
  void writeMixinDeclaration(String name,
      {Iterable<DartType> interfaces,
      void Function() membersWriter,
      String nameGroupName,
      Iterable<DartType> superclassConstraints}) {
    // TODO(brianwilkerson) Add support for type parameters, probably as a
    // parameterWriter parameter.
    write('mixin ');
    if (nameGroupName == null) {
      write(name);
    } else {
      addSimpleLinkedEdit(nameGroupName, name);
    }
    writeTypes(superclassConstraints, prefix: ' on ');
    writeTypes(interfaces, prefix: ' implements ');
    writeln(' {');
    if (membersWriter != null) {
      membersWriter();
    }
    write('}');
  }

  @override
  void writeOverride(
    ExecutableElement element, {
    StringBuffer displayTextBuffer,
    String returnTypeGroupName,
    bool invokeSuper = false,
  }) {
    void withCarbonCopyBuffer(Function() f) {
      _carbonCopyBuffer = displayTextBuffer;
      try {
        f();
      } finally {
        _carbonCopyBuffer = null;
      }
    }

    var prefix = getIndent(1);
    var prefix2 = getIndent(2);
    var elementKind = element.kind;

    var isGetter = elementKind == ElementKind.GETTER;
    var isSetter = elementKind == ElementKind.SETTER;
    var isMethod = elementKind == ElementKind.METHOD;
    var isOperator = isMethod && (element as MethodElement).isOperator;
    var memberName = element.displayName;

    // @override
    writeln('@override');
    write(prefix);

    if (isGetter) {
      writeln('// TODO: implement ${element.displayName}');
      write(prefix);
    }

    // return type
    var returnType = element.returnType;
    if (!isSetter) {
      var typeWritten = writeType(returnType,
          groupName: returnTypeGroupName, methodBeingCopied: element);
      if (typeWritten) {
        write(' ');
      }
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
      if (invokeSuper) {
        write(' => ');
        selectAll(() {
          write('super.');
          write(memberName);
        });
        writeln(';');
      } else {
        write(' => ');
        selectAll(() {
          write('throw UnimplementedError()');
        });
        write(';');
      }
      displayTextBuffer?.write(' => …');
    } else {
      var parameters = element.parameters;
      withCarbonCopyBuffer(() {
        writeTypeParameters(element.type.typeFormals,
            methodBeingCopied: element);
        writeParameters(parameters, methodBeingCopied: element);
      });
      writeln(' {');

      // TO-DO
      write(prefix2);
      write('// TODO: implement $memberName');

      if (isSetter) {
        if (invokeSuper) {
          writeln();
          write(prefix2);
          selectAll(() {
            write('super.');
            write(memberName);
            write(' = ');
            write(parameters[0].name);
            write(';');
          });
          writeln();
        } else {
          selectHere();
          writeln();
        }
      } else if (returnType.isVoid) {
        if (invokeSuper) {
          writeln();
          write(prefix2);
          selectAll(() {
            write('super');
            _writeSuperMemberInvocation(element, memberName, parameters);
          });
          writeln();
        } else {
          selectHere();
          writeln();
        }
      } else {
        writeln();
        write(prefix2);
        if (invokeSuper) {
          selectAll(() {
            write('return super');
            _writeSuperMemberInvocation(element, memberName, parameters);
          });
        } else {
          selectAll(() {
            write('throw UnimplementedError();');
          });
        }
        writeln();
      }
      // close method
      write(prefix);
      write('}');
      displayTextBuffer?.write(' { … }');
    }
  }

  @override
  void writeParameter(String name,
      {bool isCovariant = false,
      bool isRequiredNamed = false,
      ExecutableElement methodBeingCopied,
      String nameGroupName,
      DartType type,
      String typeGroupName}) {
    bool writeType() {
      if (typeGroupName != null) {
        bool hasType;
        addLinkedEdit(typeGroupName, (DartLinkedEditBuilder builder) {
          hasType = _writeType(type, methodBeingCopied: methodBeingCopied);
          builder.addSuperTypesAsSuggestions(type);
        });
        return hasType;
      }
      return _writeType(type, methodBeingCopied: methodBeingCopied);
    }

    void writeName() {
      if (nameGroupName != null) {
        addLinkedEdit(nameGroupName, (DartLinkedEditBuilder builder) {
          write(name);
        });
      } else {
        write(name);
      }
    }

    if (isCovariant) {
      write('covariant ');
    }
    if (isRequiredNamed) {
      var library = dartFileEditBuilder.resolvedUnit.libraryElement;
      if (library.featureSet.isEnabled(Feature.non_nullable)) {
        write('required ');
      } else {
        var result = dartFileEditBuilder
            .importLibraryElement(Uri.parse('package:meta/meta.dart'));
        var prefix = result.prefix;
        if (prefix != null) {
          write('@$prefix.required ');
        } else {
          write('@required ');
        }
      }
    }
    if (type != null) {
      var hasType = writeType();
      if (name.isNotEmpty) {
        if (hasType) {
          write(' ');
        }
        writeName();
      }
    } else {
      writeName();
    }
  }

  @override
  void writeParameterMatchingArgument(
      Expression argument, int index, Set<String> usedNames) {
    // append type name
    var type = argument.staticType;
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
      var suggestions =
          _getParameterNameSuggestions(usedNames, type, argument, index);
      var favorite = suggestions[0];
      usedNames.add(favorite);
      addSimpleLinkedEdit('PARAM$index', favorite,
          kind: LinkedEditSuggestionKind.PARAMETER, suggestions: suggestions);
    }
  }

  @override
  void writeParameters(Iterable<ParameterElement> parameters,
      {ExecutableElement methodBeingCopied}) {
    var parameterNames = <String>{};
    for (var i = 0; i < parameters.length; i++) {
      var name = parameters.elementAt(i).name;
      if (name.isNotEmpty) {
        parameterNames.add(name);
      }
    }

    write('(');
    var sawNamed = false;
    var sawPositional = false;
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters.elementAt(i);
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
      var name = parameter.name;
      if (name.isEmpty) {
        name = _generateUniqueName(parameterNames, 'p');
        parameterNames.add(name);
      }
      var groupPrefix =
          methodBeingCopied != null ? '${methodBeingCopied.name}:' : '';
      writeParameter(name,
          isCovariant: parameter.isCovariant,
          isRequiredNamed: parameter.isRequiredNamed,
          methodBeingCopied: methodBeingCopied,
          nameGroupName: parameter.isNamed ? null : '${groupPrefix}PARAM$i',
          type: parameter.type,
          typeGroupName: '${groupPrefix}TYPE$i');
      // default value
      var defaultCode = parameter.defaultValueCode;
      if (defaultCode != null) {
        write(' = ');
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
    var usedNames = <String>{};
    List<Expression> arguments = argumentList.arguments;
    var hasNamedParameters = false;
    for (var i = 0; i < arguments.length; i++) {
      var argument = arguments[i];
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
  void writeSetterDeclaration(String name,
      {void Function() bodyWriter,
      bool isStatic = false,
      String nameGroupName,
      DartType parameterType,
      String parameterTypeGroupName}) {
    if (isStatic) {
      write(Keyword.STATIC.lexeme);
      write(' ');
    }
    write(Keyword.SET.lexeme);
    write(' ');
    if (nameGroupName != null) {
      addSimpleLinkedEdit(nameGroupName, name);
    } else {
      write(name);
    }
    write('(');
    if (parameterType != null && !parameterType.isDynamic) {
      if (writeType(parameterType, groupName: parameterTypeGroupName)) {
        write(' ');
      }
    }
    // TODO(brianwilkerson) The name of the setter is unlikely to be a good name
    //  for the parameter. We need to find a better name to produce here.
    write(name);
    write(') ');
    if (bodyWriter == null) {
      write('{}');
    } else {
      bodyWriter();
    }
  }

  @override
  bool writeType(DartType type,
      {bool addSupertypeProposals = false,
      String groupName,
      ExecutableElement methodBeingCopied,
      bool required = false}) {
    var wroteType = false;
    if (type != null && !type.isDynamic) {
      if (groupName != null) {
        addLinkedEdit(groupName, (LinkedEditBuilder builder) {
          wroteType = _writeType(type, methodBeingCopied: methodBeingCopied);
          if (wroteType && addSupertypeProposals) {
            _addSuperTypeProposals(builder, type, <DartType>{});
          }
        });
      } else {
        wroteType = _writeType(type, methodBeingCopied: methodBeingCopied);
      }
    }
    if (!wroteType && required) {
      write(Keyword.VAR.lexeme);
      return true;
    }
    return wroteType;
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
      var isFirst = true;
      for (var typeParameter in typeParameters) {
        if (!isFirst) {
          write(', ');
        }
        isFirst = false;
        writeTypeParameter(typeParameter, methodBeingCopied: methodBeingCopied);
      }
      write('>');
    }
  }

  @override
  void writeTypes(Iterable<DartType> types, {String prefix}) {
    if (types == null || types.isEmpty) {
      return;
    }
    var first = true;
    for (var type in types) {
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

  /// Adds [toAdd] items which are not excluded.
  void _addAll(
      Set<String> excluded, Set<String> result, Iterable<String> toAdd) {
    for (var item in toAdd) {
      // add name based on "item", but not "excluded"
      for (var suffix = 1;; suffix++) {
        // prepare name, just "item" or "item2", "item3", etc
        var name = item;
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

  /// Adds to [result] either [c] or the first ASCII character after it.
  void _addSingleCharacterName(
      Set<String> excluded, Set<String> result, int c) {
    while (c < $z) {
      var name = String.fromCharCode(c);
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
      builder.addSuggestion(
        LinkedEditSuggestionKind.TYPE,
        type.getDisplayString(withNullability: false),
      );
      _addSuperTypeProposals(builder, type.superclass, alreadyAdded);
      for (var interfaceType in type.interfaces) {
        _addSuperTypeProposals(builder, interfaceType, alreadyAdded);
      }
    }
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
      var namedExpression = expression.parent as NamedExpression;
      if (namedExpression.expression == expression) {
        return namedExpression.name.label.name;
      }
    }
    // positional argument
    var parameter = expression.staticParameterElement;
    if (parameter != null) {
      return parameter.displayName;
    }

    // unknown
    return null;
  }

  String _getBaseNameFromUnwrappedExpression(Expression expression) {
    String name;
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
      var constructorName = expression.constructorName;
      var typeName = constructorName.type;
      if (typeName != null) {
        var typeNameIdentifier = typeName.name;
        // new ClassName()
        if (typeNameIdentifier is SimpleIdentifier) {
          return typeNameIdentifier.name;
        }
        // new prefix.name();
        if (typeNameIdentifier is PrefixedIdentifier) {
          var prefixed = typeNameIdentifier;
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
      if (name != null) {
        if (name.endsWith('es')) {
          name = name.substring(0, name.length - 2);
        } else if (name.endsWith('s')) {
          name = name.substring(0, name.length - 1);
        }
      }
    }
    // strip known prefixes
    if (name != null) {
      for (var i = 0; i < _KNOWN_METHOD_NAME_PREFIXES.length; i++) {
        var prefix = _KNOWN_METHOD_NAME_PREFIXES[i];
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

  /// Given a list of [imports] that do, or can, make the [name] visible in
  /// scope, return the one that will lead to the cleanest code.
  ImportElement _getBestImportForName(
      List<ImportElement> imports, String name) {
    if (imports.isEmpty) {
      return null;
    } else if (imports.length == 1) {
      return imports[0];
    }
    imports.sort((first, second) {
      // Prefer imports that make the name visible.
      var firstDefinesName = first.namespace.definedNames.containsKey(name);
      var secondDefinesName = second.namespace.definedNames.containsKey(name);
      if (firstDefinesName != secondDefinesName) {
        return firstDefinesName ? -1 : 1;
      }
      // Prefer imports without prefixes.
      var firstHasPrefix = first.prefix != null;
      var secondHasPrefix = second.prefix != null;
      if (firstHasPrefix != secondHasPrefix) {
        return firstHasPrefix ? 1 : -1;
      }
      return 0;
    });
    return imports[0];
  }

  /// Returns all variants of names by removing leading words one by one.
  List<String> _getCamelWordCombinations(String name) {
    var result = <String>[];
    var parts = getCamelWords(name);
    for (var i = 0; i < parts.length; i++) {
      var s1 = parts[i].toLowerCase();
      var s2 = parts.skip(i + 1).join();
      var suggestion = '$s1$s2';
      result.add(suggestion);
    }
    return result;
  }

  /// Return a list containing the suggested names for a parameter with the
  /// given [type] whose value in one location is computed by the given
  /// [expression]. The list will not contain any names in the set of [excluded]
  /// names. The [index] is the index of the argument, used to create a name if
  /// no better name could be created. The first name in the list will be the
  /// best name.
  List<String> _getParameterNameSuggestions(
      Set<String> usedNames, DartType type, Expression expression, int index) {
    var suggestions =
        _getVariableNameSuggestionsForExpression(type, expression, usedNames);
    if (suggestions.isNotEmpty) {
      return suggestions;
    }
    // TODO(brianwilkerson) Verify that the name below is not in the set of used names.
    return <String>['param$index'];
  }

  /// Returns possible names for a variable with the given expected type and
  /// expression assigned.
  List<String> _getVariableNameSuggestionsForExpression(DartType expectedType,
      Expression assignedExpression, Set<String> excluded) {
    var res = <String>{};
    // use expression
    if (assignedExpression != null) {
      var nameFromExpression = _getBaseNameFromExpression(assignedExpression);
      if (nameFromExpression != null) {
        nameFromExpression = removeStart(nameFromExpression, '_');
        _addAll(excluded, res, _getCamelWordCombinations(nameFromExpression));
      }
      var nameFromParent = _getBaseNameFromLocationInParent(assignedExpression);
      if (nameFromParent != null) {
        _addAll(excluded, res, _getCamelWordCombinations(nameFromParent));
      }
    }
    // use type
    if (expectedType != null && !expectedType.isDynamic) {
      if (expectedType.isDartCoreInt) {
        _addSingleCharacterName(excluded, res, $i);
      } else if (expectedType.isDartCoreDouble) {
        _addSingleCharacterName(excluded, res, $d);
      } else if (expectedType.isDartCoreString) {
        _addSingleCharacterName(excluded, res, $s);
      } else if (expectedType is InterfaceType) {
        var className = expectedType.element.name;
        _addAll(excluded, res, _getCamelWordCombinations(className));
      }
    }
    // done
    return List.from(res);
  }

  /// If the given [type] is visible in either the [_enclosingExecutable] or
  /// [_enclosingClass], or if there is a local equivalent to the type (such as
  /// in the case of a type parameter from a superclass), then return the type
  /// that is locally visible. Otherwise, return `null`.
  DartType _getVisibleType(DartType type,
      {ExecutableElement methodBeingCopied}) {
    var element = type.element;
    if (type is TypeParameterType) {
      _initializeEnclosingElements();
      var enclosing = element.enclosingElement;
      while (enclosing is GenericFunctionTypeElement ||
          enclosing is ParameterElement) {
        enclosing = enclosing.enclosingElement;
      }
      if (enclosing == _enclosingExecutable ||
          enclosing == _enclosingClass ||
          enclosing == methodBeingCopied) {
        return type;
      }
      return null;
    }
    if (element == null) {
      return type;
    }
    if (element.isPrivate && !dartFileEditBuilder._isDefinedLocally(element)) {
      return null;
    }
    return type;
  }

  /// Initialize the [_enclosingClass] and [_enclosingExecutable].
  void _initializeEnclosingElements() {
    if (!_hasEnclosingElementsInitialized) {
      var finder = _EnclosingElementFinder();
      finder.find(dartFileEditBuilder.resolvedUnit.unit, offset);
      _enclosingClass = finder.enclosingClass;
      _enclosingExecutable = finder.enclosingExecutable;
      _hasEnclosingElementsInitialized = true;
    }
  }

  /// Write the import prefix to reference the [element], if needed.
  ///
  /// The prefix is not needed if the [element] is defined in the target
  /// library, or there is already an import without prefix that exports the
  /// [element]. If there there are no existing import that exports the
  /// [element], a library that exports the [element] is scheduled for import,
  /// possibly with a prefix.
  void _writeLibraryReference(Element element) {
    // If the element is defined in the library, then no prefix needed.
    if (dartFileEditBuilder._isDefinedLocally(element)) {
      return;
    }

    // TODO(scheglov) We should use "methodBeingCopied" to verify that
    // we really are just copying this type parameter.
    if (element is TypeParameterElement) {
      return;
    }

    var import = dartFileEditBuilder._getImportElement(element);
    if (import != null) {
      if (import.prefix != null) {
        write(import.prefix.displayName);
        write('.');
      }
    } else {
      var library = element.library.source.uri;
      var import = dartFileEditBuilder._importLibrary(library);
      if (import.prefix != null) {
        write(import.prefix);
        write('.');
      }
    }
  }

  void _writeSuperMemberInvocation(ExecutableElement element, String memberName,
      List<ParameterElement> parameters) {
    final isOperator = element.isOperator;
    write(isOperator ? ' ' : '.');
    write(memberName);
    write(isOperator ? ' ' : '(');
    for (var i = 0; i < parameters.length; i++) {
      if (i > 0) {
        write(', ');
      }
      write(parameters[i].name);
    }
    write(isOperator ? ';' : ');');
  }

  /// Write the code to reference [type] in this compilation unit.
  ///
  /// If a [methodBeingCopied] is provided, then the type parameters of that
  /// method will be duplicated in the copy and will therefore be visible.
  ///
  /// If [required] it `true`, then the type will be written even if it would
  /// normally be omitted, such as with `dynamic`.
  ///
  /// Causes any libraries whose elements are used by the generated code, to be
  /// imported.
  bool _writeType(DartType type,
      {ExecutableElement methodBeingCopied, bool required = false}) {
    type = _getVisibleType(type, methodBeingCopied: methodBeingCopied);

    // If not a useful type, don't write it.
    if (type == null) {
      return false;
    }
    if (type.isDynamic) {
      if (required) {
        write('dynamic');
        return true;
      }
      return false;
    }
    if (type.isBottom) {
      var library = dartFileEditBuilder.resolvedUnit.libraryElement;
      if (library.isNonNullableByDefault) {
        write('Never');
        return true;
      }
      return false;
    }
    // The type `void` does not have an element.
    if (type is VoidType) {
      write('void');
      return true;
    }

    var element = type.element;
    // Typedef(s) are represented as GenericFunctionTypeElement(s).
    if (element is GenericFunctionTypeElement &&
        element.typeParameters.isEmpty &&
        element.enclosingElement is FunctionTypeAliasElement) {
      element = element.enclosingElement;
    }

    // Just a Function, not FunctionTypeAliasElement.
    if (type is FunctionType && element is! FunctionTypeAliasElement) {
      if (_writeType(type.returnType, methodBeingCopied: methodBeingCopied)) {
        write(' ');
      }
      write('Function');
      writeTypeParameters(type.typeFormals,
          methodBeingCopied: methodBeingCopied);
      writeParameters(type.parameters, methodBeingCopied: methodBeingCopied);
      return true;
    }

    // Ensure that the element is imported.
    _writeLibraryReference(element);

    // Write the simple name.
    var name = element.displayName;
    write(name);

    // Write type arguments.
    if (type is ParameterizedType) {
      var arguments = type.typeArguments;
      // Check if has arguments.
      var hasArguments = false;
      var allArgumentsVisible = true;
      for (var argument in arguments) {
        hasArguments = hasArguments || !argument.isDynamic;
        allArgumentsVisible = allArgumentsVisible &&
            _getVisibleType(argument, methodBeingCopied: methodBeingCopied) !=
                null;
      }
      // Write type arguments only if they are useful.
      if (hasArguments && allArgumentsVisible) {
        write('<');
        for (var i = 0; i < arguments.length; i++) {
          var argument = arguments[i];
          if (i != 0) {
            write(', ');
          }
          _writeType(argument,
              required: true, methodBeingCopied: methodBeingCopied);
        }
        write('>');
      }
    }

    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      write('?');
    }

    return true;
  }
}

/// A [FileEditBuilder] used to build edits for Dart files.
class DartFileEditBuilderImpl extends FileEditBuilderImpl
    implements DartFileEditBuilder {
  /// The resolved unit for the file.
  final ResolvedUnitResult resolvedUnit;

  /// The change builder for the library
  /// or `null` if the receiver is the builder for the library.
  final DartFileEditBuilderImpl libraryChangeBuilder;

  /// The optional generator of prefixes for new imports.
  ImportPrefixGenerator importPrefixGenerator;

  /// A mapping from libraries that need to be imported in order to make visible
  /// the names used in generated code, to information about these imports.
  Map<Uri, _LibraryToImport> librariesToImport = {};

  /// A mapping from libraries that need to be imported relatively in order to
  /// make visible the names used in generated code, to information about these
  /// imports.
  Map<String, _LibraryToImport> librariesToRelativelyImport = {};

  /// Initialize a newly created builder to build a source file edit within the
  /// change being built by the given [changeBuilder]. The file being edited has
  /// the given [resolvedUnit] and [timeStamp].
  DartFileEditBuilderImpl(ChangeBuilderImpl changeBuilder, this.resolvedUnit,
      int timeStamp, this.libraryChangeBuilder)
      : super(changeBuilder, resolvedUnit.path, timeStamp);

  @override
  bool get hasEdits =>
      super.hasEdits ||
      librariesToImport.isNotEmpty ||
      librariesToRelativelyImport.isNotEmpty;

  @override
  void addInsertion(
          int offset, void Function(DartEditBuilder builder) buildEdit) =>
      super.addInsertion(
          offset, (builder) => buildEdit(builder as DartEditBuilder));

  @override
  void addReplacement(SourceRange range,
          void Function(DartEditBuilder builder) buildEdit) =>
      super.addReplacement(
          range, (builder) => buildEdit(builder as DartEditBuilder));

  @override
  void convertFunctionFromSyncToAsync(
      FunctionBody body, TypeProvider typeProvider) {
    if (body == null && body.keyword != null) {
      throw ArgumentError(
          'The function must have a synchronous, non-generator body.');
    }
    if (body is! EmptyFunctionBody) {
      addInsertion(body.offset, (EditBuilder builder) {
        if (_isFusedWithPreviousToken(body.beginToken)) {
          builder.write(' ');
        }
        builder.write('async ');
      });
    }
    _replaceReturnTypeWithFuture(body, typeProvider);
  }

  @override
  DartFileEditBuilderImpl copyWith(ChangeBuilderImpl changeBuilder,
      {Map<DartFileEditBuilderImpl, DartFileEditBuilderImpl> editBuilderMap =
          const {}}) {
    var copy = DartFileEditBuilderImpl(changeBuilder, resolvedUnit,
        fileEdit.fileStamp, editBuilderMap[libraryChangeBuilder]);
    copy.fileEdit.edits.addAll(fileEdit.edits);
    copy.importPrefixGenerator = importPrefixGenerator;
    for (var entry in librariesToImport.entries) {
      copy.librariesToImport[entry.key] = entry.value;
    }
    for (var entry in librariesToRelativelyImport.entries) {
      copy.librariesToRelativelyImport[entry.key] = entry.value;
    }
    return copy;
  }

  @override
  DartEditBuilderImpl createEditBuilder(int offset, int length) {
    return DartEditBuilderImpl(this, offset, length);
  }

  @override
  void finalize() {
    if (librariesToImport.isNotEmpty) {
      _addLibraryImports(librariesToImport.values);
    }
    if (librariesToRelativelyImport.isNotEmpty) {
      _addLibraryImports(librariesToRelativelyImport.values);
    }
  }

  @override
  void format(SourceRange range) {
    var newContent = resolvedUnit.content;
    var newRangeOffset = range.offset;
    var newRangeLength = range.length;
    for (var edit in fileEdit.edits) {
      newContent = edit.apply(newContent);

      var lengthDelta = edit.replacement.length - edit.length;
      if (edit.offset < newRangeOffset) {
        newRangeOffset += lengthDelta;
      } else if (edit.offset < newRangeOffset + newRangeLength) {
        newRangeLength += lengthDelta;
      }
    }

    var formattedResult = DartFormatter().formatSource(
      SourceCode(
        newContent,
        isCompilationUnit: true,
        selectionStart: newRangeOffset,
        selectionLength: newRangeLength,
      ),
    );

    replaceEdits(
      range,
      SourceEdit(
        range.offset,
        range.length,
        formattedResult.selectedText,
      ),
    );
  }

  @override
  String importLibrary(Uri uri) {
    return _importLibrary(uri).uriText;
  }

  @override
  ImportLibraryElementResult importLibraryElement(Uri uri) {
    if (resolvedUnit.libraryElement.source.uri == uri) {
      return ImportLibraryElementResultImpl(null);
    }

    for (var import in resolvedUnit.libraryElement.imports) {
      var importedLibrary = import.importedLibrary;
      if (importedLibrary != null && importedLibrary.source.uri == uri) {
        return ImportLibraryElementResultImpl(import.prefix?.name);
      }
    }

    importLibrary(uri);
    return ImportLibraryElementResultImpl(null);
  }

  String importLibraryWithRelativeUri(String uriText, [String prefix]) {
    return _importLibraryWithRelativeUri(uriText, prefix).uriText;
  }

  @override
  void replaceTypeWithFuture(
      TypeAnnotation typeAnnotation, TypeProvider typeProvider) {
    //
    // Check whether the type needs to be replaced.
    //
    var type = typeAnnotation?.type;
    if (type == null || type.isDynamic || type.isDartAsyncFuture) {
      return;
    }

    addReplacement(range.node(typeAnnotation), (EditBuilder builder) {
      var futureType = typeProvider.futureType2(type);
      if (!(builder as DartEditBuilder).writeType(futureType)) {
        builder.write('void');
      }
    });
  }

  /// Adds edits ensure that all the [imports] are imported into the library.
  void _addLibraryImports(Iterable<_LibraryToImport> imports) {
    // Prepare information about existing imports.
    LibraryDirective libraryDirective;
    var importDirectives = <ImportDirective>[];
    PartDirective partDirective;
    for (var directive in resolvedUnit.unit.directives) {
      if (directive is LibraryDirective) {
        libraryDirective = directive;
      } else if (directive is ImportDirective) {
        importDirectives.add(directive);
      } else if (directive is PartDirective) {
        partDirective = directive;
      }
    }

    // Sort imports by URIs.
    var importList = imports.toList();
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
        var isDart = import.uriText.startsWith('dart:');
        var isPackage = import.uriText.startsWith('package:');
        var inserted = false;

        void insert(
            {ImportDirective prev,
            ImportDirective next,
            bool trailingNewLine = false}) {
          var lineInfo = resolvedUnit.lineInfo;
          if (prev != null) {
            var offset = prev.end;
            var line = lineInfo.getLocation(offset).lineNumber;
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
            var offset = next.offset;
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
        var isLastExistingDart = false;
        var isLastExistingPackage = false;
        for (var existingImport in importDirectives) {
          var existingUri = existingImport.uriContent ?? '';

          var isExistingDart = existingUri.startsWith('dart:');
          var isExistingPackage = existingUri.startsWith('package:');
          var isExistingRelative = !existingUri.contains(':');

          var isNewBeforeExisting = import.uriText.compareTo(existingUri) < 0;

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
        builder.writeln();
        builder.writeln();
        for (var i = 0; i < importList.length; i++) {
          var import = importList[i];
          writeImport(builder, import);
          if (i != importList.length - 1) {
            builder.writeln();
          }
        }
      });
      return;
    }

    // Insert imports: before a part directive.
    if (partDirective != null) {
      addInsertion(partDirective.offset, (EditBuilder builder) {
        for (var i = 0; i < importList.length; i++) {
          var import = importList[i];
          writeImport(builder, import);
          builder.writeln();
        }
        builder.writeln();
      });
      return;
    }

    // If still at the beginning of the file, add before the first declaration.
    int offset;
    var insertEmptyLineAfter = false;
    if (resolvedUnit.unit.declarations.isNotEmpty) {
      offset = resolvedUnit.unit.declarations.first.offset;
      insertEmptyLineAfter = true;
    } else {
      offset = resolvedUnit.unit.end;
    }
    addInsertion(offset, (EditBuilder builder) {
      for (var i = 0; i < importList.length; i++) {
        var import = importList[i];
        writeImport(builder, import);
        builder.writeln();
        if (i == importList.length - 1 && insertEmptyLineAfter) {
          builder.writeln();
        }
      }
    });
  }

  /// Return the import element used to import the given [element] into the
  /// target library, or `null` if the element was not imported, such as when
  /// the element is declared in the same library.
  ImportElement _getImportElement(Element element) {
    for (var import in resolvedUnit.libraryElement.imports) {
      var definedNames = import.namespace.definedNames;
      if (definedNames.containsValue(element)) {
        return import;
      }
    }
    return null;
  }

  Iterable<ImportElement> _getImportsForUri(Uri uri) sync* {
    for (var import in resolvedUnit.libraryElement.imports) {
      var importUri = import.importedLibrary.source.uri;
      if (importUri == uri) {
        yield import;
      }
    }
  }

  /// Computes the best URI to import [uri] into the target library.
  String _getLibraryUriText(Uri uri) {
    if (uri.scheme == 'file') {
      var pathContext = resolvedUnit.session.resourceProvider.pathContext;
      var whatPath = pathContext.fromUri(uri);
      var libraryPath = resolvedUnit.libraryElement.source.fullName;
      var libraryFolder = pathContext.dirname(libraryPath);
      var relativeFile = pathContext.relative(whatPath, from: libraryFolder);
      return pathContext.split(relativeFile).join('/');
    }
    return uri.toString();
  }

  /// Arrange to have an import added for the library with the given [uri].
  _LibraryToImport _importLibrary(Uri uri) {
    var import = (libraryChangeBuilder ?? this).librariesToImport[uri];
    if (import == null) {
      var uriText = _getLibraryUriText(uri);
      var prefix =
          importPrefixGenerator != null ? importPrefixGenerator(uri) : null;
      import = _LibraryToImport(uriText, prefix);
      (libraryChangeBuilder ?? this).librariesToImport[uri] = import;
    }
    return import;
  }

  /// Arrange to have an import added for the library with the given relative
  /// [uriText].
  _LibraryToImport _importLibraryWithRelativeUri(String uriText,
      [String prefix]) {
    var import = librariesToRelativelyImport[uriText];
    if (import == null) {
      import = _LibraryToImport(uriText, prefix);
      librariesToRelativelyImport[uriText] = import;
    }
    return import;
  }

  /// Return `true` if the [element] is defined in the target library.
  bool _isDefinedLocally(Element element) {
    return element.library == resolvedUnit.libraryElement;
  }

  /// Create an edit to replace the return type of the innermost function
  /// containing the given [node] with the type `Future`. The [typeProvider] is
  /// used to check the current return type, because if it is already `Future`
  /// no edit will be added.
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

  static bool _isFusedWithPreviousToken(Token token) {
    return token.previous.end == token.offset;
  }
}

/// A [LinkedEditBuilder] used to build linked edits for Dart files.
///
/// Clients may not extend, implement or mix-in this class.
class DartLinkedEditBuilderImpl extends LinkedEditBuilderImpl
    implements DartLinkedEditBuilder {
  /// Initialize a newly created linked edit builder.
  DartLinkedEditBuilderImpl(EditBuilderImpl editBuilder) : super(editBuilder);

  @override
  void addSuperTypesAsSuggestions(DartType type) {
    _addSuperTypesAsSuggestions(type, <DartType>{});
  }

  /// Safely implement [addSuperTypesAsSuggestions] by using the set of
  /// [alreadyAdded] types to prevent infinite loops.
  void _addSuperTypesAsSuggestions(DartType type, Set<DartType> alreadyAdded) {
    if (type is InterfaceType && alreadyAdded.add(type)) {
      addSuggestion(
        LinkedEditSuggestionKind.TYPE,
        type.getDisplayString(withNullability: false),
      );
      _addSuperTypesAsSuggestions(type.superclass, alreadyAdded);
      for (var interfaceType in type.interfaces) {
        _addSuperTypesAsSuggestions(interfaceType, alreadyAdded);
      }
    }
  }
}

/// Information about a library to import.
class ImportLibraryElementResultImpl implements ImportLibraryElementResult {
  @override
  final String prefix;

  ImportLibraryElementResultImpl(this.prefix);
}

class _EnclosingElementFinder {
  ClassElement enclosingClass;
  ExecutableElement enclosingExecutable;

  _EnclosingElementFinder();

  void find(AstNode target, int offset) {
    var node = NodeLocator2(offset).searchWithin(target);
    while (node != null) {
      if (node is ClassDeclaration) {
        enclosingClass = node.declaredElement;
      } else if (node is ConstructorDeclaration) {
        enclosingExecutable = node.declaredElement;
      } else if (node is MethodDeclaration) {
        enclosingExecutable = node.declaredElement;
      } else if (node is FunctionDeclaration) {
        enclosingExecutable = node.declaredElement;
      }
      node = node.parent;
    }
  }
}

/// Information about a new library to import.
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
