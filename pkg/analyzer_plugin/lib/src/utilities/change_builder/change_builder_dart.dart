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
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/services/top_level_declarations.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/src/utilities/charcodes.dart';
import 'package:analyzer_plugin/src/utilities/directive_sort.dart';
import 'package:analyzer_plugin/src/utilities/extensions/resolved_unit_result.dart';
import 'package:analyzer_plugin/src/utilities/library.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';

/// An [EditBuilder] used to build edits in Dart files.
class DartEditBuilderImpl extends EditBuilderImpl implements DartEditBuilder {
  static const List<String> _knownMethodNamePrefixes = ['get', 'is', 'to'];

  /// Whether [_enclosingClass] and [_enclosingExecutable] have been
  /// initialized.
  bool _hasEnclosingElementsInitialized = false;

  /// The enclosing class element, or `null` if the region that will be modified
  /// by the edit isn't inside a class declaration.
  ///
  /// This field is lazily initialized in [_initializeEnclosingElements].
  ClassElement? _enclosingClass;

  /// The enclosing executable element, possibly `null`.
  ///
  /// This field is lazily initialized in [_initializeEnclosingElements].
  ExecutableElement? _enclosingExecutable;

  /// If not `null`, [write] will copy everything into this buffer.
  StringBuffer? _carbonCopyBuffer;

  DartEditBuilderImpl(
    DartFileEditBuilderImpl super.sourceFileEditBuilder,
    super.offset,
    super.length, {
    super.description,
  });

  CodeStyleOptions get _codeStyleOptions =>
      _dartFileEditBuilder._codeStyleOptions;

  DartFileEditBuilderImpl get _dartFileEditBuilder =>
      fileEditBuilder as DartFileEditBuilderImpl;

  FeatureSet get _featureSet => _libraryElement.featureSet;

  LibraryElement get _libraryElement => _dartFileEditBuilder._libraryElement;

  TypeProvider get _typeProvider =>
      _dartFileEditBuilder.resolvedUnit.typeProvider;

  @override
  void addLinkedEdit(
    String groupName,
    void Function(DartLinkedEditBuilder builder) buildLinkedEdit,
  ) => super.addLinkedEdit(
    groupName,
    (builder) => buildLinkedEdit(builder as DartLinkedEditBuilder),
  );

  @override
  bool canWriteType(
    DartType? type, {
    List<TypeParameterElement>? typeParametersInScope,
  }) {
    return type != null && type is! DynamicType
        ? _canWriteType(
            type,
            typeParametersInScope: typeParametersInScope?.toSet(),
          )
        : false;
  }

  @override
  LinkedEditBuilderImpl createLinkedEditBuilder() {
    return DartLinkedEditBuilderImpl(this);
  }

  @override
  String getIndent(int level) => '  ' * level;

  @override
  void write(String string) {
    super.write(string);
    _carbonCopyBuffer?.write(string);
  }

  @override
  void writeClassDeclaration(
    String name, {
    Iterable<DartType>? interfaces,
    bool isAbstract = false,
    void Function()? membersWriter,
    Iterable<DartType>? mixins,
    String? nameGroupName,
    DartType? superclass,
    String? superclassGroupName,
  }) {
    // TODO(brianwilkerson): Add support for type parameters, probably as a
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
  void writeConstructorDeclaration(
    String className, {
    ArgumentList? argumentList,
    void Function()? bodyWriter,
    String? classNameGroupName,
    String? constructorName,
    String? constructorNameGroupName,
    List<String>? fieldNames,
    void Function()? initializerWriter,
    bool isConst = false,
    void Function()? parameterWriter,
  }) {
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
  void writeFieldDeclaration(
    String name, {
    void Function()? initializerWriter,
    bool isConst = false,
    bool isFinal = false,
    bool isStatic = false,
    String? nameGroupName,
    DartType? type,
    String? typeGroupName,
    bool alwaysWriteType = false,
    List<TypeParameterElement>? typeParametersInScope,
  }) {
    alwaysWriteType = alwaysWriteType || _codeStyleOptions.specifyTypes;
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
    if (type != null || alwaysWriteType) {
      // `writeType` will write `var` for `dynamic`, which we cannot use after
      // `final`.
      if ((isFinal || alwaysWriteType) && type is DynamicType) {
        write(Keyword.DYNAMIC.lexeme);
      } else {
        writeType(
          type,
          groupName: typeGroupName,
          required: !isFinal,
          shouldWriteDynamic: alwaysWriteType,
          typeParametersInScope: typeParametersInScope,
        );
      }
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
  void writeFormalParameter(
    String name, {
    bool isCovariant = false,
    bool isRequiredNamed = false,
    List<TypeParameterElement>? typeParametersInScope,
    String? nameGroupName,
    DartType? type,
    String? typeGroupName,
    bool isRequiredType = false,
  }) {
    bool writeType() {
      if (typeGroupName != null) {
        late bool hasType;
        addLinkedEdit(typeGroupName, (DartLinkedEditBuilder builder) {
          hasType = _writeTypeIfCan(
            type,
            typeParametersInScope: typeParametersInScope,
            shouldWriteDynamic: isRequiredType,
          );
          builder.addSuperTypesAsSuggestions(type);
        });
        return hasType;
      }
      return _writeTypeIfCan(
        type,
        typeParametersInScope: typeParametersInScope,
        shouldWriteDynamic: isRequiredType,
      );
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
      write('required ');
    }
    type ??= _typeProvider.objectQuestionType;
    var hasType = writeType();
    if (name.isNotEmpty) {
      if (hasType) {
        write(' ');
      }
      writeName();
    }
  }

  @override
  void writeFormalParameters(
    Iterable<FormalParameterElement> parameters, {
    List<TypeParameterElement>? typeParametersInScope,
    String? groupNamePrefix,
    bool fillParameterNames = true,
    bool includeDefaultValues = true,
    bool requiredTypes = false,
  }) {
    var parameterNames = parameters.map((e) => e.name).nonNulls.toSet();

    write('(');
    var sawNamed = false;
    var sawPositional = false;
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters.elementAt(i);
      if (i > 0) {
        write(', ');
      }
      // Might be optional.
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
      // Parameter.
      var name = parameter.name;
      if ((name == null || name == '') && fillParameterNames) {
        name = _generateUniqueName(parameterNames);
        parameterNames.add(name);
      }
      var groupPrefix = groupNamePrefix != null ? '$groupNamePrefix:' : '';
      writeFormalParameter(
        name ?? '',
        isCovariant: parameter.isCovariant,
        isRequiredNamed: parameter.isRequiredNamed,
        typeParametersInScope: typeParametersInScope,
        nameGroupName: parameter.isNamed ? null : '${groupPrefix}PARAM$i',
        type: parameter.type,
        typeGroupName: '${groupPrefix}TYPE$i',
        isRequiredType: requiredTypes,
      );
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
  void writeFunctionDeclaration(
    String name, {
    void Function()? bodyWriter,
    bool isStatic = false,
    String? nameGroupName,
    void Function()? parameterWriter,
    DartType? returnType,
    String? returnTypeGroupName,
  }) {
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
  void writeGetterDeclaration(
    String name, {
    void Function()? bodyWriter,
    bool isStatic = false,
    String? nameGroupName,
    DartType? returnType,
    String? returnTypeGroupName,
    bool alwaysWriteType = false,
    List<TypeParameterElement>? typeParametersInScope,
  }) {
    alwaysWriteType = alwaysWriteType || _codeStyleOptions.specifyReturnTypes;
    if (isStatic) {
      write(Keyword.STATIC.lexeme);
      write(' ');
    }
    if (alwaysWriteType || (returnType != null && returnType is! DynamicType)) {
      if (writeType(
        returnType,
        groupName: returnTypeGroupName,
        typeParametersInScope: typeParametersInScope,
        shouldWriteDynamic: alwaysWriteType,
      )) {
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
    var imports = [
      for (var uri in uris) ..._dartFileEditBuilder._getImportsForUri(uri),
    ];
    var import = _getBestImportForName(imports, name);
    if (import == null) {
      var library = _dartFileEditBuilder._importLibrary(uris[0]);
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
  void writeIndent([int level = 1]) {
    write(getIndent(level));
  }

  @override
  void writeLocalVariableDeclaration(
    String name, {
    void Function()? initializerWriter,
    bool isConst = false,
    bool isFinal = false,
    String? nameGroupName,
    DartType? type,
    String? typeGroupName,
  }) {
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
  void writeMixinDeclaration(
    String name, {
    Iterable<DartType>? interfaces,
    void Function()? membersWriter,
    String? nameGroupName,
    Iterable<DartType>? superclassConstraints,
  }) {
    // TODO(brianwilkerson): Add support for type parameters, probably as a
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
    bool setSelection = true,
  }) {
    void withCarbonCopyBuffer(void Function() f) {
      _carbonCopyBuffer = displayTextBuffer;
      try {
        f();
      } finally {
        _carbonCopyBuffer = null;
      }
    }

    void selectAllIfSetSelection(void Function() writer) =>
        setSelection ? selectAll(writer) : writer();

    var prefix = getIndent(1);
    var prefix2 = getIndent(2);
    var elementKind = element.kind;

    var isGetter = elementKind == ElementKind.GETTER;
    var isSetter = elementKind == ElementKind.SETTER;
    var isMethod = elementKind == ElementKind.METHOD;
    var isOperator = isMethod && (element as MethodElement).isOperator;
    var memberName = element.name;

    if (memberName == null || memberName.isEmpty) {
      // If the name is empty, we cannot write it.
      return;
    }

    // `@override` annotation.
    writeln('@override');
    write(prefix);

    if (isGetter) {
      writeln('// TODO: implement $memberName');
      write(prefix);
    }

    // Return type.
    var returnType = element.returnType;
    if (!isSetter) {
      var typeWritten = writeType(
        returnType,
        groupName: returnTypeGroupName,
        typeParametersInScope: element.typeParameters,
      );
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

    // Name.
    withCarbonCopyBuffer(() {
      write(memberName);
    });

    // Parameters and body.
    if (isGetter) {
      if (invokeSuper) {
        write(' => ');
        selectAllIfSetSelection(() => write('super.$memberName'));
        writeln(';');
      } else {
        write(' => ');
        selectAllIfSetSelection(() => write('throw UnimplementedError()'));
        write(';');
      }
      displayTextBuffer?.write(' => …');
      return;
    }

    // Method.
    var parameters = element.formalParameters;
    withCarbonCopyBuffer(() {
      writeTypeParameters(
        element.type.typeParameters,
        typeParametersInScope: element.typeParameters,
      );
      writeFormalParameters(
        parameters,
        typeParametersInScope: element.typeParameters,
        groupNamePrefix: memberName,
      );
    });
    writeln(' {');

    // TO-DO comment.
    write(prefix2);
    write('// TODO: implement $memberName');

    if (isSetter) {
      if (invokeSuper) {
        writeln();
        write(prefix2);
        selectAllIfSetSelection(
          () => write('super.$memberName = ${parameters[0].name};'),
        );
      } else {
        if (setSelection) selectHere();
      }
    } else if (returnType is VoidType) {
      if (invokeSuper) {
        writeln();
        write(prefix2);
        selectAllIfSetSelection(() {
          write('super');
          _writeSuperMemberInvocation(element, memberName, parameters);
        });
      } else {
        if (setSelection) selectHere();
      }
    } else {
      writeln();
      write(prefix2);
      if (invokeSuper) {
        selectAllIfSetSelection(() {
          write('return super');
          _writeSuperMemberInvocation(element, memberName, parameters);
        });
      } else {
        selectAllIfSetSelection(() => write('throw UnimplementedError();'));
      }
    }
    writeln();
    // Close method.
    write(prefix);
    write('}');
    displayTextBuffer?.write(' { … }');
  }

  @override
  void writeParameter(
    String name, {
    bool isCovariant = false,
    bool isRequiredNamed = false,
    List<TypeParameterElement>? typeParametersInScope,
    String? nameGroupName,
    DartType? type,
    String? typeGroupName,
    bool isRequiredType = false,
  }) {
    bool writeType() {
      if (typeGroupName != null) {
        late bool hasType;
        addLinkedEdit(typeGroupName, (DartLinkedEditBuilder builder) {
          hasType = _writeTypeIfCan(
            type,
            typeParametersInScope: typeParametersInScope,
            shouldWriteDynamic: isRequiredType,
          );
          builder.addSuperTypesAsSuggestions(type);
        });
        return hasType;
      }
      return _writeTypeIfCan(
        type,
        typeParametersInScope: typeParametersInScope,
        shouldWriteDynamic: isRequiredType,
      );
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
      write('required ');
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
    Expression argument,
    int index,
    Set<String> usedNames, {
    List<TypeParameterElement>? typeParametersInScope,
    bool isOptional = false,
  }) {
    // Append type name.
    var type = argument.staticType;
    if (type == null || type.isBottom || type.isDartCoreNull) {
      type = _typeProvider.objectQuestionType;
    }
    if (argument is NamedExpression &&
        type.nullabilitySuffix == NullabilitySuffix.none &&
        !isOptional) {
      write('required ');
    }
    if (isOptional &&
        type is TypeImpl &&
        type.nullabilitySuffix != NullabilitySuffix.question) {
      type = type.withNullability(NullabilitySuffix.question);
    }
    if (writeType(
      type,
      addSupertypeProposals: true,
      groupName: 'TYPE$index',
      typeParametersInScope: typeParametersInScope,
    )) {
      write(' ');
    }
    // Append parameter name.
    if (argument is NamedExpression) {
      write(argument.name.label.name);
    } else {
      var suggestions = _getParameterNameSuggestions(
        usedNames,
        type,
        argument,
        index,
      );
      var favorite = suggestions[0];
      usedNames.add(favorite);
      addSimpleLinkedEdit(
        'PARAM$index',
        favorite,
        kind: LinkedEditSuggestionKind.PARAMETER,
        suggestions: suggestions,
      );
    }
  }

  @override
  void writeParametersMatchingArguments(
    ArgumentList argumentList, {
    List<TypeParameterElement>? typeParametersInScope,
  }) {
    // TODO(brianwilkerson): Handle the case when there are required parameters
    // after named parameters.
    var usedNames = <String>{};
    var arguments = argumentList.arguments;
    var hasNamedParameters = false;
    for (var i = 0; i < argumentList.arguments.length; i++) {
      var argument = arguments[i];
      if (i > 0) {
        write(', ');
      }
      if (argument is NamedExpression && !hasNamedParameters) {
        hasNamedParameters = true;
        write('{');
      }
      writeParameterMatchingArgument(
        argument,
        i,
        usedNames,
        typeParametersInScope: typeParametersInScope,
      );
    }
    if (hasNamedParameters) {
      write('}');
    }
  }

  @override
  void writeReference(Element element) {
    if (element.enclosingElement is LibraryElement) {
      _writeLibraryReference(element);
    }
    write(element.displayName);
  }

  @override
  void writeSetterDeclaration(
    String name, {
    void Function()? bodyWriter,
    bool isStatic = false,
    String? nameGroupName,
    DartType? parameterType,
    String? parameterTypeGroupName,
    bool alwaysWriteType = false,
    List<TypeParameterElement>? typeParametersInScope,
  }) {
    alwaysWriteType = alwaysWriteType || _codeStyleOptions.specifyTypes;
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
    parameterType ??= DynamicTypeImpl.instance;
    if (alwaysWriteType || parameterType is! DynamicType) {
      if (writeType(
        parameterType,
        groupName: parameterTypeGroupName,
        typeParametersInScope: typeParametersInScope,
        shouldWriteDynamic: alwaysWriteType,
      )) {
        write(' ');
      }
    }
    // TODO(brianwilkerson): The name of the setter is unlikely to be a good
    // name for the parameter. We need to find a better name to produce here.
    write(name);
    write(') ');
    if (bodyWriter == null) {
      write('{}');
    } else {
      bodyWriter();
    }
  }

  @override
  bool writeType(
    DartType? type, {
    bool addSupertypeProposals = false,
    String? groupName,
    List<TypeParameterElement>? typeParametersInScope,
    bool required = false,
    bool shouldWriteDynamic = false,
  }) {
    var wroteType = false;
    if (type != null) {
      if (groupName != null) {
        addLinkedEdit(groupName, (LinkedEditBuilder builder) {
          wroteType = _writeTypeIfCan(
            type,
            typeParametersInScope: typeParametersInScope,
            shouldWriteDynamic: shouldWriteDynamic,
          );
          if (wroteType && addSupertypeProposals) {
            _addSuperTypeProposals(builder, type, {});
          }
        });
      } else {
        wroteType = _writeTypeIfCan(
          type,
          typeParametersInScope: typeParametersInScope,
          shouldWriteDynamic: shouldWriteDynamic,
        );
      }
    }
    if (!wroteType && required) {
      write(Keyword.VAR.lexeme);
      return true;
    }
    return wroteType;
  }

  @override
  void writeTypeParameter(
    TypeParameterElement typeParameter, {
    List<TypeParameterElement>? typeParametersInScope,
  }) {
    write(typeParameter.name ?? '');
    if (typeParameter.bound != null) {
      _writeTypeIfCan(
        typeParameter.bound,
        typeParametersInScope: typeParametersInScope,
        shouldWriteDynamic: true,
        prefix: ' extends ',
      );
    }
  }

  @override
  void writeTypeParameters(
    List<TypeParameterElement> typeParameters, {
    List<TypeParameterElement>? typeParametersInScope,
  }) {
    if (typeParameters.isNotEmpty) {
      write('<');
      writeTypeParameter(
        typeParameters.first,
        typeParametersInScope: typeParametersInScope,
      );
      for (var typeParameter in typeParameters.skip(1)) {
        write(', ');
        writeTypeParameter(
          typeParameter,
          typeParametersInScope: typeParametersInScope,
        );
      }
      write('>');
    }
  }

  @override
  void writeTypes(
    Iterable<DartType>? types, {
    String? prefix,
    bool shouldWriteDynamic = false,
  }) {
    if (types == null || types.isEmpty) {
      return;
    }
    if (prefix != null) {
      write(prefix);
    }
    writeType(types.first, shouldWriteDynamic: shouldWriteDynamic);
    for (var type in types.skip(1)) {
      write(', ');
      writeType(type, shouldWriteDynamic: shouldWriteDynamic);
    }
  }

  /// Adds [items] which are not excluded.
  void _addAll(
    Set<String> excluded,
    Set<String> result,
    Iterable<String> items,
  ) {
    for (var item in items) {
      // Add name based on "item", but not "excluded".
      for (var suffix = 1; ; suffix++) {
        // Prepare name, just "item" or "item2", "item3", etc.
        var name = item;
        if (suffix > 1) {
          name += suffix.toString();
        }
        // Add once found not excluded.
        if (!excluded.contains(name)) {
          result.add(name);
          break;
        }
      }
    }
  }

  /// Adds to [result] either [c] or the first ASCII character after it.
  void _addSingleCharacterName(
    Set<String> excluded,
    Set<String> result,
    int c,
  ) {
    while (c < $z) {
      var name = String.fromCharCode(c);
      // Might be done.
      if (!excluded.contains(name)) {
        result.add(name);
        break;
      }
      // Next character.
      c = c + 1;
    }
  }

  void _addSuperTypeProposals(
    LinkedEditBuilder builder,
    DartType? type,
    Set<DartType> alreadyAdded,
  ) {
    if (type is InterfaceType && alreadyAdded.add(type)) {
      builder.addSuggestion(
        LinkedEditSuggestionKind.TYPE,
        type.getDisplayString(),
      );
      _addSuperTypeProposals(builder, type.superclass, alreadyAdded);
      for (var interfaceType in type.interfaces) {
        _addSuperTypeProposals(builder, interfaceType, alreadyAdded);
      }
    }
  }

  /// Checks if the code to reference [type] in this compilation unit can be
  /// written.
  ///
  /// See also [_writeType] and [_writeTypeIfCan].
  bool _canWriteType(
    DartType? type, {
    required Set<TypeParameterElement>? typeParametersInScope,
  }) {
    // If not a useful type, don't write it.
    if (type == null) {
      return false;
    }

    type = _getVisibleType(type, typeParametersInScope: typeParametersInScope);

    if (type is InvalidType) {
      return false;
    }
    if (type is DynamicType) {
      return true;
    }
    if (type.isBottom) {
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

    var alias = type.alias;
    if (alias != null && alias.element.isAccessibleIn(_libraryElement)) {
      return true;
    }

    if (type is InterfaceType) {
      // This is so that when we hit a type parameter that depends on itself,
      // we stop iterating.
      var typeParameters = {
        for (var argument in type.typeArguments)
          if (argument is TypeParameterType) argument.element,
        ...?typeParametersInScope,
      };
      return type.typeArguments.every(
        (argument) =>
            _canWriteType(argument, typeParametersInScope: typeParameters),
      );
    }

    if (type is FunctionType) {
      // This is so that when we hit a type parameter that depends on itself,
      // we stop iterating.
      var typeParameters = {...type.typeParameters, ...?typeParametersInScope};
      return _canWriteType(
            type.returnType,
            typeParametersInScope: typeParameters,
          ) &&
          type.typeParameters.every(
            (type) =>
                typeParameters.contains(type) ||
                (type.bound != null &&
                    _canWriteType(
                      type.bound,
                      typeParametersInScope: typeParameters,
                    )) ||
                // This ensures we consider valid when the type parameter is
                // declared in another scope, to write `Object?`
                type.bound == null,
          ) &&
          type.formalParameters.every(
            (parameter) => _canWriteType(
              parameter.type,
              typeParametersInScope: typeParameters,
            ),
          );
    }

    if (type is RecordType) {
      return _featureSet.isEnabled(Feature.records) &&
          type.fields.every(
            (field) => _canWriteType(
              field.type,
              typeParametersInScope: typeParametersInScope,
            ),
          );
    }

    throw UnimplementedError('(${type.runtimeType}) $type');
  }

  /// Generates a name that does not occur in [existingNames] that begins with
  /// the given [prefix].
  String _generateUniqueName(Set<String> existingNames, {String prefix = 'p'}) {
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
    // Value in named expression.
    if (expression.parent is NamedExpression) {
      var namedExpression = expression.parent as NamedExpression;
      if (namedExpression.expression == expression) {
        return namedExpression.name.label.name;
      }
    }
    // Positional argument.
    var parameter = expression.correspondingParameter;
    if (parameter != null) {
      return parameter.displayName;
    }

    // Unknown.
    return null;
  }

  String? _getBaseNameFromUnwrappedExpression(Expression expression) {
    String? name;
    // Analyze expressions.
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
      // `new ClassName()`.
      if (importPrefix == null) {
        return namedType.name.lexeme;
      }
      // `new prefix.ClassName()`.
      if (importPrefix.element is PrefixElement) {
        return namedType.name.lexeme;
      }
      // `new ClassName.constructorName()`.
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
    // Strip known prefixes.
    if (name != null) {
      for (var prefix in _knownMethodNamePrefixes) {
        if (name.startsWith(prefix)) {
          if (name == prefix) {
            return null;
          } else if (isUpperCase(name.codeUnitAt(prefix.length))) {
            return name.substring(prefix.length);
          }
        }
      }
    }
    // Done.
    return name;
  }

  /// Given a list of [imports] that do, or can, make the [name] visible in
  /// scope, returns the one that will lead to the cleanest code.
  LibraryImport? _getBestImportForName(
    List<LibraryImport> imports,
    String name,
  ) {
    if (imports.isEmpty) {
      return null;
    } else if (imports.length == 1) {
      return imports[0];
    }
    imports.sort((first, second) {
      // Prefer imports that make the name visible.
      var firstDefinesName = first.namespace.definedNames2.containsKey(name);
      var secondDefinesName = second.namespace.definedNames2.containsKey(name);
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

  /// Returns a list containing the suggested names for a parameter with the
  /// given [type] whose value in one location is computed by the given
  /// [expression].
  ///
  /// The [index] is the index of the argument, used to create a name if no
  /// better name could be created. The first name in the list will be the
  /// best name.
  List<String> _getParameterNameSuggestions(
    Set<String> usedNames,
    DartType type,
    Expression expression,
    int index,
  ) {
    var suggestions = _getVariableNameSuggestionsForExpression(
      type,
      expression,
      usedNames,
    );
    if (suggestions.isNotEmpty) {
      return suggestions;
    }
    // TODO(brianwilkerson): Verify that the name below is not in the set of
    // used names.
    return <String>['param$index'];
  }

  /// Returns possible names for a variable with the given expected type and
  /// expression assigned.
  List<String> _getVariableNameSuggestionsForExpression(
    DartType? expectedType,
    Expression? assignedExpression,
    Set<String> excluded,
  ) {
    var res = <String>{};
    // Use expression.
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
    // Use type.
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
    // Done.
    return List.from(res);
  }

  /// If the given [type] is visible in either the [_enclosingExecutable] or
  /// [_enclosingClass], or if there is a local equivalent to the type (such as
  /// in the case of a type parameter from a superclass), then returns the type
  /// that is locally visible. Otherwise, return `null`.
  DartType _getVisibleType(
    DartType type, {
    required Iterable<TypeParameterElement>? typeParametersInScope,
  }) {
    if (type is InterfaceType) {
      var element = type.element;
      if (element.isPrivate &&
          !_dartFileEditBuilder._isDefinedLocally(element)) {
        if (element.supertype case InterfaceTypeImpl superType) {
          return _getVisibleType(
            superType.withNullability(type.nullabilitySuffix),
            typeParametersInScope: typeParametersInScope,
          );
        }
        return _typeProvider.objectElement.instantiate(
          typeArguments: const [],
          nullabilitySuffix: type.nullabilitySuffix,
        );
      }
      return type;
    }
    if (type is TypeParameterType) {
      _initializeEnclosingElements();
      var element = type.element;
      if (typeParametersInScope?.contains(element) ?? false) {
        return type;
      }
      var enclosing = element.enclosingElement;
      while (enclosing is GenericFunctionTypeElement ||
          enclosing is FormalParameterElement) {
        enclosing = enclosing!.enclosingElement;
      }
      if (enclosing != null &&
          (enclosing == _enclosingExecutable || enclosing == _enclosingClass)) {
        return type;
      }
      return _getVisibleType(
        type.element.bound?.withNullability(type.nullabilitySuffix) ??
            _typeProvider.objectQuestionType,
        typeParametersInScope: typeParametersInScope,
      );
    }
    return type;
  }

  /// Initializes the [_enclosingClass] and [_enclosingExecutable].
  void _initializeEnclosingElements() {
    if (!_hasEnclosingElementsInitialized) {
      var finder = _EnclosingElementFinder();
      finder.find(_dartFileEditBuilder.resolvedUnit.unit, offset);
      _enclosingClass = finder.enclosingClass;
      _enclosingExecutable = finder.enclosingExecutable;
      _hasEnclosingElementsInitialized = true;
    }
  }

  /// Writes the import prefix to reference the [element], if needed.
  ///
  /// The prefix is not needed if the [element] is defined in the target
  /// library, or there is already an import without prefix that exports the
  /// [element]. If there are no existing import that exports the [element], a
  /// library that exports the [element] is scheduled for import, possibly with
  /// a prefix.
  void _writeLibraryReference(Element element) {
    // If the element is defined in the library, then no prefix needed.
    if (_dartFileEditBuilder._isDefinedLocally(element)) {
      return;
    }

    var import = _dartFileEditBuilder._getImportElement(element);
    if (import == null) {
      var library = element.library?.uri;
      if (library != null) {
        var shadowed =
            _libraryElement.publicNamespace.get2(element.displayName) != null;
        String? prefix;
        if (shadowed) {
          prefix = _dartFileEditBuilder._defaultImportPrefixFor(library);
        }
        import = _dartFileEditBuilder._importLibrary(library, prefix: prefix);
      }
    }
    if (import == null) {
      return;
    }
    import._ensureShown(element.name!);
    var prefix = import.prefix;
    if (prefix.isNotEmpty) {
      write('$prefix.');
    }
  }

  void _writeSuperMemberInvocation(
    ExecutableElement element,
    String memberName,
    List<FormalParameterElement> parameters,
  ) {
    var isOperator = element is MethodElement && element.isOperator;
    write(isOperator ? ' ' : '.');
    write(memberName);
    write(isOperator ? ' ' : '(');
    for (var i = 0; i < parameters.length; i++) {
      if (i > 0) {
        write(', ');
      }
      if (parameters[i].isNamed) {
        write(parameters[i].name ?? '');
        write(': ');
      }
      write(parameters[i].name ?? '');
    }
    write(isOperator ? ';' : ');');
  }

  /// Writes the code to reference [type] in this compilation unit.
  ///
  /// This shouldn't be called unless [_canWriteType] returns `true` for the
  /// [type]. Also see [_writeTypeIfCan] that already handles this.
  ///
  /// If [typeParametersInScope] is provided, then the type parameters are
  /// known to be visible in the scope in which the type will be written.
  ///
  /// If [shouldWriteDynamic] it `true`, then the type will be written even if
  /// it would normally be omitted, such as with `dynamic`.
  ///
  /// Causes any libraries whose elements are used by the generated code, to be
  /// imported.
  void _writeType(
    DartType? type, {
    required Set<TypeParameterElement>? typeParametersInScope,
    required bool shouldWriteDynamic,
    Set<DartType>? seenTypes,
  }) {
    type ??= _typeProvider.objectQuestionType;

    seenTypes ??= {};
    seenTypes.add(type);

    type = _getVisibleType(type, typeParametersInScope: typeParametersInScope);

    if (type is InvalidType) {
      type = _typeProvider.objectQuestionType;
    }

    if (type is DynamicType) {
      if (shouldWriteDynamic) {
        write('dynamic');
      }
      return;
    }

    if (type.isBottom || type is NeverType) {
      write('Never');
      _writeTypeNullability(type);
      return;
    }

    if (type is VoidType) {
      write('void');
      return;
    }

    if (type is TypeParameterType) {
      write(type.element.name!);
      _writeTypeNullability(type);
      return;
    }

    var (element, typeArguments) = switch (type) {
      DartType(:var alias?)
          when alias.element.isAccessibleIn(_libraryElement) =>
        (alias.element, alias.typeArguments),
      InterfaceType(:var element, :var typeArguments) => // Formatting hack.
      (element, typeArguments),
      _ => (null, null),
    };
    if (element != null && typeArguments != null) {
      _writeTypeElementArguments(
        element: element,
        typeArguments: typeArguments,
        typeParametersInScope: typeParametersInScope,
        seenTypes: seenTypes,
      );
      _writeTypeNullability(type);
      return;
    }

    if (type is FunctionType) {
      var typeParameters = {...type.typeParameters, ...?typeParametersInScope};
      _writeType(
        type.returnType,
        typeParametersInScope: typeParameters,
        shouldWriteDynamic: shouldWriteDynamic,
        seenTypes: seenTypes,
      );
      if (shouldWriteDynamic || type.returnType is! DynamicType) {
        write(' ');
      }
      write('Function');
      writeTypeParameters(
        type.typeParameters,
        typeParametersInScope: typeParameters.toList(),
      );
      writeFormalParameters(
        type.formalParameters,
        typeParametersInScope: typeParameters.toList(),
        includeDefaultValues: false,
        fillParameterNames: false,
      );
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        write('?');
      }
      return;
    }

    if (type is RecordType) {
      write('(');
      var isFirst = true;
      for (var field in type.positionalFields) {
        if (isFirst) {
          isFirst = false;
        } else {
          write(', ');
        }
        _writeType(
          field.type,
          typeParametersInScope: typeParametersInScope,
          shouldWriteDynamic: shouldWriteDynamic,
          seenTypes: seenTypes,
        );
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
          _writeType(
            field.type,
            typeParametersInScope: typeParametersInScope,
            shouldWriteDynamic: shouldWriteDynamic,
            seenTypes: seenTypes,
          );
          write(' ');
          write(field.name);
        }
        write('}');
      }
      write(')');
      _writeTypeNullability(type);
      return;
    }

    throw UnimplementedError('(${type.runtimeType}) $type');
  }

  void _writeTypeElementArguments({
    required Element element,
    required List<DartType> typeArguments,
    required Set<TypeParameterElement>? typeParametersInScope,
    required Set<DartType> seenTypes,
  }) {
    // Ensure that the element is imported.
    _writeLibraryReference(element);

    // Write the simple name.
    var name = element.displayName;
    write(name);

    // Write type arguments.
    if (typeArguments.isNotEmpty) {
      write('<');
      for (var i = 0; i < typeArguments.length; i++) {
        DartType? argument = typeArguments[i];
        argument = _getVisibleType(
          argument,
          typeParametersInScope: typeParametersInScope,
        );
        if (i != 0) {
          write(', ');
        }
        if (seenTypes.containsElementAndArguments(argument)) {
          write('dynamic');
          continue;
        }
        _writeType(
          argument,
          typeParametersInScope: typeParametersInScope,
          shouldWriteDynamic: true,
          // We need to create a new set here so we only handle recursive types
          // and not to block the same type being written in different
          // arguments. Like `Map<int, int>` should write both `int`s correctly.
          // But a recursive type like `A<T extends A<T>>` should not recurse
          // infinitely and write `A<dynamic>` instead.
          seenTypes: seenTypes.toSet(),
        );
      }
      write('>');
    }
  }

  /// Writes [type] if it should be, and returns whether it was written.
  ///
  /// If the [type] is `null` it will not be written.
  ///
  /// Internally handles [type] to verify and write down only a visible type
  /// (see [_getVisibleType]).
  bool _writeTypeIfCan(
    DartType? type, {
    required List<TypeParameterElement>? typeParametersInScope,
    required bool shouldWriteDynamic,
    String? prefix,
  }) {
    if (type == null) return false;
    var typeParametersSet = typeParametersInScope?.toSet();
    var visibleType = _getVisibleType(
      type,
      typeParametersInScope: typeParametersInScope,
    );
    if (!shouldWriteDynamic && visibleType is DynamicType) return false;
    if (!_canWriteType(visibleType, typeParametersInScope: typeParametersSet)) {
      return false;
    }
    if (prefix != null) {
      write(prefix);
    }
    _writeType(
      visibleType,
      typeParametersInScope: typeParametersSet,
      shouldWriteDynamic: shouldWriteDynamic,
    );
    return true;
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

  /// The resolved unit for the file.
  final ResolvedLibraryResult resolvedLibrary;

  /// The change builder for the library or `null` if the receiver is the
  /// builder for the library.
  final DartFileEditBuilderImpl? libraryChangeBuilder;

  @override
  String? fileHeader;

  /// Whether to create edits that add imports for any written types that are
  /// not already imported.
  final bool _createEditsForImports;

  /// A mapping from libraries that need to be imported in order to make visible
  /// the names used in generated code, to information about these imports.
  final Map<Uri, _LibraryImport> _librariesToImport = {};

  /// A mapping of elements to pending imports that will be added to make them
  /// visible in the generated code.
  final Map<Element, _LibraryImport> _elementLibrariesToImport = {};

  /// The data used to revert any changes made since the last time [commit] was
  /// called.
  final _DartFileEditBuilderRevertData _revertData =
      _DartFileEditBuilderRevertData();

  /// Initializes a newly created builder to build a source file edit within the
  /// change being built by the given [changeBuilder].
  ///
  /// The file being edited has the given [resolvedUnit] and [timeStamp].
  DartFileEditBuilderImpl(
    ChangeBuilderImpl changeBuilder,
    this.resolvedLibrary,
    this.resolvedUnit,
    int timeStamp,
    this.libraryChangeBuilder, {
    required String eol,
    bool createEditsForImports = true,
  }) : _createEditsForImports = createEditsForImports,
       super(changeBuilder, resolvedUnit.path, timeStamp, eol: eol);

  @override
  bool get hasEdits =>
      super.hasEdits || _librariesToImport.isNotEmpty || fileHeader != null;

  @override
  List<Uri> get requiredImports => _librariesToImport.keys.toList();

  CodeStyleOptions get _codeStyleOptions => resolvedUnit.session.analysisContext
      .getAnalysisOptionsForFile(resolvedUnit.file)
      .codeStyleOptions;

  LibraryElement get _libraryElement => resolvedLibrary.element;

  @override
  void addInsertion(
    int offset,
    void Function(DartEditBuilder builder) buildEdit, {
    bool insertBeforeExisting = false,
  }) => super.addInsertion(
    offset,
    (builder) => buildEdit(builder as DartEditBuilder),
    insertBeforeExisting: insertBeforeExisting,
  );

  @override
  void addReplacement(
    SourceRange range,
    void Function(DartEditBuilder builder) buildEdit,
  ) => super.addReplacement(
    range,
    (builder) => buildEdit(builder as DartEditBuilder),
  );

  @override
  bool canWriteType(
    DartType? type, {
    required int offset,
    List<TypeParameterElement>? typeParametersInScope,
  }) {
    var builder = createEditBuilder(offset, 0);
    return builder.canWriteType(
      type,
      typeParametersInScope: typeParametersInScope,
    );
  }

  @override
  void commit() {
    super.commit();

    _revertData._addedLibrariesToImport.clear();
  }

  @override
  void convertFunctionFromAsyncToSync({
    required FunctionBody body,
    required TypeSystem typeSystem,
    required TypeProvider typeProvider,
  }) {
    if (body.keyword?.lexeme != Keyword.ASYNC.lexeme || body.star != null) {
      throw ArgumentError(
        'The function must have an asynchronous, non-generator body.',
      );
    }
    var keyword = body.keyword!;
    if (body is! EmptyFunctionBody) {
      addDeletion(
        range.startOffsetEndOffset(
          keyword.offset,
          keyword.end + (_isFusedWithPreviousToken(keyword.next!) ? 0 : 1),
        ),
      );
    }
    _replaceReturnTypeWithFutureArgument(
      node: body,
      typeSystem: typeSystem,
      typeProvider: typeProvider,
    );
  }

  @override
  void convertFunctionFromSyncToAsync({
    required FunctionBody body,
    required TypeSystem typeSystem,
    required TypeProvider typeProvider,
  }) {
    if (body.keyword != null) {
      throw ArgumentError(
        'The function must have a synchronous, non-generator body.',
      );
    }
    if (body is! EmptyFunctionBody) {
      addInsertion(body.offset, (EditBuilder builder) {
        if (_isFusedWithPreviousToken(body.beginToken)) {
          builder.write(' ');
        }
        builder.write('async ');
      });
    }
    _replaceReturnTypeWithFuture(
      node: body,
      typeSystem: typeSystem,
      typeProvider: typeProvider,
    );
  }

  @override
  DartEditBuilderImpl createEditBuilder(int offset, int length) {
    return DartEditBuilderImpl(
      this,
      offset,
      length,
      description: currentChangeDescription,
    );
  }

  @override
  void finalize() {
    if (_createEditsForImports && _librariesToImport.isNotEmpty) {
      _addLibraryImports(_librariesToImport.values);
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

    var languageVersion = resolvedUnit.libraryElement.languageVersion.effective;
    var formattedResult = DartFormatter(languageVersion: languageVersion)
        .formatSource(
          SourceCode(
            newContent,
            isCompilationUnit: true,
            selectionStart: newRangeOffset,
            selectionLength: newRangeLength,
          ),
        );

    replaceEdits(
      range,
      SourceEdit(range.offset, range.length, formattedResult.selectedText),
    );
  }

  /// Arranges to have an import added that makes [element] available.
  ///
  /// If [element] is already available in the current library, does nothing.
  ///
  /// If the library [element] is declared in is inside a package's 'lib/src'
  /// directory, will try to locate a public URI to import instead.
  Future<void> importElementLibrary(
    Element element, {
    Map<Element, LibraryElement?>? resultCache,
  }) async {
    if (_isDefinedLocally(element)) {
      return;
    }

    var existingImport = _getImportElement(element);
    var name = element.name;
    if (existingImport != null && name != null) {
      existingImport._ensureShown(name);
      return;
    }

    var elementLibrariesToImport =
        (libraryChangeBuilder ?? this)._elementLibrariesToImport;
    var libraryToImport =
        resultCache?[element] ??
        await TopLevelDeclarations(
          resolvedUnit,
        ).publiclyExporting(element, resultCache: resultCache) ??
        // Fall back to the element's library if we didn't find a better one.
        element.library;

    var uriToImport = libraryToImport?.uri;
    if (uriToImport != null) {
      var newImport = elementLibrariesToImport[element] = _importLibrary(
        uriToImport,
        isExplicitImport: false,
        showName: element.name,
      );

      // It's possible this new import can satisfy other pending element's
      // imports in which case we could remove them to avoid adding unnecessary
      // imports.
      _removeUnnecessaryPendingElementImports(newImport, libraryToImport);
    }
  }

  @override
  String importLibrary(
    Uri uri, {
    String? prefix,
    String? showName,
    bool useShow = false,
  }) {
    return _importLibrary(
      uri,
      prefix: prefix,
      showName: showName,
      useShow: useShow,
    ).uriText;
  }

  @override
  ImportLibraryElementResult importLibraryElement(
    Uri uri, {
    String? prefix,
    String? showName,
    bool useShow = false,
  }) {
    if (resolvedUnit.libraryElement.uri == uri) {
      return ImportLibraryElementResultImpl(null);
    }

    for (var import
        in resolvedUnit.libraryElement.firstFragment.libraryImports) {
      var importedLibrary = import.importedLibrary;
      if (importedLibrary != null && importedLibrary.uri == uri) {
        var importPrefix = import.prefix?.element.name;
        if (import.hasCombinator) {
          if (importPrefix == null && showName != null) {
            _handleCombinators(import, showName);
            return ImportLibraryElementResultImpl(importPrefix);
          }
        } else {
          return ImportLibraryElementResultImpl(importPrefix);
        }
      }
    }

    importLibrary(uri, prefix: prefix, showName: showName, useShow: useShow);
    return ImportLibraryElementResultImpl(null);
  }

  String importLibraryWithAbsoluteUri(
    Uri uri, {
    String? prefix,
    String? showName,
    bool useShow = false,
  }) {
    return _importLibrary(
      uri,
      prefix: prefix,
      showName: showName,
      useShow: useShow,
      forceAbsolute: true,
    ).uriText;
  }

  String importLibraryWithRelativeUri(
    Uri uri, {
    String? prefix,
    String? showName,
    bool useShow = false,
  }) {
    return _importLibrary(
      uri,
      prefix: prefix,
      showName: showName,
      useShow: useShow,
      forceAbsolute: true,
      forceRelative: true,
    ).uriText;
  }

  @override
  bool importsLibrary(Uri uri) {
    // Self-reference.
    if (resolvedUnit.libraryElement.uri == uri) return false;

    // Existing import.
    for (var import
        in resolvedUnit.libraryElement.firstFragment.libraryImports) {
      var importedLibrary = import.importedLibrary;
      if (importedLibrary != null && importedLibrary.uri == uri) {
        return true;
      }
    }

    // Queued change.
    var importChange = (libraryChangeBuilder ?? this)._librariesToImport[uri];
    return importChange != null;
  }

  @override
  void insertCaseClauseAtEnd(
    void Function(DartEditBuilder builder) buildEdit, {
    required Token switchKeyword,
    required Token rightParenthesis,
    required Token leftBracket,
    required Token rightBracket,
  }) {
    var lineInfo = resolvedUnit.lineInfo;
    var isBlockSingleLine = lineInfo.onSameLine(
      leftBracket.offset,
      rightBracket.offset,
    );
    int offset;
    if (isBlockSingleLine) {
      offset = leftBracket.isSynthetic ? rightParenthesis.end : leftBracket.end;
    } else {
      offset = resolvedUnit.lineInfo.getOffsetOfLine(
        lineInfo.getLocation(rightBracket.offset).lineNumber - 1,
      );
    }

    addInsertion(offset, (builder) {
      if (leftBracket.isSynthetic) {
        builder.write(' {');
      }
      if (isBlockSingleLine) {
        builder.writeln();
      }
      buildEdit(builder);
      if (isBlockSingleLine) {
        builder.write(resolvedUnit.linePrefix(switchKeyword.offset));
      }
      if (rightBracket.isSynthetic) {
        builder.write('}');
      }
    });
  }

  @override
  void insertConstructor(
    CompilationUnitMember container,
    void Function(DartEditBuilder builder) buildEdit,
  ) {
    if (container is! ClassDeclaration &&
        container is! EnumDeclaration &&
        container is! ExtensionTypeDeclaration) {
      // Can only add constructors to class, enum, and extension type
      // declarations.
      throw ArgumentError.value(
        container,
        'container',
        'Argument must be a CompilationUnitMember which can have constructor '
            'declarations.',
      );
    }
    final sortConstructorsFirst = resolvedUnit.session.analysisContext
        .getAnalysisOptionsForFile(resolvedUnit.file)
        .codeStyleOptions
        .sortConstructorsFirst;
    var lastMemberFilter = sortConstructorsFirst
        ? (member) => member is ConstructorDeclaration
        : (member) =>
              member is ConstructorDeclaration || member is FieldDeclaration;
    insertIntoUnitMember(
      container,
      buildEdit,
      lastMemberFilter: lastMemberFilter,
    );
  }

  @override
  void insertField(
    CompilationUnitMember compilationUnitMember,
    void Function(DartEditBuilder builder) buildEdit,
  ) => insertIntoUnitMember(
    compilationUnitMember,
    buildEdit,
    lastMemberFilter: (member) {
      if (resolvedUnit.session.analysisContext
          .getAnalysisOptionsForFile(resolvedUnit.file)
          .codeStyleOptions
          .sortConstructorsFirst) {
        return member is ConstructorDeclaration || member is FieldDeclaration;
      } else {
        return member is FieldDeclaration;
      }
    },
  );

  @override
  void insertGetter(
    CompilationUnitMember compilationUnitMember,
    void Function(DartEditBuilder builder) buildEdit,
  ) => insertIntoUnitMember(
    compilationUnitMember,
    buildEdit,
    lastMemberFilter: (member) =>
        member is FieldDeclaration ||
        member is ConstructorDeclaration ||
        member is MethodDeclaration && member.isGetter,
  );

  @override
  void insertIntoUnitMember(
    CompilationUnitMember compilationUnitMember,
    void Function(DartEditBuilder builder) buildEdit, {
    bool Function(ClassMember existingMember)? lastMemberFilter,
  }) {
    var preparer = _InsertionPreparer(
      compilationUnitMember,
      resolvedUnit.lineInfo,
    );
    var offset = preparer.insertionLocation(lastMemberFilter: lastMemberFilter);
    if (offset == null) {
      return;
    }

    addInsertion(offset, insertBeforeExisting: false, (builder) {
      preparer.writePrefix(builder);
      buildEdit(builder);
      preparer.writeSuffix(builder);
    });
  }

  @override
  void insertMethod(
    CompilationUnitMember compilationUnitMember,
    void Function(DartEditBuilder builder) buildEdit,
  ) => insertIntoUnitMember(
    compilationUnitMember,
    buildEdit,
    lastMemberFilter: (member) =>
        member is FieldDeclaration ||
        member is ConstructorDeclaration ||
        member is MethodDeclaration,
  );

  @override
  void replaceTypeWithFuture({
    required TypeAnnotation? typeAnnotation,
    required TypeSystem typeSystem,
    required TypeProvider typeProvider,
  }) {
    if (typeAnnotation == null) {
      return;
    }

    //
    // Check whether the type needs to be replaced.
    //
    var type = typeAnnotation.type;
    if (type == null || type is DynamicType || type.isDartAsyncFuture) {
      return;
    }

    addReplacement(range.node(typeAnnotation), (builder) {
      var valueType = typeSystem.flatten(type);
      var futureType = typeProvider.futureType(valueType);
      if (!builder.writeType(futureType)) {
        builder.write('void');
      }
    });
  }

  @override
  void replaceTypeWithFutureArgument({
    required TypeAnnotation? typeAnnotation,
    required TypeSystem typeSystem,
    required TypeProvider typeProvider,
  }) {
    if (typeAnnotation == null) {
      return;
    }

    //
    // Check whether the type needs to be replaced.
    //
    var type = typeAnnotation.type;
    if (type == null || !type.isDartAsyncFuture && !type.isDartAsyncFutureOr) {
      return;
    }

    addReplacement(range.node(typeAnnotation), (builder) {
      var valueType = typeSystem.flatten(type);
      if (!builder.writeType(valueType)) {
        builder.write('void');
      }
    });
  }

  @override
  void revert() {
    super.revert();

    for (var uri in _revertData._addedLibrariesToImport) {
      _librariesToImport.remove(uri);
    }

    _revertData._addedLibrariesToImport.clear();
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

    // Sort the new imports so dart, package, and relative imports appear in the
    // correct order.
    var importList = imports.toList()..sort();
    var sortCombinators = resolvedUnit.session.analysisContext
        .getAnalysisOptionsForFile(resolvedUnit.file)
        .isLintEnabled('combinators_ordering');
    var quote = _codeStyleOptions.preferredQuoteForUris(importDirectives);
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
        if (import.shownNames.isNotEmpty) {
          builder.write(' show ');
          if (sortCombinators) {
            builder.write(import.allShownNames.sorted().join(', '));
          } else {
            builder.write(import.allShownNames.join(', '));
          }
        }
        if (import.hiddenNames.isNotEmpty) {
          builder.write(' hide ');
          if (sortCombinators) {
            builder.write(import.allHiddenNames.sorted().join(', '));
          } else {
            builder.write(import.allHiddenNames.join(', '));
          }
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

        void updateShowCombinators(ImportDirective replace) {
          // We don't need to replace anything if there isn't a show combinator
          // already.
          if (import.shownNames.isEmpty) {
            return;
          }

          var showCombinators = replace.combinators
              .whereType<ShowCombinator>()
              .toList();

          // Insert any new show combinators at the end of the last show
          // combinator list, in sorted order, but only if there already is a
          // show combinator. If there isn't one, then don't add one.
          if (showCombinators.isEmpty) {
            return;
          }
          var existingShownNames = {
            for (var combinator in showCombinators)
              for (var nameElement in combinator.shownNames) nameElement.name,
          };

          var addedNames = import.allShownNames.difference(existingShownNames);
          if (addedNames.isNotEmpty) {
            if (sortCombinators || existingShownNames.isSorted()) {
              // If the existing names are already sorted, or the analyzer flag
              // for sorting them is set, then sort all the names.
              var combinedNames = {
                ...showCombinators.last.shownNames.map<String>(
                  (element) => element.name,
                ),
                ...addedNames,
              }.sorted();
              addSimpleReplacement(
                range.node(showCombinators.last),
                'show ${combinedNames.join(', ')}',
              );
            } else {
              addInsertion(showCombinators.last.end, (builder) {
                builder.write(', ${addedNames.sorted().join(', ')}');
              });
            }
          }
        }

        void updateHideCombinators(ImportDirective replace) {
          // Go through all of the hide combinators and remove any names that
          // are no longer hidden. We don't ever add any names to pre-existing
          // import.hiddenNames, so we don't need to worry about updating the
          // sort order.
          for (var hide in replace.combinators.whereType<HideCombinator>()) {
            var offset = hide.offset;
            var length = hide.end - offset;
            var hiddenList = hide.hiddenNames.map((e) => e.name);
            var hiddenNames = hiddenList.toSet();
            // Find any names that need to be visible, either because they are
            // in the shown names, or because they're no longer in the hidden
            // names.
            var newNames = hiddenNames
                .intersection(import.allHiddenNames)
                .difference(import.allShownNames);
            if (newNames.isEmpty) {
              var previousEnd = hide.beginToken.previous?.end ?? 0;
              addDeletion(SourceRange(previousEnd, hide.end - previousEnd));
            } else if (hiddenNames.intersection(newNames).length !=
                hiddenNames.length) {
              // Unless the `sort_combinators` lint is enabled, make sure to
              // preserve original order, while removing any names that don't
              // appear in `newNames`.
              var orderedList = sortCombinators
                  ? newNames.sorted()
                  : hiddenList.where((element) => newNames.contains(element));
              addSimpleReplacement(
                SourceRange(offset, length),
                'hide ${orderedList.join(', ')}',
              );
            }
          }
        }

        void insert({
          ImportDirective? prev,
          ImportDirective? replace,
          ImportDirective? next,
          bool trailingNewLine = false,
        }) {
          assert(
            prev == null || replace == null,
            "Can't supply both prev and replace",
          );
          assert(prev != null || replace != null || next != null);

          var lineInfo = resolvedUnit.lineInfo;
          if (prev != null) {
            var offset = prev.end;
            Token? comment = prev.endToken.next?.precedingComments;
            while (comment != null) {
              if (lineInfo.onSameLine(comment.offset, offset)) {
                offset = comment.end;
              }
              comment = comment.next;
            }
            addInsertion(offset, (EditBuilder builder) {
              builder.writeln();
              writeImport(builder, import);
            });
          } else if (replace != null) {
            updateHideCombinators(replace);
            updateShowCombinators(replace);
          } else {
            // Annotations attached to the first directive should remain above
            // the newly inserted import, as they are treated as being for the
            // file.
            var isFirst =
                next == (next!.parent as CompilationUnit).directives.first;
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
          var isReplacement =
              import.uriText == existingUri &&
              import.prefix == (existingImport.prefix?.name ?? '');
          var isNewBeforeExisting = import.uriText.compareTo(existingUri) < 0;

          if (isReplacement) {
            insert(replace: existingImport);
            break;
          } else if (isDart) {
            if (!isExistingDart || isNewBeforeExisting) {
              insert(
                prev: lastExistingDart,
                next: existingImport,
                trailingNewLine: !isExistingDart,
              );
              break;
            }
          } else if (isPackage) {
            if (isExistingRelative || isNewBeforeExisting) {
              insert(
                prev: lastExistingPackage,
                next: existingImport,
                trailingNewLine: isExistingRelative,
              );
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
    addInsertion(offset, (EditBuilder builder) {
      for (var i = 0; i < importList.length; i++) {
        var import = importList[i];
        writeImport(builder, import);
        builder.writeln();
        if (i == importList.length - 1 && insertEmptyLineAfter) {
          builder.writeln();
        }
      }
    }, insertBeforeExisting: true);
  }

  String _defaultImportPrefixFor(Uri uri) {
    // TODO(FMorschel): Think of a way to identify if the current editing range
    // already contains a variable with the same name as the generated prefix.
    // This only accounts for top-level names.
    var existingNames = {..._libraryElement.exportNamespace.definedNames2.keys};
    for (var unit in resolvedLibrary.units) {
      existingNames.addAll(
        unit.unit.directives
            .whereType<ImportDirective>()
            .map((d) => d.prefix?.name)
            .nonNulls,
      );
    }
    var suffix = 0;
    var prefix = 'prefix$suffix';
    while (existingNames.contains(prefix)) {
      suffix++;
      prefix = 'prefix$suffix';
    }
    return prefix;
  }

  /// Returns information about the library used to import the given [element]
  /// into the target library, or `null` if the element was not imported, such
  /// as when the element is declared in the same library.
  ///
  /// The result may be an existing import, or one that is pending.
  _LibraryImport? _getImportElement(Element element) {
    for (var import
        in resolvedUnit.libraryElement.firstFragment.libraryImports) {
      var lookupName = element.lookupName;
      var definedNames = import.namespace.definedNames2;
      var importedElement = definedNames[lookupName];
      if (importedElement != null &&
          importedElement.library?.uri == element.library?.uri) {
        var importedLibrary = import.importedLibrary;
        if (importedLibrary != null) {
          return _LibraryImport(
            uriText: importedLibrary.uri.toString(),
            isExplicitlyImported: true,
            shownNames: [
              for (var combinator in import.combinators)
                if (combinator is ShowElementCombinator)
                  combinator.shownNames.toList(),
            ],
            hiddenNames: [
              for (var combinator in import.combinators)
                if (combinator is HideElementCombinator)
                  combinator.hiddenNames.toList(),
            ],
            prefix: import.prefix?.name ?? '',
          );
        }
      }
    }

    return (libraryChangeBuilder ?? this)._elementLibrariesToImport[element];
  }

  List<LibraryImport> _getImportsForUri(Uri uri) {
    return [
      for (var import
          in resolvedUnit.libraryElement.firstFragment.libraryImports)
        if (import.importedLibrary?.uri == uri) import,
    ];
  }

  /// Computes the best URI to import [uri] into the target library.
  ///
  /// [uri] may be converted from an absolute URI to a relative URI depending on
  /// the enabled lint rules unless either [forceAbsolute] or [forceRelative]
  /// are `true`.
  String _getLibraryUriText(
    Uri uri, {
    bool forceAbsolute = false,
    bool forceRelative = false,
  }) {
    var pathContext = resolvedUnit.session.resourceProvider.pathContext;

    /// Returns the relative path to import [whatPath] into [resolvedUnit].
    String getRelativePath(String whatPath) {
      var libraryPath =
          resolvedUnit.libraryElement.firstFragment.source.fullName;
      var libraryFolder = pathContext.dirname(libraryPath);
      var relativeFile = pathContext.relative(whatPath, from: libraryFolder);
      return pathContext.split(relativeFile).join('/');
    }

    if (uri.isScheme('file')) {
      var whatPath = pathContext.fromUri(uri);
      return getRelativePath(whatPath);
    }
    var preferRelative = _codeStyleOptions.useRelativeUris;
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

  /// If the [import] already has combinators, update them to import [showName].
  ///
  /// If the combinator is a `show`, then [showName] will be added to the list
  /// of shown names.
  ///
  /// If the combinator is a `hide`, then [showName] will be removed from the
  /// list of hidden names.
  void _handleCombinators(LibraryImport import, String showName) {
    for (var show in import.showCombinators) {
      var names = show.shownNames.toList();
      if (!names.contains(showName)) {
        names.add(showName);
        names.sort();
        addSimpleReplacement(
          range.startOffsetEndOffset(show.offset, show.end),
          'show ${names.join(', ')}',
        );
      }
    }
    for (var hide in import.hideCombinators) {
      var names = hide.hiddenNames.toList();
      if (names.contains(showName)) {
        names.remove(showName);
        if (names.isEmpty) {
          addSimpleReplacement(
            range.startOffsetEndOffset(hide.offset - 1, hide.end),
            '',
          );
        } else {
          addSimpleReplacement(
            range.startOffsetEndOffset(hide.offset, hide.end),
            'hide ${names.join(', ')}',
          );
        }
      }
    }
  }

  /// Arranges to have an import added for the library with the given [uri].
  ///
  /// [uri] may be converted from an absolute URI to a relative URI depending on
  /// user preferences/lints unless [forceAbsolute] or [forceRelative] are
  /// `true`.
  ///
  /// If [prefix] is an empty string, adds the import without a prefix.
  ///
  /// If [showName] is supplied then any new import will show only this
  /// element, or if an import already exists it will be added to 'show' or
  /// removed from 'hide' if appropriate.
  _LibraryImport _importLibrary(
    Uri uri, {
    String? prefix,
    String? showName,
    bool isExplicitImport = true,
    bool useShow = false,
    bool forceAbsolute = false,
    bool forceRelative = false,
  }) {
    var import = (libraryChangeBuilder ?? this)._librariesToImport[uri];
    var existingShownNames = <List<String>>[];
    var existingHiddenNames = <List<String>>[];

    if (import != null) {
      if (prefix != null) {
        import.prefixes.add(prefix);
      }
      if (showName != null) {
        import._ensureShown(showName, useShow: useShow);
      }
      // If this was an explicit import request, ensure the existing import
      // is marked as such so it cannot be removed by other optimizations.
      if (isExplicitImport) {
        import.isExplicitlyImported = true;
      }
    } else {
      var uriText = _getLibraryUriText(
        uri,
        forceAbsolute: forceAbsolute,
        forceRelative: forceRelative,
      );
      // Collect the list of existing shows and hides for any imports that match
      // the URI and prefix we care about.
      for (var element
          in resolvedUnit.libraryElement.firstFragment.libraryImports) {
        var library = element.importedLibrary;
        if (library == null) {
          continue;
        }
        if ((element.prefix?.element.name ?? '') != (prefix ?? '')) {
          // Imports need to have the same prefix to be replaced.
          continue;
        }
        var elementUrlText = _getLibraryUriText(
          library.uri,
          forceAbsolute: forceAbsolute,
          forceRelative: forceRelative,
        );
        if (uriText != elementUrlText) {
          continue;
        }
        for (var combinator in element.combinators) {
          switch (combinator) {
            case ShowElementCombinator():
              existingShownNames.add(combinator.shownNames.toList());
            case HideElementCombinator():
              existingHiddenNames.add(combinator.hiddenNames.toList());
          }
        }
      }
      import = _LibraryImport(
        uriText: uriText,
        prefix: prefix ?? '',
        isExplicitlyImported: isExplicitImport,
        shownNames: existingShownNames,
        hiddenNames: existingHiddenNames,
      );
      if (showName != null) {
        import._ensureShown(showName, useShow: useShow);
      }
      (libraryChangeBuilder ?? this)._librariesToImport[uri] = import;
      _revertData._addedLibrariesToImport.add(uri);
    }
    return import;
  }

  /// Returns whether the [element] is defined in the target library.
  bool _isDefinedLocally(Element element) {
    return element.library == resolvedUnit.libraryElement;
  }

  /// Removes any pending imports (for [Element]s) that are no longer necessary
  /// because the newly-added [newImport] for [newLibrary] also provides those
  /// [Element]s.
  void _removeUnnecessaryPendingElementImports(
    _LibraryImport newImport,
    LibraryElement? newLibrary,
  ) {
    var elementLibrariesToImport =
        (libraryChangeBuilder ?? this)._elementLibrariesToImport;

    // Replace the imports for any elements that we can satisfy, and collect the
    // set of any that might no longer be needed.
    var candidatesToRemove = <_LibraryImport>{};
    // Use toList() because we'll mutate the maps values while enumerating.
    var existingOtherImports = elementLibrariesToImport.entries.toList();
    for (var MapEntry(key: otherElement, value: otherImport)
        in existingOtherImports) {
      // Ignore those that are the new import or explicit imports (which we can
      // not remove).
      if (otherImport == newImport || otherImport.isExplicitlyImported) {
        continue;
      }

      // If this new import exports the other element, change it to this import
      // and record it as a removal candidate.
      if (newLibrary?.exportNamespace.get2(otherElement.displayName) ==
          otherElement) {
        candidatesToRemove.add(otherImport);
        elementLibrariesToImport[otherElement] = newImport;
      }
    }

    // Remove anything from the removal candidates that is still used by another
    // remaining element.
    var remainingElementImports = elementLibrariesToImport.values.toSet();
    candidatesToRemove.removeWhere(remainingElementImports.contains);

    // And finally, remove the remaining candidates from the set of libraries to
    // be imported.
    (libraryChangeBuilder ?? this)._librariesToImport.removeWhere(
      (_, import) => candidatesToRemove.contains(import),
    );
  }

  /// Creates an edit to replace the return type of the innermost function
  /// containing the given [node] with the type `Future`.
  ///
  /// The [typeSystem] is used to check the current return type, because if it
  /// is already `Future`, no edit will be added.
  void _replaceReturnTypeWithFuture({
    required AstNode? node,
    required TypeSystem typeSystem,
    required TypeProvider typeProvider,
  }) {
    while (node != null) {
      node = node.parent;
      if (node is FunctionDeclaration) {
        replaceTypeWithFuture(
          typeAnnotation: node.returnType,
          typeSystem: typeSystem,
          typeProvider: typeProvider,
        );
        return;
      } else if (node is FunctionExpression &&
          node.parent is! FunctionDeclaration) {
        // Closures don't have a return type.
        return;
      } else if (node is MethodDeclaration) {
        replaceTypeWithFuture(
          typeAnnotation: node.returnType,
          typeSystem: typeSystem,
          typeProvider: typeProvider,
        );
        return;
      }
    }
  }

  /// Creates an edit to replace the return type of the innermost function
  /// containing the given [node] with the `Future` type parameter.
  ///
  /// The [typeSystem] is used to check the current return type, because if it
  /// is not a `Future`, no edit will be added.
  void _replaceReturnTypeWithFutureArgument({
    required AstNode? node,
    required TypeSystem typeSystem,
    required TypeProvider typeProvider,
  }) {
    while (node != null) {
      node = node.parent;
      if (node is FunctionDeclaration) {
        replaceTypeWithFutureArgument(
          typeAnnotation: node.returnType,
          typeSystem: typeSystem,
          typeProvider: typeProvider,
        );
        return;
      } else if (node is FunctionExpression &&
          node.parent is! FunctionDeclaration) {
        // Closures don't have a return type.
        return;
      } else if (node is MethodDeclaration) {
        replaceTypeWithFutureArgument(
          typeAnnotation: node.returnType,
          typeSystem: typeSystem,
          typeProvider: typeProvider,
        );
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
    addSuggestion(LinkedEditSuggestionKind.TYPE, _getTypeSuggestionText(type));
  }

  String _getTypeSuggestionText(InterfaceType type) {
    return type.getDisplayString();
  }
}

/// Information about a library to import.
class ImportLibraryElementResultImpl implements ImportLibraryElementResult {
  @override
  final String? prefix;

  ImportLibraryElementResultImpl(this.prefix);
}

class _DartFileEditBuilderRevertData {
  final List<Uri> _addedLibrariesToImport = [];
}

class _EnclosingElementFinder {
  ClassElement? enclosingClass;
  ExecutableElement? enclosingExecutable;

  _EnclosingElementFinder();

  void find(CompilationUnit target, int offset) {
    var node = target.nodeCovering(offset: offset);
    while (node != null && offset == node.end) {
      // If the offset is just outside the node, then the element declared by
      // the node isn't actually enclosing the offset.
      node = node.parent;
    }
    while (node != null) {
      if (node is ClassDeclaration) {
        enclosingClass = node.declaredFragment?.element;
      } else if (node is ConstructorDeclaration) {
        enclosingExecutable = node.declaredFragment?.element;
      } else if (node is MethodDeclaration) {
        enclosingExecutable = node.declaredFragment?.element;
      } else if (node is FunctionDeclaration) {
        enclosingExecutable = node.declaredFragment?.element;
      }
      node = node.parent;
    }
  }
}

/// A utility for preparing the location of an insertion within a container,
/// like a class or mixin.
class _InsertionPreparer {
  final CompilationUnitMember _declaration;

  final LineInfo _lineInfo;

  final List<ClassMember> _members;

  late final bool _foundTargetMember;

  factory _InsertionPreparer(
    CompilationUnitMember declaration,
    LineInfo lineInfo,
  ) {
    var members = declaration.members;
    if (members == null) {
      assert(
        false,
        'Unexpected CompilationUnitMember: "$declaration" is '
        '"${declaration.runtimeType}"',
      );
      members = [];
    }

    return _InsertionPreparer._(declaration, lineInfo, members);
  }

  _InsertionPreparer._(this._declaration, this._lineInfo, this._members);

  /// Returns the offset of where a new member should be inserted, as a new
  /// member of [_declaration].
  ///
  /// If [lastMemberFilter] is omitted, the offset is just after all existing
  /// members.
  ///
  /// Otherwise, the offset is just after the last member of [_declaration] that
  /// matches [lastMemberFilter]. If no existing member matches, then the offset
  /// is at the beginning of [_declaration], just after it's opening brace.
  int? insertionLocation({
    required bool Function(ClassMember existingMember)? lastMemberFilter,
  }) {
    var targetMember = lastMemberFilter == null
        ? _members.lastOrNull
        : _members.lastWhereOrNull(lastMemberFilter);
    _foundTargetMember = targetMember != null;
    if (targetMember != null) {
      // After the last target member.
      return targetMember.end;
    }

    final declaration = _declaration;
    if (declaration is EnumDeclaration) {
      // After the last enum value.
      var semicolon = declaration.body.semicolon;
      if (semicolon != null) {
        return semicolon.end;
      } else if (declaration.body.constants.isNotEmpty) {
        var lastConstant = declaration.body.constants.last;
        return lastConstant.end;
      }
    }

    // At the beginning of the class.
    var leftBracket = _declaration.leftBracket;
    if (leftBracket == null) {
      return null;
    }
    if (leftBracket.isSynthetic) {
      var previousToken = leftBracket.previous;
      if (previousToken == null) {
        return null;
      }
      return previousToken.end;
    }
    return leftBracket.end;
  }

  /// Writes some prefix text before the new member, typically newlines and
  /// indents, based on the surrounding members.
  ///
  /// This method can only be invoked after [insertionLocation], which first
  /// determines the target member that the insertion follows.
  void writePrefix(DartEditBuilder builder) {
    if (_declaration.leftBracket?.isSynthetic ?? false) {
      builder.write(' {');
    }
    var declaration = _declaration;
    if (declaration is EnumDeclaration && declaration.body.semicolon == null) {
      builder.write(';');
    }

    if (_foundTargetMember) {
      // After the target member, write two newlines.
      builder.writeln();
      builder.writeln();
      builder.writeIndent();
    } else if (declaration is EnumDeclaration &&
        declaration.body.constants.isNotEmpty) {
      // After the last constant (and the semicolon), write two newlines.
      builder.writeln();
      builder.writeln();
      builder.writeIndent();
    } else {
      // After the opening brace, just write one newline.
      builder.writeln();
      builder.writeIndent();
    }
  }

  /// Writes some suffix text after the new member, typically newlines, based
  /// on the surrounding members.
  ///
  /// This method can only be invoked after [insertionLocation], which first
  /// determines the target member that the insertion follows.
  void writeSuffix(DartEditBuilder builder) {
    if (_foundTargetMember) {
      return;
    }

    var declaration = _declaration;
    if (declaration is EnumDeclaration &&
        declaration.body.constants.isNotEmpty) {
      return;
    }

    if (_members.isNotEmpty) {
      builder.writeln();
      return;
    }

    var declarationIsSingleLine = _lineInfo.onSameLine(
      _declaration.firstTokenAfterCommentAndMetadata.offset,
      _declaration.end,
    );
    if (declarationIsSingleLine) {
      builder.writeln();
    }
    var rightBracket = _declaration.rightBracket;
    if (rightBracket == null) {
      return;
    }
    if (rightBracket.isSynthetic) {
      var next = rightBracket.next!;
      if (next.type != TokenType.CLOSE_CURLY_BRACKET) {
        builder.writeln();
        builder.write('}');
      }
    }
  }
}

/// Information about a library import.
class _LibraryImport implements Comparable<_LibraryImport> {
  final String uriText;

  late final DirectiveSortPriority sortPriority;

  /// Prefixes that this library is/will be imported using.
  ///
  /// An empty string means the import is unprefixed. This can be included along
  /// with other prefixes for a library that is both prefixed and unprefixed.
  final Set<String> prefixes = {};

  /// Names this import has in its `show` combinator.
  final List<List<String>> shownNames;

  /// Names this import has in its `hide` combinator.
  final List<List<String>> hiddenNames;

  /// Whether this import was added explicitly, either because it already exists
  /// or a caller requested it was added without the context of an [Element].
  ///
  /// If `false`, this is a pending import that only currently exists to satisfy
  /// [Element] imports and could be removed if subsequent imports also provide
  /// that element. If an explicit call is made to import this library, this
  /// flag may change from `false` to `true`.
  bool isExplicitlyImported;

  _LibraryImport({
    required this.uriText,
    required String prefix,
    required this.isExplicitlyImported,
    List<List<String>>? shownNames,
    List<List<String>>? hiddenNames,
  }) : shownNames = shownNames ?? [],
       hiddenNames = hiddenNames ?? [] {
    sortPriority = DirectiveSortPriority(uriText, DirectiveSortKind.import);
    prefixes.add(prefix);
  }

  /// The set of all names that are hidden for this import.
  Set<String> get allHiddenNames => hiddenNames.expand((e) => e).toSet();

  /// The set of all names that are visible for this import.
  Set<String> get allShownNames => shownNames.expand((e) => e).toSet();

  @override
  int get hashCode => uriText.hashCode;

  /// A prefix that is valid for referencing this library.
  ///
  /// If an empty string is returned, this library can be used unprefixed.
  String get prefix => prefixes.first;

  @override
  bool operator ==(other) {
    return other is _LibraryImport &&
        other.uriText == uriText &&
        const SetEquality().equals(other.prefixes, prefixes);
  }

  @override
  int compareTo(_LibraryImport other) {
    if (sortPriority == other.sortPriority) {
      return compareDirectiveUri(uriText, other.uriText);
    }
    return sortPriority.ordinal - other.sortPriority.ordinal;
  }

  @override
  String toString() {
    return "import '$uriText'${prefix.isNotEmpty ? 'as $prefix' : ''}"
        '${allShownNames.isNotEmpty ? 'show ${allShownNames.join(', ')}' : ''}'
        '${allHiddenNames.isNotEmpty ? 'hide ${allHiddenNames.join(', ')}' : ''};';
  }

  /// Ensures that [name] is visible for this import.
  ///
  /// If the import already has a show combinator, this name will be added.
  /// If the import hides this name, it will be unhidden.
  void _ensureShown(String name, {bool useShow = false}) {
    if (shownNames.isEmpty && useShow) {
      shownNames.add([name]);
    } else if (shownNames.isNotEmpty) {
      shownNames.last.add(name);
    }
    // Remove the name from all the hidden lists.
    for (var hiddenList in hiddenNames) {
      hiddenList.remove(name);
    }
    hiddenNames.removeWhere((nameList) => nameList.isEmpty);
  }
}

extension on Set<DartType> {
  bool containsElementAndArguments(DartType argument) {
    for (var type in this) {
      if (type == argument) {
        return true;
      }
      if (type.element != argument.element) {
        continue;
      }
      if (type is InterfaceType && argument is InterfaceType) {
        if (type.sameTypeArguments(argument)) {
          return true;
        }
      }
    }
    return false;
  }
}

extension on InterfaceType {
  bool sameTypeArguments(InterfaceType other) {
    var typeArgs = typeArguments;
    var otherTypeArgs = other.typeArguments;
    if (typeArgs.length != otherTypeArgs.length) {
      return false;
    }
    for (var i = 0; i < typeArgs.length; i++) {
      var argument = typeArgs[i];
      var otherArgument = otherTypeArgs[i];
      if (argument.element != otherArgument.element) {
        return false;
      }
      if (argument is InterfaceType &&
          otherArgument is InterfaceType &&
          !argument.sameTypeArguments(otherArgument)) {
        return false;
      }
    }
    return true;
  }
}

extension on CompilationUnitMember {
  /// The left bracket of a [CompilationUnitMember] with a known left bracket,
  /// and `null` otherwise.
  Token? get leftBracket {
    var self = this;
    switch (self) {
      case ClassDeclaration():
        if (self.body case BlockClassBody body) {
          return body.leftBracket;
        }
      case EnumDeclaration():
        return self.body.leftBracket;
      case ExtensionDeclaration():
        return self.body.leftBracket;
      case ExtensionTypeDeclaration():
        if (self.body case BlockClassBody body) {
          return body.leftBracket;
        }
      case MixinDeclaration():
        return self.body.leftBracket;
      default:
    }
    return null;
  }

  /// The members of a [CompilationUnitMember] with a known list of members, and
  /// `null` otherwise.
  List<ClassMember>? get members {
    var self = this;
    switch (self) {
      case ClassDeclaration():
        if (self.body case BlockClassBody body) {
          return body.members;
        }
      case EnumDeclaration():
        // Enum constants are handled separately; not considered members.
        return self.body.members;
      case ExtensionDeclaration():
        return self.body.members;
      case ExtensionTypeDeclaration():
        if (self.body case BlockClassBody body) {
          return body.members;
        }
      case MixinDeclaration():
        return self.body.members;
    }
    return null;
  }

  /// The right bracket of a [CompilationUnitMember] with a known right bracket,
  /// and `null` otherwise.
  Token? get rightBracket {
    var self = this;
    switch (self) {
      case ClassDeclaration():
        if (self.body case BlockClassBody body) {
          return body.rightBracket;
        }
      case EnumDeclaration():
        return self.body.rightBracket;
      case ExtensionDeclaration():
        return self.body.rightBracket;
      case ExtensionTypeDeclaration():
        if (self.body case BlockClassBody body) {
          return body.rightBracket;
        }
      case MixinDeclaration():
        return self.body.rightBracket;
    }
    return null;
  }
}

extension on LibraryImport {
  bool get hasCombinator => combinators.isNotEmpty;

  Iterable<HideElementCombinator> get hideCombinators =>
      combinators.whereType<HideElementCombinator>();

  Iterable<ShowElementCombinator> get showCombinators =>
      combinators.whereType<ShowElementCombinator>();
}

extension on DartType {
  TypeImpl? withNullability(NullabilitySuffix nullabilitySuffix) {
    var self = this;
    if (self is TypeImpl) {
      return self.withNullability(nullabilitySuffix);
    }
    return null;
  }
}
