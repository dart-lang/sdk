// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/range_factory.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class ConvertClassToEnum extends ResolvedCorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_CLASS_TO_ENUM;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_CLASS_TO_ENUM;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_CLASS_TO_ENUM_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!libraryElement.featureSet.isEnabled(Feature.enhanced_enums)) {
      // If the library doesn't support enhanced_enums then the class can't be
      // converted.
      return;
    }
    if (libraryElement.units.length > 1) {
      // If the library has any part files, then the class can't be converted
      // because we don't currently have a performant way to access the ASTs for
      // the parts to check for invocations of the constructors or subclasses of
      // the class.
      return;
    }
    final declaration = node;
    if (declaration is ClassDeclaration && declaration.name == token) {
      var description = _EnumDescription.fromClass(declaration);
      if (description != null) {
        await builder.addDartFileEdit(file, (builder) {
          description.applyChanges(builder, utils);
        });
      }
    }
  }
}

/// A superclass for the [_EnumVisitor] and [_NonEnumVisitor].
class _BaseVisitor extends RecursiveAstVisitor<void> {
  /// The element representing the enum declaration that's being visited.
  final ClassElement classElement;

  _BaseVisitor(this.classElement);

  /// Return `true` if the given [node] is an invocation of a generative
  /// constructor from the class being converted.
  bool invokesGenerativeConstructor(InstanceCreationExpression node) {
    var constructorElement = node.constructorName.staticElement;
    return constructorElement != null &&
        !constructorElement.isFactory &&
        constructorElement.enclosingElement == classElement;
  }
}

/// An exception thrown by the visitors if a condition is found that prevents
/// the class from being converted.
class _CannotConvertException implements Exception {
  final String message;

  _CannotConvertException(this.message);
}

/// A representation of a static field in the class being converted that will be
/// replaced by an enum constant.
class _ConstantField extends _Field {
  /// The element representing the constructor used to initialize the field.
  ConstructorElement constructorElement;

  /// The invocation of the constructor.
  final InstanceCreationExpression instanceCreation;

  /// The value of the index field.
  final int indexValue;

  _ConstantField(
      super.element,
      super.declaration,
      super.declarationList,
      super.fieldDeclaration,
      this.instanceCreation,
      this.constructorElement,
      this.indexValue);
}

/// Information about a single constructor in the class being converted.
class _Constructor {
  /// The declaration of the constructor.
  final ConstructorDeclaration declaration;

  /// The element representing the constructor.
  final ConstructorElement element;

  _Constructor(this.declaration, this.element);
}

/// Information about the constructors in the class being converted.
class _Constructors {
  /// A map from elements to constructors.
  final Map<ConstructorElement, _Constructor> byElement = {};

  _Constructors();

  /// Return the constructors in this collection.
  Iterable<_Constructor> get constructors => byElement.values;

  /// Add the given [constructor] to this collection.
  void add(_Constructor constructor) {
    byElement[constructor.element] = constructor;
  }

  /// Return the constructor with the given [element].
  _Constructor? forElement(ConstructorElement element) {
    return byElement[element];
  }
}

/// A description of how to convert the class to an enum.
class _EnumDescription {
  /// The class declaration being converted.
  final ClassDeclaration classDeclaration;

  /// A map from constructor declarations to information about the parameter
  /// corresponding to the index field. The map is `null` if there is no index
  /// field.
  final Map<_Constructor, _Parameter>? constructorMap;

  /// A list of the declarations to be converted into enum constants.
  final _Fields fields;

  /// A list of the indexes of members that need to be deleted.
  final List<int> membersToDelete;

  _EnumDescription({
    required this.classDeclaration,
    required this.constructorMap,
    required this.fields,
    required this.membersToDelete,
  });

  /// Return the offset immediately following the opening brace for the class
  /// body.
  int get bodyOffset => classDeclaration.leftBracket.end;

  /// Use the [builder] and correction [utils] to apply the change necessary to
  /// convert the class to an enum.
  void applyChanges(DartFileEditBuilder builder, CorrectionUtils utils) {
    // Replace the keyword.
    builder.addSimpleReplacement(
        range.token(classDeclaration.classKeyword), 'enum');

    // Remove the extends clause if there is one.
    final extendsClause = classDeclaration.extendsClause;
    if (extendsClause != null) {
      var followingToken = extendsClause.endToken.next!;
      builder.addDeletion(range.startStart(extendsClause, followingToken));
    }

    // Compute the declarations of the enum constants and delete the fields
    // being converted.
    var members = classDeclaration.members;
    var indent = utils.getIndent(1);
    var eol = utils.endOfLine;
    var constantsBuffer = StringBuffer();
    var fieldsToConvert = fields.fieldsToConvert;
    fieldsToConvert
        .sort((first, second) => first.indexValue.compareTo(second.indexValue));
    for (var field in fieldsToConvert) {
      // Compute the declaration of the corresponding enum constant.
      if (constantsBuffer.isNotEmpty) {
        constantsBuffer.write(',$eol$indent');
      }
      constantsBuffer.write(field.name);
      var invocation = field.instanceCreation;
      var constructorNameNode = invocation.constructorName;
      var invokedConstructorElement = field.constructorElement;
      var invokedConstructor = constructorMap?.keys.firstWhere(
          (constructor) => constructor.element == invokedConstructorElement);
      var parameterData = constructorMap?[invokedConstructor];
      var typeArguments = constructorNameNode.type.typeArguments;
      if (typeArguments != null) {
        constantsBuffer.write(utils.getNodeText(typeArguments));
      }
      var constructorName = constructorNameNode.name?.name;
      if (constructorName != null) {
        constantsBuffer.write('.$constructorName');
      }
      var argumentList = invocation.argumentList;
      var arguments = argumentList.arguments;
      var argumentCount = arguments.length - (parameterData == null ? 0 : 1);
      if (argumentCount == 0) {
        if (typeArguments != null || constructorName != null) {
          constantsBuffer.write('()');
        }
      } else if (parameterData == null) {
        constantsBuffer.write(utils.getNodeText(argumentList));
      } else {
        constantsBuffer.write('(');
        var index = parameterData.index;
        var last = arguments.length - 1;
        if (index == 0) {
          var offset = arguments[1].offset;
          var length = arguments[last].end - offset;
          constantsBuffer.write(utils.getText(offset, length));
        } else if (index == last) {
          var offset = arguments[0].offset;
          int length;
          if (arguments[last].endToken.next?.type == TokenType.COMMA) {
            length = arguments[last].offset - offset;
          } else {
            length = arguments[last - 1].end - offset;
          }
          constantsBuffer.write(utils.getText(offset, length));
        } else {
          var offset = arguments[0].offset;
          var length = arguments[index].offset - offset;
          constantsBuffer.write(utils.getText(offset, length));

          offset = arguments[index + 1].offset;
          length = argumentList.endToken.offset - offset;
          constantsBuffer.write(utils.getText(offset, length));
        }
        constantsBuffer.write(')');
      }

      // Delete the static field that was converted to an enum constant.
      _deleteField(builder, field, members);
    }

    // Remove the index field.
    var indexField = fields.indexField;
    if (indexField != null) {
      _deleteField(builder, indexField, members);
    }

    // Update the constructors.
    var removedConstructor = _removeUnnamedConstructor();
    _transformConstructors(builder, removedConstructor);

    // Special case replacing all of the members.
    if (membersToDelete.length == members.length) {
      builder.addSimpleReplacement(range.startEnd(members.first, members.last),
          constantsBuffer.toString());
      return;
    }

    // Insert the declarations of the enum constants.
    var semicolon = ';';
    var prefix = '$eol$indent';
    var suffix = '$semicolon$eol';
    builder.addSimpleInsertion(bodyOffset, '$prefix$constantsBuffer$suffix');

    // Delete any members that are no longer needed.
    membersToDelete.sort();
    for (var range in range.nodesInList(members, membersToDelete)) {
      builder.addDeletion(range);
    }
  }

  /// Use the [builder] to delete the [field].
  void _deleteField(DartFileEditBuilder builder, _Field field,
      NodeList<ClassMember> members) {
    var variableList = field.declarationList;
    if (variableList.variables.length == 1) {
      membersToDelete.add(members.indexOf(field.fieldDeclaration));
    } else {
      builder.addDeletion(
          range.nodeInList(variableList.variables, field.declaration));
    }
  }

  /// If the unnamed constructor is the only constructor, and if it has no
  /// parameters other than potentially the index field, then remove it.
  ConstructorDeclaration? _removeUnnamedConstructor() {
    var members = classDeclaration.members;
    var constructors = members.whereType<ConstructorDeclaration>().toList();
    if (constructors.length != 1) {
      return null;
    }
    var constructor = constructors[0];
    var name = constructor.name?.lexeme;
    if (name != null && name != 'new') {
      return null;
    }
    var parameters = constructor.parameters.parameters;
    // If there's only one constructor, then there can only be one entry in the
    // constructor map.
    var parameterData = constructorMap?.entries.first.value;
    // `parameterData` should only be `null` if there is no index field.
    var updatedParameterCount =
        parameters.length - (parameterData == null ? 0 : 1);
    if (updatedParameterCount != 0) {
      return null;
    }
    membersToDelete.add(members.indexOf(constructor));
    return constructor;
  }

  /// Transform the used constructors by removing the parameter corresponding to
  /// the index field.
  void _transformConstructors(
      DartFileEditBuilder builder, ConstructorDeclaration? removedConstructor) {
    final constructorMap = this.constructorMap;
    if (constructorMap == null) {
      return;
    }
    for (var constructor in constructorMap.keys) {
      if (constructor.declaration != removedConstructor) {
        var parameterData = constructorMap[constructor];
        if (parameterData != null) {
          var parameters = constructor.declaration.parameters.parameters;
          builder.addDeletion(
              range.nodeInList(parameters, parameters[parameterData.index]));
        }
      }
    }
  }

  /// If the given [node] can be converted into an enum, then return a
  /// description of the conversion work to be done. Otherwise, return `null`.
  static _EnumDescription? fromClass(ClassDeclaration node) {
    // The class must be a concrete class.
    var classElement = node.declaredElement;
    if (classElement == null || classElement.isAbstract) {
      return null;
    }

    // The class must be a subclass of Object, whether implicitly or explicitly.
    var extendsClause = node.extendsClause;
    if (extendsClause != null &&
        extendsClause.superclass.type?.isDartCoreObject == false) {
      return null;
    }

    // The class must either be private or must only have private constructors.
    var constructors = _validateConstructors(node, classElement);
    if (constructors == null) {
      return null;
    }

    // The class must not override either `==` or `hashCode`.
    if (!_validateMethods(node)) {
      return null;
    }

    // There must be at least one static field that can be converted into an
    // enum constant.
    //
    // The instance fields must all be final.
    var fields = _validateFields(node, classElement);
    if (fields == null || fields.fieldsToConvert.isEmpty) {
      return null;
    }

    var visitor = _EnumVisitor(classElement, fields.fieldsToConvert);
    try {
      node.accept(visitor);
    } on _CannotConvertException {
      return null;
    }

    // Within the defining library,
    // - there can't be any subclasses of the class to be converted,
    // - there can't be any invocations of any constructor from that class.
    try {
      node.root.accept(_NonEnumVisitor(classElement));
    } on _CannotConvertException {
      return null;
    }

    var usedConstructors = _computeUsedConstructors(constructors, fields);
    var constructorMap = _indexFieldData(usedConstructors, fields);
    if (fields.indexField != null && constructorMap == null) {
      return null;
    }

    var membersToDelete = <int>[];
    return _EnumDescription(
      classDeclaration: node,
      constructorMap: constructorMap,
      fields: fields,
      membersToDelete: membersToDelete,
    );
  }

  /// Return the subset of [constructors] that are invoked by the [fields] to be
  /// converted.
  static _Constructors _computeUsedConstructors(
      _Constructors constructors, _Fields fields) {
    var usedElements = <ConstructorElement>{};
    for (var field in fields.fieldsToConvert) {
      usedElements.add(field.constructorElement);
    }
    var usedConstructors = _Constructors();
    for (var element in usedElements) {
      var constructor = constructors.forElement(element);
      if (constructor != null) {
        usedConstructors.add(constructor);
      }
    }
    return usedConstructors;
  }

  /// If the index field can be removed, return a map describing the changes
  /// that need to be made to both the constructors and the invocations of those
  /// constructors. Otherwise, return `null`.
  static Map<_Constructor, _Parameter>? _indexFieldData(
      _Constructors usedConstructors, _Fields fields) {
    var indexField = fields.indexField;
    if (indexField == null) {
      return null;
    }
    // Ensure that the index field has a corresponding field formal initializer
    // in each of the used constructors.
    var constructorMap = <_Constructor, _Parameter>{};
    for (var constructor in usedConstructors.constructors) {
      var parameterData = _indexParameter(constructor, indexField);
      if (parameterData == null) {
        return null;
      }
      constructorMap[constructor] = parameterData;
    }

    var fieldsToConvert = fields.fieldsToConvert;
    var values = <int>{};
    for (var field in fieldsToConvert) {
      var constructorElement = field.constructorElement;
      var constructor = usedConstructors.forElement(constructorElement);
      if (constructor == null) {
        // We should never reach this point.
        return null;
      }
      var parameterData = constructorMap[constructor];
      if (parameterData == null) {
        // We should never reach this point.
        return null;
      }
      var arguments = field.instanceCreation.argumentList.arguments;
      var argument = parameterData.getArgument(arguments);
      if (argument is! IntegerLiteral) {
        return null;
      }
      var value = argument.value;
      if (value == null) {
        return null;
      }
      if (!values.add(value)) {
        // Duplicate value.
        return null;
      }
    }
    var sortedValues = values.toList()..sort();
    if (sortedValues.length == fieldsToConvert.length &&
        sortedValues.first == 0 &&
        sortedValues.last == fieldsToConvert.length - 1) {
      return constructorMap;
    }
    return null;
  }

  static _Parameter? _indexParameter(
      _Constructor constructor, _Field? indexField) {
    if (indexField == null) {
      return null;
    }
    var parameters = constructor.declaration.parameters.parameters;
    var indexFieldElement = indexField.element;
    for (var i = 0; i < parameters.length; i++) {
      var element = parameters[i].declaredElement;
      if (element is FieldFormalParameterElement) {
        if (element.field == indexFieldElement) {
          if (element.isPositional) {
            return _Parameter(i, element);
          } else {
            return _Parameter(i, element);
          }
        }
      }
    }
    return null;
  }

  /// Return a representation of all of the constructors declared by the
  /// [classDeclaration], or `null` if the class can't be converted.
  ///
  /// The [classElement] must be the element declared by the [classDeclaration].
  static _Constructors? _validateConstructors(
      ClassDeclaration classDeclaration, ClassElement classElement) {
    var constructors = _Constructors();
    for (var member in classDeclaration.members) {
      if (member is ConstructorDeclaration) {
        var constructor = member.declaredElement;
        if (constructor is ConstructorElement) {
          if (!classElement.isPrivate && !constructor.isPrivate) {
            // Public constructor in public enum.
            return null;
          } else if (!constructor.isFactory && !constructor.isConst) {
            // Non-const constructor.
            return null;
          }
          constructors.add(_Constructor(member, constructor));
        } else {
          // Not resolved.
          return null;
        }
      }
    }
    return constructors;
  }

  /// Return a representation of all of the constructors declared by the
  /// [classDeclaration], or `null` if the class can't be converted.
  ///
  /// The [classElement] must be the element declared by the [classDeclaration].
  static _Fields? _validateFields(
      ClassDeclaration classDeclaration, ClassElement classElement) {
    var potentialFieldsToConvert = <DartObject, List<_ConstantField>>{};
    _Field? indexField;

    for (var member in classDeclaration.members) {
      if (member is FieldDeclaration) {
        var fieldList = member.fields;
        var fields = fieldList.variables;
        if (member.isStatic) {
          for (var field in fields) {
            var fieldElement = field.declaredElement;
            if (fieldElement is FieldElement) {
              var fieldType = fieldElement.type;
              // The field can be converted to be an enum constant if it
              // - is a const field,
              // - has a type equal to the type of the class, and
              // - is initialized by an instance creation expression defined in this
              //   class.
              if (fieldElement.isConst &&
                  fieldType is InterfaceType &&
                  fieldType.element == classElement) {
                var initializer = field.initializer;
                if (initializer is InstanceCreationExpression) {
                  var constructorElement =
                      initializer.constructorName.staticElement;
                  if (constructorElement != null &&
                      !constructorElement.isFactory &&
                      constructorElement.enclosingElement == classElement) {
                    var fieldValue = fieldElement.computeConstantValue();
                    if (fieldValue != null) {
                      if (fieldList.variables.length != 1) {
                        // Too many constants in the field declaration.
                        return null;
                      }
                      potentialFieldsToConvert
                          .putIfAbsent(fieldValue, () => [])
                          .add(_ConstantField(
                              fieldElement,
                              field,
                              fieldList,
                              member,
                              initializer,
                              constructorElement,
                              fieldValue.getField('index')?.toIntValue() ??
                                  -1));
                    }
                  }
                }
              }
            }
          }
        } else {
          for (var field in fields) {
            if (!field.isFinal) {
              // Non-final instance field.
              return null;
            }
            var fieldElement = field.declaredElement;
            if (fieldElement is FieldElement) {
              var fieldType = fieldElement.type;
              if (fieldElement.name == 'index' && fieldType.isDartCoreInt) {
                indexField = _Field(fieldElement, field, fieldList, member);
              }
            }
          }
        }
      }
    }

    var fieldsToConvert = <_ConstantField>[];
    for (var list in potentialFieldsToConvert.values) {
      if (list.length == 1) {
        fieldsToConvert.add(list[0]);
      } else {
        // TODO(brianwilkerson) We could potentially handle the case where
        //  there's only one non-deprecated field in the list. We'd need to
        //  change the return type for this method so that we could return two
        //  lists: the list of fields to convert and the list of fields whose
        //  initializer needs to be updated to refer to the constant.
        return null;
      }
    }
    return _Fields(fieldsToConvert, indexField);
  }

  /// Return `true` if the [classDeclaration] does not contain any methods that
  /// prevent it from being converted.
  static bool _validateMethods(ClassDeclaration classDeclaration) {
    for (var member in classDeclaration.members) {
      if (member is MethodDeclaration) {
        final name = member.name.lexeme;
        if (name == '==' || name == 'hashCode') {
          return false;
        }
      }
    }
    return true;
  }
}

/// A visitor used to visit the class being converted. This visitor throws an
/// exception if a constructor for the class is invoked anywhere other than the
/// top-level expression of an initializer for one of the fields being converted.
class _EnumVisitor extends _BaseVisitor {
  /// The declarations of the fields that are to be converted.
  final List<VariableDeclaration> fieldsToConvert;

  /// A flag indicating whether we are currently visiting the children of a
  /// field declaration that will be converted to be a constant.
  bool inConstantDeclaration = false;

  /// Initialize a newly created visitor to visit the class declaration
  /// corresponding to the given [classElement].
  _EnumVisitor(super.classElement, List<_ConstantField> fieldsToConvert)
      : fieldsToConvert =
            fieldsToConvert.map((field) => field.declaration).toList();

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!inConstantDeclaration) {
      if (invokesGenerativeConstructor(node)) {
        throw _CannotConvertException(
            'Constructor used outside constant initializer');
      }
    }
    inConstantDeclaration = false;
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (fieldsToConvert.contains(node)) {
      inConstantDeclaration = true;
    }
    super.visitVariableDeclaration(node);
    inConstantDeclaration = false;
  }
}

/// A representation of a field of interest in the class being converted.
class _Field {
  /// The element representing the field.
  final FieldElement element;

  /// The declaration of the field.
  final VariableDeclaration declaration;

  /// The list containing the [declaration]
  final VariableDeclarationList declarationList;

  /// The field declaration containing the [declarationList].
  final FieldDeclaration fieldDeclaration;

  _Field(this.element, this.declaration, this.declarationList,
      this.fieldDeclaration);

  /// Return the name of the field.
  String get name => declaration.name.lexeme;
}

/// A representation of all the fields of interest in the class being converted.
class _Fields {
  /// The fields to be converted into enum constants.
  List<_ConstantField> fieldsToConvert;

  /// The index field, or `null` if there is no index field.
  _Field? indexField;

  _Fields(this.fieldsToConvert, this.indexField);
}

/// A visitor that visits everything in the library other than the class being
/// converted. This visitor throws an exception if the class can't be converted
/// because
/// - there is a subclass of the class, or
/// - there is an invocation of one of the constructors of the class.
class _NonEnumVisitor extends _BaseVisitor {
  /// Initialize a newly created visitor to visit everything except the class
  /// declaration corresponding to the given [classElement].
  _NonEnumVisitor(super.classElement);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var element = node.declaredElement;
    if (element == null) {
      throw _CannotConvertException('Unresolved');
    }
    if (element != classElement) {
      if (element.supertype?.element == classElement) {
        throw _CannotConvertException('Class is extended');
      } else if (element.interfaces
          .map((e) => e.element)
          .contains(classElement)) {
        throw _CannotConvertException('Class is implemented');
      } else if (element.mixins.map((e) => e.element).contains(classElement)) {
        // This case won't occur unless there's an error in the source code, but
        // it's easier to check for the condition than it is to check for the
        // diagnostic.
        throw _CannotConvertException('Class is mixed in');
      }
      super.visitClassDeclaration(node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (invokesGenerativeConstructor(node)) {
      throw _CannotConvertException(
          'Constructor used outside class being converted');
    }
    super.visitInstanceCreationExpression(node);
  }
}

/// An object used to access information about a specific parameter, including
/// its index in the parameter list as well as any associated argument in an
/// argument list.
class _Parameter {
  /// The index of this parameter in the enclosing constructor's parameter list.
  final int index;

  /// The element associated with the parameter.
  final ParameterElement element;

  _Parameter(this.index, this.element);

  /// Return the expression representing the argument associated with this
  /// parameter, or `null` if there is no such argument.
  Expression? getArgument(NodeList<Expression> arguments) {
    return arguments.firstWhereOrNull(
        (argument) => argument.staticParameterElement == element);
  }
}
