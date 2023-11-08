// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/services/top_level_declarations.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/src/utilities/charcodes.dart';
import 'package:analyzer_plugin/src/utilities/library.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';

/// An [EditBuilder] used to build edits in Dart files.
class DartEditBuilderImpl extends EditBuilderImpl implements DartEditBuilder {
  final List<String> _KNOWN_METHOD_NAME_PREFIXES = ['get', 'is', 'to'];

  /// Whether [_enclosingClass] and [_enclosingExecutable] have been
  /// initialized.
  bool _hasEnclosingElementsInitialized = false;

  /// The enclosing class element, possibly `null`.
  /// This field is lazily initialized in [_initializeEnclosingElements].
  ClassElement? _enclosingClass;

  /// The enclosing executable element, possibly `null`.
  /// This field is lazily initialized in [_initializeEnclosingElements].
  ExecutableElement? _enclosingExecutable;

  /// If not `null`, [write] will copy everything into this buffer.
  StringBuffer? _carbonCopyBuffer;

  /// Whether the target file is non-null by default.
  ///
  /// When `true`, question `?` suffixes will be included on nullable types.
  final bool isNonNullableByDefault;

  /// Initialize a newly created builder to build a source edit.
  DartEditBuilderImpl(DartFileEditBuilderImpl super.sourceFileEditBuilder,
      super.offset, super.length)
      : isNonNullableByDefault = sourceFileEditBuilder
            .resolvedUnit.libraryElement.isNonNullableByDefault;

  DartFileEditBuilderImpl get dartFileEditBuilder =>
      fileEditBuilder as DartFileEditBuilderImpl;

  @override
  void addLinkedEdit(String groupName,
          void Function(DartLinkedEditBuilder builder) buildLinkedEdit) =>
      super.addLinkedEdit(groupName,
          (builder) => buildLinkedEdit(builder as DartLinkedEditBuilder));

  @override
  bool canWriteType(DartType? type, {ExecutableElement? methodBeingCopied}) =>
      type != null && type is! DynamicType
          ? _canWriteType(type, methodBeingCopied: methodBeingCopied)
          : false;

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
      {Iterable<DartType>? interfaces,
      bool isAbstract = false,
      void Function()? membersWriter,
      Iterable<DartType>? mixins,
      String? nameGroupName,
      DartType? superclass,
      String? superclassGroupName}) {
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
      {ArgumentList? argumentList,
      void Function()? bodyWriter,
      String? classNameGroupName,
      String? constructorName,
      String? constructorNameGroupName,
      List<String>? fieldNames,
      void Function()? initializerWriter,
      bool isConst = false,
      void Function()? parameterWriter}) {
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
        write(constructorName);
      } else {
        addSimpleLinkedEdit(constructorNameGroupName, constructorName);
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
      {void Function()? initializerWriter,
      bool isConst = false,
      bool isFinal = false,
      bool isStatic = false,
      String? nameGroupName,
      DartType? type,
      String? typeGroupName}) {
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
      {void Function()? bodyWriter,
      bool isStatic = false,
      String? nameGroupName,
      void Function()? parameterWriter,
      DartType? returnType,
      String? returnTypeGroupName}) {
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
      {void Function()? bodyWriter,
      bool isStatic = false,
      String? nameGroupName,
      DartType? returnType,
      String? returnTypeGroupName}) {
    if (isStatic) {
      write(Keyword.STATIC.lexeme);
      write(' ');
    }
    if (returnType != null && returnType is! DynamicType) {
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
    var imports = <LibraryImportElement>[];
    for (var uri in uris) {
      imports.addAll(dartFileEditBuilder._getImportsForUri(uri));
    }
    var import = _getBestImportForName(imports, name);
    if (import == null) {
      var library = dartFileEditBuilder._importLibrary(uris[0]);
      var prefix = library.prefix;
      if (prefix.isNotEmpty) {
        write(prefix);
        write('.');
      }
    } else {
      var prefix = import.prefix;
      if (prefix != null) {
        write(prefix.element.displayName);
        write('.');
      }
    }
    write(name);
  }

  @override
  void writeLocalVariableDeclaration(String name,
      {void Function()? initializerWriter,
      bool isConst = false,
      bool isFinal = false,
      String? nameGroupName,
      DartType? type,
      String? typeGroupName}) {
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
      {Iterable<DartType>? interfaces,
      void Function()? membersWriter,
      String? nameGroupName,
      Iterable<DartType>? superclassConstraints}) {
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
    StringBuffer? displayTextBuffer,
    String? returnTypeGroupName,
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
      writeln('// TODO: implement $memberName');
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
      } else if (returnType is VoidType) {
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
      ExecutableElement? methodBeingCopied,
      String? nameGroupName,
      DartType? type,
      String? typeGroupName,
      bool isRequiredType = false}) {
    bool writeType() {
      if (typeGroupName != null) {
        late bool hasType;
        addLinkedEdit(typeGroupName, (DartLinkedEditBuilder builder) {
          hasType = _writeType(type,
              methodBeingCopied: methodBeingCopied, required: isRequiredType);
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
    if (argument is NamedExpression &&
        isNonNullableByDefault &&
        type.nullabilitySuffix == NullabilitySuffix.none) {
      write('required ');
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
      {ExecutableElement? methodBeingCopied,
      bool includeDefaultValues = true,
      bool requiredTypes = false}) {
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
          typeGroupName: '${groupPrefix}TYPE$i',
          isRequiredType: requiredTypes);
      // default value
      if (includeDefaultValues) {
        var defaultCode = parameter.defaultValueCode;
        if (defaultCode != null) {
          write(' = ');
          write(defaultCode);
        }
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
      {void Function()? bodyWriter,
      bool isStatic = false,
      String? nameGroupName,
      DartType? parameterType,
      String? parameterTypeGroupName}) {
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
    if (parameterType != null && parameterType is! DynamicType) {
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
  bool writeType(DartType? type,
      {bool addSupertypeProposals = false,
      String? groupName,
      ExecutableElement? methodBeingCopied,
      bool required = false}) {
    var wroteType = false;
    if (type != null && type is! DynamicType) {
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
      {ExecutableElement? methodBeingCopied}) {
    write(typeParameter.name);
    if (typeParameter.bound != null) {
      write(' extends ');
      _writeType(typeParameter.bound, methodBeingCopied: methodBeingCopied);
    }
  }

  @override
  void writeTypeParameters(List<TypeParameterElement> typeParameters,
      {ExecutableElement? methodBeingCopied}) {
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
  void writeTypes(Iterable<DartType>? types, {String? prefix}) {
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
      LinkedEditBuilder builder, DartType? type, Set<DartType> alreadyAdded) {
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

  /// Check if the code to reference [type] in this compilation unit can be
  /// written.
  ///
  /// See also [_writeType]
  bool _canWriteType(DartType? type,
      {ExecutableElement? methodBeingCopied, bool required = false}) {
    type = _getVisibleType(type, methodBeingCopied: methodBeingCopied);

    // If not a useful type, don't write it.
    if (type == null) {
      return false;
    }
    if (type is DynamicType || type is InvalidType) {
      if (required) {
        return true;
      }
      return false;
    }
    if (type.isBottom) {
      if (isNonNullableByDefault) {
        return true;
      }
      return false;
    }

    var alias = type.alias;
    if (alias != null) {
      return true;
    }

    if (type is FunctionType) {
      return true;
    }

    if (type is InterfaceType) {
      return true;
    }

    if (type is NeverType) {
      return true;
    }

    if (type is TypeParameterType) {
      return true;
    }

    if (type is VoidType) {
      return true;
    }

    if (type is RecordType) {
      // TODO(brianwilkerson) This should return `false` if the `records`
      //  feature is not enabled.
      return true;
    }

    throw UnimplementedError('(${type.runtimeType}) $type');
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

  String? _getBaseNameFromExpression(Expression expression) {
    if (expression is AsExpression) {
      return _getBaseNameFromExpression(expression.expression);
    } else if (expression is ParenthesizedExpression) {
      return _getBaseNameFromExpression(expression.expression);
    }
    return _getBaseNameFromUnwrappedExpression(expression);
  }

  String? _getBaseNameFromLocationInParent(Expression expression) {
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

  String? _getBaseNameFromUnwrappedExpression(Expression expression) {
    String? name;
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
      var namedType = constructorName.type;
      var importPrefix = namedType.importPrefix;
      // new ClassName()
      if (importPrefix == null) {
        return namedType.name2.lexeme;
      }
      // new prefix.ClassName()
      if (importPrefix.element is PrefixElement) {
        return namedType.name2.lexeme;
      }
      // new ClassName.constructorName()
      return importPrefix.name.lexeme;
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
  LibraryImportElement? _getBestImportForName(
      List<LibraryImportElement> imports, String name) {
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
  List<String> _getCamelWordCombinations(String? name) {
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
  List<String> _getVariableNameSuggestionsForExpression(DartType? expectedType,
      Expression? assignedExpression, Set<String> excluded) {
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
    if (expectedType != null && expectedType is! DynamicType) {
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
  DartType? _getVisibleType(DartType? type,
      {ExecutableElement? methodBeingCopied}) {
    if (type is InterfaceType) {
      var element = type.element;
      if (element.isPrivate &&
          !dartFileEditBuilder._isDefinedLocally(element)) {
        return null;
      }
      return type;
    }
    if (type is TypeParameterType) {
      _initializeEnclosingElements();
      var element = type.element;
      var enclosing = element.enclosingElement;
      while (enclosing is GenericFunctionTypeElement ||
          enclosing is ParameterElement) {
        enclosing = enclosing!.enclosingElement;
      }
      if (enclosing == _enclosingExecutable ||
          enclosing == _enclosingClass ||
          enclosing == methodBeingCopied) {
        return type;
      }
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
  /// [element]. If there are no existing import that exports the
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
      var prefix = import.prefix;
      if (prefix.isNotEmpty) {
        write(prefix);
        write('.');
      }
    } else {
      var library = element.library?.source.uri;
      if (library != null) {
        var import = dartFileEditBuilder._importLibrary(library);
        var prefix = import.prefix;
        if (prefix.isNotEmpty) {
          write(prefix);
          write('.');
        }
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
  bool _writeType(DartType? type,
      {ExecutableElement? methodBeingCopied, bool required = false}) {
    type = _getVisibleType(type, methodBeingCopied: methodBeingCopied);

    // If not a useful type, don't write it.
    if (type == null) {
      return false;
    }
    if (type is DynamicType || type is InvalidType) {
      if (required) {
        write('dynamic');
        return true;
      }
      return false;
    }
    if (type.isBottom) {
      if (isNonNullableByDefault) {
        write('Never');
        return true;
      }
      return false;
    }

    var alias = type.alias;
    if (alias != null) {
      _writeTypeElementArguments(
        element: alias.element,
        typeArguments: alias.typeArguments,
        methodBeingCopied: methodBeingCopied,
      );
      _writeTypeNullability(type);
      return true;
    }

    if (type is FunctionType) {
      if (_writeType(type.returnType, methodBeingCopied: methodBeingCopied)) {
        write(' ');
      }
      write('Function');
      writeTypeParameters(type.typeFormals,
          methodBeingCopied: methodBeingCopied);
      writeParameters(
        type.parameters,
        methodBeingCopied: methodBeingCopied,
        includeDefaultValues: false,
        requiredTypes: true,
      );
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        write('?');
      }
      return true;
    }

    if (type is InterfaceType) {
      _writeTypeElementArguments(
        element: type.element,
        typeArguments: type.typeArguments,
        methodBeingCopied: methodBeingCopied,
      );
      _writeTypeNullability(type);
      return true;
    }

    if (type is NeverType) {
      write('Never');
      _writeTypeNullability(type);
      return true;
    }

    if (type is TypeParameterType) {
      write(type.element.name);
      _writeTypeNullability(type);
      return true;
    }

    if (type is VoidType) {
      write('void');
      return true;
    }

    if (type is RecordType) {
      // TODO(brianwilkerson) This should return `false` if the `records`
      //  feature is not enabled. More importantly, we can't currently return
      //  `false` if some portion of a type has already been written, so we
      //  need to figure out what to do when a record type is nested in another
      //  type in a context where it isn't allowed. For example, we might
      //  enhance `_canWriteType` to be recursive, then guard all invocations of
      //  this method with a call to `_canWriteType` (and remove the return type
      //  from this method).
      write('(');
      var isFirst = true;
      for (var field in type.positionalFields) {
        if (isFirst) {
          isFirst = false;
        } else {
          write(', ');
        }
        _writeType(field.type);
      }
      var namedFields = type.namedFields;
      if (namedFields.isNotEmpty) {
        if (isFirst) {
          write('{');
        } else {
          write(', {');
        }
        isFirst = true;
        for (var field in namedFields) {
          if (isFirst) {
            isFirst = false;
          } else {
            write(', ');
          }
          _writeType(field.type);
          write(' ');
          write(field.name);
        }
        write('}');
      }
      write(')');
      _writeTypeNullability(type);
      return true;
    }

    throw UnimplementedError('(${type.runtimeType}) $type');
  }

  void _writeTypeElementArguments({
    required Element element,
    required List<DartType> typeArguments,
    required ExecutableElement? methodBeingCopied,
  }) {
    // Ensure that the element is imported.
    _writeLibraryReference(element);

    // Write the simple name.
    var name = element.displayName;
    write(name);

    // Write type arguments.
    if (typeArguments.isNotEmpty) {
      // Check if has arguments.
      var hasArguments = false;
      var allArgumentsVisible = true;
      for (var argument in typeArguments) {
        hasArguments = hasArguments || argument is! DynamicType;
        allArgumentsVisible = allArgumentsVisible &&
            _getVisibleType(argument, methodBeingCopied: methodBeingCopied) !=
                null;
      }
      // Write type arguments only if they are useful.
      if (hasArguments && allArgumentsVisible) {
        write('<');
        for (var i = 0; i < typeArguments.length; i++) {
          var argument = typeArguments[i];
          if (i != 0) {
            write(', ');
          }
          _writeType(argument,
              required: true, methodBeingCopied: methodBeingCopied);
        }
        write('>');
      }
    }
  }

  void _writeTypeNullability(DartType type) {
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      write('?');
    }
  }
}

/// A [FileEditBuilder] used to build edits for Dart files.
class DartFileEditBuilderImpl extends FileEditBuilderImpl
    implements DartFileEditBuilder {
  /// The resolved unit for the file.
  final ResolvedUnitResult resolvedUnit;

  /// The change builder for the library
  /// or `null` if the receiver is the builder for the library.
  final DartFileEditBuilderImpl? libraryChangeBuilder;

  @override
  String? fileHeader;

  /// Whether to create edits that add imports for any written types that are
  /// not already imported.
  final bool createEditsForImports;

  /// The optional generator of prefixes for new imports.
  ImportPrefixGenerator? importPrefixGenerator;

  /// A mapping from libraries that need to be imported in order to make visible
  /// the names used in generated code, to information about these imports.
  Map<Uri, _LibraryImport> librariesToImport = {};

  /// A mapping of [Element]s to pending imports that will be added to make
  /// them visible in the generated code.
  final Map<Element, _LibraryImport> _elementLibrariesToImport = {};

  /// Initialize a newly created builder to build a source file edit within the
  /// change being built by the given [changeBuilder]. The file being edited has
  /// the given [resolvedUnit] and [timeStamp].
  DartFileEditBuilderImpl(ChangeBuilderImpl changeBuilder, this.resolvedUnit,
      int timeStamp, this.libraryChangeBuilder,
      {this.createEditsForImports = true})
      : super(changeBuilder, resolvedUnit.path, timeStamp);

  CodeStyleOptions get codeStyleOptions => resolvedUnit.session.analysisContext
      .getAnalysisOptionsForFile(resolvedUnit.file)
      .codeStyleOptions;

  @override
  bool get hasEdits =>
      super.hasEdits || librariesToImport.isNotEmpty || fileHeader != null;

  @override
  List<Uri> get requiredImports => librariesToImport.keys.toList();

  @override
  void addInsertion(
          int offset, void Function(DartEditBuilder builder) buildEdit,
          {bool insertBeforeExisting = false}) =>
      super.addInsertion(
          offset, (builder) => buildEdit(builder as DartEditBuilder),
          insertBeforeExisting: insertBeforeExisting);

  @override
  void addReplacement(SourceRange range,
          void Function(DartEditBuilder builder) buildEdit) =>
      super.addReplacement(
          range, (builder) => buildEdit(builder as DartEditBuilder));

  @override
  bool canWriteType(DartType? type, {ExecutableElement? methodBeingCopied}) {
    var builder = createEditBuilder(0, 0);
    return builder.canWriteType(type, methodBeingCopied: methodBeingCopied);
  }

  @override
  void convertFunctionFromSyncToAsync(
      FunctionBody? body, TypeProvider typeProvider) {
    if (body == null || body.keyword != null) {
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
        fileEdit.fileStamp, editBuilderMap[libraryChangeBuilder],
        createEditsForImports: createEditsForImports);
    copy.fileEdit.edits.addAll(fileEdit.edits);
    copy.importPrefixGenerator = importPrefixGenerator;
    for (var entry in librariesToImport.entries) {
      copy.librariesToImport[entry.key] = entry.value;
    }
    for (var entry in _elementLibrariesToImport.entries) {
      copy._elementLibrariesToImport[entry.key] = entry.value;
    }
    return copy;
  }

  @override
  DartEditBuilderImpl createEditBuilder(int offset, int length) {
    return DartEditBuilderImpl(this, offset, length);
  }

  @override
  void finalize() {
    if (createEditsForImports && librariesToImport.isNotEmpty) {
      _addLibraryImports(librariesToImport.values);
    }
    var header = fileHeader;
    if (header != null) {
      addInsertion(0, insertBeforeExisting: true, (builder) {
        builder.writeln(header);
      });
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

  /// Arrange to have an import added that makes [element] available.
  ///
  /// If [element] is already available in the current library, does nothing.
  ///
  /// If the library [element] is declared in is inside the `src` folder, will
  /// try to locate a public URI to import instead.
  ///
  /// If [useShow] is `true`, new imports will be added that `show` only the
  /// requested element (or if there is a pending import for the library, added
  /// to its `show` combinator).
  Future<void> importElementLibrary(Element element,
      {Map<Element, LibraryElement?>? resultCache,
      bool useShow = false}) async {
    if (_isDefinedLocally(element)) {
      return;
    }

    var existingImport = _getImportElement(element);
    var name = element.name;
    if (existingImport != null && name != null) {
      existingImport.ensureShown(name);
      return;
    }

    var libraryWithElement = resultCache?[element] ??
        await TopLevelDeclarations(resolvedUnit)
            .publiclyExporting(element, resultCache: resultCache);
    if (libraryWithElement != null) {
      _elementLibrariesToImport[element] = _importLibrary(
        libraryWithElement.source.uri,
        showName: useShow ? element.name : null,
      );
      return;
    }

    // If we didn't find one, use the original URI.
    var uri = element.source?.uri;
    if (uri != null) {
      _importLibrary(uri, showName: useShow ? element.name : null);
    }
  }

  @override
  String importLibrary(Uri uri, {String? prefix, String? showName}) {
    return _importLibrary(uri, prefix: prefix, showName: showName).uriText;
  }

  @override
  ImportLibraryElementResult importLibraryElement(Uri uri) {
    if (resolvedUnit.libraryElement.source.uri == uri) {
      return ImportLibraryElementResultImpl(null);
    }

    for (var import in resolvedUnit.libraryElement.libraryImports) {
      var importedLibrary = import.importedLibrary;
      if (importedLibrary != null && importedLibrary.source.uri == uri) {
        return ImportLibraryElementResultImpl(import.prefix?.element.name);
      }
    }

    importLibrary(uri);
    return ImportLibraryElementResultImpl(null);
  }

  String importLibraryWithAbsoluteUri(Uri uri, [String? prefix]) {
    return _importLibrary(uri, prefix: prefix, forceAbsolute: true).uriText;
  }

  String importLibraryWithRelativeUri(Uri uri, [String? prefix]) {
    return _importLibrary(uri, prefix: prefix, forceRelative: true).uriText;
  }

  @override
  bool importsLibrary(Uri uri) {
    // Self-reference.
    if (resolvedUnit.libraryElement.source.uri == uri) return false;

    // Existing import.
    for (var import in resolvedUnit.libraryElement.libraryImports) {
      var importedLibrary = import.importedLibrary;
      if (importedLibrary != null && importedLibrary.source.uri == uri) {
        return true;
      }
    }

    // Queued change.
    var importChange = (libraryChangeBuilder ?? this).librariesToImport[uri];
    if (importChange != null) return true;

    return false;
  }

  @override
  void replaceTypeWithFuture(
      TypeAnnotation? typeAnnotation, TypeProvider typeProvider) {
    //
    // Check whether the type needs to be replaced.
    //
    var type = typeAnnotation?.type;
    if (type == null || type is DynamicType || type.isDartAsyncFuture) {
      return;
    }

    addReplacement(range.node(typeAnnotation!), (builder) {
      var futureType = typeProvider.futureType(type);
      if (!builder.writeType(futureType)) {
        builder.write('void');
      }
    });
  }

  /// Adds edits ensure that all the [imports] are imported into the library.
  void _addLibraryImports(Iterable<_LibraryImport> imports) {
    // Prepare information about existing imports.
    LibraryDirective? libraryDirective;
    var importDirectives = <ImportDirective>[];
    ExportDirective? firstExportDirective;
    PartDirective? firstPartDirective;
    var unit = resolvedUnit.unit;
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        libraryDirective = directive;
      } else if (directive is ImportDirective) {
        importDirectives.add(directive);
      } else if (directive is ExportDirective) {
        firstExportDirective ??= directive;
      } else if (directive is PartDirective) {
        firstPartDirective ??= directive;
      }
    }

    // Sort imports by URIs.
    var importList = imports.toList();
    importList.sort((a, b) => a.uriText.compareTo(b.uriText));

    var quote = codeStyleOptions.preferredQuoteForUris(importDirectives);
    void writeImport(EditBuilder builder, _LibraryImport import) {
      assert(import.prefixes.isNotEmpty);
      var isFirst = true;
      for (var prefix in import.prefixes.sorted()) {
        if (!isFirst) {
          builder.writeln();
        }
        isFirst = false;
        builder.write('import $quote');
        builder.write(import.uriText);
        builder.write(quote);
        if (prefix.isNotEmpty) {
          builder.write(' as ');
          builder.write(prefix);
        }
        if (import.showNames.isNotEmpty) {
          builder.write(' show ');
          builder.write(import.showNames.join(', '));
        }
        if (import.hideNames.isNotEmpty) {
          builder.write(' hide ');
          builder.write(import.hideNames.join(', '));
        }
        builder.write(';');
      }
    }

    // Insert imports: between existing imports.
    if (importDirectives.isNotEmpty) {
      for (var import in importList) {
        var isDart = import.uriText.startsWith('dart:');
        var isPackage = import.uriText.startsWith('package:');
        var inserted = false;

        void insert(
            {ImportDirective? prev,
            required ImportDirective next,
            bool trailingNewLine = false}) {
          var lineInfo = resolvedUnit.lineInfo;
          if (prev != null) {
            var offset = prev.end;
            var line = lineInfo.getLocation(offset).lineNumber;
            Token? comment = prev.endToken.next?.precedingComments;
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
            // Annotations attached to the first directive should remain above
            // the newly inserted import, as they are treated as being for the
            // file.
            var isFirst =
                next == (next.parent as CompilationUnit).directives.first;
            var offset = isFirst
                ? next.firstTokenAfterCommentAndMetadata.offset
                : next.offset;
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

        ImportDirective? lastExisting;
        ImportDirective? lastExistingDart;
        ImportDirective? lastExistingPackage;
        var isLastExistingDart = false;
        var isLastExistingPackage = false;
        for (var existingImport in importDirectives) {
          var existingUri = existingImport.uri.stringValue ?? '';

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
          addInsertion(lastExisting!.end, (EditBuilder builder) {
            if (isPackage) {
              if (isLastExistingDart) {
                builder.writeln();
              }
            } else {
              if (!isDart && (isLastExistingDart || isLastExistingPackage)) {
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

    // Insert imports: before any export directives.
    if (firstExportDirective != null) {
      addInsertion(firstExportDirective.offset, (EditBuilder builder) {
        for (var i = 0; i < importList.length; i++) {
          var import = importList[i];
          writeImport(builder, import);
          builder.writeln();
        }
        builder.writeln();
      });
      return;
    }

    // Insert imports: before any part directives.
    if (firstPartDirective != null) {
      addInsertion(firstPartDirective.offset, (EditBuilder builder) {
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
    if (unit.declarations.isNotEmpty) {
      offset = unit.declarations.first.offset;
      insertEmptyLineAfter = true;
    } else if (fileEdit.edits.isNotEmpty) {
      // If this file has edits (besides the imports) the imports should go
      // at the same offset as those edits and _not_ at `unit.end`. This is
      // because if the document is non-zero length, `unit.end` could be after
      // where the new edits will be inserted, but imports should go before
      // generated non-import code.

      // Edits are always sorted such that the first one has the lowest offset.
      offset = fileEdit.edits.first.offset;

      // Also ensure there's a blank line between the imports and the other
      // code.
      insertEmptyLineAfter = fileEdit.edits.isNotEmpty;
    } else {
      offset = unit.end;
    }
    addInsertion(
      offset,
      (EditBuilder builder) {
        for (var i = 0; i < importList.length; i++) {
          var import = importList[i];
          writeImport(builder, import);
          builder.writeln();
          if (i == importList.length - 1 && insertEmptyLineAfter) {
            builder.writeln();
          }
        }
      },
      insertBeforeExisting: true,
    );
  }

  /// Return information about the library used to import the given [element]
  /// into the target library, or `null` if the element was not imported, such
  /// as when the element is declared in the same library.
  ///
  /// The result may be an existing import, or one that is pending.
  _LibraryImport? _getImportElement(Element element) {
    for (var import in resolvedUnit.libraryElement.libraryImports) {
      var definedNames = import.namespace.definedNames;
      if (definedNames.containsValue(element)) {
        return _LibraryImport(
          uriText: import.librarySource.uri.toString(),
          prefix: import.prefix?.element.displayName ?? '',
        );
      }
    }

    return _elementLibrariesToImport[element];
  }

  Iterable<LibraryImportElement> _getImportsForUri(Uri uri) sync* {
    for (var import in resolvedUnit.libraryElement.libraryImports) {
      var importUri = import.importedLibrary?.source.uri;
      if (importUri == uri) {
        yield import;
      }
    }
  }

  /// Computes the best URI to import [uri] into the target library.
  ///
  /// [uri] may be converted from an absolute URI to a relative URI depending on
  /// user preferences/lints unless [forceAbsolute] or [forceRelative] are `true`.
  String _getLibraryUriText(
    Uri uri, {
    bool forceAbsolute = false,
    bool forceRelative = false,
  }) {
    var pathContext = resolvedUnit.session.resourceProvider.pathContext;

    /// Returns the relative path to import [whatPath] into [resolvedUnit].
    String getRelativePath(String whatPath) {
      var libraryPath = resolvedUnit.libraryElement.source.fullName;
      var libraryFolder = pathContext.dirname(libraryPath);
      var relativeFile = pathContext.relative(whatPath, from: libraryFolder);
      return pathContext.split(relativeFile).join('/');
    }

    if (uri.isScheme('file')) {
      var whatPath = pathContext.fromUri(uri);
      return getRelativePath(whatPath);
    }
    var preferRelative = codeStyleOptions.useRelativeUris;
    if (forceRelative || (preferRelative && !forceAbsolute)) {
      if (canBeRelativeImport(uri, resolvedUnit.uri)) {
        var whatPath = resolvedUnit.session.uriConverter.uriToPath(uri);
        if (whatPath != null) {
          return getRelativePath(whatPath);
        }
      }
    }
    return uri.toString();
  }

  /// Arrange to have an import added for the library with the given [uri].
  ///
  /// [uri] may be converted from an absolute URI to a relative URI depending on
  /// user preferences/lints unless [forceAbsolute] or [forceRelative] are `true`.
  ///
  /// If [prefix] is an empty string, adds the import without a prefix.
  /// If [prefix] is null, will use [importPrefixGenerator] to generate one or
  /// reuse an existing prefix for this import.
  ///
  /// If [showName] is supplied then any new import will show only this element,
  /// or if an import already exists it will be added to 'show' or removed from
  /// 'hide' if appropriate.
  _LibraryImport _importLibrary(
    Uri uri, {
    String? prefix,
    String? showName,
    bool forceAbsolute = false,
    bool forceRelative = false,
  }) {
    var import = (libraryChangeBuilder ?? this).librariesToImport[uri];
    if (import != null) {
      if (prefix != null) {
        import.prefixes.add(prefix);
      }
      if (showName != null) {
        import.ensureShown(showName);
      }
    } else {
      var uriText = _getLibraryUriText(uri,
          forceAbsolute: forceAbsolute, forceRelative: forceRelative);
      prefix ??=
          importPrefixGenerator != null ? importPrefixGenerator!(uri) : null;
      import = _LibraryImport(
        uriText: uriText,
        prefix: prefix ?? '',
        showNames: showName != null ? {showName} : null,
      );
      (libraryChangeBuilder ?? this).librariesToImport[uri] = import;
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
  void _replaceReturnTypeWithFuture(AstNode? node, TypeProvider typeProvider) {
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
    return token.previous?.end == token.offset;
  }
}

/// A [LinkedEditBuilder] used to build linked edits for Dart files.
///
/// Clients may not extend, implement or mix-in this class.
class DartLinkedEditBuilderImpl extends LinkedEditBuilderImpl
    implements DartLinkedEditBuilder {
  /// Initialize a newly created linked edit builder.
  DartLinkedEditBuilderImpl(DartEditBuilderImpl super.editBuilder);

  DartEditBuilderImpl get dartEditBuilder => editBuilder as DartEditBuilderImpl;

  @override
  void addSuperTypesAsSuggestions(DartType? type) {
    if (type is InterfaceType) {
      _addTypeAsSuggestions(type);
      type.allSupertypes.forEach(_addTypeAsSuggestions);
    }
  }

  void _addTypeAsSuggestions(InterfaceType type) {
    addSuggestion(
      LinkedEditSuggestionKind.TYPE,
      _getTypeSuggestionText(type),
    );
  }

  String _getTypeSuggestionText(InterfaceType type) {
    // Add the suffix manually, because it should only be included for '?' and
    // not '*'.
    var typeDisplay = type.getDisplayString(withNullability: false);
    return dartEditBuilder.isNonNullableByDefault &&
            type.nullabilitySuffix == NullabilitySuffix.question
        ? '$typeDisplay?'
        : typeDisplay;
  }
}

/// Information about a library to import.
class ImportLibraryElementResultImpl implements ImportLibraryElementResult {
  @override
  final String? prefix;

  ImportLibraryElementResultImpl(this.prefix);
}

class _EnclosingElementFinder {
  ClassElement? enclosingClass;
  ExecutableElement? enclosingExecutable;

  _EnclosingElementFinder();

  void find(AstNode? target, int offset) {
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

/// Information about a library import.
class _LibraryImport {
  final String uriText;

  /// Prefixes that this library is/will be imported using.
  ///
  /// An empty string means the import is unprefixed. This can be included along
  /// with other prefixes for a library that is both prefixed and unprefixed.
  final Set<String> prefixes = {};

  /// Names this import has in its `show` combinator.
  final Set<String> showNames;

  /// Names this import has in its `hide` combinator.
  final Set<String> hideNames;

  _LibraryImport({
    required this.uriText,
    required String prefix,
    Set<String>? showNames,
    Set<String>? hideNames,
  })  : showNames = showNames ?? {},
        hideNames = hideNames ?? {} {
    prefixes.add(prefix);
  }

  @override
  int get hashCode => uriText.hashCode;

  /// Returns a prefix that is valid for referencing this library.
  ///
  /// An empty string means this library can be used unprefixed.
  String get prefix => prefixes.first;

  @override
  bool operator ==(other) {
    return other is _LibraryImport &&
        other.uriText == uriText &&
        !const SetEquality().equals(other.prefixes, prefixes);
  }

  /// Ensures [name] is visible for this import.
  ///
  /// If the import already has a show combinator, this name will be added.
  /// If the import hides this name, it will be unhidden.
  void ensureShown(String name) {
    if (showNames.isNotEmpty) {
      showNames.add(name);
    }
    hideNames.remove(name);
  }
}
