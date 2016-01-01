// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.utilities.change_builder_dart;

import 'package:analysis_server/plugin/protocol/protocol.dart' hide ElementKind;
import 'package:analysis_server/src/provisional/edit/utilities/change_builder_core.dart';
import 'package:analysis_server/src/provisional/edit/utilities/change_builder_dart.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/change_builder_core.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * A [ChangeBuilder] used to build changes in Dart files.
 */
class DartChangeBuilderImpl extends ChangeBuilderImpl
    implements DartChangeBuilder {
  /**
   * The analysis context in which the files being edited were analyzed.
   */
  final AnalysisContext context;

  /**
   * Initialize a newly created change builder.
   */
  DartChangeBuilderImpl(this.context);

  @override
  DartFileEditBuilderImpl createFileEditBuilder(Source source, int fileStamp) {
    return new DartFileEditBuilderImpl(this, source, fileStamp);
  }
}

/**
 * An [EditBuilder] used to build edits in Dart files.
 */
class DartEditBuilderImpl extends EditBuilderImpl implements DartEditBuilder {
  /**
   * A utility class used to help build the source code.
   */
  final CorrectionUtils utils;

  /**
   * Initialize a newly created builder to build a source edit.
   */
  DartEditBuilderImpl(
      DartFileEditBuilderImpl sourceFileEditBuilder, int offset, int length)
      : utils = sourceFileEditBuilder.utils,
        super(sourceFileEditBuilder, offset, length);

  DartFileEditBuilderImpl get dartFileEditBuilder => fileEditBuilder;

  @override
  void writeClassDeclaration(String name,
      {Iterable<DartType> interfaces,
      bool isAbstract: false,
      void memberWriter(),
      Iterable<DartType> mixins,
      String nameGroupName,
      DartType superclass}) {
    // TODO(brianwilkerson) Add support for type parameters, probably as a
    // parameterWriter parameter.
    // TODO(brianwilkerson) Add a superclassGroupName parameter.
    if (isAbstract) {
      write(Keyword.ABSTRACT.syntax);
      write(' ');
    }
    write('class ');
    if (nameGroupName == null) {
      write(name);
    } else {
      addLinkedEdit(DartEditBuilder.NAME_GROUP_ID, (LinkedEditBuilder builder) {
        write(name);
      });
    }
    if (superclass != null) {
      write(' extends ');
      writeType(superclass, groupName: DartEditBuilder.SUPERCLASS_GROUP_ID);
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

  //@override
  void writeConstructorDeclaration(ClassElement classElement,
      {ArgumentList argumentList,
      SimpleIdentifier constructorName,
      bool isConst: false}) {
    // TODO(brianwilkerson) Clean up the API and add it to the public API.
    //
    // TODO(brianwilkerson) Support passing a list of final fields rather than
    // an argument list.
    if (isConst) {
      write(Keyword.CONST.syntax);
      write(' ');
    }
    write(classElement.name);
    write('.');
    if (constructorName != null) {
      addLinkedEdit(DartEditBuilder.NAME_GROUP_ID, (LinkedEditBuilder builder) {
        write(constructorName.name);
      });
      CompilationUnit unit = constructorName
          .getAncestor((AstNode node) => node is CompilationUnit);
      if (unit != null) {
        CompilationUnitElement element = unit.element;
        if (element != null) {
          String referenceFile = element.source.fullName;
          if (referenceFile == dartFileEditBuilder.fileEdit.file) {
            dartFileEditBuilder.addLinkedPosition(constructorName.offset,
                constructorName.length, DartEditBuilder.NAME_GROUP_ID);
          }
        }
      }
    }
    if (argumentList != null) {
      writeParametersMatchingArguments(argumentList);
    } else {
      write('()');
    }
    writeln(' {');
    write('  }');
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
      write(Keyword.STATIC.syntax);
      write(' ');
    }
    bool typeRequired = true;
    if (isConst) {
      write(Keyword.CONST.syntax);
      typeRequired = false;
    } else if (isFinal) {
      write(Keyword.FINAL.syntax);
      typeRequired = false;
    }
    if (type != null) {
      writeType(type, groupName: typeGroupName);
    } else if (typeRequired) {
      write(Keyword.VAR.syntax);
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
  void writeGetterDeclaration(String name,
      {void bodyWriter(),
      bool isStatic: false,
      String nameGroupName,
      DartType returnType,
      String returnTypeGroupName}) {
    if (isStatic) {
      write(Keyword.STATIC.syntax);
      write(' ');
    }
    if (returnType != null) {
      writeType(returnType, groupName: returnTypeGroupName);
      write(' ');
    }
    write(Keyword.GET.syntax);
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
  void writeOverrideOfInheritedMember(ExecutableElement member) {
    // prepare environment
    String prefix = utils.getIndent(1);
    // may be property
    String prefix2 = utils.getIndent(2);
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
    // REVIEW: Added groupId
    bool shouldReturn = writeType(member.type.returnType,
        groupName: DartEditBuilder.RETURN_TYPE_GROUP_ID);
    write(' ');
    if (isGetter) {
      write(Keyword.GET.syntax);
      write(' ');
    } else if (isSetter) {
      write(Keyword.SET.syntax);
      write(' ');
    } else if (isOperator) {
      write(Keyword.OPERATOR.syntax);
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
  void writeParametersMatchingArguments(ArgumentList arguments) {
    Set<String> excluded = new Set();
    bool namedFound = false;
    write('(');
    List<Expression> argumentList = arguments.arguments;
    for (int i = 0; i < argumentList.length; i++) {
      Expression argument = argumentList[i];
      DartType type = argument.bestType;
      List<String> suggestions =
          _getParameterNameSuggestions(excluded, type, argument, i);
      String favorite = suggestions[0];
      // append separator
      if (i > 0) {
        write(', ');
      }
      if (argument is NamedExpression) {
        if (!namedFound) {
          namedFound = true;
          write('[');
        }
        favorite = argument.name.label.name;
      }
      // append type name
      writeType(type, addSupertypeProposals: true, groupName: 'TYPE$i');
      write(' ');
      // append parameter name
      excluded.add(favorite);
      addLinkedEdit('ARG$i', (LinkedEditBuilder builder) {
        builder.write(favorite);
        builder.addSuggestions(LinkedEditSuggestionKind.PARAMETER, suggestions);
      });
    }
    if (namedFound) {
      write(']');
    }
    write(')');
  }

  @override
  void writeParameterSource(DartType type, String name) {
    String parameterSource = utils.getParameterSource(
        type, name, dartFileEditBuilder.librariesToImport);
    write(parameterSource);
  }

  @override
  bool writeType(DartType type,
      {bool addSupertypeProposals: false,
      String groupName,
      bool required: false}) {
    if (type != null && !type.isDynamic) {
      String typeSource =
          utils.getTypeSource(type, dartFileEditBuilder.librariesToImport);
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
    } else if (required) {
      write(Keyword.VAR.syntax);
    }
    return false;
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

  /**
   * Return a list containing the suggested names for a parmeter with the given
   * [type] whose value in one location is computed by the given [expression].
   * The list will not contain any names in the set of [excluded] names. The
   * [index] is the index of the argument, used to create a name if no better
   * name could be created. The first name in the list will be the best name.
   */
  List<String> _getParameterNameSuggestions(
      Set<String> excluded, DartType type, Expression expression, int index) {
    List<String> suggestions =
        getVariableNameSuggestionsForExpression(type, expression, excluded);
    if (suggestions.length != 0) {
      return suggestions;
    }
    return <String>['arg$index'];
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
   * A utility class used to help build the source code.
   */
  CorrectionUtils utils;

  /**
   * A set containing the elements of the libraries that need to be imported in
   * order to make visible the names used in generated code.
   */
  Set<LibraryElement> librariesToImport = new Set<LibraryElement>();

  /**
   * Initialize a newly created builder to build a source file edit within the
   * change being built by the given [changeBuilder]. The file being edited has
   * the given [source] and [timeStamp].
   */
  DartFileEditBuilderImpl(
      DartChangeBuilderImpl changeBuilder, Source source, int timeStamp)
      : super(changeBuilder, source, timeStamp) {
    AnalysisContext context = changeBuilder.context;
    List<Source> librariesContaining = context.getLibrariesContaining(source);
    if (librariesContaining.length < 1) {
      throw new StateError('Cannot build edits for ${source.fullName}');
    }
    unit = context.resolveCompilationUnit2(source, librariesContaining[0]);
    utils = new CorrectionUtils(unit);
  }

  @override
  DartEditBuilderImpl createEditBuilder(int offset, int length) {
    return new DartEditBuilderImpl(this, offset, length);
  }
}
