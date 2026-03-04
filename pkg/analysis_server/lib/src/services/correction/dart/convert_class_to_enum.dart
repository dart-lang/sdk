// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/object.dart';
import 'package:analysis_server/src/utilities/extensions/range_factory.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
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

import '../../../utilities/extensions/ast.dart';

typedef _Constructors = Map<ConstructorElement, _Constructor>;

/// This correction producer converts a class to an enum, if possible, by making
/// the following changes:
///
/// * changes the `class` keyword to `enum`,
/// * removes the `const` keyword from the primary constructor, if there is one,
/// * converts static fields into enum constant values,
/// * removes an `int index` field if there is one,
/// * removes any field formal parameters for the index field from all
///   constructors,
/// * removes all arguments for said index field formal parameters,
/// * removes the singular constructor (primary, or in-body), if there is only
///   one, and it no longer accepts any arguments (after removing a possible
///   index parameter), and it has no doc comment nor annotations.
class ConvertClassToEnum extends ResolvedCorrectionProducer {
  ConvertClassToEnum({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertClassToEnum;

  @override
  FixKind get fixKind => DartFixKind.convertClassToEnum;

  @override
  FixKind get multiFixKind => DartFixKind.convertClassToEnumMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var declaration = node.parent;
    if (declaration is! ClassDeclaration ||
        declaration.namePart.typeName != token) {
      return;
    }
    if (!isEnabled(Feature.enhanced_enums)) {
      // If the library doesn't support enhanced_enums then the class can't be
      // converted.
      return;
    }
    if (libraryElement2.fragments.length > 1) {
      // If the library has any part files, then the class can't be converted
      // because we don't currently have a performant way to access the ASTs for
      // the parts to check for invocations of the constructors or subclasses of
      // the class.
      return;
    }

    var description = _EnumDescription.fromClass(
      declaration,
      strictCasts: analysisOptions.strictCasts,
    );
    if (description != null) {
      await builder.addDartFileEdit(file, (builder) {
        description.applyChanges(builder, utils);
      });
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
    var constructorElement = node.constructorName.element;
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
class _ConstantField extends _FieldDeclaredInVariableDeclaration {
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
    this.instanceCreation,
    this.constructorElement,
    this.indexValue,
  );
}

/// Information about a single constructor (regular or primary) in the class
/// being converted.
class _Constructor {
  /// The declaration of the constructor, either a [ConstructorDeclaration] or a
  /// [PrimaryConstructorDeclaration].
  final AstNode declaration;

  /// The parameter list for this constructor.
  final FormalParameterList parameters;

  /// The element representing the constructor.
  final ConstructorElement element;

  _Constructor(this.declaration, this.parameters, this.element)
    : assert(
        declaration is ConstructorDeclaration ||
            declaration is PrimaryConstructorDeclaration,
      );
}

/// A description of how to convert the class to an enum.
class _EnumDescription {
  /// The class declaration being converted.
  final ClassDeclaration classDeclaration;

  /// A map from constructor declarations to information about the parameter
  /// corresponding to the 'index' field, or `null` if there is no 'index'
  /// field.
  final Map<_Constructor, _Parameter>? _constructorMap;

  /// A list of the declarations to be converted into enum constants.
  final List<_ConstantField> fieldsToConvert;

  /// The 'index' field, if there is one.
  final _Field? _indexField;

  /// The indexes of members that need to be deleted.
  final List<int> membersToDelete = [];

  /// The primary constructor, if it needs to be deleted.
  PrimaryConstructorDeclaration? primaryConstructorToDelete;

  /// The indexes of primary constructor parameters that need to be deleted.
  final List<int> parametersToDelete = [];

  _EnumDescription({
    required this.classDeclaration,
    required Map<_Constructor, _Parameter>? constructorMap,
    required this.fieldsToConvert,
    required _Field? indexField,
  }) : _indexField = indexField,
       _constructorMap = constructorMap;

  /// Return the offset immediately following the opening brace for the class
  /// body.
  int get bodyOffset =>
      (classDeclaration.body as BlockClassBody).leftBracket.end;

  /// Use the [builder] and correction [utils] to apply the change necessary to
  /// convert the class to an enum.
  void applyChanges(DartFileEditBuilder builder, CorrectionUtils utils) {
    // Replace the keyword.
    builder.addSimpleReplacement(
      range.token(classDeclaration.classKeyword),
      'enum',
    );

    if (classDeclaration.namePart case PrimaryConstructorDeclaration(
      :var constKeyword?,
    )) {
      builder.addDeletion(range.startStart(constKeyword, constKeyword.next!));
    }

    // Remove the extends clause if there is one.
    var extendsClause = classDeclaration.extendsClause;
    if (extendsClause != null) {
      var followingToken = extendsClause.endToken.next!;
      builder.addDeletion(range.startStart(extendsClause, followingToken));
    }

    // Compute the declarations of the enum constants and delete the fields
    // being converted.
    var members = classDeclaration.members2;
    var indent = utils.oneIndent;
    var eol = utils.endOfLine;
    var constantsBuffer = StringBuffer();
    fieldsToConvert.sort((a, b) => a.indexValue.compareTo(b.indexValue));
    for (var field in fieldsToConvert) {
      // Compute the declaration of the corresponding enum constant.
      var documentationComment = field.fieldDeclaration.documentationComment;
      if (constantsBuffer.isNotEmpty) {
        constantsBuffer.write(',$eol');
        if (documentationComment != null) {
          // If the current field has a documentation comment and
          // it's not the first field, add an extra new line.
          constantsBuffer.write(eol);
        }
        constantsBuffer.write(indent);
      }
      if (documentationComment != null) {
        constantsBuffer.write(utils.getNodeText(documentationComment));
        constantsBuffer.write('$eol$indent');
      }
      constantsBuffer.write(field.declaration.name.lexeme);
      var invocation = field.instanceCreation;
      var constructorNameNode = invocation.constructorName;
      var invokedConstructorElement = field.constructorElement;
      var invokedConstructor = _constructorMap?.keys.firstWhere(
        (constructor) => constructor.element == invokedConstructorElement,
      );
      var parameterData = _constructorMap?[invokedConstructor];
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
    if (_indexField != null) {
      _deleteField(builder, _indexField, members);
    }

    // Update the constructors.
    _transformConstructors(builder);

    if (primaryConstructorToDelete case var primaryConstructor?) {
      if (primaryConstructor.constructorName case var constuctorName?) {
        builder.addDeletion(range.startEnd(constuctorName, primaryConstructor));
      } else {
        builder.addDeletion(range.node(primaryConstructor.formalParameters));
      }
    }

    // Special case replacing all of the members.
    if (membersToDelete.length == members.length) {
      builder.addSimpleReplacement(
        range.startEnd(members.first, members.last),
        constantsBuffer.toString(),
      );
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

    var primaryConstructor = classDeclaration.namePart;
    if (primaryConstructor is PrimaryConstructorDeclaration) {
      parametersToDelete.sort();
      for (var range in range.nodesInList(
        primaryConstructor.formalParameters.parameters,
        parametersToDelete,
      )) {
        builder.addDeletion(range);
      }
    }
  }

  /// Use the [builder] to delete the [fieldData].
  void _deleteField(
    DartFileEditBuilder builder,
    _Field fieldData,
    List<ClassMember> members,
  ) {
    if (fieldData is _FieldDeclaredInVariableDeclaration) {
      var variableList = fieldData.fieldDeclaration.fields;
      if (variableList.variables.length == 1) {
        membersToDelete.add(members.indexOf(fieldData.fieldDeclaration));
      } else {
        builder.addDeletion(
          range.nodeInList(variableList.variables, fieldData.declaration),
        );
      }
    } else if (fieldData is _FieldDeclaredInPrimaryConstructor) {
      var parameters = fieldData.parameterList.parameters;
      parametersToDelete.add(parameters.indexOf(fieldData.parameter));
    }
  }

  /// Adds the unnamed constructor declaration to [membersToDelete], and returns
  /// it, if it is the only constructor, has no parameters (other than
  /// potentially the index field), has no metadata, and has no doc comments.
  AstNode? /* ConstructorDeclaration? | PrimaryConstructorDeclaration? */
  _removeUnnamedConstructor() {
    var members = classDeclaration.members2;
    var constructors = members.whereType<ConstructorDeclaration>().toList();
    var primaryConstructor = classDeclaration.namePart
        .ifTypeOrNull<PrimaryConstructorDeclaration>();

    if (primaryConstructor == null) {
      if (constructors.length != 1) return null;

      var constructor = constructors[0];
      var name = constructor.name?.lexeme;
      if (name != null && name != 'new') return null;

      if (constructor.documentationComment != null) return null;
      if (constructor.metadata.isNotEmpty) return null;
      if (constructor.initializers.isNotEmpty) return null;

      var parameters = constructor.parameters.parameters;
      // If there's only one constructor, then there can only be one entry in the
      // constructor map.
      var parameterData = _constructorMap?.entries.first.value;
      // `parameterData` should only be `null` if there is no index field.
      var updatedParameterCount =
          parameters.length - (parameterData == null ? 0 : 1);
      if (updatedParameterCount != 0) return null;

      membersToDelete.add(members.indexOf(constructor));
      return constructor;
    } else {
      if (constructors.isNotEmpty) return null; // Other constructors.

      var name = primaryConstructor.constructorName?.name.lexeme;
      if (name != null && name != 'new') return null;

      if (primaryConstructor.body case var body?) {
        if (body.documentationComment != null) return null;
        if (body.metadata.isNotEmpty) return null;
        if (body.initializers.isNotEmpty) return null;
      }

      var parameters = primaryConstructor.formalParameters.parameters;
      // If there's only one constructor, then there can only be one entry in the
      // constructor map.
      var parameterData = _constructorMap?.entries.first.value;
      // `parameterData` should only be `null` if there is no index field.
      var updatedParameterCount =
          parameters.length - (parameterData == null ? 0 : 1);
      if (updatedParameterCount != 0) return null;

      primaryConstructorToDelete = primaryConstructor;
      return primaryConstructor;
    }
  }

  /// Transform the used constructors by removing the parameter corresponding to
  /// the index field.
  void _transformConstructors(DartFileEditBuilder builder) {
    var removedConstructor = _removeUnnamedConstructor();

    if (_constructorMap == null) return;

    for (var constructorData in _constructorMap.keys) {
      // The removed constructor is simply removed; don't change its parameters.
      if (constructorData.declaration == removedConstructor) continue;

      var parameterData = _constructorMap[constructorData];
      if (parameterData != null) {
        var parameters = constructorData.parameters.parameters;
        builder.addDeletion(
          range.nodeInList(parameters, parameters[parameterData.index]),
        );
      }
    }
  }

  /// If the given [node] can be converted into an enum, then return a
  /// description of the conversion work to be done. Otherwise, return `null`.
  static _EnumDescription? fromClass(
    ClassDeclaration node, {
    required bool strictCasts,
  }) {
    // The class must be a concrete class.
    var classElement = node.declaredFragment?.element;
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
    var fields = _validateFields(node, classElement, strictCasts: strictCasts);
    if (fields == null) return null;
    var (fieldsToConvert, indexField) = fields;
    if (fieldsToConvert.isEmpty) return null;

    var visitor = _EnumVisitor(classElement, fieldsToConvert);
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

    var usedConstructors = _computeUsedConstructors(
      constructors,
      fieldsToConvert,
    );
    var constructorMap = _indexFieldData(
      usedConstructors,
      fieldsToConvert,
      indexField,
    );
    if (indexField != null && constructorMap == null) {
      return null;
    }

    return _EnumDescription(
      classDeclaration: node,
      constructorMap: constructorMap,
      fieldsToConvert: fieldsToConvert,
      indexField: indexField,
    );
  }

  /// Return the subset of [constructors] that are invoked by the [fields] to be
  /// converted.
  static _Constructors _computeUsedConstructors(
    _Constructors constructors,
    List<_ConstantField> fieldsToConvert,
  ) {
    var usedElements = {
      for (var field in fieldsToConvert) field.constructorElement,
    };
    return {for (var element in usedElements) element: ?constructors[element]};
  }

  /// If the index field can be removed, return a map describing the changes
  /// that need to be made to both the constructors and the invocations of those
  /// constructors. Otherwise, return `null`.
  static Map<_Constructor, _Parameter>? _indexFieldData(
    _Constructors usedConstructors,
    List<_ConstantField> fieldsToConvert,
    _Field? indexField,
  ) {
    if (indexField == null) return null;

    // Ensure that the index field has a corresponding field formal initializer
    // in each of the used constructors.
    var constructorMap = <_Constructor, _Parameter>{};
    for (var constructor in usedConstructors.values) {
      var parameterData = _indexParameter(constructor, indexField);
      if (parameterData == null) {
        return null;
      }
      constructorMap[constructor] = parameterData;
    }

    var values = <int>{};
    for (var field in fieldsToConvert) {
      var constructorElement = field.constructorElement;
      var constructor = usedConstructors[constructorElement];
      if (constructor == null) {
        assert(false, 'Missing _Constructor for $constructorElement');
        return null;
      }
      var parameterData = constructorMap[constructor];
      if (parameterData == null) {
        assert(false, 'Missing _Parameter for $constructor');
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

  /// Returns a [_Parameter] which describes the [FieldFormalParameterElement]
  /// for the 'index' field, if there is one, and `null` if there is not.
  static _Parameter? _indexParameter(
    _Constructor constructor,
    _Field indexFieldData,
  ) {
    var parameters = constructor.parameters.parameters;
    var indexFieldElement = indexFieldData.element;
    for (var i = 0; i < parameters.length; i++) {
      var element = parameters[i].declaredFragment!.element;
      if (element is FieldFormalParameterElement &&
          element.field == indexFieldElement) {
        return _Parameter(i, element);
      }
    }
    return null;
  }

  /// Return a representation of all of the constructors declared by the
  /// [classDeclaration], or `null` if the class can't be converted.
  ///
  /// The [classElement] must be the element declared by the [classDeclaration].
  static _Constructors? _validateConstructors(
    ClassDeclaration classDeclaration,
    ClassElement classElement,
  ) {
    if (classElement.constructors.any(
      (c) => c.isPublic && classElement.isPublic,
    )) {
      return null;
    }
    if (classElement.constructors.any((c) => !c.isFactory && !c.isConst)) {
      return null;
    }

    var constructorMap = <ConstructorElement, _Constructor>{};
    for (var member
        in classDeclaration.members2.whereType<ConstructorDeclaration>()) {
      var constructor = member.declaredFragment?.element;
      if (constructor is! ConstructorElement) return null;

      constructorMap[constructor] = _Constructor(
        member,
        member.parameters,
        constructor,
      );
    }
    if (classDeclaration.namePart
        case PrimaryConstructorDeclaration constructor) {
      var constructorElement = constructor.declaredFragment?.element;
      if (constructorElement == null) return null;
      constructorMap[constructorElement] = _Constructor(
        constructor,
        constructor.formalParameters,
        constructorElement,
      );
    }
    return constructorMap;
  }

  /// Return a representation of all of the fields declared by the
  /// [classDeclaration], or `null` if the class can't be converted.
  ///
  /// The [classElement] must be the element declared by the [classDeclaration].
  static (List<_ConstantField> fieldsToConvert, _Field? indexField)?
  _validateFields(
    ClassDeclaration classDeclaration,
    ClassElement classElement, {
    required bool strictCasts,
  }) {
    var potentialFieldsToConvert = <DartObject, List<_ConstantField>>{};
    _Field? indexFieldData;

    // First, look through variable declarations.
    for (var member in classDeclaration.members2) {
      if (member is! FieldDeclaration) continue;

      var fields = member.fields.variables;
      if (member.isStatic) {
        for (var field in fields) {
          var fieldElement = field.declaredFragment?.element;
          if (fieldElement is! FieldElement) continue;

          var fieldType = fieldElement.type;
          // The field can be converted to be an enum constant if it
          // - is a const field,
          // - has a type equal to the type of the class, and
          // - is initialized by an instance creation expression in this class.
          if (fieldElement.isConst &&
              fieldType is InterfaceType &&
              fieldType.element == classElement) {
            var initializer = field.initializer;
            if (initializer is! InstanceCreationExpression) continue;

            var constructorElement = initializer.constructorName.element;
            if (constructorElement != null &&
                !constructorElement.isFactory &&
                constructorElement.enclosingElement == classElement) {
              var fieldValue = fieldElement.computeConstantValue();
              if (fieldValue == null) continue;

              // Too many constants in the field declaration.
              if (fields.length != 1) return null;
              potentialFieldsToConvert
                  .putIfAbsent(fieldValue, () => [])
                  .add(
                    _ConstantField(
                      fieldElement,
                      field,
                      member,
                      initializer,
                      constructorElement,
                      fieldValue.getField('index')?.toIntValue() ?? -1,
                    ),
                  );
            }
          }
        }
      } else {
        for (var field in fields) {
          if (!field.isFinal) return null;

          var fieldElement = field.declaredFragment?.element;
          if (fieldElement is! FieldElement) continue;

          if (fieldElement.name == 'index' && fieldElement.type.isDartCoreInt) {
            indexFieldData = _FieldDeclaredInVariableDeclaration(
              fieldElement,
              field,
              member,
            );
          }
        }
      }
    }

    // Second, look through the primary constructor.
    if (classDeclaration.namePart
        case PrimaryConstructorDeclaration primaryConstructor) {
      for (var parameter in primaryConstructor.formalParameters.parameters) {
        var element = parameter.declaredFragment?.element;
        if (element is! FieldFormalParameterElement || !element.isDeclaring) {
          continue;
        }
        if (element.field case FieldElement fieldElement) {
          if (!fieldElement.isFinal) return null;

          if (fieldElement.name == 'index' && fieldElement.type.isDartCoreInt) {
            indexFieldData = _FieldDeclaredInPrimaryConstructor(
              fieldElement,
              primaryConstructor.formalParameters,
              parameter,
            );
          }
        }
      }
    }

    var fieldsToConvert = <_ConstantField>[];
    for (var list in potentialFieldsToConvert.values) {
      if (list.length == 1) {
        fieldsToConvert.add(list[0]);
      } else {
        // TODO(brianwilkerson): We could potentially handle the case where
        //  there's only one non-deprecated field in the list. We'd need to
        //  change the return type for this method so that we could return two
        //  lists: the list of fields to convert and the list of fields whose
        //  initializer needs to be updated to refer to the constant.
        return null;
      }
    }
    return (fieldsToConvert, indexFieldData);
  }

  /// Return `true` if the [classDeclaration] does not contain any methods that
  /// prevent it from being converted.
  static bool _validateMethods(ClassDeclaration classDeclaration) {
    for (var member in classDeclaration.members2) {
      if (member is MethodDeclaration) {
        var name = member.name.lexeme;
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
    : fieldsToConvert = fieldsToConvert
          .map((field) => field.declaration)
          .toList();

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!inConstantDeclaration) {
      if (invokesGenerativeConstructor(node)) {
        throw _CannotConvertException(
          'Constructor used outside constant initializer',
        );
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

/// Data pertaining to a field of interest in the class being converted.
sealed class _Field {
  /// The element representing the field.
  FieldElement get element;
}

/// Data pertaining to a field, declared in a primary constructor.
class _FieldDeclaredInPrimaryConstructor implements _Field {
  @override
  final FieldElement element;

  /// The parameter list of the primary constructor.
  final FormalParameterList parameterList;

  /// The parameter that corresponds to [element].
  final FormalParameter parameter;

  _FieldDeclaredInPrimaryConstructor(
    this.element,
    this.parameterList,
    this.parameter,
  );
}

/// Data pertaining to a field, declared in a variable declaration.
class _FieldDeclaredInVariableDeclaration implements _Field {
  @override
  final FieldElement element;

  /// The declaration of the field.
  final VariableDeclaration declaration;

  /// The field declaration containing the [declaration].
  final FieldDeclaration fieldDeclaration;

  _FieldDeclaredInVariableDeclaration(
    this.element,
    this.declaration,
    this.fieldDeclaration,
  );
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
    var element = node.declaredFragment?.element;
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
        'Constructor used outside class being converted',
      );
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
  final FormalParameterElement element;

  _Parameter(this.index, this.element);

  /// Return the expression representing the argument associated with this
  /// parameter, or `null` if there is no such argument.
  Expression? getArgument(NodeList<Expression> arguments) {
    return arguments.firstWhereOrNull(
      (argument) => argument.correspondingParameter == element,
    );
  }
}
