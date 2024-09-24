// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/invokes_super_self.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/augmentation.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:collection/collection.dart';

class ElementBuilder extends ThrowingAstVisitor<void> {
  final LibraryBuilder _libraryBuilder;
  final CompilationUnitElementImpl _unitElement;

  var _exportDirectiveIndex = 0;
  var _importDirectiveIndex = 0;
  var _partDirectiveIndex = 0;

  _EnclosingContext _enclosingContext;
  var _nextUnnamedExtensionId = 0;

  ElementBuilder({
    required LibraryBuilder libraryBuilder,
    required Reference unitReference,
    required CompilationUnitElementImpl unitElement,
  })  : _libraryBuilder = libraryBuilder,
        _unitElement = unitElement,
        _enclosingContext = _EnclosingContext(unitReference, unitElement);

  Linker get _linker => _libraryBuilder.linker;

  void buildDeclarationElements(CompilationUnit unit) {
    _visitPropertyFirst<TopLevelVariableDeclaration>(unit.declarations);
    _unitElement.accessors = _enclosingContext.propertyAccessors;
    _unitElement.classes = _enclosingContext.classes;
    _unitElement.enums = _enclosingContext.enums;
    _unitElement.extensions = _enclosingContext.extensions;
    _unitElement.extensionTypes = _enclosingContext.extensionTypes;
    _unitElement.functions = _enclosingContext.functions;
    _unitElement.mixins = _enclosingContext.mixins;
    _unitElement.topLevelVariables = _enclosingContext.topLevelVariables;
    _unitElement.typeAliases = _enclosingContext.typeAliases;
  }

  /// Builds exports and imports, metadata into [_unitElement].
  void buildDirectiveElements(CompilationUnitImpl unit) {
    unit.directives.accept(this);
  }

  /// Updates metadata and documentation for [_libraryBuilder].
  ///
  /// This method must be invoked after [buildDirectiveElements].
  void buildLibraryMetadata(CompilationUnitImpl unit) {
    var libraryElement = _libraryBuilder.element;

    // Prefer the actual library directive.
    var libraryDirective =
        unit.directives.whereType<LibraryDirectiveImpl>().firstOrNull;
    if (libraryDirective != null) {
      libraryDirective.element = libraryElement;
      libraryElement.documentationComment = getCommentNodeRawText(
        libraryDirective.documentationComment,
      );
      libraryElement.metadata = _buildAnnotations(libraryDirective.metadata);
      return;
    }

    // Otherwise use the first directive.
    var firstDirective = unit.directives.firstOrNull;
    if (firstDirective != null) {
      libraryElement.documentationComment = getCommentNodeRawText(
        firstDirective.documentationComment,
      );
      var firstDirectiveMetadata = firstDirective.element?.metadata;
      if (firstDirectiveMetadata != null) {
        libraryElement.metadata = firstDirectiveMetadata;
      }
    }
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = ClassElementImpl(name, nameToken.offset);
    element.isAbstract = node.abstractKeyword != null;
    element.isAugmentation = node.augmentKeyword != null;
    element.isBase = node.baseKeyword != null;
    element.isFinal = node.finalKeyword != null;
    element.isInterface = node.interfaceKeyword != null;
    element.isMacro = node.macroKeyword != null;
    element.isMixinClass = node.mixinKeyword != null;
    if (node.sealedKeyword != null) {
      element.isAbstract = true;
      element.isSealed = true;
    }
    element.hasExtendsClause = node.extendsClause != null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addClass(name, element);
    if (!element.isAugmentation) {
      _libraryBuilder.declare(name, reference);
    }

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    node.extendsClause?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
    _buildClass(node);

    _libraryBuilder.updateAugmentationTarget(name, element);

    if (element.augmentationTarget != null) {
      switch (_libraryBuilder.getAugmentedBuilder(name)) {
        case AugmentedClassDeclarationBuilder builder:
          builder.augment(element);
      }
    } else {
      _libraryBuilder.putAugmentedBuilder(
        name,
        AugmentedClassDeclarationBuilder(
          declaration: element,
        ),
      );
    }
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = ClassElementImpl(name, nameToken.offset);
    element.isAbstract = node.abstractKeyword != null;
    element.isBase = node.baseKeyword != null;
    element.isFinal = node.finalKeyword != null;
    element.isInterface = node.interfaceKeyword != null;
    element.isMacro = node.macroKeyword != null;
    element.isMixinApplication = true;
    element.isMixinClass = node.mixinKeyword != null;
    if (node.sealedKeyword != null) {
      element.isAbstract = true;
      element.isSealed = true;
    }
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addClass(name, element);
    if (!element.isAugmentation) {
      _libraryBuilder.declare(name, reference);
    }

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    node.superclass.accept(this);
    node.withClause.accept(this);
    node.implementsClause?.accept(this);
  }

  @override
  void visitConstructorDeclaration(
    covariant ConstructorDeclarationImpl node,
  ) {
    var nameNode = node.name ?? node.returnType;
    var name = node.name?.lexeme ?? '';
    if (name == 'new') {
      // A constructor declared as `C.new` is unnamed, and is modeled as such.
      name = '';
    }
    var nameOffset = nameNode.offset;

    var element = ConstructorElementImpl(name, nameOffset);
    element.isAugmentation = node.augmentKeyword != null;
    element.isConst = node.constKeyword != null;
    element.isExternal = node.externalKeyword != null;
    element.isFactory = node.factoryKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    element.nameEnd = nameNode.end;
    element.periodOffset = node.period?.offset;
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    if (element.isConst || element.isFactory) {
      element.constantInitializers = node.initializers;
    }

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addConstructor(element);
    _buildExecutableElementChildren(
      reference: reference,
      element: element,
      formalParameters: node.parameters,
    );
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    var nameNode = node.name;
    var name = nameNode.lexeme;
    var nameOffset = nameNode.offset;

    var element = EnumElementImpl(name, nameOffset);
    element.isAugmentation = node.augmentKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addEnum(name, element);
    if (!element.isAugmentation) {
      _libraryBuilder.declare(name, reference);
    }

    _libraryBuilder.updateAugmentationTarget(name, element);

    var holder = _EnclosingContext(
      reference,
      element,
      constFieldsForFinalInstance: true,
    );

    // Build fields for all enum constants.
    var constants = node.constants;
    var valuesElements = <SimpleIdentifierImpl>[];
    var valuesNames = <String>{};
    for (var i = 0; i < constants.length; ++i) {
      var constant = constants[i];
      var name = constant.name.lexeme;
      var field = ConstFieldElementImpl(name, constant.name.offset)
        ..hasImplicitType = true
        ..hasInitializer = true
        ..isAugmentation = constant.augmentKeyword != null
        ..isConst = true
        ..isEnumConstant = true
        ..isStatic = true;
      _setCodeRange(field, constant);
      _setDocumentation(field, constant);
      field.metadata = _buildAnnotationsWithUnit(
        _unitElement,
        constant.metadata,
      );

      var constructorSelector = constant.arguments?.constructorSelector;
      var constructorName = constructorSelector?.name.name;

      var initializer = InstanceCreationExpressionImpl(
        keyword: null,
        constructorName: ConstructorNameImpl(
          type: NamedTypeImpl(
            importPrefix: null,
            name2: StringToken(TokenType.STRING, element.name, -1),
            typeArguments: constant.arguments?.typeArguments,
            question: null,
          ),
          period: constructorName != null ? Tokens.period() : null,
          name: constructorName != null
              ? SimpleIdentifierImpl(
                  StringToken(TokenType.STRING, constructorName, -1),
                )
              : null,
        ),
        argumentList: ArgumentListImpl(
          leftParenthesis: Tokens.openParenthesis(),
          arguments: [
            ...?constant.arguments?.argumentList.arguments,
          ],
          rightParenthesis: Tokens.closeParenthesis(),
        ),
        typeArguments: null,
      );

      var variableDeclaration = VariableDeclarationImpl(
        name: StringToken(TokenType.STRING, name, -1),
        equals: Tokens.eq(),
        initializer: initializer,
      );
      constant.declaredElement = field;
      variableDeclaration.declaredElement = field;
      VariableDeclarationListImpl(
        comment: null,
        metadata: null,
        lateKeyword: null,
        keyword: null,
        type: null,
        variables: [variableDeclaration],
      );
      _linker.elementNodes[field] = variableDeclaration;

      field.constantInitializer = initializer;
      holder.addNonSyntheticField(field);
      valuesElements.add(
        SimpleIdentifierImpl(
          StringToken(TokenType.STRING, name, -1),
        ),
      );
      valuesNames.add(name);
    }

    // Build the 'values' field.
    if (element.augmentationTarget == null) {
      var valuesField = ConstFieldElementImpl('values', -1)
        ..isConst = true
        ..isStatic = true
        ..isSynthetic = true;
      var initializer = ListLiteralImpl(
        constKeyword: null,
        typeArguments: null,
        leftBracket: Tokens.openSquareBracket(),
        elements: valuesElements,
        rightBracket: Tokens.closeSquareBracket(),
      );
      valuesField.constantInitializer = initializer;

      var variableDeclaration = VariableDeclarationImpl(
        name: StringToken(TokenType.STRING, 'values', -1),
        equals: Tokens.eq(),
        initializer: initializer,
      );
      var valuesTypeNode = NamedTypeImpl(
        importPrefix: null,
        name2: StringToken(TokenType.STRING, 'List', -1),
        typeArguments: TypeArgumentListImpl(
          leftBracket: Tokens.lt(),
          arguments: [
            NamedTypeImpl(
              importPrefix: null,
              name2: StringToken(TokenType.STRING, element.name, -1),
              typeArguments: null,
              question: null,
            )..element2 = element.asElement2,
          ],
          rightBracket: Tokens.gt(),
        ),
        question: null,
      );
      VariableDeclarationListImpl(
        comment: null,
        metadata: null,
        lateKeyword: null,
        keyword: Tokens.const_(),
        variables: [variableDeclaration],
        type: valuesTypeNode,
      );
      _linker.elementNodes[valuesField] = variableDeclaration;

      holder.addNonSyntheticField(valuesField);

      _libraryBuilder.implicitEnumNodes[element] = ImplicitEnumNodes(
        element: element,
        valuesTypeNode: valuesTypeNode,
        valuesNode: variableDeclaration,
        valuesElement: valuesField,
        valuesNames: valuesNames,
        valuesInitializer: initializer,
      );
    } else {
      var declaration = element.augmented.declaration;
      var implicitNodes = _libraryBuilder.implicitEnumNodes[declaration];
      if (implicitNodes != null) {
        var mergedValuesElements = [
          ...implicitNodes.valuesInitializer.elements,
          for (var value in valuesElements)
            if (implicitNodes.valuesNames.add(value.name)) value,
        ];
        var initializer = ListLiteralImpl(
          constKeyword: null,
          typeArguments: null,
          leftBracket: Tokens.openSquareBracket(),
          elements: mergedValuesElements,
          rightBracket: Tokens.closeSquareBracket(),
        );
        implicitNodes.valuesElement.constantInitializer = initializer;
        implicitNodes.valuesNode.initializer = initializer;
        implicitNodes.valuesInitializer = initializer;
      }
    }

    node.withClause?.accept(this);
    node.implementsClause?.accept(this);

    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });

    element.accessors = holder.propertyAccessors;
    element.constructors = holder.constructors;
    element.fields = holder.fields;
    element.methods = holder.methods;
    element.typeParameters = holder.typeParameters;

    if (element.augmentationTarget != null) {
      var builder = _libraryBuilder.getAugmentedBuilder(name);
      if (builder is AugmentedEnumDeclarationBuilder) {
        builder.augment(element);
      }
    } else {
      _libraryBuilder.putAugmentedBuilder(
        name,
        AugmentedEnumDeclarationBuilder(
          declaration: element,
        ),
      );
    }
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    var index = _exportDirectiveIndex++;
    var exportElement = _unitElement.libraryExports[index];
    exportElement.metadata = _buildAnnotations(node.metadata);
    node.element = exportElement;
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    node.superclass.accept(this);
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken?.lexeme;
    var nameOffset = nameToken?.offset ?? -1;

    var element = ExtensionElementImpl(name, nameOffset);
    element.isAugmentation = node.augmentKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var refName = name ?? '${_nextUnnamedExtensionId++}';
    var reference = _enclosingContext.addExtension(refName, element);

    if (name != null) {
      if (!element.isAugmentation) {
        _libraryBuilder.declare(name, reference);
      }
    }

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    // TODO(scheglov): don't create a duplicate
    {
      var holder = _EnclosingContext(reference, element);
      _withEnclosing(holder, () {
        _visitPropertyFirst<FieldDeclaration>(node.members);
      });
      element.accessors = holder.propertyAccessors;
      element.fields = holder.fields;
      element.methods = holder.methods;
    }

    node.onClause?.accept(this);

    if (name != null) {
      _libraryBuilder.updateAugmentationTarget(name, element);

      if (element.augmentationTarget != null) {
        var builder = _libraryBuilder.getAugmentedBuilder(name);
        if (builder is AugmentedExtensionDeclarationBuilder) {
          builder.augment(element);
        }
      } else {
        _libraryBuilder.putAugmentedBuilder(
          name,
          AugmentedExtensionDeclarationBuilder(
            declaration: element,
          ),
        );
      }
    }
  }

  @override
  void visitExtensionOnClause(ExtensionOnClause node) {
    node.extendedType.accept(this);
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = ExtensionTypeElementImpl(name, nameToken.offset);
    element.isAugmentation = node.augmentKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addExtensionType(name, element);
    if (!element.isAugmentation) {
      _libraryBuilder.declare(name, reference);
    }

    element.isAugmentationChainStart = true;
    _libraryBuilder.updateAugmentationTarget(name, element);

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      _builtRepresentationDeclaration(
        extensionNode: node,
        representation: node.representation,
        extensionElement: element,
      );
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });

    element.accessors = holder.propertyAccessors;
    element.constructors = holder.constructors;
    element.fields = holder.fields;
    element.methods = holder.methods;
    element.typeParameters = holder.typeParameters;

    var executables = const <ExecutableElementImpl>[]
        .followedBy(element.accessors)
        .followedBy(element.methods);
    for (var executable in executables) {
      executable.isExtensionTypeMember = true;
    }

    node.implementsClause?.accept(this);

    // TODO(scheglov): We cannot do this anymore.
    // Not for class augmentations, not for classes.
    _resolveConstructorFieldFormals(element);

    if (element.augmentationTarget != null) {
      var builder = _libraryBuilder.getAugmentedBuilder(name);
      if (builder is AugmentedExtensionTypeDeclarationBuilder) {
        builder.augment(element);
      }
    } else {
      _libraryBuilder.putAugmentedBuilder(
        name,
        AugmentedExtensionTypeDeclarationBuilder(
          declaration: element,
        ),
      );
    }
  }

  @override
  void visitFieldDeclaration(
    covariant FieldDeclarationImpl node,
  ) {
    var metadata = _buildAnnotations(node.metadata);
    for (var variable in node.fields.variables) {
      var nameToken = variable.name;
      var name = nameToken.lexeme;
      var nameOffset = nameToken.offset;

      var element = FieldElementImpl(name, nameOffset);
      if (variable.initializer case var initializer?) {
        if (node.fields.isConst) {
          element = ConstFieldElementImpl(name, nameOffset)
            ..constantInitializer = initializer;
        } else if (_enclosingContext.constFieldsForFinalInstance) {
          if (node.fields.isFinal && !node.isStatic) {
            var constElement = ConstFieldElementImpl(name, nameOffset)
              ..constantInitializer = initializer;
            element = constElement;
            _libraryBuilder.finalInstanceFields.add(constElement);
          }
        }
      }

      element.hasInitializer = variable.initializer != null;
      element.isAbstract = node.abstractKeyword != null;
      element.isAugmentation = node.augmentKeyword != null;
      element.isConst = node.fields.isConst;
      element.isCovariant = node.covariantKeyword != null;
      element.isExternal = node.externalKeyword != null;
      element.isFinal = node.fields.isFinal;
      element.isLate = node.fields.isLate;
      element.isStatic = node.isStatic;
      element.metadata = metadata;
      _setCodeRange(element, variable);
      _setDocumentation(element, node);

      if (node.fields.type == null) {
        element.hasImplicitType = true;
      }

      _enclosingContext.addNonSyntheticField(element);

      _linker.elementNodes[element] = variable;
      variable.declaredElement = element;
    }
    _buildType(node.fields.type);
  }

  @override
  void visitFieldFormalParameter(
    covariant FieldFormalParameterImpl node,
  ) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

    ParameterElementImpl element;
    var parent = node.parent;
    if (parent is DefaultFormalParameterImpl) {
      element = DefaultFieldFormalParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[element] = parent;
      var refName = node.isNamed ? name : null;
      _enclosingContext.addParameter(refName, element);
    } else {
      element = FieldFormalParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      );
      _linker.elementNodes[element] = node;
      _enclosingContext.addParameter(null, element);
    }
    element.hasImplicitType = node.type == null && node.parameters == null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;

    // TODO(scheglov): check that we don't set reference for parameters
    var fakeReference = Reference.root();
    var holder = _EnclosingContext(fakeReference, element);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      if (formalParameters != null) {
        formalParameters.accept(this);
        element.parameters = holder.parameters;
      }

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.type);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

    var functionExpression = node.functionExpression;
    var body = functionExpression.body;

    Reference reference;
    ExecutableElementImpl executableElement;
    if (node.isGetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isAugmentation = node.augmentKeyword != null;
      element.isGetter = true;
      element.isStatic = true;

      reference = _enclosingContext.addGetter(name, element);
      executableElement = element;

      if (!element.isAugmentation) {
        _buildSyntheticVariable(name: name, accessorElement: element);
      }

      _libraryBuilder.topVariables.addAccessor(element);
    } else if (node.isSetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isAugmentation = node.augmentKeyword != null;
      element.isSetter = true;
      element.isStatic = true;

      reference = _enclosingContext.addSetter(name, element);
      executableElement = element;

      if (!element.isAugmentation) {
        _buildSyntheticVariable(name: name, accessorElement: element);
      }

      _libraryBuilder.topVariables.addAccessor(element);
    } else {
      var element = FunctionElementImpl(name, nameOffset);
      element.isAugmentation = node.augmentKeyword != null;
      element.isStatic = true;
      reference = _enclosingContext.addFunction(name, element);
      executableElement = element;

      _libraryBuilder.updateAugmentationTarget(name, element);
    }

    executableElement.hasImplicitReturnType = node.returnType == null;
    executableElement.isAsynchronous = body.isAsynchronous;
    executableElement.isExternal = node.externalKeyword != null;
    executableElement.isGenerator = body.isGenerator;
    executableElement.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(executableElement, node);
    _setDocumentation(executableElement, node);

    node.declaredElement = executableElement;
    _linker.elementNodes[executableElement] = node;

    _buildExecutableElementChildren(
      reference: reference,
      element: executableElement,
      formalParameters: functionExpression.parameters,
      typeParameters: functionExpression.typeParameters,
    );

    var getterOrSetterName = node.isSetter ? '$name=' : name;

    if (!executableElement.isAugmentation) {
      _libraryBuilder.declare(getterOrSetterName, reference);
    }

    _buildType(node.returnType);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = TypeAliasElementImpl(name, nameToken.offset);
    element.isFunctionTypeAliasBased = true;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addTypeAlias(name, element);
    _libraryBuilder.declare(name, reference);

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.returnType?.accept(this);
      node.parameters.accept(this);
    });

    var aliasedElement = GenericFunctionTypeElementImpl.forOffset(
      nameToken.offset,
    );
    aliasedElement.parameters = holder.parameters;

    element.typeParameters = holder.typeParameters;
    element.aliasedElement = aliasedElement;
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

    ParameterElementImpl element;
    var parent = node.parent;
    if (parent is DefaultFormalParameterImpl) {
      element = DefaultParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[element] = parent;
    } else {
      element = ParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      );
      _linker.elementNodes[element] = node;
    }
    element.isExplicitlyCovariant = node.covariantKeyword != null;
    element.isFinal = node.isFinal;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;
    var refName = node.isNamed ? name : null;
    _enclosingContext.addParameter(refName, element);

    var fakeReference = Reference.root();
    var holder = _EnclosingContext(fakeReference, element);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      formalParameters.accept(this);
      element.parameters = holder.parameters;

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.returnType);
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    var element = GenericFunctionTypeElementImpl.forOffset(node.offset);
    _unitElement.encloseElement(element);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var fakeReference = Reference.root();
    var holder = _EnclosingContext(fakeReference, element);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      formalParameters.accept(this);
      element.parameters = holder.parameters;

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.returnType);
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = TypeAliasElementImpl(name, nameToken.offset);
    element.isAugmentation = node.augmentKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addTypeAlias(name, element);
    if (!element.isAugmentation) {
      _libraryBuilder.declare(name, reference);
    }

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
    });
    element.typeParameters = holder.typeParameters;

    var typeNode = node.type;
    typeNode.accept(this);

    if (typeNode is GenericFunctionTypeImpl) {
      element.aliasedElement =
          typeNode.declaredElement as GenericFunctionTypeElementImpl;
    }

    _libraryBuilder.updateAugmentationTarget(name, element);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    node.interfaces.accept(this);
  }

  @override
  void visitImportDirective(covariant ImportDirectiveImpl node) {
    var index = _importDirectiveIndex++;
    var importElement = _unitElement.libraryImports[index];
    importElement.metadata = _buildAnnotations(node.metadata);
    node.element = importElement;
  }

  @override
  void visitLibraryDirective(covariant LibraryDirectiveImpl node) {}

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

    Reference reference;
    ExecutableElementImpl executableElement;
    if (node.isGetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isAbstract = node.isAbstract;
      element.isAugmentation = node.augmentKeyword != null;
      element.isGetter = true;
      element.isStatic = node.isStatic;

      // `class Enum {}` in `dart:core` declares `int get index` as abstract.
      // But the specification says that practically a different class
      // implementing `Enum` is used as a superclass, so `index` should be
      // considered to have non-abstract implementation.
      if (_enclosingContext.isDartCoreEnum && name == 'index') {
        element.isAbstract = false;
      }

      reference = _enclosingContext.addGetter(name, element);
      executableElement = element;

      _buildSyntheticVariable(name: name, accessorElement: element);
    } else if (node.isSetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isAbstract = node.isAbstract;
      element.isAugmentation = node.augmentKeyword != null;
      element.isSetter = true;
      element.isStatic = node.isStatic;

      reference = _enclosingContext.addSetter(name, element);
      executableElement = element;

      _buildSyntheticVariable(name: name, accessorElement: element);
    } else {
      if (name == '-') {
        var parameters = node.parameters;
        if (parameters != null && parameters.parameters.isEmpty) {
          name = 'unary-';
        }
      }

      var element = MethodElementImpl(name, nameOffset);
      element.isAbstract = node.isAbstract;
      element.isAugmentation = node.augmentKeyword != null;
      element.isStatic = node.isStatic;

      reference = _enclosingContext.addMethod(name, element);
      executableElement = element;
    }
    executableElement.hasImplicitReturnType = node.returnType == null;
    executableElement.invokesSuperSelf = node.invokesSuperSelf;
    executableElement.isAsynchronous = node.body.isAsynchronous;
    executableElement.isExternal =
        node.externalKeyword != null || node.body is NativeFunctionBody;
    executableElement.isGenerator = node.body.isGenerator;
    executableElement.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(executableElement, node);
    _setDocumentation(executableElement, node);

    node.declaredElement = executableElement;
    _linker.elementNodes[executableElement] = node;

    _buildExecutableElementChildren(
      reference: reference,
      element: executableElement,
      formalParameters: node.parameters,
      typeParameters: node.typeParameters,
    );

    _buildType(node.returnType);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = MixinElementImpl(name, nameToken.offset);
    element.isAugmentation = node.augmentKeyword != null;
    element.isBase = node.baseKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addMixin(name, element);
    if (!element.isAugmentation) {
      _libraryBuilder.declare(name, reference);
    }

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    node.onClause?.accept(this);
    node.implementsClause?.accept(this);
    _buildMixin(node);

    _libraryBuilder.updateAugmentationTarget(name, element);

    if (element.augmentationTarget != null) {
      switch (_libraryBuilder.getAugmentedBuilder(name)) {
        case AugmentedMixinDeclarationBuilder builder:
          builder.augment(element);
      }
    } else {
      _libraryBuilder.putAugmentedBuilder(
        name,
        AugmentedMixinDeclarationBuilder(
          declaration: element,
        ),
      );
    }
  }

  @override
  void visitMixinOnClause(MixinOnClause node) {
    node.superclassConstraints.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    node.typeArguments?.accept(this);
  }

  @override
  void visitPartDirective(PartDirective node) {
    var index = _partDirectiveIndex++;
    var partElement = _unitElement.parts[index];
    partElement.metadata = _buildAnnotations(node.metadata);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    var libraryElement = _libraryBuilder.element;
    libraryElement.hasPartOfDirective = true;
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    node.positionalFields.accept(this);
    node.namedFields?.accept(this);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    node.type.accept(this);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    node.fields.accept(this);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    node.type.accept(this);
  }

  @override
  void visitSimpleFormalParameter(
    covariant SimpleFormalParameterImpl node,
  ) {
    var nameToken = node.name;
    var name = nameToken?.lexeme ?? '';
    var nameOffset = nameToken?.offset ?? -1;

    ParameterElementImpl element;
    var parent = node.parent;
    if (parent is DefaultFormalParameterImpl &&
        _enclosingContext.hasDefaultFormalParameters) {
      element = DefaultParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[element] = parent;
      var refName = node.isNamed ? name : null;
      _enclosingContext.addParameter(refName, element);
    } else {
      element = ParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      );
      _linker.elementNodes[element] = node;
      _enclosingContext.addParameter(null, element);
    }

    element.hasImplicitType = node.type == null;
    element.isExplicitlyCovariant = node.covariantKeyword != null;
    element.isFinal = node.isFinal;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;

    _buildType(node.type);
  }

  @override
  void visitSuperFormalParameter(
    covariant SuperFormalParameterImpl node,
  ) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

    SuperFormalParameterElementImpl element;
    var parent = node.parent;
    if (parent is DefaultFormalParameterImpl) {
      element = DefaultSuperFormalParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[element] = parent;
      var refName = node.isNamed ? name : null;
      _enclosingContext.addParameter(refName, element);
    } else {
      element = SuperFormalParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      );
      _linker.elementNodes[element] = node;
      _enclosingContext.addParameter(null, element);
    }
    element.hasImplicitType = node.type == null && node.parameters == null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;

    // TODO(scheglov): check that we don't set reference for parameters
    var fakeReference = Reference.root();
    var holder = _EnclosingContext(fakeReference, element);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      if (formalParameters != null) {
        formalParameters.accept(this);
        element.parameters = holder.parameters;
      }

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.type);
  }

  @override
  void visitTopLevelVariableDeclaration(
    covariant TopLevelVariableDeclarationImpl node,
  ) {
    var enclosingRef = _enclosingContext.reference;

    var metadata = _buildAnnotations(node.metadata);
    for (var variable in node.variables.variables) {
      var nameToken = variable.name;
      var name = nameToken.lexeme;
      var nameOffset = nameToken.offset;

      TopLevelVariableElementImpl element;
      if (node.variables.isConst) {
        element = ConstTopLevelVariableElementImpl(name, nameOffset)
          ..constantInitializer = variable.initializer;
      } else {
        element = TopLevelVariableElementImpl(name, nameOffset);
      }

      element.hasInitializer = variable.initializer != null;
      element.isAugmentation = node.augmentKeyword != null;
      element.isConst = node.variables.isConst;
      element.isExternal = node.externalKeyword != null;
      element.isFinal = node.variables.isFinal;
      element.isLate = node.variables.isLate;
      element.metadata = metadata;
      _setCodeRange(element, variable);
      _setDocumentation(element, node);

      if (node.variables.type == null) {
        element.hasImplicitType = true;
      }

      {
        var ref = enclosingRef.getChild('@getter').addChild(name);
        var getter = element.createImplicitGetter(ref);
        _enclosingContext.addPropertyAccessorSynthetic(getter);
        _libraryBuilder.declare(name, ref);
      }

      if (element.hasSetter) {
        var ref = enclosingRef.getChild('@setter').addChild(name);
        var setter = element.createImplicitSetter(ref);
        _enclosingContext.addPropertyAccessorSynthetic(setter);
        _libraryBuilder.declare('$name=', ref);
      }

      _linker.elementNodes[element] = variable;
      _enclosingContext.addTopLevelVariable(name, element);
      variable.declaredElement = element;

      _libraryBuilder.topVariables.addVariable(element);
    }

    _buildType(node.variables.type);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    node.arguments.accept(this);
  }

  @override
  void visitTypeParameter(covariant TypeParameterImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = TypeParameterElementImpl(name, nameToken.offset);
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;
    _enclosingContext.addTypeParameter(name, element);

    _buildType(node.bound);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept(this);
  }

  @override
  void visitWithClause(WithClause node) {
    node.mixinTypes.accept(this);
  }

  List<ElementAnnotationImpl> _buildAnnotations(List<Annotation> nodeList) {
    return _buildAnnotationsWithUnit(_unitElement, nodeList);
  }

  void _buildClass(ClassDeclaration node) {
    var element = node.declaredElement as ClassElementImpl;
    // TODO(scheglov): don't create a duplicate
    var holder = _EnclosingContext(element.reference!, element,
        constFieldsForFinalInstance: true);
    _withEnclosing(holder, () {
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });

    element.accessors = holder.propertyAccessors;
    element.constructors = holder.constructors;
    element.fields = holder.fields;
    element.methods = holder.methods;
  }

  void _buildExecutableElementChildren({
    required Reference reference,
    required ExecutableElementImpl element,
    FormalParameterList? formalParameters,
    TypeParameterList? typeParameters,
  }) {
    var holder = _EnclosingContext(
      reference,
      element,
      hasDefaultFormalParameters: true,
    );
    _withEnclosing(holder, () {
      if (formalParameters != null) {
        formalParameters.accept(this);
        element.parameters = holder.parameters;
      }
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });
  }

  void _buildMixin(MixinDeclaration node) {
    var element = node.declaredElement as MixinElementImpl;
    // TODO(scheglov): don't create a duplicate
    var holder = _EnclosingContext(element.reference!, element);
    _withEnclosing(holder, () {
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });

    element.accessors = holder.propertyAccessors;
    element.fields = holder.fields;
    element.methods = holder.methods;
  }

  void _buildSyntheticVariable({
    required String name,
    required PropertyAccessorElementImpl accessorElement,
  }) {
    if (accessorElement.isAugmentation) {
      return;
    }

    var enclosingRef = _enclosingContext.reference;
    var enclosingElement = _enclosingContext.element;

    bool canUseExisting(PropertyInducingElement property) {
      return property.isSynthetic ||
          accessorElement.isSetter && property.setter == null;
    }

    PropertyInducingElementImpl? property;
    if (enclosingElement is CompilationUnitElement) {
      // Try to find the variable to attach the accessor.
      var containerRef = enclosingRef.getChild('@topLevelVariable');
      for (var reference in containerRef.getChildrenByName(name)) {
        var existing = reference.element;
        if (existing is TopLevelVariableElementImpl &&
            canUseExisting(existing)) {
          property = existing;
          break;
        }
      }

      // If no variable, add a new one.
      // In error cases could be a duplicate.
      if (property == null) {
        var reference = containerRef.addChild(name);
        var variable = property = TopLevelVariableElementImpl(name, -1)
          ..isSynthetic = true;
        _enclosingContext.addTopLevelVariableSynthetic(reference, variable);
      }
    } else {
      // Try to find the variable to attach the accessor.
      var containerRef = enclosingRef.getChild('@field');
      for (var reference in containerRef.getChildrenByName(name)) {
        var existing = reference.element;
        if (existing is FieldElementImpl && canUseExisting(existing)) {
          property = existing;
          break;
        }
      }

      // If no variable, add a new one.
      // In error cases could be a duplicate.
      if (property == null) {
        var reference = containerRef.addChild(name);
        var field = property = FieldElementImpl(name, -1)
          ..isStatic = accessorElement.isStatic
          ..isSynthetic = true;
        _enclosingContext.addFieldSynthetic(reference, field);
      }
    }

    accessorElement.variable2 = property;
    if (accessorElement.isGetter) {
      property.getter = accessorElement;
    } else {
      property.setter = accessorElement;
    }
  }

  // TODO(scheglov): Maybe inline?
  void _buildType(TypeAnnotation? node) {
    node?.accept(this);
  }

  void _builtRepresentationDeclaration({
    required ExtensionTypeElementImpl extensionElement,
    required ExtensionTypeDeclarationImpl extensionNode,
    required RepresentationDeclarationImpl representation,
  }) {
    if (extensionElement.augmentationTarget != null) {
      return;
    }

    var fieldNameToken = representation.fieldName;
    var fieldName = fieldNameToken.lexeme.ifNotEmptyOrElse('<empty>');

    var fieldElement = FieldElementImpl(
      fieldName,
      fieldNameToken.offset,
    );
    fieldElement.isFinal = true;
    fieldElement.metadata = _buildAnnotations(representation.fieldMetadata);

    var fieldBeginToken =
        representation.fieldMetadata.beginToken ?? representation.fieldType;
    var fieldCodeRangeOffset = fieldBeginToken.offset;
    var fieldCodeRangeLength = fieldNameToken.end - fieldCodeRangeOffset;
    fieldElement.setCodeRange(fieldCodeRangeOffset, fieldCodeRangeLength);

    representation.fieldElement = fieldElement;
    _linker.elementNodes[fieldElement] = representation;
    _enclosingContext.addNonSyntheticField(fieldElement);

    var formalParameterElement = FieldFormalParameterElementImpl(
      name: fieldName,
      nameOffset: fieldNameToken.offset,
      parameterKind: ParameterKind.REQUIRED,
    )
      ..field = fieldElement
      ..hasImplicitType = true;
    formalParameterElement.setCodeRange(
      fieldCodeRangeOffset,
      fieldCodeRangeLength,
    );

    extensionElement.augmented.representation = fieldElement;

    {
      String name;
      int? periodOffset;
      int nameOffset;
      int? nameEnd;
      var constructorNameNode = representation.constructorName;
      if (constructorNameNode != null) {
        var nameToken = constructorNameNode.name;
        name = nameToken.lexeme.ifEqualThen('new', '');
        periodOffset = constructorNameNode.period.offset;
        nameOffset = nameToken.offset;
        nameEnd = nameToken.end;
      } else {
        name = '';
        nameOffset = extensionNode.name.offset;
        nameEnd = extensionNode.name.end;
      }

      var constructorElement = ConstructorElementImpl(name, nameOffset)
        ..isAugmentation = extensionNode.augmentKeyword != null
        ..isConst = extensionNode.constKeyword != null
        ..nameEnd = nameEnd
        ..parameters = [formalParameterElement]
        ..periodOffset = periodOffset;
      _setCodeRange(constructorElement, representation);

      representation.constructorElement = constructorElement;
      _linker.elementNodes[constructorElement] = representation;
      _enclosingContext.addConstructor(constructorElement);

      extensionElement.augmented.primaryConstructor = constructorElement;
    }

    representation.fieldType.accept(this);
  }

  void _resolveConstructorFieldFormals(InterfaceElementImpl element) {
    for (var constructor in element.constructors) {
      for (var parameter in constructor.parameters) {
        if (parameter is FieldFormalParameterElementImpl) {
          parameter.field = element.getField(parameter.name);
        }
      }
    }
  }

  void _visitPropertyFirst<T extends AstNode>(List<AstNode> nodes) {
    // When loading from bytes, we read fields first.
    // There is no particular reason for this - we just have to store
    // either non-synthetic fields first, or non-synthetic property
    // accessors first. And we arbitrary decided to store fields first.
    for (var node in nodes) {
      if (node is T) {
        node.accept(this);
      }
    }

    // ...then we load non-synthetic accessors.
    for (var node in nodes) {
      if (node is! T) {
        node.accept(this);
      }
    }
  }

  /// Make the given [context] be the current one while running [f].
  void _withEnclosing(_EnclosingContext context, void Function() f) {
    var previousContext = _enclosingContext;
    _enclosingContext = context;
    try {
      f();
    } finally {
      _enclosingContext = previousContext;
    }
  }

  static List<ElementAnnotationImpl> _buildAnnotationsWithUnit(
    CompilationUnitElementImpl unitElement,
    List<Annotation> nodeList,
  ) {
    var length = nodeList.length;
    if (length == 0) {
      return const <ElementAnnotationImpl>[];
    }

    return List<ElementAnnotationImpl>.generate(length, (index) {
      var ast = nodeList[index] as AnnotationImpl;
      var element = ElementAnnotationImpl(unitElement);
      element.annotationAst = ast;
      ast.elementAnnotation = element;
      return element;
    }, growable: false);
  }

  static void _setCodeRange(ElementImpl element, AstNode node) {
    var parent = node.parent;
    if (node is FormalParameter && parent is DefaultFormalParameter) {
      node = parent;
    }

    if (node is VariableDeclaration && parent is VariableDeclarationList) {
      var fieldDeclaration = parent.parent;
      if (fieldDeclaration != null && parent.variables.first == node) {
        var offset = fieldDeclaration.offset;
        element.setCodeRange(offset, node.end - offset);
        return;
      }
    }

    element.setCodeRange(node.offset, node.length);
  }

  static void _setDocumentation(ElementImpl element, AnnotatedNode node) {
    element.documentationComment =
        getCommentNodeRawText(node.documentationComment);
  }
}

class _EnclosingContext {
  final Reference reference;
  final ElementImpl element;
  final List<ClassElementImpl> _classes = [];
  final List<ConstructorElementImpl> _constructors = [];
  final List<EnumElementImpl> _enums = [];
  final List<ExtensionElementImpl> _extensions = [];
  final List<ExtensionTypeElementImpl> _extensionTypes = [];
  final List<FieldElementImpl> _fields = [];
  final List<FunctionElementImpl> _functions = [];
  final List<MethodElementImpl> _methods = [];
  final List<MixinElementImpl> _mixins = [];
  final List<ParameterElementImpl> _parameters = [];
  final List<PropertyAccessorElementImpl> _propertyAccessors = [];
  final List<TopLevelVariableElementImpl> _topLevelVariables = [];
  final List<TypeAliasElementImpl> _typeAliases = [];
  final List<TypeParameterElementImpl> _typeParameters = [];

  /// A class can have `const` constructors, and if it has we need values
  /// of final instance fields.
  final bool constFieldsForFinalInstance;

  /// Not all optional formal parameters can have default values.
  /// For example, formal parameters of methods can, but formal parameters
  /// of function types - not. This flag specifies if we should create
  /// [ParameterElementImpl]s or [DefaultParameterElementImpl]s.
  final bool hasDefaultFormalParameters;

  _EnclosingContext(
    this.reference,
    this.element, {
    this.constFieldsForFinalInstance = false,
    this.hasDefaultFormalParameters = false,
  });

  List<ClassElementImpl> get classes {
    return _classes.toFixedList();
  }

  List<ConstructorElementImpl> get constructors {
    return _constructors.toFixedList();
  }

  List<EnumElementImpl> get enums {
    return _enums.toFixedList();
  }

  List<ExtensionElementImpl> get extensions {
    return _extensions.toFixedList();
  }

  List<ExtensionTypeElementImpl> get extensionTypes {
    return _extensionTypes.toFixedList();
  }

  List<FieldElementImpl> get fields {
    return _fields.toFixedList();
  }

  List<FunctionElementImpl> get functions {
    return _functions.toFixedList();
  }

  bool get isDartCoreEnum {
    var element = this.element;
    return element is ClassElementImpl && element.isDartCoreEnum;
  }

  List<MethodElementImpl> get methods {
    return _methods.toFixedList();
  }

  List<MixinElementImpl> get mixins {
    return _mixins.toFixedList();
  }

  List<ParameterElementImpl> get parameters {
    return _parameters.toFixedList();
  }

  List<PropertyAccessorElementImpl> get propertyAccessors {
    return _propertyAccessors.toFixedList();
  }

  List<TopLevelVariableElementImpl> get topLevelVariables {
    return _topLevelVariables.toFixedList();
  }

  List<TypeAliasElementImpl> get typeAliases {
    return _typeAliases.toFixedList();
  }

  List<TypeParameterElementImpl> get typeParameters {
    return _typeParameters.toFixedList();
  }

  Reference addClass(String name, ClassElementImpl element) {
    _classes.add(element);
    var containerName =
        element.isAugmentation ? '@classAugmentation' : '@class';
    return _addReference(containerName, name, element);
  }

  Reference addConstructor(ConstructorElementImpl element) {
    _constructors.add(element);

    var containerName =
        element.isAugmentation ? '@constructorAugmentation' : '@constructor';
    var referenceName = element.name.ifNotEmptyOrElse('new');
    return _addReference(containerName, referenceName, element);
  }

  Reference addEnum(String name, EnumElementImpl element) {
    _enums.add(element);
    var containerName = element.isAugmentation ? '@enumAugmentation' : '@enum';
    return _addReference(containerName, name, element);
  }

  Reference addExtension(String name, ExtensionElementImpl element) {
    _extensions.add(element);
    var containerName =
        element.isAugmentation ? '@extensionAugmentation' : '@extension';
    return _addReference(containerName, name, element);
  }

  Reference addExtensionType(String name, ExtensionTypeElementImpl element) {
    _extensionTypes.add(element);
    var containerName = element.isAugmentation
        ? '@extensionTypeAugmentation'
        : '@extensionType';
    return _addReference(containerName, name, element);
  }

  Reference addField(String name, FieldElementImpl element) {
    _fields.add(element);
    var containerName =
        element.isAugmentation ? '@fieldAugmentation' : '@field';
    return _addReference(containerName, name, element);
  }

  void addFieldSynthetic(Reference reference, FieldElementImpl element) {
    _fields.add(element);
    _bindReference(reference, element);
  }

  Reference addFunction(String name, FunctionElementImpl element) {
    _functions.add(element);
    var containerName =
        element.isAugmentation ? '@functionAugmentation' : '@function';
    return _addReference(containerName, name, element);
  }

  Reference addGetter(String name, PropertyAccessorElementImpl element) {
    _propertyAccessors.add(element);
    var containerName =
        element.isAugmentation ? '@getterAugmentation' : '@getter';
    return _addReference(containerName, name, element);
  }

  Reference addMethod(String name, MethodElementImpl element) {
    _methods.add(element);
    var containerName =
        element.isAugmentation ? '@methodAugmentation' : '@method';
    return _addReference(containerName, name, element);
  }

  Reference addMixin(String name, MixinElementImpl element) {
    _mixins.add(element);
    var containerName =
        element.isAugmentation ? '@mixinAugmentation' : '@mixin';
    return _addReference(containerName, name, element);
  }

  void addNonSyntheticField(FieldElementImpl element) {
    var name = element.name;
    addField(name, element);

    // Augmenting a variable with a variable only alters its initializer.
    // So, don't create getter and setter.
    if (element.isAugmentation) {
      return;
    }

    {
      var getterRef = reference.getChild('@getter').addChild(name);
      var getter = element.createImplicitGetter(getterRef);
      _propertyAccessors.add(getter);
    }

    if (element.hasSetter) {
      var setterRef = reference.getChild('@setter').addChild(name);
      var setter = element.createImplicitSetter(setterRef);
      _propertyAccessors.add(setter);
    }
  }

  Reference? addParameter(String? name, ParameterElementImpl element) {
    _parameters.add(element);
    if (name == null) {
      return null;
    } else {
      return _addReference('@parameter', name, element);
    }
  }

  void addPropertyAccessorSynthetic(PropertyAccessorElementImpl element) {
    _propertyAccessors.add(element);
  }

  Reference addSetter(String name, PropertyAccessorElementImpl element) {
    _propertyAccessors.add(element);
    var containerName =
        element.isAugmentation ? '@setterAugmentation' : '@setter';
    return _addReference(containerName, name, element);
  }

  Reference addTopLevelVariable(
      String name, TopLevelVariableElementImpl element) {
    _topLevelVariables.add(element);
    var containerName = element.isAugmentation
        ? '@topLevelVariableAugmentation'
        : '@topLevelVariable';
    return _addReference(containerName, name, element);
  }

  void addTopLevelVariableSynthetic(
      Reference reference, TopLevelVariableElementImpl element) {
    _topLevelVariables.add(element);
    _bindReference(reference, element);
  }

  Reference addTypeAlias(String name, TypeAliasElementImpl element) {
    _typeAliases.add(element);
    var containerName =
        element.isAugmentation ? '@typeAliasAugmentation' : '@typeAlias';
    return _addReference(containerName, name, element);
  }

  void addTypeParameter(String name, TypeParameterElementImpl element) {
    _typeParameters.add(element);
    this.element.encloseElement(element);
  }

  Reference _addReference(
    String containerName,
    String name,
    ElementImpl element,
  ) {
    var containerRef = this.reference.getChild(containerName);
    var reference = containerRef.addChild(name);
    _bindReference(reference, element);
    return reference;
  }

  void _bindReference(Reference reference, ElementImpl element) {
    reference.element = element;
    element.reference = reference;
    this.element.encloseElement(element);
  }
}
