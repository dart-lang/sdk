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
  int _nextUnnamedId = 0;

  ElementBuilder({
    required LibraryBuilder libraryBuilder,
    required CompilationUnitElementImpl unitElement,
  })  : _libraryBuilder = libraryBuilder,
        _unitElement = unitElement,
        _enclosingContext = _EnclosingContext(
          instanceElementBuilder: null,
          fragment: unitElement,
        );

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

    var fragment = ClassElementImpl(name, nameToken.offset);
    fragment.name2 = _getFragmentName(nameToken);
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAbstract = node.abstractKeyword != null;
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.isBase = node.baseKeyword != null;
    fragment.isFinal = node.finalKeyword != null;
    fragment.isInterface = node.interfaceKeyword != null;
    fragment.isMacro = node.macroKeyword != null;
    fragment.isMixinClass = node.mixinKeyword != null;
    if (node.sealedKeyword != null) {
      fragment.isAbstract = true;
      fragment.isSealed = true;
    }
    fragment.hasExtendsClause = node.extendsClause != null;
    fragment.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredElement = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var fragmentReference = _enclosingContext.addClass(refName, fragment);
    if (!fragment.isAugmentation) {
      _libraryBuilder.declare(name, fragmentReference);
    }

    var elementBuilder = _libraryBuilder.elementBuilderGetters[name];
    elementBuilder?.setPreviousFor(fragment);
    if (fragment.isAugmentation && elementBuilder is ClassElementBuilder) {
    } else {
      var libraryRef = _libraryBuilder.reference;
      var containerRef = libraryRef.getChild('@class');
      var elementReference = containerRef.addChild(refName);
      var element = ClassElementImpl2(elementReference, fragment);
      _libraryBuilder.element.classes.add(element);

      elementBuilder = ClassElementBuilder(
        element: element,
        firstFragment: fragment,
      );
      _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
    }

    var holder = _EnclosingContext(
      instanceElementBuilder: elementBuilder,
      fragment: fragment,
      constFieldsForFinalInstance: true,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });
    fragment.typeParameters = holder.typeParameters;
    fragment.accessors = holder.propertyAccessors;
    fragment.constructors = holder.constructors;
    fragment.fields = holder.fields;
    fragment.methods = holder.methods;

    node.extendsClause?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);

    elementBuilder.addFragment(fragment);
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var fragment = ClassElementImpl(name, nameToken.offset);
    fragment.name2 = _getFragmentName(nameToken);
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAbstract = node.abstractKeyword != null;
    fragment.isBase = node.baseKeyword != null;
    fragment.isFinal = node.finalKeyword != null;
    fragment.isInterface = node.interfaceKeyword != null;
    fragment.isMacro = node.macroKeyword != null;
    fragment.isMixinApplication = true;
    fragment.isMixinClass = node.mixinKeyword != null;
    if (node.sealedKeyword != null) {
      fragment.isAbstract = true;
      fragment.isSealed = true;
    }
    fragment.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredElement = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addClass(refName, fragment);
    if (!fragment.isAugmentation) {
      _libraryBuilder.declare(name, reference);
    }

    var elementBuilder = _libraryBuilder.elementBuilderGetters[name];
    elementBuilder?.setPreviousFor(fragment);
    if (fragment.isAugmentation && elementBuilder is ClassElementBuilder) {
    } else {
      var libraryRef = _libraryBuilder.reference;
      var containerRef = libraryRef.getChild('@class');
      var elementReference = containerRef.addChild(refName);
      var element = ClassElementImpl2(elementReference, fragment);
      _libraryBuilder.element.classes.add(element);

      elementBuilder = ClassElementBuilder(
        element: element,
        firstFragment: fragment,
      );
      _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
    }

    var holder = _EnclosingContext(
      instanceElementBuilder: elementBuilder,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
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
    element.typeName = node.returnType.name;
    element.typeNameOffset = node.returnType.offset;
    element.periodOffset = node.period?.offset;
    element.nameEnd = nameNode.end;
    if ((node.period, node.name) case (var _?, var name?)) {
      element.name2 = name.lexeme;
      element.nameOffset2 = name.offset;
    } else {
      element.name2 = 'new';
    }
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
      fragment: element,
      formalParameters: node.parameters,
    );
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

    var fragment = EnumElementImpl(name, nameOffset);
    fragment.name2 = _getFragmentName(nameToken);
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredElement = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addEnum(refName, fragment);
    if (!fragment.isAugmentation) {
      _libraryBuilder.declare(name, reference);
    }

    var elementBuilder = _libraryBuilder.elementBuilderGetters[name];
    elementBuilder?.setPreviousFor(fragment);
    if (fragment.isAugmentation && elementBuilder is EnumElementBuilder) {
    } else {
      var libraryRef = _libraryBuilder.reference;
      var containerRef = libraryRef.getChild('@enum');
      var elementReference = containerRef.addChild(refName);
      var element = EnumElementImpl2(elementReference, fragment);
      _libraryBuilder.element.enums.add(element);

      elementBuilder = EnumElementBuilder(
        firstFragment: fragment,
        element: element,
      );
      _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
    }

    var holder = _EnclosingContext(
      instanceElementBuilder: elementBuilder,
      fragment: fragment,
      constFieldsForFinalInstance: true,
    );

    // Build fields for all enum constants.
    var constants = node.constants;
    var valuesElements = <SimpleIdentifierImpl>[];
    var valuesNames = <String>{};
    for (var i = 0; i < constants.length; ++i) {
      var constant = constants[i];
      var nameToken = constant.name;
      var name = nameToken.lexeme;
      var field = ConstFieldElementImpl(name, constant.name.offset)
        ..hasImplicitType = true
        ..hasInitializer = true
        ..isAugmentation = constant.augmentKeyword != null
        ..isConst = true
        ..isEnumConstant = true
        ..isStatic = true;
      field.name2 = _getFragmentName(nameToken);
      field.nameOffset2 = _getFragmentNameOffset(nameToken);
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
            name2: StringToken(TokenType.STRING, fragment.name, -1),
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

      var refName = field.name2 ?? '${_nextUnnamedId++}';
      holder.addNonSyntheticField(refName, field);

      valuesElements.add(
        SimpleIdentifierImpl(
          StringToken(TokenType.STRING, name, -1),
        ),
      );
      valuesNames.add(name);
    }

    // Build the 'values' field.
    if (fragment.augmentationTarget == null) {
      var valuesField = ConstFieldElementImpl('values', -1)
        ..isConst = true
        ..isStatic = true
        ..isSynthetic = true
        ..name2 = 'values';
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
              name2: StringToken(TokenType.STRING, fragment.name, -1),
              typeArguments: null,
              question: null,
            )..element2 = fragment.asElement2,
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

      holder.addNonSyntheticField('values', valuesField);

      _libraryBuilder.implicitEnumNodes[fragment] = ImplicitEnumNodes(
        element: fragment,
        valuesTypeNode: valuesTypeNode,
        valuesNode: variableDeclaration,
        valuesElement: valuesField,
        valuesNames: valuesNames,
        valuesInitializer: initializer,
      );
    } else {
      var declaration = elementBuilder.firstFragment;
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

    fragment.accessors = holder.propertyAccessors;
    fragment.constructors = holder.constructors;
    fragment.fields = holder.fields;
    fragment.methods = holder.methods;
    fragment.typeParameters = holder.typeParameters;
    elementBuilder.addFragment(fragment);
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

    var fragment = ExtensionElementImpl(name, nameOffset);
    fragment.name2 = _getFragmentName(nameToken);
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredElement = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addExtension(refName, fragment);

    if (name != null) {
      if (!fragment.isAugmentation) {
        _libraryBuilder.declare(name, reference);
      }
    }

    FragmentedElementBuilder? elementBuilder;
    if (name != null) {
      elementBuilder = _libraryBuilder.elementBuilderGetters[name];
      elementBuilder?.setPreviousFor(fragment);
      if (fragment.isAugmentation &&
          elementBuilder is ExtensionElementBuilder) {
      } else {
        var elementReference =
            _libraryBuilder.reference.getChild('@extension').addChild(refName);
        var element = ExtensionElementImpl2(elementReference, fragment);
        _libraryBuilder.element.extensions.add(element);

        elementBuilder = ExtensionElementBuilder(
          firstFragment: fragment,
          element: element,
        );
        _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
      }
    } else {
      var elementReference =
          _libraryBuilder.reference.getChild('@extension').addChild(refName);
      var element = ExtensionElementImpl2(elementReference, fragment);
      _libraryBuilder.element.extensions.add(element);
      elementBuilder = ExtensionElementBuilder(
        firstFragment: fragment,
        element: element,
      );
      elementBuilder as ExtensionElementBuilder; // force
    }

    var holder = _EnclosingContext(
      instanceElementBuilder: elementBuilder,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });
    fragment.typeParameters = holder.typeParameters;
    fragment.accessors = holder.propertyAccessors;
    fragment.fields = holder.fields;
    fragment.methods = holder.methods;

    node.onClause?.accept(this);
    elementBuilder.addFragment(fragment);
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

    var fragment = ExtensionTypeElementImpl(name, nameToken.offset);
    fragment.name2 = _getFragmentName(nameToken);
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredElement = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addExtensionType(refName, fragment);
    if (!fragment.isAugmentation) {
      _libraryBuilder.declare(name, reference);
    }

    var elementBuilder = _libraryBuilder.elementBuilderGetters[name];
    elementBuilder?.setPreviousFor(fragment);
    if (fragment.isAugmentation &&
        elementBuilder is ExtensionTypeElementBuilder) {
    } else {
      var libraryRef = _libraryBuilder.reference;
      var containerRef = libraryRef.getChild('@extensionType');
      var elementReference = containerRef.addChild(refName);
      var element = ExtensionTypeElementImpl2(elementReference, fragment);
      _libraryBuilder.element.extensionTypes.add(element);

      elementBuilder = ExtensionTypeElementBuilder(
        firstFragment: fragment,
        element: element,
      );

      fragment.isAugmentationChainStart = true;
      _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
    }

    var holder = _EnclosingContext(
      instanceElementBuilder: elementBuilder,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      _builtRepresentationDeclaration(
        extensionNode: node,
        representation: node.representation,
        extensionElement: fragment,
      );
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });

    fragment.accessors = holder.propertyAccessors;
    fragment.constructors = holder.constructors;
    fragment.fields = holder.fields;
    fragment.methods = holder.methods;
    fragment.typeParameters = holder.typeParameters;

    var executables = const <ExecutableElementImpl>[]
        .followedBy(fragment.accessors)
        .followedBy(fragment.methods);
    for (var executable in executables) {
      executable.isExtensionTypeMember = true;
    }

    node.implementsClause?.accept(this);
    elementBuilder.addFragment(fragment);
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

      element.name2 = _getFragmentName(nameToken);
      element.nameOffset2 = _getFragmentNameOffset(nameToken);
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

      var refName = element.name2 ?? '${_nextUnnamedId++}';
      _enclosingContext.addNonSyntheticField(refName, element);

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

    element.name2 = _getFragmentName(nameToken);
    element.nameOffset2 = _getFragmentNameOffset(nameToken);
    element.hasImplicitType = node.type == null && node.parameters == null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;

    // TODO(scheglov): check that we don't set reference for parameters
    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: element,
    );
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
    FragmentedElementBuilder? elementBuilder;
    if (node.isGetter) {
      var getterFragment = PropertyAccessorElementImpl(name, nameOffset);
      getterFragment.name2 = _getFragmentName(nameToken);
      getterFragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      getterFragment.isAugmentation = node.augmentKeyword != null;
      getterFragment.isGetter = true;
      getterFragment.isStatic = true;

      var refName = getterFragment.name2 ?? '${_nextUnnamedId++}';
      reference = _enclosingContext.addGetter(refName, getterFragment);
      executableElement = getterFragment;

      if (!getterFragment.isAugmentation) {
        var variableFragment = _buildSyntheticVariable(
          name: name,
          accessorElement: getterFragment,
        ) as TopLevelVariableElementImpl;

        var elementBuilder = TopLevelVariableElementBuilder(
          element: variableFragment.element,
          firstFragment: variableFragment,
        );
        _libraryBuilder.elementBuilderVariables[name] = elementBuilder;
      }

      elementBuilder = _libraryBuilder.elementBuilderGetters[name];
      elementBuilder ??= _libraryBuilder.elementBuilderSetters[name];
      elementBuilder?.setPreviousFor(getterFragment);
      if (getterFragment.isAugmentation &&
          elementBuilder is GetterElementBuilder) {
        elementBuilder.addFragment(getterFragment);
      } else {
        elementBuilder = GetterElementBuilder(
          element: GetterElementImpl(getterFragment),
          firstFragment: getterFragment,
        );
        _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
      }
    } else if (node.isSetter) {
      var setterFragment = PropertyAccessorElementImpl(name, nameOffset);
      setterFragment.name2 = _getFragmentName(nameToken);
      setterFragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      setterFragment.isAugmentation = node.augmentKeyword != null;
      setterFragment.isSetter = true;
      setterFragment.isStatic = true;

      var refName = setterFragment.name2 ?? '${_nextUnnamedId++}';
      reference = _enclosingContext.addSetter(refName, setterFragment);
      executableElement = setterFragment;

      if (!setterFragment.isAugmentation) {
        var variableFragment = _buildSyntheticVariable(
          name: name,
          accessorElement: setterFragment,
        ) as TopLevelVariableElementImpl;

        var elementBuilder = TopLevelVariableElementBuilder(
          element: variableFragment.element,
          firstFragment: variableFragment,
        );
        _libraryBuilder.elementBuilderVariables[name] = elementBuilder;
      }

      elementBuilder = _libraryBuilder.elementBuilderSetters[name];
      elementBuilder ??= _libraryBuilder.elementBuilderGetters[name];
      elementBuilder?.setPreviousFor(setterFragment);
      if (setterFragment.isAugmentation &&
          elementBuilder is SetterElementBuilder) {
        elementBuilder.addFragment(setterFragment);
      } else {
        elementBuilder = SetterElementBuilder(
          element: SetterElementImpl(setterFragment),
          firstFragment: setterFragment,
        );
        _libraryBuilder.elementBuilderSetters[name] = elementBuilder;
      }
    } else {
      var fragment = FunctionElementImpl(name, nameOffset);
      fragment.name2 = _getFragmentName(nameToken);
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isStatic = true;
      executableElement = fragment;

      var refName = fragment.name2 ?? '${_nextUnnamedId++}';
      reference = _enclosingContext.addFunction(name, fragment);

      elementBuilder = _libraryBuilder.elementBuilderGetters[name];
      elementBuilder ??= _libraryBuilder.elementBuilderSetters[name];
      elementBuilder?.setPreviousFor(fragment);
      if (fragment.isAugmentation &&
          elementBuilder is TopLevelFunctionElementBuilder) {
        elementBuilder.addFragment(fragment);
      } else {
        var libraryRef = _libraryBuilder.reference;
        var containerRef = libraryRef.getChild('@function');
        var elementReference = containerRef.addChild(refName);
        var element = TopLevelFunctionElementImpl(
          elementReference,
          fragment,
        );
        _libraryBuilder.element.functions.add(element);

        elementBuilder = TopLevelFunctionElementBuilder(
          element: element,
          firstFragment: fragment,
        );
        _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
      }
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
      fragment: executableElement,
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

    var fragment = TypeAliasElementImpl(name, nameToken.offset);
    fragment.name2 = _getFragmentName(nameToken);
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isFunctionTypeAliasBased = true;
    fragment.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredElement = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addTypeAlias(refName, fragment);
    _libraryBuilder.declare(name, reference);

    var elementBuilder = _libraryBuilder.elementBuilderGetters[name];
    elementBuilder ??= _libraryBuilder.elementBuilderSetters[name];
    elementBuilder?.setPreviousFor(fragment);
    if (fragment.isAugmentation && elementBuilder is TypeAliasElementBuilder) {
    } else {
      var libraryRef = _libraryBuilder.reference;
      var containerRef = libraryRef.getChild('@typeAlias');
      var elementReference = containerRef.addChild(refName);
      var element = TypeAliasElementImpl2(elementReference, fragment);
      _libraryBuilder.element.typeAliases.add(element);

      elementBuilder = TypeAliasElementBuilder(
        element: element,
        firstFragment: fragment,
      );
      _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
    }

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.returnType?.accept(this);
      node.parameters.accept(this);
    });

    var aliasedElement = GenericFunctionTypeElementImpl.forOffset(
      nameToken.offset,
    );
    aliasedElement.parameters = holder.parameters;

    fragment.typeParameters = holder.typeParameters;
    fragment.aliasedElement = aliasedElement;

    elementBuilder.addFragment(fragment);
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
    element.name2 = _getFragmentName(nameToken);
    element.nameOffset2 = _getFragmentNameOffset(nameToken);
    element.isExplicitlyCovariant = node.covariantKeyword != null;
    element.isFinal = node.isFinal;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;
    var refName = node.isNamed ? name : null;
    _enclosingContext.addParameter(refName, element);

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: element,
    );
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

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: element,
    );
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

    var fragment = TypeAliasElementImpl(name, nameToken.offset);
    fragment.name2 = _getFragmentName(nameToken);
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredElement = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addTypeAlias(refName, fragment);
    if (!fragment.isAugmentation) {
      _libraryBuilder.declare(name, reference);
    }

    var elementBuilder = _libraryBuilder.elementBuilderGetters[name];
    elementBuilder ??= _libraryBuilder.elementBuilderSetters[name];
    elementBuilder?.setPreviousFor(fragment);
    if (fragment.isAugmentation && elementBuilder is TypeAliasElementBuilder) {
    } else {
      var libraryRef = _libraryBuilder.reference;
      var containerRef = libraryRef.getChild('@typeAlias');
      var elementReference = containerRef.addChild(refName);
      var element = TypeAliasElementImpl2(elementReference, fragment);
      _libraryBuilder.element.typeAliases.add(element);

      elementBuilder = TypeAliasElementBuilder(
        element: element,
        firstFragment: fragment,
      );
      _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
    }

    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
    });
    fragment.typeParameters = holder.typeParameters;

    var typeNode = node.type;
    typeNode.accept(this);

    if (typeNode is GenericFunctionTypeImpl) {
      fragment.aliasedElement =
          typeNode.declaredElement as GenericFunctionTypeElementImpl;
    }

    elementBuilder.addFragment(fragment);
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
    ExecutableElementImpl executableFragment;
    if (node.isGetter) {
      var fragment = PropertyAccessorElementImpl(name, nameOffset);
      fragment.name2 = _getFragmentName(nameToken);
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.isAbstract = node.isAbstract;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isGetter = true;
      fragment.isStatic = node.isStatic;

      // `class Enum {}` in `dart:core` declares `int get index` as abstract.
      // But the specification says that practically a different class
      // implementing `Enum` is used as a superclass, so `index` should be
      // considered to have non-abstract implementation.
      if (_enclosingContext.isDartCoreEnum && name == 'index') {
        fragment.isAbstract = false;
      }

      reference = _enclosingContext.addGetter(name, fragment);
      executableFragment = fragment;

      if (!fragment.isAugmentation) {
        var refName = fragment.name2 ?? '${_nextUnnamedId++}';
        _buildSyntheticVariable(name: refName, accessorElement: fragment);
      }
    } else if (node.isSetter) {
      var fragment = PropertyAccessorElementImpl(name, nameOffset);
      fragment.name2 = _getFragmentName(nameToken);
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.isAbstract = node.isAbstract;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isSetter = true;
      fragment.isStatic = node.isStatic;

      var refName = fragment.name2 ?? '${_nextUnnamedId++}';
      reference = _enclosingContext.addSetter(refName, fragment);
      executableFragment = fragment;

      if (!fragment.isAugmentation) {
        _buildSyntheticVariable(name: name, accessorElement: fragment);
      }
    } else {
      var isUnaryMinus = false;
      if (nameToken.lexeme == '-') {
        var parameters = node.parameters;
        isUnaryMinus = parameters != null && parameters.parameters.isEmpty;
      }

      if (isUnaryMinus) {
        name = 'unary-';
      }

      var fragment = MethodElementImpl(name, nameOffset);
      fragment.name2 = _getFragmentName(nameToken);
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.isAbstract = node.isAbstract;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isStatic = node.isStatic;

      String refName;
      if (isUnaryMinus) {
        refName = 'unary-';
      } else {
        refName = fragment.name2 ?? '${_nextUnnamedId++}';
      }

      reference = _enclosingContext.addMethod(refName, fragment);
      executableFragment = fragment;

      {
        var enclosingBuilder = _enclosingContext.instanceElementBuilder!;

        var lastFragment = enclosingBuilder.replaceGetter(fragment);
        if (fragment.isAugmentation) {
          fragment.augmentationTargetAny = lastFragment;
        }

        if (fragment.isAugmentation && lastFragment is MethodElementImpl) {
          lastFragment.augmentation = fragment;
          fragment.element = lastFragment.element;
        } else {
          var element = MethodElementImpl2(
            enclosingBuilder.element.reference!
                .getChild('@method')
                .addChild(refName),
            fragment.name2,
            fragment,
          );
          enclosingBuilder.element.methods2.add(element);
        }
      }
    }
    executableFragment.hasImplicitReturnType = node.returnType == null;
    executableFragment.invokesSuperSelf = node.invokesSuperSelf;
    executableFragment.isAsynchronous = node.body.isAsynchronous;
    executableFragment.isExternal =
        node.externalKeyword != null || node.body is NativeFunctionBody;
    executableFragment.isGenerator = node.body.isGenerator;
    executableFragment.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(executableFragment, node);
    _setDocumentation(executableFragment, node);

    node.declaredElement = executableFragment;
    _linker.elementNodes[executableFragment] = node;

    _buildExecutableElementChildren(
      reference: reference,
      fragment: executableFragment,
      formalParameters: node.parameters,
      typeParameters: node.typeParameters,
    );

    _buildType(node.returnType);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var fragment = MixinElementImpl(name, nameToken.offset);
    fragment.name2 = _getFragmentName(nameToken);
    fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
    fragment.isAugmentation = node.augmentKeyword != null;
    fragment.isBase = node.baseKeyword != null;
    fragment.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(fragment, node);
    _setDocumentation(fragment, node);

    node.declaredElement = fragment;
    _linker.elementNodes[fragment] = node;

    var refName = fragment.name2 ?? '${_nextUnnamedId++}';
    var reference = _enclosingContext.addMixin(refName, fragment);
    if (!fragment.isAugmentation) {
      _libraryBuilder.declare(name, reference);
    }

    var elementBuilder = _libraryBuilder.elementBuilderGetters[name];
    elementBuilder?.setPreviousFor(fragment);

    // If the fragment is an augmentation, and the corresponding builder
    // has correct type, add the fragment to the builder. Otherwise, create
    // a new builder.
    if (fragment.isAugmentation && elementBuilder is MixinElementBuilder) {
    } else {
      var libraryRef = _libraryBuilder.reference;
      var containerRef = libraryRef.getChild('@mixin');
      var elementReference = containerRef.addChild(refName);
      var element = MixinElementImpl2(elementReference, fragment);
      _libraryBuilder.element.mixins.add(element);

      elementBuilder = MixinElementBuilder(
        firstFragment: fragment,
        element: element,
      );
      _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
    }

    var holder = _EnclosingContext(
      instanceElementBuilder: elementBuilder,
      fragment: fragment,
    );
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });
    fragment.typeParameters = holder.typeParameters;
    fragment.accessors = holder.propertyAccessors;
    fragment.fields = holder.fields;
    fragment.methods = holder.methods;

    node.onClause?.accept(this);
    node.implementsClause?.accept(this);
    elementBuilder.addFragment(fragment);
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

    element.name2 = _getFragmentName(nameToken);
    element.nameOffset2 = _getFragmentNameOffset(nameToken);
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
    element.name2 = _getFragmentName(nameToken);
    element.nameOffset2 = _getFragmentNameOffset(nameToken);
    element.hasImplicitType = node.type == null && node.parameters == null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;

    // TODO(scheglov): check that we don't set reference for parameters
    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: element,
    );
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
    var enclosingRef = _enclosingContext.fragmentReference;

    var metadata = _buildAnnotations(node.metadata);
    for (var variable in node.variables.variables) {
      var nameToken = variable.name;
      var name = nameToken.lexeme;
      var nameOffset = nameToken.offset;

      TopLevelVariableElementImpl fragment;
      if (node.variables.isConst) {
        fragment = ConstTopLevelVariableElementImpl(name, nameOffset)
          ..constantInitializer = variable.initializer;
      } else {
        fragment = TopLevelVariableElementImpl(name, nameOffset);
      }

      fragment.name2 = _getFragmentName(nameToken);
      fragment.nameOffset2 = _getFragmentNameOffset(nameToken);
      fragment.hasInitializer = variable.initializer != null;
      fragment.isAugmentation = node.augmentKeyword != null;
      fragment.isConst = node.variables.isConst;
      fragment.isExternal = node.externalKeyword != null;
      fragment.isFinal = node.variables.isFinal;
      fragment.isLate = node.variables.isLate;
      fragment.metadata = metadata;
      _setCodeRange(fragment, variable);
      _setDocumentation(fragment, node);

      if (node.variables.type == null) {
        fragment.hasImplicitType = true;
      }

      var refName = fragment.name2 ?? '${_nextUnnamedId++}';
      _enclosingContext.addTopLevelVariable(refName, fragment);

      if (!fragment.isAugmentation) {
        {
          var ref = enclosingRef.getChild('@getter').addChild(refName);
          var getter = fragment.createImplicitGetter(ref);
          _enclosingContext.addPropertyAccessorSynthetic(getter);
          _libraryBuilder.declare(name, ref);

          var elementBuilder = GetterElementBuilder(
            element: GetterElementImpl(getter),
            firstFragment: getter,
          );
          _libraryBuilder.elementBuilderGetters[name] = elementBuilder;
        }

        if (fragment.hasSetter) {
          var ref = enclosingRef.getChild('@setter').addChild(refName);
          var setter = fragment.createImplicitSetter(ref);
          _enclosingContext.addPropertyAccessorSynthetic(setter);
          _libraryBuilder.declare('$name=', ref);

          var elementBuilder = SetterElementBuilder(
            element: SetterElementImpl(setter),
            firstFragment: setter,
          );
          _libraryBuilder.elementBuilderSetters[name] = elementBuilder;
        }
      }

      _linker.elementNodes[fragment] = variable;
      variable.declaredElement = fragment;

      var elementBuilder = _libraryBuilder.elementBuilderVariables[name];
      elementBuilder ??= _libraryBuilder.elementBuilderGetters[name];
      elementBuilder?.setPreviousFor(fragment);
      if (fragment.isAugmentation &&
          elementBuilder is TopLevelVariableElementBuilder) {
        elementBuilder.addFragment(fragment);
      } else {
        var elementReference = _libraryBuilder.reference
            .getChild('@topLevelVariable')
            .addChild(refName);
        var element = TopLevelVariableElementImpl2(
          elementReference,
          fragment,
        );
        _libraryBuilder.element.topLevelVariables.add(element);

        elementBuilder = TopLevelVariableElementBuilder(
          element: element,
          firstFragment: fragment,
        );
        _libraryBuilder.elementBuilderVariables[name] = elementBuilder;
      }
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
    element.name2 = _getFragmentName(nameToken);
    element.nameOffset2 = _getFragmentNameOffset(nameToken);
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

  void _buildExecutableElementChildren({
    required Reference reference,
    required ExecutableElementImpl fragment,
    FormalParameterList? formalParameters,
    TypeParameterList? typeParameters,
  }) {
    var holder = _EnclosingContext(
      instanceElementBuilder: null,
      fragment: fragment,
      hasDefaultFormalParameters: true,
    );
    _withEnclosing(holder, () {
      if (formalParameters != null) {
        formalParameters.accept(this);
        fragment.parameters = holder.parameters;
      }
      if (typeParameters != null) {
        typeParameters.accept(this);
        fragment.typeParameters = holder.typeParameters;
      }
    });
  }

  /// The [accessorElement] should not be an augmentation.
  PropertyInducingElementImpl _buildSyntheticVariable({
    required String name,
    required PropertyAccessorElementImpl accessorElement,
  }) {
    var refName = accessorElement.name2 ?? '${_nextUnnamedId++}';
    var enclosingRef = _enclosingContext.fragmentReference;
    var enclosingElement = _enclosingContext.fragment;

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
          ..isSynthetic = true
          ..name2 = accessorElement.name2;
        _enclosingContext.addTopLevelVariableSynthetic(reference, variable);

        var variableElementReference = _libraryBuilder.reference
            .getChild('@topLevelVariable')
            .addChild(refName);
        var variableElement = TopLevelVariableElementImpl2(
          variableElementReference,
          variable,
        );
        _libraryBuilder.element.topLevelVariables.add(variableElement);
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
          ..isSynthetic = true
          ..name2 = accessorElement.name2;
        _enclosingContext.addFieldSynthetic(reference, field);
      }
    }

    accessorElement.variable2 = property;
    if (accessorElement.isGetter) {
      property.getter = accessorElement;
    } else {
      property.setter = accessorElement;
    }
    return property;
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
    fieldElement.name2 = _getFragmentName(fieldNameToken);
    fieldElement.nameOffset2 = _getFragmentNameOffset(fieldNameToken);
    fieldElement.isFinal = true;
    fieldElement.metadata = _buildAnnotations(representation.fieldMetadata);

    var fieldBeginToken =
        representation.fieldMetadata.beginToken ?? representation.fieldType;
    var fieldCodeRangeOffset = fieldBeginToken.offset;
    var fieldCodeRangeLength = fieldNameToken.end - fieldCodeRangeOffset;
    fieldElement.setCodeRange(fieldCodeRangeOffset, fieldCodeRangeLength);

    representation.fieldElement = fieldElement;
    _linker.elementNodes[fieldElement] = representation;
    _enclosingContext.addNonSyntheticField(fieldName, fieldElement);

    var formalParameterElement = FieldFormalParameterElementImpl(
      name: fieldName,
      nameOffset: fieldNameToken.offset,
      parameterKind: ParameterKind.REQUIRED,
    )
      ..field = fieldElement
      ..hasImplicitType = true;
    formalParameterElement.name2 = _getFragmentName(fieldNameToken);
    formalParameterElement.nameOffset2 = _getFragmentNameOffset(fieldNameToken);
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
        ..periodOffset = periodOffset
        ..nameEnd = nameEnd
        ..parameters = [formalParameterElement];
      constructorElement.typeName = extensionElement.name2;
      constructorElement.typeNameOffset = extensionElement.nameOffset2;
      if (representation.constructorName case var constructorName?) {
        constructorElement.name2 = constructorName.name.lexeme;
        constructorElement.nameOffset2 = constructorName.name.offset;
      } else {
        constructorElement.name2 = 'new';
      }
      _setCodeRange(constructorElement, representation);

      representation.constructorElement = constructorElement;
      _linker.elementNodes[constructorElement] = representation;
      _enclosingContext.addConstructor(constructorElement);

      extensionElement.augmented.primaryConstructor = constructorElement;
    }

    representation.fieldType.accept(this);
  }

  String? _getFragmentName(Token? nameToken) {
    if (nameToken == null || nameToken.isSynthetic) {
      return null;
    }
    return nameToken.lexeme;
  }

  int? _getFragmentNameOffset(Token? nameToken) {
    if (nameToken == null || nameToken.isSynthetic) {
      return null;
    }
    return nameToken.offset;
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
  final InstanceElementBuilder? instanceElementBuilder;
  final ElementImpl fragment;
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

  _EnclosingContext({
    required this.instanceElementBuilder,
    required this.fragment,
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

  Reference get fragmentReference {
    return fragment.reference!;
  }

  List<FunctionElementImpl> get functions {
    return _functions.toFixedList();
  }

  bool get isDartCoreEnum {
    var fragment = this.fragment;
    return fragment is ClassElementImpl && fragment.isDartCoreEnum;
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

  void addNonSyntheticField(String name, FieldElementImpl element) {
    addField(name, element);

    // Augmenting a variable with a variable only alters its initializer.
    // So, don't create getter and setter.
    if (element.isAugmentation) {
      return;
    }

    {
      var getterRef = fragmentReference.getChild('@getter').addChild(name);
      var getter = element.createImplicitGetter(getterRef);
      _propertyAccessors.add(getter);
    }

    if (element.hasSetter) {
      var setterRef = fragmentReference.getChild('@setter').addChild(name);
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

  void addTypeParameter(String name, TypeParameterElementImpl fragment) {
    _typeParameters.add(fragment);
    this.fragment.encloseElement(fragment);
  }

  Reference _addReference(
    String containerName,
    String name,
    ElementImpl element,
  ) {
    var containerRef = fragmentReference.getChild(containerName);
    var reference = containerRef.addChild(name);
    _bindReference(reference, element);
    return reference;
  }

  void _bindReference(Reference reference, ElementImpl fragment) {
    reference.element = fragment;
    fragment.reference = reference;
    this.fragment.encloseElement(fragment);
  }
}
